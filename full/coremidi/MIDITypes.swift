import CoreFoundation

// Remaining C overlay value types: messages, notifications, thru, driver, MIDI-CI IDs.

public struct MIDIMessage_64 {
    public var word0: UInt32
    public var word1: UInt32
    public init() { word0 = 0; word1 = 0 }
    public init(word0: UInt32, word1: UInt32) {
        self.word0 = word0
        self.word1 = word1
    }
}

public struct MIDIMessage_96 {
    public var word0: UInt32
    public var word1: UInt32
    public var word2: UInt32
    public init() { word0 = 0; word1 = 0; word2 = 0 }
    public init(word0: UInt32, word1: UInt32, word2: UInt32) {
        self.word0 = word0
        self.word1 = word1
        self.word2 = word2
    }
}

public struct MIDIMessage_128 {
    public var word0: UInt32
    public var word1: UInt32
    public var word2: UInt32
    public var word3: UInt32
    public init() { word0 = 0; word1 = 0; word2 = 0; word3 = 0 }
    public init(word0: UInt32, word1: UInt32, word2: UInt32, word3: UInt32) {
        self.word0 = word0
        self.word1 = word1
        self.word2 = word2
        self.word3 = word3
    }
}

public struct MIDINotification {
    public var messageID: MIDINotificationMessageID
    public var messageSize: UInt32
    public init() {
        messageID = .msgSetupChanged
        messageSize = UInt32(MemoryLayout<MIDINotification>.size)
    }
    public init(messageID: MIDINotificationMessageID, messageSize: UInt32) {
        self.messageID = messageID
        self.messageSize = messageSize
    }
}

public struct MIDIObjectAddRemoveNotification {
    public var messageID: MIDINotificationMessageID
    public var messageSize: UInt32
    public var parent: MIDIObjectRef
    public var parentType: MIDIObjectType
    public var child: MIDIObjectRef
    public var childType: MIDIObjectType
    public init() {
        messageID = .msgObjectAdded
        messageSize = UInt32(MemoryLayout<MIDIObjectAddRemoveNotification>.size)
        parent = 0
        parentType = .other
        child = 0
        childType = .other
    }
    public init(
        messageID: MIDINotificationMessageID,
        messageSize: UInt32,
        parent: MIDIObjectRef,
        parentType: MIDIObjectType,
        child: MIDIObjectRef,
        childType: MIDIObjectType
    ) {
        self.messageID = messageID
        self.messageSize = messageSize
        self.parent = parent
        self.parentType = parentType
        self.child = child
        self.childType = childType
    }
}

public struct MIDIObjectPropertyChangeNotification {
    public var messageID: MIDINotificationMessageID
    public var messageSize: UInt32
    public var object: MIDIObjectRef
    public var objectType: MIDIObjectType
    public var propertyName: Unmanaged<CFString>
    public init(
        messageID: MIDINotificationMessageID,
        messageSize: UInt32,
        object: MIDIObjectRef,
        objectType: MIDIObjectType,
        propertyName: Unmanaged<CFString>
    ) {
        self.messageID = messageID
        self.messageSize = messageSize
        self.object = object
        self.objectType = objectType
        self.propertyName = propertyName
    }
}

public struct MIDIIOErrorNotification {
    public var messageID: MIDINotificationMessageID
    public var messageSize: UInt32
    public var driverDevice: MIDIDeviceRef
    public var errorCode: OSStatus
    public init() {
        messageID = .msgIOError
        messageSize = UInt32(MemoryLayout<MIDIIOErrorNotification>.size)
        driverDevice = 0
        errorCode = kMIDIUnknownError
    }
    public init(
        messageID: MIDINotificationMessageID,
        messageSize: UInt32,
        driverDevice: MIDIDeviceRef,
        errorCode: OSStatus
    ) {
        self.messageID = messageID
        self.messageSize = messageSize
        self.driverDevice = driverDevice
        self.errorCode = errorCode
    }
}

public struct MIDITransform {
    public var transform: MIDITransformType
    public var param: Int16
    public init() {
        transform = .none
        param = 0
    }
    public init(transform: MIDITransformType, param: Int16) {
        self.transform = transform
        self.param = param
    }
}

public struct MIDIControlTransform {
    public var controlType: MIDITransformControlType
    public var remappedControlType: MIDITransformControlType
    public var controlNumber: UInt16
    public var transform: MIDITransformType
    public var param: Int16
    public init() {
        controlType = .controlType_7Bit
        remappedControlType = .controlType_7Bit
        controlNumber = 0
        transform = .none
        param = 0
    }
    public init(
        controlType: MIDITransformControlType,
        remappedControlType: MIDITransformControlType,
        controlNumber: UInt16,
        transform: MIDITransformType,
        param: Int16
    ) {
        self.controlType = controlType
        self.remappedControlType = remappedControlType
        self.controlNumber = controlNumber
        self.transform = transform
        self.param = param
    }
}

