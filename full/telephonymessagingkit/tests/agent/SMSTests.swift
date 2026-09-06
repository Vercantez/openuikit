
import Foundation
import TelephonyMessagingKit

func testSMSContentAndMessage() {
    let content = SMSContent(body: "hello sms")
    precondition(content.body == "hello sms")
    tmkRoundTrip(content)
    let handle = SMSHandle(phoneNumber: "+15555550101")
    precondition(handle.phoneNumber == "+15555550101")
    tmkRoundTrip(handle)
    let mid = SMSMessageID(rawValue: 21)
    precondition(mid.rawValue == 21)
    precondition(mid.description == "21")
    tmkHash(mid)
    tmkRoundTrip(mid)
    let message = SMSMessage(
        cellularServiceID: tmkServiceID(),
        handle: handle,
        messageID: mid,
        content: content
    )
    precondition(message.content.body == "hello sms")
    precondition(message.handle.phoneNumber.hasPrefix("+1"))
    tmkRoundTrip(message)
}

func testSMSNotificationsAndErrors() {
    let message = tmkSMSMessage()
    let incoming = SMSService.IncomingMessageNotification(message: message)
    precondition(incoming.message.messageID == message.messageID)
    let viability = SMSService.ViabilityNotification(cellularServiceID: tmkServiceID(), isViable: false)
    precondition(viability.isViable == false)
    tmkHash(viability)
    let critical = SMSService.CriticalMessageStateNotification(
        cellularServiceID: tmkServiceID(),
        state: .sent,
        messageID: message.messageID
    )
    precondition(critical.state == .sent)
    tmkHash(critical)
    let err = SMSService.Error.notSupported
    precondition(err.errorDescription != nil)
    precondition(err != .unknown)
    tmkHash(err)
    tmkRoundTrip(err)
    tmkRoundTrip(SMSService.Error.permanentFailure)
    tmkRoundTrip(SMSService.Error.temporaryFailure)
    tmkRoundTrip(SMSService.Error.unknown)
}

func testSMSServiceBoundaries() {
    let service = TelephonyMessagingSession.shared.smsService
    precondition(service.isViable(for: tmkServiceID()) == false)
    do {
        _ = try service.incomingMessageNotifications
        preconditionFailure("incoming SMS notifications must fail closed")
    } catch let error as SMSService.Error {
        precondition(error == .notSupported)
    } catch {
        preconditionFailure("wrong error type \(error)")
    }
    do {
        _ = try service.viabilityNotifications
        preconditionFailure("SMS viability notifications must fail closed")
    } catch let error as SMSService.Error {
        precondition(error == .notSupported)
    } catch {
        preconditionFailure("wrong error type \(error)")
    }
    do {
        _ = try service.criticalMessageStateNotifications
        preconditionFailure("critical SMS notifications must fail closed")
    } catch let error as SMSService.Error {
        precondition(error == .notSupported)
    } catch {
        preconditionFailure("wrong error type \(error)")
    }
}
