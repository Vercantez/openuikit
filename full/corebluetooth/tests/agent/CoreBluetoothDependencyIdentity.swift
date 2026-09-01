@_spi(OpenUIKitHost) import CoreBluetooth
import CoreFoundation
import Dispatch
import Foundation

let _: Foundation.UUID.Type = UUID.self
let _: Foundation.NSError.Type = NSError.self
let _: Foundation.Data.Type = Data.self
let _: CoreFoundation.CFUUID.Type = CFUUID.self
let _: Dispatch.DispatchQueue.Type = DispatchQueue.self
let _: Dispatch.DispatchSpecificKey<String>.Type = DispatchSpecificKey<String>.self
let _: CoreBluetooth.CBUUID.Type = CBUUID.self
let _: CoreBluetooth.CBError.Type = CBError.self
let _: CoreBluetooth.CBATTError.Type = CBATTError.self
let _: CoreBluetooth.CBCentralManager.Type = CBCentralManager.self
let _: CoreBluetooth.CBMutableService.Type = CBMutableService.self

private func rehydrateCBError(from nsError: NSError) -> CBError? {
    guard nsError.domain == CBErrorDomain, let code = CBError.Code(rawValue: nsError.code) else {
        return nil
    }
    return CBError(code, userInfo: nsError.userInfo)
}

private func rehydrateCBATTError(from nsError: NSError) -> CBATTError? {
    guard nsError.domain == CBATTErrorDomain, let code = CBATTError.Code(rawValue: nsError.code) else {
        return nil
    }
    return CBATTError(code, userInfo: nsError.userInfo)
}

private func typedCBError(from error: any Error) -> CBError? {
    if let typed = error as? CBError { return typed }
    return rehydrateCBError(from: error as NSError)
}

private func typedCBATTError(from error: any Error) -> CBATTError? {
    if let typed = error as? CBATTError { return typed }
    return rehydrateCBATTError(from: error as NSError)
}

private func drain(_ queue: DispatchQueue) {
    queue.sync {}
}

private func containsBytes(_ haystack: Data, _ needle: String) -> Bool {
    haystack.range(of: Data(needle.utf8)) != nil
}

private final class IdentityCentralProbe: NSObject, CBCentralManagerDelegate {
    let key: DispatchSpecificKey<String>
    let token: String
    let lock = NSLock()
    var count = 0
    var initReturned = false
    var inlineDuringInit = false
    var disconnectCount = 0
    var failCount = 0
    var failInline = false
    var connectReturned = false
    let stateSemaphore = DispatchSemaphore(value: 0)
    let failSemaphore = DispatchSemaphore(value: 0)

    init(key: DispatchSpecificKey<String>, token: String) {
        self.key = key
        self.token = token
    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        _ = central
        precondition(DispatchQueue.getSpecific(key: key) == token)
        lock.lock()
        if !initReturned { inlineDuringInit = true }
        count += 1
        lock.unlock()
        stateSemaphore.signal()
    }

    func centralManager(
        _ central: CBCentralManager,
        didFailToConnect peripheral: CBPeripheral,
        error: (any Error)?
    ) {
        _ = (central, peripheral, error)
        precondition(DispatchQueue.getSpecific(key: key) == token)
        lock.lock()
        if !connectReturned { failInline = true }
        failCount += 1
        lock.unlock()
        failSemaphore.signal()
    }

    func centralManager(
        _ central: CBCentralManager,
        didDisconnectPeripheral peripheral: CBPeripheral,
        error: (any Error)?
    ) {
        _ = (central, peripheral, error)
        lock.lock()
        disconnectCount += 1
        lock.unlock()
        stateSemaphore.signal()
    }
}

