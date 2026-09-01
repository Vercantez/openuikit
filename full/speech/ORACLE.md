# Speech oracle notes

These rows are **inferred**, not Apple-runtime attested. Do not mark them
`implemented` in `coverage.tsv` until a header or live-NSError probe confirms
the integers.

## Inferred `SFSpeechError.Code` overlay raw values

Classic `SFSpeechErrorCode` integers from public headers:

| Case | Raw value | Status |
| --- | --- | --- |
| `internalServiceError` | 1 | attested |
| `audioReadFailed` | 2 | attested |
| `undefinedTemplateClassName` | 7 | attested |
| `malformedSupplementalModel` | 8 | attested |
| `timeout` | 12 | attested |
| `missingParameter` | 13 | attested |

Overlay cases present for source compatibility. Slot-filling integers below
are **inferred** from unused `SFSpeechErrorCode` numbers and must not be
treated as ABI:

| Case | Inferred raw value |
| --- | --- |
| `audioDisordered` | 3 |
| `unexpectedAudioFormat` | 4 |
| `noModel` | 5 |
| `incompatibleAudioFormats` | 6 |
| `moduleOutputFailed` | 9 |
| `assetLocaleNotAllocated` | 10 |
| `tooManyAssetLocalesAllocated` | 11 |
| `cannotAllocateUnsupportedLocale` | 15 |
| `insufficientResources` | 16 |

Fail-closed production paths use attested codes (`internalServiceError` or
`audioReadFailed`) until an oracle names the overlay integers.

## Authorization callback scheduling

`SFSpeechRecognizer.requestAuthorization` is a **class** method. This port
invokes the handler synchronously with `.denied` before returning. Apple's
queue (main, an internal privacy queue, or something else) is unattested.
Do not deliver this callback on an instance `recognizer.queue`.

## Custom language-model binary

`SFCustomLanguageModelData.export(to:)` writes a portable JSON snapshot.
Apple's supplemental-model binary layout is unattested.

## Isolated staging versus EC2

The immutable isolated gate compiles Speech without `-I` for AVFoundation or
CoreMedia. `tests/agent/stage_isolated_deps.sh` builds:

- real guest `full/coremedia/CoreMedia.swift` plus a **test-only**
  `CMSampleBuffer` compiled into module `CoreMedia`
- a **test-only** `AVFoundation` module with `AVAudioFormat` /
  `AVAudioPCMBuffer` / `AVAudioFile`

Those fixtures are not part of `libSpeech.dylib`. Production Speech imports
the modules so values keep CoreMedia/AVFoundation nominal identity.

The EC2 integrated run must build the real guest Foundation, AVFoundation,
and CoreMedia dylibs first, then compile Speech against those `-I`/`-L`
paths. `tests/agent/SpeechDependencyIdentity.swift` is the client for that
run; the isolated gate does not compile it.
