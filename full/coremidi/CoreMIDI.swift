import CoreFoundation
import Foundation

// MARK: - Linux stand-ins for Darwin / COM types referenced by the overlay

public typealias OSStatus = Int32
public typealias HRESULT = Int32
public typealias ULONG = UInt32
public typealias LPVOID = UnsafeMutableRawPointer
public typealias REFIID = UnsafeRawPointer

/// Linux substitute for Darwin's `DarwinBoolean` used by CoreMIDI C structs.
public struct DarwinBoolean: ExpressibleByBooleanLiteral, Equatable, Hashable, Sendable {
    public var _value: UInt8

    public init(_ value: Bool) { _value = value ? 1 : 0 }
    public init(booleanLiteral value: Bool) { self.init(value) }
    public var boolValue: Bool { _value != 0 }
}

/// Linux stand-in for Foundation.NetService (Bonjour). Isolated guest Foundation
/// does not ship `NetService`; this type only carries name/domain identity.
public final class NetService: NSObject {
    public let name: String
    public let domain: String
    public init(name: String, domain: String = "") {
        self.name = name
        self.domain = domain
        super.init()
    }
}

func midiCFString(_ value: String) -> CFString {
    CFStringCreateWithCString(nil, value, CFStringBuiltInEncodings.UTF8.rawValue)!
}

// MARK: - Integer newtypes / object refs

public typealias MIDIUInteger2 = UInt8
public typealias MIDIUInteger4 = UInt8
public typealias MIDIUInteger7 = UInt8
public typealias MIDIUInteger14 = UInt16
public typealias MIDIUInteger28 = UInt32
public typealias MIDIChannelNumber = MIDIUInteger4
public typealias MIDITimeStamp = UInt64
public typealias MIDIUniqueID = Int32
public typealias MIDIObjectRef = UInt32
public typealias MIDIClientRef = MIDIObjectRef
public typealias MIDIPortRef = MIDIObjectRef
public typealias MIDIEndpointRef = MIDIObjectRef
public typealias MIDIDeviceRef = MIDIObjectRef
public typealias MIDIEntityRef = MIDIObjectRef
public typealias MIDIDeviceListRef = MIDIObjectRef
public typealias MIDISetupRef = MIDIObjectRef
public typealias MIDIThruConnectionRef = MIDIObjectRef
public typealias MIDIDriverRef = UnsafeMutablePointer<UnsafeMutablePointer<MIDIDriverInterface>>
public typealias MIDIMessage_32 = UInt32
public typealias MIDICIDeviceID = MIDIUInteger7
public typealias MIDICIMUID = MIDIUInteger28
public typealias MIDICIInitiatiorMUID = NSNumber
public typealias MIDIUMPFunctionBlockID = MIDIUInteger7
public typealias MIDIUMPGroupNumber = MIDIUInteger4

public let kMIDIUInteger2Max: MIDIUInteger2 = 0x3
public let kMIDIUInteger4Max: MIDIUInteger4 = 0xF
public let kMIDIUInteger7Max: MIDIUInteger7 = 0x7F
public let kMIDIUInteger14Max: MIDIUInteger14 = 0x3FFF
public let kMIDIUInteger28Max: MIDIUInteger28 = 0x0FFF_FFFF
public let kMIDI1UPMaxSysexSize: UInt8 = 6
public let kMIDIDeviceIDFunctionBlock: MIDICIDeviceID = 0x7F
public let kMIDIDeviceIDUMPGroup: MIDICIDeviceID = 0x7E
public let MIDIChannelsWholePort: MIDIChannelNumber = 0xFF
public let kMIDIInvalidUniqueID: MIDIUniqueID = 0
public let kMIDIThruConnection_MaxEndpoints: Int = 8

public var kMIDINoteAttributeNone: Int { 0 }
public var kMIDINoteAttributeManufacturerSpecific: Int { 1 }
public var kMIDINoteAttributeProfileSpecific: Int { 2 }
public var kMIDINoteAttributePitch: Int { 3 }

// MARK: - Error codes (MIDIServices.h / macios MidiError)

