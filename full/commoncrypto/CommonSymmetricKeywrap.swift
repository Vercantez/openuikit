private func _ccLoadBE64(_ bytes: [UInt8], _ offset: Int) -> UInt64 {
    var value: UInt64 = 0
    for index in 0..<8 {
        value = (value << 8) | UInt64(bytes[offset + index])
    }
    return value
}

private func _ccStoreBE64(_ value: UInt64) -> [UInt8] {
    var current = value
    var bytes = [UInt8](repeating: 0, count: 8)
    for index in (0..<8).reversed() {
        bytes[index] = UInt8(truncatingIfNeeded: current)
        current >>= 8
    }
    return bytes
}

func _ccAESKeyWrap(kek: [UInt8], key: [UInt8], iv: [UInt8]) -> [UInt8]? {
    guard _ccAESKeyValid(kek.count), key.count >= 16, key.count % 8 == 0, iv.count == 8 else {
        return nil
    }
    let roundKeys = _ccAESExpandKey(kek)
    var a = _ccLoadBE64(iv, 0)
    let n = key.count / 8
    var r = (0..<n).map { _ccLoadBE64(key, $0 * 8) }
    for j in 0..<6 {
        for i in 0..<n {
            var block = _ccStoreBE64(a)
            block.append(contentsOf: _ccStoreBE64(r[i]))
            let encrypted = _ccAESEncryptBlock(block, roundKeys: roundKeys)
            a = _ccLoadBE64(encrypted, 0) ^ UInt64((n * j) + i + 1)
            r[i] = _ccLoadBE64(encrypted, 8)
        }
    }
    var output = _ccStoreBE64(a)
    for word in r {
        output.append(contentsOf: _ccStoreBE64(word))
    }
    return output
}

func _ccAESKeyUnwrap(kek: [UInt8], wrapped: [UInt8], iv: [UInt8]) -> [UInt8]? {
    guard _ccAESKeyValid(kek.count), wrapped.count >= 24, wrapped.count % 8 == 0, iv.count == 8 else {
        return nil
    }
    let roundKeys = _ccAESExpandKey(kek)
    var a = _ccLoadBE64(wrapped, 0)
    let n = (wrapped.count / 8) - 1
    var r = (0..<n).map { _ccLoadBE64(wrapped, ($0 + 1) * 8) }
    for j in stride(from: 5, through: 0, by: -1) {
        for i in stride(from: n - 1, through: 0, by: -1) {
            let t = UInt64((n * j) + i + 1)
            var block = _ccStoreBE64(a ^ t)
            block.append(contentsOf: _ccStoreBE64(r[i]))
            let decrypted = _ccAESDecryptBlock(block, roundKeys: roundKeys)
            a = _ccLoadBE64(decrypted, 0)
            r[i] = _ccLoadBE64(decrypted, 8)
        }
    }
    if a != _ccLoadBE64(iv, 0) {
        return nil
    }
    var output: [UInt8] = []
    for word in r {
        output.append(contentsOf: _ccStoreBE64(word))
    }
    return output
}

public func CCSymmetricWrappedSize(_ algorithm: CCWrappingAlgorithm, _ rawKeyLen: Int) -> Int {
    if Int(algorithm) != kCCWRAPAES { return 0 }
    return rawKeyLen + 8
}

public func CCSymmetricUnwrappedSize(_ algorithm: CCWrappingAlgorithm, _ wrappedKeyLen: Int) -> Int {
    if Int(algorithm) != kCCWRAPAES { return 0 }
    if wrappedKeyLen < 8 { return 0 }
    return wrappedKeyLen - 8
}

public func CCSymmetricKeyWrap(
    _ algorithm: CCWrappingAlgorithm,
    _ iv: UnsafePointer<UInt8>!,
    _ ivLen: Int,
    _ kek: UnsafePointer<UInt8>!,
    _ kekLen: Int,
    _ rawKey: UnsafePointer<UInt8>!,
    _ rawKeyLen: Int,
    _ wrappedKey: UnsafeMutablePointer<UInt8>!,
    _ wrappedKeyLen: UnsafeMutablePointer<Int>!
) -> Int32 {
    if Int(algorithm) != kCCWRAPAES {
        return Int32(kCCUnimplemented)
    }
    guard let iv, let kek, let rawKey, let wrappedKey, let wrappedKeyLen else {
        return Int32(kCCParamError)
    }
    let needed = CCSymmetricWrappedSize(algorithm, rawKeyLen)
    if wrappedKeyLen.pointee < needed {
        wrappedKeyLen.pointee = needed
        return Int32(kCCBufferTooSmall)
    }
    let ivBytes = _ccCopy(UnsafeRawPointer(iv), ivLen)
    let kekBytes = _ccCopy(UnsafeRawPointer(kek), kekLen)
    let keyBytes = _ccCopy(UnsafeRawPointer(rawKey), rawKeyLen)
    guard let wrapped = _ccAESKeyWrap(kek: kekBytes, key: keyBytes, iv: ivBytes) else {
        return Int32(kCCParamError)
    }
    _ccWrite(wrapped, to: wrappedKey)
    wrappedKeyLen.pointee = wrapped.count
    return 0
}

public func CCSymmetricKeyUnwrap(
    _ algorithm: CCWrappingAlgorithm,
    _ iv: UnsafePointer<UInt8>!,
    _ ivLen: Int,
    _ kek: UnsafePointer<UInt8>!,
    _ kekLen: Int,
    _ wrappedKey: UnsafePointer<UInt8>!,
    _ wrappedKeyLen: Int,
    _ rawKey: UnsafeMutablePointer<UInt8>!,
    _ rawKeyLen: UnsafeMutablePointer<Int>!
) -> Int32 {
    if Int(algorithm) != kCCWRAPAES {
        return Int32(kCCUnimplemented)
    }
    guard let iv, let kek, let wrappedKey, let rawKey, let rawKeyLen else {
        return Int32(kCCParamError)
    }
    let needed = CCSymmetricUnwrappedSize(algorithm, wrappedKeyLen)
    if rawKeyLen.pointee < needed {
        rawKeyLen.pointee = needed
        return Int32(kCCBufferTooSmall)
    }
    let ivBytes = _ccCopy(UnsafeRawPointer(iv), ivLen)
    let kekBytes = _ccCopy(UnsafeRawPointer(kek), kekLen)
    let wrappedBytes = _ccCopy(UnsafeRawPointer(wrappedKey), wrappedKeyLen)
    guard let unwrapped = _ccAESKeyUnwrap(kek: kekBytes, wrapped: wrappedBytes, iv: ivBytes) else {
        return Int32(kCCDecodeError)
    }
    _ccWrite(unwrapped, to: rawKey)
    rawKeyLen.pointee = unwrapped.count
    return 0
}
