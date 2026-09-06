import Foundation

public final class MIDIUMPEndpointManager {
    public struct DictionaryKey: RawRepresentable, Hashable, Sendable {
        public var rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }
        public static let endpointObject = DictionaryKey(rawValue: "MIDIUMPEndpointObjectKey")
        public static let functionBlockObject = DictionaryKey(rawValue: "MIDIUMPFunctionBlockObjectKey")
    }

    private static let sharedInstance = MIDIUMPEndpointManager()
    public class var shared: MIDIUMPEndpointManager { sharedInstance }
    private init() {}
    public var umpEndpoints: [MIDIUMPEndpoint] { [] }

    public class var endpointWasAddedNotification: NSNotification.Name {
        NSNotification.Name("MIDIUMPEndpointWasAddedNotification")
    }
    public class var endpointWasRemovedNotification: NSNotification.Name {
        NSNotification.Name("MIDIUMPEndpointWasRemovedNotification")
    }
    public class var endpointWasUpdatedNotification: NSNotification.Name {
        NSNotification.Name("MIDIUMPEndpointWasUpdatedNotification")
    }
    public class var functionBlockWasUpdatedNotification: NSNotification.Name {
        NSNotification.Name("MIDIUMPFunctionBlockWasUpdatedNotification")
    }
}

public class MIDIUMPCIProfile: NSObject {
    public let name: String
    public let profileID: MIDICIProfileID
    public let profileType: MIDICIProfileType
    public let groupOffset: MIDIUMPGroupNumber
    public let firstChannel: MIDIChannelNumber
    public private(set) var isEnabled: Bool
    public private(set) var enabledChannelCount: MIDIUInteger14
    public let totalChannelCount: MIDIUInteger14

    public init(
        name: String = "",
        profileID: MIDICIProfileID = MIDICIProfileID(),
        profileType: MIDICIProfileType = .singleChannel,
        groupOffset: MIDIUMPGroupNumber = 0,
        firstChannel: MIDIChannelNumber = 0,
        totalChannelCount: MIDIUInteger14 = 1
    ) {
        self.name = name
        self.profileID = profileID
        self.profileType = profileType
        self.groupOffset = groupOffset
        self.firstChannel = firstChannel
        self.isEnabled = false
        self.enabledChannelCount = 0
        self.totalChannelCount = totalChannelCount
        super.init()
    }

    public func setProfileState(_ isEnabled: Bool, enabledChannelCount: MIDIUInteger14) throws {
        _ = isEnabled
        _ = enabledChannelCount
        throw CoreMIDISessionError.notPermitted
    }
}

public class MIDIUMPEndpoint: NSObject {
    public var name: String
    public var midiProtocol: MIDIProtocolID
    public var supportedMIDIProtocols: MIDIUMPProtocolOptions
    public var midiDestination: MIDIEndpointRef { 0 }
    public var midiSource: MIDIEndpointRef { 0 }
    public var deviceInfo: MIDI2DeviceInfo
    public var productInstanceID: String
    public var hasStaticFunctionBlocks: Bool
    public var hasJRTSReceiveCapability: Bool { false }
    public var hasJRTSTransmitCapability: Bool { false }
    public var endpointType: MIDIUMPCIObjectBackingType
    public var functionBlocks: [MIDIUMPFunctionBlock]

    public init(
        name: String,
        deviceInfo: MIDI2DeviceInfo,
        productInstanceID: String,
        midiProtocol: MIDIProtocolID,
        endpointType: MIDIUMPCIObjectBackingType = .unknown
    ) {
        self.name = name
        self.deviceInfo = deviceInfo
        self.productInstanceID = productInstanceID
        self.midiProtocol = midiProtocol
        self.supportedMIDIProtocols = []
        self.hasStaticFunctionBlocks = false
        self.endpointType = endpointType
        self.functionBlocks = []
        super.init()
    }
}

public class MIDIUMPFunctionBlock: NSObject {
    public var name: String
    public var functionBlockID: MIDIUMPFunctionBlockID
    public var direction: MIDIUMPFunctionBlockDirection
    public var firstGroup: MIDIUMPGroupNumber
    public var totalGroupsSpanned: MIDIUInteger7
    public var maxSysEx8Streams: UInt8
    public var midi1Info: MIDIUMPFunctionBlockMIDI1Info
    public var uiHint: MIDIUMPFunctionBlockUIHint
    public var isEnabled: Bool
    public weak var umpEndpoint: MIDIUMPEndpoint?
    public weak var midiCIDevice: MIDICIDevice?

