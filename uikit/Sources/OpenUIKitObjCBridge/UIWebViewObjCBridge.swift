// UIWebView's Objective-C surface (NJKWebViewProgress, DZNWebViewController).
// An Objective-C `<UIWebViewDelegate>` object is wrapped for OpenUIKit's Swift
// delegate protocol; `-delegate` hands the original object back. Behaviour is
// UIWebView.swift's (measured, podsurfaceprobe "## webview").

#if canImport(ObjectiveC)
import Foundation
import ObjectiveC
import OpenUIKit
import OpenUIKitObjCSupport

private typealias ShouldStartIMP = @convention(c) (NSObject, Selector, NSObject, NSURLRequest, Int) -> Bool
private typealias WebViewIMP = @convention(c) (NSObject, Selector, NSObject) -> Void
private typealias DidFailIMP = @convention(c) (NSObject, Selector, NSObject, NSError) -> Void

/// Forwards OpenUIKit's delegate calls to an Objective-C UIWebViewDelegate,
/// sending only the selectors it implements (the protocol's are optional).
/// Weak, like UIKit's `delegate`.
@MainActor
final class _OUKObjCWebViewDelegate: NSObject, UIWebViewDelegate {
    weak var target: NSObject?
    init(_ target: NSObject) { self.target = target }

    private func send<F>(_ name: String, as: F.Type) -> (NSObject, Selector, F)? {
        let sel = NSSelectorFromString(name)
        guard let t = target, t.responds(to: sel) else { return nil }
        return (t, sel, unsafeBitCast(t.method(for: sel), to: F.self))
    }

    func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest,
                 navigationType: UIWebView.NavigationType) -> Bool {
        guard let (t, sel, f) = send("webView:shouldStartLoadWithRequest:navigationType:",
                                     as: ShouldStartIMP.self) else { return true }
        return f(t, sel, webView, request as NSURLRequest, navigationType.rawValue)
    }
    func webViewDidStartLoad(_ webView: UIWebView) {
        if let (t, sel, f) = send("webViewDidStartLoad:", as: WebViewIMP.self) { f(t, sel, webView) }
    }
    func webViewDidFinishLoad(_ webView: UIWebView) {
        if let (t, sel, f) = send("webViewDidFinishLoad:", as: WebViewIMP.self) { f(t, sel, webView) }
    }
    func webView(_ webView: UIWebView, didFailLoadWithError error: Error) {
        if let (t, sel, f) = send("webView:didFailLoadWithError:", as: DidFailIMP.self) {
            f(t, sel, webView, error as NSError)
        }
    }
}

nonisolated(unsafe) private var webDelegateAdapterKey: UInt8 = 0

extension UIWebView {
    /// The delegate as Objective-C set it (an adapter is kept alongside, the
    /// original object is what `-delegate` returns).
    @objc(delegate) public var __objc_delegate: NSObject? {
        get {
            if let adapter = delegate as? _OUKObjCWebViewDelegate { return adapter.target }
            return delegate as? NSObject
        }
        set {
            guard let newValue else {
                objc_setAssociatedObject(self, &webDelegateAdapterKey, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
                delegate = nil
                return
            }
            if let swift = newValue as? UIWebViewDelegate {
                objc_setAssociatedObject(self, &webDelegateAdapterKey, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
                delegate = swift
                return
            }
            let adapter = _OUKObjCWebViewDelegate(newValue)
            objc_setAssociatedObject(self, &webDelegateAdapterKey, adapter, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            delegate = adapter
        }
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
