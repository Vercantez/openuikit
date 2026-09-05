// SwiftUI S1/S1.5 composition plus the bounded S2 observation runtime.
//
// This is deliberately a small, honest implementation. It covers the syntax
// used by Focus's SearchWidgetView and DesignSystem previews plus the S2
// state/observation semantics documented in docs/SWIFTUI_S2.md, turning that
// bounded surface into an OpenUIKit hierarchy. It is not a claim that
// arbitrary SwiftUI works.

#if canImport(Foundation)
@_exported import Foundation
#elseif canImport(FoundationEssentials)
@_exported import FoundationEssentials
#endif
import Combine
@_exported import OpenUIKit

@preconcurrency @MainActor
public protocol _OpenView {
    associatedtype Body: _OpenView

    @_OpenViewBuilder var body: Body { get }

    /// Underscored implementation hook used by the OpenUIKit host.  App view
    /// types receive the body-based default and do not implement this method.
    func _makeOpenUIKitNode() -> _OpenViewNode
}

public extension _OpenView {
    func modifier<Modifier: ViewModifier>(_ modifier: Modifier) -> some _OpenView {
        _OpenAppliedViewModifier(source: self, modifier: modifier)
    }

    func buttonStyle<Style: ButtonStyle>(_ style: Style) -> some _OpenView {
        _OpenButtonStyleContent(source: self, style: style)
    }

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

@MainActor
final class _OpenGeometryNode {
    private let builder: @MainActor (CGSize) -> _OpenViewNode
    private var cachedSize: CGSize?
    private var cachedNode: _OpenViewNode?

    init(builder: @escaping @MainActor (CGSize) -> _OpenViewNode) {
        self.builder = builder
    }

