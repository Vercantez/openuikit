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

public struct _OpenButton<Label: _OpenView>: _OpenView {
    public typealias Body = Never
    public let action: @MainActor () -> Void
    public let label: Label

    public init(
        action: @escaping @MainActor () -> Void,
        @_OpenViewBuilder label: () -> Label
    ) {
        self.action = action
        self.label = label()
    }

    public init(
        _ title: String,
        action: @escaping @MainActor () -> Void
    ) where Label == _OpenText {
        self.action = action
        label = _OpenText(title)
    }

    public func _makeOpenUIKitNode() -> _OpenViewNode {
        _OpenViewNode(
            .button(
                label: _OpenGraphContext.withStructuralScope(.buttonLabel) {
                    label._makeOpenUIKitNode()
                },
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

public struct _OpenUIViewControllerRepresentableContext<Representable> {
    public init() {}
}

@MainActor
public protocol _OpenUIViewControllerRepresentable: _OpenView where Body == Never {
    associatedtype UIViewControllerType: UIViewController

    func makeUIViewController(
        context: _OpenUIViewControllerRepresentableContext<Self>
    ) -> UIViewControllerType
    func updateUIViewController(
        _ uiViewController: UIViewControllerType,
        context: _OpenUIViewControllerRepresentableContext<Self>
    )
}

public extension _OpenUIViewControllerRepresentable {
    typealias Context = _OpenUIViewControllerRepresentableContext<Self>

    func _makeOpenUIKitNode() -> _OpenViewNode {
        _OpenGraphContext.withView(self) { preparedView in
            let context = Context()
            let controller = _OpenGraphContext.representedController(
                make: { preparedView.makeUIViewController(context: context) },
                update: { preparedView.updateUIViewController($0, context: context) }
            )
            return _OpenViewNode(.viewController(controller))
        }
    }
}

@MainActor
@discardableResult
public func withAnimation<Result>(_ body: () throws -> Result) rethrows -> Result {
    try body()
}

@MainActor
func _openFlattenGroup(_ node: _OpenViewNode) -> [_OpenViewNode] {
    if case .group(let children) = node.kind {
        return children.flatMap { _openFlattenGroup($0) }
    }
    return [node]
}

@MainActor
private func _openExtractTag(
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
public typealias PageTabViewStyle = _OpenPageTabViewStyle
public typealias EdgeInsets = _OpenEdgeInsets
public typealias TapGesture = _OpenTapGesture
public typealias ZStack<Content> = _OpenZStack<Content> where Content: _OpenView
public typealias Button<Label> = _OpenButton<Label> where Label: _OpenView
public typealias ScrollView<Content> = _OpenScrollView<Content> where Content: _OpenView
public typealias TabView<SelectionValue, Content> = _OpenTabView<SelectionValue, Content>
    where SelectionValue: Hashable, Content: _OpenView
public typealias UIViewControllerRepresentableContext<Representable> =
    _OpenUIViewControllerRepresentableContext<Representable>
public typealias UIViewControllerRepresentable = _OpenUIViewControllerRepresentable
