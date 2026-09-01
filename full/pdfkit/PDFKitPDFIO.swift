import Foundation

enum PDFKitParseFailure: String, Error, Equatable {
    case notPDF
    case invalidXref
    case unsupportedXrefStream
    case unsupportedObjectStream
    case unsupportedFilter
    case unresolvedLength
    case budgetExceeded
    case cycleDetected
    case truncated
}

enum PDFKitParseOutcome {
    case success(PDFKitParsedDocument)
    case failure(PDFKitParseFailure)
}

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
    var resourceKeyCount: Int
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
        switch parseDetailed(data) {
        case .success(let document):
            return document
        case .failure:
            return nil
        }
    }

    static func parseDetailed(_ data: Data) -> PDFKitParseOutcome {
        PDFKitParser(data: data).parse()
    }

    static func write(
        pages: [PDFPage],
        attributes: [AnyHashable: Any]?,
        version: (Int, Int)
    ) -> Data? {
        PDFKitWriter.write(pages: pages, attributes: attributes, version: version)
    }
}

private struct PDFObjectID: Hashable {
    let number: Int
    let generation: Int
}

private struct PDFXRefEntry {
    let number: Int
    let generation: Int
    let offset: Int
    let inUse: Bool
}

private struct PDFPendingStream {
    let id: PDFObjectID
    let dict: [String: PDFKitObject]
    let dataOffset: Int
}

private enum PDFKitLimits {
    static let maxBytes = 8_000_000
    static let maxObjects = 1_024
    static let maxNesting = 32
    static let maxResolveHops = 64
    static let maxPages = 256
    static let maxPageTreeNodes = 512
    static let maxOutlineNodes = 256
}

private final class PDFKitParser {
    let bytes: [UInt8]
    var index = 0
    var objects: [PDFObjectID: PDFKitObject] = [:]
    var objectsByNumber: [Int: PDFObjectID] = [:]
    var trailer: [String: PDFKitObject] = [:]
    var major = 1
    var minor = 4
    var nesting = 0
    var pageTreeNodes = 0
    var outlineNodes = 0

    init(data: Data) {
        bytes = [UInt8](data)
    }

    func parse() -> PDFKitParseOutcome {
        guard bytes.count >= 8 else { return .failure(.notPDF) }
        guard bytes.count <= PDFKitLimits.maxBytes else { return .failure(.budgetExceeded) }
        guard bytes[0] == 0x25, bytes[1] == 0x50, bytes[2] == 0x44, bytes[3] == 0x46 else {
            return .failure(.notPDF)
        }
        parseHeaderVersion()
        do {
            let entries = try parseXRef()
            if trailer["Encrypt"] != nil {
                return .success(
                    PDFKitParsedDocument(
                        majorVersion: major,
                        minorVersion: minor,
                        encrypted: true,
                        pages: [],
                        attributes: [:],
                        outlines: []
                    )
                )
            }
            var pending: [PDFPendingStream] = []
            for entry in entries where entry.inUse {
                if objects.count >= PDFKitLimits.maxObjects {
                    return .failure(.budgetExceeded)
                }
                switch try parseIndirectObject(entry) {
                case .value(let id, let value):
                    try register(id, value)
                case .pendingStream(let stream):
                    pending.append(stream)
                }
            }
            for stream in pending {
                try finishStream(stream)
            }
            let catalog = try requiredDict(resolve(trailer["Root"]))
            let pagesRoot = catalog["Pages"]
            let pages = try collectPages(from: pagesRoot, inherited: InheritedPageState(), trail: [])
            let attributes = parseInfo()
            let outlines = try parseOutlines(from: catalog["Outlines"])
            return .success(
                PDFKitParsedDocument(
                    majorVersion: major,
                    minorVersion: minor,
                    encrypted: false,
                    pages: pages,
                    attributes: attributes,
                    outlines: outlines
                )
            )
        } catch let failure as PDFKitParseFailure {
            return .failure(failure)
        } catch {
            return .failure(.invalidXref)
        }
    }

