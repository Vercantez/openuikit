import Foundation
import TelephonyMessagingKit

/// Fail-closed coverage for the `async throws` SMS/MMS/RCS service methods.
///
/// Linux has no telephony daemon, so every method below throws its service
/// error immediately. Each test is a top-level synchronous no-argument
/// function; the async call itself runs inside `tmkRunBlocking` (defined in
/// the uncited `AsyncHarnessTests.swift` helper file).

func testSMSServiceAsyncFailClosed() {
    tmkRunBlocking {
        let service = TelephonyMessagingSession.shared.smsService
        do {
            try await service.sendMessage(tmkSMSMessage())
            preconditionFailure("SMS sendMessage must fail closed")
        } catch let error as SMSService.Error {
            precondition(error == .notSupported)
        } catch {
            preconditionFailure("wrong SMS sendMessage error \(error)")
        }
        do {
            try await service.reportSpam(tmkSMSMessage())
            preconditionFailure("SMS reportSpam must fail closed")
        } catch let error as SMSService.Error {
            precondition(error == .notSupported)
        } catch {
            preconditionFailure("wrong SMS reportSpam error \(error)")
        }
    }
}

func testMMSServiceAsyncFailClosed() {
    tmkRunBlocking {
        let service = TelephonyMessagingSession.shared.mmsService
        do {
            try await service.sendMessage(tmkMMSMessage())
            preconditionFailure("MMS sendMessage must fail closed")
        } catch let error as MMSService.Error {
            precondition(error == .mmsNotConfiguredForCarrier)
        } catch {
            preconditionFailure("wrong MMS sendMessage error \(error)")
        }
        do {
            try await service.reportSpam(tmkMMSMessage())
            preconditionFailure("MMS reportSpam must fail closed")
        } catch let error as MMSService.Error {
            precondition(error == .mmsNotConfiguredForCarrier)
        } catch {
            preconditionFailure("wrong MMS reportSpam error \(error)")
        }
        do {
            _ = try await service.configuration(for: tmkServiceID())
            preconditionFailure("MMS configuration must fail closed")
        } catch let error as MMSService.Error {
            precondition(error == .mmsNotConfiguredForCarrier)
        } catch {
            preconditionFailure("wrong MMS configuration error \(error)")
        }
        do {
            _ = try await service.receiveMessage(
                using: tmkServiceID(),
                messageID: MMSMessageID(rawValue: 7)
            )
            preconditionFailure("MMS receiveMessage must fail closed")
        } catch let error as MMSService.Error {
            precondition(error == .mmsNotConfiguredForCarrier)
        } catch {
            preconditionFailure("wrong MMS receiveMessage error \(error)")
        }
    }
}

func testRCSServiceSendTextAndComposingAsyncFailClosed() {
    tmkRunBlocking {
        let service = TelephonyMessagingSession.shared.rcsService
        do {
            try await service.sendMessage(
                RCSMessage.Text(body: "hello"),
                to: .uri(tmkURI()),
                using: tmkServiceID(),
                messageID: RCSMessageID(rawValue: "t1")
            )
            preconditionFailure("RCS text sendMessage must fail closed")
        } catch let error as RCSService.Error {
            precondition(error == .serviceUnavailable)
        } catch {
            preconditionFailure("wrong RCS text sendMessage error \(error)")
        }
        do {
            try await service.sendMessage(
                RCSMessage.ComposingIndicator(
                    state: .active,
                    lastActive: Date(timeIntervalSince1970: 1_700_000_000),
                    contentType: .plainText,
                    refreshInterval: .seconds(8)
                ),
                to: .uri(tmkURI()),
                using: tmkServiceID(),
                messageID: RCSMessageID(rawValue: "c1")
            )
            preconditionFailure("RCS composing sendMessage must fail closed")
        } catch let error as RCSService.Error {
            precondition(error == .serviceUnavailable)
        } catch {
            preconditionFailure("wrong RCS composing sendMessage error \(error)")
        }
    }
}

