// SymbolInkProbe on REAL iOS: harvests per-symbol coverage masks from real
// UIKit on the iOS 26 simulator, in the shape Resources/symbol_ink_ios.json
// carries (key "name|pointSize|weight|scale|phase" -> {pw, ph, w, h, ox, oy, m}).
//
// Method (same as the tab-bar harvest, docs/agent_reports/symbols-tabbar.md):
// a UIImageView showing UIImage(systemName:withConfiguration:) at each
// configuration real apps use, UIColor.label over opaque white,
// coverage = 255 − gray. 2x: two phase masks (integer vs half device-pixel
// view origin). 3x: one mask (F0). Alignment-box coverage only (ink crop
// + ox,oy into the alignment bitmap) so the resource stays under 6 MB.
//
// Also dumps live UIImageView.preferredSymbolConfiguration from a tab bar,
// a nav-bar button, and an unconfigured UIImageView, plus each
// UIImage.configuration, so the configuration table is measured, not guessed.
//
// Output: <Documents>/symbol_ink_ios.json, symbol_configs.json, then DONE.
// Run: scripts/symbol_ink_probe_sim.sh <outdir>
//      SIM_DEVICE=2x for the SE; SIMCTL_CHILD_INK_SCALE=3 on the iPhone 16.
import UIKit

let docsDir = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]

let inkScale: CGFloat = {
    if let s = ProcessInfo.processInfo.environment["INK_SCALE"], let v = Double(s), v > 0 {
        return CGFloat(v)
    }
    return UIScreen.main.scale
}()

func weightName(_ w: UIImage.SymbolWeight) -> String {
    switch w {
    case .unspecified: return "unspecified"
    case .ultraLight: return "ultraLight"
    case .thin: return "thin"
    case .light: return "light"
    case .regular: return "regular"
    case .medium: return "medium"
    case .semibold: return "semibold"
    case .bold: return "bold"
    case .heavy: return "heavy"
    case .black: return "black"
    @unknown default: return "w\(w.rawValue)"
    }
}

func scaleName(_ s: UIImage.SymbolScale) -> String {
    switch s {
    case .unspecified: return "unspecified"
    case .small: return "small"
    case .medium: return "medium"
    case .large: return "large"
    case .default: return "default"
    @unknown default: return "s\(s.rawValue)"
    }
}

func parsePointSize(_ desc: String) -> Double? {
    // "pointSize = 18.000000" or "pointSize=18"
    let keys = ["pointSize = ", "pointSize="]
    for k in keys {
        guard let r = desc.range(of: k) else { continue }
        let rest = desc[r.upperBound...]
        var num = ""
        for ch in rest {
            if (ch >= "0" && ch <= "9") || ch == "." { num.append(ch) }
            else { break }
        }
        if let v = Double(num) { return v }
    }
    return nil
}

func parseWeight(_ desc: String) -> String {
    let names = ["UltraLight", "Thin", "Light", "Regular", "Medium",
                 "Semibold", "Bold", "Heavy", "Black", "Unspecified"]
    for n in names {
        if desc.contains(n) {
            if n == "UltraLight" { return "ultraLight" }
            if n == "Semibold" { return "semibold" }
            return String(n.prefix(1)).lowercased() + String(n.dropFirst())
        }
    }
    return "unknown"
}

func parseScale(_ desc: String) -> String {
    // Prefer the scale= token so "pointSize=18" does not match "small".
    if let r = desc.range(of: "scale") {
        let rest = desc[r.lowerBound...]
        if rest.contains("Unspecified") { return "unspecified" }
        if rest.contains("Small") { return "small" }
        if rest.contains("Medium") { return "medium" }
        if rest.contains("Large") { return "large" }
        if rest.contains("Default") { return "default" }
    }
    return "unknown"
}

func configKey(pointSize: CGFloat, weight: String, scale: String) -> String {
    let pt: String
    if pointSize == pointSize.rounded() {
        pt = String(Int(pointSize))
    } else {
        pt = String(format: "%.3f", Double(pointSize))
    }
    return "\(pt)|\(weight)|\(scale)"
}

