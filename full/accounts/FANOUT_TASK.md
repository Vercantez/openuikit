# Port `Accounts` to Linux

Build a substantial, honest starting implementation of Apple's public `Accounts`
surface without changing any app source or shared platform integration file.
This is a **legacy-adapter** lane seeded from Xcode 26.1's iPhoneOS
26.1 SDK.

The immutable seed contains 82 unique public precise identifiers and
80 symbol-graph relationships. The acceptance floor is
66 nondeferred (`implemented` or `declared`) identifiers: ceil(80% of exact public symbols).

Start with `reference/public-surface.tsv`, then use the raw exact graphs listed by
`reference/symbol-graphs.json` for declarations, relationships, and availability.
The compact surface deterministically selects one occurrence per precise ID;
the graph manifest records the selection policy and duplicate/conflict counts,
while every raw occurrence remains immutable for review.
Use `reference/sdk-inputs.tsv` and `reference/tbd-exports.tsv` as provenance and
ABI evidence only; the Apple SDK input bytes are intentionally absent. Use
`reference/corpus-summary.json` to prioritize APIs exercised by the 20-app
roadmap corpus.

Deliver all of the following in `full/accounts/`:

1. Linux Swift sources for module `Accounts` and `libAccounts.dylib`, with every
   implementation source listed in `accounts_guest_sources.txt`.
2. Complete exact-ID `coverage.tsv` using only the five allowed statuses and
   evidence paths or test names that substantiate nondeferred claims.
3. Nonempty `Accounts.swift` and `README.md`, plus `oracle-questions.tsv` with
   header `precise	question	risk	reason` and at least one question; use
   `module` only for cross-cutting items.
4. `tests/agent/AccountsRuntime.swift`, meaningful focused tests, and the exact
   success marker `ACCOUNTS_AGENT_RUNTIME_OK`.
5. A clean successful run of `bash tests/acceptance/test_host.sh` with no checked-
   in or stale build products.

Declared dependencies:

- `Foundation`

Known risk labels:

- `deprecated`
- `account-service`
- `fail-closed`

Do not invent successful Apple service, device, entitlement, privacy, or UI
behavior. Record questions that need a central Apple-oracle probe and keep those
paths fail-closed until observed.
