// Digest functions. SHA-256 streaming matches the existing C guest
// (`CommonDigest.c`) byte-count / IV layout so C and Swift vectors agree.

private enum _CCAccum {
    static var bytes: [UInt: [UInt8]] = [:]

    static func key(_ pointer: UnsafeRawPointer) -> UInt {
        UInt(bitPattern: pointer)
    }

    static func reset(_ pointer: UnsafeRawPointer) {
        bytes[key(pointer)] = []
    }

    static func append(_ pointer: UnsafeRawPointer, _ data: [UInt8]) {
        var current = bytes[key(pointer)] ?? []
        current.append(contentsOf: data)
        bytes[key(pointer)] = current
    }

    static func take(_ pointer: UnsafeRawPointer) -> [UInt8] {
        let current = bytes[key(pointer)] ?? []
        bytes[key(pointer)] = nil
        return current
    }
}

private func _ccLoad32BE(_ bytes: [UInt8], _ offset: Int) -> UInt32 {
    (UInt32(bytes[offset]) << 24)
        | (UInt32(bytes[offset + 1]) << 16)
        | (UInt32(bytes[offset + 2]) << 8)
        | UInt32(bytes[offset + 3])
}

private func _ccLoad32LE(_ bytes: [UInt8], _ offset: Int) -> UInt32 {
    UInt32(bytes[offset])
        | (UInt32(bytes[offset + 1]) << 8)
        | (UInt32(bytes[offset + 2]) << 16)
        | (UInt32(bytes[offset + 3]) << 24)
}

private func _ccStore32BE(_ value: UInt32, into output: inout [UInt8]) {
    output.append(UInt8(truncatingIfNeeded: value >> 24))
    output.append(UInt8(truncatingIfNeeded: value >> 16))
    output.append(UInt8(truncatingIfNeeded: value >> 8))
    output.append(UInt8(truncatingIfNeeded: value))
}

private func _ccStore32LE(_ value: UInt32, into output: inout [UInt8]) {
    output.append(UInt8(truncatingIfNeeded: value))
    output.append(UInt8(truncatingIfNeeded: value >> 8))
    output.append(UInt8(truncatingIfNeeded: value >> 16))
    output.append(UInt8(truncatingIfNeeded: value >> 24))
}

private func _ccStore64BE(_ value: UInt64, into output: inout [UInt8]) {
    output.append(UInt8(truncatingIfNeeded: value >> 56))
    output.append(UInt8(truncatingIfNeeded: value >> 48))
    output.append(UInt8(truncatingIfNeeded: value >> 40))
    output.append(UInt8(truncatingIfNeeded: value >> 32))
    output.append(UInt8(truncatingIfNeeded: value >> 24))
    output.append(UInt8(truncatingIfNeeded: value >> 16))
    output.append(UInt8(truncatingIfNeeded: value >> 8))
    output.append(UInt8(truncatingIfNeeded: value))
}

private func _ccLoad64BE(_ bytes: [UInt8], _ offset: Int) -> UInt64 {
    var value: UInt64 = 0
    for index in 0..<8 {
        value = (value << 8) | UInt64(bytes[offset + index])
    }
    return value
}

private func _ccPad(_ input: [UInt8], block: Int, lengthBytes: Int, littleEndianLength: Bool) -> [UInt8] {
    var message = input
    message.append(0x80)
    while (message.count % block) != (block - lengthBytes) {
        message.append(0)
    }
    let bitCount = UInt64(input.count) * 8
    if littleEndianLength {
        _ccStore32LE(UInt32(truncatingIfNeeded: bitCount), into: &message)
        _ccStore32LE(UInt32(truncatingIfNeeded: bitCount >> 32), into: &message)
    } else if lengthBytes == 8 {
        _ccStore32BE(UInt32(truncatingIfNeeded: bitCount >> 32), into: &message)
        _ccStore32BE(UInt32(truncatingIfNeeded: bitCount), into: &message)
    } else {
        for _ in 0..<8 { message.append(0) }
        _ccStore64BE(bitCount, into: &message)
    }
    return message
}

private let _ccSHA256K: [UInt32] = [
    0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5,
    0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
    0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3,
    0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
    0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc,
    0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
    0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7,
    0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
    0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13,
    0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
    0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3,
    0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
    0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5,
    0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
    0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208,
    0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2,
]

