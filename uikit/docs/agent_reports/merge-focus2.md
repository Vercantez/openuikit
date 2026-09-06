# Merge focus-launch then focus-deps onto current main

MERGE TASK, no new rules. Landed `origin/agent/focus-launch` (`56d5fab2`)
then `origin/agent/focus-deps` (`9c6f595f`) on current `origin/main`
(`ed841f2e`). No files outside `uikit/`. No pin files. No
`Package.resolved`.

## Test-bundle fix (focus-launch onto main)

Operator merge `merge_focuslaunch39-merged.log` was TEST BUNDLE RED:
guest `WKNavigationDelegate` required `WKNavigation?` while unmodified
Focus uses `WKNavigation!` (`WebViewController.swift:381–515`,
`SettingsContentViewController.swift:156–166`).

SDK iPhoneSimulator 26.1 `WKNavigationDelegate.h:113–148` is
`null_unspecified WKNavigation *`, which imports as IUO. The stub
protocol + default extension now use `WKNavigation!` for
`didStartProvisionalNavigation`, `didReceiveServerRedirectForProvisionalNavigation`,
`didCommit`, `didFinish`, `didFail`, `didFailProvisionalNavigation`.

After that, `swift build --target Blockzilla` 0 errors and
`swift build --build-tests` green on the launch merge. Main's
`_transitionCoordinator` / `UIViewPropertyAnimator` path was kept
(launch's older parent-only `transitionCoordinator` was not).

## Per-conflict resolution (focus-deps)

| file | how it was resolved |
|---|---|
| `uikit/Package.swift` | Never keep-both. Re-expressed both sides in the existing typed arrays. Linux/Darwin vars keep launch's `onboardingPath` / `blockzillaRealAppDeps` **and** deps's `libkernModule` / `osTarget` / `snapKitExclude` / `uiKitLinuxDependencies` / `fuziLinuxDependencies`. `frameworkProducts` union: SnapKit (one copy, both platforms) + Sentry + Fuzi + libkern + FocusAppServices / LocalAuthentication / PassKit / Network. `frameworkTargets` union: `osTarget`, deps SnapKit (`snapKitExclude` + `PrivacyInfo.xcprivacy`), real Fuzi + CLibXML2, libkern, plus launch's FocusAppServices / LA / PassKit / Network. **Removed** the Darwin-only duplicate SnapKit product/target from `blockzillaProducts`/`blockzillaTargets`. |
| `uikit/Sources/SnapKit/*` | One copy of pin `e74fe2a`. Kept deps's `Debugging.swift` (Darwin; Linux excluded), LICENSE, VENDOR.txt, and `SnapKitOpenUIKitTests` (31/31). Launch's overlapping DSL files were identical. |
| `uikit/Sources/Fuzi/*` | One copy: deps's unmodified Fuzi 3.1.3 + libxml2. Deleted launch's XMLParser stub `Fuzi.swift` (both defined `XMLDocument`/`XMLElement`; Darwin then failed with ambiguous lookup / invalid redeclaration). |
| `uikit/Sources/Sentry/Sentry.swift` | Kept deps (154 lines, exact Focus signatures: `start(configureOptions:)`, `capture(message:/error:/exception:)`, `configureScope`, `crash()`, Linux `NSException`). |
| `uikit/Sources/RealAppProbe/FocusModules/Glean/Glean.swift` | Kept deps's fuller surface (`CounterMetricType` / nested GleanMetrics Focus names). Added launch's `@_exported import UIKit` so unmodified `NavigationPath.swift:5–6` (`import Foundation` + `import Glean` only) still sees `UIApplication`. |
| `uikit/Sources/OpenUIKit/UIViewController.swift` | Both behaviours: launch's defaulted `init(nibName:bundle:)`, deps's `topLayoutGuide`/`bottomLayoutGuide`, main's `_transitionCoordinator`. |
| `uikit/docs/REAL_APP_TEST.md` | Union, newest-first: this merge row, then deps, launch, then main's transitions / URLSession / ladder-census2 rows. |
| ingest `xcodeproj_to_package.py` + tests | Union PORTED_PRODUCTS (launch's WebKit / BlockzillaPackage / LA / PassKit / Network / StoreKit + deps's libkern). SnapKit/Sentry/Fuzi/libkern stay linux-conditioned products. WebKit is ported (not `no_port`). Fuzi class `unmeasured` (deps). |

## Merge-interaction fixes (not in either branch alone)

1. **WKNavigationDelegate IUO** — above.
2. **`NSLayoutConstraint()`** — launch's `FocusLaunchCompat` convenience
   `init()` became an override of `NSObject.init()` once deps made the
   class inherit NSObject (SnapKit Debugging.swift). Extension
   `convenience override init()` then doubled the override. Moved onto
   the class body (`NSLayoutConstraint.swift`).
3. **Fuzi stub vs real Fuzi** — above.
4. **Glean `@_exported import UIKit`** — above.

## Proof (this merge)

Darwin (`SIM_DEVICE_SUFFIX=-merge-focus2`):

- `time swift package describe`: **0.87 s** (bar <20 s)
- `swift build --target Blockzilla`: **0 errors**
- `swift build --build-tests`: **Build complete**
- SnapKit **31/31** + OpenUIKit helpers; Glean 2; Sentry 2; Libkern 3;
  Fuzi OpenSearch 1; OSTests 10. Filter group **51/51**.
- Ingest `test_xcodeproj_to_package.py`: **17 passed, 20 skipped**
- Catalyst **124/124** (`/tmp/gate-merge-focus2`)
- iOS suite **112/113** (`corner_radius` 99.411) `SKIP_CAPTURE=1`
  `/tmp/suite-merge-focus2`
- Real-app 3x floors **99.137 / 98.535 / 98.548 / 99.469 / 98.639 /
  98.133 / 97.516 / 99.65 / 82.17 / 99.86 / 99.734 / 85.393**
- `openrender realapp` SCALE=3: **15** PNGs.
  `FocusBrowserLaunch.makeRoot()` first screen: `URLBar [0, 59, 393, 56]`,
  wordmark `UIImageView [44, 364.667, 305, 65.333]` (same as
  focus-launch.md). `WKWebView` present. Browser golden **N/A**.

`docker exec -w /work-merge-focus2 uikit-linux`:

- `swift package describe`: **0.551 s**
- `swift build --target` Glean, Sentry, libkern, Fuzi, os, SnapKit,
  OSTests: green

`docker run --rm -v "$PWD":/src:ro swift:6.2-noble`:

- `swift package describe`: **1.007 s**
- `swift build -c release --product openrender`: **188.47 s**
- Glean / Sentry / libkern / Fuzi / os / SnapKit: green (`libxml2-dev`)

`scripts/linux_realapp_verify.sh /tmp/linux-realapp-merge-focus2`:
Hello **505**; miss `I|system-regular|17|light|F0.0|81`; headless
**14/14**; live **10/10**; `REAL-APP SCREEN VERIFIED ON LINUX`.
