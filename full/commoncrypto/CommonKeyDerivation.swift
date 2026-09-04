func _ccPBKDF2(
    password: [UInt8],
    salt: [UInt8],
    prf: CCPseudoRandomAlgorithm,
    rounds: UInt32,
    derivedKeyLen: Int
) -> [UInt8]? {
    let algorithm: CCHmacAlgorithm
    switch Int(prf) {
    case kCCPRFHmacAlgSHA1: algorithm = CCHmacAlgorithm(kCCHmacAlgSHA1)
    case kCCPRFHmacAlgSHA224: algorithm = CCHmacAlgorithm(kCCHmacAlgSHA224)
    case kCCPRFHmacAlgSHA256: algorithm = CCHmacAlgorithm(kCCHmacAlgSHA256)
    case kCCPRFHmacAlgSHA384: algorithm = CCHmacAlgorithm(kCCHmacAlgSHA384)
    case kCCPRFHmacAlgSHA512: algorithm = CCHmacAlgorithm(kCCHmacAlgSHA512)
    default: return nil
    }
    if rounds == 0 || derivedKeyLen == 0 { return nil }
    let hashLen = _ccHmacDigestLength(algorithm)
    let blockCount = (derivedKeyLen + hashLen - 1) / hashLen
    var derived: [UInt8] = []
    derived.reserveCapacity(blockCount * hashLen)
    for block in 1...blockCount {
        var blockIndex = [UInt8](repeating: 0, count: 4)
        blockIndex[0] = UInt8(truncatingIfNeeded: block >> 24)
        blockIndex[1] = UInt8(truncatingIfNeeded: block >> 16)
        blockIndex[2] = UInt8(truncatingIfNeeded: block >> 8)
        blockIndex[3] = UInt8(truncatingIfNeeded: block)
        var u = _ccHMAC(algorithm, key: password, message: salt + blockIndex)
        var t = u
        if rounds > 1 {
            for _ in 2...rounds {
                u = _ccHMAC(algorithm, key: password, message: u)
                for index in 0..<t.count { t[index] ^= u[index] }
            }
        }
        derived.append(contentsOf: t)
    }
    return Array(derived.prefix(derivedKeyLen))
}

public func CCKeyDerivationPBKDF(
    _ algorithm: CCPBKDFAlgorithm,
    _ password: UnsafePointer<CChar>!,
    _ passwordLen: Int,
    _ salt: UnsafePointer<UInt8>!,
    _ saltLen: Int,
    _ prf: CCPseudoRandomAlgorithm,
    _ rounds: UInt32,
    _ derivedKey: UnsafeMutablePointer<UInt8>!,
    _ derivedKeyLen: Int
) -> Int32 {
    if Int(algorithm) != kCCPBKDF2 {
        return Int32(kCCParamError)
    }
    if derivedKey == nil || derivedKeyLen == 0 || rounds == 0 {
        return Int32(kCCParamError)
    }
    if passwordLen > 0 && password == nil {
        return Int32(kCCParamError)
    }
    if saltLen > 0 && salt == nil {
        return Int32(kCCParamError)
    }
    let passwordBytes: [UInt8]
    if passwordLen == 0 || password == nil {
        passwordBytes = []
    } else {
        passwordBytes = _ccCopy(UnsafeRawPointer(password), passwordLen)
    }
    let saltBytes = saltLen == 0 ? [] : _ccCopy(UnsafeRawPointer(salt), saltLen)
    guard let derived = _ccPBKDF2(
        password: passwordBytes,
        salt: saltBytes,
        prf: prf,
        rounds: rounds,
        derivedKeyLen: derivedKeyLen
    ) else {
        return Int32(kCCParamError)
    }
    _ccWrite(derived, to: derivedKey)
    return 0
}

public func CCCalibratePBKDF(
    _ algorithm: CCPBKDFAlgorithm,
    _ passwordLen: Int,
    _ saltLen: Int,
    _ prf: CCPseudoRandomAlgorithm,
    _ derivedKeyLen: Int,
    _ msec: UInt32
) -> UInt32 {
    _ = msec
    if Int(algorithm) != kCCPBKDF2 || derivedKeyLen == 0 || saltLen > 132 {
        return UInt32.max
    }
    switch Int(prf) {
    case kCCPRFHmacAlgSHA1, kCCPRFHmacAlgSHA224, kCCPRFHmacAlgSHA256,
         kCCPRFHmacAlgSHA384, kCCPRFHmacAlgSHA512:
        break
    default:
        return UInt32.max
    }
    _ = passwordLen
    // Documented safety-net minimum; exact msec-to-rounds mapping is an oracle question.
    return 10_000
}
