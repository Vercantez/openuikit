import Foundation

struct _SecRSAKey {
    var n: _SecInt
    var e: _SecInt
    var d: _SecInt?
    var p: _SecInt?
    var q: _SecInt?
    var dP: _SecInt?
    var dQ: _SecInt?
    var qInv: _SecInt?

    var isPrivate: Bool { d != nil }
    var modulusBytes: Int { (n.bitLength + 7) / 8 }

    func publicOnly() -> _SecRSAKey {
        _SecRSAKey(n: n, e: e, d: nil, p: nil, q: nil, dP: nil, dQ: nil, qInv: nil)
    }

    func pkcs1Public() -> [UInt8] {
        _secDEREncode(.sequence([_secDERInteger(n), _secDERInteger(e)]))
    }

    func pkcs1Private() -> [UInt8]? {
        guard let d else { return nil }
        let p = self.p ?? .zero
        let q = self.q ?? .zero
        let dP = self.dP ?? .zero
        let dQ = self.dQ ?? .zero
        let qInv = self.qInv ?? .zero
        return _secDEREncode(.sequence([
            .integer([0]),
            _secDERInteger(n),
            _secDERInteger(e),
            _secDERInteger(d),
            _secDERInteger(p),
            _secDERInteger(q),
            _secDERInteger(dP),
            _secDERInteger(dQ),
            _secDERInteger(qInv),
        ]))
    }

    static func parsePKCS1(_ data: [UInt8]) -> _SecRSAKey? {
        if let inner = _secUnwrapPKCS8RSA(data) {
            return parsePKCS1(inner)
        }
        guard let root = try? _secDERParse(data), let items = root.children, items.count >= 2 else {
            return nil
        }
        if items.count >= 9, let n = _secIntFromDER(items[1]), let e = _secIntFromDER(items[2]),
           let d = _secIntFromDER(items[3]) {
            return _SecRSAKey(
                n: n, e: e, d: d,
                p: _secIntFromDER(items[4]), q: _secIntFromDER(items[5]),
                dP: _secIntFromDER(items[6]), dQ: _secIntFromDER(items[7]),
                qInv: _secIntFromDER(items[8])
            )
        }
        if let n = _secIntFromDER(items[0]), let e = _secIntFromDER(items[1]) {
            return _SecRSAKey(n: n, e: e, d: nil, p: nil, q: nil, dP: nil, dQ: nil, qInv: nil)
        }
        return nil
    }

    static func generate(bits: Int) -> _SecRSAKey? {
        guard bits == 2048 || bits == 4096 else { return nil }
        let primeBits = bits / 2
        var p = _secRandomPrime(bitLength: primeBits)
        var q = _secRandomPrime(bitLength: primeBits)
        if p < q { swap(&p, &q) }
        if p == q { return generate(bits: bits) }
        let n = p.multiplied(q)
        let phi = p.subtracting(.one).multiplied(q.subtracting(.one))
        let e = _SecInt(65537)
        guard let d = e.modInverse(phi) else { return generate(bits: bits) }
        let dP = d.modulo(p.subtracting(.one))
        let dQ = d.modulo(q.subtracting(.one))
        guard let qInv = q.modInverse(p) else { return generate(bits: bits) }
        return _SecRSAKey(n: n, e: e, d: d, p: p, q: q, dP: dP, dQ: dQ, qInv: qInv)
    }

    func crypt(_ block: [UInt8], privateExponent: Bool) -> [UInt8]? {
        let k = modulusBytes
        guard block.count == k else { return nil }
        let m = _SecInt(bytes: block)
        if m >= n { return nil }
        if privateExponent, let p, let q, let dP, let dQ, let qInv, !p.isZero, !q.isZero {
            let m1 = m.modulo(p).modPow(dP, p)
            let m2 = m.modulo(q).modPow(dQ, q)
            let h = qInv.multiplied(m1.subtractingMod(m2, p)).modulo(p)
            return m2.adding(q.multiplied(h)).bigEndianBytes(k)
        }
        let exponent: _SecInt
        if privateExponent {
            guard let d else { return nil }
            exponent = d
        } else {
            exponent = e
        }
        return m.modPow(exponent, n).bigEndianBytes(k)
    }
}

