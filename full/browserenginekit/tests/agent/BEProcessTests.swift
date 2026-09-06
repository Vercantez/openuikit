import Foundation
import BrowserEngineKit

func testRestrictedSandboxRevisionAllCases() {
    precondition(RestrictedSandboxRevision.allCases == [.revision1, .revision2])
}

func testRestrictedSandboxRevisionComparable() {
    precondition(RestrictedSandboxRevision.revision1 < .revision2)
    precondition(RestrictedSandboxRevision.revision2 > .revision1)
    precondition(RestrictedSandboxRevision.revision1 <= .revision2)
    precondition(RestrictedSandboxRevision.revision2 >= .revision1)
    precondition(RestrictedSandboxRevision.revision1 <= .revision1)
    precondition(!(RestrictedSandboxRevision.revision2 < .revision1))
}

func testRestrictedSandboxRevisionEquality() {
    precondition(RestrictedSandboxRevision.revision1 == .revision1)
    precondition(RestrictedSandboxRevision.revision1 != .revision2)
}

func testRestrictedSandboxRevisionHashable() {
    var hasher = Hasher()
    RestrictedSandboxRevision.revision1.hash(into: &hasher)
    _ = hasher.finalize()
    precondition(RestrictedSandboxRevision.revision1.hashValue != RestrictedSandboxRevision.revision2.hashValue)
}

func testRestrictedSandboxRevisionRanges() {
    let half = RestrictedSandboxRevision.revision1 ..< .revision2
    precondition(half.contains(.revision1))
    precondition(!half.contains(.revision2))
    let closed = RestrictedSandboxRevision.revision1 ... .revision2
    precondition(closed.contains(.revision2))
    let from = RestrictedSandboxRevision.revision1...
    precondition(from.contains(.revision2))
    let through: PartialRangeThrough<RestrictedSandboxRevision> = ...RestrictedSandboxRevision.revision1
    precondition(through.contains(.revision1))
    let upTo: PartialRangeUpTo<RestrictedSandboxRevision> = ..<RestrictedSandboxRevision.revision2
    precondition(upTo.contains(.revision1))
}

private final class HostSandbox: RestrictedSandboxAppliable {
    var applied: RestrictedSandboxRevision?
    func applyRestrictedSandbox(revision: RestrictedSandboxRevision) {
        applied = revision
    }
}

func testRestrictedSandboxAppliableDefaultNoOp() {
    let host = HostSandbox()
    host.applyRestrictedSandbox(revision: .revision2)
    precondition(host.applied == .revision2)
}

private struct HostWebContent: WebContentExtension {
    func handle(xpcConnection: xpc_connection_t) {
        _ = xpcConnection
    }
}

func testWebContentExtensionConfigurationDefault() {
    let ext = HostWebContent()
    precondition(ext.configuration.accept(connection: NSXPCConnection()) == false)
}

private struct HostRendering: RenderingExtension {
    func handle(xpcConnection: xpc_connection_t) {
        _ = xpcConnection
    }
}

private struct HostNetworking: NetworkingExtension {
    func handle(xpcConnection: xpc_connection_t) {
        _ = xpcConnection
    }
}

func testRenderingExtensionHandleAndConfiguration() {
    let ext = HostRendering()
    ext.handle(xpcConnection: BEHostXPCObject())
    precondition(ext.configuration.accept(connection: NSXPCConnection(serviceName: "x")) == false)
}

func testNetworkingExtensionHandleAndConfiguration() {
    let ext = HostNetworking()
    ext.handle(xpcConnection: BEHostXPCObject())
    precondition(ext.configuration.accept(connection: NSXPCConnection()) == false)
}

func testWebContentExtensionHandle() {
    let ext = HostWebContent()
    ext.handle(xpcConnection: BEHostXPCObject())
}

func testProcessCapabilityCases() {
    let background = ProcessCapability.background
    let foreground = ProcessCapability.foreground
    let suspended = ProcessCapability.suspended
    let media = ProcessCapability.mediaPlaybackAndCapture(
        environment: MediaEnvironment(webPage: URL(string: "https://example.test")!)
    )
    precondition(background != foreground)
    precondition(foreground != suspended)
    switch media {
    case .mediaPlaybackAndCapture(let environment):
        precondition(environment.webPageURL?.host == "example.test")
    default:
        preconditionFailure("expected media capability")
    }
}

func testProcessCapabilityGrantInvalidate() {
    let grant = ProcessCapability.Grant.host_makeValid()
    precondition(grant.isValid)
    grant.invalidate()
    precondition(!grant.isValid)
}

func testBEProcessCapabilityFactoriesFailClosedRequest() {
    let background = BEProcessCapability.background()
    let foreground = BEProcessCapability.foreground()
    let suspended = BEProcessCapability.suspended()
    let media = BEProcessCapability.mediaPlaybackAndCapture(
        environment: BEMediaEnvironment(webPage: URL(string: "https://example.test")!)
    )
    precondition(background.kind == .background)
    precondition(foreground.kind == .foreground)
    precondition(suspended.kind == .suspended)
    precondition(media.kind == .mediaPlaybackAndCapture)
    do {
        _ = try background.request()
        preconditionFailure("request must fail closed")
    } catch let error as BrowserEngineKitHostError {
        precondition(error == .processUnavailable)
        precondition(error.errorCode == 1)
    } catch {
        preconditionFailure("unexpected error")
    }
}

