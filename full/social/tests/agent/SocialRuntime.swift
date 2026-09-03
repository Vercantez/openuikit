@_spi(OpenUIKitHost) import Social
import Foundation

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

private let eventTimeout = DispatchTimeInterval.seconds(5)

private final class LockedState: @unchecked Sendable {
    private let lock = NSLock()
    private var returned = false
    private var sawReturned = false
    private var count = 0

    func markReturned() {
        lock.lock()
        returned = true
        lock.unlock()
    }

    func noteCallback() {
        lock.lock()
        sawReturned = returned
        count += 1
        lock.unlock()
    }

    func snapshot() -> (sawReturned: Bool, count: Int) {
        lock.lock()
        defer { lock.unlock() }
        return (sawReturned, count)
    }
}

private func waitEvent(_ semaphore: DispatchSemaphore, _ message: String) {
    precondition(semaphore.wait(timeout: .now() + eventTimeout) == .success, message)
}

private final class PerformQueueBlocker: @unchecked Sendable {
    private let occupied = DispatchSemaphore(value: 0)
    private let hold = DispatchSemaphore(value: 0)

    func occupy() {
        SocialHostControl.enqueuePerformProbe {
            self.occupied.signal()
            self.hold.wait()
        }
        waitEvent(occupied, "perform queue blocker did not start")
    }

    func release() {
        hold.signal()
    }
}

private func onMain(_ body: @MainActor () -> Void) {
    if Thread.isMainThread {
        MainActor.assumeIsolated(body)
    } else {
        DispatchQueue.main.sync {
            MainActor.assumeIsolated(body)
        }
    }
}

private func requireUITextViewDelegate(_ value: any UITextViewDelegate) {
    _ = value
}

private func requireFailClosedPerformError(_ error: (any Error)?) {
    guard let error else {
        fatalError("expected fail-closed NSError")
    }
    let nsError = error as NSError
    precondition(nsError.domain == SocialLinuxErrorDomain)
    precondition(nsError.code == 1)
}

private func assertEnums() {
    precondition(SLRequestMethod.GET.rawValue == 0)
    precondition(SLRequestMethod.POST.rawValue == 1)
    precondition(SLRequestMethod.DELETE.rawValue == 2)
    precondition(SLRequestMethod.PUT.rawValue == 3)
    precondition(SLRequestMethod(rawValue: 0) == .GET)
    precondition(SLRequestMethod(rawValue: 99) == nil)
    precondition(SLRequestMethod.GET != .POST)
    precondition(!(SLRequestMethod.GET != .GET))
    var hasher = Hasher()
    SLRequestMethod.GET.hash(into: &hasher)
    _ = SLRequestMethod.POST.hashValue
    _ = hasher.finalize()

    precondition(SLComposeViewControllerResult.cancelled.rawValue == 0)
    precondition(SLComposeViewControllerResult.done.rawValue == 1)
    precondition(SLComposeViewControllerResult(rawValue: 1) == .done)
    precondition(SLComposeViewControllerResult(rawValue: -1) == nil)
    precondition(SLComposeViewControllerResult.cancelled != .done)
    var resultHasher = Hasher()
    SLComposeViewControllerResult.done.hash(into: &resultHasher)
    _ = SLComposeViewControllerResult.cancelled.hashValue
    _ = resultHasher.finalize()
}

private func assertDeclaredServiceConstants() {
    precondition(!SLServiceTypeTwitter.isEmpty)
    precondition(!SLServiceTypeFacebook.isEmpty)
    precondition(!SLServiceTypeSinaWeibo.isEmpty)
    precondition(!SLServiceTypeTencentWeibo.isEmpty)
    precondition(!SLServiceTypeLinkedIn.isEmpty)
}

private func assertConfigurationItem() {
    let item = SLComposeSheetConfigurationItem()
    precondition(item.title == nil)
    item.title = "Account"
    item.value = "user"
    item.valuePending = true
    var tapped = false
    let handler: SLComposeSheetConfigurationItemTapHandler = {
        tapped = true
    }
    item.tapHandler = handler
    item.tapHandler()
    precondition(tapped)
    precondition(item.title == "Account")
    precondition(item.value == "user")
    precondition(item.valuePending)
}

@MainActor
private final class RecursingCancelController: SLComposeServiceViewController {
    override func didSelectCancel() {
        super.didSelectCancel()
        cancel()
    }
}

