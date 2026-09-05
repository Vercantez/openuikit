import Foundation

/// Optional callbacks for `EXHostViewController` activation.
///
/// Linux never loads an Apple extension. Delegate methods fire only when a
/// host calls the documented SPI, not because an appex process started.
@MainActor
public protocol EXHostViewControllerDelegate: NSObjectProtocol {
    @MainActor
    func hostViewControllerDidActivate(_ viewController: EXHostViewController)

    @MainActor
    func hostViewControllerWillDeactivate(
        _ viewController: EXHostViewController,
        error: (any Error)?
    )
}

extension EXHostViewControllerDelegate {
    public func hostViewControllerDidActivate(_ viewController: EXHostViewController) {
        _ = viewController
    }

    public func hostViewControllerWillDeactivate(
        _ viewController: EXHostViewController,
        error: (any Error)?
    ) {
        _ = (viewController, error)
    }
}

/// Host view controller that would embed an app extension scene on Darwin.
///
/// Isolated Linux subclasses the UIKit lookalike (`NSObject` when UIKit is
/// absent). Setting `configuration` records identity and scene ID and does
/// not start an extension. `makeXPCConnection()` always throws.
@MainActor
open class EXHostViewController: UIViewController, @unchecked Sendable {
    /// An object that holds configuration options for a host view controller.
    public struct Configuration {
        /// The app extension for this configuration object.
        public var appExtension: AppExtensionIdentity
        /// The unique identifier for this configuration object’s user interface.
        public var sceneID: String

        /// Creates a new configuration object.
        public init(appExtension: AppExtensionIdentity, sceneID: String) {
            self.appExtension = appExtension
            self.sceneID = sceneID
        }
    }

    @MainActor
    public weak var delegate: (any EXHostViewControllerDelegate)?

    @MainActor
    public var placeholderView: UIView

    /// The view controller’s configuration.
    @MainActor
    @preconcurrency
    public var configuration: Configuration?

    public override init() {
        self.placeholderView = UIView()
        super.init()
    }

    /// Always throws on Linux. There is no extension process to connect to.
    @MainActor
    open func makeXPCConnection() throws -> NSXPCConnection {
        throw ExtensionKitHostError.xpcUnavailable
    }

    /// Host-driven delegate dispatch. Does not claim an Apple extension activated.
    @_spi(OpenUIKitHost)
    public func host_reportDidActivate() {
        delegate?.hostViewControllerDidActivate(self)
    }

    /// Host-driven delegate dispatch, typically with a fail-closed error.
    @_spi(OpenUIKitHost)
    public func host_reportWillDeactivate(error: (any Error)?) {
        delegate?.hostViewControllerWillDeactivate(self, error: error)
    }
}

/// Browser for available app extensions. Linux has no extension catalog.
@MainActor
open class EXAppExtensionBrowserViewController: UIViewController, @unchecked Sendable {
    public override init() {
        super.init()
    }

    /// Always `false`. Darwin's catalog and entitlements are unobserved.
    @_spi(OpenUIKitHost)
    public var host_isExtensionCatalogAvailable: Bool { false }

    @_spi(OpenUIKitHost)
    public func host_browseFailure() -> ExtensionKitHostError {
        .extensionCatalogUnavailable
    }
}
