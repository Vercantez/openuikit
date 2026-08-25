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

// MARK: - Gradient view (spec v2)

/// A UIView backed by CAGradientLayer. Named exactly "UIGradientView" so the
/// layout dump class matches the scene-spec class name.
final class UIGradientView: UIView {
    override class var layerClass: AnyClass { CAGradientLayer.self }
}

// MARK: - Chrome (scene spec v5 — M10)

/// Set by oracle2 (which has a real, appeared root view controller) BEFORE
/// building a scene. Chrome classes that need real view-controller
/// containment (UINavigationStack, UITabBarStack) refuse to build without it,
/// which also keeps them out of the offscreen v1 oracle — their bars use
/// render-server-only materials, so such scenes must carry `"window": true`.
var oracleHostViewController: UIViewController? = nil
/// Child view controllers created while building chrome scenes. oracle2
/// removes them from the host after capturing each scene.
var oracleChildControllers: [UIViewController] = []
/// Actions that must run AFTER the scene is attached to the live window and
/// has settled (oracle2 only). Used for the large-title collapse: the nav
/// bar's scroll observation only tracks a contentOffset applied while live.
var oraclePostAttachActions: [() -> Void] = []
/// Set while building when the scene contains chrome that needs the window
/// to settle (appearance callbacks, bar materials) before capture.
var oracleNeedsSettle = false
/// Retains table-view data-source drivers for the life of the process
/// (UITableView holds its dataSource/delegate weakly).
var sceneTableDrivers: [SceneTableDriver] = []

/// In-scene UITableView data source built from the scene JSON's "sections".
final class SceneTableDriver: NSObject, UITableViewDataSource, UITableViewDelegate {
    struct Row {
        let style: UITableViewCell.CellStyle
        let text: String
        let detailText: String?
        let accessory: UITableViewCell.AccessoryType
        let selected: Bool
    }
    struct Section {
        let header: String?
        let footer: String?
        let rows: [Row]
    }
    let sections: [Section]

    init(sectionsJSON: [JSON]) {
        sections = sectionsJSON.map { s in
            let rows = (s["rows"] as? [JSON] ?? []).map { r -> Row in
                let style: UITableViewCell.CellStyle
                switch r["style"] as? String ?? "default" {
                case "default": style = .default
                case "subtitle": style = .subtitle
                case "value1": style = .value1
                case let x: fatalError("bad cell style '\(x)'")
                }
                let accessory: UITableViewCell.AccessoryType
                switch r["accessory"] as? String ?? "none" {
                case "none": accessory = .none
                case "disclosureIndicator": accessory = .disclosureIndicator
                case "checkmark": accessory = .checkmark
                case let x: fatalError("bad accessory '\(x)'")
                }
                return Row(style: style, text: r["text"] as? String ?? "",
                           detailText: r["detailText"] as? String,
                           accessory: accessory,
                           selected: r["selected"] as? Bool == true)
            }
            return Section(header: s["header"] as? String,
                           footer: s["footer"] as? String, rows: rows)
        }
    }

    func numberOfSections(in tableView: UITableView) -> Int { sections.count }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        sections[section].rows.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = sections[indexPath.section].rows[indexPath.row]
        // Fresh cell every time — no reuse, fully deterministic.
        let cell = UITableViewCell(style: row.style, reuseIdentifier: nil)
        // Modern chrome: content configuration (matches what real apps get);
        // defaultContentConfiguration() adapts to the cell's init style.
        var cfg = cell.defaultContentConfiguration()
        cfg.text = row.text
        if let d = row.detailText { cfg.secondaryText = d }
        cell.contentConfiguration = cfg
        cell.accessoryType = row.accessory
        return cell
    }
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        sections[section].header
    }
    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        sections[section].footer
    }
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell,
                   forRowAt indexPath: IndexPath) {
        // Static scene: a "selected": true row shows the selection highlight.
        if sections[indexPath.section].rows[indexPath.row].selected {
            cell.setSelected(true, animated: false)
        }
    }
}

/// Root-only chrome containers (spec v5). Plain UIViews named exactly like
/// the scene-spec classes so layout dumps agree; the real UIKit controller
/// view (all-private classes, skipped by compare.py) is their only subview.
final class UINavigationStack: UIView {}
final class UITabBarStack: UIView {}

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
    // Shadows (spec v2). layer.shadow* — note masksToBounds must stay false
    // (i.e. no clipsToBounds on the same view) or the shadow is clipped away.
    if let c = colorOrDie(j["shadowColor"], name, traits) { v.layer.shadowColor = c.cgColor }
    if let o = num(j["shadowOpacity"]) { v.layer.shadowOpacity = Float(o) }
    if let off = numArray(j["shadowOffset"]), off.count == 2 {
        v.layer.shadowOffset = CGSize(width: off[0], height: off[1])
    }
    if let r = num(j["shadowRadius"]) { v.layer.shadowRadius = r }
    if let e = j["userInteractionEnabled"] as? Bool { v.isUserInteractionEnabled = e }
    // Auto Layout (spec v4.3 — M9). A view that participates in constraints
    // opts out of the autoresizing-mask translation; such views may omit
    // "frame" entirely (constraints from the top-level "constraints" array
    // position them).
    if j["useConstraints"] as? Bool == true {
        v.translatesAutoresizingMaskIntoConstraints = false
    }
    if let p = num(j["huggingH"]) {
        v.setContentHuggingPriority(UILayoutPriority(Float(p)), for: .horizontal)
    }
    if let p = num(j["huggingV"]) {
        v.setContentHuggingPriority(UILayoutPriority(Float(p)), for: .vertical)
    }
    if let p = num(j["compressionH"]) {
        v.setContentCompressionResistancePriority(UILayoutPriority(Float(p)), for: .horizontal)
    }
    if let p = num(j["compressionV"]) {
        v.setContentCompressionResistancePriority(UILayoutPriority(Float(p)), for: .vertical)
    }
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

