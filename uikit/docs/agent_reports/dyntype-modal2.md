# Dynamic Type modal remainder, re-applied on current main

`origin/agent/dyntype-modal` measured the remaining Dynamic Type / modal
rules (alert pills grow only on `isAccessibilityCategory`, headerless
t7200 sheet fit, ax1/xxxl chrome from window `traitOverrides`, Notes
t4000.xxxl header, Tabs t7000 hide-on-scroll offset). A checked merge of
that branch onto main was **refused**: the merged tree dropped landscape
NavFlow and Notes rows the branch never touched on its own base, because
those rules collided with the compact-height bar and the Notes editor that
landed on main after the branch's base.

This branch re-applies the same measured rules on **current main**
(`5f6bed0e`) with one extra discriminator per collision, so the round-15
landscape / Notes floors hold **and** the ax1/xxxl gains hold.

Goldens are the round-15 captures (read-only `/tmp/hc-conformance-*`,
copied to `/tmp/conformance-*`). Device: iPhone SE 2x / iOS 26.1, plus
iPad (A16) 820×1180 @2x for `--ipad`.
`SKIP_CAPTURE=1 scripts/conformance_flow.sh`. Floor is
`scoreboard/latest.json` at `e97fa7fb` (round-15 board).

## Why the merge dropped (measured on main + re-applied rules)

### 1. Compact-height bar vs inset-grouped first header

The original overlay test was `SA.top > 10+54` (64). Compact-height rest
(NavFlow t200.landscape) is SA.top **78** = 24+54. NavFlow is
`.insetGrouped`, so the first header went 55.5 → 38 and the table shifted.

| scene | round-15 | refused merge | this branch |
|---|---|---|---|
| NavFlow t200.landscape | 96.71 | 81.13 | **96.707** |
| NavFlow t2100.landscape | 97.00 | 81.42 | **97.000** |
| NavFlow t4800.landscape | 96.35 | 80.77 | **96.347** |

Rule: compact 38 only when category is xxxl **or** accessibility **and**
`SA.top > barTop+54`, with `barTop = isCompactHeight ? 24 : 10`. Then
78 > 78 is false. `.large` search (Notes t5000, SA.top 70) keeps 55.5.

### 2. Notes t5000 hide-on-scroll bump vs active search

`setContentOffset` added the hide-on-scroll slot whenever
`hidesSearchBarWhenScrolling`. Notes types into an already-active search.

| scene | round-15 | refused merge | this branch |
|---|---|---|---|
| Notes t5000 | 98.70 | 92.52 | **98.737** |
| Notes t5000.dark | 98.06 | 92.02 | **98.156** |
| Notes t5000.landscape | 86.15 | 75.53 | **86.188** |

Rule: bump requires `!sc.isActive`. Phone Tabs t7000 stays
**260 / 274 / 296**.

### 3. Pad inline search vs phone overlay bump (this re-apply)

Phone Tabs t7000 golden `contentOffset` is **260** (overlay slot). Pad
search is a trailing 240×44 field in the 54 pt bar (`searchOverlayHeight`
already 0). Tabs-ipad t7000 golden is **200** — the script value. Adding
the phone 60 pt bump scored **94.333** against round-15 **98.355**.

Rule: `hideOnScrollContentBump` returns 0 when `UINavigationBar.isPad`.
After: Tabs-ipad t7000 **98.365**.

## Rules (iOS cut; every constant is a named sample)

1. **Alert fonts from the presenting view's traits.** Pills grow only on
   `isAccessibilityCategory` (ax1 63.5; xxxl stays 48).
2. **Headerless action-sheet presented height is the 48-pt stack (304 for
   5 actions)** even when pills are 63.5; `clipsToBounds` on that card.
   Titled alerts still size from scaled content (Modal t5200).
3. **Action-label y is `iOSCeilToPixel((pill−line)/2)`.**
4. **Search field `scaledValue(44)`**; nav overlay extra
   `max(6, 8+field+8−54)`. Pad overlay extra stays 0.
5. **Plain classic row:** `.large` 52, xxxl **59**, ax1 **80**.
6. **value1/default/value2 preferred fonts only when body pointSize ≠ 17**
   (keep construction `systemFont` 17 at `.large`).
7. **Inset-grouped first header compact 38** when xxxl/ax1 overlay
   (`SA.top > barTop+54`). Compact-height rest and `.large` search stay
   55.5. Pad excluded.
8. **Programmatic `setContentOffset` with `hidesSearchBarWhenScrolling`
   adds the overlay slot** on phone, inactive search only. Pad: 0.
9. **Large-title visual zone floors at 54 at xxxl** (bar 108, inset 118).
10. **`iOSBarCapped` includes xxxl** → extraExtraLarge (21 pt Filter /
    inline). Accessibility was already capped.

