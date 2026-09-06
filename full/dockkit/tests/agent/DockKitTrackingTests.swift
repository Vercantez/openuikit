import Foundation
import DockKit

func testTrackedObjectPropertiesAndEquality() {
    let id = UUID(uuidString: "33333333-3333-3333-3333-333333333333")!
    let rect = CGRect(x: 0, y: 0.1, width: 0.5, height: 0.6)
    let a = DockAccessory.TrackedObject(identifier: id, saliencyRank: 2, rect: rect)
    let b = DockAccessory.TrackedObject(identifier: id, saliencyRank: 2, rect: rect)
    let c = DockAccessory.TrackedObject(identifier: id, saliencyRank: nil, rect: rect)
    precondition(a.identifier == id)
    precondition(a.saliencyRank == 2)
    precondition(a.rect.width == 0.5)
    precondition(a == b)
    precondition(a != c)
}

func testTrackedPersonPropertiesAndEquality() {
    let id = UUID(uuidString: "44444444-4444-4444-4444-444444444444")!
    let rect = CGRect(x: 0.2, y: 0.3, width: 0.4, height: 0.5)
    let a = DockAccessory.TrackedPerson(
        identifier: id,
        saliencyRank: 0,
        speakingConfidence: 0.8,
        lookingAtCameraConfidence: 0.3,
        rect: rect
    )
    let b = DockAccessory.TrackedPerson(
        identifier: id,
        saliencyRank: 0,
        speakingConfidence: 0.8,
        lookingAtCameraConfidence: 0.3,
        rect: rect
    )
    let c = DockAccessory.TrackedPerson(identifier: id, rect: rect)
    precondition(a.identifier == id)
    precondition(a.saliencyRank == 0)
    precondition(a.speakingConfidence == 0.8)
    precondition(a.lookingAtCameraConfidence == 0.3)
    precondition(a.rect.height == 0.5)
    precondition(a == b)
    precondition(a != c)
}

func testTrackingStateProperties() {
    let time = Date(timeIntervalSince1970: 1_600_000_000)
    let person = DockAccessory.TrackedPerson(
        identifier: UUID(uuidString: "55555555-5555-5555-5555-555555555555")!,
        rect: .zero
    )
    let state = DockAccessory.TrackingState(
        trackedSubjects: [.person(person)],
        time: time
    )
    precondition(state.trackedSubjects.count == 1)
    precondition(state.time == time)
    precondition(state.description.contains("subjects: 1"))
}
