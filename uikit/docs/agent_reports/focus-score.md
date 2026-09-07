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
| `realapp_focus_home_light` | missing | 1179×2556 | — | CANNOT | No carried iOS golden; guest capture exists, but no comparison is valid. |
| `realapp_focus_settings_light` | 1179×2556 | 1179×2556 | 82.491 | FAIL | `[290,733,63,19]`; layout constant / missing view — golden has the Done/table accessory structure (151-view anchor subtree), ours has 110 views. |
| `realapp_hackers_feed_light` | 1179×2556 | 1179×2556 | 86.311 | FAIL | `[130.7,402.0,17.7,17.3]`; layout constant / missing view — measured row heights are 129.333/109 versus golden 127.333/107, with a missing-content region `[287.3,70.0,23.0,23.0]`. |
| `realapp_history_light` | 1179×2556 | 1179×2556 | 99.137 | PASS | `[125.7,700.3,7.7,0.3]`; residual blob only. |
| `realapp_history_light_ipad` | 1640×2360 | 1640×2360 | 99.860 | PASS | none (`blob=0.0`). |
| `realapp_ledger_light` | missing | 1179×2556 | — | CANNOT | No carried iOS golden; guest capture exists, but no comparison is valid. |
| `realapp_settings_dark` | 1179×2556 | 1179×2556 | 98.548 | PASS | `[28.7,560.3,6.0,0.3]`; residual blob only. |
| `realapp_settings_light` | 1179×2556 | 1179×2556 | 98.535 | PASS | `[28.7,560.3,6.0,0.3]`; residual blob only. |
| `realapp_settings_light_ax1` | 1179×2556 | 1179×2556 | 96.407 | FAIL | `[119.3,695.7,18.3,22.3]`; missing glyphs/fonts — the measured 3x ink miss is blank in the temporary diagnostic render. |
| `realapp_settings_light_ipad` | 1640×2360 | 1640×2360 | 99.650 | PASS | none (`blob=0.0`). |
| `realapp_settings_light_xs` | 1179×2556 | 1179×2556 | 98.477 | PASS | `[95.0,701.3,9.0,11.0]`; small missing-content/glyph region, below the bar. |
| `realapp_settings_light_xxxl` | 1179×2556 | 1179×2556 | 97.654 | PASS | `[106.0,699.0,13.3,16.0]`; small missing-content/glyph region, below the bar. |
| `realapp_storage_light` | 1179×2556 | 1179×2556 | 99.268 | PASS | `[21.0,297.7,13.7,11.3]`; small missing-content region. |
| `realapp_storage_light_ipad` | 1640×2360 | 1640×2360 | 99.734 | PASS | `[113.5,203.5,5.0,0.5]`; residual blob only. |
| `realapp_focus_browser_light` | 750×1334 | 750×1334 | 96.694 | FAIL | `[44.0,327.0,62.0,49.0]`; layout constant / missing view — `HomeViewToolbar` is `[0,122,375,525]` versus golden `[0,603,375,44]`; wordmark height is 65.5 versus 61. |

Scored total: **13**. Pass: **9**. Fail: **4**. CANNOT: **2**. No screen
without both a rendered guest image and an iOS golden was scored.

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
regions. The home and Ledger rows are CANNOT solely because their iOS golden
files are absent.

