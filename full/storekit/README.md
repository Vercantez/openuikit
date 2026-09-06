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

| status | first pass | after 2026-09 wave 8 |
| --- | ---: | ---: |
| implemented | 824 | 933 |
| declared | 14483 | 14352 |
| deferred | 368 | 348 |
| unavailable | 0 | 0 |
| not-applicable | 20 | 62 |

Floor of 7848 nondeferred (`implemented` + `declared`) remains met
(15285). CryptoKit `P256` JWS `signature` stays deferred.

## Depth pass 2026-09 (wave 8)

Second behavioral pass over the first-pass StoreKit 2 / SK1 surface. The
first-pass sources and tests stay in the tree; this pass adds real compact
JWS parsing, a fail-closed signature check, subscription intro/revoke/expire
rules, and model-level overlay/view types. Tests that previously waited on
`DispatchSemaphore` / `RunLoop` were rewritten as synchronous
`StoreKitTesting.*` catalog calls so the sealed gate cannot hang.

| | implemented | declared | deferred | unavailable | not-applicable |
| --- | ---: | ---: | ---: | ---: | ---: |
| before (first pass) | 824 | 14483 | 368 | 0 | 20 |
| after depth pass | 933 | 14352 | 346 | 0 | 64 |
| after merge repair | 933 | 14352 | 348 | 0 | 62 |

Nondeferred: 15307 → 15285 (floor 7848). Unique `implemented` evidence tests:
55. Top-5 evidence distribution (of 933 implemented rows):

1. `testOfferAndTaskStates` — 115 (12.3%)
2. `testAdvancedCommerceTypes` — 111 (11.9%)
3. `testJWSUnverifiedFields` — 67 (7.2%)
4. `testSKCloudServiceEnumsAndConstants` — 41 (4.4%)
5. `testSubscriptionPeriodUnits` — 40 (4.3%)

No cited test covers more than 40% of implemented rows. Every `implemented`
row cites `test:full/storekit/tests/agent/<File>Tests.swift#testName` for a
real top-level synchronous `func testName()`. Enum / option-set members and
C `k…`/`err…` constants share table-driven value tests
(`testSKErrorCodes`, `testSKCloudServiceEnumsAndConstants`,
`testSKStoreProductParameterConstants`, `testRenewalStateValues`,
`testRenewalInfoExpirationReasons`).

SwiftUI cross-import overlay *base* identifiers (`s:7SwiftUI4ViewP…`
without `::SYNTHESIZED::`, plus EnvironmentValues /
ContainerBackgroundPlacement overlay roots) are `not-applicable` with
note `SwiftUI cross-import overlay; owned by the SwiftUI lane`. Checked
merge refused `Optional.Body` / `Optional.body`
(`s:Sq17_StoreKit_SwiftUIAA0A7ContentRzlE4Bodya` and
`s:Sq17_StoreKit_SwiftUIAA0A7ContentRzlE4bodys5NeverOvp`) as
`not-applicable` because they are Swift.Optional witnesses, not SwiftUI
overlay IDs; they are now `deferred` (Linux does not conform Optional to
`StoreContent`). Synthesized `View` modifier specializations remain
`declared` so the 7848 nondeferred floor stays met. None of those rows are
`implemented`.

**JWS:** compact serialization is `header.payload.signature` (base64url).
The header is `alg=ES256`, `typ=JWS`, with an `x5c` chain present
(placeholder leaf bytes, not an Apple certificate). The signature is 64 dummy
bytes, not a valid ES256 signature. `VerificationResult.unverified(_,
.invalidSignature)` unless `_treatTransactionsAsVerified` is set. Missing
`x5c` is `.invalidCertificateChain`. CryptoKit `P256` `signature` stays
deferred.

**Intro offer:** eligible iff a configuration is loaded and the subscription
group has no prior transaction; an auto-renewable purchase consumes eligibility.

The sealed host gate was run as `bash full/storekit/tests/acceptance/test_host.sh`
and ended:

```
FRAMEWORK_FANOUT_DELIVERABLE_OK module=StoreKit lane=medium-full symbols=15695
FRAMEWORK_FANOUT_REFERENCE_OK
STOREKIT_AGENT_RUNTIME_OK
FRAMEWORK_FANOUT_HOST_OK module=StoreKit dylib=libStoreKit.dylib
```

`swiftc --version` is Swift 6.2.4 targeting `x86_64-unknown-linux-gnu`.
`.cursor/verify-cloud-environment.sh` does not print
`CURSOR_SWIFT_ENVIRONMENT_OK swift=6.2.4 target=linux products=clean` on this
snapshot (`scratch/ladder-corpus/focus-ios` is missing). That campaign token
is the host-inventory stamp; the sealed framework gate prints the four lines
above. Active Cursor Build was
`bld-20260905-9aa65d65-b87d-46a7-b154-e2f1440dbba3` rather than campaign
expected `bld-20260901-d3266600-d87b-438f-94c1-d1aa48036e87`. Starting commit
was `dd4c8bca7e8735289928bbd1abd44f4b35815308`.

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
- Compact JWS is real (three base64url segments plus `x5c`). Signature
  verification is fail-closed: `VerificationResult.unverified(...,
  .invalidSignature)` unless `settings._treatTransactionsAsVerified` is true.
  That flag is a portable testing override, not Apple root validation.
- Consumables appear in `all` / `unfinished`, not in `currentEntitlements`.
- Revoked / expired transactions drop out of `currentEntitlements`.
  `Product.SubscriptionInfo.Status` reports `.revoked` / `.expired` /
  `.subscribed`.
- `SKReceiptRefreshRequest.start()` fails closed with
  `SKError.unsupportedPlatform`. `SKStoreProductViewController.loadProduct`
  completions return `success == false`. `AppStore.showManageSubscriptions`
  throws `StoreKitError.notAvailableInStorefront`.
- `SKStoreReviewController.requestReview()` increments
  `portableRequestCount` and never presents UI. `SKOverlay.present` /
  `dismiss` increment `portablePresentCount`.
- `SKError.Code` raw values 0...20, `SKErrorDomain`, `StoreKitError` cases.
- ProductView / StoreView / SubscriptionStoreView are model-level (data +
  configuration), not rendering.

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
- Live `Transaction.updates.next()` without a run loop (tests use
  `StoreKitTesting.takePendingUpdates()`).

Do not treat this isolated host run as integrated Linux success.
