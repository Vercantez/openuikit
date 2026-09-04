# NaturalLanguage (Linux starting point)

This directory is a clean-room Linux starting point for Apple's public
`NaturalLanguage` module, seeded from the Xcode 26.1 iPhoneOS 26.1 symbol
graph, API digester, and TBD exports. It is not wired into the shared guest
package; that integration is a later central-review step.

The existing portable `NLLanguageRecognizer` from the earlier IceCubes
frontier is kept. This wave-6 pass adds tokenizer/tagger/gazetteer/embedding
declarations, schema-v2 coverage accounting, and the sealed host-gate probes.

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
  three local schemes.
- `NLGazetteer` stores an in-memory label→terms map and round-trips a Linux
  JSON file (`nlGazetteerFormat=1`). It does not read Apple gazetteer binaries.
- `NLEmbedding.write` / `init(contentsOf:)` round-trip a Linux JSON vector
  table and compute cosine distance (`1 − cosine similarity`). Apple word and
  sentence embedding tables are absent: factory methods return nil, revision
  0, and an empty `IndexSet`.
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
- `NLModel(contentsOf:)` throws a Linux-local `NSError`.
- `NLContextualEmbedding` failable inits return nil; `contextualEmbeddings(forValues:)` is empty.
- Model-backed tag schemes return nil tags.
- `init(mlModel:)` is omitted (CoreML is not a declared dependency).
- `setOrthography(_:range:)` is omitted (`NSOrthography` is unavailable in
  swift-corelibs-foundation).

## Still deferred

See `oracle-questions.tsv` for ICU word-break parity, NLTag CFString
payloads, Apple embedding revisions, gazetteer binary layout, asset-request
queues, and Create ML import.

Keep generated products out of the tree. Run
`bash tests/acceptance/test_host.sh` from this directory.
