import Dispatch
import Foundation

/// Entry point for CarKey remote control.
///
/// Linux has no CarKey daemon, entitlement, or launch-on-event registration.
/// Type methods fail closed with `FeatureNotSupported`. Apple's class has no
/// public designated initializer.
open class CarKeyRemoteControl {
    private init() {}

    /// Begins a remote-control session. Always fails closed on Linux: there is
    /// no Secure Element pairing, vehicle radio, or CarKey daemon.
    open class func start(
        delegate: any CarKeyRemoteControlSessionDelegate,
        subscriptionRange subscriptionFunctionIDRange: ClosedRange<Int>? = nil,
        with delegateCallbackQueue: DispatchQueue? = nil
    ) async throws -> CarKeyRemoteControlSession {
        _ = delegate
        _ = subscriptionFunctionIDRange
        _ = delegateCallbackQueue
        throw CarKeyErrorCode.FeatureNotSupported
    }

    /// Registers the calling app for launch on a CarKey event. Unsupported
    /// without Apple's daemon and entitlement.
    open class func registerForLaunchOnCarKeyEvent() throws {
        throw CarKeyErrorCode.FeatureNotSupported
    }

    /// Unregisters launch-on-event. Unsupported on Linux.
    open class func unregisterForLaunchOnCarKeyEvent() throws {
        throw CarKeyErrorCode.FeatureNotSupported
    }
}

/// Delegate for a `CarKeyRemoteControlSession`.
///
/// `remoteControlSession(_:didCreateKey:forVehicle:)` has a protocol-extension
/// default (empty). The other three requirements have no default. Linux never
/// delivers live callbacks: sessions never start.
public protocol CarKeyRemoteControlSessionDelegate {
    func remoteControlSession(
        _ session: CarKeyRemoteControlSession,
        didInvalidateWithError: CarKeyErrorCode
    )

    func remoteControlSession(
        _ session: CarKeyRemoteControlSession,
        didCreateKey keyID: String,
        forVehicle vehicleID: String
    )

    func remoteControlSession(
        _ session: CarKeyRemoteControlSession,
        vehicleDidUpdateReport: VehicleReport
    )

    func remoteControlSession(
        _ session: CarKeyRemoteControlSession,
        didReceivePassthroughData: Data,
        fromVehicle vehicleID: String
    )
}

extension CarKeyRemoteControlSessionDelegate {
    public func remoteControlSession(
        _ session: CarKeyRemoteControlSession,
        didCreateKey keyID: String,
        forVehicle vehicleID: String
    ) {
        _ = session
        _ = keyID
        _ = vehicleID
    }
}

/// An inactive-or-ended remote-control session.
///
/// Apple's type has no public initializer. Linux exposes `init()` so fail-closed
/// instance methods can be exercised; the session is never active.
open class CarKeyRemoteControlSession {
    /// Linux-only inactive session. `start(delegate:subscriptionRange:with:)`
    /// never succeeds on this host.
    public init() {}

    public var vehicleReports: [VehicleReport] {
        get throws {
            throw CarKeyErrorCode.SessionNotActive
        }
    }

    open func end() throws {
        throw CarKeyErrorCode.SessionNotActive
    }

    open func perform(
        _ action: RemoteKeylessEntryAction
    ) throws -> RemoteKeylessEntryAction.ExecutionRequest {
        _ = action
        throw CarKeyErrorCode.SessionNotActive
    }

    open func perform(
        _ enduringAction: RemoteKeylessEntryConfigurableEnduringAction,
        continuationStrategy: CarKeyRemoteControlSession.ContinuationStrategy
    ) throws -> RemoteKeylessEntryConfigurableEnduringAction.EnduringExecutionRequest {
        _ = enduringAction
        _ = continuationStrategy
        throw CarKeyErrorCode.SessionNotActive
    }

    open func perform(
        _ enduringAction: RemoteKeylessEntryEnduringAction
    ) throws -> RemoteKeylessEntryEnduringAction.EnduringExecutionRequest {
        _ = enduringAction
        throw CarKeyErrorCode.SessionNotActive
    }

    open func sendPassthroughData(_ passthroughData: Data, toVehicle vehicleID: String) throws {
        _ = passthroughData
        _ = vehicleID
        throw CarKeyErrorCode.SessionNotActive
    }

    open func isPassiveEntryAvailable(forVehicle vehicleID: String) throws -> Bool {
        _ = vehicleID
        throw CarKeyErrorCode.SessionNotActive
    }

    open func sign(
        data: Data,
        forVehicle vehicleID: String
    ) throws -> CarKeyRemoteControlSession.Attestation {
        _ = data
        _ = vehicleID
        throw CarKeyErrorCode.SessionNotActive
    }

    /// How a configurable enduring action should wait for continuation.
    public enum ContinuationStrategy: Equatable, Hashable, Sendable {
        case automatic
        case manual
    }

    /// Signed attestation payload. Apple produces this from Secure Enclave
    /// `sign(data:forVehicle:)`. Linux construction is for stored-field tests
    /// only; `sign` never succeeds here.
    public struct Attestation: Sendable {
        public let appBundleIdentifier: String
        public let nonce: Data
        public let signedData: Data
        public let signature: Data

        /// Linux-only stored-field constructor. Not a substitute for hardware
        /// signing.
        public init(
            appBundleIdentifier: String,
            nonce: Data,
            signedData: Data,
            signature: Data
        ) {
            self.appBundleIdentifier = appBundleIdentifier
            self.nonce = nonce
            self.signedData = signedData
            self.signature = signature
        }
    }
}
