// Probes real UIKit attributed-string measurement semantics (Mac Catalyst).
import UIKit

let traits = UITraitCollection(userInterfaceStyle: .light)

func mk(_ runs: [(String, UIFont, [NSAttributedString.Key: Any])],
        paragraph: NSParagraphStyle? = nil) -> NSAttributedString {
    let ms = NSMutableAttributedString()
    for (t, f, extra) in runs {
        var a: [NSAttributedString.Key: Any] = [.font: f,
            .foregroundColor: UIColor.label.resolvedColor(with: traits)]
        for (k, v) in extra { a[k] = v }
        ms.append(NSAttributedString(string: t, attributes: a))
    }
    if let p = paragraph {
        ms.addAttribute(.paragraphStyle, value: p, range: NSRange(location: 0, length: ms.length))
    }
    return ms
}

func label(_ s: NSAttributedString, lines: Int = 1, width: CGFloat = 200) -> UILabel {
    let l = UILabel()
    l.numberOfLines = lines
    l.attributedText = s
    return l
}

func p(_ name: String, _ v: Any) { print("\(name)\t\(v)") }

func meas(_ tag: String, _ s: NSAttributedString, lines: Int = 1, width: CGFloat = 200) {
    let l = label(s, lines: lines, width: width)
    let stf = l.sizeThatFits(CGSize(width: width, height: .greatestFiniteMagnitude))
    let ics = l.intrinsicContentSize
    let bnd = s.boundingRect(with: CGSize(width: width, height: .greatestFiniteMagnitude),
                             options: [.usesLineFragmentOrigin], context: nil)
    print("\(tag)\tstf=(\(stf.width),\(stf.height))\tics=(\(ics.width),\(ics.height))\tbound=(\(bnd.origin.x),\(bnd.origin.y),\(bnd.width),\(bnd.height))")
}

let f17 = UIFont.systemFont(ofSize: 17)
let f24 = UIFont.systemFont(ofSize: 24)
let f13 = UIFont.systemFont(ofSize: 13)
let b17 = UIFont.systemFont(ofSize: 17, weight: .bold)

print("=== 1. plain baseline (no attributes beyond font) ===")
meas("AVATAR/17", mk([("AVATAR", f17, [:])]))
p("NSString AVATAR 17", ("AVATAR" as NSString).size(withAttributes: [.font: f17]).width)
let plainLabel = UILabel(); plainLabel.font = f17; plainLabel.text = "AVATAR"
p("plain UILabel AVATAR 17 stf", plainLabel.sizeThatFits(CGSize(width: 200, height: 1e6)))

print("=== 2. kern ===")
for k in [0.0, 1.0, 2.0, -0.5, 5.0] {
    meas("AVATAR kern=\(k)", mk([("AVATAR", f17, [.kern: k])]))
}
for k in [0.0, 2.0] {
    meas("iiii kern=\(k)", mk([("iiii", f17, [.kern: k])]))
    meas("A kern=\(k)", mk([("A", f17, [.kern: k])]))
    meas("AA kern=\(k)", mk([("AA", f17, [.kern: k])]))
}
// two runs, kern only on the first: is the boundary pair kerned?
meas("AV|AT kern2|none", mk([("AV", f17, [.kern: 2.0]), ("AT", f17, [:])]))
meas("AVAT none", mk([("AVAT", f17, [:])]))

print("=== 3. mixed fonts, one line ===")
meas("17+24", mk([("Big ", f24, [:]), ("small", f17, [:])]))
meas("24 only", mk([("Big ", f24, [:])]))
meas("17 only", mk([("small", f17, [:])]))
meas("13+17+24", mk([("aa", f13, [:]), ("bb", f17, [:]), ("cc", f24, [:])]))
p("labelLineHeight 13", { let l = UILabel(); l.font = f13; l.text = "x"; return l.sizeThatFits(CGSize(width: 999, height: 1e6)).height }())
p("labelLineHeight 17", { let l = UILabel(); l.font = f17; l.text = "x"; return l.sizeThatFits(CGSize(width: 999, height: 1e6)).height }())
p("labelLineHeight 24", { let l = UILabel(); l.font = f24; l.text = "x"; return l.sizeThatFits(CGSize(width: 999, height: 1e6)).height }())
p("font 24 asc/desc/lh/leading", [f24.ascender, f24.descender, f24.lineHeight, f24.leading])
p("font 17 asc/desc/lh/leading", [f17.ascender, f17.descender, f17.lineHeight, f17.leading])
p("font 13 asc/desc/lh/leading", [f13.ascender, f13.descender, f13.lineHeight, f13.leading])

