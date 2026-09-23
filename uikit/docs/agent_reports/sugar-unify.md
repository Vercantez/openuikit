# sugar-unify: one declaration per Foundation / Objective-C name

## Problem

MEASURED with two-module scratch experiments and with `uikit/Tests/NameUnifyTests` before this change: if a client can see a second declaration of a name, Swift stops folding `[X]()` / `[K: X]()` into a type. That includes a `public typealias X = Foundation.X`, which names the very same type. The error is "cannot call value of non-function type '[X.Type]'". App files import UIKit together with Foundation, so every name OpenUIKit shares with Foundation or the Objective-C runtime has to reach them through one declaration.

## Change

OpenUIKit re-exports the Apple declaration with a scoped `@_exported import <kind> Foundation.X` instead of aliasing it. Each name keeps the `#if` condition its alias had. The names are:

- IndexPath, IndexSet, TimeInterval, NSCoder, Bundle
- NSIndexPath
- Notification, NSNotification, NotificationCenter (the last needs Foundation && ObjectiveC)
- OperationQueue
- Selector (`ObjectiveC.Selector`)
- NSRangePointer, which the scan found

The UIKit shim drops its Notification, NSNotification, NotificationCenter and OperationQueue aliases. It keeps NotificationCenter only where there is no Objective-C: on native Linux, OpenUIKit's selector-registry center is a different class from corelibs'.

The CG / QuartzCore names belong to cg-unify phase 4. NSAttributedString and NSRange were already re-exported by NetNewsWire's increment (e26fffec).

### Imports are per file

Every OpenUIKit file that uses one of these names gets its own guarded scoped import, in the `MARK: sugar-unify scoped imports` block at the top.

Those imports are `@_exported` too, because of a swiftc behaviour MEASURED in `aliastest6`. Suppose a plain `import class A.C` comes, in the module's file order, before the file holding `@_exported import class A.C`. Then a client that imports only the module cannot find `C`. When every scoped import is `@_exported`, the order doesn't matter, and the collection sugar still folds (`aliastest7`). This applies to Timer and RunLoop as well.

## Tests (`uikit/Tests/NameUnifyTests`)

- **Sugar test per name:** Foundation names, `Selector`, and the ones already unified (NSRange, NSAttributedString, Timer, RunLoop).
  - Before the change, the build failed for IndexPath, IndexSet, TimeInterval, NSCoder, Bundle, NSIndexPath, Notification, NSNotification, NotificationCenter, OperationQueue and Selector.
- **Identity:** `OpenUIKit.X.self == Foundation.X.self`.
- **Scan:** `testNoClientVisibleAliasOfAFoundationName` goes through `Sources/OpenUIKit` and `Sources/UIKitShim`. It looks for top-level public or open typealiases that can be live on Darwin with Foundation (it evaluates `#if` with three-valued logic). An alias fails the test if it meets any of these:
  - its target is qualified by Foundation, FoundationEssentials, ObjectiveC, CoreFoundation, Dispatch or Darwin;
  - its name is an Objective-C class from Foundation, CoreFoundation or libobjc;
  - its name is one of the unified value-type names.

  A second test checks the scanner itself on a synthetic source.

## Pre-existing failures, identical on origin/main 7b1b89e1

- `FoundationCoexistenceTests.testRenderPathReadsNoWallClockLocaleOrRandomSource`: CFAbsoluteTimeGetCurrent in UIApplicationMainEntry, and UUID() in UIEditMenuInteraction.
- `TextFieldDelegateTests` (2 tests)
- `UIButtonConfigurationTests.testAttributedTitleFontAndColourWin`
- `UISearchBarTests.testMeasuredFieldFrame`