public var kMIDIInvalidClient: OSStatus { -10830 }
public var kMIDIInvalidPort: OSStatus { -10831 }
public var kMIDIWrongEndpointType: OSStatus { -10832 }
public var kMIDINoConnection: OSStatus { -10833 }
public var kMIDIUnknownEndpoint: OSStatus { -10834 }
public var kMIDIUnknownProperty: OSStatus { -10835 }
public var kMIDIWrongPropertyType: OSStatus { -10836 }
public var kMIDINoCurrentSetup: OSStatus { -10837 }
public var kMIDIMessageSendErr: OSStatus { -10838 }
public var kMIDIServerStartErr: OSStatus { -10839 }
public var kMIDISetupFormatErr: OSStatus { -10840 }
public var kMIDIWrongThread: OSStatus { -10841 }
public var kMIDIObjectNotFound: OSStatus { -10842 }
public var kMIDIIDNotUnique: OSStatus { -10843 }
public var kMIDINotPermitted: OSStatus { -10844 }
public var kMIDIUnknownError: OSStatus { -10845 }

// MARK: - Property keys (process-local CFString identity)

public let kMIDIPropertyName: CFString = midiCFString("name")
public let kMIDIPropertyDisplayName: CFString = midiCFString("displayName")
public let kMIDIPropertyManufacturer: CFString = midiCFString("manufacturer")
public let kMIDIPropertyModel: CFString = midiCFString("model")
public let kMIDIPropertyUniqueID: CFString = midiCFString("uniqueID")
public let kMIDIPropertyDeviceID: CFString = midiCFString("deviceID")
public let kMIDIPropertyImage: CFString = midiCFString("image")
public let kMIDIPropertyDriverOwner: CFString = midiCFString("driverOwner")
public let kMIDIPropertyDriverVersion: CFString = midiCFString("driverVersion")
public let kMIDIPropertyDriverDeviceEditorApp: CFString = midiCFString("driverDeviceEditorApp")
public let kMIDIPropertyConnectionUniqueID: CFString = midiCFString("connectionUniqueID")
public let kMIDIPropertyOffline: CFString = midiCFString("offline")
public let kMIDIPropertyPrivate: CFString = midiCFString("private")
public let kMIDIPropertyAdvanceScheduleTimeMuSec: CFString = midiCFString("advanceScheduleTimeMuSec")
public let kMIDIPropertyCanRoute: CFString = midiCFString("canRoute")
public let kMIDIPropertyIsEmbeddedEntity: CFString = midiCFString("isEmbeddedEntity")
public let kMIDIPropertyIsBroadcast: CFString = midiCFString("isBroadcast")
public let kMIDIPropertySingleRealtimeEntity: CFString = midiCFString("singleRealtimeEntity")
public let kMIDIPropertyMaxSysExSpeed: CFString = midiCFString("maxSysExSpeed")
public let kMIDIPropertySupportsGeneralMIDI: CFString = midiCFString("supportsGeneralMIDI")
public let kMIDIPropertySupportsMMC: CFString = midiCFString("supportsMMC")
public let kMIDIPropertySupportsShowControl: CFString = midiCFString("supportsShowControl")
public let kMIDIPropertyReceivesClock: CFString = midiCFString("receivesClock")
public let kMIDIPropertyReceivesMTC: CFString = midiCFString("receivesMTC")
public let kMIDIPropertyReceivesNotes: CFString = midiCFString("receivesNotes")
public let kMIDIPropertyReceivesProgramChanges: CFString = midiCFString("receivesProgramChanges")
public let kMIDIPropertyReceivesBankSelectMSB: CFString = midiCFString("receivesBankSelectMSB")
public let kMIDIPropertyReceivesBankSelectLSB: CFString = midiCFString("receivesBankSelectLSB")
public let kMIDIPropertyTransmitsClock: CFString = midiCFString("transmitsClock")
public let kMIDIPropertyTransmitsMTC: CFString = midiCFString("transmitsMTC")
public let kMIDIPropertyTransmitsNotes: CFString = midiCFString("transmitsNotes")
public let kMIDIPropertyTransmitsProgramChanges: CFString = midiCFString("transmitsProgramChanges")
public let kMIDIPropertyTransmitsBankSelectMSB: CFString = midiCFString("transmitsBankSelectMSB")
public let kMIDIPropertyTransmitsBankSelectLSB: CFString = midiCFString("transmitsBankSelectLSB")
public let kMIDIPropertyPanDisruptsStereo: CFString = midiCFString("panDisruptsStereo")
public let kMIDIPropertyIsSampler: CFString = midiCFString("isSampler")
public let kMIDIPropertyIsDrumMachine: CFString = midiCFString("isDrumMachine")
public let kMIDIPropertyIsMixer: CFString = midiCFString("isMixer")
public let kMIDIPropertyIsEffectUnit: CFString = midiCFString("isEffectUnit")
public let kMIDIPropertyMaxReceiveChannels: CFString = midiCFString("maxReceiveChannels")
public let kMIDIPropertyMaxTransmitChannels: CFString = midiCFString("maxTransmitChannels")
public let kMIDIPropertyReceiveChannels: CFString = midiCFString("receiveChannels")
public let kMIDIPropertyTransmitChannels: CFString = midiCFString("transmitChannels")
public let kMIDIPropertyNameConfiguration: CFString = midiCFString("nameConfiguration")
public let kMIDIPropertyNameConfigurationDictionary: CFString = midiCFString("nameConfigurationDictionary")
public let kMIDIPropertyAssociatedEndpoint: CFString = midiCFString("associatedEndpoint")
public let kMIDIPropertyProtocolID: CFString = midiCFString("protocolID")
public let kMIDIPropertyUMPActiveGroupBitmap: CFString = midiCFString("umpActiveGroupBitmap")
public let kMIDIPropertyUMPCanTransmitGroupless: CFString = midiCFString("umpCanTransmitGroupless")

