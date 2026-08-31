# SwiftUI application lifecycle planning proof

This proof advances an untouched modern SwiftUI application past the
UIKit-delegate-only entry-point gate. It is intentionally a planner and host
compiler proof; no Docker or guest execution is part of this slice.

## Frozen inputs

- OpenUIKit lifecycle implementation: commit
  `24af7208342b42815b345c378af439f52286cf63`, tree
  `d08fffbf1da0aa5bf13fc2ca3f5ab7751dd3112a`.
- Hackers source: commit `83016de256ef5418f76ec53182d25e302a519234`,
  tree `7155d4ac47b2ecde906d0f438033ad18c6182143`.
- Prepared Hackers inventory SHA-256:
  `c0a2b2660e78451de459c056f8fdebd9c3282eeff1be55b12f9e619dbd012d28`.

The Hackers checkout was clean before and after every command. No application
source or project file was edited.

## Exact plan

Running `application_build_plan.py` against the 13-source inventory succeeds
and its independent `--verify` pass succeeds:

```text
APPLICATION_BUILD_PLAN_OK sources=13 compiler_inputs=0 resource_files=10 sha256=4b9253d54dca017784654c3fcd4ad127a587f818990eb6104d9771caead77374
APPLICATION_BUILD_INPUTS_OK sources=13 compiler_inputs=0 resources=5
```

The branch-specific bootstrap record is:

```text
entry_point: swiftui-app-default-main
module: Hackers2
swiftui_app.path: App/HackersApp.swift
swiftui_app.type: HackersApp
swiftui_app.sha256: d8b4cf026d2cd8f00b6fdffff070104de2526308997e3e308a2fbf0495bbaad3
info_plist.path: App/Supporting Files/Hackers-Info.plist
info_plist.sha256: 00984f0d4e0e110ed0a9a28e32d07e48c90a61083256c9237a74729e25706a45
generated_size: 111
generated_sha256: 2ac6bd64b9fab820e0124e64b1d03fc36b317a73afebc70937000ebfa2aeec8e
```

The complete generated Swift input is one comment:

```swift
// Generated build input: HackersApp inherits SwiftUI.App's default main; no competing entry point is emitted.
```

It contains no `@main`, extension, `static main`, delegate construction, or
UIKit scene bootstrap. The application receives its only entry point from
SwiftUI's production `App.main()` implementation.

## Exact next compiler diagnostic

The planned source manifest was passed byte-for-byte to Apple Swift 6.2.1 in
Swift 6 mode with `-parse-as-library`, Xcode's app-target main-actor default,
and the OpenUIKit/SwiftUI modules built from the lifecycle commit. Compilation
now reaches target dependency resolution and stops at:

```text
App/AppDelegate.swift:8:8: error: no such module 'Data'
 6 | //
 7 |
 8 | import Data
   |        `- error: no such module 'Data'
 9 | import Shared
10 | import UIKit
```

This is the next honest platform boundary. `Data` is a local Hackers package
target, not a missing first-party framework and not a SwiftUI lifecycle
diagnostic. The next application-planning slice must inventory, order, and
build transitive local package/target modules before compiling the app target.