func _secUnwrapPKCS8RSA(_ data: [UInt8]) -> [UInt8]? {
    guard let root = try? _secDERParse(data), let items = root.children, items.count >= 3 else {
        return nil
    }
    guard items[0].integerBytes != nil,
          let algorithm = items[1].children, let oid = algorithm.first?.oid,
          oid == _oidRSAEncryption,
          let inner = items[2].octet else {
        return nil
    }
    return inner
}

func _secRSAESPKCS1Encrypt(key: _SecRSAKey, plaintext: [UInt8]) -> [UInt8]? {
    let k = key.modulusBytes
    guard plaintext.count <= k - 11 else { return nil }
    let ps = _secRandomBytes(k - 3 - plaintext.count).map { $0 == 0 ? 1 : $0 }
    if ps.isEmpty { return nil }
    var em: [UInt8] = [0x00, 0x02]
    em.append(contentsOf: ps)
    em.append(0x00)
    em.append(contentsOf: plaintext)
    return key.crypt(em, privateExponent: false)
}

func _secRSAESPKCS1Decrypt(key: _SecRSAKey, ciphertext: [UInt8]) -> [UInt8]? {
    guard key.isPrivate, let em = key.crypt(ciphertext, privateExponent: true),
          em.count >= 11, em[0] == 0x00, em[1] == 0x02 else { return nil }
    var index = 2
    while index < em.count && em[index] != 0 { index += 1 }
    guard index < em.count, index >= 10 else { return nil }
    return Array(em[(index + 1)...])
}

func _secRSAOAEPEncrypt(key: _SecRSAKey, plaintext: [UInt8], digest: _SecDigest) -> [UInt8]? {
    let k = key.modulusBytes
    let hLen = digest.outputByteCount
    guard plaintext.count <= k - 2 * hLen - 2 else { return nil }
    let lHash = digest.hash([])
    var db = lHash + [UInt8](repeating: 0, count: k - 2 * hLen - 2 - plaintext.count) + [0x01] + plaintext
    let seed = _secRandomBytes(hLen)
    let dbMask = _secMGF1(digest: digest, seed: seed, length: db.count)
    for i in 0..<db.count { db[i] ^= dbMask[i] }
    var maskedSeed = seed
    let seedMask = _secMGF1(digest: digest, seed: db, length: hLen)
    for i in 0..<hLen { maskedSeed[i] ^= seedMask[i] }
    let em = [0x00] + maskedSeed + db
    return key.crypt(em, privateExponent: false)
}

func _secRSAOAEPDecrypt(key: _SecRSAKey, ciphertext: [UInt8], digest: _SecDigest) -> [UInt8]? {
    guard key.isPrivate, let em = key.crypt(ciphertext, privateExponent: true) else { return nil }
    let hLen = digest.outputByteCount
    guard em.count >= 2 * hLen + 2, em[0] == 0x00 else { return nil }
    var maskedSeed = Array(em[1..<(1 + hLen)])
    var db = Array(em[(1 + hLen)...])
    let seedMask = _secMGF1(digest: digest, seed: db, length: hLen)
    for i in 0..<hLen { maskedSeed[i] ^= seedMask[i] }
    let dbMask = _secMGF1(digest: digest, seed: maskedSeed, length: db.count)
    for i in 0..<db.count { db[i] ^= dbMask[i] }
    let lHash = digest.hash([])
    guard _secEqualBytes(Array(db.prefix(hLen)), lHash) else { return nil }
    var index = hLen
    while index < db.count && db[index] == 0 { index += 1 }
    guard index < db.count, db[index] == 0x01 else { return nil }
    return Array(db[(index + 1)...])
}

