# Notes iOS 26.1 fidelity (Linux-written app vs the oracle)

Round 13 captured the Notes conformance app on real iOS 26.1 for the first
time. Every list frame sat at 65–78 with a ~216 pt² blob and 40–70 layout
issues (`scoreboard/latest.md` at b4fb0a02; work dirs
`/tmp/hc-conformance-Notes`, `-dark`, `-rtl`). The app was not edited.

Device: iPhone SE 2x / iOS 26.1, window SA `[0,0,0,0]`. Probe
`/tmp/notes-header-probe` (`SIM_DEVICE=2x`). Goldens reused with
`SKIP_CAPTURE=1`.

The list is **custom Auto Layout cells** (`NotesTableCell`), not classic
subtitle. App-chosen row height **92**, `accessoryType = .disclosureIndicator`.

## Before

| capture | pixels | blob | layout |
|---|---|---|---|
| t200 | 77.652 | 215.8 | 43 |
| t3000 | 77.635 | 215.8 | 44 |
| t4000 | 77.699 | 216.0 | 46 |
| t5000 | 98.660 | 215.5 | 9 |
| t6000 | 67.420 | 216.0 | 40 |
| t7000 | 99.072 | 215.5 | 27 |
| t1200 | 96.793 | 215.5 | 7 |
| t200.dark | 75.587 | 216.0 | 43 |
| t200.rtl | 74.910 | 217.5 | 63 |

Light mean **84.314** / worst **67.419**. Dark mean **83.137** / worst **65.882**.
RTL mean **81.306** / worst **65.220**. Largest blob `[134.0, 597.5, 23.0, 21.0]`
= missing Notes tab `note.text` (nil; harvest union was 73 names).

Ours t200: first header **55.5** vs golden **38**; custom titles **284.5** vs
**292.5**; tab `UIImageView` **0×0**.

## Measurements

### Compact first header (notesheaderprobe + Notes t200 / t5000 / t7000)

| scenario | header | notes |
|---|---|---|
| inset_tab_8_search | **38** | contentSize 771.5; search height 0; SA.bottom 83 |
| inset_nav_8_search | 55.5 | no tab; search stays 60 pt visible |
| inset_tab_8_nosearch | 55.5 | tab alone is not enough |
| inset_nav_8_large | 38 | existing large-title rule |
| inset_tab_2_settings | 55.5 | 2×44 rows, no search |
| Notes t5000 (1 filtered row) | 55.5 | contentSize 185 < visible |

Rule (iOS cut, grouped / insetGrouped, first section): compact **38** when
the hosting VC has a `searchController` **and** a `tabBarController` **and**
`(fullHeader + rowHeights + 17.5 untitled footer) > (bounds.height − SA.top −
SA.bottom)`. Existing large-title (`SA.top ≥ 116`) and after-untitled-footer
rules unchanged.

### Disclosure eats content-view trailing 8 (notesheaderprobe + Notes t200)

Cell `layoutMargins` `[15, 16, 15, 16]`; content view `[15, 16, 15, 8]` when
`accessoryType = .disclosureIndicator`. Title 292.5 = 316.5 − 16 − 8. RTL:
contentView x=26.5, title x=8 (physical left = 8); abs title **50.5**.
`accessoryType != .none` is the same eat as `accessoryView != nil` (storage
SwitchCell). None-accessory keeps 16/16.

### Segmented Auto Layout min 34 (notesheaderprobe + Notes t7000)

Notes settings pins height **33**. Golden still lays out **34**, origin kept,
so the sort row is `[16, 5.5, 311, 34]` in the 44 pt cell. Unconstrained is
also 34. iOS cut: Auto Layout (`translatesAutoresizingMaskIntoConstraints ==
false`) controls with `0 < height < 34` expand bounds height to 34 and keep
origin. Fixture `control_segmented` explicit 32 pt frames stay 32 (Catalyst
and iOS suite **98.631** held).

This is an iOS default vs the app's 33 pt constraint — the app was not
changed.

### `note.text` harvest (`/tmp/note-text-harvest`)

`symbolinkprobe` with names file `note.text` only, SE 2x + iPhone 16 3x /
iOS 26.1. Merge only the four stored configs (aliases still map `default` /
`body|medium|large`). 18/medium/large F0 2x: pw=58 ph=50, w=46 h=42, ox=6
oy=4 — **29×25 pt**, same box as calendar. Notes t200 golden tab icon
`[131, 595.5, 29, 25]`. Tables: 73→**74** names, 584→**592** / 292→**296**
entries.

