# Portable UIKit live display and input transport

This directory bridges a true-iOS ARM64 Mach-O application to a native Linux
SDL window without importing anything into application or vendor source. The
generated `PortableUIKitApplicationHost` opts in only when
`OPENUIKIT_LIVE_TRANSPORT` names a host-created v1 transport file. With the
variable absent, the established clocked/headless loop remains the exercised
default: it opens no transport and does not render a framebuffer.

The SDL window can use the existing Xvfb → x11vnc → noVNC path in
`full/gui-harness`. Browser mouse and keyboard input enters SDL, is published
to the ring below, and is delivered through the public UIKit host seams:
`UIWindow.sendTouch`, `sendText`, and `sendKey`. Frames travel in the other
direction through `UIRenderer.render`.

## v1 wire contract

The backing file is one pointer-free, 64-bit layout:

```
256-byte header
RGBA slot 0 (host-selected fixed capacity)
RGBA slot 1 (same capacity)
N × 128-byte input records
```

Each frame slot owns its width, height, stride, byte count, format, sequence
descriptor, and an atomic cross-process lease word. The Mach-O producer takes
the inactive slot's exclusive lease, writes pixels and metadata, then
release-publishes descriptor sequence, active slot, and global sequence. A
Linux consumer takes a counted reader lease only after observing the active
slot and revalidates the commit before copying. A late reader cannot race a
producer that already claimed the slot, and a wrapping producer reports
`OPENUI_LIVE_BUSY` instead of touching a slot still being copied. Multiple
readers may safely snapshot a frame. The focused concurrent test publishes
2,000 frames while snapshotting and verifies every byte (`torn=0`).

Input is a single-producer/single-consumer ring. Each fixed record carries an
exact sequence, monotonic nanosecond timestamp, touch coordinates/ID, key, or
up to 80 bytes of UTF-8. The native host never overwrites unread input: a full
ring increments `dropped_input_count` and reports the loss. Quit and readiness
are explicit state bits, not inferred from process disappearance.

The header has compile-time size/offset assertions on both ABIs. No pointer,
`pthread` object, C atomic type, SDL type, or Swift layout crosses the file.

## Build the native host

On Linux with SDL2 development headers installed:

```bash
./full/live-transport/build_linux_sdl_host.sh \
  --output-root /private/tmp/openui-live-linux-host-r1
```

The output root must not exist. It contains the ELF host, NUL-delimited exact
compiler arguments, input/binary hashes, compiler identity, and SDL version.
To exclude a stale result, trash that exact output and rebuild it:

```bash
/usr/bin/trash /private/tmp/openui-live-linux-host-r1
```

Start the host before the guest so creation is exclusive and cannot truncate
an unrelated path:

```bash
DISPLAY=:99 /private/tmp/openui-live-linux-host-r1/openui-live-sdl-host \
  --transport /private/tmp/openui-live/session-v1.bin --create \
  --frame-capacity 67108864 --input-capacity 256
```

Then launch the already-built app through Machorun with its ordinary exact
runtime closure, adding only platform-owned environment:

```bash
OPENUIKIT_LIVE_TRANSPORT=/private/tmp/openui-live/session-v1.bin \
OPENUIKIT_LIVE_SCALE=1 \
MACHORUN_ROOT=/exact/guest-root \
/exact/guest-root/machorun /exact/Proof.app/Proof
```

No app source flag, overlay, shadow module, or source rewrite participates.
`build_portable_application_guest.sh` compiles the Darwin mmap endpoint for
the package's exact target triple/SDK and links its two platform objects into
the generated host executable.

## Gates

Local/static gates (safe while a central cold Docker replay owns the heavy
lane):

```bash
python3 -m unittest discover -s full/live-transport/tests -p 'test_*.py'
python3 -m unittest discover -s full/xcodeplan/tests -p 'test_*.py'
bash -n full/xcodeplan/build_portable_application_guest.sh
```

They cover the exact ABI layout, exclusive creation, double-buffered frame
publication, concurrent tear detection, sequenced touch/text/quit delivery,
overflow accounting, native SDL compilation, `arm64-apple-ios18.5-simulator`
guest C compilation with no external atomic-helper dependency, real Swift
host+transport typechecking, and preservation of the opt-in/headless branch.
Undefined-behavior sanitizer coverage runs wherever Clang provides it; the
Linux gate additionally runs the concurrent transport under ThreadSanitizer.

The first full Linux acceptance is deliberately graphical, not a log-only
claim: cold-build a generated UIKit scene guest, capture its initial pixels,
inject a click that changes a visible label, focus its text field and type a
known token, then capture changed pixels/text while the same SDL window is
reachable at the localhost noVNC URL. Preserve all three image SHA-256 values,
the input/frame sequences, app/platform commits and trees, platform manifest,
Mach-O/ELF hashes, and one-command relaunch in the proof directory.

## Canonical proof target and container harness

`proof-app/LiveTransportProof.xcodeproj` is a canonical three-source Xcode
application target at deployment 18.5. Its source uses ordinary Apple APIs
only (`UIApplicationDelegate`, `UIWindowSceneDelegate`, `UIAction`,
`UIButton`, and `UITextField`) and typechecks unchanged against Apple's UIKit.
The canonical inventory regenerates the same three-source list and the normal
platform-owned scene bootstrap. Fixed control coordinates make a repeatable
graphical proof possible without adding test hooks to the app.

After committing this support tree, build the display-only image from that
exact commit/tree (the command archives the commit, never the working tree):

```bash
./full/live-transport/live_runtime_harness.sh build-image \
  --source /path/to/platform-support \
  --commit FULL_SUPPORT_COMMIT --tree FULL_SUPPORT_TREE \
  --image openui-macho-live:FULL_SUPPORT_COMMIT --cold
```

After `build_portable_application_guest.sh` has cold-built the proof target,
launch its output and the frozen guest runtime read-only:

```bash
./full/live-transport/live_runtime_harness.sh launch \
  --image openui-macho-live:FULL_SUPPORT_COMMIT \
  --guest-root /exact/platform/guest-root \
  --application-output /exact/cold/application-output \
  --product LiveTransportProof --name openui-macho-live \
  --port 6080 --scripted-proof
```

The container publishes only
`http://127.0.0.1:6080/vnc.html?autoconnect=1&resize=scale` and remains alive
for interactive use. `--scripted-proof` first captures the untouched screen,
clicks the fixed button, focuses the text field, types `Linux UIKit`, and
captures both changed states. `/run/openui-live/proof.tsv` records pixel,
Mach-O, Machorun, frame-sequence, input-sequence, support commit, and support
tree evidence. Re-run health or stop the exact container with:

```bash
./full/live-transport/live_runtime_harness.sh health \
  --name openui-macho-live --port 6080
./full/live-transport/live_runtime_harness.sh stop --name openui-macho-live
```
