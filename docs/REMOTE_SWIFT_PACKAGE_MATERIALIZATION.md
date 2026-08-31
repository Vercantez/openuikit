# Exact remote Swift-package materialization

This layer turns the immutable remote-package pins in a frozen local package
graph into verified build inputs. It does not run dependency resolution, use a
branch or tag as authority, execute `Package.swift`, or write into the
application/vendor tree.

## Acquisition and cache identity

`remote_package_materializer.py` accepts only canonical HTTPS URLs in
production and exact 40- or 64-hex revision IDs already bound to a workspace
`Package.resolved`. The cache address is the SHA-256 of the canonical package
identity, exact URL, and exact revision. A checkout is created in a private
staging directory and published atomically under:

```text
objects/sha256/<first-two-hex>/<descriptor-sha256>/
  attestation.json
  repository/
```

Before publication and on every reuse, the verifier proves:

- `origin` is byte-for-byte the pinned URL;
- `HEAD^{commit}` is the pinned revision and `HEAD^{tree}` is recorded;
- the Git object format and strict object connectivity are valid;
- every tracked node is an ordinary `100644` or `100755` blob;
- every worktree file hashes to its tree blob and the worktree has no drift or
  untracked files;
- there are no symlinks or submodules;
- `Package.swift`, the complete tree listing, and the path inventory have
  stable hashes;
- the stored attestation equals a fresh reconstruction.

An existing invalid cache address is refused as stale/corrupt. It is never
deleted, overwritten, or silently recloned. This preserves evidence and avoids
turning cache corruption into an unreviewed network update.

```sh
python3 full/xcodeplan/remote_package_materializer.py materialize \
  /frozen/local-package-graph.json \
  --source-root /read/only/AppProject \
  --cache-root /outside/content-addressed-cache \
  --materializations /new/exact-materializations.json

python3 full/xcodeplan/remote_package_materializer.py verify \
  /frozen/local-package-graph.json \
  --source-root /read/only/AppProject \
  --cache-root /outside/content-addressed-cache \
  --materializations /new/exact-materializations.json
```

## Expanded build graph

The materialization set is cryptographically bound to the unresolved source
graph. Supplying it to `local_package_graph.py plan` causes the same static,
fail-closed manifest parser to load the verified remote repositories. Selected
remote library products become normal product-to-target edges. All reachable
local and remote targets then share one dependency-first order, with every
manifest and Swift source hashed. Unsupported reachable target kinds,
settings, local paths from remote packages, transitive packages without an
exact materialization, duplicate modules, cycles, source aliases, symlinks,
and non-Swift compiled sources still refuse.

```sh
python3 full/xcodeplan/local_package_graph.py plan app-inventory.json \
  --source-root /read/only/AppProject \
  --remote-materializations /new/exact-materializations.json \
  --remote-cache-root /outside/content-addressed-cache \
  --output /new/expanded-package-graph.json
```

`application_build_plan.py` accepts the same two remote arguments. The generic
application driver mounts the cache at `/remote-packages:ro`, reconstructs the
expanded graph on both host and guest, and compiles remote targets through the
same one-module/one-object-set boundary as local targets. Absolute guest paths
are emitted only by the fresh build contract; host cache paths never enter the
portable graph.

## Untouched Hackers proof (2026-08-31)

The exact workspace pins materialize as:

| Package | Commit | Tree | Manifest SHA-256 | Reachable sources |
| --- | --- | --- | --- | ---: |
| SwiftSoup 2.13.6 | `ead56133a693d0184d8c2db1a6d6394410cacfd6` | `32904e78f4f40216c76e7b0ab7e5de5b29dc81c1` | `f875a0f83881f3aa8502aa99edad350b7a54fcd4caa772040ba055e040db489c` | 60 |
| VariableBlur 1.3.0 | `1be3226d9ad7225b9ea6e46cf3c67b6861066f9c` | `bfeac0b86d93700ac4813fa42411025228ae9550` | `8b72d00d85a6f2bc9e0fa3318682fded4b04936f93d3373624a1c6f531881037` | 2 |

The expanded graph contains 6 local plus 2 remote packages, 10 local plus 2
remote library targets, 149 untouched Swift sources, 26 target dependency
edges, and no unresolved product. Its exact target order is:

```text
SwiftSoup, VariableBlur, Domain, Networking, Data, Shared, DesignSystem,
Authentication, Comments, Feed, WhatsNew, Settings
```

SwiftSoup's tracked `Sources/SwiftSoup.h` is correctly ignored for its regular
Swift target, matching SwiftPM/Xcode membership. VariableBlur's production
sources expose the next platform demands directly: SwiftUI/UIKit view
representability and visual-effect APIs, CoreImage built-in filters,
QuartzCore layer filters/KVC, and Objective-C runtime lookup. Its `#Preview`
code is guarded by `#if DEBUG` and is absent from the production compile.

The Docker-free host probe reaches target 0 (`SwiftSoup`) and then stops at a
toolchain serialization boundary: Apple Swift 6.2.1 cannot import the
platform package's `Foundation.swiftmodule`, which was produced by Swift
6.2.4. This is not a package-graph or source diagnostic. The next compilation
must use the same pinned Swift 6.2.4 Linux toolchain that built the platform
package; the production driver already provides that clean-container path.
