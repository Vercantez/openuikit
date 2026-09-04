// InkProbe on REAL iOS: harvests per-glyph ink masks from real UIKit on the
// iOS 26 simulator, in the exact shape Resources/glyph_ink.json carries for
// Mac Catalyst (GlyphInkTable.swift: key "family|size|light/dark|phase|scalar"
// -> {w, h, ox, oy, m}), so OpenUIKit can draw iOS text from measured data
// the way it draws Catalyst text.
//
// Why: the whole-suite comparison against real iOS (scripts/ios_suite.sh,
// 2026-09-04) showed iOS glyphs crisper and ~20 % lighter than the
// Catalyst-harvested masks, one pixel lower — no portable model of CoreText's
// rasterization exists, so the masks are measured, exactly as for Catalyst.
//
// Method (mirrors the Catalyst harvest's pen model): for every key in the
// bundled keys.txt, a UILabel showing the single character is placed at
// x = 20 + phase (phase from GlyphInkTable.phase's table for the size),
// y = 20, its natural size; the label is captured at scale 2 in the standard
// (sRGB) range on an opaque contrast background (white in light, black in
// dark) with the system label colour; the mask is the coverage
// (255 - gray in light, gray in dark), cropped to its ink box. ox is the
// box's left pixel minus (2 * 20 + anchor); oy its top pixel minus the
// reference row round(2 * (top + (labelHeight - lineHeight) / 2 +
// ascender)) that the port's iOS label path computes identically. The
// bottom ink row of "H" + 1 per (family, size) is recorded in "baselines"
// as a cross-check only.
//
// Output: <Documents>/glyph_ink_ios.json then DONE.
// Run: scripts/ink_probe_sim.sh <outdir>
import UIKit

let docsDir = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]

func font(family: String, size: CGFloat) -> UIFont {
    let parts = family.split(separator: "-").map(String.init)
    let kind = parts[0], weightName = parts.count > 1 ? parts[1] : "regular"
    let weights: [String: UIFont.Weight] = [
        "ultraLight": .ultraLight, "thin": .thin, "light": .light, "regular": .regular,
        "medium": .medium, "semibold": .semibold, "bold": .bold, "heavy": .heavy, "black": .black,
    ]
    let w = weights[weightName] ?? .regular
    switch kind {
    case "mono": return .monospacedSystemFont(ofSize: size, weight: w)
    case "italic":
        let base = UIFont.systemFont(ofSize: size, weight: w)
        let d = base.fontDescriptor.withSymbolicTraits(.traitItalic) ?? base.fontDescriptor
        return UIFont(descriptor: d, size: size)
    default: return .systemFont(ofSize: size, weight: w)
    }
}

/// GlyphInkTable.phase, inverted: tag -> (fraction, anchor).
func phase(size: CGFloat, tag: String) -> (frac: CGFloat, anchor: Int)? {
    if size < 12 {
        switch tag { case "0": return (0, 0); case "P1": return (0.25, 0); case "P2": return (0.5, 1); case "P3": return (0.75, 1); default: break }
    } else if size < 16 {
        switch tag { case "0": return (0, 0); case "T": return (1.0 / 3.0, 0); case "H": return (0.5, 1); case "P2": return (2.0 / 3.0, 1); default: break }
    } else if size < 29 {
        switch tag { case "0": return (0, 0); case "P1": return (0.5, 1); default: break }
    } else if tag == "0" { return (0, 0) }
    // Sweep tags "F<fraction>" (any fraction, anchor floor(2 * fraction)):
    // for probing how many phases real iOS actually distinguishes.
    if tag.hasPrefix("F"), let fr = Double(tag.dropFirst()) {
        return (CGFloat(fr), Int((2 * fr).rounded(.down)))
    }
    // Legacy numeric tags "1","2","3" (quarter phases in the oldest table).
    switch tag { case "1": return (0.25, 0); case "2": return (0.5, 1); case "3": return (0.75, 1); default: return nil }
}

struct Capture { let gray: [UInt8]; let w: Int; let h: Int }

