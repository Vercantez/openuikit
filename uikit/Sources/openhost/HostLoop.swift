// Portable host loop. Owner: host module (M7).
//
// The part of the live host that does not care what opens the window: SDL
// events -> touches / text / editing keys / key commands, the dirty-flag frame
// loop, the scripted deterministic-clock replay and its capture timeline.
// It imports neither Foundation nor CSDL2, so the same file compiles into
//
//   - openhost (native ELF), where HostCore.swift's SDLHost -- CSDL2 direct --
//     is the surface, and
//   - host_full (the Darwin Mach-O guest under machorun, full/scripts/
//     build_full.sh), where full/sdlhost's bridge to libOpenSDLHost.so is the
//     surface.
//
// Everything a surface supplies is in `HostSurface`: raw SDL values in (key
// symbols and modifier bits exactly as SDL reports them, mouse positions in
// window points), a straight-alpha RGBA bitmap out, and SDL's clock. The
// translation of those values into UIKit calls lives here, once.

import OpenUIKit

// MARK: - Scene

struct HostScene {
    let name: String
    let sizePt: CGSize
    /// Backing scale for the rendered bitmap (scene "scale" unless
    /// overridden with --scale).
    let scale: CGFloat
    let window: UIWindow
    let container: UIView
    /// Latest (delay + duration) over the scene-declared animations; the
    /// live loop keeps redrawing at least until then.
    let sceneAnimationDeadline: Double
}

/// "1.234" (3 decimal places, no Foundation).
func fmt3(_ t: Double) -> String {
    let neg = t < 0
    let ms = Int((t.magnitude * 1000).rounded())
    var frac = "\(ms % 1000)"
    while frac.count < 3 { frac = "0" + frac }
    return "\(neg ? "-" : "")\(ms / 1000).\(frac)"
}

// MARK: - Surface

/// One input event, carrying SDL's own values (keycodes, KMOD_* bits, left
/// button = 1, positions in window points).
enum HostInputEvent {
    case quit
    case keyDown(sym: Int32, mods: UInt32)
    /// SDL_TEXTINPUT: committed UTF-8 (already composed).
    case text(String)
    case mouseDown(button: UInt8, at: CGPoint)
    case mouseMotion(at: CGPoint)
    case mouseUp(button: UInt8, at: CGPoint)
    /// Anything else SDL delivered (window events, key-up, wheel, ...).
    case other
}

/// What a host window provides. SDL semantics throughout: `ticks` is
/// SDL_GetTicks, the performance counter pair is SDL_GetPerformanceCounter /
/// SDL_GetPerformanceFrequency, `present` uploads the bitmap and composites
/// it over a white clear.
@MainActor
protocol HostSurface: AnyObject {
    func pollEvent() -> HostInputEvent?
    func present(_ bmp: Bitmap)
    func ticks() -> UInt32
    func performanceCounter() -> UInt64
    func performanceFrequency() -> UInt64
    func delay(milliseconds: UInt32)
    func startTextInput()
    func quit()
}

/// Per-host choices the loop itself does not make. The defaults are
/// openhost's behaviour; host_full overrides them.
struct HostLoopHooks {
    /// Draws one frame of the window. openhost: the window alone.
    var render: @MainActor (UIWindow, CGFloat) -> Bitmap = { window, scale in
        UIRenderer.render(window, scale: scale)
    }
    /// Runs at the top of every run-loop turn, before the clock is read
    /// (host_full drains the libdispatch main queue here).
    var beginTurn: @MainActor () -> Void = {}
    /// Escape quits the live loop (openhost). When false Escape is an
    /// ordinary key and only the window's close / Cmd-Q quit.
    var escapeQuits = true
    /// Called after a scripted capture's PNG is written: (file, t).
    var didCapture: @MainActor (String, Double) throws -> Void = { _, _ in }
    /// Live loop: redraw at least this often (seconds) even when nothing
    /// the loop can see is animating. nil (openhost): idle frames never
    /// render. host_full sets it because work the app queued on the main
    /// queue or on a Timer can change the screen without an input event.
    var idleRedrawInterval: Double? = nil
    /// Scripted replay: also turn the run loop at every 1/hz between script
    /// steps (beginTurn + tick, no render), the way a device's run loop
    /// keeps turning between touches. nil (openhost): the clock jumps from
    /// step to step. host_full sets 60 so a chain of main-queue blocks and
    /// Timers an app starts at launch has run before the next scripted touch.
    var scriptStepHz: Double? = nil
}

