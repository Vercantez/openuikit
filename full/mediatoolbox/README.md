# MediaToolbox (Linux starting point)

This directory is a clean-room Linux starting point for Apple's public
`MediaToolbox` module, seeded from the Xcode 26.1 iPhoneOS 26.1 symbol
graph, API digester, TBD exports, and pinned `dotnet/macios` bindings.
It is not wired into the shared guest package.

The public Swift overlay is the audio processing tap plus media-type
name helpers. Linux has no AVFoundation audio graph, MediaToolbox
localization catalog, or Darwin `CFTypeID` registry. Those paths fail
closed. Callback structs, flag bit positions, FourCC name tables, and
the tap identity/storage state machine are real process-local behavior.

## What is real

- `kMTAudioProcessingTapCallbacksVersion_0` is `0`.
- Creation flags `PreEffects` / `PostEffects` are `1 << 0` / `1 << 1`.
- Process flags `StartOfStream` / `EndOfStream` are `1 << 8` / `1 << 9`.
- `MTAudioProcessingTapCreate` accepts exactly one creation flag, version
  `0`, and a required `process` callback. It invokes `init` (when set)
  and publishes the tap. Both flags, neither flag, or a nonzero version
  return `kMTAudioProcessingTapInvalidArgumentErr` (`-12780`, pinned
  macios `MTAudioProcessingTapError.InvalidArgument`) and write `nil`
  into `tapOut`.
- `MTAudioProcessingTapGetStorage` returns the pointer written by `init`,
  or a unique dummy word when `init` is omitted.
- `MTAudioProcessingTap` is a `Hashable` class. `==` / `!=` are identity;
  `hash(into:)` / `hashValue` follow `ObjectIdentifier`.
- `MTCopyLocalizedNameForMediaType` / `SubType` map documented CoreMedia
  FourCCs to interned English names (`vide` → `"Video"`, `avc1` →
  `"H.264"`, …). Unknown codes return `nil`.
- A Linux-only host pump (`MTAudioProcessingTapHostPrepare` /
  `HostProcess` / `HostUnprepare`) fires `prepare` / `process` /
  `unprepare` synchronously so callers can exercise the callback
  state machine without an audio unit graph.

## Fail-closed boundaries

- `MTAudioProcessingTapGetSourceAudio` always returns `-12780` and leaves
  `flagsOut` / `timeRangeOut` / `numberFramesOut` unchanged. There is no
  player, mixer, or hardware source on this host.
- `MTAudioProcessingTapGetTypeID` returns a process-local `'MTAP'`
  marker, not Darwin's registered `CFTypeID`.
- Localized names are English FourCC identities, not Apple's catalog
  strings or `Locale` lookup.
- Isolated-host `CMTime` / `CMTimeRange` / `CMMediaType` /
  `AudioBufferList` / `AudioStreamBasicDescription` exist only when
  CoreMedia / CoreAudioTypes cannot be imported. They match the field
  layouts used by those ports and are dropped under `canImport`.
  `tests/agent/MediaToolboxDependencyIdentity.swift` imports the real
  `CoreFoundation` and `CoreMedia` modules for the later EC2 build.

Sources listed in `mediatoolbox_guest_sources.txt` compile to
`libMediaToolbox.dylib`.

## Depth pass 2026-09

Implemented rows: **32**. Declared: **0**. Nondeferred: **32 / 32**.

Top-5 implemented evidence distribution:

| Citations | Evidence |
| ---: | --- |
| 9 | `MediaToolboxCallbackTests.swift#testCallbacksStructFields` |
| 7 | `MediaToolboxTypealiasTests.swift#testTypealiases` |
| 5 | `MediaToolboxConstantTests.swift#testFlagAndVersionConstants` |
| 4 | `MediaToolboxTapTests.swift#testTapEqualityAndHash` |
| 3 | `MediaToolboxTapTests.swift#testTapCreateInitStorageAndIdentity` |

The five k-constant rows share the table-driven flag/version test. After
that family is excluded, no remaining test exceeds 40% of the remaining
implemented rows (largest: `testCallbacksStructFields` at 9 / 27 =
33.3%).

The sealed host gate was run as `bash full/mediatoolbox/tests/acceptance/test_host.sh`.

Expected markers:

```
CURSOR_SWIFT_ENVIRONMENT_OK swift=6.2.4 target=linux products=clean
FRAMEWORK_FANOUT_DELIVERABLE_OK module=MediaToolbox lane=medium-full symbols=32
FRAMEWORK_FANOUT_REFERENCE_OK
MEDIATOOLBOX_AGENT_RUNTIME_OK
FRAMEWORK_FANOUT_HOST_OK module=MediaToolbox dylib=libMediaToolbox.dylib
```

`swiftc --version` on this host is Swift 6.2.4, target
`x86_64-unknown-linux-gnu`. `.cursor/verify-cloud-environment.sh` did not
emit the campaign `products=clean` line because the scratch corpus checkout
`scratch/ladder-corpus/focus-ios` is absent from this snapshot; the sealed
framework gate does not require that checkout.
