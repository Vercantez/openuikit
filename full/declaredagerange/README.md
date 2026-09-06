# DeclaredAgeRange

Linux starting point for Apple's public `DeclaredAgeRange` module, reconstructed
from the pinned Xcode 26.1 iPhoneOS symbol graph. Isolated host-gate success
is not integrated Linux / Apple Age Range service success.

## Depth pass 2026-09

Coverage of the 63 exact public identifiers:

- **before:** 0 implemented / 0 declared / 0 deferred (fresh seed)
- **after:** 63 implemented / 0 declared / 0 deferred / 0 unavailable / 0 not-applicable

Every public precise ID is `implemented`. Enum cases share table-driven
case tests (`AgeRangeDeclaration`, `Error`, `Response`). Every other
identifier has a dedicated top-level `func test*()`. No non-enum test is
cited by more than one implemented row (about 1.8% of the 56 remaining
implemented rows).

Top-5 evidence distribution (share of the 63 implemented rows):

1. `AgeRangeDeclarationTests.swift#testAgeRangeDeclarationCases` — 2 (3.2%)
2. `AgeRangeServiceErrorTests.swift#testErrorCases` — 2 (3.2%)
3. `AgeRangeResponseTests.swift#testResponseCases` — 2 (3.2%)
4. `AgeRangeServiceErrorTests.swift#testErrorHelpAnchor` — 1 (1.6%)
5. `AgeRangeServiceErrorTests.swift#testErrorFailureReason` — 1 (1.6%)

Environment: `git rev-parse HEAD` at the start of this run was
`cbb368eeea236bbc0479fefa599190972ac8cfca`. `swiftc` is Swift 6.2.4,
target `x86_64-unknown-linux-gnu`.
`.cursor/verify-cloud-environment.sh` did not emit
`CURSOR_SWIFT_ENVIRONMENT_OK` because `scratch/ladder-corpus/focus-ios` is
absent from this snapshot; the sealed framework gate does not require that
checkout. The pod booted from
`bld-20260906-253cd433-7a30-4d11-aad2-8b209b7b2d21` rather than campaign
`bld-20260901-d3266600-d87b-438f-94c1-d1aa48036e87`.

`bash full/declaredagerange/tests/acceptance/test_host.sh` ended:

```
FRAMEWORK_FANOUT_DELIVERABLE_OK module=DeclaredAgeRange lane=leaf-full symbols=63
FRAMEWORK_FANOUT_REFERENCE_OK
DECLAREDAGERANGE_AGENT_RUNTIME_OK
FRAMEWORK_FANOUT_HOST_OK module=DeclaredAgeRange dylib=libDeclaredAgeRange.dylib
```

The campaign inventory stamp
`CURSOR_SWIFT_ENVIRONMENT_OK swift=6.2.4 target=linux products=clean`
is a host-inventory token, not printed by the sealed framework gate.
`swiftc` is Swift 6.2.4 / linux and the gate compiled with a clean product
tree (`products=clean`).

## What is real

The public Foundation surface compiles to `libDeclaredAgeRange.dylib`.

- `AgeRangeService` is a struct with `static let shared`. Requests validate
  age gates then fail closed.
- Gates follow the documented sample (`13, 15, 18`): each provided
  threshold must be `>= 1`, `threshold3` requires `threshold2`, and later
  gates must be strictly greater. Other combinations throw `invalidRequest`.
- `AgeRangeService.Error` is `.notAvailable` then `.invalidRequest`
  (api-digester order). It conforms to `LocalizedError`, `Hashable`, and
  `Sendable`. Linux does not invent localized copy: `errorDescription`,
  `failureReason`, `recoverySuggestion`, and `helpAnchor` stay `nil`.
- `AgeRangeDeclaration` is `.selfDeclared` then `.guardianDeclared`.
- `ParentalControls` is an `OptionSet` over `Int`. `description` is the
  decimal raw value, matching the graph doc comment. Linux stores
  `communicationLimits` as raw value `1`.
- `AgeRange` stores `lowerBound`, `upperBound`, `ageRangeDeclaration`, and
  `activeParentalControls`. Docs: `nil` lower bound means 0; `nil` upper
  bound means none; empty parental controls means not under-18-with-limits.
- `Response` is `.declinedSharing` or `.sharing(range:)`.
- `DeclaredAgeRangeAction.callAsFunction(ageGates:_:_:)` uses the same
  gate checks. `EnvironmentValues.requestAgeRange` returns a process-local
  action.

## Fail-closed boundaries

- Linux never grants an age range, never presents system UI, and never
  returns `.sharing(range:)` or `.declinedSharing` from a live request.
  Well-formed `requestAgeRange` / `callAsFunction` calls throw
  `.notAvailable`. Completions never suspend; host tests use
  `@_spi(OpenUIKitHost)` synchronous twins.
- `UIViewController` and `EnvironmentValues` are module-local lookalikes
  when UIKit / SwiftUI are not imported. They are not a Linux UIKit or
  SwiftUI port.
- `communicationLimits` bit `1` is a Linux convention, not an observed
  Apple raw value.

## Still deferred / unobserved

See `oracle-questions.tsv` for Apple-oracle probes: `communicationLimits` raw
bit, `invalidRequest` matrix, `notAvailable` versus `declinedSharing`,
async resume queue, `LocalizedError` copy, and SwiftUI environment-key
identity.
