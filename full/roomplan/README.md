# RoomPlan (Linux starting point)

This directory is a fail-closed portable `RoomPlan` module for the OpenUIKit
Linux platform. It reconstructs the public Xcode 26.1 iPhoneOS Swift surface
from the sealed symbol graph. It is not wired into the shared guest package;
that integration is a separate central review step.

Coverage: **479 implemented / 2 declared / 0 deferred / 481 total**
(above the large-partitioned floor of 50).

## What is real

- Attribute enums (`ChairType`, `ChairLegType`, `ChairArmType`, `ChairBackType`,
  `SofaType`, `TableType`, `TableShapeType`, `StorageType`) with String raw
  values matching case names, `allCases` in API-digester order, `parentCategory`
  scoped to the matching `CapturedRoom.Object.Category`, and `shortIdentifier`
  equal to `rawValue`.
- `CapturedRoom.Object.Category.supportedAttributeTypes` /
  `supportsCombination(_:)` / `supportedCombinations` for chair, table, sofa,
  and storage families; other categories have empty combination tables.
- `CapturedRoom.ModelProvider` URL bookkeeping: existing files can be associated
  with a category or a supported attribute combination; missing files throw
  `nonExistingFile(url:)`; unsupported mixes throw
  `attributeCombinationNotSupported`.
- Export URL validation (`file` scheme, non-empty path, USD-like extension)
  then **deviceNotSupported**. No USDZ bytes are written.
- `RoomCaptureSession.isSupported == false`. `run(configuration:)` never starts
  scanning: it delivers `didEndWith` on the caller thread with
  `deviceNotSupported`, or `invalidARConfiguration` if the client replaced
  `arSession`. `isCoachingEnabled` defaults to `true`.
- Value-type Codable round trips for `CapturedRoom`, surfaces, objects,
  sections, `CapturedStructure`, `CapturedRoomData`, and attribute records.
- Option sets: `USDExportOptions` bits `1/2/4` (parametric/mesh/model) and
  `RoomBuilder.ConfigurationOptions.beautifyObjects = 1`.

## Fail-closed boundaries

Linux has no LiDAR scanner, RoomPlan daemon, ARKit world tracking, or Apple USD
exporter.

- `RoomBuilder.capturedRoom(from:)` and `StructureBuilder.capturedStructure(from:)`
  throw `deviceNotSupported` (empty structure input throws `insufficientInput`).
  Those two async identifiers are **declared**, not implemented: the sealed
  runner has no run loop and cannot `await`.
- `RoomCaptureView` is an `NSObject` stand-in (UIKit is not a declared
  dependency). `init(coder:)` returns `nil`, `subviews` is empty, layout and
  trait callbacks are no-ops, and no miniature model is rendered.
- `ARSession` is `NSObject`. Camera/world-tracking success is never invented.
- Delegate delivery is synchronous on the caller so tests can observe it
  without a run loop. Apple's queue hop is an oracle question.

## Depth pass 2026-09

Fresh seed: no prior sources, coverage, or agent tests. After this pass:
**479 implemented / 2 declared / 0 deferred**.

Top-5 implemented evidence distribution:

| Citations | Evidence |
| ---: | --- |
| 23 | `RoomPlanEnumTests.swift#testObjectCategoryAllCases` |
| 20 | `RoomPlanOptionSetTests.swift#testConfigurationOptionsAlgebra` |
| 16 | `RoomPlanAttributeTests.swift#testAttributeInequalityAndHash` |
| 15 | `RoomPlanErrorTests.swift#testLocalizedErrorOptionals` |
| 15 | `RoomPlanDelegateTests.swift#testSessionDelegateDefaults` |

`testObjectCategoryAllCases` is a table-driven enum-member test.
`testConfigurationOptionsAlgebra` covers OptionSet protocol methods on the
single `beautifyObjects` flag (well under the 40% bulk-relabel bound on the
remaining non-member rows). LocalizedError optionals and session-delegate
defaults are distinct non-enum families.

The sealed host gate was run as `bash full/roomplan/tests/acceptance/test_host.sh`
and ended:

```
FRAMEWORK_FANOUT_DELIVERABLE_OK module=RoomPlan lane=large-partitioned symbols=481
FRAMEWORK_FANOUT_REFERENCE_OK
ROOMPLAN_AGENT_RUNTIME_OK
FRAMEWORK_FANOUT_HOST_OK module=RoomPlan dylib=libRoomPlan.dylib
```

`swiftc --version` is Swift 6.2.4 targeting `x86_64-unknown-linux-gnu`.
`.cursor/verify-cloud-environment.sh` does not print
`CURSOR_SWIFT_ENVIRONMENT_OK swift=6.2.4 target=linux products=clean` on this
snapshot (`scratch/ladder-corpus/focus-ios` is missing). That campaign token
is the host-inventory stamp; the sealed framework gate prints the four lines
above. Swift 6.2.4 / linux compiled `libRoomPlan.dylib` with a clean product
tree.
