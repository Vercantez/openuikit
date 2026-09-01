# ImagePlayground (Linux starting point)

This directory is an isolated clean-room port of Apple's public
`ImagePlayground` module from the Xcode 26.1 iPhoneOS SDK symbol graphs.
It is not wired into the shared guest package.

## What is real

- `ImagePlaygroundStyle` with `illustration`, `sketch`, `animation`,
  `externalProvider`, `all`, `id`, `Hashable`, and single-value `Codable`.
- `ImagePlaygroundConcept.text(_:)`, `.extracted(from:title:)`, and
  `.image(_: URL)` (file-URL existence check only).
- `ImagePlaygroundPersonalizationPolicy` as an `Int` raw-representable enum.
- `ImageCreator.Error` as `LocalizedError` + `CustomNSError` + `CaseIterable`,
  including all nine public cases.
- `ImagePlaygroundViewController` as an `NSObject` configuration object with
  `isAvailable == false`, concept/style/policy storage, `preferredContentSize`,
  `isModalInPresentation`, and a Swift `Delegate` protocol.

## Fail-closed boundaries

Linux has no Image Playground / Apple Intelligence generative service.

- `ImageCreator.init()` always throws `.notSupported`.
- `ImageCreator.images(for:style:limit:)` is declared to return a sequence
  that would throw `.notSupported`; no instance can be constructed to call it.
- `ImagePlaygroundViewController.isAvailable` is always `false`.
- The delegate is never invoked with a generated file URL.
- No Apple image, entitlement, or on-device model success is fabricated.

## Deferred (isolated compile)

The host gate compiles this module with no extra search path. `swiftc` cannot
import `UIKit`, `SwiftUI`, `PencilKit`, `CoreGraphics`, or `ImageIO`.

Deferred until those modules can be linked:

- `ImagePlaygroundViewController` as a `UIViewController` subclass
- `sourceImage: UIImage?`, `modalPresentationStyle`, `supportedInterfaceOrientations`
- `ImagePlaygroundConcept.image(_: CGImage)` and `.drawing(_: PKDrawing)`
- `ImageCreator.CreatedImage.cgImage`
- All SwiftUI `View` sheet/style/policy modifiers and `EnvironmentValues` keys

## Tests

`tests/agent/ImagePlaygroundRuntime.swift` exercises the implemented value
types, fail-closed `ImageCreator` init, and view-controller storage, then
prints `IMAGEPLAYGROUND_AGENT_RUNTIME_OK`.

Run:

```
bash tests/acceptance/test_host.sh
```
