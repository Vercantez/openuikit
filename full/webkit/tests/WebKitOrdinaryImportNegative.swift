import WebKit

/// Ordinary-import client. Host-only control seams must stay invisible.
@MainActor
func proveHostSeamsStayHidden(webView: WKWebView, configuration: WKWebViewConfiguration) {
    _ = WebKitHostControl.lastError(on: webView)
    _ = WebKitHostControl.backForwardState(of: webView)
    WebKitHostControl.recordCommittedItem(
        on: webView,
        url: URL(string: "https://should-not-compile.invalid/")!
    )
    _ = webView._portableLastError
    _ = configuration._portableCopyForWebView()
    _ = webView.backForwardList._portableState()
}
