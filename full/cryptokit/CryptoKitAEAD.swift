import Foundation

public enum AES: Sendable {
    public enum GCM: Sendable {
        public struct Nonce: ContiguousBytes, Sequence, Sendable {
            public typealias Iterator = Array<UInt8>.Iterator
            public typealias Element = IndexingIterator<Array<UInt8>>.Element
            static let byteCount = 12
            let bytes: [UInt8]

            public init() {
                bytes = _ckRandomBytes(Self.byteCount)
            }

            public init<D: DataProtocol>(data: D) throws {
                let candidate = _ckBytes(data)
                guard candidate.count == Self.byteCount else {
                    throw CryptoKitError.incorrectParameterSize
                }
                bytes = candidate
            }

            public func makeIterator() -> Iterator { bytes.makeIterator() }
            public func withUnsafeBytes<R>(
                _ body: (UnsafeRawBufferPointer) throws -> R
            ) rethrows -> R {
                try bytes.withUnsafeBytes(body)
            }
        }

        public struct SealedBox: Sendable {
            public let nonce: Nonce
            public let combined: Data?

            public var ciphertext: Data {
                guard let combined, combined.count >= 12 + 16 else { return Data() }
                return combined.dropFirst(12).dropLast(16)
            }

            public var tag: Data {
                guard let combined, combined.count >= 16 else { return Data() }
                return combined.suffix(16)
            }

            public init<C: DataProtocol, T: DataProtocol>(
                nonce: Nonce,
                ciphertext: C,
                tag: T
            ) throws {
                let tagBytes = _ckBytes(tag)
                guard tagBytes.count == 16 else {
                    throw CryptoKitError.incorrectParameterSize
                }
                var combined = Data(nonce.bytes)
                combined.append(contentsOf: ciphertext)
                combined.append(contentsOf: tagBytes)
                self.nonce = nonce
                self.combined = combined
            }

            public init<D: DataProtocol>(combined: D) throws {
                let bytes = _ckBytes(combined)
                guard bytes.count >= 12 + 16 else {
                    throw CryptoKitError.incorrectParameterSize
                }
                nonce = try Nonce(data: Data(bytes.prefix(12)))
                self.combined = Data(bytes)
            }
        }

        public static func seal<Plaintext: DataProtocol>(
            _ message: Plaintext,
            using key: SymmetricKey,
            nonce: Nonce? = nil
        ) throws -> SealedBox {
            try seal(message, using: key, nonce: nonce, authenticating: Data())
        }

        public static func seal<Plaintext: DataProtocol, AuthenticatedData: DataProtocol>(
            _ message: Plaintext,
            using key: SymmetricKey,
            nonce: Nonce? = nil,
            authenticating authenticatedData: AuthenticatedData
        ) throws -> SealedBox {
            let keyBytes = Array(_ckData(key))
            guard keyBytes.count == 16 || keyBytes.count == 24 || keyBytes.count == 32 else {
                throw CryptoKitError.incorrectKeySize
            }
            let usedNonce = nonce ?? Nonce()
            let (ciphertext, tag) = try _aesGCMSeal(
                key: keyBytes,
                nonce: usedNonce.bytes,
                plaintext: _ckBytes(message),
                aad: _ckBytes(authenticatedData)
            )
            return try SealedBox(nonce: usedNonce, ciphertext: Data(ciphertext), tag: Data(tag))
        }

        public static func open(
            _ sealedBox: SealedBox,
            using key: SymmetricKey
        ) throws -> Data {
            try open(sealedBox, using: key, authenticating: Data())
        }

        public static func open<AuthenticatedData: DataProtocol>(
            _ sealedBox: SealedBox,
            using key: SymmetricKey,
            authenticating authenticatedData: AuthenticatedData
        ) throws -> Data {
            let keyBytes = Array(_ckData(key))
            guard keyBytes.count == 16 || keyBytes.count == 24 || keyBytes.count == 32 else {
                throw CryptoKitError.incorrectKeySize
            }
            return try Data(
                _aesGCMOpen(
                    key: keyBytes,
                    nonce: sealedBox.nonce.bytes,
                    ciphertext: _ckBytes(sealedBox.ciphertext),
                    tag: _ckBytes(sealedBox.tag),
                    aad: _ckBytes(authenticatedData)
                )
            )
        }
    }

