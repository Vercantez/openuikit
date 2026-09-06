
import Foundation
import TelephonyMessagingKit

func tmkRoundTrip<T: Codable & Equatable>(_ value: T) {
    let encoder = JSONEncoder()
    let decoder = JSONDecoder()
    do {
        let data = try encoder.encode(value)
        let decoded = try decoder.decode(T.self, from: data)
        precondition(decoded == value)
    } catch {
        preconditionFailure("codable round trip failed: \(error)")
    }
}

func tmkHash<T: Hashable>(_ value: T) {
    precondition(value.hashValue == value.hashValue)
    var hasher = Hasher()
    value.hash(into: &hasher)
    _ = hasher.finalize()
}

func tmkServiceID() -> CellularServiceID {
    CellularServiceID(uuid: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!)
}

func tmkURL() -> URL { URL(string: "https://example.invalid/tmk")! }

func tmkFileMeta() -> RCSFileTransferMetadata {
    RCSFileTransferMetadata(
        contentType: .jpeg,
        disposition: .attachment,
        expirationDate: Date(timeIntervalSince1970: 1_800_000_000),
        playbackLength: .seconds(5),
        url: tmkURL(),
        fileName: "clip.bin",
        fileSize: 2048
    )
}

func tmkSMSMessage() -> SMSMessage {
    SMSMessage(
        cellularServiceID: tmkServiceID(),
        handle: SMSHandle(phoneNumber: "+15555550101"),
        messageID: SMSMessageID(rawValue: 11),
        content: SMSContent(body: "sms-body")
    )
}

func tmkMMSPart() -> MMSPartContent {
    MMSPartContent(
        data: Data("part".utf8),
        contentType: .plainText,
        contentID: "cid-1",
        disposition: .inline,
        fileName: "note.txt"
    )
}

func tmkMMSMessage() -> MMSMessage {
    let content = MMSContent(parts: [tmkMMSPart()], recipients: [MMSHandle(phoneNumber: "+15555550102")], subject: "subj")
    return MMSMessage(
        cellularServiceID: tmkServiceID(),
        messageID: MMSMessageID(rawValue: 99),
        content: content
    )
}

func tmkRCSMessage() -> RCSMessage {
    RCSMessage(
        cellularServiceID: tmkServiceID(),
        id: RCSMessageID(rawValue: "mid-1"),
        handle: RCSHandle.uri("sip:a@example.invalid"),
        content: .text(RCSMessage.Text(body: "hello"))
    )
}

func tmkGroup() -> RCSHandle.Group {
    RCSHandle.Group(conversationID: "conv-1", focus: "focus")
}

func tmkURI() -> RCSHandle.URI {
    RCSHandle.URI(rawValue: "sip:user@example.invalid")
}

func tmkBusinessMedia() -> RCSService.Business.Media {
    RCSService.Business.Media(sha256Digest: "abc", url: tmkURL())
}

func tmkCardMedia() -> RCSService.Business.Card.Media {
    RCSService.Business.Card.Media(
        contentType: .jpeg,
        description: "pic",
        thumbnailURL: tmkURL(),
        displayHeight: .medium,
        thumbnailFileSize: Measurement(value: 10, unit: .kilobytes),
        thumbnailContentType: .jpeg,
        url: tmkURL(),
        fileSize: Measurement(value: 100, unit: .kilobytes)
    )
}

func tmkSuggestion() -> RCSService.Business.Suggestion {
    .reply(RCSService.Business.SuggestedReply(displayText: "OK"))
}

func tmkCardContent() -> RCSService.Business.Card.Content {
    RCSService.Business.Card.Content(
        description: "desc",
        suggestions: [tmkSuggestion()],
        media: tmkCardMedia(),
        title: "title"
    )
}

func tmkCard() -> RCSService.Business.Card {
    RCSService.Business.Card(
        orientation: .vertical,
        styleSheetURL: tmkURL(),
        imageAlignment: .left,
        titleFontStyle: .bold,
        descriptionFontStyle: .italics,
        content: tmkCardContent()
    )
}

