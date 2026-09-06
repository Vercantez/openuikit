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
