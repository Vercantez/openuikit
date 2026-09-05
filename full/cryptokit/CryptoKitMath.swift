import Foundation

// Limb-based unsigned integers used by X25519 (RFC 7748), Ed25519 (RFC 8032)
// and the NIST Weierstrass curves. Loops over secret bits run a fixed number
// of iterations; cswap is branch-free on the mask.

struct _CKNat: Comparable {
    var limbs: [UInt64]

    static let zero = _CKNat(limbs: [])
    static let one = _CKNat(limbs: [1])

    init(limbs: [UInt64]) {
        var value = limbs
        while let last = value.last, last == 0 {
            value.removeLast()
        }
        self.limbs = value
    }

    init(_ value: UInt64) {
        self.limbs = value == 0 ? [] : [value]
    }

    var isZero: Bool { limbs.isEmpty }

    var bitWidth: Int {
        guard let last = limbs.last else { return 0 }
        return (limbs.count - 1) * 64 + (64 - last.leadingZeroBitCount)
    }

    func bit(_ index: Int) -> Bool {
        let limb = index / 64
        let offset = index % 64
        guard limb < limbs.count else { return false }
        return ((limbs[limb] >> offset) & 1) == 1
    }

    static func < (lhs: _CKNat, rhs: _CKNat) -> Bool {
        if lhs.limbs.count != rhs.limbs.count {
            return lhs.limbs.count < rhs.limbs.count
        }
        for index in stride(from: lhs.limbs.count - 1, through: 0, by: -1) {
            if lhs.limbs[index] != rhs.limbs[index] {
                return lhs.limbs[index] < rhs.limbs[index]
            }
        }
        return false
    }

    static func == (lhs: _CKNat, rhs: _CKNat) -> Bool {
        lhs.limbs == rhs.limbs
    }

    static func + (lhs: _CKNat, rhs: _CKNat) -> _CKNat {
        let count = max(lhs.limbs.count, rhs.limbs.count)
        var result = [UInt64](repeating: 0, count: count + 1)
        var carry: UInt64 = 0
        for index in 0..<count {
            let a = index < lhs.limbs.count ? lhs.limbs[index] : 0
            let b = index < rhs.limbs.count ? rhs.limbs[index] : 0
            let (s1, o1) = a.addingReportingOverflow(b)
            let (s2, o2) = s1.addingReportingOverflow(carry)
            result[index] = s2
            carry = (o1 ? 1 : 0) + (o2 ? 1 : 0)
        }
        result[count] = carry
        return _CKNat(limbs: result)
    }

    static func - (lhs: _CKNat, rhs: _CKNat) -> _CKNat {
        precondition(lhs >= rhs)
        var result = [UInt64](repeating: 0, count: lhs.limbs.count)
        var borrow: UInt64 = 0
        for index in 0..<lhs.limbs.count {
            let a = lhs.limbs[index]
            let b = index < rhs.limbs.count ? rhs.limbs[index] : 0
            let (s1, o1) = a.subtractingReportingOverflow(b)
            let (s2, o2) = s1.subtractingReportingOverflow(borrow)
            result[index] = s2
            borrow = (o1 ? 1 : 0) + (o2 ? 1 : 0)
        }
        return _CKNat(limbs: result)
    }

    static func * (lhs: _CKNat, rhs: _CKNat) -> _CKNat {
        if lhs.isZero || rhs.isZero { return .zero }
        var result = [UInt64](repeating: 0, count: lhs.limbs.count + rhs.limbs.count)
        for i in 0..<lhs.limbs.count {
            var carry: UInt64 = 0
            for j in 0..<rhs.limbs.count {
                let (hi, lo) = _ckMul64(lhs.limbs[i], rhs.limbs[j])
                var sumLo: UInt64 = lo
                var sumHi: UInt64 = hi
                let (s1, o1) = sumLo.addingReportingOverflow(result[i + j])
                sumLo = s1
                if o1 { sumHi &+= 1 }
                let (s2, o2) = sumLo.addingReportingOverflow(carry)
                sumLo = s2
                if o2 { sumHi &+= 1 }
                result[i + j] = sumLo
                carry = sumHi
            }
            var index = i + rhs.limbs.count
            var carry2 = carry
            while carry2 != 0 {
                let (s, o) = result[index].addingReportingOverflow(carry2)
                result[index] = s
                carry2 = o ? 1 : 0
                index += 1
            }
        }
        return _CKNat(limbs: result)
    }