func tmkCarousel() -> RCSService.Business.CardCarousel {
    RCSService.Business.CardCarousel(
        styleSheetURL: tmkURL(),
        titleFontStyle: .bold,
        descriptionFontStyle: [.italics, .underline],
        width: .medium,
        contents: [tmkCardContent()]
    )
}

func tmkShowLocation() -> RCSService.Business.ShowLocationAction {
    RCSService.Business.ShowLocationAction(
        fallbackURL: tmkURL(),
        label: "hq",
        method: .query("cupertino")
    )
}

func tmkSuggestedAction() -> RCSService.Business.SuggestedAction {
    RCSService.Business.SuggestedAction(
        displayText: "Call",
        action: .dialPhoneNumber(
            RCSService.Business.DialPhoneNumberAction(phoneNumber: "+15555550100", fallbackURL: tmkURL())
        )
    )
}

func tmkHashIfPossible<T: Hashable>(_ value: T) { tmkHash(value) }
func testTelephonyMessagingSessionErrorCases() {
    let values: [TelephonyMessagingSession.Error] = [
        .invalidSession,
        .internalError,
        .invalidArgument,
        .serviceUnavailable,
    ]
    precondition(!values.isEmpty)
    for (index, value) in values.enumerated() {
        precondition(value == value)
        if values.count > 1 {
            let other = values[(index + 1) % values.count]
            if String(describing: value) != String(describing: other) {
                precondition(value != other)
            }
        }
        tmkHash(value)
        _ = String(describing: value)
    }
    tmkRoundTrip(values[0])
    let first: TelephonyMessagingSession.Error = .invalidSession
    precondition(first == values[0])
}

func testMMSServiceErrorCases() {
    let values: [MMSService.Error] = [
        .internalError,
        .mmsNotReady,
        .notSupported,
        .invalidRecipient,
        .invalidMessageParts,
        .maximumSizeExceeded,
        .mmsNotConfiguredForCarrier,
        .unknown,
    ]
    precondition(!values.isEmpty)
    for (index, value) in values.enumerated() {
        precondition(value == value)
        if values.count > 1 {
            let other = values[(index + 1) % values.count]
            if String(describing: value) != String(describing: other) {
                precondition(value != other)
            }
        }
        tmkHash(value)
        _ = String(describing: value)
    }
    tmkRoundTrip(values[0])
    let first: MMSService.Error = .internalError
    precondition(first == values[0])
}

func testRCSMessageDispositionCases() {
    let values: [RCSMessage.Disposition] = [
        .deliveryFailed,
        .interworkingFailed,
        .interworkingDelivered,
        .delivered,
        .displayed,
    ]
    precondition(!values.isEmpty)
    for (index, value) in values.enumerated() {
        precondition(value == value)
        if values.count > 1 {
            let other = values[(index + 1) % values.count]
            if String(describing: value) != String(describing: other) {
                precondition(value != other)
            }
        }
        tmkHash(value)
        _ = String(describing: value)
    }
    tmkRoundTrip(values[0])
    let first: RCSMessage.Disposition = .deliveryFailed
    precondition(first == values[0])
}

func testRCSMessageComposingIndicatorStateCases() {
    let values: [RCSMessage.ComposingIndicator.State] = [
        .idle,
        .active,
    ]
    precondition(!values.isEmpty)
    for (index, value) in values.enumerated() {
        precondition(value == value)
        if values.count > 1 {
            let other = values[(index + 1) % values.count]
            if String(describing: value) != String(describing: other) {
                precondition(value != other)
            }
        }
        tmkHash(value)
        _ = String(describing: value)
    }
    tmkRoundTrip(values[0])
    let first: RCSMessage.ComposingIndicator.State = .idle
    precondition(first == values[0])
}

