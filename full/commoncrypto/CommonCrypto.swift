// Linux starting implementation of Apple's public CommonCrypto module.
// Product sources import Foundation only when a Foundation type is required;
// this file uses the Swift standard library so the isolated host gate can
// compile without an Apple CommonCrypto Clang module.

// MARK: - Integer and status aliases

public typealias CC_LONG = UInt32
public typealias CC_LONG64 = UInt64
public typealias CCAlgorithm = UInt32
public typealias CCCryptorRef = OpaquePointer
public typealias CCCryptorStatus = Int32
public typealias CCHmacAlgorithm = UInt32
public typealias CCMode = UInt32
public typealias CCModeOptions = UInt32
public typealias CCOperation = UInt32
public typealias CCOptions = UInt32
public typealias CCPBKDFAlgorithm = UInt32
public typealias CCPadding = UInt32
public typealias CCPseudoRandomAlgorithm = UInt32
public typealias CCRNGStatus = CCCryptorStatus
public typealias CCStatus = Int32
public typealias CCWrappingAlgorithm = UInt32

// MARK: - Digest / HMAC / cryptor size macros (Apple CommonCrypto headers)

public var CC_DIGEST_DEPRECATION_WARNING: String {
    "This function is cryptographically broken and should not be used in security contexts. Clients should migrate to SHA256 (or stronger)."
}
public var CC_HMAC_CONTEXT_SIZE: Int32 { 96 }
public var CC_MD2_BLOCK_BYTES: Int32 { 64 }
public var CC_MD2_DIGEST_LENGTH: Int32 { 16 }
public var CC_MD4_BLOCK_BYTES: Int32 { 64 }
public var CC_MD4_DIGEST_LENGTH: Int32 { 16 }
public var CC_MD5_BLOCK_BYTES: Int32 { 64 }
public var CC_MD5_DIGEST_LENGTH: Int32 { 16 }
public var CC_SHA1_BLOCK_BYTES: Int32 { 64 }
public var CC_SHA1_DIGEST_LENGTH: Int32 { 20 }
public var CC_SHA224_BLOCK_BYTES: Int32 { 64 }
public var CC_SHA224_DIGEST_LENGTH: Int32 { 28 }
public var CC_SHA256_BLOCK_BYTES: Int32 { 64 }
public var CC_SHA256_DIGEST_LENGTH: Int32 { 32 }
public var CC_SHA384_BLOCK_BYTES: Int32 { 128 }
public var CC_SHA384_DIGEST_LENGTH: Int32 { 48 }
public var CC_SHA512_BLOCK_BYTES: Int32 { 128 }
public var CC_SHA512_DIGEST_LENGTH: Int32 { 64 }

// MARK: - Status / algorithm / mode constants

public var kCCSuccess: Int { 0 }
public var kCCParamError: Int { -4300 }
public var kCCBufferTooSmall: Int { -4301 }
public var kCCMemoryFailure: Int { -4302 }
public var kCCAlignmentError: Int { -4303 }
public var kCCDecodeError: Int { -4304 }
public var kCCUnimplemented: Int { -4305 }
public var kCCOverflow: Int { -4306 }
public var kCCRNGFailure: Int { -4307 }
public var kCCUnspecifiedError: Int { -4308 }
public var kCCCallSequenceError: Int { -4309 }
public var kCCKeySizeError: Int { -4310 }
public var kCCInvalidKey: Int { -4311 }

public var kCCEncrypt: Int { 0 }
public var kCCDecrypt: Int { 1 }

public var kCCAlgorithmAES128: Int { 0 }
public var kCCAlgorithmAES: Int { 0 }
public var kCCAlgorithmDES: Int { 1 }
public var kCCAlgorithm3DES: Int { 2 }
public var kCCAlgorithmCAST: Int { 3 }
public var kCCAlgorithmRC4: Int { 4 }
public var kCCAlgorithmRC2: Int { 5 }
public var kCCAlgorithmBlowfish: Int { 6 }

public var kCCOptionPKCS7Padding: Int { 0x0001 }
public var kCCOptionECBMode: Int { 0x0002 }

