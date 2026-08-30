# App compatibility — measured, then prioritized

**Goal: run and test real UIKit apps on OpenUIKit instead of stock UIKit.**

This file replaces guesswork with a census. `Tools/apicensus/census.py` scans
real open-source UIKit apps, counts every UIKit symbol they reference, and
diffs against what OpenUIKit exports — so the roadmap is ordered by what apps
actually use, not by UIKit's alphabet.

**Where this stands (updated 2026-08-30):** **97.1% effective
coverage** of what four real apps reference, 474 uses (2.9%) of
genuinely-missing types left, and a *screen* from a shipping app rendering
with **99.3%** of its source unmodified — 4 changed lines out of 605, down
from 14 at M13. M15 retired ten of those fourteen in three passes: Foundation
coexistence (5 lines), `@MainActor` isolation (4), and the harness
access-level line (1). **All 4 survivors are the single `#selector`/`@objc`
row in the native-ELF harness**, where the Swift compiler still rejects both
spellings. On Objective-C-capable targets, the responder-root selector slice
below removes the former OpenUIKit runtime/table cost for responder controls;
the historical real-app ledger has not been redefined to omit its Linux build.
See docs/REAL_APP_TEST.md for that distinction.

## Reminder UIKit `#Preview` source slice (2026-08-30)

Starting from exact Notification/bridge base
`83fbcbe2204eb836968d4e73ecfecec7b20c68ef`, the unchanged Reminder revision
`2edfc88c386b8dec1683339f58e05054c5e9ce1f` now advances from its sole
remaining front-end error to **zero diagnostics** across all 22 Swift sources.
The removed error is exactly `no macro named 'Preview'`; no error is added and
no app or vendor byte changes. `Tools/reminderpreviewprobe` pins the app tree,
whole-source SHA-256, all 26 established direct call-site lines plus the exact
three-line Preview, complete
diagnostic multisets, framework boundary, dependency/provenance identities,
fresh no-hardlink inputs, output hygiene, and tamper negatives.

This is a functional macro slice rather than a source-erasing workaround.
The native host plugin generates a unique `DeveloperToolsSupport.PreviewRegistry`
with file/line/column metadata and a main-actor `makePreview()` whose stored
body constructs Reminder's real `CreateViewController`. Literal UIKit clients
prove identical stored `UIView` and `UIViewController` instances. The host
plugin remains native to the build machine while the metadata and app objects
are emitted for their requested target, including the Linux-hosted ARM64
Mach-O path. SwiftSyntax is pinned compiler tooling, not an application
runtime dependency.

Zero front-end diagnostics does not imply a preview canvas or an app launch.
The bounded public surface accepts unnamed, single-expression UIView and
UIViewController previews. Named/trait previews, richer builders, SwiftUI
preview content, registry discovery, interactive preview hosting, hot reload,
and launch/package resource closure remain independent work. Exact behavior,
proof boundaries, native oracle facts, and OpenSwiftUI MIT attribution are in
`docs/PREVIEW.md`.

The file is written newest-last within each topic; if you want only the
current picture, read **"The punch list, re-ranked at the M15 tip"** (below),
**"Missing MEMBERS of types we already export"**, then docs/REAL_APP_TEST.md.
Everything else is the record of how the number got there, and the superseded
sections are marked as such.

## Reminder system-image source slice (2026-08-30)

The unchanged 22-file Reminder app at upstream revision
`2edfc88c386b8dec1683339f58e05054c5e9ce1f` exercises ten
`UIImage(systemName:)` expressions and one `UIImage.SymbolConfiguration`
weight-inference cascade. A pinned whole-source typecheck now reports **45 →
34 diagnostics** against the exact pre-slice base versus this implementation:
all **11 system-image diagnostics disappear**, no diagnostic is added, and the
remaining 34-error multiset is otherwise identical. The source subject is
tree `66474f2d47cc80ee551da990d748ddcc1b32aa1b`, SHA-256
`3a29a577f6290d27c09206798ab6446335eeb18a06502bfaa4d2f835850858d4`;
the app repository stays clean. `Tools/remindersystemimageprobe` owns the
external entry-point shim and reproducible census, so no app or vendor source
is patched.

This is a deliberately bounded portable provider, not a redistribution or
reimplementation of Apple's SF Symbols library. It recognizes exactly the six
case-sensitive names Reminder uses: `calendar`, `clock`, `multiply`,
`plus.circle.fill`, `circlebadge`, and `checkmark.circle.fill`. Project-authored
procedural paths render them without fonts, bundles, asset catalogs, or host
framework resources; unsupported and malformed names fail closed. The public
iOS 13 surface includes `UIImage.Configuration`, `SymbolConfiguration`, all ten
`SymbolWeight` raw values, both system-name initializers, and `isSymbolImage`.
Configuration construction, external subclassing, distinct value-copy,
secure archive, and dynamic-subclass-preserving copy behavior are covered by
literal external-module gates and compared with UIKit 26.1. One pure-Swift
class-factory limitation remains: OpenUIKit must route inherited subclass
construction and copy through the subclass's required coder initializer,
whereas Objective-C UIKit bypasses it. A subclass coder that rejects the
internal keyed seed can therefore fail a nonfailable factory. Reminder neither
subclasses nor archives configurations, so this has no effect on its source or
runtime path; the exact boundary is recorded in `KNOWN_GAPS.md`.

Native metadata and pixel oracles also pin the six default 1x/2x alignment
bounds and Reminder's 56-point regular plus size. System images retain
automatic template intent through tint/render-mode copies; an `UIImageView`
resolves ambient dynamic tint in its own traits, while ordinary automatic
rasters remain original. The layer-content cache fingerprints the resolved
template tint. Both renderer backends have closed procedural pixel hashes. The
candidate-owned image/configuration/root-frame/image-content/stable-composite
allocation paths added or changed by this slice reject non-finite or oversized
inputs before integer conversion or allocation. This is not a claim that
arbitrary hostile descendant style/transform values are sanitized; that
pre-existing renderer boundary remains in `KNOWN_GAPS.md`.
`Tools/systemimagehiddenprobe` carries the literal-UIKit, Foundation-hidden
six-symbol/hash/tint/safety closure. Its arm64 Mach-O probe builds and launches
unchanged on Linux through `machorun` against support commit
`777e7c083a90452841009f56eec959c098761113`. At that landed boundary,
`UIDatePicker` was the next Reminder UIKit blocker; the successor slice below
measures it independently. A full unchanged Reminder launch remains later
integration work; this slice does not depend on the rejected support
experiment.

## Reminder UIDatePicker source and runtime slice (2026-08-30)

The same unchanged Reminder revision, tree, 22-source subject, and SHA-256
listed above exercise two direct picker paths: a 320 x 320 inline `.date`
picker and a 160 x 160 wheel `.time` picker. The pinned whole-source census
against system-image base `8f98af2e53af566923de6616f3629bec0661aa8c`
now reports **34 -> 12 diagnostics**. Exactly **25 old diagnostics are
removed**, **3 deeper diagnostics are exposed**, and **9 remain unchanged**.
The three exposed errors are the pre-existing popover `backgroundColor`
member and two Objective-C selector/representability boundaries that could
not be diagnosed while `UIDatePicker` itself was missing. This is not a
claim that the app compiles: the exact twelve-error multiset remains pinned.
`Tools/reminderdatepickerprobe` rebuilds the base and candidate from clean
clones, verifies every direct call-site line and the whole source hash, uses
only an external process-entry shim, and rejects app/vendor or unexpected
candidate paths. Reminder source is never edited.

The public slice contains the open iOS 2 `UIDatePicker`, all five mode raw
values, all four iOS 13.4 style raw values, the native open model members and
frame/coder/zero-initializer topology, and the measured introductions for
`.inline` (iOS 14), `roundsToMinuteInterval` (iOS 15), and `.yearAndMonth`
(iOS 17.4). A literal external `import UIKit` subclass gate covers every
picker-specific open member. The committed iOS 26.1 oracle pins defaults,
rounding toggles, interval changes, non-grid-aligned bounds, countdown entry
and duration transitions, direct and method date updates, and zero
programmatic events. A source-level gate pins each granular introduction to
the corresponding UIKit 26.1 symbol-graph declaration.

Portable date evaluation is deliberately deterministic. Default construction
uses the exact finite host-supplied `Timer.currentTime` in Foundation's
reference-date domain. The nil-calendar/default environment is a snapshotted
Gregorian calendar with `en_US_POSIX`, UTC, Sunday first, and one minimum day
in the first week; it never reads process current or autoupdating providers.
Entering countdown derives current-day start from that same explicit host
clock. Non-finite and excessively distant public dates fail closed before a
Calendar call. These choices and their native-current-environment divergence
are explicit in `KNOWN_GAPS.md`.

Both Reminder-sized presentations render visible deterministic content under
the Quartz/layer and Swift/render-pass routes. Closed hashes cover 320 x 320
inline date and 160 x 160 wheel time crops. Public UIWindow touch routing
selects an inline day or wheel row with exactly one `.valueChanged`; clamped
touches and every programmatic setter emit zero. This is a bounded functional
picker, not an iOS pixel reproduction: English/24-hour labels,
non-Gregorian fidelity, compact overlays, wheel physics, accessibility, and
host localization remain outside this slice.
Picker-owned presentation viewports must have finite positive bounds, with
origin magnitude and dimensions no larger than 16,384 points. Unsupported
frame/bounds inputs collapse the private presentation frames to zero and make
picker touch handling inert before wheel row-count arithmetic; this is a
portable hostile-input limit, not a measured UIKit size policy.

