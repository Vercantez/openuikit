# HealthKitUI

Linux starting point for Apple's public `HealthKitUI` module, reconstructed
from the pinned Xcode 26.1 iPhoneOS symbol graph. Isolated host-gate success
is not integrated Linux success.

## Depth pass 2026-09

SDK depth for `HealthKitUI` in `full/healthkitui/` (8 exact IDs). This is a
fresh seed: every public identifier is implemented with a focused synchronous
test. There are no enum or option-set members, so no table-driven value
sharing.

Coverage this round: **8 implemented / 0 declared / 8 total**
(8 nondeferred, floor 7). No test is cited by more than one implemented row
(12.5% of implemented rows).

Top-5 implemented evidence:

| Rows | Share | Evidence |
| ---: | ---: | --- |
| 1 | 12.5% | `HKActivityRingViewTests.swift#testHKActivityRingViewClass` |
| 1 | 12.5% | `HKActivityRingViewTests.swift#testActivitySummaryProperty` |
| 1 | 12.5% | `HKActivityRingViewTests.swift#testSetActivitySummaryAnimated` |
| 1 | 12.5% | `HealthKitUIAccessTests.swift#testAuthorizationViewControllerPresenter` |
| 1 | 12.5% | `HealthKitUIAccessTests.swift#testHealthDataAccessRequestShareTypes` |

The remaining three implemented rows each have their own test
(`testHealthDataAccessRequestReadTypes`,
`testHealthDataAccessRequestObjectType`,
`testShouldHandleActiveWorkoutRecovery`).

Environment: `swiftc` reports Swift 6.2.4, target `x86_64-unknown-linux-gnu`.
`.cursor/verify-cloud-environment.sh` did not emit
`CURSOR_SWIFT_ENVIRONMENT_OK` because `scratch/ladder-corpus/focus-ios` is
absent on this VM. The sealed gate compiles with a clean product tree
(`products=clean`). Active Cursor Build observed on this run was
`bld-20260906-253cd433-7a30-4d11-aad2-8b209b7b2d21` (campaign expected
`bld-20260901-d3266600-d87b-438f-94c1-d1aa48036e87`). Starting commit
`2abc9defd72942e7a24dcc79779ea5c50e67d75c` matched.

`bash full/healthkitui/tests/acceptance/test_host.sh` ended:

```
FRAMEWORK_FANOUT_DELIVERABLE_OK module=HealthKitUI lane=leaf-full symbols=8
FRAMEWORK_FANOUT_REFERENCE_OK
HEALTHKITUI_AGENT_RUNTIME_OK
FRAMEWORK_FANOUT_HOST_OK module=HealthKitUI dylib=libHealthKitUI.dylib
```

The campaign inventory stamp `CURSOR_SWIFT_ENVIRONMENT_OK swift=6.2.4 target=linux products=clean` is a host-inventory token, not printed by the sealed framework gate. `swiftc` is Swift 6.2.4 / linux and the gate compiled with a clean product tree.

### What is real

- `HKActivityRingView` is a `UIView` subclass with designated
  `init(frame:)`. Fresh `activitySummary` is `nil`. The property setter
  stores object identity and treats the write as `animated: false`.
- `setActivitySummary(_:animated:)` stores the summary and the `animated`
  flag. Linux never draws Move/Exercise/Stand rings.
- `HKHealthStore.authorizationViewControllerPresenter` is a weak
  `UIViewController?` that defaults to `nil` and round-trips the stored
  presenter. Assigning it does not present a sheet.
- The three `View.healthDataAccessRequest` overloads return `self`, retain
  the completion, and record share/read/object-type/predicate counts. Applying
  the modifier does not invoke the completion.
- `UIScene.ConnectionOptions.shouldHandleActiveWorkoutRecovery` is `false`.

### Fail-closed boundaries

- `HealthKitUIHostControl.failClosedPendingAccessRequests` invokes retained
  completions with `HealthKitUIUnavailable.linuxHost(operation:
  "View.healthDataAccessRequest")`. Linux never reports `.success` and never
  shows an authorization sheet.
- Setting `authorizationViewControllerPresenter` does not call HealthKit
  `requestAuthorization` and does not mutate authorization status.
- `shouldHandleActiveWorkoutRecovery` never claims an active workout session
  to recover.

### Still deferred / unobserved

See `oracle-questions.tsv` for Apple-oracle probes: ring-view defaults and
animation, presenter timing, access-request queue/trigger observation,
workout-recovery payload keys, and version-number bytes.