public let MIDINetworkBonjourServiceType = "_apple-midi._udp"
public let MIDINetworkNotificationContactsDidChange = "MIDINetworkNotificationContactsDidChange"
public let MIDINetworkNotificationSessionDidChange = "MIDINetworkNotificationSessionDidChange"

// MARK: - Callbacks

public typealias MIDINotifyProc = (UnsafePointer<MIDINotification>, UnsafeMutableRawPointer?) -> Void
public typealias MIDINotifyBlock = (UnsafePointer<MIDINotification>) -> Void
public typealias MIDIReadProc = (UnsafePointer<MIDIPacketList>, UnsafeMutableRawPointer?, UnsafeMutableRawPointer?) -> Void
public typealias MIDIReadBlock = (UnsafePointer<MIDIPacketList>, UnsafeMutableRawPointer?) -> Void
public typealias MIDIReceiveBlock = (UnsafePointer<MIDIEventList>, UnsafeMutableRawPointer?) -> Void
public typealias MIDICompletionProc = (UnsafeMutablePointer<MIDISysexSendRequest>) -> Void
public typealias MIDICompletionProcUMP = (UnsafeMutablePointer<MIDISysexSendRequestUMP>) -> Void
public typealias MIDIEventVisitor = (UnsafeMutableRawPointer?, MIDITimeStamp, MIDIUniversalMessage) -> Void
public typealias MIDICIDiscoveryResponseBlock = ([MIDICIDiscoveredNode]) -> Void
public typealias MIDICIProfileChangedBlock = (MIDICISession, MIDIChannelNumber, MIDICIProfile, Bool) -> Void
public typealias MIDICIProfileSpecificDataBlock = (MIDICISession, MIDIChannelNumber, MIDICIProfile, Data) -> Void
public typealias MIDICISessionDisconnectBlock = (MIDICISession, any Error) -> Void

// MARK: - Enums

public enum MIDIProtocolID: Int32, Hashable, Sendable {
    case _1_0 = 1
    case _2_0 = 2
}

public enum MIDIObjectType: Int32, Hashable, Sendable {
    case other = -1
    case device = 0
    case entity = 1
    case source = 2
    case destination = 3
    case externalDevice = 0x10
    case externalEntity = 0x11
    case externalSource = 0x12
    case externalDestination = 0x13
}

public let kMIDIObjectType_ExternalMask: MIDIObjectType = MIDIObjectType(rawValue: 0x10)!

public enum MIDINotificationMessageID: Int32, Hashable, Sendable {
    case msgSetupChanged = 1
    case msgObjectAdded = 2
    case msgObjectRemoved = 3
    case msgPropertyChanged = 4
    case msgThruConnectionsChanged = 5
    case msgSerialPortOwnerChanged = 6
    case msgIOError = 7
    case msgInternalStart = 8
}

public enum MIDINetworkConnectionPolicy: UInt, Hashable, Sendable {
    case noOne = 0
    case hostsInContactList = 1
    case anyone = 2
}

public enum MIDITransformType: UInt16, Hashable, Sendable {
    case none = 0
    case filterOut = 1
    case mapControl = 2
    case add = 8
    case scale = 9
    case minValue = 10
    case maxValue = 11
    case mapValue = 12
}

