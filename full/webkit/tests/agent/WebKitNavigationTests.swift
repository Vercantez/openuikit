import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import WebKit

private func wkNavMain<T>(_ body: @escaping @MainActor () throws -> T) -> T {
    do {
        return try MainActor.assumeIsolated {
            try body()
        }
    } catch {
        fatalError("WebKit navigation test failed: \(error)")
    }
}

@MainActor
private final class RecordingNavigationDelegate: WKNavigationDelegate {
    var events: [String] = []
    var policies = 0
    var responses = 0
    var lastAction: WKNavigationAction?
    var lastResponse: WKNavigationResponse?
    var lastError: WKError?
    var actionPolicy: WKNavigationActionPolicy = .allow

    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        preferences: WKWebpagePreferences,
        decisionHandler: @escaping (WKNavigationActionPolicy, WKWebpagePreferences) -> Void
    ) {
        policies += 1
        lastAction = navigationAction
        events.append("action")
        _ = navigationAction.navigationType
        _ = navigationAction.request
        _ = navigationAction.targetFrame?.isMainFrame
        _ = navigationAction.sourceFrame
        _ = navigationAction.shouldPerformDownload
        _ = navigationAction.isContentRuleListRedirect
        decisionHandler(actionPolicy, preferences)
    }

    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationResponse: WKNavigationResponse,
        decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void
    ) {
        responses += 1
        lastResponse = navigationResponse
        events.append("response")
        _ = navigationResponse.isForMainFrame
        _ = navigationResponse.canShowMIMEType
        _ = navigationResponse.response
        decisionHandler(.allow)
    }

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation?) {
        events.append("start")
        precondition(webView.isLoading)
        precondition(webView.estimatedProgress == 0.1)
        _ = navigation?.effectiveContentMode
        _ = navigation?.requestedURL
    }

    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation?) {
        events.append("commit")
        _ = navigation
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation?) {
        events.append("finish")
        precondition(webView.estimatedProgress == 1.0)
        _ = navigation
    }

    func webView(
        _ webView: WKWebView,
        didFailProvisionalNavigation navigation: WKNavigation?,
        withError error: Error
    ) {
        events.append("failProvisional")
        lastError = error as? WKError
        _ = navigation
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation?, withError error: Error) {
        events.append("fail")
        lastError = error as? WKError
        _ = navigation
    }

    func webView(_ webView: WKWebView, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation?) {
        events.append("redirect")
        _ = navigation
    }

    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        events.append("terminate")
        _ = webView
    }
}

@MainActor
private final class RecordingUIDelegate: WKUIDelegate {
    var closed = 0
    var created: WKWebView?

    func webViewDidClose(_ webView: WKWebView) {
        closed += 1
        _ = webView
    }

    func webView(
        _ webView: WKWebView,
        createWebViewWith configuration: WKWebViewConfiguration,
        for navigationAction: WKNavigationAction,
        windowFeatures: WKWindowFeatures
    ) -> WKWebView? {
        let created = WKWebView(frame: .zero, configuration: configuration)
        self.created = created
        _ = (webView, navigationAction, windowFeatures.menuBarVisibility)
        _ = windowFeatures.statusBarVisibility
        _ = windowFeatures.toolbarsVisibility
        _ = windowFeatures.allowsResizing
        _ = windowFeatures.x
        _ = windowFeatures.y
        _ = windowFeatures.width
        _ = windowFeatures.height
        return created
    }

    func webView(
        _ webView: WKWebView,
        shouldPreviewElement elementInfo: WKPreviewElementInfo
    ) -> Bool {
        _ = (webView, elementInfo.linkURL)
        return false
    }

    func webView(
        _ webView: WKWebView,
        contextMenuWillPresentForElement elementInfo: WKContextMenuElementInfo
    ) {
        _ = (webView, elementInfo.linkURL)
    }

    func webView(
        _ webView: WKWebView,
        contextMenuDidEndForElement elementInfo: WKContextMenuElementInfo
    ) {
        _ = (webView, elementInfo)
    }

    func webView(
        _ webView: WKWebView,
        commitPreviewingViewController previewingViewController: UIViewController
    ) {
        _ = (webView, previewingViewController)
    }
}

@MainActor
private final class SchemeHandler: WKURLSchemeHandler {
    func webView(_ webView: WKWebView, start urlSchemeTask: any WKURLSchemeTask) {
        let url = urlSchemeTask.request.url ?? URL(string: "app://local")!
        let response = URLResponse(
            url: url,
            mimeType: "text/html",
            expectedContentLength: 20,
            textEncodingName: "utf-8"
        )
        urlSchemeTask.didReceive(response)
        urlSchemeTask.didReceive(Data("<title>App</title>".utf8))
        urlSchemeTask.didFinish()
        _ = webView
    }

    func webView(_ webView: WKWebView, stop urlSchemeTask: any WKURLSchemeTask) {
        _ = (webView, urlSchemeTask.request)
    }
}

