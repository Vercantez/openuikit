import Foundation

/// PDF 1.7 (ISO 32000-1) standard security handler.
/// Password / file-key: §7.6.3.3 Algorithms 2–6 (R=2, 3, 4).
/// Object encryption: §7.6.2 Algorithm 1 (RC4) and Algorithm 1a (AESV2).
/// AES-256 R=5/6 (Adobe ExtensionLevel 3 / ISO 32000-2 §7.6.4) is handled
/// for the published U/O/UE/OE/Perms layout.
enum PDFKitCrypto {
    /// ISO 32000-1 Table 51 password padding.
    static let padding: [UInt8] = [
        0x28, 0xBF, 0x4E, 0x5E, 0x4E, 0x75, 0x8A, 0x41,
        0x64, 0x00, 0x4E, 0x56, 0xFF, 0xFA, 0x01, 0x08,
        0x2E, 0x2E, 0x00, 0xB6, 0xD0, 0x68, 0x3E, 0x80,
        0x2F, 0x0C, 0xA9, 0xFE, 0x64, 0x53, 0x69, 0x7A
    ]

    struct EncryptInfo {
        var revision: Int
        var version: Int
        var keyLengthBytes: Int
        var permissions: Int32
        var ownerKey: [UInt8]
        var userKey: [UInt8]
        var fileID: [UInt8]
        var encryptMetadata: Bool
        var useAES: Bool
        var ownerEncryptionKey: [UInt8]
        var userEncryptionKey: [UInt8]
        var perms: [UInt8]
    }

    static func padPassword(_ password: String) -> [UInt8] {
        var bytes = Array(password.data(using: .isoLatin1) ?? Data(password.utf8))
        if bytes.count >= 32 { return Array(bytes.prefix(32)) }
        bytes.append(contentsOf: padding.prefix(32 - bytes.count))
        return bytes
    }

    /// Algorithm 2: encryption key from user password (R=2,3,4).
    static func fileKey(password: String, info: EncryptInfo) -> [UInt8] {
        var input = padPassword(password)
        input.append(contentsOf: info.ownerKey)
        let p = UInt32(bitPattern: info.permissions)
        input.append(UInt8(p & 0xFF))
        input.append(UInt8((p >> 8) & 0xFF))
        input.append(UInt8((p >> 16) & 0xFF))
        input.append(UInt8((p >> 24) & 0xFF))
        input.append(contentsOf: info.fileID)
        if info.revision >= 4 && !info.encryptMetadata {
            input.append(contentsOf: [0xFF, 0xFF, 0xFF, 0xFF])
        }
        var hash = md5(input)
        if info.revision >= 3 {
            for _ in 0..<50 {
                hash = md5(Array(hash.prefix(info.keyLengthBytes)))
            }
        }
        return Array(hash.prefix(info.keyLengthBytes))
    }

    /// Algorithm 6: authenticate user password (R=2,3,4).
    static func userPasswordMatches(_ password: String, info: EncryptInfo) -> [UInt8]? {
        let key = fileKey(password: password, info: info)
        if info.revision == 2 {
            let encrypted = rc4(key, padding)
            if encrypted == Array(info.userKey.prefix(32)) { return key }
            return nil
        }
        let hash = md5(padding + info.fileID)
        var output = rc4(key, hash)
        for round in 1...19 {
            let roundKey = key.map { $0 ^ UInt8(round) }
            output = rc4(roundKey, output)
        }
        if Array(output.prefix(16)) == Array(info.userKey.prefix(16)) { return key }
        return nil
    }

    /// Algorithm 3 / 7: try the owner password, recover the user password key.
    static func ownerPasswordMatches(_ password: String, info: EncryptInfo) -> [UInt8]? {
        let input = padPassword(password)
        var hash = md5(input)
        if info.revision >= 3 {
            for _ in 0..<50 { hash = md5(hash) }
        }
        let key = Array(hash.prefix(info.keyLengthBytes))
        var user = info.ownerKey
        if info.revision == 2 {
            user = rc4(key, user)
        } else {
            for round in stride(from: 19, through: 0, by: -1) {
                let roundKey = key.map { $0 ^ UInt8(round) }
                user = rc4(roundKey, user)
            }
        }
        let recovered = String(bytes: user, encoding: .isoLatin1) ?? ""
        return userPasswordMatches(recovered, info: info)
            ?? userPasswordMatches(String(bytes: Array(user.prefix(while: { $0 != 0 })), encoding: .isoLatin1) ?? "", info: info)
    }