public var kCCKeySizeAES128: Int { 16 }
public var kCCKeySizeAES192: Int { 24 }
public var kCCKeySizeAES256: Int { 32 }
public var kCCKeySizeDES: Int { 8 }
public var kCCKeySize3DES: Int { 24 }
public var kCCKeySizeMinCAST: Int { 5 }
public var kCCKeySizeMaxCAST: Int { 16 }
public var kCCKeySizeMinRC4: Int { 1 }
public var kCCKeySizeMaxRC4: Int { 512 }
public var kCCKeySizeMinRC2: Int { 1 }
public var kCCKeySizeMaxRC2: Int { 128 }
public var kCCKeySizeMinBlowfish: Int { 8 }
public var kCCKeySizeMaxBlowfish: Int { 56 }

public var kCCBlockSizeAES128: Int { 16 }
public var kCCBlockSizeDES: Int { 8 }
public var kCCBlockSize3DES: Int { 8 }
public var kCCBlockSizeCAST: Int { 8 }
public var kCCBlockSizeRC2: Int { 8 }
public var kCCBlockSizeBlowfish: Int { 8 }

public var kCCModeECB: Int { 1 }
public var kCCModeCBC: Int { 2 }
public var kCCModeCFB: Int { 3 }
public var kCCModeCTR: Int { 4 }
public var kCCModeOFB: Int { 7 }
public var kCCModeRC4: Int { 9 }
public var kCCModeCFB8: Int { 10 }

public var ccNoPadding: Int { 0 }
public var ccPKCS7Padding: Int { 1 }

public var kCCModeOptionCTR_BE: Int { 2 }

public var kCCHmacAlgSHA1: Int { 0 }
public var kCCHmacAlgMD5: Int { 1 }
public var kCCHmacAlgSHA256: Int { 2 }
public var kCCHmacAlgSHA384: Int { 3 }
public var kCCHmacAlgSHA512: Int { 4 }
public var kCCHmacAlgSHA224: Int { 5 }

public var kCCPBKDF2: Int { 2 }
public var kCCPRFHmacAlgSHA1: Int { 1 }
public var kCCPRFHmacAlgSHA224: Int { 2 }
public var kCCPRFHmacAlgSHA256: Int { 3 }
public var kCCPRFHmacAlgSHA384: Int { 4 }
public var kCCPRFHmacAlgSHA512: Int { 5 }

public var kCCWRAPAES: Int { 1 }

// RFC 3394 default IV 0xA6A6A6A6A6A6A6A6 (8 bytes).
private let _ccRfc3394IVStorage: [UInt8] = [0xA6, 0xA6, 0xA6, 0xA6, 0xA6, 0xA6, 0xA6, 0xA6]
public let CCrfc3394_iv: UnsafePointer<UInt8>! = {
    let pointer = UnsafeMutablePointer<UInt8>.allocate(capacity: 8)
    for index in 0..<8 {
        pointer[index] = _ccRfc3394IVStorage[index]
    }
    return UnsafePointer(pointer)
}()
public let CCrfc3394_ivLen: Int = 8

// MARK: - Digest / HMAC context structs

public struct CC_MD2state_st {
    public var num: Int32
    public var data: (UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8)
    public var cksm: (CC_LONG, CC_LONG, CC_LONG, CC_LONG, CC_LONG, CC_LONG, CC_LONG, CC_LONG, CC_LONG, CC_LONG, CC_LONG, CC_LONG, CC_LONG, CC_LONG, CC_LONG, CC_LONG)
    public var state: (CC_LONG, CC_LONG, CC_LONG, CC_LONG, CC_LONG, CC_LONG, CC_LONG, CC_LONG, CC_LONG, CC_LONG, CC_LONG, CC_LONG, CC_LONG, CC_LONG, CC_LONG, CC_LONG)

