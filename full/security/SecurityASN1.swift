import Foundation

enum _SecDER {
    case integer([UInt8])
    case octetString([UInt8])
    case bitString(unused: Int, bytes: [UInt8])
    case objectIdentifier([UInt8])
    case sequence([_SecDER])
    case set([_SecDER])
    case null
    case boolean(Bool)
    case utf8String(String)
    case printableString(String)
    case ia5String(String)
    case utcTime(String)
    case generalizedTime(String)
    case context(tag: UInt8, constructed: Bool, body: [_SecDER])
    case contextPrimitive(tag: UInt8, bytes: [UInt8])
    case raw(tag: UInt8, constructed: Bool, bytes: [UInt8])

    var integerBytes: [UInt8]? {
        if case .integer(let bytes) = self { return bytes }
        return nil
    }

    var octet: [UInt8]? {
        if case .octetString(let bytes) = self { return bytes }
        return nil
    }

    var oid: [UInt8]? {
        if case .objectIdentifier(let bytes) = self { return bytes }
        return nil
    }

    var children: [_SecDER]? {
        switch self {
        case .sequence(let items), .set(let items): return items
        case .context(_, _, let items): return items
        default: return nil
        }
    }
}

enum _SecDERError: Error { case truncated, invalid, unsupported }

func _secDERParse(_ data: [UInt8]) throws -> _SecDER {
    var offset = 0
    let value = try _secDERParseOne(data, &offset)
    if offset != data.count { throw _SecDERError.invalid }
    return value
}

func _secDERParseAll(_ data: [UInt8]) throws -> [_SecDER] {
    var offset = 0
    var items: [_SecDER] = []
    while offset < data.count { items.append(try _secDERParseOne(data, &offset)) }
    return items
}

private func _secDERParseOne(_ data: [UInt8], _ offset: inout Int) throws -> _SecDER {
    guard offset < data.count else { throw _SecDERError.truncated }
    let tag = data[offset]
    offset += 1
    let (length, next) = try _secDERLength(data, offset)
    offset = next
    guard offset + length <= data.count else { throw _SecDERError.truncated }
    let body = Array(data[offset..<(offset + length)])
    offset += length
    let constructed = (tag & 0x20) != 0
    let number = tag & 0x1f
    if tag & 0xc0 == 0x80 {
        if constructed {
            return .context(tag: number, constructed: true, body: try _secDERParseAll(body))
        }
        return .contextPrimitive(tag: number, bytes: body)
    }
    switch tag {
    case 0x01:
        return .boolean(body.first == 0xff)
    case 0x02:
        return .integer(body)
    case 0x03:
        guard let unused = body.first else { throw _SecDERError.invalid }
        return .bitString(unused: Int(unused), bytes: Array(body.dropFirst()))
    case 0x04:
        return .octetString(body)
    case 0x05:
        return .null
    case 0x06:
        return .objectIdentifier(body)
    case 0x0c:
        return .utf8String(String(bytes: body, encoding: .utf8) ?? "")
    case 0x13:
        return .printableString(String(bytes: body, encoding: .ascii) ?? "")
    case 0x16:
        return .ia5String(String(bytes: body, encoding: .ascii) ?? "")
    case 0x17:
        return .utcTime(String(bytes: body, encoding: .ascii) ?? "")
    case 0x18:
        return .generalizedTime(String(bytes: body, encoding: .ascii) ?? "")
    case 0x30:
        return .sequence(try _secDERParseAll(body))
    case 0x31:
        return .set(try _secDERParseAll(body))
    default:
        return .raw(tag: tag, constructed: constructed, bytes: body)
    }
}

private func _secDERLength(_ data: [UInt8], _ offset: Int) throws -> (Int, Int) {
    guard offset < data.count else { throw _SecDERError.truncated }
    let first = data[offset]
    if first & 0x80 == 0 { return (Int(first), offset + 1) }
    let count = Int(first & 0x7f)
    guard count > 0, offset + 1 + count <= data.count else { throw _SecDERError.truncated }
    var length = 0
    for byte in data[(offset + 1)..<(offset + 1 + count)] {
        length = (length << 8) | Int(byte)
    }
    return (length, offset + 1 + count)
}

func _secDERHeaderLength(_ data: [UInt8], offset: Int) -> (headerSize: Int, bodyLength: Int)? {
    guard offset < data.count else { return nil }
    let pos = offset + 1
    guard pos < data.count else { return nil }
    let first = data[pos]
    if first & 0x80 == 0 {
        return (2, Int(first))
    }
    let count = Int(first & 0x7f)
    guard count > 0, pos + 1 + count <= data.count else { return nil }
    var value = 0
    for index in 0..<count {
        value = (value << 8) | Int(data[pos + 1 + index])
    }
    return (1 + 1 + count, value)
}

func _secDERFirstChildTLV(_ data: [UInt8]) -> [UInt8]? {
    guard let (header, length) = _secDERHeaderLength(data, offset: 0) else { return nil }
    let contentStart = header
    let contentEnd = header + length
    guard contentEnd <= data.count else { return nil }
    guard let (childHeader, childLen) = _secDERHeaderLength(data, offset: contentStart) else { return nil }
    let childEnd = contentStart + childHeader + childLen
    guard childEnd <= contentEnd else { return nil }
    return Array(data[contentStart..<childEnd])
}

