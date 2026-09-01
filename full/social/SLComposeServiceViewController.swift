import Foundation

/// Share-extension compose controller used by the 20-app corpus.
///
/// Text, placeholder, character-count, configuration items, and a local
/// configuration-view stack are implemented. Preview loading has no
/// `NSExtensionContext` attachments on this host, so `loadPreviewView()`
/// returns `nil`. `didSelectPost()` does not send to a social network.
@MainActor
open class SLComposeServiceViewController: UIViewController {
    private let composeTextView = UITextView()
    private var configurationStack: [UIViewController] = []

    public init() {
        super.init(nibName: nil, bundle: nil)
    }

    open var textView: UITextView! { composeTextView }

    open var contentText: String! { composeTextView.text }

    open var placeholder: String!

    open var charactersRemaining: NSNumber!

    open var autoCompletionViewController: UIViewController!

    /// Depth of `pushConfigurationViewController` / `popConfigurationViewController`.
    public var portableConfigurationStackCount: Int { configurationStack.count }

    /// Set by the default `cancel()` implementation.
    public private(set) var portableDidCancel = false

    /// Last `isContentValid()` result observed by `validateContent()`.
    public private(set) var portableContentIsValid = true

    open func presentationAnimationDidFinish() {}

    /// Default Apple behavior is empty; subclasses perform the post.
    /// This starting point does not contact a social network.
    open func didSelectPost() {}

    /// Default Apple behavior forwards to `cancel()`.
    open func didSelectCancel() {
        cancel()
    }

    /// Marks the local sheet cancelled. There is no extension host to notify.
    open func cancel() {
        portableDidCancel = true
    }

    /// Default Apple behavior returns `true`.
    open func isContentValid() -> Bool {
        true
    }

    /// Recomputes validity from `isContentValid()`.
    open func validateContent() {
        portableContentIsValid = isContentValid()
    }

    /// Default Apple behavior returns `nil`.
    open func configurationItems() -> [Any]! {
        nil
    }

    open func reloadConfigurationItems() {
        _ = configurationItems()
    }

    open func pushConfigurationViewController(_ viewController: UIViewController!) {
        guard let viewController else { return }
        configurationStack.append(viewController)
    }

    open func popConfigurationViewController() {
        guard !configurationStack.isEmpty else { return }
        configurationStack.removeLast()
    }

    /// No extension preview attachments are available on Linux.
    open func loadPreviewView() -> UIView! {
        nil
    }
}
