import Foundation
import DockKit

func testFramingModeCases() {
    let modes: [DockAccessory.FramingMode] = [
        .automatic, .center, .left, .right,
    ]
    precondition(modes.count == 4)
    precondition(DockAccessory.FramingMode.automatic != .center)
    precondition(DockAccessory.FramingMode.left != .right)
    var hasher = Hasher()
    DockAccessory.FramingMode.center.hash(into: &hasher)
    precondition(DockAccessory.FramingMode.automatic.hashValue == DockAccessory.FramingMode.automatic.hashValue)
}

func testFramingModeCodable() {
    let encoder = JSONEncoder()
    let decoder = JSONDecoder()
    for mode in [
        DockAccessory.FramingMode.automatic,
        .center,
        .left,
        .right,
    ] {
        do {
            let data = try encoder.encode(mode)
            let roundTrip = try decoder.decode(DockAccessory.FramingMode.self, from: data)
            precondition(roundTrip == mode)
            let text = String(data: data, encoding: .utf8) ?? ""
            switch mode {
            case .automatic: precondition(text.contains("automatic"))
            case .center: precondition(text.contains("center"))
            case .left: precondition(text.contains("left"))
            case .right: precondition(text.contains("right"))
            }
        } catch {
            preconditionFailure("FramingMode Codable failed: \(error)")
        }
    }
}

func testCategoryCases() {
    let category = DockAccessory.Category.trackingStand
    precondition(category == .trackingStand)
    precondition(!(category != .trackingStand))
    precondition(category.debugDescription == "trackingStand")
    var hasher = Hasher()
    category.hash(into: &hasher)
    precondition(category.hashValue == DockAccessory.Category.trackingStand.hashValue)
}

func testCategoryCodable() {
    do {
        let data = try JSONEncoder().encode(DockAccessory.Category.trackingStand)
        let roundTrip = try JSONDecoder().decode(DockAccessory.Category.self, from: data)
        precondition(roundTrip == .trackingStand)
        let text = String(data: data, encoding: .utf8) ?? ""
        precondition(text.contains("trackingStand"))
    } catch {
        preconditionFailure("Category Codable failed: \(error)")
    }
}

func testCameraOrientationCases() {
    let cases: [DockAccessory.CameraOrientation] = [
        .unknown,
        .portrait,
        .portraitUpsideDown,
        .landscapeRight,
        .landscapeLeft,
        .faceUp,
        .faceDown,
        .corrected,
    ]
    precondition(cases.count == 8)
    precondition(DockAccessory.CameraOrientation.portrait != .landscapeLeft)
    precondition(DockAccessory.CameraOrientation.unknown != .corrected)
    var hasher = Hasher()
    DockAccessory.CameraOrientation.portrait.hash(into: &hasher)
    precondition(DockAccessory.CameraOrientation.faceDown.hashValue == DockAccessory.CameraOrientation.faceDown.hashValue)
}

func testBatteryChargeStateCases() {
    let cases: [DockAccessory.BatteryChargeState] = [
        .notCharging, .charging, .notChargeable,
    ]
    precondition(cases.count == 3)
    precondition(DockAccessory.BatteryChargeState.charging != .notCharging)
    precondition(DockAccessory.BatteryChargeState.notChargeable != .charging)
    var hasher = Hasher()
    DockAccessory.BatteryChargeState.charging.hash(into: &hasher)
    precondition(DockAccessory.BatteryChargeState.notCharging.hashValue == DockAccessory.BatteryChargeState.notCharging.hashValue)
}

func testObservationTypeCases() {
    let cases: [DockAccessory.Observation.ObservationType] = [
        .humanFace, .humanBody, .object,
    ]
    precondition(cases.count == 3)
    precondition(DockAccessory.Observation.ObservationType.humanFace != .humanBody)
    precondition(DockAccessory.Observation.ObservationType.object != .humanFace)
    var hasher = Hasher()
    DockAccessory.Observation.ObservationType.object.hash(into: &hasher)
    precondition(
        DockAccessory.Observation.ObservationType.humanBody.hashValue
            == DockAccessory.Observation.ObservationType.humanBody.hashValue
    )
}

func testAccessoryStateCases() {
    precondition(DockAccessory.State.undocked != .docked)
    precondition(DockAccessory.State.docked.debugDescription == "docked")
    precondition(DockAccessory.State.undocked.debugDescription == "undocked")
    var hasher = Hasher()
    DockAccessory.State.docked.hash(into: &hasher)
    precondition(DockAccessory.State.docked.hashValue == DockAccessory.State.docked.hashValue)
    precondition(DockAccessory.State.undocked == .undocked)
}

func testAnimationCases() {
    let cases: [DockAccessory.Animation] = [.wakeup, .yes, .no, .kapow]
    precondition(cases.count == 4)
    precondition(DockAccessory.Animation.yes != .no)
    precondition(DockAccessory.Animation.wakeup != .kapow)
    var hasher = Hasher()
    DockAccessory.Animation.kapow.hash(into: &hasher)
    precondition(DockAccessory.Animation.wakeup.hashValue == DockAccessory.Animation.wakeup.hashValue)
}

func testAccessoryEventCases() {
    let flip = DockAccessory.AccessoryEvent.cameraFlip
    let shutter = DockAccessory.AccessoryEvent.cameraShutter
    let zoom = DockAccessory.AccessoryEvent.cameraZoom(factor: 2.5)
    let zoomSame = DockAccessory.AccessoryEvent.cameraZoom(factor: 2.5)
    let zoomOther = DockAccessory.AccessoryEvent.cameraZoom(factor: 1.0)
    let button = DockAccessory.AccessoryEvent.button(id: 3, pressed: true)
    let buttonUp = DockAccessory.AccessoryEvent.button(id: 3, pressed: false)
    precondition(flip != shutter)
    precondition(zoom == zoomSame)
    precondition(zoom != zoomOther)
    precondition(button != buttonUp)
    precondition(flip == .cameraFlip)
    var hasherA = Hasher()
    var hasherB = Hasher()
    zoom.hash(into: &hasherA)
    zoomSame.hash(into: &hasherB)
    precondition(hasherA.finalize() == hasherB.finalize())
    precondition(shutter.hashValue == DockAccessory.AccessoryEvent.cameraShutter.hashValue)
}

func testTrackedSubjectTypeCases() {
    let object = DockAccessory.TrackedObject(
        identifier: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
        saliencyRank: 1,
        rect: CGRect(x: 0, y: 0, width: 1, height: 1)
    )
    let person = DockAccessory.TrackedPerson(
        identifier: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
        rect: CGRect(x: 0.2, y: 0.2, width: 0.4, height: 0.5)
    )
    let a = DockAccessory.TrackedSubjectType.object(object)
    let b = DockAccessory.TrackedSubjectType.person(person)
    precondition(a != b)
    precondition(a == .object(object))
    precondition(b == .person(person))
}
