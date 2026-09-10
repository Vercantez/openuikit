// UIButton.Configuration oracle probe (iOS 26.1).
//
// Measures exactly the members Kickstarter's KDS + Kickstarter-Framework use
// (see docs/agent_reports/uibutton-configuration.md section 1), plus the full
// factory / cornerStyle / buttonSize grid so the port's defaults are recorded
// rather than guessed.
//
// Driven by scripts/uibutton_configuration_probe_sim.sh. Writes
// Documents/uibutton-configuration.json and Documents/done.marker.

import UIKit

// MARK: - JSON helpers

func f(_ v: CGFloat) -> Double {
    let d = Double(v)
    if !d.isFinite { return d > 0 ? 1e18 : -1e18 }
    // Keep half-point measurements exact, drop float noise.
    return (d * 100_000).rounded() / 100_000
}

let lightTraits = UITraitCollection(userInterfaceStyle: .light)
let darkTraits = UITraitCollection(userInterfaceStyle: .dark)

func rgba(_ color: UIColor?, _ traits: UITraitCollection) -> String? {
    guard let color else { return nil }
    let resolved = color.resolvedColor(with: traits)
    var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
    guard resolved.getRed(&r, green: &g, blue: &b, alpha: &a) else {
        var w: CGFloat = 0
        if resolved.getWhite(&w, alpha: &a) {
            return String(format: "w%.4f/%.4f", Double(w), Double(a))
        }
        return "unreadable"
    }
    return String(format: "%.4f,%.4f,%.4f,%.4f", Double(r), Double(g), Double(b), Double(a))
}

func colorPair(_ color: UIColor?) -> Any {
    guard let color else { return NSNull() }
    return ["light": (rgba(color, lightTraits) as Any?) ?? NSNull(),
            "dark": (rgba(color, darkTraits) as Any?) ?? NSNull()]
}

func rect(_ r: CGRect) -> [Double] { [f(r.origin.x), f(r.origin.y), f(r.size.width), f(r.size.height)] }
func size(_ s: CGSize) -> [Double] { [f(s.width), f(s.height)] }
func insets(_ i: NSDirectionalEdgeInsets) -> [Double] { [f(i.top), f(i.leading), f(i.bottom), f(i.trailing)] }

// MARK: - Configuration dump

func dumpBackground(_ b: UIBackgroundConfiguration) -> [String: Any] {
    [
        "cornerRadius": f(b.cornerRadius),
        "backgroundColor": colorPair(b.backgroundColor),
        "hasBackgroundColorTransformer": b.backgroundColorTransformer != nil,
        "strokeWidth": f(b.strokeWidth),
        "strokeColor": colorPair(b.strokeColor),
        "hasStrokeColorTransformer": b.strokeColorTransformer != nil,
        "strokeOutset": f(b.strokeOutset),
        "backgroundInsets": insets(b.backgroundInsets),
        "hasCustomView": b.customView != nil,
        "hasVisualEffect": b.visualEffect != nil,
        "hasImage": b.image != nil,
    ]
}

func dumpConfig(_ c: UIButton.Configuration) -> [String: Any] {
    var d: [String: Any] = [
        "title": c.title ?? NSNull(),
        "subtitle": c.subtitle ?? NSNull(),
        "hasAttributedTitle": c.attributedTitle != nil,
        "hasImage": c.image != nil,
        "imagePadding": f(c.imagePadding),
        "imagePlacement": Int(c.imagePlacement.rawValue),
        "titlePadding": f(c.titlePadding),
        "titleAlignment": String(describing: c.titleAlignment),
        "titleLineBreakMode": c.titleLineBreakMode.rawValue,
        "subtitleLineBreakMode": c.subtitleLineBreakMode.rawValue,
        "contentInsets": insets(c.contentInsets),
        "cornerStyle": String(describing: c.cornerStyle),
        "buttonSize": String(describing: c.buttonSize),
        "baseForegroundColor": colorPair(c.baseForegroundColor),
        "baseBackgroundColor": colorPair(c.baseBackgroundColor),
        "background": dumpBackground(c.background),
        "showsActivityIndicator": c.showsActivityIndicator,
        "automaticallyUpdateForSelection": c.automaticallyUpdateForSelection,
        "hasTitleTextAttributesTransformer": c.titleTextAttributesTransformer != nil,
        "hasImageColorTransformer": c.imageColorTransformer != nil,
        "imageReservation": f(c.imageReservation),
    ]
    if #available(iOS 15.0, *) {
        d["macIdiomStyle"] = String(describing: c.macIdiomStyle)
    }
    return d
}

// MARK: - View tree dump

