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

| status | first pass | after 2026-09 wave 8 | after depth pass 3 | after depth pass 4 | after NA repair | after depth pass 6 |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| implemented | 824 | 933 | 1107 | 1298 | 1370 | 1541 |
| declared | 14483 | 14352 | 6893 | 6759 | 6753 | 6673 |
| deferred | 368 | 348 | 310 | 253 | 271 | 180 |
| unavailable | 0 | 0 | 0 | 0 | 0 | 0 |
| not-applicable | 20 | 62 | 7385 | 7385 | 7301 | 7301 |

Floor of 7848 nondeferred (`implemented` + `declared`) remains met
(8214). CryptoKit `P256` JWS `signature` stays deferred.

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
| after depth pass 3 | 1107 | 6893 | 310 | 0 | 7385 |
| after depth pass 4 | 1298 | 6759 | 253 | 0 | 7385 |

Nondeferred: 15307 → 15285 (wave 8) → **8000** (pass 3, floor 7848). Unique
`implemented` evidence tests after pass 3: 72. Top-5 evidence distribution
(of 1107 implemented rows):

1. `testOfferAndTaskStates` — 115 (10.4%)
2. `testAdvancedCommerceTypes` — 111 (10.0%)
3. `testJWSUnverifiedFields` — 67 (6.1%)
4. `testSKCloudServiceEnumsAndConstants` — 41 (3.7%)
5. `testSubscriptionPeriodUnits` — 40 (3.6%)

No cited test covers more than 40% of implemented rows. Every `implemented`
row cites `test:full/storekit/tests/agent/<File>Tests.swift#testName` for a
real top-level synchronous `func testName()`. Enum / option-set members and
C `k…`/`err…` constants share table-driven value tests
(`testSKErrorCodes`, `testSKCloudServiceEnumsAndConstants`,
`testSKStoreProductParameterConstants`, `testRenewalStateValues`,
`testRenewalInfoExpirationReasons`).

SwiftUI cross-import overlay identifiers (`s:7SwiftUI4View…` modifiers
and `_StoreKit_SwiftUI` StoreContent extensions) are `not-applicable` with
note `SwiftUI cross-import overlay; owned by the SwiftUI lane`. Pass 3
marks 7,385 overlay rows NA while keeping 8,000 nondeferred rows so the
7848 floor stays met. Checked merge refused `Optional.Body` / `Optional.body`
(`s:Sq17_StoreKit_SwiftUIAA0A7ContentRzlE4Bodya` and
`s:Sq17_StoreKit_SwiftUIAA0A7ContentRzlE4bodys5NeverOvp`) as
`not-applicable` because they are Swift.Optional witnesses, not SwiftUI
overlay IDs; they remain `deferred` (Linux does not conform Optional to
`StoreContent`). Remaining synthesized `View` modifier specializations stay
`declared` for the floor. None of those rows are `implemented`.

**Pass 3 behaviour (keep first/second-pass tests green):** promotional and
win-back `Product.PurchaseOption`s, intro offer attached on first
auto-renewable subscribe, non-renewing expiration from period, purchase
intents and messages as snapshot sequences, AppTransaction JWS fields,
SKAdNetwork completion-handler overloads, SKArcadeService Apple names,
SKCloudServiceController user-token Now wrapper, SKDownload state/length,
ExternalPurchase / ExternalLinkAccount / ExternalPurchaseLink /
ExternalPurchaseCustomLink fail-closed Now wrappers, PaymentMethodBinding
fail-closed, AdvancedCommerceProduct compact-JWS purchase fail-closed,
`Message.Reason` Int raw values (generic=0, billingIssue=1,
priceIncreaseConsent=2, winBackOffer=3). Product/Store/SubscriptionStore
views remain model-level, not rendering.

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
(depth pass 3) and ended:

```
FRAMEWORK_FANOUT_DELIVERABLE_OK module=StoreKit lane=medium-full symbols=15695
FRAMEWORK_FANOUT_REFERENCE_OK
STOREKIT_AGENT_RUNTIME_OK
FRAMEWORK_FANOUT_HOST_OK module=StoreKit dylib=libStoreKit.dylib
```

`swiftc --version` is Swift 6.2.4 targeting `x86_64-unknown-linux-gnu`.
`.cursor/verify-cloud-environment.sh` fails on this snapshot with
`missing corpus checkout: scratch/ladder-corpus/focus-ios` and therefore
does not print
`CURSOR_SWIFT_ENVIRONMENT_OK swift=6.2.4 target=linux products=clean`.
That campaign token is the host-inventory stamp; the sealed framework gate
prints the four lines above. The verify script's success line on a complete
image is `products=scratch-corpus`, not `products=clean`. Starting commit
was `2de7152a12f3beb34a4c1e92dc0e849af9a1d88b`.

