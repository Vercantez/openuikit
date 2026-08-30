import Foundation

public typealias OSStatus = Int32
public typealias SystemSoundID = UInt32
public typealias AudioFormatID = UInt32
public typealias AudioFormatFlags = UInt32
public typealias AudioUnit = OpaquePointer
public typealias AudioQueueRef = OpaquePointer
public typealias AudioQueueBufferRef = UnsafeMutablePointer<AudioQueueBuffer>

public let noErr: OSStatus = 0
public let kAudioServicesNoError: OSStatus = 0
public let kAudioServicesUnsupportedPropertyError: OSStatus = -1501
public let kAudioFormatUnsupportedDataFormatError: OSStatus = 1718449215
public let kSystemSoundID_Vibrate: SystemSoundID = 0x00000FFF
public let kAudioFormatLinearPCM: AudioFormatID = 0x6C70636D
public let kAudioFormatFlagIsFloat: AudioFormatFlags = 1 << 0
public let kAudioFormatFlagIsBigEndian: AudioFormatFlags = 1 << 1
public let kAudioFormatFlagIsSignedInteger: AudioFormatFlags = 1 << 2
public let kAudioFormatFlagIsPacked: AudioFormatFlags = 1 << 3
public let kAudioFormatFlagIsNonInterleaved: AudioFormatFlags = 1 << 5
public let kAudioFormatFlagsNativeEndian: AudioFormatFlags = 0

public enum AudioToolboxPortable {
    public enum PlaybackDisposition: String, Sendable {
        case unsupported
    }

    public private(set) static var requestedSystemSounds: [SystemSoundID] = []
    public static var playbackDisposition: PlaybackDisposition { .unsupported }

    public static func resetRequestHistory() {
        requestedSystemSounds.removeAll()
    }

    static func record(_ sound: SystemSoundID) {
        requestedSystemSounds.append(sound)
    }
}

public func AudioServicesPlaySystemSound(_ inSystemSoundID: SystemSoundID) {
    AudioToolboxPortable.record(inSystemSoundID)
}

public func AudioServicesPlayAlertSound(_ inSystemSoundID: SystemSoundID) {
    AudioToolboxPortable.record(inSystemSoundID)
}

public func AudioServicesPlaySystemSoundWithCompletion(
    _ inSystemSoundID: SystemSoundID,
    completionHandler: (() -> Void)?
) {
    AudioServicesPlaySystemSound(inSystemSoundID)
    completionHandler?()
}

public func AudioServicesCreateSystemSoundID(
    _ inFileURL: URL,
    _ outSystemSoundID: UnsafeMutablePointer<SystemSoundID>
) -> OSStatus {
    outSystemSoundID.pointee = 0
    return kAudioServicesUnsupportedPropertyError
}

public func AudioServicesDisposeSystemSoundID(
    _ inSystemSoundID: SystemSoundID
) -> OSStatus {
    kAudioServicesNoError
}

public struct AudioStreamBasicDescription: Sendable {
    public var mSampleRate: Double
    public var mFormatID: AudioFormatID
    public var mFormatFlags: AudioFormatFlags
    public var mBytesPerPacket: UInt32
    public var mFramesPerPacket: UInt32
    public var mBytesPerFrame: UInt32
    public var mChannelsPerFrame: UInt32
    public var mBitsPerChannel: UInt32
    public var mReserved: UInt32

    public init(
        mSampleRate: Double = 0,
        mFormatID: AudioFormatID = 0,
        mFormatFlags: AudioFormatFlags = 0,
        mBytesPerPacket: UInt32 = 0,
        mFramesPerPacket: UInt32 = 0,
        mBytesPerFrame: UInt32 = 0,
        mChannelsPerFrame: UInt32 = 0,
        mBitsPerChannel: UInt32 = 0,
        mReserved: UInt32 = 0
    ) {
        self.mSampleRate = mSampleRate
        self.mFormatID = mFormatID
        self.mFormatFlags = mFormatFlags
        self.mBytesPerPacket = mBytesPerPacket
        self.mFramesPerPacket = mFramesPerPacket
        self.mBytesPerFrame = mBytesPerFrame
        self.mChannelsPerFrame = mChannelsPerFrame
        self.mBitsPerChannel = mBitsPerChannel
        self.mReserved = mReserved
    }
}

public struct AudioBuffer {
    public var mNumberChannels: UInt32
    public var mDataByteSize: UInt32
    public var mData: UnsafeMutableRawPointer?

    public init(
        mNumberChannels: UInt32 = 0,
        mDataByteSize: UInt32 = 0,
        mData: UnsafeMutableRawPointer? = nil
    ) {
        self.mNumberChannels = mNumberChannels
        self.mDataByteSize = mDataByteSize
        self.mData = mData
    }
}

public struct AudioQueueBuffer {
    public var mAudioDataBytesCapacity: UInt32 = 0
    public var mAudioData: UnsafeMutableRawPointer?
    public var mAudioDataByteSize: UInt32 = 0
    public init() {}
}
