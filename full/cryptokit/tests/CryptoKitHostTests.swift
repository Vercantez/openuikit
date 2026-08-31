import CryptoKit
import Foundation

private func hex<S: Sequence>(_ bytes: S) -> String where S.Element == UInt8 {
    bytes.map { String(format: "%02x", $0) }.joined()
}

private let abc = Data("abc".utf8)
private let empty = Data()
private let multiBlock = Data((0..<1_000).map { UInt8($0 % 250) })

precondition(hex(Insecure.MD5.hash(data: empty)) == "d41d8cd98f00b204e9800998ecf8427e")
precondition(hex(Insecure.SHA1.hash(data: empty)) == "da39a3ee5e6b4b0d3255bfef95601890afd80709")
precondition(hex(SHA256.hash(data: empty)) == "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855")
precondition(hex(SHA384.hash(data: empty)) == "38b060a751ac96384cd9327eb1b1e36a21fdb71114be07434c0cc7bf63f6e1da274edebfe76f65fbd51ad2f14898b95b")
precondition(hex(SHA512.hash(data: empty)) == "cf83e1357eefb8bdf1542850d66d8007d620e4050b5715dc83f4a921d36ce9ce47d0d13c5d85f2b0ff8318d2877eec2f63b931bd47417a81a538327af927da3e")

precondition(
    hex(Insecure.MD5.hash(data: abc)) ==
        "900150983cd24fb0d6963f7d28e17f72"
)
precondition(
    hex(Insecure.SHA1.hash(data: abc)) ==
        "a9993e364706816aba3e25717850c26c9cd0d89d"
)
precondition(
    hex(SHA256.hash(data: abc)) ==
        "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad"
)
precondition(
    hex(SHA384.hash(data: abc)) ==
        "cb00753f45a35e8bb5a03d699ac65007272c32ab0eded1631a8b605a43ff5bed" +
        "8086072ba1e7cc2358baeca134c825a7"
)
precondition(
    hex(SHA512.hash(data: abc)) ==
        "ddaf35a193617abacc417349ae20413112e6fa4e89a97ea20a9eeee64b55d39a" +
        "2192992a274fc1a836ba3c23a3feebbd454d4423643ce80e2a9ac94fa54ca49f"
)
precondition(hex(Insecure.MD5.hash(data: multiBlock)) == "8e180d694724ffd45b63cafd39c95578")
precondition(hex(Insecure.SHA1.hash(data: multiBlock)) == "06a8a11885e2a1a68c7088791ae2a9fb536a93cc")
precondition(hex(SHA256.hash(data: multiBlock)) == "5d4b1b13f0daa86380d0ac6912a60a307cc9719115ecadb10a06d2d3603bd35c")
precondition(hex(SHA384.hash(data: multiBlock)) == "b568458a6075cffac7faa37b0619a960801b4602bb4d32d23539196c4d61f577f5516854d0ed991d48f2e3a418f83a04")
precondition(hex(SHA512.hash(data: multiBlock)) == "2a4aa07568a85cbd4d9c2c89b628503836f4f3aedeef876bbc04890f2bcd11cf4d3a456640d5be2368105cd37a45393d4c4ee343bb5a735b328bcb3193638cb4")

var streaming = SHA256()
streaming.update(data: Data("a".utf8))
Data("bc".utf8).withUnsafeBytes { streaming.update(bufferPointer: $0) }
precondition(streaming.finalize() == SHA256.hash(data: abc))
precondition(SHA256Digest.byteCount == 32)
precondition(Insecure.SHA1Digest.byteCount == 20)

let nonceA = ChaChaPoly.Nonce()
let nonceB = ChaChaPoly.Nonce()
precondition(nonceA.count == 12 && nonceB.count == 12)
precondition(Data(nonceA) != Data(nonceB))
let reconstructedNonce = try ChaChaPoly.Nonce(data: Data(nonceA))
precondition(reconstructedNonce.count == 12)

do {
    _ = try Curve25519.Signing.PublicKey(rawRepresentation: Data(count: 31))
    preconditionFailure("invalid Ed25519 public key length was accepted")
} catch CryptoKitError.incorrectKeySize {
    // Expected.
}
let key = try Curve25519.Signing.PublicKey(rawRepresentation: Data(count: 32))
precondition(key.rawRepresentation.count == 32)
precondition(!key.isValidSignature(Data(count: 64), for: abc))

print("CRYPTOKIT_HOST_OK hashes=md5,sha1,sha256,sha384,sha512 nonce=12 ed25519=fail-closed")