// MARK: - Key commands (M13)

/// Translate an SDL key press into UIKit's `(input, modifierFlags)` pair and
/// offer it to the responder chain's `keyCommands`. Returns true when a
/// command consumed it, which is the host's signal NOT to fall through to
/// text input — the same precedence UIKit gives key commands.
///
/// SDL keycodes are ASCII for the printable range; the arrows / escape /
/// return / tab / delete map onto `UIKeyCommand`'s own input constants.
@MainActor
func hostKeyCommand(sym: Int32, mods: UInt32, window: UIWindow) -> Bool {
    var flags: UIKeyModifierFlags = []
    if mods & 0x0003 != 0 { flags.insert(.shift) }       // KMOD_SHIFT
    if mods & 0x00C0 != 0 { flags.insert(.control) }     // KMOD_CTRL
    if mods & 0x0300 != 0 { flags.insert(.alternate) }   // KMOD_ALT
    if mods & 0x0C00 != 0 { flags.insert(.command) }     // KMOD_GUI
    let input: String
    switch sym {
    case 1073741903: input = UIKeyCommand.inputRightArrow
    case 1073741904: input = UIKeyCommand.inputLeftArrow
    case 1073741905: input = UIKeyCommand.inputDownArrow
    case 1073741906: input = UIKeyCommand.inputUpArrow
    case 27: input = UIKeyCommand.inputEscape
    case 13: input = UIKeyCommand.inputReturn
    case 9: input = UIKeyCommand.inputTab
    case 8: input = UIKeyCommand.inputDelete
    case 32...126:
        guard let scalar = Unicode.Scalar(UInt32(sym)) else { return false }
        input = String(Character(scalar))
    default:
        return false
    }
    return window.performKeyCommand(input: input, modifierFlags: flags)
}

// MARK: - Live interactive loop

