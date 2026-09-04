@_spi(PDFKitTesting) import PDFKit
import Foundation

func expect(_ condition: Bool, _ message: String) {
    if !condition {
        fputs("PDFKIT_RUNTIME_FAIL \(message)\n", stderr)
        exit(1)
    }
}

final class PDFFixtureBuilder {
    private var items: [(Int, Data)] = []

    func add(_ number: Int, _ body: String) {
        items.append((number, Data(body.utf8)))
    }

    func add(_ number: Int, _ body: Data) {
        items.append((number, body))
    }

    func finish(root: Int, info: Int? = nil, extraTrailer: String = "") -> Data {
        var output = Data("%PDF-1.4\n".utf8)
        output.append(contentsOf: [0x25, 0xE2, 0xE3, 0xCF, 0xD3, 0x0A])
        let maxNumber = items.map(\.0).max() ?? 0
        var offsets = Array(repeating: 0, count: maxNumber + 1)
        var inUse = Array(repeating: false, count: maxNumber + 1)
        for (number, body) in items {
            offsets[number] = output.count
            inUse[number] = true
            output.append(Data("\(number) 0 obj\n".utf8))
            output.append(body)
            if body.last != 0x0A { output.append(0x0A) }
            output.append(Data("endobj\n".utf8))
        }
        let xref = output.count
        var table = "xref\n0 \(maxNumber + 1)\n"
        table += "0000000000 65535 f \n"
        for number in 1...maxNumber {
            if inUse[number] {
                table += String(format: "%010d 00000 n \n", offsets[number])
            } else {
                table += "0000000000 00000 f \n"
            }
        }
        output.append(Data(table.utf8))
        var trailer = "trailer\n<< /Size \(maxNumber + 1) /Root \(root) 0 R"
        if let info {
            trailer += " /Info \(info) 0 R"
        }
        if !extraTrailer.isEmpty {
            trailer += " \(extraTrailer)"
        }
        trailer += " >>\nstartxref\n\(xref)\n%%EOF\n"
        output.append(Data(trailer.utf8))
        return output
    }
}

func helloStream(lengthAsRef: Bool = false, extraInStream: String = "") -> (Data, Int) {
    var body = "BT /F1 12 Tf 72 720 Td (Hello PDFKit) Tj ET"
    body += extraInStream
    let bodyData = Data(body.utf8)
    var stream = Data()
    if lengthAsRef {
        stream.append(Data("<< /Length 6 0 R >>\nstream\n".utf8))
    } else {
        stream.append(Data("<< /Length \(bodyData.count) >>\nstream\n".utf8))
    }
    stream.append(bodyData)
    stream.append(Data("\nendstream".utf8))
    return (stream, bodyData.count)
}

func standardPageTree(builder: PDFFixtureBuilder, contents: Data, inheritBoxes: Bool = false) {
    builder.add(1, "<< /Title (Runtime Probe) /Producer (OpenUIKit PDFKit) >>")
    builder.add(2, "<< /Type /Catalog /Pages 3 0 R >>")
    if inheritBoxes {
        builder.add(
            3,
            "<< /Type /Pages /Kids [4 0 R] /Count 1 /MediaBox [0 0 200 300] /Rotate 90 /Resources << /Font << /F1 << /Type /Font /Subtype /Type1 /BaseFont /Helvetica >> >> /ProcSet [/PDF /Text] >> >>"
        )
        builder.add(4, "<< /Type /Page /Parent 3 0 R /Contents 5 0 R >>")
    } else {
        builder.add(3, "<< /Type /Pages /Kids [4 0 R] /Count 1 >>")
        builder.add(
            4,
            "<< /Type /Page /Parent 3 0 R /MediaBox [0 0 612 792] /Resources << /Font << /F1 << /Type /Font /Subtype /Type1 /BaseFont /Helvetica >> >> >> /Contents 5 0 R >>"
        )
    }
    builder.add(5, contents)
}

func validHelloPDF() -> Data {
    let builder = PDFFixtureBuilder()
    let (stream, _) = helloStream()
    standardPageTree(builder: builder, contents: stream)
    return builder.finish(root: 2, info: 1)
}

let tempRoot = FileManager.default.temporaryDirectory
    .appendingPathComponent("pdfkit-runtime-\(UUID().uuidString)", isDirectory: true)
