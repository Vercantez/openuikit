// SwiftUI S1/S1.5: source-compatible view composition backed by OpenUIKit.
//
// This is deliberately a small, honest implementation.  It covers the
// stateless syntax used by Focus's SearchWidgetView and DesignSystem previews,
// turning that syntax into an OpenUIKit hierarchy.  It is not a claim that
// arbitrary SwiftUI works.

#if canImport(Foundation)
@_exported import Foundation
#endif
@_exported import OpenUIKit

@MainActor
public protocol _OpenView {
    associatedtype Body: _OpenView

    @_OpenViewBuilder var body: Body { get }

    /// Underscored implementation hook used by the OpenUIKit host.  App view
    /// types receive the body-based default and do not implement this method.
    func _makeOpenUIKitNode() -> _OpenViewNode
}

public extension _OpenView {
    func _makeOpenUIKitNode() -> _OpenViewNode {
        body._makeOpenUIKitNode()
    }
}

public extension _OpenView where Body == Never {
    var body: Never {
        fatalError("primitive SwiftUI views do not evaluate Never.body")
    }
}

/// Opaque public carrier required by _OpenView's public implementation hook.
/// Its representation is intentionally internal to the SwiftUI module.
@MainActor
public final class _OpenViewNode {
    let kind: _OpenViewNodeKind

    init(_ kind: _OpenViewNodeKind) {
        self.kind = kind
    }
}

indirect enum _OpenViewNodeKind {
    case empty
    case group([_OpenViewNode])
    case text(String)
    case image(_OpenImageSource)
    case color(Color)
    case roundedRectangle(cornerRadius: CGFloat, style: _OpenRoundedRectangleStyle)
    case spacer(minLength: CGFloat?)
    case hStack(children: [_OpenViewNode], alignment: VerticalAlignment, spacing: CGFloat?)
    case vStack(children: [_OpenViewNode], alignment: HorizontalAlignment, spacing: CGFloat?)
    case form(rows: [_OpenViewNode])
    case navigation(content: _OpenViewNode, title: String?)
    case gradient(Gradient, UnitPoint, UnitPoint)
    case modified(_OpenViewNode, _OpenViewModification)
}

enum _OpenRoundedRectangleStyle {
    case fill(Color?)
    case stroke(Color, lineWidth: CGFloat)
}

enum _OpenViewModification {
    case font(Font?)
    case fontWeight(Font.Weight?)
    case minimumScaleFactor(CGFloat)
    case foregroundColor(Color?)
    case frame(width: CGFloat?, height: CGFloat?, alignment: Alignment)
    case padding(Edge.Set, CGFloat?)
    case background(_OpenViewNode, alignment: Alignment)
    case overlay(_OpenViewNode, alignment: Alignment)
    case resizable
    case aspectRatio(ContentMode)
    case previewLayout(PreviewLayout)
    case clipRoundedRectangle(CGFloat)
    case navigationTitle(String)
}

extension Never: _OpenView {
    public typealias Body = Never

    public var body: Never {
        fatalError("primitive SwiftUI views do not evaluate Never.body")
    }

    public func _makeOpenUIKitNode() -> _OpenViewNode {
        fatalError("Never has no renderable node")
    }
}

@MainActor
@resultBuilder
public enum _OpenViewBuilder {
    public static func buildExpression<Content: _OpenView>(_ content: Content) -> Content {
        content
    }

    public static func buildBlock() -> _OpenEmptyView {
        _OpenEmptyView()
    }

    public static func buildBlock<Content: _OpenView>(_ content: Content) -> Content {
        content
    }

    public static func buildBlock<C0: _OpenView, C1: _OpenView>(
        _ c0: C0,
        _ c1: C1
    ) -> _OpenTupleView<(C0, C1)> {
        _OpenTupleView((c0, c1), nodes: { [c0._makeOpenUIKitNode(), c1._makeOpenUIKitNode()] })
    }

    public static func buildBlock<C0: _OpenView, C1: _OpenView, C2: _OpenView>(
        _ c0: C0,
        _ c1: C1,
        _ c2: C2
    ) -> _OpenTupleView<(C0, C1, C2)> {
        _OpenTupleView(
            (c0, c1, c2),
            nodes: {
                [c0._makeOpenUIKitNode(), c1._makeOpenUIKitNode(), c2._makeOpenUIKitNode()]
            }
        )
    }

    public static func buildOptional<Content: _OpenView>(_ component: Content?) -> Content? {
        component
    }

