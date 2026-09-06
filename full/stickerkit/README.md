# StickerKit (Linux starting point)

This directory is a fail-closed portable `StickerKit` module for the
OpenUIKit Linux platform. It reconstructs the public Xcode 26.1 iPhoneOS
26.1 Swift surface from the sealed symbol graph. It is not wired into the
shared guest package; a passing isolated host gate is not Apple avatar
editing, Messages sticker UI, or Live Photo layout.

Coverage: **8 implemented / 0 declared / 1 unavailable / 9 total**, meeting
the leaf-full floor of 8 nondeferred identifiers (`ceil(80% of 9)`).

## Depth pass 2026-09

Fresh seed: `full/stickerkit/` had `AGENTS.md`, `FANOUT_TASK.md`, and
`reference/` only. After this pass: **8 implemented / 0 declared /
0 deferred / 1 unavailable / 0 not-applicable**.

Top-5 implemented evidence distribution (8 implemented rows; each
non-enum identifier has its own test; no test is cited more than once):

| rows | share | evidence |
| ---: | ---: | --- |
| 1 | 12.5% | `AvatarEditorViewControllerTests.swift#testAvatarEditorViewControllerIsNSObjectSubclass` |
| 1 | 12.5% | `AvatarEditorViewControllerTests.swift#testAvatarEditorViewControllerInitCoderFailsClosed` |
| 1 | 12.5% | `AvatarEditorViewControllerTests.swift#testAvatarEditorViewControllerInitNibNameRecordsBundle` |
| 1 | 12.5% | `AvatarEditorViewControllerTests.swift#testAvatarEditorViewControllerViewDidLoadMarksLoadedWithoutPresenting` |
| 1 | 12.5% | `AvatarEditorViewControllerTests.swift#testAvatarEditorViewControllerViewWillAppearRecordsAnimatedWithoutPresenting` |

The remaining three implemented rows each have their own test (weak
delegate storage, protocol conformance, host-delivered dismiss). The
PhotosUI overlay is `unavailable` rather than bulk-relabeled.

Environment: `swiftc` reports Swift 6.2.4, target
`x86_64-unknown-linux-gnu`. `.cursor/verify-cloud-environment.sh` did
not emit `CURSOR_SWIFT_ENVIRONMENT_OK` because
`scratch/ladder-corpus/focus-ios` is absent on this VM (a prior main-branch
verify wiped `scratch/`). The sealed gate compiles with a clean product
tree (`products=clean`). Active Cursor Build observed on this run was
`bld-20260906-253cd433-7a30-4d11-aad2-8b209b7b2d21` (campaign expected
`bld-20260901-d3266600-d87b-438f-94c1-d1aa48036e87`). Starting commit
`cbb368eeea236bbc0479fefa599190972ac8cfca` matched.

The campaign inventory stamp
`CURSOR_SWIFT_ENVIRONMENT_OK swift=6.2.4 target=linux products=clean`
is a host-inventory token, not printed by the sealed framework gate.

## What is real

- `AvatarEditorViewController` is an `NSObject` host (Darwin inherits
  `UIKit.UIViewController`; UIKit is not a declared dependency).
- `init(nibName:bundle:)` stores the Foundation `String?` / `Bundle?`
  arguments and does not load a nib.
- `init(coder:)` always returns `nil`.
- `viewDidLoad()` sets a process-local loaded flag and does not create a
  view hierarchy or attach `AvatarEditorRemoteViewController`.
- `viewWillAppear(_:)` records the animated flag and call count. It does
  not load the view as a side effect and does not invoke the delegate.
- `delegate` is zeroing-weak `(any AvatarEditorViewControllerDelegate)?`.
- `AvatarEditorViewControllerDelegate` inherits `NSObjectProtocol` and
  requires `avatarEditorRemoteViewControllerShouldDismiss()`. Linux never
  auto-delivers that call; tests invoke it directly or through
  `@_spi(OpenUIKitHost)` `hostDeliverRemoteViewControllerShouldDismiss()`.

## Fail-closed boundaries

- Linux never presents Apple's avatar editor, never talks to a Messages /
  Stickers remote view-controller process, and never claims a successful
  Live Photo layout.
- `linuxDidPresentAppleAvatarEditor` and `linuxDidLoadRemoteViewController`
  are always `false`.
- `PHLivePhotoView.intrinsicContentSize` is `unavailable`: the overlay
  extends `PhotosUI.PHLivePhotoView` (not a StickerKit type) and returns
  `CoreFoundation.CGSize`. PhotosUI is not a declared dependency; there is
  no local `PHLivePhotoView` substitute.
- `@MainActor` / `@objc` / `dynamic` / `override` attributes are omitted
  so the sealed runner (no run loop, no ObjC UIKit base) can call the
  surface synchronously.

## Oracle questions

See `oracle-questions.tsv` for coder-archive keys, remote dismiss timing,
`viewWillAppear` child-controller attachment, Live Photo intrinsic size,
and entitlement / XPC requirements.
