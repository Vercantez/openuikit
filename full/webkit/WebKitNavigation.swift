@_exported import Foundation

#if canImport(ObjectiveC)
import class ObjectiveC.NSObject
#else
import class Foundation.NSObject
#endif

public enum WKNavigationType: Int, Sendable {
    case linkActivated = 0
    case formSubmitted = 1
    case backForward = 2
    case reload = 3
    case formResubmitted = 4
    case other = -1
}

public enum WKNavigationActionPolicy: Int, Sendable {
    case cancel = 0
    case allow = 1
    case download = 2
}

public enum WKNavigationResponsePolicy: Int, Sendable {
    case cancel = 0
    case allow = 1
    case download = 2
}

@preconcurrency @MainActor
open class WKFrameInfo: NSObject {
    public let isMainFrame: Bool
    public let request: URLRequest

    public init(
        isMainFrame: Bool = true,
        request: URLRequest = URLRequest(url: URL(string: "about:blank")!)
    ) {
        self.isMainFrame = isMainFrame
        self.request = request
        super.init()
    }
}

@preconcurrency @MainActor
open class WKNavigationAction: NSObject {
    public let request: URLRequest
    public let navigationType: WKNavigationType
    public let targetFrame: WKFrameInfo?

    internal init(
        request: URLRequest,
        navigationType: WKNavigationType,
        targetFrame: WKFrameInfo?
    ) {
        self.request = request
        self.navigationType = navigationType
        self.targetFrame = targetFrame
        super.init()
    }
}

@preconcurrency @MainActor
open class WKNavigationResponse: NSObject {
    public let response: URLResponse
    public let canShowMIMEType: Bool

    public init(response: URLResponse, canShowMIMEType: Bool) {
        self.response = response
        self.canShowMIMEType = canShowMIMEType
        super.init()
    }
}

@preconcurrency @MainActor
open class WKNavigation: NSObject {
    public internal(set) var effectiveContentMode: WKWebpagePreferences.ContentMode
    public let requestedURL: URL?

    internal init(
        requestedURL: URL?,
        effectiveContentMode: WKWebpagePreferences.ContentMode
    ) {
        self.requestedURL = requestedURL
        self.effectiveContentMode = effectiveContentMode
        super.init()
    }
}

@preconcurrency @MainActor
open class WKBackForwardListItem: NSObject {
    public let url: URL
    public let title: String?
    public let initialURL: URL

    internal init(url: URL, title: String?, initialURL: URL) {
        self.url = url
        self.title = title
        self.initialURL = initialURL
        super.init()
    }
}

@preconcurrency @MainActor
open class WKBackForwardList: NSObject {
    private var items: [WKBackForwardListItem] = []
    private var index: Int?

    open var currentItem: WKBackForwardListItem? {
        guard let index else { return nil }
        return items[index]
    }

    open var backItem: WKBackForwardListItem? {
        guard let index, index > 0 else { return nil }
        return items[index - 1]
    }

    open var forwardItem: WKBackForwardListItem? {
        guard let index, index + 1 < items.count else { return nil }
        return items[index + 1]
    }

    open var backList: [WKBackForwardListItem] {
        guard let index, index > 0 else { return [] }
        return Array(items[..<index])
    }

    open var forwardList: [WKBackForwardListItem] {
        guard let index, index + 1 < items.count else { return [] }
        return Array(items[(index + 1)...])
    }

    open func item(at index: Int) -> WKBackForwardListItem? {
        guard let current = self.index else { return nil }
        let requested = current + index
        guard items.indices.contains(requested) else { return nil }
        return items[requested]
    }
}

@preconcurrency @MainActor
open class WKWindowFeatures: NSObject {}

@preconcurrency @MainActor
open class WKContextMenuElementInfo: NSObject {
    public let linkURL: URL?

    public init(linkURL: URL? = nil) {
        self.linkURL = linkURL
        super.init()
    }
}

@preconcurrency @MainActor
public protocol WKNavigationDelegate: AnyObject {
    func webView(
        _ webView: WKWebView,
        didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation?
    )
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation?)
    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation?)
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation?)
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation?, withError error: Error)
    func webView(
        _ webView: WKWebView,
        didFailProvisionalNavigation navigation: WKNavigation?,
        withError error: Error
    )
    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    )
    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        preferences: WKWebpagePreferences,
        decisionHandler: @escaping (WKNavigationActionPolicy, WKWebpagePreferences) -> Void
    )
    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationResponse: WKNavigationResponse,
        decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void
    )
}

@MainActor
public extension WKNavigationDelegate {
    func webView(
        _ webView: WKWebView,
        didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation?
    ) {}
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation?) {}
    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation?) {}
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation?) {}
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation?, withError error: Error) {}
    func webView(
        _ webView: WKWebView,
        didFailProvisionalNavigation navigation: WKNavigation?,
        withError error: Error
    ) {}
    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) {
        decisionHandler(.allow)
    }
    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        preferences: WKWebpagePreferences,
        decisionHandler: @escaping (WKNavigationActionPolicy, WKWebpagePreferences) -> Void
    ) {
        // Dynamic protocol dispatch reaches a legacy overload implemented by
        // the conformer, exactly what Focus's settings controller relies on.
        self.webView(webView, decidePolicyFor: navigationAction) { policy in
            decisionHandler(policy, preferences)
        }
    }
    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationResponse: WKNavigationResponse,
        decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void
    ) {
        decisionHandler(.allow)
    }
}

@preconcurrency @MainActor
public protocol WKUIDelegate: AnyObject {
    func webView(
        _ webView: WKWebView,
        createWebViewWith configuration: WKWebViewConfiguration,
        for navigationAction: WKNavigationAction,
        windowFeatures: WKWindowFeatures
    ) -> WKWebView?
}

@MainActor
public extension WKUIDelegate {
    func webView(
        _ webView: WKWebView,
        createWebViewWith configuration: WKWebViewConfiguration,
        for navigationAction: WKNavigationAction,
        windowFeatures: WKWindowFeatures
    ) -> WKWebView? {
        nil
    }
}
