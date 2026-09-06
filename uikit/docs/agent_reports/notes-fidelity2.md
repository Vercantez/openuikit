# Notes fidelity 2 — harvested trash, compact-height chrome, dyntype disclosure

Second pass on the Notes conformance app after main `e6f52739`
(`docs/agent_reports/notes-fidelity.md` + `merge-notes.md`). Round-20 board
(`scoreboard/latest.md`) still had 59 Notes rows below 97.5; lowest
t11000.ax1 **55.12**, then the t12000 family (~64–73) and the Dynamic Type /
landscape variants of t6000–t11000.

Goldens: `/tmp/hc-conformance-Notes[-axis]/golden` (read-only). Replay:
`SKIP_CAPTURE=1 scripts/conformance_flow.sh /tmp/conformance-Notes[-axis]
Notes [--axis]`. Device: iPhone SE 2x / iOS 26.1, window 375×667 (landscape
667×375), status bar hidden. Nothing in `Sources/ConformanceApps/Notes/`
was changed.

## What the dumps said

### `.trash` bar button (closed at `.large`)

Default / dark / landscape golden `_UIModernBarButton` `UIImageView` is
**24×28** at `[324.817, 16.817]` (landscape `[594.817, 30.817]`). Harvested
`trash|17|medium|large|F0` in `symbol_ink_ios.json` is 48×56 px = 24×28.
Golden crop at px **(650, 34)** correlates **0.999999** with that mask. The
port was drawing `_BarSymbol.trash` 19×20.667; blob 111 at
`[326.5, 19, 21, 23]`.

ax1 / xxxl golden image is **30×35** (21 pt bar-capped body). No
`21|medium|large` harvest. Stamping 17 pt at those sizes dropped
t12000.ax1 / t12000.xxxl ~0.04, so those categories keep `_BarSymbol`.

Platter stays **44** (not 24+2×11=46). Image local origin **(10, 7)** in the
44 platter (centred y would be 8).

### Compact-height nav item side margin 38

Three samples, all 38:

| scene | platter | 667 − width − x |
|---|---|---|
| Notes t200.landscape | `[585, 24, 44, 44]` | 38 |
| NavFlow t200.landscape Filter | `[557.5, 24, 71.5, 44]` | 38 |
| TableEditor t200.landscape Edit | `[566.5, 24, 62.5, 44]` | 38 |

Portrait SE stays 16 (375−44−315=16). Guard: `UINavigationBar.isCompactHeight`.

### Inset-grouped header inner: 16 regular / 20 compact-height

Notes t200.landscape All Notes abs.x **40** = card 20 + 20. A hardcoded
inner 16 left it at 36. Portrait SE 16+16=32 is unchanged.

iPhone 16 portrait is a third sample that does **not** follow window
`iOSMargin` (20): `realapp_focus_settings_light` "General"
`_UITableViewHeaderFooterViewLabel` abs.x **36** = card 20 + **16**. Using
`iOSMargin` on every iOS chrome dropped Focus Settings 82.170→82.158.
Inner is 16 in regular height even when the card is 20; compact-height uses
20. Pad still uses `iOSPadInsetGroupedInnerInset` 20.

### Disclosure size at Dynamic Type

| category | accessory | contentView | labels |
|---|---|---|---|
| `.large` | 10.5×14 | 316.5 | 292.5 |
| xxxl | **14×19.5** | 313 | — |
| ax1 | **20×28.5** | 307 = 343−16−20 | 283 |

Vector polyline / stroke scaled into the measured box. Other categories
unmeasured → stay 10.5×14. t200.ax1 layout issues 24→3.

## Rules (iOS cut)

1. **`UIBarButtonItem.SystemItem.trash` stamps harvested SF `trash` at
   17/medium/large** unless `isAccessibilityCategory || extraExtraExtraLarge`.
   `sizeThatFits` returns the 44 platter (not content+inset). Image y = 7
   for the 24×28 stamp.
2. **`_UIBarMetrics.compactHeightSideMargin = 38`.** `itemSideMargin` is 38
   when `UINavigationBar.isCompactHeight`, else 16. Navigation bar
   leading / trailing / title layout uses it.
3. **Inset-grouped header inner is 20 only in compact height.** Regular-height
   phone stays 16 (Focus Settings 36). Pad 20. Catalyst 16.
4. **`UITableViewCell.disclosureSize`** is 20×28.5 at `.accessibilityLarge`,
   14×19.5 at `.extraExtraExtraLarge`, else 10.5×14.

## After (`SKIP_CAPTURE=1` vs round-20 goldens)

