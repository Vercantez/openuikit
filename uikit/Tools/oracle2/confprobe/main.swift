// ConfProbe: the REAL-UIKit half of the conformance-app harness
// (docs/HILLCLIMB.md, Sources/ConformanceApps).
//
// It is GENERIC. It knows nothing about any particular app: it compiles
// the whole Sources/ConformanceApps tree (every app plus the generated
// Registry.swift) against real UIKit, then looks the requested app up in
// ConformanceApps.registry — the same table openhost reads. The shell
// script copies that app's script.json into the bundle.
//
//   scripts/conformance_probe_sim.sh NavFlow /tmp/conf/golden
//
// Per capture time t in the app's script it writes, into the app container's
// Documents (the shell script copies them out):
//
//   <app>.t<ms>.png          drawHierarchy(afterScreenUpdates: false) of the
//                            WINDOW at the device scale
//   <app>.t<ms>.layout.json  {"name", "t", "screen", "views": [...]} — the
//                            Tools/oracle SceneKit dump shape widened with
//                            ABSOLUTE frames and presentation-layer geometry
//
// `openhost --app <app> --script ... --record ...` writes the same file names
// with the same keys at the same times and the same scale
// (Sources/openhost/ConformanceMode.swift); scripts/conformance_flow.sh
// compares them.
//
// Two deliberate choices, both measured:
//
//   * afterScreenUpdates: FALSE — the last committed frame, i.e. what is
//     actually on screen at t. `true` runs a fresh layout+commit pass, which
//     would report the model state and quietly hide any capture that was
//     taken mid-animation.
//   * The window is the capture, not a wrapper below the safe area (the trick
//     Tools/oracle2/simscene and navprobe use for chrome scenes). A
//     conformance app presents a pageSheet, and a pageSheet is hosted in the
//     WINDOW, so a wrapper capture would simply not contain it. That is
//     affordable here only because the device is the iPhone SE (3rd gen) with
//     UIStatusBarHidden: no notch, no home indicator, so the window's safe
//     area is zero and matches OpenUIKit's window, which has none. The dump's
//     `screen.windowSafeArea` records it every run rather than trusting it.
import UIKit

let docsDir = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
let appName = ProcessInfo.processInfo.environment["CONFPROBE_APP"] ?? "App"

func round3(_ v: CGFloat) -> Double {
    // JSONSerialization throws on NaN/inf (it aborted SimScene once the dump
    // carried layer facts); non-finite values are written as -1.
    // A finite but enormous intrinsic (UIView.noIntrinsicMetric is -1, but some
    // private chrome reports CGFloat.greatestFiniteMagnitude) overflows the
    // 1000× rounding to +inf, which is the same crash — Forms' UIDatePicker /
    // UISlider / UIStepper subviews hit that on the first capture.
    guard v.isFinite, abs(Double(v)) < 1_000_000 else { return -1 }
    let r = (Double(v) * 1000).rounded() / 1000
    return r.isFinite ? r : -1
}

