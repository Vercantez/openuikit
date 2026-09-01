import Foundation

public enum NFCTypeNameFormat: UInt8, Hashable, Sendable {
    case empty = 0x00
    case nfcWellKnown = 0x01
    case media = 0x02
    case absoluteURI = 0x03
    case nfcExternal = 0x04
    case unknown = 0x05
    case unchanged = 0x06
}

public enum NFCNDEFStatus: UInt, Hashable, Sendable {
    case notSupported = 1
    case readWrite = 2
    case readOnly = 3
}

/// NFC Forum NDEF record. Encoding and well-known Text/URI helpers follow the
/// public NFC Forum Record Type Definition; they do not talk to a radio.
open class NFCNDEFPayload: NSObject {
    public var typeNameFormat: NFCTypeNameFormat
    public var type: Data
    public var identifier: Data
    public var payload: Data
    var chunkSize: Int

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

    open class func wellKnownTypeURIPayload(string uri: String) -> Self? {
        guard let payload = _nfcEncodeURIPayload(uri) else { return nil }
        return self.init(
            format: .nfcWellKnown,
            type: Data([0x55]),
            identifier: Data(),
            payload: payload
        )
    }

    open class func wellKnownTypeURIPayload(url: URL) -> Self? {
        wellKnownTypeURIPayload(string: url.absoluteString)
    }

    open class func wellKnownTypeTextPayload(string text: String, locale: Locale) -> Self? {
        guard let payload = _nfcEncodeTextPayload(text, locale: locale) else {
            return nil
        }
        return self.init(
            format: .nfcWellKnown,
            type: Data([0x54]),
            identifier: Data(),
            payload: payload
        )
    }

    /// Historical Apple misspelling of `wellKnownTypeTextPayload(string:locale:)`.
    open class func wellKnowTypeTextPayload(string text: String, locale: Locale) -> Self? {
        wellKnownTypeTextPayload(string: text, locale: locale)
    }

    open func wellKnownTypeURIPayload() -> URL? {
        guard typeNameFormat == .nfcWellKnown,
              type == Data([0x55]),
              let string = _nfcDecodeURIPayload(payload)
        else {
            return nil
        }
        return URL(string: string)
    }

    open func wellKnownTypeTextPayload() -> (String?, Locale?) {
        guard typeNameFormat == .nfcWellKnown, type == Data([0x54]) else {
            return (nil, nil)
        }
        return _nfcDecodeTextPayload(payload)
    }
}

/// NFC Forum NDEF message: ordered records plus binary encode/decode.
open class NFCNDEFMessage: NSObject {
    public var records: [NFCNDEFPayload]

    public init(records: [NFCNDEFPayload]) {
        self.records = records
        super.init()
    }

    public init(NDEFRecords records: [NFCNDEFPayload]) {
        self.records = records
        super.init()
    }

    public convenience init?(data: Data) {
        guard let records = _nfcParseNDEFMessage(data) else { return nil }
        self.init(records: records)
    }

    public var length: Int {
        _nfcEncodeNDEFMessage(records).count
    }
}

private let _nfcURIPrefixes: [(UInt8, String)] = [
    (0x01, "http://www."),
    (0x02, "https://www."),
    (0x03, "http://"),
    (0x04, "https://"),
    (0x05, "tel:"),
    (0x06, "mailto:"),
    (0x07, "ftp://anonymous:anonymous@"),
    (0x08, "ftp://ftp."),
    (0x09, "ftps://"),
    (0x0A, "sftp://"),
    (0x0B, "smb://"),
    (0x0C, "nfs://"),
    (0x0D, "ftp://"),
    (0x0E, "dav://"),
    (0x0F, "news:"),
    (0x10, "telnet://"),
    (0x11, "imap:"),
    (0x12, "rtsp://"),
    (0x13, "urn:"),
    (0x14, "pop:"),
    (0x15, "sip:"),
    (0x16, "sips:"),
    (0x17, "tftp:"),
    (0x18, "btspp://"),
    (0x19, "btl2cap://"),
    (0x1A, "btgoep://"),
    (0x1B, "tcpobex://"),
    (0x1C, "irdaobex://"),
    (0x1D, "file://"),
    (0x1E, "urn:epc:id:"),
    (0x1F, "urn:epc:tag:"),
    (0x20, "urn:epc:pat:"),
    (0x21, "urn:epc:raw:"),
    (0x22, "urn:epc:"),
    (0x23, "urn:nfc:"),
]

