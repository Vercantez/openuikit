// SwiftUI settings controls used by Focus's exact internal-settings screens.
// These are retained graph nodes backed by real OpenUIKit controls. Bindings
// update application state, publisher/change effects participate in the host
// graph, and disabled state flows through the render environment.

#if canImport(Foundation)
import Foundation
#elseif canImport(FoundationEssentials)
import FoundationEssentials
#endif
import Combine
import OpenUIKit

/// A centered empty-state surface with retained label, description and
/// action subtrees. Keeping the three regions structurally distinct preserves
/// dynamic-property identity when an unavailable view is reevaluated while
/// still rendering through ordinary SwiftUI layout primitives.
public struct _OpenContentUnavailableView<LabelContent: _OpenView,
    DescriptionContent: _OpenView, ActionsContent: _OpenView>: _OpenView
{
    public typealias Body = Never
    public let label: LabelContent
    public let description: DescriptionContent?
    public let actions: ActionsContent?

    public init(
        @_OpenViewBuilder label: () -> LabelContent,
        @_OpenViewBuilder description: () -> DescriptionContent,
        @_OpenViewBuilder actions: () -> ActionsContent
    ) {
        self.label = label()
        self.description = description()
        self.actions = actions()
    }

    public init(
        @_OpenViewBuilder label: () -> LabelContent,
        @_OpenViewBuilder description: () -> DescriptionContent
    ) where ActionsContent == EmptyView {
        self.label = label()
        self.description = description()
        actions = nil
    }

    public init(
        @_OpenViewBuilder label: () -> LabelContent
    ) where DescriptionContent == EmptyView, ActionsContent == EmptyView {
        self.label = label()
        description = nil
        actions = nil
    }

    public func _makeOpenUIKitNode() -> _OpenViewNode {
        var children: [_OpenViewNode] = [_OpenViewNode(.spacer(minLength: 0))]
        children.append(
            _OpenGraphContext.withStructuralScope(.sectionHeader) {
                label._makeOpenUIKitNode()
            }
        )
        if let description {
            children.append(
                _OpenGraphContext.withStructuralScope(.sectionContent) {
                    description._makeOpenUIKitNode()
                }
            )
        }
        if let actions {
            children.append(
                _OpenGraphContext.withStructuralScope(.sectionFooter) {
                    actions._makeOpenUIKitNode()
                }
            )
        }
        children.append(_OpenViewNode(.spacer(minLength: 0)))
        return _OpenViewNode(
            .vStack(children: children, alignment: .center, spacing: 12)
        )
    }
}

public extension _OpenContentUnavailableView
where LabelContent == _OpenLabel<_OpenText, _OpenImage>,
      DescriptionContent == _OpenText,
      ActionsContent == _OpenEmptyView
{
    init(
        _ title: String,
        systemImage: String,
        description: Text? = nil
    ) {
        label = Label(title, systemImage: systemImage)
        self.description = description
        actions = nil
    }
}

public typealias ContentUnavailableView<LabelContent: _OpenView,
    DescriptionContent: _OpenView, ActionsContent: _OpenView> =
    _OpenContentUnavailableView<LabelContent, DescriptionContent, ActionsContent>

public struct _OpenSection<Parent: _OpenView, Content: _OpenView, Footer: _OpenView>:
    _OpenView
{
    public typealias Body = Never
    public let header: Parent?
    public let content: Content
    public let footer: Footer?

    public init(
        header: Parent,
        footer: Footer,
        @_OpenViewBuilder content: () -> Content
    ) {
        self.header = header
        self.content = content()
        self.footer = footer
    }

    public init(
        header: Parent,
        @_OpenViewBuilder content: () -> Content
    ) where Footer == _OpenEmptyView {
        self.header = header
        self.content = content()
        footer = nil
    }

    public init(
        footer: Footer,
        @_OpenViewBuilder content: () -> Content
    ) where Parent == _OpenEmptyView {
        header = nil
        self.content = content()
        self.footer = footer
    }

    public init(
        @_OpenViewBuilder content: () -> Content,
        @_OpenViewBuilder footer: () -> Footer
    ) where Parent == _OpenEmptyView {
        header = nil
        self.content = content()
        self.footer = footer()
    }

    public init(
        @_OpenViewBuilder content: () -> Content
    ) where Parent == _OpenEmptyView, Footer == _OpenEmptyView {
        header = nil
        self.content = content()
        footer = nil
    }

    public func _makeOpenUIKitNode() -> _OpenViewNode {
        let headerNode = header.map { header in
            _OpenGraphContext.withStructuralScope(.sectionHeader) {
                header._makeOpenUIKitNode()
            }
        }
        let contentNode = _OpenGraphContext.withStructuralScope(.sectionContent) {
            content._makeOpenUIKitNode()
        }
        let footerNode = footer.map { footer in
            _OpenGraphContext.withStructuralScope(.sectionFooter) {
                footer._makeOpenUIKitNode()
            }
        }
        return _OpenViewNode(
            .section(
                header: headerNode,
                footer: footerNode,
                rows: _openFlattenGroup(contentNode)
            )
        )
    }
}

