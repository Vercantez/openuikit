import Foundation
import Assignables

func testWorkDocumentInit() {
    let assignable = assignablesMakeDocument("src")
    let work = try! AssignedWorkDocument(
        id: "work",
        assignableDocument: assignable,
        partData: [:]
    )
    assignablesExpect(work.id == "work", "id")
    assignablesExpect(work.assignableDocument.id == "src", "parent")
    assignablesExpect(work.assignees.isEmpty, "assignees")
    assignablesExpect(work.scorers.isEmpty, "scorers")
    assignablesExpect(work.scoreAnnotations.isEmpty, "annotations")
    assignablesExpect(work.partIDs == AssignedWorkDocument.PartIDs.all, "parts")
    assignablesExpect(work.isPartial, "partial")
    assignablesExpect(work.isMultiPageDocument == false, "pages")
    assignablesExpect(work.pagesDebugDescription.isEmpty == false, "debug")
    let _: AssignedWorkDocument.ID = work.id
    _ = work.configuration
}

func testWorkComputeScore() {
    var work = try! assignablesMakeDocument("score-src").makeAssignedWorkDocument(id: "scored")
    assignablesExpect(work.computeScore() == 0, "empty")
    let pageID = assignablesWorkPageID("0")
    work.scoreAnnotations = [
        AssignedWorkDocument.ScoreAnnotation(
            id: "c1", pageID: pageID, location: CGPoint(x: 1, y: 1), kind: .correct
        ),
        AssignedWorkDocument.ScoreAnnotation(
            id: "i1", pageID: pageID, location: CGPoint(x: 2, y: 2), kind: .incorrect
        ),
        AssignedWorkDocument.ScoreAnnotation(
            id: "b1", pageID: pageID, location: CGPoint(x: 3, y: 3), kind: .bonus
        ),
        AssignedWorkDocument.ScoreAnnotation(
            id: "u1", pageID: nil, location: .zero, kind: .unknown
        ),
    ]
    work.assignableDocument.configuration.pointsPerCorrectScoreMark = 2
    work.assignableDocument.configuration.pointsPerIncorrectScoreMark = -1
    work.assignableDocument.configuration.pointsPerBonusScoreMark = 0.5
    assignablesExpect(work.computeScore() == 1.5, "2 - 1 + 0.5")
    work.configuration.manualScore = 99
    assignablesExpect(work.computeScore() == 99, "manual")
}

func testScoreAnnotation() {
    let pageID = assignablesWorkPageID("0")
    var annotation = AssignedWorkDocument.ScoreAnnotation(
        id: "ann",
        pageID: pageID,
        location: CGPoint(x: 4, y: 5),
        kind: .correct
    )
    assignablesExpect(annotation.id == "ann", "id")
    assignablesExpect(annotation.pageID == pageID, "page")
    assignablesExpect(annotation.location.x == 4, "x")
    assignablesExpect(annotation.kind == .correct, "kind")
    annotation.id = "ann-2"
    annotation.kind = .bonus
    annotation.location = CGPoint(x: 0, y: 0)
    annotation.pageID = nil
    assignablesExpect(annotation.id == "ann-2", "set id")
    assignablesExpect(annotation.kind == .bonus, "set kind")
    assignablesExpect(annotation.pageID == nil, "set page")
    _ = annotation.hashValue
    var hasher = Hasher()
    annotation.hash(into: &hasher)
    _ = hasher.finalize()
    let _: AssignedWorkDocument.ScoreAnnotation.Document.Type = AssignedWorkDocument.self
    let _: AssignedWorkDocument.ScoreAnnotation.ID = annotation.id
}

func testWorkAssigneesAndScorers() {
    var work = try! assignablesMakeDocument().makeAssignedWorkDocument(id: "people")
    work.assignees = [AnyUserIdentity(StringUserIdentity(value: "s1"))]
    work.scorers = [AnyUserIdentity(AnonymousUserIdentity())]
    assignablesExpect(work.assignees.count == 1, "assignees")
    assignablesExpect(work.scorers.count == 1, "scorers")
}

func testWorkSubscripts() {
    var work = try! assignablesMakeDocument().makeAssignedWorkDocument(id: "subs")
    let annotation = AssignedWorkDocument.ScoreAnnotation(
        id: "s1",
        pageID: nil,
        location: .zero,
        kind: .correct
    )
    work[annotation.id] = annotation
    assignablesExpect(work[annotation.id]?.kind == .correct, "get")
    work[annotation.id] = nil
    assignablesExpect(work[annotation.id] == nil, "removed")
    let page = work.pages[0]
    assignablesExpect(work[page.id]?.id == page.id, "page get")
}

func testWorkEquality() {
    let assignable = assignablesMakeDocument("eq")
    let a = try! assignable.makeAssignedWorkDocument(id: "w")
    let b = try! assignable.makeAssignedWorkDocument(id: "w")
    assignablesExpect(a == b, "eq")
    assignablesExpect(!(a != b), "neq")
    let c = try! assignable.makeAssignedWorkDocument(id: "other")
    assignablesExpect(a != c, "different")
    _ = a.hashValue
    var hasher = Hasher()
    a.hash(into: &hasher)
    _ = hasher.finalize()
}

func testWorkPages() {
    let work = try! assignablesMakeDocument().makeAssignedWorkDocument(id: "pages")
    assignablesExpect(work.pages.count == 1, "count")
    assignablesExpect(
        work.pages[0].assignableDocumentPageID == work.pages[0].id.assignableDocumentPageID,
        "page id"
    )
    assignablesExpect(work.pages[0].rotation.value == 0, "rotation")
    assignablesExpect(work.pages[0].debugDescription.isEmpty == false, "debug")
    _ = work.pages[0].hashValue
    var hasher = Hasher()
    work.pages[0].hash(into: &hasher)
    _ = hasher.finalize()
    let encoded = try! JSONEncoder().encode(work.pages[0].id)
    let decoded = try! JSONDecoder().decode(AssignedWorkDocument.Page.ID.self, from: encoded)
    assignablesExpect(decoded == work.pages[0].id, "page id codable")
    assignablesExpect(!(decoded != work.pages[0].id), "neq")
    _ = work.pages[0].id.hashValue
    var idHasher = Hasher()
    work.pages[0].id.hash(into: &idHasher)
    _ = idHasher.finalize()
    let _: AssignedWorkDocument.Page.Document.Type = AssignedWorkDocument.self
    let _: AssignedWorkDocument.Page.ID.Element.Type = AssignedWorkDocument.Page.self
}

func testWorkMakePart() {
    var work = try! assignablesMakeDocument().makeAssignedWorkDocument(id: "mp")
    work.scoreAnnotations = [
        AssignedWorkDocument.ScoreAnnotation(id: "a", pageID: nil, location: .zero, kind: .correct)
    ]
    let part = try! work.makePart(for: AssignedWorkDocument.PartIDs.scoreAnnotations)
    if case .data(let data) = part {
        assignablesExpect(data.isEmpty == false, "json")
    } else {
        assignablesExpect(false, "data")
    }
}
