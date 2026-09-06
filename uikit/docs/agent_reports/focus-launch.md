# Focus launch — Blockzilla on route (b)

mozilla-mobile/focus-ios at **`a2832521c1daa0c23419c73705ae043ed60c9791`**.
Focus sources were not patched. The Blockzilla copy under
`Sources/Blockzilla/` strips `@UIApplicationMain` (`ADAPTED(library-target)`)
so the module is a library; harness `OpenUIKitLaunch.swift` calls
`UIApplicationMain` from `FocusBrowserLaunch.makeRoot()`.

Worktree `agent/focus-launch`. Route **(b)** = Apple toolchain (Darwin
SwiftPM). `#selector` is not a wall here. Route (a) Linux corelibs remains
the focus-e2e census (**1073** errors / 129 sources).

Catalyst **124/124**. iOS suite **112/113** (known `corner_radius`).
Real-app 3x floors held. Linux `swift:6.2-noble` `openrender` green.
No `Package.resolved`.

## 1. Diagnostic waves (denominator = 129 present Blockzilla sources)

Ingest of `Blockzilla.xcodeproj` `--target Blockzilla` still exit 0 /
131 Swift in the generated package. The Darwin module compiles **129**
upstream files plus two harness files.

| wave | unique diagnostics | what changed |
|---|---|---|
| SnapKit vendored (pin `e74fe2a`, 36 files, `Debugging.swift` excluded) | **0** `.snp` | real SnapKit against OpenUIKit |
| first Darwin `swift build --target Blockzilla` | **139 unique / 30 files** (1999 raw) | missing UIKit / WebKit / Glean / Fuzi / frameworks |
| shims + UIKit surfaces (`FocusLaunchCompat`, Glean, Fuzi XMLParser, WebKit blank `WKWebView`) | **15** | leftover names |
| remaining two | **2 → 0** | StoreKit module-alias; generated `AppNimbus` / `EraseIntent` stand-ins |

`swift build --target Blockzilla` and `swift build --product openrender`
are **0 errors** on Darwin.

## 2. What compiled (route b)

| piece | where | notes |
|---|---|---|
| SnapKit 5.7.0 `e74fe2a` | `Sources/SnapKit/` | Darwin-only product (associated objects need ObjC) |
| WebKit | `Sources/WebKit/` from `full/webkit` | blank `WKWebView` + navigation state; `@objc dynamic estimatedProgress` Darwin-only (MEASURED WebViewController.swift:177 KVO) |
| Blockzilla 129 | `Sources/Blockzilla/` | Darwin-only; `#selector` is a Linux corelibs wall |
| BlockzillaPackage | `Sources/BlockzillaPackage/` | real UIHelpers / UIComponents / AppShortcuts / Widget / Onboarding / Licenses |
| DesignSystem | `HackersModules/DesignSystem/` | FocusUIColor/Font/Image + Hackers feed; not BlockzillaPackage `UIColor(named:)!` |
| Glean / Sentry / Nimbus / FocusAppServices / os.log | guest shims | fail-closed; not Focus patches |
| Fuzi | `Sources/Fuzi/` | real `XMLParser` tree, `shouldProcessNamespaces = true` |
| Linux Onboarding | `FocusModules/Onboarding/` | handlers only; `@_exported import Combine` so V1/V2 see `Published` |

Darwin Onboarding is the real 21-file SnapKit+Widget tree (Preview Files
excluded). Linux / guest keep the handler-only module so
`build_full.sh`'s Onboarding glob still compiles.

## 3. Launch (Darwin SwiftPM)

`FocusBrowserLaunch.makeRoot()` seeds returning-user onboarding, sandboxes
`HOME` + `CFFIXED_USER_HOME` (MEASURED try7: `WebCacheUtils.reset()` tried
to delete `~/Library/Caches/dotslash`; macOS `NSHomeDirectory` ignores
`HOME` alone), copies `fixtures/realapp/focus-bundle/` next to the
executable **before** any `Bundle.main` resource snapshot (MEASURED try3),
then `UIApplicationMain` → `AppDelegate` → `BrowserViewController`.

`openrender realapp` with `OPENUIKIT_REALAPP_SCALE=3` emits **15** PNGs.
The 15th is last (`realapp_focus_browser_light`) so a miss cannot drop
the 14. Scale-2 / `linux_realapp_verify` omit it (`SCALE=2` gate) and
stay at **14**.

