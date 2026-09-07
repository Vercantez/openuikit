# Focus fidelity score — Linux Mach-O guest vs iOS 26.1

Date: 2026-09-07. Branch: `agent/focus-score2`. Source baseline:
`4a25e111` (`origin/main`). Focus source: `a2832521c1daa0c23419c73705ae043ed60c9791`.

## Result

This is the first current-main Focus score after the drag/drop guest bridge
landed. The guest built successfully with the production full builder and
rendered all 15 registered screens under `machorun`:

```text
FOCUS_GUEST_BUILT modules=SnapKit,WebKit,DesignSystem,Licenses,UIHelpers,UIComponents,Widget,AppShortcuts,Onboarding,Blockzilla
[render_full] realapp rendered=15 failed=0
```

Phone output is 1179×2556 at 3x; iPad output is 1640×2360 at 2x; the Focus
browser output is 750×1334 at 2x on the measured SE geometry (375×667 points,
safe-area top 20). Comparison uses the existing `compare_pixels` path through
`Tools/compare/compare_realapp.py`, `PIXEL_TOL=6`, the existing structural
diagnostics, and `golden_premultiplied=False` for the straight-alpha iOS
golden. The existing real-app scoreboard bar is 97.5.

The phone guest had one measured 3x ink-table miss:
`I3|system-regular|13|light|F0.0|71`. The first unmodified diagnostic render
trapped on that exact key. For the complete census, the temporary scoring copy
enabled the existing miss-log fallback, which leaves that glyph blank rather
than fabricating an outline. This is recorded as a missing-glyph cause below;
no OpenUIKit source or ink table was changed in this branch.

| Screen | Golden | Ours | Score | Pass/fail | Top diff region / measured cause |
|---|---:|---:|---:|---|---|
| `realapp_focus_home_light` | 1179×2556 | 1179×2556 | 99.325 | PASS | `[187.7,701.7,5.7,8.7]`; one blank glyph in the 12 pt `0 trackers blocked so far` label — the Mac scale-3 `OPENUIKIT_INK_LOG` of this screen names four `I3\|system-regular\|12\|light\|F0.0\|{48,98,100,107}` misses (`0 b d k`), left blank by the miss-log fallback. Wordmark `[44,394,305,65.333]` matches the golden exactly (1 view, 0 problems). Golden captured 2026-09-07 (addendum below). |
| `realapp_focus_settings_light` | 1179×2556 | 1179×2556 | 82.491 | FAIL | `[290,733,63,19]`; layout constant / missing view — golden has the Done/table accessory structure (151-view anchor subtree), ours has 110 views. |
| `realapp_hackers_feed_light` | 1179×2556 | 1179×2556 | 86.311 | FAIL | `[130.7,402.0,17.7,17.3]`; layout constant / missing view — measured row heights are 129.333/109 versus golden 127.333/107, with a missing-content region `[287.3,70.0,23.0,23.0]`. |
| `realapp_history_light` | 1179×2556 | 1179×2556 | 99.137 | PASS | `[125.7,700.3,7.7,0.3]`; residual blob only. |
| `realapp_history_light_ipad` | 1640×2360 | 1640×2360 | 99.860 | PASS | none (`blob=0.0`). |
| `realapp_ledger_light` | 1179×2556 | 1179×2556 | 87.915 | FAIL | `[41.7,279.7,36.3,15.0]` (the `Payroll` title). Three measured causes. (1) Missing glyphs/fonts: the Mac scale-3 `OPENUIKIT_INK_LOG` of this screen names **28** `I3\|…` misses — 15 `system-semibold\|17` (e.g. `C` 67, `R` 82, `k` 107, `·` 183), 6 `system-regular\|13` (`0 4 5 6 8 ·`), 4 `system-regular\|17` (`$ , . 0`), 3 `system-medium\|17` (`R p r`) — blank under the miss-log fallback, so most subtitles, amounts and the header are empty in ours. (2) Missing view: ours has **5** `LedgerTableCell` (y 168.3…536.3) versus the golden's **6**; the sixth `Loopback FX` row (golden cell `[20,628.3,353,92]`) is absent — `LedgerStore.loopbackItem()` returns nil when the guest's 127.0.0.1 GET fails. (3) Layout constant: title/subtitle labels sit at x **40** in ours versus **36** in the golden (4 pt); amount labels, row y's, nav title, Export and Regex all match within 0.5 pt. Golden captured 2026-09-07 (addendum below). |
| `realapp_settings_dark` | 1179×2556 | 1179×2556 | 98.548 | PASS | `[28.7,560.3,6.0,0.3]`; residual blob only. |
| `realapp_settings_light` | 1179×2556 | 1179×2556 | 98.535 | PASS | `[28.7,560.3,6.0,0.3]`; residual blob only. |
| `realapp_settings_light_ax1` | 1179×2556 | 1179×2556 | 96.407 | FAIL | `[119.3,695.7,18.3,22.3]`; missing glyphs/fonts — the measured 3x ink miss is blank in the temporary diagnostic render. |
| `realapp_settings_light_ipad` | 1640×2360 | 1640×2360 | 99.650 | PASS | none (`blob=0.0`). |
| `realapp_settings_light_xs` | 1179×2556 | 1179×2556 | 98.477 | PASS | `[95.0,701.3,9.0,11.0]`; small missing-content/glyph region, below the bar. |
| `realapp_settings_light_xxxl` | 1179×2556 | 1179×2556 | 97.654 | PASS | `[106.0,699.0,13.3,16.0]`; small missing-content/glyph region, below the bar. |
| `realapp_storage_light` | 1179×2556 | 1179×2556 | 99.268 | PASS | `[21.0,297.7,13.7,11.3]`; small missing-content region. |
| `realapp_storage_light_ipad` | 1640×2360 | 1640×2360 | 99.734 | PASS | `[113.5,203.5,5.0,0.5]`; residual blob only. |
| `realapp_focus_browser_light` | 750×1334 | 750×1334 | 96.694 | FAIL | `[44.0,327.0,62.0,49.0]`; layout constant / missing view — `HomeViewToolbar` is `[0,122,375,525]` versus golden `[0,603,375,44]`; wordmark height is 65.5 versus 61. |

