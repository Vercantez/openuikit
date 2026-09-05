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
  backgrounds, and widget container-background syntax.

Coverage of the 2876 iPhoneOS 26.1 public identifiers: **332 implemented**,
2518 declared, 26 deferred (preview / unobserved constant). The first pass
marked 2389 SwiftUI `View` lookalikes `implemented` off one inert test; those
rows are `declared` again. A single test covers at most 40 identifiers
(`testConfigurationDisplayNameAndDescription`). The Widget, Timeline,
WidgetCenter, and WidgetFamily families stay nondeferred except the
`#Preview` timeline builders, which AGENTS.md forbids prioritizing.

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
- WidgetConfiguration modifiers as an `Equatable` descriptor value store.

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
