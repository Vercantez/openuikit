import Dispatch
import Foundation
import SafariServices

private final class SFLocked<Value>: @unchecked Sendable {
    private let lock = NSLock()
    private var value: Value

    init(_ value: Value) {
        self.value = value
    }

    func load() -> Value {
        lock.lock()
        defer { lock.unlock() }
        return value
    }

    func store(_ value: Value) {
        lock.lock()
        self.value = value
        lock.unlock()
    }
}

private func sfAwait<T>(_ body: @escaping () async throws -> T) -> Result<T, Error> {
    let semaphore = DispatchSemaphore(value: 0)
    let box = SFLocked<Result<T, Error>?>(nil)
    Task {
        do {
            box.store(.success(try await body()))
        } catch {
            box.store(.failure(error))
        }
        semaphore.signal()
    }
    if semaphore.wait(timeout: .now() + .seconds(5)) == .timedOut {
        preconditionFailure("async probe timed out")
    }
    guard let result = box.load() else {
        preconditionFailure("async probe did not complete")
    }
    return result
}

private func onMainActor<T>(_ body: @MainActor () -> T) -> T {
    if Thread.isMainThread {
        return MainActor.assumeIsolated(body)
    }
    return DispatchQueue.main.sync {
        MainActor.assumeIsolated(body)
    }
}

private func waitFor(_ semaphore: DispatchSemaphore, _ label: String) {
    if semaphore.wait(timeout: .now() + .seconds(5)) == .timedOut {
        preconditionFailure("timed out waiting for \(label)")
    }
}

private func sampleURL(_ string: String = "https://example.invalid/safari") -> URL {
    URL(string: string)!
}

func testErrorDomainConstants() {
    precondition(SFAuthenticationErrorDomain == "SFAuthenticationErrorDomain")
    precondition(SFContentBlockerErrorDomain == "SFContentBlockerErrorDomain")
    precondition(SFErrorDomain == "SFErrorDomain")
    precondition(SSReadingListErrorDomain == "SSReadingListErrorDomain")
    precondition(SFAuthenticationError.errorDomain == SFAuthenticationErrorDomain)
    precondition(SFAuthenticationError._nsErrorDomain == SFAuthenticationErrorDomain)
    precondition(SFError.errorDomain == SFErrorDomain)
    precondition(SFError._nsErrorDomain == SFErrorDomain)
    precondition(SSReadingListError.errorDomain == SSReadingListErrorDomain)
    precondition(SSReadingListError._nsErrorDomain == SSReadingListErrorDomain)
}

func testExtensionMessageKeys() {
    precondition(SFExtensionMessageKey == "SFExtensionMessageKey")
    precondition(SFExtensionProfileKey == "SFExtensionProfileKey")
}

func testSFAuthenticationErrorCodes() {
    precondition(SFAuthenticationError.Code.canceledLogin.rawValue == 1)
    precondition(SFAuthenticationError.canceledLogin == .canceledLogin)
    precondition(SFAuthenticationError.Code(rawValue: 1) == .canceledLogin)
    precondition(SFAuthenticationError.Code(rawValue: 0) == nil)
    precondition(SFAuthenticationError.Code.canceledLogin.hashValue ==
        SFAuthenticationError.Code.canceledLogin.hashValue)
    var hasher = Hasher()
    SFAuthenticationError.Code.canceledLogin.hash(into: &hasher)
    _ = hasher.finalize()
}

func testSFErrorCodes() {
    precondition(SFError.Code.noExtensionFound.rawValue == 1)
    precondition(SFError.Code.noAttachmentFound.rawValue == 2)
    precondition(SFError.Code.loadingInterrupted.rawValue == 3)
    precondition(SFError.Code.internalError.rawValue == 4)
    precondition(SFError.Code.missingEntitlement.rawValue == 5)
    precondition(SFError.noExtensionFound == .noExtensionFound)
    precondition(SFError.noAttachmentFound == .noAttachmentFound)
    precondition(SFError.loadingInterrupted == .loadingInterrupted)
    precondition(SFError.internalError == .internalError)
    precondition(SFError.missingEntitlement == .missingEntitlement)
    precondition(SFError.Code(rawValue: 1) == .noExtensionFound)
    precondition(SFError.Code(rawValue: 5) == .missingEntitlement)
    precondition(SFError.Code(rawValue: 0) == nil)
    precondition(SFError.Code(rawValue: 6) == nil)
    precondition(SFError.Code.internalError != .missingEntitlement)
    precondition(!(SFError.Code.internalError != .internalError))
    precondition(SFError.Code.internalError.hashValue == SFError.Code.internalError.hashValue)
    var hasher = Hasher()
    SFError.Code.noAttachmentFound.hash(into: &hasher)
    _ = hasher.finalize()
}

