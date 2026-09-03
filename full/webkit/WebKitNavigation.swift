@_exported import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

#if canImport(ObjectiveC)
import class ObjectiveC.NSObject
#else
import class Foundation.NSObject
#endif

public enum WKNavigationType: Int, Hashable, Sendable {
    case linkActivated = 0
    case formSubmitted = 1
    case backForward = 2
    case reload = 3
    case formResubmitted = 4
    case other = -1
}

public enum WKNavigationActionPolicy: Int, Hashable, Sendable {
    case cancel = 0
    case allow = 1
    case download = 2
}

public enum WKNavigationResponsePolicy: Int, Hashable, Sendable {
    case cancel = 0
    case allow = 1
    case download = 2
}

@preconcurrency @MainActor
open class WKFrameInfo: NSObject {
    public let isMainFrame: Bool
    public let request: URLRequest
    public let securityOrigin: WKSecurityOrigin
    public weak var webView: WKWebView?

    public init(
        isMainFrame: Bool = true,
        request: URLRequest = URLRequest(url: URL(string: "about:blank")!),
        securityOrigin: WKSecurityOrigin? = nil,
        webView: WKWebView? = nil
    ) {
        self.isMainFrame = isMainFrame
        self.request = request
        self.securityOrigin = securityOrigin ?? WKSecurityOrigin()
        self.webView = webView
        super.init()
    }
}

@preconcurrency @MainActor
open class WKNavigationAction: NSObject {
    public let request: URLRequest
    public let navigationType: WKNavigationType
    public let targetFrame: WKFrameInfo?
    public let sourceFrame: WKFrameInfo
    public let shouldPerformDownload: Bool
    public let isContentRuleListRedirect: Bool

    internal init(
        request: URLRequest,
        navigationType: WKNavigationType,
        targetFrame: WKFrameInfo?,
        sourceFrame: WKFrameInfo? = nil,
        shouldPerformDownload: Bool = false,
        isContentRuleListRedirect: Bool = false
    ) {
        self.request = request
        self.navigationType = navigationType
        self.targetFrame = targetFrame
        self.sourceFrame = sourceFrame ?? targetFrame ?? WKFrameInfo(isMainFrame: true, request: request)
        self.shouldPerformDownload = shouldPerformDownload
        self.isContentRuleListRedirect = isContentRuleListRedirect
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

    internal func _portableContains(_ item: WKBackForwardListItem) -> Bool {
        items.contains { $0 === item }
    }

    /// Truncates the forward list and appends a committed item. History never
    /// grows from a fail-closed `load`; only a recorded commit mutates it.
    internal func _portableRecordCommitted(url: URL, title: String?) {
        if let index {
            items.removeSubrange((index + 1)...)
        }
        items.append(WKBackForwardListItem(url: url, title: title, initialURL: url))
        index = items.count - 1
    }

    internal func _portableState() -> WKBackForwardListState {
        WKBackForwardListState(
            currentURL: currentItem?.url,
            backURLs: backList.map(\.url),
            forwardURLs: forwardList.map(\.url)
        )
    }
}

@preconcurrency @MainActor
open class WKWindowFeatures: NSObject {
    public let menuBarVisibility: NSNumber?
    public let statusBarVisibility: NSNumber?
    public let toolbarsVisibility: NSNumber?
    public let allowsResizing: NSNumber?
    public let x: NSNumber?
    public let y: NSNumber?
    public let width: NSNumber?
    public let height: NSNumber?

