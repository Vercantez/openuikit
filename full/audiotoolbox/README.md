# AudioToolbox Linux starting point

This is a clean-room canonical core for OpenUIKit's Linux `AudioToolbox` overlay. It exists to unlock later `AVFAudio` work by owning Audio Toolbox types and fail-closed C entry points, not by recreating the deleted portable stand-in (`AudioToolboxPortable`, local `AudioStreamBasicDescription` / `AudioBuffer`, or `kAudioServicesUnsupportedPropertyError = -1501`).

## What is real

- `AudioComponentDescription` is a 20-byte record of five `UInt32` fields (C ABI of Darwin `OSType` without redeclaring `OSType`).
- Built-in component discovery returns GenericOutput, MultiChannelMixer, and RemoteIO. `AudioComponentInstantiate` still fail-closes (no v3 plugin host). `AUAudioUnit` construction throws `NSOSStatusErrorDomain` / `kAudioUnitErr_ComponentManagerNotSupported`.
- In-process `MusicSequence` / `MusicTrack` / `MusicEventIterator` / `MusicPlayer` state: track ownership, ordered iteration, seek/delete, concurrent track creation, SMF parse, malformed MIDI load rejection. `MusicPlayerStart` advances an offline clock and never reaches hardware.
- `AudioFile` / `ExtAudioFile` host honest WAV / AIFF / CAF PCM containers. Missing, malformed, and unsupported-codec inputs fail closed. Close/dispose of unknown refs is crash-safe.
- `AudioQueue` objects exist in-process, own buffers, and pump an offline clock that invokes output callbacks without a device. Compressed formats return `kAudioQueueErr_CodecNotFound`.
- System sounds never play hardware. Completions **are** delivered. `kSystemSoundID_Vibrate` is 4095. `kAudioServicesUnsupportedPropertyError` is FourCC `'pty?'` (`0x7074793F`).
- Isolated returns use `Int32` for C `OSStatus`. This module does not alias or redeclare `OSStatus`, `OSType`, `AudioStreamBasicDescription`, `AudioBuffer`, `AudioBufferList`, `AudioTimeStamp`, `AudioChannelLayout`, CF objects, `NSObject`, `URL`, `Data`, or `NSError`.

## C-callable versus Swift-only

C-callable exports are the `@_cdecl` entry points. Swift overlays that take Swift structs, enums, OptionSets, `Bool`, or trailing closures are not C ABI by name alone. Linux ELF hides `internal` `@_cdecl` thunks, so typed-pointer mismatches use public `atCdecl_*` Swift names that export the Apple C symbol; those Swift names are not graph identifiers. Independent C fixtures under `tests/agent/audiotoolbox_c_probes.c` reconstruct `AudioComponentDescription`, `MIDINoteMessage`, flexible `AudioBufferList` traversal (0/1/many/overflow), and `AudioQueueBuffer`, then `dlsym` only symbols the dylib actually exports.

## Canonical identities

Product code imports Foundation always, CoreFoundation when the module exists, and CoreAudioTypes only behind `canImport`. Isolated Linux has Foundation and CoreFoundation and lacks CoreAudioTypes. ASBD-taking APIs accept a 40-byte C overlay rather than redeclaring `AudioStreamBasicDescription`. `tests/agent/AudioToolboxDependencyIdentity.swift` unconditionally imports `AudioToolbox`, `CoreAudioTypes`, `CoreFoundation`, and `Foundation` and is ready to pass genuine values through public APIs on the central ARM64 build.

## Fail-closed boundaries

Hardware I/O, compressed codecs, RemoteIO/VoiceProcessingIO render, Audio Unit plug-ins, system-sound servers, AUGraph, MusicDevice, and AudioFileStream do not succeed. Unknown/garbage refs and double-dispose do not crash.

## Deferred