struct HarvestConfig {
    let key: String
    let configuration: UIImage.SymbolConfiguration?
    let label: String
}

func dumpConfig(_ c: UIImage.SymbolConfiguration?) -> [String: Any] {
    guard let c else { return ["raw": "nil"] }
    let desc = String(describing: c)
    var out: [String: Any] = ["raw": desc]
    if let ps = parsePointSize(desc) { out["pointSize"] = ps }
    out["weight"] = parseWeight(desc)
    out["scale"] = parseScale(desc)
    return out
}

func walkImageViews(_ view: UIView, prefix: String, into out: inout [[String: Any]]) {
    if let iv = view as? UIImageView {
        var row: [String: Any] = [
            "path": prefix,
            "frame": [Double(iv.frame.minX), Double(iv.frame.minY),
                      Double(iv.frame.width), Double(iv.frame.height)],
            "preferred": dumpConfig(iv.preferredSymbolConfiguration),
        ]
        if let img = iv.image {
            row["imageSize"] = [Double(img.size.width), Double(img.size.height)]
            row["imageConfig"] = dumpConfig(img.symbolConfiguration)
            if let cg = img.cgImage {
                row["cgImage"] = [cg.width, cg.height]
            }
        }
        out.append(row)
    }
    for (i, sub) in view.subviews.enumerated() {
        walkImageViews(sub, prefix: "\(prefix)/\(type(of: sub))[\(i)]", into: &out)
    }
}

struct Capture {
    let gray: [UInt8]
    let w: Int
    let h: Int
}