private let _ccSHA512K: [UInt64] = [
    0x428a2f98d728ae22, 0x7137449123ef65cd, 0xb5c0fbcfec4d3b2f, 0xe9b5dba58189dbbc,
    0x3956c25bf348b538, 0x59f111f1b605d019, 0x923f82a4af194f9b, 0xab1c5ed5da6d8118,
    0xd807aa98a3030242, 0x12835b0145706fbe, 0x243185be4ee4b28c, 0x550c7dc3d5ffb4e2,
    0x72be5d74f27b896f, 0x80deb1fe3b1696b1, 0x9bdc06a725c71235, 0xc19bf174cf692694,
    0xe49b69c19ef14ad2, 0xefbe4786384f25e3, 0x0fc19dc68b8cd5b5, 0x240ca1cc77ac9c65,
    0x2de92c6f592b0275, 0x4a7484aa6ea6e483, 0x5cb0a9dcbd41fbd4, 0x76f988da831153b5,
    0x983e5152ee66dfab, 0xa831c66d2db43210, 0xb00327c898fb213f, 0xbf597fc7beef0ee4,
    0xc6e00bf33da88fc2, 0xd5a79147930aa725, 0x06ca6351e003826f, 0x142929670a0e6e70,
    0x27b70a8546d22ffc, 0x2e1b21385c26c926, 0x4d2c6dfc5ac42aed, 0x53380d139d95b3df,
    0x650a73548baf63de, 0x766a0abb3c77b2a8, 0x81c2c92e47edaee6, 0x92722c851482353b,
    0xa2bfe8a14cf10364, 0xa81a664bbc423001, 0xc24b8b70d0f89791, 0xc76c51a30654be30,
    0xd192e819d6ef5218, 0xd69906245565a910, 0xf40e35855771202a, 0x106aa07032bbd1b8,
    0x19a4c116b8d2d0c8, 0x1e376c085141ab53, 0x2748774cdf8eeb99, 0x34b0bcb5e19b48a8,
    0x391c0cb3c5c95a63, 0x4ed8aa4ae3418acb, 0x5b9cca4f7763e373, 0x682e6ff3d6b2b8a3,
    0x748f82ee5defb2fc, 0x78a5636f43172f60, 0x84c87814a1f0ab72, 0x8cc702081a6439ec,
    0x90befffa23631e28, 0xa4506cebde82bde9, 0xbef9a3f7b2c67915, 0xc67178f2e372532b,
    0xca273eceea26619c, 0xd186b8c721c0c207, 0xeada7dd6cde0eb1e, 0xf57d4f7fee6ed178,
    0x06f067aa72176fba, 0x0a637dc5a2c898a6, 0x113f9804bef90dae, 0x1b710b35131c471b,
    0x28db77f523047d84, 0x32caab7b40c72493, 0x3c9ebe0a15c9bebc, 0x431d67c49c100d4c,
    0x4cc5d4becb3e42b6, 0x597f299cfc657e2a, 0x5fcb6fab3ad6faec, 0x6c44198c4a475817,
]

private let _ccMD2S: [UInt8] = [
    41, 46, 67, 201, 162, 216, 124, 1, 61, 54, 84, 161, 236, 240, 6,
    19, 98, 167, 5, 243, 192, 199, 115, 140, 152, 147, 43, 217, 188,
    76, 130, 202, 30, 155, 87, 60, 253, 212, 224, 22, 103, 66, 111, 24,
    138, 23, 229, 18, 190, 78, 196, 214, 218, 158, 222, 73, 160, 251,
    245, 142, 187, 47, 238, 122, 169, 104, 121, 145, 21, 178, 7, 63,
    148, 194, 16, 137, 11, 34, 95, 33, 128, 127, 93, 154, 90, 144, 50,
    39, 53, 62, 204, 231, 191, 247, 151, 3, 255, 25, 48, 179, 72, 165,
    181, 209, 215, 94, 146, 42, 172, 86, 170, 198, 79, 184, 56, 210,
    150, 164, 125, 182, 118, 252, 107, 226, 156, 116, 4, 241, 69, 157,
    112, 89, 100, 113, 135, 32, 134, 91, 207, 101, 230, 45, 168, 2, 27,
    96, 37, 173, 174, 176, 185, 246, 28, 70, 97, 105, 52, 64, 126, 15,
    85, 71, 163, 35, 221, 81, 175, 58, 195, 92, 249, 206, 186, 197,
    234, 38, 44, 83, 13, 110, 133, 40, 132, 9, 211, 223, 205, 244, 65,
    129, 77, 82, 106, 220, 55, 200, 108, 193, 171, 250, 36, 225, 123,
    8, 12, 189, 177, 74, 120, 136, 149, 139, 227, 99, 232, 109, 233,
    203, 213, 254, 59, 0, 29, 57, 242, 239, 183, 14, 102, 88, 208, 228,
    166, 119, 114, 248, 235, 117, 75, 10, 49, 68, 80, 180, 143, 237,
    31, 26, 219, 153, 141, 51, 159, 17, 131, 20,
]

