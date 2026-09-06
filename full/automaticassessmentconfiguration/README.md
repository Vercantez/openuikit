# AutomaticAssessmentConfiguration (Linux starting point)

This directory is a clean-room Linux starting point for Apple's public
`AutomaticAssessmentConfiguration` module, seeded from the Xcode 26.1
iPhoneOS 26.1 symbol graph, API digester, TBD exports, and pinned
`dotnet/macios` bindings. It is not wired into the shared guest package;
that integration is a later central-review step.

## What is real

- `AEAssessmentError.Code` uses the pinned macios/API-digester raw values
  (`unknown = 1`, `unsupportedPlatform = 2`,
  `multipleParticipantsNotSupported = 3`,
  `configurationUpdatesNotSupported = 4`,
  `requiredParticipantsNotAvailable = 5`). `AEAssessmentErrorDomain` is
  `"AEAssessmentErrorDomain"`. Stored `userInfo`, `==` on code plus userInfo,
  hashing by code, `Code ~= Error` matching, and static `Code` aliases are
  exercised.
- `notInstalledParticipants` / `restrictedSystemParticipants` extract
  `[String]?` from Linux user-info keys named after the macios Field
  symbols (`AENotInstalledParticipantsKey`,
  `AERestrictedSystemParticipantsKey`).
- `AEAssessmentConfiguration.AutocorrectMode` is an `OptionSet` over `UInt`
  (`spelling = 1 << 0`, `punctuation = 1 << 1`) with the synthesized
  SetAlgebra/OptionSet operations.
- `AEAssessmentApplication` stores `bundleIdentifier` and equates/hashes by
  that string so participant maps are lookup-by-identity.
- `AEAssessmentConfiguration` and `AEAssessmentParticipantConfiguration`
  are process-local state: `allows*` flags, `autocorrectMode`,
  `allowsNetworkAccess`, `isRequired`, `configurationInfo`,
  `mainParticipantConfiguration` (strong, same instance), and
  `setConfiguration` / `remove` / `configurationsByApplication` (snapshot
  dictionary keyed by bundle identifier). Linux defaults every `allows*`
  flag and `isRequired` to `false` and `autocorrectMode` to `[]` as a
  restrictive local policy.

Host-compiled sources import Foundation only. The identity probe
`tests/agent/AutomaticAssessmentConfigurationDependencyIdentity.swift`
imports `AutomaticAssessmentConfiguration` and `Foundation` for the later
EC2 integration build.

## Fail-closed boundaries

Linux has no Automatic Assessment daemon, lock-task / Single App Mode,
education entitlement, or AACClient service.

- `AEAssessmentSession.supportsMultipleParticipants` and
  `supportsConfigurationUpdates` are `false`.
- `begin()` never sets `isActive`. The delegate receives
  `assessmentSession(_:failedToBeginWithError:)` synchronously with
  `AEAssessmentError.unsupportedPlatform`. `assessmentSessionDidBegin` is
  not invoked.
- `update(to:)` never replaces the stored configuration. The delegate
  receives `assessmentSession(_:failedToUpdateTo:error:)` synchronously
  with `AEAssessmentError.configurationUpdatesNotSupported`.
- `end()` is a no-op because the session never becomes active;
  `assessmentSessionDidEnd` is not invoked from `end()`.
- Delegate callbacks run on the caller before `begin` / `update` return.
  Apple's queue, timing, and exactly-once delivery are unobserved.

## Deferred

None of the 102 public precise identifiers are deferred. Darwin defaults,
NSCopying/NSSecureCoding, user-info key bytes, and error precedence remain
oracle questions rather than invented success.

Run the sealed host gate with:

```sh
bash full/automaticassessmentconfiguration/tests/acceptance/test_host.sh
```

## Depth pass 2026-09

Implemented **102** identifiers, declared **0**, deferred **0**.
Nondeferred total **102** of 102 (lane floor 82).

Top-5 evidence distribution (of 102 implemented rows; enum/option-set
members may share a table-driven value test; 40% cap on remaining ≈ 38):

| Citations | Test |
| ---: | --- |
| 5 | `testErrorCodeRawValues` (enum cases) |
| 2 | `testAutocorrectModeRawValues` (option-set members) |
| 2 | `testErrorErrorDomainStatic` |
| 2 | `testErrorErrorUserInfo` |
| 2 | `testErrorErrorCode` |

No non-enum/option-set test exceeds 40% of the remaining implemented rows.
The largest remaining citation is 2.

The campaign inventory stamp
`CURSOR_SWIFT_ENVIRONMENT_OK swift=6.2.4 target=linux products=clean`
is a host-inventory token. `.cursor/verify-cloud-environment.sh` on this
snapshot fails earlier (`missing corpus checkout: scratch/ladder-corpus/focus-ios`;
Cursor Build `bld-20260906-253cd433-7a30-4d11-aad2-8b209b7b2d21` vs seed
`bld-20260901-d3266600-d87b-438f-94c1-d1aa48036e87`). `swiftc` is Swift
6.2.4 / linux and the sealed gate compiles with a clean product tree.
