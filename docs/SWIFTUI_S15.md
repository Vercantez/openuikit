# SwiftUI S1.5: Focus DesignSystem bridge

S1.5 extends the literal local `SwiftUI` module from the static Focus widget
to all seven Swift files in the pinned Focus
`BlockzillaPackage/Sources/DesignSystem` target.  This is a source-preservation
gate: Focus remains at revision
`a2832521c1daa0c23419c73705ae043ed60c9791`, and none of its source is edited,
overlaid, conditionally compiled, or rewritten.

The seven exact inputs and pinned SHA-256 values are:

| Focus source | SHA-256 |
| --- | --- |
| `Bundle+CurrentBundle.swift` | `725315f04ecbbe4bdeceb73bdf07550e2c3f38307696d0fa7035600e018ca3af` |
| `Preview Files/AppColorsView.swift` | `0bcfbf1b672fdd82d305a8fd0fbbc319e59285b43b7aa7d4566cf445e5ecd2f1` |
| `Preview Files/AppFontsView.swift` | `99da3374150876e5212adc7f9baca7f1cd4c62afea40919a64ac31a700e7e00a` |
| `Preview Files/AppImagesView.swift` | `59f55ca617ce706cb7abe85b3d44f192261fb8690ba05b8eab4fde02f1664508` |
| `UIColor+AppColors.swift` | `4078f76f180d37f6d560dd63d59ef161302a73b7f416933533663700c314224f` |
| `UIFont+AppFonts.swift` | `ac4895febb0ad6c588ada61420b0b271afb33092d76e1dbed828ee8b337c83e6` |
| `UIImage+AppImages.swift` | `ba5720a57aa90406b95a66ea62433557b666c1558d59781018de050585797734` |

Run the proof with:

```sh
scripts/prove_focus_designsystem_swiftui.sh \
  /path/to/focus-ios/focus-ios/BlockzillaPackage
```

The script requires the pinned, clean Focus checkout, copies the seven files
byte-for-byte to a private temporary SwiftPM target, and enables only that
target's normal generated `Bundle.module` accessor.  The target depends on
the local products literally named `UIKit` and `SwiftUI`.  Its compiler input
manifest is required to contain exactly those eight Swift files, and
`-warnings-as-errors` makes successful module emission the zero-diagnostic
gate.  It verifies every hash again after staging and proves neither checkout
changed.

The same gate emits successfully with Apple Swift 6.2 on macOS and the stock
`swift:6.2-noble` Linux toolchain. A Linux release build of the local `SwiftUI`
target is a separate passing gate, so this is not a host-only type-check.

## Implemented behavior

This slice adds the smallest executed vocabulary the DesignSystem views use:

- `Form` with ordered, minimum-44-point static rows;
- eager `ForEach(_:id:content:)` expansion in collection order, with S2 using
  the typed explicit ID to scope dynamic state across reorder and removal;
- `NavigationView` and `navigationTitle(_:)` with an OpenUIKit title bar;
- `Color` as a renderable view, including `Color(UIColor)` and fixed frames;
- renderable `RoundedRectangle`, `stroke(_:lineWidth:)`, `clipShape`, and
  `overlay` backed by OpenUIKit layer fill, clipping, and borders;
- `Image(uiImage:)`, resizable sizing, and original UIKit image pixels; and
- a public `CTFont` compatibility identity plus `Font(CTFont)` that preserves
  OpenUIKit `UIFont` size, weight, and design.

Focused tests execute row ordering and geometry, UIKit image pixels, font
metrics, local rounded clipping, stroke overlays, and repeated deterministic
renders.  The test executable links the local implementation statically; its
Mach-O load commands contain neither Apple `SwiftUI.framework` nor
`SwiftUICore.framework`.

The Focus files retain their Mozilla Public License 2.0 headers.  The derived
test fixture carries the same license and names its exact upstream provenance.

## Boundaries

`Form` is a static, clipped OpenUIKit surface, not a scrolling SwiftUI form.
`ForEach` expands eagerly whenever the view body is evaluated. S2 preserves
State by the exact explicit `Hashable` ID, but this is not SwiftUI's general
view diffing engine and it does not animate insertion, removal, or moves; see
[`SWIFTUI_S2.md`](SWIFTUI_S2.md). `NavigationView` implements one
title/content column, not split-view policy, navigation paths, toolbar
preferences, or interactive transitions. Shape support is limited to the
rounded rectangle fill/stroke/clip path exercised here.

Asset catalog compilation remains outside SwiftUI. Named colors and images
delegate to OpenUIKit's loose-resource support; the separate Focus resource
normalizer must materialize supported catalog members for runtime use. The
exact-source gate emits a module but does not claim that every DesignSystem
asset format (notably vector PDF/SVG inputs) renders yet.
