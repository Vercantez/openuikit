// RealAppProbe on REAL iOS: renders the pocket-casts options-picker screen
// (Sources/RealAppProbe, unmodified vendored app source) with real UIKit in
// the iOS 26 simulator and writes, per variant:
//   <Documents>/<variant>.png          drawHierarchy(afterScreenUpdates:) at
//                                      the device scale (3) — render the port
//                                      with OPENUIKIT_REALAPP_SCALE=3 to compare
//   <Documents>/<variant>.layout.json  {"name", "views": [dumpLayout entries]}
//                                      in the Tools/oracle SceneKit shape
//                                      (path / class / frame / intrinsic /
//                                      sizeThatFits200), so Tools/compare can
//                                      diff geometry as well as pixels.
//
// Why it exists: docs/REAL_APP_TEST.md "Where the render is wrong" item 4 —
// there was no real-UIKit render of this screen to diff against. The app
// files are the same bytes the OpenUIKit build compiles; only the two harness
// files are patched for Darwin by scripts/realapp_probe_sim.sh.
//
// Run: scripts/realapp_probe_sim.sh <outdir>
import UIKit

let docsDir = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
/// Variant being captured; names the image files dumpLayout writes.
var currentVariant = ""

struct Variant {
    let name: String
    let style: UIUserInterfaceStyle
    let kind: RealAppScreen.Variant
    let theme: Theme.ThemeType
    /// See RealApp.swift: the picker variants present a sheet, the storage
    /// screen is the window's root controller and presents nothing.
    var presentsSheet = true
    var contentSizeCategory: UIContentSizeCategory = .large
    var idiom: UIUserInterfaceIdiom = .phone
}

var variants: [Variant] = []

// Non-finite values (a private view's NaN frame, or an infinite fitting
// size) are written as -1: JSONSerialization throws on NaN/inf, and the
// first appearance-aware run died with "Invalid number value (NaN) in JSON
// write" (measured 2026-09-04) — one NaN killed all three goldens.
func round3(_ v: CGFloat) -> Double {
    guard v.isFinite else { return -1 }
    return (Double(v) * 1000).rounded() / 1000
}

