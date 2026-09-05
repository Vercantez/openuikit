import CoreMIDI
import CoreFoundation
import Foundation

func testFailClosedClient() {
    let name = CFStringCreateWithCString(nil, "linux", CFStringBuiltInEncodings.UTF8.rawValue)!
    var client: MIDIClientRef = 99
    midiExpect(MIDIClientCreate(name, nil, nil, &client) == kMIDIServerStartErr, "client create")
    midiExpect(client == 0, "client out")
    midiExpect(MIDIClientCreateWithBlock(name, &client, nil) == kMIDIServerStartErr, "client block")
    midiExpect(MIDIClientDispose(1) == kMIDIInvalidClient, "dispose")
}

func testFailClosedPorts() {
    let name = CFStringCreateWithCString(nil, "port", CFStringBuiltInEncodings.UTF8.rawValue)!
    var port: MIDIPortRef = 99
    midiExpect(MIDIOutputPortCreate(0, name, &port) == kMIDINotPermitted && port == 0, "output port")
    midiExpect(MIDIInputPortCreate(0, name, { _, _, _ in }, nil, &port) == kMIDINotPermitted, "input proc")
    midiExpect(MIDIInputPortCreateWithBlock(0, name, &port, { _, _ in }) == kMIDINotPermitted, "input block")
    midiExpect(MIDIInputPortCreateWithProtocol(0, name, ._1_0, &port, { _, _ in }) == kMIDINotPermitted, "input proto")
    midiExpect(MIDIPortDispose(1) == kMIDIInvalidPort, "port dispose")
    midiExpect(MIDIPortConnectSource(0, 0, nil) == kMIDINoConnection, "connect")
    midiExpect(MIDIPortDisconnectSource(0, 0) == kMIDINoConnection, "disconnect")
}

func testFailClosedSend() {
    var list = MIDIPacketList()
    midiExpect(MIDISend(0, 0, &list) == kMIDINoConnection, "send")
    var events = MIDIEventList()
    midiExpect(MIDISendEventList(0, 0, &events) == kMIDINoConnection, "send events")
    midiExpect(MIDIReceived(0, &list) == kMIDIUnknownEndpoint, "received")
    midiExpect(MIDIReceivedEventList(0, &events) == kMIDIUnknownEndpoint, "received events")
    midiExpect(MIDIFlushOutput(0) == kMIDIUnknownEndpoint, "flush")
    midiExpect(MIDIRestart() == kMIDIServerStartErr, "restart")
    var bytes: [UInt8] = [0xF0, 0xF7]
    var request = MIDISysexSendRequest(
        destination: 0,
        data: &bytes,
        bytesToSend: 2,
        complete: false,
        reserved: (0, 0, 0),
        completionProc: { _ in },
        completionRefCon: nil
    )
    midiExpect(MIDISendSysex(&request) == kMIDINotPermitted, "sysex")
    var words: [UInt32] = [0]
    var ump = MIDISysexSendRequestUMP(
        destination: 0,
        words: &words,
        wordsToSend: 1,
        complete: false,
        completionProc: { _ in },
        completionRefCon: nil
    )
    midiExpect(MIDISendUMPSysex(&ump) == kMIDINotPermitted, "ump sysex")
    midiExpect(MIDISendUMPSysex8(&ump) == kMIDINotPermitted, "ump sysex8")
}

func testFailClosedGraph() {
    midiExpect(MIDIGetNumberOfDevices() == 0, "devices")
    midiExpect(MIDIGetNumberOfExternalDevices() == 0, "ext devices")
    midiExpect(MIDIGetNumberOfSources() == 0, "sources")
    midiExpect(MIDIGetNumberOfDestinations() == 0, "dests")
    midiExpect(MIDIGetDevice(0) == 0, "get device")
    midiExpect(MIDIGetExternalDevice(0) == 0, "get ext")
    midiExpect(MIDIGetSource(0) == 0, "get source")
    midiExpect(MIDIGetDestination(0) == 0, "get dest")
    midiExpect(MIDIDeviceGetNumberOfEntities(0) == 0, "dev entities")
    midiExpect(MIDIDeviceGetEntity(0, 0) == 0, "get entity")
    midiExpect(MIDIEntityGetNumberOfSources(0) == 0, "ent sources")
    midiExpect(MIDIEntityGetNumberOfDestinations(0) == 0, "ent dests")
    midiExpect(MIDIEntityGetSource(0, 0) == 0, "ent source")
    midiExpect(MIDIEntityGetDestination(0, 0) == 0, "ent dest")
    var device: MIDIDeviceRef = 99
    midiExpect(MIDIEntityGetDevice(0, &device) == kMIDIObjectNotFound && device == 0, "entity device")
    midiExpect(MIDIDeviceListGetNumberOfDevices(0) == 0, "list count")
    midiExpect(MIDIDeviceListGetDevice(0, 0) == 0, "list get")
    midiExpect(MIDIDeviceListAddDevice(0, 0) == kMIDINotPermitted, "list add")
    midiExpect(MIDIDeviceListDispose(0) == kMIDINotPermitted, "list dispose")
    withUnsafeTemporaryAllocation(of: UnsafeMutablePointer<MIDIDriverInterface>.self, capacity: 1) { buffer in
        midiExpect(MIDIGetDriverDeviceList(buffer.baseAddress!) == 0, "driver list")
    }
}