func testRCSServiceSendMediaAndGeoAsyncFailClosed() {
    tmkRunBlocking {
        let service = TelephonyMessagingSession.shared.rcsService
        do {
            try await service.sendMessage(
                RCSMessage.FileTransfer(
                    fileMetadata: tmkFileMeta(),
                    thumbnailMetadata: tmkFileMeta()
                ),
                to: .uri(tmkURI()),
                using: tmkServiceID(),
                messageID: RCSMessageID(rawValue: "f1")
            )
            preconditionFailure("RCS file sendMessage must fail closed")
        } catch let error as RCSService.Error {
            precondition(error == .serviceUnavailable)
        } catch {
            preconditionFailure("wrong RCS file sendMessage error \(error)")
        }
        do {
            try await service.sendMessage(
                RCSMessage.GeolocationPush(latitude: 10, longitude: 20, description: "here"),
                to: .uri(tmkURI()),
                using: tmkServiceID(),
                messageID: RCSMessageID(rawValue: "g1")
            )
            preconditionFailure("RCS geo sendMessage must fail closed")
        } catch let error as RCSService.Error {
            precondition(error == .serviceUnavailable)
        } catch {
            preconditionFailure("wrong RCS geo sendMessage error \(error)")
        }
    }
}

func testRCSServiceSendDispositionAndDeviceSpecificsAsyncFailClosed() {
    tmkRunBlocking {
        let service = TelephonyMessagingSession.shared.rcsService
        do {
            try await service.sendMessage(
                RCSMessage.DispositionNotification(
                    disposition: .displayed,
                    disposedMessageID: RCSMessageID(rawValue: "d1")
                ),
                to: tmkURI(),
                using: tmkServiceID(),
                messageID: RCSMessageID(rawValue: "n1"),
                group: nil
            )
            preconditionFailure("RCS disposition sendMessage must fail closed")
        } catch let error as RCSService.Error {
            precondition(error == .serviceUnavailable)
        } catch {
            preconditionFailure("wrong RCS disposition sendMessage error \(error)")
        }
        do {
            try await service.sendDeviceSpecifics(
                to: tmkURI(),
                using: tmkServiceID(),
                messageID: RCSMessageID(rawValue: "s1")
            )
            preconditionFailure("RCS sendDeviceSpecifics must fail closed")
        } catch let error as RCSService.Error {
            precondition(error == .serviceUnavailable)
        } catch {
            preconditionFailure("wrong RCS sendDeviceSpecifics error \(error)")
        }
    }
}

func testRCSServiceGroupChatAsyncFailClosed() {
    tmkRunBlocking {
        let service = TelephonyMessagingSession.shared.rcsService
        do {
            _ = try await service.createGroupChat(
                RCSService.CreateGroupChatRequest(
                    cellularServiceID: tmkServiceID(),
                    participants: [tmkURI()],
                    subject: "team"
                )
            )
            preconditionFailure("RCS createGroupChat must fail closed")
        } catch let error as RCSService.Error {
            precondition(error == .serviceUnavailable)
        } catch {
            preconditionFailure("wrong RCS createGroupChat error \(error)")
        }
        do {
            try await service.leaveGroupChat(
                RCSService.LeaveGroupChatRequest(
                    cellularServiceID: tmkServiceID(),
                    groupHandle: tmkGroup()
                )
            )
            preconditionFailure("RCS leaveGroupChat must fail closed")
        } catch let error as RCSService.Error {
            precondition(error == .serviceUnavailable)
        } catch {
            preconditionFailure("wrong RCS leaveGroupChat error \(error)")
        }
        do {
            try await service.changeGroupChatSubject(
                RCSService.ChangeGroupChatSubjectRequest(
                    cellularServiceID: tmkServiceID(),
                    groupHandle: tmkGroup(),
                    newSubject: "new"
                )
            )
            preconditionFailure("RCS changeGroupChatSubject must fail closed")
        } catch let error as RCSService.Error {
            precondition(error == .serviceUnavailable)
        } catch {
            preconditionFailure("wrong RCS changeGroupChatSubject error \(error)")
        }
        do {
            _ = try await service.addGroupChatParticipants(
                RCSService.AddGroupChatParticipantsRequest(
                    cellularServiceID: tmkServiceID(),
                    groupHandle: tmkGroup(),
                    participants: [tmkURI()]
                )
            )
            preconditionFailure("RCS addGroupChatParticipants must fail closed")
        } catch let error as RCSService.Error {
            precondition(error == .serviceUnavailable)
        } catch {
            preconditionFailure("wrong RCS addGroupChatParticipants error \(error)")
        }
        do {
            _ = try await service.removeGroupChatParticipants(
                RCSService.RemoveGroupChatParticipantsRequest(
                    cellularServiceID: tmkServiceID(),
                    groupHandle: tmkGroup(),
                    participants: [tmkURI()]
                )
            )
            preconditionFailure("RCS removeGroupChatParticipants must fail closed")
        } catch let error as RCSService.Error {
            precondition(error == .serviceUnavailable)
        } catch {
            preconditionFailure("wrong RCS removeGroupChatParticipants error \(error)")
        }
    }
}