func captureView(_ host: UIView, size: CGSize) -> Capture {
    host.layoutIfNeeded()
    let fmt = UIGraphicsImageRendererFormat()
    fmt.scale = inkScale
    fmt.opaque = true
    fmt.preferredRange = .standard
    let img = UIGraphicsImageRenderer(size: size, format: fmt).image { _ in
        host.drawHierarchy(in: CGRect(origin: .zero, size: size), afterScreenUpdates: true)
    }
    let cg = img.cgImage!
    let w = cg.width, h = cg.height
    var rgba = [UInt8](repeating: 0, count: w * h * 4)
    let ctx = CGContext(data: &rgba, width: w, height: h, bitsPerComponent: 8,
                         bytesPerRow: w * 4,
                         space: CGColorSpace(name: CGColorSpace.sRGB)!,
                         bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    ctx.draw(cg, in: CGRect(x: 0, y: 0, width: w, height: h))
    var gray = [UInt8](repeating: 0, count: w * h)
    for i in 0..<(w * h) {
        let r = Int(rgba[i * 4]), g = Int(rgba[i * 4 + 1]), b = Int(rgba[i * 4 + 2])
        gray[i] = UInt8(255 - (r + g + b) / 3)
    }
    return Capture(gray: gray, w: w, h: h)
}

func hexEncode(_ bytes: [UInt8]) -> String {
    let hex = Array("0123456789abcdef".utf8)
    var out = [UInt8](repeating: 0, count: bytes.count * 2)
    var i = 0
    while i < bytes.count {
        let b = bytes[i]
        out[i * 2] = hex[Int(b >> 4)]
        out[i * 2 + 1] = hex[Int(b & 0x0F)]
        i += 1
    }
    return String(decoding: out, as: UTF8.self)
}

func harvestOne(name: String, configuration: UIImage.SymbolConfiguration?,
                  origin: CGPoint, host: UIView, iv: UIImageView) -> [String: Any]? {
    let image: UIImage?
    if let configuration {
        image = UIImage(systemName: name, withConfiguration: configuration)
    } else {
        image = UIImage(systemName: name)
    }
    guard let image else { return nil }
    iv.image = image
    iv.tintColor = .label
    iv.preferredSymbolConfiguration = configuration
    iv.frame = CGRect(origin: origin, size: image.size)
    let cap = captureView(host, size: host.bounds.size)
    let vx = Int((origin.x * inkScale).rounded(.down))
    let vy = Int((origin.y * inkScale).rounded(.down))
    let pw = Int((image.size.width * inkScale).rounded())
    let ph = Int((image.size.height * inkScale).rounded())
    var minX = cap.w, minY = cap.h, maxX = -1, maxY = -1
    let x0 = max(0, vx), y0 = max(0, vy)
    let x1 = min(cap.w, vx + pw), y1 = min(cap.h, vy + ph)
    guard x1 > x0, y1 > y0 else { return nil }
    for y in y0..<y1 {
        for x in x0..<x1 where cap.gray[y * cap.w + x] > 0 {
            if x < minX { minX = x }
            if x > maxX { maxX = x }
            if y < minY { minY = y }
            if y > maxY { maxY = y }
        }
    }
    guard maxX >= 0 else { return nil }
    let bw = maxX - minX + 1, bh = maxY - minY + 1
    var bytes = [UInt8](repeating: 0, count: bw * bh)
    var row = 0
    while row < bh {
        var col = 0
        while col < bw {
            bytes[row * bw + col] = cap.gray[(minY + row) * cap.w + (minX + col)]
            col += 1
        }
        row += 1
    }
    // Alignment-box coverage only (ink crop + ox,oy). Do not store RGBA or
    // the CGImage size: the resource budget is 6 MB.
    return [
        "pw": pw, "ph": ph, "w": bw, "h": bh,
        "ox": minX - vx, "oy": minY - vy,
        "m": hexEncode(bytes),
    ]
}

final class AppDelegate: NSObject, UIApplicationDelegate {
    var window: UIWindow?

    func application(_ app: UIApplication,
                     didFinishLaunchingWithOptions o: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        let w = UIWindow(frame: UIScreen.main.bounds)
        window = w
        let vc = UIViewController()
        w.rootViewController = vc
        w.makeKeyAndVisible()
        w.overrideUserInterfaceStyle = .light

        let namesPath = Bundle.main.path(forResource: "names", ofType: "txt")!
        let names = try! String(contentsOfFile: namesPath, encoding: .utf8)
            .split(separator: "\n").map(String.init).filter { !$0.isEmpty }

        // --- live configuration dump ---------------------------------------
        var live: [String: Any] = [:]

        let unconfigured = UIImage(systemName: "calendar")
        live["unconfiguredCalendar"] = [
            "size": unconfigured.map { [Double($0.size.width), Double($0.size.height)] } as Any,
            "configuration": dumpConfig(unconfigured?.symbolConfiguration),
        ]
        let defaultView = UIImageView(image: unconfigured)
        defaultView.sizeToFit()
        live["defaultUIImageView"] = [
            "preferred": dumpConfig(defaultView.preferredSymbolConfiguration),
            "frame": [Double(defaultView.frame.width), Double(defaultView.frame.height)],
        ]

        let tab = UITabBarController()
        let a = UIViewController()
        a.tabBarItem = UITabBarItem(title: "Search",
                                     image: UIImage(systemName: "calendar"), tag: 0)
        let b = UIViewController()
        b.tabBarItem = UITabBarItem(title: "Tools",
                                     image: UIImage(systemName: "plus.circle.fill"), tag: 1)
        let c = UIViewController()
        c.tabBarItem = UITabBarItem(title: "Scroll",
                                     image: UIImage(systemName: "clock"), tag: 2)
        tab.viewControllers = [a, b, c]
        vc.addChild(tab)
        tab.view.frame = vc.view.bounds
        vc.view.addSubview(tab.view)
        tab.didMove(toParent: vc)
        tab.view.layoutIfNeeded()
        var tabViews: [[String: Any]] = []
        walkImageViews(tab.tabBar, prefix: "tabBar", into: &tabViews)
        live["tabBar"] = tabViews

        let nav = UINavigationController(rootViewController: UIViewController())
        nav.topViewController?.navigationItem.rightBarButtonItem =
            UIBarButtonItem(image: UIImage(systemName: "plus"), style: .plain,
                            target: nil, action: nil)
        nav.topViewController?.navigationItem.leftBarButtonItem =
            UIBarButtonItem(image: UIImage(systemName: "xmark"), style: .plain,
                            target: nil, action: nil)
        // Isolated nav, laid out in a second window-sized host so it does not
        // fight the tab controller.
        let navHost = UIView(frame: vc.view.bounds)
        navHost.isHidden = true
        vc.view.addSubview(navHost)
        navHost.addSubview(nav.view)
        nav.view.frame = navHost.bounds
        nav.view.layoutIfNeeded()
        var barViews: [[String: Any]] = []
        walkImageViews(nav.navigationBar, prefix: "navBar", into: &barViews)
        live["barButton"] = barViews

        let body = UIImage.SymbolConfiguration(textStyle: .body)
        live["bodyTextStyle"] = dumpConfig(body)
        let bodyView = UIImageView(image: UIImage(systemName: "calendar",
                                                    withConfiguration: body))
        bodyView.sizeToFit()
        live["bodyUIImageView"] = [
            "preferred": dumpConfig(bodyView.preferredSymbolConfiguration),
            "frame": [Double(bodyView.frame.width), Double(bodyView.frame.height)],
            "imageSize": bodyView.image.map { [Double($0.size.width), Double($0.size.height)] } as Any,
        ]

        live["device"] = [
            "system": UIDevice.current.systemVersion,
            "model": UIDevice.current.model,
            "scale": Double(UIScreen.main.scale),
            "inkScale": Double(inkScale),
            "bounds": [Double(UIScreen.main.bounds.width),
                       Double(UIScreen.main.bounds.height)],
        ]

        let cfgData = try! JSONSerialization.data(withJSONObject: live,
                                              options: [.sortedKeys, .prettyPrinted])
        try! cfgData.write(to: URL(fileURLWithPath: "\(docsDir)/symbol_configs.json"))

        // --- harvest configurations ---------------------------------------
        // MEASURED below (symbol_configs.json): default UIImage(systemName:)
        // is the body text-style configuration; tab-bar image views dump
        // pointSize=18, weight=Medium, scale=Large; bar-button image views
        // dump the live preferredSymbolConfiguration recorded in that file.
        var configs: [HarvestConfig] = [
            HarvestConfig(key: "default", configuration: nil, label: "unconfigured"),
            HarvestConfig(key: "17|regular|unspecified",
                          configuration: UIImage.SymbolConfiguration(pointSize: 17,
                                                                      weight: .regular),
                          label: "17 regular (body point size, default weight)"),
            HarvestConfig(key: "17|regular|large",
                          configuration: UIImage.SymbolConfiguration(pointSize: 17,
                                                                      weight: .regular,
                                                                      scale: .large),
                          label: "17 regular large (brief bar-button candidate)"),
            HarvestConfig(key: "17|medium|large",
                          configuration: UIImage.SymbolConfiguration(pointSize: 17,
                                                                      weight: .medium,
                                                                      scale: .large),
                          label: "17 medium large (body @ Large + bar-button weight/scale)"),
            HarvestConfig(key: "body|medium|large",
                          configuration: UIImage.SymbolConfiguration(textStyle: .body, scale: .large)
                            .applying(UIImage.SymbolConfiguration(weight: .medium)),
                          label: "live bar-button preferred: textStyle=body weight=Medium scale=Large"),
            HarvestConfig(key: "18|medium|large",
                          configuration: UIImage.SymbolConfiguration(pointSize: 18,
                                                                      weight: .medium,
                                                                      scale: .large),
                          label: "18 medium large (tab bar)"),
        ]

        // If the live dump named a configuration we do not already harvest,
        // add it. Tab-bar / bar-button preferred configs are the ones the
        // views actually stamp.
        func addLive(_ row: [String: Any], label: String) {
            guard let preferred = row["preferred"] as? [String: Any],
                  let ps = preferred["pointSize"] as? Double,
                  let w = preferred["weight"] as? String,
                  let s = preferred["scale"] as? String,
                  w != "unknown", s != "unknown" else { return }
            let key = configKey(pointSize: CGFloat(ps), weight: w, scale: s)
            if configs.contains(where: { $0.key == key }) { return }
            let weightMap: [String: UIImage.SymbolWeight] = [
                "unspecified": .unspecified, "ultraLight": .ultraLight,
                "thin": .thin, "light": .light, "regular": .regular,
                "medium": .medium, "semibold": .semibold, "bold": .bold,
                "heavy": .heavy, "black": .black,
            ]
            let scaleMap: [String: UIImage.SymbolScale] = [
                "unspecified": .unspecified, "small": .small,
                "medium": .medium, "large": .large, "default": .default,
            ]
            guard let ww = weightMap[w], let ss = scaleMap[s] else { return }
            configs.append(HarvestConfig(
                key: key,
                configuration: UIImage.SymbolConfiguration(pointSize: CGFloat(ps),
                                                         weight: ww, scale: ss),
                label: label))
        }
        for row in tabViews { addLive(row, label: "live-tabBar") }
        for row in barViews { addLive(row, label: "live-barButton") }

        let phases: [(String, CGPoint)]
        if inkScale == 3 {
            phases = [("F0", CGPoint(x: 20, y: 20))]
        } else {
            // Half a device pixel at 2x is 0.25 pt.
            phases = [
                ("F0", CGPoint(x: 20, y: 20)),
                ("F0.5", CGPoint(x: 20.25, y: 20)),
            ]
        }

        let host = UIView(frame: CGRect(x: 0, y: 0, width: 160, height: 120))
        host.backgroundColor = .white
        host.overrideUserInterfaceStyle = .light
        vc.view.addSubview(host)
        let iv = UIImageView()
        iv.contentMode = .center
        host.addSubview(iv)

        var entries: [String: Any] = [:]
        var skipped: [String] = []
        var present: [String] = []
        var missingNames: [String] = []

        for name in names {
            var any = false
            for cfg in configs {
                let probe: UIImage?
                if let configuration = cfg.configuration {
                    probe = UIImage(systemName: name, withConfiguration: configuration)
                } else {
                    probe = UIImage(systemName: name)
                }
                if probe == nil {
                    skipped.append("\(name)|\(cfg.key) (nil)")
                    continue
                }
                any = true
                for (phase, origin) in phases {
                    let key = "\(name)|\(cfg.key)|\(phase)"
                    if let rec = harvestOne(name: name, configuration: cfg.configuration,
                                            origin: origin, host: host, iv: iv) {
                        entries[key] = rec
                    } else {
                        skipped.append("\(key) (no ink)")
                    }
                }
            }
            if any { present.append(name) } else { missingNames.append(name) }
        }

        let out: [String: Any] = [
            "version": 2,
            "calibration": "label-opaque",
            "device": UIDevice.current.systemVersion,
            "scale": Int(inkScale),
            "probe": "symbolinkprobe UIImageView(image: UIImage(systemName:withConfiguration:)); UIColor.label over opaque white; coverage=255-gray; keys name|pointSize|weight|scale|phase; SE 2x / iPhone 16 3x / iOS 26.1",
            "configurations": configs.map { ["key": $0.key, "label": $0.label] },
            "names": present,
            "missingNames": missingNames,
            "skipped": skipped,
            "entries": entries,
        ]
        let data = try! JSONSerialization.data(withJSONObject: out, options: [.sortedKeys])
        try! data.write(to: URL(fileURLWithPath: "\(docsDir)/symbol_ink_ios.json"))
        try! "ok".write(toFile: docsDir + "/DONE", atomically: true, encoding: .utf8)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { exit(0) }
        return true
    }
}

UIApplicationMain(CommandLine.argc, CommandLine.unsafeArgv, nil, NSStringFromClass(AppDelegate.self))