func testFailClosedEndpoints() {
    let name = CFStringCreateWithCString(nil, "ep", CFStringBuiltInEncodings.UTF8.rawValue)!
    var endpoint: MIDIEndpointRef = 99
    midiExpect(MIDIDestinationCreate(0, name, { _, _, _ in }, nil, &endpoint) == kMIDINotPermitted, "dest create")
    midiExpect(MIDIDestinationCreateWithBlock(0, name, &endpoint, { _, _ in }) == kMIDINotPermitted, "dest block")
    midiExpect(MIDIDestinationCreateWithProtocol(0, name, ._1_0, &endpoint, { _, _ in }) == kMIDINotPermitted, "dest proto")
    midiExpect(MIDISourceCreate(0, name, &endpoint) == kMIDINotPermitted, "source create")
    midiExpect(MIDISourceCreateWithProtocol(0, name, ._1_0, &endpoint) == kMIDINotPermitted, "source proto")
    midiExpect(MIDIEndpointDispose(1) == kMIDIUnknownEndpoint, "ep dispose")
    var entity: MIDIEntityRef = 99
    midiExpect(MIDIEndpointGetEntity(0, &entity) == kMIDIUnknownEndpoint, "ep entity")
    var ref1 = UnsafeMutableRawPointer(bitPattern: 1)!
    var ref2 = UnsafeMutableRawPointer(bitPattern: 2)!
    midiExpect(MIDIEndpointGetRefCons(0, &ref1, &ref2) == kMIDIUnknownEndpoint, "get refcons")
    midiExpect(MIDIEndpointSetRefCons(0, nil, nil) == kMIDIUnknownEndpoint, "set refcons")
}

func testFailClosedProperties() {
    let key = kMIDIPropertyName
    var object: MIDIObjectRef = 99
    var type = MIDIObjectType.device
    midiExpect(MIDIObjectFindByUniqueID(1, &object, &type) == kMIDIObjectNotFound, "find")
    midiExpect(object == 0 && type == .other, "find outs")
    var string: Unmanaged<CFString>? = Unmanaged.passUnretained(key)
    midiExpect(MIDIObjectGetStringProperty(0, key, &string) == kMIDIUnknownProperty, "get string")
    var integer: Int32 = 9
    midiExpect(MIDIObjectGetIntegerProperty(0, key, &integer) == kMIDIUnknownProperty, "get int")
    var data: Unmanaged<CFData>? = nil
    midiExpect(MIDIObjectGetDataProperty(0, key, &data) == kMIDIUnknownProperty, "get data")
    var dict: Unmanaged<CFDictionary>? = nil
    midiExpect(MIDIObjectGetDictionaryProperty(0, key, &dict) == kMIDIUnknownProperty, "get dict")
    var props: Unmanaged<CFPropertyList>? = nil
    midiExpect(MIDIObjectGetProperties(0, &props, false) == kMIDIUnknownProperty, "get props")
    midiExpect(MIDIObjectSetStringProperty(0, key, key) == kMIDINotPermitted, "set string")
    midiExpect(MIDIObjectSetIntegerProperty(0, key, 1) == kMIDINotPermitted, "set int")
    let cfData = CFDataCreate(nil, [], 0)!
    midiExpect(MIDIObjectSetDataProperty(0, key, cfData) == kMIDINotPermitted, "set data")
    let cfDict = CFDictionaryCreate(nil, nil, nil, 0, nil, nil)!
    midiExpect(MIDIObjectSetDictionaryProperty(0, key, cfDict) == kMIDINotPermitted, "set dict")
    midiExpect(MIDIObjectRemoveProperty(0, key) == kMIDIUnknownProperty, "remove")
}

