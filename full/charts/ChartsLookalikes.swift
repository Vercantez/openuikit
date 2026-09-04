@_exported import Foundation

/// Always-present marker so this compilation unit is never empty on Apple
/// SDKs where the lookalike blocks below are inactive.
enum _ChartsHostLookalikesMarker {}

// Module-local stand-ins for SwiftUI / CoreGraphics types. Isolated Linux
// host compilation imports Foundation only. Real modules are imported by
// tests/agent/ChartsDependencyIdentity.swift for the later EC2 build.
// These lookalikes are compiled only when those modules are absent.

#if !canImport(SwiftUI)

public protocol View {
    associatedtype Body: View
    @ViewBuilder var body: Body { get }
}

extension Never: View {
    public typealias Body = Never
    public var body: Never {
        fatalError("Never has no View body")
    }
}

public struct EmptyView: View {
    public init() {}
    public var body: Never {
        fatalError("EmptyView is a leaf")
    }
}

@resultBuilder
public enum ViewBuilder {
    public static func buildBlock() -> EmptyView { EmptyView() }

    public static func buildBlock<Content: View>(_ content: Content) -> Content {
        content
    }

    public static func buildBlock<C0: View, C1: View>(
        _ c0: C0,
        _ c1: C1
    ) -> _ChartsPairView<C0, C1> {
        _ChartsPairView(first: c0, second: c1)
    }

    public static func buildExpression<Content: View>(_ content: Content) -> Content {
        content
    }

    public static func buildOptional<Content: View>(
        _ content: Content?
    ) -> _ChartsOptionalView<Content> {
        _ChartsOptionalView(content: content)
    }

    public static func buildIf<Content: View>(
        _ content: Content?
    ) -> _ChartsOptionalView<Content> {
        _ChartsOptionalView(content: content)
    }

    public static func buildEither<TrueContent: View, FalseContent: View>(
        first: TrueContent
    ) -> _ChartsEitherView<TrueContent, FalseContent> {
        _ChartsEitherView(storage: .first(first))
    }

    public static func buildEither<TrueContent: View, FalseContent: View>(
        second: FalseContent
    ) -> _ChartsEitherView<TrueContent, FalseContent> {
        _ChartsEitherView(storage: .second(second))
    }
}

public struct _ChartsOptionalView<Content: View>: View {
    let content: Content?
    public var body: some View { EmptyView() }
}

public struct _ChartsEitherView<First: View, Second: View>: View {
    enum Storage {
        case first(First)
        case second(Second)
    }

    let storage: Storage
    public var body: some View { EmptyView() }
}

public struct _ChartsPairView<First: View, Second: View>: View {
    let first: First
    let second: Second

    public var body: some View { first }
}

public struct AnyView: View {
    public init<V: View>(_ view: V) { _ = view }
    public var body: Never {
        fatalError("AnyView is a leaf")
    }
}

public struct VerticalAlignment: Equatable, Sendable {
    public static let top = VerticalAlignment()
    public static let center = VerticalAlignment()
    public static let bottom = VerticalAlignment()
    public init() {}
}

public struct HorizontalAlignment: Equatable, Sendable {
    public static let leading = HorizontalAlignment()
    public static let center = HorizontalAlignment()
    public static let trailing = HorizontalAlignment()
    public init() {}
}

public struct Alignment: Equatable, Sendable {
    public static let center = Alignment()
    public static let leading = Alignment()
    public static let trailing = Alignment()
    public static let top = Alignment()
    public static let bottom = Alignment()
    public init() {}
}

public struct HStack<Content: View>: View {
    let content: Content

    public init(
        alignment: VerticalAlignment = .center,
        spacing: CGFloat? = nil,
        @ViewBuilder content: () -> Content
    ) {
        _ = alignment
        _ = spacing
        self.content = content()
    }

    public var body: some View { content }
}

public struct ZStack<Content: View>: View {
    let content: Content

    public init(
        alignment: Alignment = .center,
        @ViewBuilder content: () -> Content
    ) {
        _ = alignment
        self.content = content()
    }

    public var body: some View { content }
}

public struct ForEach<Data: RandomAccessCollection, ID: Hashable, Content: View>: View {
    public init(
        _ data: Data,
        id: KeyPath<Data.Element, ID>,
        @ViewBuilder content: (Data.Element) -> Content
    ) {
        _ = data
        _ = id
        _ = content
    }

    public var body: some View { EmptyView() }
}

public struct Rectangle: View {
    public init() {}
    public var body: some View { EmptyView() }
}

public struct Circle: View, Shape {
    public init() {}
    public var body: some View { EmptyView() }
    public func path(in rect: CGRect) -> Path {
        _ = rect
        return Path()
    }
}

public struct GeometryProxy: Sendable {
    public var size: CGSize { .zero }
    public init() {}
}

public struct GeometryReader<Content: View>: View {
    public init(@ViewBuilder content: (GeometryProxy) -> Content) {
        _ = content
    }

    public var body: some View { EmptyView() }
}

public struct LocalizedStringKey: ExpressibleByStringLiteral, Hashable, Sendable, CustomStringConvertible {
    public var key: String
    public init(_ key: String) { self.key = key }
    public init(stringLiteral value: String) { self.key = value }
    public var description: String { key }
}

