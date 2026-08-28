# OpenCombine core Mach-O oracle

This directory turns one measured milestone into a repeatable, fail-closed
build: the 103 Swift files in OpenCombine's core target compile as an arm64
Darwin module/object, strict-link into `libOpenCombine.dylib`, load through a
`Combine` re-export shim, and execute under `machorun` on Linux.

It does **not** vendor OpenCombine's upstream source. The host entry point
clones a disposable checkout, detaches it at commit
`1c6f02c7ed8140c0ba7a783aaddb6e0685a0037b`, and attests the checkout before
and after compilation. Generated sources and artifacts live only under the
ignored `scratch/` tree and a new `/tmp/opencombine-core.*` container subject.

## What is proved

The build and runtime controls establish all of these together:

- the exact `Sources/OpenCombine` compiler subject is 103 tracked `.swift`
  files, with digest
  `d26c121f2ad571a5c6dce050deccfb147e37d80cbf0e482a48328cd64e1650f5`;
- the source list is NUL-delimited, and the digest is SHA-256 over repeated
  `relative path + NUL + file bytes + NUL` records;
- the four additional checkout inputs are inventoried and hashed too: the C++
  helper, `COpenCombineHelpers.h`, `module.modulemap`, and the exact
  `OpenCombineDispatch/DispatchQueue+Scheduler.swift` boundary probe. The
  before/after attestation brackets every compiler invocation, and refuses
  dirty, untracked, symlinked, added, or removed files in either input root;
- every explicitly configured non-checkout compiler search subject is closed
  as a complete tree. The
  SDK is 95 directories, 1,559 files, and 3 symlinks with digest
  `dfbdb6b65f6dcf5e7b72857dcf47ec43c0fb26f86aeae06189c803b61c1799a8`;
  the six-file `Swift.swiftmodule` and `_Concurrency.swiftmodule` bundles have
  digests `5557fdbdce380ef69b427c77262c3da9fcd40d02ff7549fa7fde6fe2fdf9ee49`
  and `18202e5d7dbbfe85fd12f02049a23dda6bef1a3e14c8347a8ffb769c86e109c1`.
  These are NUL-safe digests over sorted `kind + NUL + relative path + NUL +
  value + NUL` records, where value is a file hash, symlink target, or empty
  directory marker.
  The build attests the originals, copies only those exact trees into isolated
  roots, attests the copies, uses only the copies for compilation, and brackets
  both sides afterward. A pre-product `canImport` probe refuses a hidden
  `Combine` or `OpenCombine` module;
- the upstream helper starts at SHA-256
  `73dbadeff3f6cebb9f5c57e09380e3166b65e68f0b0427d97d6a8ffdce693693`,
  the exact recorded patch is
  `875cd931e95c5442775e1042a412517ab7475be0489b1a81f824a54f6872c79b`,
  and the patched source is
  `d9fbefcdba66d892d9064c46b21b6084af217ddec1d604bcaf27b160de66083b`;
- the unmodified helper fails a strict link on all four imported
  `std::recursive_mutex` operations; the patch uses an explicitly recursive
  pthread mutex and removes the unnecessary `std::system_error` dependency;
- `libOpenCombine.dylib`, `libCombine.dylib`, and all guest executables are
  arm64 Mach-O artifacts with `MH_NOUNDEFS` and exact dependency/load-command
  records. The parser consumes `--all-headers` and enforces, in order, every
  dylib command's kind, install-name spelling, compatibility version, and
  current version. This distinguishes ordinary, weak, re-export, upward, and
  lazy loads and covers frameworks, `@rpath`, and `@loader_path` spellings;
- the linked core has exactly 14 regular plus 14 lazy `_Concurrency` binds,
  with no overlap (28 unique), and exactly two weak binds. Every one is checked
  against symbols that `llvm-nm --defined-only` finds in the actual staged
  provider. The patched helper's 21 imports are likewise resolved only against
  defined symbols, with symbol-to-dylib provider evidence retained;
- the four dylibs used from both link and guest-runtime locations (`libc++abi`,
  `libobjc`, `libswiftCore`, and `libswiftcompat`) must agree byte-for-byte
  before the link and after the guest controls;
- guest roots, compiler subjects, build artifacts, the loader, and the existing
  `libdispatch.dylib` are hashed across the operation so a run cannot mutate
  its own evidence unnoticed.

The runtime oracle exercises the compatibility spelling real iOS source uses:

```swift
import Combine
@Published var value: Int
counter.$value.sink { ... }
```

Four controls must discriminate:

| control | required result | purpose |
|---|---:|---|
| positive | exit 0, `ORACLE_OK …` | `@Published`, projected publisher, and `sink` work |
| mutated | exit 133, `ORACLE_FAIL …` | the positive assertion can detect changed delivery semantics |
| missing dylib | exit 72, exact loader diagnostic | the result depends on the newly staged OpenCombine dylib |
| reentrant | exit 0, `REENTRANT_OK …` | the recursive pthread lock path is exercised rather than merely linked |

Each discriminator is an exact full line, must occur exactly once on its
policy-selected stdout or stderr stream, and must be absent from the other
stream.

These controls prove this bounded core behavior. They do not claim complete
Combine API compatibility, `OpenCombineFoundation`, or application-level
compatibility.

## Run it

The fast policy tests need no container build:

```sh
bash full/oracle-opencombine/test_lightweight.sh
```

The current suite has 45 tests. They mutate pins, core and auxiliary compiler
inputs, isolated module-tree contents/inventory/symlinks, source denominators,
asset and policy scopes, link/runtime hash agreements, Mach-O load kinds and
versions (including weak and re-export mutations), oracle expectations,
standalone and directory-shaped Dispatch module inventory, and output path
guards. Every mutation must be refused.

