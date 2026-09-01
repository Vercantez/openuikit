import Foundation

#if canImport(UIKit)
import UIKit
#endif

/// Share-extension compose controller used by the 20-app corpus.
///
/// Text, placeholder, character count, validity, configuration items, and a
/// single pushed configuration controller are implemented. Preview loading
/// has no extension attachments, so `loadPreviewView()` returns `nil`.
/// `didSelectPost()` / `didSelectCancel()` are partial host hooks: they do
/// not complete an Apple `NSExtensionContext`.
@MainActor
open class SLComposeServiceViewController: UIViewController, UITextViewDelegate {
    private let composeTextView = UITextView()
    private var pushedConfigurationController: UIViewController?

    public init() {
        super.init(nibName: nil, bundle: nil)
        composeTextView.delegate = self
        _ = Self.uiTextViewDelegateWitness(self)
    }

    open var textView: UITextView! { composeTextView }

    open var contentText: String! { composeTextView.text }

    open var placeholder: String!

    open var charactersRemaining: NSNumber!

    open var autoCompletionViewController: UIViewController!

    @_spi(OpenUIKitHost)
    public var hostConfigurationControllerCount: Int {
        pushedConfigurationController == nil ? 0 : 1
    }

    @_spi(OpenUIKitHost)
    public private(set) var hostExtensionCompletion: SocialHostExtensionCompletion = .none

    @_spi(OpenUIKitHost)
    public private(set) var hostContentIsValid = true

    open func presentationAnimationDidFinish() {}

    /// Partial host hook. Apple's default is empty; subclasses post.
    /// This does not complete an extension request.
    open func didSelectPost() {
        hostExtensionCompletion = .postedWithoutExtensionContext
    }

    /// Partial host hook. Records cancellation without `NSExtensionContext`
    /// completion. Does not call `cancel()` (avoids recursion).
    open func didSelectCancel() {
        hostExtensionCompletion = .cancelledWithoutExtensionContext
    }

    /// Triggers `didSelectCancel()`. There is no extension host to notify.
    open func cancel() {
        didSelectCancel()
    }

    /// Default Apple behavior returns `true`.
    open func isContentValid() -> Bool {
        true
    }

    /// Recomputes validity from `isContentValid()`.
    open func validateContent() {
        hostContentIsValid = isContentValid()
    }

    /// Default Apple behavior returns `nil`.
    open func configurationItems() -> [Any]! {
        nil
    }

    open func reloadConfigurationItems() {
        _ = configurationItems()
    }

    /// At most one configuration controller is retained.
    open func pushConfigurationViewController(_ viewController: UIViewController!) {
        guard let viewController else { return }
        guard pushedConfigurationController == nil else { return }
        pushedConfigurationController = viewController
    }

    open func popConfigurationViewController() {
        pushedConfigurationController = nil
    }

    /// No extension preview attachments are available on this host.
    open func loadPreviewView() -> UIView! {
        nil
    }

    open func textViewDidChange(_ textView: UITextView) {
        _ = textView
        validateContent()
    }

    private static func uiTextViewDelegateWitness(
        _ controller: SLComposeServiceViewController
    ) -> any UITextViewDelegate {
        controller
    }
}
