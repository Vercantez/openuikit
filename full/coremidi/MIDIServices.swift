import CoreFoundation

// Fail-closed MIDI services: no Apple MIDIServer, driver host, or hardware graph.

private func midiRefuse(_ out: UnsafeMutablePointer<MIDIObjectRef>? = nil) -> OSStatus {
    out?.pointee = 0
    return kMIDINotPermitted
}

public func MIDIGetNumberOfDevices() -> Int { 0 }
public func MIDIGetNumberOfExternalDevices() -> Int { 0 }
public func MIDIGetNumberOfSources() -> Int { 0 }
public func MIDIGetNumberOfDestinations() -> Int { 0 }
public func MIDIGetDevice(_ deviceIndex0: Int) -> MIDIDeviceRef { 0 }
public func MIDIGetExternalDevice(_ deviceIndex0: Int) -> MIDIDeviceRef { 0 }
public func MIDIGetSource(_ sourceIndex0: Int) -> MIDIEndpointRef { 0 }
public func MIDIGetDestination(_ destIndex0: Int) -> MIDIEndpointRef { 0 }

public func MIDIClientCreate(
    _ name: CFString,
    _ notifyProc: MIDINotifyProc?,
    _ notifyRefCon: UnsafeMutableRawPointer?,
    _ outClient: UnsafeMutablePointer<MIDIClientRef>
) -> OSStatus {
    _ = name; _ = notifyProc; _ = notifyRefCon
    outClient.pointee = 0
    return kMIDIServerStartErr
}

public func MIDIClientCreateWithBlock(
    _ name: CFString,
    _ outClient: UnsafeMutablePointer<MIDIClientRef>,
    _ notifyBlock: MIDINotifyBlock?
) -> OSStatus {
    _ = name; _ = notifyBlock
    outClient.pointee = 0
    return kMIDIServerStartErr
}

public func MIDIClientDispose(_ client: MIDIClientRef) -> OSStatus {
    _ = client
    return kMIDIInvalidClient
}

public func MIDIInputPortCreate(
    _ client: MIDIClientRef, _ portName: CFString, _ readProc: MIDIReadProc,
    _ refCon: UnsafeMutableRawPointer?, _ outPort: UnsafeMutablePointer<MIDIPortRef>
) -> OSStatus {
    _ = client; _ = portName; _ = readProc; _ = refCon
    return midiRefuse(outPort)
}

public func MIDIInputPortCreateWithBlock(
    _ client: MIDIClientRef, _ portName: CFString,
    _ outPort: UnsafeMutablePointer<MIDIPortRef>, _ readBlock: @escaping MIDIReadBlock
) -> OSStatus {
    _ = client; _ = portName; _ = readBlock
    return midiRefuse(outPort)
}

public func MIDIInputPortCreateWithProtocol(
    _ client: MIDIClientRef, _ portName: CFString, _ protocol: MIDIProtocolID,
    _ outPort: UnsafeMutablePointer<MIDIPortRef>, _ receiveBlock: @escaping MIDIReceiveBlock
) -> OSStatus {
    _ = client; _ = portName; _ = `protocol`; _ = receiveBlock
    return midiRefuse(outPort)
}

public func MIDIOutputPortCreate(
    _ client: MIDIClientRef, _ portName: CFString, _ outPort: UnsafeMutablePointer<MIDIPortRef>
) -> OSStatus {
    _ = client; _ = portName
    return midiRefuse(outPort)
}

public func MIDIPortDispose(_ port: MIDIPortRef) -> OSStatus {
    _ = port
    return kMIDIInvalidPort
}

public func MIDIPortConnectSource(_ port: MIDIPortRef, _ source: MIDIEndpointRef, _ connRefCon: UnsafeMutableRawPointer?) -> OSStatus {
    _ = port; _ = source; _ = connRefCon
    return kMIDINoConnection
}

public func MIDIPortDisconnectSource(_ port: MIDIPortRef, _ source: MIDIEndpointRef) -> OSStatus {
    _ = port; _ = source
    return kMIDINoConnection
}

public func MIDIDestinationCreate(
    _ client: MIDIClientRef, _ name: CFString, _ readProc: MIDIReadProc,
    _ refCon: UnsafeMutableRawPointer?, _ outDest: UnsafeMutablePointer<MIDIEndpointRef>
) -> OSStatus {
    _ = client; _ = name; _ = readProc; _ = refCon
    return midiRefuse(outDest)
}

public func MIDIDestinationCreateWithBlock(
    _ client: MIDIClientRef, _ name: CFString,
    _ outDest: UnsafeMutablePointer<MIDIEndpointRef>, _ readBlock: @escaping MIDIReadBlock
) -> OSStatus {
    _ = client; _ = name; _ = readBlock
    return midiRefuse(outDest)
}

