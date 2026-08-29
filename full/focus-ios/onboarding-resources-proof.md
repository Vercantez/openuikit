# Focus Onboarding and Widget resource-normalization proof

This proof turns the pinned target-local Focus asset catalogs into an explicit,
portable resource layout. It attests source bytes, copies the supported raw
color catalogs, rasterizes every PDF appearance at 1x/2x/3x, creates original
geometric replacements for the four used system-symbol names, and writes a
lookup index plus loose PNG aliases usable by OpenUIKit's current named-image
subset.

It does **not** run `actool`, emit or decode `Assets.car`, establish equivalence
to Apple's asset compiler, link or run a guest, or prove that Foundation,
UIKit, or SwiftUI discovers these bundles at runtime.

## Pinned subject

The source is Focus commit
`a2832521c1daa0c23419c73705ae043ed60c9791`. The pinned `Package.swift` does
not declare either target's catalogs as SwiftPM resources, so the policy calls
them `raw-unhandled`.

- `Onboarding/DesignSystem`: 18 catalog files / 32,355,391 bytes, comprising
  four color sets, five image sets, and seven PDF image appearances.
- `Widget/Media.xcassets`: 5 files / 73,131 bytes, comprising two color sets and
  one PDF logo.
- Total catalog input: 23 files / 32,428,522 bytes.
- Lookup contract: the exact pinned `Color+AppColors.swift`,
  `Image+AppImages.swift`, and `Widget/Assets.swift` files.

Every catalog file must be a regular, non-symlink file. The proof compares the
filesystem inventory with the complete pinned Git tree inventory, compares
live bytes with `git show` for the exact commit, and checks the reviewed size
and SHA-256. The entire Focus file inventory must also be clean, so
`shipping_source_edits: []` covers the checkout rather than only the selected
assets. Ordinary untracked files, ignored untracked files (including generated
Xcode sources), and `assume-unchanged` or `skip-worktree` index flags are all
forbidden and independently recorded. All 23 files, the three lookup sources,
and `Package.swift` are captured in memory and staged under `inputs/focus-ios/`;
the private `0700` proof root contains a non-writable `0555`/`0444` input tree,
and all transformation commands address only those proof-local copies. Modes,
ACL absence, bytes, source, Git commit, and the observed rasterizer discovery
record are checked again after normalization.
The output must be new, inside an owned private parent, and outside both the
Focus and swift-macho repositories.

As with the module proof, the account running this userspace process is assumed
not to be simultaneously hostile to itself. The private proof-root isolation
prevents ordinary cross-UID writes to staged inputs and outputs; a same-UID
process that deliberately reverses permissions and restores bytes during a
rasterizer read is outside the claim. The external rasterizer installation is
not part of that private closure: the proof does not claim continuous path
identity or cross-UID immutability for it.

## Exact image and appearance mappings

| Target | Logical name | Appearance | Pinned PDF |
| --- | --- | --- | --- |
| Onboarding | `icon_background` | default | `icon_onboarding_background.pdf` |
| Onboarding | `icon_background` | dark | `background_icon_dark.pdf` |
| Onboarding | `icon_close` | default | `icon_close_light.pdf` |
| Onboarding | `icon_close` | dark | `icon_close.pdf` |
| Onboarding | `icon_hugging_focus` | default | `HuggingFocus.pdf` |
| Onboarding | `icon_logo` | default | `icon_logo.pdf` |
| Onboarding | `jiggle_mode_image` | default | `JiggleMode.pdf` |
| Widget | `icon_logo` | default | `icon_logo.pdf` |

Each entry is rasterized with `pdftocairo -png -transp -singlefile -r N`, where
`N` is 72, 144, or 216 DPI. The result is 24 canonical PNGs under
`images/<logical-name>/<appearance>@<scale>x.png`. Each reviewed record fixes
the output path, byte count, file SHA-256, and dimensions. The proof decodes
every PNG itself, validates chunk CRCs and non-interlaced RGBA8 structure, and
audits a pixel SHA-256 plus exact transparent, partial-alpha, and opaque pixel
counts.

Two independently observed front-end/output profiles are accepted:

- macOS/arm64, Homebrew Poppler 25.04.0, executable SHA-256
  `963b05a5c78b2a8a32bbfb9a2a3c542a258dd7ec8e9b64d782a4d9848ed058c1`;
- Ubuntu Noble/Linux aarch64, Poppler 24.02.0-1ubuntu9.9, executable SHA-256
  `dec6518985e0810a886ac53a3293f2d49cf292621874501ab0a821eff666e41f`.

All 24 PNGs were reproduced byte-for-byte across those two profiles. Their
combined path/size/hash digest is
`16cd9d48a52095e2057797a654f03a7b548f0afdd5ad1f52057aacb8097ca78a`
(1,338,962 bytes). This is a bounded artifact result: an unreviewed
architecture, front-end executable byte hash, version report, or raster output
is refused at the points where it is checked. The audit records the absolute
front-end executable, version, full commands, controlled environment, and
dynamic-loader install-name/path report at opening and closing discovery.
Linux `ldd` load addresses are ASLR-dependent, so only those parenthesized
hexadecimal addresses are replaced with a fixed marker; the remaining reported
install names and paths are preserved. Dependency file bytes are not hashed,
and the executable path is not continuously attested between discoveries. The
portable artifact claim is therefore grounded in the exact reviewed output
hashes, not a claim about the complete dynamic dependency closure.