do {
    try FileManager.default.createDirectory(at: tempRoot, withIntermediateDirectories: true)
} catch {
    expect(false, "create unique temp directory")
}
defer { try? FileManager.default.removeItem(at: tempRoot) }

let empty = PDFDocument()
expect(empty.pageCount == 0, "empty document has no pages")
expect(empty.allowsCopying, "unlocked document allows copying")
expect(empty.accessPermissions.contains(.allowsCommenting), "accessPermissions bits")
expect(empty.allowsPrinting, "unlocked document allows printing")
expect(empty.permissionsStatus == .owner, "new document is owner-permissioned")
expect(empty.majorVersion == 1 && empty.minorVersion == 4, "default version")
expect(empty.unlock(withPassword: "secret") == false, "empty unlock fail-closed")

let page = PDFPage()
expect(page.bounds(for: .mediaBox).width == 612, "default media box width")
expect(page.characterIndex(at: .zero) == NSNotFound, "character index placeholder")
expect(page.characterBounds(at: 0) == .zero, "character bounds placeholder")
page.setBounds(CGRect(x: 0, y: 0, width: 400, height: 500), for: .mediaBox)
page.setBounds(CGRect(x: 10, y: 10, width: 380, height: 480), for: .cropBox)
empty.insert(page, at: 0)
expect(empty.pageCount == 1, "inserted page")
expect(empty.page(at: 0) === page, "page(at:) identity")
expect(empty.index(for: page) == 0, "index(for:)")
expect(page.label == "1", "page label")
expect(page.bounds(for: .cropBox).width == 380, "crop box")

let second = PDFPage()
empty.insert(second, at: 1)
expect(empty.pageCount == 2, "second page")
empty.exchangePage(at: 0, withPageAt: 1)
expect(empty.page(at: 0) === second, "exchange")
empty.removePage(at: 0)
expect(empty.pageCount == 1, "remove page")
expect(empty.page(at: 0) === page, "remaining page")

let annotation = PDFAnnotation(
    bounds: CGRect(x: 10, y: 10, width: 80, height: 20),
    forType: .highlight,
    withProperties: nil
)
expect(annotation.markupType == .highlight, "highlight subtype")
expect(PDFAnnotation.name(for: .circle) == "Circle", "line style name")
expect(PDFAnnotation.lineStyle(fromName: "OpenArrow") == .openArrow, "line style parse")
expect(annotation.setValue("note", forAnnotationKey: .contents), "set contents")
expect(annotation.value(forAnnotationKey: .contents) as? String == "note", "get contents")
expect(annotation.setRect(CGRect(x: 1, y: 2, width: 3, height: 4), forAnnotationKey: .rect), "set rect")
expect(annotation.bounds.width == 3, "rect assigned")
annotation.setBoolean(true, forAnnotationKey: .open)
expect(annotation.isOpen, "open flag")
annotation.removeValue(forAnnotationKey: .contents)
expect(annotation.contents == nil, "contents removed")
page.addAnnotation(annotation)
expect(page.annotations.count == 1, "annotation attached")
expect(page.annotation(at: CGPoint(x: 2, y: 3)) === annotation, "hit test")
page.removeAnnotation(annotation)
expect(page.annotations.isEmpty, "annotation removed")
page.addAnnotation(annotation)

let destination = PDFDestination(page: page, at: CGPoint(x: 0, y: 100))
let goTo = PDFActionGoTo(destination: destination)
expect(goTo.type == "GoTo", "goto type")
let named = PDFActionNamed(name: .nextPage)
expect(named.name == .nextPage, "named action")
expect(PDFActionNamedName(rawValue: 8) == .find, "named find raw value")
let urlAction = PDFActionURL(url: URL(string: "https://example.com")!)
expect(urlAction.url?.host == "example.com", "url action")
let remote = PDFActionRemoteGoTo(
    pageIndex: 2,
    at: CGPoint(x: 1, y: 2),
    fileURL: URL(fileURLWithPath: "/tmp/other.pdf")
)
expect(remote.pageIndex == 2, "remote page")
let reset = PDFActionResetForm()
reset.fields = ["a"]
expect(reset.type == "ResetForm", "reset form")

