# CallKit for Linux

This directory is a process-local starting implementation of Apple's public
`CallKit` module for the OpenUIKit Linux host. The type, method, and error-code
identities follow the pinned iPhoneOS 26.1 symbol graph (366 precise public
identifiers). Guest sources are listed in `callkit_guest_sources.txt` and build
into `libCallKit.dylib`.

## What is real

- Handles, call updates, provider configuration, transactions, and the full
  `CXAction` tree (start, answer, end, hold, mute, group, DTMF, translation
  metadata) are constructible, copyable where the graph requires it, and
  NSSecureCoding-round-trippable for the coded types.
- `CXProvider`, `CXCallController`, and `CXCallObserver` share a process-local
  call registry. Incoming and outgoing calls can be reported, observed, and
  driven through provider-delegate `perform` callbacks.
- Request validation is honest at the portable boundary: empty transactions,
  missing providers, unknown UUIDs, duplicate UUIDs, and maximum call-group
  overflow fail with `CXErrorCodeRequestTransactionError`.
- Call Directory entry lists can be assembled and locally validated (order,
  duplicates, incremental removal). Completion, reload, enabled-status, and
  Settings opening cannot talk to an Apple extension host.

## Fail-closed boundaries

- No system in-call UI, no cellular/telephony daemon, and no ringing.
- `AVAudioSession` activation/deactivation callbacks are deferred: this module
  is compiled in isolation and does not import AVFoundation.
- `CXProvider.reportNewIncomingVoIPPushPayload` fails closed. There is no
  Notification Service Extension or PushKit host.
- `CXCallDirectoryManager.reloadExtension`, `enabledStatusForExtension`,
  `openSettings`, and `CXCallDirectoryExtensionContext.completeRequest` fail
  closed. Entries are never installed into an OS call-directory database.
- Translation and DTMF actions record requested state only. They do not play
  audio or invoke a translation engine.

## Deferred / still open

See `oracle-questions.tsv` for exact error-domain strings, newer error raw
values, the Call Directory phone-number ceiling, default action timeouts, and
Apple audio-session timing. Those questions need a central Apple-oracle probe.

Run the host gate with:

```sh
bash full/callkit/tests/acceptance/test_host.sh
```
