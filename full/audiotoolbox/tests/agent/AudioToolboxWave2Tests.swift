#if canImport(CoreFoundation)
import CoreFoundation
#endif
#if canImport(Glibc)
import Glibc
#endif
import Foundation
import AudioToolbox

private func atW2Expect(_ condition: Bool, _ message: String) {
    if !condition {
        fatalError(message)
    }
}

private func atW2PCMBlob(
    rate: Float64,
    channels: UInt32 = 1,
    bits: UInt32 = 32,
    flags: UInt32 = 9,
    nonInterleaved: Bool = false
) -> [UInt8] {
    var blob = [UInt8](repeating: 0, count: 40)
    var localFlags = flags
    if nonInterleaved {
        localFlags |= 32
    }
    let bytesPerSample = bits / 8
    let bytesPerFrame = nonInterleaved ? bytesPerSample : bytesPerSample * channels
    blob.withUnsafeMutableBytes { raw in
        let p = raw.baseAddress!
        p.storeBytes(of: rate, toByteOffset: 0, as: Float64.self)
        p.storeBytes(of: UInt32(0x6C70_636D), toByteOffset: 8, as: UInt32.self)
        p.storeBytes(of: localFlags, toByteOffset: 12, as: UInt32.self)
        p.storeBytes(of: bytesPerFrame, toByteOffset: 16, as: UInt32.self)
        p.storeBytes(of: UInt32(1), toByteOffset: 20, as: UInt32.self)
        p.storeBytes(of: bytesPerFrame, toByteOffset: 24, as: UInt32.self)
        p.storeBytes(of: channels, toByteOffset: 28, as: UInt32.self)
        p.storeBytes(of: bits, toByteOffset: 32, as: UInt32.self)
    }
    return blob
}

#if canImport(CoreFoundation)
private func atW2FileURL(_ path: String) -> CFURL {
    path.withCString { cstr in
        CFURLCreateFromFileSystemRepresentation(
            kCFAllocatorDefault,
            UnsafeRawPointer(cstr).assumingMemoryBound(to: UInt8.self),
            path.utf8.count,
            false
        )!
    }
}
#endif

private var atFillSource: [Float] = [0, 1]
private func atFillComplexProc(
    _ converter: AudioConverterRef,
    _ ioPackets: UnsafeMutablePointer<UInt32>,
    _ ioData: UnsafeMutableRawPointer,
    _ packetDescs: UnsafeMutablePointer<UnsafeMutableRawPointer?>,
    _ userData: UnsafeMutableRawPointer?
) -> Int32 {
    _ = converter
    _ = packetDescs
    _ = userData
    guard Optional(ioData) != nil else { return -1 }
    let count = Int(ioData.loadUnaligned(fromByteOffset: 0, as: UInt32.self))
    _ = count
    let stored = ioData.loadUnaligned(fromByteOffset: 16, as: UInt.self)
    guard let dest = UnsafeMutableRawPointer(bitPattern: stored) else {
        ioPackets.pointee = 0
        return 0
    }
    let want = min(Int(ioPackets.pointee), atFillSource.count)
    for index in 0..<want {
        dest.storeBytes(of: atFillSource[index], toByteOffset: index * 4, as: Float.self)
    }
    ioPackets.pointee = UInt32(want)
    ioData.storeBytes(of: UInt32(want * 4), toByteOffset: 12, as: UInt32.self)
    return 0
}

private var atQueueListenerCount = 0
private func atQueueIsRunningListener(
    _ user: UnsafeMutableRawPointer?,
    _ queue: AudioQueueRef,
    _ id: AudioQueuePropertyID
) {
    _ = user
    _ = queue
    if id == kAudioQueueProperty_IsRunning {
        atQueueListenerCount += 1
    }
}

private var atGraphCallbackSamples: [Int16] = []
private func atGraphInputCallback(
    _ refCon: UnsafeMutableRawPointer?,
    _ flags: UnsafeMutablePointer<AudioUnitRenderActionFlags>?,
    _ timeStamp: UnsafeRawPointer?,
    _ bus: UInt32,
    _ frames: UInt32,
    _ ioData: UnsafeMutableRawPointer?
) -> Int32 {
    _ = refCon
    _ = timeStamp
    _ = bus
    flags?.pointee.remove(.unitRenderAction_OutputIsSilence)
    guard let ioData else { return kAudioUnitErr_InvalidParameter }
    let stored = ioData.loadUnaligned(fromByteOffset: 16, as: UInt.self)
    guard let dest = UnsafeMutableRawPointer(bitPattern: stored) else {
        return kAudioUnitErr_InvalidParameter
    }
    for index in 0..<Int(frames) {
        let sample: Int16 = index < atGraphCallbackSamples.count ? atGraphCallbackSamples[index] : 0
        dest.storeBytes(of: sample, toByteOffset: index * 2, as: Int16.self)
    }
    return 0
}

func testAudioConverterLinearInterpolation() {
    let source = atW2PCMBlob(rate: 1, bits: 32, flags: 9)
    let dest = atW2PCMBlob(rate: 2, bits: 32, flags: 9)
    var converter: AudioConverterRef?
    atW2Expect(
        source.withUnsafeBytes { s in
            dest.withUnsafeBytes { d in
                AudioConverterNew(s.baseAddress, d.baseAddress, &converter)
            }
        } == 0,
        "new converter"
    )
    var complexity = kAudioConverterSampleRateConverterComplexity_Linear
    atW2Expect(
        AudioConverterSetProperty(
            converter,
            kAudioConverterSampleRateConverterComplexity,
            4,
            &complexity
        ) == 0,
        "set linear"
    )
    var size: UInt32 = 4
    var stored: UInt32 = 0
    atW2Expect(
        AudioConverterGetProperty(
            converter,
            kAudioConverterSampleRateConverterComplexity,
            &size,
            &stored
        ) == 0,
        "get complexity"
    )
    atW2Expect(stored == kAudioConverterSampleRateConverterComplexity_Linear, "linear payload")
    let input: [Float] = [0, 1]
    var output = [Float](repeating: -9, count: 3)
    var outSize = UInt32(MemoryLayout<Float>.size * 3)
    let status = input.withUnsafeBytes { inRaw in
        output.withUnsafeMutableBytes { outRaw in
            AudioConverterConvertBuffer(
                converter,
                UInt32(inRaw.count),
                inRaw.baseAddress,
                &outSize,
                outRaw.baseAddress
            )
        }
    }
    atW2Expect(status == 0, "convert")
    atW2Expect(abs(output[0] - 0) < 0.0001, "hand-computed dest[0]=0")
    atW2Expect(abs(output[1] - 0.5) < 0.0001, "hand-computed dest[1]=0.5")
    atW2Expect(abs(output[2] - 1) < 0.0001, "hand-computed dest[2]=1")
    atW2Expect(AudioConverterDispose(converter) == 0, "dispose")
}