`Tools/datepickerhiddenprobe` closes the corresponding Foundation-hidden
compile/link/runtime gate without weakening the historical system-image proof.
It pins clean support commit
`3aea5dfa7858ec607183f4233fbb678babb9fb1e` (tree
`89b8640036f1982f47b07d5d8da9b9fb339ee244`, sole parent `777e7c...`), the
Swift 6.2.4 ARM64 Docker toolchain, the surviving FoundationEssentials
modules/objects, and exact 12/102 OpenCoreGraphics/OpenUIKit source censuses.
The gate freshly compiles every framework source plus the literal `import
UIKit` predecessor and DatePicker guests, links direct pinned
FoundationEssentials objects with fresh C compatibility objects, rejects a
direct Foundation/CoreFoundation load, and launches through Linux `machorun`.
The predecessor runs once; DatePicker runs twice with byte-identical expected
stdout and empty stderr. Its transcript covers the explicit host clock,
calendar reset, non-grid bounds, rounding toggle, countdown setters, translated
public wheel touches, zero programmatic events, and repeat-identical 320 x 320
inline/160 x 160 wheel pixels.

That hidden provider has one measured substrate boundary: without
FoundationInternationalization, pinned FoundationEssentials uses its
unlocalized locale implementation and exposes a requested `en_US_POSIX` as
`en_001`. The guest asserts both the exact request and the exact exposed value;
full-Foundation macOS tests continue to require `en_US_POSIX`. The two
providers also retain separate closed render hashes instead of rewriting
pixels to make unlike locale/Foundation stacks appear identical. This runtime
proof is the bounded picker path, not a complete unchanged Reminder launch.

## Reminder presentation state and table-row-move slice (2026-08-30)

The unchanged Reminder revision and 22-source subject pinned by the picker
slice now typecheck against one direct successor to DatePicker commit
`0d08b8768db6b3a077192be04bcb13e18199c049`. The complete diagnostic
multiset moves from **12 -> 7**: exactly the missing popover
`backgroundColor` plus `.systemBackground` cascade, missing
`modalTransitionStyle` plus `.crossDissolve` cascade, and missing
`UITableView.moveRow(at:to:)` diagnostic disappear. No diagnostic is added;
the remaining seven are byte-for-byte unchanged. The Reminder commit, tree,
whole-source SHA-256, all 22 source paths, and the union of the prior 20 picker
lines with the 3 new presentation/table lines are pinned. The resulting
`call_sites=23` census and exact candidate changed-path boundary live in
`Tools/reminderpresentationtableprobe`; app and vendor source remain clean.

`UIModalTransitionStyle` carries UIKit's raw values and platform availability,
and the externally overridable `UIViewController.modalTransitionStyle`
defaults to `.coverVertical` and round-trips all styles. This is **state
compatibility only**: assigning `.crossDissolve` does not change OpenUIKit's
built-in sheet/full-screen animator or claim native transition pixels or
timing. The iOS 8 popover controller, controller accessor, and
`backgroundColor` are externally overridable with the measured nil/set/reset
state. OpenUIKit still adapts every popover to its compact sheet route and
does not draw regular-width arrow/chrome; the stored color does not yet paint
that missing surface.

The open iOS 5 `UITableView.moveRow(at:to:)` now applies a valid,
already-committed data-source move without recycling visible cells that remain
in the viewport. Direct moves and exactly one move inside an outer
`beginUpdates()` / `endUpdates()` transaction preserve cell identity,
destination frames, visible order, and selection through same-section,
cross-section, off-screen, and no-op permutations. Pending structural batches
suppress intermediate layout/scroll retiling until the outer commit, so a
nested viewport change cannot read post-move items under pre-move keys.
Multiple moves, move-plus-insert/reload, dirty pre-update metrics, and invalid
slots take the coherent full-rebuild path. They intentionally make no cell
identity or animation claim; `RowAnimation` remains a visual hint rather than
implemented row-transition pixels.

`Tools/presentationtableprobe` is the committed iOS 26.1 native boundary. With
animations disabled, it pins only public enum/property/color state and the
direct/pure-single-batch cell identity, exact destination frames, visible
order, and selection remapping measured by the preserved oracle. It does not
measure cross-dissolve pixels/timing, animated row interpolation,
regular-width popover rendering, invalid-index exceptions, or mixed-batch
identity. The seven remaining Reminder diagnostics are two picker Objective-C
selector/representability errors, trait registration, text optionality,
`#Preview`, `Notification` ambiguity, and the `endEditing` selector boundary;
this is not yet a claim that unchanged Reminder compiles or launches.

## Reminder trait, text, and framework-selector slice (2026-08-30)

The next exact successor starts at presentation/table commit
`99c0e9a65bcfbab9041b76782b0d390c435b2725` and advances unchanged Reminder's
complete diagnostic multiset from **7 -> 4**. Only three errors disappear:
the missing controller `registerForTraitChanges` handler overload,
`UITextView.text` being non-optional at an optional-binding call site, and
`#selector(UIView.endEditing)` lacking Objective-C exposure. No diagnostic is
added and no app or vendor source is edited. The gate retains the exact
Reminder commit/tree/22-source hash, pins the prior 23 call-site lines plus
the three new lines (`call_sites=26`), and requires the exact 21-path candidate
boundary. The four byte-for-byte remaining errors are the two
`UIDatePicker` Objective-C representability errors, `#Preview`, and the
Foundation/OpenUIKit `Notification` ambiguity. Unchanged Reminder therefore
still does not compile or launch.

The trait addition is intentionally a bounded handler-form surface, not a
claim that the iOS 17 trait system is complete. A `UIViewController` owns its
registrations without loading its view; dropping the caller's token does not
unregister it, explicit unregister suppresses later delivery, and replacing
the root view does not lose the registration. Known modeled axes are filtered
by metatype identity and their previous/current values; an unknown custom
trait is delivered conservatively on an explicit event. Delivery is
synchronous only when a host calls
`UIView._traitsDidChange(previous:)` with the root's complete effective prior
collection. OpenUIKit does not yet export the full `UITraitChangeObservable`
protocol topology, selector overloads, `traitOverrides`, `UIMutableTraits`,
or automatic system/window/override-setter delivery. Within that portable
host seam, modern controller handlers run before OpenUIKit's existing legacy
callback as a deterministic local policy. A separate iOS 26.1 check confirms
that order for one immediate attached light-to-dark direct trait override;
it does not claim legacy callbacks are globally filtered or exactly once.

`UITextView.text` is now externally overridable with UIKit's imported
`String!` shape. It accepts optional binding and both `String!` and `String?`
downstream override spellings. A nil assignment normalizes immediately to a
non-nil empty string while clearing attributed content, clamping the caret,
and invalidating text layout. This is the native header's
`null_resettable` contract rather than a nullable stored-content claim.

On Objective-C-capable targets `UIView.endEditing(_:)` exports the exact
`endEditing:` selector. Native ELF Linux retains the same pure-Swift method
without an Objective-C attribute; a Linux-hosted Mach-O Apple target remains
Objective-C-capable and uses the attributed branch. `SelectorDispatch` has
one framework-owned built-in for that exact one-argument selector, so an
unchanged tap recognizer can reach the view without making the app conform to
`SelectorDispatching`.
iOS 26.1 passes `false` for this target/action spelling; OpenUIKit does the
same and treats the selector as resolved even when `endEditing(false)` returns
false because a text delegate refuses. At this predecessor slice boundary it
was not a general Objective-C dispatcher or a solution for app-defined
`@objc` methods and Objective-C-unrepresentable OpenUIKit class parameters.
The responder-root successor below supersedes the first limitation for its
measured target/sender family.

`Tools/traittextselectorprobe` is the committed iOS 26.1 native boundary for
the text null reset, exact selector name/direct method, rejecting-responder
semantics, target/action's measured `false` argument, matching/same/unrelated
trait delivery, bounded direct-style handler/legacy order, unregister, and
observable-owned token lifetime. Literal
`import UIKit` and portable runtime tests separately pin no initial controller
delivery, no registration-time view load, root replacement, child effective-
trait filtering, optional override topology, actual recognized-tap delivery,
and unresolved-selector reporting. `Tools/remindertraittextselectorprobe`
then checks the full exact **7 -> 4** app diagnostic multisets; neither probe
claims full trait topology, general Objective-C interop, or app launch.

## Reminder responder-root and Objective-C selector slice (2026-08-30)

Starting from exact framework base
`09130c91084627d6bda68a2a757cc729b17e9c8b`, the unchanged Reminder revision
`2edfc88c386b8dec1683339f58e05054c5e9ce1f` now advances from **4 -> 2**
whole-source diagnostics. Exactly the `#selector(DatePickerViewController.dateChanged(_:))`
and `@objc func dateChanged(_ sender: UIDatePicker)` errors disappear; no
diagnostic is added. `#Preview` and the Foundation/OpenUIKit `Notification`
ambiguity remain byte-for-byte. The app stays unedited and does not yet build
or launch. `Tools/reminderobjcselectorprobe` pins its tree, all 22 sources,
source SHA-256 `3a29a577f6290d27c09206798ab6446335eeb18a06502bfaa4d2f835850858d4`,
26 direct call-site lines, complete diagnostic multisets, a 26-path candidate
boundary, fresh no-hardlink clones, and ten tamper negatives.

`UIResponder` now inherits `NSObject`: Foundation supplies it on ordinary
native builds (including native ELF), while the Foundation-hidden
Linux-hosted Mach-O Apple target imports the staged ObjectiveC root directly.
The inherited chain makes `UIView`, `UIControl`, and `UIDatePicker`
Objective-C-representable wherever Objective-C interop exists, while preserving
NSObject identity `Equatable`/`Hashable` behavior on native ELF. Redundant
`UIView` and `UIScene` conformances were removed rather than competing with
NSObject. The responder-root exposure uncovered one real archive override:
`UIVisualEffectView.replacementObject(for:)` now overrides NSObject's hook and
retains the existing base-snapshot surrogate contract.

