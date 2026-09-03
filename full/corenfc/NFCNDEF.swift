import Foundation

// NDEF record encoding follows the public NFC Forum NDEF 1.0 layout
// (MB/ME/CF/SR/IL/TNF header, type, optional ID, payload). This is
// software-only message construction, not a claim of Apple radio behavior.

private let ndefURIPrefixes: [String] = [
    "",
    "http://www.",
    "https://www.",
    "http://",
    "https://",
    "tel:",
    "mailto:",
    "ftp://anonymous:anonymous@",
    "ftp://ftp.",
    "ftps://",
    "sftp://",
    "smb://",
    "nfs://",
    "ftp://",
    "dav://",
    "news:",
    "telnet://",
    "imap:",
    "rtsp://",
    "urn:",
    "pop:",
    "sip:",
    "sips:",
    "tftp:",
    "btspp://",
    "btl2cap://",
    "btgoep://",
    "tcpobex://",
    "irdaobex://",
    "file://",
    "urn:epc:id:",
    "urn:epc:tag:",
    "urn:epc:pat:",
    "urn:epc:raw:",
    "urn:epc:",
    "urn:nfc:",
]

public class NFCNDEFPayload: NSObject, NSSecureCoding {
    public var typeNameFormat: NFCTypeNameFormat
    public var type: Data
    public var identifier: Data
    public var payload: Data
    public var chunkSize: Int

    public static var supportsSecureCoding: Bool { true }

    public required init(
        format: NFCTypeNameFormat,
        type: Data,
        identifier: Data,
        payload: Data
    ) {
        self.typeNameFormat = format
        self.type = type
        self.identifier = identifier
        self.payload = payload
        self.chunkSize = 0
        super.init()
    }

    public required init(
        format: NFCTypeNameFormat,
        type: Data,
        identifier: Data,
        payload: Data,
        chunkSize: Int
    ) {
        self.typeNameFormat = format
        self.type = type
        self.identifier = identifier
        self.payload = payload
        self.chunkSize = max(0, chunkSize)
        super.init()
    }

    public required init?(coder: NSCoder) {
        let formatRaw = UInt8(truncatingIfNeeded: coder.decodeInteger(forKey: "typeNameFormat"))
        guard let format = NFCTypeNameFormat(rawValue: formatRaw) else {
            return nil
        }
        guard let type = coder.decodeObject(of: NSData.self, forKey: "type") as Data? else {
            return nil
        }
        guard let identifier = coder.decodeObject(of: NSData.self, forKey: "identifier") as Data? else {
            return nil
        }
        guard let payload = coder.decodeObject(of: NSData.self, forKey: "payload") as Data? else {
            return nil
        }
        self.typeNameFormat = format
        self.type = type
        self.identifier = identifier
        self.payload = payload
        self.chunkSize = coder.decodeInteger(forKey: "chunkSize")
        super.init()
    }

    public func encode(with coder: NSCoder) {
        coder.encode(Int(typeNameFormat.rawValue), forKey: "typeNameFormat")
        coder.encode(type as NSData, forKey: "type")
        coder.encode(identifier as NSData, forKey: "identifier")
        coder.encode(payload as NSData, forKey: "payload")
        coder.encode(chunkSize, forKey: "chunkSize")
    }

    public class func wellKnownTypeURIPayload(string uri: String) -> Self? {
        guard let encoded = encodeURIPayload(uri) else {
            return nil
        }
        return Self(
            format: .nfcWellKnown,
            type: Data([0x55]),
            identifier: Data(),
            payload: encoded
        )
    }

    public class func wellKnownTypeURIPayload(url: URL) -> Self? {
        wellKnownTypeURIPayload(string: url.absoluteString)
    }

    public class func wellKnownTypeTextPayload(string text: String, locale: Locale) -> Self? {
        guard let encoded = encodeTextPayload(text: text, locale: locale) else {
            return nil
        }
        return Self(
            format: .nfcWellKnown,
            type: Data([0x54]),
            identifier: Data(),
            payload: encoded
        )
    }

