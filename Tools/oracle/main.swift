// Oracle: renders scene JSON files with REAL UIKit (Mac Catalyst, offscreen).
// Usage:
//   oracle render <outdir> <scene.json>...
//   oracle colors <outfile.json>
//   oracle fontmetrics <outfile.json>
import UIKit

// MARK: - JSON helpers

typealias JSON = [String: Any]

func num(_ v: Any?) -> CGFloat? {
    if let d = v as? Double { return CGFloat(d) }
    if let i = v as? Int { return CGFloat(i) }
    return nil
}
func numArray(_ v: Any?) -> [CGFloat]? {
    guard let a = v as? [Any] else { return nil }
    return a.compactMap { num($0) }
}

// MARK: - Colors

let systemColorNames: [(String, UIColor)] = [
    ("systemRed", .systemRed), ("systemOrange", .systemOrange), ("systemYellow", .systemYellow),
    ("systemGreen", .systemGreen), ("systemMint", .systemMint), ("systemTeal", .systemTeal),
    ("systemCyan", .systemCyan), ("systemBlue", .systemBlue), ("systemIndigo", .systemIndigo),
    ("systemPurple", .systemPurple), ("systemPink", .systemPink), ("systemBrown", .systemBrown),
    ("systemGray", .systemGray), ("systemGray2", .systemGray2), ("systemGray3", .systemGray3),
    ("systemGray4", .systemGray4), ("systemGray5", .systemGray5), ("systemGray6", .systemGray6),
    ("label", .label), ("secondaryLabel", .secondaryLabel), ("tertiaryLabel", .tertiaryLabel),
    ("quaternaryLabel", .quaternaryLabel),
    ("systemBackground", .systemBackground), ("secondarySystemBackground", .secondarySystemBackground),
    ("tertiarySystemBackground", .tertiarySystemBackground),
    ("systemGroupedBackground", .systemGroupedBackground),
    ("secondarySystemGroupedBackground", .secondarySystemGroupedBackground),
    ("tertiarySystemGroupedBackground", .tertiarySystemGroupedBackground),
    ("separator", .separator), ("opaqueSeparator", .opaqueSeparator),
    ("link", .link), ("placeholderText", .placeholderText),
    ("systemFill", .systemFill), ("secondarySystemFill", .secondarySystemFill),
    ("tertiarySystemFill", .tertiarySystemFill), ("quaternarySystemFill", .quaternarySystemFill),
    ("tintColor", UIColor.tintColor),
]
let systemColorMap: [String: UIColor] = Dictionary(uniqueKeysWithValues: systemColorNames)

func parseColor(_ s: String) -> UIColor? {
    if s == "clear" { return .clear }
    if s == "black" { return .black }
    if s == "white" { return .white }
    if let c = systemColorMap[s] { return c }
    if s.hasPrefix("#") {
        let hex = String(s.dropFirst())
        guard hex.count == 6 || hex.count == 8, let v = UInt64(hex, radix: 16) else { return nil }
        if hex.count == 6 {
            return UIColor(red: CGFloat((v >> 16) & 0xFF) / 255, green: CGFloat((v >> 8) & 0xFF) / 255,
                           blue: CGFloat(v & 0xFF) / 255, alpha: 1)
        } else {
            return UIColor(red: CGFloat((v >> 24) & 0xFF) / 255, green: CGFloat((v >> 16) & 0xFF) / 255,
                           blue: CGFloat((v >> 8) & 0xFF) / 255, alpha: CGFloat(v & 0xFF) / 255)
        }
    }
    if s.hasPrefix("rgba(") && s.hasSuffix(")") {
        let inner = s.dropFirst(5).dropLast()
        let parts = inner.split(separator: ",").compactMap { Double($0.trimmingCharacters(in: .whitespaces)) }
        guard parts.count == 4 else { return nil }
        return UIColor(red: parts[0], green: parts[1], blue: parts[2], alpha: parts[3])
    }
    return nil
}

func colorOrDie(_ v: Any?, _ context: String) -> UIColor? {
    guard let s = v as? String else { return nil }
    guard let c = parseColor(s) else { fatalError("bad color '\(s)' in \(context)") }
    return c
}

// MARK: - Fonts