func testAudioConverterFillComplexBuffer() {
    let source = atW2PCMBlob(rate: 1, bits: 32, flags: 9)
    let dest = atW2PCMBlob(rate: 1, bits: 32, flags: 9)
    var converter: AudioConverterRef?
    atW2Expect(
        source.withUnsafeBytes { s in
            dest.withUnsafeBytes { d in
                AudioConverterNew(s.baseAddress, d.baseAddress, &converter)
            }
        } == 0,
        "new"
    )
    atFillSource = [0.25, -0.5]
    var packets: UInt32 = 2
    var output = [Float](repeating: 0, count: 2)
    var abl = [UInt8](repeating: 0, count: 24)
    let status = output.withUnsafeMutableBytes { outRaw in
        abl.withUnsafeMutableBytes { raw in
            raw.baseAddress!.storeBytes(of: UInt32(1), toByteOffset: 0, as: UInt32.self)
            raw.baseAddress!.storeBytes(of: UInt32(1), toByteOffset: 8, as: UInt32.self)
            raw.baseAddress!.storeBytes(of: UInt32(8), toByteOffset: 12, as: UInt32.self)
            raw.baseAddress!.storeBytes(of: UInt(bitPattern: outRaw.baseAddress), toByteOffset: 16, as: UInt.self)
            return AudioConverterFillComplexBuffer(
                converter,
                atFillComplexProc,
                nil,
                &packets,
                raw.baseAddress,
                nil
            )
        }
    }
    atW2Expect(status == 0, "fill")
    atW2Expect(packets == 2, "packets")
    atW2Expect(abs(output[0] - 0.25) < 0.0001, "sample 0")
    atW2Expect(abs(output[1] + 0.5) < 0.0001, "sample 1")
    atW2Expect(AudioConverterDispose(converter) == 0, "dispose")
}

func testAudioConverterNonInterleavedInt16ToFloat32() {
    let source = atW2PCMBlob(rate: 44100, channels: 2, bits: 16, flags: 12, nonInterleaved: true)
    let dest = atW2PCMBlob(rate: 44100, channels: 2, bits: 32, flags: 9, nonInterleaved: true)
    var converter: AudioConverterRef?
    atW2Expect(
        source.withUnsafeBytes { s in
            dest.withUnsafeBytes { d in
                AudioConverterNew(s.baseAddress, d.baseAddress, &converter)
            }
        } == 0,
        "new"
    )
    var input = [Int16](repeating: 0, count: 4)
    input[0] = 32767
    input[1] = 16384
    input[2] = -32768
    input[3] = 0
    var output = [Float](repeating: 0, count: 4)
    var outSize = UInt32(MemoryLayout<Float>.size * 4)
    let status = input.withUnsafeBytes { inRaw in
        output.withUnsafeMutableBytes { outRaw in
            AudioConverterConvertBuffer(
                converter,
                UInt32(inRaw.count),
                inRaw.baseAddress,
                &outSize,
                outRaw.baseAddress
            )
        }
    }
    atW2Expect(status == 0, "convert non-interleaved")
    atW2Expect(output[0] > 0.9, "L0")
    atW2Expect(output[2] < -0.9, "R0")
    atW2Expect(AudioConverterDispose(converter) == 0, "dispose")
}

func testAudioConverterConvertComplexBuffer() {
    let source = atW2PCMBlob(rate: 44100, bits: 16, flags: 12)
    let dest = atW2PCMBlob(rate: 44100, bits: 32, flags: 9)
    var converter: AudioConverterRef?
    atW2Expect(
        source.withUnsafeBytes { s in
            dest.withUnsafeBytes { d in
                AudioConverterNew(s.baseAddress, d.baseAddress, &converter)
            }
        } == 0,
        "new"
    )
    var samples: [Int16] = [0, 16384]
    var floats = [Float](repeating: 0, count: 2)
    var inABL = [UInt8](repeating: 0, count: 24)
    var outABL = [UInt8](repeating: 0, count: 24)
    let status = samples.withUnsafeMutableBytes { inRaw in
        floats.withUnsafeMutableBytes { outRaw in
            inABL.withUnsafeMutableBytes { inList in
                outABL.withUnsafeMutableBytes { outList in
                    inList.baseAddress!.storeBytes(of: UInt32(1), toByteOffset: 0, as: UInt32.self)
                    inList.baseAddress!.storeBytes(of: UInt32(1), toByteOffset: 8, as: UInt32.self)
                    inList.baseAddress!.storeBytes(of: UInt32(4), toByteOffset: 12, as: UInt32.self)
                    inList.baseAddress!.storeBytes(of: UInt(bitPattern: inRaw.baseAddress), toByteOffset: 16, as: UInt.self)
                    outList.baseAddress!.storeBytes(of: UInt32(1), toByteOffset: 0, as: UInt32.self)
                    outList.baseAddress!.storeBytes(of: UInt32(1), toByteOffset: 8, as: UInt32.self)
                    outList.baseAddress!.storeBytes(of: UInt32(8), toByteOffset: 12, as: UInt32.self)
                    outList.baseAddress!.storeBytes(of: UInt(bitPattern: outRaw.baseAddress), toByteOffset: 16, as: UInt.self)
                    return AudioConverterConvertComplexBuffer(
                        converter,
                        2,
                        inList.baseAddress,
                        outList.baseAddress
                    )
                }
            }
        }
    }
    atW2Expect(status == 0, "complex convert")
    atW2Expect(floats[1] > 0.4 && floats[1] < 0.6, "half scale")
    atW2Expect(AudioConverterDispose(converter) == 0, "dispose")
}

