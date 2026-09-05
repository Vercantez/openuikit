# silent-frameworks — StoreKit, iCloud KVS, HTTPCookie, CoreImage, ImageIO

Worktree `agent/silent-frameworks`. No UI chrome: these modules exist so
ladder apps compile on Linux. Nothing here changes a scene pixel.

## Before / after

| gate | before | after |
|---|---|---|
| Catalyst | 124/124 | 124/124 (no render rule) |
| iOS suite | 112/113 (`corner_radius`) | 112/113 |
| Real-app floors | 99.137 / 98.535 / 98.548 / 99.469 / 98.639 / 98.133 / 97.516 / 99.511 / 82.192 / 99.760 / 99.689 / 85.393 | unchanged |
| HTTPCookie Apple golden | absent | **16/16** exact vs Apple Foundation 2026-09-05 |
| ImageIO PNG | absent | Apple NSImage vs port, 16×12 gradient, **identical RGBA8** |
| ImageIO JPEG | absent | same file, **maxDelta=2** (PIXEL_TOL 6) |
| CIGaussianBlur extent | absent | pad **3 × inputRadius** (SE 2x / iOS 26.1) |

## 1. StoreKit (fail-closed)

Linux product/module `StoreKit`; Darwin `OpenUIKitStoreKit` so XCTest still
sees Apple's StoreKit. Call shapes grepped from `scratch/ladder-corpus`
2026-09-05 (Hackers `SupportPurchaseRepository`, pocket-casts `IAPHelper`,
Signal `BackupSubscriptionManager`, Telegram `InAppPurchaseManager`,
simplenote `StoreManager`, ProtonMail `purchase(options:)`, nextcloud review).

Stubs (every path fail-closed):

| API | behaviour |
|---|---|
| `Product.products(for:)` | `[]` |
| `Product.purchase()` / `purchase(options:)` | throws `StoreKitError.unknown` |
| `AppStore.sync()` | throws `StoreKitError.unknown` |
| `AppStore.canMakePayments` | `false` |
| `Transaction.updates` / `currentEntitlements` | empty `AsyncStream` |
| `Transaction.latest` / `currentEntitlement` | `nil` |
| `Transaction.finish()` | no-op |
| `SKPaymentQueue.canMakePayments()` | `false` |
| `SKPaymentQueue.add(_: SKPayment)` | `.failed` + `SKError.paymentNotAllowed` |
| `SKPaymentQueue.restoreCompletedTransactions()` | observer `…FailedWithError` `.unknown` |
| `SKProductsRequest.start()` | empty products, invalid IDs = requested set, then `requestDidFinish` |
| `SKStoreReviewController.requestReview` / `in:` | no-op |
| `AppStore.requestReview(in:)` | no-op |
| `Storefront.current` | `nil` |
| `VerificationResult` | `.verified` / `.unverified` |

Open (types not stubbed; list so a later branch can add them without colliding):
`Product.priceFormatStyle`, `Product.subscription` / `SubscriptionInfo`,
SwiftUI StoreKit views, `Product.PurchaseOption` payload cases.

## 2. NSUbiquitousKeyValueStore

`OpenUIKitUbiquitousKeyValueStore` is UserDefaults suite
`OpenUI.NSUbiquitousKeyValueStore`. Linux `typealias NSUbiquitousKeyValueStore`
plus the notification name constants. Darwin apps keep Apple's Foundation
type; tests use the portable class.

Hackers `BookmarksRepository` / `ReadStatusRepository`: `.default`,
`didChangeExternallyNotification`, `data(forKey:)`, `set(_:forKey:)`,
`synchronize()`. Local writes do not post `didChangeExternally` (Apple only
posts that for cloud replicas; same honesty as `full/foundation/UbiquitousKeyValueStore.swift`).

## 3. HTTPCookieStorage

Implementation already lived in `full/foundation/URLSession.swift`. This
branch wraps that file with `-D HTTPCOOKIE_PORT` so the HOST oracle can
compile just the cookie types (no new guest source, no pin bump).

Apple Foundation 2026-09-05 native differential
(`foundation-httpcookie-apple-2026-09-05.txt`, 16 rows,
sha256 `8d4c1d5f0afae89aeca967d54bea17d3e9d4245b028c5b5bd2b1f1d66ee4ea07`):

Rules read off Apple:

- `HTTPCookie(properties:)` keeps a path that does not start with `/`
  (`init.relative-path` `path=no-slash`).
- Set-Cookie `Domain=example.test` stores `.example.test`.
- Default path for `https://www.example.test/account/login` is `/account`.
- `Expires=Wed, 21 Oct 2015 07:28:00 GMT` → `1445412480.0`.
- `HTTPCookieStorage()` is a dummy (`cookies == nil`); the golden uses
  `.shared` with `ouik-sf-*` names.
