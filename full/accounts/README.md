# Accounts

Linux starting point for Apple's public `Accounts` module, reconstructed from
the pinned Xcode 26.1 iPhoneOS symbol graph plus Apple-oracle observations.
This directory is not wired into the shared guest package. A passing isolated
host gate is not integrated Linux success.

## What is real

The public Swift surface compiles to `libAccounts.dylib`.

Oracle-measured constants (asserted in `AccountsRuntime.swift`):

- `ACAccountTypeIdentifierTwitter == "com.apple.twitter"`
- `ACAccountTypeIdentifierFacebook == "com.apple.facebook"`
- `ACAccountTypeIdentifierSinaWeibo == "com.apple.sinaweibo"`
- `ACAccountTypeIdentifierTencentWeibo == "com.apple.account.tencentweibo"`
- `ACErrorDomain == "com.apple.accounts"`
- `NSNotification.Name.ACAccountStoreDidChange.rawValue == "ACAccountStoreDidChangeNotification"`
- Facebook / Tencent option keys retain their exported names; audience values
  are `"everyone"`, `"friends"`, and `"me"`
- `ACErrorCode` named constants raw values `1...23` (`ACErrorUnknown = 1` through `ACErrorCredentialItemNotExpired = 23`)

Also implemented:

- `ACAccountCredentialRenewResult` (`renewed`, `rejected`, `failed`)
- Completion-handler typealiases and both callback and `async throws` overloads
  of `saveAccount`, `removeAccount`, `requestAccessToAccounts`, and
  `renewCredentials`
- Local `ACAccount` / `ACAccountCredential` objects and `ACAccountType`
  descriptors obtained from the store

`accountType(withAccountTypeIdentifier:)` returns a populated type whose
`identifier` matches the request for those four known public identifiers, and
returns `nil` for unknown identifiers and for `nil`. `accessGranted` is always
`false`. The observed descriptions are `Twitter`, `Facebook`, `Sina Weibo`, and
`Tencent Weibo`.

## Fail-closed boundaries

Linux has no Apple account daemon, entitlement prompt, or social-network
plugin. The implementation never fabricates a granted account, persisted
identifier, renewed token, or store-changed notification.

- `ACAccountStore.accounts` is empty; `accounts(with:)` returns `[]`;
  `account(withIdentifier:)` returns `nil`.
- `ACAccount.identifier` and `userFullName` stay `nil` (nothing is saved).
- Access, save, remove, and credential renewal never succeed. Callbacks report
  `false` (renew: `.failed`) plus Foundation `NSError` with domain
  `com.apple.accounts` (`ACErrorDomain`) and code `7`
  (`ACErrorPermissionDenied`).
- Those completions hop once with `DispatchQueue.async` onto a private serial
  queue (label `Accounts.ACAccountStore.completion`).
  Delivery is exactly-once per call. A nil handler is not invoked. Nested
  callback calls enqueue behind the running handler (`async`, never `sync`).
  Tests prove non-inline ordering through an `OpenUIKitHost` SPI hook that
  occupies the queue, records return under a lock, releases it, then asserts
  the callback saw `returned == true` and `count == 1`. The hook is absent from
  ordinary `import Accounts` API and from the pinned Apple surface.
- Async overlays wait on the same callback path and throw the same fail-closed
  `NSError`.
- The store never posts `ACAccountStoreDidChange`.

## Still open

See `oracle-questions.tsv` for Darwin callback-queue / `(false, nil)` versus
error mapping, async `renewCredentials` throw-versus-return, and identifier
assignment after a successful save. Private TBD types remain out of scope.

`tests/agent/AccountsRuntime.swift` is the isolated host probe
(`ACCOUNTS_AGENT_RUNTIME_OK`). `tests/agent/AccountsDependencyIdentity.swift`
is prepared for a future clean EC2 run that builds guest Foundation first and
prints `ACCOUNTS_DEPENDENCY_IDENTITY_OK` only after assertions pass. Compiling
that file against toolchain Foundation is not guest-Foundation success.

Run `bash tests/acceptance/test_host.sh` from this directory. Keep generated
products out of the tree.