func weight(_ s: String?) -> UIFont.Weight {
    switch s ?? "regular" {
    case "ultraLight": return .ultraLight
    case "thin": return .thin
    case "light": return .light
    case "regular": return .regular
    case "medium": return .medium
    case "semibold": return .semibold
    case "bold": return .bold
    case "heavy": return .heavy
    case "black": return .black
    default: fatalError("bad weight")
    }
}

func fontFrom(_ j: JSON) -> UIFont {
    let size = num(j["fontSize"]) ?? 17
    if j["italic"] as? Bool == true { return .italicSystemFont(ofSize: size) }
    if j["monospaced"] as? Bool == true {
        return .monospacedSystemFont(ofSize: size, weight: weight(j["fontWeight"] as? String))
    }
    return .systemFont(ofSize: size, weight: weight(j["fontWeight"] as? String))
}

// MARK: - Image synthesis

func makeImage(_ j: JSON, scale: CGFloat) -> UIImage {
    guard let sz = numArray(j["size"]), sz.count == 2 else { fatalError("image needs size") }
    let size = CGSize(width: sz[0], height: sz[1])
    let colors = (j["colors"] as? [String] ?? ["#FF00FF"]).map { parseColor($0)! }
    let kind = j["kind"] as? String ?? "solid"
    let fmt = UIGraphicsImageRendererFormat()
    fmt.scale = scale
    fmt.opaque = false
    return UIGraphicsImageRenderer(size: size, format: fmt).image { ctx in
        let cg = ctx.cgContext
        switch kind {
        case "solid":
            cg.setFillColor(colors[0].cgColor)
            cg.fill(CGRect(origin: .zero, size: size))
        case "checker":
            let tile = num(j["tile"]) ?? 8
            cg.setFillColor(colors[0].cgColor)
            cg.fill(CGRect(origin: .zero, size: size))
            cg.setFillColor((colors.count > 1 ? colors[1] : colors[0]).cgColor)
            var y: CGFloat = 0, row = 0
            while y < size.height {
                var x: CGFloat = 0, col = 0
                while x < size.width {
                    if (row + col) % 2 == 1 { cg.fill(CGRect(x: x, y: y, width: tile, height: tile)) }
                    x += tile; col += 1
                }
                y += tile; row += 1
            }
        case "gradient":
            let c0 = colors[0].cgColor, c1 = (colors.count > 1 ? colors[1] : colors[0]).cgColor
            let grad = CGGradient(colorsSpace: CGColorSpace(name: CGColorSpace.sRGB),
                                  colors: [c0, c1] as CFArray, locations: [0, 1])!
            let horizontal = (j["direction"] as? String) == "horizontal"
            cg.drawLinearGradient(grad, start: .zero,
                                  end: horizontal ? CGPoint(x: size.width, y: 0) : CGPoint(x: 0, y: size.height),
                                  options: [])
        default: fatalError("bad image kind \(kind)")
        }
    }
}

// MARK: - View building

func applyCommon(_ v: UIView, _ j: JSON, name: String) {
    if let f = numArray(j["frame"]), f.count == 4 {
        v.frame = CGRect(x: f[0], y: f[1], width: f[2], height: f[3])
    }
    if let c = colorOrDie(j["backgroundColor"], name) { v.backgroundColor = c }
    if let a = num(j["alpha"]) { v.alpha = a }
    if j["hidden"] as? Bool == true { v.isHidden = true }
    if j["clipsToBounds"] as? Bool == true { v.clipsToBounds = true }
    if let r = num(j["cornerRadius"]) { v.layer.cornerRadius = r }
    if let w = num(j["borderWidth"]) { v.layer.borderWidth = w }
    if let c = colorOrDie(j["borderColor"], name) { v.layer.borderColor = c.cgColor }
    if let m = j["autoresizingMask"] as? [String] {
        var mask: UIView.AutoresizingMask = []
        for item in m {
            switch item {
            case "flexibleWidth": mask.insert(.flexibleWidth)
            case "flexibleHeight": mask.insert(.flexibleHeight)
            case "flexibleLeftMargin": mask.insert(.flexibleLeftMargin)
            case "flexibleRightMargin": mask.insert(.flexibleRightMargin)
            case "flexibleTopMargin": mask.insert(.flexibleTopMargin)
            case "flexibleBottomMargin": mask.insert(.flexibleBottomMargin)
            default: fatalError("bad autoresizing \(item)")
            }
        }
        v.autoresizingMask = mask
    }
}