func _secRSAPKCS1Sign(key: _SecRSAKey, digestInfo: [UInt8]) -> [UInt8]? {
    guard key.isPrivate else { return nil }
    let k = key.modulusBytes
    guard digestInfo.count <= k - 11 else { return nil }
    var em: [UInt8] = [0x00, 0x01]
    em.append(contentsOf: [UInt8](repeating: 0xff, count: k - 3 - digestInfo.count))
    em.append(0x00)
    em.append(contentsOf: digestInfo)
    return key.crypt(em, privateExponent: true)
}

func _secRSAPKCS1Verify(key: _SecRSAKey, digestInfo: [UInt8], signature: [UInt8]) -> Bool {
    guard let em = key.crypt(signature, privateExponent: false) else { return false }
    let k = key.modulusBytes
    guard em.count == k, em[0] == 0x00, em[1] == 0x01 else { return false }
    var index = 2
    while index < em.count && em[index] == 0xff { index += 1 }
    guard index < em.count, em[index] == 0x00 else { return false }
    return _secEqualBytes(Array(em[(index + 1)...]), digestInfo)
}

func _secRSAPSSSign(key: _SecRSAKey, messageHash: [UInt8], digest: _SecDigest) -> [UInt8]? {
    guard key.isPrivate else { return nil }
    let k = key.modulusBytes
    let hLen = digest.outputByteCount
    let sLen = hLen
    guard k >= hLen + sLen + 2 else { return nil }
    let salt = _secRandomBytes(sLen)
    let mHash = messageHash
    let mPrime = [UInt8](repeating: 0, count: 8) + mHash + salt
    let h = digest.hash(mPrime)
    var db = [UInt8](repeating: 0, count: k - hLen - sLen - 2) + [0x01] + salt
    let dbMask = _secMGF1(digest: digest, seed: h, length: db.count)
    for i in 0..<db.count { db[i] ^= dbMask[i] }
    if let first = db.first { db[0] = first & 0x7f }
    let em = db + h + [0xbc]
    return key.crypt(em, privateExponent: true)
}

func _secRSAPSSVerify(key: _SecRSAKey, messageHash: [UInt8], signature: [UInt8], digest: _SecDigest) -> Bool {
    guard let em = key.crypt(signature, privateExponent: false) else { return false }
    let k = key.modulusBytes
    let hLen = digest.outputByteCount
    let sLen = hLen
    guard em.count == k, em.last == 0xbc, k >= hLen + sLen + 2 else { return false }
    var db = Array(em.prefix(k - hLen - 1))
    let h = Array(em[(k - hLen - 1)..<(k - 1)])
    let dbMask = _secMGF1(digest: digest, seed: h, length: db.count)
    for i in 0..<db.count { db[i] ^= dbMask[i] }
    if let first = db.first { db[0] = first & 0x7f }
    var index = 0
    while index < db.count - sLen && db[index] == 0 { index += 1 }
    guard index < db.count - sLen, db[index] == 0x01 else { return false }
    let salt = Array(db.suffix(sLen))
    let mPrime = [UInt8](repeating: 0, count: 8) + messageHash + salt
    return _secEqualBytes(digest.hash(mPrime), h)
}

// MARK: - NIST EC

struct _SecECCurve {
    var name: String
    var size: Int
    var p: _SecInt
    var a: _SecInt
    var b: _SecInt
    var n: _SecInt
    var gx: _SecInt
    var gy: _SecInt
    var oid: [UInt8]
}

func _secCurveP256() -> _SecECCurve {
    let p = _SecInt(bytes: _secHex("ffffffff00000001000000000000000000000000ffffffffffffffffffffffff"))
    return _SecECCurve(
        name: "P-256", size: 32, p: p,
        a: p.subtracting(_SecInt(3)),
        b: _SecInt(bytes: _secHex("5ac635d8aa3a93e7b3ebbd55769886bc651d06b0cc53b0f63bce3c3e27d2604b")),
        n: _SecInt(bytes: _secHex("ffffffff00000000ffffffffffffffffbce6faada7179e84f3b9cac2fc632551")),
        gx: _SecInt(bytes: _secHex("6b17d1f2e12c4247f8bce6e563a440f277037d812deb33a0f4a13945d898c296")),
        gy: _SecInt(bytes: _secHex("4fe342e2fe1a7f9b8ee7eb4a7c0f9e162bce33576b315ececbb6406837bf51f5")),
        oid: _oidPrime256v1
    )
}