/// A value-bound slider backed by OpenUIKit's measured UISlider. Values are
/// snapped to the declared step before the binding is updated, and reversed
/// or non-finite ranges fail closed to a stable lower-bound value.
public struct _OpenSlider<Value: BinaryFloatingPoint>: _OpenView {
    public typealias Body = Never
    public let value: Binding<Value>
    public let bounds: ClosedRange<Value>
    public let step: Value

    public init(
        value: Binding<Value>,
        in bounds: ClosedRange<Value> = 0 ... 1,
        step: Value = 1
    ) {
        self.value = value
        self.bounds = bounds
        self.step = step
    }

    public func _makeOpenUIKitNode() -> _OpenViewNode {
        let minimum = Double(bounds.lowerBound)
        let maximum = Double(bounds.upperBound)
        let increment = Double(step)
        return _OpenViewNode(
            .slider(
                value: Double(value.wrappedValue),
                minimum: minimum,
                maximum: maximum,
                step: increment,
                setValue: { rawValue in
                    let lower = min(minimum, maximum)
                    let upper = max(minimum, maximum)
                    let clamped = min(max(rawValue, lower), upper)
                    let snapped: Double
                    if increment.isFinite, increment > 0 {
                        snapped = min(
                            max(
                                lower + ((clamped - lower) / increment)
                                    .rounded(.toNearestOrAwayFromZero) * increment,
                                lower
                            ),
                            upper
                        )
                    } else {
                        snapped = clamped
                    }
                    value.wrappedValue = Value(snapped)
                }
            )
        )
    }
}

/// Retained two-dimensional grid. Rows share column widths computed from the
/// largest cell in each column, so a non-square row set remains aligned.
public struct _OpenGrid<Content: _OpenView>: _OpenView {
    public typealias Body = Never
    public let horizontalSpacing: CGFloat?
    public let verticalSpacing: CGFloat?
    public let content: Content

    public init(
        horizontalSpacing: CGFloat? = nil,
        verticalSpacing: CGFloat? = nil,
        @_OpenViewBuilder content: () -> Content
    ) {
        self.horizontalSpacing = horizontalSpacing
        self.verticalSpacing = verticalSpacing
        self.content = content()
    }

    public func _makeOpenUIKitNode() -> _OpenViewNode {
        let contentNode = _OpenGraphContext.withStructuralScope(.vStackContent) {
            content._makeOpenUIKitNode()
        }
        return _OpenViewNode(
            .grid(
                rows: _openFlattenGroup(contentNode),
                horizontalSpacing: horizontalSpacing,
                verticalSpacing: verticalSpacing
            )
        )
    }
}

public struct _OpenGridRow<Content: _OpenView>: _OpenView {
    public typealias Body = Never
    public let content: Content

    public init(@_OpenViewBuilder content: () -> Content) {
        self.content = content()
    }

    public func _makeOpenUIKitNode() -> _OpenViewNode {
        let contentNode = _OpenGraphContext.withStructuralScope(.hStackContent) {
            content._makeOpenUIKitNode()
        }
        return _OpenViewNode(.gridRow(_openFlattenGroup(contentNode)))
    }
}

/// A URL-opening control with link accessibility semantics. The destination
/// remains a typed Foundation URL until activation and is dispatched through
/// UIApplication's existing portable URL boundary.
public struct _OpenLink<Label: _OpenView>: _OpenView {
    public typealias Body = Never
    public let destination: URL
    public let label: Label

