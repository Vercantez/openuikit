# Interactive host for the Mach-O guest (Firefox Focus in a window)

Branch `agent/guest-interactive-host`. Firefox Focus, launched through its real
AppDelegate by machorun, now runs in a window on Linux. Real mouse and keyboard
events drive it: taps, typing, the menu, Settings, pushing a screen and going
back. The web view stays blank because there is no WebKit engine.

## Open it

    bash scripts/ops/guest_interactive.sh            # builds if stale, then prints
      Open: http://localhost:6080/vnc.html?autoconnect=1&resize=scale&reconnect=1

`--detach` starts it and returns; `--stop` stops it; `--port N` picks another
port; `--no-build` skips the build step. The script builds the guest with
`local_guest_verify.sh` (with `LOCAL_GUEST_SKIP_VERIFY=1`). It also builds
`openuikit-guest-interactive:arm64`, which is the guest image plus Xvfb,
x11vnc, noVNC and xdotool (`scripts/ops/guest_interactive.Dockerfile`). Then it
starts the container with the port bound to 127.0.0.1 and waits for
`HOST_FULL_LAUNCHED`.

I checked the whole route from the Mac: the page returns 200, the websocket
upgrade returns 101, x11vnc answers `RFB 003.008`, and xdotool clicks and
typing on the Xvfb display drove the app. I could not run a real browser
session because the Chrome extension was not connected.

## Architecture

| piece | where | role |
|---|---|---|
| C ABI | `full/sdlhost/include/OpenSDLHostABI.h` | Versioned (`v1`). Fixed-arity functions, one fixed-width event struct, and no SDL type, union or variadic call across the boundary. Same rules as `OpenURLTransportABI.h`. |
| Linux side | `full/sdlhost/OpenSDLHost.c` → `libOpenSDLHost.so` (`build_host_helper.sh`) | Owns the SDL window, renderer, streaming texture (ABGR8888, which is the Bitmap byte order) and event queue. Also has a main-queue drain (`_dispatch_main_queue_callback_4CF`, resolved with dlsym), a frame cap when there is no vsync, and `OPENUI_SDL_HOST_STATS`. |
| Darwin side | `full/sdlhost/OpenSDLHostBridge.c` → `darwin/usr/lib/libOpenSDLHost.dylib` | `_glibc_openui_sdl_host_v1_*` labels, which machorun resolves only for dylibs in its trusted root, the same pattern as the other bridges. Only host_full links it. |
| Shared loop | `uikit/Sources/openhost/HostLoop.swift` | Factored out of `HostCore.swift` with no Foundation or CSDL2 import. It holds `HostSurface`, SDL event to touch/text/key/key-command translation, the dirty-flag live loop and the `--script/--record` replay. openhost compiles it with `SDLHost` as the surface. host_full compiles the same file. |
| Guest driver | `full/driver/host_full/main.swift` | Launches Focus the way `runRealApp` does (the `realapp_focus_browser_light` variant, 375x667 @2x, real AppDelegate) and runs the shared loop over the bridge. It draws the software keyboard (`_UIKeyboardChrome.renderCapture`) and writes a `state.json` per capture. |
| Build | `full/scripts/build_full.sh` | Built only where `/usr/include/SDL2/SDL.h` exists (the guest image has it). Links `-O` copies of OpenUIKit and OpenCoreGraphics; everything else keeps the `-Onone` objects. |

openhost's behaviour is unchanged. Every host_full-specific choice is a
`HostLoopHooks` field whose default is openhost's old behaviour: the render
function, a per-turn hook, Escape quitting, idle redraw (off by default) and
60 Hz run-loop turns between script steps (off by default).

## Gate

`uikit/scripts/linux_guest_host_verify.sh` runs at the end of
`linux_guest_realapp_verify.sh`, so `local_guest_verify.sh` now covers it. It
replays `uikit/fixtures/realapp/focus_host_script.json` twice under
`SDL_VIDEODRIVER=dummy`, then asserts on each capture's state and on the frames:

| t (s) | step | asserted |
|---|---|---|
| 0.5 | launch | URL field is first responder, keyboard up. This is Focus's own `applicationDidBecomeActive` behaviour. |
| 1.6 | tap the `<` cancel button | editing ends, keyboard down |
| 2.6 | tap the URL bar | editing, keyboard up |
| 3.3 | type `mozilla` | the field's text is `mozilla` |
| 4.2 | cancel | field cleared |
| 5.0 | tap the hamburger | menu shows Help and Settings |
| 6.0 | tap Settings | `SettingsViewController` presented in its navigation controller |
| 7.0 | tap Theme | `ThemeViewController` pushed |
| 8.0 | tap back | popped to Settings |
| 9.5 | tap Done | presentation dismissed |

The gate also checks that both runs wrote byte-identical files (10 PNGs and 10
state files), and that the frame changes at every step that changes the screen.
Wherever SDL2 is installed, a missing host_full fails the gate.

Verdict lines:

    FOCUS_REAL_APPDELEGATE_LAUNCHED root=BrowserViewController
    rendered 15 screens; existing screens byte-identical 14/14 (including Ledger)
    REAL-APP SCREEN VERIFIED ON LINUX
    GUEST HOST INTERACTION VERIFIED ON LINUX

## Port fixes the interactions needed (all in `uikit/Sources/OpenUIKit`)