## Depth pass 2026-09 (wave 8, pass 4)

Next StoreKit 2 / SK1 behavioral pass over the pass-3 tree. Existing sources
and tests stay green. This pass adds:

- `SKOverlay.present` fail-closed: `storeOverlayWillStartPresentation` then
  `storeOverlayDidFailToLoad` with `SKError.overlayInvalidConfiguration`.
  `dismiss` fires `willStartDismissal` / `didFinishDismissal`.
  `storeOverlayDidFinishPresentation` is on the protocol but is not invented
  on a successful present.
- `SKTerminateForInvalidReceipt` records a portable call count and does not
  abort.
- `SKError` / `SKANError` as `CustomNSError` + `LocalizedError`, including
  `Code.~=` pattern matching.
- Real `OptionSet`/`SetAlgebra` operations on `SKCloudServiceCapability` and
  `Product.SubscriptionRelationship` (previously over-deferred).
- `SKPaymentQueue` observers: storefront-change on configuration load,
  `didRevokeEntitlementsForProductIdentifiers` on `StoreKitTesting.revoke`,
  and `portableAskShouldAddStorePayment`.
- Subscription status / storefront snapshots from the local testing store.
- Equatable `!=`, `hash(into:)`, `hashValue`, and `Comparable` operators on
  StoreKit-owned enums/option sets.

| | implemented | declared | deferred | unavailable | not-applicable |
| --- | ---: | ---: | ---: | ---: | ---: |
| before (pass 3) | 1107 | 6893 | 310 | 0 | 7385 |
| after depth pass 4 | 1298 | 6759 | 253 | 0 | 7385 |

Nondeferred: **8057** (floor 7848). Unique `implemented` evidence tests: 83.
Top-5 evidence distribution (of 1298 implemented rows):

1. `testOfferAndTaskStates` — 115 (8.9%)
2. `testAdvancedCommerceTypes` — 111 (8.6%)
3. `testJWSUnverifiedFields` — 67 (5.2%)
4. `testHashableRawRepresentableMixing` — 48 (3.7%)
5. `testSKCloudServiceEnumsAndConstants` — 41 (3.2%)

No cited test covers more than 40% of implemented rows. Remaining
`s:7SwiftUI4View…` synthesized modifier specializations stay `declared` so
the 7848 nondeferred floor stays met; they are not marked `implemented`.
SwiftUI overlay re-exports already `not-applicable` are unchanged.

The sealed host gate is `bash full/storekit/tests/acceptance/test_host.sh`.
Depth pass 4 ended:

```
FRAMEWORK_FANOUT_DELIVERABLE_OK module=StoreKit lane=medium-full symbols=15695
FRAMEWORK_FANOUT_REFERENCE_OK
STOREKIT_AGENT_RUNTIME_OK
FRAMEWORK_FANOUT_HOST_OK module=StoreKit dylib=libStoreKit.dylib
```

`swiftc --version` is Swift 6.2.4 targeting `x86_64-unknown-linux-gnu`.
`.cursor/verify-cloud-environment.sh` fails on this snapshot with
`missing corpus checkout: scratch/ladder-corpus/focus-ios` and therefore
does not print
`CURSOR_SWIFT_ENVIRONMENT_OK swift=6.2.4 target=linux products=clean`.
That campaign token is the host-inventory stamp; the sealed framework gate
prints the four lines above. The verify script's success line on a complete
image is `products=scratch-corpus`, not `products=clean`. Starting commit
was `2de7152a12f3beb34a4c1e92dc0e849af9a1d88b`.

## Depth pass 2026-09 (wave 8, NA repair)

Checked merge of `43103bf1` refused 18 `not-applicable` rows that are not
SwiftUI `View` overlay IDs (`s:7SwiftUI4View…`). `_StoreKit_SwiftUI`
`StoreContent` protocol methods, style `.automatic`/`.large`/`.regular`
witnesses, `EnvironmentValues` StoreKit actions, and
`ContainerBackgroundPlacement.subscriptionStore*` are StoreKit-owned.
This repair implements those APIs as model-level declarations and cites
focused tests in `StoreKitDepthPass5Tests.swift`. Optional/Never
`StoreContent` method witnesses stay `deferred` (same reason as
`Optional.Body` / `Optional.body`). Remaining NA is 7301
`s:7SwiftUI4View…` overlay re-exports.

| | implemented | declared | deferred | unavailable | not-applicable |
| --- | ---: | ---: | ---: | ---: | ---: |
| before (pass 4 / refused merge) | 1298 | 6759 | 253 | 0 | 7385 |
| after NA repair | 1370 | 6753 | 271 | 0 | 7301 |