func testAudioFileStreamOptionSetsAndConstants() {
    atW2Expect(AudioFileStreamParseFlags(rawValue: 1) == .discontinuity, "discontinuity init")
    atW2Expect(AudioFileStreamParseFlags.discontinuity.rawValue == 1, "discontinuity")
    atW2Expect(AudioFileStreamPropertyFlags.propertyIsCached.rawValue == 1, "cached")
    atW2Expect(AudioFileStreamPropertyFlags.cacheProperty.rawValue == 2, "cache property")
    atW2Expect(AudioFileStreamSeekFlags.offsetIsEstimated.rawValue == 1, "estimated")
    let flags: AudioFileStreamParseFlags = [.discontinuity]
    atW2Expect(flags.contains(.discontinuity), "contains")
    atW2Expect(AudioFileStreamPropertyFlags(rawValue: 1) == .propertyIsCached, "cached init")
    atW2Expect(AudioFileStreamSeekFlags(rawValue: 1) == .offsetIsEstimated, "seek init")
    atW2Expect(kAudioFileStreamError_UnsupportedFileType == kAudioFileUnsupportedFileTypeError, "typ?")
    atW2Expect(kAudioFileStreamError_UnsupportedDataFormat == kAudioFileUnsupportedDataFormatError, "fmt?")
    atW2Expect(kAudioFileStreamError_UnsupportedProperty == kAudioFileUnsupportedPropertyError, "pty?")
    atW2Expect(kAudioFileStreamError_BadPropertySize == kAudioFileBadPropertySizeError, "!siz")
    atW2Expect(kAudioFileStreamError_NotOptimized == kAudioFileNotOptimizedError, "optm")
    atW2Expect(kAudioFileStreamError_InvalidPacketOffset == kAudioFileInvalidPacketOffsetError, "pck?")
    atW2Expect(kAudioFileStreamError_InvalidFile == kAudioFileInvalidFileError, "dta?")
    atW2Expect(kAudioFileStreamError_UnspecifiedError == kAudioFileUnspecifiedError, "wht?")
    atW2Expect(kAudioFileStreamProperty_DataFormat == kAudioFilePropertyDataFormat, "dfmt")
    atW2Expect(kAudioFileStreamProperty_FileFormat == kAudioFilePropertyFileFormat, "ffmt")
    atW2Expect(kAudioFileStreamProperty_PacketSizeUpperBound == kAudioFilePropertyPacketSizeUpperBound, "pkub")
    atW2Expect(kAudioFileStreamProperty_ChannelLayout == kAudioFilePropertyChannelLayout, "cmap")
    atW2Expect(kAudioFileStreamProperty_ReadyToProducePackets == 0x7265_6479, "redy")
    atW2Expect(kAudioFileStreamProperty_AverageBytesPerPacket == 0x6162_7070, "abpp")
    atW2Expect(kAudioFileStreamError_DataUnavailable == atSignedFourCCProxy("more"), "more")
    atW2Expect(kAudioFileStreamError_IllegalOperation == atSignedFourCCProxy("nope"), "nope")
    atW2Expect(kAudioFileStreamError_ValueUnknown == atSignedFourCCProxy("unk?"), "unk?")
    atW2Expect(kAudioFileStreamError_DiscontinuityCantRecover == atSignedFourCCProxy("dsc!"), "dsc!")
    atW2Expect(kAUNodeInteraction_Connection == 1, "connection")
    atW2Expect(kAUNodeInteraction_InputCallback == 2, "input callback")
}

private func atSignedFourCCProxy(_ s: StaticString) -> Int32 {
    precondition(s.utf8CodeUnitCount == 4)
    return s.withUTF8Buffer { buffer in
        Int32(bitPattern: (UInt32(buffer[0]) << 24) | (UInt32(buffer[1]) << 16) | (UInt32(buffer[2]) << 8) | UInt32(buffer[3]))
    }
}