After framework semantic built-ins, `SelectorDispatch` now asks an
Objective-C-capable NSObject target whether it responds and performs exact
zero-, one-, or two-argument delivery. The portable `SelectorDispatching`
registry remains the fallback and the only native-ELF route. Runtime metadata
wins when a target supplies both. Targets remain weak. A live unresolved
explicit selector is still reported nonfatally through `onUnresolved`, unlike
UIKit's measured exception; OpenUIKit prunes dead weak targets, while broader
UIKit nil-target responder routing is not claimed. This slice does not move
`UIGestureRecognizer` or `UIEvent` under NSObject, and OpenUIKit Notification
and Timer selector delivery remains registry-only. Notification identity and
selector delivery are intentionally isolated to the next slice.

The native iOS 26.1 oracle pins responder NSObject topology, selector names,
0/1/2 delivery, exact sender identity, order, and weak lifetime. The separate
Foundation-hidden ARM64 Mach-O gate freshly compiles all 12 OpenCoreGraphics
and 102 OpenUIKit sources plus a literal `import UIKit` guest with Swift 6.2.4
on Linux, rejects a Foundation umbrella load, and runs the guest twice through
`machorun`. It covers typed UIDatePicker delivery, runtime precedence,
registry fallback, `endEditing:`'s measured `false`, and dead weak targets.

## Reminder Notification identity and bridge slice (2026-08-30)

Starting from exact framework base
`b8531df000f35a4580a9f239bb0348d04552053f`, this successor removes only
unchanged Reminder's Foundation/OpenUIKit `Notification` ambiguity. Its exact
whole-source diagnostic multiset advances **2 -> 1** with zero additions and
zero app/vendor edits; the byte-for-byte remaining diagnostic is `#Preview`.
`Tools/remindernotificationprobe` pins the Reminder commit/tree, all 22 source
files, source hash, 26 direct call sites, complete multisets, the exact
32-path candidate boundary, fresh no-hardlink clones, and ten tamper
negatives. This still is not an unchanged app build or launch.

The public identity follows target capability:

- With Foundation and Objective-C visible, `Notification`, `NSNotification`,
  `NotificationCenter`, and `OperationQueue` are aliases of Foundation's
  declarations. Literal `import Foundation` plus `import UIKit` therefore has
  one unqualified center/value family. OpenUIKit lifecycle posts and app
  observers meet on Foundation's real default center, including its queue,
  threading, ownership, and reentrant-removal behavior.
- Native ELF shares Foundation's notification value, Objective-C carrier, and
  queue identities, but keeps OpenUIKit's custom center. Corelibs Foundation
  has no selector-observer API because Swift Objective-C interop is disabled;
  a file that imports both modules qualifies `UIKit.NotificationCenter`, and
  portable selectors use `Selector.named` plus the registry. Its custom token
  subclasses Foundation.NSObject and therefore still assigns to
  `any Foundation.NSObjectProtocol`. The custom and corelibs Foundation
  centers are distinct and do not cross-deliver registrations or posts.
- A Foundation-hidden Objective-C guest keeps OpenUIKit's value, queue, and
  center. Its block token is an ObjectiveC.NSObject and assigns to
  `any NSObjectProtocol`. The value has a public
  `_ObjectiveCBridgeable` conformance backed by
  an NSObject carrier also exposed as the bounded `NSNotification` surface
  (`Name`, `name`, `object`, `userInfo`, and labeled initializer). The custom
  center supports measured zero-argument observers and prebridges once per
  post so all one-argument runtime thunks are invoked from one carrier:
  NSNotification handlers observe shared identity, while Notification
  handlers receive unbridged values. Runtime metadata wins before the
  registry.
  The guest's app-facing Foundation module must alias these exact OpenUIKit
  identities. This candidate proves that companion shape but does not edit the
  separately owned support checkout; landing the support alias is a required
  end-to-end follow-up.

Only the custom center promises registration-order snapshot delivery and
inline block delivery with an ignored queue. The native alias deliberately
inherits Foundation: the iOS 26.1 oracle shows that removing a later observer
during a post suppresses it in that same post. The bounded hidden
`NSNotification` is not a Foundation class cluster and does not claim
NSCopying, NSCoding, KVC, `NSNotificationQueue`, or preservation of an
original preboxed carrier through a value round trip. Timer remains the
host-clock implementation and its selector form remains registry-only.

## Visual-effect source compatibility slice (2026-08-29)

The 20-app ladder corpus uses `UIVisualEffectView` in 17 repositories and
`UIBlurEffect` in 16; four repositories also use `UIVibrancyEffect`. This
slice makes the unchanged Swift source for the foundational iOS 8/13 effect
family compile against real public types rather than app-side shims:
`UIVisualEffect`, all 20 public iOS `UIBlurEffect.Style` cases,
`UIVibrancyEffectStyle`, both vibrancy factory spellings represented by the
iOS 26.1 symbol graph, and the open effect-view API. It also narrows
`UIBarAppearance.backgroundEffect` from the previous `AnyObject?` placeholder
to UIKit's `UIBlurEffect?` property. Runtime probes override the header's
misleading `copy` annotation: UIKit retains exact identity and sends zero copy
messages on assignment and appearance-copy initialization, so OpenUIKit uses
strong storage and documents the resulting `@NSCopying` metadata divergence.

Runtime coverage is intentionally useful before pixels land. Apps can create,
subclass, mutate, and inspect effects and effect views; immutable built-in
effect objects copy by identity, compare/hash with measured UIKit semantics,
and securely archive with their configuration on Darwin and Linux. Their
NSObject equality/hash surface remains nonisolated for strict Swift 6.
`contentView` is stable once accessed and reproduces UIKit's nil/base/blur lazy
materialization, vibrancy's eager materialization, the measured access-order
geometry matrix, and immediate bounds-origin realignment only when an assigned
effect changes under NSObject equality. Fresh/default-reset base, toolbar, and
tab appearances share UIKit's internal chrome-effect identity, while ordinary
blur factories remain distinct. Apps
must add children through `contentView`; direct effect-view insertion is a
native `NSInternalInconsistencyException` and a documented portable fatal
invariant failure on Linux. Unknown effect subclasses remain valid but
inert. On Darwin, a base effect view also supports the deliberately narrow
geometry/effect snapshot documented in
`KNOWN_GAPS.md`; it is not a subclass or content-hierarchy archive. The
renderer-facing descriptor is internal and backend neutral so a later
view-render integration slice can route it into the existing deterministic
software/Quartz Canvas backdrop-filter primitive without changing app source
or making the public effects mutable. No corpus source was edited for this
slice.

This does not close the material-rendering row: app and framework effect
views remain visually transparent, and existing framework platters retain
their measured flat fallbacks. Public raw construction preserves measured
unnamed blur tags 3 and 21, while arbitrary extensible-enum integers remain a
documented pure-Swift limitation. Archive portability, private-hierarchy
differences, bar declaration metadata, and Foundation-hidden behavior are
recorded in docs/KNOWN_GAPS.md under “Visual-effect object and view semantics.”

## Focus text-input compatibility slice (2026-08-29)

The unchanged Focus sources exercise a compact but connected UIKit cluster:
keyboard traits on fields and text views, attributed placeholders, clear and
custom side views, assistant-bar group clearing, `selectAll(_:)`, overridable
text-field rect hooks, `textDidChangeNotification`, and subtree-wide
`endEditing(_:)`. OpenUIKit now exports and implements that cluster as one
behaviorally coherent slice rather than as compile-only properties.

Ground truth came from the local iOS 26.1 SDK plus a Simulator oracle. The
oracle pinned all enum values/defaults; placeholder coupling; the 19.667x19 pt
clear-button geometry in a 200x34 rounded field; side-view/text rectangles;
and right-view precedence over the clear control (including assignment order).
With an always-visible 12x22 right view, the oracle reported right-view
`[188,6,12,22]`, clear-button-hook `[176,8,19,19]`, and text/editing
`[7,2,181,30]`, with no clear control in the hierarchy. It also pinned
the hook's mode-dependent no-right-view geometry: inactive `.never` and
`.whileEditing` use `[176,8,19,19]`, while active modes use
`[175,8,19.667,19]` even when text is empty. Other probes pinned
inactive side-view detachment with geometry preservation; attached-vs-detached
`selectAll`; assistant identity/defaults; and every `endEditing` branch (no
responder, outside subtree, permissive delegate, refusing delegate, force
false/true). Group ownership follows the SDK's explicit single-group contract.
Focus's text-field subclasses compile
against genuinely open placeholder/text/editing/right-view hooks; no app
source, overlay, or conditional import is involved. Presentation boundaries
for the host keyboard, assistant bar, generated placeholder metadata, and the
SF Symbol clear glyph are enumerated in docs/KNOWN_GAPS.md rather than hidden
behind inert API.

## Focus Pro Tips page controller (2026-08-29)

The unchanged Focus source at revision
`a2832521c1daa0c23419c73705ae043ed60c9791` contains a conventional
`TipsPageViewController`: it constructs a horizontal scroll-style
`UIPageViewController`, installs itself as delegate/data source, sets an
initial controller with `animated: true`, and finds the direct child
`UIPageControl` to apply the app's tint. This slice adds that public surface
and real runtime behavior to OpenUIKit; no Focus source, project, dependency,
or generated input is patched.

The compatibility work is deliberately measured beyond “the names compile.”
An iOS 26.1 oracle pins enum and option-key raw values, lazy defaults, direct
hierarchy shape, page-indicator eligibility, inter-page spacing, appearance
and containment callback order, synchronous versus host-clock completion,
interruption, and page-indicator query timing. Gesture-driven neighbor/delegate
flow and reversal cancellation are portable-runtime tested; the UIKit oracle
does not synthesize an interactive gesture. The saturated Focus census is run
from a fresh clone of this OpenUIKit revision and brackets every Focus Swift
input with before/after SHA-256 manifests. On the page slice's isolated base,
the broad saturated census moved from **457 to 440 primary diagnostics**: all
**17** diagnostics in `TipsPageViewController.swift` (including the
type/protocol errors and their enum/color cascades) disappeared. This final
integrated revision also contains the independently accepted text-input slice
and totals **400** diagnostics. Its log contains zero `UIPageViewController`
or `TipsPageViewController` occurrences. Both manifests report source-subject
SHA-256 `96e2b5eda3ba03f7c5963b06500ceb05d59777f37c4e61006be37ce0424398bd`.

