import Foundation
import WebKit

private func wkMain<T>(_ body: @escaping @MainActor () throws -> T) -> T {
    // The sealed runner invokes tests from process-main `main.swift`. That
    // thread is the MainActor executor on this Linux host; hopping with
    // Task + wait deadlocks because the waiter occupies the same executor.
    do {
        return try MainActor.assumeIsolated {
            try body()
        }
    } catch {
        fatalError("WebKit agent test failed: \(error)")
    }
}

func testWKErrorDomainAndCodes() {
    precondition(WKErrorDomain == "WKErrorDomain")
    precondition(WKError.errorDomain == WKErrorDomain)
    precondition(WKError.Code.unknown.rawValue == 1)
    precondition(WKError.Code.webContentProcessTerminated.rawValue == 2)
    precondition(WKError.Code.webViewInvalidated.rawValue == 3)
    precondition(WKError.Code.javaScriptExceptionOccurred.rawValue == 4)
    precondition(WKError.Code.javaScriptResultTypeIsUnsupported.rawValue == 5)
    precondition(WKError.Code.contentRuleListStoreCompileFailed.rawValue == 6)
    precondition(WKError.Code.contentRuleListStoreLookUpFailed.rawValue == 7)
    precondition(WKError.Code.contentRuleListStoreRemoveFailed.rawValue == 8)
    precondition(WKError.Code.contentRuleListStoreVersionMismatch.rawValue == 9)
    precondition(WKError.Code.attributedStringContentFailedToLoad.rawValue == 10)
    precondition(WKError.Code.attributedStringContentLoadTimedOut.rawValue == 11)
    precondition(WKError.Code.javaScriptInvalidFrameTarget.rawValue == 12)
    precondition(WKError.Code.navigationAppBoundDomain.rawValue == 13)
    precondition(WKError.Code.javaScriptAppBoundDomain.rawValue == 14)
    precondition(WKError.Code.duplicateCredential.rawValue == 15)
    precondition(WKError.Code.malformedCredential.rawValue == 16)
    precondition(WKError.Code.credentialNotFound.rawValue == 17)
    let error = WKError(code: .unknown, operation: "probe")
    precondition(error.errorCode == 1)
    precondition(error.localizedDescription.contains("WKErrorDomain"))
    precondition(WKError.unknown ~= error)
}

func testWebsiteDataStoreEraseCompletes() {
    wkMain {
        precondition(WKWebsiteDataStore.default() === WKWebsiteDataStore.default())
        let ephemeral = WKWebsiteDataStore.nonPersistent()
        precondition(!ephemeral.isPersistent)
        var erased = 0
        ephemeral.removeData(
            ofTypes: WKWebsiteDataStore.allWebsiteDataTypes(),
            modifiedSince: Date(timeIntervalSince1970: 0)
        ) { erased += 1 }
        precondition(erased == 1)
        precondition(WKWebsiteDataTypeCookies == "WKWebsiteDataTypeCookies")
        precondition(WKWebsiteDataTypeHashSalt == "WKWebsiteDataTypeHashSalt")
    }
}

func testContentRuleListCompileAndLookup() {
    wkMain {
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
        var invalidError: WKError?
        store.compileContentRuleList(
            forIdentifier: "broken",
            encodedContentRuleList: #"[{"trigger":{}}]"#
        ) { list, error in
            precondition(list == nil)
            invalidError = error as? WKError
        }
        precondition(invalidError?.code == .contentRuleListStoreCompileFailed)
        var missingError: WKError?
        store.lookUpContentRuleList(forIdentifier: "absent") { list, error in
            precondition(list == nil)
            missingError = error as? WKError
        }
        precondition(missingError?.code == .contentRuleListStoreLookUpFailed)
        store.removeContentRuleList(forIdentifier: "portable") {
            precondition($0 == nil)
        }
    }
}

@MainActor
private final class AllowingDelegate: WKNavigationDelegate {
    var policies = 0
    var starts = 0
    var provisionalFailures = 0
    var commits = 0
    var finishes = 0
    var lastError: WKError?

    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        preferences: WKWebpagePreferences,
        decisionHandler: @escaping (WKNavigationActionPolicy, WKWebpagePreferences) -> Void
    ) {
        policies += 1
        preferences.preferredContentMode = .desktop
        decisionHandler(.allow, preferences)
    }

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation?) {
        starts += 1
        precondition(navigation?.effectiveContentMode == .desktop)
    }

    func webView(
        _ webView: WKWebView,
        didFailProvisionalNavigation navigation: WKNavigation?,
        withError error: Error
    ) {
        provisionalFailures += 1
        lastError = error as? WKError
    }

    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation?) { commits += 1 }
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation?) { finishes += 1 }
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
        decisionHandler: @escaping (WKNavigationActionPolicy, WKWebpagePreferences) -> Void
    ) {
        policies += 1
        decisionHandler(.cancel, preferences)
    }

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation?) {
        starts += 1
    }

    func webView(
        _ webView: WKWebView,
        didFailProvisionalNavigation navigation: WKNavigation?,
        withError error: Error
    ) {
        _ = error
        failures += 1
    }
}