func testAudioFileStreamWAVParse() {
#if canImport(CoreFoundation)
    let path = FileManager.default.temporaryDirectory
        .appendingPathComponent("openuikit-at-stream-\(UUID().uuidString).wav")
    defer { try? FileManager.default.removeItem(at: path) }
    let format = atW2PCMBlob(rate: 44100, bits: 16, flags: 12)
    var file: AudioFileID?
    atW2Expect(
        format.withUnsafeBytes { raw in
            AudioFileCreateWithURL(atW2FileURL(path.path), kAudioFileWAVEType, raw.baseAddress, [], &file)
        } == 0,
        "create"
    )
    var packets: UInt32 = 4
    let samples: [Int16] = [0, 1, -1, 2]
    atW2Expect(
        samples.withUnsafeBytes { raw in
            AudioFileWritePackets(file, false, 8, nil, 0, &packets, raw.baseAddress)
        } == 0,
        "write"
    )
    atW2Expect(AudioFileClose(file) == 0, "close")
    let bytes = try! Data(contentsOf: path)
    final class Box: @unchecked Sendable {
        var packets = 0
        var bytes = 0
        var properties: [UInt32] = []
    }
    let box = Box()
    let listener: AudioFileStream_PropertyListenerProc = { user, _, property, _ in
        Unmanaged<Box>.fromOpaque(user!).takeUnretainedValue().properties.append(property)
    }
    let packetsProc: AudioFileStream_PacketsProc = { user, byteCount, packetCount, _, _ in
        let box = Unmanaged<Box>.fromOpaque(user!).takeUnretainedValue()
        box.bytes += Int(byteCount)
        box.packets += Int(packetCount)
    }
    var stream: AudioFileStreamID?
    let user = Unmanaged.passUnretained(box).toOpaque()
    atW2Expect(
        AudioFileStreamOpen(user, listener, packetsProc, kAudioFileWAVEType, &stream) == 0,
        "open stream"
    )
    let half = bytes.count / 2
    atW2Expect(
        bytes.withUnsafeBytes { raw in
            AudioFileStreamParseBytes(stream, UInt32(half), raw.baseAddress, [])
        } == 0,
        "first half"
    )
    atW2Expect(
        bytes.withUnsafeBytes { raw in
            AudioFileStreamParseBytes(
                stream,
                UInt32(bytes.count - half),
                raw.baseAddress!.advanced(by: half),
                []
            )
        } == 0,
        "second half"
    )
    atW2Expect(box.properties.contains(kAudioFileStreamProperty_DataFormat), "dfmt announced")
    atW2Expect(box.properties.contains(kAudioFileStreamProperty_ReadyToProducePackets), "ready")
    atW2Expect(box.packets == 4, "packets")
    var infoSize: UInt32 = 0
    var writable: UInt8 = 1
    atW2Expect(
        AudioFileStreamGetPropertyInfo(stream, kAudioFileStreamProperty_DataFormat, &infoSize, &writable) == 0,
        "info dfmt"
    )
    atW2Expect(infoSize == 40, "asbd size")
    atW2Expect(
        AudioFileStreamSetProperty(stream, kAudioFileStreamProperty_DataFormat, 0, nil)
            == kAudioFileStreamError_UnsupportedProperty,
        "set fail-closed"
    )
    var size: UInt32 = 40
    var formatOut = [UInt8](repeating: 0, count: 40)
    atW2Expect(
        formatOut.withUnsafeMutableBytes { raw in
            AudioFileStreamGetProperty(stream, kAudioFileStreamProperty_DataFormat, &size, raw.baseAddress)
        } == 0,
        "get format"
    )
    var durationPackets: UInt64 = 0
    size = 8
    atW2Expect(
        AudioFileStreamGetProperty(stream, kAudioFileStreamProperty_AudioDataPacketCount, &size, &durationPackets) == 0,
        "packet count"
    )
    atW2Expect(durationPackets == 4, "4 packets")
    var pkub: UInt32 = 0
    size = 4
    atW2Expect(
        AudioFileStreamGetProperty(stream, kAudioFileStreamProperty_PacketSizeUpperBound, &size, &pkub) == 0,
        "pkub"
    )
    atW2Expect(pkub == 2, "16-bit packet")
    var avg: UInt32 = 0
    size = 4
    atW2Expect(
        AudioFileStreamGetProperty(stream, kAudioFileStreamProperty_AverageBytesPerPacket, &size, &avg) == 0,
        "abpp"
    )
    var byteCount: UInt64 = 0
    size = 8
    atW2Expect(
        AudioFileStreamGetProperty(stream, kAudioFileStreamProperty_AudioDataByteCount, &size, &byteCount) == 0,
        "bcnt"
    )
    atW2Expect(byteCount == 8, "8 audio bytes")
    var layout = [UInt8](repeating: 0, count: 12)
    size = 12
    atW2Expect(
        layout.withUnsafeMutableBytes { raw in
            AudioFileStreamGetProperty(stream, kAudioFileStreamProperty_ChannelLayout, &size, raw.baseAddress)
        } == 0,
        "layout"
    )
    var byteOffset: Int64 = -1
    var seekFlags = AudioFileStreamSeekFlags()
    atW2Expect(AudioFileStreamSeek(stream, 1, &byteOffset, &seekFlags) == 0, "seek")
    atW2Expect(AudioFileStreamClose(stream) == 0, "close")
#endif
}

func testAudioFileAIFFAndCAFRoundTrip() {
#if canImport(CoreFoundation)
    for (type, name) in [(kAudioFileAIFFType, "aiff"), (kAudioFileCAFType, "caf")] {
        let path = FileManager.default.temporaryDirectory
            .appendingPathComponent("openuikit-at-\(UUID().uuidString).\(name)")
        defer { try? FileManager.default.removeItem(at: path) }
        let format = atW2PCMBlob(rate: 44100, bits: 16, flags: type == kAudioFileAIFFType ? 14 : 12)
        var file: AudioFileID?
        atW2Expect(
            format.withUnsafeBytes { raw in
                AudioFileCreateWithURL(atW2FileURL(path.path), type, raw.baseAddress, [], &file)
            } == 0,
            "create \(name)"
        )
        var packets: UInt32 = 4
        let samples: [Int16] = [10, 20, 30, 40]
        atW2Expect(
            samples.withUnsafeBytes { raw in
                AudioFileWritePackets(file, false, 8, nil, 0, &packets, raw.baseAddress)
            } == 0,
            "write \(name)"
        )
        var duration: Float64 = 0
        var size: UInt32 = 8
        atW2Expect(
            AudioFileGetProperty(file, kAudioFilePropertyEstimatedDuration, &size, &duration) == 0,
            "duration"
        )
        atW2Expect(duration > 0, "positive duration")
        var bound: UInt32 = 0
        size = 4
        atW2Expect(
            AudioFileGetProperty(file, kAudioFilePropertyPacketSizeUpperBound, &size, &bound) == 0,
            "pkub"
        )
        atW2Expect(bound == 2, "16-bit mono packet")
        var layout = [UInt8](repeating: 0, count: 12)
        size = 12
        atW2Expect(
            layout.withUnsafeMutableBytes { raw in
                AudioFileGetProperty(file, kAudioFilePropertyChannelLayout, &size, raw.baseAddress)
            } == 0,
            "cmap"
        )
        atW2Expect(AudioFileClose(file) == 0, "close")
        var opened: AudioFileID?
        atW2Expect(
            AudioFileOpenURL(atW2FileURL(path.path), .readPermission, type, &opened) == 0,
            "reopen \(name)"
        )
        var readPackets: UInt32 = 4
        var readBytes: UInt32 = 0
        var out = [Int16](repeating: 0, count: 4)
        atW2Expect(
            out.withUnsafeMutableBytes { raw in
                AudioFileReadPackets(opened, false, &readBytes, nil, 0, &readPackets, raw.baseAddress)
            } == 0,
            "read \(name)"
        )
        atW2Expect(out == samples, "round trip \(name)")
        atW2Expect(AudioFileClose(opened) == 0, "close2")
        var stream: AudioFileStreamID?
        atW2Expect(AudioFileStreamOpen(nil, nil, nil, type, &stream) == 0, "stream \(name)")
        let data = try! Data(contentsOf: path)
        atW2Expect(
            data.withUnsafeBytes { raw in
                AudioFileStreamParseBytes(stream, UInt32(raw.count), raw.baseAddress, [])
            } == 0,
            "parse \(name)"
        )
        var fileType: UInt32 = 0
        size = 4
        atW2Expect(
            AudioFileStreamGetProperty(stream, kAudioFileStreamProperty_FileFormat, &size, &fileType) == 0,
            "stream file type"
        )
        atW2Expect(fileType == type, "hinted type")
        atW2Expect(AudioFileStreamClose(stream) == 0, "stream close")
    }
#endif
}