private func exerciseNSErrorBridging() {
    let typed = CBError(.connectionFailed, userInfo: ["probe": "identity"])
    let nsError = typed as NSError
    precondition(nsError.domain == CBErrorDomain)
    precondition(nsError.code == CBError.connectionFailed.rawValue)
    precondition(nsError.userInfo["probe"] as? String == "identity")
    if let preserved = nsError as? CBError {
        precondition(preserved.code == .connectionFailed)
        precondition(preserved.userInfo["probe"] as? String == "identity")
    } else {
        let rebuilt = rehydrateCBError(from: nsError)
        precondition(rebuilt?.code == .connectionFailed)
        precondition(rebuilt?.userInfo["probe"] as? String == "identity")
    }
    precondition(CBError.connectionFailed ~= nsError)
    precondition(CBError.connectionFailed ~= typed)
    precondition(typedCBError(from: nsError)?.code == .connectionFailed)
    precondition(typedCBError(from: nsError)?.userInfo["probe"] as? String == "identity")
    precondition(typed.hashValue == CBError(.connectionFailed, userInfo: ["other": 0]).hashValue)
    precondition(typed != CBError(.connectionFailed))

    let fresh = NSError(
        domain: CBErrorDomain,
        code: CBError.invalidParameters.rawValue,
        userInfo: ["fresh": true]
    )
    precondition((fresh as? CBError) == nil)
    precondition(CBError.invalidParameters ~= fresh)
    precondition(rehydrateCBError(from: fresh)?.userInfo["fresh"] as? Bool == true)
    precondition(typedCBError(from: fresh)?.userInfo["fresh"] as? Bool == true)

    let att = CBATTError(.invalidHandle, userInfo: ["att": "x"])
    let attNS = att as NSError
    precondition(attNS.domain == CBATTErrorDomain)
    precondition(attNS.code == 1)
    if let preserved = attNS as? CBATTError {
        precondition(preserved.code == .invalidHandle)
        precondition(preserved.userInfo["att"] as? String == "x")
    } else {
        precondition(rehydrateCBATTError(from: attNS)?.code == .invalidHandle)
    }
    precondition(CBATTError.invalidHandle ~= attNS)
    precondition(CBATTError.invalidHandle ~= att)
    precondition(typedCBATTError(from: attNS)?.code == .invalidHandle)

    let freshATT = NSError(
        domain: CBATTErrorDomain,
        code: CBATTError.invalidHandle.rawValue,
        userInfo: ["att": "x"]
    )
    precondition((freshATT as? CBATTError) == nil)
    precondition(rehydrateCBATTError(from: freshATT)?.code == .invalidHandle)
}

private func exerciseUUIDIdentity() {
    let short = CBUUID(string: "180A")
    precondition(short.data == Data([0x18, 0x0A]))
    precondition(short.uuidString == "180A")
    precondition(CBUUID(data: short.data).uuidString == "180A")
    precondition(CBUUID(string: "180a").uuidString == "180A")
    precondition(CBUUID(string: "0000180A-0000-1000-8000-00805F9B34FB") == short)
    precondition(CBUUID(string: "0000180A") == short)
    precondition(CBUUID(data: Data([0x0A, 0x18])).uuidString == "0A18")

    let wide32 = CBUUID(string: "12345678")
    precondition(wide32.data == Data([0x12, 0x34, 0x56, 0x78]))
    precondition(CBUUID(data: wide32.data).uuidString == "12345678")

    let full = CBUUID(string: "ABCDEF01-2345-6789-ABCD-EF0123456789")
    precondition(full.data.count == 16)
    precondition(CBUUID(data: full.data).uuidString == full.uuidString)
    precondition(CBUUID(string: "ABCDEF0123456789ABCDEF0123456789") == full)

    precondition(CBUUID._hostData(fromString: "not-a-uuid") == nil)
    precondition(CBUUID._hostData(fromString: "180") == nil)
    precondition(CBUUID._hostData(fromString: "0x180A") == nil)
    precondition(CBUUID._hostData(fromString: "ZZZZ") == nil)
    precondition(CBUUID._hostData(fromString: " 180A") == nil)
    precondition(CBUUID._hostData(fromBytes: Data([1, 2, 3])) == nil)
    precondition(CBUUID._hostData(fromBytes: Data([0x18])) == nil)
    precondition(CBUUID._hostData(fromBytes: Data(count: 15)) == nil)
}

private func exerciseGATTIdentity() {
    let a = CBMutableService(type: CBUUID(string: "180F"), primary: true)
    let b = CBMutableService(type: CBUUID(string: "180A"), primary: true)
    let characteristic = CBMutableCharacteristic(
        type: CBUUID(string: "2A19"),
        properties: [.read],
        value: Data([0x01]),
        permissions: [.readable]
    )
    let descriptor = CBMutableDescriptor(
        type: CBUUID(string: CBUUIDClientCharacteristicConfigurationString),
        value: Data([0x00, 0x00])
    )
    characteristic.descriptors = [descriptor]
    let other = CBMutableCharacteristic(
        type: CBUUID(string: "2A29"),
        properties: [.read],
        value: nil,
        permissions: [.readable]
    )
    other.descriptors = [descriptor]
    precondition(descriptor.characteristic === other)
    precondition(!(characteristic.descriptors ?? []).contains(where: { $0 === descriptor }))

    a.characteristics = [characteristic]
    b.characteristics = [characteristic]
    precondition(characteristic.service === b)
    precondition(!(a.characteristics ?? []).contains(where: { $0 === characteristic }))

    let included = CBMutableService(type: CBUUID(string: "1800"), primary: false)
    a.includedServices = [included]
    b.includedServices = [included]
    precondition(!(a.includedServices ?? []).contains(where: { $0 === included }))
    b.includedServices = []
    a.includedServices = [included]
    precondition((a.includedServices ?? []).contains(where: { $0 === included }))
}

