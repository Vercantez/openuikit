# IdentityDocumentServices (Linux starting point)

This directory is a fail-closed portable `IdentityDocumentServices` module
for the OpenUIKit Linux platform, seeded from the Xcode 26.1 iPhoneOS
public surface (106 exact IDs). Isolated host compilation produces
`libIdentityDocumentServices.dylib` with Foundation only.

Linux has no identity-document entitlement, Secure Element, Apple
presentment daemon, or ISO 18013-5 CBOR validator. Web presentment
validation and provider registration never report success.

## What is real

- ISO 18013-5 request trees (`ElementInfo`, `DocumentRequest`,
  `DocumentRequestSet`, `PresentmentRequest`, `RequestAuthentication`,
  `ISO18013MobileDocumentRequest`) store caller fields and round-trip.
- `ISO18013MobileDocumentResponse` stores caller `Data`.
- `IdentityDocumentWebPresentmentRawRequest` stores `RequestType` and
  payload bytes. `RequestType` is the documented
  `iso18013MobileDocument` case with `Equatable` / `Hashable`.
- `IdentityDocumentPresentmentError.Code` raw values follow the pinned
  API-digester child order: `unknown = 0`, `invalidRequest = 1`,
  `requestInProgress = 2`, `cancelled = 3`, `notEntitled = 4`.
- Presentment `~=` matches `IdentityDocumentPresentmentError` by `code`.
- `MobileDocumentRegistration` stores type, authority key identifiers,
  document identifier, and invalidation date. Omitting the identifier
  uses `UUID().uuidString`.
- `IdentityDocumentProviderRegistrationStore.Status` and
  `RegistrationError` cases match the documented enum children
  (`authorized` / `notDetermined` / `notAuthorized` / `notSupported`
  and `unknown` / `invalidRequest` / `notAuthorized` / `notSupported`).

## Fail-closed boundaries

- `IdentityDocumentWebPresentmentRawRequestValidator` rejects empty
  request data and non-https origins as `invalidRequest`. Any other
  payload throws `notEntitled`. It never returns a parsed ISO 18013-5
  request.
- `IdentityDocumentProviderRegistrationStore.status` is always
  `.notSupported`. `addRegistration`, `removeRegistration`, and
  `registrations` throw `.notSupported`. Those async members are
  declared, not awaited by the isolated runner.
- `RequestAuthentication.authenticationCertificateChain` uses a
  module-local `SecCertificate` stand-in because Security is not a
  declared dependency. There is no trust evaluation.
- Constructing `ISO18013MobileDocumentResponse` is not a successful
  presentment.

## Depth pass 2026-09

Before the merge-ledger repair: **99 implemented** / **4 declared** /
**3 not-applicable**. Operator merge refused the `not-applicable` Actor
isolation rows (they are not SwiftUI cross-import overlay IDs).

After: **99 implemented** / **7 declared** / **0 not-applicable**.
Nondeferred count 106, above the medium-full floor of 53. The three
`Actor` isolation witnesses (`assertIsolated`, `assumeIsolated`,
`preconditionIsolated`) are `declared`; calling them off the actor
traps and the isolated runner cannot hop.

## Wave 10 re-examination 2026-09-15

Before: **99 implemented** / **7 declared** / **0 deferred** / **0 n/a**.
After: **99 implemented** / **7 declared** / **0 deferred** / **0 n/a**
(implemented gain 0). The four remaining async members (`status`,
`registrations`, `addRegistration`, `removeRegistration`) cannot be cited
by synchronous no-argument tests: calling them requires `await`, which the
sealed runner forbids, and their fail-closed `.notSupported` behavior must
not report success without the Apple presentment daemon. The three `Actor`
isolation witnesses trap when called off the actor. No SwiftUI View-overlay
rows exist in this module, so the overlay override does not apply.

Top-5 `implemented` evidence distribution:

1. `testPresentmentErrorCodeRawValues` — 9 rows (enum table)
2. `testMobileDocumentRegistrationStoresFields` — 6 rows
3. `testPresentmentErrorStaticCodeAliases` — 5 rows (Code static lets)
4. `testRegistrationErrorCases` — 5 rows (enum table)
5. `testRegistrationStoreStatusCases` — 5 rows (enum table)

No non-enum test is cited by more than 6 implemented rows (40% of the
remaining 78 non-table rows would be 31).

## Wave 11 re-examination 2026-09-15

Before: **99 implemented** / **7 declared** / **0 deferred** / **0 n/a**.
After: **99 implemented** / **7 declared** / **0 deferred** / **0 n/a**
(implemented gain 0). Re-probed conversion with a scratch `swiftc` build:
synchronous access to `IdentityDocumentProviderRegistrationStore.status`
from a non-`async` function is a compile error (`'async' property access
in a function that does not support concurrency`), and the sealed runner
forbids `await`, semaphores, and run-loop waits in cited tests, so the
four async members (`status`, `registrations`, `addRegistration`,
`removeRegistration`) cannot be cited by synchronous no-argument tests.
The three `Actor` isolation witnesses trap when called off the actor.
No SwiftUI View-overlay rows exist in this module (no `View`/`SwiftUI`
precise IDs in the public surface), so the overlay override does not
apply. Fail-closed behavior unchanged: async store members report
`.notSupported` without the Apple presentment daemon.

## Wave 12 re-examination 2026-09-15

