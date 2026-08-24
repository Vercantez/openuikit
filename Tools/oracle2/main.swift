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
guard cliArgs.count >= 3, cliArgs[1] == "render" else {
    print("usage: oracle2 render <outdir> <scene.json>...")
    exit(1)
}
let outdir = cliArgs[2]
let sceneFiles = Array(cliArgs.dropFirst(3))
try! FileManager.default.createDirectory(atPath: outdir, withIntermediateDirectories: true)

// MARK: - Renderer

final class Renderer {
    let host: UIView          // rootViewController.view — scene containers are attached here
    var attempts = 0

    init(host: UIView) { self.host = host }

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
        wrapper.layoutIfNeeded()

        if spec.animations.isEmpty {
            // afterScreenUpdates: true flushes pending CA transactions so the
            // just-attached hierarchy is rendered by the server before capture.
            let img = Self.snapshot(wrapper, size: sceneSize, scale: spec.scale)
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
        wrapper.layer.speed = 0
        wrapper.layer.timeOffset = 0
        startAnimations(spec.animations, container: container, traits: spec.traits)
        CATransaction.flush()
        if ProcessInfo.processInfo.environment["ORACLE2_ANIM_DEBUG"] != nil {
            for a in spec.animations {
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

        renderer = Renderer(host: vc.view)
        renderer!.start()
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
DispatchQueue.main.asyncAfter(deadline: .now() + 60) {
    FileHandle.standardError.write(Data("oracle2: watchdog timeout\n".utf8))
    exit(3)
}

_ = UIApplicationMain(CommandLine.argc, CommandLine.unsafeArgv, nil, NSStringFromClass(AppDelegate.self))
