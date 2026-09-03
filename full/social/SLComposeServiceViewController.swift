import Foundation

#if canImport(UIKit)
import UIKit
#endif

/// Share-extension compose sheet controller.
///
/// Linux has no `NSExtensionContext` host. `didSelectPost` / `didSelectCancel`
/// record local invocation only; they do not complete an Apple extension
/// request. `cancel()` calls `didSelectCancel()` and refuses to re-enter.

@MainActor
open class SLComposeServiceViewController: UIViewController, UITextViewDelegate {
    private let storedTextView = UITextView()
    private var storedPlaceholder: String?
    private var storedCharactersRemaining: NSNumber?
    private var storedAutoCompletionViewController: UIViewController?
    private var pushedConfigurationViewController: UIViewController?
    private var isHandlingCancel = false
    private var didFinishPresentationAnimation = false
    private var lastValidatedContent: Bool?
    private var configurationReloadCount = 0
    private var didSelectPostCount = 0
    private var didSelectCancelCount = 0
    private var previewView: UIView?

    public override init() {
        #if canImport(UIKit)
        super.init(nibName: nil, bundle: nil)
        #else
        super.init()
        #endif
        storedTextView.delegate = self
        storedTextView.text = ""
    }

    #if canImport(UIKit)
    public required init?(coder: NSCoder) {
        return nil
    }
    #endif

    open var textView: UITextView! { storedTextView }

    open var contentText: String! { storedTextView.text ?? "" }

    open var placeholder: String! {
        get { storedPlaceholder }
        set { storedPlaceholder = newValue }
    }

    open var charactersRemaining: NSNumber! {
        get { storedCharactersRemaining }
        set { storedCharactersRemaining = newValue }
    }

    open var autoCompletionViewController: UIViewController! {
        get { storedAutoCompletionViewController }
        set { storedAutoCompletionViewController = newValue }
    }

    open func presentationAnimationDidFinish() {
        didFinishPresentationAnimation = true
    }

    open func isContentValid() -> Bool {
        true
    }

    open func validateContent() {
        lastValidatedContent = isContentValid()
    }

    open func configurationItems() -> [Any]! {
        []
    }

    open func reloadConfigurationItems() {
        configurationReloadCount += 1
        _ = configurationItems()
    }

    /// At most one pushed configuration controller. A second push is ignored
    /// until `popConfigurationViewController()`.
    open func pushConfigurationViewController(_ viewController: UIViewController!) {
        guard pushedConfigurationViewController == nil, let viewController else {
            return
        }
        pushedConfigurationViewController = viewController
    }

    open func popConfigurationViewController() {
        pushedConfigurationViewController = nil
    }

    open func loadPreviewView() -> UIView! {
        if let previewView {
            return previewView
        }
        let view = UIView()
        previewView = view
        return view
    }

    /// Calls `didSelectCancel()` once. Does not recurse if `didSelectCancel`
    /// calls `cancel()` again.
    open func cancel() {
        guard !isHandlingCancel else { return }
        isHandlingCancel = true
        defer { isHandlingCancel = false }
        didSelectCancel()
    }

    /// Partial Linux host: no `NSExtensionContext` to complete. Does not call
    /// `cancel()`.
    open func didSelectCancel() {
        didSelectCancelCount += 1
    }

    /// Partial Linux host: no Apple share-sheet post pipeline.
    open func didSelectPost() {
        didSelectPostCount += 1
    }

    open func textViewDidChange(_ textView: UITextView) {
        _ = textView.text
    }
}

extension SLComposeServiceViewController {
    @_spi(OpenUIKitHost)
    public var isolatedHostConfigurationReloadCount: Int { configurationReloadCount }

    @_spi(OpenUIKitHost)
    public var isolatedHostPushedConfigurationController: UIViewController? {
        pushedConfigurationViewController
    }

    @_spi(OpenUIKitHost)
    public var isolatedHostDidFinishPresentationAnimation: Bool {
        didFinishPresentationAnimation
    }

    @_spi(OpenUIKitHost)
    public var isolatedHostLastValidatedContent: Bool? { lastValidatedContent }

    @_spi(OpenUIKitHost)
    public var isolatedHostDidSelectPostCount: Int { didSelectPostCount }

    @_spi(OpenUIKitHost)
    public var isolatedHostDidSelectCancelCount: Int { didSelectCancelCount }

    @_spi(OpenUIKitHost)
    public func isolatedHostReplaceText(_ string: String) {
        storedTextView.text = string
        textViewDidChange(storedTextView)
    }
}
