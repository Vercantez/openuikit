# CoreAudioKit (Linux starting point)

This directory is a clean-room Linux starting point for Apple's public
`CoreAudioKit` module, seeded from the Xcode 26.1 iPhoneOS 26.1 symbol
graph, API digester, TBD exports, and pinned `dotnet/macios`
`src/coreaudiokit.cs`. It is not wired into the shared guest package;
that integration is a later central-review step.

The isolated host compiler has Foundation only. Product sources may
`import Foundation` and, when present, the real `AudioToolbox` and
`UIKit` modules. Types owned by those dependencies are module-local
lookalikes behind `#if !canImport(...)` so the overlay can compile.
They compile out when the real modules are on the link line and are not
substitutes for listed dependencies.

## Depth pass 2026-09

Fresh seed: `full/coreaudiokit/` had `AGENTS.md`, `FANOUT_TASK.md`, and
`reference/` only. This pass implements all **46** exact public
identifiers with focused synchronous tests (acceptance floor 23
nondeferred).

Coverage: **46 implemented / 0 declared / 0 deferred / 0 unavailable /
0 not-applicable** (46 nondeferred, floor 23).

Top-5 implemented evidence (46 rows; 40% cap of remaining non-enum rows
= 18; no enum/option-set members in this surface):

| Rows | Share | Evidence |
| ---: | ---: | --- |
| 1 | 2.2% | `AUAudioUnitViewConfigurationTests.swift#testAUAudioUnitViewConfigurationClass` |
| 1 | 2.2% | `AUAudioUnitViewConfigurationTests.swift#testAUAudioUnitViewConfigurationInit` |
| 1 | 2.2% | `AUAudioUnitViewConfigurationTests.swift#testAUAudioUnitViewConfigurationWidth` |
| 1 | 2.2% | `AUAudioUnitViewConfigurationTests.swift#testAUAudioUnitViewConfigurationHeight` |
| 1 | 2.2% | `AUAudioUnitViewConfigurationTests.swift#testAUAudioUnitViewConfigurationHostHasController` |

Every other implemented row cites its own `test*` function (1 row /
2.2% each). No test is cited by more than one identifier.

Environment: `swiftc` reports Swift 6.2.4, target
`x86_64-unknown-linux-gnu`. `.cursor/verify-cloud-environment.sh` did
not emit `CURSOR_SWIFT_ENVIRONMENT_OK` because
`scratch/ladder-corpus/focus-ios` is absent on this VM. The sealed gate
compiles with a clean product tree (`products=clean`). Active Cursor
Build observed on this run was
`bld-20260906-253cd433-7a30-4d11-aad2-8b209b7b2d21` (campaign expected
`bld-20260901-d3266600-d87b-438f-94c1-d1aa48036e87`). Starting commit
`2abc9defd72942e7a24dcc79779ea5c50e67d75c` matched.

`bash full/coreaudiokit/tests/acceptance/test_host.sh` is the sealed
gate. Expected markers:

```
FRAMEWORK_FANOUT_DELIVERABLE_OK module=CoreAudioKit lane=medium-full symbols=46
FRAMEWORK_FANOUT_REFERENCE_OK
COREAUDIOKIT_AGENT_RUNTIME_OK
FRAMEWORK_FANOUT_HOST_OK module=CoreAudioKit dylib=libCoreAudioKit.dylib
```

The campaign inventory stamp
`CURSOR_SWIFT_ENVIRONMENT_OK swift=6.2.4 target=linux products=clean`
is a host-inventory token, not printed by the sealed framework gate.
`swiftc` is Swift 6.2.4 / linux and the gate compiled with a clean
product tree.

### What is real

- `AUAudioUnitViewConfiguration` stores `width`, `height`, and
  `hostHasController` from `init(width:height:hostHasController:)` as
  get-only properties and round-trips them through `NSSecureCoding`.
- `AUGenericViewInternal` is a `UIView` (`AUGenericViewInternalBase`)
  that stores `auAudioUnit`, `owningController`, `paramObserverToken`,
  and `showSingleClumpIndex`. Collection-view will-display methods
  record the last index path / element kind. `removeScheduledUpdatesTimer()`
  clears a host-armed scheduled flag and does not fire a `Timer`.
  `removeFromSuperview()` also clears that flag.
- `AUAppleCustomViewLoader.customViewController(for:audioUnit:v3AU:)`
  always returns `nil`.
- `AUAudioUnit.requestViewController(completionHandler:)` calls the
  handler synchronously with `nil`. `supportedViewConfigurations(_:)`
  returns an empty `IndexSet`. `select(_:)` records the configuration
  for host inspection.
- `AUViewController` / `AUGenericViewController` construct as
  `UIViewController` subclasses. `auAudioUnit` get/set stores the unit
  and does not layout parameter chrome.
- `CABTMIDICentralViewController` / `CABTMIDILocalPeripheralViewController`
  construct; discovered-peripheral count is 0 and advertising is false.
- `CAInterAppAudioSwitcherView` stores `isShowingAppNames` and the last
  output `AudioUnit`. `contentWidth()` is always `0` (no IAA apps).
- `CAInterAppAudioTransportView` stores `isEnabled` and color/font
  properties. `isConnected`, `isPlaying`, and `isRecording` are always
  false. Linux color/font defaults are host placeholders (white/red,
  system 12pt), not claimed Apple RGB values.

### Fail-closed boundaries

- No Audio Unit custom view, generic parameter chrome, or remote AUv3
  view controller is created.
- No Inter-App Audio connection, transport clock, or peer-app switcher
  icons.
- No Bluetooth MIDI scan or local-peripheral advertisement.
- No parameter-observer registration when `auAudioUnit` is assigned.
- Isolated-host UIKit / AudioToolbox lookalikes are compile shims, not
  guest UIKit or AudioToolbox.

Unresolved questions live in `oracle-questions.tsv`.