Rendering and reentrant-transition limits are listed in
`docs/KNOWN_GAPS.md` under “UIPageViewController”; in particular, page curl
is a flat programmatic swap and OpenUIKit deliberately cleans up an
animated-on-animated reentry that iOS 26.1 itself leaves wedged.

## Baseline measurement (2026-08-25, before M12)

Corpus: three large production apps, all code-based or mostly code-based —
Artsy **eidolon** (159 Swift files), **DuckDuckGo iOS** (1,197), Kickstarter
**ios-oss** (2,053). 10,162 UIKit symbol references total.

Real UIKit's surface, for reference: **737 types** (530 ObjC classes + 208
protocols, counted from the SDK headers). OpenUIKit exported 44 of *those*
names — **6% by raw type count**. (That 44 counts only names that also exist
in the SDK header list; the 63 quoted later in this file is the count of all
public `UI`/`NS`/`CA`-prefixed types OpenUIKit declares, which includes
internal-facing ones UIKit has no equivalent for. Two different questions, two
different methods — the later one is used consistently from here on.) The raw
type count is misleading either way, and here is the number that matters:

| | uses | share |
|---|---|---|
| **We implement it** | 7,133 | **70.2%** |
| Foundation provides free on Linux (`NSObject`, `NSString`, `NSCoder`, `NSValue`) | 400 | 3.9% |
| Out of scope (`UIStoryboard`, `UIStoryboardSegue`, `UIWebView`) | 95 | 0.9% |
| **Actual work remaining** | **2,534** | **24.9%** |

**Effective coverage: 74.8%** of what real apps touch, excluding storyboards
(a deliberate non-goal — code-based UI is the target) and counting Foundation
types that already exist off Darwin.

A small vocabulary does most of the work: apps reference ~171 distinct UIKit
types, not 737. That is why the punch list is tractable.

## Objective-C apps: a working facade (prototype)

The census counts Swift call sites, but the goal is "run real UIKit apps", and
some of them are Objective-C. A prototype facade — real ObjC `@interface`s over
a `@_cdecl` C ABI, no `@objc` anywhere — puts `UIView`, `UILabel`, `UIButton`
and `UIViewController` in reach of an Objective-C app on **Linux**, with ObjC
subclasses overriding `layoutSubviews`/`drawRect:` and dispatching
`@selector` target-action through the ObjC runtime. Its render is
byte-identical to the Swift equivalent's. Extrapolated cost of the full
facade, from this file's ranked type list: ~750 C entry points for the top 20
types (71% of all uses), ~2,200 for everything OpenUIKit exports — which is
why the recommendation is to generate it. Full report: **docs/OBJC_FACADE.md**.

## Selector target-action: shipped (M12)

The census counted **~360 `#selector` uses** across the corpus and the earlier
verdict was that none of them were addressable on native ELF. The portable API
changed that at M12; the 2026-08-30 responder-root slice then added real
runtime dispatch on Objective-C-capable targets:
`UIControl.addTarget(_:action:for:)`, `removeTarget(_:action:for:)`,
`UIGestureRecognizer.init(target:action:)` and `addTarget(_:action:)` now
exist and work on **both** macOS and Linux. Native ELF uses the registry;
Objective-C-capable NSObject targets use metadata first. Full design,
measurements and limits: docs/OBJC_RUNTIME.md.

Precisely how much of the ~360 that covers:

| where the selector goes | corpus share (approx.) | status |
|---|---|---|
| `UIControl.addTarget(_:action:for:)` | the large majority | **registry on native ELF; unchanged runtime dispatch for responder targets/senders on ObjC-capable builds** |
| `UIGestureRecognizer(target:action:)` / `addTarget(_:action:)` | second largest | **dispatch works; the recognizer sender itself is still not ObjC-representable** |
| `UIBarButtonItem(…target:action:)` | — | implemented through central dispatch; its non-responder sender still bounds typed ObjC actions |
| `NotificationCenter.addObserver(_:selector:name:)` | — | **native Foundation runtime on Foundation+Objective-C; central runtime-before-registry in the hidden guest; registry on native ELF** |
| `Timer.scheduledTimer(…selector:)` | — | implemented on the host clock but **registry-only** |
| `UIAppearance`, KVO | — | process-wide `UINavigationBar.appearance()` subset works; `UITableView` and scoped/containment appearance proxies plus KVO remain missing (portable design in docs/OBJC_RUNTIME.md) |

Two source-level costs remain, and they are substrate-dependent:

1. **Every native-ELF selector target writes a name -> method table**
   (`ActionTable` + a `SelectorDispatching` conformance). Objective-C-capable
   responder targets with exposed methods no longer pay this cost.
2. **On native ELF Linux `@objc` and `#selector` do not compile at all** (a Swift
   compiler/stdlib limitation, measured in docs/OBJC_RUNTIME.md). The
   portable spelling is `Selector.named("buttonTapped")`, which also compiles
   on Darwin — so one source can serve both platforms, at the cost of a
   mechanical `#selector(x)` → `Selector.named("x")` rewrite of those ~360
   sites and dropping `@objc`.

On Objective-C-capable builds, a responder controller action receiving a
responder control such as `UIButton`, `UISwitch`, or `UIDatePicker` is now
verbatim UIKit source. A sender outside the responder NSObject branch, such as
`UIGestureRecognizer` or `UIEvent`, must still be typed as `AnyObject` or use
the registry.

## Current measurement — after M12 (2026-08-25)

Re-run at the M12 tip with all four clusters merged
(`Tools/apicensus/census-latest.json`, reproduced from scratch at this commit;
the JSON and the tables below agree to the digit). The corpus also grew by one
app — **pocket-casts-ios** (1,690 Swift files) — so the headline is reported
both ways to keep the comparison honest.

**Like-for-like, same three apps, same 10,162 uses:**

| | before M12 | after M12 |
|---|---|---|
| distinct types implemented | 38 / 171 | **63 / 171** |
| frequency-weighted coverage | 70.2% | **85.4%** |

**+15.2 points** from the four clusters. Counting public `class`/`struct`/
`enum`/`protocol`/`typealias` declarations in `Sources/OpenUIKit` whose name
starts `UI`/`NS`/`CA`, OpenUIKit went from **63 to 111** exported UIKit-shaped
type names over the milestone.

**Four-app corpus (5,099 Swift files, 16,343 uses, 220 distinct UIKit types
referenced — 70 implemented, 150 missing), the number the command now prints:**

| | uses | share |
|---|---|---|
| **We implement it** | 13,572 | **83.0%** |
| Foundation provides free on Linux (`NSObject` 175, `NSString` 137, `NSCoder` 379, `NSValue` 13) | 704 | 4.3% |
| Out of scope (`UINib` 126, `UIStoryboard` 61, `UIStoryboardSegue` 22, `UIWebView` 2) | 211 | 1.3% |
| **Actual work remaining** | **1,856** | **11.4%** |

**Effective coverage: 88.5%.**

Reproduce with `Tools/apicensus/run.sh <dir-of-app-checkouts>`, which
regenerates **both** inputs from source rather than trusting a stale list —
the 737 SDK type names come from the Mac Catalyst UIKit headers, the 111
"ours" names from `Sources/OpenUIKit` — and rewrites
`Tools/apicensus/census-latest.json`. Verified 2026-08-25 to reproduce the
committed JSON byte-for-byte at this commit. The corpus is not vendored; clone
`artsy/eidolon`, `duckduckgo/iOS`, `kickstarter/ios-oss` and
`Automattic/pocket-casts-ios` into one directory.

## What M12 shipped

Four clusters, all merged on master, all oracle-backed. 15 new fixture scenes
(81 → **96**), 150 rendered frames.

"uses closed" is measured on the four-app corpus: the total references to
types that moved from `missing` to `implemented` between `d3ab657` and HEAD.
Together they account for **2,139 of the four-app corpus's 16,343 uses**
(+13.1 points), and for the whole of the 70.2 → 85.4 move on the shared
three-app corpus.

| cluster | uses closed | biggest types | fixtures |
|---|---|---|---|
| App lifecycle / environment | 805 | `UIApplication` 500, `UIDevice` 95, `UIScreen` 90, `UIResponder` 73 | (no pixel surface; `openhost --app` boots through `UIApplicationMain`) |
| Attributed text | 713 | `NSAttributedString` 591, `NSMutableAttributedString` 72, `UIFontDescriptor` 22 | `attrtext_runs` / `_paragraph` / `_kern_baseline` / `_underline_strike` / `_dark` / `_fields` |
| Alerts + custom transitions | 514 | `UIAlertController` 219, `UIAlertAction` 194, `UIPresentationController` 34 | `alert_basic` / `_destructive` / `_actionsheet` / `_dark` |
| Image / drawing / controls | 107 | `UIActivityIndicatorView` 74, `UIGraphicsImageRenderer` 16 | `control_activity` / `_slider` / `_segmented` / `_pagecontrol` / `_dark` |

(The four clusters were *chosen* on the three-app punch list, where they were
worth 560 / 543 / 396 / 106 uses. The table above is what they turned out to
be worth once pocket-casts-ios joined the corpus.)

Details per cluster are in docs/ROADMAP.md (M12) and the scope/divergence
notes in docs/KNOWN_GAPS.md. Three divergences are worth surfacing here
because they change what an app sees:

