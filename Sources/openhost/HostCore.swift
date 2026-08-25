// SDL2 live host core. Owner: host module (M7).
//
// This file must NOT import Foundation (same rule as SceneBuilder.swift:
// OpenUIKit's CG types would clash with Apple's CoreGraphics types that
// Foundation drags in on Darwin). Foundation-facing IO lives in main.swift
// and the shared SceneIO.swift.
//
// Scene building is shared with openrender: SceneBuilder.swift and
// SceneIO.swift are SYMLINKED into this target (Sources/openhost/*.swift ->
// ../openrender/*.swift), so both executables compile the exact same code
// and openrender stays byte-identical in behavior.
//
// Host model:
//   - A UIWindow (event module, M7) owns the scene; SDL mouse events are
//     forwarded as touches (down = began, drag = moved, up = ended).
//   - Clock: SDL_GetTicks (live mode) or the script timeline (scripted
//     mode) drives OpenUIKitRuntime.animationTime; t = 0 at start.
//   - Every frame renders through the standard pipeline (UIRenderer:
//     quartz backend + QZLayer compositor) into a Bitmap, blitted to an
//     SDL streaming texture. Bitmap bytes are straight-alpha RGBA in
//     memory order R,G,B,A == SDL_PIXELFORMAT_ABGR8888 on little-endian;
//     SDL_BLENDMODE_BLEND composites straight alpha over the white clear
//     (matching Tools/compare/compare.py's over-white compositing).

import OpenUIKit
import CSDL2

// MARK: - Scene setup (host variant of openrender's runScene)

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

/// Build the scene into a live UIWindow. Mirrors runScene's build path
/// (traits, style, window glyph masks) with one deliberate divergence: the
/// root view gets the FULL scene frame. openrender reproduces the oracle's
/// root-frame quirk (root stays 0x0, background never draws) for golden
/// parity; a live host needs the root hit-testable — UIKit prunes subviews
/// outside their parent's bounds, so a 0x0 root would swallow every touch.
func buildHostScene(_ scene: JSONValue, scaleOverride: CGFloat?,
                    warn: (String) -> Void) -> HostScene {
    guard let name = scene["name"]?.stringValue else { fatalError("scene missing name") }
    guard let sz = numArray(scene["size"]), sz.count == 2 else { fatalError("scene missing size") }
    let scale = scaleOverride ?? (num(scene["scale"]) ?? 2)
    let style: UIUserInterfaceStyle = scene["style"]?.stringValue == "dark" ? .dark : .light
    GlyphInkTable.windowCompositing = scene["window"]?.boolValue ?? false
    UITraitCollection.current = UITraitCollection(userInterfaceStyle: style,
                                                  displayScale: scale)

    guard var rootJ = scene["root"]?.objectValue else { fatalError("scene missing root") }
    rootJ["frame"] = .array([.number(0), .number(0),
                             .number(Double(sz[0])), .number(Double(sz[1]))])

    let container = buildView(rootJ, scale: scale, warn: warn)
    container.overrideUserInterfaceStyle = style

    let window = UIWindow(frame: CGRect(x: 0, y: 0, width: sz[0], height: sz[1]))
    window.overrideUserInterfaceStyle = style
    window.addSubview(container)
    window.setNeedsLayout()
    window.layoutIfNeeded()

    // Action logging: every scene-defined UIControl reports touchDown /
    // touchUpInside / valueChanged to stdout with its subview-index path.
    var registry: [ObjectIdentifier: String] = [:]
    sceneViewRegistry(container, rootJ, path: "", into: &registry)
    wireControlLogging(container, registry: registry)

    // Scene-declared animations (spec v3) start at t = 0 on the host clock.
    let animations = parseAnimations(scene)
    startAnimations(animations, container: container)
    let deadline = animations.map { a -> Double in
        a.kind == "switch-setOn" ? 1.1 : a.delay + a.duration
    }.max() ?? 0

    return HostScene(name: name, sizePt: CGSize(width: sz[0], height: sz[1]),
                     scale: scale, window: window, container: container,
                     sceneAnimationDeadline: deadline)
}

