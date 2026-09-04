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

    /// Re-encode a capture as 8-bit sRGB with STRAIGHT (non-premultiplied)
    /// alpha and no colour profile, whatever the renderer produced: across
    /// a 98-scene run the extended-range renderer handed back premultiplied,
    /// Display-P3-tagged bitmaps for some scenes and untagged straight ones
    /// for others (measured 2026-09-04), so the PNG bytes are normalised here
    /// and compare.py can read them like openrender's own.
    func normalizedSRGB(_ img: UIImage) -> UIImage {
        guard let cg = img.cgImage else { return img }
        let w = cg.width, h = cg.height
        var premul = [UInt8](repeating: 0, count: w * h * 4)
        let space = CGColorSpace(name: CGColorSpace.sRGB)!
        guard let ctx = CGContext(data: &premul, width: w, height: h, bitsPerComponent: 8,
                                  bytesPerRow: w * 4, space: space,
                                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return img }
        ctx.draw(cg, in: CGRect(x: 0, y: 0, width: w, height: h))
        // Un-premultiply into a straight-alpha buffer (CG cannot draw into a
        // non-premultiplied context, but it can wrap one as an image).
        var straight = [UInt8](repeating: 0, count: w * h * 4)
        for i in 0..<(w * h) {
            let a = Int(premul[i * 4 + 3])
            if a == 0 { continue }
            for c in 0..<3 {
                let v = Int(premul[i * 4 + c]) * 255 + a / 2
                straight[i * 4 + c] = UInt8(min(255, v / a))
            }
            straight[i * 4 + 3] = UInt8(a)
        }
        let data = Data(straight)
        guard let provider = CGDataProvider(data: data as CFData),
              let out = CGImage(width: w, height: h, bitsPerComponent: 8, bitsPerPixel: 32,
                                bytesPerRow: w * 4, space: space,
                                bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.last.rawValue),
                                provider: provider, decode: nil, shouldInterpolate: false,
                                intent: .defaultIntent) else { return img }
        return UIImage(cgImage: out, scale: img.scale, orientation: .up)
    }

    func snapshot(_ view: UIView, size: CGSize, scale: CGFloat) -> UIImage {
        let fmt = UIGraphicsImageRendererFormat()
        fmt.scale = scale
        // Capture range: .extended by default (SIMSCENE_RANGE overrides).
        // MEASURED 2026-09-04: .automatic tags Display P3 (a saturated
        // #1971C2 read raw is (54,111,188)); .standard gives sRGB but DROPS
        // private glass materials (the sheet grabber vanished, region min
        // 255 vs 195); .extended keeps the materials. Whatever the renderer
        // hands back, normalizedSRGB() re-encodes it as untagged 8-bit sRGB
        // with straight alpha.
        switch ProcessInfo.processInfo.environment["SIMSCENE_RANGE"] ?? "extended" {
        case "standard": fmt.preferredRange = .standard
        case "automatic": fmt.preferredRange = .automatic
        default: fmt.preferredRange = .extended
        }
        fmt.opaque = false
        return normalizedSRGB(UIGraphicsImageRenderer(size: size, format: fmt).image { _ in
            view.drawHierarchy(in: CGRect(origin: .zero, size: size), afterScreenUpdates: true)
        })
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

        let sceneSize = CGSize(width: spec.width, height: spec.height)
        if window.bounds.size != sceneSize {
            print("warning: scene \(spec.name) size \(sceneSize) != device \(window.bounds.size)")
        }
        let wrapper = UIView(frame: CGRect(origin: .zero, size: sceneSize))
        // Every tint-coloured control (progress fill, checkmark, chevron,
        // button title) rendered GREY in the goldens captured after the
        // alert scenes: a dismissed UIAlertController leaves the host's
        // tintAdjustmentMode dimmed. Force normal for every scene (measured
        // 2026-09-04: progress fill (151,151,152), checkmark (155,155,155)).
        wrapper.tintAdjustmentMode = .normal
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
            try writeLayoutDump(window, spec: spec, outdir: outDir)
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
        // Dump AFTER the capture, while the wrapper is still in the window:
        // drawHierarchy(afterScreenUpdates: true) runs UIKit's final layout
        // pass, and the dump used to run before the wrapper was even added
        // (measured 2026-09-04: tableview_grouped's dump said cells at x 8 /
        // 359 wide / 53 tall while the pixels showed the iOS 26 card at
        // x 20 / 335 wide).
        // Modal scenes present OVER the window: dump the window so the sheet's
        // own views (platter, grabber, content) are in the layout file too.
        if spec.modal == nil { try writeLayoutDump(container, spec: spec, outdir: outDir) }
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
