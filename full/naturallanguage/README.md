# Portable NaturalLanguage frontier

This tranche implements the exact `NaturalLanguage` boundary that blocks the
untouched IceCubes `StatusKit` package on Linux. The pinned app commit imports
the framework in three files; its concrete runtime path creates
`NLLanguageRecognizer`, calls `processString`, asks for one hypothesis, checks
the probability against `0.85`, and consumes `NLLanguage.rawValue`.

The implementation is a real local classifier, not a service-success stub. It
first identifies distinctive Unicode scripts, then classifies Latin text with
compact character-trigram profiles and marker-word evidence. Incremental
processing, reset, language constraints, and prior hints are supported. Short
or content-free input deliberately produces low/no evidence, preserving
IceCubes' `nil` fallback instead of inventing a confident language.

`tests/NaturalLanguageIceCubesOracle.swift` is compiled twice with the exact,
unmodified 34-line IceCubes `LanguageDetection.swift`: once against Apple
NaturalLanguage 26.1 and once against this framework. The 17-line transcript
must match byte-for-byte. It covers six Latin languages, three non-Latin
scripts, IceCubes' mention/hashtag/emoji stripping, low-evidence fallback,
direct and incremental recognition, reset, constraints, and hints.

An independent 29-sentence generalization oracle then exercises 19 Latin
profiles and ten script routes with text that is not used by IceCubes. Both the
top BCP-47 identity and IceCubes' `>= 0.85` confidence decision match Apple
26.1 for all 29 cases. This broader corpus is also compiled and cold-run as an
ARM64 Mach-O executable, preventing a native-host-only classifier result.

The guest builder additionally emits `libNaturalLanguage.dylib`, compiles the
same untouched consumer for `arm64-apple-ios18.0-simulator`, audits the Mach-O
module/dylib/executable identities, cold-runs it through the published Linux
guest root, and brackets every app/framework/oracle input by hash. It only
creates a narrowly named output directory; it never edits IceCubes or a
platform package.

This tranche intentionally does not claim Apple's private tokenizer, tagger,
embedding, model, or gazetteer APIs. Those are separate evidence boundaries.
