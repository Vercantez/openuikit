// host_full/main.swift -- host_full: the interactive host for the Mach-O guest.
//
// render_full launches Firefox Focus through its real AppDelegate and writes
// PNGs; host_full launches it the SAME way (RealApp.swift's variant table and
// window setup, the realapp_focus_browser_light row) and then runs it: SDL
// mouse and keyboard events become touches, text and editing keys, the run
// loop turns, and every frame is blitted to a real window.
//
// Pieces, all shared rather than forked:
//   uikit/Sources/openhost/HostLoop.swift   event translation, live loop,
//                                           scripted replay (openhost's own)
//   full/sdlhost/OpenSDLHostBridge.c        Darwin side of the window ABI
//   full/sdlhost/OpenSDLHost.c              Linux side: SDL window, events,
//                                           texture upload, main-queue drain
//   uikit/Sources/openrender/RealApp.swift  the variant table + geometry
//
//   host_full [--app focus] [--assets DIR]
//             [--script events.json --record outdir]
//
// Live mode opens the window and runs until it is closed (or Cmd-Q). With
// --script/--record it replays openhost's script format under the
// deterministic clock and writes <scene>.t<ms>.png plus a
// <scene>.t<ms>.state.json per capture (text fields, first responder,
// keyboard, presented controllers, visible labels).
//
// Like full/driver/main.swift this file does not import Foundation; file IO
// and the environment go through CPortableIO.

import COpenSDLHost
import CPortableIO
import OpenUIKit
import RealAppProbe

// MARK: - IO (the CPortableIO subset render_full's driver uses)

func hostWarn(_ message: String) { cpio_log_stderr(message) }

func hostExit(_ code: Int32) -> Never {
    cpio_exit(code)
    fatalError("cpio_exit returned")
}

func hostEnv(_ name: String) -> String? {
    guard let c = cpio_getenv(name) else { return nil }
    return String(cString: c)
}

struct HostIOError: Error { let path: String }

func hostWrite(_ bytes: [UInt8], _ path: String) throws {
    let ok = bytes.withUnsafeBufferPointer { buf in
        cpio_write_file(path, buf.baseAddress, bytes.count) != 0
    }
    if !ok { throw HostIOError(path: path) }
}

func hostJSONText(_ v: JSONValue) -> String {
    switch v {
    case .null: return "null"
    case .bool(let b): return b ? "true" : "false"
    case .number(let d):
        if !d.isFinite { return "null" }
        if d == d.rounded(), abs(d) < 1e15 { return String(Int64(d)) }
        return String(d)
    case .string(let s):
        var out = "\""
        for c in s.unicodeScalars {
            switch c {
            case "\"": out += "\\\""
            case "\\": out += "\\\\"
            case "\n": out += "\\n"
            case "\r": out += "\\r"
            case "\t": out += "\\t"
            default:
                if c.value < 0x20 {
                    let hex = String(c.value, radix: 16)
                    out += "\\u" + String(repeating: "0", count: 4 - hex.count) + hex
                } else {
                    out.unicodeScalars.append(c)
                }
            }
        }
        return out + "\""
    case .array(let a): return "[" + a.map(hostJSONText).joined(separator: ",") + "]"
    case .object(let o):
        return "{" + o.keys.sorted().map { "\(hostJSONText(.string($0))):\(hostJSONText(o[$0]!))" }
            .joined(separator: ",") + "}"
    }
}

// MARK: - The window, through libOpenSDLHost

@MainActor
final class GuestSDLSurface: HostSurface {
    let handle: UnsafeMutableRawPointer
    let pixelW: Int32
    let pixelH: Int32

    init(title: String, sizePt: CGSize, scale: CGFloat) {
        let ptW = Int32(sizePt.width), ptH = Int32(sizePt.height)
        pixelW = Int32((sizePt.width * scale).rounded())
        pixelH = Int32((sizePt.height * scale).rounded())
        guard let h = openui_sdl_host_v1_open(title, ptW, ptH, pixelW, pixelH) else {
            fatalError("host_full: cannot open the SDL window: "
                       + String(cString: openui_sdl_host_v1_last_error()))
        }
        handle = h
    }