Scored total: **15** (was 13 before the 2026-09-07 addendum). Pass: **10**.
Fail: **5**. CANNOT: **0**. No screen without both a rendered guest image
and an iOS golden was scored.

## Evidence and cause classes

- `/tmp/focus-score-compare.txt` contains the official comparator output for
  the 13 available goldens and the structural diagnostics.
- `/tmp/focus-score-browser.txt` contains the direct existing
  `compare.compare_pixels` call for the browser at scale 2; the normal real-app
  wrapper reaches the browser pixel result, then its layout walk encounters the
  known null-coordinate serialization and raises `TypeError`.
- `/tmp/focus-score-render-fatal.log` records the unmodified first-render
  evidence: `OPENUIKIT_IOS_INK_MISS: I3|system-regular|13|light|F0.0|71`.
- `/tmp/focus-score-render.log` records the complete diagnostic run:
  `realapp rendered=15 failed=0`.
- `/tmp/focus-score-final/<screen>.layout.json` and
  `/tmp/focus-score-diff/<screen>.diff.png` are the per-screen layout and
  pixel evidence; the goldens remain under
  `goldens/ios/golden_realapp_ios/` and were not edited.

The four failures have measured causes, not guesses: Focus settings is a
layout/structural mismatch; Hackers feed is a row-layout plus missing-content
mismatch; Settings AX1 is the explicit missing 3x ink key; and Focus browser
has a toolbar/wordmark layout mismatch. No timing or color/material cause was
assigned because the layout/diff evidence already identifies the dominant
regions. The home and Ledger rows were CANNOT solely because their iOS golden
files were absent; the addendum below carries those goldens and scores them.

## Addendum 2026-09-07 — home and Ledger goldens (`agent/focus-goldens-home-ledger`)

