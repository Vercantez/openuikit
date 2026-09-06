# IdentityDocumentServicesUI (Linux)

Leaf-full starting implementation of Apple's public
`IdentityDocumentServicesUI` surface for Linux. The module is
`IdentityDocumentServicesUI`; the host gate produces
`libIdentityDocumentServicesUI.dylib`.

## Depth pass 2026-09

SDK depth for `IdentityDocumentServicesUI` in
`full/identitydocumentservicesui/` (31 exact IDs). This is a fresh seed:
every public identifier is implemented with a focused synchronous test.
There are no enum or option-set members on this surface, so no table-driven
value sharing.

Coverage this round: **31 implemented / 0 declared / 31 total**
(31 nondeferred, floor 25). No test is cited by more than one implemented
row (3.2% of implemented rows; well under the 40% bulk-relabel ceiling).

Top-5 implemented evidence:

| Rows | Share | Evidence |
| ---: | ---: | --- |
| 1 | 3.2% | `ISO18013MobileDocumentRequestTests.swift#testISO18013MobileDocumentRequestSceneType` |
| 1 | 3.2% | `ISO18013MobileDocumentRequestTests.swift#testISO18013MobileDocumentRequestSceneBodyTypealias` |
| 1 | 3.2% | `ISO18013MobileDocumentRequestTests.swift#testISO18013MobileDocumentRequestSceneBody` |
| 1 | 3.2% | `ISO18013MobileDocumentRequestTests.swift#testISO18013MobileDocumentRequestSceneInit` |
| 1 | 3.2% | `ISO18013MobileDocumentRequestTests.swift#testISO18013MobileDocumentRequestContextType` |

The remaining 26 implemented rows each also cite one unique test (3.2%).

Environment: `swiftc` reports Swift 6.2.4, target `x86_64-unknown-linux-gnu`.
`.cursor/verify-cloud-environment.sh` did not emit
`CURSOR_SWIFT_ENVIRONMENT_OK` because `scratch/ladder-corpus/focus-ios` is
absent on this VM. The sealed gate compiles with a clean product tree
(`products=clean`). Active Cursor Build observed on this run was
`bld-20260906-253cd433-7a30-4d11-aad2-8b209b7b2d21` (campaign expected
`bld-20260901-d3266600-d87b-438f-94c1-d1aa48036e87`). Starting commit
`26f5086c5b31ba816742f18d3096152cd32280f4` matched.

`origin/agent/fw-identitydocumentservicesui` did not exist; this pass
publishes that branch from the Cursor-created work branch.

### What is real

- `ISO18013MobileDocumentRequestContext.requestingWebsiteOrigin` defaults to
  `nil` and round-trips a stored `URL?`.
- `request` stores the `ISO18013MobileDocumentRequest` value (presentment
  sets, mandatory flag, document type, namespace element `isRetaining`).
- `cancel()` is idempotent and moves host phase `idle → cancelled`. Copies
  share storage because Darwin's `cancel()` is non-mutating on a struct.
- `sendResponse(_:)` never invokes the handler. First call from `idle`
  throws `linuxHost(operation: "sendResponse")`; a second call throws
  `sendResponse.requestInProgress`; after `cancel()` it throws
  `sendResponse.cancelled`.
- `IdentityDocumentWebPresentmentController.delegate` and
  `presentationContextProvider` are weak, default `nil`, and independent
  per instance.
- `performRequests(_:origin:)` records origin and request count, then always
  throws. It does not consult the delegate or presentation anchor.
- `IdentityDocumentRequestSceneBuilder.buildBlock` is identity for one
  scene and a `IdentityDocumentRequestScenePair` for two.
  `buildOptional` wraps some/none; `buildLimitedAvailability` is passthrough.
- `IdentityDocumentProvider.configuration` vends
  `AppExtensionSceneConfiguration` from `body` without an `appex`.
- `performRegistrationUpdates()` is a process-local no-op besides what a
  conforming type records; it never talks to a registration store.

### Fail-closed boundaries

- No Wallet / ISO 18013 web-presentment sheet, website origin verification,
  or Apple `IdentityDocumentPresentmentError` success path.
- `IdentityDocumentServicesUIHostControl.presentWebPresentment()` always
  throws `IdentityDocumentServicesUIUnavailable.linuxHost(operation: "presentWebPresentment")`.
- Isolated-host `ISO18013MobileDocumentRequest` /
  `ISO18013MobileDocumentResponse` /
  `IdentityDocumentWebPresentmentRawRequest` / `UIWindow` / `View` /
  `AppExtension` / `AppExtensionScene` names exist only when those modules
  cannot be imported. They are not those modules' ABI.
- Darwin `@MainActor` and `async throws` are omitted so the no-run-loop
  host gate can call the API synchronously.
- TBD-only `ISO18013MobileDocumentRawRequestScene`,
  `ISO18013MobileDocumentRawRequestContext`, and `sceneIdentifiers` are
  not published.

See `coverage.tsv` and `oracle-questions.tsv`.

The campaign inventory stamp `CURSOR_SWIFT_ENVIRONMENT_OK swift=6.2.4 target=linux products=clean` is a host-inventory token, not printed by the sealed framework gate. `swiftc` is Swift 6.2.4 / linux and the gate compiles with a clean product tree.
