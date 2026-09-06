# CryptoTokenKit (Linux starting point)

This directory is a clean-room Linux starting point for Apple's public
`CryptoTokenKit` module, seeded from the Xcode 26.1 iPhoneOS 26.1 symbol
graph, API digester, TBD exports, and the pinned `dotnet/macios` bindings.
It is not wired into the shared guest package; that integration is a later
central-review step.

Linux has no smart-card reader, NFC slot, `ctkd` token daemon, or Secure
Enclave. Session I/O, PIN pads, pairing, and private-key operations never
invent hardware success.

## What is real

- `TKError` is a `@frozen` `Foundation._BridgedStoredNSError` overlay.
  `TKError.Code` raw values match pinned macios `TKErrorCode`
  (`notImplemented = -1` … `authenticationNeeded = -9`).
  `TKErrorDomain` is the process-local string `TKErrorDomain`.
- `TKSmartCardPINFormat.Charset` / `Encoding` / `Justification`,
  `TKSmartCardSlot.State`, `TKTokenOperation`, and the option sets
  `TKSmartCardProtocol`, `Completion`, and `Confirmation` use the macios
  bit positions and sequential integers.
- BER-TLV (`TKBERTLVRecord`), compact TLV (`TKCompactTLVRecord`), and
  simple TLV (`TKSimpleTLVRecord`) encode and parse ISO 7816-4 definite
  forms. `TKTLVRecord.init(from:)` / `sequenceOfRecords(from:)` parse BER.
- `TKSmartCardATR` parses ISO/IEC 7816-3 ATR bytes (TS `0x3B`/`0x3F`,
  interface groups, historical bytes, optional TCK). Historical bytes that
  are compact TLV become `historicalRecords`.
- `TKSmartCardPINFormat` and user-interaction objects are stored-property
  value holders (ObjC zero-init defaults).
- `TKToken.Configuration` / `TKTokenDriver.Configuration` and
  `TKTokenKeychainContents` are process-local catalogs: add/remove token
  configurations, fill keychain items, and look up keys/certificates by
  `objectID` (`objectNotFound` when missing).
- `TKTokenAuthOperation.finish()` succeeds (no further auth). Password and
  smart-card PIN subclasses fail closed with `notImplemented`.

Host-compiled sources import Foundation only. The identity probe
`tests/agent/CryptoTokenKitDependencyIdentity.swift` imports
`CryptoTokenKit` and `Foundation` for the later EC2 integration build.

## Fail-closed boundaries

- `TKSmartCard.beginSession`, `send`, `withSession`, and `transmit` return
  `communicationError`. `makeSmartCard()` is nil. PIN user-interaction
  factories return nil.
- `endSession()` still clears `context` when `isSensitive` is true.
- `TKSmartCardSlotManager.default` has empty `slotNames`.
  `isNFCSupported()` is false. NFC session `update(message:)` throws
  `notImplemented`.
- Token watcher `tokenIDs` stay empty; insertion/removal handlers never
  fire.
- Smart-card pairing (`registerSmartCard` / `unregisterSmartCard`) throws
  `notImplemented`.
- Session delegate defaults refuse sign/decrypt/key-exchange with
  `notImplemented` and auth with `authenticationNeeded`.

## Deferred

- `TKTokenKeyAlgorithm.isAlgorithm` / `supportsAlgorithm`
- `TKTokenKeychainCertificate.init(certificate:objectID:)`
- `TKTokenKeychainKey.init(certificate:objectID:)`

`SecCertificate` and `SecKeyAlgorithm` belong to Security, which is not a
declared dependency. A public lookalike is forbidden.

Async overlays `transmit(_:)`, `getSlot(withName:)`, and
`createNFCSlot(message:)` are declared: the sealed runner cannot await.

Run the sealed host gate with:

```sh
bash full/cryptotokenkit/tests/acceptance/test_host.sh
```

## Depth pass 2026-09

Implemented **298** identifiers, declared **73** (compiler-synthesized
OptionSet/Equatable/Hashable witnesses plus async overlays), deferred **4**.
Nondeferred total **371** of 375 (lane floor 188).

Top-5 implemented evidence distribution:

1. `testTKTokenConfigurationKeyLookup` — 15 (keychain key/certificate fields)
2. `testTKErrorStaticCodeAliases` — 15 (`TKError.*` static `Code` aliases)
3. `testTKErrorBridging` — 14 (`_BridgedStoredNSError` overlay)
4. `testTKErrorCodeRawValues` / `testTKSmartCardATRDirectConvention` — 11 each
5. `testTKSmartCardPINFormatProperties` / `testTKTokenInitAndConfiguration` — 10 each

Enum/option-set members and C constants share table-driven value tests.
No other single test is cited by more than 40% of the remaining
implemented rows (`testTKTokenConfigurationKeyLookup` is 15/247 ≈ 6%).