    static func unlock(password: String, info: EncryptInfo) -> (key: [UInt8], owner: Bool)? {
        if info.revision >= 5 {
            return unlockAES256(password: password, info: info)
        }
        if let key = userPasswordMatches(password, info: info) {
            return (key, false)
        }
        if let key = ownerPasswordMatches(password, info: info) {
            return (key, true)
        }
        return nil
    }

    /// Algorithm 1 / 1a: decrypt one string or stream.
    static func decryptObject(
        _ data: Data,
        key fileKey: [UInt8],
        object: Int,
        generation: Int,
        useAES: Bool
    ) -> Data {
        var objectKey = fileKey
        objectKey.append(UInt8(object & 0xFF))
        objectKey.append(UInt8((object >> 8) & 0xFF))
        objectKey.append(UInt8((object >> 16) & 0xFF))
        objectKey.append(UInt8(generation & 0xFF))
        objectKey.append(UInt8((generation >> 8) & 0xFF))
        if useAES { objectKey.append(contentsOf: [0x73, 0x41, 0x6C, 0x54]) }
        let digest = md5(objectKey)
        let n = min(fileKey.count + 5, 16)
        let rc4Key = Array(digest.prefix(n))
        if !useAES {
            return Data(rc4(rc4Key, [UInt8](data)))
        }
        let aesKey = Array(digest.prefix(min(16, digest.count)))
        return Data(aesCBCDecrypt([UInt8](data), key: aesKey) ?? [])
    }

    static func encryptObject(
        _ data: Data,
        key fileKey: [UInt8],
        object: Int,
        generation: Int,
        useAES: Bool
    ) -> Data {
        var objectKey = fileKey
        objectKey.append(UInt8(object & 0xFF))
        objectKey.append(UInt8((object >> 8) & 0xFF))
        objectKey.append(UInt8((object >> 16) & 0xFF))
        objectKey.append(UInt8(generation & 0xFF))
        objectKey.append(UInt8((generation >> 8) & 0xFF))
        if useAES { objectKey.append(contentsOf: [0x73, 0x41, 0x6C, 0x54]) }
        let digest = md5(objectKey)
        let n = min(fileKey.count + 5, 16)
        let rc4Key = Array(digest.prefix(n))
        if !useAES {
            return Data(rc4(rc4Key, [UInt8](data)))
        }
        let aesKey = Array(digest.prefix(min(16, digest.count)))
        var iv = [UInt8](repeating: 0, count: 16)
        for index in 0..<16 { iv[index] = UInt8(index &* 17 &+ 3) }
        return Data(aesCBCEncrypt([UInt8](data), key: aesKey, iv: iv))
    }

    // MARK: - AES-256 (R=5)

    private static func unlockAES256(password: String, info: EncryptInfo) -> (key: [UInt8], owner: Bool)? {
        let passwordBytes = Array((password.data(using: .utf8) ?? Data()).prefix(127))
        if info.userKey.count >= 48 {
            let salt = Array(info.userKey[32..<40])
            let hash = sha256(passwordBytes + salt)
            if hash == Array(info.userKey.prefix(32)), info.userEncryptionKey.count >= 32 {
                if let fileKey = aes256CBCDecrypt(info.userEncryptionKey, key: hash) {
                    return (Array(fileKey.prefix(32)), false)
                }
            }
        }
        if info.ownerKey.count >= 48 {
            let salt = Array(info.ownerKey[32..<40])
            let hash = sha256(passwordBytes + salt + Array(info.userKey.prefix(48)))
            if hash == Array(info.ownerKey.prefix(32)), info.ownerEncryptionKey.count >= 32 {
                if let fileKey = aes256CBCDecrypt(info.ownerEncryptionKey, key: hash) {
                    return (Array(fileKey.prefix(32)), true)
                }
            }
        }
        return nil
    }