func testRCSMessageContentCases() {
    let values: [RCSMessage.Content] = [
        .businessCard(tmkCard()),
        .fileTransfer(RCSMessage.FileTransfer(fileMetadata: tmkFileMeta())),
        .geolocationPush(RCSMessage.GeolocationPush(latitude: 1, longitude: 2, description: "here")),
        .composingIndicator(RCSMessage.ComposingIndicator(state: .idle)),
        .businessCardCarousel(tmkCarousel()),
        .dispositionNotification(RCSMessage.DispositionNotification(disposition: .delivered, disposedMessageID: RCSMessageID(rawValue: "d"))),
        .text(RCSMessage.Text(body: "hello")),
    ]
    precondition(!values.isEmpty)
    for (index, value) in values.enumerated() {
        precondition(value == value)
        if values.count > 1 {
            let other = values[(index + 1) % values.count]
            if String(describing: value) != String(describing: other) {
                precondition(value != other)
            }
        }
        _ = String(describing: value)
    }
    tmkRoundTrip(values[0])
    let first: RCSMessage.Content = .businessCard(tmkCard())
    precondition(first == values[0])
}

func testRCSServiceGroupChatEventCases() {
    let group = tmkGroup()
    let uri = tmkURI()
    let sid = tmkServiceID()
    let values: [RCSService.GroupChatEvent] = [
        .subjectUpdated(RCSService.GroupChatSubjectUpdatedEvent(newSubject: "s", groupHandle: group, cellularServiceID: sid, changedBy: uri)),
        .participantsAdded(RCSService.GroupChatParticipantsAddedEvent(addedParticipants: [uri], groupHandle: group, cellularServiceID: sid, addedBy: uri)),
        .participantsRemoved(RCSService.GroupChatParticipantsRemovedEvent(removedParticipants: [uri], groupHandle: group, cellularServiceID: sid, removedCurrentUser: false, removedBy: uri)),
        .ended(RCSService.GroupChatEndedEvent(groupHandle: group, cellularServiceID: sid, endedBy: uri)),
        .started(RCSService.GroupChatStartedEvent(groupHandle: group, participants: [uri], cellularServiceID: sid, creator: uri, subject: "hello")),
    ]
    precondition(!values.isEmpty)
    for value in values {
        _ = String(describing: value)
    }
}

func testRCSServiceReportSpamRequestCategoryCases() {
    let values: [RCSService.ReportSpamRequest.Category] = [
        .inappropriateContent,
        .spam,
        .fraud,
        .other,
        .invalid,
    ]
    precondition(!values.isEmpty)
    for (index, value) in values.enumerated() {
        precondition(value == value)
        if values.count > 1 {
            let other = values[(index + 1) % values.count]
            if String(describing: value) != String(describing: other) {
                precondition(value != other)
            }
        }
        tmkHash(value)
        _ = String(describing: value)
    }
    tmkRoundTrip(values[0])
    let first: RCSService.ReportSpamRequest.Category = .inappropriateContent
    precondition(first == values[0])
}

func testRCSServiceRemoteCapabilitiesAvailabilityCases() {
    let values: [RCSService.RemoteCapabilities.Availability] = [
        .unavailable,
        .available,
    ]
    precondition(!values.isEmpty)
    for (index, value) in values.enumerated() {
        precondition(value == value)
        if values.count > 1 {
            let other = values[(index + 1) % values.count]
            if String(describing: value) != String(describing: other) {
                precondition(value != other)
            }
        }
        tmkHash(value)
        _ = String(describing: value)
    }
    tmkRoundTrip(values[0])
    let first: RCSService.RemoteCapabilities.Availability = .unavailable
    precondition(first == values[0])
}

func testRCSServiceRemoteCapabilitiesRequestCachePolicyCases() {
    let values: [RCSService.RemoteCapabilitiesRequest.CachePolicy] = [
        .cacheOrRemote,
        .cacheOnly,
    ]
    precondition(!values.isEmpty)
    for (index, value) in values.enumerated() {
        precondition(value == value)
        if values.count > 1 {
            let other = values[(index + 1) % values.count]
            if String(describing: value) != String(describing: other) {
                precondition(value != other)
            }
        }
        tmkHash(value)
        _ = String(describing: value)
    }
    tmkRoundTrip(values[0])
    let first: RCSService.RemoteCapabilitiesRequest.CachePolicy = .cacheOrRemote
    precondition(first == values[0])
}