    init(
        blockName: String,
        direction: MIDIUMPFunctionBlockDirection,
        firstGroup: MIDIUMPGroupNumber,
        totalGroupsSpanned: MIDIUInteger7,
        maxSysEx8Streams: UInt8,
        midi1Info: MIDIUMPFunctionBlockMIDI1Info,
        uiHint: MIDIUMPFunctionBlockUIHint,
        isEnabled: Bool
    ) {
        self.name = blockName
        self.functionBlockID = 0
        self.direction = direction
        self.firstGroup = firstGroup
        self.totalGroupsSpanned = totalGroupsSpanned
        self.maxSysEx8Streams = maxSysEx8Streams
        self.midi1Info = midi1Info
        self.uiHint = uiHint
        self.isEnabled = isEnabled
        super.init()
    }
}

public final class MIDIUMPMutableEndpoint: MIDIUMPEndpoint {
    public private(set) var isEnabled: Bool = false
    public var mutableFunctionBlocks: [MIDIUMPMutableFunctionBlock] = []

    public init?(
        name: String,
        deviceInfo: MIDI2DeviceInfo,
        productInstanceID: String,
        midiProtocol MIDIProtocol: MIDIProtocolID,
        destinationCallback: @escaping MIDIReceiveBlock
    ) {
        _ = destinationCallback
        super.init(
            name: name,
            deviceInfo: deviceInfo,
            productInstanceID: productInstanceID,
            midiProtocol: MIDIProtocol,
            endpointType: .virtual
        )
    }

    public convenience init?(
        name: String,
        deviceInfo: MIDI2DeviceInfo,
        productInstanceID: String,
        MIDIProtocol: MIDIProtocolID,
        destinationCallback: @escaping MIDIReceiveBlock
    ) {
        self.init(
            name: name,
            deviceInfo: deviceInfo,
            productInstanceID: productInstanceID,
            midiProtocol: MIDIProtocol,
            destinationCallback: destinationCallback
        )
    }

    public func setName(_ name: String) throws {
        _ = name
        throw CoreMIDISessionError.notPermitted
    }

    public func setEnabled(_ isEnabled: Bool) throws {
        _ = isEnabled
        throw CoreMIDISessionError.notPermitted
    }

    public func registerFunctionBlocks(_ functionBlocks: [MIDIUMPMutableFunctionBlock], markAsStatic: Bool) throws {
        _ = functionBlocks
        _ = markAsStatic
        throw CoreMIDISessionError.notPermitted
    }
}

public final class MIDIUMPMutableFunctionBlock: MIDIUMPFunctionBlock {
    public override var umpEndpoint: MIDIUMPEndpoint? {
        get { super.umpEndpoint }
        set { super.umpEndpoint = newValue }
    }

    public var mutableEndpoint: MIDIUMPMutableEndpoint? {
        umpEndpoint as? MIDIUMPMutableEndpoint
    }

    public init?(
        name: String,
        direction: MIDIUMPFunctionBlockDirection,
        firstGroup: MIDIUMPGroupNumber,
        totalGroupsSpanned: MIDIUInteger7,
        maxSysEx8Streams: UInt8,
        midi1Info: MIDIUMPFunctionBlockMIDI1Info,
        uiHint: MIDIUMPFunctionBlockUIHint,
        isEnabled: Bool
    ) {
        super.init(
            blockName: name,
            direction: direction,
            firstGroup: firstGroup,
            totalGroupsSpanned: totalGroupsSpanned,
            maxSysEx8Streams: maxSysEx8Streams,
            midi1Info: midi1Info,
            uiHint: uiHint,
            isEnabled: isEnabled
        )
    }

    public convenience init?(
        name: String,
        direction: MIDIUMPFunctionBlockDirection,
        firstGroup: MIDIUMPGroupNumber,
        totalGroupsSpanned: MIDIUInteger7,
        maxSysEx8Streams: UInt8,
        MIDI1Info: MIDIUMPFunctionBlockMIDI1Info,
        UIHint: MIDIUMPFunctionBlockUIHint,
        isEnabled: Bool
    ) {
        self.init(
            name: name,
            direction: direction,
            firstGroup: firstGroup,
            totalGroupsSpanned: totalGroupsSpanned,
            maxSysEx8Streams: maxSysEx8Streams,
            midi1Info: MIDI1Info,
            uiHint: UIHint,
            isEnabled: isEnabled
        )
    }

    public func setName(_ name: String) throws {
        _ = name
        throw CoreMIDISessionError.notPermitted
    }

    public func setEnabled(_ isEnabled: Bool) throws {
        _ = isEnabled
        throw CoreMIDISessionError.notPermitted
    }

    public func reconfigure(
        firstGroup: MIDIUMPGroupNumber,
        direction: MIDIUMPFunctionBlockDirection,
        MIDI1Info: MIDIUMPFunctionBlockMIDI1Info,
        UIHint: MIDIUMPFunctionBlockUIHint
    ) -> Bool {
        _ = firstGroup
        _ = direction
        _ = MIDI1Info
        _ = UIHint
        return false
    }
}