/// Re-encode a capture as 8-bit sRGB with STRAIGHT (non-premultiplied)
/// alpha and no colour profile. Copied from Tools/oracle2/simscene: the
/// extended-range renderer tags Display P3, and PIL/compare.py read the
/// PNG bytes without converting the ICC (Feed t200 card centre: P3-raw
/// (78, 121, 211) vs sRGB (64, 122, 217) for UIColor(0.25, 0.48, 0.85)).
func normalizedSRGB(_ img: UIImage) -> UIImage {
    guard let cg = img.cgImage else { return img }
    let w = cg.width, h = cg.height
    var premul = [UInt8](repeating: 0, count: w * h * 4)
    let space = CGColorSpace(name: CGColorSpace.sRGB)!
    guard let ctx = CGContext(data: &premul, width: w, height: h, bitsPerComponent: 8,
                              bytesPerRow: w * 4, space: space,
                              bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return img }
    ctx.draw(cg, in: CGRect(x: 0, y: 0, width: w, height: h))
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

func rectArr(_ r: CGRect) -> [Double] {
    [round3(r.origin.x), round3(r.origin.y), round3(r.width), round3(r.height)]
}

/// Mirror of Sources/openhost/ConformanceMode.swift's
/// `dumpConformanceLayout`, key for key. `abs` accumulates frame origins
/// (less bounds origins) to the captured root — the only geometry the two
/// trees can be compared on, because real UIKit hangs the app's controllers
/// off private containers the port has no counterpart for.
func dumpLayout(_ v: UIView, path: String, absOrigin: CGPoint,
                into out: inout [[String: Any]]) {
    let origin = CGPoint(x: absOrigin.x + v.frame.origin.x - v.bounds.origin.x,
                         y: absOrigin.y + v.frame.origin.y - v.bounds.origin.y)
    var entry: [String: Any] = [
        "path": path,
        "class": String(describing: type(of: v)),
        "frame": rectArr(v.frame),
        "abs": rectArr(CGRect(origin: origin, size: v.frame.size)),
        "bounds": rectArr(v.bounds),
        "hidden": v.isHidden,
        "alpha": round3(v.alpha),
    ]
    let sa = v.safeAreaInsets
    entry["safeAreaInsets"] = [round3(sa.top), round3(sa.left),
                               round3(sa.bottom), round3(sa.right)]
    if v.layer.cornerRadius != 0 { entry["cornerRadius"] = round3(v.layer.cornerRadius) }
    if v.transform != .identity {
        let t = v.transform
        entry["transform"] = [round3(t.a), round3(t.b), round3(t.c),
                              round3(t.d), round3(t.tx), round3(t.ty)]
    }
    // The presentation layer next to the model: a capture that caught an
    // animation in flight differs here. Every NavFlow capture is at rest, and
    // this is what proves it instead of assuming it.
    if let p = v.layer.presentation(), p.frame != v.layer.frame {
        entry["pframe"] = rectArr(p.frame)
    }
    if let c = v.backgroundColor {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        if c.getRed(&r, green: &g, blue: &b, alpha: &a) {
            entry["bg"] = [round3(r), round3(g), round3(b), round3(a)]
        }
    }
    if let l = v as? UILabel {
        if let t = l.text { entry["text"] = t }
        entry["fontSize"] = round3(l.font.pointSize)
        entry["fontName"] = l.font.fontName
    }
    if v is UILabel || v is UIButton || v is UISwitch || v is UIImageView
        || v is UITextField || v is UITextView {
        let i = v.intrinsicContentSize
        entry["intrinsic"] = [i.width == UIView.noIntrinsicMetric ? -1 : round3(i.width),
                              i.height == UIView.noIntrinsicMetric ? -1 : round3(i.height)]
    }
    if let sw = v as? UISwitch { entry["isOn"] = sw.isOn }
    if let tf = v as? UITextField {
        entry["isEditing"] = tf.isEditing
    }
    if let tv = v as? UITextView {
        if let t = tv.text { entry["text"] = t }
        entry["isEditing"] = tv.isFirstResponder
    }
    if let sl = v as? UISlider { entry["value"] = round3(CGFloat(sl.value)) }
    if let st = v as? UIStepper { entry["value"] = round3(CGFloat(st.value)) }
    if let sg = v as? UISegmentedControl {
        entry["selectedSegmentIndex"] = sg.selectedSegmentIndex
    }
    if let sv = v as? UIScrollView {
        entry["contentOffset"] = [round3(sv.contentOffset.x), round3(sv.contentOffset.y)]
        entry["contentSize"] = [round3(sv.contentSize.width), round3(sv.contentSize.height)]
        let ci = sv.contentInset, ai = sv.adjustedContentInset
        entry["contentInset"] = [round3(ci.top), round3(ci.left), round3(ci.bottom), round3(ci.right)]
        entry["adjustedContentInset"] = [round3(ai.top), round3(ai.left),
                                         round3(ai.bottom), round3(ai.right)]
    }
    out.append(entry)
    for (i, sub) in v.subviews.enumerated() {
        dumpLayout(sub, path: path.isEmpty ? "\(i)" : "\(path).\(i)",
                   absOrigin: origin, into: &out)
    }
}

/// `{t, action}` steps and capture times, read out of the app's script.json
/// (copied into the bundle by scripts/conformance_probe_sim.sh).
func loadScript() -> (steps: [(t: Double, action: String)], captures: [Double]) {
    guard let url = Bundle.main.url(forResource: "script", withExtension: "json"),
          let data = try? Data(contentsOf: url),
          let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
        fatalError("confprobe: no script.json in the bundle")
    }
    let steps = ((obj["events"] as? [[String: Any]]) ?? []).compactMap {
        e -> (Double, String)? in
        guard let t = e["t"] as? Double, let a = e["action"] as? String else { return nil }
        return (t, a)
    }.sorted { $0.0 < $1.0 }
    let captures = ((obj["captures"] as? [Double]) ?? []).sorted()
    precondition(!captures.isEmpty, "confprobe: script has no captures")
    return (steps, captures)
}

/// ms, zero-padded to >= 3 digits — the same suffix openrender / openhost use
/// (captureSuffix in SceneBuilder.swift, capture_suffix in compare.py).
func captureSuffix(_ t: Double) -> String {
    String(format: "t%03d", Int((t * 1000).rounded()))
}

final class AppDelegate: NSObject, UIApplicationDelegate {
    var window: UIWindow?
    var steps: [(t: Double, action: String)] = []
    var captures: [Double] = []
    var performAction: ((String) -> Void)?

