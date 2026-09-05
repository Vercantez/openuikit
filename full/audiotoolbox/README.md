# AudioToolbox Linux starting point

This is a clean-room canonical core for OpenUIKit's Linux `AudioToolbox` overlay. It exists to unlock later `AVFAudio` work by owning Audio Toolbox types and fail-closed C entry points, not by recreating the deleted portable stand-in (`AudioToolboxPortable`, local `AudioStreamBasicDescription` / `AudioBuffer`, or `kAudioServicesUnsupportedPropertyError = -1501`).

## What is real

- `AudioComponentDescription` is a 20-byte record of five `UInt32` fields (C ABI of Darwin `OSType` without redeclaring `OSType`).
- Built-in component discovery returns GenericOutput, MultiChannelMixer, ScheduledSoundPlayer, and RemoteIO. `AudioComponentInstantiate` still fail-closes (no v3 plugin host). Empty/`RemoteIO` `AUAudioUnit` construction throws `NSOSStatusErrorDomain` / `kAudioUnitErr_ComponentManagerNotSupported`; software mixer/generator/generic-output units instantiate.
- In-process `MusicSequence` / `MusicTrack` / `MusicEventIterator` / `MusicPlayer` state: track ownership, ordered iteration, seek/delete, concurrent track creation, SMF type 0/1 parse, malformed MIDI load rejection. `MusicPlayerStart` advances an offline clock and never reaches hardware.
- `AudioFile` / `ExtAudioFile` host honest WAV / AIFF / CAF PCM containers. Missing, malformed, and unsupported-codec inputs fail closed. Close/dispose of unknown refs is crash-safe.
- `AudioQueue` objects exist in-process, own buffers, and pump an offline clock that invokes output callbacks without a device. Compressed formats return `kAudioQueueErr_CodecNotFound`.
- System sounds never play hardware. Completions **are** delivered. `kSystemSoundID_Vibrate` is 4095. `kAudioServicesUnsupportedPropertyError` is FourCC `'pty?'` (`0x7074793F`).
- Isolated returns use `Int32` for C `OSStatus`. This module does not alias or redeclare `OSStatus`, `OSType`, `AudioStreamBasicDescription`, `AudioBuffer`, `AudioBufferList`, `AudioTimeStamp`, `AudioChannelLayout`, CF objects, `NSObject`, `URL`, `Data`, or `NSError`.

## C-callable versus Swift-only

C-callable exports are the `@_cdecl` entry points. Swift overlays that take Swift structs, enums, OptionSets, `Bool`, or trailing closures are not C ABI by name alone. Linux ELF hides `internal` `@_cdecl` thunks, so typed-pointer mismatches use public `atCdecl_*` Swift names that export the Apple C symbol; those Swift names are not graph identifiers. Independent C fixtures under `tests/agent/audiotoolbox_c_probes.c` reconstruct `AudioComponentDescription`, `MIDINoteMessage`, flexible `AudioBufferList` traversal (0/1/many/overflow), and `AudioQueueBuffer`, then `dlsym` only symbols the dylib actually exports.

## Canonical identities

Product code imports Foundation always, CoreFoundation when the module exists, and CoreAudioTypes only behind `canImport`. Isolated Linux has Foundation and CoreFoundation and lacks CoreAudioTypes. ASBD-taking APIs accept a 40-byte C overlay rather than redeclaring `AudioStreamBasicDescription`. `tests/agent/AudioToolboxDependencyIdentity.swift` unconditionally imports `AudioToolbox`, `CoreAudioTypes`, `CoreFoundation`, and `Foundation` and is ready to pass genuine values through public APIs on the central ARM64 build.

## Fail-closed boundaries

Hardware I/O, compressed codecs, RemoteIO/VoiceProcessingIO render, Audio Unit plug-ins, and system-sound servers do not succeed. Unknown/garbage refs and double-dispose do not crash. AUGraph RemoteIO nodes return `kAUGraphErr_OutputNodeErr`. `AUAudioUnit.startHardware()` throws. AudioFileStream SetProperty is unsupported.

## Deferred

AUGraph unnamed-union overlay, v3 AU realtime render blocks, AudioCodec, MusicDevice I/O, compressed CAF/AAC encode/decode, CoreAudioTypes-typed realtime-safe converters, and synthesized Equatable/Hashable members without product anchors remain deferred or unavailable until a central Apple-oracle / ARM64 integration build observes them.

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

Coverage after this pass: **730 implemented / 299 declared / 1793 deferred / 412 unavailable**.

### Fail-closed boundaries (depth)

- No hardware I/O, system-sound server, or RemoteIO / VoiceProcessingIO render path.
- Compressed codecs, AudioFileStream packet-table/cookie properties, AudioCodec, MusicDevice MIDI I/O, and 3D/spatial mixer runtime remain deferred or unavailable.
- `AudioStreamBasicDescription` / `AudioBufferList` names stay in CoreAudioTypes. Isolated calls take 40-byte ASBD blobs and buffer-list overlays.
- Unknown refs and double-dispose stay crash-safe.

### Tests and gate

- Agent tests: `tests/agent/AudioToolboxCoreTests.swift`, `tests/agent/AudioToolboxDepthTests.swift` (including `testAudioToolboxConstantCatalog`).
- Sealed host gate: `bash full/audiotoolbox/tests/acceptance/test_host.sh` (this Linux environment is the host; no docker). Exact marker output from the green run:

```
FRAMEWORK_FANOUT_DELIVERABLE_OK module=AudioToolbox lane=large-partitioned symbols=3234
FRAMEWORK_FANOUT_REFERENCE_OK
AUDIOTOOLBOX_AGENT_RUNTIME_OK
FRAMEWORK_FANOUT_HOST_OK module=AudioToolbox dylib=libAudioToolbox.dylib
```

