import Foundation
import UIKit
import WebKit

@MainActor
private final class NativeDelegate: NSObject, WKNavigationDelegate, WKUIDelegate,
    WKScriptMessageHandler
{
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
        decisionHandler: @escaping (
            WKNavigationActionPolicy, WKWebpagePreferences
        ) -> Void
    ) {
        decisionHandler(.allow, preferences)
    }

    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationResponse: WKNavigationResponse,
        decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void
    ) {
        decisionHandler(.allow)
    }

    func webView(
        _ webView: WKWebView,
        createWebViewWith configuration: WKWebViewConfiguration,
        for navigationAction: WKNavigationAction,
        windowFeatures: WKWindowFeatures
    ) -> WKWebView? {
        nil
    }

    func userContentController(
        _ userContentController: WKUserContentController,
        didReceive message: WKScriptMessage
    ) {}
}

// Compiling this function against the pinned SDK is the signature oracle for
// Focus's WebKit-facing calls. It is intentionally never run: the runtime
// oracle below must not start network or renderer work.
@MainActor
private func compileFocusSurface(
    webView: WKWebView,
    request: URLRequest,
    data: Data,
    rule: WKContentRuleList,
    delegate: NativeDelegate
) {
    webView.navigationDelegate = delegate
    webView.uiDelegate = delegate
    webView.configuration.userContentController.add(rule)
    webView.configuration.userContentController.removeAllContentRuleLists()
    webView.configuration.userContentController.addUserScript(
        WKUserScript(
            source: "true",
            injectionTime: .atDocumentStart,
            forMainFrameOnly: true
        )
    )
    webView.configuration.userContentController.add(delegate, name: "native")
    webView.configuration.userContentController.removeScriptMessageHandler(
        forName: "native"
    )
    _ = webView.load(request)
    _ = webView.load(
        data,
        mimeType: "text/plain",
        characterEncodingName: "utf-8",
        baseURL: request.url!
    )
    _ = webView.reload()
    _ = webView.reloadFromOrigin()
    _ = webView.goBack()
    _ = webView.goForward()
    webView.stopLoading()
    webView.evaluateJavaScript("true") { _, _ in }
    _ = webView.url
    _ = webView.title
    _ = webView.hasOnlySecureContent
    _ = webView.estimatedProgress
    _ = webView.isLoading
    _ = webView.canGoBack
    _ = webView.canGoForward
    _ = webView.backForwardList.currentItem
    _ = webView.backForwardList.backList
    _ = webView.backForwardList.forwardList
    _ = webView.scrollView
    webView.setAllMediaPlaybackSuspended(true) {}
    var obscuredContentInsets = webView.obscuredContentInsets
    obscuredContentInsets.bottom = 24
    webView.obscuredContentInsets = obscuredContentInsets
    webView.underPageBackgroundColor = .clear
    _ = webView.underPageBackgroundColor
    let observations: [NSKeyValueObservation] = [
        webView.observe(\.url, options: [.initial, .old, .new]) { _, _ in },
        webView.observe(\.title, options: [.new]) { _, _ in },
        webView.observe(\.canGoBack, options: [.new]) { _, _ in },
        webView.observe(\.canGoForward, options: [.new]) { _, _ in },
        webView.observe(\.isLoading, options: [.new]) { _, _ in },
        webView.observe(
            \.underPageBackgroundColor,
            options: [.initial, .new]
        ) { _, _ in },
    ]
    withExtendedLifetime(observations) {}
}

