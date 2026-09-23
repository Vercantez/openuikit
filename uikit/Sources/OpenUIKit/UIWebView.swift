// UIWebView — deprecated (iOS 12), still declared by the iOS 26.1 SDK and
// still functional in its runtime. Eidolon's AppDelegate builds one to read
// `navigator.userAgent`, its WebViewController subclasses
// DZNWebViewController, and NJKWebViewProgress proxies its delegate.
//
// MEASURED iOS 26.1 (Tools/oracle2/podsurfaceprobe "## webview"):
//   * a UIView subclass whose scrollView is a UIScrollView filling it;
//   * nil delegate / request, not loading, cannot go back or forward,
//     scalesPageToFit NO; UIWebViewNavigationType LinkClicked 0 … Other 5;
//   * -loadHTMLString:baseURL: (nil base) changes nothing in the same turn;
//     later the delegate sees shouldStartLoad(about:blank, Other, main
//     document about:blank), then didStartLoad with `loading` YES, then
//     didFinishLoad with `loading` NO; `request` is then about:blank.
//
// NOT implemented, and fail-closed: OpenUIKit has no web engine and no
// JavaScript. `stringByEvaluatingJavaScript(from:)` returns nil (iOS returns
// the script's result, e.g. the user agent), HTML is not rendered, and
// `loadRequest(_:)` records the request but never starts a load — no
// delegate callback claims a page arrived.

// Apple toolchains only: URLRequest lives in FoundationNetworking on Linux,
// which OpenUIKit does not link; the Foundation-hidden guest has no URLRequest.
#if canImport(Foundation) && canImport(ObjectiveC)
import Foundation

/// UIKit's @objc protocol (objc-protocols.md shape): SDK selectors, all
/// optional; OpenUIKit calls it through the helpers at the end of this file.
@objc(UIWebViewDelegate) @preconcurrency @MainActor
public protocol UIWebViewDelegate: NSObjectProtocol {
    @objc(webView:shouldStartLoadWithRequest:navigationType:)
    optional func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest,
                          navigationType: UIWebView.NavigationType) -> Bool
    @objc(webViewDidStartLoad:)
    optional func webViewDidStartLoad(_ webView: UIWebView)
    @objc(webViewDidFinishLoad:)
    optional func webViewDidFinishLoad(_ webView: UIWebView)
    @objc(webView:didFailLoadWithError:)
    optional func webView(_ webView: UIWebView, didFailLoadWithError error: Error)
}

@available(iOS, deprecated: 12.0, message: "No longer supported; please adopt WKWebView.")
@preconcurrency @MainActor
open class UIWebView: UIView {
    @objc(UIWebViewNavigationType)
    public enum NavigationType: Int, Sendable {
        case linkClicked = 0, formSubmitted, backForward, reload, formResubmitted, other
    }

    public weak var delegate: UIWebViewDelegate?
    public let scrollView: UIScrollView
    public private(set) var request: URLRequest?
    public private(set) var isLoading = false
    public private(set) var canGoBack = false
    public private(set) var canGoForward = false
    public var scalesPageToFit = false

    public override init(frame: CGRect) {
        scrollView = UIScrollView(frame: CGRect(origin: .zero, size: frame.size))
        super.init(frame: frame)
        scrollView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(scrollView)
    }

    public required init?(coder: NSCoder) {
        scrollView = UIScrollView(frame: .zero)
        super.init(coder: coder)
        scrollView.frame = bounds
        scrollView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(scrollView)
    }

    /// No web engine: records the request, starts nothing (see the header).
    open func loadRequest(_ request: URLRequest) {
        self.request = request
    }

    /// The measured about:blank sequence for a nil base URL; the markup is
    /// not rendered. A non-nil base URL is not measured and loads nothing.
    open func loadHTMLString(_ string: String, baseURL: URL?) {
        guard baseURL == nil, let blank = URL(string: "about:blank") else { return }
        var request = URLRequest(url: blank)
        request.mainDocumentURL = blank
        _UIWebViewTurn.later { [weak self] in
            guard let self else { return }
            if let delegate = self.delegate,
               !(delegate.webView?(self, shouldStartLoadWith: request, navigationType: .other) ?? true) { return }
            self.isLoading = true
            self.delegate?.webViewDidStartLoad?(self)
            _UIWebViewTurn.later { [weak self] in
                guard let self else { return }
                self.request = request
                self.isLoading = false
                self.delegate?.webViewDidFinishLoad?(self)
            }
        }
    }

    /// No JavaScript engine: nil for every script (iOS evaluates it).
    open func stringByEvaluatingJavaScript(from script: String) -> String? { nil }

    open func reload() {}
    open func stopLoading() { isLoading = false }
    open func goBack() {}
    open func goForward() {}
}

/// The next main-queue turn (the measured callbacks are not synchronous).
enum _UIWebViewTurn {
    static func later(_ work: @escaping @MainActor () -> Void) {
        DispatchQueue.main.async { MainActor.assumeIsolated { work() } }
    }
}
#endif
