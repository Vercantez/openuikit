# PassKit (Linux starting point)

This is a clean-room Linux starting implementation of Apple's public `PassKit`
surface for OpenUIKit, seeded from the Xcode 26.1 iPhoneOS 26.1 symbol graph,
API digester, TBD exports, and pinned `dotnet/macios` bindings. It is not Apple
PassKit and it is not wired into the shared guest package.

Unchanged application source continues to import `PassKit`. Linux has no Wallet,
no Apple Pay network, no CMS signature verifier, and no identity-document
hardware. Pass JSON parsing, payment-request models, and enum identities are
real; presentation, provisioning, and pass-signature validation fail closed.

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
  Method 8 (deflate) archives throw `invalidDataError`; CMS signatures are
  not verified.
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
  is `false`; `passes()` is empty; `containsPass` is `false`; `canAddPasses()`
  is `false`. `addPasses` completes with `.didCancelAddPasses`. Throwing library
  APIs (`activate`, issuer-data `PKAddPassesViewController`, service-provider
  data) throw `PKPassKitError.notEntitledError`. `canMakePayments` / `present`
  return `false`. Failable payment-sheet inits return `nil`. `PKSecureElementPass`
  constructs with deactivated empty account fields.
- **SwiftUI overlay.** `PayWithApplePayButton`, `AddPassToWalletButton`,
  `PayLaterView`, and related labels/styles construct as inert `View`
  values. Synthesized SwiftUI.View members are identity no-ops in
  `PassKitViewSurface.swift`.

## Fail-closed / not observed here

- CMS signature and WWDR chain validation (`PKPassKitError.invalidSignature`).
- Deflate (ZIP method 8) pkpass archives.
- Pass library persistence, Secure Element, Felica, and Apple Pay sessions.
- Identity document requests and JPKI certificate/PIN operations (throw
  `JPKIPassContents.Error.resourceNotAvailable`).
- UIKit Wallet chrome: `PKAddPassesViewController` has no UIKit dependency in
  this seed, so `canAddPasses()` is false, failable inits return `nil`, and the
  finish delegate is never fired by a presentation (listed gap).
- `PKPaymentButton` drawing / Apple Pay button artwork. The control constructs
  disabled; `cornerRadius` is a stored value only. UIKit note: paint is not
  modelled on this Foundation host.
- SwiftUI layout, accessibility, and Apple Pay button artwork.

## Lookalikes

Isolated host sources import Foundation only. Types owned by UIKit,
CoreGraphics, Contacts, AddressBook, SwiftUI, and LocalAuthentication are
module-local stand-ins in `PassKitLookalikes.swift` / `PassKitJPKI.swift`,
compiled only when those modules are absent. `tests/agent/PassKitDependencyIdentity.swift`
imports the real `PassKit` and `Foundation` modules for the later EC2 build
and must not be used to justify public substitutes for Foundation-owned types.

See `oracle-questions.tsv` for facts that still need an Apple-runtime probe.
