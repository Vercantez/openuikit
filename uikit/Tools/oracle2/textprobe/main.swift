// TextProbe on REAL iOS: the exact pen position CoreText gives every glyph
// of a UILabel's line, for a set of strings and fonts, so the port's
// advance + kerning model can be diffed against iOS glyph by glyph.
// Why: with real-iOS glyph masks in place (Tools/oracle2/inkprobe), the
// remaining text residual is per-glyph pen drift of up to 0.5 px
// (measured 2026-09-04 on label_align); this probe says which glyphs.
//
// Output: <Documents>/text_positions_ios.json =
//   {"cases": [{"text", "family", "size", "glyphs": [{"char", "x", "advance"}],
//               "lineWidth", "labelWidth"}]}
// x is the glyph origin in POINTS from the line origin (CTRunGetPositions),
// advance from CTRunGetAdvances; labelWidth is the label's sizeToFit width.
// Run: scripts/text_probe_sim.sh <outdir>
import UIKit
import CoreText

let docsDir = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
func r4(_ v: CGFloat) -> Double { (Double(v) * 10000).rounded() / 10000 }

let strings = ["Left aligned", "Center aligned", "Right aligned", "Tall frame vertical centering",
               "This text is definitely too long to fit", "The quick brown fox", "Hello UIKit",
               "0123456789 !@#$%", "Large Title", "Fixed frame label", "AVAST Wavy To. LT", "iiiiillll",
               "Account", "Name", "Miguel", "Sign Out", "Show unread count", "Wi-Fi only", "Download",
               "Up Next Swipe", "Remove Download", "ROW ACTION"]
struct FontSpec { let family: String; let size: CGFloat; let font: UIFont }
let fonts: [FontSpec] = [
    FontSpec(family: "system-regular", size: 17, font: .systemFont(ofSize: 17)),
    FontSpec(family: "system-regular", size: 13, font: .systemFont(ofSize: 13)),
    FontSpec(family: "system-regular", size: 15, font: .systemFont(ofSize: 15)),
    FontSpec(family: "system-regular", size: 22, font: .systemFont(ofSize: 22)),
    FontSpec(family: "system-semibold", size: 17, font: .systemFont(ofSize: 17, weight: .semibold)),
    FontSpec(family: "system-semibold", size: 18, font: .systemFont(ofSize: 18, weight: .semibold)),
    FontSpec(family: "system-semibold", size: 16, font: .systemFont(ofSize: 16, weight: .semibold)),
    FontSpec(family: "system-bold", size: 13, font: .systemFont(ofSize: 13, weight: .bold)),
    FontSpec(family: "system-bold", size: 34, font: .systemFont(ofSize: 34, weight: .bold)),
    FontSpec(family: "system-medium", size: 17, font: .systemFont(ofSize: 17, weight: .medium)),
]