    // MARK: - primitives (FIPS 180-1 MD5, FIPS 197 AES, RC4)

    static func md5(_ input: [UInt8]) -> [UInt8] {
        let s: [UInt32] = [
            7, 12, 17, 22, 7, 12, 17, 22, 7, 12, 17, 22, 7, 12, 17, 22,
            5, 9, 14, 20, 5, 9, 14, 20, 5, 9, 14, 20, 5, 9, 14, 20,
            4, 11, 16, 23, 4, 11, 16, 23, 4, 11, 16, 23, 4, 11, 16, 23,
            6, 10, 15, 21, 6, 10, 15, 21, 6, 10, 15, 21, 6, 10, 15, 21
        ]
        let k: [UInt32] = [
            0xd76aa478, 0xe8c7b756, 0x242070db, 0xc1bdceee, 0xf57c0faf, 0x4787c62a, 0xa8304613, 0xfd469501,
            0x698098d8, 0x8b44f7af, 0xffff5bb1, 0x895cd7be, 0x6b901122, 0xfd987193, 0xa679438e, 0x49b40821,
            0xf61e2562, 0xc040b340, 0x265e5a51, 0xe9b6c7aa, 0xd62f105d, 0x02441453, 0xd8a1e681, 0xe7d3fbc8,
            0x21e1cde6, 0xc33707d6, 0xf4d50d87, 0x455a14ed, 0xa9e3e905, 0xfcefa3f8, 0x676f02d9, 0x8d2a4c8a,
            0xfffa3942, 0x8771f681, 0x6d9d6122, 0xfde5380c, 0xa4beea44, 0x4bdecfa9, 0xf6bb4b60, 0xbebfbc70,
            0x289b7ec6, 0xeaa127fa, 0xd4ef3085, 0x04881d05, 0xd9d4d039, 0xe6db99e5, 0x1fa27cf8, 0xc4ac5665,
            0xf4292244, 0x432aff97, 0xab9423a7, 0xfc93a039, 0x655b59c3, 0x8f0ccc92, 0xffeff47d, 0x85845dd1,
            0x6fa87e4f, 0xfe2ce6e0, 0xa3014314, 0x4e0811a1, 0xf7537e82, 0xbd3af235, 0x2ad7d2bb, 0xeb86d391
        ]
        var message = input
        message.append(0x80)
        while (message.count % 64) != 56 { message.append(0) }
        var bitLength = UInt64(input.count) * 8
        for _ in 0..<8 {
            message.append(UInt8(bitLength & 0xFF))
            bitLength >>= 8
        }
        var a0: UInt32 = 0x67452301
        var b0: UInt32 = 0xefcdab89
        var c0: UInt32 = 0x98badcfe
        var d0: UInt32 = 0x10325476
        var offset = 0
        while offset < message.count {
            var m = [UInt32](repeating: 0, count: 16)
            for index in 0..<16 {
                let i = offset + index * 4
                m[index] = UInt32(message[i])
                    | (UInt32(message[i + 1]) << 8)
                    | (UInt32(message[i + 2]) << 16)
                    | (UInt32(message[i + 3]) << 24)
            }
            var a = a0, b = b0, c = c0, d = d0
            for i in 0..<64 {
                let f: UInt32
                let g: Int
                switch i {
                case 0..<16:
                    f = (b & c) | ((~b) & d)
                    g = i
                case 16..<32:
                    f = (d & b) | ((~d) & c)
                    g = (5 * i + 1) % 16
                case 32..<48:
                    f = b ^ c ^ d
                    g = (3 * i + 5) % 16
                default:
                    f = c ^ (b | (~d))
                    g = (7 * i) % 16
                }
                let temp = d
                d = c
                c = b
                b = b &+ rotateLeft(a &+ f &+ k[i] &+ m[g], s[i])
                a = temp
            }
            a0 &+= a
            b0 &+= b
            c0 &+= c
            d0 &+= d
            offset += 64
        }
        var digest = [UInt8]()
        for word in [a0, b0, c0, d0] {
            digest.append(UInt8(word & 0xFF))
            digest.append(UInt8((word >> 8) & 0xFF))
            digest.append(UInt8((word >> 16) & 0xFF))
            digest.append(UInt8((word >> 24) & 0xFF))
        }
        return digest
    }

