// SimScene: iOS Simulator SCENE renderer (M10 chrome).
//
// Why it exists: Mac Catalyst cannot produce the iOS pageSheet presentation
// AT ALL — a presented .pageSheet is hosted in a bridged AppKit sheet window
// (_UIBridgedPresentationWindow) whose Mac chrome (corners/shadow/backdrop)
// is composited OUTSIDE UIKit, so neither oracle can capture the iOS look
// (dimmed base, rounded top corners, sheet inset from the top). Scenes with
// a top-level "modal" key are therefore rendered by REAL iOS UIKit in the
// headless iOS Simulator (iPhone 16, iOS 26) — the same route the M8 scroll
// physics goldens took (SimProbe).
//
// Contract: scene size must equal the device's portrait point size
// (iPhone 16: 393 x 852). The capture is the APP WINDOW only — the system
// status bar is SpringBoard's overlay and is not part of drawHierarchy, so
// goldens carry no clock/battery. Scene building / layout dumping is the
// same SceneKit.swift as both Mac oracles.
//
// Protocol (see scripts/render_sim_scenes.sh):
//   scenes IN:   <app container>/Documents/scenes/*.json
//   renders OUT: <app container>/Documents/out/<name>.png + .layout.json
//   completion:  Documents/out/DONE ("ok" or failure list); app exit(0)
import UIKit

let docsDir = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
let scenesDir = docsDir + "/scenes"
let outDir = docsDir + "/out"

final class SimSceneRenderer {
    let hostVC: UIViewController
    let window: UIWindow
    var host: UIView { hostVC.view }

    init(hostVC: UIViewController, window: UIWindow) {
        self.hostVC = hostVC
        self.window = window
    }

    func snapshot(_ view: UIView, size: CGSize, scale: CGFloat) -> UIImage {
        let fmt = UIGraphicsImageRendererFormat()
        fmt.scale = scale
        fmt.opaque = false
        return UIGraphicsImageRenderer(size: size, format: fmt).image { _ in
            view.drawHierarchy(in: CGRect(origin: .zero, size: size), afterScreenUpdates: true)
        }
    }

    func renderAll() {
        try? FileManager.default.createDirectory(atPath: outDir, withIntermediateDirectories: true)
        let files = ((try? FileManager.default.contentsOfDirectory(atPath: scenesDir)) ?? [])
            .filter { $0.hasSuffix(".json") }.sorted()
        var failures: [String] = []
        for f in files {
            do { try renderOne(file: scenesDir + "/" + f) }
            catch { failures.append("\(f): \(error)") }
        }
        let status = failures.isEmpty ? "ok" : failures.joined(separator: "\n")
        try? status.write(toFile: outDir + "/DONE", atomically: true, encoding: .utf8)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { exit(0) }
    }

    func renderOne(file: String) throws {
        let spec = try loadScene(file: file)
        guard spec.animations.isEmpty else {
            fatalError("scene \(spec.name): SimScene renders static scenes only")
        }
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
        }
        let container = buildContainer(spec)
        try writeLayoutDump(container, spec: spec, outdir: outDir)

        let sceneSize = CGSize(width: spec.width, height: spec.height)
        if window.bounds.size != sceneSize {
            print("warning: scene \(spec.name) size \(sceneSize) != device \(window.bounds.size)")
        }
        let wrapper = UIView(frame: CGRect(origin: .zero, size: sceneSize))
        wrapper.backgroundColor = nil
        wrapper.overrideUserInterfaceStyle = spec.style
        wrapper.addSubview(container)
        host.addSubview(wrapper)
        // Chrome scenes (spec v5.3): keep the scene OUT of the device's top
        // safe area, exactly like oracle2 does on Catalyst — otherwise a
        // hosted navigation controller lays its bar out below a 59 pt inset
        // that has no counterpart in the portable renderer, and the scene
        // would have to be device-sized. The capture stays wrapper-relative,
        // so the golden is unaffected apart from the shift.
        // Window-captured scenes (modal / alert) must NOT move — their
        // golden IS the window.
        if oracleNeedsSettle && spec.modal == nil && spec.alert == nil {
            wrapper.frame.origin.y = window.safeAreaInsets.top
        }
        wrapper.layoutIfNeeded()
        RunLoop.current.run(until: Date().addingTimeInterval(0.3))
        for action in oraclePostAttachActions { action() }
        wrapper.layoutIfNeeded()
        RunLoop.current.run(until: Date().addingTimeInterval(0.3))