final class AppDelegate: NSObject, UIApplicationDelegate {
    var window: UIWindow?
    func application(_ app: UIApplication,
                     didFinishLaunchingWithOptions o: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        let w = UIWindow(frame: UIScreen.main.bounds)
        window = w
        w.rootViewController = UIViewController()
        w.makeKeyAndVisible()
        var cases: [[String: Any]] = []
        for f in fonts {
            for text in strings {
                let label = UILabel()
                label.font = f.font; label.text = text
                label.sizeToFit()
                // The same attributed string UILabel lays out (font only;
                // UILabel adds no kerning attribute of its own).
                let attr = NSAttributedString(string: text, attributes: [.font: f.font])
                let line = CTLineCreateWithAttributedString(attr)
                var glyphs: [[String: Any]] = []
                let runs = CTLineGetGlyphRuns(line) as! [CTRun]
                let chars = Array(text.utf16)
                for run in runs {
                    let n = CTRunGetGlyphCount(run)
                    var positions = [CGPoint](repeating: .zero, count: n)
                    var advances = [CGSize](repeating: .zero, count: n)
                    var indices = [CFIndex](repeating: 0, count: n)
                    CTRunGetPositions(run, CFRange(location: 0, length: n), &positions)
                    CTRunGetAdvances(run, CFRange(location: 0, length: n), &advances)
                    CTRunGetStringIndices(run, CFRange(location: 0, length: n), &indices)
                    for i in 0..<n {
                        let idx = indices[i]
                        let ch = idx < chars.count ? String(utf16CodeUnits: [chars[idx]], count: 1) : "?"
                        glyphs.append(["char": ch, "x": r4(positions[i].x), "advance": r4(advances[i].width)])
                    }
                }
                let width = CTLineGetTypographicBounds(line, nil, nil, nil)
                cases.append(["text": text, "family": f.family, "size": Double(f.size),
                              "glyphs": glyphs, "lineWidth": r4(CGFloat(width)),
                              "labelWidth": r4(label.frame.width), "labelHeight": r4(label.frame.height)])
            }
        }
        // Diagnostic renders: the same string through UILabel + drawHierarchy
        // (what the scene captures see) and through CTLineDraw into a bitmap
        // (what the ink harvest uses), both at scale 2 / sRGB / opaque white.
        for (i, text) in ["Left aligned", "The quick brown fox", "Center aligned"].enumerated() {
            let f = UIFont.systemFont(ofSize: 17)
            let host = UIView(frame: CGRect(x: 0, y: 200, width: 320, height: 60))
            host.backgroundColor = .white
            w.rootViewController!.view.addSubview(host)
            let label = UILabel(frame: CGRect(x: 10, y: 20, width: 300, height: 22))
            label.font = f; label.text = text; label.textColor = .label
            host.addSubview(label)
            host.layoutIfNeeded()
            let fmt = UIGraphicsImageRendererFormat(); fmt.scale = 2; fmt.opaque = true; fmt.preferredRange = .standard
            let img = UIGraphicsImageRenderer(size: host.bounds.size, format: fmt).image { _ in
                host.drawHierarchy(in: host.bounds, afterScreenUpdates: true)
            }
            try! img.pngData()!.write(to: URL(fileURLWithPath: "\(docsDir)/diag_label_\(i).png"))
            // CoreText at the same geometry: pen x 10, baseline = 20 + (22 - lineHeight)/2 + ascender.
            let img2 = UIGraphicsImageRenderer(size: host.bounds.size, format: fmt).image { rc in
                let ctx = rc.cgContext
                UIColor.white.setFill(); ctx.fill(host.bounds)
                let attr = NSAttributedString(string: text, attributes: [.font: f, .foregroundColor: UIColor.label])
                let line = CTLineCreateWithAttributedString(attr)
                ctx.textMatrix = CGAffineTransform(scaleX: 1, y: -1)
                ctx.textPosition = CGPoint(x: 10, y: 20 + (22 - f.lineHeight) / 2 + f.ascender)
                CTLineDraw(line, ctx)
            }
            try! img2.pngData()!.write(to: URL(fileURLWithPath: "\(docsDir)/diag_ct_\(i).png"))
            host.removeFromSuperview()
        }
        // Alignment diagnostic: a right- and a centre-aligned 300 pt label
        // (drawHierarchy) next to CTLineDraw renders at candidate origins,
        // so the origin rule UILabel applies can be read off pixel-exactly.
        var alignDiag: [String: Any] = [:]
        for (i, (text, align)) in [("Right aligned", NSTextAlignment.right), ("Center aligned", .center)].enumerated() {
            let f = UIFont.systemFont(ofSize: 17)
            let host = UIView(frame: CGRect(x: 0, y: 300, width: 320, height: 60)); host.backgroundColor = .white
            w.rootViewController!.view.addSubview(host)
            let label = UILabel(frame: CGRect(x: 10, y: 20, width: 300, height: 22))
            label.font = f; label.text = text; label.textColor = .label; label.textAlignment = align
            host.addSubview(label); host.layoutIfNeeded()
            let fmt = UIGraphicsImageRendererFormat(); fmt.scale = 2; fmt.opaque = true; fmt.preferredRange = .extended
            let img = UIGraphicsImageRenderer(size: host.bounds.size, format: fmt).image { _ in
                host.drawHierarchy(in: host.bounds, afterScreenUpdates: true)
            }
            try! img.pngData()!.write(to: URL(fileURLWithPath: "\(docsDir)/align_label_\(i).png"))
            let attr = NSAttributedString(string: text, attributes: [.font: f])
            let line = CTLineCreateWithAttributedString(attr)
            let width = CGFloat(CTLineGetTypographicBounds(line, nil, nil, nil))
            let exact = align == .right ? 300 - width : (300 - width) / 2
            alignDiag["\(i)_lineWidth"] = Double(width); alignDiag["\(i)_exactOrigin"] = Double(10 + exact)
            let candidates: [(String, CGFloat)] = [("exact", exact), ("floorHalf", (exact * 2).rounded(.down) / 2), ("nearestHalf", (exact * 2).rounded() / 2),
                                                   ("floorThird", (exact * 3).rounded(.down) / 3), ("nearestThird", (exact * 3).rounded() / 3), ("floor", exact.rounded(.down)), ("ceilWidthHalf", align == .right ? 300 - (width * 2).rounded(.up) / 2 : (300 - (width * 2).rounded(.up) / 2) / 2)]
            for (name, origin) in candidates {
                let img2 = UIGraphicsImageRenderer(size: host.bounds.size, format: fmt).image { rc in
                    let ctx = rc.cgContext; UIColor.white.setFill(); ctx.fill(host.bounds)
                    let a2 = NSAttributedString(string: text, attributes: [.font: f, .foregroundColor: UIColor.label])
                    let l2 = CTLineCreateWithAttributedString(a2)
                    ctx.textMatrix = CGAffineTransform(scaleX: 1, y: -1)
                    ctx.textPosition = CGPoint(x: 10 + origin, y: 20 + (22 - f.lineHeight) / 2 + f.ascender)
                    CTLineDraw(l2, ctx)
                }
                try! img2.pngData()!.write(to: URL(fileURLWithPath: "\(docsDir)/align_ct_\(i)_\(name).png"))
                alignDiag["\(i)_\(name)"] = Double(10 + origin)
            }
            host.removeFromSuperview()
        }
        let data = try! JSONSerialization.data(withJSONObject: ["cases": cases, "device": UIDevice.current.systemVersion, "alignDiag": alignDiag],
                                               options: [.sortedKeys])
        try! data.write(to: URL(fileURLWithPath: "\(docsDir)/text_positions_ios.json"))
        try! "ok".write(toFile: docsDir + "/DONE", atomically: true, encoding: .utf8)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { exit(0) }
        return true
    }
}

UIApplicationMain(CommandLine.argc, CommandLine.unsafeArgv, nil, NSStringFromClass(AppDelegate.self))