func _ccSHA256(_ input: [UInt8], variant224: Bool = false) -> [UInt8] {
    let message = _ccPad(input, block: 64, lengthBytes: 8, littleEndianLength: false)
    var state: [UInt32] = variant224 ? [
        0xc1059ed8, 0x367cd507, 0x3070dd17, 0xf70e5939,
        0xffc00b31, 0x68581511, 0x64f98fa7, 0xbefa4fa4,
    ] : [
        0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a,
        0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19,
    ]
    var offset = 0
    while offset < message.count {
        var words = [UInt32](repeating: 0, count: 64)
        for index in 0..<16 {
            words[index] = _ccLoad32BE(message, offset + index * 4)
        }
        for index in 16..<64 {
            let x = words[index - 15]
            let y = words[index - 2]
            let s0 = x._ccRotR(7) ^ x._ccRotR(18) ^ (x >> 3)
            let s1 = y._ccRotR(17) ^ y._ccRotR(19) ^ (y >> 10)
            words[index] = words[index - 16] &+ s0 &+ words[index - 7] &+ s1
        }
        var a = state[0], b = state[1], c = state[2], d = state[3]
        var e = state[4], f = state[5], g = state[6], h = state[7]
        for index in 0..<64 {
            let s1 = e._ccRotR(6) ^ e._ccRotR(11) ^ e._ccRotR(25)
            let choose = (e & f) ^ ((~e) & g)
            let t1 = h &+ s1 &+ choose &+ _ccSHA256K[index] &+ words[index]
            let s0 = a._ccRotR(2) ^ a._ccRotR(13) ^ a._ccRotR(22)
            let majority = (a & b) ^ (a & c) ^ (b & c)
            let t2 = s0 &+ majority
            h = g; g = f; f = e; e = d &+ t1
            d = c; c = b; b = a; a = t1 &+ t2
        }
        state[0] &+= a; state[1] &+= b; state[2] &+= c; state[3] &+= d
        state[4] &+= e; state[5] &+= f; state[6] &+= g; state[7] &+= h
        offset += 64
    }
    var digest: [UInt8] = []
    let count = variant224 ? 7 : 8
    for index in 0..<count {
        _ccStore32BE(state[index], into: &digest)
    }
    if variant224 {
        digest = Array(digest.prefix(28))
    }
    return digest
}

func _ccSHA512(_ input: [UInt8], variant384: Bool) -> [UInt8] {
    let message = _ccPad(input, block: 128, lengthBytes: 16, littleEndianLength: false)
    var state: [UInt64] = variant384 ? [
        0xcbbb9d5dc1059ed8, 0x629a292a367cd507, 0x9159015a3070dd17, 0x152fecd8f70e5939,
        0x67332667ffc00b31, 0x8eb44a8768581511, 0xdb0c2e0d64f98fa7, 0x47b5481dbefa4fa4,
    ] : [
        0x6a09e667f3bcc908, 0xbb67ae8584caa73b, 0x3c6ef372fe94f82b, 0xa54ff53a5f1d36f1,
        0x510e527fade682d1, 0x9b05688c2b3e6c1f, 0x1f83d9abfb41bd6b, 0x5be0cd19137e2179,
    ]
    var offset = 0
    while offset < message.count {
        var words = [UInt64](repeating: 0, count: 80)
        for index in 0..<16 {
            words[index] = _ccLoad64BE(message, offset + index * 8)
        }
        for index in 16..<80 {
            let x = words[index - 15]
            let y = words[index - 2]
            let s0 = x._ccRotR(1) ^ x._ccRotR(8) ^ (x >> 7)
            let s1 = y._ccRotR(19) ^ y._ccRotR(61) ^ (y >> 6)
            words[index] = words[index - 16] &+ s0 &+ words[index - 7] &+ s1
        }
        var a = state[0], b = state[1], c = state[2], d = state[3]
        var e = state[4], f = state[5], g = state[6], h = state[7]
        for index in 0..<80 {
            let s1 = e._ccRotR(14) ^ e._ccRotR(18) ^ e._ccRotR(41)
            let choose = (e & f) ^ ((~e) & g)
            let t1 = h &+ s1 &+ choose &+ _ccSHA512K[index] &+ words[index]
            let s0 = a._ccRotR(28) ^ a._ccRotR(34) ^ a._ccRotR(39)
            let majority = (a & b) ^ (a & c) ^ (b & c)
            let t2 = s0 &+ majority
            h = g; g = f; f = e; e = d &+ t1
            d = c; c = b; b = a; a = t1 &+ t2
        }
        state[0] &+= a; state[1] &+= b; state[2] &+= c; state[3] &+= d
        state[4] &+= e; state[5] &+= f; state[6] &+= g; state[7] &+= h
        offset += 128
    }
    var digest: [UInt8] = []
    let count = variant384 ? 6 : 8
    for index in 0..<count {
        _ccStore64BE(state[index], into: &digest)
    }
    return digest
}

