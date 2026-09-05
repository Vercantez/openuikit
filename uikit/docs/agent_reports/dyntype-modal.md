# Dynamic Type modal remainder

`origin/agent/dyntype-merged` closed ax1 chrome on NavFlow / Modal / Tabs /
Pager / Notes (report `dyntype-rest.md`) but dropped four round-15 rows
when re-rendered against `/tmp/hc-conformance-Modal-{ax1,xxxl}` (and the
matching Notes / Tabs goldens). This branch keeps those rules and fits the
samples the merge could not: the t7200 action sheet at ax1/xxxl, Notes
t4000.xxxl's first header, and Tabs t7000's programmatic hide offset.

Goldens are the round-15 captures (read-only `/tmp/hc-conformance-*`;
copied to `/tmp/conformance-*`). Device: iPhone SE 2x / iOS 26.1.
`SKIP_CAPTURE=1 scripts/conformance_flow.sh`. Floor is
`scoreboard/latest.md` at `45f6395b`.

## Why the merge dropped

The ax1 alert rule was measured on Modal t5200 (titled alert: title 33
Semibold, message 30 Regular 2-line 72, pills `max(48, lineHeight+24)` =
63.5). Applying that growth to every action stack:

| sample | what grew | golden | merge |
|---|---|---|---|
| t7200.ax1 | presented card with 5×63.5 pills → 381.5 | PhoneTVMacView **304**, sequence 381.5 clipped | 88.97 → **74.57** |
| t7200.xxxl | pills 27.5+24 = 51.5, card stretched | pills still **48**, card **304** | 97.33 → **89.45** |
| Notes t4000.xxxl | search field `scaledValue(44)` = 58 matched; first header stayed 55.5 | header **38**, table y 84 | 78.91 → **77.50** |
| Tabs t7000.ax1 | 80 pt rows at `setContentOffset(200)` | offset **296** = 200+96 | 92.06 → **91.42** |

t7200 is a **headerless action sheet** (Copy / Share / Favorite / Delete /
Cancel), not t5200.

## Frames (golden, SE 2x / iOS 26.1)

**Modal t7200** (no title/message):

| category | card | pills | labels |
|---|---|---|---|
| `.large` | 304 | 48 | 17 Medium, h=20.5; Copy y pad ceil((48−20.5)/2)=14 |
| `.xxxl` | 304 | **48** | 23 Medium, h=27.5; Copy abs 208 − pill 197.5 = **10.5** |
| `.ax1` | **304** (clips) | **63.5** | 33 Medium, h=39.5; sequence 381.5 |

**Modal t5200.ax1** (titled): card 426, title 33 / message 30 2-line 72,
pills 63.5. Header slack (title relative y 73 vs 22) stays OPEN.

**Notes t4000.xxxl:** search field `[16, 18, 274, 58]`, bar 74, table y 84,
first header **38**. `scaledValue(44)` at xxxl = 58 (table interpolates
40→52.667, 48→63.333). Notes t200.xxxl at SA.top 64 golden header is 38 —
left OPEN so Forms t200.xxxl grouped Account 55.5 does not drop.

**Tabs t7000:** `setContentOffset(200)` lands at **260 / 274 / 296** =
200 + (8+field+8) with `hidesSearchBarWhenScrolling`. Rows: `.large` 52,
xxxl **59**, ax1 80.

**NavFlow t200.xxxl:** bar `[0, 10, 375, 108]` = 54 + **54** (40 Bold box
48; `max(52, 48+4)` is 52 → bar 106). Filter / inline Library **21 pt**
(extraExtraLarge cap; xxxl is not an accessibility category). Large title
uncapped 40.

## Rules (iOS cut)

1. **Pills grow only on `isAccessibilityCategory`.** xxxl stays 48 (t7200 /
   t5200.xxxl). ax1 stays 63.5 (t5200.ax1 / t7200.ax1).
2. **Headerless action-sheet presented height is the 48-pt stack (304 for
   5 actions)** even when pills are 63.5; `clipsToBounds` on that card.
   Titled alerts still size from scaled content (t5200).
3. **Action-label y is `iOSCeilToPixel((pill−line)/2)`** on iOS.
4. **Inset-grouped first header is compact 38** when `SA.top > 10+54`
   (search overlay). Pad and grouped (Forms) unchanged. Large-title
   compact (SA.top ≥ expanded inset) unchanged.
5. **Programmatic `setContentOffset` with `hidesSearchBarWhenScrolling`
   adds `max(54+6, 8+scaledField(44)+8)`.**