    func pollEvent() -> HostInputEvent? {
        var e = openui_sdl_event_v1()
        guard openui_sdl_host_v1_poll(handle, &e) == 1 else { return nil }
        let p = CGPoint(x: CGFloat(e.x), y: CGFloat(e.y))
        switch e.kind {
        case OPENUI_SDL_EVENT_QUIT.rawValue:
            return .quit
        case OPENUI_SDL_EVENT_KEY_DOWN.rawValue:
            return .keyDown(sym: e.key_sym, mods: e.key_mods)
        case OPENUI_SDL_EVENT_TEXT.rawValue:
            let str = withUnsafeBytes(of: e.text) { buf -> String in
                String(decoding: buf.prefix { $0 != 0 }, as: UTF8.self)
            }
            return .text(str)
        case OPENUI_SDL_EVENT_MOUSE_DOWN.rawValue:
            return .mouseDown(button: UInt8(truncatingIfNeeded: e.button), at: p)
        case OPENUI_SDL_EVENT_MOUSE_MOTION.rawValue:
            return .mouseMotion(at: p)
        case OPENUI_SDL_EVENT_MOUSE_UP.rawValue:
            return .mouseUp(button: UInt8(truncatingIfNeeded: e.button), at: p)
        default:
            return .other
        }
    }

    func present(_ bmp: Bitmap) {
        precondition(bmp.width == Int(pixelW) && bmp.height == Int(pixelH),
                     "bitmap \(bmp.width)x\(bmp.height) != texture \(pixelW)x\(pixelH)")
        let rc = bmp.pixels.withUnsafeBufferPointer { buf in
            openui_sdl_host_v1_present(handle, buf.baseAddress, pixelW, pixelH, pixelW * 4)
        }
        if rc != 0 {
            hostWarn("host_full: present failed: " + String(cString: openui_sdl_host_v1_last_error()))
        }
    }

    func ticks() -> UInt32 { openui_sdl_host_v1_ticks() }
    func performanceCounter() -> UInt64 { openui_sdl_host_v1_performance_counter() }
    func performanceFrequency() -> UInt64 { openui_sdl_host_v1_performance_frequency() }
    func delay(milliseconds: UInt32) { openui_sdl_host_v1_delay(milliseconds) }
    func startTextInput() { openui_sdl_host_v1_start_text_input(handle) }
    func quit() { openui_sdl_host_v1_close(handle) }
}

// MARK: - Launch (RealApp.swift's realapp window setup, kept alive)

/// The apps host_full can run: the RealApp.swift variant whose geometry and
/// root factory it uses.
let hostApps: [String: String] = [
    "focus": "realapp_focus_browser_light",
]

var hostRetained: [AnyObject] = []

/// runRealApp's setup, step for step, minus the render: traits, assets and
/// nibs, the screen, a window at the variant's geometry with its safe area,
/// the real root (for Focus: FocusBrowserLaunch.makeRoot(), i.e. the real
/// AppDelegate through UIApplicationMain), appearance, layout.
@MainActor
func launchHostApp(_ app: String, assets: String) -> HostScene {
    guard let variantName = hostApps[app] else {
        let names = hostApps.keys.sorted().joined(separator: ", ")
        hostWarn("host_full: unknown app \"\(app)\" (available: \(names))")
        hostExit(2)
    }
    guard let variant = realAppVariants.first(where: { $0.name == variantName }) else {
        hostWarn("host_full: this build has no \(variantName) variant (Blockzilla not compiled in?)")
        hostExit(2)
    }
    RealAppScreen.installFocusBundleResourcesIfNeeded()
    didSeedFocusBundleResources = true
    let size = variant.windowSize
    let scale = variant.idiom == .pad ? variant.nativeScale : realAppScale
    Timer._reset()
    GlyphInkTable.windowCompositing = false
    OpenUIKitRuntime.systemFontCut = .iOS
    UIDevice.current.userInterfaceIdiom = variant.idiom
    OpenUIKitRuntime.assetCatalogIdiom = variant.idiom
    UITraitCollection.current = UITraitCollection(
        userInterfaceStyle: variant.style,
        displayScale: scale,
        preferredContentSizeCategory: variant.contentSizeCategory,
        userInterfaceIdiom: variant.idiom)
    RealAppScreen.configureAssets(directory: assets)
    var nibs = RealAppScreen.defaultNibsDirectory
    if assets.hasSuffix("/assets") {
        nibs = String(assets.dropLast(7)) + "/nibs"
    }
    RealAppScreen.configureNibs(directory: nibs)
    OpenUIKitRuntime.imageScreenScale = scale
    UIScreen.main._hostConfigure(bounds: CGRect(origin: .zero, size: size), scale: scale)

    let window = UIWindow(frame: CGRect(origin: .zero, size: size))
    window.backgroundColor = .black
    window._setSafeAreaInsets(variant.safeAreaInsets)
    window.overrideUserInterfaceStyle = variant.style
    let root = variant.makeRoot()
    window.rootViewController = root
    window.makeKeyAndVisible()
    if variant.presentsSheet {
        (root as? BackdropViewController)?.presentPickerNow()
    } else {
        root.beginAppearanceTransition(true, animated: false)
        root.endAppearanceTransition()
    }
    window.setNeedsLayout()
    window.layoutIfNeeded()
    hostRetained.append(window)
    hostRetained.append(root)
    print("HOST_FULL_LAUNCHED app=\(app) root=\(type(of: root)) "
          + "window=\(fmt3(Double(size.width)))x\(fmt3(Double(size.height))) scale=\(fmt3(Double(scale)))")
    return HostScene(name: "\(app)_host", sizePt: size, scale: scale,
                     window: window, container: root.view, sceneAnimationDeadline: 0)
}