func describeControl(_ c: UIControl) -> String {
    if let sw = c as? UISwitch { return "class=UISwitch on=\(sw.isOn)" }
    if let b = c as? UIButton {
        return "class=UIButton title=\"\(b.currentTitle ?? "")\""
    }
    return "class=\(String(describing: type(of: c)))"
}

func wireControlLogging(_ v: UIView, registry: [ObjectIdentifier: String]) {
    if let c = v as? UIControl, let path = registry[ObjectIdentifier(c)] {
        c.addTarget(for: .touchDown) { control, _ in
            print("action: touchDown      t=\(fmt3(OpenUIKitRuntime.animationTime)) path=\(path) \(describeControl(control))")
        }
        c.addTarget(for: .touchUpInside) { control, _ in
            print("action: touchUpInside  t=\(fmt3(OpenUIKitRuntime.animationTime)) path=\(path) \(describeControl(control))")
        }
        c.addTarget(for: .valueChanged) { control, _ in
            print("action: valueChanged   t=\(fmt3(OpenUIKitRuntime.animationTime)) path=\(path) \(describeControl(control))")
        }
    }
    for sub in v.subviews { wireControlLogging(sub, registry: registry) }
}

/// "1.234" (3 decimal places, no Foundation).
func fmt3(_ t: Double) -> String {
    let neg = t < 0
    let ms = Int((t.magnitude * 1000).rounded())
    var frac = "\(ms % 1000)"
    while frac.count < 3 { frac = "0" + frac }
    return "\(neg ? "-" : "")\(ms / 1000).\(frac)"
}

// MARK: - Nav demo (M7.5 navigation): a UINavigationController-hosted app

/// Keeps the navigation controller alive (HostScene only holds views).
var _navDemoNav: UINavigationController?

/// A Settings-style disclosure row: label + "›" chevron + hairline,
/// highlight flash on touch, pushes a detail VC on tap.
final class NavDemoRow: UIControl {
    let titleLabel = UILabel()
    let chevron = UILabel()
    let hairline = UIView()

    init(title: String) {
        super.init(frame: .zero)
        backgroundColor = .secondarySystemGroupedBackground
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 17)
        titleLabel.textColor = .label
        chevron.text = "\u{203A}" // ›
        chevron.font = .systemFont(ofSize: 17, weight: .semibold)
        chevron.textColor = .systemGray2
        hairline.backgroundColor = .separator
        addSubview(titleLabel)
        addSubview(chevron)
        addSubview(hairline)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let t = titleLabel.intrinsicContentSize
        titleLabel.frame = CGRect(x: 16, y: (bounds.height - t.height) / 2,
                                  width: t.width, height: t.height)
        let c = chevron.intrinsicContentSize
        chevron.frame = CGRect(x: bounds.width - c.width - 16,
                               y: (bounds.height - c.height) / 2,
                               width: c.width, height: c.height)
        hairline.frame = CGRect(x: 16, y: bounds.height - 0.5,
                                width: bounds.width - 16, height: 0.5)
    }

    override func stateDidChange() {
        super.stateDidChange()
        backgroundColor = isHighlighted ? .systemGray4
                                        : .secondarySystemGroupedBackground
    }
}

final class NavDemoDetailVC: UIViewController {
    override func viewDidLoad() {
        view.backgroundColor = .systemGroupedBackground
        let card = UIView(frame: CGRect(x: 16, y: 20,
                                        width: view.bounds.width - 32, height: 120))
        card.backgroundColor = .secondarySystemGroupedBackground
        card.layer.cornerRadius = 10
        card.autoresizingMask = [.flexibleWidth]
        view.addSubview(card)
        let heading = UILabel()
        heading.text = title
        heading.font = .systemFont(ofSize: 20, weight: .semibold)
        heading.frame = CGRect(x: 16, y: 16, width: card.bounds.width - 32,
                               height: 24)
        card.addSubview(heading)
        let body = UILabel()
        body.text = "Pushed with the iOS slide transition."
        body.font = .systemFont(ofSize: 15)
        body.textColor = .secondaryLabel
        body.frame = CGRect(x: 16, y: 48, width: card.bounds.width - 32,
                            height: 20)
        card.addSubview(body)
    }
}