    func application(_ app: UIApplication,
                     didFinishLaunchingWithOptions o: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        guard let entry = ConformanceApps.registry[appName] else {
            var have = ""
            for (i, n) in ConformanceApps.names.enumerated() {
                if i > 0 { have += ", " }
                have += n
            }
            fatalError("confprobe: unknown app \"\(appName)\" (have \(have))")
        }
        let w = UIWindow(frame: UIScreen.main.bounds)
        w.overrideUserInterfaceStyle = .light
        // A dismissed alert or sheet leaves the process's tint dimmed
        // (docs/ORACLE_FLOW.md capture hazards); NavFlow dismisses a sheet
        // halfway through its script, so pin the tint for the whole run.
        w.tintAdjustmentMode = .normal
        w.rootViewController = entry.makeRoot()
        w.makeKeyAndVisible()
        window = w
        performAction = entry.perform
        if w.bounds.size != entry.windowSize {
            print("confprobe: WARNING device \(w.bounds.size) != app \(entry.windowSize)")
        }
        (steps, captures) = loadScript()
        // Let the first frame commit before the timeline starts: UIKit skips
        // presentation work for a hierarchy that has never been displayed,
        // and afterScreenUpdates: false would hand back an empty bitmap.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [self] in run() }
        return true
    }

    /// Replay the merged timeline on the main run loop. At equal times an
    /// action runs before a capture, the same order openhost's recorder uses.
    func run() {
        enum Item { case step(String); case capture(Double) }
        var timeline: [(t: Double, order: Int, item: Item)] = []
        for (i, s) in steps.enumerated() { timeline.append((s.t, 0, .step(s.action))); _ = i }
        for c in captures { timeline.append((c, 1, .capture(c))) }
        timeline.sort { ($0.t, $0.order) < ($1.t, $1.order) }
        let t0 = CACurrentMediaTime()
        for (i, entry) in timeline.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + entry.t) { [self] in
                switch entry.item {
                case .step(let action):
                    print("action: \(action) t=\(entry.t)")
                    performAction?(action)
                case .capture(let t):
                    capture(at: t)
                }
                if i == timeline.count - 1 {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [self] in
                        print("confprobe: \(String(format: "%.3f", CACurrentMediaTime() - t0)) s")
                        try? "ok".write(toFile: docsDir + "/DONE", atomically: true, encoding: .utf8)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { exit(0) }
                    }
                }
            }
        }
    }

    func capture(at t: Double) {
        guard let w = window else { return }
        let fmt = UIGraphicsImageRendererFormat()
        fmt.scale = UIScreen.main.scale
        // .extended keeps the private glass materials the bar platters and
        // the sheet are made of; .standard drops them (measured, see
        // Tools/oracle2/simscene). opaque: the window is fully covered, so
        // alpha is 255 everywhere and premultiplied == straight — which is
        // what lets compare.py read these as straight-alpha goldens.
        fmt.preferredRange = .extended
        fmt.opaque = true
        let img = UIGraphicsImageRenderer(bounds: w.bounds, format: fmt).image { _ in
            w.drawHierarchy(in: w.bounds, afterScreenUpdates: false)
        }
        // Same re-encode SimScene uses (docs/ORACLE_FLOW.md): `.extended`
        // hands back Display-P3-tagged bitmaps. Feed t200, iPhone SE 2x:
        // UIColor(0.25, 0.48, 0.85) is sRGB (64, 122, 217) after this
        // conversion and P3-raw (78, 121, 211) without it — 14 counts, over
        // PIXEL_TOL 6, 99.8 % of each generated card. compare.py / PIL read
        // PNG bytes without the ICC, so the golden has to be untagged sRGB.
        let suffix = captureSuffix(t)
        try! normalizedSRGB(img).pngData()!.write(
            to: URL(fileURLWithPath: "\(docsDir)/\(appName).\(suffix).png"))

        var views: [[String: Any]] = []
        dumpLayout(w, path: "", absOrigin: .zero, into: &views)
        let sa = w.safeAreaInsets
        let payload: [String: Any] = [
            "name": "\(appName).\(suffix)",
            "t": round3(CGFloat(t)),
            "screen": ["scale": Double(UIScreen.main.scale),
                       "bounds": [round3(w.bounds.width), round3(w.bounds.height)],
                       "windowSafeArea": [round3(sa.top), round3(sa.left),
                                          round3(sa.bottom), round3(sa.right)]],
            "views": views,
        ]
        let data: Data
        do {
            data = try JSONSerialization.data(withJSONObject: payload, options: [.sortedKeys])
        } catch {
            print("confprobe: JSON dump failed at t=\(t): \(error)")
            try? "json failed: \(error)".write(toFile: docsDir + "/DONE",
                                               atomically: true, encoding: .utf8)
            return
        }
        try! data.write(to: URL(fileURLWithPath: "\(docsDir)/\(appName).\(suffix).layout.json"))
        print("captured \(appName).\(suffix).png")
    }
}

// Watchdog — never wedge the simulator boot pipeline.
DispatchQueue.main.asyncAfter(deadline: .now() + 120) {
    try? "watchdog timeout".write(toFile: docsDir + "/DONE", atomically: true, encoding: .utf8)
    exit(3)
}

UIApplicationMain(CommandLine.argc, CommandLine.unsafeArgv, nil,
                  NSStringFromClass(AppDelegate.self))
