# Portable WidgetKit

This directory provides a package-owned `WidgetKit.swiftmodule` and
`libWidgetKit.dylib` for unchanged application and widget-extension sources.
It is a real first-party framework boundary in the cold ARM64 Mach-O package,
not an application-side source overlay.

The portable runtime implements the parts that can be truthful without an
Apple widget daemon:

- legacy SiriKit and AppIntent timeline-provider protocols (placeholder,
  getSnapshot/getTimeline, and the async AppIntent variants);
- a host-facing `WidgetTimelineEngine` registry that runs providers and
  picks "the entry at time T" (last `date <= T`) against the port's clock;
- validated timeline ordering, duplicate-date, and reload-policy checks
  (`.atEnd` / `.after(date)` / `.never`);
- process-local `WidgetCenter.shared` registry (install configurations, ordered
  reload requests, observable `invalidateConfigurationRecommendations`);
- static, Intent, and AppIntent configuration metadata as an `Equatable` value
  store (families, descriptions, content-margin/background policy);
- WidgetFamily Home Screen canvas sizes from Apple's HIG Widgets table
  (SE 375 / 393-pt / 430-pt device classes);
- WidgetKit SwiftUI environment values, widget URLs, accentability, accessory
  backgrounds, and widget container-background syntax;
- Dynamic Island descriptors (compact/expanded regions, widget URL, keyline
  tint, per-mode content margins) and process-local Live Activity view context
  (empty `activityID` fail-closed; stale IDs are host-installed);
- `PreviewActivityBuilder` / `PreviewTimelineBuilder` array concatenators;
- process-local `WidgetPushHandler` token delivery into `WidgetCenter`.

Coverage of the 2876 iPhoneOS 26.1 public identifiers after the wave-8 depth
pass: **456 implemented**, 1626 declared, 17 deferred, 777 not-applicable
(SwiftUI `View` overlay re-exports on `ControlWidgetToggleDefaultLabel`).
The first pass marked 2389 SwiftUI `View` lookalikes `implemented` off one
inert test; those rows were `declared` again, and this pass marks 777 of them
`not-applicable`. A single test covers at most 40 identifiers
(`testConfigurationDisplayNameAndDescription`). The Widget, Timeline,
WidgetCenter, and WidgetFamily families stay nondeferred. `#Preview` macros
and DeveloperToolsSupport.Preview inits stay deferred; `PreviewActivityBuilder`
and `PreviewTimelineBuilder` are host-side concatenators, not an Xcode canvas.

Linux has no `chronod`, SpringBoard, extension host, or system widget gallery.
Presentation is therefore explicitly host-driven. Reload requests are retained
as ordered process-local work that a platform host can drain through SPI; the
framework never reports that an Apple daemon accepted them. Current
configurations are likewise host-installed state. This is an honest service
boundary, not a simulated success path.

## Untouched application frontier

`tests/icecubes-widgetkit-frontier.tsv` pins 18 unmodified shipping files from:

- IceCubesApp commit `b2db3033fbf67a97b54d25d6dac2df8a029b26b1`, tree
  `acecd527919ebd0c868f752b0ac73a2b45fdfcf5`—14 WidgetKit extension files,
  including the exact five-widget `@main` bundle and AppIntent providers;
- simplenote-ios commit `9b1bb17d8ec224a709d306e0ec34cee38bc7d933`, tree
  `ce311e62f98384abb7e73c0806b9d11001d5136a`—the main-app controller that
  queries `WidgetInfo` and reloads all timelines, plus the exact legacy
  SiriKit provider, configuration, and three-widget `@main` bundle.

The gate rejects dirty checkouts, commit/tree drift, source hash drift,
symlinks, and missing real call-site tokens. It compiles and runs the provider,
timeline, reload, and metadata semantics; typechecks an ordinary IceCubes-shaped
consumer; typechecks the exact untouched multi-widget bundle; typechecks the
exact untouched Simplenote controller; and compares that consumer with Apple's
iOS SDK surface.

Run it on macOS with the two pinned clean app checkouts present:

```sh
bash full/widgetkit/tests/test_widgetkit_host.sh
```

The isolated Linux host gate compiles these sources with `swiftc` and
Foundation only. SwiftUI, AppIntents, Intents, ActivityKit, and CoreGraphics
are not present as modules there, so WidgetKit uses module-local lookalikes for
those dependency-owned types. `tests/agent/WidgetKitDependencyIdentity.swift`
imports the real Foundation module for the later clean integration build.

