# Focus e2e — Blockzilla on Linux, no Mac in the compile loop

mozilla-mobile/focus-ios at **`a2832521c1daa0c23419c73705ae043ed60c9791`**
(the Focus widget-gate pin). The exam is the **Blockzilla app** target, not
the widget. Focus sources were not patched. Stubs and products live in
OpenUIKit / the generated package only.

Worktree `agent/focus-e2e`. Container `uikit-linux` = `swift:6.2-noble`,
Swift **6.2.4**, `aarch64-unknown-linux-gnu`. `/src` is still main; this
worktree was tarred to `/work-focus-e2e`.

Catalyst **124/124**. iOS suite **112/113** (known `corner_radius`).
Real-app floors held. Linux `openhost` and `openrender` both green.
No `Package.resolved`.

## 1. Ingest

```
python3 Tools/ingest/xcodeproj_to_package.py \
  $LADDER_CORPUS/focus-ios/focus-ios/Blockzilla.xcodeproj \
  --target Blockzilla --out /tmp/flow-focus-e2e/ingest --openuikit /work-focus-e2e
```

Exit **0**, `swift=131`, `gaps=0`.

| ingest | no_port | what changed |
|---|---|---|
| before this branch | **21** | Combine was `no_port` (SDK module, not a package product) |
| Combine product | **20** | Combine gone from `no_port`; emitted linux-conditioned `.product` |
| + harness-stub products | **14** | Glean / Intents / IntentsUI / Onboarding / Licenses / DesignSystem |

Remaining **14 no_port** (re-ingest after the products): SnapKit, Fuzi,
Sentry, UIHelpers, FocusAppServices, AppShortcuts, WebKit,
LocalAuthentication, SafariServices, AudioToolbox, CoreHaptics, Network,
PassKit, StoreKit.

`os` is still classified **toolchain** (1 file: `Nimbus/NimbusWrapper.swift`
`import os.log`). That is a lie on Linux corelibs — see wave 1b.

Local BlockzillaPackage (`Focus`, tools 5.5) is **copied** next to the
generated package and **not linked**. UIHelpers / AppShortcuts stay
`no_port` for that reason. UIComponents (2 files) is in-tree and not in
`no_port`.

## 2. Port surfaces added

### Combine as an OpenUIKit product (the closeable gap)

MEASURED Blockzilla ingest: **15 files** `import Combine`
(`AppDelegate.swift:8` is the first after Glean/Sentry). Ladder corpus
20 apps: **17/20** import Combine (1840 files). dep-trial already named
this.

`Sources/Combine/Combine.swift` is `#if os(Linux)` `@_exported import
OpenCombine` plus the three typealiases. Darwin compiles
`enum _OpenUIKitCombineProduct {}` so `swift build --product Combine` is
not an empty module. Ingest emits

```
.product(name: "Combine", package: "OpenUIKit", condition: .when(platforms: [.linux]))
```

so Darwin dependents keep the SDK module. Linux wave 1d:
**0** `no such module 'Combine'`.

### Harness stubs published as products

Wave 1 tried stub targets named `Glean`, `Intents`, `Onboarding`,
`Licenses`, `DesignSystem` in the ingested package. SwiftPM refused:

```
multiple similar targets 'DesignSystem', 'Glean', 'Intents' and 3 others
appear in package 'linux-build' and 'work-focus-e2e'
```

Those names already exist as RealAppProbe Focus/Hackers stub **targets**.
Publishing them as products lets ingested Blockzilla `import Glean` on
Linux without a second target of the same name. Darwin ingest still uses
the linux-only `.product` condition. **These are not Mozilla Glean and not
the SDK Intents framework.** DesignSystem is the Hackers stub (Focus
Settings names no DesignSystem types; full Blockzilla does).

## 3. Linux corelibs census (Focus sources untouched)

`docker exec uikit-linux`, ingested package at
`/tmp/flow-focus-e2e/linux-build`, OpenUIKit at `/work-focus-e2e`.

**Wave 0 (as emitted):** first error
`Blockzilla/AppDelegate.swift:6:8: no such module 'Glean'`. 2 `error:`
lines. Combine product is already a dependency; the compiler never reaches
it.

