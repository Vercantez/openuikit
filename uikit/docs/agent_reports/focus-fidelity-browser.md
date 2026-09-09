# Focus browser toolbar layout — agent/focus-fidelity-browser

Branch `agent/focus-fidelity-browser`, base `f0e0382f` (origin/main).
Screen `realapp_focus_browser_light`, golden iPhone SE (3rd gen) 2x, iOS 26.1
(focus-golden.md). Focus source unchanged (`a2832521`).

Before: **96.694 FAIL** (focus-score.md). After: **99.288 PASS** (bar 97.5) on
the same guest route, same scorer call, same golden — scored 2026-09-09 by the
operator after harvesting the one 2x ink key the first re-render trapped on
(`system-regular|15|light|F0.25|44`, agent/ink2x-comma): `machorun render_full
realapp` at the SE geometry, 15 screens rendered, 0 ink misses; mae 1.104,
largest remaining blob 22.5 px² at `[57.0, 43.5, 7.5, 10.5]` (2x pixels).
The SE geometry is now registered for the screen (agent/focus-browser-se), so
the score needs no scoring-time patch.

## Measurement

focus-score.md named the cause: `HomeViewToolbar` at `[0,122,375,525]`
(parent-relative) against the golden's `[0,603,375,44]`, and a 65.5 pt
wordmark against 61. Both were reproduced from the two layout dumps
(`/tmp/focus-score-final/realapp_focus_browser_light.layout.json` versus
`goldens/ios/golden_realapp_ios/realapp_focus_browser_light.layout.json`):

| view | golden (abs) | guest before (abs) |
|---|---|---|
| HomeViewToolbar | `[0, 623, 375, 44]` | `[0, 142, 375, 525]` |
| its UIStackView | `[10, 623, 355, 44]` | `[10, 142, 355, 525]` |
| tip band (`tipView`) | `[0, 481, 375, 148]` | `[0, 0, 375, 148]` |
| wordmark UIImageView | `[44, 311.5, 287, 61]` | `[44, 311.5, 287, 65.5]` |

The app's constraints (`HomeViewToolbar.swift`, SnapKit): the stack is
`top = toolbar.top`, `height = 44`, `bottom = toolbar.safeAreaLayoutGuide`;
the toolbar itself is `bottom = view.bottom` plus safe-area leading/trailing;
the tip band is `bottom = toolbar.top + 6`, `height = 148`. Nothing else
sizes the toolbar, so its height must come out as `44 + safe bottom inset`.

### Probe (the smallest scene that reproduces it)

`probe_toolbar_guide_bottom{0,34}`: a 375x667 root with a forced safe area
`[20, 0, B, 0]`, a constraint-sized "toolbar" (`bottom = root.bottom`,
safe-area leading/trailing) holding a "stack" (`top = toolbar.top`,
`left/right ±10`, `height 44`, `bottom = toolbar.safeAreaLayoutGuide.bottom`),
a "band" (`bottom = toolbar.top + 6`, `height 148`) and a 61 pt "logo"
(`top = centerY - 32`, `leading/trailing ±44`). Captured with
`SIM_DEVICE=2x scripts/render_sim_scenes.sh` on the private
`OpenUIKit-2x-focus-fidelity-browser` simulator (iPhone SE 3rd gen, iOS
26.1) and rendered with `openrender render` before and after the fix:

| view | oracle B=0 | ours before | ours after | oracle B=34 | ours before | ours after |
|---|---|---|---|---|---|---|
| toolbar | `[0,623,375,44]` | `[0,0,375,667]` | `[0,623,375,44]` | `[0,589,375,78]` | `[0,0,375,667]` | `[0,589,375,78]` |
| stack | `[10,0,355,44]` | `[10,0,355,667]` | `[10,0,355,44]` | `[10,0,355,44]` | `[10,0,355,633]` | `[10,0,355,44]` |
| band | `[0,481,375,148]` | `[0,-142,375,148]` | `[0,481,375,148]` | `[0,447,375,148]` | `[0,-142,375,148]` | `[0,447,375,148]` |
| logo | `[44,301.5,287,61]` | same | same | `[44,301.5,287,61]` | same | same |

The oracle's toolbar height is `44 + B` in both captures; every frame in
both probes matches after the fix.

## Cause

`LayoutEngine.solve` anchored a SYSTEM layout guide (`safeAreaLayoutGuide`,
`layoutMarginsGuide`, …) to a rect frozen from its owner's CURRENT bounds
(`UILayoutGuide.systemFrame()`), as four required constants. A
constraint-sized owner that has never been laid out has zero bounds, so
its safe-area guide was zero-height at `owner.top`; `stack.bottom =
guide.bottom` then collided with `stack.top = owner.top; stack.height =
44`, the height constraint was dropped as the late-comer and the toolbar's
top was left under-determined — the solver parked it where the tip band
lands at the window's top (`y = 0`, band bottom 148, toolbar top 142 abs =
122 parent-relative). The next pass re-froze the guide to the stretched
bounds, so the wrong answer was a fixed point. focus-e2e.md had recorded
the same stretch on the home screen as "OPEN … REAL_APP_TEST blocker 12".

