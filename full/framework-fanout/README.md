# Framework fan-out campaign contract

This directory contains the shared machinery for producing many **reviewable
framework starting points** in parallel. A passing cloud-agent branch is useful
input to the platform effort. It is not a claim of Apple behavioral parity and
it is not, by itself, a production framework.

Headers, Swift symbol graphs, and the Swift API digester describe compile-time
surface. A `.tbd` records linker-visible symbols. Pinned independent bindings
can corroborate imported identities and enum values. None of these sources
establishes runtime behavior, threading, callbacks, persistence, error payloads,
entitlements, daemon interaction, or hardware semantics. Agents must say
`deferred` or `unavailable` when those facts are not known; invented success is
worse than a clearly marked gap.

New campaigns must use `scripts/framework-fanout/generate_seed_v2.py`. The
original `generate_seed.py` remains frozen so already-published schema-v1 seeds
can still be reproduced and validated; it is not the template for new fan-out.

## Two gates

Run a seed gate immediately before dispatch:

```sh
python3 -B full/framework-fanout/validate_seed.py \
  --framework full/<slug> --phase seed
```

Run the deliverable gate before accepting an agent branch:

```sh
python3 -B full/framework-fanout/validate_seed.py \
  --framework full/<slug> --phase deliverable
```

The seed gate verifies more than file presence. It joins the raw symbol graphs
to `public-surface.tsv`, verifies the graph manifest's counts and hashes,
verifies both canonical SHA-256 ledgers, checks SDK-input and `.tbd` metadata,
validates the location-free `swift-api-digester` tree, verifies the pinned
external-evidence lock, and compares the corpus summary byte-for-byte with the
pinned framework-roadmap records and rankings. Repository-relative generator,
roadmap, and evidence-lock provenance is also rehashed. The framework metadata
keeps its dependency module tokens sorted and unique so later integration can
plan a real module graph rather than infer dependencies from an agent's
implementation.

Framework schema v2 adds `reference/api-digester.json`,
`reference/api-crosswalk.tsv`, `reference/symbol-conflicts.tsv`, and
`reference/external-evidence.json`. The symbol graph remains the exact public-ID
census. The API digester complements it with compiler-imported ObjC USRs,
superclass/protocol identity, declaration attributes, optionality, and ordered
children. The crosswalk records, for every graph ID, whether a declaration was
matched by exact USR, by an unambiguous imported name, ambiguously, or not at
all. It is an audit trail, not permission to invent a match.

The external dossier currently pins `dotnet/macios` at one immutable commit.
Cursor's saved environment materializes that source once under
`$OPENUIKIT_MACIOS_ROOT` as a root-owned, read-only checkout, so agents can
inspect binding annotations without spending every run recloning it. The saved
environment verifies its origin, commit, license digest, ownership, modes,
cleanliness, and absence of symlinks before work begins. Apple-derived
declaration evidence wins every declaration conflict. Runtime behavior is
established only by an Apple runtime oracle or focused implementation tests;
static binding data is never runtime evidence.

Read-only ownership prevents accidental edits, not hostile tampering: cloud
agents have passwordless `sudo`. Every later central audit must re-verify the
pinned commit, tree cleanliness, origin, license digest, and framework diff;
filesystem mode alone is never a trust boundary.

Apple's extractor can emit one precise identifier in multiple raw graphs, and
the full symbol objects can legitimately disagree. No occurrence is discarded
from the immutable evidence. `symbol-graphs.json` records both the number of
extra occurrences and the number of precise IDs having more than one distinct
full canonical-JSON payload; the validator recomputes both counts from the raw
graphs. In schema v2, `reference/symbol-conflicts.tsv` preserves every distinct
payload, graph path, ownership tier, multiplicity, and the selected canonical
row for each conflicting ID. `symbolCount`, the public surface, and later
coverage remain one row per unique precise ID.

The extractor may also vary array order between otherwise equivalent runs.
Because the raw graphs are retained byte-for-byte, two fresh seeds are not
promised to have identical whole-tree hashes. Schema v2 therefore records
separate symbol and relationship multiset hashes. They hash sorted canonical
JSON payloads using domain-separated, unsigned-64-bit length framing, retain
duplicate multiplicity, and ignore only raw whitespace, object-key order,
outer collection order, and graph-file iteration order. Compare these hashes,
the public surface, API-digester tree and crosswalk, conflict ledger,
external-evidence dossier, SDK-input ledger, and TBD exports for semantic
reproducibility. Once a seed is published, its raw graph bytes and every
downstream digest remain immutable.

The v1 canonical public-surface occurrence is the minimum tuple of: ownership
tier, UTF-8 source-graph path, canonical full-symbol payload bytes, and symbol
array index. Tier zero is the requested module's `<Module>.symbols.json`; tier
one is another graph owned by the requested module; tier two is any remaining
graph. The manifest pins this as
`primary-module-graph_then-module-owned_then-utf8-path_then-canonical-payload_then-index-v1`.
This favors the primary module graph while remaining stable across extractor
output order. Conflicts remain visible in the immutable raw graphs and their
manifest count; canonicalization does not relabel them as agreement.

