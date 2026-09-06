import Foundation
import Assignables

func testPartIDIdentity() {
    let part = MergeablePartsContainerPartID("base")
    assignablesExpect(part.rawValue == "base", "raw")
    assignablesExpect(part == MergeablePartsContainerPartID("base"), "eq")
    assignablesExpect(part != MergeablePartsContainerPartID("authors"), "neq")
    _ = part.hashValue
    var hasher = Hasher()
    part.hash(into: &hasher)
    _ = hasher.finalize()
}

func testAssignablePartIDs() {
    assignablesExpect(AssignableDocument.PartIDs.base.rawValue == "base", "base")
    assignablesExpect(
        AssignableDocument.PartIDs.instructionMarkup.rawValue == "instructionMarkup",
        "markup"
    )
    assignablesExpect(AssignableDocument.PartIDs.questionBoxes.rawValue == "questionBoxes", "boxes")
    assignablesExpect(AssignableDocument.PartIDs.authors.rawValue == "authors", "authors")
    assignablesExpect(AssignableDocument.PartIDs.all.count == 4, "all count")
    assignablesExpect(AssignableDocument.PartIDs.all.contains(AssignableDocument.PartIDs.base), "contains")
    let _: AssignableDocument.PartIDs.Document.Type = AssignableDocument.self
}

func testAssignedWorkPartIDs() {
    assignablesExpect(
        AssignedWorkDocument.PartIDs.assignableDocumentBase.rawValue == "assignableDocumentBase",
        "base"
    )
    assignablesExpect(
        AssignedWorkDocument.PartIDs.assignableDocumentInstructionMarkup.rawValue
            == "assignableDocumentInstructionMarkup",
        "markup"
    )
    assignablesExpect(
        AssignedWorkDocument.PartIDs.assignableDocumentQuestionBoxes.rawValue
            == "assignableDocumentQuestionBoxes",
        "boxes"
    )
    assignablesExpect(
        AssignedWorkDocument.PartIDs.assignableDocumentAuthors.rawValue == "assignableDocumentAuthors",
        "authors"
    )
    assignablesExpect(AssignedWorkDocument.PartIDs.takerMarkup.rawValue == "takerMarkup", "taker")
    assignablesExpect(AssignedWorkDocument.PartIDs.scorerMarkup.rawValue == "scorerMarkup", "scorer")
    assignablesExpect(
        AssignedWorkDocument.PartIDs.scoreAnnotations.rawValue == "scoreAnnotations",
        "score"
    )
    assignablesExpect(AssignedWorkDocument.PartIDs.assignees.rawValue == "assignees", "assignees")
    assignablesExpect(AssignedWorkDocument.PartIDs.scorers.rawValue == "scorers", "scorers")
    assignablesExpect(AssignedWorkDocument.PartIDs.all.count == 9, "all")
    let _: AssignedWorkDocument.PartIDs.Document.Type = AssignedWorkDocument.self
}
