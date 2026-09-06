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

Hardware I/O, compressed codecs, RemoteIO/VoiceProcessingIO render, Audio Unit plug-ins, MIDI CI, and system-sound servers do not succeed. Unknown/garbage refs and double-dispose do not crash. AUGraph RemoteIO nodes return `kAUGraphErr_OutputNodeErr`. `AUAudioUnit.startHardware()` throws. AudioFileStream SetProperty is unsupported. AudioCodec objects and MusicDevice MIDI on non-music-device units fail closed.

## Deferred

AUGraph unnamed-union overlay, v3 AU realtime render blocks, MusicDeviceMIDIEventList (`MIDIEventList`), compressed CAF/AAC encode/decode, CoreAudioTypes-typed realtime-safe converters, and synthesized Equatable/Hashable members without product anchors remain deferred or unavailable until a central Apple-oracle / ARM64 integration build observes them.

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

## Depth pass 2026-09 (wave 9)

Third SDK-depth pass on the wave-8 tree (keep existing tests green; do not rewrite). HEAD at start was `bff8535c68425cc39fb45cb00d447b0981b57242`. `.cursor/verify-cloud-environment.sh` still fails because `scratch/ladder-corpus/focus-ios` is absent; `swiftc` is Swift 6.2.4 targeting `x86_64-unknown-linux-gnu`. Active Cursor Build on this pod is `bld-20260906-253cd433-7a30-4d11-aad2-8b209b7b2d21` (seed expected `bld-20260901-d3266600-d87b-438f-94c1-d1aa48036e87`). The sealed gate is the authority for `FRAMEWORK_FANOUT_HOST_OK`.

### Coverage before / after

| status | after wave 8 | after wave 9 |
| --- | ---: | ---: |
| implemented | 873 | 1371 |
| declared | 277 | 158 |
| deferred | 1765 | 1704 |
| unavailable | 319 | 1 |
| not-applicable | 0 | 0 |

No SwiftUI cross-import overlay IDs (`s:7SwiftUI4View…`) appear in this census. Remaining `unavailable` is `AUMIDICIProfileChangedBlock` (MIDI CI / Apple-service). Codec, CAF, MusicDevice, and AudioFileStream packet-table IDs that are not hardware/daemon-bound were reclassified to `implemented` or `deferred`.

### Top-5 implemented evidence distribution (after)

1. `testAudioToolboxConstantCatalog` — 146 rows (10.6%) — table-driven k…/err… payloads
2. `testAudioCodecConstantsAndFailClosed` — 138 (10.1%) — table-driven AudioCodec FourCC/quality/error IDs plus fail-closed codec entry points
3. `testCAFRemainingStructFields` — 107 (7.8%) — CAF chunk/marker/region/instrument field overlays
4. `testAudioUnitPropertyAndScopeIDsExact` — 95 (6.9%) — table-driven AU property/scope IDs
5. `testAudioUnitPropertyInfoAndParameterOptions` — 73 (5.3%) — table-driven parameter-unit/option-set/render-action flags

No non-table test exceeds 40% of implemented rows (`testMixerVolumeAffectsMix` is 4.0%).

### Public surface added this pass

- **Mixer parameters.** Per-element volume/enable/pan on MultiChannelMixer; render-callback PCM is scaled by input-element volume. Matrix mixer meter IDs, 3D mixer parameter IDs, HAL output volume, TimePitch/NewTimePitch/Varispeed, and AUGroup MIDI CC parameter IDs are exact constants. `AudioUnitGetPropertyInfo` reports the mixer parameter list; `AudioUnitAddRenderNotify` / `RemoveRenderNotify` store observers.
- **AudioQueue.** `GetParameter` / `SetParameter` for volume, pan, play rate, pitch, and ramp time; `Prime`; `GetCurrentTime` sample-time overlay. Processing taps and timelines fail closed (`TooManyTaps` / `InvalidTapContext` / `InvalidParameter`).
- **AudioFile.** `Optimize`, `ReadPacketData`, `SetProperty(DeferSizeUpdates)`, and `GetGlobalInfo` / `GetGlobalInfoSize` for WAVE/AIFF/CAF readable/writable types plus Linear PCM format IDs.
- **MusicSequence.** Beats↔seconds, bar/beat time, track index, CopyInsert/Cut/Merge/MoveEvents, mute/solo/offset/length/resolution, `SetEventTime`, SMF `FileCreate` / `FileCreateData`, AUGraph attach, `MusicPlayerPreroll`.
- **AudioCodec / MusicDevice.** Exact codec property/error/quality/select constants. Codec initialize/produce/append APIs fail closed. `MusicDeviceMIDIEvent` / `SysEx` / `StartNote` / `StopNote` fail closed on software units. `MusicDeviceMIDIEventList` stays deferred (`MIDIEventList` is CoreMIDI-owned).
- **CAF helpers.** Remaining chunk/marker/region/instrument/peak/overview/UMID/UUID field overlays and memberwise/empty inits. Packet-table flexible `mPacketDescriptions` tail is not overlaid.