**Wave 1b** (OpenUIKit harness products + stubs for the 14 `no_port` names
that do not collide): first remaining module error
`Nimbus/NimbusWrapper.swift:5:8: no such module 'os.log'`.

A SwiftPM target named `"os.log"` compiles as module **`os_log`**
(`[3/5] Compiling os_log oslog.swift`). `import os.log` still fails.
You cannot stub Apple's `os.log` overlay with a SwiftPM target name.

**Wave 1d** (generated-package `exclude` of `NimbusWrapper.swift` only —
not a Focus-source patch — plus a `UIComponents` stub): **1073** `error:`
lines, **0** remaining `no such module`. Ranked by diagnostic (ladder
reach in parentheses):

| rank | what | count | other ladder apps (of 20) |
|---|---|---|---|
| 1 | SnapKit `.snp` / `Constraint` | 128 | 2 (firefox-ios, focus-ios) |
| 2 | `#selector` / ObjC interop disabled | 65 + 82 | native-ELF blocker 1 (REAL_APP_TEST) |
| 3 | GleanMetrics / `Glean.handleCustomUrl` (harness stub vs real Glean) | 92 | 2 (firefox-ios, focus-ios) |
| 4 | WebKit `WKWebView` / `WKNavigation` / … | 75 | 16 |
| 5 | DesignSystem `UIColor.primaryText` / `.accent` / `UIFont.body16` (Hackers stub, not BlockzillaPackage) | 73 + 32 | local package, not rewritten |
| 6 | UIHelpers `animateHidden` / `install` / `orientation` | 21 + 5 + 4 | local BlockzillaPackage |
| 7 | `OnboardingEventsHandling.route` / `.send` (empty protocol stub) | 19 | local package |
| 8 | `URLRequest` (corelibs split onto FoundationNetworking) | 10 | 19 (dep-trial Networking) |
| 9 | `SentrySDK` | 5 | 6 |
| 10 | `OSAtomicCompareAndSwap32Barrier` / `OSSpinLock*` (libkern) | 5 + 2 | Darwin-only atomics in vendored Deferred |
| 11 | `SFContentBlockerManager` | 2 | SafariServices 16 apps |
| 12 | `LAContext` | 3 | LocalAuthentication 11 |
| 13 | `SKStoreReviewController` | 1 | StoreKit 14 |
| 14 | `INVoiceShortcutCenter` / `INShortcut` | 2 + 2 | Intents 12 |
| 15 | `PKPass` | 1 | PassKit 7 |
| 16 | `IPv4Address` / `IPv6Address` | 1 + 1 | Network 10 |
| 17 | `NimbusWrapper` (the excluded `os.log` file) | 11 | Focus-only |

Hottest files: `BrowserViewController.swift` 167, `URLBar.swift` 126,
`WebViewController.swift` 89, `OverlayView.swift` 67, `AppDelegate.swift` 41.

Nothing in that list is a UIKit/Foundation/SwiftUI surface a Darwin golden
already covers except Combine (closed) and the FoundationNetworking
`URLRequest` split (dep-trial; adding `import FoundationNetworking` would
patch Focus sources, which this exam forbids).

## 4. Screens that did render

### Browser home (`openhost --app focus`)

Unmodified `HomeViewController.swift` from a2832521 except the same
`#selector` / `@objc private` → `Selector.named` + `func rotated()`
adaptation Settings already uses (`scripts/realapp_probe_sim.sh`
restores the Darwin oracle text). UIHelpers
`UIApplication+Orientation.swift` and `UIViewController+Child.swift`
are byte copies of BlockzillaPackage.

Window iPhone 16 **393×852**. Script
`Sources/RealAppProbe/Focus/script.json`, capture **0.20**.

Mac quartz and Linux (`SDL_VIDEODRIVER=dummy`,
`OPENUIKIT_FONT_DIR=/agent/fonts`, `OPENUIKIT_BACKEND=quartz`) produced
**byte-identical** `focus_app.t200.png`
(`sha256:64771e0041bffbac3e8251db157aaa3e9e4f9d52a37ae884cb87698096e0b2fd`).
Copy: `docs/agent_reports/focus-e2e/focus_home.t200.png`.