func _secDEREncode(_ value: _SecDER) -> [UInt8] {
    switch value {
    case .integer(let bytes):
        return _secDERTLV(0x02, bytes)
    case .octetString(let bytes):
        return _secDERTLV(0x04, bytes)
    case .bitString(let unused, let bytes):
        return _secDERTLV(0x03, [UInt8(unused)] + bytes)
    case .objectIdentifier(let bytes):
        return _secDERTLV(0x06, bytes)
    case .sequence(let items):
        return _secDERTLV(0x30, items.flatMap(_secDEREncode))
    case .set(let items):
        return _secDERTLV(0x31, items.flatMap(_secDEREncode))
    case .null:
        return [0x05, 0x00]
    case .boolean(let flag):
        return [0x01, 0x01, flag ? 0xff : 0x00]
    case .utf8String(let text):
        return _secDERTLV(0x0c, Array(text.utf8))
    case .printableString(let text):
        return _secDERTLV(0x13, Array(text.utf8))
    case .ia5String(let text):
        return _secDERTLV(0x16, Array(text.utf8))
    case .utcTime(let text):
        return _secDERTLV(0x17, Array(text.utf8))
    case .generalizedTime(let text):
        return _secDERTLV(0x18, Array(text.utf8))
    case .context(let tag, let constructed, let body):
        let t = 0x80 | (constructed ? 0x20 : 0) | tag
        return _secDERTLV(t, body.flatMap(_secDEREncode))
    case .contextPrimitive(let tag, let bytes):
        return _secDERTLV(0x80 | tag, bytes)
    case .raw(let tag, _, let bytes):
        return _secDERTLV(tag, bytes)
    }
}

func _secDERTLV(_ tag: UInt8, _ body: [UInt8]) -> [UInt8] {
    var out = [tag]
    let length = body.count
    if length < 0x80 {
        out.append(UInt8(length))
    } else if length < 0x100 {
        out.append(0x81); out.append(UInt8(length))
    } else if length < 0x10000 {
        out.append(0x82)
        out.append(UInt8(length >> 8))
        out.append(UInt8(truncatingIfNeeded: length))
    } else {
        out.append(0x83)
        out.append(UInt8(length >> 16))
        out.append(UInt8(length >> 8))
        out.append(UInt8(truncatingIfNeeded: length))
    }
    out.append(contentsOf: body)
    return out
}

func _secDERInteger(_ value: _SecInt) -> _SecDER {
    var bytes = value.bigEndianBytes()
    if bytes.isEmpty { bytes = [0] }
    if let first = bytes.first, first & 0x80 != 0 { bytes.insert(0, at: 0) }
    return .integer(bytes)
}

func _secIntFromDER(_ node: _SecDER) -> _SecInt? {
    guard var bytes = node.integerBytes else { return nil }
    if bytes.first == 0 { bytes.removeFirst() }
    return _SecInt(bytes: bytes)
}

func _secOID(_ text: String) -> [UInt8] {
    let parts = text.split(separator: Character(".")).compactMap { Int($0) }
    guard parts.count >= 2 else { return [] }
    var body: [UInt8] = [UInt8(parts[0] * 40 + parts[1])]
    for part in parts.dropFirst(2) {
        var value = part
        var stack: [UInt8] = [UInt8(value & 0x7f)]
        value >>= 7
        while value > 0 {
            stack.append(UInt8((value & 0x7f) | 0x80))
            value >>= 7
        }
        body.append(contentsOf: stack.reversed())
    }
    return body
}

func _secOIDString(_ body: [UInt8]) -> String {
    guard let first = body.first else { return "" }
    var parts = [Int(first / 40), Int(first % 40)]
    var value = 0
    for byte in body.dropFirst() {
        value = (value << 7) | Int(byte & 0x7f)
        if byte & 0x80 == 0 {
            parts.append(value)
            value = 0
        }
    }
    return parts.map(String.init).joined(separator: ".")
}

let _oidRSAEncryption = _secOID("1.2.840.113549.1.1.1")
let _oidECPublicKey = _secOID("1.2.840.10045.2.1")
let _oidPrime256v1 = _secOID("1.2.840.10045.3.1.7")
let _oidSecp384r1 = _secOID("1.3.132.0.34")
let _oidSecp521r1 = _secOID("1.3.132.0.35")
let _oidSha256WithRSA = _secOID("1.2.840.113549.1.1.11")
let _oidSha1WithRSA = _secOID("1.2.840.113549.1.1.5")
let _oidEcdsaWithSHA256 = _secOID("1.2.840.10045.4.3.2")
let _oidEcdsaWithSHA384 = _secOID("1.2.840.10045.4.3.3")
let _oidEcdsaWithSHA512 = _secOID("1.2.840.10045.4.3.4")
let _oidCommonName = _secOID("2.5.4.3")
let _oidOrganizationName = _secOID("2.5.4.10")
let _oidSubjectAltName = _secOID("2.5.29.17")
let _oidEmailAddress = _secOID("1.2.840.113549.1.9.1")
let _oidPkcs7Data = _secOID("1.2.840.113549.1.7.1")
let _oidPkcs12CertBag = _secOID("1.2.840.113549.1.12.10.1.3")
let _oidPkcs12KeyBag = _secOID("1.2.840.113549.1.12.10.1.1")
let _oidPkcs12ShroudedKeyBag = _secOID("1.2.840.113549.1.12.10.1.2")
let _oidX509Certificate = _secOID("1.2.840.113549.1.9.22.1")
let _oidPkcs8 = _secOID("1.2.840.113549.1.12.10.1.1")