@main
private struct WebKitNativeOracle {
    @MainActor
    static func main() {
        let persistentA = WKWebsiteDataStore.default()
        let persistentB = WKWebsiteDataStore.default()
        let ephemeralA = WKWebsiteDataStore.nonPersistent()
        let ephemeralB = WKWebsiteDataStore.nonPersistent()
        print("data.default-singleton=\(persistentA === persistentB)")
        print("data.nonpersistent-distinct=\(ephemeralA !== ephemeralB)")
        print("data.nonpersistent-is-persistent=\(ephemeralA.isPersistent)")

        let configuration = WKWebViewConfiguration()
        print("configuration.inline=\(configuration.allowsInlineMediaPlayback)")
        print(
            "configuration.application-name="
                + (configuration.applicationNameForUserAgent ?? "nil")
        )
        print("configuration.https-upgrade=\(configuration.upgradeKnownHostsToHTTPS)")
        print("configuration.viewport-ignore=\(configuration.ignoresViewportScaleLimits)")
        print("preferences.minimum-font=\(configuration.preferences.minimumFontSize)")
        print(
            "preferences.js-windows="
                + "\(configuration.preferences.javaScriptCanOpenWindowsAutomatically)"
        )

        let webView = WKWebView(
            frame: CGRect(x: 11, y: 12, width: 320, height: 480),
            configuration: configuration
        )
        print("web.configuration-shell-copied=\(webView.configuration !== configuration)")
        print(
            "web.preferences-shared="
                + "\(webView.configuration.preferences === configuration.preferences)"
        )
        print(
            "web.controller-shared="
                + "\(webView.configuration.userContentController === configuration.userContentController)"
        )
        print(
            "web.data-store-shared="
                + "\(webView.configuration.websiteDataStore === configuration.websiteDataStore)"
        )
        print("web.url=\(webView.url?.absoluteString ?? "nil")")
        print("web.title=\(webView.title ?? "nil")")
        print("web.progress=\(webView.estimatedProgress)")
        print("web.loading=\(webView.isLoading)")
        print("web.back=\(webView.canGoBack)")
        print("web.forward=\(webView.canGoForward)")
        print("web.secure=\(webView.hasOnlySecureContent)")
        print("web.history-current=\(webView.backForwardList.currentItem == nil ? "nil" : "set")")
        print("web.history-back-count=\(webView.backForwardList.backList.count)")
        print("web.history-forward-count=\(webView.backForwardList.forwardList.count)")
        print(
            "web.frame=\(Int(webView.frame.origin.x)),\(Int(webView.frame.origin.y)),"
                + "\(Int(webView.frame.width)),\(Int(webView.frame.height))"
        )
        print(
            "web.scroll-frame=\(Int(webView.scrollView.frame.origin.x)),"
                + "\(Int(webView.scrollView.frame.origin.y)),"
                + "\(Int(webView.scrollView.frame.width)),"
                + "\(Int(webView.scrollView.frame.height))"
        )
        print("web.gestures=\(webView.allowsBackForwardNavigationGestures)")
        print("web.link-preview=\(webView.allowsLinkPreview)")
        print("web.custom-user-agent=\(webView.customUserAgent ?? "nil")")
        print(
            "enum.action=\(WKNavigationActionPolicy.cancel.rawValue),"
                + "\(WKNavigationActionPolicy.allow.rawValue),"
                + "\(WKNavigationActionPolicy.download.rawValue)"
        )
        print(
            "enum.response=\(WKNavigationResponsePolicy.cancel.rawValue),"
                + "\(WKNavigationResponsePolicy.allow.rawValue),"
                + "\(WKNavigationResponsePolicy.download.rawValue)"
        )
        print(
            "enum.navigation=\(WKNavigationType.linkActivated.rawValue),"
                + "\(WKNavigationType.formSubmitted.rawValue),"
                + "\(WKNavigationType.backForward.rawValue),"
                + "\(WKNavigationType.reload.rawValue),"
                + "\(WKNavigationType.formResubmitted.rawValue),"
                + "\(WKNavigationType.other.rawValue)"
        )
        print(
            "enum.content-mode=\(WKWebpagePreferences.ContentMode.recommended.rawValue),"
                + "\(WKWebpagePreferences.ContentMode.mobile.rawValue),"
                + "\(WKWebpagePreferences.ContentMode.desktop.rawValue)"
        )
    }
}
