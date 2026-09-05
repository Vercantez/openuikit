# iPad conformance (NavFlow, TableEditor, Modal)

`--ipad` on `scripts/conformance_flow.sh` captures on a private **iPad (A16)**
(820×1180 @2x portrait, `SIM_DEVICE_SUFFIX=-conf-ipad`) and openhost renders
with idiom `.pad`, that window size, and window SA `[32, 0, 25, 0]` (the
same plumbing as real-app `*_ipad`). Work dirs:
`/tmp/hc-conformance-{NavFlow,TableEditor,Modal}-ipad`. Phone ConfProbe still
hides the status bar; the iPad plist leaves it visible so SA is 32/25.

Nav bar on this device is still **54** pt (`[0, 32, 820, 54]` inline /
`[0, 32, 820, 106]` large), not 50.

## Baseline (first capture, phone chrome)

| app | worst | mean | notes |
|---|---|---|---|
| NavFlow-ipad | **91.507** (t4800) | 97.857 | t200 blob 304 at the large title |
| TableEditor-ipad | **98.481** | 99.025 | blob **561.8** every capture (title y) |
| Modal-ipad | **5.841** (t7200) | 91.422 | action sheet still a phone card |

Window SA `[32, 0, 25, 0]` both sides. Bar `[0, 32, 820, 106]` at large-title
rest. Golden large-title label abs y **89.5** (= 32 + 54 + 3.5); ours **111.5**.
Table SA top **138** both sides at t200; `collapseDistance = offset.y + 116`
with rest offset −138 → distance **−22**. NavFlow t4800 after pop: ours table
abs y **116** vs golden **138**.

Modal t9200 golden `_UIPopoverView [561, 62, 240, 180]`; ours a full-height
`_UIPageSheetView`. t7200 golden `_UIPopoverView [266, 466, 288, 248]`, **no
Cancel**, dim `[0,0,0,0]`; ours 320×304 card with Cancel and black dim.

## Rule 1 — pad `largeTitleExpandedInset` is 138

Phone 116 = 10 + 54 + 52. Pad **138** = 32 + 54 + 52.

`UINavigationBar.largeTitleExpandedInset` is a computed `var`: `isPad ? 138 :
116`. Guard `UINavigationBar.isPad` (iOS cut AND pad idiom). Phone SE stays
116. Used by collapse distance, `bindContentScrollView` rest offset, snap, and
compact-header `safeAreaInsets.top >=` that inset.

## Rule 2 — pad regular-width popover stays a popover

MEASURED Modal-ipad t9200 / t7200, iPad (A16) 820×1180 @2x / iOS 26.1.

1. `adaptedStyle` returns `.popover` when iOS + pad (phone still `.pageSheet`).
2. `_makeDefaultPresentationController` returns the popover PC when resolved
   style is `.popover`.
3. Frame = `preferredContentSize`; x = `width − size.width − 19` (820 − 240 −
   561 = **19**); y = SA.top + **30** (32 + 30 = 62). Dim alpha 0.
4. Pad action sheet (`preferredStyle == .actionSheet`): width **288**, drop
   cancel, origin = `sourceRect.origin − size/2` (Modal's 1×1 at view mid
   410,590 → `[266, 466, 288, 248]`), dim 0, no alert ring-shadow (unmeasured
   on this chrome). Phone action sheet stays the 320 card.

Phone `testPopoverAdaptsToASheet` still expects `.pageSheet`.

## After (SKIP_CAPTURE=1, same goldens)

**NavFlow-ipad** mean 97.857 → **99.194**, worst 91.507 → **98.461**

| capture | before | after | blob | layout |
|---|---|---|---|---|
| t200 | 98.975 | **99.226** | 304 → 75.5 | 13 → 12 |
| t1200 | 98.461 | 98.461 | 78.5 | 17 → 16 |
| t2100 | 98.975 | **99.226** | 304 → 75.5 | 13 → 12 |
| t3000 | 99.538 | 99.538 | 59.5 | 2 |
| t3900 | 99.687 | 99.687 | 59.5 | 2 |
| t4800 | **91.507** | **99.023** | 63.5 → 75.5 | 23 → 12 |

**TableEditor-ipad** mean 99.025 → **99.399**, worst 98.481 → **98.855**; t200
blob 561.8 → 80.5 (title y closed). Remaining blob 105.2 on edit captures is
the Edit platter, not the large title.

**Modal-ipad** mean 91.422 → **98.205**, worst 5.841 → **84.245**

| capture | before | after |
|---|---|---|
| t200 / t2100 / t4100 / t6100 / t8100 | 99.939 | 99.939 |
| t600 | ~98.6 | 98.825 |
| t1200 | ~98.8 | 98.800 |
| t3200 | ~98.6 | 98.641 |
| t5200 | 99.419 | 99.419 |
| t7200 | **5.841** | **84.245** |
| t9200 | 95.899 | **98.898** |
| t10100 | 99.939 | 99.939 |

t7200 / t9200 frames now match (`[266, 466, 288, 248]` / `[561, 62, 240, 180]`).
t7200 leftover is popover **glass + shadow** (card centre golden 245 vs ours
254; outside halo 238 vs 255) — not fitted; dump labels are the pill box 256
wide vs iOS intrinsic text. t9200 leftover is the More platter (same as root).

Phone SKIP_CAPTURE against `/tmp/hc-conformance-{NavFlow,TableEditor,Modal}`:
scores identical (NavFlow mean 98.995 / worst 97.949; TableEditor 98.784 /
97.578; Modal 99.100 / 97.639).

## OPEN (not guessed)

- PageSheet on pad is full-width, top **42** vs ours **32** (NavFlow Filter
  t1200). Not one of the two largest.
- Inset-grouped inner text x **20** vs **16** (NavFlow labels abs 40 vs 36);
  card x stays 20.
- Pad action-sheet popover glass (`_UIPopoverGlassBackground`, interior 245)
  and drop shadow. Phone alert ring-shadow constants were not re-used.
- Popover corner radius: dump has none; PNG top-left of `[561,62,240,180]` is
  already 252.
- Trailing inset **19** is measured (not 20). Layout tol is 0.5 pt.

## Gates

Catalyst **124/124**; iOS suite **112/113** (known `corner_radius` 99.411);
real-app floors unchanged **99.137 / 98.535 / 98.548 / 99.469 / 98.639 /
98.133 / 97.516 / 99.511 / 82.192 / 99.760 / 99.689 / 84.582**; Linux
`swift:6.2-noble` openrender green; no `Package.resolved`.
