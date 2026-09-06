# LightweightCodeRequirements (Linux starting point)

Clean-room Linux port of Apple's public `LightweightCodeRequirements` DSL,
seeded from the Xcode 26.1 iPhoneOS 26.1 symbol graph, API digester, and TBD
exports. This directory is not wired into the shared guest package.

Host sources import **Foundation only**. `libLightweightCodeRequirements.dylib`
builds with `-warnings-as-errors`.

## What is real

The public 294-identifier overlay is a value-level constraint language:

- `LaunchConstraint` / `OnDiskConstraint` / `ProcessConstraint` and their
  `@resultBuilder` types (`buildBlock`, `buildExpression`, `buildEither`,
  `buildOptional`)
- Leaf facts: `TeamIdentifier`, `SigningIdentifier`, `CodeDirectoryHash`,
  `InfoPlistHash`, `PlatformType`, `ValidationCategory`, `IsMainBinary`,
  `IsInitProcess`, `IsSIPProtected`, `TeamIdentifierMatchesCurrentProcess`
- `EntitlementsQuery` fluent chains using documented CoreEntitlements opcodes
  (`kCEOpSelectKey=1` … `kCEOpMatchType=11`)
- `OnDiskCodeSigningFlags` / `ProcessCodeSigningFlags` `OptionSet` arithmetic
  with Darwin `CS_*` bit values
- `allOf` / `anyOf` simplification from Apple's DSL docs: flatten nested same
  operators, replace a single child with that child, throw `duplicateKey` when
  the same fact type appears twice (except multiple `EntitlementsQuery` tests)
- Domain conversions (`Launch` ↔ `OnDisk` ↔ `Process`) throw
  `unsupportedConstraintForRequirementType` when a fact is not valid for the
  destination (graph conformances)
- Empty requirements throw `malformedConstraint`
- `Codable` round-trips through documented LWCR-style keys (`team-identifier`,
  `$and`, `$or`, `$in`)

`PlatformType.Value` uses Mach-O `PLATFORM_*` integers. `ValidationCategory.Value`
uses `CS_VALIDATION_CATEGORY_*` (`.none` is 10). `EntitlementsQuery.DataType`
uses `CEType` (dictionary=1 … boolean=5).

## Fail-closed boundaries

Linux has no AMFI, codesign, SIP volume map, or `SecTask`/`SecStaticCode`.

- This module never reports that a binary, process, or launch *satisfied* a
  requirement. Kernel evaluation APIs (`SecTaskValidateForRequirement`,
  `SecCodeCheckValidityWith*`) are TBD-only and are not part of the 294
  public identifiers.
- `TeamIdentifierMatchesCurrentProcess` stores a boolean fact; it does not
  read a Linux process team ID.
- `IsSIPProtected` / `IsInitProcess` / `IsMainBinary` are stored facts, not
  probes of the host OS.
- `ConstraintError.taskIsNoLongerValid` is a public case and is never thrown
  by constructors (no live-task evaluator).
- Apple JSON/plist byte identity for `encode(to:)` is unobserved; round-trips
  are host-defined using documented fact key names.

## Deferred

See `oracle-questions.tsv` for overlay raw-bit confirmation, Codable key
parity, entitlements opcode pairing, and TBD-only `ValidationResult` /
`ConstraintCategory` symbols.

## Tests

- `tests/agent/LightweightCodeRequirementsLoadSmoke.swift` — canonical marker
- `tests/agent/*Tests.swift` — focused `test*` probes (no stdout)
- `tests/agent/LightweightCodeRequirementsDependencyIdentity.swift` — Foundation
  `Data` through `CodeDirectoryHash` / `InfoPlistHash`

## Depth pass 2026-09

Implemented **294 / 294** public precise identifiers (`declared` = 0).

Top-5 `implemented` evidence distribution:

| cites | test |
| ---: | --- |
| 21 | `SigningFlagsTests.swift#testProcessSigningFlagRawValues` |
| 16 | `SigningFlagsTests.swift#testOnDiskSigningFlagRawValues` |
| 16 | `PlatformValidationTests.swift#testPlatformTypeRawValues` |
| 12 | `EntitlementsQueryTests.swift#testEntitlementsQueryDataTypeRawValues` |
| 12 | `PlatformValidationTests.swift#testValidationCategoryRawValues` |

Those five are table-driven enum / option-set member tests. No other single
test is cited by more than 40% of the remaining implemented rows.
