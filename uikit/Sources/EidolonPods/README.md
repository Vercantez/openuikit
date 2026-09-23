# Eidolon's Objective-C CocoaPods, vendored

The 17 Objective-C pods artsy/eidolon `44486ed` locks in its Podfile.lock (16
the app names plus NJKWebViewProgress, which DZNWebViewController depends on),
at their resolved commits, as a SwiftPM package of Clang targets that build
against OpenUIKit on route (b).

| path | what |
|---|---|
| `Pods/<pod>/` | byte-identical upstream files: what the locked podspec selects (`source_files` minus `exclude_files`), its `resources`, its licence and podspec. Checksums: `PROVENANCE.json` (per file, and the GitHub archive of the commit). |
| `Targets/<Module>/` | one Clang target per pod: `Sources/` and `include/<Name>/` are relative symlinks into `Pods/`, `include/module.modulemap` and `<Module>-umbrella.h` are what CocoaPods' `use_frameworks!` generates |
| `Targets/PodsUIKitUmbrella/` | publishes `<UIKit/UIKit.h>` (the route (b) umbrella, `Support/UIKit/UIKit.h`) to the pods' consumers, whose module builds need it for each pod umbrella's `#import <UIKit/UIKit.h>` |
| `Support/Pod-prefix.pch` | CocoaPods' generated prefix header, `-include`d by every pod translation unit |
| `pods-manifest.json` | per pod: module, files, licence, dependencies, and `resources` with the bundle path CocoaPods copies each one to |
| `Package.swift` | the package; depends on OpenUIKit at `../..` |

Nothing here is edited by hand. Regenerate with

```sh
# pods: one checkout per pod at the commit in fixtures/realapp/eidolon/objc_pods.json
python3 Tools/ingest/objc_pods_package.py <pods-dir> fixtures/realapp/eidolon/objc_pods.json \
    Sources/EidolonPods --uikit ../.. --vendor
```

OpenUIKit's own package does not list these targets: an app chain adds this
package (`docs/agent_reports/eidolon-kiosk-chain.json`, "packages") and
depends on the pod products. The Apple-toolchain iOS-triple build of all 17
compiles with 0 errors (docs/agent_reports/eidolon-kiosk.md).

## Resources

`pods-manifest.json` lists each pod's resources with `bundle_path`: where
CocoaPods puts it (a file at the bundle root, a `.bundle` directory whole).
With `use_frameworks!` that bundle is the pod's framework and the pods find
their files with `[NSBundle bundleForClass:]`; linked statically into the app
executable that is the main bundle, so the app bundle carries them at its
root (Artsy+UIFonts' EB Garamond / TeX Gyre Adventor fonts, SVProgressHUD.bundle,
DZNWebViewController's images and scripts, Artsy+UILabels' chevrons).

Licences: `THIRD_PARTY_LICENSES/EidolonPods.md`.