func testSFContentBlockerErrorCodes() {
    precondition(SFContentBlockerErrorCode.noExtensionFound.rawValue == 1)
    precondition(SFContentBlockerErrorCode.noAttachmentFound.rawValue == 2)
    precondition(SFContentBlockerErrorCode.loadingInterrupted.rawValue == 3)
    precondition(SFContentBlockerErrorCode(rawValue: 1) == .noExtensionFound)
    precondition(SFContentBlockerErrorCode(rawValue: 0) == nil)
    precondition(SFContentBlockerErrorCode.noExtensionFound != .loadingInterrupted)
    precondition(
        SFContentBlockerErrorCode.noAttachmentFound.hashValue ==
            SFContentBlockerErrorCode.noAttachmentFound.hashValue
    )
    var hasher = Hasher()
    SFContentBlockerErrorCode.loadingInterrupted.hash(into: &hasher)
    _ = hasher.finalize()
}

func testSSReadingListErrorCodes() {
    precondition(SSReadingListError.Code.urlSchemeNotAllowed.rawValue == 1)
    precondition(SSReadingListError.urlSchemeNotAllowed == .urlSchemeNotAllowed)
    precondition(SSReadingListError.Code(rawValue: 1) == .urlSchemeNotAllowed)
    precondition(SSReadingListError.Code(rawValue: 2) == nil)
    precondition(SSReadingListError.Code.urlSchemeNotAllowed.hashValue ==
        SSReadingListError.Code.urlSchemeNotAllowed.hashValue)
    var hasher = Hasher()
    SSReadingListError.Code.urlSchemeNotAllowed.hash(into: &hasher)
    _ = hasher.finalize()
}

func testSFErrorBridgedMembers() {
    let empty = SFError(.internalError)
    precondition(empty.code == .internalError)
    precondition(empty.errorCode == 4)
    precondition(empty.userInfo.isEmpty)
    precondition(empty.errorUserInfo.isEmpty)
    precondition(!empty.localizedDescription.isEmpty)
    precondition(empty == SFError(.internalError))
    precondition(empty != SFError(.missingEntitlement))

    let tagged = SFError(.noExtensionFound, userInfo: ["sentinel": "sf"])
    precondition(tagged.userInfo["sentinel"] as? String == "sf")
    precondition(tagged.errorUserInfo["sentinel"] as? String == "sf")
    precondition(tagged.errorCode == 1)
    precondition(empty.hashValue == SFError(.internalError).hashValue)
    var hasher = Hasher()
    empty.hash(into: &hasher)
    _ = hasher.finalize()

    let error: any Error = SFError(.loadingInterrupted)
    precondition(SFError.Code.loadingInterrupted ~= error)
    precondition(!(SFError.Code.internalError ~= error))
}

func testSFAuthenticationErrorBridgedMembers() {
    let error = SFAuthenticationError(.canceledLogin, userInfo: ["k": "v"])
    precondition(error.code == .canceledLogin)
    precondition(error.errorCode == 1)
    precondition(error.userInfo["k"] as? String == "v")
    precondition(error == SFAuthenticationError(.canceledLogin, userInfo: ["k": "v"]))
    precondition(error != SFAuthenticationError(.canceledLogin))
    precondition(SFAuthenticationError.Code.canceledLogin ~= error)
    precondition(!error.localizedDescription.isEmpty)
    var hasher = Hasher()
    error.hash(into: &hasher)
    _ = hasher.finalize()
    _ = error.hashValue
}

func testSSReadingListErrorBridgedMembers() {
    let error = SSReadingListError(.urlSchemeNotAllowed)
    precondition(error.code == .urlSchemeNotAllowed)
    precondition(error.errorCode == 1)
    precondition(error.userInfo.isEmpty)
    precondition(error == SSReadingListError(.urlSchemeNotAllowed))
    precondition(SSReadingListError.Code.urlSchemeNotAllowed ~= error)
    precondition(!error.localizedDescription.isEmpty)
    var hasher = Hasher()
    error.hash(into: &hasher)
    _ = hasher.finalize()
    _ = error.hashValue
}

