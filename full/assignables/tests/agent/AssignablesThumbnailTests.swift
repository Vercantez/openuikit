import Foundation
import Assignables

func testQuestionThumbnail() {
    let question = AssignableDocument.Question(boxes: [], maxScore: nil)
    let empty = AssignableDocument.Question.Thumbnail(questionID: question.id)
    assignablesExpect(empty.questionID == question.id, "questionID")
    assignablesExpect(empty.data == nil, "nil data")
    let page = assignablesPageID("thumb-0")
    let box = AssignableDocument.QuestionBox(
        id: "thumb-box",
        pageID: page,
        bounds: CGRect(x: 0, y: 0, width: 12, height: 12)
    )
    let payload = AssignableDocument.Question.Thumbnail.Data(
        box: box,
        image: UIImage(),
        pageID: page
    )
    let filled = AssignableDocument.Question.Thumbnail(questionID: question.id, data: payload)
    assignablesExpect(filled.questionID == question.id, "filled questionID")
    assignablesExpect(filled.data == payload, "filled data")
    assignablesExpect(filled == filled, "eq")
    assignablesExpect(filled != empty, "neq")
    _ = filled.hashValue
    var hasher = Hasher()
    filled.hash(into: &hasher)
    _ = hasher.finalize()
    let _: AssignableDocument.Question.Thumbnail.Type = AssignableDocument.Question.Thumbnail.self
}

func testQuestionThumbnailData() {
    let page = assignablesPageID("thumb-1")
    let box = AssignableDocument.QuestionBox(
        id: "thumb-data-box",
        pageID: page,
        bounds: CGRect(x: 1, y: 2, width: 20, height: 10)
    )
    var payload = AssignableDocument.Question.Thumbnail.Data(
        box: box,
        image: UIImage(),
        pageID: page
    )
    assignablesExpect(payload.box == box, "box")
    assignablesExpect(payload.pageID == page, "pageID")
    _ = payload.image
    payload.box = box
    payload.pageID = page
    assignablesExpect(payload.box.id == "thumb-data-box", "box id")
    assignablesExpect(payload == payload, "eq")
    _ = payload.hashValue
    var hasher = Hasher()
    payload.hash(into: &hasher)
    _ = hasher.finalize()
    let _: AssignableDocument.Question.Thumbnail.Data.Type = AssignableDocument.Question.Thumbnail.Data.self
}
