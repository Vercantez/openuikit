# SafariServices for Objective-C: the Clang module and SFSafariViewController

**Date:** 2026-09-23
**Branch:** `agent/safari-objc` (from main e6fdc777)

## The wall

NetNewsWire ships an Objective-C category, `SFSafariViewController+Extras.h/.m`,
that wraps `-initWithURL:` in `@try/@catch`. The bridging header imports it,
and the Swift side calls it at `WebViewController.swift:935` and
`MainFeedCollectionViewController.swift:678`.

On the iOS triple, target `NetNewsWireObjC` failed with **7 errors**
(reproduced with a one-target `spm_app_chain` + `chain_census --ios-target`
package):
* `NS_ASSUME_NONNULL_BEGIN`/`END` were unknown, and so were `nil` and
  `NSException`.
* The build reported "no visible @interface for 'SFSafariViewController'
  declares the selector 'initWithURL:'".

There were two causes:
1. `@import SafariServices;` resolved to SwiftPM's generated module map for
   the Swift target. That map has no `export *`, so Foundation was loaded but
   not visible to the importer.
2. The Swift class exported no `-initWithURL:`.

## Measured on the iOS 26.1 simulator (`Tools/oracle2/safariobjcprobe`)

The same Objective-C scenario runs on both sides (`transcript-ios26.1.txt`):
* The superclass is UIViewController, and the runtime name is
  `SFSafariViewController`.
* `-initWithURL:` accepts **http and https only**, in either case. It raises
  **`NSInvalidArgumentException`** for file, mailto, feed, about, a custom
  scheme, and a string with no scheme.
* A category's `@try/@catch` wrapper returns nil for a rejected URL.
* Default `dismissButtonStyle` is **1 (`.close`)**. The port said `.done`;
  the painted glyph is `xmark` either way.
* Default configuration: `entersReaderIfAvailable` NO, `barCollapsingEnabled`
  YES.

## Change

* **Swift `SafariServices`** (Apple builds):
  * `SFSafariViewController` has UIKit's runtime name.
  * It exports `initWithURL:`, `initWithURL:configuration:`,
    `configuration` and `dismissButtonStyle`.
  * `Configuration` is `SFSafariViewControllerConfiguration`, and the enum is
    `SFSafariViewControllerDismissButtonStyle`.
  * A URL whose scheme isn't http or https raises `NSInvalidArgumentException`,
    as measured. Portable builds have no Objective-C exceptions and accept
    the URL.
  * The default `dismissButtonStyle` is now `.close`.
* **New Clang target `SafariServicesObjC`** (product `SafariServicesObjC`):
  * **What it is:** a module named `SafariServices` with `export *`, like the
    SDK framework module. It re-exports Foundation and OpenUIKit's Objective-C
    interfaces, and declares the Swift classes with the generated header's
    `external_source_symbol(defined_in="SafariServices", generated_declaration)`.
    As a result, Swift (an app's bridging header) resolves them to the Swift
    classes, and an Objective-C category attaches to the Swift class.
  * **Swift importers:** Swift has no Clang module `OpenUIKit`, so under
    `__swift__` the header declares the UIResponder/UIViewController chain as
    OpenUIKit's generated declarations instead.
  * **OpenUIKit in the product:** OpenUIKit is part of the product because
    SwiftPM orders a Clang target only after its **direct** Swift
    dependencies' generated headers. **Measured:** "OpenUIKit-Swift.h not
    found" without it.
* **`spm_app_chain.py`**: an Objective-C target (C-family sources, no Swift)
  that lists `SafariServices` gets the `SafariServicesObjC` product. It also
  gets the generated-header define pair every Clang consumer of OpenUIKit
  gets, as in `xcodeproj_to_package.py`.
  **Measured:** without that pair, UIViewController is
  `objc_subclassing_restricted` for the consumer.

## Verification

* **NetNewsWireObjC** (iOS triple, one-target chain census): **7 errors → 0,
  passed.**
* **`Tests/SafariObjCTests`** (3 tests):
  * The Objective-C scenario matches iOS 26.1 line for line, including the
    exception raised through `-initWithURL:` and caught by the category.
  * NetNewsWire's Swift shape: `SFSafariViewController.ouk_safeSafariViewController(url)`
    is a class method on the Swift class that returns it, and
    `.overFullScreen` can be set.
  * Every method the Clang header declares exists on the Swift class.
  * Before the change the fixture didn't compile.
* **`test_spm_app_chain`**: 10 tests, including the new product mapping and
  define pair.
* **`swift test`**: no new failures; the failing set is a subset of main's.

## Open

* The same pattern will be needed for other frameworks an app's Objective-C
  imports as a module (`OBJC_MODULE_PRODUCTS` in `spm_app_chain.py`).
* `SFSafariViewControllerDelegate` isn't an `@objc` protocol. Its methods use
  UIActivity, which isn't an Objective-C type.
* NetNewsWire's Swift app target, which reaches this code through the
  bridging header, is re-censused on netnewswire-launch's side.
