# Accounts

Linux starting point for Apple's public `Accounts` module, reconstructed from
the pinned Xcode 26.1 iPhoneOS symbol graph. This directory is not wired into
the shared guest package; integration is a separate central-review step.

## What is real

The public Swift surface compiles to `libAccounts.dylib`:

- Constants for the four public social account-type identifiers, Facebook /
  Tencent option keys, `ACErrorDomain`, and
  `NSNotification.Name.ACAccountStoreDidChange`.
- `ACErrorCode` as a `UInt32` `RawRepresentable` struct, plus the 23 public
  code constants (`ACErrorUnknown = 1` … `ACErrorCredentialItemNotExpired = 23`).
- `ACAccountCredentialRenewResult` (`renewed = 0`, `rejected = 1`, `failed = 2`).
- Completion-handler typealiases and both callback and `async throws` overloads
  of `saveAccount`, `removeAccount`, `requestAccessToAccounts`, and
  `renewCredentials`.
- Local `ACAccount`, `ACAccountType`, and `ACAccountCredential` objects.
  Username, description, account type, and OAuth tokens can be stored in
  process. `accountType(withAccountTypeIdentifier:)` returns a descriptor
  whose `identifier` matches the request.

`Hashable` / `Equatable` on `ACErrorCode` and `ACAccountCredentialRenewResult`
come from the Swift protocol synthesis recorded in the graph.

## Fail-closed boundaries

Linux has no Apple account daemon, entitlement prompt, or social-network
plugin. The implementation never fabricates a granted account, persisted
identifier, renewed token, or store-changed notification.

- `ACAccountType.accessGranted` is always `false`.
- `ACAccountStore.accounts` is empty; `accounts(with:)` returns `[]`;
  `account(withIdentifier:)` returns `nil`.
- `ACAccount.identifier` and `userFullName` stay `nil` (nothing is saved).
- Access, save, remove, and credential renewal complete once with
  `granted/saved/removed = false` and an `NSError` in `ACErrorDomain` whose
  code is `ACErrorPermissionDenied`. The `async throws` overloads throw that
  same error and never return `.renewed`.
- Completions run synchronously on the caller’s thread. Apple queue timing is
  not claimed.

## Still deferred / oracle

String payloads and numeric codes follow Apple’s published identifiers, not a
live Darwin probe. Questions in `oracle-questions.tsv` cover raw notification
strings, `requestAccess` `(false, nil)` versus error, unknown-type nil vs
object, identifier assignment after save, and async mapping of
`renewCredentials`. Private TBD types (`ACDManagedAccount`, entitlement
keys, dataclasses) are outside the public graph and are not declared.

Run `bash tests/acceptance/test_host.sh` from this directory. Keep generated
products out of the tree.
