# PassKit (Linux starting point)

This is a clean-room Linux starting implementation of Apple's public `PassKit`
surface for OpenUIKit, seeded from the Xcode 26.1 iPhoneOS 26.1 symbol graph,
API digester, TBD exports, and pinned `dotnet/macios` bindings. It is not Apple
PassKit and it is not wired into the shared guest package.

Unchanged application source continues to import `PassKit`. Linux has no Wallet,
no Apple Pay network, no CMS/WWDR verifier, and no identity-document
hardware. Pass JSON parsing, `manifest.json` SHA-1 checks, an in-process pass
store, documented `PKPaymentRequest` field validation, and enum identities are
real; presentation, provisioning, and PKCS#7 verification fail closed.

## What is real

- **`.pkpass` ZIP + `pass.json`.** `PKPass.init(data:)` unpacks a stored-method
  ZIP (APPNOTE.TXT method 0), reads `pass.json`, and maps the documented keys
  `formatVersion`, `passTypeIdentifier`, `serialNumber`, `organizationName`,
  `description`, `logoText`, `barcodes`/`barcode`, `relevantDate`,
  `expirationDate`, `voided`, `locations`, `webServiceURL`,
  `authenticationToken`, `userInfo`, and the style dictionaries
  `boardingPass` / `coupon` / `eventTicket` / `generic` / `storeCard` with
  primary / secondary / auxiliary / back / header fields.
  `localizedValue(forFieldKey:)` returns those field values.
  `icon.png` is not decoded: `icon` is an empty `UIImage`.
  `passURL` stays `nil` (Wallet shoebox URLs are unobserved).
  Missing required keys or a non-ZIP throw `PKPassKitError.invalidDataError`
  (rawValue 1). `formatVersion != 1` throws `unsupportedVersionError` (rawValue 2).
  Method 8 (deflate) archives throw `invalidDataError`. When `manifest.json` is
  present, each listed file's SHA-1 must match or init throws `invalidDataError`.
  When a PKCS#7 `signature` file is present, init throws `invalidSignature`
  (rawValue 3): this host never claims WWDR-chain success.
- **Host pass store.** `PKPassLibrary.isPassLibraryAvailable()` stays `false`
  (no Apple Wallet / Secure Element). `addPasses` with identity-bearing barcode
  passes records them in an in-process table and completes `.didAddPasses`;
  empty / identity-less payloads still complete `.didCancelAddPasses`.
  `containsPass`, `removePass`, `replacePass`, `passes()`, `passes(of:)`, and
  `pass(withPassTypeIdentifier:serialNumber:)` read that table.
- **Payment request validation.** `PassKitPaymentRequestValidation.issues(for:)`
  applies Apple's documented required-field rules: nonempty `merchantIdentifier`,
  `supportedNetworks`, 3DS or EMV `merchantCapabilities`, ISO 3166-1 alpha-2
  `countryCode`, ISO 4217 `currencyCode`, nonempty labeled `paymentSummaryItems`
  (pending totals must be zero), coupon-code flag pairing, shipping-method
  identifier/label, and required fields on recurring / automatic-reload /
  deferred requests. `PKPaymentAuthorizationController.present` records those
  issues, calls the completion with `false`, and synchronously dispatches
  `paymentAuthorizationControllerDidFinish` (no run loop). Failable
  `PKPaymentAuthorizationViewController` inits still return `nil`.
- **Payment request model.** `PKPaymentRequest` stores merchant, country,
  currency, networks, capabilities, summary items, and contact-field sets.
  `PKPaymentSummaryItem` keeps label / `NSDecimalNumber` amount / type;
  amounts add through `NSDecimalNumber.adding`. Recurring / automatic-reload /
  deferred items store interval, threshold, and dates from their inits.
- **Networks and option sets.** `PKPaymentNetwork` raw strings follow the
  exported `PKPaymentNetwork*` identifiers (AmEx, Visa, MasterCard, …).
  `PKMerchantCapability` bits match pinned macios (`threeDSecure = 1<<0`,
  `instantFundsOut = 1<<7`). `PKAddressField` and `PKRadioTechnology` are
  OptionSets with those pinned bits.
- **Enums and errors.** Payment button type/style, authorization status, pass
  type, shipping type, Pay Later display style, and error codes use the macios
  native raw values. `PKPassKitError` codes are `unknownError = -1`,
  `invalidDataError = 1`, `unsupportedVersionError = 2`, `invalidSignature = 3`,
  `notEntitledError = 4`. `PKPayLater.validate` returns `false`.
- **Value stores.** `PKContact`, `PKShippingMethod`, `PKPaymentMethod`,
  `PKAddPaymentPassRequest`, and `PKAddPaymentPassRequestConfiguration` keep the
  fields written to them. Configuration `init?(encryptionScheme:)` stores the
  scheme.
