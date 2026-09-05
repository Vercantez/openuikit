import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
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
    precondition((error as NSError).domain == WKErrorDomain)
    precondition(WKError.unknown ~= error)
}

func testWebsiteDataStoreEraseCompletes() {
    wkMain {
        precondition(WKWebsiteDataStore.default() === WKWebsiteDataStore.default())
        let ephemeral = WKWebsiteDataStore.nonPersistent()
        precondition(!ephemeral.isPersistent)
        let cookie = HTTPCookie(properties: [
            .name: "session",
            .value: "1",
            .domain: "example.invalid",
            .path: "/",
        ])!
        var stored = 0
        ephemeral.httpCookieStore.setCookie(cookie) { stored += 1 }
        precondition(stored == 1)
        var cookies: [HTTPCookie] = []
        ephemeral.httpCookieStore.getAllCookies { cookies = $0 }
        precondition(cookies.count == 1)
        var records: [WKWebsiteDataRecord] = []
        ephemeral.fetchDataRecords(ofTypes: [WKWebsiteDataTypeCookies]) { records = $0 }
        precondition(records.count == 1)
        precondition(records[0].dataTypes.contains(WKWebsiteDataTypeCookies))
        var erased = 0
        ephemeral.removeData(
            ofTypes: WKWebsiteDataStore.allWebsiteDataTypes(),
            modifiedSince: Date(timeIntervalSince1970: 0)
        ) { erased += 1 }
        precondition(erased == 1)
        ephemeral.httpCookieStore.getAllCookies { cookies = $0 }
        precondition(cookies.isEmpty)
        precondition(WKWebsiteDataTypeCookies == "WKWebsiteDataTypeCookies")
        precondition(WKWebsiteDataTypeHashSalt == "WKWebsiteDataTypeHashSalt")
        let identified = WKWebsiteDataStore(forIdentifier: UUID())
        precondition(identified.isPersistent)
        precondition(identified.identifier != nil)
        var ids: [UUID] = [UUID()]
        WKWebsiteDataStore.fetchAllDataStoreIdentifiers { ids = $0 }
        precondition(ids.isEmpty)
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
        var available: [String]? = ["x"]
        store.getAvailableContentRuleListIdentifiers { available = $0 }
        precondition(available?.isEmpty == true)
        let rooted = WKContentRuleListStore.store(with: URL(string: "file:///tmp/wk-rules")!)
        precondition(rooted !== store)
        var missingSelector: WKError?
        store.compileContentRuleList(
            forIdentifier: "hide",
            encodedContentRuleList: #"[{"trigger":{"url-filter":".*"},"action":{"type":"css-display-none"}}]"#
        ) { list, error in
            precondition(list == nil)
            missingSelector = error as? WKError
        }
        precondition(missingSelector?.code == .contentRuleListStoreCompileFailed)
        var bothDomains: WKError?
        store.compileContentRuleList(
            forIdentifier: "domains",
            encodedContentRuleList: #"[{"trigger":{"url-filter":".*","if-domain":["a.com"],"unless-domain":["b.com"]},"action":{"type":"block"}}]"#
        ) { _, error in
            bothDomains = error as? WKError
        }
        precondition(bothDomains?.code == .contentRuleListStoreCompileFailed)
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
            precondition((error as? WKError)?.code == .javaScriptExceptionOccurred)
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
        precondition(controller.userScripts[0].isForMainFrameOnly)
        precondition(controller.userScripts[0].world === WKContentWorld.page)
        let worldScript = WKUserScript(
            source: "1",
            injectionTime: .atDocumentEnd,
            forMainFrameOnly: false,
            in: .defaultClient
        )
        controller.addUserScript(worldScript)
        precondition(worldScript.injectionTime == .atDocumentEnd)
        precondition(!worldScript.isForMainFrameOnly)
        controller.removeAllUserScripts()
        precondition(controller.userScripts.isEmpty)
        precondition(WKUserScriptInjectionTime.atDocumentStart.rawValue == 0)
        precondition(WKUserScriptInjectionTime.atDocumentEnd.rawValue == 1)

        let handler = ProbeScriptHandler()
        controller.add(handler, name: "probe")
        controller.add(handler, contentWorld: .page, name: "world")
        precondition(controller.registeredScriptMessageHandlerNames == ["probe", "world"])
        handler.userContentController(
            controller,
            didReceive: WKScriptMessage(name: "probe", body: "ok")
        )
        precondition(handler.names == ["probe"])
        controller.removeScriptMessageHandler(forName: "probe")
        controller.removeScriptMessageHandler(forName: "world", contentWorld: .page)
        controller.removeAllScriptMessageHandlers()
        precondition(controller.registeredScriptMessageHandlerNames.isEmpty)

        let store = WKContentRuleListStore.default()
        var list: WKContentRuleList?
        store.compileContentRuleList(
            forIdentifier: "ucc",
            encodedContentRuleList: #"[{"trigger":{"url-filter":".*"},"action":{"type":"block"}}]"#
        ) { compiled, _ in list = compiled }
        if let list {
            controller.add(list)
            precondition(controller.registeredContentRuleListIdentifiers == ["ucc"])
            controller.remove(list)
            controller.removeAllContentRuleLists()
            precondition(controller.registeredContentRuleListIdentifiers.isEmpty)
        }
    }
}

