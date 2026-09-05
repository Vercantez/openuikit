// SwiftUI S2: the non-observation composition and lifecycle vocabulary used
// by Mozilla Focus's Onboarding target.  Observation wrappers live in their
// own compatibility slice; this file deliberately contains no object graph or
// publisher machinery.

#if canImport(Foundation)
import Foundation
#endif
import OpenUIKit

public enum _OpenTextAlignment: Equatable, Sendable {
    case leading
    case center
    case trailing
}

public enum _OpenColorScheme: Equatable, Sendable {
    case light
    case dark
}

public enum _OpenNavigationBarTitleDisplayMode: Equatable, Sendable {
    case automatic
    case inline
    case large
}

public enum _OpenScrollDismissesKeyboardMode: Equatable, Sendable {
    case automatic
    case immediately
    case interactively
    case never
}

public enum _OpenControlSize: Equatable, Sendable {
    case mini
    case small
    case regular
    case large
    case extraLarge
}

public enum _OpenSymbolRenderingMode: Equatable, Sendable {
    case monochrome
    case hierarchical
    case palette
    case multicolor
}

public struct _OpenToolbarItemPlacement: Hashable, Sendable {
    private let rawValue: UInt8

    private init(_ rawValue: UInt8) { self.rawValue = rawValue }

    public static let automatic = _OpenToolbarItemPlacement(0)
    public static let principal = _OpenToolbarItemPlacement(1)
    public static let navigationBarLeading = _OpenToolbarItemPlacement(2)
    public static let navigationBarTrailing = _OpenToolbarItemPlacement(3)
    public static let topBarLeading = navigationBarLeading
    public static let topBarTrailing = navigationBarTrailing
    public static let bottomBar = _OpenToolbarItemPlacement(4)
    public static let cancellationAction = _OpenToolbarItemPlacement(5)
    public static let confirmationAction = _OpenToolbarItemPlacement(6)
}

public enum _OpenToolbarSpacerSizing: Hashable, Sendable {
    case fixed
    case flexible
}

public enum _OpenDefaultToolbarItemKind: Hashable, Sendable {
    case search
}

public struct _OpenSearchFieldPlacement: Hashable, Sendable {
    private let rawValue: UInt8
    private init(_ rawValue: UInt8) { self.rawValue = rawValue }

    public static let automatic = _OpenSearchFieldPlacement(0)
    public static let toolbar = _OpenSearchFieldPlacement(1)
    public static let navigationBarDrawer = _OpenSearchFieldPlacement(2)
}

public enum _OpenSearchToolbarBehavior: Hashable, Sendable {
    case automatic
    case minimize
}

/// Retained list presentation choice. The concrete value rather than a
/// marker protocol keeps style dispatch Foundation-free and lets the host
/// renderer apply the choice at the list boundary.
public struct _OpenListStyle: Hashable, Sendable {
    enum Storage: Hashable, Sendable {
        case automatic
        case plain
        case grouped
        case insetGrouped
        case sidebar
    }

    let storage: Storage
    private init(_ storage: Storage) { self.storage = storage }

    public static let automatic = _OpenListStyle(.automatic)
    public static let plain = _OpenListStyle(.plain)
    public static let grouped = _OpenListStyle(.grouped)
    public static let insetGrouped = _OpenListStyle(.insetGrouped)
    public static let sidebar = _OpenListStyle(.sidebar)
}

/// Legacy nominal style retained by SwiftUI for source compatibility. It is
/// deliberately a value rather than a protocol existential so the portable
/// renderer can select the measured grouped presentation without reflection.
public struct _OpenGroupedListStyle: Hashable, Sendable {
    public init() {}
}

public struct _OpenGeometryProxy: Sendable {
    public let size: CGSize
    public let safeAreaInsets: EdgeInsets

    init(size: CGSize, safeAreaInsets: EdgeInsets = EdgeInsets()) {
        self.size = size
        self.safeAreaInsets = safeAreaInsets
    }

    public func frame(in coordinateSpace: CoordinateSpace) -> CGRect {
        _ = coordinateSpace
        return CGRect(origin: .zero, size: size)
    }
}

public struct _OpenCoordinateSpace: Hashable, @unchecked Sendable {
    private enum Storage: Hashable { case local, global, named(AnyHashable) }
    private let storage: Storage

    private init(_ storage: Storage) { self.storage = storage }
    public static let local = _OpenCoordinateSpace(.local)
    public static let global = _OpenCoordinateSpace(.global)
    public static func named<Name: Hashable>(_ name: Name) -> _OpenCoordinateSpace {
        _OpenCoordinateSpace(.named(AnyHashable(name)))
    }
}

public struct _OpenPageTabViewStyle: Equatable, Sendable {
    public enum IndexDisplayMode: Equatable, Sendable {
        case automatic
        case always
        case never
    }

    let indexDisplayMode: IndexDisplayMode

    public static func page(
        indexDisplayMode: IndexDisplayMode = .automatic
    ) -> _OpenPageTabViewStyle {
        _OpenPageTabViewStyle(indexDisplayMode: indexDisplayMode)
    }
}