func _ccSHA1(_ input: [UInt8]) -> [UInt8] {
    let message = _ccPad(input, block: 64, lengthBytes: 8, littleEndianLength: false)
    var state: [UInt32] = [
        0x67452301, 0xefcdab89, 0x98badcfe, 0x10325476, 0xc3d2e1f0,
    ]
    var offset = 0
    while offset < message.count {
        var words = [UInt32](repeating: 0, count: 80)
        for index in 0..<16 {
            words[index] = _ccLoad32BE(message, offset + index * 4)
        }
        for index in 16..<80 {
            words[index] = (words[index - 3] ^ words[index - 8] ^ words[index - 14] ^ words[index - 16])._ccRotL(1)
        }
        var a = state[0], b = state[1], c = state[2], d = state[3], e = state[4]
        for index in 0..<80 {
            let f: UInt32
            let k: UInt32
            switch index {
            case 0..<20:
                f = (b & c) | ((~b) & d)
                k = 0x5a827999
            case 20..<40:
                f = b ^ c ^ d
                k = 0x6ed9eba1
            case 40..<60:
                f = (b & c) | (b & d) | (c & d)
                k = 0x8f1bbcdc
            default:
                f = b ^ c ^ d
                k = 0xca62c1d6
            }
            let temp = a._ccRotL(5) &+ f &+ e &+ k &+ words[index]
            e = d
            d = c
            c = b._ccRotL(30)
            b = a
            a = temp
        }
        state[0] &+= a; state[1] &+= b; state[2] &+= c; state[3] &+= d; state[4] &+= e
        offset += 64
    }
    var digest: [UInt8] = []
    for value in state {
        _ccStore32BE(value, into: &digest)
    }
    return digest
}

func _ccMD5(_ input: [UInt8]) -> [UInt8] {
    let s: [UInt32] = [
        7, 12, 17, 22, 7, 12, 17, 22, 7, 12, 17, 22, 7, 12, 17, 22,
        5, 9, 14, 20, 5, 9, 14, 20, 5, 9, 14, 20, 5, 9, 14, 20,
        4, 11, 16, 23, 4, 11, 16, 23, 4, 11, 16, 23, 4, 11, 16, 23,
        6, 10, 15, 21, 6, 10, 15, 21, 6, 10, 15, 21, 6, 10, 15, 21,
    ]
    let k: [UInt32] = [
        0xd76aa478, 0xe8c7b756, 0x242070db, 0xc1bdceee, 0xf57c0faf, 0x4787c62a, 0xa8304613, 0xfd469501,
        0x698098d8, 0x8b44f7af, 0xffff5bb1, 0x895cd7be, 0x6b901122, 0xfd987193, 0xa679438e, 0x49b40821,
        0xf61e2562, 0xc040b340, 0x265e5a51, 0xe9b6c7aa, 0xd62f105d, 0x02441453, 0xd8a1e681, 0xe7d3fbc8,
        0x21e1cde6, 0xc33707d6, 0xf4d50d87, 0x455a14ed, 0xa9e3e905, 0xfcefa3f8, 0x676f02d9, 0x8d2a4c8a,
        0xfffa3942, 0x8771f681, 0x6d9d6122, 0xfde5380c, 0xa4beea44, 0x4bdecfa9, 0xf6bb4b60, 0xbebfbc70,
        0x289b7ec6, 0xeaa127fa, 0xd4ef3085, 0x04881d05, 0xd9d4d039, 0xe6db99e5, 0x1fa27cf8, 0xc4ac5665,
        0xf4292244, 0x432aff97, 0xab9423a7, 0xfc93a039, 0x655b59c3, 0x8f0ccc92, 0xffeff47d, 0x85845dd1,
        0x6fa87e4f, 0xfe2ce6e0, 0xa3014314, 0x4e0811a1, 0xf7537e82, 0xbd3af235, 0x2ad7d2bb, 0xeb86d391,
    ]
    let message = _ccPad(input, block: 64, lengthBytes: 8, littleEndianLength: true)
    var a0: UInt32 = 0x67452301
    var b0: UInt32 = 0xefcdab89
    var c0: UInt32 = 0x98badcfe
    var d0: UInt32 = 0x10325476
    var offset = 0
    while offset < message.count {
        var m = [UInt32](repeating: 0, count: 16)
        for index in 0..<16 {
            m[index] = _ccLoad32LE(message, offset + index * 4)
        }
        var a = a0, b = b0, c = c0, d = d0
        for i in 0..<64 {
            let f: UInt32
            let g: Int
            switch i {
            case 0..<16:
                f = (b & c) | ((~b) & d)
                g = i
            case 16..<32:
                f = (d & b) | ((~d) & c)
                g = (5 * i + 1) % 16
            case 32..<48:
                f = b ^ c ^ d
                g = (3 * i + 5) % 16
            default:
                f = c ^ (b | (~d))
                g = (7 * i) % 16
            }
            let temp = d
            d = c
            c = b
            b = b &+ (a &+ f &+ k[i] &+ m[g])._ccRotL(s[i])
            a = temp
        }
        a0 &+= a; b0 &+= b; c0 &+= c; d0 &+= d
        offset += 64
    }
    var digest: [UInt8] = []
    _ccStore32LE(a0, into: &digest)
    _ccStore32LE(b0, into: &digest)
    _ccStore32LE(c0, into: &digest)
    _ccStore32LE(d0, into: &digest)
    return digest
}

