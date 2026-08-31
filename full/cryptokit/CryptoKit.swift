@_exported import Foundation

// A portable CryptoKit-compatible core. Hashing is implemented directly in
// Swift so the guest dylib has no dependency on an Apple crypto framework or
// an ELF library. Public-key verification currently fails closed until the
// platform's native Ed25519 provider is connected.

public enum CryptoKitError: Error, Equatable, Sendable {
    case incorrectKeySize
    case incorrectParameterSize
    case authenticationFailure
    case underlyingCoreCryptoError(error: Int32)
}

public protocol Digest: ContiguousBytes, CustomStringConvertible, Hashable,
    Sequence, Sendable
where Element == UInt8 {
    static var byteCount: Int { get }
}

public extension Digest {
    func makeIterator() -> Array<UInt8>.Iterator {
        withUnsafeBytes { Array($0) }.makeIterator()
    }
}

public protocol HashFunction: Sendable {
    associatedtype Digest: CryptoKit.Digest
    static var blockByteCount: Int { get }
    init()
    mutating func update(bufferPointer: UnsafeRawBufferPointer)
    func finalize() -> Digest
}

public extension HashFunction {
    mutating func update<D: DataProtocol>(data: D) {
        data.regions.forEach { region in
            region.withUnsafeBytes { update(bufferPointer: $0) }
        }
    }

    static func hash<D: DataProtocol>(data: D) -> Digest {
        var value = Self()
        value.update(data: data)
        return value.finalize()
    }
}

private func _digestDescription(_ bytes: [UInt8]) -> String {
    bytes.map { String(format: "%02x", $0) }.joined()
}

public struct SHA256Digest: Digest {
    public static let byteCount = 32
    private let bytes: [UInt8]
    fileprivate init(_ bytes: [UInt8]) { self.bytes = bytes }
    public func withUnsafeBytes<R>(_ body: (UnsafeRawBufferPointer) throws -> R) rethrows -> R {
        try bytes.withUnsafeBytes(body)
    }
    public var description: String { _digestDescription(bytes) }
}

public struct SHA384Digest: Digest {
    public static let byteCount = 48
    private let bytes: [UInt8]
    fileprivate init(_ bytes: [UInt8]) { self.bytes = bytes }
    public func withUnsafeBytes<R>(_ body: (UnsafeRawBufferPointer) throws -> R) rethrows -> R {
        try bytes.withUnsafeBytes(body)
    }
    public var description: String { _digestDescription(bytes) }
}

public struct SHA512Digest: Digest {
    public static let byteCount = 64
    private let bytes: [UInt8]
    fileprivate init(_ bytes: [UInt8]) { self.bytes = bytes }
    public func withUnsafeBytes<R>(_ body: (UnsafeRawBufferPointer) throws -> R) rethrows -> R {
        try bytes.withUnsafeBytes(body)
    }
    public var description: String { _digestDescription(bytes) }
}

public enum Insecure {
    public struct SHA1Digest: Digest {
        public static let byteCount = 20
        private let bytes: [UInt8]
        fileprivate init(_ bytes: [UInt8]) { self.bytes = bytes }
        public func withUnsafeBytes<R>(_ body: (UnsafeRawBufferPointer) throws -> R) rethrows -> R {
            try bytes.withUnsafeBytes(body)
        }
        public var description: String { _digestDescription(bytes) }
    }

    public struct MD5Digest: Digest {
        public static let byteCount = 16
        private let bytes: [UInt8]
        fileprivate init(_ bytes: [UInt8]) { self.bytes = bytes }
        public func withUnsafeBytes<R>(_ body: (UnsafeRawBufferPointer) throws -> R) rethrows -> R {
            try bytes.withUnsafeBytes(body)
        }
        public var description: String { _digestDescription(bytes) }
    }

    public struct SHA1: HashFunction {
        public typealias Digest = SHA1Digest
        public static let blockByteCount = 64
        private var bytes: [UInt8] = []

        public init() {}
        public mutating func update(bufferPointer: UnsafeRawBufferPointer) {
            bytes.append(contentsOf: bufferPointer)
        }
        public func finalize() -> SHA1Digest { SHA1Digest(_sha1(bytes)) }
    }

    public struct MD5: HashFunction {
        public typealias Digest = MD5Digest
        public static let blockByteCount = 64
        private var bytes: [UInt8] = []

        public init() {}
        public mutating func update(bufferPointer: UnsafeRawBufferPointer) {
            bytes.append(contentsOf: bufferPointer)
        }
        public func finalize() -> MD5Digest { MD5Digest(_md5(bytes)) }
    }
}