public struct _OpenEdgeInsets: Equatable, Sendable {
    public let top: CGFloat
    public let leading: CGFloat
    public let bottom: CGFloat
    public let trailing: CGFloat

    public init(top: CGFloat, leading: CGFloat, bottom: CGFloat, trailing: CGFloat) {
        self.top = top
        self.leading = leading
        self.bottom = bottom
        self.trailing = trailing
    }

    public init() {
        self.init(top: 0, leading: 0, bottom: 0, trailing: 0)
    }
}

public struct _OpenTransaction: Sendable {
    public var animation: Animation?
    public var disablesAnimations: Bool

    public init(animation: Animation? = nil) {
        self.animation = animation
        disablesAnimations = false
    }
}

@MainActor
@discardableResult
public func withTransaction<Result>(
    _ transaction: Transaction,
    _ body: () throws -> Result
) rethrows -> Result {
    if transaction.disablesAnimations || transaction.animation == nil {
        return try body()
    }
    return try withAnimation(transaction.animation, body)
}

/// Preference values flow up the retained node tree. The host reduces every
/// value in source order and invokes the nearest listener after the subtree
/// has been resolved for its concrete geometry.
public protocol _OpenPreferenceKey {
    associatedtype Value
    static var defaultValue: Value { get }
    static func reduce(value: inout Value, nextValue: () -> Value)
}

public struct _OpenScrollGeometry: Sendable {
    public let contentOffset: CGPoint
    public let contentSize: CGSize
    public let containerSize: CGSize
    public let contentInsets: EdgeInsets

    init(scrollView: UIScrollView) {
        contentOffset = scrollView.contentOffset
        contentSize = scrollView.contentSize
        containerSize = scrollView.bounds.size
        contentInsets = EdgeInsets(
            top: scrollView.contentInset.top,
            leading: scrollView.contentInset.left,
            bottom: scrollView.contentInset.bottom,
            trailing: scrollView.contentInset.right
        )
    }
}

public enum _OpenScrollPhase: Hashable, Sendable {
    case idle
    case tracking
    case interacting
    case decelerating
    case animating

    public var isScrolling: Bool { self != .idle }
}

public struct _OpenScrollPhaseChangeContext: Sendable {
    public let geometry: ScrollGeometry

    public init(geometry: ScrollGeometry) {
        self.geometry = geometry
    }
}

@MainActor
final class _OpenScrollProxyStorage {
    weak var scrollView: UIScrollView?
    var targetRects: [AnyHashable: CGRect] = [:]
    weak var coordinator: AnyObject?
    var notifyAfterScroll: (@MainActor () -> Void)?

    func scrollTo(_ id: AnyHashable, anchor: UnitPoint?) {
        guard let scrollView, let target = targetRects[id] else { return }
        let point = anchor ?? .center
        let x = target.minX - max(0, scrollView.bounds.width - target.width) * point.x
        let y = target.minY - max(0, scrollView.bounds.height - target.height) * point.y
        let maxX = max(-scrollView.contentInset.left,
                       scrollView.contentSize.width - scrollView.bounds.width
                           + scrollView.contentInset.right)
        let maxY = max(-scrollView.contentInset.top,
                       scrollView.contentSize.height - scrollView.bounds.height
                           + scrollView.contentInset.bottom)
        scrollView.setContentOffset(
            CGPoint(
                x: min(max(x, -scrollView.contentInset.left), maxX),
                y: min(max(y, -scrollView.contentInset.top), maxY)
            ),
            animated: _OpenAnimationContext.current != nil
        )
        notifyAfterScroll?()
    }
}

public struct _OpenScrollViewProxy: Sendable {
    @MainActor private let storage: _OpenScrollProxyStorage

    @MainActor init(storage: _OpenScrollProxyStorage) { self.storage = storage }

    @MainActor public func scrollTo<ID: Hashable>(_ id: ID, anchor: UnitPoint? = nil) {
        storage.scrollTo(AnyHashable(id), anchor: anchor)
    }
}

public struct _OpenScrollViewReader<Content: _OpenView>: _OpenView {
    public typealias Body = Never
    private let storage: _OpenScrollProxyStorage
    private let content: Content

    public init(
        @_OpenViewBuilder content: @escaping @MainActor (ScrollViewProxy) -> Content
    ) {
        let storage = _OpenScrollProxyStorage()
        self.storage = storage
        self.content = content(ScrollViewProxy(storage: storage))
    }

    public func _makeOpenUIKitNode() -> _OpenViewNode {
        _OpenViewNode(
            .scrollReader(
                content: _OpenGraphContext.withStructuralScope(.scrollContent) {
                    content._makeOpenUIKitNode()
                },
                storage: storage
            )
        )
    }
}

public protocol _OpenGesture {}

@MainActor
protocol _OpenGestureNodeProviding {
    var _openGestureNode: _OpenGestureNode { get }
}

@MainActor
struct _OpenGestureNode {
    enum Kind {
        case tap(@MainActor () -> Void)
        case longPress(minimumDuration: Double, @MainActor (Bool) -> Void)
        case drag(
            minimumDistance: CGFloat,
            coordinateSpace: CoordinateSpace,
            changed: @MainActor (DragGesture.Value) -> Void,
            ended: @MainActor (DragGesture.Value) -> Void
        )
    }
    let kind: Kind
}