public struct MIDIValueMap {
    public var value: (
        UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
        UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
        UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
        UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
        UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
        UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
        UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
        UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
        UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
        UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
        UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
        UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
        UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
        UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
        UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
        UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8
    )
    public init() {
        var identity = MIDIValueMap.zeroTuple()
        withUnsafeMutableBytes(of: &identity) { raw in
            let buf = raw.bindMemory(to: UInt8.self)
            for i in 0..<128 { buf[i] = UInt8(i) }
        }
        value = identity
    }
    private static func zeroTuple() -> (
        UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
        UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
        UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
        UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
        UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
        UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
        UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
        UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
        UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
        UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
        UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
        UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
        UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
        UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
        UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
        UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8
    ) {
        (
            UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0),
            UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0),
            UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0),
            UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0),
            UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0),
            UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0),
            UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0),
            UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0),
            UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0),
            UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0),
            UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0),
            UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0),
            UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0),
            UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0),
            UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0),
            UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0)
        )
    }
    public init(value: (
        UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
        UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
        UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
        UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
        UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
        UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
        UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
        UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
        UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
        UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
        UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
        UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
        UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
        UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
        UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
        UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8
    )) {
        self.value = value
    }
}

public struct MIDIThruConnectionEndpoint {
    public var endpointRef: MIDIEndpointRef
    public var uniqueID: MIDIUniqueID
    public init() {
        endpointRef = 0
        uniqueID = kMIDIInvalidUniqueID
    }
    public init(endpointRef: MIDIEndpointRef, uniqueID: MIDIUniqueID) {
        self.endpointRef = endpointRef
        self.uniqueID = uniqueID
    }
}

public struct MIDISysexSendRequest {
    public var destination: MIDIEndpointRef
    public var data: UnsafePointer<UInt8>
    public var bytesToSend: UInt32
    public var complete: DarwinBoolean
    public var reserved: (UInt8, UInt8, UInt8)
    public var completionProc: MIDICompletionProc
    public var completionRefCon: UnsafeMutableRawPointer?
    public init(
        destination: MIDIEndpointRef,
        data: UnsafePointer<UInt8>,
        bytesToSend: UInt32,
        complete: DarwinBoolean,
        reserved: (UInt8, UInt8, UInt8),
        completionProc: @escaping MIDICompletionProc,
        completionRefCon: UnsafeMutableRawPointer?
    ) {
        self.destination = destination
        self.data = data
        self.bytesToSend = bytesToSend
        self.complete = complete
        self.reserved = reserved
        self.completionProc = completionProc
        self.completionRefCon = completionRefCon
    }
}

public struct MIDISysexSendRequestUMP {
    public var destination: MIDIEndpointRef
    public var words: UnsafeMutablePointer<UInt32>
    public var wordsToSend: UInt32
    public var complete: DarwinBoolean
    public var completionProc: MIDICompletionProcUMP
    public var completionRefCon: UnsafeMutableRawPointer?
    public init(
        destination: MIDIEndpointRef,
        words: UnsafeMutablePointer<UInt32>,
        wordsToSend: UInt32,
        complete: DarwinBoolean,
        completionProc: @escaping MIDICompletionProcUMP,
        completionRefCon: UnsafeMutableRawPointer?
    ) {
        self.destination = destination
        self.words = words
        self.wordsToSend = wordsToSend
        self.complete = complete
        self.completionProc = completionProc
        self.completionRefCon = completionRefCon
    }
}

public struct MIDI2DeviceManufacturer {
    public var sysExIDByte: (UInt8, UInt8, UInt8)
    public init() { sysExIDByte = (0, 0, 0) }
    public init(sysExIDByte: (UInt8, UInt8, UInt8)) { self.sysExIDByte = sysExIDByte }
}

public struct MIDI2DeviceRevisionLevel {
    public var revisionLevel: (UInt8, UInt8, UInt8, UInt8)
    public init() { revisionLevel = (0, 0, 0, 0) }
    public init(revisionLevel: (UInt8, UInt8, UInt8, UInt8)) { self.revisionLevel = revisionLevel }
}

