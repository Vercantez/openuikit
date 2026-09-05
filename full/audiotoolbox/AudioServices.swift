#if canImport(CoreFoundation)
import CoreFoundation
#endif
import Foundation

public typealias AudioServicesSystemSoundCompletionProc = @convention(c) (
    SystemSoundID,
    UnsafeMutableRawPointer?
) -> Void

private struct ATSoundCompletion {
    var proc: AudioServicesSystemSoundCompletionProc
    var clientData: UnsafeMutableRawPointer?
}

private let soundLock = NSLock()
private var completions: [SystemSoundID: ATSoundCompletion] = [:]
private var nextSoundID: SystemSoundID = 0x1000

@_cdecl("AudioServicesPlaySystemSound")
public func AudioServicesPlaySystemSound(_ inSystemSoundID: SystemSoundID) {
    atDeliverSystemSoundCompletion(inSystemSoundID)
}

@_cdecl("AudioServicesPlayAlertSound")
public func AudioServicesPlayAlertSound(_ inSystemSoundID: SystemSoundID) {
    atDeliverSystemSoundCompletion(inSystemSoundID)
}

public func AudioServicesPlaySystemSoundWithCompletion(
    _ inSystemSoundID: SystemSoundID,
    _ inCompletionBlock: (() -> Void)?
) {
    AudioServicesPlaySystemSound(inSystemSoundID)
    inCompletionBlock?()
}

public func AudioServicesPlayAlertSoundWithCompletion(
    _ inSystemSoundID: SystemSoundID,
    _ inCompletionBlock: (() -> Void)?
) {
    AudioServicesPlayAlertSound(inSystemSoundID)
    inCompletionBlock?()
}

private func atDeliverSystemSoundCompletion(_ id: SystemSoundID) {
    var completion: ATSoundCompletion?
    atWithLock(soundLock) {
        completion = completions[id]
    }
    completion?.proc(id, completion?.clientData)
}

#if canImport(CoreFoundation)
@_cdecl("AudioServicesCreateSystemSoundID")
public func AudioServicesCreateSystemSoundID(
    _ inFileURL: CFURL?,
    _ outSystemSoundID: UnsafeMutablePointer<SystemSoundID>?
) -> Int32 {
    outSystemSoundID?.pointee = 0
    guard let inFileURL else {
        return kAudioServicesSystemSoundUnspecifiedError
    }
    if atCFURLIsLikelyMalformed(inFileURL) {
        return kAudioServicesSystemSoundUnspecifiedError
    }
    var dummy: AudioFileID?
    let openStatus = AudioFileOpenURL(inFileURL, .readPermission, 0, &dummy)
    if openStatus == kAudioFileFileNotFoundError {
        return kAudioServicesSystemSoundUnspecifiedError
    }
    if openStatus != 0 {
        return kAudioServicesSystemSoundUnspecifiedError
    }
    if let dummy {
        _ = AudioFileClose(dummy)
    }
    let assigned: SystemSoundID = atWithLock(soundLock) {
        let value = nextSoundID
        nextSoundID += 1
        return value
    }
    outSystemSoundID?.pointee = assigned
    return kAudioServicesNoError
}
#endif

@_cdecl("AudioServicesDisposeSystemSoundID")
public func AudioServicesDisposeSystemSoundID(_ inSystemSoundID: SystemSoundID) -> Int32 {
    atWithLock(soundLock) {
        completions.removeValue(forKey: inSystemSoundID)
    }
    return kAudioServicesNoError
}

@_cdecl("AudioServicesAddSystemSoundCompletion")
public func AudioServicesAddSystemSoundCompletion(
    _ inSystemSoundID: SystemSoundID,
    _ inRunLoop: UnsafeRawPointer?,
    _ inRunLoopMode: UnsafeRawPointer?,
    _ inCompletionRoutine: AudioServicesSystemSoundCompletionProc?,
    _ inClientData: UnsafeMutableRawPointer?
) -> Int32 {
    _ = inRunLoop
    _ = inRunLoopMode
    guard let inCompletionRoutine else { return atParamError }
    return atWithLock(soundLock) {
        completions[inSystemSoundID] = ATSoundCompletion(
            proc: inCompletionRoutine,
            clientData: inClientData
        )
        return kAudioServicesNoError
    }
}

@_cdecl("AudioServicesRemoveSystemSoundCompletion")
public func AudioServicesRemoveSystemSoundCompletion(_ inSystemSoundID: SystemSoundID) {
    atWithLock(soundLock) {
        completions.removeValue(forKey: inSystemSoundID)
    }
}

@_cdecl("AudioServicesGetPropertyInfo")
public func AudioServicesGetPropertyInfo(
    _ inPropertyID: AudioServicesPropertyID,
    _ inSpecifierSize: UInt32,
    _ inSpecifier: UnsafeRawPointer?,
    _ outPropertyDataSize: UnsafeMutablePointer<UInt32>?,
    _ outWritable: UnsafeMutablePointer<UInt8>?
) -> Int32 {
    _ = inSpecifierSize
    _ = inSpecifier
    outPropertyDataSize?.pointee = 4
    outWritable?.pointee = 0
    if inPropertyID == kAudioServicesPropertyIsUISound
        || inPropertyID == kAudioServicesPropertyCompletePlaybackIfAppDies
    {
        return kAudioServicesUnsupportedPropertyError
    }
    return kAudioServicesUnsupportedPropertyError
}

@_cdecl("AudioServicesGetProperty")
public func AudioServicesGetProperty(
    _ inPropertyID: AudioServicesPropertyID,
    _ inSpecifierSize: UInt32,
    _ inSpecifier: UnsafeRawPointer?,
    _ ioPropertyDataSize: UnsafeMutablePointer<UInt32>?,
    _ outPropertyData: UnsafeMutableRawPointer?
) -> Int32 {
    _ = inPropertyID
    _ = inSpecifierSize
    _ = inSpecifier
    _ = ioPropertyDataSize
    _ = outPropertyData
    return kAudioServicesUnsupportedPropertyError
}

@_cdecl("AudioServicesSetProperty")
public func AudioServicesSetProperty(
    _ inPropertyID: AudioServicesPropertyID,
    _ inSpecifierSize: UInt32,
    _ inSpecifier: UnsafeRawPointer?,
    _ inPropertyDataSize: UInt32,
    _ inPropertyData: UnsafeRawPointer?
) -> Int32 {
    _ = inPropertyID
    _ = inSpecifierSize
    _ = inSpecifier
    _ = inPropertyDataSize
    _ = inPropertyData
    return kAudioServicesUnsupportedPropertyError
}

#if canImport(CoreFoundation)
@_cdecl("CopyNameFromSoundBank")
public func CopyNameFromSoundBank(
    _ inURL: CFURL?,
    _ outName: UnsafeMutablePointer<Unmanaged<CFString>?>?
) -> Int32 {
    outName?.pointee = nil
    guard let inURL else { return atParamError }
    if atCFURLIsLikelyMalformed(inURL) {
        return kAudioFileInvalidFileError
    }
    return kAudioFileUnsupportedFileTypeError
}

@_cdecl("CopyInstrumentInfoFromSoundBank")
public func CopyInstrumentInfoFromSoundBank(
    _ inURL: CFURL?,
    _ outInstrumentInfo: UnsafeMutablePointer<Unmanaged<CFArray>?>?
) -> Int32 {
    outInstrumentInfo?.pointee = nil
    guard let inURL else { return atParamError }
    _ = inURL
    return kAudioFileUnsupportedFileTypeError
}
#endif