public struct _OpenDragGesture: _OpenGesture {
    public struct Value: Sendable {
        public let time: Date
        public let location: CGPoint
        public let startLocation: CGPoint
        public let translation: CGSize
        public let predictedEndLocation: CGPoint
        public let predictedEndTranslation: CGSize
        public let velocity: CGSize

        init(location: CGPoint, startLocation: CGPoint, velocity: CGSize = .zero) {
            time = Date()
            self.location = location
            self.startLocation = startLocation
            translation = CGSize(
                width: location.x - startLocation.x,
                height: location.y - startLocation.y
            )
            self.velocity = velocity
            predictedEndLocation = CGPoint(
                x: location.x + velocity.width * 0.1,
                y: location.y + velocity.height * 0.1
            )
            predictedEndTranslation = CGSize(
                width: predictedEndLocation.x - startLocation.x,
                height: predictedEndLocation.y - startLocation.y
            )
        }
    }

    public let minimumDistance: CGFloat
    public let coordinateSpace: CoordinateSpace
    private let changed: @MainActor (Value) -> Void
    private let ended: @MainActor (Value) -> Void

    public init(
        minimumDistance: CGFloat = 10,
        coordinateSpace: CoordinateSpace = .local
    ) {
        self.minimumDistance = minimumDistance
        self.coordinateSpace = coordinateSpace
        changed = { _ in }
        ended = { _ in }
    }

    private init(
        minimumDistance: CGFloat,
        coordinateSpace: CoordinateSpace,
        changed: @escaping @MainActor (Value) -> Void,
        ended: @escaping @MainActor (Value) -> Void
    ) {
        self.minimumDistance = minimumDistance
        self.coordinateSpace = coordinateSpace
        self.changed = changed
        self.ended = ended
    }

    public func onChanged(_ action: @escaping @MainActor (Value) -> Void) -> _OpenDragGesture {
        _OpenDragGesture(
            minimumDistance: minimumDistance,
            coordinateSpace: coordinateSpace,
            changed: action,
            ended: ended
        )
    }

    public func onEnded(_ action: @escaping @MainActor (Value) -> Void) -> _OpenDragGesture {
        _OpenDragGesture(
            minimumDistance: minimumDistance,
            coordinateSpace: coordinateSpace,
            changed: changed,
            ended: action
        )
    }
}

extension _OpenDragGesture: _OpenGestureNodeProviding {
    var _openGestureNode: _OpenGestureNode {
        _OpenGestureNode(
            kind: .drag(
                minimumDistance: minimumDistance,
                coordinateSpace: coordinateSpace,
                changed: changed,
                ended: ended
            )
        )
    }
}

public struct _OpenLongPressGesture: _OpenGesture {
    public let minimumDuration: Double
    private let ended: @MainActor (Bool) -> Void

    public init(minimumDuration: Double = 0.5) {
        self.minimumDuration = minimumDuration
        ended = { _ in }
    }

    private init(minimumDuration: Double, ended: @escaping @MainActor (Bool) -> Void) {
        self.minimumDuration = minimumDuration
        self.ended = ended
    }

    public func onEnded(
        _ action: @escaping @MainActor (Bool) -> Void
    ) -> _OpenLongPressGesture {
        _OpenLongPressGesture(minimumDuration: minimumDuration, ended: action)
    }
}

extension _OpenLongPressGesture: _OpenGestureNodeProviding {
    var _openGestureNode: _OpenGestureNode {
        _OpenGestureNode(kind: .longPress(minimumDuration: minimumDuration, ended))
    }
}

public struct _OpenTapGesture {
    let action: (@MainActor () -> Void)?

    public init() {
        action = nil
    }

    private init(action: @escaping @MainActor () -> Void) {
        self.action = action
    }

    public func onEnded(_ action: @escaping @MainActor (()) -> Void) -> _OpenTapGesture {
        _OpenTapGesture(action: { action(()) })
    }
}

extension _OpenTapGesture: _OpenGesture, _OpenGestureNodeProviding {
    var _openGestureNode: _OpenGestureNode {
        _OpenGestureNode(kind: .tap(action ?? {}))
    }
}

public struct _OpenZStack<Content: _OpenView>: _OpenView {
    public typealias Body = Never
    public let alignment: Alignment
    public let content: Content

    public init(
        alignment: Alignment = .center,
        @_OpenViewBuilder content: () -> Content
    ) {
        self.alignment = alignment
        self.content = content()
    }

    public func _makeOpenUIKitNode() -> _OpenViewNode {
        _OpenViewNode(
            .zStack(
                children: _openFlattenGroup(
                    _OpenGraphContext.withStructuralScope(.zStackContent) {
                        content._makeOpenUIKitNode()
                    }
                ),
                alignment: alignment
            )
        )
    }
}

