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
    public var red: Double
    public var green: Double
    public var blue: Double
    public var opacityValue: Double

    public init() {
        red = 0
        green = 0
        blue = 0
        opacityValue = 1
    }

    public init(_ name: String) {
        _ = name
        self.init()
    }

    public init(red: Double, green: Double, blue: Double, opacity: Double = 1) {
        self.red = red
        self.green = green
        self.blue = blue
        self.opacityValue = opacity
    }

    public static let clear = Color(red: 0, green: 0, blue: 0, opacity: 0)
    public static let blue = Color(red: 0, green: 0, blue: 1)
    public static let black = Color(red: 0, green: 0, blue: 0)
    public static let white = Color(red: 1, green: 1, blue: 1)
    public static let primary = Color(red: 0, green: 0, blue: 0)
    public static let secondary = Color(red: 0.5, green: 0.5, blue: 0.5)

    public func opacity(_ opacity: Double) -> Color {
        Color(red: red, green: green, blue: blue, opacity: opacity)
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
    public enum Element: Equatable, Sendable {
        case move(CGPoint)
        case line(CGPoint)
        case close
        case rect(CGRect)
        case ellipse(CGRect)
    }

    public var elements: [Element]

    public init() { elements = [] }

    public init(_ rect: CGRect) {
        elements = [.rect(rect)]
    }

    public mutating func move(to point: CGPoint) {
        elements.append(.move(point))
    }

    public mutating func addLine(to point: CGPoint) {
        elements.append(.line(point))
    }

    public mutating func addLines(_ points: [CGPoint]) {
        guard let first = points.first else { return }
        if elements.isEmpty {
            move(to: first)
            for point in points.dropFirst() { addLine(to: point) }
        } else {
            for point in points { addLine(to: point) }
        }
    }

    public mutating func addRect(_ rect: CGRect) {
        elements.append(.rect(rect))
    }

    public mutating func addEllipse(in rect: CGRect) {
        elements.append(.ellipse(rect))
    }

    public mutating func closeSubpath() {
        elements.append(.close)
    }

    public var cgRects: [CGRect] {
        elements.compactMap {
            if case .rect(let rect) = $0 { return rect }
            return nil
        }
    }

    public var polylines: [[CGPoint]] {
        var lines: [[CGPoint]] = []
        var current: [CGPoint] = []
        for element in elements {
            switch element {
            case .move(let point):
                if !current.isEmpty { lines.append(current) }
                current = [point]
            case .line(let point):
                if current.isEmpty { current = [point] }
                else { current.append(point) }
            case .close:
                if let first = current.first { current.append(first) }
                if !current.isEmpty { lines.append(current) }
                current = []
            case .rect, .ellipse:
                if !current.isEmpty { lines.append(current) }
                current = []
            }
        }
        if !current.isEmpty { lines.append(current) }
        return lines
    }
}

public protocol Shape: View {
    func path(in rect: CGRect) -> Path
}

public struct FillStyle: Hashable, Sendable {
    public var isEOFilled: Bool
    public init(eoFill: Bool = false, antialiased: Bool = true) {
        _ = antialiased
        isEOFilled = eoFill
    }
}

public struct RoundedCornerStyle: Hashable, Sendable {
    public static let circular = RoundedCornerStyle()
    public static let continuous = RoundedCornerStyle()
    public init() {}
}

public enum Axis: Hashable, Sendable {
    case horizontal
    case vertical
}

public struct UnitPoint: Hashable, Sendable {
    public var x: CGFloat
    public var y: CGFloat
    public init(x: CGFloat = 0, y: CGFloat = 0) {
        self.x = x
        self.y = y
    }
    public static let center = UnitPoint(x: 0.5, y: 0.5)
    public static let top = UnitPoint(x: 0.5, y: 0)
    public static let bottom = UnitPoint(x: 0.5, y: 1)
    public static let leading = UnitPoint(x: 0, y: 0.5)
    public static let trailing = UnitPoint(x: 1, y: 0.5)
}

public struct Font: Hashable, Sendable {
    public static let body = Font()
    public static let caption = Font()
    public init() {}
}

public struct GraphicsContext {
    public struct Shading: Hashable, Sendable {
        public var color: Color
        public static func color(_ color: Color) -> Shading {
            Shading(color: color)
        }
    }

    public var bitmap: ChartBitmap

    public init(width: Int, height: Int) {
        bitmap = ChartBitmap(width: width, height: height)
    }

    public init(bitmap: ChartBitmap) {
        self.bitmap = bitmap
    }

    public mutating func fill(
        _ path: Path,
        with shading: Shading,
        style: FillStyle = FillStyle()
    ) {
        _ = style
        let packed = ChartBitmap.pack(
            red: shading.color.red,
            green: shading.color.green,
            blue: shading.color.blue,
            opacity: shading.color.opacityValue
        )
        for rect in path.cgRects {
            bitmap.fillRect(rect, color: packed)
        }
        for line in path.polylines where line.count >= 3 {
            bitmap.fillPolygon(line, color: packed)
        }
        for element in path.elements {
            if case .ellipse(let rect) = element {
                bitmap.fillEllipse(rect, color: packed)
            }
        }
    }

    public mutating func stroke(
        _ path: Path,
        with shading: Shading,
        lineWidth: CGFloat = 1
    ) {
        let packed = ChartBitmap.pack(
            red: shading.color.red,
            green: shading.color.green,
            blue: shading.color.blue,
            opacity: shading.color.opacityValue
        )
        for line in path.polylines {
            bitmap.strokePolyline(line, color: packed, width: max(1, Int(lineWidth.rounded())))
        }
        for rect in path.cgRects {
            bitmap.strokeRect(rect, color: packed, width: max(1, Int(lineWidth.rounded())))
        }
    }

    public mutating func stroke(
        _ path: Path,
        with shading: Shading,
        style: StrokeStyle
    ) {
        stroke(path, with: shading, lineWidth: style.lineWidth)
    }
}

public struct Canvas<Symbols: View>: View {
    let renderer: (inout GraphicsContext, CGSize) -> Void
    let symbols: Symbols

    public init(
        opaque: Bool = false,
        colorMode: Int = 0,
        rendersAsynchronously: Bool = false,
        renderer: @escaping (inout GraphicsContext, CGSize) -> Void,
        @ViewBuilder symbols: () -> Symbols
    ) {
        _ = opaque
        _ = colorMode
        _ = rendersAsynchronously
        self.renderer = renderer
        self.symbols = symbols()
    }

    public var body: some View { symbols }

    public func render(size: CGSize) -> ChartBitmap {
        var context = GraphicsContext(
            width: max(1, Int(size.width.rounded())),
            height: max(1, Int(size.height.rounded()))
        )
        renderer(&context, size)
        return context.bitmap
    }
}

public extension Canvas where Symbols == EmptyView {
    init(
        opaque: Bool = false,
        renderer: @escaping (inout GraphicsContext, CGSize) -> Void
    ) {
        self.init(opaque: opaque, renderer: renderer, symbols: { EmptyView() })
    }
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
