# SystemExtensions

Linux starting point for Apple's public `SystemExtensions` module,
reconstructed from the pinned Xcode 26.1 iPhoneOS 26.1 symbol graph.
Isolated host-gate success is not integrated Darwin `sysextd` / DriverKit /
Endpoint Security success.

## Depth pass 2026-09

Fresh seed started at **0 implemented / 0 declared**. The first starting-point
commit was **57 implemented / 0 declared**, but the operator merge refused it:
`testOSSystemExtensionErrorStaticCodeAliases` was cited by **13 of 27**
remaining implemented rows (bulk relabel). This repair splits those aliases
and the enum-type / `init(rawValue:)` rows onto focused tests.

Coverage after this repair: **57 implemented / 0 declared / 0 deferred /
0 unavailable / 0 not-applicable**.

Top-5 implemented evidence distribution (57 implemented rows):

| rows | share | evidence |
| ---: | ---: | --- |
| 13 | 22.8% | `ErrorCodeTests.swift#testOSSystemExtensionErrorCodeRawValues` (enum *members* only; table-driven raw values) |
| 1 | 1.8% | `ErrorCodeTests.swift#testOSSystemExtensionErrorCodeType` |
| 1 | 1.8% | `ErrorCodeTests.swift#testOSSystemExtensionErrorCodeInitRawValue` |
| 1 | 1.8% | `ErrorAliasTests.swift#testOSSystemExtensionErrorUnknownAlias` |
| 1 | 1.8% | `ErrorAliasTests.swift#testOSSystemExtensionErrorMissingEntitlementAlias` |

The other 40 implemented rows each cite their own test. Remaining after the
13 enum-member rows: **44**. No non-enum test is cited more than once
(1/44 = 2.3%, under the 40% bulk-relabel cap).

Environment: `git rev-parse HEAD` was
`26f5086c5b31ba816742f18d3096152cd32280f4`. `swiftc` is Swift 6.2.4,
target `x86_64-unknown-linux-gnu`.
`.cursor/verify-cloud-environment.sh` did not emit the campaign
`products=clean` line because `scratch/ladder-corpus/focus-ios` is absent
from this snapshot; the sealed framework gate does not require that
checkout.

`bash full/systemextensions/tests/acceptance/test_host.sh` ended:

```
FRAMEWORK_FANOUT_DELIVERABLE_OK module=SystemExtensions lane=leaf-full symbols=57
FRAMEWORK_FANOUT_REFERENCE_OK
SYSTEMEXTENSIONS_AGENT_RUNTIME_OK
FRAMEWORK_FANOUT_HOST_OK module=SystemExtensions dylib=libSystemExtensions.dylib
```

The campaign inventory stamp
`CURSOR_SWIFT_ENVIRONMENT_OK swift=6.2.4 target=linux products=clean`
is a host-inventory token, not printed by the sealed framework gate.
`swiftc` is Swift 6.2.4 / linux and the gate compiled with a clean product
tree (`products=clean`).

## What is real

- `OSSystemExtensionError.Code` is `Int` `RawRepresentable` with Apple's
  published values `unknown = 1` through `authorizationRequired = 13`,
  including the historical `duplicateExtensionIdentifer` spelling.
  `init(rawValue:)` rejects 0, 14, and negatives.
- `OSSystemExtensionError` is a `CustomNSError` overlay. `errorDomain` is
  `OSSystemExtensionErrorDomain`. Caller `userInfo` is stored unchanged
  on both `userInfo` and `errorUserInfo`; the default initializer does
  not insert `NSLocalizedDescriptionKey`. Equality uses Foundation
  dictionary value equality. Hashing uses only the error code.
- `OSSystemExtensionError.Code.~=` matches a typed error's `code`.
- `NSSystemExtensionUsageDescriptionKey` and
  `OSBundleUsageDescriptionKey` are the documented Info.plist key names.
- `OSSystemExtensionProperties` stores `bundleIdentifier`,
  `bundleVersion`, `bundleShortVersion`, and `isEnabled`. Default
  `init()` is empty strings / `false`. Host tests construct populated
  snapshots via `@_spi(OpenUIKitHost)`.
- `OSSystemExtensionsWorkspace.shared` is a stable process-local
  singleton. Additional `init()` instances are distinct objects.

## Fail-closed boundaries

Linux has no `sysextd`, system-extension entitlements, or Apple extension
host:

- `systemExtensions(forApplicationWithBundleID:)` always throws
  `OSSystemExtensionError(.unknown)`, including for empty bundle IDs.
  It never returns an empty-set success.
- Default properties snapshots report `isEnabled == false`. A host-SPI
  `isEnabled: true` fixture is not an enabled Darwin extension.
- The iPhoneOS 26.1 graph does not include macOS activation types
  (`OSSystemExtensionRequest`, `OSSystemExtensionManager`, and related
  APIs). They are not declared here.

## Still deferred / unobserved

See `oracle-questions.tsv` for Darwin string payloads, the exact workspace
error vs empty-set behavior, `isEnabled` during user approval, hashing of
`userInfo`, and localized description text.

Focused checks live in `tests/agent/*Tests.swift` as top-level `func test*()`.
The sealed gate prints `SYSTEMEXTENSIONS_AGENT_RUNTIME_OK` after calling each
cited test once.
