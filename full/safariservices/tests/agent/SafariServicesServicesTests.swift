import Foundation
import SafariServices

private func sampleURL(_ string: String = "https://example.invalid/safari") -> URL {
    URL(string: string)!
}

func testContentBlockerState() {
    let enabled = SFContentBlockerState(isEnabled: true)
    let disabled = SFContentBlockerState(isEnabled: false)
    precondition(enabled.isEnabled)
    precondition(!disabled.isEnabled)
    precondition((enabled as NSObject) === enabled)
}

func testContentBlockerManagerGetStateFailClosed() {
    var count = 0
    var state: SFContentBlockerState?
    var error: (any Error)?
    SFContentBlockerManager.getStateOfContentBlocker(withIdentifier: "com.example.blocker") {
        receivedState,
        receivedError in
        count += 1
        state = receivedState
        error = receivedError
    }
    precondition(count == 1)
    precondition(state == nil)
    let portable = error as? SafariServicesPortableError
    precondition(portable?.code == .contentBlockerServiceUnavailable)
}

func testContentBlockerManagerReloadFailClosed() {
    var count = 0
    var error: (any Error)?
    SFContentBlockerManager.reloadContentBlocker(withIdentifier: "com.example.blocker") { received in
        count += 1
        error = received
    }
    precondition(count == 1)
    let portable = error as? SafariServicesPortableError
    precondition(portable?.code == .contentBlockerServiceUnavailable)
}

func testSSReadingListDefault() {
    guard let list = SSReadingList.default() else {
        preconditionFailure("Linux SSReadingList.default() must return the fail-closed handle")
    }
    precondition((list as NSObject) === SSReadingList.default())
}

func testSSReadingListSupportsURL() {
    precondition(SSReadingList.supportsURL(sampleURL("https://example.invalid/a")))
    precondition(SSReadingList.supportsURL(sampleURL("http://example.invalid/a")))
    precondition(SSReadingList.supportsURL(sampleURL("HTTPS://EXAMPLE.INVALID/a")))
    precondition(!SSReadingList.supportsURL(sampleURL("ftp://example.invalid/a")))
    precondition(!SSReadingList.supportsURL(sampleURL("about:blank")))
}

func testSSReadingListAddItemSchemeRejected() {
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
}

func testSSReadingListAddItemServiceUnavailable() {
    guard let list = SSReadingList.default() else {
        preconditionFailure("Linux SSReadingList.default() must return the fail-closed handle")
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

func testAuthenticationSessionStartFailClosed() {
    var called = false
    let session = SFAuthenticationSession(
        url: sampleURL("https://login.example.invalid/"),
        callbackURLScheme: "example"
    ) { _, _ in
        called = true
    }
    precondition(session.start() == false)
    precondition(called == false)
}

func testAuthenticationSessionCancel() {
    var called = false
    let session = SFAuthenticationSession(
        url: sampleURL("https://login.example.invalid/"),
        callbackURLScheme: "example"
    ) { _, _ in
        called = true
    }
    session.cancel()
    precondition(called == false)
}

func testAuthenticationSessionInitCapitalURL() {
    var called = false
    let capital = SFAuthenticationSession(
        URL: sampleURL("https://login.example.invalid/"),
        callbackURLScheme: nil
    ) { _, _ in
        called = true
    }
    precondition(capital.start() == false)
    precondition(called == false)
}

func testSafariSettingsExportFailClosed() {
    var count = 0
    var error: (any Error)?
    SFSafariSettings.openExportBrowsingDataSettings { received in
        count += 1
        error = received
    }
    precondition(count == 1)
    let portable = error as? SafariServicesPortableError
    precondition(portable?.code == .browserServiceUnavailable)
}

func testSafariSettingsExportNilHandler() {
    SFSafariSettings.openExportBrowsingDataSettings(completionHandler: nil)
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
