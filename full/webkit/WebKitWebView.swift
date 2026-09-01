@_exported import Foundation
#if canImport(UIKit)
@_exported import UIKit
#elseif canImport(OpenUIKit)
@_exported import OpenUIKit
#endif

@preconcurrency @MainActor
open class WKWebView: UIView {
    public let configuration: WKWebViewConfiguration
    public weak var navigationDelegate: WKNavigationDelegate?
    public weak var uiDelegate: WKUIDelegate?
    public let backForwardList = WKBackForwardList()
    public let scrollView: UIScrollView

    open var allowsBackForwardNavigationGestures = false
    open var allowsLinkPreview = true
    open var customUserAgent: String? = ""

    private var _obscuredContentInsets: UIEdgeInsets = .zero
    /// Insets covered by app-owned chrome. WebKit requires every edge to be
    /// non-negative; invalid geometry fails before mutating retained state.
    open var obscuredContentInsets: UIEdgeInsets {
        get { _obscuredContentInsets }
        set {
            precondition(
                newValue.top >= 0 && newValue.left >= 0 &&
                    newValue.bottom >= 0 && newValue.right >= 0,
                "WKWebView obscuredContentInsets must be non-negative"
            )
            _setObserved(
                \WKWebView.obscuredContentInsets,
                storage: &_obscuredContentInsets,
                to: newValue
            )
        }
    }

    private var _underPageBackgroundColor: UIColor? = .white
    /// A renderer may replace this value from page content. With no renderer,
    /// the explicitly assigned app value remains authoritative and observable.
    open var underPageBackgroundColor: UIColor? {
        get { _underPageBackgroundColor }
        set {
            // `null_resettable` resets to WebKit's opaque-white default.
            let resolvedValue: UIColor? = newValue ?? .white
            _setObservedIfChanged(
                \WKWebView.underPageBackgroundColor,
                storage: &_underPageBackgroundColor,
                to: resolvedValue
            )
        }
    }

    public private(set) var url: URL?
    public private(set) var title: String? = ""
    public private(set) var estimatedProgress: Double = 0
    public private(set) var isLoading = false
    public private(set) var hasOnlySecureContent = false
    public private(set) var lastPortableError: WKPortableError?

    open var canGoBack: Bool {
        backForwardList.backItem != nil
    }
    open var canGoForward: Bool {
        backForwardList.forwardItem != nil
    }

    private var navigationGeneration: UInt64 = 0
    private var isDeliveringFailure = false
    private var isAllMediaPlaybackSuspended = false

    public init(frame: CGRect, configuration: WKWebViewConfiguration) {
        self.configuration = configuration._portableCopyForWebView()
        self.scrollView = UIScrollView(
            frame: CGRect(origin: .zero, size: frame.size)
        )
        super.init(frame: frame)
        addSubview(scrollView)
    }

    public override convenience init(frame: CGRect) {
        self.init(frame: frame, configuration: WKWebViewConfiguration())
    }

    public required init?(coder: NSCoder) {
        self.configuration = WKWebViewConfiguration()
        self.scrollView = UIScrollView()
        super.init(coder: coder)
        addSubview(scrollView)
    }

    open override func layoutSubviews() {
        super.layoutSubviews()
        scrollView.frame = bounds
    }

    @discardableResult
    open func load(_ request: URLRequest) -> WKNavigation? {
        _beginUnavailableNavigation(
            request: request,
            navigationType: .other,
            operation: "load(request:)"
        )
    }

    @discardableResult
    open func loadFileURL(
        _ url: URL,
        allowingReadAccessTo readAccessURL: URL
    ) -> WKNavigation? {
        _beginUnavailableNavigation(
            request: URLRequest(url: url),
            navigationType: .other,
            operation: "loadFileURL(_:allowingReadAccessTo:)"
        )
    }

    @discardableResult
    open func loadHTMLString(_ string: String, baseURL: URL?) -> WKNavigation? {
        let requested = baseURL ?? URL(string: "about:blank")!
        return _beginUnavailableNavigation(
            request: URLRequest(url: requested),
            navigationType: .other,
            operation: "loadHTMLString(_:baseURL:)"
        )
    }

    @discardableResult
    open func load(
        _ data: Data,
        mimeType: String,
        characterEncodingName: String,
        baseURL: URL
    ) -> WKNavigation? {
        _beginUnavailableNavigation(
            request: URLRequest(url: baseURL),
            navigationType: .other,
            operation: "load(_:mimeType:characterEncodingName:baseURL:)"
        )
    }

    open func stopLoading() {
        navigationGeneration &+= 1
        _setObservedIfChanged(
            \WKWebView.isLoading, storage: &isLoading, to: false
        )
    }

    /// Retains the suspension state even though the portable WebKit has no
    /// media engine. Completion is delivered exactly once after the state
    /// transition has committed, allowing callers to serialize later loads.
    open func setAllMediaPlaybackSuspended(
        _ suspended: Bool,
        completionHandler: (@MainActor @Sendable () -> Void)? = nil
    ) {
        isAllMediaPlaybackSuspended = suspended
        guard let completionHandler else { return }
        Task { @MainActor in
            // Apple's completion is never delivered before this method
            // returns. Yielding also preserves call order on the main actor.
            await Task.yield()
            completionHandler()
        }
    }

    /// Swift-concurrency spelling synthesized by Apple's WebKit importer.
    open func setAllMediaPlaybackSuspended(_ suspended: Bool) async {
        await withCheckedContinuation { continuation in
            setAllMediaPlaybackSuspended(suspended) {
                continuation.resume()
            }
        }
    }

