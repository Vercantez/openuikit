@_exported import Foundation

// Portable CryptoKit: hashing, HMAC, HKDF, AES-GCM, ChaChaPoly, AES-KW,
// X25519 (RFC 7748), Ed25519 (RFC 8032), P-256/P-384/P-521 (FIPS 186-4),
// and HPKE base mode (RFC 9180). Secure Enclave and post-quantum KEMs stay
// fail-closed. Every field constant is named from a published vector.

public enum CryptoKitError: Error, Hashable, Sendable {
    case incorrectKeySize
    case incorrectParameterSize
    case authenticationFailure
    case underlyingCoreCryptoError(error: Int32)
    case wrapFailure
    case unwrapFailure
    case invalidParameter
}

public enum CryptoKitASN1Error: Error, Hashable, Sendable {
    case invalidFieldIdentifier
    case unexpectedFieldType
    case invalidObjectIdentifier
    case invalidASN1Object
    case invalidASN1IntegerEncoding
    case invalidPEMDocument
    case truncatedASN1Field
    case unsupportedFieldLength
}

public typealias CryptoKitMetaError = any Error

public protocol Digest: ContiguousBytes, CustomStringConvertible, Hashable,
    Sequence, Sendable
where Element == UInt8 {
    static var byteCount: Int { get }
}

public extension Digest {
    func makeIterator() -> Array<UInt8>.Iterator {
        withUnsafeBytes { Array($0) }.makeIterator()
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.withUnsafeBytes { left in
            rhs.withUnsafeBytes { right in
                _ckEqual(left, right)
            }
        }
    }

    static func == <D: DataProtocol>(lhs: Self, rhs: D) -> Bool {
        let right = Array(rhs)
        return lhs.withUnsafeBytes { left in
            right.withUnsafeBytes { raw in _ckEqual(left, raw) }
        }
    }
}

public protocol MessageAuthenticationCode: ContiguousBytes, CustomStringConvertible,
    Hashable, Sequence, Sendable
where Element == UInt8 {
    var byteCount: Int { get }
}

public extension MessageAuthenticationCode {
    func makeIterator() -> Array<UInt8>.Iterator {
        withUnsafeBytes { Array($0) }.makeIterator()
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.withUnsafeBytes { left in
            rhs.withUnsafeBytes { right in
                _ckEqual(left, right)
            }
        }
    }

