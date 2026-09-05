@_spi(PDFKitTesting) import PDFKit
import Foundation

func testDocumentParseValidAndCommittedFixture() {
    let sampleData = pdfkitValidHelloPDF()
    pdfkitExpect(PDFKitTesting.parseStatus(sampleData) == "ok", "valid xref status")
    let sample = PDFDocument(data: sampleData)
    pdfkitExpect(sample != nil, "parse sample PDF")
    pdfkitExpect(sample?.pageCount == 1, "sample page count")
    pdfkitExpect(sample?.page(at: 0)?.bounds(for: .mediaBox).width == 612, "sample media box")
    pdfkitExpect(sample?.string?.contains("Hello PDFKit") == true, "extracted text")
    pdfkitExpect(sample?.majorVersion == 1 && sample?.minorVersion == 4, "version")

    let fixtureData = pdfkitRequireCommittedFixture("minimal.pdf")
    pdfkitExpect(PDFKitTesting.parseStatus(fixtureData) == "ok", "hand-written minimal.pdf status")
    let fixtureDoc = PDFDocument(data: fixtureData)
    pdfkitExpect(fixtureDoc != nil, "minimal.pdf init")
    pdfkitExpect(fixtureDoc?.pageCount == 1, "minimal.pdf page count")
    pdfkitExpect(fixtureDoc?.string?.contains("Hello PDFKit") == true, "minimal.pdf text")
    pdfkitExpect(fixtureDoc?.dataRepresentation() == fixtureData, "unmutated byte round-trip")
}

func testDocumentParseRejectsNonPDFAndBudgets() {
    pdfkitExpect(PDFKitTesting.parseStatus(Data("not a pdf".utf8)) == "notPDF", "not PDF")
    pdfkitExpect(PDFDocument(data: Data("not a pdf".utf8)) == nil, "init nil")

    var oversized = Data("%PDF-1.4\n".utf8)
    oversized.append(Data(repeating: 0x20, count: 8_000_001))
    pdfkitExpect(PDFKitTesting.parseStatus(oversized) == "budgetExceeded", "byte budget")

    let nestBuilder = PDFFixtureBuilder()
    let nested = String(repeating: "[", count: 40) + String(repeating: "]", count: 40)
    nestBuilder.add(1, nested)
    nestBuilder.add(2, "<< /Type /Catalog /Pages 3 0 R >>")
    nestBuilder.add(3, "<< /Type /Pages /Kids [] /Count 0 >>")
    pdfkitExpect(PDFKitTesting.parseStatus(nestBuilder.finish(root: 2)) == "budgetExceeded", "nesting budget")

    var objectBudget = Data("%PDF-1.4\n".utf8)
    objectBudget.append(Data("xref\n0 2000\ntrailer\n<< /Size 2000 /Root 1 0 R >>\nstartxref\n9\n%%EOF\n".utf8))
    pdfkitExpect(PDFKitTesting.parseStatus(objectBudget) == "budgetExceeded", "object-count budget")

    let cyclicBuilder = PDFFixtureBuilder()
    cyclicBuilder.add(2, "<< /Type /Catalog /Pages 3 0 R >>")
    cyclicBuilder.add(3, "<< /Type /Pages /Kids [3 0 R] /Count 1 >>")
    pdfkitExpect(PDFKitTesting.parseStatus(cyclicBuilder.finish(root: 2)) == "cycleDetected", "cyclic page tree")
}

func testDocumentParseIgnoresObjectsInsideStreams() {
    let fakeBuilder = PDFFixtureBuilder()
    let (fakeStream, _) = pdfkitHelloStream(
        extraInStream: "\n99 0 obj\n<< /Type /Page /Parent 3 0 R /MediaBox [0 0 10 10] >>\nendobj\n"
    )
    pdfkitStandardPageTree(builder: fakeBuilder, contents: fakeStream)
    let fakeData = fakeBuilder.finish(root: 2, info: 1)
    pdfkitExpect(PDFKitTesting.parseStatus(fakeData) == "ok", "stream-embedded obj status")
    let fakeDoc = PDFDocument(data: fakeData)
    pdfkitExpect(fakeDoc?.pageCount == 1, "obj tokens inside streams are not objects")
}

