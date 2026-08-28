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

@MainActor
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
    if let e = j["userInteractionEnabled"]?.boolValue { v.isUserInteractionEnabled = e }
    // Auto Layout (spec v4.3 — M9), mirroring the oracle's applyCommon: a
    // view that participates in constraints opts out of the autoresizing-mask
    // translation (it may omit "frame" entirely).
    if j["useConstraints"]?.boolValue == true {
        v.translatesAutoresizingMaskIntoConstraints = false
    }
    // Forced safe area (spec v5.3). The oracle needs a UIView subclass that
    // overrides the getter (real UIKit has no setter); here it is one call.
    if let i = numArray(j["safeAreaInsets"]), i.count == 4 {
        v._setSafeAreaInsets(UIEdgeInsets(top: i[0], left: i[1],
                                          bottom: i[2], right: i[3]))
    }
    if let p = num(j["huggingH"]) {
        v.setContentHuggingPriority(UILayoutPriority(rawValue: Float(p)), for: .horizontal)
    }
    if let p = num(j["huggingV"]) {
        v.setContentHuggingPriority(UILayoutPriority(rawValue: Float(p)), for: .vertical)
    }
    if let p = num(j["compressionH"]) {
        v.setContentCompressionResistancePriority(UILayoutPriority(rawValue: Float(p)),
                                                  for: .horizontal)
    }
    if let p = num(j["compressionV"]) {
        v.setContentCompressionResistancePriority(UILayoutPriority(rawValue: Float(p)),
                                                  for: .vertical)
    }
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

@MainActor
func makeLabel(_ j: SceneJSON) -> UILabel {
    let l = UILabel()
    l.text = j["text"]?.stringValue
    l.font = fontFrom(j)
    if let c = colorOrDie(j["textColor"], "UILabel") { l.textColor = c }
    l.textAlignment = textAlignment(j["textAlignment"]?.stringValue)
    if let n = intValue(j["numberOfLines"]) { l.numberOfLines = n }
    l.lineBreakMode = lineBreakMode(j["lineBreakMode"]?.stringValue)
    // Attributed content last (it adopts the paragraph alignment / break mode).
    if let aj = j["attributedText"]?.objectValue {
        l.attributedText = attributedStringFrom(aj)
    }
    return l
}

// MARK: - Attributed text (scene spec v5.2 — M12; mirrors oracle SceneKit)

func underlineStyle(_ v: JSONValue?) -> Int? {
    if let b = v?.boolValue { return b ? NSUnderlineStyle.single.rawValue : 0 }
    guard let s = v?.stringValue else { return nil }
    switch s {
    case "none": return 0
    case "single": return NSUnderlineStyle.single.rawValue
    case "thick": return NSUnderlineStyle.thick.rawValue
    case "double": return NSUnderlineStyle.double.rawValue
    default: fatalError("bad underline style \(s)")
    }
}

func paragraphStyleFrom(_ j: SceneJSON) -> NSParagraphStyle {
    let p = NSMutableParagraphStyle()
    p.alignment = textAlignment(j["alignment"]?.stringValue)
    if let v = num(j["lineSpacing"]) { p.lineSpacing = v }
    if let v = num(j["paragraphSpacing"]) { p.paragraphSpacing = v }
    if let v = num(j["paragraphSpacingBefore"]) { p.paragraphSpacingBefore = v }
    if let v = num(j["lineHeightMultiple"]) { p.lineHeightMultiple = v }
    if let v = num(j["minimumLineHeight"]) { p.minimumLineHeight = v }
    if let v = num(j["maximumLineHeight"]) { p.maximumLineHeight = v }
    if let v = num(j["firstLineHeadIndent"]) { p.firstLineHeadIndent = v }
    if let v = num(j["headIndent"]) { p.headIndent = v }
    if let v = num(j["tailIndent"]) { p.tailIndent = v }
    p.lineBreakMode = lineBreakMode(j["lineBreakMode"]?.stringValue)
    return p
}

func attributedStringFrom(_ j: SceneJSON) -> NSAttributedString {
    guard let runs = j["runs"]?.arrayValue, !runs.isEmpty else {
        fatalError("attributedText needs a non-empty \"runs\" array")
    }
    let out = NSMutableAttributedString()
    for rv in runs {
        guard let r = rv.objectValue, let text = r["text"]?.stringValue else {
            fatalError("run needs \"text\"")
        }
        var a: [NSAttributedString.Key: Any] = [.font: fontFrom(r)]
        a[.foregroundColor] = colorOrDie(r["color"], "attributed run") ?? UIColor.label
        if let c = colorOrDie(r["backgroundColor"], "attributed run") { a[.backgroundColor] = c }
        if let v = num(r["kern"]) { a[.kern] = v }
        if let v = num(r["baselineOffset"]) { a[.baselineOffset] = v }
        if let u = underlineStyle(r["underline"]) { a[.underlineStyle] = u }
        if let u = underlineStyle(r["strikethrough"]) { a[.strikethroughStyle] = u }
        if let c = colorOrDie(r["underlineColor"], "attributed run") { a[.underlineColor] = c }
        if let c = colorOrDie(r["strikethroughColor"], "attributed run") {
            a[.strikethroughColor] = c
        }
        out.append(NSAttributedString(string: text, attributes: a))
    }
    if let pj = j["paragraph"]?.objectValue {
        out.addAttribute(.paragraphStyle, value: paragraphStyleFrom(pj),
                         range: NSRange(location: 0, length: out.length))
    }
    return out
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

@MainActor
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

@MainActor
func makeProgressView(_ j: SceneJSON) -> UIProgressView {
    let p = UIProgressView()
    if let v = num(j["progress"]) { p.progress = Float(v) }
    if let c = colorOrDie(j["progressTintColor"], "UIProgressView") { p.progressTintColor = c }
    if let c = colorOrDie(j["trackTintColor"], "UIProgressView") { p.trackTintColor = c }
    return p
}

@MainActor
func makeSlider(_ j: SceneJSON) -> UISlider {
    let s = UISlider()
    if let v = num(j["minimumValue"]) { s.minimumValue = Float(v) }
    if let v = num(j["maximumValue"]) { s.maximumValue = Float(v) }
    if let v = num(j["value"]) { s.value = Float(v) }
    if let c = colorOrDie(j["minimumTrackTintColor"], "UISlider") { s.minimumTrackTintColor = c }
    if let c = colorOrDie(j["maximumTrackTintColor"], "UISlider") { s.maximumTrackTintColor = c }
    if let c = colorOrDie(j["thumbTintColor"], "UISlider") { s.thumbTintColor = c }
    if j["enabled"]?.boolValue == false { s.isEnabled = false }
    return s
}

@MainActor
func makeSegmentedControl(_ j: SceneJSON) -> UISegmentedControl {
    let items = (j["segments"]?.arrayValue ?? []).compactMap { $0.stringValue }
    let s = UISegmentedControl(items: items)
    if let i = num(j["selectedSegmentIndex"]) { s.selectedSegmentIndex = Int(i) }
    if let c = colorOrDie(j["selectedSegmentTintColor"], "UISegmentedControl") {
        s.selectedSegmentTintColor = c
    }
    if j["enabled"]?.boolValue == false { s.isEnabled = false }
    return s
}

@MainActor
func makeActivityIndicator(_ j: SceneJSON) -> UIActivityIndicatorView {
    let style: UIActivityIndicatorView.Style
    switch j["style"]?.stringValue ?? "medium" {
    case "medium": style = .medium
    case "large": style = .large
    case let s: fatalError("bad activity indicator style \(s)")
    }
    let a = UIActivityIndicatorView(style: style)
    if let c = colorOrDie(j["color"], "UIActivityIndicatorView") { a.color = c }
    a.hidesWhenStopped = j["hidesWhenStopped"]?.boolValue ?? true
    if j["animating"]?.boolValue ?? true { a.startAnimating() }
    return a
}

@MainActor
func makePageControl(_ j: SceneJSON) -> UIPageControl {
    let p = UIPageControl()
    p.numberOfPages = Int(num(j["numberOfPages"]) ?? 3)
    p.currentPage = Int(num(j["currentPage"]) ?? 0)
    p.hidesForSinglePage = j["hidesForSinglePage"]?.boolValue ?? false
    if let c = colorOrDie(j["pageIndicatorTintColor"], "UIPageControl") {
        p.pageIndicatorTintColor = c
    }
    if let c = colorOrDie(j["currentPageIndicatorTintColor"], "UIPageControl") {
        p.currentPageIndicatorTintColor = c
    }
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

@MainActor
func makeStackView(_ j: SceneJSON) -> UIStackView {
    let s = UIStackView()
    s.axis = stackAxis(j["axis"]?.stringValue)
    if let sp = num(j["spacing"]) { s.spacing = sp }
    s.distribution = stackDistribution(j["stackDistribution"]?.stringValue)
    s.alignment = stackAlignment(j["stackAlignment"]?.stringValue)
    return s
}

@MainActor
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

@MainActor
func makeScrollView(_ j: SceneJSON) -> UIScrollView {
    let s = UIScrollView()
    if let cs = numArray(j["contentSize"]), cs.count == 2 {
        s.contentSize = CGSize(width: cs[0], height: cs[1])
    }
    if let ci = numArray(j["contentInset"]), ci.count == 4 {
        s.contentInset = UIEdgeInsets(top: ci[0], left: ci[1],
                                      bottom: ci[2], right: ci[3])
    }
    // Pull-to-refresh (spec v5.3), mirroring the oracle: install the control,
    // optionally start it, and clear `isHidden` explicitly (the oracle has to,
    // because offscreen UIKit never runs the reveal animation).
    if let rj = j["refreshControl"]?.objectValue {
        let rc = UIRefreshControl()
        s.refreshControl = rc
        if rj["refreshing"]?.boolValue == true { rc.beginRefreshing() }
        rc.isHidden = false
    }
    return s
}

/// Data source + delegate for a scene's `UIPickerView` (spec v5.3), mirroring
/// the oracle's `ScenePickerSource`. Retained in `retainedPickerSources`
/// because UIPickerView holds both weakly.
final class ScenePickerSource: UIPickerViewDataSource, UIPickerViewDelegate {
    let titles: [String]
    let rowHeight: CGFloat
    init(titles: [String], rowHeight: CGFloat) {
        self.titles = titles
        self.rowHeight = rowHeight
    }
    func numberOfComponents(in pickerView: UIPickerView) -> Int { 1 }
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        titles.count
    }
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int,
                    forComponent component: Int) -> String? { titles[row] }
    func pickerView(_ pickerView: UIPickerView,
                    rowHeightForComponent component: Int) -> CGFloat { rowHeight }
}
var retainedPickerSources: [ScenePickerSource] = []

