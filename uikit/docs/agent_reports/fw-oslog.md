# fw-oslog — OSLog store, Logger, privacy, signposts

Worktree branch `agent/fw-oslog`. SDK-depth work in `full/oslog/` (128
public IDs). No UI chrome and no `uikit/` render rule.

## Before / after

| gate | before | after |
|---|---|---|
| OSLog coverage | 92 implemented / 36 declared / 0 deferred | **125 implemented / 3 declared / 0 deferred** |
| Host gate (Linux `swift:6.2-noble`) | seed-only | **`FRAMEWORK_FANOUT_HOST_OK`** `OSLOG_AGENT_RUNTIME_OK` |
| Catalyst | 124/124 | unchanged (no render rule) |
| iOS suite | 112/113 (`corner_radius`) | unchanged |
| Real-app floors | 99.137 / 98.535 / 98.548 / 99.469 / 98.639 / 98.133 / 97.516 / 99.511 / 82.170 / 99.760 / 99.689 / 85.393 | unchanged |

Target was implemented ≥ 120 and fully nondeferred. The three leftover
`declared` rows are types the iOS 26.1 probe never produced.

## What was measured

Private SE 2x `OpenUIKit-2x-fw-oslog` (UDID `4CC4EFE8-6888-4808-B743-83684FAD2E8F`),
iOS 26.1, 2026-09-05. Probe sources lived in `/tmp/oslog-probe-fw-oslog/`
(not in the repo).

### OSLogType / Level

| name | raw |
|---|---|
| `OSLogType.default` | 0 |
| `info` | 1 |
| `debug` | 2 |
| `error` | 16 |
| `fault` | 17 |
| `OSLogEntryLog.Level.undefined…fault` | 0…5 |

Logger method → Level (same probe):

| method | Level |
|---|---|
| `log` / `notice` / `log(level: .default)` | notice (3) |
| `info` | info (2) |
| `warning` / `error` | error (4) |
| `critical` / `fault` | fault (5) |
| `trace` / `debug` / `log(level: .debug)` | debug (1) on the port |

Apple's `currentProcessIdentifier` store **dropped** debug/trace rows.
The in-process ring keeps them so those methods are observable.

Apple docs cited for redaction:
[OSLogPrivacy](https://developer.apple.com/documentation/os/oslogprivacy)
and
[Generating Log Messages](https://developer.apple.com/documentation/os/generating-log-messages-from-your-code).

### Privacy (`composedMessage` in-process)

| interpolation | composedMessage |
|---|---|
| `.public` / `.private` / `.auto` string `"hunter2"` | visible (`hunter2`) |
| `.sensitive` string or int | `"<private>"` exactly |
| `.private(mask: .hash)` | still `"hunter2"` in-process; `formatString` is `%{private,mask.hash}s` |

Components (probe): string=4, int64=3, double=2, uInt64=5, data=1,
trailing empty undefined=0. Static strings: one undefined component with
the full text.

### Predicates / reverse / position

Keys that matched on Apple's store: `subsystem`, `category`,
`messageType == "error"` **or** `== 16` (OSLogType raw, not Level 4),
`"default"` / `0` for notice, `"notice"` matches none, `eventMessage CONTAINS`.
`level == 4` did **not** match on Apple; the port still accepts `level` as
Level raw 0…5 (brief).

Apple's Swift `getEntries(with: .reverse)` stayed chronological
(`sameOrder=true`). A future `position(date:)` still returned all rows.
The port **does** reverse and apply `date >=` / since-end (see
`full/oslog/oracle-questions.tsv`).

### Signposts / process fields

Apple's store returned **0** `OSLogEntrySignpost` after
`OSSignposter.beginInterval` / `emitEvent` / `endInterval`. The port
records them so the public subclasses are reachable.

Signpost ID constants: exclusive=`0xEEEEB0B5B2B2EEEE`,
**invalid=`UInt64.max`**, **null=0**.

`process` = `sender` = executable name; `storeCategory` = 0;
`threadIdentifier` ≠ 0 (`pthread_threadid_np` sample 57490599).

No `OSLogEntryActivity` / `OSLogEntryBoundary` from Logger or
OSSignposter → those 3 IDs stay declared.

## Overlay vs `uikit/Sources/os` (unread, unchanged)

Wave-26 `os` accepts the same Logger / `os_log` / `os_signpost` call
shapes and **discards** them. This module writes the ring and returns
store rows.

| item | `full/oslog` | `uikit/Sources/os` |
|---|---|---|
| Logger / os_log | records `OSLogEntryLog` | no-op |
| OSSignposter / os_signpost | records `OSLogEntrySignpost` | function + ID only; no OSSignposter type |
| `OSSignpostID.invalid` | `UInt64.max` (probe) | **0** (swapped with null) |
| `OSSignpostID.null` | `0` (probe) | **`UInt64.max`** |
| `OSLogPrivacy.mask(.hash)` | `%{private,mask.hash}s` | no Mask API |
| `Logger(log:)` | implemented | absent |
| stderr diagnostic | `[subsystem:category] text` | none |

Do not edit `uikit/Sources/os`; the swapped invalid/null constants are a
known overlay bug relative to iOS 26.1.

## Linux NSPredicate

`NSPredicate(format:)` is **unavailable** in swift-corelibs-foundation
(`renamed to init(block:)`). `predicateFormat` is deprecated and fails
`-warnings-as-errors`. Darwin parses `predicateFormat` for the documented
keys. Linux `getEntries(matching:)` calls `evaluate(with: entry)` so
callers use `NSPredicate(block:)`. Agent tests wrap both behind
`oslogPredicate`.

## Open (oracle-questions.tsv)

- Whether Apple ever fails `init(scope: .currentProcessIdentifier)` off-simulator.
- `.logarchive` NSError domain/code and catalog layout.
- ObjC enumerator reverse vs the Swift overlay that stayed chronological.
- Console / other-process redaction of `.private` (in-process shows the value).
- Disagreeing `argumentCategory` / payload pairs.
- `init(coder:)` keyed-archive keys.
- What public API produces `OSLogEntryActivity` / `OSLogEntryBoundary`.
- Whether a later Darwin integration still `@_exported import os`
  (`os_activity_id_t` is **not** re-exported by Darwin `os`; this module
  declares the aliases itself).

## Verification

- Darwin `swiftc -warnings-as-errors` module + agent tests →
  stdout `OSLOG_AGENT_RUNTIME_OK`.
- Docker `swift:6.2-noble` `full/oslog/tests/acceptance/test_host.sh` →
  `FRAMEWORK_FANOUT_HOST_OK module=OSLog dylib=libOSLog.dylib`.
- Linux `swift:6.2-noble` `openrender` release build (no pixel change).
- `uikit/Sources/os` not edited.