func testRCSServiceFilesSpamRevokeSuggestAsyncFailClosed() {
    tmkRunBlocking {
        let service = TelephonyMessagingSession.shared.rcsService
        do {
            _ = try await service.upload(
                RCSService.FileUploadRequest(
                    cellularServiceID: tmkServiceID(),
                    fileURL: tmkURL(),
                    contentType: .jpeg,
                    thumbnailURL: tmkURL(),
                    thumbnailContentType: .jpeg
                )
            )
            preconditionFailure("RCS upload must fail closed")
        } catch let error as RCSService.Error {
            precondition(error == .serviceUnavailable)
        } catch {
            preconditionFailure("wrong RCS upload error \(error)")
        }
        do {
            _ = try await service.download(
                RCSService.FileDownloadRequest(
                    cellularServiceID: tmkServiceID(),
                    fileURL: tmkURL(),
                    destinationFileURL: tmkURL()
                )
            )
            preconditionFailure("RCS download must fail closed")
        } catch let error as RCSService.Error {
            precondition(error == .serviceUnavailable)
        } catch {
            preconditionFailure("wrong RCS download error \(error)")
        }
        do {
            try await service.reportSpam(
                RCSService.ReportSpamRequest(
                    message: tmkRCSMessage(),
                    fileContent: Data("evidence".utf8),
                    category: .spam,
                    reason: "junk"
                )
            )
            preconditionFailure("RCS reportSpam must fail closed")
        } catch let error as RCSService.Error {
            precondition(error == .serviceUnavailable)
        } catch {
            preconditionFailure("wrong RCS reportSpam error \(error)")
        }
        do {
            _ = try await service.revokeMessage(
                RCSService.RevokeMessageRequest(
                    cellularServiceID: tmkServiceID(),
                    handle: .uri(tmkURI()),
                    messageID: RCSMessageID(rawValue: "r1")
                )
            )
            preconditionFailure("RCS revokeMessage must fail closed")
        } catch let error as RCSService.Error {
            precondition(error == .serviceUnavailable)
        } catch {
            preconditionFailure("wrong RCS revokeMessage error \(error)")
        }
        do {
            try await service.sendSuggestionResponse(
                RCSService.SuggestionResponse(
                    cellularServiceID: tmkServiceID(),
                    destination: .uri(tmkURI()),
                    messageID: RCSMessageID(rawValue: "m"),
                    originatingMessageID: RCSMessageID(rawValue: "o"),
                    suggestion: tmkSuggestion()
                )
            )
            preconditionFailure("RCS sendSuggestionResponse must fail closed")
        } catch let error as RCSService.Error {
            precondition(error == .serviceUnavailable)
        } catch {
            preconditionFailure("wrong RCS sendSuggestionResponse error \(error)")
        }
    }
}

func testRCSServiceLookupAsyncFailClosed() {
    tmkRunBlocking {
        let service = TelephonyMessagingSession.shared.rcsService
        do {
            _ = try await service.remoteCapabilities(
                for: RCSService.RemoteCapabilitiesRequest(
                    cellularServiceID: tmkServiceID(),
                    handle: .uri(tmkURI()),
                    cachePolicy: .cacheOrRemote
                )
            )
            preconditionFailure("RCS remoteCapabilities must fail closed")
        } catch let error as RCSService.Error {
            precondition(error == .serviceUnavailable)
        } catch {
            preconditionFailure("wrong RCS remoteCapabilities error \(error)")
        }
        do {
            _ = try await service.businessInformation(
                for: RCSService.BusinessInformationRequest(
                    cellularServiceID: tmkServiceID(),
                    handle: tmkURI(),
                    cachePolicy: .remoteOnly
                )
            )
            preconditionFailure("RCS businessInformation must fail closed")
        } catch let error as RCSService.Error {
            precondition(error == .serviceUnavailable)
        } catch {
            preconditionFailure("wrong RCS businessInformation error \(error)")
        }
    }
}