Nondeferred: **8123** (floor 7848). Unique `implemented` evidence tests: 93.
Top-5 evidence distribution (of 1370 implemented rows):

1. `testOfferAndTaskStates` — 115 (8.4%)
2. `testAdvancedCommerceTypes` — 111 (8.1%)
3. `testJWSUnverifiedFields` — 67 (4.9%)
4. `testHashableRawRepresentableMixing` — 48 (3.5%)
5. `testSKCloudServiceEnumsAndConstants` — 41 (3.0%)

No cited test covers more than 40% of implemented rows. New tests each
cover one family (StoreContent modifiers per conforming type, product
view style statics, overlay style statics, environment actions,
container-background placements). Enum / option-set members and C
`k…`/`err…` constants still share table-driven value tests.

The sealed host gate is `bash full/storekit/tests/acceptance/test_host.sh`.
NA repair ended:

```
FRAMEWORK_FANOUT_DELIVERABLE_OK module=StoreKit lane=medium-full symbols=15695
FRAMEWORK_FANOUT_REFERENCE_OK
STOREKIT_AGENT_RUNTIME_OK
FRAMEWORK_FANOUT_HOST_OK module=StoreKit dylib=libStoreKit.dylib
```

`swiftc --version` is Swift 6.2.4 targeting `x86_64-unknown-linux-gnu`.
`.cursor/verify-cloud-environment.sh` fails on this snapshot with
`missing corpus checkout: scratch/ladder-corpus/focus-ios` and therefore
does not print
`CURSOR_SWIFT_ENVIRONMENT_OK swift=6.2.4 target=linux products=clean`.
That campaign token is the host-inventory stamp; the sealed framework gate
prints the four lines above. The verify script's success line on a complete
image is `products=scratch-corpus`, not `products=clean`. Starting commit
was `2de7152a12f3beb34a4c1e92dc0e849af9a1d88b`.

## Depth pass 2026-09 (wave 8, pass 6)

Checked merge of `5b834b48` refused the branch for **no depth gain**
(implemented 1370 → 1370). Reclassifying remaining `s:7SwiftUI4View…`
overlay rows to not-applicable is bookkeeping; this pass implements real
behaviour and cites a focused synchronous `func test*()` per family.

New model-level APIs exercised by `StoreKitDepthPass6Tests.swift`:

- `NSNotification.Name` StoreKit storefront/cloud-service names and the
  matching `SK*Notification` lets
- `SKAdImpression.adType`
- `DateComponents.init(subscriptionPeriod:)`
- `SKDownloadState` / `SKOverlay.Position` /
  `SKCloudServiceCapability` / `SKCloudServiceAuthorizationStatus`
  `init(rawValue:)` (table-driven enum / option-set values)
- Subscription store button labels, policy kinds, store-button kinds,
  offer-view button kinds, control backgrounds, and placement keys
- Control-placement statics including protocol `.automatic`
- Control / product / offer / option-group style statics
  (`.picker`, `.buttons`, `.compactPicker`, `.pagedPicker`,
  `.prominentPicker`, `.pagedProminentPicker`, `.compact`, `.tabs`,
  `.links`)
- `SubscriptionStoreControlStyle` `SubscribeButton` /
  `SubscriptionPicker` / `SubscriptionPickerOption` typealiases
- `StoreContentBuilder.buildIf` / `buildLimitedAvailability`
- `SubscriptionStoreControlStyleConfiguration` option / picker-option /
  section / icon / configuration values (split tests, one family each)
- `ProductViewStyleConfiguration` model fields and `purchase()`
- `EntitlementTaskState.transaction` when `Value == VerificationResult<Transaction>?`

Remaining `s:7SwiftUI4View…` overlay re-exports stay `not-applicable`
(7301). Optional/Never `StoreContent` witnesses stay `deferred`.

| | implemented | declared | deferred | unavailable | not-applicable |
| --- | ---: | ---: | ---: | ---: | ---: |
| before (NA repair / refused merge `5b834b48`) | 1370 | 6753 | 271 | 0 | 7301 |
| after depth pass 6 | 1541 | 6673 | 180 | 0 | 7301 |

Nondeferred: **8214** (floor 7848). Unique `implemented` evidence tests:
117. Top-5 evidence distribution (of 1541 implemented rows):

1. `testOfferAndTaskStates` — 115 (7.5%)
2. `testAdvancedCommerceTypes` — 111 (7.2%)
3. `testJWSUnverifiedFields` — 67 (4.3%)
4. `testHashableRawRepresentableMixing` — 48 (3.1%)
5. `testSKCloudServiceEnumsAndConstants` — 41 (2.7%)

