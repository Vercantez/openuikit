# Portability — verified, not asserted

OpenUIKit claims to be a *portable* UIKit. This document records what was
actually tested, on 2026-08-25, rather than what the architecture intends.

Reproduce any time with `scripts/linux_verify.sh` (renderer),
`scripts/linux_selector_verify.sh` (the app-facing selector API),
`scripts/linux_realapp_verify.sh` (a REAL app's screen — M14) and
`scripts/objc_facade_verify.sh` (an Objective-C app — M15). All need Docker.

## Notification identity / bridge substrate matrix (2026-08-30)

Notification deliberately chooses identity by capability rather than by OS:

| build | value / ObjC carrier / queue | center and selector route |
|---|---|---|
| Foundation + Objective-C | aliases Foundation `Notification`, `NSNotification`, `OperationQueue` | aliases Foundation `NotificationCenter`; native zero/one-argument selector behavior and queue semantics |
| native ELF, Foundation visible | aliases Foundation values/carrier/queue; custom token subclasses Foundation.NSObject and assigns to Foundation.NSObjectProtocol | custom OpenUIKit center; `Selector.named` + registry because corelibs has no selector observer API |
| Linux-hosted Mach-O, Foundation hidden | custom value + public `_ObjectiveCBridgeable` NSObject carrier exposed as bounded `NSNotification`; custom queue | custom center; real Objective-C 0/1 metadata first, registry fallback second |

The hidden custom center prebridges once for selector delivery, preserving one
carrier identity across multiple NSNotification-typed observers while a
Notification-typed thunk unbridges the same box. Block observers still receive
the Swift value. Object filters use reference identity; name/object wildcards,
duplicates, weak selector/filter lifetime, token removal, and reentrant
snapshots stay in the portable center. Its queue is accepted and ignored.
Foundation+Objective-C builds do not inherit those custom promises: they use
Foundation's actual queue, ownership, and reentrant-removal behavior.

`Tools/notificationbridgeprobe/guest.sh` pins both non-Darwin routes. It builds
the candidate as a native-ELF external package client and runs it twice, then
compiles OpenUIKit and UIKit with Foundation hidden before assembling a tiny
app-facing Foundation module whose aliases match production's required shape.
Foundation-only, UIKit-only, and direct Foundation+UIKit sources are compiled
together; the Mach-O guest runs twice through pinned machorun, and its load
commands must contain no Foundation umbrella. The production support checkout
is separately owned and still needs those four FoundationGuest aliases before
the hidden route is end-to-end complete.

## Responder NSObject and selector dispatch substrate matrix (2026-08-30)

The responder hierarchy now has one semantic root across three distinct
substrates, without pretending they have the same compiler capabilities:

| build | NSObject provider | literal Swift `@objc` / `#selector` | action delivery |
|---|---|---|---|
| native Darwin | Foundation | yes | semantic built-ins, then NSObject runtime 0/1/2, then registry fallback |
| native ELF Linux | corelibs Foundation | no | `Selector.named` + `SelectorDispatching` registry |
| Linux-hosted `arm64-apple-macos15.0` guest, Foundation hidden | ObjectiveC | yes | semantic built-ins, then NSObject runtime 0/1/2, then registry fallback |

`UIResponder` selects Foundation's NSObject first, ObjectiveC's only when the
Foundation umbrella is unavailable, and fails compilation if neither exists.
`UIView` and `UIScene` no longer redeclare NSObject's inherited identity
`Equatable`/`Hashable` behavior. This makes responder controls such as
`UIDatePicker` Objective-C-representable on both ObjC-capable rows while
retaining ordinary NSObject identity on native ELF.

`Tools/objcselectordispatchprobe/guest.sh` is the cross-substrate gate. It
first compiles a native-ELF NSObject micro-oracle with `canImport(ObjectiveC)`
forbidden. It then freshly compiles all 12 OpenCoreGraphics and 102 OpenUIKit
sources plus the UIKit shim and a literal `import UIKit` guest with the pinned
Linux Swift 6.2.4 toolchain, while Foundation is hidden. Load commands must not
contain the Foundation umbrella. The linked ARM64 Mach-O guest runs twice via
the pinned `machorun` root with identical output and checks NSObject identity,
zero/one/two-argument actions, a typed UIDatePicker sender, and a typed UIButton
two-argument action whose event is identity-equal to the same touch event seen
by a closure. It also pins runtime precedence, registry fallback, the
`endEditing:` built-in, and weak target release.

At this responder slice's frozen boundary, `UIGestureRecognizer` and `UIEvent`
remained plain Swift classes and NotificationCenter/Timer were registry-only.
The Notification successor above now uses native Foundation or central 0/1
runtime dispatch; Timer remains registry-only. A live unresolved explicit target remains
nonfatal through `SelectorDispatch.onUnresolved`, unlike UIKit's exception,
and broader UIKit nil-target responder-chain routing is not claimed.

## M15 integrated: the three pieces hold together

M15 landed as three independent branches — Foundation coexistence,
`@MainActor` isolation, and the Objective-C facade — and each is verified in
its own section below. What the integration adds is that they hold
*simultaneously*, on the same tree, with no pixel moving:

| gate | result at the merged tip |
|---|---|
| `swift build` (macOS **and** `swift:6.2-noble`) | clean, zero warnings |
| 108 oracle scenes vs real UIKit | **108/108** |
| 9 scroll traces | **9/9** |
| `swift test` | **765** tests, 2 skipped, 0 failures |
| `scripts/linux_verify.sh` | **162/162 byte-identical** macOS vs Linux; 108/108 vs goldens |
| `scripts/linux_realapp_verify.sh` | **13/13 byte-identical** |
| `scripts/objc_facade_verify.sh` | ObjC PNG **== Swift PNG**, same SHA-256 |

Two interactions were real and are worth knowing about, because both are
places a future change could quietly break:

1. **`@_cdecl` cannot be actor-isolated**, so the C ABI needed an explicit
   crossing (`oukMain`, docs/OBJC_FACADE.md "The actor boundary"). It is
   `MainActor.assumeIsolated` — a check plus a straight call, no hop — which
   is exactly why the ObjC render is still byte-identical to the Swift one.
   A hop would have serialized differently and an unchecked
   `@MainActor @_cdecl` would have hidden the question.
2. **The ObjC facade now links Swift's Foundation transitively**, because
   OpenUIKit imports it. Visible in the verify run's `ldd` output
   (`libFoundation.so`, `libFoundationEssentials.so`, `lib_FoundationICU.so`)
   alongside `libobjc.so.4.6` and `libgnustep-base.so.1.31` — two
   Foundations, one process, no symbol collision, same bytes out. That is a
   result, not an assumption: gnustep-base's `<Foundation/NSGeometry.h>`
   declares `CGFloat`/`CGPoint`/`CGSize`/`CGRect` and corelibs-Foundation
   declares its own, and they coexist because the ObjC side and the Swift
   side only ever exchange `double`s across the ABI.

## M15: `@MainActor` isolation does not cost portability

`@MainActor` is Swift-concurrency, not Foundation and not ObjC, so it works
identically off Darwin — verified, not assumed. Re-run at the M15 tip in
`swift:6.2-noble`:

| check | result |
|---|---|
| `swift build -c release` of the library + `openrender` on Linux | **clean, zero warnings** |
| `scripts/linux_verify.sh` | **162/162 frames byte-identical** to the macOS render, 108/108 scenes vs the real-UIKit goldens |
| `scripts/linux_realapp_verify.sh` | **13/13 byte-identical** (3 headless + 10 live) |

Two notes for anyone porting further:

- **`MainActor.assumeIsolated` is stdlib, and back-deploys.** It needed one
  manifest change on the Apple side only — `platforms: [.macOS(.v11)]`,
  because naming `MainActor` requires a 10.15+ deployment target and SwiftPM
  was already linking these products for macOS 11. Nothing was added for
  Linux, and still **no `.unsafeFlags`**, so the package remains usable as an
  SPM dependency (the property Package.swift's header exists to protect).
- **The Linux toolchain is stricter, and that was useful.** Swift 6.2 on
  Linux flagged `#ConformanceIsolation` on the identity
  `Hashable`/`Equatable` conformances of the newly-isolated classes before
  anything else did. They are fixed with `nonisolated` witnesses, not
  suppressed.

## M14: a real app's source compiles and renders identically on Linux

The strongest portability statement to date, because the source under test is
not ours. `scripts/linux_realapp_verify.sh` builds the library, `openrender`,
`openhost` **and `Sources/RealAppProbe`** — four UNMODIFIED source files from
Automattic/pocket-casts-ios (docs/REAL_APP_TEST.md) — inside the same stock
container, then renders and replays them:

| check | result |
|---|---|
| `swift build -c release` with the vendored app source | **clean** — the app's own code compiles off Darwin |
| `openrender realapp` (3 headless configurations) | **3/3 byte-identical** to the macOS render |
| `openhost --app pocketcasts --script …` (10 recorded frames, SDL dummy driver) | **10/10 byte-identical** |

Run 2026-08-25: `REAL-APP SCREEN VERIFIED ON LINUX`, 13/13. The live replay
matters as much as the headless one: it drives real touches through the app's
`touchesBegan`, its `UISwitch` target-action and its tap-to-dismiss, so
identical bytes mean identical *behaviour*, not just identical drawing.

## Result

Built inside a stock `swift:6.2-noble` container (`aarch64-unknown-linux-gnu`,
Swift 6.2.4) — no Apple frameworks present at all:

| check | result |
|---|---|
| `swift build -c release --product openrender` | **clean** (library + quartz + CLI) |
| All 162 fixture frames rendered on Linux | **108/108 scenes pass** vs the real-UIKit goldens |
| Linux frames vs the macOS frames, SHA-256 | **162/162 byte-identical** |

**Re-verified 2026-08-25 at the M13 wrap-up commit on `master`**
(`scripts/linux_verify.sh`), i.e. at the M14 tip with all four M13
app-compat clusters *and* M14 merged: Swift 6.2.4,
`aarch64-unknown-linux-gnu`, **24.73 s** clean build, 162 frames rendered,
**108/108 scenes pass**, **162/162 byte-identical** to the macOS render,
`PORTABILITY VERIFIED`. This is the run that clears the wrap-up gate — no
cluster broke portability and nothing had to be fixed to make it pass.

The M14 additions carried one specific risk worth naming, because it is the
kind that would show up here and nowhere else: **Dynamic Type is driven by a
vendored JSON table** (`Resources/dynamic_type.json`, the verbatim
`Tools/oracle2/dyntypeprobe` dump) rather than by querying a host text system,
so `UIFontMetrics` and `UIFont.preferredFont(forTextStyle:)` resolve to the
same numbers off Darwin as on it. Byte-identical output across all 162 frames
is the proof that no host lookup crept in.

Earlier runs: M13 merge (108/108, 162/162, 23.6 s), M12 (96/96, 150/150),
M11 (81/81, 135/135), M10 (80/80, 134/135).

The M13 clusters were each verified on their own branch too, but the merge is
the run that matters: `UICollectionView`, the bar-item platters, the menu
machinery and `NotificationCenter`/`Timer` had never been compiled together
off Darwin before this. The portability risks they each carried —
`NotificationCenter` and `Timer` shadowed Foundation types at that historical
merge boundary, and the
menu/bar clusters lean on the M12 selector dispatch that already had a Linux
path — all held.

### How each M12 cluster kept the property

| cluster | the portability risk | what was done |
|---|---|---|
| Attributed text | `NSAttributedString`/`NSParagraphStyle` are Foundation types | Declared in OpenUIKit instead — see below. Underline/strikethrough rects are a vendored measured table (`text_decorations.json`), so the decoration path needs no text engine. |
| Image codecs | PNG/JPEG decoding is a system service on Darwin | Routed to the `stb_image` copy already inside the vendored CQuartz, via an additive C API (`patches/quartz/005-image-io-memory.patch`). No decoding code in OpenUIKit, no platform image framework, and `UIImage(named:)` resolves against `OpenUIKitRuntime.imageSearchPaths` — empty by default, so the library hardcodes no host paths. |
| App lifecycle | `UIApplication`/`UIDevice`/`UIScreen` are inherently host-facing | No run loop and no wall clock enter the core: `UIApplicationMain` returns and the host drives five `_host…` methods. `UIScreen` is fed by the host's real surface; `UIDevice`'s values are *declared constants*, and its header says so, precisely because the process may be on Linux. |
| Alerts | measured metrics could have been read from a live UIKit | They are vendored constants from a Simulator probe, not a runtime query. `UIScreenMetrics`' safe-area insets are likewise hardcoded measurements (a real gap — docs/KNOWN_GAPS.md — but a portable one). |
| Two-cut font fix | a second font *file* would have been a host dependency | `OpenUIKitRuntime.systemFontCut` subtracts a measured per-size constant from the existing vendored table. Pure data; no `.SFUI` file is loaded or needed for metrics. |

Byte-identical output across two operating systems and two C++ standard
libraries is the strongest form of the claim: the renderer is deterministic
and carries no host dependency.

## Selector target-action, verified on Linux (M12)

This section records the original portable M12 result. The responder-root
matrix above is the current Objective-C-capable behavior; the native-ELF
registry and frame-replay result below remain unchanged.

`scripts/linux_selector_verify.sh` proves the app-facing API of
docs/OBJC_RUNTIME.md is portable, not just the renderer. Inside the same
`swift:6.2-noble` container (plus `libsdl2-dev`):

| check | result |
|---|---|
| library + `openrender` + **`openhost`** build | **clean** |
| selector dispatch tests (the portable 23 of the 27) | **23/23 pass** |
| `openhost --app selectors --script …` replayed headlessly | **10 frames** |
| those frames vs the macOS frames, SHA-256 | **10/10 byte-identical** |

The replayed screen (`Sources/DemoApp/SelectorApp.swift`) is wired *entirely*
with `addTarget(_:action:for:)` and `UITapGestureRecognizer(target:action:)`
— no closures — and it renders a live counter, so a selector that failed to
fire would change the pixels. Byte-identical frames therefore prove the
actions dispatched identically on both operating systems.

This also closes the "`openhost` was not built on Linux" gap below. Building it
there took two fixes, both real portability bugs that only a Linux host run
could expose:

1. **`SDLHost` demanded an accelerated renderer**, which the headless dummy
   video driver cannot provide, so `openhost` died in `SDL_CreateRenderer`.
   It now falls back to a software renderer. Captured frames come from the
   `Bitmap`, not from SDL, so the fallback cannot change output.
2. **`openhost` never read `OPENUIKIT_FONT_DIR`** — only `openrender` did.
   That went unnoticed while `openhost` was a macOS-only tool with the system
   SF available. On Linux the first run dropped every glyph outside the
   harvested ink table: "Target-Action" rendered as "Target tion",
   "Increment" as "n re ent", and the counter digits vanished entirely. The
   same env-var block openrender has now lives in `openhost` too.

The second one is worth dwelling on: it is the "fonts are the one host
dependency" gap below, in a new place, and it was invisible until something
other than `openrender` ran off Darwin.

### Two Linux XCTest quirks found on the way — neither is ours

Both matter to anyone wiring `swift test` into Linux CI, and both were
confirmed against **untouched** suites, so neither is a property of the
selector work:

1. **`swift test` hangs outright** in this container. Its harness blocks in
   `poll()` with no TTY while the XCTest child sits idle — indefinitely
   (killed after 27 minutes; the same tests run in 5 ms when invoked
   directly). The script therefore does `swift build --build-tests` and runs
   the `OpenUIKitPackageTests.xctest` bundle itself.
2. **The bundle hangs mid-run roughly one launch in five**, at a different
   test each time, sleeping in `poll()` with a second thread in
   `epoll_wait`. Measured over 10 launches each: `UIControlTests` 3/10 hung,
   `GeometryTests`+`ColorTests` — *purely computational, no window, no
   touches, no selectors* — 2/10 hung. So it is the Swift 6.2.4 Linux XCTest
   runtime in this image, not the library. The script runs the bundle under
   `timeout` and retries, and requires a real
   "Executed N tests, with 0 failures" line before passing.

Neither reproduces on macOS, where the full 427-test suite runs green every
time.

## M15: the library imports Foundation, and there is exactly one `CGRect`

**Superseded below: "the library imports no Foundation" was true through M14
and is no longer the rule.** What replaced it is narrower and more useful.

The old rule bought portability by *declaring* every Foundation-shaped type
OpenUIKit needed. docs/APP_COMPAT.md measured the bill: an app that imports
both OpenUIKit and Foundation — every real app, because its model layer is
Foundation — saw two types of each name, and the compiler refused to pick.
`NSCoder` alone appears in 344 of the corpus's 5,099 files, and every test
file in this repo carried four to six `private typealias CGRect =
OpenUIKit.CGRect` lines to work around it.

The collision was never missing API. It was duplicate NAMES, and the fix was
subtraction:

| type | M14 | M15 |
|---|---|---|
| `CGFloat`, `CGPoint`, `CGSize`, `CGRect` | declared in `OpenCoreGraphics/Geometry.swift` | `typealias` to Foundation's |
| `CGVector` | declared | Foundation's where it exists (Darwin); ours on Linux, which has none — **measured** |
| `IndexPath` | declared in `UITableView.swift` | Foundation's, with UIKit's `init(row:section:)` / `.row` / `.item` / `.section` added as extensions, exactly as real UIKit does |
| `NSRange`, `NSRangePointer`, `NSMakeRange` | declared in `NSAttributedString.swift` | Foundation's |
| `TimeInterval` | declared in `UITouch.swift` | Foundation's |

A `typealias` is what makes it safe. Unqualified lookup that finds a typealias
AND the type it aliases resolves to one declaration, so `import Foundation` +
`import OpenUIKit` in one file is unambiguous. Aliasing rather than
`@_exported import Foundation` is also deliberate: it puts the names in
OpenUIKit's namespace, so the other ~100 source files keep compiling with no
per-file Foundation import, and `CGColor` / `CGAffineTransform` never have to
fight CoreGraphics' for the name on Darwin.

**The proof:** 151 `private typealias` lines deleted from 40 test files, and
`Tests/OpenUIKitTests/FoundationCoexistenceTests.swift` — which imports
Foundation the way an app does and would not compile before this — is green.
So is the gate that matters: 108/108 scenes and **162/162 byte-identical**
frames on Linux.

### What is deliberately NOT aliased, and why

Each of these was measured, not assumed. Full statement in
`Sources/OpenUIKit/FoundationTypes.swift`.

- **`CGAffineTransform`.** Linux Foundation has none, so there is no collision
  to remove there — and one shared implementation is what keeps the render
  byte-identical, because `init(rotationAngle:)` uses the library's own sine
  series rather than libm, which is not guaranteed bit-identical across two
  libcs. **The one residual collision:** on Darwin, `import Foundation` does
  re-export CoreGraphics' `CGAffineTransform`, so a Darwin file that imports
  both still needs `OpenUIKit.CGAffineTransform`. On Linux — the target
  platform — there is nothing to disambiguate.
- **`NSAttributedString` / `NSMutableAttributedString`.** MEASURED on Swift
  6.2 Linux: `NSMutableAttributedString.addAttribute` **traps** the second
  time a plain Swift value is stored under a key, because run coalescing calls
  `isEqual` on the boxed value. Every OpenUIKit attribute value (`UIFont`,
  `UIColor`, `CGFloat`, `NSParagraphStyle`) is a plain Swift value, so
  Foundation's attributed string cannot hold UIKit's attributes on the target
  platform at all.
- **`Notification` / `NSNotification` / `NotificationCenter` /
  `OperationQueue`.** Values/carrier/queue alias Foundation whenever it is
  visible, and Foundation+Objective-C aliases its center too. Native ELF keeps
  the custom center because corelibs has no selector method and its block
  object-filter behavior diverges. A Foundation-hidden Objective-C build uses
  the custom bridged family described in the matrix above.
- **`Timer` / `RunLoop`.** They run on the SCRIPTED host clock
  (`UIWindow.tick(timestamp:)`). Foundation's run on `Date`, which would put
  wall-clock time in the frame loop and end byte-identical rendering.

### The determinism rule that replaced the no-Foundation rule

Importing Foundation is now allowed. Reading a **wall clock, a locale or a
random source** from the render or layout path is not, and that is what makes
the Linux frames byte-identical. It is enforced, not asserted:
`FoundationCoexistenceTests.testRenderPathReadsNoWallClockLocaleOrRandomSource`
scans both library targets and fails on `Date(`, `NSDate`, `DateFormatter`,
`Calendar(`, `Locale(`, `gettimeofday`, `clock_gettime`, `mach_absolute_time`,
`CFAbsoluteTimeGetCurrent`, `arc4random` or `UUID(` outside a comment.

### One Swift rule worth knowing before you touch this

A **default argument** (`init(frame: CGRect = .zero)`) and an `@inlinable`
body may only use members whose defining module *that file* imports — the one
place the geometry types do not ride in on OpenCoreGraphics' typealias. 31
files therefore carry a **scoped** import (`import struct
CoreGraphics.CGRect`, …). The scoping is load-bearing, not tidiness: the
unscoped `import CoreGraphics` breaks 8 files by dragging CoreGraphics'
`CGColor` and `CGAffineTransform` into scope beside OpenCoreGraphics' own.

## What made it work

- ~~The library targets import **no** Foundation and no Apple framework.~~
  **Superseded at M15 — see the section above.** Through M14 the rule read:
  the library targets (`OpenUIKit`, `OpenCoreGraphics`) import **no**
  Foundation and no Apple framework — a rule enforced since day one. The
  audit found zero violations and zero `#if os(...)` conditionals. The current
  substrate seams use `#if canImport(ObjectiveC)` in `UISelector.swift` for
  the selector type/runtime path and a Foundation-then-ObjectiveC provider
  choice in `UIResponder.swift` for NSObject. These are capability checks, not
  OS-name branches; native ELF takes Foundation identity plus the portable
  selector registry, while the Foundation-hidden Apple guest takes the staged
  Objective-C runtime.
- `CQuartz` (the vendored Quartz 2D + CoreAnimation implementation) is
  portable C++17 and compiled unmodified on Linux.
- Text **metrics** come from a vendored data table (`font_metrics.json` —
  the macOS `.SFNS` cut of San Francisco; `OpenUIKitRuntime.systemFontCut`
  switches to the measured iOS `.SFUI` advances, see docs/KNOWN_GAPS.md),
  text **ink** from harvested masks (`glyph_ink.json`) and
  underline/strikethrough **rects** from a measured table
  (`text_decorations.json`, M12) — all data, so layout and most glyph
  rendering need no font files and no system text engine.
- Attributed text (M12) keeps the rule: `NSAttributedString` and
  `NSParagraphStyle` are OpenUIKit's own types, not Foundation's, precisely
  so the attributed path stays Foundation-free off Darwin. The cost is name
  shadowing for apps that import both — docs/KNOWN_GAPS.md.
- The controls2 cluster (2026-08-25) originally extended the same tradeoff to
  Notification and Timer. The Notification successor now uses the capability
  matrix above: only the custom native-ELF/Foundation-hidden centers ignore
  `queue:`; Foundation+Objective-C honors it. **`Timer` / `RunLoop`** remain
  declared in OpenUIKit, and Timer fires from
  `UIWindow.tick(timestamp:)` rather than from a wall clock — the same
  host-clock discipline that already drives scroll physics, transitions and
  animation completions, and the reason a timer can never make a golden
  non-reproducible.

## Two fixes this exercise required

1. `Sources/openrender/SceneIO.swift` used `CFGetTypeID`/`CFBooleanGetTypeID`
   (CoreFoundation, Darwin-only) to tell a JSON `true` from a `1` coming back
   from `JSONSerialization`. Replaced by parsing with OpenUIKit's own MiniJSON,
   which distinguishes the two natively — portable *and* less ambiguous.
2. Glyphs **not** covered by the harvested ink table fall back to rasterizing
   from a font file, and the built-in search paths were macOS-only. Off Darwin
   there is no system SF, so those glyphs silently did not draw (`"Library"`
   rendered as `"Li rar"` — the 34pt bold `b` and `y` were missing while
   everything else was pixel-perfect). Added `OPENUIKIT_FONT_DIR=<dir>`, which
   registers `SFNS.ttf` / `SFNSMono.ttf` / `SFNSItalic.ttf` from a directory
   the user supplies. Apple's fonts are not redistributable, so shipping them
   is not an option; pointing at a copy is.

## Honest gaps

- **Fonts are the one host dependency.** Glyphs outside the harvested ink
  table fall back to rasterizing from a font file, and off Darwin there is no
  system SF. At M10 a Linux run without `OPENUIKIT_FONT_DIR` rendered
  122/134 frames byte-identically and **still passed 80/80** while dropping
  letters — that is the blind spot the structural gates were built for.

  Re-measured at the M12 tip (2026-08-25) with both structural checks active:
  the same no-font run now **fails 22 of 96 scenes**. Every failure is on the
  structural gates alone — **zero** layout issues anywhere, and every
  percentage score is 97.4–99.9, i.e. all 22 are still above their category
  thresholds and would all have passed on the percentage:

  | caught by | scenes | worst / best score |
  |---|---|---|
  | content absence **and** the blob cap | 11 — `navbar_large` (blob 260.8 pt², the missing 34 pt `b` of "Library"), `navbar_dark` (258.2), `constraints_baseline` (137.2), `attrtext_runs` (136.2), `modal_sheet` / `modal_sheet_grabber` (108.0), `tabbar_basic` / `tabbar_tinted` (94.5 / 90.8), `alert_basic` / `alert_destructive` / `alert_actionsheet` (83.2) | 97.48 / 99.42 |
  | **content absence only** (blob under the 80 pt² cap) | 11 — `attrtext_fields` (59.8), `tableview_dark` (54.2), `navbar_inline` (50.2), `alert_dark` (48.5), `control_segmented` (39.0), `attrtext_underline_strike` (34.0), `control_dark` (33.8), `tableview_grouped` (29.8), `attrtext_paragraph` (22.5), `constraints_compression` (21.8), `attrtext_dark` (12.8) | 97.42 / **99.89** |

  The second row is the whole argument for having two checks. Those scenes are
  missing **body text** rather than display-size glyphs; their stems are ~2
  device pixels wide, so they never form a blob large enough to trip the size
  cap. `attrtext_dark` is the extreme case: a 4.0 × 8.5 pt hole where the
  golden has ink, on a frame scoring **99.892 %** — invisible to both the
  percentage and the blob cap, caught by absence alone. The check added in M12
  therefore doubled the catch rate on this exact failure mode (11 → 22),
  and every scene it caught it caught correctly.

  Fixes for the underlying dependency, in order of preference: extend the
  harvest (pure data, keeps the zero-dependency property), ship a
  metrically-compatible libre font, or supply SF. Reproduce the no-font run by
  dropping `OPENUIKIT_FONT_DIR` from `linux_verify.sh`'s inner script.
- ~~**The thresholds have a blind spot this exposed.**~~ **FIXED 2026-08-25.**
  `navbar_large` passed at its category threshold while visibly missing two
  letters, because the affected pixels were a small fraction of a large
  canvas. compare.py now runs a **structural gate** alongside the percentage:
  connected components of the severe-diff mask (delta > 150 counts), failing
  any frame with a contiguous wrong region over 80 pt². The exact corruption
  that slipped through measures 248.8 pt² and now fails, while all 96 scenes
  still pass. M12 added the **content-absence** check beside it, after the
  same class of failure proved able to hide body text under the size cap (see
  the font gap above). Design, calibration table and the one case neither
  check can see: docs/SCENE_SPEC.md "Structural diff gate".

  Note for whoever tunes this next: the 80 pt² cap was calibrated on a "worst
  legitimate component 33.2 pt²" that turned out to be the two-cuts-of-SF bug,
  not a rasterization limit. With that fixed the worst legitimate component
  over all 96 passing scenes is **20.0 pt²** (`stack_alignment`,
  `anim_concurrent`), so the cap could be tightened considerably — the calibration
  comment in compare.py is stale (docs/KNOWN_GAPS.md).
- ~~**`openhost` was not built on Linux**~~ **FIXED 2026-08-25.**
  `scripts/linux_selector_verify.sh` installs `libsdl2-dev`, builds `openhost`
  on Linux and runs a scripted capture headlessly under
  `SDL_VIDEODRIVER=dummy`; the frames match macOS byte for byte. Only the
  `--app selectors` script is replayed there so far — extending it to the
  other apps and to `--nav-demo` is mechanical.
- x86-64 Linux is untested (this ran on arm64). No reason to expect trouble;
  no evidence either.
