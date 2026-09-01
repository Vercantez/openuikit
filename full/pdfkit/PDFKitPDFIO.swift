import Foundation

enum PDFKitObject {
    case null
    case bool(Bool)
    case number(Double)
    case string(String)
    case name(String)
    case array([PDFKitObject])
    case dict([String: PDFKitObject])
    case ref(Int, Int)
    case stream([String: PDFKitObject], Data)

    var intValue: Int? {
        if case .number(let value) = self { return Int(value) }
        return nil
    }

    var doubleValue: Double? {
        if case .number(let value) = self { return value }
        return nil
    }

    var stringValue: String? {
        switch self {
        case .string(let value), .name(let value): return value
        default: return nil
        }
    }

    var nameValue: String? {
        if case .name(let value) = self { return value }
        return nil
    }

    var arrayValue: [PDFKitObject]? {
        if case .array(let value) = self { return value }
        return nil
    }

    var dictValue: [String: PDFKitObject]? {
        switch self {
        case .dict(let value): return value
        case .stream(let dict, _): return dict
        default: return nil
        }
    }

    var streamData: Data? {
        if case .stream(_, let data) = self { return data }
        return nil
    }
}

struct PDFKitParsedPage {
    var mediaBox: CGRect
    var cropBox: CGRect?
    var bleedBox: CGRect?
    var trimBox: CGRect?
    var artBox: CGRect?
    var rotation: Int
    var contents: Data
    var text: String
}

struct PDFKitParsedDocument {
    var majorVersion: Int
    var minorVersion: Int
    var encrypted: Bool
    var pages: [PDFKitParsedPage]
    var attributes: [AnyHashable: Any]
    var outlines: [PDFKitParsedOutline]
}

struct PDFKitParsedOutline {
    var title: String
    var pageIndex: Int?
    var children: [PDFKitParsedOutline]
}

enum PDFKitIO {
    static func parse(_ data: Data) -> PDFKitParsedDocument? {
        guard let header = PDFKitParser(data: data).parse() else { return nil }
        return header
    }

    static func write(
        pages: [PDFPage],
        attributes: [AnyHashable: Any]?,
        version: (Int, Int)
    ) -> Data? {
        PDFKitWriter.write(pages: pages, attributes: attributes, version: version)
    }
}

private final class PDFKitParser {
    let bytes: [UInt8]
    var objects: [Int: PDFKitObject] = [:]
    var catalogRef: (Int, Int)?
    var infoRef: (Int, Int)?
    var encrypted = false
    var major = 1
    var minor = 4

    init(data: Data) {
        bytes = [UInt8](data)
    }

    func parse() -> PDFKitParsedDocument? {
        guard bytes.count >= 8 else { return nil }
        guard bytes[0] == 0x25, bytes[1] == 0x50, bytes[2] == 0x44, bytes[3] == 0x46 else {
            return nil
        }
        parseHeaderVersion()
        scanIndirectObjects()
        parseTrailerHints()
        if encrypted {
            return PDFKitParsedDocument(
                majorVersion: major,
                minorVersion: minor,
                encrypted: true,
                pages: [],
                attributes: [:],
                outlines: []
            )
        }
        let catalog = resolve(catalogObject())?.dictValue
        let pagesRoot = catalog.flatMap { $0["Pages"] }.flatMap { resolve($0) }
        let pages = collectPages(from: pagesRoot)
        let attributes = parseInfo()
        let outlines = parseOutlines(from: catalog.flatMap { $0["Outlines"] })
        return PDFKitParsedDocument(
            majorVersion: major,
            minorVersion: minor,
            encrypted: false,
            pages: pages,
            attributes: attributes,
            outlines: outlines
        )
    }

    private func parseHeaderVersion() {
        var index = 5
        var token = ""
        while index < bytes.count {
            let char = bytes[index]
            if char == 0x0A || char == 0x0D || char == 0x20 { break }
            token.append(Character(UnicodeScalar(char)))
            index += 1
        }
        let parts = token.split(separator: ".")
        if parts.count == 2 {
            major = Int(parts[0]) ?? 1
            minor = Int(parts[1]) ?? 4
        }
    }