private func _nfcEncodeURIPayload(_ uri: String) -> Data? {
    guard !uri.isEmpty else { return nil }
    let match = _nfcURIPrefixes
        .filter { uri.hasPrefix($0.1) }
        .max(by: { $0.1.count < $1.1.count })
    let code = match?.0 ?? 0x00
    let remainder = match.map { String(uri.dropFirst($0.1.count)) } ?? uri
    var data = Data([code])
    data.append(contentsOf: remainder.utf8)
    return data
}

private func _nfcDecodeURIPayload(_ payload: Data) -> String? {
    guard let code = payload.first else { return nil }
    let remainder = String(decoding: payload.dropFirst(), as: UTF8.self)
    if let prefix = _nfcURIPrefixes.first(where: { $0.0 == code })?.1 {
        return prefix + remainder
    }
    if code == 0x00 {
        return remainder
    }
    return nil
}

private func _nfcLanguageCode(from locale: Locale) -> String {
    if let code = locale.language.languageCode?.identifier, !code.isEmpty {
        return String(code.prefix(63))
    }
    let identifier = locale.identifier
    let head = identifier.split(separator: "_").first.map(String.init) ?? "en"
    return String(head.prefix(63))
}

private func _nfcEncodeTextPayload(_ text: String, locale: Locale) -> Data? {
    let language = _nfcLanguageCode(from: locale)
    let languageBytes = Array(language.utf8)
    guard languageBytes.count <= 63 else { return nil }
    var data = Data([UInt8(languageBytes.count)])
    data.append(contentsOf: languageBytes)
    data.append(contentsOf: text.utf8)
    return data
}

private func _nfcDecodeTextPayload(_ payload: Data) -> (String?, Locale?) {
    guard let status = payload.first else { return (nil, nil) }
    let languageLength = Int(status & 0x3F)
    let isUTF16 = (status & 0x80) != 0
    guard payload.count >= 1 + languageLength else { return (nil, nil) }
    let languageBytes = payload.dropFirst().prefix(languageLength)
    let language = String(decoding: languageBytes, as: UTF8.self)
    let textBytes = payload.dropFirst(1 + languageLength)
    let text: String
    if isUTF16 {
        let units = textBytes.withUnsafeBytes { buffer -> [UInt16] in
            let raw = buffer.bindMemory(to: UInt16.self)
            return Array(raw)
        }
        text = String(utf16CodeUnits: units, count: units.count)
    } else {
        text = String(decoding: textBytes, as: UTF8.self)
    }
    let locale = language.isEmpty ? Locale(identifier: "en") : Locale(identifier: language)
    return (text, locale)
}

private struct _NDEFHeader {
    var messageBegin: Bool
    var messageEnd: Bool
    var chunkFlag: Bool
    var shortRecord: Bool
    var idLengthPresent: Bool
    var typeNameFormat: NFCTypeNameFormat
    var type: Data
    var identifier: Data
    var payload: Data
}

private func _nfcEncodeRecord(_ record: NFCNDEFPayload, mb: Bool, me: Bool) -> Data {
    let chunks: [Data]
    if record.chunkSize > 0, record.payload.count > record.chunkSize {
        var slices: [Data] = []
        var remaining = record.payload
        while remaining.count > record.chunkSize {
            slices.append(remaining.prefix(record.chunkSize))
            remaining = remaining.dropFirst(record.chunkSize)
        }
        slices.append(remaining)
        chunks = slices
    } else {
        chunks = [record.payload]
    }

    var encoded = Data()
    for (index, chunk) in chunks.enumerated() {
        let first = index == 0
        let last = index == chunks.count - 1
        let header = _NDEFHeader(
            messageBegin: mb && first,
            messageEnd: me && last,
            chunkFlag: !last && chunks.count > 1,
            shortRecord: chunk.count <= 255,
            idLengthPresent: first && !record.identifier.isEmpty,
            typeNameFormat: first ? record.typeNameFormat : .unchanged,
            type: first ? record.type : Data(),
            identifier: first ? record.identifier : Data(),
            payload: chunk
        )
        encoded.append(_nfcEncodeHeader(header))
    }
    return encoded
}