public enum MIDITransformControlType: UInt8, Hashable, Sendable {
    case controlType_7Bit = 0
    case controlType_14Bit = 1
    case controlType_7BitRPN = 2
    case controlType_14BitRPN = 3
    case controlType_7BitNRPN = 4
    case controlType_14BitNRPN = 5
}

public enum MIDIMessageType: UInt32, Hashable, Sendable {
    case utility = 0
    case system = 1
    case channelVoice1 = 2
    case sysEx = 3
    case channelVoice2 = 4
    case data128 = 5
    case flexData = 0xD
    case unknownF = 0xF
    case invalid = 0xFF
    public static var stream: MIDIMessageType { .unknownF }
}

public enum MIDICVStatus: UInt32, Hashable, Sendable {
    case registeredPNC = 0
    case assignablePNC = 1
    case registeredControl = 2
    case assignableControl = 3
    case relRegisteredControl = 4
    case relAssignableControl = 5
    case perNotePitchBend = 6
    case noteOff = 8
    case noteOn = 9
    case polyPressure = 10
    case controlChange = 11
    case programChange = 12
    case channelPressure = 13
    case pitchBend = 14
    case perNoteMgmt = 15
}

public enum MIDISysExStatus: UInt32, Hashable, Sendable {
    case complete = 0
    case start = 1
    case `continue` = 2
    case end = 3
    case mixedDataSetHeader = 8
    case mixedDataSetPayload = 9
}

public enum MIDISystemStatus: UInt32, Hashable, Sendable {
    case statusStartOfExclusive = 240
    case statusMTC = 241
    case statusSongPosPointer = 242
    case statusSongSelect = 243
    case statusTuneRequest = 246
    case statusEndOfExclusive = 247
    case statusTimingClock = 248
    case statusStart = 250
    case statusContinue = 251
    case statusStop = 252
    case statusActiveSending = 254
    case statusSystemReset = 255
    public static var statusActiveSensing: MIDISystemStatus { .statusActiveSending }
}

public enum MIDINoteAttribute: UInt8, Hashable, Sendable {
    case none = 0
    case manufacturerSpecific = 1
    case profileSpecific = 2
    case pitch = 3
}

public enum MIDIUtilityStatus: UInt32, Hashable, Sendable {
    case NOOP = 0
    case jitterReductionClock = 1
    case jitterReductionTimestamp = 2
    case deltaClockstampTicksPerQuarterNote = 3
    case ticksSinceLastEvent = 4
}

public enum UMPStreamMessageStatus: UInt32, Hashable, Sendable {
    case endpointDiscovery = 0x00
    case endpointInfoNotification = 0x01
    case deviceIdentityNotification = 0x02
    case endpointNameNotification = 0x03
    case productInstanceIDNotification = 0x04
    case streamConfigurationRequest = 0x05
    case streamConfigurationNotification = 0x06
    case functionBlockDiscovery = 0x10
    case functionBlockInfoNotification = 0x11
    case functionBlockNameNotification = 0x12
    case startOfClip = 0x20
    case endOfClip = 0x21
}

public enum UMPStreamMessageFormat: UInt8, Hashable, Sendable {
    case complete = 0x00
    case start = 0x01
    case continuing = 0x02
    case end = 0x03
}

public enum MIDIUMPFunctionBlockMIDI1Info: Int32, Hashable, Sendable {
    case notMIDI1 = 0
    case unrestrictedBandwidth = 1
    case restrictedBandwidth = 2
}

public enum MIDIUMPFunctionBlockUIHint: Int32, Hashable, Sendable {
    case unknown = 0
    case receiver = 1
    case sender = 2
    case senderReceiver = 3
}

public enum MIDIUMPFunctionBlockDirection: Int32, Hashable, Sendable {
    case unknown = 0
    case input = 1
    case output = 2
    case bidirectional = 3
}

public enum MIDICIDeviceType: UInt8, Hashable, Sendable {
    case unknown = 0
    case legacyMIDI1 = 1
    case virtual = 2
    case usbMIDI = 3
}

public enum MIDICIProfileMessageType: MIDIUInteger7, Hashable, Sendable {
    case profileInquiry = 0x20
    case replyToProfileInquiry = 0x21
    case setProfileOn = 0x22
    case setProfileOff = 0x23
    case profileEnabledReport = 0x24
    case profileDisabledReport = 0x25
    case profileAdded = 0x26
    case profileRemoved = 0x27
    case detailsInquiry = 0x28
    case replyToDetailsInquiry = 0x29
    case profileSpecificData = 0x2F
}

