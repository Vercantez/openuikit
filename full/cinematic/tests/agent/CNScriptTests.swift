import Foundation
import Cinematic

private func cnTime(_ seconds: Double) -> CMTime {
    CMTime(seconds: seconds, preferredTimescale: 600)
}

private func cnRange(start: Double, duration: Double) -> CMTimeRange {
    CMTimeRange(start: cnTime(start), duration: cnTime(duration))
}

private func cnDetection(seconds: Double, type: CNDetectionType, disparity: Float) -> CNDetection {
    CNDetection(
        time: cnTime(seconds),
        detectionType: type,
        normalizedRect: CGRect(x: 0.1, y: 0.1, width: 0.2, height: 0.3),
        focusDisparity: disparity
    )
}

func testCNScriptHostMakeTimeRangeAndFNumber() {
    let script = CNScript.host_make(timeRange: cnRange(start: 0, duration: 10), fNumber: 1.8)
    precondition(script.timeRange.duration.seconds == 10)
    precondition(script.fNumber == 1.8)
    script.fNumber = 4.0
    precondition(script.fNumber == 4.0)
}

func testCNScriptAddAndRemoveUserDecision() {
    let script = CNScript.host_make(timeRange: cnRange(start: 0, duration: 10))
    let decision = CNDecision(time: cnTime(1), detectionID: CNDetectionID(3), strong: true)
    precondition(script.addUserDecision(decision))
    let users = script.userDecisions(in: cnRange(start: 0, duration: 10))
    precondition(users.count == 1)
    precondition(users[0].isUserDecision)
    precondition(users[0].isStrongDecision)
    precondition(script.removeUserDecision(decision))
    precondition(script.userDecisions(in: cnRange(start: 0, duration: 10)).isEmpty)
}

func testCNScriptRemoveAllUserDecisions() {
    let script = CNScript.host_make(timeRange: cnRange(start: 0, duration: 10))
    _ = script.addUserDecision(CNDecision(time: cnTime(1), detectionID: CNDetectionID(1), strong: false))
    _ = script.addUserDecision(CNDecision(time: cnTime(2), detectionID: CNDetectionID(2), strong: true))
    script.removeAllUserDecisions()
    precondition(script.userDecisions(in: cnRange(start: 0, duration: 10)).isEmpty)
}

func testCNScriptAddAndRemoveDetectionTrack() {
    let script = CNScript.host_make(timeRange: cnRange(start: 0, duration: 10))
    let track = CNFixedDetectionTrack(focusDisparity: 0.3)
    let assigned = script.addDetectionTrack(track)
    precondition(assigned == track.detectionID)
    precondition(script.addedDetectionTracks.count == 1)
    precondition(script.detectionTrack(for: assigned) === track)
    precondition(script.removeDetectionTrack(track))
    precondition(script.addedDetectionTracks.isEmpty)
}

func testCNScriptDetectionTrackForDecision() {
    let script = CNScript.host_make(timeRange: cnRange(start: 0, duration: 10))
    let track = CNCustomDetectionTrack(
        detections: [cnDetection(seconds: 1, type: .humanFace, disparity: 0.4)],
        smooth: false
    )
    _ = script.addDetectionTrack(track)
    let decision = CNDecision(time: cnTime(1), detectionID: track.detectionID, strong: true)
    precondition(script.detectionTrack(for: decision) === track)
}

func testCNScriptBaseAndMergedDecisions() {
    let base = CNDecision(time: cnTime(1), detectionID: CNDetectionID(1), strong: false)
    let script = CNScript.host_make(
        timeRange: cnRange(start: 0, duration: 10),
        baseDecisions: [base]
    )
    let user = CNDecision(time: cnTime(2), detectionID: CNDetectionID(2), strong: true)
    _ = script.addUserDecision(user)
    precondition(script.baseDecisions(in: cnRange(start: 0, duration: 10)).count == 1)
    precondition(script.decisions(in: cnRange(start: 0, duration: 10)).count == 2)
}

func testCNScriptDecisionAtTolerance() {
    let decision = CNDecision(time: cnTime(5), detectionID: CNDetectionID(4), strong: true)
    let script = CNScript.host_make(
        timeRange: cnRange(start: 0, duration: 10),
        baseDecisions: [decision]
    )
    let found = script.decision(at: cnTime(5.01), tolerance: cnTime(0.05))
    precondition(found?.focusDetectionID == .single(CNDetectionID(4)))
    let missing = script.decision(at: cnTime(8), tolerance: cnTime(0.01))
    precondition(missing == nil)
}

func testCNScriptDecisionAfterAndBefore() {
    let first = CNDecision(time: cnTime(1), detectionID: CNDetectionID(1), strong: false)
    let second = CNDecision(time: cnTime(4), detectionID: CNDetectionID(2), strong: false)
    let script = CNScript.host_make(
        timeRange: cnRange(start: 0, duration: 10),
        baseDecisions: [first, second]
    )
    precondition(script.decision(after: cnTime(1))?.time.seconds == 4)
    precondition(script.decision(before: cnTime(4))?.time.seconds == 1)
    precondition(script.decision(after: cnTime(4)) == nil)
    precondition(script.decision(before: cnTime(1)) == nil)
}

