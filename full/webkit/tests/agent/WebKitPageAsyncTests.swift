import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import WebKit

// Async WebPage surface: dialog/policy fail-closed defaults, immediate-throw
// JavaScript/export paths, in-process media controls, and async extension
// inits. No renderer, media engine, sensor hardware, panel, network fetch,
// or extension process is implied. Nothing waits on a queue, semaphore,
// RunLoop, or DispatchQueue.main; every awaited call completes in-process.

private struct AsyncDefaultDialogProbe: WebPage.DialogPresenting {}
private struct AsyncDefaultDeciderProbe: WebPage.NavigationDeciding {}

func testPageAsyncDialogDefaults() async {
    let dialog: any WebPage.DialogPresenting = AsyncDefaultDialogProbe()
    let frame = await WebPage.FrameInfo()
    let params = await WKOpenPanelParameters()
    let file = await dialog.handleFileInputPrompt(parameters: params, initiatedBy: frame)
    precondition(file == .cancel)
    await dialog.handleJavaScriptAlert(message: "hello", initiatedBy: frame)
    let prompt = await dialog.handleJavaScriptPrompt(
        message: "name?", defaultText: "Ada", initiatedBy: frame
    )
    precondition(prompt == .cancel)
    let confirm = await dialog.handleJavaScriptConfirm(message: "sure?", initiatedBy: frame)
    precondition(confirm == .cancel)
    // Default-text nil variant exercises the same requirement overload.
    let promptNil = await dialog.handleJavaScriptPrompt(
        message: "name?", defaultText: nil, initiatedBy: frame
    )
    precondition(promptNil == .cancel)
}

func testPageAsyncNavigationDecideDefaults() async {
    var decider: any WebPage.NavigationDeciding = AsyncDefaultDeciderProbe()
    let frame = await WebPage.FrameInfo()
    let action = await WebPage.NavigationAction(source: frame)
    var prefs = WebPage.NavigationPreferences()
    let actionPolicy = await decider.decidePolicy(for: action, preferences: &prefs)
    precondition(actionPolicy == .cancel)
    let response = await WebPage.NavigationResponse(
        response: URLResponse(
            url: URL(string: "https://example.com/")!,
            mimeType: "text/html",
            expectedContentLength: 0,
            textEncodingName: "utf-8"
        ),
        canShowMimeType: true
    )
    let responsePolicy = await decider.decidePolicy(for: response)
    precondition(responsePolicy == .cancel)
}

func testPageAsyncCallJavaScriptThrows() async {
    let page = await WebPage()
    do {
        _ = try await page.callJavaScript("null")
        preconditionFailure("WebPage.callJavaScript should fail closed without an engine")
    } catch {
        precondition((error as? WKError)?.code == .unknown)
    }
    do {
        _ = try await page.callJavaScript(
            "echo",
            arguments: ["key": "value"],
            in: nil,
            contentWorld: nil
        )
        preconditionFailure("WebPage.callJavaScript should fail closed with arguments")
    } catch {
        precondition((error as? WKError)?.code == .unknown)
    }
}

func testPageAsyncMediaState() async {
    let page = await WebPage()
    let idleInitial = await page.mediaPlaybackState()
    precondition(idleInitial == .none)
    await page.pauseAllMediaPlayback()
    let idleAfterPause = await page.mediaPlaybackState()
    precondition(idleAfterPause == .none)
    await page.setCameraCaptureState(.active)
    let camActive = await page.cameraCaptureState
    precondition(camActive == .active)
    await page.setMicrophoneCaptureState(.muted)
    let micMuted = await page.microphoneCaptureState
    precondition(micMuted == .muted)
    await page.setCameraCaptureState(.none)
    await page.setMicrophoneCaptureState(.none)
    let camIdle = await page.cameraCaptureState
    let micIdle = await page.microphoneCaptureState
    precondition(camIdle == .none)
    precondition(micIdle == .none)
    await page.closeAllMediaPresentations()
    await page.setAllMediaPlaybackSuspended(true)
    let suspended = await page.isMediaPlaybackSuspended
    precondition(suspended == true)
    await page.setAllMediaPlaybackSuspended(false)
    let resumed = await page.isMediaPlaybackSuspended
    precondition(resumed == false)
    let idleFinal = await page.mediaPlaybackState()
    precondition(idleFinal == .none)
}

