#if canImport(CoreAudioTypes)
import CoreAudioTypes
#endif
#if canImport(CoreFoundation)
import CoreFoundation
#endif
import Foundation

public typealias SystemSoundID = UInt32
public typealias AudioFileTypeID = UInt32
public typealias AudioFileID = OpaquePointer
public typealias AudioFilePropertyID = UInt32
public typealias AudioFileStreamID = OpaquePointer
public typealias AudioFileStreamPropertyID = UInt32
public typealias AudioFormatPropertyID = UInt32
public typealias AudioConverterRef = OpaquePointer
public typealias AudioConverterPropertyID = UInt32
public typealias AudioQueueRef = OpaquePointer
public typealias AudioQueueTimelineRef = OpaquePointer
public typealias AudioQueueProcessingTapRef = OpaquePointer
public typealias AudioQueuePropertyID = UInt32
public typealias AudioQueueParameterID = UInt32
public typealias AudioQueueParameterValue = Float32
public typealias AudioServicesPropertyID = UInt32
public typealias AudioComponent = OpaquePointer
public typealias AudioComponentInstance = OpaquePointer
public typealias AudioComponentMethod = OpaquePointer
public typealias AudioUnit = AudioComponentInstance
public typealias AudioUnitElement = UInt32
public typealias AudioUnitParameterID = UInt32
public typealias AudioUnitParameterValue = Float32
public typealias AudioUnitPropertyID = UInt32
public typealias AudioUnitScope = UInt32
public typealias AUGraph = OpaquePointer
public typealias AUNode = Int32
public typealias AUParameterListenerRef = OpaquePointer
public typealias AUEventListenerRef = AUParameterListenerRef
public typealias AUParameterAddress = UInt64
public typealias AUAudioFrameCount = UInt32
public typealias AUAudioChannelCount = UInt32
public typealias AUEventSampleTime = Int64
public typealias AUValue = Float
public typealias AUParameterObserverToken = UnsafeMutableRawPointer
public typealias AUParameterObserver = (AUParameterAddress, AUValue) -> Void
public typealias AUParameterAutomationObserver = (Int, UnsafePointer<AUParameterAutomationEvent>) -> Void
public typealias AUParameterRecordingObserver = (Int, UnsafePointer<AURecordedParameterEvent>) -> Void
public typealias AUImplementorValueObserver = (AUParameter, AUValue) -> Void
public typealias AUImplementorValueProvider = (AUParameter) -> AUValue
public typealias AUImplementorStringFromValueCallback = (AUParameter, UnsafePointer<AUValue>?) -> String
public typealias AUImplementorValueFromStringCallback = (AUParameter, String) -> AUValue
public typealias AUImplementorDisplayNameWithLengthCallback = (AUParameterNode, Int) -> String
public typealias AudioUnitPropertyListenerProc = @convention(c) (
    UnsafeMutableRawPointer?,
    AudioUnit?,
    AudioUnitPropertyID,
    AudioUnitScope,
    AudioUnitElement
) -> Void
public typealias AudioUnitAddPropertyListenerProc = (
    UnsafeMutableRawPointer?,
    AudioUnitPropertyID,
    AudioUnitPropertyListenerProc,
    UnsafeMutableRawPointer?
) -> Int32
public typealias AudioUnitRemovePropertyListenerProc = (
    UnsafeMutableRawPointer?,
    AudioUnitPropertyID,
    AudioUnitPropertyListenerProc
) -> Int32
public typealias AudioUnitRemovePropertyListenerWithUserDataProc = (
    UnsafeMutableRawPointer?,
    AudioUnitPropertyID,
    AudioUnitPropertyListenerProc,
    UnsafeMutableRawPointer?
) -> Int32
public typealias ExtAudioFileRef = OpaquePointer
public typealias ExtAudioFilePropertyID = UInt32
public typealias ExtAudioFilePacketTableInfoOverride = Int32
public typealias MusicPlayer = OpaquePointer
public typealias MusicSequence = OpaquePointer
public typealias MusicTrack = OpaquePointer
public typealias MusicEventIterator = OpaquePointer
public typealias MusicEventType = UInt32
public typealias MusicTimeStamp = Float64
public typealias MusicDeviceComponent = AudioComponentInstance
public typealias MusicDeviceGroupID = UInt32
public typealias MusicDeviceInstrumentID = UInt32
public typealias NoteInstanceID = UInt32
public typealias AudioCodec = AudioComponentInstance
public typealias AudioCodecPropertyID = UInt32

public let kInstrumentInfoKey_LSB = "LSB"
public let kInstrumentInfoKey_MSB = "MSB"
public let kInstrumentInfoKey_Name = "name"
public let kInstrumentInfoKey_Program = "program"

public let kAudioComponentConfigurationInfo_ValidationResult = "ValidationResult"
public let kAudioComponentValidationParameter_ForceValidation = "ForceValidation"
public let kAudioComponentValidationParameter_LoadOutOfProcess = "LoadOutOfProcess"
public let kAudioComponentValidationParameter_TimeOut = "TimeOut"

public let AUEventSampleTimeImmediate: AUEventSampleTime = -1
public let kSystemSoundID_Vibrate: SystemSoundID = 0x0000_0FFF
