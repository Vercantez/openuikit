# SwiftUI S2: bounded state and observation

S2 adds a deliberately bounded state/observation runtime to OpenUIKit's local
module named `SwiftUI`. It is enough for the current Focus onboarding slice;
it is not a claim that arbitrary SwiftUI applications run. App sources retain
their normal `import SwiftUI`, property-wrapper declarations, and view bodies.
No app file is rewritten or conditionally compiled for this implementation.

## Supported source surface

The local module currently provides these observation declarations:

- `Binding` with `init(get:set:)`, `init(projectedValue:)`, writable dynamic
  members, `wrappedValue`, `projectedValue`, and `constant(_:)`;
- `State` with `init(wrappedValue:)`, `init(initialValue:)`, `wrappedValue`,
  and a projected `Binding`;
- `ObservedObject` with `init(wrappedValue:)`, `init(initialValue:)`, object
  replacement, and projected bindings through reference-writable key paths;
- `DynamicProperty`, including recursive preparation of stored custom dynamic
  properties and inner-before-outer `update()` ordering; and
- the platform `ObservableObject`, `Published`, and related Combine identities
  re-exported by `SwiftUI`.

On native Darwin, SwiftUI compiles against the SDK's first-party `Combine`
module. On Linux, the package's literal `Combine` target re-exports a pinned
OpenCombine revision. SwiftPM platform conditions select that target for a
Linux destination even when the manifest itself is evaluated on macOS; the
shim is not compiled or linked into a native Darwin SwiftUI build.

`Binding`, `State`, `ObservedObject`, and `DynamicProperty` are not globally
`@MainActor`-isolated, matching the source behavior needed to declare and
initialize them in otherwise nonisolated code. View evaluation and the
retained OpenUIKit graph remain main-actor operations.

## Runtime semantics

Before evaluating a view body, the host makes a mutable copy of the view,
recursively prepares its stored dynamic properties, runs `update()`, writes
ordinary value-type mutations back into that copy, and evaluates `body` on
the prepared copy. Nested `State` and `ObservedObject` values are therefore
live before their enclosing custom property's `update()` runs.

Each mounted `State` location is keyed by the implemented structural view
path, stored-property path, and value type. Graph attachment lives on each
prepared `State` wrapper copy, not on its shared pre-mount seed. Reusing one
stateful view value in two tuple positions consequently produces two
locations. A projected binding captures its attached location and cannot be
redirected by preparation of another copy.

The implemented structural path distinguishes:

- tuple positions, optional presence, and conditional branches;
- positional builder arrays;
- explicit `Group` containers;
- `HStack`, `VStack`, `Form`, navigation, and modified content;
- deferred background and overlay content; and
- `ForEach` elements by the actual `Hashable` value supplied through `id:`.

An explicit `ForEach` ID keeps its state across reorder. Removing an ID tears
down that location and detaches old bindings; reinserting it starts from the
new initial value. Positional builder arrays intentionally remain positional.
Same-typed conditional branches do not share state, and removing an earlier
optional does not renumber a later stack sibling.

`UIViewRepresentable` and `UIViewControllerRepresentable` each retain one
coordinator beside the represented object at a stable graph location. Updates
receive that same coordinator, and the corresponding dismantle hook runs once
when the location leaves the graph or its host is destroyed.

The task effect owns one structured `Task` per stable graph location and ID.
Reevaluation with an equal ID preserves it, changing the ID cancels and starts
new work, and removing the view cancels outstanding work. Task cancellation is
cooperative, matching Swift concurrency. Mach-O guest execution additionally
requires the platform's Dispatch/main-executor boundary; source compatibility
does not substitute a synchronous callback.

The current view surface also includes all standard dynamic text styles,
hierarchical foreground styles, color and linear-gradient foreground-style
inputs, `Group`, `accessibilityHidden`, and bitmap-backed decorative Images
with all eight CGImage orientations. A foreground gradient currently resolves
to its leading color for text and symbols; masked gradient glyph rendering is
a separately measurable renderer extension.

`ObservedObject` subscribes once per object identity in the active graph.
Publication schedules one coalesced render on a later main-actor turn. Native
package builds use Swift's main executor. A Foundation-hidden Mach-O guest
uses the next explicit OpenUIKit host-clock tick, avoiding an unavailable
Apple dispatch/voucher dependency while preserving deferred, coalesced UI
work. Host-clock delivery invalidates its one-shot timer and consumes its
action before graph code runs. Each graph pass also owns a reference-identity
token: direct root evaluation retires the old token, so its stale callback
cannot consume a later publication's work. Timers created during a recursively
entered host step remain in the following outermost turn. Removing the view cancels
the subscription; neither the subscription nor detached
State storage retains the hosting controller. Two stored fields that alias one
class `DynamicProperty` still each receive `update()`. Class identities are
tracked only along the active recursive descent so true cycles terminate
without turning aliasing into render-wide deduplication.

## Reflection and safety boundary

Swift has no public writable stored-property reflection API. S2 uses private,
cross-platform Swift runtime entry points also used by the standard library's
Mirror implementation and Reflection SPI. Runtime metadata supplies the true
stored-field count, label, declared type, strength, and byte offset. The
runtime child accessor supplies a balanced value copy; calling it directly
bypasses `CustomReflectable`, so a custom mirror cannot silently hide a
dynamic property. The prepared value is written back only after type,
alignment, field-order, storage-strength, and applicable value-container
bounds checks. Native class-field offsets are runtime-relative to the heap
object and do not have a public object-size bound to check.

This is a conscious compatibility risk, not a stable Swift language contract.
The implementation is gated on Apple Swift 6.2 and the stock Swift 6.2 Linux
toolchain. Emission of full reflection metadata for every client type which
stores a dynamic property is a hard build prerequisite. The normal supported
SwiftPM builds emit it. A client deliberately compiled with
`-disable-reflection-metadata` can report zero runtime fields; that is
indistinguishable from a real zero-field type and can silently skip
preparation. Such a build is unsupported.

Detectable runtime ABI, count, order, type, alignment, bounds, or storage-kind
mismatches terminate with an explicit diagnostic rather than evaluating a
body with silently stale state. Existentially stored dynamic properties and
recognized non-strong concrete fields, such as an unowned class dynamic
property, also fail loudly because their physical storage cannot be safely
written as the opened concrete value. A weak reference is Optional storage and
is not recognized as a direct DynamicProperty field. Stored fields in
unsupported container metadata kinds fail loudly when the runtime reports
them.

Mounted State mutation and `ObservableObject` publication are UI mutations.
They must occur on the main actor; an off-main call traps at the asserted
boundary instead of racing the OpenUIKit tree. An unmounted local `State`
value remains usable from nonisolated code.

## Not claimed

S2 does not yet provide `StateObject`, environment values/objects, focus,
preferences, transactions, animations, SwiftUI's general diffing engine, or
the complete APIs of the four supported wrappers. `ForEach` still
eagerly expands the implemented OpenUIKit node tree and does not animate
insertions or moves. The renderer and layout vocabulary remain the bounded S1
and S1.5 surfaces plus later explicitly documented slices; this observation
runtime does not make unsupported SwiftUI views render.

The focused regression suite covers state survival and teardown, same-type
conditional isolation, optional/tuple/stack and array boundaries, typed
`ForEach` reorder/removal, nested State plus ObservedObject lifecycle,
value-type `update()` write-back, class-property aliasing, custom mirrors,
reference ownership, and reused stateful view values. Native Darwin and Linux
release probes exercise the same unchanged source spellings.