## Colors, current OpenUIKit aliases, and symbols

The exact supported color files are copied without rewriting to bundle-root
`Colors.xcassets` (Onboarding) and `Media.xcassets` (Widget). Those locations
and the catalogs' current universal sRGB/default/dark subset are directly
understood by OpenUIKit's current `UIColor(named:in:compatibleWith:)` loader.
The proof also parses all entries and records both source components and
derived RGBA8 values.

OpenUIKit's current `UIImage` loader reads loose PNG/JPEG files and selects
`@2x`/`@3x`, but it does not select luminosity variants. The proof therefore
materializes these explicit bundle-root aliases:

- default: `icon_background.png`, `icon_background@2x.png`, and
  `icon_background@3x.png` (and the same pattern for every other image);
- dark/manual: `icon_background.dark.png`,
  `icon_background.dark@2x.png`, and `icon_background.dark@3x.png`, plus the
  equivalent `icon_close.dark` files.

Default aliases can be requested by logical name. Dark aliases require overlay
or caller trait selection; with the current dotted-name parser, the request
must include the final extension, for example
`UIImage(named: "icon_background.dark.png", ...)`. The proof does not imply
automatic appearance selection.

The shipping source uses `Image(systemName:)` for `1.circle.fill`,
`2.circle.fill`, `3.circle.fill`, and `magnifyingglass`. The proof does not copy
SF Symbols. It generates original 24-point integer-geometry RGBA alpha masks,
supersampled 8x, with an in-script stored-deflate PNG encoder, at all three
scales. The 12 results total 130,572 bytes and have combined digest
`b1886a9da201fdfe072a4f3574fd62a4201f414aa41977dc0f8598cb4057f3f1`.
Stable overlay aliases are:

- `1.circle.fill` -> `step_one`
- `2.circle.fill` -> `step_two`
- `3.circle.fill` -> `step_three`
- `magnifyingglass` -> `icon_magnifying_glass`

The aliases, including their scale variants, are loose bundle-root PNGs. The
original dotted symbol names remain only in the explicit index because
OpenUIKit's current `splitExtension` treats the final dot as a file extension,
and the shipping SwiftUI `Image(systemName:)` calls are not wired to loose
images. The UIKit overlay must request the stable aliases.

## Claim boundary and output

A successful output contains two `Focus_<Target>.bundle` directories with:

- 24 canonical PDF-derived PNGs;
- 12 canonical original-symbol PNGs;
- 36 byte-identical loose OpenUIKit aliases;
- 8 raw color-catalog files;
- two canonical `resource-index.json` files;
- canonical `onboarding-resources-audit.json` outside the bundles.

The index proves logical name, appearance fallback, scale, dimensions, alpha,
and file identity. It is not currently a runtime API. The loose files and raw
color catalogs are deliberately shaped for current OpenUIKit, but a bundle
resource root still has to be supplied, the Onboarding SwiftUI routes still
need the OpenUIKit-backed SwiftUI renderer/hosting bridge, and dark image
selection still needs explicit trait logic. Vector preservation beyond the
three emitted scales, Apple slicing,
idiom/gamut/high-contrast behavior, asset optimization, and `.car` format are
outside this proof.

## Reproduce

On the reviewed macOS host, use a new output path outside either repository:

```bash
cd /Users/miguelsalinas/swift-macho-linux
RESOURCE_PROOF_ROOT=$(mktemp -d /tmp/focus-onboarding-resources.XXXXXX)
python3 -B full/focus-ios/onboarding_resources_proof.py prove \
  scratch/ladder-corpus/focus-ios/focus-ios \
  full/focus-ios/onboarding-resources-proof.json \
  "$RESOURCE_PROOF_ROOT/output"
python3 -B full/focus-ios/test_onboarding_resources_proof.py -v
```

The exact Ubuntu Noble/aarch64 reproduction uses the project image plus the
reviewed distro Poppler package. The output mount is separate from the
read-only source repository:

```bash
cd /Users/miguelsalinas/swift-macho-linux
LINUX_RESOURCE_PROOF=$(mktemp -d /tmp/focus-onboarding-resources-linux.XXXXXX)
docker run --rm \
  -v "$PWD":/w:ro \
  -v "$LINUX_RESOURCE_PROOF":/proof \
  -w /w swift-macho-spike:noble bash -lc '
    set -e
    apt-get update -qq
    apt-get install -y -qq --no-install-recommends \
      python3 poppler-utils=24.02.0-1ubuntu9.9
    python3 -B full/focus-ios/onboarding_resources_proof.py prove \
      scratch/ladder-corpus/focus-ios/focus-ios \
      full/focus-ios/onboarding-resources-proof.json \
      /proof/output
  '
```

The proof intentionally refuses if the observed `pdftocairo` front-end
binary/version report or exact raster output differs from the reviewed profile.
The test suite covers policy widening, stale, unsafe-parent, ACL-bearing and
in-repository outputs, unrelated and hidden source drift, ignored generated
Xcode source, extra catalog files, staging tamper, exact light/dark catalog
semantics, color parsing, PNG corruption, deterministic geometric symbols,
OpenUIKit aliases, index fallback, and the full isolated normalization path.
