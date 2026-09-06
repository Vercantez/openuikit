import Foundation

/// One-shot remote keyless-entry command.
public struct RemoteKeylessEntryAction: Sendable {
    public let functionID: FunctionIdentifier
    public let actionID: ActionIdentifier
    public let recipientVehicleID: String

    public init(
        functionID: FunctionIdentifier,
        actionID: ActionIdentifier,
        vehicleID: String
    ) {
        self.functionID = functionID
        self.actionID = actionID
        self.recipientVehicleID = vehicleID
    }

    /// Handle for an in-flight one-shot action.
    ///
    /// Apple's type has no public initializer. Linux `init()` produces a
    /// request that is not in progress.
    public final class ExecutionRequest: Sendable {
        public init() {}

        public func results() async throws -> ExecutionStatus {
            throw CarKeyErrorCode.RequestNotInProgress
        }
    }
}

/// Enduring remote keyless-entry command (hold-style).
public struct RemoteKeylessEntryEnduringAction: Sendable {
    public let functionID: FunctionIdentifier
    public let actionID: ActionIdentifier
    public let recipientVehicleID: String

    public init(
        functionID: FunctionIdentifier,
        actionID: ActionIdentifier,
        vehicleID: String
    ) {
        self.functionID = functionID
        self.actionID = actionID
        self.recipientVehicleID = vehicleID
    }

    /// Handle for an in-flight enduring action.
    public final class EnduringExecutionRequest {
        public init() {}

        public func results() async throws -> ExecutionStatus {
            throw CarKeyErrorCode.RequestNotInProgress
        }

        public func stop() throws {
            throw CarKeyErrorCode.RequestNotInProgress
        }
    }
}

/// Configurable enduring action that can request continuation data.
public struct RemoteKeylessEntryConfigurableEnduringAction: Sendable {
    public let functionID: FunctionIdentifier
    public let actionID: ActionIdentifier
    public let recipientVehicleID: String

    public init(
        functionID: FunctionIdentifier,
        actionID: ActionIdentifier,
        vehicleID: String
    ) {
        self.functionID = functionID
        self.actionID = actionID
        self.recipientVehicleID = vehicleID
    }

    /// ObjC-visible handle for a configurable enduring action.
    ///
    /// The TBD exports an empty `init()`; Linux uses that constructor to make
    /// a request that is not in progress. `eventStream` finishes immediately
    /// with no events (no vehicle, no daemon).
    @objc
    public final class EnduringExecutionRequest: NSObject {
        public override init() {
            super.init()
        }

        public var eventStream: AsyncStream<
            RemoteKeylessEntryConfigurableEnduringAction.EnduringExecutionRequest.Event
        > {
            AsyncStream { continuation in
                continuation.finish()
            }
        }

        public func results() async throws -> ExecutionStatus {
            throw CarKeyErrorCode.RequestNotInProgress
        }

        public func stop() throws {
            throw CarKeyErrorCode.RequestNotInProgress
        }

        /// Continuation payload presented by an in-flight configurable action.
        public struct ContinuationRequest: Sendable {
            public let data: Data?

            public init(data: Data? = nil) {
                self.data = data
            }

            public func confirm(_ data: Data? = nil) throws {
                _ = data
                throw CarKeyErrorCode.RequestNotInProgress
            }
        }

        public enum Event {
            case receivedContinuationRequest(
                RemoteKeylessEntryConfigurableEnduringAction.EnduringExecutionRequest.ContinuationRequest
            )
        }
    }
}
