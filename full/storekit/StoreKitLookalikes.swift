import Foundation

// Module-local lookalikes for isolated Linux host compilation. The sealed
// StoreKit seed lists only Foundation as a dependency. UIKit/SwiftUI types
// appear in StoreKit signatures; they are not imported here. The EC2 probe
// `tests/agent/StoreKitDependencyIdentity.swift` carries real module imports.

#if !canImport(UIKit) && !canImport(OpenUIKit)
open class UIScene: NSObject {
    public override init() { super.init() }
}

open class UIWindowScene: UIScene {
    public override init() { super.init() }
}

open class UIViewController: NSObject {
    public override init() { super.init() }
}
#endif

#if !canImport(SwiftUI)

public protocol View {
    associatedtype Body: View
    var body: Body { get }
}

public struct EmptyView: View {
    public init() {}
    public var body: EmptyView { self }
}

@resultBuilder
public enum ViewBuilder {
    public static func buildBlock() -> EmptyView { EmptyView() }
    public static func buildBlock<Content: View>(_ content: Content) -> Content { content }
    public static func buildOptional<Content: View>(_ content: Content?) -> Content? { content }
    public static func buildEither<TrueContent: View>(first: TrueContent) -> TrueContent { first }
    public static func buildEither<FalseContent: View>(second: FalseContent) -> FalseContent { second }
    public static func buildExpression<Content: View>(_ content: Content) -> Content { content }
}

@propertyWrapper
public struct Binding<Value> {
    public var wrappedValue: Value
    public var projectedValue: Binding<Value> { self }

    public init(get: @escaping () -> Value, set: @escaping (Value) -> Void) {
        wrappedValue = get()
        _ = set
    }

    public init(wrappedValue: Value) {
        self.wrappedValue = wrappedValue
    }

    public static func constant(_ value: Value) -> Binding<Value> {
        Binding(wrappedValue: value)
    }
}

public struct LocalizedStringKey: ExpressibleByStringLiteral, Hashable, Sendable {
    public var value: String
    public init(stringLiteral value: String) { self.value = value }
    public init(_ value: String) { self.value = value }
}

public struct LocalizedStringResource: Hashable, Sendable, ExpressibleByStringLiteral {
    public var value: String
    public init(stringLiteral value: String) { self.value = value }
    public init(_ value: String) { self.value = value }
}

public struct Text: View {
    public struct LineStyle: Hashable, Sendable {
        public struct Pattern: Hashable, Sendable {
            public static let solid = Pattern()
            public init() {}
        }
        public init() {}
    }
    public struct AlignmentStrategy: Hashable, Sendable { public init() {} }
    public struct Case: Hashable, Sendable { public init() {} }
    public struct Scale: Hashable, Sendable { public init() {} }
    public struct TruncationMode: Hashable, Sendable { public init() {} }
    public struct WritingDirectionStrategy: Hashable, Sendable { public init() {} }
    public init(_ key: LocalizedStringKey) { _ = key }
    public init(_ resource: LocalizedStringResource) { _ = resource }
    public init<S: StringProtocol>(_ text: S) { _ = text }
    public var body: EmptyView { EmptyView() }
}

public struct Color: View, Hashable, Sendable {
    public enum RGBColorSpace: Hashable, Sendable { case sRGB, sRGBLinear }
    public static let clear = Color()
    public static let primary = Color()
    public static let secondary = Color()
    public init() {}
    public init(_ colorSpace: RGBColorSpace, white: Double, opacity: Double) {
        _ = colorSpace
        _ = white
        _ = opacity
    }
    public var body: EmptyView { EmptyView() }
}

public struct Image: View {
    public struct Scale: Hashable, Sendable { public init() {} }
    public struct DynamicRange: Hashable, Sendable { public init() {} }
    public init() {}
    public var body: EmptyView { EmptyView() }
}

public enum Visibility: Hashable, Sendable {
    case automatic
    case visible
    case hidden
}

public protocol ShapeStyle {}
extension Color: ShapeStyle {}

public protocol Shape {}
public struct Rectangle: Shape {
    public init() {}
}

public struct UnitPoint: Hashable, Sendable {
    public var x: CGFloat
    public var y: CGFloat
    public init(x: CGFloat, y: CGFloat) { self.x = x; self.y = y }
    public static let center = UnitPoint(x: 0.5, y: 0.5)
}

public enum Edge: Hashable, Sendable {
    case top, leading, bottom, trailing
    public struct Set: OptionSet, Sendable {
        public let rawValue: Int
        public init(rawValue: Int) { self.rawValue = rawValue }
        public static let top = Set(rawValue: 1 << 0)
        public static let leading = Set(rawValue: 1 << 1)
        public static let bottom = Set(rawValue: 1 << 2)
        public static let trailing = Set(rawValue: 1 << 3)
        public static let all: Set = [.top, .leading, .bottom, .trailing]
        public static let horizontal: Set = [.leading, .trailing]
        public static let vertical: Set = [.top, .bottom]
    }
}