func dumpLayout(_ v: UIView, path: String, into out: inout [[String: Any]]) {
    var entry: [String: Any] = [
        "path": path,
        "class": String(describing: type(of: v)),
        "frame": [round3(v.frame.origin.x), round3(v.frame.origin.y),
                  round3(v.frame.width), round3(v.frame.height)],
    ]
    if v is UILabel || v is UIButton || v is UISwitch || v is UIImageView || v is UIProgressView
        || v is UITextField || v is UITextView || v is UISlider {
        let i = v.intrinsicContentSize
        entry["intrinsic"] = [i.width == UIView.noIntrinsicMetric ? -1 : round3(i.width),
                              i.height == UIView.noIntrinsicMetric ? -1 : round3(i.height)]
    }
    if v is UILabel || v is UIButton {
        let s = v.sizeThatFits(CGSize(width: 200, height: CGFloat.greatestFiniteMagnitude))
        entry["sizeThatFits200"] = [round3(s.width), round3(s.height)]
    }
    if let l = v as? UILabel, let t = l.text { entry["text"] = t }
    if let sv = v as? UIScrollView {
        // Where the content sits: the app sets contentInset.top and UIKit
        // starts the offset at -adjustedContentInset.top (measured below).
        entry["contentOffset"] = [round3(sv.contentOffset.x), round3(sv.contentOffset.y)]
        entry["contentSize"] = [round3(sv.contentSize.width), round3(sv.contentSize.height)]
        let ci = sv.contentInset, ai = sv.adjustedContentInset
        entry["contentInset"] = [round3(ci.top), round3(ci.left), round3(ci.bottom), round3(ci.right)]
        entry["adjustedContentInset"] = [round3(ai.top), round3(ai.left), round3(ai.bottom), round3(ai.right)]
        entry["contentInsetAdjustmentBehavior"] = sv.contentInsetAdjustmentBehavior.rawValue
    }
    // Appearance facts the SceneKit dump does not carry but a sheet/switch
    // comparison needs: corner radius, background, alpha, hidden, tint.
    entry["cornerRadius"] = round3(v.layer.cornerRadius)
    entry["alpha"] = round3(v.alpha)
    entry["hidden"] = v.isHidden
    func rgba(_ c: UIColor?) -> [Double]? {
        guard let c = c else { return nil }
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        guard c.getRed(&r, green: &g, blue: &b, alpha: &a) else { return nil }
        return [round3(r), round3(g), round3(b), round3(a)]
    }
    if let bg = rgba(v.backgroundColor) { entry["bg"] = bg }
    if let sw = v as? UISwitch {
        entry["isOn"] = sw.isOn
        if let t = rgba(sw.onTintColor) { entry["onTint"] = t }
        if let t = rgba(sw.thumbTintColor) { entry["thumbTint"] = t }
    }
    if let l = v as? UILabel {
        entry["font"] = [l.font.fontName, round3(l.font.pointSize)]
        // Vertical metrics of the iOS cut, the numbers the port's
        // FontEngine table must reproduce for UILabel heights to match.
        entry["fontMetrics"] = ["ascender": round3(l.font.ascender), "descender": round3(l.font.descender),
                                "lineHeight": round3(l.font.lineHeight), "leading": round3(l.font.leading),
                                "capHeight": round3(l.font.capHeight), "xHeight": round3(l.font.xHeight)]
        if let t = rgba(l.textColor) { entry["textColor"] = t }
        entry["textAlignment"] = l.textAlignment.rawValue
    }
    // Layer facts that decide how a floating sheet card is drawn: the
    // transform (the card is scaled 377/393), the corner curve, a mask
    // layer's class/frame/radius, the shadow, and the layer's masksToBounds.
    let ly = v.layer
    let t = v.transform
    if t != .identity {
        entry["transform"] = [round3(t.a), round3(t.b), round3(t.c), round3(t.d), round3(t.tx), round3(t.ty)]
    }
    entry["cornerCurve"] = ly.cornerCurve.rawValue
    entry["maskedCorners"] = Int(ly.maskedCorners.rawValue)
    entry["masksToBounds"] = ly.masksToBounds
    if let m = ly.mask {
        var md: [String: Any] = [
            "class": String(describing: type(of: m)),
            "frame": [round3(m.frame.origin.x), round3(m.frame.origin.y),
                      round3(m.frame.width), round3(m.frame.height)],
            "cornerRadius": round3(m.cornerRadius),
            "cornerCurve": m.cornerCurve.rawValue,
        ]
        if let s = m as? CAShapeLayer, let p = s.path {
            let b = p.boundingBox
            md["pathBounds"] = [round3(b.origin.x), round3(b.origin.y), round3(b.width), round3(b.height)]
        }
        entry["mask"] = md
    }
    if ly.shadowOpacity != 0 {
        entry["shadow"] = ["opacity": round3(CGFloat(ly.shadowOpacity)),
                           "radius": round3(ly.shadowRadius),
                           "offset": [round3(ly.shadowOffset.width), round3(ly.shadowOffset.height)],
                           "color": rgba(ly.shadowColor.map { UIColor(cgColor: $0) }) ?? [],
                           "hasPath": ly.shadowPath != nil]
    }
    if let subs = ly.sublayers, subs.count > v.subviews.count {
        entry["extraSublayers"] = subs.filter { $0.delegate == nil }.map { l -> [String: Any] in
            var d: [String: Any] = ["class": String(describing: type(of: l)),
                                    "frame": [round3(l.frame.origin.x), round3(l.frame.origin.y),
                                              round3(l.frame.width), round3(l.frame.height)],
                                    "cornerRadius": round3(l.cornerRadius),
                                    "opacity": round3(CGFloat(l.opacity))]
            if let bg = l.backgroundColor, let c = rgba(UIColor(cgColor: bg)) { d["bg"] = c }
            if l.shadowOpacity != 0 {
                d["shadow"] = ["opacity": round3(CGFloat(l.shadowOpacity)), "radius": round3(l.shadowRadius),
                               "offset": [round3(l.shadowOffset.width), round3(l.shadowOffset.height)]]
            }
            return d
        }
    }
    // The image an image view shows (the switch's on-track sheen is one),
    // written beside the layout so the port can be compared against it.
    if let iv = v as? UIImageView {
        if let img = iv.image, let data = img.pngData(), !currentVariant.isEmpty {
            let file = "\(currentVariant).\(path).png"
            try? data.write(to: URL(fileURLWithPath: "\(docsDir)/\(file)"))
            entry["image"] = ["file": file, "size": [round3(img.size.width), round3(img.size.height)],
                              "scale": round3(img.scale), "renderingMode": img.renderingMode.rawValue,
                              "capInsets": [round3(img.capInsets.top), round3(img.capInsets.left),
                                            round3(img.capInsets.bottom), round3(img.capInsets.right)]]
            if let tint = rgba(iv.tintColor) { entry["ivTint"] = tint }
            entry["contentMode"] = iv.contentMode.rawValue
        }
    }
    // Margin/safe-area facts: which views inset their margins, and by how
    // much (the header row's width depends on the stack view's margins).
    let lm = v.layoutMargins, sa = v.safeAreaInsets
    entry["layoutMargins"] = [round3(lm.top), round3(lm.left), round3(lm.bottom), round3(lm.right)]
    entry["safeAreaInsets"] = [round3(sa.top), round3(sa.left), round3(sa.bottom), round3(sa.right)]
    entry["insetsLayoutMarginsFromSafeArea"] = v.insetsLayoutMarginsFromSafeArea
    entry["preservesSuperviewLayoutMargins"] = v.preservesSuperviewLayoutMargins
    if #available(iOS 26.0, *) {
        let desc = String(describing: v.cornerConfiguration)
        if !desc.contains("uniformCorners(radius: 0") && !desc.hasSuffix("none") { entry["cornerConfiguration"] = desc }
    }
    // Every layer under a UIDropShadowView (the sheet card): the corner
    // rounding is not on any VIEW's layer.cornerRadius, so list the layers.
    if String(describing: type(of: v)) == "UIDropShadowView" {
        func layerTree(_ l: CALayer, _ lp: String, _ acc: inout [[String: Any]]) {
            var d: [String: Any] = ["path": lp, "class": String(describing: type(of: l)),
                                    "frame": [round3(l.frame.origin.x), round3(l.frame.origin.y), round3(l.frame.width), round3(l.frame.height)],
                                    "cornerRadius": round3(l.cornerRadius), "cornerCurve": l.cornerCurve.rawValue,
                                    "masksToBounds": l.masksToBounds, "opacity": round3(CGFloat(l.opacity)),
                                    "hasMask": l.mask != nil, "delegateClass": l.delegate.map { String(describing: type(of: $0)) } ?? ""]
            if let kv = l.value(forKey: "cornerRadius") as? CGFloat { d["kvcCornerRadius"] = round3(kv) }
            if let m = l.mask {
                d["maskClass"] = String(describing: type(of: m)); d["maskRadius"] = round3(m.cornerRadius)
                if let s = m as? CAShapeLayer, let pth = s.path { let b = pth.boundingBox; d["maskPathBounds"] = [round3(b.origin.x), round3(b.origin.y), round3(b.width), round3(b.height)] }
            }
            if l.shadowOpacity != 0 { d["shadowOpacity"] = round3(CGFloat(l.shadowOpacity)); d["shadowRadius"] = round3(l.shadowRadius) }
            acc.append(d)
            for (i, sl) in (l.sublayers ?? []).enumerated() { layerTree(sl, lp.isEmpty ? "\(i)" : "\(lp).\(i)", &acc) }
        }
        var acc: [[String: Any]] = []
        layerTree(v.layer, "", &acc)
        entry["layerTree"] = acc
    }
    out.append(entry)
    for (i, sub) in v.subviews.enumerated() {
        dumpLayout(sub, path: path.isEmpty ? "\(i)" : "\(path).\(i)", into: &out)
    }
}