func testHTMLStringLoadCommitsAndParsesTitle() {
    wkNavMain {
        let webView = WKWebView(
            frame: CGRect(x: 0, y: 0, width: 320, height: 480),
            configuration: WKWebViewConfiguration()
        )
        let delegate = RecordingNavigationDelegate()
        webView.navigationDelegate = delegate
        webView.customUserAgent = "OpenUIKit-Portable"
        webView.allowsBackForwardNavigationGestures = true
        webView.allowsLinkPreview = false
        webView.isInspectable = true
        webView.pageZoom = 1.25
        webView.mediaType = "screen"
        _ = webView.scrollView
        _ = webView.cameraCaptureState
        _ = webView.microphoneCaptureState
        _ = webView.fullscreenState
        _ = webView.hasOnlySecureContent
        _ = webView.themeColor
        _ = webView.certificateChain
        _ = webView.isBlockedByScreenTime
        _ = webView.isWritingToolsActive
        _ = webView.isFindInteractionEnabled
        _ = webView.interactionState
        _ = webView.minimumViewportInset
        _ = webView.maximumViewportInset
        webView.obscuredContentInsets = UIEdgeInsets(top: 1, left: 0, bottom: 0, right: 0)
        webView.underPageBackgroundColor = .black
        webView.setMinimumViewportInset(
            UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0),
            maximumViewportInset: UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        )
        precondition(WKWebView.handlesURLScheme("https"))
        precondition(WKWebView.handlesURLScheme("about"))
        precondition(!WKWebView.handlesURLScheme("mailto"))

        let navigation = webView.loadHTMLString(
            "<html><head><title>Hello</title></head><body></body></html>",
            baseURL: URL(string: "https://example.invalid/")
        )
        precondition(navigation != nil)
        precondition(delegate.events == ["action", "start", "response", "commit", "finish"])
        precondition(delegate.policies == 1 && delegate.responses == 1)
        precondition(webView.title == "Hello")
        precondition(webView.url?.absoluteString == "https://example.invalid/")
        precondition(!webView.isLoading)
        precondition(webView.estimatedProgress == 1.0)
        precondition(webView.backForwardList.currentItem?.url == webView.url)
        precondition(webView.backForwardList.currentItem?.title == "Hello")
        precondition(webView.backForwardList.backItem == nil)
        precondition(!webView.canGoBack && !webView.canGoForward)
        precondition(delegate.lastResponse?.isForMainFrame == true)
        precondition(delegate.lastAction?.navigationType == .other)

        var literal: Any?
        webView.evaluateJavaScript("\"ok\"") { value, error in
            literal = value
            precondition(error == nil)
        }
        precondition(literal as? String == "ok")
        var number: Any?
        webView.evaluateJavaScript("42") { value, error in
            number = value
            precondition(error == nil)
        }
        precondition(number as? Int == 42)
        var flag: Any?
        webView.evaluateJavaScript("true") { value, error in
            flag = value
            precondition(error == nil)
        }
        precondition(flag as? Bool == true)
        var empty: Any? = "x"
        webView.evaluateJavaScript("null") { value, error in
            empty = value
            precondition(error == nil)
        }
        precondition(empty is NSNull)
    }
}

func testDataAndSimulatedLoadsCommit() {
    wkNavMain {
        let webView = WKWebView(frame: .zero)
        let delegate = RecordingNavigationDelegate()
        webView.navigationDelegate = delegate
        let html = Data("<title>Data</title>".utf8)
        _ = webView.load(
            html,
            mimeType: "text/html",
            characterEncodingName: "utf-8",
            baseURL: URL(string: "about:blank")!
        )
        precondition(webView.title == "Data")
        precondition(delegate.events.last == "finish")
        let simulated = webView.loadSimulatedRequest(
            URLRequest(url: URL(string: "https://simulated.invalid/")!),
            responseHTML: "<title>Sim</title>"
        )
        _ = simulated.effectiveContentMode
        precondition(webView.title == "Sim")
        let response = URLResponse(
            url: URL(string: "https://simulated.invalid/body")!,
            mimeType: "text/plain",
            expectedContentLength: 4,
            textEncodingName: "utf-8"
        )
        _ = webView.loadSimulatedRequest(
            URLRequest(url: URL(string: "https://simulated.invalid/body")!),
            response: response,
            responseData: Data("body".utf8)
        )
        _ = webView.loadSimulatedRequest(
            URLRequest(url: URL(string: "https://simulated.invalid/alias")!),
            withResponseHTML: "<title>Alias</title>"
        )
        _ = webView.loadSimulatedRequest(
            URLRequest(url: URL(string: "https://simulated.invalid/alias2")!),
            with: response,
            responseData: Data("x".utf8)
        )
        precondition(webView.canGoBack)
        let back = webView.goBack()
        precondition(back != nil)
        precondition(webView.canGoForward)
        _ = webView.goForward()
        if let current = webView.backForwardList.currentItem {
            _ = webView.go(to: current)
            _ = current.initialURL
            _ = webView.backForwardList.item(at: 0)
            _ = webView.backForwardList.backList
            _ = webView.backForwardList.forwardList
        }
        _ = webView.reload()
        _ = webView.reloadFromOrigin()
        webView.stopLoading()
        precondition(!webView.isLoading)
    }
}