func _ccMD4(_ input: [UInt8]) -> [UInt8] {
    let message = _ccPad(input, block: 64, lengthBytes: 8, littleEndianLength: true)
    var a0: UInt32 = 0x67452301
    var b0: UInt32 = 0xefcdab89
    var c0: UInt32 = 0x98badcfe
    var d0: UInt32 = 0x10325476
    var offset = 0
    while offset < message.count {
        var x = [UInt32](repeating: 0, count: 16)
        for index in 0..<16 {
            x[index] = _ccLoad32LE(message, offset + index * 4)
        }
        var a = a0, b = b0, c = c0, d = d0
        func f(_ x: UInt32, _ y: UInt32, _ z: UInt32) -> UInt32 { (x & y) | ((~x) & z) }
        func g(_ x: UInt32, _ y: UInt32, _ z: UInt32) -> UInt32 { (x & y) | (x & z) | (y & z) }
        func h(_ x: UInt32, _ y: UInt32, _ z: UInt32) -> UInt32 { x ^ y ^ z }
        func round1(_ a: inout UInt32, _ b: UInt32, _ c: UInt32, _ d: UInt32, _ k: Int, _ s: UInt32) {
            a = (a &+ f(b, c, d) &+ x[k])._ccRotL(s)
        }
        func round2(_ a: inout UInt32, _ b: UInt32, _ c: UInt32, _ d: UInt32, _ k: Int, _ s: UInt32) {
            a = (a &+ g(b, c, d) &+ x[k] &+ 0x5a827999)._ccRotL(s)
        }
        func round3(_ a: inout UInt32, _ b: UInt32, _ c: UInt32, _ d: UInt32, _ k: Int, _ s: UInt32) {
            a = (a &+ h(b, c, d) &+ x[k] &+ 0x6ed9eba1)._ccRotL(s)
        }
        round1(&a, b, c, d, 0, 3); round1(&d, a, b, c, 1, 7); round1(&c, d, a, b, 2, 11); round1(&b, c, d, a, 3, 19)
        round1(&a, b, c, d, 4, 3); round1(&d, a, b, c, 5, 7); round1(&c, d, a, b, 6, 11); round1(&b, c, d, a, 7, 19)
        round1(&a, b, c, d, 8, 3); round1(&d, a, b, c, 9, 7); round1(&c, d, a, b, 10, 11); round1(&b, c, d, a, 11, 19)
        round1(&a, b, c, d, 12, 3); round1(&d, a, b, c, 13, 7); round1(&c, d, a, b, 14, 11); round1(&b, c, d, a, 15, 19)
        round2(&a, b, c, d, 0, 3); round2(&d, a, b, c, 4, 5); round2(&c, d, a, b, 8, 9); round2(&b, c, d, a, 12, 13)
        round2(&a, b, c, d, 1, 3); round2(&d, a, b, c, 5, 5); round2(&c, d, a, b, 9, 9); round2(&b, c, d, a, 13, 13)
        round2(&a, b, c, d, 2, 3); round2(&d, a, b, c, 6, 5); round2(&c, d, a, b, 10, 9); round2(&b, c, d, a, 14, 13)
        round2(&a, b, c, d, 3, 3); round2(&d, a, b, c, 7, 5); round2(&c, d, a, b, 11, 9); round2(&b, c, d, a, 15, 13)
        round3(&a, b, c, d, 0, 3); round3(&d, a, b, c, 8, 9); round3(&c, d, a, b, 4, 11); round3(&b, c, d, a, 12, 15)
        round3(&a, b, c, d, 2, 3); round3(&d, a, b, c, 10, 9); round3(&c, d, a, b, 6, 11); round3(&b, c, d, a, 14, 15)
        round3(&a, b, c, d, 1, 3); round3(&d, a, b, c, 9, 9); round3(&c, d, a, b, 5, 11); round3(&b, c, d, a, 13, 15)
        round3(&a, b, c, d, 3, 3); round3(&d, a, b, c, 11, 9); round3(&c, d, a, b, 7, 11); round3(&b, c, d, a, 15, 15)
        a0 &+= a; b0 &+= b; c0 &+= c; d0 &+= d
        offset += 64
    }
    var digest: [UInt8] = []
    _ccStore32LE(a0, into: &digest)
    _ccStore32LE(b0, into: &digest)
    _ccStore32LE(c0, into: &digest)
    _ccStore32LE(d0, into: &digest)
    return digest
}