6. **Plain classic xxxl row is 59** (measured Tabs t200.xxxl / t7000.xxxl).
   ax1 stays `scaledValue(44)=80`; `.large` `max(52, 44)=52`.
7. **Large-title visual zone floors at 54 at xxxl** (bar 108, inset 118).
   ax1 stays 61.5 / 115.5 / 125.5.
8. **`iOSBarCapped` includes xxxl** → extraExtraLarge (21 pt Filter /
   inline). Accessibility was already capped.

## After SKIP_CAPTURE=1 vs round-15 (`45f6395b`)

Named floors:

| scene | round-15 | dyntype-merged | this branch |
|---|---|---|---|
| Modal t7200.ax1 | 88.97 | 74.57 | **97.399** |
| Modal t7200.xxxl | 97.33 | 89.45 | **98.240** |
| Notes t4000.xxxl | 78.91 | 77.50 | **87.408** |
| Tabs t7000.ax1 | 92.06 | 91.42 | **95.977** |

Other rows that moved ≥ 0.05 (all held or gained except the leftover pair):

| scene | round-15 | after | Δ |
|---|---|---|---|
| Modal t5200.ax1 | 66.14 | 77.202 | +11.06 |
| Modal t5200.xxxl | 81.31 | 84.986 | +3.68 |
| Notes t4000.ax1 | 69.97 | 86.269 | +16.30 |
| Notes t5000.ax1 | 79.35 | 89.871 | +10.52 |
| Notes t11000.ax1 | 45.17 | 52.170 | +7.00 |
| Notes t11000.xxxl | 55.73 | 58.499 | +2.77 |
| Tabs t200.ax1 | 92.60 | 96.546 | +3.95 |
| Tabs t4000.ax1 | 87.80 | 94.207 | +6.41 |
| Tabs t7000.xxxl | 91.85 | 96.173 | +4.32 |
| Tabs t200.xxxl | 92.61 | 96.424 | +3.81 |
| NavFlow t200.xxxl | 94.29 | 97.362 | +3.07 |
| NavFlow t4800.xxxl | 93.47 | 96.409 | +2.94 |
| NavFlow t4800.ax1 | 93.01 | 94.384 | +1.37 |
| Feed t4800.xxxl | 93.57 | 99.111 | +5.54 |
| **Tabs t6000.ax1** | 83.14 | **82.739** | **−0.401** |
| **Tabs t6000.xxxl** | 85.59 | 85.242 | **−0.348** |

App means (this branch): Modal ax1 97.254 worst 77.202; xxxl 97.973 /
84.986. Notes ax1 82.067 / 52.170; xxxl 83.212 / 58.499. Tabs ax1 92.971 /
82.739; xxxl 93.688 / 84.598. NavFlow ax1 96.910 / 94.384; xxxl 97.864 /
96.409. Pager both 99.424 / 99.353. Forms ax1 98.216 / 98.191; xxxl
98.600 / 98.575. Feed ax1 99.420 / 99.313; xxxl 99.349 / 99.111.
TableEditor ax1 97.326 / 96.424; xxxl 87.656 / 70.697.

The two drops are the cancel leftover already in `scoreboard/open.txt`
(`Tabs-t6000-ax1-search-below-bar` / `Tabs-t6000-cancel-inset`): golden
still has the search overlay 0.6 s after cancel (1 view animating); ours
snaps `isActive = false`. Round-15 scored that leftover against 52 pt rows;
80 / 59 pt rows that match t200 / t7000 cost ~0.4. Same number as
`merge-dyntype.md` Tabs `--ax1` worst **82.739**. Not modelled as a rest
rule.

## Gates

- `swift test --filter IOSDevicePixelMetricsTests --filter UIAlertActionModelTests --filter TraitCollectionTests --filter DynamicTypeTests`: 55 tests, 0 failures
- iOS suite `SKIP_CAPTURE=1`: **112/113** (`corner_radius` 99.411)
- Catalyst: **124/124**
- Real-app: **99.137 / 98.535 / 98.548 / 99.469 / 98.639 / 98.133 / 97.516 / 99.511 / 82.170 / 99.760 / 99.689 / 85.393**
- Linux `swift:6.2-noble` `openrender` green (175.05 s)
- No `Package.resolved`

## OPEN

- Modal t5200.ax1 header slack (card 426 vs 384; title y 73 vs 22).
- Notes t200 first header 38 vs 55.5 at SA.top 64 (t4000 search overlay is 38).
- Tabs t6000 cancel leftover (search still up on the golden side).
