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

    public private(set) var url: URL?
    public private(set) var title: String? = ""
    public private(set) var estimatedProgress: Double = 0
    public private(set) var isLoading = false
    public private(set) var hasOnlySecureContent = false
    public private(set) var lastPortableError: WKPortableError?

    open var canGoBack: Bool { backForwardList.backItem != nil }
    open var canGoForward: Bool { backForwardList.forwardItem != nil }

    private var navigationGeneration: UInt64 = 0
    private var isDeliveringFailure = false

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
        isLoading = false
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
            url = request.url
            title = ""
            estimatedProgress = 0
            hasOnlySecureContent = false
            isLoading = false
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
                self.isLoading = false
                return
            }

            navigation.effectiveContentMode = selectedPreferences.preferredContentMode
            self.url = request.url
            self.title = ""
            self.estimatedProgress = 0
            self.hasOnlySecureContent = false
            self.isLoading = true
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
            self.isLoading = false
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
}