public struct Alignment: Hashable, Sendable {
    public static let center = Alignment()
    public static let leading = Alignment()
    public static let trailing = Alignment()
    public init() {}
}

public struct HorizontalAlignment: Hashable, Sendable {
    public static let center = HorizontalAlignment()
    public static let leading = HorizontalAlignment()
    public static let trailing = HorizontalAlignment()
    public init() {}
}

public enum VerticalEdge: Hashable, Sendable {
    case top, bottom
    public struct Set: OptionSet, Sendable {
        public let rawValue: Int
        public init(rawValue: Int) { self.rawValue = rawValue }
        public static let top = Set(rawValue: 1)
        public static let bottom = Set(rawValue: 2)
        public static let all: Set = [.top, .bottom]
    }
}

public enum Axis: Hashable, Sendable {
    case horizontal, vertical
    public struct Set: OptionSet, Sendable {
        public let rawValue: Int
        public init(rawValue: Int) { self.rawValue = rawValue }
        public static let horizontal = Set(rawValue: 1)
        public static let vertical = Set(rawValue: 2)
        public static let both: Set = [.horizontal, .vertical]
    }
}

public struct SearchFieldPlacement: Hashable, Sendable {
    public static let automatic = SearchFieldPlacement()
    public init() {}
}

public struct ToolbarPlacement: Hashable, Sendable {
    public static let automatic = ToolbarPlacement()
    public init() {}
}

public struct Animation: Hashable, Sendable {
    public static let `default` = Animation()
    public init() {}
}

public struct Namespace: Hashable {
    public struct ID: Hashable { public init() {} }
    public init() {}
}

public struct ModifiedContent<Content, Modifier>: View {
    public var body: EmptyView { EmptyView() }
}

public struct AccessibilityAttachmentModifier {}

public struct PlaceholderContentView<Value>: View {
    public var body: EmptyView { EmptyView() }
}

public protocol PreferenceKey {
    associatedtype Value
    static var defaultValue: Value { get }
}

public protocol Gesture {}
public protocol Transferable {}
public protocol FileDocument {}
public protocol AccessibilityRotorContent {}
public protocol ObservableObject: AnyObject {}

@resultBuilder
public enum AccessibilityRotorContentBuilder {
    public static func buildBlock() -> EmptyView { EmptyView() }
    public static func buildBlock<Content>(_ content: Content) -> Content { content }
}

public struct AccessibilitySystemRotor: Hashable, Sendable {
    public init() {}
}

public struct AccessibilityTraits: OptionSet, Sendable {
    public let rawValue: Int
    public init(rawValue: Int) { self.rawValue = rawValue }
}

public struct AccessibilityCustomContentKey: Hashable, Sendable {
    public init(_ label: String) { _ = label }
}

public enum AXCustomContent {
    public enum Importance: Hashable, Sendable {
        case `default`
        case high
    }
}

public struct FillStyle: Hashable, Sendable {
    public init() {}
}

public struct KeyPress: Hashable, Sendable {
    public struct Result: Hashable, Sendable {
        public static let handled = Result()
        public static let ignored = Result()
        public init() {}
    }
    public struct Phases: OptionSet, Sendable {
        public let rawValue: Int
        public init(rawValue: Int) { self.rawValue = rawValue }
        public static let down = Phases(rawValue: 1)
        public static let up = Phases(rawValue: 2)
        public static let `repeat` = Phases(rawValue: 4)
        public static let all: Phases = [.down, .up, .repeat]
    }
    public init() {}
}

public struct KeyEquivalent: Hashable, Sendable {
    public init() {}
}

public struct UTType: Hashable, Sendable {
    public var identifier: String
    public init(identifier: String) { self.identifier = identifier }
}

open class NSItemProvider: NSObject {
    public override init() { super.init() }
}

@propertyWrapper
public struct FocusState<Value> {
    public struct Binding {
        public var wrappedValue: Value
        public init(wrappedValue: Value) { self.wrappedValue = wrappedValue }
    }
    public var wrappedValue: Value
    public var projectedValue: FocusState<Value>.Binding {
        FocusState.Binding(wrappedValue: wrappedValue)
    }
    public init(wrappedValue: Value) { self.wrappedValue = wrappedValue }
}

public struct Anchor<Value>: Hashable, Sendable {
    public struct Source: Hashable, Sendable {
        public static var bounds: Source { Source() }
        public init() {}
    }
    public init() {}
}

#endif