let childOutline = PDFOutline()
childOutline.label = "Section"
let outline = PDFOutline()
outline.label = "Chapter 1"
outline.destination = destination
outline.insertChild(childOutline, at: 0)
expect(outline.numberOfChildren == 1, "outline child")
expect(outline.child(at: 0)?.label == "Section", "child label")
empty.outlineRoot = outline
expect(empty.outlineRoot?.label == "Chapter 1", "outline root")

empty.documentAttributes = [PDFDocumentAttribute.titleAttribute: "In-memory"]
let serialized = empty.dataRepresentation()
expect(serialized != nil, "serialize in-memory document")
expect(String(data: serialized!, encoding: .isoLatin1)?.hasPrefix("%PDF-") == true, "serialized header")
expect(PDFKitTesting.parseStatus(serialized!) == "ok", "writer xref parses")

let sampleData = validHelloPDF()
expect(PDFKitTesting.parseStatus(sampleData) == "ok", "valid xref status")
let sample = PDFDocument(data: sampleData)
expect(sample != nil, "parse sample PDF")
expect(sample?.pageCount == 1, "sample page count")
expect(sample?.page(at: 0)?.bounds(for: .mediaBox).width == 612, "sample media box")
expect(sample?.string?.contains("Hello PDFKit") == true, "extracted text")
expect(sample?.documentAttributes?[PDFDocumentAttribute.titleAttribute] as? String == "Runtime Probe", "info title")
expect(sample?.page(at: 0)?.numberOfCharacters ?? 0 > 0, "character count")

let matches = sample?.findString("PDFKit", withOptions: []) ?? []
expect(matches.count == 1, "findString count")
expect(matches.first?.string?.contains("PDFKit") == true, "findString text")
let nextFromMatch = sample?.findString("PDFKit", fromSelection: matches.first, withOptions: [])
expect(nextFromMatch == nil, "no later PDFKit match")
let ellMatches = sample?.findString("l", withOptions: []) ?? []
expect(ellMatches.count >= 2, "multiple letter matches")
let laterEll = sample?.findString("l", fromSelection: ellMatches.first, withOptions: [])
expect(laterEll != nil, "find next on same page")
expect(laterEll?.string == "l", "next match text")

sample?.beginFindString("Hello", withOptions: [])
expect(sample?.isFinding == false, "synchronous find finished")
sample?.cancelFindString()

let entire = sample?.selectionForEntireDocument
expect(entire?.string?.contains("Hello") == true, "entire document")
if let firstPage = sample?.page(at: 0) {
    expect(sample?.selection(from: firstPage, atCharacterIndex: 0, to: firstPage, atCharacterIndex: 5)?.string != nil, "range selection")
    expect(firstPage.selection(for: NSRange(location: 0, length: 5))?.string != nil, "page range")
    expect(firstPage.selectionForWord(at: .zero)?.string != nil, "word selection")
    expect(firstPage.selectionForLine(at: .zero)?.string != nil, "line selection")
    _ = firstPage.attributedString
    _ = firstPage.dataRepresentation
}

let tempURL = tempRoot.appendingPathComponent("roundtrip.pdf")
expect(sample?.write(to: tempURL) == true, "write(to:)")
expect(sample?.write(toFile: tempURL.path) == true, "write(toFile:)")
let fromURL = PDFDocument(url: tempURL)
expect(fromURL?.pageCount == 1, "init(url:) page count")
expect(fromURL?.documentURL == tempURL, "documentURL")
expect(fromURL?.string?.contains("Hello PDFKit") == true, "url reload text")
expect(fromURL?.write(to: tempURL, withOptions: [.ownerPasswordOption: "x"]) == false, "password write refused")
expect(fromURL?.dataRepresentation(options: [PDFDocumentWriteOption.userPasswordOption: "x"]) == nil, "password data refused")

let inheritBuilder = PDFFixtureBuilder()
let (inheritStream, _) = helloStream()
standardPageTree(builder: inheritBuilder, contents: inheritStream, inheritBoxes: true)
let inherited = PDFDocument(data: inheritBuilder.finish(root: 2, info: 1))
expect(inherited?.page(at: 0)?.bounds(for: .mediaBox).width == 200, "inherited MediaBox")
expect(inherited?.page(at: 0)?.rotation == 90, "inherited Rotate")
expect(PDFKitTesting.resourceKeyCount(for: inherited!.page(at: 0)!) >= 1, "inherited Resources")
expect(inherited?.string?.contains("Hello PDFKit") == true, "inherited resources still extract")

