# NaturalLanguage (Linux starting point)

This directory is a clean-room Linux starting point for Apple's public
`NaturalLanguage` module, seeded from the Xcode 26.1 iPhoneOS 26.1 symbol
graph, API digester, and TBD exports. It is not wired into the shared guest
package; that integration is a later central-review step.

The existing portable `NLLanguageRecognizer` from the earlier IceCubes
frontier is kept. Tokenizer, tagger, gazetteer, embedding, and model
surfaces compile into `libNaturalLanguage.dylib` under the sealed host gate.

## What is real

- `NLLanguage` is a BCP-47 string newtype. The IceCubes `StatusKit` consumer
  still classifies Latin text with the compact trigram/marker-word model and
  non-Latin text by Unicode script. Incremental `processString`, `reset`,
  constraints, and hints are unchanged.
- `NLScript`, `NLTag`, and `NLTagScheme` are string newtypes. Script raw
  values are ISO 15924 codes. Tag/scheme raw values follow the documented
  `NSLinguisticTag` strings until an Apple oracle records the NL* CFStrings.
- `NLTokenizer` splits word/sentence/paragraph/document ranges using Swift
  `Character` classes (letter/number/whitespace/punctuation). This is a local
  tokenizer, not Apple's ICU word-break.
- `NLTagger` implements `.tokenType`, `.language`, and `.script` locally.
  Gazetteers overlay labels for whatever scheme they are attached to.
  `.lemma`, `.lexicalClass`, `.nameType`, and `.sentimentScore` return nil
  without Apple models. `requestAssets` reports `.available` only for the
  three local schemes and invokes the completion handler on the caller.
- `NLGazetteer` stores an in-memory label→terms map and round-trips a Linux
  JSON file (`nlGazetteerFormat=1`). It does not read Apple gazetteer binaries.
- `NLEmbedding.write` / `init(contentsOf:)` round-trip a Linux JSON vector
  table and compute cosine distance (`1 − cosine similarity`). Apple word and
  sentence embedding tables are absent: factory methods return nil, revision
  0, and an empty `IndexSet`.
- `NLContextualEmbedding` inits return a catalog entry with
  `hasAvailableAssets == false`, `dimension == 0`, and `revision == 0`.
  `load()` throws. `requestAssets` completes synchronously with
  `.notAvailable`. `embeddingResult` returns a result that stores the input
  string and language, with `sequenceLength == 0` and no token vectors.
- `NLModel(contentsOf:)` accepts a Linux JSON model (`nlModelFormat=1`) with
  exact-string labels. Classifier lookup returns that label (confidence 1.0);
  sequence lookup labels each token. Apple Create ML packages throw.
- Integer enums and option sets use the sequential / bit-shift raw values
  corroborated by the pinned dotnet/macios bindings (`NLTokenUnit`,
  `NLDistanceType`, `NLModel.ModelType`, asset-result enums, `NLTagger.Options`,
  `NLTokenizer.Attributes`).

`tests/agent/NaturalLanguageRuntime.swift` is a standalone probe that prints
`NATURALLANGUAGE_AGENT_RUNTIME_OK`. The sealed schema-v2 gate derives its
runner from `implemented` coverage and `*Tests.swift`.

## Fail-closed boundaries

Linux has no Apple NaturalLanguage models, asset downloads, Create ML
runtime, or `NSOrthography`.

- `NLEmbedding.wordEmbedding(for:)` / `sentenceEmbedding(for:)` return nil.
- `NLModel(contentsOf:)` throws unless the file is Linux JSON `nlModelFormat=1`.
- `NLContextualEmbedding` never reports available Apple assets; `load()` throws.
- Model-backed tag schemes return nil tags.
- `init(mlModel:)` is omitted (CoreML is not a declared dependency).
- `setOrthography(_:range:)` is omitted (`NSOrthography` is unavailable in
  swift-corelibs-foundation).

## Still deferred

See `oracle-questions.tsv` for ICU word-break parity, NLTag CFString
payloads, Apple embedding revisions, gazetteer binary layout, asset-request
queues, Create ML import, and whether Apple `init(language:)` is nil when
assets are missing.

Keep generated products out of the tree. Run
`bash tests/acceptance/test_host.sh` from this directory.

## Depth pass 2026-09

Coverage before this pass: 338 implemented / 25 declared / 3 deferred /
0 unavailable / 0 not-applicable (366 exact IDs).

Coverage after this pass: 363 implemented / 0 declared / 3 deferred /
0 unavailable / 0 not-applicable.

The three remaining deferred identifiers are Apple-service / missing-type
boundaries that cannot be implemented without a forbidden substitute:

- `NLModel.init(mlModel:)` and its synthesized `init(MLModel:)` (CoreML
  `MLModel` is not a declared dependency).
- `NLTagger.setOrthography(_:range:)` (`NSOrthography` is absent from
  swift-corelibs-foundation).

The 25 previously `declared` identifiers are now `implemented` with
constructible fail-closed instances: contextual embedding catalog entries
(no Apple assets), empty `NLContextualEmbeddingResult` values, and Linux
JSON `NLModel` lookup tables.

Top-5 evidence distribution after this pass (of 363 implemented rows):

1. `testNLLanguageConstants` — 63 rows (17.4%)
2. `testNLTagAndSchemeConstants` — 57 rows (15.7%)
3. `testNLTaggerOptionsAndTokenizerAttributes` — 55 rows (15.2%)
4. `testNLScriptConstants` — 36 rows (9.9%)
5. `testNLTokenUnitAndDistanceType` — 34 rows (9.4%)

Those five are enum / option-set / constant table tests. Of the 25 rows
raised in this pass, the largest single citation is
`testNLContextualEmbeddingUnavailableProperties` at 7/25 (28%).
