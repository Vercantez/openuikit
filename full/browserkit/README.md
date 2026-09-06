# BrowserKit (Linux starting point)

Clean-room Linux starting point for Apple's public `BrowserKit` module,
seeded from the Xcode 26.1 iPhoneOS 26.1 symbol graph, API digester, TBD
exports, and the pinned `dotnet/macios` evidence lock (which has no
BrowserKit bindings). This directory is not wired into the shared guest
package.

`libBrowserKit.dylib` compiles with `-warnings-as-errors` under the sealed
host gate.

Coverage: **8 implemented / 0 declared / 0 deferred / 8 total**
(fully nondeferred, above the leaf-full floor of 7).

## Depth pass 2026-09

This is a fresh seed: the directory had `AGENTS.md`, `FANOUT_TASK.md`, and
`reference/` only. This pass implements all **8** exact public identifiers
as `implemented` (0 declared / 0 deferred / 0 unavailable / 0 not-applicable).

Top-5 evidence distribution after this pass (of 8 implemented rows):

1. `BEAvailabilityContextTests.swift#testBEAvailabilityContextType` — 1 row (12.5%)
2. `BEAvailabilityContextTests.swift#testBEAvailabilityContextWebBrowserRawValue` — 1 row (12.5%)
3. `BEAvailabilityTests.swift#testBEAvailabilityIsNSObject` — 1 row (12.5%)
4. `BEAvailabilityTests.swift#testBEAvailabilityIsEligibleFailClosed` — 1 row (12.5%)
5. `BEAvailabilityContextTests.swift#testBEAvailabilityContextInequality` — 1 row (12.5%)

Every implemented row cites a dedicated top-level `func test*()`. No test
is cited by more than one row.

## What is real

- `BEAvailability` is an `open` `NSObject` subclass. Distinct instances are
  not identical; `isEqual` follows `NSObject` identity.
- `BEAvailability.Context` is an `Int` `NS_ENUM` nested type with one
  public case, `webBrowser`. The first implicit `NS_ENUM` enumerator is
  raw value `0`. `init?(rawValue:)` returns `.webBrowser` for `0` and
  `nil` for every other `Int`.
- Synthesized `Equatable` / `Hashable` witnesses (`!=`, `hashValue`,
  `hash(into:)`) follow the standard `Int` raw-value implementations.
  Equal contexts hash equal; `Set` membership collapses duplicates.
- `isEligible(for:completionHandler:)` invokes the handler exactly once,
  synchronously, before returning, with `(false, BrowserKitHostError.eligibilityUnavailable)`.
- The async overlay `isEligible(for:)` always throws that same error and
  never returns `true` or a successful `false`.

## Fail-closed boundaries

Linux has no Apple alternative-engine eligibility daemon, region service,
web-browser entitlement, or BrowserKit process.

- `isEligible` never returns `true`.
- `isEligible` never reports a successful negative (`false` with a nil
  error). Callers that only inspect the Boolean still see `false`; callers
  that inspect the error see `BrowserKitHostError.eligibilityUnavailable`.
- `BrowserKitHostError` uses domain `BrowserKit.Linux` and code `1`. Those
  values are a Linux discriminator, not Apple's NSError payload.
- `BEEligibilityContextApp` is absent from the Xcode 26.1 graph and is
  not declared.

## Deferred / oracle

See `oracle-questions.tsv` for Apple error domain/codes, callback queue,
successful-negative vs lookup-failure, and whether `webBrowser` is
confirmed as raw `0` from header bytes.

## Tests

- `tests/agent/BrowserKitLoadSmoke.swift` — canonical schema-v2 marker
- `tests/agent/*Tests.swift` — focused `test*` probes (no stdout)
- `tests/agent/BrowserKitDependencyIdentity.swift` — Foundation `NSObject`
  / `NSError` through public `BEAvailability` APIs

Keep generated products out of the tree. Run
`bash tests/acceptance/test_host.sh` from this directory or
`bash full/browserkit/tests/acceptance/test_host.sh` from the repo root.

## Environment and gate

`git rev-parse HEAD` at the start of this seed was
`26f5086c5b31ba816742f18d3096152cd32280f4`. `swiftc` is Swift 6.2.4,
target `x86_64-unknown-linux-gnu`.
`.cursor/verify-cloud-environment.sh` did not emit
`CURSOR_SWIFT_ENVIRONMENT_OK swift=6.2.4 target=linux products=clean`
because `scratch/ladder-corpus/focus-ios` is absent from this snapshot.
The sealed framework gate does not require that checkout. The pod
booted from `bld-20260906-253cd433-7a30-4d11-aad2-8b209b7b2d21` rather
than campaign `bld-20260901-d3266600-d87b-438f-94c1-d1aa48036e87`.
The sealed host gate compiles a clean product tree (`products=clean`).

Exact sealed-gate markers from `bash full/browserkit/tests/acceptance/test_host.sh`:

```
FRAMEWORK_FANOUT_DELIVERABLE_OK module=BrowserKit lane=leaf-full symbols=8
FRAMEWORK_FANOUT_REFERENCE_OK
BROWSERKIT_AGENT_RUNTIME_OK
FRAMEWORK_FANOUT_HOST_OK module=BrowserKit dylib=libBrowserKit.dylib
```