## Fix

`Sources/OpenUIKit/AutoLayout/LayoutEngine.swift`: a system guide is now
four edge relations to its owner's solver variables — `left = owner.left +
inset.left`, `width = owner.width - inset.left - inset.right`, same
vertically — with the measured insets (`safeAreaInsets`, `layoutMargins`).
The scroll view's `frameLayoutGuide` and the readable guide's capped 920 pt
band keep their bounds-derived rect, expressed as insets of that same rect,
so their anchoring is unchanged. For a frame-based or already-converged
owner the two formulations are numerically identical, which is why no
existing scene moves.

Test: `SafeAreaPropagationTests.testGuideFollowsConstraintSizedOwner`
(both probe insets). Before the fix: 6 assertion failures, owner
`(0,0,375,667)`; after: passes.

### Wordmark (second measured cause)

`fixtures/realapp/assets/img_focus_wordmark{,@2x,@3x}.png` were the
imageset's DARK-appearance files (`luminosity: dark` in
`img_focus_wordmark.imageset/Contents.json`; 585x131 at 2x, so 65.5 pt)
copied under the imageset's name. The golden is light and draws the
unspecified-appearance `ic_logo_wordmark_light_horizontal@2x.png`
(585x122, 61 pt): the golden crop's ink minimum is rgb (32,18,57), that
file's ink mean (83,46,123), the dark file's (169,135,201). The loose
fixture now holds the unspecified-appearance files for both imagesets
(focus and klar). This is a harness fixture, not app source; a dark Focus
screen would need the appearance-aware catalog index instead (open).

## After

Guest route (`uikit-linux`, production `full/scripts/build_full.sh` on the
branch tree, `FOCUS_GUEST_BUILT`, exit 0; `machorun render_full realapp`):

- Production verifier `scripts/linux_guest_realapp_verify.sh`: 15 screens,
  0 ink misses, **13/14** pinned PNGs byte-identical; the one that changed
  is `realapp_focus_home_light` (the same toolbar), so its pin and the
  committed 393x852 browser fixture were regenerated from this run
  (`4bb886c6…`, `ee1d6f2a…`) and the verifier then printed
  `REAL-APP SCREEN VERIFIED ON LINUX` (14/14).
- Score at the golden's geometry (temporary container-only harness patch,
  exactly focus-score.md's: browser Screen at 375x667, nativeScale 2, safe
  top 20; `compare.compare_pixels(..., golden_premultiplied=False,
  scale=2)`):

```text
scoring rebuild: FOCUS_GUEST_BUILT (exit 0)
machorun render_full realapp: Trace/breakpoint trap
OpenUIKit/GlyphInkTable.swift:214: Fatal error: OPENUIKIT_IOS_INK_MISS: I|system-regular|15|light|F0.25|44
  — no outline font; harvest (family|size|appearance|phase|scalar) into Resources/glyph_ink_ios.json
```

Darwin route (iPhone 16 3x): HomeViewToolbar `[0,715,393,78]`
(`44 + 34`), wordmark intrinsic `292.333 x 61`.

## Gates

- Catalyst: **124/124**.
- Fresh iOS suite: **112/113**, only the existing `corner_radius` 99.411.
- Twelve real-app floors unchanged: 99.137 / 98.535 / 98.548 / 99.469 /
  98.639 / 98.133 / 97.516 / 99.650 / 82.170 / 99.860 / 99.734 / 85.393.
- Auto Layout unit tests (`Layout|Constraint|SafeArea|Guide|StackView|
  Anchor|Cassowary|Margin`): 190/190.
- `CHECK_ONLY=1 bash uikit/scripts/agent_merge.sh agent/focus-fidelity-browser`:

```text
run 1 (before merging main): MERGE CONFLICT with main
  — uikit/fixtures/realapp/linux-existing14.sha256: main (8c1ac462) re-pinned
  the Focus settings row while this branch re-pins the home row; resolved by
  union in 39ca516c (both rows measured on their own trees; the merged tree
  was not re-rendered on the guest).
run 2 (after the merge): see the final commit of this branch.
```

## Open

- The registered browser screen still renders at 393x852 @2x (the pinned
  Linux fixture); the SE geometry the golden needs remains a scoring-time
  patch, as in focus-score.md. Registering it moves the fixture pin and
  the verifier's `bounds` assertion and was left to the operator.
- The after-score at the golden's geometry is blocked by ONE 2x ink key,
  `I|system-regular|15|light|F0.25|44` (a 15 pt regular comma at phase
  0.25): with the toolbar now at the bottom the tip label lands on a new
  sub-pixel phase that `glyph_ink_ios.json` does not carry. Harvest it
  with `Tools/oracle2/inkprobe` on the SE (as focus-guest-linux.md did for
  three keys) and re-run the scoring render; no rebuild was attempted after
  the wrap-up instruction. The production 393x852 render has 0 misses.
- A dark-appearance Focus capture would need `img_focus_wordmark` served
  from an appearance-aware catalog index rather than the loose fixture.
