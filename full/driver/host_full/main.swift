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
//   uikit/Sources/openhost/RealAppHost.swift the launch (RealApp.swift's
//                                           window setup, kept alive), the
//                                           replay state and the loop hooks
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

// MARK: - Apps

/// The apps host_full can run: the RealAppScreen row whose geometry and root
/// factory it uses (uikit/Sources/openhost/RealAppHost.swift launches it).
let hostApps: [String: String] = [
    "focus": "realapp_focus_browser_light",
]

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

// HOST_FULL_BREAK_LOG=1: UIKit's "Will attempt to recover by breaking
// constraint" log, from the engine's own break decisions.
if hostEnv("HOST_FULL_BREAK_LOG") == "1" {
    func item(_ o: AnyObject?) -> String {
        guard let o else { return "nil" }
        let id = (o as? UIView)?.accessibilityIdentifier.map { "#" + $0 } ?? ""
        return "\(type(of: o))\(id)@\(UInt(bitPattern: ObjectIdentifier(o).hashValue) & 0xffffff)"
    }
    func describe(_ c: NSLayoutConstraint) -> String {
        let rel = c.relation == .equal ? "==" : c.relation == .lessThanOrEqual ? "<=" : ">="
        return "\(item(c.firstItem)).\(c.firstAttribute.rawValue) \(rel) \(item(c.secondItem)).\(c.secondAttribute.rawValue)"
            + " *\(c.multiplier) +\(c.constant) @\(c.priority.rawValue)"
    }
    OpenUIKitRuntime.constraintBreakObserver = { broken, set in
        hostWarn("HOST_FULL_BREAK \(describe(broken))")
        for c in set { hostWarn("    exclusive \(describe(c))") }
    }
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
    guard let row = hostApps[hostAppName] else {
        hostWarn("host_full: unknown app \"\(hostAppName)\" (available: \(hostApps.keys.sorted().joined(separator: ", ")))")
        hostExit(2)
    }
    guard let scene = launchRealAppHost(row: row, assets: hostAssets, phoneScale: realAppScale,
                                        sceneName: "\(hostAppName)_host") else {
        hostWarn("host_full: this build has no \(row) row (Blockzilla not compiled in?)")
        hostExit(2)
    }
    // stderr: unbuffered, so a launcher watching a pipe sees it at once.
    hostWarn("HOST_FULL_LAUNCHED app=\(hostAppName) root=\(type(of: scene.window.rootViewController!)) "
             + "window=\(fmt3(Double(scene.sizePt.width)))x\(fmt3(Double(scene.sizePt.height))) scale=\(fmt3(Double(scene.scale)))")
    // One run-loop turn also runs what the app queued on the main queue
    // (Focus activates its URL field from DispatchQueue.main.async).
    var hooks = realAppHostHooks(drainMainQueue: { _ = openui_sdl_host_v1_drain_main_queue() })

    if let scriptPath = hostScriptPath, let recordDir = hostRecordDir {
        guard let bytes = ResourceIO.readFile(scriptPath),
              let script = JSONValue.parse(bytes), script.objectValue != nil else {
            hostWarn("host_full: cannot read script \(scriptPath)")
            hostExit(2)
        }
        let (events, captures) = parseScript(script)
        hooks.didCapture = { file, t in
            let stem = file.hasSuffix(".png") ? String(file.dropLast(4)) : file
            try hostWrite(Array(hostJSONText(realAppHostState(scene, t: t)).utf8),
                          "\(recordDir)/\(stem).state.json")
            if hostEnv("HOST_FULL_LAYOUT_DUMP") == "1" {
                var views: [JSONValue] = []
                dumpLayout(scene.window, path: "", into: &views)
                try hostWrite(Array(hostJSONText(.array(views)).utf8),
                              "\(recordDir)/\(stem).layout.json")
                // Diagnostic: the installed constraints of views of the class
                // named by HOST_FULL_CONSTRAINTS_OF (e.g. URLBar).
                if let cls = hostEnv("HOST_FULL_CONSTRAINTS_OF") {
                    var lines: [String] = []
                    func name(_ o: AnyObject?) -> String {
                        guard let o else { return "nil" }
                        return "\(type(of: o))@\(UInt(bitPattern: ObjectIdentifier(o).hashValue) & 0xffff)"
                    }
                    func walk(_ v: UIView) {
                        if String(describing: type(of: v)) == cls {
                            for c in v.constraints {
                                lines.append("\(c.isActive ? "on " : "off") \(name(c.firstItem)).\(c.firstAttribute.rawValue) \(c.relation.rawValue) \(name(c.secondItem)).\(c.secondAttribute.rawValue) *\(c.multiplier) +\(c.constant) @\(c.priority.rawValue)")
                            }
                        }
                        v.subviews.forEach(walk)
                    }
                    walk(scene.window)
                    try hostWrite(Array(lines.joined(separator: "\n").utf8),
                                  "\(recordDir)/\(stem).constraints.txt")
                }
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
