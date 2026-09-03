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
  name / description / keywords / text. `init(contentType:)` uses
  UniformTypeIdentifiers when that module exists and a module-local `UTType`
  lookalike on the isolated Linux host (UniformTypeIdentifiers is not a
  seeded dependency).
- `CSSearchQuery` runs against `CSSearchableIndex.default()` using the
  existing portable term matcher. Handlers run synchronously after `start()`.
  `CSUserQuery` reuses that path and yields **no** `CSSuggestion` values.
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

## Deferred

- `NSUserActivity.contentAttributeSet` — `NSUserActivity` is not in Linux
  Foundation.
- `CoreSpotlightAPIVersion` — the Int32 payload is not in the public inputs.
- Apple's CSSearchQuery DSL, callback queue, mailbox string payloads, client
  state size cap, and suggestion ranking remain oracle questions.

Run the sealed host gate with:

```sh
python3 -B full/framework-fanout/validate_seed.py --framework full/corespotlight --phase deliverable
bash full/corespotlight/tests/acceptance/test_host.sh
```