### RTL tab items (Notes t200.rtl)

After the icon existed, RTL blob grew 217.5→338: we drew `note.text` on the
left while golden Notes is on the right. Golden Notes label abs.x **216**,
Settings **124**; LTR Notes is ~130. Same reverse as `UISegmentedControl`:
visual index `n−1−i` inside the centered platter. Phone layout only (pad
floating bar is title-packed, not measured here).

## After (`SKIP_CAPTURE=1`)

### Light (`/tmp/hc-conformance-Notes`)

| capture | before | after | blob | layout |
|---|---|---|---|---|
| t200 | 77.652 | **89.019** | 215.8→111.2 | 43→3 |
| t3000 | 77.635 | **88.916** | 215.8→78.2 | 44→4 |
| t4000 | 77.699 | **88.901** | 216.0→38.2 | 46→6 |
| t5000 | 98.660 | **98.784** | 215.5→38.2 | 9→6 |
| t6000 | 67.420 | 65.933 | 216.0→111.2 | 40→25 |
| t7000 | 99.072 | **99.191** | 215.5→15.8 | 27→26 |
| t8000 | 99.054 | **99.173** | 215.5→15.8 | 3→2 |
| t9000 | 99.031 | **99.150** | 215.5→15.8 | 3→2 |
| t1200 | 96.793 | 96.914 | 215.5→129.5 | 7 |
| t2100 | 97.416 | 97.538 | 215.5→129.5 | 7 |
| t10000 | 67.419 | 65.932 | 216.0→79.2 | 51→36 |
| t11000 | 68.275 | 66.641 | 179.5→73.5 | 44→29 |
| t12000 | 69.953 | 67.728 | 216.2→111.2 | 40→25 |

Mean **84.314 → 86.448**. t200 frames now match: header 38, titles 292.5 at
x=32, tab icon 29×25. t5000 stayed compact-off (1 row). t6000/t10000 pixel
drop is the known 60 pt cancel leftover **plus** the 17.5 header the leftover
search un-compacts on the golden side (ours snaps to rest 38). Same class as
`Tabs-t6000-cancel-inset`.

### Dark (`/tmp/hc-conformance-Notes-dark`)

t200.dark **75.587 → 86.887** (blob 216.0→64.0, layout 43→3). Mean
**83.137 → 85.580**. t7000.dark 97.710→97.815.

### RTL (`/tmp/hc-conformance-Notes-rtl`)

t200.rtl **74.910 → 81.516** (blob 217.5→111.2, layout 63→3). t7000.rtl
**96.011 → 99.192**. Mean **81.306 → 84.808**. Worst **65.220 → 65.880**
(cancel-inset frames).

### iPad (`/tmp/hc-conformance-Notes-ipad`)

Pad visible height does not compact the first header (8×92 + 55.5 fits).
Disclosure trailing 8 still applies. t200 **94.32 → 97.649** (layout 29→4);
t4000 96.054→99.384; t10000 93.978→96.188. Mean **96.412 → 98.157**. t200
blob still 197.8 (pad floating title-only tab bar, not the phone `note.text`
hole).

## Leftover / OPEN

- **Nav search platter** — t200 largest blob `[326.5, 19.0, 21.0, 23.0]`.
  Golden `PlatterView [315, 0, 44, 44]` / inner image 24×28; ours icon
  19×20.667 in the same 44×44 slot. Layout issues 3 (dump extras: Search
  placeholder in the 0-height bar, glass-copy tab labels). Glass, not a
  new layout rule.
- **Cancel-search 60 pt** — Notes t6000/t10000/t11000/t12000. Already
  `scoreboard/open.txt` `Tabs-t6000-cancel-inset`. Golden still animating;
  header stays 55.5 while search is 60 pt visible.
- **t1200 glass back vs `‹`** — same OPEN as NavFlow t3000.rtl.
- **contentSize 771.5 vs 38+736+17.5=791.5** (−20). Probe matches 771.5; no
  footer rule invented.

App-chosen fonts (semibold 17 / regular 15 / regular 13) matched the dump.
App-chosen row height 92 matched. DateFormatter U+202F timestamps matched.

## Gates

Catalyst **124/124**. iOS suite **112/113** (`corner_radius` 99.411). Real-app
**99.137 / 98.535 / 98.548 / 99.469 / 98.639 / 98.133 / 97.516 / 99.511 /
82.170 / 99.760 / 99.689 / 85.393**. Linux `swift:6.2-noble` openrender green.
No `Package.resolved`. Notes sources untouched.
