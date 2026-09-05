@_spi(PDFKitTesting) import PDFKit
import Foundation

func testActionsDestinationsAndOutlines() {
    let document = PDFDocument()
    let page = PDFPage()
    let other = PDFPage()
    document.insert(page, at: 0)
    document.insert(other, at: 1)

    let destination = PDFDestination(page: page, at: CGPoint(x: 0, y: 100))
    pdfkitExpect(destination.page === page, "dest page")
    pdfkitExpect(destination.point.y == 100, "dest point")
    destination.zoom = kPDFDestinationUnspecifiedValue
    let destAlias = PDFDestination(page: page, atPoint: CGPoint(x: 0, y: 100))
    pdfkitExpect(destAlias.point.y == 100, "atPoint alias")

    let destA = PDFDestination(page: page, at: CGPoint(x: 0, y: 200))
    let destB = PDFDestination(page: page, at: CGPoint(x: 0, y: 10))
    pdfkitExpect(destA.compare(destB) == .orderedAscending, "higher y first")
    let destC = PDFDestination(page: other, at: .zero)
    pdfkitExpect(destA.compare(destC) == .orderedAscending, "earlier page first")
    let destSame = PDFDestination(page: page, at: CGPoint(x: 0, y: 200))
    pdfkitExpect(destA.compare(destSame) == .orderedSame, "same dest")
    let destX = PDFDestination(page: page, at: CGPoint(x: 5, y: 200))
    pdfkitExpect(destA.compare(destX) == .orderedAscending, "smaller x first")

    let goTo = PDFActionGoTo(destination: destination)
    pdfkitExpect(goTo.type == "GoTo", "goto type")
    pdfkitExpect(goTo.destination === destination, "goto dest")
    let named = PDFActionNamed(name: .nextPage)
    pdfkitExpect(named.name == .nextPage, "named action")
    pdfkitExpect(named.type == "Named", "named type")
    let urlAction = PDFActionURL(url: URL(string: "https://example.com")!)
    pdfkitExpect(urlAction.url?.host == "example.com", "url action")
    pdfkitExpect(urlAction.type == "URI", "uri type")
    let urlAlias = PDFActionURL(URL: URL(string: "https://example.org")!)
    pdfkitExpect(urlAlias.url?.host == "example.org", "URL alias")
    let remote = PDFActionRemoteGoTo(
        pageIndex: 2,
        at: CGPoint(x: 1, y: 2),
        fileURL: URL(fileURLWithPath: "/tmp/other.pdf")
    )
    pdfkitExpect(remote.pageIndex == 2, "remote page")
    pdfkitExpect(remote.point.x == 1, "remote point")
    pdfkitExpect(remote.url.path.hasSuffix("other.pdf"), "remote url")
    pdfkitExpect(remote.type == "GoToR", "remote type")
    let remoteAlias = PDFActionRemoteGoTo(
        pageIndex: 1,
        atPoint: .zero,
        fileURL: URL(fileURLWithPath: "/tmp/x.pdf")
    )
    pdfkitExpect(remoteAlias.pageIndex == 1, "remote alias")
    let reset = PDFActionResetForm()
    reset.fields = ["a"]
    reset.fieldsIncludedAreCleared = false
    pdfkitExpect(reset.type == "ResetForm", "reset form")
    pdfkitExpect(PDFAction().type == "Action", "base action")

    let childOutline = PDFOutline()
    childOutline.label = "Section"
    childOutline.isOpen = true
    childOutline.action = named
    let outline = PDFOutline()
    outline.label = "Chapter 1"
    outline.destination = destination
    outline.insertChild(childOutline, at: 0)
    pdfkitExpect(outline.numberOfChildren == 1, "outline child")
    pdfkitExpect(outline.child(at: 0)?.label == "Section", "child label")
    pdfkitExpect(outline.child(at: 0)?.parent === outline, "parent")
    pdfkitExpect(childOutline.index == 0, "child index")
    pdfkitExpect(outline.child(at: 3) == nil, "missing child")
    document.outlineRoot = outline
    pdfkitExpect(document.outlineRoot?.label == "Chapter 1", "outline root")
    pdfkitExpect(document.outlineRoot?.document === document, "outline document")
    childOutline.removeFromParent()
    pdfkitExpect(outline.numberOfChildren == 0, "removed child")
    outline.insertChild(childOutline, at: 0)

    let helloDoc = PDFDocument(data: pdfkitValidHelloPDF())
    let helloPage = helloDoc?.page(at: 0)
    let helloDest = PDFDestination(page: helloPage!, at: .zero)
    let helloOutline = PDFOutline()
    helloOutline.label = "HelloDest"
    helloOutline.destination = helloDest
    helloDoc?.outlineRoot = helloOutline
    pdfkitExpect(
        helloDoc?.outlineItem(for: helloDoc!.selectionForEntireDocument!)?.label == "HelloDest",
        "outline item for selection"
    )

    let serialized = document.dataRepresentation()
    pdfkitExpect(serialized != nil, "write with outlines")
    let reloaded = PDFDocument(data: serialized!)
    pdfkitExpect(reloaded?.outlineRoot?.numberOfChildren == 1, "outline round trip children")
    pdfkitExpect(reloaded?.outlineRoot?.child(at: 0)?.label == "Section", "outline round trip label")

    let fixture = PDFDocument(data: pdfkitRequireCommittedFixture("outline.pdf"))
    pdfkitExpect(fixture?.outlineRoot?.numberOfChildren == 1, "committed outline children")
    pdfkitExpect(fixture?.outlineRoot?.child(at: 0)?.label == "Hello", "committed outline label")
}
