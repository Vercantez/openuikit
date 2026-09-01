# CallKit for Linux

This directory is a process-local starting implementation of Apple's public
`CallKit` module for the OpenUIKit Linux host. The type, method, and error-code
identities follow the pinned iPhoneOS 26.1 symbol graph (366 precise public
identifiers). Guest sources are listed in `callkit_guest_sources.txt` and build
into `libCallKit.dylib`.

The isolated host gate compiles these sources against Foundation only. It does
**not** prove integrated Linux success against a real guest AVFoundation. That
proof is `tests/agent/CallKitDependencyIdentity.swift`, which is not compiled
by `tests/acceptance/test_host.sh`.

## What is real

- Handles, call updates, provider configuration, transactions, and the full
  `CXAction` tree (start, answer, end, hold, mute, group, DTMF, translation
  metadata) are constructible, copyable where the graph requires it, and
  NSSecureCoding-round-trippable for `CXHandle` and `CXCallAction`.
- `CXProvider`, `CXCallController`, and `CXCallObserver` share a process-local
  call registry. Incoming and outgoing calls can be reported, observed, and
  driven through provider-delegate `perform` callbacks.
- Request handling uses atomic full-transaction preflight. UUID ownership is
  validated before any registry mutation. Each action is routed to the provider
  that owns its call. Group actions check both UUIDs, target existence, maximum
  call groups, maximum calls per group, and multiple starts in one transaction.
  A rejected action or a failed `fulfill`/`fail` does not leave partial registry
  mutation; mutation happens only on successful fulfill.
- Nil provider/observer delegate queues schedule on the main queue via
  `async` (header convention; Darwin 26.1 still unattested). Callbacks are
  never re-entered on the same queue from a nested `request`.
- Call Directory entry lists can be assembled and locally validated (order,
  duplicates, incremental removal). Completion, reload, enabled-status, and
  Settings opening cannot talk to an Apple extension host.

## Fail-closed boundaries

- No system in-call UI, no cellular/telephony daemon, and no ringing.
- Canonical `CXProviderDelegate` `didActivate` / `didDeactivate` methods use
  the real `AVFoundation.AVAudioSession` type behind `#if canImport(AVFoundation)`.
  This module never declares a lookalike `AVAudioSession`. Isolated compilation
  omits those methods; they stay `deferred` until an EC2 run builds guest
  AVFoundation first.
- `CXProvider.reportNewIncomingVoIPPushPayload` fails closed. There is no
  Notification Service Extension or PushKit host.
- `CXCallDirectoryManager.reloadExtension`, `enabledStatusForExtension`,
  `openSettings`, and `CXCallDirectoryExtensionContext.completeRequest` fail
  closed. Entries are never installed into an OS call-directory database.
- Translation and DTMF actions record requested state only. They do not play
  audio or invoke a translation engine.
- Error-domain string bytes, `CXCallDirectoryPhoneNumberMax`,
  `CXTranslationEngine` raw values, and newer incoming/request/directory error
  raw values are placeholders or compile-only surface. They are not claimed as
  Darwin ABI.

## Deferred / still open

See `oracle-questions.tsv` for exact error-domain strings, newer error raw
values, the Call Directory phone-number ceiling, translation constants, default
action timeouts, nil-queue Darwin confirmation, and Apple audio-session timing.

Future EC2 dependency identity (not the isolated gate): build guest Foundation
and AVFoundation modules and dylibs first, compile this framework with their
`-I`/`-L` paths, link a client that imports CallKit and the dependencies, pass
a real `AVAudioSession` through both provider-delegate callbacks, run with
`LD_LIBRARY_PATH`, confirm `libCallKit.dylib` is loaded, and expect
`CALLKIT_DEPENDENCY_IDENTITY_OK`.

Run the isolated host gate with:

```sh
bash tests/acceptance/test_host.sh
```