    public init(
        destination: URL,
        @_OpenViewBuilder label: () -> Label
    ) {
        self.destination = destination
        self.label = label()
    }

    public init(_ title: String, destination: URL) where Label == _OpenText {
        self.destination = destination
        label = _OpenText(title)
    }

    public func _makeOpenUIKitNode() -> _OpenViewNode {
        _OpenViewNode(
            .link(
                label: _OpenGraphContext.withStructuralScope(.buttonLabel) {
                    label._makeOpenUIKitNode()
                },
                destination: destination
            )
        )
    }
}

public struct _OpenCircularProgressViewStyle: Hashable, Sendable {
    public init() {}
    public static let circular = _OpenCircularProgressViewStyle()
}

/// Legacy alert value used by `alert(item:)`. Buttons are retained actions,
/// not labels discarded at compile time, and map to UIAlertAction roles.
public struct _OpenAlert {
    public struct Button {
        let label: _OpenText
        let role: ButtonRole?
        let action: @MainActor () -> Void

        public static func `default`(
            _ label: Text,
            action: (@MainActor () -> Void)? = nil
        ) -> Button {
            Button(label: label, role: nil, action: action ?? {})
        }

        public static func cancel(
            _ label: Text,
            action: (@MainActor () -> Void)? = nil
        ) -> Button {
            Button(label: label, role: .cancel, action: action ?? {})
        }

        public static func destructive(
            _ label: Text,
            action: (@MainActor () -> Void)? = nil
        ) -> Button {
            Button(label: label, role: .destructive, action: action ?? {})
        }
    }

    let title: _OpenText
    let message: _OpenText?
    let buttons: [Button]

    public init(
        title: Text,
        message: Text? = nil,
        dismissButton: Button? = nil
    ) {
        self.title = title
        self.message = message
        buttons = dismissButton.map { [$0] } ?? []
    }

    public init(
        title: Text,
        message: Text? = nil,
        primaryButton: Button,
        secondaryButton: Button
    ) {
        self.title = title
        self.message = message
        buttons = [primaryButton, secondaryButton]
    }

    @MainActor
    func actionNode() -> _OpenViewNode {
        _OpenViewNode(
            .group(
                buttons.map { button in
                    _OpenViewNode(
                        .button(
                            label: button.label._makeOpenUIKitNode(),
                            pressedLabel: nil,
                            role: button.role,
                            action: button.action
                        )
                    )
                }
            )
        )
    }
}

public struct _OpenToggle<Label: _OpenView>: _OpenView {
    public typealias Body = Never
    public let isOn: Binding<Bool>
    public let label: Label

    public init(
        isOn: Binding<Bool>,
        @_OpenViewBuilder label: () -> Label
    ) {
        self.isOn = isOn
        self.label = label()
    }

    public init(_ title: String, isOn: Binding<Bool>) where Label == _OpenText {
        self.isOn = isOn
        label = _OpenText(title)
    }

    public func _makeOpenUIKitNode() -> _OpenViewNode {
        _OpenViewNode(
            .toggle(
                label: _OpenGraphContext.withStructuralScope(.toggleLabel) {
                    label._makeOpenUIKitNode()
                },
                isOn: isOn.wrappedValue,
                setIsOn: { isOn.wrappedValue = $0 }
            )
        )
    }
}

public struct _OpenTextField: _OpenView {
    public typealias Body = Never
    public let title: String
    public let text: Binding<String>
    public let axis: Axis

    public init(_ title: String, text: Binding<String>) {
        self.title = title
        self.text = text
        axis = .horizontal
    }

    public init(_ title: String, text: Binding<String>, axis: Axis) {
        self.title = title
        self.text = text
        self.axis = axis
    }

    public func _makeOpenUIKitNode() -> _OpenViewNode {
        _OpenViewNode(
            .textField(
                title: title,
                text: text.wrappedValue,
                isSecure: false,
                axis: axis,
                setText: { text.wrappedValue = $0 }
            )
        )
    }
}

public struct _OpenSecureField: _OpenView {
    public typealias Body = Never
    public let title: String
    public let text: Binding<String>

    public init(_ title: String, text: Binding<String>) {
        self.title = title
        self.text = text
    }