public func MIDIDestinationCreateWithProtocol(
    _ client: MIDIClientRef, _ name: CFString, _ protocol: MIDIProtocolID,
    _ outDest: UnsafeMutablePointer<MIDIEndpointRef>, _ readBlock: @escaping MIDIReceiveBlock
) -> OSStatus {
    _ = client; _ = name; _ = `protocol`; _ = readBlock
    return midiRefuse(outDest)
}

public func MIDISourceCreate(
    _ client: MIDIClientRef, _ name: CFString, _ outSrc: UnsafeMutablePointer<MIDIEndpointRef>
) -> OSStatus {
    _ = client; _ = name
    return midiRefuse(outSrc)
}

public func MIDISourceCreateWithProtocol(
    _ client: MIDIClientRef, _ name: CFString, _ protocol: MIDIProtocolID,
    _ outSrc: UnsafeMutablePointer<MIDIEndpointRef>
) -> OSStatus {
    _ = client; _ = name; _ = `protocol`
    return midiRefuse(outSrc)
}

public func MIDIEndpointDispose(_ endpt: MIDIEndpointRef) -> OSStatus {
    _ = endpt
    return kMIDIUnknownEndpoint
}

public func MIDIEndpointGetEntity(_ inEndpoint: MIDIEndpointRef, _ outEntity: UnsafeMutablePointer<MIDIEntityRef>?) -> OSStatus {
    _ = inEndpoint
    outEntity?.pointee = 0
    return kMIDIUnknownEndpoint
}

public func MIDIEndpointGetRefCons(
    _ endpt: MIDIEndpointRef,
    _ ref1: UnsafeMutablePointer<UnsafeMutableRawPointer>?,
    _ ref2: UnsafeMutablePointer<UnsafeMutableRawPointer>?
) -> OSStatus {
    _ = endpt
    _ = ref1
    _ = ref2
    return kMIDIUnknownEndpoint
}

public func MIDIEndpointSetRefCons(_ endpt: MIDIEndpointRef, _ ref1: UnsafeMutableRawPointer?, _ ref2: UnsafeMutableRawPointer?) -> OSStatus {
    _ = endpt; _ = ref1; _ = ref2
    return kMIDIUnknownEndpoint
}

public func MIDISend(_ port: MIDIPortRef, _ dest: MIDIEndpointRef, _ pktlist: UnsafePointer<MIDIPacketList>) -> OSStatus {
    _ = port; _ = dest; _ = pktlist
    return kMIDINoConnection
}

public func MIDISendEventList(_ port: MIDIPortRef, _ dest: MIDIEndpointRef, _ evtlist: UnsafePointer<MIDIEventList>) -> OSStatus {
    _ = port; _ = dest; _ = evtlist
    return kMIDINoConnection
}

public func MIDIReceived(_ src: MIDIEndpointRef, _ pktlist: UnsafePointer<MIDIPacketList>) -> OSStatus {
    _ = src; _ = pktlist
    return kMIDIUnknownEndpoint
}

public func MIDIReceivedEventList(_ src: MIDIEndpointRef, _ evtlist: UnsafePointer<MIDIEventList>) -> OSStatus {
    _ = src; _ = evtlist
    return kMIDIUnknownEndpoint
}

public func MIDIFlushOutput(_ dest: MIDIEndpointRef) -> OSStatus {
    _ = dest
    return kMIDIUnknownEndpoint
}

public func MIDIRestart() -> OSStatus { kMIDIServerStartErr }

public func MIDISendSysex(_ request: UnsafeMutablePointer<MIDISysexSendRequest>) -> OSStatus {
    _ = request
    return kMIDINotPermitted
}

public func MIDISendUMPSysex(_ umpRequest: UnsafeMutablePointer<MIDISysexSendRequestUMP>) -> OSStatus {
    _ = umpRequest
    return kMIDINotPermitted
}

public func MIDISendUMPSysex8(_ umpRequest: UnsafeMutablePointer<MIDISysexSendRequestUMP>) -> OSStatus {
    MIDISendUMPSysex(umpRequest)
}

public func MIDIObjectFindByUniqueID(
    _ inUniqueID: MIDIUniqueID,
    _ outObject: UnsafeMutablePointer<MIDIObjectRef>?,
    _ outObjectType: UnsafeMutablePointer<MIDIObjectType>?
) -> OSStatus {
    _ = inUniqueID
    outObject?.pointee = 0
    outObjectType?.pointee = .other
    return kMIDIObjectNotFound
}

public func MIDIObjectGetStringProperty(_ obj: MIDIObjectRef, _ propertyID: CFString, _ str: UnsafeMutablePointer<Unmanaged<CFString>?>) -> OSStatus {
    _ = obj; _ = propertyID
    str.pointee = nil
    return kMIDIUnknownProperty
}