func testRCSServiceBusinessInformationRequestCachePolicyCases() {
    let values: [RCSService.BusinessInformationRequest.CachePolicy] = [
        .remoteOnly,
        .cacheOrRemote,
        .cacheOnly,
    ]
    precondition(!values.isEmpty)
    for (index, value) in values.enumerated() {
        precondition(value == value)
        if values.count > 1 {
            let other = values[(index + 1) % values.count]
            if String(describing: value) != String(describing: other) {
                precondition(value != other)
            }
        }
        tmkHash(value)
        _ = String(describing: value)
    }
    tmkRoundTrip(values[0])
    let first: RCSService.BusinessInformationRequest.CachePolicy = .remoteOnly
    precondition(first == values[0])
}

func testRCSServiceErrorCases() {
    let values: [RCSService.Error] = [
        .internalError,
        .permanentError,
        .temporaryError,
        .notSupported,
        .decodingFailed,
        .invalidArgument,
        .serviceUnavailable,
        .maximumSizeExceeded,
        .unknown,
        .notFound,
    ]
    precondition(!values.isEmpty)
    for (index, value) in values.enumerated() {
        precondition(value == value)
        if values.count > 1 {
            let other = values[(index + 1) % values.count]
            if String(describing: value) != String(describing: other) {
                precondition(value != other)
            }
        }
        tmkHash(value)
        _ = String(describing: value)
    }
    tmkRoundTrip(values[0])
    let first: RCSService.Error = .internalError
    precondition(first == values[0])
}

func testRCSServiceBusinessMediaEntryContentTypeCases() {
    let values: [RCSService.Business.MediaEntry.ContentType] = [
        .logo,
        .other,
    ]
    precondition(!values.isEmpty)
    for (index, value) in values.enumerated() {
        precondition(value == value)
        if values.count > 1 {
            let other = values[(index + 1) % values.count]
            if String(describing: value) != String(describing: other) {
                precondition(value != other)
            }
        }
        tmkHash(value)
        _ = String(describing: value)
    }
    tmkRoundTrip(values[0])
    let first: RCSService.Business.MediaEntry.ContentType = .logo
    precondition(first == values[0])
}

func testRCSServiceBusinessMediaEntryLabelCases() {
    let values: [RCSService.Business.MediaEntry.Label] = [
        .icon,
    ]
    precondition(!values.isEmpty)
    for (index, value) in values.enumerated() {
        precondition(value == value)
        if values.count > 1 {
            let other = values[(index + 1) % values.count]
            if String(describing: value) != String(describing: other) {
                precondition(value != other)
            }
        }
        tmkHash(value)
        _ = String(describing: value)
    }
    tmkRoundTrip(values[0])
    let first: RCSService.Business.MediaEntry.Label = .icon
    precondition(first == values[0])
}

func testRCSServiceBusinessSuggestionCases() {
    let values: [RCSService.Business.Suggestion] = [
        tmkSuggestion(),
        .action(tmkSuggestedAction()),
    ]
    precondition(!values.isEmpty)
    for (index, value) in values.enumerated() {
        precondition(value == value)
        if values.count > 1 {
            let other = values[(index + 1) % values.count]
            if String(describing: value) != String(describing: other) {
                precondition(value != other)
            }
        }
        _ = String(describing: value)
    }
    tmkRoundTrip(values[0])
    let first: RCSService.Business.Suggestion = tmkSuggestion()
    precondition(first == values[0])
}

func testRCSServiceBusinessOpenURLActionDetentCases() {
    let values: [RCSService.Business.OpenURLAction.Detent] = [
        .mediumLarge,
        .large,
        .medium,
    ]
    precondition(!values.isEmpty)
    for (index, value) in values.enumerated() {
        precondition(value == value)
        if values.count > 1 {
            let other = values[(index + 1) % values.count]
            if String(describing: value) != String(describing: other) {
                precondition(value != other)
            }
        }
        tmkHash(value)
        _ = String(describing: value)
    }
    tmkRoundTrip(values[0])
    let first: RCSService.Business.OpenURLAction.Detent = .mediumLarge
    precondition(first == values[0])
}

