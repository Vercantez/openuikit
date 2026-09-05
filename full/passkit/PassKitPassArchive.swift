import Foundation

/// Stored-method ZIP reader for `.pkpass` plus `pass.json` field mapping.
///
/// A pkpass is a ZIP (APPNOTE.TXT) whose payload is Apple's documented Wallet
/// pass dictionary. This host unpacks compression method 0 (stored) and
/// reads those keys; it does not inflate method 8 and does not verify the
/// CMS signature. Unsigned stored archives are accepted as structure, not as
/// trusted passes.
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
        guard let jsonData = passJSON(in: files) else {
            throw PKPassKitError(.invalidDataError)
        }
        return try manifest(fromJSON: jsonData)
    }

    static func passJSON(in files: [String: Data]) -> Data? {
        for (name, payload) in files {
            if lastPathComponent(name) == "pass.json" {
                return payload
            }
        }
        return nil
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
