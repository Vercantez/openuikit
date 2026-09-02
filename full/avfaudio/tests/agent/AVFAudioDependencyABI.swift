import Foundation
#if canImport(Glibc)
import Glibc
#endif
#if canImport(Darwin)
import Darwin
#endif
import AVFAudio
@_spi(OpenUIKitHost) import AVFAudio

#if canImport(CoreAudioTypes)
import CoreAudioTypes
#else
#error("AVFAudio dependency ABI probe requires CoreAudioTypes")
#endif
#if canImport(AudioToolbox)
import AudioToolbox
#else
#error("AVFAudio dependency ABI probe requires AudioToolbox")
#endif
#if canImport(CoreMIDI)
import CoreMIDI
#else
#error("AVFAudio dependency ABI probe requires CoreMIDI")
#endif
#if canImport(CoreMedia)
import CoreMedia
#else
#error("AVFAudio dependency ABI probe requires CoreMedia")
#endif

enum ABIFailure: Error {
    case message(String)
}

func require(_ condition: Bool, _ message: String) throws {
    if !condition { throw ABIFailure.message(message) }
}

func requireThrows(_ message: String, _ operation: () throws -> Void) throws {
    var didThrow = false
    do {
        try operation()
    } catch {
        didThrow = true
    }
    try require(didThrow, message)
}

struct AVFAudioCLayoutReport {
    var audioBufferSize: UInt = 0
    var audioBufferAlign: UInt = 0
    var audioBufferListSize: UInt = 0
    var audioBufferListAlign: UInt = 0
    var audioBufferListNumberBuffersOffset: UInt = 0
    var audioBufferListBuffersOffset: UInt = 0
    var asbdSize: UInt = 0
    var asbdAlign: UInt = 0
    var walkedBuffers: UInt32 = 0
}

@_silgen_name("avfaudio_abi_fill_c_layout_report")
func avfaudioABIFillCLayoutReport(
    _ report: UnsafeMutablePointer<AVFAudioCLayoutReport>?
) -> CInt

@_silgen_name("avfaudio_abi_c_probe_available")
func avfaudioABICProbeAvailable() -> CInt

#if canImport(CoreAudioTypes) || canImport(AudioToolbox)
func audioBufferPointer(
    _ list: UnsafeMutablePointer<AudioBufferList>
) -> UnsafeMutablePointer<AudioBuffer> {
    let offset = MemoryLayout<AudioBufferList>.offset(of: \.mBuffers)
        ?? MemoryLayout<UInt32>.stride
    return UnsafeMutableRawPointer(list).advanced(by: offset).assumingMemoryBound(to: AudioBuffer.self)
}

func allocateFlexibleList(bufferCount: Int) -> UnsafeMutablePointer<AudioBufferList> {
    let extra = MemoryLayout<AudioBuffer>.stride * max(bufferCount - 1, 0)
    let byteCount = MemoryLayout<AudioBufferList>.size + extra
    let raw = UnsafeMutableRawPointer.allocate(
        byteCount: byteCount,
        alignment: max(MemoryLayout<AudioBufferList>.alignment, MemoryLayout<AudioBuffer>.alignment)
    )
    raw.initializeMemory(as: UInt8.self, repeating: 0, count: byteCount)
    let list = raw.bindMemory(to: AudioBufferList.self, capacity: 1)
    list.pointee.mNumberBuffers = UInt32(bufferCount)
    return list
}
#endif

