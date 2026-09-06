@_spi(OpenUIKitHost) import SharedWithYouCore
import Foundation

func testSWStartCollaborationActionClass() {
    let metadata = SWCollaborationMetadata(
        collaborationIdentifier: SWCollaborationIdentifier("start.meta")
    )
    let action = SharedWithYouCoreHostControl.makeStartCollaborationAction(metadata: metadata)
    swcRequireType(action, as: SWStartCollaborationAction.self)
    swcRequireType(action, as: SWAction.self)
    precondition(action.isComplete == false)
}

func testSWStartCollaborationActionCollaborationMetadata() {
    let metadata = SWCollaborationMetadata(
        collaborationIdentifier: SWCollaborationIdentifier("start.meta")
    )
    metadata.title = "Doc"
    let action = SharedWithYouCoreHostControl.makeStartCollaborationAction(metadata: metadata)
    precondition(action.collaborationMetadata.collaborationIdentifier.rawValue == "start.meta")
    precondition(action.collaborationMetadata.title == "Doc")
}

func testSWStartCollaborationActionFulfillUsingCollaborationIdentifier() {
    let metadata = SWCollaborationMetadata(
        localIdentifier: SWLocalCollaborationIdentifier("pending.local")
    )
    let action = SharedWithYouCoreHostControl.makeStartCollaborationAction(metadata: metadata)
    let url = URL(string: "https://example.invalid/share/doc")!
    let identifier = SWCollaborationIdentifier("cloud.collab")
    action.fulfill(using: url, collaborationIdentifier: identifier)
    precondition(action.isComplete)
    precondition(SharedWithYouCoreHostControl.actionCompletion(action) == .fulfilled)
    precondition(SharedWithYouCoreHostControl.fulfilledURL(action) == url)
    precondition(
        SharedWithYouCoreHostControl.fulfilledCollaborationIdentifier(action) == identifier
    )
    let other = URL(string: "https://example.invalid/other")!
    action.fulfill(using: other, collaborationIdentifier: SWCollaborationIdentifier("ignored"))
    precondition(SharedWithYouCoreHostControl.fulfilledURL(action) == url)
}

func testSWUpdateCollaborationParticipantsActionClass() {
    let metadata = SWCollaborationMetadata(
        collaborationIdentifier: SWCollaborationIdentifier("update.meta")
    )
    let action = SharedWithYouCoreHostControl.makeUpdateCollaborationParticipantsAction(
        metadata: metadata
    )
    swcRequireType(action, as: SWUpdateCollaborationParticipantsAction.self)
    swcRequireType(action, as: SWAction.self)
}

func testSWUpdateCollaborationParticipantsActionCollaborationMetadata() {
    let metadata = SWCollaborationMetadata(
        collaborationIdentifier: SWCollaborationIdentifier("update.meta")
    )
    metadata.title = "Roster"
    let action = SharedWithYouCoreHostControl.makeUpdateCollaborationParticipantsAction(
        metadata: metadata
    )
    precondition(action.collaborationMetadata.title == "Roster")
}

func testSWUpdateCollaborationParticipantsActionAddedIdentities() {
    let added = SWPerson.Identity(rootHash: Data([0x0a]))
    let metadata = SWCollaborationMetadata(
        collaborationIdentifier: SWCollaborationIdentifier("update.added")
    )
    let action = SharedWithYouCoreHostControl.makeUpdateCollaborationParticipantsAction(
        metadata: metadata,
        addedIdentities: [added]
    )
    precondition(action.addedIdentities.count == 1)
    precondition(action.addedIdentities[0].rootHash == Data([0x0a]))
}

func testSWUpdateCollaborationParticipantsActionRemovedIdentities() {
    let removed = SWPerson.Identity(rootHash: Data([0x0b]))
    let metadata = SWCollaborationMetadata(
        collaborationIdentifier: SWCollaborationIdentifier("update.removed")
    )
    let action = SharedWithYouCoreHostControl.makeUpdateCollaborationParticipantsAction(
        metadata: metadata,
        removedIdentities: [removed]
    )
    precondition(action.removedIdentities.count == 1)
    precondition(action.removedIdentities[0].rootHash == Data([0x0b]))
}
