# Focus Onboarding UIKit-core proof

This is a fail-closed, reproducible compile/module-emission proof for the
non-SwiftUI portion of Focus's `Onboarding` package target. It proves that the
exact unchanged ten-source UIKit/core closure emits an Apple-targeted Swift
module against the pinned port substrate. It is not a Focus SwiftPM build, an
Xcode build, a link, or an execution result.

## Pinned subject

| Input | Exact captured subject | Compiler treatment |
|---|---:|---|
| Focus | `a2832521c1daa0c23419c73705ae043ed60c9791` | pinned package manifest and workspace lock |
| OpenUIKit | `4c82757bb9cf193605dd9625d73562b1758e85e8` | 299 package/validation inputs, 8,441,392 bytes, staged then `UIKit` target compiled |
| SnapKit | `e74fe2a978d1216c3602b129447c7301573cc2d8` | 36 unchanged sources, 121,457 bytes, emitted as `SnapKit` |
| DesignSystem | Focus pin above | 4 unchanged production sources, 8,872 bytes, emitted as `DesignSystem` |
| Onboarding UIKit/core | Focus pin above | 10 unchanged sources, 25,924 bytes, emitted as `OnboardingUIKitCore` |

The proof captures every input from a committed regular Git blob, compares its
worktree bytes with `HEAD`, copies the captured bytes into a new proof-local
input tree, makes the proof root private (`0700`), removes write permission from
every staged file and directory (`0444`/`0555`), and makes every compiler command
address only those staged copies. It verifies both modes and bytes before and
after every compiler invocation, recaptures all three repositories afterward,
and requires the opening and closing identities to match. Git status masking
such as `assume-unchanged` therefore cannot hide a source edit. All three
worktrees must also be clean; tracked dirt and untracked files both refuse the
proof.

The new proof root must live in an owned `0700` parent. The full resolved
ancestor chain may be owned only by root or the invoking UID and is checked for
unsafe non-sticky write access. macOS extended ACLs are refused on that chain,
the output root, and every staged descendant. This prevents another ordinary
UID from replacing the root or inheriting write access that POSIX mode bits
alone would hide.

The execution assumption is explicit: the account running the proof is not
simultaneously hostile to its own build. A process with the same OS identity
can deliberately reverse owner permissions, mutate an input during a compiler
read, restore it, and thereby defeat any userspace before/after attestation.
The private, non-writable stage prevents ordinary concurrent writes and has a
regression control, but it is not a privilege boundary against that attacker.

Two OpenUIKit `openhost` symlinks are captured and hash-checked but deliberately
not recreated in the proof-local package. They point at already-staged
`openrender` sources and belong to a target outside the `UIKit` dependency
closure. The audit records them as validation-only exclusions; every regular
file under OpenUIKit's `Sources` and `Tests` trees is staged so SwiftPM can
validate the unchanged package manifest without reading the live checkout.

The exact dependency order is:

```text
OpenUIKit/OpenCoreGraphics -> UIKit shim -> SnapKit -> DesignSystem -> OnboardingUIKitCore
```

The DesignSystem compiler receives one additional 146-byte generated build
input, `generated/DesignSystem/Bundle+Module.swift`. It is separately labeled
and hash-pinned; `shipping_source_edits` must remain empty. Any other generated
Swift file is rejected as an adaptation.

## Exact Onboarding boundary

The ten compiled shipping sources are:

```text
Handler/Action.swift
Handler/OnboardingEventsHandlerV1.swift
Handler/OnboardingEventsHandlerV2.swift
Handler/OnboardingEventsHandling.swift
Handler/OnboardingVersion.swift
Handler/ToolTipRoute.swift
OnboardingViewController.swift
Tooltip/TooltipTableViewCell.swift
Tooltip/TooltipView.swift
Tooltip/TooltipViewController.swift
```

All paths above are relative to
`BlockzillaPackage/Sources/Onboarding`. The other eleven Swift files—three
target-local DesignSystem helpers, `PortraitHostingController`, the preview,
and six files under `SwiftUI Onboarding`—are hash-captured as explicit
exclusions. They are not represented as working or compiled by this proof.