    public init(
        menuBarVisibility: NSNumber? = nil,
        statusBarVisibility: NSNumber? = nil,
        toolbarsVisibility: NSNumber? = nil,
        allowsResizing: NSNumber? = nil,
        x: NSNumber? = nil,
        y: NSNumber? = nil,
        width: NSNumber? = nil,
        height: NSNumber? = nil
    ) {
        self.menuBarVisibility = menuBarVisibility
        self.statusBarVisibility = statusBarVisibility
        self.toolbarsVisibility = toolbarsVisibility
        self.allowsResizing = allowsResizing
        self.x = x
        self.y = y
        self.width = width
        self.height = height
        super.init()
    }
}

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
    func webViewWebContentProcessDidTerminate(_ webView: WKWebView)
    func webView(
        _ webView: WKWebView,
        navigationAction: WKNavigationAction,
        didBecome download: WKDownload
    )
    func webView(
        _ webView: WKWebView,
        navigationResponse: WKNavigationResponse,
        didBecome download: WKDownload
    )
    func webView(
        _ webView: WKWebView,
        authenticationChallenge challenge: URLAuthenticationChallenge,
        shouldAllowDeprecatedTLS decisionHandler: @escaping (Bool) -> Void
    )
    func webView(
        _ webView: WKWebView,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
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
    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        _ = webView
    }
    func webView(
        _ webView: WKWebView,
        navigationAction: WKNavigationAction,
        didBecome download: WKDownload
    ) {
        _ = (webView, navigationAction, download)
    }
    func webView(
        _ webView: WKWebView,
        navigationResponse: WKNavigationResponse,
        didBecome download: WKDownload
    ) {
        _ = (webView, navigationResponse, download)
    }
    func webView(
        _ webView: WKWebView,
        authenticationChallenge challenge: URLAuthenticationChallenge,
        shouldAllowDeprecatedTLS decisionHandler: @escaping (Bool) -> Void
    ) {
        _ = (webView, challenge)
        decisionHandler(false)
    }
    func webView(
        _ webView: WKWebView,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        _ = (webView, challenge)
        completionHandler(.cancelAuthenticationChallenge, nil)
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
    func webViewDidClose(_ webView: WKWebView)
    func webView(
        _ webView: WKWebView,
        runJavaScriptAlertPanelWithMessage message: String,
        initiatedByFrame frame: WKFrameInfo
    ) async
    func webView(
        _ webView: WKWebView,
        runJavaScriptConfirmPanelWithMessage message: String,
        initiatedByFrame frame: WKFrameInfo
    ) async -> Bool
    func webView(
        _ webView: WKWebView,
        runJavaScriptTextInputPanelWithPrompt prompt: String,
        defaultText: String?,
        initiatedByFrame frame: WKFrameInfo
    ) async -> String?
    func webView(
        _ webView: WKWebView,
        requestDeviceOrientationAndMotionPermissionFor origin: WKSecurityOrigin,
        initiatedByFrame frame: WKFrameInfo,
        decisionHandler: @escaping (WKPermissionDecision) -> Void
    )
    func webView(
        _ webView: WKWebView,
        decideMediaCapturePermissionsFor origin: WKSecurityOrigin,
        initiatedBy frame: WKFrameInfo,
        type: WKMediaCaptureType
    ) async -> WKPermissionDecision
    func webView(
        _ webView: WKWebView,
        showLockdownModeFirstUseMessage message: String
    ) async -> WKDialogResult
    func webView(
        _ webView: WKWebView,
        runOpenPanelWith parameters: WKOpenPanelParameters,
        initiatedByFrame frame: WKFrameInfo
    ) async -> [URL]?
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
    func webViewDidClose(_ webView: WKWebView) {
        _ = webView
    }
    func webView(
        _ webView: WKWebView,
        runJavaScriptAlertPanelWithMessage message: String,
        initiatedByFrame frame: WKFrameInfo
    ) async {
        _ = (webView, message, frame)
    }
    func webView(
        _ webView: WKWebView,
        runJavaScriptConfirmPanelWithMessage message: String,
        initiatedByFrame frame: WKFrameInfo
    ) async -> Bool {
        _ = (webView, message, frame)
        return false
    }
    func webView(
        _ webView: WKWebView,
        runJavaScriptTextInputPanelWithPrompt prompt: String,
        defaultText: String?,
        initiatedByFrame frame: WKFrameInfo
    ) async -> String? {
        _ = (webView, prompt, defaultText, frame)
        return nil
    }
    func webView(
        _ webView: WKWebView,
        requestDeviceOrientationAndMotionPermissionFor origin: WKSecurityOrigin,
        initiatedByFrame frame: WKFrameInfo,
        decisionHandler: @escaping (WKPermissionDecision) -> Void
    ) {
        _ = (webView, origin, frame)
        decisionHandler(.deny)
    }
    func webView(
        _ webView: WKWebView,
        decideMediaCapturePermissionsFor origin: WKSecurityOrigin,
        initiatedBy frame: WKFrameInfo,
        type: WKMediaCaptureType
    ) async -> WKPermissionDecision {
        _ = (webView, origin, frame, type)
        return .deny
    }
    func webView(
        _ webView: WKWebView,
        showLockdownModeFirstUseMessage message: String
    ) async -> WKDialogResult {
        _ = (webView, message)
        return .showDefault
    }
    func webView(
        _ webView: WKWebView,
        runOpenPanelWith parameters: WKOpenPanelParameters,
        initiatedByFrame frame: WKFrameInfo
    ) async -> [URL]? {
        _ = (webView, parameters, frame)
        return nil
    }
}
