// Oracle v2: renders scene JSON files with REAL UIKit inside a REAL UIWindOW
// (Mac Catalyst app) via drawHierarchy(afterScreenUpdates: true).
//
// Why it exists: some controls (UISwitch — its thumb lives in a private
// layer-tree that only the render server draws) produce nothing through
// offscreen `layer.render(in:)`, which is what Tools/oracle (v1) uses.
// Scenes that need this path carry a top-level `"window": true` key.
//
// Scene building / layout dumping is shared with v1: Tools/oracle/SceneKit.swift
// is compiled into both binaries (see scripts/build_oracle2.sh).
//
// Usage (via the wrapper — the binary must live inside the .app bundle):
//   Tools/oracle2/run.sh render <outdir> <scene.json>...
//
// Notes:
// - Must run as a .app bundle (bare Catalyst binaries assert on missing
//   bundleIdentifier). Info.plist sets LSUIElement so no Dock icon appears;
//   the window still flashes briefly on screen — unavoidable, since the
//   whole point is that the render server composites it for real.
// - The window is only renderable once the render server has composited it;
//   we poll with a probe view until drawHierarchy stops returning blank.
import UIKit

// MARK: - CLI (parsed before UIApplicationMain; still works under it)

let cliArgs = CommandLine.arguments
guard cliArgs.count >= 3, cliArgs[1] == "render" || cliArgs[1] == "scroll" else {
    print("usage: oracle2 render <outdir> <scene.json>...")
    print("       oracle2 scroll <outdir> [discover]   (scroll-physics probe)")
    exit(1)
}
/// "scroll" runs the scroll-physics measurement probe (scrollprobe.swift)
/// instead of the scene renderer.
let scrollMode = cliArgs[1] == "scroll"
let outdir = cliArgs[2]
let sceneFiles = Array(cliArgs.dropFirst(3))
try! FileManager.default.createDirectory(atPath: outdir, withIntermediateDirectories: true)

// MARK: - Renderer

final class Renderer {
    let hostVC: UIViewController   // rootViewController — chrome scenes need real containment
    var host: UIView { hostVC.view }  // scene containers are attached here
    var attempts = 0

    init(hostVC: UIViewController) { self.hostVC = hostVC }