    func shiftedLeft(_ bits: Int) -> _CKNat {
        if isZero || bits == 0 { return self }
        let limbShift = bits / 64
        let bitShift = bits % 64
        var result = [UInt64](repeating: 0, count: limbs.count + limbShift + 1)
        if bitShift == 0 {
            for index in 0..<limbs.count { result[index + limbShift] = limbs[index] }
        } else {
            var carry: UInt64 = 0
            for index in 0..<limbs.count {
                result[index + limbShift] = (limbs[index] << bitShift) | carry
                carry = limbs[index] >> (64 - bitShift)
            }
            result[limbs.count + limbShift] = carry
        }
        return _CKNat(limbs: result)
    }

    func shiftedRight(_ bits: Int) -> _CKNat {
        if isZero || bits == 0 { return self }
        let limbShift = bits / 64
        let bitShift = bits % 64
        if limbShift >= limbs.count { return .zero }
        if bitShift == 0 {
            return _CKNat(limbs: Array(limbs.dropFirst(limbShift)))
        }
        var result = [UInt64](repeating: 0, count: limbs.count - limbShift)
        for index in 0..<result.count {
            let current = limbs[index + limbShift]
            let next = (index + limbShift + 1) < limbs.count ? limbs[index + limbShift + 1] : 0
            result[index] = (current >> bitShift) | (next << (64 - bitShift))
        }
        return _CKNat(limbs: result)
    }

    func settingBit(_ index: Int) -> _CKNat {
        let limb = index / 64
        let offset = index % 64
        var result = limbs
        if result.count <= limb {
            result.append(contentsOf: [UInt64](repeating: 0, count: limb + 1 - result.count))
        }
        result[limb] |= (1 << offset)
        return _CKNat(limbs: result)
    }

    func divmod(_ divisor: _CKNat) -> (_CKNat, _CKNat) {
        precondition(!divisor.isZero)
        if self < divisor { return (.zero, self) }
        var quotient = _CKNat.zero
        var remainder = _CKNat.zero
        let width = bitWidth
        for index in stride(from: width - 1, through: 0, by: -1) {
            remainder = remainder.shiftedLeft(1)
            if bit(index) { remainder = remainder + .one }
            if remainder >= divisor {
                remainder = remainder - divisor
                quotient = quotient.settingBit(index)
            }
        }
        return (quotient, remainder)
    }

    func modulo(_ modulus: _CKNat) -> _CKNat { _fastMod(self, modulus) }

    func modAdd(_ other: _CKNat, _ modulus: _CKNat) -> _CKNat {
        (self + other).modulo(modulus)
    }

    func modSub(_ other: _CKNat, _ modulus: _CKNat) -> _CKNat {
        let a = modulo(modulus)
        let b = other.modulo(modulus)
        if a >= b { return a - b }
        return modulus - (b - a)
    }

    func modMul(_ other: _CKNat, _ modulus: _CKNat) -> _CKNat {
        (self * other).modulo(modulus)
    }

    func modPow(_ exponent: _CKNat, _ modulus: _CKNat) -> _CKNat {
        var result = _CKNat.one
        var base = modulo(modulus)
        var exp = exponent
        while !exp.isZero {
            if exp.bit(0) { result = result.modMul(base, modulus) }
            base = base.modMul(base, modulus)
            exp = exp.shiftedRight(1)
        }
        return result
    }

    func modInverse(_ modulus: _CKNat) -> _CKNat {
        let value = modulo(modulus)
        precondition(!value.isZero)
        return value.modPow(modulus - _CKNat(2), modulus)
    }
}

func _fastMod(_ value: _CKNat, _ modulus: _CKNat) -> _CKNat {
    var x = value
    if x < modulus { return x }
    let bits = modulus.bitWidth
    var steps = 0
    while x >= modulus {
        steps += 1
        let hi = x.shiftedRight(bits)
        if hi.isZero {
            x = x - modulus
            continue
        }
        let prod = hi * modulus
        if x >= prod {
            x = x - prod
        } else {
            return value.divmod(modulus).1
        }
        if steps > 64 { return value.divmod(modulus).1 }
    }
    return x
}

