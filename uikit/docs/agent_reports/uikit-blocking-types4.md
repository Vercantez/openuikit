# Triple-column display-mode resolution

Branch: `agent/uikit-blocking-types4`, based on `origin/agent/uikit-blocking-types3`.
Measured 2026-09-07 (America/Chicago), iOS 26.1 / 23B86, private iPad A16 @2x.

## One completed item

The inherited report left wider triple-column behavior open. This change
closes the **display-mode resolution** question across initial appearance,
explicit mounted requests and bounds resizing. Split view was the highest-use
implemented family with an applicable remaining item (54 corpus references).
No other family was changed and no subagents were used.

Before: **503/805** captured mode-and-actual-behavior observations matched.
After: **805/805** match. The previous 820 pt special case was not a width rule:
it reported two-displace at wide widths and incorrectly handled initial
requests and subsequent resize transitions.

The first tiled frames measure primary `[10,32,240,658]`, supplementary
`[0,0,490,700]` with safe-left 250, secondary `[490.5,0,464,700]`. Required
width is **240 + 240 + 10 + 0.5 + 464 = 954.5 pt**. Pixel rounding explains
**954.249 → not tiled**, **954.25 → tiled** on the 2x oracle. Raising either
side minimum to 300 shifts the boundary +60; secondary minimum 500 shifts
it +36. Every constant is a measured frame component, minimum or pixel size.

Initial narrow requests for two-beside/two-displace resolve to one-beside;
explicit mounted requests resolve to two-over. At sufficient width both
resolve to two-beside. Narrowing a tiled layout returns to one-beside.
Explicit overlay requests remain overlaid on resize, while initial overlay
preferences start secondary-only. Requested modes remain stored separately
from the actual result. Automatic resolves to one/two-beside according to fit.

The rule and resize driver are guarded by `systemFontCut == .iOS` and the
triple-column style. Source, reproduction script, six verbatim oracle JSONs
and an 805-observation replay test are carried under
`Tools/oracle2/splitwidthprobe/` and `Tests/OpenUIKitTests/UISplitViewWidthTests.swift`.

## Scope and remaining questions

No declarations were added, so this behavioral correction does not change
the inherited textual census (54 blocking types / 280 uses; weighted
95.860884%, effective 99.639176%). These are inherited census numbers, not
a new census run or a claim of additional app launches.

Floating sidebar pixels, safe areas, actual column frames/width getters,
interactive animation, compact/regular containment changes, inspector,
direct split-behavior overrides, and post-appearance sizing preference
changes remain open. Measurements
cover regular-width containers at 700 pt height, including widths beyond
the physical screen; they do not claim additional physical devices. The
other families' remaining items are unchanged.

## Validation

- **19 tests pass**: the new 805-observation replay plus all 18 existing
  split-view tests. Before replay: 503/805 matched; after: 805/805.
- Native release build passes (73.75 s).
- Fresh iOS suite **112/113 before and after** against the same fresh
  goldens. All 113 numeric scores and rendered PNGs are identical. The
  existing `corner_radius` miss remains 99.411 against a 99.5 bar.
- Catalyst **124/124 before and after**, all 178 rendered PNGs identical.
- All 15 real-app PNGs and all 14 scorable values are identical. The browser
  golden is absent in both runs. Hackers feed remains 98.235, Ledger 99.610.
- Linux `swift:6.2-noble` release `openrender` passes (219.30 s).
- Required merge-check proof is recorded after completion.