    static func == <D: DataProtocol>(lhs: Self, rhs: D) -> Bool {
        let right = Array(rhs)
        return lhs.withUnsafeBytes { left in
            right.withUnsafeBytes { raw in _ckEqual(left, raw) }
        }
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

func _digestDescription(_ bytes: [UInt8]) -> String {
    bytes.map { String(format: "%02x", $0) }.joined()
}

func _ckEqual(_ left: UnsafeRawBufferPointer, _ right: UnsafeRawBufferPointer) -> Bool {
    guard left.count == right.count else { return false }
    var diff: UInt8 = 0
    for index in 0..<left.count {
        diff |= left[index] ^ right[index]
    }
    return diff == 0
}

func _ckEqualBytes(_ left: [UInt8], _ right: [UInt8]) -> Bool {
    left.withUnsafeBytes { a in
        right.withUnsafeBytes { b in _ckEqual(a, b) }
    }
}

func _ckRandomBytes(_ count: Int) -> [UInt8] {
    var generator = SystemRandomNumberGenerator()
    return (0..<count).map { _ in UInt8.random(in: .min ... .max, using: &generator) }
}

func _ckData<D: ContiguousBytes>(_ value: D) -> Data {
    value.withUnsafeBytes { Data($0) }
}

func _ckBytes<D: DataProtocol>(_ value: D) -> [UInt8] {
    Array(value)
}

func _ckUnavailableCrypto() -> CryptoKitError {
    .underlyingCoreCryptoError(error: -1)
}

public struct SymmetricKeySize: Sendable {
    public let bitCount: Int
    public init(bitCount: Int) { self.bitCount = bitCount }
    public static var bits128: SymmetricKeySize { SymmetricKeySize(bitCount: 128) }
    public static var bits192: SymmetricKeySize { SymmetricKeySize(bitCount: 192) }
    public static var bits256: SymmetricKeySize { SymmetricKeySize(bitCount: 256) }
}

public struct SymmetricKey: ContiguousBytes, Equatable, Sendable {
    private let bytes: [UInt8]

    public init<D: ContiguousBytes>(data: D) {
        bytes = Array(_ckData(data))
    }

    public init(size: SymmetricKeySize) {
        bytes = _ckRandomBytes((size.bitCount + 7) / 8)
    }

    init(rawBytes: [UInt8]) {
        bytes = rawBytes
    }

    public var bitCount: Int { bytes.count * 8 }

    public func withUnsafeBytes<R>(
        _ body: (UnsafeRawBufferPointer) throws -> R
    ) rethrows -> R {
        try bytes.withUnsafeBytes(body)
    }

    public static func == (lhs: SymmetricKey, rhs: SymmetricKey) -> Bool {
        _ckEqualBytes(lhs.bytes, rhs.bytes)
    }
}

public struct HashedAuthenticationCode<H: HashFunction>: MessageAuthenticationCode {
    public typealias Element = UInt8
    public typealias Iterator = Array<UInt8>.Iterator
    fileprivate let bytes: [UInt8]

    init(_ bytes: [UInt8]) { self.bytes = bytes }

    public var byteCount: Int { bytes.count }
    public var description: String { _digestDescription(bytes) }
    public var hashValue: Int { bytes.hashValue }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(bytes)
    }

    public func withUnsafeBytes<R>(
        _ body: (UnsafeRawBufferPointer) throws -> R
    ) rethrows -> R {
        try bytes.withUnsafeBytes(body)
    }
}

public struct HMAC<H: HashFunction>: Sendable {
    public typealias Key = SymmetricKey
    public typealias MAC = HashedAuthenticationCode<H>

    private let keyBytes: [UInt8]
    private var message: [UInt8]

    public init(key: SymmetricKey) {
        keyBytes = Array(_ckData(key))
        message = []
    }

    public mutating func update<D: DataProtocol>(data: D) {
        message.append(contentsOf: data)
    }

    public func finalize() -> HMAC<H>.MAC {
        HashedAuthenticationCode(_hmac(H.self, key: keyBytes, message: message))
    }

    public static func authenticationCode<D: DataProtocol>(
        for data: D,
        using key: SymmetricKey
    ) -> HMAC<H>.MAC {
        var hmac = HMAC(key: key)
        hmac.update(data: data)
        return hmac.finalize()
    }

    public static func isValidAuthenticationCode(
        _ mac: HMAC<H>.MAC,
        authenticating bufferPointer: UnsafeRawBufferPointer,
        using key: SymmetricKey
    ) -> Bool {
        let expected = authenticationCode(for: Data(bufferPointer), using: key)
        return expected == mac
    }

    public static func isValidAuthenticationCode<D: DataProtocol>(
        _ authenticationCode: HMAC<H>.MAC,
        authenticating authenticatedData: D,
        using key: SymmetricKey
    ) -> Bool {
        Self.authenticationCode(for: authenticatedData, using: key) == authenticationCode
    }

