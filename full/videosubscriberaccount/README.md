# VideoSubscriberAccount (Linux starting point)

This directory is a fail-closed portable `VideoSubscriberAccount` module for the
OpenUIKit Linux platform, seeded from the Xcode 26.1 iPhoneOS public surface
(210 exact IDs). Isolated host compilation produces
`libVideoSubscriberAccount.dylib` with Foundation only.

Linux has no TV-provider daemon, SAML/API identity service, Apple entitlement,
or UIKit presentation host. Account access, metadata enqueue, user-account
sync, and auto sign-in never report success.

## What is real

- `VSAccountAccessStatus` raw values: `notDetermined = 0`, `restricted = 1`,
  `denied = 2`, `granted = 3`.
- `VSError.Code` raw values: `accessNotGranted = 0` through `unsupported = 7`,
  matching pinned `dotnet/macios` `[Native]` order. Typed construction,
  `userInfo`, equality, hashing, and `~=` matching are exercised.
- `VSErrorDomain` and the four `VSErrorInfoKey*` strings equal their ObjC
  field names (TBD exports).
- `VSSubscriptionAccessLevel`: `unknown = 0`, `freeWithAccount = 1`,
  `paid = 2`.
- `VSUserAccount.AccountType`: `free = 0`, `paid = 1`.
- `VSUserAccount.OriginatingDeviceCategory`: `mobile = 0`, `other = 1`.
- `VSUserAccountManager.AutoSignInAuthorization`: `notDetermined = 0`,
  `granted = 1`, `denied = 2`.
- `VSUserAccountManager.QueryOptions` as an `OptionSet` (`allDevices = 1`).
- `VSAccountProviderAuthenticationScheme` and `VSCheckAccessOption` string
  newtypes. Raw strings equal the ObjC field names until an Apple-oracle
  probe records Darwin live payloads.
- `VSUserAccount` / `VSAppleSubscription` value types with documented
  initializers, storage, equality, and hashing.
- Request/response objects store caller fields. Metadata and provider
  responses are locally constructible because no provider process exists.
- `VSSubscriptionRegistrationCenter.setCurrentSubscription` retains a
  process-local value only.

## Fail-closed boundaries

- `VSAccountManager.enqueue` completes on the caller thread with
  `VSError.unsupported` and never returns metadata.
- `checkAccessStatus(options:)` (async overlay) throws
  `VSError.unsupported`. The raw-graph completion overlay completes with
  `.notDetermined` plus the same error. Never `.granted`.
- `VSUserAccountManager` query/update/auto-sign-in APIs throw
  `VSError.unsupported`. They never invent accounts or tokens.
- Required `VSAccountManagerDelegate` present/dismiss methods take
  UIKit `UIViewController` and are deferred. This module does not publish a
  UIKit lookalike. The optional authentication gate defaults to `false`.
- `VSOpenTVProviderSettingsURLString` stores the export name until an oracle
  probe records the live settings URL.

## Depth pass 2026-09

Implemented **201** of 210 exact IDs (7 `declared` async overlays, 2 UIKit
`deferred` delegate methods). Nondeferred count 208, above the medium-full
floor of 105.

Top-5 `implemented` evidence distribution:

1. `testAccountMetadataRequestDefaultsAndStorage` — 14 rows (request storage)
2. `testErrorStruct` — 14 rows (error overlay table)
3. `testErrorCodeRawValues` — 12 rows (enum table)
4. `testUserAccountPropertyStorage` — 11 rows (value-type storage)
5. `testAccountAccessStatusRawValues` — 9 rows (enum table)

`testErrorCodeRawValues` is a table-driven enum-member test.
`testAccountAccessStatusRawValues` is a table-driven enum test. Request
storage and user-account property tests cover distinct non-enum families and
stay well under the 40% bulk-relabel bound.

## Tests

`tests/agent/VideoSubscriberAccountLoadSmoke.swift` is the schema-v2 load
marker. `tests/agent/*Tests.swift` holds the sealed focused tests.
`tests/agent/VideoSubscriberAccountDependencyIdentity.swift` is prepared for
a future clean EC2 run that builds guest Foundation first.

Run `bash tests/acceptance/test_host.sh` from this directory, or
`bash full/videosubscriberaccount/tests/acceptance/test_host.sh` from the
repository root. Keep generated products out of the tree.

The sealed host gate ended:

```
FRAMEWORK_FANOUT_DELIVERABLE_OK module=VideoSubscriberAccount lane=medium-full symbols=210
FRAMEWORK_FANOUT_REFERENCE_OK
VIDEOSUBSCRIBERACCOUNT_AGENT_RUNTIME_OK
FRAMEWORK_FANOUT_HOST_OK module=VideoSubscriberAccount dylib=libVideoSubscriberAccount.dylib
```

The campaign inventory stamp `CURSOR_SWIFT_ENVIRONMENT_OK swift=6.2.4 target=linux products=clean` is a host-inventory token. `.cursor/verify-cloud-environment.sh` on this snapshot fails earlier (`missing corpus checkout: scratch/ladder-corpus/focus-ios`; Cursor Build `bld-20260906-253cd433-7a30-4d11-aad2-8b209b7b2d21` vs seed `bld-20260901-d3266600-d87b-438f-94c1-d1aa48036e87`). `swiftc` is Swift 6.2.4 / linux and the sealed gate compiled with a clean product tree.