Wordmark PNGs in `fixtures/realapp/assets/` are sha256-identical to
`Blockzilla/Assets.xcassets/img_focus_wordmark.imageset`.

`openrender realapp` emits `realapp_focus_home_light` (13th screen).
No iOS-simulator golden yet (`compare_realapp.py`: `MISSING golden=False
out=True`). Operator captures afterwards.

MEASURED dump, iPhone 16 points, scale 3:

| view | frame | note |
|---|---|---|
| wordmark `UIImageView` | `[44, 394, 305, 65.333]` | `centerY + textLogoOffset`; offset = `-10 - 44/2` = **−32** (UIConstants.layout). Correct. |
| `HomeViewToolbar` | `[0, 75.333, 393, 777]` | Upstream SnapKit is the same constraint set (`height` 44 + `bottom` to safeArea). On iOS that is a ~78 pt bar at the bottom. |
| tip band | `[0, −67, 393, 148]` | `tipView.bottom = toolbar.top + 6` with toolbar.top = 75.3. Label therefore paints at the **top** of the window. |
| tracker `UILabel` | `[126.333, 67, 140.667, 14.333]` in the tip band | text `"0 trackers blocked so far"` (TipManager with 0 blocked). |

No URL bar: `BrowserViewController` + SnapKit + WKWebView are listed
blockers. The home overlay is the first screen without those.

OPEN: the toolbar stretch is UIStackView not honouring the 44 pt height
together with top+bottom pins (REAL_APP_TEST blocker 12). Not modelled;
not a parameter search against a missing golden.

### Settings (existing)

`realapp_focus_settings_light` **82.170** held (blob still 481.7).

## 5. Gates

| gate | result |
|---|---|
| Catalyst `compare.py` | **124/124** |
| iOS suite `SKIP_CAPTURE=1` | **112/113** (`corner_radius` 99.411) |
| real-app floors | **99.137 / 98.535 / 98.548 / 99.469 / 98.639 / 98.133 / 97.516 / 99.511 / 82.170 / 99.760 / 99.689 / 85.393** |
| ingest tests | **34** OK |
| Linux `docker exec` `openhost --app focus` | 1 capture, sha256 = Mac |
| `docker run --rm -v "$PWD":/src:ro swift:6.2-noble` `openrender` | complete (178.87 s) |

## 6. Open questions

- **`import os.log`.** Ingest classifies `os` as toolchain. Linux has no
  `os` / `os.log`. SwiftPM cannot ship a module literally named `os.log`.
  `origin/agent/combine-product` also publishes `os`; that would still not
  satisfy `import os.log`. Not added here (merge collision; would not close
  the Focus file).
- **WebKit / SnapKit / Sentry ObjC.** No Darwin golden for a port. Ranked
  above.
- **Local BlockzillaPackage** (Onboarding 21 files, UIHelpers, DesignSystem
  colours) is copied and not rewritten onto OpenUIKit products. The
  published Onboarding/DesignSystem products are the RealAppProbe stubs.
- **Home toolbar vs simulator.** Operator golden will show where the 148 pt
  tip band sits on iOS 26.1. Ours is a UIStackView resolution, not a new
  layout constant.
- Guest `queue_box.sh arm64 verify`: `TBD_CHECK_OK`, `difftest rc=0`,
  `build_full rc=0`, `GATE_B_PASS` at both `399c3d76` and `739cc5f4`.
  `GUEST_REALAPP_RC=133` on
  `OPENUIKIT_IOS_INK_MISS: I|system-semibold|18|light|F0.0|83` after
  **12** PNGs. The 2x iOS table has **no** system-semibold|18 (3x has 48
  keys including that S). 739cc5f4 puts home last so the miss is the 13th
  screen and cannot drop Hackers. Harvesting the 2x mask is a follow-up;
  copying it from the 3x table is not a measurement.

## 7. What was not done

- No Focus-source patches.
- No WebKit, SnapKit, or Sentry ports.
- No `Package.resolved`.
- No pin / `env/` / `scripts/vendor_pins.sh` edits.
