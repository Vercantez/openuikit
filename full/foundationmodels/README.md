# FoundationModels Linux lane (wave-6 deliverable)

This directory is a clean-room Linux starting point for Apple's public
`FoundationModels` module, seeded from the Xcode 26.1 iPhoneOS 26.1 symbol
graph, API digester, and TBD exports. It keeps the existing IceCubes
compiler/data-plane implementation and extends it to the wave-6 deliverable
gate. It is not wired into the shared guest package; that integration is a
later central-review step.

## What is real

- `@Generable` / `@Guide` still expand on the Apple SDK and Mach-O guest via
  `FoundationModelsMacros`. The isolated Linux host compiles the module
  without `#externalMacro` because the SwiftSyntax plugin is not loaded.
  Tests adopt the protocol-based `Generable` surface (nested structs, string
  enums, arrays, and scalar guides).
- `GeneratedContent` supports scalar, array, and ordered structure values,
  typed property decoding, JSON parse/print, IDs, equality, `isComplete`
  partial snapshots, and in-memory round trips. JSON object key order after
  `JSONSerialization` is not claimed to match Apple.
- `GenerationGuide`, `GenerationSchema` (including `SchemaError`, `anyOf`,
  dynamic-root init, and a **local** Codable representation),
  `DynamicGenerationSchema`, `Instructions`, `Prompt`, result builders,
  `GenerationOptions`, `Transcript` (Entry-preserving local Codable),
  `Tool`, and `LanguageModelFeedback` are source-compatible with focused
  tests for the portable data plane.
- `Decimal`, `Optional`, and `Array` Generable conformances match the graph.

Host-compiled sources import Foundation only. The identity probe
`tests/agent/FoundationModelsDependencyIdentity.swift` imports
`FoundationModels` and `Foundation` for the later EC2 integration build.

## Fail-closed boundaries

Linux does not have Apple Intelligence model assets or the private inference
runtime.

- Default `SystemLanguageModel` reports `.unavailable(.deviceNotEligible)`,
  `isAvailable` is false, `supportedLanguages` is empty, and
  `supportsLocale` is false. IceCubes fallback paths that check availability
  still see an unavailable model.
- Direct and streaming `LanguageModelSession` inference throw
  `GenerationError.assetsUnavailable` unless the documented Linux stand-in is
  installed. No Apple model output is fabricated.
- `SystemLanguageModel.Adapter` inits, `compile()`, and
  `removeObsoleteAdapters()` throw `AssetError.invalidAsset`.
  `compatibleAdapterIdentifiers` returns an empty list.
- `logFeedbackAttachment` returns empty `Data`. That is a local no-op, not
  an Apple feedback payload.
- `GenerationError.Refusal.explanation` throws `assetsUnavailable`.
- Regex `@Guide` / `GenerationGuide.pattern` is recorded locally; applying
  Apple's regex engine at generation time is fail-closed
  (`unsupportedGuide` via the `OPENUIKIT_FM_REGEX_GUIDE` sentinel).

## Deferred / not applicable

- `Adapter.isCompatible(_:)` takes `BackgroundAssets.AssetPack`. That module
  is not a seeded host dependency; no public lookalike is declared.
- Swift stdlib `Int` BinaryInteger/format witnesses that appear in the
  FoundationModels graph are `not-applicable`; this module does not own them.
- `@Generable` / `@Guide` macros stay `declared` on the isolated Linux host.
- Combine `Sequence.publisher` witnesses stay `declared` (Combine is not a
  seeded host dependency).
- `Never.generatedContent` / `Never.init(_:)` cannot be executed.
- Apple's exact schema/transcript Codable documents, feedback `Data`
  contents, adapter compiler errors, and availability-reason mapping remain
  oracle questions.

## Frozen IceCubes frontier

The IceCubes compiler/runtime frontier is unchanged: untouched commit
`b2db3033fbf67a97b54d25d6dac2df8a029b26b1`, `FoundationModels.swift` plus
`FoundationModelsMacros.swift`. Default inference remains fail-closed so
existing fallback paths keep working. Guest builders still compile that
single runtime source.

Run the sealed host gate with:

```sh
python3 -B full/framework-fanout/validate_seed.py --framework full/foundationmodels --phase deliverable
bash full/foundationmodels/tests/acceptance/test_host.sh
```

## Depth pass 2026-09

This pass finishes the available public surface with a documented
deterministic stand-in model. It is not on-device Apple Intelligence.

### Public surface

- `SystemLanguageModel`: default use case/guardrails, availability, supported
  languages, locale checks. Default availability is
  `.unavailable(.deviceNotEligible)`.
- `LanguageModelSession`: inits with instructions/tools/transcript, `prewarm`,
  `isResponding`, `respond(to:options:)` and `streamResponse` producing
  `Response` / `ResponseStream.Snapshot` (partial then complete for strings).
- `Tool` calling: when the prompt has prefix `OPENUIKIT_FM_TOOL <name> <args>`,
  the stand-in invokes the named session tool and appends
  `toolCalls` / `toolOutput` transcript entries. Tool `Output` is bridged
  through `PromptRepresentable` into `GeneratedContent` / text segments.
- `@Generable` protocol (not the SwiftSyntax macro on Linux): String, Int,
  Double, Bool, arrays, nested structs, and string enums with `@Guide`-shaped
  `GenerationGuide` constraints (description, anyOf, range, count). Regex
  pattern guides are listed fail-closed.
- `InstructionsBuilder` / `PromptBuilder` string composition.
- `Transcript.Entry` Codable round trip for
  instructions/prompt/response/toolCalls/toolOutput (local document, not
  Apple's archive).
- `LanguageModelFeedback` sentiment/issue value types. Attachment logging
  remains empty `Data`.

Coverage after this pass: implemented ≥ 660 of 754 IDs; remaining declared
rows are macros, Combine publishers, and uninhabited `Never` witnesses.
`Adapter.isCompatible` stays deferred.

### Linux stand-in contract

Install with `SystemLanguageModel.installLinuxStandInForTesting()` and remove
with `removeLinuxStandInForTesting()`. While installed:

- availability becomes `.available`; `supportedLanguages` contains English.
- `respond` / `streamResponse` echo `"STANDIN:" + prompt` (truncated to
  `maximumResponseTokens` characters when set).
- `temperature` must be in `0...2`; `maximumResponseTokens` must be `>= 1`.
- transcript grows in order: instructions (once), prompt, optional tool
  calls/output, response.
- sentinels: `OPENUIKIT_FM_GUARDRAIL`, `OPENUIKIT_FM_REFUSAL`,
  `OPENUIKIT_FM_REGEX_GUIDE`, `OPENUIKIT_FM_LOCALE`, plus the 8192-character
  context window.

### Unresolved behavioral questions

- Exact Apple sampling/token accounting vs this character-truncated echo.
- Whether `Tool.name` has a protocol default, and its string.
- Apple's Transcript/GenerationSchema wire documents.
- Mapping of Darwin entitlement/hardware states onto
  `UnavailableReason` values other than `deviceNotEligible`.
- Bytes returned by `logFeedbackAttachment` on Apple Intelligence.
- `ResponseStream.next(isolation:)` actor/isolation timing on Apple.
