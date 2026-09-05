@_spi(OpenUIKitHost) import GroupActivities
import Foundation

func testGroupSessionWaitingState() {
    let id = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!
    let session = gaMakeSession(label: "waiting", id: id, locallyInitiated: true)
    gaRequire(session.id == id, "id")
    gaRequire(session.isLocallyInitiated, "locally initiated")
    gaRequire(session.state == .waiting, "waiting")
    gaRequire(session.activeParticipants.isEmpty, "no participants yet")
    gaRequire(session.sceneSessionIdentifier == nil, "no UIKit scene")
    gaRequire(session.activity.label == "waiting", "activity")
    gaRequire(session.description.contains(id.uuidString), "description")
    gaRequire(session.description.contains("waiting"), "description state")
}

func testGroupSessionJoinStateMachine() {
    let session = gaMakeSession(label: "join")
    session.join()
    gaRequire(session.state == .joined, "joined")
    gaRequire(session.activeParticipants == [session.localParticipant], "local joined")
    session.join()
    gaRequire(session.state == .joined, "join is idempotent while joined")
}

func testGroupSessionLeaveInvalidates() {
    let session = gaMakeSession(label: "leave")
    session.join()
    session.leave()
    gaRequire(
        session.state == .invalidated(reason: GroupActivitiesHostError.sessionLeft),
        "leave reason"
    )
    gaRequire(!session.activeParticipants.contains(session.localParticipant), "left set")
    session.leave()
    gaRequire(
        session.state == .invalidated(reason: GroupActivitiesHostError.sessionLeft),
        "leave while invalidated is a no-op"
    )
    session.join()
    gaRequire(
        session.state == .invalidated(reason: GroupActivitiesHostError.sessionLeft),
        "cannot rejoin after leave"
    )
}

func testGroupSessionEndInvalidates() {
    let session = gaMakeSession(label: "end")
    session.join()
    session.end()
    gaRequire(
        session.state == .invalidated(reason: GroupActivitiesHostError.sessionEnded),
        "end reason"
    )
    gaRequire(session.activeParticipants.isEmpty, "end clears participants")
    session.end()
    gaRequire(
        session.state == .invalidated(reason: GroupActivitiesHostError.sessionEnded),
        "end while invalidated is a no-op"
    )
}

func testGroupSessionEndFromWaiting() {
    let session = gaMakeSession(label: "end-waiting", locallyInitiated: false)
    gaRequire(!session.isLocallyInitiated, "remote")
    session.end()
    gaRequire(
        session.state == .invalidated(reason: GroupActivitiesHostError.sessionEnded),
        "end from waiting"
    )
}

func testGroupSessionStateEquality() {
    gaRequire(
        GroupSession<ProbeActivity>.State.waiting == .waiting,
        "waiting =="
    )
    gaRequire(
        GroupSession<ProbeActivity>.State.joined != .waiting,
        "state !="
    )
    gaRequire(
        GroupSession<ProbeActivity>.State.invalidated(reason: GroupActivitiesHostError.sessionLeft)
            == .invalidated(reason: GroupActivitiesHostError.sessionLeft),
        "invalidated identity"
    )
    gaRequire(
        GroupSession<ProbeActivity>.State.invalidated(reason: GroupActivitiesHostError.sessionLeft)
            != .invalidated(reason: GroupActivitiesHostError.sessionEnded),
        "invalidated reasons"
    )
}

func testGroupSessionActivityMutation() {
    let session = gaMakeSession(label: "original")
    session.activity = ProbeActivity(label: "updated")
    gaRequire(session.activity.label == "updated", "activity set")
}

func testGroupSessionLocalParticipant() {
    let session = gaMakeSession()
    gaRequire(session.localParticipant.id != UUID(), "has id")
    gaRequire(!session.localParticipant.isNearbyWithLocalParticipant, "nearby")
}

func testGroupSessionShowNotice() {
    let session = gaMakeSession()
    let event = GroupSessionEvent(
        originator: session.localParticipant,
        action: .play,
        url: nil
    )
    session.showNotice(event)
    gaRequire(session.hostLastNotice == event, "notice stored")
    gaRequire(session.state == .waiting, "notice does not join")
}

func testGroupSessionPostEvent() {
    let session = gaMakeSession()
    let posted = GroupSession<ProbeActivity>.Event(
        originator: session.localParticipant,
        localizedDescription: "hello"
    )
    gaRequire(posted.originator == session.localParticipant, "event originator")
    gaRequire(posted.localizedDescription == "hello", "event text")
    session.postEvent(posted)
    gaRequire(session.hostLastPostedEvent == posted, "posted")
}

func testGroupSessionRequestForeground() {
    let session = gaMakeSession()
    session.requestForegroundPresentation()
    gaRequire(session.hostDidRequestForeground, "recorded")
    gaRequire(session.state == .waiting, "no UI promotion")
}

func testGroupSessionSessionsSequence() {
    let sessions = ProbeActivity.sessions()
    gaRequire(
        ProbeActivity.Sessions.self == GroupSession<ProbeActivity>.Sessions.self,
        "Sessions alias"
    )
    gaRequire(
        GroupSession<ProbeActivity>.Sessions.Element.self == GroupSession<ProbeActivity>.self,
        "Element"
    )
    gaRequire(
        GroupSession<ProbeActivity>.Sessions.AsyncIterator.self
            == GroupSession<ProbeActivity>.Sessions.Iterator.self,
        "AsyncIterator"
    )
    gaRequire(
        GroupSession<ProbeActivity>.Sessions.Iterator.Element.self
            == GroupSession<ProbeActivity>.self,
        "Iterator.Element"
    )
    _ = sessions.makeAsyncIterator()
}

func testGroupStateObserverIneligible() {
    let observer = GroupStateObserver()
    gaRequire(!observer.isEligibleForGroupSession, "never eligible")
    let again = GroupStateObserver()
    gaRequire(!again.isEligibleForGroupSession, "init")
}