    /// Apple's historical misspelling, preserved as a distinct public entry.
    public class func wellKnowTypeTextPayload(string text: String, locale: Locale) -> Self? {
        wellKnownTypeTextPayload(string: text, locale: locale)
    }

    public func wellKnownTypeURIPayload() -> URL? {
        guard typeNameFormat == .nfcWellKnown, type == Data([0x55]) else {
            return nil
        }
        guard let string = decodeURIPayload(payload) else {
            return nil
        }
        return URL(string: string)
    }

    public func wellKnownTypeTextPayload() -> (String?, Locale?) {
        guard typeNameFormat == .nfcWellKnown, type == Data([0x54]) else {
            return (nil, nil)
        }
        return decodeTextPayload(payload)
    }

    func encodeRecord(messageBegin: Bool, messageEnd: Bool) -> Data {
        encodeNDEFRecord(
            format: typeNameFormat,
            type: type,
            identifier: identifier,
            payload: payload,
            messageBegin: messageBegin,
            messageEnd: messageEnd
        )
    }
}

public class NFCNDEFMessage: NSObject, NSSecureCoding {
    public var records: [NFCNDEFPayload]

    public static var supportsSecureCoding: Bool { true }

    public init(records: [NFCNDEFPayload]) {
        self.records = records
        super.init()
    }

    public init(NDEFRecords records: [NFCNDEFPayload]) {
        self.records = records
        super.init()
    }

    public convenience init?(data: Data) {
        guard let decoded = decodeNDEFMessage(data) else {
            return nil
        }
        self.init(records: decoded)
    }

    public required init?(coder: NSCoder) {
        guard let stored = coder.decodeObject(
            of: [NSArray.self, NFCNDEFPayload.self],
            forKey: "records"
        ) as? [NFCNDEFPayload] else {
            return nil
        }
        self.records = stored
        super.init()
    }

    public func encode(with coder: NSCoder) {
        coder.encode(records as NSArray, forKey: "records")
    }

    public var length: Int {
        encodedData().count
    }

    public func encodedData() -> Data {
        guard !records.isEmpty else {
            return Data()
        }
        var encoded = Data()
        for (index, record) in records.enumerated() {
            encoded.append(
                record.encodeRecord(
                    messageBegin: index == 0,
                    messageEnd: index == records.count - 1
                )
            )
        }
        return encoded
    }
}

private func encodeURIPayload(_ uri: String) -> Data? {
    guard !uri.isEmpty else {
        return nil
    }
    var bestCode = 0
    var bestPrefix = ""
    for (code, prefix) in ndefURIPrefixes.enumerated() where !prefix.isEmpty {
        if uri.hasPrefix(prefix), prefix.count > bestPrefix.count {
            bestCode = code
            bestPrefix = prefix
        }
    }
    let remainder = String(uri.dropFirst(bestPrefix.count))
    var payload = Data([UInt8(bestCode)])
    payload.append(Data(remainder.utf8))
    return payload
}

private func decodeURIPayload(_ payload: Data) -> String? {
    guard let code = payload.first else {
        return nil
    }
    let remainder = String(decoding: payload.dropFirst(), as: UTF8.self)
    if Int(code) < ndefURIPrefixes.count {
        return ndefURIPrefixes[Int(code)] + remainder
    }
    return remainder
}

private func encodeTextPayload(text: String, locale: Locale) -> Data? {
    let language = (locale.language.languageCode?.identifier ?? locale.identifier)
        .split(separator: "-")
        .first
        .map(String.init)?
        .lowercased() ?? "en"
    let languageBytes = Array(language.utf8)
    guard languageBytes.count <= 32, !languageBytes.isEmpty else {
        return nil
    }
    var payload = Data([UInt8(languageBytes.count & 0x3F)])
    payload.append(Data(languageBytes))
    payload.append(Data(text.utf8))
    return payload
}

