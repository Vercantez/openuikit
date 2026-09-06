# OpenAL (Linux starting point)

This directory is a clean-room Linux starting point for Apple's public `OpenAL`
Clang overlay, seeded from the Xcode 26.1 iPhoneOS 26.1 SDK. It produces one
nominal Swift module, `OpenAL`, and a loadable `libOpenAL.dylib`. It is a
**legacy-adapter** for a deprecated 3D audio API. It is not Apple behavioral
parity and it is not wired into the shared guest package.

## What is real

- Overlay scalar types (`ALenum`, `ALuint`, `ALCsizei`, …) with the widths
  recorded in the symbol graph, plus every `LPAL*` / Apple proc-pointer alias.
- OpenAL 1.1 / ALC token values, Apple Spatial Audio room-type ordinals 0–12,
  and `AL_QUEUE_HAS_LOOPED` (`0x9000`).
- A software playback device (`OpenUIKit Soft`) with context create/destroy,
  current-context TLS, attribute lists, enumeration strings, and ALC 1.1
  version queries.
- Source and buffer name generation, `alBufferData` PCM copy, static vs
  streaming source types, queue/unqueue, and the INITIAL/PLAYING/PAUSED/STOPPED
  state machine (including vector play/pause/stop/rewind).
- Listener and source property round-trips (gain, pitch, cones, offsets,
  position/velocity/orientation).
- Documented error codes with sticky-until-query semantics, `alGetEnumValue` /
  `alcGetEnumValue` name tables, and inverse-distance gain arithmetic.

## Fail-closed / not invented

- `alcCaptureOpenDevice` returns `NULL` and `ALC_INVALID_VALUE`. There is no
  microphone. Capture start/stop/samples on a null device report
  `ALC_INVALID_DEVICE`.
- `alGetProcAddress` / `alcGetProcAddress` return `NULL`, including Apple
  Spatial Audio, 3DMixer, source-notification, static-buffer, and output-capturer
  names. Constructed proc-pointer aliases in tests return
  `AL_INVALID_OPERATION` and never apply reverb or mix to a DAC.
- `alSourcePlay` sets `AL_PLAYING` but does not consume buffers on a clock:
  there is no hardware renderer. `AL_BUFFERS_PROCESSED` stays 0 until `Stop`.
- `alEnable` / `alDisable` record `AL_INVALID_ENUM` (OpenAL 1.1 has no
  enableable capabilities). AL extensions are reported empty.

## Still deferred

No public-surface identifier is deferred: all 342 exact IDs are `implemented`
with a focused `test*` function. Remaining Apple questions live in
`oracle-questions.tsv`.

Isolated compile (this environment) can import `Foundation` and
`CoreFoundation`. Run the immutable host gate:

```sh
bash tests/acceptance/test_host.sh
```

## Depth pass 2026-09

Campaign `ios26.1-fwseed-r11`, lane `legacy-adapter`, framework `OpenAL`
(342 IDs). Starting commit `342dd2ee859ac3c9369653620a0b8835883008ad`.

| | implemented | declared | deferred |
|---|---:|---:|---:|
| Seed | 0 | 0 | n/a (no coverage yet) |
| After this pass | **342** | **0** | **0** |

Nondeferred 342. Every `implemented` row cites
`test:full/openal/tests/agent/<File>Tests.swift#testName` for a real
top-level synchronous no-argument `func testName()`.

Top-5 evidence distribution (implemented rows → test):

1. `testALDistanceDopplerAndStrings` — 28 (distance/doppler/getters + matching `LPAL*` aliases)
2. `testALListenerRoundTrip` — 24 (listener get/set + `LPAL*` aliases)
3. `testALSourcePropertiesRoundTrip` — 24 (source properties + `LPAL*` aliases)
4. `testALScalarTypes` — 24 (C scalar typealiases)
5. `testAppleExtensionProcPtrsFailClosed` — 23 (Apple proc-pointer aliases, fail-closed)

Host gate markers from `bash full/openal/tests/acceptance/test_host.sh`:

```
FRAMEWORK_FANOUT_DELIVERABLE_OK module=OpenAL lane=legacy-adapter symbols=342
FRAMEWORK_FANOUT_REFERENCE_OK
OPENAL_AGENT_RUNTIME_OK
FRAMEWORK_FANOUT_HOST_OK module=OpenAL dylib=libOpenAL.dylib
```

`.cursor/verify-cloud-environment.sh` on this snapshot fails earlier
(`missing corpus checkout: scratch/ladder-corpus/focus-ios`) and therefore does
not print `CURSOR_SWIFT_ENVIRONMENT_OK swift=6.2.4 target=linux products=clean`.
`swiftc` is Swift 6.2.4 targeting `x86_64-unknown-linux-gnu`. The sealed gate
compiled a clean product tree (no `.build` / `build` / `scratch` under
`full/openal/`).
