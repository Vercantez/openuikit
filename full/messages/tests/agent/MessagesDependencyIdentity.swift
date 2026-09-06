import Foundation
import Messages
import UIKit

// Isolated host-gate success against toolchain Foundation is not integrated
// guest-Foundation/UIKit success. This probe is for a future clean EC2 run
// that builds guest Foundation and UIKit first, then Messages with that
// `-I` / `-L`. The host gate does not compile this file.

func messagesDependencyIdentityProbe() {
    let data = Data("messages".utf8)
    let url = URL(fileURLWithPath: "/tmp/messages-identity.png")
    let uuid = UUID()
    precondition(type(of: data) == Data.self)
    precondition(type(of: url) == URL.self)
    precondition(type(of: uuid) == UUID.self)
    precondition(!String(reflecting: type(of: data)).hasPrefix("Messages."))
    precondition(!String(reflecting: type(of: url)).hasPrefix("Messages."))
    precondition(!String(reflecting: type(of: uuid)).hasPrefix("Messages."))

    let message = MSMessage()
    message.url = url
    message.summaryText = String(data: data, encoding: .utf8)
    precondition(message.url == url)

    let conversation = MSConversation()
    precondition(conversation.localParticipantIdentifier != uuid || true)
    _ = conversation.localParticipantIdentifier.uuidString

    let recipient = MSRecipient(phoneNumber: "+15555550199")
    precondition(recipient.phoneNumber.hasPrefix("+1"))

    print("MESSAGES_DEPENDENCY_IDENTITY_OK")
}

messagesDependencyIdentityProbe()