private func decodeTextPayload(_ payload: Data) -> (String?, Locale?) {
    guard let status = payload.first else {
        return (nil, nil)
    }
    let languageLength = Int(status & 0x3F)
    let utf16 = (status & 0x80) != 0
    guard payload.count >= 1 + languageLength else {
        return (nil, nil)
    }
    let languageData = payload.dropFirst().prefix(languageLength)
    let language = String(decoding: languageData, as: UTF8.self)
    let body = payload.dropFirst(1 + languageLength)
    let text: String
    if utf16 {
        text = body.withUnsafeBytes { raw in
            let count = raw.count / 2
            guard count > 0 else {
                return ""
            }
            let pointer = raw.bindMemory(to: UInt16.self)
            var units: [UInt16] = []
            units.reserveCapacity(count)
            for index in 0..<count {
                units.append(UInt16(bigEndian: pointer[index]))
            }
            return String(utf16CodeUnits: units, count: units.count)
        }
    } else {
        text = String(decoding: body, as: UTF8.self)
    }
    return (text, Locale(identifier: language))
}

func encodeNDEFRecord(
    format: NFCTypeNameFormat,
    type: Data,
    identifier: Data,
    payload: Data,
    messageBegin: Bool,
    messageEnd: Bool
) -> Data {
    let shortRecord = payload.count < 256
    let hasID = !identifier.isEmpty
    var header: UInt8 = format.rawValue & 0x07
    if messageBegin { header |= 0x80 }
    if messageEnd { header |= 0x40 }
    if shortRecord { header |= 0x10 }
    if hasID { header |= 0x08 }
    var data = Data([header, UInt8(clamping: type.count)])
    if shortRecord {
        data.append(UInt8(payload.count))
    } else {
        var length = UInt32(payload.count).bigEndian
        withUnsafeBytes(of: &length) { data.append(contentsOf: $0) }
    }
    if hasID {
        data.append(UInt8(clamping: identifier.count))
    }
    data.append(type)
    if hasID {
        data.append(identifier)
    }
    data.append(payload)
    return data
}

func decodeNDEFMessage(_ data: Data) -> [NFCNDEFPayload]? {
    guard !data.isEmpty else {
        return nil
    }
    var records: [NFCNDEFPayload] = []
    var offset = 0
    var sawMessageEnd = false
    while offset < data.count {
        if sawMessageEnd {
            return nil
        }
        let header = data[offset]
        offset += 1
        let tnf = NFCTypeNameFormat(rawValue: header & 0x07) ?? .unknown
        let messageBegin = (header & 0x80) != 0
        let messageEnd = (header & 0x40) != 0
        let chunked = (header & 0x20) != 0
        let shortRecord = (header & 0x10) != 0
        let hasID = (header & 0x08) != 0
        if chunked {
            return nil
        }
        if records.isEmpty != messageBegin {
            return nil
        }
        guard offset < data.count else {
            return nil
        }
        let typeLength = Int(data[offset])
        offset += 1
        let payloadLength: Int
        if shortRecord {
            guard offset < data.count else {
                return nil
            }
            payloadLength = Int(data[offset])
            offset += 1
        } else {
            guard offset + 4 <= data.count else {
                return nil
            }
            var value: UInt32 = 0
            for _ in 0..<4 {
                value = (value << 8) | UInt32(data[offset])
                offset += 1
            }
            payloadLength = Int(value)
        }
        var idLength = 0
        if hasID {
            guard offset < data.count else {
                return nil
            }
            idLength = Int(data[offset])
            offset += 1
        }
        guard offset + typeLength + idLength + payloadLength <= data.count else {
            return nil
        }
        let type = Data(data[offset..<(offset + typeLength)])
        offset += typeLength
        let identifier = Data(data[offset..<(offset + idLength)])
        offset += idLength
        let payload = Data(data[offset..<(offset + payloadLength)])
        offset += payloadLength
        records.append(
            NFCNDEFPayload(format: tnf, type: type, identifier: identifier, payload: payload)
        )
        sawMessageEnd = messageEnd
    }
    guard sawMessageEnd, !records.isEmpty else {
        return nil
    }
    return records
}