func testWebContentProcessFailClosed() {
    var process = WebContentProcess.host_makeUnavailable()
    precondition(!process.isInvalidated)
    do {
        _ = try process.makeLibXPCConnection()
        preconditionFailure("xpc must fail")
    } catch let error as BrowserEngineKitHostError {
        precondition(error == .xpcUnavailable)
    } catch {
        preconditionFailure("unexpected")
    }
    do {
        _ = try process.grantCapability(.background)
        preconditionFailure("grant must fail")
    } catch let error as BrowserEngineKitHostError {
        precondition(error == .processUnavailable)
    } catch {
        preconditionFailure("unexpected")
    }
    do {
        _ = try process.grantCapability(.foreground, invalidationHandler: {})
        preconditionFailure("grant must fail")
    } catch let error as BrowserEngineKitHostError {
        precondition(error == .processUnavailable)
    } catch {
        preconditionFailure("unexpected")
    }
    let interaction = process.createVisibilityPropagationInteraction()
    _ = interaction
    process.invalidate()
    precondition(process.isInvalidated)
}

func testNetworkingProcessFailClosed() {
    var process = NetworkingProcess.host_makeUnavailable()
    do {
        _ = try process.makeLibXPCConnection()
        preconditionFailure("xpc must fail")
    } catch let error as BrowserEngineKitHostError {
        precondition(error == .xpcUnavailable)
    } catch {
        preconditionFailure("unexpected")
    }
    do {
        _ = try process.grantCapability(.suspended)
        preconditionFailure("grant must fail")
    } catch let error as BrowserEngineKitHostError {
        precondition(error == .processUnavailable)
    } catch {
        preconditionFailure("unexpected")
    }
    do {
        _ = try process.grantCapability(.background, invalidationHandler: {})
        preconditionFailure("grant must fail")
    } catch let error as BrowserEngineKitHostError {
        precondition(error == .processUnavailable)
    } catch {
        preconditionFailure("unexpected")
    }
    process.invalidate()
    precondition(process.isInvalidated)
}

func testRenderingProcessFailClosed() {
    var process = RenderingProcess.host_makeUnavailable()
    do {
        _ = try process.makeLibXPCConnection()
        preconditionFailure("xpc must fail")
    } catch let error as BrowserEngineKitHostError {
        precondition(error == .xpcUnavailable)
    } catch {
        preconditionFailure("unexpected")
    }
    do {
        _ = try process.grantCapability(.background)
        preconditionFailure("grant must fail")
    } catch let error as BrowserEngineKitHostError {
        precondition(error == .processUnavailable)
    } catch {
        preconditionFailure("unexpected")
    }
    do {
        _ = try process.grantCapability(.foreground, invalidationHandler: {})
        preconditionFailure("grant must fail")
    } catch let error as BrowserEngineKitHostError {
        precondition(error == .processUnavailable)
    } catch {
        preconditionFailure("unexpected")
    }
    _ = process.createVisibilityPropagationInteraction()
    process.invalidate()
    precondition(process.isInvalidated)
}

func testExtensionConfigurationAcceptRejects() {
    precondition(RenderingExtensionConfiguration().accept(connection: NSXPCConnection()) == false)
    precondition(NetworkingExtensionConfiguration().accept(connection: NSXPCConnection()) == false)
    precondition(WebContentExtensionConfiguration().accept(connection: NSXPCConnection()) == false)
}

func testBrowserEngineKitHostErrorCodes() {
    precondition(BrowserEngineKitHostError.processUnavailable.errorCode == 1)
    precondition(BrowserEngineKitHostError.xpcUnavailable.errorCode == 2)
    precondition(BrowserEngineKitHostError.layerHierarchyUnavailable.errorCode == 3)
    precondition(BrowserEngineKitHostError.mediaSessionUnavailable.errorCode == 4)
    precondition(BrowserEngineKitHostError.downloadMonitorUnavailable.errorCode == 5)
    precondition(BrowserEngineKitHostError.errorDomain == "BrowserEngineKit.Linux")
}

private final class HostExtensionProcess: NSObject, BEExtensionProcess {
    var invalidated = false
    func invalidate() { invalidated = true }
    func makeLibXPCConnectionError() throws -> xpc_connection_t {
        throw BrowserEngineKitHostError.xpcUnavailable
    }
}

func testBEExtensionProcessMakeLibXPCConnectionError() {
    let process = HostExtensionProcess()
    do {
        _ = try process.makeLibXPCConnectionError()
        preconditionFailure("must fail closed")
    } catch let error as BrowserEngineKitHostError {
        precondition(error == .xpcUnavailable)
    } catch {
        preconditionFailure("unexpected")
    }
    process.invalidate()
    precondition(process.invalidated)
}

func testLinuxBoundaryFlags() {
    precondition(BrowserEngineKitLinuxBoundary.helperProcessAvailable == false)
    precondition(BrowserEngineKitLinuxBoundary.layerHierarchyAvailable == false)
    precondition(BrowserEngineKitLinuxBoundary.mediaCaptureAvailable == false)
    precondition(BrowserEngineKitLinuxBoundary.downloadMonitorAvailable == false)
}
