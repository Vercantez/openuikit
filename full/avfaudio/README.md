# AVFAudio Linux starting point

This directory is a **clean-room Linux starting point** for Apple's public `AVFAudio` module, seeded from the Xcode 26.1 iPhoneOS SDK symbol graphs. It is not a claim of Apple behavioral parity.

## What is real

- **Formats and PCM buffers.** `AVAudioFormat` can be built from common format, standard stereo/mono, settings dictionaries, and `AudioStreamBasicDescription` stand-ins. `AVAudioPCMBuffer` allocates zeroed planar or interleaved storage and exposes float/int channel pointers.
- **Engine graph.** `AVAudioEngine` tracks attach/connect/disconnect, can enter offline manual rendering, and mixes scheduled `AVAudioPlayerNode` float buffers into a destination PCM buffer. `start()`/`stop()` flip an in-memory running flag; no Core Audio I/O runs.
- **Session state.** `AVAudioSession.sharedInstance()` stores category, mode, options, sample rate, and mute flags. Record permission is **denied**. Inputs, AirPlay, continuity microphone, and microphone injection are absent.
- **Player / recorder / file / converter.** Objects can be constructed and configured. `AVAudioPlayer.play()` and `AVAudioRecorder.record()` return `false`. File decode/encode and compressed conversion throw `AVAudioError.codecUnavailable`. Same-format float32 conversion copies samples.
- **Speech.** `AVSpeechUtterance` holds text and rate. `AVSpeechSynthesizer.speak` queues the utterance and does **not** set `isSpeaking`. Voice catalogs are empty; personal voice authorization is `.unsupported`.
- **MIDI / units.** Sequencer tracks and MIDI events are in-memory data. `AVAudioUnit.instantiate` throws. Factory AU graphs are parameter holders, not DSP.

## Fail-closed boundaries

| Surface | Linux behavior |
| --- | --- |
| Hardware playback / capture | No DAC/ADC; play/record return false |
| Apple speech voices | Empty catalog; no PCM is synthesized |
| Personal Voice | `.unsupported` |
| Microphone injection / entitlements | Disabled / denied |
| Compressed codecs, AU graphs, MusicSequence | `AVAudioError.notSupported` / `codecUnavailable` |
| Spatial / AirPlay / CarPlay routes | Constants exist; no devices |
| `AVAudioUnitComponent.icon` | Unavailable (UIKit) |

C ABI types (`AudioStreamBasicDescription`, `AudioBufferList`, `AudioTimeStamp`, `AudioComponentDescription`, …) are **portable stand-ins** so signatures compile without linking CoreAudio/AudioToolbox/CoreMIDI/CoreMedia. They are not Apple layout.

## Deferred / later work

True output rendering, tap callbacks on a real-time thread, decoder/encoder containers, AUAudioUnit hosting, and session-daemon interruptions remain for later integration once those dependencies exist in the sysroot.

## Tests

`tests/agent/AVFAudioRuntime.swift` exercises format/buffer/session/engine mix, fail-closed player/recorder/speech, and prints `AVFAUDIO_AGENT_RUNTIME_OK`.

Run the immutable host gate:

```sh
bash tests/acceptance/test_host.sh
```
