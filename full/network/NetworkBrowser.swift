import Foundation

/// Bonjour / application-service browser. Linux has no mDNS responder; start
/// fails closed with POSIX EOPNOTSUPP and never fabricates peers.
public final class NWBrowser: @unchecked Sendable, CustomDebugStringConvertible {
    public enum Descriptor: Hashable, Sendable {
        case bonjour(type: String, domain: String?)
        case bonjourWithTXTRecord(type: String, domain: String?)
        case applicationService(name: String)
    }

    public enum State: Equatable, Sendable {
        case setup
        case waiting(NWError)
        case ready
        case failed(NWError)
        case cancelled
    }

    public struct Result: Hashable, Sendable {
        public let endpoint: NWEndpoint
        public let interfaces: [NWInterface]
        public let metadata: Metadata

        public enum Metadata: Hashable, Sendable, CustomDebugStringConvertible {
            case none
            case bonjour(NWTXTRecord)
            public var debugDescription: String { "\(self)" }
        }

        public enum Change: Hashable, Sendable {
            public struct Flags: OptionSet, Hashable, Sendable {
                public let rawValue: UInt8
                public init(rawValue: UInt8) { self.rawValue = rawValue }
                public typealias ArrayLiteralElement = Flags
                public typealias Element = Flags
                public static let identical = Flags(rawValue: 1 << 0)
                public static let interfaceAdded = Flags(rawValue: 1 << 1)
                public static let interfaceRemoved = Flags(rawValue: 1 << 2)
                public static let metadataChanged = Flags(rawValue: 1 << 3)
            }

            case identical
            case added(Result)
            case removed(Result)
            case changed(old: Result, new: Result, flags: Flags)

            public init(between old: Result?, _ new: Result?) {
                switch (old, new) {
                case (nil, nil): self = .identical
                case (nil, let new?): self = .added(new)
                case (let old?, nil): self = .removed(old)
                case (let old?, let new?):
                    self = .changed(old: old, new: new, flags: [])
                }
            }
        }
    }

    public let descriptor: Descriptor
    public let parameters: NWParameters
    public private(set) var browseResults: Set<Result> = []
    public var stateUpdateHandler: ((State) -> Void)?
    public var browseResultsChangedHandler: ((Set<Result>, Set<Result.Change>) -> Void)?
    public private(set) var queue: DispatchQueue?
    public private(set) var state: State = .setup

    public init(for descriptor: Descriptor, using parameters: NWParameters) {
        self.descriptor = descriptor
        self.parameters = parameters
    }

    public func start(queue: DispatchQueue) {
        self.queue = queue
        guard state == .setup else { return }
        // Listed gap: no Bonjour/mDNS on Linux. Fail closed; empty change set.
        state = .failed(.posix(.EOPNOTSUPP))
        stateUpdateHandler?(.failed(.posix(.EOPNOTSUPP)))
        browseResultsChangedHandler?([], [])
    }

    public func cancel() {
        state = .cancelled
        stateUpdateHandler?(.cancelled)
    }

    public var debugDescription: String { "NWBrowser(\(state))" }
}

public protocol NWGroupDescriptor: AnyObject, Sendable {}

public class NWMulticastGroup: NWGroupDescriptor, @unchecked Sendable {
    public init?(with endpoint: NWEndpoint) { return nil }
}

public class NWMultiplexGroup: NWGroupDescriptor, @unchecked Sendable {
    public init(with endpoint: NWEndpoint) { _ = endpoint }
}

public final class NWConnectionGroup: @unchecked Sendable {
    public enum State: Equatable, Sendable {
        case setup
        case waiting(NWError)
        case ready
        case failed(NWError)
        case cancelled
    }

    public class Message: NWConnection.ContentContext {
        public let group: NWConnectionGroup?
        public init(group: NWConnectionGroup?) {
            self.group = group
            super.init(identifier: "group-message")
        }
    }

    public let descriptor: any NWGroupDescriptor
    public let parameters: NWParameters
    public var stateUpdateHandler: ((State) -> Void)?
    public var newConnectionHandler: ((NWConnection) -> Void)?
    public private(set) var state: State = .setup

    public init(with descriptor: any NWGroupDescriptor, using parameters: NWParameters) {
        self.descriptor = descriptor
        self.parameters = parameters
    }

    public func start(queue: DispatchQueue) {
        state = .failed(.unsupported)
        stateUpdateHandler?(.failed(.unsupported))
    }

    public func cancel() {
        state = .cancelled
        stateUpdateHandler?(.cancelled)
    }
}
