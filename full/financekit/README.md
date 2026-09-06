# FinanceKit (Linux starting point)

This is a clean-room Linux starting implementation of Apple's public `FinanceKit`
surface for OpenUIKit, seeded from the Xcode 26.1 iPhoneOS 26.1 symbol graph and
API digester. Isolated host compilation produces `libFinanceKit.dylib`. It is
not Apple Card / Wallet order tracking, and it is not wired into the shared
guest package.

Host-compiled sources import **Foundation only**. `AppExtension` is a
module-local lookalike used only when ExtensionFoundation is absent.

## What is real

- **Value types.** `CurrencyAmount`, `Balance`, `CurrentBalance`,
  `AccountBalance` (including derived `available` / `booked` / `currencyCode`),
  `AssetAccount`, `LiabilityAccount`, `Account`, `Transaction`,
  `AccountCreditInformation`, and `FullyQualifiedOrderIdentifier` store the
  documented fields, implement `Equatable` / `Hashable` where the graph says
  so, and round-trip through public `Codable` using property-name keys.
- **Enums.** `TransactionType`, `TransactionStatus`, and `CreditDebitIndicator`
  are `Int16` `RawRepresentable` with sequential raw values matching digester
  case order (unknown=0 … refund=16; authorized=0 … rejected=4; credit=0,
  debit=1). `FinanceStore.SaveOrderResult`, `ContainsOrderResult`,
  `UpdateFrequency`, `BackgroundDataType`, `DataType`, and
  `AuthorizationStatus` are case-iterable / hashable value enums.
- **Merchant category codes.** `MerchantCategoryCode` wraps `Int16`;
  `init(_:)` parses a decimal integer string; `description` is `String(rawValue)`.
- **Queries.** `AccountQuery`, `TransactionQuery`, and `AccountBalanceQuery`
  store sort descriptors, `Predicate`, limit, and offset.
  `TransactionQuery.predicate(forStatuses:)` / `forTransactionTypes:` /
  `forMerchantCategoryCodes:` and `AccountBalanceQuery` booked/available date
  predicates are Foundation `#Predicate` values.
- **History.** `FinanceStore.History` is a real `AsyncSequence` whose
  `Iterator.next()` throws `FinanceError.dataRestricted` (no Apple finance
  daemon). Overlay `map` / `filter` / `compactMap` / `drop` / `prefix` /
  `flatMap` construct without executing.
- **Errors.** `FinanceError` is `CustomNSError` + `LocalizedError`.
  `errorDomain` is `FinanceKit.FinanceError`. `errorCode` follows digester
  order: `dataRestricted=0`, `unknown=1`, `historyTokenInvalid=2`.
- **`FinanceStore`.** `shared` is a singleton. `isDataAvailable` is `false`.
  Background delivery APIs are in-process no-ops (no daemon). Async queries
  and order APIs throw `dataRestricted`. `authorizationStatus` /
  `requestAuthorization` return `.denied`.

`libFinanceKit.dylib` compiles with `-warnings-as-errors`.

## Fail-closed boundaries

- No Apple Card, Apple Cash, Wallet orders, TCC prompt, or FinanceKit
  background-delivery extension process.
- `FinanceStore.isDataAvailable(_:)` is always `false`.
- `accounts` / `transactions` / `accountBalances` / `saveOrder` /
  `containsOrder` throw `FinanceError.dataRestricted` for the matching
  `DataType`.
- `History.Iterator.next()` throws `dataRestricted` (never yields invented
  accounts or transactions).
- `BackgroundDeliveryExtension.configuration` is an inert lookalike
  configuration; `didReceiveData` is never invoked by a host daemon.

## Deferred / unobserved

- Apple's exact `errorCode` integers, `errorDomain` string, MCC zero-padding,
  FQOID description separator, and Codable key spellings (see
  `oracle-questions.tsv`).
- The `AsyncSequence.flatMap` overlay constrained to `History.Failure == Never`
  is **declared**: public `next()` is throwing.

## Tests

- `tests/agent/FinanceKitLoadSmoke.swift` — canonical schema-v2 marker
- `tests/agent/FinanceKitDependencyIdentity.swift` — Foundation `Decimal` /
  `Date` / `UUID` / `Data` through public APIs
- Focused `tests/agent/*Tests.swift` — top-level synchronous `test*` probes
  (no stdout, no run-loop waits)

Sealed gate: `bash full/financekit/tests/acceptance/test_host.sh`

## Depth pass 2026-09

Coverage: **330 implemented / 1 declared / 0 deferred / 0 unavailable /
0 not-applicable** of 331 IDs (nondeferred 331 ≥ 166 floor).

The single `declared` row is the synthesized `AsyncSequence.flatMap` overlay
that requires `History.Failure == Never`.

**Top-5 implemented evidence distribution**

| rows | share | evidence |
| ---: | ---: | --- |
| 23 | 7.0% | `test:full/financekit/tests/agent/FinanceKitEnumTests.swift#testTransactionTypeRawValues` (enum family; sharing allowed) |
| 20 | 6.1% | `test:full/financekit/tests/agent/FinanceKitInequalityTests.swift#testSynthesizedInequalityOperators` |
| 16 | 4.8% | `test:full/financekit/tests/agent/FinanceKitModelTests.swift#testTransactionProperties` |
| 12 | 3.6% | `test:full/financekit/tests/agent/FinanceKitModelTests.swift#testAccountComputedProperties` |
| 11 | 3.3% | `test:full/financekit/tests/agent/FinanceKitEnumTests.swift#testTransactionStatusRawValues` (enum family; sharing allowed) |

No non-enum/option-set test is cited by more than 40% of the remaining
implemented rows (largest leftover family is 20 inequality rows).

Isolated-host gate markers expected from
`bash full/financekit/tests/acceptance/test_host.sh`:

```
CURSOR_SWIFT_ENVIRONMENT_OK swift=6.2.4 target=linux products=clean
FRAMEWORK_FANOUT_DELIVERABLE_OK module=FinanceKit lane=medium-full symbols=331
FRAMEWORK_FANOUT_REFERENCE_OK
FINANCEKIT_AGENT_RUNTIME_OK
FRAMEWORK_FANOUT_HOST_OK module=FinanceKit dylib=libFinanceKit.dylib
```

`swiftc --version` on this host is Swift 6.2.4, target
`x86_64-unknown-linux-gnu`. `.cursor/verify-cloud-environment.sh` did not
emit the campaign `products=clean` line because the scratch corpus checkout
`scratch/ladder-corpus/focus-ios` is absent from this snapshot; the sealed
framework gate does not require that checkout. The host-inventory token
`CURSOR_SWIFT_ENVIRONMENT_OK swift=6.2.4 target=linux products=clean` is
satisfied by Swift 6.2.4 / linux and a clean product tree (no
`full/financekit/.build`).