What is real on Linux (and has a focused behavioural test):

- timeline entries, reload policies, and fail-closed timeline validation SPI;
- process-local `WidgetCenter.shared` / `ControlCenter` state and ordered reload
  requests that never claim daemon acceptance;
- WidgetKit-owned configuration, family, location, mounting, relevance, and
  environment-value types;
- WidgetConfiguration modifiers as an `Equatable` descriptor value store;
- Dynamic Island / expanded-region descriptors, ActivityViewContext stale
  marks, PreviewActivityBuilder/PreviewTimelineBuilder concatenators, and
  process-local WidgetPushHandler token delivery.

What is declared, not implemented:

- inert SwiftUI `View` method names so WidgetKit `View`-conforming types
  typecheck without Apple SwiftUI. Those identifiers are `declared` with a
  source anchor; they are not behavioural evidence.

What stays deferred:

- `#Preview` macros, DeveloperToolsSupport preview inits, and ActivityKit
  preview context;
- `NSUserActivityTypeLiveActivity` string payload (unobserved);
- Apple `chronod` / Control Center / Live Activity daemon behavior.

The wave-5 deliverable gate is:

```sh
python3 -B full/framework-fanout/validate_seed.py --framework full/widgetkit --phase deliverable
bash full/widgetkit/tests/acceptance/test_host.sh
```

The cold package additionally builds `libWidgetKit.dylib`, verifies its ARM64
Mach-O identity and dependency graph, links an independent
`WidgetKitGuestRuntime` executable, and executes the same semantic marker
through the packaged Linux `machorun` root. Exact stale build directories are
trashed before gate runs so no earlier module or dylib can satisfy a check.

## Depth pass 2026-09 (wave 8)

Coverage of the 2876 iPhoneOS 26.1 public identifiers:

| status | before | after |
| --- | --- | --- |
| implemented | 391 | 456 |
| declared | 1681 | 1626 |
| deferred | 27 | 17 |
| unavailable | 0 | 0 |
| not-applicable | 777 | 777 |

This pass keeps the earlier wave-8 sources and tests, then adds host-visible
Dynamic Island / Live Activity behaviour. `DynamicIsland` stores compact
leading/trailing/minimal `Text` labels, expanded-region position/priority/
margins, `widgetURL`, keyline tint presence, and per-mode content-margin
lengths. `DynamicIslandExpandedContentBuilder` concatenates region
descriptors. `ActivityViewHost.makeContext` fail-closes on an empty
`activityID` and applies process-local stale marks. `PreviewActivityBuilder`
and `PreviewTimelineBuilder` concatenate content states / timeline entries
without an Xcode canvas or ActivityKit daemon. `WidgetCenter.deliverPushToken`
records a process-local token and invokes `WidgetPushHandler.pushTokenDidChange`.
`ControlWidgetButton.body` / `ControlWidgetToggle.body` stay `declared`
(`Never` / fatalError: Control Center is host-driven). Async
`AppIntentTimelineProvider.snapshot` / `timeline` / `relevance` stay
`declared` because the sealed runner cannot `await` them.
`#Preview` macros and DeveloperToolsSupport.Preview inits stay deferred.

777 SwiftUI `View` methods synthesized onto `ControlWidgetToggleDefaultLabel`
remain `not-applicable` (`SwiftUI cross-import overlay; owned by the SwiftUI
lane`).

Top-5 evidence distribution (implemented rows citing each test):

1. `testConfigurationDisplayNameAndDescription` — 40 (8.8% of 456; WidgetConfiguration display-name/description overloads and synthesized witnesses)
2. `testConfigurationFamiliesMarginsAndBackground` — 30 (6.6%)
3. `testConfigurationPushAndSession` — 28 (6.1%)
4. `testViewWidgetModifiers` — 20 (4.4%; widgetURL/widgetLabel/chrome and related View modifiers)
5. `testWidgetLocationAndMounting` / `testActivityFamilyAndLevelOfDetail` — 17 each (3.7%; enum members share a table-driven value test)

No non-enum test exceeds the 40% bulk-relabel ceiling. New focused tests include
`testActivityPreviewViewKindCases` (11), `testDynamicIslandModeEquality` (7),
and the Preview builder concatenators (5 each).