func proveCLayoutIdentity() throws {
    #if canImport(CoreAudioTypes) || canImport(AudioToolbox)
    try require(avfaudioABICProbeAvailable() == 1, "C dependency headers are unavailable")
    var report = AVFAudioCLayoutReport()
    try require(
        avfaudioABIFillCLayoutReport(&report) == 0,
        "C flexible AudioBufferList walk failed"
    )
    try require(
        report.audioBufferSize == UInt(MemoryLayout<AudioBuffer>.size),
        "AudioBuffer size"
    )
    try require(
        report.audioBufferAlign == UInt(MemoryLayout<AudioBuffer>.alignment),
        "AudioBuffer alignment"
    )
    try require(
        report.audioBufferListSize == UInt(MemoryLayout<AudioBufferList>.size),
        "AudioBufferList size"
    )
    try require(
        report.audioBufferListAlign == UInt(MemoryLayout<AudioBufferList>.alignment),
        "AudioBufferList alignment"
    )
    guard
        let numberBuffersOffset = MemoryLayout<AudioBufferList>.offset(of: \.mNumberBuffers),
        let buffersOffset = MemoryLayout<AudioBufferList>.offset(of: \.mBuffers)
    else {
        throw ABIFailure.message("Swift AudioBufferList field offsets are unavailable")
    }
    try require(
        report.audioBufferListNumberBuffersOffset == UInt(numberBuffersOffset),
        "AudioBufferList.mNumberBuffers offset"
    )
    try require(
        report.audioBufferListBuffersOffset == UInt(buffersOffset),
        "AudioBufferList.mBuffers offset"
    )
    try require(
        report.asbdSize == UInt(MemoryLayout<AudioStreamBasicDescription>.size),
        "AudioStreamBasicDescription size"
    )
    try require(
        report.asbdAlign == UInt(MemoryLayout<AudioStreamBasicDescription>.alignment),
        "AudioStreamBasicDescription alignment"
    )
    try require(report.walkedBuffers == 4, "C flexible AudioBufferList buffer count")
    #else
    try require(avfaudioABICProbeAvailable() == 0, "C and Swift dependency visibility differ")
    throw ABIFailure.message("canonical CoreAudioTypes/AudioToolbox dependencies are unavailable")
    #endif
}

func awaitDeniedPermission() throws {
    var count = 0
    var inline = false
    var granted = true
    let lock = NSLock()
    let sem = DispatchSemaphore(value: 0)
    AVFAudioHostAvailability.callbackQueue.sync {
        AVAudioSession.sharedInstance().requestRecordPermission { value in
            dispatchPrecondition(condition: .onQueue(AVFAudioHostAvailability.callbackQueue))
            lock.lock()
            count += 1
            granted = value
            lock.unlock()
            sem.signal()
        }
        lock.lock()
        inline = count != 0
        lock.unlock()
    }
    try require(!inline, "ABI permission callback ran inline")
    try require(sem.wait(timeout: .now() + 2) == .success, "ABI permission timeout")
    try require(count == 1, "ABI permission not exactly once")
    try require(granted == false, "ABI permission must be denied")
}

func proveNoCopyDeallocatorOnce() throws {
    #if canImport(CoreAudioTypes) || canImport(AudioToolbox)
    guard
        let format = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: 44100,
            channels: 2,
            interleaved: false
        )
    else {
        throw ABIFailure.message("no-copy format")
    }
    let list = allocateFlexibleList(bufferCount: 2)
    let buffers = audioBufferPointer(list)
    let planeBytes = 256 * MemoryLayout<Float>.stride
    for index in 0..<2 {
        let plane = UnsafeMutableRawPointer.allocate(byteCount: planeBytes, alignment: 16)
        plane.initializeMemory(as: UInt8.self, repeating: 0, count: planeBytes)
        buffers[index] = AudioBuffer(
            mNumberChannels: 1,
            mDataByteSize: UInt32(planeBytes),
            mData: plane
        )
    }
    let deallocCount = UnsafeMutablePointer<Int>.allocate(capacity: 1)
    deallocCount.initialize(to: 0)
    do {
        let buffer = AVAudioPCMBuffer(
            pcmFormat: format,
            bufferListNoCopy: UnsafePointer(list),
            deallocator: { released in
                deallocCount.pointee += 1
                let releasedBuffers = audioBufferPointer(UnsafeMutablePointer(mutating: released))
                let count = Int(released.pointee.mNumberBuffers)
                for index in 0..<count {
                    releasedBuffers[index].mData?.deallocate()
                }
                UnsafeMutableRawPointer(mutating: released).deallocate()
            }
        )
        try require(buffer != nil, "no-copy buffer")
        try require(buffer?.floatChannelData != nil, "no-copy channel exposure")
        try require(deallocCount.pointee == 0, "deallocator must not run while buffer is alive")
    }
    try require(deallocCount.pointee == 1, "no-copy deallocator must run exactly once")
    deallocCount.deinitialize(count: 1)
    deallocCount.deallocate()
    #endif
}

