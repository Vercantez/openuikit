# AudioToolbox Linux starting point

This is a clean-room canonical core for OpenUIKit's Linux `AudioToolbox` overlay. It exists to unlock later `AVFAudio` work by owning Audio Toolbox types and fail-closed C entry points, not by recreating the deleted portable stand-in (`AudioToolboxPortable`, local `AudioStreamBasicDescription` / `AudioBuffer`, or `kAudioServicesUnsupportedPropertyError = -1501`).

## What is real

- `AudioComponentDescription` is a 20-byte record of five `UInt32` fields (C ABI of Darwin `OSType` without redeclaring `OSType`).
- Component discovery is empty; instantiate/register/validate fail closed.
- `AUAudioUnit` construction throws `NSOSStatusErrorDomain` / `kAudioUnitErr_ComponentManagerNotSupported`.
- In-process `MusicSequence` / `MusicTrack` / `MusicEventIterator` / `MusicPlayer` state: track ownership, ordered iteration, seek/delete, concurrent track creation, malformed MIDI load rejection. `MusicPlayerStart` never reaches hardware.
- `AudioFileOpenURL` / `ExtAudioFileOpenURL` distinguish missing, malformed, and unsupported-codec inputs. Close/dispose of unknown refs is crash-safe.
- `AudioQueue` objects exist in-process and own buffers (zero/one/many, overflow, alias enqueue, concurrent allocate, dispose idempotence). `AudioQueueStart` returns `kAudioQueueErr_InvalidDevice`.
- System sounds never play and never invoke completion procs. `kAudioServicesUnsupportedPropertyError` is FourCC `'pty?'` (`0x7074793F`).
- Isolated returns use `Int32` for C `OSStatus`. This module does not alias or redeclare `OSStatus`, `OSType`, `AudioStreamBasicDescription`, `AudioBuffer`, `AudioBufferList`, `AudioTimeStamp`, `AudioChannelLayout`, CF objects, `NSObject`, `URL`, `Data`, or `NSError`.

## C-callable versus Swift-only

C-callable exports are the `@_cdecl` entry points. Swift overlays that take Swift structs, enums, OptionSets, `Bool`, or trailing closures are not C ABI by name alone. Linux ELF hides `internal` `@_cdecl` thunks, so typed-pointer mismatches use public `atCdecl_*` Swift names that export the Apple C symbol; those Swift names are not graph identifiers. Independent C fixtures under `tests/agent/audiotoolbox_c_probes.c` reconstruct `AudioComponentDescription`, `MIDINoteMessage`, flexible `AudioBufferList` traversal (0/1/many/overflow), and `AudioQueueBuffer`, then `dlsym` only symbols the dylib actually exports.

## Canonical identities

Product code imports Foundation always, CoreFoundation when the module exists, and CoreAudioTypes only behind `canImport`. Isolated Linux has Foundation and CoreFoundation and lacks CoreAudioTypes; ASBD-taking APIs (`AudioConverterNew`, `AudioFileCreateWithURL`, graph-accurate `AudioQueueNewOutput`) are omitted rather than given a local type of the same name. `tests/agent/AudioToolboxDependencyIdentity.swift` unconditionally imports `AudioToolbox`, `CoreAudioTypes`, `CoreFoundation`, and `Foundation` and is ready to pass genuine values through public APIs on the central ARM64 build.

## Fail-closed boundaries

Hardware I/O, codecs, Audio Unit plug-ins, system-sound servers, and unsupported plugins do not succeed. Playback APIs are not success. Unknown/garbage refs and double-dispose do not crash.

## Deferred

AUGraph hosting, v3 AU rendering, AudioCodec, MusicDevice I/O, CAF/AAC encode/decode, CoreAudioTypes-typed converters/queues, and synthesized Equatable/Hashable members without product anchors remain deferred or unavailable until a central Apple-oracle / ARM64 integration build observes them.