private func _nfcEncodeHeader(_ header: _NDEFHeader) -> Data {
    var flags: UInt8 = header.typeNameFormat.rawValue & 0x07
    if header.messageBegin { flags |= 0x80 }
    if header.messageEnd { flags |= 0x40 }
    if header.chunkFlag { flags |= 0x20 }
    if header.shortRecord { flags |= 0x10 }
    if header.idLengthPresent { flags |= 0x08 }
    var data = Data([flags, UInt8(truncatingIfNeeded: header.type.count)])
    if header.shortRecord {
        data.append(UInt8(truncatingIfNeeded: header.payload.count))
    } else {
        var length = UInt32(header.payload.count).bigEndian
        withUnsafeBytes(of: &length) { data.append(contentsOf: $0) }
    }
    if header.idLengthPresent {
        data.append(UInt8(truncatingIfNeeded: header.identifier.count))
    }
    data.append(header.type)
    if header.idLengthPresent {
        data.append(header.identifier)
    }
    data.append(header.payload)
    return data
}

func _nfcEncodeNDEFMessage(_ records: [NFCNDEFPayload]) -> Data {
    guard !records.isEmpty else { return Data() }
    var data = Data()
    for (index, record) in records.enumerated() {
        data.append(
            _nfcEncodeRecord(
                record,
                mb: index == 0,
                me: index == records.count - 1
            )
        )
    }
    return data
}

private func _nfcParseNDEFMessage(_ data: Data) -> [NFCNDEFPayload]? {
    var offset = 0
    var records: [NFCNDEFPayload] = []
    var assembling: (NFCTypeNameFormat, Data, Data, Data)?
    var sawMessageEnd = false
    if data.isEmpty { return [] }
    while offset < data.count {
        guard let parsed = _nfcParseHeader(data, offset: &offset) else { return nil }
        if parsed.chunkFlag {
            if assembling == nil {
                assembling = (parsed.typeNameFormat, parsed.type, parsed.identifier, parsed.payload)
            } else {
                assembling?.3.append(parsed.payload)
            }
        } else if var current = assembling {
            current.3.append(parsed.payload)
            records.append(
                NFCNDEFPayload(
                    format: current.0,
                    type: current.1,
                    identifier: current.2,
                    payload: current.3
                )
            )
            assembling = nil
        } else {
            records.append(
                NFCNDEFPayload(
                    format: parsed.typeNameFormat,
                    type: parsed.type,
                    identifier: parsed.identifier,
                    payload: parsed.payload
                )
            )
        }
        if parsed.messageEnd {
            sawMessageEnd = true
            break
        }
    }
    if assembling != nil { return nil }
    if !sawMessageEnd { return nil }
    return records
}

private func _nfcParseHeader(_ data: Data, offset: inout Int) -> _NDEFHeader? {
    guard offset < data.count else { return nil }
    let flags = data[offset]
    offset += 1
    let tnf = NFCTypeNameFormat(rawValue: flags & 0x07) ?? .unknown
    let mb = (flags & 0x80) != 0
    let me = (flags & 0x40) != 0
    let cf = (flags & 0x20) != 0
    let sr = (flags & 0x10) != 0
    let il = (flags & 0x08) != 0
    guard offset < data.count else { return nil }
    let typeLength = Int(data[offset])
    offset += 1
    let payloadLength: Int
    if sr {
        guard offset < data.count else { return nil }
        payloadLength = Int(data[offset])
        offset += 1
    } else {
        guard offset + 4 <= data.count else { return nil }
        payloadLength = Int(
            UInt32(data[offset]) << 24
                | UInt32(data[offset + 1]) << 16
                | UInt32(data[offset + 2]) << 8
                | UInt32(data[offset + 3])
        )
        offset += 4
    }
    var idLength = 0
    if il {
        guard offset < data.count else { return nil }
        idLength = Int(data[offset])
        offset += 1
    }
    guard offset + typeLength + idLength + payloadLength <= data.count else {
        return nil
    }
    let type = data.subdata(in: offset..<(offset + typeLength))
    offset += typeLength
    let identifier = data.subdata(in: offset..<(offset + idLength))
    offset += idLength
    let payload = data.subdata(in: offset..<(offset + payloadLength))
    offset += payloadLength
    return _NDEFHeader(
        messageBegin: mb,
        messageEnd: me,
        chunkFlag: cf,
        shortRecord: sr,
        idLengthPresent: il,
        typeNameFormat: tnf,
        type: type,
        identifier: identifier,
        payload: payload
    )
}