public func MIDIObjectGetIntegerProperty(_ obj: MIDIObjectRef, _ propertyID: CFString, _ outValue: UnsafeMutablePointer<Int32>) -> OSStatus {
    _ = obj; _ = propertyID
    outValue.pointee = 0
    return kMIDIUnknownProperty
}

public func MIDIObjectGetDataProperty(_ obj: MIDIObjectRef, _ propertyID: CFString, _ outData: UnsafeMutablePointer<Unmanaged<CFData>?>) -> OSStatus {
    _ = obj; _ = propertyID
    outData.pointee = nil
    return kMIDIUnknownProperty
}

public func MIDIObjectGetDictionaryProperty(_ obj: MIDIObjectRef, _ propertyID: CFString, _ outDict: UnsafeMutablePointer<Unmanaged<CFDictionary>?>) -> OSStatus {
    _ = obj; _ = propertyID
    outDict.pointee = nil
    return kMIDIUnknownProperty
}

public func MIDIObjectGetProperties(_ obj: MIDIObjectRef, _ outProperties: UnsafeMutablePointer<Unmanaged<CFPropertyList>?>, _ deep: Bool) -> OSStatus {
    _ = obj; _ = deep
    outProperties.pointee = nil
    return kMIDIUnknownProperty
}

public func MIDIObjectSetStringProperty(_ obj: MIDIObjectRef, _ propertyID: CFString, _ str: CFString) -> OSStatus {
    _ = obj; _ = propertyID; _ = str
    return kMIDINotPermitted
}

public func MIDIObjectSetIntegerProperty(_ obj: MIDIObjectRef, _ propertyID: CFString, _ value: Int32) -> OSStatus {
    _ = obj; _ = propertyID; _ = value
    return kMIDINotPermitted
}

public func MIDIObjectSetDataProperty(_ obj: MIDIObjectRef, _ propertyID: CFString, _ data: CFData) -> OSStatus {
    _ = obj; _ = propertyID; _ = data
    return kMIDINotPermitted
}

public func MIDIObjectSetDictionaryProperty(_ obj: MIDIObjectRef, _ propertyID: CFString, _ dict: CFDictionary) -> OSStatus {
    _ = obj; _ = propertyID; _ = dict
    return kMIDINotPermitted
}

public func MIDIObjectRemoveProperty(_ obj: MIDIObjectRef, _ propertyID: CFString) -> OSStatus {
    _ = obj; _ = propertyID
    return kMIDIUnknownProperty
}

public func MIDIDeviceGetNumberOfEntities(_ device: MIDIDeviceRef) -> Int { _ = device; return 0 }
public func MIDIDeviceGetEntity(_ device: MIDIDeviceRef, _ entityIndex0: Int) -> MIDIEntityRef { _ = device; _ = entityIndex0; return 0 }
public func MIDIEntityGetNumberOfSources(_ entity: MIDIEntityRef) -> Int { _ = entity; return 0 }
public func MIDIEntityGetNumberOfDestinations(_ entity: MIDIEntityRef) -> Int { _ = entity; return 0 }
public func MIDIEntityGetSource(_ entity: MIDIEntityRef, _ sourceIndex0: Int) -> MIDIEndpointRef { _ = entity; _ = sourceIndex0; return 0 }
public func MIDIEntityGetDestination(_ entity: MIDIEntityRef, _ destIndex0: Int) -> MIDIEndpointRef { _ = entity; _ = destIndex0; return 0 }
public func MIDIEntityGetDevice(_ inEntity: MIDIEntityRef, _ outDevice: UnsafeMutablePointer<MIDIDeviceRef>?) -> OSStatus {
    _ = inEntity
    outDevice?.pointee = 0
    return kMIDIObjectNotFound
}

public func MIDIDeviceCreate(
    _ owner: MIDIDriverRef?, _ name: CFString, _ manufacturer: CFString, _ model: CFString,
    _ outDevice: UnsafeMutablePointer<MIDIDeviceRef>
) -> OSStatus {
    _ = owner; _ = name; _ = manufacturer; _ = model
    return midiRefuse(outDevice)
}

public func MIDIExternalDeviceCreate(
    _ name: CFString, _ manufacturer: CFString, _ model: CFString,
    _ outDevice: UnsafeMutablePointer<MIDIDeviceRef>
) -> OSStatus {
    _ = name; _ = manufacturer; _ = model
    return midiRefuse(outDevice)
}

