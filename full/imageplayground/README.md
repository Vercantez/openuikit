# ImagePlayground (Linux starting point)

This directory is a fail-closed portable `ImagePlayground` module for the
OpenUIKit Linux platform. It reconstructs the public Xcode 26.1 iPhoneOS Swift
surface from the sealed symbol graph. It is not wired into the shared guest
package; a passing isolated host gate is not integrated Linux success and is
not Apple generative-service behavior.

## Depth pass 2026-09

Coverage of the 89 exact public identifiers:

| | implemented | declared | deferred | unavailable | not-applicable |
|---|---:|---:|---:|---:|---:|
| Before | 42 | 14 | 33 | 0 | 0 |
| After | 56 | 0 | 33 | 0 | 0 |

Raised `implemented` on the Foundation-only surface: styles, concepts,
personalization-policy raw values, `ImageCreator` fail-closed init, and
`ImageCreator.Error` cases plus Linux-host `CustomNSError` / `LocalizedError`
payloads. The 20-app corpus ranks WordPress-iOS first (three files under
Gutenberg / MediaPicker). `scratch/ladder-corpus/focus-ios` has **zero**
`ImagePlayground` tokens. WordPress exercises `ImagePlaygroundViewController`,
`isAvailable`, concepts, `sourceImage`, and the delegate — all UIKit and
therefore still deferred on this isolated host (no UIViewController substitute).

Top-5 evidence distribution among 56 implemented rows (17 focused tests;
largest non-enum-member test is 12.5%):

| rows | share | evidence |
|---:|---:|---|
| 12 | 21.4% | `ImageCreatorErrorTests.swift#testCreatorErrorCases` (enum cases / `allCases`) |
| 7 | 12.5% | `ImagePlaygroundStyleTests.swift#testStyleCatalog` |
| 5 | 8.9% | `ImagePlaygroundStyleTests.swift#testStyleEqualityAndHashing` |
| 5 | 8.9% | `ImageCreatorErrorPayloadTests.swift#testCreatorErrorLocalizedPayload` |
| 4 | 7.1% | `ImagePlaygroundPersonalizationPolicyTests.swift#testPersonalizationPolicyCases` |

## Reference dossier

Kept the **monorepo** `full/imageplayground/reference/` from the seed.

- `provenance.generatorPath`: `scripts/framework-fanout/generate_seed.py`
- `provenance.generatorSHA256`: `2b8230ced5a3ed78f070607346f6a684d9e0fb74a8932b92bc0f5e38f46f0a8e`
- Xcode 26.1 / iPhoneOS 26.1

## What is real (isolated host: Foundation + Dispatch)

- `ImagePlaygroundStyle` static members `animation`, `illustration`, `sketch`,
  `externalProvider`, `all`, `Identifiable.id`, `Hashable` / `Equatable`.
  `id` strings are Linux-host tokens matching the static names. Darwin payloads
  are unobserved. `Codable` is a single-value `id` string.
- `ImagePlaygroundConcept.text` and `extracted(from:title:)` record caller
  input. No NLP extraction.
- `ImagePlaygroundConcept.image(URL)` records file URLs without ImageIO decode
  and returns `nil` for non-file URLs (Apple documents a local file URL).
- `ImagePlaygroundPersonalizationPolicy` cases. Integer raw values are a
  Linux-host map (automatic=0, enabled=1, disabled=2); Darwin values are
  unobserved. The documented “automatic equals enabled by default” applies to
  UI personalization, not to enum identity — the cases stay distinct.
- `ImageCreator.init()` always throws `ImageCreator.Error.unavailable`.
- `ImageCreator.Error` cases, `Equatable` / `Hashable` / `CaseIterable`.
  `errorDomain` is the Linux-host string `ImagePlayground.ImageCreator.Error`.
  `errorCode` follows `allCases` order from 0. `errorDescription` /
  `localizedDescription` use the sealed graph case documentation as Linux-host
  text. `errorUserInfo` is empty. Darwin payloads are unobserved.

## Fail-closed / deferred

Isolated `swiftc` cannot `import` UIKit, SwiftUI, CoreGraphics, ImageIO, or
PencilKit. Those dependency-bearing APIs are compiled only under
`#if canImport(...)`. There is no NSObject, CGImage, UIViewController, View,
or PKDrawing substitute.

Deferred on this host (33 identifiers):

- `ImagePlaygroundViewController` (must subclass `UIKit.UIViewController`)
- `CreatedImage.cgImage` (must be real `CGImage`)
- `ImageCreator.images(for:style:limit:)`
- `ImagePlaygroundConcept.image(CGImage)` and `drawing(PKDrawing)`
- SwiftUI `View` / `EnvironmentValues` overlays, including
  `imagePlaygroundSheet` and `supportsImagePlayground`

No Apple Image Playground service, Photos personalization, or generated image
bytes. Completions never invent a created-image URL.

`tests/agent/ImagePlaygroundDependencyIdentity.swift` is prepared for a future
EC2 guest run that builds real dependency modules first
(`IMAGEPLAYGROUND_DEPENDENCY_IDENTITY_OK`). It is not compiled by the isolated
host gate.

See `oracle-questions.tsv` for Darwin probes. Keep generated products out
of the tree.

## Host gate (this pass)

`bash full/imageplayground/tests/acceptance/test_host.sh` ended:

```
FRAMEWORK_FANOUT_REFERENCE_OK
IMAGEPLAYGROUND_AGENT_RUNTIME_OK
FRAMEWORK_FANOUT_HOST_OK module=ImagePlayground dylib=libImagePlayground.dylib
```

`swiftc --version` reports Swift 6.2.4, Target: x86_64-unknown-linux-gnu.
`.cursor/verify-cloud-environment.sh` did not print
`CURSOR_SWIFT_ENVIRONMENT_OK swift=6.2.4 target=linux products=clean` on
this pod (missing scratch corpus/products relative to campaign build
`bld-20260901-d3266600-d87b-438f-94c1-d1aa48036e87`).
