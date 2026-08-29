# OpenUIKit-backed SwiftUI port contract

The compatibility target is an actual guest module named `SwiftUI`. Focus must
keep every `import SwiftUI`, view declaration, modifier chain, property wrapper,
and `UIHostingController` call site unchanged. Build-generated files such as
SwiftPM's resource accessor are allowed; source overlays, conditional imports,
and rewritten Focus files are not.

This document separates three gates which are easy to conflate:

| Gate | What it proves | What it does not prove |
| --- | --- | --- |
| Compile surface | The exact Focus files typecheck against a module named `SwiftUI` and link without Apple's SwiftUI framework. | State invalidation, layout, pixels, input, or Linux execution. |
| Runtime semantics | The declarative graph updates, identities are stable, bindings publish, lifecycle callbacks fire, and controls perform the expected actions. | Correct geometry, drawing, native window/input delivery, or Linux guest loading. |
| Renderer and host | `UIHostingController` mounts the graph as OpenUIKit views, the Linux host draws it, and machorun delivers events/run-loop work. | APIs and behaviors outside the tested source slice. |

All three must be green before a source slice is called executable.

## Required architecture

### 1. Module and type identity

- Emit `SwiftUI.swiftmodule` and `libSwiftUI.dylib` for the same
  `arm64-apple-macos13.0` guest ABI as the current OpenUIKit proof.
- Link to the project-owned `UIKit`/OpenUIKit, Foundation/CoreGraphics/Darwin
  substrate, and the single guest Combine/OpenCombine identity. Never link
  `/System/Library/Frameworks/SwiftUI.framework`.
- Re-export or otherwise make visible the authoritative modules the pinned
  importers require without a direct provider import: Foundation (`Bundle`,
  `Date`, `NSError`, `NSException`, `NSLocalizedString`, `URL`, `UserDefaults`),
  CoreGraphics (`CGFloat`), CoreText (`CTFont`), UIKit (`UIApplication`,
  `UIColor`, `UIFont`, `UIImage`, `UIInterfaceOrientationMask`, `UIPageControl`,
  `UIPasteboard`, `UIViewController`), and Combine (`ObservableObject`,
  `Published`). The canonical JSON carries exact per-symbol source evidence.
- Preserve generic and associated-type spellings. A type-erased, `Any`-based
  facade can be an internal renderer detail, but it cannot replace the public
  `View`, `View.Body`, `some View`, `Binding`, or hosting-controller contracts.

### 2. Declarative core

- `View` plus a `Never` primitive-body terminator.
- `@resultBuilder ViewBuilder` with empty, single, tuple, optional,
  `buildEither`, availability, and collection forms demanded by the inventory.
- Stable structural identity for tuples, `ForEach`, conditionals, and tagged
  children; diffing must preserve control/state identity across recomputation.
- Value wrappers for modifiers. A modifier may start unimplemented, but it must
  remain represented in the graph so adding behavior does not change identity.
- `State`, `Binding`, `ObservedObject`, and the one exported
  `ObservableObject`/`Published` implementation, with main-run-loop
  invalidation and no duplicate Combine type universe.
- Environment propagation for color scheme, safe area, font, foreground color,
  and the other values required by the exact Focus slice.

### 3. OpenUIKit renderer

- A renderer protocol transforms immutable view descriptions into a retained
  mounted tree. The first backend is OpenUIKit; donor GTK/DOM backends are not
  part of the Mach-O guest graph.
- Primitive mappings begin with `Text -> UILabel`, `Image -> UIImageView`,
  `Button -> UIButton`, stacks -> layout containers, `Spacer` -> flexible
  layout demand, and `ScrollView`/`List`/`Form` -> OpenUIKit scroll/table
  surfaces as later slices require them.
- Layout modifiers feed a deterministic proposal/measurement/placement pass.
  They cannot be compile-only no-ops once a slice reaches its renderer gate.
- Paint modifiers map to OpenUIKit/CQuartz colors, clipping, corner radii,
  shadows, gradients, and image modes. Asset lookup goes through the existing
  bundle/xcassets pipeline, not host filesystem shortcuts.
- Gestures and controls feed semantic events back into bindings/actions;
  lifecycle (`onAppear`) and observation invalidation are scheduled through the
  guest run loop.

### 4. Hosting boundary

`UIHostingController<Content: View>` must inherit OpenUIKit's
`UIViewController`, retain a mutable `rootView`, create exactly one renderer
root, mount during the normal controller lifecycle, propagate bounds/safe area,
and tear down subscriptions and mounted nodes on replacement/deinit.

`UIViewControllerRepresentable` is a later compile requirement from the
checked-in Onboarding preview source. It is not a reason to block the first
runtime slice, but the package target cannot claim complete source emission
until its context/coordinator/update/dismantle contract compiles.

## Milestones and proof gates

### S0 — exact contract (present artifact)

`focus-swiftui-surface.json` pins 28 direct importers: 9 main-app files, 18
linked local-package files, and the one unique Widgets extension entry. The
main-app link closure contains 27. Four `Preview Files` sources are still real
SwiftPM compile inputs. The inventory records a reviewed lexical vocabulary of
30 SwiftUI-shaped type/protocol candidates, 38 dot-call modifier candidates, 3
property-wrapper candidates, 18 `View`-conformance candidates, and 44 exact
`some View` token occurrences. Exact locations do not attribute UIKit member
collisions, Combine `$name` projections, or nested callback conditionals to
SwiftUI/ViewBuilder.

Gate: byte-identical regeneration and the local tests pass. This is not a
SwiftUI implementation claim.

### S1 — smallest honest executable slice: Focus `Widget`

Compile these two exact, unmodified files:

- `BlockzillaPackage/Sources/Widget/Assets.swift`
- `BlockzillaPackage/Sources/Widget/SearchWidgetView.swift`

