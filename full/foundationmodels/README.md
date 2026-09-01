# Portable FoundationModels

This tranche supplies the first real `FoundationModels` framework boundary for
untouched IceCubes builds on Linux. It publishes an ARM64 Mach-O
`libFoundationModels.dylib`, a target Swift module, and a relocatable native
AArch64 `FoundationModelsMacros` compiler plugin.

The implemented compiler/data plane is functional rather than nominal:

- `@Generable` derives a generation schema, generated-content encoder,
  generated-content decoder, and partially generated representation for typed
  stored properties.
- `@Guide` carries descriptions and array count constraints into the generated
  schema. The `.count(5)` inference bridge matches the Apple SDK's `[Never]`
  fallback technique.
- `GeneratedContent` supports scalar, array, and ordered structure values,
  typed property decoding, stable JSON, IDs, equality, and round trips.
- `GenerationGuide`, `GenerationSchema`, `Instructions`, `Prompt`, builders,
  `GenerationOptions`, responses, and asynchronous response streams cover the
  exact IceCubes StatusKit surface.

Linux does not have Apple's private model assets or Apple Intelligence service.
The service plane therefore fails closed: `SystemLanguageModel` reports
`.unavailable(.deviceNotEligible)`, `isAvailable` is false, and direct and
streaming inference throw `LanguageModelSession.GenerationError.assetsUnavailable`.
No fabricated model output is returned. This activates IceCubes' existing
fallback behavior without changing its source.

## Frozen consumer and differential

The frontier is frozen to untouched IceCubes commit
`b2db3033fbf67a97b54d25d6dac2df8a029b26b1`. The two StatusKit source hashes,
line denominators, and API calls live in
`tests/icecubes_foundationmodels_frontier.tsv`.

`FoundationModelsNativeOracle.swift` runs against Apple's Xcode 26.1 framework.
The portable generated-content transcript is required to match its four-line
golden byte for byte. The portable macro expansion is also audited for the
schema, encoder, partial value, guide, and conformance derivations.

Run the fast native differential on macOS:

```sh
bash full/foundationmodels/tests/test_foundationmodels_native.sh
```

Run the Linux-built true-iOS ARM64 Mach-O proof against a completed platform
package:

```sh
bash full/foundationmodels/tests/build_foundationmodels_guest.sh
```

The latter refuses a dirty FoundationModels tranche or a nonempty output,
builds the native ELF plugin and target Mach-O artifacts from cold inputs,
audits their architectures and load commands, expands the exact IceCubes macro
shape, cold-runs it through `machorun`, and records a complete source/artifact
attestation.