@MainActor
func makePickerView(_ j: SceneJSON) -> UIPickerView {
    let p = UIPickerView()
    let titles = j["rows"]?.arrayValue?.compactMap { $0.stringValue } ?? []
    let src = ScenePickerSource(titles: titles, rowHeight: num(j["rowHeight"]) ?? 32)
    retainedPickerSources.append(src)
    p.dataSource = src
    p.delegate = src
    if let f = numArray(j["frame"]), f.count == 4 {
        p.frame = CGRect(x: f[0], y: f[1], width: f[2], height: f[3])
    }
    if let b = j["showsSelectionIndicator"]?.boolValue { p.showsSelectionIndicator = b }
    p.reloadAllComponents()
    if let r = num(j["selectedRow"]) { p.selectRow(Int(r), inComponent: 0, animated: false) }
    return p
}

@MainActor
func makeTextField(_ j: SceneJSON) -> UITextField {
    let t = UITextField()
    switch j["borderStyle"]?.stringValue ?? "none" {
    case "none": t.borderStyle = .none
    case "line": t.borderStyle = .line
    case "bezel": t.borderStyle = .bezel
    case "roundedRect": t.borderStyle = .roundedRect
    case let b: fatalError("bad borderStyle \(b)")
    }
    t.text = j["text"]?.stringValue
    t.placeholder = j["placeholder"]?.stringValue
    if j["fontSize"] != nil || j["fontWeight"] != nil { t.font = fontFrom(j) }
    if let c = colorOrDie(j["textColor"], "UITextField") { t.textColor = c }
    t.tintColor = t.tintColor.resolvedColor(with: UITraitCollection.current)
    if let aj = j["attributedText"]?.objectValue { t.attributedText = attributedStringFrom(aj) }
    return t
}

@MainActor
func makeTextView(_ j: SceneJSON) -> UITextView {
    let t = UITextView()
    t.text = j["text"]?.stringValue ?? ""
    t.font = fontFrom(j)   // spec: fontSize default 17, always applied
    if let c = colorOrDie(j["textColor"], "UITextView") { t.textColor = c }
    if let aj = j["attributedText"]?.objectValue { t.attributedText = attributedStringFrom(aj) }
    return t
}

@MainActor
func makeSwitch(_ j: SceneJSON) -> UISwitch {
    let s = UISwitch()
    s.isOn = j["on"]?.boolValue ?? false
    if let c = colorOrDie(j["onTintColor"], "UISwitch") { s.onTintColor = c }
    return s
}

@MainActor
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
    if j["highlighted"]?.boolValue == true { b.isHighlighted = true }
    return b
}

// MARK: - UITableView (spec v5 — M10 chrome)

/// In-scene UITableView data source/delegate built from the scene JSON's
/// "sections" (mirrors the oracle's SceneTableDriver: fresh cells, no
/// reuse — fully deterministic). Retained for the process lifetime because
/// UITableView holds dataSource/delegate weakly, like real UIKit.
var sceneTableDrivers: [SceneTableDriver] = []

final class SceneTableDriver: UITableViewDataSource, UITableViewDelegate {
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

    init(sectionsJSON: [JSONValue]) {
        sections = sectionsJSON.map { sv in
            guard let s = sv.objectValue else { fatalError("bad table section") }
            let rows = (s["rows"]?.arrayValue ?? []).map { rv -> Row in
                guard let r = rv.objectValue else { fatalError("bad table row") }
                let style: UITableViewCell.CellStyle
                switch r["style"]?.stringValue ?? "default" {
                case "default": style = .default
                case "subtitle": style = .subtitle
                case "value1": style = .value1
                case let x: fatalError("bad cell style '\(x)'")
                }
                let accessory: UITableViewCell.AccessoryType
                switch r["accessory"]?.stringValue ?? "none" {
                case "none": accessory = .none
                case "disclosureIndicator": accessory = .disclosureIndicator
                case "checkmark": accessory = .checkmark
                case let x: fatalError("bad accessory '\(x)'")
                }
                return Row(style: style, text: r["text"]?.stringValue ?? "",
                           detailText: r["detailText"]?.stringValue,
                           accessory: accessory,
                           selected: r["selected"]?.boolValue == true)
            }
            return Section(header: s["header"]?.stringValue,
                           footer: s["footer"]?.stringValue, rows: rows)
        }
    }

