import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import WebKit

private func wkStateMain<T>(_ body: @escaping @MainActor () throws -> T) -> T {
    do {
        return try MainActor.assumeIsolated {
            try body()
        }
    } catch {
        fatalError("WebKit state test failed: \(error)")
    }
}

@MainActor
private final class KVORecordingDelegate: WKNavigationDelegate {
    var events: [String] = []
    var downloads: [WKDownload] = []
    var actionPolicy: WKNavigationActionPolicy = .allow
    var responsePolicy: WKNavigationResponsePolicy = .allow

    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        preferences: WKWebpagePreferences,
        decisionHandler: @escaping (WKNavigationActionPolicy, WKWebpagePreferences) -> Void
    ) {
        events.append("action")
        decisionHandler(actionPolicy, preferences)
    }

    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationResponse: WKNavigationResponse,
        decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void
    ) {
        events.append("response")
        decisionHandler(responsePolicy)
    }

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation?) {
        events.append("start")
        precondition(webView.isLoading)
        _ = navigation
    }

    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation?) {
        events.append("commit")
        _ = navigation
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation?) {
        events.append("finish")
        _ = navigation
    }

    func webView(
        _ webView: WKWebView,
        navigationAction: WKNavigationAction,
        didBecome download: WKDownload
    ) {
        events.append("actionDownload")
        downloads.append(download)
        _ = navigationAction
    }

    func webView(
        _ webView: WKWebView,
        navigationResponse: WKNavigationResponse,
        didBecome download: WKDownload
    ) {
        events.append("responseDownload")
        downloads.append(download)
        _ = navigationResponse
    }
}

@MainActor
private final class PanelDelegate: WKUIDelegate {
    var alerts: [String] = []
    var confirms: [String] = []
    var prompts: [String] = []

    func webView(
        _ webView: WKWebView,
        runJavaScriptAlertPanelWithMessage message: String,
        initiatedByFrame frame: WKFrameInfo,
        completionHandler: @escaping () -> Void
    ) {
        alerts.append(message)
        _ = (webView, frame)
        completionHandler()
    }

    func webView(
        _ webView: WKWebView,
        runJavaScriptConfirmPanelWithMessage message: String,
        initiatedByFrame frame: WKFrameInfo,
        completionHandler: @escaping (Bool) -> Void
    ) {
        confirms.append(message)
        _ = (webView, frame)
        completionHandler(true)
    }

    func webView(
        _ webView: WKWebView,
        runJavaScriptTextInputPanelWithPrompt prompt: String,
        defaultText: String?,
        initiatedByFrame frame: WKFrameInfo,
        completionHandler: @escaping (String?) -> Void
    ) {
        prompts.append(prompt)
        _ = (webView, frame)
        completionHandler(defaultText ?? "typed")
    }
}

@MainActor
private final class DeliveredHandler: WKScriptMessageHandler {
    var bodies: [Any] = []
    func userContentController(
        _ userContentController: WKUserContentController,
        didReceive message: WKScriptMessage
    ) {
        bodies.append(message.body)
        _ = (userContentController, message.webView, message.frameInfo, message.world, message.name)
    }
}

@MainActor
private final class ReplyHandler: WKScriptMessageHandlerWithReply {
    var names: [String] = []
    func userContentController(
        _ userContentController: WKUserContentController,
        didReceive message: WKScriptMessage,
        replyHandler: @escaping (Any?, String?) -> Void
    ) {
        names.append(message.name)
        replyHandler("pong", nil)
        _ = userContentController
    }
}

func testWebViewKVOStateAfterHTMLStringLoad() {
    wkStateMain {
        let webView = WKWebView(frame: .zero)
        precondition(!webView.isLoading)
        precondition(webView.estimatedProgress == 0)
        precondition(webView.url == nil)
        precondition(!webView.canGoBack)
        precondition(!webView.canGoForward)
        let navigation = webView.loadHTMLString(
            "<html><head><title>State</title></head></html>",
            baseURL: URL(string: "https://state.invalid/")
        )
        precondition(navigation != nil)
        precondition(webView.title == "State")
        precondition(webView.url?.host == "state.invalid")
        precondition(!webView.isLoading)
        precondition(webView.estimatedProgress == 1.0)
        precondition(!webView.canGoBack && !webView.canGoForward)
        _ = webView.hasOnlySecureContent
    }
}

