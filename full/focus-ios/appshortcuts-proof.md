# Focus AppShortcuts module proof

This proof emits the real Focus `AppShortcuts` module and its three application
dependencies as four separate Swift modules. It is a pinned compatibility
milestone, not a general SwiftPM implementation, an Xcode build, a linked
application, or Linux execution.

## Proved graph

The accepted graph is fixed to Focus
`a2832521c1daa0c23419c73705ae043ed60c9791` and OpenUIKit
`0bba80a4138ece678844e2f55da16ffb7cbf70e9`:

```text
11 exact UIHelpers sources
    -> 1 exact UIComponents source
    -> 4-source DesignSystem production subset + staged Bundle.module accessor
    -> 5 exact AppShortcuts sources
```

Each node emits its own module with `-parse-as-library -wmo`, Swift language
mode 5, and target `arm64-apple-macos13.0`. A successful proof requires all four
`.swiftmodule` files and their compiler sidecars to be nonempty and every
module diagnostic log to contain zero bytes.

`DesignSystem` contains seven committed Swift files. The proof does not call
that the four-source compilation an unmodified target: it is the reviewed
production subset already exercised by the package-resource proof. The three
SwiftUI-only files below `DesignSystem/Preview Files` are explicit policy
exclusions. Their individual hashes and aggregate digest are pinned alongside
the four compiled sources, so an exclusion cannot silently appear, disappear,
or change.

## No source adaptation

All 21 compiled Focus sources are consumed byte-for-byte from the pinned
commit. There is no generated UIComponents source, source overlay, patched
Focus file, or adaptation configuration in the policy. OpenUIKit `0bba80a`
models UIKit's framework initializer inheritance, so the unchanged
`ShortcutView.swift` can construct `AsyncImageView()` even though Focus's
subclass declares `override init(frame:)`.

The proof asserts both sides of that claim: the policy schema rejects an
`adaptation` entry, and the output must not contain the retired `generated/`
adaptation tree. The sole generated Swift input is SwiftPM's compile-only
`DesignSystem/Bundle.module` accessor described below.

## Resource boundary

The driver reuses `package_resources.py` to stage the raw Focus catalogs and
the fail-closed, compile-only `DesignSystem/Bundle.module` accessor. The
resource policy and resource tool bytes are themselves pinned and attested
before and after compilation, and the staged tree/audit are verified after the
compiler returns.

The resource slice records OpenUIKit `81e1e05` because that was the historical
commit used to prove its four-source DesignSystem surface. That value is not
the OpenUIKit input for this proof. The AppShortcuts policy independently pins
`0bba80a`, which supplies the later pointer APIs and framework-correct view
initializer behavior consumed by `ShortcutView`.

Raw `.xcassets` staging still does not run `actool`, decode PDF/SVG assets, or
provide runtime `Bundle.module` discovery.

## Fail-closed contract

Before compilation the driver requires:

- exact policy shape and semantic equality with the reviewed built-in policy;
- exact Focus and OpenUIKit commits, repository locations, and clean worktrees;
- no tracked modifications, untracked files, symlinked source components, or
  consumed worktree bytes that differ from their committed blobs;
- exact `Package.swift`, source inventories, per-file sizes/hashes, aggregate
  source digests, preview exclusions, absence of source adaptation, resource
  policy, and resource tool; and
- a new output path outside both source repositories.

Git subprocesses discard ambient `GIT_*` redirection, global configuration,
replace objects, fsmonitor, and hooks. After the four compilers return, the
driver verifies that no adaptation output exists, then verifies the resource
stage/audit/accessor, local resource policy/tool, Focus capture, and OpenUIKit
capture again. Any drift voids the proof instead of leaving a green result
attached to mixed inputs. Existing output is refused without deletion.

Run it from the repository root with clean, pinned input repositories:

```bash
python3 -B full/focus-ios/appshortcuts_proof.py prove \
  /path/to/clean/focus-repository/focus-ios \
  /path/to/clean/openuikit \
  full/focus-ios/appshortcuts-proof.json \
  /new/path/appshortcuts-proof

python3 -B full/focus-ios/test_appshortcuts_proof.py -v
```

The full positive integration test is macOS-only because the proof currently
uses the Apple Swift toolchain's macOS SDK modules, including Foundation and
Combine. The output is an arm64 Mach-O-targeted module graph; it is not a linked
guest and has not been executed by `machorun` on Linux. Moving this exact graph
to Linux still requires the project’s portable Foundation/Combine substrate,
link closure, and a behavioral runner.