    func numberOfSections(in tableView: UITableView) -> Int { sections.count }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        sections[section].rows.count
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = sections[indexPath.section].rows[indexPath.row]
        // Fresh cell every time — no reuse, fully deterministic (the oracle
        // driver does the same; reuse is exercised by the unit tests).
        let cell = UITableViewCell(style: row.style, reuseIdentifier: nil)
        cell.textLabel.text = row.text
        cell.detailTextLabel?.text = row.detailText
        cell.accessoryType = row.accessory
        return cell
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        sections[section].header
    }

    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        sections[section].footer
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        // The real UIKit oracle self-sizes; the measured subtitle cell is
        // taller than the default (portable self-sizing is out of scope —
        // docs/KNOWN_GAPS.md).
        sections[indexPath.section].rows[indexPath.row].style == .subtitle
            ? UITableViewCell.subtitleRowHeight
            : UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell,
                   forRowAt indexPath: IndexPath) {
        // Static scene: a "selected": true row shows the selection highlight.
        if sections[indexPath.section].rows[indexPath.row].selected {
            cell.setSelected(true, animated: false)
        }
    }
}

@MainActor
func makeTableView(_ j: SceneJSON) -> UITableView {
    let style: UITableView.Style
    switch j["style"]?.stringValue ?? "plain" {
    case "plain": style = .plain
    case "insetGrouped": style = .insetGrouped
    case let s: fatalError("bad table style '\(s)'")
    }
    let t = UITableView(frame: .zero, style: style)
    // Mirror the oracle's pinning: no indicator subviews in static scenes.
    t.showsVerticalScrollIndicator = false
    t.showsHorizontalScrollIndicator = false
    // Window scenes (oracle2, real UIWindow) carry real-device inset-grouped
    // metrics: the card side margin measures 16 pt there vs 8 pt in the
    // offscreen Catalyst oracle (see UITableView.insetGroupedSideInset).
    // runScene has already latched the scene's "window" flag here.
    if GlyphInkTable.windowCompositing {
        t.insetGroupedSideInset = 16
    }
    let driver = SceneTableDriver(sectionsJSON: j["sections"]?.arrayValue ?? [])
    sceneTableDrivers.append(driver)   // dataSource/delegate are weak
    t.dataSource = driver
    t.delegate = driver
    return t
}

// MARK: - UICollectionView (spec v5.3 — M13 collection module)

/// In-scene UICollectionView data source/delegate built from the scene JSON's
/// "sections" (mirrors the oracle's SceneCollectionDriver exactly). Retained
/// for the process lifetime because UICollectionView holds its
/// dataSource/delegate weakly, like real UIKit.
var sceneCollectionDrivers: [SceneCollectionDriver] = []

/// Scene cell: a colored, optionally rounded content view with one centered
/// label filling it (identical to the oracle's SceneCollectionCell).
final class SceneCollectionCell: UICollectionViewCell {
    let label = UILabel()
    required init(frame: CGRect = .zero) {
        super.init(frame: frame)
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 17)
        contentView.addSubview(label)
    }
    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }
    override func layoutSubviews() {
        super.layoutSubviews()
        label.frame = contentView.bounds
    }
}

/// Scene supplementary view: one 13 pt semibold label, inset 16 pt, filling
/// the height (so it centers vertically).
final class SceneCollectionSupplementary: UICollectionReusableView {
    let label = UILabel()
    required init(frame: CGRect = .zero) {
        super.init(frame: frame)
        label.font = .systemFont(ofSize: 13, weight: .semibold)
        label.textColor = .secondaryLabel
        addSubview(label)
    }
    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }
    override func layoutSubviews() {
        super.layoutSubviews()
        label.frame = CGRect(x: 16, y: 0, width: max(0, bounds.width - 32),
                             height: bounds.height)
    }
}

final class SceneCollectionDriver: UICollectionViewDataSource,
                                   UICollectionViewDelegateFlowLayout {
    struct Item {
        let text: String
        let color: UIColor?
        let textColor: UIColor?
        let size: CGSize?
    }
    struct Section {
        let header: String?
        let footer: String?
        let items: [Item]
    }
    let sections: [Section]
    let cornerRadius: CGFloat

    init(sectionsJSON: [JSONValue], cornerRadius: CGFloat) {
        self.cornerRadius = cornerRadius
        sections = sectionsJSON.map { sv in
            guard let s = sv.objectValue else { fatalError("bad collection section") }
            let items = (s["items"]?.arrayValue ?? []).map { iv -> Item in
                guard let i = iv.objectValue else { fatalError("bad collection item") }
                let size = numArray(i["size"]).flatMap {
                    $0.count == 2 ? CGSize(width: $0[0], height: $0[1]) : nil
                }
                return Item(text: i["text"]?.stringValue ?? "",
                            color: colorOrDie(i["color"], "collection item"),
                            textColor: colorOrDie(i["textColor"], "collection item"),
                            size: size)
            }
            return Section(header: s["header"]?.stringValue,
                           footer: s["footer"]?.stringValue, items: items)
        }
    }

    func numberOfSections(in cv: UICollectionView) -> Int { sections.count }

    func collectionView(_ cv: UICollectionView, numberOfItemsInSection s: Int) -> Int {
        sections[s].items.count
    }

    func collectionView(_ cv: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let item = sections[indexPath.section].items[indexPath.item]
        let cell = cv.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath)
            as! SceneCollectionCell
        cell.contentView.backgroundColor = item.color
        cell.contentView.layer.cornerRadius = cornerRadius
        cell.label.text = item.text
        cell.label.textColor = item.textColor ?? .label
        return cell
    }

    func collectionView(_ cv: UICollectionView, viewForSupplementaryElementOfKind kind: String,
                        at indexPath: IndexPath) -> UICollectionReusableView {
        let view = cv.dequeueReusableSupplementaryView(ofKind: kind,
                                                       withReuseIdentifier: "supp",
                                                       for: indexPath)
            as! SceneCollectionSupplementary
        view.label.text = kind == UICollectionView.elementKindSectionHeader
            ? sections[indexPath.section].header : sections[indexPath.section].footer
        return view
    }

    func collectionView(_ cv: UICollectionView, layout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        sections[indexPath.section].items[indexPath.item].size
            ?? (layout as! UICollectionViewFlowLayout).itemSize
    }

    func collectionView(_ cv: UICollectionView, layout: UICollectionViewLayout,
                        referenceSizeForHeaderInSection s: Int) -> CGSize {
        sections[s].header == nil
            ? .zero : (layout as! UICollectionViewFlowLayout).headerReferenceSize
    }

    func collectionView(_ cv: UICollectionView, layout: UICollectionViewLayout,
                        referenceSizeForFooterInSection s: Int) -> CGSize {
        sections[s].footer == nil
            ? .zero : (layout as! UICollectionViewFlowLayout).footerReferenceSize
    }
}