@MainActor
private func assertComposeService() {
    let controller = SLComposeServiceViewController()
    requireUITextViewDelegate(controller)
    let _: UIViewController = controller
    let _: UITextView = controller.textView

    precondition((controller.contentText ?? "") == "")
    controller.isolatedHostReplaceText("hello")
    precondition(controller.contentText == "hello")

    controller.placeholder = "Write something"
    precondition(controller.placeholder == "Write something")
    controller.charactersRemaining = NSNumber(value: 140)
    precondition(controller.charactersRemaining.intValue == 140)

    precondition(controller.isContentValid())
    controller.validateContent()
    precondition(controller.isolatedHostLastValidatedContent == true)

    let items = controller.configurationItems() ?? []
    precondition(items.isEmpty)
    controller.reloadConfigurationItems()
    precondition(controller.isolatedHostConfigurationReloadCount == 1)

    let first = UIViewController()
    let second = UIViewController()
    controller.pushConfigurationViewController(first)
    controller.pushConfigurationViewController(second)
    precondition(controller.isolatedHostPushedConfigurationController === first)
    controller.popConfigurationViewController()
    precondition(controller.isolatedHostPushedConfigurationController == nil)
    controller.pushConfigurationViewController(second)
    precondition(controller.isolatedHostPushedConfigurationController === second)

    let preview = controller.loadPreviewView()
    precondition(preview != nil)
    let _: UIView = preview!

    controller.autoCompletionViewController = first
    precondition(controller.autoCompletionViewController === first)

    controller.presentationAnimationDidFinish()
    precondition(controller.isolatedHostDidFinishPresentationAnimation)

    controller.didSelectPost()
    precondition(controller.isolatedHostDidSelectPostCount == 1)

    let cancelController = RecursingCancelController()
    cancelController.cancel()
    precondition(cancelController.isolatedHostDidSelectCancelCount == 1)
}

@MainActor
private func assertComposeViewController() {
    precondition(SLComposeViewController.isAvailable(forServiceType: SLServiceTypeTwitter) == false)
    precondition(SLComposeViewController.isAvailable(forServiceType: nil) == false)
    precondition(SLComposeViewController(forServiceType: SLServiceTypeTwitter) == nil)
    precondition(SLComposeViewController(forServiceType: "unknown") == nil)

    let controller = SocialHostControl.makeComposeViewController(serviceType: "isolated")
    precondition(controller.serviceType == "isolated")
    precondition(controller.setInitialText("draft"))
    precondition(controller.isolatedHostInitialText == "draft")
    precondition(controller.setInitialText(nil) == false)

    let image = UIImage()
    precondition(controller.add(image))
    precondition(controller.isolatedHostImageCount == 1)
    precondition(controller.add(UIImage?.none) == false)
    precondition(controller.removeAllImages())
    precondition(controller.isolatedHostImageCount == 0)

    let url = URL(string: "https://example.invalid/a")!
    precondition(controller.add(url))
    precondition(controller.isolatedHostURLCount == 1)
    precondition(controller.add(URL?.none) == false)
    precondition(controller.removeAllURLs())
    precondition(controller.isolatedHostURLCount == 0)

    var calls = 0
    var last: SLComposeViewControllerResult?
    let completion: SLComposeViewControllerCompletionHandler = { result in
        calls += 1
        last = result
    }
    controller.completionHandler = completion
    SocialHostControl.invokeCompletion(controller, result: .done)
    precondition(calls == 1)
    precondition(last == .done)
    precondition(controller.completionHandler == nil)
    SocialHostControl.invokeCompletion(controller, result: .cancelled)
    precondition(calls == 1)
}

private func exampleURL() -> URL {
    URL(string: "https://example.invalid/social")!
}

private func assertRequestSurface() {
    let parameters: [AnyHashable: Any] = ["status": "hello"]
    let request = SLRequest(
        forServiceType: SLServiceTypeTwitter,
        requestMethod: .POST,
        url: exampleURL(),
        parameters: parameters
    )
    precondition(request != nil)
    precondition(request!.requestMethod == .POST)
    precondition(request!.url == exampleURL())
    precondition((request!.parameters["status"] as? String) == "hello")
    precondition(request!.isolatedHostServiceType == SLServiceTypeTwitter)
    precondition(request!.account == nil)

    let prepared = request!.preparedURLRequest()
    precondition(prepared != nil)
    precondition(prepared!.httpMethod == "POST")
    precondition(prepared!.httpBody != nil)

    let get = SLRequest(
        forServiceType: "x",
        requestMethod: .GET,
        url: exampleURL(),
        parameters: ["q": "term"]
    )!
    let getPrepared = get.preparedURLRequest()!
    precondition(getPrepared.httpMethod == "GET")
    precondition(getPrepared.url?.query?.contains("q=term") == true)

    let missing = SLRequest(
        forServiceType: "x",
        requestMethod: .GET,
        url: nil,
        parameters: [:]
    )!
    precondition(missing.preparedURLRequest() == nil)
}

private func assertAccountFailClosed() {
    let request = SLRequest(
        forServiceType: "x",
        requestMethod: .POST,
        url: exampleURL(),
        parameters: [:]
    )!
    request.account = SocialHostControl.makeAccountFixture()
    precondition(request.account != nil)
    precondition(request.preparedURLRequest() == nil)
}

