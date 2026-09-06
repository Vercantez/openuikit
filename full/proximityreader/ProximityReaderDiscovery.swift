import Foundation

public final class ProximityReaderDiscovery: @unchecked Sendable {
    public init() {}

    public final var contentList: [ProximityReaderDiscovery.Content] {
        get async throws {
            throw ContentError.notSupported
        }
    }

    public final func content(for topic: ProximityReaderDiscovery.Topic) async throws -> ProximityReaderDiscovery.Content {
        _ = topic
        throw ContentError.notSupported
    }

    public final func presentContent(
        _ content: ProximityReaderDiscovery.Content,
        from viewController: UIViewController
    ) async throws {
        _ = content
        _ = viewController
        throw ContentError.notSupported
    }

    public enum ContentError: Error, Hashable, LocalizedError, Sendable {
        case systemBusy
        case notSupported
        case contentNotFound
        case networkUnavailable
        case contentDisplayFailed
        case unknown

        public var errorDescription: String? {
            switch self {
            case .systemBusy: return "ProximityReaderDiscovery.ContentError.systemBusy"
            case .notSupported: return "ProximityReaderDiscovery.ContentError.notSupported"
            case .contentNotFound: return "ProximityReaderDiscovery.ContentError.contentNotFound"
            case .networkUnavailable: return "ProximityReaderDiscovery.ContentError.networkUnavailable"
            case .contentDisplayFailed: return "ProximityReaderDiscovery.ContentError.contentDisplayFailed"
            case .unknown: return "ProximityReaderDiscovery.ContentError.unknown"
            }
        }

        public var failureReason: String? { nil }
        public var recoverySuggestion: String? { nil }
        public var helpAnchor: String? { nil }
        public var localizedDescription: String { errorDescription ?? "ContentError" }

        public func hash(into hasher: inout Hasher) {
            hasher.combine(String(describing: self))
        }

        public var hashValue: Int {
            var hasher = Hasher()
            hash(into: &hasher)
            return hasher.finalize()
        }
    }

    public enum Topic: Sendable {
        public enum Payment: Hashable, Sendable {
            case howToTap

            public func hash(into hasher: inout Hasher) {
                hasher.combine(0)
            }

            public var hashValue: Int {
                var hasher = Hasher()
                hash(into: &hasher)
                return hasher.finalize()
            }
        }

        case payment(ProximityReaderDiscovery.Topic.Payment)
    }

    public struct Content: Identifiable, Sendable {
        public typealias ID = String
        public let id: String
        public let description: String

        public init(id: String, description: String) {
            self.id = id
            self.description = description
        }
    }
}
