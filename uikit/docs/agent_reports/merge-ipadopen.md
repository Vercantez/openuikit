# Merge: ipad-open pad glass kinds + dark-rest dark bar glass

MERGE TASK, no new rules. `origin/agent/ipadopen-merged` (pad glass kinds
from ipad-open) into current main (dark-rest `_usesIOSDarkBarGlass`).

## What conflicted

`RenderPass.swift` (`view:` vs `bar:`), `UIGlassMaterial.swift` (mix table
+ `apply` signature), `GlassMaterialTests.swift` (both test sets),
`scoreboard/open.txt`, `docs/REAL_APP_TEST.md`.

## Resolution

One `apply(in:path:bounds:dark:view:)` that reads `_iosGlassKind` **and**
`_usesIOSDarkBarGlass`. Dark bar is **not** a `.darkBar` kind: the same
`.platter` view is light 253/220 and dark 19/84 (flag on the view, mix
selected from the trait). Pad popovers stay two other kinds.

| mix | interiors | constants | sample |
|---|---|---|---|
| platter light | 253 / 220 | α=222/255, T=220/222 | glass_toolbar_se |
| dark sheet | 57 over black | α=203/255, T=57/203 | /tmp/sheetfill_dark |
| dark bar | **19** / **84** | α=190/255, T=19/190 | /tmp/glass-dark-out, SE 2x |
| pad content popover | **252** / **215** | α=218/255, T=215/218 | /tmp/ipad-open-cap popover_* |
| pad action-sheet | **246** / **178** | α=187/255, T=178/187 | /tmp/ipad-open-cap popover_actionsheet_* |

Tests: main's `GlassMaterialTests` plus ipad-open's named pad tests (never
keep-both on braces). Scoreboard keeps `pad-content-popover-halo` and
`Tabs-t2000-dark-bar-chroma`. Fidelity table keeps both rows (ipad-open
newest).

## After (this Mac, SKIP_CAPTURE=1)

Modal-ipad (`scripts/conformance_flow.sh /tmp/hc-conformance-Modal-ipad Modal --ipad`)
matches ipad-open: mean **98.988**, worst **91.491** (t7200), t3200 **99.781**,
t9200 **98.923**, t600 **99.235**, t1200 **99.367**.

Tabs-dark (`…/Tabs-dark Tabs --dark`) keeps dark-rest's glass captures:
t1000.dark **98.784**, t2000.dark **84.907** blob **8.0**. Mean **94.279**
(dark-rest wrote 92.667; t200.dark 97.315 vs 93.920 is main's later 52 pt
plain-row rule, not a glass miss).

Catalyst **124/124**. Real-app unchanged vs main: **99.137 / 98.535 / 98.548 /
99.469 / 98.639 / 98.133 / 97.516 / 99.511 / 82.192 / 99.760 / 99.689 / 85.393**.
Suite **112/113** (known `corner_radius` 99.411). `swift test --filter GlassMaterial` 12/12.
`swift build --build-tests` green. Linux `swift:6.2-noble` openrender green. No `Package.resolved`.
