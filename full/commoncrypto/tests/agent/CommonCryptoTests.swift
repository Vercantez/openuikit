import CommonCrypto

private func ccHex(_ bytes: [UInt8]) -> String {
    let digits: [Character] = [
        "0", "1", "2", "3", "4", "5", "6", "7",
        "8", "9", "a", "b", "c", "d", "e", "f",
    ]
    var result = ""
    for byte in bytes {
        result.append(digits[Int(byte >> 4)])
        result.append(digits[Int(byte & 0x0f)])
    }
    return result
}

private func ccBytes(_ hex: String) -> [UInt8] {
    var bytes: [UInt8] = []
    var remaining = hex
    while remaining.count >= 2 {
        let pair = String(remaining.prefix(2))
        remaining.removeFirst(2)
        bytes.append(UInt8(pair, radix: 16)!)
    }
    return bytes
}

private func ccDigest(
    length: Int,
    _ body: (UnsafeMutablePointer<UInt8>) -> UnsafeMutablePointer<UInt8>?
) -> [UInt8] {
    var digest = [UInt8](repeating: 0, count: length)
    let returned = digest.withUnsafeMutableBufferPointer { buffer in
        body(buffer.baseAddress!)
    }
    precondition(returned != nil)
    return digest
}

func testDigestMacros() {
    precondition(CC_MD2_DIGEST_LENGTH == 16)
    precondition(CC_MD2_BLOCK_BYTES == 64)
    precondition(CC_MD4_DIGEST_LENGTH == 16)
    precondition(CC_MD4_BLOCK_BYTES == 64)
    precondition(CC_MD5_DIGEST_LENGTH == 16)
    precondition(CC_MD5_BLOCK_BYTES == 64)
    precondition(CC_SHA1_DIGEST_LENGTH == 20)
    precondition(CC_SHA1_BLOCK_BYTES == 64)
    precondition(CC_SHA224_DIGEST_LENGTH == 28)
    precondition(CC_SHA224_BLOCK_BYTES == 64)
    precondition(CC_SHA256_DIGEST_LENGTH == 32)
    precondition(CC_SHA256_BLOCK_BYTES == 64)
    precondition(CC_SHA384_DIGEST_LENGTH == 48)
    precondition(CC_SHA384_BLOCK_BYTES == 128)
    precondition(CC_SHA512_DIGEST_LENGTH == 64)
    precondition(CC_SHA512_BLOCK_BYTES == 128)
    precondition(CC_HMAC_CONTEXT_SIZE == 96)
    precondition(CC_DIGEST_DEPRECATION_WARNING.contains("SHA256"))
}

func testStatusConstants() {
    precondition(kCCSuccess == 0)
    precondition(kCCParamError == -4300)
    precondition(kCCBufferTooSmall == -4301)
    precondition(kCCMemoryFailure == -4302)
    precondition(kCCAlignmentError == -4303)
    precondition(kCCDecodeError == -4304)
    precondition(kCCUnimplemented == -4305)
    precondition(kCCOverflow == -4306)
    precondition(kCCRNGFailure == -4307)
    precondition(kCCUnspecifiedError == -4308)
    precondition(kCCCallSequenceError == -4309)
    precondition(kCCKeySizeError == -4310)
    precondition(kCCInvalidKey == -4311)
}

func testAlgorithmConstants() {
    precondition(kCCEncrypt == 0)
    precondition(kCCDecrypt == 1)
    precondition(kCCAlgorithmAES128 == 0)
    precondition(kCCAlgorithmAES == 0)
    precondition(kCCAlgorithmDES == 1)
    precondition(kCCAlgorithm3DES == 2)
    precondition(kCCAlgorithmCAST == 3)
    precondition(kCCAlgorithmRC4 == 4)
    precondition(kCCAlgorithmRC2 == 5)
    precondition(kCCAlgorithmBlowfish == 6)
    precondition(kCCOptionPKCS7Padding == 1)
    precondition(kCCOptionECBMode == 2)
    precondition(kCCModeECB == 1)
    precondition(kCCModeCBC == 2)
    precondition(kCCModeCFB == 3)
    precondition(kCCModeCTR == 4)
    precondition(kCCModeOFB == 7)
    precondition(kCCModeRC4 == 9)
    precondition(kCCModeCFB8 == 10)
    precondition(ccNoPadding == 0)
    precondition(ccPKCS7Padding == 1)
    precondition(kCCModeOptionCTR_BE == 2)
}