public struct SHA256: HashFunction {
    public typealias Digest = SHA256Digest
    public static let blockByteCount = 64
    private var bytes: [UInt8] = []

    public init() {}
    public mutating func update(bufferPointer: UnsafeRawBufferPointer) {
        bytes.append(contentsOf: bufferPointer)
    }
    public func finalize() -> SHA256Digest { SHA256Digest(_sha256(bytes)) }
}

public struct SHA384: HashFunction {
    public typealias Digest = SHA384Digest
    public static let blockByteCount = 128
    private var bytes: [UInt8] = []

    public init() {}
    public mutating func update(bufferPointer: UnsafeRawBufferPointer) {
        bytes.append(contentsOf: bufferPointer)
    }
    public func finalize() -> SHA384Digest {
        SHA384Digest(Array(_sha512(bytes, variant384: true).prefix(48)))
    }
}

public struct SHA512: HashFunction {
    public typealias Digest = SHA512Digest
    public static let blockByteCount = 128
    private var bytes: [UInt8] = []

    public init() {}
    public mutating func update(bufferPointer: UnsafeRawBufferPointer) {
        bytes.append(contentsOf: bufferPointer)
    }
    public func finalize() -> SHA512Digest {
        SHA512Digest(_sha512(bytes, variant384: false))
    }
}

public enum ChaChaPoly {
    public struct Nonce: ContiguousBytes, Sequence, Sendable {
        public typealias Iterator = Array<UInt8>.Iterator
        public typealias Element = UInt8
        public static let byteCount = 12
        private let bytes: [UInt8]

        public init() {
            var generator = SystemRandomNumberGenerator()
            bytes = (0..<Self.byteCount).map { _ in
                UInt8.random(in: .min ... .max, using: &generator)
            }
        }

        public init<D: DataProtocol>(data: D) throws {
            let candidate = Array(data)
            guard candidate.count == Self.byteCount else {
                throw CryptoKitError.incorrectParameterSize
            }
            bytes = candidate
        }

        public var count: Int { bytes.count }
        public func makeIterator() -> Iterator { bytes.makeIterator() }
        public func withUnsafeBytes<R>(
            _ body: (UnsafeRawBufferPointer) throws -> R
        ) rethrows -> R {
            try bytes.withUnsafeBytes(body)
        }
    }
}

public enum Curve25519 {
    public enum Signing {
        public struct PublicKey: Sendable {
            public let rawRepresentation: Data

            public init<D: ContiguousBytes>(rawRepresentation: D) throws {
                let value = rawRepresentation.withUnsafeBytes { Data($0) }
                guard value.count == 32 else {
                    throw CryptoKitError.incorrectKeySize
                }
                self.rawRepresentation = value
            }

            public func isValidSignature<S: DataProtocol, D: DataProtocol>(
                _ signature: S,
                for data: D
            ) -> Bool {
                // Truthful fail-closed behavior: never report an unverified
                // signature as authentic while Ed25519 is unavailable.
                _ = data
                return signature.count == 64 && false
            }
        }
    }
}

private extension UInt32 {
    func _rotatedLeft(_ amount: UInt32) -> UInt32 {
        (self << amount) | (self >> (32 - amount))
    }
    func _rotatedRight(_ amount: UInt32) -> UInt32 {
        (self >> amount) | (self << (32 - amount))
    }
}

private extension UInt64 {
    func _rotatedRight(_ amount: UInt64) -> UInt64 {
        (self >> amount) | (self << (64 - amount))
    }
}

private func _appendUInt32BE(_ value: UInt32, to bytes: inout [UInt8]) {
    bytes.append(UInt8(truncatingIfNeeded: value >> 24))
    bytes.append(UInt8(truncatingIfNeeded: value >> 16))
    bytes.append(UInt8(truncatingIfNeeded: value >> 8))
    bytes.append(UInt8(truncatingIfNeeded: value))
}

private func _appendUInt32LE(_ value: UInt32, to bytes: inout [UInt8]) {
    bytes.append(UInt8(truncatingIfNeeded: value))
    bytes.append(UInt8(truncatingIfNeeded: value >> 8))
    bytes.append(UInt8(truncatingIfNeeded: value >> 16))
    bytes.append(UInt8(truncatingIfNeeded: value >> 24))
}

private func _appendUInt64BE(_ value: UInt64, to bytes: inout [UInt8]) {
    for shift in stride(from: 56, through: 0, by: -8) {
        bytes.append(UInt8(truncatingIfNeeded: value >> UInt64(shift)))
    }
}

