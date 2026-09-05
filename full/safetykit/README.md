# SafetyKit

Linux starting point for Apple's public `SafetyKit` module, reconstructed from
the pinned Xcode 26.1 iPhoneOS 26.1 symbol graph, API digester, and the
read-only `dotnet/macios` SafetyKit bindings. This directory is not wired into
the shared guest package. A passing isolated host gate is not integrated Linux
success with guest Foundation, CoreLocation, or Apple Crash Detection.

## Depth pass 2026-09

This is a fresh seed: 70 exact public identifiers, floor 56 nondeferred.

Coverage after this pass: **70 implemented / 0 declared / 0 deferred /
0 unavailable / 0 not-applicable**.

Top-5 evidence distribution (share of the 70 implemented rows):

1. `SAErrorTests.swift#testSAErrorInitUserInfoAndCustomNSError` — 7 (10.0%)
2. `SAEmergencyResponseTests.swift#testSAEmergencyResponseVoiceCallStatusRawValues` — 6 (8.6%, enum members)
3. `SAErrorTests.swift#testSAErrorCodeRawValues` — 6 (8.6%, enum members)
4. `SAAuthorizationStatusTests.swift#testSAAuthorizationStatusRawValues` — 5 (7.1%, enum members)
5. `SACrashDetectionTests.swift#testSACrashDetectionEventResponseRawValues` — 4 (5.7%, enum members)

Tied at 4 citations: `testSAErrorStaticCodeAliases`. No non-enum test is cited
by more than 40% of the remaining implemented rows (largest non-enum citation
is 7 of 70).

## What is real

- `SAAuthorizationStatus`, `SACrashDetectionEvent.Response`,
  `SAEmergencyResponseManager.VoiceCallStatus`, and `SAError.Code` are
  `Int` enumerations whose raw values match the pinned macios
  `SAEnums.cs` (`notDetermined = 0`, `attempted = 0` / `disabled = 1`,
  `dialing = 0` … `failed = 3`, `notAuthorized = 1` … `operationFailed = 4`).
- `SAErrorDomain` and `SAError.errorDomain` are `SAErrorDomain`. `SAError`
  preserves caller-supplied `userInfo` on both `userInfo` and
  `errorUserInfo`; the default initializer leaves both dictionaries empty
  and does not insert a localized-description mapping. Equality uses
  Foundation dictionary value equality. Hashing uses only the error code.
- `SACrashDetectionEvent` stores `date`, `response`, and optional
  `location`. Apple's surface has no public designated initializer;
  `host_makeEvent` is isolated-host construction. `init(coder:)` /
  `encode(with:)` round-trip those fields under host archive keys.
- `SACrashDetectionManager.isAvailable` is `false`.
  `authorizationStatus` stays `.notDetermined`.
  `requestAuthorization` completes once, synchronously, with
  `(.notDetermined, SAError.notAllowed)`.
- `SAEmergencyResponseManager.dialVoiceCall` completes once,
  synchronously, with `(false, SAError.notAllowed)` for every phone number.
  The Swift async overlay of the same ObjC selector throws that error.
- Optional delegate methods have empty defaults. Weak `delegate`
  properties round-trip. Host SPI can inject a crash event or voice-call
  status for wiring tests; those paths are not Apple sensor or telephony
  callbacks.

## Fail-closed boundaries

Linux has no Crash Detection sensor, SafetyKit daemon, Crash Detection
entitlement, or Emergency SOS telephony.

- `isAvailable` is `false`. Authorization is never granted.
- `requestAuthorization` never presents a prompt and never delivers
  `crashDetectionManager(_:didDetect:)`.
- `dialVoiceCall` never places a call and never emits
  `VoiceCallStatus` callbacks from the dial path.
- Isolated-host `CLLocation` in `SALocation.swift` compiles out when
  CoreLocation is imported. It is not a Linux port of CoreLocation and is
  not a live GPS fix.

Private TBD types (`SAClient`, `SAServer`, `SATelephonyManager`,
`CSKappaConnection`, and the other `_OBJC_CLASS_$_SA*` exports) are not
part of this module.

## Still open

See `oracle-questions.tsv` for Darwin `SAErrorDomain` bytes, authorization
status after a refused prompt, callback queues, NSCoder key names, empty
phone-number validation, and CoreLocation identity when that module is
linked.

Focused checks live in `tests/agent/*Tests.swift` as top-level `func test*()`.
The sealed gate prints `SAFETYKIT_AGENT_RUNTIME_OK` after calling each
cited test once.

```
CURSOR_SWIFT_ENVIRONMENT_OK swift=6.2.4 target=linux products=clean
FRAMEWORK_FANOUT_DELIVERABLE_OK module=SafetyKit lane=leaf-full symbols=70
FRAMEWORK_FANOUT_REFERENCE_OK
SAFETYKIT_AGENT_RUNTIME_OK
FRAMEWORK_FANOUT_HOST_OK module=SafetyKit dylib=libSafetyKit.dylib
```

Run `bash full/safetykit/tests/acceptance/test_host.sh` from the repo
root. Keep generated products out of the tree.
