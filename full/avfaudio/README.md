# AVFAudio Linux starting point

This directory is a **clean-room Linux starting point** for Apple's public `AVFAudio` module, seeded from the Xcode 26.1 iPhoneOS SDK symbol graphs. It is not a claim of Apple behavioral parity, and it is **not** an integrated Linux success until a future EC2 cold build imports the real dependency modules, builds and load-tests `libAVFAudio.dylib`, and passes `tests/agent/AVFAudioDependencyABI.swift`.

## Dependencies

Product sources `import Foundation` and, when the compiler can see them, bind the shared `CoreAudioTypes`, `AudioToolbox`, `CoreMIDI`, and `CoreMedia` modules. This tree does **not** redeclare those modules' C types, aliases, callback ABIs, or constants. `AudioBufferList` is never modeled as a one-element Swift stand-in.

The current isolated host gate compiles AVFAudio without those modules on the search path, so C-ABI signatures are compiled only under `#if canImport(...)`. Linux host controls are `@_spi(OpenUIKitHost)` (`AVFAudioHostAvailability`).

## What has runtime evidence

- **Formats and software PCM.** `AVAudioFormat` from common format, standard mono/stereo, and settings dictionaries. `AVAudioPCMBuffer` allocates zeroed planar or interleaved storage and exposes float channel pointers and stride. No-copy `AudioBufferList` ownership is compiled only when CoreAudioTypes/AudioToolbox is imported.
- **Buffer copying.** `AVAudioBuffer` carries the pinned `NSCopying` and
  `NSMutableCopying` relationships. PCM copies own independent storage, retain
  only valid frames, and expose the first `AudioBuffer` byte capacity as
  `frameCapacity`; compressed-buffer copies have the base `AVAudioBuffer`
  dynamic type. These observable details are checked against iOS 26.1.
- **Engine graph bookkeeping.** Attach/connect/disconnect and connection-point queries. `connect` replaces the existing edge for `(destination, inputBus)`. Hardware `start()` throws and leaves `isRunning` false. Manual rendering (`enableManualRenderingMode` + `start` + `renderOffline`) mixes scheduled PCM offline.
- **Session preferences.** `setCategory` stores category/mode/options. Activation, port override, and hardware configuration **throw**. Record permission is delivered **asynchronously**, exactly once, on `AVFAudio.callback`.
- **Player / recorder / converter / sequencer.** `AVAudioPlayer` throwing URL initializers use throwing I/O. Empty or garbage payloads throw; only a narrowly validated 16-bit linear PCM WAVE construct. Play, record, convert, and sequencer start stay fail-closed.
- **Speech.** Utterance text is stored. `speak` does not set `isSpeaking`. Personal-voice authorization is `.unsupported`, delivered asynchronously on the callback queue.

## Fail-closed boundaries

| Surface | Linux behavior |
| --- | --- |
| Hardware playback / capture | `play()` / `record()` return false |
| Hardware engine I/O | `start()` without manual mode throws; `isRunning` stays false |
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

The mixed probe is executable rather than documentary. It requires canonical
CoreAudioTypes, AudioToolbox, CoreMIDI, and CoreMedia modules and headers; a
missing dependency is a hard failure. It builds `AVFAudioDependencyABI.c`, links the C
object into the Swift probe, compares the C and Swift sizes, alignments, and
`AudioBufferList` field offsets, walks a four-buffer flexible list, and verifies
the loaded AVFAudio image:

```sh
bash tests/agent/test_avfaudio_dependency_abi.sh canonical
```

Additional dependency search, library, or header arguments can be supplied as
repeated `--swift-arg ARG` and `--clang-arg ARG` pairs. The current repository
boundary can be checked separately with `repository` mode. That mode refuses
until all four dependency-owned modules exist and provide the canonical
declarations. It rejects unclassified compiler errors instead of allowing a
known dependency diagnostic to mask an AVFAudio-local failure, and it never
substitutes AVFAudio-local lookalikes.

Run the immutable host gate:

```sh
bash tests/acceptance/test_host.sh
```

## Depth pass 2026-09

Campaign `ios26.1-fwdepth-r3`, framework `AVFAudio`, lane `large-partitioned`. This pass implements the value/state-machine core **without audio hardware**. Coverage: **1558 implemented / 0 declared / 79 deferred / 1 unavailable** of 1638 IDs (gate floor is 150 nondeferred). Families `AVAudioFormat`, `AVAudioPCMBuffer`, `AVAudioTime`, `AVAudioFile`, `AVAudioEngine` (manual rendering), and `AVAudioConverter` are nondeferred except C-ABI `canImport` APIs (`AudioStreamBasicDescription`, `AudioBufferList`, `AudioTimeStamp`, `AVAudioSourceNode`/`SinkNode`, `manualRenderingBlock`, MIDI event-list connect, `AUAudioUnit` wrappers).

### Public surface (Linux-backed)