func testKeyAndBlockSizes() {
    precondition(kCCKeySizeAES128 == 16)
    precondition(kCCKeySizeAES192 == 24)
    precondition(kCCKeySizeAES256 == 32)
    precondition(kCCKeySizeDES == 8)
    precondition(kCCKeySize3DES == 24)
    precondition(kCCKeySizeMinCAST == 5)
    precondition(kCCKeySizeMaxCAST == 16)
    precondition(kCCKeySizeMinRC4 == 1)
    precondition(kCCKeySizeMaxRC4 == 512)
    precondition(kCCKeySizeMinRC2 == 1)
    precondition(kCCKeySizeMaxRC2 == 128)
    precondition(kCCKeySizeMinBlowfish == 8)
    precondition(kCCKeySizeMaxBlowfish == 56)
    precondition(kCCBlockSizeAES128 == 16)
    precondition(kCCBlockSizeDES == 8)
    precondition(kCCBlockSize3DES == 8)
    precondition(kCCBlockSizeCAST == 8)
    precondition(kCCBlockSizeRC2 == 8)
    precondition(kCCBlockSizeBlowfish == 8)
}

func testHmacAndWrapConstants() {
    precondition(kCCHmacAlgSHA1 == 0)
    precondition(kCCHmacAlgMD5 == 1)
    precondition(kCCHmacAlgSHA256 == 2)
    precondition(kCCHmacAlgSHA384 == 3)
    precondition(kCCHmacAlgSHA512 == 4)
    precondition(kCCHmacAlgSHA224 == 5)
    precondition(kCCPBKDF2 == 2)
    precondition(kCCPRFHmacAlgSHA1 == 1)
    precondition(kCCPRFHmacAlgSHA224 == 2)
    precondition(kCCPRFHmacAlgSHA256 == 3)
    precondition(kCCPRFHmacAlgSHA384 == 4)
    precondition(kCCPRFHmacAlgSHA512 == 5)
    precondition(kCCWRAPAES == 1)
    precondition(CCrfc3394_ivLen == 8)
    precondition(CCrfc3394_iv[0] == 0xA6)
    precondition(CCrfc3394_iv[7] == 0xA6)
}

func testSHA256Vectors() {
    let empty = ccDigest(length: Int(CC_SHA256_DIGEST_LENGTH)) { md in
        CC_SHA256(nil, 0, md)
    }
    precondition(ccHex(empty) == "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855")
    let abc = Array("abc".utf8)
    let oneShot = abc.withUnsafeBytes { raw in
        ccDigest(length: Int(CC_SHA256_DIGEST_LENGTH)) { md in
            CC_SHA256(raw.baseAddress!, CC_LONG(abc.count), md)
        }
    }
    precondition(ccHex(oneShot) == "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad")

    var context = CC_SHA256_CTX()
    precondition(context.hash.0 == 0)
    precondition(CC_SHA256_Init(&context) == 1)
    precondition(context.hash.0 == 0x6a09e667)
    precondition(context.hash.7 == 0x5be0cd19)
    abc.withUnsafeBytes { raw in
        precondition(CC_SHA256_Update(&context, raw.baseAddress!, 1) == 1)
        precondition(CC_SHA256_Update(&context, raw.baseAddress!.advanced(by: 1), 2) == 1)
    }
    var streaming = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
    precondition(CC_SHA256_Final(&streaming, &context) == 1)
    precondition(ccHex(streaming) == ccHex(oneShot))

    let boundary = [UInt8](repeating: 0x61, count: 65)
    var boundaryContext = CC_SHA256_CTX()
    precondition(CC_SHA256_Init(&boundaryContext) == 1)
    boundary.withUnsafeBytes { raw in
        precondition(CC_SHA256_Update(&boundaryContext, raw.baseAddress!, 55) == 1)
        precondition(CC_SHA256_Update(&boundaryContext, raw.baseAddress!.advanced(by: 55), 10) == 1)
    }
    var boundaryDigest = [UInt8](repeating: 0, count: 32)
    precondition(CC_SHA256_Final(&boundaryDigest, &boundaryContext) == 1)
    precondition(ccHex(boundaryDigest) == "635361c48bb9eab14198e76ea8ab7f1a41685d6ad62aa9146d301d4f17eb0ae0")
}

