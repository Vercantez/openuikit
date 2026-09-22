// SwiftUI S3: the list/navigation vocabulary used by Mozilla Focus's exact
// Licenses target. NavigationLink creates a fresh retained hosting graph for
// its destination and pushes it through the enclosing UIKit navigation
// controller; application source does not participate in that bridge.

import OpenUIKit

public struct _OpenList<Content: _OpenView>: _OpenView {
    public typealias Body = Never
    public let content: Content

    public init(@_OpenViewBuilder content: () -> Content) {
        self.content = content()
    }

    /// SwiftUI's single-selection `List(selection:content:)` (ios-oss
    /// Library PaginatingList.swift:48). The list renders as the plain list;
    /// OpenUIKit's list rows have no selection state yet, so the binding is
    /// never written (no row reads as selected) — recorded in
    /// docs/KNOWN_GAPS.md.
    public init<SelectionValue: Hashable>(selection: _OpenBinding<SelectionValue?>?,
                                          @_OpenViewBuilder content: () -> Content) {
        _ = selection
        self.content = content()
    }

    public func _makeOpenUIKitNode() -> _OpenViewNode {
        _OpenViewNode(
            .list(
                rows: _openFlattenGroup(
                    _OpenGraphContext.withStructuralScope(.listContent) {
                        content._makeOpenUIKitNode()
                    }
                )
            )
        )
    }
}

public struct _OpenNavigationLink<Destination: _OpenView, Label: _OpenView>: _OpenView {
    public typealias Body = Never
    public let destination: Destination
    public let label: Label

    public init(
        @_OpenViewBuilder destination: () -> Destination,
        @_OpenViewBuilder label: () -> Label
    ) {
        self.destination = destination()
        self.label = label()
    }

    public init(
        destination: Destination,
        @_OpenViewBuilder label: () -> Label
    ) {
        self.destination = destination
        self.label = label()
    }

    public func _makeOpenUIKitNode() -> _OpenViewNode {
        let labelNode = _OpenGraphContext.withStructuralScope(.navigationLinkLabel) {
            label._makeOpenUIKitNode()
        }
        return _OpenViewNode(
            .navigationLink(
                label: labelNode,
                makeDestinationController: {
                    _OpenUIHostingController(rootView: destination)
                }
            )
        )
    }
}

public typealias List<Content> = _OpenList<Content> where Content: _OpenView
public typealias NavigationLink<Destination, Label> =
    _OpenNavigationLink<Destination, Label>
    where Destination: _OpenView, Label: _OpenView