func _ckMul64(_ a: UInt64, _ b: UInt64) -> (UInt64, UInt64) {
    let a0 = a & 0xffff_ffff
    let a1 = a >> 32
    let b0 = b & 0xffff_ffff
    let b1 = b >> 32
    let p0 = a0 * b0
    let p1 = a0 * b1
    let p2 = a1 * b0
    let p3 = a1 * b1
    var mid = (p0 >> 32) + (p1 & 0xffff_ffff) + (p2 & 0xffff_ffff)
    let lo = (p0 & 0xffff_ffff) | (mid << 32)
    mid >>= 32
    let hi = p3 + (p1 >> 32) + (p2 >> 32) + mid
    return (hi, lo)
}

func _ckNatFromBE(_ bytes: [UInt8]) -> _CKNat {
    var limbs: [UInt64] = []
    var index = bytes.count
    while index > 0 {
        let start = max(0, index - 8)
        var limb: UInt64 = 0
        for byte in bytes[start..<index] {
            limb = (limb << 8) | UInt64(byte)
        }
        limbs.append(limb)
        index = start
    }
    return _CKNat(limbs: limbs)
}

func _ckNatFromLE(_ bytes: [UInt8]) -> _CKNat {
    _ckNatFromBE(Array(bytes.reversed()))
}

func _ckNatToBE(_ value: _CKNat, length: Int) -> [UInt8] {
    var bytes = [UInt8](repeating: 0, count: length)
    var remaining = value
    for index in stride(from: length - 1, through: 0, by: -1) {
        if remaining.limbs.isEmpty { break }
        bytes[index] = UInt8(truncatingIfNeeded: remaining.limbs[0])
        remaining = remaining.shiftedRight(8)
    }
    return bytes
}

func _ckNatToLE(_ value: _CKNat, length: Int) -> [UInt8] {
    Array(_ckNatToBE(value, length: length).reversed())
}

func _ckNatFromHex(_ hex: String) -> _CKNat {
    var bytes: [UInt8] = []
    var index = hex.startIndex
    if hex.count % 2 == 1 {
        bytes.append(UInt8(String(hex[index]), radix: 16)!)
        index = hex.index(after: index)
    }
    while index < hex.endIndex {
        let next = hex.index(index, offsetBy: 2)
        bytes.append(UInt8(hex[index..<next], radix: 16)!)
        index = next
    }
    return _ckNatFromBE(bytes)
}

func _ckCswap(_ swap: Bool, _ a: _CKNat, _ b: _CKNat) -> (_CKNat, _CKNat) {
    swap ? (b, a) : (a, b)
}

// MARK: - RFC 7748 X25519

let _p25519 = _CKNat.one.shiftedLeft(255) - _CKNat(19)
let _a24 = _CKNat(121665)

func _reduceP25519(_ value: _CKNat) -> _CKNat {
    var x = value
    while x.bitWidth > 255 {
        let hi = x.shiftedRight(255)
        let lo = x - hi.shiftedLeft(255)
        x = lo + hi * _CKNat(19)
    }
    if x >= _p25519 { x = x - _p25519 }
    return x
}

func _addP25519(_ a: _CKNat, _ b: _CKNat) -> _CKNat { _reduceP25519(a + b) }
func _subP25519(_ a: _CKNat, _ b: _CKNat) -> _CKNat {
    let left = _reduceP25519(a)
    let right = _reduceP25519(b)
    if left >= right { return left - right }
    return _p25519 - (right - left)
}
func _mulP25519(_ a: _CKNat, _ b: _CKNat) -> _CKNat { _reduceP25519(a * b) }
func _powP25519(_ base: _CKNat, _ exponent: _CKNat) -> _CKNat {
    var result = _CKNat.one
    var value = _reduceP25519(base)
    var exp = exponent
    while !exp.isZero {
        if exp.bit(0) { result = _mulP25519(result, value) }
        value = _mulP25519(value, value)
        exp = exp.shiftedRight(1)
    }
    return result
}
func _invP25519(_ value: _CKNat) -> _CKNat {
    _powP25519(value, _p25519 - _CKNat(2))
}