func testContentBlockerState() {
    let enabled = SFContentBlockerState(isEnabled: true)
    let disabled = SFContentBlockerState(isEnabled: false)
    precondition(enabled.isEnabled)
    precondition(!disabled.isEnabled)
    precondition((enabled as NSObject) === enabled)
}

func testContentBlockerManagerGetStateFailClosed() {
    let returned = SFLocked(false)
    let count = SFLocked(0)
    let seenReturned = SFLocked(false)
    let stateBox = SFLocked<SFContentBlockerState?>(nil)
    let errorBox = SFLocked<(any Error)?>(nil)
    let done = DispatchSemaphore(value: 0)

    SFContentBlockerManager.getStateOfContentBlocker(withIdentifier: "com.example.blocker") {
        state,
        error in
        seenReturned.store(returned.load())
        count.store(count.load() + 1)
        stateBox.store(state)
        errorBox.store(error)
        done.signal()
    }
    returned.store(true)
    waitFor(done, "getStateOfContentBlocker")
    precondition(seenReturned.load())
    precondition(count.load() == 1)
    precondition(stateBox.load() == nil)
    let portable = errorBox.load() as? SafariServicesPortableError
    precondition(portable?.code == .contentBlockerServiceUnavailable)
}

func testContentBlockerManagerReloadFailClosed() {
    let returned = SFLocked(false)
    let count = SFLocked(0)
    let seenReturned = SFLocked(false)
    let errorBox = SFLocked<(any Error)?>(nil)
    let done = DispatchSemaphore(value: 0)

    SFContentBlockerManager.reloadContentBlocker(withIdentifier: "com.example.blocker") { error in
        seenReturned.store(returned.load())
        count.store(count.load() + 1)
        errorBox.store(error)
        done.signal()
    }
    returned.store(true)
    waitFor(done, "reloadContentBlocker")
    precondition(seenReturned.load())
    precondition(count.load() == 1)
    let portable = errorBox.load() as? SafariServicesPortableError
    precondition(portable?.code == .contentBlockerServiceUnavailable)
}

func testContentBlockerManagerReloadAsync() {
    let result = sfAwait {
        try await SFContentBlockerManager.reloadContentBlocker(withIdentifier: "com.example.blocker")
    }
    switch result {
    case .success:
        preconditionFailure("reloadContentBlocker async must not succeed")
    case .failure(let error):
        let portable = error as? SafariServicesPortableError
        precondition(portable?.code == .contentBlockerServiceUnavailable)
    }
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
    let copied = configuration.copy()
    precondition(copied !== configuration)
    precondition(copied.entersReaderIfAvailable)
    precondition(!copied.barCollapsingEnabled)
    copied.entersReaderIfAvailable = false
    precondition(configuration.entersReaderIfAvailable)
}

func testSafariViewControllerInits() {
    onMainActor {
        let url = sampleURL()
        let fromURL = SFSafariViewController(url: url)
        precondition(fromURL.initialURL == url)
        precondition(fromURL.configuration.entersReaderIfAvailable == false)
        precondition(fromURL.dismissButtonStyle == .done)
        precondition(fromURL.portableError.code == .browserServiceUnavailable)
        precondition(fromURL.delegate == nil)

        let fromCapital = SFSafariViewController(URL: url)
        precondition(fromCapital.initialURL == url)

        let reader = SFSafariViewController(url: url, entersReaderIfAvailable: true)
        precondition(reader.configuration.entersReaderIfAvailable)
        let readerCapital = SFSafariViewController(URL: url, entersReaderIfAvailable: false)
        precondition(!readerCapital.configuration.entersReaderIfAvailable)

        let configuration = SFSafariViewControllerConfiguration()
        configuration.barCollapsingEnabled = false
        let configured = SFSafariViewController(url: url, configuration: configuration)
        precondition(!configured.configuration.barCollapsingEnabled)
        precondition(configured.configuration !== configuration)
        let configuredCapital = SFSafariViewController(URL: url, configuration: configuration)
        precondition(!configuredCapital.configuration.barCollapsingEnabled)

        configured.dismissButtonStyle = .cancel
        precondition(configured.dismissButtonStyle == .cancel)

        let blank = SFSafariViewController()
        precondition(blank.initialURL.absoluteString == "about:blank")
    }
}