func _ccMD2(_ input: [UInt8]) -> [UInt8] {
    var x = [UInt8](repeating: 0, count: 48)
    var checksum = [UInt8](repeating: 0, count: 16)
    var l: UInt8 = 0
    func process(_ block: [UInt8]) {
        for j in 0..<16 {
            x[16 + j] = block[j]
            x[32 + j] = x[16 + j] ^ x[j]
        }
        var t: UInt8 = 0
        for j in 0..<18 {
            for k in 0..<48 {
                t = x[k] ^ _ccMD2S[Int(t)]
                x[k] = t
            }
            t = t &+ UInt8(j)
        }
        t = l
        for j in 0..<16 {
            t = checksum[j] ^ _ccMD2S[Int(block[j] ^ t)]
            checksum[j] = t
        }
        l = t
    }
    var offset = 0
    while offset + 16 <= input.count {
        process(Array(input[offset..<(offset + 16)]))
        offset += 16
    }
    var last = Array(input[offset...])
    let pad = 16 - last.count
    last.append(contentsOf: [UInt8](repeating: UInt8(pad), count: pad))
    process(last)
    process(checksum)
    return Array(x[0..<16])
}

private func _ccDigestBytes(_ data: UnsafeRawPointer?, _ len: CC_LONG) -> [UInt8]? {
    if len == 0 { return [] }
    guard let data else { return nil }
    return _ccCopy(data, Int(len))
}

private func _ccOneShot(
    _ data: UnsafeRawPointer!,
    _ len: CC_LONG,
    _ md: UnsafeMutablePointer<UInt8>!,
    hash: ([UInt8]) -> [UInt8]
) -> UnsafeMutablePointer<UInt8>! {
    guard let md else { return nil }
    guard let bytes = _ccDigestBytes(data, len) else { return nil }
    _ccWrite(hash(bytes), to: md)
    return md
}

public func CC_MD2(_ data: UnsafeRawPointer!, _ len: CC_LONG, _ md: UnsafeMutablePointer<UInt8>!) -> UnsafeMutablePointer<UInt8>! {
    _ccOneShot(data, len, md, hash: _ccMD2)
}

public func CC_MD2_Init(_ c: UnsafeMutablePointer<CC_MD2_CTX>!) -> Int32 {
    guard let c else { return 0 }
    c.pointee = CC_MD2_CTX()
    _CCAccum.reset(c)
    return 1
}

public func CC_MD2_Update(_ c: UnsafeMutablePointer<CC_MD2_CTX>!, _ data: UnsafeRawPointer!, _ len: CC_LONG) -> Int32 {
    guard let c else { return 0 }
    guard let bytes = _ccDigestBytes(data, len) else { return 0 }
    _CCAccum.append(c, bytes)
    c.pointee.num = Int32(_CCAccum.bytes[_CCAccum.key(c)]?.count ?? 0)
    return 1
}

public func CC_MD2_Final(_ md: UnsafeMutablePointer<UInt8>!, _ c: UnsafeMutablePointer<CC_MD2_CTX>!) -> Int32 {
    guard let c, let md else { return 0 }
    let digest = _ccMD2(_CCAccum.take(c))
    let padded = digest + [UInt8](repeating: 0, count: 16)
    c.pointee.data = _ccMakeU8x16(padded)
    _ccWrite(digest, to: md)
    return 1
}

public func CC_MD4(_ data: UnsafeRawPointer!, _ len: CC_LONG, _ md: UnsafeMutablePointer<UInt8>!) -> UnsafeMutablePointer<UInt8>! {
    _ccOneShot(data, len, md, hash: _ccMD4)
}

public func CC_MD4_Init(_ c: UnsafeMutablePointer<CC_MD4_CTX>!) -> Int32 {
    guard let c else { return 0 }
    c.pointee = CC_MD4_CTX()
    c.pointee.A = 0x67452301
    c.pointee.B = 0xefcdab89
    c.pointee.C = 0x98badcfe
    c.pointee.D = 0x10325476
    _CCAccum.reset(c)
    return 1
}

public func CC_MD4_Update(_ c: UnsafeMutablePointer<CC_MD4_CTX>!, _ data: UnsafeRawPointer!, _ len: CC_LONG) -> Int32 {
    guard let c else { return 0 }
    guard let bytes = _ccDigestBytes(data, len) else { return 0 }
    _CCAccum.append(c, bytes)
    return 1
}

