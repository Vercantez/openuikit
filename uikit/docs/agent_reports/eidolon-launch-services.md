# Eidolon service boundaries and Apple/guest interfaces

Date: 2026-09-07. App: artsy/eidolon `44486ed` (full pin in the adjacent
JSON). This is a bounded service/API measurement, not a first-screen result.
First screen, iOS pixel score, and guest execution: **N/A**.

## Services measured

| boundary | source measurement | result |
|---|---|---|
| Keys | The pinned Podfile requests 11 generated key properties. `APIKeys.swift:31` chooses successful bundled responses when either Artsy key has fewer than 2 characters. | Added all 11 properties with an explicit unavailable marker of length greater than 2; `servicesAvailable` is false. Empty keys would have fabricated demo success. |
| Launch | `AppDelegate.swift:18` constructs `Networking.newDefaultNetworking()` as a stored-property initializer, before `didFinishLaunchingWithOptions`. | `EidolonLaunchCompat.withLaunchPreflight` throws before evaluating its application-construction closure. Test observes **0** construction callbacks, so no app delegate or provider is constructed. This does not claim an implemented network transport. |
| ARAnalytics | Locked 5.0.1 resolves to `888744016bb4f53ad5b652819406645bd21f80c7`. `ARAnalytics.h:51,126,129` declares the 3 called selectors; `.m:821,822,831` defines the 3 called constants. | Swift-facing calls compile against the real headers on the simulator SDK. Adapter retains no configuration, identity, or event; it starts no provider, logs unavailability once, and remains disabled. |
| Stripe | Lock specifies 12.1.0 (`e3c35c97963b938baac22612e4f4aae4b1cab8eb`); Podfile requests 14.0.1. Locked `STPAPIClient.h:37,54,192`, `STPBlocks.h:91`, and card/address/token headers supply the app-called declarations. | Swift service adapter calls completion exactly **once**, with **nil token** and a nonnil `serviceUnavailable` error. Token/card construction is private. The app's force-unwrapped failure at `StripeManager.swift:51` is respected. No payment or account can be created. Resolving the lock/request disagreement is still a wall. |
| CardFlight | Locked 4.3.1 podspec names `https://github.com/CardFlight/cardflight-v4-ios.git`, tag `v4.3.1`, and a commercial all-rights-reserved license. | `git ls-remote` exits **128**, `Repository not found`. No binary/source was redistributed. `CFTCredentials.setup(... completion: nil)` does not disclose the callback type, so no supposedly exact callback signature was invented. |

The ARAnalytics and Stripe call probe typechecks against their real pinned
Objective-C headers using Apple Swift 6.2.1 and iPhoneSimulator26.1 in Swift 4
mode: **0 errors**, 2 deprecated `PKAddressField` warnings. This proves the
called Swift signatures; it does not assert that the entire SDK builds or
that the Swift service adapters implement the SDK's Objective-C ABI.

The unchanged `APIKeys.swift` and `CreditCard.swift`, plus the byte-for-byte
`STPCardBrand` extension extracted from `StripeManager.swift`, typecheck
against the service modules. The `CreditCardValidation.m` caller still needs
the real Stripe validator/header graph; this adapter does not invent credit
card validation or supply a `Stripe/Stripe.h` facade.

## Updated blocker table

| blocker | measured state |
|---|---|
| Generated credentials and sample success | 11 Keys properties compile, all marked unavailable. Preflight prevents construction of the default provider; no successful fixture response is substituted. |
| Stripe dependency consistency | Podfile 14.0.1 differs from lock 12.1.0. Only the locked API's called Swift service surface is adapted. |
| CardFlight exact interfaces | The pinned SDK repository is unavailable. Completion type and complete binary API/ABI remain unmeasured; no CardFlight shim exists. |
| Native Apple dialect | A probe containing the app's `UIApplicationLaunchOptionsKey`, `UIWebView`, `IBOutlet UITextView`, and `IBAction AnyObject` compiles in Swift 4 mode. Swift 5 mode has **1 error**: the launch-options name was obsoleted in Swift 4.2. UIWebView is a warning, not an unavailable declaration, in this SDK. |
| Port API surface | The same Swift 4 probe importing the built OpenUIKit module has **2 missing declarations**: `UIApplicationLaunchOptionsKey` and `UIWebView`. The outlet/action declarations pass. No web-view behavior was guessed. |
| Objective-C service consumers | Pure Swift adapters do not publish a Clang `Stripe/Stripe.h` for `CreditCardValidation.m`. Their successful Swift caller probe is not an Objective-C ABI claim. |
| Guest wiring | Read-only `full/scripts/build_full.sh` inspection finds **0** Eidolon module names. Its `compile_app_module` and RealAppProbe globs do not add these service objects or an Eidolon app object. No guest wiring or pin was changed; guest launch is N/A. |
| First screen | No app delegate was run through these service adapters. No golden or pixel score is claimed. |

## Verification and integration

Darwin Apple Swift 6.2.1: **4/4** `ServiceFailureTests` pass. Linux
`swift:6.2-noble`, Swift 6.2.4, aarch64: **4/4** pass. These tests cover the
demo-response predicate, disabled analytics, failure-only tokenization, and
the application-construction callback remaining zero.

```sh
swift test --package-path Sources/EidolonServiceShims \
  --scratch-path /tmp/eidolon-services/shim-build --filter ServiceFailureTests
docker run --rm -v "$PWD/Sources/EidolonServiceShims":/src:ro swift:6.2-noble \
  bash -c 'cp -r /src /work && cd /work && swift test --filter ServiceFailureTests'
```

The standalone verification package provides four explicit target paths. A
root package can declare them without a remote package or new pin:

```swift
.target(name: "Keys", path: "Sources/EidolonServiceShims/Keys"),
.target(name: "ARAnalytics", path: "Sources/EidolonServiceShims/ARAnalytics"),
.target(name: "Stripe", path: "Sources/EidolonServiceShims/Stripe"),
.target(name: "EidolonLaunchCompat", dependencies: ["Keys"],
        path: "Sources/EidolonServiceShims/EidolonLaunchCompat"),
```

No library source uses `_StringProcessing` algorithms. The adjacent JSON
contains compiler diagnostics, header authority commits, the inaccessible
CardFlight source command/output, and hashes of the carried licenses and
podspecs. The only copied upstream artifacts in this directory are those
licenses and podspecs; the adapters are identified as adapters throughout.