func dumpTree(_ v: UIView, depth: Int = 0) -> [String: Any] {
    var d: [String: Any] = [
        "class": String(describing: type(of: v)),
        "frame": rect(v.frame),
        "hidden": v.isHidden,
        "alpha": f(v.alpha),
        "cornerRadius": f(v.layer.cornerRadius),
        "borderWidth": f(v.layer.borderWidth),
        "masksToBounds": v.layer.masksToBounds,
    ]
    if let bg = v.backgroundColor { d["backgroundColor"] = colorPair(bg) }
    if let lb = v.layer.backgroundColor {
        d["layerBackgroundColor"] = rgba(UIColor(cgColor: lb), lightTraits) ?? NSNull()
    }
    if let bc = v.layer.borderColor {
        d["layerBorderColor"] = rgba(UIColor(cgColor: bc), lightTraits) ?? NSNull()
    }
    if let label = v as? UILabel {
        d["text"] = label.text ?? NSNull()
        d["font"] = "\(label.font.fontName)@\(f(label.font.pointSize))"
        d["textColor"] = colorPair(label.textColor)
        d["lineBreakMode"] = label.lineBreakMode.rawValue
        d["textAlignment"] = label.textAlignment.rawValue
        d["numberOfLines"] = label.numberOfLines
    }
    if let iv = v as? UIImageView {
        d["hasImage"] = iv.image != nil
        d["tintColor"] = colorPair(iv.tintColor)
    }
    if depth < 4, !v.subviews.isEmpty {
        d["subviews"] = v.subviews.map { dumpTree($0, depth: depth + 1) }
    }
    return d
}

// MARK: - Pixel profiles