    public static func buildEither<TrueContent: _OpenView, FalseContent: _OpenView>(
        first component: TrueContent
    ) -> _OpenConditionalContent<TrueContent, FalseContent> {
        _OpenConditionalContent(first: component)
    }

    public static func buildEither<TrueContent: _OpenView, FalseContent: _OpenView>(
        second component: FalseContent
    ) -> _OpenConditionalContent<TrueContent, FalseContent> {
        _OpenConditionalContent(second: component)
    }

    public static func buildArray<Content: _OpenView>(_ components: [Content]) -> _OpenViewArray<Content> {
        _OpenViewArray(components)
    }

    public static func buildLimitedAvailability<Content: _OpenView>(_ component: Content) -> Content {
        component
    }
}

public struct _OpenEmptyView: _OpenView {
    public typealias Body = Never

    public init() {}

    public func _makeOpenUIKitNode() -> _OpenViewNode {
        _OpenViewNode(.empty)
    }
}

public struct _OpenTupleView<T>: _OpenView {
    public typealias Body = Never
    public let value: T
    private let nodeBuilder: @MainActor () -> [_OpenViewNode]

    init(_ value: T, nodes: @escaping @MainActor () -> [_OpenViewNode]) {
        self.value = value
        self.nodeBuilder = nodes
    }

    public func _makeOpenUIKitNode() -> _OpenViewNode {
        _OpenViewNode(.group(nodeBuilder()))
    }
}

public struct _OpenConditionalContent<TrueContent: _OpenView, FalseContent: _OpenView>: _OpenView {
    public typealias Body = Never
    private let nodeBuilder: @MainActor () -> _OpenViewNode

    init(first content: TrueContent) {
        nodeBuilder = { content._makeOpenUIKitNode() }
    }

    init(second content: FalseContent) {
        nodeBuilder = { content._makeOpenUIKitNode() }
    }

    public func _makeOpenUIKitNode() -> _OpenViewNode {
        nodeBuilder()
    }
}

public struct _OpenViewArray<Content: _OpenView>: _OpenView {
    public typealias Body = Never
    private let components: [Content]

    init(_ components: [Content]) {
        self.components = components
    }

    public func _makeOpenUIKitNode() -> _OpenViewNode {
        _OpenViewNode(.group(components.map { $0._makeOpenUIKitNode() }))
    }
}

extension Optional: _OpenView where Wrapped: _OpenView {
    public typealias Body = Never

    public func _makeOpenUIKitNode() -> _OpenViewNode {
        switch self {
        case .some(let wrapped): return wrapped._makeOpenUIKitNode()
        case .none: return _OpenViewNode(.empty)
        }
    }
}

public struct _OpenText: _OpenView {
    public typealias Body = Never
    public let content: String

    public init(_ content: String) {
        self.content = content
    }

    public func _makeOpenUIKitNode() -> _OpenViewNode {
        _OpenViewNode(.text(content))
    }
}

public struct _OpenImage: _OpenView {
    public typealias Body = Never
    let source: _OpenImageSource

    public init(systemName: String) {
        source = .system(name: systemName)
    }

    public init(_ name: String, bundle: Bundle? = nil) {
        source = .named(name: name, bundle: bundle)
    }

    public init(uiImage: UIImage) {
        source = .uiImage(uiImage)
    }

    public func _makeOpenUIKitNode() -> _OpenViewNode {
        _OpenViewNode(.image(source))
    }

    public func resizable() -> some _OpenView {
        _OpenModifiedContent(content: self, modification: .resizable)
    }
}

enum _OpenImageSource {
    case system(name: String)
    case named(name: String, bundle: Bundle?)
    case uiImage(UIImage)
}

extension _OpenColor: _OpenView {
    public typealias Body = Never

    public func _makeOpenUIKitNode() -> _OpenViewNode {
        _OpenViewNode(.color(self))
    }
}

extension _OpenRoundedRectangle: _OpenView {
    public typealias Body = Never

    public func _makeOpenUIKitNode() -> _OpenViewNode {
        _OpenViewNode(.roundedRectangle(cornerRadius: cornerRadius, style: .fill(nil)))
    }

    public func stroke(_ color: Color, lineWidth: CGFloat = 1) -> some _OpenView {
        _OpenRoundedRectangleStroke(
            cornerRadius: cornerRadius,
            color: color,
            lineWidth: lineWidth
        )
    }
}

public struct _OpenRoundedRectangleStroke: _OpenView {
    public typealias Body = Never
    public let cornerRadius: CGFloat
    public let color: Color
    public let lineWidth: CGFloat