    private enum ParsedIndirect {
        case value(PDFObjectID, PDFKitObject)
        case pendingStream(PDFPendingStream)
    }

    private struct InheritedPageState {
        var mediaBox: CGRect?
        var cropBox: CGRect?
        var bleedBox: CGRect?
        var trimBox: CGRect?
        var artBox: CGRect?
        var rotation: Int = 0
        var resources: PDFKitObject?
    }

    private func parseHeaderVersion() {
        var cursor = 5
        var token = ""
        while cursor < bytes.count {
            let char = bytes[cursor]
            if char == 0x0A || char == 0x0D || char == 0x20 { break }
            token.append(Character(UnicodeScalar(char)))
            cursor += 1
        }
        let parts = token.split(separator: ".")
        if parts.count == 2 {
            major = Int(parts[0]) ?? 1
            minor = Int(parts[1]) ?? 4
        }
    }

    private func parseXRef() throws -> [PDFXRefEntry] {
        guard let start = startXRefOffset() else { throw PDFKitParseFailure.invalidXref }
        guard start >= 0, start < bytes.count else { throw PDFKitParseFailure.invalidXref }
        index = start
        skipWhitespaceAndComments()
        if matchKeyword("xref") {
            let entries = try parseClassicXRef()
            skipWhitespaceAndComments()
            guard matchKeyword("trailer") else { throw PDFKitParseFailure.invalidXref }
            skipWhitespaceAndComments()
            guard case .dict(let dict) = try readObject() else { throw PDFKitParseFailure.invalidXref }
            trailer = dict
            if let type = dict["Type"]?.nameValue, type == "XRef" {
                throw PDFKitParseFailure.unsupportedXrefStream
            }
            return entries
        }
        throw PDFKitParseFailure.unsupportedXrefStream
    }

    private func startXRefOffset() -> Int? {
        let window = min(bytes.count, 2048)
        let start = bytes.count - window
        var cursor = bytes.count - 1
        while cursor >= start {
            if matchAt(cursor, "startxref") {
                var scan = cursor + 9
                while scan < bytes.count, isWhitespace(bytes[scan]) { scan += 1 }
                let numberStart = scan
                while scan < bytes.count, bytes[scan] >= 0x30 && bytes[scan] <= 0x39 {
                    scan += 1
                }
                guard scan > numberStart else { return nil }
                return Int(String(bytes: bytes[numberStart..<scan], encoding: .ascii) ?? "")
            }
            cursor -= 1
        }
        return nil
    }

    private func matchAt(_ position: Int, _ keyword: String) -> Bool {
        let utf8 = Array(keyword.utf8)
        guard position + utf8.count <= bytes.count else { return false }
        for (offset, value) in utf8.enumerated() {
            if bytes[position + offset] != value { return false }
        }
        return true
    }

    private func parseClassicXRef() throws -> [PDFXRefEntry] {
        var entries: [PDFXRefEntry] = []
        skipWhitespaceAndComments()
        while index < bytes.count {
            skipWhitespaceAndComments()
            if matchKeyword("trailer") {
                rewindKeyword("trailer")
                break
            }
            guard let first = readRawInt() else { break }
            skipWhitespaceAndComments()
            guard let count = readRawInt() else { throw PDFKitParseFailure.invalidXref }
            if entries.count + count > PDFKitLimits.maxObjects {
                throw PDFKitParseFailure.budgetExceeded
            }
            for objectNumber in first..<(first + count) {
                skipWhitespaceAndComments()
                guard let offset = readPaddedInt(digits: 10) else { throw PDFKitParseFailure.invalidXref }
                skipOneSpace()
                guard let generation = readPaddedInt(digits: 5) else { throw PDFKitParseFailure.invalidXref }
                skipOneSpace()
                guard index < bytes.count else { throw PDFKitParseFailure.truncated }
                let flag = bytes[index]
                index += 1
                let inUse = flag == 0x6E
                if flag != 0x6E && flag != 0x66 { throw PDFKitParseFailure.invalidXref }
                if index < bytes.count, bytes[index] == 0x20 { index += 1 }
                if index < bytes.count, bytes[index] == 0x0D { index += 1 }
                if index < bytes.count, bytes[index] == 0x0A { index += 1 }
                entries.append(
                    PDFXRefEntry(number: objectNumber, generation: generation, offset: offset, inUse: inUse)
                )
            }
        }
        if entries.isEmpty { throw PDFKitParseFailure.invalidXref }
        return entries
    }

