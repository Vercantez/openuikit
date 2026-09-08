# Eidolon Objective-C build boundary

Date: 2026-09-07. Unmodified inputs: `artsy/eidolon`
`44486ed9149f16b3eb3a5e687f99ae078309f4fe`. Compiler: Xcode 26.1
Apple Clang, arm64 macOS route (b), macOS 26.1 SDK.
This is a syntax census of the three original `.m` units, not an app
link, a guest execution, or an iOS oracle capture.

The JSON companion records every exact command, diagnostic, exit code,
and source SHA-256. Each command uses `-fsyntax-only -fobjc-arc -fmodules`,
with a module cache under `/tmp/eidolon-launch-objc/`.

## Separating generated header layout from framework errors

The initial ingested package exposed only `include`, while copied headers
retained `include/Kiosk/App/`. The three original `.m` files use quoted
sibling imports such as `#import "CreditCardValidation.h"`; the initial
probe therefore measured **3 missing local headers across 3 units**.
The initial tree also omitted the original companion
`Kiosk/Supporting Files/PodsBridgingHeader.h` imported by BridgingHeader.h.

**Both generation bugs are fixed.** The ingest tool now recursively
follows existing local quoted headers and emits the two measured Clang
search paths, `include/Kiosk/App` and `include/Kiosk/Supporting Files`.
The regenerated tree carries the original PodsBridgingHeader.h. A fresh
syntax run using those emitted paths clears all local-header lookup
failures: StubResponses compiles, and the other two units reach their
external dependency failures below.

An independent byte comparison against the pinned corpus verifies
**117/117 unchanged files: 109 Swift, 3 Objective-C, and 5 headers**.
The recursive-header MiniApp test and Swift-language-version preservation
test both pass (**2/2**); generated Package.swift preserves the app's
`SWIFT_VERSION = 4.0` as `swiftLanguageVersions: [.version("4")]`.

## Three-unit syntax measurements before and after generation repair

| input | generated header root + current facade | nested header path + current facade | nested header path + original Foundation imports |
|---|---:|---:|---:|
| CreditCardValidation.m | fail, 3 errors | fail, 3 errors | fail, 1 error |
| KioskDateFormatter.m | fail, 3 errors | fail, 3 errors | fail, 1 error |
| StubResponses.m | fail, 3 errors | fail, 2 errors | pass, 0 errors |
| total | 0/3 pass, 9 errors | 0/3 pass, 8 errors | 1/3 pass, 2 errors |

For the facade columns, the probe force-includes the actual
`ObjCFacade/include/UIKit.h` and supplies both its include directory and
`Sources/COpenUIKitABI/include`. The current facade itself emits two
errors in every unit:

```text
UIKit.h:177:43: error: unknown type name 'UINavigationController'
UIKit.h:229:23: error: unknown type name 'UIEdgeInsets'; did you mean 'NSEdgeInsets'?
```

The first is a forward-declaration ordering issue: the property appears
before the header's `@class UINavigationController` declaration. The
second is a missing type declaration in the facade header. These are
measured existing header problems, not newly inferred app behaviors.
This task did not modify the shared facade.

All three `.m` files directly import Foundation rather than UIKit.
Removing only the probe's forced facade include isolates their actual
remaining dependency failures:

```text
CreditCardValidation.h:2:9: fatal error: 'Stripe/Stripe.h' file not found
KioskDateFormatter.m:2:9: fatal error: module 'ISO8601DateFormatter' not found
```

`StubResponses.m` then compiles unchanged with zero diagnostics.
Its result is only a syntax success; the upstream macro intentionally
selects demo-response mode when the private Artsy font header is absent.
No application or service operation was executed by this syntax probe.

The ISO8601 error is the app's external CocoaPod **0.8** module imported
as `@import ISO8601DateFormatter`, not an assertion that the guest's
Foundation ISO8601DateFormatter family is absent. Likewise a Swift
Stripe shim does not supply the Objective-C `<Stripe/Stripe.h>` header
or validate its ABI automatically.

## Ingest product inventory audit

The regenerated manifest changes `no_port` **30 → 17**. An actual
`swift package dump-package` (exit 0) confirms all 13 newly classified
names exist as root package products, and their emitted Eidolon
product dependencies are macOS-conditional:
`ARAnalytics`, `Action`, `Alamofire`, `Keys`, `Moya`, `NSObject_Rx`,
`Reachability`, `Result`, `RxCocoa`, `RxOptional`, `RxSwift`, `Stripe`,
and `SwiftyJSON`.

This is the measured change in dependency inventory. A product name
being present does not prove the app-used UIKit branches, Objective-C
headers, service behavior, or guest linkage. In particular, the external
Objective-C Stripe header failure remains in the syntax census even
though the Swift Stripe product now exists.

## Blocker table

| blocker | measured state |
|---|---|
| Generated local headers | Fixed: emitted headerSearchPath settings clear all 3 initial local-header lookup failures. |
| Generated companion header | Fixed: recursively discovered PodsBridgingHeader.h is carried byte-identically. |
| Current ObjC UIKit facade | 2 repeated self-consistency errors: UINavigationController declaration order and absent UIEdgeInsets. |
| Actual Objective-C dependencies | Foundation-only probes leave 2 errors: Stripe header and external ISO8601DateFormatter module. StubResponses compiles. |
| Storyboard runtime | Separately executed port probe returns nil for Auction initial controller; direct archive reads produce base-class fallbacks. See eidolon-launch-oracle.md. |
| App link, guest, first screen, score | Not established by these syntax probes; N/A. |
