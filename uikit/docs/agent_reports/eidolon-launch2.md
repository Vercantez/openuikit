# Eidolon pass 2: UIButton.rx.tap on the Apple toolchain

2026-09-07, `agent/eidolon-launch2`, base `ddacdcdf`.

This pass addresses **one remaining item** from [eidolon-launch.md](eidolon-launch.md):
the pinned RxCocoa's macOS platform branch makes Eidolon's `UIButton.rx.tap`
expressions require `NSButton`. Three representative expressions now type-check
with **3 errors → 0**. The port matches **16/16** event/ownership observations
from real iOS 26.1. This is a dependency API/lifetime result, not an app launch:
Eidolon's first-screen golden, layout and pixel score remain **N/A → N/A**.
No subagents were used.

## Why this item

The landed report identifies concrete tap call sites in the pinned app:
`ChooseAuctionViewController.swift:34`, `ListingsCollectionViewCell.swift:141`,
and `SaleArtworkDetailsViewController.swift:241`. The app imports `RxCocoa`
and `UIKit` without any additional adapter import. A small extension in the
existing RxCocoa module can resolve this wall without replacing app code,
fetching unavailable services, or claiming that the entire dependency graph
now builds. The frozen census remains **NEAR / =B 6**; DEP includes other walls.

## Measurement and rule

The oracle builds **unchanged** RxSwift 4.1.2 and the RxCocoa slice needed for
UIButton/UIControl: its original iOS extensions, Foundation, traits, shared
helpers and four ObjC runtime files. It uses Apple UIKit, not OpenUIKit.
The source selection and hashes are recorded in `eidolon-launch2.json`;
this slice is not represented as a build of the full iOS RxCocoa module.
The pin remains `3e848781c7756accced855a6317a4c2ff5e8588b`.

Private iPhone 16, iOS **26.1**, simulator name
`OpenUIKit-EidolonTap-eidolon-launch2`. `EidolonTap` is a standalone measurement
app, excluded from the normal ConformanceApps target; it adds no axis.
Its shared scenarios and the carried `fixtures/realapp/eidolon/tap-oracle.json`
are used verbatim by the port test. The calls are explicit `sendActions`,
not simulated touches, a rendered screen, or a successful service response.

| Observation | iOS oracle | completed port |
|---|---:|---:|
| Initial / unrelated events | 0 / 0 callbacks | 0 / 0 |
| One touch-up-inside, two subscriptions | 1 callback each | 1 each |
| Explicit send while disabled | delivered | delivered |
| Dispose first subscriber, send again | first 3, second 4 cumulative | 3 / 4 |
| Dispose all | registered event mask 0; no extra callbacks | same |
| Union subscription; two individual sends then one combined send | 2 → 3 callbacks | 2 → 3 |
| `take(1)` disposal during delivery | 1 next, 1 completion, mask 0 | same |
| Release subscribed button | button released; 1 completion | same |
| Subscribe after release | 0 next, 1 completion | same |
| Dispose releases observer capture | true | true |

The added `RxCocoa/OpenUIKit/OpenUIKitControlEvents.swift` adapts the original
observable construction to OpenUIKit's existing control registration token.
It preserves real RxSwift `Observable`, `ControlEvent`, scheduling, weak control
capture and `takeUntil(deallocated)`. The public event mask is the native
`UIControl.Event` type; `.tap` observes `.touchUpInside`. The adapter is compiled
only for macOS with OpenUIKit available. The original iOS and AppKit source
branches remain byte-for-byte unchanged; an AppKit overload compile assertion
also remains in the test target.

The first bridge attempt exposed a necessary ownership defect: **10/12**
original oracle cases passed, but the button never released and its stream
never completed. A bare button without Rx reproduced the problem. OpenUIKit's
`UIView.superview` was strong, creating a cycle with `subviews`, including a
UIButton's built-in label.

