import CoreMIDI
import Foundation

func testNetworkSession() {
    let host = MIDINetworkHost(name: "box", address: "127.0.0.1", port: 5004)
    midiExpect(host.name == "box" && host.address == "127.0.0.1" && host.port == 5004, "host address")
    midiExpect(host.netServiceName == nil && host.netServiceDomain == nil, "no net service")
    let service = NetService(name: "svc", domain: "local.")
    let fromService = MIDINetworkHost(name: "svc-host", netService: service)
    midiExpect(fromService.netServiceName == "svc", "from NetService")
    let named = MIDINetworkHost(name: "n", netServiceName: "svc", netServiceDomain: "local.")
    midiExpect(named.hasSameAddress(as: fromService), "same address")
    midiExpect(!named.hasSameAddress(as: host), "different address")
    let connection = MIDINetworkConnection(host: host)
    midiExpect(connection.host === host, "connection host")
    let session = MIDINetworkSession.default()
    midiExpect(session.networkPort == 0, "disabled port")
    midiExpect(session.networkName.isEmpty, "disabled name")
    midiExpect(session.localName == "OpenUIKit-CoreMIDI", "local name")
    session.isEnabled = true
    midiExpect(session.networkPort == 5004, "enabled port")
    midiExpect(!session.networkName.isEmpty, "enabled name")
    session.connectionPolicy = .anyone
    midiExpect(session.connectionPolicy == .anyone, "policy")
    midiExpect(session.addContact(host), "add contact")
    midiExpect(session.contacts().contains(host), "contacts")
    midiExpect(session.addConnection(connection), "add connection")
    midiExpect(session.connections().contains(connection), "connections")
    midiExpect(session.sourceEndpoint() == 0 && session.destinationEndpoint() == 0, "no endpoints")
    midiExpect(session.removeConnection(connection), "remove connection")
    midiExpect(session.removeContact(host), "remove contact")
    session.isEnabled = false
}