private func _word32BE(_ bytes: [UInt8], _ offset: Int) -> UInt32 {
    (UInt32(bytes[offset]) << 24)
        | (UInt32(bytes[offset + 1]) << 16)
        | (UInt32(bytes[offset + 2]) << 8)
        | UInt32(bytes[offset + 3])
}

private func _word32LE(_ bytes: [UInt8], _ offset: Int) -> UInt32 {
    UInt32(bytes[offset])
        | (UInt32(bytes[offset + 1]) << 8)
        | (UInt32(bytes[offset + 2]) << 16)
        | (UInt32(bytes[offset + 3]) << 24)
}

private func _word64BE(_ bytes: [UInt8], _ offset: Int) -> UInt64 {
    var value: UInt64 = 0
    for index in 0..<8 { value = (value << 8) | UInt64(bytes[offset + index]) }
    return value
}

private func _padded64(_ input: [UInt8], littleEndianLength: Bool) -> [UInt8] {
    var message = input
    let bitCount = UInt64(input.count) &* 8
    message.append(0x80)
    while message.count % 64 != 56 { message.append(0) }
    if littleEndianLength {
        for shift in stride(from: 0, through: 56, by: 8) {
            message.append(UInt8(truncatingIfNeeded: bitCount >> UInt64(shift)))
        }
    } else {
        _appendUInt64BE(bitCount, to: &message)
    }
    return message
}

private func _padded128(_ input: [UInt8]) -> [UInt8] {
    var message = input
    let bitCount = UInt64(input.count) &* 8
    message.append(0x80)
    while message.count % 128 != 112 { message.append(0) }
    _appendUInt64BE(0, to: &message)
    _appendUInt64BE(bitCount, to: &message)
    return message
}

private func _md5(_ input: [UInt8]) -> [UInt8] {
    let shifts: [UInt32] = [
        7, 12, 17, 22, 7, 12, 17, 22, 7, 12, 17, 22, 7, 12, 17, 22,
        5, 9, 14, 20, 5, 9, 14, 20, 5, 9, 14, 20, 5, 9, 14, 20,
        4, 11, 16, 23, 4, 11, 16, 23, 4, 11, 16, 23, 4, 11, 16, 23,
        6, 10, 15, 21, 6, 10, 15, 21, 6, 10, 15, 21, 6, 10, 15, 21,
    ]
    let constants: [UInt32] = [
        0xd76aa478, 0xe8c7b756, 0x242070db, 0xc1bdceee,
        0xf57c0faf, 0x4787c62a, 0xa8304613, 0xfd469501,
        0x698098d8, 0x8b44f7af, 0xffff5bb1, 0x895cd7be,
        0x6b901122, 0xfd987193, 0xa679438e, 0x49b40821,
        0xf61e2562, 0xc040b340, 0x265e5a51, 0xe9b6c7aa,
        0xd62f105d, 0x02441453, 0xd8a1e681, 0xe7d3fbc8,
        0x21e1cde6, 0xc33707d6, 0xf4d50d87, 0x455a14ed,
        0xa9e3e905, 0xfcefa3f8, 0x676f02d9, 0x8d2a4c8a,
        0xfffa3942, 0x8771f681, 0x6d9d6122, 0xfde5380c,
        0xa4beea44, 0x4bdecfa9, 0xf6bb4b60, 0xbebfbc70,
        0x289b7ec6, 0xeaa127fa, 0xd4ef3085, 0x04881d05,
        0xd9d4d039, 0xe6db99e5, 0x1fa27cf8, 0xc4ac5665,
        0xf4292244, 0x432aff97, 0xab9423a7, 0xfc93a039,
        0x655b59c3, 0x8f0ccc92, 0xffeff47d, 0x85845dd1,
        0x6fa87e4f, 0xfe2ce6e0, 0xa3014314, 0x4e0811a1,
        0xf7537e82, 0xbd3af235, 0x2ad7d2bb, 0xeb86d391,
    ]
    let message = _padded64(input, littleEndianLength: true)
    var h0: UInt32 = 0x67452301
    var h1: UInt32 = 0xefcdab89
    var h2: UInt32 = 0x98badcfe
    var h3: UInt32 = 0x10325476
    for block in stride(from: 0, to: message.count, by: 64) {
        let words = (0..<16).map { _word32LE(message, block + $0 * 4) }
        var a = h0, b = h1, c = h2, d = h3
        for index in 0..<64 {
            let f: UInt32
            let wordIndex: Int
            switch index {
            case 0..<16:
                f = (b & c) | ((~b) & d); wordIndex = index
            case 16..<32:
                f = (d & b) | ((~d) & c); wordIndex = (5 * index + 1) % 16
            case 32..<48:
                f = b ^ c ^ d; wordIndex = (3 * index + 5) % 16
            default:
                f = c ^ (b | ~d); wordIndex = (7 * index) % 16
            }
            let next = b &+ (a &+ f &+ constants[index] &+ words[wordIndex])
                ._rotatedLeft(shifts[index])
            a = d; d = c; c = b; b = next
        }
        h0 &+= a; h1 &+= b; h2 &+= c; h3 &+= d
    }
    var result: [UInt8] = []
    for value in [h0, h1, h2, h3] { _appendUInt32LE(value, to: &result) }
    return result
}