    private func scanIndirectObjects() {
        var index = 0
        while index < bytes.count {
            let saved = index
            skipWhitespaceAndComments(from: &index)
            if let objectNumber = readNumber(from: &index) {
                skipWhitespaceAndComments(from: &index)
                if readNumber(from: &index) != nil {
                    skipWhitespaceAndComments(from: &index)
                    if matchKeyword("obj", from: &index) {
                        skipWhitespaceAndComments(from: &index)
                        if let value = readObject(from: &index) {
                            skipWhitespaceAndComments(from: &index)
                            _ = matchKeyword("endobj", from: &index)
                            if case .number(let number) = objectNumber {
                                objects[Int(number)] = value
                            }
                            continue
                        }
                    }
                }
            }
            index = saved + 1
        }
    }

    private func parseTrailerHints() {
        let text = String(decoding: bytes, as: UTF8.self)
        if text.contains("/Encrypt") {
            encrypted = true
        }
        if let catalog = firstCatalog() {
            catalogRef = catalog
        }
        if let info = namedRef("/Info", in: text) {
            infoRef = info
        }
    }

    private func firstCatalog() -> (Int, Int)? {
        for (number, object) in objects {
            if object.dictValue?["Type"]?.nameValue == "Catalog" {
                return (number, 0)
            }
        }
        return nil
    }

    private func namedRef(_ name: String, in text: String) -> (Int, Int)? {
        guard let range = text.range(of: "\(name) ") else { return nil }
        let rest = text[range.upperBound...]
        let parts = rest.split(whereSeparator: { $0 == " " || $0 == "\n" || $0 == "\r" })
        guard parts.count >= 2, let objectNumber = Int(parts[0]), let generation = Int(parts[1]) else {
            return nil
        }
        return (objectNumber, generation)
    }

    private func catalogObject() -> PDFKitObject? {
        if let catalogRef, let object = objects[catalogRef.0] { return object }
        return objects.values.first { $0.dictValue?["Type"]?.nameValue == "Catalog" }
    }

    private func collectPages(from object: PDFKitObject?) -> [PDFKitParsedPage] {
        guard let object else { return [] }
        let resolved = resolve(object)
        guard let dict = resolved?.dictValue else { return [] }
        if dict["Type"]?.nameValue == "Pages" {
            var pages: [PDFKitParsedPage] = []
            if let kids = dict["Kids"]?.arrayValue {
                for kid in kids {
                    pages.append(contentsOf: collectPages(from: kid))
                }
            }
            return pages
        }
        if dict["Type"]?.nameValue == "Page" {
            if let page = makePage(from: dict) {
                return [page]
            }
        }
        return []
    }

    private func makePage(from dict: [String: PDFKitObject]) -> PDFKitParsedPage? {
        let media = rect(from: dict["MediaBox"]) ?? CGRect(x: 0, y: 0, width: 612, height: 792)
        let contentsData = contentData(from: dict["Contents"])
        return PDFKitParsedPage(
            mediaBox: media,
            cropBox: rect(from: dict["CropBox"]),
            bleedBox: rect(from: dict["BleedBox"]),
            trimBox: rect(from: dict["TrimBox"]),
            artBox: rect(from: dict["ArtBox"]),
            rotation: dict["Rotate"]?.intValue ?? 0,
            contents: contentsData,
            text: PDFKitTextExtractor.extract(from: contentsData)
        )
    }

    private func contentData(from object: PDFKitObject?) -> Data {
        guard let object else { return Data() }
        let resolved = resolve(object)
        if let data = resolved?.streamData { return data }
        if let array = resolved?.arrayValue {
            var combined = Data()
            for item in array {
                if let data = resolve(item)?.streamData {
                    combined.append(data)
                }
            }
            return combined
        }
        return Data()
    }

    private func rect(from object: PDFKitObject?) -> CGRect? {
        guard let values = resolve(object)?.arrayValue, values.count == 4,
              let x1 = values[0].doubleValue, let y1 = values[1].doubleValue,
              let x2 = values[2].doubleValue, let y2 = values[3].doubleValue
        else { return nil }
        return CGRect(x: x1, y: y1, width: x2 - x1, height: y2 - y1)
    }

