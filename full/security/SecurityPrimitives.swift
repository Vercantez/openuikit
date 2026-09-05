import Foundation

func _secRandomBytes(_ count: Int) -> [UInt8] {
    guard count > 0 else { return [] }
    if let handle = FileHandle(forReadingAtPath: "/dev/urandom") {
        let data = handle.readData(ofLength: count)
        try? handle.close()
        if data.count == count { return Array(data) }
    }
    var generator = SystemRandomNumberGenerator()
    return (0..<count).map { _ in UInt8.random(in: .min ... .max, using: &generator) }
}

func _secEqualBytes(_ left: [UInt8], _ right: [UInt8]) -> Bool {
    guard left.count == right.count else { return false }
    var acc: UInt8 = 0
    for index in 0..<left.count { acc |= left[index] ^ right[index] }
    return acc == 0
}

func _secBool(_ value: Any?) -> Bool {
    if let flag = value as? Bool { return flag }
    if let number = value as? Int { return number != 0 }
    if let number = value as? NSNumber { return number.boolValue }
    if let text = value as? String { return text == "1" || text == "true" }
    return false
}

func _secInt(_ value: Any?) -> Int? {
    if let number = value as? Int { return number }
    if let number = value as? Int32 { return Int(number) }
    if let number = value as? Int64 { return Int(number) }
    if let number = value as? NSNumber { return number.intValue }
    if let text = value as? String { return Int(text) }
    return nil
}

func _secString(_ value: Any?) -> String? {
    if let text = value as? String { return text }
    return nil
}

func _secData(_ value: Any?) -> Data? {
    if let data = value as? Data { return data }
    if let bytes = value as? [UInt8] { return Data(bytes) }
    return nil
}

// MARK: - Hash

private extension UInt32 {
    func _rotl(_ amount: UInt32) -> UInt32 { (self << amount) | (self >> (32 - amount)) }
    func _rotr(_ amount: UInt32) -> UInt32 { (self >> amount) | (self << (32 - amount)) }
}

private extension UInt64 {
    func _rotr(_ amount: UInt64) -> UInt64 { (self >> amount) | (self << (64 - amount)) }
}

private func _append32BE(_ value: UInt32, to bytes: inout [UInt8]) {
    bytes.append(UInt8(truncatingIfNeeded: value >> 24))
    bytes.append(UInt8(truncatingIfNeeded: value >> 16))
    bytes.append(UInt8(truncatingIfNeeded: value >> 8))
    bytes.append(UInt8(truncatingIfNeeded: value))
}

private func _append32LE(_ value: UInt32, to bytes: inout [UInt8]) {
    bytes.append(UInt8(truncatingIfNeeded: value))
    bytes.append(UInt8(truncatingIfNeeded: value >> 8))
    bytes.append(UInt8(truncatingIfNeeded: value >> 16))
    bytes.append(UInt8(truncatingIfNeeded: value >> 24))
}

private func _append64BE(_ value: UInt64, to bytes: inout [UInt8]) {
    for shift in stride(from: 56, through: 0, by: -8) {
        bytes.append(UInt8(truncatingIfNeeded: value >> UInt64(shift)))
    }
}

private func _w32BE(_ bytes: [UInt8], _ offset: Int) -> UInt32 {
    (UInt32(bytes[offset]) << 24)
        | (UInt32(bytes[offset + 1]) << 16)
        | (UInt32(bytes[offset + 2]) << 8)
        | UInt32(bytes[offset + 3])
}

private func _w32LE(_ bytes: [UInt8], _ offset: Int) -> UInt32 {
    UInt32(bytes[offset])
        | (UInt32(bytes[offset + 1]) << 8)
        | (UInt32(bytes[offset + 2]) << 16)
        | (UInt32(bytes[offset + 3]) << 24)
}

private func _w64BE(_ bytes: [UInt8], _ offset: Int) -> UInt64 {
    var value: UInt64 = 0
    for index in 0..<8 { value = (value << 8) | UInt64(bytes[offset + index]) }
    return value
}

private func _pad64(_ input: [UInt8], littleEndianLength: Bool) -> [UInt8] {
    var message = input
    let bitCount = UInt64(input.count) &* 8
    message.append(0x80)
    while message.count % 64 != 56 { message.append(0) }
    if littleEndianLength {
        for shift in stride(from: 0, through: 56, by: 8) {
            message.append(UInt8(truncatingIfNeeded: bitCount >> UInt64(shift)))
        }
    } else {
        _append64BE(bitCount, to: &message)
    }
    return message
}

private func _pad128(_ input: [UInt8]) -> [UInt8] {
    var message = input
    let bitCount = UInt64(input.count) &* 8
    message.append(0x80)
    while message.count % 128 != 112 { message.append(0) }
    _append64BE(0, to: &message)
    _append64BE(bitCount, to: &message)
    return message
}

