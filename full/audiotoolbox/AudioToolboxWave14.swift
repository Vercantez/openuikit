import Dispatch
import Foundation
#if canImport(CoreFoundation)
import CoreFoundation
#endif

// Wave-14 depth pass: offline-invokable remainder of the AudioToolbox census.
// Everything here runs in-process without hardware, daemons, or services.
// Behaviors that differ from Apple queue/runloop/async timing are documented
// per item and recorded in oracle-questions.tsv instead of guessed.

// MARK: - ExtAudioFileWriteAsync (synchronous offline completion)

// Apple's async variant completes on a later runloop turn. The offline host
// has no runloop, so the write completes synchronously with the exact
// ExtAudioFileWrite engine and status contract. No hardware I/O is involved.
public func ExtAudioFileWriteAsync(
    _ inExtAudioFile: ExtAudioFileRef?,
    _ inNumberFrames: UInt32,
    _ ioData: UnsafeRawPointer?
) -> Int32 {
    return ExtAudioFileWrite(inExtAudioFile, inNumberFrames, ioData)
}

// MARK: - CAShowFile (FILE* debug output)

// Mirrors CAShow's stderr text but routes it to the caller's C stream. A nil
// stream falls back to stderr, matching CAShow. No hardware is involved.
public func CAShowFile(_ inObject: UnsafeMutableRawPointer?, _ inFile: UnsafeMutablePointer<FILE>?) {
    let text: String
    if let inObject {
        text = "AudioToolbox object \(inObject)\n"
    } else {
        text = "AudioToolbox object nil\n"
    }
    if let inFile {
        text.withCString { cString in
            _ = fputs(cString, inFile)
        }
    } else if let data = text.data(using: .utf8) {
        try? FileHandle.standardError.write(contentsOf: data)
    }
}

// MARK: - Callback-backed AudioFile persistence

// AudioFileOpenWithCallbacks / AudioFileInitializeWithCallbacks snapshot
// model: at open, the full byte range reported by the get-size proc is pulled
// through the read proc into memory (chunked at 64 KiB, stopping early when a
// proc reports a short transfer). Packet/byte reads and writes then operate
// on that snapshot through the exact in-memory engine used by URL-backed
// files. At flush (close of a writable file), the encoded WAVE/AIFF/CAF
// container is pushed back through the set-size and write procs. A client
// that mutates its backing store behind the snapshot will not be observed
// until the next open; that divergence is recorded in oracle-questions.tsv.
internal func atWave14PullCallbackStore(
    client: UnsafeMutableRawPointer,
    read: AudioFile_ReadProc,
    getSize: AudioFile_GetSizeProc
) -> (status: Int32, data: Data) {
    let size = getSize(client)
    if size < 0 {
        return (kAudioFileInvalidFileError, Data())
    }
    var data = Data()
    if size > 0 {
        data.reserveCapacity(Int(min(size, 16 * 1024 * 1024)))
    }
    var offset: Int64 = 0
    while offset < size {
        let want = UInt32(min(size - offset, 65536))
        var chunk = [UInt8](repeating: 0, count: Int(want))
        var actual: UInt32 = 0
        let status: Int32 = chunk.withUnsafeMutableBytes { raw in
            read(client, offset, want, raw.baseAddress!, &actual)
        }
        if status != 0 {
            return (kAudioFileUnspecifiedError, Data())
        }
        if actual > want {
            return (kAudioFileUnspecifiedError, Data())
        }
        if actual == 0 {
            break
        }
        data.append(contentsOf: chunk.prefix(Int(actual)))
        offset += Int64(actual)
        if actual < want {
            break
        }
    }
    return (0, data)
}