func testSHA1AndSHA2Family() {
    let abc = Array("abc".utf8)
    let sha1 = abc.withUnsafeBytes { raw in
        ccDigest(length: Int(CC_SHA1_DIGEST_LENGTH)) { md in
            CC_SHA1(raw.baseAddress!, 3, md)
        }
    }
    precondition(ccHex(sha1) == "a9993e364706816aba3e25717850c26c9cd0d89d")

    var sha1ctx = CC_SHA1_CTX()
    precondition(CC_SHA1_Init(&sha1ctx) == 1)
    precondition(sha1ctx.h0 == 0x67452301)
    abc.withUnsafeBytes { raw in
        precondition(CC_SHA1_Update(&sha1ctx, raw.baseAddress!, 3) == 1)
    }
    var sha1out = [UInt8](repeating: 0, count: 20)
    precondition(CC_SHA1_Final(&sha1out, &sha1ctx) == 1)
    precondition(ccHex(sha1out) == ccHex(sha1))

    let sha224 = abc.withUnsafeBytes { raw in
        ccDigest(length: Int(CC_SHA224_DIGEST_LENGTH)) { md in
            CC_SHA224(raw.baseAddress!, 3, md)
        }
    }
    precondition(ccHex(sha224) == "23097d223405d8228642a477bda255b32aadbce4bda0b3f7e36c9da7")
    var sha224ctx = CC_SHA256_CTX()
    precondition(CC_SHA224_Init(&sha224ctx) == 1)
    abc.withUnsafeBytes { raw in
        precondition(CC_SHA224_Update(&sha224ctx, raw.baseAddress!, 3) == 1)
    }
    var sha224out = [UInt8](repeating: 0, count: 28)
    precondition(CC_SHA224_Final(&sha224out, &sha224ctx) == 1)
    precondition(ccHex(sha224out) == ccHex(sha224))

    let sha384 = abc.withUnsafeBytes { raw in
        ccDigest(length: Int(CC_SHA384_DIGEST_LENGTH)) { md in
            CC_SHA384(raw.baseAddress!, 3, md)
        }
    }
    precondition(
        ccHex(sha384)
            == "cb00753f45a35e8bb5a03d699ac65007272c32ab0eded1631a8b605a43ff5bed"
            + "8086072ba1e7cc2358baeca134c825a7"
    )
    var sha384ctx = CC_SHA512_CTX()
    precondition(CC_SHA384_Init(&sha384ctx) == 1)
    abc.withUnsafeBytes { raw in
        precondition(CC_SHA384_Update(&sha384ctx, raw.baseAddress!, 3) == 1)
    }
    var sha384out = [UInt8](repeating: 0, count: 48)
    precondition(CC_SHA384_Final(&sha384out, &sha384ctx) == 1)
    precondition(ccHex(sha384out) == ccHex(sha384))

    let sha512 = abc.withUnsafeBytes { raw in
        ccDigest(length: Int(CC_SHA512_DIGEST_LENGTH)) { md in
            CC_SHA512(raw.baseAddress!, 3, md)
        }
    }
    precondition(
        ccHex(sha512)
            == "ddaf35a193617abacc417349ae20413112e6fa4e89a97ea20a9eeee64b55d39a"
            + "2192992a274fc1a836ba3c23a3feebbd454d4423643ce80e2a9ac94fa54ca49f"
    )
    var sha512ctx = CC_SHA512_CTX()
    precondition(CC_SHA512_Init(&sha512ctx) == 1)
    abc.withUnsafeBytes { raw in
        precondition(CC_SHA512_Update(&sha512ctx, raw.baseAddress!, 3) == 1)
    }
    var sha512out = [UInt8](repeating: 0, count: 64)
    precondition(CC_SHA512_Final(&sha512out, &sha512ctx) == 1)
    precondition(ccHex(sha512out) == ccHex(sha512))
}