private final class RecordingDelegate: SFSafariViewControllerDelegate, @unchecked Sendable {
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

func testSafariViewControllerDelegateInitialLoadFailure() {
    onMainActor {
        let controller = SFSafariViewController(url: sampleURL())
        let delegate = RecordingDelegate()
        controller.delegate = delegate
        controller.reportPortableInitialLoadFailure()
        precondition(delegate.initialLoad == false)
        delegate.safariViewControllerDidFinish(controller)
        precondition(delegate.didFinish)
        delegate.safariViewController(controller, initialLoadDidRedirectTo: sampleURL("https://redirect.invalid/"))
        precondition(delegate.redirected?.absoluteString == "https://redirect.invalid/")
        delegate.safariViewControllerWillOpenInBrowser(controller)
        precondition(delegate.openedInBrowser)
    }
}

func testSafariViewControllerPrewarmAndInvalidate() {
    onMainActor {
        let token = SFSafariViewController.prewarmConnections(to: [sampleURL()])
        precondition(!token.isInvalidated)
        token.invalidate()
        precondition(token.isInvalidated)
        token.invalidate()
        precondition(token.isInvalidated)
    }
}

func testSafariViewControllerDataStoreClear() {
    let returned = SFLocked(false)
    let count = SFLocked(0)
    let seenReturned = SFLocked(false)
    let done = DispatchSemaphore(value: 0)

    onMainActor {
        let store = SFSafariViewController.DataStore.default
        store.clearWebsiteData {
            seenReturned.store(returned.load())
            count.store(count.load() + 1)
            done.signal()
        }
        returned.store(true)
    }
    waitFor(done, "clearWebsiteData")
    precondition(seenReturned.load())
    precondition(count.load() == 1)
}

func testSSReadingListSupportsAndAdd() {
    precondition(SSReadingList.supportsURL(sampleURL("https://example.invalid/a")))
    precondition(SSReadingList.supportsURL(sampleURL("http://example.invalid/a")))
    precondition(SSReadingList.supportsURL(sampleURL("HTTPS://EXAMPLE.INVALID/a")))
    precondition(!SSReadingList.supportsURL(sampleURL("ftp://example.invalid/a")))
    precondition(!SSReadingList.supportsURL(sampleURL("about:blank")))

    guard let list = SSReadingList.default() else {
        preconditionFailure("Linux SSReadingList.default() must return the fail-closed handle")
    }
    do {
        try list.addItem(
            with: sampleURL("file:///tmp/x"),
            title: "nope",
            previewText: nil
        )
        preconditionFailure("unsupported scheme must throw")
    } catch let error as SSReadingListError {
        precondition(error.code == .urlSchemeNotAllowed)
    } catch {
        preconditionFailure("expected SSReadingListError.urlSchemeNotAllowed")
    }

    do {
        try list.addItem(with: sampleURL(), title: "Example", previewText: "preview")
        preconditionFailure("http(s) add must not persist")
    } catch let error as SafariServicesPortableError {
        precondition(error.code == .browserServiceUnavailable)
    } catch {
        preconditionFailure("expected SafariServicesPortableError.browserServiceUnavailable")
    }
}

func testAuthenticationSessionDoesNotStart() {
    let called = SFLocked(false)
    let session = SFAuthenticationSession(
        url: sampleURL("https://login.example.invalid/"),
        callbackURLScheme: "example"
    ) { _, _ in
        called.store(true)
    }
    precondition(session.start() == false)
    session.cancel()
    let capital = SFAuthenticationSession(
        URL: sampleURL("https://login.example.invalid/"),
        callbackURLScheme: nil
    ) { _, _ in
        called.store(true)
    }
    precondition(capital.start() == false)
    Thread.sleep(forTimeInterval: 0.05)
    precondition(called.load() == false)
}

func testSafariSettingsExportFailClosed() {
    let returned = SFLocked(false)
    let count = SFLocked(0)
    let seenReturned = SFLocked(false)
    let errorBox = SFLocked<(any Error)?>(nil)
    let done = DispatchSemaphore(value: 0)

    SFSafariSettings.openExportBrowsingDataSettings { error in
        seenReturned.store(returned.load())
        count.store(count.load() + 1)
        errorBox.store(error)
        done.signal()
    }
    returned.store(true)
    waitFor(done, "openExportBrowsingDataSettings")
    precondition(seenReturned.load())
    precondition(count.load() == 1)
    let portable = errorBox.load() as? SafariServicesPortableError
    precondition(portable?.code == .browserServiceUnavailable)
}

func testAddToHomeScreenActivityItemRequirements() {
    final class Item: SFAddToHomeScreenActivityItem {
        let url = sampleURL()
        let title = "Example"
    }
    let item = Item()
    precondition(item.url == sampleURL())
    precondition(item.title == "Example")
}
