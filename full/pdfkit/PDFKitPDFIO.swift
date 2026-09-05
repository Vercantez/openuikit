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

    var boolValue: Bool? {
        if case .bool(let value) = self { return value }
        return nil
    }

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
    var annotations: [PDFKitParsedAnnotation]
    var characters: [PDFKitParsedCharacter]
    var resources: PDFKitObject?
}

struct PDFKitParsedCharacter {
    var scalar: Character
    var bounds: CGRect
}

struct PDFKitParsedAnnotation {
    var subtype: String
    var bounds: CGRect
    var contents: String?
    var uri: String?
    var destinationPageIndex: Int?
    var fieldName: String?
    var fieldValue: String?
    var quadPoints: [CGPoint]
    var colorComponents: [CGFloat]
}

struct PDFKitParsedDocument {
    var majorVersion: Int
    var minorVersion: Int
    var encrypted: Bool
    var pages: [PDFKitParsedPage]
    var attributes: [AnyHashable: Any]
    var outlines: [PDFKitParsedOutline]
    var accessPermissions: PDFAccessPermissions
    var permissionsStatus: PDFDocumentPermissions
    var encryptInfo: PDFKitCrypto.EncryptInfo?
}

struct PDFKitParsedOutline {
    var title: String
    var pageIndex: Int?
    var children: [PDFKitParsedOutline]
}

enum PDFKitIO {
    static func parse(_ data: Data, password: String? = nil) -> PDFKitParsedDocument? {
        switch parseDetailed(data, password: password) {
        case .success(let document):
            return document
        case .failure:
            return nil
        }
    }