    public static func isValidAuthenticationCode<C: ContiguousBytes, D: DataProtocol>(
        _ authenticationCode: C,
        authenticating authenticatedData: D,
        using key: SymmetricKey
    ) -> Bool {
        let expected = Self.authenticationCode(for: authenticatedData, using: key)
        return expected.withUnsafeBytes { left in
            authenticationCode.withUnsafeBytes { right in _ckEqual(left, right) }
        }
    }
}

public struct HKDF<H: HashFunction>: Sendable {
    public static func extract<Salt: DataProtocol>(
        inputKeyMaterial: SymmetricKey,
        salt: Salt?
    ) -> HashedAuthenticationCode<H> {
        let saltBytes: [UInt8]
        if let salt {
            saltBytes = _ckBytes(salt)
        } else {
            saltBytes = [UInt8](repeating: 0, count: H.Digest.byteCount)
        }
        return HMAC<H>.authenticationCode(
            for: Data(_ckData(inputKeyMaterial)),
            using: SymmetricKey(rawBytes: saltBytes)
        )
    }

    public static func expand<PRK: ContiguousBytes, Info: DataProtocol>(
        pseudoRandomKey prk: PRK,
        info: Info?,
        outputByteCount: Int
    ) -> SymmetricKey {
        let infoBytes = info.map(_ckBytes) ?? []
        let hashLen = H.Digest.byteCount
        let n = max(1, (outputByteCount + hashLen - 1) / hashLen)
        var output: [UInt8] = []
        var previous: [UInt8] = []
        let key = SymmetricKey(data: prk)
        for index in 1...n {
            var block = previous
            block.append(contentsOf: infoBytes)
            block.append(UInt8(index))
            let mac = HMAC<H>.authenticationCode(for: Data(block), using: key)
            previous = mac.withUnsafeBytes { Array($0) }
            output.append(contentsOf: previous)
        }
        return SymmetricKey(rawBytes: Array(output.prefix(outputByteCount)))
    }

    public static func deriveKey(
        inputKeyMaterial: SymmetricKey,
        outputByteCount: Int
    ) -> SymmetricKey {
        deriveKey(
            inputKeyMaterial: inputKeyMaterial,
            salt: Data(),
            info: Data(),
            outputByteCount: outputByteCount
        )
    }

    public static func deriveKey<Info: DataProtocol>(
        inputKeyMaterial: SymmetricKey,
        info: Info,
        outputByteCount: Int
    ) -> SymmetricKey {
        deriveKey(
            inputKeyMaterial: inputKeyMaterial,
            salt: Data(),
            info: info,
            outputByteCount: outputByteCount
        )
    }

    public static func deriveKey<Salt: DataProtocol>(
        inputKeyMaterial: SymmetricKey,
        salt: Salt,
        outputByteCount: Int
    ) -> SymmetricKey {
        deriveKey(
            inputKeyMaterial: inputKeyMaterial,
            salt: salt,
            info: Data(),
            outputByteCount: outputByteCount
        )
    }

    public static func deriveKey<Salt: DataProtocol, Info: DataProtocol>(
        inputKeyMaterial: SymmetricKey,
        salt: Salt,
        info: Info,
        outputByteCount: Int
    ) -> SymmetricKey {
        let prk = extract(inputKeyMaterial: inputKeyMaterial, salt: Optional(salt))
        return expand(pseudoRandomKey: prk, info: Optional(info), outputByteCount: outputByteCount)
    }
}

public struct SharedSecret: ContiguousBytes, Hashable, Sendable {
    let bytes: [UInt8]

    init(bytes: [UInt8]) { self.bytes = bytes }

    public var description: String { _digestDescription(bytes) }
    public var hashValue: Int { bytes.hashValue }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(bytes)
    }

    public func withUnsafeBytes<R>(
        _ body: (UnsafeRawBufferPointer) throws -> R
    ) rethrows -> R {
        try bytes.withUnsafeBytes(body)
    }

    public static func == (lhs: SharedSecret, rhs: SharedSecret) -> Bool {
        _ckEqualBytes(lhs.bytes, rhs.bytes)
    }

    public static func == <D: DataProtocol>(lhs: SharedSecret, rhs: D) -> Bool {
        _ckEqualBytes(lhs.bytes, _ckBytes(rhs))
    }