final class NavDemoRootVC: UIViewController {
    override func viewDidLoad() {
        title = "Settings"
        view.backgroundColor = .systemGroupedBackground
        let titles = ["General", "Display & Brightness", "About"]
        for (i, t) in titles.enumerated() {
            let row = NavDemoRow(title: t)
            row.frame = CGRect(x: 0, y: 20 + CGFloat(i) * 44,
                               width: view.bounds.width, height: 44)
            row.autoresizingMask = [.flexibleWidth]
            row.addTarget(for: .touchUpInside) { [weak self] control, _ in
                guard let self, let row = control as? NavDemoRow else { return }
                print("action: push           t=\(fmt3(OpenUIKitRuntime.animationTime)) row=\"\(row.titleLabel.text ?? "")\"")
                let detail = NavDemoDetailVC()
                detail.title = row.titleLabel.text
                self.navigationController?.pushViewController(detail, animated: true)
            }
            view.addSubview(row)
        }
    }
}

/// Build the navigation demo (openhost --nav-demo): a UINavigationController
/// with a Settings-style root, hosted in a live UIWindow. Push/pop run the
/// APP_FEEL transition (slide + parallax + scrim + edge shadow); the back
/// button and the left-edge swipe both pop.
func buildNavDemoScene(scaleOverride: CGFloat?) -> HostScene {
    let scale = scaleOverride ?? 2
    let size = CGSize(width: 390, height: 700)
    GlyphInkTable.windowCompositing = false
    UITraitCollection.current = UITraitCollection(userInterfaceStyle: .light,
                                                  displayScale: scale)
    let window = UIWindow(frame: CGRect(origin: .zero, size: size))
    let nav = UINavigationController(rootViewController: NavDemoRootVC())
    _navDemoNav = nav
    nav.view.frame = window.bounds
    window.addSubview(nav.view)
    window.setNeedsLayout()
    window.layoutIfNeeded()
    return HostScene(name: "nav_demo", sizePt: size, scale: scale,
                     window: window, container: nav.view,
                     sceneAnimationDeadline: 0)
}

// MARK: - SDL host window

final class SDLHost {
    let sdlWindow: OpaquePointer
    let renderer: OpaquePointer
    let texture: OpaquePointer
    let pixelW: Int32
    let pixelH: Int32

    /// Window is created at the scene's POINT size (SDL logical/screen
    /// coordinates; on a HiDPI display SDL_WINDOW_ALLOW_HIGHDPI gives the
    /// drawable 2x pixels). The texture holds the rendered bitmap at the
    /// scene scale; SDL_RenderSetLogicalSize keeps mouse coordinates in
    /// scene points regardless of the display's pixel density.
    init(title: String, sizePt: CGSize, scale: CGFloat) {
        SDL_SetMainReady()
        guard SDL_Init(UInt32(SDL_INIT_VIDEO)) == 0 else {
            fatalError("SDL_Init failed: \(String(cString: SDL_GetError()))")
        }
        let ptW = Int32(sizePt.width), ptH = Int32(sizePt.height)
        pixelW = Int32((sizePt.width * scale).rounded())
        pixelH = Int32((sizePt.height * scale).rounded())
        let centered: Int32 = 0x2FFF0000  // SDL_WINDOWPOS_CENTERED
        guard let w = SDL_CreateWindow(
            title, centered, centered, ptW, ptH,
            SDL_WINDOW_ALLOW_HIGHDPI.rawValue | SDL_WINDOW_SHOWN.rawValue)
        else { fatalError("SDL_CreateWindow failed: \(String(cString: SDL_GetError()))") }
        sdlWindow = w
        guard let r = SDL_CreateRenderer(
            w, -1,
            SDL_RENDERER_ACCELERATED.rawValue | SDL_RENDERER_PRESENTVSYNC.rawValue)
        else { fatalError("SDL_CreateRenderer failed: \(String(cString: SDL_GetError()))") }
        renderer = r
        SDL_RenderSetLogicalSize(r, ptW, ptH)
        // ABGR8888 packed == R,G,B,A byte order on little-endian — exactly
        // the Bitmap layout (straight-alpha RGBA8).
        guard let t = SDL_CreateTexture(
            r, SDL_PIXELFORMAT_ABGR8888.rawValue,
            Int32(SDL_TEXTUREACCESS_STREAMING.rawValue), pixelW, pixelH)
        else { fatalError("SDL_CreateTexture failed: \(String(cString: SDL_GetError()))") }
        texture = t
        SDL_SetTextureBlendMode(t, SDL_BLENDMODE_BLEND)
    }