func textAlignment(_ s: String?) -> NSTextAlignment {
    switch s ?? "natural" {
    case "left": return .left
    case "center": return .center
    case "right": return .right
    case "justified": return .justified
    case "natural": return .natural
    default: fatalError("bad alignment")
    }
}

func lineBreakMode(_ s: String?) -> NSLineBreakMode {
    switch s ?? "truncateTail" {
    case "wordWrap": return .byWordWrapping
    case "charWrap": return .byCharWrapping
    case "clip": return .byClipping
    case "truncateHead": return .byTruncatingHead
    case "truncateTail": return .byTruncatingTail
    case "truncateMiddle": return .byTruncatingMiddle
    default: fatalError("bad lineBreakMode")
    }
}

func buildView(_ j: JSON, scale: CGFloat) -> UIView {
    let cls = j["class"] as? String ?? "UIView"
    let v: UIView
    switch cls {
    case "UIView":
        v = UIView()
    case "UILabel":
        let l = UILabel()
        l.text = j["text"] as? String
        l.font = fontFrom(j)
        if let c = colorOrDie(j["textColor"], cls) { l.textColor = c }
        l.textAlignment = textAlignment(j["textAlignment"] as? String)
        if let n = j["numberOfLines"] as? Int { l.numberOfLines = n }
        l.lineBreakMode = lineBreakMode(j["lineBreakMode"] as? String)
        v = l
    case "UIImageView":
        let iv = UIImageView()
        if let ij = j["image"] as? JSON { iv.image = makeImage(ij, scale: scale) }
        if let cm = j["contentMode"] as? String {
            let modes: [String: UIView.ContentMode] = [
                "scaleToFill": .scaleToFill, "scaleAspectFit": .scaleAspectFit,
                "scaleAspectFill": .scaleAspectFill, "center": .center, "top": .top,
                "bottom": .bottom, "left": .left, "right": .right, "topLeft": .topLeft,
                "topRight": .topRight, "bottomLeft": .bottomLeft, "bottomRight": .bottomRight,
                "redraw": .redraw,
            ]
            iv.contentMode = modes[cm]!
        }
        v = iv
    case "UIButton":
        let b = UIButton(type: .system)
        b.setTitle(j["title"] as? String, for: .normal)
        if j["fontSize"] != nil || j["fontWeight"] != nil { b.titleLabel!.font = fontFrom(j) }
        if let c = colorOrDie(j["titleColor"], cls) { b.setTitleColor(c, for: .normal) }
        if j["enabled"] as? Bool == false { b.isEnabled = false }
        v = b
    case "UISwitch":
        let s = UISwitch()
        s.isOn = j["on"] as? Bool ?? false
        if let c = colorOrDie(j["onTintColor"], cls) { s.onTintColor = c }
        v = s
    case "UIProgressView":
        let p = UIProgressView(progressViewStyle: .default)
        p.progress = Float(num(j["progress"]) ?? 0)
        if let c = colorOrDie(j["progressTintColor"], cls) { p.progressTintColor = c }
        if let c = colorOrDie(j["trackTintColor"], cls) { p.trackTintColor = c }
        v = p
    case "UIStackView":
        let s = UIStackView()
        s.axis = (j["axis"] as? String) == "vertical" ? .vertical : .horizontal
        if let sp = num(j["spacing"]) { s.spacing = sp }
        let dists: [String: UIStackView.Distribution] = [
            "fill": .fill, "fillEqually": .fillEqually, "fillProportionally": .fillProportionally,
            "equalSpacing": .equalSpacing, "equalCentering": .equalCentering,
        ]
        if let d = j["stackDistribution"] as? String { s.distribution = dists[d]! }
        let aligns: [String: UIStackView.Alignment] = [
            "fill": .fill, "leading": .leading, "trailing": .trailing, "center": .center,
            "top": .top, "bottom": .bottom, "firstBaseline": .firstBaseline, "lastBaseline": .lastBaseline,
        ]
        if let a = j["stackAlignment"] as? String { s.alignment = aligns[a]! }
        v = s
    default:
        fatalError("unsupported class \(cls)")
    }

    applyCommon(v, j, name: cls)

    if let subs = j["subviews"] as? [JSON] {
        for sub in subs {
            let child = buildView(sub, scale: scale)
            if let stack = v as? UIStackView { stack.addArrangedSubview(child) }
            else { v.addSubview(child) }
        }
    }

    if j["sizeToFit"] as? Bool == true {
        let origin = v.frame.origin
        v.sizeToFit()
        v.frame.origin = origin
    }
    if let t = numArray(j["transform"]), t.count == 6 {
        v.transform = CGAffineTransform(a: t[0], b: t[1], c: t[2], d: t[3], tx: t[4], ty: t[5])
    }
    return v
}

