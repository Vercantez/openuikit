import Foundation
import SafariServices

private func sampleURL(_ string: String = "https://example.invalid/safari") -> URL {
    URL(string: string)!
}

func testDismissButtonStyle() {
    precondition(SFSafariViewController.DismissButtonStyle.done.rawValue == 0)
    precondition(SFSafariViewController.DismissButtonStyle.close.rawValue == 1)
    precondition(SFSafariViewController.DismissButtonStyle.cancel.rawValue == 2)
    precondition(SFSafariViewController.DismissButtonStyle(rawValue: 0) == .done)
    precondition(SFSafariViewController.DismissButtonStyle(rawValue: 3) == nil)
    precondition(SFSafariViewController.DismissButtonStyle.done != .close)
    precondition(
        SFSafariViewController.DismissButtonStyle.cancel.hashValue ==
            SFSafariViewController.DismissButtonStyle.cancel.hashValue
    )
    var hasher = Hasher()
    SFSafariViewController.DismissButtonStyle.close.hash(into: &hasher)
    _ = hasher.finalize()
}

func testSafariViewControllerConfigurationCopy() {
    let configuration = SFSafariViewController.Configuration()
    precondition(configuration.entersReaderIfAvailable == false)
    precondition(configuration.barCollapsingEnabled == true)
    configuration.entersReaderIfAvailable = true
    configuration.barCollapsingEnabled = false
    let copied: SFSafariViewControllerConfiguration = configuration.copy()
    precondition(copied !== configuration)
    precondition(copied.entersReaderIfAvailable)
    precondition(!copied.barCollapsingEnabled)
    copied.entersReaderIfAvailable = false
    precondition(configuration.entersReaderIfAvailable)
}

func testSafariViewControllerInitWithURL() {
    let url = sampleURL()
    let fromURL = SFSafariViewController(url: url)
    precondition(fromURL.initialURL == url)
    precondition(fromURL.configuration.entersReaderIfAvailable == false)
    precondition(fromURL.dismissButtonStyle == .done)
    precondition(fromURL.portableError.code == .browserServiceUnavailable)
    precondition(fromURL.delegate == nil)

    let fromCapital = SFSafariViewController(URL: url)
    precondition(fromCapital.initialURL == url)
}

func testSafariViewControllerInitWithConfiguration() {
    let url = sampleURL()
    let configuration = SFSafariViewControllerConfiguration()
    configuration.barCollapsingEnabled = false
    let configured = SFSafariViewController(url: url, configuration: configuration)
    precondition(!configured.configuration.barCollapsingEnabled)
    precondition(configured.configuration !== configuration)
    let configuredCapital = SFSafariViewController(URL: url, configuration: configuration)
    precondition(!configuredCapital.configuration.barCollapsingEnabled)
}

func testSafariViewControllerInitEntersReader() {
    let url = sampleURL()
    let reader = SFSafariViewController(url: url, entersReaderIfAvailable: true)
    precondition(reader.configuration.entersReaderIfAvailable)
    let readerCapital = SFSafariViewController(URL: url, entersReaderIfAvailable: false)
    precondition(!readerCapital.configuration.entersReaderIfAvailable)
}

func testSafariViewControllerDismissButtonStyleProperty() {
    let controller = SFSafariViewController(url: sampleURL())
    precondition(controller.dismissButtonStyle == .done)
    controller.dismissButtonStyle = .cancel
    precondition(controller.dismissButtonStyle == .cancel)
    controller.dismissButtonStyle = .close
    precondition(controller.dismissButtonStyle == .close)
}

private final class RecordingDelegate: SFSafariViewControllerDelegate {
    var didFinish = false
    var initialLoad: Bool?
    var redirected: URL?
    var openedInBrowser = false

    func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        didFinish = true
        _ = controller
    }

    func safariViewController(
        _ controller: SFSafariViewController,
        didCompleteInitialLoad didLoadSuccessfully: Bool
    ) {
        initialLoad = didLoadSuccessfully
        _ = controller
    }

    func safariViewController(
        _ controller: SFSafariViewController,
        initialLoadDidRedirectTo URL: URL
    ) {
        redirected = URL
        _ = controller
    }

    func safariViewControllerWillOpenInBrowser(_ controller: SFSafariViewController) {
        openedInBrowser = true
        _ = controller
    }
}

func testSafariViewControllerDelegateDidFinish() {
    let controller = SFSafariViewController(url: sampleURL())
    let delegate = RecordingDelegate()
    controller.delegate = delegate
    precondition(controller.delegate === delegate)
    delegate.safariViewControllerDidFinish(controller)
    precondition(delegate.didFinish)
}

func testSafariViewControllerDelegateInitialLoad() {
    let controller = SFSafariViewController(url: sampleURL())
    let delegate = RecordingDelegate()
    controller.delegate = delegate
    controller.reportPortableInitialLoadFailure()
    precondition(delegate.initialLoad == false)
}

func testSafariViewControllerDelegateRedirect() {
    let controller = SFSafariViewController(url: sampleURL())
    let delegate = RecordingDelegate()
    controller.delegate = delegate
    delegate.safariViewController(
        controller,
        initialLoadDidRedirectTo: sampleURL("https://redirect.invalid/")
    )
    precondition(delegate.redirected?.absoluteString == "https://redirect.invalid/")
}

func testSafariViewControllerDelegateWillOpenInBrowser() {
    let controller = SFSafariViewController(url: sampleURL())
    let delegate = RecordingDelegate()
    controller.delegate = delegate
    delegate.safariViewControllerWillOpenInBrowser(controller)
    precondition(delegate.openedInBrowser)
}

func testSafariViewControllerPrewarmConnections() {
    let token = SFSafariViewController.prewarmConnections(to: [sampleURL()])
    precondition(!token.isInvalidated)
}

func testSafariViewControllerPrewarmingTokenInvalidate() {
    let token = SFSafariViewController.prewarmConnections(to: [sampleURL()])
    token.invalidate()
    precondition(token.isInvalidated)
    token.invalidate()
    precondition(token.isInvalidated)
}

func testSafariViewControllerDataStoreDefault() {
    let store = SFSafariViewController.DataStore.default
    precondition((store as NSObject) === SFSafariViewController.DataStore.default)
}

func testSafariViewControllerDataStoreClear() {
    var count = 0
    SFSafariViewController.DataStore.default.clearWebsiteData {
        count += 1
    }
    precondition(count == 1)
    SFSafariViewController.DataStore.default.clearWebsiteData(completionHandler: nil)
}