func testAudioQueuePropertyListenerAndSink() {
    let format = atW2PCMBlob(rate: 44100, bits: 16, flags: 12)
    atQueueListenerCount = 0
    var captured = [Int16]()
    let callback: AudioQueueOutputCallback = { _, _, buffer in
        let count = Int(buffer.pointee.mAudioDataByteSize) / 2
        let ptr = buffer.pointee.mAudioData.assumingMemoryBound(to: Int16.self)
        captured.append(contentsOf: UnsafeBufferPointer(start: ptr, count: count))
    }
    var queue: AudioQueueRef?
    atW2Expect(
        format.withUnsafeBytes { raw in
            AudioQueueNewOutput(raw.baseAddress, callback, nil, nil, nil, 0, &queue)
        } == 0,
        "new output"
    )
    atW2Expect(
        AudioQueueAddPropertyListener(queue, kAudioQueueProperty_IsRunning, atQueueIsRunningListener, nil) == 0,
        "listen"
    )
    var buffer: AudioQueueBufferRef?
    atW2Expect(AudioQueueAllocateBuffer(queue, 8, &buffer) == 0, "alloc")
    let samples: [Int16] = [1, 2, 3, 4]
    for (index, sample) in samples.enumerated() {
        buffer!.pointee.mAudioData.storeBytes(of: sample, toByteOffset: index * 2, as: Int16.self)
    }
    buffer!.pointee.mAudioDataByteSize = 8
    atW2Expect(AudioQueueEnqueueBuffer(queue, buffer, 0, nil) == 0, "enqueue")
    atW2Expect(AudioQueueStart(queue, nil) == 0, "start")
    atW2Expect(captured == samples, "sample-exact sink")
    atW2Expect(atQueueListenerCount >= 1, "running listener")
    atW2Expect(AudioQueuePause(queue) == 0, "pause")
    atW2Expect(AudioQueueFlush(queue) == 0, "flush")
    atW2Expect(AudioQueueStop(queue, true) == 0, "stop")
    atW2Expect(
        AudioQueueRemovePropertyListener(queue, kAudioQueueProperty_IsRunning, atQueueIsRunningListener, nil) == 0,
        "remove"
    )
    atW2Expect(AudioQueueDispose(queue, true) == 0, "dispose")
}