func testLoadFailsClosedWithoutCommit() {
    wkMain {
        let configuration = WKWebViewConfiguration()
        precondition(configuration.allowsInlineMediaPlayback == false)
        precondition(configuration.applicationNameForUserAgent == "Mobile/15E148")
        precondition(configuration.upgradeKnownHostsToHTTPS)
        let webView = WKWebView(frame: CGRect(x: 0, y: 0, width: 320, height: 480), configuration: configuration)
        precondition(webView.configuration !== configuration)
        precondition(webView.configuration.preferences === configuration.preferences)
        let allowing = AllowingDelegate()
        webView.navigationDelegate = allowing
        let navigation = webView.load(URLRequest(url: URL(string: "https://example.invalid/")!))
        precondition(navigation != nil)
        precondition(navigation?.effectiveContentMode == .desktop)
        precondition(allowing.policies == 1)
        precondition(allowing.starts == 1 && allowing.provisionalFailures == 1)
        precondition(allowing.commits == 0 && allowing.finishes == 0)
        precondition(allowing.lastError?.code == .unknown)
        precondition(!webView.isLoading)
        precondition(webView.backForwardList.currentItem == nil)
        var js = 0
        webView.evaluateJavaScript("document.title") { value, error in
            js += 1
            precondition(value == nil)
            precondition((error as? WKError)?.code == .unknown)
        }
        precondition(js == 1)
    }
}

func testNavigationCancelDoesNotStart() {
    wkMain {
        let cancelled = WKWebView(frame: .zero)
        let cancelling = CancellingDelegate()
        cancelled.navigationDelegate = cancelling
        _ = cancelled.load(URLRequest(url: URL(string: "https://cancel.invalid/")!))
        precondition(cancelling.policies == 1)
        precondition(cancelling.starts == 0 && cancelling.failures == 0)
        precondition(cancelled.url == nil)
    }
}

func testUserContentControllerRegistration() {
    wkMain {
        let controller = WKUserContentController()
        let script = WKUserScript(
            source: "window.portable = true",
            injectionTime: .atDocumentStart,
            forMainFrameOnly: true
        )
        controller.addUserScript(script)
        precondition(controller.userScripts.count == 1)
        precondition(WKUserScriptInjectionTime.atDocumentStart.rawValue == 0)
        precondition(WKUserScriptInjectionTime.atDocumentEnd.rawValue == 1)
    }
}

func testOptionSetRawValues() {
    precondition(WKAudiovisualMediaTypes.audio.rawValue == 1)
    precondition(WKAudiovisualMediaTypes.video.rawValue == 2)
    precondition(WKAudiovisualMediaTypes.all.contains(.audio))
    precondition(WKDataDetectorTypes.phoneNumber.rawValue == 1)
    precondition(WKDataDetectorTypes.link.rawValue == 2)
    precondition(WKDataDetectorTypes.spotlightSuggestion == .lookupSuggestion)
    precondition(WKWebViewDataType.sessionStorage.rawValue == 1)
    precondition(WKMediaPlaybackState.none.rawValue == 0)
    precondition(WKMediaCaptureState.muted.rawValue == 2)
    precondition(WKPermissionDecision.prompt.rawValue == 0)
    precondition(WKDialogResult.showDefault.rawValue == 1)
    precondition(WKSelectionGranularity.dynamic.rawValue == 0)
}

func testURLSchemeParsing() {
    wkMain {
        let https = URLScheme("HTTPS")
        precondition(https?.rawValue == "https")
        precondition(URLScheme("") == nil)
        precondition(https != URLScheme("http"))
        precondition(URLScheme(rawValue: "HTTPS")?.rawValue == "https")
    }
}

func testWebExtensionFailClosed() {
    wkMain {
        let ext = WKWebExtension()
        precondition(!ext.errors.isEmpty)
        precondition(WKWebExtension.Error.Code.unknown.rawValue == 1)
        precondition(WKWebExtension.Error.Code.resourceNotFound.rawValue == 2)
        precondition(WKWebExtension.Permission.storage.rawValue == "storage")
        let pattern = WKWebExtension.MatchPattern(string: "*://example.com/*")
        precondition(pattern?.host == "example.com")
        let context = WKWebExtensionContext(for: ext)
        precondition(!context.isLoaded)
        precondition(!context.hasPermission(.tabs))
        let controller = WKWebExtensionController()
        do {
            try controller.load(context)
        } catch {
            fatalError("unexpected load error \(error)")
        }
    }
}

func testPreferencesAppleOverlayNames() {
    wkMain {
        let prefs = WKPreferences()
        precondition(prefs.minimumFontSize == 0)
        precondition(!prefs.javaScriptCanOpenWindowsAutomatically)
        precondition(prefs.isFraudulentWebsiteWarningEnabled)
        precondition(prefs.isTextInteractionEnabled)
        prefs.isElementFullscreenEnabled = true
        precondition(prefs.elementFullscreenEnabled)
        precondition(prefs.inactiveSchedulingPolicy == .suspend)
        let page = WKWebpagePreferences()
        precondition(page.preferredContentMode == .recommended)
        precondition(page.allowsContentJavaScript)
        precondition(page.preferredHTTPSNavigationPolicy == .keepAsRequested)
    }
}

func testCookieStoreDisallowPolicy() {
    wkMain {
        let store = WKHTTPCookieStore()
        precondition(store.cookiePolicy == .allow)
        var observed: WKHTTPCookieStore.CookiePolicy?
        store.getCookiePolicy { observed = $0 }
        precondition(observed == .allow)
        precondition(WKHTTPCookieStore.CookiePolicy.allow.rawValue == 0)
        precondition(WKHTTPCookieStore.CookiePolicy.disallow.rawValue == 1)
    }
}

func testProcessPoolAndContentWorld() {
    wkMain {
        _ = WKProcessPool()
        precondition(WKContentWorld.page.name == nil)
        let named = WKContentWorld.world(name: "portable")
        precondition(named.name == "portable")
        let origin = WKSecurityOrigin(protocol: "https", host: "example.com", port: 443)
        precondition(origin.host == "example.com")
        precondition(origin.port == 443)
    }
}