func capture(_ label: UILabel, dark: Bool, host: UIView) -> Capture {
    let size = CGSize(width: 200, height: 120)
    host.overrideUserInterfaceStyle = dark ? .dark : .light
    host.backgroundColor = dark ? .black : .white
    let fmt = UIGraphicsImageRendererFormat()
    fmt.scale = 2; fmt.opaque = true; fmt.preferredRange = .standard
    let img = UIGraphicsImageRenderer(size: size, format: fmt).image { _ in
        host.drawHierarchy(in: CGRect(origin: .zero, size: size), afterScreenUpdates: true)
    }
    let cg = img.cgImage!
    let w = cg.width, h = cg.height
    var rgba = [UInt8](repeating: 0, count: w * h * 4)
    let ctx = CGContext(data: &rgba, width: w, height: h, bitsPerComponent: 8, bytesPerRow: w * 4,
                        space: CGColorSpace(name: CGColorSpace.sRGB)!,
                        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    ctx.draw(cg, in: CGRect(x: 0, y: 0, width: w, height: h))
    var gray = [UInt8](repeating: 0, count: w * h)
    for i in 0..<(w * h) {
        let r = Int(rgba[i * 4]), g = Int(rgba[i * 4 + 1]), b = Int(rgba[i * 4 + 2])
        let v = (r + g + b) / 3
        gray[i] = UInt8(dark ? v : 255 - v)   // coverage of the label colour
    }
    return Capture(gray: gray, w: w, h: h)
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
        let host = UIView(frame: CGRect(x: 0, y: 100, width: 200, height: 120))
        vc.view.addSubview(host)
        let label = UILabel()
        host.addSubview(label)

        let keysPath = Bundle.main.path(forResource: "keys", ofType: "txt")!
        let keys = try! String(contentsOfFile: keysPath, encoding: .utf8)
            .split(separator: "\n").map(String.init).filter { !$0.isEmpty }
        var entries: [String: Any] = [:]
        var baselines: [String: Any] = [:]
        var skipped: [String] = []
        let originX: CGFloat = 20, originY: CGFloat = 20
        var baselineCache: [String: Int] = [:]

        func baselinePx(family: String, size: CGFloat, f: UIFont, dark: Bool) -> Int {
            let ck = "\(family)|\(Int(size))|\(dark ? "dark" : "light")"
            if let b = baselineCache[ck] { return b }
            label.font = f; label.text = "H"; label.textColor = .label
            label.frame = CGRect(x: originX, y: originY, width: 100, height: 0)
            label.sizeToFit()
            let cap = capture(label, dark: dark, host: host)
            var bottom = -1
            for y in 0..<cap.h { for x in 0..<cap.w where cap.gray[y * cap.w + x] > 127 { bottom = y } }
            let b = bottom + 1
            baselineCache[ck] = b
            baselines[ck] = ["baselinePx": b, "labelTopPx": Int(originY * 2),
                             "offsetPx": b - Int(originY * 2),
                             "labelHeight": Double(label.frame.height),
                             "ascender": Double(f.ascender), "lineHeight": Double(f.lineHeight)]
            return b
        }

        for key in keys {
            let p = key.split(separator: "|").map(String.init)
            guard p.count == 5, let sizeKey = Int(p[1]), let scalarValue = UInt32(p[4]),
                  let scalar = Unicode.Scalar(scalarValue) else { skipped.append(key); continue }
            let family = p[0], dark = p[2] == "dark", tag = p[3]
            let size = CGFloat(sizeKey)
            guard let ph = phase(size: size, tag: tag) else { skipped.append(key); continue }
            let f = font(family: family, size: size)
            let base = baselinePx(family: family, size: size, f: f, dark: dark)
            label.font = f; label.text = String(Character(scalar)); label.textColor = .label
            label.frame = CGRect(x: originX + ph.frac, y: originY, width: 150, height: 0)
            label.sizeToFit()
            let cap = capture(label, dark: dark, host: host)
            var minX = cap.w, minY = cap.h, maxX = -1, maxY = -1
            for y in 0..<cap.h { for x in 0..<cap.w where cap.gray[y * cap.w + x] > 0 {
                if x < minX { minX = x }; if x > maxX { maxX = x }
                if y < minY { minY = y }; if y > maxY { maxY = y }
            } }
            guard maxX >= 0 else { skipped.append(key + " (no ink)"); continue }
            let bw = maxX - minX + 1, bh = maxY - minY + 1
            var hex = ""
            hex.reserveCapacity(bw * bh * 2)
            for y in minY...maxY { for x in minX...maxX {
                let v = cap.gray[y * cap.w + x]
                hex += String(format: "%02x", v)
            } }
            // oy is relative to a REFERENCE row both sides compute the same
            // way, not to a measured baseline: round(2 * (labelTop +
            // (labelHeight - lineHeight) / 2 + ascender)). The port's iOS
            // label path uses exactly this (UILabel.swift, iOS cut), so the
            // masks carry the truth about where iOS puts the ink relative
            // to it; the measured "H" baseline is kept in "baselines" only
            // as a cross-check.
            let ref = Int(((originY + (label.frame.height - f.lineHeight) / 2 + f.ascender) * 2).rounded())
            entries[key] = ["w": bw, "h": bh,
                            "ox": minX - (Int(originX) * 2 + ph.anchor),
                            "oy": minY - ref,
                            "m": hex]
            _ = base
        }
        let out: [String: Any] = ["version": 1, "calibration": "opaque", "scale": 2,
                                  "device": UIDevice.current.systemVersion,
                                  "entries": entries, "baselines": baselines, "skipped": skipped]
        let data = try! JSONSerialization.data(withJSONObject: out, options: [.sortedKeys])
        try! data.write(to: URL(fileURLWithPath: "\(docsDir)/glyph_ink_ios.json"))
        try! "ok".write(toFile: docsDir + "/DONE", atomically: true, encoding: .utf8)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { exit(0) }
        return true
    }
}

UIApplicationMain(CommandLine.argc, CommandLine.unsafeArgv, nil, NSStringFromClass(AppDelegate.self))