Source baseline `f0e0382f` (`origin/main`, this report's branch merged).

**Capture.** Both goldens come from the same recipe as every other phone
row in `goldens/ios/golden_realapp_ios/`: `scripts/realapp_probe_sim.sh`
(RealAppProbe compiled against Apple UIKit) with `REALAPP_DEVICE=iPhone-16`
on a private `OpenUIKit-Chrome-iPhone-16-focus-goldens-home-ledger`
simulator, iOS 26.1 (23B86), light, `UICTContentSizeCategoryL`, 393×852 @3
→ 1179×2556, `drawHierarchy` + the `dumpLayout` shape. Proof the family is
identical: the six phone screens the run also produced
(`realapp_settings_light`, `_history_light`, `_storage_light`,
`_focus_settings_light`, `_hackers_feed_light`, `_settings_light_ax1`) are
**byte-identical** to the carried goldens. Rest: a second fresh launch on
the same device produced byte-identical PNGs and layout dumps for both new
screens. The probe script needed three Darwin-only fixes to compile again
(`-wmo` for the seven-file Onboarding stub, the whole DesignSystem stub
directory for `UIFont.footnote12` / `UIColor.secondaryText`, and the
`OpenUIKitRuntime.imageSearchPaths` guard in FocusScreens.swift, which real
UIKit does not have); no vendored app source changed. The 14 new files
(2 PNG + 2 layout dumps + 10 `UIImageView` sub-images) are registered in
`goldens/ios/manifest.json` with sha256 like the rest of the set;
`FORCE=1 scripts/goldens_restore.sh golden_realapp_ios` verifies 85 files.

Measured golden frames (window-space, points):

| screen | view | frame |
|---|---|---|
| home | wordmark `UIImageView` (image 292.333×65.333 @3) | `[44, 394, 305, 65.333]` |
| home | `0 trackers blocked so far` (`.SFUI-Regular` 12) | `[126.333, 699, 140.667, 14.333]` |
| ledger | `LedgerTableCell` × 6 | y 168.333, 260.333, 352.333, 444.333, 536.333, 628.333; `[20, y, 353, 92]` |
| ledger | title / subtitle x | 36 (`.SFUI-Semibold` 17 / `.SFUI-Regular` 13) |
| ledger | header label `2026-09-04T10:30:00Z · json ok` | `[36, 141.667, 264.667, 20.333]` |
| ledger | `Regex` placeholder (`.SFUI-Medium` 17) | `[74.667, 790, 48.333, 20.333]` |

**Guest render.** Same route as above: a fresh `/work-focus-goldens`
snapshot of this branch in `uikit-linux`, `full/scripts/build_full.sh`
(`FOCUS_GUEST_BUILT`, both success stamps), `machorun render_full realapp`
with the verifier's environment, all 15 screens `rendered=15 failed=0`. Two
container-only changes were needed to reproduce this report's 3x phone
output, exactly as this report's own temporary scoring copy did, and neither
is committed: the full driver never sets `realAppScale` (unmodified main
renders phones at 786×1704 @2, which the 3x goldens cannot score), so the
copy sets it to 3; and the first 3x run trapped on the same
`OPENUIKIT_IOS_INK_MISS: I3|system-regular|13|light|F0.0|71` (in
`realapp_storage_light`), so the copy enables `GlyphInkTable.logMisses`
(blank glyph instead of a trap). Scorer: `Tools/compare/compare_realapp.py
--scale 3 --golden-straight-alpha` (identical without the flag; both
goldens are opaque), `PIXEL_TOL=6`, bar 97.5.

| screen | score | result |
|---|---:|---|
| `realapp_focus_home_light` | **99.325** | PASS (Mac iOS-cut route for reference: 99.286) |
| `realapp_ledger_light` | **87.915** | FAIL (Mac iOS-cut route, outline-font fallback and a working loopback row: 97.096) |

The Ledger causes are in the table row above: 28 unharvested 3x ink keys,
the missing `Loopback FX` row (5 cells vs 6), and a 4 pt title inset. No
OpenUIKit rule or ink table changed on this branch.

## Required merge proof

Command run from the monorepo root:

```text
CHECK_ONLY=1 bash uikit/scripts/agent_merge.sh agent/focus-score2
```

The checker printed no `REFUSED` line. Its final output was:

```text
Build of product 'openrender' complete! (161.30s)
checks passed (CHECK_ONLY)
```
