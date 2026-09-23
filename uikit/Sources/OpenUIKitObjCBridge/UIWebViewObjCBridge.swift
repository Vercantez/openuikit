// UIWebView's Objective-C surface (NJKWebViewProgress, DZNWebViewController).
// UIWebViewDelegate is OpenUIKit's own @objc protocol, so an Objective-C
// delegate is stored as is. Behaviour is UIWebView.swift's (measured,
// podsurfaceprobe "## webview").

#if canImport(ObjectiveC)
import Foundation
import ObjectiveC
import OpenUIKit
import OpenUIKitObjCSupport

extension UIWebView {
    /// `id<UIWebViewDelegate>`: OpenUIKit's own @objc protocol.
    @objc(delegate) public var __objc_delegate: UIWebViewDelegate? {
        get { delegate } set { delegate = newValue }
    }
    @objc(scrollView) public var __objc_scrollView: UIScrollView { scrollView }
    @objc(request) public var __objc_request: URLRequest? { request }
    @objc(isLoading) public var __objc_isLoading: Bool { isLoading }
    @objc(loading) public var __objc_loading: Bool { isLoading }
    @objc(canGoBack) public var __objc_canGoBack: Bool { canGoBack }
    @objc(canGoForward) public var __objc_canGoForward: Bool { canGoForward }
    @objc(scalesPageToFit) public var __objc_scalesPageToFit: Bool {
        get { scalesPageToFit } set { scalesPageToFit = newValue }
    }
    @objc(loadRequest:) public func __objc_loadRequest(_ request: URLRequest) { loadRequest(request) }
    @objc(loadHTMLString:baseURL:) public func __objc_loadHTMLString(_ string: String, baseURL: URL?) {
        loadHTMLString(string, baseURL: baseURL)
    }
    @objc(stringByEvaluatingJavaScriptFromString:)
    public func __objc_stringByEvaluatingJavaScript(from script: String) -> String? {
        stringByEvaluatingJavaScript(from: script)
    }
    @objc(reload) public func __objc_reload() { reload() }
    @objc(stopLoading) public func __objc_stopLoading() { stopLoading() }
    @objc(goBack) public func __objc_goBack() { goBack() }
    @objc(goForward) public func __objc_goForward() { goForward() }
}
#endif
