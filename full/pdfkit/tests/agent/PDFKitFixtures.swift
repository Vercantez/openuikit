@_spi(PDFKitTesting) import PDFKit
import Foundation

func pdfkitExpect(_ condition: Bool, _ message: String) {
    if !condition {
        fputs("PDFKIT_RUNTIME_FAIL \(message)\n", stderr)
        exit(1)
    }
}

func pdfkitHashProbe<T: Hashable>(_ value: T) {
    _ = value.hashValue
    var hasher = Hasher()
    value.hash(into: &hasher)
    _ = hasher.finalize()
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

func pdfkitHelloStream(lengthAsRef: Bool = false, extraInStream: String = "") -> (Data, Int) {
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

func pdfkitStandardPageTree(
    builder: PDFFixtureBuilder,
    contents: Data,
    inheritBoxes: Bool = false,
    extraPage: String = ""
) {
    builder.add(1, "<< /Title (Runtime Probe) /Producer (OpenUIKit PDFKit) /Author (Depth Pass) >>")
    builder.add(2, "<< /Type /Catalog /Pages 3 0 R >>")
    if inheritBoxes {
        builder.add(
            3,
            "<< /Type /Pages /Kids [4 0 R] /Count 1 /MediaBox [0 0 200 300] /Rotate 90 /Resources << /Font << /F1 << /Type /Font /Subtype /Type1 /BaseFont /Helvetica >> >> /ProcSet [/PDF /Text] >> >>"
        )
        builder.add(4, "<< /Type /Page /Parent 3 0 R /Contents 5 0 R \(extraPage)>>")
    } else {
        builder.add(3, "<< /Type /Pages /Kids [4 0 R] /Count 1 >>")
        builder.add(
            4,
            "<< /Type /Page /Parent 3 0 R /MediaBox [0 0 612 792] /Resources << /Font << /F1 << /Type /Font /Subtype /Type1 /BaseFont /Helvetica >> >> >> /Contents 5 0 R \(extraPage)>>"
        )
    }
    builder.add(5, contents)
}

func pdfkitValidHelloPDF() -> Data {
    let builder = PDFFixtureBuilder()
    let (stream, _) = pdfkitHelloStream()
    pdfkitStandardPageTree(builder: builder, contents: stream)
    return builder.finish(root: 2, info: 1)
}

func pdfkitCommittedFixtureURL(_ name: String) -> URL {
    URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .appendingPathComponent("fixtures")
        .appendingPathComponent(name)
}

func pdfkitRequireCommittedFixture(_ name: String) -> Data {
    let url = pdfkitCommittedFixtureURL(name)
    guard let data = try? Data(contentsOf: url) else {
        pdfkitExpect(false, "missing committed fixture \(name)")
        return Data()
    }
    return data
}

func pdfkitMakeTempRoot() -> URL {
    let url = FileManager.default.temporaryDirectory
        .appendingPathComponent("pdfkit-depth-\(UUID().uuidString)", isDirectory: true)
    try! FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    return url
}
