# StoreKit for Linux

This directory is a clean-room starting implementation of Apple's public
`StoreKit` module for the isolated wave-5 host gate. Isolated `swiftc`
produces `libStoreKit.dylib` with **Foundation only**. UIKit and SwiftUI are
absent; signatures that name those modules use module-local lookalikes.
`tests/agent/StoreKitDependencyIdentity.swift` is the later EC2 probe that
imports real Foundation (and, when those modules exist, UIKit/SwiftUI).

This is not App Store behavioral parity and not an integrated Linux product.

**Reference dossier:** `full/storekit/reference/` from origin/main (wave-5
seed `7147ef0e`, PR #115). Immutable seed files were not rewritten.

## Coverage (measured)

| status | before | after |
| --- | ---: | ---: |
| implemented | 26 | 824 |
| declared | 15084 | 14483 |
| deferred | 565 | 368 |
| not-applicable | 20 | 20 |

Floor of 7848 nondeferred (`implemented` + `declared`) remains met
(15307). Target for this lane was `implemented >= 800` with the
Product / Transaction / VerificationResult / AppStore / SKPaymentQueue
families nondeferred (CryptoKit `P256` JWS `signature` stays deferred).

## What is real (isolated host)

There is no App Store on Linux. Purchases run through a **local testing
store** modelled on Xcode StoreKit Testing `.storekit` JSON
(`identifier`, `products`, `subscriptionGroups`,
`nonRenewingSubscriptions`, `settings`). Load it with
`StoreKitTesting.loadConfiguration(json:)` / `(data:)` / `(from:)`.

- Fail-closed with no configuration: `Product.products(for:)` /
  `purchase` / `AppStore.sync()` throw `StoreKitError.notAvailableInStorefront`
  (Apple: the function isn’t available for this storefront).
  `SKPaymentQueue.canMakePayments()` is `false`; `add(_:)` notifies
  `.failed` with `SKError.paymentNotAllowed` (raw 4).
- With a loaded configuration: catalog lookup, SK1/SK2 purchases,
  `Transaction.currentEntitlements` / `.updates` / `.all` / `.unfinished` /
  `.latest(for:)` / `finish()`, `Storefront.current`, SKProductsRequest,
  SKProduct price formatting via `NumberFormatter` + the configuration
  locale, `Product.SubscriptionInfo` / `RenewalState`.
- JWS compact serialization is unsigned (`alg: none`). Results are
  `VerificationResult.unverified(..., .invalidSignature)` unless
  `settings._treatTransactionsAsVerified` is true. Apple's public
  `.storekit` schema does not carry certificates.
- Consumables appear in `all` / `unfinished`, not in `currentEntitlements`.
- `SKStoreReviewController.requestReview()` increments
  `portableRequestCount` and never presents UI.
- `SKError.Code` raw values 0...20, `SKErrorDomain`, `StoreKitError` cases.
- Source-compatible StoreKit SwiftUI overlay types as inert `View`
  lookalikes.

## Fail-closed / deferred

- No App Store, Music, SKAdNetwork postback, or receipt daemon.
- No purchase sheet, manage-subscriptions sheet, offer-code sheet, or
  review prompt UI (`ui` risk).
- CryptoKit `P256` JWS signature fields on `VerificationResult`
  (not a seed dependency).
- Overlay/view-controller presentation against a real `UIWindowScene`.
- Darwin `SKCloudServiceCapability` bit assignments beyond the named
  statics used for a compiling OptionSet.
- Apple numeric storefront identifiers (testing store uses the locale
  region, e.g. `USA`).

Do not treat this isolated host run as integrated Linux success.