func _x25519(_ scalar: [UInt8], _ uBytes: [UInt8]) -> [UInt8] {
    // RFC 7748 §6.1: Alice secret 77076d0a… → public 8520f009…, shared 4a5d9d5b….
    var k = Array(scalar.prefix(32))
    if k.count < 32 { k.append(contentsOf: [UInt8](repeating: 0, count: 32 - k.count)) }
    k[0] &= 248
    k[31] &= 127
    k[31] |= 64
    var u = Array(uBytes.prefix(32))
    if u.count < 32 { u.append(contentsOf: [UInt8](repeating: 0, count: 32 - u.count)) }
    u[31] &= 127

    let x1 = _ckNatFromLE(u)
    var x2 = _CKNat.one
    var z2 = _CKNat.zero
    var x3 = x1
    var z3 = _CKNat.one
    var swapped = false
    let kInt = _ckNatFromLE(k)
    for t in stride(from: 254, through: 0, by: -1) {
        let kt = kInt.bit(t)
        swapped = swapped != kt
        (x2, x3) = _ckCswap(swapped, x2, x3)
        (z2, z3) = _ckCswap(swapped, z2, z3)
        swapped = kt
        let a = _addP25519(x2, z2)
        let aa = _mulP25519(a, a)
        let b = _subP25519(x2, z2)
        let bb = _mulP25519(b, b)
        let e = _subP25519(aa, bb)
        let c = _addP25519(x3, z3)
        let d = _subP25519(x3, z3)
        let da = _mulP25519(d, a)
        let cb = _mulP25519(c, b)
        x3 = _addP25519(da, cb)
        x3 = _mulP25519(x3, x3)
        z3 = _subP25519(da, cb)
        z3 = _mulP25519(_mulP25519(z3, z3), x1)
        x2 = _mulP25519(aa, bb)
        z2 = _mulP25519(e, _addP25519(aa, _mulP25519(e, _a24)))
    }
    (x2, _) = _ckCswap(swapped, x2, x3)
    (z2, _) = _ckCswap(swapped, z2, z3)
    let result = _mulP25519(x2, _invP25519(z2))
    return _ckNatToLE(result, length: 32)
}

func _x25519PublicKey(_ secret: [UInt8]) -> [UInt8] {
    var base = [UInt8](repeating: 0, count: 32)
    base[0] = 9
    return _x25519(secret, base)
}

// MARK: - RFC 8032 Ed25519

let _ed25519D: _CKNat = _subP25519(.zero, _mulP25519(_CKNat(121665), _invP25519(_CKNat(121666))))
let _ed25519I = _powP25519(_CKNat(2), _p25519.shiftedRight(2))
let _ed25519L = _ckNatFromHex("1000000000000000000000000000000014def9dea2f79cd65812631a5cf5d3ed")
let _ed25519Bx = _ckNatFromHex("216936d3cd6e53fec0a4e231fdd6dc5c692cc7609525a7b2c9562d608f25d51a")
let _ed25519By = _ckNatFromHex("6666666666666666666666666666666666666666666666666666666666666658")

struct _EdPoint {
    var x: _CKNat
    var y: _CKNat
    var z: _CKNat
    var t: _CKNat

    static let identity = _EdPoint(x: .zero, y: .one, z: .one, t: .zero)
    static let base = _EdPoint.affine(_ed25519Bx, _ed25519By)

    static func affine(_ x: _CKNat, _ y: _CKNat) -> _EdPoint {
        _EdPoint(x: x, y: y, z: .one, t: _mulP25519(x, y))
    }

    func affine() -> (x: _CKNat, y: _CKNat) {
        let inv = _invP25519(z)
        return (_mulP25519(x, inv), _mulP25519(y, inv))
    }

    func adding(_ q: _EdPoint) -> _EdPoint {
        let a = _mulP25519(x, q.x)
        let b = _mulP25519(y, q.y)
        let c = _mulP25519(t, _mulP25519(_ed25519D, q.t))
        let d = _mulP25519(z, q.z)
        let e = _subP25519(_subP25519(_mulP25519(_addP25519(x, y), _addP25519(q.x, q.y)), a), b)
        let f = _subP25519(d, c)
        let g = _addP25519(d, c)
        let h = _addP25519(b, a)
        return _EdPoint(
            x: _mulP25519(e, f),
            y: _mulP25519(g, h),
            z: _mulP25519(f, g),
            t: _mulP25519(e, h)
        )
    }

    func doubled() -> _EdPoint { adding(self) }

    func scaled(_ scalar: _CKNat) -> _EdPoint {
        var result = _EdPoint.identity
        var addend = self
        var k = scalar
        while !k.isZero {
            if k.bit(0) { result = result.adding(addend) }
            addend = addend.doubled()
            k = k.shiftedRight(1)
        }
        return result
    }
}