    /// Upload the bitmap and present it composited over a white clear
    /// (straight-alpha blend — same convention as compare.py).
    func present(_ bmp: Bitmap) {
        precondition(bmp.width == Int(pixelW) && bmp.height == Int(pixelH),
                     "bitmap \(bmp.width)x\(bmp.height) != texture \(pixelW)x\(pixelH)")
        bmp.pixels.withUnsafeBytes { buf in
            _ = SDL_UpdateTexture(texture, nil, buf.baseAddress, Int32(bmp.width * 4))
        }
        SDL_SetRenderDrawColor(renderer, 255, 255, 255, 255)
        SDL_RenderClear(renderer)
        SDL_RenderCopy(renderer, texture, nil, nil)
        SDL_RenderPresent(renderer)
    }

    func quit() {
        SDL_DestroyTexture(texture)
        SDL_DestroyRenderer(renderer)
        SDL_DestroyWindow(sdlWindow)
        SDL_Quit()
    }
}

// MARK: - Live interactive loop

func runLive(_ scene: HostScene) {
    let host = SDLHost(title: scene.name, sizePt: scene.sizePt, scale: scene.scale)
    defer { host.quit() }

    let startTicks = SDL_GetTicks()
    var running = true
    var mouseDown = false
    // Redraw-until deadline: scene animations first, extended 1.5 s past
    // every input event (covers the longest control animation — the
    // UISwitch track spring settles in < 1.0 s). Idle frames skip the
    // render entirely.
    var renderUntil = scene.sceneAnimationDeadline + 0.5
    var renderedFrames = 0
    var renderNanos: UInt64 = 0
    let perfFreq = SDL_GetPerformanceFrequency()

    // First frame renders unconditionally.
    var needsRender = true

    while running {
        var ev = SDL_Event()
        var now = Double(SDL_GetTicks() &- startTicks) / 1000.0
        while SDL_PollEvent(&ev) != 0 {
            now = Double(SDL_GetTicks() &- startTicks) / 1000.0
            OpenUIKitRuntime.animationTime = now
            switch ev.type {
            case SDL_QUIT.rawValue:
                running = false
            case SDL_KEYDOWN.rawValue:
                let sym = ev.key.keysym.sym
                let mods = UInt32(ev.key.keysym.mod)
                let cmdQ = sym == 113 /* q */ && (mods & 0x0C00) != 0 /* KMOD_GUI */
                if cmdQ || sym == 27 /* escape */ { running = false }
            case SDL_MOUSEBUTTONDOWN.rawValue where ev.button.button == 1:
                mouseDown = true
                let p = CGPoint(x: CGFloat(ev.button.x), y: CGFloat(ev.button.y))
                scene.window.sendTouch(.began, at: p, timestamp: now)
                renderUntil = now + 1.5
                needsRender = true
            case SDL_MOUSEMOTION.rawValue where mouseDown:
                let p = CGPoint(x: CGFloat(ev.motion.x), y: CGFloat(ev.motion.y))
                scene.window.sendTouch(.moved, at: p, timestamp: now)
                renderUntil = now + 1.5
                needsRender = true
            case SDL_MOUSEBUTTONUP.rawValue where ev.button.button == 1:
                mouseDown = false
                let p = CGPoint(x: CGFloat(ev.button.x), y: CGFloat(ev.button.y))
                scene.window.sendTouch(.ended, at: p, timestamp: now)
                renderUntil = now + 1.5
                needsRender = true
            default:
                break
            }
        }
        if !running { break }

        now = Double(SDL_GetTicks() &- startTicks) / 1000.0
        OpenUIKitRuntime.animationTime = now
        scene.window.tick(timestamp: now)  // long-press style time advance

        if needsRender || now <= renderUntil {
            needsRender = false
            let t0 = SDL_GetPerformanceCounter()
            let bmp = UIRenderer.render(scene.window, scale: scene.scale)
            renderNanos &+= (SDL_GetPerformanceCounter() &- t0)
            host.present(bmp)  // vsync paces the loop
            renderedFrames += 1
            if renderedFrames % 120 == 0 {
                let avgMs = Double(renderNanos) / Double(perfFreq) * 1000
                    / Double(renderedFrames)
                print("stats: \(renderedFrames) frames, avg render \(fmt3(avgMs)) ms")
            }
        } else {
            SDL_Delay(10)  // idle: nothing animating, no input
        }
    }
}