@MainActor
func makeCollectionView(_ j: SceneJSON) -> UICollectionView {
    let layout = UICollectionViewFlowLayout()
    switch j["scrollDirection"]?.stringValue ?? "vertical" {
    case "vertical": layout.scrollDirection = .vertical
    case "horizontal": layout.scrollDirection = .horizontal
    case let s: fatalError("bad scrollDirection '\(s)'")
    }
    if let sz = numArray(j["itemSize"]), sz.count == 2 {
        layout.itemSize = CGSize(width: sz[0], height: sz[1])
    }
    if let n = num(j["minimumLineSpacing"]) { layout.minimumLineSpacing = n }
    if let n = num(j["minimumInteritemSpacing"]) { layout.minimumInteritemSpacing = n }
    if let ins = numArray(j["sectionInset"]), ins.count == 4 {
        layout.sectionInset = UIEdgeInsets(top: ins[0], left: ins[1],
                                           bottom: ins[2], right: ins[3])
    }
    if let sz = numArray(j["headerSize"]), sz.count == 2 {
        layout.headerReferenceSize = CGSize(width: sz[0], height: sz[1])
    }
    if let sz = numArray(j["footerSize"]), sz.count == 2 {
        layout.footerReferenceSize = CGSize(width: sz[0], height: sz[1])
    }
    let c = UICollectionView(frame: .zero, collectionViewLayout: layout)
    // Mirror the oracle's pinning: no indicator subviews in static scenes.
    c.showsVerticalScrollIndicator = false
    c.showsHorizontalScrollIndicator = false
    c.register(SceneCollectionCell.self, forCellWithReuseIdentifier: "cell")
    for kind in [UICollectionView.elementKindSectionHeader,
                 UICollectionView.elementKindSectionFooter] {
        c.register(SceneCollectionSupplementary.self, forSupplementaryViewOfKind: kind,
                   withReuseIdentifier: "supp")
    }
    let driver = SceneCollectionDriver(sectionsJSON: j["sections"]?.arrayValue ?? [],
                                       cornerRadius: num(j["itemCornerRadius"]) ?? 0)
    sceneCollectionDrivers.append(driver)   // dataSource/delegate are weak
    c.dataSource = driver
    c.delegate = driver
    return c
}

/// Classes the scene spec defines but OpenUIKit does not implement yet.
/// They are instantiated as plain UIView (with common props) so geometry
/// scenes still run; the compare step fails for these scenes until the
/// owning modules land. Adding a real class later = one `case` line below.
// Spec v5 (M10 chrome): goldens exist, OpenUIKit implementations pending.
// Substituting a plain UIView keeps `openrender render fixtures/scenes/*`
// running end-to-end (the scenes FAIL compare until implemented, they just
// don't abort the batch).
let notYetImplementedClasses: Set<String> = []

// MARK: - Chrome containers (scene spec v5 — M10, viewcontroller module)

/// Root-only wrapper classes matching the oracle's container naming (the
/// layout dump compares the wrapper's own frame; the controller tree below
/// is private on both sides). See docs/SCENE_SPEC.md "UINavigationStack" /
/// "UITabBarStack".
final class UINavigationStack: UIView {}
final class UITabBarStack: UIView {}

let chromeRootClasses: Set<String> = ["UINavigationStack", "UITabBarStack"]

// MARK: - Bar button items / bar appearance (scene spec v5.3 — M13)

let barSystemItems: [String: UIBarButtonItem.SystemItem] = [
    "done": .done, "cancel": .cancel, "edit": .edit, "save": .save,
    "add": .add, "close": .close, "trash": .trash, "action": .action,
    "refresh": .refresh, "reply": .reply, "compose": .compose,
    "organize": .organize, "bookmarks": .bookmarks, "search": .search,
    "camera": .camera, "undo": .undo, "redo": .redo,
    "flexibleSpace": .flexibleSpace, "fixedSpace": .fixedSpace,
]

@MainActor
func makeBarButtonItem(_ j: SceneJSON, scale: CGFloat,
                       warn: (String) -> Void) -> UIBarButtonItem {
    let style: UIBarButtonItem.Style =
        j["style"]?.stringValue == "done" ? .done : .plain
    let item: UIBarButtonItem
    if let sys = j["systemItem"]?.stringValue {
        guard let s = barSystemItems[sys] else {
            fatalError("bad barButtonSystemItem '\(sys)'")
        }
        item = UIBarButtonItem(barButtonSystemItem: s)
    } else if let cv = j["customView"]?.objectValue {
        item = UIBarButtonItem(customView: buildView(cv, scale: scale, warn: warn))
    } else if let ij = j["image"]?.objectValue {
        item = UIBarButtonItem(image: makeImage(ij, scale: scale), style: style)
    } else {
        item = UIBarButtonItem(title: j["title"]?.stringValue ?? "", style: style)
    }
    if let w = num(j["width"]) { item.width = w }
    if let e = j["enabled"]?.boolValue { item.isEnabled = e }
    if let c = colorOrDie(j["tintColor"], "UIBarButtonItem") { item.tintColor = c }
    return item
}

@MainActor
func makeBarItems(_ v: JSONValue?, scale: CGFloat,
                  warn: (String) -> Void) -> [UIBarButtonItem]? {
    guard let arr = v?.arrayValue else { return nil }
    return arr.map { entry in
        guard let o = entry.objectValue else { fatalError("bad bar item entry") }
        return makeBarButtonItem(o, scale: scale, warn: warn)
    }
}

@MainActor
func applyBarAppearance<A: UIBarAppearance>(_ j: SceneJSON, to a: A) {
    switch j["configuration"]?.stringValue ?? "default" {
    case "default": a.configureWithDefaultBackground()
    case "opaque": a.configureWithOpaqueBackground()
    case "transparent": a.configureWithTransparentBackground()
    case let c: fatalError("bad appearance configuration '\(c)'")
    }
    if let c = colorOrDie(j["backgroundColor"], "appearance") { a.backgroundColor = c }
    if let sc = j["shadowColor"] {
        if case .null = sc { a.shadowColor = nil }
        else if let c = colorOrDie(sc, "appearance") { a.shadowColor = c }
    }
    if let nav = a as? UINavigationBarAppearance {
        if let t = j["titleTextAttributes"]?.objectValue {
            nav.titleTextAttributes = barTitleAttributes(t)
        }
        if let t = j["largeTitleTextAttributes"]?.objectValue {
            nav.largeTitleTextAttributes = barTitleAttributes(t)
        }
    }
}

@MainActor
func makeBarAppearance<A: UIBarAppearance>(_ j: SceneJSON, _ kind: A.Type) -> A {
    let a = A()
    applyBarAppearance(j, to: a)
    return a
}

func barTitleAttributes(_ j: SceneJSON) -> UIBarTitleTextAttributes {
    var attrs = UIBarTitleTextAttributes()
    attrs.foregroundColor = colorOrDie(j["color"], "titleTextAttributes")
    if j["fontSize"] != nil || j["fontWeight"] != nil
        || j["italic"] != nil || j["monospaced"] != nil {
        attrs.font = fontFrom(j)
    }
    return attrs
}

@MainActor
func makeToolbar(_ j: SceneJSON, scale: CGFloat, warn: (String) -> Void) -> UIToolbar {
    let t = UIToolbar()
    t.items = makeBarItems(j["items"], scale: scale, warn: warn)
    if let c = colorOrDie(j["barTintColor"], "UIToolbar") { t.barTintColor = c }
    if let c = colorOrDie(j["tintColor"], "UIToolbar") { t.tintColor = c }
    if let tr = j["translucent"]?.boolValue { t.isTranslucent = tr }
    if let aj = j["appearance"]?.objectValue {
        t.standardAppearance = makeBarAppearance(aj, UIToolbarAppearance.self)
    }
    return t
}