Why this slice comes first:

- it is in the actual main-app link closure through Onboarding;
- it is small but genuinely declarative rather than a type-only probe;
- it exercises nested `VStack`/`HStack`, `Text`, `Image`, `Spacer`,
  `LinearGradient`, `Gradient`, `Color`, optional background content,
  `RoundedRectangle`, resource bundles, font/image/layout/paint modifiers, and
  legacy preview syntax;
- it has no navigation, mutable state, Combine timing, or WidgetKit dependency,
  so failures localize to the new SwiftUI core/renderer.

The test harness is new project code, not an app edit. It instantiates the
public `SearchWidgetView`, hosts it in `UIHostingController`, and renders the
real 135x135 card.

S1 is green only when all of the following are true:

1. The two staged source hashes match the canonical inventory and no patch is
   applied.
2. A SwiftPM-equivalent generated `Bundle.module` accessor and normalized
   resource bundle are separately attested.
3. Module emission reports zero errors against the guest `SwiftUI` and
   OpenUIKit modules.
4. Mach-O dependency inspection proves no Apple SwiftUI linkage.
5. A linked Mach-O harness executes under Linux machorun.
6. The mounted OpenUIKit hierarchy contains the expected text and image nodes,
   and a deterministic pixel probe demonstrates a non-flat gradient, decoded
   logo, clipping, and text coverage at the expected geometry.

Current status (2026-08-28): those six bounded execution gates are green for
the exact two-file slice. `build_focus_widget_guest.sh` emits an arm64 Mach-O
executable, links the local SwiftUI implementation as static objects, executes
it under machorun on Linux, and produces a deterministic 270x270 PNG from the
unchanged Focus view. `FOCUS_WIDGET_GUEST.md` records the source/resource/root
attestations, pixel checks, reproduction command, and honesty limits. The
required reusable `libSwiftUI.dylib` packaging is still open, so this result is
not a claim that the complete framework architecture, S2, WidgetKit, or the
full Focus app is executable.

A macOS-native render, a compile-only module, a hand-recreated widget, or a
Linux process that never mounts/draws the exact Focus view does not satisfy S1.

### S2 — observation and unmodified onboarding

Compile the complete 21-source Onboarding target unchanged, then host
`OnboardingView` through its existing `PortraitHostingController`.

Required behavior checks include:

- `@ObservedObject` observes the exact `OnboardingViewModel`;
- its `@Published activeScreen` produces one invalidation on change;
- `TabView(selection:)`, `.tag`, and page style keep selection and page state in
  sync in both directions;
- the get-started button sends telemetry before changing screens;
- close/settings/skip actions retain the pinned side-effect order;
- `onAppear` is once per actual appearance, not every graph recomputation;
- touch/pan delivery works under the Linux OpenUIKit host.

The package emission gate also covers the four compile-only preview/support
requirements (`PreviewProvider` and `UIViewControllerRepresentable`) without
pretending they are runtime routes.

### S3 — real app hosting call sites

With the exact package products available, compile the three unchanged app
hosting files (`BrowserViewController`, `OnboardingFactory`, and
`SettingsViewController`) as part of their original target graph. Link probes
must show that `PortraitHostingController` and `UIHostingController` resolve to
the new guest SwiftUI dylib.

Runtime gates exercise the three shipping onboarding/widget routes and verify
presentation/dismissal against OpenUIKit controller state. This milestone is
still narrower than launching the complete app.

### S4 — settings, lists, forms, and navigation

Compile and execute the six app-target Internal Settings views plus the
`Licenses` target unchanged. This introduces `Form`, `Section`, `List`,
`ForEach`, `NavigationView`, `NavigationLink`, `ScrollView`, `Picker`, `Toggle`,
`TextField`, `State`, bindings, `onChange`, and `onReceive`.

The runtime gate covers dynamic rows, selection/binding round trips,
push/pop/navigation titles, scrolling, form control activation, disabled
state, text entry, and publisher delivery. Static screenshots alone are not
sufficient.

### S5 — WidgetKit and extension launch

`Widgets/Widgets.swift` is a separate first-party-framework boundary. It adds
`WidgetKit`, timeline/provider/configuration types, widget-family environment,
deep-link URLs, preview context, and iOS 17 container backgrounds. Keep the
SwiftUI module reusable, but track WidgetKit as its own port with its own
extension bundle and launch host. S1's `Widget` library render does not imply
that the Widgets extension runs.

### S6 — expand by measured app demand

After the complete Focus SwiftUI boundary is green, run the same token/source
inventory over the pinned app ladder. Add APIs only with a source consumer,
Apple behavior oracle where available, guest behavior test, renderer test when
visual, and license provenance for adapted donor code. Maintain per-API status
as compile-only, semantic, rendered, and Linux-executed instead of one binary
“supported” flag.

## Donor policy

`donor-lock.json` pins six permissively licensed candidates. None is accepted
as a drop-in dependency. Useful seams are:

- OpenSwiftUI: API-shape and compatibility-oracle patterns;
- Tokamak: result-builder/reconciliation/layout ideas;
- AltSwiftUI: UIKit-hosting and UIKit-control mapping patterns;
- SwiftCrossUI: backend abstraction examples;
- SwiftOpenUI: declarative graph, state/layout, and renderer contracts;
- QuillUI: a product actually named `SwiftUI`, re-export topology, selective
  compatibility extensions, and UIKit hosting/representable shapes.

Any adapted file must retain its license notice, identify repository and exact
revision, and receive an OpenUIKit-specific behavior test. The existing
OpenUIKit/Foundation/Combine identities remain authoritative; importing a
donor's whole GTK/AppKit/UIKit substrate would create a second incompatible
runtime and is outside this plan.
