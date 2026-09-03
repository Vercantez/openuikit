# ImagePlayground (Linux starting point)

This directory is a fail-closed portable `ImagePlayground` module for the
OpenUIKit Linux platform. It reconstructs the public Xcode 26.1 iPhoneOS Swift
surface from the sealed symbol graph. It is not wired into the shared guest
package; a passing isolated host gate is not integrated Linux success and is
not Apple generative-service behavior.

The GitHub App installation for this promotion run could not fetch
`github.com/Vercantez/openuikit-linux-platform` branch
`cursor/port-imageplayground-to-linux-dfdc` (legacy PR #34, about 758 Swift
lines). `git fetch platform` returned **404 Not Found**, so that tree could not
be copied by content. The lane was reconstructed from the monorepo seed
(`reference/public-surface.tsv`, symbol graphs) plus the in-repo PR #34 repair
brief in `full/framework-fanout/repairs-wave2-pr30-40.json`.

## Reference dossier

Kept the **monorepo** `full/imageplayground/reference/` from current
`origin/main`.

- `provenance.generatorPath`: `scripts/framework-fanout/generate_seed.py`
- `provenance.generatorSHA256`: `2b8230ced5a3ed78f070607346f6a684d9e0fb74a8932b92bc0f5e38f46f0a8e`
- Xcode 26.1 / iPhoneOS 26.1
- Platform `reference/` could not be compared (repo unavailable). Immutable
  seed files were not rewritten.

## What is real (isolated host: Foundation + Dispatch)

- `ImagePlaygroundStyle` static members `animation`, `illustration`, `sketch`,
  `externalProvider`, `all`, `Identifiable.id`, `Hashable` / `Equatable`.
  `id` strings are Linux-host tokens matching the static names. Darwin payloads
  are unobserved.
- `ImagePlaygroundConcept.text`, `extracted(from:title:)`, and `image(URL)`
  record caller input. No NLP extraction and no ImageIO decode.
- `ImagePlaygroundPersonalizationPolicy` cases. Integer raw values are a
  Linux-host map (0/1/2); Darwin values are unobserved.
- `ImageCreator.init()` always throws `ImageCreator.Error.unavailable`.
- `ImageCreator.Error` cases, `Equatable` / `Hashable` / `CaseIterable`.
  `errorDomain` / `errorCode` / `LocalizedError` strings are Linux-host
  (`ImagePlayground.ImageCreator.Error`, codes in `allCases` order, nil
  descriptions). Darwin payloads are unobserved.

## Fail-closed / deferred

Isolated `swiftc` cannot `import` UIKit, SwiftUI, CoreGraphics, ImageIO, or
PencilKit. Those dependency-bearing APIs are compiled only under
`#if canImport(...)`. There is no NSObject, CGImage, UIViewController, View,
or PKDrawing substitute.

Deferred on this host:

- `ImagePlaygroundViewController` (must subclass `UIKit.UIViewController`)
- `CreatedImage.cgImage` (must be real `CGImage`)
- `ImageCreator.images(for:style:limit:)`
- `ImagePlaygroundConcept.image(CGImage)` and `drawing(PKDrawing)`
- SwiftUI `View` / `EnvironmentValues` overlays, including
  `imagePlaygroundSheet`

No Apple Image Playground service, Photos personalization, or generated image
bytes. Completions never invent a created-image URL.

`tests/agent/ImagePlaygroundDependencyIdentity.swift` is prepared for a future
EC2 guest run that builds real dependency modules first
(`IMAGEPLAYGROUND_DEPENDENCY_IDENTITY_OK`). It is not compiled by the isolated
host gate.

See `oracle-questions.tsv` for Darwin probes. Run
`bash tests/acceptance/test_host.sh` from this directory. Keep generated
products out of the tree.
