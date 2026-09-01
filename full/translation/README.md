# Translation

Linux starting implementation of Apple's public `Translation` module, seeded
from the Xcode 26.1 iPhoneOS 26.1 SDK symbol graphs. The leaf depends only on
`Foundation`. It produces `libTranslation.dylib` and a Swift module named
`Translation`.

## What is real

Value types and local session bookkeeping are implemented and exercised:

- `TranslationError` static cases, `LocalizedError` descriptions, and `~=`
  pattern matching
- `LanguageAvailability` and `LanguageAvailability.Status` (`Equatable` /
  `Hashable`)
- `TranslationSession.Request`, `Response`, `Configuration` (including
  `invalidate()` / `version` identity), and `BatchResponse: AsyncSequence`
- `TranslationSession.init(installedSource:target:)`, stored languages,
  `canRequestDownloads`, `isReady`, and `cancel()`

`TranslationSession.Response.init` exists for tests and previews, matching the
public graph. Callers may construct sample responses; the session never emits
one.

## Fail-closed boundaries

Linux has no Apple translation language packs, on-device models, language
identification, download UI, or system translation popover. The port does not
invent that behavior:

- `LanguageAvailability.supportedLanguages` is empty
- `status(from:to:)` is always `.unsupported`
- `status(for:to:)` always throws `TranslationError.unableToIdentifyLanguage`
- `TranslationSession.canRequestDownloads` is `false` and `isReady` is `false`
- `prepareTranslation()`, `translate(_:)`, `translations(from:)`, and
  iterating `translate(batch:)` throw a typed `TranslationError`
  (`nothingToTranslate`, `alreadyCancelled`, `unableToIdentifyLanguage`,
  `unsupportedLanguagePairing`, or `notInstalled`)
- No translated `targetText` is ever produced by the session

Same-language pairings (shared `Locale.Language.languageCode`, including
en-US/en-GB) fail as `unsupportedLanguagePairing`, following the public note
that the framework does not translate a language to itself.

## Not applicable / still deferred

The `_Translation_SwiftUI` view modifiers (`translationTask` and
`translationPresentation`) require SwiftUI (`View`, `Binding`,
`PopoverAttachmentAnchor`, `Edge`). This leaf's declared dependency is
`Foundation` only, so those three symbols are `not-applicable`.

`AsyncSequence` combinators on `BatchResponse` (`map`, `filter`, `reduce`,
and the other stdlib overlays) compile through protocol conformance. They are
declared, not reimplemented.

Apple-only questions (exact localized strings, language-asset catalogs, LID
thresholds, download prompts) stay in `oracle-questions.tsv`.
