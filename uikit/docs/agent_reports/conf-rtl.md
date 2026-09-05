# RTL conformance axis + two layout-direction rules

Nothing in the oracle exercised right-to-left layout. This branch adds an
RTL axis to the harness the way `--dark` was added, captures NavFlow,
TableEditor and Forms on the SE 2x, and closes the two largest measured
misses per app.

## Harness

`scripts/conformance_flow.sh <workdir> <App> --rtl` sets
`CONFPROBE_DIRECTION` / `OPENUIKIT_APP_DIRECTION=rtl`. Capture names are
suffixed `.rtl` (`t200.rtl`); combining `--dark --rtl` yields
`t200.dark.rtl`. LTR names stay `t200`.

`--dark` can pin the window alone because `overrideUserInterfaceStyle`
inherits through traits. `semanticContentAttribute` does **not**
propagate: a child of an RTL parent with `.unspecified` stays LTR
(`UIButtonTests`).

MEASURED `/tmp/rtlprobe`, iPhone SE 2x / iOS 26.1:

| pin | rtl views | large title x | switch x | disclosure x |
|---|---|---|---|---|
| window only | 1/76 (window) | 16 | 282 | 332.5 |
| window + root + navbar | 4/76 | still LTR content | 282 | — |
| `UIView.appearance()` + window | **74/76** | **247.5** | **0** (cell-local) / **16** abs | **16** |

Two views stayed LTR under appearance (`UITableViewCellContentView`,
`UISwitchModernVisualElement` — private / spatial). OpenUIKit's
`contentView` is a normal `UIView` and picks up the appearance stamp.
`UIApplication.shared.userInterfaceLayoutDirection` stayed **ltr** in
every pin.

The `--rtl` axis therefore sets
`UIView.appearance().semanticContentAttribute = .forceRightToLeft` (and
`UINavigationBar.appearance()`) **before** `makeRoot()`, then the window.
`UIView.init(frame:)` copies a non-unspecified appearance value so the
port matches that stamp. Round scores `/tmp/hc-conformance-<App>-rtl`
(`scripts/hillclimb.sh`, `scripts/agent_merge.sh`, `scripts/scoreboard.py`
keys `NavFlow.rtl`).

## Baseline (RTL, appearance pin, before the two rules)

All on iPhone SE 2x / iOS 26.1. Window-only RTL was byte-score identical
to LTR (NavFlow t3000 98.196 blob 97.2).

| app | worst | mean | notes |
|---|---|---|---|
| NavFlow | **92.170** (t4800.rtl) | 94.153 | t200.rtl 92.960; t3900.rtl blob **851.5** at the switch |
| TableEditor | **90.338** (t2350.rtl) | 91.297 | every capture blob 296.8 |
| Forms | **89.566** (t1200.rtl) | 89.656 | switch abs.x 298 vs 16; labels at 16 vs ~300 |

### Frames (golden vs ours, before)

NavFlow t200.rtl: large title `"Library"` 247.5 vs 16; `"Notifications"`
247 vs 32; `"On"` 50.5 vs 302; `"Filter"` 31.703 vs 303.5; header
`"General"` 281 vs 32.

NavFlow t3900.rtl: `UISwitch` 32 vs 282; `"Allow Notifications"` 201.5 vs
32; large title `"Notifications"` 155.5 vs 16.

TableEditor t200.rtl: `"Reminders"` 189 vs 16; `"Alpha"` 315.5 vs 16;
`"Edit"` 31.74 vs 312.5.

Forms t200.rtl: switch 16 vs 298; `"Enabled"` 297.5 vs 16; date picker
16 vs 231; `"Small"` 284.5 vs 56.

## Rule 1 — Auto Layout `.leading` / `.trailing`

`.left` / `.right` stay physical. `.leading` / `.trailing` (and the
margin twins) follow the item's
`effectiveUserInterfaceLayoutDirection`. A layout guide follows its
owning view.

MEASURED Forms t200.rtl + NavFlow t3900.rtl, iPhone SE 2x / iOS 26.1:
`label.leading = guide.leading` (constant 0) puts Enabled at abs.x
**297.5**; `switch.trailing = guide.trailing` puts the switch at **x=16**.
`switchLabel.leading = card.leading + 16` puts `"Allow Notifications"` at
**201.5** (16 pt *inward* from the card's right). Mapping leading → right
edge without negating the constant would add 16 to the right edge.

The axis reverse also swaps `≤` / `≥`: Forms
`label.trailing ≤ control.leading − 8` stays a **minimum** 8 pt gap
(Enabled stays 61.5 wide at x 297.5, not stretched to 274). Unspecified
still resolves LTR, so Catalyst fixtures and LTR captures do not move.

## Rule 2 — table / nav chrome mirror

Stock cell chrome, headers, large titles, and bar-button groups are
packed in LTR then mirrored about the view width when `_layoutIsRTL`.
Auto Layout children of `contentView` (Forms `pinTrailingControl`) are
already placed by rule 1 and are not mirrored again.

MEASURED NavFlow t200.rtl / TableEditor t200.rtl / `/tmp/rtlprobe`,
iPhone SE 2x / iOS 26.1:

- `"Library"` large title x **247.5** = 375 − 16 − 111.5
- `"Reminders"` **189** = 375 − 16 − 170
- `"Alpha"` **315.5** = 375 − 16 − 43.5
- disclosure abs.x **16**; chevron points trailing (left) in the 10.5 box
- `leftBarButtonItems` are the leading group → Filter / Edit on the
  physical left (trailing)
- `UILabel` `.natural` draws on the leading (right) edge
- `UISegmentedControl` packs leading-to-trailing: Forms `"Small"` (index 0)
  on the right, `"Large"` on the left

## After (SKIP_CAPTURE=1)

| app | capture | before | after |
|---|---|---|---|
| NavFlow | t200.rtl | 92.960 | **99.599** |
| NavFlow | t3900.rtl | 94.520 (blob 851.5) | **98.788** (blob 58.8) |
| NavFlow | t4800.rtl | 92.170 | **98.712** |
| NavFlow | worst / mean | 92.170 / 94.153 | **97.812 / 98.960** |
| TableEditor | t200.rtl | 93.064 | **99.051** |
| TableEditor | t2350.rtl | 90.338 | **97.574** |
| TableEditor | worst / mean | 90.338 / 91.297 | **97.574 / 98.782** |
| Forms | t200.rtl | 89.583 (layout 16) | **97.901** (layout 5) |
| Forms | worst / mean | 89.566 / 89.656 | **97.793 / 97.838** |

NavFlow t3000.rtl leftover is the known LTR OPEN: iOS 26 44×44 glass
back chevron vs the port's `'‹'` + `'Library'` (layout_issues=2, blob
58.8). Forms leftover is the compact date-picker capsule (golden text
h=20 vs ours 34) and segmented height 34 vs 33 — same class as LTR
Forms.

## LTR / gates

LTR SKIP_CAPTURE=1 against `/tmp/hc-conformance-<App>`:

- NavFlow t200 **99.622** / t1200 99.248 / t3000 98.196 — identical to
  the pre-change summary
- Forms t200 **98.910** / worst 98.895 / mean 98.933 — identical
- TableEditor rest scores match the current LTR floor (t2350 97.578)

Catalyst **124/124**. iOS suite **112/113** (known `corner_radius`
99.411). Real-app floors held: **99.137 / 98.535 / 98.548 / 99.469 /
98.639 / 98.133 / 97.516 / 99.511 / 82.192 / 99.760 / 99.689 / 84.582**.
Linux `swift:6.2-noble` `openrender` green. No `Package.resolved`.