The campaign environment token `CURSOR_SWIFT_ENVIRONMENT_OK swift=6.2.4 target=linux products=clean` is a host-inventory stamp, not printed by the sealed framework gate. Swift 6.2.4 / linux was used to compile `libAudioToolbox.dylib`.

## Depth pass 2026-09 (wave 8)

Second SDK-depth pass on the first-pass tree (keep existing tests green; do not rewrite). `.cursor/verify-cloud-environment.sh` still fails on this snapshot because `scratch/ladder-corpus/focus-ios` is absent; `swiftc` is Swift 6.2.4 targeting `x86_64-unknown-linux-gnu`. The sealed gate is the authority for `FRAMEWORK_FANOUT_HOST_OK`.

### Coverage before / after

| status | first pass | after wave 8 |
| --- | ---: | ---: |
| implemented | 730 | 873 |
| declared | 299 | 277 |
| deferred | 1793 | 1765 |
| unavailable | 412 | 319 |
| not-applicable | 0 | 0 |

No SwiftUI cross-import overlay IDs (`s:7SwiftUI4View…`) appear in this census.

### Top-5 implemented evidence distribution (after)

1. `testAudioToolboxConstantCatalog` — 146 rows (16.7%) — table-driven k…/err… payloads
2. `testAudioUnitPropertyAndScopeIDsExact` — 95 (10.9%) — table-driven AU property/scope IDs
3. `testAudioSessionDeprecatedConstants` — 67 (7.7%) — table-driven AudioSession constants
4. `testAudioComponentBuiltInsAndUnits` — 63 (7.2%)
5. `testAudioConverterPropertyIDsExact` — 57 (6.5%)

No non-table test exceeds 40% of implemented rows (`testAUGraphMixerToOutput` is 4.0%).

### Public surface added this pass

- **AudioConverter.** Linear sample-rate conversion (stated formula, hand-computed `[0, 0.5, 1]` at 1 Hz → 2 Hz), int16/int32/float32 interleaved and non-interleaved, `AudioConverterFillComplexBuffer` callback protocol, `AudioConverterConvertComplexBuffer`.
- **AudioFile / ExtAudioFile.** Channel layout (`kAudioFilePropertyChannelLayout`, 12-byte overlay), estimated duration, packet-size upper bound; WAV/AIFF/CAF PCM read/write stays sample-exact.
- **AudioFileStream.** Incremental WAV/AIFF/CAF PCM parse, property listener, packets proc, GetProperty/GetPropertyInfo/Seek; SetProperty fail-closed.
- **AudioQueue.** Property listeners for `kAudioQueueProperty_IsRunning`; output pump copies rendered PCM so tests can assert sample-exact callback buffers. NewOutput/NewInput/Allocate/Enqueue/Start/Stop/Pause/Flush/Dispose remain hosted.
- **AudioComponent / AudioUnit.** ScheduledSoundPlayer generator catalog + sine render; mixer/output connections; RemoteIO initialize/render still fail-closed.
- **AUGraph.** Nodes, connections, input callbacks, Initialize/Start/Stop, interaction queries, CPU load 0, render-notify inert; RemoteIO nodes return `kAUGraphErr_OutputNodeErr`.
- **AUAudioUnit v3.** Software mixer/generator/generic-output instantiate; `allocateRenderResources` / bus counts / names; `startHardware()` fail-closed. Empty descriptions and RemoteIO still throw `kAudioUnitErr_ComponentManagerNotSupported`.
- **MusicSequence.** SMF type 0 and type 1: every `MTrk` is a user track; tempo meta still lands on the tempo track; event iteration unchanged.
- **CAF helpers.** `CAFFileHeader` (8), packed `CAFChunkHeader` (12), `CAFAudioDescription` (32), `CAF_SMPTE_Time` (8).

### Fail-closed boundaries (wave 8)

- No hardware I/O, system-sound server, or RemoteIO / VoiceProcessingIO render.
- Compressed codecs, AudioCodec, MusicDevice MIDI I/O, 3D/spatial mixer runtime, AU render observers, and AudioFileStream packet-table/cookie/random-access properties stay deferred or unavailable.
- `AudioStreamBasicDescription` / `AudioBufferList` names stay in CoreAudioTypes. Isolated calls take 40-byte ASBD blobs and buffer-list overlays.
- Unknown refs and double-dispose stay crash-safe.

### Tests and gate

- Agent tests: `AudioToolboxCoreTests.swift`, `AudioToolboxDepthTests.swift`, `AudioToolboxWave2Tests.swift`.
- Sealed host gate: `bash full/audiotoolbox/tests/acceptance/test_host.sh`. Exact marker output from the green wave-8 run:

```
FRAMEWORK_FANOUT_DELIVERABLE_OK module=AudioToolbox lane=large-partitioned symbols=3234
FRAMEWORK_FANOUT_REFERENCE_OK
AUDIOTOOLBOX_AGENT_RUNTIME_OK
FRAMEWORK_FANOUT_HOST_OK module=AudioToolbox dylib=libAudioToolbox.dylib
```

Swift `6.2.4` / `x86_64-unknown-linux-gnu` compiled `libAudioToolbox.dylib`. `.cursor/verify-cloud-environment.sh` still cannot print `CURSOR_SWIFT_ENVIRONMENT_OK swift=6.2.4 target=linux products=clean` because `scratch/ladder-corpus/focus-ios` is missing on this snapshot.

### Unresolved behavioral questions

See `oracle-questions.tsv`. New items this pass: Apple SRC phase versus the stated linear formula, `AUGraphIsRunning` DarwinBoolean layout, `AUNodeInteraction` unnamed-union layout, and incremental `AudioFileStreamParseBytes` OSStatus on truncated headers.