public struct MIDICIProfileIDStandard {
    public var profileIDByte1: MIDIUInteger7
    public var profileBank: MIDIUInteger7
    public var profileNumber: MIDIUInteger7
    public var profileVersion: MIDIUInteger7
    public var profileLevel: MIDIUInteger7
    public init() {
        profileIDByte1 = 0
        profileBank = 0
        profileNumber = 0
        profileVersion = 0
        profileLevel = 0
    }
    public init(
        profileIDByte1: MIDIUInteger7,
        profileBank: MIDIUInteger7,
        profileNumber: MIDIUInteger7,
        profileVersion: MIDIUInteger7,
        profileLevel: MIDIUInteger7
    ) {
        self.profileIDByte1 = profileIDByte1
        self.profileBank = profileBank
        self.profileNumber = profileNumber
        self.profileVersion = profileVersion
        self.profileLevel = profileLevel
    }
}

public struct MIDICIProfileIDManufacturerSpecific {
    public var sysExID1: MIDIUInteger7
    public var sysExID2: MIDIUInteger7
    public var sysExID3: MIDIUInteger7
    public var info1: MIDIUInteger7
    public var info2: MIDIUInteger7
    public init() {
        sysExID1 = 0
        sysExID2 = 0
        sysExID3 = 0
        info1 = 0
        info2 = 0
    }
    public init(
        sysExID1: MIDIUInteger7,
        sysExID2: MIDIUInteger7,
        sysExID3: MIDIUInteger7,
        info1: MIDIUInteger7,
        info2: MIDIUInteger7
    ) {
        self.sysExID1 = sysExID1
        self.sysExID2 = sysExID2
        self.sysExID3 = sysExID3
        self.info1 = info1
        self.info2 = info2
    }
}

public struct MIDICIProfileID {
    public var standard: MIDICIProfileIDStandard
    public var manufacturerSpecific: MIDICIProfileIDManufacturerSpecific
    public init() {
        standard = MIDICIProfileIDStandard()
        manufacturerSpecific = MIDICIProfileIDManufacturerSpecific()
    }
    public init(standard: MIDICIProfileIDStandard) {
        self.standard = standard
        self.manufacturerSpecific = MIDICIProfileIDManufacturerSpecific()
    }
    public init(manufacturerSpecific: MIDICIProfileIDManufacturerSpecific) {
        self.standard = MIDICIProfileIDStandard()
        self.manufacturerSpecific = manufacturerSpecific
    }
}

public struct MIDICIDeviceIdentification {
    public var manufacturer: (UInt8, UInt8, UInt8)
    public var family: (UInt8, UInt8)
    public var modelNumber: (UInt8, UInt8)
    public var revisionLevel: (UInt8, UInt8, UInt8, UInt8)
    public var reserved: (UInt8, UInt8, UInt8, UInt8, UInt8)
    public init() {
        manufacturer = (0, 0, 0)
        family = (0, 0)
        modelNumber = (0, 0)
        revisionLevel = (0, 0, 0, 0)
        reserved = (0, 0, 0, 0, 0)
    }
    public init(
        manufacturer: (UInt8, UInt8, UInt8),
        family: (UInt8, UInt8),
        modelNumber: (UInt8, UInt8),
        revisionLevel: (UInt8, UInt8, UInt8, UInt8),
        reserved: (UInt8, UInt8, UInt8, UInt8, UInt8)
    ) {
        self.manufacturer = manufacturer
        self.family = family
        self.modelNumber = modelNumber
        self.revisionLevel = revisionLevel
        self.reserved = reserved
    }
}

public struct MIDIUniversalMessage {
    public var type: MIDIMessageType
    public var reserved: (UInt8, UInt8, UInt8)
    public var group: UInt8

    public struct __Unnamed_union___Anonymous_field3 {
        public struct __Unnamed_struct_channelVoice1 {
            public var channel: UInt8
            public var status: MIDICVStatus
            public var data1: UInt8
            public var data2: UInt8
            public init() {
                channel = 0
                status = .noteOn
                data1 = 0
                data2 = 0
            }
        }
        public struct __Unnamed_struct_channelVoice2 {
            public var channel: UInt8
            public var status: MIDICVStatus
            public var note: UInt8
            public var value: UInt32
            public init() {
                channel = 0
                status = .noteOn
                note = 0
                value = 0
            }
        }
        public struct __Unnamed_struct_sysEx {
            public var status: MIDISysExStatus
            public var bytesUsed: UInt8
            public init() {
                status = .complete
                bytesUsed = 0
            }
        }
        public struct __Unnamed_struct_system {
            public var status: MIDISystemStatus
            public init() { status = .statusTimingClock }
        }
        public struct __Unnamed_struct_utility {
            public var status: MIDIUtilityStatus
            public init() { status = .NOOP }
        }
        public struct __Unnamed_struct_data128 {
            public var wordCount: UInt8
            public init() { wordCount = 0 }
        }
        public struct __Unnamed_struct_unknown {
            public var word: UInt32
            public init() { word = 0 }
        }
    }