    public func hkdfDerivedSymmetricKey<H: HashFunction, Salt: DataProtocol, SI: DataProtocol>(
        using hashFunction: H.Type,
        salt: Salt,
        sharedInfo: SI,
        outputByteCount: Int
    ) -> SymmetricKey {
        _ = hashFunction
        return HKDF<H>.deriveKey(
            inputKeyMaterial: SymmetricKey(rawBytes: bytes),
            salt: salt,
            info: sharedInfo,
            outputByteCount: outputByteCount
        )
    }

    public func x963DerivedSymmetricKey<H: HashFunction, SI: DataProtocol>(
        using hashFunction: H.Type,
        sharedInfo: SI,
        outputByteCount: Int
    ) -> SymmetricKey {
        _ = hashFunction
        let info = _ckBytes(sharedInfo)
        let hashLen = H.Digest.byteCount
        let n = max(1, (outputByteCount + hashLen - 1) / hashLen)
        var output: [UInt8] = []
        for counter in 1...n {
            var block = bytes
            block.append(UInt8((counter >> 24) & 0xff))
            block.append(UInt8((counter >> 16) & 0xff))
            block.append(UInt8((counter >> 8) & 0xff))
            block.append(UInt8(counter & 0xff))
            block.append(contentsOf: info)
            output.append(contentsOf: H.hash(data: Data(block)))
        }
        return SymmetricKey(rawBytes: Array(output.prefix(outputByteCount)))
    }
}

func _hmac<H: HashFunction>(_ type: H.Type, key: [UInt8], message: [UInt8]) -> [UInt8] {
    _ = type
    var keyBytes = key
    if keyBytes.count > H.blockByteCount {
        keyBytes = Array(H.hash(data: Data(keyBytes)))
    }
    if keyBytes.count < H.blockByteCount {
        keyBytes += [UInt8](repeating: 0, count: H.blockByteCount - keyBytes.count)
    }
    let innerPad = keyBytes.map { $0 ^ 0x36 }
    let outerPad = keyBytes.map { $0 ^ 0x5c }
    let inner = H.hash(data: Data(innerPad + message))
    return Array(H.hash(data: Data(outerPad) + Data(inner)))
}

public struct SHA256Digest: Digest {
    public typealias Element = UInt8
    public typealias Iterator = Array<UInt8>.Iterator
    public static let byteCount = 32
    private let bytes: [UInt8]
    fileprivate init(_ bytes: [UInt8]) { self.bytes = bytes }
    public var description: String { _digestDescription(bytes) }
    public var hashValue: Int { bytes.hashValue }
    public func hash(into hasher: inout Hasher) { hasher.combine(bytes) }
    public func withUnsafeBytes<R>(_ body: (UnsafeRawBufferPointer) throws -> R) rethrows -> R {
        try bytes.withUnsafeBytes(body)
    }
}

public struct SHA384Digest: Digest {
    public typealias Element = UInt8
    public typealias Iterator = Array<UInt8>.Iterator
    public static let byteCount = 48
    private let bytes: [UInt8]
    fileprivate init(_ bytes: [UInt8]) { self.bytes = bytes }
    public var description: String { _digestDescription(bytes) }
    public var hashValue: Int { bytes.hashValue }
    public func hash(into hasher: inout Hasher) { hasher.combine(bytes) }
    public func withUnsafeBytes<R>(_ body: (UnsafeRawBufferPointer) throws -> R) rethrows -> R {
        try bytes.withUnsafeBytes(body)
    }
}

public struct SHA512Digest: Digest {
    public typealias Element = UInt8
    public typealias Iterator = Array<UInt8>.Iterator
    public static let byteCount = 64
    private let bytes: [UInt8]
    fileprivate init(_ bytes: [UInt8]) { self.bytes = bytes }
    public var description: String { _digestDescription(bytes) }
    public var hashValue: Int { bytes.hashValue }
    public func hash(into hasher: inout Hasher) { hasher.combine(bytes) }
    public func withUnsafeBytes<R>(_ body: (UnsafeRawBufferPointer) throws -> R) rethrows -> R {
        try bytes.withUnsafeBytes(body)
    }
}