func testAUGraphMixerToOutput() {
    var graph: AUGraph?
    atW2Expect(NewAUGraph(&graph) == 0, "new graph")
    atW2Expect(AUGraphOpen(graph) == 0, "open")
    var open: UInt8 = 0
    atW2Expect(AUGraphIsOpen(graph, &open) == 0 && open == 1, "is open")
    var mixerDesc = AudioComponentDescription(
        componentType: kAudioUnitType_Mixer,
        componentSubType: kAudioUnitSubType_MultiChannelMixer,
        componentManufacturer: kAudioUnitManufacturer_Apple,
        componentFlags: 0,
        componentFlagsMask: 0
    )
    var outputDesc = AudioComponentDescription(
        componentType: kAudioUnitType_Output,
        componentSubType: kAudioUnitSubType_GenericOutput,
        componentManufacturer: kAudioUnitManufacturer_Apple,
        componentFlags: 0,
        componentFlagsMask: 0
    )
    var mixerNode: AUNode = 0
    var outputNode: AUNode = 0
    atW2Expect(AUGraphAddNode(graph, &mixerDesc, &mixerNode) == 0, "add mixer")
    atW2Expect(AUGraphAddNode(graph, &outputDesc, &outputNode) == 0, "add output")
    var count: UInt32 = 0
    atW2Expect(AUGraphGetNodeCount(graph, &count) == 0 && count == 2, "two nodes")
    var indexed: AUNode = 0
    atW2Expect(AUGraphGetIndNode(graph, 0, &indexed) == 0 && indexed == mixerNode, "ind")
    atW2Expect(AUGraphConnectNodeInput(graph, mixerNode, 0, outputNode, 0) == 0, "connect")
    atGraphCallbackSamples = [100, 200, 300, 400]
    var callback = AURenderCallbackStruct(inputProc: atGraphInputCallback, inputProcRefCon: nil)
    atW2Expect(AUGraphSetNodeInputCallback(graph, mixerNode, 0, &callback) == 0, "input callback")
    atW2Expect(AUGraphInitialize(graph) == 0, "initialize")
    var initialized: UInt8 = 0
    atW2Expect(AUGraphIsInitialized(graph, &initialized) == 0 && initialized == 1, "initialized")
    atW2Expect(AUGraphStart(graph) == 0, "start")
    var running: UInt8 = 0
    atW2Expect(AUGraphIsRunning(graph, &running) == 0 && running == 1, "running")
    var mixerUnit: AudioUnit?
    var description = AudioComponentDescription()
    atW2Expect(AUGraphNodeInfo(graph, mixerNode, &description, &mixerUnit) == 0, "node info")
    atW2Expect(mixerUnit != nil, "mixer unit")
    var interactionCount: UInt32 = 0
    atW2Expect(AUGraphGetNumberOfInteractions(graph, &interactionCount) == 0, "interactions")
    atW2Expect(interactionCount >= 1, "has interactions")
    var nodeInteractions: UInt32 = 0
    atW2Expect(AUGraphCountNodeInteractions(graph, mixerNode, &nodeInteractions) == 0, "node interactions")
    atW2Expect(nodeInteractions >= 1, "mixer has interactions")
    var storedInteractions = [AUNodeInteraction](repeating: AUNodeInteraction(), count: 4)
    var ioNum: UInt32 = 4
    atW2Expect(
        storedInteractions.withUnsafeMutableBufferPointer { buffer in
            AUGraphGetNodeInteractions(graph, mixerNode, &ioNum, buffer.baseAddress)
        } == 0,
        "get node interactions"
    )
    var interaction = AUNodeInteraction()
    atW2Expect(AUGraphGetInteractionInfo(graph, 0, &interaction) == 0, "info")
    atW2Expect(interaction.nodeInteractionType == kAUNodeInteraction_Connection, "connection type")
    atW2Expect(interaction.sourceNode == mixerNode, "source")
    atW2Expect(interaction.destNode == outputNode, "dest")
    atW2Expect(interaction.sourceOutputNumber == 0 && interaction.destInputNumber == 0, "buses")
    var load: Float32 = 1
    atW2Expect(AUGraphGetCPULoad(graph, &load) == 0 && load == 0, "cpu")
    atW2Expect(AUGraphGetMaxCPULoad(graph, &load) == 0, "max cpu")
    var updated: UInt8 = 0
    atW2Expect(AUGraphUpdate(graph, &updated) == 0, "update")
    var list = [UInt8](repeating: 0, count: 24)
    var samples = [Int16](repeating: 0, count: 4)
    list.withUnsafeMutableBytes { raw in
        raw.baseAddress!.storeBytes(of: UInt32(1), toByteOffset: 0, as: UInt32.self)
        raw.baseAddress!.storeBytes(of: UInt32(1), toByteOffset: 8, as: UInt32.self)
        raw.baseAddress!.storeBytes(of: UInt32(8), toByteOffset: 12, as: UInt32.self)
        samples.withUnsafeMutableBytes { pcm in
            raw.baseAddress!.storeBytes(of: UInt(bitPattern: pcm.baseAddress), toByteOffset: 16, as: UInt.self)
            var flags = AudioUnitRenderActionFlags()
            atW2Expect(AudioUnitRender(mixerUnit, &flags, nil, 0, 4, raw.baseAddress) == 0, "render mixer")
        }
    }
    atW2Expect(AUGraphStop(graph) == 0, "stop")
    atW2Expect(AUGraphUninitialize(graph) == 0, "uninit")
    atW2Expect(AUGraphDisconnectNodeInput(graph, outputNode, 0) == 0, "disconnect")
    atW2Expect(AUGraphClearConnections(graph) == 0, "clear")
    atW2Expect(AUGraphRemoveNode(graph, mixerNode) == 0, "remove")
    atW2Expect(AUGraphClose(graph) == 0, "close")
    atW2Expect(DisposeAUGraph(graph) == 0, "dispose")
    atW2Expect(DisposeAUGraph(graph) == 0, "idempotent")
}

func testAudioComponentGeneratorUnit() {
    var description = AudioComponentDescription(
        componentType: kAudioUnitType_Generator,
        componentSubType: kAudioUnitSubType_ScheduledSoundPlayer,
        componentManufacturer: kAudioUnitManufacturer_Apple,
        componentFlags: 0,
        componentFlagsMask: 0
    )
    atW2Expect(AudioComponentCount(&description) == 1, "generator catalogued")
    let component = AudioComponentFindNext(nil, &description)
    atW2Expect(component != nil, "find generator")
    var copied = AudioComponentDescription()
    atW2Expect(AudioComponentGetDescription(component, &copied) == 0, "copy desc")
    atW2Expect(copied.componentSubType == kAudioUnitSubType_ScheduledSoundPlayer, "sspl")
    var instance: AudioComponentInstance?
    atW2Expect(AudioComponentInstanceNew(component, &instance) == 0, "new")
    atW2Expect(AudioUnitInitialize(instance) == 0, "init generator")
    var list = [UInt8](repeating: 0, count: 24)
    var samples = [Int16](repeating: 0, count: 16)
    list.withUnsafeMutableBytes { raw in
        raw.baseAddress!.storeBytes(of: UInt32(1), toByteOffset: 0, as: UInt32.self)
        raw.baseAddress!.storeBytes(of: UInt32(2), toByteOffset: 8, as: UInt32.self)
        raw.baseAddress!.storeBytes(of: UInt32(32), toByteOffset: 12, as: UInt32.self)
        samples.withUnsafeMutableBytes { pcm in
            raw.baseAddress!.storeBytes(of: UInt(bitPattern: pcm.baseAddress), toByteOffset: 16, as: UInt.self)
            var flags = AudioUnitRenderActionFlags()
            atW2Expect(AudioUnitRender(instance, &flags, nil, 0, 8, raw.baseAddress) == 0, "render gen")
            atW2Expect(!flags.contains(.unitRenderAction_OutputIsSilence), "not silence")
        }
    }
    atW2Expect(AudioComponentInstanceDispose(instance) == 0, "dispose")
}