func testMDFamily() {
    let abc = Array("abc".utf8)
    let md5 = abc.withUnsafeBytes { raw in
        ccDigest(length: Int(CC_MD5_DIGEST_LENGTH)) { md in
            CC_MD5(raw.baseAddress!, 3, md)
        }
    }
    precondition(ccHex(md5) == "900150983cd24fb0d6963f7d28e17f72")
    var md5ctx = CC_MD5_CTX()
    precondition(CC_MD5_Init(&md5ctx) == 1)
    precondition(md5ctx.A == 0x67452301)
    abc.withUnsafeBytes { raw in
        precondition(CC_MD5_Update(&md5ctx, raw.baseAddress!, 3) == 1)
    }
    var md5out = [UInt8](repeating: 0, count: 16)
    precondition(CC_MD5_Final(&md5out, &md5ctx) == 1)
    precondition(ccHex(md5out) == ccHex(md5))

    let md4 = abc.withUnsafeBytes { raw in
        ccDigest(length: Int(CC_MD4_DIGEST_LENGTH)) { md in
            CC_MD4(raw.baseAddress!, 3, md)
        }
    }
    precondition(ccHex(md4) == "a448017aaf21d8525fc10ae87aa6729d")
    var md4ctx = CC_MD4_CTX()
    precondition(CC_MD4_Init(&md4ctx) == 1)
    abc.withUnsafeBytes { raw in
        precondition(CC_MD4_Update(&md4ctx, raw.baseAddress!, 3) == 1)
    }
    var md4out = [UInt8](repeating: 0, count: 16)
    precondition(CC_MD4_Final(&md4out, &md4ctx) == 1)
    precondition(ccHex(md4out) == ccHex(md4))

    let md2 = abc.withUnsafeBytes { raw in
        ccDigest(length: Int(CC_MD2_DIGEST_LENGTH)) { md in
            CC_MD2(raw.baseAddress!, 3, md)
        }
    }
    precondition(ccHex(md2) == "da853b0d3f88d99b30283a69e6ded6bb")
    var md2ctx = CC_MD2_CTX()
    precondition(CC_MD2_Init(&md2ctx) == 1)
    abc.withUnsafeBytes { raw in
        precondition(CC_MD2_Update(&md2ctx, raw.baseAddress!, 3) == 1)
    }
    var md2out = [UInt8](repeating: 0, count: 16)
    precondition(CC_MD2_Final(&md2out, &md2ctx) == 1)
    precondition(ccHex(md2out) == ccHex(md2))
}