// MARK: - Attributed text (scene spec v5.2 — M12)

func underlineStyle(_ v: Any?) -> Int? {
    if let b = v as? Bool { return b ? NSUnderlineStyle.single.rawValue : 0 }
    guard let s = v as? String else { return nil }
    switch s {
    case "none": return 0
    case "single": return NSUnderlineStyle.single.rawValue
    case "thick": return NSUnderlineStyle.thick.rawValue
    case "double": return NSUnderlineStyle.double.rawValue
    default: fatalError("bad underline style \(s)")
    }
}

func paragraphStyleFrom(_ j: JSON) -> NSParagraphStyle {
    let p = NSMutableParagraphStyle()
    p.alignment = textAlignment(j["alignment"] as? String)
    if let v = num(j["lineSpacing"]) { p.lineSpacing = v }
    if let v = num(j["paragraphSpacing"]) { p.paragraphSpacing = v }
    if let v = num(j["paragraphSpacingBefore"]) { p.paragraphSpacingBefore = v }
    if let v = num(j["lineHeightMultiple"]) { p.lineHeightMultiple = v }
    if let v = num(j["minimumLineHeight"]) { p.minimumLineHeight = v }
    if let v = num(j["maximumLineHeight"]) { p.maximumLineHeight = v }
    if let v = num(j["firstLineHeadIndent"]) { p.firstLineHeadIndent = v }
    if let v = num(j["headIndent"]) { p.headIndent = v }
    if let v = num(j["tailIndent"]) { p.tailIndent = v }
    p.lineBreakMode = lineBreakMode(j["lineBreakMode"] as? String)
    return p
}

func attributedStringFrom(_ j: JSON, traits: UITraitCollection) -> NSAttributedString {
    guard let runs = j["runs"] as? [JSON], !runs.isEmpty else {
        fatalError("attributedText needs a non-empty \"runs\" array")
    }
    let out = NSMutableAttributedString()
    for r in runs {
        guard let text = r["text"] as? String else { fatalError("run needs \"text\"") }
        var a: [NSAttributedString.Key: Any] = [.font: fontFrom(r)]
        a[.foregroundColor] = colorOrDie(r["color"], "attributed run", traits)
            ?? UIColor.label.resolvedColor(with: traits)
        if let c = colorOrDie(r["backgroundColor"], "attributed run", traits) {
            a[.backgroundColor] = c
        }
        if let v = num(r["kern"]) { a[.kern] = v }
        if let v = num(r["baselineOffset"]) { a[.baselineOffset] = v }
        if let u = underlineStyle(r["underline"]) { a[.underlineStyle] = u }
        if let u = underlineStyle(r["strikethrough"]) { a[.strikethroughStyle] = u }
        if let c = colorOrDie(r["underlineColor"], "attributed run", traits) {
            a[.underlineColor] = c
        }
        if let c = colorOrDie(r["strikethroughColor"], "attributed run", traits) {
            a[.strikethroughColor] = c
        }
        out.append(NSAttributedString(string: text, attributes: a))
    }
    if let pj = j["paragraph"] as? JSON {
        out.addAttribute(.paragraphStyle, value: paragraphStyleFrom(pj),
                         range: NSRange(location: 0, length: out.length))
    }
    return out
}