- **`UIVisualEffectView` exists, but nothing blurs yet.** Alert cards, button pills,
  the sheet grabber, the tab-bar platter and the `UIPageControl` background
  are measured FLAT equivalents fitted over neutral bases. Correct on a flat
  backdrop (residual < 1.5 counts), wrong in hue over a saturated one.
- **`NSAttributedString` and friends SHADOW Foundation's types.** They were
  introduced while OpenUIKit imported no Foundation. M15 retired that blanket
  rule, but the distinct type remains because corelibs Foundation measurably
  traps on repeated plain-Swift UIKit attribute values. An app that imports
  both still needs a file-scope `typealias`, and a Foundation attributed string
  cannot be handed to a `UILabel`.
- ~~**No notifications.**~~ **CLOSED by the controls2 cluster** (see the next
  section): OpenUIKit declares a portable `NotificationCenter` and posts the
  app-lifecycle notifications. The keyboard names are declared but nothing
  posts them — there is no system keyboard.

Also landed and cheap, outside the four clusters: `UIImage(named:/
contentsOfFile:/data:)` with PNG+JPEG decode via the `stb_image` copy already
inside CQuartz (`patches/quartz/005-image-io-memory.patch` — OpenUIKit
contains no decoding code of its own), `UIBezierPath`, and app-side drawing
(`UIView.draw(_:)`, `UIGraphicsImageRenderer`, `UIGraphicsGetCurrentContext()`,
`UIColor.setFill()/setStroke()`).

## Current measurement — after M13 (2026-08-25, all four clusters merged)

Four clusters shipped in M13 and are merged here: **collection view**,
**bars & appearance**, **menus & actions + delegate protocols**, and
**controls2**. Merged gates: `swift build` clean, **108/108 fixture scenes**
(96 → 108), **9/9 scroll traces**, **711 tests** (544 → 711), 0 failures.
`Sources/OpenUIKit` now declares **170** public `UI`/`NS`/`CA` type names
(111 at the M12 tip).

**Caveat on this re-measurement, stated up front:** the corpus is still not
vendored in this environment, so `Tools/apicensus/run.sh` could not re-scan
the apps. What was re-run is the half that does not need them — the `--ours`
list was regenerated from `Sources/OpenUIKit` at this merge commit and the
committed per-type use counts in `Tools/apicensus/census-latest.json` were
reclassified against it. Those counts are a property of the corpus and did
not change, so this reproduces `census.py`'s arithmetic exactly; only the
per-app file counts and the `missing_members_of_implemented` list are stale.
`census-latest.json` is therefore left as M12 wrote it — rerun the full
script with the checkouts to refresh it.

**Four-app corpus (16,343 uses, 220 distinct UIKit types referenced —
112 implemented, 108 missing):**

| | uses | share | was (M12) |
|---|---|---|---|
| **We implement it** | 14,829 | **90.7%** | 83.0% |
| Foundation provides free on Linux (`NSCoder` 379, `NSObject` 175, `NSString` 137, `NSValue` 13) | 704 | 4.3% | 4.3% |
| Out of scope (`UINib` 126, `UIStoryboard` 61, `UIStoryboardSegue` 22, `UIWebView` 2) | 211 | 1.3% | 1.3% |
| **Actual work remaining** | **599** | **3.7%** | 11.4% |

**Effective coverage: 96.3%** (was 88.5%). M13's four clusters moved **42
types and 1,257 uses** from `missing` to `implemented`, led by
`UIBarButtonItem` (270), `UICollectionView` (222),
`UIActivityViewController` (84), `UIKeyCommand` (81),
`UICollectionViewCell` (78) and `UIAction` (69).

What was left at that commit, ranked by how many apps need it:
`UIVisualEffectView` (20, 3 apps) + `UIBlurEffect` (12, 3) — the blur
divergence this file has carried since M12 — `UIApplicationShortcutItem`
(18, 3), the haptics generators (`UIImpactFeedbackGenerator` 15,
`UISelectionFeedbackGenerator` 7, both 3 apps and both trivially stubbable),
`NSTextAttachment` (13, 3), `UIViewControllerTransitionCoordinator` (7, 3),
then the two-app entries led by `UIFontMetrics` (66 — Dynamic Type),
`UIPasteboard` (32), `UIImagePickerController` (17), `NSItemProvider` (16)
and `UIPointerInteraction` (12).

> **Superseded.** `UIFontMetrics` and the Dynamic Type cluster shipped in M14.
> The current numbers and the current punch list are the next section.

## Current measurement — M13 wrap-up, at the M14 tip (2026-08-25)

Re-measured at `HEAD` on `master` with M13's four clusters *and* M14 merged.
`Sources/OpenUIKit` now declares **180** public `UI`/`NS`/`CA` type names
(170 at the M13 merge, 111 at M12, 63 before it).

**Same caveat as the M13 re-measurement, and for the same reason:** the four
app checkouts are not vendored in this environment, so `census.py` could not
re-scan them. What was regenerated from source is the `--ours` half — every
public `UI`/`NS`/`CA` type in `Sources/OpenUIKit` at this commit — and the
committed per-type use counts in `Tools/apicensus/census-latest.json` were
reclassified against it. Those counts are a property of the corpus and did
not change, so this reproduces `census.py`'s arithmetic exactly; only the
per-app file counts and `missing_members_of_implemented` are stale, and
`census-latest.json` is left as M12 wrote it.

**Four-app corpus (16,343 uses, 220 distinct UIKit types referenced —
116 implemented, 104 missing):**

| | uses | share | M13 merge | M12 |
|---|---|---|---|---|
| **We implement it** | 14,954 | **91.5%** | 90.7% | 83.0% |
| Foundation provides free on Linux (`NSCoder` 379, `NSObject` 175, `NSString` 137, `NSValue` 13) | 704 | 4.3% | 4.3% | 4.3% |
| Out of scope (`UINib` 126, `UIStoryboard` 61, `UIStoryboardSegue` 22, `UIWebView` 2) | 211 | 1.3% | 1.3% | 1.3% |
| **Actual work remaining** | **474** | **2.9%** | 3.7% | 11.4% |

**Effective coverage: 97.1%** (96.3% at the M13 merge, 88.5% at M12).

The +0.8 is M14's Dynamic Type cluster: four newly exported types are
referenced by the corpus — `UIFontMetrics` (66 uses, 2 apps),
`UITraitPreferredContentSizeCategory` (55), `UITraitHorizontalSizeClass` (2)
and `UITraitUserInterfaceStyle` (2) — **125 uses closed**. Six more
(`UIContentSizeCategory`, `UIAccessibilityTraits`, `UITraitDefinition`,
`UITraitChangeRegistration`, `UITraitDisplayScale`,
`UITraitVerticalSizeClass`) the corpus does not name, so they score zero here
while still being what makes the other four usable.

## The punch list, re-ranked at the M14 tip

Clustered from the **96 genuinely-missing types (474 uses)** left after
Foundation and the out-of-scope four are removed. "apps" is the largest
number of corpus apps any type in the cluster appears in.

The ranking rule is the census's own — **apps first, then uses** — because a
cluster at 0.2% of uses can still be the reason an app does not launch. Both
orderings are given, since they disagree sharply at the top now.

| # | cluster | uses | apps | notes |
|---|---|---|---|---|
| 1 | **Materials / blur (glass)** | 37 | 3 | `UIVisualEffectView` 20, `UIBlurEffect` 12, `UIGlassEffect` 3, `UIVisualEffect` 1, `UIVibrancyEffect` 1. The oldest open divergence in the project and **the single largest source of remaining pixel error**: every platter in the framework — alert card, sheet grabber, tab-bar platter, bar-button capsules, `UIPageControl` background — is a flat colour fitted over a neutral base. Correct on a flat backdrop (residual < 1.5 counts), wrong in hue over a saturated one. The deterministic backdrop-filter primitive now exists; closing this row means routing effect descriptors and framework chrome through it, not adding more declarations. |
| 2 | **Home-screen shortcuts** | 31 | 3 | `UIApplicationShortcutItem` 18, `UIApplicationShortcutIcon` 8, `UIMutableApplicationShortcutItem` 5. Pure value types plus one `UIApplication` property; no pixels, no oracle needed. The cheapest three-app entry on the list. |
| 3 | **Haptics** | 30 | 3 | `UIImpactFeedbackGenerator` 15, `UINotificationFeedbackGenerator` 8, `UISelectionFeedbackGenerator` 7. No portable hardware to drive, so the honest shape is a no-op that records calls (and is therefore testable). Compile-blocker removal, nothing more. |
| 4 | **TextKit attachments** | 17 | 3 | `NSTextAttachment` 13, plus one-off `NSTextContainer` / `NSLayoutManager` / `NSTextStorage`. The first one is real work — an inline image box the data-driven text engine must lay out and the run painter must draw. The other three are TextKit-1 plumbing we deliberately do not have. |
| 5 | **Transition coordinator + interactive transitions** | 13 | 3 | `UIViewControllerTransitionCoordinator` 7, `UIPercentDrivenInteractiveTransition` 3, `UIViewControllerInteractiveTransitioning` 3. Sits directly on M12's presentation/transitioning API and M7.5's interactive back-swipe, both of which already exist; this is the public handle onto them. |

By **uses** instead, the two-app entries outrank items 2–5 and would reorder
the list: **drag & drop** (62 across 12 types — `UIDropSession` 11,
`UICollectionViewDropProposal` 11, `UIDragItem` 10, `UIDragSession` 8),
**pointer / hover** (33 across 4), `UIPasteboard` (32, a single type and no
system pasteboard to talk to off-device), **table extras** (31 — swipe
actions 17, diffable data sources 14), **system pickers** (25 —
`UIImagePickerController` 17, `UIDocumentPickerViewController` 4; system UI
we cannot reproduce, so a compiling stub that reports "unavailable"), and
`NSItemProvider` + activity items (18).

