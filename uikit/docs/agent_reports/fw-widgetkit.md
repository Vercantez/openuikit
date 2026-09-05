# WidgetKit SDK depth (agent/fw-widgetkit)

## What was measured

Public iPhoneOS 26.1 WidgetKit surface in `full/widgetkit/reference/public-surface.tsv`: **2876** precise IDs. Before this branch, coverage was **149 implemented / 2701 declared / 26 deferred**. After: **2721 implemented / 129 declared / 26 deferred**.

The Widget, Timeline, WidgetCenter, and WidgetFamily families are nondeferred except `#Preview` / `PreviewTimelineBuilder` (26 deferred rows total; AGENTS.md forbids prioritizing `#Preview`).

## Rules (cited, not searched)

1. **Entry at time T.** Apple WidgetKit `Timeline` documentation: WidgetKit renders the timeline entry whose `date` is closest to, but not later than, the current date. `WidgetTimelineEngine.entry(ofKind:at:)` takes the last entry with `date <= T`, or the first entry if `T` is before every date.
2. **Reload policy.** Apple `TimelineReloadPolicy`: `.atEnd` reloads at the last entry date; `.after(date)` reloads at that date (fail-closed if `date` is before the last entry); `.never` has no automatic reload.
3. **Home Screen canvas sizes.** Apple Human Interface Guidelines, Widgets, plus WidgetFamily documentation. Logical points used here:
   - SE 375-pt class: small 155×155, medium 329×155, large 329×345
   - 393-pt iPhone: small 158×158, medium 338×158, large 338×354
   - 430-pt iPhone: small 170×170, medium 364×170, large 364×382
   Extra-large (iPad) and Lock Screen accessory families return `nil`; the host must pass `TimelineProviderContext.displaySize`. Oracle questions record the missing tables.
4. **WidgetCenter.** Process-local configurations and ordered reload requests; `currentPushInfo` is nil without an aps token (fail-closed, tested).

## Verification

- Isolated Linux compile + 27 cited tests in `docker exec uikit-linux`: module `swiftc -warnings-as-errors`, load-smoke marker `WIDGETKIT_AGENT_RUNTIME_OK`.
- Mac `swiftc` of `libWidgetKit.dylib` with warnings-as-errors.
- `bash tests/acceptance/test_host.sh` still refuses at the shared seed validator: `scripts/framework-fanout/generate_seed_v2.py` is `e56ee6e7…` on this worktree while immutable `reference/framework.json` pins `e44f6bde…`. That digest is sealed; this branch does not rewrite it. The compile/test half of the same gate is green on Linux.
- Focus widget guest builder was not re-run end-to-end (needs the normalized Focus_Widget.bundle input). WidgetKit sources remain listed in sorted `widgetkit_guest_sources.txt` with the original six paths plus `WidgetKitTimelineEngine.swift`. No Focus inventory file was edited.

## Out of scope / open

- Accessory and extra-large point sizes (oracle-questions.tsv).
- Preview macros (deferred).
- `NSUserActivityTypeLiveActivity` string payload (deferred).
- Control widget templates remain mostly declared (129 declared rows, mostly ControlWidget*).