func testContextInits() {
    let md2 = CC_MD2state_st()
    precondition(md2.num == 0)
    let md2b = CC_MD2state_st(
        num: 1,
        data: md2.data,
        cksm: md2.cksm,
        state: md2.state
    )
    precondition(md2b.num == 1)
    let md4 = CC_MD4state_st(A: 1, B: 2, C: 3, D: 4, Nl: 5, Nh: 6, data: CC_MD4state_st().data, num: 7)
    precondition(md4.A == 1 && md4.num == 7)
    let md5 = CC_MD5state_st(A: 1, B: 2, C: 3, D: 4, Nl: 5, Nh: 6, data: CC_MD5state_st().data, num: 8)
    precondition(md5.D == 4 && md5.num == 8)
    let sha1 = CC_SHA1state_st(
        h0: 1, h1: 2, h2: 3, h3: 4, h4: 5, Nl: 6, Nh: 7, data: CC_SHA1state_st().data, num: 9
    )
    precondition(sha1.h4 == 5 && sha1.num == 9)
    let sha256 = CC_SHA256state_st(
        count: CC_SHA256state_st().count,
        hash: CC_SHA256state_st().hash,
        wbuf: CC_SHA256state_st().wbuf
    )
    precondition(sha256.count.0 == 0)
    let sha512 = CC_SHA512state_st(
        count: CC_SHA512state_st().count,
        hash: CC_SHA512state_st().hash,
        wbuf: CC_SHA512state_st().wbuf
    )
    precondition(sha512.hash.0 == 0)
    var hmac = CCHmacContext()
    precondition(hmac.ctx.0 == 0)
    hmac = CCHmacContext(ctx: hmac.ctx)
    precondition(hmac.ctx.95 == 0)
    let _: CCAlgorithm = 0
    let _: CCCryptorRef? = nil
    let _: CCCryptorStatus = 0
    let _: CCHmacAlgorithm = 0
    let _: CCMode = 0
    let _: CCModeOptions = 0
    let _: CCOperation = 0
    let _: CCOptions = 0
    let _: CCPBKDFAlgorithm = 0
    let _: CCPadding = 0
    let _: CCPseudoRandomAlgorithm = 0
    let _: CCRNGStatus = 0
    let _: CCStatus = 0
    let _: CCWrappingAlgorithm = 0
    let _: CC_LONG = 0
    let _: CC_LONG64 = 0
    let _: CC_MD2_CTX = CC_MD2_CTX()
    let _: CC_MD4_CTX = CC_MD4_CTX()
    let _: CC_MD5_CTX = CC_MD5_CTX()
    let _: CC_SHA1_CTX = CC_SHA1_CTX()
    let _: CC_SHA256_CTX = CC_SHA256_CTX()
    let _: CC_SHA512_CTX = CC_SHA512_CTX()
}

func testHMACSHA256RFC4231() {
    let key = [UInt8](repeating: 0x0b, count: 20)
    let data = Array("Hi There".utf8)
    var mac = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
    key.withUnsafeBytes { keyRaw in
        data.withUnsafeBytes { dataRaw in
            CCHmac(
                CCHmacAlgorithm(kCCHmacAlgSHA256),
                keyRaw.baseAddress!,
                key.count,
                dataRaw.baseAddress!,
                data.count,
                &mac
            )
        }
    }
    precondition(ccHex(mac) == "b0344c61d8db38535ca8afceaf0bf12b881dc200c9833da726e9376c2e32cff7")

    var ctx = CCHmacContext()
    key.withUnsafeBytes { keyRaw in
        CCHmacInit(&ctx, CCHmacAlgorithm(kCCHmacAlgSHA256), keyRaw.baseAddress!, key.count)
    }
    data.withUnsafeBytes { dataRaw in
        CCHmacUpdate(&ctx, dataRaw.baseAddress!, 3)
        CCHmacUpdate(&ctx, dataRaw.baseAddress!.advanced(by: 3), data.count - 3)
    }
    var streamed = [UInt8](repeating: 0, count: 32)
    CCHmacFinal(&ctx, &streamed)
    precondition(ccHex(streamed) == ccHex(mac))
}

