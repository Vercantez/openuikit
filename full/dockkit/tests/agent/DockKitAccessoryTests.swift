import Foundation
import DockKit

func testDockAccessoryHostConstruction() {
    let identifier = DockAccessory.Identifier(
        name: "host",
        uuid: UUID(uuidString: "77777777-7777-7777-7777-777777777777")!,
        category: .trackingStand
    )
    let accessory = DockAccessory(identifier: identifier)
    precondition(accessory.identifier == identifier)
}

func testDockAccessoryEqualityAndHash() {
    let uuid = UUID(uuidString: "88888888-8888-8888-8888-888888888888")!
    let identifier = DockAccessory.Identifier(name: "eq", uuid: uuid, category: .trackingStand)
    let a = DockAccessory(identifier: identifier)
    let b = DockAccessory(identifier: identifier)
    let c = DockAccessory(
        identifier: DockAccessory.Identifier(
            name: "other",
            uuid: UUID(uuidString: "99999999-9999-9999-9999-999999999999")!,
            category: .trackingStand
        )
    )
    precondition(a == b)
    precondition(a != c)
    var hasherA = Hasher()
    var hasherB = Hasher()
    a.hash(into: &hasherA)
    b.hash(into: &hasherB)
    precondition(hasherA.finalize() == hasherB.finalize())
    precondition(a.hashValue == b.hashValue)
}

func testDockAccessoryDebugDescription() {
    let identifier = DockAccessory.Identifier(
        name: "debug-stand",
        uuid: UUID(uuidString: "AAAAAAAA-0000-0000-0000-000000000001")!,
        category: .trackingStand
    )
    let accessory = DockAccessory(identifier: identifier)
    precondition(accessory.debugDescription.contains("debug-stand"))
}

func testDockAccessoryDefaultProperties() {
    let accessory = DockAccessory(
        identifier: DockAccessory.Identifier(
            name: "defaults",
            uuid: UUID(uuidString: "AAAAAAAA-0000-0000-0000-000000000002")!,
            category: .trackingStand
        )
    )
    precondition(accessory.framingMode == .automatic)
    precondition(accessory.regionOfInterest == .zero)
    precondition(accessory.hardwareModel == nil)
    precondition(accessory.firmwareVersion == nil)
}

func testDockAccessoryLimitsThrow() {
    let accessory = makeHostAccessory()
    do {
        _ = try accessory.limits
        preconditionFailure("limits must fail closed")
    } catch let error as DockKitError {
        precondition(error == .notSupported)
    } catch {
        preconditionFailure("expected DockKitError")
    }
}

func testDockAccessoryMotionStatesThrow() {
    let accessory = makeHostAccessory()
    do {
        _ = try accessory.motionStates
        preconditionFailure("motionStates must fail closed")
    } catch let error as DockKitError {
        precondition(error == .notSupported)
    } catch {
        preconditionFailure("expected DockKitError")
    }
}

func testDockAccessoryBatteryStatesThrow() {
    let accessory = makeHostAccessory()
    do {
        _ = try accessory.batteryStates
        preconditionFailure("batteryStates must fail closed")
    } catch let error as DockKitError {
        precondition(error == .notSupported)
    } catch {
        preconditionFailure("expected DockKitError")
    }
}

func testDockAccessoryTrackingStatesThrow() {
    let accessory = makeHostAccessory()
    do {
        _ = try accessory.trackingStates
        preconditionFailure("trackingStates must fail closed")
    } catch let error as DockKitError {
        precondition(error == .notSupported)
    } catch {
        preconditionFailure("expected DockKitError")
    }
}

func testDockAccessoryAccessoryEventsThrow() {
    let accessory = makeHostAccessory()
    do {
        _ = try accessory.accessoryEvents
        preconditionFailure("accessoryEvents must fail closed")
    } catch let error as DockKitError {
        precondition(error == .notSupported)
    } catch {
        preconditionFailure("expected DockKitError")
    }
}

func testDockAccessorySetLimitsThrow() {
    let accessory = makeHostAccessory()
    do {
        try accessory.setLimits(DockAccessory.Limits(yaw: nil, pitch: nil, roll: nil))
        preconditionFailure("setLimits must fail closed")
    } catch let error as DockKitError {
        precondition(error == .notSupported)
    } catch {
        preconditionFailure("expected DockKitError")
    }
}

func testDockAccessorySetOrientationVectorThrow() {
    let accessory = makeHostAccessory()
    do {
        _ = try accessory.setOrientation(Vector3D(x: 0, y: 0, z: 0))
        preconditionFailure("setOrientation(Vector3D) must fail closed")
    } catch let error as DockKitError {
        precondition(error == .notSupported)
    } catch {
        preconditionFailure("expected DockKitError")
    }
}

func testDockAccessorySetOrientationRotationThrow() {
    let accessory = makeHostAccessory()
    do {
        _ = try accessory.setOrientation(Rotation3D())
        preconditionFailure("setOrientation(Rotation3D) must fail closed")
    } catch let error as DockKitError {
        precondition(error == .notSupported)
    } catch {
        preconditionFailure("expected DockKitError")
    }
}

private func makeHostAccessory() -> DockAccessory {
    DockAccessory(
        identifier: DockAccessory.Identifier(
            name: "host-accessory",
            uuid: UUID(uuidString: "AAAAAAAA-0000-0000-0000-000000000099")!,
            category: .trackingStand
        )
    )
}