public func MIDIDeviceDispose(_ device: MIDIDeviceRef) -> OSStatus { _ = device; return kMIDINotPermitted }
public func MIDIDeviceAddEntity(
    _ device: MIDIDeviceRef, _ name: CFString, _ embedded: Bool,
    _ numSourceEndpoints: Int, _ numDestinationEndpoints: Int,
    _ newEntity: UnsafeMutablePointer<MIDIEntityRef>
) -> OSStatus {
    _ = device; _ = name; _ = embedded; _ = numSourceEndpoints; _ = numDestinationEndpoints
    return midiRefuse(newEntity)
}

public func MIDIDeviceNewEntity(
    _ device: MIDIDeviceRef, _ name: CFString, _ protocol: MIDIProtocolID, _ embedded: Bool,
    _ numSourceEndpoints: Int, _ numDestinationEndpoints: Int,
    _ newEntity: UnsafeMutablePointer<MIDIEntityRef>
) -> OSStatus {
    _ = device; _ = name; _ = `protocol`; _ = embedded; _ = numSourceEndpoints; _ = numDestinationEndpoints
    return midiRefuse(newEntity)
}

public func MIDIDeviceRemoveEntity(_ device: MIDIDeviceRef, _ entity: MIDIEntityRef) -> OSStatus {
    _ = device; _ = entity
    return kMIDINotPermitted
}

public func MIDIEntityAddOrRemoveEndpoints(_ entity: MIDIEntityRef, _ numSourceEndpoints: Int, _ numDestinationEndpoints: Int) -> OSStatus {
    _ = entity; _ = numSourceEndpoints; _ = numDestinationEndpoints
    return kMIDINotPermitted
}

public func MIDIDeviceListGetNumberOfDevices(_ devList: MIDIDeviceListRef) -> Int { _ = devList; return 0 }
public func MIDIDeviceListGetDevice(_ devList: MIDIDeviceListRef, _ index0: Int) -> MIDIDeviceRef { _ = devList; _ = index0; return 0 }
public func MIDIDeviceListAddDevice(_ devList: MIDIDeviceListRef, _ dev: MIDIDeviceRef) -> OSStatus {
    _ = devList; _ = dev
    return kMIDINotPermitted
}
public func MIDIDeviceListDispose(_ devList: MIDIDeviceListRef) -> OSStatus { _ = devList; return kMIDINotPermitted }

public func MIDISetupAddDevice(_ device: MIDIDeviceRef) -> OSStatus { _ = device; return kMIDINotPermitted }
public func MIDISetupAddExternalDevice(_ device: MIDIDeviceRef) -> OSStatus { _ = device; return kMIDINotPermitted }
public func MIDISetupRemoveDevice(_ device: MIDIDeviceRef) -> OSStatus { _ = device; return kMIDINotPermitted }
public func MIDISetupRemoveExternalDevice(_ device: MIDIDeviceRef) -> OSStatus { _ = device; return kMIDINotPermitted }

public func MIDIGetDriverDeviceList(_ driver: MIDIDriverRef) -> MIDIDeviceListRef { _ = driver; return 0 }

public func MIDIGetDriverIORunLoop() -> Unmanaged<CFRunLoop> {
    Unmanaged.passUnretained(CFRunLoopGetCurrent())
}

public func MIDIBluetoothDriverActivateAllConnections() -> OSStatus { kMIDINotPermitted }
public func MIDIBluetoothDriverDisconnect(_ uuid: CFString) -> OSStatus { _ = uuid; return kMIDINotPermitted }

public func MIDIThruConnectionCreate(
    _ inPersistentOwnerID: CFString?,
    _ inConnectionParams: CFData,
    _ outConnection: UnsafeMutablePointer<MIDIThruConnectionRef>
) -> OSStatus {
    _ = inPersistentOwnerID; _ = inConnectionParams
    return midiRefuse(outConnection)
}

public func MIDIThruConnectionDispose(_ connection: MIDIThruConnectionRef) -> OSStatus {
    _ = connection
    return kMIDIObjectNotFound
}

private let midiEmptyCFData: CFData = CFDataCreate(nil, [], 0)!

public func MIDIThruConnectionFind(_ inPersistentOwnerID: CFString, _ outConnectionList: UnsafeMutablePointer<Unmanaged<CFData>>) -> OSStatus {
    _ = inPersistentOwnerID
    outConnectionList.pointee = Unmanaged.passUnretained(midiEmptyCFData)
    return kMIDINotPermitted
}

public func MIDIThruConnectionGetParams(_ connection: MIDIThruConnectionRef, _ outConnectionParams: UnsafeMutablePointer<Unmanaged<CFData>>) -> OSStatus {
    _ = connection
    outConnectionParams.pointee = Unmanaged.passUnretained(midiEmptyCFData)
    return kMIDIObjectNotFound
}

public func MIDIThruConnectionSetParams(_ connection: MIDIThruConnectionRef, _ inConnectionParams: CFData) -> OSStatus {
    _ = connection; _ = inConnectionParams
    return kMIDIObjectNotFound
}
