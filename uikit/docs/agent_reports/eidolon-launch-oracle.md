# Eidolon iOS 26.1 oracle and resource measurements

Date: 2026-09-07. Corpus: `artsy/eidolon` at
`44486ed9149f16b3eb3a5e687f99ae078309f4fe`. Xcode 26.1 (17B55),
iPhoneSimulator SDK 26.1, installed iOS 26.1 runtime 23B86.
The reserved private suffix is `-eidolon-launch-oracle`; no simulator device
was booted because the original app did not reach a successful build.
**First-screen golden, layout, and fidelity score: N/A.**

## Resource compilation

Run from `uikit/`, with `EIDOLON` naming the pinned corpus checkout:

```sh
scripts/compile_realapp_nibs.sh --out /tmp/eidolon-launch-nibs \
  "$EIDOLON/Kiosk/Storyboards/KeypadView.xib" \
  "$EIDOLON/Kiosk/Storyboards/Auction.storyboard" \
  "$EIDOLON/Kiosk/Storyboards/Fulfillment.storyboard"
```

This is unmodified Interface Builder input, compiled by Xcode's `ibtool`.
All three invocations succeed. Artifacts are carried under
`fixtures/realapp/eidolon/nibs/`, and its `manifest.json` verifies all
61 output files. Artifact SHA-256 values and source hashes are also in
`eidolon-launch-oracle.json`.

| source | XML scenes | custom-class occurrences | output NIBArchive files | output bytes, including plist |
|---|---:|---:|---:|---:|
| Auction.storyboard | 12 | 39 | 21 | 68,859 |
| Fulfillment.storyboard | 20 | 130 | 37 | 148,306 |
| KeypadView.xib | 0 | 14 | 1 | 6,551 |
| total | 32 | 183 | 59 | 223,716 |

There are two compiled `Info.plist` files and 48 distinct XML custom-class
names. This count includes `UIResponder` on the xib First Responder
placeholder; it is not a count of 48 missing classes.

The Auction initial controller is XML ID `KCM-cT-BEX`, class
`Kiosk.AppViewController`. Its compiled controller archive is
`Auction.storyboardc/AppViewController.nib` (2,299 bytes); its view archive
is `KCM-cT-BEX-view-jGy-SO-AWq.nib` (5,727 bytes). The first scene also
requires `Kiosk.ActionButton` and `Kiosk.ListingsCountdownManager` and
an embedded navigation/listings route. Compiling the archives does not
prove custom-class registration, outlets, segues, or controller instantiation.

## Native build measurements

The source checkout was copied unchanged to
`/tmp/eidolon-launch-oracle-source`, omitting only `.git`, so Xcode's
workspace bookkeeping could not modify the corpus. Run from `uikit/`:

```sh
xcodebuild \
  -workspace /tmp/eidolon-launch-oracle-source/Kiosk.xcworkspace \
  -scheme Kiosk -configuration Debug -sdk iphonesimulator \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath /tmp/eidolon-launch-derived \
  CODE_SIGNING_ALLOWED=NO build
```

Exit **65**, with one build error: missing
`Pods/Target Support Files/Pods-Kiosk/Pods-Kiosk.debug.xcconfig`.
The workspace points at an absent `Pods/Pods.xcodeproj`; the dependency
graph contains only Kiosk. Xcode also warns that the app's iOS 10.0
minimum is below the current simulator SDK's supported 12.0 minimum.
That warning is not being counted as the fatal error.

```sh
pod install --deployment --no-repo-update \
  --project-directory=/tmp/eidolon-launch-oracle-source
```

The installed CocoaPods 1.15.2 initially exits **1** because the required
`cocoapods-keys` plugin is absent. The app locks CocoaPods 1.9.1.
The plugin absence is a repaired tooling issue, not the terminal claim:
`cocoapods-keys` 2.0.6, `dotenv` 2.5.0, `osx_keychain` 1.0.2,
`RubyInline` 3.12.4, and `ZenTest` 4.12.0 were installed at the app's
Gemfile.lock versions under `/tmp/eidolon-launch-oracle-gems`.
The unqualified dependency install had first failed because current
`dotenv` requires Ruby 3.0 while the system Ruby is 2.6.10.

CocoaPods' actual `Pod::Lockfile#detect_changes_with_podfile` was then
run against the two tracked files without plugin hooks or service keys:

```sh
ruby -r cocoapods-core -r json -e '
root = Pathname.new("/tmp/eidolon-launch-oracle-source")
podfile = Pod::Podfile.from_file(root + "Podfile")
lockfile = Pod::Lockfile.from_file(root + "Podfile.lock")
puts JSON.pretty_generate(lockfile.detect_changes_with_podfile(podfile))'
```

It reports **Stripe changed**, **Artsy+OSSUIFonts added**, and
**Artsy+UIFonts removed**, with 34 unchanged dependency entries.
The additional `Keys removed` entry is explained by this diagnostic
intentionally not running the plugin that injects the generated Keys pod;
it is not another app-version conflict.