func proveCopySemantics() throws {
    guard
        let format = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: 44_100,
            channels: 2,
            interleaved: false
        ),
        let original = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 4)
    else {
        throw ABIFailure.message("copy format")
    }
    original.frameLength = 2
    guard let originalChannels = original.floatChannelData else {
        throw ABIFailure.message("copy source channels")
    }
    originalChannels[0][0] = 1
    originalChannels[0][1] = 2
    originalChannels[0][2] = 3

    guard
        let copied = original.copy() as? AVAudioPCMBuffer,
        let mutableCopied = original.mutableCopy() as? AVAudioPCMBuffer
    else {
        throw ABIFailure.message("PCM copying dynamic type")
    }
    try require(copied !== original, "PCM copy identity")
    try require(mutableCopied !== original, "PCM mutable copy identity")
    try require(copied.frameCapacity == 16, "PCM copy capacity uses first-buffer bytes")
    try require(mutableCopied.frameCapacity == 16, "PCM mutable copy capacity")
    try require(copied.frameLength == 2, "PCM copy frame length")
    try require(copied.format === original.format, "PCM copy format identity")
    try require(copied.floatChannelData?[0][0] == 1, "PCM copy valid sample 0")
    try require(copied.floatChannelData?[0][1] == 2, "PCM copy valid sample 1")
    try require(copied.floatChannelData?[0][2] == 0, "PCM copy excludes invalid frames")
    originalChannels[0][0] = 9
    try require(copied.floatChannelData?[0][0] == 1, "PCM copy storage independence")

    var asbd = AudioStreamBasicDescription(
        mSampleRate: 44_100,
        mFormatID: kAudioFormatMPEG4AAC,
        mFormatFlags: 0,
        mBytesPerPacket: 0,
        mFramesPerPacket: 1_024,
        mBytesPerFrame: 0,
        mChannelsPerFrame: 2,
        mBitsPerChannel: 0,
        mReserved: 0
    )
    guard let compressedFormat = AVAudioFormat(streamDescription: &asbd) else {
        throw ABIFailure.message("compressed copy format")
    }
    let compressed = AVAudioCompressedBuffer(
        format: compressedFormat,
        packetCapacity: 3,
        maximumPacketSize: 8
    )
    guard
        let compressedCopy = compressed.copy() as? AVAudioBuffer,
        let compressedMutableCopy = compressed.mutableCopy() as? AVAudioBuffer
    else {
        throw ABIFailure.message("compressed copying base type")
    }
    try require(
        !(compressedCopy is AVAudioCompressedBuffer),
        "compressed copy dynamic type"
    )
    try require(
        !(compressedMutableCopy is AVAudioCompressedBuffer),
        "compressed mutable copy dynamic type"
    )
    try require(compressedCopy !== compressed, "compressed copy identity")
    try require(compressedMutableCopy !== compressed, "compressed mutable copy identity")
    try require(compressedCopy.format === compressed.format, "compressed copy format identity")
    try require(
        compressedMutableCopy.format === compressed.format,
        "compressed mutable copy format identity"
    )
}

