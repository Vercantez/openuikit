import Foundation

public typealias AudioFile_ReadProc = @convention(c) (
    UnsafeMutableRawPointer,
    Int64,
    UInt32,
    UnsafeMutableRawPointer,
    UnsafeMutablePointer<UInt32>
) -> Int32

public typealias AudioFile_WriteProc = @convention(c) (
    UnsafeMutableRawPointer,
    Int64,
    UInt32,
    UnsafeRawPointer,
    UnsafeMutablePointer<UInt32>
) -> Int32

public typealias AudioFile_GetSizeProc = @convention(c) (UnsafeMutableRawPointer) -> Int64

public typealias AudioFile_SetSizeProc = @convention(c) (UnsafeMutableRawPointer, Int64) -> Int32

public typealias AudioQueuePropertyListenerProc = @convention(c) (
    UnsafeMutableRawPointer?,
    AudioQueueRef,
    AudioQueuePropertyID
) -> Void