public func CC_MD4_Final(_ md: UnsafeMutablePointer<UInt8>!, _ c: UnsafeMutablePointer<CC_MD4_CTX>!) -> Int32 {
    guard let c, let md else { return 0 }
    _ccWrite(_ccMD4(_CCAccum.take(c)), to: md)
    return 1
}

public func CC_MD5(_ data: UnsafeRawPointer!, _ len: CC_LONG, _ md: UnsafeMutablePointer<UInt8>!) -> UnsafeMutablePointer<UInt8>! {
    _ccOneShot(data, len, md, hash: _ccMD5)
}

public func CC_MD5_Init(_ c: UnsafeMutablePointer<CC_MD5_CTX>!) -> Int32 {
    guard let c else { return 0 }
    c.pointee = CC_MD5_CTX()
    c.pointee.A = 0x67452301
    c.pointee.B = 0xefcdab89
    c.pointee.C = 0x98badcfe
    c.pointee.D = 0x10325476
    _CCAccum.reset(c)
    return 1
}

public func CC_MD5_Update(_ c: UnsafeMutablePointer<CC_MD5_CTX>!, _ data: UnsafeRawPointer!, _ len: CC_LONG) -> Int32 {
    guard let c else { return 0 }
    guard let bytes = _ccDigestBytes(data, len) else { return 0 }
    _CCAccum.append(c, bytes)
    return 1
}

public func CC_MD5_Final(_ md: UnsafeMutablePointer<UInt8>!, _ c: UnsafeMutablePointer<CC_MD5_CTX>!) -> Int32 {
    guard let c, let md else { return 0 }
    _ccWrite(_ccMD5(_CCAccum.take(c)), to: md)
    return 1
}

public func CC_SHA1(_ data: UnsafeRawPointer!, _ len: CC_LONG, _ md: UnsafeMutablePointer<UInt8>!) -> UnsafeMutablePointer<UInt8>! {
    _ccOneShot(data, len, md, hash: _ccSHA1)
}

public func CC_SHA1_Init(_ c: UnsafeMutablePointer<CC_SHA1_CTX>!) -> Int32 {
    guard let c else { return 0 }
    c.pointee = CC_SHA1_CTX()
    c.pointee.h0 = 0x67452301
    c.pointee.h1 = 0xefcdab89
    c.pointee.h2 = 0x98badcfe
    c.pointee.h3 = 0x10325476
    c.pointee.h4 = 0xc3d2e1f0
    _CCAccum.reset(c)
    return 1
}

public func CC_SHA1_Update(_ c: UnsafeMutablePointer<CC_SHA1_CTX>!, _ data: UnsafeRawPointer!, _ len: CC_LONG) -> Int32 {
    guard let c else { return 0 }
    guard let bytes = _ccDigestBytes(data, len) else { return 0 }
    _CCAccum.append(c, bytes)
    return 1
}

public func CC_SHA1_Final(_ md: UnsafeMutablePointer<UInt8>!, _ c: UnsafeMutablePointer<CC_SHA1_CTX>!) -> Int32 {
    guard let c, let md else { return 0 }
    _ccWrite(_ccSHA1(_CCAccum.take(c)), to: md)
    return 1
}

public func CC_SHA224(_ data: UnsafeRawPointer!, _ len: CC_LONG, _ md: UnsafeMutablePointer<UInt8>!) -> UnsafeMutablePointer<UInt8>! {
    _ccOneShot(data, len, md, hash: { _ccSHA256($0, variant224: true) })
}

public func CC_SHA224_Init(_ c: UnsafeMutablePointer<CC_SHA256_CTX>!) -> Int32 {
    guard let c else { return 0 }
    c.pointee = CC_SHA256_CTX()
    c.pointee.hash = _ccMakeU32x8([
        0xc1059ed8, 0x367cd507, 0x3070dd17, 0xf70e5939,
        0xffc00b31, 0x68581511, 0x64f98fa7, 0xbefa4fa4,
    ])
    _CCAccum.reset(c)
    return 1
}

public func CC_SHA224_Update(_ c: UnsafeMutablePointer<CC_SHA256_CTX>!, _ data: UnsafeRawPointer!, _ len: CC_LONG) -> Int32 {
    guard let c else { return 0 }
    guard let bytes = _ccDigestBytes(data, len) else { return 0 }
    _CCAccum.append(c, bytes)
    return 1
}

public func CC_SHA224_Final(_ md: UnsafeMutablePointer<UInt8>!, _ c: UnsafeMutablePointer<CC_SHA256_CTX>!) -> Int32 {
    guard let c, let md else { return 0 }
    _ccWrite(_ccSHA256(_CCAccum.take(c), variant224: true), to: md)
    return 1
}

public func CC_SHA256(_ data: UnsafeRawPointer!, _ len: CC_LONG, _ md: UnsafeMutablePointer<UInt8>!) -> UnsafeMutablePointer<UInt8>! {
    _ccOneShot(data, len, md, hash: { _ccSHA256($0, variant224: false) })
}