func testRCSServiceBusinessOpenURLActionTargetCases() {
    let values: [RCSService.Business.OpenURLAction.Target] = [
        .defaultBrowser,
        .inApp(detent: .medium),
    ]
    precondition(!values.isEmpty)
    for (index, value) in values.enumerated() {
        precondition(value == value)
        if values.count > 1 {
            let other = values[(index + 1) % values.count]
            if String(describing: value) != String(describing: other) {
                precondition(value != other)
            }
        }
        _ = String(describing: value)
    }
    tmkRoundTrip(values[0])
    let first: RCSService.Business.OpenURLAction.Target = .defaultBrowser
    precondition(first == values[0])
}

func testRCSServiceBusinessSuggestedActionActionCases() {
    let values: [RCSService.Business.SuggestedAction.Action] = [
        .composeText(RCSService.Business.ComposeTextAction(phoneNumber: "+15555550100", text: "hi")),
        .sendLocation,
        .showLocation(tmkShowLocation()),
        .dialPhoneNumber(RCSService.Business.DialPhoneNumberAction(phoneNumber: "+15555550100", fallbackURL: tmkURL())),
        .composeRecording(RCSService.Business.ComposeRecordingAction(phoneNumber: "+15555550100", mediaType: .audio)),
        .createCalendarEvent(RCSService.Business.CreateCalendarEventAction(
            description: "meet",
            fallbackURL: tmkURL(),
            title: "Standup",
            endTime: Date(timeIntervalSince1970: 2),
            startTime: Date(timeIntervalSince1970: 1)
        )),
        .sendDeviceSpecifics,
        .enableDisplayedNotifications,
        .openURL(RCSService.Business.OpenURLAction(url: tmkURL(), target: .defaultBrowser)),
    ]
    precondition(!values.isEmpty)
    for (index, value) in values.enumerated() {
        precondition(value == value)
        if values.count > 1 {
            let other = values[(index + 1) % values.count]
            if String(describing: value) != String(describing: other) {
                precondition(value != other)
            }
        }
        _ = String(describing: value)
    }
    tmkRoundTrip(values[0])
    let first: RCSService.Business.SuggestedAction.Action = .composeText(RCSService.Business.ComposeTextAction(phoneNumber: "+15555550100", text: "hi"))
    precondition(first == values[0])
}

func testRCSServiceBusinessOrganizationNameNameTypeCases() {
    let values: [RCSService.Business.OrganizationName.NameType] = [
        .officialName,
    ]
    precondition(!values.isEmpty)
    for (index, value) in values.enumerated() {
        precondition(value == value)
        if values.count > 1 {
            let other = values[(index + 1) % values.count]
            if String(describing: value) != String(describing: other) {
                precondition(value != other)
            }
        }
        tmkHash(value)
        _ = String(describing: value)
    }
    tmkRoundTrip(values[0])
    let first: RCSService.Business.OrganizationName.NameType = .officialName
    precondition(first == values[0])
}

func testRCSServiceBusinessShowLocationActionMethodCases() {
    let values: [RCSService.Business.ShowLocationAction.Method] = [
        .coordinates(CLLocationCoordinate2D(latitude: 37.78, longitude: -122.41)),
        .query("tmk"),
    ]
    precondition(!values.isEmpty)
    for (index, value) in values.enumerated() {
        precondition(value == value)
        if values.count > 1 {
            let other = values[(index + 1) % values.count]
            if String(describing: value) != String(describing: other) {
                precondition(value != other)
            }
        }
        _ = String(describing: value)
    }
    tmkRoundTrip(values[0])
    let first: RCSService.Business.ShowLocationAction.Method = .coordinates(CLLocationCoordinate2D(latitude: 37.78, longitude: -122.41))
    precondition(first == values[0])
}

func testRCSServiceBusinessComposeRecordingActionMediaTypeCases() {
    let values: [RCSService.Business.ComposeRecordingAction.MediaType] = [
        .audio,
        .video,
    ]
    precondition(!values.isEmpty)
    for (index, value) in values.enumerated() {
        precondition(value == value)
        if values.count > 1 {
            let other = values[(index + 1) % values.count]
            if String(describing: value) != String(describing: other) {
                precondition(value != other)
            }
        }
        tmkHash(value)
        _ = String(describing: value)
    }
    tmkRoundTrip(values[0])
    let first: RCSService.Business.ComposeRecordingAction.MediaType = .audio
    precondition(first == values[0])
}

