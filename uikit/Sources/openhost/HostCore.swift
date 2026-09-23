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
// The event translation, the live loop and the scripted replay live in
// HostLoop.swift (no CSDL2, no Foundation) so the Mach-O guest host
// (full/sdlhost, `host_full`) compiles the same code; this file keeps the
// SDL window itself (`SDLHost`, the `HostSurface` openhost uses) and the
// scene builders.
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

/// Build the scene into a live UIWindow. Mirrors runScene's build path
/// (traits, style, window glyph masks) with one deliberate divergence: the
/// root view gets the FULL scene frame. openrender reproduces the oracle's
/// root-frame quirk (root stays 0x0, background never draws) for golden
/// parity; a live host needs the root hit-testable — UIKit prunes subviews
/// outside their parent's bounds, so a 0x0 root would swallow every touch.
@MainActor
func buildHostScene(_ scene: JSONValue, scaleOverride: CGFloat?,
                    warn: (String) -> Void) -> HostScene {
    guard let name = scene["name"]?.stringValue else { fatalError("scene missing name") }
    guard let sz = numArray(scene["size"]), sz.count == 2 else { fatalError("scene missing size") }
    let scale = scaleOverride ?? (num(scene["scale"]) ?? 2)
    let style: UIUserInterfaceStyle = scene["style"]?.stringValue == "dark" ? .dark : .light
    GlyphInkTable.windowCompositing = scene["window"]?.boolValue ?? false
    UITraitCollection.current = UITraitCollection(userInterfaceStyle: style,
                                                  displayScale: scale)
    // UIScreen reports the surface this host actually opens (M12).
    UIScreen.main._hostConfigure(
        bounds: CGRect(x: 0, y: 0, width: sz[0], height: sz[1]), scale: scale)

    guard var rootJ = scene["root"]?.objectValue else { fatalError("scene missing root") }
    rootJ["frame"] = .array([.number(0), .number(0),
                             .number(Double(sz[0])), .number(Double(sz[1]))])

    let container = buildView(rootJ, scale: scale, warn: warn)
    container.overrideUserInterfaceStyle = style

    let window = UIWindow(frame: CGRect(x: 0, y: 0, width: sz[0], height: sz[1]))
    window.overrideUserInterfaceStyle = style
    window.addSubview(container)
    window.makeKeyAndVisible()
    window.setNeedsLayout()
    window.layoutIfNeeded()

    // Chrome scenes (spec v5 — M10, viewcontroller module): live offsets
    // after the real frames exist, then a top-level "modal" presents
    // ANIMATED at t = 0 in the live host so scripted captures can grab the
    // slide-up (openrender presents settled for golden parity).
    applyPendingChromeActions()
    if let modalJ = scene["modal"]?.objectValue {
        guard let contentJ = modalJ["content"]?.objectValue else {
            fatalError("scene \(name): \"modal\" needs a \"content\" view object")
        }
        let baseVC = UIViewController()
        baseVC.view = container
        let sheetVC = UIViewController()
        sheetVC.view = buildView(contentJ, scale: scale, warn: warn)
        baseVC.present(sheetVC, animated: true)
        sceneRetainedControllers.append(baseVC)
        sceneRetainedControllers.append(sheetVC)
    }

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

@MainActor
func describeControl(_ c: UIControl) -> String {
    if let sw = c as? UISwitch { return "class=UISwitch on=\(sw.isOn)" }
    if let b = c as? UIButton {
        return "class=UIButton title=\"\(b.currentTitle ?? "")\""
    }
    return "class=\(String(describing: type(of: c)))"
}

@MainActor
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

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

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
@MainActor
func buildNavDemoScene(scaleOverride: CGFloat?, largeTitles: Bool = false) -> HostScene {
    let scale = scaleOverride ?? 2
    let size = CGSize(width: 390, height: 700)
    GlyphInkTable.windowCompositing = false
    // OPENUIKIT_FORCE_IOS=1 runs the demo under the iOS cut, the same switch
    // `openrender` takes. Without it the demo renders macOS chrome, and the
    // iOS-only bar rules (large titles, the bar transition) never fire — so
    // the recording could not be compared with Tools/oracle2/navprobe's.
    OpenUIKitRuntime.systemFontCut = forceIOSCut ? .iOS : .macOS
    UITraitCollection.current = UITraitCollection(userInterfaceStyle: .light,
                                                  displayScale: scale)
    UIScreen.main._hostConfigure(bounds: CGRect(origin: .zero, size: size),
                                 scale: scale)
    let window = UIWindow(frame: UIScreen.main.bounds)
    let nav = UINavigationController(rootViewController: NavDemoRootVC())
    // --large-titles: the root shows its title large (iOS collapses it to
    // the inline title as a push transition runs).
    nav.navigationBar.prefersLargeTitles = largeTitles
    _navDemoNav = nav
    window.rootViewController = nav
    window.makeKeyAndVisible()
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
        // Headless CI (SDL_VIDEODRIVER=dummy) has no accelerated renderer;
        // fall back to whatever SDL offers. Captured frames come from the
        // Bitmap, not from this renderer, so the fallback cannot change them.
        guard let r = SDL_CreateRenderer(
                w, -1,
                SDL_RENDERER_ACCELERATED.rawValue | SDL_RENDERER_PRESENTVSYNC.rawValue)
            ?? SDL_CreateRenderer(w, -1, SDL_RENDERER_SOFTWARE.rawValue)
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

// MARK: - SDL surface (HostLoop.swift's HostSurface over CSDL2)

extension SDLHost: HostSurface {
    func pollEvent() -> HostInputEvent? {
        var ev = SDL_Event()
        guard SDL_PollEvent(&ev) != 0 else { return nil }
        switch ev.type {
        case SDL_QUIT.rawValue:
            return .quit
        case SDL_KEYDOWN.rawValue:
            return .keyDown(sym: ev.key.keysym.sym, mods: UInt32(ev.key.keysym.mod))
        case SDL_TEXTINPUT.rawValue:
            // ev.text.text: fixed UTF-8 C buffer (composed characters).
            let str = withUnsafeBytes(of: ev.text.text) { buf -> String in
                let bytes = buf.prefix { $0 != 0 }
                return String(decoding: bytes, as: UTF8.self)
            }
            return .text(str)
        case SDL_MOUSEBUTTONDOWN.rawValue:
            return .mouseDown(button: ev.button.button,
                              at: CGPoint(x: CGFloat(ev.button.x), y: CGFloat(ev.button.y)))
        case SDL_MOUSEMOTION.rawValue:
            return .mouseMotion(at: CGPoint(x: CGFloat(ev.motion.x), y: CGFloat(ev.motion.y)))
        case SDL_MOUSEBUTTONUP.rawValue:
            return .mouseUp(button: ev.button.button,
                            at: CGPoint(x: CGFloat(ev.button.x), y: CGFloat(ev.button.y)))
        default:
            return .other
        }
    }

    func ticks() -> UInt32 { SDL_GetTicks() }
    func performanceCounter() -> UInt64 { SDL_GetPerformanceCounter() }
    func performanceFrequency() -> UInt64 { SDL_GetPerformanceFrequency() }
    func delay(milliseconds: UInt32) { SDL_Delay(milliseconds) }
    func startTextInput() { SDL_StartTextInput() }
}

// MARK: - openhost entry points (HostLoop.swift over an SDL window)

@MainActor
func runLive(_ scene: HostScene) {
    let host = SDLHost(title: scene.name, sizePt: scene.sizePt, scale: scene.scale)
    runLive(scene, host: host)
}

@MainActor
func runScripted(_ scene: HostScene, events: [ScriptEvent], captures: [Double],
                 outdir: String) throws -> [String] {
    let host = SDLHost(title: "\(scene.name) [scripted]",
                       sizePt: scene.sizePt, scale: scene.scale)
    return try runScripted(scene, events: events, captures: captures, outdir: outdir,
                           host: host, save: { bytes, path in
                               try writeBinaryFile(bytes, path: path)
                           })
}
