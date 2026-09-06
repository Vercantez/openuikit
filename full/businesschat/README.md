# BusinessChat (Linux)

Leaf-full starting implementation of Apple's public `BusinessChat` surface
for Linux. The module is `BusinessChat`; the host gate produces
`libBusinessChat.dylib`. Isolated host-gate success is not integrated
Linux success and is not a Messages for Business service.

## Depth pass 2026-09

SDK depth for `BusinessChat` in `full/businesschat/` (21 exact IDs).

**Before** (refused merge at `149078779dfb`): **21 implemented / 0 declared /
21 total**, but `FW_MERGE GATE RED` because
`BCChatActionTests.testChatActionClass` used `BCChatAction.self is AnyClass`
(always-true under `-warnings-as-errors`). Coverage already cited focused
`test*` functions; the ledger was not a bulk relabel. The always-true `is`
made the cited class test uncompilable on the merge host.

**After** this repair: **21 implemented / 0 declared / 21 total** (21
nondeferred, floor 17). `testChatActionClass` now checks
`String(reflecting:)` and `superclass` instead of `is`. Tests remain
split by family (`BCChatActionParameterTests`, `BCChatButtonStyleTests`,
`BCChatActionTests`, `BCChatButtonTests`). Enum cases share one
table-driven raw-value test; every other implemented identifier has its
own test. No non-enum test is cited by more than 1 of the remaining 19
implemented rows (5.3%; cap 40%).

Top-5 implemented evidence:

| Rows | Share | Evidence |
| ---: | ---: | --- |
| 2 | 9.5% | `BCChatButtonStyleTests.swift#testStyleCases` (table-driven style enum / raw values) |
| 1 | 4.8% | `BCChatButtonStyleTests.swift#testStyleType` |
| 1 | 4.8% | `BCChatButtonStyleTests.swift#testStyleInitRawValue` |
| 1 | 4.8% | `BCChatActionParameterTests.swift#testParameterType` |
| 1 | 4.8% | 17 other focused tests, one identifier each |

Environment: `swiftc` reports Swift 6.2.4, target `x86_64-unknown-linux-gnu`.
`.cursor/verify-cloud-environment.sh` did not emit
`CURSOR_SWIFT_ENVIRONMENT_OK` because `scratch/ladder-corpus/focus-ios` is
absent on this VM. The sealed gate compiles with a clean product tree
(`products=clean`). Active Cursor Build observed on this run was
`bld-20260906-253cd433-7a30-4d11-aad2-8b209b7b2d21` (campaign expected
`bld-20260901-d3266600-d87b-438f-94c1-d1aa48036e87`). Starting commit
`343270ce44481a5ae11b87a6e0713e396ada1ef2` matched.

`origin/agent/fw-businesschat` did not exist; this pass publishes that
branch from the Cursor-created work branch.

`bash full/businesschat/tests/acceptance/test_host.sh` ended:

```
FRAMEWORK_FANOUT_DELIVERABLE_OK module=BusinessChat lane=leaf-full symbols=21
FRAMEWORK_FANOUT_REFERENCE_OK
BUSINESSCHAT_AGENT_RUNTIME_OK
FRAMEWORK_FANOUT_HOST_OK module=BusinessChat dylib=libBusinessChat.dylib
```

The campaign inventory stamp `CURSOR_SWIFT_ENVIRONMENT_OK swift=6.2.4 target=linux products=clean` is a host-inventory token, not printed by the sealed framework gate. `swiftc` is Swift 6.2.4 / linux and the gate compiled with a clean product tree.

### What is real

- `BCChatButton.Style` is `.light` (0) then `.dark` (1), matching pinned
  macios `[Native]` order. `init?(rawValue:)` rejects unknown `Int` values.
  Synthesized `Hashable` / `Equatable` are exercised.
- `BCChatAction.Parameter` is a `String` `RawRepresentable` newtype with
  `init(_:)` and `init(rawValue:)` storing the same payload. Static
  `.intent` / `.group` / `.body` use the ObjC constant names exported by
  the TBD (`BCParameterNameIntent`, `BCParameterNameGroup`,
  `BCParameterNameBody`). Darwin NSString payloads are unobserved.
- `BCChatAction.openTranscript(businessIdentifier:intentParameters:)`
  records the identifier and dictionary in-process. It does not open
  Messages and does not construct a `https://bcrw.apple.com` URL.
- `BCChatButton.init(style:)` stores the style. `init?(coder:)` returns
  `nil` (no Apple UI archive on Linux).

### Fail-closed boundaries

- No Messages.app, Messages for Business / Business Chat daemon, or
  business-chat entitlement.
- `BusinessChatHostControl.openTranscriptResult()` always returns
  `BusinessChatUnavailable.linuxHost(operation: "openTranscript")`.
  `didOpenTranscript()` is always `false`.
- Isolated-host `BCChatButton` subclasses `NSObject`. A public `UIControl`
  lookalike is forbidden. Restoring the Darwin `UIControl` superclass is
  an oracle question for a UIKit-linked guest build.
- Darwin `@MainActor` on the button is omitted so the no-run-loop host
  gate can call it synchronously.

See `coverage.tsv` and `oracle-questions.tsv`.