Schema v2 removes the redundant array-index tie breaker and pins
`primary-module-graph_then-module-owned_then-utf8-path_then-canonical-payload-v2`.
Selection is therefore explicitly independent of extractor array order; the
conflict ledger proves the selected payload.

`reference/immutable-files.sha256` covers `AGENTS.md`, `FANOUT_TASK.md`, the
acceptance script, and every other file below `reference/`; it excludes only
itself. The mutable guest manifest is intentionally excluded. This ledger is a
drift detector, not an adversarial trust boundary: central review must still
inspect the Git diff and verify that the seed commit is the expected parent.

The deliverable gate repeats every seed check and additionally rejects symlinks,
compiled products, build directories, incomplete precise-ID accounting, and
guest-manifest paths outside that framework. It requires:

```text
<Module>.swift
<slug>_guest_sources.txt
README.md
coverage.tsv
oracle-questions.tsv
tests/agent/<Module>LoadSmoke.swift        # schema v2
tests/agent/<Module>Runtime.swift          # schema v1 only
```

Schema-v2 frameworks that declare dependencies also require
`tests/agent/<Module>DependencyIdentity.swift`. It imports the target and every
real dependency and is consumed by the later clean EC2 integration build. The
isolated cloud gate does not compile this probe and must never be used to justify
module-local public lookalikes for dependency-owned types.

The manifest contains sorted, unique, repository-relative `.swift` paths below
`full/<slug>/`. Test sources and build directories are forbidden. The primary
`<Module>.swift` must be listed.

## Coverage is accounting, not a percentage slogan

`coverage.tsv` has this exact header:

```text
precise status evidence notes
```

The separators are tabs. Every precise identifier in the immutable symbol graph
appears exactly once, with no extras. Allowed statuses are `implemented`,
`declared`, `deferred`, `unavailable`, and `not-applicable`. Only `implemented`
and `declared` are nondeferred. Both require evidence. Every deferred,
unavailable, or not-applicable row requires an explanatory note.

The generator records the exact minimum nondeferred count in
`reference/framework.json`; the validator consumes that pinned count rather
than maintaining a second policy calculator. Campaign generation uses these v1
rules:

- `leaf-full` and `legacy-adapter`: ceiling of 80 percent of precise IDs.
- `medium-full`: ceiling of 50 percent.
- `large-partitioned`: the smaller of 150 and the larger of 50 or the ceiling
  of 10 percent.

`declared` means that a source-compatible declaration exists; it does not mean
the behavior works. In schema v2, each `declared` row must cite
`source:full/<slug>/<product-source>.swift#Symbol`, and that source must be in
the guest manifest. Each `implemented` row must cite
`test:full/<slug>/tests/agent/*Tests.swift#testFunction`; the function must exist
as a top-level synchronous no-argument function. The acceptance gate derives a
trusted runner from those anchors, compiles every test source, explicitly loads
the dylib, and invokes every distinct cited test exactly once. Coverage rows are
a review index, not a substitute for meaningful assertions.

## Oracle queue

`oracle-questions.tsv` has the exact tab-separated header:

```text
precise question risk reason
```

It contains at least one question. `precise` is either one exact graph ID or the
literal `module` for a cross-cutting behavior. Every field is nonempty. This is
where an agent turns missing Apple behavior into an explicit central-oracle
work queue instead of guessing.

The schema-v2 load-smoke source is canonical: `import <Module>`, one blank line,
then `let frameworkLoadSmokeMarker = "<MARKER>"`, with a final newline. The
marker recorded in `reference/framework.json` is formed by uppercasing the
module, replacing non-alphanumeric characters with underscores, and appending
`_AGENT_RUNTIME_OK`. The sealed gate—not agent-authored call text—generates the
runner from structured coverage. It compares stdout byte-for-byte, including
all trailing newlines. The metadata key remains `runtimeMarker` for schema-v1
compatibility, but in schema v2 the marker proves only that the framework and
cited focused tests compiled, loaded, and ran. It is not general behavioral
evidence.

## What central review still owns

After the cloud gate passes, central review must:

1. Confirm the immutable seed against the expected seed commit and inspect all
   mutable changes.
2. Run the acceptance script in a clean, pinned Linux toolchain with no stale
   `.build`, `build`, or `scratch` products.
3. Probe material questions on an Apple SDK/runtime and feed observed facts back
   into implementation and regression tests.
4. Review ABI, error, async/callback, concurrency, ownership, and fail-closed
   behavior instead of inferring them from declarations.
5. Integrate the reviewed sources into the shared package/sysroot, build the
   real `lib<Module>.dylib`, and test an unchanged application consumer.

Only those later steps can graduate a starting point into the platform.