public struct SHA3_256Digest: Digest {
    public typealias Element = UInt8
    public typealias Iterator = Array<UInt8>.Iterator
    public static let byteCount = 32
    private let bytes: [UInt8]
    fileprivate init(_ bytes: [UInt8]) { self.bytes = bytes }
    public var description: String { _digestDescription(bytes) }
    public var hashValue: Int { bytes.hashValue }
    public func hash(into hasher: inout Hasher) { hasher.combine(bytes) }
    public func withUnsafeBytes<R>(_ body: (UnsafeRawBufferPointer) throws -> R) rethrows -> R {
        try bytes.withUnsafeBytes(body)
    }
}

public struct SHA3_384Digest: Digest {
    public typealias Element = UInt8
    public typealias Iterator = Array<UInt8>.Iterator
    public static let byteCount = 48
    private let bytes: [UInt8]
    fileprivate init(_ bytes: [UInt8]) { self.bytes = bytes }
    public var description: String { _digestDescription(bytes) }
    public var hashValue: Int { bytes.hashValue }
    public func hash(into hasher: inout Hasher) { hasher.combine(bytes) }
    public func withUnsafeBytes<R>(_ body: (UnsafeRawBufferPointer) throws -> R) rethrows -> R {
        try bytes.withUnsafeBytes(body)
    }
}

public struct SHA3_512Digest: Digest {
    public typealias Element = UInt8
    public typealias Iterator = Array<UInt8>.Iterator
    public static let byteCount = 64
    private let bytes: [UInt8]
    fileprivate init(_ bytes: [UInt8]) { self.bytes = bytes }
    public var description: String { _digestDescription(bytes) }
    public var hashValue: Int { bytes.hashValue }
    public func hash(into hasher: inout Hasher) { hasher.combine(bytes) }
    public func withUnsafeBytes<R>(_ body: (UnsafeRawBufferPointer) throws -> R) rethrows -> R {
        try bytes.withUnsafeBytes(body)
    }
}

public enum Insecure {
    public struct SHA1Digest: Digest {
        public typealias Element = UInt8
        public typealias Iterator = Array<UInt8>.Iterator
        public static let byteCount = 20
        private let bytes: [UInt8]
        fileprivate init(_ bytes: [UInt8]) { self.bytes = bytes }
        public var description: String { _digestDescription(bytes) }
        public var hashValue: Int { bytes.hashValue }
        public func hash(into hasher: inout Hasher) { hasher.combine(bytes) }
        public func withUnsafeBytes<R>(_ body: (UnsafeRawBufferPointer) throws -> R) rethrows -> R {
            try bytes.withUnsafeBytes(body)
        }
    }

    public struct MD5Digest: Digest {
        public typealias Element = UInt8
        public typealias Iterator = Array<UInt8>.Iterator
        public static let byteCount = 16
        private let bytes: [UInt8]
        fileprivate init(_ bytes: [UInt8]) { self.bytes = bytes }
        public var description: String { _digestDescription(bytes) }
        public var hashValue: Int { bytes.hashValue }
        public func hash(into hasher: inout Hasher) { hasher.combine(bytes) }
        public func withUnsafeBytes<R>(_ body: (UnsafeRawBufferPointer) throws -> R) rethrows -> R {
            try bytes.withUnsafeBytes(body)
        }
    }

    public struct SHA1: HashFunction {
        public typealias Digest = SHA1Digest
        public static let blockByteCount = 64
        public static let byteCount = 20
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
        public static let byteCount = 16
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
    public static let byteCount = 32
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
    public static let byteCount = 48
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
    public static let byteCount = 64
    private var bytes: [UInt8] = []