An independent UIKit **Mac Catalyst** executable (26.1 SDK, macOS **26.5.2**
host) agreed with the iOS
ownership probe: a retained child does not retain its parent; `superview`
clears; a parent retains an attached child. After removal and an autorelease
pool drain the child releases. Before the fix, the port reported
`buttonReleased=false parentReleased=false superviewCleared=false`; both Apple
authorities reported all three **true**. `superview` is now weak, while the
parent's child array retains its children. This is the same rule on both
Apple authorities, so it does not depend on the font/chrome cut. The final
oracle has **16** cases, adding ownership isolation and the event union.

## Validation

| Check | measured result |
|---|---|
| Focused Darwin release tests | **12/12** tests; all **16/16** oracle cases agree. |
| Native oracle repeat | All 16 rows identical on a second capture of the final scenarios. |
| Catalyst | **124/124 → 124/124**; all **178/178 PNGs** and **124/124 layouts** unchanged. |
| Fresh iOS suite | **112/113 → 112/113**; all **113/113 PNGs and layouts** unchanged. Same sole `corner_radius` miss, **99.411**. |
| Existing real-app screens, iOS cut @3 | All **15/15 PNGs and layouts** unchanged. All **14** available golden scores identical; browser's golden remains absent in `/tmp/golden_realapp_ios`, so its numeric score is N/A. |
| Launch preflight / load list | Before and after exit **2**, unavailable, with no output directory; `openrender` dylib load list unchanged. |
| Linux Swift 6.2 noble | Release `openrender` build **green (183.17 s)**; required `OpenUIKitTests` target **green (23.94 s)**; isolated native-ELF ownership probe **5/5 assertions**. |
| Required merge proof | Pending after the implementation commit. |

An optional **whole-package** Linux `swift test` did not reach execution:
the current run reported four Hackers `NotificationCenter.publisher` inference
errors; a private unmodified baseline copy stopped first on missing
`SDL2/SDL.h`. These are different first blockers, not a claim of identical
failures. The required Linux release build, relevant test-target build and
isolated ownership probe pass; no whole-package Linux XCTest pass is claimed,
and no unrelated Hackers or SDL source was changed.

The baseline is the pre-change release executable saved from `ddacdcdf`.
For the iOS comparison it was replayed against the **same freshly captured**
goldens and scale-split scene inputs as the final executable. No scene or
golden was removed, rewritten, resized or substituted.

## Remaining blocker table (scope preserved)

| blocker | state after this pass |
|---|---|
| DEP: UIButton tap platform selection | Closed for the measured API: three representative app expressions compile; 16/16 oracle cases match. |
| DEP: other reactive UIKit surfaces | Not claimed: the vendored module still selects other AppKit platform branches. This adapter only adds control events and button tap. |
| NIB | Unchanged from landed report: initial storyboard lookup nil; missing app factories; 10/17/12 unhandled direct archive entries. |
| DEP / ObjC / native build | Prior measured walls remain: 14 absent imports, unavailable locked CardFlight source, Stripe/fonts metadata mismatch, two missing ObjC dependencies. Not re-measured in this pass. |
| Services / app initialization | Fail-closed preflight unchanged. No credentials, demo-account success, payment or network result was fabricated. |
| Mach-O guest | No Eidolon guest executable or guest dependency build was produced. The production builder wiring remains outside this uikit-only pass. |
| First-screen score | N/A before and after; no Eidolon screenshot or layout claimed. Existing real-app regressions are measured separately. |

## Reproduce

From `uikit/`:

```sh
SIM_DEVICE_SUFFIX=-eidolon-launch2 python3 scripts/eidolon_tap_probe_sim.py /tmp/eidolon-tap-oracle
swift test -c release --filter 'EidolonRxCocoaTests|ViewGeometryTests'
SIM_DEVICE_SUFFIX=-eidolon-launch2 scripts/ios_suite.sh /tmp/suite-eidolon-launch2
```

The three-expression type-check source, exact commands, diagnostics, Catalyst
ownership probe source/output and source-integrity counts are carried in
`eidolon-launch2.json`. The original app's **117/117** files, dependency
**368/368** files and original compiled nib/plist **61/61** artifacts match
the landed hashes. No corpus checkout or pin changed.

Required merge proof from the repository root:

```sh
CHECK_ONLY=1 bash uikit/scripts/agent_merge.sh agent/eidolon-launch2
```