The real build uses the existing pinned `fm-build` image and requires three
already-built inputs inside that container plus an exact 17-file host runtime
root:

```sh
RUNTIME_ROOT=/absolute/path/to/the/policy-matching/base-root \
MACHORUN_CONTAINER=/tmp/codex-opencombine.HqQN6k/work/machorun \
CONCURRENCY_MODULE_CONTAINER=/tmp/codex-opencombine.HqQN6k/out \
CONTAINER_OUT=/tmp/opencombine-core.my-new-run \
bash full/oracle-opencombine/build_and_run.sh \
  "$PWD/scratch/opencombine-core-my-new-run"
```

`SWIFT_MODULE_CONTAINER` defaults to `/work/swiftmodule`; its configured value
is recorded in `RUN.txt` alongside the `_Concurrency` root.
`OPENCOMBINE_CLONE_SOURCE` may name a local Git mirror when network cloning is
undesirable; `git clone --no-checkout --no-local` is still used and the same
commit/content/cleanliness attestation applies. Both output paths must be new.
A failed run is retained for inspection and must not be reused.

`policy.json` pins the image, tool executables and versions, complete Swift,
`_Concurrency`, and SDK trees, link inputs, loader, source and patch identities,
`libdispatch`, and every base-runtime file. A current `scratch/mrroot_full`
that has been rebuilt since the measurement is expected to be refused; do not
silently repin it. Rebuilding or changing any input is a new reviewed
measurement.

### Prebuilt provenance and repeatability limit

This directory does not build or recover all of its prerequisites. In the
recorded run, the source-built `_Concurrency` module and `machorun` loader live
under the transient `/tmp/codex-opencombine.HqQN6k` probe, the source-built
`Swift.swiftmodule` lives under `/work/swiftmodule`, the SDK and Dispatch/link
inputs live elsewhere under `/work`, and the exact runtime root is supplied
from outside this directory. Their complete relevant bytes, tool executables,
and container image are pinned and rechecked, but their source provenance and
reconstruction recipes are not made self-contained here. Deleting those
prebuilt inputs makes this harness correctly refuse until the same reviewed
subjects are reconstructed or a new measurement is made.

For that reason this is a **repeatable build in the pinned environment**, not
a hermetic or byte-reproducible build from source. Swift records the absolute
checkout path in part of the core output. Absolute-path-bearing source-list and
JSON attestations also truthfully record each fresh checkout root. Those files
are not claimed to be byte identities across differently named subjects. The
semantic identities are the relative-path source digest, complete input-tree
manifests, normalized load records, bind/provider audits, and runtime outcomes.
No prefix mapping is claimed.

This was measured, not inferred: final fresh subjects `...-q2` and `...-r2`
both passed all four controls and every semantic audit. Seven of ten exported
artifacts were byte-identical. `OpenCombine.o`, `OpenCombine.swiftmodule`, and
`libOpenCombine.dylib` differed because they bear the subject path (the dylib
hashes were respectively `4fdf47c14ca37662ed7063c65d14ff5117acd3a573811e7b5ad9b69d31033f9b`
and `69a28dbbe26dd075d903321f521509041c9c8bb5419f2b0480db33944f1c2c61`).
The complete SDK/module manifests, normalized dependency records, all
regular/lazy/weak bind sets, provider results, normalized Dispatch failure,
and policy-selected discriminator lines and exits were identical. Full
path-bearing mutated and missing-dylib stderr streams are not claimed as byte
identities across differently named subjects.

Successful host output contains an exact, manifest-verified `export/` tree:

- `export/RESULT.txt`: the bounded result and artifact hashes;
- `export/artifacts/`: modules, objects/dylibs, and the three guest executables;
- `export/audit/`: NUL source lists, per-source hashes, dependency and undefined
  symbol reports, provider checks, staged-root manifests, and subject hashes;
- `export/logs/`: compiler/linker output and the expected Dispatch failure;
- `export/results/`: stdout, stderr, and exit status for every runtime control;
- `host-audit/container-export.manifest.nul`: the in-container SHA/path manifest
  used to reject truncated, expanded, or changed host copies.

## Explicit OpenCombineDispatch boundary

`/work/lib/libdispatch.dylib` exists and is preserved byte-for-byte, and a
`libswiftDispatch.tbd` link stub exists. The inventory detects both directory
bundles and standalone `Dispatch.swiftmodule` files and requires exactly one
directory bundle at the pinned path, with no unreviewed nested directories.
Its eight pinned files are four
`arm64e`/`x86_64` interfaces and four matching documentation files for macOS or
Mac Catalyst. It contains zero
`arm64-apple-macos.swiftmodule` or `arm64-apple-macos.swiftinterface` files, and
the container contains zero actual `libswiftDispatch.dylib` files.

The boundary experiment copies that exact bundle to its own attested root and
adds the copied bundle's parent to `-I`, along with the built `Combine` shim,
`OpenCombine`, and the exact helper module. This causally selects the pinned
`arm64e-apple-macos.swiftinterface`; it then fails exactly because the interface
imports the absent `_StringProcessing` module and because its Apple Swift 6.2.1
SDK/compiler identity does not match the pinned Swift 6.2.4 compiler. The
normalized error headlines and exit 1 are policy discriminators, not an
inference from filenames.

The build records that failure as the current boundary and refuses if the
boundary changes. `OpenCombineDispatch` is not built or claimed here. Advancing
it requires a target-correct, compiler-compatible Dispatch Swift module, its
explicit module dependencies (beginning with `_StringProcessing`), and its
runtime dylib, then a new strict-link and guest runtime oracle rather than
relaxing this policy.
