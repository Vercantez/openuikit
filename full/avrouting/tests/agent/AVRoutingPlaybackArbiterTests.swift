import Foundation
import AVRouting

final class RoutingPlaybackStub: NSObject, AVRoutingPlaybackParticipant {}

func testRoutingPlaybackParticipantConformance() {
    let participant = RoutingPlaybackStub()
    let asProtocol: any AVRoutingPlaybackParticipant = participant
    precondition(asProtocol === participant)
    let arbiter = AVRoutingPlaybackArbiter.shared()
    arbiter.preferredParticipantForExternalPlayback = asProtocol
    precondition(arbiter.preferredParticipantForExternalPlayback === participant)
    arbiter.preferredParticipantForExternalPlayback = nil
}

func testRoutingPlaybackArbiterIsNSObjectSubclass() {
    let arbiter = AVRoutingPlaybackArbiter.shared()
    let asObject: NSObject = arbiter
    precondition(asObject === arbiter)
}

func testRoutingPlaybackArbiterSharedIdentity() {
    let first = AVRoutingPlaybackArbiter.shared()
    let second = AVRoutingPlaybackArbiter.shared()
    precondition(first === second)
    let participant = RoutingPlaybackStub()
    first.preferredParticipantForExternalPlayback = participant
    precondition(second.preferredParticipantForExternalPlayback === participant)
    precondition(second.preferredParticipantForExternalPlayback === first.preferredParticipantForExternalPlayback)
    first.preferredParticipantForExternalPlayback = nil
}

func testRoutingPlaybackArbiterPreferredParticipantWeak() {
    let arbiter = AVRoutingPlaybackArbiter.shared()
    arbiter.preferredParticipantForExternalPlayback = nil
    precondition(arbiter.preferredParticipantForExternalPlayback == nil)
    do {
        let participant = RoutingPlaybackStub()
        arbiter.preferredParticipantForExternalPlayback = participant
        precondition(arbiter.preferredParticipantForExternalPlayback === participant)
        arbiter.preferredParticipantForExternalPlayback = nil
        precondition(arbiter.preferredParticipantForExternalPlayback == nil)
        arbiter.preferredParticipantForExternalPlayback = participant
        precondition(arbiter.preferredParticipantForExternalPlayback === participant)
    }
    precondition(arbiter.preferredParticipantForExternalPlayback == nil)
}
