import Foundation
import Assignables

func testAssignableDocumentInit() {
    let document = assignablesMakeDocument("init-doc")
    assignablesExpect(document.id == "init-doc", "id")
    assignablesExpect(document.pages.isEmpty == false, "default page")
    assignablesExpect(document.authors.isEmpty, "authors")
    assignablesExpect(document.questions.isEmpty, "questions")
    assignablesExpect(document.partIDs == AssignableDocument.PartIDs.all, "parts")
    assignablesExpect(document.isPartial, "partial without stored parts")
    assignablesExpect(document.isMultiPageDocument == false, "single page")
    assignablesExpect(document.pagesDebugDescription.isEmpty == false, "debug")
    let _: AssignableDocument.ID = document.id
    let _: any AssignableDocumentElement = document.questions.first ?? AssignableDocument.Question(boxes: [], maxScore: nil)
    _ = document.configuration
}

func testAssignableDocumentEquality() {
    let a = assignablesMakeDocument("same")
    let b = assignablesMakeDocument("same")
    assignablesExpect(a == b, "eq")
    assignablesExpect(!(a != b), "neq")
    let c = assignablesMakeDocument("other")
    assignablesExpect(a != c, "different")
    _ = a.hashValue
    var hasher = Hasher()
    a.hash(into: &hasher)
    _ = hasher.finalize()
}

func testMakeAssignedWorkDocument() {
    let document = assignablesMakeDocument("assignable")
    let work = try! document.makeAssignedWorkDocument(id: "work-id")
    assignablesExpect(work.id == "work-id", "id")
    assignablesExpect(work.assignableDocument.id == "assignable", "parent")
    assignablesExpect(work.assignees.isEmpty, "no assignee")
    let generated = try! document.makeAssignedWorkDocument()
    assignablesExpect(generated.id.isEmpty == false, "generated id")
}

func testAssignableAssign() {
    let document = assignablesMakeDocument("to-assign")
    let identity = StringUserIdentity(value: "student")
    let boxed = try! document.assign(to: AnyUserIdentity(identity))
    assignablesExpect(boxed.assignees.count == 1, "boxed assignee")
    assignablesExpect(boxed.assignees[0].stringRepresentation == "student", "repr")
    let generic = try! document.assign(to: identity)
    assignablesExpect(generic.assignees[0] == AnyUserIdentity(identity), "generic")
}

func testComputeMaxScore() {
    var document = assignablesMakeDocument()
    assignablesExpect(document.computeMaxScore() == nil, "empty uses config max")
    let page = assignablesPageID("0")
    _ = document.appendQuestion(pageID: page, rect: CGRect(x: 0, y: 0, width: 1, height: 1), maxScore: 3)
    _ = document.appendQuestion(pageID: page, rect: CGRect(x: 0, y: 2, width: 1, height: 1), maxScore: 5)
    assignablesExpect(document.computeMaxScore() == 8, "sum")
    _ = document.appendQuestion(pageID: page, rect: CGRect(x: 0, y: 4, width: 1, height: 1), maxScore: nil)
    assignablesExpect(document.computeMaxScore(defaultQuestionMaxScore: 2) == 10, "default fill")
    document.configuration.maxScore = 4
    assignablesExpect(document.computeMaxScore() == 4, "capped")
}

func testMakePartQuestionBoxes() {
    var document = assignablesMakeDocument("parts")
    let page = assignablesPageID("0")
    _ = document.appendQuestion(pageID: page, rect: CGRect(x: 0, y: 0, width: 2, height: 2), maxScore: 1)
    let part = try! document.makePart(for: AssignableDocument.PartIDs.questionBoxes)
    assignablesExpect(part != nil, "made")
    if case .data(let data) = part {
        assignablesExpect(data.isEmpty == false, "json")
    } else {
        assignablesExpect(false, "data case")
    }
    let authors = try! document.makePart(for: AssignableDocument.PartIDs.authors)
    if case .data = authors {
        assignablesExpect(true, "authors")
    } else {
        assignablesExpect(false, "authors data")
    }
    let base = try! document.makePart(for: AssignableDocument.PartIDs.base)
    if case .data(let data) = base {
        assignablesExpect(data.isEmpty, "empty base")
    } else {
        assignablesExpect(false, "base")
    }
}

func testAuthorsProperty() {
    var document = assignablesMakeDocument("authors")
    assignablesExpect(document.authors.isEmpty, "start")
    document.authors = [AnyUserIdentity(StringUserIdentity(value: "teacher"))]
    assignablesExpect(document.authors.count == 1, "set")
    assignablesExpect(document.authors[0].stringRepresentation == "teacher", "repr")
}
