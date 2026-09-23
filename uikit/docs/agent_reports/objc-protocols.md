# UIKit's delegate and data-source protocols as `@objc` protocols (increment 1)

**Date:** 2026-09-22
**Branch:** `agent/objc-protocols` (merged with main 4b6a693f)
**Oracle:** iPhone 16, iOS 26.1 simulator (`Tools/oracle2/objcprotocolprobe`)

## What changed

On the Apple toolchain (`OPENUIKIT_OBJC_SUBCLASSING`), these protocols now
have UIKit's own shape:

* UIScrollViewDelegate
* UITableViewDataSource / UITableViewDelegate
* UICollectionViewDataSource / UICollectionViewDelegate

Each is an `@objc` protocol under UIKit's runtime name. Each refines
`NSObjectProtocol` and uses the iPhoneSimulator26.1 SDK selectors
(`numberOfSectionsInTableView:`, `tableView:cellForRowAtIndexPath:`,
`viewForZoomingInScrollView:`, `scrollViewDidEndZooming:withView:atScale:` …).
The SDK's split between required and `optional` members is kept.
`tableView:editingStyleForRowAtIndexPath:` is a **delegate** method, as in
`UITableView.h`; the Swift protocol had it on the data source.

Linux ELF and the Foundation-hidden guest keep the Swift protocols and their
default implementations, unchanged. They have no `@objc`.

Every OpenUIKit call site goes through `UIKitProtocolDispatch.swift`:
* On Apple the helpers spell `delegate.method?(…)`, and an absent method
  yields the old default value.
* On the portable builds they make the Swift call.

One call site serves both builds, so a delegate that does not implement a
method behaves the same on each. The one exception is the row-height rule
below.

This fixes NetNewsWire's rows (netnewswire-launch, `chain_census.py
--ios-target`), which now compile and run in `Tests/ObjCProtocolTests`:
* RSCore's `let numberOfSections = dataSource.numberOfSections` gives nil when
  the method is absent.
* `@objc protocol ImageScrollViewDelegate: UIScrollViewDelegate` is accepted.
* `@objc weak var imageScrollViewDelegate` is accepted.
* `imageScrollViewDelegate?.scrollViewDidScroll?(…)` forwards.

One protocol now serves an app's Swift and Objective-C halves.
`UIKitObjCSupport.h` no longer declares its own `…ObjC`-named copies, which
had been a "different definitions in different modules" error once the
generated ones existed.

## Presence semantics, measured and matched

`OUKProtocolScenario.m` is the same Objective-C file the simulator ran. Its
delegates implement different subsets of the optional methods, and
`ObjCProtocolTests` compares its output line for line with
`transcript-ios26.1.txt`. It runs with the iOS font cut at 3x, matching the
oracle device.

| case | iOS 26.1 | OpenUIKit before | now |
|---|---|---|---|
| data source with only the 2 required methods | 1 section; rows 52 pt; only `numberOfRows`/`cellForRow` sent | same | same |
| `rowHeight` 70, delegate without `heightForRow` | rows 70 | 70 | 70 |
| `rowHeight` 70, `heightForRow` returns 60 / **automatic** / 50 | 60 / **52** / 50 | 60 / **70** / 50 | 60 / 52 / 50 |
| `setZoomScale:2` without `viewForZoomingInScrollView:` | zoomScale **1**, nothing sent | 2 | 1 |
| `setZoomScale:2` with a 100×100 zoom view | contentSize **{200, 200}**; `viewForZooming` and `scrollViewDidZoom` sent | {100, 100} | {200, 200} |
| `scrollViewDidScroll` on setContentOffset, same offset again, contentOffset= | 1 / 0 / 1 | same | same |
| numberOfSections 2 + titles (plain) | geometry and call set | same | same |

* **Row height.** A delegate that *answers* `automaticDimension` self-sizes
  the row even when `rowHeight` is fixed. This is visible only where presence
  is: the Apple builds. On the portable builds the Swift default
  implementation cannot say "not implemented", so `automaticDimension` there
  still means "use rowHeight", the long-standing behaviour.
* **Zoom.** Both zoom rules apply on every build.

## Other changes the protocols required (SDK shapes)

* UISwipeActionsConfiguration, UIContextualAction, UITableViewDiffableDataSource
  and UICollectionViewDiffableDataSource derive from NSObject, as UIKit's do.
* The in-repo conformers now derive from NSObject: SceneBuilder's drivers,
  SwiftUI's scroll coordinator, the page view controller's private delegate
  and 27 test classes. Real apps' conformers already do, because UIKit
  requires it.
  * SceneBuilder must not import Foundation, so it uses a scoped
    `ObjectiveC.NSObject` import.
  * On Linux these classes get an empty base class.
* UIKitObjCSupport.h:
  * adds `UITableViewAutomaticDimension` (-1);
  * keeps `UITextViewDelegate` without its UIScrollViewDelegate refinement.
    Refining the generated protocol through a forward declaration compiles,
    but the link fails because Swift does not export the protocol object
    (**measured**: undefined `__OBJC_PROTOCOL_$_UIScrollViewDelegate`).
* OpenUIKitObjCBridge twins: UIScrollView `delegate`, `zoomScale`,
  `minimum/maximumZoomScale`, `setZoomScale:animated:`; UITableView
  `dataSource`, `rectForRowAtIndexPath:`.

## Verification

* `Tests/ObjCProtocolTests`, 4 tests:
  * the scroll and table scenarios match iOS 26.1;
  * UIKit names, SDK selectors and the required/optional split (read through
    `protocol_getMethodDescription`);
  * NetNewsWire's shapes.
  * Before the change the fixture did not compile: no `delegate`/`dataSource`
    Objective-C properties, and no generated protocols.
* Full `swift test`, 2013 tests: the failing set is exactly main's (12
  classes). No new failures.
* Census, main → branch:
  * Simplenote Objective-C half: 847 → **841**.
  * eidolon pods: 507 → 507 (they do not depend on these protocols).

## Open (next increments, by corpus demand)

* **UICollectionViewDelegateFlowLayout** is still a Swift protocol refining
  the `@objc` UICollectionViewDelegate. Its requirements use OpenUIKit's
  `UIEdgeInsets` struct and `UICollectionViewLayout`, a class not derived
  from NSObject. Both must become Objective-C types first.
* **UITextViewDelegate / UITextFieldDelegate** carry UITextItem, UIMenu,
  UIContextMenuInteractionAnimating and OpenUIKit's NSTextAttachment. The
  support header's text-view protocol then regains its scroll refinement.
* **Also next:** UINavigationControllerDelegate, UIGestureRecognizerDelegate
  and the rest, in `full/ladder` census order.
* **netnewswire-first-screen's branch** adds 7 collection and 3 table members
  to these protocols. Whichever branch reaches main second converts them to
  SDK-named optional requirements.
