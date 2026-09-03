# Port `MetalPerformanceShaders` to Linux

Build a substantial, honest starting implementation of Apple's public `MetalPerformanceShaders`
surface without changing any app source or shared platform integration file.
This is a **large-partitioned** lane seeded from Xcode 26.1's iPhoneOS
26.1 SDK.

The immutable seed contains 3382 unique public precise identifiers and
7000 symbol-graph relationships. The acceptance floor is
150 nondeferred (`implemented` or `declared`) identifiers: min(150, max(50, ceil(10% of exact public symbols))).

Start with `reference/public-surface.tsv`, then use the raw exact graphs listed by
`reference/symbol-graphs.json` for declarations, relationships, and availability.
The compact surface deterministically selects one occurrence per precise ID;
the graph manifest records the selection policy and duplicate/conflict counts,
while every raw occurrence remains immutable for review.
Use `reference/sdk-inputs.tsv` and `reference/tbd-exports.tsv` as provenance and
ABI evidence only; the Apple SDK input bytes are intentionally absent. Use
`reference/corpus-summary.json` to prioritize APIs exercised by the 20-app
roadmap corpus.

Deliver all of the following in `full/metalperformanceshaders/`:

1. Linux Swift sources for module `MetalPerformanceShaders` and `libMetalPerformanceShaders.dylib`, with every
   implementation source listed in `metalperformanceshaders_guest_sources.txt`.
2. Complete exact-ID `coverage.tsv` using only the five allowed statuses and
   evidence paths or test names that substantiate nondeferred claims.
3. Nonempty `MetalPerformanceShaders.swift` and `README.md`, plus `oracle-questions.tsv` with
   header `precise	question	risk	reason` and at least one question; use
   `module` only for cross-cutting items.
4. `tests/agent/MetalPerformanceShadersRuntime.swift`, meaningful focused tests, and the exact
   success marker `METALPERFORMANCESHADERS_AGENT_RUNTIME_OK`.
5. A clean successful run of `bash tests/acceptance/test_host.sh` with no checked-
   in or stale build products.

Declared dependencies:

- `Foundation`
- `Metal`

Known risk labels:

- `gpu`
- `numerics`
- `hardware`
- `metal`

Do not invent successful Apple service, device, entitlement, privacy, or UI
behavior. Record questions that need a central Apple-oracle probe and keep those
paths fail-closed until observed.
