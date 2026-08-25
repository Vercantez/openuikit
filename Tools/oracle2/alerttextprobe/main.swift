// AlertTextProbe: why does the alert TITLE drift while a plain label does not?
//
// Presents the exact `alert_dark` fixture alert in the iOS 26 simulator,
// walks to the title/message/action UILabels, and dumps for each of them:
//   - the font (name, size, descriptor attributes, variation axes)
//   - the label's attributedText attributes VERBATIM (kern / tracking, if any)
//   - CoreText glyph positions + advances of the label's OWN attributed
//     string, and of a plain `UIFont.systemFont` string for comparison
//   - the label frame in window coordinates
// Output: <Documents>/alerttext.json
import UIKit
import CoreText

let docsDir = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]

func fontDump(_ f: UIFont) -> [String: Any] {
    var d: [String: Any] = [
        "name": f.fontName,
        "family": f.familyName,
        "size": Double(f.pointSize),
        "ascender": Double(f.ascender),
        "descender": Double(f.descender),
        "lineHeight": Double(f.lineHeight),
        "capHeight": Double(f.capHeight),
        "xHeight": Double(f.xHeight),
    ]
    let ct = f as CTFont
    if let axes = CTFontCopyVariationAxes(ct) as? [[String: Any]] {
        d["axes"] = axes.map { a in
            var o: [String: Any] = [:]
            for (k, v) in a { o["\(k)"] = "\(v)" }
            return o
        }
    }
    if let vari = CTFontCopyVariation(ct) as? [AnyHashable: Any] {
        var o: [String: Any] = [:]
        for (k, v) in vari { o["\(k)"] = "\(v)" }
        d["variation"] = o
    }
    var attrs: [String: String] = [:]
    for (k, v) in f.fontDescriptor.fontAttributes { attrs[k.rawValue] = "\(v)" }
    d["descriptorAttributes"] = attrs
    // trak-table tracking CoreText would apply at this size, if any.
    if let t = CTFontCopyTable(ct, CTFontTableTag(kCTFontTableTrak), []) {
        d["hasTrakTable"] = CFDataGetLength(t)
    }
    return d
}

/// Per-glyph run positions of a CTLine.
func lineDump(_ s: NSAttributedString) -> [String: Any] {
    let line = CTLineCreateWithAttributedString(s)
    var out: [[String: Any]] = []
    for r in (CTLineGetGlyphRuns(line) as! [CTRun]) {
        let n = CTRunGetGlyphCount(r)
        var pos = [CGPoint](repeating: .zero, count: n)
        var adv = [CGSize](repeating: .zero, count: n)
        var glyphs = [CGGlyph](repeating: 0, count: n)
        var idx = [CFIndex](repeating: 0, count: n)
        CTRunGetPositions(r, CFRangeMake(0, n), &pos)
        CTRunGetAdvances(r, CFRangeMake(0, n), &adv)
        CTRunGetGlyphs(r, CFRangeMake(0, n), &glyphs)
        CTRunGetStringIndices(r, CFRangeMake(0, n), &idx)
        var runAttrs: [String: String] = [:]
        for (k, v) in (CTRunGetAttributes(r) as! [CFString: Any]) { runAttrs["\(k)"] = "\(v)" }
        out.append([
            "glyphCount": n,
            "positions": pos.map { Double($0.x) },
            "advances": adv.map { Double($0.width) },
            "glyphs": glyphs.map { Int($0) },
            "stringIndices": idx.map { Int($0) },
            "attrs": runAttrs,
        ])
    }
    var asc: CGFloat = 0, desc: CGFloat = 0, lead: CGFloat = 0
    let w = CTLineGetTypographicBounds(line, &asc, &desc, &lead)
    return ["runs": out, "width": Double(w),
            "ascent": Double(asc), "descent": Double(desc), "leading": Double(lead),
            "imageBounds": {
                let b = CTLineGetImageBounds(line, nil)
                return [Double(b.minX), Double(b.minY), Double(b.width), Double(b.height)]
            }()]
}

func attrDump(_ s: NSAttributedString) -> [[String: Any]] {
    var out: [[String: Any]] = []
    s.enumerateAttributes(in: NSRange(location: 0, length: s.length)) { a, r, _ in
        var m: [String: String] = [:]
        for (k, v) in a { m[k.rawValue] = "\(v)" }
        out.append(["range": [r.location, r.length], "attrs": m])
    }
    return out
}

