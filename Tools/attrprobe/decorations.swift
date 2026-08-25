// Probe 5: underline / strikethrough rect geometry sweep.
// The label is sized to exactly one line box so y0 == 0 and the baseline is
// unambiguous; the rule rect is recovered from a difference image by
// deconvolving CG's 3-tap text-smoothing blur (edge rows sit at ~12% of the
// plateau, so rows above half the peak are the rect's own rows).
import UIKit

let traits = UITraitCollection(userInterfaceStyle: .light)

func attr(_ text: String, _ f: UIFont, _ extra: [NSAttributedString.Key: Any]) -> NSAttributedString {
    var a: [NSAttributedString.Key: Any] = [.font: f, .foregroundColor: UIColor.black]
    for (k, v) in extra { a[k] = v }
    return NSAttributedString(string: text, attributes: a)
}

func render(_ s: NSAttributedString, w: CGFloat, h: CGFloat) -> (px: [UInt8], w: Int, h: Int) {
    let l = UILabel(frame: CGRect(x: 0, y: 0, width: w, height: h))
    l.numberOfLines = 1
    l.attributedText = s
    let scale: CGFloat = 2
    let pw = Int(w * scale), ph = Int(h * scale)
    let cs = CGColorSpace(name: CGColorSpace.sRGB)!
    let ctx = CGContext(data: nil, width: pw, height: ph, bitsPerComponent: 8,
                        bytesPerRow: pw * 4, space: cs,
                        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    ctx.setFillColor(UIColor.white.cgColor)
    ctx.fill(CGRect(x: 0, y: 0, width: CGFloat(pw), height: CGFloat(ph)))
    ctx.translateBy(x: 0, y: CGFloat(ph))
    ctx.scaleBy(x: scale, y: -scale)
    traits.performAsCurrent { l.layer.render(in: ctx) }
    let d = ctx.data!.bindMemory(to: UInt8.self, capacity: pw * ph * 4)
    var out = [UInt8](repeating: 0, count: pw * ph)
    for i in 0..<(pw * ph) { out[i] = d[i * 4] }
    return (out, pw, ph)
}

/// (topPx, thicknessPx) of the rule rect, relative to the label's top edge.
func rule(_ f: UIFont, key: NSAttributedString.Key) -> (top: Int, thick: Int, rows: [Double])? {
    let l0 = UILabel(); l0.font = f; l0.text = "nn"
    let lh = l0.sizeThatFits(CGSize(width: 1e4, height: 1e6)).height
    let W: CGFloat = 200
    let plain = render(attr("nn", f, [:]), w: W, h: lh)
    let deco = render(attr("nn", f, [key: NSUnderlineStyle.single.rawValue]), w: W, h: lh)
    var rowSum = [Double](repeating: 0, count: plain.h)
    for y in 0..<plain.h {
        for x in 0..<plain.w {
            let i = y * plain.w + x
            let d = Double(plain.px[i]) - Double(deco.px[i])
            if d > 2 { rowSum[y] += d / 255.0 }
        }
    }
    guard let peak = rowSum.max(), peak > 0.5 else { return nil }
    var first = -1, last = -1
    for y in 0..<plain.h where rowSum[y] > 0.5 * peak {
        if first < 0 { first = y }
        last = y
    }
    guard first >= 0 else { return nil }
    return (first, last - first + 1, rowSum.map { $0 / peak })
}

let weights: [(String, UIFont.Weight)] = [
    ("ultraLight", .ultraLight), ("thin", .thin), ("light", .light), ("regular", .regular),
    ("medium", .medium), ("semibold", .semibold), ("bold", .bold), ("heavy", .heavy),
    ("black", .black),
]

print("=== ctFont underline metrics (units/2048 per point) ===")
for (wn, w) in weights {
    let f = UIFont.systemFont(ofSize: 17, weight: w)
    let pos = -CTFontGetUnderlinePosition(f as CTFont) / 17 * 2048
    let th = CTFontGetUnderlineThickness(f as CTFont) / 17 * 2048
    print("\(wn)\tposUnits=\(String(format: "%.2f", pos))\tthickUnits=\(String(format: "%.2f", th))")
}
for (tag, f) in [("italic17", UIFont.italicSystemFont(ofSize: 17)),
                 ("mono17", UIFont.monospacedSystemFont(ofSize: 17, weight: .regular)),
                 ("monoBold17", UIFont.monospacedSystemFont(ofSize: 17, weight: .bold))] {
    let pos = -CTFontGetUnderlinePosition(f as CTFont) / 17 * 2048
    let th = CTFontGetUnderlineThickness(f as CTFont) / 17 * 2048
    print("\(tag)\tposUnits=\(String(format: "%.2f", pos))\tthickUnits=\(String(format: "%.2f", th))")
}

print("=== UNDERLINE sweep (regular) ===")
print("size\tlineH\tasc\tbaselinePx\ttopPx\tthickPx\ttopRelPt\tthickPt\tctPos\tctThick")
for s in 8...40 {
    let f = UIFont.systemFont(ofSize: CGFloat(s))
    guard let r = rule(f, key: .underlineStyle) else { print("\(s)\tnone"); continue }
    let bl = (f.ascender + 0.5).rounded(.down)
    let l0 = UILabel(); l0.font = f; l0.text = "nn"
    let lh = l0.sizeThatFits(CGSize(width: 1e4, height: 1e6)).height
    print("\(s)\t\(lh)\t\(String(format: "%.3f", f.ascender))\t\(bl * 2)\t\(r.top)\t\(r.thick)\t\(String(format: "%.1f", Double(r.top) / 2 - Double(bl)))\t\(Double(r.thick) / 2)\t\(String(format: "%.4f", -CTFontGetUnderlinePosition(f as CTFont)))\t\(String(format: "%.4f", CTFontGetUnderlineThickness(f as CTFont)))")
}

print("=== UNDERLINE by weight (17, 24, 34) ===")
for s in [17, 24, 34] {
    for (wn, w) in weights {
        let f = UIFont.systemFont(ofSize: CGFloat(s), weight: w)
        guard let r = rule(f, key: .underlineStyle) else { continue }
        let bl = (f.ascender + 0.5).rounded(.down)
        print("\(s)\t\(wn)\ttopRelPt=\(Double(r.top) / 2 - Double(bl))\tthickPt=\(Double(r.thick) / 2)\tctThick=\(String(format: "%.4f", CTFontGetUnderlineThickness(f as CTFont)))")
    }
}

print("=== STRIKETHROUGH sweep (regular) ===")
print("size\tbaselinePt\ttopRelPt\tthickPt\txHeight\tcapHeight")
for s in 8...40 {
    let f = UIFont.systemFont(ofSize: CGFloat(s))
    guard let r = rule(f, key: .strikethroughStyle) else { print("\(s)\tnone"); continue }
    let bl = (f.ascender + 0.5).rounded(.down)
    print("\(s)\t\(bl)\t\(Double(r.top) / 2 - Double(bl))\t\(Double(r.thick) / 2)\t\(String(format: "%.4f", f.xHeight))\t\(String(format: "%.4f", f.capHeight))")
}

print("=== STRIKETHROUGH by weight (17, 24) ===")
for s in [17, 24] {
    for (wn, w) in weights {
        let f = UIFont.systemFont(ofSize: CGFloat(s), weight: w)
        guard let r = rule(f, key: .strikethroughStyle) else { continue }
        let bl = (f.ascender + 0.5).rounded(.down)
        print("\(s)\t\(wn)\ttopRelPt=\(Double(r.top) / 2 - Double(bl))\tthickPt=\(Double(r.thick) / 2)\txH=\(String(format: "%.4f", f.xHeight))")
    }
}
