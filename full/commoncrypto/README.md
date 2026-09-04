# CommonCrypto Linux lane

This directory is a clean-room starting point for a Linux `CommonCrypto` module.
It is not a claim of Apple runtime parity.

## What is real

- The existing C SHA-256 implementation in `CommonDigest.c` / `include/CommonDigest.h`
  remains in place and is still exercised by `tests/test_commoncrypto_host.sh`.
- The Swift module compiled by the isolated host gate is a Foundation-free
  `CommonCrypto` overlay of the public Clang-imported surface: digest, HMAC,
  AES-ECB/CBC/CTR, PBKDF2, RFC 3394 AES key wrap, and `CCRandomGenerateBytes`.
- Digest and HMAC one-shot plus streaming paths are checked against FIPS / RFC
  vectors (empty and `"abc"` SHA-256 match the C guest tests). AES-128 ECB/CBC
  use NIST SP 800-38A blocks; HMAC-SHA256 uses RFC 4231 case 1; PBKDF2 uses
  RFC 6070; key wrap uses RFC 3394.

## Fail-closed

- DES, 3DES, CAST, RC4, RC2, and Blowfish `CCCryptor` algorithms return
  `kCCUnimplemented`.
- CFB/OFB/CFB8 cryptor modes, non-zero tweak, and non-zero `numRounds` return
  `kCCUnimplemented`.
- `CCCryptorReset` is implemented for CBC only; other modes return
  `kCCUnimplemented`.
- `CCCalibratePBKDF` returns the documented 10_000-round safety-net minimum
  rather than an Apple wall-clock calibration.

## Deferred

- `kCCContextSize*` constants: Apple documents them as version-variable, and
  the sealed iPhoneOS 26.1 header bytes are not in the seed.
- Exact Apple `CCCalibratePBKDF` msec-to-rounds mapping.
- C ABI layout of `CCCryptorRef` and `CCCryptorCreateFromData` caller-supplied
  context memory (the Swift gate returns an opaque Swift box).