func testRCSServiceBusinessCardOrientationCases() {
    let values: [RCSService.Business.Card.Orientation] = [
        .horizontal,
        .vertical,
    ]
    precondition(!values.isEmpty)
    for (index, value) in values.enumerated() {
        precondition(value == value)
        if values.count > 1 {
            let other = values[(index + 1) % values.count]
            if String(describing: value) != String(describing: other) {
                precondition(value != other)
            }
        }
        tmkHash(value)
        _ = String(describing: value)
    }
    tmkRoundTrip(values[0])
    let first: RCSService.Business.Card.Orientation = .horizontal
    precondition(first == values[0])
}

func testRCSServiceBusinessCardImageAlignmentCases() {
    let values: [RCSService.Business.Card.ImageAlignment] = [
        .left,
        .right,
    ]
    precondition(!values.isEmpty)
    for (index, value) in values.enumerated() {
        precondition(value == value)
        if values.count > 1 {
            let other = values[(index + 1) % values.count]
            if String(describing: value) != String(describing: other) {
                precondition(value != other)
            }
        }
        tmkHash(value)
        _ = String(describing: value)
    }
    tmkRoundTrip(values[0])
    let first: RCSService.Business.Card.ImageAlignment = .left
    precondition(first == values[0])
}

func testRCSServiceBusinessCardMediaHeightCases() {
    let values: [RCSService.Business.Card.Media.Height] = [
        .tall,
        .short,
        .medium,
    ]
    precondition(!values.isEmpty)
    for (index, value) in values.enumerated() {
        precondition(value == value)
        if values.count > 1 {
            let other = values[(index + 1) % values.count]
            if String(describing: value) != String(describing: other) {
                precondition(value != other)
            }
        }
        tmkHash(value)
        _ = String(describing: value)
    }
    tmkRoundTrip(values[0])
    let first: RCSService.Business.Card.Media.Height = .tall
    precondition(first == values[0])
}

func testRCSServiceBusinessCardWidthCases() {
    let values: [RCSService.Business.Card.Width] = [
        .small,
        .medium,
    ]
    precondition(!values.isEmpty)
    for (index, value) in values.enumerated() {
        precondition(value == value)
        if values.count > 1 {
            let other = values[(index + 1) % values.count]
            if String(describing: value) != String(describing: other) {
                precondition(value != other)
            }
        }
        tmkHash(value)
        _ = String(describing: value)
    }
    tmkRoundTrip(values[0])
    let first: RCSService.Business.Card.Width = .small
    precondition(first == values[0])
}

func testRCSServiceBusinessMenuContentCases() {
    let values: [RCSService.Business.Menu.Content] = [
        .suggestion(tmkSuggestion()),
        .submenu(RCSService.Business.Menu(title: "more", contents: [.suggestion(tmkSuggestion())])),
    ]
    precondition(!values.isEmpty)
    for (index, value) in values.enumerated() {
        precondition(value == value)
        if values.count > 1 {
            let other = values[(index + 1) % values.count]
            if String(describing: value) != String(describing: other) {
                precondition(value != other)
            }
        }
        _ = String(describing: value)
    }
    tmkRoundTrip(values[0])
    let first: RCSService.Business.Menu.Content = .suggestion(tmkSuggestion())
    precondition(first == values[0])
}

func testRCSServiceBusinessURIEntryLabelCases() {
    let values: [RCSService.Business.URIEntry.Label] = [
        .sms,
        .serviceID,
    ]
    precondition(!values.isEmpty)
    for (index, value) in values.enumerated() {
        precondition(value == value)
        if values.count > 1 {
            let other = values[(index + 1) % values.count]
            if String(describing: value) != String(describing: other) {
                precondition(value != other)
            }
        }
        tmkHash(value)
        _ = String(describing: value)
    }
    tmkRoundTrip(values[0])
    let first: RCSService.Business.URIEntry.Label = .sms
    precondition(first == values[0])
}