/// Controllers built for the current scene must outlive the JSON walk
/// (views do not retain their controllers). Lives for the process — same
/// pattern as the oracle's sceneTableDrivers.
var sceneRetainedControllers: [UIViewController] = []

/// Build the UINavigationStack scene root: a real UINavigationController
/// (one content VC hosting a full-size scroll view with the scene subviews
/// as content), mirroring the oracle's construction. `contentOffset` is
/// applied LIVE after the tree is laid out (the bar tracks observed
/// offsets) — see applyPendingChromeActions, called from runScene.
@MainActor
func makeNavigationStack(_ j: SceneJSON, scale: CGFloat,
                         warn: (String) -> Void) -> UIView {
    let stack = UINavigationStack()
    let contentVC = UIViewController()
    contentVC.view.backgroundColor =
        colorOrDie(j["backgroundColor"], "UINavigationStack") ?? .systemBackground
    contentVC.title = j["title"]?.stringValue
    // Bar button items / title view / prompt (spec v5.3).
    contentVC.navigationItem.leftBarButtonItems =
        makeBarItems(j["leftItems"], scale: scale, warn: warn)
    contentVC.navigationItem.rightBarButtonItems =
        makeBarItems(j["rightItems"], scale: scale, warn: warn)
    if let tv = j["titleView"]?.objectValue {
        contentVC.navigationItem.titleView = buildView(tv, scale: scale, warn: warn)
    }
    contentVC.navigationItem.prompt = j["prompt"]?.stringValue
    let scroll = UIScrollView(frame: contentVC.view.bounds)
    scroll.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    scroll.showsVerticalScrollIndicator = false
    scroll.showsHorizontalScrollIndicator = false
    if let cs = numArray(j["contentSize"]), cs.count == 2 {
        scroll.contentSize = CGSize(width: cs[0], height: cs[1])
    }
    for sub in j["subviews"]?.arrayValue ?? [] {
        guard let subJ = sub.objectValue else { fatalError("bad subview in UINavigationStack") }
        scroll.addSubview(buildView(subJ, scale: scale, warn: warn))
    }
    contentVC.view.addSubview(scroll)
    contentVC.setContentScrollView(scroll)
    if let ti = makeBarItems(j["toolbarItems"], scale: scale, warn: warn) {
        contentVC.toolbarItems = ti
    }
    let nav = UINavigationController(rootViewController: contentVC)
    nav.navigationBar.prefersLargeTitles = j["largeTitle"]?.boolValue == true
    if let c = colorOrDie(j["tintColor"], "UINavigationStack") {
        nav.navigationBar.tintColor = c
    }
    if let aj = j["appearance"]?.objectValue {
        let a = makeBarAppearance(aj, UINavigationBarAppearance.self)
        nav.navigationBar.standardAppearance = a
        nav.navigationBar.scrollEdgeAppearance = a
        nav.navigationBar.compactAppearance = a
    }
    if let aj = j["scrollEdgeAppearance"]?.objectValue {
        nav.navigationBar.scrollEdgeAppearance =
            makeBarAppearance(aj, UINavigationBarAppearance.self)
    }
    if contentVC.toolbarItems != nil {
        nav.isToolbarHidden = false
        if let c = colorOrDie(j["toolbarTintColor"], "UINavigationStack") {
            nav.toolbar.tintColor = c
        }
        if let aj = j["toolbarAppearance"]?.objectValue {
            nav.toolbar.standardAppearance = makeBarAppearance(aj, UIToolbarAppearance.self)
        }
    }
    nav.view.frame = stack.bounds
    nav.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    stack.addSubview(nav.view)
    sceneRetainedControllers.append(nav)
    // Offsets only after the real frames exist (mirrors the oracle's
    // post-attach application; the bar recomputes for observed offsets).
    if let co = numArray(j["contentOffset"]), co.count == 2 {
        pendingChromeActions.append {
            scroll.contentOffset = CGPoint(x: co[0], y: co[1])
        }
    }
    return stack
}

/// Deferred chrome setup (live offset application) run by runScene after
/// the initial layout pass.
var pendingChromeActions: [() -> Void] = []

func applyPendingChromeActions() {
    let actions = pendingChromeActions
    pendingChromeActions = []
    for a in actions { a() }
}

/// Build the UITabBarStack scene root: a real UITabBarController whose
/// items get titles + synthesized template images; the selected item's
/// "content" view fills that tab's controller view.
@MainActor
func makeTabBarStack(_ j: SceneJSON, scale: CGFloat,
                     warn: (String) -> Void) -> UIView {
    let stack = UITabBarStack()
    let tab = UITabBarController()
    var vcs: [UIViewController] = []
    for (i, itemJSON) in (j["items"]?.arrayValue ?? []).enumerated() {
        guard let item = itemJSON.objectValue else {
            fatalError("UITabBarStack: bad items entry")
        }
        let vc = UIViewController()
        vc.view.backgroundColor = .systemBackground
        if let content = item["content"]?.objectValue {
            vc.view.addSubview(buildView(content, scale: scale, warn: warn))
        }
        var img: UIImage? = nil
        if let ij = item["image"]?.objectValue { img = makeImage(ij, scale: scale) }
        vc.tabBarItem = UITabBarItem(title: item["title"]?.stringValue,
                                     image: img, tag: i)
        vcs.append(vc)
    }
    tab.viewControllers = vcs
    if let idx = intValue(j["selectedIndex"]) { tab.selectedIndex = idx }
    if let c = colorOrDie(j["tintColor"], "UITabBarStack") { tab.tabBar.tintColor = c }
    tab.view.frame = stack.bounds
    tab.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    stack.addSubview(tab.view)
    sceneRetainedControllers.append(tab)
    return stack
}