    public func _makeOpenUIKitNode() -> _OpenViewNode {
        _OpenViewNode(
            .textField(
                title: title,
                text: text.wrappedValue,
                isSecure: true,
                axis: .horizontal,
                setText: { text.wrappedValue = $0 }
            )
        )
    }
}

/// Indeterminate progress maps to OpenUIKit's real activity view. A string
/// label is retained as adjacent SwiftUI text, matching the accessibility and
/// layout contract of `ProgressView("…")` without inventing a second control.
public struct _OpenProgressView: _OpenView {
    public typealias Body = Never
    public let title: String?

    public init() { title = nil }

    public init(_ title: String) { self.title = title }

    public func _makeOpenUIKitNode() -> _OpenViewNode {
        let progress = _OpenViewNode(.progress)
        guard let title else { return progress }
        return _OpenViewNode(
            .hStack(
                children: [progress, _OpenViewNode(.text(title))],
                alignment: .center,
                spacing: 8
            )
        )
    }
}

public struct _OpenPicker<SelectionValue: Hashable, Label: _OpenView, Content: _OpenView>:
    _OpenView
{
    public typealias Body = Never
    public let selection: Binding<SelectionValue>
    public let label: Label
    public let content: Content

    public init(
        selection: Binding<SelectionValue>,
        label: Label,
        @_OpenViewBuilder content: () -> Content
    ) {
        self.selection = selection
        self.label = label
        self.content = content()
    }

    /// SwiftUI's trailing-content/trailing-label spelling, used by Settings
    /// forms to keep a rich Label beside a menu-backed selection control.
    public init(
        selection: Binding<SelectionValue>,
        @_OpenViewBuilder content: () -> Content,
        @_OpenViewBuilder label: () -> Label
    ) {
        self.selection = selection
        self.label = label()
        self.content = content()
    }

    public init(
        _ title: String,
        selection: Binding<SelectionValue>,
        @_OpenViewBuilder content: () -> Content
    ) where Label == _OpenText {
        self.selection = selection
        label = _OpenText(title)
        self.content = content()
    }

    public func _makeOpenUIKitNode() -> _OpenViewNode {
        let labelNode = _OpenGraphContext.withStructuralScope(.pickerLabel) {
            label._makeOpenUIKitNode()
        }
        let contentNode = _OpenGraphContext.withStructuralScope(.pickerContent) {
            content._makeOpenUIKitNode()
        }
        let options = _openFlattenGroup(contentNode).map { node -> _OpenPickerOption in
            let extracted = _openExtractTag(node)
            guard let tag = extracted.tag else {
                preconditionFailure("SwiftUI Picker options require a tag or ForEach identity")
            }
            return _OpenPickerOption(content: extracted.content, tag: tag)
        }
        return _OpenViewNode(
            .picker(
                label: labelNode,
                options: options,
                selection: AnyHashable(selection.wrappedValue),
                setSelection: { tag in
                    guard let value = tag.base as? SelectionValue else { return }
                    selection.wrappedValue = value
                }
            )
        )
    }
}

public struct _OpenMenuPickerStyle: Sendable {
    public init() {}
    public static let menu = _OpenMenuPickerStyle()
}

public typealias MenuPickerStyle = _OpenMenuPickerStyle

public typealias Section<Parent, Content, Footer> =
    _OpenSection<Parent, Content, Footer>
    where Parent: _OpenView, Content: _OpenView, Footer: _OpenView
public typealias Toggle<Label> = _OpenToggle<Label> where Label: _OpenView
public typealias TextField = _OpenTextField
public typealias SecureField = _OpenSecureField
public typealias ProgressView = _OpenProgressView
public typealias Slider<Value> = _OpenSlider<Value> where Value: BinaryFloatingPoint
public typealias Grid<Content> = _OpenGrid<Content> where Content: _OpenView
public typealias GridRow<Content> = _OpenGridRow<Content> where Content: _OpenView
public typealias Link<Label> = _OpenLink<Label> where Label: _OpenView
public typealias CircularProgressViewStyle = _OpenCircularProgressViewStyle
public typealias Alert = _OpenAlert
public typealias Picker<SelectionValue, Label, Content> =
    _OpenPicker<SelectionValue, Label, Content>
    where SelectionValue: Hashable, Label: _OpenView, Content: _OpenView
