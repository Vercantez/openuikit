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
- `GeneratedContent` supports scalar, array, and ordered structure values,
  typed property decoding, JSON parse/print, IDs, equality, and in-memory
  round trips. JSON object key order after `JSONSerialization` is not claimed
  to match Apple.
- `GenerationGuide`, `GenerationSchema` (including `SchemaError`, `anyOf`,
  dynamic-root init, and a **local** Codable representation),
  `DynamicGenerationSchema`, `Instructions`, `Prompt`, result builders,
  `GenerationOptions`, `Transcript`, `Tool`, and `LanguageModelFeedback`
  are source-compatible declarations with focused tests for the portable
  data plane.
- `Decimal`, `Optional`, and `Array` Generable conformances match the graph.

Host-compiled sources import Foundation only. The identity probe
`tests/agent/FoundationModelsDependencyIdentity.swift` imports
`FoundationModels` and `Foundation` for the later EC2 integration build.

## Fail-closed boundaries

Linux does not have Apple Intelligence model assets or the private inference
runtime.

- `SystemLanguageModel` reports `.unavailable(.deviceNotEligible)`,
  `isAvailable` is false, `supportedLanguages` is empty, and
  `supportsLocale` is false.
- Direct and streaming `LanguageModelSession` inference throw
  `GenerationError.assetsUnavailable`. No fabricated model output is
  returned. This preserves IceCubes' existing fallback path.
- `SystemLanguageModel.Adapter` inits, `compile()`, and
  `removeObsoleteAdapters()` throw `AssetError.invalidAsset`.
  `compatibleAdapterIdentifiers` returns an empty list.
- `logFeedbackAttachment` returns empty `Data`. That is a local no-op, not
  an Apple feedback payload.
- `GenerationError.Refusal.explanation` throws `assetsUnavailable`.

## Deferred / not applicable

- `Adapter.isCompatible(_:)` takes `BackgroundAssets.AssetPack`. That module
  is not a seeded host dependency; no public lookalike is declared.
- Swift stdlib `Int` BinaryInteger/format witnesses that appear in the
  FoundationModels graph are `not-applicable`; this module does not own them.
- Apple's exact schema/transcript Codable documents, feedback `Data`
  contents, adapter compiler errors, and availability-reason mapping remain
  oracle questions.

## Frozen IceCubes frontier

The IceCubes compiler/runtime frontier is unchanged: untouched commit
`b2db3033fbf67a97b54d25d6dac2df8a029b26b1`, `FoundationModels.swift` plus
`FoundationModelsMacros.swift`, and fail-closed inference. Guest builders
still compile that single runtime source.

Run the sealed host gate with:

```sh
python3 -B full/framework-fanout/validate_seed.py --framework full/foundationmodels --phase deliverable
bash full/foundationmodels/tests/acceptance/test_host.sh
```
