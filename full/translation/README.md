# Translation (Linux starting point)

This directory is a fail-closed portable `Translation` module for the OpenUIKit
Linux platform. It reconstructs the public Xcode 26.1 iPhoneOS Swift surface
from the sealed symbol graph. It is not wired into the shared guest package;
that integration is a separate central review step.

The 20-app corpus exercises this module in Telegram-iOS (`Translate.swift`,
rich-text edit menu) and WordPress-iOS (`TranslationViewModel.swift`):
`TranslationSession`, `translate(_:)`, `LanguageAvailability`, and the
SwiftUI `translationTask` overlay. Focus-iOS in the pinned ladder checkout
does not reference these symbols. Session/availability APIs are implemented
locally; the SwiftUI overlay stays `deferred` because this seed depends only
on Foundation.

## What is real

- `TranslationError` exposes the eight public static cases, `errorDescription`,
  `failureReason`, `LocalizedError` defaults, `localizedDescription`, and `~=`
  matching against `any Error`. Copy is process-local English.
- `LanguageAvailability` constructs, reports an empty `supportedLanguages`
  list, and returns `.unsupported` for every `status(from:to:)` pair,
  including documented same-language pairings (English US → English UK).
  `status(for:to:)` always throws `unableToIdentifyLanguage` (no LID).
- `TranslationSession.init(installedSource:target:)` records languages,
  reports `canRequestDownloads == false` and `isReady == false`, and
  fail-closes with a documented local preflight: `alreadyCancelled`,
  `nothingToTranslate` (empty source text / empty batch),
  `unsupportedLanguagePairing` (same languageCode+script), then
  `notInstalled`.
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
`TRANSLATION_AGENT_RUNTIME_OK`. Focused `*Tests.swift` files are the coverage
evidence for implemented identifiers.

## Depth pass 2026-09

Coverage before: 84 implemented / 0 declared / 3 deferred / 0 unavailable /
2 not-applicable.

Coverage after: 84 implemented / 0 declared / 3 deferred / 0 unavailable /
2 not-applicable.

The prior seed already marked the Foundation surface implemented, but every
row cited `TranslationRuntime.swift` as bulk evidence. This pass keeps the
same 84/3/2 split, replaces evidence with focused `test:…*Tests.swift#testName`
citations, and tightens documented fail-closed behavior (LID always throws,
same-language pairing, `canRequestDownloads == false` ⇒ `notInstalled`).
Implemented count cannot rise further without SwiftUI or fabricating
`Failure == Never` flatMap.

Top-5 evidence distribution (implemented rows):

1. `testTranslationErrorCases` — 9 (table-driven static error cases)
2. `testLanguageAvailabilityStatusCases` — 4 (enum members)
3. All remaining implemented tests — 1 row each

No non-enum test exceeds 40% of implemented rows (cap 33).
