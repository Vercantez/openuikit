// SceneKit: scene-JSON -> real-UIKit view hierarchy, shared by BOTH oracles:
//   Tools/oracle  (v1): offscreen layer.render(in:)
//   Tools/oracle2 (v2): real-window drawHierarchy(afterScreenUpdates:) app
// Keep this file renderer-agnostic. Any behavior change here invalidates
// goldens produced by both tools — coordinate before touching.
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

// IMPORTANT: colors must be resolved eagerly against the scene's trait
// collection. The offscreen view hierarchy is never attached to a UIWindow,
// so neither `overrideUserInterfaceStyle` nor `UITraitCollection.performAsCurrent`
// affects the traitCollection views use when dynamic colors are pushed to
// their layers — without this, dark scenes render with LIGHT-mode colors.
// (oracle2 attaches views to a real window, but eager resolution yields the
// same values there, so both tools share this path.)
func colorOrDie(_ v: Any?, _ context: String, _ traits: UITraitCollection) -> UIColor? {
    guard let s = v as? String else { return nil }
    guard let c = parseColor(s) else { fatalError("bad color '\(s)' in \(context)") }
    return c.resolvedColor(with: traits)
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

func applyCommon(_ v: UIView, _ j: JSON, name: String, traits: UITraitCollection) {
    if let f = numArray(j["frame"]), f.count == 4 {
        v.frame = CGRect(x: f[0], y: f[1], width: f[2], height: f[3])
    }
    if let c = colorOrDie(j["backgroundColor"], name, traits) { v.backgroundColor = c }
    if let a = num(j["alpha"]) { v.alpha = a }
    if j["hidden"] as? Bool == true { v.isHidden = true }
    if j["clipsToBounds"] as? Bool == true { v.clipsToBounds = true }
    if let r = num(j["cornerRadius"]) { v.layer.cornerRadius = r }
    if let w = num(j["borderWidth"]) { v.layer.borderWidth = w }
    if let c = colorOrDie(j["borderColor"], name, traits) { v.layer.borderColor = c.cgColor }
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

func buildView(_ j: JSON, scale: CGFloat, traits: UITraitCollection) -> UIView {
    let cls = j["class"] as? String ?? "UIView"
    let v: UIView
    switch cls {
    case "UIView":
        v = UIView()
    case "UILabel":
        let l = UILabel()
        l.text = j["text"] as? String
        l.font = fontFrom(j)
        if let c = colorOrDie(j["textColor"], cls, traits) { l.textColor = c }
        // Default .label is dynamic and would resolve light offscreen (no window).
        else { l.textColor = UIColor.label.resolvedColor(with: traits) }
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
        // Default title color comes from the dynamic tint; pin it to the
        // scene style (offscreen views never see trait changes).
        b.tintColor = b.tintColor.resolvedColor(with: traits)
        if let c = colorOrDie(j["titleColor"], cls, traits) { b.setTitleColor(c, for: .normal) }
        if j["enabled"] as? Bool == false { b.isEnabled = false }
        v = b
    case "UISwitch":
        let s = UISwitch()
        s.isOn = j["on"] as? Bool ?? false
        if let c = colorOrDie(j["onTintColor"], cls, traits) { s.onTintColor = c }
        v = s
    case "UIProgressView":
        let p = UIProgressView(progressViewStyle: .default)
        p.progress = Float(num(j["progress"]) ?? 0)
        if let c = colorOrDie(j["progressTintColor"], cls, traits) { p.progressTintColor = c }
        if let c = colorOrDie(j["trackTintColor"], cls, traits) { p.trackTintColor = c }
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

    applyCommon(v, j, name: cls, traits: traits)

    if let subs = j["subviews"] as? [JSON] {
        for sub in subs {
            let child = buildView(sub, scale: scale, traits: traits)
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

// MARK: - Scene loading / building (shared driver pieces)

struct SceneSpec {
    let name: String
    let width: CGFloat
    let height: CGFloat
    let scale: CGFloat
    let style: UIUserInterfaceStyle
    let traits: UITraitCollection
    /// Top-level `"window": true` — scene must be rendered by oracle2
    /// (real window + drawHierarchy); its controls do not draw offscreen.
    let windowRequired: Bool
    let rootJSON: JSON
}

func loadScene(file: String) throws -> SceneSpec {
    let data = try Data(contentsOf: URL(fileURLWithPath: file))
    let scene = try JSONSerialization.jsonObject(with: data) as! JSON
    let name = scene["name"] as! String
    let sz = numArray(scene["size"])!
    let scale = num(scene["scale"]) ?? 2
    let style: UIUserInterfaceStyle = (scene["style"] as? String) == "dark" ? .dark : .light
    return SceneSpec(name: name, width: sz[0], height: sz[1], scale: scale, style: style,
                     traits: UITraitCollection(userInterfaceStyle: style),
                     windowRequired: scene["window"] as? Bool == true,
                     rootJSON: scene["root"] as! JSON)
}

func buildContainer(_ spec: SceneSpec) -> UIView {
    var container: UIView!
    spec.traits.performAsCurrent {
        var rootJ = spec.rootJSON
        // NOTE (long-standing quirk, kept intentionally): this frame array mixes
        // Int and CGFloat elements, and numArray() fails to cast the CGFloats,
        // so the root view actually KEEPS frame (0,0,0,0) — its background is
        // never drawn and every golden layout dump has root frame [0,0,0,0].
        // openrender replicates this on purpose (see SceneBuilder.swift).
        // Changing it would invalidate every golden; coordinate across modules
        // before "fixing" it.
        rootJ["frame"] = [0, 0, spec.width, spec.height]
        container = buildView(rootJ, scale: spec.scale, traits: spec.traits)
        container.overrideUserInterfaceStyle = spec.style
        container.setNeedsLayout()
        container.layoutIfNeeded()
    }
    return container
}

func writeLayoutDump(_ container: UIView, name: String, outdir: String) throws {
    var views: [JSON] = []
    dumpLayout(container, path: "", into: &views)
    let layout: JSON = ["name": name, "views": views]
    let layoutData = try JSONSerialization.data(withJSONObject: layout, options: [.prettyPrinted, .sortedKeys])
    try layoutData.write(to: URL(fileURLWithPath: "\(outdir)/\(name).layout.json"))
}
