# SwiftUI S2: Focus Onboarding

S2 emits Mozilla Focus's complete 21-Swift-file `Onboarding` target unchanged
at Focus revision `a2832521c1daa0c23419c73705ae043ed60c9791`. It combines the
retained state/observation graph with an OpenUIKit renderer for the concrete
composition and lifecycle APIs the target uses. No Focus source is patched,
overlaid, conditionally compiled, or copied into this repository.

Run the fail-closed proof with pinned, clean Focus and SnapKit checkouts:

```sh
scripts/prove_focus_onboarding_swiftui.sh \
  /path/to/focus-ios/focus-ios/BlockzillaPackage \
  /path/to/SnapKit
```

On macOS the command performs a release SwiftPM target build and then repeats
the proof in stock `swift:6.2-noble` Linux. It checks the exact 21-file
inventory and every SHA-256, both Git revisions and clean states, compiler
source manifests, warnings-as-errors, and post-build source hashes. SnapKit's
`Debugging.swift` is the sole excluded pinned input because its optional debug
description override requires NSObject override dispatch; its own hash and
absence from the compiler manifest are verified.

The only additional Swift inputs are visibly named generated build support:

- SwiftPM `Bundle.module` resource accessors on macOS;
- one target-wide re-export for the Combine visibility Xcode supplies;
- a Linux-only weak-key associated-object store used by exact SnapKit;
- a Linux compile-support module named `ObjectiveC`; and
- a Linux module-emission-only `Bundle.module` declaration.

The source manifests require these inputs individually and reject any extra
app source or overlay.

## Implemented runtime behavior

- `TabView(selection:)` consumes child tags, renders the selected page, and
  installs a functional `UIPageControl` for
  `.page(indexDisplayMode: .always)`. Binding writes and observed selection
  changes rebuild the visible page; the control path is exercised with real
  began/ended window touches.
- `Text` uses unlimited word-wrapped `UILabel` lines. A fixed-width long
  onboarding sentence therefore measures and renders multiple lines.
- vertical `ScrollView` measurement distinguishes an unbounded content axis
  from the viewport. A `VStack` containing `Spacer` fills the viewport without
  synthesizing the previous 10,000-point content tail.
- a simultaneous tap on a subtree containing `Button` is registered on the
  same `UIControl` as the primary action. Visual background and clipping
  wrappers pass touches through to that control. Tests inject began/ended
  touches through `UIWindow`, proving both actions survive actual hit testing.
- `UIViewControllerRepresentable` retains one controller per stable graph
  identity, calls update on every rebuild, and reconciles
  `addChild`/`didMove`/removal containment. Hosting-controller appearance
  transitions are forwarded to represented children.
- `onAppear` is driven by the hosting controller's appearance lifecycle. Its
  structural identity survives observation-driven body rebuilds, while a real
  disappearance and reappearance delivers it again.

The Linux-only NSString drawing convenience used by Focus tooltips is backed
by OpenUIKit's deterministic text layout rather than a compile-only stub.

## Boundaries

The macOS proof emits the complete release target, including object code. The
stock Linux proof emits the complete release-mode Swift module after building
all dependencies, but deliberately does not emit or execute object code for
the two unchanged Focus `@objc` selector handlers. Enabling ObjC interop in
the stock Linux Swift runtime reaches semantic/module emission, then crashes
IRGen because the shipped runtime has no compatible Objective-C metadata
layout. The proof reports this as a module-only result; it is not a Linux
runtime claim for those UIKit controller files.

The SwiftUI/OpenUIKit paths above do execute natively and are covered by
focused behavior tests on the local host. Page swiping, animated transitions,
general gesture arbitration, controller coordinators, SwiftUI environment
diffing, and arbitrary tab styles remain outside this slice.

For the Foundation-hidden Mach-O packaging path, observation invalidation is
deferred to the next host-supplied `UIWindow.tick(timestamp:)` turn. This keeps
the guest UI deterministic and avoids routing a main-actor task through the
Apple dispatch voucher entry points that the Linux guest runtime does not
provide. A scheduled invalidation is consumed exactly once before user graph
code runs. Its graph pass owns a reference-identity token, so direct root
evaluation retires stale work without letting that callback steal a newer
publication's token. A zero-delay timer created during any recursively entered
host step cannot run until the following outermost step.

The integration proof compiles Focus's ten exact shipping SwiftUI Onboarding
runtime sources plus its two exact Widget sources directly from the pinned,
clean checkout. It links them with separately packaged FoundationEssentials,
Foundation, OpenUIKit, Combine, and SwiftUI ARM64 Mach-O dylibs, then runs the
guest on Linux. Three real window touches advance to page two, open the
settings URL through the host hook, and dismiss through Skip. The proof also
checks deferred rendering, both page-control states, appearance telemetry, and
a Foundation UUID generate/parse/format round trip before printing
`FOCUS_ONBOARDING_MACHO_GUEST_OK`.
