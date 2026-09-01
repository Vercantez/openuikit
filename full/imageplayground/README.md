# ImagePlayground (Linux starting point)

This directory is an isolated clean-room port of Apple's public
`ImagePlayground` module from the Xcode 26.1 iPhoneOS SDK symbol graphs.
It is not wired into the shared guest package. Passing the isolated host
gate is **not** integrated Linux success.

## What compiles in the isolated host configuration

The host gate compiles this module with no extra search path. `swiftc` cannot
import `UIKit`, `SwiftUI`, `PencilKit`, `CoreGraphics`, or `ImageIO`.

Real in that configuration:

- `ImagePlaygroundStyle` public identities (`illustration`, `sketch`,
  `animation`, `externalProvider`) plus `Hashable` / `Identifiable`
- `ImagePlaygroundConcept.text(_:)` and `.extracted(from:title:)`
- `ImagePlaygroundPersonalizationPolicy` cases
- `ImageCreator.Error` cases, equality, hashing, and `CaseIterable`
- `ImageCreator.init()` throwing `.notSupported`

Local `id` tokens, Codable layout, `CustomNSError` domain/codes, and
`LocalizedError` copy are declared stand-ins, not Apple-observed values.

## Dependency-bearing surface (compiled only when the module exists)

There are no module-local types named `UIViewController`, `UIImage`,
`CGImage`, `PKDrawing`, `View`, or `EnvironmentValues`.

- `#if canImport(UIKit)`: `ImagePlaygroundViewController` subclasses
  `UIKit.UIViewController`, exposes `sourceImage: UIImage?`, presentation
  overrides, and `Delegate: NSObjectProtocol`. `isAvailable` is `false`.
- `#if canImport(CoreGraphics)`: `CreatedImage.cgImage` and
  `ImagePlaygroundConcept.image(_: CGImage)`
- `#if canImport(PencilKit)`: `ImagePlaygroundConcept.drawing(_: PKDrawing)`
- `#if canImport(ImageIO)`: URL image concepts require a decodable image
- `#if canImport(SwiftUI)`: `View` sheet/style/policy modifiers and
  `EnvironmentValues` keys (`supportsImagePlayground` is `false`)

Host-only construction (`CreatedImage(_hostCGImage:)`, style `_hostID`,
delegate dispatch) is `@_spi(OpenUIKitHost)`.

## Fail-closed boundaries

- `ImageCreator.init()` always throws `.notSupported`
- No generated file URL is produced on production paths
- SwiftUI sheets do not present a generation UI or call `onCompletion`
- `isAvailable` / `supportsImagePlayground` stay `false`

## Tests

- `tests/agent/ImagePlaygroundRuntime.swift` — isolated host runtime,
  prints `IMAGEPLAYGROUND_AGENT_RUNTIME_OK`
- `tests/agent/ImagePlaygroundDependencyIdentity.swift` — future clean EC2
  run after guest Foundation, CoreGraphics, ImageIO, PencilKit, SwiftUI,
  and UIKit dylibs are built and passed via `-I`/`-L`; prints
  `IMAGEPLAYGROUND_DEPENDENCY_IDENTITY_OK`

```
bash tests/acceptance/test_host.sh
```