@MainActor
func runLive(_ scene: HostScene, host: HostSurface, hooks: HostLoopHooks = HostLoopHooks()) {
    // App lifecycle (M12): the app is launched by now (buildAppScene ran
    // UIApplicationMain); it becomes ACTIVE once the first frame is on
    // screen, and terminates when the loop exits. Scene mode has no app
    // delegate, so these are no-ops there.
    defer {
        UIApplication.shared._hostWillTerminate()
        host.quit()
    }
    var becameActive = false

    let startTicks = host.ticks()
    var running = true
    var mouseDown = false
    var renderedFrames = 0
    var renderNanos: UInt64 = 0
    let perfFreq = host.performanceFrequency()

    // Dirty-flag rendering (M7.5): a frame is rendered only when something
    // can have changed —
    //   - an input event arrived (needsRender),
    //   - a finger is down (drag scrub / content-touch-delay highlight),
    //   - a scroll view is decelerating/bouncing,
    //   - a navigation transition is in flight,
    //   - a recorded UIView/UISwitch animation is still running
    //     (OpenUIKitRuntime.animationWorkDeadline, +0.1s slop so the final
    //     settled frame is always presented),
    //   - a UIView.animate completion handler is still queued (it fires on
    //     the clock and may change the hierarchy).
    // Idle frames render nothing and sleep.
    var needsRender = true // first frame renders unconditionally
    var lastRenderTime = 0.0

    func animationsActive(at now: Double) -> Bool {
        mouseDown
            || UIScrollView._hasActiveScrollAnimations
            || UINavigationController._hasActiveTransition
            || UIViewController._hasActiveSheetInteraction   // sheet release spring
            || UIView._hasPendingAnimationCompletions
            || UITextInputState._hasActiveCaret   // caret blink (M8 text input)
            || now <= OpenUIKitRuntime.animationWorkDeadline + 0.1
    }

    // Text input (M8): committed characters arrive via SDL_TEXTINPUT
    // (proper unicode composition); editing keys via SDL_KEYDOWN below.
    host.startTextInput()

    while running {
        hooks.beginTurn()
        var now = Double(host.ticks() &- startTicks) / 1000.0
        while let ev = host.pollEvent() {
            now = Double(host.ticks() &- startTicks) / 1000.0
            OpenUIKitRuntime.animationTime = now
            switch ev {
            case .quit:
                running = false
            case .keyDown(let sym, let mods):
                let cmdQ = sym == 113 /* q */ && (mods & 0x0C00) != 0 /* KMOD_GUI */
                if cmdQ || (hooks.escapeQuits && sym == 27 /* escape */) { running = false }
                // KEY COMMANDS first (M13). UIKit gives the responder chain's
                // UIKeyCommands the press before anything else sees it; only
                // an unclaimed press falls through to editing keys / text.
                if hostKeyCommand(sym: sym, mods: mods, window: scene.window) {
                    needsRender = true
                    continue
                }
                // Editing keys to the first responder (SDL keycodes).
                let key: UIKeyEventKey? = switch sym {
                case 8: .backspace          // SDLK_BACKSPACE
                case 13: .return            // SDLK_RETURN
                case 1073741903: .right     // SDLK_RIGHT
                case 1073741904: .left      // SDLK_LEFT
                case 1073741905: .down      // SDLK_DOWN
                case 1073741906: .up        // SDLK_UP
                default: nil
                }
                if let key {
                    scene.window.sendKey(key, timestamp: now)
                    needsRender = true
                }
            case .text(let str):
                if !str.isEmpty {
                    scene.window.sendText(str, timestamp: now)
                    needsRender = true
                }
            case .mouseDown(let button, let p) where button == 1:
                mouseDown = true
                scene.window.sendTouch(.began, at: p, timestamp: now)
                needsRender = true
            case .mouseMotion(let p) where mouseDown:
                scene.window.sendTouch(.moved, at: p, timestamp: now)
                needsRender = true
            case .mouseUp(let button, let p) where button == 1:
                mouseDown = false
                scene.window.sendTouch(.ended, at: p, timestamp: now)
                needsRender = true
            default:
                break
            }
        }
        if !running { break }

        now = Double(host.ticks() &- startTicks) / 1000.0
        OpenUIKitRuntime.animationTime = now
        scene.window.tick(timestamp: now)  // long-press style time advance

        if let interval = hooks.idleRedrawInterval, now - lastRenderTime >= interval {
            needsRender = true
        }
        if needsRender || animationsActive(at: now) {
            needsRender = false
            lastRenderTime = now
            let t0 = host.performanceCounter()
            // Layout before draw, like UIKit's commit: views added since the
            // last frame (e.g. a freshly pushed VC's screen) get their
            // layoutSubviews pass before they are first rendered.
            scene.window.layoutIfNeeded()
            let bmp = hooks.render(scene.window, scene.scale)
            renderNanos &+= (host.performanceCounter() &- t0)
            host.present(bmp)  // vsync paces the loop
            renderedFrames += 1
            if !becameActive {
                becameActive = true
                UIApplication.shared._hostDidBecomeActive()
            }
            if renderedFrames % 120 == 0 {
                let avgMs = Double(renderNanos) / Double(perfFreq) * 1000
                    / Double(renderedFrames)
                print("stats: \(renderedFrames) frames, avg render \(fmt3(avgMs)) ms")
            }
        } else {
            host.delay(milliseconds: 10)  // idle: nothing animating, no input
        }
    }
}

// MARK: - Scripted mode (deterministic clock, captured frames)

struct ScriptEvent {
    let t: Double
    let kind: String  // "down" | "move" | "up" | "text" | "key"
    let point: CGPoint          // down/move/up
    let string: String          // text
    let key: UIKeyEventKey?     // key
}

/// Parse the --script JSON: {"events": [{t, kind, x, y} |
/// {t, kind: "text", string} | {t, kind: "key", key: "backspace|left|
/// right|up|down|return"}...], "captures": [t...]}.
func parseScript(_ script: JSONValue) -> (events: [ScriptEvent], captures: [Double]) {
    let events: [ScriptEvent] = (script["events"]?.arrayValue ?? []).map { e in
        guard let j = e.objectValue,
              let t = j["t"]?.doubleValue,
              let kind = j["kind"]?.stringValue else {
            fatalError("bad script event (need {t, kind, ...})")
        }
        switch kind {
        case "down", "move", "up":
            guard let x = j["x"]?.doubleValue, let y = j["y"]?.doubleValue else {
                fatalError("bad script event (\(kind) needs x, y)")
            }
            return ScriptEvent(t: t, kind: kind,
                               point: CGPoint(x: CGFloat(x), y: CGFloat(y)),
                               string: "", key: nil)
        case "text":
            guard let s = j["string"]?.stringValue else {
                fatalError("bad script event (text needs \"string\")")
            }
            return ScriptEvent(t: t, kind: kind, point: .zero, string: s, key: nil)
        case "key":
            guard let k = j["key"]?.stringValue,
                  let key = UIKeyEventKey(rawValue: k) else {
                fatalError("bad script event (key needs \"key\": backspace|left|right|up|down|return)")
            }
            return ScriptEvent(t: t, kind: kind, point: .zero, string: "", key: key)
        default:
            fatalError("bad script event kind \"\(kind)\"")
        }
    }
    let captures = (script["captures"]?.arrayValue ?? []).compactMap { $0.doubleValue }
    guard !captures.isEmpty else { fatalError("script needs non-empty \"captures\"") }
    return (events, captures)
}

