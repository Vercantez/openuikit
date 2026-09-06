import Foundation
import Assignables

func testSyncMergeSameDocument() {
    var document = assignablesMakeDocument("merge")
    var other = assignablesMakeDocument("merge")
    other.authors = [AnyUserIdentity(StringUserIdentity(value: "author"))]
    let changed = try! document.merge(other: other)
    assignablesExpect(changed, "changed")
    assignablesExpect(document.authors.count == 1, "authors copied")
}

func testSyncMergePartURL() {
    var document = assignablesMakeDocument("url-merge")
    let page = assignablesPageID("0")
    _ = document.appendQuestion(pageID: page, rect: CGRect(x: 0, y: 0, width: 3, height: 3), maxScore: 2)
    let part = try! document.makePart(for: AssignableDocument.PartIDs.questionBoxes)
    guard case .data(let data) = part else {
        assignablesExpect(false, "expected data")
        return
    }
    let url = FileManager.default.temporaryDirectory.appendingPathComponent("assignables-qboxes.json")
    try! data.write(to: url)
    var target = assignablesMakeDocument("url-merge")
    let changed = try! target.merge(partID: AssignableDocument.PartIDs.questionBoxes, partDataURL: url)
    assignablesExpect(changed, "merged")
    assignablesExpect(target.questions.count == 1, "questions")
}

func testSyncMergeMissingURL() {
    var document = assignablesMakeDocument("missing")
    do {
        _ = try document.merge(
            partID: AssignableDocument.PartIDs.base,
            partDataURL: URL(fileURLWithPath: "/tmp/assignables-does-not-exist-\(UUID().uuidString)")
        )
        assignablesExpect(false, "should throw")
    } catch AssignableDocument.Error.invalidURL {
        assignablesExpect(true, "invalidURL")
    } catch {
        assignablesExpect(false, "wrong \(error)")
    }
}

func testWorkSyncMerge() {
    var work = try! assignablesMakeDocument("mw").makeAssignedWorkDocument(id: "mw")
    var other = try! assignablesMakeDocument("mw").makeAssignedWorkDocument(id: "mw")
    other.scorers = [AnyUserIdentity(AnonymousUserIdentity())]
    let changed = try! work.merge(other: other)
    assignablesExpect(changed, "changed")
    assignablesExpect(work.scorers.count == 1, "scorers")
}
