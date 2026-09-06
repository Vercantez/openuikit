import Foundation
import Messages

final class MessagesLifecycleProbe: MSMessagesAppViewController {
    var willSelectCount = 0
    var didSelectCount = 0
    var didReceiveCount = 0
    var didStartSendingCount = 0
    var didCancelSendingCount = 0
    var willTransitionCount = 0
    var didTransitionCount = 0
    var dismissCount = 0

    override func willSelect(_ message: MSMessage, conversation: MSConversation) {
        willSelectCount += 1
        super.willSelect(message, conversation: conversation)
    }

    override func didSelect(_ message: MSMessage, conversation: MSConversation) {
        didSelectCount += 1
        super.didSelect(message, conversation: conversation)
    }

    override func didReceive(_ message: MSMessage, conversation: MSConversation) {
        didReceiveCount += 1
        super.didReceive(message, conversation: conversation)
    }

    override func didStartSending(_ message: MSMessage, conversation: MSConversation) {
        didStartSendingCount += 1
        super.didStartSending(message, conversation: conversation)
    }

    override func didCancelSending(_ message: MSMessage, conversation: MSConversation) {
        didCancelSendingCount += 1
        super.didCancelSending(message, conversation: conversation)
    }

    override func willTransition(to presentationStyle: MSMessagesAppPresentationStyle) {
        willTransitionCount += 1
        super.willTransition(to: presentationStyle)
    }

    override func didTransition(to presentationStyle: MSMessagesAppPresentationStyle) {
        didTransitionCount += 1
        super.didTransition(to: presentationStyle)
    }

    override func dismiss() {
        dismissCount += 1
        super.dismiss()
    }
}

func testDefaultPresentationStyleCompact() {
    let controller = MSMessagesAppViewController()
    precondition(controller.presentationStyle == .compact)
}

func testDefaultPresentationContextMessages() {
    let controller = MSMessagesAppViewController()
    precondition(controller.presentationContext == .messages)
}

func testActiveConversationNil() {
    let controller = MSMessagesAppViewController()
    precondition(controller.activeConversation == nil)
}

func testRequestPresentationStyle() {
    let probe = MessagesLifecycleProbe()
    probe.requestPresentationStyle(.expanded)
    precondition(probe.presentationStyle == .expanded)
    precondition(probe.willTransitionCount == 1)
    precondition(probe.didTransitionCount == 1)
    probe.requestPresentationStyle(.transcript)
    precondition(probe.presentationStyle == .transcript)
}

func testWillBecomeActiveSetsConversation() {
    let controller = MSMessagesAppViewController()
    let conversation = MSConversation()
    controller.willBecomeActive(with: conversation)
    precondition(controller.activeConversation === conversation)
    controller.didBecomeActive(with: conversation)
    precondition(controller.activeConversation === conversation)
}

func testDidResignActiveClearsConversation() {
    let controller = MSMessagesAppViewController()
    let conversation = MSConversation()
    controller.willBecomeActive(with: conversation)
    controller.willResignActive(with: conversation)
    precondition(controller.activeConversation === conversation)
    controller.didResignActive(with: conversation)
    precondition(controller.activeConversation == nil)
}

func testDismissDoesNotCrash() {
    let probe = MessagesLifecycleProbe()
    probe.dismiss()
    precondition(probe.dismissCount == 1)
}

func testSelectReceiveSendHooks() {
    let probe = MessagesLifecycleProbe()
    let conversation = MSConversation()
    let message = MSMessage()
    probe.willSelect(message, conversation: conversation)
    probe.didSelect(message, conversation: conversation)
    probe.didReceive(message, conversation: conversation)
    probe.didStartSending(message, conversation: conversation)
    probe.didCancelSending(message, conversation: conversation)
    precondition(probe.willSelectCount == 1)
    precondition(probe.didSelectCount == 1)
    precondition(probe.didReceiveCount == 1)
    precondition(probe.didStartSendingCount == 1)
    precondition(probe.didCancelSendingCount == 1)
}

func testContentSizeThatFitsZero() {
    let controller = MSMessagesAppViewController()
    let fitted = controller.contentSizeThatFits(CGSize(width: 320, height: 200))
    precondition(fitted == .zero)
}

func testMessageCornerRadiusZero() {
    let controller = MSMessagesAppViewController()
    precondition(controller.messageCornerRadius == 0)
}

func testInvalidateMessageTintColor() {
    let controller = MSMessagesAppViewController()
    controller.invalidateMessageTintColor()
}