    private func parseInfo() -> [AnyHashable: Any] {
        var attributes: [AnyHashable: Any] = [:]
        let info: PDFKitObject?
        if let infoRef {
            info = objects[infoRef.0]
        } else {
            info = objects.values.first { dict in
                let keys = dict.dictValue?.keys
                return keys?.contains("Title") == true || keys?.contains("Producer") == true
            }
        }
        guard let dict = resolve(info)?.dictValue else { return attributes }
        let mapping: [(String, PDFDocumentAttribute)] = [
            ("Title", .titleAttribute),
            ("Author", .authorAttribute),
            ("Subject", .subjectAttribute),
            ("Creator", .creatorAttribute),
            ("Producer", .producerAttribute),
            ("Keywords", .keywordsAttribute)
        ]
        for (key, attribute) in mapping {
            if let value = dict[key]?.stringValue {
                attributes[attribute] = value
            }
        }
        return attributes
    }

    private func parseOutlines(from object: PDFKitObject?) -> [PDFKitParsedOutline] {
        guard let dict = resolve(object)?.dictValue else { return [] }
        guard let first = dict["First"] else { return [] }
        return collectOutlineSiblings(from: first)
    }

    private func collectOutlineSiblings(from object: PDFKitObject?) -> [PDFKitParsedOutline] {
        var items: [PDFKitParsedOutline] = []
        var current = object
        var guardCount = 0
        while let node = current, guardCount < 10_000 {
            guardCount += 1
            if let dict = resolve(node)?.dictValue {
                let title = dict["Title"]?.stringValue ?? ""
                var destPageIndex: Int?
                if let dest = resolve(dict["Dest"]) {
                    destPageIndex = pageIndex(fromDestination: dest)
                }
                let children = dict["First"].map { collectOutlineSiblings(from: $0) } ?? []
                items.append(PDFKitParsedOutline(title: title, pageIndex: destPageIndex, children: children))
                current = dict["Next"]
            } else {
                break
            }
        }
        return items
    }

    private func pageIndex(fromDestination object: PDFKitObject) -> Int? {
        if let array = object.arrayValue, let first = array.first, case .ref(let number, _) = first {
            return pageNumberToIndex(number)
        }
        if case .ref(let number, _) = object {
            return pageNumberToIndex(number)
        }
        return nil
    }

    private func pageNumberToIndex(_ number: Int) -> Int? {
        var index = 0
        if let catalog = catalogObject()?.dictValue?["Pages"] {
            return findPageIndex(object: catalog, target: number, index: &index)
        }
        return nil
    }

    private func findPageIndex(object: PDFKitObject, target: Int, index: inout Int) -> Int? {
        if case .ref(let number, _) = object, number == target { return index }
        guard let dict = resolve(object)?.dictValue else { return nil }
        if dict["Type"]?.nameValue == "Page" {
            if case .ref(let number, _) = object, number == target { return index }
            index += 1
            return nil
        }
        if let kids = dict["Kids"]?.arrayValue {
            for kid in kids {
                if case .ref(let number, _) = kid, number == target { return index }
                if let found = findPageIndex(object: kid, target: target, index: &index) {
                    return found
                }
            }
        }
        return nil
    }

    private func resolve(_ object: PDFKitObject?) -> PDFKitObject? {
        var current = object
        var hops = 0
        while let value = current, hops < 32 {
            hops += 1
            if case .ref(let number, _) = value {
                current = objects[number]
            } else {
                return value
            }
        }
        return current
    }

    private func skipWhitespaceAndComments(from index: inout Int) {
        while index < bytes.count {
            let char = bytes[index]
            if char == 0x25 {
                while index < bytes.count, bytes[index] != 0x0A, bytes[index] != 0x0D {
                    index += 1
                }
                continue
            }
            if char == 0x00 || char == 0x09 || char == 0x0A || char == 0x0C || char == 0x0D || char == 0x20 {
                index += 1
                continue
            }
            break
        }
    }