    public init() {
        self.num = 0
        self.data = (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
        self.cksm = (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
        self.state = (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
    }

    public init(num: Int32, data: (UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8), cksm: (CC_LONG, CC_LONG, CC_LONG, CC_LONG, CC_LONG, CC_LONG, CC_LONG, CC_LONG, CC_LONG, CC_LONG, CC_LONG, CC_LONG, CC_LONG, CC_LONG, CC_LONG, CC_LONG), state: (CC_LONG, CC_LONG, CC_LONG, CC_LONG, CC_LONG, CC_LONG, CC_LONG, CC_LONG, CC_LONG, CC_LONG, CC_LONG, CC_LONG, CC_LONG, CC_LONG, CC_LONG, CC_LONG)) {
        self.num = num
        self.data = data
        self.cksm = cksm
        self.state = state
    }
}
public typealias CC_MD2_CTX = CC_MD2state_st

public struct CC_MD4state_st {
    public var A: CC_LONG
    public var B: CC_LONG
    public var C: CC_LONG
    public var D: CC_LONG
    public var Nl: CC_LONG
    public var Nh: CC_LONG
    public var data: (CC_LONG, CC_LONG, CC_LONG, CC_LONG, CC_LONG, CC_LONG, CC_LONG, CC_LONG, CC_LONG, CC_LONG, CC_LONG, CC_LONG, CC_LONG, CC_LONG, CC_LONG, CC_LONG)
    public var num: UInt32

    public init() {
        self.A = 0; self.B = 0; self.C = 0; self.D = 0
        self.Nl = 0; self.Nh = 0
        self.data = (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
        self.num = 0
    }

    public init(A: CC_LONG, B: CC_LONG, C: CC_LONG, D: CC_LONG, Nl: CC_LONG, Nh: CC_LONG, data: (CC_LONG, CC_LONG, CC_LONG, CC_LONG, CC_LONG, CC_LONG, CC_LONG, CC_LONG, CC_LONG, CC_LONG, CC_LONG, CC_LONG, CC_LONG, CC_LONG, CC_LONG, CC_LONG), num: UInt32) {
        self.A = A; self.B = B; self.C = C; self.D = D
        self.Nl = Nl; self.Nh = Nh
        self.data = data
        self.num = num
    }
}
public typealias CC_MD4_CTX = CC_MD4state_st

public struct CC_MD5state_st {
    public var A: CC_LONG
    public var B: CC_LONG
    public var C: CC_LONG
    public var D: CC_LONG
    public var Nl: CC_LONG
    public var Nh: CC_LONG
    public var data: (CC_LONG, CC_LONG, CC_LONG, CC_LONG, CC_LONG, CC_LONG, CC_LONG, CC_LONG, CC_LONG, CC_LONG, CC_LONG, CC_LONG, CC_LONG, CC_LONG, CC_LONG, CC_LONG)
    public var num: Int32

    public init() {
        self.A = 0; self.B = 0; self.C = 0; self.D = 0
        self.Nl = 0; self.Nh = 0
        self.data = (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
        self.num = 0
    }

    public init(A: CC_LONG, B: CC_LONG, C: CC_LONG, D: CC_LONG, Nl: CC_LONG, Nh: CC_LONG, data: (CC_LONG, CC_LONG, CC_LONG, CC_LONG, CC_LONG, CC_LONG, CC_LONG, CC_LONG, CC_LONG, CC_LONG, CC_LONG, CC_LONG, CC_LONG, CC_LONG, CC_LONG, CC_LONG), num: Int32) {
        self.A = A; self.B = B; self.C = C; self.D = D
        self.Nl = Nl; self.Nh = Nh
        self.data = data
        self.num = num
    }
}
public typealias CC_MD5_CTX = CC_MD5state_st

public struct CC_SHA1state_st {
    public var h0: CC_LONG
    public var h1: CC_LONG
    public var h2: CC_LONG
    public var h3: CC_LONG
    public var h4: CC_LONG
    public var Nl: CC_LONG
    public var Nh: CC_LONG
    public var data: (CC_LONG, CC_LONG, CC_LONG, CC_LONG, CC_LONG, CC_LONG, CC_LONG, CC_LONG, CC_LONG, CC_LONG, CC_LONG, CC_LONG, CC_LONG, CC_LONG, CC_LONG, CC_LONG)
    public var num: Int32

    public init() {
        self.h0 = 0; self.h1 = 0; self.h2 = 0; self.h3 = 0; self.h4 = 0
        self.Nl = 0; self.Nh = 0
        self.data = (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
        self.num = 0
    }

    public init(h0: CC_LONG, h1: CC_LONG, h2: CC_LONG, h3: CC_LONG, h4: CC_LONG, Nl: CC_LONG, Nh: CC_LONG, data: (CC_LONG, CC_LONG, CC_LONG, CC_LONG, CC_LONG, CC_LONG, CC_LONG, CC_LONG, CC_LONG, CC_LONG, CC_LONG, CC_LONG, CC_LONG, CC_LONG, CC_LONG, CC_LONG), num: Int32) {
        self.h0 = h0; self.h1 = h1; self.h2 = h2; self.h3 = h3; self.h4 = h4
        self.Nl = Nl; self.Nh = Nh
        self.data = data
        self.num = num
    }
}
public typealias CC_SHA1_CTX = CC_SHA1state_st

public struct CC_SHA256state_st {
    public var count: (CC_LONG, CC_LONG)
    public var hash: (CC_LONG, CC_LONG, CC_LONG, CC_LONG, CC_LONG, CC_LONG, CC_LONG, CC_LONG)
    public var wbuf: (CC_LONG, CC_LONG, CC_LONG, CC_LONG, CC_LONG, CC_LONG, CC_LONG, CC_LONG, CC_LONG, CC_LONG, CC_LONG, CC_LONG, CC_LONG, CC_LONG, CC_LONG, CC_LONG)

    public init() {
        self.count = (0, 0)
        self.hash = (0, 0, 0, 0, 0, 0, 0, 0)
        self.wbuf = (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
    }

    public init(count: (CC_LONG, CC_LONG), hash: (CC_LONG, CC_LONG, CC_LONG, CC_LONG, CC_LONG, CC_LONG, CC_LONG, CC_LONG), wbuf: (CC_LONG, CC_LONG, CC_LONG, CC_LONG, CC_LONG, CC_LONG, CC_LONG, CC_LONG, CC_LONG, CC_LONG, CC_LONG, CC_LONG, CC_LONG, CC_LONG, CC_LONG, CC_LONG)) {
        self.count = count
        self.hash = hash
        self.wbuf = wbuf
    }
}
public typealias CC_SHA256_CTX = CC_SHA256state_st

public struct CC_SHA512state_st {
    public var count: (CC_LONG64, CC_LONG64)
    public var hash: (CC_LONG64, CC_LONG64, CC_LONG64, CC_LONG64, CC_LONG64, CC_LONG64, CC_LONG64, CC_LONG64)
    public var wbuf: (CC_LONG64, CC_LONG64, CC_LONG64, CC_LONG64, CC_LONG64, CC_LONG64, CC_LONG64, CC_LONG64, CC_LONG64, CC_LONG64, CC_LONG64, CC_LONG64, CC_LONG64, CC_LONG64, CC_LONG64, CC_LONG64)

    public init() {
        self.count = (0, 0)
        self.hash = (0, 0, 0, 0, 0, 0, 0, 0)
        self.wbuf = (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
    }

    public init(count: (CC_LONG64, CC_LONG64), hash: (CC_LONG64, CC_LONG64, CC_LONG64, CC_LONG64, CC_LONG64, CC_LONG64, CC_LONG64, CC_LONG64), wbuf: (CC_LONG64, CC_LONG64, CC_LONG64, CC_LONG64, CC_LONG64, CC_LONG64, CC_LONG64, CC_LONG64, CC_LONG64, CC_LONG64, CC_LONG64, CC_LONG64, CC_LONG64, CC_LONG64, CC_LONG64, CC_LONG64)) {
        self.count = count
        self.hash = hash
        self.wbuf = wbuf
    }
}
public typealias CC_SHA512_CTX = CC_SHA512state_st

public struct CCHmacContext {
    public var ctx: (UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32)

    public init() {
        self.ctx = (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
    }

    public init(ctx: (UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32)) {
        self.ctx = ctx
    }
}

// MARK: - Internal helpers

func _ccCopy(_ source: UnsafeRawPointer?, _ count: Int) -> [UInt8] {
    guard count > 0 else { return [] }
    guard let source else { return [] }
    let buffer = UnsafeRawBufferPointer(start: source, count: count)
    return Array(buffer)
}

func _ccWrite(_ bytes: [UInt8], to dest: UnsafeMutableRawPointer?) {
    guard let dest, !bytes.isEmpty else { return }
    bytes.withUnsafeBytes { source in
        dest.copyMemory(from: source.baseAddress!, byteCount: bytes.count)
    }
}

func _ccHex(_ bytes: [UInt8]) -> String {
    let digits: [Character] = [
        "0", "1", "2", "3", "4", "5", "6", "7",
        "8", "9", "a", "b", "c", "d", "e", "f",
    ]
    var result = ""
    result.reserveCapacity(bytes.count * 2)
    for byte in bytes {
        result.append(digits[Int(byte >> 4)])
        result.append(digits[Int(byte & 0x0f)])
    }
    return result
}

func _ccU32x16(_ value: (UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32)) -> [UInt32] {
    [value.0, value.1, value.2, value.3, value.4, value.5, value.6, value.7, value.8, value.9, value.10, value.11, value.12, value.13, value.14, value.15]
}

func _ccMakeU32x16(_ values: [UInt32]) -> (UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32) {
    precondition(values.count >= 16)
    return (UInt32(values[0]), UInt32(values[1]), UInt32(values[2]), UInt32(values[3]), UInt32(values[4]), UInt32(values[5]), UInt32(values[6]), UInt32(values[7]), UInt32(values[8]), UInt32(values[9]), UInt32(values[10]), UInt32(values[11]), UInt32(values[12]), UInt32(values[13]), UInt32(values[14]), UInt32(values[15]))
}

func _ccU8x16(_ value: (UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8)) -> [UInt8] {
    [value.0, value.1, value.2, value.3, value.4, value.5, value.6, value.7, value.8, value.9, value.10, value.11, value.12, value.13, value.14, value.15]
}

func _ccMakeU8x16(_ values: [UInt8]) -> (UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8) {
    precondition(values.count >= 16)
    return (UInt8(values[0]), UInt8(values[1]), UInt8(values[2]), UInt8(values[3]), UInt8(values[4]), UInt8(values[5]), UInt8(values[6]), UInt8(values[7]), UInt8(values[8]), UInt8(values[9]), UInt8(values[10]), UInt8(values[11]), UInt8(values[12]), UInt8(values[13]), UInt8(values[14]), UInt8(values[15]))
}

func _ccU32x8(_ value: (UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32)) -> [UInt32] {
    [value.0, value.1, value.2, value.3, value.4, value.5, value.6, value.7]
}

func _ccMakeU32x8(_ values: [UInt32]) -> (UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32) {
    precondition(values.count >= 8)
    return (UInt32(values[0]), UInt32(values[1]), UInt32(values[2]), UInt32(values[3]), UInt32(values[4]), UInt32(values[5]), UInt32(values[6]), UInt32(values[7]))
}

func _ccU32x2(_ value: (UInt32, UInt32)) -> [UInt32] {
    [value.0, value.1]
}

func _ccMakeU32x2(_ values: [UInt32]) -> (UInt32, UInt32) {
    precondition(values.count >= 2)
    return (UInt32(values[0]), UInt32(values[1]))
}

func _ccU64x2(_ value: (UInt64, UInt64)) -> [UInt64] {
    [value.0, value.1]
}

func _ccMakeU64x2(_ values: [UInt64]) -> (UInt64, UInt64) {
    precondition(values.count >= 2)
    return (UInt64(values[0]), UInt64(values[1]))
}

func _ccU64x8(_ value: (UInt64, UInt64, UInt64, UInt64, UInt64, UInt64, UInt64, UInt64)) -> [UInt64] {
    [value.0, value.1, value.2, value.3, value.4, value.5, value.6, value.7]
}

func _ccMakeU64x8(_ values: [UInt64]) -> (UInt64, UInt64, UInt64, UInt64, UInt64, UInt64, UInt64, UInt64) {
    precondition(values.count >= 8)
    return (UInt64(values[0]), UInt64(values[1]), UInt64(values[2]), UInt64(values[3]), UInt64(values[4]), UInt64(values[5]), UInt64(values[6]), UInt64(values[7]))
}

func _ccU64x16(_ value: (UInt64, UInt64, UInt64, UInt64, UInt64, UInt64, UInt64, UInt64, UInt64, UInt64, UInt64, UInt64, UInt64, UInt64, UInt64, UInt64)) -> [UInt64] {
    [value.0, value.1, value.2, value.3, value.4, value.5, value.6, value.7, value.8, value.9, value.10, value.11, value.12, value.13, value.14, value.15]
}

func _ccMakeU64x16(_ values: [UInt64]) -> (UInt64, UInt64, UInt64, UInt64, UInt64, UInt64, UInt64, UInt64, UInt64, UInt64, UInt64, UInt64, UInt64, UInt64, UInt64, UInt64) {
    precondition(values.count >= 16)
    return (UInt64(values[0]), UInt64(values[1]), UInt64(values[2]), UInt64(values[3]), UInt64(values[4]), UInt64(values[5]), UInt64(values[6]), UInt64(values[7]), UInt64(values[8]), UInt64(values[9]), UInt64(values[10]), UInt64(values[11]), UInt64(values[12]), UInt64(values[13]), UInt64(values[14]), UInt64(values[15]))
}

extension UInt32 {
    func _ccRotL(_ amount: UInt32) -> UInt32 {
        (self << amount) | (self >> (32 - amount))
    }
    func _ccRotR(_ amount: UInt32) -> UInt32 {
        (self >> amount) | (self << (32 - amount))
    }
}

extension UInt64 {
    func _ccRotR(_ amount: UInt64) -> UInt64 {
        (self >> amount) | (self << (64 - amount))
    }
}