    static func parseDetailed(_ data: Data, password: String? = nil) -> PDFKitParseOutcome {
        PDFKitParser(data: data, password: password).parse()
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
    var objectStreamNumber: Int = -1
    var objectStreamIndex: Int = -1
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
    var bytes: [UInt8]
    let password: String?
    var index = 0
    var objects: [PDFObjectID: PDFKitObject] = [:]
    var objectsByNumber: [Int: PDFObjectID] = [:]
    var trailer: [String: PDFKitObject] = [:]
    var major = 1
    var minor = 4
    var nesting = 0
    var pageTreeNodes = 0
    var outlineNodes = 0
    var encryptObjectNumber: Int?
    var fileKey: [UInt8]?
    var useAES = false
    var unlockedAsOwner = false

    init(data: Data, password: String?) {
        bytes = [UInt8](data)
        self.password = password
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
            var pending: [PDFPendingStream] = []
            for entry in entries where entry.inUse && entry.offset >= 0 {
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
            let encryptInfo = try parseEncryptInfo()
            if let encryptInfo {
                if let password {
                    guard let unlocked = PDFKitCrypto.unlock(password: password, info: encryptInfo) else {
                        return .success(lockedDocument(info: encryptInfo))
                    }
                    fileKey = unlocked.key
                    useAES = encryptInfo.useAES
                    unlockedAsOwner = unlocked.owner
                    try decryptAllObjects()
                } else {
                    return .success(lockedDocument(info: encryptInfo))
                }
            }
            try expandObjectStreams()
            try decodeAllStreams()
            let catalog = try requiredDict(resolve(trailer["Root"]))
            let pagesRoot = catalog["Pages"]
            let pages = try collectPages(from: pagesRoot, inherited: InheritedPageState(), trail: [])
            let attributes = parseInfo()
            let outlines = try parseOutlines(from: catalog["Outlines"])
            return .success(
                PDFKitParsedDocument(
                    majorVersion: major,
                    minorVersion: minor,
                    encrypted: encryptInfo != nil,
                    pages: pages,
                    attributes: attributes,
                    outlines: outlines,
                    accessPermissions: permissions(from: encryptInfo, owner: unlockedAsOwner),
                    permissionsStatus: encryptInfo == nil
                        ? .owner
                        : (unlockedAsOwner ? .owner : .user),
                    encryptInfo: encryptInfo
                )
            )
        } catch let failure as PDFKitParseFailure {
            return .failure(failure)
        } catch {
            return .failure(.invalidXref)
        }
    }

    private func lockedDocument(info: PDFKitCrypto.EncryptInfo) -> PDFKitParsedDocument {
        PDFKitParsedDocument(
            majorVersion: major,
            minorVersion: minor,
            encrypted: true,
            pages: [],
            attributes: [:],
            outlines: [],
            accessPermissions: [],
            permissionsStatus: .none,
            encryptInfo: info
        )
    }

    private func permissions(from info: PDFKitCrypto.EncryptInfo?, owner: Bool) -> PDFAccessPermissions {
        if info == nil || owner {
            return [
                .allowsLowQualityPrinting, .allowsHighQualityPrinting, .allowsDocumentChanges,
                .allowsDocumentAssembly, .allowsContentCopying, .allowsContentAccessibility,
                .allowsCommenting, .allowsFormFieldEntry
            ]
        }
        let bits = UInt32(bitPattern: info?.permissions ?? -4)
        var set: PDFAccessPermissions = []
        if (bits & (1 << 2)) != 0 { set.insert(.allowsLowQualityPrinting) }
        if (bits & (1 << 3)) != 0 { set.insert(.allowsHighQualityPrinting) }
        if (bits & (1 << 4)) != 0 { set.insert(.allowsDocumentChanges) }
        if (bits & (1 << 5)) != 0 { set.insert(.allowsContentCopying) }
        if (bits & (1 << 6)) != 0 {
            set.insert(.allowsCommenting)
            set.insert(.allowsFormFieldEntry)
        }
        if (bits & (1 << 9)) != 0 { set.insert(.allowsContentAccessibility) }
        if (bits & (1 << 10)) != 0 { set.insert(.allowsDocumentAssembly) }
        return set
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
        return try parseXRef(at: start, trail: [])
    }

    private func parseXRef(at start: Int, trail: Set<Int>) throws -> [PDFXRefEntry] {
        guard start >= 0, start < bytes.count else { throw PDFKitParseFailure.invalidXref }
        if trail.contains(start) { throw PDFKitParseFailure.cycleDetected }
        var nextTrail = trail
        nextTrail.insert(start)
        index = start
        skipWhitespaceAndComments()
        if matchKeyword("xref") {
            var entries = try parseClassicXRef()
            skipWhitespaceAndComments()
            guard matchKeyword("trailer") else { throw PDFKitParseFailure.invalidXref }
            skipWhitespaceAndComments()
            guard case .dict(let dict) = try readObject() else { throw PDFKitParseFailure.invalidXref }
            if trailer.isEmpty { trailer = dict }
            if let prev = dict["Prev"]?.intValue {
                let previous = try parseXRef(at: prev, trail: nextTrail)
                entries = mergeXRef(previous, entries)
            }
            return entries
        }
        return try parseXRefStream(at: start, trail: nextTrail)
    }

    private func mergeXRef(_ older: [PDFXRefEntry], _ newer: [PDFXRefEntry]) -> [PDFXRefEntry] {
        var map: [Int: PDFXRefEntry] = [:]
        for entry in older { map[entry.number] = entry }
        for entry in newer { map[entry.number] = entry }
        return map.values.sorted { $0.number < $1.number }
    }

    /// ISO 32000-1 §7.5.8 cross-reference streams.
    private func parseXRefStream(at start: Int, trail: Set<Int>) throws -> [PDFXRefEntry] {
        index = start
        skipWhitespaceAndComments()
        guard let number = readRawInt() else { throw PDFKitParseFailure.invalidXref }
        skipWhitespaceAndComments()
        guard let generation = readRawInt() else { throw PDFKitParseFailure.invalidXref }
        skipWhitespaceAndComments()
        guard matchKeyword("obj") else { throw PDFKitParseFailure.invalidXref }
        skipWhitespaceAndComments()
        let header = try readObject()
        skipWhitespaceAndComments()
        guard matchKeyword("stream") else { throw PDFKitParseFailure.invalidXref }
        if index < bytes.count, bytes[index] == 0x0D { index += 1 }
        if index < bytes.count, bytes[index] == 0x0A { index += 1 }
        guard let dict = header.dictValue else { throw PDFKitParseFailure.invalidXref }
        let length = try resolvedInt(dict["Length"])
        let end = index + length
        guard end <= bytes.count else { throw PDFKitParseFailure.truncated }
        var streamData = Data(bytes[index..<end])
        streamData = try PDFKitFilters.decode(streamData, filter: dict["Filter"], decodeParms: dict["DecodeParms"] ?? dict["DP"])
        if trailer.isEmpty { trailer = dict }
        let id = PDFObjectID(number: number, generation: generation)
        objects[id] = .stream(dict, streamData)
        objectsByNumber[number] = id
        let width = (dict["W"]?.arrayValue ?? []).compactMap(\.intValue)
        guard width.count == 3 else { throw PDFKitParseFailure.invalidXref }
        let size = dict["Size"]?.intValue ?? 0
        var subsections: [(Int, Int)] = []
        if let indexArray = dict["Index"]?.arrayValue {
            var cursor = 0
            while cursor + 1 < indexArray.count {
                subsections.append((indexArray[cursor].intValue ?? 0, indexArray[cursor + 1].intValue ?? 0))
                cursor += 2
            }
        } else {
            subsections = [(0, size)]
        }
        let rowWidth = width.reduce(0, +)
        guard rowWidth > 0 else { throw PDFKitParseFailure.invalidXref }
        var entries: [PDFXRefEntry] = []
        var streamIndex = 0
        let raw = [UInt8](streamData)
        for (first, count) in subsections {
            for objectNumber in first..<(first + count) {
                guard streamIndex + rowWidth <= raw.count else { throw PDFKitParseFailure.truncated }
                let field1 = xrefField(raw, at: streamIndex, width: width[0])
                let field2 = xrefField(raw, at: streamIndex + width[0], width: width[1])
                let field3 = xrefField(raw, at: streamIndex + width[0] + width[1], width: width[2])
                streamIndex += rowWidth
                let type = width[0] == 0 ? 1 : field1
                switch type {
                case 0:
                    entries.append(PDFXRefEntry(number: objectNumber, generation: field3, offset: 0, inUse: false))
                case 1:
                    entries.append(PDFXRefEntry(number: objectNumber, generation: field3, offset: field2, inUse: true))
                case 2:
                    entries.append(
                        PDFXRefEntry(
                            number: objectNumber,
                            generation: 0,
                            offset: -1,
                            inUse: true,
                            objectStreamNumber: field2,
                            objectStreamIndex: field3
                        )
                    )
                default:
                    throw PDFKitParseFailure.invalidXref
                }
            }
        }
        if let prev = dict["Prev"]?.intValue {
            let previous = try parseXRef(at: prev, trail: trail)
            entries = mergeXRef(previous, entries)
        }
        return entries
    }

    private func xrefField(_ bytes: [UInt8], at offset: Int, width: Int) -> Int {
        if width == 0 { return 0 }
        var value = 0
        for index in 0..<width {
            value = (value << 8) | Int(bytes[offset + index])
        }
        return value
    }

    private func resolvedInt(_ object: PDFKitObject?) throws -> Int {
        if let value = object?.intValue { return value }
        if case .ref = object {
            let resolved = try resolve(object)
            if let value = resolved?.intValue { return value }
        }
        throw PDFKitParseFailure.unresolvedLength
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
        objects[id] = value
        objectsByNumber[id.number] = id
    }

    /// ISO 32000-1 §7.5.7 object streams.
    private func expandObjectStreams() throws {
        let streams = objects.filter { _, value in
            value.dictValue?["Type"]?.nameValue == "ObjStm"
        }
        for (id, value) in streams {
            guard case .stream(let dict, let data) = value else { continue }
            let decoded = try PDFKitFilters.decode(
                data,
                filter: dict["Filter"],
                decodeParms: dict["DecodeParms"] ?? dict["DP"]
            )
            let count = dict["N"]?.intValue ?? 0
            let first = dict["First"]?.intValue ?? 0
            guard count >= 0, first >= 0, first <= decoded.count else { throw PDFKitParseFailure.invalidXref }
            let header = [UInt8](decoded.prefix(first))
            var cursor = 0
            var pairs: [(Int, Int)] = []
            for _ in 0..<count {
                while cursor < header.count, header[cursor] == 0x20 || header[cursor] == 0x0A || header[cursor] == 0x0D || header[cursor] == 0x09 {
                    cursor += 1
                }
                let numberStart = cursor
                while cursor < header.count, header[cursor] >= 0x30 && header[cursor] <= 0x39 { cursor += 1 }
                guard cursor > numberStart else { throw PDFKitParseFailure.invalidXref }
                let objectNumber = Int(String(bytes: header[numberStart..<cursor], encoding: .ascii) ?? "") ?? 0
                while cursor < header.count, header[cursor] == 0x20 || header[cursor] == 0x0A || header[cursor] == 0x0D || header[cursor] == 0x09 {
                    cursor += 1
                }
                let offsetStart = cursor
                while cursor < header.count, header[cursor] >= 0x30 && header[cursor] <= 0x39 { cursor += 1 }
                guard cursor > offsetStart else { throw PDFKitParseFailure.invalidXref }
                let relative = Int(String(bytes: header[offsetStart..<cursor], encoding: .ascii) ?? "") ?? 0
                pairs.append((objectNumber, relative))
            }
            let payload = [UInt8](decoded.dropFirst(first))
            for (objectNumber, relative) in pairs {
                if objects[PDFObjectID(number: objectNumber, generation: 0)] != nil { continue }
                guard relative >= 0, relative < payload.count else { throw PDFKitParseFailure.invalidXref }
                let parsed = try readObjectFromBytes(Array(payload[relative...]))
                try register(PDFObjectID(number: objectNumber, generation: 0), parsed)
            }
            _ = id
        }
    }

    private func readObjectFromBytes(_ source: [UInt8]) throws -> PDFKitObject {
        let savedBytes = bytes
        let savedIndex = index
        let savedNesting = nesting
        bytes = source
        index = 0
        nesting = 0
        defer {
            bytes = savedBytes
            index = savedIndex
            nesting = savedNesting
        }
        return try readObject()
    }

    private func parseEncryptInfo() throws -> PDFKitCrypto.EncryptInfo? {
        guard let encryptRef = trailer["Encrypt"] else { return nil }
        if case .ref(let number, _) = encryptRef {
            encryptObjectNumber = number
        }
        guard let dict = try resolve(encryptRef)?.dictValue else { return nil }
        let filter = dict["Filter"]?.nameValue ?? ""
        if filter != "Standard" { throw PDFKitParseFailure.unsupportedFilter }
        let revision = dict["R"]?.intValue ?? 2
        let version = dict["V"]?.intValue ?? 1
        let lengthBits = dict["Length"]?.intValue ?? (revision <= 2 ? 40 : 128)
        var info = PDFKitCrypto.EncryptInfo(
            revision: revision,
            version: version,
            keyLengthBytes: max(5, lengthBits / 8),
            permissions: Int32(dict["P"]?.intValue ?? -4),
            ownerKey: binaryString(dict["O"]),
            userKey: binaryString(dict["U"]),
            fileID: fileIdentifier(),
            encryptMetadata: dict["EncryptMetadata"]?.boolValue ?? true,
            useAES: usesAES(dict),
            ownerEncryptionKey: binaryString(dict["OE"]),
            userEncryptionKey: binaryString(dict["UE"]),
            perms: binaryString(dict["Perms"])
        )
        if revision >= 5 { info.keyLengthBytes = 32 }
        return info
    }

    private func usesAES(_ dict: [String: PDFKitObject]) -> Bool {
        if let cfm = dict["CFM"]?.nameValue { return cfm == "AESV2" || cfm == "AESV3" }
        if let filterDict = dict["CF"]?.dictValue {
            let stm = dict["StmF"]?.nameValue ?? "StdCF"
            if let cfm = filterDict[stm]?.dictValue?["CFM"]?.nameValue {
                return cfm == "AESV2" || cfm == "AESV3"
            }
        }
        return dict["V"]?.intValue ?? 0 >= 4 && dict["R"]?.intValue ?? 0 >= 4
    }

    private func fileIdentifier() -> [UInt8] {
        if let array = trailer["ID"]?.arrayValue, let first = array.first {
            return binaryString(first)
        }
        return []
    }

    private func binaryString(_ object: PDFKitObject?) -> [UInt8] {
        switch object {
        case .string(let value):
            return Array(value.data(using: .isoLatin1) ?? Data())
        case .stream(_, let data):
            return [UInt8](data)
        default:
            return []
        }
    }

    private func decryptAllObjects() throws {
        guard let fileKey else { return }
        for (id, value) in objects {
            if id.number == encryptObjectNumber { continue }
            objects[id] = decryptObject(value, id: id, key: fileKey)
        }
    }

    private func decryptObject(_ object: PDFKitObject, id: PDFObjectID, key: [UInt8]) -> PDFKitObject {
        switch object {
        case .string(let value):
            let raw = Array(value.data(using: .isoLatin1) ?? Data())
            let decrypted = PDFKitCrypto.decryptObject(
                Data(raw),
                key: key,
                object: id.number,
                generation: id.generation,
                useAES: useAES
            )
            return .string(String(data: decrypted, encoding: .isoLatin1) ?? "")
        case .stream(let dict, let data):
            let decrypted = PDFKitCrypto.decryptObject(
                data,
                key: key,
                object: id.number,
                generation: id.generation,
                useAES: useAES
            )
            let newDict = decryptDict(dict, id: id, key: key)
            return .stream(newDict, decrypted)
        case .dict(let dict):
            return .dict(decryptDict(dict, id: id, key: key))
        case .array(let items):
            return .array(items.map { decryptObject($0, id: id, key: key) })
        default:
            return object
        }
    }

    private func decryptDict(
        _ dict: [String: PDFKitObject],
        id: PDFObjectID,
        key: [UInt8]
    ) -> [String: PDFKitObject] {
        var result: [String: PDFKitObject] = [:]
        for (name, value) in dict {
            result[name] = decryptObject(value, id: id, key: key)
        }
        return result
    }

    private func decodeAllStreams() throws {
        for (id, value) in objects {
            guard case .stream(let dict, let data) = value else { continue }
            if dict["Type"]?.nameValue == "XRef" { continue }
            if dict["Type"]?.nameValue == "ObjStm" { continue }
            let decoded = try PDFKitFilters.decode(
                data,
                filter: dict["Filter"] ?? dict["F"],
                decodeParms: dict["DecodeParms"] ?? dict["DP"]
            )
            var newDict = dict
            newDict["Filter"] = nil
            newDict["F"] = nil
            newDict["DecodeParms"] = nil
            newDict["DP"] = nil
            newDict["Length"] = .number(Double(decoded.count))
            objects[id] = .stream(newDict, decoded)
        }
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
        let extracted = PDFKitTextExtractor.extract(from: contentsData, box: media)
        return PDFKitParsedPage(
            mediaBox: media,
            cropBox: rect(from: dict["CropBox"]) ?? inherited.cropBox,
            bleedBox: rect(from: dict["BleedBox"]) ?? inherited.bleedBox,
            trimBox: rect(from: dict["TrimBox"]) ?? inherited.trimBox,
            artBox: rect(from: dict["ArtBox"]) ?? inherited.artBox,
            rotation: dict["Rotate"]?.intValue ?? inherited.rotation,
            contents: contentsData,
            text: extracted.text,
            resourceKeyCount: resourceKeyCount(from: resources),
            annotations: try parseAnnotations(from: dict["Annots"]),
            characters: extracted.characters,
            resources: resources
        )
    }

    private func parseAnnotations(from object: PDFKitObject?) throws -> [PDFKitParsedAnnotation] {
        guard let resolved = try resolve(object), let array = resolved.arrayValue else { return [] }
        var annotations: [PDFKitParsedAnnotation] = []
        for item in array {
            guard let dict = try resolve(item)?.dictValue else { continue }
            let subtype = dict["Subtype"]?.nameValue ?? dict["Subtype"]?.stringValue ?? "Text"
            let bounds = rect(from: dict["Rect"]) ?? .zero
            var uri: String?
            var destPage: Int?
            if let action = try resolve(dict["A"])?.dictValue {
                if action["S"]?.nameValue == "URI" {
                    uri = action["URI"]?.stringValue
                }
                if action["S"]?.nameValue == "GoTo", let dest = action["D"] {
                    destPage = try pageIndex(fromDestination: dest)
                }
            }
            if let dest = dict["Dest"] {
                destPage = try pageIndex(fromDestination: try resolve(dest) ?? dest)
            }
            var quads: [CGPoint] = []
            if let numbers = dict["QuadPoints"]?.arrayValue {
                var index = 0
                while index + 1 < numbers.count {
                    quads.append(CGPoint(x: numbers[index].doubleValue ?? 0, y: numbers[index + 1].doubleValue ?? 0))
                    index += 2
                }
            }
            var color: [CGFloat] = []
            if let components = dict["C"]?.arrayValue {
                color = components.compactMap { $0.doubleValue.map { CGFloat($0) } }
            }
            annotations.append(
                PDFKitParsedAnnotation(
                    subtype: subtype,
                    bounds: bounds,
                    contents: dict["Contents"]?.stringValue,
                    uri: uri,
                    destinationPageIndex: destPage,
                    fieldName: dict["T"]?.stringValue,
                    fieldValue: dict["V"]?.stringValue,
                    quadPoints: quads,
                    colorComponents: color
                )
            )
        }
        return annotations
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
        if let created = pdfDate(dict["CreationDate"]?.stringValue) {
            attributes[PDFDocumentAttribute.creationDateAttribute] = created
        }
        if let modified = pdfDate(dict["ModDate"]?.stringValue) {
            attributes[PDFDocumentAttribute.modificationDateAttribute] = modified
        }
        return attributes
    }

    private func pdfDate(_ string: String?) -> Date? {
        guard var text = string else { return nil }
        if text.hasPrefix("D:") {
            text = String(text.dropFirst(2))
        }
        let digits = text.prefix(14).filter { $0.isNumber }
        guard digits.count >= 8 else { return nil }
        var components = DateComponents()
        components.year = Int(digits.prefix(4))
        components.month = Int(digits.dropFirst(4).prefix(2))
        components.day = Int(digits.dropFirst(6).prefix(2))
        if digits.count >= 10 { components.hour = Int(digits.dropFirst(8).prefix(2)) }
        if digits.count >= 12 { components.minute = Int(digits.dropFirst(10).prefix(2)) }
        if digits.count >= 14 { components.second = Int(digits.dropFirst(12).prefix(2)) }
        return Calendar(identifier: .gregorian).date(from: components)
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
        return .string(String(bytes: result, encoding: .isoLatin1) ?? "")
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
    static func extract(from data: Data, box: CGRect) -> (text: String, characters: [PDFKitParsedCharacter]) {
        let tokens = PDFKitContentLexer.tokens(in: data)
        var pieces: [String] = []
        var characters: [PDFKitParsedCharacter] = []
        var fontSize: CGFloat = 12
        var x: CGFloat = 0
        var y: CGFloat = box.size.height - 72
        var inText = false
        var index = 0
        while index < tokens.count {
            let token = tokens[index]
            if token == "BT" {
                inText = true
                index += 1
                continue
            }
            if token == "ET" {
                inText = false
                index += 1
                continue
            }
            if token == "Tf", index >= 2 {
                fontSize = CGFloat(Double(tokens[index - 1]) ?? 12)
            }
            if token == "Td" || token == "TD", index >= 2 {
                x += CGFloat(Double(tokens[index - 2]) ?? 0)
                y += CGFloat(Double(tokens[index - 1]) ?? 0)
            }
            if token == "Tm", index >= 6 {
                x = CGFloat(Double(tokens[index - 2]) ?? 0)
                y = CGFloat(Double(tokens[index - 1]) ?? 0)
            }
            if inText, token == "Tj" || token == "'" || token == "\"", index >= 1 {
                let string = unquote(tokens[index - 1])
                if !string.isEmpty {
                    pieces.append(string)
                    appendCharacters(string, fontSize: fontSize, x: &x, y: y, into: &characters)
                }
            }
            if inText, token == "TJ", index >= 1 {
                let string = unquote(tokens[index - 1])
                if !string.isEmpty {
                    pieces.append(string)
                    appendCharacters(string, fontSize: fontSize, x: &x, y: y, into: &characters)
                }
            }
            index += 1
        }
        if pieces.isEmpty {
            // Fall back to scanning literal strings so a content stream that
            // only uses non-standard operators still yields searchable text.
            let fallback = fallbackStrings(data)
            if !fallback.isEmpty {
                pieces = fallback
                var cursorX: CGFloat = 72
                let cursorY = max(24, box.size.height - 72)
                for piece in fallback {
                    var x = cursorX
                    appendCharacters(piece, fontSize: 12, x: &x, y: cursorY, into: &characters)
                    cursorX = x + 8
                }
            }
        }
        let text = pieces.joined(separator: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return (text, characters)
    }

    private static func appendCharacters(
        _ string: String,
        fontSize: CGFloat,
        x: inout CGFloat,
        y: CGFloat,
        into characters: inout [PDFKitParsedCharacter]
    ) {
        let width = fontSize * 0.6
        let height = fontSize
        for character in string {
            characters.append(
                PDFKitParsedCharacter(
                    scalar: character,
                    bounds: CGRect(x: x, y: y, width: width, height: height)
                )
            )
            x += width
        }
    }

    private static func unquote(_ token: String) -> String {
        if token.hasPrefix("("), token.hasSuffix(")") {
            return unescape(String(token.dropFirst().dropLast()))
        }
        if token.hasPrefix("<"), token.hasSuffix(">") {
            let hex = String(token.dropFirst().dropLast())
            var data = Data()
            var cursor = hex.startIndex
            while cursor < hex.endIndex {
                let next = hex.index(cursor, offsetBy: 2, limitedBy: hex.endIndex) ?? hex.endIndex
                if let value = UInt8(hex[cursor..<next], radix: 16) {
                    data.append(value)
                }
                cursor = next
            }
            return String(data: data, encoding: .isoLatin1) ?? ""
        }
        return ""
    }

    private static func unescape(_ string: String) -> String {
        var result = ""
        var index = string.startIndex
        while index < string.endIndex {
            let char = string[index]
            if char == "\\" {
                let next = string.index(after: index)
                if next < string.endIndex {
                    result.append(string[next])
                    index = string.index(after: next)
                    continue
                }
            }
            result.append(char)
            index = string.index(after: index)
        }
        return result
    }

    private static func fallbackStrings(_ data: Data) -> [String] {
        guard let text = String(data: data, encoding: .isoLatin1) else { return [] }
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
        return pieces
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

enum PDFKitContentLexer {
    static func tokens(in data: Data) -> [String] {
        var tokens: [String] = []
        let bytes = [UInt8](data)
        var index = 0
        while index < bytes.count {
            let byte = bytes[index]
            if byte == 0x00 || byte == 0x09 || byte == 0x0A || byte == 0x0C || byte == 0x0D || byte == 0x20 {
                index += 1
                continue
            }
            if byte == 0x25 {
                while index < bytes.count, bytes[index] != 0x0A, bytes[index] != 0x0D { index += 1 }
                continue
            }
            if byte == 0x28 {
                let start = index
                index += 1
                var depth = 1
                while index < bytes.count, depth > 0 {
                    if bytes[index] == 0x5C {
                        index += 2
                        continue
                    }
                    if bytes[index] == 0x28 { depth += 1 }
                    if bytes[index] == 0x29 { depth -= 1 }
                    index += 1
                }
                tokens.append(String(bytes: bytes[start..<min(index, bytes.count)], encoding: .isoLatin1) ?? "")
                continue
            }
            if byte == 0x3C {
                let start = index
                if index + 1 < bytes.count, bytes[index + 1] == 0x3C {
                    index += 2
                    var depth = 1
                    while index + 1 < bytes.count, depth > 0 {
                        if bytes[index] == 0x3C, bytes[index + 1] == 0x3C {
                            depth += 1
                            index += 2
                            continue
                        }
                        if bytes[index] == 0x3E, bytes[index + 1] == 0x3E {
                            depth -= 1
                            index += 2
                            continue
                        }
                        index += 1
                    }
                    tokens.append("<<>>")
                    continue
                }
                while index < bytes.count, bytes[index] != 0x3E { index += 1 }
                if index < bytes.count { index += 1 }
                tokens.append(String(bytes: bytes[start..<min(index, bytes.count)], encoding: .isoLatin1) ?? "")
                continue
            }
            if byte == 0x5B {
                let start = index
                index += 1
                var depth = 1
                while index < bytes.count, depth > 0 {
                    if bytes[index] == 0x5B { depth += 1 }
                    if bytes[index] == 0x5D { depth -= 1 }
                    if bytes[index] == 0x28 {
                        index += 1
                        var sdepth = 1
                        while index < bytes.count, sdepth > 0 {
                            if bytes[index] == 0x5C { index += 2; continue }
                            if bytes[index] == 0x28 { sdepth += 1 }
                            if bytes[index] == 0x29 { sdepth -= 1 }
                            index += 1
                        }
                        continue
                    }
                    index += 1
                }
                tokens.append(String(bytes: bytes[start..<min(index, bytes.count)], encoding: .isoLatin1) ?? "")
                continue
            }
            let start = index
            while index < bytes.count {
                let current = bytes[index]
                if current == 0x00 || current == 0x09 || current == 0x0A || current == 0x0C || current == 0x0D || current == 0x20 {
                    break
                }
                if current == 0x28 || current == 0x29 || current == 0x3C || current == 0x3E || current == 0x5B || current == 0x5D || current == 0x2F || current == 0x25 {
                    break
                }
                index += 1
            }
            if index == start { index += 1; continue }
            tokens.append(String(bytes: bytes[start..<index], encoding: .ascii) ?? "")
        }
        return tokens
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
        var pageNumbers: [Int] = []
        var bodies: [(Int, Data)] = [(1, info)]
        var nextNumber = 4
        var pageBodies: [(Int, Data)] = []
        var outlineRootNumber: Int?
        for page in pages {
            let contentNumber = nextNumber
            nextNumber += 1
            var annotNumbers: [Int] = []
            for annotation in page.annotations {
                let annotNumber = nextNumber
                nextNumber += 1
                annotNumbers.append(annotNumber)
                pageBodies.append((annotNumber, object(annotNumber, Data(annotationDictionary(annotation).utf8))))
            }
            let pageNumber = nextNumber
            nextNumber += 1
            pageNumbers.append(pageNumber)
            let box = page.bounds(for: .mediaBox)
            let stream: Data
            if let existing = page.contentData, !existing.isEmpty {
                stream = wrappedStream(existing)
            } else {
                stream = contentStream(for: page.string ?? "", box: box)
            }
            pageBodies.append((contentNumber, object(contentNumber, stream)))
            var dict = "<< /Type /Page /Parent 3 0 R /MediaBox [\(boxArray(box))]"
            let crop = page.bounds(for: .cropBox)
            if crop != box { dict += " /CropBox [\(boxArray(crop))]" }
            if page.rotation != 0 { dict += " /Rotate \(page.rotation)" }
            dict += " /Resources << /Font << /F1 << /Type /Font /Subtype /Type1 /BaseFont /Helvetica >> >> >> /Contents \(contentNumber) 0 R"
            if !annotNumbers.isEmpty {
                dict += " /Annots [\(annotNumbers.map { "\($0) 0 R" }.joined(separator: " "))]"
            }
            dict += " >>"
            pageBodies.append((pageNumber, object(pageNumber, Data(dict.utf8))))
        }
        if let outline = pages.first?.document?.outlineRoot, outline.numberOfChildren > 0 {
            let built = outlineObjects(outline, start: nextNumber, pageNumbers: pageNumbers, pages: pages)
            outlineRootNumber = built.root
            nextNumber = built.next
            pageBodies.append(contentsOf: built.bodies.map { ($0.0, object($0.0, $0.1)) })
        }
        var catalogBody = "<< /Type /Catalog /Pages 3 0 R"
        if let outlineRootNumber {
            catalogBody += " /Outlines \(outlineRootNumber) 0 R"
        }
        catalogBody += " >>"
        bodies.append((2, object(2, Data(catalogBody.utf8))))
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
        func addDate(_ key: String, _ value: Any?) {
            guard let date = value as? Date else { return }
            let formatted = pdfDateString(date)
            parts.append("/\(key) (\(formatted))")
        }
        addDate("CreationDate", attributes?[PDFDocumentAttribute.creationDateAttribute])
        addDate("ModDate", attributes?[PDFDocumentAttribute.modificationDateAttribute])
        parts.append(">>")
        return parts.joined(separator: " ")
    }

    private static func pdfDateString(_ date: Date) -> String {
        let calendar = Calendar(identifier: .gregorian)
        let c = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
        return String(
            format: "D:%04d%02d%02d%02d%02d%02d",
            c.year ?? 1970,
            c.month ?? 1,
            c.day ?? 1,
            c.hour ?? 0,
            c.minute ?? 0,
            c.second ?? 0
        )
    }

    private static func wrappedStream(_ data: Data) -> Data {
        var stream = Data("<< /Length \(data.count) >>\nstream\n".utf8)
        stream.append(data)
        if data.last != 0x0A { stream.append(0x0A) }
        stream.append(Data("endstream".utf8))
        return stream
    }

    private static func boxArray(_ box: CGRect) -> String {
        "\(pdfNumber(box.origin.x)) \(pdfNumber(box.origin.y)) \(pdfNumber(box.origin.x + box.size.width)) \(pdfNumber(box.origin.y + box.size.height))"
    }

    private static func annotationDictionary(_ annotation: PDFAnnotation) -> String {
        let type = annotation.type ?? "Text"
        var parts = [
            "<< /Type /Annot /Subtype /\(type) /Rect [\(boxArray(annotation.bounds))]"
        ]
        if let contents = annotation.contents {
            parts.append("/Contents (\(escape(contents)))")
        }
        if let field = annotation.fieldName {
            parts.append("/T (\(escape(field)))")
        }
        if let value = annotation.widgetStringValue {
            parts.append("/V (\(escape(value)))")
        }
        if let url = annotation.url {
            parts.append("/A << /S /URI /URI (\(escape(url.absoluteString))) >>")
        }
        parts.append(">>")
        return parts.joined(separator: " ")
    }

    private static func outlineObjects(
        _ root: PDFOutline,
        start: Int,
        pageNumbers: [Int],
        pages: [PDFPage]
    ) -> (root: Int, next: Int, bodies: [(Int, Data)]) {
        var next = start
        var bodies: [(Int, Data)] = []

        func emitSiblings(_ outlines: [PDFOutline], parent: Int?) -> [Int] {
            let numbers = outlines.map { _ -> Int in
                let number = next
                next += 1
                return number
            }
            for (index, outline) in outlines.enumerated() {
                var children: [PDFOutline] = []
                for childIndex in 0..<outline.numberOfChildren {
                    if let child = outline.child(at: childIndex) { children.append(child) }
                }
                let childNumbers = emitSiblings(children, parent: numbers[index])
                var dict = "<< /Title (\(escape(outline.label ?? "")))"
                if let parent { dict += " /Parent \(parent) 0 R" }
                if index + 1 < numbers.count { dict += " /Next \(numbers[index + 1]) 0 R" }
                if index > 0 { dict += " /Prev \(numbers[index - 1]) 0 R" }
                if let first = childNumbers.first, let last = childNumbers.last {
                    dict += " /First \(first) 0 R /Last \(last) 0 R /Count \(childNumbers.count)"
                }
                if let dest = outline.destination, let page = dest.page,
                   let pageIndex = pages.firstIndex(where: { $0 === page }),
                   pageNumbers.indices.contains(pageIndex) {
                    dict += " /Dest [\(pageNumbers[pageIndex]) 0 R /XYZ \(pdfNumber(dest.point.x)) \(pdfNumber(dest.point.y)) 0]"
                }
                dict += " >>"
                bodies.append((numbers[index], Data(dict.utf8)))
            }
            return numbers
        }

        let children: [PDFOutline] = (0..<root.numberOfChildren).compactMap { root.child(at: $0) }
        if children.isEmpty {
            let number = next
            next += 1
            bodies.append((number, Data("<< /Title (\(escape(root.label ?? ""))) >>".utf8)))
            return (number, next, bodies)
        }
        let childNumbers = emitSiblings(children, parent: nil)
        // Synthetic root points at the first sibling chain.
        let rootNumber = next
        next += 1
        let dict = "<< /Type /Outlines /First \(childNumbers[0]) 0 R /Last \(childNumbers[childNumbers.count - 1]) 0 R /Count \(childNumbers.count) >>"
        bodies.append((rootNumber, Data(dict.utf8)))
        return (rootNumber, next, bodies)
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