func testPBKDF2RFC6070() {
    let password = Array("password".utf8)
    let salt = Array("salt".utf8)
    var derived = [UInt8](repeating: 0, count: 20)
    let status = password.withUnsafeBytes { passwordRaw in
        salt.withUnsafeBytes { saltRaw in
            CCKeyDerivationPBKDF(
                CCPBKDFAlgorithm(kCCPBKDF2),
                passwordRaw.bindMemory(to: CChar.self).baseAddress!,
                password.count,
                saltRaw.bindMemory(to: UInt8.self).baseAddress!,
                salt.count,
                CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA1),
                1,
                &derived,
                derived.count
            )
        }
    }
    precondition(status == 0)
    precondition(ccHex(derived) == "0c60c80f961f0e71f3a9b524af6012062fe037a6")
    let rounds = CCCalibratePBKDF(
        CCPBKDFAlgorithm(kCCPBKDF2),
        password.count,
        salt.count,
        CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA256),
        32,
        100
    )
    precondition(rounds >= 10_000)
    precondition(
        CCCalibratePBKDF(CCPBKDFAlgorithm(kCCPBKDF2), 1, 200, CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA1), 16, 1)
            == UInt32.max
    )
}

func testAESECBAndCBC() {
    let key = ccBytes("000102030405060708090a0b0c0d0e0f")
    let plain = ccBytes("00112233445566778899aabbccddeeff")
    var cipher = [UInt8](repeating: 0, count: 16)
    var moved = 0
    let encryptStatus = key.withUnsafeBytes { keyRaw in
        plain.withUnsafeBytes { plainRaw in
            CCCrypt(
                CCOperation(kCCEncrypt),
                CCAlgorithm(kCCAlgorithmAES),
                CCOptions(kCCOptionECBMode),
                keyRaw.baseAddress!,
                key.count,
                nil,
                plainRaw.baseAddress!,
                plain.count,
                &cipher,
                cipher.count,
                &moved
            )
        }
    }
    precondition(encryptStatus == 0)
    precondition(moved == 16)
    precondition(ccHex(cipher) == "69c4e0d86a7b0430d8cdb78070b4c55a")

    var recovered = [UInt8](repeating: 0, count: 16)
    let decryptStatus = key.withUnsafeBytes { keyRaw in
        cipher.withUnsafeBytes { cipherRaw in
            CCCrypt(
                CCOperation(kCCDecrypt),
                CCAlgorithm(kCCAlgorithmAES128),
                CCOptions(kCCOptionECBMode),
                keyRaw.baseAddress!,
                key.count,
                nil,
                cipherRaw.baseAddress!,
                cipher.count,
                &recovered,
                recovered.count,
                &moved
            )
        }
    }
    precondition(decryptStatus == 0)
    precondition(recovered == plain)

    let cbcKey = ccBytes("2b7e151628aed2a6abf7158809cf4f3c")
    let iv = ccBytes("000102030405060708090a0b0c0d0e0f")
    let cbcPlain = ccBytes("6bc1bee22e409f96e93d7e117393172a")
    var cbcCipher = [UInt8](repeating: 0, count: 16)
    let cbcStatus = cbcKey.withUnsafeBytes { keyRaw in
        iv.withUnsafeBytes { ivRaw in
            cbcPlain.withUnsafeBytes { plainRaw in
                CCCrypt(
                    CCOperation(kCCEncrypt),
                    CCAlgorithm(kCCAlgorithmAES),
                    0,
                    keyRaw.baseAddress!,
                    cbcKey.count,
                    ivRaw.baseAddress!,
                    plainRaw.baseAddress!,
                    cbcPlain.count,
                    &cbcCipher,
                    cbcCipher.count,
                    &moved
                )
            }
        }
    }
    precondition(cbcStatus == 0)
    precondition(ccHex(cbcCipher) == "7649abac8119b246cee98e9b12e9197d")
}

