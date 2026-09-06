# Focus browser iOS oracle — agent/focus-golden

Firefox Focus **a2832521c1daa0c23419c73705ae043ed60c9791**, built by
`xcodebuild` from its **Blockzilla.xcodeproj**, scheme **Focus**, configuration
**FocusDebug**, against **Apple UIKit**, on iPhone SE (3rd generation),
iOS **26.1 (23B86)**. Screen: `realapp_focus_browser_light`.

Before: **no browser simulator golden; score N/A**. After: a native
**750×1334 PNG at 2x**, a **164-view** layout dump, and build/source/capture
provenance. No OpenUIKit rendering rule changed. This is the oracle rung,
not a claim that the guest already matches it.

## Reproduce and locate

From `uikit/`:

```sh
SIM_DEVICE_SUFFIX=-focus-golden scripts/focus_probe_sim.sh \
  /tmp/golden-focus-browser-ios \
  ~/openuikit/scratch/ladder-corpus/focus-ios /tmp/focus-golden-oracle
```

Registration: `fixtures/realapp/focus-browser-oracle.json`. Golden PNG,
layout, and full provenance:
`goldens/ios/golden_realapp_ios/realapp_focus_browser_light.*`.
The probe writes only a temporary project copy, simulator data, and its
chosen output directory. The corpus is never patched. It checks the app
and real dependency pins, tracked-source cleanliness, all **227** existing
Swift/ObjC/header files against the copy, and all **129 upstream Swift
files** in the actual Blockzilla compiler input list.

The compiler receives 134 Swift files: 129 upstream files, two generated
stand-in files, one capture harness, and Xcode's two generated files
(EraseIntent and asset symbols). One additional ObjC constructor starts
the harness; upstream `@UIApplicationMain` remains intact.

## Build boundary

`CODE_SIGNING_ALLOWED=NO ARCHS=arm64 ONLY_ACTIVE_ARCH=YES`; iOS SDK 26.1,
deployment target 15.0, Swift language 5.0, `FOCUS DEBUG`, `-Onone`.
The app and its extension targets still build from the original project.
Real SnapKit **e74fe2a978d1216c3602b129447c7301573cc2d8**, real Fuzi
**f08c8323da21e985f3772610753bcfc652c2103f**, and upstream BlockzillaPackage
use Apple frameworks. Package resolution is redirected to local pins.

Only Glean, Sentry, and FocusAppServices/Nimbus use the launch harness's
stand-ins, copied byte-for-byte. No Glean telemetry, Sentry crash reporting,
or Nimbus service fetch is needed to measure this offline home screen.
Nimbus's feature defaults come from the upstream manifest. The missing
`Generated/Metrics.swift` imports the launch Glean surface;
`Generated/AppNimbus.swift` aliases its Nimbus surface and supplies the
same `String: Error` conformance as the launch harness. Without that
conformance the real compiler fails at NimbusWrapper.swift:74.

In the temporary project, the app's four shell phases (wordmark copy,
empty SwiftLint phase, Glean generation, Nimbus generation) are excluded.
The existing wordmark assets remain unchanged, and the two network-backed
generation phases are replaced by the documented generated files.
Only BlockzillaPackage's package-resolution declaration changes; none of
its Swift source files changes. No Package.resolved is committed.

Full resolved Blockzilla build settings are carried in provenance,
with machine/work paths replaced by `$HOME`/`$ORACLE_WORK`. Its SHA-256
uses sorted compact JSON:
`4afeaa9d30a8b6fc087664ce326b207e601f55114b6418e5f4814abb99754c39`. The project digest, dependency/stand-in hashes,
harness hashes, and all 129 compiled source hashes are also carried.

## Exact launch state and rest measurement

1. Fresh-install `org.mozilla.ios.Focus` on private
   `OpenUIKit-FocusOracle-focus-golden`; appearance light. Set the four
   keyboard tutorial flags used by `conformance_probe_sim.sh` on this
   device only.
