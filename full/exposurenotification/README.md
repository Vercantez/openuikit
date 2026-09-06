# ExposureNotification (Linux starting point)

This directory is a fail-closed portable `ExposureNotification` module for the
OpenUIKit Linux platform. It reconstructs the public Xcode 26.1 iPhoneOS
Swift surface from the sealed symbol graph. It is not wired into the shared
guest package; that integration is a separate central review step.

Coverage: **264 implemented / 0 declared / 0 deferred / 264 total**
(fully nondeferred, above the medium-full floor of 132).

## What is real

- `ENError` / `ENErrorDomain` / `ENError.Code` with NS_ERROR_ENUM integers
  `unknown = 1` through `travelStatusNotAvailable = 17`, matching API-digester
  child order. Typed construction, `userInfo`, equality, hashing, `NSError`
  bridging, and `~=` matching are exercised.
- Authorization, status, calibration, infectiousness, diagnosis-report, and
  variant-of-concern enums with sequential raw values, plus `ENActivityFlags`
  as a `UInt32` `OptionSet` (`reserved1 = 1<<0` … notification-tapped = `1<<3`).
- Range constants corroborated by the objc2-exposure-notification bindings
  generated from Apple's `ENCommon.h` (`ENAttenuationMin = 0`,
  `ENAttenuationMax = 0xFF`, `ENRiskLevelMax = 7`, `ENRiskScoreMax = 255`,
  `ENRiskWeightDefault = 1`, `ENRiskWeightDefaultV2 = 100`,
  `ENRiskWeightMaxV2 = 250`).
- `ENExposureConfiguration` stores every documented scoring field. V1
  level-value arrays default to eight `1`s; V1 weights default to
  `ENRiskWeightDefault`; V2 weights default to `ENRiskWeightDefaultV2`;
  `attenuationDurationThresholds` defaults to `[50, 70]`.
- Result types (`ENTemporaryExposureKey`, `ENScanInstance`, `ENExposureWindow`,
  `ENExposureInfo`, `ENExposureSummaryItem`, `ENExposureDaySummary`,
  `ENExposureDetectionSummary`) store and return the fields the graph lists.
  `ENTemporaryExposureKey.rollingPeriod` defaults to 144.
- `ENManager` is constructible. `authorizationStatus` is `.restricted`.
  `exposureNotificationEnabled` is `false`. `exposureNotificationStatus` is
  `.unknown` until `invalidate()`. Completions are invoked on the caller
  thread.

## Fail-closed boundaries

Linux has no Exposure Notification daemon, Bluetooth TEK radio, EN
entitlement, or privacy prompt.

- `activate` and every diagnosis-key / detection / pre-auth method complete
  with `ENError.unsupported` (or `.invalidated` after `invalidate()`). They
  never claim a match, never return keys, and never enable EN.
- `getUserTraveled` completes with `travelStatusNotAvailable` (the documented
  error for that API) while the manager is live, and `.invalidated` after
  `invalidate()`.
- `setExposureNotificationEnabled` never flips `exposureNotificationEnabled`.
- `activityHandler` / `diagnosisKeysAvailableHandler` can be stored and
  invoked by tests; the daemon never fires them.
- `ENErrorOutType` is `UnsafeMutablePointer<NSError?>` because Linux Swift
  has no `AutoreleasingUnsafeMutablePointer`.
- Delegate/queue hops are unobserved. Fail-closed completions are delivered
  synchronously so the sealed runner (no run loop) can observe them.

## Depth pass 2026-09

Fresh seed: no prior implemented/declared split. After this pass:
**264 implemented / 0 declared / 0 deferred**.

Top-5 implemented evidence distribution:

| Citations | Evidence |
| ---: | --- |
| 36 | `ExposureNotificationErrorTests.swift#testENErrorCodeRawValues` |
| 13 | `ExposureNotificationConstantTests.swift#testENRangeConstants` |
| 13 | `ExposureNotificationConstantTests.swift#testENTypealiases` |
| 11 | `ExposureNotificationResultTypeTests.swift#testENExposureInfoProperties` |
| 10 | `ExposureNotificationEnumTests.swift#testENStatusRawValues` |

`testENErrorCodeRawValues` is a table-driven enum-member and static
`ENError.*` code test. `testENRangeConstants` is a table-driven C
min/max/weight constant test. Status raw values are a table-driven enum
test. Configuration/result and manager tests cover distinct non-enum
families and stay well under the 40% bulk-relabel bound.

The sealed host gate was run as `bash full/exposurenotification/tests/acceptance/test_host.sh`
and ended:

```
FRAMEWORK_FANOUT_DELIVERABLE_OK module=ExposureNotification lane=medium-full symbols=264
FRAMEWORK_FANOUT_REFERENCE_OK
EXPOSURENOTIFICATION_AGENT_RUNTIME_OK
FRAMEWORK_FANOUT_HOST_OK module=ExposureNotification dylib=libExposureNotification.dylib
```

`swiftc --version` is Swift 6.2.4 targeting `x86_64-unknown-linux-gnu`.
`.cursor/verify-cloud-environment.sh` does not print
`CURSOR_SWIFT_ENVIRONMENT_OK swift=6.2.4 target=linux products=clean` on this
snapshot (`scratch/ladder-corpus/focus-ios` is missing). That campaign token
is the host-inventory stamp; the sealed framework gate prints the four lines
above.
