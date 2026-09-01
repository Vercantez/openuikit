import Foundation
import PDFKit

func expect(_ condition: Bool, _ message: String) {
    if !condition {
        fputs("PDFKIT_RUNTIME_FAIL \(message)\n", stderr)
        exit(1)
    }
}

func samplePDFData() -> Data {
    let body = "BT /F1 12 Tf 72 720 Td (Hello PDFKit) Tj ET"
    let stream = "<< /Length \(body.utf8.count) >>\nstream\n\(body)\nendstream"
    let pdf = """
    %PDF-1.4
    1 0 obj
    << /Title (Runtime Probe) /Producer (OpenUIKit PDFKit) >>
    endobj
    2 0 obj
    << /Type /Catalog /Pages 3 0 R >>
    endobj
    3 0 obj
    << /Type /Pages /Kids [4 0 R] /Count 1 >>
    endobj
    4 0 obj
    << /Type /Page /Parent 3 0 R /MediaBox [0 0 612 792] /Resources << /Font << /F1 << /Type /Font /Subtype /Type1 /BaseFont /Helvetica >> >> >> /Contents 5 0 R >>
    endobj
    5 0 obj
    \(stream)
    endobj
    xref
    0 6
    0000000000 65535 f 
    trailer
    << /Size 6 /Root 2 0 R /Info 1 0 R >>
    startxref
    0
    %%EOF
    """
    return Data(pdf.utf8)
}

let empty = PDFDocument()
expect(empty.pageCount == 0, "empty document has no pages")
expect(empty.allowsCopying, "unlocked document allows copying")
expect(empty.permissionsStatus == .owner, "new document is owner-permissioned")

let page = PDFPage()
expect(page.bounds(for: .mediaBox).width == 612, "default media box width")
page.setBounds(CGRect(x: 0, y: 0, width: 400, height: 500), for: .mediaBox)
empty.insert(page, at: 0)
expect(empty.pageCount == 1, "inserted page")
expect(empty.page(at: 0) === page, "page(at:) identity")
expect(empty.index(for: page) == 0, "index(for:)")
expect(page.label == "1", "page label")

let annotation = PDFAnnotation(
    bounds: CGRect(x: 10, y: 10, width: 80, height: 20),
    forType: .highlight,
    withProperties: nil
)
expect(annotation.markupType == .highlight, "highlight subtype")
expect(PDFAnnotation.name(for: .circle) == "Circle", "line style name")
expect(PDFAnnotation.lineStyle(fromName: "OpenArrow") == .openArrow, "line style parse")
page.addAnnotation(annotation)
expect(page.annotations.count == 1, "annotation attached")
expect(page.annotation(at: CGPoint(x: 12, y: 12)) === annotation, "hit test")

let destination = PDFDestination(page: page, at: CGPoint(x: 0, y: 100))
let goTo = PDFActionGoTo(destination: destination)
expect(goTo.type == "GoTo", "goto type")
let named = PDFActionNamed(name: .nextPage)
expect(named.name == .nextPage, "named action")
let urlAction = PDFActionURL(url: URL(string: "https://example.com")!)
expect(urlAction.url?.host == "example.com", "url action")

let outline = PDFOutline()
outline.label = "Chapter 1"
outline.destination = destination
empty.outlineRoot = outline
expect(empty.outlineRoot?.label == "Chapter 1", "outline root")

empty.documentAttributes = [PDFDocumentAttribute.titleAttribute: "In-memory"]
let serialized = empty.dataRepresentation()
expect(serialized != nil, "serialize in-memory document")
expect(String(data: serialized!, encoding: .isoLatin1)?.hasPrefix("%PDF-") == true, "serialized header")

let sample = PDFDocument(data: samplePDFData())
expect(sample != nil, "parse sample PDF")
expect(sample?.pageCount == 1, "sample page count")
expect(sample?.page(at: 0)?.bounds(for: .mediaBox).width == 612, "sample media box")
expect(sample?.string?.contains("Hello PDFKit") == true, "extracted text")
expect(sample?.documentAttributes?[PDFDocumentAttribute.titleAttribute] as? String == "Runtime Probe", "info title")

let matches = sample?.findString("PDFKit", withOptions: []) ?? []
expect(matches.count == 1, "findString count")
expect(matches.first?.string?.contains("PDFKit") == true, "findString text")

let temp = FileManager.default.temporaryDirectory.appendingPathComponent("pdfkit-runtime.pdf")
expect(sample?.write(to: temp) == true, "write(to:)")
let fromURL = PDFDocument(url: temp)
expect(fromURL?.pageCount == 1, "init(url:) page count")
expect(fromURL?.string?.contains("Hello PDFKit") == true, "url reload text")

let encryptedHint = Data("%PDF-1.4\n1 0 obj\n<< /Type /Catalog /Pages 3 0 R /Encrypt 2 0 R >>\nendobj\n".utf8)
let locked = PDFDocument(data: encryptedHint)
expect(locked?.isEncrypted == true, "encrypt flag")
expect(locked?.isLocked == true, "locked flag")
expect(locked?.unlock(withPassword: "secret") == false, "unlock fail-closed")
expect(locked?.pageCount == 0, "encrypted content withheld")

expect(PDFDisplayBox.cropBox.rawValue == 1, "display box raw value")
expect(PDFAccessPermissions.allowsCommenting.contains(.allowsCommenting), "access permissions")
expect(PDFAreaOfInterest.pageArea.contains(.pageArea), "area of interest")
expect(kPDFDestinationUnspecifiedValue < 0, "unspecified destination sentinel")
expect(PDFAnnotationKey.subtype.rawValue == "/Subtype", "annotation key")
expect(Notification.Name.PDFViewDocumentChanged.rawValue.contains("PDFViewDocumentChanged"), "notification name")

let border = PDFBorder()
border.style = .dashed
border.lineWidth = 2
expect(border.borderKeyValues[PDFBorderKey.style.rawValue] as? Int == PDFBorderStyle.dashed.rawValue, "border keys")

let imagePage = PDFPage(image: UIImage(size: CGSize(width: 200, height: 100)))
expect(imagePage?.bounds(for: .mediaBox).width == 200, "image page media box")

MainActor.assumeIsolated {
    let view = PDFView(frame: CGRect(x: 0, y: 0, width: 300, height: 400))
    view.document = sample
    expect(view.currentPage != nil, "current page after assign")
    expect(view.canGoToNextPage == false, "single page cannot go next")
    expect(view.canZoomIn, "can zoom in")
    view.zoomIn(nil)
    expect(view.scaleFactor > 1, "zoom in changes scale")
    view.goToFirstPage(nil)
    view.perform(named)
    view.perform(goTo)
    view.selectAll(nil)
    expect(view.currentSelection?.string?.contains("Hello") == true, "select all")
    view.clearSelection()
    expect(view.currentSelection == nil, "clear selection")
    let converted = view.convert(CGPoint(x: 10, y: 20), from: view.currentPage!)
    expect(converted.x > 0, "convert from page")
    let thumbs = PDFThumbnailView()
    thumbs.pdfView = view
    expect(thumbs.selectedPages?.count == 1, "thumbnail selection")
    expect(view.visiblePages.count == 1, "visible pages")
    let image = view.currentPage!.thumbnail(of: CGSize(width: 40, height: 50), for: .mediaBox)
    expect(image.size.width == 40 && image.size.height == 50, "placeholder thumbnail size")
}

print("PDFKIT_AGENT_RUNTIME_OK")
