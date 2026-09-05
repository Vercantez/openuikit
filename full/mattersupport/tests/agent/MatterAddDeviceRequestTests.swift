@_spi(OpenUIKitHost) import MatterSupport
import Dispatch
import Foundation

let matterSupportTestTimeout = DispatchTimeInterval.seconds(5)

func matterSupportAwait(_ body: @escaping @Sendable () async -> Void) {
    let done = DispatchSemaphore(value: 0)
    Task {
        await body()
        done.signal()
    }
    precondition(
        done.wait(timeout: .now() + matterSupportTestTimeout) == .success,
        "MatterSupport test timed out"
    )
}

func matterSupportRequireUnavailable(
    operation: String,
    _ body: @escaping @Sendable () async throws -> Void
) {
    matterSupportAwait {
        do {
            try await body()
            fatalError("expected fail-closed throw for \(operation)")
        } catch let error as NSError {
            precondition(
                error.domain == "MatterSupport.linux.unavailable",
                "unexpected domain \(error.domain) for \(operation)"
            )
            precondition(error.code == 1, "unexpected code \(error.code) for \(operation)")
            precondition(
                !String(reflecting: type(of: error)).hasPrefix("MatterSupport."),
                "fail-closed error must be Foundation.NSError"
            )
        } catch {
            fatalError("wrong error type \(error) for \(operation)")
        }
    }
}

func matterSupportRoundTrip<T: Codable & Equatable>(_ value: T) -> T {
    let encoder = JSONEncoder()
    let decoder = JSONDecoder()
    let data = try! encoder.encode(value)
    return try! decoder.decode(T.self, from: data)
}

func matterSupportJSONObject(_ value: some Encodable) -> [String: Any] {
    let data = try! JSONEncoder().encode(value)
    return try! JSONSerialization.jsonObject(with: data) as! [String: Any]
}

func testHomeValueSemantics() {
    var home = MatterAddDeviceRequest.Home(displayName: "Main")
    precondition(home.displayName == "Main")
    home.displayName = "Cottage"
    precondition(home.displayName == "Cottage")
    let same = MatterAddDeviceRequest.Home(displayName: "Cottage")
    let other = MatterAddDeviceRequest.Home(displayName: "Main")
    precondition(home == same)
    precondition(home != other)
    precondition(!(home == other))
    precondition(home.hashValue == same.hashValue)
    var hasher = Hasher()
    home.hash(into: &hasher)
    _ = hasher.finalize()
}

func testRoomValueSemantics() {
    var room = MatterAddDeviceRequest.Room(displayName: "Kitchen")
    precondition(room.displayName == "Kitchen")
    room.displayName = "Hall"
    precondition(room.displayName == "Hall")
    let same = MatterAddDeviceRequest.Room(displayName: "Hall")
    let other = MatterAddDeviceRequest.Room(displayName: "Kitchen")
    precondition(room == same)
    precondition(room != other)
    precondition(room.hashValue == same.hashValue)
    var hasher = Hasher()
    room.hash(into: &hasher)
    _ = hasher.finalize()
}

func testTopologyValueSemantics() {
    var topology = MatterAddDeviceRequest.Topology(
        ecosystemName: "OpenUIKit",
        homes: [MatterAddDeviceRequest.Home(displayName: "Main")]
    )
    precondition(topology.ecosystemName == "OpenUIKit")
    precondition(topology.homes.count == 1)
    precondition(topology.homes[0].displayName == "Main")
    topology.ecosystemName = "Garden"
    topology.homes.append(MatterAddDeviceRequest.Home(displayName: "Shed"))
    precondition(topology.homes.map(\.displayName) == ["Main", "Shed"])
    let same = MatterAddDeviceRequest.Topology(
        ecosystemName: "Garden",
        homes: [
            MatterAddDeviceRequest.Home(displayName: "Main"),
            MatterAddDeviceRequest.Home(displayName: "Shed"),
        ]
    )
    let other = MatterAddDeviceRequest.Topology(ecosystemName: "Garden", homes: [])
    precondition(topology == same)
    precondition(topology != other)
    precondition(topology.hashValue == same.hashValue)
    var hasher = Hasher()
    topology.hash(into: &hasher)
    _ = hasher.finalize()
}

