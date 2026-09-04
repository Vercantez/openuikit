final class _CCHmacBox {
    var algorithm: CCHmacAlgorithm
    var ipad: [UInt8]
    var opad: [UInt8]
    var message: [UInt8]

    init(algorithm: CCHmacAlgorithm, key: [UInt8]) {
        self.algorithm = algorithm
        let block = _ccHmacBlock(algorithm)
        var actualKey = key
        if actualKey.count > block {
            actualKey = _ccHmacHash(algorithm, actualKey)
        }
        if actualKey.count < block {
            actualKey.append(contentsOf: [UInt8](repeating: 0, count: block - actualKey.count))
        }
        ipad = actualKey.map { $0 ^ 0x36 }
        opad = actualKey.map { $0 ^ 0x5c }
        message = []
    }
}

private let _ccHmacMagic: UInt32 = 0x484D4143

func _ccHmacBlock(_ algorithm: CCHmacAlgorithm) -> Int {
    switch Int(algorithm) {
    case kCCHmacAlgSHA384, kCCHmacAlgSHA512:
        return 128
    default:
        return 64
    }
}

func _ccHmacDigestLength(_ algorithm: CCHmacAlgorithm) -> Int {
    switch Int(algorithm) {
    case kCCHmacAlgMD5: return Int(CC_MD5_DIGEST_LENGTH)
    case kCCHmacAlgSHA1: return Int(CC_SHA1_DIGEST_LENGTH)
    case kCCHmacAlgSHA224: return Int(CC_SHA224_DIGEST_LENGTH)
    case kCCHmacAlgSHA256: return Int(CC_SHA256_DIGEST_LENGTH)
    case kCCHmacAlgSHA384: return Int(CC_SHA384_DIGEST_LENGTH)
    case kCCHmacAlgSHA512: return Int(CC_SHA512_DIGEST_LENGTH)
    default: return Int(CC_SHA256_DIGEST_LENGTH)
    }
}

func _ccHmacHash(_ algorithm: CCHmacAlgorithm, _ data: [UInt8]) -> [UInt8] {
    switch Int(algorithm) {
    case kCCHmacAlgMD5: return _ccMD5(data)
    case kCCHmacAlgSHA1: return _ccSHA1(data)
    case kCCHmacAlgSHA224: return _ccSHA256(data, variant224: true)
    case kCCHmacAlgSHA256: return _ccSHA256(data, variant224: false)
    case kCCHmacAlgSHA384: return _ccSHA512(data, variant384: true)
    case kCCHmacAlgSHA512: return _ccSHA512(data, variant384: false)
    default: return _ccSHA256(data, variant224: false)
    }
}

func _ccHMAC(_ algorithm: CCHmacAlgorithm, key: [UInt8], message: [UInt8]) -> [UInt8] {
    let box = _CCHmacBox(algorithm: algorithm, key: key)
    box.message = message
    let inner = _ccHmacHash(algorithm, box.ipad + box.message)
    return _ccHmacHash(algorithm, box.opad + inner)
}

private func _ccHmacStore(_ box: _CCHmacBox, into ctx: UnsafeMutablePointer<CCHmacContext>) {
    if ctx.pointee.ctx.2 == _ccHmacMagic {
        _ = _ccHmacLoad(ctx, releasing: true)
    }
    let unmanaged = Unmanaged.passRetained(box)
    let raw = UInt(bitPattern: unmanaged.toOpaque())
    ctx.pointee.ctx.0 = UInt32(truncatingIfNeeded: raw)
    ctx.pointee.ctx.1 = UInt32(truncatingIfNeeded: raw >> 32)
    ctx.pointee.ctx.2 = _ccHmacMagic
}

private func _ccHmacLoad(
    _ ctx: UnsafeMutablePointer<CCHmacContext>,
    releasing: Bool
) -> _CCHmacBox? {
    guard ctx.pointee.ctx.2 == _ccHmacMagic else { return nil }
    let raw = UInt(ctx.pointee.ctx.0) | (UInt(ctx.pointee.ctx.1) << 32)
    guard let pointer = UnsafeRawPointer(bitPattern: raw) else { return nil }
    let unmanaged = Unmanaged<_CCHmacBox>.fromOpaque(pointer)
    if releasing {
        ctx.pointee.ctx.2 = 0
        return unmanaged.takeRetainedValue()
    }
    return unmanaged.takeUnretainedValue()
}

public func CCHmacInit(
    _ ctx: UnsafeMutablePointer<CCHmacContext>!,
    _ algorithm: CCHmacAlgorithm,
    _ key: UnsafeRawPointer!,
    _ keyLength: Int
) {
    guard let ctx else { return }
    let keyBytes = keyLength == 0 ? [] : _ccCopy(key, keyLength)
    _ccHmacStore(_CCHmacBox(algorithm: algorithm, key: keyBytes), into: ctx)
}

public func CCHmacUpdate(
    _ ctx: UnsafeMutablePointer<CCHmacContext>!,
    _ data: UnsafeRawPointer!,
    _ dataLength: Int
) {
    guard let ctx, let box = _ccHmacLoad(ctx, releasing: false) else { return }
    if dataLength > 0 {
        box.message.append(contentsOf: _ccCopy(data, dataLength))
    }
}

public func CCHmacFinal(
    _ ctx: UnsafeMutablePointer<CCHmacContext>!,
    _ macOut: UnsafeMutableRawPointer!
) {
    guard let ctx, let box = _ccHmacLoad(ctx, releasing: true) else { return }
    let inner = _ccHmacHash(box.algorithm, box.ipad + box.message)
    let digest = _ccHmacHash(box.algorithm, box.opad + inner)
    _ccWrite(digest, to: macOut)
}

public func CCHmac(
    _ algorithm: CCHmacAlgorithm,
    _ key: UnsafeRawPointer!,
    _ keyLength: Int,
    _ data: UnsafeRawPointer!,
    _ dataLength: Int,
    _ macOut: UnsafeMutableRawPointer!
) {
    let keyBytes = keyLength == 0 ? [] : _ccCopy(key, keyLength)
    let message = dataLength == 0 ? [] : _ccCopy(data, dataLength)
    _ccWrite(_ccHMAC(algorithm, key: keyBytes, message: message), to: macOut)
}
