import Foundation
import BrowserEngineKit

func testMediaEnvironmentWebPageInit() {
    let url = URL(string: "https://example.test/watch")!
    let environment = MediaEnvironment(webPage: url)
    precondition(environment.webPageURL == url)
    precondition(!environment.isActive)
}

func testMediaEnvironmentXPCInitThrows() {
    do {
        _ = try MediaEnvironment(xpcRepresentation: BEHostXPCObject())
        preconditionFailure("xpc media environment must fail")
    } catch let error as BrowserEngineKitHostError {
        precondition(error == .mediaSessionUnavailable)
    } catch {
        preconditionFailure("unexpected")
    }
}

func testMediaEnvironmentActivateSuspendCaptureFailClosed() {
    let environment = MediaEnvironment(webPage: URL(string: "https://example.test")!)
    do {
        try environment.activate()
        preconditionFailure("activate must fail")
    } catch let error as BrowserEngineKitHostError {
        precondition(error == .mediaSessionUnavailable)
    } catch {
        preconditionFailure("unexpected")
    }
    do {
        try environment.suspend()
        preconditionFailure("suspend must fail")
    } catch let error as BrowserEngineKitHostError {
        precondition(error == .mediaSessionUnavailable)
    } catch {
        preconditionFailure("unexpected")
    }
    do {
        _ = try environment.makeCaptureSession()
        preconditionFailure("capture must fail")
    } catch let error as BrowserEngineKitHostError {
        precondition(error == .mediaSessionUnavailable)
        precondition(error.errorCode == 4)
    } catch {
        preconditionFailure("unexpected")
    }
    precondition(environment.createXPCRepresentation() is BEHostXPCObject)
}

func testBEMediaEnvironmentWebPageInit() {
    let url = URL(string: "https://example.test/clip")!
    let environment = BEMediaEnvironment(webPage: url)
    precondition(environment.webPageURL == url)
}

func testBEMediaEnvironmentXPCInitThrows() {
    do {
        _ = try BEMediaEnvironment(xpcRepresentation: BEHostXPCObject())
        preconditionFailure("class xpc init must fail")
    } catch let error as BrowserEngineKitHostError {
        precondition(error == .mediaSessionUnavailable)
    } catch {
        preconditionFailure("unexpected")
    }
}
