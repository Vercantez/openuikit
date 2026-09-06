import Foundation
import BrowserEngineKit

// Future clean EC2 dependency-identity client. Isolated host-gate success
// against toolchain Foundation is not integrated guest-Foundation success.

private func assertNotBrowserEngineKitType<T>(_ value: T) {
    precondition(!String(reflecting: type(of: value)).hasPrefix("BrowserEngineKit."))
}

func browserEngineKitDependencyIdentityProbe() {
    let url = URL(string: "https://example.test/page")!
    assertNotBrowserEngineKitType(url)
    precondition(type(of: url) == URL.self)

    let manifestJSON = Data(#"{"name":"Example","start_url":"/"}"#.utf8)
    assertNotBrowserEngineKitType(manifestJSON)
    let manifest = BEWebAppManifest(jsonData: manifestJSON, manifestURL: url)
    precondition(manifest != nil)
    precondition(manifest?.manifestURL == url)
    precondition(manifest?.jsonData == manifestJSON)

    let progress = Progress(totalUnitCount: 4)
    assertNotBrowserEngineKitType(progress)
    let token = Data([0x01, 0x02])
    assertNotBrowserEngineKitType(token)
    let monitor = BEDownloadMonitor(
        sourceURL: url,
        destinationURL: URL(string: "file:///tmp/out.bin")!,
        observedProgress: progress,
        liveActivityAccessToken: token
    )
    precondition(monitor.sourceURL == url)
    precondition(monitor.observedProgress === progress)
    precondition(monitor.liveActivityAccessToken == token)

    let environment = MediaEnvironment(webPage: url)
    precondition(environment.webPageURL == url)

    let range = NSRange(location: 2, length: 3)
    assertNotBrowserEngineKitType(range)
    let context = BETextDocumentContext(
        selectedText: "sel",
        contextBefore: "before",
        contextAfter: "after",
        markedText: nil,
        selectedRangeInMarkedText: range
    )
    precondition(context.selectedRangeInMarkedText.location == 2)
    precondition(context.selectedRangeInMarkedText.length == 3)

    let attributed = NSAttributedString(string: "hello")
    assertNotBrowserEngineKitType(attributed)
    let attributedContext = BETextDocumentContext(
        attributedSelectedText: attributed,
        contextBefore: nil,
        contextAfter: nil,
        markedText: nil,
        selectedRangeInMarkedText: NSRange(location: 0, length: 0)
    )
    precondition(attributedContext.attributedSelectedText?.string == "hello")
}

#if BROWSERENGINEKIT_IDENTITY_MAIN
browserEngineKitDependencyIdentityProbe()
print("BROWSERENGINEKIT_DEPENDENCY_IDENTITY_OK")
#endif
