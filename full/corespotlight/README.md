# CoreSpotlight (Linux starting point)

This directory is a clean-room Linux starting point for Apple's public
`CoreSpotlight` module, seeded from the Xcode 26.1 iPhoneOS 26.1 symbol
graph, API digester, and TBD exports. It keeps the existing process-local
named index and extends it to the wave-5 deliverable gate. It is not wired
into the shared guest package; that integration is a later central-review
step.

## What is real

- The portable index, item snapshots, callback and async CRUD, domain
  deletion, expiration filtering, term queries, batch client state, and
  AppIntents entity mutation hooks from the original lane remain.
- `CSIndexError` / `CSSearchQueryError` are `Foundation._BridgedStoredNSError`
  wrappers. `Code` raw values match the pinned `dotnet/macios` enum
  (`unknownError = -1` through `mismatchedClientState = -1006`; query errors
  `-2000...-2003`). Empty unique identifiers fail with `invalidItemError`;
  mismatched batch state fails with `mismatchedClientState`.
- `CSSearchableItemAttributeSet` stores the public attribute bag, custom
  keys, `move(from:)`, and a keyed-archive round trip of title / display
  name / description / keywords / text / thumbnail / dates / location /
  custom keys. `init(contentType:)` uses UniformTypeIdentifiers when that
  module exists and a module-local `UTType` lookalike on the isolated Linux
  host (UniformTypeIdentifiers is not a seeded dependency).
- `CSSearchQuery` runs against `CSSearchableIndex.default()`. Predicate
  strings use the documented subset (`attribute == "value"`, comparisons,
  `&&` / `||`, `*` with `c`/`d`). Unprefixed strings still use the portable
  term matcher. Handlers run synchronously after `start()`. `CSUserQuery`
  reuses that path and yields **no** `CSSuggestion` values.
- `CSSearchableItem.expirationDate` defaults to one month from creation.
- `CSCustomAttributeKey` fail-closes empty / `kMD` / `_kMD` / invalid
  character names. Reverse-DNS dots are accepted.
- `fetchData`, `CSImportExtension.update`, and delegate data/fileURL hooks
  fail closed with `indexUnavailableError` or `indexingUnsupported`.
- `FileProtectionType` is the real Foundation type. Linux does not isolate
  index storage by protection class; the value is stored and round-tripped
  only.

Host-compiled sources import Foundation only (plus the optional
UniformTypeIdentifiers when the Darwin SDK is present). The identity probe
`tests/agent/CoreSpotlightDependencyIdentity.swift` imports `CoreSpotlight`
and `Foundation` for the later EC2 integration build.

## Fail-closed boundaries

Linux has no Spotlight daemon, mdworker, or Apple ranking service.

- `fetchData(forBundleIdentifier:itemIdentifier:contentType:)` always throws
  `CSIndexError.indexUnavailableError` and never returns file bytes.
- `CSImportExtension.update` always throws `indexingUnsupported`.
- `CSUserQuery` never invents suggestions or semantic hits.
- `CSUserQuery.prepare()` / `prepareProtectionClasses` are no-ops.
- `userEngaged` records nothing.
- Delegate reindex callbacks are not fired by a system indexer. Tests call
  `@_spi(OpenUIKitHost) _requestDelegateReindexAll()` and
  `_requestDelegateReindex(identifiers:)`.

## Deferred

- `NSUserActivity.contentAttributeSet` — `NSUserActivity` is not in Linux
  Foundation.
- `CoreSpotlightAPIVersion` — the Int32 payload is not in the public inputs.

Apple's callback queue, mailbox string payloads, client-state size cap,
`$time` / `InRange` calendar semantics, and suggestion ranking remain
oracle questions.

Run the sealed host gate with:

```sh
python3 -B full/framework-fanout/validate_seed.py --framework full/corespotlight --phase deliverable
bash full/corespotlight/tests/acceptance/test_host.sh
```

## Depth pass 2026-09

SDK depth for `CoreSpotlight` (599 IDs). The process-local index is now
the full Linux starting point:

- `CSSearchableIndex.default()`, `isIndexingAvailable() == true` for that
  local index, callback/async CRUD, domain/identifier/all deletes with
  completion errors, `beginBatch` / `endBatch(withClientState:)` /
  `fetchLastClientState`, and the documented delegate reindex test hook.
- `CSSearchableItem` unique/domain identifiers, `attributeSet`, `isUpdate`,
  and a one-month default `expirationDate`.
- `CSSearchableItemAttributeSet` documented attributes (title,
  contentDescription, keywords, thumbnailData, contentType via the port's
  `UTType`, displayName, dates, contacts, location),
  `setValue`/`value(forCustomKey:)` with `CSCustomAttributeKey` validation,
  and an NSSecureCoding round trip.
- `CSSearchQuery(queryString:queryContext:)` documented query-language
  subset over the local index; `foundItemsHandler` / `completionHandler` /
  `start` / `cancel` / `isCancelled`.
- `CSUserQuery` (iOS 18) suggestions fail closed (listed, never fabricated).
- `CSIndexExtensionRequestHandler` shape and `CSIndexError` raw values.
- `CSLocalizedString`.

Coverage after this pass: **597 implemented**, **0 declared**, **2 deferred**
(`CoreSpotlightAPIVersion`, `NSUserActivity.contentAttributeSet`). That meets
implemented ≥ 590. The two deferred identifiers cannot be declared on this
isolated Linux host without inventing an Int32 payload or a Foundation type
that does not exist.

Sealed gate (this environment is the Linux host; no docker):

```
CURSOR_SWIFT_ENVIRONMENT_OK swift=6.2.4 target=linux products=clean
FRAMEWORK_FANOUT_DELIVERABLE_OK module=CoreSpotlight lane=medium-full symbols=599
FRAMEWORK_FANOUT_REFERENCE_OK
CORESPOTLIGHT_AGENT_RUNTIME_OK
FRAMEWORK_FANOUT_HOST_OK module=CoreSpotlight dylib=libCoreSpotlight.dylib
```
