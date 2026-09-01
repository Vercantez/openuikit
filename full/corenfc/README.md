# CoreNFC on Linux

Portable starting implementation of Apple's public `CoreNFC` module for
OpenUIKit on Linux. The seed is Xcode 26.1 / iPhoneOS 26.1 (587 public
precise identifiers). Hardware, entitlement, privacy-prompt, payment, VAS
wallet, and host-card-emulation paths **fail closed**. They never invent a
successful Apple NFC transaction.

## What is real

- **NDEF records and messages.** `NFCNDEFPayload` / `NFCNDEFMessage` encode and
  parse NFC Forum records, including well-known URI (`U`) and Text (`T`)
  helpers. `length` is the encoded byte count. Chunked records follow the
  public NFC Forum chunking flags.
- **ISO 7816-4 command APDUs.** `NFCISO7816APDU` parses short and extended
  command layouts. `expectedResponseLength` is `-1` when Le is absent.
- **Public enumerations and option sets** with documented raw values
  (`NFCTypeNameFormat`, `NFCNDEFStatus`, `NFCMiFareFamily`, FeliCa polling
  constants, ISO 15693 request/response flags, tag-session polling options,
  VAS mode and status words).
- **`NFCReaderError`** as a `CustomNSError` in `NFCErrorDomain`, with the
  public code groups (reader 1–8, transceive 100, invalidation 200, tag
  command 300, NDEF session 400).
- **Session objects** (`NFCNDEFReaderSession`, `NFCTagReaderSession`,
  `NFCPaymentTagReaderSession`, `NFCVASReaderSession`) that compile, store
  `alertMessage`, and expose `readingAvailable == false`.
- **Tag protocol surface** (`NFCNDEFTag`, `NFCMiFareTag`, `NFCISO7816Tag`,
  `NFCISO15693Tag`, `NFCFeliCaTag`) plus `NFCTag` wrappers. Default
  implementations refuse I/O with `readerErrorUnsupportedFeature`.
- **CardSession / NFCPresentmentIntentAssertion** types: `isSupported` and
  `isEligible` are false; construction and acquire throw `systemNotAvailable`.
- **`NFCWindowSceneEvent`** as a Codable enum. Delivering it to UIKit scenes
  is out of scope (no UIKit dependency).

## Fail-closed boundaries

| API | Linux behavior |
| --- | --- |
| `NFCReaderSession.readingAvailable` | `false` |
| `begin()` | invalidates with `NFCReaderError.readerErrorUnsupportedFeature` |
| `connect(to:)` | throws / completion `readerErrorUnsupportedFeature` |
| Tag transceive, NDEF read/write, VAS, payment | same error |
| `CardSession()` / `startEmulation()` | `CardSession.Error.systemNotAvailable` |
| `NFCPresentmentIntentAssertion.acquire()` | `.systemNotAvailable` |
| `NSUserActivity.ndefMessagePayload` | not applicable (no `NSUserActivity`) |
| UIKit `UIScene.ConnectionOptions.nfcEvent` | not applicable |

No radio is opened, no entitlement is claimed, and no privacy prompt is shown.

## Still deferred / oracle

Exact Apple `NFCErrorDomain` string bytes, several `NFCReaderError` raw
values added after iOS 17, default tag-command retry policy, and whether
`NFCTagReaderSession.init` returns `nil` when reading is unavailable remain
central-oracle questions (`oracle-questions.tsv`).

## Layout

| Path | Role |
| --- | --- |
| `CoreNFC.swift` | Module constants, typealiases, scene event |
| `NFCError.swift` | `NFCReaderError` |
| `NFCNDEF.swift` | NDEF payload/message |
| `NFCFlags.swift` | Enums, option sets, FeliCa/ISO 15693 structs |
| `NFCISO7816.swift` | Command/response APDU |
| `NFCTags.swift` | Tag protocols and command configuration |
| `NFCSessions.swift` | Reader sessions and delegates |
| `NFCVAS.swift` | Value-added services configuration |
| `CardSession.swift` | Card emulation and presentment assertion |
| `tests/agent/CoreNFCRuntime.swift` | Prints `CORENFC_AGENT_RUNTIME_OK` |

Build and evidence are gated by `tests/acceptance/test_host.sh`.
