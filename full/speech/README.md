# Speech Linux starting point

This directory is a **clean-room Linux starting point** for Apple's public `Speech`
module, seeded from the Xcode 26.1 iPhoneOS SDK symbol graphs. It is not a claim
of Apple behavioral parity, and it is **not** an integrated Linux success until a
future EC2 cold build imports the real `AVFoundation` and `CoreMedia` modules,
builds and load-tests `libSpeech.dylib`, and passes
`tests/agent/SpeechDependencyIdentity.swift`.

The GitHub App installation that produced this tree can read
`Vercantez/openuikit` only. The fan-out branch
`cursor/port-speech-to-linux-a374` on `openuikit-linux-platform` (legacy PR #20)
was **unavailable** to this run (`git fetch` / GitHub API both 404). This
deliverable is therefore a fresh isolated host implementation from the current
monorepo seed, not a byte-copy of those 2863 Swift lines. The monorepo
`full/speech/reference/` dossier is the one kept (seed generator
`scripts/framework-fanout/generate_seed.py` SHA-256
`2b8230ced5a3ed78f070607346f6a684d9e0fb74a8932b92bc0f5e38f46f0a8e`).

## Dependencies

Product sources `import Foundation`. `AVFoundation` and `CoreMedia` types
(`AVAudioPCMBuffer`, `AVAudioFormat`, `AVAudioFile`, `CMTime`, `CMTimeRange`,
`CMSampleBuffer`) are compiled only under `#if canImport(...)`. This tree does
**not** redeclare those modules' types.

Linux host controls live under `@_spi(OpenUIKitHost)`.

## What has runtime evidence

- **Authorization.** `authorizationStatus()` starts `.notDetermined`.
  `requestAuthorization` stores `.denied` and delivers that status asynchronously,
  exactly once, off the caller, on a serial callback queue. `supportedLocales()`
  is empty.
- **Recognizer bookkeeping.** `SFSpeechRecognizer` is an `NSObject` subclass.
  Locale, `defaultTaskHint`, `supportsOnDeviceRecognition`, and `queue` store.
  `isAvailable` is always `false`.
- **Requests.** URL requests keep their URL and recognition options. Audio-buffer
  `endAudio()` is sticky. PCM/sample-buffer appends are compiled only with
  AVFoundation/CoreMedia.
- **Tasks.** `recognitionTask` stays `.running` until cancel/finish or a queued
  fail-closed hop, then reports `(nil, SFSpeechError.internalServiceError)` and
  `didFinishSuccessfully(false)`. Cancel before that hop sets `isCancelled`.
- **Analyzer surface.** `SpeechAnalyzer` stores modules and `AnalysisContext`.
  `finalizeAndFinishThroughEndOfInput` throws. `AssetInventory.status` is
  `.unsupported`; `reserve` throws. Transcriber/dictation/detector locale
  catalogs are empty; result sequences yield nothing.
- **Custom language model data.** Phrase counts and pronunciations store via the
  result-builder initializer. `export` throws. `supportedPhonemes` is empty.
- **AttributedString confidence.** `AttributeScopes.SpeechAttributes.ConfidenceAttribute`
  round-trips a `Double`. `CMTimeRange` attributes are compiled only with CoreMedia.

## Fail-closed boundaries

| Surface | Linux behavior |
| --- | --- |
| Apple speech recognition | Tasks never produce transcripts |
| Microphone / privacy | Authorization is `.denied`; no prompt |
| On-device models | `isAvailable` / `SpeechTranscriber.isAvailable` stay false |
| Custom LM export / prepare | Throw `SFSpeechError` |
| Analyzer audio ingest | `#if canImport` only; otherwise deferred |
| `init(coder:)` | Returns nil; `supportsSecureCoding` is false |

`SFSpeechErrorDomain` is the literal `SFSpeechErrorDomain`. Apple's string and
analyzer error integers are unobserved; extra analyzer codes use host values
1001...1009 and are not asserted as Apple's.

## Tests

- `tests/agent/SpeechRuntime.swift` prints `SPEECH_AGENT_RUNTIME_OK`.
- `tests/agent/SpeechDependencyIdentity.swift` is a future EC2 probe.
