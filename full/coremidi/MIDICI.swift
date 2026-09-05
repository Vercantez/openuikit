import CoreFoundation
import Foundation

public final class MIDICIDeviceManager {
    public struct DictionaryKey: RawRepresentable, Hashable, Sendable {
        public var rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }
        public static let deviceObject = DictionaryKey(rawValue: "MIDICIDeviceObjectKey")
        public static let profileObject = DictionaryKey(rawValue: "MIDICIProfileObjectKey")
    }

    private static let sharedInstance = MIDICIDeviceManager()
    public class var shared: MIDICIDeviceManager { sharedInstance }
    private init() {}
    public var discoveredCIDevices: [MIDICIDevice] { [] }

    public class var deviceWasAddedNotification: NSNotification.Name {
        NSNotification.Name("MIDICIDeviceWasAddedNotification")
    }
    public class var deviceWasRemovedNotification: NSNotification.Name {
        NSNotification.Name("MIDICIDeviceWasRemovedNotification")
    }
    public class var profileWasRemovedNotification: NSNotification.Name {
        NSNotification.Name("MIDICIProfileWasRemovedNotification")
    }
    public class var profileWasUpdatedNotification: NSNotification.Name {
        NSNotification.Name("MIDICIProfileWasUpdatedNotification")
    }
}

public final class MIDI2DeviceInfo: NSObject {
    public let manufacturerID: MIDI2DeviceManufacturer
    public let family: MIDIUInteger14
    public let modelNumber: MIDIUInteger14
    public let revisionLevel: MIDI2DeviceRevisionLevel
    public init(
        manufacturerID: MIDI2DeviceManufacturer,
        family: MIDIUInteger14,
        modelNumber: MIDIUInteger14,
        revisionLevel: MIDI2DeviceRevisionLevel
    ) {
        self.manufacturerID = manufacturerID
        self.family = family
        self.modelNumber = modelNumber
        self.revisionLevel = revisionLevel
        super.init()
    }
}

public final class MIDICIDevice: NSObject {
    public var muid: MIDICIMUID { 0 }
    public var deviceInfo: MIDI2DeviceInfo
    public var deviceType: MIDICIDeviceType { .unknown }
    public var maxSysExSize: UInt { 0 }
    public var maxPropertyExchangeRequests: UInt { 0 }
    public var supportsProtocolNegotiation: Bool { false }
    public var supportsProfileConfiguration: Bool { false }
    public var supportsPropertyExchange: Bool { false }
    public var supportsProcessInquiry: Bool { false }
    public var profiles: [MIDIUMPCIProfile] { [] }
    init(deviceInfo: MIDI2DeviceInfo) {
        self.deviceInfo = deviceInfo
        super.init()
    }
}

public final class MIDICIDeviceInfo: NSObject, NSCoding {
    public let midiDestination: MIDIEndpointRef
    public let manufacturerID: Data
    public let family: Data
    public let modelNumber: Data
    public let revisionLevel: Data

    public init(
        destination midiDestination: MIDIEntityRef,
        manufacturer: Data,
        family: Data,
        model modelNumber: Data,
        revision: Data
    ) {
        self.midiDestination = midiDestination
        self.manufacturerID = manufacturer
        self.family = family
        self.modelNumber = modelNumber
        self.revisionLevel = revision
        super.init()
    }

    public required init?(coder: NSCoder) {
        _ = coder
        return nil
    }

    public func encode(with coder: NSCoder) {}
}

public final class MIDICIProfile: NSObject, NSCoding {
    public let name: String
    public let profileID: Data
    public init(data: Data) {
        self.profileID = data
        self.name = ""
        super.init()
    }
    public init(data: Data, name inName: String) {
        self.profileID = data
        self.name = inName
        super.init()
    }
    public required init?(coder: NSCoder) {
        _ = coder
        return nil
    }
    public func encode(with coder: NSCoder) {}
}

public final class MIDICIProfileState: NSObject, NSCoding {
    public let midiChannel: MIDIChannelNumber
    public let enabledProfiles: [MIDICIProfile]
    public let disabledProfiles: [MIDICIProfile]
    public init(channel midiChannelNum: MIDIChannelNumber, enabledProfiles enabled: [MIDICIProfile], disabledProfiles disabled: [MIDICIProfile]) {
        self.midiChannel = midiChannelNum
        self.enabledProfiles = enabled
        self.disabledProfiles = disabled
        super.init()
    }
    public init(enabledProfiles enabled: [MIDICIProfile], disabledProfiles disabled: [MIDICIProfile]) {
        self.midiChannel = MIDIChannelsWholePort
        self.enabledProfiles = enabled
        self.disabledProfiles = disabled
        super.init()
    }
    public required init?(coder: NSCoder) {
        _ = coder
        return nil
    }
    public func encode(with coder: NSCoder) {}
}