let forwardBuilder = PDFFixtureBuilder()
let (forwardStream, forwardLength) = helloStream(lengthAsRef: true)
forwardBuilder.add(1, "<< /Title (Forward Length) >>")
forwardBuilder.add(2, "<< /Type /Catalog /Pages 3 0 R >>")
forwardBuilder.add(3, "<< /Type /Pages /Kids [4 0 R] /Count 1 >>")
forwardBuilder.add(
    4,
    "<< /Type /Page /Parent 3 0 R /MediaBox [0 0 612 792] /Contents 5 0 R >>"
)
forwardBuilder.add(5, forwardStream)
forwardBuilder.add(6, "\(forwardLength)")
let forwardData = forwardBuilder.finish(root: 2, info: 1)
expect(PDFKitTesting.parseStatus(forwardData) == "ok", "forward length status")
let forwardDoc = PDFDocument(data: forwardData)
expect(forwardDoc?.string?.contains("Hello PDFKit") == true, "forward indirect /Length")

let fakeBuilder = PDFFixtureBuilder()
let (fakeStream, _) = helloStream(extraInStream: "\n99 0 obj\n<< /Type /Page /Parent 3 0 R /MediaBox [0 0 10 10] >>\nendobj\n")
standardPageTree(builder: fakeBuilder, contents: fakeStream)
let fakeData = fakeBuilder.finish(root: 2, info: 1)
expect(PDFKitTesting.parseStatus(fakeData) == "ok", "stream-embedded obj status")
let fakeDoc = PDFDocument(data: fakeData)
expect(fakeDoc?.pageCount == 1, "obj tokens inside streams are not objects")

let cyclicBuilder = PDFFixtureBuilder()
cyclicBuilder.add(2, "<< /Type /Catalog /Pages 3 0 R >>")
cyclicBuilder.add(3, "<< /Type /Pages /Kids [3 0 R] /Count 1 >>")
expect(PDFKitTesting.parseStatus(cyclicBuilder.finish(root: 2)) == "cycleDetected", "cyclic page tree")

let encryptBuilder = PDFFixtureBuilder()
encryptBuilder.add(1, "<< /Title (Locked) >>")
encryptBuilder.add(2, "<< /Type /Catalog /Pages 3 0 R >>")
encryptBuilder.add(3, "<< /Type /Pages /Kids [4 0 R] /Count 1 >>")
encryptBuilder.add(4, "<< /Type /Page /Parent 3 0 R /MediaBox [0 0 612 792] >>")
encryptBuilder.add(9, "<< /Filter /Standard /V 1 /R 2 /P -4 >>")
let encryptData = encryptBuilder.finish(root: 2, info: 1, extraTrailer: "/Encrypt 9 0 R")
expect(PDFKitTesting.parseStatus(encryptData) == "encrypted", "trailer Encrypt")
let locked = PDFDocument(data: encryptData)
expect(locked?.isEncrypted == true, "encrypt flag")
expect(locked?.isLocked == true, "locked flag")
expect(locked?.unlock(withPassword: "secret") == false, "unlock fail-closed")
expect(locked?.pageCount == 0, "encrypted content withheld")
expect(locked?.dataRepresentation() == nil, "locked document does not write")
expect(locked?.write(to: tempRoot.appendingPathComponent("locked.pdf")) == false, "locked write fails")

let catalogEncrypt = PDFFixtureBuilder()
let (catalogStream, _) = helloStream()
catalogEncrypt.add(1, "<< /Title (Not Encrypted) >>")
catalogEncrypt.add(2, "<< /Type /Catalog /Pages 3 0 R /Encrypt 9 0 R >>")
catalogEncrypt.add(3, "<< /Type /Pages /Kids [4 0 R] /Count 1 >>")
catalogEncrypt.add(
    4,
    "<< /Type /Page /Parent 3 0 R /MediaBox [0 0 612 792] /Contents 5 0 R >>"
)
catalogEncrypt.add(5, catalogStream)
expect(PDFKitTesting.parseStatus(catalogEncrypt.finish(root: 2, info: 1)) == "ok", "Encrypt only in catalog is not trailer encryption")

