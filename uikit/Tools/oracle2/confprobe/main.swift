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
//   <app>.t<ms>.png          light LTR portrait capture (default)
//   <app>.t<ms>.dark.png     dark capture (`"style":"dark"` or CONFPROBE_STYLE)
//   <app>.t<ms>.rtl.png      RTL capture (`"direction":"rtl"` or CONFPROBE_DIRECTION)
//   <app>.t<ms>.ax1.png      `.accessibilityLarge` (`CONFPROBE_CONTENT_SIZE=ax1`)
//   <app>.t<ms>.xxxl.png     `.extraExtraExtraLarge` (`CONFPROBE_CONTENT_SIZE=xxxl`)
//   <app>.t<ms>.landscape.png  landscape capture (`"orientation":"landscape"`
//                              or CONFPROBE_ORIENTATION)
//   <app>.t<ms>.layout.json  {"name", "t", "style", "direction", "contentSize",
//                            "orientation", "clock", "screen", "views"}
//                            — absolute MODEL frames plus presentation-layer
//                            geometry (pframe / pabs / popacity) and the
//                            CADisplayLink timestamp of this capture
//
// `openhost --app <app> --script ... --record ...` writes the same file names
// with the same keys at the same 60 Hz FRAME INDEX and the same scale
// (Sources/openhost/ConformanceMode.swift); scripts/conformance_flow.sh
// compares them.
//
// The timeline is a CADisplayLink at preferredFramesPerSecond = 60, not a
// GCD wall-clock. Script times convert with ConformanceClock.frameIndex
// (Int((t * 60).rounded())): TableEditor t1350 is frame 81 = 9 ticks after
// delete-row-2 at frame 72; Modal t600 is frame 36 = 12 ticks after
// sheet-medium at frame 24. The same delay on a GCD timer, openhost's
// loop, and a vsync used to land at remaining 0.162 / 0.179 / 0.238
// (scoreboard/open.txt). CONFPROBE_TRACE=1 also writes Documents/trace.json
// with every tick's moving presentation frames (no PNG — a snapshot stalls
// the link and would skip vsyncs).
//
// Two deliberate choices, both measured:
//
//   * afterScreenUpdates: FALSE — the last committed frame, i.e. what is
//     actually on screen at this display-link tick. `true` runs a fresh
//     layout+commit pass, which would report the model state and quietly
//     hide any capture that was taken mid-animation.
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
/// `dumpConformanceLayout`, key for key. `abs` accumulates MODEL frame
/// origins (less bounds origins) to the captured root — the only geometry
/// the two trees can be compared on at rest, because real UIKit hangs the
/// app's controllers off private containers the port has no counterpart for.
///
/// `pframe` / `pabs` / `popacity` are the presentation layer of THIS
/// display-link tick (navprobe dumpPresentation). Mid-flight captures
/// (TableEditor t1350, Modal t600) have already snapped the model to the
/// destination (`abs` matches rest, layout 0) while the PNG shows the
/// spring; without presentation geometry the dump cannot grade the curve.
func dumpLayout(_ v: UIView, path: String, absOrigin: CGPoint,
                pAbsOrigin: CGPoint,
                into out: inout [[String: Any]]) {
    let origin = CGPoint(x: absOrigin.x + v.frame.origin.x - v.bounds.origin.x,
                         y: absOrigin.y + v.frame.origin.y - v.bounds.origin.y)
    let p = v.layer.presentation()
    let pFrame = p?.frame ?? v.layer.frame
    let pBounds = p?.bounds ?? v.layer.bounds
    let pOrigin = CGPoint(x: pAbsOrigin.x + pFrame.origin.x - pBounds.origin.x,
                          y: pAbsOrigin.y + pFrame.origin.y - pBounds.origin.y)
    var entry: [String: Any] = [
        "path": path,
        "class": String(describing: type(of: v)),
        "frame": rectArr(v.frame),
        "abs": rectArr(CGRect(origin: origin, size: v.frame.size)),
        "bounds": rectArr(v.bounds),
        "hidden": v.isHidden,
        "alpha": round3(v.alpha),
        "pframe": rectArr(pFrame),
        "pabs": rectArr(CGRect(origin: pOrigin, size: pFrame.size)),
        "popacity": round3(CGFloat(p?.opacity ?? v.layer.opacity)),
    ]
    // `playing` is presentation != MODEL LAYER, not view.frame: UIButtonLabel
    // keeps view.frame.y=6 and layer.frame.y=0 at rest (TableEditor t200
    // Edit/Done). A GCD-era dump compared p.frame != v.layer.frame.
    // Bounds-origin animations (UIScrollView contentOffset, Pager fling /
    // page-next) do not move layer.frame, so compare presentation bounds too.
    if let p, p.frame != v.layer.frame || p.bounds != v.layer.bounds {
        entry["playing"] = true
    }
    let sa = v.safeAreaInsets
    entry["safeAreaInsets"] = [round3(sa.top), round3(sa.left),
                               round3(sa.bottom), round3(sa.right)]
    if v.layer.cornerRadius != 0 { entry["cornerRadius"] = round3(v.layer.cornerRadius) }
    if v.transform != .identity {
        let t = v.transform
        entry["transform"] = [round3(t.a), round3(t.b), round3(t.c),
                              round3(t.d), round3(t.tx), round3(t.ty)]
    }
    if let p {
        let tr = p.transform
        if !CATransform3DIsIdentity(tr) {
            entry["ptransform"] = [round3(tr.m11), round3(tr.m12),
                                   round3(tr.m21), round3(tr.m22),
                                   round3(tr.m41), round3(tr.m42)]
        }
        if let keys = v.layer.animationKeys(), !keys.isEmpty,
           pFrame != v.layer.frame || p.bounds != v.layer.bounds {
            entry["anims"] = keys.compactMap { k -> [String: Any]? in
                guard let a = v.layer.animation(forKey: k) else { return nil }
                var d: [String: Any] = [
                    "key": k,
                    "class": String(describing: type(of: a)),
                    "duration": round3(CGFloat(a.duration)),
                    "beginTime": round3(CGFloat(a.beginTime)),
                ]
                if let s = a as? CASpringAnimation {
                    d["mass"] = round3(CGFloat(s.mass))
                    d["stiffness"] = round3(CGFloat(s.stiffness))
                    d["damping"] = round3(CGFloat(s.damping))
                    d["initialVelocity"] = round3(CGFloat(s.initialVelocity))
                }
                return d
            }
        }
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
    if v.effectiveUserInterfaceLayoutDirection == .rightToLeft {
        entry["uiDir"] = "rtl"
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
        // Presentation bounds.origin is the mid-flight paging offset
        // (Pager fling / page-next). Model contentOffset has already
        // snapped to the destination when UIView.animate commits.
        if let p = v.layer.presentation() {
            entry["pcontentOffset"] = [round3(p.bounds.origin.x),
                                       round3(p.bounds.origin.y)]
        }
        entry["contentSize"] = [round3(sv.contentSize.width), round3(sv.contentSize.height)]
        let ci = sv.contentInset, ai = sv.adjustedContentInset
        entry["contentInset"] = [round3(ci.top), round3(ci.left), round3(ci.bottom), round3(ci.right)]
        entry["adjustedContentInset"] = [round3(ai.top), round3(ai.left),
                                         round3(ai.bottom), round3(ai.right)]
    }
    out.append(entry)
    for (i, sub) in v.subviews.enumerated() {
        dumpLayout(sub, path: path.isEmpty ? "\(i)" : "\(path).\(i)",
                   absOrigin: origin, pAbsOrigin: pOrigin, into: &out)
    }
}

/// `{t, action}` steps, capture times, optional `"style"` (`light` /
/// `dark`), `"direction"` (`ltr` / `rtl`), and `"orientation"`
/// (`portrait` / `landscape`), read out of the app's script.json
/// (copied into the bundle by scripts/conformance_probe_sim.sh).
/// `CONFPROBE_STYLE` / `CONFPROBE_DIRECTION` / `CONFPROBE_ORIENTATION`
/// override the fields so `conformance_flow.sh --dark` / `--rtl` /
/// `--landscape` can replay a light LTR portrait script without rewriting
/// it. `CONFPROBE_CONTENT_SIZE` (`ax1` / `xxxl`) pins
/// `window.traitOverrides.preferredContentSizeCategory` the same
/// way (`conformance_flow.sh --ax1` / `--xxxl`).
func loadScript() -> (steps: [(t: Double, action: String)], captures: [Double],
                       style: String, direction: String, contentSize: String,
                       orientation: String) {
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
    let style = ConformanceClock.resolvedStyle(
        script: (obj["style"] as? String) ?? "light",
        environment: ProcessInfo.processInfo.environment["CONFPROBE_STYLE"])
    let direction = ConformanceClock.resolvedDirection(
        script: (obj["direction"] as? String) ?? "ltr",
        environment: ProcessInfo.processInfo.environment["CONFPROBE_DIRECTION"])
    let contentSize = ConformanceClock.resolvedContentSize(
        environment: ProcessInfo.processInfo.environment["CONFPROBE_CONTENT_SIZE"])
    let orientation = ConformanceClock.resolvedOrientation(
        script: (obj["orientation"] as? String) ?? "portrait",
        environment: ProcessInfo.processInfo.environment["CONFPROBE_ORIENTATION"])
    return (steps, captures, style, direction, contentSize, orientation)
}

    /// First CASpringAnimation.beginTime in the tree (absolute media time).
    /// Only springs: a fallback to any CAAnimation with duration > 0.05
    /// sought Pager's bounds-tick page/fling curve to the wrong clock
    /// (MEASURED iPhone SE 2x / iOS 26.1: live n=6 offset 469, but the
    /// fallback freeze left every mid-flight capture at 378 = n=1).
    /// TableEditor / Modal still match — they install CASpringAnimation.
    func firstSpringBegin(_ v: UIView) -> CFTimeInterval? {
        if let keys = v.layer.animationKeys() {
            for k in keys {
                if let a = v.layer.animation(forKey: k) as? CASpringAnimation, a.beginTime > 1 {
                    return a.beginTime
                }
            }
        }
        for s in v.subviews {
            if let t = firstSpringBegin(s) { return t }
        }
        return nil
    }

/// Seek the window's layer tree to absolute media time `media` and freeze
/// it there so dumpLayout + drawHierarchy see one sample. MEASURED: five
/// runs that captured live at display-link timestamp action+0.15 still
/// had CA beginTime 0.142–0.146 before the stamp (remaining 0.190–0.200);
/// seeking to begin+N/60 is the named frame.
func freezeLayer(_ layer: CALayer, at media: CFTimeInterval) {
    let local = layer.convertTime(media, from: nil)
    layer.speed = 0
    layer.timeOffset = local
}

func unfreezeLayer(_ layer: CALayer) {
    // Identity clock, not the pause-resume formula: we may have SEEKED into
    // the future (begin+N/60), and a resume-from-paused-time would leave
    // convertTime warped for the next mid-flight (TableEditor t2350 remaining
    // 0.034 instead of env(9/60)=0.179 after the t1350 seek).
    layer.speed = 1
    layer.timeOffset = 0
    layer.beginTime = 0
}

/// Presentation bounds.origin of every UIScrollView. Pager page-next /
/// fling write contentOffset each vsync (model == presentation); there is
/// no CAAnimation freezeLayer can seek (pager-clock probe: only anims are
/// page-control `contentsMultiplyColor`).
func collectScrollPOffsets(_ v: UIView, into out: inout [CGPoint]) {
    if let sv = v as? UIScrollView {
        let p = sv.layer.presentation()
        out.append(CGPoint(x: p?.bounds.origin.x ?? sv.bounds.origin.x,
                           y: p?.bounds.origin.y ?? sv.bounds.origin.y))
    }
    for s in v.subviews {
        collectScrollPOffsets(s, into: &out)
    }
}

func scrollOffsetsMoved(_ a: [CGPoint], _ b: [CGPoint]) -> Bool {
    let n = min(a.count, b.count)
    for i in 0..<n {
        if abs(a[i].x - b[i].x) > 0.5 || abs(a[i].y - b[i].y) > 0.5 {
            return true
        }
    }
    return false
}

/// Invert the measured cosine ease-in-out 0.3 s curve (pager-clock probe
/// n=1..17, max |Δ| 0.25 pt) so a late first-motion sample still names
/// the right frame. `distance` is the queuing scroll view's page extent.
func cosineLocalN(delta: CGFloat, distance: CGFloat) -> Int {
    let d = abs(Double(distance))
    if d < 1 { return 1 }
    var u = abs(Double(delta)) / d
    if u > 1 { u = 1 }
    let arg = max(-1.0, min(1.0, 1 - 2 * u))
    let t = acos(arg) / Double.pi
    let n = Int((t * 18.0).rounded())
    return n < 1 ? 1 : n
}

func collectScrollFacts(_ v: UIView, into out: inout [(name: String, px: CGFloat, py: CGFloat, w: CGFloat, h: CGFloat)]) {
    if let sv = v as? UIScrollView {
        let p = sv.layer.presentation()
        out.append((String(describing: type(of: sv)),
                    p?.bounds.origin.x ?? sv.bounds.origin.x,
                    p?.bounds.origin.y ?? sv.bounds.origin.y,
                    sv.bounds.width, sv.bounds.height))
    }
    for s in v.subviews {
        collectScrollFacts(s, into: &out)
    }
}

final class AppDelegate: NSObject, UIApplicationDelegate {
    enum Item { case step(String); case capture(Double) }

    var window: UIWindow?
    var steps: [(t: Double, action: String)] = []
    var captures: [Double] = []
    /// `light` or `dark`. Set on the window *before* `makeRoot()` so
    /// semantic colours resolve against the style the first capture sees.
    var style: String = "light"
    /// `ltr` or `rtl`. Set on the window *before* `makeRoot()` so
    /// `semanticContentAttribute` is in place for the first layout.
    var direction: String = "ltr"
    /// `large` / `ax1` / `xxxl`. Window `traitOverrides.preferredContentSizeCategory`
    /// is pinned before `makeRoot()` (`conformance_flow.sh --ax1` / `--xxxl`).
    var contentSize: String = "large"
    /// `portrait` or `landscape`. The SE is rotated to landscapeLeft
    /// before the first capture (`conformance_flow.sh --landscape`).
    var orientation: String = "portrait"
    var performAction: ((String) -> Void)?
    var link: CADisplayLink?
    var frameIndex = 0
    var warmupLeft = 3
    var timeline: [(frame: Int, order: Int, item: Item)] = []
    var cursor = 0
    var tracing = false
    var trace: [[String: Any]] = []
    var startedAt: CFTimeInterval = 0
    var lastServicedFrame = -1
    var lastActionTimestamp: CFTimeInterval = 0
    var lastActionFrame = 0
    /// Captures after an action, keyed by the action's script frame.
    /// Mid-flight (≤ 20 frames) is a seek to spring begin+N/60; rest is
    /// waited out on the display-link clock so a PNG stall cannot shrink
    /// the gap (TableEditor teD-3 t900 was 0.313 s after a late edit and
    /// scored 96.630 with 27 views still playing).
    var capturesByActionFrame: [Int: [(t: Double, frames: Int, seek: Bool)]] = [:]
    var armedAfterAction: [(t: Double, frames: Int, seek: Bool)] = []
    var springBegin: CFTimeInterval?
    /// Rest presentation offsets of every UIScrollView, snapped after the
    /// action. First motion is named frame 1 of a tick-updated scroll.
    var scrollRestOffsets: [CGPoint] = []
    var sawScrollMotion = false
    var motionTimestamp: CFTimeInterval = 0
    var motionLocalN = 1
    var motionDistance: CGFloat = 375
    var motionRest: CGFloat = 375
    var motionAxisX = true
    var motionIndex = 0
    var lastCurN = 0

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
        (steps, captures, style, direction, contentSize, orientation) = loadScript()
        // RTL: `UIView.appearance()` BEFORE the window. MEASURED /tmp/rtlprobe,
        // iPhone SE 2x / iOS 26.1: window-only `semanticContentAttribute =
        // .forceRightToLeft` stamps the window (1/76 views `uiDir=rtl`,
        // large-title x 16, switch x 282, disclosure x 332.5). Appearance
        // stamps the tree (74/76, large-title x 247.5 = 375−16−111.5,
        // switch x 0, disclosure x 16). `--dark` can pin the window alone
        // because `overrideUserInterfaceStyle` inherits via traits; RTL
        // does not. `--rtl` therefore pins appearance then the window.
        if direction == "rtl" {
            UIView.appearance().semanticContentAttribute = .forceRightToLeft
            UINavigationBar.appearance().semanticContentAttribute = .forceRightToLeft
        }
        let w = UIWindow(frame: UIScreen.main.bounds)
        // Style on the window BEFORE makeRoot so the first capture (and
        // every semantic colour resolved at view construction) sees it.
        // Light stays `.light` (the previous hardcoded pin); `--dark` /
        // script `"style":"dark"` pins `.dark`.
        w.overrideUserInterfaceStyle = style == "dark" ? .dark : .light
        // Direction on the window BEFORE makeRoot so the first layout
        // sees it. LTR stays unspecified (the previous pin); `--rtl` /
        // script `"direction":"rtl"` pins `.forceRightToLeft`.
        if direction == "rtl" {
            w.semanticContentAttribute = .forceRightToLeft
        }
        // Content size BEFORE makeRoot so `UIFont.preferredFont(forTextStyle:)`
        // at construction (Forms body labels, Feed headline/subheadline,
        // TableEditor subtitle cells, bar-button titles) sees the category.
        // Default `.large` is unsuffixed so existing goldens do not move.
        w.traitOverrides.preferredContentSizeCategory =
            ConformanceClock.contentSizeCategory(for: contentSize)
        // A dismissed alert or sheet leaves the process's tint dimmed
        // (docs/ORACLE_FLOW.md capture hazards); NavFlow dismisses a sheet
        // halfway through its script, so pin the tint for the whole run.
        w.tintAdjustmentMode = .normal
        w.rootViewController = entry.makeRoot()
        w.makeKeyAndVisible()
        window = w
        performAction = entry.perform
        if orientation == "landscape" {
            // Pin the interface to landscapeLeft before makeRoot's first
            // layout. The shell also rotates the SE device; this is the
            // in-process authority if the Simulator window is still
            // portrait. MEASURED: UIInterfaceOrientation.landscapeLeft
            // on iPhone SE 2x is 667×375.
            if let scene = w.windowScene {
                scene.requestGeometryUpdate(
                    .iOS(interfaceOrientations: .landscapeLeft)
                ) { error in
                    print("confprobe: requestGeometryUpdate \(error)")
                }
            }
        }
        let expected = orientation == "landscape"
            ? CGSize(width: 667, height: 375) : entry.windowSize
        if w.bounds.size != expected {
            print("confprobe: WARNING device \(w.bounds.size) != expected \(expected)")
        }
        print("confprobe: style=\(style) direction=\(direction) contentSize=\(contentSize) orientation=\(orientation)")
        tracing = ProcessInfo.processInfo.environment["CONFPROBE_TRACE"] != nil
        // Let the first frame commit before the timeline starts: UIKit skips
        // presentation work for a hierarchy that has never been displayed,
        // and afterScreenUpdates: false would hand back an empty bitmap.
        // Landscape waits until the window is actually 667×375 so the first
        // capture is not a portrait frame with a .landscape name.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [self] in
            waitForLandscapeThenStart(attempts: 0)
        }
        return true
    }

    func application(_ application: UIApplication,
                     supportedInterfaceOrientationsFor window: UIWindow?)
        -> UIInterfaceOrientationMask {
        orientation == "landscape" ? .landscapeLeft : .allButUpsideDown
    }

    func requestLandscape(_ w: UIWindow) {
        if let scene = w.windowScene {
            scene.requestGeometryUpdate(
                .iOS(interfaceOrientations: .landscapeLeft)
            ) { error in
                print("confprobe: requestGeometryUpdate \(error)")
            }
        }
    }

    func waitForLandscapeThenStart(attempts: Int) {
        let size = window?.bounds.size ?? .zero
        if orientation == "landscape", size.width <= size.height, attempts < 20 {
            if let w = window { requestLandscape(w) }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [self] in
                waitForLandscapeThenStart(attempts: attempts + 1)
            }
            return
        }
        if orientation == "landscape", let w = window {
            let sa = w.safeAreaInsets
            let h = w.traitCollection.horizontalSizeClass.rawValue
            let v = w.traitCollection.verticalSizeClass.rawValue
            let io = w.windowScene?.interfaceOrientation.rawValue ?? 0
            print("confprobe: landscape window=\(size.width)x\(size.height)"
                  + " sa=[\(sa.top), \(sa.left), \(sa.bottom), \(sa.right)]"
                  + " hSize=\(h) vSize=\(v) io=\(io)")
        }
        startLink()
    }

    /// Replay the merged timeline on a 60 Hz CADisplayLink. Script times
    /// become `ConformanceClock.frameIndex` (TableEditor t1350 = frame 81,
    /// 9/60 s of *media* time after delete at frame 72). The index is
    /// `round((timestamp − t0) × 60)`, not a callback counter: five runs
    /// that counted callbacks still drifted remaining travel 0.189–0.209
    /// (dt 0.122–0.147 s) because a rest PNG stall stretched later ticks
    /// while Core Animation kept vsync time. At equal frames a capture
    /// runs before an action so Pager t400's PNG cannot stall the private
    /// page-scroll updater that ignores layer.speed (pager-clock probe).
    func startLink() {
        let stepFrames = steps.map { ConformanceClock.frameIndex(for: $0.t) }
        for (i, s) in steps.enumerated() {
            timeline.append((stepFrames[i], 1, .step(s.action)))
        }
        for c in captures {
            let cf = ConformanceClock.frameIndex(for: c)
            var prev: Int?
            for sf in stepFrames {
                if sf <= cf { prev = sf }
            }
            if let pa = prev {
                let d = cf - pa
                if d > 0 {
                    let seek = d <= 20
                    var list = capturesByActionFrame[pa] ?? []
                    list.append((t: c, frames: d, seek: seek))
                    capturesByActionFrame[pa] = list
                    continue
                }
            }
            timeline.append((cf, 0, .capture(c)))
        }
        for pa in capturesByActionFrame.keys {
            capturesByActionFrame[pa]!.sort { $0.frames < $1.frames }
        }
        timeline.sort { ($0.frame, $0.order) < ($1.frame, $1.order) }
        let l = CADisplayLink(target: self, selector: #selector(tick(_:)))
        l.preferredFramesPerSecond = ConformanceClock.hz
        l.preferredFrameRateRange = CAFrameRateRange(
            minimum: Float(ConformanceClock.hz),
            maximum: Float(ConformanceClock.hz),
            preferred: Float(ConformanceClock.hz))
        l.add(to: .main, forMode: .common)
        link = l
    }

    @objc func tick(_ l: CADisplayLink) {
        // Three warmup ticks so the link is running at 60 Hz before frame 0
        // of the script (navprobe records from the first tick; a cold link's
        // first duration is not always 1/60).
        if warmupLeft > 0 {
            warmupLeft -= 1
            return
        }
        if startedAt == 0 {
            startedAt = l.timestamp
            lastActionTimestamp = l.timestamp
        }
        // Media frame, not callback count. A 40 ms drawHierarchy stall after
        // t900 used to be counted as one tick while CA advanced two vsyncs;
        // the mid-flight sample then walked 0.12–0.15 s of spring.
        let frame = Int(((l.timestamp - startedAt) * Double(ConformanceClock.hz)).rounded())
        if frame == lastServicedFrame { return }
        lastServicedFrame = frame
        frameIndex = frame
        if l.duration > 0.020 {
            print("confprobe: WARNING dropped frame at \(frame) duration=\(l.duration)")
        }
        if tracing { appendTrace(link: l) }
        while cursor < timeline.count, timeline[cursor].frame <= frame {
            let entry = timeline[cursor]
            switch entry.item {
            case .step(let action):
                print("action: \(action) t=\(ConformanceClock.time(of: entry.frame)) frame=\(frame)")
                lastActionTimestamp = l.timestamp
                lastActionFrame = frame
                performAction?(action)
                sawScrollMotion = false
                motionTimestamp = 0
                motionLocalN = 1
                motionRest = 375
                motionAxisX = true
                scrollRestOffsets = []
                if let w = window {
                    collectScrollPOffsets(w, into: &scrollRestOffsets)
                }
                if let list = capturesByActionFrame[entry.frame] {
                    armedAfterAction = list
                    springBegin = nil
                    print("armed \(list.count) capture(s) after \(action)")
                }
            case .capture(let t):
                capture(at: t, frame: frame, link: l, sampleElapsed: nil, springBegin: nil)
            }
            cursor += 1
        }
        // Post-action captures: seek mid-flight to spring begin+N/60;
        // tick-updated scrolls (Pager page-next / fling) invert the cosine
        // from the presentation offset so named frame N is the first tick
        // whose local index reaches N (callback count / timestamp skip a
        // vsync the private updater still runs); rest waits on the
        // action's timestamp so a PNG stall cannot shrink the gap
        // (TableEditor / Modal still seek).
        if !armedAfterAction.isEmpty, frame > lastActionFrame, let w = window {
            var wantsSeek = false
            for item in armedAfterAction {
                if item.seek { wantsSeek = true; break }
            }
            if wantsSeek, springBegin == nil {
                springBegin = firstSpringBegin(w)
            }
            // MEASURED pager-clock probe, iPhone SE 2x / iOS 26.1:
            // setViewControllers(animated:) starts 1 or 2 vsyncs after the
            // action (10 in-process traces: delay [1,2,2,…]; wait-from-action
            // n=6 pOffset 442 vs 469). No bounds CAAnimation (modelOffset
            // == pOffset; freezeLayer at action+6/60 stays at the live n=1
            // state; layer.speed=0 does not stop the updater). Invert
            // cosine from pOffset so named frame N is independent of that
            // 1–2 vsync start (mot+5 → 469, mot+11 → 656.5 on all 10).
            let waitingOnScroll = springBegin == nil && wantsSeek
            if waitingOnScroll {
                if !sawScrollMotion {
                    var now: [CGPoint] = []
                    collectScrollPOffsets(w, into: &now)
                    if scrollOffsetsMoved(scrollRestOffsets, now) {
                        sawScrollMotion = true
                        motionTimestamp = l.timestamp
                        var facts: [(name: String, px: CGFloat, py: CGFloat, w: CGFloat, h: CGFloat)] = []
                        collectScrollFacts(w, into: &facts)
                        var bestAbs: CGFloat = 0
                        var bestDelta: CGFloat = 0
                        var bestW: CGFloat = 375
                        var bestIdx = 0
                        let n = min(scrollRestOffsets.count, facts.count)
                        for i in 0..<n {
                            let dx = facts[i].px - scrollRestOffsets[i].x
                            let dy = facts[i].py - scrollRestOffsets[i].y
                            let mag = max(abs(dx), abs(dy))
                            if mag > bestAbs {
                                bestAbs = mag
                                bestIdx = i
                                if abs(dx) >= abs(dy) {
                                    bestDelta = dx
                                    bestW = facts[i].w
                                    motionRest = scrollRestOffsets[i].x
                                    motionAxisX = true
                                } else {
                                    bestDelta = dy
                                    bestW = facts[i].h
                                    motionRest = scrollRestOffsets[i].y
                                    motionAxisX = false
                                }
                            }
                        }
                        motionIndex = bestIdx
                        // Pick the travel (page width, two pages, …) whose
                        // cosine n=1..8 residual is smallest so a late
                        // first-motion sample still names the right frame.
                        var bestErr: CGFloat = 1_000_000
                        let candidates: [CGFloat] = [bestW, bestW * 2]
                        for d in candidates {
                            if d < 1 { continue }
                            let guess = cosineLocalN(delta: bestDelta, distance: d)
                            let u = (1 - cos(Double.pi * Double(guess) / 18.0)) / 2
                            let pred = abs(d) * CGFloat(u)
                            let err = abs(pred - abs(bestDelta))
                            if err < bestErr {
                                bestErr = err
                                motionLocalN = guess
                                motionDistance = d
                            }
                        }
                        print("motion localN=\(motionLocalN) delta=\(bestDelta) dist=\(motionDistance) err=\(bestErr)")
                    }
                }
            }
            while let next = armedAfterAction.first {
                if next.seek, let origin = springBegin {
                    let elapsed = Double(next.frames) / Double(ConformanceClock.hz)
                    freezeLayer(w.layer, at: origin + elapsed)
                    CATransaction.flush()
                    capture(at: next.t, frame: lastActionFrame + next.frames, link: l,
                            sampleElapsed: elapsed, springBegin: origin)
                    unfreezeLayer(w.layer)
                    armedAfterAction.removeFirst()
                    continue
                }
                if next.seek {
                    if sawScrollMotion {
                        var facts: [(name: String, px: CGFloat, py: CGFloat, w: CGFloat, h: CGFloat)] = []
                        collectScrollFacts(w, into: &facts)
                        var cur = motionRest
                        if motionIndex < facts.count {
                            cur = motionAxisX ? facts[motionIndex].px : facts[motionIndex].py
                        }
                        let curN = cosineLocalN(delta: cur - motionRest, distance: motionDistance)
                        lastCurN = curN
                        // Named frame N is the first tick whose inverted
                        // cosine index reaches N (pager-clock live traces:
                        // n=6 pOffset 469, n=12 656.5).
                        if next.frames >= 18 {
                            let since = (l.timestamp - motionTimestamp) * Double(ConformanceClock.hz)
                            if abs(cur - motionRest) > 1 || since < 15 { break }
                        } else if curN < next.frames {
                            break
                        }
                        capture(at: next.t, frame: lastActionFrame + next.frames, link: l,
                                sampleElapsed: Double(next.frames) / Double(ConformanceClock.hz),
                                springBegin: nil)
                        armedAfterAction.removeFirst()
                        continue
                    }
                    let giveUp = lastActionTimestamp
                        + Double(next.frames + 20) / Double(ConformanceClock.hz)
                    if l.timestamp + 1e-4 < giveUp { break }
                }
                let due = lastActionTimestamp
                    + Double(next.frames) / Double(ConformanceClock.hz)
                if l.timestamp + 1e-4 < due { break }
                capture(at: next.t, frame: frame, link: l,
                        sampleElapsed: nil, springBegin: nil)
                armedAfterAction.removeFirst()
            }
        }
        if cursor >= timeline.count, armedAfterAction.isEmpty {
            l.invalidate()
            link = nil
            finish()
            return
        }
    }

    func appendTrace(link l: CADisplayLink) {
        guard let w = window else { return }
        var views: [[String: Any]] = []
        dumpLayout(w, path: "", absOrigin: .zero, pAbsOrigin: .zero, into: &views)
        var moving: [[String: Any]] = []
        for v in views {
            guard let pframe = v["pframe"] as? [Double],
                  let frame = v["frame"] as? [Double],
                  pframe != frame else { continue }
            var row: [String: Any] = [
                "path": v["path"] as Any,
                "class": v["class"] as Any,
                "pabs": v["pabs"] as Any,
                "pframe": pframe,
                "popacity": v["popacity"] as Any,
            ]
            if let text = v["text"] { row["text"] = text }
            if let anims = v["anims"] { row["anims"] = anims }
            moving.append(row)
        }
        trace.append([
            "frame": frameIndex,
            "displayLinkTimestamp": round3(CGFloat(l.timestamp)),
            "displayLinkDuration": round3(CGFloat(l.duration)),
            "moving": moving,
        ])
    }

    func capture(at t: Double, frame: Int, link: CADisplayLink,
                 sampleElapsed: Double?, springBegin: CFTimeInterval?) {
        guard let w = window else { return }
        // Layout dump FIRST: presentation() is this display-link tick.
        // drawHierarchy can stall ~40 ms and would otherwise sample a later
        // vsync (navprobe: stamp with link.timestamp, not CACurrentMediaTime).
        var views: [[String: Any]] = []
        dumpLayout(w, path: "", absOrigin: .zero, pAbsOrigin: .zero, into: &views)

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
        let suffix = ConformanceClock.captureSuffix(for: t, style: style,
                                                    direction: direction,
                                                    contentSize: contentSize,
                                                    orientation: orientation)
        try! normalizedSRGB(img).pngData()!.write(
            to: URL(fileURLWithPath: "\(docsDir)/\(appName).\(suffix).png"))

        var clock: [String: Any] = [
            "frame": frame,
            "hz": ConformanceClock.hz,
            "scriptT": round3(CGFloat(t)),
            "displayLinkTimestamp": round3(CGFloat(link.timestamp)),
            "displayLinkDuration": round3(CGFloat(link.duration)),
            "displayLinkTargetTimestamp": round3(CGFloat(link.targetTimestamp)),
            "sinceAction": round3(CGFloat(link.timestamp - lastActionTimestamp)),
            "sinceActionFrames": Int(((link.timestamp - lastActionTimestamp)
                                      * Double(ConformanceClock.hz)).rounded()),
        ]
        if let sampleElapsed {
            clock["sampleElapsed"] = round3(CGFloat(sampleElapsed))
        }
        if let springBegin {
            clock["springBegin"] = round3(CGFloat(springBegin))
        }
        if sawScrollMotion {
            clock["motionTimestamp"] = round3(CGFloat(motionTimestamp))
            clock["motionLocalN"] = motionLocalN
            clock["curN"] = lastCurN
            clock["sinceMotionFrames"] = Int(((link.timestamp - motionTimestamp)
                                              * Double(ConformanceClock.hz)).rounded())
        }
        let sa = w.safeAreaInsets
        let payload: [String: Any] = [
            "name": "\(appName).\(suffix)",
            "t": round3(CGFloat(t)),
            "orientation": orientation,
            "style": style,
            "direction": direction,
            "contentSize": contentSize,
            "clock": clock,
            "screen": ["scale": Double(UIScreen.main.scale),
                       "bounds": [round3(w.bounds.width), round3(w.bounds.height)],
                       "windowSafeArea": [round3(sa.top), round3(sa.left),
                                          round3(sa.bottom), round3(sa.right)],
                       "horizontalSizeClass": w.traitCollection.horizontalSizeClass.rawValue,
                       "verticalSizeClass": w.traitCollection.verticalSizeClass.rawValue,
                       "interfaceOrientation": w.windowScene?.interfaceOrientation.rawValue ?? 0],
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
        print("captured \(appName).\(suffix).png frame=\(frame) dl=\(String(format: "%.6f", link.timestamp))")
    }

    func finish() {
        if tracing {
            let payload: [String: Any] = ["hz": ConformanceClock.hz, "frames": trace]
            if let data = try? JSONSerialization.data(withJSONObject: payload,
                                                      options: [.sortedKeys]) {
                try? data.write(to: URL(fileURLWithPath: "\(docsDir)/trace.json"))
                print("confprobe: wrote trace.json (\(trace.count) ticks)")
            }
        }
        let elapsed = startedAt == 0 ? 0 : CACurrentMediaTime() - startedAt
        print("confprobe: \(String(format: "%.3f", elapsed)) s  frames=\(frameIndex)")
        try? "ok".write(toFile: docsDir + "/DONE", atomically: true, encoding: .utf8)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { exit(0) }
    }
}

// Watchdog — never wedge the simulator boot pipeline.
DispatchQueue.main.asyncAfter(deadline: .now() + 120) {
    try? "watchdog timeout".write(toFile: docsDir + "/DONE", atomically: true, encoding: .utf8)
    exit(3)
}

UIApplicationMain(CommandLine.argc, CommandLine.unsafeArgv, nil,
                  NSStringFromClass(AppDelegate.self))
