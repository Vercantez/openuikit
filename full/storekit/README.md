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

## What is real (isolated host)

- Fail-closed payments: `SKPaymentQueue.canMakePayments()` is `false`;
  `add(_:)` notifies observers with a `.failed` transaction and
  `StoreKitPortableError.paymentsUnavailable`.
- Fail-closed StoreKit 2 catalog: `Product.products(for:)` throws
  `productUnavailable`. `purchase` throws `paymentsUnavailable`.
- Fail-closed SKAdNetwork postbacks and impression start/end.
- `SKRequest.start()` delivers `serviceUnavailable` to the delegate.
- `SKStoreReviewController.requestReview()` increments
  `portableRequestCount` and never presents UI.
- `AppStore.sync()` / manage-subscription APIs throw `serviceUnavailable`.
- `Storefront.current` and `Transaction.latest(for:)` are nil.
- `SKError.Code` raw values 0...20, `SKErrorDomain`, `StoreKitError` cases.
- `Product.PurchaseOption` factories and `Product.SubscriptionPeriod.Unit`
  ordering.
- Source-compatible StoreKit SwiftUI overlay types (`ProductView`,
  `StoreView`, `SubscriptionStoreView`, …) as inert `View` lookalikes.
  Inherited SwiftUI `View` modifiers compile and return `EmptyView()`.

The original `StoreKit.swift` fail-closed payment/product/review paths are
kept. Type kinds that disagreed with the sealed graph (`SKAdNetwork` class,
`SKStoreReviewController` class, `Product.PurchaseOption` struct) were
corrected in place.

## Fail-closed / deferred

- No App Store, Music, SKAdNetwork postback, or receipt daemon.
- No purchase sheet, manage-subscriptions sheet, offer-code sheet, or
  review prompt UI (`ui` risk).
- SwiftUI.Transaction modifiers that collide with `StoreKit.Transaction`
  on this host.
- CryptoKit `P256` JWS signature fields on `VerificationResult`.
- Overlay/view-controller presentation against a real `UIWindowScene`.
- Darwin `SKCloudServiceCapability` bit assignments beyond the named
  statics used for a compiling OptionSet.
- Optional/Never `StoreContent` overlay members (Swift stdlib types).

Do not treat this isolated host run as integrated Linux success.
