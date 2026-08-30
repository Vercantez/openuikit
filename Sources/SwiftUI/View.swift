// SwiftUI S1/S1.5 composition plus the bounded S2 observation runtime.
//
// This is deliberately a small, honest implementation. It covers the syntax
// used by Focus's SearchWidgetView and DesignSystem previews plus the S2
// state/observation semantics documented in docs/SWIFTUI_S2.md, turning that
// bounded surface into an OpenUIKit hierarchy. It is not a claim that
// arbitrary SwiftUI works.

#if canImport(Foundation)
@_exported import Foundation
#endif
import Combine
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
        _OpenGraphContext.withView(self) { preparedView in
            preparedView.body._makeOpenUIKitNode()
        }
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
    case zStack(children: [_OpenViewNode], alignment: Alignment)
    case button(label: _OpenViewNode, action: @MainActor () -> Void)
    case scroll(content: _OpenViewNode)
    case tabView(
        pages: [_OpenTabPage],
        selection: AnyHashable,
        setSelection: @MainActor (AnyHashable) -> Void,
        indexDisplayMode: PageTabViewStyle.IndexDisplayMode?
    )
    case viewController(UIViewController)
    case form(rows: [_OpenViewNode])
    case list(rows: [_OpenViewNode])
    case section(
        header: _OpenViewNode?,
        footer: _OpenViewNode?,
        rows: [_OpenViewNode]
    )
    case toggle(
        label: _OpenViewNode,
        isOn: Bool,
        setIsOn: @MainActor (Bool) -> Void
    )
    case textField(
        title: String,
        text: String,
        setText: @MainActor (String) -> Void
    )
    case picker(
        label: _OpenViewNode,
        options: [_OpenPickerOption],
        selection: AnyHashable,
        setSelection: @MainActor (AnyHashable) -> Void
    )
    case navigationLink(
        label: _OpenViewNode,
        makeDestinationController: @MainActor () -> UIViewController
    )
    case navigation(content: _OpenViewNode, configuration: _OpenNavigationConfiguration)
    case gradient(Gradient, UnitPoint, UnitPoint)
    case modified(_OpenViewNode, _OpenViewModification)
}

enum _OpenRoundedRectangleStyle {
    case fill(Color?)
    case stroke(Color, lineWidth: CGFloat)
}

struct _OpenTabPage {
    let content: _OpenViewNode
    let tag: AnyHashable?
}

struct _OpenPickerOption {
    let content: _OpenViewNode
    let tag: AnyHashable
}

enum _OpenViewModification {
    case font(Font?)
    case fontWeight(Font.Weight?)
    case minimumScaleFactor(CGFloat)
    case foregroundColor(Color?)
    case frame(width: CGFloat?, height: CGFloat?, alignment: Alignment)
    case flexibleFrame(maxWidth: CGFloat?, maxHeight: CGFloat?, alignment: Alignment)
    case padding(Edge.Set, CGFloat?)
    case edgeInsetsPadding(EdgeInsets)
    case background(_OpenViewNode, alignment: Alignment)
    case overlay(_OpenViewNode, alignment: Alignment)
    case resizable
    case aspectRatio(ContentMode)
    case multilineTextAlignment(TextAlignment)
    case tapAction(@MainActor () -> Void)
    case simultaneousTapAction(@MainActor () -> Void)
    case onAppear(identity: _OpenGraphIdentity?, action: @MainActor () -> Void)
    case shadow(radius: CGFloat)
    case colorScheme(ColorScheme)
    case safeAreaIgnored
    case previewLayout(PreviewLayout)
    case clipRoundedRectangle(CGFloat)
    case navigationTitle(String)
    case navigationBarHidden(Bool)
    case navigationBackButtonHidden(Bool)
    case navigationTitleDisplayMode(NavigationBarTitleDisplayMode)
    case toolbar(_OpenViewNode)
    case tag(AnyHashable)
    case pageTabViewStyle(PageTabViewStyle.IndexDisplayMode)
    case disabled(Bool)
    case effect
}

