import Foundation
import Messages

func testRecipientPhoneNumber() {
    var recipient = MSRecipient(phoneNumber: "+15555550100")
    precondition(recipient.phoneNumber == "+15555550100")
    recipient.phoneNumber = "+15555550101"
    precondition(recipient.phoneNumber == "+15555550101")
}

func testRecipientEquality() {
    let a = MSRecipient(phoneNumber: "+15555550100")
    let b = MSRecipient(phoneNumber: "+15555550100")
    let c = MSRecipient(phoneNumber: "+15555550999")
    precondition(a == b)
    precondition(a != c)
}

func testRecipientHash() {
    let a = MSRecipient(phoneNumber: "+15555550100")
    let b = MSRecipient(phoneNumber: "+15555550100")
    precondition(a.hashValue == b.hashValue)
    var hasher = Hasher()
    a.hash(into: &hasher)
    _ = hasher.finalize()
}

func testCriticalMessageText() {
    var message = MSCriticalMessage(messageText: "evacuate now")
    precondition(message.messageText == "evacuate now")
    message.messageText = "updated"
    precondition(message.messageText == "updated")
}

func testMessengerInit() {
    let messenger = MSCriticalSMSMessenger()
    precondition(type(of: messenger) == MSCriticalSMSMessenger.self)
    precondition(messenger is NSObject)
}

func testMaximumCriticalMessagingRecipientsIsZero() {
    let messenger = MSCriticalSMSMessenger()
    precondition(messenger.maximumCriticalMessagingRecipients == 0)
}