func testAUAudioUnitSoftwareMixer() {
    let mixer = AudioComponentDescription(
        componentType: kAudioUnitType_Mixer,
        componentSubType: kAudioUnitSubType_MultiChannelMixer,
        componentManufacturer: kAudioUnitManufacturer_Apple,
        componentFlags: 0,
        componentFlagsMask: 0
    )
    do {
        let unit = try AUAudioUnit(componentDescription: mixer)
        atW2Expect(unit.audioUnitName == "MultiChannelMixer", "name")
        atW2Expect(unit.manufacturerName == "Apple", "mfr")
        atW2Expect(unit.componentDescription.componentSubType == kAudioUnitSubType_MultiChannelMixer, "desc")
        atW2Expect(unit.inputBusses.count == 2, "two input busses")
        atW2Expect(unit.outputBusses.count == 1, "one output")
        atW2Expect(unit.canPerformOutput == false, "mixer is not output")
        atW2Expect(unit.canPerformInput == false, "no hardware input")
        atW2Expect(unit.parameterTree.children.isEmpty, "empty tree")
        try unit.allocateRenderResources()
        atW2Expect(unit.renderResourcesAllocated, "allocated")
        unit.maximumFramesToRender = 64
        atW2Expect(unit.maximumFramesToRender == 64, "frames")
        unit.deallocateRenderResources()
        atW2Expect(!unit.renderResourcesAllocated, "deallocated")
        unit.reset()
        do {
            try unit.startHardware()
            fatalError("hardware must fail closed")
        } catch {
            atW2Expect(true, "hardware fail-closed")
        }
        unit.stopHardware()
        atW2Expect(unit.componentVersion == 0, "version")
        atW2Expect(unit.latency == 0 && unit.tailTime == 0, "times")
        atW2Expect(unit.renderingOffline, "offline")
        atW2Expect(!unit.running, "not running")
    } catch {
        fatalError("software mixer must instantiate")
    }
    let remote = AudioComponentDescription(
        componentType: kAudioUnitType_Output,
        componentSubType: kAudioUnitSubType_RemoteIO,
        componentManufacturer: kAudioUnitManufacturer_Apple,
        componentFlags: 0,
        componentFlagsMask: 0
    )
    do {
        _ = try AUAudioUnit(componentDescription: remote)
        fatalError("RemoteIO must fail closed")
    } catch let error as NSError {
        atW2Expect(error.domain == NSOSStatusErrorDomain, "domain")
        atW2Expect(error.code == Int(kAudioUnitErr_ComponentManagerNotSupported), "unsupported")
    } catch {
        fatalError("unexpected error")
    }
    let generator = AudioComponentDescription(
        componentType: kAudioUnitType_Generator,
        componentSubType: kAudioUnitSubType_ScheduledSoundPlayer,
        componentManufacturer: kAudioUnitManufacturer_Apple,
        componentFlags: 0,
        componentFlagsMask: 0
    )
    do {
        let unit = try AUAudioUnit(componentDescription: generator)
        atW2Expect(unit.audioUnitShortName == "sspl", "short name")
        atW2Expect(unit.outputEnabled, "output enabled")
    } catch {
        fatalError("generator v3 must instantiate")
    }
}

func testCAFStructLayouts() {
    atW2Expect(MemoryLayout<CAFFileHeader>.size == 8, "file header")
    atW2Expect(MemoryLayout<CAFChunkHeader>.size == 12, "chunk header")
    atW2Expect(MemoryLayout<CAFAudioDescription>.size == 32, "desc")
    atW2Expect(MemoryLayout<CAF_SMPTE_Time>.size == 8, "smpte")
    let emptyHeader = CAFFileHeader()
    atW2Expect(emptyHeader.mFileType == kCAF_FileType, "default caff")
    atW2Expect(emptyHeader.mFileVersion == 1, "version")
    atW2Expect(emptyHeader.mFileFlags == 0, "flags")
    let header = CAFFileHeader(mFileType: kCAF_FileType, mFileVersion: 1, mFileFlags: 0)
    atW2Expect(header.mFileType == kCAF_FileType, "caff")
    let desc = CAFAudioDescription(
        mSampleRate: 44100,
        mFormatID: 0x6C70_636D,
        mFormatFlags: [.linearPCMFormatFlagIsLittleEndian],
        mBytesPerPacket: 4,
        mFramesPerPacket: 1,
        mChannelsPerFrame: 2,
        mBitsPerChannel: 16
    )
    atW2Expect(desc.mSampleRate == 44100, "rate")
    atW2Expect(desc.mFormatID == 0x6C70_636D, "lpcm")
    atW2Expect(desc.mBytesPerPacket == 4, "bpp")
    atW2Expect(desc.mFramesPerPacket == 1, "fpp")
    atW2Expect(desc.mChannelsPerFrame == 2, "channels")
    atW2Expect(desc.mBitsPerChannel == 16, "bits")
    atW2Expect(desc.mFormatFlags.contains(.linearPCMFormatFlagIsLittleEndian), "le")
    let emptyDesc = CAFAudioDescription()
    atW2Expect(emptyDesc.mChannelsPerFrame == 0, "empty desc")
    let chunk = CAFChunkHeader(mChunkType: kCAF_AudioDataChunkID, mChunkSize: 16)
    atW2Expect(chunk.mChunkType == kCAF_AudioDataChunkID, "data")
    atW2Expect(chunk.mChunkSize == 16, "chunk size")
    let emptyChunk = CAFChunkHeader()
    atW2Expect(emptyChunk.mChunkSize == 0, "empty chunk")
    let smpte = CAF_SMPTE_Time(mHours: 1, mMinutes: 2, mSeconds: 3, mFrames: 4, mSubFrameSampleOffset: 5)
    atW2Expect(smpte.mHours == 1 && smpte.mMinutes == 2, "smpte h/m")
    atW2Expect(smpte.mSeconds == 3 && smpte.mFrames == 4, "smpte s/f")
    atW2Expect(smpte.mSubFrameSampleOffset == 5, "subframe")
    let emptySmpte = CAF_SMPTE_Time()
    atW2Expect(emptySmpte.mHours == 0, "empty smpte")
    _ = header
}