    public func _makeOpenUIKitNode() -> _OpenViewNode {
        _OpenViewNode(
            .roundedRectangle(
                cornerRadius: cornerRadius,
                style: .stroke(color, lineWidth: max(0, lineWidth))
            )
        )
    }
}

public struct _OpenSpacer: _OpenView {
    public typealias Body = Never
    public let minLength: CGFloat?

    public init(minLength: CGFloat? = nil) {
        self.minLength = minLength
    }

    public func _makeOpenUIKitNode() -> _OpenViewNode {
        _OpenViewNode(.spacer(minLength: minLength))
    }
}

public struct _OpenHStack<Content: _OpenView>: _OpenView {
    public typealias Body = Never
    public let alignment: VerticalAlignment
    public let spacing: CGFloat?
    public let content: Content

    public init(
        alignment: VerticalAlignment = .center,
        spacing: CGFloat? = nil,
        @_OpenViewBuilder content: () -> Content
    ) {
        self.alignment = alignment
        self.spacing = spacing
        self.content = content()
    }

    public func _makeOpenUIKitNode() -> _OpenViewNode {
        _OpenViewNode(
            .hStack(
                children: _flattenGroup(content._makeOpenUIKitNode()),
                alignment: alignment,
                spacing: spacing
            )
        )
    }
}

public struct _OpenVStack<Content: _OpenView>: _OpenView {
    public typealias Body = Never
    public let alignment: HorizontalAlignment
    public let spacing: CGFloat?
    public let content: Content

    public init(
        alignment: HorizontalAlignment = .center,
        spacing: CGFloat? = nil,
        @_OpenViewBuilder content: () -> Content
    ) {
        self.alignment = alignment
        self.spacing = spacing
        self.content = content()
    }

    public func _makeOpenUIKitNode() -> _OpenViewNode {
        _OpenViewNode(
            .vStack(
                children: _flattenGroup(content._makeOpenUIKitNode()),
                alignment: alignment,
                spacing: spacing
            )
        )
    }
}

/// Static settings-form subset.  Each top-level child becomes an ordered,
/// minimum-44-point row backed by an OpenUIKit view hierarchy.
public struct _OpenForm<Content: _OpenView>: _OpenView {
    public typealias Body = Never
    public let content: Content

    public init(@_OpenViewBuilder content: () -> Content) {
        self.content = content()
    }

    public func _makeOpenUIKitNode() -> _OpenViewNode {
        _OpenViewNode(.form(rows: _flattenGroup(content._makeOpenUIKitNode())))
    }
}

/// Eager, stateless collection expansion used by the DesignSystem previews.
/// Identity is accepted for source compatibility; S1.5 does not diff updates.
public struct _OpenForEach<Data, ID, Content>: _OpenView
where Data: RandomAccessCollection, ID: Hashable, Content: _OpenView {
    public typealias Body = Never
    public let data: Data
    private let contentBuilder: @MainActor (Data.Element) -> Content

    public init(
        _ data: Data,
        id: KeyPath<Data.Element, ID>,
        @_OpenViewBuilder content: @escaping @MainActor (Data.Element) -> Content
    ) {
        self.data = data
        _ = id
        contentBuilder = content
    }

    public func _makeOpenUIKitNode() -> _OpenViewNode {
        _OpenViewNode(.group(data.map { contentBuilder($0)._makeOpenUIKitNode() }))
    }
}

public struct _OpenNavigationView<Content: _OpenView>: _OpenView {
    public typealias Body = Never
    public let content: Content

    public init(@_OpenViewBuilder content: () -> Content) {
        self.content = content()
    }

    public func _makeOpenUIKitNode() -> _OpenViewNode {
        let (node, title) = _extractNavigationTitle(content._makeOpenUIKitNode())
        return _OpenViewNode(.navigation(content: node, title: title))
    }
}

public struct _OpenLinearGradient: _OpenView {
    public typealias Body = Never
    public let gradient: Gradient
    public let startPoint: UnitPoint
    public let endPoint: UnitPoint

    public init(gradient: Gradient, startPoint: UnitPoint, endPoint: UnitPoint) {
        self.gradient = gradient
        self.startPoint = startPoint
        self.endPoint = endPoint
    }

    public func _makeOpenUIKitNode() -> _OpenViewNode {
        _OpenViewNode(.gradient(gradient, startPoint, endPoint))
    }
}

public struct _OpenModifiedContent<Content: _OpenView>: _OpenView {
    public typealias Body = Never
    let content: Content
    let modification: _OpenViewModification

