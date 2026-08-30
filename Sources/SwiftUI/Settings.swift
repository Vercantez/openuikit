// SwiftUI settings controls used by Focus's exact internal-settings screens.
// These are retained graph nodes backed by real OpenUIKit controls. Bindings
// update application state, publisher/change effects participate in the host
// graph, and disabled state flows through the render environment.

import Combine
import OpenUIKit

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

    public init(_ title: String, text: Binding<String>) {
        self.title = title
        self.text = text
    }

    public func _makeOpenUIKitNode() -> _OpenViewNode {
        _OpenViewNode(
            .textField(
                title: title,
                text: text.wrappedValue,
                setText: { text.wrappedValue = $0 }
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

public typealias Section<Parent, Content, Footer> =
    _OpenSection<Parent, Content, Footer>
    where Parent: _OpenView, Content: _OpenView, Footer: _OpenView
public typealias Toggle<Label> = _OpenToggle<Label> where Label: _OpenView
public typealias TextField = _OpenTextField
public typealias Picker<SelectionValue, Label, Content> =
    _OpenPicker<SelectionValue, Label, Content>
    where SelectionValue: Hashable, Label: _OpenView, Content: _OpenView