The DesignSystem preview-only sources are likewise explicitly captured and
excluded. Its 117 raw asset-catalog files (169,439 bytes) are staged verbatim,
but the pinned package manifest does not declare them as resources. No
`actool`, catalog decoding, runtime bundle lookup, or asset loading occurs.

SnapKit's `Sources/Debugging.swift` is the one explicit, hash-pinned exclusion.
It only overrides diagnostic string formatting through Objective-C/NSObject
dispatch that a pure-Swift OpenUIKit base does not provide; it defines no
constraint creation, installation, update, or DSL API. The other 36 upstream
sources are compiled unchanged.

## Diagnostic contract

`SnapKit` and `DesignSystem` must emit empty diagnostic logs. Every module must
emit zero errors. `OnboardingUIKitCore` must emit exactly these two warnings,
which are retained rather than suppressed:

```text
Handler/OnboardingEventsHandlerV2.swift:11:57: cannot use struct 'Publisher' here; 'Combine' was not imported by this file
Handler/OnboardingEventsHandling.swift:9:50: cannot use struct 'Publisher' here; 'Combine' was not imported by this file
```

The warning paths, locations, and messages are matched exactly. Any additional
warning or any error refuses the proof. The staged OpenUIKit SwiftPM build log
is preserved and hash-audited, and it too must contain zero errors; Xcode/Clang
may report substrate build warnings whose exact presence is recorded alongside
the hashed toolchain identity.

## Reproduce

From the repository root on macOS with Xcode installed, make clean detached
local clones (the proof intentionally refuses dirty or untracked worktrees):

```bash
PROOF_PARENT=$(mktemp -d /tmp/focus-onboarding-uikit.XXXXXX)
git clone --quiet --shared --no-checkout \
  scratch/ladder-corpus/focus-ios "$PROOF_PARENT/focus"
git -C "$PROOF_PARENT/focus" checkout --quiet --detach \
  a2832521c1daa0c23419c73705ae043ed60c9791
git clone --quiet --shared --no-checkout ../uikit "$PROOF_PARENT/uikit"
git -C "$PROOF_PARENT/uikit" checkout --quiet --detach \
  4c82757bb9cf193605dd9625d73562b1758e85e8
git clone --quiet --shared --no-checkout \
  scratch/xcodeplan-deps/SnapKit "$PROOF_PARENT/snapkit"
git -C "$PROOF_PARENT/snapkit" checkout --quiet --detach \
  e74fe2a978d1216c3602b129447c7301573cc2d8
python3 -B full/focus-ios/onboarding_uikit_proof.py \
  "$PROOF_PARENT/focus/focus-ios" \
  "$PROOF_PARENT/uikit" \
  "$PROOF_PARENT/snapkit" \
  full/focus-ios/onboarding-uikit-proof.json \
  "$PROOF_PARENT/proof"
```

The output must be a new path in that private parent. The audit is written to
`$PROOF_PARENT/proof/onboarding-uikit-audit.json`. Run all positive and
adversarial controls with:

```bash
cd full/focus-ios
python3 -B -m unittest -v test_onboarding_uikit_proof
```

Tool discovery is rooted at `/usr/bin/xcrun`. Subprocesses inherit no caller
environment: a fixed nine-variable allowlist supplies Git isolation, locale,
`HOME`, `TMPDIR`, and `PATH`. This also excludes open-ended Clang/Swift driver
variables such as `CCC_OVERRIDE_OPTIONS` and `C_INCLUDE_PATH`. The resolved
`swift`, `swiftc`, macOS SDK settings, and `xcrun` binaries are hashed. The full
commands, exact environment, and input records are audited, and toolchain
identity is rediscovered after compilation.

## Claim boundary

This proof runs on macOS and uses Apple's compiler and macOS SDK to emit
`arm64-apple-macos13.0` modules. It does **not**:

- run `xcodebuild` or reproduce the complete `.xcodeproj`;
- compile the eleven excluded SwiftUI/preview sources;
- compile or decode asset catalogs;
- perform runtime `Bundle.module` discovery;
- link an app or extension;
- produce or launch a Focus bundle; or
- execute this Onboarding code as a Mach-O guest on Linux.

The result is an exact host/macOS compile frontier, not Linux guest execution.