    private func readObject(from index: inout Int) -> PDFKitObject? {
        skipWhitespaceAndComments(from: &index)
        guard index < bytes.count else { return nil }
        let char = bytes[index]
        switch char {
        case 0x3C:
            if index + 1 < bytes.count, bytes[index + 1] == 0x3C {
                return readDictionaryOrStream(from: &index)
            }
            return readHexString(from: &index)
        case 0x5B:
            return readArray(from: &index)
        case 0x28:
            return readLiteralString(from: &index)
        case 0x2F:
            return readName(from: &index)
        default:
            if matchKeyword("true", from: &index) { return .bool(true) }
            if matchKeyword("false", from: &index) { return .bool(false) }
            if matchKeyword("null", from: &index) { return .null }
            return readNumberOrRef(from: &index)
        }
    }

    private func readDictionaryOrStream(from index: inout Int) -> PDFKitObject? {
        index += 2
        var dict: [String: PDFKitObject] = [:]
        while index < bytes.count {
            skipWhitespaceAndComments(from: &index)
            if index + 1 < bytes.count, bytes[index] == 0x3E, bytes[index + 1] == 0x3E {
                index += 2
                break
            }
            guard let keyObject = readName(from: &index), case .name(let key) = keyObject else {
                return nil
            }
            skipWhitespaceAndComments(from: &index)
            guard let value = readObject(from: &index) else { return nil }
            dict[key] = value
        }
        skipWhitespaceAndComments(from: &index)
        if matchKeyword("stream", from: &index) {
            if index < bytes.count, bytes[index] == 0x0D { index += 1 }
            if index < bytes.count, bytes[index] == 0x0A { index += 1 }
            let length = resolve(dict["Length"])?.intValue ?? 0
            let end = min(bytes.count, index + max(0, length))
            let data = Data(bytes[index..<end])
            index = end
            skipWhitespaceAndComments(from: &index)
            _ = matchKeyword("endstream", from: &index)
            return .stream(dict, data)
        }
        return .dict(dict)
    }

    private func readArray(from index: inout Int) -> PDFKitObject? {
        index += 1
        var items: [PDFKitObject] = []
        while index < bytes.count {
            skipWhitespaceAndComments(from: &index)
            if index < bytes.count, bytes[index] == 0x5D {
                index += 1
                break
            }
            guard let item = readObject(from: &index) else { break }
            items.append(item)
        }
        return .array(items)
    }

    private func readName(from index: inout Int) -> PDFKitObject? {
        guard index < bytes.count, bytes[index] == 0x2F else { return nil }
        index += 1
        var name = ""
        while index < bytes.count {
            let char = bytes[index]
            if isDelimiter(char) || isWhitespace(char) { break }
            if char == 0x23, index + 2 < bytes.count {
                let hex = String(bytes: bytes[(index + 1)..<(index + 3)], encoding: .ascii) ?? ""
                if let value = UInt8(hex, radix: 16) {
                    name.append(Character(UnicodeScalar(value)))
                    index += 3
                    continue
                }
            }
            name.append(Character(UnicodeScalar(char)))
            index += 1
        }
        return .name(name)
    }

    private func readLiteralString(from index: inout Int) -> PDFKitObject? {
        index += 1
        var result = [UInt8]()
        var depth = 1
        while index < bytes.count, depth > 0 {
            let char = bytes[index]
            index += 1
            if char == 0x5C, index < bytes.count {
                let next = bytes[index]
                index += 1
                switch next {
                case 0x6E: result.append(0x0A)
                case 0x72: result.append(0x0D)
                case 0x74: result.append(0x09)
                case 0x62: result.append(0x08)
                case 0x66: result.append(0x0C)
                case 0x28: result.append(0x28)
                case 0x29: result.append(0x29)
                case 0x5C: result.append(0x5C)
                default: result.append(next)
                }
                continue
            }
            if char == 0x28 { depth += 1 }
            if char == 0x29 {
                depth -= 1
                if depth == 0 { break }
            }
            result.append(char)
        }
        return .string(String(bytes: result, encoding: .utf8) ?? String(bytes: result, encoding: .isoLatin1) ?? "")
    }