@MainActor
private final class ProbeScriptHandler: WKScriptMessageHandler {
    var names: [String] = []
    func userContentController(
        _ userContentController: WKUserContentController,
        didReceive message: WKScriptMessage
    ) {
        names.append(message.name)
        _ = message.body
        _ = message.frameInfo.isMainFrame
        _ = message.world
        _ = message.webView
        _ = userContentController
    }
}

func testOptionSetRawValues() {
    precondition(WKAudiovisualMediaTypes.audio.rawValue == 1)
    precondition(WKAudiovisualMediaTypes.video.rawValue == 2)
    precondition(WKAudiovisualMediaTypes.all.contains(.audio))
    precondition(WKAudiovisualMediaTypes.all.contains(.video))
    precondition(WKDataDetectorTypes.phoneNumber.rawValue == 1)
    precondition(WKDataDetectorTypes.link.rawValue == 2)
    precondition(WKDataDetectorTypes.address.rawValue == 4)
    precondition(WKDataDetectorTypes.calendarEvent.rawValue == 8)
    precondition(WKDataDetectorTypes.trackingNumber.rawValue == 16)
    precondition(WKDataDetectorTypes.flightNumber.rawValue == 32)
    precondition(WKDataDetectorTypes.spotlightSuggestion == .lookupSuggestion)
    precondition(WKDataDetectorTypes.all.contains(.link))
    precondition(WKWebViewDataType.sessionStorage.rawValue == 1)
    precondition(WKMediaPlaybackState.none.rawValue == 0)
    precondition(WKMediaPlaybackState.paused.rawValue == 1)
    precondition(WKMediaPlaybackState.suspended.rawValue == 2)
    precondition(WKMediaPlaybackState.playing.rawValue == 3)
    precondition(WKMediaCaptureState.none.rawValue == 0)
    precondition(WKMediaCaptureState.active.rawValue == 1)
    precondition(WKMediaCaptureState.muted.rawValue == 2)
    precondition(WKMediaCaptureType.camera.rawValue == 0)
    precondition(WKMediaCaptureType.microphone.rawValue == 1)
    precondition(WKMediaCaptureType.cameraAndMicrophone.rawValue == 2)
    precondition(WKPermissionDecision.prompt.rawValue == 0)
    precondition(WKPermissionDecision.grant.rawValue == 1)
    precondition(WKPermissionDecision.deny.rawValue == 2)
    precondition(WKDialogResult.showDefault.rawValue == 1)
    precondition(WKDialogResult.askAgain.rawValue == 2)
    precondition(WKDialogResult.handled.rawValue == 3)
    precondition(WKSelectionGranularity.dynamic.rawValue == 0)
    precondition(WKSelectionGranularity.character.rawValue == 1)
    precondition(WKNavigationActionPolicy.allow.rawValue == 1)
    precondition(WKNavigationActionPolicy.cancel.rawValue == 0)
    precondition(WKNavigationActionPolicy.download.rawValue == 2)
    precondition(WKNavigationResponsePolicy.allow.rawValue == 1)
    precondition(WKNavigationResponsePolicy.cancel.rawValue == 0)
    precondition(WKNavigationResponsePolicy.download.rawValue == 2)
    precondition(WKNavigationType.linkActivated.rawValue == 0)
    precondition(WKNavigationType.formSubmitted.rawValue == 1)
    precondition(WKNavigationType.backForward.rawValue == 2)
    precondition(WKNavigationType.reload.rawValue == 3)
    precondition(WKNavigationType.formResubmitted.rawValue == 4)
    precondition(WKNavigationType.other.rawValue == -1)
    var media = WKAudiovisualMediaTypes.audio
    media.formUnion(.video)
    _ = media.intersection(.all)
    _ = media.hashValue
    _ = WKDataDetectorTypes.all.isSuperset(of: .link)
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
        precondition(prefs.javaScriptEnabled)
        precondition(prefs.isFraudulentWebsiteWarningEnabled)
        precondition(prefs.isTextInteractionEnabled)
        precondition(prefs.isSiteSpecificQuirksModeEnabled)
        precondition(!prefs.shouldPrintBackgrounds)
        prefs.isElementFullscreenEnabled = true
        precondition(prefs.elementFullscreenEnabled)
        precondition(prefs.inactiveSchedulingPolicy == .suspend)
        prefs.inactiveSchedulingPolicy = .throttle
        precondition(prefs.inactiveSchedulingPolicy == .throttle)
        prefs.inactiveSchedulingPolicy = .none
        let page = WKWebpagePreferences()
        precondition(page.preferredContentMode == .recommended)
        precondition(page.preferredContentMode != .mobile)
        precondition(page.allowsContentJavaScript)
        precondition(!page.isLockdownModeEnabled)
        precondition(page.preferredHTTPSNavigationPolicy == .keepAsRequested)
        page.preferredHTTPSNavigationPolicy = .automaticFallbackToHTTP
        page.preferredHTTPSNavigationPolicy = .userMediatedFallbackToHTTP
        page.preferredHTTPSNavigationPolicy = .errorOnFailure
        let configuration = WKWebViewConfiguration()
        configuration.suppressesIncrementalRendering = true
        configuration.allowsAirPlayForMediaPlayback = false
        configuration.mediaPlaybackAllowsAirPlay = false
        configuration.upgradeKnownHostsToHTTPS = false
        configuration.limitsNavigationsToAppBoundDomains = true
        configuration.ignoresViewportScaleLimits = true
        configuration.allowsInlinePredictions = true
        configuration.allowsPictureInPictureMediaPlayback = false
        configuration.mediaPlaybackRequiresUserAction = true
        configuration.requiresUserActionForMediaPlayback = true
        configuration.dataDetectorTypes = .all
        configuration.mediaTypesRequiringUserActionForPlayback = .all
        configuration.selectionGranularity = .character
        configuration.showsSystemScreenTimeBlockingView = false
        configuration.supportsAdaptiveImageGlyph = true
        _ = configuration.urlSchemeHandler(forURLScheme: "app")
        configuration.setURLSchemeHandler(nil, forURLScheme: "app")
        precondition(configuration.processPool === configuration.processPool)
    }
}

@MainActor
private final class CookieProbeObserver: WKHTTPCookieStoreObserver {
    var changes = 0
    func cookiesDidChange(in cookieStore: WKHTTPCookieStore) {
        changes += 1
        _ = cookieStore
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
        let observer = CookieProbeObserver()
        store.add(observer)
        let cookie = HTTPCookie(properties: [
            .name: "id",
            .value: "1",
            .domain: "example.invalid",
            .path: "/",
        ])!
        store.setCookie(cookie) {}
        precondition(observer.changes == 1)
        store.setCookiePolicy(.disallow) {}
        let blocked = HTTPCookie(properties: [
            .name: "blocked",
            .value: "1",
            .domain: "example.invalid",
            .path: "/",
        ])!
        store.setCookie(blocked) {}
        var cookies: [HTTPCookie] = []
        store.getAllCookies { cookies = $0 }
        precondition(cookies.count == 1)
        store.delete(cookie) {}
        store.getAllCookies { cookies = $0 }
        precondition(cookies.isEmpty)
        store.remove(observer)
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