func labelDump(_ l: UILabel, in window: UIWindow) -> [String: Any] {
    let f = l.convert(l.bounds, to: window)
    var d: [String: Any] = [
        "class": NSStringFromClass(type(of: l)),
        "text": l.text ?? "",
        "frame": [Double(f.minX), Double(f.minY), Double(f.width), Double(f.height)],
        "alignment": l.textAlignment.rawValue,
        "font": fontDump(l.font),
        "numberOfLines": l.numberOfLines,
        "adjustsFontSizeToFitWidth": l.adjustsFontSizeToFitWidth,
        "minimumScaleFactor": Double(l.minimumScaleFactor),
        "lineBreakMode": l.lineBreakMode.rawValue,
    ]
    if let at = l.attributedText {
        d["attributed"] = attrDump(at)
        d["ctLineOfAttributedText"] = lineDump(at)
    }
    // Same string with a PLAIN systemFont of the same size/weight, so the two
    // CTLines can be diffed directly.
    if let t = l.text {
        d["ctLineWithLabelFont"] = lineDump(NSAttributedString(string: t, attributes: [.font: l.font!]))
    }
    d["intrinsic"] = [Double(l.intrinsicContentSize.width), Double(l.intrinsicContentSize.height)]
    d["sizeThatFits"] = {
        let s = l.sizeThatFits(CGSize(width: 10_000, height: 10_000))
        return [Double(s.width), Double(s.height)]
    }()
    return d
}

func collectLabels(_ v: UIView, into out: inout [UILabel]) {
    if let l = v as? UILabel { out.append(l) }
    for s in v.subviews { collectLabels(s, into: &out) }
}

final class AppDelegate: NSObject, UIApplicationDelegate {
    var window: UIWindow?
    func application(_ app: UIApplication,
                     didFinishLaunchingWithOptions o: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        let w = UIWindow(frame: UIScreen.main.bounds)
        window = w
        let host = UIViewController()
        host.view.backgroundColor = UIColor(white: 0.2, alpha: 1)
        w.rootViewController = host
        w.overrideUserInterfaceStyle = .dark
        w.makeKeyAndVisible()
        RunLoop.current.run(until: Date().addingTimeInterval(0.3))

        let ac = UIAlertController(title: "Delete File?",
                                   message: "This cannot be undone.",
                                   preferredStyle: .alert)
        ac.overrideUserInterfaceStyle = .dark
        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        ac.addAction(UIAlertAction(title: "Delete", style: .destructive))
        host.present(ac, animated: false)
        RunLoop.current.run(until: Date().addingTimeInterval(0.6))
        w.layoutIfNeeded()
        RunLoop.current.run(until: Date().addingTimeInterval(0.2))

        var labels: [UILabel] = []
        collectLabels(w, into: &labels)

        // Reference: a PLAIN UILabel of the same string/font in the same window.
        let ref = UILabel()
        ref.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        ref.text = "Delete File?"
        ref.sizeToFit()
        host.view.addSubview(ref)
        ref.frame = CGRect(x: 66.5, y: 200, width: 260, height: 21)
        w.layoutIfNeeded()

        var out: [String: Any] = [
            "labels": labels.map { labelDump($0, in: w) },
            "referencePlainLabel": labelDump(ref, in: w),
        ]
        // Candidate fonts the alert title might really be.
        var cands: [String: Any] = [:]
        for (n, f) in [
            "system17semibold": UIFont.systemFont(ofSize: 17, weight: .semibold),
            "headline": UIFont.preferredFont(forTextStyle: .headline),
            "body": UIFont.preferredFont(forTextStyle: .body),
            "system17regular": UIFont.systemFont(ofSize: 17, weight: .regular),
        ] {
            cands[n] = ["font": fontDump(f),
                        "line": lineDump(NSAttributedString(string: "Delete File?",
                                                            attributes: [.font: f]))]
        }
        out["candidates"] = cands
        let data = try! JSONSerialization.data(withJSONObject: out,
                                               options: [.prettyPrinted, .sortedKeys])
        try! data.write(to: URL(fileURLWithPath: "\(docsDir)/alerttext.json"))
        try! "ok".write(toFile: docsDir + "/DONE", atomically: true, encoding: .utf8)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { exit(0) }
        return true
    }
}

let delegateClassName = NSStringFromClass(AppDelegate.self)
UIApplicationMain(CommandLine.argc, CommandLine.unsafeArgv, nil, delegateClassName)