final class AppDelegate: NSObject, UIApplicationDelegate {
    var window: UIWindow?
    var index = 0

    func application(_ app: UIApplication,
                     didFinishLaunchingWithOptions o: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        variants = RealAppScreen.screens.compactMap { s in
            // Phone rows capture on the iPhone 16; pad rows on the iPad
            // (A16). Mixing them on one device would write an iPad-named
            // golden at phone geometry (or the reverse).
            let wantPad = s.idiom == .pad
            let isPad = UIDevice.current.userInterfaceIdiom == .pad
            guard wantPad == isPad else { return nil }
            return Variant(name: s.name, style: s.style, kind: s.variant, theme: s.theme,
                           presentsSheet: s.presentsSheet, contentSizeCategory: s.contentSizeCategory,
                           idiom: s.idiom)
        }
        let w = UIWindow(frame: UIScreen.main.bounds)
        window = w
        runNext()
        return true
    }

    func runNext() {
        guard index < variants.count, let w = window else {
            try! "ok".write(toFile: docsDir + "/DONE", atomically: true, encoding: .utf8)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { exit(0) }
            return
        }
        let v = variants[index]
        w.overrideUserInterfaceStyle = v.style
        // Dynamic Type override on the window before the screen is built
        // and before capture. `UITraitCollection(preferredContentSizeCategory:)`
        // is the value; iOS 17+ `traitOverrides` is the setter. Applied
        // every variant (including `.large`) so a previous `_xs`/`_ax1`
        // capture cannot leak into the next one on this reused window.
        let categoryTraits = UITraitCollection(preferredContentSizeCategory: v.contentSizeCategory)
        w.traitOverrides.preferredContentSizeCategory = v.contentSizeCategory
        // OptionsPicker.addAction sets fonts via UIFontMetrics (which reads
        // `UITraitCollection.current`) *before* the picker is added to the
        // window. Push the same category onto `current` so construction
        // matches the override the presented tree inherits.
        UITraitCollection.current = UITraitCollection(traitsFrom: [UITraitCollection.current, categoryTraits])
        let root = RealAppScreen.makeRoot(variant: v.kind, theme: v.theme)
        w.rootViewController = root
        w.makeKeyAndVisible()
        // viewDidAppear presents the picker with animated: true (0.4 s); the
        // openrender capture is taken at animationTime = 1.0, past the end.
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [self] in
            capture(v, window: w)
            guard v.presentsSheet else {
                // Nothing was presented, so there is nothing to dismiss; the
                // next variant simply replaces the window's root.
                index += 1
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { self.runNext() }
                return
            }
            root.dismiss(animated: false) {
                self.index += 1
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { self.runNext() }
            }
        }
    }

    func capture(_ v: Variant, window w: UIWindow) {
        currentVariant = v.name
        let format = UIGraphicsImageRendererFormat()
        // The device's own scale (3 on the iPhone 16): the layout dump is on
        // the 1/3-pt grid, so the pixels must be too; `openrender realapp`
        // renders at OPENUIKIT_REALAPP_SCALE=3 for the comparison.
        format.scale = UIScreen.main.scale
        // Extended range: sRGB values, and private materials still render
        // (see simscene/main.swift).
        format.preferredRange = .extended
        format.opaque = true
        let renderer = UIGraphicsImageRenderer(bounds: w.bounds, format: format)
        let img = renderer.image { _ in
            w.drawHierarchy(in: w.bounds, afterScreenUpdates: true)
        }
        try! img.pngData()!.write(to: URL(fileURLWithPath: "\(docsDir)/\(v.name).png"))
        var views: [[String: Any]] = []
        dumpLayout(w, path: "", into: &views)
        let layout: [String: Any] = ["name": v.name, "views": views,
                                     "contentSizeCategory": v.contentSizeCategory.rawValue,
                                     "windowContentSizeCategory": w.traitCollection.preferredContentSizeCategory.rawValue,
                                     "userInterfaceIdiom": UIDevice.current.userInterfaceIdiom == .pad ? "pad" : "phone",
                                     "screen": ["scale": Double(UIScreen.main.scale),
                                                "bounds": [round3(w.bounds.width), round3(w.bounds.height)]]]
        let data = try! JSONSerialization.data(withJSONObject: layout, options: [.sortedKeys])
        try! data.write(to: URL(fileURLWithPath: "\(docsDir)/\(v.name).layout.json"))
    }
}

let delegateClassName = NSStringFromClass(AppDelegate.self)
UIApplicationMain(CommandLine.argc, CommandLine.unsafeArgv, nil, delegateClassName)
