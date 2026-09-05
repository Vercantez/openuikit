@_spi(OpenUIKitHost) import ExtensionKit
import Foundation

private func onMain(_ work: @escaping @Sendable @MainActor () -> Void) {
    precondition(Thread.isMainThread, "ExtensionKit tests require the main thread")
    MainActor.assumeIsolated(work)
}

private final class HostDelegateProbe: NSObject, EXHostViewControllerDelegate, @unchecked Sendable {
    var didActivateCount = 0
    var willDeactivateCount = 0
    var lastError: (any Error)?
    weak var activated: EXHostViewController?
    weak var deactivated: EXHostViewController?

    func hostViewControllerDidActivate(_ viewController: EXHostViewController) {
        didActivateCount += 1
        activated = viewController
    }

    func hostViewControllerWillDeactivate(
        _ viewController: EXHostViewController,
        error: (any Error)?
    ) {
        willDeactivateCount += 1
        deactivated = viewController
        lastError = error
    }
}

func testAppExtensionBrowserViewControllerExists() {
    onMain {
        let browser = EXAppExtensionBrowserViewController()
        precondition(browser.host_isExtensionCatalogAvailable == false)
        precondition(browser.host_browseFailure() == .extensionCatalogUnavailable)
        let nsError = browser.host_browseFailure() as NSError
        precondition(nsError.domain == ExtensionKitHostError.errorDomain)
        precondition(nsError.code == 3)
    }
}

func testHostViewControllerClass() {
    onMain {
        let host = EXHostViewController()
        precondition(host.configuration == nil)
        precondition(host.delegate == nil)
    }
}

func testHostViewControllerMakeXPCConnectionThrows() {
    onMain {
        let host = EXHostViewController()
        let identity = AppExtensionIdentity(bundleIdentifier: "com.example.ext")
        host.configuration = EXHostViewController.Configuration(
            appExtension: identity,
            sceneID: "scene"
        )
        do {
            _ = try host.makeXPCConnection()
            fatalError("makeXPCConnection must fail closed")
        } catch let error as ExtensionKitHostError {
            precondition(error == .xpcUnavailable)
            precondition((error as NSError).code == 1)
            precondition((error as NSError).domain == "ExtensionKit.Linux")
        } catch {
            fatalError("unexpected error \(error)")
        }
    }
}

func testHostViewControllerDelegateWeak() {
    onMain {
        let host = EXHostViewController()
        var probe: HostDelegateProbe? = HostDelegateProbe()
        host.delegate = probe
        precondition(host.delegate === probe)
        probe = nil
        precondition(host.delegate == nil)
    }
}

func testHostViewControllerPlaceholderViewRoundTrip() {
    onMain {
        let host = EXHostViewController()
        let replacement = UIView()
        host.placeholderView = replacement
        precondition(host.placeholderView === replacement)
    }
}

func testHostViewControllerDelegateProtocol() {
    onMain {
        let probe = HostDelegateProbe()
        let host = EXHostViewController()
        let asProtocol: any EXHostViewControllerDelegate = probe
        asProtocol.hostViewControllerDidActivate(host)
        asProtocol.hostViewControllerWillDeactivate(host, error: nil)
        precondition(probe.didActivateCount == 1)
        precondition(probe.willDeactivateCount == 1)
    }
}

func testHostViewControllerDidActivateDispatch() {
    onMain {
        let host = EXHostViewController()
        let probe = HostDelegateProbe()
        host.delegate = probe
        host.host_reportDidActivate()
        precondition(probe.didActivateCount == 1)
        precondition(probe.activated === host)
        precondition(probe.willDeactivateCount == 0)
    }
}

func testHostViewControllerWillDeactivateDispatch() {
    onMain {
        let host = EXHostViewController()
        let probe = HostDelegateProbe()
        host.delegate = probe
        host.host_reportWillDeactivate(error: ExtensionKitHostError.xpcUnavailable)
        precondition(probe.willDeactivateCount == 1)
        precondition(probe.deactivated === host)
        let error = probe.lastError as? ExtensionKitHostError
        precondition(error == .xpcUnavailable)
        precondition(probe.didActivateCount == 0)
    }
}

func testHostViewControllerConfigurationGetSet() {
    onMain {
        let host = EXHostViewController()
        precondition(host.configuration == nil)
        let identity = AppExtensionIdentity(bundleIdentifier: "com.example.host")
        let value = EXHostViewController.Configuration(
            appExtension: identity,
            sceneID: "editor"
        )
        host.configuration = value
        precondition(host.configuration?.sceneID == "editor")
        precondition(host.configuration?.appExtension.bundleIdentifier == "com.example.host")
        host.configuration = nil
        precondition(host.configuration == nil)
    }
}

func testHostViewControllerConfigurationInit() {
    onMain {
        let identity = AppExtensionIdentity(bundleIdentifier: "com.example.init")
        var value = EXHostViewController.Configuration(
            appExtension: identity,
            sceneID: "gallery"
        )
        precondition(value.sceneID == "gallery")
        value.sceneID = "renamed"
        precondition(value.sceneID == "renamed")
        let other = AppExtensionIdentity(bundleIdentifier: "com.example.other")
        value.appExtension = other
        precondition(value.appExtension.bundleIdentifier == "com.example.other")
    }
}

func testHostViewControllerConfigurationAppExtension() {
    onMain {
        let identity = AppExtensionIdentity(bundleIdentifier: "com.example.property")
        let value = EXHostViewController.Configuration(
            appExtension: identity,
            sceneID: "id"
        )
        precondition(value.appExtension == identity)
        precondition(value.appExtension.bundleIdentifier == "com.example.property")
    }
}

func testHostViewControllerConfigurationSceneID() {
    onMain {
        let value = EXHostViewController.Configuration(
            appExtension: AppExtensionIdentity(bundleIdentifier: "com.example.scene"),
            sceneID: "unique-scene"
        )
        precondition(value.sceneID == "unique-scene")
        precondition(value.sceneID != "")
    }
}
