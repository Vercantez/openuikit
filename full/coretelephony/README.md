# CoreTelephony (Linux starting point)

This directory is a fail-closed portable `CoreTelephony` module for the
OpenUIKit Linux platform. It reconstructs the public Xcode 26.1 iPhoneOS Swift
surface from the sealed symbol graph. It is not wired into the shared guest
package; a passing isolated host gate is not integrated Linux success.

The GitHub App installation for this promotion run could not fetch
`github.com/Vercantez/openuikit-linux-platform`
(`cursor/port-coretelephony-to-linux-7cc7`, legacy PR #7). The lane was built
from the monorepo seed plus the in-repo PR #7 repair brief
(`full/framework-fanout/repairs-wave1-pr4-9.json`) and pinned `dotnet/macios`
enum raw values. The monorepo `reference/` dossier was kept (generator SHA-256
`2b8230ced5a3ed78f070607346f6a684d9e0fb74a8932b92bc0f5e38f46f0a8e`); the
platform branch `reference/` could not be compared (`unavailable`).

## What is real

- `kCTErrorDomainNoError` / `POSIX` / `Mach` are `0` / `1` / `2`, matching
  pinned macios `CTErrorDomain`. `CTError` stores `Int32` domain and error
  fields; `init()` is a zero error in the no-error domain.
- Enum raw values follow sequential `NS_ENUM` / macios `[Native]` case order:
  `CTCellularDataRestrictedState` (`UInt` 0...2), `CTCellularPlanCapability`
  (`Int` 0...1), `CTCellularPlanProvisioningAddPlanResult` (`UInt` 0...3).
  `hashValue`, `hash(into:)`, and `!=` are exercised for the plan enums.
- `CTCellularData.restrictedState` is always `.restrictedStateUnknown`. The
  first non-nil `cellularDataRestrictionDidUpdateNotifier` assignment hops
  off the caller and delivers that state exactly once. Replacing a non-nil
  handler does not invent later service updates; nil → non-nil fires again.
- Delegate protocols are real requirements (the optional
  `CTTelephonyNetworkInfoDelegate` member has a default no-op). Existential
  dispatch reaches conformer overrides. Linux never fabricates
  `dataServiceIdentifierDidChange` or `subscriberTokenRefreshed`.
- Radio, carrier, SIM, call, and eSIM queries fail closed: `nil` / empty /
  `false`. `addPlan` completes asynchronously with `.fail`; `update` and
  plan-status token APIs fail with `NSPOSIXErrorDomain` / `EPERM`.
- `init(coder:)` on plan types returns `nil`; Apple archive keys are
  unobserved.
- Call-state constants use the public CTCall payloads (`dialing`, `incoming`,
  `connected`, `disconnected`). RAT constants use the C identifier as the
  string value (the 20-app corpus compares `currentRadioAccessTechnology`
  against `CTRadioAccessTechnologyLTE` and siblings). Notification
  `rawValue`s are the C notification identifiers.

## Fail-closed / not claimed

- No baseband, SIM, carrier token, eSIM host, or CallKit replacement.
- `CTCall.callState` stays empty; Linux never reports `CTCallStateConnected`.
- `CTTelephonyNetworkInfo.currentRadioAccessTechnology` stays `nil`.
- `CTCallCenter.callEventHandler` is stored and never invoked.
- No module-local CoreFoundation aliases.

## Depth pass 2026-09

- implemented before: 92
- implemented after: 112
- declared before: 20
- declared after: 0
- deferred / unavailable / not-applicable: 0 / 0 / 0

The remaining 20 C string constants (call state, RAT, notification names,
`CTSubscriberTokenRefreshed`) moved from `declared` to `implemented` with
table-driven value tests. Every `implemented` row now cites a top-level
`func testName()` under `tests/agent/*Tests.swift`. Corpus priority from
`reference/corpus-summary.json` (Telegram, Home Assistant, Kickstarter
ios-oss, Signal, element): `CTTelephonyNetworkInfo`,
`currentRadioAccessTechnology`, `CTRadioAccessTechnology*`, `CTCarrier`,
`CTCellularData`. `scratch/ladder-corpus` was not present in this
environment; ranking used the sealed corpus summary.

Top-5 evidence distribution:

1. `testRadioAccessTechnologyConstants` — 13
2. `testAddPlanResultEnum` — 9
3. `testRestrictedStateEnum` — 8
4. `testPlanCapabilityEnum` — 7
5. `testPlanRequestStorage` — 7

Did not touch `machorun/`, `uikit/`, `env/contract.json`, or
`scripts/vendor_pins.sh`.