One-app clusters, in demand order: **cell content configuration** (26 —
`UIContentConfiguration` 18), `UIPageViewController` (22), **edit menu /
`UIMenuController`** (18), **compositional layout** (11 — the tail of the
shipped collection-view cluster), **search controller** (11 —
`UISearchController` 8, on top of the `UISearchBar` controls2 already
shipped), `UIPinchGestureRecognizer` (9), `UIViewPropertyAnimator` (7, 2
apps), `UISceneConfiguration` (5), `UIImageAsset` (5).

The unclustered tail is **24 types / 29 uses**, and every one of them appears
in exactly one app: five types at 2 references
(`UILocalizedIndexedCollation`, `UIPrintInteractionController`,
`UICollectionViewListCell`, `UIDropProposal`,
`UIDocumentInteractionControllerDelegate`) and nineteen at 1. At this point
the type census has very little left to say — which is itself the finding,
and the reason "Missing MEMBERS of types we already export" below and
docs/REAL_APP_TEST.md now matter more than anything in this table. The
largest single item anywhere in this document is not a type at all:
`UIView.setAnimationsEnabled` + `performWithoutAnimation`, **100 corpus
uses**, one global flag and one wrapper of work.

## What M13 shipped — collection view (2026-08-25)

The census's #1 cluster: **collection view** (498 uses across 23 types,
all four apps). `UICollectionView`, `UICollectionViewCell`,
`UICollectionReusableView`, `UICollectionViewLayout` +
`UICollectionViewFlowLayout`, `UICollectionViewLayoutAttributes` and the
`UICollectionViewDataSource` / `UICollectionViewDelegate` /
`UICollectionViewDelegateFlowLayout` trio — the last of which also clears
three of the "delegate protocols" cluster's 51 collection-view uses.

5 new fixture scenes: `collection_flow_grid`,
`collection_flow_lines`, `collection_sections`, `collection_horizontal`,
`collection_dark`. The flow layout's geometry was PROBED rather than guessed
(`scripts/flow_probe.sh`, 20 configurations against real UIKit) because two
of its rules are not derivable from the documentation — see docs/ROADMAP.md
(M13) and docs/KNOWN_GAPS.md.

The prerequisite the punch list called out was done first: the reuse
machinery moved out of `UITableView` into `Sources/OpenUIKit/UIReuse.swift`
and both containers now drive one implementation, with every `tableview_*`
fixture and table test unchanged as the regression bar.

Registered cell and supplementary-view subclasses use UIKit's ordinary
`override init(frame:)` spelling. OpenUIKit keeps that public initializer
non-required and routes its internal class-metatype construction through a
separate SPI sibling's initializer-vtable slot. Application subclasses never
inherit the bridge, while registered overrides and inherited leaf classes are
still constructed dynamically in FoundationEssentials-only Mach-O guests.

Still open inside the cluster: `UICollectionViewCompositionalLayout`,
`NSCollectionLayoutSection` and `UICollectionViewDiffableDataSource`, plus
animated batch updates.

## What M13 shipped — menus & actions + delegate protocols (2026-08-25)

Clusters **#3 (menus & actions)** and most of **#4 (delegate protocols)**,
plus the share-sheet stub from **#5**.
The census is NOT re-run here (it needs the corpus checkouts), so the tables
above still show these as missing; what is measurable without the corpus is
the list of census symbols that move from `missing` to `implemented`, and
their `uses` column adds to **439** of the four-app corpus's 16,343:

| symbol | uses | symbol | uses |
|---|---|---|---|
| `UIActivityViewController` | 84 | `UIMenuElement` | 11 |
| `UIKeyCommand` | 81 | `UIPopoverPresentationControllerDelegate` | 10 |
| `UIAction` | 69 | `UIAdaptivePresentationControllerDelegate` | 9 |
| `UIMenu` | 49 | `UISearchBar` | 9 |
| `UIContextMenuConfiguration` | 23 | `UIActivityItemSource` | 9 |
| `UITextFieldDelegate` | 20 | `UITargetedPreview` | 6 |
| `UITextViewDelegate` | 15 | `UIPopoverPresentationController` | 6 |
| `UIGestureRecognizerDelegate` | 14 | `UISearchBarDelegate` | 3 |
| `UISheetPresentationControllerDelegate` | 14 | `UIContextMenuInteraction` (+delegate, +2 animating) | 6 |

Also added, outside the census's type list: `UICommand`,
`UIDeferredMenuElement`, `UIInteraction`, `UIControl.addAction(_:for:)`,
`UIButton(primaryAction:)` / `.menu` / `.showsMenuAsPrimaryAction` /
`performPrimaryAction()`, `UIResponder.keyCommands`,
`UIWindow.performKeyCommand(input:modifierFlags:)`, `UIActivity`,
`UIPopoverArrowDirection`, `UIModalPresentationStyle.popover`, and the
remaining `UIScrollViewDelegate` members (including a HONOURED
`scrollViewWillEndDragging` retarget).

Oracle status, stated plainly: the menu's geometry and colours are measured
by a new probe (`Tools/oracle2/menuprobe` + `scripts/menu_probe_sim.sh`,
17 configurations on real iOS 26.1), but **there is no fixture scene** —
iOS 26 draws the menu platter in the render server, where neither oracle can
capture it. The measurements are locked in by
`Tests/OpenUIKitTests/MenuTests.swift` instead, whose every expected number
comes from the probe. Full argument and the divergence list:
docs/KNOWN_GAPS.md "Menus, actions & delegate protocols".

Still missing from cluster #4 after this: the `UICollectionView` delegate /
data-source trio (owned by the collection-view cluster).

## What the "controls2" cluster shipped (2026-08-25, after M12)

The remaining controls plus the compile-blockers that are not types. **The
census was NOT re-run** (the corpus is not vendored and no checkout was
available in this environment), so no new coverage percentage is claimed
here; what follows is the list of punch-list entries this cluster closes,
with their four-app use counts from the table below.

| shipped | punch-list line it closes | uses |
|---|---|---|
| `NotificationCenter` + `Notification` + `Notification.Name` + `OperationQueue`, with the five app-lifecycle notifications actually POSTED | "the notification-name group", the largest genuinely-missing member group | ~90 |
| `UILayoutGuide` in the cassowary solver, `UIView.safeAreaInsets` / `safeAreaLayoutGuide` / `layoutMarginsGuide` / `readableContentGuide` / `layoutMargins` / `preservesSuperviewLayoutMargins`, `UIViewController.additionalSafeAreaInsets`, `safeAreaInsetsDidChange` | `safeAreaLayoutGuide`, the doc's own named example of "a missing MEMBER of a type we DO export" | in "virtually every modern constraint set" |
| `Timer` + `RunLoop` on the host clock (both the closure and the selector forms) | the `Timer.scheduledTimer(…selector:)` row of the selector table above — "not implemented" | — |
| `UIRefreshControl` with pull-to-refresh | tail entry | 12 |
| `UIStepper` | tail entry (metrics were already probed) | 22 |
| `UISearchBar` (+ `UISearchTextField`, `UISearchBarDelegate`) | the "search" tail cluster | 23 |
| `UIPickerView` (+ its data-source / delegate protocols) | tail entry | — |

Two new fixtures: `constraints_safearea` (100.0 %) and
`control_refresh` (99.4 %). Three of the four controls could NOT be goldened,
and the reasons are properties of the oracle rather than shortcuts — a
private material that `layer.render(in:)` draws as nothing (`UISearchBar`), a
SwiftUI hosting view that renders nothing at all (`UIStepper`), and a
`CAGradientLayer` that turns the whole capture into a translucent wash
(`UIPickerView`). Each is replaced by unit tests that replay real UIKit's own
numbers, and each is written up in docs/KNOWN_GAPS.md with the probe route
that would close it (the windowed oracle, which needs an active display
session, or a Simulator drag).

`UIDatePicker` was deferred in this historical controls2 pass. The bounded
Reminder implementation described at the top of this file now builds on that
measured picker wheel; the historical deferral is no longer current status.

At this historical controls2 boundary `NotificationCenter`, `Notification`,
and `Timer` shadowed Foundation. The Notification identity/bridge successor at
the top of this file supersedes the first two on Foundation+Objective-C and
the value on native ELF; Timer remains a distinct host-clock type.

## The punch list as it stood at M12 — HISTORICAL

> **Superseded** by "The punch list, re-ranked at the M14 tip" above. Kept
> because it is the ranking M13's four clusters were *chosen* from, and the
> strike-throughs are the record of what closing them cost.

Clustered from the 150 missing types (1,856 uses). "apps" is the largest
number of corpus apps any type in the cluster appears in — a 4 means every app
needs it.

| # | cluster | uses | apps | notes |
|---|---|---|---|---|
| 1 | ~~**Collection view**~~ **SHIPPED (M13)** | 498 | 4 | `UICollectionView` 222, `UICollectionViewCell` 78, `UICollectionViewLayout` 41, `UICollectionViewFlowLayout` 30, data source/delegate 51 — all of that now exists. The reuse machinery was lifted out of `UITableView` into `Sources/OpenUIKit/UIReuse.swift` first, and both containers drive it. Still open in the TAIL of this cluster: `UICollectionViewCompositionalLayout`, `NSCollectionLayoutSection` and `UICollectionViewDiffableDataSource`, plus animated batch updates (docs/KNOWN_GAPS.md "UICollectionView"). |
| 2 | ~~**Bars & appearance** (6 types)~~ **SHIPPED (M13)** | ~~322~~ | 4 | `UIBarButtonItem`, `UINavigationItem`, `UIToolbar`, `UIBarAppearance` + the navigation-bar / toolbar / tab-bar subclasses, and `UIBarMetrics`. Navigation-title attributes use UIKit's dictionary source shape. See "What M13 shipped" below. |
| 3 | ~~**Menus & actions** (9 types)~~ **SHIPPED (M13)** | ~~252~~ | 2 | `UIKeyCommand` 81, `UIAction` 69, `UIMenu` 49, `UIContextMenuConfiguration` 23. Concentrated in two apps but dense there, and `UIAction` is how modern code-based UI wires buttons at all. |
| 4 | ~~**Delegate protocols** (14 types)~~ **SHIPPED (M13)** | ~~144~~ | 4 | `UITextFieldDelegate` 20, `UITextViewDelegate` 15, `UIGestureRecognizerDelegate` 14, the collection-view trio 51, the presentation-controller delegates 23. Mostly *declarations that do not exist yet* — an app fails to compile on the conformance before any behaviour is missing. Cheapest points on the list. |
| 5 | **Share / system UI** (5 types) | 130 | 3 | `UIActivityViewController` 84 **SHIPPED (M13, as a stub)**; `UIImagePickerController` 17 and `NSItemProvider` 16 still open. System UI we cannot reproduce; the honest shape is a compiling stub that reports "unavailable". |

