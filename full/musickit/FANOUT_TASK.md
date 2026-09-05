# Port `MusicKit` to Linux

Build a substantial, honest starting implementation of Apple's public `MusicKit`
surface without changing any app source or shared platform integration file.
This is a **medium-full** lane seeded from Xcode 26.1's iPhoneOS
26.1 SDK.

The immutable seed contains 2534 unique public precise identifiers and
3526 symbol-graph relationships. The acceptance floor is
1267 nondeferred (`implemented` or `declared`) identifiers: ceil(50% of exact public symbols).

Start with `reference/public-surface.tsv`, then use the raw exact graphs listed by
`reference/symbol-graphs.json` for declarations, relationships, and availability.
The compact surface deterministically selects one occurrence per precise ID;
the graph manifest records the selection policy and duplicate/conflict counts,
while every raw occurrence remains immutable for review.
Reconcile each planned declaration with `reference/api-digester.json` before
coding. It supplies the compiler's imported ObjC USRs, base/protocol identity,
selectors, optionality, attributes, and ordered enum children. Then consult the
pinned independent bindings described by `reference/external-evidence.json` as a
secondary cross-check. Apple-derived evidence wins; any unresolved conflict is an
oracle question, not a license to guess. External bindings are not runtime
evidence and their implementation must not be copied.
Use `reference/sdk-inputs.tsv` and `reference/tbd-exports.tsv` as provenance and
ABI evidence only; the Apple SDK input bytes are intentionally absent. Use
`reference/corpus-summary.json` to prioritize APIs exercised by the 20-app
roadmap corpus.

Deliver all of the following in `full/musickit/`:

1. Linux Swift sources for module `MusicKit` and `libMusicKit.dylib`, with every
   implementation source listed in `musickit_guest_sources.txt`.
2. Complete exact-ID `coverage.tsv` using only the five allowed statuses.
   `implemented` evidence has the exact form
   `test:full/musickit/tests/agent/*Tests.swift#testName`; `declared` evidence has
   the exact form `source:full/musickit/<product-source>.swift#Symbol`. Every cited
   test/function and product source/anchor must exist, and the product source
   must be listed in `musickit_guest_sources.txt`.
3. Nonempty `MusicKit.swift` and `README.md`, plus `oracle-questions.tsv` with
   header `precise	question	risk	reason` and at least one question; use
   `module` only for cross-cutting items.
4. Top-level synchronous no-argument functions named `test*` in
   `tests/agent/*Tests.swift`, plus `tests/agent/MusicKitLoadSmoke.swift` whose
   exact content is `import MusicKit`, one blank line, and
   `let frameworkLoadSmokeMarker = "MUSICKIT_AGENT_RUNTIME_OK"`. The sealed gate derives a runner
   from `implemented` coverage, loads `libMusicKit.dylib`, and calls each cited
   test exactly once before accepting marker-only output. The load/marker check
   is not behavioral evidence by itself.
5. If dependencies are declared, `tests/agent/MusicKitDependencyIdentity.swift`
   importing the real modules and exercising genuine dependency values. The
   clean EC2 integration build, not a framework-local lookalike, is the authority.
6. A clean successful run of `bash tests/acceptance/test_host.sh` with no checked-
   in or stale build products.

Declared dependencies:

- `Foundation`

Known risk labels:

- `network`
- `os-service`
- `fail-closed`

Do not invent successful Apple service, device, entitlement, privacy, or UI
behavior. Record questions that need a central Apple-oracle probe and keep those
paths fail-closed until observed. Static declarations and binding annotations do
not prove defaults, callback timing, queue choice, exactly-once delivery,
retention, coding round trips, hardware behavior, or service results.