func proveAudioTimeStampFlagRoundTrip() throws {
    #if canImport(CoreAudioTypes) || canImport(AudioToolbox)
    func stamp(
        hostTime: UInt64,
        sampleTime: Double,
        flags: AudioTimeStampFlags
    ) -> AudioTimeStamp {
        var value = AudioTimeStamp()
        value.mHostTime = hostTime
        value.mSampleTime = sampleTime
        value.mFlags = flags
        return value
    }

    func roundTrip(
        _ flags: AudioTimeStampFlags,
        expectHost: Bool,
        expectSample: Bool,
        label: String
    ) throws {
        var value = stamp(hostTime: 99, sampleTime: 44100, flags: flags)
        try require(
            value.mFlags.contains(.hostTimeValid) == expectHost,
            "\(label) host flag"
        )
        try require(
            value.mFlags.contains(.sampleTimeValid) == expectSample,
            "\(label) sample flag"
        )
        let decoded = AVAudioTime(audioTimeStamp: &value, sampleRate: 44100)
        try require(decoded.isHostTimeValid == expectHost, "\(label) host validity")
        try require(decoded.isSampleTimeValid == expectSample, "\(label) sample validity")
        var encoded = decoded.audioTimeStamp
        try require(
            encoded.mFlags.contains(.hostTimeValid) == expectHost,
            "\(label) encoded host flag"
        )
        try require(
            encoded.mFlags.contains(.sampleTimeValid) == expectSample,
            "\(label) encoded sample flag"
        )
        let again = AVAudioTime(audioTimeStamp: &encoded, sampleRate: 44100)
        try require(again.isHostTimeValid == expectHost, "\(label) second host validity")
        try require(again.isSampleTimeValid == expectSample, "\(label) second sample validity")
        if !expectHost {
            try require(encoded.mHostTime == 0, "\(label) encoded host time cleared")
        }
        if !expectSample {
            try require(encoded.mSampleTime == 0, "\(label) encoded sample time cleared")
        }
    }

    // Leftover mHostTime=99 / mSampleTime=44100 must not imply validity.
    try roundTrip([], expectHost: false, expectSample: false, label: "none")
    try roundTrip([.hostTimeValid], expectHost: true, expectSample: false, label: "host-only")
    try roundTrip([.sampleTimeValid], expectHost: false, expectSample: true, label: "sample-only")
    try roundTrip(
        [.hostTimeValid, .sampleTimeValid],
        expectHost: true,
        expectSample: true,
        label: "both"
    )
    try roundTrip(
        [.rateScalarValid],
        expectHost: false,
        expectSample: false,
        label: "nonzero-rate-scalar-only"
    )

    let hostOnly = AVAudioTime(hostTime: 42)
    var hostStamp = hostOnly.audioTimeStamp
    try require(hostStamp.mFlags.contains(.hostTimeValid), "AVAudioTime host-only flag")
    try require(!hostStamp.mFlags.contains(.sampleTimeValid), "AVAudioTime host-only excludes sample")
    let hostDecoded = AVAudioTime(audioTimeStamp: &hostStamp, sampleRate: 48000)
    try require(hostDecoded.isHostTimeValid && !hostDecoded.isSampleTimeValid, "host-only round-trip")

    let sampleOnly = AVAudioTime(sampleTime: 128, atRate: 44100)
    var sampleStamp = sampleOnly.audioTimeStamp
    try require(sampleStamp.mFlags.contains(.sampleTimeValid), "AVAudioTime sample-only flag")
    try require(!sampleStamp.mFlags.contains(.hostTimeValid), "AVAudioTime sample-only excludes host")
    let sampleDecoded = AVAudioTime(audioTimeStamp: &sampleStamp, sampleRate: 44100)
    try require(
        sampleDecoded.isSampleTimeValid && !sampleDecoded.isHostTimeValid,
        "sample-only round-trip"
    )

    let bothValid = AVAudioTime(hostTime: 7, sampleTime: 256, atRate: 48000)
    var bothStamp = bothValid.audioTimeStamp
    try require(
        bothStamp.mFlags.contains(.hostTimeValid) && bothStamp.mFlags.contains(.sampleTimeValid),
        "AVAudioTime both flags"
    )
    let bothDecoded = AVAudioTime(audioTimeStamp: &bothStamp, sampleRate: 48000)
    try require(
        bothDecoded.isHostTimeValid && bothDecoded.isSampleTimeValid,
        "both flags round-trip"
    )
    print("AVFAUDIO_AUDIO_TIMESTAMP_FLAGS_OK")
    #endif
}