    private func parseIndirectObject(_ entry: PDFXRefEntry) throws -> ParsedIndirect {
        guard entry.offset >= 0, entry.offset < bytes.count else { throw PDFKitParseFailure.invalidXref }
        index = entry.offset
        skipWhitespaceAndComments()
        guard let number = readRawInt(), number == entry.number else { throw PDFKitParseFailure.invalidXref }
        skipWhitespaceAndComments()
        guard let generation = readRawInt(), generation == entry.generation else {
            throw PDFKitParseFailure.invalidXref
        }
        skipWhitespaceAndComments()
        guard matchKeyword("obj") else { throw PDFKitParseFailure.invalidXref }
        skipWhitespaceAndComments()
        let id = PDFObjectID(number: entry.number, generation: entry.generation)
        let value = try readObject()
        skipWhitespaceAndComments()
        if matchKeyword("stream") {
            if let type = value.dictValue?["Type"]?.nameValue, type == "XRef" {
                throw PDFKitParseFailure.unsupportedXrefStream
            }
            if let type = value.dictValue?["Type"]?.nameValue, type == "ObjStm" {
                throw PDFKitParseFailure.unsupportedObjectStream
            }
            try rejectUnsupportedFilter(value.dictValue ?? [:])
            if index < bytes.count, bytes[index] == 0x0D { index += 1 }
            if index < bytes.count, bytes[index] == 0x0A { index += 1 }
            let dataOffset = index
            guard case .dict(let dict) = value else { throw PDFKitParseFailure.truncated }
            if let length = dict["Length"]?.intValue {
                return .value(id, try readStream(dict: dict, dataOffset: dataOffset, length: length))
            }
            if case .ref = dict["Length"] {
                return .pendingStream(PDFPendingStream(id: id, dict: dict, dataOffset: dataOffset))
            }
            throw PDFKitParseFailure.unresolvedLength
        }
        return .value(id, value)
    }

    private func finishStream(_ pending: PDFPendingStream) throws {
        let lengthObject = try resolve(pending.dict["Length"])
        guard let length = lengthObject?.intValue, length >= 0 else {
            throw PDFKitParseFailure.unresolvedLength
        }
        let stream = try readStream(dict: pending.dict, dataOffset: pending.dataOffset, length: length)
        try register(pending.id, stream)
    }

    private func readStream(dict: [String: PDFKitObject], dataOffset: Int, length: Int) throws -> PDFKitObject {
        let end = dataOffset + length
        guard end <= bytes.count else { throw PDFKitParseFailure.truncated }
        let data = Data(bytes[dataOffset..<end])
        return .stream(dict, data)
    }

    private func register(_ id: PDFObjectID, _ value: PDFKitObject) throws {
        if let type = value.dictValue?["Type"]?.nameValue, type == "ObjStm" {
            throw PDFKitParseFailure.unsupportedObjectStream
        }
        if let type = value.dictValue?["Type"]?.nameValue, type == "XRef" {
            throw PDFKitParseFailure.unsupportedXrefStream
        }
        try rejectUnsupportedFilter(value.dictValue ?? [:])
        objects[id] = value
        objectsByNumber[id.number] = id
    }

    private func rejectUnsupportedFilter(_ dict: [String: PDFKitObject]) throws {
        let filter = dict["Filter"] ?? dict["F"]
        guard let filter else { return }
        if let name = filter.nameValue {
            if name != "Identity" { throw PDFKitParseFailure.unsupportedFilter }
            return
        }
        if let array = filter.arrayValue {
            if array.contains(where: { $0.nameValue != "Identity" }) {
                throw PDFKitParseFailure.unsupportedFilter
            }
            return
        }
        throw PDFKitParseFailure.unsupportedFilter
    }