private func exerciseCallbackIdentity() {
    let key = DispatchSpecificKey<String>()
    let queue = DispatchQueue(label: "corebluetooth.identity")
    queue.setSpecific(key: key, value: "identity-token")
    let first = IdentityCentralProbe(key: key, token: "identity-token")
    let manager = CBCentralManager(delegate: first, queue: queue)
    first.lock.lock()
    first.initReturned = true
    let inlineAtReturn = first.inlineDuringInit
    first.lock.unlock()
    precondition(!inlineAtReturn)
    precondition(first.stateSemaphore.wait(timeout: .now() + 2) == .success)
    drain(queue)
    drain(queue)
    first.lock.lock()
    precondition(first.count == 1)
    precondition(!first.inlineDuringInit)
    first.lock.unlock()

    let second = IdentityCentralProbe(key: key, token: "identity-token")
    second.lock.lock()
    second.initReturned = true
    second.lock.unlock()
    manager.delegate = second
    precondition(second.stateSemaphore.wait(timeout: .now() + 2) == .success)
    drain(queue)
    drain(queue)
    second.lock.lock()
    precondition(second.count == 1)
    second.lock.unlock()
    first.lock.lock()
    precondition(first.count == 1)
    first.lock.unlock()

    let peer = CBPeripheral(hostIdentifier: UUID(), queue: queue)
    manager.cancelPeripheralConnection(peer)
    drain(queue)
    second.lock.lock()
    precondition(second.disconnectCount == 0)
    second.lock.unlock()

    manager.connect(peer)
    second.lock.lock()
    second.connectReturned = true
    let failInlineAtReturn = second.failInline
    second.lock.unlock()
    precondition(!failInlineAtReturn)
    precondition(second.failSemaphore.wait(timeout: .now() + 2) == .success)
    drain(queue)
    second.lock.lock()
    precondition(second.failCount == 1)
    precondition(!second.failInline)
    second.lock.unlock()

    weak var weakProbe: IdentityCentralProbe?
    do {
        let transient = IdentityCentralProbe(key: key, token: "identity-token")
        transient.lock.lock()
        transient.initReturned = true
        transient.lock.unlock()
        weakProbe = transient
        manager.delegate = transient
        _ = transient.stateSemaphore.wait(timeout: .now() + 2)
    }
    drain(queue)
    precondition(weakProbe == nil)
}

private func runProcess(executable: String, arguments: [String]) -> (status: Int32, output: String) {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: executable)
    process.arguments = arguments
    let outputURL = FileManager.default.temporaryDirectory
        .appendingPathComponent("cb-identity-\(UUID().uuidString).txt")
    precondition(
        FileManager.default.createFile(atPath: outputURL.path, contents: nil)
    )
    let handle = try! FileHandle(forWritingTo: outputURL)
    process.standardOutput = handle
    process.standardError = handle
    try! process.run()
    process.waitUntilExit()
    try? handle.close()
    let output = (try? String(contentsOf: outputURL, encoding: .utf8)) ?? ""
    try? FileManager.default.removeItem(at: outputURL)
    return (process.terminationStatus, output)
}

private func lddPath() -> String {
    for candidate in ["/usr/bin/ldd", "/bin/ldd"] {
        if FileManager.default.isExecutableFile(atPath: candidate) {
            return candidate
        }
    }
    fatalError("ldd is not available")
}

private func inspectLoadedDylib() {
    _ = CBUUID.self
    _ = CBError.self
    _ = CBCentralManager.self
    let executable = CommandLine.arguments[0]
    let executableDeps = runProcess(executable: lddPath(), arguments: [executable]).output
    precondition(
        executableDeps.contains("libCoreBluetooth") || executableDeps.contains("CoreBluetooth"),
        "identity executable does not link libCoreBluetooth.dylib"
    )
    precondition(
        executableDeps.contains("libFoundation") || executableDeps.contains("Foundation"),
        "identity executable does not link Foundation"
    )
    precondition(
        executableDeps.contains("libdispatch") || executableDeps.contains("Dispatch"),
        "identity executable does not link Dispatch"
    )

    if let path = ProcessInfo.processInfo.environment["COREBLUETOOTH_DYLIB"] {
        precondition(FileManager.default.isReadableFile(atPath: path))
        let dylib = try! Data(contentsOf: URL(fileURLWithPath: path))
        precondition(containsBytes(dylib, "CBErrorDomain"))
        precondition(containsBytes(dylib, "CBATTErrorDomain"))
        let dylibDeps = runProcess(executable: lddPath(), arguments: [path]).output
        precondition(
            dylibDeps.contains("libswiftCore") || dylibDeps.contains("swift"),
            "dylib is missing a Swift runtime dependency"
        )
        precondition(
            dylibDeps.contains("libFoundation") || dylibDeps.contains("Foundation"),
            "dylib is missing Foundation"
        )
    }
}

exerciseNSErrorBridging()
exerciseUUIDIdentity()
exerciseGATTIdentity()
exerciseCallbackIdentity()
inspectLoadedDylib()
print("COREBLUETOOTH_DEPENDENCY_IDENTITY_OK")
