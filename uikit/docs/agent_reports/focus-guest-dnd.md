# Focus guest drag/drop — agent/focus-guest-dnd

## Measurement and decision

Task: verify88's two Blockzilla guest errors, with Blockzilla unchanged.
The Foundation-hidden compiler reproduction went from **2 errors to 0**:
`Foundation.NSItemProvider` could not enter `UIDragItem`, and
`any UIDropSession` had no `loadObjects`. This is an API/payload repair;
no pixel, layout, font, or platform-rendering rule changed.

**Decision: a subclass bridge, rather than a typealias.** The umbrella's
NotificationCenter alias pattern establishes the need to share the actual
UIKit object. However, the extension-host provider is an open class with a
required `init?(coder:)` witness for the guest `NSSecureCoding` protocol.
A retroactive conformance on the foreign, non-final OpenUIKit class cannot
supply that required initializer in an extension. A separate guest alias/conformance probe measured the compiler rejection:
`initializer requirement 'init(coder:)' can only be satisfied by a 'required'
initializer in the definition of non-final class 'NSItemProvider'`.
Making it final would also remove existing subclassing semantics. Instead Foundation's provider
inherits OpenUIKit's storage and designated initializers. `UIDragItem`
retains that exact provider object (`===`), without converting or duplicating
the payload. Foundation retains secure coding, copying, synchronized mutable
`suggestedName`, and the existing 64-entry, process-local coder transport.
Copies and coded snapshots preserve both representation identifiers and
retained objects. NSExtensionItem's attachment type and transport are intact.
The two public type spellings are a superclass/subclass pair, not aliases;
an arbitrary base OpenUIKit provider is not automatically a Foundation
secure-coding provider.

The public, documented guest hook `UIDropSession._openUIKitLoadObjects`
extracts retained typed payloads (localObject first). An extension in the
existing Foundation `Progress.swift` exposes `loadObjects` through the
protocol existential, completes exactly once, and returns the canonical
Foundation.Progress, with the delivered units marked complete. No second
Progress, dependency family, source-manifest entry, or StringProcessing
algorithm was introduced. The documented copying initializer is the other
guest boundary hook.

## Apple Foundation oracle

Preserved the supplied operator-Mac measurements and repeated them with
`swift /tmp/focus-guest-dnd-oracle.swift` on this Mac. A typed
`(URL) -> NSItemProvider?` reference confirms the failable signature.
The fresh probe writes an extensionless file containing `focus` in a private
/tmp directory and leaves `missing.txt` absent:

```text
https: nonnil=true ids=["public.url"]
existing: nonnil=true ids=["dyn.age8u", "public.file-url", "public.url"]
missing.txt: nonnil=true ids=["public.plain-text", "public.file-url", "public.url"]
directory: nonnil=true ids=["dyn.age8u", "public.file-url", "public.url"]
```

Both non-Darwin provider branches now have `init?(contentsOf:)`, retain the
URL, and expose these measured identifiers. Previously the guest umbrella
returned nil for all contentsOf calls; the guest library used a non-failable
initializer and only public.file-url, even for https. Linux file-content
representations read the file or report its error; URL representations
serialize the URL. No golden PNG/layout was edited.

Open questions: other filename UTIs and external/file-coordinated guest
representations remain unmeasured; only their known URL representations are
advertised. This change tests retained in-process URL/String payloads, not
XPC, arbitrary coercion, persistent archives, or real system drag timing.

## Reproduction and guest proof

Copied the committed tree with `git -C .. archive HEAD | docker exec -i
uikit-linux ... tar -xf -` into `/work-focus-guest-dnd`, then ran the requested
commands in that directory. The operator container is **aarch64**, Swift
**6.2.4**, and cannot reach the full Blockzilla compile:

```text
full/swiftui/build_focus_widget_guest.sh: line 20: 1: usage: build_focus_widget_guest.sh <normalized-Focus_Widget.bundle>
bash: full/swiftui/build_and_run_reminder_scene_guest.sh: No such file or directory
build_full: no FE sysroot at /work-focus-guest-dnd/scratch/sysroot_fe4; run full/foundation/stage_fe_sysroot.sh (Darwin) or scripts/x86/stage_fe_sysroot.sh (Linux x86_64 sibling)
```

`build_full.sh:1454` owns `compile_app_module Blockzilla`; the supplied
rung-c script is absent from this repository revision. Neither /src nor /work
in the existing container was changed. Full x86 rung-b/rung-c execution
remains the operator's authority, and is **not claimed here**.

Used the allowed Foundation-hidden fallback with the staged FE4 sysroot at
`/Users/miguelsalinas/swift-macho-linux` and
`swift-macho-spike:python3-nosde-preflight-20260830`:

```text
# before
GUEST_ROUTE_COMPILE_OK openuikit=139 opencoregraphics=12
GUEST_ROUTE_CHECK_OK elapsed=66s out=/tmp/guest-route-focus-guest-dnd-before
# after
GUEST_ROUTE_COMPILE_OK openuikit=139 opencoregraphics=12
GUEST_ROUTE_CHECK_OK elapsed=58s out=/tmp/guest-route-focus-guest-dnd-after
```