func testCIAndUMPClasses() {
    midiExpect(MIDICIDeviceManager.shared.discoveredCIDevices.isEmpty, "no ci devices")
    _ = MIDICIDeviceManager.deviceWasAddedNotification
    _ = MIDICIDeviceManager.deviceWasRemovedNotification
    _ = MIDICIDeviceManager.profileWasRemovedNotification
    _ = MIDICIDeviceManager.profileWasUpdatedNotification
    midiExpect(MIDICIDeviceManager.DictionaryKey.deviceObject.rawValue.contains("Device"), "device key")
    midiExpect(MIDICIDeviceManager.DictionaryKey.profileObject.rawValue.contains("Profile"), "profile key")
    let manufacturer = MIDI2DeviceManufacturer(sysExIDByte: (1, 2, 3))
    let revision = MIDI2DeviceRevisionLevel(revisionLevel: (1, 0, 0, 0))
    let info = MIDI2DeviceInfo(manufacturerID: manufacturer, family: 1, modelNumber: 2, revisionLevel: revision)
    midiExpect(info.family == 1 && info.modelNumber == 2, "device info")
    let ciInfo = MIDICIDeviceInfo(destination: 0, manufacturer: Data([1]), family: Data([2]), model: Data([3]), revision: Data([4]))
    midiExpect(ciInfo.midiDestination == 0, "ci info dest")
    midiExpect(MIDICIDeviceInfo(coder: NSCoder()) == nil, "ci info coder")
    ciInfo.encode(with: NSCoder())
    let profile = MIDICIProfile(data: Data([1, 2]))
    midiExpect(profile.profileID.count == 2, "profile data")
    let named = MIDICIProfile(data: Data([1]), name: "p")
    midiExpect(named.name == "p", "profile name")
    midiExpect(MIDICIProfile(coder: NSCoder()) == nil, "profile coder")
    named.encode(with: NSCoder())
    let state = MIDICIProfileState(channel: 1, enabledProfiles: [named], disabledProfiles: [])
    midiExpect(state.midiChannel == 1 && state.enabledProfiles.count == 1, "profile state")
    let whole = MIDICIProfileState(enabledProfiles: [], disabledProfiles: [named])
    midiExpect(state.disabledProfiles.isEmpty && whole.midiChannel == MIDIChannelsWholePort, "whole port")
    midiExpect(MIDICIProfileState(coder: NSCoder()) == nil, "state coder")
    state.encode(with: NSCoder())
    let node = MIDICIDiscoveredNode(destination: 0, deviceInfo: ciInfo)
    midiExpect(!node.supportsProfiles && !node.supportsProperties, "node caps")
    midiExpect(node.maximumSysExSize == 0, "max sysex")
    midiExpect(MIDICIDiscoveredNode(coder: NSCoder()) == nil, "node coder")
    node.encode(with: NSCoder())
    var discovered: [MIDICIDiscoveredNode]? = nil
    MIDICIDiscoveryManager.sharedInstance().discover { discovered = $0 }
    midiExpect(discovered?.isEmpty == true, "discovery empty")
    final class Delegate: MIDICIProfileResponderDelegate {
        func connectInitiator(_ initiatorMUID: MIDICIInitiatiorMUID, with deviceInfo: MIDICIDeviceInfo) -> Bool {
            _ = initiatorMUID; _ = deviceInfo
            return false
        }
        func initiatorDisconnected(_ initiatorMUID: MIDICIInitiatiorMUID) { _ = initiatorMUID }
    }
    let responder = MIDICIResponder(deviceInfo: ciInfo, profileDelegate: Delegate(), profileStates: [state], supportProperties: false)
    midiExpect(!responder.start(), "responder start")
    midiExpect(!responder.notify(named, onChannel: 0, isEnabled: true), "notify")
    midiExpect(!responder.send(named, onChannel: 0, profileData: Data()), "send profile")
    midiExpect(responder.initiators.isEmpty, "initiators")
    responder.stop()
    var ready = false
    let session = MIDICISession(discoveredNode: node, dataReadyHandler: { ready = true }, disconnectHandler: { _, _ in })
    midiExpect(ready, "data ready")
    midiExpect(!session.supportsProfileCapability && !session.supportsPropertyCapability, "session caps")
    midiExpect(session.midiDestination == 0, "session dest")
    midiExpect(session.maxSysExSize == 0 && session.maxPropertyRequests == 0, "session max")
    midiExpect(session.profileState(forChannel: 1).enabledProfiles.isEmpty, "profile state empty")
    do {
        try session.enable(named, onChannel: 0)
        midiExpect(false, "enable should throw")
    } catch { midiExpect(true, "enable threw") }
    do {
        try session.disableProfile(named, onChannel: 0)
        midiExpect(false, "disable should throw")
    } catch { midiExpect(true, "disable threw") }
    midiExpect(!session.send(named, onChannel: 0, profileData: Data()), "session send")
    session.profileChangedCallback = { _, _, _, _ in }
    session.profileSpecificDataHandler = { _, _, _, _ in }
    let profileID = MIDICIProfileID(standard: MIDICIProfileIDStandard(profileIDByte1: 1, profileBank: 0, profileNumber: 1, profileVersion: 0, profileLevel: 1))
    midiExpect(profileID.standard.profileNumber == 1, "profile id standard")
    let mfrID = MIDICIProfileID(manufacturerSpecific: MIDICIProfileIDManufacturerSpecific(sysExID1: 1, sysExID2: 2, sysExID3: 3, info1: 0, info2: 0))
    midiExpect(mfrID.manufacturerSpecific.sysExID1 == 1, "profile id mfr")
    _ = MIDICIProfileID()
    _ = MIDICIProfileIDStandard()
    _ = MIDICIProfileIDManufacturerSpecific()
    var ident = MIDICIDeviceIdentification()
    ident.manufacturer = (1, 2, 3)
    midiExpect(ident.manufacturer.0 == 1, "ident")
    ident = MIDICIDeviceIdentification(manufacturer: (0, 0, 0), family: (0, 0), modelNumber: (0, 0), revisionLevel: (0, 0, 0, 0), reserved: (0, 0, 0, 0, 0))
    midiExpect(ident.family.0 == 0, "ident memberwise")
    _ = MIDI2DeviceManufacturer()
    _ = MIDI2DeviceRevisionLevel()

    midiExpect(MIDIUMPEndpointManager.shared.umpEndpoints.isEmpty, "no ump endpoints")
    _ = MIDIUMPEndpointManager.endpointWasAddedNotification
    _ = MIDIUMPEndpointManager.endpointWasRemovedNotification
    _ = MIDIUMPEndpointManager.endpointWasUpdatedNotification
    _ = MIDIUMPEndpointManager.functionBlockWasUpdatedNotification
    midiExpect(MIDIUMPEndpointManager.DictionaryKey.endpointObject.rawValue.contains("Endpoint"), "ump ep key")
    midiExpect(MIDIUMPEndpointManager.DictionaryKey.functionBlockObject.rawValue.contains("Function"), "ump fb key")
    let umpProfile = MIDIUMPCIProfile(name: "p", profileID: profileID, profileType: .singleChannel, groupOffset: 0, firstChannel: 0, totalChannelCount: 1)
    midiExpect(!umpProfile.isEnabled && umpProfile.totalChannelCount == 1, "ump profile")
    do {
        try umpProfile.setProfileState(true, enabledChannelCount: 1)
        midiExpect(false, "set profile should throw")
    } catch { midiExpect(true, "set profile threw") }
    let endpoint = MIDIUMPEndpoint(name: "ep", deviceInfo: info, productInstanceID: "id", midiProtocol: ._1_0)
    midiExpect(endpoint.midiDestination == 0 && endpoint.midiSource == 0, "ump ep refs")
    midiExpect(!endpoint.hasJRTSReceiveCapability && !endpoint.hasJRTSTransmitCapability, "jrts")
    midiExpect(endpoint.functionBlocks.isEmpty, "no fbs")
    midiExpect(endpoint.endpointType == .unknown, "backing")
    let mutable = MIDIUMPMutableEndpoint(
        name: "v",
        deviceInfo: info,
        productInstanceID: "id",
        midiProtocol: ._2_0,
        destinationCallback: { _, _ in }
    )
    midiExpect(mutable != nil, "mutable endpoint constructs")
    midiExpect(MIDIUMPMutableEndpoint(name: "v", deviceInfo: info, productInstanceID: "id", MIDIProtocol: ._2_0, destinationCallback: { _, _ in }) != nil, "convenience init")
    do {
        try mutable?.setName("x")
        midiExpect(false, "setName should throw")
    } catch { midiExpect(true, "setName threw") }
    do {
        try mutable?.setEnabled(true)
        midiExpect(false, "setEnabled should throw")
    } catch { midiExpect(true, "setEnabled threw") }
    let block = MIDIUMPMutableFunctionBlock(
        name: "fb",
        direction: .output,
        firstGroup: 0,
        totalGroupsSpanned: 1,
        maxSysEx8Streams: 1,
        midi1Info: .notMIDI1,
        uiHint: .sender,
        isEnabled: false
    )
    midiExpect(block != nil, "mutable fb")
    midiExpect(
        MIDIUMPMutableFunctionBlock(
            name: "fb",
            direction: .output,
            firstGroup: 0,
            totalGroupsSpanned: 1,
            maxSysEx8Streams: 1,
            MIDI1Info: .notMIDI1,
            UIHint: .sender,
            isEnabled: false
        ) != nil,
        "fb convenience"
    )
    do {
        try mutable?.registerFunctionBlocks([], markAsStatic: true)
        midiExpect(false, "register should throw")
    } catch { midiExpect(true, "register threw") }
    do {
        try block?.setName("x")
        midiExpect(false, "fb setName should throw")
    } catch { midiExpect(true, "fb setName threw") }
    do {
        try block?.setEnabled(true)
        midiExpect(false, "fb setEnabled should throw")
    } catch { midiExpect(true, "fb setEnabled threw") }
    midiExpect(block?.reconfigure(firstGroup: 0, direction: .input, MIDI1Info: .notMIDI1, UIHint: .receiver) == false, "reconfigure")
    midiExpect(block?.umpEndpoint == nil, "fb endpoint")
}