// MARK: - Scripted mode (deterministic clock, captured frames)

struct ScriptEvent {
    let t: Double
    let kind: String  // "down" | "move" | "up"
    let point: CGPoint
}

/// Parse the --script JSON: {"events": [{t, kind, x, y}...],
/// "captures": [t...]}.
func parseScript(_ script: JSONValue) -> (events: [ScriptEvent], captures: [Double]) {
    let events: [ScriptEvent] = (script["events"]?.arrayValue ?? []).map { e in
        guard let j = e.objectValue,
              let t = j["t"]?.doubleValue,
              let kind = j["kind"]?.stringValue,
              let x = j["x"]?.doubleValue, let y = j["y"]?.doubleValue,
              ["down", "move", "up"].contains(kind) else {
            fatalError("bad script event (need {t, kind: down|move|up, x, y})")
        }
        return ScriptEvent(t: t, kind: kind,
                           point: CGPoint(x: CGFloat(x), y: CGFloat(y)))
    }
    let captures = (script["captures"]?.arrayValue ?? []).compactMap { $0.doubleValue }
    guard !captures.isEmpty else { fatalError("script needs non-empty \"captures\"") }
    return (events, captures)
}

/// Drive the scripted event sequence against the live window under a
/// deterministic clock, capturing PNG frames at the listed times into
/// `outdir` (as "<scene>.t<ms>.png"). The SDL window still opens and shows
/// each captured frame. Returns the capture file names in timeline order.
func runScripted(_ scene: HostScene, events: [ScriptEvent], captures: [Double],
                 outdir: String) throws -> [String] {
    let host = SDLHost(title: "\(scene.name) [scripted]",
                       sizePt: scene.sizePt, scale: scene.scale)
    defer { host.quit() }

    // Merge into one timeline; at equal times events run before captures.
    enum Step { case event(ScriptEvent); case capture(Double) }
    var steps: [(t: Double, order: Int, seq: Int, step: Step)] = []
    for (i, e) in events.enumerated() { steps.append((e.t, 0, i, .event(e))) }
    for (i, t) in captures.enumerated() { steps.append((t, 1, i, .capture(t))) }
    steps.sort { ($0.t, $0.order, $0.seq) < ($1.t, $1.order, $1.seq) }

    var written: [String] = []
    for entry in steps {
        OpenUIKitRuntime.animationTime = entry.t
        scene.window.tick(timestamp: entry.t)
        // Keep the OS event queue drained so the window stays responsive.
        var ev = SDL_Event()
        while SDL_PollEvent(&ev) != 0 {}
        switch entry.step {
        case .event(let e):
            let phase: UITouch.Phase = e.kind == "down" ? .began
                                     : e.kind == "move" ? .moved : .ended
            scene.window.sendTouch(phase, at: e.point, timestamp: e.t)
        case .capture(let t):
            let t0 = SDL_GetPerformanceCounter()
            let bmp = UIRenderer.render(scene.window, scale: scene.scale)
            let ms = Double(SDL_GetPerformanceCounter() &- t0)
                / Double(SDL_GetPerformanceFrequency()) * 1000
            host.present(bmp)
            let file = "\(scene.name).\(captureSuffix(t)).png"
            try writeBinaryFile(bmp.pngData(), path: "\(outdir)/\(file)")
            print("captured \(file) (render \(fmt3(ms)) ms)")
            written.append(file)
        }
    }
    return written
}