let filterBuilder = PDFFixtureBuilder()
filterBuilder.add(2, "<< /Type /Catalog /Pages 3 0 R >>")
filterBuilder.add(3, "<< /Type /Pages /Kids [4 0 R] /Count 1 >>")
filterBuilder.add(4, "<< /Type /Page /Parent 3 0 R /MediaBox [0 0 612 792] /Contents 5 0 R >>")
filterBuilder.add(5, "<< /Length 3 /Filter /FlateDecode >>\nstream\nabc\nendstream")
expect(PDFKitTesting.parseStatus(filterBuilder.finish(root: 2)) == "unsupportedFilter", "unsupported filter")

let objStm = PDFFixtureBuilder()
objStm.add(2, "<< /Type /Catalog /Pages 3 0 R >>")
objStm.add(3, "<< /Type /Pages /Kids [] /Count 0 >>")
objStm.add(4, "<< /Type /ObjStm /N 0 /First 0 /Length 0 >>\nstream\n\nendstream")
expect(PDFKitTesting.parseStatus(objStm.finish(root: 2)) == "unsupportedObjectStream", "object stream")

var xrefStream = Data("%PDF-1.5\n".utf8)
xrefStream.append(Data("1 0 obj\n<< /Type /XRef /Size 1 /W [1 1 1] /Length 0 >>\nstream\nendstream\nendobj\nstartxref\n9\n%%EOF\n".utf8))
expect(PDFKitTesting.parseStatus(xrefStream) == "unsupportedXrefStream", "xref stream")

expect(PDFKitTesting.parseStatus(Data("not a pdf".utf8)) == "notPDF", "not PDF")

var oversized = Data("%PDF-1.4\n".utf8)
oversized.append(Data(repeating: 0x20, count: 8_000_001))
expect(PDFKitTesting.parseStatus(oversized) == "budgetExceeded", "byte budget")

let nestBuilder = PDFFixtureBuilder()
let nested = String(repeating: "[", count: 40) + String(repeating: "]", count: 40)
nestBuilder.add(1, nested)
nestBuilder.add(2, "<< /Type /Catalog /Pages 3 0 R >>")
nestBuilder.add(3, "<< /Type /Pages /Kids [] /Count 0 >>")
expect(PDFKitTesting.parseStatus(nestBuilder.finish(root: 2)) == "budgetExceeded", "nesting budget")

var objectBudget = Data("%PDF-1.4\n".utf8)
objectBudget.append(Data("xref\n0 2000\ntrailer\n<< /Size 2000 /Root 1 0 R >>\nstartxref\n9\n%%EOF\n".utf8))
expect(PDFKitTesting.parseStatus(objectBudget) == "budgetExceeded", "object-count budget")

expect(PDFDisplayBox.cropBox.rawValue == 1, "display box raw value")
expect(PDFDisplayBox(rawValue: 0) == .mediaBox, "media box raw init")
expect(PDFAccessPermissions.allowsCommenting.contains(.allowsCommenting), "access permissions")
expect(PDFAreaOfInterest.pageArea.contains(.pageArea), "area of interest")
expect(PDFAreaOfInterest.pageArea.union(.annotationArea).contains(.annotationArea), "area union")
expect(kPDFDestinationUnspecifiedValue < 0, "unspecified destination sentinel")
expect(PDFAnnotationKey.subtype.rawValue == "/Subtype", "annotation key")
expect(PDFAnnotationSubtype.highlight.rawValue == "/Highlight", "highlight subtype raw")
expect(PDFDocumentAttribute.titleAttribute.rawValue == "Title", "title attribute")
expect(Notification.Name.PDFViewDocumentChanged.rawValue.contains("PDFViewDocumentChanged"), "notification name")
expect(PDFInterpolationQuality.none.rawValue == 0, "interpolation")
expect(PDFDisplayMode.singlePageContinuous.rawValue == 1, "display mode")
expect(PDFDisplayDirection.horizontal.rawValue == 1, "display direction")
expect(PDFThumbnailLayoutMode.vertical.rawValue == 0, "thumbnail layout")
expect(PDFWidgetControlType.checkBoxControl.rawValue == 2, "widget control")
expect(PDFMarkupType.redact.rawValue == 3, "markup redact")
expect(PDFBorderStyle.dashed.rawValue == 1, "border dashed")
expect(PDFSelectionGranularity.word.rawValue == 1, "granularity")
expect(PDFTextAnnotationIconType.comment.rawValue == 0, "icon comment")
expect(PDFWidgetCellState.offState.rawValue == 0, "widget off")
expect(PDFAnnotationHighlightingMode.invert.rawValue == "I", "highlighting mode")
expect(PDFAppearanceCharacteristicsKey.caption.rawValue == "/CA", "appearance key")
expect(PDFPage.ImageInitializationOption.mediaBox.rawValue.contains("MediaBox"), "image option")