    /// drawHierarchy returns a blank image until the window has actually been
    /// composited by the render server. Poll a probe view until it draws.
    func start() {
        let probe = UIView(frame: CGRect(x: 0, y: 0, width: 8, height: 8))
        probe.backgroundColor = .red
        host.addSubview(probe)
        let img = Self.snapshot(probe, size: probe.bounds.size, scale: 1)
        // Also require the ACTIVE appearance: an inactive Catalyst window
        // desaturates dynamic tints (UISwitch default on-track goes gray),
        // which does not match iOS ground truth. AppDelegate activates the
        // app via the AppKit bridge; wait for the trait to land.
        let live = Self.isNonBlank(img) && host.traitCollection.activeAppearance == .active
        probe.removeFromSuperview()
        if live {
            renderAll()
            return
        }
        attempts += 1
        if attempts > 100 {   // ~5s
            FileHandle.standardError.write(Data("oracle2: window never became renderable (probe stayed blank)\n".utf8))
            exit(2)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { self.start() }
    }

    static func snapshot(_ view: UIView, size: CGSize, scale: CGFloat) -> UIImage {
        let fmt = UIGraphicsImageRendererFormat()
        fmt.scale = scale
        fmt.opaque = false
        return UIGraphicsImageRenderer(size: size, format: fmt).image { _ in
            view.drawHierarchy(in: CGRect(origin: .zero, size: size), afterScreenUpdates: true)
        }
    }

    static func isNonBlank(_ img: UIImage) -> Bool {
        guard let cg = img.cgImage, let data = cg.dataProvider?.data as Data? else { return false }
        return data.contains { $0 != 0 }
    }

    func renderAll() {
        var failures = 0
        for file in sceneFiles {
            do { try renderOne(file: file) }
            catch { print("FAIL \(file): \(error)"); failures += 1 }
        }
        exit(failures == 0 ? 0 : 1)
    }

    func renderOne(file: String) throws {
        let spec = try loadScene(file: file)
        // Chrome scenes (spec v5) build real child view controllers against
        // the live host VC and may register post-attach actions.
        oracleHostViewController = hostVC
        oracleChildControllers = []
        oraclePostAttachActions = []
        oracleNeedsSettle = false
        defer {
            for c in oracleChildControllers {
                c.willMove(toParent: nil)
                c.view.removeFromSuperview()
                c.removeFromParent()
            }
            oracleChildControllers = []
            oraclePostAttachActions = []
            oracleNeedsSettle = false
        }
        let container = buildContainer(spec)

        // Layout dump EXACTLY like v1: same code, same moment (pre-attach).
        try writeLayoutDump(container, spec: spec, outdir: outdir)

        // The container keeps frame (0,0,0,0) (see the quirk note in
        // SceneKit.buildContainer) — its subviews still composite because
        // nothing clips. Wrap it in a transparent scene-sized view and
        // snapshot the wrapper, mirroring v1's renderer-sized context.
        let sceneSize = CGSize(width: spec.width, height: spec.height)
        let wrapper = UIView(frame: CGRect(origin: .zero, size: sceneSize))
        wrapper.backgroundColor = nil
        wrapper.overrideUserInterfaceStyle = spec.style
        wrapper.addSubview(container)
        host.addSubview(wrapper)
        // Chrome scenes: keep the scene OUT of the Catalyst window's top
        // safe-area intrusion (~41 pt with the hidden titlebar) — otherwise
        // the nav/tab bars lay out against Mac window chrome that has no
        // iOS counterpart. Position only; the snapshot is wrapper-relative.
        if oracleNeedsSettle {
            wrapper.frame.origin.y = host.safeAreaInsets.top
        }
        wrapper.layoutIfNeeded()

        if spec.animations.isEmpty {
            // Chrome scenes (spec v5): let the window settle so child-VC
            // appearance callbacks fire and bar materials resolve, then run
            // post-attach actions (e.g. the large-title collapse offset,
            // which the nav bar only honors while live) and settle again.
            if oracleNeedsSettle || !oraclePostAttachActions.isEmpty || spec.modal != nil {
                RunLoop.current.run(until: Date().addingTimeInterval(0.3))
                for action in oraclePostAttachActions { action() }
                wrapper.layoutIfNeeded()
                RunLoop.current.run(until: Date().addingTimeInterval(0.3))
            }
            if ProcessInfo.processInfo.environment["ORACLE2_CHROME_DEBUG"] != nil {
                print("host.safeAreaInsets=\(host.safeAreaInsets) wrapper.frame=\(wrapper.frame)")
                func walkS(_ v: UIView) {
                    if let s = v as? UIScrollView {
                        print("scroll offset=\(s.contentOffset) adjInset=\(s.adjustedContentInset) inset=\(s.contentInset) safe=\(s.safeAreaInsets)")
                    }
                    for sub in v.subviews { walkS(sub) }
                }
                walkS(wrapper)
                func walk(_ v: UIView, _ depth: Int) {
                    let cls = NSStringFromClass(type(of: v))
                    var extra = ""
                    if let l = v as? UILabel { extra = " text=\"\(l.text ?? "")\" font=\(l.font.pointSize)/\(l.font.fontName)" }
                    print(String(repeating: "  ", count: depth) + "\(cls) frame=\(v.frame) alpha=\(v.alpha) hidden=\(v.isHidden)\(extra)")
                    for s in v.subviews { walk(s, depth + 1) }
                }
                walk(wrapper, 0)
            }
            let img: UIImage
            if let modal = spec.modal {
                // Present a real pageSheet and capture the WHOLE WINDOW —
                // the presentation (dimming + sheet) lives at window level,
                // outside the wrapper. Scene size must equal the window size.
                let win = host.window!
                if win.bounds.size != sceneSize {
                    print("warning: modal scene \(spec.name) size \(sceneSize) != window \(win.bounds.size)")
                }
                // Catalyst presents pageSheet in a bridged AppKit sheet
                // window in regular width — force compact so the sheet is an
                // in-window iOS-style presentation we can capture.
                win.traitOverrides.horizontalSizeClass = .compact
                defer { win.traitOverrides.remove(UITraitHorizontalSizeClass.self) }
                let vc = UIViewController()
                let content = buildView(modal["content"] as! JSON,
                                        scale: spec.scale, traits: spec.traits)
                content.frame = vc.view.bounds
                content.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                vc.view.backgroundColor = UIColor.systemBackground.resolvedColor(with: spec.traits)
                vc.view.addSubview(content)
                vc.modalPresentationStyle = .pageSheet
                hostVC.present(vc, animated: false)
                // Settle: presentation transaction + dimming must be composited.
                RunLoop.current.run(until: Date().addingTimeInterval(0.5))
                if ProcessInfo.processInfo.environment["ORACLE2_CHROME_DEBUG"] != nil {
                    print("presented=\(String(describing: hostVC.presentedViewController)) sheetView.window=\(String(describing: vc.viewIfLoaded?.window)) hostWindow=\(win)")
                    for s in win.subviews { print("win sub: \(NSStringFromClass(type(of: s))) frame=\(s.frame)") }
                    if let pc = vc.presentationController {
                        print("presentationController=\(NSStringFromClass(type(of: pc))) containerView=\(String(describing: pc.containerView))")
                    }
                    if let bw = vc.viewIfLoaded?.window, bw !== win {
                        let bimg = Self.snapshot(bw, size: bw.bounds.size, scale: spec.scale)
                        try? bimg.pngData()!.write(to: URL(fileURLWithPath: "\(outdir)/DEBUG_bridged.png"))
                        func walk(_ v: UIView, _ d: Int) {
                            print(String(repeating: "  ", count: d) + "\(NSStringFromClass(type(of: v))) frame=\(v.frame) alpha=\(v.alpha)")
                            if d < 4 { for s in v.subviews { walk(s, d + 1) } }
                        }
                        walk(bw, 0)
                    }
                }
                img = Self.snapshot(win, size: sceneSize, scale: spec.scale)
                vc.dismiss(animated: false)
                RunLoop.current.run(until: Date().addingTimeInterval(0.3))
            } else {
                // afterScreenUpdates: true flushes pending CA transactions so
                // the just-attached hierarchy is rendered by the server
                // before capture.
                img = Self.snapshot(wrapper, size: sceneSize, scale: spec.scale)
            }
            wrapper.removeFromSuperview()
            try img.pngData()!.write(to: URL(fileURLWithPath: "\(outdir)/\(spec.name).png"))
            print("rendered \(spec.name)")
            return
        }

        // Animation capture (scene spec v3) — deterministic, no wall clock:
        // 1. FREEZE the scene's animation clock before anything is committed:
        //    wrapper.layer.speed = 0 pins every descendant's local time to
        //    wrapper.layer.timeOffset (convertTime: local = (parent - begin)
        //    * speed + timeOffset = timeOffset, inherited by children with
        //    speed 1 / beginTime 0). CACurrentMediaTime() cancels out of the
        //    math entirely, so two runs are byte-identical.
        // 2. Start REAL UIView.animate with the JSON's changes. At commit CA
        //    resolves each animation's beginTime against the frozen local
        //    timeline: beginTime = frozen-now (0) + delay. UIKit applies
        //    fillMode backwards for delayed animations, so t < delay shows
        //    the FROM state; t >= delay + duration shows the model (TO) state
        //    because with speed = 0 the completion/removal never fires and
        //    the ended animation no longer contributes (fillMode removed).
        // 3. For each capture time t: seek wrapper.layer.timeOffset = t and
        //    drawHierarchy(afterScreenUpdates: true) — that commits the seek
        //    and makes the render server composite the presentation tree at
        //    frozen time t before capturing.
        // switch-setOn scenes (spec v4) CANNOT be captured by the frozen
        // seek: probing shows the modern (iOS 26 liquid-glass) UISwitch is
        // a hybrid —
        //   * the blue "well" slide is a real CASpringAnimation (critical,
        //     duration-fit: off→on ωn=9.24/D≈1.0, on→off ωn=15.71/D≈0.588,
        //     both satisfying the ωD=9.2334 settling equation),
        //   * the on/off glyphs crossfade over 0.2 s,
        //   * but the THUMB is a `_UILiquidLensView` driven by a DISPLAY
        //     LINK: under a frozen layer clock it crawls on wall time and
        //     ignores the seek entirely.
        // Also, UIKit applies setOn(animated: true) WITHOUT any animation
        // for a hierarchy that has never been displayed — the window must
        // settle on screen for a few frames first (verified both ways).
        // So these scenes are sampled on the WALL clock: settle 0.3 s,
        // call the real setOn(animated: true), then snapshot when the
        // elapsed media time crosses each capture time. Frames carry a few
        // ms of scheduling jitter (unlike the byte-deterministic frozen
        // path) — the control pixel threshold absorbs it.
        if spec.animations.contains(where: { $0.kind == "switch-setOn" }) {
            guard spec.animations.allSatisfy({ $0.kind == "switch-setOn" }) else {
                fatalError("scene \(spec.name): switch-setOn cannot be mixed with uiview-animate entries")
            }
            RunLoop.current.run(until: Date().addingTimeInterval(0.3))
            let t0 = CACurrentMediaTime()
            startAnimations(spec.animations, container: container, traits: spec.traits)
            for t in spec.captureTimes {
                while CACurrentMediaTime() - t0 < t {
                    RunLoop.current.run(until: Date().addingTimeInterval(0.002))
                }
                let img = Self.snapshot(wrapper, size: sceneSize, scale: spec.scale)
                try img.pngData()!.write(
                    to: URL(fileURLWithPath: "\(outdir)/\(spec.name).\(captureSuffix(t)).png"))
            }
            wrapper.removeFromSuperview()
            print("rendered \(spec.name) (\(spec.captureTimes.count) frames, wall clock)")
            return
        }

        wrapper.layer.speed = 0
        wrapper.layer.timeOffset = 0
        startAnimations(spec.animations, container: container, traits: spec.traits)
        CATransaction.flush()
        if ProcessInfo.processInfo.environment["ORACLE2_ANIM_DEBUG"] != nil {
            func walk(_ l: CALayer, _ depth: Int) {
                let keys = l.animationKeys() ?? []
                let cls = NSStringFromClass(type(of: l))
                let delegateCls = l.delegate.map { NSStringFromClass(type(of: $0)) } ?? "-"
                print(String(repeating: "  ", count: depth) + "\(cls) [\(delegateCls)] pos=\(l.position) anims=\(keys)")
                for k in keys {
                    let an = l.animation(forKey: k)!
                    print(String(repeating: "  ", count: depth) + "  * [\(k)] \(type(of: an)) beginTime=\(an.beginTime) dur=\(an.duration) fill=\(an.fillMode.rawValue) removed=\(an.isRemovedOnCompletion)")
                    if let ba = an as? CABasicAnimation {
                        print(String(repeating: "  ", count: depth) + "    from=\(String(describing: ba.fromValue)) to=\(String(describing: ba.toValue)) keyPath=\(String(describing: ba.keyPath)) additive=\(ba.isAdditive)")
                    }
                    if let sp = an as? CASpringAnimation {
                        print(String(repeating: "  ", count: depth) + "    spring mass=\(sp.mass) k=\(sp.stiffness) c=\(sp.damping) v0=\(sp.initialVelocity)")
                    }
                }
                for s in l.sublayers ?? [] { walk(s, depth + 1) }
            }
            for a in spec.animations where a.kind == "switch-setOn" {
                print("=== switch '\(a.target)' layer tree after flush ===")
                walk(viewAtPath(container, a.target).layer, 0)
            }
            for a in spec.animations where a.kind != "switch-setOn" {
                let layer = viewAtPath(container, a.target).layer
                print("target '\(a.target)' local time:", layer.convertTime(CACurrentMediaTime(), from: nil))
                for k in layer.animationKeys() ?? [] {
                    let an = layer.animation(forKey: k)!
                    print("  [\(k)] \(type(of: an)) beginTime=\(an.beginTime) duration=\(an.duration) fillMode=\(an.fillMode.rawValue) removed=\(an.isRemovedOnCompletion) tf=\(String(describing: (an as? CABasicAnimation)?.timingFunction))")
                    if let sp = an as? CASpringAnimation {
                        print("    spring mass=\(sp.mass) stiffness=\(sp.stiffness) damping=\(sp.damping) initialVelocity=\(sp.initialVelocity) settlingDuration=\(sp.settlingDuration)")
                    }
                }
            }
        }
        for t in spec.captureTimes {
            wrapper.layer.timeOffset = t
            let img = Self.snapshot(wrapper, size: sceneSize, scale: spec.scale)
            try img.pngData()!.write(
                to: URL(fileURLWithPath: "\(outdir)/\(spec.name).\(captureSuffix(t)).png"))
        }
        wrapper.removeFromSuperview()
        print("rendered \(spec.name) (\(spec.captureTimes.count) frames)")
    }
}

// MARK: - App / scene lifecycle
// A window attached to a UIWindowScene is required: with the legacy
// (non-scene) lifecycle the window never gets composited and drawHierarchy
// stays blank (verified experimentally).

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    var renderer: Renderer?
    var scrollProbe: ScrollProbeRunner?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {
        guard let ws = scene as? UIWindowScene else { fatalError("expected UIWindowScene") }
        // Keep the (briefly visible) window small but big enough for any scene.
        let winSize = CGSize(width: 700, height: 520)
        ws.sizeRestrictions?.minimumSize = winSize
        ws.sizeRestrictions?.maximumSize = winSize
        ws.titlebar?.titleVisibility = .hidden
        ws.titlebar?.toolbar = nil

        let win = UIWindow(windowScene: ws)
        window = win
        let vc = UIViewController()
        vc.view.backgroundColor = .clear
        win.rootViewController = vc
        win.makeKeyAndVisible()

        // Catalyst: an LSUIElement app never activates on its own, and an
        // inactive window renders controls with the inactive (desaturated)
        // appearance. Activate via the AppKit bridge (briefly steals focus —
        // unavoidable for correct active-appearance ground truth).
        if let nsAppClass = NSClassFromString("NSApplication") as? NSObject.Type,
           let nsApp = nsAppClass.value(forKey: "sharedApplication") as? NSObject {
            _ = nsApp.perform(NSSelectorFromString("activateIgnoringOtherApps:"), with: true)
        }

        if scrollMode {
            scrollProbe = ScrollProbeRunner(
                host: vc.view, outdir: outdir,
                mode: sceneFiles.first ?? "full")
            scrollProbe!.start()
        } else {
            renderer = Renderer(hostVC: vc)
            renderer!.start()
        }
    }
}

class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     configurationForConnecting connectingSceneSession: UISceneSession,
                     options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        let cfg = UISceneConfiguration(name: "oracle2", sessionRole: connectingSceneSession.role)
        cfg.delegateClass = SceneDelegate.self
        return cfg
    }
}

// Watchdog: never leave a stray window on the user's screen.
// (The scroll probe runs many real-time gestures — give it longer.)
DispatchQueue.main.asyncAfter(deadline: .now() + (scrollMode ? 300 : 60)) {
    FileHandle.standardError.write(Data("oracle2: watchdog timeout\n".utf8))
    exit(3)
}

_ = UIApplicationMain(CommandLine.argc, CommandLine.unsafeArgv, nil, NSStringFromClass(AppDelegate.self))