t200 blob 111.2→**34.8**. t7000.landscape **97.226→97.503** (crossed 97.5).
61 Notes rows were below 97.5; 60 remain. Default mean 90.251→**90.268**.
Worst is still t11000.ax1 **55.444** (alert-card slack).

Tiny Notes drops, recorded not reverted: t12000.ax1 **68.535→68.496**
(−0.039), t12000.xxxl **70.520→70.476** (−0.044) — skipped 17 pt stamp at
those sizes; leftover is mid-delete + 30×35 trash. t4000.landscape
**86.007→85.987** (−0.020) — blob still compact tab-bar Settings, not nav
trash. t5000.ax1 −0.003 / t11000.xxxl −0.004 / Notes-ipad:t200 −0.003 are
noise.

### Every Notes row, every axis

| scene | r20 | after | Δ |
|---|---|---|---|
| t200 | 89.433 | 89.470 | +0.037 |
| t1200 | 96.919 | 96.919 | 0 |
| t2100 | 95.382 | 95.382 | 0 |
| t3000 | 89.117 | 89.157 | +0.040 |
| t4000 | 89.111 | 89.111 | 0 |
| t5000 | 98.818 | 98.818 | 0 |
| t6000 | 82.159 | 82.196 | +0.037 |
| t7000 | 99.192 | 99.192 | 0 |
| t8000 | 99.174 | 99.174 | 0 |
| t9000 | 99.164 | 99.164 | 0 |
| t10000 | 82.161 | 82.199 | +0.038 |
| t11000 | 80.615 | 80.649 | +0.034 |
| t12000 | 72.015 | 72.052 | +0.037 |
| t200.dark | 87.204 | **87.263** | +0.059 |
| t1200.dark | 96.971 | 96.971 | 0 |
| t2100.dark | 93.919 | 93.919 | 0 |
| t3000.dark | 87.271 | **87.325** | +0.054 |
| t4000.dark | 86.884 | 86.884 | 0 |
| t5000.dark | 98.221 | 98.221 | 0 |
| t6000.dark | 82.885 | **82.944** | +0.059 |
| t7000.dark | 97.856 | 97.856 | 0 |
| t8000.dark | 97.854 | 97.854 | 0 |
| t9000.dark | 97.836 | 97.836 | 0 |
| t10000.dark | 82.992 | **83.054** | +0.062 |
| t11000.dark | 87.839 | 87.873 | +0.034 |
| t12000.dark | 73.229 | **73.288** | +0.059 |
| t200.rtl | 81.716 | 81.753 | +0.037 |
| t1200.rtl | 96.987 | 96.987 | 0 |
| t2100.rtl | 95.452 | 95.452 | 0 |
| t3000.rtl | 81.720 | 81.758 | +0.038 |
| t4000.rtl | 85.734 | 85.734 | 0 |
| t5000.rtl | 97.860 | 97.860 | 0 |
| t6000.rtl | 79.986 | 80.024 | +0.038 |
| t7000.rtl | 99.194 | 99.194 | 0 |
| t8000.rtl | 99.176 | 99.176 | 0 |
| t9000.rtl | 99.166 | 99.166 | 0 |
| t10000.rtl | 79.968 | 80.006 | +0.038 |
| t11000.rtl | 78.736 | 78.770 | +0.034 |
| t12000.rtl | 71.987 | 72.025 | +0.038 |
| t200.ax1 | 88.713 | **89.025** | +0.312 |
| t1200.ax1 | 96.931 | 96.931 | 0 |
| t2100.ax1 | 95.393 | 95.393 | 0 |
| t3000.ax1 | 88.427 | **88.739** | +0.312 |
| t4000.ax1 | 86.571 | **86.883** | +0.312 |
| t5000.ax1 | 96.167 | 96.164 | −0.003 |
| t6000.ax1 | 77.364 | **77.622** | +0.258 |
| t7000.ax1 | 99.190 | 99.190 | 0 |
| t8000.ax1 | 99.172 | 99.172 | 0 |
| t9000.ax1 | 99.161 | 99.161 | 0 |
| t10000.ax1 | 77.373 | **77.630** | +0.257 |
| t11000.ax1 | 55.123 | **55.444** | +0.321 |
| t12000.ax1 | 68.535 | 68.496 | −0.039 |
| t200.xxxl | 89.433 | 89.441 | +0.008 |
| t1200.xxxl | 96.931 | 96.931 | 0 |
| t2100.xxxl | 95.393 | 95.393 | 0 |
| t3000.xxxl | 89.070 | 89.078 | +0.008 |
| t4000.xxxl | 88.549 | 88.558 | +0.009 |
| t5000.xxxl | 97.921 | 97.923 | +0.002 |
| t6000.xxxl | 80.533 | 80.539 | +0.006 |
| t7000.xxxl | 99.190 | 99.190 | 0 |
| t8000.xxxl | 99.172 | 99.172 | 0 |
| t9000.xxxl | 99.161 | 99.161 | 0 |
| t10000.xxxl | 80.538 | 80.544 | +0.006 |
| t11000.xxxl | 71.181 | 71.177 | −0.004 |
| t12000.xxxl | 70.520 | 70.476 | −0.044 |
| t200.landscape | 85.946 | **86.232** | +0.286 |
| t1200.landscape | 94.790 | **95.527** | +0.737 |
| t2100.landscape | 94.193 | **95.129** | +0.936 |
| t3000.landscape | 85.680 | **86.692** | +1.012 |
| t4000.landscape | 86.007 | 85.987 | −0.020 |
| t5000.landscape | 86.723 | **86.911** | +0.188 |
| t6000.landscape | 71.915 | **72.190** | +0.275 |
| t7000.landscape | 97.226 | **97.503** | +0.277 |
| t8000.landscape | 97.206 | **97.483** | +0.277 |
| t9000.landscape | 97.196 | **97.473** | +0.277 |
| t10000.landscape | 71.991 | **72.933** | +0.942 |
| t11000.landscape | 76.578 | **76.821** | +0.243 |
| t12000.landscape | 64.582 | **64.649** | +0.067 |
| Notes-ipad:t200 | 97.729 | 97.726 | −0.003 |
| Notes-ipad:t1200 | 98.056 | 98.056 | 0 |
| Notes-ipad:t2100 | 95.493 | 95.493 | 0 |
| Notes-ipad:t3000 | 97.731 | 97.731 | 0 |
| Notes-ipad:t4000 | 99.463 | 99.463 | 0 |
| Notes-ipad:t5000 | 99.660 | 99.660 | 0 |
| Notes-ipad:t6000 | 97.618 | 97.618 | 0 |
| Notes-ipad:t7000 | 98.661 | 98.661 | 0 |
| Notes-ipad:t8000 | 98.799 | 98.799 | 0 |
| Notes-ipad:t9000 | 98.796 | 98.796 | 0 |
| Notes-ipad:t10000 | 96.110 | 96.110 | 0 |
| Notes-ipad:t11000 | 97.567 | 97.567 | 0 |
| Notes-ipad:t12000 | 97.751 | 97.751 | 0 |