### Fail-closed boundaries (wave 9)

- No hardware I/O, system-sound server, RemoteIO / VoiceProcessingIO render, processing taps, or AudioQueue timelines.
- Compressed codec objects never initialize; MusicDevice MIDI on non-music-device units returns `kAudioUnitErr_CannotDoInCurrentContext`.
- MIDI CI (`AUMIDICIProfileChangedBlock`) remains unavailable.
- `AudioStreamBasicDescription` / `AudioBufferList` names stay in CoreAudioTypes. Isolated calls take 40-byte ASBD blobs and buffer-list overlays.
- Unknown refs and double-dispose stay crash-safe.

### Tests and gate

- Agent tests: `AudioToolboxCoreTests.swift`, `AudioToolboxDepthTests.swift`, `AudioToolboxWave2Tests.swift`, `AudioToolboxWave3Tests.swift`.
- Sealed host gate: `bash full/audiotoolbox/tests/acceptance/test_host.sh`. Exact marker output from the green wave-9 run:

```
FRAMEWORK_FANOUT_DELIVERABLE_OK module=AudioToolbox lane=large-partitioned symbols=3234
FRAMEWORK_FANOUT_REFERENCE_OK
AUDIOTOOLBOX_AGENT_RUNTIME_OK
FRAMEWORK_FANOUT_HOST_OK module=AudioToolbox dylib=libAudioToolbox.dylib
```

Swift `6.2.4` / `x86_64-unknown-linux-gnu` compiled `libAudioToolbox.dylib`. `.cursor/verify-cloud-environment.sh` still cannot print `CURSOR_SWIFT_ENVIRONMENT_OK swift=6.2.4 target=linux products=clean` because `scratch/ladder-corpus/focus-ios` is missing on this snapshot.

### Unresolved behavioral questions

See `oracle-questions.tsv`. New items this pass: mixer volume versus `SetRenderCallback`, AudioCodec null `OSStatus`, MusicDevice MIDI on non-music-device units, processing-tap/timeline fail-closed codes, and CAF packet-table flexible-array layout.

## Depth pass 2026-09 (wave 10)

Fourth SDK-depth pass on the wave-9 tree (keep existing tests green; do not rewrite). HEAD at start was `2de7152a12f3beb34a4c1e92dc0e849af9a1d88b`. `.cursor/verify-cloud-environment.sh` still fails because `scratch/ladder-corpus/focus-ios` is absent; `swiftc` is Swift 6.2.4 targeting `x86_64-unknown-linux-gnu`. The sealed gate is the authority for `FRAMEWORK_FANOUT_HOST_OK`.

### Coverage before / after

| status | after wave 9 | after wave 10 |
| --- | ---: | ---: |
| implemented | 1371 | 2619 |
| declared | 158 | 90 |
| deferred | 1704 | 524 |
| unavailable | 1 | 1 |
| not-applicable | 0 | 0 |

No SwiftUI cross-import overlay IDs (`s:7SwiftUI4View…`) appear in this census. Remaining `unavailable` is `AUMIDICIProfileChangedBlock` (MIDI CI / Apple-service).

### Top-5 implemented evidence distribution (after)

1. `testEnumHashableInequalityCatalog` — 200 rows (7.6%) — table-driven enum `!=` / `hash(into:)` / `init(rawValue:)`
2. `testOptionSetAlgebraAudioUnitAndQueue` — 200 (7.6%) — table-driven OptionSet algebra
3. `testOptionSetAlgebraNewMixerFlags` — 168 (6.4%) — mixer/transport/slice flags
4. `testOptionSetAlgebraAudioFileFamily` — 163 (6.2%) — AudioFile/CAF OptionSet algebra
5. `testAudioToolboxConstantCatalog` — 146 (5.6%) — table-driven k…/err… payloads

No non-table test exceeds 40% of implemented rows.

### Public surface added this pass