func _secMD5(_ input: [UInt8]) -> [UInt8] {
    let shifts: [UInt32] = [
        7, 12, 17, 22, 7, 12, 17, 22, 7, 12, 17, 22, 7, 12, 17, 22,
        5, 9, 14, 20, 5, 9, 14, 20, 5, 9, 14, 20, 5, 9, 14, 20,
        4, 11, 16, 23, 4, 11, 16, 23, 4, 11, 16, 23, 4, 11, 16, 23,
        6, 10, 15, 21, 6, 10, 15, 21, 6, 10, 15, 21, 6, 10, 15, 21,
    ]
    let constants: [UInt32] = [
        0xd76aa478, 0xe8c7b756, 0x242070db, 0xc1bdceee, 0xf57c0faf, 0x4787c62a, 0xa8304613, 0xfd469501,
        0x698098d8, 0x8b44f7af, 0xffff5bb1, 0x895cd7be, 0x6b901122, 0xfd987193, 0xa679438e, 0x49b40821,
        0xf61e2562, 0xc040b340, 0x265e5a51, 0xe9b6c7aa, 0xd62f105d, 0x02441453, 0xd8a1e681, 0xe7d3fbc8,
        0x21e1cde6, 0xc33707d6, 0xf4d50d87, 0x455a14ed, 0xa9e3e905, 0xfcefa3f8, 0x676f02d9, 0x8d2a4c8a,
        0xfffa3942, 0x8771f681, 0x6d9d6122, 0xfde5380c, 0xa4beea44, 0x4bdecfa9, 0xf6bb4b60, 0xbebfbc70,
        0x289b7ec6, 0xeaa127fa, 0xd4ef3085, 0x04881d05, 0xd9d4d039, 0xe6db99e5, 0x1fa27cf8, 0xc4ac5665,
        0xf4292244, 0x432aff97, 0xab9423a7, 0xfc93a039, 0x655b59c3, 0x8f0ccc92, 0xffeff47d, 0x85845dd1,
        0x6fa87e4f, 0xfe2ce6e0, 0xa3014314, 0x4e0811a1, 0xf7537e82, 0xbd3af235, 0x2ad7d2bb, 0xeb86d391,
    ]
    let message = _pad64(input, littleEndianLength: true)
    var h0: UInt32 = 0x67452301, h1: UInt32 = 0xefcdab89, h2: UInt32 = 0x98badcfe, h3: UInt32 = 0x10325476
    for block in stride(from: 0, to: message.count, by: 64) {
        let words = (0..<16).map { _w32LE(message, block + $0 * 4) }
        var a = h0, b = h1, c = h2, d = h3
        for index in 0..<64 {
            let f: UInt32
            let wordIndex: Int
            switch index {
            case 0..<16: f = (b & c) | ((~b) & d); wordIndex = index
            case 16..<32: f = (d & b) | ((~d) & c); wordIndex = (5 * index + 1) % 16
            case 32..<48: f = b ^ c ^ d; wordIndex = (3 * index + 5) % 16
            default: f = c ^ (b | ~d); wordIndex = (7 * index) % 16
            }
            let next = b &+ (a &+ f &+ constants[index] &+ words[wordIndex])._rotl(shifts[index])
            a = d; d = c; c = b; b = next
        }
        h0 &+= a; h1 &+= b; h2 &+= c; h3 &+= d
    }
    var result: [UInt8] = []
    for value in [h0, h1, h2, h3] { _append32LE(value, to: &result) }
    return result
}

func _secSHA1(_ input: [UInt8]) -> [UInt8] {
    let message = _pad64(input, littleEndianLength: false)
    var state: [UInt32] = [0x67452301, 0xefcdab89, 0x98badcfe, 0x10325476, 0xc3d2e1f0]
    for block in stride(from: 0, to: message.count, by: 64) {
        var words = [UInt32](repeating: 0, count: 80)
        for index in 0..<16 { words[index] = _w32BE(message, block + index * 4) }
        for index in 16..<80 {
            words[index] = (words[index - 3] ^ words[index - 8] ^ words[index - 14] ^ words[index - 16])._rotl(1)
        }
        var a = state[0], b = state[1], c = state[2], d = state[3], e = state[4]
        for index in 0..<80 {
            let f: UInt32
            let constant: UInt32
            switch index {
            case 0..<20: f = (b & c) | ((~b) & d); constant = 0x5a827999
            case 20..<40: f = b ^ c ^ d; constant = 0x6ed9eba1
            case 40..<60: f = (b & c) | (b & d) | (c & d); constant = 0x8f1bbcdc
            default: f = b ^ c ^ d; constant = 0xca62c1d6
            }
            let temporary = a._rotl(5) &+ f &+ e &+ constant &+ words[index]
            e = d; d = c; c = b._rotl(30); b = a; a = temporary
        }
        state[0] &+= a; state[1] &+= b; state[2] &+= c; state[3] &+= d; state[4] &+= e
    }
    var result: [UInt8] = []
    for value in state { _append32BE(value, to: &result) }
    return result
}

private let _sha256K: [UInt32] = [
    0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
    0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3, 0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
    0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc, 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
    0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7, 0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
    0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13, 0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
    0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
    0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
    0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208, 0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2,
]

private func _sha256State(_ input: [UInt8], iv: [UInt32]) -> [UInt32] {
    let message = _pad64(input, littleEndianLength: false)
    var state = iv
    for block in stride(from: 0, to: message.count, by: 64) {
        var words = [UInt32](repeating: 0, count: 64)
        for index in 0..<16 { words[index] = _w32BE(message, block + index * 4) }
        for index in 16..<64 {
            let x = words[index - 15], y = words[index - 2]
            let s0 = x._rotr(7) ^ x._rotr(18) ^ (x >> 3)
            let s1 = y._rotr(17) ^ y._rotr(19) ^ (y >> 10)
            words[index] = words[index - 16] &+ s0 &+ words[index - 7] &+ s1
        }
        var a = state[0], b = state[1], c = state[2], d = state[3]
        var e = state[4], f = state[5], g = state[6], h = state[7]
        for index in 0..<64 {
            let s1 = e._rotr(6) ^ e._rotr(11) ^ e._rotr(25)
            let choose = (e & f) ^ ((~e) & g)
            let t1 = h &+ s1 &+ choose &+ _sha256K[index] &+ words[index]
            let s0 = a._rotr(2) ^ a._rotr(13) ^ a._rotr(22)
            let majority = (a & b) ^ (a & c) ^ (b & c)
            h = g; g = f; f = e; e = d &+ t1
            d = c; c = b; b = a; a = t1 &+ s0 &+ majority
        }
        state[0] &+= a; state[1] &+= b; state[2] &+= c; state[3] &+= d
        state[4] &+= e; state[5] &+= f; state[6] &+= g; state[7] &+= h
    }
    return state
}

func _secSHA256(_ input: [UInt8]) -> [UInt8] {
    let state = _sha256State(input, iv: [
        0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a,
        0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19,
    ])
    var result: [UInt8] = []
    for value in state { _append32BE(value, to: &result) }
    return result
}

