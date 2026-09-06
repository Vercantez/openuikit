import Foundation
import Assignables

func testAssignableDocumentViewBody() {
    var document = assignablesMakeDocument("view")
    let view = AssignableDocumentView(document: Binding(get: { document }, set: { document = $0 }))
    let _: AssignableDocumentView.Document = document
    let empty: AssignableDocumentView.Body = EmptyView()
    _ = empty
    _ = view.body
    assignablesExpect(true, "constructed")
}

func testAssignableDocumentViewMarkupInit() {
    var document = assignablesMakeDocument("view-markup")
    var activated = false
    let view = AssignableDocumentView(
        document: Binding(get: { document }, set: { document = $0 }),
        activePartID: AssignableDocument.PartIDs.base,
        hiddenPartIDs: [AssignableDocument.PartIDs.instructionMarkup],
        selectedPageID: nil,
        selectedQuestionID: nil,
        showsPageThumbnails: false,
        isStructureEditingEnabled: false,
        allowsPencilDrawing: false,
        onMarkupActivation: { activated = $0 }
    )
    _ = view.body
    assignablesExpect(activated == false, "not invoked")
}

func testAssignedWorkDocumentViewBody() {
    var work = try! assignablesMakeDocument("work-view").makeAssignedWorkDocument(id: "wv")
    let view = AssignedWorkDocumentView(
        document: Binding(get: { work }, set: { work = $0 }),
        hiddenPartIDs: []
    )
    let _: AssignedWorkDocumentView.Document = work
    let empty: AssignedWorkDocumentView.Body = EmptyView()
    _ = empty
    _ = view.body
    assignablesExpect(true, "constructed")
}

func testAssignedWorkDocumentViewMarkupInit() {
    var work = try! assignablesMakeDocument("work-markup").makeAssignedWorkDocument(id: "wm")
    var activated = false
    let view = AssignedWorkDocumentView(
        document: Binding(get: { work }, set: { work = $0 }),
        activePartID: AssignedWorkDocument.PartIDs.takerMarkup,
        hiddenPartIDs: [AssignedWorkDocument.PartIDs.scorerMarkup],
        selectedPageID: nil,
        selectedQuestionID: nil,
        showsPageThumbnails: false,
        isStructureEditingEnabled: true,
        onMarkupActivation: { activated = $0 }
    )
    _ = view.body
    assignablesExpect(activated == false, "not invoked")
}
