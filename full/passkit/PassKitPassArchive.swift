import Foundation

/// Stored-method ZIP reader for `.pkpass` plus `pass.json` field mapping.
///
/// A pkpass is a ZIP (APPNOTE.TXT) whose payload is Apple's documented Wallet
/// pass dictionary. This host unpacks compression method 0 (stored) and
/// reads those keys; it does not inflate method 8. When `manifest.json` is
/// present, each listed file's SHA-1 must match. When a PKCS#7 `signature`
/// is present, verification is fail-closed (`invalidSignature`): Linux has
/// no WWDR chain checker. Unsigned stored archives remain accepted as
/// structure, not as trusted passes.
///
/// Fixture used by `testPassJSONArchive`: stored ZIP containing only
/// `pass.json` with formatVersion 1, passTypeIdentifier, serialNumber,
/// organizationName, description, and the generic style fields.
enum PassKitPassArchive {
    static let localFileSignature: UInt32 = 0x0403_4b50
    static let centralDirectorySignature: UInt32 = 0x0201_4b50
    static let eocdSignature: UInt32 = 0x0605_4b50
    static let storedCompression: UInt16 = 0

    struct Manifest {
        var serialNumber: String
        var passTypeIdentifier: String
        var organizationName: String
        var localizedDescription: String
        var localizedName: String
        var authenticationToken: String?
        var webServiceURL: URL?
        var relevantDate: Date?
        var userInfo: [AnyHashable: Any]?
        var fieldValues: [String: Any]
        var relevantDates: [PKPassRelevantDate]
    }

    static func parse(_ data: Data) throws -> Manifest {
        let files = try storedFiles(from: data)
        try rejectPKCS7SignatureIfPresent(in: files)
        try verifyManifestSHA1sIfPresent(in: files)
        guard let jsonData = passJSON(in: files) else {
            throw PKPassKitError(.invalidDataError)
        }
        return try manifest(fromJSON: jsonData)
    }

    static func passJSON(in files: [String: Data]) -> Data? {
        fileNamed("pass.json", in: files)
    }

    static func fileNamed(_ expected: String, in files: [String: Data]) -> Data? {
        for (name, payload) in files {
            if lastPathComponent(name) == expected {
                return payload
            }
        }
        return nil
    }

    /// PKCS#7/CMS is a BER SEQUENCE (`0x30`). Presence is fail-closed: this
    /// host never claims a WWDR-validated signature.
    static func rejectPKCS7SignatureIfPresent(in files: [String: Data]) throws {
        guard let signature = fileNamed("signature", in: files) else { return }
        _ = signature.first == 0x30
        throw PKPassKitError(.invalidSignature)
    }

    static func verifyManifestSHA1sIfPresent(in files: [String: Data]) throws {
        guard let manifestData = fileNamed("manifest.json", in: files) else { return }
        let object: Any
        do {
            object = try JSONSerialization.jsonObject(with: manifestData, options: [])
        } catch {
            throw PKPassKitError(.invalidDataError)
        }
        guard let map = object as? [String: Any] else {
            throw PKPassKitError(.invalidDataError)
        }
        for (name, value) in map {
            guard let expected = stringValue(value)?.lowercased(), !expected.isEmpty else {
                throw PKPassKitError(.invalidDataError)
            }
            guard let payload = fileNamed(name, in: files) else {
                throw PKPassKitError(.invalidDataError)
            }
            if sha1Hex(payload) != expected {
                throw PKPassKitError(.invalidDataError)
            }
        }
    }

    static func sha1Hex(_ data: Data) -> String {
        PassKitSHA1.hexDigest(data)
    }

    static func lastPathComponent(_ name: String) -> String {
        if let slash = name.lastIndex(of: "/") {
            return String(name[name.index(after: slash)...])
        }
        return name
    }