private func _sha1(_ input: [UInt8]) -> [UInt8] {
    let message = _padded64(input, littleEndianLength: false)
    var state: [UInt32] = [
        0x67452301, 0xefcdab89, 0x98badcfe, 0x10325476, 0xc3d2e1f0,
    ]
    for block in stride(from: 0, to: message.count, by: 64) {
        var words = [UInt32](repeating: 0, count: 80)
        for index in 0..<16 { words[index] = _word32BE(message, block + index * 4) }
        for index in 16..<80 {
            words[index] = (words[index - 3] ^ words[index - 8]
                ^ words[index - 14] ^ words[index - 16])._rotatedLeft(1)
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
            let temporary = a._rotatedLeft(5) &+ f &+ e &+ constant &+ words[index]
            e = d; d = c; c = b._rotatedLeft(30); b = a; a = temporary
        }
        state[0] &+= a; state[1] &+= b; state[2] &+= c
        state[3] &+= d; state[4] &+= e
    }
    var result: [UInt8] = []
    for value in state { _appendUInt32BE(value, to: &result) }
    return result
}

private let _sha256Constants: [UInt32] = [
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

private func _sha256(_ input: [UInt8]) -> [UInt8] {
    let message = _padded64(input, littleEndianLength: false)
    var state: [UInt32] = [
        0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a,
        0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19,
    ]
    for block in stride(from: 0, to: message.count, by: 64) {
        var words = [UInt32](repeating: 0, count: 64)
        for index in 0..<16 { words[index] = _word32BE(message, block + index * 4) }
        for index in 16..<64 {
            let x = words[index - 15]
            let y = words[index - 2]
            let s0 = x._rotatedRight(7) ^ x._rotatedRight(18) ^ (x >> 3)
            let s1 = y._rotatedRight(17) ^ y._rotatedRight(19) ^ (y >> 10)
            words[index] = words[index - 16] &+ s0 &+ words[index - 7] &+ s1
        }
        var a = state[0], b = state[1], c = state[2], d = state[3]
        var e = state[4], f = state[5], g = state[6], h = state[7]
        for index in 0..<64 {
            let s1 = e._rotatedRight(6) ^ e._rotatedRight(11) ^ e._rotatedRight(25)
            let choose = (e & f) ^ ((~e) & g)
            let temporary1 = h &+ s1 &+ choose &+ _sha256Constants[index] &+ words[index]
            let s0 = a._rotatedRight(2) ^ a._rotatedRight(13) ^ a._rotatedRight(22)
            let majority = (a & b) ^ (a & c) ^ (b & c)
            let temporary2 = s0 &+ majority
            h = g; g = f; f = e; e = d &+ temporary1
            d = c; c = b; b = a; a = temporary1 &+ temporary2
        }
        state[0] &+= a; state[1] &+= b; state[2] &+= c; state[3] &+= d
        state[4] &+= e; state[5] &+= f; state[6] &+= g; state[7] &+= h
    }
    var result: [UInt8] = []
    for value in state { _appendUInt32BE(value, to: &result) }
    return result
}

private let _sha512Constants: [UInt64] = [
    0x428a2f98d728ae22, 0x7137449123ef65cd, 0xb5c0fbcfec4d3b2f,
    0xe9b5dba58189dbbc, 0x3956c25bf348b538, 0x59f111f1b605d019,
    0x923f82a4af194f9b, 0xab1c5ed5da6d8118, 0xd807aa98a3030242,
    0x12835b0145706fbe, 0x243185be4ee4b28c, 0x550c7dc3d5ffb4e2,
    0x72be5d74f27b896f, 0x80deb1fe3b1696b1, 0x9bdc06a725c71235,
    0xc19bf174cf692694, 0xe49b69c19ef14ad2, 0xefbe4786384f25e3,
    0x0fc19dc68b8cd5b5, 0x240ca1cc77ac9c65, 0x2de92c6f592b0275,
    0x4a7484aa6ea6e483, 0x5cb0a9dcbd41fbd4, 0x76f988da831153b5,
    0x983e5152ee66dfab, 0xa831c66d2db43210, 0xb00327c898fb213f,
    0xbf597fc7beef0ee4, 0xc6e00bf33da88fc2, 0xd5a79147930aa725,
    0x06ca6351e003826f, 0x142929670a0e6e70, 0x27b70a8546d22ffc,
    0x2e1b21385c26c926, 0x4d2c6dfc5ac42aed, 0x53380d139d95b3df,
    0x650a73548baf63de, 0x766a0abb3c77b2a8, 0x81c2c92e47edaee6,
    0x92722c851482353b, 0xa2bfe8a14cf10364, 0xa81a664bbc423001,
    0xc24b8b70d0f89791, 0xc76c51a30654be30, 0xd192e819d6ef5218,
    0xd69906245565a910, 0xf40e35855771202a, 0x106aa07032bbd1b8,
    0x19a4c116b8d2d0c8, 0x1e376c085141ab53, 0x2748774cdf8eeb99,
    0x34b0bcb5e19b48a8, 0x391c0cb3c5c95a63, 0x4ed8aa4ae3418acb,
    0x5b9cca4f7763e373, 0x682e6ff3d6b2b8a3, 0x748f82ee5defb2fc,
    0x78a5636f43172f60, 0x84c87814a1f0ab72, 0x8cc702081a6439ec,
    0x90befffa23631e28, 0xa4506cebde82bde9, 0xbef9a3f7b2c67915,
    0xc67178f2e372532b, 0xca273eceea26619c, 0xd186b8c721c0c207,
    0xeada7dd6cde0eb1e, 0xf57d4f7fee6ed178, 0x06f067aa72176fba,
    0x0a637dc5a2c898a6, 0x113f9804bef90dae, 0x1b710b35131c471b,
    0x28db77f523047d84, 0x32caab7b40c72493, 0x3c9ebe0a15c9bebc,
    0x431d67c49c100d4c, 0x4cc5d4becb3e42b6, 0x597f299cfc657e2a,
    0x5fcb6fab3ad6faec, 0x6c44198c4a475817,
]

private func _sha512(_ input: [UInt8], variant384: Bool) -> [UInt8] {
    let message = _padded128(input)
    var state: [UInt64] = variant384 ? [
        0xcbbb9d5dc1059ed8, 0x629a292a367cd507, 0x9159015a3070dd17,
        0x152fecd8f70e5939, 0x67332667ffc00b31, 0x8eb44a8768581511,
        0xdb0c2e0d64f98fa7, 0x47b5481dbefa4fa4,
    ] : [
        0x6a09e667f3bcc908, 0xbb67ae8584caa73b, 0x3c6ef372fe94f82b,
        0xa54ff53a5f1d36f1, 0x510e527fade682d1, 0x9b05688c2b3e6c1f,
        0x1f83d9abfb41bd6b, 0x5be0cd19137e2179,
    ]
    for block in stride(from: 0, to: message.count, by: 128) {
        var words = [UInt64](repeating: 0, count: 80)
        for index in 0..<16 { words[index] = _word64BE(message, block + index * 8) }
        for index in 16..<80 {
            let x = words[index - 15]
            let y = words[index - 2]
            let s0 = x._rotatedRight(1) ^ x._rotatedRight(8) ^ (x >> 7)
            let s1 = y._rotatedRight(19) ^ y._rotatedRight(61) ^ (y >> 6)
            words[index] = words[index - 16] &+ s0 &+ words[index - 7] &+ s1
        }
        var a = state[0], b = state[1], c = state[2], d = state[3]
        var e = state[4], f = state[5], g = state[6], h = state[7]
        for index in 0..<80 {
            let s1 = e._rotatedRight(14) ^ e._rotatedRight(18) ^ e._rotatedRight(41)
            let choose = (e & f) ^ ((~e) & g)
            let temporary1 = h &+ s1 &+ choose &+ _sha512Constants[index] &+ words[index]
            let s0 = a._rotatedRight(28) ^ a._rotatedRight(34) ^ a._rotatedRight(39)
            let majority = (a & b) ^ (a & c) ^ (b & c)
            let temporary2 = s0 &+ majority
            h = g; g = f; f = e; e = d &+ temporary1
            d = c; c = b; b = a; a = temporary1 &+ temporary2
        }
        state[0] &+= a; state[1] &+= b; state[2] &+= c; state[3] &+= d
        state[4] &+= e; state[5] &+= f; state[6] &+= g; state[7] &+= h
    }
    var result: [UInt8] = []
    for value in state { _appendUInt64BE(value, to: &result) }
    return result
}
