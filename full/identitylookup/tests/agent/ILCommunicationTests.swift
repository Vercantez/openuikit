import Foundation
import IdentityLookup

func testCallCommunicationStoresSenderAndDate() {
    let date = Date(timeIntervalSince1970: 1_700_000_000)
    let call = ILCallCommunication(sender: "+15555550100", dateReceived: date)
    precondition(call.sender == "+15555550100")
    precondition(call.dateReceived == date)
}

func testMessageCommunicationStoresBody() {
    let date = Date(timeIntervalSince1970: 1_700_000_100)
    let message = ILMessageCommunication(
        sender: "SHORTCODE",
        dateReceived: date,
        messageBody: "Your code is 123456"
    )
    precondition(message.sender == "SHORTCODE")
    precondition(message.dateReceived == date)
    precondition(message.messageBody == "Your code is 123456")
}

func testCommunicationSecureCodingRoundTrip() {
    let date = Date(timeIntervalSince1970: 1_700_000_200)
    let original = ILMessageCommunication(
        sender: "Alice",
        dateReceived: date,
        messageBody: "hello"
    )
    let data = try! NSKeyedArchiver.archivedData(
        withRootObject: original,
        requiringSecureCoding: true
    )
    let decoded = try! NSKeyedUnarchiver.unarchivedObject(
        ofClass: ILMessageCommunication.self,
        from: data
    )
    precondition(decoded != nil)
    precondition(decoded?.sender == "Alice")
    precondition(decoded?.messageBody == "hello")
    precondition(decoded?.dateReceived.timeIntervalSince1970 == date.timeIntervalSince1970)
}

func testCallCommunicationSecureCodingRoundTrip() {
    let date = Date(timeIntervalSince1970: 1_700_000_250)
    let original = ILCallCommunication(sender: "+15555550999", dateReceived: date)
    let data = try! NSKeyedArchiver.archivedData(
        withRootObject: original,
        requiringSecureCoding: true
    )
    let decoded = try! NSKeyedUnarchiver.unarchivedObject(
        ofClass: ILCallCommunication.self,
        from: data
    )
    precondition(decoded?.sender == "+15555550999")
    precondition(decoded?.dateReceived.timeIntervalSince1970 == date.timeIntervalSince1970)
}

func testCommunicationCoderRejectsMissingDate() {
    let empty = try! NSKeyedArchiver.archivedData(
        withRootObject: NSString(string: "not-a-communication"),
        requiringSecureCoding: true
    )
    let decoded = try? NSKeyedUnarchiver.unarchivedObject(
        ofClass: ILCommunication.self,
        from: empty
    )
    precondition(decoded == nil)
}
