import Foundation

#if canImport(SwiftUI)
import SwiftUI
#endif

/// SwiftUI editor for an `AssignableDocument`.
///
/// Darwin marks this type `@MainActor @preconcurrency`. The isolated-host
/// `View` lookalike is nonisolated, so Linux omits the actor annotation.
/// `body` is `EmptyView`; Linux never presents markup, Pencil, or PDF UI.
public struct AssignableDocumentView: View {
    public typealias Document = AssignableDocument
    public typealias Body = EmptyView

    private let document: Binding<AssignableDocumentView.Document>
    private let activePartID: MergeablePartsContainerPartID?
    private let hiddenPartIDs: [MergeablePartsContainerPartID]
    private let showsPageThumbnails: Bool
    private let isStructureEditingEnabled: Bool
    private let allowsPencilDrawing: Bool
    private let onMarkupActivation: ((Bool) -> Void)?

    public init(
        document: Binding<AssignableDocumentView.Document>,
        activePartID: MergeablePartsContainerPartID? = nil,
        hiddenPartIDs: [MergeablePartsContainerPartID] = [],
        selectedPageID: Binding<AssignableDocumentView.Document.Page.ID?>? = nil,
        selectedQuestionID: Binding<AssignableDocumentView.Document.Question.ID?>? = nil,
        showsPageThumbnails: Bool = true,
        isStructureEditingEnabled: Bool = true,
        allowsPencilDrawing: Bool = true,
        onMarkupActivation: @escaping (Bool) -> Void
    ) {
        self.document = document
        self.activePartID = activePartID
        self.hiddenPartIDs = hiddenPartIDs
        self.showsPageThumbnails = showsPageThumbnails
        self.isStructureEditingEnabled = isStructureEditingEnabled
        self.allowsPencilDrawing = allowsPencilDrawing
        self.onMarkupActivation = onMarkupActivation
        _ = selectedPageID
        _ = selectedQuestionID
    }

    public init(
        document: Binding<AssignableDocumentView.Document>,
        activePartID: MergeablePartsContainerPartID? = nil,
        hiddenPartIDs: [MergeablePartsContainerPartID] = [],
        selectedPageID: Binding<AssignableDocumentView.Document.Page.ID?>? = nil,
        selectedQuestionID: Binding<AssignableDocumentView.Document.Question.ID?>? = nil,
        showsPageThumbnails: Bool = true,
        isStructureEditingEnabled: Bool = true
    ) {
        self.document = document
        self.activePartID = activePartID
        self.hiddenPartIDs = hiddenPartIDs
        self.showsPageThumbnails = showsPageThumbnails
        self.isStructureEditingEnabled = isStructureEditingEnabled
        self.allowsPencilDrawing = true
        self.onMarkupActivation = nil
        _ = selectedPageID
        _ = selectedQuestionID
    }

    public var body: EmptyView {
        _ = document.wrappedValue
        _ = activePartID
        _ = hiddenPartIDs
        _ = showsPageThumbnails
        _ = isStructureEditingEnabled
        _ = allowsPencilDrawing
        _ = onMarkupActivation
        return EmptyView()
    }
}

/// SwiftUI editor for an `AssignedWorkDocument`.
///
/// Linux `body` is `EmptyView`. Markup activation is retained and never
/// invoked from public APIs.
public struct AssignedWorkDocumentView: View {
    public typealias Document = AssignedWorkDocument
    public typealias Body = EmptyView

    private let document: Binding<AssignedWorkDocumentView.Document>
    private let activePartID: MergeablePartsContainerPartID?
    private let hiddenPartIDs: [MergeablePartsContainerPartID]
    private let showsPageThumbnails: Bool
    private let isStructureEditingEnabled: Bool
    private let onMarkupActivation: ((Bool) -> Void)?

    public init(
        document: Binding<AssignedWorkDocumentView.Document>,
        activePartID: MergeablePartsContainerPartID? = nil,
        hiddenPartIDs: [MergeablePartsContainerPartID],
        selectedPageID: Binding<AssignedWorkDocumentView.Document.Page.ID?>? = nil,
        selectedQuestionID: Binding<AssignableDocument.Question.ID?>? = nil,
        showsPageThumbnails: Bool = true,
        isStructureEditingEnabled: Bool = false,
        onMarkupActivation: @escaping (Bool) -> Void
    ) {
        self.document = document
        self.activePartID = activePartID
        self.hiddenPartIDs = hiddenPartIDs
        self.showsPageThumbnails = showsPageThumbnails
        self.isStructureEditingEnabled = isStructureEditingEnabled
        self.onMarkupActivation = onMarkupActivation
        _ = selectedPageID
        _ = selectedQuestionID
    }

    public init(
        document: Binding<AssignedWorkDocumentView.Document>,
        activePartID: MergeablePartsContainerPartID? = nil,
        hiddenPartIDs: [MergeablePartsContainerPartID],
        selectedPageID: Binding<AssignedWorkDocumentView.Document.Page.ID?>? = nil,
        selectedQuestionID: Binding<AssignableDocument.Question.ID?>? = nil,
        showsPageThumbnails: Bool = true,
        isStructureEditingEnabled: Bool = false
    ) {
        self.document = document
        self.activePartID = activePartID
        self.hiddenPartIDs = hiddenPartIDs
        self.showsPageThumbnails = showsPageThumbnails
        self.isStructureEditingEnabled = isStructureEditingEnabled
        self.onMarkupActivation = nil
        _ = selectedPageID
        _ = selectedQuestionID
    }

    public var body: EmptyView {
        _ = document.wrappedValue
        _ = activePartID
        _ = hiddenPartIDs
        _ = showsPageThumbnails
        _ = isStructureEditingEnabled
        _ = onMarkupActivation
        return EmptyView()
    }
}