        if ProcessInfo.processInfo.environment["SIMSCENE_DEBUG"] != nil {
            print("=== \(spec.name) tree (window safeArea \(window.safeAreaInsets)) ===")
            debugWalk(wrapper)
        }

        let img: UIImage
        if let modal = spec.modal {
            let vc = UIViewController()
            let content = buildView(modal["content"] as! JSON,
                                    scale: spec.scale, traits: spec.traits)
            content.frame = vc.view.bounds
            content.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            vc.view.backgroundColor = UIColor.systemBackground.resolvedColor(with: spec.traits)
            vc.view.addSubview(content)
            vc.modalPresentationStyle = .pageSheet
            vc.overrideUserInterfaceStyle = spec.style
            // Spec v5.1: "grabber": true -> prefersGrabberVisible. UIKit's
            // default is false, which is why the original modal_sheet golden
            // carries no grabber.
            if (modal["grabber"] as? Bool) == true {
                vc.sheetPresentationController?.prefersGrabberVisible = true
            }
            hostVC.present(vc, animated: false)
            RunLoop.current.run(until: Date().addingTimeInterval(0.5))
            img = snapshot(window, size: sceneSize, scale: spec.scale)
            vc.dismiss(animated: false)
            RunLoop.current.run(until: Date().addingTimeInterval(0.3))
        } else if let alertJSON = spec.alert {
            // Spec v5.2 (M12): a real UIAlertController over the base scene.
            // Same routing reason as "modal" — Catalyst bridges alerts into
            // AppKit panels, so only real iOS can produce the golden.
            // The alert's DIM lives outside the alert's own view, so it
            // resolves against the WINDOW's traits — the scene's style has to
            // be pushed all the way up or a dark scene gets a light dim
            // (openrender resolves everything against the scene style, so the
            // two renderers would disagree by 28 counts of dimming).
            window.overrideUserInterfaceStyle = spec.style
            defer { window.overrideUserInterfaceStyle = .unspecified }
            let ac = buildAlert(alertJSON, style: spec.style)
            hostVC.present(ac, animated: false)
            RunLoop.current.run(until: Date().addingTimeInterval(0.5))
            img = snapshot(window, size: sceneSize, scale: spec.scale)
            window.endEditing(true)
            ac.dismiss(animated: false)
            // A presented alert's views outlive `dismiss` long enough that a
            // second alert can stack on top of the first in the same process
            // (measured while building Tools/oracle2/alertprobe), so wait for
            // the teardown instead of sleeping a fixed amount.
            let deadline = Date().addingTimeInterval(3)
            while hostVC.presentedViewController != nil, Date() < deadline {
                RunLoop.current.run(until: Date().addingTimeInterval(0.05))
            }
            RunLoop.current.run(until: Date().addingTimeInterval(0.3))
        } else {
            img = snapshot(wrapper, size: sceneSize, scale: spec.scale)
        }
        wrapper.removeFromSuperview()
        try img.pngData()!.write(to: URL(fileURLWithPath: "\(outDir)/\(spec.name).png"))
        print("rendered \(spec.name)")
    }
}

class SimSceneAppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    var renderer: SimSceneRenderer?

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        let win = UIWindow(frame: UIScreen.main.bounds)
        window = win
        let vc = UIViewController()
        vc.view.backgroundColor = .clear
        win.rootViewController = vc
        win.makeKeyAndVisible()
        let r = SimSceneRenderer(hostVC: vc, window: win)
        renderer = r
        // Let the first render commit before capturing (UIKit skips
        // presentation work for never-displayed hierarchies).
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { r.renderAll() }
        return true
    }
}

// Watchdog — never wedge the simulator boot pipeline.
DispatchQueue.main.asyncAfter(deadline: .now() + 120) {
    try? "watchdog timeout".write(toFile: outDir + "/DONE", atomically: true, encoding: .utf8)
    exit(3)
}

_ = UIApplicationMain(CommandLine.argc, CommandLine.unsafeArgv, nil,
                      NSStringFromClass(SimSceneAppDelegate.self))