    public func _makeOpenUIKitNode() -> _OpenViewNode {
        _OpenViewNode(.modified(content._makeOpenUIKitNode(), modification))
    }
}

public extension _OpenView {
    func font(_ font: Font?) -> some _OpenView {
        _OpenModifiedContent(content: self, modification: .font(font))
    }

    func fontWeight(_ weight: Font.Weight?) -> some _OpenView {
        _OpenModifiedContent(content: self, modification: .fontWeight(weight))
    }

    func minimumScaleFactor(_ factor: CGFloat) -> some _OpenView {
        _OpenModifiedContent(content: self, modification: .minimumScaleFactor(factor))
    }

    func foregroundColor(_ color: Color?) -> some _OpenView {
        _OpenModifiedContent(content: self, modification: .foregroundColor(color))
    }

    func frame(
        width: CGFloat? = nil,
        height: CGFloat? = nil,
        alignment: Alignment = .center
    ) -> some _OpenView {
        _OpenModifiedContent(
            content: self,
            modification: .frame(width: width, height: height, alignment: alignment)
        )
    }

    func padding(_ edges: Edge.Set = .all, _ length: CGFloat? = nil) -> some _OpenView {
        _OpenModifiedContent(content: self, modification: .padding(edges, length))
    }

    func background<Background: _OpenView>(
        _ background: Background,
        alignment: Alignment = .center
    ) -> some _OpenView {
        _OpenModifiedContent(
            content: self,
            modification: .background(background._makeOpenUIKitNode(), alignment: alignment)
        )
    }

    func overlay<Overlay: _OpenView>(
        _ overlay: Overlay,
        alignment: Alignment = .center
    ) -> some _OpenView {
        _OpenModifiedContent(
            content: self,
            modification: .overlay(overlay._makeOpenUIKitNode(), alignment: alignment)
        )
    }

    func aspectRatio(contentMode: ContentMode) -> some _OpenView {
        _OpenModifiedContent(content: self, modification: .aspectRatio(contentMode))
    }

    func previewLayout(_ value: PreviewLayout) -> some _OpenView {
        _OpenModifiedContent(content: self, modification: .previewLayout(value))
    }

    func clipShape<S: Shape>(_ shape: S) -> some _OpenView {
        let radius = (shape as? RoundedRectangle)?.cornerRadius ?? 0
        return _OpenModifiedContent(
            content: self,
            modification: .clipRoundedRectangle(radius)
        )
    }

    func navigationTitle(_ title: String) -> some _OpenView {
        _OpenModifiedContent(content: self, modification: .navigationTitle(title))
    }
}

@MainActor
private func _flattenGroup(_ node: _OpenViewNode) -> [_OpenViewNode] {
    if case .group(let children) = node.kind {
        return children.flatMap { _flattenGroup($0) }
    }
    return [node]
}

@MainActor
private func _extractNavigationTitle(_ node: _OpenViewNode) -> (_OpenViewNode, String?) {
    if case .modified(let content, .navigationTitle(let title)) = node.kind {
        return (content, title)
    }
    return (node, nil)
}

public protocol _OpenPreviewProvider {
    associatedtype Previews: _OpenView
    @_OpenViewBuilder @MainActor static var previews: Previews { get }
}

// Public source-compatible spellings.  See Values.swift for why the runtime
// nominal names are distinct when an Apple SDK is present.
public typealias View = _OpenView
public typealias ViewBuilder = _OpenViewBuilder
public typealias EmptyView = _OpenEmptyView
public typealias TupleView<T> = _OpenTupleView<T>
public typealias _ConditionalContent<TrueContent, FalseContent> =
    _OpenConditionalContent<TrueContent, FalseContent>
    where TrueContent: _OpenView, FalseContent: _OpenView
public typealias Text = _OpenText
public typealias Image = _OpenImage
public typealias Spacer = _OpenSpacer
public typealias HStack<Content> = _OpenHStack<Content> where Content: _OpenView
public typealias VStack<Content> = _OpenVStack<Content> where Content: _OpenView
public typealias Form<Content> = _OpenForm<Content> where Content: _OpenView
public typealias ForEach<Data, ID, Content> = _OpenForEach<Data, ID, Content>
    where Data: RandomAccessCollection, ID: Hashable, Content: _OpenView
public typealias NavigationView<Content> = _OpenNavigationView<Content> where Content: _OpenView
public typealias LinearGradient = _OpenLinearGradient
public typealias PreviewProvider = _OpenPreviewProvider
