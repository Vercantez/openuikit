import Foundation

/// Post-processes raw `CapturedRoomData` into a `CapturedRoom`.
public class RoomBuilder {
    public struct ConfigurationOptions: OptionSet, Sendable {
        public let rawValue: Int

        public init(rawValue: Int) {
            self.rawValue = rawValue
        }

        public static let beautifyObjects = ConfigurationOptions(rawValue: 1 << 0)
    }

    public enum BuildError: Swift.Error, LocalizedError, Equatable, Hashable, Sendable {
        case insufficientInput
        case invalidInput
        case exceedSceneSizeLimit
        case deviceNotSupported
        case internalError

        public var errorDescription: String? {
            switch self {
            case .insufficientInput:
                return "The framework expects more captured room data."
            case .invalidInput:
                return "The framework encountered invalid captured room data."
            case .exceedSceneSizeLimit:
                return "The scene size grew past the framework's limitations."
            case .deviceNotSupported:
                return "The framework doesn't support the user's device."
            case .internalError:
                return "The framework encountered an unexpected error case."
            }
        }
    }

    let options: ConfigurationOptions

    public init(options: ConfigurationOptions) {
        self.options = options
    }

    /// Linux has no RoomPlan reconstruction pipeline. Always fail-closed.
    public func capturedRoom(from capturedRoomData: CapturedRoomData) async throws -> CapturedRoom {
        _ = capturedRoomData
        _ = options
        throw BuildError.deviceNotSupported
    }
}

/// Combines multiple captured rooms that share compatible world space.
public class StructureBuilder {
    public typealias ConfigurationOptions = RoomBuilder.ConfigurationOptions

    public enum BuildError: Swift.Error, LocalizedError, Equatable, Hashable, Sendable {
        case insufficientInput
        case invalidInput
        case invalidRoomLocation
        case exceedSceneSizeLimit
        case deviceNotSupported
        case internalError

        public var errorDescription: String? {
            switch self {
            case .insufficientInput:
                return "The framework expects more captured room data."
            case .invalidInput:
                return "The framework encountered invalid captured room data."
            case .invalidRoomLocation:
                return "The captured rooms do not share compatible world space."
            case .exceedSceneSizeLimit:
                return "The scene size grew past the framework's limitations."
            case .deviceNotSupported:
                return "The framework doesn't support the user's device."
            case .internalError:
                return "The framework encountered an unexpected error case."
            }
        }
    }

    let options: ConfigurationOptions

    public init(options: ConfigurationOptions) {
        self.options = options
    }

    /// Linux cannot merge ARKit world maps. Empty input is `insufficientInput`;
    /// any rooms still fail closed with `deviceNotSupported`.
    public func capturedStructure(from rooms: [CapturedRoom]) async throws -> CapturedStructure {
        _ = options
        if rooms.isEmpty {
            throw BuildError.insufficientInput
        }
        throw BuildError.deviceNotSupported
    }
}