func testMusicSequenceSMFType1Tracks() {
#if canImport(CoreFoundation)
    let smf: [UInt8] = [
        0x4D, 0x54, 0x68, 0x64, 0x00, 0x00, 0x00, 0x06,
        0x00, 0x01, 0x00, 0x02, 0x00, 0x60,
        0x4D, 0x54, 0x72, 0x6B, 0x00, 0x00, 0x00, 0x0B,
        0x00, 0xFF, 0x51, 0x03, 0x07, 0xA1, 0x20,
        0x00, 0xFF, 0x2F, 0x00,
        0x4D, 0x54, 0x72, 0x6B, 0x00, 0x00, 0x00, 0x0C,
        0x00, 0x90, 0x40, 0x40,
        0x60, 0x80, 0x40, 0x00,
        0x00, 0xFF, 0x2F, 0x00,
    ]
    var sequence: MusicSequence?
    atW2Expect(NewMusicSequence(&sequence) == 0, "seq")
    let data = smf.withUnsafeBufferPointer { buffer in
        CFDataCreate(kCFAllocatorDefault, buffer.baseAddress, buffer.count)!
    }
    atW2Expect(MusicSequenceFileLoadData(sequence, data, .midiType, []) == 0, "load type 1")
    var count: UInt32 = 0
    atW2Expect(MusicSequenceGetTrackCount(sequence, &count) == 0, "count")
    atW2Expect(count == 2, "two user tracks")
    var track: MusicTrack?
    atW2Expect(MusicSequenceGetIndTrack(sequence, 1, &track) == 0, "track 1")
    var iterator: MusicEventIterator?
    atW2Expect(NewMusicEventIterator(track, &iterator) == 0, "iterator")
    var has: UInt8 = 0
    atW2Expect(MusicEventIteratorHasCurrentEvent(iterator, &has) == 0 && has == 1, "has note")
    var time: MusicTimeStamp = -1
    var type: MusicEventType = 0
    var payload: UnsafeRawPointer?
    var size: UInt32 = 0
    atW2Expect(MusicEventIteratorGetEventInfo(iterator, &time, &type, &payload, &size) == 0, "info")
    atW2Expect(type == kMusicEventType_MIDINoteMessage, "note")
    atW2Expect(DisposeMusicEventIterator(iterator) == 0, "iterator")
    atW2Expect(DisposeMusicSequence(sequence) == 0, "dispose")
#endif
}

func testAudioFileChannelLayoutAndDuration() {
#if canImport(CoreFoundation)
    let path = FileManager.default.temporaryDirectory
        .appendingPathComponent("openuikit-at-props-\(UUID().uuidString).wav")
    defer { try? FileManager.default.removeItem(at: path) }
    let format = atW2PCMBlob(rate: 8000, bits: 16, flags: 12)
    var file: AudioFileID?
    format.withUnsafeBytes { raw in
        _ = AudioFileCreateWithURL(atW2FileURL(path.path), kAudioFileWAVEType, raw.baseAddress, [], &file)
    }
    var packets: UInt32 = 8000
    let samples = [Int16](repeating: 1, count: 8000)
    samples.withUnsafeBytes { raw in
        _ = AudioFileWritePackets(file, false, 16000, nil, 0, &packets, raw.baseAddress)
    }
    var infoSize: UInt32 = 0
    var writable: UInt32 = 1
    atW2Expect(
        AudioFileGetPropertyInfo(file, kAudioFilePropertyChannelLayout, &infoSize, &writable) == 0,
        "info"
    )
    atW2Expect(infoSize == 12, "layout size")
    var duration: Float64 = 0
    var size: UInt32 = 8
    atW2Expect(
        AudioFileGetProperty(file, kAudioFilePropertyEstimatedDuration, &size, &duration) == 0,
        "duration"
    )
    atW2Expect(abs(duration - 1.0) < 0.001, "one second")
    var asbd = [UInt8](repeating: 0, count: 40)
    size = 40
    atW2Expect(
        asbd.withUnsafeMutableBytes { raw in
            AudioFileGetProperty(file, kAudioFilePropertyDataFormat, &size, raw.baseAddress)
        } == 0,
        "dfmt"
    )
    atW2Expect(AudioFileClose(file) == 0, "close")
#endif
}

func testAUGraphRemoteIOFailClosed() {
    var graph: AUGraph?
    atW2Expect(NewAUGraph(&graph) == 0, "new")
    atW2Expect(AUGraphOpen(graph) == 0, "open")
    var remote = AudioComponentDescription(
        componentType: kAudioUnitType_Output,
        componentSubType: kAudioUnitSubType_RemoteIO,
        componentManufacturer: kAudioUnitManufacturer_Apple,
        componentFlags: 0,
        componentFlagsMask: 0
    )
    var node: AUNode = 0
    atW2Expect(AUGraphAddNode(graph, &remote, &node) == 0, "add remote")
    atW2Expect(AUGraphInitialize(graph) == kAUGraphErr_OutputNodeErr, "RemoteIO fail-closed")
    atW2Expect(DisposeAUGraph(graph) == 0, "dispose")
}

func testAUGraphAddRenderNotifyInert() {
    var graph: AUGraph?
    atW2Expect(NewAUGraph(&graph) == 0, "new")
    atW2Expect(AUGraphAddRenderNotify(graph, atGraphInputCallback, nil) == 0, "add notify")
    atW2Expect(AUGraphRemoveRenderNotify(graph, atGraphInputCallback, nil) == 0, "remove notify")
    atW2Expect(DisposeAUGraph(graph) == 0, "dispose")
}