@MainActor
func buildView(_ input: SceneJSON, scale: CGFloat, warn: (String) -> Void) -> UIView {
    var j = input
    let cls = j["class"]?.stringValue ?? "UIView"
    // Spec v5.3: a nav stack's "backgroundColor" belongs to the hosted
    // content view controller, not to the wrapper (mirrors the oracle, which
    // nils the key out for the same reason).
    if cls == "UINavigationStack" { j["backgroundColor"] = nil }
    let v: UIView
    switch cls {
    case "UIView": v = UIView()
    case "UILabel": v = makeLabel(j)
    case "UIImageView": v = makeImageView(j, scale: scale)
    case "UIProgressView": v = makeProgressView(j)
    case "UIStackView": v = makeStackView(j)
    case "UISwitch": v = makeSwitch(j)
    case "UISlider": v = makeSlider(j)
    case "UISegmentedControl": v = makeSegmentedControl(j)
    case "UIActivityIndicatorView": v = makeActivityIndicator(j)
    case "UIPageControl": v = makePageControl(j)
    case "UIButton": v = makeButton(j)
    case "UIGradientView": v = makeGradientView(j)
    case "UIScrollView": v = makeScrollView(j)
    case "UIPickerView": v = makePickerView(j)
    case "UITableView": v = makeTableView(j)
    case "UICollectionView": v = makeCollectionView(j)
    case "UITextField": v = makeTextField(j)
    case "UITextView": v = makeTextView(j)
    case "UINavigationStack": v = makeNavigationStack(input, scale: scale, warn: warn)
    case "UITabBarStack": v = makeTabBarStack(j, scale: scale, warn: warn)
    case "UIToolbar": v = makeToolbar(j, scale: scale, warn: warn)
    case _ where notYetImplementedClasses.contains(cls):
        warn("openrender: warning: class '\(cls)' not implemented yet; substituting plain UIView")
        v = UIView()
    default:
        fatalError("unsupported class \(cls)")
    }

    applyCommon(v, j, name: cls)

    // Chrome containers consume "subviews" themselves (they live in the
    // controller's content scroll view, not on the wrapper).
    if let subs = j["subviews"]?.arrayValue, !(v is UINavigationStack),
       !(v is UITabBarStack) {
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
    // Scroll position applies AFTER the frame and children exist (mirrors
    // the oracle; setting it earlier is fine for OpenUIKit but real UIKit
    // can re-clamp an offset set on a zero-sized scroll view).
    if let sv = v as? UIScrollView, let co = numArray(j["contentOffset"]),
       co.count == 2 {
        sv.contentOffset = CGPoint(x: co[0], y: co[1])
    }
    if let t = numArray(j["transform"]), t.count == 6 {
        v.transform = CGAffineTransform(a: t[0], b: t[1], c: t[2], d: t[3], tx: t[4], ty: t[5])
    }
    return v
}

// MARK: - Hit tests (scene spec v4, mirror oracle's runHitTests)

/// Scene-defined views (built from the JSON) -> dot-joined subview-index
/// path. Private implementation subviews (UIButtonLabel, ...) stay out of
/// the registry; hit results normalize to the nearest scene-defined
/// ancestor — identical rule to the oracle.
@MainActor
func sceneViewRegistry(_ v: UIView, _ j: SceneJSON, path: String,
                       into out: inout [ObjectIdentifier: String]) {
    out[ObjectIdentifier(v)] = path
    let subs = j["subviews"]?.arrayValue ?? []
    for (i, sub) in subs.enumerated() {
        guard i < v.subviews.count, let subJ = sub.objectValue else { break }
        sceneViewRegistry(v.subviews[i], subJ,
                          path: path.isEmpty ? "\(i)" : "\(path).\(i)", into: &out)
    }
}

/// Mirror of the oracle's hit-test driver: the degenerate 0x0 root is
/// bypassed by running UIKit's hit-test recursion step at the root
/// (reverse subview order, converted point, first hit wins), so the root
/// itself is never a hit result.
@MainActor
func runHitTests(_ points: [CGPoint], container: UIView,
                 rootJSON: SceneJSON) -> [JSONValue] {
    var registry: [ObjectIdentifier: String] = [:]
    sceneViewRegistry(container, rootJSON, path: "", into: &registry)
    var out: [JSONValue] = []
    for p in points {
        var hit: UIView? = nil
        for sub in container.subviews.reversed() {
            if let h = sub.hitTest(sub.convert(p, from: container), with: nil) {
                hit = h
                break
            }
        }
        var norm = hit
        while let v = norm, registry[ObjectIdentifier(v)] == nil { norm = v.superview }
        var entry: [String: JSONValue] = [
            "point": .array([.number(round3(p.x)), .number(round3(p.y))]),
        ]
        if let path = norm.flatMap({ registry[ObjectIdentifier($0)] }) {
            entry["path"] = .string(path)
        } else {
            entry["path"] = .null
        }
        out.append(.object(entry))
    }
    return out
}

// MARK: - Animations (scene spec v3, mirror oracle's parseAnimations)

struct SceneAnimation {
    let kind: String              // "uiview-animate" | "switch-setOn"
    let target: String            // dot-joined subview-index path ("" = root)
    let duration: Double
    let delay: Double
    /// nil when spring is set.
    let curve: UIView.AnimationOptions?
    let springDamping: CGFloat?   // non-nil => spring animation
    let springVelocity: CGFloat
    let changes: SceneJSON
    let on: Bool                  // switch-setOn only
}

func parseAnimations(_ scene: JSONValue) -> [SceneAnimation] {
    guard let arr = scene["animations"]?.arrayValue else { return [] }
    return arr.map { entry in
        guard let j = entry.objectValue else { fatalError("bad animation entry") }
        let kind = j["kind"]?.stringValue ?? "uiview-animate"
        switch kind {
        case "uiview-animate":
            var curve: UIView.AnimationOptions? = nil
            var damping: CGFloat? = nil
            var velocity: CGFloat = 0
            if let s = j["spring"]?.objectValue {
                damping = num(s["damping"]) ?? 1
                velocity = num(s["initialVelocity"]) ?? 0
            } else {
                switch j["curve"]?.stringValue ?? "easeInOut" {
                case "linear": curve = .curveLinear
                case "easeIn": curve = .curveEaseIn
                case "easeOut": curve = .curveEaseOut
                case "easeInOut": curve = .curveEaseInOut
                case let c: fatalError("bad animation curve '\(c)'")
                }
            }
            guard let changes = j["changes"]?.objectValue, !changes.isEmpty else {
                fatalError("animation needs non-empty \"changes\"")
            }
            return SceneAnimation(kind: kind, target: j["target"]?.stringValue ?? "",
                                  duration: Double(num(j["duration"]) ?? 0.25),
                                  delay: Double(num(j["delay"]) ?? 0),
                                  curve: curve, springDamping: damping,
                                  springVelocity: velocity, changes: changes,
                                  on: false)
        case "switch-setOn":
            guard let on = j["on"]?.boolValue else {
                fatalError("switch-setOn needs \"on\": true|false")
            }
            return SceneAnimation(kind: kind, target: j["target"]?.stringValue ?? "",
                                  duration: 0, delay: 0, curve: nil,
                                  springDamping: nil, springVelocity: 0,
                                  changes: [:], on: on)
        default:
            fatalError("bad animation kind '\(kind)'")
        }
    }
}

/// Resolve a dot-joined subview-index path ("" = root) against the built tree.
@MainActor
func viewAtPath(_ root: UIView, _ path: String) -> UIView {
    var v = root
    guard !path.isEmpty else { return v }
    for comp in path.split(separator: ".") {
        guard let i = Int(comp), i >= 0, i < v.subviews.count else {
            fatalError("bad animation target path '\(path)'")
        }
        v = v.subviews[i]
    }
    return v
}

/// Apply one animation entry's `changes` to the target view. Called INSIDE
/// the UIView.animate block. Mirrors the oracle's applyAnimationChanges.
@MainActor
func applyAnimationChanges(_ v: UIView, _ changes: SceneJSON) {
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
            v.backgroundColor = colorOrDie(value, "animation changes")
        case "transform":
            let t = numArray(value)!
            v.transform = CGAffineTransform(a: t[0], b: t[1], c: t[2], d: t[3],
                                            tx: t[4], ty: t[5])
        case "cornerRadius":
            v.layer.cornerRadius = num(value)!
        default:
            fatalError("unsupported animated property '\(key)'")
        }
    }
}