    static func sha256(_ input: [UInt8]) -> [UInt8] {
        let k: [UInt32] = [
            0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
            0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3, 0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
            0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc, 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
            0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7, 0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
            0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13, 0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
            0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
            0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
            0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208, 0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2
        ]
        var message = input
        message.append(0x80)
        while (message.count % 64) != 56 { message.append(0) }
        let bitLength = UInt64(input.count) * 8
        for shift in [56, 48, 40, 32, 24, 16, 8, 0] {
            message.append(UInt8((bitLength >> shift) & 0xFF))
        }
        var state: [UInt32] = [
            0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a,
            0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19
        ]
        var offset = 0
        while offset < message.count {
            var words = [UInt32](repeating: 0, count: 64)
            for index in 0..<16 {
                let i = offset + index * 4
                words[index] = (UInt32(message[i]) << 24)
                    | (UInt32(message[i + 1]) << 16)
                    | (UInt32(message[i + 2]) << 8)
                    | UInt32(message[i + 3])
            }
            for index in 16..<64 {
                let x = words[index - 15]
                let y = words[index - 2]
                let s0 = rotateRight(x, 7) ^ rotateRight(x, 18) ^ (x >> 3)
                let s1 = rotateRight(y, 17) ^ rotateRight(y, 19) ^ (y >> 10)
                words[index] = words[index - 16] &+ s0 &+ words[index - 7] &+ s1
            }
            var a = state[0], b = state[1], c = state[2], d = state[3]
            var e = state[4], f = state[5], g = state[6], h = state[7]
            for index in 0..<64 {
                let s1 = rotateRight(e, 6) ^ rotateRight(e, 11) ^ rotateRight(e, 25)
                let choose = (e & f) ^ ((~e) & g)
                let t1 = h &+ s1 &+ choose &+ k[index] &+ words[index]
                let s0 = rotateRight(a, 2) ^ rotateRight(a, 13) ^ rotateRight(a, 22)
                let majority = (a & b) ^ (a & c) ^ (b & c)
                let t2 = s0 &+ majority
                h = g
                g = f
                f = e
                e = d &+ t1
                d = c
                c = b
                b = a
                a = t1 &+ t2
            }
            state[0] &+= a
            state[1] &+= b
            state[2] &+= c
            state[3] &+= d
            state[4] &+= e
            state[5] &+= f
            state[6] &+= g
            state[7] &+= h
            offset += 64
        }
        var digest = [UInt8]()
        for word in state {
            digest.append(UInt8((word >> 24) & 0xFF))
            digest.append(UInt8((word >> 16) & 0xFF))
            digest.append(UInt8((word >> 8) & 0xFF))
            digest.append(UInt8(word & 0xFF))
        }
        return digest
    }

    static func rc4(_ key: [UInt8], _ data: [UInt8]) -> [UInt8] {
        var s = Array(UInt8(0)...UInt8(255))
        var j = 0
        for i in 0..<256 {
            j = (j + Int(s[i]) + Int(key[i % key.count])) % 256
            s.swapAt(i, j)
        }
        var i = 0
        j = 0
        var output = [UInt8](repeating: 0, count: data.count)
        for index in 0..<data.count {
            i = (i + 1) % 256
            j = (j + Int(s[i])) % 256
            s.swapAt(i, j)
            let k = s[(Int(s[i]) + Int(s[j])) % 256]
            output[index] = data[index] ^ k
        }
        return output
    }

    static func aesCBCDecrypt(_ data: [UInt8], key: [UInt8]) -> [UInt8]? {
        guard data.count >= 16, data.count % 16 == 0 else { return nil }
        let iv = Array(data.prefix(16))
        let body = Array(data.dropFirst(16))
        let roundKeys = aesExpand(key)
        var previous = iv
        var output: [UInt8] = []
        var offset = 0
        while offset < body.count {
            let block = Array(body[offset..<(offset + 16)])
            let plain = xorBlock(aesDecryptBlock(block, roundKeys: roundKeys), previous)
            output.append(contentsOf: plain)
            previous = block
            offset += 16
        }
        guard let last = output.last, last >= 1, last <= 16, output.count >= Int(last) else { return nil }
        let pad = Int(last)
        if output.suffix(pad).contains(where: { $0 != last }) { return nil }
        output.removeLast(pad)
        return output
    }