func _secCurveP384() -> _SecECCurve {
    let p = _SecInt(bytes: _secHex("fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffeffffffff0000000000000000ffffffff"))
    return _SecECCurve(
        name: "P-384", size: 48, p: p,
        a: p.subtracting(_SecInt(3)),
        b: _SecInt(bytes: _secHex("b3312fa7e23ee7e4988e056be3f82d19181d9c6efe8141120314088f5013875ac656398d8a2ed19d2a85c8edd3ec2aef")),
        n: _SecInt(bytes: _secHex("ffffffffffffffffffffffffffffffffffffffffffffffffc7634d81f4372ddf581a0db248b0a77aecec196accc52973")),
        gx: _SecInt(bytes: _secHex("aa87ca22be8b05378eb1c71ef320ad746e1d3b628ba79b9859f741e082542a385502f25dbf55296c3a545e3872760ab7")),
        gy: _SecInt(bytes: _secHex("3617de4a96262c6f5d9e98bf9292dc29f8f41dbd289a147ce9da3113b5f0b8c00a60b1ce1d7e819d7a431d7c90ea0e5f")),
        oid: _oidSecp384r1
    )
}

func _secCurveP521() -> _SecECCurve {
    let p = _SecInt(bytes: _secHex("01ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff"))
    return _SecECCurve(
        name: "P-521", size: 66, p: p,
        a: p.subtracting(_SecInt(3)),
        b: _SecInt(bytes: _secHex("0051953eb9618e1c9a1f929a21a0b68540eea2da725b99b315f3b8b489918ef109e156193951ec7e937b1652c0bd3bb1bf073573df883d2c34f1ef451fd46b503f00")),
        n: _SecInt(bytes: _secHex("01fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffa51868783bf2f966b7fcc0148f709a5d03bb5c9b8899c47aebb6fb71e91386409")),
        gx: _SecInt(bytes: _secHex("00c6858e06b70404e9cd9e3ecb662395b4429c648139053fb521f828af606b4d3dbaa14b5e77efe75928fe1dc127a2ffa8de3348b3c1856a429bf97e7e31c2e5bd66")),
        gy: _SecInt(bytes: _secHex("011839296a789a3bc0045c8a5fb42c7d1bd998f54449579b446817afbd17273e662c97ee72995ef42640c550b9013fad0761353c7086a272c24088be94769fd16650")),
        oid: _oidSecp521r1
    )
}

func _secHex(_ text: String) -> [UInt8] {
    var bytes: [UInt8] = []
    var chars: [UInt8] = []
    for unit in text.utf8 {
        if unit == 0x20 { continue }
        chars.append(unit)
        if chars.count == 2 {
            func nibble(_ c: UInt8) -> UInt8 {
                if c >= 48 && c <= 57 { return c - 48 }
                if c >= 97 && c <= 102 { return c - 87 }
                if c >= 65 && c <= 70 { return c - 55 }
                return 0
            }
            bytes.append((nibble(chars[0]) << 4) | nibble(chars[1]))
            chars.removeAll()
        }
    }
    return bytes
}

struct _SecECPoint {
    var x: _SecInt
    var y: _SecInt
    var infinity: Bool
    static let infinity = _SecECPoint(x: .zero, y: .zero, infinity: true)
}