print("=== 4. baselineOffset ===")
for b in [0.0, 3.0, -3.0, 8.0] {
    meas("bo=\(b) single-run", mk([("Offset", f17, [.baselineOffset: b])]))
    meas("bo=\(b) mixed", mk([("aa", f17, [:]), ("bb", f17, [.baselineOffset: b])]))
}

print("=== 5. paragraph style: line spacing etc (multi-line) ===")
let long = "The quick brown fox jumps over the lazy dog near the river bank"
func para(_ cfg: (NSMutableParagraphStyle) -> Void) -> NSParagraphStyle {
    let ps = NSMutableParagraphStyle(); ps.lineBreakMode = .byWordWrapping; cfg(ps); return ps
}
meas("wrap default", mk([(long, f17, [:])], paragraph: para { _ in }), lines: 0, width: 200)
for ls in [2.0, 6.0, 10.0] {
    meas("lineSpacing=\(ls)", mk([(long, f17, [:])], paragraph: para { $0.lineSpacing = ls }), lines: 0, width: 200)
}
for m in [1.2, 1.5, 0.8] {
    meas("lineHeightMultiple=\(m)", mk([(long, f17, [:])], paragraph: para { $0.lineHeightMultiple = m }), lines: 0, width: 200)
}
for mn in [30.0, 10.0] {
    meas("minLineHeight=\(mn)", mk([(long, f17, [:])], paragraph: para { $0.minimumLineHeight = mn }), lines: 0, width: 200)
}
for mx in [30.0, 12.0] {
    meas("maxLineHeight=\(mx)", mk([(long, f17, [:])], paragraph: para { $0.maximumLineHeight = mx }), lines: 0, width: 200)
}
meas("paragraphSpacing=10", mk([("first para\nsecond para", f17, [:])], paragraph: para { $0.paragraphSpacing = 10 }), lines: 0, width: 200)
meas("paraSpacingNone", mk([("first para\nsecond para", f17, [:])], paragraph: para { _ in }), lines: 0, width: 200)
meas("paragraphSpacingBefore=10", mk([("first para\nsecond para", f17, [:])], paragraph: para { $0.paragraphSpacingBefore = 10 }), lines: 0, width: 200)

print("=== 6. indents ===")
for fi in [0.0, 20.0] {
    for hi in [0.0, 10.0] {
        for ti in [0.0, -20.0] {
            meas("first=\(fi) head=\(hi) tail=\(ti)",
                 mk([(long, f17, [:])], paragraph: para {
                    $0.firstLineHeadIndent = fi; $0.headIndent = hi; $0.tailIndent = ti }),
                 lines: 0, width: 200)
        }
    }
}

print("=== 7. underline / strikethrough measurement impact ===")
meas("underline single", mk([("Under", f17, [.underlineStyle: NSUnderlineStyle.single.rawValue])]))
meas("no underline", mk([("Under", f17, [:])]))
meas("strike", mk([("Under", f17, [.strikethroughStyle: NSUnderlineStyle.single.rawValue])]))

print("=== 8. font underline metrics ===")
for f in [f13, f17, f24, b17] {
    let ct = f as CTFont
    p("underline pos/thick \(f.pointSize) \(f.fontName)",
      [CTFontGetUnderlinePosition(ct), CTFontGetUnderlineThickness(ct)])
}

print("=== 9. label alignment from paragraph style ===")
let alignLabel = UILabel()
alignLabel.attributedText = mk([("hi", f17, [:])], paragraph: para { $0.alignment = .center })
p("label.textAlignment after attributed center", alignLabel.textAlignment.rawValue)
let alignLabel2 = UILabel()
alignLabel2.textAlignment = .right
alignLabel2.attributedText = mk([("hi", f17, [:])])
p("label.textAlignment plain attributed after setting right", alignLabel2.textAlignment.rawValue)

print("=== 10. lineBreakMode from paragraph vs label ===")
let lb = UILabel(); lb.numberOfLines = 0
lb.attributedText = mk([(long, f17, [:])], paragraph: para { $0.lineBreakMode = .byWordWrapping })
p("lb.lineBreakMode", lb.lineBreakMode.rawValue)
p("lb numberOfLines0 stf", lb.sizeThatFits(CGSize(width: 200, height: 1e6)))

print("=== 11. no paragraph style at all, multiline ===")
meas("no-para multiline", mk([(long, f17, [:])]), lines: 0, width: 200)
meas("no-para 2 lines", mk([(long, f17, [:])]), lines: 2, width: 200)

print("=== 12. mixed-font wrap ===")
meas("mixed wrap", mk([("The quick brown ", f24, [:]), ("fox jumps over the lazy dog", f13, [:])]), lines: 0, width: 200)
