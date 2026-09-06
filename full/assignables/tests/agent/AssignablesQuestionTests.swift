import Foundation
import Assignables

func testQuestionBox() {
    let page = assignablesPageID("0")
    let box = AssignableDocument.QuestionBox(
        id: "box-1",
        pageID: page,
        bounds: CGRect(x: 1, y: 2, width: 30, height: 40)
    )
    assignablesExpect(box.id == "box-1", "id")
    assignablesExpect(box.pageID == page, "page")
    assignablesExpect(box.bounds.width == 30, "bounds")
    var mutable = box
    mutable.id = "box-2"
    mutable.bounds.origin.x = 5
    assignablesExpect(mutable.id == "box-2", "set id")
    assignablesExpect(mutable.bounds.origin.x == 5, "set bounds")
    assignablesExpect(box != mutable, "neq")
    _ = box.hashValue
    var hasher = Hasher()
    box.hash(into: &hasher)
    _ = hasher.finalize()
    let _: AssignableDocument.QuestionBox.Document.Type = AssignableDocument.self
    let _: AssignableDocument.QuestionBox.ID = box.id
}

func testQuestionInit() {
    let page = assignablesPageID("0")
    let box = AssignableDocument.QuestionBox(
        id: "qbox",
        pageID: page,
        bounds: CGRect(x: 0, y: 0, width: 10, height: 10)
    )
    var question = AssignableDocument.Question(boxes: [box], maxScore: 5)
    assignablesExpect(question.boxes.count == 1, "boxes")
    assignablesExpect(question.maxScore == 5, "score")
    question.maxScore = 8
    question.boxes = [box, box]
    assignablesExpect(question.maxScore == 8, "set score")
    assignablesExpect(question.boxes.count == 2, "set boxes")
    let paged = AssignableDocument.Question(pageID: page, boxes: [box], maxScore: nil)
    assignablesExpect(paged.maxScore == nil, "nil score")
    assignablesExpect(question != paged, "neq")
    _ = question.hashValue
    var hasher = Hasher()
    question.hash(into: &hasher)
    _ = hasher.finalize()
    let _: AssignableDocument.Question.Document.Type = AssignableDocument.self
    let _: AssignableDocument.Question.ID = question.id
}

func testAppendAndRemoveQuestion() {
    var document = assignablesMakeDocument()
    let page = assignablesPageID("0")
    let id = document.appendQuestion(
        pageID: page,
        rect: CGRect(x: 0, y: 0, width: 20, height: 10),
        maxScore: 4
    )
    assignablesExpect(document.questions.count == 1, "appended")
    assignablesExpect(document.questions[0].maxScore == 4, "max")
    assignablesExpect(document.questions(on: page).count == 1, "on page")
    let removed = document.removeQuestion(id)
    assignablesExpect(removed?.id == id, "removed id")
    assignablesExpect(document.questions.isEmpty, "empty")
    assignablesExpect(document.removeQuestion(id) == nil, "second remove")
}

func testQuestionSubscripts() {
    var document = assignablesMakeDocument()
    let page = assignablesPageID("0")
    let questionID = document.appendQuestion(
        pageID: page,
        rect: CGRect(x: 1, y: 1, width: 8, height: 8),
        maxScore: 1
    )
    assignablesExpect(document[questionID]?.maxScore == 1, "question get")
    var updated = document[questionID]!
    updated.maxScore = 9
    document[questionID] = updated
    assignablesExpect(document[questionID]?.maxScore == 9, "question set")
    let boxID = document.questions[0].boxes[0].id
    assignablesExpect(document[boxID]?.id == boxID, "box get")
    var box = document[boxID]!
    box.bounds.size.width = 50
    document[boxID] = box
    assignablesExpect(document[boxID]?.bounds.size.width == 50, "box set")
    document[boxID] = nil
    assignablesExpect(document.questions.isEmpty || document[boxID] == nil, "box removed")
}

func testBasicDocumentElementID() {
    let question = AssignableDocument.Question(boxes: [], maxScore: nil)
    let encoded = try! JSONEncoder().encode(question.id)
    let decoded = try! JSONDecoder().decode(AssignableDocument.Question.ID.self, from: encoded)
    assignablesExpect(decoded == question.id, "round trip")
    assignablesExpect(!(decoded != question.id), "neq")
    _ = question.id.hashValue
    var hasher = Hasher()
    question.id.hash(into: &hasher)
    _ = hasher.finalize()
}
