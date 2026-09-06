import Foundation
@_spi(OpenUIKitHost) import SystemExtensions

func testOSSystemExtensionsWorkspaceType() {
    let workspace = OSSystemExtensionsWorkspace()
    precondition(type(of: workspace) == OSSystemExtensionsWorkspace.self)
    let object: NSObject = workspace
    precondition(object === workspace)
}

func testOSSystemExtensionsWorkspaceShared() {
    let shared = OSSystemExtensionsWorkspace.shared
    precondition(shared === OSSystemExtensionsWorkspace.shared)
    precondition(type(of: shared) == OSSystemExtensionsWorkspace.self)
    let constructed = OSSystemExtensionsWorkspace()
    precondition(constructed !== shared)
}

func testOSSystemExtensionsWorkspaceSystemExtensionsFailClosed() {
    let workspace = OSSystemExtensionsWorkspace.shared
    var thrown: OSSystemExtensionError?
    do {
        _ = try workspace.systemExtensions(forApplicationWithBundleID: "com.example.app")
        preconditionFailure("workspace query must not succeed")
    } catch let error as OSSystemExtensionError {
        thrown = error
    } catch {
        preconditionFailure("expected OSSystemExtensionError, got \(error)")
    }
    guard let error = thrown else {
        preconditionFailure("missing thrown error")
    }
    precondition(error.code == .unknown)
    precondition(error.errorCode == 1)
    precondition(OSSystemExtensionError.errorDomain == OSSystemExtensionErrorDomain)
    let ns = error as NSError
    precondition(ns.domain == OSSystemExtensionErrorDomain)
    precondition(ns.code == 1)
    precondition(SystemExtensionsHostControl.workspaceQueryError.code == .unknown)

    do {
        _ = try workspace.systemExtensions(forApplicationWithBundleID: "")
        preconditionFailure("empty bundle ID must not succeed")
    } catch let error as OSSystemExtensionError {
        precondition(error.code == .unknown)
    } catch {
        preconditionFailure("expected OSSystemExtensionError for empty bundle ID")
    }
}