    static func storedFiles(from data: Data) throws -> [String: Data] {
        guard data.count >= 22 else {
            throw PKPassKitError(.invalidDataError)
        }
        guard let eocd = eocdOffset(in: data) else {
            throw PKPassKitError(.invalidDataError)
        }
        let cdOffset = Int(readUInt32(data, eocd + 16))
        let cdSize = Int(readUInt32(data, eocd + 12))
        let entryCount = Int(readUInt16(data, eocd + 10))
        guard cdOffset >= 0, cdSize >= 0, cdOffset + cdSize <= data.count else {
            throw PKPassKitError(.invalidDataError)
        }
        var files: [String: Data] = [:]
        var cursor = cdOffset
        let cdEnd = cdOffset + cdSize
        var parsed = 0
        while parsed < entryCount, cursor + 46 <= cdEnd {
            guard readUInt32(data, cursor) == centralDirectorySignature else {
                throw PKPassKitError(.invalidDataError)
            }
            let method = readUInt16(data, cursor + 10)
            let compressedSize = Int(readUInt32(data, cursor + 20))
            let nameLen = Int(readUInt16(data, cursor + 28))
            let extraLen = Int(readUInt16(data, cursor + 30))
            let commentLen = Int(readUInt16(data, cursor + 32))
            let localOffset = Int(readUInt32(data, cursor + 42))
            let nameStart = cursor + 46
            guard nameStart + nameLen <= data.count else {
                throw PKPassKitError(.invalidDataError)
            }
            let nameData = data.subdata(in: nameStart ..< (nameStart + nameLen))
            guard let name = String(data: nameData, encoding: .utf8) else {
                throw PKPassKitError(.invalidDataError)
            }
            let payload = try localFilePayload(
                in: data,
                localOffset: localOffset,
                compressedSize: compressedSize,
                method: method
            )
            files[name] = payload
            cursor = nameStart + nameLen + extraLen + commentLen
            parsed += 1
        }
        if files.isEmpty {
            throw PKPassKitError(.invalidDataError)
        }
        return files
    }

    static func eocdOffset(in data: Data) -> Int? {
        let minimum = 22
        guard data.count >= minimum else { return nil }
        let commentMax = 65535
        let start = data.count - minimum
        let floor = max(0, data.count - minimum - commentMax)
        var index = start
        while index >= floor {
            if readUInt32(data, index) == eocdSignature {
                return index
            }
            if index == 0 { break }
            index -= 1
        }
        return nil
    }

    static func localFilePayload(
        in data: Data,
        localOffset: Int,
        compressedSize: Int,
        method: UInt16
    ) throws -> Data {
        guard localOffset >= 0, localOffset + 30 <= data.count else {
            throw PKPassKitError(.invalidDataError)
        }
        guard readUInt32(data, localOffset) == localFileSignature else {
            throw PKPassKitError(.invalidDataError)
        }
        guard method == storedCompression else {
            // Method 8 (deflate) is typical of signed Apple archives; this
            // host only unpacks stored files so the fixture can round-trip
            // without zlib. See oracle-questions.tsv.
            throw PKPassKitError(.invalidDataError)
        }
        let nameLen = Int(readUInt16(data, localOffset + 26))
        let extraLen = Int(readUInt16(data, localOffset + 28))
        let dataStart = localOffset + 30 + nameLen + extraLen
        guard dataStart >= 0, compressedSize >= 0, dataStart + compressedSize <= data.count else {
            throw PKPassKitError(.invalidDataError)
        }
        return data.subdata(in: dataStart ..< (dataStart + compressedSize))
    }

