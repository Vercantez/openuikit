import Foundation

/// Snapshot of a vehicle's connectivity and function state.
///
/// Apple's type has no public initializer; reports arrive through an active
/// remote-control session. The Linux initializer stores caller-supplied fields
/// so value-type behavior can be tested without inventing a live vehicle.
public struct VehicleReport: Sendable {
    public let identifier: String

    private let connected: Bool
    private let functions: [FunctionIdentifier]
    private let functionStatus: [Int: FunctionStatus]
    private let functionProprietary: [Int: Data]

    /// Linux-only construction of a report record.
    public init(
        identifier: String,
        isConnected: Bool = false,
        supportedFunctions: [FunctionIdentifier] = [],
        statusByFunction: [FunctionIdentifier: FunctionStatus] = [:],
        proprietaryDataByFunction: [FunctionIdentifier: Data] = [:]
    ) {
        self.identifier = identifier
        self.connected = isConnected
        self.functions = supportedFunctions
        var statuses: [Int: FunctionStatus] = [:]
        for (function, status) in statusByFunction {
            statuses[function.rawValue] = status
        }
        self.functionStatus = statuses
        var proprietary: [Int: Data] = [:]
        for (function, data) in proprietaryDataByFunction {
            proprietary[function.rawValue] = data
        }
        self.functionProprietary = proprietary
    }

    public var isConnected: Bool { connected }

    public var supportedFunctions: [FunctionIdentifier] { functions }

    /// Returns the stored status when `function` is listed as supported.
    /// Throws `FunctionUnknown` when the identifier is not in
    /// `supportedFunctions`. Whether Apple returns `nil` instead of throwing
    /// for an unsupported id is an oracle question.
    public func status(for function: FunctionIdentifier) throws -> FunctionStatus? {
        guard functions.contains(function) else {
            throw CarKeyErrorCode.FunctionUnknown
        }
        return functionStatus[function.rawValue]
    }

    /// Returns stored proprietary bytes when `function` is listed as supported.
    /// Throws `FunctionUnknown` when the identifier is not in
    /// `supportedFunctions`.
    public func proprietaryData(for function: FunctionIdentifier) throws -> Data? {
        guard functions.contains(function) else {
            throw CarKeyErrorCode.FunctionUnknown
        }
        return functionProprietary[function.rawValue]
    }
}
