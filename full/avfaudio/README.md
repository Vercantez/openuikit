# AVFAudio Linux starting point

This directory is a **clean-room Linux starting point** for Apple's public `AVFAudio` module, seeded from the Xcode 26.1 iPhoneOS SDK symbol graphs. It is not a claim of Apple behavioral parity, and it is **not** an integrated Linux success until a future EC2 cold build imports the real dependency modules, builds and load-tests `libAVFAudio.dylib`, and passes `tests/agent/AVFAudioDependencyABI.swift`.

## Dependencies

Product sources `import Foundation` and, when the compiler can see them, bind the shared `CoreAudioTypes`, `AudioToolbox`, `CoreMIDI`, and `CoreMedia` modules. This tree does **not** redeclare those modules' C types, aliases, callback ABIs, or constants. `AudioBufferList` is never modeled as a one-element Swift stand-in.

The current isolated host gate compiles AVFAudio without those modules on the search path, so C-ABI signatures are compiled only under `#if canImport(...)`. Linux host controls are `@_spi(OpenUIKitHost)` (`AVFAudioHostAvailability`).

## What has runtime evidence

- **Formats and software PCM.** `AVAudioFormat` from common format, standard mono/stereo, and settings dictionaries. `AVAudioPCMBuffer` allocates zeroed planar or interleaved storage and exposes float channel pointers and stride. No-copy `AudioBufferList` ownership is compiled only when CoreAudioTypes/AudioToolbox is imported.
- **Engine graph bookkeeping.** Attach/connect/disconnect and connection-point queries. `connect` replaces the existing edge for `(destination, inputBus)`. `start()`, manual rendering, and offline render **throw** and do not set `isRunning` or produce buffers.
- **Session preferences.** `setCategory` stores category/mode/options. Activation, port override, and hardware configuration **throw**. Record permission is delivered **asynchronously**, exactly once, on `AVFAudio.callback`.
- **Player / recorder / converter / sequencer.** `AVAudioPlayer` throwing URL initializers use throwing I/O. Empty or garbage payloads throw; only a narrowly validated 16-bit linear PCM WAVE construct. Play, record, convert, and sequencer start stay fail-closed.
- **Speech.** Utterance text is stored. `speak` does not set `isSpeaking`. Personal-voice authorization is `.unsupported`, delivered asynchronously on the callback queue.

## Fail-closed boundaries

| Surface | Linux behavior |
| --- | --- |
| Hardware playback / capture | `play()` / `record()` return false |
| Engine I/O and render | `start` / manual render throw; `isRunning` stays false |
| Session activation / hardware | `setActive` and preferred hardware APIs throw |
| Apple speech voices | Empty catalog; no PCM is synthesized |
| Personal Voice | `.unsupported`, async callback |
| Codecs, AU graphs, MusicSequence | Host-unavailable `NSError` |
| `AVAudioUnitComponent.icon` | Unavailable (UIKit) |

Asynchronous callbacks are non-inline, exactly-once, non-reentrant, and delivered on the serial queue `AVFAudio.callback` (`AVFAudioHostAvailability.callbackQueue`).

## Tests

- `tests/agent/AVFAudioRuntime.swift` prints `AVFAUDIO_AGENT_RUNTIME_OK`.
- `tests/agent/AVFAudioCorpus.swift` compiles Signal `AVSpeechSynthesizer`/delegate/utterance, Telegram `AVAudioSession.sharedInstance`/`outputVolume`, and Nextcloud `AVAudioApplication` record permission.
- `tests/agent/AVFAudioDependencyABI.swift` (and `AVFAudioDependencyABI.c`) is a **future EC2** mixed C/Swift identity/ABI probe. It is not executed by the isolated host gate. Do not treat a green host gate as integrated Linux ABI success.

The mixed probe is executable rather than documentary. On a host with canonical
dependency modules and headers, it builds `AVFAudioDependencyABI.c`, links the C
object into the Swift probe, compares the C and Swift sizes, alignments, and
`AudioBufferList` field offsets, walks a four-buffer flexible list, and verifies
the loaded AVFAudio image:

```sh
bash tests/agent/test_avfaudio_dependency_abi.sh canonical
```

Additional dependency search, library, or header arguments can be supplied as
repeated `--swift-arg ARG` and `--clang-arg ARG` pairs. The current repository
boundary can be checked separately with `repository` mode. That mode refuses
until the dependency-owned `AudioToolbox` and `CoreMedia` modules provide the
canonical CoreAudioTypes, AudioToolbox, and CoreMedia declarations; it never
substitutes AVFAudio-local lookalikes.

Run the immutable host gate:

```sh
bash tests/acceptance/test_host.sh
```
