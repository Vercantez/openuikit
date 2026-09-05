import Foundation

// ANSI X9.63 / SEC1 / SPKI / PKCS#8 encodings used by CryptoKit's NIST keys.
// Layouts match the iPhoneOS 26.1 symbol-graph sizes: raw is x||y (no prefix),
// x963 public is 04||x||y, x963 private is 04||x||y||d, compact is x when y is even.

func _ckCoordBytes(_ value: _CKNat, length: Int) -> Data {
    Data(_ckNatToBE(value, length: length))
}

func _ckRawPublic(_ point: _NISTPoint, _ curve: _NISTCurve) -> Data {
    _ckCoordBytes(point.x, length: curve.coordinateByteCount)
        + _ckCoordBytes(point.y, length: curve.coordinateByteCount)
}

func _ckX963Public(_ point: _NISTPoint, _ curve: _NISTCurve) -> Data {
    Data([0x04]) + _ckRawPublic(point, curve)
}

func _ckCompressedPublic(_ point: _NISTPoint, _ curve: _NISTCurve) -> Data {
    Data([point.y.bit(0) ? 0x03 : 0x02]) + _ckCoordBytes(point.x, length: curve.coordinateByteCount)
}

func _ckCompactPublic(_ point: _NISTPoint, _ curve: _NISTCurve) -> Data? {
    guard !point.y.bit(0) else { return nil }
    return _ckCoordBytes(point.x, length: curve.coordinateByteCount)
}

func _ckX963Private(_ scalar: _CKNat, _ point: _NISTPoint, _ curve: _NISTCurve) -> Data {
    _ckX963Public(point, curve) + _ckCoordBytes(scalar, length: curve.coordinateByteCount)
}

func _ckParseRawPublic(_ data: Data, _ curve: _NISTCurve) throws -> _NISTPoint {
    let bytes = Array(data)
    let n = curve.coordinateByteCount
    guard bytes.count == 2 * n else { throw CryptoKitError.incorrectKeySize }
    let x = _ckNatFromBE(Array(bytes[0..<n]))
    let y = _ckNatFromBE(Array(bytes[n..<(2 * n)]))
    let point = _NISTPoint.affine(x, y)
    guard _nistOnCurve(point, curve) else { throw CryptoKitError.incorrectParameterSize }
    return point
}

func _ckParseX963Public(_ data: Data, _ curve: _NISTCurve) throws -> _NISTPoint {
    let bytes = Array(data)
    let n = curve.coordinateByteCount
    if bytes.count == 1 + n, bytes[0] == 0x02 || bytes[0] == 0x03 {
        return try _ckParseCompressedPublic(data, curve)
    }
    guard bytes.count == 1 + 2 * n, bytes[0] == 0x04 else {
        throw CryptoKitError.incorrectParameterSize
    }
    return try _ckParseRawPublic(Data(bytes[1...]), curve)
}

func _ckParseCompressedPublic(_ data: Data, _ curve: _NISTCurve) throws -> _NISTPoint {
    let bytes = Array(data)
    let n = curve.coordinateByteCount
    guard bytes.count == 1 + n, bytes[0] == 0x02 || bytes[0] == 0x03 else {
        throw CryptoKitError.incorrectParameterSize
    }
    let x = _ckNatFromBE(Array(bytes[1...]))
    let even = bytes[0] == 0x02
    guard let y = _nistYFromX(x, even: even, curve) else {
        throw CryptoKitError.incorrectParameterSize
    }
    let point = _NISTPoint.affine(x, y)
    guard _nistOnCurve(point, curve) else { throw CryptoKitError.incorrectParameterSize }
    return point
}

func _ckParseCompactPublic(_ data: Data, _ curve: _NISTCurve) throws -> _NISTPoint {
    let bytes = Array(data)
    let n = curve.coordinateByteCount
    guard bytes.count == n else { throw CryptoKitError.incorrectParameterSize }
    let x = _ckNatFromBE(bytes)
    guard let y = _nistYFromX(x, even: true, curve) else {
        throw CryptoKitError.incorrectParameterSize
    }
    let point = _NISTPoint.affine(x, y)
    guard _nistOnCurve(point, curve) else { throw CryptoKitError.incorrectParameterSize }
    return point
}

func _ckParsePrivateScalar(_ data: Data, _ curve: _NISTCurve) throws -> _CKNat {
    let bytes = Array(data)
    guard bytes.count == curve.coordinateByteCount else { throw CryptoKitError.incorrectKeySize }
    let scalar = _ckNatFromBE(bytes)
    guard _nistIsValidScalar(scalar, curve) else { throw CryptoKitError.incorrectParameterSize }
    return scalar
}

