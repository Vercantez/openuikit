@_exported import Foundation

// Module-local stand-ins for types owned by undeclared modules (SwiftUI,
// HealthKit, CoreLocation, MapKit). The isolated Linux host compiles
// Foundation only. These lookalikes are compiled only when those modules
// are absent. They are not Linux ports of those frameworks.

#if !canImport(SwiftUI)
public protocol View {
    associatedtype Body: View
    @ViewBuilder var body: Body { get }
}

@resultBuilder
public enum ViewBuilder {
    public static func buildBlock() -> EmptyView {
        EmptyView()
    }

    public static func buildBlock<Content: View>(_ content: Content) -> Content {
        content
    }

    public static func buildExpression<Content: View>(_ content: Content) -> Content {
        content
    }
}

public struct EmptyView: View {
    public init() {}
    public var body: Never { preconditionFailure("EmptyView has no body") }
}

extension Never: View {
    public var body: Never { self }
}

public struct LocalizedStringKey: ExpressibleByStringLiteral, Hashable, Sendable {
    public let rawValue: String

    public init(stringLiteral value: String) {
        rawValue = value
    }
}

public struct Text: View {
    public let storage: String

    public init(_ string: String) {
        storage = string
    }

    public init(_ key: LocalizedStringKey) {
        storage = key.rawValue
    }

    public init<S: StringProtocol>(_ string: S) {
        storage = String(string)
    }

    public var body: EmptyView { EmptyView() }
}

@propertyWrapper
public struct Binding<Value> {
    private let getter: () -> Value
    private let setter: (Value) -> Void

    public var wrappedValue: Value {
        get { getter() }
        nonmutating set { setter(newValue) }
    }

    public var projectedValue: Binding<Value> { self }

    public init(get: @escaping () -> Value, set: @escaping (Value) -> Void) {
        getter = get
        setter = set
    }

    public static func constant(_ value: Value) -> Binding<Value> {
        Binding(get: { value }, set: { _ in })
    }
}

public struct Color: Equatable, Hashable, Sendable {
    public let token: String

    public init(_ token: String) {
        self.token = token
    }

    public static let clear = Color("clear")
}

public struct Gradient: Equatable, Hashable, Sendable {
    public var colors: [Color]

    public init(colors: [Color]) {
        self.colors = colors
    }
}

public struct Image: Equatable, Hashable, Sendable, View {
    public typealias Body = EmptyView

    public let name: String

    public init(_ name: String) {
        self.name = name
    }

    public var body: EmptyView { EmptyView() }
}
#endif

#if !canImport(HealthKit)
public final class HKStateOfMind: NSObject, @unchecked Sendable {
    public let valence: Double

    public init(valence: Double = 0) {
        self.valence = valence
        super.init()
    }
}

public final class HKQuantity: NSObject, @unchecked Sendable {
    public let unitIdentifier: String
    public let doubleValue: Double

    public init(unitIdentifier: String, doubleValue: Double) {
        self.unitIdentifier = unitIdentifier
        self.doubleValue = doubleValue
        super.init()
    }
}

/// Minimal HealthKit activity-type token. `other = 3000` is Apple's documented
/// `HKWorkoutActivityTypeOther` raw value. Other Darwin cases are unobserved.
public struct HKWorkoutActivityType: Equatable, Hashable, Sendable {
    public let rawValue: UInt

    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }

    public static let other = HKWorkoutActivityType(rawValue: 3000)
    public static let running = HKWorkoutActivityType(rawValue: 37)
    public static let walking = HKWorkoutActivityType(rawValue: 52)
}
#endif

#if !canImport(CoreLocation)
public final class CLLocation: NSObject, @unchecked Sendable {
    public let latitude: Double
    public let longitude: Double

    public init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
        super.init()
    }
}
#endif

#if !canImport(MapKit)
public struct MKMapItem: Sendable {
    public struct Identifier: Equatable, Hashable, Sendable {
        public let rawValue: String

        public init(rawValue: String) {
            self.rawValue = rawValue
        }
    }
}
#endif

public enum JournalingSuggestionsUnavailable: Error, Equatable, Sendable {
    case linuxHost(operation: String)
}