func testDeviceCriteriaCases() {
    let uuid = UUID(uuidString: "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE")!
    let key = Data([0x01, 0x02, 0x03, 0x04])
    let cases: [(MatterAddDeviceRequest.DeviceCriteria, MatterAddDeviceRequest.DeviceCriteria)] = [
        (.allDevices, .allDevices),
        (
            .fabricNode(rootPublicKey: key, nodeID: 99),
            .fabricNode(rootPublicKey: Data([0x01, 0x02, 0x03, 0x04]), nodeID: 99)
        ),
        (.serialNumber("SN-1"), .serialNumber("SN-1")),
        (.commissioningID(uuid), .commissioningID(uuid)),
        (.vendorID(0xFFF1), .vendorID(0xFFF1)),
        (.productID(0x1234), .productID(0x1234)),
        (.all([.vendorID(1), .productID(2)]), .all([.vendorID(1), .productID(2)])),
        (.any([.serialNumber("A"), .serialNumber("B")]), .any([.serialNumber("A"), .serialNumber("B")])),
        (.not(.allDevices), .not(.allDevices)),
    ]
    precondition(Set(cases.map(\.0)).count == cases.count)
    for (lhs, rhs) in cases {
        precondition(lhs == rhs)
        precondition(!(lhs != rhs))
        precondition(lhs.hashValue == rhs.hashValue)
        var hasher = Hasher()
        lhs.hash(into: &hasher)
        _ = hasher.finalize()
    }
    precondition(MatterAddDeviceRequest.DeviceCriteria.vendorID(1) != .vendorID(2))
    precondition(
        MatterAddDeviceRequest.DeviceCriteria.fabricNode(rootPublicKey: key, nodeID: 1)
            != .fabricNode(rootPublicKey: key, nodeID: 2)
    )
    precondition(
        MatterAddDeviceRequest.DeviceCriteria.not(.allDevices) != .not(.serialNumber("x"))
    )
    precondition(
        MatterAddDeviceRequest.DeviceCriteria.all([.vendorID(1)])
            != .any([.vendorID(1)])
    )
}

func testAddDeviceRequestStorage() {
    let topology = MatterAddDeviceRequest.Topology(
        ecosystemName: "Eco",
        homes: [MatterAddDeviceRequest.Home(displayName: "Home")]
    )
    var request = MatterAddDeviceRequest(
        topology: topology,
        showing: .allDevices,
        shouldScanNetworks: true
    )
    precondition(request.topology.ecosystemName == "Eco")
    precondition(request.showDeviceCriteria == .allDevices)
    precondition(request.shouldScanNetworks == true)
    request.showDeviceCriteria = .vendorID(7)
    request.shouldScanNetworks = false
    request.topology = MatterAddDeviceRequest.Topology(ecosystemName: "Other", homes: [])
    precondition(request.showDeviceCriteria == .vendorID(7))
    precondition(request.shouldScanNetworks == false)
    precondition(request.topology.ecosystemName == "Other")

    let same = MatterAddDeviceRequest(
        topology: request.topology,
        showing: .vendorID(7),
        shouldScanNetworks: false
    )
    let other = MatterAddDeviceRequest(
        topology: request.topology,
        showing: .allDevices,
        shouldScanNetworks: false
    )
    precondition(request == same)
    precondition(request != other)
    precondition(request.hashValue == same.hashValue)
    var hasher = Hasher()
    request.hash(into: &hasher)
    _ = hasher.finalize()
}

func testAddDeviceRequestIsSupported() {
    precondition(MatterAddDeviceRequest.isSupported == false)
}

