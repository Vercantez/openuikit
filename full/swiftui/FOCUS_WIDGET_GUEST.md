# Focus SwiftUI S1 Mach-O guest proof

This proof compiles Focus's pinned `Widget/Assets.swift` and
`Widget/SearchWidgetView.swift` directly from the clean checkout, links them
against a reusable `libSwiftUI.dylib` backed by sibling `libOpenUIKit.dylib`,
`libOpenCoreGraphics.dylib`, `libFoundationEssentials.dylib`,
`libCombine.dylib`, and `libOpenCombine.dylib` images, and runs the resulting
arm64 Mach-O executable under `machorun` on Linux. The guest
mounts the exact production composition, checks its OpenUIKit hierarchy and
layout, applies the production preview's 135x135 frame and 20-point rounded
clip, resolves both normalized named colors and `icon_logo`, proves visible
title/search/logo pixels, renders twice byte-identically in each of two
separate guest processes, and writes a
135-point, 270x270-pixel PNG at 2x scale.

The framework checkout is independently pinned clean before and after the
gate to OpenUIKit commit `83fbcbe2204eb836968d4e73ecfecec7b20c68ef`,
tree `54552fea10c23c9124fb300db33c9db54aad32b9`.

No Focus source is copied, patched, overlaid, conditionally rewritten, or
generated. `FocusWidgetBundle.generated.swift` is separately labelled
project-owned compatibility build support; it is not a generated or
SwiftPM-equivalent accessor. The exact pinned Focus `Package.swift` declares no
Widget resources, so Apple SwiftPM 6.2.1 generates no accessor and defines
`SWIFT_MODULE_RESOURCE_BUNDLE_UNAVAILABLE`, even though unchanged Widget source
contains `Bundle.module` asset spellings. `FocusWidgetGuestMain.swift` is the
project-owned executable harness. The reviewed exact normalized
`Focus_Widget.bundle` is staged beside the guest; the compatibility support
resolves it relative to `Bundle.main` without a process-global image-search
fallback. The runtime asserts that exact bundle/resource root, evaluates
unchanged Widget color and image declarations, and then proves their rendered
pixels.

The emitted `package/` directory contains the SwiftUI, OpenUIKit,
OpenCoreGraphics, FoundationEssentials and dependency, literal Combine, and
OpenCombine Swift modules, their
matching C module maps and public headers, and six sibling dylibs. The proof
compiles the Focus client and harness against that package rather than reaching
back into `build/full`. Every sibling has an `@rpath` install name and an
`@loader_path` runpath. `libSwiftUI` imports UI symbols from
`libOpenUIKit`, and observation symbols through the literal `libCombine`
re-export and single `libOpenCombine` implementation. The executable imports
SwiftUI, OpenUIKit, FoundationEssentials, and OpenCoreGraphics directly through
`@loader_path/package`; its link
map contains no framework object. Swift may still emit
consumer-owned specializations and metadata records whose mangled signatures
mention imported types; those are not a second framework implementation.
OpenUIKit and its portable C support are packaged exactly once in
`libOpenUIKit`; OpenCoreGraphics and FoundationEssentials each have one
separate sibling image. This avoids duplicate UIKit, graphics, or Foundation
type/metadata universes. `libSwiftUI` is therefore a real reusable Mach-O
image, although this is still a project runtime package atop the prepared guest
SDK and Swift runtime, not a standalone Apple-compatible framework or general
SwiftUI implementation.

Swift 6 lowers OpenUIKit's main-actor-isolated layer destruction through
`pthread_main_np`. The project's `libSystem.B.dylib` umbrella is therefore an
explicit physical linker input for `libOpenUIKit` as well as the already
declared `/usr/lib/libSystem.B.dylib` runtime image. The exact linker-input and
recursive-runtime-closure allowlists fail closed if that provider relationship
changes.

The resource input must be `Focus_Widget.bundle` emitted by the committed
`full/focus-ios/onboarding_resources_proof.py`. The build checks the reviewed
resource index, named-color catalogs, logo, Focus commit, source hashes, clean
checkout before and after, the canonical digest of all 16 bundle files, the
exact seven-directory normalized-bundle topology,
SwiftUI/build-support and OpenUIKit source brackets, exact open-font bytes, the
target-15 contract that Foundation remains hidden while FoundationEssentials
is visible, Mach-O architecture, exact `LC_ID_DYLIB`, `LC_RPATH`,
dependency and linker-input allowlists, absence of direct Apple Foundation/
SwiftUI/SwiftUICore loads from the executable and packaged dylibs, universal
two-level bind providers across direct, associated-type, conformance, and
foreign-type-extension manglings for all five Swift module identities, reverse
framework symbol-ownership exclusions,
missing-`libSwiftUI` and missing-`libOpenUIKit` controls, and separate
missing-`libCombine` and missing-`libOpenCombine` recursive-load controls, the
guest-root manifest against the current machorun checkout, a hash
manifest for every node in the complete `build/full` input subset, the complete
CPortableIO/CSTBTrueType header trees, and the complete private SDK/sysroot
resolution tree used by the resume-only path, within-run
guest-root/package execution brackets, runtime assertions, and final artifact
hashes. The immutable Focus sources, normalized resource tree, support files,
fonts, commits, and selected upstream inputs are independently hash-pinned.
The complete derived-input manifest and package-tree hashes are explicitly
labelled `per-run`: compiler-produced `.swiftsourceinfo` files can encode the
absolute checkout root, so those aggregate hashes prove no mutation between
compile and both executions in one run, not byte-for-byte reproducibility
across different workspace paths.

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

Every resolved closure image must be a regular file reached only through real
directories below its declared package or guest-root boundary. A symlink at the
image or any ancestor component is rejected rather than followed and mislabeled
as in-root content.

The resume contract is deliberately fail-closed. Its canonical input manifest
records regular files, directories, symlinks, and symlink targets, so missing,
extra, type, byte, or link-target drift is visible. It includes the Foundation
guard source, all OpenUIKit/OpenCoreGraphics and FoundationEssentials build
artifacts, the Foundation C-shim headers, both complete portable C header trees,
and every node of `scratch/sysroot_fe4`, including the eight
exact TBD paths named by the link maps. The adversarial integration runner
mutates each reviewed class in isolation—plus provider and inventory proof
logic and a runtime ancestor-directory symlink—and requires
`SKIP_FULL_BUILD=1` to stop before guest success, restores the node, and finally
proves a clean isolated resume still runs.

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

The build consumes the exact successful OpenCombine oracle subject at
`scratch/opencombine-core-durable-20260828-r2` by default. Its result, object,
module, helper source/header/module map, and project-owned patch are all
hash-pinned and included in the build-input bracket. A fresh checkout must
first reproduce the prerequisite described in `full/oracle-opencombine/README.md`;
an alternate location can be selected with `OPENCOMBINE_ROOT`, but it must
match the same reviewed bytes.

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
FocusWidget and the harness remain ordinary executable objects; SwiftUI,
OpenUIKit, OpenCoreGraphics, FoundationEssentials, Combine, and OpenCombine are
separately loadable sibling dylibs with one identity apiece.
The package has not yet been installed into a system guest root or wrapped as
an Apple `.framework` directory, and it does not imply coverage beyond the
currently implemented SwiftUI source surface.
