# OSLog (Linux starting point)

This directory is a clean-room Linux starting point for Apple's public
`OSLog` module (the unified-log *store* / entry surface plus the `Logger` /
`os_log` / `OSSignposter` overlay the 20-app ladder actually calls), seeded
from the Xcode 26.1 iPhoneOS 26.1 symbol graph, API digester, and TBD
exports. It is not wired into the shared guest package; that integration is
a later central-review step.

The isolated Linux host gate compiles Foundation only and does not import
`os`. Overlay types that Darwin re-exports from `os` are declared here so
`import OSLog` is enough to log and then read the current-process store.

## What is real

- Nested `NS_ENUM` / `OptionSet` identities use the pinned `dotnet/macios`
  raw values (`OSLogEntryLog.Level.debug == 1`,
  `OSLogStore.Scope.currentProcessIdentifier == 1`,
  `OSLogEnumerator.Options.reverse == 1`, and the matching store-category /
  signpost-type / argument-category sequences). Probe 2026-09-05 on
  OpenUIKit-2x-fw-oslog (iPhone SE 3rd gen / iOS 26.1) confirmed
  `OSLogType` raw values default=0 info=1 debug=2 error=16 fault=17 and the
  Level sequence 0…5.
- `OSLogStore.init(scope: .currentProcessIdentifier)` is backed by an
  in-process ring (capacity 4096, a port bound). `Logger`, `os_log`, and
  `OSSignposter` append `OSLogEntryLog` / `OSLogEntrySignpost` rows.
  `getEntries(with:at:matching:)` filters them.
- Logger method → `OSLogEntryLog.Level` (same probe): `log`/`notice`/
  `log(level: .default)` → notice(3); `info` → info(2); `warning`/`error` →
  error(4); `critical`/`fault` → fault(5); `trace`/`debug` → debug(1).
  Apple's store dropped debug rows; the ring keeps them.
- Privacy (probe + Apple
  [OSLogPrivacy](https://developer.apple.com/documentation/os/oslogprivacy)
  / [Generating Log Messages](https://developer.apple.com/documentation/os/generating-log-messages-from-your-code)):
  `.sensitive` `composedMessage` is exactly `"<private>"` even
  in-process; `.private` / `.auto` strings are visible in
  `currentProcessIdentifier`; `.private(mask: .hash)` keeps the value
  in-process and records `%{private,mask.hash}s` in `formatString`.
- NSPredicate keys measured on that store: `subsystem`, `category`,
  `messageType` (`"error"` or `0x10`, `"default"` or `0` — not `"notice"`),
  `eventMessage` CONTAINS, `eventType == logEvent`. `level` (0…5) is
  accepted as the brief's documented alias. Darwin parses
  `predicateFormat`; Linux corelibs makes `NSPredicate(format:)`
  unavailable, so `getEntries(matching:)` evaluates `NSPredicate(block:)`
  against the entry.
- `position(date:)` is a start cursor (`date >=`);
  `position(timeIntervalSinceEnd:)` is a window from the newest row.
- `OSLogMessageComponent.Argument` cases are constructible value tokens
  and are filled from live interpolations (string=4, int64=3, double=2,
  uInt64=5, data=1, trailing empty undefined=0).
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
- `OSLogEntryActivity` / `OSLogEntryBoundary` compile but were not
  produced by Logger/OSSignposter on the iOS 26.1 probe (0 activity /
  boundary rows). They stay `declared`.

## Deferred

None. 125 identifiers are `implemented`, 3 `declared` (activity class +
parent id, boundary class). No `deferred` rows.

## Overlay vs `uikit/Sources/os`

Wave-26 `os` accepts the same Logger / `os_log` / `os_signpost` call
shapes and discards them. This module writes the ring. Signpost ID
constants measured on iOS 26.1: `exclusive=0xEEEEB0B5B2B2EEEE`,
`invalid=UInt64.max`, `null=0`. `uikit/Sources/os` swaps invalid/null;
that file is left unchanged.

`tests/agent/OSLogDependencyIdentity.swift` imports `OSLog` and `Foundation`
and passes real `URL`, `Date`, `TimeInterval`, `NSPredicate`, `Data`, and
`NSNumber` values through public APIs. It is for a later clean EC2
integration build; the isolated host gate does not compile it.