    func resolve(_ size: CGSize) -> _OpenViewNode {
        let bounded = CGSize(
            width: size.width.isFinite ? max(0, size.width) : 10_000,
            height: size.height.isFinite ? max(0, size.height) : 10_000
        )
        if cachedSize == bounded, let cachedNode { return cachedNode }
        let node = builder(bounded)
        cachedSize = bounded
        cachedNode = node
        return node
    }
}

indirect enum _OpenViewNodeKind {
    case empty
    case group([_OpenViewNode])
    case text(String)
    case image(_OpenImageSource)
    case color(Color)
    case roundedRectangle(cornerRadius: CGFloat, style: _OpenRoundedRectangleStyle)
    case capsule(_OpenRoundedRectangleStyle)
    case divider
    case progress(value: Double?, total: Double)
    case slider(
        value: Double,
        minimum: Double,
        maximum: Double,
        step: Double,
        setValue: @MainActor (Double) -> Void
    )
    case spacer(minLength: CGFloat?)
    case hStack(children: [_OpenViewNode], alignment: VerticalAlignment, spacing: CGFloat?)
    case vStack(children: [_OpenViewNode], alignment: HorizontalAlignment, spacing: CGFloat?)
    case zStack(children: [_OpenViewNode], alignment: Alignment)
    case grid(
        rows: [_OpenViewNode],
        horizontalSpacing: CGFloat?,
        verticalSpacing: CGFloat?
    )
    case gridRow([_OpenViewNode])
    case button(
        label: _OpenViewNode,
        pressedLabel: _OpenViewNode?,
        role: ButtonRole?,
        action: @MainActor () -> Void
    )
    case menu(
        label: _OpenViewNode,
        pressedLabel: _OpenViewNode?,
        content: _OpenViewNode
    )
    case geometry(_OpenGeometryNode)
    case scroll(content: _OpenViewNode)
    case scrollReader(content: _OpenViewNode, storage: _OpenScrollProxyStorage)
    case customLayout(layout: any Layout, children: [_OpenViewNode])
    case tabView(
        pages: [_OpenTabPage],
        selection: AnyHashable,
        setSelection: @MainActor (AnyHashable) -> Void,
        indexDisplayMode: PageTabViewStyle.IndexDisplayMode?
    )
    case view(UIView)
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
        isSecure: Bool,
        axis: Axis,
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
    case link(label: _OpenViewNode, destination: URL)
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

struct _OpenAlertConfiguration {
    let title: String
    let getIsPresented: @MainActor () -> Bool
    let setIsPresented: @MainActor (Bool) -> Void
    let actions: _OpenViewNode
    let message: _OpenViewNode
}

enum _OpenPresentationKind: Equatable {
    case sheet
    case navigationDestination
}

/// Reference storage lets an already-presented destination adopt the newest
/// binding closures after its parent graph re-evaluates.  It is captured by
/// `DismissAction` across Swift's sendable boundary, while every access stays
/// on the UI actor.
@MainActor
final class _OpenPresentationState: @unchecked Sendable {
    let getIsPresented: @MainActor () -> Bool
    let setIsPresented: @MainActor (Bool) -> Void
    let onDismiss: @MainActor () -> Void

    init(
        getIsPresented: @escaping @MainActor () -> Bool,
        setIsPresented: @escaping @MainActor (Bool) -> Void,
        onDismiss: @escaping @MainActor () -> Void = {}
    ) {
        self.getIsPresented = getIsPresented
        self.setIsPresented = setIsPresented
        self.onDismiss = onDismiss
    }

    func dismiss() {
        setIsPresented(false)
    }
}

struct _OpenPresentationConfiguration {
    let identity: _OpenGraphIdentity?
    let kind: _OpenPresentationKind
    let state: _OpenPresentationState
    let makeDestination: @MainActor (DismissAction) -> AnyView
}

/// Type-erased typed destination registration carried through the rendered
/// tree until the enclosing NavigationStack consumes it. Matching is exact:
/// an unsupported path element never produces a placeholder controller.
@MainActor
struct _OpenNavigationDestinationRegistration {
    let valueType: ObjectIdentifier
    let matches: (AnyHashable) -> Bool
    let makeNode: (AnyHashable) -> _OpenViewNode?
}

/// A single already-evaluated destination. Its dynamic properties belong to
/// the parent graph, while the retained UIKit navigation controller owns only
/// presentation and back-stack lifetime.
@MainActor
struct _OpenNavigationResolvedDestination {
    let value: AnyHashable
    let node: _OpenViewNode
    let configuration: _OpenNavigationConfiguration
}

@MainActor
struct _OpenNavigationPathBinding {
    let getElements: () -> [AnyHashable]
    let setElements: ([AnyHashable]) -> Void

    func dismissDestination(at index: Int) {
        let elements = getElements()
        guard index >= 0, index < elements.count else { return }
        setElements(Array(elements.prefix(index)))
    }
}

struct _OpenSearchConfiguration {
    let getText: @MainActor () -> String
    let setText: @MainActor (String) -> Void
    let prompt: String
    let placement: SearchFieldPlacement
}

struct _OpenPreferenceRecord {
    let key: ObjectIdentifier
    let value: Any
}

struct _OpenPreferenceListener {
    let key: ObjectIdentifier
    let defaultValue: Any
    let reduce: (inout Any, Any) -> Void
    let action: @MainActor (Any) -> Void
}

struct _OpenScrollVisibilityObserver {
    let threshold: CGFloat
    let deliver: @MainActor ([AnyHashable]) -> Void
}

struct _OpenScrollGeometryObserver {
    let read: @MainActor (ScrollGeometry) -> Any
    let equals: (Any, Any) -> Bool
    let deliver: @MainActor (Any, Any) -> Void
}

struct _OpenScrollPhaseObserver {
    let deliver: @MainActor (
        ScrollPhase,
        ScrollPhase,
        ScrollPhaseChangeContext
    ) -> Void
}

struct _OpenGeometryObserver {
    let read: @MainActor (GeometryProxy) -> Any
    let deliver: @MainActor (Any) -> Void
}

enum _OpenViewModification {
    case font(Font?)
    case fontWeight(Font.Weight?)
    case monospacedDigits
    case minimumScaleFactor(CGFloat)
    case allowsTightening(Bool)
    case foregroundColor(Color?)
    case tint(Color?)
    case opacity(CGFloat)
    case brightness(Double)
    case saturation(Double)
    case scaleEffect(CGFloat)
    case anchoredScaleEffect(CGFloat, UnitPoint)
    case rotationEffect(Angle, UnitPoint)
    case offset(CGSize)
    case lineLimit(Int?)
    case lineLimitRange(ClosedRange<Int>)
    case truncationMode(TextTruncationMode)
    case layoutPriority(Double)
    case fixedSize(horizontal: Bool, vertical: Bool)
    case frame(width: CGFloat?, height: CGFloat?, alignment: Alignment)
    case flexibleFrame(
        minWidth: CGFloat?,
        maxWidth: CGFloat?,
        minHeight: CGFloat?,
        maxHeight: CGFloat?,
        alignment: Alignment
    )
    case padding(Edge.Set, CGFloat?)
    case edgeInsetsPadding(EdgeInsets)
    case background(_OpenViewNode, alignment: Alignment)
    case overlay(_OpenViewNode, alignment: Alignment)
    case mask(_OpenViewNode, alignment: Alignment)
    case resizable
    case aspectRatio(CGFloat?, ContentMode)
    case multilineTextAlignment(TextAlignment)
    case tapAction(@MainActor () -> Void)
    case simultaneousTapAction(@MainActor () -> Void)
    case gesture(_OpenGestureNode)
    case onAppear(identity: _OpenGraphIdentity?, action: @MainActor () -> Void)
    case onDisappear(identity: _OpenGraphIdentity?, action: @MainActor () -> Void)
    case openURL(@MainActor (URL) -> Void)
    case shadow(color: Color, radius: CGFloat, x: CGFloat, y: CGFloat)
    case colorScheme(ColorScheme)
    case safeAreaIgnored(Edge.Set)
    case previewLayout(PreviewLayout)
    case clipRoundedRectangle(CGFloat, CACornerMask)
    case clipped
    case hidden
    case navigationTitle(String)
    case navigationBarHidden(Bool)
    case navigationBackButtonHidden(Bool)
    case navigationTitleDisplayMode(NavigationBarTitleDisplayMode)
    case navigationDestination(_OpenNavigationDestinationRegistration)
    case toolbar(_OpenViewNode)
    case tag(AnyHashable)
    case pageTabViewStyle(PageTabViewStyle.IndexDisplayMode)
    case disabled(Bool)
    case accessibilityHidden(Bool)
    case accessibilityElement(AccessibilityChildBehavior)
    case accessibilityLabel(String)
    case accessibilityHint(String)
    case accessibilityValue(String)
    case accessibilityTraits(AccessibilityTraits)
    case allowsHitTesting(Bool)
    case zIndex(Double)
    case focus(get: @MainActor () -> Bool, set: @MainActor (Bool) -> Void)
    case textContentType(UITextContentType?)
    case autocapitalization(UITextAutocapitalizationType)
    case autocorrectionDisabled(Bool)
    case submit(@MainActor () -> Void)
    case submitLabel(SubmitLabel)
    case scrollDismissesKeyboard(ScrollDismissesKeyboardMode)
    case scrollDisabled(Bool)
    case scrollPhase(_OpenScrollPhaseObserver)
    case controlSize(ControlSize)
    case imageScale(ImageScale)
    case circularProgressStyle
    case linearProgressStyle
    case compositingGroup
    case menuPickerStyle
    case symbolRenderingMode(SymbolRenderingMode?)
    case accessibilityIdentifier(String)
    case alert(_OpenAlertConfiguration)
    case presentation(_OpenPresentationConfiguration)
    case glassEffect
    case buttonBorderShape(ButtonBorderShape)
    case accessibilityAction(name: String?, action: @MainActor () -> Void)
    case identifier(AnyHashable)
    case preference(_OpenPreferenceRecord)
    case preferenceListener(_OpenPreferenceListener)
    case scrollVisibility(_OpenScrollVisibilityObserver)
    case scrollGeometry(_OpenScrollGeometryObserver)
    case geometryObserver(_OpenGeometryObserver)
    case refreshable(@MainActor () async -> Void)
    case safeAreaInset(edge: Edge, spacing: CGFloat?, content: _OpenViewNode)
    case scrollIndicators(Visibility)
    case toolbarVisibility(Visibility, ToolbarPlacement)
    case toolbarBackgroundVisibility(Visibility, ToolbarPlacement)
    case swipeActions(edge: Edge, allowsFullSwipe: Bool, actions: _OpenViewNode)
    case contextMenu(_OpenViewNode)
    case matchedGeometry(id: AnyHashable, namespace: Namespace.ID, isSource: Bool)
    case listStyle(ListStyle)
    case listRowBackground(_OpenViewNode)
    case listRowSeparator(Visibility, VerticalEdge.Set)
    case searchable(_OpenSearchConfiguration)
    case searchToolbarBehavior(SearchToolbarBehavior)
    case menuIndicator(Visibility)
    case toolbarItem(ToolbarItemPlacement)
    case projection(@MainActor (CGSize) -> ProjectionTransform)
    case effect
}

/// Construction-time modifier payload. Background and overlay views remain
/// deferred until their modified content is reached through the structural
/// tree; evaluating them while a parent body is being assembled would flatten
/// sibling tuple/stack scopes and alias their dynamic state.
fileprivate enum _OpenViewModifier {
    case font(Font?)
    case fontWeight(Font.Weight?)
    case monospacedDigits
    case minimumScaleFactor(CGFloat)
    case allowsTightening(Bool)
    case foregroundColor(Color?)
    case tint(Color?)
    case opacity(CGFloat)
    case brightness(Double)
    case saturation(Double)
    case scaleEffect(CGFloat)
    case anchoredScaleEffect(CGFloat, UnitPoint)
    case rotationEffect(Angle, UnitPoint)
    case offset(CGSize)
    case lineLimit(Int?)
    case lineLimitRange(ClosedRange<Int>)
    case truncationMode(TextTruncationMode)
    case layoutPriority(Double)
    case fixedSize(horizontal: Bool, vertical: Bool)
    case frame(width: CGFloat?, height: CGFloat?, alignment: Alignment)
    case flexibleFrame(
        minWidth: CGFloat?,
        maxWidth: CGFloat?,
        minHeight: CGFloat?,
        maxHeight: CGFloat?,
        alignment: Alignment
    )
    case padding(Edge.Set, CGFloat?)
    case edgeInsetsPadding(EdgeInsets)
    case background(@MainActor () -> _OpenViewNode, alignment: Alignment)
    case overlay(@MainActor () -> _OpenViewNode, alignment: Alignment)
    case mask(@MainActor () -> _OpenViewNode, alignment: Alignment)
    case resizable
    case aspectRatio(CGFloat?, ContentMode)
    case multilineTextAlignment(TextAlignment)
    case tapAction(@MainActor () -> Void)
    case simultaneousTapAction(@MainActor () -> Void)
    case gesture(_OpenGestureNode)
    case onAppear(@MainActor () -> Void)
    case onDisappear(@MainActor () -> Void)
    case openURL(@MainActor (URL) -> Void)
    case shadow(color: Color, radius: CGFloat, x: CGFloat, y: CGFloat)
    case colorScheme(ColorScheme)
    case safeAreaIgnored(Edge.Set)
    case previewLayout(PreviewLayout)
    case clipRoundedRectangle(CGFloat, CACornerMask)
    case clipped
    case hidden
    case navigationTitle(String)
    case navigationBarHidden(Bool)
    case navigationBackButtonHidden(Bool)
    case navigationTitleDisplayMode(NavigationBarTitleDisplayMode)
    case navigationDestination(_OpenNavigationDestinationRegistration)
    case toolbar(@MainActor () -> _OpenViewNode)
    case tag(AnyHashable)
    case pageTabViewStyle(PageTabViewStyle.IndexDisplayMode)
    case disabled(Bool)
    case accessibilityHidden(Bool)
    case accessibilityElement(AccessibilityChildBehavior)
    case accessibilityLabel(String)
    case accessibilityHint(String)
    case accessibilityValue(String)
    case accessibilityTraits(AccessibilityTraits)
    case allowsHitTesting(Bool)
    case zIndex(Double)
    case focus(get: @MainActor () -> Bool, set: @MainActor (Bool) -> Void)
    case textContentType(UITextContentType?)
    case autocapitalization(UITextAutocapitalizationType)
    case autocorrectionDisabled(Bool)
    case submit(@MainActor () -> Void)
    case submitLabel(SubmitLabel)
    case scrollDismissesKeyboard(ScrollDismissesKeyboardMode)
    case scrollDisabled(Bool)
    case scrollPhase(_OpenScrollPhaseObserver)
    case controlSize(ControlSize)
    case imageScale(ImageScale)
    case circularProgressStyle
    case linearProgressStyle
    case compositingGroup
    case menuPickerStyle
    case symbolRenderingMode(SymbolRenderingMode?)
    case accessibilityIdentifier(String)
    case alert(
        title: String,
        getIsPresented: @MainActor () -> Bool,
        setIsPresented: @MainActor (Bool) -> Void,
        actions: @MainActor () -> _OpenViewNode,
        message: @MainActor () -> _OpenViewNode
    )
    case presentation(
        kind: _OpenPresentationKind,
        state: _OpenPresentationState,
        makeDestination: @MainActor (DismissAction) -> AnyView
    )
    case glassEffect
    case buttonBorderShape(ButtonBorderShape)
    case accessibilityAction(name: String?, action: @MainActor () -> Void)
    case identifier(AnyHashable)
    case preference(_OpenPreferenceRecord)
    case preferenceListener(_OpenPreferenceListener)
    case scrollVisibility(_OpenScrollVisibilityObserver)
    case scrollGeometry(_OpenScrollGeometryObserver)
    case geometryObserver(_OpenGeometryObserver)
    case refreshable(@MainActor () async -> Void)
    case safeAreaInset(
        edge: Edge,
        spacing: CGFloat?,
        content: @MainActor () -> _OpenViewNode
    )
    case scrollIndicators(Visibility)
    case toolbarVisibility(Visibility, ToolbarPlacement)
    case toolbarBackgroundVisibility(Visibility, ToolbarPlacement)
    case swipeActions(
        edge: Edge,
        allowsFullSwipe: Bool,
        actions: @MainActor () -> _OpenViewNode
    )
    case contextMenu(@MainActor () -> _OpenViewNode)
    case matchedGeometry(id: AnyHashable, namespace: Namespace.ID, isSource: Bool)
    case listStyle(ListStyle)
    case listRowBackground(@MainActor () -> _OpenViewNode)
    case listRowSeparator(Visibility, VerticalEdge.Set)
    case searchable(_OpenSearchConfiguration)
    case searchToolbarBehavior(SearchToolbarBehavior)
    case menuIndicator(Visibility)
    case projection(@MainActor (CGSize) -> ProjectionTransform)
    case effect
    case onChange(@MainActor () -> Void)
    case animation(@MainActor () -> Void)
    case onReceive(@MainActor () -> Void)
    case task(@MainActor () -> Void)

    @MainActor
    func resolve() -> _OpenViewModification {
        switch self {
        case .font(let value): return .font(value)
        case .fontWeight(let value): return .fontWeight(value)
        case .monospacedDigits: return .monospacedDigits
        case .minimumScaleFactor(let value): return .minimumScaleFactor(value)
        case .allowsTightening(let value): return .allowsTightening(value)
        case .foregroundColor(let value): return .foregroundColor(value)
        case .tint(let value): return .tint(value)
        case .opacity(let value): return .opacity(value)
        case .brightness(let value): return .brightness(value)
        case .saturation(let value): return .saturation(value)
        case .scaleEffect(let value): return .scaleEffect(value)
        case .anchoredScaleEffect(let value, let anchor):
            return .anchoredScaleEffect(value, anchor)
        case .rotationEffect(let angle, let anchor):
            return .rotationEffect(angle, anchor)
        case .offset(let offset): return .offset(offset)
        case .lineLimit(let value): return .lineLimit(value)
        case .lineLimitRange(let value): return .lineLimitRange(value)
        case .truncationMode(let value): return .truncationMode(value)
        case .layoutPriority(let value): return .layoutPriority(value)
        case .fixedSize(let horizontal, let vertical):
            return .fixedSize(horizontal: horizontal, vertical: vertical)
        case .frame(let width, let height, let alignment):
            return .frame(width: width, height: height, alignment: alignment)
        case .flexibleFrame(let minWidth, let maxWidth, let minHeight, let maxHeight, let alignment):
            return .flexibleFrame(
                minWidth: minWidth,
                maxWidth: maxWidth,
                minHeight: minHeight,
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
        case .mask(let makeNode, let alignment):
            return .mask(
                _OpenGraphContext.withStructuralScope(.overlay, operation: makeNode),
                alignment: alignment
            )
        case .resizable: return .resizable
        case .aspectRatio(let ratio, let mode): return .aspectRatio(ratio, mode)
        case .multilineTextAlignment(let alignment):
            return .multilineTextAlignment(alignment)
        case .tapAction(let action): return .tapAction(action)
        case .simultaneousTapAction(let action): return .simultaneousTapAction(action)
        case .gesture(let gesture): return .gesture(gesture)
        case .onAppear(let action):
            return _OpenGraphContext.withStructuralScope(.onAppear) {
                .onAppear(identity: _OpenGraphContext.currentIdentity(), action: action)
            }
        case .onDisappear(let action):
            return _OpenGraphContext.withStructuralScope(.onDisappear) {
                .onDisappear(identity: _OpenGraphContext.currentIdentity(), action: action)
            }
        case .openURL(let action): return .openURL(action)
        case .shadow(let color, let radius, let x, let y):
            return .shadow(color: color, radius: radius, x: x, y: y)
        case .colorScheme(let scheme): return .colorScheme(scheme)
        case .safeAreaIgnored(let edges): return .safeAreaIgnored(edges)
        case .previewLayout(let value): return .previewLayout(value)
        case .clipRoundedRectangle(let radius, let corners):
            return .clipRoundedRectangle(radius, corners)
        case .clipped: return .clipped
        case .hidden: return .hidden
        case .navigationTitle(let title): return .navigationTitle(title)
        case .navigationBarHidden(let hidden): return .navigationBarHidden(hidden)
        case .navigationBackButtonHidden(let hidden):
            return .navigationBackButtonHidden(hidden)
        case .navigationTitleDisplayMode(let mode):
            return .navigationTitleDisplayMode(mode)
        case .navigationDestination(let registration):
            return .navigationDestination(registration)
        case .toolbar(let makeNode):
            return .toolbar(
                _OpenGraphContext.withStructuralScope(.toolbar, operation: makeNode)
            )
        case .tag(let value): return .tag(value)
        case .pageTabViewStyle(let mode): return .pageTabViewStyle(mode)
        case .disabled(let disabled): return .disabled(disabled)
        case .accessibilityHidden(let hidden): return .accessibilityHidden(hidden)
        case .accessibilityElement(let children): return .accessibilityElement(children)
        case .accessibilityLabel(let label): return .accessibilityLabel(label)
        case .accessibilityHint(let hint): return .accessibilityHint(hint)
        case .accessibilityValue(let value): return .accessibilityValue(value)
        case .accessibilityTraits(let traits): return .accessibilityTraits(traits)
        case .allowsHitTesting(let enabled): return .allowsHitTesting(enabled)
        case .zIndex(let value): return .zIndex(value)
        case .focus(let get, let set): return .focus(get: get, set: set)
        case .textContentType(let value): return .textContentType(value)
        case .autocapitalization(let value): return .autocapitalization(value)
        case .autocorrectionDisabled(let value): return .autocorrectionDisabled(value)
        case .submit(let action): return .submit(action)
        case .submitLabel(let label): return .submitLabel(label)
        case .scrollDismissesKeyboard(let mode): return .scrollDismissesKeyboard(mode)
        case .scrollDisabled(let disabled): return .scrollDisabled(disabled)
        case .scrollPhase(let observer): return .scrollPhase(observer)
        case .controlSize(let size): return .controlSize(size)
        case .imageScale(let scale): return .imageScale(scale)
        case .circularProgressStyle: return .circularProgressStyle
        case .linearProgressStyle: return .linearProgressStyle
        case .compositingGroup: return .compositingGroup
        case .menuPickerStyle: return .menuPickerStyle
        case .symbolRenderingMode(let mode): return .symbolRenderingMode(mode)
        case .accessibilityIdentifier(let identifier):
            return .accessibilityIdentifier(identifier)
        case .alert(let title, let getIsPresented, let setIsPresented,
                    let makeActions, let makeMessage):
            return .alert(
                _OpenAlertConfiguration(
                    title: title,
                    getIsPresented: getIsPresented,
                    setIsPresented: setIsPresented,
                    actions: _OpenGraphContext.withStructuralScope(
                        .overlay,
                        operation: makeActions
                    ),
                    message: _OpenGraphContext.withStructuralScope(
                        .background,
                        operation: makeMessage
                    )
                )
            )
        case .presentation(let kind, let state, let makeDestination):
            return _OpenGraphContext.withStructuralScope(.presentation) {
                .presentation(
                    _OpenPresentationConfiguration(
                        identity: _OpenGraphContext.currentIdentity(),
                        kind: kind,
                        state: state,
                        makeDestination: makeDestination
                    )
                )
            }
        case .glassEffect: return .glassEffect
        case .buttonBorderShape(let shape): return .buttonBorderShape(shape)
        case .accessibilityAction(let name, let action):
            return .accessibilityAction(name: name, action: action)
        case .identifier(let value): return .identifier(value)
        case .preference(let record): return .preference(record)
        case .preferenceListener(let listener): return .preferenceListener(listener)
        case .scrollVisibility(let observer): return .scrollVisibility(observer)
        case .scrollGeometry(let observer): return .scrollGeometry(observer)
        case .geometryObserver(let observer): return .geometryObserver(observer)
        case .refreshable(let action): return .refreshable(action)
        case .safeAreaInset(let edge, let spacing, let makeContent):
            return .safeAreaInset(
                edge: edge,
                spacing: spacing,
                content: _OpenGraphContext.withStructuralScope(
                    .overlay,
                    operation: makeContent
                )
            )
        case .scrollIndicators(let visibility): return .scrollIndicators(visibility)
        case .toolbarVisibility(let visibility, let placement):
            return .toolbarVisibility(visibility, placement)
        case .toolbarBackgroundVisibility(let visibility, let placement):
            return .toolbarBackgroundVisibility(visibility, placement)
        case .swipeActions(let edge, let allowsFullSwipe, let makeActions):
            return .swipeActions(
                edge: edge,
                allowsFullSwipe: allowsFullSwipe,
                actions: _OpenGraphContext.withStructuralScope(
                    .overlay,
                    operation: makeActions
                )
            )
        case .contextMenu(let makeNode):
            return .contextMenu(
                _OpenGraphContext.withStructuralScope(.overlay, operation: makeNode)
            )
        case .matchedGeometry(let id, let namespace, let isSource):
            return .matchedGeometry(id: id, namespace: namespace, isSource: isSource)
        case .listStyle(let style): return .listStyle(style)
        case .listRowBackground(let makeBackground):
            return .listRowBackground(
                _OpenGraphContext.withStructuralScope(
                    .background,
                    operation: makeBackground
                )
            )
        case .listRowSeparator(let visibility, let edges):
            return .listRowSeparator(visibility, edges)
        case .searchable(let configuration): return .searchable(configuration)
        case .searchToolbarBehavior(let behavior):
            return .searchToolbarBehavior(behavior)
        case .menuIndicator(let visibility): return .menuIndicator(visibility)
        case .projection(let resolve): return .projection(resolve)
        case .effect: return .effect
        case .onChange(let install):
            _OpenGraphContext.withStructuralScope(.onChange) { install() }
            return .effect
        case .animation(let install):
            _OpenGraphContext.withStructuralScope(.animation) { install() }
            return .effect
        case .onReceive(let install):
            _OpenGraphContext.withStructuralScope(.onReceive) { install() }
            return .effect
        case .task(let install):
            _OpenGraphContext.withStructuralScope(.task) { install() }
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
    ) -> _OpenSiblingList {
        _OpenSiblingList(accumulated, next)
    }

    public static func buildPartialBlock<Next: _OpenView>(
        accumulated: _OpenSiblingList,
        next: Next
    ) -> _OpenSiblingList {
        accumulated.appending(next)
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

    nonisolated public init() {}

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

/// Flat result-builder accumulation for blocks with more than one sibling.
///
/// A recursively nested generic tuple makes the constraint solver revisit the
/// entire accumulated type for every additional statement. Real application
/// bodies routinely contain dozens of conditional siblings and modifiers;
/// flattening only the *builder carrier* keeps their source compile time
/// bounded while retaining an explicit structural index for every child.
/// Single-expression blocks still preserve their concrete type through the
/// `buildPartialBlock(first:)` overload above.
public struct _OpenSiblingList: _OpenView {
    public typealias Body = Never
    private let nodeBuilders: [@MainActor () -> _OpenViewNode]

    init<First: _OpenView, Second: _OpenView>(_ first: First, _ second: Second) {
        nodeBuilders = [
            { first._makeOpenUIKitNode() },
            { second._makeOpenUIKitNode() },
        ]
    }

    private init(nodeBuilders: [@MainActor () -> _OpenViewNode]) {
        self.nodeBuilders = nodeBuilders
    }

    func appending<Next: _OpenView>(_ next: Next) -> _OpenSiblingList {
        _OpenSiblingList(nodeBuilders: nodeBuilders + [{ next._makeOpenUIKitNode() }])
    }

    public func _makeOpenUIKitNode() -> _OpenViewNode {
        _OpenViewNode(
            .group(
                nodeBuilders.enumerated().map { index, buildNode in
                    _OpenGraphContext.withStructuralScope(.tupleElement(index)) {
                        buildNode()
                    }
                }
            )
        )
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

/// A semantic, layout-transparent container. Unlike returning builder content
/// directly, Group owns a stable structural scope so dynamic state in a Group
/// cannot alias an adjacent sibling during graph reevaluation.
public struct _OpenGroup<Content: _OpenView>: _OpenView {
    public typealias Body = Never
    public let content: Content

    public init(@_OpenViewBuilder content: () -> Content) {
        self.content = content()
    }

    public func _makeOpenUIKitNode() -> _OpenViewNode {
        _OpenGraphContext.withStructuralScope(.groupContent) {
            content._makeOpenUIKitNode()
        }
    }
}

/// A value-keyed environment scope. It is transparent to layout while the
/// graph prepares every DynamicProperty below it from the scoped value copy.
public struct _OpenEnvironmentValueContent<Content: _OpenView, Value>: _OpenView {
    public typealias Body = Never
    let content: Content
    let keyPath: WritableKeyPath<EnvironmentValues, Value>
    let value: Value

    public func _makeOpenUIKitNode() -> _OpenViewNode {
        _OpenGraphContext.withStructuralScope(.environmentContent) {
            _OpenGraphContext.withEnvironment(keyPath, value: value) {
                content._makeOpenUIKitNode()
            }
        }
    }
}

/// Type-keyed environment injection used by Observation-backed application
/// services. Nested scopes restore the exact parent object table on exit.
public struct _OpenEnvironmentObjectContent<Content: _OpenView, Object: AnyObject>:
    _OpenView
{
    public typealias Body = Never
    let content: Content
    let object: Object

    public func _makeOpenUIKitNode() -> _OpenViewNode {
        _OpenGraphContext.withStructuralScope(.environmentObjectContent) {
            _OpenGraphContext.withEnvironmentObject(object) {
                content._makeOpenUIKitNode()
            }
        }
    }
}

public struct _OpenDisabledContent<Content: _OpenView>: _OpenView {
    public typealias Body = Never
    let content: Content
    let disabled: Bool

    public func _makeOpenUIKitNode() -> _OpenViewNode {
        _OpenGraphContext.withStructuralScope(.disabledContent) {
            let parentIsEnabled = _OpenGraphContext.environmentValue(\.isEnabled)
            let node = _OpenGraphContext.withEnvironment(
                \EnvironmentValues.isEnabled,
                value: parentIsEnabled && !disabled
            ) {
                content._makeOpenUIKitNode()
            }
            return _OpenViewNode(.modified(node, .disabled(disabled)))
        }
    }
}

public struct _OpenColorSchemeContent<Content: _OpenView>: _OpenView {
    public typealias Body = Never
    let content: Content
    let colorScheme: ColorScheme

    public func _makeOpenUIKitNode() -> _OpenViewNode {
        _OpenGraphContext.withStructuralScope(.colorSchemeContent) {
            let node = _OpenGraphContext.withEnvironment(
                \EnvironmentValues.colorScheme,
                value: colorScheme
            ) {
                content._makeOpenUIKitNode()
            }
            return _OpenViewNode(.modified(node, .colorScheme(colorScheme)))
        }
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
    private var usesMonospacedDigits = false

    nonisolated public init(_ content: String) {
        self.content = content
    }

    @_disfavoredOverload
    nonisolated public init<S: StringProtocol>(_ content: S) {
        self.content = String(content)
    }

    nonisolated public init(verbatim content: String) {
        self.content = content
    }

    @available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
    nonisolated public init(_ content: AttributedString) {
        self.content = String(content.characters)
    }

    #if canImport(Foundation) || canImport(FoundationEssentials)
    @available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
    nonisolated public init<F>(_ input: F.FormatInput, format: F)
    where F: FormatStyle, F.FormatInput: Equatable, F.FormatOutput == String {
        content = format.format(input)
    }
    #endif

    /// Uses a fixed-width numeral design while leaving punctuation and other
    /// glyphs in the surrounding text style. OpenUIKit's portable font cut
    /// currently represents that OpenType feature with its monospaced face,
    /// preserving stable counter widths across value changes.
    nonisolated public func monospacedDigit() -> _OpenText {
        var result = self
        result.usesMonospacedDigits = true
        return result
    }

    public func _makeOpenUIKitNode() -> _OpenViewNode {
        let text = _OpenViewNode(.text(content))
        guard usesMonospacedDigits else { return text }
        return _OpenViewNode(.modified(text, .monospacedDigits))
    }
}

public struct _OpenImage: _OpenView {
    public typealias Body = Never
    let source: _OpenImageSource

    public enum Orientation: UInt8, Sendable {
        case up
        case upMirrored
        case down
        case downMirrored
        case leftMirrored
        case right
        case rightMirrored
        case left
    }

    nonisolated public init(systemName: String) {
        source = .system(name: systemName)
    }

    nonisolated public init(_ name: String, bundle: Bundle? = nil) {
        source = .named(name: name, bundle: bundle)
    }

    public init(uiImage: UIImage) {
        source = .uiImage(uiImage)
    }

    public init(
        decorative image: Bitmap,
        scale: CGFloat,
        orientation: Orientation
    ) {
        source = .uiImage(
            UIImage(
                bitmap: _openOrientedBitmap(image, orientation: orientation),
                scale: scale
            )
        )
    }

    public func _makeOpenUIKitNode() -> _OpenViewNode {
        _OpenViewNode(.image(source))
    }

    public func resizable() -> some _OpenView {
        _OpenModifiedContent(content: self, modification: .resizable)
    }
}

private func _openOrientedBitmap(
    _ source: Bitmap,
    orientation: _OpenImage.Orientation
) -> Bitmap {
    guard orientation != .up, source.width > 0, source.height > 0 else {
        return source
    }
    let swapsAxes: Bool
    switch orientation {
    case .leftMirrored, .right, .rightMirrored, .left: swapsAxes = true
    case .up, .upMirrored, .down, .downMirrored: swapsAxes = false
    }
    let output = Bitmap(
        width: swapsAxes ? source.height : source.width,
        height: swapsAxes ? source.width : source.height
    )
    for y in 0..<output.height {
        for x in 0..<output.width {
            let sourceX: Int
            let sourceY: Int
            switch orientation {
            case .up:
                sourceX = x
                sourceY = y
            case .upMirrored:
                sourceX = source.width - 1 - x
                sourceY = y
            case .down:
                sourceX = source.width - 1 - x
                sourceY = source.height - 1 - y
            case .downMirrored:
                sourceX = x
                sourceY = source.height - 1 - y
            case .leftMirrored:
                sourceX = y
                sourceY = x
            case .right:
                sourceX = y
                sourceY = source.height - 1 - x
            case .rightMirrored:
                sourceX = source.width - 1 - y
                sourceY = source.height - 1 - x
            case .left:
                sourceX = source.width - 1 - y
                sourceY = x
            }
            let sourceIndex = (sourceY * source.width + sourceX) * 4
            let outputIndex = (y * output.width + x) * 4
            output.pixels[outputIndex] = source.pixels[sourceIndex]
            output.pixels[outputIndex + 1] = source.pixels[sourceIndex + 1]
            output.pixels[outputIndex + 2] = source.pixels[sourceIndex + 2]
            output.pixels[outputIndex + 3] = source.pixels[sourceIndex + 3]
        }
    }
    return output
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

    public func strokeBorder(_ color: Color, lineWidth: CGFloat = 1) -> some _OpenView {
        _OpenRoundedRectangleStroke(
            cornerRadius: cornerRadius,
            color: color,
            lineWidth: lineWidth
        )
    }

    public func fill(_ color: Color) -> some _OpenView {
        _OpenFilledRoundedRectangle(cornerRadius: cornerRadius, color: color)
    }
}

@MainActor
private final class _SwiftUIUnevenRoundedRectangleView: UIView {
    let radii: (topLeading: CGFloat, bottomLeading: CGFloat,
        bottomTrailing: CGFloat, topTrailing: CGFloat)
    let fillColor: Color

    init(shape: UnevenRoundedRectangle, color: Color) {
        radii = (
            shape.topLeadingRadius,
            shape.bottomLeadingRadius,
            shape.bottomTrailingRadius,
            shape.topTrailingRadius
        )
        fillColor = color
        super.init(frame: .zero)
        isOpaque = false
        backgroundColor = .clear
        accessibilityIdentifier = "SwiftUI.UnevenRoundedRectangle"
    }

    required init?(coder: NSCoder) { nil }

    override func drawContent(in canvas: Canvas, bounds: CGRect) {
        let limit = max(0, min(bounds.width, bounds.height) / 2)
        let tl = min(radii.topLeading, limit)
        let bl = min(radii.bottomLeading, limit)
        let br = min(radii.bottomTrailing, limit)
        let tr = min(radii.topTrailing, limit)
        var path = Path()
        path.move(to: CGPoint(x: bounds.minX + tl, y: bounds.minY))
        path.addLine(to: CGPoint(x: bounds.maxX - tr, y: bounds.minY))
        if tr > 0 {
            path.addQuad(
                to: CGPoint(x: bounds.maxX, y: bounds.minY + tr),
                control: CGPoint(x: bounds.maxX, y: bounds.minY)
            )
        }
        path.addLine(to: CGPoint(x: bounds.maxX, y: bounds.maxY - br))
        if br > 0 {
            path.addQuad(
                to: CGPoint(x: bounds.maxX - br, y: bounds.maxY),
                control: CGPoint(x: bounds.maxX, y: bounds.maxY)
            )
        }
        path.addLine(to: CGPoint(x: bounds.minX + bl, y: bounds.maxY))
        if bl > 0 {
            path.addQuad(
                to: CGPoint(x: bounds.minX, y: bounds.maxY - bl),
                control: CGPoint(x: bounds.minX, y: bounds.maxY)
            )
        }
        path.addLine(to: CGPoint(x: bounds.minX, y: bounds.minY + tl))
        if tl > 0 {
            path.addQuad(
                to: CGPoint(x: bounds.minX + tl, y: bounds.minY),
                control: CGPoint(x: bounds.minX, y: bounds.minY)
            )
        }
        path.close()
        canvas.fill(
            path,
            color: fillColor.resolve().resolvedCGColor(with: traitCollection)
        )
    }
}

extension _OpenUnevenRoundedRectangle: _OpenView {
    public typealias Body = Never

    public func _makeOpenUIKitNode() -> _OpenViewNode {
        _OpenViewNode(
            .view(_SwiftUIUnevenRoundedRectangleView(shape: self, color: .primary))
        )
    }

    public func fill(_ color: Color) -> some _OpenView {
        _OpenUnevenRoundedRectangleFill(shape: self, color: color)
    }
}

public struct _OpenUnevenRoundedRectangleFill: _OpenView {
    public typealias Body = Never
    public let shape: UnevenRoundedRectangle
    public let color: Color

    public func _makeOpenUIKitNode() -> _OpenViewNode {
        _OpenViewNode(
            .view(_SwiftUIUnevenRoundedRectangleView(shape: shape, color: color))
        )
    }
}

public struct _OpenFilledRoundedRectangle: _OpenView {
    public typealias Body = Never
    public let cornerRadius: CGFloat
    public let color: Color

    public func _makeOpenUIKitNode() -> _OpenViewNode {
        _OpenViewNode(.roundedRectangle(cornerRadius: cornerRadius, style: .fill(color)))
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

extension _OpenRectangle: _OpenView {
    public typealias Body = Never

    public func _makeOpenUIKitNode() -> _OpenViewNode {
        _OpenViewNode(.roundedRectangle(cornerRadius: 0, style: .fill(nil)))
    }

    public func fill(_ color: Color) -> some _OpenView {
        _OpenFilledRoundedRectangle(cornerRadius: 0, color: color)
    }
}

extension _OpenCapsule: _OpenView {
    public typealias Body = Never

    public func _makeOpenUIKitNode() -> _OpenViewNode {
        _OpenViewNode(.capsule(.fill(nil)))
    }

    public func fill(_ color: Color) -> some _OpenView {
        _OpenFilledCapsule(color: color)
    }

    public func stroke(_ color: Color, lineWidth: CGFloat = 1) -> some _OpenView {
        _OpenStrokedCapsule(color: color, lineWidth: lineWidth)
    }
}

extension _OpenCircle: _OpenView {
    public typealias Body = Never

    public func _makeOpenUIKitNode() -> _OpenViewNode {
        _OpenViewNode(.capsule(.fill(nil)))
    }

    public func fill(_ color: Color) -> some _OpenView {
        _OpenFilledCapsule(color: color)
    }

    public func stroke(_ color: Color, lineWidth: CGFloat = 1) -> some _OpenView {
        _OpenStrokedCapsule(color: color, lineWidth: lineWidth)
    }
}

/// Shape value returned by `trim(from:to:)`.  Keeping the authored fractions
/// in the value (instead of clipping a pre-rendered bitmap) lets animation
/// updates rebuild the exact arc and keeps stroke caps on the true endpoints.
@frozen
public struct _OpenTrimmedShape<Base: _OpenShape>: _OpenShape {
    public var shape: Base
    public var startFraction: CGFloat
    public var endFraction: CGFloat

    public init(
        shape: Base,
        startFraction: CGFloat = 0,
        endFraction: CGFloat = 1
    ) {
        self.shape = shape
        self.startFraction = startFraction
        self.endFraction = endFraction
    }
}

extension _OpenTrimmedShape: Sendable where Base: Sendable {}

public extension _OpenShape {
    nonisolated func trim(
        from startFraction: CGFloat = 0,
        to endFraction: CGFloat = 1
    ) -> _OpenTrimmedShape<Self> {
        _OpenTrimmedShape(
            shape: self,
            startFraction: startFraction,
            endFraction: endFraction
        )
    }

    /// Portable CGFloat is intentionally a distinct value type in the guest
    /// SDK. Apple source commonly passes progress ratios stored as Double;
    /// CoreGraphics bridges that conversion at this generic Shape boundary.
    @_disfavoredOverload
    nonisolated func trim(
        from startFraction: Double,
        to endFraction: Double
    ) -> _OpenTrimmedShape<Self> {
        trim(from: CGFloat(startFraction), to: CGFloat(endFraction))
    }
}

public struct _OpenTrimmedCircleStroke<Style: ShapeStyle>: _OpenView {
    public typealias Body = Never
    let shape: _OpenTrimmedShape<_OpenCircle>
    let style: Style
    let strokeStyle: StrokeStyle

    public func _makeOpenUIKitNode() -> _OpenViewNode {
        let view = _SwiftUITrimmedCircleStrokeView(
            startFraction: shape.startFraction,
            endFraction: shape.endFraction,
            color: style._openResolvedForegroundColor(),
            strokeStyle: strokeStyle
        )
        return _OpenViewNode(.view(view))
    }
}

extension _OpenTrimmedShape: _OpenView where Base == _OpenCircle {
    public typealias Body = Never

    public func _makeOpenUIKitNode() -> _OpenViewNode {
        _OpenTrimmedCircleStroke(
            shape: self,
            style: _OpenColor.black,
            strokeStyle: StrokeStyle()
        )._makeOpenUIKitNode()
    }

    public func stroke<Style: ShapeStyle>(
        _ content: Style,
        style: StrokeStyle
    ) -> some _OpenView {
        _OpenTrimmedCircleStroke(
            shape: self,
            style: content,
            strokeStyle: style
        )
    }

    public func stroke<Style: ShapeStyle>(
        _ content: Style,
        lineWidth: CGFloat = 1
    ) -> some _OpenView {
        stroke(content, style: StrokeStyle(lineWidth: lineWidth))
    }
}

@MainActor
private final class _SwiftUITrimmedCircleStrokeView: UIView {
    let startFraction: CGFloat
    let endFraction: CGFloat
    let strokeColor: Color
    let strokeStyle: StrokeStyle

    init(
        startFraction: CGFloat,
        endFraction: CGFloat,
        color: Color,
        strokeStyle: StrokeStyle
    ) {
        self.startFraction = startFraction
        self.endFraction = endFraction
        strokeColor = color
        self.strokeStyle = strokeStyle
        super.init(frame: .zero)
        backgroundColor = .clear
        isOpaque = false
        isUserInteractionEnabled = false
        accessibilityIdentifier = "SwiftUI.Circle.trim.stroke"
    }

    required init?(coder: NSCoder) { nil }

    override func drawContent(in canvas: Canvas, bounds: CGRect) {
        let width = strokeStyle.lineWidth.isFinite
            ? max(0, strokeStyle.lineWidth) : 0
        guard width > 0,
              startFraction.isFinite,
              endFraction.isFinite else { return }
        let start = min(max(startFraction, 0), 1)
        let end = min(max(endFraction, 0), 1)
        guard end > start else { return }

        let radius = max(0, min(bounds.width, bounds.height) / 2 - width / 2)
        guard radius > 0 else { return }
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let circumference = 2 * CGFloat.pi * radius
        guard circumference.isFinite, circumference > 0 else { return }
        let pathLength = (end - start) * circumference
        let color = strokeColor.resolve().resolvedCGColor(with: traitCollection)
        let cap: CanvasLineCap
        switch strokeStyle.lineCap {
        case .butt: cap = .butt
        case .round: cap = .round
        case .square: cap = .square
        }
        let join: CanvasLineJoin
        switch strokeStyle.lineJoin {
        case .miter: join = .miter
        case .round: join = .round
        case .bevel: join = .bevel
        }

        func drawArc(from lower: CGFloat, to upper: CGFloat) {
            guard upper > lower else { return }
            let path = UIBezierPath(
                arcCenter: center,
                radius: radius,
                startAngle: lower * 2 * .pi,
                endAngle: upper * 2 * .pi,
                clockwise: true
            ).cgPath
            canvas.stroke(
                path,
                color: color,
                lineWidth: width,
                cap: cap,
                join: join,
                miterLimit: strokeStyle.miterLimit.isFinite
                    ? max(0, strokeStyle.miterLimit) : 10
            )
        }

        var pattern = strokeStyle.dash.filter { $0.isFinite && $0 > 0 }
        guard !pattern.isEmpty else {
            drawArc(from: start, to: end)
            return
        }
        if pattern.count % 2 != 0 { pattern.append(contentsOf: pattern) }
        let cycle = pattern.reduce(0, +)
        guard cycle.isFinite, cycle > 0,
              pathLength.isFinite, pathLength > 0 else { return }

        var phase = strokeStyle.dashPhase.isFinite ? strokeStyle.dashPhase : 0
        phase.formTruncatingRemainder(dividingBy: cycle)
        if phase < 0 { phase += cycle }
        var patternIndex = 0
        while phase >= pattern[patternIndex] {
            phase -= pattern[patternIndex]
            patternIndex = (patternIndex + 1) % pattern.count
        }
        var remaining = pattern[patternIndex] - phase
        var cursor: CGFloat = 0
        while cursor < pathLength {
            let next = min(pathLength, cursor + remaining)
            // Extremely small finite dash entries can round away when added
            // to a much larger path position. Fail closed instead of spinning
            // forever on an unrepresentable segment boundary.
            guard next > cursor else { return }
            if patternIndex % 2 == 0 {
                drawArc(
                    from: start + cursor / circumference,
                    to: start + next / circumference
                )
            }
            cursor = next
            patternIndex = (patternIndex + 1) % pattern.count
            remaining = pattern[patternIndex]
        }
    }
}

/// System materials are live blur-backed OpenUIKit views. Keeping material as
/// a primitive View lets contextual spellings such as `.background(.bar)`
/// resolve without flattening the effect into an opaque color.
public struct _OpenMaterial: _OpenView, Sendable {
    public typealias Body = Never

    enum Style: Sendable { case bar, regular, thin, thick }
    let style: Style

    public func _makeOpenUIKitNode() -> _OpenViewNode {
        let blurStyle: UIBlurEffect.Style
        switch style {
        case .bar, .regular: blurStyle = .systemMaterial
        case .thin: blurStyle = .systemThinMaterial
        case .thick: blurStyle = .systemThickMaterial
        }
        let view = UIVisualEffectView(effect: UIBlurEffect(style: blurStyle))
        view.accessibilityIdentifier = "SwiftUI.Material.\(style)"
        return _OpenViewNode(.view(view))
    }
}

public extension _OpenView where Self == _OpenMaterial {
    static var bar: _OpenMaterial { _OpenMaterial(style: .bar) }
    static var regularMaterial: _OpenMaterial { _OpenMaterial(style: .regular) }
    static var thinMaterial: _OpenMaterial { _OpenMaterial(style: .thin) }
    static var thickMaterial: _OpenMaterial { _OpenMaterial(style: .thick) }
}

public typealias Material = _OpenMaterial

public struct _OpenFilledCapsule: _OpenView {
    public typealias Body = Never
    public let color: Color

    public func _makeOpenUIKitNode() -> _OpenViewNode {
        _OpenViewNode(.capsule(.fill(color)))
    }
}

public struct _OpenStrokedCapsule: _OpenView {
    public typealias Body = Never
    public let color: Color
    public let lineWidth: CGFloat

    public func _makeOpenUIKitNode() -> _OpenViewNode {
        _OpenViewNode(.capsule(.stroke(color, lineWidth: max(0, lineWidth))))
    }
}

public extension _OpenShape where Self == _OpenRoundedRectangle {
    static func rect(
        cornerRadius: CGFloat,
        style: RoundedCornerStyle = .circular
    ) -> _OpenRoundedRectangle {
        _OpenRoundedRectangle(cornerRadius: cornerRadius, style: style)
    }
}

public struct _OpenDivider: _OpenView {
    public typealias Body = Never
    public init() {}

    public func _makeOpenUIKitNode() -> _OpenViewNode {
        _OpenViewNode(.divider)
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

public extension _OpenForEach where Data.Element: Identifiable, ID == Data.Element.ID {
    init(
        _ data: Data,
        @_OpenViewBuilder content: @escaping @MainActor (Data.Element) -> Content
    ) {
        self.init(data, id: \.id, content: content)
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

/// Heterogeneous, value-semantic navigation state. AnyHashable preserves the
/// exact dynamic type used to select `navigationDestination(for:)`, while the
/// public collection operations match the NavigationPath surface used by
/// state stores and deep-link routers.
public struct _OpenNavigationPath: Equatable, @unchecked Sendable {
    fileprivate var elements: [AnyHashable]

    public init() { elements = [] }

    public init<S>(_ elements: S) where S: Sequence, S.Element: Hashable {
        self.elements = elements.map(AnyHashable.init)
    }

    fileprivate init(erasedElements: [AnyHashable]) {
        elements = erasedElements
    }

    public var count: Int { elements.count }
    public var isEmpty: Bool { elements.isEmpty }

    public mutating func append<Value: Hashable>(_ value: Value) {
        elements.append(AnyHashable(value))
    }

    public mutating func removeLast(_ count: Int = 1) {
        precondition(count >= 0 && count <= elements.count)
        elements.removeLast(count)
    }
}

/// A real retained UIKit navigation stack driven in both directions by its
/// SwiftUI path binding. Destination bodies are evaluated in the parent graph
/// (so State/Environment/Observation identity remains intact), while the
/// controller owns pushes, interactive pops, titles, and toolbar surfaces.
public struct _OpenNavigationStack<Content: _OpenView>: _OpenView {
    public typealias Body = Never
    public let content: Content
    private let pathBinding: _OpenNavigationPathBinding?

    public init(@_OpenViewBuilder root: () -> Content) {
        content = root()
        pathBinding = nil
    }

    public init(
        path: Binding<NavigationPath>,
        @_OpenViewBuilder root: () -> Content
    ) {
        content = root()
        pathBinding = _OpenNavigationPathBinding(
            getElements: { path.wrappedValue.elements },
            setElements: { path.wrappedValue = NavigationPath(erasedElements: $0) }
        )
    }

    public init<Data>(
        path: Binding<Data>,
        @_OpenViewBuilder root: () -> Content
    ) where Data: MutableCollection & RandomAccessCollection & RangeReplaceableCollection,
        Data.Element: Hashable
    {
        content = root()
        pathBinding = _OpenNavigationPathBinding(
            getElements: { path.wrappedValue.map(AnyHashable.init) },
            setElements: { erased in
                let typed = erased.compactMap { $0.base as? Data.Element }
                guard typed.count == erased.count else { return }
                var value = path.wrappedValue
                value.replaceSubrange(value.startIndex..<value.endIndex, with: typed)
                path.wrappedValue = value
            }
        )
    }

    public func _makeOpenUIKitNode() -> _OpenViewNode {
        let contentNode = _OpenGraphContext.withStructuralScope(.navigationContent) {
            content._makeOpenUIKitNode()
        }
        let (rootNode, rootConfiguration) = _openExtractNavigationConfiguration(
            contentNode
        )

        var registrations = rootConfiguration.destinations
        var resolved: [_OpenNavigationResolvedDestination] = []
        if let pathBinding {
            for (index, value) in pathBinding.getElements().enumerated() {
                guard let registration = registrations.last(where: { $0.matches(value) })
                else { break }
                let dismiss = DismissAction {
                    pathBinding.dismissDestination(at: index)
                }
                guard let destinationNode = _OpenGraphContext.withStructuralScope(
                    .navigationPathElement(index: index, value: value),
                    operation: {
                        _OpenGraphContext.withEnvironment(
                            \.dismiss,
                            value: dismiss,
                            operation: { registration.makeNode(value) }
                        )
                    }
                ) else { break }
                let (node, configuration) = _openExtractNavigationConfiguration(
                    destinationNode
                )
                resolved.append(
                    _OpenNavigationResolvedDestination(
                        value: value,
                        node: node,
                        configuration: configuration
                    )
                )
                registrations.append(contentsOf: configuration.destinations)
            }
        }

        let controller = _OpenGraphContext.representedController(
            makeCoordinator: { () },
            make: { _ in _SwiftUINavigationStackController() },
            update: { controller, _ in
                controller.update(
                    rootNode: rootNode,
                    rootConfiguration: rootConfiguration,
                    pathBinding: pathBinding,
                    destinations: resolved
                )
            },
            dismantle: { controller, _ in controller.dismantleStack() }
        )
        return _OpenViewNode(.viewController(controller))
    }
}

public enum _OpenNavigationSplitViewVisibility: Hashable, Sendable {
    case automatic
    case all
    case doubleColumn
    case detailOnly
}

/// Two-column adaptive navigation. Wide automatic/all layouts retain both
/// subtrees side-by-side with deterministic column geometry; compact
/// automatic and explicit detail-only layouts keep only the detail subtree.
public struct _OpenNavigationSplitView<Sidebar: _OpenView, Detail: _OpenView>:
    _OpenView
{
    public typealias Body = Never
    private let columnVisibility: Binding<NavigationSplitViewVisibility>?
    public let sidebar: Sidebar
    public let detail: Detail

    public init(
        columnVisibility: Binding<NavigationSplitViewVisibility>,
        @_OpenViewBuilder sidebar: () -> Sidebar,
        @_OpenViewBuilder detail: () -> Detail
    ) {
        self.columnVisibility = columnVisibility
        self.sidebar = sidebar()
        self.detail = detail()
    }

    public init(
        @_OpenViewBuilder sidebar: () -> Sidebar,
        @_OpenViewBuilder detail: () -> Detail
    ) {
        columnVisibility = nil
        self.sidebar = sidebar()
        self.detail = detail()
    }

    public func _makeOpenUIKitNode() -> _OpenViewNode {
        let sidebarNode = _OpenGraphContext.withStructuralScope(
            .navigationSplitSidebar
        ) { sidebar._makeOpenUIKitNode() }
        let detailNode = _OpenGraphContext.withStructuralScope(
            .navigationSplitDetail
        ) { detail._makeOpenUIKitNode() }
        let visibility = columnVisibility?.wrappedValue ?? .automatic
        return _OpenViewNode(
            .geometry(
                _OpenGeometryNode { size in
                    let showsSidebar: Bool
                    switch visibility {
                    case .detailOnly:
                        showsSidebar = false
                    case .automatic:
                        showsSidebar = size.width >= 600
                    case .all, .doubleColumn:
                        showsSidebar = true
                    }
                    guard showsSidebar else { return detailNode }

                    let dividerWidth: CGFloat = 1
                    let preferred = min(max(size.width * 0.36, 320), 400)
                    let sidebarWidth = min(preferred, max(0, size.width * 0.5))
                    let detailWidth = max(0, size.width - sidebarWidth - dividerWidth)
                    let sidebarColumn = _OpenViewNode(
                        .modified(
                            sidebarNode,
                            .frame(
                                width: sidebarWidth,
                                height: size.height,
                                alignment: .center
                            )
                        )
                    )
                    let detailColumn = _OpenViewNode(
                        .modified(
                            detailNode,
                            .frame(
                                width: detailWidth,
                                height: size.height,
                                alignment: .center
                            )
                        )
                    )
                    return _OpenViewNode(
                        .modified(
                            _OpenViewNode(
                                .hStack(
                                    children: [
                                        sidebarColumn,
                                        _OpenViewNode(.divider),
                                        detailColumn,
                                    ],
                                    alignment: .center,
                                    spacing: 0
                                )
                            ),
                            .accessibilityIdentifier("SwiftUI.NavigationSplitView")
                        )
                    )
                }
            )
        )
    }
}

/// The source-facing ViewModifier protocol evaluates its body against a
/// retained node rather than flattening the modifier at declaration time.
/// That preserves dynamic-property and structural identity across graph
/// reevaluations just like the built-in modifier pipeline.
@preconcurrency @MainActor
public protocol _OpenViewModifierProtocol {
    associatedtype Body: _OpenView
    typealias Content = _OpenViewModifierContent<Self>

    @_OpenViewBuilder func body(content: Content) -> Body
}

public struct _OpenViewModifierContent<Modifier: _OpenViewModifierProtocol>: _OpenView {
    public typealias Body = Never
    private let node: _OpenViewNode

    fileprivate init(node: _OpenViewNode) {
        self.node = node
    }

    public func _makeOpenUIKitNode() -> _OpenViewNode { node }
}

public struct _OpenAppliedViewModifier<Source: _OpenView, Modifier: _OpenViewModifierProtocol>:
    _OpenView
{
    public typealias Body = Never
    let source: Source
    let modifier: Modifier

    public func _makeOpenUIKitNode() -> _OpenViewNode {
        let sourceNode = _OpenGraphContext.withStructuralScope(.modifiedContent) {
            source._makeOpenUIKitNode()
        }
        if let effect = modifier as? any GeometryEffect {
            return _OpenViewNode(
                .modified(
                    sourceNode,
                    .projection { size in effect.effectValue(size: size) }
                )
            )
        }
        return modifier.body(
            content: _OpenViewModifierContent<Modifier>(node: sourceNode)
        )._makeOpenUIKitNode()
    }
}

public typealias ViewModifier = _OpenViewModifierProtocol

/// Type-erased button label supplied to ButtonStyle.Configuration.
public struct _OpenButtonStyleLabel: _OpenView {
    public typealias Body = Never
    private let node: _OpenViewNode

    fileprivate init(node: _OpenViewNode) { self.node = node }
    public func _makeOpenUIKitNode() -> _OpenViewNode { node }
}

public struct _OpenButtonStyleConfiguration {
    public typealias Label = _OpenButtonStyleLabel
    public let label: Label
    public let isPressed: Bool
    public let role: ButtonRole?

    fileprivate init(label: Label, isPressed: Bool, role: ButtonRole?) {
        self.label = label
        self.isPressed = isPressed
        self.role = role
    }
}

@preconcurrency @MainActor
public protocol _OpenButtonStyleProtocol {
    associatedtype Body: _OpenView
    typealias Configuration = _OpenButtonStyleConfiguration

    @_OpenViewBuilder func makeBody(configuration: Configuration) -> Body
}

public struct _OpenPlainButtonStyle: _OpenButtonStyleProtocol, Sendable {
    public init() {}
    public func makeBody(configuration: Configuration) -> some _OpenView {
        configuration.label
    }
}

public extension _OpenButtonStyleProtocol where Self == _OpenPlainButtonStyle {
    static var plain: _OpenPlainButtonStyle { _OpenPlainButtonStyle() }
}

public struct _OpenBorderedButtonStyle: _OpenButtonStyleProtocol, Sendable {
    public init() {}

    public func makeBody(configuration: Configuration) -> some _OpenView {
        configuration.label
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Color(uiColor: configuration.isPressed
                    ? .tertiarySystemFill
                    : .secondarySystemFill)
            )
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .opacity(configuration.isPressed ? 0.78 : 1)
    }
}

public extension _OpenButtonStyleProtocol where Self == _OpenBorderedButtonStyle {
    static var bordered: _OpenBorderedButtonStyle { _OpenBorderedButtonStyle() }
}

/// The filled system button style used for primary actions. The normal and
/// highlighted graphs are retained separately by `_OpenButtonStyleContent`,
/// so press feedback changes the concrete fill while preserving the button's
/// action, role and accessibility identity.
public struct _OpenBorderedProminentButtonStyle: _OpenButtonStyleProtocol, Sendable {
    public init() {}

    public func makeBody(configuration: Configuration) -> some _OpenView {
        let fill: UIColor
        switch configuration.role {
        case .some(.destructive):
            fill = .systemRed
        default:
            fill = .systemBlue
        }
        return configuration.label
            .foregroundStyle(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Color(uiColor: fill))
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .opacity(configuration.isPressed ? 0.72 : 1)
    }
}

public extension _OpenButtonStyleProtocol
where Self == _OpenBorderedProminentButtonStyle {
    static var borderedProminent: _OpenBorderedProminentButtonStyle {
        _OpenBorderedProminentButtonStyle()
    }
}

/// Portable rendering for the system glass button styles introduced by the
/// newest SDK.  The normal and pressed configurations remain distinct nodes,
/// so OpenUIKit's button control switches the real blur-backed surface while
/// tracking highlight state rather than merely accepting the source syntax.
public struct _OpenGlassButtonStyle: _OpenButtonStyleProtocol, Sendable {
    let isProminent: Bool

    public init(isProminent: Bool = false) { self.isProminent = isProminent }

    public func makeBody(configuration: Configuration) -> some _OpenView {
        configuration.label
            .padding(8)
            .background(isProminent ? Color(uiColor: .systemBlue).opacity(0.72) : Color.clear)
            .glassEffect()
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
    }
}

public extension _OpenButtonStyleProtocol where Self == _OpenGlassButtonStyle {
    static var glass: _OpenGlassButtonStyle { _OpenGlassButtonStyle() }
    static var glassProminent: _OpenGlassButtonStyle {
        _OpenGlassButtonStyle(isProminent: true)
    }
}

public struct _OpenButtonStyleContent<Source: _OpenView, Style: _OpenButtonStyleProtocol>:
    _OpenView
{
    public typealias Body = Never
    let source: Source
    let style: Style

    public func _makeOpenUIKitNode() -> _OpenViewNode {
        let node = _OpenGraphContext.withStructuralScope(.modifiedContent) {
            source._makeOpenUIKitNode()
        }
        return _openApplyingButtonStyle(node, style: style)
    }
}

@MainActor
private func _openApplyingButtonStyle<Style: _OpenButtonStyleProtocol>(
    _ node: _OpenViewNode,
    style: Style
) -> _OpenViewNode {
    switch node.kind {
    case .button(let label, _, let role, let action):
        let normal = style.makeBody(
            configuration: .init(
                label: _OpenButtonStyleLabel(node: label),
                isPressed: false,
                role: role
            )
        )._makeOpenUIKitNode()
        let pressed = style.makeBody(
            configuration: .init(
                label: _OpenButtonStyleLabel(node: label),
                isPressed: true,
                role: role
            )
        )._makeOpenUIKitNode()
        return _OpenViewNode(
            .button(label: normal, pressedLabel: pressed, role: role, action: action)
        )
    case .menu(let label, _, let content):
        let normal = style.makeBody(
            configuration: .init(
                label: _OpenButtonStyleLabel(node: label),
                isPressed: false,
                role: nil
            )
        )._makeOpenUIKitNode()
        let pressed = style.makeBody(
            configuration: .init(
                label: _OpenButtonStyleLabel(node: label),
                isPressed: true,
                role: nil
            )
        )._makeOpenUIKitNode()
        return _OpenViewNode(
            .menu(label: normal, pressedLabel: pressed, content: content)
        )
    case .group(let children):
        return _OpenViewNode(.group(children.map { _openApplyingButtonStyle($0, style: style) }))
    case .hStack(let children, let alignment, let spacing):
        return _OpenViewNode(
            .hStack(
                children: children.map { _openApplyingButtonStyle($0, style: style) },
                alignment: alignment,
                spacing: spacing
            )
        )
    case .vStack(let children, let alignment, let spacing):
        return _OpenViewNode(
            .vStack(
                children: children.map { _openApplyingButtonStyle($0, style: style) },
                alignment: alignment,
                spacing: spacing
            )
        )
    case .zStack(let children, let alignment):
        return _OpenViewNode(
            .zStack(
                children: children.map { _openApplyingButtonStyle($0, style: style) },
                alignment: alignment
            )
        )
    case .grid(let rows, let horizontalSpacing, let verticalSpacing):
        return _OpenViewNode(
            .grid(
                rows: rows.map { _openApplyingButtonStyle($0, style: style) },
                horizontalSpacing: horizontalSpacing,
                verticalSpacing: verticalSpacing
            )
        )
    case .gridRow(let cells):
        return _OpenViewNode(
            .gridRow(cells.map { _openApplyingButtonStyle($0, style: style) })
        )
    case .modified(let content, let modification):
        return _OpenViewNode(
            .modified(_openApplyingButtonStyle(content, style: style), modification)
        )
    default:
        return node
    }
}

public typealias ButtonStyle = _OpenButtonStyleProtocol
public typealias PlainButtonStyle = _OpenPlainButtonStyle
public typealias BorderedButtonStyle = _OpenBorderedButtonStyle
public typealias BorderedProminentButtonStyle = _OpenBorderedProminentButtonStyle
public typealias GlassButtonStyle = _OpenGlassButtonStyle

public struct _OpenLabel<Title: _OpenView, Icon: _OpenView>: _OpenView {
    public typealias Body = Never
    public let title: Title
    public let icon: Icon

    public init(
        @_OpenViewBuilder title: () -> Title,
        @_OpenViewBuilder icon: () -> Icon
    ) {
        self.title = title()
        self.icon = icon()
    }

    nonisolated public init(_ title: String, systemImage: String)
        where Title == _OpenText, Icon == _OpenImage
    {
        self.title = _OpenText(title)
        icon = _OpenImage(systemName: systemImage)
    }

    public func _makeOpenUIKitNode() -> _OpenViewNode {
        _OpenViewNode(
            .hStack(
                children: [
                    _OpenGraphContext.withStructuralScope(.tupleElement(0)) {
                        icon._makeOpenUIKitNode()
                    },
                    _OpenGraphContext.withStructuralScope(.tupleElement(1)) {
                        title._makeOpenUIKitNode()
                    },
                ],
                alignment: .center,
                spacing: 6
            )
        )
    }
}

public struct _OpenIconOnlyLabelStyle: Sendable {
    public init() {}
    public static let iconOnly = _OpenIconOnlyLabelStyle()
}

public struct _OpenIconOnlyLabelStyleContent<Source: _OpenView>: _OpenView {
    public typealias Body = Never
    let source: Source

    public func _makeOpenUIKitNode() -> _OpenViewNode {
        _openApplyingIconOnlyLabelStyle(source._makeOpenUIKitNode())
    }
}

@MainActor
private func _openApplyingIconOnlyLabelStyle(_ node: _OpenViewNode) -> _OpenViewNode {
    switch node.kind {
    case .hStack(let children, _, let spacing) where children.count == 2 && spacing == 6:
        // _OpenLabel's structural spelling is exactly icon + title with a
        // six-point gap.  Keep the actual icon node (including its modifiers)
        // so tint, symbol mode and accessibility still reach the host.
        return children[0]
    case .modified(let content, let modification):
        return _OpenViewNode(
            .modified(_openApplyingIconOnlyLabelStyle(content), modification)
        )
    default:
        return node
    }
}

public struct _OpenLinearGradient: _OpenView {
    public typealias Body = Never
    public let gradient: Gradient
    public let startPoint: UnitPoint
    public let endPoint: UnitPoint

    nonisolated public init(gradient: Gradient, startPoint: UnitPoint, endPoint: UnitPoint) {
        self.gradient = gradient
        self.startPoint = startPoint
        self.endPoint = endPoint
    }

    nonisolated public init(
        colors: [Color],
        startPoint: UnitPoint,
        endPoint: UnitPoint
    ) {
        gradient = Gradient(colors: colors)
        self.startPoint = startPoint
        self.endPoint = endPoint
    }

    nonisolated public init(
        stops: [Gradient.Stop],
        startPoint: UnitPoint,
        endPoint: UnitPoint
    ) {
        gradient = Gradient(stops: stops)
        self.startPoint = startPoint
        self.endPoint = endPoint
    }

    public func _makeOpenUIKitNode() -> _OpenViewNode {
        _OpenViewNode(.gradient(gradient, startPoint, endPoint))
    }
}

extension _OpenLinearGradient: _OpenShapeStyle {
    public func _openResolvedForegroundColor() -> _OpenColor {
        gradient.colors.first ?? .clear
    }
}

/// Contextual ShapeStyle constructors used by spellings such as
/// `.foregroundStyle(.linearGradient(colors:startPoint:endPoint:))`. They
/// build the same concrete gradient value as `LinearGradient(...)`,
/// preserving all stop locations and the renderer's unit-coordinate
/// direction.
public extension _OpenShapeStyle where Self == _OpenLinearGradient {
    nonisolated static func linearGradient(
        _ gradient: Gradient,
        startPoint: UnitPoint,
        endPoint: UnitPoint
    ) -> _OpenLinearGradient {
        _OpenLinearGradient(
            gradient: gradient,
            startPoint: startPoint,
            endPoint: endPoint
        )
    }

    nonisolated static func linearGradient(
        colors: [Color],
        startPoint: UnitPoint,
        endPoint: UnitPoint
    ) -> _OpenLinearGradient {
        _OpenLinearGradient(
            colors: colors,
            startPoint: startPoint,
            endPoint: endPoint
        )
    }

    nonisolated static func linearGradient(
        stops: [Gradient.Stop],
        startPoint: UnitPoint,
        endPoint: UnitPoint
    ) -> _OpenLinearGradient {
        _OpenLinearGradient(
            stops: stops,
            startPoint: startPoint,
            endPoint: endPoint
        )
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

/// A type-bounded modifier carrier for effect chains.
///
/// Effect modifiers do not participate in layout's generic structure: their
/// work is installed while the retained graph node is materialized. Keeping
/// that carrier non-generic prevents long `.onChange`/`.animation` chains
/// from growing a recursive constraint type, while the nested node closures
/// still retain every effect and structural scope in source order.
public struct _OpenEffectContent: _OpenView {
    public typealias Body = Never
    private let contentBuilder: @MainActor () -> _OpenViewNode
    private let modifier: _OpenViewModifier

    fileprivate init<Content: _OpenView>(
        content: Content,
        modification: _OpenViewModifier
    ) {
        contentBuilder = { content._makeOpenUIKitNode() }
        modifier = modification
    }

    public func _makeOpenUIKitNode() -> _OpenViewNode {
        let contentNode = _OpenGraphContext.withStructuralScope(.modifiedContent) {
            contentBuilder()
        }
        return _OpenViewNode(.modified(contentNode, modifier.resolve()))
    }
}

public extension _OpenView {
    func environment<Value>(
        _ keyPath: WritableKeyPath<EnvironmentValues, Value>,
        _ value: Value
    ) -> some _OpenView {
        _OpenEnvironmentValueContent(
            content: self,
            keyPath: keyPath,
            value: value
        )
    }

    func environment<Object: AnyObject>(_ object: Object) -> some _OpenView {
        _OpenEnvironmentObjectContent(content: self, object: object)
    }

    func font(_ font: Font?) -> some _OpenView {
        _OpenModifiedContent(content: self, modification: .font(font))
    }

    func fontWeight(_ weight: Font.Weight?) -> some _OpenView {
        _OpenModifiedContent(content: self, modification: .fontWeight(weight))
    }

    func monospacedDigit() -> some _OpenView {
        _OpenModifiedContent(content: self, modification: .monospacedDigits)
    }

    func minimumScaleFactor(_ factor: CGFloat) -> some _OpenView {
        _OpenModifiedContent(content: self, modification: .minimumScaleFactor(factor))
    }

    func allowsTightening(_ flag: Bool) -> some _OpenView {
        _OpenModifiedContent(content: self, modification: .allowsTightening(flag))
    }

    func foregroundColor(_ color: Color?) -> some _OpenView {
        _OpenModifiedContent(content: self, modification: .foregroundColor(color))
    }

    func tint(_ color: Color?) -> some _OpenView {
        _OpenModifiedContent(content: self, modification: .tint(color))
    }

    func accentColor(_ accentColor: Color?) -> some _OpenView {
        _OpenModifiedContent(content: self, modification: .tint(accentColor))
    }

    func opacity(_ opacity: Double) -> some _OpenView {
        _OpenModifiedContent(
            content: self,
            modification: .opacity(CGFloat(min(max(opacity, 0), 1)))
        )
    }

    @_disfavoredOverload
    func opacity(_ opacity: CGFloat) -> some _OpenView {
        _OpenModifiedContent(
            content: self,
            modification: .opacity(min(max(opacity, 0), 1))
        )
    }

    /// Adds an sRGB brightness offset to the completed view subtree.
    func brightness(_ amount: Double) -> some _OpenView {
        _OpenModifiedContent(content: self, modification: .brightness(amount))
    }

    /// Scales colorfulness around luminance while preserving subtree alpha.
    func saturation(_ amount: Double) -> some _OpenView {
        _OpenModifiedContent(content: self, modification: .saturation(amount))
    }

    func scaleEffect(_ scale: CGFloat) -> some _OpenView {
        _OpenModifiedContent(content: self, modification: .scaleEffect(scale))
    }

    func scaleEffect(_ scale: CGFloat, anchor: UnitPoint) -> some _OpenView {
        _OpenModifiedContent(
            content: self,
            modification: .anchoredScaleEffect(scale, anchor)
        )
    }

    func rotationEffect(
        _ angle: Angle,
        anchor: UnitPoint = .center
    ) -> some _OpenView {
        _OpenModifiedContent(
            content: self,
            modification: .rotationEffect(angle, anchor)
        )
    }

    func offset(_ offset: CGSize) -> some _OpenView {
        _OpenModifiedContent(content: self, modification: .offset(offset))
    }

    func offset(x: CGFloat = 0, y: CGFloat = 0) -> some _OpenView {
        offset(CGSize(width: x, height: y))
    }

    /// EquatableView only changes invalidation cost. Structural graph keys
    /// already preserve this view's state, so rendering remains transparent.
    func equatable() -> some _OpenView where Self: Equatable {
        _OpenModifiedContent(content: self, modification: .effect)
    }

    func lineLimit(_ number: Int?) -> some _OpenView {
        _OpenModifiedContent(content: self, modification: .lineLimit(number))
    }

    func lineLimit(_ range: ClosedRange<Int>) -> some _OpenView {
        _OpenModifiedContent(content: self, modification: .lineLimitRange(range))
    }

    func truncationMode(_ mode: TextTruncationMode) -> some _OpenView {
        _OpenModifiedContent(content: self, modification: .truncationMode(mode))
    }

    func layoutPriority(_ value: Double) -> some _OpenView {
        _OpenModifiedContent(content: self, modification: .layoutPriority(value))
    }

    /// Requests the child's ideal extent on the selected axes while retaining
    /// the parent's concrete proposal on the others. This is the important
    /// behavior behind vertically fixed multiline labels: width still wraps,
    /// but a short row proposal no longer truncates their intrinsic height.
    func fixedSize(
        horizontal: Bool = true,
        vertical: Bool = true
    ) -> some _OpenView {
        _OpenModifiedContent(
            content: self,
            modification: .fixedSize(horizontal: horizontal, vertical: vertical)
        )
    }

    func foregroundStyle<Style: ShapeStyle>(_ style: Style) -> some _OpenView {
        foregroundColor(style._openResolvedForegroundColor())
    }

    func foregroundStyle<Primary: ShapeStyle, Secondary: ShapeStyle>(
        _ primary: Primary,
        _ secondary: Secondary
    ) -> some _OpenView {
        _ = secondary
        return foregroundColor(primary._openResolvedForegroundColor())
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
        minWidth: CGFloat? = nil,
        idealWidth: CGFloat? = nil,
        maxWidth: CGFloat? = nil,
        minHeight: CGFloat? = nil,
        idealHeight: CGFloat? = nil,
        maxHeight: CGFloat? = nil,
        alignment: Alignment = .center
    ) -> some _OpenView {
        _ = idealWidth
        _ = idealHeight
        return _OpenModifiedContent(
            content: self,
            modification: .flexibleFrame(
                minWidth: minWidth,
                maxWidth: maxWidth,
                minHeight: minHeight,
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

    func background<Style: ShapeStyle, S: Shape>(
        _ style: Style,
        in shape: S
    ) -> some _OpenView {
        let color = style._openResolvedForegroundColor()
        let backgroundNode: _OpenViewNode
        if let rounded = shape as? RoundedRectangle {
            backgroundNode = _OpenViewNode(
                .roundedRectangle(
                    cornerRadius: max(0, rounded.cornerRadius),
                    style: .fill(color)
                )
            )
        } else if shape is Capsule || shape is Circle {
            backgroundNode = _OpenViewNode(.capsule(.fill(color)))
        } else {
            backgroundNode = _OpenViewNode(
                .roundedRectangle(cornerRadius: 0, style: .fill(color))
            )
        }
        return _OpenModifiedContent(
            content: self,
            modification: .background({ backgroundNode }, alignment: .center)
        )
    }

    func background<Background: _OpenView>(
        alignment: Alignment = .center,
        @_OpenViewBuilder content: () -> Background
    ) -> some _OpenView {
        let background = content()
        return _OpenModifiedContent(
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

    func mask<Mask: _OpenView>(
        alignment: Alignment = .center,
        @_OpenViewBuilder _ mask: () -> Mask
    ) -> some _OpenView {
        let maskContent = mask()
        return _OpenModifiedContent(
            content: self,
            modification: .mask(
                { maskContent._makeOpenUIKitNode() },
                alignment: alignment
            )
        )
    }

    func overlay<Overlay: _OpenView>(
        alignment: Alignment = .center,
        @_OpenViewBuilder content: () -> Overlay
    ) -> some _OpenView {
        let overlay = content()
        return _OpenModifiedContent(
            content: self,
            modification: .overlay(
                { overlay._makeOpenUIKitNode() },
                alignment: alignment
            )
        )
    }

    func aspectRatio(contentMode: ContentMode) -> some _OpenView {
        _OpenModifiedContent(content: self, modification: .aspectRatio(nil, contentMode))
    }

    func aspectRatio(
        _ aspectRatio: CGFloat?,
        contentMode: ContentMode
    ) -> some _OpenView {
        let ratio = aspectRatio.flatMap { value in
            value.isFinite && value > 0 ? value : nil
        }
        return _OpenModifiedContent(
            content: self,
            modification: .aspectRatio(ratio, contentMode)
        )
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
            modification: .clipRoundedRectangle(max(0, radius), ._allKnown)
        )
    }

    func shadow(radius: CGFloat) -> some _OpenView {
        shadow(color: .black.opacity(0.33), radius: radius)
    }

    func shadow(
        color: Color = .black.opacity(0.33),
        radius: CGFloat,
        x: CGFloat = 0,
        y: CGFloat = 0
    ) -> some _OpenView {
        _OpenModifiedContent(
            content: self,
            modification: .shadow(
                color: color,
                radius: max(0, radius),
                x: x.isFinite ? x : 0,
                y: y.isFinite ? y : 0
            )
        )
    }

    func colorScheme(_ colorScheme: ColorScheme) -> some _OpenView {
        _OpenColorSchemeContent(content: self, colorScheme: colorScheme)
    }

    func ignoresSafeArea(
        _ regions: SafeAreaRegions = .all,
        edges: Edge.Set = .all
    ) -> some _OpenView {
        _ = regions
        return _OpenModifiedContent(content: self, modification: .safeAreaIgnored(edges))
    }

    func edgesIgnoringSafeArea(_ edges: Edge.Set) -> some _OpenView {
        _OpenModifiedContent(content: self, modification: .safeAreaIgnored(edges))
    }

    func onAppear(perform action: @escaping @MainActor () -> Void) -> some _OpenView {
        _OpenModifiedContent(content: self, modification: .onAppear(action))
    }

    func onDisappear(
        perform action: (@MainActor () -> Void)? = nil
    ) -> some _OpenView {
        _OpenModifiedContent(content: self, modification: .onDisappear(action ?? {}))
    }

    func onOpenURL(perform action: @escaping @MainActor (URL) -> Void) -> some _OpenView {
        _OpenModifiedContent(content: self, modification: .openURL(action))
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

    func simultaneousGesture<G: Gesture>(_ gesture: G) -> some _OpenView {
        guard let provider = gesture as? any _OpenGestureNodeProviding else {
            return _OpenModifiedContent(content: self, modification: .effect)
        }
        return _OpenModifiedContent(
            content: self,
            modification: .gesture(provider._openGestureNode)
        )
    }

    func gesture<G: Gesture>(_ gesture: G) -> some _OpenView {
        simultaneousGesture(gesture)
    }

    func highPriorityGesture<G: Gesture>(_ gesture: G) -> some _OpenView {
        guard let provider = gesture as? any _OpenGestureNodeProviding else {
            return _OpenModifiedContent(content: self, modification: .effect)
        }
        return _OpenModifiedContent(
            content: self,
            modification: .gesture(provider._openGestureNode)
        )
    }

    func onLongPressGesture(
        minimumDuration: Double = 0.5,
        perform action: @escaping @MainActor () -> Void
    ) -> some _OpenView {
        simultaneousGesture(
            LongPressGesture(minimumDuration: minimumDuration)
                .onEnded { recognized in if recognized { action() } }
        )
    }

    func previewLayout(_ value: PreviewLayout) -> some _OpenView {
        _OpenModifiedContent(content: self, modification: .previewLayout(value))
    }

    func clipShape<S: Shape>(_ shape: S) -> some _OpenView {
        let radius: CGFloat
        let corners: CACornerMask
        if let rounded = shape as? RoundedRectangle {
            radius = rounded.cornerRadius
            corners = ._allKnown
        } else if let uneven = shape as? UnevenRoundedRectangle {
            radius = max(
                uneven.topLeadingRadius,
                uneven.bottomLeadingRadius,
                uneven.bottomTrailingRadius,
                uneven.topTrailingRadius
            )
            var selected: CACornerMask = []
            if uneven.topLeadingRadius > 0 { selected.insert(.layerMinXMinYCorner) }
            if uneven.topTrailingRadius > 0 { selected.insert(.layerMaxXMinYCorner) }
            if uneven.bottomLeadingRadius > 0 { selected.insert(.layerMinXMaxYCorner) }
            if uneven.bottomTrailingRadius > 0 { selected.insert(.layerMaxXMaxYCorner) }
            corners = selected
        } else if shape is Capsule || shape is Circle {
            radius = 10_000
            corners = ._allKnown
        } else {
            radius = 0
            corners = []
        }
        return _OpenModifiedContent(
            content: self,
            modification: .clipRoundedRectangle(radius, corners)
        )
    }

    func contentShape<S: Shape>(_ shape: S) -> some _OpenView {
        _ = shape
        return _OpenModifiedContent(content: self, modification: .effect)
    }

    func contentShape<S: Shape>(
        _ kinds: ContentShapeKinds,
        _ shape: S
    ) -> some _OpenView {
        _ = kinds
        return contentShape(shape)
    }

    func clipped(antialiased: Bool = false) -> some _OpenView {
        _ = antialiased
        return _OpenModifiedContent(content: self, modification: .clipped)
    }

    func hidden() -> some _OpenView {
        _OpenModifiedContent(content: self, modification: .hidden)
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
        _OpenDisabledContent(content: self, disabled: disabled)
    }

    func accessibilityHidden(_ hidden: Bool) -> some _OpenView {
        _OpenModifiedContent(
            content: self,
            modification: .accessibilityHidden(hidden)
        )
    }

    func accessibilityElement(
        children: AccessibilityChildBehavior = .ignore
    ) -> some _OpenView {
        _OpenModifiedContent(
            content: self,
            modification: .accessibilityElement(children)
        )
    }

    func accessibilityLabel(_ label: String) -> some _OpenView {
        _OpenModifiedContent(content: self, modification: .accessibilityLabel(label))
    }

    func accessibilityLabel(_ label: Text) -> some _OpenView {
        accessibilityLabel(label.content)
    }

    func accessibilityHint(_ hint: String) -> some _OpenView {
        _OpenModifiedContent(content: self, modification: .accessibilityHint(hint))
    }

    func accessibilityValue(_ value: String) -> some _OpenView {
        _OpenModifiedContent(content: self, modification: .accessibilityValue(value))
    }

    func accessibilityAddTraits(_ traits: AccessibilityTraits) -> some _OpenView {
        _OpenModifiedContent(content: self, modification: .accessibilityTraits(traits))
    }

    func accessibilityAction(
        _ kind: AccessibilityActionKind = .default,
        _ handler: @escaping @MainActor () -> Void
    ) -> some _OpenView {
        _ = kind
        return _OpenModifiedContent(
            content: self,
            modification: .accessibilityAction(name: nil, action: handler)
        )
    }

    func accessibilityAction(
        named name: Text,
        _ handler: @escaping @MainActor () -> Void
    ) -> some _OpenView {
        _OpenModifiedContent(
            content: self,
            modification: .accessibilityAction(name: name.content, action: handler)
        )
    }

    func allowsHitTesting(_ enabled: Bool) -> some _OpenView {
        _OpenModifiedContent(content: self, modification: .allowsHitTesting(enabled))
    }

    func zIndex(_ value: Double) -> some _OpenView {
        _OpenModifiedContent(content: self, modification: .zIndex(value))
    }

    func focused(_ binding: FocusState<Bool>.Binding) -> some _OpenView {
        _OpenModifiedContent(
            content: self,
            modification: .focus(
                get: { binding.wrappedValue },
                set: {
                    guard binding.wrappedValue != $0 else { return }
                    binding.wrappedValue = $0
                }
            )
        )
    }

    func focused<Value: Hashable>(
        _ binding: FocusState<Value?>.Binding,
        equals value: Value
    ) -> some _OpenView {
        _OpenModifiedContent(
            content: self,
            modification: .focus(
                get: { binding.wrappedValue == value },
                set: { focused in
                    let next: Value? = focused ? value : nil
                    guard binding.wrappedValue != next else { return }
                    binding.wrappedValue = next
                }
            )
        )
    }

    func textContentType(_ textContentType: UITextContentType?) -> some _OpenView {
        _OpenModifiedContent(
            content: self,
            modification: .textContentType(textContentType)
        )
    }

    func autocapitalization(
        _ style: UITextAutocapitalizationType
    ) -> some _OpenView {
        _OpenModifiedContent(
            content: self,
            modification: .autocapitalization(style)
        )
    }

    func disableAutocorrection(_ disable: Bool?) -> some _OpenView {
        _OpenModifiedContent(
            content: self,
            modification: .autocorrectionDisabled(disable ?? false)
        )
    }

    func onSubmit(_ action: @escaping @MainActor () -> Void) -> some _OpenView {
        _OpenModifiedContent(content: self, modification: .submit(action))
    }

    func submitLabel(_ label: SubmitLabel) -> some _OpenView {
        _OpenModifiedContent(content: self, modification: .submitLabel(label))
    }

    func scrollDismissesKeyboard(
        _ mode: ScrollDismissesKeyboardMode
    ) -> some _OpenView {
        _OpenModifiedContent(
            content: self,
            modification: .scrollDismissesKeyboard(mode)
        )
    }

    func controlSize(_ size: ControlSize) -> some _OpenView {
        _OpenModifiedContent(content: self, modification: .controlSize(size))
    }

    func imageScale(_ scale: ImageScale) -> some _OpenView {
        _OpenModifiedContent(content: self, modification: .imageScale(scale))
    }

    func progressViewStyle(
        _ style: CircularProgressViewStyle
    ) -> some _OpenView {
        _ = style
        return _OpenModifiedContent(
            content: self,
            modification: .circularProgressStyle
        )
    }

    func progressViewStyle(
        _ style: LinearProgressViewStyle
    ) -> some _OpenView {
        _ = style
        return _OpenModifiedContent(
            content: self,
            modification: .linearProgressStyle
        )
    }

    /// Establishes a retained offscreen-compositing boundary. The renderer
    /// materializes a dedicated transparent host, so modifiers outside this
    /// call (notably opacity and masks) apply once to the whole descendant
    /// result instead of being distributed across individual children.
    func compositingGroup() -> some _OpenView {
        _OpenModifiedContent(content: self, modification: .compositingGroup)
    }

    func pickerStyle(_ style: MenuPickerStyle) -> some _OpenView {
        _ = style
        return _OpenModifiedContent(content: self, modification: .menuPickerStyle)
    }

    func menuIndicator(_ visibility: Visibility) -> some _OpenView {
        _OpenModifiedContent(content: self, modification: .menuIndicator(visibility))
    }

    func symbolRenderingMode(_ mode: SymbolRenderingMode?) -> some _OpenView {
        _OpenModifiedContent(content: self, modification: .symbolRenderingMode(mode))
    }

    func accessibilityIdentifier(_ identifier: String) -> some _OpenView {
        _OpenModifiedContent(
            content: self,
            modification: .accessibilityIdentifier(identifier)
        )
    }

    func labelStyle(
        _ style: _OpenIconOnlyLabelStyle
    ) -> some _OpenView {
        _ = style
        return _OpenIconOnlyLabelStyleContent(source: self)
    }

    func alert<Actions: _OpenView, Message: _OpenView>(
        _ title: String,
        isPresented: Binding<Bool>,
        @_OpenViewBuilder actions: () -> Actions,
        @_OpenViewBuilder message: () -> Message
    ) -> some _OpenView {
        let alertActions = actions()
        let alertMessage = message()
        return _OpenModifiedContent(
            content: self,
            modification: .alert(
                title: title,
                getIsPresented: { isPresented.wrappedValue },
                setIsPresented: { isPresented.wrappedValue = $0 },
                actions: { alertActions._makeOpenUIKitNode() },
                message: { alertMessage._makeOpenUIKitNode() }
            )
        )
    }

    func alert<Data, Actions: _OpenView, Message: _OpenView>(
        _ title: String,
        isPresented: Binding<Bool>,
        presenting data: Data?,
        @_OpenViewBuilder actions: (Data) -> Actions,
        @_OpenViewBuilder message: (Data) -> Message
    ) -> some _OpenView {
        let alertActions = data.map(actions)
        let alertMessage = data.map(message)
        return _OpenModifiedContent(
            content: self,
            modification: .alert(
                title: title,
                getIsPresented: { isPresented.wrappedValue && data != nil },
                setIsPresented: { isPresented.wrappedValue = $0 },
                actions: { alertActions?._makeOpenUIKitNode() ?? _OpenViewNode(.empty) },
                message: { alertMessage?._makeOpenUIKitNode() ?? _OpenViewNode(.empty) }
            )
        )
    }

    func alert<Item: Identifiable>(
        item: Binding<Item?>,
        content: (Item) -> Alert
    ) -> some _OpenView {
        let value = item.wrappedValue
        let alert = value.map(content)
        return _OpenModifiedContent(
            content: self,
            modification: .alert(
                title: alert?.title.content ?? "",
                getIsPresented: { item.wrappedValue != nil },
                setIsPresented: { presented in
                    if !presented { item.wrappedValue = nil }
                },
                actions: {
                    alert?.actionNode() ?? _OpenViewNode(.empty)
                },
                message: {
                    alert?.message?._makeOpenUIKitNode() ?? _OpenViewNode(.empty)
                }
            )
        )
    }

    /// Presents content in OpenUIKit's measured page-sheet controller.  The
    /// destination is intentionally deferred until presentation, matching
    /// SwiftUI's lifecycle and avoiding state allocation for a closed sheet.
    func sheet<SheetContent: _OpenView>(
        isPresented: Binding<Bool>,
        @_OpenViewBuilder content: @escaping @MainActor () -> SheetContent
    ) -> some _OpenView {
        sheet(isPresented: isPresented, onDismiss: nil, content: content)
    }

    /// The dismissal callback is delivered after the concrete UIKit
    /// presentation has left its parent, including interactive swipe
    /// dismissal and programmatic binding changes. The retained presentation
    /// controller guards it so UIKit's delegate and containment callbacks
    /// cannot double-deliver one presentation cycle.
    func sheet<SheetContent: _OpenView>(
        isPresented: Binding<Bool>,
        onDismiss: (@MainActor () -> Void)?,
        @_OpenViewBuilder content: @escaping @MainActor () -> SheetContent
    ) -> some _OpenView {
        let state = _OpenPresentationState(
            getIsPresented: { isPresented.wrappedValue },
            setIsPresented: { isPresented.wrappedValue = $0 },
            onDismiss: onDismiss ?? {}
        )
        return _OpenModifiedContent(
            content: self,
            modification: .presentation(
                kind: .sheet,
                state: state,
                makeDestination: { dismiss in
                    AnyView(content().environment(\.dismiss, dismiss))
                }
            )
        )
    }

    /// Drives a UIKit navigation push from a Boolean binding.  When no
    /// navigation controller encloses the host, a full-screen presentation is
    /// used as SwiftUI's portable fallback rather than silently doing nothing.
    func navigationDestination<Destination: _OpenView>(
        isPresented: Binding<Bool>,
        @_OpenViewBuilder destination: @escaping @MainActor () -> Destination
    ) -> some _OpenView {
        let state = _OpenPresentationState(
            getIsPresented: { isPresented.wrappedValue },
            setIsPresented: { isPresented.wrappedValue = $0 }
        )
        return _OpenModifiedContent(
            content: self,
            modification: .presentation(
                kind: .navigationDestination,
                state: state,
                makeDestination: { dismiss in
                    AnyView(destination().environment(\.dismiss, dismiss))
                }
            )
        )
    }

    /// Registers an exact typed value destination for the nearest
    /// NavigationStack. Builders remain lazy with respect to values absent
    /// from the path and fail closed when AnyHashable's dynamic type differs.
    func navigationDestination<Data: Hashable, Destination: _OpenView>(
        for data: Data.Type,
        @_OpenViewBuilder destination: @escaping @MainActor (Data) -> Destination
    ) -> some _OpenView {
        _ = data
        return _OpenModifiedContent(
            content: self,
            modification: .navigationDestination(
                _OpenNavigationDestinationRegistration(
                    valueType: ObjectIdentifier(Data.self),
                    matches: { $0.base is Data },
                    makeNode: { value in
                        guard let typed = value.base as? Data else { return nil }
                        return destination(typed)._makeOpenUIKitNode()
                    }
                )
            )
        )
    }

    func navigationSplitViewColumnWidth(_ width: CGFloat) -> some _OpenView {
        _OpenModifiedContent(
            content: self,
            modification: .frame(
                width: max(0, width),
                height: nil,
                alignment: .center
            )
        )
    }

    func navigationSplitViewColumnWidth(
        min minimum: CGFloat? = nil,
        ideal: CGFloat,
        max maximum: CGFloat? = nil
    ) -> some _OpenView {
        let lower = max(0, minimum ?? 0)
        let upper = max(lower, maximum ?? .greatestFiniteMagnitude)
        let width = min(max(ideal, lower), upper)
        return navigationSplitViewColumnWidth(width)
    }

    func glassEffect() -> some _OpenView {
        _OpenModifiedContent(content: self, modification: .glassEffect)
    }

    func glassEffect<S: Shape>(
        _ glass: Glass,
        in shape: S
    ) -> some _OpenView {
        _ = glass
        let radius: CGFloat
        if let rounded = shape as? RoundedRectangle {
            radius = rounded.cornerRadius
        } else if shape is Capsule || shape is Circle {
            radius = 10_000
        } else {
            radius = 0
        }
        return _OpenModifiedContent(
            content: self,
            modification: .clipRoundedRectangle(radius, ._allKnown)
        ).glassEffect()
    }

    func glassEffectTransition(_ transition: GlassEffectTransition) -> some _OpenView {
        _ = transition
        return _OpenModifiedContent(content: self, modification: .effect)
    }

    func buttonBorderShape(_ shape: ButtonBorderShape) -> some _OpenView {
        _OpenModifiedContent(content: self, modification: .buttonBorderShape(shape))
    }

    func contextMenu<MenuItems: _OpenView>(
        @_OpenViewBuilder menuItems: () -> MenuItems
    ) -> some _OpenView {
        let menuItems = menuItems()
        return _OpenModifiedContent(
            content: self,
            modification: .contextMenu { menuItems._makeOpenUIKitNode() }
        )
    }

    func contextMenu<MenuItems: _OpenView, Preview: _OpenView>(
        @_OpenViewBuilder menuItems: () -> MenuItems,
        @_OpenViewBuilder preview: () -> Preview
    ) -> some _OpenView {
        _ = preview()
        return contextMenu(menuItems: menuItems)
    }

    func id<ID: Hashable>(_ id: ID) -> some _OpenView {
        _OpenModifiedContent(content: self, modification: .identifier(AnyHashable(id)))
    }

    func preference<Key: PreferenceKey>(
        key: Key.Type = Key.self,
        value: Key.Value
    ) -> some _OpenView {
        _OpenModifiedContent(
            content: self,
            modification: .preference(
                _OpenPreferenceRecord(key: ObjectIdentifier(key), value: value)
            )
        )
    }

    func onPreferenceChange<Key: PreferenceKey>(
        _ key: Key.Type = Key.self,
        perform action: @escaping @MainActor (Key.Value) -> Void
    ) -> some _OpenView {
        _OpenModifiedContent(
            content: self,
            modification: .preferenceListener(
                _OpenPreferenceListener(
                    key: ObjectIdentifier(key),
                    defaultValue: Key.defaultValue,
                    reduce: { aggregate, next in
                        guard var typed = aggregate as? Key.Value,
                              let typedNext = next as? Key.Value else { return }
                        Key.reduce(value: &typed, nextValue: { typedNext })
                        aggregate = typed
                    },
                    action: { value in
                        guard let typed = value as? Key.Value else { return }
                        action(typed)
                    }
                )
            )
        )
    }

    func transaction(_ transform: (inout Transaction) -> Void) -> some _OpenView {
        var transaction = Transaction(animation: _OpenAnimationContext.current)
        transform(&transaction)
        return _OpenModifiedContent(content: self, modification: .effect)
    }

    func transition(_ transition: AnyTransition) -> _OpenEffectContent {
        _ = transition
        return _OpenEffectContent(content: self, modification: .effect)
    }

    func contentTransition(_ transition: ContentTransition) -> _OpenEffectContent {
        _ = transition
        return _OpenEffectContent(content: self, modification: .effect)
    }

    func matchedGeometryEffect<ID: Hashable>(
        id: ID,
        in namespace: Namespace.ID,
        properties: _OpenMatchedGeometryProperties = .frame,
        anchor: UnitPoint = .center,
        isSource: Bool = true
    ) -> some _OpenView {
        _ = properties
        _ = anchor
        return _OpenModifiedContent(
            content: self,
            modification: .matchedGeometry(
                id: AnyHashable(id),
                namespace: namespace,
                isSource: isSource
            )
        )
    }

    func onChange<Value: Equatable>(
        of value: Value,
        perform action: @escaping @MainActor (Value) -> Void
    ) -> _OpenEffectContent {
        _OpenEffectContent(
            content: self,
            modification: .onChange {
                _OpenGraphContext.trackChange(value, action: action)
            }
        )
    }

    func onChange<Value: Equatable>(
        of value: Value,
        _ action: @escaping @MainActor (Value, Value) -> Void
    ) -> _OpenEffectContent {
        _OpenEffectContent(
            content: self,
            modification: .onChange {
                _OpenGraphContext.trackChange(value) { oldValue, newValue in
                    action(oldValue, newValue)
                }
            }
        )
    }

    func animation<Value: Equatable>(
        _ animation: Animation?,
        value: Value
    ) -> _OpenEffectContent {
        _OpenEffectContent(
            content: self,
            modification: .animation {
                _OpenGraphContext.trackAnimation(animation, value: value)
            }
        )
    }

    func onReceive<PublisherType: Combine.Publisher>(
        _ publisher: PublisherType,
        perform action: @escaping @MainActor (PublisherType.Output) -> Void
    ) -> _OpenEffectContent {
        _OpenEffectContent(
            content: self,
            modification: .onReceive {
                _OpenGraphContext.subscribe(publisher, action: action)
            }
        )
    }

    func task(
        priority: TaskPriority? = nil,
        _ action: @escaping @MainActor () async -> Void
    ) -> some _OpenView {
        task(id: _OpenDefaultTaskIdentity.value, priority: priority, action)
    }

    func task<ID: Equatable>(
        id value: ID,
        priority: TaskPriority? = nil,
        _ action: @escaping @MainActor () async -> Void
    ) -> some _OpenView {
        _OpenModifiedContent(
            content: self,
            modification: .task {
                _OpenGraphContext.installTask(
                    id: value,
                    priority: priority,
                    action: action
                )
            }
        )
    }

    func navigationBarHidden(_ hidden: Bool) -> some _OpenView {
        _OpenModifiedContent(content: self, modification: .navigationBarHidden(hidden))
    }

    func navigationBarBackButtonHidden(_ hidden: Bool = true) -> some _OpenView {
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

    func navigationBarItems<Trailing: _OpenView>(
        trailing: Trailing
    ) -> some _OpenView {
        return _OpenModifiedContent(
            content: self,
            modification: .toolbar { trailing._makeOpenUIKitNode() }
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

    func searchable(
        text: Binding<String>,
        placement: SearchFieldPlacement = .automatic,
        prompt: String = "Search"
    ) -> some _OpenView {
        _OpenModifiedContent(
            content: self,
            modification: .searchable(
                _OpenSearchConfiguration(
                    getText: { text.wrappedValue },
                    setText: { text.wrappedValue = $0 },
                    prompt: prompt,
                    placement: placement
                )
            )
        )
    }

    func searchToolbarBehavior(
        _ behavior: SearchToolbarBehavior
    ) -> some _OpenView {
        _OpenModifiedContent(
            content: self,
            modification: .searchToolbarBehavior(behavior)
        )
    }

    func toolbar(
        _ visibility: Visibility,
        for placement: ToolbarPlacement
    ) -> some _OpenView {
        _OpenModifiedContent(
            content: self,
            modification: .toolbarVisibility(visibility, placement)
        )
    }

    func toolbarBackground(
        _ visibility: Visibility,
        for placement: ToolbarPlacement
    ) -> some _OpenView {
        _OpenModifiedContent(
            content: self,
            modification: .toolbarBackgroundVisibility(visibility, placement)
        )
    }

    func refreshable(
        action: @escaping @MainActor @Sendable () async -> Void
    ) -> some _OpenView {
        _OpenModifiedContent(content: self, modification: .refreshable(action))
    }

    func safeAreaInset<Content: _OpenView>(
        edge: Edge,
        alignment: HorizontalAlignment = .center,
        spacing: CGFloat? = nil,
        @_OpenViewBuilder content: () -> Content
    ) -> some _OpenView {
        _ = alignment
        let insetContent = content()
        return _OpenModifiedContent(
            content: self,
            modification: .safeAreaInset(
                edge: edge,
                spacing: spacing,
                content: { insetContent._makeOpenUIKitNode() }
            )
        )
    }

    func scrollIndicators(_ visibility: Visibility) -> some _OpenView {
        _OpenModifiedContent(content: self, modification: .scrollIndicators(visibility))
    }

    func scrollDisabled(_ disabled: Bool) -> some _OpenView {
        _OpenModifiedContent(content: self, modification: .scrollDisabled(disabled))
    }

    func onScrollPhaseChange(
        _ action: @escaping @MainActor (
            ScrollPhase,
            ScrollPhase,
            ScrollPhaseChangeContext
        ) -> Void
    ) -> some _OpenView {
        _OpenModifiedContent(
            content: self,
            modification: .scrollPhase(_OpenScrollPhaseObserver(deliver: action))
        )
    }

    func scrollTargetLayout() -> some _OpenView {
        _OpenModifiedContent(content: self, modification: .effect)
    }

    func onScrollTargetVisibilityChange<ID: Hashable>(
        idType: ID.Type,
        threshold: CGFloat = 0.5,
        _ action: @escaping @MainActor ([ID]) -> Void
    ) -> some _OpenView {
        _ = idType
        return _OpenModifiedContent(
            content: self,
            modification: .scrollVisibility(
                _OpenScrollVisibilityObserver(
                    threshold: min(max(threshold, 0), 1),
                    deliver: { values in action(values.compactMap { $0.base as? ID }) }
                )
            )
        )
    }

    func onScrollGeometryChange<Value: Equatable>(
        for type: Value.Type,
        of transform: @escaping @MainActor (ScrollGeometry) -> Value,
        action: @escaping @MainActor (Value, Value) -> Void
    ) -> some _OpenView {
        _ = type
        return _OpenModifiedContent(
            content: self,
            modification: .scrollGeometry(
                _OpenScrollGeometryObserver(
                    read: { transform($0) },
                    equals: { lhs, rhs in
                        guard let lhs = lhs as? Value,
                              let rhs = rhs as? Value else { return false }
                        return lhs == rhs
                    },
                    deliver: { old, new in
                        guard let old = old as? Value, let new = new as? Value else { return }
                        action(old, new)
                    }
                )
            )
        )
    }

    func onGeometryChange<Value: Equatable>(
        for type: Value.Type,
        of transform: @escaping @MainActor (GeometryProxy) -> Value,
        action: @escaping @MainActor (Value) -> Void
    ) -> some _OpenView {
        _ = type
        return _OpenModifiedContent(
            content: self,
            modification: .geometryObserver(
                _OpenGeometryObserver(
                    read: { transform($0) },
                    deliver: { value in
                        guard let value = value as? Value else { return }
                        action(value)
                    }
                )
            )
        )
    }

    func swipeActions<Actions: _OpenView>(
        edge: Edge = .trailing,
        allowsFullSwipe: Bool = true,
        @_OpenViewBuilder content: () -> Actions
    ) -> some _OpenView {
        let actions = content()
        return _OpenModifiedContent(
            content: self,
            modification: .swipeActions(
                edge: edge,
                allowsFullSwipe: allowsFullSwipe,
                actions: { actions._makeOpenUIKitNode() }
            )
        )
    }

    func swipeActionsContainer() -> some _OpenView {
        _OpenModifiedContent(content: self, modification: .effect)
    }

    func listStyle(_ style: ListStyle) -> some _OpenView {
        _OpenModifiedContent(content: self, modification: .listStyle(style))
    }

    func listStyle(_ style: GroupedListStyle) -> some _OpenView {
        _ = style
        return _OpenModifiedContent(content: self, modification: .listStyle(.grouped))
    }

    func listRowBackground<Background: _OpenView>(
        _ background: Background
    ) -> some _OpenView {
        _OpenModifiedContent(
            content: self,
            modification: .listRowBackground {
                background._makeOpenUIKitNode()
            }
        )
    }

    func listRowSeparator(
        _ visibility: Visibility,
        edges: VerticalEdge.Set = .all
    ) -> some _OpenView {
        _OpenModifiedContent(
            content: self,
            modification: .listRowSeparator(visibility, edges)
        )
    }

    func listRowInsets(_ insets: EdgeInsets?) -> some _OpenView {
        guard let insets else {
            return _OpenModifiedContent(content: self, modification: .effect)
        }
        return _OpenModifiedContent(content: self, modification: .edgeInsetsPadding(insets))
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

private enum _OpenDefaultTaskIdentity: Equatable {
    case value
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
    /// True when `.searchable(..., placement: .toolbar)` is on the tree.
    /// Stored as a Bool (not the closure-bearing search config) so
    /// `evaluateRoot` does not trip a SIL ownership crash on the optional.
    var searchIsToolbar = false
    var destinations: [_OpenNavigationDestinationRegistration] = []
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
        case .navigationDestination(let registration):
            configuration.destinations.append(registration)
        case .toolbar(let toolbar):
            configuration.toolbar = toolbar
        case .searchable(let search):
            // Copy the placement into chrome so UIHostingController /
            // NavigationStack can install the 44×44 nav platter; keep the
            // modifier on the node so SwiftUIDesignSystemTests still find
            // `SwiftUI.Searchable`.
            configuration.searchIsToolbar = search.placement == .toolbar
            unwrapped = _OpenViewNode(.modified(unwrapped, modification))
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
    case .grid(let rows, let horizontalSpacing, let verticalSpacing):
        let (unwrapped, configuration) = _extractNavigationChildren(rows)
        return (
            _OpenViewNode(
                .grid(
                    rows: unwrapped,
                    horizontalSpacing: horizontalSpacing,
                    verticalSpacing: verticalSpacing
                )
            ),
            configuration
        )
    case .gridRow(let cells):
        let (unwrapped, configuration) = _extractNavigationChildren(cells)
        return (_OpenViewNode(.gridRow(unwrapped)), configuration)
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
        configuration.searchIsToolbar = configuration.searchIsToolbar
            || childConfiguration.searchIsToolbar
        configuration.destinations.append(contentsOf: childConfiguration.destinations)
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
public typealias Group<Content> = _OpenGroup<Content> where Content: _OpenView
public typealias _ConditionalContent<TrueContent, FalseContent> =
    _OpenConditionalContent<TrueContent, FalseContent>
    where TrueContent: _OpenView, FalseContent: _OpenView
public typealias Text = _OpenText
public typealias Image = _OpenImage
public typealias Spacer = _OpenSpacer
public typealias Divider = _OpenDivider
public typealias Label<Title, Icon> = _OpenLabel<Title, Icon>
    where Title: _OpenView, Icon: _OpenView
public typealias IconOnlyLabelStyle = _OpenIconOnlyLabelStyle
public typealias HStack<Content> = _OpenHStack<Content> where Content: _OpenView
public typealias VStack<Content> = _OpenVStack<Content> where Content: _OpenView
public typealias Form<Content> = _OpenForm<Content> where Content: _OpenView
public typealias ForEach<Data, ID, Content> = _OpenForEach<Data, ID, Content>
    where Data: RandomAccessCollection, ID: Hashable, Content: _OpenView
public typealias NavigationView<Content> = _OpenNavigationView<Content> where Content: _OpenView
public typealias NavigationPath = _OpenNavigationPath
public typealias NavigationStack<Content> = _OpenNavigationStack<Content>
    where Content: _OpenView
public typealias NavigationSplitViewVisibility = _OpenNavigationSplitViewVisibility
public typealias NavigationSplitView<Sidebar, Detail> =
    _OpenNavigationSplitView<Sidebar, Detail>
    where Sidebar: _OpenView, Detail: _OpenView
public typealias LinearGradient = _OpenLinearGradient
public typealias PreviewProvider = _OpenPreviewProvider
