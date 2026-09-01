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

## Fail-closed boundaries

These paths never fabricate Apple speech, microphone, privacy-grant, or
asset-download success:

- `SFSpeechRecognizer.isAvailable` is always `false`.
- `authorizationStatus()` / `requestAuthorization` stay at `.denied`.
- `supportedLocales()` / transcriber locale inventories are empty.
- Recognition tasks complete immediately with `SFSpeechError.noModel`.
- `SpeechAnalyzer` prepare/start/analyze methods throw `noModel` or
  `audioReadFailed`.
- `AssetInventory` reports `.unsupported`; `reserve(locale:)` throws
  `cannotAllocateUnsupportedLocale`; downloads throw `noModel`.
- `SFSpeechLanguageModel.prepareCustomLanguageModel` throws `noModel`.

AVFoundation / CoreMedia types used in Speech signatures (`AVAudioFormat`,
`AVAudioPCMBuffer`, `AVAudioFile`, `CMTime`, `CMTimeRange`,
`CMSampleBuffer`) are Speech-local stand-ins because the isolated host gate
cannot import those modules.

## Deferred / unverified

- Exact integer values for iOS 26 analyzer overlay error codes.
- Exact `SFSpeechErrorDomain` string on an Apple runtime (this port uses
  `SFSpeechErrorDomain`).
- Apple proprietary custom-language-model binary format.
- On-device model download, microphone capture, and remote dictation.

See `oracle-questions.tsv` for the probe list.