    static func aesCBCEncrypt(_ data: [UInt8], key: [UInt8], iv: [UInt8]) -> [UInt8] {
        var padded = data
        let pad = 16 - (padded.count % 16)
        padded.append(contentsOf: [UInt8](repeating: UInt8(pad), count: pad))
        let roundKeys = aesExpand(key)
        var previous = iv
        var output = iv
        var offset = 0
        while offset < padded.count {
            let block = Array(padded[offset..<(offset + 16)])
            let encrypted = aesEncryptBlock(xorBlock(block, previous), roundKeys: roundKeys)
            output.append(contentsOf: encrypted)
            previous = encrypted
            offset += 16
        }
        return output
    }

    private static func aes256CBCDecrypt(_ data: [UInt8], key: [UInt8]) -> [UInt8]? {
        // UE/OE are a single AES-256 block (no IV) in R=5.
        if data.count == 32 {
            let roundKeys = aesExpand(key)
            return aesDecryptBlock(Array(data.prefix(16)), roundKeys: roundKeys)
                + aesDecryptBlock(Array(data.suffix(16)), roundKeys: roundKeys)
        }
        return aesCBCDecrypt(data, key: Array(key.prefix(16)))
    }

    private static func rotateLeft(_ value: UInt32, _ amount: UInt32) -> UInt32 {
        (value << amount) | (value >> (32 - amount))
    }

    private static func rotateRight(_ value: UInt32, _ amount: UInt32) -> UInt32 {
        (value >> amount) | (value << (32 - amount))
    }

    private static func xorBlock(_ a: [UInt8], _ b: [UInt8]) -> [UInt8] {
        zip(a, b).map { $0 ^ $1 }
    }
}

private let _pdfAESSbox: [UInt8] = [
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
    0x8c, 0xa1, 0x89, 0x0d, 0xbf, 0xe6, 0x42, 0x68, 0x41, 0x99, 0x2d, 0x0f, 0xb0, 0x54, 0xbb, 0x16
]

private let _pdfAESInvSbox: [UInt8] = {
    var inverse = [UInt8](repeating: 0, count: 256)
    for index in 0..<256 { inverse[Int(_pdfAESSbox[index])] = UInt8(index) }
    return inverse
}()

private func _pdfAESXt(_ value: UInt8) -> UInt8 {
    let shifted = UInt8(truncatingIfNeeded: Int(value) << 1)
    return (value & 0x80) == 0 ? shifted : (shifted ^ 0x1b)
}

private func _pdfAESMul(_ value: UInt8, _ factor: UInt8) -> UInt8 {
    var result: UInt8 = 0
    var a = value
    var b = factor
    while b != 0 {
        if (b & 1) != 0 { result ^= a }
        a = _pdfAESXt(a)
        b >>= 1
    }
    return result
}

