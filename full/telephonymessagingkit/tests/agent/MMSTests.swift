
import Foundation
import TelephonyMessagingKit

func testMMSPartAndContent() {
    var part = tmkMMSPart()
    precondition(part.filename == "note.txt")
    precondition(part.contentID == "cid-1")
    precondition(part.disposition == .inline)
    precondition(part.contentType == UTType.plainText)
    part.addCustomHeader(MMSPartContent.MMSCustomHeader(key: "X-Test", value: "1"))
    precondition(part.customHeaders.count == 1)
    precondition(part.customHeaders[0].key == "X-Test")
    tmkRoundTrip(part.customHeaders[0])
    tmkRoundTrip(part.disposition)
    var content = MMSContent(parts: [part], recipients: [MMSHandle(phoneNumber: "+15555550109")], subject: "Hello")
    precondition(content.subject == "Hello")
    precondition(content.recipients.count == 1)
    content.from = MMSHandle(phoneNumber: "+15555550100")
    content.headers["X-Mms"] = "yes"
    precondition(content.from?.phoneNumber == "+15555550100")
    let empty = MMSContent()
    precondition(empty.parts.isEmpty)
    tmkRoundTrip(content)
}

func testMMSMessageSizeAndEquality() {
    let message = tmkMMSMessage()
    precondition(message.totalSize.value == Double(message.content.parts[0].data.count))
    precondition(message.totalSize.unit == UnitInformationStorage.bytes)
    precondition(message.description == message.messageID.description)
    let copy = MMSMessage(
        cellularServiceID: message.cellularServiceID,
        messageID: message.messageID,
        content: message.content
    )
    precondition(message == copy)
    tmkRoundTrip(message)
    tmkRoundTrip(message.messageID)
}

func testMMSConfigurationAndNotifications() {
    let cfg = MMSService.Configuration(
        maximumImageSize: Measurement(value: 1, unit: .megabytes),
        maximumRecipients: 10,
        maximumMessageSize: Measurement(value: 300, unit: .kilobytes),
        maximumSubjectSize: Measurement(value: 80, unit: .bytes),
        smsSizeToBeSentAsMMSInstead: Measurement(value: 160, unit: .bytes)
    )
    precondition(cfg.maximumRecipients == 10)
    _ = cfg.maximumImageSize
    let message = tmkMMSMessage()
    let incoming = MMSService.IncomingMessageNotification(
        cellularServiceID: message.cellularServiceID,
        message: message,
        messageID: message.messageID
    )
    precondition(incoming.messageID == message.messageID)
    let viability = MMSService.ViabilityNotification(cellularServiceID: tmkServiceID(), isViable: false)
    precondition(viability.isViable == false)
}

func testMMSServiceBoundariesAndErrors() {
    let service = TelephonyMessagingSession.shared.mmsService
    precondition(service.isViable(for: tmkServiceID()) == false)
    do {
        _ = try service.incomingMessageNotifications
        preconditionFailure("MMS incoming must fail closed")
    } catch let error as MMSService.Error {
        precondition(error == .mmsNotConfiguredForCarrier)
    } catch {
        preconditionFailure("wrong error \(error)")
    }
    do {
        _ = try service.viabilityNotifications
        preconditionFailure("MMS viability must fail closed")
    } catch let error as MMSService.Error {
        precondition(error == .mmsNotConfiguredForCarrier)
    } catch {
        preconditionFailure("wrong error \(error)")
    }
    let err = MMSService.Error.mmsNotConfiguredForCarrier
    precondition(err.errorDescription != nil)
    precondition(err.recoverySuggestion != nil)
    tmkHash(err)
    tmkRoundTrip(err)
    tmkRoundTrip(MMSService.Error.unknown)
    tmkRoundTrip(MMSService.Error.notSupported)
    tmkRoundTrip(MMSService.Error.invalidRecipient)
    tmkRoundTrip(MMSService.Error.invalidMessageParts)
    tmkRoundTrip(MMSService.Error.internalError)
    tmkRoundTrip(MMSService.Error.mmsNotReady)
    tmkRoundTrip(MMSService.Error.maximumSizeExceeded)
}