func buildView(_ jIn: JSON, scale: CGFloat, traits: UITraitCollection) -> UIView {
    var j = jIn   // chrome cases consume "subviews" themselves and clear it
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
        // Attributed content last: UILabel adopts the paragraph style's
        // alignment / line-break mode when the string carries one.
        if let aj = j["attributedText"] as? JSON {
            l.attributedText = attributedStringFrom(aj, traits: traits)
        }
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
        if j["highlighted"] as? Bool == true { b.isHighlighted = true }
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
    case "UISlider":
        let s = UISlider()
        s.minimumValue = Float(num(j["minimumValue"]) ?? 0)
        s.maximumValue = Float(num(j["maximumValue"]) ?? 1)
        s.value = Float(num(j["value"]) ?? 0)
        s.tintColor = s.tintColor.resolvedColor(with: traits)
        if let c = colorOrDie(j["minimumTrackTintColor"], cls, traits) {
            s.minimumTrackTintColor = c
        }
        if let c = colorOrDie(j["maximumTrackTintColor"], cls, traits) {
            s.maximumTrackTintColor = c
        }
        if let c = colorOrDie(j["thumbTintColor"], cls, traits) { s.thumbTintColor = c }
        if j["enabled"] as? Bool == false { s.isEnabled = false }
        v = s
    case "UISegmentedControl":
        let titles = j["segments"] as? [String] ?? []
        let sc = UISegmentedControl(items: titles)
        if let i = j["selectedSegmentIndex"] as? Int { sc.selectedSegmentIndex = i }
        sc.tintColor = sc.tintColor.resolvedColor(with: traits)
        if let c = colorOrDie(j["selectedSegmentTintColor"], cls, traits) {
            sc.selectedSegmentTintColor = c
        }
        if j["enabled"] as? Bool == false { sc.isEnabled = false }
        v = sc
    case "UIActivityIndicatorView":
        let style: UIActivityIndicatorView.Style
        switch j["style"] as? String ?? "medium" {
        case "medium": style = .medium
        case "large": style = .large
        case let s: fatalError("bad activity indicator style \(s)")
        }
        let a = UIActivityIndicatorView(style: style)
        if let c = colorOrDie(j["color"], cls, traits) { a.color = c }
        else { a.color = a.color.resolvedColor(with: traits) }
        a.hidesWhenStopped = j["hidesWhenStopped"] as? Bool ?? true
        if j["animating"] as? Bool ?? true { a.startAnimating() }
        v = a
    case "UIPageControl":
        let p = UIPageControl()
        p.numberOfPages = j["numberOfPages"] as? Int ?? 3
        p.currentPage = j["currentPage"] as? Int ?? 0
        p.hidesForSinglePage = j["hidesForSinglePage"] as? Bool ?? false
        p.tintColor = p.tintColor.resolvedColor(with: traits)
        if let c = colorOrDie(j["pageIndicatorTintColor"], cls, traits) {
            p.pageIndicatorTintColor = c
        }
        if let c = colorOrDie(j["currentPageIndicatorTintColor"], cls, traits) {
            p.currentPageIndicatorTintColor = c
        }
        v = p
    case "UIStepper":
        let s = UIStepper()
        s.minimumValue = num(j["minimumValue"]).map { Double($0) } ?? 0
        s.maximumValue = num(j["maximumValue"]).map { Double($0) } ?? 100
        s.stepValue = num(j["stepValue"]).map { Double($0) } ?? 1
        s.value = num(j["value"]).map { Double($0) } ?? 0
        s.tintColor = s.tintColor.resolvedColor(with: traits)
        if j["enabled"] as? Bool == false { s.isEnabled = false }
        v = s
    case "UIGradientView":
        let g = UIGradientView()
        let gl = g.layer as! CAGradientLayer
        guard let colorStrings = j["colors"] as? [String], colorStrings.count >= 2 else {
            fatalError("UIGradientView needs \"colors\" with >= 2 entries")
        }
        gl.colors = colorStrings.map { s -> CGColor in
            guard let c = parseColor(s) else { fatalError("bad color '\(s)' in UIGradientView") }
            return c.resolvedColor(with: traits).cgColor
        }
        if let locs = numArray(j["locations"]) {
            gl.locations = locs.map { NSNumber(value: Double($0)) }
        }
        if let p = numArray(j["startPoint"]), p.count == 2 { gl.startPoint = CGPoint(x: p[0], y: p[1]) }
        if let p = numArray(j["endPoint"]), p.count == 2 { gl.endPoint = CGPoint(x: p[0], y: p[1]) }
        if let t = j["gradientType"] as? String {
            guard t == "axial" else { fatalError("gradientType '\(t)' unsupported (axial only)") }
            gl.type = .axial
        }
        v = g
    case "UITextField":
        let t = UITextField()
        switch j["borderStyle"] as? String ?? "none" {
        case "none": t.borderStyle = .none
        case "line": t.borderStyle = .line
        case "bezel": t.borderStyle = .bezel
        case "roundedRect": t.borderStyle = .roundedRect
        case let b: fatalError("bad borderStyle \(b)")
        }
        t.text = j["text"] as? String
        t.placeholder = j["placeholder"] as? String
        if j["fontSize"] != nil || j["fontWeight"] != nil { t.font = fontFrom(j) }
        if let c = colorOrDie(j["textColor"], cls, traits) { t.textColor = c }
        // Default .label is dynamic and would resolve light offscreen.
        else { t.textColor = UIColor.label.resolvedColor(with: traits) }
        t.tintColor = t.tintColor.resolvedColor(with: traits)
        if let aj = j["attributedText"] as? JSON {
            t.attributedText = attributedStringFrom(aj, traits: traits)
        }
        v = t
    case "UITextView":
        let t = UITextView()
        // Same pinning as UIScrollView: no safe-area shifts, no indicator
        // subviews in the layout dump.
        t.contentInsetAdjustmentBehavior = .never
        t.showsVerticalScrollIndicator = false
        t.showsHorizontalScrollIndicator = false
        t.text = j["text"] as? String ?? ""
        t.font = fontFrom(j)   // spec: fontSize default 17, always applied
        if let c = colorOrDie(j["textColor"], cls, traits) { t.textColor = c }
        else { t.textColor = UIColor.label.resolvedColor(with: traits) }
        // Default background is dynamic systemBackground — pin it to the
        // scene style (an explicit scene backgroundColor overrides below).
        t.backgroundColor = t.backgroundColor?.resolvedColor(with: traits)
        if let aj = j["attributedText"] as? JSON {
            t.attributedText = attributedStringFrom(aj, traits: traits)
        }
        v = t
    case "UIScrollView":
        let s = UIScrollView()
        // No VC hierarchy offscreen: keep UIKit from shifting the offset
        // by safe-area adjustments, and no indicator subviews (they would
        // pollute the layout dump; OpenUIKit creates its lazily on scroll).
        s.contentInsetAdjustmentBehavior = .never
        s.showsVerticalScrollIndicator = false
        s.showsHorizontalScrollIndicator = false
        if let cs = numArray(j["contentSize"]), cs.count == 2 {
            s.contentSize = CGSize(width: cs[0], height: cs[1])
        }
        if let ci = numArray(j["contentInset"]), ci.count == 4 {
            s.contentInset = UIEdgeInsets(top: ci[0], left: ci[1],
                                          bottom: ci[2], right: ci[3])
        }
        v = s
    case "UITableView":
        let style: UITableView.Style
        switch j["style"] as? String ?? "plain" {
        case "plain": style = .plain
        case "insetGrouped": style = .insetGrouped
        case let s: fatalError("bad table style '\(s)'")
        }
        let t = UITableView(frame: .zero, style: style)
        // Same pinning as UIScrollView (no VC/safe-area shifts offscreen, no
        // indicator subviews in the dump).
        t.contentInsetAdjustmentBehavior = .never
        t.showsVerticalScrollIndicator = false
        t.showsHorizontalScrollIndicator = false
        // iPhone metrics: cell margins / inset-grouped insets are size-class
        // dependent; the Catalyst oracle idiom is .pad, so pin compact width.
        t.traitOverrides.horizontalSizeClass = .compact
        let driver = SceneTableDriver(sectionsJSON: j["sections"] as? [JSON] ?? [])
        sceneTableDrivers.append(driver)   // dataSource/delegate are weak
        t.dataSource = driver
        t.delegate = driver
        v = t
    case "UINavigationStack":
        // Root-only (spec v5). Real UINavigationController; requires a live
        // host VC (oracle2) — bar materials are render-server-only anyway.
        guard let host = oracleHostViewController else {
            fatalError("UINavigationStack requires oracle2 (mark the scene \"window\": true)")
        }
        let stack = UINavigationStack()
        stack.traitOverrides.horizontalSizeClass = .compact  // iPhone bar metrics
        let contentVC = UIViewController()
        contentVC.view.backgroundColor = UIColor.systemBackground.resolvedColor(with: traits)
        contentVC.navigationItem.title = j["title"] as? String
        let scroll = UIScrollView(frame: contentVC.view.bounds)
        scroll.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        // .automatic is REQUIRED here: the large-title expansion/collapse is
        // driven by contentOffset relative to the bar-adjusted inset.
        scroll.contentInsetAdjustmentBehavior = .automatic
        scroll.showsVerticalScrollIndicator = false
        scroll.showsHorizontalScrollIndicator = false
        if let csz = numArray(j["contentSize"]), csz.count == 2 {
            scroll.contentSize = CGSize(width: csz[0], height: csz[1])
        }
        for sub in j["subviews"] as? [JSON] ?? [] {
            scroll.addSubview(buildView(sub, scale: scale, traits: traits))
        }
        j["subviews"] = nil   // consumed (they live in the scroll view)
        contentVC.view.addSubview(scroll)
        // Explicitly bind the scroll view to the bar (large-title expansion /
        // collapse + edge effects) — automatic detection is unreliable for a
        // hosted (non-root) navigation controller.
        contentVC.setContentScrollView(scroll, for: .top)
        let nav = UINavigationController(rootViewController: contentVC)
        nav.navigationBar.prefersLargeTitles = j["largeTitle"] as? Bool == true
        if j["largeTitle"] as? Bool == true {
            contentVC.navigationItem.largeTitleDisplayMode = .always
        }
        host.addChild(nav)
        nav.view.frame = stack.bounds
        nav.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        stack.addSubview(nav.view)
        nav.didMove(toParent: host)
        oracleChildControllers.append(nav)
        oracleNeedsSettle = true
        // The bar's large-title expansion/collapse state only updates for
        // offset changes its scroll observer SEES — apply offsets live,
        // post-attach. Without an explicit "contentOffset" the scene shows
        // the rest (expanded) state; the bar still needs one observed change
        // to leave its initial collapsed layout, so nudge and settle back.
        let explicitOffset: CGPoint? = (numArray(j["contentOffset"]).flatMap {
            $0.count == 2 ? CGPoint(x: $0[0], y: $0[1]) : nil
        })
        oraclePostAttachActions.append { [weak nav] in
            if let co = explicitOffset {
                scroll.setContentOffset(co, animated: false)
            } else {
                // Expanded rest state. The bar only engages its expanded
                // layout for an OBSERVED offset that physically reveals the
                // large-title region, so: reveal it (inset grows to include
                // the large title), force the bar layout, then settle at the
                // new rest offset.
                scroll.setContentOffset(
                    CGPoint(x: 0, y: -scroll.adjustedContentInset.top - 52), animated: false)
                nav?.view.layoutIfNeeded()
                scroll.setContentOffset(
                    CGPoint(x: 0, y: -scroll.adjustedContentInset.top), animated: false)
            }
        }
        v = stack
    case "UITabBarStack":
        // Root-only (spec v5). Real UITabBarController with template-image
        // items; requires a live host VC (oracle2).
        guard let host = oracleHostViewController else {
            fatalError("UITabBarStack requires oracle2 (mark the scene \"window\": true)")
        }
        let stack = UITabBarStack()
        stack.traitOverrides.horizontalSizeClass = .compact  // bottom (iPhone) tab bar
        let tab = UITabBarController()
        var vcs: [UIViewController] = []
        for (i, item) in (j["items"] as? [JSON] ?? []).enumerated() {
            let vc = UIViewController()
            vc.view.backgroundColor = UIColor.systemBackground.resolvedColor(with: traits)
            if let content = item["content"] as? JSON {
                vc.view.addSubview(buildView(content, scale: scale, traits: traits))
            }
            var img: UIImage? = nil
            if let ij = item["image"] as? JSON {
                img = makeImage(ij, scale: scale).withRenderingMode(.alwaysTemplate)
            }
            vc.tabBarItem = UITabBarItem(title: item["title"] as? String, image: img, tag: i)
            vcs.append(vc)
        }
        tab.viewControllers = vcs
        if let idx = j["selectedIndex"] as? Int { tab.selectedIndex = idx }
        if let c = colorOrDie(j["tintColor"], cls, traits) { tab.tabBar.tintColor = c }
        host.addChild(tab)
        tab.view.frame = stack.bounds
        tab.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        stack.addSubview(tab.view)
        tab.didMove(toParent: host)
        oracleChildControllers.append(tab)
        oracleNeedsSettle = true
        // Catalyst leaves the (fully laid out) UITabBar hidden with alpha 0
        // — it expects to host tabs in the NSToolbar titlebar, which oracle2
        // suppresses. Reveal the real bar once live.
        oraclePostAttachActions.append { [weak tab] in
            tab?.tabBar.isHidden = false
            tab?.tabBar.alpha = 1
        }
        v = stack
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
    // Scroll position after frame/children exist (UIKit may re-clamp an
    // offset applied to a zero-sized scroll view).
    if let sv = v as? UIScrollView, let co = numArray(j["contentOffset"]),
       co.count == 2 {
        sv.contentOffset = CGPoint(x: co[0], y: co[1])
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
    // UISlider is the only new (app-compat cluster) control whose intrinsic
    // size OpenUIKit reproduces exactly; UISegmentedControl's per-segment
    // intrinsic width does not follow any formula that fits every probe,
    // and the remaining new controls are not implemented yet
    // (docs/KNOWN_GAPS.md).
    if v is UILabel || v is UIButton || v is UISwitch || v is UIImageView || v is UIProgressView
        || v is UITextField || v is UITextView || v is UISlider {
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

// MARK: - Hit tests (scene spec v4)

/// Map every SCENE-DEFINED view (the ones buildView created from the JSON)
/// to its dot-joined subview-index path. Private UIKit implementation
/// subviews (UIButtonLabel, UISwitch internals, ...) are NOT in the
/// registry — hit results are normalized to the nearest scene-defined
/// ancestor so both renderers report comparable paths. Scene children are
/// always added before UIKit inserts private siblings, so scene child i ==
/// subviews[i] (the same invariant the layout-dump path comparison relies
/// on).
func sceneViewRegistry(_ v: UIView, _ j: JSON, path: String,
                       into out: inout [ObjectIdentifier: String]) {
    out[ObjectIdentifier(v)] = path
    let subs = j["subviews"] as? [JSON] ?? []
    for (i, subJ) in subs.enumerated() {
        guard i < v.subviews.count else { break }
        sceneViewRegistry(v.subviews[i], subJ,
                          path: path.isEmpty ? "\(i)" : "\(path).\(i)", into: &out)
    }
}

/// Run the scene's top-level "hitTests" probe points (root coordinates)
/// against REAL UIKit hit testing and dump [{"point": [x, y],
/// "path": "0.2.1" | null}, ...].
///
/// The root container keeps the degenerate (0,0,0,0) frame (root-frame
/// quirk), so `container.hitTest` would always fail the root's own
/// point(inside:). The driver instead performs UIKit's hit-test recursion
/// step at the root itself — reverse subview order, per-subview converted
/// point, first non-nil hitTest wins — exactly what UIView.hitTest does for
/// its children. Consequence: the root view itself is never a hit result
/// (misses dump null).
func runHitTests(_ points: [CGPoint], container: UIView, rootJSON: JSON) -> [JSON] {
    var registry: [ObjectIdentifier: String] = [:]
    sceneViewRegistry(container, rootJSON, path: "", into: &registry)
    var out: [JSON] = []
    for p in points {
        var hit: UIView? = nil
        for sub in container.subviews.reversed() {
            if let h = sub.hitTest(sub.convert(p, from: container), with: nil) {
                hit = h
                break
            }
        }
        // Normalize to the nearest scene-defined ancestor.
        var norm = hit
        while let v = norm, registry[ObjectIdentifier(v)] == nil { norm = v.superview }
        var entry: JSON = ["point": [round3(p.x), round3(p.y)]]
        entry["path"] = norm.flatMap { registry[ObjectIdentifier($0)] } ?? NSNull()
        out.append(entry)
    }
    return out
}

// MARK: - Animations (scene spec v3)

/// One entry of the top-level `"animations"` array. See docs/SCENE_SPEC.md.
struct AnimationSpec {
    let kind: String              // "uiview-animate" | "switch-setOn"
    let target: String            // view path, e.g. "0.1" ("" = root)
    let duration: TimeInterval
    let delay: TimeInterval
    /// nil when `spring` is set. One of linear|easeIn|easeOut|easeInOut.
    let curve: UIView.AnimationOptions?
    let springDamping: CGFloat?   // non-nil => spring animation
    let springVelocity: CGFloat
    let changes: JSON             // property -> target value (scene-spec encodings)
    let on: Bool                  // switch-setOn only
}

func parseAnimations(_ scene: JSON) -> [AnimationSpec] {
    guard let arr = scene["animations"] as? [JSON] else { return [] }
    return arr.map { j in
        let kind = j["kind"] as? String ?? "uiview-animate"
        switch kind {
        case "uiview-animate":
            var curve: UIView.AnimationOptions? = nil
            var damping: CGFloat? = nil
            var velocity: CGFloat = 0
            if let s = j["spring"] as? JSON {
                damping = num(s["damping"]) ?? 1
                velocity = num(s["initialVelocity"]) ?? 0
            } else {
                switch j["curve"] as? String ?? "easeInOut" {
                case "linear": curve = .curveLinear
                case "easeIn": curve = .curveEaseIn
                case "easeOut": curve = .curveEaseOut
                case "easeInOut": curve = .curveEaseInOut
                case let c: fatalError("bad animation curve '\(c)'")
                }
            }
            guard let changes = j["changes"] as? JSON, !changes.isEmpty else {
                fatalError("animation needs non-empty \"changes\"")
            }
            return AnimationSpec(kind: kind, target: j["target"] as? String ?? "",
                                 duration: Double(num(j["duration"]) ?? 0.25),
                                 delay: Double(num(j["delay"]) ?? 0),
                                 curve: curve, springDamping: damping, springVelocity: velocity,
                                 changes: changes, on: false)
        case "switch-setOn":
            // Real UISwitch.setOn(_:animated: true) under the frozen clock;
            // the switch supplies its own timing (duration/curve keys are
            // not accepted).
            guard let on = j["on"] as? Bool else {
                fatalError("switch-setOn needs \"on\": true|false")
            }
            return AnimationSpec(kind: kind, target: j["target"] as? String ?? "",
                                 duration: 0, delay: 0, curve: nil,
                                 springDamping: nil, springVelocity: 0,
                                 changes: [:], on: on)
        default:
            fatalError("bad animation kind '\(kind)'")
        }
    }
}

/// Resolve a dot-joined subview-index path ("" = root) against the built tree.
/// Used by animation targets AND constraint items (spec v4.3).
func viewAtPath(_ root: UIView, _ path: String) -> UIView {
    var v = root
    guard !path.isEmpty else { return v }
    for comp in path.split(separator: ".") {
        guard let i = Int(comp), i >= 0, i < v.subviews.count else {
            fatalError("bad view path '\(path)'")
        }
        v = v.subviews[i]
    }
    return v
}

// MARK: - Constraints (scene spec v4.3 — M9)

func layoutAttribute(_ s: String) -> NSLayoutConstraint.Attribute {
    switch s {
    case "left": return .left
    case "right": return .right
    case "top": return .top
    case "bottom": return .bottom
    case "leading": return .leading
    case "trailing": return .trailing
    case "width": return .width
    case "height": return .height
    case "centerX": return .centerX
    case "centerY": return .centerY
    case "firstBaseline": return .firstBaseline
    case "lastBaseline": return .lastBaseline
    default: fatalError("bad constraint attribute '\(s)'")
    }
}

/// Build and activate REAL NSLayoutConstraints from the scene's top-level
/// "constraints" array. Item paths use layout-dump addressing ("" = root).
/// Must run after the tree is built and BEFORE layoutIfNeeded; priorities are
/// set pre-activation (required<->optional flips post-activation would throw).
func activateConstraints(_ specs: [JSON], container: UIView) {
    var built: [NSLayoutConstraint] = []
    for j in specs {
        guard let itemPath = j["item"] as? String else {
            fatalError("constraint needs \"item\" (view path, \"\" = root)")
        }
        guard let attrName = j["attribute"] as? String else {
            fatalError("constraint needs \"attribute\"")
        }
        let item = viewAtPath(container, itemPath)
        let relation: NSLayoutConstraint.Relation
        switch j["relation"] as? String ?? "eq" {
        case "eq": relation = .equal
        case "le": relation = .lessThanOrEqual
        case "ge": relation = .greaterThanOrEqual
        case let r: fatalError("bad constraint relation '\(r)'")
        }
        var toView: UIView? = nil
        var toAttr: NSLayoutConstraint.Attribute = .notAnAttribute
        if let tp = j["toItem"] as? String {   // JSON null decodes as NSNull, not String
            toView = viewAtPath(container, tp)
            // toAttribute defaults to the first attribute (the common case:
            // pinning like to like).
            toAttr = layoutAttribute(j["toAttribute"] as? String ?? attrName)
        } else if j["toAttribute"] is String {
            fatalError("constraint has \"toAttribute\" but no \"toItem\"")
        }
        let c = NSLayoutConstraint(item: item, attribute: layoutAttribute(attrName),
                                   relatedBy: relation, toItem: toView, attribute: toAttr,
                                   multiplier: num(j["multiplier"]) ?? 1,
                                   constant: num(j["constant"]) ?? 0)
        if let p = num(j["priority"]) { c.priority = UILayoutPriority(Float(p)) }
        built.append(c)
    }
    NSLayoutConstraint.activate(built)
}

/// Apply one animation entry's `changes` to the target view. Called INSIDE the
/// UIView.animate block. Property encodings match the scene spec (colors are
/// resolved eagerly against the scene traits, like all scene colors).
func applyAnimationChanges(_ v: UIView, _ changes: JSON, traits: UITraitCollection) {
    for (key, value) in changes {
        switch key {
        case "frame":
            let f = numArray(value)!
            v.frame = CGRect(x: f[0], y: f[1], width: f[2], height: f[3])
        case "center":
            let c = numArray(value)!
            v.center = CGPoint(x: c[0], y: c[1])
        case "bounds":
            let b = numArray(value)!
            v.bounds = CGRect(x: b[0], y: b[1], width: b[2], height: b[3])
        case "alpha":
            v.alpha = num(value)!
        case "backgroundColor":
            v.backgroundColor = colorOrDie(value, "animation changes", traits)
        case "transform":
            let t = numArray(value)!
            v.transform = CGAffineTransform(a: t[0], b: t[1], c: t[2], d: t[3], tx: t[4], ty: t[5])
        case "cornerRadius":
            v.layer.cornerRadius = num(value)!
        default:
            fatalError("unsupported animated property '\(key)'")
        }
    }
}

/// Kick off every animation entry with real UIView.animate. The caller is
/// responsible for having FROZEN the clock first (ancestor layer speed = 0,
/// timeOffset = 0) so the animations' beginTimes land on the frozen local
/// timeline and captures are deterministic.
///
/// Delay handling: UIKit computes the CAAnimation's beginTime as
/// convertTime(CACurrentMediaTime() + delay, to: layer) — under a frozen
/// ancestor EVERY media time converts to the frozen constant, so the delay is
/// annihilated at commit (verified: beginTime lands at exactly 0, animation
/// runs [0, duration]). We reintroduce it deterministically by shifting the
/// TARGET LAYER's own timeline: layer.beginTime = delay makes the layer's
/// local time = parentLocal - delay, so the animation (active [0, duration]
/// in layer-local time) is active [delay, delay + duration] on the seek
/// timeline, and UIKit's fillMode .both shows the FROM state during the
/// delay — same as real delayed playback. Constraint: this shifts the whole
/// layer, so multiple animation entries targeting the SAME view must share
/// one delay (enforced here; use different views otherwise).
func startAnimations(_ anims: [AnimationSpec], container: UIView, traits: UITraitCollection) {
    var delayByTarget: [String: TimeInterval] = [:]
    for a in anims {
        if a.kind == "switch-setOn" {
            guard let sw = viewAtPath(container, a.target) as? UISwitch else {
                fatalError("switch-setOn target '\(a.target)' is not a UISwitch")
            }
            sw.setOn(a.on, animated: true)
            continue
        }
        if let existing = delayByTarget[a.target], existing != a.delay {
            fatalError("animations targeting the same view ('\(a.target)') must share one delay")
        }
        delayByTarget[a.target] = a.delay
        let target = viewAtPath(container, a.target)
        let block = { applyAnimationChanges(target, a.changes, traits: traits) }
        if let damping = a.springDamping {
            UIView.animate(withDuration: a.duration, delay: a.delay,
                           usingSpringWithDamping: damping,
                           initialSpringVelocity: a.springVelocity,
                           options: [], animations: block)
        } else {
            UIView.animate(withDuration: a.duration, delay: a.delay,
                           options: [a.curve!], animations: block)
        }
        if a.delay > 0 {
            target.layer.beginTime = a.delay
            // Before its own beginTime a layer with default fillMode
            // "removed" is not displayed at all; .both makes it present its
            // local-time-0 state (= the animation's backwards-filled FROM
            // value) during the delay, matching real delayed playback.
            target.layer.fillMode = .both
        }
    }
}

/// Frame-file suffix for a capture time: milliseconds, >= 3 digits
/// (0.08 -> "t080", 1.0 -> "t1000").
func captureSuffix(_ t: TimeInterval) -> String {
    String(format: "t%03d", Int((t * 1000).rounded()))
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
    /// Scene spec v3: animations + capture times. Non-empty `animations`
    /// requires oracle2 (CA discards animations on layers with no render
    /// context, so the offscreen v1 path cannot capture them).
    let animations: [AnimationSpec]
    let captureTimes: [TimeInterval]
    /// Scene spec v4: hit-test probe points (root coordinates); results are
    /// appended to the layout dump as "hitTests".
    let hitTests: [CGPoint]
    /// Scene spec v4.3 (M9): top-level "constraints" array (raw JSON entries;
    /// nil when the key is absent). PRESENCE of the key — even as [] — exempts
    /// the scene from the root-frame quirk: the root gets its REAL frame
    /// [0, 0, w, h] so constraints against the root resolve correctly (and the
    /// root's backgroundColor draws). openrender must mirror both behaviors.
    let constraints: [JSON]?
    /// Scene spec v5 (M10): top-level "modal" — a presented pageSheet whose
    /// STATIC look (dimming, sheet chrome) is captured window-wide by
    /// oracle2. nil when absent. Requires "window": true; v1 refuses it.
    let modal: JSON?
    /// Scene spec v5.2 (M12): top-level "alert" — a presented
    /// UIAlertController captured window-wide. Same routing rule as "modal"
    /// (real iOS in the Simulator; Catalyst bridges alerts to AppKit panels).
    let alert: JSON?
}

/// Build the real `UIAlertController` a scene's `"alert"` object describes.
func buildAlert(_ j: JSON, style: UIUserInterfaceStyle) -> UIAlertController {
    let preferred: UIAlertController.Style =
        (j["style"] as? String ?? "alert") == "actionSheet" ? .actionSheet : .alert
    let ac = UIAlertController(title: j["title"] as? String,
                               message: j["message"] as? String,
                               preferredStyle: preferred)
    ac.overrideUserInterfaceStyle = style
    for ph in (j["textFields"] as? [String] ?? []) {
        ac.addTextField { $0.placeholder = ph }
    }
    var preferredAction: UIAlertAction?
    for entry in (j["actions"] as? [JSON] ?? []) {
        let s: UIAlertAction.Style
        switch entry["style"] as? String ?? "default" {
        case "cancel": s = .cancel
        case "destructive": s = .destructive
        case "default": s = .default
        default: fatalError("bad alert action style")
        }
        let a = UIAlertAction(title: entry["title"] as? String ?? "", style: s, handler: nil)
        if let enabled = entry["enabled"] as? Bool { a.isEnabled = enabled }
        ac.addAction(a)
        if (j["preferredAction"] as? String) == (entry["title"] as? String) {
            preferredAction = a
        }
    }
    if let p = preferredAction { ac.preferredAction = p }
    // NOTE: never touch `popoverPresentationController` — reading it flips an
    // iPhone action sheet into a popover presentation (and drops the cancel
    // action). Measured; see Sources/OpenUIKit/UIAlertController.swift.
    return ac
}

/// Root classes exempt from the root-frame quirk (spec v5): a 0-sized root
/// cannot host a controller view, so these get the REAL [0, 0, w, h] frame
/// (like constraint scenes). openrender must mirror.
let chromeRootClasses: Set<String> = ["UINavigationStack", "UITabBarStack"]

func loadScene(file: String) throws -> SceneSpec {
    let data = try Data(contentsOf: URL(fileURLWithPath: file))
    let scene = try JSONSerialization.jsonObject(with: data) as! JSON
    let name = scene["name"] as! String
    let sz = numArray(scene["size"])!
    let scale = num(scene["scale"]) ?? 2
    let style: UIUserInterfaceStyle = (scene["style"] as? String) == "dark" ? .dark : .light
    let animations = parseAnimations(scene)
    let captureTimes = (numArray(scene["captureTimes"]) ?? []).map { Double($0) }
    if !animations.isEmpty && captureTimes.isEmpty {
        fatalError("scene \(name): \"animations\" requires \"captureTimes\"")
    }
    if scene["constraints"] != nil && !(scene["constraints"] is [JSON]) {
        fatalError("scene \(name): \"constraints\" must be an array of objects")
    }
    let hitTests: [CGPoint] = (scene["hitTests"] as? [Any] ?? []).map {
        guard let a = numArray($0), a.count == 2 else {
            fatalError("scene \(name): bad hitTests entry (need [x, y])")
        }
        return CGPoint(x: a[0], y: a[1])
    }
    if let modal = scene["modal"] as? JSON {
        guard (modal["style"] as? String ?? "pageSheet") == "pageSheet" else {
            fatalError("scene \(name): modal style must be \"pageSheet\"")
        }
        guard modal["content"] is JSON else {
            fatalError("scene \(name): \"modal\" needs a \"content\" view object")
        }
        guard scene["window"] as? Bool == true else {
            fatalError("scene \(name): \"modal\" requires \"window\": true (oracle2)")
        }
    }
    if let alert = scene["alert"] as? JSON {
        let st = alert["style"] as? String ?? "alert"
        guard st == "alert" || st == "actionSheet" else {
            fatalError("scene \(name): alert style must be \"alert\" or \"actionSheet\"")
        }
        guard alert["actions"] is [JSON] else {
            fatalError("scene \(name): \"alert\" needs an \"actions\" array")
        }
        guard scene["window"] as? Bool == true else {
            fatalError("scene \(name): \"alert\" requires \"window\": true (SimScene)")
        }
        guard scene["modal"] == nil else {
            fatalError("scene \(name): \"alert\" and \"modal\" are mutually exclusive")
        }
    }
    return SceneSpec(name: name, width: sz[0], height: sz[1], scale: scale, style: style,
                     traits: UITraitCollection(userInterfaceStyle: style),
                     windowRequired: scene["window"] as? Bool == true,
                     rootJSON: scene["root"] as! JSON,
                     animations: animations, captureTimes: captureTimes,
                     hitTests: hitTests,
                     constraints: scene["constraints"] as? [JSON],
                     modal: scene["modal"] as? JSON,
                     alert: scene["alert"] as? JSON)
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
        //
        // EXCEPTION (spec v4.3): constraint scenes (top-level "constraints"
        // present) get the REAL root frame — constraints pinning to a
        // 0-sized root would be useless, and no pre-v4.3 golden has the key,
        // so nothing old is invalidated. Consequence: the root background
        // DRAWS in constraint scenes and their dumps have root frame
        // [0, 0, w, h]. openrender must mirror this.
        //
        // SECOND EXCEPTION (spec v5): chrome root classes (UINavigationStack,
        // UITabBarStack) — a 0-sized root cannot host the controller view
        // (its autoresizing would keep it 0-sized), so they too get the real
        // frame. Their dumps have root frame [0, 0, w, h].
        if spec.constraints != nil
            || chromeRootClasses.contains(spec.rootJSON["class"] as? String ?? "UIView") {
            rootJ["frame"] = [0.0, 0.0, Double(spec.width), Double(spec.height)]
        } else {
            rootJ["frame"] = [0, 0, spec.width, spec.height]
        }
        container = buildView(rootJ, scale: spec.scale, traits: spec.traits)
        if let cs = spec.constraints { activateConstraints(cs, container: container) }
        container.overrideUserInterfaceStyle = spec.style
        container.setNeedsLayout()
        container.layoutIfNeeded()
    }
    return container
}

func writeLayoutDump(_ container: UIView, spec: SceneSpec, outdir: String) throws {
    var views: [JSON] = []
    dumpLayout(container, path: "", into: &views)
    var layout: JSON = ["name": spec.name, "views": views]
    if !spec.hitTests.isEmpty {
        layout["hitTests"] = runHitTests(spec.hitTests, container: container,
                                         rootJSON: spec.rootJSON)
    }
    let layoutData = try JSONSerialization.data(withJSONObject: layout, options: [.prettyPrinted, .sortedKeys])
    try layoutData.write(to: URL(fileURLWithPath: "\(outdir)/\(spec.name).layout.json"))
}