2. Before upstream UIApplicationMain runs, seed exactly
   `FocusBrowserLaunch.prepareReturningUserDefaults`: JSON-encoded
   `Set<ToolTipRoute>` containing `.onboarding(.v1)`, `.onboarding(.v2)`,
   `.searchBar`, `.menu` under `OnboardingConstants.shownTips`, plus
   `onboardingDidAppear=true` and `showOldOnboarding=true`.
3. Real AppDelegate creates BrowserViewController. Apple UIKit automatically
   focuses the URL field, presenting its keyboard. This was confirmed with
   the framebuffer: an app-window-only screenshot would otherwise hide the
   keyboard while retaining its shifted home layout.
4. At `didBecomeActive +1s`, send `.touchUpInside` to the upstream control
   identified by `URLBar.cancelButton`. Its own `cancelPressed` sets
   `isEditing=false`. This extra real-app interaction produces the requested
   keyboard-dismissed home (shield, URL bar, hamburger, wordmark).
5. Capture the app window at +3, +4, +5 seconds using extended-range
   `drawHierarchy(afterScreenUpdates: true)`, normalize to straight-alpha
   sRGB using the existing confprobe algorithm, then dump layout **after**
   each PNG. Select +5 only after all three samples pass rest checks.

The three samples have **0 changed pixel channels**, maximum pixel delta
**0**, and identical model/presentation geometry across all **164 views**.
A second fresh-install launch also produced **0 changed pixel channels**
against the earlier accepted capture. There are **0 focused text fields** and **0 visible moving views**.
The single presentation-opacity difference is
`_UIRefreshControlModernReplicatorView`, inside both a hidden web container
and a hidden UIRefreshControl, with presentation opacity 0. No animations
are disabled to obtain this result. This follows keyboard-fidelity's
model-layer comparison convention rather than comparing UIView.frame to
the layer's presentation frame.

The window's safe area is **[20, 0, 0, 0]**. System status text is in a
separate window and is excluded by the existing realapp app-window capture
convention; the 20-point inset is retained. A framebuffer screenshot is
kept under the temporary work directory to confirm no keyboard or overlay
is omitted.

| measured view | absolute frame, points |
|---|---|
| UIWindow | `[0, 0, 375, 667]` |
| URLBar | `[0, 20, 375, 56]` |
| Home wordmark UIImageView | `[44, 311.5, 287, 61]` |

## Scoring boundary

At capture time, origin/main is `71c8fc1e` and
`origin/agent/focus-guest-linux` is not published. Main's Linux guest does
not emit the browser row. **Golden only; Linux browser score N/A.**
The existing Darwin browser render uses 393×852 at 3x and is not a
same-device comparison to this SE golden. Never resize either image to
manufacture a score. The sibling guest needs the measured **375×667,
2x, top safe area 20** and the keyboard-dismissed state above.

Once that Linux artifact exists, use the realapp scorer:

```sh
python3 Tools/compare/compare_realapp.py \
  --golden goldens/ios/golden_realapp_ios --out /path/to/linux/render \
  --scale 2 --golden-straight-alpha
```

The new straight-alpha flag leaves the scorer's existing default unchanged.
This golden is opaque, so either alpha interpretation gives identical
pixels. The URLBar anchor was already registered in the scorer.

## Gates

- Catalyst: **124/124**.
- FocusLaunchCoreTests: **12/12**, 0 failures.
- Linux `swift:6.2-noble` release openrender: **green**, 315.97 s.
- Existing twelve real-app floors, unchanged: **99.137 / 98.535 / 98.548 /
  99.469 / 98.639 / 98.133 / 97.516 / 99.650 / 82.170 / 99.860 /
  99.734 / 85.393**. The three pre-existing unscored rows remain separate
  from this floor comparison.
- Fresh iOS suite: **112/113**; only the existing `corner_radius` miss
  (**99.411**). Stashing every change and replaying the fresh goldens also
  yields **112/113**, with the same sole miss; no scene dropped.

Artifact validation: the realapp scorer self-comparison reports **100.0**,
MAE **0**, blob **0**, and **58 URLBar-subtree views / 0 problems**. This
is solely an artifact/scorer check, not a Linux fidelity score.
