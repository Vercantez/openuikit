@_spi(OpenUIKitHost) import GroupActivities
import Foundation

func testJournalAttachmentLoadMetadataAsync() async {
    let attachment = GroupSessionJournal.Attachment(id: UUID())
    do {
        let _: ProbeMessage = try await attachment.loadMetadata(of: ProbeMessage.self)
        gaRequire(false, "loadMetadata should throw")
    } catch {
        gaRequire(gaHostError(error) == .journalUnavailable, "journal")
    }
}

func testJournalAttachmentsIteratorNextAsync() async {
    let session = gaMakeSession()
    let journal = GroupSessionJournal(session: session)
    var iterator = journal.attachments.makeAsyncIterator()
    let value = await iterator.next()
    gaRequire(value == nil, "empty attachments")
}

func testJournalRemoveAttachmentAsync() async {
    let session = gaMakeSession()
    let journal = GroupSessionJournal(session: session)
    do {
        try await journal.remove(attachment: GroupSessionJournal.Attachment(id: UUID()))
        gaRequire(false, "remove should throw")
    } catch {
        gaRequire(gaHostError(error) == .journalUnavailable, "journal")
    }
}

func testMessengerSendDataAsync() async {
    let session = gaMakeSession()
    let messenger = GroupSessionMessenger(session: session)
    do {
        try await messenger.send(Data([0x01]), to: .all)
        gaRequire(false, "send should throw")
    } catch {
        gaRequire(gaHostError(error) == .messengerUnavailable, "messenger")
    }
}

func testMessengerSendMessageAsync() async {
    let session = gaMakeSession()
    let messenger = GroupSessionMessenger(session: session)
    do {
        try await messenger.send(ProbeMessage(text: "hi"), to: .all)
        gaRequire(false, "send should throw")
    } catch {
        gaRequire(gaHostError(error) == .messengerUnavailable, "messenger")
    }
}

func testMessengerMessagesIteratorNextAsync() async {
    let session = gaMakeSession()
    let messenger = GroupSessionMessenger(session: session)
    var iterator = messenger.messages(of: ProbeMessage.self).makeAsyncIterator()
    let value = await iterator.next()
    gaRequire(value == nil, "empty messages")
}

func testSessionsIteratorNextAsync() async {
    var iterator = ProbeActivity.sessions().makeAsyncIterator()
    let value = await iterator.next()
    gaRequire(value == nil, "empty sessions")
}

func testActivityMetadataGetterAsync() async {
    let activity = ProbeActivity(label: "meta")
    let metadata = await activity.metadata
    gaRequire(metadata == GroupActivityMetadata(), "default metadata")
}

func testPrepareForActivationAsync() async {
    let activity = ProbeActivity(label: "prep")
    let result = await activity.prepareForActivation()
    gaRequire(result == .activationDisabled, "disabled")
}

func testActivateAsync() async {
    let activity = ProbeActivity(label: "act")
    do {
        _ = try await activity.activate()
        gaRequire(false, "activate should throw")
    } catch {
        gaRequire(gaHostError(error) == .sharePlayUnavailable, "shareplay")
    }
}