func inspectLoadedLibrary() throws {
    let handle = dlopen("libAVFAudio.dylib", RTLD_NOW)
    try require(handle != nil, "dlopen libAVFAudio.dylib")
    defer { if let handle { dlclose(handle) } }

    var info = Dl_info()
    let symbol = dlsym(handle, "$s8AVFAudio13AVAudioEngineCMa")
        ?? dlsym(handle, "OBJC_CLASS_$_AVAudioEngine")
    try require(symbol != nil, "AVAudioEngine metadata symbol is missing")
    try require(dladdr(symbol, &info) != 0, "AVAudioEngine metadata image is unknown")
    guard let filename = info.dli_fname else {
        throw ABIFailure.message("AVAudioEngine metadata image lacks a filename")
    }
    let name = String(cString: filename)
    try require(
        name == "libAVFAudio.dylib" || name.hasSuffix("/libAVFAudio.dylib"),
        "loaded image should be the staged libAVFAudio.dylib: \(name)"
    )

    let shadowOSStatus = dlsym(handle, "$s8AVFAudio8OSStatusa")
    try require(shadowOSStatus == nil, "libAVFAudio must not export a module-local OSStatus alias")
    let shadowABL = dlsym(handle, "$s8AVFAudio15AudioBufferListVMa")
    try require(shadowABL == nil, "libAVFAudio must not export a module-local AudioBufferList")
}

func run() throws {
    try inspectLoadedLibrary()
    try awaitDeniedPermission()

    var appCount = 0
    var appInline = false
    var appGranted = true
    let appSem = DispatchSemaphore(value: 0)
    AVFAudioHostAvailability.callbackQueue.sync {
        AVAudioApplication.requestRecordPermission { granted in
            dispatchPrecondition(condition: .onQueue(AVFAudioHostAvailability.callbackQueue))
            appCount += 1
            appGranted = granted
            appSem.signal()
        }
        appInline = appCount != 0
    }
    try require(!appInline, "application permission ran inline")
    try require(appSem.wait(timeout: .now() + 2) == .success, "application permission timeout")
    try require(appCount == 1, "application permission exactly once")
    try require(appGranted == false, "application permission denied")

    var voiceCount = 0
    var voiceInline = false
    var voiceStatus: AVSpeechSynthesizer.PersonalVoiceAuthorizationStatus?
    let voiceSem = DispatchSemaphore(value: 0)
    AVFAudioHostAvailability.callbackQueue.sync {
        AVSpeechSynthesizer.requestPersonalVoiceAuthorization { status in
            dispatchPrecondition(condition: .onQueue(AVFAudioHostAvailability.callbackQueue))
            voiceCount += 1
            voiceStatus = status
            voiceSem.signal()
        }
        voiceInline = voiceCount != 0
    }
    try require(!voiceInline, "personal voice ran inline")
    try require(voiceSem.wait(timeout: .now() + 2) == .success, "personal voice timeout")
    try require(voiceCount == 1, "personal voice exactly once")
    try require(voiceStatus == .unsupported, "personal voice unsupported")

    let engine = AVAudioEngine()
    try requireThrows("ABI engine.start succeeded without a host") {
        try engine.start()
    }
    try require(!engine.isRunning, "ABI engine running after failed start")
    try requireThrows("ABI setActive succeeded without a host") {
        try AVAudioSession.sharedInstance().setActive(true)
    }

    try proveCLayoutIdentity()
    try proveNoCopyDeallocatorOnce()
    try proveCopySemantics()
    try proveAudioTimeStampFlagRoundTrip()

    try require(MemoryLayout<MIDIEventList>.size > 0, "MIDIEventList from CoreMIDI")
    try require(MemoryLayout<CMTime>.size > 0, "CMTime from CoreMedia")

    print("AVFAUDIO_DEPENDENCY_ABI_OK")
}

do {
    try run()
} catch {
    fputs("AVFAUDIO_DEPENDENCY_ABI_FAIL: \(error)\n", stderr)
    exit(1)
}