    static func manifest(fromJSON jsonData: Data) throws -> Manifest {
        let object: Any
        do {
            object = try JSONSerialization.jsonObject(with: jsonData, options: [])
        } catch {
            throw PKPassKitError(.invalidDataError)
        }
        guard let root = object as? [String: Any] else {
            throw PKPassKitError(.invalidDataError)
        }
        guard let formatVersion = intValue(root["formatVersion"]) else {
            throw PKPassKitError(.invalidDataError)
        }
        if formatVersion != 1 {
            throw PKPassKitError(.unsupportedVersionError)
        }
        let passTypeIdentifier = try requiredString(root, "passTypeIdentifier")
        let serialNumber = try requiredString(root, "serialNumber")
        let organizationName = try requiredString(root, "organizationName")
        let description = try requiredString(root, "description")
        var fieldValues: [String: Any] = [:]
        ingestStyleFields(from: root, into: &fieldValues)
        ingestBarcodes(from: root, into: &fieldValues)
        if let voided = boolValue(root["voided"]) {
            fieldValues["voided"] = voided
        }
        if let expiration = parsePassDate(root["expirationDate"]) {
            fieldValues["expirationDate"] = expiration
        }
        ingestLocations(from: root, into: &fieldValues)

        let logoText = stringValue(root["logoText"])
        let localizedName: String
        if let logoText, !logoText.isEmpty {
            localizedName = logoText
        } else {
            localizedName = organizationName
        }

        var relevantDate = parsePassDate(root["relevantDate"])
        var relevantDates: [PKPassRelevantDate] = []
        if let relevantDate {
            let wrapper = PKPassRelevantDate()
            wrapper.date = relevantDate
            relevantDates.append(wrapper)
        }
        if let array = root["relevantDates"] as? [Any] {
            for item in array {
                if let dict = item as? [String: Any], let date = parsePassDate(dict["date"]) {
                    let wrapper = PKPassRelevantDate()
                    wrapper.date = date
                    relevantDates.append(wrapper)
                    if relevantDate == nil {
                        relevantDate = date
                    }
                }
            }
        }

        var userInfo: [AnyHashable: Any]?
        if let info = root["userInfo"] as? [String: Any] {
            userInfo = info
        }

        let token = stringValue(root["authenticationToken"])
        var webServiceURL: URL?
        if let urlString = stringValue(root["webServiceURL"]) {
            webServiceURL = URL(string: urlString)
        }

        return Manifest(
            serialNumber: serialNumber,
            passTypeIdentifier: passTypeIdentifier,
            organizationName: organizationName,
            localizedDescription: description,
            localizedName: localizedName,
            authenticationToken: token,
            webServiceURL: webServiceURL,
            relevantDate: relevantDate,
            userInfo: userInfo,
            fieldValues: fieldValues,
            relevantDates: relevantDates
        )
    }

    static func ingestStyleFields(from root: [String: Any], into fields: inout [String: Any]) {
        let styleKeys = ["boardingPass", "coupon", "eventTicket", "generic", "storeCard"]
        for style in styleKeys {
            guard let dict = root[style] as? [String: Any] else { continue }
            let buckets = [
                "primaryFields", "secondaryFields", "auxiliaryFields",
                "backFields", "headerFields",
            ]
            for bucket in buckets {
                guard let items = dict[bucket] as? [Any] else { continue }
                for item in items {
                    guard let field = item as? [String: Any] else { continue }
                    guard let key = stringValue(field["key"]), !key.isEmpty else { continue }
                    if let value = field["value"] {
                        fields[key] = value
                    }
                }
            }
            if let transit = stringValue(dict["transitType"]) {
                fields["transitType"] = transit
            }
            break
        }
    }

    static func ingestBarcodes(from root: [String: Any], into fields: inout [String: Any]) {
        if let barcode = root["barcode"] as? [String: Any] {
            if let message = barcode["message"] {
                fields["barcode"] = message
            }
        }
        if let barcodes = root["barcodes"] as? [Any], let first = barcodes.first as? [String: Any] {
            if let message = first["message"] {
                fields["barcodes"] = message
            }
        }
    }

    static func ingestLocations(from root: [String: Any], into fields: inout [String: Any]) {
        guard let locations = root["locations"] as? [Any], let first = locations.first as? [String: Any] else {
            return
        }
        if let text = stringValue(first["relevantText"]) {
            fields["locationRelevantText"] = text
        }
    }

    static func requiredString(_ root: [String: Any], _ key: String) throws -> String {
        guard let value = stringValue(root[key]), !value.isEmpty else {
            throw PKPassKitError(.invalidDataError)
        }
        return value
    }

    static func stringValue(_ value: Any?) -> String? {
        if let string = value as? String { return string }
        return nil
    }

    static func intValue(_ value: Any?) -> Int? {
        if let int = value as? Int { return int }
        if let number = value as? NSNumber { return number.intValue }
        return nil
    }