    @discardableResult
    open func reload() -> WKNavigation? {
        guard let url else { return nil }
        return _beginUnavailableNavigation(
            request: URLRequest(url: url),
            navigationType: .reload,
            operation: "reload()"
        )
    }

    @discardableResult
    open func reloadFromOrigin() -> WKNavigation? {
        guard let url else { return nil }
        return _beginUnavailableNavigation(
            request: URLRequest(
                url: url,
                cachePolicy: .reloadIgnoringLocalCacheData
            ),
            navigationType: .reload,
            operation: "reloadFromOrigin()"
        )
    }

    @discardableResult
    open func goBack() -> WKNavigation? {
        nil
    }

    @discardableResult
    open func goForward() -> WKNavigation? {
        nil
    }

    @discardableResult
    open func go(to item: WKBackForwardListItem) -> WKNavigation? {
        nil
    }

    open func evaluateJavaScript(
        _ javaScriptString: String,
        completionHandler: ((Any?, Error?) -> Void)? = nil
    ) {
        completionHandler?(
            nil,
            WKPortableError(
                code: .engineUnavailable,
                operation: "evaluateJavaScript(_:)"
            )
        )
    }

    @discardableResult
    private func _beginUnavailableNavigation(
        request: URLRequest,
        navigationType: WKNavigationType,
        operation: String
    ) -> WKNavigation {
        navigationGeneration &+= 1
        let generation = navigationGeneration
        let preferences = configuration.defaultWebpagePreferences._portableCopy()
        let navigation = WKNavigation(
            requestedURL: request.url,
            effectiveContentMode: preferences.preferredContentMode
        )
        let action = WKNavigationAction(
            request: request,
            navigationType: navigationType,
            targetFrame: WKFrameInfo(isMainFrame: true, request: request)
        )
        if isDeliveringFailure {
            _setObservedIfChanged(
                \WKWebView.url, storage: &url, to: request.url
            )
            _setObservedIfChanged(
                \WKWebView.title, storage: &title, to: ""
            )
            estimatedProgress = 0
            hasOnlySecureContent = false
            _setObservedIfChanged(
                \WKWebView.isLoading, storage: &isLoading, to: false
            )
            lastPortableError = WKPortableError(
                code: .engineUnavailable,
                operation: operation,
                requestedURL: request.url
            )
            return navigation
        }
        var decided = false

        let apply: (WKNavigationActionPolicy, WKWebpagePreferences) -> Void = {
            [weak self, weak navigation] policy, selectedPreferences in
            guard let self, let navigation, !decided else { return }
            decided = true
            guard self.navigationGeneration == generation else { return }
            guard policy == .allow else {
                self._setObservedIfChanged(
                    \WKWebView.isLoading,
                    storage: &self.isLoading,
                    to: false
                )
                return
            }

            navigation.effectiveContentMode = selectedPreferences.preferredContentMode
            self._setObservedIfChanged(
                \WKWebView.url, storage: &self.url, to: request.url
            )
            self._setObservedIfChanged(
                \WKWebView.title, storage: &self.title, to: ""
            )
            self.estimatedProgress = 0
            self.hasOnlySecureContent = false
            self._setObservedIfChanged(
                \WKWebView.isLoading, storage: &self.isLoading, to: true
            )
            self.lastPortableError = nil
            self.navigationDelegate?.webView(
                self,
                didStartProvisionalNavigation: navigation
            )

            // No transport or renderer is linked. A provisional failure is a
            // real outcome; didCommit/didFinish are deliberately impossible.
            let failure = WKPortableError(
                code: .engineUnavailable,
                operation: operation,
                requestedURL: request.url
            )
            self._setObservedIfChanged(
                \WKWebView.isLoading, storage: &self.isLoading, to: false
            )
            self.lastPortableError = failure
            // Focus and many browsers respond to a provisional failure by
            // synchronously loading locally generated error-page data. There
            // is still no renderer, so that nested request cannot succeed;
            // record its terminal error without recursively invoking the same
            // delegate until the stack overflows. A later, non-reentrant load
            // remains observable through a fresh failure callback.
            self.isDeliveringFailure = true
            self.navigationDelegate?.webView(
                self,
                didFailProvisionalNavigation: navigation,
                withError: failure
            )
            self.isDeliveringFailure = false
        }

        if let navigationDelegate {
            navigationDelegate.webView(
                self,
                decidePolicyFor: action,
                preferences: preferences,
                decisionHandler: apply
            )
        } else {
            apply(.allow, preferences)
        }
        return navigation
    }

    private func _setObserved<Value>(
        _ keyPath: KeyPath<WKWebView, Value>,
        storage: inout Value,
        to newValue: Value
    ) {
        let oldValue = storage
        #if !PORTABLE_WEBKIT_HOST
        _portableWillChangeValue(for: keyPath, oldValue: oldValue)
        #endif
        storage = newValue
        #if !PORTABLE_WEBKIT_HOST
        _portableDidChangeValue(
            for: keyPath, oldValue: oldValue, newValue: newValue
        )
        #endif
    }

    private func _setObservedIfChanged<Value: Equatable>(
        _ keyPath: KeyPath<WKWebView, Value>,
        storage: inout Value,
        to newValue: Value
    ) {
        guard storage != newValue else { return }
        _setObserved(keyPath, storage: &storage, to: newValue)
    }
}
