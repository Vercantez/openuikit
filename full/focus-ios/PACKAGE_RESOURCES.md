# Pinned Focus package-resource staging

This slice stages a deliberately small, reviewed resource subject from Focus
commit `a2832521c1daa0c23419c73705ae043ed60c9791`. It is not a general SwiftPM,
Xcode asset-catalog, or `actool` replacement.

[`package-resources.json`](package-resources.json) pins `Package.swift` by size
and SHA-256, the exact five resource roots below, their file and byte counts,
their per-root digests, the aggregate source/stage digests, the four shipping
DesignSystem sources, and OpenUIKit commit
`81e1e05fbde712a28ea031534462b80740ed5eb5` for the module proof.

| target | package status at the pinned manifest | staged input | files | bytes | source digest |
|---|---|---:|---:|---:|---|
| DesignSystem | raw, undeclared | `Colors.xcassets` | 40 | 18,621 | `da3cadc474b51d242db2dde483c15b4c5c0b03bac0df11c3ff1dd32281e994d4` |
| DesignSystem | raw, undeclared | `Assets.xcassets` | 77 | 150,818 | `9a06e64a83591e2dc2e7f6e44afd6f181c4f9501f4bf22502887b3033e025532` |
| Widget | raw, undeclared | `Media.xcassets` | 5 | 73,131 | `cf65ea586b104d622bb50ec5f0c09a1dc11ec0f293d322776dbb6f698f880126` |
| Licenses | declared `.copy` | `license-list.plist` | 1 | 55,562 | `8c814c66d2e1fb2d38bd6442b1dcd9793327ca7a596b5179060b766275bef377` |
| Licenses | declared `.copy` | `focus-ios.plist` | 1 | 16,500 | `e613db4a1ae22ea3b65a35f7b36e047b88e8b8dea6266c5e94cb250e8193ec45` |

The complete resource subject is **124 files / 314,632 bytes**, with source
digest `c04936bbf7e156abd3e417c5234b168026d0260c8e3eacd8aa3c0a8e83015f19`.
After the pinned path mapping, its digest is
`0e58bc76ee291d321cd94a1c98310cee0e86703f17cf48ea5be0dbaa64fb4bee`.
The declaration labels are observations about the byte-pinned manifest: that
manifest declares only the two Licenses `.copy` rules. The tool does not edit
or reinterpret the manifest to make the three raw catalogs SwiftPM resources.

## Stage and verify

From the `swift-macho-linux` root:

```bash
resource_run=$(mktemp -d /tmp/focus-package-resources.XXXXXX)
python3 -B full/focus-ios/package_resources.py stage \
  scratch/ladder-corpus/focus-ios/focus-ios \
  full/focus-ios/package-resources.json \
  "$resource_run/stage" "$resource_run/audit.json"

python3 -B full/focus-ios/package_resources.py verify \
  scratch/ladder-corpus/focus-ios/focus-ios \
  full/focus-ios/package-resources.json \
  "$resource_run/stage" "$resource_run/audit.json"
```

`stage` requires both output paths to be new and outside the Focus checkout. It
never overwrites or deletes an old output. A crash after the exclusive stage
directory is created can leave a partial directory, but that directory has no
valid audit and every later run refuses it as stale.

The output layout is deterministic in path, bytes, and mode (`0755`
directories, `0644` files):

```text
stage/
  resources/
    DesignSystem/Colors.xcassets/...   # hierarchy retained verbatim
    DesignSystem/Assets.xcassets/...   # hierarchy retained verbatim
    Widget/Media.xcassets/...          # hierarchy retained verbatim
    Licenses/license-list.plist
    Licenses/focus-ios.plist
  accessors/
    DesignSystem/Bundle+Module.swift   # the only generated Swift source
```

The canonical JSON audit contains every source and staged relative path, file
size, SHA-256, catalog directory, group digest, aggregate digest, pinned module
source, manifest hash, and policy-file hash. It contains no checkout or output
absolute path, so two fresh stages from the same bytes produce identical audit
bytes. The digest framing hashes each UTF-8 path, a NUL, decimal byte count, a
NUL, content SHA-256, and newline in bytewise path order.

Before publishing, the tool requires the exact Git commit; compares the disk
inventory below every approved resource root to `git ls-files`; rejects extra,
missing, empty-untracked, non-regular, and symlink entries; securely reads and
hashes every file; stages only held, attested bytes; then recaptures the entire
source subject. `verify` brackets its stage and audit checks with the same input
capture. Policy keys and values are closed over compiled-in approved constants,
so a syntactically valid policy cannot widen the subject by itself.

Run the 22 self-contained fixture controls plus the pinned-checkout integration
control with:

```bash
python3 -B full/focus-ios/test_package_resources.py -v
```

The negative controls cover commit, manifest, resource, and DesignSystem source
drift; stale stage/audit outputs; source and staged tampering; untracked source
and staged files and empty directories; symlinks; semantically widened policy;
and absolute, backslash, and `..` source/stage path escapes. A duplicate-stage
control compares every output path/byte and the complete audit.

## Exact DesignSystem module proof

[`prove_designsystem_resources.sh`](prove_designsystem_resources.sh) creates a
fresh output root, stages the policy, clones the OpenUIKit object source without
a checkout, detaches at the commit named by the audit rather than consuming its
current HEAD or uncommitted files, builds the real `OpenUIKit` product, reads
the four pinned source paths from the resource audit, and invokes `swiftc` in
Swift 5 language mode. It then re-verifies the staged/source bracket after the
compiler returns.

```bash
full/focus-ios/prove_designsystem_resources.sh
```

The proved compiler subject is exactly:

- `Bundle+CurrentBundle.swift`
- `UIColor+AppColors.swift`
- `UIFont+AppFonts.swift`
- `UIImage+AppImages.swift`
- the one generated `accessors/DesignSystem/Bundle+Module.swift`

The three `Preview Files/*.swift` sources are not included. On 2026-08-28 the
command emitted `DesignSystem.swiftmodule` for
`arm64-apple-macos13.0` with a zero-byte diagnostic log against OpenUIKit
`81e1e05`. The proof is bracketed source/module emission, not execution.

## Deliberate runtime boundaries

The generated accessor is a 146-byte compile-only definition whose
`Bundle.module` property traps with `runtime Bundle.module discovery is
unavailable`. That is intentional: neither this slice nor OpenUIKit currently
wires the staged target directories into Foundation's runtime `Bundle`
discovery. A future runnable target needs a real, tested bundle layout and
lookup policy; replacing the trap with `Bundle.main` would silently assert a
layout this proof does not establish.

The catalogs are copied raw and are not compiled by `actool`. The DesignSystem
catalogs contain 42 PDF and 2 SVG payloads, and the Widget catalog adds one PDF.
OpenUIKit `81e1e05` does not decode or rasterize those vectors. Thus the source
module can emit, but Focus's force-unwrapped named images are not safe to execute
until a pinned vector-decoding or deterministic rasterization stage exists.
The raw universal sRGB color-set parsing already implemented by OpenUIKit is
also not a claim of runtime success here until the real Foundation bundle root
is supplied.

This slice does not compile or execute Widget or Licenses, does not prove plist
runtime lookup/decoding, does not build the Focus app, and does not make SwiftUI
portable. Its compiler proof uses Apple's macOS SDK because that is the current
OpenUIKit build target; it is not a Linux guest execution proof.
