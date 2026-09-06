import Dispatch
import Foundation

/// A snapshot of the system's Screen Time configuration.
///
/// Apple does not publish a public initializer. Linux never delivers a live
/// snapshot from `STScreenTimeConfigurationObserver`; host tests construct the
/// fail-closed value (`enforcesChildRestrictions == false`) via
/// `ScreenTimeHostControl`.
open class STScreenTimeConfiguration: NSObject {
    /// Whether Screen Time is enforcing child restrictions.
    ///
    /// Linux always reports `false`. There is no child Apple ID, MDM, or
    /// Screen Time settings daemon.
    open var enforcesChildRestrictions: Bool {
        storedEnforcesChildRestrictions
    }

    private let storedEnforcesChildRestrictions: Bool

    init(enforcesChildRestrictions: Bool) {
        self.storedEnforcesChildRestrictions = enforcesChildRestrictions
        super.init()
    }
}

/// Observes Screen Time configuration changes.
///
/// `startObserving` / `stopObserving` are a local state machine. Linux never
/// connects to `STScreenTimeAgentConnection` / `_STMachServiceNameScreenTime`,
/// so `configuration` stays `nil`.
open class STScreenTimeConfigurationObserver: NSObject {
    public let updateQueue: DispatchQueue
    private var observing = false

    public init(updateQueue: DispatchQueue) {
        self.updateQueue = updateQueue
        super.init()
    }

    open func startObserving() {
        observing = true
    }

    open func stopObserving() {
        observing = false
    }

    /// Always `nil` on Linux: the observer never receives a daemon snapshot.
    open var configuration: STScreenTimeConfiguration? {
        nil
    }

    @_spi(OpenUIKitHost)
    public var isObserving: Bool { observing }
}