## Other apps (must not drop)

Replay vs `/tmp/hc-conformance-*` into `/tmp/canary-*` / `/tmp/conformance-*`:

| app axis | result |
|---|---|
| NavFlow landscape | t200 **96.464→96.900**, t2100 **97.000→98.339**, t4800 **96.054→97.156** |
| NavFlow ax1 | t200/t2100/t4800 **+0.37** |
| NavFlow xxxl | t200/t2100/t4800 **+0.57** |
| NavFlow default | hold |
| Ledger landscape | t200 **89.218→90.054**, t2100 **86.563→88.296** |
| Ledger ax1 | t200 **+0.89**, t3000 **94.604→95.638**, t6000.ax1 **69.214→69.458** |
| Ledger xxxl | t200 **+0.97**, t3000 **+1.13** |
| TableEditor landscape | all **+0.06–0.27** (t200 **99.373→99.640**) |
| Tabs landscape / ax1 | hold (byte-level) |
| TableEditor ax1 | hold |
| Forms default | hold |

## OPEN

- **Notes-trash-ax1-xxxl** — 30×35 needs a 21|medium|large harvest. `.large`
  24×28 is closed.
- **Notes-t12000-delete-animation** — golden header 38 mid-flight vs rest 55.5.
- **Keyboard** — t2100 family; t2100.landscape **95.129** after the 38 pt
  inset (was 94.193). Still `Forms-keyboard-letter-caps`.
- **t11000.ax1 55.444** — `_UIAlertControllerPhoneTVMacView` 369 vs 280.5
  (`Modal-t5200-ax1-header-slack`).
- t4000.landscape −0.02 leftover is compact tab title packing, not nav trash.

Closed vs prior open.txt: Notes-trash-bar-symbol at `.large`; landscape All
Notes x 40; compact-height nav inset 38; ax1/xxxl cell content 307 / 313.

## Gates

Catalyst **124/124**. iOS suite **112/113** (`corner_radius` 99.411). Real-app
floors held: **99.137 / 98.535 / 98.548 / 99.469 / 98.639 / 98.133 / 97.516 /
99.65 / 82.170 / 99.860 / 99.734 / 85.393** (ledger / focus-home goldens
absent from `/tmp/golden_realapp_ios`). Linux `swift:6.2-noble` openrender
green (180.51 s). No `Package.resolved`.
