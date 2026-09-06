import Foundation
import IdentityLookup

func testClassificationResponseActionInit() {
    let response = ILClassificationResponse(action: .reportJunk)
    precondition(response.action == .reportJunk)
    precondition(response.userString == nil)
    precondition(response.userInfo == nil)
}

func testClassificationResponseClassificationActionInit() {
    let response = ILClassificationResponse(classificationAction: .reportNotJunk)
    precondition(response.action == .reportNotJunk)
}

func testClassificationResponseUserFields() {
    let response = ILClassificationResponse(action: .reportJunkAndBlockSender)
    response.userString = "blocked"
    response.userInfo = ["reason": "spam"]
    precondition(response.userString == "blocked")
    precondition(response.userInfo?["reason"] as? String == "spam")
}

func testClassificationResponseSecureCodingRoundTrip() {
    let original = ILClassificationResponse(action: .reportJunk)
    original.userString = "junk"
    let data = try! NSKeyedArchiver.archivedData(
        withRootObject: original,
        requiringSecureCoding: true
    )
    let decoded = try! NSKeyedUnarchiver.unarchivedObject(
        ofClass: ILClassificationResponse.self,
        from: data
    )
    precondition(decoded?.action == .reportJunk)
    precondition(decoded?.userString == "junk")
}

func testCallClassificationRequestStoresCalls() {
    let date = Date(timeIntervalSince1970: 1_700_000_300)
    let call = ILCallCommunication(sender: "+15555550111", dateReceived: date)
    let request = ILCallClassificationRequest(callCommunications: [call])
    precondition(request.callCommunications.count == 1)
    precondition(request.callCommunications[0].sender == "+15555550111")
}

func testMessageClassificationRequestStoresMessages() {
    let date = Date(timeIntervalSince1970: 1_700_000_400)
    let message = ILMessageCommunication(
        sender: "BANK",
        dateReceived: date,
        messageBody: "otp"
    )
    let request = ILMessageClassificationRequest(messageCommunications: [message])
    precondition(request.messageCommunications.count == 1)
    precondition(request.messageCommunications[0].messageBody == "otp")
}

func testClassificationRequestSecureCodingRoundTrip() {
    let date = Date(timeIntervalSince1970: 1_700_000_500)
    let call = ILCallCommunication(sender: "+15555550222", dateReceived: date)
    let original = ILCallClassificationRequest(callCommunications: [call])
    let data = try! NSKeyedArchiver.archivedData(
        withRootObject: original,
        requiringSecureCoding: true
    )
    let decoded = try! NSKeyedUnarchiver.unarchivedObject(
        ofClass: ILCallClassificationRequest.self,
        from: data
    )
    precondition(decoded?.callCommunications.count == 1)
    precondition(decoded?.callCommunications[0].sender == "+15555550222")
}

func testMessageClassificationRequestSecureCodingRoundTrip() {
    let date = Date(timeIntervalSince1970: 1_700_000_550)
    let message = ILMessageCommunication(
        sender: "SHOP",
        dateReceived: date,
        messageBody: "order"
    )
    let original = ILMessageClassificationRequest(messageCommunications: [message])
    let data = try! NSKeyedArchiver.archivedData(
        withRootObject: original,
        requiringSecureCoding: true
    )
    let decoded = try! NSKeyedUnarchiver.unarchivedObject(
        ofClass: ILMessageClassificationRequest.self,
        from: data
    )
    precondition(decoded?.messageCommunications.count == 1)
    precondition(decoded?.messageCommunications[0].messageBody == "order")
}

func testClassificationRequestBaseInit() {
    let request = ILClassificationRequest()
    precondition(type(of: request) == ILClassificationRequest.self)
    let data = try! NSKeyedArchiver.archivedData(
        withRootObject: request,
        requiringSecureCoding: true
    )
    let decoded = try! NSKeyedUnarchiver.unarchivedObject(
        ofClass: ILClassificationRequest.self,
        from: data
    )
    precondition(decoded != nil)
}
