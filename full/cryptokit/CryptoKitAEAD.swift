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
    var r128 = [UInt8](key.prefix(16))
    r128[3] &= 15
    r128[4] &= 252
    r128[7] &= 15
    r128[8] &= 252
    r128[11] &= 15
    r128[12] &= 252
    r128[15] &= 15
    func load26(_ bytes: [UInt8], _ offset: Int, _ right: Int) -> UInt64 {
        var value: UInt64 = 0
        for index in 0..<4 {
            if offset + index < bytes.count {
                value |= UInt64(bytes[offset + index]) << (8 * index)
            }
        }
        return (value >> right) & 0x3ffffff
    }
    r = [
        load26(r128, 0, 0),
        load26(r128, 3, 2),
        load26(r128, 6, 4),
        load26(r128, 9, 6),
        load26(r128, 12, 8),
    ]
    let s: [UInt64] = [
        UInt64(key[16]) | (UInt64(key[17]) << 8) | (UInt64(key[18]) << 16) | (UInt64(key[19]) << 24),
        UInt64(key[20]) | (UInt64(key[21]) << 8) | (UInt64(key[22]) << 16) | (UInt64(key[23]) << 24),
        UInt64(key[24]) | (UInt64(key[25]) << 8) | (UInt64(key[26]) << 16) | (UInt64(key[27]) << 24),
        UInt64(key[28]) | (UInt64(key[29]) << 8) | (UInt64(key[30]) << 16) | (UInt64(key[31]) << 24),
    ]
    var h = [UInt64](repeating: 0, count: 5)
    let r1_5 = r[1] * 5
    let r2_5 = r[2] * 5
    let r3_5 = r[3] * 5
    let r4_5 = r[4] * 5
    var offset = 0
    while offset < message.count {
        var block = [UInt8](repeating: 0, count: 17)
        let take = min(16, message.count - offset)
        for index in 0..<take { block[index] = message[offset + index] }
        block[take] = 1
        var t = [
            load26(block, 0, 0),
            load26(block, 3, 2),
            load26(block, 6, 4),
            load26(block, 9, 6),
            load26(block, 12, 8),
        ]
        if take == 16 { t[4] += 1 << 24 }
        for index in 0..<5 { h[index] &+= t[index] }
        let d0 = h[0] * r[0] + h[1] * r4_5 + h[2] * r3_5 + h[3] * r2_5 + h[4] * r1_5
        let d1 = h[0] * r[1] + h[1] * r[0] + h[2] * r4_5 + h[3] * r3_5 + h[4] * r2_5
        let d2 = h[0] * r[2] + h[1] * r[1] + h[2] * r[0] + h[3] * r4_5 + h[4] * r3_5
        let d3 = h[0] * r[3] + h[1] * r[2] + h[2] * r[1] + h[3] * r[0] + h[4] * r4_5
        let d4 = h[0] * r[4] + h[1] * r[3] + h[2] * r[2] + h[3] * r[1] + h[4] * r[0]
        h[0] = d0 & 0x3ffffff; var carry = d0 >> 26
        h[1] = (d1 + carry) & 0x3ffffff; carry = (d1 + carry) >> 26
        h[2] = (d2 + carry) & 0x3ffffff; carry = (d2 + carry) >> 26
        h[3] = (d3 + carry) & 0x3ffffff; carry = (d3 + carry) >> 26
        h[4] = (d4 + carry) & 0x3ffffff; carry = (d4 + carry) >> 26
        h[0] += carry * 5
        carry = h[0] >> 26
        h[0] &= 0x3ffffff
        h[1] += carry
        offset += 16
    }
    var carry = h[1] >> 26; h[1] &= 0x3ffffff
    h[2] += carry; carry = h[2] >> 26; h[2] &= 0x3ffffff
    h[3] += carry; carry = h[3] >> 26; h[3] &= 0x3ffffff
    h[4] += carry; carry = h[4] >> 26; h[4] &= 0x3ffffff
    h[0] += carry * 5; carry = h[0] >> 26; h[0] &= 0x3ffffff
    h[1] += carry
    var g = h
    g[0] += 5
    carry = g[0] >> 26; g[0] &= 0x3ffffff
    g[1] += carry; carry = g[1] >> 26; g[1] &= 0x3ffffff
    g[2] += carry; carry = g[2] >> 26; g[2] &= 0x3ffffff
    g[3] += carry; carry = g[3] >> 26; g[3] &= 0x3ffffff
    g[4] += carry - (1 << 26)
    let mask = (g[4] >> 63) &- 1
    let nmask = ~mask
    for index in 0..<5 {
        h[index] = (h[index] & nmask) | (g[index] & mask)
    }
    var f0 = (h[0] | (h[1] << 26)) &+ s[0]
    var f1 = ((h[1] >> 6) | (h[2] << 20)) &+ s[1]
    var f2 = ((h[2] >> 12) | (h[3] << 14)) &+ s[2]
    var f3 = ((h[3] >> 18) | (h[4] << 8)) &+ s[3]
    f1 += f0 >> 32; f0 &= 0xffffffff
    f2 += f1 >> 32; f1 &= 0xffffffff
    f3 += f2 >> 32; f2 &= 0xffffffff
    f3 &= 0xffffffff
    var tag = [UInt8](repeating: 0, count: 16)
    for (index, value) in [f0, f1, f2, f3].enumerated() {
        tag[index * 4] = UInt8(truncatingIfNeeded: value)
        tag[index * 4 + 1] = UInt8(truncatingIfNeeded: value >> 8)
        tag[index * 4 + 2] = UInt8(truncatingIfNeeded: value >> 16)
        tag[index * 4 + 3] = UInt8(truncatingIfNeeded: value >> 24)
    }
    return tag
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
