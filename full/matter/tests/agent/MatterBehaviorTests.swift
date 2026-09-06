import Foundation
import Matter

func testClusterNameLookup() {
    mtrRequire(MTRClusterNameForID(n(6)) == "OnOff" || MTRClusterNameForID(n(6)) == "OnOffID" || (MTRClusterNameForID(n(6))?.contains("OnOff") ?? false), "onoff name")
    mtrRequire(MTRClusterNameForID(n(3)) != nil, "identify name")
    mtrRequire(MTRAttributeNameForID(n(6), n(0xFFFD)) == "ClusterRevision", "global rev")
    mtrRequire(MTRAttributeNameForID(n(6), n(0xFFF8)) == "GeneratedCommandList", "gen list")
    mtrRequire(MTRAttributeNameForID(n(6), n(0)) == "OnOff", "onoff attr")
    mtrRequire(MTRRequestCommandNameForID(n(6), n(0)) == "Off", "off")
    mtrRequire(MTRRequestCommandNameForID(n(6), n(1)) == "On", "on")
    mtrRequire(MTRRequestCommandNameForID(n(6), n(2)) == "Toggle", "toggle")
    mtrRequire(MTRResponseCommandNameForID(n(6), n(1)) == "On", "resp")
    mtrRequire(MTREventNameForID(n(0x28), n(0)) == "StartUp", "startup")
    mtrRequire(MTRClusterNameForID(n(0xFFFFFF)) == nil, "unknown cluster")
}

func testThreadOperationalDataset() {
    let name = "OpenThread"
    let ext = Data(repeating: 0x11, count: MTRSizeThreadExtendedPANID)
    let key = Data(repeating: 0x22, count: MTRSizeThreadMasterKey)
    let pskc = Data(repeating: 0x33, count: MTRSizeThreadPSKc)
    let pan = Data([0xAB, 0xCD])
    let dataset = MTRThreadOperationalDataset(
        networkName: name, extendedPANID: ext, masterKey: key, psKc: pskc, channel: 15, panID: pan
    )
    mtrRequire(dataset != nil, "create")
    mtrRequire(dataset?.networkName == name, "name")
    mtrRequire(dataset?.channel == 15, "ch")
    mtrRequire(dataset?.channelNumber.uint16Value == 15, "chn")
    let blob = dataset!.data()
    mtrRequire(!blob.isEmpty, "serialize")
    let round = MTRThreadOperationalDataset(data: blob)
    mtrRequire(round?.networkName == name, "rt name")
    mtrRequire(round?.channel == 15, "rt ch")
    mtrRequire(round?.extendedPANID == ext, "rt ext")
    mtrRequire(MTRThreadOperationalDataset(networkName: name, extendedPANID: Data(), masterKey: key, psKc: pskc, channel: 1, panID: pan) == nil, "bad ext")
    let viaNumber = MTRThreadOperationalDataset(
        networkName: name, extendedPANID: ext, masterKey: key, psKc: pskc,
        channelNumber: n(15), panID: pan
    )
    mtrRequire(viaNumber?.channel == 15, "via number")
    let viaPSKc = MTRThreadOperationalDataset(
        networkName: name, extendedPANID: ext, masterKey: key, PSKc: pskc,
        channelNumber: n(15), panID: pan
    )
    mtrRequire(viaPSKc?.psKc == pskc, "pskc alias")
}