    public enum KeyWrap: Sendable {
        public static func wrap(
            _ keyToWrap: SymmetricKey,
            using kek: SymmetricKey
        ) throws -> Data {
            let kekBytes = Array(_ckData(kek))
            let keyBytes = Array(_ckData(keyToWrap))
            guard kekBytes.count == 16 || kekBytes.count == 24 || kekBytes.count == 32 else {
                throw CryptoKitError.incorrectKeySize
            }
            guard keyBytes.count >= 16, keyBytes.count % 8 == 0 else {
                throw CryptoKitError.incorrectParameterSize
            }
            return try Data(_aesKeyWrap(kek: kekBytes, key: keyBytes))
        }

        public static func unwrap<WrappedKey: DataProtocol>(
            _ wrappedKey: WrappedKey,
            using kek: SymmetricKey
        ) throws -> SymmetricKey {
            let kekBytes = Array(_ckData(kek))
            let wrapped = _ckBytes(wrappedKey)
            guard kekBytes.count == 16 || kekBytes.count == 24 || kekBytes.count == 32 else {
                throw CryptoKitError.incorrectKeySize
            }
            guard wrapped.count >= 24, wrapped.count % 8 == 0 else {
                throw CryptoKitError.incorrectParameterSize
            }
            do {
                return SymmetricKey(rawBytes: try _aesKeyUnwrap(kek: kekBytes, wrapped: wrapped))
            } catch {
                throw CryptoKitError.unwrapFailure
            }
        }
    }
}

public enum ChaChaPoly: Sendable {
    public struct Nonce: ContiguousBytes, Sequence, Sendable {
        public typealias Iterator = Array<UInt8>.Iterator
        public typealias Element = IndexingIterator<Array<UInt8>>.Element
        static let byteCount = 12
        let bytes: [UInt8]

        public init() {
            bytes = _ckRandomBytes(Self.byteCount)
        }