/// Render `view` at scale 1 (a 1-pt pixel profile) over transparent black.
func renderPixels(_ view: UIView) -> (w: Int, h: Int, px: [UInt8])? {
    let w = Int(view.bounds.width.rounded()), h = Int(view.bounds.height.rounded())
    guard w > 0, h > 0, w < 2000, h < 2000 else { return nil }
    var buf = [UInt8](repeating: 0, count: w * h * 4)
    guard let cs = CGColorSpace(name: CGColorSpace.sRGB) else { return nil }
    let ok: Bool = buf.withUnsafeMutableBytes { raw -> Bool in
        guard let ctx = CGContext(data: raw.baseAddress, width: w, height: h,
                                  bitsPerComponent: 8, bytesPerRow: w * 4, space: cs,
                                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
        else { return false }
        view.layer.render(in: ctx)
        return true
    }
    return ok ? (w, h, buf) : nil
}

func pixel(_ p: (w: Int, h: Int, px: [UInt8]), _ x: Int, _ y: Int) -> [Int] {
    guard x >= 0, y >= 0, x < p.w, y < p.h else { return [-1, -1, -1, -1] }
    let i = (y * p.w + x) * 4
    return [Int(p.px[i]), Int(p.px[i + 1]), Int(p.px[i + 2]), Int(p.px[i + 3])]
}

/// Run-length encoded horizontal scanline: [[startX, runLength, r,g,b,a], ...]
func scanline(_ p: (w: Int, h: Int, px: [UInt8]), y: Int) -> [[Int]] {
    var runs: [[Int]] = []
    var start = 0
    var current = pixel(p, 0, y)
    for x in 1..<p.w {
        let c = pixel(p, x, y)
        if c != current {
            runs.append([start, x - start] + current)
            start = x
            current = c
        }
    }
    runs.append([start, p.w - start] + current)
    return runs
}

/// For each of the first `rows` scanlines, the leftmost x with alpha >= 128.
/// This reads a corner radius off the rendered shape directly.
func cornerProfile(_ p: (w: Int, h: Int, px: [UInt8]), rows: Int = 16) -> [Int] {
    var result: [Int] = []
    for y in 0..<Swift.min(rows, p.h) {
        var found = -1
        for x in 0..<p.w where pixel(p, x, y)[3] >= 128 { found = x; break }
        result.append(found)
    }
    return result
}

// MARK: - Probe body

@MainActor
final class Probe {
    var out: [String: Any] = [:]
    let window: UIWindow

    init(window: UIWindow) { self.window = window }

    /// Host a button in the window, lay it out, and hand it to `body`.
    func hosted(_ button: UIButton, width: CGFloat? = nil, height: CGFloat? = nil,
                _ body: (UIButton) -> Void) {
        window.addSubview(button)
        let intrinsic = button.intrinsicContentSize
        button.frame = CGRect(x: 0, y: 0,
                              width: width ?? intrinsic.width,
                              height: height ?? intrinsic.height)
        button.setNeedsLayout()
        button.layoutIfNeeded()
        // A configured button defers its update to the next layout pass.
        window.setNeedsLayout()
        window.layoutIfNeeded()
        body(button)
        button.removeFromSuperview()
    }

    // 1. Factory defaults.
    func factories() {
        var factories: [(String, UIButton.Configuration)] = [
            ("plain", .plain()), ("filled", .filled()), ("tinted", .tinted()),
            ("gray", .gray()), ("borderless", .borderless()), ("bordered", .bordered()),
            ("borderedTinted", .borderedTinted()), ("borderedProminent", .borderedProminent()),
        ]
        if #available(iOS 26.0, *) {
            factories.append(("glass", .glass()))
            factories.append(("prominentGlass", .prominentGlass()))
            factories.append(("clearGlass", .clearGlass()))
            factories.append(("prominentClearGlass", .prominentClearGlass()))
        }
        var rows: [String: Any] = [:]
        for (name, config) in factories { rows[name] = dumpConfig(config) }
        out["factoryDefaults"] = rows
    }

    // 2. Intrinsic size, subview tree and pixels per factory (title "Configure").
    func factoryLayout() {
        var factories: [(String, () -> UIButton.Configuration)] = [
            ("plain", { .plain() }), ("filled", { .filled() }), ("tinted", { .tinted() }),
            ("gray", { .gray() }), ("borderless", { .borderless() }), ("bordered", { .bordered() }),
            ("borderedTinted", { .borderedTinted() }),
            ("borderedProminent", { .borderedProminent() }),
        ]
        if #available(iOS 26.0, *) { factories.append(("glass", { .glass() })) }
        var rows: [String: Any] = [:]
        for (name, make) in factories {
            var config = make()
            config.title = "Configure"
            let button = UIButton(configuration: config)
            var row: [String: Any] = [:]
            hosted(button) { b in
                row["intrinsicContentSize"] = size(b.intrinsicContentSize)
                row["sizeThatFitsUnbounded"] = size(b.sizeThatFits(
                    CGSize(width: CGFloat.greatestFiniteMagnitude,
                           height: CGFloat.greatestFiniteMagnitude)))
                row["frame"] = rect(b.frame)
                row["tree"] = dumpTree(b)
                row["titleLabelFrame"] = rect(b.titleLabel?.frame ?? .zero)
                if let label = b.titleLabel {
                    row["titleFont"] = "\(label.font.fontName)@\(f(label.font.pointSize))"
                    row["titleColor"] = colorPair(label.textColor)
                }
                row["resolvedConfig"] = dumpConfig(b.configuration ?? .plain())
                if let p = renderPixels(b) {
                    row["pixels"] = [
                        "size": [p.w, p.h],
                        "midRow": scanline(p, y: p.h / 2),
                        "topLeftCorner": cornerProfile(p),
                        "center": pixel(p, p.w / 2, p.h / 2),
                        "topEdgeMid": pixel(p, p.w / 2, 0),
                        "leftEdgeMid": pixel(p, 0, p.h / 2),
                    ]
                }
            }
            rows[name] = row
        }
        out["factoryLayout"] = rows
    }

    // 3. Colours resolved per control state, for the factories KDS uses.
    func statesPerFactory() {
        var rows: [String: Any] = [:]
        for (name, make) in [("filled", { UIButton.Configuration.filled() }),
                             ("bordered", { UIButton.Configuration.bordered() }),
                             ("borderless", { UIButton.Configuration.borderless() }),
                             ("plain", { UIButton.Configuration.plain() })] {
            var perState: [String: Any] = [:]
            for stateName in ["normal", "highlighted", "disabled", "selected"] {
                var config = make()
                config.title = "Configure"
                let button = UIButton(configuration: config)
                switch stateName {
                case "highlighted": button.isHighlighted = true
                case "disabled": button.isEnabled = false
                case "selected": button.isSelected = true
                default: break
                }
                var row: [String: Any] = [:]
                hosted(button) { b in
                    row["state"] = b.state.rawValue
                    row["intrinsicContentSize"] = size(b.intrinsicContentSize)
                    if let label = b.titleLabel { row["titleColor"] = colorPair(label.textColor) }
                    row["configBackground"] = dumpBackground(b.configuration?.background ?? .clear())
                    row["configBaseForeground"] = colorPair(b.configuration?.baseForegroundColor)
                    row["configBaseBackground"] = colorPair(b.configuration?.baseBackgroundColor)
                    if let p = renderPixels(b) {
                        row["center"] = pixel(p, p.w / 2, p.h / 2)
                        row["fillAt2_2"] = pixel(p, 2, 2)
                        row["midRow"] = scanline(p, y: p.h / 2)
                    }
                }
                perState[stateName] = row
            }
            rows[name] = perState
        }
        out["statesPerFactory"] = rows
    }

    // 4. cornerStyle x button height: measured corner radius from pixels.
    func cornerStyles() {
        let styles: [(String, UIButton.Configuration.CornerStyle)] = [
            ("fixed", .fixed), ("dynamic", .dynamic), ("small", .small),
            ("medium", .medium), ("large", .large), ("capsule", .capsule),
        ]
        var rows: [String: Any] = [:]
        for (name, style) in styles {
            var byHeight: [String: Any] = [:]
            for h in [20.0, 28.0, 34.0, 44.0, 60.0] as [CGFloat] {
                var config = UIButton.Configuration.filled()
                config.title = "Configure"
                config.cornerStyle = style
                let button = UIButton(configuration: config)
                var row: [String: Any] = [:]
                hosted(button, width: 160, height: h) { b in
                    row["cornerStyleRaw"] = String(describing: b.configuration?.cornerStyle)
                    row["backgroundCornerRadius"] =
                        f(b.configuration?.background.cornerRadius ?? -1)
                    row["layerCornerRadius"] = f(b.layer.cornerRadius)
                    // The background view UIKit inserts, if any.
                    row["subviewCornerRadii"] = b.subviews.map {
                        ["class": String(describing: type(of: $0)),
                         "cornerRadius": f($0.layer.cornerRadius),
                         "frame": rect($0.frame)] as [String: Any]
                    }
                    if let p = renderPixels(b) {
                        row["topLeftCorner"] = cornerProfile(p, rows: Int(h / 2))
                        row["midRow"] = scanline(p, y: p.h / 2)
                    }
                }
                byHeight["h\(Int(h))"] = row
            }
            // Explicit background.cornerRadius, which is what KDS assigns.
            var explicit = UIButton.Configuration.filled()
            explicit.title = "Configure"
            explicit.cornerStyle = style
            explicit.background.cornerRadius = 6
            let button = UIButton(configuration: explicit)
            var row: [String: Any] = [:]
            hosted(button, width: 160, height: 44) { b in
                row["backgroundCornerRadius"] = f(b.configuration?.background.cornerRadius ?? -1)
                if let p = renderPixels(b) { row["topLeftCorner"] = cornerProfile(p, rows: 14) }
            }
            byHeight["explicitRadius6_h44"] = row
            rows[name] = byHeight
        }
        out["cornerStyles"] = rows
    }

    // 5. buttonSize: intrinsic size and default insets.
    func buttonSizes() {
        let sizes: [(String, UIButton.Configuration.Size)] = [
            ("mini", .mini), ("small", .small), ("medium", .medium), ("large", .large),
        ]
        var rows: [String: Any] = [:]
        for (name, bs) in sizes {
            var config = UIButton.Configuration.filled()
            config.title = "Configure"
            config.buttonSize = bs
            let button = UIButton(configuration: config)
            var row: [String: Any] = ["describing": String(describing: bs)]
            hosted(button) { b in
                row["intrinsicContentSize"] = size(b.intrinsicContentSize)
                row["contentInsets"] = insets(b.configuration?.contentInsets ?? .zero)
                row["titleLabelFrame"] = rect(b.titleLabel?.frame ?? .zero)
                if let label = b.titleLabel {
                    row["titleFont"] = "\(label.font.fontName)@\(f(label.font.pointSize))"
                }
                if let p = renderPixels(b) { row["topLeftCorner"] = cornerProfile(p, rows: 12) }
            }
            rows[name] = row
        }
        out["buttonSizes"] = rows
    }

    // 6. contentInsets sweep: what KDS assigns (12/12/12/12 and 8.5/12/8.5/12).
    func contentInsetsSweep() {
        var rows: [String: Any] = [:]
        let cases: [(String, NSDirectionalEdgeInsets)] = [
            ("zero", .zero),
            ("kds_plain", NSDirectionalEdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 12)),
            ("kds_image", NSDirectionalEdgeInsets(top: 8.5, leading: 12, bottom: 8.5, trailing: 12)),
            ("asym", NSDirectionalEdgeInsets(top: 3, leading: 20, bottom: 7, trailing: 4)),
        ]
        for (name, i) in cases {
            var config = UIButton.Configuration.filled()
            config.title = "Configure"
            config.contentInsets = i
            let button = UIButton(configuration: config)
            var row: [String: Any] = ["assigned": insets(i)]
            hosted(button) { b in
                row["intrinsicContentSize"] = size(b.intrinsicContentSize)
                row["readBack"] = insets(b.configuration?.contentInsets ?? .zero)
                row["titleLabelFrame"] = rect(b.titleLabel?.frame ?? .zero)
            }
            rows[name] = row
        }
        // Same sweep on .borderless(), which is what the Framework sites use.
        var borderless: [String: Any] = [:]
        for (name, i) in cases {
            var config = UIButton.Configuration.borderless()
            config.title = "Configure"
            config.contentInsets = i
            let button = UIButton(configuration: config)
            var row: [String: Any] = [:]
            hosted(button) { b in
                row["intrinsicContentSize"] = size(b.intrinsicContentSize)
                row["titleLabelFrame"] = rect(b.titleLabel?.frame ?? .zero)
            }
            borderless[name] = row
        }
        rows["borderless"] = borderless
        out["contentInsets"] = rows
    }

    // 7. imagePlacement / imagePadding: title and image frames.
    func imagePlacement() {
        let image = UIImage(systemName: "star.fill") ?? UIImage()
        var rows: [String: Any] = [:]
        let placements: [(String, NSDirectionalRectEdge)] = [
            ("leading", .leading), ("trailing", .trailing),
            ("top", .top), ("bottom", .bottom),
        ]
        for (name, placement) in placements {
            for padding in [0.0, 6.0, 20.0] as [CGFloat] {
                var config = UIButton.Configuration.filled()
                config.title = "Go"
                config.image = image
                config.imagePlacement = placement
                config.imagePadding = padding
                let button = UIButton(configuration: config)
                var row: [String: Any] = ["placementRaw": Int(placement.rawValue)]
                hosted(button) { b in
                    row["intrinsicContentSize"] = size(b.intrinsicContentSize)
                    row["titleLabelFrame"] = rect(b.titleLabel?.frame ?? .zero)
                    row["imageViewFrame"] = rect(b.imageView?.frame ?? .zero)
                    row["imageSize"] = size(image.size)
                    row["tree"] = dumpTree(b)
                }
                rows["\(name)_pad\(Int(padding))"] = row
            }
        }
        out["imagePlacement"] = rows
    }

    // 8. title / subtitle / attributedTitle / titleAlignment.
    func titles() {
        var rows: [String: Any] = [:]
        // title + subtitle
        var config = UIButton.Configuration.filled()
        config.title = "Configure"
        config.subtitle = "Subtitle"
        var button = UIButton(configuration: config)
        var row: [String: Any] = [:]
        hosted(button) { b in
            row["intrinsicContentSize"] = size(b.intrinsicContentSize)
            row["tree"] = dumpTree(b)
            row["titlePadding"] = f(b.configuration?.titlePadding ?? -1)
        }
        rows["titleAndSubtitle"] = row

        // attributedTitle, as PledgeOverTimePaymentScheduleViewController writes it.
        // Built exactly as PledgeOverTimePaymentScheduleViewController does.
        let attributed = AttributedString(NSAttributedString(
            string: "Terms of Use",
            attributes: [.font: UIFont.systemFont(ofSize: 20, weight: .bold),
                         .foregroundColor: UIColor.systemRed]))
        var config2 = UIButton.Configuration.borderless()
        config2.attributedTitle = attributed
        button = UIButton(configuration: config2)
        row = [:]
        hosted(button) { b in
            row["intrinsicContentSize"] = size(b.intrinsicContentSize)
            row["titleLabelFrame"] = rect(b.titleLabel?.frame ?? .zero)
            if let label = b.titleLabel {
                row["titleFont"] = "\(label.font.fontName)@\(f(label.font.pointSize))"
                row["titleColor"] = colorPair(label.textColor)
                row["labelText"] = label.text ?? NSNull()
            }
            // Reading back: does `title` mirror the attributed string?
            row["readBackTitle"] = b.configuration?.title ?? NSNull()
            if let at = b.configuration?.attributedTitle {
                row["readBackAttributedCharacters"] = String(at.characters)
            }
        }
        rows["attributedTitle"] = row

        // Setting `title` after `attributedTitle` and vice versa.
        var config3 = UIButton.Configuration.plain()
        config3.attributedTitle = AttributedString("Attributed")
        config3.title = "Plain"
        rows["titleAfterAttributed"] = [
            "title": (config3.title as Any?) ?? NSNull(),
            "attributed": (config3.attributedTitle.map { String($0.characters) } as Any?) ?? NSNull(),
        ] as [String: Any]
        var config4 = UIButton.Configuration.plain()
        config4.title = "Plain"
        config4.attributedTitle = AttributedString("Attributed")
        rows["attributedAfterTitle"] = [
            "title": (config4.title as Any?) ?? NSNull(),
            "attributed": (config4.attributedTitle.map { String($0.characters) } as Any?) ?? NSNull(),
        ] as [String: Any]

        // titleAlignment on a wide button.
        var alignments: [String: Any] = [:]
        for (name, alignment) in [
            ("automatic", UIButton.Configuration.TitleAlignment.automatic),
            ("leading", .leading), ("center", .center), ("trailing", .trailing),
        ] {
            var c = UIButton.Configuration.filled()
            c.title = "Configure"
            c.subtitle = "Sub"
            c.titleAlignment = alignment
            let b = UIButton(configuration: c)
            var r: [String: Any] = ["raw": String(describing: alignment)]
            hosted(b, width: 260, height: 60) { button in
                r["titleLabelFrame"] = rect(button.titleLabel?.frame ?? .zero)
                r["tree"] = dumpTree(button)
            }
            alignments[name] = r
        }
        rows["titleAlignment"] = alignments

        // titleLineBreakMode: a long title in a narrow button.
        var lineBreak: [String: Any] = [:]
        for (name, mode) in [("byWordWrapping", NSLineBreakMode.byWordWrapping),
                             ("byTruncatingTail", .byTruncatingTail),
                             ("byTruncatingMiddle", .byTruncatingMiddle),
                             ("byCharWrapping", .byCharWrapping)] {
            var c = UIButton.Configuration.filled()
            c.title = "A rather long button title here"
            c.titleLineBreakMode = mode
            let b = UIButton(configuration: c)
            var r: [String: Any] = ["raw": mode.rawValue]
            hosted(b, width: 140, height: 80) { button in
                r["titleLabelFrame"] = rect(button.titleLabel?.frame ?? .zero)
                r["labelLineBreakMode"] = button.titleLabel?.lineBreakMode.rawValue ?? -1
                r["labelNumberOfLines"] = button.titleLabel?.numberOfLines ?? -1
                r["labelText"] = button.titleLabel?.text ?? NSNull()
            }
            // And what the unbounded intrinsic size becomes.
            let b2 = UIButton(configuration: c)
            hosted(b2) { button in
                r["intrinsicContentSize"] = size(button.intrinsicContentSize)
            }
            lineBreak[name] = r
        }
        rows["titleLineBreakMode"] = lineBreak
        out["titles"] = rows
    }

    // 9. The transformers: when they run, what they receive, what they change.
    func transformers() {
        var log: [String] = []
        var config = UIButton.Configuration.filled()
        config.title = "Configure"
        config.baseForegroundColor = .systemGreen
        config.image = UIImage(systemName: "star.fill")

        // Exactly KDS's shape.
        config.titleTextAttributesTransformer =
            UIConfigurationTextAttributesTransformer { incoming in
                var container = incoming
                let inFont = container[AttributeScopes.UIKitAttributes.FontAttribute.self]
                let inColor =
                    container[AttributeScopes.UIKitAttributes.ForegroundColorAttribute.self]
                log.append("title in: font=\(inFont.map { "\($0.fontName)@\($0.pointSize)" } ?? "nil") "
                    + "color=\(rgba(inColor, lightTraits) ?? "nil") "
                    + "keys=\(container)")
                container[AttributeScopes.UIKitAttributes.FontAttribute.self] =
                    UIFont.systemFont(ofSize: 22, weight: .heavy)
                container[AttributeScopes.UIKitAttributes.ForegroundColorAttribute.self] =
                    UIColor.systemPurple
                return container
            }
        config.imageColorTransformer = UIConfigurationColorTransformer { incoming in
            log.append("image in: \(rgba(incoming, lightTraits) ?? "?")")
            return .systemOrange
        }

        let button = UIButton(configuration: config)
        var row: [String: Any] = [:]
        hosted(button) { b in
            row["intrinsicContentSize"] = size(b.intrinsicContentSize)
            if let label = b.titleLabel {
                row["titleFont"] = "\(label.font.fontName)@\(f(label.font.pointSize))"
                row["titleColor"] = colorPair(label.textColor)
            }
            row["imageViewTintColor"] = colorPair(b.imageView?.tintColor)
            row["tree"] = dumpTree(b)
            if let p = renderPixels(b) { row["midRow"] = scanline(p, y: p.h / 2) }
        }
        row["callLog"] = log
        // A transformer that changes nothing: does the base colour survive?
        var passthrough = UIButton.Configuration.filled()
        passthrough.title = "Configure"
        passthrough.baseForegroundColor = .systemGreen
        passthrough.titleTextAttributesTransformer =
            UIConfigurationTextAttributesTransformer { $0 }
        let b2 = UIButton(configuration: passthrough)
        var r2: [String: Any] = [:]
        hosted(b2) { b in
            if let label = b.titleLabel {
                r2["titleFont"] = "\(label.font.fontName)@\(f(label.font.pointSize))"
                r2["titleColor"] = colorPair(label.textColor)
            }
        }
        row["passthrough"] = r2
        out["transformers"] = row
    }

    // 10. configurationUpdateHandler: when does it fire?
    func updateHandler() {
        var events: [[String: Any]] = []
        var config = UIButton.Configuration.filled()
        config.title = "Configure"
        let button = UIButton(configuration: config)
        var phase = "init"
        button.configurationUpdateHandler = { b in
            events.append(["phase": phase, "state": b.state.rawValue,
                           "isHighlighted": b.isHighlighted, "isEnabled": b.isEnabled,
                           "isSelected": b.isSelected])
        }
        window.addSubview(button)
        button.frame = CGRect(x: 0, y: 0, width: 160, height: 44)

        func run(_ name: String, _ body: () -> Void) {
            phase = name
            let before = events.count
            body()
            window.setNeedsLayout()
            window.layoutIfNeeded()
            events.append(["phase": "\(name)/after", "fired": events.count - before])
        }

        run("assignHandler+layout") {}
        run("setNeedsUpdateConfiguration") { button.setNeedsUpdateConfiguration() }
        run("layoutOnly") {}
        run("isHighlighted=true") { button.isHighlighted = true }
        run("isHighlighted=false") { button.isHighlighted = false }
        run("isEnabled=false") { button.isEnabled = false }
        run("isEnabled=true") { button.isEnabled = true }
        run("isSelected=true") { button.isSelected = true }
        run("configuration=newValue") {
            var c = button.configuration
            c?.title = "Changed"
            button.configuration = c
        }
        run("frameChange") { button.frame = CGRect(x: 0, y: 0, width: 200, height: 44) }
        run("tintColorChange") { button.tintColor = .systemPink }
        run("setNeedsUpdateConfigurationTwice") {
            button.setNeedsUpdateConfiguration()
            button.setNeedsUpdateConfiguration()
        }
        // Does setNeedsUpdateConfiguration fire synchronously (before layout)?
        phase = "syncCheck"
        let beforeSync = events.count
        button.setNeedsUpdateConfiguration()
        events.append(["phase": "syncCheck/immediate", "fired": events.count - beforeSync])
        window.layoutIfNeeded()

        button.removeFromSuperview()
        out["updateHandler"] = ["events": events]

        // Mutating the configuration INSIDE the handler (KDS's updateColors).
        var events2: [String] = []
        var c2 = UIButton.Configuration.bordered()
        c2.title = "Configure"
        let b2 = UIButton(configuration: c2)
        var depth = 0
        b2.configurationUpdateHandler = { b in
            depth += 1
            events2.append("enter depth=\(depth) state=\(b.state.rawValue)")
            if depth < 6 {
                var cc = b.configuration
                cc?.background.backgroundColor =
                    b.state.contains(.highlighted) ? .systemRed : .systemBlue
                b.configuration = cc
            }
            depth -= 1
        }
        window.addSubview(b2)
        b2.frame = CGRect(x: 0, y: 0, width: 160, height: 44)
        window.layoutIfNeeded()
        b2.isHighlighted = true
        window.layoutIfNeeded()
        var r2: [String: Any] = ["log": events2]
        r2["finalBackground"] = colorPair(b2.configuration?.background.backgroundColor)
        if let p = renderPixels(b2) { r2["center"] = pixel(p, p.w / 2, p.h / 2) }
        b2.removeFromSuperview()
        out["updateHandlerReentrancy"] = r2
    }

    // 11. `updated(for:)`.
    func updatedFor() {
        var rows: [String: Any] = [:]
        for stateName in ["normal", "highlighted", "disabled"] {
            var config = UIButton.Configuration.filled()
            config.title = "Configure"
            config.baseForegroundColor = .systemGreen
            config.baseBackgroundColor = .systemBlue
            let button = UIButton(configuration: config)
            switch stateName {
            case "highlighted": button.isHighlighted = true
            case "disabled": button.isEnabled = false
            default: break
            }
            window.addSubview(button)
            button.frame = CGRect(x: 0, y: 0, width: 160, height: 44)
            window.layoutIfNeeded()
            let updated = config.updated(for: button)
            rows[stateName] = [
                "before": dumpConfig(config),
                "after": dumpConfig(updated),
                "changed": dumpConfig(updated).description != dumpConfig(config).description,
            ]
            button.removeFromSuperview()
        }
        out["updatedFor"] = rows
    }

    // 12. showsActivityIndicator, and UIButton(configuration:primaryAction:).
    func misc() {
        var rows: [String: Any] = [:]
        var config = UIButton.Configuration.filled()
        config.title = "Configure"
        config.showsActivityIndicator = true
        let button = UIButton(configuration: config)
        var row: [String: Any] = [:]
        hosted(button) { b in
            row["intrinsicContentSize"] = size(b.intrinsicContentSize)
            row["tree"] = dumpTree(b)
        }
        rows["showsActivityIndicator"] = row

        // AlertBanner's `UIButton(configuration: .plain())`, and the
        // primaryAction form.
        var fired = 0
        let action = UIAction(title: "Action Title") { _ in fired += 1 }
        let b2 = UIButton(configuration: .plain(), primaryAction: action)
        var r2: [String: Any] = [:]
        hosted(b2) { b in
            r2["configTitle"] = b.configuration?.title ?? NSNull()
            r2["currentTitle"] = b.currentTitle ?? NSNull()
            r2["labelText"] = b.titleLabel?.text ?? NSNull()
            r2["intrinsicContentSize"] = size(b.intrinsicContentSize)
            b.sendActions(for: .touchUpInside)
        }
        r2["actionFired"] = fired
        rows["primaryAction"] = r2

        // Does a legacy setTitle survive a configuration, and vice versa?
        let b3 = UIButton(configuration: .filled())
        b3.setTitle("Legacy", for: .normal)
        var r3: [String: Any] = ["configTitleAfterSetTitle": b3.configuration?.title ?? NSNull()]
        hosted(b3) { b in
            r3["labelText"] = b.titleLabel?.text ?? NSNull()
            r3["currentTitle"] = b.currentTitle ?? NSNull()
            r3["intrinsicContentSize"] = size(b.intrinsicContentSize)
        }
        rows["legacySetTitleWithConfiguration"] = r3

        // Setting configuration to nil on a previously configured button.
        let b4 = UIButton(configuration: .filled())
        b4.configuration?.title = "Configure"
        b4.configuration = nil
        var r4: [String: Any] = [:]
        hosted(b4) { b in
            r4["labelText"] = b.titleLabel?.text ?? NSNull()
            r4["intrinsicContentSize"] = size(b.intrinsicContentSize)
            r4["titleFont"] = b.titleLabel.map { "\($0.font.fontName)@\(f($0.pointSizeShim))" }
                ?? NSNull()
        }
        rows["configurationSetToNil"] = r4

        // A plain UIButton(frame:) has no configuration.
        let b5 = UIButton(frame: .zero)
        rows["plainButtonConfigurationIsNil"] = b5.configuration == nil
        let b6 = UIButton(type: .system)
        rows["systemButtonConfigurationIsNil"] = b6.configuration == nil

        // background stroke, exactly as KDS assigns it.
        var stroked = UIButton.Configuration.bordered()
        stroked.title = "Configure"
        stroked.background.backgroundColor = .white
        stroked.background.strokeColor = .systemRed
        stroked.background.strokeWidth = 2
        stroked.background.cornerRadius = 6
        stroked.cornerStyle = .fixed
        let b7 = UIButton(configuration: stroked)
        var r7: [String: Any] = [:]
        hosted(b7, width: 160, height: 44) { b in
            r7["tree"] = dumpTree(b)
            if let p = renderPixels(b) {
                r7["midRow"] = scanline(p, y: p.h / 2)
                r7["midColumn"] = (0..<p.h).map { pixel(p, p.w / 2, $0) }
                r7["topLeftCorner"] = cornerProfile(p, rows: 12)
            }
        }
        rows["backgroundStroke"] = r7
        out["misc"] = rows
    }

    // 13. Explicit base colours under each state -- the exact question KDS's
    // `updateColors` + `titleTextAttributesTransformer` workaround turns on.
    func explicitColorsPerState() {
        var rows: [String: Any] = [:]
        func sweep(_ name: String, _ make: @escaping () -> UIButton.Configuration) {
            var perState: [String: Any] = [:]
            for stateName in ["normal", "highlighted", "disabled"] {
                let button = UIButton(configuration: make())
                switch stateName {
                case "highlighted": button.isHighlighted = true
                case "disabled": button.isEnabled = false
                default: break
                }
                var r: [String: Any] = [:]
                hosted(button, width: 160, height: 44) { b in
                    if let label = b.titleLabel {
                        r["titleColor"] = colorPair(label.textColor)
                        r["titleFont"] = "\(label.font.fontName)@\(f(label.font.pointSize))"
                    }
                    r["configBackgroundColor"] =
                        colorPair(b.configuration?.background.backgroundColor)
                    r["configStrokeColor"] = colorPair(b.configuration?.background.strokeColor)
                    r["configStrokeWidth"] = f(b.configuration?.background.strokeWidth ?? -1)
                    r["strokeViews"] = b.subviews.flatMap { $0.subviews }.map {
                        ["class": String(describing: type(of: $0)),
                         "borderWidth": f($0.layer.borderWidth),
                         "borderColor": $0.layer.borderColor
                            .map { c in rgba(UIColor(cgColor: c), lightTraits) ?? "?" } ?? "nil",
                         "bg": $0.layer.backgroundColor
                            .map { c in rgba(UIColor(cgColor: c), lightTraits) ?? "?" } ?? "nil",
                        ] as [String: Any]
                    }
                    if let p = renderPixels(b) {
                        r["fillAt4_22"] = pixel(p, 4, 22)
                        r["edgeAt0_22"] = pixel(p, 0, 22)
                    }
                }
                perState[stateName] = r
            }
            rows[name] = perState
        }

        // (a) baseForegroundColor alone.
        sweep("filled_baseForeground") {
            var c = UIButton.Configuration.filled()
            c.title = "Configure"
            c.baseForegroundColor = .systemGreen
            return c
        }
        // (b) KDS's workaround: the transformer forces foregroundColor from
        //     the configuration's own baseForegroundColor.
        sweep("filled_baseForeground_transformer") {
            var c = UIButton.Configuration.filled()
            c.title = "Configure"
            c.baseForegroundColor = .systemGreen
            let forced = UIColor.systemGreen
            c.titleTextAttributesTransformer =
                UIConfigurationTextAttributesTransformer { incoming in
                    var out = incoming
                    out[AttributeScopes.UIKitAttributes.FontAttribute.self] =
                        UIFont.systemFont(ofSize: 19, weight: .medium)
                    out[AttributeScopes.UIKitAttributes.ForegroundColorAttribute.self] = forced
                    return out
                }
            return c
        }
        // (c) baseBackgroundColor alone.
        sweep("filled_baseBackground") {
            var c = UIButton.Configuration.filled()
            c.title = "Configure"
            c.baseBackgroundColor = .systemRed
            return c
        }
        // (d) an explicit background.backgroundColor, as KDS assigns per state.
        sweep("filled_explicitBackground") {
            var c = UIButton.Configuration.filled()
            c.title = "Configure"
            c.background.backgroundColor = .systemRed
            return c
        }
        // (e) explicit stroke on a bordered configuration, as KDS assigns.
        sweep("bordered_explicitStroke") {
            var c = UIButton.Configuration.bordered()
            c.title = "Configure"
            c.background.backgroundColor = .white
            c.background.strokeColor = .systemRed
            c.background.strokeWidth = 2
            return c
        }
        // (f) plain with an explicit background colour: does a fill appear?
        sweep("plain_explicitBackground") {
            var c = UIButton.Configuration.plain()
            c.title = "Configure"
            c.background.backgroundColor = .systemRed
            return c
        }
        out["explicitColorsPerState"] = rows
    }
}