    private func readHexString(from index: inout Int) -> PDFKitObject? {
        index += 1
        var hex = ""
        while index < bytes.count, bytes[index] != 0x3E {
            let char = bytes[index]
            if !isWhitespace(char) {
                hex.append(Character(UnicodeScalar(char)))
            }
            index += 1
        }
        if index < bytes.count { index += 1 }
        if hex.count % 2 == 1 { hex.append("0") }
        var data = Data()
        var cursor = hex.startIndex
        while cursor < hex.endIndex {
            let next = hex.index(cursor, offsetBy: 2)
            if let value = UInt8(hex[cursor..<next], radix: 16) {
                data.append(value)
            }
            cursor = next
        }
        return .string(String(data: data, encoding: .isoLatin1) ?? "")
    }

    private func readNumberOrRef(from index: inout Int) -> PDFKitObject? {
        guard let first = readNumber(from: &index) else { return nil }
        let afterFirst = index
        skipWhitespaceAndComments(from: &index)
        if let second = readNumber(from: &index) {
            skipWhitespaceAndComments(from: &index)
            if matchKeyword("R", from: &index),
               case .number(let objectNumber) = first,
               case .number(let generation) = second
            {
                return .ref(Int(objectNumber), Int(generation))
            }
            index = afterFirst
            return first
        }
        index = afterFirst
        return first
    }

    private func readNumber(from index: inout Int) -> PDFKitObject? {
        skipWhitespaceAndComments(from: &index)
        let start = index
        if index < bytes.count, bytes[index] == 0x2B || bytes[index] == 0x2D { index += 1 }
        var sawDigit = false
        while index < bytes.count, bytes[index] >= 0x30 && bytes[index] <= 0x39 {
            sawDigit = true
            index += 1
        }
        if index < bytes.count, bytes[index] == 0x2E {
            index += 1
            while index < bytes.count, bytes[index] >= 0x30 && bytes[index] <= 0x39 {
                sawDigit = true
                index += 1
            }
        }
        guard sawDigit else {
            index = start
            return nil
        }
        let token = String(bytes: bytes[start..<index], encoding: .ascii) ?? ""
        guard let value = Double(token) else { return nil }
        return .number(value)
    }

    private func matchKeyword(_ keyword: String, from index: inout Int) -> Bool {
        let saved = index
        let utf8 = Array(keyword.utf8)
        guard index + utf8.count <= bytes.count else { return false }
        for (offset, value) in utf8.enumerated() {
            if bytes[index + offset] != value {
                index = saved
                return false
            }
        }
        index += utf8.count
        if index < bytes.count, !isDelimiter(bytes[index]), !isWhitespace(bytes[index]) {
            index = saved
            return false
        }
        return true
    }

    private func isWhitespace(_ char: UInt8) -> Bool {
        char == 0x00 || char == 0x09 || char == 0x0A || char == 0x0C || char == 0x0D || char == 0x20
    }

    private func isDelimiter(_ char: UInt8) -> Bool {
        char == 0x28 || char == 0x29 || char == 0x3C || char == 0x3E || char == 0x5B || char == 0x5D
            || char == 0x7B || char == 0x7D || char == 0x2F || char == 0x25
    }
}

