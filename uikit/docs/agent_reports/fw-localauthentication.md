# LocalAuthentication SDK depth (agent/fw-localauthentication)

Coverage before: **0 implemented / 233 declared / 14 deferred**.
Coverage after: **234 implemented / 0 declared / 13 deferred**.

Target was fully nondeferred and implemented ≥ 200. Thirteen identifiers
still require undeclared dependencies (Security `SecAccessControl` /
`SecKeyAlgorithm`, Combine `ObservableObjectPublisher`) and stay deferred
with notes. `LAAuthenticationView` is not in the iPhoneOS 26.1 module
graph (247 IDs).

## Measurements (2026-09-05)

Mac probe `/tmp/la-oracle.swift` against SDK LocalAuthentication
(Xcode 26.1 / macOS 26.0):

| symbol | value |
|---|---|
| `LAErrorDomain` / `kLAErrorDomain` | `com.apple.LocalAuthentication` |
| `LATouchIDAuthenticationMaximumAllowableReuseDuration` | `300.0` |
| default reuse property | `0.0` |
| assigning `10000` to the reuse property | reads back `10000.0` (not clamped on set) |
| `LABiometryType` | none 0, touchID 1, faceID 2, opticID 4 |
| `LARight.State` | unknown 0, authorizing 1, authorized 2, notAuthorized 3 |

`LAPublicDefines.h` (SDK, not vendored) matches the domain string, error
codes `-1…-11` and `-1004`, and policy numbers. `LAContext.h` documents
the 5-minute accepted reuse interval, private-queue `evaluatePolicy`
replies, `invalidate` → `appCancel` in-flight / `invalidContext` after,
and `interactionNotAllowed` → `notInteractive`.

`docker exec uikit-linux`: Swift 6.2.4 Foundation has no `NSErrorPointer`.

This Mac has Touch ID (`biometryType == 1`) and a login password, so
`canEvaluatePolicy(.deviceOwnerAuthentication)` returned true here. That
is not the Linux host. Linux has no sensor and no passcode broker:
biometric policies → `biometryNotAvailable`, device-owner →
`passcodeNotSet` unless `LocalAuthenticationTestHook` registers a
simulated passcode, companion → `companionNotAvailable`.

## Rules

- `LAErrorDomain` is the measured Apple payload, not the C identifier.
- Reuse constant is 300; the stored property is unclamped (measured).
- `evaluatePolicy` replies hop onto `LocalAuthentication.reply` (non-inline).
- `invalidate()` cancels in-flight work with `appCancel`.
- `LARight` walks `unknown → authorizing → authorized | notAuthorized`
  (LARight.h).
- `LARightStore.shared` is in-memory on Linux. Keys fail closed with
  `invalidContext` (no Secure Enclave).

## Gates

- Mac: module + 32 focused tests → `LOCALAUTHENTICATION_AGENT_RUNTIME_OK`
- `docker exec uikit-linux` `bash tests/acceptance/test_host.sh` →
  `FRAMEWORK_FANOUT_HOST_OK` (234 implemented rows, 13 deferred)
- `docker run swift:6.2-noble` `swift build -c release --product openrender`
  in `uikit/` → green (173.71 s). No UIKit render rule.