func testTypealiasesAndStandIns() {
    let _: MIDIClientRef = 0
    let _: MIDIPortRef = 0
    let _: MIDIEndpointRef = 0
    let _: MIDIDeviceRef = 0
    let _: MIDIEntityRef = 0
    let _: MIDIDeviceListRef = 0
    let _: MIDISetupRef = 0
    let _: MIDIThruConnectionRef = 0
    let _: MIDIObjectRef = 0
    let _: MIDIUniqueID = kMIDIInvalidUniqueID
    let _: MIDITimeStamp = 0
    let _: MIDIChannelNumber = 0
    let _: MIDIUInteger2 = 0
    let _: MIDIUInteger4 = 0
    let _: MIDIUInteger7 = 0
    let _: MIDIUInteger14 = 0
    let _: MIDIUInteger28 = 0
    let _: MIDIMessage_32 = 0
    let _: MIDICIDeviceID = 0
    let _: MIDICIMUID = 0
    let _: MIDICIInitiatiorMUID = 0
    let _: MIDIUMPFunctionBlockID = 0
    let _: MIDIUMPGroupNumber = 0
    let _: OSStatus = kMIDINotPermitted
    let _: HRESULT = 0
    let _: ULONG = 0
    midiExpect(true, "typealias smoke")
}