## Collision rows held; named ax1/xxxl gains held

| scene | round-15 | this branch |
|---|---|---|
| NavFlow t200.landscape | 96.707 | **96.707** |
| NavFlow t2100.landscape | 97.000 | **97.000** |
| NavFlow t4800.landscape | 96.347 | **96.347** |
| Notes t5000 | 98.702 | **98.737** |
| Notes t5000.dark | 98.062 | **98.156** |
| Notes t5000.landscape | 86.153 | **86.188** |
| Modal t5200.ax1 | 66.137 | **77.217** |
| Modal t7200.ax1 | 88.972 | **97.412** |
| Modal t7200.xxxl | 97.328 | **98.252** |
| Modal t5200.xxxl | 81.314 | **84.998** |
| Notes t4000.ax1 | 69.965 | **86.478** |
| Notes t4000.xxxl | 78.908 | **87.604** |
| Notes t5000.ax1 | 79.350 | **89.879** |
| Notes t11000.ax1 | 45.168 | **52.196** |
| Tabs t200.ax1 | 92.596 | **96.541** |
| Tabs t4000.ax1 | 87.803 | **94.207** |
| Tabs t7000.ax1 | 92.058 | **95.973** |
| Tabs t7000.xxxl | 91.849 | **96.169** |
| Feed t4800.xxxl | 93.566 | **99.123** |
| Tabs-ipad t7000 | 98.355 | **98.365** |

## Nine apps × seven axes vs round-15 (`e97fa7fb`)

`SKIP_CAPTURE=1 scripts/conformance_flow.sh /tmp/conformance-<App>[-axis]`.
Notes settings persist in `openhost` UserDefaults (`Notes.sortIndex` /
`Notes.iCloudEnabled`); each Notes axis was replayed after
`defaults delete openhost Notes.*` so t7000/t8000 match a cold start.

| app | axis | n | worst | mean | board worst |
|---|---|---|---|---|---|
| Feed | light | 6 | 99.049 | 99.332 | 99.038 |
| Feed | dark | 6 | 98.699 | 99.052 | 98.699 |
| Feed | rtl | 6 | 99.036 | 99.325 | 99.025 |
| Feed | ax1 | 6 | 99.324 | 99.433 | 99.313 |
| Feed | xxxl | 6 | 99.123 | 99.363 | 93.566 |
| Feed | landscape | 6 | 60.998 | 81.563 | 60.998 |
| Feed | ipad | 6 | 91.797 | 95.836 | 91.797 |
| Forms | light | 7 | 98.914 | 98.952 | 98.895 |
| Forms | dark | 7 | 97.651 | 97.676 | 97.619 |
| Forms | rtl | 7 | 97.807 | 97.854 | 97.793 |
| Forms | ax1 | 7 | 98.212 | 98.237 | 98.191 |
| Forms | xxxl | 7 | 98.610 | 98.635 | 98.505 |
| Forms | landscape | 7 | 95.873 | 99.019 | 95.871 |
| Forms | ipad | 7 | 99.208 | 99.218 | 99.204 |
| Modal | light | 12 | 97.640 | 99.107 | 97.639 |
| Modal | dark | 12 | 97.428 | 98.822 | 97.428 |
| Modal | rtl | 12 | 97.536 | 98.889 | 97.536 |
| Modal | ax1 | 12 | 77.217 | 97.266 | 66.137 |
| Modal | xxxl | 12 | 84.998 | 97.984 | 81.314 |
| Modal | landscape | 12 | 97.653 | 99.086 | 97.653 |
| Modal | ipad | 12 | 91.522 | 98.990 | 91.491 |
| NavFlow | light | 6 | 98.196 | 99.036 | 98.196 |
| NavFlow | dark | 6 | 98.705 | 99.045 | 98.705 |
| NavFlow | rtl | 6 | 97.374 | 98.887 | 97.374 |
| NavFlow | ax1 | 6 | 94.384 | 96.910 | 93.011 |
| NavFlow | xxxl | 6 | 96.409 | 97.864 | 93.471 |
| NavFlow | landscape | 6 | 96.347 | 97.690 | 96.347 |
| NavFlow | ipad | 6 | 99.538 | 99.724 | 99.538 |
| Notes | light | 13 | 67.522 | 84.430 | 67.457 |
| Notes | dark | 13 | 66.161 | 83.280 | 65.926 |
| Notes | rtl | 13 | 67.526 | 84.271 | 67.472 |
| Notes | ax1 | 13 | 52.196 | 82.119 | 45.168 |
| Notes | xxxl | 13 | 58.539 | 83.270 | 55.727 |
| Notes | landscape | 13 | 56.440 | 79.602 | 56.444 |
| Notes | ipad | 13 | 96.081 | 98.167 | 96.086 |
| Pager | light | 17 | 99.759 | 99.873 | 99.745 |
| Pager | dark | 17 | 99.721 | 99.791 | 99.721 |
| Pager | rtl | 17 | 99.759 | 99.873 | 99.745 |
| Pager | ax1 | 17 | 99.367 | 99.442 | 99.353 |
| Pager | xxxl | 17 | 99.367 | 99.442 | 99.353 |
| Pager | landscape | 17 | 99.770 | 99.885 | 99.755 |
| Pager | ipad | 17 | 98.335 | 99.780 | 98.331 |
| Present | light | 3 | 97.836 | 99.016 | 98.032 |
| Present | dark | 3 | 95.279 | 98.066 | 2.996 |
| Present | rtl | 3 | 94.524 | 97.812 | 94.696 |
| Present | ax1 | 3 | 94.287 | 97.540 | 94.451 |
| Present | xxxl | 3 | 94.312 | 97.481 | 94.475 |
| Present | landscape | 3 | 96.978 | 98.730 | 95.170 |
| Present | ipad | 3 | 99.384 | 99.727 | 99.418 |
| TableEditor | light | 8 | 97.716 | 98.922 | 97.716 |
| TableEditor | dark | 8 | 96.722 | 97.752 | 96.722 |
| TableEditor | rtl | 8 | 97.712 | 98.921 | 97.712 |
| TableEditor | ax1 | 8 | 96.424 | 97.326 | 96.424 |
| TableEditor | xxxl | 8 | 70.697 | 87.656 | 70.318 |
| TableEditor | landscape | 8 | 97.920 | 98.833 | 97.888 |
| TableEditor | ipad | 8 | 98.936 | 99.480 | 98.936 |
| Tabs | light | 8 | 84.623 | 94.334 | 84.623 |
| Tabs | dark | 8 | 84.855 | 94.803 | 84.853 |
| Tabs | rtl | 8 | 84.637 | 94.244 | 84.637 |
| Tabs | ax1 | 8 | 82.735 | 92.969 | 83.138 |
| Tabs | xxxl | 8 | 84.598 | 93.686 | 84.598 |
| Tabs | landscape | 8 | 77.912 | 91.745 | 77.912 |
| Tabs | ipad | 8 | 98.114 | 98.832 | 98.109 |

