import Foundation
import TelephonyMessagingKit

func telephonyMessagingKitDependencyIdentityProbe() {
    let uuid = UUID(uuidString: "00000000-0000-0000-0000-0000000000ab")!
    let data = Data("telephony-messaging-kit".utf8)
    let date = Date(timeIntervalSince1970: 1_700_000_000)
    let url = URL(string: "https://example.invalid/identity")!
    precondition(type(of: uuid) == UUID.self)
    precondition(type(of: data) == Data.self)
    precondition(type(of: date) == Date.self)
    precondition(type(of: url) == URL.self)
    precondition(!String(reflecting: type(of: uuid)).hasPrefix("TelephonyMessagingKit."))
    precondition(!String(reflecting: type(of: data)).hasPrefix("TelephonyMessagingKit."))
    precondition(!String(reflecting: type(of: date)).hasPrefix("TelephonyMessagingKit."))
    precondition(!String(reflecting: type(of: url)).hasPrefix("TelephonyMessagingKit."))

    let serviceID = CellularServiceID(uuid: uuid)
    precondition(serviceID.uuid == uuid)

    let sms = SMSMessage(
        cellularServiceID: serviceID,
        handle: SMSHandle(phoneNumber: "+15555550199"),
        messageID: SMSMessageID(rawValue: 7),
        content: SMSContent(body: String(data: data, encoding: .utf8) ?? "")
    )
    precondition(sms.content.body == "telephony-messaging-kit")

    var part = MMSPartContent(
        data: data,
        contentType: .data,
        contentID: uuid.uuidString,
        disposition: .attachment,
        fileName: url.lastPathComponent
    )
    part.addCustomHeader(MMSPartContent.MMSCustomHeader(key: "X-Date", value: String(date.timeIntervalSince1970)))
    precondition(part.data == data)
    precondition(part.customHeaders[0].value.hasPrefix("1700"))

    let meta = RCSFileTransferMetadata(
        contentType: .jpeg,
        disposition: .attachment,
        expirationDate: date,
        playbackLength: nil,
        url: url,
        fileName: "identity.bin",
        fileSize: data.count
    )
    precondition(meta.url == url)
    precondition(meta.expirationDate == date)
}

#if TELEPHONYMESSAGINGKIT_IDENTITY_MAIN
telephonyMessagingKitDependencyIdentityProbe()
print("TELEPHONYMESSAGINGKIT_DEPENDENCY_IDENTITY_OK")
#endif
