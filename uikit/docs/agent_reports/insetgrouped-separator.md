# Inset-grouped classic-cell separators — 2026-09-07

Base: `f803cd09`; branch: `agent/insetgrouped-separator`.

The reported 393 pt portrait gap was already closed in the drawing path:
`plainSeparatorInsets` is used only by `.plain` in `separatorDrawInsets`.
The inset-grouped branch already draws 16 pt left/right in portrait. The
measurement found a separate compact-height error in the same rule.

## Real iOS measurements

Private iPhone 16 and SE (3rd generation) simulators, suffix
`-insetgrouped-separator`, iOS 26.1 (23B86). Scratch probe and raw captures:
`/tmp/insetgrouped-separator-probe/`. Recipe follows
`scripts/render_sim_scenes.sh` / `scripts/conformance_probe_sim.sh`:
`swiftc -O -target arm64-apple-ios26.0-simulator`, simulator SDK, install and
launch by private UDID, native-scale `drawHierarchy(afterScreenUpdates: true)`,
then walk views and use `view.convert(view.bounds, to: window)`.
The landscape app uses the repo's landscape-only ConfProbe plist. The probe
is a `UITableViewController(style: .insetGrouped)`, three default-style classic
cells, 44 pt rows, no explicit margins or separator insets. Capture at 2 s;
a repeat constructs the table at +0.5 s after orientation settles. Navigation
hosting was also checked. The scratch app is not committed.

All geometry below is in points. Separator measurements are the two interior
row separators; both agree. The section's last cell additionally contains a
full-card-width separator subview, recorded separately below.

| Device / window | Scale | Horizontal table safe area | Card x / width | Interior separator window x / width | Cell separatorInset (T,L,B,R) |
|---|---:|---|---|---|---|
| iPhone 16 portrait, 393×852 | 3 | 0 / 0 | 20 / 353 | **36 / 321** | 0,16,0,16 |
| SE portrait, 375×667 | 2 | 0 / 0 | 16 / 343 | **32 / 311** | 0,16,0,16 |
| iPhone 16 landscape, 852×393 | 3 | 59 / 59 | 79 / 694 | **95 / 662** | 0,16,0,16 |
| SE landscape, 667×375 (additional control) | 2 | 0 / 0 | 20 / 627 | **40 / 587** | 0,20,0,20 |

Cell and content-view margins are [15,16,15,16] for the first three samples,
[15,20,15,20] for the SE landscape control. The labels have the same local
x as the separator. Bare and navigation-hosted iPhone 16 landscape agree.
Landscape dump verifies screen/window 852×393 and compact vertical size class.
Full-card final-cell separator x/width: 20/353, 16/343, 79/694, 20/627,
respectively; final-row visibility is outside this rule.

PIL/numpy confirms pixel transitions on the first interior separator scanline:
iPhone 16 portrait x **108→1071 px**, SE portrait **64→686 px**, iPhone 16
landscape **285→2271 px**, SE landscape **80→1254 px**. The interval is RGB
(232,232,232), with white immediately after its right edge. These are the
frame endpoints multiplied by the native scale, not score-fitted values.

## One-variable probe and rule

Window width alone does **not** explain the samples: 852 pt still uses 16,
while 667 pt uses 20. Do not copy `contentMargin`'s 414 pt threshold.

On the same navigation-hosted iPhone 16 landscape window, a scratch
`UITableView` subclass overrides **only** the left/right components of
`super.safeAreaInsets`, retaining top 78 and bottom 20. Each sample uses a
fresh process. Native scale and window geometry stay fixed.

| Table safe area L / R | Card x / width | Measured separator inset L / R |
|---|---|---|
| 0 / 0 | 20 / 812 | 20 / 20 |
| 0 / 2 | 20 / 810 | 20 / 20 |
| 2 / 0 | 22 / 810 | 20 / 20 |
| 2 / 2 | 22 / 808 | 16 / 16 |
| 4 / 4 | 24 / 804 | 16 / 16 |
| 59 / 59 | 79 / 694 | 16 / 16 |

Bounded rule: iOS phone inset-grouped, compact height: both positive horizontal
safe-area components select 16/16; otherwise retain the system margin on
**both** sides. This fits every captured sample. Regular-height phone, iPad,
Catalyst, and explicit table/cell separator-inset precedence retain their
existing paths. No new width threshold is introduced.

| Sample | Previous L/R | New L/R | Previous → new separator x/width on the measured card | Oracle |
|---|---|---|---|---|
| 393 portrait | 16/16 | 16/16 | 36/321 → 36/321 | 36/321 |
| 375 portrait | 16/16 | 16/16 | 32/311 → 32/311 | 32/311 |
| 852 landscape, safe 59/59 | 20/16 | 16/16 | 99/658 → 95/662 | 95/662 |
| 667 landscape, safe 0/0 | 20/16 | 20/20 | 40/591 → 40/587 | 40/587 |

