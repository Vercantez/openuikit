# AudioUnit (Linux starting point)

This is an honest Linux starting point for Apple's `AudioUnit` compatibility
module, seeded from the iPhoneOS 26.1 Swift graph. It is not Apple behavioral
parity and it is not a plug-in host.

## What is real

- Public `AUDIO_UNIT_VERSION: Int32 { get }` (precise ID
  `c:@macro@AUDIO_UNIT_VERSION`). The getter returns `1070`, the publicly
  observed modern Audio Component-era header value. Clients that branch on
  `AUDIO_UNIT_VERSION < 1060` therefore take the Audio Component path.
- Loadable `libAudioUnit.dylib` / Swift module `AudioUnit`.
- When `AudioToolbox`, `CoreAudio`, or `CoreAudioTypes` are already built and
  importable, this module `@_exported` imports them (Linux stand-in for the
  iOS umbrella-header re-export). The isolated host gate compiles this module
  alone, so those imports stay omitted there.

## Fail-closed boundaries

Linux does **not** instantiate Apple Audio Units, register plug-ins, or run a
Core Audio realtime render timeline. `@_spi(AudioUnitLinux)` host hooks report
that plug-in hosting, realtime render, and Apple system units are unavailable
and throw if a caller tries to require them.

Do not treat a green isolated gate as evidence that HighPass, DynamicsProcessor,
PeakLimiter, or AUiPodTimeOther effects work.

## What is deferred / owned elsewhere

The roadmap corpus (`pocket-casts-ios` `podcasts/EffectsPlayer.swift`) imports
`AudioUnit` and then uses C APIs:

- `AudioUnit` instance type, `AudioUnitSetParameter`, `AudioUnitParameterID`
- `kAudioUnitScope_Global`
- `AudioComponentDescription`
- `kAudioUnitType_FormatConverter`, `kAudioUnitType_Effect`
- `kAudioUnitSubType_AUiPodTimeOther`, `kAudioUnitSubType_HighPassFilter`,
  `kAudioUnitSubType_DynamicsProcessor`, `kAudioUnitSubType_PeakLimiter`
- `kAudioUnitManufacturer_Apple`

Those identifiers are owned by AudioToolbox (with types from CoreAudio /
CoreAudioTypes). This module does not declare lookalikes. They become usable
here only after those dependencies are ported and on the import path.

`Foundation` is a declared integration dependency; the unique pinned symbol
does not require it.

## Tests

`tests/agent/AudioUnitRuntime.swift` exercises the version getter and the
fail-closed Linux host SPI, then prints `AUDIOUNIT_AGENT_RUNTIME_OK`.