func testPageAsyncExportThrows() async {
    let page = await WebPage()
    do {
        _ = try await page.exported(as: .pdf())
        preconditionFailure("WebPage.exported should fail closed without a renderer")
    } catch {
        precondition((error as? WKError)?.code == .unknown)
    }
    do {
        _ = try await page.exported(as: .image())
        preconditionFailure("WebPage.exported should fail closed without a renderer")
    } catch {
        precondition((error as? WKError)?.code == .unknown)
    }
}

func testPageAsyncExtensionInits() async {
    do {
        _ = try await WKWebExtension(appExtensionBundle: Bundle.main)
        preconditionFailure("init(appExtensionBundle:) should fail closed without an extension process")
    } catch let error as WKWebExtension.Error {
        precondition(error.code == .resourceNotFound)
    } catch {
        preconditionFailure("init(appExtensionBundle:) threw an unexpected error: \(error)")
    }
    let root = FileManager.default.temporaryDirectory
        .appendingPathComponent("wk-async-ext-\(UUID().uuidString)", isDirectory: true)
    try? FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
    try? Data("""
    {"manifest_version": 3, "name": "AsyncProbe", "version": "1.0"}
    """.utf8).write(to: root.appendingPathComponent("manifest.json"))
    let ext = try? await WKWebExtension(resourceBaseURL: root)
    let extVersion = await ext?.manifestVersion
    let extName = await ext?.displayName
    let extErrorsEmpty = await ext?.errors.isEmpty
    precondition(extVersion == 3)
    precondition(extName == "AsyncProbe")
    precondition(extErrorsEmpty == true)
    try? FileManager.default.removeItem(at: root)
    do {
        _ = try await WKWebExtension(resourceBaseURL: root)
        preconditionFailure("init(resourceBaseURL:) should throw for a missing directory")
    } catch {
        _ = error
    }
}

// Authentication-challenge fail-closed default: the isolated host has no Web
// Content process or trust-evaluation daemon, so the NavigationDeciding
// default cancels. The challenge is formable in-process with a test-local
// URLAuthenticationChallengeSender (nil credential, no failure response);
// the product ignores it and answers (.cancelAuthenticationChallenge, nil).
private final class AsyncChallengeSenderProbe: NSObject, URLAuthenticationChallengeSender, @unchecked Sendable {
    func use(_ credential: URLCredential, for challenge: URLAuthenticationChallenge) {}
    func continueWithoutCredential(for challenge: URLAuthenticationChallenge) {}
    func cancel(_ challenge: URLAuthenticationChallenge) {}
    func performDefaultHandling(for challenge: URLAuthenticationChallenge) {}
    func rejectProtectionSpaceAndContinue(with challenge: URLAuthenticationChallenge) {}
}

func testPageAsyncChallengeDispositionDefaults() async {
    var decider: any WebPage.NavigationDeciding = AsyncDefaultDeciderProbe()
    let space = URLProtectionSpace(
        host: "example.com", port: 443, protocol: "https", realm: nil, authenticationMethod: nil
    )
    let challenge = URLAuthenticationChallenge(
        protectionSpace: space,
        proposedCredential: nil,
        previousFailureCount: 0,
        failureResponse: nil,
        error: nil,
        sender: AsyncChallengeSenderProbe()
    )
    let (disposition, credential) = await decider.decideAuthenticationChallengeDisposition(
        for: challenge
    )
    precondition(disposition == .cancelAuthenticationChallenge)
    precondition(credential == nil)
}