func testLoadFileURLAndLoadFileRequest() {
    wkStateMain {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("wk-file-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let file = directory.appendingPathComponent("page.html")
        try Data("<title>File</title>".utf8).write(to: file)
        let webView = WKWebView(frame: .zero)
        let fromURL = webView.loadFileURL(file, allowingReadAccessTo: directory)
        precondition(fromURL != nil)
        precondition(webView.title == "File")
        let request = URLRequest(url: file)
        let fromRequest = webView.loadFileRequest(request, allowingReadAccessTo: directory)
        precondition(fromRequest != nil)
        let missing = webView.loadFileURL(
            directory.appendingPathComponent("absent.html"),
            allowingReadAccessTo: directory
        )
        precondition(missing != nil)
        precondition(!webView.isLoading)
        try? FileManager.default.removeItem(at: directory)
    }
}

func testGoBackForwardReloadStopAndHistoryItem() {
    wkStateMain {
        let webView = WKWebView(frame: .zero)
        _ = webView.loadHTMLString("<title>One</title>", baseURL: URL(string: "https://one.invalid/"))
        _ = webView.loadHTMLString("<title>Two</title>", baseURL: URL(string: "https://two.invalid/"))
        precondition(webView.canGoBack)
        precondition(webView.backForwardList.backItem?.url.host == "one.invalid")
        let back = webView.goBack()
        precondition(back != nil)
        precondition(webView.canGoForward)
        let forward = webView.goForward()
        precondition(forward != nil)
        if let current = webView.backForwardList.currentItem {
            precondition(webView.go(to: current) != nil)
            _ = current.initialURL
            _ = webView.backForwardList.item(at: -1)
            _ = webView.backForwardList.backList
            _ = webView.backForwardList.forwardList
        }
        precondition(webView.reload() != nil)
        precondition(webView.reloadFromOrigin() != nil)
        webView.stopLoading()
        precondition(!webView.isLoading)
    }
}

func testCallAsyncJavaScriptJSONOnlyEvaluator() {
    wkStateMain {
        let webView = WKWebView(frame: .zero)
        var object: Any?
        webView.callAsyncJavaScript(
            "return {\"k\":1};",
            arguments: [:],
            in: nil,
            in: .page
        ) { value, error in
            object = value
            precondition(error == nil)
        }
        let dictionary = object as? [String: Any]
        precondition(dictionary?["k"] as? Int == 1 || dictionary?["k"] as? NSNumber != nil)
        var failed: WKError?
        webView.callAsyncJavaScript(
            "document.title",
            in: nil,
            in: .page
        ) { value, error in
            precondition(value == nil)
            failed = error as? WKError
        }
        precondition(failed?.code == .javaScriptExceptionOccurred)
        var array: Any?
        webView.evaluateJavaScript("[1,2]") { value, error in
            array = value
            precondition(error == nil)
        }
        precondition((array as? [Any])?.count == 2)
    }
}

func testSnapshotPDFAndWebArchiveFailClosed() {
    wkStateMain {
        let webView = WKWebView(frame: .zero)
        let snapshot = WKSnapshotConfiguration()
        snapshot.rect = CGRect(x: 0, y: 0, width: 10, height: 10)
        snapshot.snapshotWidth = 10
        snapshot.afterScreenUpdates = false
        var snapshotError: WKError?
        webView.takeSnapshot(configuration: snapshot) { image, error in
            precondition(image == nil)
            snapshotError = error as? WKError
        }
        precondition(snapshotError?.code == .unknown)
        let pdf = WKPDFConfiguration()
        pdf.rect = .zero
        pdf.allowTransparentBackground = true
        var pdfFailed = false
        webView.createPDF(configuration: pdf) { result in
            if case .failure(let error) = result {
                pdfFailed = (error as? WKError)?.code == .unknown
            }
        }
        precondition(pdfFailed)
        var archiveFailed = false
        webView.createWebArchiveData { result in
            if case .failure = result { archiveFailed = true }
        }
        precondition(archiveFailed)
    }
}

func testNavigationActionDownloadPolicyPromotesDownload() {
    wkStateMain {
        let webView = WKWebView(frame: .zero)
        let delegate = KVORecordingDelegate()
        delegate.actionPolicy = .download
        webView.navigationDelegate = delegate
        _ = webView.loadHTMLString("<html></html>", baseURL: URL(string: "https://dl.invalid/"))
        precondition(delegate.events.contains("actionDownload"))
        precondition(!delegate.events.contains("start"))
        precondition(delegate.downloads.first?.originalRequest != nil)
        precondition(!webView.isLoading)
    }
}

func testNavigationResponseDownloadPolicyPromotesDownload() {
    wkStateMain {
        let webView = WKWebView(frame: .zero)
        let delegate = KVORecordingDelegate()
        delegate.responsePolicy = .download
        webView.navigationDelegate = delegate
        _ = webView.loadHTMLString("<html></html>", baseURL: URL(string: "https://dl2.invalid/"))
        precondition(delegate.events.contains("responseDownload"))
        precondition(delegate.events.contains("start"))
        precondition(!delegate.events.contains("commit"))
        precondition(!webView.isLoading)
    }
}

func testScriptMessageHandlerDeliveryFromEvaluateJavaScript() {
    wkStateMain {
        let webView = WKWebView(frame: .zero)
        let handler = DeliveredHandler()
        webView.configuration.userContentController.add(handler, name: "probe")
        webView.evaluateJavaScript("window.webkit.messageHandlers.probe.postMessage(\"ok\")") { _, error in
            precondition(error == nil)
        }
        precondition(handler.bodies.first as? String == "ok")
        webView.evaluateJavaScript("window.webkit.messageHandlers.probe.postMessage({\"n\":1})") { _, error in
            precondition(error == nil)
        }
        precondition(handler.bodies.count == 2)
        let reply = ReplyHandler()
        webView.configuration.userContentController.addScriptMessageHandler(
            reply,
            contentWorld: .page,
            name: "reply"
        )
        webView.evaluateJavaScript("window.webkit.messageHandlers.reply.postMessage(true)") { _, error in
            precondition(error == nil)
        }
        precondition(reply.names == ["reply"])
    }
}

func testJavaScriptPanelCallbacksFromEvaluateJavaScript() {
    wkStateMain {
        let webView = WKWebView(frame: .zero)
        let ui = PanelDelegate()
        webView.uiDelegate = ui
        webView.evaluateJavaScript("alert(\"hi\")") { _, error in
            precondition(error == nil)
        }
        precondition(ui.alerts == ["hi"])
        var confirmed: Any?
        webView.evaluateJavaScript("confirm(\"go\")") { value, error in
            confirmed = value
            precondition(error == nil)
        }
        precondition(confirmed as? Bool == true)
        var typed: Any?
        webView.evaluateJavaScript("prompt(\"name\", \"def\")") { value, error in
            typed = value
            precondition(error == nil)
        }
        precondition(typed as? String == "def")
        precondition(ui.confirms == ["go"])
        precondition(ui.prompts == ["name"])
    }
}