/// Kick off every animation entry with UIView.animate. Unlike the oracle
/// (which must shift layer timelines under a frozen CA clock), the engine
/// handles per-animation delay natively, so this is a direct translation.
@MainActor
func startAnimations(_ anims: [SceneAnimation], container: UIView) {
    for a in anims {
        let target = viewAtPath(container, a.target)
        if a.kind == "switch-setOn" {
            guard let sw = target as? UISwitch else {
                fatalError("switch-setOn target '\(a.target)' is not a UISwitch")
            }
            sw.setOn(a.on, animated: true)
            continue
        }
        if let damping = a.springDamping {
            UIView.animate(withDuration: a.duration, delay: a.delay,
                           usingSpringWithDamping: damping,
                           initialSpringVelocity: a.springVelocity,
                           options: []) {
                applyAnimationChanges(target, a.changes)
            }
        } else {
            UIView.animate(withDuration: a.duration, delay: a.delay,
                           options: [a.curve!]) {
                applyAnimationChanges(target, a.changes)
            }
        }
    }
}

/// Frame-file suffix for a capture time: milliseconds, >= 3 digits
/// (0.08 -> "t080", 1.0 -> "t1000"). Mirrors the oracle's captureSuffix.
func captureSuffix(_ t: Double) -> String {
    var ms = "\(Int((t * 1000).rounded()))"
    while ms.count < 3 { ms = "0" + ms }
    return "t" + ms
}

// MARK: - Constraints (scene spec v4.3 — M9, mirror oracle's activateConstraints)

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
    case "leftMargin": return .leftMargin
    case "rightMargin": return .rightMargin
    case "topMargin": return .topMargin
    case "bottomMargin": return .bottomMargin
    case "leadingMargin": return .leadingMargin
    case "trailingMargin": return .trailingMargin
    case "centerXWithinMargins": return .centerXWithinMargins
    case "centerYWithinMargins": return .centerYWithinMargins
    default: fatalError("bad constraint attribute '\(s)'")
    }
}

/// The constrained object at a scene path: the view itself, or one of its
/// layout guides when the constraint carries a "guide"/"toGuide" key
/// (spec v5.3). Mirrors Tools/oracle/SceneKit.swift's `layoutItem`.
@MainActor
func layoutItem(_ container: UIView, _ path: String, _ guide: String?) -> AnyObject {
    let v = viewAtPath(container, path)
    switch guide {
    case nil: return v
    case "safeArea": return v.safeAreaLayoutGuide
    case "layoutMargins": return v.layoutMarginsGuide
    case "readableContent": return v.readableContentGuide
    case let g?: fatalError("bad guide '\(g)' (safeArea|layoutMargins|readableContent)")
    }
}

/// Build and activate NSLayoutConstraints from the scene's top-level
/// "constraints" array. Item paths use layout-dump addressing ("" = root).
/// Runs after the tree is built and BEFORE layoutIfNeeded; priorities are
/// set pre-activation (mirrors Tools/oracle/SceneKit.swift).
@MainActor
func activateConstraints(_ specs: [JSONValue], container: UIView) {
    var built: [NSLayoutConstraint] = []
    for entry in specs {
        guard let j = entry.objectValue else { fatalError("bad constraint entry") }
        guard let itemPath = j["item"]?.stringValue else {
            fatalError("constraint needs \"item\" (view path, \"\" = root)")
        }
        guard let attrName = j["attribute"]?.stringValue else {
            fatalError("constraint needs \"attribute\"")
        }
        let item = layoutItem(container, itemPath, j["guide"]?.stringValue)
        let relation: NSLayoutConstraint.Relation
        switch j["relation"]?.stringValue ?? "eq" {
        case "eq": relation = .equal
        case "le": relation = .lessThanOrEqual
        case "ge": relation = .greaterThanOrEqual
        case let r: fatalError("bad constraint relation '\(r)'")
        }
        var toView: AnyObject? = nil
        var toAttr: NSLayoutConstraint.Attribute = .notAnAttribute
        if let tp = j["toItem"]?.stringValue {   // JSON null is not a string
            toView = layoutItem(container, tp, j["toGuide"]?.stringValue)
            // toAttribute defaults to the first attribute (the common case:
            // pinning like to like).
            toAttr = layoutAttribute(j["toAttribute"]?.stringValue ?? attrName)
        } else if j["toAttribute"]?.stringValue != nil {
            fatalError("constraint has \"toAttribute\" but no \"toItem\"")
        }
        let c = NSLayoutConstraint(item: item, attribute: layoutAttribute(attrName),
                                   relatedBy: relation, toItem: toView, attribute: toAttr,
                                   multiplier: num(j["multiplier"]) ?? 1,
                                   constant: num(j["constant"]) ?? 0)
        if let p = num(j["priority"]) { c.priority = UILayoutPriority(rawValue: Float(p)) }
        built.append(c)
    }
    NSLayoutConstraint.activate(built)
}

// MARK: - Layout dump (mirror oracle keys + rounding exactly)

func round3(_ v: CGFloat) -> Double { (Double(v) * 1000).rounded() / 1000 }

