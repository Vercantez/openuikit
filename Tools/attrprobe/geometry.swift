// Probe 4: difference-image extraction of underline / strikethrough rules,
// and pixel verification of the baselineOffset ascent/descent model.
import UIKit

let traits = UITraitCollection(userInterfaceStyle: .light)

func mk(_ runs: [(String, UIFont, [NSAttributedString.Key: Any])]) -> NSAttributedString {
    let ms = NSMutableAttributedString()
    for (t, f, extra) in runs {
        var a: [NSAttributedString.Key: Any] = [.font: f, .foregroundColor: UIColor.black]
        for (k, v) in extra { a[k] = v }
        ms.append(NSAttributedString(string: t, attributes: a))
    }
    return ms
}

func render(_ s: NSAttributedString, size: CGSize, lines: Int = 1) -> (px: [UInt8], w: Int, h: Int) {
    let l = UILabel(frame: CGRect(origin: .zero, size: size))
    l.numberOfLines = lines
    l.attributedText = s
    let scale: CGFloat = 2
    let w = Int(size.width * scale), h = Int(size.height * scale)
    let cs = CGColorSpace(name: CGColorSpace.sRGB)!
    let ctx = CGContext(data: nil, width: w, height: h, bitsPerComponent: 8,
                        bytesPerRow: w * 4, space: cs,
                        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    ctx.setFillColor(UIColor.white.cgColor)
    ctx.fill(CGRect(x: 0, y: 0, width: CGFloat(w), height: CGFloat(h)))
    ctx.translateBy(x: 0, y: CGFloat(h))
    ctx.scaleBy(x: scale, y: -scale)
    traits.performAsCurrent { l.layer.render(in: ctx) }
    let d = ctx.data!.bindMemory(to: UInt8.self, capacity: w * h * 4)
    var out = [UInt8](repeating: 0, count: w * h)
    for i in 0..<(w * h) { out[i] = d[i * 4] }
    return (out, w, h)
}

let size = CGSize(width: 240, height: 60)

/// Rule geometry from the difference of decorated and plain renders.
func ruleGeometry(_ tag: String, font: UIFont, key: NSAttributedString.Key, text: String = "nn") {
    let plain = render(mk([(text, font, [:])]), size: size)
    let deco = render(mk([(text, font, [key: NSUnderlineStyle.single.rawValue])]), size: size)
    // Coverage added by the rule, per row, summed over columns.
    var rowSum = [Double](repeating: 0, count: plain.h)
    var colMin = plain.w, colMax = -1
    for y in 0..<plain.h {
        for x in 0..<plain.w {
            let i = y * plain.w + x
            let d = Double(plain.px[i]) - Double(deco.px[i])
            if d > 2 {
                rowSum[y] += d / 255.0
                if x < colMin { colMin = x }
                if x > colMax { colMax = x }
            }
        }
    }
    var rows: [(Int, Double)] = []
    for y in 0..<plain.h where rowSum[y] > 0.05 { rows.append((y, rowSum[y])) }
    guard !rows.isEmpty else { print("\(tag): no rule found"); return }
    // Interior columns only (avoid the AA at the rule's horizontal ends).
    let w = Double(colMax - colMin + 1 - 4)
    let prof = rows.map { "\($0.0):\(String(format: "%.3f", $0.1 / w))" }.joined(separator: " ")
    let total = rows.reduce(0.0) { $0 + $1.1 } / w
    let l = UILabel(); l.font = font; l.text = text
    let lh = l.sizeThatFits(CGSize(width: 1e4, height: 1e6)).height
    let y0 = ((size.height - lh) / 2 + 0.5).rounded(.down)
    let baseline = y0 + (font.ascender + 0.5).rounded(.down)
    print("\(tag) baselinePx=\(baseline * 2) totalPx=\(String(format: "%.3f", total)) cols=\(colMin)...\(colMax) ctThick=\(CTFontGetUnderlineThickness(font as CTFont)) ctPos=\(CTFontGetUnderlinePosition(font as CTFont)) xH=\(font.xHeight)\n    \(prof)")
}

print("=== UNDERLINE ===")
for (t, f) in [("reg10", UIFont.systemFont(ofSize: 10)), ("reg13", UIFont.systemFont(ofSize: 13)),
               ("reg15", UIFont.systemFont(ofSize: 15)), ("reg17", UIFont.systemFont(ofSize: 17)),
               ("reg20", UIFont.systemFont(ofSize: 20)), ("reg24", UIFont.systemFont(ofSize: 24)),
               ("reg28", UIFont.systemFont(ofSize: 28)), ("reg34", UIFont.systemFont(ofSize: 34)),
               ("med17", UIFont.systemFont(ofSize: 17, weight: .medium)),
               ("semi17", UIFont.systemFont(ofSize: 17, weight: .semibold)),
               ("bold17", UIFont.systemFont(ofSize: 17, weight: .bold)),
               ("bold24", UIFont.systemFont(ofSize: 24, weight: .bold))] {
    ruleGeometry(t, font: f, key: .underlineStyle)
}

print("=== STRIKETHROUGH ===")
for (t, f) in [("reg13", UIFont.systemFont(ofSize: 13)), ("reg17", UIFont.systemFont(ofSize: 17)),
               ("reg20", UIFont.systemFont(ofSize: 20)), ("reg24", UIFont.systemFont(ofSize: 24)),
               ("bold17", UIFont.systemFont(ofSize: 17, weight: .bold)),
               ("reg34", UIFont.systemFont(ofSize: 34))] {
    ruleGeometry(t, font: f, key: .strikethroughStyle)
}

print("=== UNDERLINE STYLES (17pt) ===")
do {
    let f = UIFont.systemFont(ofSize: 17)
    for (name, style) in [("single", NSUnderlineStyle.single), ("thick", .thick), ("double", .double)] {
        let plain = render(mk([("nn", f, [:])]), size: size)
        let deco = render(mk([("nn", f, [.underlineStyle: style.rawValue])]), size: size)
        var rows: [Int] = []
        for y in 0..<plain.h {
            var s = 0.0
            for x in 0..<plain.w {
                let i = y * plain.w + x
                let d = Double(plain.px[i]) - Double(deco.px[i])
                if d > 2 { s += d / 255 }
            }
            if s > 0.05 { rows.append(y) }
        }
        print("\(name): rows \(rows)")
    }
}

print("=== baselineOffset ascent model (label 240x60, 'T' runs) ===")
let f17 = UIFont.systemFont(ofSize: 17)
func baselineRows(_ runs: [(String, UIFont, [NSAttributedString.Key: Any])], cols: [Int]) {
    let img = render(mk(runs), size: size)
    var out: [String] = []
    for c in cols {
        var rows: [Int] = []
        for y in 0..<img.h where img.px[y * img.w + c] < 128 { rows.append(y) }
        out.append("col\(c)=\(rows.first ?? -1)...\(rows.last ?? -1)")
    }
    let l = UILabel(); l.numberOfLines = 1; l.attributedText = mk(runs)
    print("H=\(l.sizeThatFits(CGSize(width: 1e4, height: CGFloat(1e6))).height)\t\(out.joined(separator: " "))")
}
print("bo {0}:"); baselineRows([("T", f17, [:])], cols: [10])
print("bo {+3}:"); baselineRows([("T", f17, [.baselineOffset: 3.0])], cols: [10])
print("bo {-3}:"); baselineRows([("T", f17, [.baselineOffset: -3.0])], cols: [10])
print("bo {-5}:"); baselineRows([("T", f17, [.baselineOffset: -5.0])], cols: [10])
print("bo {+3,-3}:"); baselineRows([("T", f17, [.baselineOffset: 3.0]), ("T", f17, [.baselineOffset: -3.0])], cols: [10, 30])
print("bo {+2,-5}:"); baselineRows([("T", f17, [.baselineOffset: 2.0]), ("T", f17, [.baselineOffset: -5.0])], cols: [10, 30])
print("bo {0,+6}:"); baselineRows([("T", f17, [:]), ("T", f17, [.baselineOffset: 6.0])], cols: [10, 30])
print("mixed font 24/17:"); baselineRows([("T", UIFont.systemFont(ofSize: 24), [:]), ("T", f17, [:])], cols: [10, 40])
print("mixed font 13/24:"); baselineRows([("T", UIFont.systemFont(ofSize: 13), [:]), ("T", UIFont.systemFont(ofSize: 24), [:])], cols: [6, 30])
