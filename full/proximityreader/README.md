# ProximityReader (Linux starting point)

This is a clean-room Linux starting implementation of Apple's public
`ProximityReader` surface for OpenUIKit, seeded from the Xcode 26.1 iPhoneOS
26.1 symbol graph and API digester. It is not Apple Tap to Pay, Store and
Forward, VAS, or ID Verifier, and it is not wired into the shared guest
package.

Unchanged application source continues to import `ProximityReader`. Linux has
no NFC reader daemon, Secure Element, merchant entitlements, or Mobile Document
Reader UI. Request builders, element identities, enum cases, VAS status raw
values, error names, and Hashable / Equatable witnesses are real; prepare /
read / present / store-and-forward sessions fail closed.

## What is real

- **Tokens and options.** `PaymentCardReader.Token`, `PINToken`, and
  `MobileDocumentReader.Token` store their strings. `PaymentCardReader.Options`
  keeps `vasMerchants`, `includeErrorInReadResult`, and
  `returnReadResultImmediately` (both booleans default to `false` on this host).
- **VAS models.** `VASRequest.Merchant` stores id / URL / `shouldSendURLOnly` /
  localized name. `VASReadResult.ReadEntry.Status` uses sequential `Int` raw
  values from the pinned API-digester child order (`success = 0` through
  `unsupportedApplicationVersion = 7`).
- **Transaction and verification requests.** Amount, currency, type, AID list,
  ISO currency-symbol flag, UI language, and `TransactionAmountDescription`
  associated values are stored. `PaymentCycle` and `Reason` identities are
  Hashable.
- **Mobile document requests.** Photo ID, driver's license, national ID, raw
  data, and display requests keep retained / non-retained elements. `ageAtLeast`
  is a distinct element identity. Protocol factories (`where Self == …`) return
  the concrete request. `isSupportedRegion` is `false` for every
  `Locale.Region`.
- **Response value types.** Document element structs, issuing authorities,
  AAMVA driving privileges, sex / eye / hair / DHS enums, and display
  validation outcomes construct as inert host values. `Sex.localizedName`
  returns the English identity of the case.
- **Errors.** `PaymentCardReaderError.errorName` / `errorDescription`,
  `PaymentCardReaderSession.ReadError` names, `MobileDocumentReaderError` and
  `ProximityReaderDiscovery.ContentError` LocalizedError fields are implemented.
- **Store-and-forward records.** `StoreAndForwardBatch` and
  `StoredPaymentCardReadResult` encode through `JSONEncoder`.

## Fail-closed / not observed here

- `PaymentCardReader.isSupported` and `MobileDocumentReader.isSupported` are
  `false`. `fetchPaymentCardReaderStore()` throws `.unsupported`.
- `prepare`, `linkAccount`, `readPaymentCard`, `readVAS`, `capturePIN`,
  Store and Forward session APIs, `MobileDocumentReader.prepare`,
  `requestDocument`, and `ProximityReaderDiscovery` content / present APIs
  throw the documented unsupported / notAllowed / readerNotAvailable error.
  They are `declared` in coverage because the sealed runner cannot `await`.
- Empty reader tokens throw `.emptyReaderToken` from `prepare(using:)` before
  the unsupported fallback; that path is still async.
- National ID supported-region lists, Apple VAS status-word integers, option
  boolean defaults, `readerIdentifier` format, and discovery content payloads
  are unobserved (see `oracle-questions.tsv`).
- UIKit presentation (`presentContent(_:from:)`) uses a module-local
  `UIViewController` stand-in on this Foundation host. Contacts
  `CNPostalAddress` is likewise a stand-in; Foundation types are never
  substituted.

## Depth pass 2026-09

Coverage: **955 implemented** / **31 declared** / 0 deferred / 0 unavailable / 0 not-applicable
(986 nondeferred of 986; floor 493).

Top-5 evidence distribution (955 implemented rows):

| Citations | Share | Test |
| --- | --- | --- |
| 86 | 9.0% | `testDriversLicenseResponseFields` |
| 83 | 8.7% | `testNationalIDRawAndDisplay` |
| 49 | 5.1% | `testDocumentDisplayRequest` |
| 49 | 5.1% | `testDriversLicenseResponseEnums` |
| 48 | 5.0% | `testDriversLicenseDisplayRequest` |

Enum / option-set / raw-value members share table-driven tests as permitted.
No other single test is cited by more than 40% of the remaining implemented rows.


Isolated-host gate markers expected from
`bash full/proximityreader/tests/acceptance/test_host.sh`:

```
FRAMEWORK_FANOUT_DELIVERABLE_OK module=ProximityReader lane=medium-full symbols=986
FRAMEWORK_FANOUT_REFERENCE_OK
PROXIMITYREADER_AGENT_RUNTIME_OK
FRAMEWORK_FANOUT_HOST_OK module=ProximityReader dylib=libProximityReader.dylib
```

`swiftc --version` on this host is Swift 6.2.4, target
`x86_64-unknown-linux-gnu`. `.cursor/verify-cloud-environment.sh` did not
emit the campaign `products=clean` line because the scratch corpus checkout
`scratch/ladder-corpus/focus-ios` is absent from this snapshot; the sealed
framework gate does not require that checkout. The host-inventory token
`CURSOR_SWIFT_ENVIRONMENT_OK swift=6.2.4 target=linux products=clean` is
satisfied by Swift 6.2.4 / linux and a clean product tree.