Below the top five, in demand order: **Dynamic Type** — `UIFontMetrics` (66)
plus `UITraitPreferredContentSizeCategory` (55, sitting in the unclustered
tail because it appears in only one app) plus the `UIFont.preferredFont`
member (21), together ~142 uses and arguably top-3 if counted as one cluster
— then **drag & drop** (65), **materials/blur** (34 — the fix for the
divergence above), **pointer/hover** (33), `UIPasteboard` (32), **haptics**
(30, trivially stubbable), **home-screen shortcuts** (26), **search** (23),
`UIPageViewController` (22), `UIStepper` (22 — metrics already probed,
docs/KNOWN_GAPS.md), **table extras** (swipe actions/diffable, 21), **TextKit
attachments** (17), **transition coordinator** (13), `UIRefreshControl` (12).
The unclustered tail is 47 types / 199 uses. **`UIStepper` (22), the
"search" cluster (23), `UIRefreshControl` (12) and `UIPickerView` are now
IMPLEMENTED** — see "What the controls2 cluster shipped" below.

## Missing MEMBERS of types we already export — re-checked at the M14 tip

This is a separate 2,930-use pool, and the member scanner is noisier than the
type scanner: the top entries are `UILabel.lens` (297), `UIButton.lens` (217)
and `UIFont.ksr_*` — Kickstarter's own lens library and font extensions, not
UIKit at all. Filtering app-local extensions left ~477 uses of genuinely
missing members at M12. Each was re-checked against `Sources/OpenUIKit` at
this commit:

| member | uses | status at HEAD |
|---|---|---|
| `UIView.setAnimationsEnabled` | 92 | **still missing** — now the largest single gap in the pool, and a cheap one: a global flag the animation engine consults when opening a transaction |
| the notification-name group | ~90 | **closed** (controls2) — `NotificationCenter`, `Notification.Name` and the five posted app-lifecycle names |
| `systemLayoutSizeFitting` + `UIView.layoutFittingCompressedSize` | 24 | **closed** (M14, `UIViewCompat.swift` / `UIStackView.swift`) |
| `UIFont.preferredFont` | 21 | **closed** (M14, `UIFontMetrics.swift`) |
| `UIAppearance` proxies (`UINavigationBar.appearance` 11, `UITableView.appearance` 6) | 17 | **partial** — the process-wide `UINavigationBar.appearance()` subset is shipped; `UITableView.appearance()` and trait-/containment-scoped proxies remain missing |
| `UIView.addKeyframe` | 12 | **still missing** — keyframe animations |
| `UIView.performWithoutAnimation` | 8 | **still missing** — falls out of `setAnimationsEnabled` |
| `UIFont.monospacedDigitSystemFont` | 8 | **still missing** — needs the monospaced-digit metrics harvested |

So the member pool went from ~477 to ~**340** genuinely-missing uses, and
**`setAnimationsEnabled` + `performWithoutAnimation` (100 uses) is the single
best-value item left anywhere in this document** — larger than any missing
*type* cluster, and one flag plus one wrapper of work.

## Method notes / caveats

- The census is regex-based over Swift sources; it counts *type* references
  well and members roughly. It undercounts protocol conformances written
  indirectly and overcounts symbols in dead code.
- Type coverage ≠ API coverage. We may export `UIView` while missing members
  a given app needs (`safeAreaLayoutGuide` WAS the known example; the
  controls2 cluster implemented it). The
  `missing_members_of_implemented` section of the census JSON tracks this and
  should be reviewed per cluster as it is implemented.
- **The member census does not distinguish UIKit members from app-defined
  extensions on UIKit types** (new caveat, 2026-08-25). Over half of that
  pool's 2,930 uses are one app's `lens`/`ksr_*` extensions. Any ranking built
  on member counts must be filtered against our own sources first, as the
  paragraph above does; the type counts are unaffected.
- The corpus skews toward large, older apps (one still uses `UIWebView`).
  Adding a couple of modern code-based apps would sharpen the ranking.
- Coverage is weighted by *reference count*, which rewards ubiquitous types
  (`UIView`, `UIColor`) over pivotal-but-rare ones. A cluster at 1% of uses
  can still be the reason an app does not launch. Read the punch list with
  the "apps" column, not only the "uses" column.

## Definition of done for this phase — REACHED at the screen level (M14)

A real, code-based open-source app compiles against OpenUIKit and renders its
first screen — headless via `openrender`, live via `openhost`, and identically
on Linux. Everything implemented on the way keeps its oracle fixtures, so
"runs real apps" never trades away "matches real UIKit."

**Outcome (2026-08-25). Full write-up: docs/REAL_APP_TEST.md.**

A screen from **Automattic/pocket-casts-ios** — its options-picker sheet,
four files, 605 lines — was vendored into `Sources/RealAppProbe` and compiled
against OpenUIKit. It renders headlessly (`openrender realapp`, three
configurations), live (`openhost --app pocketcasts`, with the app's own touch
handling, switch action and tap-to-dismiss driven by real touches), and
**byte-identically on Linux** (`scripts/linux_realapp_verify.sh`: 13/13 frames
across the headless renders and the scripted live replay).

**14 of the 605 lines had to change — 97.7 % unmodified** *(4 and 99.3 % after
M15 closed the Foundation row, the `@MainActor` row and the harness row — see
"M15" below)*, and the 258-line view controller (all of the Auto Layout)
compiles byte-for-byte. The ledger as first measured, by reason:
`NSCoder`/Foundation collision 5, `@MainActor` isolation 4, `#selector`/`@objc`
4, harness access level 1 — every row except `#selector`/`@objc` is **0** after
M15, leaving 4. **None of the 14 was a missing UIKit member** — every one is a
language or runtime incompatibility.

The cost that does not show up in that ratio is the 246 lines of scaffolding
(the app's theme system re-expressed, a `SelectorDispatching` table, a `UIKit`
module alias) — see the report.

So the honest statement of where this stands:

- **rendering a real code-based screen: done**, for this class of screen;
- **compiling a whole app: not close**, and the reasons are now specific
  and ranked (docs/REAL_APP_TEST.md "Blocked on"): Foundation
  interoperability (`NSCoder` alone appears in 344 of the corpus's 5,099
  files), selector dispatch, ~~`@MainActor`~~ *(closed in M15)*, asset
  catalogs, xibs. Only the last is out of scope by choice.

The next milestone this suggests is **not** more UIKit types. It is
`import Foundation` alongside OpenUIKit, which would let an app's model layer,
theme system and string tables compile untouched.

## M15: Foundation coexistence — done (2026-08-25)

**`import Foundation` next to `import OpenUIKit` now compiles.** That was the
#1 item above and it is closed for the geometry types, `IndexPath`, `NSRange`
and `TimeInterval`, which is what unblocks `NSCoder` (344 files), `NSObject`
(175), `NSString` (137) and `NSValue` (13) — the 704 uses, **4.3 %** of the
corpus, that this table has been listing as "Foundation provides free on
Linux". They are free *now*; before M15 the file that wanted them could not
also mention a `CGRect`.

The insight was that the collision was never missing API — it was duplicate
NAMES — so the fix was subtraction. OpenUIKit stopped declaring rivals and
started re-exporting Foundation's own types (`typealias`, so lookup resolves
to one declaration), keeping UIKit's conveniences as extensions the way real
UIKit does. Design and the measured reasons: docs/PORTABILITY.md "M15: the
library imports Foundation, and there is exactly one `CGRect`".

**Evidence, not assertion:**

| | before | after |
|---|---|---|
| `private typealias X = OpenUIKit.X` lines in `Tests/` | 178 | **27** (151 deleted, across 40 files) |
| a test file that imports Foundation *and* uses UIKit geometry unqualified | impossible | `Tests/OpenUIKitTests/FoundationCoexistenceTests.swift` |
| oracle scenes / scroll traces / unit tests | 108 / 9 / 732 | 108 / 9 / **738** |
| Linux frames byte-identical to macOS | 162/162 | **162/162** |

