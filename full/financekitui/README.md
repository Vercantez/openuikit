# FinanceKitUI

Linux starting point for Apple's public `FinanceKitUI` module, reconstructed
from the pinned Xcode 26.1 iPhoneOS symbol graph. Isolated host-gate success
is not integrated Linux success.

## Depth pass 2026-09

SDK depth for `FinanceKitUI` in `full/financekitui/` (1576 exact IDs). This is
a fresh seed: owned FinanceKitUI types are implemented with focused
synchronous tests. Synthesized SwiftUI `View` identity modifiers are
declared (Linux has no layout engine). There are no enum or option-set
members in the owned census, so no table-driven value sharing.

Coverage this round: **40 implemented / 1536 declared / 1576 total**
(1576 nondeferred, floor 1261). No test is cited by more than one
implemented row (2.5% of implemented rows).

Top-5 implemented evidence:

| Rows | Share | Evidence |
| ---: | ---: | --- |
| 1 | 2.5% | `TransactionPickerTests.swift#testTransactionPickerStruct` |
| 1 | 2.5% | `TransactionPickerTests.swift#testTransactionPickerBody` |
| 1 | 2.5% | `AddOrderToWalletButtonTests.swift#testAddOrderToWalletButtonInitSignedArchive` |
| 1 | 2.5% | `FinancialConnectionUITests.swift#testFinancialConnectionExtensionAuthorizationResultInitFrom` |
| 1 | 2.5% | `FinancialConnectionUITests.swift#testFinancialConnectionExtensionAuthorizationRequestCompleteResult` |

The remaining 35 implemented rows each have their own test.

Environment: `swiftc` reports Swift 6.2.4, target `x86_64-unknown-linux-gnu`.
`.cursor/verify-cloud-environment.sh` did not emit
`CURSOR_SWIFT_ENVIRONMENT_OK` because `scratch/ladder-corpus/focus-ios` is
absent on this VM. The sealed gate compiles with a clean product tree
(`products=clean`). Active Cursor Build observed on this run was
`bld-20260906-253cd433-7a30-4d11-aad2-8b209b7b2d21` (campaign expected
`bld-20260901-d3266600-d87b-438f-94c1-d1aa48036e87`). Starting commit
`26f5086c5b31ba816742f18d3096152cd32280f4` matched.

`bash full/financekitui/tests/acceptance/test_host.sh` ended:

```
FRAMEWORK_FANOUT_DELIVERABLE_OK module=FinanceKitUI lane=leaf-full symbols=1576
FRAMEWORK_FANOUT_REFERENCE_OK
FINANCEKITUI_AGENT_RUNTIME_OK
FRAMEWORK_FANOUT_HOST_OK module=FinanceKitUI dylib=libFinanceKitUI.dylib
```

The campaign inventory stamp `CURSOR_SWIFT_ENVIRONMENT_OK swift=6.2.4 target=linux products=clean` is a host-inventory token, not printed by the sealed framework gate. `swiftc` is Swift 6.2.4 / linux and the gate compiled with a clean product tree.

### What is real

- `TransactionPicker` stores a `Binding<[Transaction]>` and label. Fresh
  construction records selection count. `body` is `EmptyView`.
- `View.transactionPicker(isPresented:selection:)` returns `self` and
  records the presentation flag plus selection count. It does not present a
  sheet and does not write back into either binding.
- `AddOrderToWalletButton` stores the signed archive and completion. Init
  does not invoke the completion.
- `AddOrderToWalletButtonStyle.black` and `.blackOutline` are distinct
  hashable values. `addOrderToWalletButtonStyle` records the last style.
- `FinancialConnectionExtensionAuthorizationResult` round-trips `params`
  through `JSONEncoder` / `JSONDecoder` with a keyed `params` field.
- `FinancialConnectionExtensionAuthorizationRequest.complete` delivers the
  first result synchronously and ignores later completes.
- `FinancialConnectionUIExtension.configuration` wraps `body` in an
  isolation `AppExtensionSceneConfiguration`.

### Fail-closed boundaries

- `FinanceKitUIHostControl.failClosedPendingWalletButtons()` invokes retained
  completions with `FinanceKitUIUnavailable.linuxHost(operation:
  "AddOrderToWalletButton")`. Linux never reports `SaveOrderResult.added`.
- Applying `transactionPicker` does not query `FinanceStore` and never
  shows a picker.
- `authorize(_:)` on the sample extension completes with
  `FinanceKitUIUnavailable.linuxHost`. There is no bank-login sheet.
- `FinancialConnectionUIExtensionAuthorizationScene` stores the content
  closure and does not render it.

### Still deferred / unobserved

- Wallet badge artwork, PKAddPassButton mapping, and save-order error
  codes (see `oracle-questions.tsv`).
- Transaction picker sheet lifecycle and the FinanceKit query that feeds it.
- Authorization request completion queue and Apple Codable keys.
- TBD-only ABI (`OrderImage`, `ShippingBox`, `OrderReceipt`, …) is outside
  the public Swift census and is not declared here.

## Depth pass 2026-09 (wave 8)

Wave 8 began at **40 implemented / 1536 declared / 0 deferred / 0
unavailable / 0 not-applicable** and ends at **40 implemented / 1536
declared / 0 deferred / 0 unavailable / 0 not-applicable**. The complete
non-overlay FinanceKitUI census is the 40 implemented rows; all 1536 other
rows have `s:7SwiftUI4View...::SYNTHESIZED::` precise identifiers and are
SwiftUI cross-import overlay re-exports. Consequently there is no remaining
non-overlay family that can honestly be moved from `declared` to
`implemented`, and no unavailable row requiring a hardware, daemon, or
entitlement rationale.

The depth-pass direction says overlay re-exports are `not-applicable`, while
the immutable leaf-full acceptance policy requires at least 1261 rows in its
`implemented` or `declared` statuses. Reclassifying all 1536 overlays would
leave 40 nondeferred rows and make the supplied sealed gate fail before it
builds the module. Wave 8 therefore preserves the seed ledger rather than
weakening the gate or falsely claiming that Linux tests exercise SwiftUI-owned
modifiers. Central review should resolve this policy conflict before changing
those rows.

Top-5 implemented evidence distribution remains:

| Rows | Share | Evidence |
| ---: | ---: | --- |
| 1 | 2.5% | `TransactionPickerTests.swift#testTransactionPickerStruct` |
| 1 | 2.5% | `TransactionPickerTests.swift#testTransactionPickerBody` |
| 1 | 2.5% | `AddOrderToWalletButtonTests.swift#testAddOrderToWalletButtonInitSignedArchive` |
| 1 | 2.5% | `FinancialConnectionUITests.swift#testFinancialConnectionExtensionAuthorizationResultInitFrom` |
| 1 | 2.5% | `FinancialConnectionUITests.swift#testFinancialConnectionExtensionAuthorizationRequestCompleteResult` |

Each of the remaining 35 implemented rows also cites a distinct focused,
top-level synchronous test. No implemented evidence is shared between rows.
