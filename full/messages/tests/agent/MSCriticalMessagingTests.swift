import Foundation
import Messages

func testRequestAuthorizationThrowsNotSupported() async {
    let messenger = MSCriticalSMSMessenger()
    let recipients = [MSRecipient(phoneNumber: "+15555550100")]
    do {
        _ = try await messenger.requestAuthorization(for: recipients)
        preconditionFailure("requestAuthorization should throw notSupported")
    } catch let error as MSCriticalMessagingError {
        precondition(error == .notSupported)
    } catch {
        preconditionFailure("unexpected error: \(error)")
    }
}

func testCheckAuthorizationStatusThrowsNotSupported() async {
    let messenger = MSCriticalSMSMessenger()
    let recipients = [MSRecipient(phoneNumber: "+15555550100")]
    do {
        _ = try await messenger.checkAuthorizationStatus(for: recipients)
        preconditionFailure("checkAuthorizationStatus should throw notSupported")
    } catch let error as MSCriticalMessagingError {
        precondition(error == .notSupported)
    } catch {
        preconditionFailure("unexpected error: \(error)")
    }
}

func testSendThrowsNotSupported() async {
    let messenger = MSCriticalSMSMessenger()
    let message = MSCriticalMessage(messageText: "evacuate now")
    let recipient = MSRecipient(phoneNumber: "+15555550100")
    do {
        _ = try await messenger.send(message, to: recipient)
        preconditionFailure("send should throw notSupported")
    } catch let error as MSCriticalMessagingError {
        precondition(error == .notSupported)
    } catch {
        preconditionFailure("unexpected error: \(error)")
    }
}
