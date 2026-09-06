# Merge `origin/agent/merge-focus2` onto main (split Package.swift)

MERGE TASK, no new rules. Main (`29bdb649`) already carries materials40c,
textkit41c, pickers41c, values39e, transitions39 — typed
`coreProducts`/`frameworkProducts` and
`coreTargets`/`frameworkTargets`/`conformanceTargets`/`testTargets`, plus
PhotosUI. `origin/agent/merge-focus2` (`8bc7b509`) is Blockzilla vendored
as a library under `Sources/Blockzilla` + BlockzillaPackage, SnapKit at
Focus's pin with its test target, the WebKit guest stub with the SDK's
IUO delegate shapes, Sentry/Glean/Fuzi/libkern/os guest modules,
FocusLaunchCompat, and the RealAppProbe launch harness (report
`merge-focus2.md`). It was written on main `3e58c4f4`; the operator's
checked merge refused it: `UNEXPECTED CONFLICT (manifest):
uikit/Package.swift`.

Never keep-both on the manifest or on Swift. This merge keeps **every
main target, product, dependency, exclude list, swiftSettings and
platform condition** (including PhotosUI) and **adds the branch's
products/targets on the split arrays**. Darwin
`blockzillaProducts`/`blockzillaTargets` stay `#if !os(Linux)`.

## File resolutions

| file | how it was resolved |
|---|---|
| `uikit/Package.swift` | Not keep-both. Took main's split arrays. PhotosUI stays on `frameworkProducts`/`frameworkTargets`. Incoming SnapKit / Sentry / Fuzi / libkern / FocusAppServices / LocalAuthentication / PassKit / Network appended there. `osTarget` (Linux `publicHeadersPath`) replaces `.target(name: "os")`. Darwin `blockzillaProducts`/`blockzillaTargets` (Blockzilla, WebKit, UIHelpers, UIComponents, AppShortcuts, Widget) stay the `#if !os(Linux)` arrays. |
| `uikit/docs/REAL_APP_TEST.md` | Union, newest-first: this merge; then pickers / textkit / materials / values; then merge-focus2 / focus-deps / focus-launch; then main's transitions row. |
| `Sources/OpenUIKit/FocusLaunchCompat.swift` | Dropped duplicate `UIPrintFormatter` / `UIPrintPageRenderer` / `UIPrintInfo` / `UIActivityItemProvider` (pickers already define them). Focus names moved onto those types. |
| `Sources/OpenUIKit/UIPrintInteractionController.swift` | Added `UIPrintInfo(dictionary:)`, `addPrintFormatter`, `viewPrintFormatter` (OpenUtils.swift:19, :25; WebViewController.swift:87). |
| `Sources/OpenUIKit/UIActivityViewController.swift` | `open func activityViewController(_:subjectForActivityType:)` so TitleActivityItemProvider.swift:30 can `override`. |
| `Sources/OpenUIKit/UIViewController.swift` | Auto-merged: launch's defaulted nib init (AutocompleteSettingViewController.swift:19 `convenience init()` is not an override). Pickers' `override init()` became `init()` / `convenience init()` (`UIColorPickerViewController`, `UIFontPickerViewController`, `UISearchController`). |
| `Sources/UIKitShim/UIKit.swift` | One `NSAttributedString` alias (textkit block). Kept focus2 `Timer` + `OpenUIKitObjectiveC` re-export. |
| `Tests/OpenUIKitTests/SystemPickerTests.swift` | Linux 6.2.4 `ActorIsolatedCall` on Safari/PHPicker Probe types (inferred MainActor from `@_exported import UIKit`). Those two tests stay Darwin-only; Linux XCTest cannot invoke `@MainActor` anyway (linux-trial). |
| `Tests/OpenUIKitTests/ValueTypeTailTests.swift` / `TextKitTests.swift` | Linux `NotificationCenter.default` is Foundation + OpenUIKit. Private typealias to OpenUIKit (same pattern as TextKit's `NSAttributedString`). |

Auto-merged without conflict: UILayoutGuide NSObject + SnapKit `topLayoutGuide`, UIResponder `accessibilityValue` (AutocompleteTextField override), SafariServices `@_exported import UIKit`, ingest PORTED_PRODUCTS, compare_realapp 15th screen.

`swift package describe --type json` vs main: **no removed products or targets**. Shared product records match. Added products: SnapKit, Sentry, Fuzi, OpenUIKitLibkern, FocusAppServices, LocalAuthentication, PassKit, Network, Blockzilla, AppShortcuts, WebKit, UIHelpers, UIComponents. Added targets: those plus Widget, SnapKitOpenUIKitTests, GleanTests, SentryTests, LibkernTests, FuziTests.

No files outside `uikit/`. No pin files. No `Package.resolved`.

## Proof (this merge)

Mac (`SIM_DEVICE_SUFFIX=-merge-focus3`):

- `time swift package describe --type json > /dev/null`: **0.628 s** (bar <20 s)
- `swift build --target Blockzilla`: **0 errors**
- `swift build --build-tests`: Build complete (16.67 s)
- SnapKit **31/31**; Glean/Sentry/Libkern/Fuzi/OSTests 18; SystemPickerTests Darwin 14; ingest `test_xcodeproj_to_package.py` **17 passed, 20 skipped**
- Catalyst **124/124** (`/tmp/gate-merge-focus3`)
- iOS suite **112/113** (`corner_radius` 99.411) `SKIP_CAPTURE=1` `/tmp/suite-merge-focus3`
- Real-app 3x floors **99.137 / 98.535 / 98.548 / 99.469 / 98.639 / 98.133 / 97.516 / 99.65 / 82.17 / 99.86 / 99.734 / 85.393**
- `OPENUIKIT_REALAPP_SCALE=3` `openrender realapp`: **15** PNGs. `FocusBrowserLaunch.makeRoot()` `URLBar [0, 59, 393, 56]`, wordmark `UIImageView [44, 364.667, 305, 65.333]`. `WKWebView` present. Browser golden **N/A**.

`docker exec -w /work-merge-focus3 uikit-linux`:

- `swift package describe`: **0.582 s**
- Glean / Sentry / libkern / Fuzi / os / SnapKit / PhotosUI: green
- `swift build -c release --product openrender`: **201.57 s**

`docker run --rm … swift:6.2-noble` (tree tarred to `/work`, exclude `.build` / `Package.resolved`):

- `swift package describe`: **0.998 s**
- `swift build -c release --product openrender`: **228.77 s**
- Glean / Sentry / libkern / Fuzi / os / SnapKit / PhotosUI: green (`libxml2-dev`)

`scripts/linux_realapp_verify.sh /tmp/linux-realapp-merge-focus3`:
headless **14/14**; live **10/10**; `REAL-APP SCREEN VERIFIED ON LINUX`.

No new rendering rules. Catalyst paths stay behind the existing iOS cut.
The focus-launch measurements (URLBar / wordmark) and pickers PhotosUI
product are unchanged.