func _ed25519RecoverX(_ y: _CKNat, sign: Bool) -> _CKNat? {
    // RFC 8032 §5.1.3: x = (u/v)^((p+3)/8) via uv^3 (uv^7)^((p-5)/8).
    let y2 = _mulP25519(y, y)
    let u = _subP25519(y2, .one)
    let v = _addP25519(_mulP25519(_ed25519D, y2), .one)
    let v3 = _mulP25519(_mulP25519(v, v), v)
    let v7 = _mulP25519(_mulP25519(v3, v3), v)
    let exp = (_p25519 - _CKNat(5)).shiftedRight(3)
    var x = _mulP25519(_mulP25519(u, v3), _powP25519(_mulP25519(u, v7), exp))
    let vx2 = _mulP25519(v, _mulP25519(x, x))
    if vx2 == u {
        // ok
    } else if vx2 == _subP25519(.zero, u) {
        x = _mulP25519(x, _ed25519I)
    } else {
        return nil
    }
    if x.bit(0) != sign {
        if x.isZero { return nil }
        x = _subP25519(.zero, x)
    }
    return x
}

func _ed25519Encode(_ point: _EdPoint) -> [UInt8] {
    let a = point.affine()
    var bytes = _ckNatToLE(a.y, length: 32)
    if a.x.bit(0) { bytes[31] |= 0x80 }
    return bytes
}

func _ed25519Decode(_ bytes: [UInt8]) -> _EdPoint? {
    guard bytes.count == 32 else { return nil }
    var yBytes = bytes
    let sign = (yBytes[31] & 0x80) != 0
    yBytes[31] &= 0x7f
    let y = _ckNatFromLE(yBytes)
    if y >= _p25519 { return nil }
    guard let x = _ed25519RecoverX(y, sign: sign) else { return nil }
    return _EdPoint.affine(x, y)
}

func _ed25519ClampScalar(_ hashed: [UInt8]) -> _CKNat {
    var a = Array(hashed.prefix(32))
    a[0] &= 248
    a[31] &= 63
    a[31] |= 64
    return _ckNatFromLE(a)
}

func _ed25519ReduceL(_ bytes: [UInt8]) -> _CKNat {
    _ckNatFromLE(bytes).modulo(_ed25519L)
}

func _ed25519PublicKey(_ seed: [UInt8]) -> [UInt8] {
    let hashed = Array(SHA512.hash(data: Data(seed)))
    let a = _ed25519ClampScalar(hashed)
    return _ed25519Encode(_EdPoint.base.scaled(a))
}

func _ed25519Sign(_ seed: [UInt8], _ message: [UInt8]) -> [UInt8] {
    // RFC 8032 §7.1 empty message: seed 9d61b19d… → sig e5564300…/5fb88215….
    let hashed = Array(SHA512.hash(data: Data(seed)))
    let a = _ed25519ClampScalar(hashed)
    let prefix = Array(hashed.dropFirst(32))
    let publicKey = _ed25519Encode(_EdPoint.base.scaled(a))
    let r = _ed25519ReduceL(Array(SHA512.hash(data: Data(prefix + message))))
    let R = _ed25519Encode(_EdPoint.base.scaled(r))
    let k = _ed25519ReduceL(Array(SHA512.hash(data: Data(R + publicKey + message))))
    let S = r.modAdd(k.modMul(a, _ed25519L), _ed25519L)
    return R + _ckNatToLE(S, length: 32)
}

func _ed25519Verify(_ publicKey: [UInt8], _ signature: [UInt8], _ message: [UInt8]) -> Bool {
    guard signature.count == 64, let A = _ed25519Decode(publicKey) else { return false }
    let Rbytes = Array(signature.prefix(32))
    let Sbytes = Array(signature.suffix(32))
    guard let R = _ed25519Decode(Rbytes) else { return false }
    let S = _ckNatFromLE(Sbytes)
    if S >= _ed25519L { return false }
    let k = _ed25519ReduceL(Array(SHA512.hash(data: Data(Rbytes + publicKey + message))))
    let left = _EdPoint.base.scaled(S)
    let right = R.adding(A.scaled(k))
    let la = left.affine()
    let ra = right.affine()
    return la.x == ra.x && la.y == ra.y
}

// MARK: - NIST Weierstrass curves (FIPS 186-4)

struct _NISTCurve {
    let name: String
    let p: _CKNat
    let n: _CKNat
    let b: _CKNat
    let gx: _CKNat
    let gy: _CKNat
    let coordinateByteCount: Int
    let oid: [UInt8]
    let pemCurveName: String

    var a: _CKNat { p.modSub(_CKNat(3), p) }