- **OptionSet / enum overlays.** Remaining mixer/spatial/host-transport/slice/settings flags plus corroborated enum cases; synthesized SetAlgebra/Hashable/`init(rawValue:)` members are exercised by table tests.
- **Parameter/property IDs.** Sampler, EQ/filter/dynamics/delay/reverb2/random/round-trip AAC, VoiceIO, AudioMix, hardware-codec policy, converter prime method, render-quality, instrument-type, and preset/settings/configuration string keys.
- **Overlay structs.** `AUChannelInfo`, `AudioUnitParameter`, `AUPreset`, `MIDIMetaEvent`/`MIDIRawData`/`ParameterEvent`, CAF-adjacent `AudioFileMarker`/`AudioFile_SMPTE_Time`, sampler instrument/bank records, `AUParameterAutomationEvent`.
- **AUParameter tree.** Factory `createParameter`/`createGroup`/`createTree`, observer tokens, `setValue`, string conversion callbacks.
- **Runtime.** In-memory AudioFile user-data chunks; `MusicSequenceReverse` plus meta/raw/parameter events and `SetEventInfo`; `AudioUnitProcess` delegates to Render; property listeners fire on `SetProperty`; converter `Prepare`; hardware I/O helpers stay fail-closed (`AudioOutputUnitPublish`, queue device time, MusicDevice MIDI list).

### Fail-closed boundaries (wave 10)

- No hardware I/O, system-sound server, RemoteIO / VoiceProcessingIO render, processing taps, or AudioQueue device clocks.
- MIDI CI remains unavailable. Compressed codec objects never initialize.
- Inter-app Audio Unit publish/icon APIs return `kAudioComponentErr_NotPermitted`.
- `AudioStreamBasicDescription` / `AudioBufferList` names stay in CoreAudioTypes.

### Tests and gate

- Agent tests: `AudioToolboxCoreTests.swift`, `AudioToolboxDepthTests.swift`, `AudioToolboxWave2Tests.swift`, `AudioToolboxWave3Tests.swift`, `AudioToolboxWave4Tests.swift`, `AudioToolboxWave5Tests.swift`.
- Only host script under `tests/`: `bash full/audiotoolbox/tests/acceptance/test_host.sh` (exit 0). Exact sealed-gate stdout:

```
FRAMEWORK_FANOUT_DELIVERABLE_OK module=AudioToolbox lane=large-partitioned symbols=3234
FRAMEWORK_FANOUT_REFERENCE_OK
AUDIOTOOLBOX_AGENT_RUNTIME_OK
FRAMEWORK_FANOUT_HOST_OK module=AudioToolbox dylib=libAudioToolbox.dylib
```

- `swift --version` is `Swift 6.2.4` targeting `x86_64-unknown-linux-gnu`. `.cursor/verify-cloud-environment.sh` still fails (`scratch/ladder-corpus/focus-ios` missing) and therefore does not print `CURSOR_SWIFT_ENVIRONMENT_OK swift=6.2.4 target=linux products=clean`. The sealed gate is the authority for this pass.

### Unresolved behavioral questions

See `oracle-questions.tsv`. New items this pass: 3D mixer HeadYaw/decibel aliases, `AUParameterAutomationEvent` reserved/hostTime layout, and `AudioUnitProcess` versus `AudioUnitRender` pull semantics.

## Depth pass 2026-09 (wave 11)

Fifth SDK-depth pass on the wave-10 tree (keep existing tests green; do not rewrite). HEAD at start was `39dc25a2769fb88a50f0853964137a4f96d50322`. `.cursor/verify-cloud-environment.sh` still fails because `scratch/ladder-corpus/focus-ios` is absent; `swiftc` is Swift 6.2.4 targeting `x86_64-unknown-linux-gnu`. Active Cursor Build on this pod is `bld-20260906-253cd433-7a30-4d11-aad2-8b209b7b2d21` (seed expected `bld-20260901-d3266600-d87b-438f-94c1-d1aa48036e87`). The sealed gate is the authority for `FRAMEWORK_FANOUT_HOST_OK`.

### Coverage before / after

| status | after wave 10 | after wave 11 |
| --- | ---: | ---: |
| implemented | 2619 | 2927 |
| declared | 90 | 44 |
| deferred | 524 | 262 |
| unavailable | 1 | 1 |
| not-applicable | 0 | 0 |

No SwiftUI cross-import overlay IDs (`s:7SwiftUI4View…`) appear in this census. Remaining `unavailable` is `AUMIDICIProfileChangedBlock` (MIDI CI daemon / CoreMIDI).

### Top-5 implemented evidence distribution (after)

