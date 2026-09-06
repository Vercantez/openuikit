import Foundation
import Assignables

func testPageIDCodable() {
    let pageID = assignablesPageID("page-7")
    assignablesExpect(pageID.debugDescription == "page-7", "debug")
    let encoded = try! JSONEncoder().encode(pageID)
    let decoded = try! JSONDecoder().decode(AssignableDocument.Page.ID.self, from: encoded)
    assignablesExpect(decoded == pageID, "round trip")
    assignablesExpect(!(decoded != pageID), "neq")
    _ = pageID.hashValue
    var hasher = Hasher()
    pageID.hash(into: &hasher)
    _ = hasher.finalize()
    let _: AssignableDocument.Page.ID.Element.Type = AssignableDocument.Page.self
}

func testPageProperties() {
    let document = assignablesMakeDocument()
    let page = document.pages[0]
    assignablesExpect(page.size == .zero, "default size")
    assignablesExpect(page.rotation.value == 0, "rotation")
    assignablesExpect(page.debugDescription.isEmpty == false, "debug")
    assignablesExpect(document[page.id]?.id == page.id, "subscript")
    assignablesExpect(page == document.pages[0], "eq")
    _ = page.hashValue
    var hasher = Hasher()
    page.hash(into: &hasher)
    _ = hasher.finalize()
    let _: AssignableDocument.Page.Document.Type = AssignableDocument.self
}

func testDocumentThumbnailType() {
    let document = assignablesMakeDocument()
    let thumbnail = DocumentThumbnail<AssignableDocument>(pageID: document.pages[0].id)
    assignablesExpect(thumbnail.pageID == document.pages[0].id, "page")
}

func testMultiPageDocument() {
    var document = assignablesMakeDocument()
    _ = document.appendQuestion(
        pageID: assignablesPageID("extra"),
        rect: CGRect(x: 0, y: 0, width: 10, height: 10),
        maxScore: 1
    )
    assignablesExpect(document.isMultiPageDocument, "multi")
    assignablesExpect(document.pages.count >= 2, "pages")
}
