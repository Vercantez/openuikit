import Foundation
import Messages

func testSessionInit() {
    let session = MSSession()
    let other = MSSession()
    precondition(session.linuxSessionIdentifier != other.linuxSessionIdentifier)
}

func testSessionCoding() {
    let session = MSSession()
    let data = try! NSKeyedArchiver.archivedData(
        withRootObject: session,
        requiringSecureCoding: true
    )
    let decoded = try! NSKeyedUnarchiver.unarchivedObject(
        ofClass: MSSession.self,
        from: data
    )
    precondition(decoded != nil)
    precondition(decoded?.linuxSessionIdentifier == session.linuxSessionIdentifier)
}

func testMessageDefaultInit() {
    let message = MSMessage()
    precondition(message.session == nil)
    precondition(message.isPending == false)
    let nullSender = UUID(uuid: (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0))
    precondition(message.senderParticipantIdentifier == nullSender)
    precondition(message.shouldExpire == false)
    precondition(message.url == nil)
    precondition(message.layout == nil)
    precondition(message.accessibilityLabel == nil)
    precondition(message.summaryText == nil)
    precondition(message.error == nil)
}

func testMessageSessionInit() {
    let session = MSSession()
    let message = MSMessage(session: session)
    precondition(message.session === session)
    precondition(message.isPending == false)
}

func testMessageURLAndSummary() {
    let message = MSMessage()
    let url = URL(string: "https://example.com/balloon")
    message.url = url
    message.summaryText = "hello"
    message.accessibilityLabel = "balloon"
    precondition(message.url == url)
    precondition(message.summaryText == "hello")
    precondition(message.accessibilityLabel == "balloon")
}

func testMessageShouldExpire() {
    let message = MSMessage()
    message.shouldExpire = true
    precondition(message.shouldExpire == true)
    message.shouldExpire = false
    precondition(message.shouldExpire == false)
}

func testMessageErrorProperty() {
    let message = MSMessage()
    message.error = MSCriticalMessagingError.sendFailed
    precondition(message.error is MSCriticalMessagingError)
}

func testMessageLayoutCopying() {
    let layout = MSMessageTemplateLayout()
    layout.caption = "caption"
    let message = MSMessage()
    message.layout = layout
    layout.caption = "mutated"
    let stored = message.layout as? MSMessageTemplateLayout
    precondition(stored?.caption == "caption")
    precondition(stored !== layout)
}

func testMessageCopy() {
    let session = MSSession()
    let message = MSMessage(session: session)
    message.shouldExpire = true
    message.summaryText = "sum"
    message.url = URL(string: "https://example.com/x")
    let layout = MSMessageTemplateLayout()
    layout.imageTitle = "title"
    message.layout = layout
    let copy = message.copy() as! MSMessage
    precondition(copy !== message)
    precondition(copy.session === session)
    precondition(copy.shouldExpire == true)
    precondition(copy.summaryText == "sum")
    precondition(copy.url == message.url)
    let copiedLayout = copy.layout as? MSMessageTemplateLayout
    precondition(copiedLayout?.imageTitle == "title")
    precondition(copiedLayout !== layout)
}

func testMessageCoding() {
    let message = MSMessage()
    message.shouldExpire = true
    message.summaryText = "coded"
    message.url = URL(string: "https://example.com/coded")
    let data = try! NSKeyedArchiver.archivedData(
        withRootObject: message,
        requiringSecureCoding: true
    )
    let decoded = try! NSKeyedUnarchiver.unarchivedObject(
        ofClass: MSMessage.self,
        from: data
    )
    precondition(decoded != nil)
    precondition(decoded?.shouldExpire == true)
    precondition(decoded?.summaryText == "coded")
    precondition(decoded?.url == URL(string: "https://example.com/coded"))
    precondition(decoded?.isPending == false)
}