    private func collectPages(
        from object: PDFKitObject?,
        inherited: InheritedPageState,
        trail: Set<PDFObjectID>
    ) throws -> [PDFKitParsedPage] {
        pageTreeNodes += 1
        if pageTreeNodes > PDFKitLimits.maxPageTreeNodes { throw PDFKitParseFailure.budgetExceeded }
        guard let object else { return [] }
        var nextTrail = trail
        if case .ref(let number, let generation) = object {
            let id = PDFObjectID(number: number, generation: generation)
            if trail.contains(id) { throw PDFKitParseFailure.cycleDetected }
            nextTrail.insert(id)
        }
        let resolved = try resolve(object)
        guard let dict = resolved?.dictValue else { return [] }
        var state = inherited
        if let media = rect(from: dict["MediaBox"]) { state.mediaBox = media }
        if let crop = rect(from: dict["CropBox"]) { state.cropBox = crop }
        if let bleed = rect(from: dict["BleedBox"]) { state.bleedBox = bleed }
        if let trim = rect(from: dict["TrimBox"]) { state.trimBox = trim }
        if let art = rect(from: dict["ArtBox"]) { state.artBox = art }
        if let rotate = dict["Rotate"]?.intValue { state.rotation = rotate }
        if dict["Resources"] != nil { state.resources = dict["Resources"] }
        if dict["Type"]?.nameValue == "Pages" {
            var pages: [PDFKitParsedPage] = []
            if let kids = dict["Kids"]?.arrayValue {
                for kid in kids {
                    pages.append(contentsOf: try collectPages(from: kid, inherited: state, trail: nextTrail))
                    if pages.count > PDFKitLimits.maxPages { throw PDFKitParseFailure.budgetExceeded }
                }
            }
            return pages
        }
        if dict["Type"]?.nameValue == "Page" {
            return [try makePage(from: dict, inherited: state)]
        }
        return []
    }

    private func makePage(
        from dict: [String: PDFKitObject],
        inherited: InheritedPageState
    ) throws -> PDFKitParsedPage {
        let media = rect(from: dict["MediaBox"])
            ?? inherited.mediaBox
            ?? CGRect(x: 0, y: 0, width: 612, height: 792)
        let contentsData = try contentData(from: dict["Contents"])
        let resources = dict["Resources"] ?? inherited.resources
        return PDFKitParsedPage(
            mediaBox: media,
            cropBox: rect(from: dict["CropBox"]) ?? inherited.cropBox,
            bleedBox: rect(from: dict["BleedBox"]) ?? inherited.bleedBox,
            trimBox: rect(from: dict["TrimBox"]) ?? inherited.trimBox,
            artBox: rect(from: dict["ArtBox"]) ?? inherited.artBox,
            rotation: dict["Rotate"]?.intValue ?? inherited.rotation,
            contents: contentsData,
            text: PDFKitTextExtractor.extract(from: contentsData),
            resourceKeyCount: resourceKeyCount(from: resources)
        )
    }

    private func resourceKeyCount(from object: PDFKitObject?) -> Int {
        guard let resolved = try? resolve(object) else { return 0 }
        return resolved.dictValue?.count ?? 0
    }

    private func contentData(from object: PDFKitObject?) throws -> Data {
        guard let object else { return Data() }
        let resolved = try resolve(object)
        if let data = resolved?.streamData { return data }
        if let array = resolved?.arrayValue {
            var combined = Data()
            for item in array {
                if let data = try resolve(item)?.streamData {
                    combined.append(data)
                }
            }
            return combined
        }
        return Data()
    }

    private func rect(from object: PDFKitObject?) -> CGRect? {
        guard let resolved = try? resolve(object), let values = resolved.arrayValue, values.count == 4,
              let x1 = values[0].doubleValue, let y1 = values[1].doubleValue,
              let x2 = values[2].doubleValue, let y2 = values[3].doubleValue
        else { return nil }
        return CGRect(
            x: CGFloat(x1),
            y: CGFloat(y1),
            width: CGFloat(x2 - x1),
            height: CGFloat(y2 - y1)
        )
    }

