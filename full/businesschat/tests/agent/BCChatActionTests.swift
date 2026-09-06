import Foundation
@_spi(OpenUIKitHost) import BusinessChat

func testChatActionClass() {
    precondition(type(of: BCChatAction.self) == BCChatAction.Type.self)
    let asObjectType: NSObject.Type = BCChatAction.self
    precondition(asObjectType == BCChatAction.self)
    precondition(String(reflecting: BCChatAction.self) == "BusinessChat.BCChatAction")
    precondition(BCChatAction.self is AnyClass)
}

func testOpenTranscriptFailClosed() {
    BusinessChatHostControl.reset()
    precondition(BusinessChatHostControl.lastOpenTranscript() == nil)
    precondition(BusinessChatHostControl.didOpenTranscript() == false)

    let parameters: [BCChatAction.Parameter: String] = [
        .intent: "account_question",
        .group: "billing",
        .body: "Need a copy of my invoice",
    ]
    BCChatAction.openTranscript(
        businessIdentifier: "urn:biz:example-business",
        intentParameters: parameters
    )

    let recorded = BusinessChatHostControl.lastOpenTranscript()
    precondition(recorded?.businessIdentifier == "urn:biz:example-business")
    precondition(recorded?.intentParameters[.intent] == "account_question")
    precondition(recorded?.intentParameters[.group] == "billing")
    precondition(recorded?.intentParameters[.body] == "Need a copy of my invoice")
    precondition(recorded?.intentParameters.count == 3)
    precondition(BusinessChatHostControl.didOpenTranscript() == false)

    switch BusinessChatHostControl.openTranscriptResult() {
    case .success:
        preconditionFailure("Linux must not report a successful transcript open")
    case .failure(let error):
        precondition(error == .linuxHost(operation: "openTranscript"))
    }

    BCChatAction.openTranscript(
        businessIdentifier: "",
        intentParameters: [:]
    )
    let empty = BusinessChatHostControl.lastOpenTranscript()
    precondition(empty?.businessIdentifier == "")
    precondition(empty?.intentParameters.isEmpty == true)
    precondition(BusinessChatHostControl.didOpenTranscript() == false)
}