let border = PDFBorder()
border.style = .dashed
border.lineWidth = 2
border.dashPattern = [2, 1]
expect(border.borderKeyValues[PDFBorderKey.style.rawValue] as? Int == PDFBorderStyle.dashed.rawValue, "border keys")
border.draw(in: CGRect(x: 0, y: 0, width: 10, height: 10))

let appearance = PDFAppearanceCharacteristics()
appearance.caption = "OK"
appearance.rotation = 0
expect(appearance.appearanceCharacteristicsKeyValues[PDFAppearanceCharacteristicsKey.caption.rawValue] as? String == "OK", "appearance caption")

let destA = PDFDestination(page: page, at: CGPoint(x: 0, y: 200))
let destB = PDFDestination(page: page, at: CGPoint(x: 0, y: 10))
expect(destA.compare(destB) == .orderedAscending, "destination compare")

let encryptInStream = PDFFixtureBuilder()
let (encryptInStreamBody, _) = helloStream(extraInStream: "\n/Encrypt")
standardPageTree(builder: encryptInStream, contents: encryptInStreamBody)
expect(
    PDFKitTesting.parseStatus(encryptInStream.finish(root: 2, info: 1)) == "ok",
    "/Encrypt bytes outside the trailer dictionary are not encryption"
)

MainActor.assumeIsolated {
    let annotatedView = PDFView(frame: CGRect(x: 0, y: 0, width: 300, height: 400))
    annotatedView.document = empty
    expect(annotatedView.currentPage === page, "in-memory current page")
    expect(annotatedView.areaOfInterest(for: CGPoint(x: 2, y: 3)).contains(.annotationArea), "annotation area")

    let view = PDFView(frame: CGRect(x: 0, y: 0, width: 300, height: 400))
    view.document = sample
    expect(view.currentPage != nil, "current page after assign")
    expect(view.canGoToNextPage == false, "single page cannot go next")
    expect(view.canZoomIn, "can zoom in")
    view.zoomIn(nil)
    expect(view.scaleFactor > 1, "zoom in changes scale")
    view.zoomOut(nil)
    view.goToFirstPage(nil)
    view.perform(named)
    view.perform(goTo)
    view.perform(urlAction)
    view.perform(remote)
    view.selectAll(nil)
    expect(view.currentSelection?.string?.contains("Hello") == true, "select all")
    view.setCurrentSelection(view.currentSelection, animate: false)
    view.scrollSelectionToVisible(nil)
    view.copy(nil)
    view.clearSelection()
    expect(view.currentSelection == nil, "clear selection")
    let converted = view.convert(CGPoint(x: 10, y: 20), from: view.currentPage!)
    expect(converted.x > 0, "convert from page")
    let convertedRect = view.convert(CGRect(x: 0, y: 0, width: 10, height: 10), from: view.currentPage!)
    expect(convertedRect.width > 0, "convert rect")
    expect(view.visiblePages.count == 1, "visible pages")
    expect(view.rowSize(for: view.currentPage!).width > 0, "row size")
    view.usePageViewController(true, withViewOptions: nil)
    expect(view.isUsingPageViewController, "page view controller flag")
    view.displayMode = .singlePageContinuous
    expect(view.visiblePages.count == 1, "continuous visible")
    view.annotationsChanged(on: view.currentPage!)
    let thumbs = PDFThumbnailView(frame: .zero)
    thumbs.pdfView = view
    thumbs.layoutMode = .vertical
    thumbs.thumbnailSize = CGSize(width: 40, height: 50)
    expect(thumbs.selectedPages?.count == 1, "thumbnail selection")
    expect(view.scaleFactorForSizeToFit > 0, "size to fit")
    view.layoutDocumentView()
}

print("PDFKIT_AGENT_RUNTIME_OK")