- **AVAudioFormat.** `init(standardFormatWithSampleRate:channels:)`, `init(commonFormat:sampleRate:channels:interleaved:)`, `init(settings:)`. Settings keys: `AVFormatIDKey` (`1819304813` / `'lpcm'`), `AVSampleRateKey`, `AVNumberOfChannelsKey`, `AVLinearPCMBitDepthKey`, `AVLinearPCMIsBigEndianKey` (`false`), `AVLinearPCMIsFloatKey`, `AVLinearPCMIsNonInterleaved`, optional `AVChannelLayoutKey`. `isStandard` is non-interleaved float32. `init(streamDescription:)` remains `canImport(CoreAudioTypes)`.
- **AVAudioPCMBuffer.** `frameCapacity`/`frameLength`, planar and interleaved `floatChannelData`/`int16ChannelData`/`int32ChannelData` (interleaved channel `n` is offset by `n * bytesPerSample`, matching Apple), `stride`. Copy retains Apple's first-`AudioBuffer` **byte** `frameCapacity` quirk.
- **AVAudioTime.** Host/sample validity, `extrapolateTime(fromAnchor:)`, `hostTime(forSeconds:)` / `seconds(forHostTime:)` via `clock_gettime(CLOCK_MONOTONIC)` nanoseconds (`1e9` ticks/s). Mach-absolute-time numer/denom is not claimed.
- **AVAudioFile.** WAV (RIFF PCM 16/32 and IEEE float) read/write; CAF PCM (`desc` 36-byte little-endian, `lpcm`, channels at +28, bits at +32) read/write; AIFF PCM **read** (IEEE80 sample rate). `length` / `framePosition` / `fileFormat` / `processingFormat`. `framePosition` clamps to `length`; writers update `length` before `framePosition`.
- **AVAudioEngine graph.** Attach/connect/disconnect/start/stop/reset. Hardware `start()` stays fail-closed. `enableManualRenderingMode` succeeds; `start()` in manual mode sets `isRunning`; `renderOffline` walks player → EQ `globalGain` → mixer, mixes scheduled PCM, applies mixer `outputVolume`, posts `.AVAudioEngineConfigurationChange`. `disableManualRenderingMode` is nonthrowing and stops the engine (Apple's method does not throw).
- **AVAudioConverter.** PCM int/float, channel map, stereo downmix, linear sample-rate interpolation (documented gap vs Apple's resampler). Compressed formats throw.
- **AVAudioMixerNode / AVAudioPlayerNode / AVAudioUnitEQ.** Software mix/gain/pan on PCM in manual rendering. Constant-gain pan: `pan == 0` leaves both channels at 1.0; `pan == -1` left=1 right=0.

### Fail-closed boundaries

| Surface | Linux behavior |
| --- | --- |
| Hardware engine I/O | `start()` without manual mode throws `AVAudioEngineManualRenderingError.hostUnavailable`; `isRunning` stays false |
| Compressed converters / files | `AVAudioConverter` and `AVAudioFile` throw `AVFAudioError.hostUnavailable` |
| `AVAudioUnitSampler` | `loadSoundBankInstrument` / `loadAudioFiles` throw; `startNote` is a no-op |
| `AVSpeechSynthesizer` | Empty voice catalog; `speak` does not set `isSpeaking` |
| `AVAudioSession` activation / hardware | `setActive` and preferred hardware APIs throw (session types remain in this module; not duplicated into AVFoundation) |
| `AVAudioEngine.manualRenderingBlock` | Compiled only with CoreAudioTypes |
| ASBD / AudioBufferList / AudioTimeStamp | Compiled only with CoreAudioTypes; isolated host does not claim the round trip |

### Tests and markers

`bash full/avfaudio/tests/acceptance/test_host.sh` (Linux host, no docker). Agent runtime covers format/settings, PCM layout, time extrapolation, WAV/CAF/AIFF, converter PCM/SRC/channelMap, mixer pan/gain, engine manual render mix, speech/sampler fail-closed, and a depth catalog of ≥900 symbols.

Actual sealed host gate (`bash full/avfaudio/tests/acceptance/test_host.sh`, 2026-09-05, Swift 6.2.4 `x86_64-unknown-linux-gnu`):

```
FRAMEWORK_FANOUT_REFERENCE_OK
AVFAUDIO_AGENT_RUNTIME_OK
FRAMEWORK_FANOUT_HOST_OK module=AVFAudio dylib=libAVFAudio.dylib
```

Campaign also asked for `CURSOR_SWIFT_ENVIRONMENT_OK swift=6.2.4 target=linux products=clean`. That line is printed by `.cursor/verify-cloud-environment.sh`, not the sealed gate. This snapshot fails attestation (`missing corpus checkout: scratch/ladder-corpus/focus-ios`; Cursor Build `bld-20260905-9aa65d65-b87d-46a7-b154-e2f1440dbba3` vs seed `bld-20260901-d3266600-d87b-438f-94c1-d1aa48036e87`). Swift 6.2.4 linux is present. The sealed gate was not weakened.

### Unresolved behavioral questions (central review)

See `oracle-questions.tsv`: linear SRC vs Apple resampler; CAF `desc` 36 vs 32; constant-gain pan vs constant-power; sampler `loadSoundBankInstrument` host-unavailable vs empty bank; ASBD round-trip only when CoreAudioTypes is imported; AVAudioSession ownership vs AVFoundation.