The Stripe mismatch is concrete: Podfile requests **14.0.1** while its
lockfile records **12.1.0**. Without staff/CI flags, Podfile requests
`Artsy+OSSUIFonts`, whereas the lockfile records `Artsy+UIFonts` **3.1.3**.
The upstream README explicitly says those private licensed fonts are not
part of the open-source distribution. No fonts or Stripe pin was silently
changed to make the original oracle build proceed.

## Locked CardFlight source wall

The `CardFlight-v4` **4.3.1** CocoaPods spec names
`https://github.com/CardFlight/cardflight-v4-ios.git`, tag `v4.3.1`.
The services/dependency probe retrieved the spec from
`https://raw.githubusercontent.com/CocoaPods/Specs/master/Specs/0/9/9/CardFlight-v4/4.3.1/CardFlight-v4.podspec.json`.
An independent source probe here ran:

```sh
git ls-remote https://github.com/CardFlight/cardflight-v4-ios.git 'refs/tags/*4.3.1*'
```

Exit **128**, exact output:

```text
remote: Repository not found.
fatal: repository 'https://github.com/CardFlight/cardflight-v4-ios.git/' not found
```

This is the measured source-access wall after routine missing plugin
tooling was repaired. It does not establish whether the repository has
been removed or made private. Correcting build metadata alone cannot
reproduce the locked native dependency graph from the sources available
in this run. No replacement CardFlight binary or successful account,
payment, or network callback was fabricated.

## Blocker table

| blocker | measured state |
|---|---|
| NIB compilation | Cleared: 3/3 Interface Builder inputs compile; 59 NIBArchive files plus 2 plists. |
| NIB runtime | Port probe executes: Auction initial controller is nil; direct compiled controller NIB falls back to plain UIViewController with 10 unhandled entries. Native app runtime remains unmeasured. |
| Native dependency workspace | Original iOS 26.1 Xcode build exits 65, one missing Pods base-configuration error. |
| Locked CardFlight source | Version 4.3.1 spec's repository probe exits 128, `Repository not found`; native dependencies remain unavailable. |
| Locked dependency metadata | CocoaPods compatibility check confirms Stripe 14.0.1 vs 12.1.0 conflict; default OSS fonts differ from the private locked fonts. |
| Oracle app identity | The app is an iPad landscape kiosk: the storyboards declare iPad target runtime, and Info.plist enables only landscape orientations for iPad. A 393×852 iPhone settings-harness capture would not establish this first screen. |
| Service mode | Upstream `APIKeys.stubResponses` uses API strings shorter than 2 to select the app's built-in demo responses; `fastlane oss_keys` supplies `-`. No demo response was created or represented as a real network/account success in this measurement. |
| First screen and pixel score | N/A: no successful original app build, no capture, no layout dump, no comparison. |

Logs remain at `/tmp/eidolon-launch-xcodebuild.log`,
`/tmp/eidolon-launch-pod-deployment.log`, and
`/tmp/eidolon-launch-lock-diff.json`, and
`/tmp/eidolon-launch-cardflight.log`. The JSON companion carries the
fatal diagnostic, command, source/resource hashes, and measured counts
so the report remains reviewable without these temporary logs.

## Port runtime boundary, executed

A `/tmp` Swift executable linked the already-built OpenUIKit release
module and 190 object files from OpenUIKit, OpenCoreGraphics, CSTBTrueType,
CPortableIO, and CQuartz. It loaded the carried compiled resources without
registering substitute app classes. Compile and execution both exited **0**.
The source, runtime output, input source hashes, and linker inputs recipe
are retained in this report's JSON companion (`port_runtime`).

```text
storyboard.initial.isNil=true
factory.AppViewController=false
factory.ActionButton=false
factory.ListingsCountdownManager=false
```

| compiled archive directly opened with UINib | parsed | actual top-level type | distinct unhandled entries |
|---|---|---|---:|
| Auction.storyboardc/AppViewController.nib | yes | OpenUIKit.UIViewController | 10 |
| Auction.storyboardc/KCM-cT-BEX-view-jGy-SO-AWq.nib | yes | OpenUIKit.UIView | 17 |
| KeypadView.nib | yes | OpenUIKit.UIView | 12 |

`Sources/OpenUIKit/UIApplication.swift` implements
`UIStoryboard.instantiateInitialViewController()` as unconditional `nil`.
The direct archive decoder falls back to UIKit base classes for absent
custom factories; these returned objects are not Eidolon's controllers.
The initial-controller archive also records unsupported embed/modal segue
templates, event connections, and the `storyboard`/`countdownManager`
outlets. The view archive records missing ActionButton, two named fonts,
outlet-collection wiring, and view/constraint keys.

This closes the uncertainty about the port's runtime boundary without
claiming an Eidolon screen or a simulator comparison. The process also
prints the existing duplicate `CAFilter` registration diagnostic from
Apple QuartzCore and the linked port; it does not abort this probe.
