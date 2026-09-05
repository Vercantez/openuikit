@_spi(OpenUIKitHost) import WiFiAware
import Dispatch
import Foundation

private func waExpect(_ condition: Bool, _ message: String) {
    precondition(condition, message)
}

private final class WABox<T>: @unchecked Sendable {
    var value: T?
    var error: (any Error)?
}

private func waAwait<T: Sendable>(_ body: @escaping @Sendable () async throws -> T) -> T {
    let box = WABox<T>()
    let semaphore = DispatchSemaphore(value: 0)
    Task {
        do {
            box.value = try await body()
        } catch {
            box.error = error
        }
        semaphore.signal()
    }
    precondition(semaphore.wait(timeout: .now() + 5) == .success, "async timeout")
    if let error = box.error {
        fatalError("\(error)")
    }
    return box.value!
}

func testPairedDeviceCodable() {
    let json = Data(
        #"{"id":7,"name":"Lamp","pairingInfo":{"pairingName":"Lamp","vendorName":"Acme","modelName":"L1"}}"#.utf8
    )
    let device = try! JSONDecoder().decode(WAPairedDevice.self, from: json)
    let id: WAPairedDevice.ID = device.id
    waExpect(id == 7, "device id")
    waExpect(device.name == "Lamp", "device name")
    waExpect(device.pairingInfo != nil, "pairingInfo present")
    waExpect(device.description.contains("Lamp"), "device description")
    let encoded = try! JSONEncoder().encode(device)
    let decoded = try! JSONDecoder().decode(WAPairedDevice.self, from: encoded)
    waExpect(decoded == device, "device ==")
    let other = try! JSONDecoder().decode(
        WAPairedDevice.self,
        from: Data(#"{"id":8,"name":null,"pairingInfo":null}"#.utf8)
    )
    waExpect(device != other, "device !=")
    var hasher = Hasher()
    device.hash(into: &hasher)
    _ = hasher.finalize()
    _ = device.hashValue
    let snapshot: WAPairedDevice.Devices = [device.id: device]
    waExpect(snapshot.count == 1, "Devices typealias")
}

func testPairingInfoCodable() {
    let json = Data(#"{"pairingName":"Lamp","vendorName":"Acme","modelName":"L1"}"#.utf8)
    let info = try! JSONDecoder().decode(WAPairedDevice.PairingInfo.self, from: json)
    waExpect(info.pairingName == "Lamp", "pairingName")
    waExpect(info.vendorName == "Acme", "vendorName")
    waExpect(info.modelName == "L1", "modelName")
    waExpect(info.description.contains("Acme"), "pairing description")
    waExpect(info == info, "pairing ==")
    let other = try! JSONDecoder().decode(
        WAPairedDevice.PairingInfo.self,
        from: Data(#"{"pairingName":"X","vendorName":"Y","modelName":"Z"}"#.utf8)
    )
    waExpect(info != other, "pairing !=")
    var hasher = Hasher()
    info.hash(into: &hasher)
    _ = hasher.finalize()
    _ = info.hashValue
    let encoded = try! JSONEncoder().encode(info)
    let decoded = try! JSONDecoder().decode(WAPairedDevice.PairingInfo.self, from: encoded)
    waExpect(decoded == info, "pairing Codable")
}

func testAllDevicesEmptyInventory() {
    let snapshot = waAwait { try await WAPairedDevice.allDevices.current() }
    waExpect(snapshot == [:], "allDevices.current is empty")
    let predicate = #Predicate<WAPairedDevice> { candidate in
        candidate.id == 7
    }
    let matching = waAwait { try await WAPairedDevice.allDevices(matching: predicate).current() }
    waExpect(matching == [:], "matching inventory is still empty")
    let _: WAPairedDevice.DevicesSequence = WAPairedDevice.allDevices
}
