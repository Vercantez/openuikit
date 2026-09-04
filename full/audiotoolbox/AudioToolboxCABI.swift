#if canImport(CoreFoundation)
import CoreFoundation
#endif
import Foundation

/// C ABI thunks. Swift names are `atCdecl_*` so they do not overload the typed
/// overlay; the exported C symbol is the `@_cdecl` name. These are not graph
/// surface identifiers.

@_cdecl("AudioComponentCount")
public func atCdecl_AudioComponentCount(_ inDesc: UnsafeRawPointer?) -> UInt32 {
    guard let inDesc else { return 0 }
    return AudioComponentCount(
        inDesc.assumingMemoryBound(to: AudioComponentDescription.self)
    )
}

@_cdecl("AudioComponentFindNext")
public func atCdecl_AudioComponentFindNext(
    _ inComponent: OpaquePointer?,
    _ inDesc: UnsafeRawPointer?
) -> OpaquePointer? {
    guard let inDesc else { return nil }
    return AudioComponentFindNext(
        inComponent,
        inDesc.assumingMemoryBound(to: AudioComponentDescription.self)
    )
}

@_cdecl("AudioComponentGetDescription")
public func atCdecl_AudioComponentGetDescription(
    _ inComponent: OpaquePointer?,
    _ outDesc: UnsafeMutableRawPointer?
) -> Int32 {
    guard let outDesc else {
        return AudioComponentGetDescription(inComponent, nil)
    }
    return AudioComponentGetDescription(
        inComponent,
        outDesc.assumingMemoryBound(to: AudioComponentDescription.self)
    )
}

@_cdecl("AudioComponentInstanceCanDo")
public func atCdecl_AudioComponentInstanceCanDo(
    _ inInstance: OpaquePointer?,
    _ inSelectorID: Int16
) -> UInt8 {
    AudioComponentInstanceCanDo(inInstance, inSelectorID) ? 1 : 0
}

@_cdecl("AudioQueueDispose")
public func atCdecl_AudioQueueDispose(
    _ inAQ: OpaquePointer?,
    _ inImmediate: UInt8
) -> Int32 {
    AudioQueueDispose(inAQ, inImmediate != 0)
}

@_cdecl("AudioQueueStop")
public func atCdecl_AudioQueueStop(
    _ inAQ: OpaquePointer?,
    _ inImmediate: UInt8
) -> Int32 {
    AudioQueueStop(inAQ, inImmediate != 0)
}

@_cdecl("AudioQueueNewOutput")
public func atCdecl_AudioQueueNewOutput(
    _ inFormat: UnsafeRawPointer?,
    _ inCallbackProc: UnsafeMutableRawPointer?,
    _ inUserData: UnsafeMutableRawPointer?,
    _ inCallbackRunLoop: UnsafeRawPointer?,
    _ inCallbackRunLoopMode: UnsafeRawPointer?,
    _ inFlags: UInt32,
    _ outAQ: UnsafeMutablePointer<OpaquePointer?>?
) -> Int32 {
    _ = inCallbackProc
    let callback: AudioQueueOutputCallback? = nil
    return AudioQueueNewOutput(
        inFormat,
        callback,
        inUserData,
        inCallbackRunLoop,
        inCallbackRunLoopMode,
        inFlags,
        outAQ
    )
}

@_cdecl("AudioQueueAllocateBuffer")
public func atCdecl_AudioQueueAllocateBuffer(
    _ inAQ: OpaquePointer?,
    _ inBufferByteSize: UInt32,
    _ outBuffer: UnsafeMutablePointer<UnsafeMutableRawPointer?>?
) -> Int32 {
    var buffer: AudioQueueBufferRef?
    let status = AudioQueueAllocateBuffer(inAQ, inBufferByteSize, &buffer)
    outBuffer?.pointee = buffer.map { UnsafeMutableRawPointer($0) }
    return status
}

@_cdecl("AudioQueueFreeBuffer")
public func atCdecl_AudioQueueFreeBuffer(
    _ inAQ: OpaquePointer?,
    _ inBuffer: UnsafeMutableRawPointer?
) -> Int32 {
    let typed = inBuffer.map { $0.assumingMemoryBound(to: AudioQueueBuffer.self) }
    return AudioQueueFreeBuffer(inAQ, typed)
}

#if canImport(CoreFoundation)
@_cdecl("AudioFileOpenURL")
public func atCdecl_AudioFileOpenURL(
    _ inFileRef: CFURL?,
    _ inPermissions: Int8,
    _ inFileTypeHint: UInt32,
    _ outAudioFile: UnsafeMutablePointer<OpaquePointer?>?
) -> Int32 {
    let permissions = AudioFilePermissions(rawValue: inPermissions) ?? .readPermission
    return AudioFileOpenURL(inFileRef, permissions, inFileTypeHint, outAudioFile)
}

@_cdecl("MusicTrackNewMIDINoteEvent")
public func atCdecl_MusicTrackNewMIDINoteEvent(
    _ inTrack: OpaquePointer?,
    _ inTimeStamp: Float64,
    _ inMessage: UnsafeRawPointer?
) -> Int32 {
    guard let inMessage else {
        return MusicTrackNewMIDINoteEvent(inTrack, inTimeStamp, nil)
    }
    return MusicTrackNewMIDINoteEvent(
        inTrack,
        inTimeStamp,
        inMessage.assumingMemoryBound(to: MIDINoteMessage.self)
    )
}
#endif