/// Construction-time modifier payload. Background and overlay views remain
/// deferred until their modified content is reached through the structural
/// tree; evaluating them while a parent body is being assembled would flatten
/// sibling tuple/stack scopes and alias their dynamic state.
fileprivate enum _OpenViewModifier {
    case font(Font?)
    case fontWeight(Font.Weight?)
    case minimumScaleFactor(CGFloat)
    case foregroundColor(Color?)
    case frame(width: CGFloat?, height: CGFloat?, alignment: Alignment)
    case flexibleFrame(maxWidth: CGFloat?, maxHeight: CGFloat?, alignment: Alignment)
    case padding(Edge.Set, CGFloat?)
    case edgeInsetsPadding(EdgeInsets)
    case background(@MainActor () -> _OpenViewNode, alignment: Alignment)
    case overlay(@MainActor () -> _OpenViewNode, alignment: Alignment)
    case resizable
    case aspectRatio(ContentMode)
    case multilineTextAlignment(TextAlignment)
    case tapAction(@MainActor () -> Void)
    case simultaneousTapAction(@MainActor () -> Void)
    case onAppear(@MainActor () -> Void)
    case shadow(radius: CGFloat)
    case colorScheme(ColorScheme)
    case safeAreaIgnored
    case previewLayout(PreviewLayout)
    case clipRoundedRectangle(CGFloat)
    case navigationTitle(String)
    case navigationBarHidden(Bool)
    case navigationBackButtonHidden(Bool)
    case navigationTitleDisplayMode(NavigationBarTitleDisplayMode)
    case toolbar(@MainActor () -> _OpenViewNode)
    case tag(AnyHashable)
    case pageTabViewStyle(PageTabViewStyle.IndexDisplayMode)
    case disabled(Bool)
    case onChange(@MainActor () -> Void)
    case onReceive(@MainActor () -> Void)

    @MainActor
    func resolve() -> _OpenViewModification {
        switch self {
        case .font(let value): return .font(value)
        case .fontWeight(let value): return .fontWeight(value)
        case .minimumScaleFactor(let value): return .minimumScaleFactor(value)
        case .foregroundColor(let value): return .foregroundColor(value)
        case .frame(let width, let height, let alignment):
            return .frame(width: width, height: height, alignment: alignment)
        case .flexibleFrame(let maxWidth, let maxHeight, let alignment):
            return .flexibleFrame(
                maxWidth: maxWidth,
                maxHeight: maxHeight,
                alignment: alignment
            )
        case .padding(let edges, let length): return .padding(edges, length)
        case .edgeInsetsPadding(let insets): return .edgeInsetsPadding(insets)
        case .background(let makeNode, let alignment):
            return .background(
                _OpenGraphContext.withStructuralScope(.background, operation: makeNode),
                alignment: alignment
            )
        case .overlay(let makeNode, let alignment):
            return .overlay(
                _OpenGraphContext.withStructuralScope(.overlay, operation: makeNode),
                alignment: alignment
            )
        case .resizable: return .resizable
        case .aspectRatio(let value): return .aspectRatio(value)
        case .multilineTextAlignment(let alignment):
            return .multilineTextAlignment(alignment)
        case .tapAction(let action): return .tapAction(action)
        case .simultaneousTapAction(let action): return .simultaneousTapAction(action)
        case .onAppear(let action):
            return _OpenGraphContext.withStructuralScope(.onAppear) {
                .onAppear(identity: _OpenGraphContext.currentIdentity(), action: action)
            }
        case .shadow(let radius): return .shadow(radius: radius)
        case .colorScheme(let scheme): return .colorScheme(scheme)
        case .safeAreaIgnored: return .safeAreaIgnored
        case .previewLayout(let value): return .previewLayout(value)
        case .clipRoundedRectangle(let radius): return .clipRoundedRectangle(radius)
        case .navigationTitle(let title): return .navigationTitle(title)
        case .navigationBarHidden(let hidden): return .navigationBarHidden(hidden)
        case .navigationBackButtonHidden(let hidden):
            return .navigationBackButtonHidden(hidden)
        case .navigationTitleDisplayMode(let mode):
            return .navigationTitleDisplayMode(mode)
        case .toolbar(let makeNode):
            return .toolbar(
                _OpenGraphContext.withStructuralScope(.toolbar, operation: makeNode)
            )
        case .tag(let value): return .tag(value)
        case .pageTabViewStyle(let mode): return .pageTabViewStyle(mode)
        case .disabled(let disabled): return .disabled(disabled)
        case .onChange(let install):
            _OpenGraphContext.withStructuralScope(.onChange) { install() }
            return .effect
        case .onReceive(let install):
            _OpenGraphContext.withStructuralScope(.onReceive) { install() }
            return .effect
        }
    }
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
        _OpenTupleView(
            (c0, c1),
            nodes: {
                [
                    _OpenGraphContext.withStructuralScope(.tupleElement(0)) {
                        c0._makeOpenUIKitNode()
                    },
                    _OpenGraphContext.withStructuralScope(.tupleElement(1)) {
                        c1._makeOpenUIKitNode()
                    },
                ]
            }
        )
    }

    public static func buildBlock<C0: _OpenView, C1: _OpenView, C2: _OpenView>(
        _ c0: C0,
        _ c1: C1,
        _ c2: C2
    ) -> _OpenTupleView<(C0, C1, C2)> {
        _OpenTupleView(
            (c0, c1, c2),
            nodes: {
                [
                    _OpenGraphContext.withStructuralScope(.tupleElement(0)) {
                        c0._makeOpenUIKitNode()
                    },
                    _OpenGraphContext.withStructuralScope(.tupleElement(1)) {
                        c1._makeOpenUIKitNode()
                    },
                    _OpenGraphContext.withStructuralScope(.tupleElement(2)) {
                        c2._makeOpenUIKitNode()
                    },
                ]
            }
        )
    }

    /// SwiftUI's builder accepts arbitrary-length sibling lists.  Partial
    /// blocks keep that property without a ladder of fixed tuple overloads.
    public static func buildPartialBlock<Content: _OpenView>(first: Content) -> Content {
        first
    }

    public static func buildPartialBlock<Accumulated: _OpenView, Next: _OpenView>(
        accumulated: Accumulated,
        next: Next
    ) -> _OpenTupleView<(Accumulated, Next)> {
        _OpenTupleView(
            (accumulated, next),
            nodes: {
                [
                    _OpenGraphContext.withStructuralScope(.tupleElement(0)) {
                        accumulated._makeOpenUIKitNode()
                    },
                    _OpenGraphContext.withStructuralScope(.tupleElement(1)) {
                        next._makeOpenUIKitNode()
                    },
                ]
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
        nodeBuilder = {
            _OpenGraphContext.withStructuralScope(.conditionalTrue) {
                content._makeOpenUIKitNode()
            }
        }
    }

    init(second content: FalseContent) {
        nodeBuilder = {
            _OpenGraphContext.withStructuralScope(.conditionalFalse) {
                content._makeOpenUIKitNode()
            }
        }
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
        _OpenViewNode(
            .group(
                components.enumerated().map { index, component in
                    _OpenGraphContext.withStructuralScope(.arrayElement(index)) {
                        component._makeOpenUIKitNode()
                    }
                }
            )
        )
    }
}

extension Optional: _OpenView where Wrapped: _OpenView {
    public typealias Body = Never

    public func _makeOpenUIKitNode() -> _OpenViewNode {
        switch self {
        case .some(let wrapped):
            return _OpenGraphContext.withStructuralScope(.optionalSome) {
                wrapped._makeOpenUIKitNode()
            }
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

    public init(verbatim content: String) {
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
                children: _flattenGroup(
                    _OpenGraphContext.withStructuralScope(.hStackContent) {
                        content._makeOpenUIKitNode()
                    }
                ),
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
                children: _flattenGroup(
                    _OpenGraphContext.withStructuralScope(.vStackContent) {
                        content._makeOpenUIKitNode()
                    }
                ),
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
        _OpenViewNode(
            .form(
                rows: _flattenGroup(
                    _OpenGraphContext.withStructuralScope(.formContent) {
                        content._makeOpenUIKitNode()
                    }
                )
            )
        )
    }
}

/// Eager collection expansion. Each element's explicit Hashable ID forms a
/// typed graph scope so retained state follows the element through reorder and
/// is destroyed when that ID leaves the collection.
public struct _OpenForEach<Data, ID, Content>: _OpenView
where Data: RandomAccessCollection, ID: Hashable, Content: _OpenView {
    public typealias Body = Never
    public let data: Data
    private let idKeyPath: KeyPath<Data.Element, ID>
    private let contentBuilder: @MainActor (Data.Element) -> Content

    public init(
        _ data: Data,
        id: KeyPath<Data.Element, ID>,
        @_OpenViewBuilder content: @escaping @MainActor (Data.Element) -> Content
    ) {
        self.data = data
        idKeyPath = id
        contentBuilder = content
    }

    public func _makeOpenUIKitNode() -> _OpenViewNode {
        _OpenGraphContext.withStructuralScope(.forEachContent) {
            var seen: Set<AnyHashable> = []
            let nodes = data.map { element -> _OpenViewNode in
                let identifier = AnyHashable(element[keyPath: idKeyPath])
                precondition(
                    seen.insert(identifier).inserted,
                    "ForEach requires unique element IDs"
                )
                return _OpenGraphContext.withStructuralScope(.forEachElement(identifier)) {
                    let node = contentBuilder(element)._makeOpenUIKitNode()
                    if _openExtractTag(node).tag != nil {
                        return node
                    }
                    return _OpenViewNode(
                        .modified(
                            node,
                            .tag(identifier)
                        )
                    )
                }
            }
            return _OpenViewNode(.group(nodes))
        }
    }
}

public struct _OpenNavigationView<Content: _OpenView>: _OpenView {
    public typealias Body = Never
    public let content: Content

    public init(@_OpenViewBuilder content: () -> Content) {
        self.content = content()
    }

    public func _makeOpenUIKitNode() -> _OpenViewNode {
        let contentNode = _OpenGraphContext.withStructuralScope(.navigationContent) {
            content._makeOpenUIKitNode()
        }
        let (node, configuration) = _openExtractNavigationConfiguration(
            contentNode
        )
        return _OpenViewNode(.navigation(content: node, configuration: configuration))
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
    private let modifier: _OpenViewModifier

    fileprivate init(content: Content, modification: _OpenViewModifier) {
        self.content = content
        modifier = modification
    }

    public func _makeOpenUIKitNode() -> _OpenViewNode {
        let contentNode = _OpenGraphContext.withStructuralScope(.modifiedContent) {
            content._makeOpenUIKitNode()
        }
        let resolvedModifier = modifier.resolve()
        if case .pageTabViewStyle(let indexDisplayMode) = resolvedModifier {
            return _openApplyingPageTabViewStyle(
                contentNode,
                indexDisplayMode: indexDisplayMode
            )
        }
        return _OpenViewNode(.modified(contentNode, resolvedModifier))
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

    func frame(
        maxWidth: CGFloat? = nil,
        maxHeight: CGFloat? = nil,
        alignment: Alignment = .center
    ) -> some _OpenView {
        _OpenModifiedContent(
            content: self,
            modification: .flexibleFrame(
                maxWidth: maxWidth,
                maxHeight: maxHeight,
                alignment: alignment
            )
        )
    }

    func padding(_ edges: Edge.Set = .all, _ length: CGFloat? = nil) -> some _OpenView {
        _OpenModifiedContent(content: self, modification: .padding(edges, length))
    }

    func padding(_ length: CGFloat) -> some _OpenView {
        _OpenModifiedContent(content: self, modification: .padding(.all, length))
    }

    func padding(_ insets: EdgeInsets) -> some _OpenView {
        _OpenModifiedContent(content: self, modification: .edgeInsetsPadding(insets))
    }

    func background<Background: _OpenView>(
        _ background: Background,
        alignment: Alignment = .center
    ) -> some _OpenView {
        _OpenModifiedContent(
            content: self,
            modification: .background(
                { background._makeOpenUIKitNode() },
                alignment: alignment
            )
        )
    }

    func overlay<Overlay: _OpenView>(
        _ overlay: Overlay,
        alignment: Alignment = .center
    ) -> some _OpenView {
        _OpenModifiedContent(
            content: self,
            modification: .overlay(
                { overlay._makeOpenUIKitNode() },
                alignment: alignment
            )
        )
    }

    func aspectRatio(contentMode: ContentMode) -> some _OpenView {
        _OpenModifiedContent(content: self, modification: .aspectRatio(contentMode))
    }

    func scaledToFit() -> some _OpenView {
        aspectRatio(contentMode: .fit)
    }

    func scaledToFill() -> some _OpenView {
        aspectRatio(contentMode: .fill)
    }

    func bold() -> some _OpenView {
        fontWeight(.bold)
    }

    func multilineTextAlignment(_ alignment: TextAlignment) -> some _OpenView {
        _OpenModifiedContent(
            content: self,
            modification: .multilineTextAlignment(alignment)
        )
    }

    func cornerRadius(_ radius: CGFloat) -> some _OpenView {
        _OpenModifiedContent(
            content: self,
            modification: .clipRoundedRectangle(max(0, radius))
        )
    }

    func shadow(radius: CGFloat) -> some _OpenView {
        _OpenModifiedContent(content: self, modification: .shadow(radius: max(0, radius)))
    }

    func colorScheme(_ colorScheme: ColorScheme) -> some _OpenView {
        _OpenModifiedContent(content: self, modification: .colorScheme(colorScheme))
    }

    func ignoresSafeArea() -> some _OpenView {
        _OpenModifiedContent(content: self, modification: .safeAreaIgnored)
    }

    func edgesIgnoringSafeArea(_ edges: Edge.Set) -> some _OpenView {
        _ = edges
        return _OpenModifiedContent(content: self, modification: .safeAreaIgnored)
    }

    func onAppear(perform action: @escaping @MainActor () -> Void) -> some _OpenView {
        _OpenModifiedContent(content: self, modification: .onAppear(action))
    }

    func onTapGesture(perform action: @escaping @MainActor () -> Void) -> some _OpenView {
        _OpenModifiedContent(content: self, modification: .tapAction(action))
    }

    func simultaneousGesture(_ gesture: TapGesture) -> some _OpenView {
        _OpenModifiedContent(
            content: self,
            modification: .simultaneousTapAction(gesture.action ?? {})
        )
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

    func navigationBarTitle(_ title: String) -> some _OpenView {
        navigationTitle(title)
    }

    func navigationBarTitle(_ title: Text) -> some _OpenView {
        navigationTitle(title.content)
    }

    func disabled(_ disabled: Bool) -> some _OpenView {
        _OpenModifiedContent(content: self, modification: .disabled(disabled))
    }

    func onChange<Value: Equatable>(
        of value: Value,
        perform action: @escaping @MainActor (Value) -> Void
    ) -> some _OpenView {
        _OpenModifiedContent(
            content: self,
            modification: .onChange {
                _OpenGraphContext.trackChange(value, action: action)
            }
        )
    }

    func onReceive<PublisherType: Combine.Publisher>(
        _ publisher: PublisherType,
        perform action: @escaping @MainActor (PublisherType.Output) -> Void
    ) -> some _OpenView {
        _OpenModifiedContent(
            content: self,
            modification: .onReceive {
                _OpenGraphContext.subscribe(publisher, action: action)
            }
        )
    }

    func navigationBarHidden(_ hidden: Bool) -> some _OpenView {
        _OpenModifiedContent(content: self, modification: .navigationBarHidden(hidden))
    }

    func navigationBarBackButtonHidden(_ hidden: Bool) -> some _OpenView {
        _OpenModifiedContent(content: self, modification: .navigationBackButtonHidden(hidden))
    }

    func navigationBarTitleDisplayMode(
        _ displayMode: NavigationBarTitleDisplayMode
    ) -> some _OpenView {
        _OpenModifiedContent(
            content: self,
            modification: .navigationTitleDisplayMode(displayMode)
        )
    }

    func toolbar<ToolbarContent: _OpenView>(
        @_OpenViewBuilder content: () -> ToolbarContent
    ) -> some _OpenView {
        let toolbarContent = content()
        return _OpenModifiedContent(
            content: self,
            modification: .toolbar { toolbarContent._makeOpenUIKitNode() }
        )
    }

    func tag<Value: Hashable>(_ tag: Value) -> some _OpenView {
        _OpenModifiedContent(content: self, modification: .tag(AnyHashable(tag)))
    }

    func tabViewStyle(_ style: PageTabViewStyle) -> some _OpenView {
        _OpenModifiedContent(
            content: self,
            modification: .pageTabViewStyle(style.indexDisplayMode)
        )
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
struct _OpenNavigationConfiguration {
    var title: String?
    var barHidden = false
    var backButtonHidden = false
    var titleDisplayMode: NavigationBarTitleDisplayMode = .automatic
    var toolbar: _OpenViewNode?
}

@MainActor
func _openExtractNavigationConfiguration(
    _ node: _OpenViewNode
) -> (_OpenViewNode, _OpenNavigationConfiguration) {
    switch node.kind {
    case .modified(let content, let modification):
        var (unwrapped, configuration) = _openExtractNavigationConfiguration(content)
        switch modification {
        case .navigationTitle(let title):
            configuration.title = title
        case .navigationBarHidden(let hidden):
            configuration.barHidden = hidden
        case .navigationBackButtonHidden(let hidden):
            configuration.backButtonHidden = hidden
        case .navigationTitleDisplayMode(let displayMode):
            configuration.titleDisplayMode = displayMode
        case .toolbar(let toolbar):
            configuration.toolbar = toolbar
        default:
            unwrapped = _OpenViewNode(.modified(unwrapped, modification))
        }
        return (unwrapped, configuration)
    case .scroll(let content):
        let (unwrapped, configuration) = _openExtractNavigationConfiguration(content)
        return (_OpenViewNode(.scroll(content: unwrapped)), configuration)
    case .group(let children):
        let (unwrapped, configuration) = _extractNavigationChildren(children)
        return (_OpenViewNode(.group(unwrapped)), configuration)
    case .hStack(let children, let alignment, let spacing):
        let (unwrapped, configuration) = _extractNavigationChildren(children)
        return (
            _OpenViewNode(.hStack(children: unwrapped, alignment: alignment, spacing: spacing)),
            configuration
        )
    case .vStack(let children, let alignment, let spacing):
        let (unwrapped, configuration) = _extractNavigationChildren(children)
        return (
            _OpenViewNode(.vStack(children: unwrapped, alignment: alignment, spacing: spacing)),
            configuration
        )
    case .zStack(let children, let alignment):
        let (unwrapped, configuration) = _extractNavigationChildren(children)
        return (_OpenViewNode(.zStack(children: unwrapped, alignment: alignment)), configuration)
    case .form(let rows):
        let (unwrapped, configuration) = _extractNavigationChildren(rows)
        return (_OpenViewNode(.form(rows: unwrapped)), configuration)
    case .list(let rows):
        let (unwrapped, configuration) = _extractNavigationChildren(rows)
        return (_OpenViewNode(.list(rows: unwrapped)), configuration)
    case .section(let header, let footer, let rows):
        let (unwrapped, configuration) = _extractNavigationChildren(rows)
        return (
            _OpenViewNode(
                .section(header: header, footer: footer, rows: unwrapped)
            ),
            configuration
        )
    default:
        return (node, _OpenNavigationConfiguration())
    }
}

@MainActor
private func _extractNavigationChildren(
    _ children: [_OpenViewNode]
) -> ([_OpenViewNode], _OpenNavigationConfiguration) {
    var configuration = _OpenNavigationConfiguration()
    let nodes = children.map { child -> _OpenViewNode in
        let (node, childConfiguration) = _openExtractNavigationConfiguration(child)
        if let title = childConfiguration.title { configuration.title = title }
        configuration.barHidden = configuration.barHidden || childConfiguration.barHidden
        configuration.backButtonHidden = configuration.backButtonHidden
            || childConfiguration.backButtonHidden
        if childConfiguration.titleDisplayMode != .automatic {
            configuration.titleDisplayMode = childConfiguration.titleDisplayMode
        }
        if let toolbar = childConfiguration.toolbar { configuration.toolbar = toolbar }
        return node
    }
    return (nodes, configuration)
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