internal func atWave14FlushCallbacks(_ file: ATAudioFileObject) -> Int32 {
    guard file.permissions != .readPermission else {
        return 0
    }
    guard let client = file.callbackClient,
          let write = file.callbackWrite,
          let setSize = file.callbackSetSize
    else {
        return 0
    }
    let encoded: Data
    switch file.fileType {
    case kAudioFileWAVEType:
        encoded = atEncodeWAV(format: file.format, audio: file.audioBytes)
    case kAudioFileCAFType:
        encoded = atEncodeCAF(format: file.format, audio: file.audioBytes)
    default:
        encoded = atEncodeAIFF(format: file.format, audio: file.audioBytes)
    }
    if setSize(client, Int64(encoded.count)) != 0 {
        return kAudioFileUnspecifiedError
    }
    if encoded.isEmpty {
        return 0
    }
    var actual: UInt32 = 0
    let status: Int32 = encoded.withUnsafeBytes { raw in
        write(client, 0, UInt32(encoded.count), raw.baseAddress!, &actual)
    }
    if status != 0 || actual != UInt32(encoded.count) {
        return kAudioFileUnspecifiedError
    }
    return 0
}

// Apple's C signature carries `void *` client data with nullable-tolerant
// callers, but the exported Swift proc overlays take a non-optional client
// pointer, so a nil client cannot be forwarded to them: fail closed.
public func AudioFileOpenWithCallbacks(
    _ inClientData: UnsafeMutableRawPointer?,
    _ inReadFunc: AudioFile_ReadProc?,
    _ inWriteFunc: AudioFile_WriteProc?,
    _ inGetSizeFunc: AudioFile_GetSizeProc?,
    _ inSetSizeFunc: AudioFile_SetSizeProc?,
    _ inFileTypeHint: AudioFileTypeID,
    _ outAudioFile: UnsafeMutablePointer<AudioFileID?>?
) -> Int32 {
    outAudioFile?.pointee = nil
    guard let outAudioFile,
          let client = inClientData,
          let read = inReadFunc,
          let getSize = inGetSizeFunc
    else {
        return kAudioFileUnspecifiedError
    }
    let pulled = atWave14PullCallbackStore(client: client, read: read, getSize: getSize)
    guard pulled.status == 0 else {
        return pulled.status
    }
    if pulled.data.isEmpty {
        return kAudioFileInvalidFileError
    }
    guard let parsed = atParseAudioFile(pulled.data, hint: inFileTypeHint) else {
        return kAudioFileUnsupportedFileTypeError
    }
    if !parsed.format.isPCM {
        return kAudioFileUnsupportedDataFormatError
    }
    let writable = inWriteFunc != nil && inSetSizeFunc != nil
    let file = ATAudioFileObject(
        urlPath: "",
        fileType: parsed.type,
        format: parsed.format,
        audioBytes: parsed.audio,
        dataOffset: parsed.offset,
        permissions: writable ? .readWritePermission : .readPermission
    )
    file.callbackBacked = true
    file.callbackClient = client
    file.callbackRead = read
    file.callbackWrite = inWriteFunc
    file.callbackGetSize = getSize
    file.callbackSetSize = inSetSizeFunc
    outAudioFile.pointee = ATRegistry.shared.retain(file)
    return 0
}

