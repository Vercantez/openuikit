# FileProviderUI (Linux)

Leaf-full starting implementation of Apple's public `FileProviderUI`
surface for Linux. The module is `FileProviderUI`; the host gate produces
`libFileProviderUI.dylib`.

## Depth pass 2026-09

SDK depth for `FileProviderUI` in `full/fileproviderui/` (22 exact IDs).
This is a fresh seed: owned FileProviderUI types are implemented with focused
tests. Enum cases share one table-driven raw-value test; every other
implemented identifier has its own test.

Coverage this round: **22 implemented / 0 declared / 22 total**
(22 nondeferred, floor 18). No non-enum test is cited by more than 1
implemented row (5.0% of the 20 non-enum-member implemented rows). Enum
cases share a table-driven raw-value test.

Top-5 implemented evidence:

| Rows | Share | Evidence |
| ---: | ---: | --- |
| 2 | 9.1% | `FileProviderUIErrorCodeTests.swift#testErrorCodeCases` (table-driven error enum / raw values) |
| 1 | 4.5% | `FileProviderUIErrorCodeTests.swift#testErrorCodeType` |
| 1 | 4.5% | `FileProviderUIErrorCodeTests.swift#testErrorDomain` |
| 1 | 4.5% | `FileProviderUIActionIdentifierTests.swift#testActionIdentifierType` |
| 1 | 4.5% | 18 other focused tests, one identifier each |

Environment: `swiftc` reports Swift 6.2.4, target `x86_64-unknown-linux-gnu`.
`.cursor/verify-cloud-environment.sh` did not emit
`CURSOR_SWIFT_ENVIRONMENT_OK` because `scratch/ladder-corpus/focus-ios` is
absent on this VM. The sealed gate compiles with a clean product tree
(`products=clean`). Active Cursor Build observed on this run was
`bld-20260906-253cd433-7a30-4d11-aad2-8b209b7b2d21` (campaign expected
`bld-20260901-d3266600-d87b-438f-94c1-d1aa48036e87`). Starting commit
`2abc9defd72942e7a24dcc79779ea5c50e67d75c` matched.

`origin/agent/fw-fileproviderui` did not exist; this pass publishes that
branch from the Cursor-created work branch.

`bash full/fileproviderui/tests/acceptance/test_host.sh` ended:

```
FRAMEWORK_FANOUT_DELIVERABLE_OK module=FileProviderUI lane=leaf-full symbols=22
FRAMEWORK_FANOUT_REFERENCE_OK
FILEPROVIDERUI_AGENT_RUNTIME_OK
FRAMEWORK_FANOUT_HOST_OK module=FileProviderUI dylib=libFileProviderUI.dylib
```

The campaign inventory stamp `CURSOR_SWIFT_ENVIRONMENT_OK swift=6.2.4 target=linux products=clean` is a host-inventory token, not printed by the sealed framework gate. `swiftc` is Swift 6.2.4 / linux and the gate compiled with a clean product tree.

### What is real

- `FPUIExtensionErrorCode` is `.userCancelled` (0) then `.failed` (1), matching
  pinned macios `[Native]` order. `init?(rawValue:)` rejects unknown `UInt`
  values. Synthesized `Hashable` / `Equatable` are exercised.
- `FPUIErrorDomain` is the string `"FPUIErrorDomain"`. The enum conforms to
  `CustomNSError` so `as NSError` yields that domain and the raw code.
- `FPUIActionIdentifier` is a `String` `RawRepresentable` newtype with
  `init(_:)` and `init(rawValue:)` storing the same payload.
- `FPUIActionExtensionContext` tracks a process-local request disposition
  (`active` → `completed` or `cancelled`). The first terminal call wins;
  later complete/cancel calls no-op.
- `domainIdentifier` is `nil` until host SPI injects an
  `NSFileProviderDomainIdentifier`.
- `FPUIActionExtensionViewController.prepare(forAction:itemIdentifiers:)` and
  `prepare(forError:)` record inputs (and are overridable). They do not
  present UI. `extensionContext` is a stable process-local context.

### Fail-closed boundaries

- No Files.app, File Provider UI extension plug-in, or authentication sheet.
- `completeRequest()` / `cancelRequest(withError:)` do not complete an Apple
  `NSExtensionContext` request and do not call into a daemon.
- Isolated-host `NSFileProviderDomainIdentifier` /
  `NSFileProviderItemIdentifier` / `UIViewController` names exist only when
  FileProvider / UIKit cannot be imported. They are not those modules' ABI.
- Darwin `@MainActor` on the view controller is omitted so the no-run-loop
  host gate can call it synchronously.
- `_FPUIActionIdentifierAuthenticate` is not published; its string payload
  is an oracle question.

See `coverage.tsv` and `oracle-questions.tsv`.