public struct LocalizedStringResource: ExpressibleByStringLiteral, Hashable, Sendable, CustomStringConvertible {
    public var key: String
    public init(_ key: String) { self.key = key }
    public init(stringLiteral value: String) { self.key = value }
    public var description: String { key }
}

public struct Text: View, CustomStringConvertible {
    public let content: String
    public init(_ content: String) { self.content = content }
    public init(_ key: LocalizedStringKey) { self.content = key.key }
    public init(_ resource: LocalizedStringResource) { self.content = resource.key }
    public init<S: StringProtocol>(_ string: S) { self.content = String(string) }
    public var description: String { content }
    public var body: some View { EmptyView() }
}

public protocol ShapeStyle {}

public struct Color: View, ShapeStyle, Hashable, Sendable {
    public init() {}
    public init(_ name: String) { _ = name }
    public static let clear = Color()
    public static let blue = Color()
    public static let black = Color()
    public static let white = Color()
    public static let primary = Color()
    public static let secondary = Color()
    public func opacity(_ opacity: Double) -> Color {
        _ = opacity
        return self
    }
    public var body: some View { EmptyView() }
}

public struct StrokeStyle: Equatable, Hashable, Sendable {
    public var lineWidth: CGFloat
    public var dash: [CGFloat]
    public var dashPhase: CGFloat

    public init(
        lineWidth: CGFloat = 1,
        dash: [CGFloat] = [],
        dashPhase: CGFloat = 0
    ) {
        self.lineWidth = lineWidth
        self.dash = dash
        self.dashPhase = dashPhase
    }
}

public struct Visibility: Equatable, Hashable, Sendable {
    private let rawValue: UInt8
    private init(_ rawValue: UInt8) { self.rawValue = rawValue }
    public static let automatic = Visibility(0)
    public static let visible = Visibility(1)
    public static let hidden = Visibility(2)
}

@propertyWrapper
public struct Binding<Value> {
    public var wrappedValue: Value
    public var projectedValue: Binding<Value> { self }

    public init(wrappedValue: Value) {
        self.wrappedValue = wrappedValue
    }

    public init(get: @escaping () -> Value, set: @escaping (Value) -> Void) {
        self.wrappedValue = get()
        _ = set
    }

    public static func constant(_ value: Value) -> Binding<Value> {
        Binding(wrappedValue: value)
    }
}

public struct AccessibilityChildBehavior: Equatable, Sendable {
    public static let contain = AccessibilityChildBehavior()
    public static let ignore = AccessibilityChildBehavior()
    public static let combine = AccessibilityChildBehavior()
    public init() {}
}

public struct Angle: Hashable, Sendable {
    public var radians: Double
    public init() { self.radians = 0 }
    public init(radians: Double) { self.radians = radians }
    public init(degrees: Double) { self.radians = degrees * .pi / 180 }
    public static func degrees(_ value: Double) -> Angle { Angle(degrees: value) }
    public static func radians(_ value: Double) -> Angle { Angle(radians: value) }
}

public struct Anchor<Value>: Hashable {
    public init() {}
}

public struct AnyShapeStyle: Hashable, Sendable {
    public init() {}
    public init<S: ShapeStyle>(_ style: S) { _ = style }
}

public struct Path: Equatable, Sendable {
    public init() {}
    public init(_ rect: CGRect) { _ = rect }
}

public protocol Shape: View {
    func path(in rect: CGRect) -> Path
}

public struct ShapeRole: Hashable, Sendable {
    public static let fill = ShapeRole()
    public static let stroke = ShapeRole()
    public static let separator = ShapeRole()
    public init() {}
}

public protocol ScrollTargetBehavior {}

public extension View {
    func overlay<Overlay: View>(
        alignment: Alignment = .center,
        @ViewBuilder content: () -> Overlay
    ) -> some View {
        _ = alignment
        _ = content
        return self
    }

    func frame(
        minWidth: CGFloat? = nil,
        idealWidth: CGFloat? = nil,
        maxWidth: CGFloat? = nil,
        minHeight: CGFloat? = nil,
        idealHeight: CGFloat? = nil,
        maxHeight: CGFloat? = nil,
        alignment: Alignment = .center
    ) -> some View {
        _ = minWidth
        _ = idealWidth
        _ = maxWidth
        _ = minHeight
        _ = idealHeight
        _ = maxHeight
        _ = alignment
        return self
    }

    func frame(
        width: CGFloat? = nil,
        height: CGFloat? = nil,
        alignment: Alignment = .center
    ) -> some View {
        _ = width
        _ = height
        _ = alignment
        return self
    }

    func accessibilityElement(
        children: AccessibilityChildBehavior = .ignore
    ) -> some View {
        _ = children
        return self
    }

    func accessibilityLabel(_ label: Text) -> some View {
        _ = label
        return self
    }

    func accessibilityLabel<S: StringProtocol>(_ label: S) -> some View {
        _ = label
        return self
    }

    func foregroundStyle<S: ShapeStyle>(_ style: S) -> some View {
        _ = style
        return self
    }
}

#endif