private enum PDFKitTextExtractor {
    static func extract(from data: Data) -> String {
        guard let text = String(data: data, encoding: .isoLatin1) else { return "" }
        var pieces: [String] = []
        var cursor = text.startIndex
        while cursor < text.endIndex {
            if text[cursor] == "(" {
                if let (string, next) = readPDFString(text, from: cursor) {
                    pieces.append(string)
                    cursor = next
                    continue
                }
            }
            cursor = text.index(after: cursor)
        }
        return pieces.joined(separator: " ")
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func readPDFString(_ text: String, from start: String.Index) -> (String, String.Index)? {
        var index = text.index(after: start)
        var depth = 1
        var result = ""
        while index < text.endIndex, depth > 0 {
            let char = text[index]
            if char == "\\" {
                let next = text.index(after: index)
                if next < text.endIndex {
                    result.append(text[next])
                    index = text.index(after: next)
                    continue
                }
            }
            if char == "(" { depth += 1 }
            if char == ")" {
                depth -= 1
                if depth == 0 {
                    return (result, text.index(after: index))
                }
            }
            if depth > 0, !(char == "(" && depth == 1) {
                result.append(char)
            }
            index = text.index(after: index)
        }
        return nil
    }
}

private enum PDFKitWriter {
    static func write(
        pages: [PDFPage],
        attributes: [AnyHashable: Any]?,
        version: (Int, Int)
    ) -> Data? {
        var objects: [String] = []
        objects.append("") // 1-based
        let infoNumber = 1
        objects.append(infoDictionary(attributes))
        let catalogNumber = 2
        let pagesNumber = 3
        objects.append("<< /Type /Catalog /Pages \(pagesNumber) 0 R >>")

        var pageNumbers: [Int] = []
        var pending: [(Int, String)] = []
        var nextNumber = 4
        for page in pages {
            let contentNumber = nextNumber
            nextNumber += 1
            let pageNumber = nextNumber
            nextNumber += 1
            pageNumbers.append(pageNumber)
            let box = page.bounds(for: .mediaBox)
            let text = page.string ?? ""
            let stream = contentStream(for: text, box: box)
            pending.append((contentNumber, stream))
            pending.append((
                pageNumber,
                "<< /Type /Page /Parent \(pagesNumber) 0 R /MediaBox [\(pdfNumber(box.origin.x)) \(pdfNumber(box.origin.y)) \(pdfNumber(box.origin.x + box.size.width)) \(pdfNumber(box.origin.y + box.size.height))] /Resources << /Font << /F1 << /Type /Font /Subtype /Type1 /BaseFont /Helvetica >> >> >> /Contents \(contentNumber) 0 R >>"
            ))
        }
        while objects.count < nextNumber {
            objects.append("")
        }
        objects[pagesNumber] =
            "<< /Type /Pages /Kids [\(pageNumbers.map { "\($0) 0 R" }.joined(separator: " "))] /Count \(pages.count) >>"
        for (number, body) in pending {
            objects[number] = body
        }

        var output = "%PDF-\(version.0).\(version.1)\n%\u{00E2}\u{00E3}\u{00CF}\u{00D3}\n"
        var offsets = [0]
        for number in 1..<objects.count {
            offsets.append(output.utf8.count)
            if objects[number].hasPrefix("<< /Length") || objects[number].contains("stream\n") {
                output += "\(number) 0 obj\n\(objects[number])\nendobj\n"
            } else {
                output += "\(number) 0 obj\n\(objects[number])\nendobj\n"
            }
        }
        let xref = output.utf8.count
        output += "xref\n0 \(objects.count)\n"
        output += "0000000000 65535 f \n"
        for number in 1..<objects.count {
            output += String(format: "%010d 00000 n \n", offsets[number])
        }
        output += "trailer\n<< /Size \(objects.count) /Root \(catalogNumber) 0 R /Info \(infoNumber) 0 R >>\n"
        output += "startxref\n\(xref)\n%%EOF\n"
        return output.data(using: .isoLatin1)
    }

    private static func infoDictionary(_ attributes: [AnyHashable: Any]?) -> String {
        var parts = ["<<"]
        func add(_ key: String, _ value: Any?) {
            guard let string = value as? String else { return }
            parts.append("/\(key) (\(escape(string)))")
        }
        add("Title", attributes?[PDFDocumentAttribute.titleAttribute])
        add("Author", attributes?[PDFDocumentAttribute.authorAttribute])
        add("Subject", attributes?[PDFDocumentAttribute.subjectAttribute])
        add("Creator", attributes?[PDFDocumentAttribute.creatorAttribute])
        add("Producer", attributes?[PDFDocumentAttribute.producerAttribute] ?? "OpenUIKit PDFKit")
        add("Keywords", attributes?[PDFDocumentAttribute.keywordsAttribute])
        parts.append(">>")
        return parts.joined(separator: " ")
    }

    private static func contentStream(for text: String, box: CGRect) -> String {
        let escaped = escape(text)
        let y = max(24, box.size.height - 72)
        let body = "BT /F1 12 Tf 72 \(pdfNumber(y)) Td (\(escaped)) Tj ET"
        let data = body.data(using: .isoLatin1) ?? Data(body.utf8)
        return "<< /Length \(data.count) >>\nstream\n\(body)\nendstream"
    }

    private static func escape(_ string: String) -> String {
        string
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "(", with: "\\(")
            .replacingOccurrences(of: ")", with: "\\)")
    }

    private static func pdfNumber(_ value: CGFloat) -> String {
        String(format: "%.3f", Double(value))
    }
}
