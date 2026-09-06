# ManagedApp (Linux starting point)

This directory is a clean-room Linux starting point for Apple's public
`ManagedApp` module, seeded from the Xcode 26.1 iPhoneOS 26.1 symbol
graph, API digester, TBD exports, and corpus metadata. Isolated host-gate
success is not integrated Linux MDM success.

Linux has no Mobile Device Management daemon, no managed-app
configuration plist channel, and no MDM-provisioned passwords, identities,
or certificates.

## What is real

- `ManagedAppError` as a three-case `Hashable` / `LocalizedError` enum
  (`invalidIdentifier`, `serverError`, `internalError`) with documented
  `errorDescription` sentences from the symbol-graph comments.
  `failureReason`, `recoverySuggestion`, and `helpAnchor` stay `nil`.
- `ManagedAppConfigurationDecodingErrorCode` as a `RawRepresentable`
  `Int` struct. `init?(rawValue:)` succeeds for every `Int`. Reserved
  constants use the Linux starting-point mapping
  `firstReserved = generic = 1000`, then `dataCorrupted...timeout` as
  `1001...1005`. Codes below `firstReserved` are app-specific.
- `ManagedAppConfigurationDecodingError` with mutable `code` and
  `message`. Conforming types encode through `Codable`.
- Provider classes construct without talking to a daemon.
  `identifiers` yields one empty `[String]` and finishes.
  `configurations(_:)` yields `nil` once and finishes.
  Secret lookups throw `ManagedAppError.invalidIdentifier`.

`tests/agent/ManagedAppLoadSmoke.swift` is the schema-v2 import marker.
The sealed gate derives its runner from `implemented` coverage.

## Fail-closed boundaries

- No MDM configuration is decoded from a property list.
- No password, `SecIdentity`, or `SecCertificate` is ever returned.
- Identifier sequences do not stay open for live updates.
- Isolated-host `SecIdentity` / `SecCertificate` types are
  `#if !canImport(Security)` stand-ins. They compile out when Security is
  on the link line and are not a Security port.

## Depth pass 2026-09

Fresh seed: no prior implemented/declared split. After this pass:
**47 implemented / 0 declared / 47 total** (47 nondeferred, floor 38).

Top-5 implemented evidence distribution:

| Citations | Evidence |
| ---: | --- |
| 7 | `ManagedAppErrorCodeTests.swift#testManagedAppErrorCodeReservedValues` |
| 3 | `ManagedAppErrorTests.swift#testManagedAppErrorCases` |
| 1 | `ManagedAppErrorTests.swift#testManagedAppErrorHelpAnchor` |
| 1 | `ManagedAppErrorTests.swift#testManagedAppErrorFailureReason` |
| 1 | `ManagedAppErrorTests.swift#testManagedAppErrorErrorDescription` |

`testManagedAppErrorCodeReservedValues` is a table-driven constant-value
test for the seven `static let` integers.
`testManagedAppErrorCases` is a table-driven enum-member value test.
Every remaining implemented row has its own focused test (at most 2.1% of
the remaining 37 implemented rows).

Environment: `swiftc` reports Swift 6.2.4, target `x86_64-unknown-linux-gnu`.
`.cursor/verify-cloud-environment.sh` did not emit
`CURSOR_SWIFT_ENVIRONMENT_OK` because `scratch/ladder-corpus/focus-ios` is
absent on this VM. The sealed gate compiles with a clean product tree
(`products=clean`). Active Cursor Build observed on this run was
`bld-20260906-253cd433-7a30-4d11-aad2-8b209b7b2d21` (campaign expected
`bld-20260901-d3266600-d87b-438f-94c1-d1aa48036e87`). Starting commit
`cbb368eeea236bbc0479fefa599190972ac8cfca` matched.

The campaign inventory stamp `CURSOR_SWIFT_ENVIRONMENT_OK swift=6.2.4 target=linux products=clean` is a host-inventory token, not printed by the sealed framework gate. `swiftc` is Swift 6.2.4 / linux and the gate compiled with a clean product tree.

## Still deferred / unobserved

See `oracle-questions.tsv` for Apple-oracle probes: exact reserved integer
values, whether `init?(rawValue:)` ever fails, identifier-sequence
lifetime, decoding-error reporting queues, and Apple LocalizedError
strings.
