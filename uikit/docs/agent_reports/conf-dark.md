# Dark conformance axis + two iOS-cut palette rules

Every previous conformance capture was light-only. This branch adds a
style axis to the harness and closes the two largest dark misses the
light captures never hit.

## Harness

`scripts/conformance_flow.sh <workdir> <App> --dark` sets
`CONFPROBE_STYLE` / `OPENUIKIT_APP_STYLE=dark`. Both confprobe and
openhost honour a `style` field (env wins so a light `script.json` can
still drive a dark timeline). The window gets
`overrideUserInterfaceStyle = .dark` **before** `makeRoot()`. Capture
names are suffixed `.dark` (`t200.dark`); light names stay `t200`.

The round scores `/tmp/hc-conformance-<App>` and
`/tmp/hc-conformance-<App>-dark` (`scripts/hillclimb.sh`,
`scripts/agent_merge.sh`, `scripts/scoreboard.py` keys `NavFlow.dark`
separately).

All seven apps were captured dark on the iPhone SE 2x / iOS 26.1
(one confprobe process per sheet/alert scene).

## Baseline (dark, before the two rules)

| app | worst | mean | notes |
|---|---|---|---|
| NavFlow | **4.551** (t1200.dark) | 83.338 | rest ~99; large Filter sheet |
| Modal | **4.226** (t9200.dark) | 75.688 | t3200.dark 4.244; t1200.dark 50.577 |
| Forms | **46.559** | 46.893 | every capture ~46.5 |
| TableEditor | 96.470 | 97.530 | not in the two-rule set |
| Feed | 89.434 | 94.420 | selected-card blob after scroll |
| Tabs | 84.907 | 92.655 | same class as light Tabs |
| Pager | 99.723 | 99.789 | already green |

## Rule 1 — dark `systemBackground` sheet fill (iOS cut)

Probe `/tmp/sheetfill_dark` (not in the repo), iPhone SE 2x / iOS 26.1,
one process per case. `Tools/oracle2/colorprobe` now also dumps an
`elevated` sibling (`userInterfaceLevel = .elevated`).

| case | sample |
|---|---|
| `systemBackground` dark | (0, 0, 0) |
| `systemBackground` dark elevated = `secondarySystemBackground` | (28, 28, 30) |
| large pageSheet + explicit `.systemBackground` over black/white/red/gray33 | always **(28, 28, 30)** — elevated, not glass |
| floating medium + `.systemBackground` over black | **(57, 57, 57)** |
| same over gray33 / white / red | (62, 62, 62) / (84, 84, 84) / (116, 48, 48) |

Gray floating samples fit `out = (52/255)·B_dim + 57` with
`B_dim = 0.52·B` (Modal t1200.dark `UIDimmingView` alpha 0.48), i.e.
**α = 203/255**, **T = 57/203**. Red chroma residual is reported, not
fitted (same class as the light red residual).

A second sample disagrees if the presented view left `backgroundColor`
nil: fixture `modal_sheet_grabber_dark`, iPhone 16 3x / iOS 26.1, over
`#333333`, large-sheet interior is unelevated **(0, 0, 0)**; the dimmed
presenting strip is (41, 41, 41) = 0.2 over #333. Remapping that default
fill to (28, 28, 30) dropped the suite scene to 12.191. The elevated
remap therefore applies only when the presented view **set**
`.systemBackground` (`presentedViewSetBackground`); NavFlow / Modal /
the probe do, the fixture does not.

`_UIGlassMaterial` dark mix is gated by `_usesIOSDarkGlass` so bar
platters keep the measured dark flats (19 / 25). No white ring in dark
(Modal t1200.dark interior is a flat 57 cluster).

## Rule 2 — `.grouped` cell fill (iOS cut)

Forms t200.dark, iPhone SE 2x / iOS 26.1: golden cell interiors are
**(28, 28, 30)** = `secondarySystemGroupedBackground`; the port painted
`.systemBackground` (0, 0, 0). NavFlow inset-grouped cells already
matched (the section card paints `secondarySystemGroupedBackground`).
Light both resolve to white, so light captures do not move. Catalyst
keeps `.systemBackground`.

## After

| app | capture | before | after |
|---|---|---|---|
| NavFlow | t1200.dark | 4.551 | **98.705** |
| NavFlow | mean | 83.338 | **99.030** |
| Modal | t9200.dark | 4.226 | **98.593** |
| Modal | t3200.dark | 4.244 | **98.405** |
| Modal | t1200.dark | 50.577 | **97.467** |
| Modal | t600.dark | 55.182 | **97.428** |
| Modal | mean | 75.688 | **98.827** |
| Forms | t200.dark | 46.559 | **97.633** |
| Forms | mean | 46.893 | **97.635** |

TableEditor / Feed / Tabs / Pager dark scores are unchanged (not in
the two-rule set). Light NavFlow / Forms / Modal are byte-score
identical (mean 98.995 / 98.933 / 99.100).

`modal_sheet_grabber_dark` stays **99.766**.

## Per-capture dark scores (SE 2x)

**NavFlow** t200 **99.307**, t1200 **98.705**, t2100 **99.307**, t3000
98.775, t3900 98.792, t4800 99.296. Mean **99.030**.

**Forms** t200 **97.633**, t1200 **97.615**, t2100 97.652, t3000 97.645,
t3900 97.624, t4800 97.619, t5700 97.654. Mean **97.635**.

**Modal** t200 99.648, t600 **97.428**, t1200 **97.467**, t2100 99.648,
t3200 **98.405**, t4100 99.648, t5200 97.707, t6100 99.648, t7200
98.430, t8100 99.648, t9200 **98.593**, t10100 99.649. Mean **98.827**.

**TableEditor** t200 98.675, t900 97.304, t1350 96.687, t1900 97.314,
t2350 **96.470**, t2900 97.298, t3800 97.298, t4800 99.194. Mean 97.530.

**Feed** t200 99.435, t700 99.345, t1800 99.435, t2800 89.435, t3800
**89.434**, t4800 89.434. Mean 94.420.

**Tabs** t200 93.901, t1000 98.799, t2000 **84.907**, t3000 94.139,
t4000 93.630, t5000 93.819, t6000 89.120, t7000 92.928. Mean 92.655.

**Pager** worst t1800 / t4650 **99.723**, mean **99.789**.

## Open (not modelled)

- Dark dim 0.48 (Modal dumps, floating and large over black) vs 0.2
  (`modal_sheet_grabber_dark` over #333). Over black the two are
  indistinguishable in pixels; left alone.
- Large-dark grabber (98, 98, 103) over (28, 28, 30).
- Feed t2800+ selected-card blob; Tabs SF-symbol / 52-vs-53; TableEditor
  mid-flight. Same families as light.
- Dark-glass red residual (116, 48, 48) vs the two-unknown mix.

## Gates

Catalyst **124/124**. iOS suite **112/113** (known `corner_radius`
99.411). Real-app floors held: 99.137 / 98.535 / 98.548 / 99.469 /
98.639 / 98.133 / 97.516 / 99.511 / 99.760 / 99.689 / 82.192 / 84.582.
Linux `swift:6.2-noble` openrender green. No `Package.resolved`.