private func assertMultipart() {
    let request = SLRequest(
        forServiceType: "x",
        requestMethod: .POST,
        url: exampleURL(),
        parameters: ["caption": "hi"]
    )!
    request.addMultipartData(nil, withName: "file", type: "text/plain", filename: "a.txt")
    precondition(request.isolatedHostMultipartPartCount == 0)
    request.addMultipartData(Data("no".utf8), withName: "bad\nname", type: "text/plain", filename: "a.txt")
    precondition(request.isolatedHostMultipartPartCount == 0)
    request.addMultipartData(Data("no".utf8), withName: "file", type: "text/\rplain", filename: "a.txt")
    precondition(request.isolatedHostMultipartPartCount == 0)
    request.addMultipartData(Data("no".utf8), withName: "file", type: "text/plain", filename: "a\"b.txt")
    precondition(request.isolatedHostMultipartPartCount == 0)

    request.addMultipartData(Data("payload".utf8), withName: "file", type: "text/plain", filename: "note.txt")
    precondition(request.isolatedHostMultipartPartCount == 1)
    let prepared = request.preparedURLRequest()
    precondition(prepared != nil)
    let body = String(data: prepared!.httpBody ?? Data(), encoding: .utf8) ?? ""
    precondition(body.contains("name=\"caption\""))
    precondition(body.contains("name=\"file\""))
    precondition(body.contains("filename=\"note.txt\""))
    precondition(body.contains("payload"))
    precondition(prepared!.value(forHTTPHeaderField: "Content-Type")?.contains("multipart/form-data") == true)

    let injected = SLRequest(
        forServiceType: "x",
        requestMethod: .POST,
        url: exampleURL(),
        parameters: ["na\nme": "v"]
    )!
    injected.addMultipartData(Data("x".utf8), withName: "file", type: "text/plain", filename: nil)
    precondition(injected.preparedURLRequest() == nil)
}

private func assertBoundaryCollisionRetry() {
    var n = 0
    SocialHostControl.setBoundaryCandidateSource {
        n += 1
        if n < 3 {
            return "COLLIDE"
        }
        return "UNIQUEBOUND"
    }
    let request = SLRequest(
        forServiceType: "x",
        requestMethod: .POST,
        url: exampleURL(),
        parameters: ["token": "COLLIDE"]
    )!
    request.addMultipartData(Data("z".utf8), withName: "file", type: "text/plain", filename: nil)
    let prepared = request.preparedURLRequest()
    precondition(prepared != nil)
    let body = String(data: prepared!.httpBody ?? Data(), encoding: .utf8) ?? ""
    precondition(body.contains("UNIQUEBOUND"))
    precondition(!body.contains("--COLLIDE"))
    precondition(n >= 3)
    SocialHostControl.resetBoundaryCandidateSource()
}

private func assertPerformFailClosed() {
    let request = SLRequest(
        forServiceType: "x",
        requestMethod: .GET,
        url: exampleURL(),
        parameters: [:]
    )!
    let state = LockedState()
    let finished = DispatchSemaphore(value: 0)
    let blocker = PerformQueueBlocker()
    blocker.occupy()
    request.perform { data, response, error in
        precondition(data == nil)
        precondition(response == nil)
        requireFailClosedPerformError(error)
        state.noteCallback()
        finished.signal()
    }
    state.markReturned()
    let duringBlock = state.snapshot()
    precondition(duringBlock.count == 0)
    blocker.release()
    waitEvent(finished, "perform handler did not run")
    let after = state.snapshot()
    precondition(after.count == 1)
    precondition(after.sawReturned)
}

@MainActor
private func assertStandaloneFixtureMarker() {
    #if canImport(UIKit)
    let view = UIView()
    let name = String(reflecting: type(of: view))
    precondition(name.hasPrefix("UIKit."), "expected UIKit.UIView, got \(name)")
    #else
    let view = UIView()
    let name = String(reflecting: type(of: view))
    precondition(name.hasPrefix("Social."), "expected Social.UIView fixture, got \(name)")
    print("SOCIAL_STANDALONE_UNIT_FIXTURE_ONLY")
    #endif
    precondition(SocialHostControl.isStandaloneUnitFixture == true || SocialHostControl.isStandaloneUnitFixture == false)
}

assertEnums()
assertDeclaredServiceConstants()
assertConfigurationItem()
onMain {
    assertComposeService()
    assertComposeViewController()
    assertStandaloneFixtureMarker()
}
assertRequestSurface()
assertAccountFailClosed()
assertMultipart()
assertBoundaryCollisionRetry()
assertPerformFailClosed()
print("SOCIAL_AGENT_RUNTIME_OK")
