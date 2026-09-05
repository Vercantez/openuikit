@_spi(OpenUIKitHost) import GroupActivities
import Foundation

func testParticipantIdentity() {
    let id = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
    let participant = Participant(id: id)
    gaRequire(participant.id == id, "id")
    gaRequire(Participant.ID.self == UUID.self, "ID alias")
    gaRequire(!participant.isNearbyWithLocalParticipant, "nearby always false")
    gaRequire(participant.description.contains(id.uuidString), "description")
    gaRequire(participant == Participant(id: id), "equal")
    gaRequire(participant != Participant(id: UUID()), "participant !=")
    var hasher = Hasher()
    participant.hash(into: &hasher)
    gaRequire(participant.hashValue == Participant(id: id).hashValue, "hashValue")
}

func testParticipantsCases() {
    let one = Participant(id: UUID())
    let onlyOne = Participants.only(one)
    gaRequire(Participants.all != onlyOne, "all != only")
    if case .only(let set) = onlyOne {
        gaRequire(set == [one], "only(_:) wraps a set")
    } else {
        fatalError("expected only")
    }
    let setCase = Participants.only(Set([one]))
    gaRequire(setCase == onlyOne, "only(Set) == only(participant)")
}

func testGroupSessionEventActions() {
    let originator = Participant(id: UUID())
    let url = URL(string: "https://example.invalid/song")
    let play = GroupSessionEvent(originator: originator, action: .play, url: url)
    gaRequire(play.originator == originator, "originator")
    gaRequire(play.action == .play, "play")
    gaRequire(play.url == url, "url")
    gaRequire(GroupSessionEvent.Action.pause == .pause, "pause")
    gaRequire(GroupSessionEvent.Action.seek == .seek, "seek")
    gaRequire(GroupSessionEvent.Action.updatedQueue == .updatedQueue, "updatedQueue let")
    gaRequire(GroupSessionEvent.Action.skip(item: "track") != .play, "skip")
    let song = GroupSessionEvent.Action.QueueChange.Item.song("song-a")
    let container = GroupSessionEvent.Action.QueueChange.Item.container("album")
    gaRequire(song != container, "item kinds")
    let added = GroupSessionEvent.Action.QueueChange.added(song)
    let upNext = GroupSessionEvent.Action.QueueChange.setUpNext(container)
    gaRequire(added != upNext, "queue change")
    let queued = GroupSessionEvent.Action.updatedQueue(added)
    gaRequire(queued != .updatedQueue, "updatedQueue(_:) distinct from let")
    gaRequire(
        GroupSessionEvent(originator: originator, action: .pause, url: nil).url == nil,
        "nil url"
    )
}
