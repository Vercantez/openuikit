# Local Swift-package application graph

This slice moves portable applications past the first `no such module` wall
without editing application or package source. It statically freezes the
reachable local SwiftPM graph selected by an Xcode application and inserts one
real compiler/link boundary per library target.

## Trust boundary

`project_inventory.py` now records every `XCLocalSwiftPackageReference`, its
canonical source-root-relative path, and the SHA-256 of its `Package.swift`.
It preserves an explicit product-to-package reference when Xcode publishes
one. Xcode sometimes omits that reference for a uniquely named local product;
in that case the package planner requires the product name to occur in exactly
one inventoried manifest. It never picks the first match.

`local_package_graph.py` does not execute a manifest, invoke SwiftPM, contact a
registry, or resolve a URL. Its static parser accepts ordinary `.library`
products, `.target` library targets, local `.package(path:)` dependencies,
immutable workspace pins, and the three dependency forms used by normal
library targets. It also preserves the static per-target settings used by
modern Swift packages: `.swiftLanguageMode(.v4/.v4_2/.v5/.v6)` and
`.defaultIsolation(MainActor.self)`. They become an exact, allowlisted
option/value vector in each target's build contract; every other reachable
setting or conditional form still refuses. Unsupported reachable target kinds,
conditions, dynamic expressions, mixed-language sources, or product types
refuse. Remote dependency requirements accept static semantic-version strings
and the equivalent `Version(major, minor, patch)` constructor. The legacy
unconditional `.productItem(..., condition: nil)` spelling is normalized to
the same product edge as `.product(...)`; an actual condition still refuses.
Unreachable test targets may remain declared because they are not part of the
selected application build.

Every package root, target root, source, manifest, and workspace resolution
file must be a regular, non-symlink object canonically contained by the
application source root. The planner rejects missing paths, escapes, symlinks,
portable case/normalization aliases, hard-link source aliases, duplicate
package/product/target/module/source identities, unresolved edges, and cycles.

## Frozen graph

The canonical `portable-local-swift-package-graph` contains:

- selected Xcode product to local target edges;
- every reachable local package and manifest hash;
- every reachable library product to target edge;
- a dependency-first topological target list;
- each target-to-target and target-to-external-product edge;
- every ordered Swift source with size and SHA-256;
- the workspace `Package.resolved` hash and complete pin set;
- each used remote declaration, exact pin, consumer, and an explicit null
  materialization.

The graph may be successfully frozen while marked `blocked`. That distinction
is important: a pinned URL/revision proves identity, not that source bytes are
present. `require-buildable` reports all missing materializations and exits
nonzero. It never manufactures a module or treats a product name as a system
framework.

```sh
python3 full/xcodeplan/local_package_graph.py plan app-inventory.json \
  --source-root /read/only/AppProject --output /new/local-package-graph.json
python3 full/xcodeplan/local_package_graph.py verify \
  /new/local-package-graph.json --source-root /read/only/AppProject
python3 full/xcodeplan/local_package_graph.py require-buildable \
  /new/local-package-graph.json --source-root /read/only/AppProject
```

`application_build_plan.py` embeds the same graph and publishes separately
hashed `local-package-graph.json` and `local-package-targets.nul` inputs. Its
normal verifier reconstructs the graph from the untouched tree, so source,
manifest, dependency, pin, product selection, or ordering drift invalidates
the entire application plan.

## Compiler and linker boundary

For a graph with all source materialized,
`build_portable_application_guest.sh` consumes targets in the frozen
dependency-first order. Each target gets a distinct `-module-name`,
`-emit-module-path`, output-file map, and exhaustive object directory. Later
targets and the application receive only the frozen package module directory
as an additional import path. Frozen Swift language-mode and default-isolation
arguments are applied target by target, matching their manifests instead of
silently inheriting the application target's defaults. Every package object is
checked as ARM64 Mach-O, recorded in the link ledger, and linked exactly once
beside the application objects. The build contract and output maps are
reconstructed after compilation. Both host and guest rerun the
remote-materialization gate.

## Untouched Hackers proof (2026-08-31)

The read-only Hackers checkout at commit
`83016de` selects eight Xcode products. The graph expands those products into:

- 6 local packages;
- 10 local library products and 10 reachable production targets;
- 87 untouched Swift sources;
- 26 target dependency edges;
- 2 workspace resolution pins.

The exact target order is `Domain`, `Networking`, `Data`, `Shared`,
`DesignSystem`, `Authentication`, `Comments`, `Feed`, `WhatsNew`, `Settings`.
The previous application diagnostic, `no such module 'Data'`, is therefore
fully explained and planned rather than bypassed. Compilation now stops at the
next honest input boundary:

```text
remote package materialization required before compilation: swiftsoup@ead56133a693d0184d8c2db1a6d6394410cacfd6 (https://github.com/scinfu/SwiftSoup.git); variableblur@1be3226d9ad7225b9ea6e46cf3c67b6861066f9c (https://github.com/nikstar/VariableBlur)
```

SwiftSoup is pinned to version `2.13.6`; VariableBlur is pinned to `1.3.0`.
The follow-on exact materialization and expanded graph are described in
[`REMOTE_SWIFT_PACKAGE_MATERIALIZATION.md`](REMOTE_SWIFT_PACKAGE_MATERIALIZATION.md).
No application or vendor source was changed.