func _secECAdd(_ curve: _SecECCurve, _ p: _SecECPoint, _ q: _SecECPoint) -> _SecECPoint {
    if p.infinity { return q }
    if q.infinity { return p }
    if p.x == q.x {
        if p.y == q.y { return _secECDouble(curve, p) }
        return .infinity
    }
    guard let inv = q.x.subtractingMod(p.x, curve.p).modInverse(curve.p) else { return .infinity }
    let lambda = q.y.subtractingMod(p.y, curve.p).multiplied(inv).modulo(curve.p)
    let x = lambda.multiplied(lambda).subtractingMod(p.x, curve.p).subtractingMod(q.x, curve.p)
    let y = lambda.multiplied(p.x.subtractingMod(x, curve.p)).modulo(curve.p).subtractingMod(p.y, curve.p)
    return _SecECPoint(x: x, y: y, infinity: false)
}

func _secECDouble(_ curve: _SecECCurve, _ p: _SecECPoint) -> _SecECPoint {
    if p.infinity { return p }
    let two = _SecInt(2)
    let three = _SecInt(3)
    guard let inv = two.multiplied(p.y).modulo(curve.p).modInverse(curve.p) else { return .infinity }
    let lambda = three.multiplied(p.x).multiplied(p.x).adding(curve.a).modulo(curve.p).multiplied(inv).modulo(curve.p)
    let x = lambda.multiplied(lambda).subtractingMod(two.multiplied(p.x).modulo(curve.p), curve.p)
    let y = lambda.multiplied(p.x.subtractingMod(x, curve.p)).modulo(curve.p).subtractingMod(p.y, curve.p)
    return _SecECPoint(x: x, y: y, infinity: false)
}

func _secECMul(_ curve: _SecECCurve, _ k: _SecInt, _ point: _SecECPoint) -> _SecECPoint {
    var result = _SecECPoint.infinity
    var addend = point
    var scalar = k
    while !scalar.isZero {
        if (scalar.words[0] & 1) == 1 {
            result = _secECAdd(curve, result, addend)
        }
        addend = _secECDouble(curve, addend)
        scalar = scalar.shiftedRight(1)
    }
    return result
}

struct _SecECKey {
    var curve: _SecECCurve
    var d: _SecInt?
    var publicPoint: _SecECPoint

    var isPrivate: Bool { d != nil }

    func publicOnly() -> _SecECKey {
        _SecECKey(curve: curve, d: nil, publicPoint: publicPoint)
    }

    func x963Public() -> [UInt8] {
        [0x04] + publicPoint.x.bigEndianBytes(curve.size) + publicPoint.y.bigEndianBytes(curve.size)
    }

    func x963Private() -> [UInt8]? {
        guard let d else { return nil }
        return x963Public() + d.bigEndianBytes(curve.size)
    }

    static func parseX963(_ data: [UInt8], curve: _SecECCurve, wantPrivate: Bool) -> _SecECKey? {
        let pubLen = 1 + 2 * curve.size
        guard data.first == 0x04 else { return nil }
        if data.count == pubLen {
            let x = _SecInt(bytes: Array(data[1..<(1 + curve.size)]))
            let y = _SecInt(bytes: Array(data[(1 + curve.size)...]))
            return _SecECKey(curve: curve, d: nil, publicPoint: _SecECPoint(x: x, y: y, infinity: false))
        }
        if wantPrivate, data.count == pubLen + curve.size {
            let x = _SecInt(bytes: Array(data[1..<(1 + curve.size)]))
            let y = _SecInt(bytes: Array(data[(1 + curve.size)..<(pubLen)]))
            let d = _SecInt(bytes: Array(data[pubLen...]))
            return _SecECKey(curve: curve, d: d, publicPoint: _SecECPoint(x: x, y: y, infinity: false))
        }
        if wantPrivate, data.count == curve.size {
            let d = _SecInt(bytes: data)
            let point = _secECMul(curve, d, _SecECPoint(x: curve.gx, y: curve.gy, infinity: false))
            return _SecECKey(curve: curve, d: d, publicPoint: point)
        }
        return nil
    }

