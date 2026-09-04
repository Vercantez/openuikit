import Foundation

// Additional AppIntents classes from the sealed public surface.

@propertyWrapper public class AppDependency<Value>: NSObject, @unchecked Sendable {
    public override init() { super.init() }

    public var wrappedValue: Value? { get { nil } set { } }
}

public class AppDependencyManager: NSObject, @unchecked Sendable {
    public override init() { super.init() }
    public enum Error: Hashable, Sendable {
        case failedToLoadDependency
        case failedToRetrieveDependency
        case incorrectDependencyType
    }
}

public class IntentProjection<Intent>: NSObject, @unchecked Sendable {
    public override init() { super.init() }
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