    static let p256 = _NISTCurve(
        name: "P-256",
        p: _ckNatFromHex("ffffffff00000001000000000000000000000000ffffffffffffffffffffffff"),
        n: _ckNatFromHex("ffffffff00000000ffffffffffffffffbce6faada7179e84f3b9cac2fc632551"),
        b: _ckNatFromHex("5ac635d8aa3a93e7b3ebbd55769886bc651d06b0cc53b0f63bce3c3e27d2604b"),
        gx: _ckNatFromHex("6b17d1f2e12c4247f8bce6e563a440f277037d812deb33a0f4a13945d898c296"),
        gy: _ckNatFromHex("4fe342e2fe1a7f9b8ee7eb4a7c0f9e162bce33576b315ececbb6406837bf51f5"),
        coordinateByteCount: 32,
        oid: [0x2a, 0x86, 0x48, 0xce, 0x3d, 0x03, 0x01, 0x07],
        pemCurveName: "prime256v1"
    )

    static let p384 = _NISTCurve(
        name: "P-384",
        p: _ckNatFromHex("fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffeffffffff0000000000000000ffffffff"),
        n: _ckNatFromHex("ffffffffffffffffffffffffffffffffffffffffffffffffc7634d81f4372ddf581a0db248b0a77aecec196accc52973"),
        b: _ckNatFromHex("b3312fa7e23ee7e4988e056be3f82d19181d9c6efe8141120314088f5013875ac656398d8a2ed19d2a85c8edd3ec2aef"),
        gx: _ckNatFromHex("aa87ca22be8b05378eb1c71ef320ad746e1d3b628ba79b9859f741e082542a385502f25dbf55296c3a545e3872760ab7"),
        gy: _ckNatFromHex("3617de4a96262c6f5d9e98bf9292dc29f8f41dbd289a147ce9da3113b5f0b8c00a60b1ce1d7e819d7a431d7c90ea0e5f"),
        coordinateByteCount: 48,
        oid: [0x2b, 0x81, 0x04, 0x00, 0x22],
        pemCurveName: "secp384r1"
    )

    static let p521 = _NISTCurve(
        name: "P-521",
        p: _ckNatFromHex("01ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff"),
        n: _ckNatFromHex("01fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffa51868783bf2f966b7fcc0148f709a5d03bb5c9b8899c47aebb6fb71e91386409"),
        b: _ckNatFromHex("0051953eb9618e1c9a1f929a21a0b68540eea2da725b99b315f3b8b489918ef109e156193951ec7e937b1652c0bd3bb1bf073573df883d2c34f1ef451fd46b503f00"),
        gx: _ckNatFromHex("00c6858e06b70404e9cd9e3ecb662395b4429c648139053fb521f828af606b4d3dbaa14b5e77efe75928fe1dc127a2ffa8de3348b3c1856a429bf97e7e31c2e5bd66"),
        gy: _ckNatFromHex("011839296a789a3bc0045c8a5fb42c7d1bd998f54449579b446817afbd17273e662c97ee72995ef42640c550b9013fad0761353c7086a272c24088be94769fd16650"),
        coordinateByteCount: 66,
        oid: [0x2b, 0x81, 0x04, 0x00, 0x23],
        pemCurveName: "secp521r1"
    )
}

struct _NISTPoint {
    var x: _CKNat
    var y: _CKNat
    var infinity: Bool

    static let infinity = _NISTPoint(x: .zero, y: .zero, infinity: true)

    static func affine(_ x: _CKNat, _ y: _CKNat) -> _NISTPoint {
        _NISTPoint(x: x, y: y, infinity: false)
    }
}

func _nistOnCurve(_ point: _NISTPoint, _ curve: _NISTCurve) -> Bool {
    if point.infinity { return false }
    if point.x >= curve.p || point.y >= curve.p { return false }
    let yy = point.y.modMul(point.y, curve.p)
    let xx = point.x.modMul(point.x, curve.p)
    let rhs = xx.modMul(point.x, curve.p)
        .modAdd(curve.a.modMul(point.x, curve.p), curve.p)
        .modAdd(curve.b, curve.p)
    return yy == rhs
}

func _nistAdd(_ p: _NISTPoint, _ q: _NISTPoint, _ curve: _NISTCurve) -> _NISTPoint {
    if p.infinity { return q }
    if q.infinity { return p }
    if p.x == q.x {
        if p.y == q.y { return _nistDouble(p, curve) }
        return .infinity
    }
    let lambda = q.y.modSub(p.y, curve.p).modMul(q.x.modSub(p.x, curve.p).modInverse(curve.p), curve.p)
    let x = lambda.modMul(lambda, curve.p).modSub(p.x, curve.p).modSub(q.x, curve.p)
    let y = lambda.modMul(p.x.modSub(x, curve.p), curve.p).modSub(p.y, curve.p)
    return .affine(x, y)
}

