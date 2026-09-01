# Accounts

Linux starting point for Apple's public `Accounts` module, reconstructed from
the pinned Xcode 26.1 iPhoneOS symbol graph. This directory is not wired into
the shared guest package. A passing isolated host gate is not integrated Linux
success.

## What is real

The public Swift surface compiles to `libAccounts.dylib`:

- Declarations for the four social account-type identifiers, Facebook /
  Tencent option keys, `ACErrorDomain`, and
  `NSNotification.Name.ACAccountStoreDidChange`. Exact Darwin string payloads
  are not claimed.
- `ACErrorCode` as a `UInt32` `RawRepresentable` struct and the 23 named
  constants. Numeric Apple mappings are not claimed.
- `ACAccountCredentialRenewResult` (`renewed`, `rejected`, `failed`).
- Completion-handler typealiases and both callback and `async throws` overloads
  of `saveAccount`, `removeAccount`, `requestAccessToAccounts`, and
  `renewCredentials`.
- Local `ACAccount`, `ACAccountType`, and `ACAccountCredential` objects.
  Username, description, account type, and OAuth tokens can be stored in
  process. `accountType(withAccountTypeIdentifier:)` returns a descriptor
  whose `identifier` matches the request. `accessGranted` is always `false`.

`Hashable` / `Equatable` on `ACErrorCode` and `ACAccountCredentialRenewResult`
come from Swift protocol synthesis recorded in the graph.

## Fail-closed boundaries

Linux has no Apple account daemon, entitlement prompt, or social-network
plugin. The implementation never fabricates a granted account, persisted
identifier, renewed token, or store-changed notification.

- `ACAccountStore.accounts` is empty; `accounts(with:)` returns `[]`;
  `account(withIdentifier:)` returns `nil`.
- `ACAccount.identifier` and `userFullName` stay `nil` (nothing is saved).
- Access, save, remove, and credential renewal never succeed. Callbacks report
  `false` (renew: `.failed`) plus an `NSError` whose domain is `ACErrorDomain`
  and whose code is `ACErrorPermissionDenied`'s local raw value.
- Every one of those completions is delivered **exactly once** on the serial
  queue labeled `Accounts.ACAccountStore.completion`. Handlers are not invoked
  on the calling stack (no synchronous / reentrant delivery). A nil handler is
  not invoked. Async overlays wait on that same callback path (`async`, never
  `sync` onto the completion queue) so they share fail-closed behavior without
  deadlock.
- The store never posts `ACAccountStoreDidChange`.

## Still deferred / oracle

Guessed identifier strings, notification names, error-domain bytes, display
descriptions, and numeric `ACErrorCode` mappings are `declared` until a Darwin
probe. See `oracle-questions.tsv`. Private TBD types remain out of scope.

`tests/agent/AccountsRuntime.swift` is the isolated host probe
(`ACCOUNTS_AGENT_RUNTIME_OK`). `tests/agent/AccountsDependencyIdentity.swift`
is prepared for a future clean EC2 run that builds guest Foundation first,
links this module against it, passes Foundation `NSObject` / `NSError` /
`NSArray` / `NSString` / `Date` / `Notification` values through public APIs,
and prints `ACCOUNTS_DEPENDENCY_IDENTITY_OK` only after assertions pass. That
run is not this isolated gate.

Run `bash tests/acceptance/test_host.sh` from this directory. Keep generated
products out of the tree.
