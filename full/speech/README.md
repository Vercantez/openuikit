# Speech Linux starting point

This directory is a **clean-room Linux starting point** for Apple's public `Speech`
module, seeded from the Xcode 26.1 iPhoneOS SDK symbol graphs. It is not a claim
of Apple behavioral parity.

## Depth pass 2026-09

SDK depth for `Speech` (602 IDs). The refused merge at `a1542254` claimed
**564 implemented / 5 declared / 33 unavailable / 0 deferred**, but every
`implemented` row cited `tests/agent/SpeechRuntime.swift` (a file path, not
`test:full/speech/tests/agent/<File>Tests.swift#testName`).

This repair: **563 implemented / 6 declared / 33 unavailable / 0 deferred**.
`AttributeDynamicLookup.subscript(dynamicMember:)` moved to `declared` because
Linux `AttributedString` has no `AttributeScopes.speech` member, so that
subscript is not callable. There is still **no speech engine**. Recognition
succeeds only when a documented `@_spi(OpenUIKitHost)` hook registers a scripted
recognizer.

Top-5 `implemented` evidence (563 rows; no non-enum test exceeds 40% of the
397 remaining non-enum/constant rows):

| Rows | Evidence |
| ---: | --- |
| 42 | `test:full/speech/tests/agent/SpeechErrorTests.swift#testSFSpeechErrorCodes` |
| 32 | `test:full/speech/tests/agent/SpeechCustomLanguageModelTests.swift#testCustomLanguageModelInsert` |
| 29 | `test:full/speech/tests/agent/SpeechEnumTests.swift#testDictationTranscriberEnums` |
| 28 | `test:full/speech/tests/agent/SpeechEnumTests.swift#testSpeechClassicEnums` |
| 27 | `test:full/speech/tests/agent/SpeechEnumTests.swift#testSpeechTranscriberEnums` |

### Public surface that is real

- **`SFSpeechRecognizer.supportedLocales()`** returns the documented QuickType
  dictation catalog cited by
  [supportedLocales()](https://developer.apple.com/documentation/speech/sfspeechrecognizer/supportedlocales())
  ([feature availability](https://www.apple.com/ios/feature-availability/#quicktype-keyboard-dictation)).
- **`init?(locale:)`** returns `nil` when the identifier is not in that catalog
  ([init(locale:)](https://developer.apple.com/documentation/speech/sfspeechrecognizer/init(locale:))).
  Default `init()` always succeeds with `Locale.current` when supported, else `en-US`
  (keyboard-dictation fallback is unobserved).
- **`isAvailable`** is `false` unless `SpeechHostControl.registerScriptedRecognizer`
  installs a script for that locale
  ([isAvailable](https://developer.apple.com/documentation/speech/sfspeechrecognizer/isavailable)).
- **Authorization.** `authorizationStatus()` starts `.notDetermined`.
  `requestAuthorization` remembers the first decision and delivers the handler on
  the **main queue**. Without a host decision the first call fail-closes to
  `.denied` (no TCC prompt).
  [requestAuthorization(_:)](https://developer.apple.com/documentation/speech/sfspeechrecognizer/requestauthorization(_:))
  / [Asking Permission](https://developer.apple.com/documentation/speech/asking-permission-to-use-speech-recognition).
- **Task state machine**
  ([SFSpeechRecognitionTaskState](https://developer.apple.com/documentation/speech/sfspeechrecognitiontaskstate),
  [cancel()](https://developer.apple.com/documentation/speech/sfspeechrecognitiontask/cancel()),
  [finish()](https://developer.apple.com/documentation/speech/sfspeechrecognitiontask/finish())):
  `starting` → `running` → (`finishing` after audio ends / `canceling` after
  `cancel()`) → `completed`. `finish()` is a no-op on URL requests (Apple: the
  file is buffered immediately). Buffer tasks stay `.running` until `endAudio()`
  or `finish()`.
- **Scripted results** deliver `SFSpeechRecognitionResult` /
  `SFTranscription` / `SFTranscriptionSegment` (substring, timestamp, duration,
  confidence, alternativeSubstrings, formattedString, isFinal,
  speechRecognitionMetadata) plus the documented delegate callbacks.
- **Requests.** `SFSpeechURLRecognitionRequest` / `SFSpeechAudioBufferRecognitionRequest`
  store `shouldReportPartialResults`, `requiresOnDeviceRecognition`,
  `contextualStrings`, `addsPunctuation`, `taskHint`. Host `append` /
  `appendAudioSampleBuffer` / `nativeAudioFormat` (16 kHz mono) use isolated
  stand-in buffer types; they are not AVFoundation types.
- **`SFSpeechError`** raw values match pinned `dotnet/macios` Xcode 26:
  `internalServiceError=1`, `audioReadFailed=2`, `undefinedTemplateClassName=7`,
  `malformedSupplementalModel=8`, `timeout=12`, `missingParameter=13`.
- **`kLSRErrorDomain` / `kAFAssistantErrorDomain`** codes from
  [SFSpeechRecognitionTask.error](https://developer.apple.com/documentation/speech/sfspeechrecognitiontask/error):
  102 assets missing, 301 canceled, 1700 not authorized. Darwin string payloads
  are unobserved.
- **`SFSpeechLanguageModel.prepareCustomLanguageModel`** (all four iOS 17/26
  overloads) throw `SFSpeechError.internalServiceError`.
- **`SFVoiceAnalytics` / `SFAcousticFeature`** copy with value `isEqual`.
- Analyzer / transcriber / detector / custom LM data bookkeeping from wave-1
  remains: catalogs empty, `AssetInventory.status` `.unsupported`, export/reserve
  throw.

### Fail-closed boundaries

| Surface | Linux behavior |
| --- | --- |
| Apple speech recognition | No engine. Tasks without a scripted recognizer complete with `kLSRErrorDomain` 102 |
| Microphone / privacy | No prompt. `.notDetermined` → `.denied` unless a host decision is installed. Unauthorized tasks use `kAFAssistantErrorDomain` 1700 |
| On-device models | `isAvailable` stays false until a script is registered |
| `requiresOnDeviceRecognition` without an on-device script | `kLSRErrorDomain` 102 |
| Custom LM prepare / export | `SFSpeechError.internalServiceError` |
| Analyzer audio ingest (`AnalyzerInput`, `prepareToAnalyze`, `AVAudioFile`, `CMTime` APIs) | **unavailable** on this isolated compile (not redeclared) |
| `init(coder:)` | Returns nil; `supportsSecureCoding` is false |

### Tests

Focused top-level `func test*()` checks live in `tests/agent/*Tests.swift`.
The schema-v1 host compiles `tests/agent/SpeechRuntime.swift`, which stitches
those functions and prints `SPEECH_AGENT_RUNTIME_OK`.

Run `bash tests/acceptance/test_host.sh` from this directory (or
`bash full/speech/tests/acceptance/test_host.sh` from the repo root). Keep
generated products out of the tree.

## Dependencies

Product sources `import Foundation`. `AVFoundation` and `CoreMedia` types
are compiled only under `#if canImport(...)`. Isolated-host stand-ins
(`SpeechHostPCMBuffer`, `SpeechHostSampleBuffer`, `SpeechHostAudioFormat`,
`SpeechHostTimeRange`) exist so append / time-range attributes can be
exercised without redeclaring those modules' types.

Linux host controls live under `@_spi(OpenUIKitHost)`.
