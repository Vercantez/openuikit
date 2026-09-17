import CoreGraphics
import Foundation
import DockKit

func testAsyncIteratorNextReturnsNil() async {
    var events = DockAccessory.AccessoryEvents().makeAsyncIterator()
    var motion = DockAccessory.MotionStates().makeAsyncIterator()
    var changes = DockAccessory.StateChanges().makeAsyncIterator()
    var batteries = DockAccessory.BatteryStates().makeAsyncIterator()
    var tracking = DockAccessory.TrackingStates().makeAsyncIterator()
    precondition(await events.next() == nil)
    precondition(await motion.next() == nil)
    precondition(await changes.next() == nil)
    precondition(await batteries.next() == nil)
    precondition(await tracking.next() == nil)
}

func testAsyncIteratorNextIsolationReturnsNil() async throws {
    var events = DockAccessory.AccessoryEvents().makeAsyncIterator()
    var motion = DockAccessory.MotionStates().makeAsyncIterator()
    var changes = DockAccessory.StateChanges().makeAsyncIterator()
    var batteries = DockAccessory.BatteryStates().makeAsyncIterator()
    var tracking = DockAccessory.TrackingStates().makeAsyncIterator()
    precondition(try await events.next(isolation: nil) == nil)
    precondition(try await motion.next(isolation: nil) == nil)
    precondition(try await changes.next(isolation: nil) == nil)
    precondition(try await batteries.next(isolation: nil) == nil)
    precondition(try await tracking.next(isolation: nil) == nil)
}

func testAsyncSequenceAllSatisfyOnEmpty() async throws {
    precondition(try await DockAccessory.AccessoryEvents().allSatisfy { _ in false })
    precondition(try await DockAccessory.MotionStates().allSatisfy { _ in false })
    precondition(try await DockAccessory.StateChanges().allSatisfy { _ in false })
    precondition(try await DockAccessory.BatteryStates().allSatisfy { _ in false })
    precondition(try await DockAccessory.TrackingStates().allSatisfy { _ in false })
}

func testAsyncSequenceContainsWhereOnEmpty() async throws {
    precondition(try await DockAccessory.AccessoryEvents().contains { _ in true } == false)
    precondition(try await DockAccessory.MotionStates().contains { _ in true } == false)
    precondition(try await DockAccessory.StateChanges().contains { _ in true } == false)
    precondition(try await DockAccessory.BatteryStates().contains { _ in true } == false)
    precondition(try await DockAccessory.TrackingStates().contains { _ in true } == false)
}

func testAsyncSequenceContainsElementOnEmpty() async {
    precondition(await DockAccessory.AccessoryEvents().contains(.cameraShutter) == false)
    precondition(
        await DockAccessory.BatteryStates().contains(
            DockAccessory.BatteryState(
                name: "pack",
                batteryLevel: 1,
                chargeState: .notCharging,
                lowBattery: false
            )
        ) == false
    )
}

func testAsyncSequenceFirstWhereOnEmpty() async throws {
    precondition(try await DockAccessory.AccessoryEvents().first { _ in true } == nil)
    precondition(try await DockAccessory.MotionStates().first { _ in true } == nil)
    precondition(try await DockAccessory.StateChanges().first { _ in true } == nil)
    precondition(try await DockAccessory.BatteryStates().first { _ in true } == nil)
    precondition(try await DockAccessory.TrackingStates().first { _ in true } == nil)
}