private extension UILabel {
    var pointSizeShim: CGFloat { font.pointSize }
}

// MARK: - Driver

@MainActor
func runProbe() {
    let window = UIWindow(frame: UIScreen.main.bounds)
    window.overrideUserInterfaceStyle = .light
    window.rootViewController = UIViewController()
    window.makeKeyAndVisible()
    window.rootViewController?.view.backgroundColor = .white

    let probe = Probe(window: window)
    probe.out["meta"] = [
        "device": UIDevice.current.model,
        "systemVersion": UIDevice.current.systemVersion,
        "scale": f(UIScreen.main.scale),
        "bounds": rect(UIScreen.main.bounds),
    ]
    let steps: [(String, () -> Void)] = [
        ("factories", probe.factories),
        ("factoryLayout", probe.factoryLayout),
        ("statesPerFactory", probe.statesPerFactory),
        ("cornerStyles", probe.cornerStyles),
        ("buttonSizes", probe.buttonSizes),
        ("contentInsetsSweep", probe.contentInsetsSweep),
        ("imagePlacement", probe.imagePlacement),
        ("titles", probe.titles),
        ("transformers", probe.transformers),
        ("updateHandler", probe.updateHandler),
        ("updatedFor", probe.updatedFor),
        ("misc", probe.misc),
        ("explicitColorsPerState", probe.explicitColorsPerState),
    ]
    var completed: [String] = []
    for (name, step) in steps {
        step()
        completed.append(name)
        // Checkpoint after every step so a crash still yields what ran.
        probe.out["completedSteps"] = completed
        write(probe.out)
    }
    write(probe.out)
    let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    FileManager.default.createFile(atPath: docs.appendingPathComponent("done.marker").path,
                                   contents: Data())
}

func write(_ object: [String: Any]) {
    let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    let url = docs.appendingPathComponent("uibutton-configuration.json")
    guard let data = try? JSONSerialization.data(
        withJSONObject: object, options: [.prettyPrinted, .sortedKeys]) else {
        try? Data("SERIALIZATION FAILED".utf8).write(to: url)
        return
    }
    try? data.write(to: url)
}

final class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions:
                        [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        MainActor.assumeIsolated { runProbe() }
        return true
    }
}

UIApplicationMain(CommandLine.argc, CommandLine.unsafeArgv, nil,
                  NSStringFromClass(AppDelegate.self))
