# NetNewsWire first screen (route (b), iOS triple): status 2026-09-23

Branch `agent/netnewswire-first-screen`. Every increment passed
`CHECK_ONLY=1 agent_merge.sh` (124/124 scenes, GUEST_ROUTE_CHECK_OK) and
`local_guest_verify.sh` (14/14 byte-identical, REAL-APP SCREEN VERIFIED ON
LINUX).

## Reach (chain census, iOS 26.1 simulator SDK with Apple UIKit/SwiftUI removed)

| measurement | NNW app errors |
|---|---|
| first census this round | 282 |
| after batch B | 129 |
| combined with cg-unify phase 1 and objc-protocols | 102 |
| + SwiftUI rows, Foundation-name re-exports, CoreText, timer-unify, corrected app flags | 3 |
| + safari-objc (objc-surface), full bridging-header translation, UIViewController.overrideUserInterfaceStyle | **0** (all 24 chain targets) |

The combined figure means this branch plus origin/main, timer-unify-2,
objc-protocols-2, cg-unify-phase3, and cg-unify's CG re-export
(measurement-only here; cg-unify owns it), and for the 0 row also
agent/safari-objc. All 24 targets type-check with 0 errors. Type-checking is
not linking: the chain spec has no executable app target yet.

## Increments

| commit | content |
|---|---|
| b96e25e9 … 300a9ebc | AuthenticationServices, WidgetKit, UIKit re-exports UserNotifications, batches A and B (launch path, cells, collection/table hooks) |
| e44dc41c | `@main` scene launch in UIKit's measured order |
| c59cabad | UISlider.TrackConfiguration, `animate(springDuration:)` (QuartzCore-measured coefficients and settling), UIScene notification names, trait target/action |
| e26fffec | SwiftUI rows NNW needs: exact iOS system colours (Color.red/green/blue/gray were the pure primaries before), AnyShapeStyle, `.link`, Section builders, LabeledContent, ShareLink, segmented picker, List(data), sheet(item:), navigationSubtitle and others. NSAttributedString and NSRange re-exported instead of re-declared (collection sugar). CoreText visible through UIKit. The ObjectIdentifier-keyed list-config leak behind the order-dependent collection tests |
| b67ccb46 | headless `@main` runs the CFRunLoop with a host-clock ticker; app flags as Xcode applies them |
| bc747373 | Feeds golden (stable state) plus live-data masks in the real-app compare |
| 02ee39c2 | UIViewController.overrideUserInterfaceStyle (vcstyleprobe); app depends on and imports NetNewsWireObjC (bridging header in full) |

Every fix is measured on the iOS 26.1 simulator (oracles under
Tools/oracle2: nnwmiscprobe, nnwswiftuiprobe, springsettleprobe, scenelaunch,
cellconfig, sendaction). Every fix has a test that fails before it and
passes after. Partial implementations are listed in docs/KNOWN_GAPS.md.

## Golden

`netnewswire-first-screen/realapp_nnw_feeds_light.*`, captured by
Tools/oracle2/nnwgolden/run.sh:
- a fresh device, notification permission answered "Don't Allow" (seeded),
  widget stripped, captured after the refresh settles;
- 20 masks (unread counts and account favicons, 3.4 % of pixels), taken from
  the golden's own layout.

A no-network capture needs admin rights, so the masked comparison was chosen.

## Not reached

- **App link.** safari-objc and cg-unify's CG re-exports must merge. Then the
  spec needs an executable app target with Info.plist and resources.
- **Port render of the Feeds list.** No masked or unmasked score exists yet.
- **Guest wiring under machorun.** Not started.
