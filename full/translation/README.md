# Translation (Linux starting point)

This directory is a fail-closed portable `Translation` module for the OpenUIKit
Linux platform. It reconstructs the public Xcode 26.1 iPhoneOS Swift surface
from the sealed symbol graph. It is not wired into the shared guest package;
that integration is a separate central review step.

The legacy fan-out branch `cursor/port-translation-to-linux-5890` (platform PR
#29) was not readable from this GitHub App installation, so this is a seed
reconstruction rather than a byte-copy of those 692 Swift lines. The monorepo
`reference/` dossier on `origin/main` is the one kept.

## What is real

- `TranslationError` exposes the eight public static cases, `errorDescription`,
  `failureReason`, `LocalizedError` defaults, `localizedDescription`, and `~=`
  matching against `any Error`.
- `LanguageAvailability` constructs, reports an empty `supportedLanguages`
  list, returns `.unsupported` for every language pair, and throws
  `unableToIdentifyLanguage` for empty `status(for:to:)` text.
- `TranslationSession` records `sourceLanguage` / `targetLanguage`, reports
  `canRequestDownloads == false` and `isReady == false`, and fail-closes
  `prepareTranslation()`, `translate(_:)`, and `translations(from:)` with
  typed errors (`notInstalled`, `nothingToTranslate`, `alreadyCancelled`).
- `translate(batch:)` returns a `BatchResponse` whose async iterator throws
  on the first `next()` and never yields a fabricated `targetText`.
- `Configuration.invalidate()` increments `version` so Equatable identity
  changes. `Request` and `Response` store the documented fields.

## Fail-closed boundaries

- Linux has no Apple translation ML service, language pack download, or
  on-device model. This port never invents a successful translation.
- Exact Apple localized error strings, download UI, and language-identification
  heuristics are unobserved; questions are in `oracle-questions.tsv`.
- SwiftUI `View.translationTask` and `translationPresentation` live in the
  `_Translation_SwiftUI` overlay and require SwiftUI, which this seed does
  not declare. Those three precise IDs are `deferred`.
- Two `AsyncSequence.flatMap` overloads constrained to `Failure == Never` are
  `not-applicable` because `BatchResponse.AsyncIterator.next()` throws.

## Tests

`tests/agent/TranslationRuntime.swift` is the host-gate probe and prints
`TRANSLATION_AGENT_RUNTIME_OK`.