    static func boolValue(_ value: Any?) -> Bool? {
        if let flag = value as? Bool { return flag }
        if let number = value as? NSNumber { return number.boolValue }
        return nil
    }

    static func parsePassDate(_ value: Any?) -> Date? {
        guard let string = stringValue(value) else { return nil }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        if let date = formatter.date(from: string) {
            return date
        }
        formatter.formatOptions = [.withFullDate]
        return formatter.date(from: string)
    }

    static func readUInt16(_ data: Data, _ offset: Int) -> UInt16 {
        let b0 = UInt16(data[offset])
        let b1 = UInt16(data[offset + 1]) << 8
        return b0 | b1
    }

    static func readUInt32(_ data: Data, _ offset: Int) -> UInt32 {
        let b0 = UInt32(data[offset])
        let b1 = UInt32(data[offset + 1]) << 8
        let b2 = UInt32(data[offset + 2]) << 16
        let b3 = UInt32(data[offset + 3]) << 24
        return b0 | b1 | b2 | b3
    }
}

/// RFC 3174 SHA-1 for `manifest.json` file hashes. Not a CMS verifier.
enum PassKitSHA1 {
    static func hexDigest(_ data: Data) -> String {
        digest(data).map { String(format: "%02x", $0) }.joined()
    }

    static func digest(_ data: Data) -> [UInt8] {
        var h0: UInt32 = 0x6745_2301
        var h1: UInt32 = 0xEFCD_AB89
        var h2: UInt32 = 0x98BA_DCFE
        var h3: UInt32 = 0x1032_5476
        var h4: UInt32 = 0xC3D2_E1F0

        var message = [UInt8](data)
        let bitCount = UInt64(message.count) * 8
        message.append(0x80)
        while (message.count % 64) != 56 {
            message.append(0)
        }
        for i in (0..<8).reversed() {
            message.append(UInt8((bitCount >> (UInt64(i) * 8)) & 0xFF))
        }

        var chunkStart = 0
        while chunkStart < message.count {
            var w = [UInt32](repeating: 0, count: 80)
            for i in 0..<16 {
                let o = chunkStart + i * 4
                w[i] = (UInt32(message[o]) << 24)
                    | (UInt32(message[o + 1]) << 16)
                    | (UInt32(message[o + 2]) << 8)
                    | UInt32(message[o + 3])
            }
            for i in 16..<80 {
                w[i] = rotateLeft(w[i - 3] ^ w[i - 8] ^ w[i - 14] ^ w[i - 16], 1)
            }
            var a = h0
            var b = h1
            var c = h2
            var d = h3
            var e = h4
            for i in 0..<80 {
                let f: UInt32
                let k: UInt32
                switch i {
                case 0..<20:
                    f = (b & c) | ((~b) & d)
                    k = 0x5A82_7999
                case 20..<40:
                    f = b ^ c ^ d
                    k = 0x6ED9_EBA1
                case 40..<60:
                    f = (b & c) | (b & d) | (c & d)
                    k = 0x8F1B_BCDC
                default:
                    f = b ^ c ^ d
                    k = 0xCA62_C1D6
                }
                let temp = rotateLeft(a, 5) &+ f &+ e &+ k &+ w[i]
                e = d
                d = c
                c = rotateLeft(b, 30)
                b = a
                a = temp
            }
            h0 = h0 &+ a
            h1 = h1 &+ b
            h2 = h2 &+ c
            h3 = h3 &+ d
            h4 = h4 &+ e
            chunkStart += 64
        }

        func bytes(_ value: UInt32) -> [UInt8] {
            [
                UInt8((value >> 24) & 0xFF),
                UInt8((value >> 16) & 0xFF),
                UInt8((value >> 8) & 0xFF),
                UInt8(value & 0xFF),
            ]
        }
        return bytes(h0) + bytes(h1) + bytes(h2) + bytes(h3) + bytes(h4)
    }

    static func rotateLeft(_ value: UInt32, _ bits: UInt32) -> UInt32 {
        (value << bits) | (value >> (32 - bits))
    }
}