@MainActor
func dumpLayout(_ v: UIView, path: String, into out: inout [JSONValue]) {
    var entry: [String: JSONValue] = [
        "path": .string(path),
        "class": .string(String(describing: type(of: v))),
        "frame": .array([.number(round3(v.frame.origin.x)), .number(round3(v.frame.origin.y)),
                         .number(round3(v.frame.width)), .number(round3(v.frame.height))]),
    ]
    // Oracle: intrinsic for UILabel/UIButton/UISwitch/UIImageView/UIProgressView.
    // Extend the check as OpenUIKit grows those classes.
    if v is UILabel || v is UIButton || v is UIImageView || v is UIProgressView || v is UISwitch
        || v is UITextField || v is UITextView || v is UISlider {
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
    /// One entry per output PNG: filename (without directory) -> bytes.
    /// Static scenes produce ["<name>.png"]; animation scenes (spec v3)
    /// produce one "<name>.t<ms>.png" per capture time.
    var pngs: [(file: String, data: [UInt8])]
    var layout: JSONValue
}

@MainActor
func runScene(_ scene: JSONValue, warn: (String) -> Void) -> SceneResult {
    guard let name = scene["name"]?.stringValue else { fatalError("scene missing name") }
    guard let sz = numArray(scene["size"]), sz.count == 2 else { fatalError("scene missing size") }
    // One scene's scheduled Timers must never leak into the next scene's
    // capture (Sources/OpenUIKit/Timer.swift): the host clock is the only
    // thing that fires them, and it rewinds per scene.
    Timer._reset()
    let scale = num(scene["scale"]) ?? 2
    let style: UIUserInterfaceStyle = scene["style"]?.stringValue == "dark" ? .dark : .light
    // Window scenes ("window": true, rendered by oracle2 via drawHierarchy
    // in a real UIWindow) get the render server's darker glyph rasterization
    // — select the window-variant ink masks for text (text module).
    GlyphInkTable.windowCompositing = scene["window"]?.boolValue ?? false
    // Scenes with an "alert" or a "modal" key cannot be rendered by either
    // Mac oracle (Catalyst bridges UIAlertController into an AppKit panel and
    // a pageSheet into an AppKit sheet window), so scripts/regen_goldens.sh
    // routes exactly those through the iOS Simulator instead. Real iOS
    // resolves `UIFont.systemFont` to the `.SFUI` cut of San Francisco, not
    // the `.SFNS` cut Catalyst uses, and the two are spaced differently below
    // 20 pt — so those goldens must be laid out with the iOS advances. The
    // routing rule is duplicated here on purpose; ScenePipelineProbeTests
    // asserts the two stay in sync. See FontEngine.SystemFontCut.
    // v5.3 (M13) adds a THIRD route to the Simulator: a scene may ask for
    // real iOS chrome explicitly with `"ios": true` (the bars cluster —
    // Catalyst is not the ground truth for iOS 26 bar platters).
    OpenUIKitRuntime.systemFontCut =
        (scene["alert"] != nil || scene["modal"] != nil
         || scene["ios"]?.boolValue == true) ? .iOS : .macOS

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
    //
    // EXCEPTION (spec v4.3 — M9): the PRESENCE of a top-level "constraints"
    // key (even []) gives the root its REAL frame [0, 0, w, h] — constraints
    // pinning to a 0-sized root would be useless. Consequently the root's
    // backgroundColor draws and dumps show the real root frame (mirrors
    // Tools/oracle/SceneKit.swift buildContainer).
    let constraintSpecs: [JSONValue]? = {
        guard let cv = scene["constraints"] else { return nil }
        guard let arr = cv.arrayValue else {
            fatalError("scene \(name): \"constraints\" must be an array of objects")
        }
        return arr
    }()
    // SECOND EXCEPTION (spec v5 — M10 chrome): chrome root classes
    // (UINavigationStack / UITabBarStack) also get the REAL scene frame —
    // a 0-sized root cannot host the controller view (mirrors the oracle's
    // buildContainer).
    let rootIsChrome = chromeRootClasses.contains(
        rootJ["class"]?.stringValue ?? "UIView")
    if constraintSpecs != nil || rootIsChrome {
        rootJ["frame"] = .array([.number(0), .number(0),
                                 .number(Double(sz[0])), .number(Double(sz[1]))])
    } else {
        rootJ["frame"] = nil
    }

    let container = buildView(rootJ, scale: scale, warn: warn)
    if let specs = constraintSpecs { activateConstraints(specs, container: container) }
    container.overrideUserInterfaceStyle = style
    container.setNeedsLayout()
    container.layoutIfNeeded()
    // Chrome scenes (spec v5): live offsets after the real frames exist.
    applyPendingChromeActions()
    container.layoutIfNeeded()

    var views: [JSONValue] = []
    dumpLayout(container, path: "", into: &views)
    var layoutObj: [String: JSONValue] = ["name": .string(name), "views": .array(views)]
    // Scene spec v4: hit-test probes (root coordinates) -> "hitTests".
    if let probes = scene["hitTests"]?.arrayValue, !probes.isEmpty {
        let points: [CGPoint] = probes.map {
            guard let a = numArray($0), a.count == 2 else {
                fatalError("scene \(name): bad hitTests entry (need [x, y])")
            }
            return CGPoint(x: a[0], y: a[1])
        }
        layoutObj["hitTests"] = .array(runHitTests(points, container: container,
                                                   rootJSON: rootJ))
    }
    let layout = JSONValue.object(layoutObj)

    // The canvas must be the scene size even though the root view is 0x0
    // (oracle renders into a sz-sized context). Host wrapper draws nothing
    // itself; it only gives UIRenderer the right bitmap size.
    let host = UIView(frame: CGRect(x: 0, y: 0, width: sz[0], height: sz[1]))
    host.addSubview(container)

    // Scene spec v5 (M10): top-level "modal" — present a real pageSheet
    // over the base scene for the PIXEL comparison only (the layout dump
    // above excludes the sheet, mirroring the oracle/simulator renderer).
    if let modalJ = scene["modal"]?.objectValue {
        guard (modalJ["style"]?.stringValue ?? "pageSheet") == "pageSheet" else {
            fatalError("scene \(name): modal style must be \"pageSheet\"")
        }
        guard let contentJ = modalJ["content"]?.objectValue else {
            fatalError("scene \(name): \"modal\" needs a \"content\" view object")
        }
        let baseVC = UIViewController()
        baseVC.view = host
        let sheetVC = UIViewController()
        sheetVC.view = buildView(contentJ, scale: scale, warn: warn)
        // Spec v5.1: "grabber": true -> prefersGrabberVisible (UIKit's
        // default is false, hence two goldens).
        if modalJ["grabber"]?.boolValue == true {
            sheetVC.sheetPresentationController?.prefersGrabberVisible = true
        }
        baseVC.present(sheetVC, animated: false)
        host.layoutIfNeeded()
        sceneRetainedControllers.append(baseVC)
        sceneRetainedControllers.append(sheetVC)
    }

    // Scene spec v5.2 (M12): top-level "alert" — a presented
    // UIAlertController over the base scene, pixels only (its internals are
    // private on both sides, exactly like the modal sheet's content).
    if let alertJ = scene["alert"]?.objectValue {
        let st = alertJ["style"]?.stringValue ?? "alert"
        guard st == "alert" || st == "actionSheet" else {
            fatalError("scene \(name): alert style must be \"alert\" or \"actionSheet\"")
        }
        guard let actionsJ = alertJ["actions"]?.arrayValue else {
            fatalError("scene \(name): \"alert\" needs an \"actions\" array")
        }
        let baseVC = UIViewController()
        baseVC.view = host
        let ac = UIAlertController(title: alertJ["title"]?.stringValue,
                                   message: alertJ["message"]?.stringValue,
                                   preferredStyle: st == "actionSheet" ? .actionSheet : .alert)
        ac.view.overrideUserInterfaceStyle = style
        for ph in (alertJ["textFields"]?.arrayValue ?? []) {
            ac.addTextField { $0.placeholder = ph.stringValue }
        }
        var preferred: UIAlertAction?
        for entry in actionsJ {
            guard let e = entry.objectValue else { fatalError("scene \(name): bad alert action") }
            let s: UIAlertAction.Style
            switch e["style"]?.stringValue ?? "default" {
            case "cancel": s = .cancel
            case "destructive": s = .destructive
            case "default": s = .default
            default: fatalError("scene \(name): bad alert action style")
            }
            let a = UIAlertAction(title: e["title"]?.stringValue ?? "", style: s)
            if let enabled = e["enabled"]?.boolValue { a.isEnabled = enabled }
            ac.addAction(a)
            if alertJ["preferredAction"]?.stringValue == e["title"]?.stringValue {
                preferred = a
            }
        }
        if let p = preferred { ac.preferredAction = p }
        baseVC.present(ac, animated: false)
        host.layoutIfNeeded()
        sceneRetainedControllers.append(baseVC)
        sceneRetainedControllers.append(ac)
    }

    // Scene spec v3: animation scenes render one frame per capture time
    // (and no plain <name>.png). Animations are started AFTER the layout
    // dump — the dump is the pre-animation (t = 0) model layout.
    let animations = parseAnimations(scene)
    if !animations.isEmpty {
        let captureTimes = (scene["captureTimes"]?.arrayValue ?? [])
            .compactMap { $0.doubleValue }
        guard !captureTimes.isEmpty else {
            fatalError("scene \(name): \"animations\" requires \"captureTimes\"")
        }
        startAnimations(animations, container: container)
        var pngs: [(file: String, data: [UInt8])] = []
        for t in captureTimes {
            OpenUIKitRuntime.animationTime = t
            let bmp = UIRenderer.render(host, scale: scale)
            pngs.append(("\(name).\(captureSuffix(t)).png", bmp.pngData()))
        }
        OpenUIKitRuntime.animationTime = 0
        return SceneResult(name: name, pngs: pngs, layout: layout)
    }

    let bmp = UIRenderer.render(host, scale: scale)
    return SceneResult(name: name, pngs: [("\(name).png", bmp.pngData())],
                       layout: layout)
}
