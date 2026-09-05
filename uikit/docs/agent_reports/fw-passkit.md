# PassKit corpus surface — agent/fw-passkit

SDK-depth work in `full/passkit/`. No iOS pixel rule and no Catalyst golden
change. Before: **311 implemented / 4911 declared / 51 deferred**. After:
**990 implemented / 4232 declared / 51 deferred**. Named families
`PKPass`, `PKPassLibrary`, `PKPaymentRequest`, `PKPaymentSummaryItem`,
`PKPaymentNetwork`, `PKPassKitError` are nondeferred (hashValue witnesses stay
deferred under `-warnings-as-errors`).

## What was measured

A stored-method ZIP (APPNOTE.TXT local file + central directory + EOCD,
compression method 0) containing `pass.json` with formatVersion 1,
passTypeIdentifier `pass.openuikit.example`, serialNumber `SN-1`,
organizationName `OpenUIKit`, description `Event ticket`, logoText `Logo`,
authenticationToken, webServiceURL, relevantDate `2026-09-05T12:00:00Z`,
generic primary/secondary/auxiliary/back fields, barcode message `HELLO`,
and a location relevantText. `PKPass.init(data:)` on Linux Swift 6.2.4
returns those strings; `localizedValue(forFieldKey:)` returns the field
values; `icon.png` bytes in the archive do not change `icon`; `passURL` is
nil. Non-ZIP bytes and a ZIP without `pass.json` throw
`PKPassKitError.invalidDataError` (rawValue 1). `formatVersion` 99 throws
`unsupportedVersionError` (rawValue 2). A boardingPass style dictionary
exposes `transitType` through `localizedValue`.

`PKPassLibrary.isPassLibraryAvailable()` is false; `passes()` is empty;
`containsPass` is false; `addPasses` completes `.didCancelAddPasses`;
`activate` completions deliver `PKPassKitError.notEntitledError` (rawValue 4).
`PKAddPassesViewController.canAddPasses()` is false; failable inits return
nil; issuer-data init throws `notEntitledError`. `PKPaymentSummaryItem`
amounts `10.00` + `2.50` compare equal to `12.50` via `NSDecimalNumber.adding`.
`PKPaymentNetwork` raw strings (Visa, AmEx, MasterCard, JCB, NAPAS, …) match
the historical identifier spellings. `PKPaymentButton` constructs disabled;
drawing is not modelled.

## Open (not guessed)

- Apple's NSError payload for a signed vs unsigned pkpass, and for deflate
  (method 8) archives.
- `localizedName` vs logoText / .lproj.
- Wallet `passURL` shoebox form.
- Whether `init?(pass:)` is nil solely because `canAddPasses` is false.
- `PKPaymentNetworkAmex` NSString bytes on iPhoneOS 26.1 (TBD has the symbol
  only).

## Gates

`bash tests/acceptance/test_host.sh` is the PassKit host gate (Linux
`swift:6.2-noble`, warnings-as-errors, coverage evidence, marker-only
stdout). No OpenUIKit render rule; Catalyst / iOS suite / real-app pixels
are unchanged. Report lives here rather than a worktree-root `REPORT.md`.