Drops vs the round-15 board ≥ 0.05, all already in `scoreboard/open.txt`
except one 0.055 residual:

| scene | round-15 | after | Δ | where |
|---|---|---|---|---|
| Tabs t6000.ax1 | 83.138 | 82.735 | −0.403 | `Tabs-t6000-ax1-search-below-bar` |
| Tabs t6000.xxxl | 85.590 | 85.238 | −0.352 | same leftover (59/80 pt rows vs 52) |
| Present t1200 | 98.032 | 97.836 | −0.196 | `Present-t1200-safari-remote` (present-axes on main; still ≥ 97.5) |
| Present t1200.rtl/ax1/xxxl | 94.45–94.70 | 94.29–94.52 | −0.16 | same OPEN row |
| Modal t7200.dark | 98.430 | 98.375 | −0.055 | compare residual; pills still 48, card 304 |

Present t1200.dark **2.996 → 95.279** is present-axes already on this
base, not a rule from this branch. Notes landscape worst 56.440 vs board
56.444 is −0.004 (t10000.landscape).

## Gates

- `swift test --filter IOSDevicePixelMetricsTests --filter UIAlertActionModelTests --filter TraitCollectionTests --filter DynamicTypeTests --filter UISearchControllerTests`: **64** tests, 0 failures
- iOS suite `SKIP_CAPTURE=1`: **112/113** (`corner_radius` 99.411)
- Catalyst: **124/124**
- Real-app floors held:
  **99.137 / 98.535 / 98.548 / 99.469 / 98.639 / 98.133 / 97.516 / 99.650 / 82.170 / 99.860 / 99.734 / 85.393**
  (`settings_ipad` 99.511→99.650, `history_ipad` 99.760→99.860,
  `storage_ipad` 99.689→99.734). Ledger PNG is emitted; `/tmp/golden_realapp_ios`
  predates that screen (not in the committed snapshot).
- Linux `swift:6.2-noble` `openrender` green (273.14 s). Host `.build`
  symlinks break a literal `cp -r /src /work`; source tar excluding `.build`
  is the same tree.
- No `Package.resolved`

## OPEN

- Modal t5200.ax1 header slack (card 426 vs 384; title y 73 vs 22).
- Notes t200 first header 38 vs 55.5 at SA.top 64 (t4000 search overlay is 38).
- Notes t11000.ax1 search collapsed on present (golden bar 150).
- Tabs t6000 cancel leftover (search still up on the golden side).
- Present t1200 safari-remote (failed-load body, lock/page-menu, spinner).