public func CC_SHA256_Init(_ c: UnsafeMutablePointer<CC_SHA256_CTX>!) -> Int32 {
    guard let c else { return 0 }
    c.pointee = CC_SHA256_CTX()
    c.pointee.hash = _ccMakeU32x8([
        0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a,
        0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19,
    ])
    _CCAccum.reset(c)
    return 1
}

public func CC_SHA256_Update(_ c: UnsafeMutablePointer<CC_SHA256_CTX>!, _ data: UnsafeRawPointer!, _ len: CC_LONG) -> Int32 {
    guard let c else { return 0 }
    guard let bytes = _ccDigestBytes(data, len) else { return 0 }
    _CCAccum.append(c, bytes)
    let total = UInt64(_CCAccum.bytes[_CCAccum.key(c)]?.count ?? 0)
    c.pointee.count = _ccMakeU32x2([UInt32(truncatingIfNeeded: total), UInt32(truncatingIfNeeded: total >> 32)])
    return 1
}

public func CC_SHA256_Final(_ md: UnsafeMutablePointer<UInt8>!, _ c: UnsafeMutablePointer<CC_SHA256_CTX>!) -> Int32 {
    guard let c, let md else { return 0 }
    _ccWrite(_ccSHA256(_CCAccum.take(c), variant224: false), to: md)
    c.pointee = CC_SHA256_CTX()
    return 1
}

public func CC_SHA384(_ data: UnsafeRawPointer!, _ len: CC_LONG, _ md: UnsafeMutablePointer<UInt8>!) -> UnsafeMutablePointer<UInt8>! {
    _ccOneShot(data, len, md, hash: { _ccSHA512($0, variant384: true) })
}

public func CC_SHA384_Init(_ c: UnsafeMutablePointer<CC_SHA512_CTX>!) -> Int32 {
    guard let c else { return 0 }
    c.pointee = CC_SHA512_CTX()
    c.pointee.hash = _ccMakeU64x8([
        0xcbbb9d5dc1059ed8, 0x629a292a367cd507, 0x9159015a3070dd17, 0x152fecd8f70e5939,
        0x67332667ffc00b31, 0x8eb44a8768581511, 0xdb0c2e0d64f98fa7, 0x47b5481dbefa4fa4,
    ])
    _CCAccum.reset(c)
    return 1
}

public func CC_SHA384_Update(_ c: UnsafeMutablePointer<CC_SHA512_CTX>!, _ data: UnsafeRawPointer!, _ len: CC_LONG) -> Int32 {
    guard let c else { return 0 }
    guard let bytes = _ccDigestBytes(data, len) else { return 0 }
    _CCAccum.append(c, bytes)
    return 1
}

public func CC_SHA384_Final(_ md: UnsafeMutablePointer<UInt8>!, _ c: UnsafeMutablePointer<CC_SHA512_CTX>!) -> Int32 {
    guard let c, let md else { return 0 }
    _ccWrite(_ccSHA512(_CCAccum.take(c), variant384: true), to: md)
    return 1
}

public func CC_SHA512(_ data: UnsafeRawPointer!, _ len: CC_LONG, _ md: UnsafeMutablePointer<UInt8>!) -> UnsafeMutablePointer<UInt8>! {
    _ccOneShot(data, len, md, hash: { _ccSHA512($0, variant384: false) })
}

public func CC_SHA512_Init(_ c: UnsafeMutablePointer<CC_SHA512_CTX>!) -> Int32 {
    guard let c else { return 0 }
    c.pointee = CC_SHA512_CTX()
    c.pointee.hash = _ccMakeU64x8([
        0x6a09e667f3bcc908, 0xbb67ae8584caa73b, 0x3c6ef372fe94f82b, 0xa54ff53a5f1d36f1,
        0x510e527fade682d1, 0x9b05688c2b3e6c1f, 0x1f83d9abfb41bd6b, 0x5be0cd19137e2179,
    ])
    _CCAccum.reset(c)
    return 1
}

public func CC_SHA512_Update(_ c: UnsafeMutablePointer<CC_SHA512_CTX>!, _ data: UnsafeRawPointer!, _ len: CC_LONG) -> Int32 {
    guard let c else { return 0 }
    guard let bytes = _ccDigestBytes(data, len) else { return 0 }
    _CCAccum.append(c, bytes)
    return 1
}

public func CC_SHA512_Final(_ md: UnsafeMutablePointer<UInt8>!, _ c: UnsafeMutablePointer<CC_SHA512_CTX>!) -> Int32 {
    guard let c, let md else { return 0 }
    _ccWrite(_ccSHA512(_CCAccum.take(c), variant384: false), to: md)
    return 1
}
