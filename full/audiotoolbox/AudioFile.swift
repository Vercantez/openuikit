#if canImport(CoreAudioTypes)
import CoreAudioTypes
#endif
#if canImport(CoreFoundation)
import CoreFoundation
#endif
#if os(Linux)
import Glibc
#endif
import Foundation

public enum AudioFilePermissions: Int8, Sendable, Hashable {
    case readPermission = 0x01
    case writePermission = 0x02
    case readWritePermission = 0x03
}

public struct AudioFileFlags: OptionSet, Sendable, Hashable {
    public let rawValue: UInt32
    public init(rawValue: UInt32) { self.rawValue = rawValue }
    public static let eraseFile = AudioFileFlags(rawValue: 1)
    public static let dontPageAlignAudioData = AudioFileFlags(rawValue: 2)
}

@frozen
public struct AudioFilePacketTableInfo: Equatable, Hashable, Sendable {
    public var mNumberValidFrames: Int64
    public var mPrimingFrames: Int32
    public var mRemainderFrames: Int32

    public init() {
        mNumberValidFrames = 0
        mPrimingFrames = 0
        mRemainderFrames = 0
    }

    public init(mNumberValidFrames: Int64, mPrimingFrames: Int32, mRemainderFrames: Int32) {
        self.mNumberValidFrames = mNumberValidFrames
        self.mPrimingFrames = mPrimingFrames
        self.mRemainderFrames = mRemainderFrames
    }
}

@frozen
public struct AudioFileTypeAndFormatID: Equatable, Hashable, Sendable {
    public var mFileType: AudioFileTypeID
    public var mFormatID: UInt32

    public init() {
        mFileType = 0
        mFormatID = 0
    }

    public init(mFileType: AudioFileTypeID, mFormatID: UInt32) {
        self.mFileType = mFileType
        self.mFormatID = mFormatID
    }
}

internal final class ATAudioFileObject: ATObject {
    let urlPath: String
    var closed = false

    init(urlPath: String) {
        self.urlPath = urlPath
    }
}

internal final class ATExtAudioFileObject: ATObject {
    var wrapped: ATAudioFileObject?
    var frameOffset: Int64 = 0
}

#if canImport(CoreFoundation)
public func AudioFileOpenURL(
    _ inFileRef: CFURL?,
    _ inPermissions: AudioFilePermissions,
    _ inFileTypeHint: AudioFileTypeID,
    _ outAudioFile: UnsafeMutablePointer<AudioFileID?>?
) -> Int32 {
    _ = inPermissions
    _ = inFileTypeHint
    outAudioFile?.pointee = nil
    guard let inFileRef else { return kAudioFileUnspecifiedError }
    if atCFURLIsLikelyMalformed(inFileRef) {
        return kAudioFileInvalidFileError
    }
    var buffer = [UInt8](repeating: 0, count: 4096)
    let gotPath = buffer.withUnsafeMutableBufferPointer { ptr in
        CFURLGetFileSystemRepresentation(inFileRef, true, ptr.baseAddress, 4096)
    }
    if !gotPath {
        return kAudioFileInvalidFileError
    }
    let path = String(cString: buffer)
    if path.isEmpty || path == "/" {
        return kAudioFileInvalidFileError
    }
    if path.withCString({ access($0, F_OK) }) != 0 {
        return kAudioFileFileNotFoundError
    }
    return kAudioFileUnsupportedFileTypeError
}

@_cdecl("ExtAudioFileOpenURL")
public func ExtAudioFileOpenURL(
    _ inURL: CFURL?,
    _ outExtAudioFile: UnsafeMutablePointer<ExtAudioFileRef?>?
) -> Int32 {
    outExtAudioFile?.pointee = nil
    guard let inURL else { return kExtAudioFileError_InvalidDataFormat }
    var dummy: AudioFileID?
    let status = AudioFileOpenURL(inURL, .readPermission, 0, &dummy)
    if status == kAudioFileFileNotFoundError {
        return kAudioFileFileNotFoundError
    }
    if status == kAudioFileInvalidFileError {
        return kExtAudioFileError_InvalidDataFormat
    }
    return kExtAudioFileError_InvalidDataFormat
}
#endif

@_cdecl("AudioFileClose")
public func AudioFileClose(_ inAudioFile: AudioFileID?) -> Int32 {
    let status = ATRegistry.shared.release(inAudioFile)
    return status == atParamError ? kAudioFileNotOpenError : 0
}

@_cdecl("ExtAudioFileDispose")
public func ExtAudioFileDispose(_ inExtAudioFile: ExtAudioFileRef?) -> Int32 {
    let status = ATRegistry.shared.release(inExtAudioFile)
    return status == atParamError ? 0 : status
}

@_cdecl("ExtAudioFileTell")
public func ExtAudioFileTell(
    _ inExtAudioFile: ExtAudioFileRef?,
    _ outFrameOffset: UnsafeMutablePointer<Int64>?
) -> Int32 {
    guard let file = ATRegistry.shared.lookup(inExtAudioFile, as: ATExtAudioFileObject.self) else {
        return kExtAudioFileError_InvalidOperationOrder
    }
    outFrameOffset?.pointee = file.frameOffset
    return 0
}

@_cdecl("ExtAudioFileSeek")
public func ExtAudioFileSeek(
    _ inExtAudioFile: ExtAudioFileRef?,
    _ inFrameOffset: Int64
) -> Int32 {
    guard let file = ATRegistry.shared.lookup(inExtAudioFile, as: ATExtAudioFileObject.self) else {
        return kExtAudioFileError_InvalidSeek
    }
    if inFrameOffset < 0 {
        return kExtAudioFileError_InvalidSeek
    }
    file.frameOffset = inFrameOffset
    return kExtAudioFileError_InvalidSeek
}

@_cdecl("ExtAudioFileWrapAudioFileID")
public func ExtAudioFileWrapAudioFileID(
    _ inFileID: AudioFileID?,
    _ inForWriting: Bool,
    _ outExtAudioFile: UnsafeMutablePointer<ExtAudioFileRef?>?
) -> Int32 {
    _ = inForWriting
    outExtAudioFile?.pointee = nil
    guard ATRegistry.shared.lookup(inFileID, as: ATAudioFileObject.self) != nil else {
        return kAudioFileNotOpenError
    }
    return kExtAudioFileError_InvalidOperationOrder
}

#if canImport(CoreAudioTypes)
public func AudioFileCreateWithURL(
    _ inFileRef: CFURL,
    _ inFileType: AudioFileTypeID,
    _ inFormat: UnsafePointer<AudioStreamBasicDescription>,
    _ inFlags: AudioFileFlags,
    _ outAudioFile: UnsafeMutablePointer<AudioFileID?>
) -> Int32 {
    _ = inFileRef
    _ = inFileType
    _ = inFormat
    _ = inFlags
    outAudioFile.pointee = nil
    return kAudioFileUnsupportedDataFormatError
}

public func ExtAudioFileCreateWithURL(
    _ inURL: CFURL,
    _ inFileType: AudioFileTypeID,
    _ inStreamDesc: UnsafePointer<AudioStreamBasicDescription>,
    _ inChannelLayout: UnsafeRawPointer?,
    _ inFlags: AudioFileFlags,
    _ outExtAudioFile: UnsafeMutablePointer<ExtAudioFileRef?>
) -> Int32 {
    _ = inURL
    _ = inFileType
    _ = inStreamDesc
    _ = inChannelLayout
    _ = inFlags
    outExtAudioFile.pointee = nil
    return kExtAudioFileError_InvalidDataFormat
}
#endif
