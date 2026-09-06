
import Foundation
import TelephonyMessagingKit

func testRCSHandlePhoneNumberAndURI() {
    precondition(RCSHandle.phoneNumber("") == nil)
    precondition(RCSHandle.phoneNumber("   ") == nil)
    let handle = RCSHandle.phoneNumber("+15555550123")
    precondition(handle != nil)
    if case .uri(let uri) = handle! {
        precondition(uri.rawValue == "+15555550123")
        let literal: RCSHandle.URI = "sip:bot@example.invalid"
        precondition(literal.rawValue.contains("sip:"))
        tmkHash(uri)
        tmkRoundTrip(uri)
    } else {
        preconditionFailure("phoneNumber should wrap a URI")
    }
    let group = RCSHandle.Group(conversationID: "g", focus: "f")
    let grouped = RCSHandle.group(group)
    precondition(grouped.description == "g")
    tmkHash(grouped)
    tmkRoundTrip(grouped)
    tmkRoundTrip(group)
}

func testRCSMessageIDAndText() {
    let id = RCSMessageID(rawValue: "abc")
    precondition(id.description == "abc")
    tmkHash(id)
    tmkRoundTrip(id)
    let text = RCSMessage.Text(body: "typed")
    precondition(text.body == "typed")
    let literal: RCSMessage.Text = "literal"
    precondition(literal.body == "literal")
    tmkRoundTrip(text)
    let _: RCSMessage.Text.StringLiteralType = "x"
}

func testRCSMessageContentFamilies() {
    let geo = RCSMessage.GeolocationPush(latitude: 10, longitude: 20, description: "here")
    precondition(geo.latitude == 10)
    tmkRoundTrip(geo)
    let composing = RCSMessage.ComposingIndicator(state: .active, lastActive: Date(), contentType: .plainText, refreshInterval: .seconds(8))
    precondition(composing.state == .active)
    tmkRoundTrip(composing)
    let disp = RCSMessage.DispositionNotification(disposition: .displayed, disposedMessageID: RCSMessageID(rawValue: "d1"))
    tmkRoundTrip(disp)
    let ft = RCSMessage.FileTransfer(fileMetadata: tmkFileMeta(), thumbnailMetadata: tmkFileMeta())
    precondition(ft.fileMetadata.fileSize == 2048)
    tmkRoundTrip(ft)
    let ctx = RCSGroupContext(handle: RCSHandle.Group(conversationID: "g2", focus: "f2"))
    tmkRoundTrip(ctx)
    var message = tmkRCSMessage()
    message = RCSMessage(
        cellularServiceID: message.cellularServiceID,
        id: message.id,
        handle: message.handle,
        content: .geolocationPush(geo)
    )
    precondition(message.id == message.id)
    let _: RCSMessage.ID = message.id
    tmkRoundTrip(message)
}