// MARK: - Layout dump

func round3(_ v: CGFloat) -> Double { (Double(v) * 1000).rounded() / 1000 }

func dumpLayout(_ v: UIView, path: String, into out: inout [JSON]) {
    var entry: JSON = [
        "path": path,
        "class": String(describing: type(of: v)),
        "frame": [round3(v.frame.origin.x), round3(v.frame.origin.y),
                  round3(v.frame.width), round3(v.frame.height)],
    ]
    if v is UILabel || v is UIButton || v is UISwitch || v is UIImageView || v is UIProgressView {
        let i = v.intrinsicContentSize
        entry["intrinsic"] = [i.width == UIView.noIntrinsicMetric ? -1 : round3(i.width),
                              i.height == UIView.noIntrinsicMetric ? -1 : round3(i.height)]
    }
    if v is UILabel || v is UIButton {
        let s = v.sizeThatFits(CGSize(width: 200, height: CGFloat.greatestFiniteMagnitude))
        entry["sizeThatFits200"] = [round3(s.width), round3(s.height)]
    }
    out.append(entry)
    for (i, sub) in v.subviews.enumerated() {
        dumpLayout(sub, path: path.isEmpty ? "\(i)" : "\(path).\(i)", into: &out)
    }
}

// MARK: - Render one scene

func renderScene(file: String, outdir: String) throws {
    let data = try Data(contentsOf: URL(fileURLWithPath: file))
    let scene = try JSONSerialization.jsonObject(with: data) as! JSON
    let name = scene["name"] as! String
    let sz = numArray(scene["size"])!
    let scale = num(scene["scale"]) ?? 2
    let style: UIUserInterfaceStyle = (scene["style"] as? String) == "dark" ? .dark : .light

    let traits = UITraitCollection(userInterfaceStyle: style)
    var container: UIView!
    traits.performAsCurrent {
        var rootJ = scene["root"] as! JSON
        rootJ["frame"] = [0, 0, sz[0], sz[1]]
        container = buildView(rootJ, scale: scale)
        container.overrideUserInterfaceStyle = style
        container.setNeedsLayout()
        container.layoutIfNeeded()
    }

    var views: [JSON] = []
    dumpLayout(container, path: "", into: &views)
    let layout: JSON = ["name": name, "views": views]
    let layoutData = try JSONSerialization.data(withJSONObject: layout, options: [.prettyPrinted, .sortedKeys])
    try layoutData.write(to: URL(fileURLWithPath: "\(outdir)/\(name).layout.json"))

    let fmt = UIGraphicsImageRendererFormat()
    fmt.scale = scale
    fmt.opaque = false
    let renderer = UIGraphicsImageRenderer(size: CGSize(width: sz[0], height: sz[1]), format: fmt)
    let img = renderer.image { ctx in
        traits.performAsCurrent {
            container.layer.render(in: ctx.cgContext)
        }
    }
    try img.pngData()!.write(to: URL(fileURLWithPath: "\(outdir)/\(name).png"))
    print("rendered \(name)")
}

// MARK: - Color dump

