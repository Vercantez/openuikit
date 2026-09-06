# ThreadNetwork (Linux starting point)

This directory is a fail-closed portable `ThreadNetwork` module for the
OpenUIKit Linux platform. It reconstructs the public Xcode 26.1 iPhoneOS
Swift surface from the sealed symbol graph. Isolated host-gate success is
not integrated Linux / Thread daemon success, and this module is not
wired into the shared guest package.

Coverage: **23 implemented / 0 declared / 0 deferred / 23 total**
(fully nondeferred, above the leaf-full floor of 19).

## Depth pass 2026-09

Fresh seed: no prior implemented/declared split. After this pass:
**23 implemented / 0 declared / 0 deferred**.

Every public precise ID is `implemented` with a dedicated top-level
`func test*()` (23 tests, 23 rows). The 20-app corpus records one
Home Assistant occurrence (`ThreadClientService.swift`).

Top-5 evidence distribution (share of the 23 implemented rows):

| Citations | Evidence |
| ---: | --- |
| 1 | `THClientTests.swift#testTHClientType` |
| 1 | `THClientTests.swift#testTHClientInit` |
| 1 | `THClientTests.swift#testTHClientCheckPreferredNetwork` |
| 1 | `THClientTests.swift#testTHClientIsPreferredAvailable` |
| 1 | `THClientTests.swift#testTHClientAllCredentials` |

No test is cited by more than one implemented row. There are no public
enum/option-set members or C `k…`/`err…` constants in this surface.

## What is real

- `THCredentials` stores `networkName`, `extendedPANID`, `borderAgentID`,
  `activeOperationalDataSet`, `networkKey`, `pskc`, `panID`,
  `creationDate`, and `lastModificationDate` as get-only fields, plus
  `channel` as a `UInt8` get/set field. Host tests construct records via
  `@_spi(OpenUIKitHost)` because Apple publishes no public designated
  initializer (`DisableDefaultCtor` in the pinned macios bindings).
- `channel` mutation stores any `UInt8` (no invented 11...26 clamp) and
  does not rewrite `lastModificationDate`.
- `NSSecureCoding` round-trips every stored field through
  `init(coder:)` / `encode(with:)`. A missing `channel` key decodes as
  `0`. Coding keys follow the ObjC property names (`PSKC` for `pskc`).
- `THClient.init()` constructs a local handle. Completions run inline on
  the caller. Async overlays never suspend.

## Fail-closed boundaries

Linux has no Thread radio, `threadnwt` / Thread daemon, Border Agent, or
manage-credentials entitlement.

- `allCredentials`, `allActiveCredentials`, `preferredCredentials`,
  `credentials(forBorderAgentID:)`, `credentials(forExtendedPANID:)`,
  `storeCredentials`, and `deleteCredentials` always fail with
  `ThreadNetworkError.unavailable`. Completions receive `nil` credentials
  (not an empty-set success) plus that error.
- `checkPreferredNetwork(forActiveOperationalDataset:completion:)` and
  `isPreferredAvailable()` always report `false`.
- Operational-dataset TLV parsing is not invented. `storeCredentials`
  does not inspect dataset bytes.
- `THPreferredNetworkEntry` is exported by the TBD but is not in the
  sealed 23-ID public surface; it is not declared here.
- Apple's NSError domain and integer codes are unobserved;
  `ThreadNetworkError` is a local Swift error.

## Environment and gate

`git rev-parse HEAD` at the start of this seed was
`342dd2ee859ac3c9369653620a0b8835883008ad`. `swiftc` is Swift 6.2.4,
target `x86_64-unknown-linux-gnu`.
`.cursor/verify-cloud-environment.sh` did not emit
`CURSOR_SWIFT_ENVIRONMENT_OK swift=6.2.4 target=linux products=clean`
because `scratch/ladder-corpus/focus-ios` is absent from this snapshot.
The sealed framework gate does not require that checkout. The pod
booted from `bld-20260906-253cd433-7a30-4d11-aad2-8b209b7b2d21` rather
than campaign `bld-20260901-d3266600-d87b-438f-94c1-d1aa48036e87`.

`bash full/threadnetwork/tests/acceptance/test_host.sh` ended:

```
FRAMEWORK_FANOUT_DELIVERABLE_OK module=ThreadNetwork lane=leaf-full symbols=23
FRAMEWORK_FANOUT_REFERENCE_OK
THREADNETWORK_AGENT_RUNTIME_OK
FRAMEWORK_FANOUT_HOST_OK module=ThreadNetwork dylib=libThreadNetwork.dylib
```

The campaign inventory stamp
`CURSOR_SWIFT_ENVIRONMENT_OK swift=6.2.4 target=linux products=clean`
is a host-inventory token, not printed by the sealed framework gate.
`swiftc` is Swift 6.2.4 / linux and the gate compiled with a clean product
tree (`products=clean`).