private func aesExpand(_ key: [UInt8]) -> [[UInt8]] {
    let keyLength = key.count
    let rounds = keyLength == 16 ? 10 : (keyLength == 24 ? 12 : 14)
    let n = max(4, keyLength / 4)
    var words = [[UInt8]](repeating: [0, 0, 0, 0], count: 4 * (rounds + 1))
    for index in 0..<n {
        let start = min(index * 4, key.count)
        var word = [UInt8](repeating: 0, count: 4)
        for offset in 0..<4 where start + offset < key.count {
            word[offset] = key[start + offset]
        }
        words[index] = word
    }
    let rcon: [UInt8] = [0x00, 0x01, 0x02, 0x04, 0x08, 0x10, 0x20, 0x40, 0x80, 0x1b, 0x36]
    for index in n..<(4 * (rounds + 1)) {
        var temp = words[index - 1]
        if index % n == 0 {
            temp = [temp[1], temp[2], temp[3], temp[0]].map { _pdfAESSbox[Int($0)] }
            temp[0] ^= rcon[index / n]
        } else if n > 6 && index % n == 4 {
            temp = temp.map { _pdfAESSbox[Int($0)] }
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

private func aesEncryptBlock(_ input: [UInt8], roundKeys: [[UInt8]]) -> [UInt8] {
    var state = input
    func addRoundKey(_ round: Int) {
        for index in 0..<16 { state[index] ^= roundKeys[round][index] }
    }
    addRoundKey(0)
    for round in 1..<(roundKeys.count - 1) {
        for index in 0..<16 { state[index] = _pdfAESSbox[Int(state[index])] }
        state = [
            state[0], state[5], state[10], state[15],
            state[4], state[9], state[14], state[3],
            state[8], state[13], state[2], state[7],
            state[12], state[1], state[6], state[11]
        ]
        var mixed = [UInt8](repeating: 0, count: 16)
        for column in 0..<4 {
            let i = column * 4
            let a = state[i], b = state[i + 1], c = state[i + 2], d = state[i + 3]
            mixed[i] = _pdfAESXt(a) ^ _pdfAESXt(b) ^ b ^ c ^ d
            mixed[i + 1] = a ^ _pdfAESXt(b) ^ _pdfAESXt(c) ^ c ^ d
            mixed[i + 2] = a ^ b ^ _pdfAESXt(c) ^ _pdfAESXt(d) ^ d
            mixed[i + 3] = _pdfAESXt(a) ^ a ^ b ^ c ^ _pdfAESXt(d)
        }
        state = mixed
        addRoundKey(round)
    }
    for index in 0..<16 { state[index] = _pdfAESSbox[Int(state[index])] }
    state = [
        state[0], state[5], state[10], state[15],
        state[4], state[9], state[14], state[3],
        state[8], state[13], state[2], state[7],
        state[12], state[1], state[6], state[11]
    ]
    addRoundKey(roundKeys.count - 1)
    return state
}

private func aesDecryptBlock(_ input: [UInt8], roundKeys: [[UInt8]]) -> [UInt8] {
    var state = input
    func addRoundKey(_ round: Int) {
        for index in 0..<16 { state[index] ^= roundKeys[round][index] }
    }
    addRoundKey(roundKeys.count - 1)
    for round in stride(from: roundKeys.count - 2, through: 1, by: -1) {
        state = [
            state[0], state[13], state[10], state[7],
            state[4], state[1], state[14], state[11],
            state[8], state[5], state[2], state[15],
            state[12], state[9], state[6], state[3]
        ]
        for index in 0..<16 { state[index] = _pdfAESInvSbox[Int(state[index])] }
        addRoundKey(round)
        var mixed = [UInt8](repeating: 0, count: 16)
        for column in 0..<4 {
            let i = column * 4
            let a = state[i], b = state[i + 1], c = state[i + 2], d = state[i + 3]
            mixed[i] = _pdfAESMul(a, 14) ^ _pdfAESMul(b, 11) ^ _pdfAESMul(c, 13) ^ _pdfAESMul(d, 9)
            mixed[i + 1] = _pdfAESMul(a, 9) ^ _pdfAESMul(b, 14) ^ _pdfAESMul(c, 11) ^ _pdfAESMul(d, 13)
            mixed[i + 2] = _pdfAESMul(a, 13) ^ _pdfAESMul(b, 9) ^ _pdfAESMul(c, 14) ^ _pdfAESMul(d, 11)
            mixed[i + 3] = _pdfAESMul(a, 11) ^ _pdfAESMul(b, 13) ^ _pdfAESMul(c, 9) ^ _pdfAESMul(d, 14)
        }
        state = mixed
    }
    state = [
        state[0], state[13], state[10], state[7],
        state[4], state[1], state[14], state[11],
        state[8], state[5], state[2], state[15],
        state[12], state[9], state[6], state[3]
    ]
    for index in 0..<16 { state[index] = _pdfAESInvSbox[Int(state[index])] }
    addRoundKey(0)
    return state
}