/// Groups neighboring glass-effect surfaces into one compositing namespace.
/// OpenUIKit already renders each child through the same backdrop pipeline;
/// this retained boundary preserves source ordering and exposes the requested
/// spacing to hosts without inserting a layout container of its own.
public struct _OpenGlassEffectContainer<Content: _OpenView>: _OpenView {
    public typealias Body = Never
    public let spacing: CGFloat
    public let content: Content

    public init(
        spacing: CGFloat = 8,
        @_OpenViewBuilder content: () -> Content
    ) {
        self.spacing = max(0, spacing)
        self.content = content()
    }

    public func _makeOpenUIKitNode() -> _OpenViewNode {
        _OpenViewNode(
            .modified(
                content._makeOpenUIKitNode(),
                .accessibilityIdentifier("SwiftUI.GlassEffectContainer.\(spacing)")
            )
        )
    }
}

public struct _OpenButton<Label: _OpenView>: _OpenView {
    public typealias Body = Never
    nonisolated(unsafe) public let action: @MainActor () -> Void
    nonisolated(unsafe) public let label: Label
    public let role: ButtonRole?

    @preconcurrency public init(
        action: @escaping @MainActor () -> Void,
        @_OpenViewBuilder label: () -> Label
    ) {
        self.action = action
        self.label = label()
        role = nil
    }

    @preconcurrency public init(
        role: ButtonRole?,
        action: @escaping @MainActor () -> Void,
        @_OpenViewBuilder label: () -> Label
    ) {
        self.action = action
        self.label = label()
        self.role = role
    }

    nonisolated public init(
        _ title: String,
        action: @escaping @MainActor () -> Void
    ) where Label == _OpenText {
        self.action = action
        label = _OpenText(title)
        role = nil
    }

    nonisolated public init(
        _ title: String,
        role: ButtonRole?,
        action: @escaping @MainActor () -> Void
    ) where Label == _OpenText {
        self.action = action
        label = _OpenText(title)
        self.role = role
    }

    public func _makeOpenUIKitNode() -> _OpenViewNode {
        _OpenViewNode(
            .button(
                label: _OpenGraphContext.withStructuralScope(.buttonLabel) {
                    label._makeOpenUIKitNode()
                },
                pressedLabel: nil,
                role: role,
                action: action
            )
        )
    }
}

public struct _OpenScrollView<Content: _OpenView>: _OpenView {
    public typealias Body = Never
    public let content: Content

    public init(@_OpenViewBuilder content: () -> Content) {
        self.content = content()
    }

    public func _makeOpenUIKitNode() -> _OpenViewNode {
        _OpenViewNode(
            .scroll(
                content: _OpenGraphContext.withStructuralScope(.scrollContent) {
                    content._makeOpenUIKitNode()
                }
            )
        )
    }
}

/// A layout reader whose child is resolved against the concrete proposal
/// used by the OpenUIKit host.  This is intentionally a node-level primitive:
/// the proxy is not guessed at body construction time, so rotations and host
/// resizes update the child's measured minimums on the next layout pass.
public struct _OpenGeometryReader<Content: _OpenView>: _OpenView {
    public typealias Body = Never
    private let content: @MainActor (GeometryProxy) -> Content

    public init(
        @_OpenViewBuilder content: @escaping @MainActor (GeometryProxy) -> Content
    ) {
        self.content = content
    }

    public func _makeOpenUIKitNode() -> _OpenViewNode {
        _OpenViewNode(
            .geometry(
                _OpenGeometryNode { size in
                    content(GeometryProxy(size: size))._makeOpenUIKitNode()
                }
            )
        )
    }
}

/// `LazyVStack` shares the eager stack node today, but not merely as a syntax
/// alias: a scroll host measures and clips that node against its viewport,
/// and its children retain stable IDs for programmatic scrolling.  The public
/// nominal leaves room for viewport materialisation without changing app ABI.
public struct _OpenLazyVStack<Content: _OpenView>: _OpenView {
    public typealias Body = Never
    public let alignment: HorizontalAlignment
    public let spacing: CGFloat?
    public let pinnedViews: _OpenPinnedScrollableViews
    public let content: Content

    public init(
        alignment: HorizontalAlignment = .center,
        spacing: CGFloat? = nil,
        pinnedViews: _OpenPinnedScrollableViews = [],
        @_OpenViewBuilder content: () -> Content
    ) {
        self.alignment = alignment
        self.spacing = spacing
        self.pinnedViews = pinnedViews
        self.content = content()
    }

