import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import WebKit

private func wkPagePolicyMain<T>(_ body: @escaping @MainActor () throws -> T) -> T {
    do {
        return try MainActor.assumeIsolated { try body() }
    } catch {
        fatalError("WebKit page policy test failed: \(error)")
    }
}

@MainActor
private final class PolicyProbePreviewItem: WKPreviewActionItem {
    let identifier: String
    let title: String

    init(identifier: String, title: String) {
        self.identifier = identifier
        self.title = title
    }
}

@MainActor
private final class PolicyProbeReaderTab: WKWebExtensionTab {}

@MainActor
private final class PolicyProbeControllerDelegate: WKWebExtensionControllerDelegate {
    var updatedActions = 0

    func webExtensionController(
        _ controller: WKWebExtensionController,
        didUpdate action: WKWebExtension.Action,
        forExtensionContext context: WKWebExtensionContext
    ) {
        _ = (controller, context)
        _ = action.label
        updatedActions += 1
    }
}

func testPageStopLoadingClearsLoading() {
    wkPagePolicyMain {
        let page = WebPage(configuration: WebPage.Configuration())
        page.stopLoading()
        precondition(!page.isLoading)
    }
}

func testPageConfigurationSharedStores() {
    wkPagePolicyMain {
        let config = WebPage.Configuration()
        precondition(config.websiteDataStore.isPersistent)
        precondition(config.websiteDataStore === WKWebsiteDataStore.default())
        precondition(config.urlSchemeHandlers.isEmpty)
        let userContentController: WKUserContentController = config.userContentController
        _ = userContentController
        precondition(config.webExtensionController == nil)
        precondition(config.deviceSensorAuthorization.permissionPolicy == .prompt)
    }
}

func testPageConfigurationPresenterInits() {
    wkPagePolicyMain {
        let base = WebPage.Configuration()
        let plain = WebPage(configuration: base)
        _ = plain.configuration
        let deciding = WebPage(configuration: base, navigationDecider: nil)
        _ = deciding.configuration
        let presenting = WebPage(configuration: base, dialogPresenter: nil)
        _ = presenting.configuration
        let both = WebPage(configuration: base, navigationDecider: nil, dialogPresenter: nil)
        _ = both.configuration
    }
}

func testPageIdlePresentationAndCaptureState() {
    wkPagePolicyMain {
        let page = WebPage(configuration: WebPage.Configuration())
        precondition(page.fullscreenState == .notInFullscreen)
        precondition(!page.isWritingToolsActive)
        precondition(!page.isBlockedByScreenTime)
        precondition(page.cameraCaptureState == .none)
        precondition(page.microphoneCaptureState == .none)
    }
}

func testPageFrameInfoValues() {
    wkPagePolicyMain {
        let url = URL(string: "https://example.com/page")!
        let frame = WebPage.FrameInfo(
            isMainFrame: true,
            request: URLRequest(url: url),
            securityOrigin: WKSecurityOrigin()
        )
        precondition(frame.isMainFrame)
        precondition(frame.request.url == url)
        _ = frame.securityOrigin
        let subframe = WebPage.FrameInfo(isMainFrame: false, request: URLRequest(url: url))
        precondition(!subframe.isMainFrame)
        precondition(subframe.request.url == url)
    }
}

func testPageNavigationActionPolicyValues() {
    wkPagePolicyMain {
        let url = URL(string: "https://example.com/next")!
        let source = WebPage.FrameInfo(request: URLRequest(url: url))
        let target = WebPage.FrameInfo(isMainFrame: false, request: URLRequest(url: url))
        let action = WebPage.NavigationAction(
            source: source,
            target: target,
            navigationType: .linkActivated,
            request: URLRequest(url: url),
            shouldPerformDownload: false,
            isContentRuleListRedirect: false
        )
        precondition(action.source.isMainFrame)
        precondition(action.target?.isMainFrame == false)
        precondition(action.navigationType == .linkActivated)
        precondition(action.request.url == url)
        precondition(!action.shouldPerformDownload)
        precondition(!action.isContentRuleListRedirect)
        let redirect = WebPage.NavigationAction(
            source: source,
            navigationType: .other,
            request: URLRequest(url: url),
            shouldPerformDownload: true,
            isContentRuleListRedirect: true
        )
        precondition(redirect.target == nil)
        precondition(redirect.shouldPerformDownload)
        precondition(redirect.isContentRuleListRedirect)
    }
}

func testPageNavigationResponseValues() {
    wkPagePolicyMain {
        let url = URL(string: "https://example.com/doc")!
        let urlResponse = URLResponse(
            url: url, mimeType: "text/html", expectedContentLength: 8, textEncodingName: "utf-8"
        )
        let response = WebPage.NavigationResponse(response: urlResponse, canShowMimeType: true)
        precondition((response.response.url == url))
        precondition(response.canShowMimeType)
        let opaque = WebPage.NavigationResponse(response: urlResponse, canShowMimeType: false)
        precondition(!opaque.canShowMimeType)
    }
}

func testFindInteractionEnabledRoundTrip() {
    wkPagePolicyMain {
        let webView = WKWebView(frame: .zero)
        precondition(!webView.isFindInteractionEnabled)
        webView.isFindInteractionEnabled = true
        precondition(webView.isFindInteractionEnabled)
        webView.isFindInteractionEnabled = false
        precondition(!webView.isFindInteractionEnabled)
    }
}

func testPreviewActionItemIdentifier() {
    wkPagePolicyMain {
        let item: any WKPreviewActionItem = PolicyProbePreviewItem(
            identifier: "com.example.preview.open", title: "Open"
        )
        precondition(item.identifier == "com.example.preview.open")
        precondition(item.title == "Open")
    }
}

func testExtensionDelegateSyncWindowsAndActions() {
    wkPagePolicyMain {
        let controller = WKWebExtensionController()
        let context = WKWebExtensionContext(for: WKWebExtension())
        let delegate = PolicyProbeControllerDelegate()
        let action = WKWebExtension.Action()
        delegate.webExtensionController(
            controller, didUpdate: action, forExtensionContext: context
        )
        precondition(delegate.updatedActions == 1)
        let focused = delegate.webExtensionController(controller, focusedWindowFor: context)
        precondition(focused == nil)
        let windows = delegate.webExtensionController(controller, openWindowsFor: context)
        precondition(windows.isEmpty)
    }
}

func testTabReaderModeAvailability() {
    wkPagePolicyMain {
        let context = WKWebExtensionContext(for: WKWebExtension())
        let tab = PolicyProbeReaderTab()
        precondition(!tab.isReaderModeAvailable(for: context))
    }
}
