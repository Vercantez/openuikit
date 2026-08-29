# Focus SwiftUI S1 Mach-O guest proof

This proof compiles Focus's pinned `Widget/Assets.swift` and
`Widget/SearchWidgetView.swift` directly from the clean checkout, links them
with the literal `SwiftUI` module backed by authoritative OpenUIKit, and runs
the resulting arm64 Mach-O executable under `machorun` on Linux. The guest
mounts the exact production composition, checks its OpenUIKit hierarchy and
layout, applies the production preview's 135x135 frame and 20-point rounded
clip, resolves both normalized named colors and `icon_logo`, proves visible
title/search/logo pixels, renders twice byte-identically, and writes a
135-point, 270x270-pixel PNG at 2x scale.

No Focus source is copied, patched, overlaid, conditionally rewritten, or
generated. `FocusWidgetBundle.generated.swift` is the separately labelled
SwiftPM `Bundle.module` accessor; `FocusWidgetGuestMain.swift` is the
project-owned executable harness. On the Foundation-hidden path the accessor
returns the identity-only `Bundle.main`, while the host supplies the normalized
bundle directory through `OpenUIKitRuntime.imageSearchPaths`.

The resource input must be `Focus_Widget.bundle` emitted by the committed
`full/focus-ios/onboarding_resources_proof.py`. The build checks the reviewed
resource index, named-color catalogs, logo, Focus commit, source hashes, clean
checkout before and after, the canonical digest of all 16 bundle files, the
exact seven-directory normalized-bundle topology,
SwiftUI/build-support and OpenUIKit source brackets, exact open-font bytes,
Foundation invisibility, Mach-O architecture, absence of Foundation/SwiftUI/
SwiftUICore Apple load commands, the guest-root manifest against the current
machorun checkout, a hash manifest for every linked substrate object used by
the resume-only path, a stable guest-root execution bracket, runtime
assertions, and final artifact hashes.

The Noble image's pinned DejaVu Sans and DejaVu Sans Bold provide a
redistributable missing-glyph fallback. The proof stages and preflights their
exact bytes under the guest-visible `build/swiftui-guest/fonts/` path. The
representative 2x render uses OpenUIKit's harvested-ink path for covered glyphs;
OpenUIKit still lays the title out with its SF-derived metrics. This proves that
title text is visible and stable, but does not claim complete Apple SF glyph or
geometry equivalence. The acceptance gate uses the representative 2x scale. A
separate 1x diagnostic also finds title ink by comparing visible and hidden
renders, but its antialiasing peaks at RGB 234 against this gradient and thus
does not satisfy the 2x gate's deliberately strict RGB-235 near-white probe.

Run in the project image (the resource-proof parent is mounted read-only):

```bash
docker run --rm \
  -v "$PWD":/w \
  -v /Users/miguelsalinas/uikit:/uikit:ro \
  -v /Users/miguelsalinas/machorun:/machorun:ro \
  -v "$RESOURCE_PROOF/output/bundles":/focus-resources:ro \
  -w /w swift-macho-spike:noble \
  bash full/swiftui/build_focus_widget_guest.sh \
    /focus-resources/Focus_Widget.bundle
```

Generated output lives only under `build/swiftui-guest/`. This is an exact S1
widget-slice execution proof, not a linked Focus application, WidgetKit
extension, Apple SwiftUI compatibility claim, or general SwiftUI runtime.
SwiftUI, FocusWidget, and the harness are currently linked as static object
files into this one executable. A separately loadable `libSwiftUI.dylib` is a
future framework-packaging milestone, not part of this proof.
