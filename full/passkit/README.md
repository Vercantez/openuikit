# PassKit (Linux starting point)

This is a clean-room Linux starting implementation of Apple's public `PassKit`
surface for OpenUIKit, seeded from the Xcode 26.1 iPhoneOS 26.1 symbol graph,
API digester, TBD exports, and pinned `dotnet/macios` bindings. It is not Apple
PassKit and it is not wired into the shared guest package.

Unchanged application source continues to import `PassKit`. Linux has no Wallet,
no Apple Pay network, no signed `.pkpass` verifier, and no identity-document
hardware. Payment-request models and enum identities are real; presentation,
provisioning, and pass validation fail closed.

## What is real

- **Payment request model.** `PKPaymentRequest` stores merchant, country,
  currency, networks, capabilities, summary items, and contact-field sets.
  `PKPaymentSummaryItem` keeps label / `NSDecimalNumber` amount / type. Recurring
  items keep interval unit/count and optional dates.
- **Networks and option sets.** `PKPaymentNetwork` raw strings follow the
  exported `PKPaymentNetwork*` identifiers (AmEx, Visa, MasterCard, …).
  `PKMerchantCapability` bits match pinned macios (`threeDSecure = 1<<0`,
  `instantFundsOut = 1<<7`). `PKAddressField` and `PKRadioTechnology` are
  OptionSets with those pinned bits.
- **Enums.** Payment button type/style, authorization status, pass type,
  shipping type, Pay Later display style, and error codes use the macios
  native raw values. `PKPayLater.validate` exists and returns `false`.
- **Fail-closed Wallet / Apple Pay.** `PKPass.init(data:)` throws
  `PassKitPortableError.passValidationUnavailable` instead of accepting
  unsigned bytes. `PKPassLibrary` is empty; `addPasses` reports failure.
  `canMakePayments` / `canAddPasses` / `present` return `false`. Failable
  view-controller inits return `nil`. Delegate defaults complete with
  `.failure`.
- **SwiftUI overlay.** `PayWithApplePayButton`, `AddPassToWalletButton`,
  `PayLaterView`, and related labels/styles construct as inert `View`
  values. Synthesized SwiftUI.View members are identity no-ops in
  `PassKitViewSurface.swift`.

## Fail-closed / not observed here

- Signed pkpass archive and signature validation.
- Pass library persistence, Secure Element, Felica, and Apple Pay sessions.
- Identity document requests and JPKI certificate/PIN operations.
- UIKit Wallet chrome (`PKAddPassesViewController`, payment buttons are
  disabled `UIButton` lookalikes when UIKit is absent).
- SwiftUI layout, accessibility, and Apple Pay button artwork.

## Lookalikes

Isolated host sources import Foundation only. Types owned by UIKit,
CoreGraphics, Contacts, AddressBook, SwiftUI, and LocalAuthentication are
module-local stand-ins in `PassKitLookalikes.swift` / `PassKitJPKI.swift`,
compiled only when those modules are absent. `tests/agent/PassKitDependencyIdentity.swift`
imports the real `PassKit` and `Foundation` modules for the later EC2 build
and must not be used to justify public substitutes for Foundation-owned types.

See `oracle-questions.tsv` for facts that still need an Apple-runtime probe.