func testRCSServiceBusinessURIEntryURITypeCases() {
    let values: [RCSService.Business.URIEntry.URIType] = [
        .sip,
        .other,
    ]
    precondition(!values.isEmpty)
    for (index, value) in values.enumerated() {
        precondition(value == value)
        if values.count > 1 {
            let other = values[(index + 1) % values.count]
            if String(describing: value) != String(describing: other) {
                precondition(value != other)
            }
        }
        tmkHash(value)
        _ = String(describing: value)
    }
    tmkRoundTrip(values[0])
    let first: RCSService.Business.URIEntry.URIType = .sip
    precondition(first == values[0])
}

func testSMSServiceCriticalMessageStateNotificationStateCases() {
    let values: [SMSService.CriticalMessageStateNotification.State] = [
        .sent,
    ]
    precondition(!values.isEmpty)
    for (index, value) in values.enumerated() {
        precondition(value == value)
        if values.count > 1 {
            let other = values[(index + 1) % values.count]
            if String(describing: value) != String(describing: other) {
                precondition(value != other)
            }
        }
        tmkHash(value)
        _ = String(describing: value)
    }
    let first: SMSService.CriticalMessageStateNotification.State = .sent
    precondition(first == values[0])
}

func testSMSServiceErrorCases() {
    let values: [SMSService.Error] = [
        .notSupported,
        .permanentFailure,
        .temporaryFailure,
        .unknown,
    ]
    precondition(!values.isEmpty)
    for (index, value) in values.enumerated() {
        precondition(value == value)
        if values.count > 1 {
            let other = values[(index + 1) % values.count]
            if String(describing: value) != String(describing: other) {
                precondition(value != other)
            }
        }
        tmkHash(value)
        _ = String(describing: value)
    }
    tmkRoundTrip(values[0])
    let first: SMSService.Error = .notSupported
    precondition(first == values[0])
}

func testMMSPartContentMMSDispositionTypeCases() {
    let values: [MMSPartContent.MMSDispositionType] = [
        .attachment,
        .inline,
    ]
    precondition(!values.isEmpty)
    for (index, value) in values.enumerated() {
        precondition(value == value)
        if values.count > 1 {
            let other = values[(index + 1) % values.count]
            if String(describing: value) != String(describing: other) {
                precondition(value != other)
            }
        }
        tmkHash(value)
        _ = String(describing: value)
    }
    tmkRoundTrip(values[0])
    let first: MMSPartContent.MMSDispositionType = .attachment
    precondition(first == values[0])
}

func testRCSFileTransferMetadataDispositionCases() {
    let values: [RCSFileTransferMetadata.Disposition] = [
        .attachment,
        .render,
    ]
    precondition(!values.isEmpty)
    for (index, value) in values.enumerated() {
        precondition(value == value)
        if values.count > 1 {
            let other = values[(index + 1) % values.count]
            if String(describing: value) != String(describing: other) {
                precondition(value != other)
            }
        }
        tmkHash(value)
        _ = String(describing: value)
    }
    tmkRoundTrip(values[0])
    let first: RCSFileTransferMetadata.Disposition = .attachment
    precondition(first == values[0])
}

func testRCSHandleCases() {
    let values: [RCSHandle] = [
        .uri(RCSHandle.URI(rawValue: "sip:user@example.invalid")),
        .group(RCSHandle.Group(conversationID: "conv-1", focus: "focus")),
    ]
    precondition(!values.isEmpty)
    for (index, value) in values.enumerated() {
        precondition(value == value)
        if values.count > 1 {
            let other = values[(index + 1) % values.count]
            if String(describing: value) != String(describing: other) {
                precondition(value != other)
            }
        }
        tmkHash(value)
        _ = String(describing: value)
    }
    tmkRoundTrip(values[0])
    let first: RCSHandle = .uri(RCSHandle.URI(rawValue: "sip:user@example.invalid"))
    precondition(first == values[0])
}
