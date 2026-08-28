# Focus Widget module proof

This proof emits the exact two-source Focus `Widget` target with Apple's Swift
compiler and stages its exact raw asset catalog. It is a narrow module-emission
milestone, not a claim that the target links or runs as a Mach-O guest on Linux.

The pinned subject is:

- Focus `a2832521c1daa0c23419c73705ae043ed60c9791`;
- `Assets.swift` and `SearchWidgetView.swift`, unchanged (2,539 bytes total);
- `Media.xcassets`, unchanged (5 files / 73,131 bytes);
- one 146-byte generated-build-input, module-local `Bundle.module` accessor;
- OpenUIKit `0bba80a4138ece678844e2f55da16ffb7cbf70e9` and SnapKit
  `e74fe2a978d1216c3602b129447c7301573cc2d8`, attested as surrounding
  port state but explicitly **not** passed to this target's compiler invocation.

`Widget` imports only SwiftUI and has no package-target dependency. The pinned
`Package.swift` also does not declare `Media.xcassets` as a resource; the policy
therefore labels it `raw-unhandled-at-pinned-manifest`. The generated accessor
supplies only the build-time `Bundle.module` name expected by the shipping
source. It traps if evaluated and makes no claim that stock SwiftPM currently
generates the accessor for this manifest.

The two shipping files are captured from committed blobs and copied byte for
byte into `inputs/Widget/`. The compiler consumes only those proof-local copies,
never the live Focus worktree paths. Their complete inventory and hashes are
verified again after compilation and audited as unchanged shipping-source
inputs. The audit reports `shipping_source_edits: []`; it lists the accessor
separately under `generated_build_inputs`, so the extra generated input is not
hidden behind an ambiguous no-adaptations claim.

## What success establishes

On macOS with Apple's Swift compiler, the proof invokes `swiftc` in Swift 5
mode with `-parse-as-library`, `-wmo`, target `arm64-apple-macos13.0`, and the
two exact staged source copies plus the exact generated accessor. Success requires all four
Widget module artifacts to be non-empty and the combined compiler diagnostic
log to contain zero bytes. Source, repository, generated-input, and staged
resource identities are checked before and after compilation.

Toolchain discovery does not trust `PATH`, `swiftc`, `SWIFT_EXEC`, `SDKROOT`,
`DEVELOPER_DIR`, `TOOLCHAINS`, or inherited Swift/Clang driver overrides. The
proof uses `/usr/bin/xcrun` in a sanitized environment to resolve Apple's
`swiftc` and the macOS SDK, passes that SDK explicitly with `-sdk`, and invokes
the resolved launcher by absolute path. The audit records the discovery-tool
hash, compiler launcher and resolved executable, compiler binary hash, SDK
path, version, complete command and flags, exact compiler inputs, and the fact
that there is no link step. Discovery, compiler, version, and SDK identity are
resolved again after module emission and must remain identical.

The resource stage is deterministic and byte-for-byte only. It does **not** run
`actool`, compile the catalog, decode its PDF, discover a runtime bundle, link a
binary, launch anything, or exercise Linux. The audit records these negative
claim boundaries and lists no source adaptations.

## Run

The repositories passed to the proof must be clean checkouts whose `HEAD`
resolves to the three pinned commits; detached `HEAD` is not required. The
output path must not exist. From this repository:

```bash
python3 -B full/focus-ios/widget_proof.py prove \
  /clean/focus-checkout/focus-ios \
  /clean/openuikit-checkout \
  /clean/snapkit-checkout \
  full/focus-ios/widget-proof.json \
  /new/path/widget-proof

python3 -B full/focus-ios/test_widget_proof.py -v
```

The output contains unchanged shipping-source inputs, the staged raw catalog,
generated accessor, zero-byte diagnostic log, four module artifacts, and
canonical `widget-audit.json`.
Stale outputs are refused and never overwritten. The controls cover policy and
path widening, hidden source/resource drift, resource-stage tampering,
unexpected generated Swift inputs, ambient Git redirects, and the complete
pinned integration path.