Against those actual hidden modules, compiled a narrow module named
Foundation from the existing extension guest identity fixture, actual coding
protocols, NSExtensionHost, and Progress. The baseline added only the exact
old fail-closed FoundationGuest initializer. The probe retained the failing
URLBar/BrowserViewController call shapes:

```text
/tmp/focus-guest-dnd-probe.swift:6:34: error: cannot convert value of type 'Foundation.NSItemProvider' to expected argument type 'OpenUIKit.NSItemProvider'
/tmp/focus-guest-dnd-probe.swift:7:17: error: value of type 'any UIDropSession' has no member 'loadObjects'
```

The same probe compiles after the change. The carried compile test additionally
emits the guest test executable's object containing URL/String, existential,
identity, copy/coder, empty-session and localObject-precedence assertions:

```text
FOCUS_GUEST_DND_COMPILE_OK provider=subclass-bridge session=existential progress=Foundation coding=retained
```

Reproduce from uikit/ after running guest_route_check with the above output:

```sh
docker run --rm \
  -v /Users/miguelsalinas/swift-macho-linux:/w:ro -v /tmp:/tmp \
  -v "$PWD/..":/src:ro -v "$PWD":/uikit:ro \
  swift-macho-spike:python3-nosde-preflight-20260830 \
  bash /src/full/appshim/tests/test_focus_guest_dnd_compile.sh \
  /tmp/guest-route-focus-guest-dnd-after /tmp/focus-guest-dnd-carried
```

`full/foundation/tests/test_foundation_extension_guest_ec2.sh` now also
builds and runs this carried test when supplied a complete guest package.
Here it was **cross-compiled, not executed**: the complete guest package is
not available. The focused Linux tests execute the URL and String provider
payload path without setting localObject.

## Regression checks

- Focused macOS unit tests: **24/24**, Linux Swift 6.2.4: **26/26**.
- Existing Apple extension-host oracle/runtime: exact carried golden;
  secure coding/copy/metadata, 66 callbacks, 64 concurrent operations pass.
- Guest OpenUIKit object: **0 → 0** undefined StringProcessing references (`llvm-nm-18 --undefined-only`).
- Existing Progress Apple oracle/runtime: typed observation, cancellation,
  pause/resume and completion pass.
- Catalyst: **124/124 before and after**, all **178/178 PNGs byte-identical**.
- Real-app renders: **15/15 PNGs byte-identical** before/after. The 12 existing
  comparisons retain their scores/floors. Home, Ledger and Focus browser
  goldens were already missing in /tmp/golden_realapp_ios; no new golden or
  unsupported score is claimed for them.
- Fresh private-device iOS suite: **112/113 before and after**, **113/113 PNGs byte-identical**. Only pre-existing `corner_radius` fails (99.411). Baseline executable retained before editing and replayed against the same fresh goldens.
- Linux release `openrender`: **PASS**, Swift 6.2.4, 222.89 s. The first copy attempt raced a transient SwiftPM build.db-journal; retried the exact requested Docker command after local builds finished.

## Final merge check

**All checks passed; zero REFUSED lines.** The checker printed its success
marker, then the shell returned **128 during the existing EXIT cleanup**.
The normal CHECK_ONLY path already aborts the temporary merge; the EXIT
trap attempts `git merge --abort` again under `set -e`. The temporary tree
has no MERGE_HEAD. No build, scope, render, or conformance check failed.
The checker itself is outside this task's edit scope and was not patched. The initial worktree check used stale
local `main` (1e03a29f), which incorrectly included three pre-existing WebKit
baseline commits in this task's scope. The task started at `origin/main`
89291fae. Re-ran the unchanged checker in an isolated shared clone at
`/tmp/focus-guest-dnd-audit`, with its local main set to that exact remote
baseline and the task commit 2d5a023b present locally. No operator branch,
checker source, ALLOW_DROP setting, or permitted-path expression was changed.
The isolated check saw exactly the 11 authorized task files. This final report
update is documentation only; all implementation and test sources are the
ones validated by that check.

From the isolated repository root:

```sh
ALLOW_PATHS='^full/(foundation|appshim)/' CHECK_ONLY=1 bash uikit/scripts/agent_merge.sh agent/focus-guest-dnd
```

Catalyst 124/124, Foundation-hidden compile (139+12, 54 s), full macOS test
bundle, all real-app floors, all 707 conformance comparisons, and clean Linux
openrender/ConformanceApps/OpenUIKitTests builds passed. Exact log tail:

```text
   TextKit:t1200.xxxl: 99.920 (board 99.920)
   TextKit:t2200.xxxl: 99.577 (board 99.577)
==> Linux build
/work/Sources/OpenUIKit/UIPrintInteractionController.swift:212:5: warning: non-'@objc' instance method declared in extension cannot be overridden; use 'public' instead; this will be an error in a future Swift language mode
    |     `- warning: non-'@objc' instance method declared in extension cannot be overridden; use 'public' instead; this will be an error in a future Swift language mode
Build of product 'openrender' complete! (164.07s)
checks passed (CHECK_ONLY)
```