    public var channelVoice1: __Unnamed_union___Anonymous_field3.__Unnamed_struct_channelVoice1
    public var channelVoice2: __Unnamed_union___Anonymous_field3.__Unnamed_struct_channelVoice2
    public var sysEx: __Unnamed_union___Anonymous_field3.__Unnamed_struct_sysEx
    public var system: __Unnamed_union___Anonymous_field3.__Unnamed_struct_system
    public var utility: __Unnamed_union___Anonymous_field3.__Unnamed_struct_utility
    public var data128: __Unnamed_union___Anonymous_field3.__Unnamed_struct_data128
    public var unknown: __Unnamed_union___Anonymous_field3.__Unnamed_struct_unknown

    public init() {
        type = .invalid
        reserved = (0, 0, 0)
        group = 0
        channelVoice1 = .init()
        channelVoice2 = .init()
        sysEx = .init()
        system = .init()
        utility = .init()
        data128 = .init()
        unknown = .init()
    }
}

public struct MIDIDriverInterface {
    public var QueryInterface: (UnsafeMutableRawPointer, REFIID, UnsafeMutablePointer<LPVOID?>?) -> HRESULT
    public var AddRef: (UnsafeMutableRawPointer) -> ULONG
    public var Release: (UnsafeMutableRawPointer) -> ULONG
    public var FindDevices: (MIDIDriverRef, MIDIDeviceListRef) -> OSStatus
    public var Start: (MIDIDriverRef, MIDIDeviceListRef) -> OSStatus
    public var Stop: (MIDIDriverRef) -> OSStatus
    public var Configure: (MIDIDriverRef, MIDIDeviceRef) -> OSStatus
    public var Send: (MIDIDriverRef, UnsafePointer<MIDIPacketList>, UnsafeMutableRawPointer, UnsafeMutableRawPointer) -> OSStatus
    public var EnableSource: (MIDIDriverRef, MIDIEndpointRef, DarwinBoolean) -> OSStatus
    public var Flush: (MIDIDriverRef, MIDIEndpointRef, UnsafeMutableRawPointer?, UnsafeMutableRawPointer?) -> OSStatus
    public var Monitor: (MIDIDriverRef, MIDIEndpointRef, UnsafePointer<MIDIPacketList>) -> OSStatus
    public var SendPackets: (MIDIDriverRef, UnsafePointer<MIDIEventList>, UnsafeMutableRawPointer, UnsafeMutableRawPointer) -> OSStatus
    public var MonitorEvents: (MIDIDriverRef, MIDIEndpointRef, UnsafePointer<MIDIEventList>) -> OSStatus

    public init(
        QueryInterface: @escaping (UnsafeMutableRawPointer, REFIID, UnsafeMutablePointer<LPVOID?>?) -> HRESULT,
        AddRef: @escaping (UnsafeMutableRawPointer) -> ULONG,
        Release: @escaping (UnsafeMutableRawPointer) -> ULONG,
        FindDevices: @escaping (MIDIDriverRef, MIDIDeviceListRef) -> OSStatus,
        Start: @escaping (MIDIDriverRef, MIDIDeviceListRef) -> OSStatus,
        Stop: @escaping (MIDIDriverRef) -> OSStatus,
        Configure: @escaping (MIDIDriverRef, MIDIDeviceRef) -> OSStatus,
        Send: @escaping (MIDIDriverRef, UnsafePointer<MIDIPacketList>, UnsafeMutableRawPointer, UnsafeMutableRawPointer) -> OSStatus,
        EnableSource: @escaping (MIDIDriverRef, MIDIEndpointRef, DarwinBoolean) -> OSStatus,
        Flush: @escaping (MIDIDriverRef, MIDIEndpointRef, UnsafeMutableRawPointer?, UnsafeMutableRawPointer?) -> OSStatus,
        Monitor: @escaping (MIDIDriverRef, MIDIEndpointRef, UnsafePointer<MIDIPacketList>) -> OSStatus,
        SendPackets: @escaping (MIDIDriverRef, UnsafePointer<MIDIEventList>, UnsafeMutableRawPointer, UnsafeMutableRawPointer) -> OSStatus,
        MonitorEvents: @escaping (MIDIDriverRef, MIDIEndpointRef, UnsafePointer<MIDIEventList>) -> OSStatus
    ) {
        self.QueryInterface = QueryInterface
        self.AddRef = AddRef
        self.Release = Release
        self.FindDevices = FindDevices
        self.Start = Start
        self.Stop = Stop
        self.Configure = Configure
        self.Send = Send
        self.EnableSource = EnableSource
        self.Flush = Flush
        self.Monitor = Monitor
        self.SendPackets = SendPackets
        self.MonitorEvents = MonitorEvents
    }
}