- Host-only `example.test` does not match `sub.example.test`; dotted
  `.example.test` does. Path `/secure` does not match `/other`.
- `requestHeaderFields` **preserves input order** (not RFC 6265 path-length
  sort): `[domain, host]` → `domain=two; host=one`.
- Expired `setCookie` / `setCookies` delete the matching live cookie.

Port `HTTPCookieStorage()` remains an isolated in-memory jar (Linux has no
cookie disk). Corpus uses `.shared`.

## 4. CoreImage

Linux module `CoreImage`; Darwin `OpenUIKitCoreImage`. Types: `CIImage`,
`CIContext`, `CIFilter`, `CIColor`, `CIFilter.gaussianBlur()`,
`CIFilter(name: "CIGaussianBlur")`, `CIFilter.qrCodeGenerator()`
(**outputImage nil**, fail-closed), `CIConstantColorGenerator`.

`import CoreImage.CIFilterBuiltins` is a clang submodule of Apple's
CoreImage. A mixed Swift/C target named `CoreImage` shadows XCTest on Darwin
and was dropped. Pocket Casts TV `QRCodeView` still needs that import (open).

**MEASURED** ciblurprobe, iPhone SE 2x / iOS 26.1,
`SIM_DEVICE_SUFFIX=-silent-frameworks`:

| radius | extent | pad |
|---|---|---|
| 1 | `(-3,-3,38,38)` | 3 |
| 2 | `(-6,-6,44,44)` | 6 |
| 10 | `(-30,-30,92,92)` | 30 |

Rule: pad = **3 × inputRadius** on each side.

Radius 2 crop of the 32×32 known image (white 8×8 at (12,12) on opaque black):
centre (16,16) **243**, just-outside (10,16) **128**, origin α **91**.

Impulse (one white pixel at (16,16), radius 2) row y=16:
`2,6,17,30,43,52,56,52,…` peak 56, support 6 = 3×radius. The port's
separable FIR is recovered from that axis. RGB of the 8×8 crop is **not**
within PIXEL_TOL 6 of the three iOS samples (centre was 28/255 off with that
kernel) — off-axis kernel is an open question. Extent matches.

## 5. ImageIO

Linux module `ImageIO`; Darwin `OpenUIKitImageIO`. `CGImageSource` /
`CGImageDestination` for PNG and JPEG on CQuartz `QZImageDecodeRGBA` /
`QZImageEncodePNG` / `QZImageEncodeJPEG`.

Darwin CGContext rejects straight-alpha `.last` (GoldenDarkModeTests uses
`.premultipliedLast`). The Darwin CGImage wrapper premuls / un-premuls.

**MEASURED** 2026-09-05, 16×12 gradient:

- PNG: Apple `NSImage` (Apple ImageIO) vs port — **identical RGBA8**.
- JPEG quality 0.95: **maxDelta=2**.

Thumbnails return the decoded frame (no resample). Corpus
`kCGImageSourceThumbnailMaxPixelSize` is an open question.

## Darwin module names

A target named `ImageIO` / `CoreImage` / `StoreKit` in this package makes
`import ImageIO` inside XCTest/XCUIAutomation resolve to the port, which
needs `CQuartz` and breaks `swift test`. Package.swift picks the literal
Apple names only on Linux (`#if os(Linux)`).

## Verify

- `swift test --filter StoreKitTests --filter ImageIOTests --filter CoreImageTests --filter UbiquitousKeyValueStoreTests` — all passed.
- `python3 full/foundation/tests/test_foundation_formatters.py` — HTTPCookie 16 rows pinned.
- Cookie HOST: Apple golden + port `cmp` exact.
- Catalyst / iOS suite / real-app / Linux openrender: recorded in
  `docs/REAL_APP_TEST.md`.
- No `Package.resolved`, no pin files, no files outside `uikit/` except
  `full/foundation/` for the cookie golden.

## Open questions

- `import CoreImage.CIFilterBuiltins` (Telegram MediaEditor, Pocket Casts TV).
- CIGaussianBlur off-axis kernel (impulse axis recovered, 8×8 crop not
  PIXEL_TOL 6).
- `CGImageSourceCreateThumbnailAtIndex` max-pixel-size resampling.
- `HTTPCookieStorage()` on Apple is a dummy; the port's `init()` is a working
  in-memory jar.
- StoreKit `Product.subscription` / SwiftUI store views / purchase option
  payloads.
- Guest `URLSession.swift` `_HTTPDateParser` still uses `String.contains("-")`
  (pre-existing, not this branch).
