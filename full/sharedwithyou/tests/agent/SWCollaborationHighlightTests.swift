import Foundation
@_spi(OpenUIKitHost) import SharedWithYou

func testCollaborationHighlightClass() {
    let highlight = swSampleCollaboration("sheet")
    let asHighlight: SWHighlight = highlight
    swRequire(asHighlight === highlight, "subclass")
}

func testCollaborationIdentifierProperty() {
    let highlight = SharedWithYouHostControl.makeCollaborationHighlight(
        url: swSampleURL("cid"),
        collaborationIdentifier: "collab.cid"
    )
    swRequire(highlight.collaborationIdentifier == "collab.cid", "cid")
}

func testCollaborationTitleProperty() {
    let highlight = SharedWithYouHostControl.makeCollaborationHighlight(
        url: swSampleURL("title"),
        title: "Budget"
    )
    swRequire(highlight.title == "Budget", "title")
}

func testCollaborationCreationDateProperty() {
    let date = Date(timeIntervalSince1970: 1_700_000_000)
    let highlight = SharedWithYouHostControl.makeCollaborationHighlight(
        url: swSampleURL("date"),
        creationDate: date
    )
    swRequire(highlight.creationDate == date, "date")
}

func testCollaborationContentTypeProperty() {
    let type = UTType(identifier: "public.plain-text")
    let highlight = SharedWithYouHostControl.makeCollaborationHighlight(
        url: swSampleURL("uti"),
        contentType: type
    )
    swRequire(highlight.contentType.identifier == "public.plain-text", "uti")
}
