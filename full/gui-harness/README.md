# Linux graphical application harness

This harness turns a pinned SwiftPM application commit into a native Linux
image, opens its SDL window in Xvfb, and transports the live framebuffer and
input through x11vnc + noVNC. The browser path is deliberately localhost-only.
Mouse, drag and keyboard events arriving through noVNC enter the same X11/SDL
event queue the application uses locally.

This directory is the **native Linux/OpenUIKit display route**. It is
immediately useful for playable platform and application evaluation, but its
Showcase result alone is not evidence that the same source completed the
true-iOS Mach-O route. The platform-owned bridge for that second route now
lives in `full/live-transport`: it carries `UIRenderer` pixels and sequenced
UIKit input between a platform-7 Mach-O guest and a native SDL host while
reusing this Xvfb/x11vnc/noVNC display path.

## Source contract

`build` requires the complete commit and tree IDs. It verifies the object pair,
rejects unmaterialized submodules, and runs `git archive COMMIT` into a fresh
temporary Docker context. It never copies or bind-mounts the checkout's working
tree, `.build`, untracked overlays, or vendor edits. The image records the
commit, tree, archive SHA-256, tracked-file count, product and display contract
as labels. The Dockerfile checks the same provenance before invoking SwiftPM.

The default base is the immutable ARM64-capable Swift image used by the first
live proof:

```
swift@sha256:29b983751c605c2d3102d2ab93438c6e0cadf110d9d2aa6e929b6dec9dcb7cbc
```

Swift 6.2.4 currently crashes in package-wide default cross-module
optimization on one OpenUIKit `RealAppProbe` generic. The harness therefore
passes the supported `-Xswiftc -disable-cmo` compiler toggle by default while
retaining release optimization. `--enable-cmo` removes that toggle for sources
where the compiler issue does not apply.

## Exact known-green Showcase

The following source commit is the last tree before a Linux-only KVC override
regression. Its 3,023-line DemoApp and `openhost` bytes are identical to the
newer platform head used during the 2026-09-01 live evaluation.

```bash
H=/path/to/swift-macho-linux/full/gui-harness/linux_gui_harness.sh
U=/path/to/OpenUIKit
C=2aad35f61f3a1e8f794cdcd974f1be5de6ae24fa
T=2ff9e40017d4a210d3c1bfbbd29ce04a13c7f4fb

"$H" audit --source "$U" --commit "$C" --tree "$T"
"$H" build --source "$U" --commit "$C" --tree "$T" \
  --image openplatform-showcase:2aad35f --cold
"$H" launch --image openplatform-showcase:2aad35f \
  --name openplatform-showcase-live --app showcase --port 6080
```

Open the stable URL printed by `launch`:

```
http://127.0.0.1:6080/vnc.html?autoconnect=1&resize=scale
```

The Showcase is an ordinary three-tab UIKit platform demo: Settings and its
profile sheet, a navigable/animated Tasks table, and live text fields/views.
It is a useful broad graphical proof, but it is not represented as an external
open-source application.

## Repeat, inspect and stop

`health` verifies all four processes, commit/tree identity, the visible X11
window, a non-uniform captured framebuffer, and the noVNC HTTP endpoint:

```bash
"$H" health --name openplatform-showcase-live
"$H" relaunch --image openplatform-showcase:2aad35f \
  --name openplatform-showcase-live --app showcase --port 6080
"$H" stop --name openplatform-showcase-live
```

`launch` refuses to overwrite an existing container. `relaunch` and `stop`
remove only the exact validated container name. Custom public bindings are not
supported; the published noVNC port is always `127.0.0.1`.

Use `build --cold` whenever the proof must exclude Docker layer reuse. The
source compilation also starts by deleting `.build` inside the archived tree.
Without `--cold`, Docker may reuse a previously attested identical build layer.