1. `testEnumHashableInequalityCatalog` — 200 rows (6.8%) — table-driven enum `!=` / `hash(into:)` / `init(rawValue:)`
2. `testOptionSetAlgebraAudioUnitAndQueue` — 200 (6.8%) — table-driven OptionSet algebra
3. `testOptionSetAlgebraNewMixerFlags` — 168 (5.7%) — mixer/transport/slice flags
4. `testOptionSetAlgebraAudioFileFamily` — 163 (5.6%) — AudioFile/CAF OptionSet algebra
5. `testAudioToolboxConstantCatalog` — 146 (5.0%) — table-driven k…/err… payloads

No non-table test exceeds 40% of implemented rows. Wave-11 family tests each cite only the identifiers they exercise.

### Public surface added this pass

- **Parameter ID aliases.** `k3DMixerParam_BusEnable` / `*InDecibels` aliases of Enable/gain/reverb/occlusion; `kNewTimePitchParam_Smoothness` / `EnableSpectralCoherence` aliases plus `EnableTransientPreservation=7`; dynamic-range / program-target / sound-isolation constants.
- **Overlays.** `AudioUnitParameterInfo` (52-byte name), `ScheduledAudioSlice` / `ScheduledAudioFileRegion`, `AUMIDIEvent` / `AUParameterEvent` / `AURenderEventHeader` / `AURenderEvent`, `AudioFileRegion` + `NextAudioFileRegion`, `AudioPanningInfo`, flattened `AudioUnitParameterEvent`, `HostCallbackInfo`, packet translations, queue meter/assignment/parameter events, node connections, ducking/start-at-time/MIDI callback structs, `ExtendedNoteOnEvent`.
- **Runtime.** `AudioUnitScheduleParameters` applies immediate values and ramp end-values onto mixer parameters; `AudioQueueEnqueueBufferWithParameters` stores start/end trim and optional volume events; `AudioQueueOfflineRender` copies trimmed PCM sample-exactly (silence when the queue is empty). `AudioComponentCopyName` returns the built-in software-unit name (`MultiChannelMixer`, `GenericOutput`, `ScheduledSoundPlayer`, `RemoteIO`); `AudioComponentRegister` / `Validate` stay fail-closed and do not publish plugins. Sound-bank name/instrument copy returns `kAudioFileUnsupportedFileTypeError`.
- **AUAudioUnit v3.** `AUAudioUnitStatus`, `registerSubclass` (stored, does not publish plugins), `presetState(for:)` fail-closed, `AUAudioUnitV2Bridge` wrapping a v2 software instance. RemoteIO still fail-closes. MIDI CI / `MIDIEventList` / `AVAudioFormat` remain deferred or unavailable.

### Fail-closed boundaries (wave 11)

- No hardware I/O, system-sound server, RemoteIO / VoiceProcessingIO render, processing taps, or AudioQueue device clocks.
- MIDI CI remains unavailable. Compressed codec objects never initialize.
- `registerSubclass` does not add components to `AudioComponentFindNext`.
- `AudioStreamBasicDescription` / `AudioBufferList` / `AudioTimeStamp` / `AudioChannelLayout` names stay in CoreAudioTypes. Isolated calls take 40-byte ASBD blobs, buffer-list overlays, and 64-byte timestamp slots.
- Unknown refs and double-dispose stay crash-safe.

### Tests and gate

- Agent tests: previous waves plus `AudioToolboxWave6Tests.swift`.
- Only host script under `tests/`: `bash full/audiotoolbox/tests/acceptance/test_host.sh`. Exact sealed-gate stdout:

```
FRAMEWORK_FANOUT_DELIVERABLE_OK module=AudioToolbox lane=large-partitioned symbols=3234
FRAMEWORK_FANOUT_REFERENCE_OK
AUDIOTOOLBOX_AGENT_RUNTIME_OK
FRAMEWORK_FANOUT_HOST_OK module=AudioToolbox dylib=libAudioToolbox.dylib
```

Swift `6.2.4` / `x86_64-unknown-linux-gnu` compiled `libAudioToolbox.dylib`. `.cursor/verify-cloud-environment.sh` still fails (`scratch/ladder-corpus/focus-ios` missing) and therefore does not print `CURSOR_SWIFT_ENVIRONMENT_OK swift=6.2.4 target=linux products=clean`. The sealed gate is the authority for this pass.

### Unresolved behavioral questions

See `oracle-questions.tsv`. New items this pass: 3D-mixer BusEnable alias versus bindgen IDs 20–26, DRC GeneralCompression 6 versus sequential 4, `AudioUnitParameterEvent` unnamed-union layout, `ScheduledAudioSlice` timestamp packing, and `AURenderEvent` C-union size with `MIDIEventList`.