func testCNScriptPrimaryAndSecondaryDecision() {
    let base = CNDecision(time: cnTime(1), detectionID: CNDetectionID(1), strong: false)
    let script = CNScript.host_make(
        timeRange: cnRange(start: 0, duration: 10),
        baseDecisions: [base]
    )
    precondition(script.primaryDecision(at: cnTime(2))?.focusDetectionID == .single(CNDetectionID(1)))
    precondition(script.secondaryDecision(at: cnTime(2)) == nil)
    let user = CNDecision(time: cnTime(1.5), detectionID: CNDetectionID(9), strong: true)
    _ = script.addUserDecision(user)
    let primary = script.primaryDecision(at: cnTime(2))
    precondition(primary?.isUserDecision == true)
    precondition(script.secondaryDecision(at: cnTime(2))?.focusDetectionID == .single(CNDetectionID(1)))
}

func testCNScriptTimeRangeOfTransitionAfterAndBefore() {
    let first = CNDecision(time: cnTime(1), detectionID: CNDetectionID(1), strong: true)
    let second = CNDecision(time: cnTime(4), detectionID: CNDetectionID(2), strong: true)
    let script = CNScript.host_make(
        timeRange: cnRange(start: 0, duration: 10),
        baseDecisions: [first, second]
    )
    let after = script.timeRangeOfTransition(after: first)
    precondition(abs(after.duration.seconds - 3) < 0.001)
    let before = script.timeRangeOfTransition(before: second)
    precondition(abs(before.duration.seconds - 3) < 0.001)
    let trailing = script.timeRangeOfTransition(after: second)
    precondition(trailing.duration.seconds == 0)
}

func testCNScriptFrameAtTime() {
    let detection = cnDetection(seconds: 1, type: .humanFace, disparity: 0.5)
    let track = CNCustomDetectionTrack(detections: [detection], smooth: false)
    let script = CNScript.host_make(
        timeRange: cnRange(start: 0, duration: 10),
        detections: []
    )
    _ = script.addDetectionTrack(track)
    _ = script.addUserDecision(
        CNDecision(time: cnTime(1), detectionID: track.detectionID, strong: true)
    )
    let frame = script.frame(at: cnTime(1), tolerance: cnTime(0.1))
    precondition(frame != nil)
    precondition(frame?.time.seconds == 1)
    precondition(frame?.focusDisparity == 0.5)
    precondition(frame?.focusDetection.detectionType == .humanFace)
    precondition(frame?.allDetections.isEmpty == false)
    precondition(frame?.detection(for: track.detectionID) != nil)
    precondition(frame?.bestDetection(for: track.detectionGroupID)?.detectionID == track.detectionID)
}

func testCNScriptFramesInRange() {
    let early = cnDetection(seconds: 1, type: .humanFace, disparity: 0.2)
    let late = cnDetection(seconds: 5, type: .humanFace, disparity: 0.9)
    let script = CNScript.host_make(
        timeRange: cnRange(start: 0, duration: 10),
        detections: [early, late]
    )
    let frames = script.frames(in: cnRange(start: 0, duration: 3))
    precondition(frames.count == 1)
    precondition(frames[0].focusDisparity == 0.2)
}

func testCNScriptChangesRoundTrip() {
    let script = CNScript.host_make(timeRange: cnRange(start: 0, duration: 10), fNumber: 2.2)
    _ = script.addUserDecision(CNDecision(time: cnTime(3), detectionID: CNDetectionID(6), strong: true))
    let track = CNFixedDetectionTrack(focusDisparity: 0.44)
    _ = script.addDetectionTrack(track)
    let snapshot = script.changes()
    precondition(snapshot.fNumber == 2.2)
    precondition(snapshot.userDecisions.count == 1)
    precondition(snapshot.addedDetectionTracks.count == 1)
    let data = snapshot.dataRepresentation
    let restored = CNScript.Changes(dataRepresentation: data)
    precondition(restored != nil)
    precondition(restored?.fNumber == 2.2)
    precondition(restored?.userDecisions.count == 1)
    precondition(restored?.userDecisions.first?.isUserDecision == true)
    precondition(restored?.addedDetectionTracks.count == 1)
}

func testCNScriptChangesInitRejectsGarbage() {
    precondition(CNScript.Changes(dataRepresentation: Data([0x00, 0x01, 0x02])) == nil)
    precondition(CNScript.Changes(dataRepresentation: Data()) == nil)
}

func testCNScriptReloadAndTrimmedChanges() {
    let script = CNScript.host_make(timeRange: cnRange(start: 0, duration: 10), fNumber: 2.8)
    _ = script.addUserDecision(CNDecision(time: cnTime(1), detectionID: CNDetectionID(1), strong: false))
    _ = script.addUserDecision(CNDecision(time: cnTime(8), detectionID: CNDetectionID(2), strong: true))
    let trimmed = script.changes(trimmedBy: cnRange(start: 0, duration: 5))
    precondition(trimmed.userDecisions.count == 1)
    precondition(trimmed.userDecisions[0].time.seconds == 1)
    script.reload(changes: trimmed)
    precondition(script.userDecisions(in: cnRange(start: 0, duration: 10)).count == 1)
    script.reload(changes: nil)
    precondition(script.userDecisions(in: cnRange(start: 0, duration: 10)).isEmpty)
}
