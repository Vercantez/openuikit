// Scene -> OpenUIKit view building + layout dump + render.
// Owner: rendercli module.
//
// This file must NOT import Foundation: it works with OpenUIKit's CG types
// (which would clash with Apple's CoreGraphics types that Foundation drags
// in on Darwin). JSON comes in as OpenUIKit.JSONValue (converted from
// JSONSerialization output in SceneIO.swift).
//
// The logic mirrors Tools/oracle/main.swift exactly: same property
// application order (frame/common props, then subviews, then sizeToFit,
// transform LAST), same color parsing, same layout dump keys and rounding.

import OpenUIKit

typealias SceneJSON = [String: JSONValue]

// MARK: - JSON helpers (mirror oracle's num/numArray)

func num(_ v: JSONValue?) -> CGFloat? {
    v?.doubleValue.map { CGFloat($0) }
}

func numArray(_ v: JSONValue?) -> [CGFloat]? {
    guard let a = v?.arrayValue else { return nil }
    return a.compactMap { $0.doubleValue.map { CGFloat($0) } }
}

func intValue(_ v: JSONValue?) -> Int? {
    v?.doubleValue.map { Int($0) }
}

// MARK: - Colors (mirror oracle)

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

private func trimmedWS(_ s: Substring) -> Substring {
    var t = s
    while let f = t.first, f == " " || f == "\t" { t = t.dropFirst() }
    while let l = t.last, l == " " || l == "\t" { t = t.dropLast() }
    return t
}

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
        let parts = inner.split(separator: ",").compactMap { Double(trimmedWS($0)) }
        guard parts.count == 4 else { return nil }
        return UIColor(red: parts[0], green: parts[1], blue: parts[2], alpha: parts[3])
    }
    return nil
}

func colorOrDie(_ v: JSONValue?, _ context: String) -> UIColor? {
    guard let s = v?.stringValue else { return nil }
    guard let c = parseColor(s) else { fatalError("bad color '\(s)' in \(context)") }
    return c
}

// MARK: - Fonts (mirror oracle)

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

func fontFrom(_ j: SceneJSON) -> UIFont {
    let size = num(j["fontSize"]) ?? 17
    if j["italic"]?.boolValue == true { return .italicSystemFont(ofSize: size) }
    if j["monospaced"]?.boolValue == true {
        return .monospacedSystemFont(ofSize: size, weight: weight(j["fontWeight"]?.stringValue))
    }
    return .systemFont(ofSize: size, weight: weight(j["fontWeight"]?.stringValue))
}

// MARK: - View building (mirror oracle order exactly)

