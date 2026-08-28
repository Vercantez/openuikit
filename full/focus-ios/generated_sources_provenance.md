# Focus generated Swift source provenance

This record covers Focus commit
`a2832521c1daa0c23419c73705ae043ed60c9791` (committer timestamp
`2024-03-05T08:22:23Z`). It documents the two reproducible open-source
generators and the one unresolved proprietary generator. The executable policy
and byte oracles live in `generated_sources.py`.

This is not a claim that the complete generated-source set is ready. The
localized Intents source remains unresolved, and `generated_sources.py
readiness` intentionally exits nonzero until that changes.

## Xcode build graph

`Blockzilla.xcodeproj/project.pbxproj` has these generated main-target inputs:

- The Glean shell phase reads `Blockzilla/metrics.yaml`, declares
  `Blockzilla/Generated/Metrics.swift`, and runs
  `bash $PWD/bin/sdk_generator.sh`.
- The Nimbus shell phase reads `nimbus.fml.yaml`, declares
  `$(SRCROOT)/$(PROJECT)/Generated/AppNimbus.swift`, and runs
  `bash $SOURCE_ROOT/bin/nimbus-fml.sh --verbose`.
- The Sources phase includes localized
  `Blockzilla/Base.lproj/Intents.intentdefinition`; Xcode invokes
  `intentbuilderc` and adds its derived Swift source to the target.

The exact project, scripts, manifests, package resolution, and intent definition
are SHA-256-attested by the tool before generation. The relevant Focus and
generator repositories are attested again after subprocess execution and before
accepted bytes are written, so persistent concurrent or tool-induced mutations
fail closed. Git commands discard ambient `GIT_*` repository, index, object,
worktree, and configuration redirects; user and system Git configuration and
replacement objects are disabled for those identity/cleanliness checks.

## `Metrics.swift` / Glean

Focus's script specified `glean_parser~=13.0`. Version 13.0.0 was published on
2024-02-26, before the pinned Focus commit; 13.0.1 was published on 2024-03-27,
after it. Therefore 13.0.0 is the historical resolution, while running the
script now would silently select 13.0.1.

- Generator: `glean-parser` 13.0.0, MPL-2.0.
- PyPI wheel: `glean_parser-13.0.0-py3-none-any.whl`.
- Wheel SHA-256:
  `1c1e9d33fae3b804fc066ae6b2ae7ae8f4148cac1e5b248f2c1e2bfc2e3ae520`.
- Hash-locked CPython 3.11 dependency snapshot:
  `glean_dependencies.lock`, SHA-256
  `ce1581055ebfb3d91718484f5b5c222c6dd4b8b0cffba2a50d661e09dcc6ae75`.
- Input SHA-256:
  `Blockzilla/metrics.yaml = 47836b573e6b3aa9144786b85485cc75ff4520ce56ffdf410e427c3888f38cc8`.
- Accepted output SHA-256:
  `aea69809e642b25bebb82f392d82d8d6efca2227fc585cff8bf983e0fd3bea17`
  (880 lines, 30,935 bytes).

Two clock controls are required. `build_date=0` normalizes generated `BuildInfo`
to the Unix epoch, while glean-parser separately calls both
`datetime.datetime.utcnow()` and `datetime.datetime.now()` when validating and
applying metric expirations. The tool freezes both parser clock paths to
2024-03-05, the pinned commit's UTC date. This preserves metrics with July 2024
expirations as enabled while correctly disabling the metrics whose expiration
is exactly 2024-03-05. Generating in 2026 without that clock control changes 16
`disabled` values despite using `build_date=0`.

Reproduction (the output and wheel paths must not already exist):

