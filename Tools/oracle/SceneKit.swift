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
}

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
    let hitTests: [CGPoint] = (scene["hitTests"] as? [Any] ?? []).map {
        guard let a = numArray($0), a.count == 2 else {
            fatalError("scene \(name): bad hitTests entry (need [x, y])")
        }
        return CGPoint(x: a[0], y: a[1])
    }
    return SceneSpec(name: name, width: sz[0], height: sz[1], scale: scale, style: style,
                     traits: UITraitCollection(userInterfaceStyle: style),
                     windowRequired: scene["window"] as? Bool == true,
                     rootJSON: scene["root"] as! JSON,
                     animations: animations, captureTimes: captureTimes,
                     hitTests: hitTests)
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
