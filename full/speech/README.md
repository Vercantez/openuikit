# Speech (Linux starting point)

Portable Swift surface for Apple's public `Speech` module, seeded from the
Xcode 26.1 iPhoneOS SDK graphs. This is a **medium-full** lane: the classic
`SFSpeechRecognizer` family plus the iOS 26 `SpeechAnalyzer` /
`SpeechTranscriber` family are present as real types.

## What is real

- Request, result, transcription, error, option, preset, and custom
  language-model *data* types compile and behave deterministically.
- `SFCustomLanguageModelData` records phrase counts, pronunciations, and
  template expansions, and can export a JSON snapshot to a file URL.
- Analyzer modules can be constructed and reconfigured. Locale / format
  queries return empty collections.
- Authorization, availability, and supported-locale queries are answered
  locally without talking to Apple.
- `SFSpeechRecognizer` is an `NSObject` subclass. Recognition result and
  delegate callbacks are delivered on `recognizer.queue` (serial by default).
- Audio and time types (`AVAudioFormat`, `AVAudioPCMBuffer`, `AVAudioFile`,
  `CMSampleBuffer`, `CMTime`, `CMTimeRange`) are imported from AVFoundation
  and CoreMedia so they keep those modules' nominal identity.

## Fail-closed boundaries

These paths never fabricate Apple speech, microphone, privacy-grant, or
asset-download success:

- `SFSpeechRecognizer.isAvailable` is always `false`.
- `authorizationStatus()` / `requestAuthorization` stay at `.denied`.
  Authorization is a class method; its callback is not dispatched on an
  instance `queue` (see `ORACLE.md`).
- `supportedLocales()` / transcriber locale inventories are empty.
- Recognition tasks complete with attested `SFSpeechError.internalServiceError`.
- `SpeechAnalyzer` prepare/start/analyze-sequence methods throw
  `internalServiceError`; file analyze throws attested `audioReadFailed`.
- `AssetInventory` reports `.unsupported`; `reserve(locale:)` throws
  `internalServiceError`; downloads throw `internalServiceError`.
- `SFSpeechLanguageModel.prepareCustomLanguageModel` throws
  `internalServiceError`.

## Isolated staging versus EC2

The immutable isolated host gate does not pass `-I` for AVFoundation or
CoreMedia. From `full/speech/`:

```bash
eval "$(bash tests/agent/stage_isolated_deps.sh)"
export PATH="$SPEECH_DEP_STAGE/bin:$PATH"
export LD_LIBRARY_PATH="$SPEECH_DEP_STAGE${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
bash tests/acceptance/test_host.sh
```

Staging compiles the real guest CoreMedia module plus test-only
`CMSampleBuffer` / AVFoundation audio types. Those fixtures are **not**
linked into `libSpeech.dylib`. A passing isolated gate is not integrated
Linux success.

The EC2 integrated run must build real guest Foundation, AVFoundation, and
CoreMedia first, compile Speech with their `-I`/`-L` paths, and run
`tests/agent/SpeechDependencyIdentity.swift` (marker
`SPEECH_DEPENDENCY_IDENTITY_OK`) with `LD_LIBRARY_PATH` including
`libSpeech.dylib`.

## Deferred / unverified

- Exact integer values for iOS 26 analyzer overlay error codes (see
  `ORACLE.md`). Those cases exist for source compatibility only.
- Exact `SFSpeechErrorDomain` string on an Apple runtime (this port uses
  `SFSpeechErrorDomain`).
- Apple proprietary custom-language-model binary format.
- On-device model download, microphone capture, and remote dictation.
- `SFSpeechRecognizer.init?()` as a failable convenience override of
  `NSObject.init()` (Linux uses non-failable `override init()`).

See `oracle-questions.tsv` for the probe list.