func _nistDouble(_ p: _NISTPoint, _ curve: _NISTCurve) -> _NISTPoint {
    if p.infinity || p.y.isZero { return .infinity }
    let xx = p.x.modMul(p.x, curve.p)
    let num = xx.modAdd(xx, curve.p).modAdd(xx, curve.p).modAdd(curve.a, curve.p)
    let den = p.y.modAdd(p.y, curve.p).modInverse(curve.p)
    let lambda = num.modMul(den, curve.p)
    let x = lambda.modMul(lambda, curve.p).modSub(p.x, curve.p).modSub(p.x, curve.p)
    let y = lambda.modMul(p.x.modSub(x, curve.p), curve.p).modSub(p.y, curve.p)
    return .affine(x, y)
}

func _nistScale(_ point: _NISTPoint, _ scalar: _CKNat, _ curve: _NISTCurve) -> _NISTPoint {
    if point.infinity || scalar.isZero { return .infinity }
    var rx = _CKNat.zero
    var ry = _CKNat.zero
    var rz = _CKNat.zero
    var inf = true
    var ax = point.x
    var ay = point.y
    var az = _CKNat.one
    var k = scalar
    while !k.isZero {
        if k.bit(0) {
            if inf {
                rx = ax
                ry = ay
                rz = az
                inf = false
            } else {
                let added = _nistJacAdd(rx, ry, rz, ax, ay, az, curve)
                rx = added.0
                ry = added.1
                rz = added.2
                inf = added.3
            }
        }
        let doubled = _nistJacDoubleCoords(ax, ay, az, curve)
        ax = doubled.0
        ay = doubled.1
        az = doubled.2
        k = k.shiftedRight(1)
    }
    if inf { return .infinity }
    let zInv = rz.modInverse(curve.p)
    let z2 = zInv.modMul(zInv, curve.p)
    let z3 = z2.modMul(zInv, curve.p)
    return .affine(rx.modMul(z2, curve.p), ry.modMul(z3, curve.p))
}

func _nistJacDoubleCoords(_ x: _CKNat, _ y: _CKNat, _ z: _CKNat, _ curve: _NISTCurve) -> (_CKNat, _CKNat, _CKNat) {
    let p = curve.p
    let yy = y.modMul(y, p)
    let zz = z.modMul(z, p)
    let xyy = x.modMul(yy, p)
    let fourXyy = xyy.modAdd(xyy, p).modAdd(xyy.modAdd(xyy, p), p)
    let xx = x.modMul(x, p)
    let z4 = zz.modMul(zz, p)
    let m = xx.modAdd(xx, p).modAdd(xx, p).modSub(z4.modMul(_CKNat(3), p), p)
    let x3 = m.modMul(m, p).modSub(fourXyy.modAdd(fourXyy, p), p)
    let yyyy = yy.modMul(yy, p)
    let eightYYYY = yyyy.modAdd(yyyy, p)
    let eight2 = eightYYYY.modAdd(eightYYYY, p)
    let eight4 = eight2.modAdd(eight2, p)
    let y3 = m.modMul(fourXyy.modSub(x3, p), p).modSub(eight4, p)
    let yz = y.modAdd(z, p)
    let z3 = yz.modMul(yz, p).modSub(yy, p).modSub(zz, p)
    return (x3, y3, z3)
}

