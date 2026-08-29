# Focus SwiftUI S1 Mach-O guest proof

This proof compiles Focus's pinned `Widget/Assets.swift` and
`Widget/SearchWidgetView.swift` directly from the clean checkout, links them
against a reusable `libSwiftUI.dylib` backed by the sibling
`libOpenUIKit.dylib`, and runs the resulting arm64 Mach-O executable under
`machorun` on Linux. The guest
mounts the exact production composition, checks its OpenUIKit hierarchy and
layout, applies the production preview's 135x135 frame and 20-point rounded
clip, resolves both normalized named colors and `icon_logo`, proves visible
title/search/logo pixels, renders twice byte-identically in each of two
separate guest processes, and writes a
135-point, 270x270-pixel PNG at 2x scale.

No Focus source is copied, patched, overlaid, conditionally rewritten, or
generated. `FocusWidgetBundle.generated.swift` is the separately labelled
SwiftPM `Bundle.module` accessor; `FocusWidgetGuestMain.swift` is the
project-owned executable harness. On the Foundation-hidden path the accessor
returns the identity-only `Bundle.main`, while the host supplies the normalized
bundle directory through `OpenUIKitRuntime.imageSearchPaths`.

The emitted `package/` directory contains the SwiftUI, OpenUIKit, and
OpenCoreGraphics Swift modules, their matching C module maps and public
headers, `libSwiftUI.dylib`, and `libOpenUIKit.dylib`. The proof compiles the
Focus client and harness against that package rather than reaching back into
`build/full`. `libSwiftUI` has the exact install name
`@rpath/libSwiftUI.dylib` and imports its OpenUIKit symbols from
`@rpath/libOpenUIKit.dylib`. The executable imports both libraries through
`@loader_path/package`; its link map contains neither framework object and it
exports neither framework implementation's symbols. Swift may still emit
consumer-owned specializations and metadata records whose mangled signatures
mention imported types; those are not a second framework implementation.
OpenUIKit, OpenCoreGraphics, the portable C support, and the small Swift-runtime
patch are packaged exactly once in `libOpenUIKit`. This avoids a duplicate
UIKit type/metadata universe. `libSwiftUI` is therefore a real reusable Mach-O
image, although this is still a project runtime package atop the prepared guest
SDK and Swift runtime, not a standalone Apple-compatible framework or general
SwiftUI implementation.

The resource input must be `Focus_Widget.bundle` emitted by the committed
`full/focus-ios/onboarding_resources_proof.py`. The build checks the reviewed
resource index, named-color catalogs, logo, Focus commit, source hashes, clean
checkout before and after, the canonical digest of all 16 bundle files, the
exact seven-directory normalized-bundle topology,
SwiftUI/build-support and OpenUIKit source brackets, exact open-font bytes,
Foundation invisibility, Mach-O architecture, exact `LC_ID_DYLIB`, `LC_RPATH`,
dependency and linker-input allowlists, absence of direct Apple Foundation/
SwiftUI/SwiftUICore loads from the executable and packaged dylibs, universal
SwiftUI/OpenUIKit/OpenCoreGraphics two-level bind providers, reverse framework
symbol-ownership exclusions, a missing-`libSwiftUI`
loader-failure control, a reciprocal missing-`libOpenUIKit` recursive-load
control, the guest-root manifest against the current machorun checkout, a hash
manifest for every node in the complete `build/full` input subset, the complete
CPortableIO/CSTBTrueType header trees, and the complete private SDK/sysroot
resolution tree used by the resume-only path, stable
guest-root/package execution brackets, runtime assertions, and final artifact
hashes.

The direct-load statement above is intentionally narrower than “no
Foundation-named load anywhere.” The staged non-Apple Swift runtime itself has
transitive load commands for
`/System/Library/Frameworks/Foundation.framework/Foundation` and
`CoreFoundation.framework/CoreFoundation`. In this project guest root those
paths resolve to the project's extensionless loud-abort substrate stubs, not to
Apple Foundation binaries. `build_full.sh` records and grades both stubs in the
root manifest, and the guest proof recursively resolves every Mach-O load and
re-export from the executable, hashes the complete closure plus its edges,
loader, and root manifest, and brackets that exact closure before and after
both successful guest processes. A resume cannot replace the previously
recorded input or closure manifests. Those stubs abort if reached; this widget
success proves that the bounded path does not call them, not that Foundation or
CoreFoundation behavior has been implemented.

The resume contract is deliberately fail-closed. Its canonical input manifest
records regular files, directories, symlinks, and symlink targets, so missing,
extra, type, byte, or link-target drift is visible. It includes the Foundation
guard source, all OpenUIKit/OpenCoreGraphics module artifacts, both complete C
header trees, and every node of `scratch/sysroot_full`, including the five
exact TBD paths named by the link maps. The adversarial integration runner
mutates each reviewed class in isolation—plus provider and inventory proof
logic—and requires `SKIP_FULL_BUILD=1` to stop before guest success, restores
the byte, and finally proves a clean isolated resume still runs.

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
FocusWidget and the harness remain ordinary executable objects; SwiftUI and
OpenUIKit are separately loadable sibling dylibs with one OpenUIKit identity.
The package has not yet been installed into a system guest root or wrapped as
an Apple `.framework` directory, and it does not imply coverage beyond the
currently implemented SwiftUI S1/S1.5 source surface.