        public init<D: DataProtocol>(data: D) throws {
            let candidate = _ckBytes(data)
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

    @frozen public struct SealedBox: Sendable {
        public let combined: Data
        public var nonce: Nonce {
            try! Nonce(data: combined.prefix(12))
        }
        public var ciphertext: Data {
            combined.dropFirst(12).dropLast(16)
        }
        public var tag: Data { combined.suffix(16) }

        public init<C: DataProtocol, T: DataProtocol>(
            nonce: Nonce,
            ciphertext: C,
            tag: T
        ) throws {
            let tagBytes = _ckBytes(tag)
            guard tagBytes.count == 16 else {
                throw CryptoKitError.incorrectParameterSize
            }
            var combined = Data(nonce.bytes)
            combined.append(contentsOf: ciphertext)
            combined.append(contentsOf: tagBytes)
            self.combined = combined
        }

        public init<D: DataProtocol>(combined: D) throws {
            let bytes = _ckBytes(combined)
            guard bytes.count >= 12 + 16 else {
                throw CryptoKitError.incorrectParameterSize
            }
            self.combined = Data(bytes)
        }
    }

    public static func seal<Plaintext: DataProtocol>(
        _ message: Plaintext,
        using key: SymmetricKey,
        nonce: Nonce? = nil
    ) throws -> SealedBox {
        try seal(message, using: key, nonce: nonce, authenticating: Data())
    }

    public static func seal<Plaintext: DataProtocol, AuthenticatedData: DataProtocol>(
        _ message: Plaintext,
        using key: SymmetricKey,
        nonce: Nonce? = nil,
        authenticating authenticatedData: AuthenticatedData
    ) throws -> SealedBox {
        let keyBytes = Array(_ckData(key))
        guard keyBytes.count == 32 else { throw CryptoKitError.incorrectKeySize }
        let usedNonce = nonce ?? Nonce()
        let (ciphertext, tag) = _chachaPolySeal(
            key: keyBytes,
            nonce: usedNonce.bytes,
            plaintext: _ckBytes(message),
            aad: _ckBytes(authenticatedData)
        )
        return try SealedBox(nonce: usedNonce, ciphertext: Data(ciphertext), tag: Data(tag))
    }

    public static func open(
        _ sealedBox: SealedBox,
        using key: SymmetricKey
    ) throws -> Data {
        try open(sealedBox, using: key, authenticating: Data())
    }

    public static func open<AuthenticatedData: DataProtocol>(
        _ sealedBox: SealedBox,
        using key: SymmetricKey,
        authenticating authenticatedData: AuthenticatedData
    ) throws -> Data {
        let keyBytes = Array(_ckData(key))
        guard keyBytes.count == 32 else { throw CryptoKitError.incorrectKeySize }
        return try Data(
            _chachaPolyOpen(
                key: keyBytes,
                nonce: sealedBox.nonce.bytes,
                ciphertext: _ckBytes(sealedBox.ciphertext),
                tag: _ckBytes(sealedBox.tag),
                aad: _ckBytes(authenticatedData)
            )
        )
    }
}

// MARK: - AES

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

private let _aesRcon: [UInt8] = [
    0x00, 0x01, 0x02, 0x04, 0x08, 0x10, 0x20, 0x40, 0x80, 0x1b, 0x36,
]

private func _aesXt(_ value: UInt8) -> UInt8 {
    let high = value & 0x80
    let shifted = (value << 1) & 0xff
    return high == 0 ? shifted : (shifted ^ 0x1b)
}

private func _aesExpandKey(_ key: [UInt8]) -> [[UInt8]] {
    let keyLength = key.count
    let rounds = keyLength == 16 ? 10 : (keyLength == 24 ? 12 : 14)
    let n = keyLength / 4
    var words = [[UInt8]](repeating: [0, 0, 0, 0], count: 4 * (rounds + 1))
    for index in 0..<n {
        words[index] = Array(key[(index * 4)..<(index * 4 + 4)])
    }
    for index in n..<(4 * (rounds + 1)) {
        var temp = words[index - 1]
        if index % n == 0 {
            temp = [temp[1], temp[2], temp[3], temp[0]].map { _aesSBox[Int($0)] }
            temp[0] ^= _aesRcon[index / n]
        } else if n > 6 && index % n == 4 {
            temp = temp.map { _aesSBox[Int($0)] }
        }
        words[index] = zip(words[index - n], temp).map { $0 ^ $1 }
    }
    var roundKeys: [[UInt8]] = []
    for round in 0...rounds {
        var block: [UInt8] = []
        for column in 0..<4 { block.append(contentsOf: words[round * 4 + column]) }
        roundKeys.append(block)
    }
    return roundKeys
}

private func _aesEncryptBlock(_ input: [UInt8], roundKeys: [[UInt8]]) -> [UInt8] {
    var state = input
    func addRoundKey(_ round: Int) {
        for index in 0..<16 { state[index] ^= roundKeys[round][index] }
    }
    func subBytes() {
        for index in 0..<16 { state[index] = _aesSBox[Int(state[index])] }
    }
    func shiftRows() {
        state = [
            state[0], state[5], state[10], state[15],
            state[4], state[9], state[14], state[3],
            state[8], state[13], state[2], state[7],
            state[12], state[1], state[6], state[11],
        ]
    }
    func mixColumns() {
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
    }
    addRoundKey(0)
    for round in 1..<(roundKeys.count - 1) {
        subBytes()
        shiftRows()
        mixColumns()
        addRoundKey(round)
    }
    subBytes()
    shiftRows()
    addRoundKey(roundKeys.count - 1)
    return state
}

private func _gf128Mul(_ x: [UInt8], _ y: [UInt8]) -> [UInt8] {
    var v = y
    var z = [UInt8](repeating: 0, count: 16)
    for byte in x {
        for bit in (0..<8).reversed() {
            if ((byte >> bit) & 1) == 1 {
                for index in 0..<16 { z[index] ^= v[index] }
            }
            let lsb = v[15] & 1
            var carry: UInt8 = 0
            for index in 0..<16 {
                let next = v[index] & 1
                v[index] = (v[index] >> 1) | (carry << 7)
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
        for index in 0..<take { block[index] = data[offset + index] }
        for index in 0..<16 { y[index] ^= block[index] }
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

private func _aesCTR(
    roundKeys: [[UInt8]],
    counter: [UInt8],
    data: [UInt8]
) -> [UInt8] {
    var blockCounter = counter
    var output: [UInt8] = []
    output.reserveCapacity(data.count)
    var offset = 0
    while offset < data.count {
        let keystream = _aesEncryptBlock(blockCounter, roundKeys: roundKeys)
        _inc32(&blockCounter)
        let take = min(16, data.count - offset)
        for index in 0..<take {
            output.append(data[offset + index] ^ keystream[index])
        }
        offset += take
    }
    return output
}

private func _aesGCMSeal(
    key: [UInt8],
    nonce: [UInt8],
    plaintext: [UInt8],
    aad: [UInt8]
) throws -> ([UInt8], [UInt8]) {
    let roundKeys = _aesExpandKey(key)
    let h = _aesEncryptBlock([UInt8](repeating: 0, count: 16), roundKeys: roundKeys)
    var j0 = nonce
    j0.append(contentsOf: [0, 0, 0, 1])
    var counter = j0
    _inc32(&counter)
    let ciphertext = _aesCTR(roundKeys: roundKeys, counter: counter, data: plaintext)
    var ghashInput = aad
    let aadPad = (16 - (aad.count % 16)) % 16
    ghashInput.append(contentsOf: [UInt8](repeating: 0, count: aadPad))
    ghashInput.append(contentsOf: ciphertext)
    let cipherPad = (16 - (ciphertext.count % 16)) % 16
    ghashInput.append(contentsOf: [UInt8](repeating: 0, count: cipherPad))
    func lengthBytes(_ count: Int) -> [UInt8] {
        var value = UInt64(count) * 8
        var bytes = [UInt8](repeating: 0, count: 8)
        for index in (0..<8).reversed() {
            bytes[index] = UInt8(truncatingIfNeeded: value)
            value >>= 8
        }
        return bytes
    }
    ghashInput.append(contentsOf: lengthBytes(aad.count))
    ghashInput.append(contentsOf: lengthBytes(ciphertext.count))
    let s = _ghash(h, ghashInput)
    let tagMask = _aesEncryptBlock(j0, roundKeys: roundKeys)
    let tag = zip(s, tagMask).map { $0 ^ $1 }
    return (ciphertext, tag)
}

private func _aesGCMOpen(
    key: [UInt8],
    nonce: [UInt8],
    ciphertext: [UInt8],
    tag: [UInt8],
    aad: [UInt8]
) throws -> [UInt8] {
    let roundKeys = _aesExpandKey(key)
    let h = _aesEncryptBlock([UInt8](repeating: 0, count: 16), roundKeys: roundKeys)
    var j0 = nonce
    j0.append(contentsOf: [0, 0, 0, 1])
    var ghashInput = aad
    let aadPad = (16 - (aad.count % 16)) % 16
    ghashInput.append(contentsOf: [UInt8](repeating: 0, count: aadPad))
    ghashInput.append(contentsOf: ciphertext)
    let cipherPad = (16 - (ciphertext.count % 16)) % 16
    ghashInput.append(contentsOf: [UInt8](repeating: 0, count: cipherPad))
    func lengthBytes(_ count: Int) -> [UInt8] {
        var value = UInt64(count) * 8
        var bytes = [UInt8](repeating: 0, count: 8)
        for index in (0..<8).reversed() {
            bytes[index] = UInt8(truncatingIfNeeded: value)
            value >>= 8
        }
        return bytes
    }
    ghashInput.append(contentsOf: lengthBytes(aad.count))
    ghashInput.append(contentsOf: lengthBytes(ciphertext.count))
    let s = _ghash(h, ghashInput)
    let tagMask = _aesEncryptBlock(j0, roundKeys: roundKeys)
    let computed = zip(s, tagMask).map { $0 ^ $1 }
    guard _ckEqualBytes(computed, tag) else { throw CryptoKitError.authenticationFailure }
    var counter = j0
    _inc32(&counter)
    return _aesCTR(roundKeys: roundKeys, counter: counter, data: ciphertext)
}

private func _aesKeyWrap(kek: [UInt8], key: [UInt8]) throws -> [UInt8] {
    let roundKeys = _aesExpandKey(kek)
    var a: UInt64 = 0xa6a6a6a6a6a6a6a6
    let n = key.count / 8
    var r = (0..<n).map { index -> UInt64 in
        var word: UInt64 = 0
        for byte in 0..<8 { word = (word << 8) | UInt64(key[index * 8 + byte]) }
        return word
    }
    for j in 0..<6 {
        for i in 0..<n {
            var block = [UInt8](repeating: 0, count: 16)
            var av = a
            for byte in (0..<8).reversed() {
                block[byte] = UInt8(truncatingIfNeeded: av)
                av >>= 8
            }
            var rv = r[i]
            for byte in (8..<16).reversed() {
                block[byte] = UInt8(truncatingIfNeeded: rv)
                rv >>= 8
            }
            let encrypted = _aesEncryptBlock(block, roundKeys: roundKeys)
            var t: UInt64 = 0
            for byte in 0..<8 { t = (t << 8) | UInt64(encrypted[byte]) }
            a = t ^ UInt64((n * j) + i + 1)
            r[i] = 0
            for byte in 8..<16 { r[i] = (r[i] << 8) | UInt64(encrypted[byte]) }
        }
    }
    var output: [UInt8] = []
    var av = a
    for _ in 0..<8 {
        output.insert(UInt8(truncatingIfNeeded: av), at: 0)
        av >>= 8
    }
    for word in r {
        var value = word
        var chunk = [UInt8](repeating: 0, count: 8)
        for byte in (0..<8).reversed() {
            chunk[byte] = UInt8(truncatingIfNeeded: value)
            value >>= 8
        }
        output.append(contentsOf: chunk)
    }
    return output
}

private func _aesKeyUnwrap(kek: [UInt8], wrapped: [UInt8]) throws -> [UInt8] {
    // Inverse of RFC 3394 using encrypt-only AES via stored wrap check.
    // Linux guest implements wrap; unwrap verifies by re-wrapping candidates is
    // not possible without AES decrypt. Fail closed unless wrap round-trips via
    // a dedicated decrypt path.
    throw CryptoKitError.unwrapFailure
}

// MARK: - ChaCha20-Poly1305 (RFC 8439)

private func _rotl32(_ value: UInt32, _ amount: UInt32) -> UInt32 {
    (value << amount) | (value >> (32 - amount))
}

private func _chachaQuarter(_ state: inout [UInt32], _ ia: Int, _ ib: Int, _ ic: Int, _ id: Int) {
    state[ia] &+= state[ib]; state[id] ^= state[ia]; state[id] = _rotl32(state[id], 16)
    state[ic] &+= state[id]; state[ib] ^= state[ic]; state[ib] = _rotl32(state[ib], 12)
    state[ia] &+= state[ib]; state[id] ^= state[ia]; state[id] = _rotl32(state[id], 8)
    state[ic] &+= state[id]; state[ib] ^= state[ic]; state[ib] = _rotl32(state[ib], 7)
}

private func _chachaBlock(key: [UInt8], nonce: [UInt8], counter: UInt32) -> [UInt8] {
    let constants: [UInt32] = [0x61707865, 0x3320646e, 0x79622d32, 0x6b206574]
    func word(_ bytes: [UInt8], _ offset: Int) -> UInt32 {
        UInt32(bytes[offset])
            | (UInt32(bytes[offset + 1]) << 8)
            | (UInt32(bytes[offset + 2]) << 16)
            | (UInt32(bytes[offset + 3]) << 24)
    }
    var state: [UInt32] = constants
    for index in 0..<8 { state.append(word(key, index * 4)) }
    state.append(counter)
    for index in 0..<3 { state.append(word(nonce, index * 4)) }
    var working = state
    for _ in 0..<10 {
        _chachaQuarter(&working, 0, 4, 8, 12)
        _chachaQuarter(&working, 1, 5, 9, 13)
        _chachaQuarter(&working, 2, 6, 10, 14)
        _chachaQuarter(&working, 3, 7, 11, 15)
        _chachaQuarter(&working, 0, 5, 10, 15)
        _chachaQuarter(&working, 1, 6, 11, 12)
        _chachaQuarter(&working, 2, 7, 8, 13)
        _chachaQuarter(&working, 3, 4, 9, 14)
    }
    var output: [UInt8] = []
    for index in 0..<16 {
        let value = working[index] &+ state[index]
        output.append(UInt8(truncatingIfNeeded: value))
        output.append(UInt8(truncatingIfNeeded: value >> 8))
        output.append(UInt8(truncatingIfNeeded: value >> 16))
        output.append(UInt8(truncatingIfNeeded: value >> 24))
    }
    return output
}

private func _chacha20(key: [UInt8], nonce: [UInt8], counter: UInt32, data: [UInt8]) -> [UInt8] {
    var output: [UInt8] = []
    output.reserveCapacity(data.count)
    var blockCounter = counter
    var offset = 0
    while offset < data.count {
        let stream = _chachaBlock(key: key, nonce: nonce, counter: blockCounter)
        blockCounter &+= 1
        let take = min(64, data.count - offset)
        for index in 0..<take { output.append(data[offset + index] ^ stream[index]) }
        offset += take
    }
    return output
}

private func _poly1305(key: [UInt8], message: [UInt8]) -> [UInt8] {
    precondition(key.count == 32)
    var r = Array(key.prefix(16))
    r[3] &= 15
    r[7] &= 15
    r[11] &= 15
    r[15] &= 15
    r[4] &= 252
    r[8] &= 252
    r[12] &= 252
    let s = Array(key[16..<32])

    func add(_ lhs: [UInt8], _ rhs: [UInt8]) -> [UInt8] {
        let count = max(lhs.count, rhs.count)
        var result = [UInt8](repeating: 0, count: count)
        var carry: UInt16 = 0
        for index in 0..<count {
            let left = index < lhs.count ? UInt16(lhs[index]) : 0
            let right = index < rhs.count ? UInt16(rhs[index]) : 0
            let sum = left + right + carry
            result[index] = UInt8(truncatingIfNeeded: sum)
            carry = sum >> 8
        }
        if carry != 0 { result.append(UInt8(carry)) }
        return result
    }

    func mul(_ lhs: [UInt8], _ rhs: [UInt8]) -> [UInt8] {
        var acc = [UInt32](repeating: 0, count: lhs.count + rhs.count)
        for i in 0..<lhs.count {
            for j in 0..<rhs.count {
                acc[i + j] += UInt32(lhs[i]) * UInt32(rhs[j])
            }
        }
        var result = [UInt8](repeating: 0, count: acc.count)
        var carry: UInt32 = 0
        for index in 0..<acc.count {
            let value = acc[index] + carry
            result[index] = UInt8(truncatingIfNeeded: value)
            carry = value >> 8
        }
        while carry != 0 {
            result.append(UInt8(truncatingIfNeeded: carry))
            carry >>= 8
        }
        return result
    }

    func modP(_ value: [UInt8]) -> [UInt8] {
        var current = value
        while true {
            while current.count > 17, current.last == 0 { current.removeLast() }
            if current.count < 17 { return current }
            if current.count == 17, current[16] < 4 { return current }
            var high = Array(current.dropFirst(16))
            if !high.isEmpty {
                high[0] >>= 2
                for index in 1..<high.count {
                    high[index - 1] |= (high[index] & 3) << 6
                    high[index] >>= 2
                }
            }
            var low = Array(current.prefix(16))
            if current.count > 16 {
                low.append(current[16] & 3)
            }
            current = add(low, mul(high, [5]))
        }
    }

    var accumulator: [UInt8] = [0]
    var offset = 0
    while offset < message.count {
        let take = min(16, message.count - offset)
        var block = Array(message[offset..<(offset + take)])
        block.append(1)
        accumulator = modP(mul(add(accumulator, block), r))
        offset += take
    }
    var tag = add(accumulator, s)
    if tag.count < 16 {
        tag.append(contentsOf: [UInt8](repeating: 0, count: 16 - tag.count))
    }
    return Array(tag.prefix(16))
}

private func _poly1305Pad(_ aad: [UInt8], _ ciphertext: [UInt8]) -> [UInt8] {
    func pad16(_ bytes: [UInt8]) -> [UInt8] {
        var value = bytes
        while value.count % 16 != 0 { value.append(0) }
        return value
    }
    func le64(_ value: Int) -> [UInt8] {
        var count = UInt64(value)
        var bytes = [UInt8](repeating: 0, count: 8)
        for index in 0..<8 {
            bytes[index] = UInt8(truncatingIfNeeded: count)
            count >>= 8
        }
        return bytes
    }
    return pad16(aad) + pad16(ciphertext) + le64(aad.count) + le64(ciphertext.count)
}

private func _chachaPolySeal(
    key: [UInt8],
    nonce: [UInt8],
    plaintext: [UInt8],
    aad: [UInt8]
) -> ([UInt8], [UInt8]) {
    let otk = _chachaBlock(key: key, nonce: nonce, counter: 0)
    let ciphertext = _chacha20(key: key, nonce: nonce, counter: 1, data: plaintext)
    let tag = _poly1305(key: Array(otk.prefix(32)), message: _poly1305Pad(aad, ciphertext))
    return (ciphertext, tag)
}

private func _chachaPolyOpen(
    key: [UInt8],
    nonce: [UInt8],
    ciphertext: [UInt8],
    tag: [UInt8],
    aad: [UInt8]
) throws -> [UInt8] {
    let otk = _chachaBlock(key: key, nonce: nonce, counter: 0)
    let expected = _poly1305(key: Array(otk.prefix(32)), message: _poly1305Pad(aad, ciphertext))
    guard _ckEqualBytes(expected, tag) else { throw CryptoKitError.authenticationFailure }
    return _chacha20(key: key, nonce: nonce, counter: 1, data: ciphertext)
}
