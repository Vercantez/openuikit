# WidgetKit SDK depth, second pass (agent/fw-widgetkit2)

Base: `origin/agent/fw-widgetkit` (first pass, refused for coverage honesty).
Scope: `full/widgetkit/` plus this report. No uikit sources, no `reference/`
or `tests/acceptance/` edits, no pin files.

## What was refused

`coverage.tsv` marked **2721** identifiers `implemented`, but **2389** of them
cited one test (`tests/agent/WidgetKitViewSurfaceTests.swift#testInertViewSurface`)
— a bulk relabel of the SwiftUI `View`/modifier surface as "inert implemented".
`testConfigurationModifiers` cited **114** rows (over the 60-row / 25% cap).

Invented success is worse than a marked gap. `implemented` evidence must be a
focused test of that identifier's behaviour.

## Coverage before / after

| | implemented | declared | deferred | nondeferred |
|---|---:|---:|---:|---:|
| first pass (refused) | 2721 | 129 | 26 | 2850 |
| this pass | **332** | **2518** | 26 | 2850 |

Public surface is still 2876 precise IDs. The medium-full floor is 1438
nondeferred; 2850 remains well above it.

Every row whose only evidence was the inert/bulk test is `declared` again with
`source:full/widgetkit/<file>.swift#Symbol` (almost all
`WidgetKitViewStubs.swift`; ControlWidget label types in
`WidgetKitControls.swift`). `WidgetKitViewSurfaceTests.swift` is deleted.

`testConfigurationModifiers` (114 rows) was split into four tests, each
exercising a small family:

| test | rows |
|---|---:|
| testConfigurationDisplayNameAndDescription | 40 |
| testConfigurationFamiliesMarginsAndBackground | 30 |
| testConfigurationPushAndSession | 28 |
| testConfigurationTypes | 16 |

No implemented test is cited by more than 60 rows or 25% of implemented rows
(max is 40 / 332 = 12.0%).

## Evidence distribution (top 5 tests by row count)

1. `testConfigurationDisplayNameAndDescription` — 40
2. `testConfigurationFamiliesMarginsAndBackground` — 30
3. `testConfigurationPushAndSession` — 28
4. `testViewWidgetModifiers` — 20
5. `testWidgetLocationAndMounting` — 17
   (tie: `testActivityFamilyAndLevelOfDetail` — 17)

29 distinct cited tests. 332 implemented rows.

## Behaviour this pass actually tests

Cited Apple documentation, not a comparison-score search.

1. **Timeline engine.** Apple WidgetKit `Timeline` / `TimelineProvider`:
   WidgetKit renders the last entry with `date <= T` (closest not after).
   `WidgetTimelineEngine` against an injectable clock: before all dates → first
   entry; at 25 with dates 10/20/30 → stamp 20; after the last date → last
   entry. `TimelineReloadPolicy`: `.atEnd` → last entry date; `.after(date)` →
   that date if `date >= last`; `.never` → no automatic reload. Fail-closed:
   empty, out-of-order, duplicate dates, `.after` before last entry.
2. **WidgetCenter.shared.** Apple `WidgetCenter` documentation: clients use
   the shared instance. Linux has no `chronod`; every `WidgetCenter` instance
   shares one process-local registry so a host (Focus widget guest included)
   can `installCurrentConfigurations`, then `getCurrentConfigurations` /
   `currentConfigurations()` return those infos. `reloadTimelines(ofKind:)`
   / `reloadAllTimelines` append ordered requests. `invalidateConfigurationRecommendations`
   does not drop installed widgets (Apple: it asks for new recommendations);
   the port records a host-visible invalidation count. `currentPushInfo` is nil
   without an aps token.
3. **WidgetFamily canvases.** Apple Human Interface Guidelines, Widgets
   (https://developer.apple.com/design/human-interface-guidelines/widgets),
   Home Screen logical points:
   - SE 375-pt: small 155×155, medium 329×155, large 329×345
   - 393-pt iPhone: small 158×158, medium 338×158, large 338×354
   - 430-pt iPhone: small 170×170, medium 364×170, large 364×382
   Extra-large (iPad) and Lock Screen accessory families return `nil`; the host
   must pass `TimelineProviderContext.displaySize`.
4. **WidgetConfiguration modifiers** as an `Equatable` value store: two
   independently built configs with the same display name, description,
   families, and margin/background flags compare equal; a different
   `supportedFamilies` does not.
5. **Environment values** (`widgetFamily`, `widgetRenderingMode`,
   `showsWidgetContainerBackground`, `widgetContentMargins`) round-trip.
   Default `widgetContentMargins` is `EdgeInsets()` (all zero) until an oracle
   records Apple's system margins (new row in `oracle-questions.tsv`).
6. **WidgetBundle** composition: IceCubes' five-widget `@main` shape
   typechecks (`WidgetBundleBuilder` 1…5). `AccessoryWidgetBackground` plus
   `containerBackground(for: .widget)`.

`widgetkit_guest_sources.txt` is unchanged (seven sorted product sources,
including `WidgetKitTimelineEngine.swift`).

## Verification

- Isolated Linux `swiftc -warnings-as-errors` of `libWidgetKit.dylib` plus 29
  cited tests in `docker exec uikit-linux`: stdout is exactly
  `WIDGETKIT_AGENT_RUNTIME_OK`.
- Mac `swiftc -warnings-as-errors` of `libWidgetKit.dylib`.
- `bash full/widgetkit/tests/acceptance/test_host.sh` still refuses at the
  shared seed validator: `scripts/framework-fanout/generate_seed_v2.py` is
  `e56ee6e7…` on this worktree while sealed `reference/framework.json` pins
  `e44f6bde…`. That digest is immutable; this branch does not rewrite it (same
  refusal the first pass recorded). The compile/test half of that gate is
  green on Linux.
- Focus widget guest builder was not re-run end-to-end (needs the normalized
  Focus_Widget.bundle input). WidgetKit sources remain listed in sorted
  `widgetkit_guest_sources.txt`. No Focus inventory file was edited.

## Open (oracle-questions.tsv)

- `NSUserActivityTypeLiveActivity` string payload.
- Accessory / extra-large point sizes.
- Default `widgetContentMargins` on iPhone 16 / iOS 26.1 (new).
- `chronod` acknowledgement of `reloadAllTimelines` / `currentPushInfo` queue.