// MARK: - Per-capture state (what the replay check asserts on)

@MainActor
func collectState(_ v: UIView, path: String, into fields: inout [JSONValue],
                  labels: inout [JSONValue], visible: Bool) {
    let shown = visible && !v.isHidden && v.alpha > 0.01
    if let tf = v as? UITextField {
        let r = tf.convert(tf.bounds, to: nil)
        fields.append(.object([
            "path": .string(path),
            "frameInWindow": .array([r.origin.x, r.origin.y, r.width, r.height]
                .map { .number((Double($0) * 1000).rounded() / 1000) }),
            "class": .string(String(describing: type(of: tf))),
            "text": .string(tf.text ?? ""),
            "placeholder": .string(tf.placeholder ?? ""),
            "isEditing": .bool(tf.isEditing),
            "isFirstResponder": .bool(tf.isFirstResponder),
            "visible": .bool(shown),
        ]))
    }
    if shown, let l = v as? UILabel, let t = l.text, !t.isEmpty {
        labels.append(.string(t))
    }
    if shown, let b = v as? UIButton, let t = b.currentTitle, !t.isEmpty {
        labels.append(.string(t))
    }
    for (i, sub) in v.subviews.enumerated() {
        collectState(sub, path: path.isEmpty ? "\(i)" : "\(path).\(i)",
                     into: &fields, labels: &labels, visible: shown)
    }
}

@MainActor
func hostState(_ scene: HostScene, t: Double) -> JSONValue {
    var fields: [JSONValue] = []
    var labels: [JSONValue] = []
    collectState(scene.window, path: "", into: &fields, labels: &labels, visible: true)
    var presented: [JSONValue] = []
    var vc = scene.window.rootViewController?.presentedViewController
    while let p = vc {
        presented.append(.string(String(describing: type(of: p))))
        if let nav = p as? UINavigationController, let top = nav.topViewController {
            presented.append(.string("top=" + String(describing: type(of: top))))
        }
        vc = p.presentedViewController
    }
    let responder = scene.window.firstResponder
    return .object([
        "t": .number(t),
        "firstResponder": responder.map { .string(String(describing: type(of: $0))) } ?? .null,
        "keyboardUp": .bool(responder is UIKeyInput),
        "keyboardOverlap": .number(Double(_UIKeyboardChrome.currentOverlap)),
        "textFields": .array(fields),
        "presented": .array(presented),
        "labels": .array(labels),
    ])
}

// MARK: - main

if let v = hostEnv("OPENUIKIT_BACKEND") {
    switch v {
    case "swift": OpenUIKitRuntime.renderBackend = .swift
    case "quartz": OpenUIKitRuntime.renderBackend = .quartz
    default: hostWarn("warning: ignoring unknown OPENUIKIT_BACKEND=\(v) (use swift|quartz)")
    }
}
if let v = hostEnv("OPENUIKIT_RESOURCE_ROOT") { OpenUIKitRuntime.resourceRoot = v }
if let v = hostEnv("OPENUIKIT_REALAPP_SCALE"), let s = Double(v), s > 0 { realAppScale = CGFloat(s) }

// Glyphs. The guest draws text from the harvested iOS ink tables and has no
// SF outline font, so render_full traps on a glyph the harvest lacks
// (OPENUIKIT_IOS_INK_MISS). A window the user types into cannot trap on the
// first unharvested key, so host_full records misses instead (reported as
// HOST_FULL_INK_MISSES when it exits) and draws them from a substitute
// outline face: DejaVu, the same fallback ResourceIO installs for packaged
// apps. Harvested glyphs, and every ASCII advance (font_metrics.json), are
// unchanged; only glyphs that would otherwise trap or vanish use the face.
GlyphInkTable.logMisses = true
let hostFallbackFontDir = hostEnv("OPENUIKIT_HOST_FALLBACK_FONT_DIR") ?? "/usr/share/fonts/truetype/dejavu"
if ResourceIO.readFile(hostFallbackFontDir + "/DejaVuSans.ttf") != nil {
    let regular = hostFallbackFontDir + "/DejaVuSans.ttf"
    let bold = ResourceIO.readFile(hostFallbackFontDir + "/DejaVuSans-Bold.ttf") != nil
        ? hostFallbackFontDir + "/DejaVuSans-Bold.ttf" : regular
    OpenUIKitRuntime.fontPaths = [
        "system": regular, "medium": bold, "semibold": bold,
        "bold": bold, "heavy": bold, "black": bold,
    ]
} else {
    hostWarn("host_full: no fallback face in \(hostFallbackFontDir); unharvested glyphs will be blank")
}