```sh
mkdir /tmp/focus-glean-wheelhouse
/path/to/cpython3.11 -m pip download \
  --no-deps --only-binary=:all: --require-hashes \
  --dest /tmp/focus-glean-wheelhouse \
  -r full/focus-ios/glean_dependencies.lock
/path/to/cpython3.11 -m pip download --no-deps --only-binary=:all: \
  --dest /tmp/focus-glean-wheelhouse 'glean-parser==13.0.0'
python3 full/focus-ios/generated_sources.py glean \
  /path/to/pinned/focus-ios \
  /path/to/cpython3.11 \
  /tmp/focus-glean-wheelhouse \
  /tmp/Metrics.swift
```

The tool checks the lock and generator-wheel hashes before creating a fresh
virtual environment. It installs dependencies offline with pip's isolated,
no-index, no-deps, require-hashes mode, then extracts the generator from the
attested wheel and places it first on the isolated interpreter's import path.
Ambient `PIP_*`, `PYTHONHOME`, and `PYTHONPATH` settings are removed. Generation
is accepted only if the sole output is `Metrics.swift` with the reviewed hash
above.

The dependency lock is a reproducibility envelope created for this audit, not
a claim about the transitive versions present on a particular developer's
machine in 2024. Focus pinned only the broad parser range and reused a local
virtualenv; it did not record a transitive lock. The historically relevant
generator source is the attested 13.0.0 wheel, while the reviewed final-byte
oracle proves that the locked envelope renders the accepted Swift.