public func AudioFileInitializeWithCallbacks(
    _ inClientData: UnsafeMutableRawPointer?,
    _ inReadFunc: AudioFile_ReadProc?,
    _ inWriteFunc: AudioFile_WriteProc?,
    _ inGetSizeFunc: AudioFile_GetSizeProc?,
    _ inSetSizeFunc: AudioFile_SetSizeProc?,
    _ inFileTypeHint: AudioFileTypeID,
    _ inFormat: UnsafeRawPointer?,
    _ inFlags: AudioFileFlags,
    _ outAudioFile: UnsafeMutablePointer<AudioFileID?>?
) -> Int32 {
    _ = inFlags
    outAudioFile?.pointee = nil
    guard let outAudioFile,
          let client = inClientData,
          let read = inReadFunc,
          let write = inWriteFunc,
          let getSize = inGetSizeFunc,
          let setSize = inSetSizeFunc
    else {
        return kAudioFileUnspecifiedError
    }
    guard let inFormat, var format = atLoadASBD(inFormat) else {
        return kAudioFileUnspecifiedError
    }
    if format.mFormatID != atFormatLinearPCM {
        return kAudioFileUnsupportedDataFormatError
    }
    if format.validatePCM() != 0 {
        return kAudioFileUnsupportedDataFormatError
    }
    atFillPCMASBD(&format)
    switch inFileTypeHint {
    case kAudioFileWAVEType, kAudioFileAIFFType, kAudioFileAIFCType, kAudioFileCAFType:
        break
    default:
        return kAudioFileUnsupportedFileTypeError
    }
    let file = ATAudioFileObject(
        urlPath: "",
        fileType: inFileTypeHint,
        format: format,
        audioBytes: Data(),
        dataOffset: 0,
        permissions: .readWritePermission
    )
    file.callbackBacked = true
    file.callbackClient = client
    file.callbackRead = read
    file.callbackWrite = write
    file.callbackGetSize = getSize
    file.callbackSetSize = setSize
    outAudioFile.pointee = ATRegistry.shared.retain(file)
    return 0
}

// MARK: - AudioQueue dispatch-queue constructors

// The dispatch queue selects callback delivery context on Apple platforms.
// The offline host pumps enqueued buffers synchronously on the calling thread
// (the same engine as the runloop constructors, whose runloop arguments are
// likewise accepted and ignored), so the queue is accepted for API
// compatibility and its hop timing is recorded in oracle-questions.tsv.
public func AudioQueueNewOutputWithDispatchQueue(
    _ inFormat: UnsafeRawPointer?,
    _ inCallbackProc: AudioQueueOutputCallback?,
    _ inUserData: UnsafeMutableRawPointer?,
    _ inCallbackDispatchQueue: DispatchQueue?,
    _ inFlags: UInt32,
    _ outAQ: UnsafeMutablePointer<AudioQueueRef?>?
) -> Int32 {
    _ = inCallbackDispatchQueue
    return AudioQueueNewOutput(inFormat, inCallbackProc, inUserData, nil, nil, inFlags, outAQ)
}

public func AudioQueueNewInputWithDispatchQueue(
    _ inFormat: UnsafeRawPointer?,
    _ inCallbackProc: AudioQueueInputCallback?,
    _ inUserData: UnsafeMutableRawPointer?,
    _ inCallbackDispatchQueue: DispatchQueue?,
    _ inFlags: UInt32,
    _ outAQ: UnsafeMutablePointer<AudioQueueRef?>?
) -> Int32 {
    _ = inCallbackDispatchQueue
    return AudioQueueNewInput(inFormat, inCallbackProc, inUserData, nil, nil, inFlags, outAQ)
}

// MARK: - DarwinBoolean memberwise-init overlays

// DarwinBoolean is a 1-byte value on every Swift platform (probed size 1,
// alignment 1 on Linux Swift 6.2.4); the overlays store its exact boolValue.
// The UInt8 spellings remain the canonical in-memory form.
extension AUVoiceIOOtherAudioDuckingConfiguration {
    public init(
        mEnableAdvancedDucking: DarwinBoolean,
        mDuckingLevel: AUVoiceIOOtherAudioDuckingLevel
    ) {
        self.init(
            mEnableAdvancedDucking: mEnableAdvancedDucking.boolValue ? 1 : 0,
            mDuckingLevel: mDuckingLevel
        )
    }
}

extension AudioUnitMeterClipping {
    public init(
        peakValueSinceLastCall: Float32,
        sawInfinity: DarwinBoolean,
        sawNotANumber: DarwinBoolean
    ) {
        self.init(
            peakValueSinceLastCall: peakValueSinceLastCall,
            sawInfinity: sawInfinity.boolValue ? 1 : 0,
            sawNotANumber: sawNotANumber.boolValue ? 1 : 0
        )
    }
}