func testFailClosedDeviceSetup() {
    let name = CFStringCreateWithCString(nil, "dev", CFStringBuiltInEncodings.UTF8.rawValue)!
    var device: MIDIDeviceRef = 99
    midiExpect(MIDIDeviceCreate(nil, name, name, name, &device) == kMIDINotPermitted, "device create")
    midiExpect(MIDIExternalDeviceCreate(name, name, name, &device) == kMIDINotPermitted, "ext create")
    midiExpect(MIDIDeviceDispose(1) == kMIDINotPermitted, "dispose")
    var entity: MIDIEntityRef = 99
    midiExpect(MIDIDeviceAddEntity(0, name, false, 0, 0, &entity) == kMIDINotPermitted, "add entity")
    midiExpect(MIDIDeviceNewEntity(0, name, ._1_0, false, 0, 0, &entity) == kMIDINotPermitted, "new entity")
    midiExpect(MIDIDeviceRemoveEntity(0, 0) == kMIDINotPermitted, "remove entity")
    midiExpect(MIDIEntityAddOrRemoveEndpoints(0, 0, 0) == kMIDINotPermitted, "add/remove ep")
    midiExpect(MIDISetupAddDevice(0) == kMIDINotPermitted, "setup add")
    midiExpect(MIDISetupAddExternalDevice(0) == kMIDINotPermitted, "setup add ext")
    midiExpect(MIDISetupRemoveDevice(0) == kMIDINotPermitted, "setup remove")
    midiExpect(MIDISetupRemoveExternalDevice(0) == kMIDINotPermitted, "setup remove ext")
}

func testFailClosedThruBluetooth() {
    midiExpect(MIDIBluetoothDriverActivateAllConnections() == kMIDINotPermitted, "bt activate")
    let uuid = CFStringCreateWithCString(nil, "uuid", CFStringBuiltInEncodings.UTF8.rawValue)!
    midiExpect(MIDIBluetoothDriverDisconnect(uuid) == kMIDINotPermitted, "bt disconnect")
    let data = CFDataCreate(nil, [], 0)!
    var connection: MIDIThruConnectionRef = 99
    midiExpect(MIDIThruConnectionCreate(nil, data, &connection) == kMIDINotPermitted, "thru create")
    midiExpect(MIDIThruConnectionDispose(1) == kMIDIObjectNotFound, "thru dispose")
    var found: Unmanaged<CFData> = Unmanaged.passUnretained(data)
    midiExpect(MIDIThruConnectionFind(nameCF(), &found) == kMIDINotPermitted, "thru find")
    midiExpect(MIDIThruConnectionGetParams(1, &found) == kMIDIObjectNotFound, "thru get")
    midiExpect(MIDIThruConnectionSetParams(1, data) == kMIDIObjectNotFound, "thru set")
    _ = MIDIGetDriverIORunLoop().takeUnretainedValue()
}

func nameCF() -> CFString {
    CFStringCreateWithCString(nil, "owner", CFStringBuiltInEncodings.UTF8.rawValue)!
}

func testNotificationsAndDriver() {
    var note = MIDINotification()
    midiExpect(note.messageID == .msgSetupChanged, "note init")
    note = MIDINotification(messageID: .msgIOError, messageSize: 8)
    midiExpect(note.messageSize > 0, "note size")
    var add = MIDIObjectAddRemoveNotification()
    midiExpect(add.childType == .other, "add/remove")
    add = MIDIObjectAddRemoveNotification(
        messageID: .msgObjectAdded,
        messageSize: 1,
        parent: 0,
        parentType: .device,
        child: 0,
        childType: .source
    )
    midiExpect(add.parentType == .device, "add memberwise")
    let change = MIDIObjectPropertyChangeNotification(
        messageID: .msgPropertyChanged,
        messageSize: 1,
        object: 0,
        objectType: .device,
        propertyName: Unmanaged.passUnretained(kMIDIPropertyName)
    )
    midiExpect(change.objectType == .device, "prop change")
    var io = MIDIIOErrorNotification()
    midiExpect(io.errorCode == kMIDIUnknownError, "io error")
    io = MIDIIOErrorNotification(messageID: .msgIOError, messageSize: 1, driverDevice: 0, errorCode: kMIDIUnknownError)
    midiExpect(io.errorCode == kMIDIUnknownError, "io memberwise")
    let driver = MIDIDriverInterface(
        QueryInterface: { _, _, _ in 0 },
        AddRef: { _ in 1 },
        Release: { _ in 0 },
        FindDevices: { _, _ in kMIDINotPermitted },
        Start: { _, _ in kMIDINotPermitted },
        Stop: { _ in kMIDINotPermitted },
        Configure: { _, _ in kMIDINotPermitted },
        Send: { _, _, _, _ in kMIDINotPermitted },
        EnableSource: { _, _, _ in kMIDINotPermitted },
        Flush: { _, _, _, _ in kMIDINotPermitted },
        Monitor: { _, _, _ in kMIDINotPermitted },
        SendPackets: { _, _, _, _ in kMIDINotPermitted },
        MonitorEvents: { _, _, _ in kMIDINotPermitted }
    )
    withUnsafeTemporaryAllocation(of: UnsafeMutablePointer<MIDIDriverInterface>.self, capacity: 1) { buffer in
        midiExpect(driver.Stop(buffer.baseAddress!) == kMIDINotPermitted, "driver stop")
    }
    _ = DarwinBoolean(true).boolValue
    let flag: DarwinBoolean = false
    midiExpect(!flag.boolValue, "darwin false")
}