MEASURED first screen (iPhone 16 393×852 @3x, iOS cut):

| view | frame |
|---|---|
| `URLBar` | `[0, 59, 393, 56]` |
| wordmark `UIImageView` | `[44, 364.667, 305, 65.333]` (same `textLogoOffset` −32 as focus-e2e home) |

Pixels: URL bar (shield + hamburger) + Firefox Focus wordmark on the
gradient home. `WKWebView` is a blank content view.

Info.plist is linked with Darwin `-sectcreate __TEXT __info_plist`
(MEASURED AppInfo / NimbusExtensions force-unwrap `CFBundleName=Focus`,
`CFBundlePackageType=APPL`, `CFBundleShortVersionString=9000`,
`NimbusAppName=focus_ios`, `NimbusAppChannel=developer`).

`import os.log` in `NimbusWrapper.swift:5` compiled against this
package's `os` product (`_$s2os5OSLogV9subsystem8categoryACSS_SStcfC`
matches `Sources/os/OSLog.swift.o`). Debug `swift test` failed to link
it until Blockzilla / openrender / openhost depend on `os`.

## 4. First-screen score vs iOS 26.1

**N/A — no simulator golden.** `/tmp/golden_realapp_ios` has the Pocket
Casts / Focus settings / Hackers rows and is missing home, ledger, and
browser. `scripts/realapp_probe_sim.sh` compiles FocusModules stubs +
vendored Focus cells against Apple UIKit; `canImport(Blockzilla)` is
false, so the 15th row is omitted. Extending that probe to 129 Blockzilla
files + SnapKit + Apple WebKit was not done this pass. Do not invent a
score from a parameter search.

`compare_realapp.py` prints `realapp_focus_browser_light: MISSING
golden=False out=True`. Anchor class is `URLBar`.

## 5. Guest machorun (route b binary on Linux)

**Not linked this pass.** `full/scripts/build_full.sh` hardcodes
`compile_app_module` for the existing stubs and globs
`RealAppProbe/*.swift`, `Vendored/*.swift`, `Focus/*.swift`,
`Hackers/*.swift`. This branch cannot edit `full/`. Putting
`import SnapKit` / `import WebKit` sources on that glob would break the
14-screen guest. Operator must add `compile_app_module` for SnapKit,
WebKit, BlockzillaPackage, Blockzilla. Until then `render_full realapp`
stays **14** (`canImport(Blockzilla)` false).

## 6. Remaining blockers by class

| class | count | notes |
|---|---|---|
| guest `build_full.sh` glob | 1 | cannot compile Blockzilla into `render_full` from `uikit/` |
| iOS 26.1 browser golden | 1 | probe does not compile Blockzilla; score N/A |
| route (a) `#selector` / `@objc` | 147 (focus-e2e) | Linux corelibs still cannot compile Blockzilla |
| OpenSearch `UIImage(data:)` | 3 warnings | data: PNG favicons; engines still parse |
| SafariServices content blocker | 1 log | `SafariServicesUnavailableError` 0; fail-closed |
| `full/` WebKit KVO / SnapKit associated objects on corelibs | Darwin-only products | Linux `--build-tests` otherwise fails |

## 7. Gates

| gate | result |
|---|---|
| Catalyst | **124/124** (`/tmp/gate-focus-launch`) |
| iOS suite | **112/113** (`corner_radius` 99.411) |
| 3x realapp floors | **99.137 / 98.535 / 98.548 / 99.469 / 98.639 / 98.133 / 97.516 / 99.65 / 82.17 / 99.86 / 99.734 / 85.393** |
| `openrender realapp` SCALE=3 | **15** PNGs including `realapp_focus_browser_light` |
| `GlyphInkTableTests` + `ApplicationShellCompatibilityTests` | **22/22** |
| ingest tests | **34** tests, 20 skipped, OK |
| Linux `swift:6.2-noble` `openrender` | green (209 s) |
| `linux_realapp_verify.sh` | **rc=0** Hello **505**; miss `I\|system-regular\|17\|light\|F0.0\|81`; headless **14/14** live **10/10**; `REAL-APP SCREEN VERIFIED ON LINUX` |

3x floors are against the incomplete `/tmp/golden_realapp_ios` (no home /
ledger / browser goldens). The 12 rows that exist are unchanged.