    private func parseInfo() -> [AnyHashable: Any] {
        var attributes: [AnyHashable: Any] = [:]
        guard let dict = try? resolve(trailer["Info"])?.dictValue else { return attributes }
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

    private func parseOutlines(from object: PDFKitObject?) throws -> [PDFKitParsedOutline] {
        guard let dict = try resolve(object)?.dictValue else { return [] }
        guard let first = dict["First"] else { return [] }
        return try collectOutlineSiblings(from: first, trail: [])
    }

    private func collectOutlineSiblings(
        from object: PDFKitObject?,
        trail: Set<PDFObjectID>
    ) throws -> [PDFKitParsedOutline] {
        var items: [PDFKitParsedOutline] = []
        var current = object
        var seen = trail
        while let node = current {
            outlineNodes += 1
            if outlineNodes > PDFKitLimits.maxOutlineNodes { throw PDFKitParseFailure.budgetExceeded }
            var nextSeen = seen
            if case .ref(let number, let generation) = node {
                let id = PDFObjectID(number: number, generation: generation)
                if seen.contains(id) { throw PDFKitParseFailure.cycleDetected }
                nextSeen.insert(id)
            }
            guard let dict = try resolve(node)?.dictValue else { break }
            let title = dict["Title"]?.stringValue ?? ""
            var destPageIndex: Int?
            if let dest = try resolve(dict["Dest"]) {
                destPageIndex = try pageIndex(fromDestination: dest)
            }
            let children = try dict["First"].map { try collectOutlineSiblings(from: $0, trail: nextSeen) } ?? []
            items.append(PDFKitParsedOutline(title: title, pageIndex: destPageIndex, children: children))
            current = dict["Next"]
            seen = nextSeen
        }
        return items
    }

    private func pageIndex(fromDestination object: PDFKitObject) throws -> Int? {
        if let array = object.arrayValue, let first = array.first, case .ref(let number, let generation) = first {
            return try pageNumberToIndex(PDFObjectID(number: number, generation: generation))
        }
        if case .ref(let number, let generation) = object {
            return try pageNumberToIndex(PDFObjectID(number: number, generation: generation))
        }
        return nil
    }

    private func pageNumberToIndex(_ target: PDFObjectID) throws -> Int? {
        var index = 0
        guard let root = try resolve(trailer["Root"]), let pages = root.dictValue?["Pages"] else {
            return nil
        }
        return try findPageIndex(object: pages, target: target, index: &index, trail: [])
    }

    private func findPageIndex(
        object: PDFKitObject?,
        target: PDFObjectID,
        index: inout Int,
        trail: Set<PDFObjectID>
    ) throws -> Int? {
        guard let object else { return nil }
        var nextTrail = trail
        if case .ref(let number, let generation) = object {
            let id = PDFObjectID(number: number, generation: generation)
            if trail.contains(id) { throw PDFKitParseFailure.cycleDetected }
            if id == target { return index }
            nextTrail.insert(id)
        }
        guard let dict = try resolve(object)?.dictValue else { return nil }
        if dict["Type"]?.nameValue == "Page" {
            index += 1
            return nil
        }
        if let kids = dict["Kids"]?.arrayValue {
            for kid in kids {
                if let found = try findPageIndex(object: kid, target: target, index: &index, trail: nextTrail) {
                    return found
                }
            }
        }
        return nil
    }

    private func requiredDict(_ object: PDFKitObject?) throws -> [String: PDFKitObject] {
        guard let dict = object?.dictValue else { throw PDFKitParseFailure.invalidXref }
        return dict
    }

    private func resolve(_ object: PDFKitObject?) throws -> PDFKitObject? {
        var current = object
        var hops = 0
        var seen: Set<PDFObjectID> = []
        while let value = current {
            hops += 1
            if hops > PDFKitLimits.maxResolveHops { throw PDFKitParseFailure.budgetExceeded }
            if case .ref(let number, let generation) = value {
                let id = PDFObjectID(number: number, generation: generation)
                if seen.contains(id) { throw PDFKitParseFailure.cycleDetected }
                seen.insert(id)
                current = objects[id]
            } else {
                return value
            }
        }
        return current
    }

    private func skipWhitespaceAndComments() {
        while index < bytes.count {
            let char = bytes[index]
            if char == 0x25 {
                while index < bytes.count, bytes[index] != 0x0A, bytes[index] != 0x0D {
                    index += 1
                }
                continue
            }
            if isWhitespace(char) {
                index += 1
                continue
            }
            break
        }
    }

    private func readObject() throws -> PDFKitObject {
        nesting += 1
        defer { nesting -= 1 }
        if nesting > PDFKitLimits.maxNesting { throw PDFKitParseFailure.budgetExceeded }
        skipWhitespaceAndComments()
        guard index < bytes.count else { throw PDFKitParseFailure.truncated }
        let char = bytes[index]
        switch char {
        case 0x3C:
            if index + 1 < bytes.count, bytes[index + 1] == 0x3C {
                return try readDictionary()
            }
            return try readHexString()
        case 0x5B:
            return try readArray()
        case 0x28:
            return try readLiteralString()
        case 0x2F:
            return try readName()
        default:
            if matchKeyword("true") { return .bool(true) }
            if matchKeyword("false") { return .bool(false) }
            if matchKeyword("null") { return .null }
            return try readNumberOrRef()
        }
    }

    private func readDictionary() throws -> PDFKitObject {
        index += 2
        var dict: [String: PDFKitObject] = [:]
        while index < bytes.count {
            skipWhitespaceAndComments()
            if index + 1 < bytes.count, bytes[index] == 0x3E, bytes[index + 1] == 0x3E {
                index += 2
                return .dict(dict)
            }
            guard case .name(let key) = try readName() else { throw PDFKitParseFailure.truncated }
            skipWhitespaceAndComments()
            dict[key] = try readObject()
        }
        throw PDFKitParseFailure.truncated
    }

    private func readArray() throws -> PDFKitObject {
        index += 1
        var items: [PDFKitObject] = []
        while index < bytes.count {
            skipWhitespaceAndComments()
            if index < bytes.count, bytes[index] == 0x5D {
                index += 1
                return .array(items)
            }
            items.append(try readObject())
        }
        throw PDFKitParseFailure.truncated
    }

    private func readName() throws -> PDFKitObject {
        guard index < bytes.count, bytes[index] == 0x2F else { throw PDFKitParseFailure.truncated }
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

    private func readLiteralString() throws -> PDFKitObject {
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
            if depth > 0 { result.append(char) }
        }
        return .string(String(bytes: result, encoding: .utf8) ?? String(bytes: result, encoding: .isoLatin1) ?? "")
    }

    private func readHexString() throws -> PDFKitObject {
        index += 1
        var hex = ""
        while index < bytes.count, bytes[index] != 0x3E {
            let char = bytes[index]
            if !isWhitespace(char) { hex.append(Character(UnicodeScalar(char))) }
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

    private func readNumberOrRef() throws -> PDFKitObject {
        guard let first = readNumberValue() else { throw PDFKitParseFailure.truncated }
        let afterFirst = index
        skipWhitespaceAndComments()
        if let second = readNumberValue() {
            skipWhitespaceAndComments()
            if matchKeyword("R") {
                return .ref(Int(first), Int(second))
            }
            index = afterFirst
            return .number(first)
        }
        index = afterFirst
        return .number(first)
    }

    private func readNumberValue() -> Double? {
        skipWhitespaceAndComments()
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
        return Double(String(bytes: bytes[start..<index], encoding: .ascii) ?? "")
    }

    private func readRawInt() -> Int? {
        skipWhitespaceAndComments()
        let start = index
        if index < bytes.count, bytes[index] == 0x2B || bytes[index] == 0x2D { index += 1 }
        var saw = false
        while index < bytes.count, bytes[index] >= 0x30 && bytes[index] <= 0x39 {
            saw = true
            index += 1
        }
        guard saw else {
            index = start
            return nil
        }
        return Int(String(bytes: bytes[start..<index], encoding: .ascii) ?? "")
    }

    private func readPaddedInt(digits: Int) -> Int? {
        guard index + digits <= bytes.count else { return nil }
        let token = String(bytes: bytes[index..<(index + digits)], encoding: .ascii) ?? ""
        index += digits
        return Int(token.trimmingCharacters(in: .whitespaces))
    }

    private func skipOneSpace() {
        if index < bytes.count, bytes[index] == 0x20 { index += 1 }
    }

    private func matchKeyword(_ keyword: String) -> Bool {
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

    private func rewindKeyword(_ keyword: String) {
        index -= keyword.utf8.count
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
            if depth > 0 { result.append(char) }
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
        func object(_ number: Int, _ body: Data) -> Data {
            var data = Data("\(number) 0 obj\n".utf8)
            data.append(body)
            if !body.isEmpty, body.last != 0x0A { data.append(0x0A) }
            data.append(Data("endobj\n".utf8))
            return data
        }

        let info = object(1, Data(infoDictionary(attributes).utf8))
        let catalog = object(2, Data("<< /Type /Catalog /Pages 3 0 R >>".utf8))
        var pageNumbers: [Int] = []
        var bodies: [(Int, Data)] = [(1, info), (2, catalog)]
        var nextNumber = 4
        var pageBodies: [(Int, Data)] = []
        for page in pages {
            let contentNumber = nextNumber
            nextNumber += 1
            let pageNumber = nextNumber
            nextNumber += 1
            pageNumbers.append(pageNumber)
            let box = page.bounds(for: .mediaBox)
            let stream = contentStream(for: page.string ?? "", box: box)
            pageBodies.append((contentNumber, object(contentNumber, stream)))
            let dict =
                "<< /Type /Page /Parent 3 0 R /MediaBox [\(pdfNumber(box.origin.x)) \(pdfNumber(box.origin.y)) \(pdfNumber(box.origin.x + box.size.width)) \(pdfNumber(box.origin.y + box.size.height))] /Resources << /Font << /F1 << /Type /Font /Subtype /Type1 /BaseFont /Helvetica >> >> >> /Contents \(contentNumber) 0 R >>"
            pageBodies.append((pageNumber, object(pageNumber, Data(dict.utf8))))
        }
        let kids = pageNumbers.map { "\($0) 0 R" }.joined(separator: " ")
        let pagesObject = object(
            3,
            Data("<< /Type /Pages /Kids [\(kids)] /Count \(pages.count) >>".utf8)
        )
        bodies.append((3, pagesObject))
        bodies.append(contentsOf: pageBodies)
        bodies.sort { $0.0 < $1.0 }

        var output = Data("%PDF-\(version.0).\(version.1)\n".utf8)
        output.append(contentsOf: [0x25, 0xE2, 0xE3, 0xCF, 0xD3, 0x0A])
        var offsets = [0]
        var nextExpected = 1
        for (number, body) in bodies {
            while nextExpected < number {
                offsets.append(0)
                nextExpected += 1
            }
            offsets.append(output.count)
            output.append(body)
            nextExpected = number + 1
        }
        let xref = output.count
        var xrefTable = "xref\n0 \(offsets.count)\n"
        xrefTable += "0000000000 65535 f \n"
        for number in 1..<offsets.count {
            xrefTable += String(format: "%010d 00000 n \n", offsets[number])
        }
        output.append(Data(xrefTable.utf8))
        output.append(Data("trailer\n<< /Size \(offsets.count) /Root 2 0 R /Info 1 0 R >>\n".utf8))
        output.append(Data("startxref\n\(xref)\n%%EOF\n".utf8))
        return output
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

    private static func contentStream(for text: String, box: CGRect) -> Data {
        let escaped = escape(text)
        let y = max(24, box.size.height - 72)
        let body = "BT /F1 12 Tf 72 \(pdfNumber(y)) Td (\(escaped)) Tj ET\n"
        let bodyData = Data(body.utf8)
        var stream = Data("<< /Length \(bodyData.count) >>\nstream\n".utf8)
        stream.append(bodyData)
        stream.append(Data("endstream".utf8))
        return stream
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