func _secSHA224(_ input: [UInt8]) -> [UInt8] {
    let state = _sha256State(input, iv: [
        0xc1059ed8, 0x367cd507, 0x3070dd17, 0xf70e5939,
        0xffc00b31, 0x68581511, 0x64f98fa7, 0xbefa4fa4,
    ])
    var result: [UInt8] = []
    for value in state { _append32BE(value, to: &result) }
    return Array(result.prefix(28))
}

private let _sha512K: [UInt64] = [
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

private func _sha512State(_ input: [UInt8], iv: [UInt64]) -> [UInt64] {
    let message = _pad128(input)
    var state = iv
    for block in stride(from: 0, to: message.count, by: 128) {
        var words = [UInt64](repeating: 0, count: 80)
        for index in 0..<16 { words[index] = _w64BE(message, block + index * 8) }
        for index in 16..<80 {
            let x = words[index - 15], y = words[index - 2]
            let s0 = x._rotr(1) ^ x._rotr(8) ^ (x >> 7)
            let s1 = y._rotr(19) ^ y._rotr(61) ^ (y >> 6)
            words[index] = words[index - 16] &+ s0 &+ words[index - 7] &+ s1
        }
        var a = state[0], b = state[1], c = state[2], d = state[3]
        var e = state[4], f = state[5], g = state[6], h = state[7]
        for index in 0..<80 {
            let s1 = e._rotr(14) ^ e._rotr(18) ^ e._rotr(41)
            let choose = (e & f) ^ ((~e) & g)
            let t1 = h &+ s1 &+ choose &+ _sha512K[index] &+ words[index]
            let s0 = a._rotr(28) ^ a._rotr(34) ^ a._rotr(39)
            let majority = (a & b) ^ (a & c) ^ (b & c)
            h = g; g = f; f = e; e = d &+ t1
            d = c; c = b; b = a; a = t1 &+ s0 &+ majority
        }
        state[0] &+= a; state[1] &+= b; state[2] &+= c; state[3] &+= d
        state[4] &+= e; state[5] &+= f; state[6] &+= g; state[7] &+= h
    }
    return state
}

func _secSHA512(_ input: [UInt8]) -> [UInt8] {
    let state = _sha512State(input, iv: [
        0x6a09e667f3bcc908, 0xbb67ae8584caa73b, 0x3c6ef372fe94f82b, 0xa54ff53a5f1d36f1,
        0x510e527fade682d1, 0x9b05688c2b3e6c1f, 0x1f83d9abfb41bd6b, 0x5be0cd19137e2179,
    ])
    var result: [UInt8] = []
    for value in state { _append64BE(value, to: &result) }
    return result
}

func _secSHA384(_ input: [UInt8]) -> [UInt8] {
    let state = _sha512State(input, iv: [
        0xcbbb9d5dc1059ed8, 0x629a292a367cd507, 0x9159015a3070dd17, 0x152fecd8f70e5939,
        0x67332667ffc00b31, 0x8eb44a8768581511, 0xdb0c2e0d64f98fa7, 0x47b5481dbefa4fa4,
    ])
    var result: [UInt8] = []
    for value in state { _append64BE(value, to: &result) }
    return Array(result.prefix(48))
}

enum _SecDigest {
    case md5, sha1, sha224, sha256, sha384, sha512

    var digestInfoPrefix: [UInt8] {
        switch self {
        case .md5:
            return [0x30, 0x20, 0x30, 0x0c, 0x06, 0x08, 0x2a, 0x86, 0x48, 0x86, 0xf7, 0x0d, 0x02, 0x05, 0x05, 0x00, 0x04, 0x10]
        case .sha1:
            return [0x30, 0x21, 0x30, 0x09, 0x06, 0x05, 0x2b, 0x0e, 0x03, 0x02, 0x1a, 0x05, 0x00, 0x04, 0x14]
        case .sha224:
            return [0x30, 0x2d, 0x30, 0x0d, 0x06, 0x09, 0x60, 0x86, 0x48, 0x01, 0x65, 0x03, 0x04, 0x02, 0x04, 0x05, 0x00, 0x04, 0x1c]
        case .sha256:
            return [0x30, 0x31, 0x30, 0x0d, 0x06, 0x09, 0x60, 0x86, 0x48, 0x01, 0x65, 0x03, 0x04, 0x02, 0x01, 0x05, 0x00, 0x04, 0x20]
        case .sha384:
            return [0x30, 0x41, 0x30, 0x0d, 0x06, 0x09, 0x60, 0x86, 0x48, 0x01, 0x65, 0x03, 0x04, 0x02, 0x02, 0x05, 0x00, 0x04, 0x30]
        case .sha512:
            return [0x30, 0x51, 0x30, 0x0d, 0x06, 0x09, 0x60, 0x86, 0x48, 0x01, 0x65, 0x03, 0x04, 0x02, 0x03, 0x05, 0x00, 0x04, 0x40]
        }
    }

    var outputByteCount: Int {
        switch self {
        case .md5: return 16
        case .sha1: return 20
        case .sha224: return 28
        case .sha256: return 32
        case .sha384: return 48
        case .sha512: return 64
        }
    }

    func hash(_ input: [UInt8]) -> [UInt8] {
        switch self {
        case .md5: return _secMD5(input)
        case .sha1: return _secSHA1(input)
        case .sha224: return _secSHA224(input)
        case .sha256: return _secSHA256(input)
        case .sha384: return _secSHA384(input)
        case .sha512: return _secSHA512(input)
        }
    }
}

func _secHMAC(digest: _SecDigest, key: [UInt8], message: [UInt8]) -> [UInt8] {
    let block = digest == .sha384 || digest == .sha512 ? 128 : 64
    var k = key
    if k.count > block { k = digest.hash(k) }
    if k.count < block { k.append(contentsOf: [UInt8](repeating: 0, count: block - k.count)) }
    let ipad = k.map { $0 ^ 0x36 }
    let opad = k.map { $0 ^ 0x5c }
    return digest.hash(opad + digest.hash(ipad + message))
}

func _secMGF1(digest: _SecDigest, seed: [UInt8], length: Int) -> [UInt8] {
    var output: [UInt8] = []
    var counter: UInt32 = 0
    while output.count < length {
        var block = seed
        _append32BE(counter, to: &block)
        output.append(contentsOf: digest.hash(block))
        counter += 1
    }
    return Array(output.prefix(length))
}

func _secPBKDF2(password: [UInt8], salt: [UInt8], iterations: Int, length: Int, digest: _SecDigest) -> [UInt8] {
    var output: [UInt8] = []
    var blockIndex: UInt32 = 1
    while output.count < length {
        var block = salt
        _append32BE(blockIndex, to: &block)
        var u = _secHMAC(digest: digest, key: password, message: block)
        var t = u
        if iterations > 1 {
            for _ in 1..<iterations {
                u = _secHMAC(digest: digest, key: password, message: u)
                for index in 0..<t.count { t[index] ^= u[index] }
            }
        }
        output.append(contentsOf: t)
        blockIndex += 1
    }
    return Array(output.prefix(length))
}

// MARK: - AES-GCM (FIPS 197 / NIST SP 800-38D)

private let _aesSBox: [UInt8] = [
    0x63, 0x7c, 0x77, 0x7b, 0xf2, 0x6b, 0x6f, 0xc5, 0x30, 0x01, 0x67, 0x2b, 0xfe, 0xd7, 0xab, 0x76,
    0xca, 0x82, 0xc9, 0x7d, 0xfa, 0x59, 0x47, 0xf0, 0xad, 0xd4, 0xa2, 0xaf, 0x9c, 0xa4, 0x72, 0xc0,
    0xb7, 0xfd, 0x93, 0x26, 0x36, 0x3f, 0xf7, 0xcc, 0x34, 0xa5, 0xe5, 0xf1, 0x71, 0xd8, 0x31, 0x15,
    0x04, 0xc7, 0x23, 0xc3, 0x18, 0x96, 0x05, 0x9a, 0x07, 0x12, 0x80, 0xe2, 0xeb, 0x27, 0xb2, 0x75,
    0x09, 0x83, 0x2c, 0x1a, 0x1b, 0x6e, 0x5a, 0xa0, 0x52, 0x3b, 0xd6, 0xb3, 0x29, 0xe3, 0x2f, 0x84,
    0x53, 0xd1, 0x00, 0xed, 0x20, 0xfc, 0xb1, 0x5b, 0x6a, 0xcb, 0xbe, 0x39, 0x4a, 0x4c, 0x58, 0xcf,
    0xd0, 0xef, 0xaa, 0xfb, 0x43, 0x4d, 0x33, 0x85, 0x45, 0xf9, 0x02, 0x7f, 0x50, 0x3c, 0x9f, 0xa8,
    0x51, 0xa3, 0x40, 0x8f, 0x92, 0x9d, 0x38, 0xf5, 0xbc, 0xb6, 0xda, 0x21, 0x10, 0xff, 0xf3, 0xd2,
    0xcd, 0x0c, 0x13, 0xec, 0x5f, 0x97, 0x44, 0x17, 0xc4, 0xa7, 0x7e, 0x3d, 0x64, 0x5d, 0x19, 0x73,
    0x60, 0x81, 0x4f, 0xdc, 0x22, 0x2a, 0x90, 0x88, 0x46, 0xee, 0xb8, 0x14, 0xde, 0x5e, 0x0b, 0xdb,
    0xe0, 0x32, 0x3a, 0x0a, 0x49, 0x06, 0x24, 0x5c, 0xc2, 0xd3, 0xac, 0x62, 0x91, 0x95, 0xe4, 0x79,
    0xe7, 0xc8, 0x37, 0x6d, 0x8d, 0xd5, 0x4e, 0xa9, 0x6c, 0x56, 0xf4, 0xea, 0x65, 0x7a, 0xae, 0x08,
    0xba, 0x78, 0x25, 0x2e, 0x1c, 0xa6, 0xb4, 0xc6, 0xe8, 0xdd, 0x74, 0x1f, 0x4b, 0xbd, 0x8b, 0x8a,
    0x70, 0x3e, 0xb5, 0x66, 0x48, 0x03, 0xf6, 0x0e, 0x61, 0x35, 0x57, 0xb9, 0x86, 0xc1, 0x1d, 0x9e,
    0xe1, 0xf8, 0x98, 0x11, 0x69, 0xd9, 0x8e, 0x94, 0x9b, 0x1e, 0x87, 0xe9, 0xce, 0x55, 0x28, 0xdf,
    0x8c, 0xa1, 0x89, 0x0d, 0xbf, 0xe6, 0x42, 0x68, 0x41, 0x99, 0x2d, 0x0f, 0xb0, 0x54, 0xbb, 0x16,
]

private func _aesXt(_ value: UInt8) -> UInt8 {
    let shifted = (value << 1) & 0xff
    return (value & 0x80) == 0 ? shifted : (shifted ^ 0x1b)
}

private func _aesExpandKey(_ key: [UInt8]) -> [[UInt8]] {
    let rounds = key.count == 16 ? 10 : (key.count == 24 ? 12 : 14)
    let n = key.count / 4
    var words = [[UInt8]](repeating: [0, 0, 0, 0], count: 4 * (rounds + 1))
    for index in 0..<n { words[index] = Array(key[(index * 4)..<(index * 4 + 4)]) }
    let rcon: [UInt8] = [0x00, 0x01, 0x02, 0x04, 0x08, 0x10, 0x20, 0x40, 0x80, 0x1b, 0x36]
    for index in n..<(4 * (rounds + 1)) {
        var temp = words[index - 1]
        if index % n == 0 {
            temp = [temp[1], temp[2], temp[3], temp[0]].map { _aesSBox[Int($0)] }
            temp[0] ^= rcon[index / n]
        } else if n > 6 && index % n == 4 {
            temp = temp.map { _aesSBox[Int($0)] }
        }
        words[index] = zip(words[index - n], temp).map { $0 ^ $1 }
    }
    return (0...rounds).map { round in
        var block: [UInt8] = []
        for column in 0..<4 { block.append(contentsOf: words[round * 4 + column]) }
        return block
    }
}

private func _aesEncryptBlock(_ input: [UInt8], roundKeys: [[UInt8]]) -> [UInt8] {
    var state = input
    func add(_ round: Int) { for i in 0..<16 { state[i] ^= roundKeys[round][i] } }
    add(0)
    for round in 1..<(roundKeys.count - 1) {
        for i in 0..<16 { state[i] = _aesSBox[Int(state[i])] }
        state = [
            state[0], state[5], state[10], state[15],
            state[4], state[9], state[14], state[3],
            state[8], state[13], state[2], state[7],
            state[12], state[1], state[6], state[11],
        ]
        var mixed = [UInt8](repeating: 0, count: 16)
        for column in 0..<4 {
            let i = column * 4
            let a = state[i], b = state[i + 1], c = state[i + 2], d = state[i + 3]
            mixed[i] = _aesXt(a) ^ _aesXt(b) ^ b ^ c ^ d
            mixed[i + 1] = a ^ _aesXt(b) ^ _aesXt(c) ^ c ^ d
            mixed[i + 2] = a ^ b ^ _aesXt(c) ^ _aesXt(d) ^ d
            mixed[i + 3] = _aesXt(a) ^ a ^ b ^ c ^ _aesXt(d)
        }
        state = mixed
        add(round)
    }
    for i in 0..<16 { state[i] = _aesSBox[Int(state[i])] }
    state = [
        state[0], state[5], state[10], state[15],
        state[4], state[9], state[14], state[3],
        state[8], state[13], state[2], state[7],
        state[12], state[1], state[6], state[11],
    ]
    add(roundKeys.count - 1)
    return state
}

private func _gf128Mul(_ x: [UInt8], _ y: [UInt8]) -> [UInt8] {
    var v = y
    var z = [UInt8](repeating: 0, count: 16)
    for byte in x {
        for bit in (0..<8).reversed() {
            if ((byte >> bit) & 1) == 1 {
                for i in 0..<16 { z[i] ^= v[i] }
            }
            let lsb = v[15] & 1
            var carry: UInt8 = 0
            for i in 0..<16 {
                let next = v[i] & 1
                v[i] = (v[i] >> 1) | (carry << 7)
                carry = next
            }
            if lsb == 1 { v[0] ^= 0xe1 }
        }
    }
    return z
}

private func _ghash(_ h: [UInt8], _ data: [UInt8]) -> [UInt8] {
    var y = [UInt8](repeating: 0, count: 16)
    var offset = 0
    while offset < data.count {
        var block = [UInt8](repeating: 0, count: 16)
        let take = min(16, data.count - offset)
        for i in 0..<take { block[i] = data[offset + i] }
        for i in 0..<16 { y[i] ^= block[i] }
        y = _gf128Mul(y, h)
        offset += 16
    }
    return y
}

private func _inc32(_ counter: inout [UInt8]) {
    var carry: UInt16 = 1
    for index in [15, 14, 13, 12] {
        let sum = UInt16(counter[index]) + carry
        counter[index] = UInt8(truncatingIfNeeded: sum)
        carry = sum >> 8
    }
}

private func _aesCTR(roundKeys: [[UInt8]], counter: [UInt8], data: [UInt8]) -> [UInt8] {
    var blockCounter = counter
    var output: [UInt8] = []
    output.reserveCapacity(data.count)
    var offset = 0
    while offset < data.count {
        let keystream = _aesEncryptBlock(blockCounter, roundKeys: roundKeys)
        _inc32(&blockCounter)
        let take = min(16, data.count - offset)
        for i in 0..<take { output.append(data[offset + i] ^ keystream[i]) }
        offset += take
    }
    return output
}

func _secAESGCMSeal(key: [UInt8], nonce: [UInt8], plaintext: [UInt8], aad: [UInt8] = []) -> ([UInt8], [UInt8]) {
    let roundKeys = _aesExpandKey(key)
    let h = _aesEncryptBlock([UInt8](repeating: 0, count: 16), roundKeys: roundKeys)
    var j0 = nonce
    j0.append(contentsOf: [0, 0, 0, 1])
    var counter = j0
    _inc32(&counter)
    let ciphertext = _aesCTR(roundKeys: roundKeys, counter: counter, data: plaintext)
    func len64(_ count: Int) -> [UInt8] {
        var value = UInt64(count) * 8
        var bytes = [UInt8](repeating: 0, count: 8)
        for i in (0..<8).reversed() { bytes[i] = UInt8(truncatingIfNeeded: value); value >>= 8 }
        return bytes
    }
    var ghashInput = aad
    ghashInput.append(contentsOf: [UInt8](repeating: 0, count: (16 - (aad.count % 16)) % 16))
    ghashInput.append(contentsOf: ciphertext)
    ghashInput.append(contentsOf: [UInt8](repeating: 0, count: (16 - (ciphertext.count % 16)) % 16))
    ghashInput.append(contentsOf: len64(aad.count) + len64(ciphertext.count))
    let s = _ghash(h, ghashInput)
    let tag = zip(s, _aesEncryptBlock(j0, roundKeys: roundKeys)).map { $0 ^ $1 }
    return (ciphertext, tag)
}

func _secAESGCMOpen(key: [UInt8], nonce: [UInt8], ciphertext: [UInt8], tag: [UInt8], aad: [UInt8] = []) -> [UInt8]? {
    let roundKeys = _aesExpandKey(key)
    let h = _aesEncryptBlock([UInt8](repeating: 0, count: 16), roundKeys: roundKeys)
    var j0 = nonce
    j0.append(contentsOf: [0, 0, 0, 1])
    func len64(_ count: Int) -> [UInt8] {
        var value = UInt64(count) * 8
        var bytes = [UInt8](repeating: 0, count: 8)
        for i in (0..<8).reversed() { bytes[i] = UInt8(truncatingIfNeeded: value); value >>= 8 }
        return bytes
    }
    var ghashInput = aad
    ghashInput.append(contentsOf: [UInt8](repeating: 0, count: (16 - (aad.count % 16)) % 16))
    ghashInput.append(contentsOf: ciphertext)
    ghashInput.append(contentsOf: [UInt8](repeating: 0, count: (16 - (ciphertext.count % 16)) % 16))
    ghashInput.append(contentsOf: len64(aad.count) + len64(ciphertext.count))
    let s = _ghash(h, ghashInput)
    let computed = zip(s, _aesEncryptBlock(j0, roundKeys: roundKeys)).map { $0 ^ $1 }
    guard _secEqualBytes(computed, tag) else { return nil }
    var counter = j0
    _inc32(&counter)
    return _aesCTR(roundKeys: roundKeys, counter: counter, data: ciphertext)
}

// MARK: - Big integer (unsigned, little-endian UInt64 limbs)

private func _secShiftLeftLimbs(_ words: [UInt64], bits: Int, count: Int) -> [UInt64] {
    var result = [UInt64](repeating: 0, count: count)
    if bits == 0 {
        for i in 0..<min(words.count, count) { result[i] = words[i] }
        return result
    }
    var carry: UInt64 = 0
    for i in 0..<count {
        let w = i < words.count ? words[i] : 0
        result[i] = (w << bits) | carry
        carry = w >> (64 - bits)
    }
    return result
}

private func _secShiftRightLimbs(_ words: [UInt64], bits: Int) -> [UInt64] {
    if bits == 0 { return words }
    var result = [UInt64](repeating: 0, count: words.count)
    let inv = 64 - bits
    for i in 0..<words.count {
        let high = i + 1 < words.count ? words[i + 1] << inv : 0
        result[i] = (words[i] >> bits) | high
    }
    return result
}

/// Knuth Algorithm D (The Art of Computer Programming 4.3.1). Returns (quotient, remainder).
func _secDivLimbs(_ dividend: [UInt64], _ divisor: [UInt64]) -> ([UInt64], [UInt64]) {
    var v = divisor
    while v.count > 1 && v.last == 0 { v.removeLast() }
    var u = dividend
    while u.count > 1 && u.last == 0 { u.removeLast() }
    precondition(!v.isEmpty && !(v.count == 1 && v[0] == 0))
    if u.count < v.count { return ([0], u) }
    if v.count == 1 {
        let d = v[0]
        var remainder: UInt64 = 0
        var q = [UInt64](repeating: 0, count: u.count)
        for index in stride(from: u.count - 1, through: 0, by: -1) {
            let (quot, rel) = d.dividingFullWidth((remainder, u[index]))
            q[index] = quot
            remainder = rel
        }
        return (q, [remainder])
    }
    let n = v.count
    let shift = v[n - 1].leadingZeroBitCount
    v = _secShiftLeftLimbs(v, bits: shift, count: n)
    u.append(0)
    u = _secShiftLeftLimbs(u, bits: shift, count: u.count)
    let m = u.count - n - 1
    var q = [UInt64](repeating: 0, count: m + 1)
    let vn1 = v[n - 1]
    let vn2 = n > 1 ? v[n - 2] : 0
    for j in stride(from: m, through: 0, by: -1) {
        let ujn = u[j + n]
        let ujn1 = u[j + n - 1]
        var qhat: UInt64
        var rhat: UInt64
        var rhatOverflow = false
        if ujn >= vn1 {
            qhat = UInt64.max
            let (sum, overflow) = ujn1.addingReportingOverflow(vn1)
            rhat = sum
            rhatOverflow = overflow || ujn > vn1
        } else {
            (qhat, rhat) = vn1.dividingFullWidth((ujn, ujn1))
        }
        if n > 1 && !rhatOverflow {
            while true {
                let (ph, pl) = qhat.multipliedFullWidth(by: vn2)
                let ujnm2 = u[j + n - 2]
                if ph < rhat || (ph == rhat && pl <= ujnm2) { break }
                qhat &-= 1
                let (nr, overflow) = rhat.addingReportingOverflow(vn1)
                rhat = nr
                if overflow { break }
            }
        }
        var pHi: UInt64 = 0
        var borrow: UInt64 = 0
        for i in 0..<n {
            let (hi, lo) = qhat.multipliedFullWidth(by: v[i])
            let (lo2, o1) = lo.addingReportingOverflow(pHi)
            pHi = hi &+ (o1 ? 1 : 0)
            var (diff, b1) = u[j + i].subtractingReportingOverflow(lo2)
            var b: UInt64 = b1 ? 1 : 0
            if borrow != 0 {
                let (d2, b2) = diff.subtractingReportingOverflow(borrow)
                diff = d2
                b += b2 ? 1 : 0
            }
            u[j + i] = diff
            borrow = b
        }
        var (diff, b1) = u[j + n].subtractingReportingOverflow(pHi)
        var extra: UInt64 = b1 ? 1 : 0
        if borrow != 0 {
            let (d2, b2) = diff.subtractingReportingOverflow(borrow)
            diff = d2
            extra += b2 ? 1 : 0
        }
        u[j + n] = diff
        if extra != 0 {
            qhat &-= 1
            var carry: UInt64 = 0
            for i in 0..<n {
                let (s1, o1) = u[j + i].addingReportingOverflow(v[i])
                let (s2, o2) = s1.addingReportingOverflow(carry)
                u[j + i] = s2
                carry = (o1 ? 1 : 0) + (o2 ? 1 : 0)
            }
            u[j + n] = u[j + n] &+ carry
        }
        q[j] = qhat
    }
    var rem = Array(u.prefix(n))
    rem = _secShiftRightLimbs(rem, bits: shift)
    return (q, rem)
}

struct _SecInt: Comparable, Equatable {
    var words: [UInt64]

    static let zero = _SecInt(words: [0])
    static let one = _SecInt(words: [1])

    init(words: [UInt64]) {
        var trimmed = words
        while trimmed.count > 1 && trimmed.last == 0 { trimmed.removeLast() }
        self.words = trimmed.isEmpty ? [0] : trimmed
    }

    init(_ value: UInt64) { self.words = [value] }

    init(bytes bigEndian: [UInt8]) {
        var bytes = bigEndian
        while bytes.first == 0 && bytes.count > 1 { bytes.removeFirst() }
        if bytes.isEmpty { self.init(words: [0]); return }
        var words: [UInt64] = []
        var index = bytes.count
        while index > 0 {
            var word: UInt64 = 0
            let take = min(8, index)
            for offset in 0..<take {
                word |= UInt64(bytes[index - 1 - offset]) << (UInt64(offset) * 8)
            }
            words.append(word)
            index -= take
        }
        self.init(words: words)
    }

    var isZero: Bool { words.count == 1 && words[0] == 0 }
    var bitLength: Int {
        if isZero { return 0 }
        let last = words[words.count - 1]
        return (words.count - 1) * 64 + (64 - last.leadingZeroBitCount)
    }

    func bigEndianBytes(_ length: Int? = nil) -> [UInt8] {
        var bytes: [UInt8] = []
        for word in words.reversed() {
            for shift in stride(from: 56, through: 0, by: -8) {
                bytes.append(UInt8(truncatingIfNeeded: word >> UInt64(shift)))
            }
        }
        while bytes.count > 1 && bytes[0] == 0 { bytes.removeFirst() }
        if let length {
            if bytes.count > length { return Array(bytes.suffix(length)) }
            return [UInt8](repeating: 0, count: length - bytes.count) + bytes
        }
        return bytes
    }

    static func < (lhs: _SecInt, rhs: _SecInt) -> Bool {
        if lhs.words.count != rhs.words.count { return lhs.words.count < rhs.words.count }
        for index in stride(from: lhs.words.count - 1, through: 0, by: -1) {
            if lhs.words[index] != rhs.words[index] { return lhs.words[index] < rhs.words[index] }
        }
        return false
    }

    func adding(_ other: _SecInt) -> _SecInt {
        let count = max(words.count, other.words.count)
        var result = [UInt64](repeating: 0, count: count + 1)
        var carry: UInt64 = 0
        for index in 0..<count {
            let a = index < words.count ? words[index] : 0
            let b = index < other.words.count ? other.words[index] : 0
            let (s1, o1) = a.addingReportingOverflow(b)
            let (s2, o2) = s1.addingReportingOverflow(carry)
            result[index] = s2
            carry = (o1 ? 1 : 0) + (o2 ? 1 : 0)
        }
        result[count] = carry
        return _SecInt(words: result)
    }

    func subtracting(_ other: _SecInt) -> _SecInt {
        precondition(self >= other)
        var result = [UInt64](repeating: 0, count: words.count)
        var borrow: UInt64 = 0
        for index in 0..<words.count {
            let b = index < other.words.count ? other.words[index] : 0
            let (d1, u1) = words[index].subtractingReportingOverflow(b)
            let (d2, u2) = d1.subtractingReportingOverflow(borrow)
            result[index] = d2
            borrow = (u1 ? 1 : 0) + (u2 ? 1 : 0)
        }
        return _SecInt(words: result)
    }

    func shiftedLeft(_ bits: Int) -> _SecInt {
        if isZero || bits == 0 { return self }
        let wordShift = bits / 64
        let bitShift = bits % 64
        var result = [UInt64](repeating: 0, count: words.count + wordShift + 1)
        if bitShift == 0 {
            for index in 0..<words.count { result[index + wordShift] = words[index] }
        } else {
            var carry: UInt64 = 0
            for index in 0..<words.count {
                result[index + wordShift] = (words[index] << bitShift) | carry
                carry = words[index] >> (64 - bitShift)
            }
            result[words.count + wordShift] = carry
        }
        return _SecInt(words: result)
    }

    func shiftedRight(_ bits: Int) -> _SecInt {
        if bits <= 0 { return self }
        let wordShift = bits / 64
        let bitShift = bits % 64
        if wordShift >= words.count { return .zero }
        if bitShift == 0 {
            return _SecInt(words: Array(words.dropFirst(wordShift)))
        }
        var result: [UInt64] = []
        for index in wordShift..<words.count {
            let high = index + 1 < words.count ? words[index + 1] << (64 - bitShift) : 0
            result.append((words[index] >> bitShift) | high)
        }
        return _SecInt(words: result)
    }

    func multiplied(_ other: _SecInt) -> _SecInt {
        if isZero || other.isZero { return .zero }
        var result = [UInt64](repeating: 0, count: words.count + other.words.count)
        for i in 0..<words.count {
            var carry: UInt64 = 0
            for j in 0..<other.words.count {
                let (hi, lo) = words[i].multipliedFullWidth(by: other.words[j])
                var c1: UInt64 = 0
                let (s1, o1) = result[i + j].addingReportingOverflow(lo)
                c1 += o1 ? 1 : 0
                let (s2, o2) = s1.addingReportingOverflow(carry)
                c1 += o2 ? 1 : 0
                result[i + j] = s2
                let (s3, o3) = hi.addingReportingOverflow(c1)
                carry = s3
                if o3 { /* hi + small carry cannot overflow UInt64 from 2x64 mul */ }
                _ = o3
            }
            var k = i + other.words.count
            while carry != 0 {
                let (s, o) = result[k].addingReportingOverflow(carry)
                result[k] = s
                carry = o ? 1 : 0
                k += 1
            }
        }
        return _SecInt(words: result)
    }

    func quotientAndRemainder(dividingBy divisor: _SecInt) -> (_SecInt, _SecInt) {
        precondition(!divisor.isZero)
        if self < divisor { return (.zero, self) }
        if divisor.words.count == 1 {
            let d = divisor.words[0]
            var remainder: UInt64 = 0
            var q = [UInt64](repeating: 0, count: words.count)
            for index in stride(from: words.count - 1, through: 0, by: -1) {
                let value = (UInt64(remainder), words[index])
                let (quot, rel) = d.dividingFullWidth(value)
                q[index] = quot
                remainder = rel
            }
            return (_SecInt(words: q), _SecInt(remainder))
        }
        // Knuth Algorithm D. Bit-serial remainder (measured on Linux Swift 6.2)
        // spent the 120s host-gate budget on a single RSA-2048 CRT op.
        let (q, r) = _secDivLimbs(words, divisor.words)
        return (_SecInt(words: q), _SecInt(words: r))
    }

    func modulo(_ modulus: _SecInt) -> _SecInt {
        quotientAndRemainder(dividingBy: modulus).1
    }

    func addingMod(_ other: _SecInt, _ modulus: _SecInt) -> _SecInt {
        adding(other).modulo(modulus)
    }

    func subtractingMod(_ other: _SecInt, _ modulus: _SecInt) -> _SecInt {
        let left = modulo(modulus)
        let right = other.modulo(modulus)
        if left >= right { return left.subtracting(right) }
        return modulus.subtracting(right.subtracting(left))
    }

    func modPow(_ exponent: _SecInt, _ modulus: _SecInt) -> _SecInt {
        var result = _SecInt.one
        var base = self.modulo(modulus)
        var exp = exponent
        while !exp.isZero {
            if (exp.words[0] & 1) == 1 {
                result = result.multiplied(base).modulo(modulus)
            }
            base = base.multiplied(base).modulo(modulus)
            exp = exp.shiftedRight(1)
        }
        return result
    }

    func gcd(_ other: _SecInt) -> _SecInt {
        var a = self, b = other
        while !b.isZero { (a, b) = (b, a.modulo(b)) }
        return a
    }

    func modInverse(_ modulus: _SecInt) -> _SecInt? {
        var t = _SecInt.zero, newT = _SecInt.one
        var r = modulus, newR = self.modulo(modulus)
        var tNeg = false, newTNeg = false
        while !newR.isZero {
            let q = r.quotientAndRemainder(dividingBy: newR).0
            let prod = q.multiplied(newT)
            // t, newT as signed via flags
            let nextTNeg: Bool
            let nextT: _SecInt
            if tNeg == newTNeg {
                if t >= prod { nextT = t.subtracting(prod); nextTNeg = tNeg }
                else { nextT = prod.subtracting(t); nextTNeg = !tNeg }
            } else {
                nextT = t.adding(prod)
                nextTNeg = tNeg
            }
            (t, newT, tNeg, newTNeg) = (newT, nextT, newTNeg, nextTNeg)
            let nextR = r.subtracting(q.multiplied(newR))
            (r, newR) = (newR, nextR)
        }
        if r != .one { return nil }
        if tNeg { return modulus.subtracting(t.modulo(modulus)) }
        return t.modulo(modulus)
    }

    static func random(bitLength: Int) -> _SecInt {
        let byteCount = (bitLength + 7) / 8
        var bytes = _secRandomBytes(byteCount)
        if let last = bytes.first {
            let extra = byteCount * 8 - bitLength
            bytes[0] = last & (0xff >> extra)
            bytes[0] |= 1 << (7 - extra)
        }
        bytes[bytes.count - 1] |= 1
        return _SecInt(bytes: bytes)
    }
}

private let _smallPrimes: [UInt64] = [
    3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47, 53, 59, 61, 67, 71, 73, 79, 83, 89, 97,
    101, 103, 107, 109, 113, 127, 131, 137, 139, 149, 151, 157, 163, 167, 173, 179, 181, 191, 193,
    197, 199, 211, 223, 227, 229, 233, 239, 241, 251, 257, 263, 269, 271, 277, 281, 283, 293, 307,
    311, 313, 317, 331, 337, 347, 349, 353, 359, 367, 373, 379, 383, 389, 397, 401, 409, 419, 421,
]

func _secIsProbablePrime(_ n: _SecInt, rounds: Int = 8) -> Bool {
    if n < _SecInt(2) { return false }
    if n == _SecInt(2) { return true }
    if (n.words[0] & 1) == 0 { return false }
    for p in _smallPrimes {
        let prime = _SecInt(p)
        if n == prime { return true }
        if n.modulo(prime).isZero { return false }
    }
    let nMinusOne = n.subtracting(.one)
    var s = 0
    var d = nMinusOne
    while (d.words[0] & 1) == 0 {
        d = d.shiftedRight(1)
        s += 1
    }
    for _ in 0..<rounds {
        var a = _SecInt.random(bitLength: max(2, n.bitLength - 1))
        if a < _SecInt(2) { a = _SecInt(2) }
        if a >= nMinusOne { a = _SecInt(2) }
        var x = a.modPow(d, n)
        if x == .one || x == nMinusOne { continue }
        var passed = false
        if s > 1 {
            for _ in 1..<s {
                x = x.multiplied(x).modulo(n)
                if x == nMinusOne { passed = true; break }
                if x == .one { return false }
            }
        }
        if !passed { return false }
    }
    return true
}

func _secRandomPrime(bitLength: Int) -> _SecInt {
    while true {
        var candidate = _SecInt.random(bitLength: bitLength)
        candidate.words[0] |= 1
        if _secIsProbablePrime(candidate) { return candidate }
    }
}