func testCustomSchemeHandlerCommits() {
    wkNavMain {
        let configuration = WKWebViewConfiguration()
        let handler = SchemeHandler()
        configuration.setURLSchemeHandler(handler, forURLScheme: "app")
        precondition(configuration.urlSchemeHandler(forURLScheme: "app") != nil)
        let webView = WKWebView(frame: .zero, configuration: configuration)
        let delegate = RecordingNavigationDelegate()
        webView.navigationDelegate = delegate
        _ = webView.load(URLRequest(url: URL(string: "app://local/page")!))
        precondition(delegate.events == ["action", "start", "response", "commit", "finish"])
        precondition(webView.title == "App")
    }
}

func testJavaScriptLiteralsAndUIDelegate() {
    wkNavMain {
        let webView = WKWebView(frame: .zero)
        let ui = RecordingUIDelegate()
        webView.uiDelegate = ui
        ui.webViewDidClose(webView)
        precondition(ui.closed == 1)
        let loader = WKWebView(frame: .zero)
        let recorder = RecordingNavigationDelegate()
        loader.navigationDelegate = recorder
        _ = loader.loadHTMLString("<html></html>", baseURL: nil)
        let action = recorder.lastAction!
        _ = ui.webView(
            webView,
            createWebViewWith: WKWebViewConfiguration(),
            for: action,
            windowFeatures: WKWindowFeatures()
        )
        precondition(ui.created != nil)
        _ = ui.webView(webView, shouldPreviewElement: WKPreviewElementInfo(linkURL: nil))
        ui.webView(webView, contextMenuWillPresentForElement: WKContextMenuElementInfo())
        ui.webView(webView, contextMenuDidEndForElement: WKContextMenuElementInfo())
        ui.webView(webView, commitPreviewingViewController: UIViewController())

        let snapshot = WKSnapshotConfiguration()
        snapshot.rect = CGRect(x: 0, y: 0, width: 10, height: 10)
        snapshot.snapshotWidth = 10
        snapshot.afterScreenUpdates = false
        let pdf = WKPDFConfiguration()
        pdf.rect = .zero
        pdf.allowTransparentBackground = true
        let find = WKFindConfiguration()
        find.backwards = true
        find.caseSensitive = true
        find.wraps = false
        webView.find("nope", configuration: find) { result in
            precondition(!result.matchFound)
        }
        var download: WKDownload?
        webView.startDownload(using: URLRequest(url: URL(string: "https://example.invalid/file")!)) {
            download = $0
        }
        precondition(download?.originalRequest != nil)
        precondition(download?.webView === webView)
        _ = download?.originatingFrame
        _ = download?.isUserInitiated
        download?.cancel { _ in }
        var resumed: WKDownload?
        webView.resumeDownload(fromResumeData: Data()) { resumed = $0 }
        _ = resumed
        _ = WKDownload.PlaceholderPolicy.disable
        _ = WKDownload.PlaceholderPolicy.enable
        _ = WKDownload.RedirectPolicy.allow
        _ = WKDownload.RedirectPolicy.cancel
        _ = WKOpenPanelParameters(allowsMultipleSelection: true, allowsDirectories: true)
        _ = WKFindResult(matchFound: true)
        _ = WKWebsiteDataRecord(displayName: "Example", dataTypes: [WKWebsiteDataTypeLocalStorage])
        webView.closeAllMediaPresentations()
        webView.requestMediaPlaybackState { state in
            precondition(state == .none)
        }
        precondition(webView.fullscreenState == .notInFullscreen)
        _ = WKWebView.FullscreenState.enteringFullscreen
        _ = WKWebView.FullscreenState.inFullscreen
        _ = WKWebView.FullscreenState.exitingFullscreen
    }
}

func testProcessPoolWorldsAndPreviewConstants() {
    wkNavMain {
        _ = WKProcessPool()
        precondition(WKContentWorld.page.name == nil)
        precondition(WKContentWorld.defaultClient.name == nil)
        let named = WKContentWorld.world(name: "portable")
        precondition(named.name == "portable")
        let origin = WKSecurityOrigin(protocol: "https", host: "example.com", port: 443)
        precondition(origin.host == "example.com")
        precondition(origin.port == 443)
        precondition(origin.protocol == "https")
        precondition(
            WKPreviewActionItemIdentifierCopy.hasPrefix("WKPreviewActionItemIdentifier")
        )
        precondition(
            WKPreviewActionItemIdentifierOpen.hasPrefix("WKPreviewActionItemIdentifier")
        )
        precondition(
            WKPreviewActionItemIdentifierShare.hasPrefix("WKPreviewActionItemIdentifier")
        )
        precondition(
            WKPreviewActionItemIdentifierAddToReadingList.hasPrefix("WKPreviewActionItemIdentifier")
        )
        _ = URLScheme("HTTPS")
        let features = WKWindowFeatures(
            menuBarVisibility: 1,
            statusBarVisibility: 0,
            toolbarsVisibility: 1,
            allowsResizing: 1,
            x: 0,
            y: 0,
            width: 320,
            height: 240
        )
        precondition(features.width != nil)
    }
}
