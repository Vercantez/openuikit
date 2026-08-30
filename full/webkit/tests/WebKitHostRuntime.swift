import WebKit

@MainActor
private final class ScriptHandler: WKScriptMessageHandler {
    func userContentController(
        _ userContentController: WKUserContentController,
        didReceive message: WKScriptMessage
    ) {
        fatalError("a WebKit configuration shell must never invent script delivery")
    }
}

@MainActor
private final class AllowingDelegate: WKNavigationDelegate {
    var policies = 0
    var starts = 0
    var provisionalFailures = 0
    var commits = 0
    var finishes = 0
    var lastError: WKPortableError?

    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        preferences: WKWebpagePreferences,
        decisionHandler: @escaping (
            WKNavigationActionPolicy, WKWebpagePreferences
        ) -> Void
    ) {
        policies += 1
        precondition(navigationAction.request.url?.absoluteString == "https://example.invalid/")
        preferences.preferredContentMode = .desktop
        decisionHandler(.allow, preferences)
    }

    func webView(
        _ webView: WKWebView,
        didStartProvisionalNavigation navigation: WKNavigation?
    ) {
        starts += 1
        precondition(navigation?.effectiveContentMode == .desktop)
    }

    func webView(
        _ webView: WKWebView,
        didFailProvisionalNavigation navigation: WKNavigation?,
        withError error: Error
    ) {
        provisionalFailures += 1
        lastError = error as? WKPortableError
    }

    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation?) {
        commits += 1
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation?) {
        finishes += 1
    }
}

@MainActor
private final class CancellingDelegate: WKNavigationDelegate {
    var policies = 0
    var starts = 0
    var failures = 0

    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        preferences: WKWebpagePreferences,
        decisionHandler: @escaping (
            WKNavigationActionPolicy, WKWebpagePreferences
        ) -> Void
    ) {
        policies += 1
        decisionHandler(.cancel, preferences)
    }

    func webView(
        _ webView: WKWebView,
        didStartProvisionalNavigation navigation: WKNavigation?
    ) {
        starts += 1
    }

    func webView(
        _ webView: WKWebView,
        didFailProvisionalNavigation navigation: WKNavigation?,
        withError error: Error
    ) {
        failures += 1
    }
}

@MainActor
private final class LegacyDelegate: WKNavigationDelegate {
    var policies = 0

    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) {
        policies += 1
        decisionHandler(.cancel)
    }
}

@MainActor
private final class ErrorPageDelegate: WKNavigationDelegate {
    var starts = 0
    var failures = 0

    func webView(
        _ webView: WKWebView,
        didStartProvisionalNavigation navigation: WKNavigation?
    ) {
        starts += 1
    }

    func webView(
        _ webView: WKWebView,
        didFailProvisionalNavigation navigation: WKNavigation?,
        withError error: Error
    ) {
        failures += 1
        _ = webView.load(
            Data("portable error".utf8),
            mimeType: "text/plain",
            characterEncodingName: "utf-8",
            baseURL: URL(string: "about:portable-error")!
        )
    }
}

