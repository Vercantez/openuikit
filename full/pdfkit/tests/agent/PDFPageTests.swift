@_spi(PDFKitTesting) import PDFKit
import Foundation

func testPageBoundsRotationAndText() {
    let page = PDFPage()
    pdfkitExpect(page.bounds(for: .mediaBox).width == 612, "default media")
    pdfkitExpect(page.characterIndex(at: .zero) == NSNotFound, "empty char index")
    pdfkitExpect(page.characterBounds(at: 0) == .zero, "empty char bounds")
    page.setBounds(CGRect(x: 0, y: 0, width: 400, height: 500), for: .mediaBox)
    page.setBounds(CGRect(x: 10, y: 10, width: 380, height: 480), for: .cropBox)
    page.setBounds(CGRect(x: 5, y: 5, width: 390, height: 490), for: .bleedBox)
    page.setBounds(CGRect(x: 8, y: 8, width: 384, height: 484), for: .trimBox)
    page.setBounds(CGRect(x: 20, y: 20, width: 360, height: 460), for: .artBox)
    page.rotation = 90
    pdfkitExpect(page.bounds(for: .cropBox).width == 380, "crop")
    pdfkitExpect(page.bounds(for: .bleedBox).width == 390, "bleed")
    pdfkitExpect(page.bounds(for: .trimBox).width == 384, "trim")
    pdfkitExpect(page.bounds(for: .artBox).width == 360, "art")
    pdfkitExpect(page.rotation == 90, "rotation")
    page.displaysAnnotations = false
    pdfkitExpect(page.displaysAnnotations == false, "displaysAnnotations")

    let sample = PDFDocument(data: pdfkitValidHelloPDF())
    let samplePage = sample?.page(at: 0)
    pdfkitExpect(samplePage?.string?.contains("Hello PDFKit") == true, "page string")
    pdfkitExpect((samplePage?.numberOfCharacters ?? 0) > 0, "character count")
    _ = samplePage?.attributedString
    _ = samplePage?.dataRepresentation
    let thumb = samplePage?.thumbnail(of: CGSize(width: 32, height: 40), for: .mediaBox)
    pdfkitExpect(thumb?.size.width == 32, "thumbnail width")
    pdfkitExpect(thumb?.size.height == 40, "thumbnail height")

    let fixture = PDFDocument(data: pdfkitRequireCommittedFixture("minimal.pdf"))
    if let page = fixture?.page(at: 0) {
        pdfkitExpect(page.characterBounds(at: 0).width > 0, "character bounds from Tf 12")
        pdfkitExpect(page.bounds(for: .mediaBox).width == 612, "fixture media")
    }

    let imagePage = PDFPage(image: PDFKitImage(size: CGSize(width: 10, height: 10)))
    pdfkitExpect(imagePage != nil, "init(image:)")
    let optionPage = PDFPage(
        image: PDFKitImage(size: CGSize(width: 8, height: 8)),
        options: [
            .mediaBox: CGRect(x: 0, y: 0, width: 50, height: 60),
            .rotation: 180
        ]
    )
    pdfkitExpect(optionPage?.bounds(for: .mediaBox).width == 50, "image media option")
    pdfkitExpect(optionPage?.rotation == 180, "image rotation option")
}

func testPageAnnotationsAndSelection() {
    let document = PDFDocument()
    let page = PDFPage()
    document.insert(page, at: 0)
    let annotation = PDFAnnotation(
        bounds: CGRect(x: 10, y: 10, width: 80, height: 20),
        forType: .highlight,
        withProperties: nil
    )
    page.addAnnotation(annotation)
    pdfkitExpect(page.annotations.count == 1, "annotation attached")
    pdfkitExpect(page.annotation(at: CGPoint(x: 12, y: 12)) === annotation, "hit test")
    pdfkitExpect(annotation.page === page, "annotation.page")
    page.removeAnnotation(annotation)
    pdfkitExpect(page.annotations.isEmpty, "annotation removed")
    page.addAnnotation(annotation)

    let sample = PDFDocument(data: pdfkitValidHelloPDF())
    let samplePage = sample!.page(at: 0)!
    pdfkitExpect(samplePage.selection(for: NSRange(location: 0, length: 5))?.string != nil, "page range")
    pdfkitExpect(samplePage.selectionForWord(at: .zero)?.string != nil, "word selection")
    pdfkitExpect(samplePage.selectionForLine(at: .zero)?.string != nil, "line selection")
    pdfkitExpect(
        samplePage.selection(for: CGRect(x: 0, y: 0, width: 100, height: 100))?.string != nil,
        "rect selection"
    )
    pdfkitExpect(
        samplePage.selection(from: .zero, to: CGPoint(x: 10, y: 10))?.string != nil,
        "point selection"
    )
    pdfkitExpect(
        sample?.selection(
            from: samplePage,
            atCharacterIndex: 0,
            to: samplePage,
            atCharacterIndex: 5
        )?.string != nil,
        "document range selection"
    )
    _ = sample?.selection(from: samplePage, at: .zero, to: samplePage, at: CGPoint(x: 10, y: 10))
    _ = sample?.selection(
        from: samplePage,
        at: .zero,
        to: samplePage,
        at: CGPoint(x: 10, y: 10),
        with: .character
    )
    _ = sample?.selection(
        from: samplePage,
        at: .zero,
        to: samplePage,
        at: CGPoint(x: 10, y: 10),
        with: .word
    )
    _ = sample?.selection(
        from: samplePage,
        at: .zero,
        to: samplePage,
        at: CGPoint(x: 10, y: 10),
        with: .line
    )
    let entire = sample?.selectionForEntireDocument
    pdfkitExpect(entire?.string?.contains("Hello") == true, "entire document")
    entire?.extend(atEnd: 1)
    entire?.extend(atStart: 1)
    entire?.extendForLineBoundaries()
    _ = entire?.numberOfTextRanges(on: samplePage)
    _ = entire?.range(at: 0, on: samplePage)
    _ = entire?.selectionsByLine()
    _ = entire?.bounds(for: samplePage)
    _ = entire?.attributedString
    _ = entire?.pages
    entire?.color = .black
    entire?.draw(for: samplePage, active: true)
    entire?.draw(for: samplePage, with: .mediaBox, active: false)
    let extra = PDFSelection(document: sample!)
    extra.add(entire!)
    extra.add([entire!])
    _ = sample?.outlineItem(for: entire!)
}