    public init() {}
    public mutating func update(bufferPointer: UnsafeRawBufferPointer) {
        bytes.append(contentsOf: bufferPointer)
    }
    public func finalize() -> SHA512Digest {
        SHA512Digest(_sha512(bytes, variant384: false))
    }
}

public typealias SHA2_256 = SHA256
public typealias SHA2_384 = SHA384
public typealias SHA2_512 = SHA512

public struct SHA3_256: HashFunction {
    public typealias Digest = SHA3_256Digest
    public static let blockByteCount = 136
    public static let byteCount = 32
    private var bytes: [UInt8] = []

    public init() {}
    public mutating func update(bufferPointer: UnsafeRawBufferPointer) {
        bytes.append(contentsOf: bufferPointer)
    }
    public func finalize() -> SHA3_256Digest {
        SHA3_256Digest(_sha3(bytes, rate: 136, outputByteCount: 32))
    }
}

public struct SHA3_384: HashFunction {
    public typealias Digest = SHA3_384Digest
    public static let blockByteCount = 104
    public static let byteCount = 48
    private var bytes: [UInt8] = []

    public init() {}
    public mutating func update(bufferPointer: UnsafeRawBufferPointer) {
        bytes.append(contentsOf: bufferPointer)
    }
    public func finalize() -> SHA3_384Digest {
        SHA3_384Digest(_sha3(bytes, rate: 104, outputByteCount: 48))
    }
}

public struct SHA3_512: HashFunction {
    public typealias Digest = SHA3_512Digest
    public static let blockByteCount = 72
    public static let byteCount = 64
    private var bytes: [UInt8] = []