1. **Target-action to non-NSObject Swift targets** (`UISelector.swift`).
   UIKit's `objc_msgSend` reaches `@objc` methods of any Swift class. Focus's
   `UIControlSubscription<…>` (Combine+UIControl) is a plain generic class, so
   none of its URL-bar button publishers fired. The fix sends through
   `class_getMethodImplementation`.
2. **`.menuActionTriggered` before a primary-action menu** (`UIButton.swift`).
   UIKit sends it before presenting the menu. Focus builds its hamburger menu in
   that handler, starting from `UIMenu(children: [])`.
3. **`dismiss(animated:)` on a child of a presented controller**
   (`UIPresentation.swift`). This dismisses that presentation, as UIKit
   documents. Focus's Settings Done button needs it.
4. **Views with non-finite frames are skipped** by `RenderPass` instead of
   trapping on `Int(NaN)`.

The 14 existing screens and the Focus browser fixture stayed byte-identical
with all four changes.

The guest also depends on two host-level behaviours:

- **Main-queue drain.** Focus activates its URL field from
  `DispatchQueue.main.async`, and nothing drained the host libdispatch main
  queue before.
- **Ink misses do not trap.** host_full sets `GlyphInkTable.logMisses` and
  draws unharvested glyphs with DejaVu, the same fallback ResourceIO uses. The
  misses are reported as `HOST_FULL_INK_MISSES`: 33 keys, mostly system-regular
  16 and 22 pt, which is the keyboard caps.

## What works and what does not

| interaction | status |
|---|---|
| Launch through the real AppDelegate | works |
| Tap the URL bar, keyboard appears (drawn software keyboard) | works |
| Typing from the Mac keyboard (SDL_TEXTINPUT, then the first responder) | works in the model: the field holds `mozilla`. **The glyphs are not drawn** (see below). |
| Cancel / dismiss the keyboard | works |
| Hamburger menu (Help, Settings) | works |
| Settings sheet, push Theme, back, Done | works |
| Tapping the on-screen keyboard's keys | does not work. `_UIKeyboardWindow` has user interaction disabled, so a tap there reaches the app. |
| The page itself | blank (no WebKit engine) |

**Known gap: the editing-mode URL bar collapses to a 40 pt field.** The field
lands at x 271, and its text canvas gets a NaN frame, so typed text is not
drawn. The gate prints this as a note and does not hide it. The cause is Auto
Layout, not the host:

- Focus's editing constraints contain required constraints that contradict
  each other. `rightBarViewLayoutGuide.trailing` is constrained to
  `cm.leading - 110`, to `>= cm.leading - 60`, and through the border to
  `cm.leading - 14`.
- Its `leftBarViewLayoutGuide` also carries a self-referential
  `leading == leading + 10`.
- The port drops the constraint added last, where iOS breaks a different one.
- The resulting solve sacrifices the guide's 40 pt width (priority 900).

In one ordering (Done's completion re-activating the bar) the solve comes out
right, with the field at 48..311. Fixing this means making the port choose the
same constraint to break as iOS. That is a change to the layout engine and was
out of scope here. `HOST_FULL_CONSTRAINTS_OF=URLBar HOST_FULL_LAYOUT_DUMP=1`
dumps the constraints and layout for whoever takes it on.

## Performance (measured, arm64 container on an M-series Mac)

| screen | render per frame | live frame rate | input to present |
|---|---|---|---|
| Home / keyboard, `-O` OpenUIKit | 40–200 ms | 6–8 fps (continuous because of the caret) | 115–190 ms (xdotool click to SDL present) |
| Settings sheet | 300–580 ms | about 2 fps | about 580 ms |
| Anything, `-Onone` objects (before this change) | 490–2030 ms | | |

- Settings renders with no layer caching (`cache hit/build/direct 0/0/0`).
- noVNC transport adds latency on top of these numbers. It was not measured.
- It is usable to click through, but it is not smooth. The next steps would
  be profiling the uncached Settings render and running the caret redraw at
  2 Hz instead of every loop turn.

## Risks

- ALLOW_PATHS covers `full/` and `scripts/ops/` paths. `build_full.sh` gains a
  background `-O` compile of OpenUIKit when SDL2 is present, which adds build
  time (it overlaps the other stages).
- The four OpenUIKit fixes change behaviour for every app. They move the port
  toward documented UIKit behaviour, and the conformance gate is the check.
- `guest_subject.py` now covers `full/sdlhost`.
- The interactive image is built from Ubuntu apt at first use, so it needs
  network access.

## Verification run (2026-09-22, after merging main 535694fa)

- `local_guest_verify.sh <worktree>`: rc=0. FOCUS_REAL_APPDELEGATE_LAUNCHED,
  14/14 byte-identical, REAL-APP SCREEN VERIFIED ON LINUX, GUEST HOST
  INTERACTION VERIFIED ON LINUX.
- `CHECK_ONLY=1 ALLOW_PATHS='^full/(sdlhost/|driver/host_full/|scripts/build_full\.sh$|focus-ios/guest_subject\.py$)|^scripts/ops/guest_interactive\.(sh|Dockerfile)$' agent_merge.sh agent/guest-interactive-host`:
  checks passed (CHECK_ONLY). This covered the guest route, the conformance
  apps against the committed goldens, and the Linux build.