func applyCommon(_ v: UIView, _ j: SceneJSON, name: String) {
    if let f = numArray(j["frame"]), f.count == 4 {
        v.frame = CGRect(x: f[0], y: f[1], width: f[2], height: f[3])
    }
    if let c = colorOrDie(j["backgroundColor"], name) { v.backgroundColor = c }
    if let a = num(j["alpha"]) { v.alpha = a }
    if j["hidden"]?.boolValue == true { v.isHidden = true }
    if j["clipsToBounds"]?.boolValue == true { v.clipsToBounds = true }
    if let r = num(j["cornerRadius"]) { v.layer.cornerRadius = r }
    if let w = num(j["borderWidth"]) { v.layer.borderWidth = w }
    if let c = colorOrDie(j["borderColor"], name) { v.layer.borderColor = c.cgColor }
    // Shadows (spec v2), mirroring the oracle's applyCommon order. Colors
    // resolve against the scene style via UITraitCollection.current, exactly
    // like the oracle's colorOrDie(_:_:traits).cgColor.
    if let c = colorOrDie(j["shadowColor"], name) { v.layer.shadowColor = c.cgColor }
    if let o = num(j["shadowOpacity"]) { v.layer.shadowOpacity = Float(o) }
    if let off = numArray(j["shadowOffset"]), off.count == 2 {
        v.layer.shadowOffset = CGSize(width: off[0], height: off[1])
    }
    if let r = num(j["shadowRadius"]) { v.layer.shadowRadius = r }
    if let m = j["autoresizingMask"]?.arrayValue {
        var mask: UIView.AutoresizingMask = []
        for item in m {
            switch item.stringValue {
            case "flexibleWidth": mask.insert(.flexibleWidth)
            case "flexibleHeight": mask.insert(.flexibleHeight)
            case "flexibleLeftMargin": mask.insert(.flexibleLeftMargin)
            case "flexibleRightMargin": mask.insert(.flexibleRightMargin)
            case "flexibleTopMargin": mask.insert(.flexibleTopMargin)
            case "flexibleBottomMargin": mask.insert(.flexibleBottomMargin)
            default: fatalError("bad autoresizing \(String(describing: item.stringValue))")
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

func makeLabel(_ j: SceneJSON) -> UILabel {
    let l = UILabel()
    l.text = j["text"]?.stringValue
    l.font = fontFrom(j)
    if let c = colorOrDie(j["textColor"], "UILabel") { l.textColor = c }
    l.textAlignment = textAlignment(j["textAlignment"]?.stringValue)
    if let n = intValue(j["numberOfLines"]) { l.numberOfLines = n }
    l.lineBreakMode = lineBreakMode(j["lineBreakMode"]?.stringValue)
    return l
}

// MARK: - Image synthesis (mirror oracle's makeImage)

/// Synthesize a UIImage per docs/SCENE_SPEC.md by filling Bitmap pixels
/// procedurally at the scene scale (the oracle does the equivalent through
/// UIGraphicsImageRenderer with format.scale = scene scale).
func makeImage(_ j: SceneJSON, scale: CGFloat) -> UIImage {
    guard let sz = numArray(j["size"]), sz.count == 2 else { fatalError("image needs size") }
    let pw = Int((sz[0] * scale).rounded())
    let ph = Int((sz[1] * scale).rounded())
    let colorStrings = j["colors"]?.arrayValue?.compactMap { $0.stringValue } ?? ["#FF00FF"]
    let colors: [CGColor] = colorStrings.map {
        guard let c = parseColor($0) else { fatalError("bad color '\($0)' in image") }
        return c.cgColor
    }
    let kind = j["kind"]?.stringValue ?? "solid"
    let bmp = Bitmap(width: pw, height: ph)

    func bytes(_ c: CGColor) -> (UInt8, UInt8, UInt8, UInt8) {
        func b(_ v: CGFloat) -> UInt8 { UInt8(max(0, min(255, (v * 255).rounded()))) }
        return (b(c.red), b(c.green), b(c.blue), b(c.alpha))
    }

    switch kind {
    case "solid":
        let (r, g, b, a) = bytes(colors[0])
        for i in stride(from: 0, to: bmp.pixels.count, by: 4) {
            bmp.pixels[i] = r; bmp.pixels[i + 1] = g
            bmp.pixels[i + 2] = b; bmp.pixels[i + 3] = a
        }
    case "checker":
        // Oracle fills tile rects on a point grid; tile*scale is the pixel
        // pitch (integral for all fixture scenes, so fills are pixel-exact).
        let tile = (num(j["tile"]) ?? 8) * scale
        let c0 = bytes(colors[0])
        let c1 = bytes(colors.count > 1 ? colors[1] : colors[0])
        for y in 0..<ph {
            let row = Int(CGFloat(y) / tile)
            for x in 0..<pw {
                let col = Int(CGFloat(x) / tile)
                let (r, g, b, a) = (row + col) % 2 == 1 ? c1 : c0
                let o = (y * pw + x) * 4
                bmp.pixels[o] = r; bmp.pixels[o + 1] = g
                bmp.pixels[o + 2] = b; bmp.pixels[o + 3] = a
            }
        }
    case "gradient":
        // CG linear gradient over an sRGB stop space: per-pixel lerp of the
        // gamma-encoded components, sampled at pixel centers.
        let c0 = colors[0]
        let c1 = colors.count > 1 ? colors[1] : colors[0]
        let horizontal = j["direction"]?.stringValue == "horizontal"
        let n = horizontal ? pw : ph
        var stops: [(UInt8, UInt8, UInt8, UInt8)] = []
        stops.reserveCapacity(n)
        for i in 0..<n {
            let t = (CGFloat(i) + 0.5) / CGFloat(n)
            stops.append(bytes(CGColor(red: c0.red + (c1.red - c0.red) * t,
                                       green: c0.green + (c1.green - c0.green) * t,
                                       blue: c0.blue + (c1.blue - c0.blue) * t,
                                       alpha: c0.alpha + (c1.alpha - c0.alpha) * t)))
        }
        for y in 0..<ph {
            for x in 0..<pw {
                let (r, g, b, a) = stops[horizontal ? x : y]
                let o = (y * pw + x) * 4
                bmp.pixels[o] = r; bmp.pixels[o + 1] = g
                bmp.pixels[o + 2] = b; bmp.pixels[o + 3] = a
            }
        }
    default:
        fatalError("bad image kind \(kind)")
    }
    return UIImage(bitmap: bmp, scale: scale)
}

func makeImageView(_ j: SceneJSON, scale: CGFloat) -> UIImageView {
    let iv = UIImageView()
    if let ij = j["image"]?.objectValue { iv.image = makeImage(ij, scale: scale) }
    if let cm = j["contentMode"]?.stringValue {
        let modes: [String: UIViewContentMode] = [
            "scaleToFill": .scaleToFill, "scaleAspectFit": .scaleAspectFit,
            "scaleAspectFill": .scaleAspectFill, "center": .center, "top": .top,
            "bottom": .bottom, "left": .left, "right": .right, "topLeft": .topLeft,
            "topRight": .topRight, "bottomLeft": .bottomLeft, "bottomRight": .bottomRight,
            "redraw": .redraw,
        ]
        guard let mode = modes[cm] else { fatalError("bad contentMode \(cm)") }
        iv.contentMode = mode
    }
    return iv
}

func makeProgressView(_ j: SceneJSON) -> UIProgressView {
    let p = UIProgressView()
    if let v = num(j["progress"]) { p.progress = Float(v) }
    if let c = colorOrDie(j["progressTintColor"], "UIProgressView") { p.progressTintColor = c }
    if let c = colorOrDie(j["trackTintColor"], "UIProgressView") { p.trackTintColor = c }
    return p
}

func stackAxis(_ s: String?) -> NSLayoutConstraint.Axis {
    switch s ?? "horizontal" {
    case "horizontal": return .horizontal
    case "vertical": return .vertical
    default: fatalError("bad axis")
    }
}

func stackDistribution(_ s: String?) -> UIStackView.Distribution {
    switch s ?? "fill" {
    case "fill": return .fill
    case "fillEqually": return .fillEqually
    case "fillProportionally": return .fillProportionally
    case "equalSpacing": return .equalSpacing
    case "equalCentering": return .equalCentering
    default: fatalError("bad stackDistribution")
    }
}

func stackAlignment(_ s: String?) -> UIStackView.Alignment {
    switch s ?? "fill" {
    case "fill": return .fill
    case "leading": return .leading
    case "trailing": return .trailing
    case "center": return .center
    case "top": return .top
    case "bottom": return .bottom
    case "firstBaseline": return .firstBaseline
    case "lastBaseline": return .lastBaseline
    default: fatalError("bad stackAlignment")
    }
}

func makeStackView(_ j: SceneJSON) -> UIStackView {
    let s = UIStackView()
    s.axis = stackAxis(j["axis"]?.stringValue)
    if let sp = num(j["spacing"]) { s.spacing = sp }
    s.distribution = stackDistribution(j["stackDistribution"]?.stringValue)
    s.alignment = stackAlignment(j["stackAlignment"]?.stringValue)
    return s
}

func makeGradientView(_ j: SceneJSON) -> UIGradientView {
    let g = UIGradientView()
    guard let colorStrings = j["colors"]?.arrayValue?.compactMap({ $0.stringValue }),
          colorStrings.count >= 2 else {
        fatalError("UIGradientView needs \"colors\" with >= 2 entries")
    }
    // Mirror the oracle: colors resolved against the scene traits at build
    // time (UITraitCollection.current carries the scene style here).
    g.colors = colorStrings.map { s -> UIColor in
        guard let c = parseColor(s) else { fatalError("bad color '\(s)' in UIGradientView") }
        return c.resolvedColor(with: UITraitCollection.current)
    }
    if let locs = numArray(j["locations"]) { g.locations = locs }
    if let p = numArray(j["startPoint"]), p.count == 2 {
        g.startPoint = CGPoint(x: p[0], y: p[1])
    }
    if let p = numArray(j["endPoint"]), p.count == 2 {
        g.endPoint = CGPoint(x: p[0], y: p[1])
    }
    if let t = j["gradientType"]?.stringValue {
        guard t == "axial" else { fatalError("gradientType '\(t)' unsupported (axial only)") }
    }
    return g
}

func makeSwitch(_ j: SceneJSON) -> UISwitch {
    let s = UISwitch()
    s.isOn = j["on"]?.boolValue ?? false
    if let c = colorOrDie(j["onTintColor"], "UISwitch") { s.onTintColor = c }
    return s
}

func makeButton(_ j: SceneJSON) -> UIButton {
    let b = UIButton(type: .system)
    b.setTitle(j["title"]?.stringValue, for: .normal)
    if j["fontSize"] != nil || j["fontWeight"] != nil { b.titleLabel?.font = fontFrom(j) }
    // Mirror the oracle: pin the dynamic tint to the scene style (it sets
    // b.tintColor = b.tintColor.resolvedColor(with: traits) at build time;
    // UITraitCollection.current carries the scene traits here).
    b.tintColor = b.tintColor.resolvedColor(with: UITraitCollection.current)
    if let c = colorOrDie(j["titleColor"], "UIButton") { b.setTitleColor(c, for: .normal) }
    if j["enabled"]?.boolValue == false { b.isEnabled = false }
    return b
}

/// Classes the scene spec defines but OpenUIKit does not implement yet.
/// They are instantiated as plain UIView (with common props) so geometry
/// scenes still run; the compare step fails for these scenes until the
/// owning modules land. Adding a real class later = one `case` line below.
let notYetImplementedClasses: Set<String> = []

func buildView(_ j: SceneJSON, scale: CGFloat, warn: (String) -> Void) -> UIView {
    let cls = j["class"]?.stringValue ?? "UIView"
    let v: UIView
    switch cls {
    case "UIView": v = UIView()
    case "UILabel": v = makeLabel(j)
    case "UIImageView": v = makeImageView(j, scale: scale)
    case "UIProgressView": v = makeProgressView(j)
    case "UIStackView": v = makeStackView(j)
    case "UISwitch": v = makeSwitch(j)
    case "UIButton": v = makeButton(j)
    case "UIGradientView": v = makeGradientView(j)
    case _ where notYetImplementedClasses.contains(cls):
        warn("openrender: warning: class '\(cls)' not implemented yet; substituting plain UIView")
        v = UIView()
    default:
        fatalError("unsupported class \(cls)")
    }

    applyCommon(v, j, name: cls)

    if let subs = j["subviews"]?.arrayValue {
        for sub in subs {
            guard let subJ = sub.objectValue else { fatalError("bad subview in \(cls)") }
            let child = buildView(subJ, scale: scale, warn: warn)
            if let stack = v as? UIStackView {
                stack.addArrangedSubview(child)
            } else {
                v.addSubview(child)
            }
        }
    }

    if j["sizeToFit"]?.boolValue == true {
        let origin = v.frame.origin
        v.sizeToFit()
        v.frame.origin = origin
    }
    if let t = numArray(j["transform"]), t.count == 6 {
        v.transform = CGAffineTransform(a: t[0], b: t[1], c: t[2], d: t[3], tx: t[4], ty: t[5])
    }
    return v
}

// MARK: - Layout dump (mirror oracle keys + rounding exactly)

func round3(_ v: CGFloat) -> Double { (Double(v) * 1000).rounded() / 1000 }

func dumpLayout(_ v: UIView, path: String, into out: inout [JSONValue]) {
    var entry: [String: JSONValue] = [
        "path": .string(path),
        "class": .string(String(describing: type(of: v))),
        "frame": .array([.number(round3(v.frame.origin.x)), .number(round3(v.frame.origin.y)),
                         .number(round3(v.frame.width)), .number(round3(v.frame.height))]),
    ]
    // Oracle: intrinsic for UILabel/UIButton/UISwitch/UIImageView/UIProgressView.
    // Extend the check as OpenUIKit grows those classes.
    if v is UILabel || v is UIButton || v is UIImageView || v is UIProgressView || v is UISwitch {
        let i = v.intrinsicContentSize
        entry["intrinsic"] = .array([
            .number(i.width == UIView.noIntrinsicMetric ? -1 : round3(i.width)),
            .number(i.height == UIView.noIntrinsicMetric ? -1 : round3(i.height)),
        ])
    }
    // Oracle: sizeThatFits200 for UILabel/UIButton.
    if v is UILabel || v is UIButton {
        let s = v.sizeThatFits(CGSize(width: 200, height: CGFloat.greatestFiniteMagnitude))
        entry["sizeThatFits200"] = .array([.number(round3(s.width)), .number(round3(s.height))])
    }
    out.append(.object(entry))
    for (i, sub) in v.subviews.enumerated() {
        dumpLayout(sub, path: path.isEmpty ? "\(i)" : "\(path).\(i)", into: &out)
    }
}

// MARK: - Run one scene

struct SceneResult {
    var name: String
    var png: [UInt8]
    var layout: JSONValue
}

func runScene(_ scene: JSONValue, warn: (String) -> Void) -> SceneResult {
    guard let name = scene["name"]?.stringValue else { fatalError("scene missing name") }
    guard let sz = numArray(scene["size"]), sz.count == 2 else { fatalError("scene missing size") }
    let scale = num(scene["scale"]) ?? 2
    let style: UIUserInterfaceStyle = scene["style"]?.stringValue == "dark" ? .dark : .light

    // Mirror oracle's traits.performAsCurrent { build } — semantic colors
    // resolved at build time (e.g. layer.borderColor via .cgColor) must use
    // the scene style.
    UITraitCollection.current = UITraitCollection(userInterfaceStyle: style, displayScale: scale)

    guard var rootJ = scene["root"]?.objectValue else { fatalError("scene missing root") }
    // Match the oracle exactly: it overwrites rootJ["frame"] with a mixed
    // Int/CGFloat array that its own numArray() then fails to parse, so the
    // root view KEEPS frame (0,0,0,0) and its background never draws (see
    // golden/*.layout.json: root frame is [0,0,0,0]; golden PNGs are
    // transparent outside subviews). Drop any root frame to reproduce that.
    rootJ["frame"] = nil

    let container = buildView(rootJ, scale: scale, warn: warn)
    container.overrideUserInterfaceStyle = style
    container.setNeedsLayout()
    container.layoutIfNeeded()

    var views: [JSONValue] = []
    dumpLayout(container, path: "", into: &views)
    let layout = JSONValue.object(["name": .string(name), "views": .array(views)])

    // The canvas must be the scene size even though the root view is 0x0
    // (oracle renders into a sz-sized context). Host wrapper draws nothing
    // itself; it only gives UIRenderer the right bitmap size.
    let host = UIView(frame: CGRect(x: 0, y: 0, width: sz[0], height: sz[1]))
    host.addSubview(container)
    let bmp = UIRenderer.render(host, scale: scale)
    return SceneResult(name: name, png: bmp.pngData(), layout: layout)
}
