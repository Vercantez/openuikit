import Foundation

extension Tips {
    /// Public rule type. Apple's `#Rule` macro is unavailable on Linux; the
    /// expanded non-macro spelling is `Tips.Rule(parameter, predicate)` and
    /// `Tips.Rule(event, predicate)`.
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

        /// `#Rule(Self.$parameter) { $0 == value }` expanded form.
        public init<Value: Decodable & Encodable & Sendable>(
            _ parameter: Tips.Parameter<Value>,
            predicate: @escaping @Sendable (Value) -> Bool
        ) {
            self.init {
                predicate(parameter.wrappedValue)
            }
        }

        /// `#Rule(Self.event) { $0.donations.count > n }` expanded form.
        public init<DonationInfo: Decodable & Encodable & Sendable>(
            _ event: Tips.Event<DonationInfo>,
            predicate: @escaping @Sendable (Tips.Event<DonationInfo>) -> Bool
        ) {
            self.init {
                predicate(event)
            }
        }

        func evaluate() -> Bool {
            predicate()
        }
    }

    @propertyWrapper
    public struct Parameter<Value: Decodable & Encodable & Sendable>: Sendable {
        public typealias ID = String
        public typealias Value = Value

        public let id: String
        let defaultValue: Value
        let options: [Tips.ParameterOption]
        private let localBox: LocalBox

        public var projectedValue: Tips.Parameter<Value> { self }

        public var wrappedValue: Value {
            get {
                if let payload = storedPayload(),
                   let decoded = try? JSONDecoder().decode(Value.self, from: payload)
                {
                    return decoded
                }
                return defaultValue
            }
            nonmutating set {
                guard let payload = try? JSONEncoder().encode(newValue) else {
                    return
                }
                if id.isEmpty {
                    localBox.value = payload
                    return
                }
                TipsStore.shared.storeParameter(
                    id: id,
                    payload: payload,
                    transient: isTransient
                )
            }
        }

        public init(
            wrappedValue: Value,
            id: String = "",
            options: Tips.ParameterOption...
        ) {
            self.id = id
            self.defaultValue = wrappedValue
            self.options = options
            self.localBox = LocalBox()
        }

        private var isTransient: Bool {
            options.contains { $0 == .transient }
        }

        private func storedPayload() -> Data? {
            if id.isEmpty {
                return localBox.value
            }
            return TipsStore.shared.loadParameter(id: id, transient: isTransient)
        }

        private final class LocalBox: @unchecked Sendable {
            var value: Data?
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