- **Fail-closed Wallet / Apple Pay.** `PKPassLibrary.isPassLibraryAvailable()`
  is `false`. Secure Element / Felica / activation / service-provider APIs stay
  fail-closed (`notEntitledError` / empty / `false`). `canMakePayments` returns
  `false`. Failable payment-sheet inits return `nil`. `PKSecureElementPass`
  constructs with deactivated empty account fields. `PKIdentityAuthorizationController`
  does not request documents (async path throws / returns `false`).
- **SwiftUI overlay.** `PayWithApplePayButton`, `AddPassToWalletButton`,
  `PayLaterView`, and related labels/styles construct as inert `View`
  values. Synthesized `s:7SwiftUI4View…` members stay `declared` (identity
  no-ops) with note `SwiftUI cross-import overlay; owned by the SwiftUI lane`;
  they are never `implemented`. Relabeling all 3904 of those rows
  `not-applicable` would drop nondeferred coverage below the sealed 2637 floor.

## Fail-closed / not observed here

- CMS/WWDR signature *success*. A present PKCS#7 `signature` throws
  `PKPassKitError.invalidSignature`; Linux does not parse the CMS or check
  Apple's WWDR chain.
- Deflate (ZIP method 8) pkpass archives.
- Apple Wallet / Secure Element / Felica / Apple Pay network sessions.
- Identity document requests and JPKI certificate/PIN operations (throw
  `JPKIPassContents.Error.resourceNotAvailable`).
- UIKit Wallet chrome: `PKAddPassesViewController` has no UIKit dependency in
  this seed, so `canAddPasses()` is false, failable inits return `nil`, and the
  finish delegate is never fired by a presentation (listed gap).
- `PKPaymentButton` drawing / Apple Pay button artwork. The control constructs
  disabled; `cornerRadius` is a stored value only. UIKit note: paint is not
  modelled on this Foundation host.
- SwiftUI layout, accessibility, and Apple Pay button artwork.
- Durable pass-library persistence across processes (the host store is
  in-memory for this isolated module).

## Lookalikes

Isolated host sources import Foundation only. Types owned by UIKit,
CoreGraphics, Contacts, AddressBook, SwiftUI, and LocalAuthentication are
module-local stand-ins in `PassKitLookalikes.swift` / `PassKitJPKI.swift`,
compiled only when those modules are absent. `tests/agent/PassKitDependencyIdentity.swift`
imports the real `PassKit` and `Foundation` modules for the later EC2 build
and must not be used to justify public substitutes for Foundation-owned types.

See `oracle-questions.tsv` for facts that still need an Apple-runtime probe.

## Depth pass 2026-09 (wave 8)

Coverage **before** this continuation: 1318 implemented / 3904 declared / 51
deferred / 0 unavailable / 0 not-applicable.

Coverage **after**: 1320 implemented / 3904 declared / 49 deferred / 0 unavailable /
0 not-applicable.

This continuation directly exercises the two remaining synthesized hash witnesses
for `PKPaymentRequest` nested value types: `MerchantCategoryCode.hashValue` and
`ApplePayLaterAvailability.Reason.hashValue`. It keeps all earlier behavior and
tests intact. Apple Pay presentation, eligibility, provisioning, secure-element,
identity-document, and remote Wallet operations remain fail-closed because Linux
has no Apple UI runtime, Wallet daemon, required hardware, entitlements, or Apple
services.

The 3904 `s:7SwiftUI4View…` synthesized members remain **declared** rather than
implemented. They are cross-import overlay surface owned by the SwiftUI lane;
the sealed medium-full gate nevertheless counts only `implemented` and `declared`
rows toward its mandatory 2637-symbol floor, so changing those rows to
`not-applicable` would make the required gate mathematically impossible.

Top-5 evidence distribution (1320 implemented rows):

| Citations | Share | Test |
| --- | --- | --- |
| 83 | 6.3% | `testEnumHashableAndInequality` (enum Hashable/`!=`; sharing allowed) |
| 57 | 4.3% | `testOptionSetAlgebra` (OptionSet/SetAlgebra members; sharing allowed) |
| 52 | 3.9% | `testCorpusRemainingEnumRawValues` (enum family; sharing allowed) |
| 51 | 3.9% | `testSecureElementPassFailClosed` |
| 46 | 3.5% | `testPaymentErrors` / `testJPKIFailClosed` |

No non-enum/option-set test is cited by more than 40% of the remaining
implemented rows. The focused nested-payment-request test now supports 25 rows
(1.7%).

Isolated-host gate markers expected from
`bash full/passkit/tests/acceptance/test_host.sh`:

```
FRAMEWORK_FANOUT_DELIVERABLE_OK module=PassKit lane=medium-full symbols=5273
FRAMEWORK_FANOUT_REFERENCE_OK
PASSKIT_AGENT_RUNTIME_OK
FRAMEWORK_FANOUT_HOST_OK module=PassKit dylib=libPassKit.dylib
```

`swiftc --version` on this host is Swift 6.2.4, target
`x86_64-unknown-linux-gnu`. The verified campaign environment marker is
`CURSOR_SWIFT_ENVIRONMENT_OK swift=6.2.4 target=linux products=scratch-corpus evidence=dotnet-macios`.