func _nistJacAdd(
    _ x1: _CKNat, _ y1: _CKNat, _ z1: _CKNat,
    _ x2: _CKNat, _ y2: _CKNat, _ z2: _CKNat,
    _ curve: _NISTCurve
) -> (_CKNat, _CKNat, _CKNat, Bool) {
    let p = curve.p
    let z1z1 = z1.modMul(z1, p)
    let z2z2 = z2.modMul(z2, p)
    let u1 = x1.modMul(z2z2, p)
    let u2 = x2.modMul(z1z1, p)
    let z1z2z2 = z2.modMul(z2z2, p)
    let z2z1z1 = z1.modMul(z1z1, p)
    let s1 = y1.modMul(z1z2z2, p)
    let s2 = y2.modMul(z2z1z1, p)
    if u1 == u2 {
        if s1 == s2 {
            let d = _nistJacDoubleCoords(x1, y1, z1, curve)
            return (d.0, d.1, d.2, false)
        }
        return (.zero, .zero, .zero, true)
    }
    let h = u2.modSub(u1, p)
    let r = s2.modSub(s1, p)
    let h2 = h.modMul(h, p)
    let h3 = h.modMul(h2, p)
    let u1h2 = u1.modMul(h2, p)
    let x3 = r.modMul(r, p).modSub(h3, p).modSub(u1h2.modAdd(u1h2, p), p)
    let y3 = r.modMul(u1h2.modSub(x3, p), p).modSub(s1.modMul(h3, p), p)
    let z3 = z1.modMul(z2, p).modMul(h, p)
    return (x3, y3, z3, false)
}

func _nistGenerator(_ curve: _NISTCurve) -> _NISTPoint {
    .affine(curve.gx, curve.gy)
}

func _nistPublicPoint(_ scalar: _CKNat, _ curve: _NISTCurve) -> _NISTPoint {
    _nistScale(_nistGenerator(curve), scalar, curve)
}

func _nistIsValidScalar(_ scalar: _CKNat, _ curve: _NISTCurve) -> Bool {
    !scalar.isZero && scalar < curve.n
}

func _nistRandomScalar(_ curve: _NISTCurve) -> _CKNat {
    while true {
        let bytes = _ckRandomBytes(curve.coordinateByteCount)
        let value = _ckNatFromBE(bytes).modulo(curve.n)
        if _nistIsValidScalar(value, curve) { return value }
    }
}

func _nistYFromX(_ x: _CKNat, even: Bool, _ curve: _NISTCurve) -> _CKNat? {
    let xx = x.modMul(x, curve.p)
    let rhs = xx.modMul(x, curve.p).modAdd(curve.a.modMul(x, curve.p), curve.p).modAdd(curve.b, curve.p)
    guard let y = _nistSqrt(rhs, curve.p) else { return nil }
    if y.bit(0) != even { return y }
    return curve.p.modSub(y, curve.p)
}

func _nistSqrt(_ value: _CKNat, _ p: _CKNat) -> _CKNat? {
    if value.isZero { return .zero }
    // All three NIST primes are 3 mod 4, so sqrt(a) = a^((p+1)/4).
    let exp = (p + .one).shiftedRight(2)
    let root = value.modPow(exp, p)
    if root.modMul(root, p) == value { return root }
    return nil
}

func _ecdsaSign(
    _ curve: _NISTCurve,
    scalar: _CKNat,
    digest: [UInt8]
) -> (r: _CKNat, s: _CKNat) {
    let e = _ecdsaInteger(digest, curve)
    while true {
        let k = _nistRandomScalar(curve)
        let R = _nistPublicPoint(k, curve)
        if R.infinity { continue }
        let r = R.x.modulo(curve.n)
        if r.isZero { continue }
        let s = k.modInverse(curve.n).modMul(e.modAdd(r.modMul(scalar, curve.n), curve.n), curve.n)
        if s.isZero { continue }
        return (r, s)
    }
}

func _ecdsaVerify(
    _ curve: _NISTCurve,
    publicPoint: _NISTPoint,
    digest: [UInt8],
    r: _CKNat,
    s: _CKNat
) -> Bool {
    guard _nistOnCurve(publicPoint, curve) else { return false }
    if r.isZero || s.isZero || r >= curve.n || s >= curve.n { return false }
    let e = _ecdsaInteger(digest, curve)
    let w = s.modInverse(curve.n)
    let u1 = e.modMul(w, curve.n)
    let u2 = r.modMul(w, curve.n)
    let point = _nistAdd(
        _nistScale(_nistGenerator(curve), u1, curve),
        _nistScale(publicPoint, u2, curve),
        curve
    )
    if point.infinity { return false }
    return point.x.modulo(curve.n) == r
}

func _ecdsaInteger(_ digest: [UInt8], _ curve: _NISTCurve) -> _CKNat {
    var bytes = digest
    let maxBytes = (curve.n.bitWidth + 7) / 8
    if bytes.count > maxBytes {
        bytes = Array(bytes.prefix(maxBytes))
    }
    var value = _ckNatFromBE(bytes)
    let excess = bytes.count * 8 - curve.n.bitWidth
    if excess > 0 { value = value.shiftedRight(excess) }
    return value.modulo(curve.n)
}
