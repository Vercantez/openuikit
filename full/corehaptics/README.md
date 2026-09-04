# CoreHaptics (Linux starting point)

This directory is a clean-room Linux starting point for Apple's public
`CoreHaptics` module, seeded from the Xcode 26.1 iPhoneOS 26.1 symbol graph,
API digester, TBD exports, and pinned `dotnet/macios` bindings. It is not
wired into the shared guest package; that integration is a later
central-review step.

The original fail-closed lane (`CHHapticEngine.start` never claims hardware
success, portable pattern player, `supportsHaptics == false`) is kept and
extended to the wave-6 deliverable gate. Nested identity types now match the
graph (`CHHapticEvent.ParameterID`, `CHHapticDynamicParameter.ID`,
`CHHapticPattern.Key`) instead of the original simplified enums.

Unchanged application source continues to import `CoreHaptics`. Linux has no
Taptic Engine or Core Haptics server: constructing an engine succeeds,
playback and registration throw `CHHapticError.notSupported`, and device
capability reports no haptics and no audio.

## What is real

- `CHHapticError` is a `Foundation._BridgedStoredNSError` wrapper. `Code` raw
  values match pinned macios (`engineNotRunning = -4805`, `notSupported =
  -4809`, `memoryError = -4899`, …). `CoreHapticsErrorDomain` uses the C
  identifier as a Linux fallback spelling.
- Event, dynamic-parameter, and pattern-key newtypes are `RawRepresentable`
  strings. Payloads follow Apple's public AHAP schema (`HapticIntensity`,
  `HapticTransient`, `Version`, …), matching the original lane.
- `CHHapticEvent`, `CHHapticEventParameter`, `CHHapticDynamicParameter`,
  `CHHapticParameterCurve` / `ControlPoint`, and `CHHapticPattern` store
  in-process pattern data. Negative event times/durations throw
  `invalidEventTime` / `invalidEventDuration`.
- `CHHapticPattern` parses and exports a portable AHAP-shaped dictionary
  (`init(dictionary:)`, `init(contentsOf:)`, `exportDictionary()`).
- `CHHapticEngine` constructs without hardware. `start()`,
  `registerAudioResource`, `unregisterAudioResource`, and `playPattern`
  throw `notSupported`. Completion / finished handlers run synchronously
  on the caller (portable, not Apple queue evidence).
- `makePlayer` / `makeAdvancedPlayer` return `CHHapticPortablePatternPlayer`
  (kept from the original lane). Start/send/schedule/pause/resume/seek throw
  `notSupported`; `stop` / `cancel` only clear local playing state.
- `capabilitiesForHardware()` reports `supportsHaptics == false` and
  `supportsAudio == false`. Attribute queries throw `notSupported`.
- `StoppedReason` / `FinishedAction` raw values match pinned macios.
- Foundation `TimeInterval`, `URL`, `Data`, `NSError`, and `NSString` values
  pass through public APIs (`tests/agent/CoreHapticsDependencyIdentity.swift`
  is for the later clean EC2 integration build).

## Fail-closed boundaries

- There is no haptic renderer, audio session, or Core Haptics daemon.
- `init(audioSession:)` is omitted: `AVAudioSession` is not a declared
  dependency.
- Parameter min/max/default attributes are not invented.
- `currentTime` is always `0`.
- Audio-resource option key strings use the C identifier; Apple's `NSString`
  payload is unobserved.
- Successful playback, looping, seeking, and resource registration are never
  claimed.

## Still open

See `oracle-questions.tsv`. Hardware streams, Apple completion queues, AHAP
extra-key round trips, and audio-session initialization remain deferred.

`tests/agent/CoreHapticsLoadSmoke.swift` is the canonical schema-v2 marker
probe. Focused checks live in `tests/agent/CoreHapticsTests.swift`.
`tests/agent/CoreHapticsRuntime.swift` records the runtime contract those
tests exercise.

Run `bash tests/acceptance/test_host.sh` from this directory. Keep generated
products out of the tree.
