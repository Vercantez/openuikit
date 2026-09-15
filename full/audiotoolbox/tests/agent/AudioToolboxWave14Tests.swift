import AudioToolbox
import Dispatch
import Foundation
#if canImport(CoreFoundation)
import CoreFoundation
#endif

// Wave-14 tests: offline-invokable remainder rows. Every test is top-level,
// synchronous, and argument-free. The dispatch-queue constructors are
// exercised for creation and offline pump behavior only; no main-queue hops,
// runloops, semaphores, or suspension points are used.

private func wave14Expect(_ condition: Bool, _ message: String) {
    if !condition {
        fatalError(message)
    }
}

#if canImport(CoreFoundation)
private func wave14FileURL(_ path: String) -> CFURL {
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

private func wave14PCMBlob(
    rate: Float64 = 8000,
    channels: UInt32 = 1,
    bits: UInt32 = 16,
    flags: UInt32 = 12
) -> [UInt8] {
    var blob = [UInt8](repeating: 0, count: 40)
    let bytesPerSample = bits / 8
    blob.withUnsafeMutableBytes { raw in
        let p = raw.baseAddress!
        p.storeBytes(of: rate, toByteOffset: 0, as: Float64.self)
        p.storeBytes(of: UInt32(0x6C70_636D), toByteOffset: 8, as: UInt32.self)
        p.storeBytes(of: flags, toByteOffset: 12, as: UInt32.self)
        p.storeBytes(of: bytesPerSample * channels, toByteOffset: 16, as: UInt32.self)
        p.storeBytes(of: UInt32(1), toByteOffset: 20, as: UInt32.self)
        p.storeBytes(of: bytesPerSample * channels, toByteOffset: 24, as: UInt32.self)
        p.storeBytes(of: channels, toByteOffset: 28, as: UInt32.self)
        p.storeBytes(of: bits, toByteOffset: 32, as: UInt32.self)
    }
    return blob
}

// 24-byte single-buffer list overlay: count@0, channels@8, byteSize@12,
// data pointer@16 (matches the product atLoadBufferList layout).
private func wave14BufferList(byteSize: UInt32, data: UnsafeMutableRawPointer?) -> [UInt8] {
    var list = [UInt8](repeating: 0, count: 24)
    list.withUnsafeMutableBytes { raw in
        raw.baseAddress!.storeBytes(of: UInt32(1), toByteOffset: 0, as: UInt32.self)
        raw.baseAddress!.storeBytes(of: UInt32(1), toByteOffset: 8, as: UInt32.self)
        raw.baseAddress!.storeBytes(of: byteSize, toByteOffset: 12, as: UInt32.self)
        raw.baseAddress!.storeBytes(
            of: UInt(bitPattern: data),
            toByteOffset: 16,
            as: UInt.self
        )
    }
    return list
}

private final class ATWave14CallbackBox: @unchecked Sendable {
    var store: Data
    init(_ store: Data = Data()) {
        self.store = store
    }
}

private func wave14BoxPointer(_ box: ATWave14CallbackBox) -> UnsafeMutableRawPointer {
    Unmanaged.passUnretained(box).toOpaque()
}

private func wave14ReadProc() -> AudioFile_ReadProc {
    return { client, position, requested, buffer, actual in
        let box = Unmanaged<ATWave14CallbackBox>.fromOpaque(client).takeUnretainedValue()
        let start = Int(max(position, 0))
        let available = max(box.store.count - start, 0)
        let count = min(Int(requested), available)
        if count > 0 {
            box.store.withUnsafeBytes { raw in
                buffer.copyMemory(from: raw.baseAddress!.advanced(by: start), byteCount: count)
            }
        }
        actual.pointee = UInt32(count)
        return 0
    }
}

private func wave14WriteProc() -> AudioFile_WriteProc {
    return { client, position, requested, buffer, actual in
        let box = Unmanaged<ATWave14CallbackBox>.fromOpaque(client).takeUnretainedValue()
        let start = Int(max(position, 0))
        let count = Int(requested)
        if start > box.store.count {
            box.store.append(Data(count: start - box.store.count))
        }
        let incoming = Data(bytes: buffer, count: count)
        if start == box.store.count {
            box.store.append(incoming)
        } else {
            let end = start + count
            if end > box.store.count {
                box.store.append(Data(count: end - box.store.count))
            }
            box.store.replaceSubrange(start..<end, with: incoming)
        }
        actual.pointee = requested
        return 0
    }
}

private func wave14GetSizeProc() -> AudioFile_GetSizeProc {
    return { client in
        let box = Unmanaged<ATWave14CallbackBox>.fromOpaque(client).takeUnretainedValue()
        return Int64(box.store.count)
    }
}

private func wave14SetSizeProc() -> AudioFile_SetSizeProc {
    return { client, size in
        let box = Unmanaged<ATWave14CallbackBox>.fromOpaque(client).takeUnretainedValue()
        if size < 0 {
            return kAudioFileUnspecifiedError
        }
        if Int64(box.store.count) > size {
            box.store.removeSubrange(Int(size)..<box.store.count)
        } else {
            box.store.append(Data(count: Int(size) - box.store.count))
        }
        return 0
    }
}

func testWave14ExtAudioFileWriteAsync() {
#if canImport(CoreFoundation)
    let path = FileManager.default.temporaryDirectory
        .appendingPathComponent("openuikit-at-w14-\(UUID().uuidString).wav")
    defer { try? FileManager.default.removeItem(at: path) }
    // The file itself is Float32 PCM so client traffic survives the offline
    // engine bit-exactly; int16 traffic loses ~1 LSB per float round trip
    // (pre-existing engine precision, also visible through synchronous Write).
    let format = wave14PCMBlob(bits: 32, flags: 9)
    var ext: ExtAudioFileRef?
    wave14Expect(
        format.withUnsafeBytes { raw in
            ExtAudioFileCreateWithURL(
                wave14FileURL(path.path),
                kAudioFileWAVEType,
                raw.baseAddress,
                nil,
                [],
                &ext
            )
        } == 0,
        "ext create"
    )
    // Float32 client data survives the offline PCM engine bit-exactly.
    let samples: [Float32] = [0.25, -0.5, 0.75, -1.0]
    let writeFrames: UInt32 = 4
    samples.withUnsafeBytes { sampleRaw in
        let list = wave14BufferList(
            byteSize: 16,
            data: UnsafeMutableRawPointer(mutating: sampleRaw.baseAddress!)
        )
        wave14Expect(
            list.withUnsafeBytes { raw in
                ExtAudioFileWriteAsync(ext, writeFrames, raw.baseAddress)
            } == 0,
            "async write"
        )
    }
    var told: Int64 = -1
    wave14Expect(ExtAudioFileTell(ext, &told) == 0 && told == 4, "tell advanced")
    wave14Expect(ExtAudioFileSeek(ext, 0) == 0, "seek")
    var readFrames: UInt32 = 4
    var out = [Float32](repeating: 0, count: 4)
    out.withUnsafeMutableBytes { outRaw in
        var list = wave14BufferList(byteSize: 16, data: outRaw.baseAddress!)
        wave14Expect(
            list.withUnsafeMutableBytes { raw in
                ExtAudioFileRead(ext, &readFrames, raw.baseAddress)
            } == 0,
            "read back"
        )
    }
    wave14Expect(readFrames == 4 && out == samples, "async sample-exact")
    let badList = wave14BufferList(byteSize: 16, data: nil)
    wave14Expect(
        badList.withUnsafeBytes { raw in
            ExtAudioFileWriteAsync(nil, 1, raw.baseAddress)
        } == kExtAudioFileError_InvalidOperationOrder,
        "unknown ref"
    )
    wave14Expect(ExtAudioFileDispose(ext) == 0, "dispose")
#endif
}

func testWave14CAShowFile() {
#if canImport(CoreFoundation)
    let path = FileManager.default.temporaryDirectory
        .appendingPathComponent("openuikit-at-show-\(UUID().uuidString).txt")
    defer { try? FileManager.default.removeItem(at: path) }
    let stream = path.path.withCString { fopen($0, "w") }
    wave14Expect(stream != nil, "fopen")
    CAShowFile(nil, stream)
    let marker = UnsafeMutableRawPointer(bitPattern: 0x1234)
    CAShowFile(marker, stream)
    CAShowFile(nil, nil)
    wave14Expect(fclose(stream) == 0, "fclose")
    let text = try! String(contentsOf: path, encoding: .utf8)
    wave14Expect(text.contains("AudioToolbox object nil"), "nil line")
    wave14Expect(text.contains("AudioToolbox object"), "pointer line")
#endif
}

func testWave14AudioFileOpenWithCallbacks() {
#if canImport(CoreFoundation)
    // Seed a real WAV container through the URL engine, then serve its bytes
    // through procs.
    let path = FileManager.default.temporaryDirectory
        .appendingPathComponent("openuikit-at-cbseed-\(UUID().uuidString).wav")
    defer { try? FileManager.default.removeItem(at: path) }
    let format = wave14PCMBlob()
    var seed: AudioFileID?
    wave14Expect(
        format.withUnsafeBytes { raw in
            AudioFileCreateWithURL(wave14FileURL(path.path), kAudioFileWAVEType, raw.baseAddress, [], &seed)
        } == 0,
        "seed create"
    )
    var seedPackets: UInt32 = 4
    let seedSamples: [Int16] = [10, 20, 30, 40]
    wave14Expect(
        seedSamples.withUnsafeBytes { raw in
            AudioFileWritePackets(seed, false, 8, nil, 0, &seedPackets, raw.baseAddress)
        } == 0,
        "seed write"
    )
    wave14Expect(AudioFileClose(seed) == 0, "seed close")
    let box = ATWave14CallbackBox(try! Data(contentsOf: path))
    let client = wave14BoxPointer(box)
    let read = wave14ReadProc()
    let write = wave14WriteProc()
    let getSize = wave14GetSizeProc()
    let setSize = wave14SetSizeProc()
    var file: AudioFileID?
    wave14Expect(
        AudioFileOpenWithCallbacks(client, read, write, getSize, setSize, kAudioFileWAVEType, &file) == 0,
        "callback open"
    )
    var readBytes: UInt32 = 8
    var out = [Int16](repeating: 0, count: 4)
    wave14Expect(
        out.withUnsafeMutableBytes { raw in
            AudioFileReadBytes(file, false, 0, &readBytes, raw.baseAddress)
        } == 0 && readBytes == 8,
        "callback read"
    )
    // WAV data starts at byte 44 for this encoder; decode little-endian.
    let first = Int(out[0])
    wave14Expect(first == 10 && out == seedSamples, "callback sample-exact")
    let replacement: [Int16] = [50, 60, 70, 80]
    var writeBytes: UInt32 = 8
    wave14Expect(
        replacement.withUnsafeBytes { raw in
            AudioFileWriteBytes(file, false, 0, &writeBytes, raw.baseAddress)
        } == 0,
        "callback write"
    )
    wave14Expect(AudioFileClose(file) == 0, "callback close flushes")
    // The flush pushed an encoded container back through the procs: the
    // backing store must still parse and carry the replacement samples.
    var reopened: AudioFileID?
    wave14Expect(
        AudioFileOpenWithCallbacks(client, read, write, getSize, setSize, 0, &reopened) == 0,
        "reopen flushed store"
    )
    var check = [Int16](repeating: 0, count: 4)
    var checkBytes: UInt32 = 8
    wave14Expect(
        check.withUnsafeMutableBytes { raw in
            AudioFileReadBytes(reopened, false, 0, &checkBytes, raw.baseAddress)
        } == 0,
        "read flushed"
    )
    wave14Expect(check == replacement, "flush sample-exact")
    wave14Expect(AudioFileClose(reopened) == 0, "close reopened")
    // Fail-closed edges.
    var bad: AudioFileID?
    wave14Expect(
        AudioFileOpenWithCallbacks(nil, read, write, getSize, setSize, kAudioFileWAVEType, &bad) != 0
            && bad == nil,
        "nil client"
    )
    wave14Expect(
        AudioFileOpenWithCallbacks(client, nil, write, getSize, setSize, kAudioFileWAVEType, &bad) != 0
            && bad == nil,
        "nil read proc"
    )
    let failingRead: AudioFile_ReadProc = { _, _, _, _, actual in
        actual.pointee = 0
        return -1
    }
    wave14Expect(
        AudioFileOpenWithCallbacks(client, failingRead, write, getSize, setSize, kAudioFileWAVEType, &bad)
            == kAudioFileUnspecifiedError && bad == nil,
        "failing read proc"
    )
    let emptyBox = ATWave14CallbackBox()
    wave14Expect(
        AudioFileOpenWithCallbacks(
            wave14BoxPointer(emptyBox),
            read,
            write,
            getSize,
            setSize,
            kAudioFileWAVEType,
            &bad
        ) == kAudioFileInvalidFileError && bad == nil,
        "empty store"
    )
    let garbageBox = ATWave14CallbackBox(Data("not-an-audio-file".utf8))
    wave14Expect(
        AudioFileOpenWithCallbacks(
            wave14BoxPointer(garbageBox),
            read,
            write,
            getSize,
            setSize,
            kAudioFileWAVEType,
            &bad
        ) == kAudioFileUnsupportedFileTypeError && bad == nil,
        "garbage store"
    )
    // Read-only opens (no write/set-size procs) parse but reject writes.
    var readOnly: AudioFileID?
    wave14Expect(
        AudioFileOpenWithCallbacks(client, read, nil, getSize, nil, kAudioFileWAVEType, &readOnly) == 0,
        "read-only open"
    )
    var denied: UInt32 = 2
    let deniedBytes: [UInt8] = [0, 0]
    wave14Expect(
        deniedBytes.withUnsafeBytes { raw in
            AudioFileWriteBytes(readOnly, false, 0, &denied, raw.baseAddress)
        } == kAudioFilePermissionsError,
        "read-only write denied"
    )
    wave14Expect(AudioFileClose(readOnly) == 0, "close read-only")
#endif
}

func testWave14AudioFileInitializeWithCallbacks() {
#if canImport(CoreFoundation)
    let box = ATWave14CallbackBox()
    let client = wave14BoxPointer(box)
    let read = wave14ReadProc()
    let write = wave14WriteProc()
    let getSize = wave14GetSizeProc()
    let setSize = wave14SetSizeProc()
    let format = wave14PCMBlob(rate: 44100)
    var file: AudioFileID?
    wave14Expect(
        format.withUnsafeBytes { raw in
            AudioFileInitializeWithCallbacks(
                client,
                read,
                write,
                getSize,
                setSize,
                kAudioFileWAVEType,
                raw.baseAddress,
                [],
                &file
            )
        } == 0,
        "callback initialize"
    )
    var packets: UInt32 = 4
    let samples: [Int16] = [7, 8, 9, 10]
    wave14Expect(
        samples.withUnsafeBytes { raw in
            AudioFileWritePackets(file, false, 8, nil, 0, &packets, raw.baseAddress)
        } == 0,
        "write packets"
    )
    wave14Expect(AudioFileClose(file) == 0, "close pushes container")
    wave14Expect(box.store.count > 44, "container pushed")
    wave14Expect(
        box.store.prefix(4) == Data([0x52, 0x49, 0x46, 0x46]),
        "RIFF magic"
    )
    // The pushed container must parse through the callback open path.
    var reopened: AudioFileID?
    wave14Expect(
        AudioFileOpenWithCallbacks(client, read, write, getSize, setSize, kAudioFileWAVEType, &reopened) == 0,
        "reopen initialized"
    )
    var readPackets: UInt32 = 4
    var readBytes: UInt32 = 0
    var out = [Int16](repeating: 0, count: 4)
    wave14Expect(
        out.withUnsafeMutableBytes { raw in
            AudioFileReadPackets(reopened, false, &readBytes, nil, 0, &readPackets, raw.baseAddress)
        } == 0,
        "read packets"
    )
    wave14Expect(out == samples, "initialize round trip")
    wave14Expect(AudioFileClose(reopened) == 0, "close reopened")
    // Fail-closed edges.
    var bad: AudioFileID?
    wave14Expect(
        format.withUnsafeBytes { raw in
            AudioFileInitializeWithCallbacks(
                client,
                read,
                write,
                getSize,
                setSize,
                AudioFileTypeID(0xDEAD_BEEF),
                raw.baseAddress,
                [],
                &bad
            )
        } == kAudioFileUnsupportedFileTypeError && bad == nil,
        "bad file type"
    )
    wave14Expect(
        AudioFileInitializeWithCallbacks(
            client,
            read,
            write,
            getSize,
            setSize,
            kAudioFileWAVEType,
            nil,
            [],
            &bad
        ) == kAudioFileUnspecifiedError && bad == nil,
        "nil format"
    )
    var compressed = format
    compressed.withUnsafeMutableBytes { raw in
        raw.baseAddress!.storeBytes(of: UInt32(0xDEAD_BEEF), toByteOffset: 8, as: UInt32.self)
    }
    wave14Expect(
        compressed.withUnsafeBytes { raw in
            AudioFileInitializeWithCallbacks(
                client,
                read,
                write,
                getSize,
                setSize,
                kAudioFileWAVEType,
                raw.baseAddress,
                [],
                &bad
            )
        } == kAudioFileUnsupportedDataFormatError && bad == nil,
        "compressed format"
    )
    wave14Expect(
        format.withUnsafeBytes { raw in
            AudioFileInitializeWithCallbacks(
                nil,
                read,
                write,
                getSize,
                setSize,
                kAudioFileWAVEType,
                raw.baseAddress,
                [],
                &bad
            )
        } == kAudioFileUnspecifiedError && bad == nil,
        "nil client"
    )
#endif
}

func testWave14AudioQueueDispatchQueues() {
    let format = wave14PCMBlob(rate: 44100)
    let queue = DispatchQueue(label: "openuikit-at-wave14")
    var output: AudioQueueRef?
    let noOutputCallback: AudioQueueOutputCallback? = nil
    wave14Expect(
        format.withUnsafeBytes { raw in
            AudioQueueNewOutputWithDispatchQueue(raw.baseAddress, noOutputCallback, nil, queue, 0, &output)
        } == 0 && output != nil,
        "dispatch output"
    )
    var runningSize: UInt32 = 4
    var running: UInt32 = 99
    wave14Expect(
        withUnsafeMutableBytes(of: &running) { raw in
            AudioQueueGetProperty(output, kAudioQueueProperty_IsRunning, raw.baseAddress, &runningSize)
        } == 0,
        "output property"
    )
    wave14Expect(AudioQueueDispose(output, true) == 0, "dispose output")
    var input: AudioQueueRef?
    let noInputCallback: AudioQueueInputCallback? = nil
    wave14Expect(
        format.withUnsafeBytes { raw in
            AudioQueueNewInputWithDispatchQueue(raw.baseAddress, noInputCallback, nil, queue, 0, &input)
        } == 0 && input != nil,
        "dispatch input"
    )
    wave14Expect(AudioQueueDispose(input, true) == 0, "dispose input")
    var bad: AudioQueueRef?
    wave14Expect(
        AudioQueueNewOutputWithDispatchQueue(nil, noOutputCallback, nil, queue, 0, &bad)
            == kAudioQueueErr_InvalidParameter && bad == nil,
        "nil format"
    )
    var compressed = format
    compressed.withUnsafeMutableBytes { raw in
        raw.baseAddress!.storeBytes(of: UInt32(0xDEAD_BEEF), toByteOffset: 8, as: UInt32.self)
    }
    wave14Expect(
        compressed.withUnsafeBytes { raw in
            AudioQueueNewInputWithDispatchQueue(raw.baseAddress, noInputCallback, nil, nil, 0, &bad)
        } == kAudioQueueErr_CodecNotFound && bad == nil,
        "compressed dispatch input"
    )
}

func testWave14DarwinBooleanInits() {
    let enabled = AUVoiceIOOtherAudioDuckingConfiguration(
        mEnableAdvancedDucking: DarwinBoolean(true),
        mDuckingLevel: .default
    )
    wave14Expect(enabled.mEnableAdvancedDucking == 1, "ducking true")
    wave14Expect(enabled.mDuckingLevel == .default, "ducking level")
    let disabled = AUVoiceIOOtherAudioDuckingConfiguration(
        mEnableAdvancedDucking: DarwinBoolean(false),
        mDuckingLevel: .default
    )
    wave14Expect(disabled.mEnableAdvancedDucking == 0, "ducking false")
    let clipping = AudioUnitMeterClipping(
        peakValueSinceLastCall: 0.5,
        sawInfinity: DarwinBoolean(false),
        sawNotANumber: DarwinBoolean(true)
    )
    wave14Expect(clipping.peakValueSinceLastCall == 0.5, "peak")
    wave14Expect(clipping.sawInfinity == 0, "infinity false")
    wave14Expect(clipping.sawNotANumber == 1, "nan true")
}