func _ckParseX963Private(_ data: Data, _ curve: _NISTCurve) throws -> (_CKNat, _NISTPoint) {
    let bytes = Array(data)
    let n = curve.coordinateByteCount
    guard bytes.count == 1 + 3 * n, bytes[0] == 0x04 else {
        throw CryptoKitError.incorrectParameterSize
    }
    let point = try _ckParseRawPublic(Data(bytes[1..<(1 + 2 * n)]), curve)
    let scalar = try _ckParsePrivateScalar(Data(bytes[(1 + 2 * n)...]), curve)
    let expected = _nistPublicPoint(scalar, curve)
    guard expected.x == point.x, expected.y == point.y else {
        throw CryptoKitError.incorrectParameterSize
    }
    return (scalar, point)
}

func _asn1Length(_ count: Int) -> [UInt8] {
    if count < 0x80 { return [UInt8(count)] }
    var value = count
    var bytes: [UInt8] = []
    while value > 0 {
        bytes.insert(UInt8(value & 0xff), at: 0)
        value >>= 8
    }
    return [UInt8(0x80 | bytes.count)] + bytes
}

func _asn1TLV(_ tag: UInt8, _ body: [UInt8]) -> [UInt8] {
    [tag] + _asn1Length(body.count) + body
}

func _asn1Integer(_ value: _CKNat) -> [UInt8] {
    var bytes = _ckNatToBE(value, length: max(1, (value.bitWidth + 7) / 8))
    if bytes.isEmpty { bytes = [0] }
    if let first = bytes.first, first & 0x80 != 0 {
        bytes.insert(0, at: 0)
    }
    return _asn1TLV(0x02, bytes)
}

func _asn1OID(_ oid: [UInt8]) -> [UInt8] { _asn1TLV(0x06, oid) }

func _asn1BitString(_ bytes: [UInt8]) -> [UInt8] {
    _asn1TLV(0x03, [0x00] + bytes)
}

func _asn1OctetString(_ bytes: [UInt8]) -> [UInt8] {
    _asn1TLV(0x04, bytes)
}

func _asn1Sequence(_ parts: [UInt8]) -> [UInt8] {
    _asn1TLV(0x30, parts)
}

let _oidECPublicKey: [UInt8] = [0x2a, 0x86, 0x48, 0xce, 0x3d, 0x02, 0x01]

func _ckSPKI(_ point: _NISTPoint, _ curve: _NISTCurve) -> Data {
    let algorithm = _asn1Sequence(_asn1OID(_oidECPublicKey) + _asn1OID(curve.oid))
    let body = _asn1Sequence(algorithm + _asn1BitString(Array(_ckX963Public(point, curve))))
    return Data(body)
}

func _ckSEC1(_ scalar: _CKNat, _ point: _NISTPoint, _ curve: _NISTCurve) -> [UInt8] {
    let version = _asn1TLV(0x02, [0x01])
    let key = _asn1OctetString(Array(_ckCoordBytes(scalar, length: curve.coordinateByteCount)))
    let publicBits = _asn1TLV(0xa1, _asn1BitString(Array(_ckX963Public(point, curve))))
    return _asn1Sequence(version + key + publicBits)
}

func _ckPKCS8(_ scalar: _CKNat, _ point: _NISTPoint, _ curve: _NISTCurve) -> Data {
    let version = _asn1TLV(0x02, [0x00])
    let algorithm = _asn1Sequence(_asn1OID(_oidECPublicKey) + _asn1OID(curve.oid))
    let inner = _asn1OctetString(_ckSEC1(scalar, point, curve))
    return Data(_asn1Sequence(version + algorithm + inner))
}

func _ckPEM(_ der: Data, label: String) -> String {
    let b64 = der.base64EncodedString()
    var lines: [String] = ["-----BEGIN \(label)-----"]
    var index = b64.startIndex
    while index < b64.endIndex {
        let next = b64.index(index, offsetBy: 64, limitedBy: b64.endIndex) ?? b64.endIndex
        lines.append(String(b64[index..<next]))
        index = next
    }
    lines.append("-----END \(label)-----")
    return lines.joined(separator: "\n") + "\n"
}

func _ckFindLiteral(_ haystack: String, _ needle: String) -> String.Index? {
    var index = haystack.startIndex
    while index < haystack.endIndex {
        if haystack[index...].hasPrefix(needle) { return index }
        index = haystack.index(after: index)
    }
    return nil
}

func _ckParsePEM(_ pem: String, expectedLabel: String) throws -> Data {
    let begin = "-----BEGIN \(expectedLabel)-----"
    let end = "-----END \(expectedLabel)-----"
    guard pem.hasPrefix(begin) else { throw CryptoKitASN1Error.invalidPEMDocument }
    guard let endIndex = _ckFindLiteral(pem, end) else { throw CryptoKitASN1Error.invalidPEMDocument }
    let inner = pem[pem.index(pem.startIndex, offsetBy: begin.count)..<endIndex]
    var b64 = ""
    for ch in inner where ch != "\n" && ch != "\r" && ch != " " {
        b64.append(ch)
    }
    guard let data = Data(base64Encoded: b64) else { throw CryptoKitASN1Error.invalidPEMDocument }
    return data
}