AUGraph hosting, v3 AU rendering, AudioCodec, MusicDevice I/O, compressed CAF/AAC encode/decode, CoreAudioTypes-typed complex converters, and synthesized Equatable/Hashable members without product anchors remain deferred or unavailable until a central Apple-oracle / ARM64 integration build observes them.

## Depth pass 2026-09

SDK depth expansion for `AudioToolbox` (3234 IDs). Isolated Linux now hosts an offline PCM starting point for the AudioServices / AudioQueue / AudioFile / ExtAudioFile / AudioConverter / AudioUnit-generic families.

### Public surface implemented

- **Constants.** Exact FourCC / numeric payloads for `kAudioFileProperty_*`, `kExtAudioFileProperty_*`, `kAudioQueueProperty_*`, `kAudioConverter*`, `kAudioFormatProperty_*`, `kAudioFormat*` error codes, `kAudioUnitType_*` / `kAudioUnitSubType_*` / `kAudioUnitProperty_*` / `kAudioUnitScope_*`, CAF chunk/marker/SMPTE IDs, file-type IDs, and OSStatus families. Deprecated **AudioSession** constants are declared with exact values; no AudioSession I/O functions are hosted.
- **AudioServices.** `AudioServicesPlaySystemSound` / `PlayAlertSound` (and Swift completion variants) are silent no-ops. Completions are delivered. `CreateSystemSoundID` succeeds after a real WAV/AIFF/CAF open; missing files stay unspecified-error.
- **AudioQueue.** `NewOutput` / `NewInput`, allocate/enqueue/start/stop/pause/reset/dispose, and property get/set for the documented `kAudioQueueProperty_*` IDs. An offline clock pumps enqueued PCM buffers and invokes the output callback without hardware.
- **AudioFile.** Honest WAV / AIFF / CAF open, create, close, packet/byte read-write, and `GetProperty` for format, byte/packet counts, duration, bitrate, and related IDs.
- **ExtAudioFile.** Open/create/wrap plus client PCM format conversion on read/write.
- **AudioConverter.** PCM↔PCM sample-size, endianness, interleave, and channel-map conversion. Compressed formats return `kAudioConverterErr_FormatNotSupported`.
- **AudioComponent / AudioUnit.** `FindNext` / `Count` return documented built-ins (GenericOutput, MultiChannelMixer, RemoteIO). `Initialize` / `Render` succeed for GenericOutput (silence) and Mixer (offline PCM mix of empty inputs). RemoteIO initialize/render fail closed.
- **MusicSequence / MusicPlayer.** SMF parse (`MThd`/`MTrk`, VLQ, tempo meta 0x51, note on/off). Offline `MusicPlayerStart` advances time from a tempo map (default 120 BPM).

Coverage after this pass: **729 implemented / 300 declared / 1793 deferred / 412 unavailable**.

### Fail-closed boundaries (depth)

- No hardware I/O, system-sound server, or RemoteIO / VoiceProcessingIO render path.
- Compressed codecs, AudioFileStream, AudioCodec, AUGraph, MusicDevice MIDI I/O, and 3D/spatial mixer runtime remain deferred or unavailable.
- `AudioStreamBasicDescription` / `AudioBufferList` names stay in CoreAudioTypes. Isolated calls take 40-byte ASBD blobs and buffer-list overlays.
- Unknown refs and double-dispose stay crash-safe.

### Tests and gate

- Agent tests: `tests/agent/AudioToolboxCoreTests.swift`, `tests/agent/AudioToolboxDepthTests.swift` (including `testAudioToolboxConstantCatalog`).
- Sealed host gate: `bash full/audiotoolbox/tests/acceptance/test_host.sh` (this Linux environment is the host; no docker).

### Unresolved behavioral questions

See `oracle-questions.tsv`. Remaining Apple-oracle items include completion-queue identity for `AudioComponentInstantiate`, the real iOS OSStatus when `MusicPlayerStart` has no output AU, AURenderBlock realtime aliasing, and whether vibrate (4095) is a no-op or a distinct haptic path.