func testDocumentParseForwardIndirectLength() {
    let forwardBuilder = PDFFixtureBuilder()
    let (forwardStream, forwardLength) = pdfkitHelloStream(lengthAsRef: true)
    forwardBuilder.add(1, "<< /Title (Forward Length) >>")
    forwardBuilder.add(2, "<< /Type /Catalog /Pages 3 0 R >>")
    forwardBuilder.add(3, "<< /Type /Pages /Kids [4 0 R] /Count 1 >>")
    forwardBuilder.add(4, "<< /Type /Page /Parent 3 0 R /MediaBox [0 0 612 792] /Contents 5 0 R >>")
    forwardBuilder.add(5, forwardStream)
    forwardBuilder.add(6, "\(forwardLength)")
    let forwardData = forwardBuilder.finish(root: 2, info: 1)
    pdfkitExpect(PDFKitTesting.parseStatus(forwardData) == "ok", "forward length status")
    let forwardDoc = PDFDocument(data: forwardData)
    pdfkitExpect(forwardDoc?.string?.contains("Hello PDFKit") == true, "forward indirect /Length")
}

func testDocumentParseContentFilters() {
    let flateBuilder = PDFFixtureBuilder()
    flateBuilder.add(2, "<< /Type /Catalog /Pages 3 0 R >>")
    flateBuilder.add(3, "<< /Type /Pages /Kids [4 0 R] /Count 1 >>")
    flateBuilder.add(4, "<< /Type /Page /Parent 3 0 R /MediaBox [0 0 612 792] /Contents 5 0 R >>")
    let flatePayload = PDFKitTesting.flate(Data("BT /F1 12 Tf 72 720 Td (Hello PDFKit) Tj ET".utf8))
    var flateStream = Data("<< /Length \(flatePayload.count) /Filter /FlateDecode >>\nstream\n".utf8)
    flateStream.append(flatePayload)
    flateStream.append(Data("\nendstream".utf8))
    flateBuilder.add(5, flateStream)
    let flateData = flateBuilder.finish(root: 2)
    pdfkitExpect(PDFKitTesting.parseStatus(flateData) == "ok", "FlateDecode content stream")
    pdfkitExpect(PDFDocument(data: flateData)?.string?.contains("Hello PDFKit") == true, "FlateDecode extracted text")

    let hexBuilder = PDFFixtureBuilder()
    let hexPayload = PDFKitTesting.asciiHex(Data("BT /F1 12 Tf 72 720 Td (Hello PDFKit) Tj ET".utf8))
    hexBuilder.add(2, "<< /Type /Catalog /Pages 3 0 R >>")
    hexBuilder.add(3, "<< /Type /Pages /Kids [4 0 R] /Count 1 >>")
    hexBuilder.add(4, "<< /Type /Page /Parent 3 0 R /MediaBox [0 0 612 792] /Contents 5 0 R >>")
    var hexStream = Data("<< /Length \(hexPayload.count) /Filter /ASCIIHexDecode >>\nstream\n".utf8)
    hexStream.append(hexPayload)
    hexStream.append(Data("\nendstream".utf8))
    hexBuilder.add(5, hexStream)
    pdfkitExpect(PDFDocument(data: hexBuilder.finish(root: 2))?.string?.contains("Hello PDFKit") == true, "ASCIIHexDecode")

    let a85Builder = PDFFixtureBuilder()
    let a85Payload = PDFKitTesting.ascii85(Data("BT /F1 12 Tf 72 720 Td (Hello PDFKit) Tj ET".utf8))
    a85Builder.add(2, "<< /Type /Catalog /Pages 3 0 R >>")
    a85Builder.add(3, "<< /Type /Pages /Kids [4 0 R] /Count 1 >>")
    a85Builder.add(4, "<< /Type /Page /Parent 3 0 R /MediaBox [0 0 612 792] /Contents 5 0 R >>")
    var a85Stream = Data("<< /Length \(a85Payload.count) /Filter /ASCII85Decode >>\nstream\n".utf8)
    a85Stream.append(a85Payload)
    a85Stream.append(Data("\nendstream".utf8))
    a85Builder.add(5, a85Stream)
    pdfkitExpect(PDFDocument(data: a85Builder.finish(root: 2))?.string?.contains("Hello PDFKit") == true, "ASCII85Decode")

    let rlBuilder = PDFFixtureBuilder()
    let rlPayload = PDFKitTesting.runLength(Data("BT /F1 12 Tf 72 720 Td (Hello PDFKit) Tj ET".utf8))
    rlBuilder.add(2, "<< /Type /Catalog /Pages 3 0 R >>")
    rlBuilder.add(3, "<< /Type /Pages /Kids [4 0 R] /Count 1 >>")
    rlBuilder.add(4, "<< /Type /Page /Parent 3 0 R /MediaBox [0 0 612 792] /Contents 5 0 R >>")
    var rlStream = Data("<< /Length \(rlPayload.count) /Filter /RunLengthDecode >>\nstream\n".utf8)
    rlStream.append(rlPayload)
    rlStream.append(Data("\nendstream".utf8))
    rlBuilder.add(5, rlStream)
    pdfkitExpect(PDFDocument(data: rlBuilder.finish(root: 2))?.string?.contains("Hello PDFKit") == true, "RunLengthDecode")

    let unknownFilter = PDFFixtureBuilder()
    unknownFilter.add(2, "<< /Type /Catalog /Pages 3 0 R >>")
    unknownFilter.add(3, "<< /Type /Pages /Kids [4 0 R] /Count 1 >>")
    unknownFilter.add(4, "<< /Type /Page /Parent 3 0 R /MediaBox [0 0 612 792] /Contents 5 0 R >>")
    unknownFilter.add(5, "<< /Length 3 /Filter /UnknownDecode >>\nstream\nabc\nendstream")
    pdfkitExpect(PDFKitTesting.parseStatus(unknownFilter.finish(root: 2)) == "unsupportedFilter", "unknown filter")
}