    public init() {}
    public mutating func update(bufferPointer: UnsafeRawBufferPointer) {
        bytes.append(contentsOf: bufferPointer)
    }
    public func finalize() -> SHA3_512Digest {
        SHA3_512Digest(_sha3(bytes, rate: 72, outputByteCount: 64))
    }
}

public protocol DiffieHellmanKeyAgreement: Sendable {
    associatedtype PublicKey: Sendable
    var publicKey: PublicKey { get }
    func sharedSecretFromKeyAgreement(with publicKeyShare: PublicKey) throws -> SharedSecret
}

public protocol HPKEPublicKeySerialization: Sendable {
    func hpkeRepresentation(kem: HPKE.KEM) throws -> Data
    init<D: ContiguousBytes>(_ serialization: D, kem: HPKE.KEM) throws
}

public protocol HPKEDiffieHellmanPublicKey: HPKEPublicKeySerialization {
    associatedtype EphemeralPrivateKey: HPKEDiffieHellmanPrivateKeyGeneration
    where Self == Self.EphemeralPrivateKey.PublicKey
}

public protocol HPKEDiffieHellmanPrivateKey: DiffieHellmanKeyAgreement
where PublicKey: HPKEDiffieHellmanPublicKey {}

public protocol HPKEDiffieHellmanPrivateKeyGeneration: HPKEDiffieHellmanPrivateKey {
    init()
}

public protocol KEMPublicKey: Sendable {
    func encapsulate() throws -> KEM.EncapsulationResult
}

public protocol KEMPrivateKey: Sendable {
    associatedtype PublicKey: KEMPublicKey
    var publicKey: PublicKey { get }
    func decapsulate(_ encapsulated: Data) throws -> SymmetricKey
    static func generate() throws -> Self
}

public protocol HPKEKEMPublicKey: HPKEPublicKeySerialization, KEMPublicKey {
    associatedtype EphemeralPrivateKey: HPKEKEMPrivateKeyGeneration
    where Self == Self.EphemeralPrivateKey.PublicKey
}

public protocol HPKEKEMPrivateKey: KEMPrivateKey where PublicKey: HPKEKEMPublicKey {}

public protocol HPKEKEMPrivateKeyGeneration: HPKEKEMPrivateKey {
    init() throws
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

private let _keccakRoundConstants: [UInt64] = [
    0x0000000000000001, 0x0000000000008082, 0x800000000000808A,
    0x8000000080008000, 0x000000000000808B, 0x0000000080000001,
    0x8000000080008081, 0x8000000000008009, 0x000000000000008A,
    0x0000000000000088, 0x0000000080008009, 0x000000008000000A,
    0x000000008000808B, 0x800000000000008B, 0x8000000000008089,
    0x8000000000008003, 0x8000000000008002, 0x8000000000000080,
    0x000000000000800A, 0x800000008000000A, 0x8000000080008081,
    0x8000000000008080, 0x0000000080000001, 0x8000000080008008,
]

private func _keccakRotateLeft(_ value: UInt64, _ amount: Int) -> UInt64 {
    (value << amount) | (value >> (64 - amount))
}

private func _keccakPermute(_ state: inout [UInt64]) {
    let rotationOffsets: [[Int]] = [
        [0, 36, 3, 41, 18],
        [1, 44, 10, 45, 2],
        [62, 6, 43, 15, 61],
        [28, 55, 25, 21, 56],
        [27, 20, 39, 8, 14],
    ]
    for round in 0..<24 {
        var c = [UInt64](repeating: 0, count: 5)
        var d = [UInt64](repeating: 0, count: 5)
        for x in 0..<5 {
            c[x] = state[x] ^ state[x + 5] ^ state[x + 10] ^ state[x + 15] ^ state[x + 20]
        }
        for x in 0..<5 {
            d[x] = c[(x + 4) % 5] ^ _keccakRotateLeft(c[(x + 1) % 5], 1)
        }
        for x in 0..<5 {
            for y in 0..<5 {
                state[x + 5 * y] ^= d[x]
            }
        }
        var b = [UInt64](repeating: 0, count: 25)
        for x in 0..<5 {
            for y in 0..<5 {
                b[y + 5 * ((2 * x + 3 * y) % 5)] =
                    _keccakRotateLeft(state[x + 5 * y], rotationOffsets[x][y])
            }
        }
        for x in 0..<5 {
            for y in 0..<5 {
                state[x + 5 * y] = b[x + 5 * y] ^ ((~b[(x + 1) % 5 + 5 * y]) & b[(x + 2) % 5 + 5 * y])
            }
        }
        state[0] ^= _keccakRoundConstants[round]
    }
}

func _sha3(_ input: [UInt8], rate: Int, outputByteCount: Int) -> [UInt8] {
    var state = [UInt64](repeating: 0, count: 25)

    func xorRateBlock(_ block: ArraySlice<UInt8>) {
        let bytes = Array(block)
        for lane in 0..<(rate / 8) {
            var word: UInt64 = 0
            for byte in 0..<8 {
                word |= UInt64(bytes[lane * 8 + byte]) << (8 * byte)
            }
            state[lane] ^= word
        }
    }

    var offset = 0
    while offset + rate <= input.count {
        xorRateBlock(input[offset..<(offset + rate)])
        _keccakPermute(&state)
        offset += rate
    }

    var last = [UInt8](repeating: 0, count: rate)
    let remaining = input.count - offset
    if remaining > 0 {
        for index in 0..<remaining { last[index] = input[offset + index] }
    }
    last[remaining] ^= 0x06
    last[rate - 1] ^= 0x80
    xorRateBlock(last[0..<rate])
    _keccakPermute(&state)

    var output: [UInt8] = []
    output.reserveCapacity(outputByteCount)
    while output.count < outputByteCount {
        for lane in 0..<(rate / 8) {
            var word = state[lane]
            for _ in 0..<8 {
                output.append(UInt8(truncatingIfNeeded: word))
                word >>= 8
                if output.count == outputByteCount { return output }
            }
        }
        _keccakPermute(&state)
    }
    return Array(output.prefix(outputByteCount))
}