func dumpColors(outfile: String) throws {
    var result: JSON = [:]
    for styleName in ["light", "dark"] {
        let traits = UITraitCollection(userInterfaceStyle: styleName == "dark" ? .dark : .light)
        var table: JSON = [:]
        for (name, color) in systemColorNames {
            let resolved = color.resolvedColor(with: traits)
            var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
            // Convert to extended sRGB components
            let srgb = resolved.cgColor.converted(to: CGColorSpace(name: CGColorSpace.sRGB)!,
                                                  intent: .defaultIntent, options: nil) ?? resolved.cgColor
            let comps = srgb.components!
            if comps.count >= 4 { r = comps[0]; g = comps[1]; b = comps[2]; a = comps[3] }
            else { r = comps[0]; g = comps[0]; b = comps[0]; a = comps[1] }
            table[name] = [Double(r), Double(g), Double(b), Double(a)]
        }
        result[styleName] = table
    }
    let data = try JSONSerialization.data(withJSONObject: result, options: [.prettyPrinted, .sortedKeys])
    try data.write(to: URL(fileURLWithPath: outfile))
    print("wrote \(outfile)")
}

// MARK: - Font metrics dump

func dumpFontMetrics(outfile: String) throws {
    var fonts: [JSON] = []
    let weights: [(String, UIFont.Weight)] = [
        ("ultraLight", .ultraLight), ("thin", .thin), ("light", .light), ("regular", .regular),
        ("medium", .medium), ("semibold", .semibold), ("bold", .bold), ("heavy", .heavy), ("black", .black),
    ]
    let sizes: [CGFloat] = Array(stride(from: 8, through: 40, by: 1)).map { CGFloat($0) } + [11.5, 13.5, 17.5]
    let sampleStrings = [
        "Hello UIKit", "The quick brown fox jumps over the lazy dog", "0123456789",
        "AVAST Wavy To. LT", "iiiiillll", "WWWW MMMM",
    ]
    func entry(_ label: String, _ font: UIFont) -> JSON {
        var advances: [String: Double] = [:]
        for scalar in 32...126 {
            let ch = String(UnicodeScalar(scalar)!)
            let w = (ch as NSString).size(withAttributes: [.font: font]).width
            advances[ch] = Double(w)
        }
        var strings: [String: Double] = [:]
        for s in sampleStrings {
            strings[s] = Double((s as NSString).size(withAttributes: [.font: font]).width)
        }
        return [
            "id": label,
            "pointSize": Double(font.pointSize),
            "ascender": Double(font.ascender),
            "descender": Double(font.descender),
            "lineHeight": Double(font.lineHeight),
            "capHeight": Double(font.capHeight),
            "xHeight": Double(font.xHeight),
            "leading": Double(font.leading),
            "advances": advances,
            "stringWidths": strings,
            "postScriptName": font.fontName,
        ]
    }
    for size in sizes {
        for (wname, w) in weights {
            fonts.append(entry("system-\(wname)-\(size)", .systemFont(ofSize: size, weight: w)))
        }
        fonts.append(entry("italic-regular-\(size)", .italicSystemFont(ofSize: size)))
        fonts.append(entry("mono-regular-\(size)", .monospacedSystemFont(ofSize: size, weight: .regular)))
        fonts.append(entry("mono-bold-\(size)", .monospacedSystemFont(ofSize: size, weight: .bold)))
    }
    let data = try JSONSerialization.data(withJSONObject: ["fonts": fonts], options: [.sortedKeys])
    try data.write(to: URL(fileURLWithPath: outfile))
    print("wrote \(outfile) (\(fonts.count) font entries)")
}

// MARK: - Main

let args = CommandLine.arguments
guard args.count >= 3 else {
    print("usage: oracle render <outdir> <scene.json>... | oracle colors <out.json> | oracle fontmetrics <out.json>")
    exit(1)
}
switch args[1] {
case "render":
    let outdir = args[2]
    try FileManager.default.createDirectory(atPath: outdir, withIntermediateDirectories: true)
    var failures = 0
    for file in args.dropFirst(3) {
        do { try renderScene(file: file, outdir: outdir) }
        catch { print("FAIL \(file): \(error)"); failures += 1 }
    }
    exit(failures == 0 ? 0 : 1)
case "colors":
    try dumpColors(outfile: args[2])
case "fontmetrics":
    try dumpFontMetrics(outfile: args[2])
default:
    print("unknown command \(args[1])")
    exit(1)
}
