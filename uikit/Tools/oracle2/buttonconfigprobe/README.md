# buttonconfigprobe — `UIButton.Configuration` on the iOS 26.1 oracle

Driven by `scripts/uibutton_configuration_probe_sim.sh /tmp/out` from `uikit/`.
Builds `main.swift` with `swiftc -target arm64-apple-ios26.0-simulator`, installs
it on a private **iPhone 16 / iOS 26.1** device
(`OpenUIKit-ButtonConfig$SIM_DEVICE_SUFFIX`), and copies
`Documents/uibutton-configuration.json` out. The app checkpoints the JSON after
every section, so a crash still yields what ran; `completedSteps` names them.

Committed transcript: **`ios-26.1-iphone16.json`** (13/13 sections).

The scope is Kickstarter's, not the SDK's: the 28 `UIButton.Configuration` uses
in `KDS` plus the six in `Kickstarter-Framework` / `Library`. See
`docs/agent_reports/uibutton-configuration.md`.

## Sections

| key | what it records |
|---|---|
| `factoryDefaults` | every member of all 12 factories (8 classic + 4 glass) |
| `factoryLayout` | intrinsic size, subview tree, title frame/font/colour, and a 1-pt pixel profile (mid-row run-length, top-left corner profile, edge samples) per factory |
| `statesPerFactory` | normal/highlighted/disabled/selected for `.filled`, `.bordered`, `.borderless`, `.plain` |
| `cornerStyles` | all six styles at heights 20/28/34/44/60, plus an explicit `background.cornerRadius` of 6 at 44 |
| `buttonSizes` | `.mini`/`.small`/`.medium`/`.large`: insets, font, intrinsic size |
| `contentInsets` | zero, KDS's two inset sets, and an asymmetric one, on `.filled` and `.borderless` |
| `imagePlacement` | four placements × padding 0/6/20, title and image frames |
| `titles` | title+subtitle, `attributedTitle`, title/attributed ordering, `titleAlignment`, `titleLineBreakMode` |
| `transformers` | what `titleTextAttributesTransformer` and `imageColorTransformer` receive and what their output does |
| `updateHandler` | when `configurationUpdateHandler` fires, and reentrancy when the handler assigns `configuration` |
| `updatedFor` | which fields `updated(for:)` rewrites |
| `misc` | `showsActivityIndicator`, `UIButton(configuration:primaryAction:)`, legacy `setTitle` under a configuration, clearing a configuration, background stroke |
| `explicitColorsPerState` | `baseForegroundColor` / `baseBackgroundColor` / explicit `background.backgroundColor` / explicit stroke, each across normal-highlighted-disabled |

## Reading the pixel profiles

`midRow` is a run-length encoded scanline: `[startX, runLength, r, g, b, a]`.
`topLeftCorner` is, for each of the first *n* rows, the leftmost x whose alpha
is ≥ 128 — which reads a corner radius straight off the rendered shape. All
renders are at **scale 1**, so one array index is one point.

## Two facts the probe itself established

* `UIButton.Configuration.CornerStyle`, `.Size` and `.TitleAlignment` are not
  `RawRepresentable` on iOS 26, so they are recorded by `String(describing:)`.
  `titleLineBreakMode` is a non-optional `NSLineBreakMode`, and the size type
  is spelled `Size`, not `ButtonSize`.
* Setting `.font` / `.foregroundColor` on the transformer's `AttributeContainer`
  by dynamic member lookup resolves to **SwiftUI's** scope inside a probe that
  imports only UIKit, and fails to link (`SwiftUICore` is not an allowed
  client). The probe therefore uses the explicit
  `AttributeScopes.UIKitAttributes.FontAttribute.self` subscripts.