/// Drive the scripted event sequence against the live window under a
/// deterministic clock, capturing PNG frames at the listed times into
/// `outdir` (as "<scene>.t<ms>.png"). The window still opens and shows each
/// captured frame. `save` writes one file (bytes, path). Returns the capture
/// file names in timeline order.
@MainActor
func runScripted(_ scene: HostScene, events: [ScriptEvent], captures: [Double],
                 outdir: String, host: HostSurface,
                 hooks: HostLoopHooks = HostLoopHooks(),
                 save: ([UInt8], String) throws -> Void) throws -> [String] {
    defer {
        UIApplication.shared._hostWillTerminate()
        host.quit()
    }
    var becameActive = false

    // Merge into one timeline; at equal times events run before captures.
    enum Step { case event(ScriptEvent); case capture(Double) }
    var steps: [(t: Double, order: Int, seq: Int, step: Step)] = []
    for (i, e) in events.enumerated() { steps.append((e.t, 0, i, .event(e))) }
    for (i, t) in captures.enumerated() { steps.append((t, 1, i, .capture(t))) }
    steps.sort { ($0.t, $0.order, $0.seq) < ($1.t, $1.order, $1.seq) }

    var written: [String] = []
    var lastT = 0.0
    for entry in steps {
        if let hz = hooks.scriptStepHz, hz > 0 {
            // Integer frame indices (as ConformanceClock does) so the turn
            // times are the same on every run: frames strictly after the
            // previous step and strictly before this one.
            var frame = Int((lastT * hz).rounded(.down)) + 1
            while Double(frame) / hz < entry.t {
                let ft = Double(frame) / hz
                hooks.beginTurn()
                OpenUIKitRuntime.animationTime = ft
                scene.window.tick(timestamp: ft)
                frame += 1
            }
        }
        lastT = entry.t
        hooks.beginTurn()
        OpenUIKitRuntime.animationTime = entry.t
        scene.window.tick(timestamp: entry.t)
        // Keep the OS event queue drained so the window stays responsive.
        while host.pollEvent() != nil {}
        switch entry.step {
        case .event(let e):
            switch e.kind {
            case "text":
                scene.window.sendText(e.string, timestamp: e.t)
            case "key":
                scene.window.sendKey(e.key!, timestamp: e.t)
            default:
                let phase: UITouch.Phase = e.kind == "down" ? .began
                                         : e.kind == "move" ? .moved : .ended
                scene.window.sendTouch(phase, at: e.point, timestamp: e.t)
            }
        case .capture(let t):
            let t0 = host.performanceCounter()
            scene.window.layoutIfNeeded() // layout before draw (as in runLive)
            LayerBridge.debugCompositeHits = 0
            LayerBridge.debugCompositeBuilds = 0
            LayerBridge.debugDirectLayers = 0
            let bmp = hooks.render(scene.window, scene.scale)
            let ms = Double(host.performanceCounter() &- t0)
                / Double(host.performanceFrequency()) * 1000
            host.present(bmp)
            if !becameActive {
                becameActive = true
                UIApplication.shared._hostDidBecomeActive()
            }
            let file = "\(scene.name).\(captureSuffix(t)).png"
            try save(bmp.pngData(), "\(outdir)/\(file)")
            try hooks.didCapture(file, t)
            print("captured \(file) (render \(fmt3(ms)) ms, cache hit/build/direct "
                  + "\(LayerBridge.debugCompositeHits)/\(LayerBridge.debugCompositeBuilds)/\(LayerBridge.debugDirectLayers))")
            written.append(file)
        }
    }
    return written
}