func testDeviceTypeAndProductIdentity() {
    let light = MTRDeviceType(forID: n(0x0100))
    mtrRequire(light?.name == "On/Off Light", "light")
    mtrRequire(light?.isUtility == false, "not util")
    let root = MTRDeviceType(forID: n(0x0016))
    mtrRequire(root?.isUtility == true, "root util")
    mtrRequire(MTRDeviceType(forID: n(0x9999)) == nil, "unknown dt")
    let rev = MTRDeviceTypeRevision(deviceTypeID: n(0x0100), revision: n(1))
    mtrRequire(rev != nil, "rev")
    mtrRequire(rev?.deviceType?.name == "On/Off Light", "rev lookup")
    mtrRequire(MTRDeviceTypeRevision(deviceTypeID: n(0x0100), revision: n(0)) == nil, "rev 0")
    let pid = MTRProductIdentity(vendorID: n(0xFFF1), productID: n(0x8001))
    mtrRequire(pid.vendorID.uintValue == 0xFFF1, "vid")
    mtrRequire(pid.productID.uintValue == 0x8001, "pid")
    let params = MTRCommissioningParameters()
    params.wifiSSID = Data("net".utf8)
    params.countryCode = "US"
    params.skipCommissioningComplete = true
    mtrRequire(params.countryCode == "US", "cc")
    mtrRequire(params.skipCommissioningComplete, "skip")
    let fabric = MTRFabricInfo()
    fabric.fabricIndex = n(1)
    mtrRequire(fabric.fabricIndex.intValue == 1, "fabric")
    let ep = MTREndpointInfo()
    ep.endpointID = n(1)
    mtrRequire(ep.endpointID.intValue == 1, "epid")
}

func testAsyncWorkQueue() {
    let queue = MTRAsyncCallbackWorkQueue()
    let item = MTRAsyncCallbackQueueWorkItem()
    var ready = 0
    item.readyHandler = { _, count in
        ready = count + 1
    }
    queue.enqueue(item)
    mtrRequire(item.enqueued, "enqueued")
    mtrRequire(ready == 1, "ready sync")
    item.retryWork()
    mtrRequire(item.retryCount == 1, "retry")
    item.endWork()
    mtrRequire(item.ended, "ended")
    queue.invalidate()
}

func testLogCallback() {
    final class Box { var hit = false; var last = "" }
    let box = Box()
    MTRSetLogCallback(.detail) { type, module, message in
        box.hit = true
        box.last = module + ":" + message
        mtrRequire(type == .error, "logged error")
    }
    _ = MTRSetupPayload(payload: "!!!not-a-payload")
    mtrRequire(box.hit, "callback fired")
    mtrRequire(box.last.contains("Matter"), "module")
    MTRSetLogCallback(.error, nil)
}

func testAccessGrant() {
    let grant = MTRAccessGrant(
        subjectID: n(1),
        grantedPrivilege: .administer,
        authenticationMode: .CASE
    )
    mtrRequire(grant.grantedPrivilege == .administer, "priv")
    mtrRequire(grant.authenticationMode == .CASE, "auth")
    mtrRequire(grant.subjectID?.intValue == 1, "subj")
    mtrRequire(MTRAccessControlEntryPrivilege.view.rawValue == 1, "view")
    mtrRequire(MTRAccessControlEntryPrivilege.administer.rawValue == 5, "admin")
    mtrRequire(MTRAccessControlEntryAuthMode.PASE.rawValue == 1, "pase")
    mtrRequire(MTRAccessControlEntryAuthMode.CASE.rawValue == 2, "case")
}

func testMemoryStorage() {
    final class HostStorage: NSObject, MTRStorage {
        var bag: [String: Data] = [:]
        func storageData(forKey key: String) -> Data? { bag[key] }
        func setStorageData(_ value: Data, forKey key: String) -> Bool {
            bag[key] = value
            return true
        }
        func removeStorageData(forKey key: String) -> Bool {
            bag.removeValue(forKey: key) != nil
        }
    }
    let store = HostStorage()
    mtrRequire(store.setStorageData(Data([1, 2]), forKey: "k"), "set")
    mtrRequire(store.storageData(forKey: "k") == Data([1, 2]), "get")
    mtrRequire(store.removeStorageData(forKey: "k"), "rm")
    mtrRequire(store.storageData(forKey: "k") == nil, "gone")
    let params = MTRDeviceControllerFactoryParams()
    params.storage = store
    mtrRequire(params.storage != nil, "assigned")
    mtrRequire(!params.shouldStartServer, "server off")
}
