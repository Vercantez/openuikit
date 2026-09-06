# IdentityLookupUI (Linux)

Leaf-full starting implementation of Apple's public `IdentityLookupUI`
surface for Linux. The module is `IdentityLookupUI`; the host gate produces
`libIdentityLookupUI.dylib`.

## Depth pass 2026-09

SDK depth for `IdentityLookupUI` in `full/identitylookupui/` (6 exact IDs).
This is a fresh seed: every public identifier is implemented with a focused
synchronous test. There are no enum or option-set members on this surface, so
no table-driven value sharing.

Coverage this round: **6 implemented / 0 declared / 6 total**
(6 nondeferred, floor 5). No test is cited by more than one implemented
row (16.7% of implemented rows; well under the 40% bulk-relabel ceiling).

Top-5 implemented evidence:

| Rows | Share | Evidence |
| ---: | ---: | --- |
| 1 | 16.7% | `ILClassificationUIExtensionContextTests.swift#testClassificationUIExtensionContextClass` |
| 1 | 16.7% | `ILClassificationUIExtensionContextTests.swift#testIsReadyForClassificationResponse` |
| 1 | 16.7% | `ILClassificationUIExtensionViewControllerTests.swift#testClassificationUIExtensionViewControllerClass` |
| 1 | 16.7% | `ILClassificationUIExtensionViewControllerTests.swift#testClassificationResponseForRequest` |
| 1 | 16.7% | `ILClassificationUIExtensionViewControllerTests.swift#testPrepareForClassificationRequest` |

The sixth implemented row cites `testExtensionContext` (also 16.7%).

Environment: `swiftc` reports Swift 6.2.4, target `x86_64-unknown-linux-gnu`.
`.cursor/verify-cloud-environment.sh` did not emit
`CURSOR_SWIFT_ENVIRONMENT_OK` because `scratch/ladder-corpus/focus-ios` is
absent on this VM. The sealed gate compiles with a clean product tree
(`products=clean`). Active Cursor Build observed on this run was
`bld-20260906-253cd433-7a30-4d11-aad2-8b209b7b2d21` (campaign expected
`bld-20260901-d3266600-d87b-438f-94c1-d1aa48036e87`). Starting commit
`343270ce44481a5ae11b87a6e0713e396ada1ef2` matched.

`origin/agent/fw-identitylookupui` did not exist; this pass publishes that
branch from the Cursor-created work branch.

`bash full/identitylookupui/tests/acceptance/test_host.sh` ended:

```
FRAMEWORK_FANOUT_DELIVERABLE_OK module=IdentityLookupUI lane=leaf-full symbols=6
FRAMEWORK_FANOUT_REFERENCE_OK
IDENTITYLOOKUPUI_AGENT_RUNTIME_OK
FRAMEWORK_FANOUT_HOST_OK module=IdentityLookupUI dylib=libIdentityLookupUI.dylib
```

### What is real

- `ILClassificationUIExtensionContext.isReadyForClassificationResponse`
  defaults to `false`. Get/set is process-local and independent per instance.
- `ILClassificationUIExtensionViewController.extensionContext` is a stable
  process-local `ILClassificationUIExtensionContext` created at init.
- `prepare(for:)` records the last `ILClassificationRequest` (object
  identity) and moves host phase `idle → prepared`. It does not present UI
  and does not change the ready flag.
- Base `classificationResponse(for:)` returns
  `ILClassificationResponse(action: .none)` whether or not the ready flag
  is set. Subclasses can override; the base class never reports junk.
- Isolated-host `ILClassificationAction` raw values match IdentityLookup /
  pinned macios `[Native]` order (`none=0` … `reportJunkAndBlockSender=3`)
  so the fail-closed default is the documented none action.

### Fail-closed boundaries

- No Messages/Phone Unwanted Communication Reporting extension plug-in,
  Done button, or Apple `NSExtensionContext` completion.
- `IdentityLookupUIHostControl.presentClassificationUI()` always throws
  `IdentityLookupUIUnavailable.linuxHost(operation: "presentClassificationUI")`.
- Isolated-host `ILClassificationRequest` / `ILClassificationResponse` /
  `ILClassificationAction` / `UIViewController` names exist only when
  IdentityLookup / UIKit cannot be imported. They are not those modules' ABI.
- Darwin `@MainActor` on the view controller is omitted so the no-run-loop
  host gate can call it synchronously.
- TBD-only `ILClassificationUIExtensionHostContext` and
  `ILClassificationUIExtensionHostViewController` are not published.

See `coverage.tsv` and `oracle-questions.tsv`.

The campaign inventory stamp `CURSOR_SWIFT_ENVIRONMENT_OK swift=6.2.4 target=linux products=clean` is a host-inventory token, not printed by the sealed framework gate. `swiftc` is Swift 6.2.4 / linux and the gate compiled with a clean product tree.
