@_spi(OpenUIKitHost) import GroupActivities
import Foundation

func testGroupActivityIdentifier() {
    let identifier = ProbeActivity.activityIdentifier
    gaRequire(identifier.contains("ProbeActivity"), "type name")
    gaRequire(identifier.contains("."), "bundle prefix")
}

func testGroupActivitySessionsFactory() {
    let sessions = ProbeActivity.sessions()
    _ = sessions.makeAsyncIterator()
}

func testGroupActivityProtocolSurface() {
    gaRequire((ProbeActivity.self as any GroupActivity.Type).activityIdentifier == ProbeActivity.activityIdentifier, "protocol witness")
}

func testMessengerDefaultDeliveryMode() {
    let session = gaMakeSession()
    let messenger = GroupSessionMessenger(session: session)
    gaRequire(messenger.deliveryMode == .reliable, "default reliable")
}

func testMessengerExplicitDeliveryMode() {
    let session = gaMakeSession()
    let messenger = GroupSessionMessenger(session: session, deliveryMode: .unreliable)
    gaRequire(messenger.deliveryMode == .unreliable, "unreliable")
}

func testMessengerSendDataCompletionFailsClosed() {
    let session = gaMakeSession()
    let messenger = GroupSessionMessenger(session: session)
    var seen: (any Error)?
    messenger.send(Data([0x01, 0x02]), to: .all) { error in
        seen = error
    }
    let host = gaHostError(seen)
    gaRequire(host == .messengerUnavailable, "data send")
    gaRequire(host.errorCode == 6, "code")
}

func testMessengerSendMessageCompletionFailsClosed() {
    let session = gaMakeSession()
    let messenger = GroupSessionMessenger(session: session)
    var seen: (any Error)?
    messenger.send(ProbeMessage(text: "hi"), to: .only(session.localParticipant)) { error in
        seen = error
    }
    gaRequire(gaHostError(seen) == .messengerUnavailable, "codable send")
}

func testMessengerMessageContextSource() {
    let participant = Participant(id: UUID())
    let context = GroupSessionMessenger.MessageContext(source: participant)
    gaRequire(context.source == participant, "source")
}

func testMessengerMessagesSequence() {
    let session = gaMakeSession()
    let messenger = GroupSessionMessenger(session: session)
    let dataMessages = messenger.messages(of: Data.self)
    gaRequire(
        GroupSessionMessenger.Messages<Data>.Element.self
            == GroupSessionMessenger.Messages<Data>.Iterator.Element.self,
        "Element"
    )
    gaRequire(
        GroupSessionMessenger.Messages<Data>.AsyncIterator.self
            == GroupSessionMessenger.Messages<Data>.Iterator.self,
        "AsyncIterator"
    )
    gaRequire(
        GroupSessionMessenger.Messages<Data>.Iterator.Element.self
            == GroupSessionMessenger.Messages<Data>.Element.self,
        "Iterator.Element"
    )
    _ = dataMessages.makeAsyncIterator()
    let typed = messenger.messages(of: ProbeMessage.self)
    _ = typed.makeAsyncIterator()
}

func testJournalAttachmentsSequence() {
    let session = gaMakeSession()
    let journal = GroupSessionJournal(session: session)
    gaRequire(
        GroupSessionJournal.Attachments.Element.self == [GroupSessionJournal.Attachment].self,
        "Element"
    )
    gaRequire(
        GroupSessionJournal.Attachments.AsyncIterator.self
            == GroupSessionJournal.Attachments.Iterator.self,
        "AsyncIterator"
    )
    gaRequire(
        GroupSessionJournal.Attachments.Iterator.Element.self
            == GroupSessionJournal.Attachments.Element.self,
        "Iterator.Element"
    )
    _ = journal.attachments.makeAsyncIterator()
    let copy = journal.attachments
    journal.attachments = copy
    _ = journal.attachments
}

func testJournalAttachmentIdentity() {
    let id = UUID(uuidString: "33333333-3333-3333-3333-333333333333")!
    let attachment = GroupSessionJournal.Attachment(id: id)
    gaRequire(attachment.id == id, "id")
    gaRequire(GroupSessionJournal.Attachment.ID.self == UUID.self, "ID alias")
    gaRequire(attachment == GroupSessionJournal.Attachment(id: id), "equal")
}