The same bytes were produced with CPython 3.11 on macOS ARM64, Linux ARM64,
and Linux x86_64 (the latter under Docker's AMD64 emulation).
The exact output also passed an iOS Swift typecheck against Glean 58.0.0's
published `Glean.xcframework` (package revision
`724814f167bf42e33fafa856f7d19fc752beca2c`, archive/checksum
`a6de1ce9d1f3cdb8bcd3b1ca0947fd106b4f7e11649fb04fc9df4c6b8b6ef20a`).
That binary has device and simulator slices only, not a Linux slice.

The generated API uses Glean `BuildInfo`, `CommonMetricData`, boolean, counter,
event, labeled, quantity, string, and UUID metrics plus Foundation date/time
types. Existing census-only Glean declarations with the same generated names
must be separated into runtime compatibility code before this source is added.
`AppDelegate.setupTelemetry` initializes Glean and records metrics during
launch, so a Linux port may choose a truthful no-op transport but cannot simply
omit this generated API.

## `AppNimbus.swift` / Nimbus FML

Focus pins `rust-components-swift` version `125.0.20240302000149`, commit/tag
`c110d9f8204568ec3950c233cf48b8b40136d806`. Its binary URLs and the matching
Taskcluster `nimbus-fml` archive were returning 404 when audited on 2026-08-28,
so the binary cannot serve as a durable generator input.

The open-source recovery pins Application Services commit
`219ca78e2ce82d48cd5eed8b198b112b750c0925`, the latest commit found before that
nightly. That selection is a bounded timestamp inference, not a recovered CI
revision. All 19 Swift files under the nightly package's
`swift-source/focus/Nimbus` are byte-identical to
`components/nimbus/ios/Nimbus` at the chosen commit, which establishes source
compatibility but cannot select one historical commit. In fact, the same
Nimbus runtime tree (`9ca840f31a3ff2dd84b0c79f0543f3b82d9fcf5e`) and generator
tree (`580560dd62de048487d817992f9ccdc4b35f47a4`) occur at Application
Services commits `f538529f15db54c179d43d4d3b69c1978d968a60`,
`84c511ee4c9b9107468f970c567be1daaa145619`,
`78f2d581f6614100b8b3eeb33e9cbc8ab627d9a3`, and the chosen commit. The
tool attests every package file hash, both tree identities, and performs the
19-file comparison before and after it builds and runs the generator.

- Generator source candidate: Application Services, MPL-2.0.
- Reproducibly pinned compatible Application Services commit:
  `219ca78e2ce82d48cd5eed8b198b112b750c0925`.
- Exact Glean submodule gitlink:
  `e8e842169a9a6e07ed21156e6204e2cb01a38139`.
- Rust compiler: `rustc 1.75.0 (82e1608df 2023-12-21)`.
- Cargo: `cargo 1.75.0 (1d8b05cdd 2023-11-20)`.
- Nimbus runtime tree:
  `9ca840f31a3ff2dd84b0c79f0543f3b82d9fcf5e`.
- Nimbus generator tree:
  `580560dd62de048487d817992f9ccdc4b35f47a4`.
- Repository Cargo configuration SHA-256:
  `.cargo/config = c57c5a46658916dc9a7c425d5b63a5e2fc74f8072f662fe7f1b9ab838501dd0b`.
- `Cargo.lock` SHA-256:
  `ab861a7124b9f306e665b1973ca0b97a8362f1296423229bd8ab04afdb6f1cfc`.
- `rust-toolchain.toml` SHA-256:
  `c80b7dc231ed9e9fa38aa8b749a6ebb9b4864319b9f9719bb2e1f37485936f3e`.
- Developer output SHA-256:
  `62c7618de24c2e7273c8e48f54a05988fddff719d92400e262ed8770058f4bec`.
- Beta/release output SHA-256:
  `9b25e56225081df34fbd982fde68e1e4d2904a7812899704bc38d51882074cdb`.

Reproduction:

```sh
git clone https://github.com/mozilla/rust-components-swift.git \
  /tmp/focus-rust-components
git -C /tmp/focus-rust-components checkout \
  c110d9f8204568ec3950c233cf48b8b40136d806

git clone https://github.com/mozilla/application-services.git \
  /tmp/focus-appservices
git -C /tmp/focus-appservices checkout \
  219ca78e2ce82d48cd5eed8b198b112b750c0925
git -C /tmp/focus-appservices submodule update --init \
  components/external/glean

rustup toolchain install 1.75.0
python3 full/focus-ios/generated_sources.py nimbus \
  /path/to/pinned/focus-ios \
  /tmp/focus-rust-components \
  /tmp/focus-appservices \
  /tmp/focus-nimbus-cargo-target \
  developer \
  /tmp/AppNimbus.swift
```

The Cargo target path must be absent. The tool creates it and a nested
`CARGO_HOME` exclusively with private permissions and refuses shared or
preseeded target/cache directories. It removes ambient Cargo, Rust build,
compiler/linker, Git configuration, Python-path, sccache/ccache, pkg-config,
and vcpkg overrides; rejects `.cargo/config` or `.cargo/config.toml` in parent
directories; and attests the repository's own `.cargo/config`. It preserves
`PATH`, `HOME`, network proxy/certificate settings, and the host toolchain/SDK,
which remain declared host inputs rather than hash-attested artifacts.

Dependency acquisition has one explicit, intentional Cargo fetch boundary:
`cargo +1.75.0 fetch --locked` may contact crates.io and GitHub, but writes only
to the fresh private Cargo home. The attested lock contains 475 checksum-pinned
registry packages and one Git dependency pinned to ohttp revision
`fc3f4c787d1f6a6a87bf5194f7152cc906b02973`. After fetch, compilation uses
`cargo +1.75.0 build --release --frozen`; `CARGO_NET_OFFLINE=true` is also set,
so Cargo cannot resolve or download anything during compilation. These Cargo
controls are not an OS-level network sandbox: dependency build scripts, proc
macros, and the resulting `nimbus-fml` process are not technically prevented
from opening sockets. This audit did not monitor or deny such access; the final
Swift bytes are hash-gated, but a network-hermetic claim would require a
platform sandbox. A fully preloaded offline reproduction would additionally
require an attested Cargo vendor/cache, which this repository does not claim to
provide.

The tool then validates the manifest from the pinned Focus working directory,
while placing its cache and all generated bytes outside every pinned checkout.
It sets `MOZ_APPSERVICES_MODULE=FocusAppServices`, re-attests all three
repositories and the 19-file source mapping after compilation and generation,
and accepts exactly one output with the channel-specific reviewed hash. A fresh
private-cache end-to-end run completed on macOS ARM64 in about 27 seconds on the
audited machine; macOS ARM64 and Linux ARM64 builds produced byte-identical
Swift. The only channel semantic difference is `showNewOnboarding`: true for
developer, false for beta/release.

The pinned `bin/nimbus-fml-configuration.sh` maps Xcode configurations exactly
as follows: `FocusDebug` and `KlarDebug` use `developer`; `FocusEnterprise` and
`KlarEnterprise` use `beta`; `Focus`, `FocusRelease`, `Klar`, and `KlarRelease`
use `release`; any other configuration name is passed through as the channel.
The reproduction CLI makes this choice explicit instead of inferring an Xcode
configuration.

The accepted generated output passed an iOS Swift typecheck with the pinned
FocusAppServices FML/UniFFI sources and headers. It imports Foundation and,
conditionally, FocusAppServices; its surface uses `FeatureManifestInterface`,
`FeaturesInterface`, `FeatureHolder`, `FeatureHolderAny`, `FMLObjectInterface`,
`FMLFeatureInterface`, `Variables`, and `NilVariables`. The existing census
stub defines `AppNimbus` itself and must be reduced to a compatible runtime
surface before integrating this generated source.
`NimbusWrapper` constructs its launch-time feature manifest from
`AppNimbus.shared`, and `TipViewController` reads a generated feature directly;
this source is both a compile dependency and part of launch behavior.

### Nimbus provenance limit

Focus intentionally ignored `bin/nimbus-fml.sh`; bootstrap fetched that
launcher from the moving Application Services `main` branch. Consequently the
exact launcher bytes used by an arbitrary historical developer build cannot be
proven. The recovery does not execute or claim those bytes. It bypasses the
launcher and directly builds a compatible, reproducibly pinned open generator
source candidate, then gates the final bytes. Neither the shared source-tree
identity nor the package match can prove which Application Services commit
backed the nightly. The exact historical launcher, generator binary, and CI
revision remain unavailable.

## `EraseIntent.swift` / Intents

`Blockzilla/Base.lproj/Intents.intentdefinition` records Xcode tools version
14.2 and build 14C18. It defines one custom `Erase` intent with success and
failure responses. Apple's `intentbuilderc` is a Mach-O executable tied to
private Xcode frameworks and has no Linux build; its license is proprietary.

Current Xcode 26.1 can deterministically render the schema with:

```sh
xcrun intentbuilderc generate \
  -input "/path/to/pinned/focus-ios/Blockzilla/Base.lproj/Intents.intentdefinition" \
  -output /tmp/focus-intents \
  -language Swift -swiftVersion 5.0 -visibility public \
  -moduleName Blockzilla
```

The inspected Xcode build was 17B55; its ARM64 `intentbuilderc` SHA-256 was
`5bac81fd48923d96e0a709cbf87959d781e70f7229ee9a82cffe8c1b60c75a5a`.

Repeated current-Xcode output was 100 lines / 4,868 bytes, SHA-256
`4b8206a1e37f0bb6c13cb8ef1fb2b9fd0b0fbb360c05c73b7762a1d1eebbabb4`,
and typechecked for iOS. It conditionally imports Intents and defines
`EraseIntent`, `EraseIntentHandling`, `EraseIntentResponseCode`, and
`EraseIntentResponse`. This is a useful semantic reference, not an accepted
Xcode 14.2 byte oracle.

Without these derived declarations the pinned main target reports six primary
diagnostics across `BrowserViewController`, `SiriShortcuts`, and `AppDelegate`.
They are therefore a compile-time main-target dependency even though Siri is
not needed to draw the first application frame.

The remaining defensible options are to obtain and attest the Xcode 14.2
rendering, or implement an open schema translator plus an Intents-compatible
Linux runtime and verify its semantics against Apple-generated references.
Inventing handwritten declarations would erase the provenance boundary, so
the current tooling refuses to report full readiness.
