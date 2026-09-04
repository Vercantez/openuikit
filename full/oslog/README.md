# OSLog (Linux starting point)

This directory is a clean-room Linux starting point for Apple's public
`OSLog` module (the unified-log *store* / entry surface), seeded from the
Xcode 26.1 iPhoneOS 26.1 symbol graph, API digester, and TBD exports. It is
not wired into the shared guest package; that integration is a later
central-review step.

The existing portable `OSLogPortable` contract is kept. On Darwin the module
still re-exports the lower-level `os` Logger / signpost identity used by the
IceCubes consumer proof. The isolated Linux host gate compiles Foundation
only and does not import `os`.

## What is real

- Nested `NS_ENUM` / `OptionSet` identities use the pinned `dotnet/macios`
  raw values (`OSLogEntryLog.Level.debug == 1`,
  `OSLogStore.Scope.currentProcessIdentifier == 1`,
  `OSLogEnumerator.Options.reverse == 1`, and the matching store-category /
  signpost-type / argument-category sequences).
- `OSLogStore.init(scope: .currentProcessIdentifier)` returns an empty
  in-memory query handle. Linux has no `logd` catalog, so `getEntries` yields
  no rows rather than inventing log content.
- `position(date:)`, `position(timeIntervalSinceEnd:)`, and
  `position(timeIntervalSinceLatestBoot:)` return opaque `OSLogPosition`
  tokens. They are not applied against an Apple timesync database.
- `OSLogMessageComponent.Argument` cases are constructible value tokens
  (`undefined`, `data`, `double`, `signed`, `string`, `unsigned`).
- `OSLogPortable.supportsUnifiedLogging` remains `false`.

`tests/agent/OSLogRuntime.swift` is a standalone probe that prints
`OSLOG_AGENT_RUNTIME_OK`. The sealed schema-v2 gate derives its runner from
`implemented` coverage and `*Tests.swift`.

## Fail-closed boundaries

- `OSLogStore.init(url:)` and `init(URL:)` throw
  `OSLogPortable.StoreError.logArchiveUnavailable`. The `.logarchive` bytes
  and catalog chunk layout are not in the public seed.
- `OSLogEntry` / `OSLogMessageComponent` `init(coder:)` returns `nil`.
  Apple's keyed-archive keys are unobserved, so no payload is invented.
- `getEntries(with:at:matching:)` ignores options, position, and
  `NSPredicate` because there are no rows to filter. Predicate/KVC matching
  against live unified-log content is unobserved.
- Entry subclasses exist for source compatibility. Public construction is
  unavailable; Linux does not mint catalog rows.

## Deferred

These need a central Apple-runtime oracle or a real log archive before they
can be marked `implemented`:

- Materializing `OSLogEntry`, `OSLogEntryLog`, `OSLogEntrySignpost`,
  `OSLogEntryActivity`, `OSLogEntryBoundary`, and `OSLogMessageComponent`
  instances from a store.
- `OSLogEnumerator` as an `NSEnumerator` (the Swift overlay returns
  `AnySequence` and Linux has no rows to enumerate).
- Protocol witnesses on live process/payload entries
  (`OSLogEntryFromProcess`, `OSLogEntryWithPayload`).
- Whether `init(scope:)` on iOS ever fails, and how `NSPredicate` / position
  filter a non-empty catalog.

`tests/agent/OSLogDependencyIdentity.swift` imports `OSLog` and `Foundation`
and passes real `URL`, `Date`, `TimeInterval`, `NSPredicate`, `Data`, and
`NSNumber` values through public APIs. It is for a later clean EC2
integration build; the isolated host gate does not compile it.