    static func generate(curve: _SecECCurve) -> _SecECKey {
        var d = _SecInt.random(bitLength: curve.n.bitLength)
        if d >= curve.n || d.isZero { d = _SecInt.one }
        let point = _secECMul(curve, d, _SecECPoint(x: curve.gx, y: curve.gy, infinity: false))
        return _SecECKey(curve: curve, d: d, publicPoint: point)
    }
}

func _secECDSASign(key: _SecECKey, hash: [UInt8], der: Bool) -> [UInt8]? {
    guard let d = key.d else { return nil }
    let curve = key.curve
    let z = _SecInt(bytes: Array(hash.prefix(curve.size)))
    while true {
        let k = _SecInt.random(bitLength: curve.n.bitLength)
        if k.isZero || k >= curve.n { continue }
        let rPoint = _secECMul(curve, k, _SecECPoint(x: curve.gx, y: curve.gy, infinity: false))
        let r = rPoint.x.modulo(curve.n)
        if r.isZero { continue }
        guard let kInv = k.modInverse(curve.n) else { continue }
        let s = kInv.multiplied(z.adding(r.multiplied(d))).modulo(curve.n)
        if s.isZero { continue }
        if der {
            return _secDEREncode(.sequence([_secDERInteger(r), _secDERInteger(s)]))
        }
        return r.bigEndianBytes(curve.size) + s.bigEndianBytes(curve.size)
    }
}

func _secECDSAVerify(key: _SecECKey, hash: [UInt8], signature: [UInt8]) -> Bool {
    let curve = key.curve
    let r: _SecInt
    let s: _SecInt
    if let root = try? _secDERParse(signature), let items = root.children, items.count == 2,
       let rr = _secIntFromDER(items[0]), let ss = _secIntFromDER(items[1]) {
        r = rr; s = ss
    } else if signature.count == 2 * curve.size {
        r = _SecInt(bytes: Array(signature.prefix(curve.size)))
        s = _SecInt(bytes: Array(signature.suffix(curve.size)))
    } else {
        return false
    }
    if r.isZero || s.isZero || r >= curve.n || s >= curve.n { return false }
    guard let sInv = s.modInverse(curve.n) else { return false }
    let z = _SecInt(bytes: Array(hash.prefix(curve.size)))
    let u1 = z.multiplied(sInv).modulo(curve.n)
    let u2 = r.multiplied(sInv).modulo(curve.n)
    let p1 = _secECMul(curve, u1, _SecECPoint(x: curve.gx, y: curve.gy, infinity: false))
    let p2 = _secECMul(curve, u2, key.publicPoint)
    let rPoint = _secECAdd(curve, p1, p2)
    if rPoint.infinity { return false }
    return rPoint.x.modulo(curve.n) == r
}

func _secECDH(privateKey: _SecECKey, publicKey: _SecECKey) -> [UInt8]? {
    guard let d = privateKey.d, privateKey.curve.size == publicKey.curve.size else { return nil }
    let shared = _secECMul(privateKey.curve, d, publicKey.publicPoint)
    if shared.infinity { return nil }
    return shared.x.bigEndianBytes(privateKey.curve.size)
}

func _secCurve(forBits bits: Int) -> _SecECCurve? {
    switch bits {
    case 256: return _secCurveP256()
    case 384: return _secCurveP384()
    case 521: return _secCurveP521()
    default: return nil
    }
}

func _secCurve(forOID oid: [UInt8]) -> _SecECCurve? {
    if oid == _oidPrime256v1 { return _secCurveP256() }
    if oid == _oidSecp384r1 { return _secCurveP384() }
    if oid == _oidSecp521r1 { return _secCurveP521() }
    return nil
}

func _secCurve(forX963 count: Int) -> _SecECCurve? {
    if count == 65 || count == 97 { return _secCurveP256() }
    if count == 145 { return _secCurveP384() }
    if count == 1 + 2 * 48 { return _secCurveP384() }
    if count == 1 + 3 * 48 { return _secCurveP384() }
    if count == 133 || count == 199 || count == 1 + 2 * 66 || count == 1 + 3 * 66 {
        return _secCurveP521()
    }
    return nil
}