func reportInkMisses() {
    let missed = GlyphInkTable.missedKeys.sorted()
    print("HOST_FULL_INK_MISSES \(missed.count)" + (missed.isEmpty ? "" : ": " + missed.joined(separator: " ")))
}

let hostUsage = "usage: host_full [--app focus] [--assets DIR] [--script events.json --record outdir]"
var hostAppName = "focus"
var hostAssets = "/uikit/fixtures/realapp/assets"
var hostScriptPath: String? = nil
var hostRecordDir: String? = nil
var hostArgs = CommandLine.arguments.dropFirst().makeIterator()
while let arg = hostArgs.next() {
    switch arg {
    case "--app": guard let v = hostArgs.next() else { hostWarn(hostUsage); hostExit(2) }; hostAppName = v
    case "--assets": guard let v = hostArgs.next() else { hostWarn(hostUsage); hostExit(2) }; hostAssets = v
    case "--script": guard let v = hostArgs.next() else { hostWarn(hostUsage); hostExit(2) }; hostScriptPath = v
    case "--record": guard let v = hostArgs.next() else { hostWarn(hostUsage); hostExit(2) }; hostRecordDir = v
    case "-h", "--help": print(hostUsage); hostExit(0)
    default: hostWarn(hostUsage); hostExit(2)
    }
}
guard (hostScriptPath == nil) == (hostRecordDir == nil) else {
    hostWarn("--script and --record must be used together\n" + hostUsage)
    hostExit(2)
}

MainActor.assumeIsolated {
    let scene = launchHostApp(hostAppName, assets: hostAssets)
    var hooks = HostLoopHooks()
    // The software keyboard lives in its own window (UIKeyboardChrome.swift);
    // composite it the way the conformance captures do, so "keyboard up" is
    // on screen and not only in the responder chain.
    hooks.render = { window, scale in
        _UIKeyboardChrome.renderCapture(appWindow: window, scale: scale)
    }
    // One run-loop turn also runs what the app queued on the main queue
    // (Focus activates its URL field from DispatchQueue.main.async).
    hooks.beginTurn = { _ = openui_sdl_host_v1_drain_main_queue() }
    // Escape is a key for the app, not a quit shortcut.
    hooks.escapeQuits = false
    // Main-queue blocks and Timers can change the screen with no input.
    hooks.idleRedrawInterval = 0.5
    // Replays turn the run loop at 60 Hz between steps, like a device.
    hooks.scriptStepHz = 60

    if let scriptPath = hostScriptPath, let recordDir = hostRecordDir {
        guard let bytes = ResourceIO.readFile(scriptPath),
              let script = JSONValue.parse(bytes), script.objectValue != nil else {
            hostWarn("host_full: cannot read script \(scriptPath)")
            hostExit(2)
        }
        let (events, captures) = parseScript(script)
        hooks.didCapture = { file, t in
            let stem = file.hasSuffix(".png") ? String(file.dropLast(4)) : file
            try hostWrite(Array(hostJSONText(hostState(scene, t: t)).utf8),
                          "\(recordDir)/\(stem).state.json")
            if hostEnv("HOST_FULL_LAYOUT_DUMP") == "1" {
                var views: [JSONValue] = []
                dumpLayout(scene.window, path: "", into: &views)
                try hostWrite(Array(hostJSONText(.array(views)).utf8),
                              "\(recordDir)/\(stem).layout.json")
            }
        }
        let surface = GuestSDLSurface(title: "\(scene.name) [scripted]",
                                      sizePt: scene.sizePt, scale: scene.scale)
        do {
            let written = try runScripted(scene, events: events, captures: captures,
                                          outdir: recordDir, host: surface, hooks: hooks,
                                          save: hostWrite)
            print("recorded \(written.count) frames to \(recordDir)")
            reportInkMisses()
        } catch let e as HostIOError {
            hostWarn("host_full: cannot write \(e.path)")
            hostExit(1)
        } catch {
            hostWarn("host_full: \(error)")
            hostExit(1)
        }
        hostExit(0)
    }

    let surface = GuestSDLSurface(title: "Firefox Focus (OpenUIKit guest)",
                                  sizePt: scene.sizePt, scale: scene.scale)
    runLive(scene, host: surface, hooks: hooks)
    reportInkMisses()
    hostExit(0)
}