The frame arithmetic above deliberately uses the measured card geometry to
isolate this separator rule. OpenUIKit's automatic card safe-area positioning
and its landscape content-margin rule are separate unresolved differences;
this change does not claim that the entire 852 pt table matches. The unit test
lays out an actual cell at the measured card frame and checks its separator
view. The existing portrait test now calls `separatorDrawInsets` rather than
the plain-only helper; changing that helper to 16 would regress plain tables.

## Validation

- Named oracle flow (fresh suite goldens reused with `SKIP_CAPTURE=1`):
  tableview_grouped **98.498**, tableview_dark **99.001**, both PASS.
- Fresh iOS suite, then stashed-baseline replay of the same captures:
  **112/113 → 112/113**, **113/113 PNGs byte-identical**. Sole failure:
  corner_radius **99.411** before and after.
- Catalyst **124/124 → 124/124**, **178/178 PNGs byte-identical**.
- Real-app renders **15/15 PNGs byte-identical**, all 12 existing merge floors
  held. The comparator reports the pre-existing missing browser golden;
  its render is included in the byte comparison.
- `swift test --filter 'IOSDevicePixelMetricsTests|TableView'`: **82/82**.
- `swift:6.2-noble` release openrender build: green (**172.88 s**).
- Exact requested operator command, run from the repo root:
  `CHECK_ONLY=1 bash uikit/scripts/agent_merge.sh agent/insetgrouped-separator`.
  **`checks passed (CHECK_ONLY)`**, **zero `REFUSED` lines**. It then exited
  **128 in cleanup**, as documented in the brief. Full output:
  `/tmp/insetgrouped-separator-merge-check.log`.
- The operator check also passed the Foundation-hidden guest build
  (**139 OpenUIKit + 12 OpenCoreGraphics files**, 53 s), test-bundle build,
  Catalyst gate, real-app floors, Linux release (**164.58 s**), Linux
  ConformanceApps target, and Linux OpenUIKitTests target.
- The final amendment records these results only; source/tests are identical
  to local commit `6ddfb47d`, which the checker merged and verified.

## Before / after conformance board

Before = `scoreboard/latest.json`; after = the CHECK_ONLY merged-tree replay
against the same `/tmp/hc-conformance-*` goldens. The current board has 12 app
families (the requested ten-app gate has grown), 84 app/axis capture sets,
**707 rows**. All **487 passing rows remain passing**, 220 remain below their
existing bars. **688 scores unchanged, 19 improved by 0.001–0.005, zero lower**.
Every changed score is an SE landscape row.

| App | Rows | Passing before → after | Lowest before → after | Changed scores |
|---|---:|---|---|---:|
| Feed | 42 | 36 → 36 | 76.344 → 76.344 | 0 |
| Forms | 49 | 14 → 14 | 91.426 → 91.426 | 0 |
| Ledger | 56 | 14 → 14 | 88.187 → 88.188 | 6 |
| Materials | 56 | 50 → 50 | 78.337 → 78.337 | 0 |
| Modal | 84 | 79 → 79 | 91.529 → 91.529 | 0 |
| NavFlow | 42 | 38 → 38 | 96.516 → 96.516 | 3 |
| Notes | 91 | 33 → 33 | 64.718 → 64.719 | 10 |
| Pager | 119 | 119 → 119 | 98.335 → 98.335 | 0 |
| Present | 21 | 16 → 16 | 94.413 → 94.413 | 0 |
| TableEditor | 70 | 52 → 52 | 77.166 → 77.166 | 0 |
| Tabs | 56 | 15 → 15 | 77.867 → 77.867 | 0 |
| TextKit | 21 | 21 → 21 | 99.541 → 99.541 | 0 |

All changed board rows:

| Row | Board before | Replay after | Delta |
|---|---:|---:|---:|
| Ledger:t200.landscape | 90.056 | 90.057 | +0.001 |
| Ledger:t2100.landscape | 88.187 | 88.188 | +0.001 |
| Ledger:t3000.landscape | 90.534 | 90.537 | +0.003 |
| Ledger:t5000.landscape | 90.182 | 90.183 | +0.001 |
| Ledger:t6000.landscape | 91.914 | 91.915 | +0.001 |
| Ledger:t7000.landscape | 89.874 | 89.875 | +0.001 |
| NavFlow:t200.landscape | 98.122 | 98.127 | +0.005 |
| NavFlow:t2100.landscape | 99.562 | 99.567 | +0.005 |
| NavFlow:t4800.landscape | 98.675 | 98.680 | +0.005 |
| Notes:t10000.landscape | 73.003 | 73.005 | +0.002 |
| Notes:t11000.landscape | 76.869 | 76.871 | +0.002 |
| Notes:t12000.landscape | 64.718 | 64.719 | +0.001 |
| Notes:t200.landscape | 86.336 | 86.339 | +0.003 |
| Notes:t3000.landscape | 86.860 | 86.864 | +0.004 |
| Notes:t4000.landscape | 86.094 | 86.097 | +0.003 |
| Notes:t6000.landscape | 73.010 | 73.011 | +0.001 |
| Notes:t7000.landscape | 97.571 | 97.572 | +0.001 |
| Notes:t8000.landscape | 97.554 | 97.556 | +0.002 |
| Notes:t9000.landscape | 97.544 | 97.546 | +0.002 |