Before: **99 implemented** / **7 declared** / **0 deferred** / **0 n/a**.
After: **99 implemented** / **7 declared** / **0 deferred** / **0 n/a**
(implemented gain 0). Re-verified each leftover against the sealed-runner
rules: the four store members (`status`, `registrations`, `addRegistration`,
`removeRegistration`) are `async` (see `reference/public-surface.tsv`), so
any synchronous no-argument citing test would be a compile error, and the
runner forbids `await`, semaphores, and run-loop waits. Their fail-closed
`.notSupported` behavior must not report success without the Apple
presentment daemon. The three `Actor` isolation witnesses
(`assertIsolated`, `assumeIsolated`, `preconditionIsolated`) trap when
called off the actor and would crash the sealed runner. No `View`/`SwiftUI`
precise IDs exist in this module, so the overlay override does not apply.
Product sources still compile under `swiftc -warnings-as-errors`; the 42
cited `test*` functions link and emit only the exact success marker
(harness run with a Darwin shim for the Linux-only `Glibc` gate import).
The shared deliverable validator (`validate_seed.py --phase deliverable`)
refuses before compiling because `full/framework-roadmap/framework-roadmap.json`
is absent from this worktree snapshot — a repo-wide precondition outside
`full/identitydocumentservices/` that no edit here can satisfy; all
in-scope checks pass.

## Wave 13 re-examination 2026-09-18

Before: **99 implemented** / **7 declared** / **0 deferred** / **0 n/a**.
After: **103 implemented** / **3 declared** / **0 deferred** / **0 n/a**
(implemented gain 4). The sealed host runner is now `@main async` and
`await`s top-level `func test*() async`, so the four in-process async
store members convert cleanly: `status` (async getter returning
`.notSupported`), `registrations`, `addRegistration`, and
`removeRegistration` (each throwing `.notSupported` immediately with no
hardware/daemon wait). Each is cited by a dedicated non-throwing `async`
test that awaits the member in-process and asserts the fail-closed
`.notSupported` outcome — no `DispatchQueue.main`, `RunLoop`, or
semaphore waits, and no success is reported without the Apple
presentment daemon. The runner emits `await name()` without `try`, so
the new tests are `async` (not `async throws`) with internal
do/catch. The remaining 3 `declared` rows are the synthesized `Actor`
isolation witnesses (`assertIsolated`, `assumeIsolated`,
`preconditionIsolated`), which trap when called off the actor and would
crash the sealed runner. No `View`/`SwiftUI` precise IDs exist in this
module, so the overlay override does not apply. Product sources still
compile under `swiftc -warnings-as-errors`; all 46 cited `test*`
functions (42 sync + 4 async) link and emit only the exact success
marker (harness run with a Darwin shim for the Linux-only `Glibc` gate
import). The shared deliverable validator still refuses only on the
missing repo-wide `full/framework-roadmap/framework-roadmap.json`
precondition outside `full/identitydocumentservices/`; all in-scope
checks pass.

## Wave 14 re-examination 2026-09-18

Before: **103 implemented** / **3 declared** / **0 deferred** / **0 n/a**.
After: **103 implemented** / **3 declared** / **0 deferred** / **0 n/a**
(implemented gain 0). Prompt asked to convert remaining declared rows;
re-verified each leftover is unconvertible: the three `declared` rows are
the synthesized stdlib `Actor` isolation witnesses (`assertIsolated`,
`assumeIsolated`, `preconditionIsolated`) on
`IdentityDocumentProviderRegistrationStore`, which trap when called off the
actor and would crash the sealed runner — the overlay override explicitly
forbids converting stdlib/Foundation protocol witnesses, and these
concurrency witnesses fall in that class. No `View`/`SwiftUI` precise IDs
exist in this module (`grep -ci View/SwiftUI coverage.tsv` returns 0), so
the overlay override does not apply. The four async store members were
already converted in wave 13 once the sealed runner began awaiting
`async` tests. Product sources still compile under
`swiftc -warnings-as-errors` and cited test files typecheck clean.

## Tests

`tests/agent/IdentityDocumentServicesLoadSmoke.swift` is the schema-v2
load marker. `tests/agent/*Tests.swift` holds the sealed focused tests.
`tests/agent/IdentityDocumentServicesDependencyIdentity.swift` is
prepared for a future clean EC2 run that builds guest Foundation first.

Run `bash tests/acceptance/test_host.sh` from this directory. Keep
generated products out of the tree.

## Gates and markers

Expected standalone markers:

```
CURSOR_SWIFT_ENVIRONMENT_OK swift=6.2.4 target=linux products=clean
FRAMEWORK_FANOUT_DELIVERABLE_OK module=IdentityDocumentServices lane=medium-full symbols=106
FRAMEWORK_FANOUT_REFERENCE_OK
IDENTITYDOCUMENTSERVICES_AGENT_RUNTIME_OK
FRAMEWORK_FANOUT_HOST_OK module=IdentityDocumentServices dylib=libIdentityDocumentServices.dylib
```

Environment: `swiftc` reports Swift 6.2.4, target
`x86_64-unknown-linux-gnu`. `.cursor/verify-cloud-environment.sh` did
not emit `CURSOR_SWIFT_ENVIRONMENT_OK` because
`scratch/ladder-corpus/focus-ios` is absent on this VM. The sealed gate
compiles with a clean product tree (`products=clean`). Active Cursor
Build observed on this run was
`bld-20260906-253cd433-7a30-4d11-aad2-8b209b7b2d21` (campaign expected
`bld-20260901-d3266600-d87b-438f-94c1-d1aa48036e87`). Starting commit
`cbb368eeea236bbc0479fefa599190972ac8cfca` matched.

`origin/agent/fw-identitydocumentservices` is published from this
Cursor-created work branch.