struct _ASN1Cursor {
    let bytes: [UInt8]
    var offset: Int

    init(_ data: Data) {
        bytes = Array(data)
        offset = 0
    }

    mutating func expect(_ tag: UInt8) throws -> [UInt8] {
        guard offset < bytes.count, bytes[offset] == tag else {
            throw CryptoKitASN1Error.unexpectedFieldType
        }
        offset += 1
        guard offset < bytes.count else { throw CryptoKitASN1Error.truncatedASN1Field }
        let first = bytes[offset]
        offset += 1
        let length: Int
        if first < 0x80 {
            length = Int(first)
        } else {
            let count = Int(first & 0x7f)
            guard count > 0, count < 5, offset + count <= bytes.count else {
                throw CryptoKitASN1Error.unsupportedFieldLength
            }
            var value = 0
            for _ in 0..<count {
                value = (value << 8) | Int(bytes[offset])
                offset += 1
            }
            length = value
        }
        guard offset + length <= bytes.count else { throw CryptoKitASN1Error.truncatedASN1Field }
        let body = Array(bytes[offset..<(offset + length)])
        offset += length
        return body
    }

    mutating func integer() throws -> _CKNat {
        let body = try expect(0x02)
        guard !body.isEmpty else { throw CryptoKitASN1Error.invalidASN1IntegerEncoding }
        return _ckNatFromBE(body)
    }
}

func _ckParseSPKI(_ data: Data, _ curve: _NISTCurve) throws -> _NISTPoint {
    var cursor = _ASN1Cursor(data)
    let seq = try cursor.expect(0x30)
    var inner = _ASN1Cursor(Data(seq))
    let alg = try inner.expect(0x30)
    var algCursor = _ASN1Cursor(Data(alg))
    let oid = try algCursor.expect(0x06)
    let curveOID = try algCursor.expect(0x06)
    guard oid == _oidECPublicKey, curveOID == curve.oid else {
        throw CryptoKitASN1Error.invalidObjectIdentifier
    }
    let bits = try inner.expect(0x03)
    guard bits.first == 0x00 else { throw CryptoKitASN1Error.invalidASN1Object }
    return try _ckParseX963Public(Data(bits.dropFirst()), curve)
}

func _ckParsePKCS8(_ data: Data, _ curve: _NISTCurve) throws -> _CKNat {
    var cursor = _ASN1Cursor(data)
    let seq = try cursor.expect(0x30)
    var inner = _ASN1Cursor(Data(seq))
    _ = try inner.integer()
    let alg = try inner.expect(0x30)
    var algCursor = _ASN1Cursor(Data(alg))
    let oid = try algCursor.expect(0x06)
    let curveOID = try algCursor.expect(0x06)
    guard oid == _oidECPublicKey, curveOID == curve.oid else {
        throw CryptoKitASN1Error.invalidObjectIdentifier
    }
    let octet = try inner.expect(0x04)
    return try _ckParseSEC1(Data(octet), curve)
}

func _ckParseSEC1(_ data: Data, _ curve: _NISTCurve) throws -> _CKNat {
    var cursor = _ASN1Cursor(data)
    let seq = try cursor.expect(0x30)
    var inner = _ASN1Cursor(Data(seq))
    _ = try inner.integer()
    let key = try inner.expect(0x04)
    return try _ckParsePrivateScalar(Data(key), curve)
}

func _ckDERSignature(r: _CKNat, s: _CKNat) -> Data {
    Data(_asn1Sequence(_asn1Integer(r) + _asn1Integer(s)))
}

func _ckParseDERSignature(_ data: Data, coordinateByteCount: Int) throws -> (r: _CKNat, s: _CKNat) {
    var cursor = _ASN1Cursor(data)
    let seq = try cursor.expect(0x30)
    var inner = _ASN1Cursor(Data(seq))
    let r = try inner.integer()
    let s = try inner.integer()
    _ = coordinateByteCount
    return (r, s)
}

func _ckRawSignature(r: _CKNat, s: _CKNat, coordinateByteCount: Int) -> Data {
    _ckCoordBytes(r, length: coordinateByteCount) + _ckCoordBytes(s, length: coordinateByteCount)
}

func _ckParseRawSignature(_ data: Data, coordinateByteCount: Int) throws -> (r: _CKNat, s: _CKNat) {
    let bytes = Array(data)
    guard bytes.count == 2 * coordinateByteCount else { throw CryptoKitError.incorrectParameterSize }
    let r = _ckNatFromBE(Array(bytes[0..<coordinateByteCount]))
    let s = _ckNatFromBE(Array(bytes[coordinateByteCount...]))
    return (r, s)
}
