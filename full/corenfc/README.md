# CoreNFC

Linux starting point for Apple's public `CoreNFC` module, reconstructed from
the pinned Xcode 26.1 iPhoneOS symbol graph. This directory is not wired into
the shared guest package. A passing isolated host gate is not integrated Linux
success and is not Apple NFC behavioral parity.

The legacy fan-out branch `cursor/port-corenfc-to-linux-9597` (platform PR #50,
claimed 2456 Swift lines) was not readable from this GitHub App token (scoped
to `Vercantez/openuikit` only). `git fetch platform` and the GitHub API both
returned 404. This tree is a seed-based deliverable, not a byte-copy of those
lines.

**Reference dossier kept:** monorepo `full/corenfc/reference/` (generator
`scripts/framework-fanout/generate_seed.py`, SHA-256
`2b8230ced5a3ed78f070607346f6a684d9e0fb74a8932b92bc0f5e38f46f0a8e`). The
platform branch dossier was unavailable to compare, so the current seed on
main is the one retained.

## What is real

The public Swift surface compiles to `libCoreNFC.dylib`.

Implemented and exercised:

- NDEF well-known text (`T`) and URI (`U`) payload factories, including Apple's
  historical `wellKnowTypeTextPayload` spelling, plus NFC Forum NDEF 1.0
  message encode/decode and `length`
- ISO 7816-4 short command APDU construct/parse (`Le` 0 means 256)
- Enums, aliases, and OptionSet algebra (`NFCTypeNameFormat`,
  `NFCTagReaderSession.PollingOption`, ISO 15693 request/response flags,
  FeliCa polling/encryption identifiers, VAS mode/status)
- `NFCReaderError` / `NFCErrorDomain` constructibility and pattern matching
- Session objects: `readingAvailable` is `false`; NDEF `begin()` hops onto
  `sessionQueue` and invalidates with `readerErrorUnsupportedFeature`;
  `NFCTagReaderSession.init?` returns `nil`
- `CardSession` / `NFCPresentmentIntentAssertion` refuse with
  `systemNotAvailable`

## Fail-closed boundaries

Linux has no NFC controller, Core NFC entitlement, privacy prompt, or Apple
VAS/card-emulation daemon.

- No tag is ever detected. Tag protocol methods throw or callback with
  `NFCReaderError.readerErrorUnsupportedFeature` (or a related NDEF writer
  code). They do not invent UID, NDEF, or APDU success.
- `CardSession.isSupported` is `false`; `isEligible` is `false`; emulation APIs
  throw `systemNotAvailable`.
- UIKit overlay types (`NFCWindowSceneEvent`, `NFCWindowSceneDelegate`,
  `UIScene.ConnectionOptions.nfcEvent`) are deferred: UIKit is not a declared
  dependency of this seed.
- `NSUserActivity.ndefMessagePayload` is deferred: `NSUserActivity` is not
  present in this Linux Foundation overlay.
- Swift cannot overload `sendCommand(apdu:)` by return type alone, so the
  `NFCISO7816ResponseAPDU`-returning overlay is deferred; Linux exposes the
  ObjC tuple result.

## Depth pass 2026-09

SDK depth against the sealed 587-ID public surface. Coverage before this pass:
**167 implemented / 396 declared / 24 deferred**. After: **542 implemented /
21 declared / 24 deferred**.

The pinned 20-app corpus summary names only home-assistant-ios
(`NFCReader` / `NFCWriter` / `NFCNDEFPayload+Additions` / `iOSTagManager`).
`scratch/ladder-corpus/focus-ios` contains no `CoreNFC` / `NFCNDEF` /
`NFCReader` / `NFCTag` references, so ranking followed that NDEF
reader/writer family first, then the rest of the documented public API.

Implemented on Linux:

- NFC Forum NDEF 1.0 text/URI factories, message encode/decode, payload
  properties, and `NSSecureCoding` round-trip
- ISO 7816-4 short APDU construct/parse and response status words
- Table-driven enum / OptionSet raw values and algebra
- `NFCReaderError` codes (macios binding integers 1 / 100 / 200 / 300 / 400)
- Fail-closed reader sessions, tag protocols (async + completion + Result
  overlays), `CardSession`, and `NFCPresentmentIntentAssertion`

Still deferred (24): UIKit scene overlay, `NSUserActivity.ndefMessagePayload`,
Darwin `_BridgedStoredNSError` bridging, and the return-type-overloaded
ISO 7816 `sendCommand` / `sendMiFareISO7816Command` overlays.

The 21 remaining `declared` rows are Swift stdlib `AsyncSequence` combinators
on `CardSession.EventStream` (not CoreNFC-specific behavior).

Top-5 implemented evidence distribution:

| rows | evidence |
| ---: | --- |
| 29 | `test:full/corenfc/tests/agent/NFCErrorTests.swift#testNFCReaderErrorCodeRawValues` |
| 25 | `test:full/corenfc/tests/agent/NFCErrorTests.swift#testNFCReaderErrorStaticCodeProperties` |
| 22 | `test:full/corenfc/tests/agent/NFCTagTests.swift#testISO15693TagCallbacksFailClosed` |
| 21 | `test:full/corenfc/tests/agent/NFCEnumTests.swift#testNFCVASErrorCodeRawValues` |
| 21 | `test:full/corenfc/tests/agent/NFCOptionSetTests.swift#testNFCISO15693RequestFlagAlgebra` |

Enum / OptionSet / C-constant members share table-driven value tests. No other
single test exceeds 40% of the remaining implemented rows (max 5.7%).

## Oracle questions

See `oracle-questions.tsv`. Error-domain string bytes, Darwin raw values beyond
the pinned macios bindings, and every radio/entitlement success path remain
unobserved.