func testDocumentParseXrefStream() {
    let content = Data("BT /F1 12 Tf 72 720 Td (Hello PDFKit) Tj ET".utf8)
    let objects: [(Int, Data)] = [
        (1, Data("<< /Type /Catalog /Pages 2 0 R >>".utf8)),
        (2, Data("<< /Type /Pages /Kids [3 0 R] /Count 1 >>".utf8)),
        (3, Data("<< /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] /Resources << /Font << /F1 << /Type /Font /Subtype /Type1 /BaseFont /Helvetica >> >> >> /Contents 4 0 R >>".utf8)),
        (4, {
            var stream = Data("<< /Length \(content.count) >>\nstream\n".utf8)
            stream.append(content)
            stream.append(Data("\nendstream".utf8))
            return stream
        }())
    ]
    var output = Data("%PDF-1.5\n".utf8)
    output.append(contentsOf: [0x25, 0xE2, 0xE3, 0xCF, 0xD3, 0x0A])
    var offsets = Array(repeating: 0, count: 6)
    for (number, body) in objects {
        offsets[number] = output.count
        output.append(Data("\(number) 0 obj\n".utf8))
        output.append(body)
        if body.last != 0x0A { output.append(0x0A) }
        output.append(Data("endobj\n".utf8))
    }
    var streamBytes = Data()
    for number in 1...5 {
        streamBytes.append(1)
        let offset = UInt16(offsets[number])
        streamBytes.append(UInt8(offset >> 8))
        streamBytes.append(UInt8(offset & 0xFF))
        streamBytes.append(0)
    }
    let xrefAt = output.count
    offsets[5] = xrefAt
    let object5Entry = 4 * 4
    streamBytes[object5Entry] = 1
    streamBytes[object5Entry + 1] = UInt8((UInt16(xrefAt) >> 8) & 0xFF)
    streamBytes[object5Entry + 2] = UInt8(UInt16(xrefAt) & 0xFF)
    streamBytes[object5Entry + 3] = 0
    var xrefObj = Data("5 0 obj\n<< /Type /XRef /Size 6 /W [1 2 1] /Index [1 5] /Root 1 0 R /Length \(streamBytes.count) >>\nstream\n".utf8)
    xrefObj.append(streamBytes)
    xrefObj.append(Data("\nendstream\nendobj\n".utf8))
    output.append(xrefObj)
    output.append(Data("startxref\n\(xrefAt)\n%%EOF\n".utf8))
    pdfkitExpect(PDFKitTesting.parseStatus(output) == "ok", "xref stream")
    pdfkitExpect(PDFDocument(data: output)?.string?.contains("Hello PDFKit") == true, "xref stream text")
}