@main
private struct WebKitHostRuntime {
    @MainActor
    static func main() {
        precondition(WKWebsiteDataStore.default() === WKWebsiteDataStore.default())
        let ephemeral = WKWebsiteDataStore.nonPersistent()
        precondition(!ephemeral.isPersistent)
        precondition(ephemeral !== WKWebsiteDataStore.nonPersistent())
        var erased = 0
        ephemeral.removeData(
            ofTypes: WKWebsiteDataStore.allWebsiteDataTypes(),
            modifiedSince: Date(timeIntervalSince1970: 0)
        ) { erased += 1 }
        precondition(erased == 1)

        let configuration = WKWebViewConfiguration()
        precondition(configuration.allowsInlineMediaPlayback == false)
        precondition(configuration.applicationNameForUserAgent == "Mobile/15E148")
        precondition(configuration.upgradeKnownHostsToHTTPS)
        precondition(configuration.preferences.minimumFontSize == 0)
        precondition(!configuration.preferences.javaScriptCanOpenWindowsAutomatically)

        let controller = configuration.userContentController
        let script = WKUserScript(
            source: "window.portable = true",
            injectionTime: .atDocumentStart,
            forMainFrameOnly: true
        )
        controller.addUserScript(script)
        precondition(controller.userScripts.count == 1)
        precondition(controller.userScripts[0] === script)
        let handler = ScriptHandler()
        controller.add(handler, name: "portable")
        precondition(controller.registeredScriptMessageHandlerNames == ["portable"])
        controller.removeScriptMessageHandler(forName: "portable")
        precondition(controller.registeredScriptMessageHandlerNames.isEmpty)

        let store = WKContentRuleListStore.default()
        let rules = #"[{"trigger":{"url-filter":".*"},"action":{"type":"block"}}]"#
        var compiled: WKContentRuleList?
        var compileError: Error?
        store.compileContentRuleList(
            forIdentifier: "portable",
            encodedContentRuleList: rules
        ) { compiled = $0; compileError = $1 }
        precondition(compiled?.identifier == "portable")
        precondition(compileError == nil)
        var lookedUp: WKContentRuleList?
        store.lookUpContentRuleList(forIdentifier: "portable") {
            lookedUp = $0
            precondition($1 == nil)
        }
        precondition(lookedUp === compiled)
        var identifiers: [String]?
        store.getAvailableContentRuleListIdentifiers { identifiers = $0 }
        precondition(identifiers == ["portable"])
        var invalidError: WKPortableError?
        store.compileContentRuleList(
            forIdentifier: "broken",
            encodedContentRuleList: #"[{"trigger":{}}]"#
        ) { list, error in
            precondition(list == nil)
            invalidError = error as? WKPortableError
        }
        precondition(invalidError?.code == .invalidContentRuleList)
        store.removeContentRuleList(forIdentifier: "portable") {
            precondition($0 == nil)
        }

        let webView = WKWebView(
            frame: CGRect(x: 11, y: 12, width: 320, height: 480),
            configuration: configuration
        )
        precondition(webView.configuration !== configuration)
        precondition(webView.configuration.preferences === configuration.preferences)
        precondition(webView.configuration.userContentController === controller)
        precondition(webView.configuration.websiteDataStore === configuration.websiteDataStore)
        precondition(webView.frame == CGRect(x: 11, y: 12, width: 320, height: 480))
        precondition(webView.scrollView.frame == CGRect(x: 0, y: 0, width: 320, height: 480))
        precondition(webView.url == nil)
        precondition(webView.title == "")
        precondition(webView.estimatedProgress == 0)
        precondition(!webView.isLoading && !webView.canGoBack && !webView.canGoForward)
        precondition(!webView.hasOnlySecureContent)
        precondition(webView.allowsLinkPreview)
        precondition(webView.customUserAgent == "")

        let allowing = AllowingDelegate()
        webView.navigationDelegate = allowing
        let navigation = webView.load(
            URLRequest(url: URL(string: "https://example.invalid/")!)
        )
        precondition(navigation != nil)
        precondition(navigation?.effectiveContentMode == .desktop)
        precondition(allowing.policies == 1)
        precondition(allowing.starts == 1 && allowing.provisionalFailures == 1)
        precondition(allowing.commits == 0 && allowing.finishes == 0)
        precondition(allowing.lastError?.code == .engineUnavailable)
        precondition(webView.lastPortableError?.code == .engineUnavailable)
        precondition(!webView.isLoading && webView.backForwardList.currentItem == nil)

        var javaScriptCallbacks = 0
        webView.evaluateJavaScript("document.title") { value, error in
            javaScriptCallbacks += 1
            precondition(value == nil)
            precondition((error as? WKPortableError)?.code == .engineUnavailable)
        }
        precondition(javaScriptCallbacks == 1)

        let cancelled = WKWebView(frame: .zero)
        let cancelling = CancellingDelegate()
        cancelled.navigationDelegate = cancelling
        _ = cancelled.load(URLRequest(url: URL(string: "https://cancel.invalid/")!))
        precondition(cancelling.policies == 1)
        precondition(cancelling.starts == 0 && cancelling.failures == 0)
        precondition(cancelled.url == nil && cancelled.lastPortableError == nil)

        let legacyView = WKWebView(frame: .zero)
        let legacy = LegacyDelegate()
        legacyView.navigationDelegate = legacy
        _ = legacyView.load(URLRequest(url: URL(string: "https://legacy.invalid/")!))
        precondition(legacy.policies == 1)
        precondition(legacyView.url == nil && legacyView.lastPortableError == nil)

        let errorPageView = WKWebView(frame: .zero)
        let errorPage = ErrorPageDelegate()
        errorPageView.navigationDelegate = errorPage
        _ = errorPageView.load(
            URLRequest(url: URL(string: "https://error-page.invalid/")!)
        )
        precondition(errorPage.starts == 1 && errorPage.failures == 1)
        precondition(errorPageView.lastPortableError?.code == .engineUnavailable)
        precondition(errorPageView.url?.absoluteString == "about:portable-error")
        precondition(!errorPageView.isLoading)

        print(
            "WEBKIT_HOST_RUNTIME_OK "
                + "configuration=copied state=retained policies=honored "
                + "navigation=engine-unavailable rendering=absent"
        )
    }
}