func testAsyncSequenceReduceOnEmpty() async throws {
    precondition(try await DockAccessory.AccessoryEvents().reduce(0) { acc, _ in acc + 1 } == 0)
    precondition(try await DockAccessory.MotionStates().reduce(0) { acc, _ in acc + 1 } == 0)
    precondition(try await DockAccessory.StateChanges().reduce(0) { acc, _ in acc + 1 } == 0)
    precondition(try await DockAccessory.BatteryStates().reduce(0) { acc, _ in acc + 1 } == 0)
    precondition(try await DockAccessory.TrackingStates().reduce(0) { acc, _ in acc + 1 } == 0)
    var eventCount = 0
    _ = try await DockAccessory.AccessoryEvents().reduce(into: 0) { acc, _ in
        acc += 1
        eventCount = acc
    }
    var motionCount = 0
    _ = try await DockAccessory.MotionStates().reduce(into: 0) { acc, _ in
        acc += 1
        motionCount = acc
    }
    var changeCount = 0
    _ = try await DockAccessory.StateChanges().reduce(into: 0) { acc, _ in
        acc += 1
        changeCount = acc
    }
    var batteryCount = 0
    _ = try await DockAccessory.BatteryStates().reduce(into: 0) { acc, _ in
        acc += 1
        batteryCount = acc
    }
    var trackingCount = 0
    _ = try await DockAccessory.TrackingStates().reduce(into: 0) { acc, _ in
        acc += 1
        trackingCount = acc
    }
    precondition(eventCount == 0)
    precondition(motionCount == 0)
    precondition(changeCount == 0)
    precondition(batteryCount == 0)
    precondition(trackingCount == 0)
}

func testAsyncSequenceMinMaxOnEmpty() async throws {
    precondition(try await DockAccessory.AccessoryEvents().max { _, _ in true } == nil)
    precondition(try await DockAccessory.MotionStates().max { _, _ in true } == nil)
    precondition(try await DockAccessory.StateChanges().max { _, _ in true } == nil)
    precondition(try await DockAccessory.BatteryStates().max { _, _ in true } == nil)
    precondition(try await DockAccessory.TrackingStates().max { _, _ in true } == nil)
    precondition(try await DockAccessory.AccessoryEvents().min { _, _ in true } == nil)
    precondition(try await DockAccessory.MotionStates().min { _, _ in true } == nil)
    precondition(try await DockAccessory.StateChanges().min { _, _ in true } == nil)
    precondition(try await DockAccessory.BatteryStates().min { _, _ in true } == nil)
    precondition(try await DockAccessory.TrackingStates().min { _, _ in true } == nil)
}

func testAsyncHardwareCommandsFailClosed() async {
    let accessory = DockAccessory(
        identifier: DockAccessory.Identifier(
            name: "dock",
            uuid: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
            category: .trackingStand
        )
    )
    let info = DockAccessory.CameraInformation(
        captureDevice: AVCaptureDevice.DeviceType(rawValue: "wide"),
        cameraPosition: .front,
        orientation: .portrait,
        cameraIntrinsics: nil,
        referenceDimensions: nil
    )
    func expectUnsupported(_ body: () async throws -> Void) async {
        do {
            try await body()
            preconditionFailure("DockKit hardware must fail closed")
        } catch let error as DockKitError {
            precondition(error == .notSupported)
        } catch {
            preconditionFailure("expected DockKitError.notSupported")
        }
    }
    await expectUnsupported { try await DockAccessoryManager.shared.setSystemTrackingEnabled(true) }
    await expectUnsupported { try await accessory.selectSubject(at: .zero) }
    await expectUnsupported { try await accessory.selectSubjects([]) }
    await expectUnsupported { try await accessory.setFramingMode(.center) }
    await expectUnsupported {
        _ = try await accessory.setOrientation(Vector3D(), duration: .seconds(0), relative: false)
    }
    await expectUnsupported {
        _ = try await accessory.setOrientation(Rotation3D(), duration: .seconds(0), relative: false)
    }
    await expectUnsupported { try await accessory.setAngularVelocity(Vector3D()) }
    await expectUnsupported { try await accessory.setRegionOfInterest(.zero) }
    await expectUnsupported {
        try await accessory.track([] as [DockAccessory.Observation], cameraInformation: info)
    }
    await expectUnsupported {
        try await accessory.track(
            [] as [DockAccessory.Observation],
            cameraInformation: info,
            image: CVPixelBuffer()
        )
    }
    await expectUnsupported {
        try await accessory.track([] as [AVMetadataObject], cameraInformation: info)
    }
    await expectUnsupported {
        try await accessory.track(
            [] as [AVMetadataObject],
            cameraInformation: info,
            image: CVPixelBuffer()
        )
    }
    await expectUnsupported { _ = try await accessory.animate(motion: .wakeup) }
}