func testAddDeviceRequestPerformFailsClosed() {
    let request = MatterAddDeviceRequest(
        topology: MatterAddDeviceRequest.Topology(ecosystemName: "Eco", homes: []),
        showing: .allDevices,
        shouldScanNetworks: true
    )
    matterSupportRequireUnavailable(operation: "perform") {
        try await request.perform()
    }

    matterSupportAwait {
        await withTaskGroup(of: String.self) { group in
            for _ in 0..<8 {
                group.addTask {
                    do {
                        try await request.perform()
                        fatalError("perform must not succeed")
                    } catch let error as NSError {
                        return error.domain
                    } catch {
                        fatalError("unexpected \(error)")
                    }
                }
            }
            var count = 0
            for await domain in group {
                precondition(domain == "MatterSupport.linux.unavailable")
                count += 1
            }
            precondition(count == 8)
        }
    }
}

func testHomeCodableRoundTrip() {
    let home = MatterAddDeviceRequest.Home(displayName: "Orchard")
    precondition(matterSupportRoundTrip(home) == home)
    let object = matterSupportJSONObject(home)
    precondition(object["displayName"] as? String == "Orchard")
}

func testRoomCodableRoundTrip() {
    let room = MatterAddDeviceRequest.Room(displayName: "Pantry")
    precondition(matterSupportRoundTrip(room) == room)
    let object = matterSupportJSONObject(room)
    precondition(object["displayName"] as? String == "Pantry")
}

func testTopologyCodableRoundTrip() {
    let topology = MatterAddDeviceRequest.Topology(
        ecosystemName: "Home Assistant",
        homes: [MatterAddDeviceRequest.Home(displayName: "")]
    )
    precondition(matterSupportRoundTrip(topology) == topology)
    let object = matterSupportJSONObject(topology)
    precondition(object["ecosystemName"] as? String == "Home Assistant")
    let homes = object["homes"] as! [[String: Any]]
    precondition(homes.count == 1)
    precondition(homes[0]["displayName"] as? String == "")
}

func testDeviceCriteriaCodableRoundTrip() {
    let uuid = UUID(uuidString: "00000000-1111-2222-3333-444444444444")!
    let nested: [MatterAddDeviceRequest.DeviceCriteria] = [
        .allDevices,
        .fabricNode(rootPublicKey: Data([0xAA]), nodeID: 7),
        .serialNumber("serial"),
        .commissioningID(uuid),
        .vendorID(0x1234),
        .productID(99),
        .all([.vendorID(1), .not(.productID(2))]),
        .any([.serialNumber("A"), .serialNumber("B")]),
        .not(.allDevices),
    ]
    for item in nested {
        precondition(matterSupportRoundTrip(item) == item)
    }
    let vendorJSON = matterSupportJSONObject(MatterAddDeviceRequest.DeviceCriteria.vendorID(8))
    precondition(vendorJSON["kind"] as? String == "vendorID")
    precondition(vendorJSON["int"] as? Int == 8)
    let allJSON = matterSupportJSONObject(MatterAddDeviceRequest.DeviceCriteria.allDevices)
    precondition(allJSON["kind"] as? String == "allDevices")

    let bad = Data(#"{"kind":"not-a-real-kind"}"#.utf8)
    do {
        _ = try JSONDecoder().decode(MatterAddDeviceRequest.DeviceCriteria.self, from: bad)
        fatalError("unknown DeviceCriteria kind must not decode")
    } catch is DecodingError {
        ()
    } catch {
        fatalError("expected DecodingError, got \(error)")
    }
}

func testAddDeviceRequestCodableRoundTrip() {
    let request = MatterAddDeviceRequest(
        topology: MatterAddDeviceRequest.Topology(
            ecosystemName: "Home Assistant",
            homes: []
        ),
        showing: .serialNumber("HA-1"),
        shouldScanNetworks: true
    )
    precondition(matterSupportRoundTrip(request) == request)
    let object = matterSupportJSONObject(request)
    precondition(object["shouldScanNetworks"] as? Bool == true)
    let criteria = object["showDeviceCriteria"] as! [String: Any]
    precondition(criteria["kind"] as? String == "serialNumber")
    precondition(criteria["string"] as? String == "HA-1")
    precondition(object["setupPayload"] == nil)
}