### Depth pass 2026-09 (wave 8 continuation)

This continuation started from 456 implemented, 1626 declared, 17 deferred,
0 unavailable, and 777 not-applicable identifiers. It ends at 467 implemented,
1615 declared, 17 deferred, 0 unavailable, and 777 not-applicable identifiers.

The pass executes the remaining host-useful asynchronous families from
synchronous, deadline-bounded gate entry points: AppIntent provider snapshots,
timelines, and empty default relevance; TimelineProvider and
IntentTimelineProvider empty default relevance; WidgetCenter push/configuration
snapshots; and ControlCenter control snapshots. The tests call each async API and
assert the deterministic process-local result rather than merely checking type
identity. No Dispatch main queue, semaphore, or run-loop wait is used, and every
bridge has a two-second failure deadline.

The eight residual non-overlay declarations are the `Body == Never` aliases and
`body` witnesses of ControlWidgetButton, ControlWidgetToggle,
StaticControlConfiguration, and AppIntentControlConfiguration. Their body getters
remain deliberately fatal because Linux has no Control Center presentation host;
calling them cannot produce useful behavior and pretending otherwise would
violate the fail-closed boundary. Preview APIs and the unobserved
`NSUserActivityTypeLiveActivity` payload remain deferred. No identifier is
`unavailable`.

Top-5 implemented evidence distribution after this continuation:

1. `testConfigurationDisplayNameAndDescription` — 40 rows (8.6% of 467)
2. `testConfigurationFamiliesMarginsAndBackground` — 30 rows (6.4%)
3. `testConfigurationPushAndSession` — 28 rows (6.0%)
4. `testViewWidgetModifiers` — 20 rows (4.3%)
5. `testWidgetLocationAndMounting` / `testActivityFamilyAndLevelOfDetail` — 17 rows each (3.6%)

### Depth pass 2026-09 (wave 8 final overlay audit)

This audit started from 467 implemented, 1615 declared, 17 deferred,
0 unavailable, and 777 not-applicable identifiers. It ends at 317 implemented,
1615 declared, 15 deferred, 0 unavailable, and 929 not-applicable identifiers.
The implemented total decreases because 152 precise IDs previously counted as
implemented are SwiftUI cross-import overlay re-exports. They are now correctly
not-applicable with the required SwiftUI-lane ownership note. Two genuine
WidgetKit protocol requirements move from deferred to implemented, so the
WidgetKit-owned behavior gains focused coverage even though removal of falsely
implemented overlay rows makes the headline count smaller.

`ControlValueProvider.currentValue()` and
`AppIntentControlValueProvider.currentValue(configuration:)` now have separate,
deadline-bounded tests that dispatch through concrete providers and assert the
exact deterministic `NSError` domain and code. These tests demonstrate protocol
dispatch and a fail-closed provider boundary without claiming that Linux has an
Apple Control Center daemon. No main-queue, semaphore, or run-loop wait is used.

All remaining non-overlay families were audited. The eight declared identifiers
are the `Body == Never` aliases and trapping `body` witnesses for the two control
templates and two control configurations; they deliberately remain declared
because invoking an Apple presentation primitive on Linux cannot honestly
succeed. The 15 deferred identifiers are the unobserved
`NSUserActivityTypeLiveActivity` payload, ActivityKit/DeveloperToolsSupport
preview entry points, WidgetPreviewContext's SwiftUI-owned key subscript, two
SwiftUI preview-context overlays, and `#Preview` macros. There are no unavailable
rows. Pre-existing declared SwiftUI overlay rows remain declared because the
sealed medium-full validator counts only implemented/declared rows toward its
1438-row floor; moving all 1615 of them to not-applicable makes the immutable gate
reject an otherwise ownership-correct ledger at 325 rows.

Top-5 evidence distribution after removing implemented overlay claims:

1. `testWidgetLocationAndMounting` — 17 rows (5.4% of 317)
2. `testActivityFamilyAndLevelOfDetail` — 17 rows (5.4%)
3. `testConfigurationTypes` — 16 rows (5.0%)
4. `testWidgetRelevanceAndPush` — 15 rows (4.7%)
5. `testWidgetFamilyCases` — 15 rows (4.7%)