    public func _makeOpenUIKitNode() -> _OpenViewNode {
        _OpenViewNode(
            .vStack(
                children: _openFlattenGroup(
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

public struct _OpenPinnedScrollableViews: OptionSet, Hashable, Sendable {
    public let rawValue: UInt8
    public init(rawValue: UInt8) { self.rawValue = rawValue }
    public static let sectionHeaders = _OpenPinnedScrollableViews(rawValue: 1 << 0)
    public static let sectionFooters = _OpenPinnedScrollableViews(rawValue: 1 << 1)
}

public struct _OpenProposedViewSize: Equatable, Sendable {
    public var width: CGFloat?
    public var height: CGFloat?

    public init(width: CGFloat?, height: CGFloat?) {
        self.width = width
        self.height = height
    }

    public init(_ size: CGSize) {
        width = size.width
        height = size.height
    }

    public static let unspecified = _OpenProposedViewSize(width: nil, height: nil)

    public func replacingUnspecifiedDimensions(
        by defaultSize: CGSize = CGSize(width: 10, height: 10)
    ) -> CGSize {
        CGSize(width: width ?? defaultSize.width, height: height ?? defaultSize.height)
    }
}

@MainActor
final class _OpenLayoutPlacement {
    var point: CGPoint?
    var anchor: UnitPoint = .topLeading
    var proposal: ProposedViewSize = .unspecified
}

public struct _OpenLayoutSubview: Identifiable {
    public let id: AnyHashable
    private let measure: @MainActor (ProposedViewSize) -> CGSize
    let placement: _OpenLayoutPlacement

    @MainActor
    init(
        id: AnyHashable,
        measure: @escaping @MainActor (ProposedViewSize) -> CGSize,
        placement: _OpenLayoutPlacement
    ) {
        self.id = id
        self.measure = measure
        self.placement = placement
    }

    @MainActor public func sizeThatFits(_ proposal: ProposedViewSize) -> CGSize {
        measure(proposal)
    }

    @MainActor public func place(
        at position: CGPoint,
        anchor: UnitPoint = .topLeading,
        proposal: ProposedViewSize
    ) {
        placement.point = position
        placement.anchor = anchor
        placement.proposal = proposal
    }
}

public struct _OpenLayoutSubviews: RandomAccessCollection {
    public typealias Index = Int
    public typealias Element = LayoutSubview
    private let values: [LayoutSubview]

    @MainActor init(_ values: [LayoutSubview]) { self.values = values }
    public var startIndex: Int { values.startIndex }
    public var endIndex: Int { values.endIndex }
    public subscript(position: Int) -> LayoutSubview { values[position] }
}

@preconcurrency @MainActor
public protocol _OpenLayout {
    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: LayoutSubviews,
        cache: inout ()
    ) -> CGSize

    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: LayoutSubviews,
        cache: inout ()
    )
}

public struct _OpenLayoutView<LayoutType: Layout, Content: _OpenView>: _OpenView {
    public typealias Body = Never
    let layout: LayoutType
    let content: Content

    public func _makeOpenUIKitNode() -> _OpenViewNode {
        _OpenViewNode(
            .customLayout(
                layout: layout,
                children: _openFlattenGroup(
                    _OpenGraphContext.withStructuralScope(.vStackContent) {
                        content._makeOpenUIKitNode()
                    }
                )
            )
        )
    }
}

public extension _OpenLayout {
    func callAsFunction<Content: _OpenView>(
        @_OpenViewBuilder content: () -> Content
    ) -> _OpenLayoutView<Self, Content> {
        _OpenLayoutView(layout: self, content: content())
    }
}

/// ToolbarItem is a semantic placement wrapper. Navigation bars currently
/// consume leading/principal/trailing items; the item remains a normal view
/// outside a toolbar, matching SwiftUI's builder behavior.
public struct _OpenToolbarItem<Content: _OpenView>: _OpenView {
    public typealias Body = Never
    public let placement: ToolbarItemPlacement
    public let content: Content

    public init(
        placement: ToolbarItemPlacement = .automatic,
        @_OpenViewBuilder content: () -> Content
    ) {
        self.placement = placement
        self.content = content()
    }

    public func _makeOpenUIKitNode() -> _OpenViewNode {
        content._makeOpenUIKitNode()
    }
}

/// Newer SwiftUI toolbars use semantic spacers instead of empty fixed-width
/// views. The retained spacer keeps its placement so future toolbar layout
/// can partition each bar; today the same node participates in the existing
/// stack expansion rules.
public struct _OpenToolbarSpacer: _OpenView {
    public typealias Body = Never
    public let sizing: ToolbarSpacerSizing
    public let placement: ToolbarItemPlacement

    public init(
        _ sizing: ToolbarSpacerSizing = .fixed,
        placement: ToolbarItemPlacement = .automatic
    ) {
        self.sizing = sizing
        self.placement = placement
    }

    public func _makeOpenUIKitNode() -> _OpenViewNode {
        _OpenViewNode(.spacer(minLength: sizing == .flexible ? nil : 0))
    }
}

/// System-supplied toolbar affordances remain semantic nodes. Search is
/// rendered by the enclosing `searchable` configuration; the toolbar item is
/// its discoverable magnifying-glass affordance.
public struct _OpenDefaultToolbarItem: _OpenView {
    public typealias Body = Never
    public let kind: DefaultToolbarItemKind
    public let placement: ToolbarItemPlacement

    public init(
        kind: DefaultToolbarItemKind,
        placement: ToolbarItemPlacement = .automatic
    ) {
        self.kind = kind
        self.placement = placement
    }

    public func _makeOpenUIKitNode() -> _OpenViewNode {
        switch kind {
        case .search:
            return _OpenImage(systemName: "magnifyingglass")._makeOpenUIKitNode()
        }
    }
}

/// A menu is a real primary-action UIButton at render time. Its label stays
/// in the SwiftUI node graph (so styles, symbols, and accessibility compose)
/// while its content is converted to OpenUIKit's UIMenu/UIAction tree.
public struct _OpenMenu<Label: _OpenView, Content: _OpenView>: _OpenView {
    public typealias Body = Never
    public let content: Content
    public let label: Label

    public init(
        @_OpenViewBuilder content: () -> Content,
        @_OpenViewBuilder label: () -> Label
    ) {
        self.content = content()
        self.label = label()
    }

    public func _makeOpenUIKitNode() -> _OpenViewNode {
        let labelNode = _OpenGraphContext.withStructuralScope(.buttonLabel) {
            label._makeOpenUIKitNode()
        }
        let contentNode = _OpenGraphContext.withStructuralScope(.menuContent) {
            content._makeOpenUIKitNode()
        }
        return _OpenViewNode(
            .menu(label: labelNode, pressedLabel: nil, content: contentNode)
        )
    }
}

public struct _OpenTabView<SelectionValue: Hashable, Content: _OpenView>: _OpenView {
    public typealias Body = Never
    public let selection: Binding<SelectionValue>
    public let content: Content

    public init(
        selection: Binding<SelectionValue>,
        @_OpenViewBuilder content: () -> Content
    ) {
        self.selection = selection
        self.content = content()
    }

    public func _makeOpenUIKitNode() -> _OpenViewNode {
        let contentNode = _OpenGraphContext.withStructuralScope(.tabViewContent) {
            content._makeOpenUIKitNode()
        }
        let pages = _openFlattenGroup(contentNode).map { child in
            let (pageContent, tag) = _openExtractTag(child)
            return _OpenTabPage(content: pageContent, tag: tag)
        }
        return _OpenViewNode(
            .tabView(
                pages: pages,
                selection: AnyHashable(selection.wrappedValue),
                setSelection: { tag in
                    guard let value = tag.base as? SelectionValue else { return }
                    selection.wrappedValue = value
                },
                indexDisplayMode: nil
            )
        )
    }
}

/// Context retained for one stable UIViewControllerRepresentable graph
/// location. Coordinators are created with their controller and survive body
/// reevaluation until that structural location leaves the graph.
public struct _OpenUIViewControllerRepresentableContext<Representable>
    where Representable: _OpenUIViewControllerRepresentable
{
    public let coordinator: Representable.Coordinator

    init(coordinator: Representable.Coordinator) {
        self.coordinator = coordinator
    }
}

/// Context retained for one stable UIViewRepresentable graph location. The
/// coordinator is created once with the represented view and reused for every
/// subsequent update, matching SwiftUI's identity contract.
public struct _OpenUIViewRepresentableContext<Representable>
    where Representable: _OpenUIViewRepresentable
{
    public let coordinator: Representable.Coordinator

    init(coordinator: Representable.Coordinator) {
        self.coordinator = coordinator
    }
}

@MainActor
public protocol _OpenUIViewRepresentable: _OpenView where Body == Never {
    associatedtype UIViewType: UIView
    associatedtype Coordinator = Void

    func makeUIView(
        context: _OpenUIViewRepresentableContext<Self>
    ) -> UIViewType
    func updateUIView(
        _ uiView: UIViewType,
        context: _OpenUIViewRepresentableContext<Self>
    )
    func makeCoordinator() -> Coordinator
    static func dismantleUIView(_ uiView: UIViewType, coordinator: Coordinator)
}

public extension _OpenUIViewRepresentable {
    typealias Context = _OpenUIViewRepresentableContext<Self>

    static func dismantleUIView(_ uiView: UIViewType, coordinator: Coordinator) {
        _ = uiView
        _ = coordinator
    }

    func _makeOpenUIKitNode() -> _OpenViewNode {
        _OpenGraphContext.withView(self) { preparedView in
            let view = _OpenGraphContext.representedView(
                makeCoordinator: { preparedView.makeCoordinator() },
                make: { coordinator in
                    preparedView.makeUIView(
                        context: Context(coordinator: coordinator)
                    )
                },
                update: { view, coordinator in
                    preparedView.updateUIView(
                        view,
                        context: Context(coordinator: coordinator)
                    )
                },
                dismantle: { view, coordinator in
                    Self.dismantleUIView(view, coordinator: coordinator)
                }
            )
            return _OpenViewNode(.view(view))
        }
    }
}

public extension _OpenUIViewRepresentable where Coordinator == Void {
    func makeCoordinator() {}
}

@MainActor
public protocol _OpenUIViewControllerRepresentable: _OpenView where Body == Never {
    associatedtype UIViewControllerType: UIViewController
    associatedtype Coordinator = Void

    func makeUIViewController(
        context: _OpenUIViewControllerRepresentableContext<Self>
    ) -> UIViewControllerType
    func updateUIViewController(
        _ uiViewController: UIViewControllerType,
        context: _OpenUIViewControllerRepresentableContext<Self>
    )
    func makeCoordinator() -> Coordinator
    static func dismantleUIViewController(
        _ uiViewController: UIViewControllerType,
        coordinator: Coordinator
    )
}

public extension _OpenUIViewControllerRepresentable {
    typealias Context = _OpenUIViewControllerRepresentableContext<Self>

    static func dismantleUIViewController(
        _ uiViewController: UIViewControllerType,
        coordinator: Coordinator
    ) {
        _ = uiViewController
        _ = coordinator
    }

    func _makeOpenUIKitNode() -> _OpenViewNode {
        _OpenGraphContext.withView(self) { preparedView in
            let controller = _OpenGraphContext.representedController(
                makeCoordinator: { preparedView.makeCoordinator() },
                make: { coordinator in
                    preparedView.makeUIViewController(
                        context: Context(coordinator: coordinator)
                    )
                },
                update: { controller, coordinator in
                    preparedView.updateUIViewController(
                        controller,
                        context: Context(coordinator: coordinator)
                    )
                },
                dismantle: { controller, coordinator in
                    Self.dismantleUIViewController(
                        controller,
                        coordinator: coordinator
                    )
                }
            )
            return _OpenViewNode(.viewController(controller))
        }
    }
}

public extension _OpenUIViewControllerRepresentable where Coordinator == Void {
    func makeCoordinator() {}
}

/// A portable SwiftUI animation transaction.  The value is intentionally
/// independent of Core Animation: the OpenUIKit host translates it into the
/// same deterministic UIView animation clock used by UIKit transitions.
public struct _OpenAnimation: Hashable, Sendable {
    indirect enum Storage: Hashable, Sendable {
        case cubic(
            c1x: Double,
            c1y: Double,
            c2x: Double,
            c2y: Double,
            duration: Double
        )
        case spring(response: Double, dampingFraction: Double, blendDuration: Double)
        case repeated(Storage, autoreverses: Bool)
    }

    let storage: Storage

    private init(storage: Storage) {
        self.storage = storage
    }

    public static let `default` = easeInOut(duration: 0.35)
    public static let linear = linear(duration: 0.35)
    public static let easeIn = easeIn(duration: 0.35)
    public static let easeOut = easeOut(duration: 0.35)
    public static let easeInOut = easeInOut(duration: 0.35)

    public static func linear(duration: Double) -> _OpenAnimation {
        timingCurve(0, 0, 1, 1, duration: duration)
    }

    public static func easeIn(duration: Double) -> _OpenAnimation {
        timingCurve(0.42, 0, 1, 1, duration: duration)
    }

    public static func easeOut(duration: Double) -> _OpenAnimation {
        timingCurve(0, 0, 0.58, 1, duration: duration)
    }

    public static func easeInOut(duration: Double) -> _OpenAnimation {
        timingCurve(0.42, 0, 0.58, 1, duration: duration)
    }

    public static func timingCurve(
        _ c1x: Double,
        _ c1y: Double,
        _ c2x: Double,
        _ c2y: Double,
        duration: Double = 0.35
    ) -> _OpenAnimation {
        _OpenAnimation(
            storage: .cubic(
                c1x: c1x,
                c1y: c1y,
                c2x: c2x,
                c2y: c2y,
                duration: max(0, duration)
            )
        )
    }

    public static func spring(
        response: Double = 0.55,
        dampingFraction: Double = 0.825,
        blendDuration: Double = 0
    ) -> _OpenAnimation {
        _OpenAnimation(
            storage: .spring(
                response: max(0, response),
                dampingFraction: min(max(0, dampingFraction), 1),
                blendDuration: max(0, blendDuration)
            )
        )
    }

    /// Repeats the receiver for as long as it remains installed in the view
    /// graph. Each leg keeps the receiver's exact timing curve; autoreverse
    /// alternates the presentation direction without changing the model.
    public func repeatForever(autoreverses: Bool = true) -> _OpenAnimation {
        _OpenAnimation(storage: .repeated(storage, autoreverses: autoreverses))
    }
}

public typealias Animation = _OpenAnimation

@MainActor
enum _OpenAnimationContext {
    static var current: Animation?

    static func withAnimation<Result>(
        _ animation: Animation?,
        operation: () throws -> Result
    ) rethrows -> Result {
        let previous = current
        current = animation
        defer { current = previous }
        return try operation()
    }
}

@MainActor
@discardableResult
public func withAnimation<Result>(
    _ animation: Animation? = .default,
    _ body: () throws -> Result
) rethrows -> Result {
    try _OpenAnimationContext.withAnimation(animation, operation: body)
}

@MainActor
func _openFlattenGroup(_ node: _OpenViewNode) -> [_OpenViewNode] {
    if case .group(let children) = node.kind {
        return children.flatMap { _openFlattenGroup($0) }
    }
    // MEASURED realapp_hackers_feed_light, iPhone 16 @3x / iOS 26.1:
    // `if let whatsNewPanel` / `if enableSearchPagination` false branches
    // are Optional.none → `.empty`. Real List does not materialize those
    // as cells (7 visible ListCollectionViewCell, no 44 pt spacers). The
    // port floored empty rows to defaultFormRowHeight and shifted the
    // feed by 44 pt.
    if case .empty = node.kind {
        return []
    }
    return [node]
}

@MainActor
func _openExtractTag(
    _ node: _OpenViewNode
) -> (content: _OpenViewNode, tag: AnyHashable?) {
    guard case .modified(let content, let modification) = node.kind else {
        return (node, nil)
    }
    if case .tag(let tag) = modification {
        return (content, tag)
    }
    let extracted = _openExtractTag(content)
    guard let tag = extracted.tag else { return (node, nil) }
    return (_OpenViewNode(.modified(extracted.content, modification)), tag)
}

@MainActor
func _openApplyingPageTabViewStyle(
    _ node: _OpenViewNode,
    indexDisplayMode: PageTabViewStyle.IndexDisplayMode
) -> _OpenViewNode {
    switch node.kind {
    case .tabView(let pages, let selection, let setSelection, _):
        return _OpenViewNode(
            .tabView(
                pages: pages,
                selection: selection,
                setSelection: setSelection,
                indexDisplayMode: indexDisplayMode
            )
        )
    case .modified(let content, let modification):
        return _OpenViewNode(
            .modified(
                _openApplyingPageTabViewStyle(
                    content,
                    indexDisplayMode: indexDisplayMode
                ),
                modification
            )
        )
    default:
        return _OpenViewNode(.modified(node, .pageTabViewStyle(indexDisplayMode)))
    }
}

public typealias TextAlignment = _OpenTextAlignment
public typealias ColorScheme = _OpenColorScheme
public typealias NavigationBarTitleDisplayMode = _OpenNavigationBarTitleDisplayMode
public typealias ScrollDismissesKeyboardMode = _OpenScrollDismissesKeyboardMode
public typealias ControlSize = _OpenControlSize
public typealias SymbolRenderingMode = _OpenSymbolRenderingMode
public typealias ToolbarItemPlacement = _OpenToolbarItemPlacement
public typealias ToolbarSpacerSizing = _OpenToolbarSpacerSizing
public typealias DefaultToolbarItemKind = _OpenDefaultToolbarItemKind
public typealias SearchFieldPlacement = _OpenSearchFieldPlacement
public typealias SearchToolbarBehavior = _OpenSearchToolbarBehavior
public typealias ListStyle = _OpenListStyle
public typealias GroupedListStyle = _OpenGroupedListStyle
public typealias GeometryProxy = _OpenGeometryProxy
public typealias CoordinateSpace = _OpenCoordinateSpace
public typealias PageTabViewStyle = _OpenPageTabViewStyle
public typealias EdgeInsets = _OpenEdgeInsets
public typealias Transaction = _OpenTransaction
public typealias PreferenceKey = _OpenPreferenceKey
public typealias ScrollGeometry = _OpenScrollGeometry
public typealias ScrollPhase = _OpenScrollPhase
public typealias ScrollPhaseChangeContext = _OpenScrollPhaseChangeContext
public typealias ScrollViewProxy = _OpenScrollViewProxy
public typealias Gesture = _OpenGesture
public typealias DragGesture = _OpenDragGesture
public typealias LongPressGesture = _OpenLongPressGesture
public typealias PinnedScrollableViews = _OpenPinnedScrollableViews
public typealias ProposedViewSize = _OpenProposedViewSize
public typealias LayoutSubview = _OpenLayoutSubview
public typealias LayoutSubviews = _OpenLayoutSubviews
public typealias Subviews = _OpenLayoutSubviews
public typealias Layout = _OpenLayout
public typealias TapGesture = _OpenTapGesture
public typealias ZStack<Content> = _OpenZStack<Content> where Content: _OpenView
public typealias GlassEffectContainer<Content> = _OpenGlassEffectContainer<Content>
    where Content: _OpenView
public typealias Button<Label> = _OpenButton<Label> where Label: _OpenView
public typealias ScrollView<Content> = _OpenScrollView<Content> where Content: _OpenView
public typealias ScrollViewReader<Content> = _OpenScrollViewReader<Content> where Content: _OpenView
public typealias LazyVStack<Content> = _OpenLazyVStack<Content> where Content: _OpenView
public typealias GeometryReader<Content> = _OpenGeometryReader<Content> where Content: _OpenView
public typealias ToolbarItem<Content> = _OpenToolbarItem<Content> where Content: _OpenView
public typealias ToolbarSpacer = _OpenToolbarSpacer
public typealias DefaultToolbarItem = _OpenDefaultToolbarItem
public typealias Menu<Label, Content> = _OpenMenu<Label, Content>
    where Label: _OpenView, Content: _OpenView
public typealias TabView<SelectionValue, Content> = _OpenTabView<SelectionValue, Content>
    where SelectionValue: Hashable, Content: _OpenView
public typealias UIViewControllerRepresentableContext<Representable> =
    _OpenUIViewControllerRepresentableContext<Representable>
    where Representable: _OpenUIViewControllerRepresentable
public typealias UIViewControllerRepresentable = _OpenUIViewControllerRepresentable
public typealias UIViewRepresentableContext<Representable> =
    _OpenUIViewRepresentableContext<Representable>
    where Representable: _OpenUIViewRepresentable
public typealias UIViewRepresentable = _OpenUIViewRepresentable
