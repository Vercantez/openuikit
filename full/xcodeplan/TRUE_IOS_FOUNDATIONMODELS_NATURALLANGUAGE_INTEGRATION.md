# FoundationModels/NaturalLanguage true-platform integration lane

This lane starts at `e4f1ed0172f14cda203f173041ef478713d27992` and contains
the real FoundationModels publication, native macro plugin, NaturalLanguage
29-row differential, clean cross-import consumption, and portable Foundation
runtime-identity work. It deliberately omits these temporary workarounds:

- `d03d48d0ad67e7fb3cfef84666077d8a9021a81d` (host cleanup in place of guest
  `FileManager.removeItem`)
- `d05115d3fe2b25a2b51b82401d1f694caeac3f9b` (`Data` copies in place of guest
  `FileManager.copyItem`)

`TrueIOSSwiftUIDylibProbe.swift` therefore remains the real capability gate: it
removes a prior directory, creates it, copies two font files, and removes the
directory again through Foundation `FileManager`. The platform builder has no
host-side CoreText proof-directory cleanup fallback.

## Frozen-FTS replay boundary

Do not replay this command until `/root` supplies the frozen FTS commit as
`FTS_HEAD`. The only runtime-input substitution is the complete Machorun source
root passed as `MACHORUN`; do not copy a lone `libSystem.B.dylib`. A fresh
`build_full.sh` invocation must regenerate the renamed `libSystem.real.dylib`,
the syspatch/concpatch umbrella, and `.manifest` together before the true
platform is rebuilt.

Run the following single command group inside the existing network-disabled
ARM64 Linux builder with every absolute input path mounted. The replay worktree
must be a clean checkout of this integration-lane HEAD and must not exist before
that checkout is created. The new platform output is exactly
`/private/tmp/true-fm-nl-fts-platform-proof-20260901/true-ios-platform`.

```bash
set -euo pipefail
test "$(git -C /private/tmp/machorun-fts-20260901 rev-parse HEAD^{commit})" = "$FTS_HEAD"
test -z "$(git -C /private/tmp/machorun-fts-20260901 status --porcelain=v1 --untracked-files=all)"

replay=/private/tmp/true-fm-nl-fts-replay-20260901
inputs=/private/tmp/hackers-platform-cold-inputs-runtime-46d54dd-20260831
sdk=/private/tmp/true-ios-full-sdk-stager-v2-20260831
uikit=/private/tmp/uikit-48176-foundationmodels-proof

env W="$replay" UIKIT="$uikit" \
    MACHORUN=/private/tmp/machorun-fts-20260901 \
    SF="$inputs/swift-foundation" SC="$inputs/swift-collections" \
    BASE_RUNTIME_SOURCE="$inputs/mrroot" \
    FE_RUNTIME_SOURCE="$inputs/mrroot_fe" \
    SYS="$inputs/sysroot_fe4" \
    APPLE_SWIFT_USER_OVERLAYS="$sdk/apple-overlays" \
    TARGET=arm64-apple-ios18.0-simulator MINOS=18.0 \
    LINK_PLATFORM=ios-simulator LINK_SDK_VERSION=26.1 \
    bash "$replay/full/scripts/build_full.sh" \
&& env W="$replay" UIKIT="$uikit" \
    FULL="$replay/build/full" FULL_BUILD_PROJECT="$replay" \
    MRROOT_INPUT="$replay/scratch/mrroot_full" \
    SWIFT_FOUNDATION="$inputs/swift-foundation" \
    SWIFT_FOUNDATION_ICU="$inputs/swift-foundation-icu" \
    SWIFT_COLLECTIONS="$inputs/swift-collections" \
    OPENCOMBINE_SOURCE="$inputs/opencombine-core-durable-20260828-r2/source" \
    TRUE_IOS_SDK_STAGE="$sdk" SYS="$sdk/sdk" \
    APPLE_SWIFT_USER_OVERLAYS="$sdk/apple-overlays" \
    OUTPUT_ROOT=/private/tmp/true-fm-nl-fts-platform-proof-20260901/true-ios-platform \
    FOUNDATION_ICU_JOBS=8 \
    bash "$replay/full/xcodeplan/build_true_ios_platform_frameworks.sh"
```

The replay is accepted only if the package validator succeeds, the main probe
finishes its FileManager/CoreText traversal, the FoundationModels consumer and
29-row NaturalLanguage probe remain byte-identical to their frozen Apple
transcripts, and all runtime stderr attestations retain their exact contracts.