**What did not move, and why** (each measured — details in
`Sources/OpenUIKit/FoundationTypes.swift`): `NSAttributedString`
(corelibs-Foundation *traps* when a plain Swift value is stored as an
attribute twice, and every UIKit attribute value is one), `NotificationCenter`
(the native-ELF selector form remains registry-only, and that is the spelling
apps use most), `Timer`/`RunLoop` (they run on the scripted host
clock; Foundation's run on `Date`, which would end byte-identical rendering),
and `CGAffineTransform` (Linux Foundation has none, so keeping ours costs
nothing there — it clashes only on Darwin).

That leaves the remaining four blockers from the real-app ledger: selector
dispatch, `@MainActor`, asset catalogs, xibs.

Earlier blockers in the punch-list ordering — items 4, 2 and 1 (delegate
protocols, `UIBarButtonItem`, `UICollectionView`) — are all closed as of M13.

## What M13 shipped — bars & appearance (2026-08-25)

The whole #2 cluster, oracle-backed. **8 new exported types** and **5 new fixture
scenes**:

| type | corpus uses | notes |
|---|---|---|
| `UIBarButtonItem` | 270 | all five UIKit initializers (`title:style:target:action:`, `barButtonSystemItem:target:action:`, `image:style:target:action:`, `customView:`, plain), `isEnabled`, `tintColor`, `width`, `style`. Target-action goes through the M12 selector machinery, and the sender UIKit hands the action is the ITEM. |
| `UINavigationBarAppearance` | 33 | plus `UIBarAppearance`, `UIToolbarAppearance`, `UITabBarAppearance`, and `UIBarMetrics`. `configureWith{Default,Opaque,Transparent}Background`, `backgroundColor`, `shadowColor`, dictionary-shaped `titleTextAttributes` / `largeTitleTextAttributes`; wired to `standardAppearance` / `scrollEdgeAppearance` / `compactAppearance` on the bar AND per-item on `UINavigationItem`. The 2026-08-29 Focus slice also added the metric-keyed legacy background-image API, legacy shadow/title properties, and `UIBarButtonItem.accessibilityIdentifier`. |
| `UIToolbar` | 12 | `items`, `setItems(_:animated:)`, `barTintColor`, `tintColor`, `isTranslucent`, appearance objects; plus `UINavigationController.toolbar` / `isToolbarHidden` / `setToolbarHidden(_:animated:)` driven by the top controller's `toolbarItems`. |
| `UINavigationItem` | — | `title`, `titleView`, `prompt`, `left`/`rightBarButtonItem(s)` (+ the animated setters), `backBarButtonItem`, `backButtonTitle`, `hidesBackButton`, `largeTitleDisplayMode`, per-item appearances. Reachable as `UIViewController.navigationItem`, created lazily and seeded from `title` exactly like UIKit — which is how every real app configures a bar. |

Fixtures (all routed to real iOS in the Simulator through the new `"ios": true`
scene key — Mac Catalyst is not ground truth for iOS 26's glass bars):
`navitem_buttons` (leading + trailing items, a system item, a disabled item),
`navitem_titleview` (custom title view over a transparent bar),
`navitem_dark` (dark mode, a template-image item, a per-item tint),
`navbar_appearance` (opaque background + shadow hairline + custom title text
attributes), `toolbar_basic` (flexible and fixed spaces, two bars).

Two divergences are worth surfacing here because they change what an app sees
(full detail in docs/KNOWN_GAPS.md "Bars & appearance"):

- **Bar buttons are glass platters, and ours are flat.** Correct over a flat
  neutral backdrop (over white the platter is invisible apart from its
  measured shadow), wrong in hue over a saturated one — the same
  `UIVisualEffectView` gap the alert card and tab-bar platter already carry.
- **No SF Symbols.** Measured, only `.edit` and `.save` render as text on
  iOS 26 and are exact; `.done` is the prominent (tint-filled) checkmark and
  every other system item is a hand-fitted vector of the measured size. No
  golden gates those vectors.

One guessed constant was replaced by measurement: the inline navigation bar's
zone split was 20 + 44 with the title centred at y 42; real iOS 26 is 10 + 54
with the centre at **32**. `barHeight` stays 64, so nothing below the bar
moved.

## `@MainActor` isolation: shipped (M15, 2026-08-25)

Punch-list blocker **#3** in docs/REAL_APP_TEST.md, and the cheapest large win
on that list: `@MainActor` appears **641 times across 270** of the corpus's
5,099 Swift files, and the count only goes up as apps move toward the Swift 6
language mode, where main-actor isolation is the default expectation.

The problem was not that apps call something OpenUIKit lacks. It is that real
UIKit annotates its classes `@MainActor`, so an app can write

```swift
let action: @MainActor () -> Void        // and call it from a touch handler
@MainActor func reload() { tableView.reloadData() }
nonisolated func hashValue() -> Int
```

and have it type-check. Against classes with *no* isolation the same code is a
concurrency error — which is why 4 of the real-app harness's 14 changed lines
were annotations that had to be deleted rather than adapted.

**What is annotated now** mirrors the iOS SDK: `UIResponder` and every
subclass, `UIControl`, `UIGestureRecognizer`, `UIScreen`, `UIDevice`, the
touch/event types, the presentation and transitioning types, the bar-item and
bar-appearance types, the Auto Layout types, and **every delegate /
data-source protocol** (the SDK annotates those too, and it is forced anyway —
a `@MainActor` witness cannot satisfy a nonisolated requirement).

**What is deliberately left nonisolated** — because it is legal off the main
actor in real UIKit too, and because isolating it would constrain any future
threading of the renderer: all of `OpenCoreGraphics`, the glyph-run painter
(`UILabel.drawGlyphLine`/`drawGlyph`, spelled `nonisolated static`), the
Cassowary solver, the font engine, `UIColor`/`UIImage`/`UIFont`/
`UIBezierPath`/`UIGraphicsImageRenderer`, and the Foundation shapes
(`NSAttributedString`, `Timer`, and the custom NotificationCenter branches).

Three boundary families are crossed on purpose with `MainActor.assumeIsolated`
(a *checked* assertion that traps off-main) and never `nonisolated(unsafe)`:
Timer delivery plus **custom-center** notification delivery to a
`SelectorDispatching` target, the top-level code in each tool's `main.swift`,
and the `oukMain` wrapper around Objective-C C-ABI entry points. Full reasoning, the
strict-concurrency numbers and the measured zero perf cost are in
docs/KNOWN_GAPS.md "Actor isolation".

**Result for app source:** the harness's real-app ledger goes **14 changed
lines → 10**, 97.7 % → **98.3 %** unmodified, and the entire `@MainActor`
category disappears from it. *(Combined with the Foundation row and the
harness row, the M15 tip is 4 lines / 99.3 % — see the M15 punch list at the
end of this file.)* Renders are unchanged: 108/108 scenes, 9/9 scroll
traces, 737 tests (5 new, `ActorIsolationTests`), 162/162 byte-identical
macOS-vs-Linux frames, and 13/13 for
the real-app screen.

---

## The punch list, re-ranked at the M15 tip (2026-08-25)

> **Supersedes** "The punch list, re-ranked at the M14 tip" for the
> *app-compatibility* blockers. That section is still the current ranking for
> the **missing-type clusters** (blur, shortcuts, haptics, TextKit
> attachments, transition coordinator), which M15 did not touch. What changed
> is the list of things that stop an app's *source* from compiling at all.

Two entries **drop off entirely**, and this is the milestone's headline:

| dropped | was ranked | why it is gone |
|---|---|---|
| ~~**Foundation cannot be imported alongside OpenUIKit**~~ | **#1** — "the single biggest structural obstacle to compiling an app as a whole" | OpenUIKit's `CGRect`/`CGPoint`/`CGSize`/`CGFloat`, `IndexPath`, `NSRange` and `TimeInterval` are now `typealias`-es to Foundation's own types, so there is one declaration rather than two rivals. `import Foundation` next to `import UIKit` compiles; `NSCoder` (379 uses / 344 files), `NSObject` (175), `NSString` (137) resolve. |
| ~~**No `@MainActor` isolation**~~ | **#3** — 641 uses / 270 files | UIResponder and every subclass, UIControl, the gesture/touch/event types, the presentation types, the Auto Layout types and every delegate protocol are `@MainActor`, matching the iOS SDK. |

### What is actually left, ranked

Ranking rule: **can an app's source compile at all**, then corpus reach.

| # | blocker | corpus reach | status |
|---|---|---|---|
| 1 | **`@objc` / `#selector` on native ELF** | `#selector` 1,138 / 360 files; `@objc` 1,189 / 395 | The native-ELF Swift compiler still emits *"Objective-C interoperability is disabled"* before a library can help, so the cross-platform real-app harness retains its 4-line adaptation and registry table. Objective-C-capable responder controls dispatch unchanged 0/1/2-argument target/action; Notification observers now dispatch measured zero/one-argument methods through native Foundation or the hidden guest's central runtime. Recognizer/event senders and Timer remain bounded. Objective-C app source remains a separate libobjc2 facade path (docs/OBJC_FACADE.md). |
| 2 | **No asset catalog** | `UIImage(named:)` 438 / 161 | `.xcassets` is unread; only loose `@2x`/`@3x` files resolve, and the template-rendering-intent flag that app tinting depends on lives in the catalog. Self-contained project, no oracle needed. |
| 3 | **Localization** | `L10n.` 3,400 / 540 | Not UIKit, but unavoidable in a whole-app attempt: three of four corpus apps route every user-visible string through a generated enum over `NSLocalizedString`/`Bundle`. Now *more* tractable than at M14, because Foundation is importable. |
| 4 | **`UIWindow` runs no appearance transition** | `viewDidAppear` 119 / 105 | `makeKeyAndVisible()` does not drive `viewWillAppear`/`viewDidAppear`, so app code that starts work there never runs. Small fix; the harness works around it with an explicit call. |
| 5 | **Materials / blur** | 37 / 3 apps | Unchanged from the M14 ranking, and still the largest source of remaining *pixel* error. Not a compile blocker. |
| 6 | **xibs / storyboards** | `@IBOutlet` 1,678 / 323 files | **Out of scope by choice**, restated because it is why 323 of 5,099 files are unreachable by construction. |

The shape of the list has changed qualitatively. At M14 the top blockers were
things OpenUIKit was missing. The top cross-platform blocker is now a
**native-ELF language** restriction that no amount of API surface will fix;
Objective-C-capable responder controls dispatch unchanged source. Everything below it is
either tooling (asset catalogs, localization) or a known pixel divergence. The
useful next work is scaffolding reduction, not type count — see the "code
written around it" section of docs/REAL_APP_TEST.md, where 256 lines of
harness now dwarf the 4 lines of adaptation.