public final class MIDICIDiscoveredNode: NSObject, NSCoding {
    public let destination: MIDIEntityRef
    public let deviceInfo: MIDICIDeviceInfo
    public var maximumSysExSize: NSNumber { 0 }
    public var supportsProfiles: Bool { false }
    public var supportsProperties: Bool { false }
    public init(destination: MIDIEntityRef, deviceInfo: MIDICIDeviceInfo) {
        self.destination = destination
        self.deviceInfo = deviceInfo
        super.init()
    }
    public required init?(coder: NSCoder) {
        _ = coder
        return nil
    }
    public func encode(with coder: NSCoder) {}
}

public final class MIDICIDiscoveryManager: NSObject {
    private static let shared = MIDICIDiscoveryManager()
    public class func sharedInstance() -> MIDICIDiscoveryManager { shared }
    public func discover(handler completedHandler: @escaping MIDICIDiscoveryResponseBlock) {
        completedHandler([])
    }
}

public protocol MIDICIProfileResponderDelegate: AnyObject {
    func connectInitiator(_ initiatorMUID: MIDICIInitiatiorMUID, with deviceInfo: MIDICIDeviceInfo) -> Bool
    func initiatorDisconnected(_ initiatorMUID: MIDICIInitiatiorMUID)
    func handleData(for aProfile: MIDICIProfile, onChannel channel: MIDIChannelNumber, data inData: Data)
    func willSetProfile(_ aProfile: MIDICIProfile, onChannel channel: MIDIChannelNumber, enabled enabledState: Bool) -> Bool
}

extension MIDICIProfileResponderDelegate {
    public func handleData(for aProfile: MIDICIProfile, onChannel channel: MIDIChannelNumber, data inData: Data) {
        _ = aProfile; _ = channel; _ = inData
    }
    public func willSetProfile(_ aProfile: MIDICIProfile, onChannel channel: MIDIChannelNumber, enabled enabledState: Bool) -> Bool {
        _ = aProfile; _ = channel; _ = enabledState
        return true
    }
}

public final class MIDICIResponder: NSObject {
    public let deviceInfo: MIDICIDeviceInfo
    public let profileDelegate: any MIDICIProfileResponderDelegate
    public private(set) var initiators: [MIDICIInitiatiorMUID] = []
    private var running = false

    public init(
        deviceInfo: MIDICIDeviceInfo,
        profileDelegate delegate: any MIDICIProfileResponderDelegate,
        profileStates: [MIDICIProfileState],
        supportProperties: Bool
    ) {
        self.deviceInfo = deviceInfo
        self.profileDelegate = delegate
        _ = profileStates
        _ = supportProperties
        super.init()
    }

    public func start() -> Bool {
        running = false
        return false
    }

    public func stop() {
        running = false
        initiators = []
    }

    public func notify(_ aProfile: MIDICIProfile, onChannel channel: MIDIChannelNumber, isEnabled enabledState: Bool) -> Bool {
        _ = aProfile; _ = channel; _ = enabledState
        return false
    }

    public func send(_ aProfile: MIDICIProfile, onChannel channel: MIDIChannelNumber, profileData profileSpecificData: Data) -> Bool {
        _ = aProfile; _ = channel; _ = profileSpecificData
        return false
    }
}

public enum CoreMIDISessionError: Error {
    case notPermitted
}

public final class MIDICISession: NSObject {
    public let deviceInfo: MIDICIDeviceInfo
    public var midiDestination: MIDIEntityRef { 0 }
    public var supportsProfileCapability: Bool { false }
    public var supportsPropertyCapability: Bool { false }
    public var maxSysExSize: NSNumber { 0 }
    public var maxPropertyRequests: NSNumber { 0 }
    public var profileChangedCallback: MIDICIProfileChangedBlock?
    public var profileSpecificDataHandler: MIDICIProfileSpecificDataBlock?

    public init(
        discoveredNode: MIDICIDiscoveredNode,
        dataReadyHandler handler: @escaping () -> Void,
        disconnectHandler: @escaping MIDICISessionDisconnectBlock
    ) {
        self.deviceInfo = discoveredNode.deviceInfo
        super.init()
        handler()
        disconnectHandler(self, CoreMIDISessionError.notPermitted)
    }

    public func profileState(forChannel channel: MIDIChannelNumber) -> MIDICIProfileState {
        MIDICIProfileState(channel: channel, enabledProfiles: [], disabledProfiles: [])
    }

    public func enable(_ profile: MIDICIProfile, onChannel channel: MIDIChannelNumber) throws {
        _ = profile; _ = channel
        throw CoreMIDISessionError.notPermitted
    }

    public func disableProfile(_ profile: MIDICIProfile, onChannel channel: MIDIChannelNumber) throws {
        _ = profile; _ = channel
        throw CoreMIDISessionError.notPermitted
    }

    public func send(_ profile: MIDICIProfile, onChannel channel: MIDIChannelNumber, profileData profileSpecificData: Data) -> Bool {
        _ = profile; _ = channel; _ = profileSpecificData
        return false
    }
}
