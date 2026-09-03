import Foundation

extension Tips {
    /// Public rule type. Apple's `#Rule` macro is the Darwin constructor; that
    /// expansion is unobserved here. Host tests build rules through
    /// `@_spi(OpenUIKitHost)`.
    public struct Rule: Sendable {
        public enum CompoundOperation: Hashable, Sendable {
            case conjunction
            case disjunction
        }

        let predicate: @Sendable () -> Bool
        let operation: CompoundOperation?

        init(
            operation: CompoundOperation? = nil,
            predicate: @escaping @Sendable () -> Bool
        ) {
            self.operation = operation
            self.predicate = predicate
        }
    }

    public struct Parameter<Value: Decodable & Encodable & Sendable>: Sendable {
        public typealias ID = String
        public typealias Value = Value

        public let id: String
        public var wrappedValue: Value
        let options: [Tips.ParameterOption]

        public init(
            wrappedValue: Value,
            id: String = "",
            options: Tips.ParameterOption...
        ) {
            self.id = id
            self.wrappedValue = wrappedValue
            self.options = options
        }
    }
}

extension Tips.Rule {
    @_spi(OpenUIKitHost)
    public init(hostPredicate: @escaping @Sendable () -> Bool) {
        self.init(predicate: hostPredicate)
    }

    @_spi(OpenUIKitHost)
    public func evaluateHost() -> Bool {
        predicate()
    }

    @_spi(OpenUIKitHost)
    public var hostOperation: CompoundOperation? {
        operation
    }

    @_spi(OpenUIKitHost)
    public static func conjunction(
        _ lhs: Tips.Rule,
        _ rhs: Tips.Rule
    ) -> Tips.Rule {
        Tips.Rule(operation: .conjunction) {
            lhs.predicate() && rhs.predicate()
        }
    }

    @_spi(OpenUIKitHost)
    public static func disjunction(
        _ lhs: Tips.Rule,
        _ rhs: Tips.Rule
    ) -> Tips.Rule {
        Tips.Rule(operation: .disjunction) {
            lhs.predicate() || rhs.predicate()
        }
    }
}
