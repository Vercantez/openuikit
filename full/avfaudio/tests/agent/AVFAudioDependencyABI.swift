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
#endif
#if canImport(AudioToolbox)
import AudioToolbox
#endif
#if canImport(CoreMIDI)
import CoreMIDI
#endif
#if canImport(CoreMedia)
import CoreMedia
#endif

enum ABIFailure: Error {
    case message(String)
}

func require(_ condition: Bool, _ message: String) throws {
    if !condition { throw ABIFailure.message(message) }
}

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

func awaitDeniedPermission() throws {
    var count = 0
    var inline = false
    var granted = true
    let lock = NSLock()
    let sem = DispatchSemaphore(value: 0)
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

func inspectLoadedLibrary() throws {
    let handle = dlopen("libAVFAudio.dylib", RTLD_NOW)
    try require(handle != nil, "dlopen libAVFAudio.dylib")
    defer { if let handle { dlclose(handle) } }

    var info = Dl_info()
    let symbol = dlsym(handle, "$s8AVFAudio14AVAudioEngineCMa")
        ?? dlsym(handle, "OBJC_CLASS_$_AVAudioEngine")
    if let symbol, dladdr(symbol, &info) != 0, let filename = info.dli_fname {
        let name = String(cString: filename)
        try require(name.contains("AVFAudio"), "loaded image should be AVFAudio: \(name)")
    }

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
    let appSem = DispatchSemaphore(value: 0)
    AVAudioApplication.requestRecordPermission { granted in
        dispatchPrecondition(condition: .onQueue(AVFAudioHostAvailability.callbackQueue))
        appCount += 1
        try? require(granted == false, "application permission denied")
        appSem.signal()
    }
    appInline = appCount != 0
    try require(!appInline, "application permission ran inline")
    try require(appSem.wait(timeout: .now() + 2) == .success, "application permission timeout")
    try require(appCount == 1, "application permission exactly once")

    var voiceCount = 0
    var voiceInline = false
    let voiceSem = DispatchSemaphore(value: 0)
    AVSpeechSynthesizer.requestPersonalVoiceAuthorization { status in
        dispatchPrecondition(condition: .onQueue(AVFAudioHostAvailability.callbackQueue))
        voiceCount += 1
        try? require(status == .unsupported, "personal voice unsupported")
        voiceSem.signal()
    }
    voiceInline = voiceCount != 0
    try require(!voiceInline, "personal voice ran inline")
    try require(voiceSem.wait(timeout: .now() + 2) == .success, "personal voice timeout")
    try require(voiceCount == 1, "personal voice exactly once")

    let engine = AVAudioEngine()
    do {
        try engine.start()
        throw ABIFailure.message("ABI engine.start succeeded without a host")
    } catch {
        try require(!engine.isRunning, "ABI engine running after failed start")
    }
    do {
        try AVAudioSession.sharedInstance().setActive(true)
        throw ABIFailure.message("ABI setActive succeeded without a host")
    } catch {}

    try proveNoCopyDeallocatorOnce()

    #if canImport(CoreAudioTypes) || canImport(AudioToolbox)
    let list = allocateFlexibleList(bufferCount: 3)
    defer { UnsafeMutableRawPointer(list).deallocate() }
    try require(list.pointee.mNumberBuffers == 3, "flexible ABL buffer count")
    let buffers = audioBufferPointer(list)
    for index in 0..<3 {
        buffers[index].mNumberChannels = UInt32(index + 1)
        buffers[index].mDataByteSize = UInt32(16 * (index + 1))
    }
    try require(buffers[0].mNumberChannels == 1, "ABL buffer 0")
    try require(buffers[1].mNumberChannels == 2, "ABL buffer 1")
    try require(buffers[2].mNumberChannels == 3, "ABL buffer 2")
    try require(
        MemoryLayout<AudioBufferList>.offset(of: \.mNumberBuffers) == 0,
        "mNumberBuffers offset"
    )
    try require(MemoryLayout<AudioBuffer>.size > 0, "AudioBuffer from dependency")
    try require(
        MemoryLayout<AudioStreamBasicDescription>.size > 0,
        "ASBD exposed by dependency module"
    )
    try require(
        MemoryLayout<AudioTimeStamp>.size > 0,
        "AudioTimeStamp exposed by dependency module"
    )
    try require(
        MemoryLayout<AudioComponentDescription>.size > 0,
        "AudioComponentDescription from dependency"
    )
    #endif

    #if canImport(CoreMIDI)
    try require(MemoryLayout<MIDIEventList>.size > 0, "MIDIEventList from CoreMIDI")
    #endif

    #if canImport(CoreMedia)
    try require(MemoryLayout<CMTime>.size > 0, "CMTime from CoreMedia")
    #endif

    print("AVFAUDIO_DEPENDENCY_ABI_OK")
}

do {
    try run()
} catch {
    fputs("AVFAUDIO_DEPENDENCY_ABI_FAIL: \(error)\n", stderr)
    exit(1)
}