public enum MIDICIPropertyExchangeMessageType: MIDIUInteger7, Hashable, Sendable {
    case inquiryPropertyExchangeCapabilities = 0x30
    case replyToPropertyExchangeCapabilities = 0x31
    case inquiryHasPropertyData_Reserved = 0x32
    case inquiryReplyToHasPropertyData_Reserved = 0x33
    case inquiryGetPropertyData = 0x34
    case replyToGetProperty = 0x35
    case inquirySetPropertyData = 0x36
    case replyToSetPropertyData = 0x37
    case subscription = 0x38
    case replyToSubscription = 0x39
    case notify = 0x3F
}

public enum MIDICIProcessInquiryMessageType: MIDIUInteger7, Hashable, Sendable {
    case inquiryProcessInquiryCapabilities = 0x40
    case replyToProcessInquiryCapabilities = 0x41
    case inquiryMIDIMessageReport = 0x42
    case replyToMIDIMessageReport = 0x43
    case endOfMIDIMessageReport = 0x44
}

public enum MIDICIManagementMessageType: MIDIUInteger7, Hashable, Sendable {
    case discovery = 0x70
    case replyToDiscovery = 0x71
    case inquiryEndpointInformation = 0x72
    case replyToEndpointInformation = 0x73
    case midiCIACK = 0x7D
    case invalidateMUID = 0x7E
    case midiNAK = 0x7F
}

public enum MIDICIProfileType: UInt8, Hashable, Sendable {
    case singleChannel = 1
    case group = 2
    case functionBlock = 3
    case multichannel = 4
}

public enum MIDIUMPCIObjectBackingType: UInt8, Hashable, Sendable {
    case unknown = 0
    case virtual = 1
    case driverDevice = 2
    case usbMIDI = 3
}

// MARK: - Option sets

public struct MIDICICategoryOptions: OptionSet, Hashable, Sendable {
    public let rawValue: MIDIUInteger7
    public init(rawValue: MIDIUInteger7) { self.rawValue = rawValue }
    public static var protocolNegotiation: MIDICICategoryOptions { MIDICICategoryOptions(rawValue: 1 << 1) }
    public static var profileConfigurationSupported: MIDICICategoryOptions { MIDICICategoryOptions(rawValue: 1 << 2) }
    public static var propertyExchangeSupported: MIDICICategoryOptions { MIDICICategoryOptions(rawValue: 1 << 3) }
    public static var processInquirySupported: MIDICICategoryOptions { MIDICICategoryOptions(rawValue: 1 << 4) }
}

public struct MIDIPerNoteManagementOptions: OptionSet, Hashable, Sendable {
    public let rawValue: UInt8
    public init(rawValue: UInt8) { self.rawValue = rawValue }
    public static var reset: MIDIPerNoteManagementOptions { MIDIPerNoteManagementOptions(rawValue: 1 << 0) }
    public static var detach: MIDIPerNoteManagementOptions { MIDIPerNoteManagementOptions(rawValue: 1 << 1) }
}

public struct MIDIProgramChangeOptions: OptionSet, Hashable, Sendable {
    public let rawValue: UInt8
    public init(rawValue: UInt8) { self.rawValue = rawValue }
    public static var bankValid: MIDIProgramChangeOptions { MIDIProgramChangeOptions(rawValue: 1 << 0) }
}

public struct MIDIUMPProtocolOptions: OptionSet, Hashable, Sendable {
    public let rawValue: MIDIUInteger4
    public init(rawValue: MIDIUInteger4) { self.rawValue = rawValue }
    public static var midi1: MIDIUMPProtocolOptions { MIDIUMPProtocolOptions(rawValue: 1) }
    public static var midi2: MIDIUMPProtocolOptions { MIDIUMPProtocolOptions(rawValue: 1 << 1) }
}

public struct MIDICIPropertyExchangeRequestID: RawRepresentable, Hashable, Sendable {
    public var rawValue: UInt8
    public init(rawValue: UInt8) { self.rawValue = rawValue }
    public init(_ rawValue: UInt8) { self.rawValue = rawValue }
    public static var badRequestID: MIDICIPropertyExchangeRequestID { MIDICIPropertyExchangeRequestID(rawValue: 0xFF) }
}
