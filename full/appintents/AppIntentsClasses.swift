import Foundation

// Additional AppIntents classes from the sealed public surface.

@propertyWrapper public class AppDependency<Value: Sendable>: NSObject, @unchecked Sendable {
    public var projectedValue: AppDependency<Value> { self }

    private var storedKey: AnyHashable = AnyHashable(String(describing: Value.self))
    private var storedManager: AppDependencyManager = .shared
    private var storedDefault: (() -> Value)?

    public override init() {
        super.init()
    }

    public convenience init(
        key: AnyHashable? = nil,
        manager: AppDependencyManager = .shared
    ) {
        self.init()
        storedKey = key ?? AnyHashable(String(describing: Value.self))
        storedManager = manager
    }

    public convenience init(
        key: AnyHashable? = nil,
        manager: AppDependencyManager = .shared,
        default defaultValueProvider: @autoclosure @escaping () -> Value
    ) {
        self.init(key: key, manager: manager)
        storedDefault = defaultValueProvider
    }

    public convenience init(
        key: AnyHashable? = nil,
        manager: AppDependencyManager = .shared,
        default defaultValueProvider: @escaping () async throws -> Value
    ) {
        self.init(key: key, manager: manager)
        _ = defaultValueProvider
    }

    public var wrappedValue: Value {
        get {
            if let value = try? storedManager.get(Value.self, key: storedKey) {
                return value
            }
            if let storedDefault {
                return storedDefault()
            }
            preconditionFailure(
                "AppDependency missing for \(Value.self); Apple crashes, Linux get() throws failedToRetrieveDependency"
            )
        }
        set {
            storedManager.add(key: storedKey, dependency: newValue)
        }
    }
}

public class AppDependencyManager: NSObject, @unchecked Sendable {
    public static let shared = AppDependencyManager()

    private let lock = NSLock()
    private var values: [AnyHashable: Any] = [:]

    public override init() { super.init() }

    public enum Error<Value>: Swift.Error {
        case failedToLoadDependency
        case failedToRetrieveDependency
        case incorrectDependencyType

        public var errorDescription: String? {
            switch self {
            case .failedToLoadDependency:
                return "failedToLoadDependency"
            case .failedToRetrieveDependency:
                return "failedToRetrieveDependency"
            case .incorrectDependencyType:
                return "incorrectDependencyType"
            }
        }
    }

    public func add<Dependency>(
        key: AnyHashable? = nil,
        dependency dependencyProvider: @escaping () async throws -> Dependency
    ) where Dependency: Sendable {
        _ = dependencyProvider
        _ = key
        // Async providers are unobserved; register nothing and let get() fail closed.
    }

    public func add<Dependency>(
        key: AnyHashable? = nil,
        dependency dependencyProvider: @autoclosure @escaping () -> () throws -> Dependency
    ) where Dependency: Sendable {
        let resolvedKey: AnyHashable = key ?? AnyHashable(String(describing: Dependency.self))
        do {
            let value = try dependencyProvider()()
            lock.lock()
            values[resolvedKey] = value
            lock.unlock()
        } catch {
            _ = error
        }
    }

    public func add<Dependency>(
        key: AnyHashable? = nil,
        dependency dependencyProvider: @autoclosure @escaping () -> Dependency
    ) where Dependency: Sendable {
        let resolvedKey: AnyHashable = key ?? AnyHashable(String(describing: Dependency.self))
        let value = dependencyProvider()
        lock.lock()
        values[resolvedKey] = value
        lock.unlock()
    }

    /// Linux get() is the fail-closed substitute for Apple's crash-on-missing.
    /// Measured: missing key throws `failedToRetrieveDependency`
    /// (testAppDependencyManagerRegisterGetFailClosed). Associated values on
    /// Apple's Error cases are unobserved.
    public func get<Dependency>(
        _ type: Dependency.Type = Dependency.self,
        key: AnyHashable? = nil
    ) throws -> Dependency {
        let resolvedKey: AnyHashable = key ?? AnyHashable(String(describing: type))
        lock.lock()
        let stored = values[resolvedKey]
        lock.unlock()
        guard let stored else {
            throw Error<Dependency>.failedToRetrieveDependency
        }
        guard let typed = stored as? Dependency else {
            throw Error<Dependency>.incorrectDependencyType
        }
        return typed
    }

    public func reset() {
        lock.lock()
        values.removeAll()
        lock.unlock()
    }
}

@dynamicMemberLookup
public class IntentProjection<Intent: AppIntent>: NSObject, @unchecked Sendable {
    public let intent: Intent

    public init(_ intent: Intent) {
        self.intent = intent
        super.init()
    }

    public subscript<Value: _IntentValue>(
        dynamicMember keyPath: KeyPath<Intent, Value>
    ) -> Value.UnwrappedType {
        let value = intent[keyPath: keyPath]
        guard let unwrapped = value as? Value.UnwrappedType else {
            preconditionFailure("IntentProjection dynamic member is not UnwrappedType")
        }
        return unwrapped
    }
}

public class EqualToComparator<Property, PropertyType, ComparatorMappingType>: NSObject, @unchecked Sendable {
    public override init() { super.init() }
}

public class ContainsComparator<Property, PropertyType, InputType, ComparatorMappingType>: NSObject, @unchecked Sendable {
    public override init() { super.init() }
}

public class LessThanComparator<Property, PropertyType, ComparatorMappingType>: NSObject, @unchecked Sendable {
    public override init() { super.init() }
}

public class EntityQueryProperty<Entity, Subject, Property, PropertyType, ComparatorMappingType>: NSObject, @unchecked Sendable {
    public override init() { super.init() }
}

public class HasPrefixComparator<Property, PropertyType, InputType, ComparatorMappingType>: NSObject, @unchecked Sendable {
    public override init() { super.init() }
}

public class HasSuffixComparator<Property, PropertyType, InputType, ComparatorMappingType>: NSObject, @unchecked Sendable {
    public override init() { super.init() }
}

public class IsBetweenComparator<Property, PropertyType, InputType, ComparatorMappingType>: NSObject, @unchecked Sendable {
    public override init() { super.init() }
}

public class NotEqualToComparator<Property, PropertyType, ComparatorMappingType>: NSObject, @unchecked Sendable {
    public override init() { super.init() }
}

public class EntityQueryComparator<Property, PropertyType, InputType, ComparatorMappingType>: NSObject, @unchecked Sendable {
    public override init() { super.init() }
}

public class GreaterThanComparator<Property, PropertyType, ComparatorMappingType>: NSObject, @unchecked Sendable {
    public override init() { super.init() }
}

public class RelevantIntentManager: NSObject, @unchecked Sendable {
    public override init() { super.init() }
}

public class LessThanOrEqualToComparator<Property, PropertyType, ComparatorMappingType>: NSObject, @unchecked Sendable {
    public override init() { super.init() }
}

public class EntityQueryPropertyDeclaration<Entity, ComparatorMappingType>: NSObject, @unchecked Sendable {
    public override init() { super.init() }
}

public class GreaterThanOrEqualToComparator<Property, PropertyType, ComparatorMappingType>: NSObject, @unchecked Sendable {
    public override init() { super.init() }
}

