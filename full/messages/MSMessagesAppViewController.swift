import Foundation

/// Transcript chrome for an iMessage app. `messageTintColor` (`UIColor`)
/// is omitted on the isolated host.
public protocol MSMessagesAppTranscriptPresentation {
    func contentSizeThatFits(_ size: CGSize) -> CGSize
    func invalidateMessageTintColor()
    var messageCornerRadius: CGFloat { get }
}

/// iMessage app extension view controller. Isolated host subclasses
/// `NSObject` because `UIViewController` is UIKit-owned. There is no
/// Messages host, so `activeConversation` stays `nil` until a lifecycle
/// method is invoked with a locally constructed conversation, insert/send
/// still fail closed on that conversation, and presentation-style requests
/// update in-process state only.
open class MSMessagesAppViewController: NSObject, MSMessagesAppTranscriptPresentation {
    public private(set) var activeConversation: MSConversation?
    public private(set) var presentationStyle: MSMessagesAppPresentationStyle
    public private(set) var presentationContext: MSMessagesAppPresentationContext
    public private(set) var messageCornerRadius: CGFloat

    public override init() {
        self.activeConversation = nil
        self.presentationStyle = .compact
        self.presentationContext = .messages
        self.messageCornerRadius = 0
        super.init()
    }

    open func requestPresentationStyle(
        _ presentationStyle: MSMessagesAppPresentationStyle
    ) {
        willTransition(to: presentationStyle)
        self.presentationStyle = presentationStyle
        didTransition(to: presentationStyle)
    }

    open func dismiss() {}

    open func willBecomeActive(with conversation: MSConversation) {
        activeConversation = conversation
    }

    open func didBecomeActive(with conversation: MSConversation) {
        activeConversation = conversation
    }

    open func willResignActive(with conversation: MSConversation) {
        _ = conversation
    }

    open func didResignActive(with conversation: MSConversation) {
        _ = conversation
        activeConversation = nil
    }

    open func willSelect(_ message: MSMessage, conversation: MSConversation) {
        _ = message
        _ = conversation
    }

    open func didSelect(_ message: MSMessage, conversation: MSConversation) {
        _ = message
        _ = conversation
    }

    open func didReceive(_ message: MSMessage, conversation: MSConversation) {
        _ = message
        _ = conversation
    }

    open func didStartSending(_ message: MSMessage, conversation: MSConversation) {
        _ = message
        _ = conversation
    }

    open func didCancelSending(_ message: MSMessage, conversation: MSConversation) {
        _ = message
        _ = conversation
    }

    open func willTransition(to presentationStyle: MSMessagesAppPresentationStyle) {
        _ = presentationStyle
    }

    open func didTransition(to presentationStyle: MSMessagesAppPresentationStyle) {
        _ = presentationStyle
    }

    open func contentSizeThatFits(_ size: CGSize) -> CGSize {
        _ = size
        return .zero
    }

    open func invalidateMessageTintColor() {}
}