func testAESCTRAndPKCS7() {
    let key = [UInt8](repeating: 0x11, count: 16)
    let iv = [UInt8](repeating: 0x22, count: 16)
    let plain = Array("hello CommonCrypto CTR".utf8)
    var cryptor: CCCryptorRef?
    let created = key.withUnsafeBytes { keyRaw in
        iv.withUnsafeBytes { ivRaw in
            CCCryptorCreateWithMode(
                CCOperation(kCCEncrypt),
                CCMode(kCCModeCTR),
                CCAlgorithm(kCCAlgorithmAES),
                CCPadding(ccNoPadding),
                ivRaw.baseAddress!,
                keyRaw.baseAddress!,
                key.count,
                nil,
                0,
                0,
                CCModeOptions(kCCModeOptionCTR_BE),
                &cryptor
            )
        }
    }
    precondition(created == 0)
    var cipher = [UInt8](repeating: 0, count: plain.count + 16)
    var moved = 0
    plain.withUnsafeBytes { raw in
        precondition(
            CCCryptorUpdate(cryptor, raw.baseAddress!, plain.count, &cipher, cipher.count, &moved) == 0
        )
    }
    var finalMoved = 0
    let cipherCount = cipher.count
    cipher.withUnsafeMutableBytes { buffer in
        precondition(
            CCCryptorFinal(
                cryptor,
                buffer.baseAddress!.advanced(by: moved),
                cipherCount - moved,
                &finalMoved
            ) == 0
        )
    }
    cipher = Array(cipher.prefix(moved + finalMoved))
    precondition(CCCryptorRelease(cryptor) == 0)
    precondition(cipher != plain)

    var decryptor: CCCryptorRef?
    _ = key.withUnsafeBytes { keyRaw in
        iv.withUnsafeBytes { ivRaw in
            CCCryptorCreateWithMode(
                CCOperation(kCCDecrypt),
                CCMode(kCCModeCTR),
                CCAlgorithm(kCCAlgorithmAES),
                CCPadding(ccNoPadding),
                ivRaw.baseAddress!,
                keyRaw.baseAddress!,
                key.count,
                nil,
                0,
                0,
                0,
                &decryptor
            )
        }
    }
    var recovered = [UInt8](repeating: 0, count: cipher.count + 16)
    var decryptMoved = 0
    cipher.withUnsafeBytes { raw in
        precondition(
            CCCryptorUpdate(decryptor, raw.baseAddress!, cipher.count, &recovered, recovered.count, &decryptMoved) == 0
        )
    }
    var decryptFinal = 0
    let recoveredCount = recovered.count
    recovered.withUnsafeMutableBytes { buffer in
        precondition(
            CCCryptorFinal(
                decryptor,
                buffer.baseAddress!.advanced(by: decryptMoved),
                recoveredCount - decryptMoved,
                &decryptFinal
            ) == 0
        )
    }
    recovered = Array(recovered.prefix(decryptMoved + decryptFinal))
    precondition(recovered == plain)
    precondition(CCCryptorRelease(decryptor) == 0)

    var padded: CCCryptorRef?
    let padCreate = key.withUnsafeBytes { keyRaw in
        CCCryptorCreate(
            CCOperation(kCCEncrypt),
            CCAlgorithm(kCCAlgorithmAES),
            CCOptions(kCCOptionPKCS7Padding | kCCOptionECBMode),
            keyRaw.baseAddress!,
            key.count,
            nil,
            &padded
        )
    }
    precondition(padCreate == 0)
    let needed = CCCryptorGetOutputLength(padded, 5, true)
    precondition(needed == 16)
    var padOut = [UInt8](repeating: 0, count: needed)
    let five = Array("hello".utf8)
    var padMoved = 0
    five.withUnsafeBytes { raw in
        precondition(CCCryptorUpdate(padded, raw.baseAddress!, five.count, &padOut, padOut.count, &padMoved) == 0)
    }
    var padFinal = 0
    let padCount = padOut.count
    padOut.withUnsafeMutableBytes { buffer in
        precondition(
            CCCryptorFinal(
                padded,
                buffer.baseAddress!.advanced(by: padMoved),
                padCount - padMoved,
                &padFinal
            ) == 0
        )
    }
    precondition(padMoved + padFinal == 16)
    precondition(CCCryptorRelease(padded) == 0)
}

