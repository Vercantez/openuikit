import Foundation
import TelephonyMessagingKit

func testRCSConfigurationAndRequests() {
    let cfg = RCSService.Configuration(
        maximumGroupSize: 100,
        chatRevokeTimeout: .seconds(30),
        maximumTextMessageSize: Measurement(value: 8, unit: .kilobytes),
        fileTransferWarningSize: Measurement(value: 10, unit: .megabytes),
        maximumFileTransferSize: Measurement(value: 100, unit: .megabytes)
    )
    precondition(cfg.maximumGroupSize == 100)
    precondition(cfg.chatRevokeTimeout == .seconds(30))

    let upload = RCSService.FileUploadRequest(
        cellularServiceID: tmkServiceID(),
        fileURL: tmkURL(),
        contentType: .jpeg,
        thumbnailURL: tmkURL(),
        thumbnailContentType: .jpeg
    )
    precondition(upload.fileURL == tmkURL())
    let uploadMeta = RCSService.FileUploadRequest.Metadata(
        fileMetadata: tmkFileMeta(),
        thumbnailMetadata: tmkFileMeta(),
        transactionID: UUID(uuidString: "00000000-0000-0000-0000-0000000000aa")!
    )
    precondition(uploadMeta.fileMetadata.fileSize == 2048)

    let download = RCSService.FileDownloadRequest(
        cellularServiceID: tmkServiceID(),
        fileURL: tmkURL(),
        destinationFileURL: tmkURL()
    )
    precondition(download.destinationFileURL.host == "example.invalid")
    let downloadMeta = RCSService.FileDownloadRequest.Metadata(suggestedFileName: "a.bin", contentType: .data)
    precondition(downloadMeta.suggestedFileName == "a.bin")

    let spam = RCSService.ReportSpamRequest(
        message: tmkRCSMessage(),
        fileContent: Data("evidence".utf8),
        category: .fraud,
        reason: "scam"
    )
    precondition(spam.category == .fraud)

    let caps = RCSService.RemoteCapabilities(
        validUntil: Date(timeIntervalSince1970: 9),
        availability: .available,
        supportsChat: true,
        isBusinessHandle: false,
        alternativeHandles: [.uri(tmkURI())],
        supportsGeolocation: true,
        supportsFileTransfer: true
    )
    precondition(caps.supportsChat)
    tmkRoundTrip(caps)

    let update = RCSService.RemoteHandleUpdate(
        isBusinessHandle: true,
        newHandle: .uri(tmkURI()),
        capabilities: caps,
        cellularServiceID: tmkServiceID(),
        handle: .uri(tmkURI())
    )
    precondition(update.isBusinessHandle)

    let suggestion = RCSService.SuggestionResponse(
        cellularServiceID: tmkServiceID(),
        destination: .uri(tmkURI()),
        messageID: RCSMessageID(rawValue: "m"),
        originatingMessageID: RCSMessageID(rawValue: "o"),
        suggestion: tmkSuggestion()
    )
    precondition(suggestion.messageID.rawValue == "m")
}

func testRCSGroupAndCapabilityRequests() {
    let revoke = RCSService.RevokeMessageRequest(
        cellularServiceID: tmkServiceID(),
        handle: .uri(tmkURI()),
        messageID: RCSMessageID(rawValue: "r1")
    )
    precondition(revoke.messageID.rawValue == "r1")

    let leave = RCSService.LeaveGroupChatRequest(
        cellularServiceID: tmkServiceID(),
        groupHandle: tmkGroup()
    )
    precondition(leave.groupHandle.conversationID == "conv-1")

    let create = RCSService.CreateGroupChatRequest(
        cellularServiceID: tmkServiceID(),
        participants: [tmkURI()],
        subject: "team"
    )
    precondition(create.subject == "team")
    let created = RCSService.CreateGroupChatRequest.Result(
        groupHandle: tmkGroup(),
        participants: [tmkURI()],
        subject: "team"
    )
    precondition(created.subject == "team")

    let remoteReq = RCSService.RemoteCapabilitiesRequest(
        cellularServiceID: tmkServiceID(),
        handle: .uri(tmkURI()),
        cachePolicy: .cacheOrRemote
    )
    precondition(remoteReq.cachePolicy.description == "cacheOrRemote")
    precondition(RCSService.RemoteCapabilitiesRequest.CachePolicy.cacheOnly.description == "cacheOnly")
    tmkRoundTrip(remoteReq.cachePolicy)

    let bizReq = RCSService.BusinessInformationRequest(
        cellularServiceID: tmkServiceID(),
        handle: tmkURI(),
        cachePolicy: .remoteOnly
    )
    precondition(bizReq.cachePolicy == .remoteOnly)

    let change = RCSService.ChangeGroupChatSubjectRequest(
        cellularServiceID: tmkServiceID(),
        groupHandle: tmkGroup(),
        newSubject: "new"
    )
    _ = change.newSubject

    let add = RCSService.AddGroupChatParticipantsRequest(
        cellularServiceID: tmkServiceID(),
        groupHandle: tmkGroup(),
        participants: [tmkURI()]
    )
    let addResult = RCSService.AddGroupChatParticipantsRequest.Result(added: [tmkURI()])
    precondition(add.participants.count == 1)
    _ = addResult

    let remove = RCSService.RemoveGroupChatParticipantsRequest(
        cellularServiceID: tmkServiceID(),
        groupHandle: tmkGroup(),
        participants: [tmkURI()]
    )
    let removeResult = RCSService.RemoveGroupChatParticipantsRequest.Result(removed: [tmkURI()])
    precondition(remove.participants.count == 1)
    precondition(removeResult.removed.count == 1)
}

func testRCSIncomingAndViability() {
    let incoming = RCSService.IncomingMessageNotification(
        suggestions: [tmkSuggestion()],
        groupContext: RCSGroupContext(handle: tmkGroup()),
        message: tmkRCSMessage()
    )
    precondition(incoming.suggestions.count == 1)
    let viability = RCSService.ViabilityNotification(cellularServiceID: tmkServiceID(), isViable: false)
    precondition(viability.isViable == false)
}