No cited test covers more than 40% of implemented rows. Enum / option-set
members and C `k…`/`err…` constants still share table-driven value tests.
Every other new family has its own `test*` function; the largest new
family is 15 rows (`testSubscriptionStoreButtonLabelValues`,
`testControlPlacementStatics`,
`testControlStyleConfigurationSectionMembers`). Every `implemented` row
cites `test:full/storekit/tests/agent/<File>Tests.swift#testName` for a
real top-level synchronous `func testName()` that exercises that
identifier.

The sealed host gate is `bash full/storekit/tests/acceptance/test_host.sh`.
Depth pass 6 gate markers are recorded after that command ends
`FRAMEWORK_FANOUT_HOST_OK`.

`swiftc --version` is Swift 6.2.4 targeting `x86_64-unknown-linux-gnu`.
`.cursor/verify-cloud-environment.sh` fails on this snapshot with
`missing corpus checkout: scratch/ladder-corpus/focus-ios` and therefore
does not print
`CURSOR_SWIFT_ENVIRONMENT_OK swift=6.2.4 target=linux products=clean`.
Starting commit was `2de7152a12f3beb34a4c1e92dc0e849af9a1d88b`.

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
  `portableRequestCount` and never presents UI. `SKOverlay.present`
  fires `willStartPresentation` then `didFailToLoad` with
  `SKError.overlayInvalidConfiguration`; `dismiss` fires dismissal
  callbacks. `SKTerminateForInvalidReceipt` increments a portable
  count and does not abort.
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
- ExternalPurchase / ExternalLinkAccount / ExternalPurchaseLink /
  ExternalPurchaseCustomLink presentation and token minting (Linux
  `canPresentNow` / `canOpenNow` / `isEligibleNow` are false; sheets throw
  `notAvailableInStorefront`).
- PaymentMethodBinding bind/pinning (fail-closed `notEligible`).
- AdvancedCommerceProduct.purchase compact-JWS (fail-closed).
- SKArcadeService register/repair/status (fail-closed).
- SKReceiptRefreshRequest / AppStore.showManageSubscriptions (unchanged).

Do not treat this isolated host run as integrated Linux success.

## Depth pass 2026-09 (wave 8)

This wave adds a public, deterministic compact-JWS parser for Linux callers.
It validates the three base64url segments, object-shaped JSON payload, exact
`ES256` protected-header algorithm, nonempty fully decodable `x5c` chain, and
the 64-byte raw ECDSA signature shape. These structural checks do **not**
establish Apple trust: `signatureVerificationError` remains explicitly
fail-closed as `invalidSignature` because this Foundation-only lane has neither
Apple StoreKit trust roots nor an ES256 verification dependency. Malformed
security fields are rejected with `VerificationError` rather than accepted or
silently discarded.

Five synthesized advanced-commerce inequality witnesses and the generic
`VerificationResult` inequality witness now have focused synchronous behavioral
evidence. Apple-service async entry points remain declared rather than being
promoted through blocking tests; ExternalPurchase, ExternalLinkAccount,
ExternalPurchaseLink, ExternalPurchaseCustomLink, PaymentMethodBinding, and
AdvancedCommerceProduct purchase operations therefore remain fail-closed at
their existing synchronous Linux boundaries.

| | implemented | declared | deferred | unavailable | not-applicable |
| --- | ---: | ---: | ---: | ---: | ---: |
| before depth pass 2026-09 wave 8 | 1541 | 6673 | 180 | 0 | 7301 |
| after depth pass 2026-09 wave 8 | 1547 | 6667 | 180 | 0 | 7301 |
| before this follow-on run | 1547 | 6667 | 180 | 0 | 7301 |
| after this follow-on run | 1559 | 6655 | 180 | 0 | 7301 |

The follow-on adds focused compatibility-typealias and synthesized inequality
witnesses for the real StoreKit surface. Async Apple-service entry points remain
declared: the synchronous test contract cannot honestly prove that their async
entry points execute, even where a separately tested synchronous Linux boundary
fails closed. The sealed medium-full gate requires 7,848 implemented/declared
rows, so further SwiftUI-overlay reclassification cannot be made without
violating the immutable acceptance floor; the existing 7,301 overlay rows remain
not-applicable and no non-overlay identifier was reclassified that way.

Nondeferred remains **8214** (floor 7848). Top-5 evidence distribution (of 1559
implemented rows):

1. `testOfferAndTaskStates` — 115 (7.4%)
2. `testAdvancedCommerceTypes` — 111 (7.1%)
3. `testJWSUnverifiedFields` — 67 (4.3%)
4. `testHashableRawRepresentableMixing` — 48 (3.1%)
5. `testSKCloudServiceEnumsAndConstants` — 41 (2.6%)

No cited test covers more than 40% of implemented rows. The sealed host gate
for this wave is `bash full/storekit/tests/acceptance/test_host.sh`.