func testCryptorFailClosedAndReset() {
    var cryptor: CCCryptorRef?
    let des = CCCryptorCreate(
        CCOperation(kCCEncrypt),
        CCAlgorithm(kCCAlgorithmDES),
        0,
        nil,
        8,
        nil,
        &cryptor
    )
    precondition(Int(des) == kCCUnimplemented)

    let key = [UInt8](repeating: 0x33, count: 16)
    let iv = [UInt8](repeating: 0x44, count: 16)
    var created: CCCryptorRef?
    _ = key.withUnsafeBytes { keyRaw in
        iv.withUnsafeBytes { ivRaw in
            CCCryptorCreate(
                CCOperation(kCCEncrypt),
                CCAlgorithm(kCCAlgorithmAES),
                0,
                keyRaw.baseAddress!,
                key.count,
                ivRaw.baseAddress!,
                &created
            )
        }
    }
    precondition(CCCryptorReset(created, nil) == 0)
    var used = 0
    let scratch = [UInt8](repeating: 0, count: 128)
    let fromData = key.withUnsafeBytes { keyRaw in
        scratch.withUnsafeBytes { dataRaw in
            CCCryptorCreateFromData(
                CCOperation(kCCEncrypt),
                CCAlgorithm(kCCAlgorithmAES),
                CCOptions(kCCOptionECBMode),
                keyRaw.baseAddress!,
                key.count,
                nil,
                dataRaw.baseAddress!,
                32,
                &created,
                &used
            )
        }
    }
    precondition(Int(fromData) == kCCBufferTooSmall)
    _ = CCCryptorRelease(created)
}

func testRandomAndKeyWrap() {
    var first = [UInt8](repeating: 0, count: 16)
    var second = [UInt8](repeating: 0, count: 16)
    precondition(CCRandomGenerateBytes(&first, first.count) == 0)
    precondition(CCRandomGenerateBytes(&second, second.count) == 0)
    precondition(first != second)
    precondition(Int(CCRandomGenerateBytes(nil, 4)) == kCCParamError)

    let kek = ccBytes("000102030405060708090a0b0c0d0e0f")
    let raw = ccBytes("00112233445566778899aabbccddeeff")
    precondition(CCSymmetricWrappedSize(CCWrappingAlgorithm(kCCWRAPAES), raw.count) == raw.count + 8)
    var wrapped = [UInt8](repeating: 0, count: 24)
    var wrappedLen = wrapped.count
    let wrapStatus = kek.withUnsafeBytes { kekRaw in
        raw.withUnsafeBytes { rawKey in
            CCSymmetricKeyWrap(
                CCWrappingAlgorithm(kCCWRAPAES),
                CCrfc3394_iv,
                CCrfc3394_ivLen,
                kekRaw.bindMemory(to: UInt8.self).baseAddress!,
                kek.count,
                rawKey.bindMemory(to: UInt8.self).baseAddress!,
                raw.count,
                &wrapped,
                &wrappedLen
            )
        }
    }
    precondition(wrapStatus == 0)
    precondition(ccHex(Array(wrapped.prefix(wrappedLen))) == "1fa68b0a8112b447aef34bd8fb5a7b829d3e862371d2cfe5")
    precondition(CCSymmetricUnwrappedSize(CCWrappingAlgorithm(kCCWRAPAES), wrappedLen) == raw.count)
    var unwrapped = [UInt8](repeating: 0, count: 16)
    var unwrappedLen = unwrapped.count
    let unwrapStatus = kek.withUnsafeBytes { kekRaw in
        wrapped.withUnsafeBytes { wrappedRaw in
            CCSymmetricKeyUnwrap(
                CCWrappingAlgorithm(kCCWRAPAES),
                CCrfc3394_iv,
                CCrfc3394_ivLen,
                kekRaw.bindMemory(to: UInt8.self).baseAddress!,
                kek.count,
                wrappedRaw.bindMemory(to: UInt8.self).baseAddress!,
                wrappedLen,
                &unwrapped,
                &unwrappedLen
            )
        }
    }
    precondition(unwrapStatus == 0)
    precondition(Array(unwrapped.prefix(unwrappedLen)) == raw)
}
