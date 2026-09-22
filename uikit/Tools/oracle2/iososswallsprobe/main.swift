// ios-oss launch pass 2 oracle: the UIKit members Kickstarter-Prelude's
// lens protocols and the Kickstarter design system (KDS) require.
//
// Run as a command-line binary on a private iPhone 16 / iOS 26.1 simulator
// (`scripts/iososs_walls_probe_sim.sh`). Prints one `key=value` line per
// measurement; the runner stores them verbatim in
// docs/agent_reports/ios-oss-launch2-walls-oracle-ios26.1.json.
//
// Families:
//   lens.*    Prelude_UIKit lens-protocol members (UIButton background images,
//             UIControl target introspection, font/textColor nullability,
//             UIScrollView.scrollIndicatorInsets, UIStackView, UITabBar,
//             UIProgressView, UIActivityIndicatorView, UITableViewController,
//             UIGraphicsBeginImageContext).
//   config.*  UIButton.Configuration defaults per style, UIBackgroundConfiguration
//             defaults inside it, and when configurationUpdateHandler runs.
//   fontdesc.* UIFontDescriptor attribute names / keys and what addingAttributes
//             does to the resulting font.
//   ct.*      CoreText SFNT feature constants and CTFontManagerRegisterFontsForURL
//             with the app's own Inter variable fonts, then UIFont(name:size:).
//   cgcolor.* component count per UIColor constant / semantic colour.
//   misc.*    UIAccessibility.isBoldTextEnabled, UIDevice.identifierForVendor.
import UIKit
import CoreText

func out(_ key: String, _ value: Any?) {
    if let value { print("\(key)=\(value)") } else { print("\(key)=nil") }
}

func insets(_ i: NSDirectionalEdgeInsets) -> String {
    "(\(i.top), \(i.leading), \(i.bottom), \(i.trailing))"
}

func colorDesc(_ c: UIColor?) -> String {
    guard let c else { return "nil" }
    var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
    let resolved = c.resolvedColor(with: UITraitCollection(userInterfaceStyle: .light))
    resolved.getRed(&r, green: &g, blue: &b, alpha: &a)
    return String(format: "rgba(%.4f,%.4f,%.4f,%.4f)", r, g, b, a)
}

func fontDesc(_ f: UIFont?) -> String {
    guard let f else { return "nil" }
    return "\(f.fontName)|\(f.familyName)|\(f.pointSize)"
}

final class Target: NSObject {
    @objc func tap(_ sender: Any) {}
    @objc func other() {}
}

@MainActor
func lens() {
    for (name, type) in [("system", UIButton.ButtonType.system), ("custom", .custom)] {
        let b = UIButton(type: type)
        out("lens.button.\(name).adjustsImageWhenHighlighted", b.adjustsImageWhenHighlighted)
        out("lens.button.\(name).adjustsImageWhenDisabled", b.adjustsImageWhenDisabled)
        out("lens.button.\(name).backgroundImage.normal", b.backgroundImage(for: .normal) as Any?)
    }
    let b = UIButton(type: .custom)
    let img = UIGraphicsImageRenderer(size: CGSize(width: 2, height: 3)).image { _ in }
    b.setBackgroundImage(img, for: .normal)
    out("lens.button.bg.normal.isSame", b.backgroundImage(for: .normal) === img)
    out("lens.button.bg.highlighted.isSame", b.backgroundImage(for: .highlighted) === img)
    out("lens.button.bg.highlighted.isNil", b.backgroundImage(for: .highlighted) == nil)
    out("lens.button.bg.disabled.isNil", b.backgroundImage(for: .disabled) == nil)
    out("lens.button.bg.selected.isNil", b.backgroundImage(for: .selected) == nil)
    out("lens.button.bg.current.isSame", b.currentBackgroundImage === img)
    b.isHighlighted = true
    out("lens.button.bg.currentWhileHighlighted.isSame", b.currentBackgroundImage === img)
    b.isHighlighted = false
    b.setBackgroundImage(nil, for: .normal)
    out("lens.button.bg.afterNil.isNil", b.backgroundImage(for: .normal) == nil)

    let c = UIControl()
    out("lens.control.allTargets.count", c.allTargets.count)
    let t = Target()
    c.addTarget(t, action: #selector(Target.tap(_:)), for: .touchUpInside)
    out("lens.control.allTargets.afterAdd.count", c.allTargets.count)
    out("lens.control.allTargets.containsTarget", c.allTargets.contains(t))
    out("lens.control.actions.touchUpInside", c.actions(forTarget: t, forControlEvent: .touchUpInside) as Any?)
    out("lens.control.actions.valueChanged", c.actions(forTarget: t, forControlEvent: .valueChanged) as Any?)
    c.addTarget(t, action: #selector(Target.other), for: .touchUpInside)
    out("lens.control.actions.touchUpInside.two", c.actions(forTarget: t, forControlEvent: .touchUpInside) as Any?)
    out("lens.control.allTargets.sameTargetTwice.count", c.allTargets.count)
    c.addTarget(nil, action: #selector(Target.other), for: .valueChanged)
    out("lens.control.allTargets.withNil.count", c.allTargets.count)
    out("lens.control.allTargets.withNil.containsNSNull", c.allTargets.contains(NSNull()))
    out("lens.control.actions.nilTarget.valueChanged", c.actions(forTarget: nil, forControlEvent: .valueChanged) as Any?)
    let other = Target()
    out("lens.control.actions.otherTarget", c.actions(forTarget: other, forControlEvent: .touchUpInside) as Any?)

    let label = UILabel()
    out("lens.label.font.default", fontDesc(label.font))
    label.font = nil
    out("lens.label.font.afterNil", fontDesc(label.font))
    out("lens.label.textAlignment.default", label.textAlignment.rawValue)

    let field = UITextField()
    out("lens.textField.font.default", fontDesc(field.font))
    field.font = UIFont.systemFont(ofSize: 30)
    field.font = nil
    out("lens.textField.font.afterNil", fontDesc(field.font))
    out("lens.textField.textAlignment.default", field.textAlignment.rawValue)

    let tv = UITextView()
    out("lens.textView.font.default", fontDesc(tv.font))
    out("lens.textView.textColor.default", colorDesc(tv.textColor))
    tv.text = "abc"
    out("lens.textView.font.afterText", fontDesc(tv.font))
    out("lens.textView.textColor.afterText", colorDesc(tv.textColor))
    tv.font = UIFont.systemFont(ofSize: 30)
    tv.font = nil
    out("lens.textView.font.afterNil", fontDesc(tv.font))
    tv.textColor = .red
    tv.textColor = nil
    out("lens.textView.textColor.afterNil", colorDesc(tv.textColor))
    out("lens.textView.isSecureTextEntry.default", tv.isSecureTextEntry)
    out("lens.textView.textAlignment.default", tv.textAlignment.rawValue)
    let tv2 = UITextView()
    out("lens.textView2.font.defaultBeforeText", fontDesc(tv2.font))

    let sv = UIScrollView()
    out("lens.scroll.scrollIndicatorInsets.default", sv.scrollIndicatorInsets)
    sv.scrollIndicatorInsets = UIEdgeInsets(top: 1, left: 2, bottom: 3, right: 4)
    out("lens.scroll.afterSet.vertical", sv.verticalScrollIndicatorInsets)
    out("lens.scroll.afterSet.horizontal", sv.horizontalScrollIndicatorInsets)
    sv.verticalScrollIndicatorInsets = UIEdgeInsets(top: 5, left: 6, bottom: 7, right: 8)
    out("lens.scroll.afterVertical.scrollIndicatorInsets", sv.scrollIndicatorInsets)
    sv.horizontalScrollIndicatorInsets = UIEdgeInsets(top: 9, left: 10, bottom: 11, right: 12)
    out("lens.scroll.afterHorizontal.scrollIndicatorInsets", sv.scrollIndicatorInsets)

    out("lens.stack.isBaselineRelativeArrangement.default", UIStackView().isBaselineRelativeArrangement)
    out("lens.tabBar.barTintColor.default", colorDesc(UITabBar().barTintColor))

    out("lens.progress.style.raws", [UIProgressView.Style.default.rawValue, UIProgressView.Style.bar.rawValue])
    out("lens.progress.style.default", UIProgressView().progressViewStyle.rawValue)
    out("lens.progress.style.initBar", UIProgressView(progressViewStyle: .bar).progressViewStyle.rawValue)
    let pv = UIProgressView()
    pv.progressViewStyle = .bar
    out("lens.progress.style.setBar", pv.progressViewStyle.rawValue)

    let ai = UIActivityIndicatorView(style: .medium)
    out("lens.activity.medium.style", ai.style.rawValue)
    out("lens.activity.medium.color", colorDesc(ai.color))
    ai.style = .large
    out("lens.activity.setLarge.style", ai.style.rawValue)
    out("lens.activity.setLarge.color", colorDesc(ai.color))
    ai.color = .red
    ai.style = .medium
    out("lens.activity.redThenMedium.color", colorDesc(ai.color))
    ai.color = nil
    out("lens.activity.afterNil.color", colorDesc(ai.color))
    out("lens.activity.style.raws", [UIActivityIndicatorView.Style.medium.rawValue,
                                     UIActivityIndicatorView.Style.large.rawValue])

    let tvc = UITableViewController(style: .plain)
    let replacement = UITableView(frame: .zero, style: .grouped)
    tvc.tableView = replacement
    out("lens.tvc.setTableView.tableViewIsSame", tvc.tableView === replacement)
    out("lens.tvc.setTableView.viewIsSame", tvc.view === replacement)

    let px = CGRect(x: 0, y: 0, width: 1, height: 1)
    UIGraphicsBeginImageContext(px.size)
    let ctx = UIGraphicsGetCurrentContext()
    out("lens.imageContext.hasContext", ctx != nil)
    ctx?.setFillColor(UIColor(red: 1, green: 0, blue: 0, alpha: 1).cgColor)
    ctx?.fill(px)
    let pixel = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    out("lens.imageContext.size", pixel?.size as Any?)
    out("lens.imageContext.scale", pixel?.scale as Any?)
    if let cg = pixel?.cgImage, let data = cg.dataProvider?.data, let p = CFDataGetBytePtr(data) {
        out("lens.imageContext.pixel", "\(p[0]),\(p[1]),\(p[2]),\(p[3]) bpp=\(cg.bitsPerPixel) info=\(cg.bitmapInfo.rawValue)")
    }
    UIGraphicsBeginImageContext(px.size)
    let unfilled = UIGraphicsGetImageFromCurrentImageContext()
    let ctx2 = UIGraphicsGetCurrentContext()
    ctx2?.fill(px)
    let blackFilled = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    if let cg = unfilled?.cgImage, let data = cg.dataProvider?.data, let p = CFDataGetBytePtr(data) {
        out("lens.imageContext.unfilledPixel", "\(p[0]),\(p[1]),\(p[2]),\(p[3])")
    }
    if let cg = blackFilled?.cgImage, let data = cg.dataProvider?.data, let p = CFDataGetBytePtr(data) {
        out("lens.imageContext.defaultFillPixel", "\(p[0]),\(p[1]),\(p[2]),\(p[3])")
    }
    out("lens.afterEnd.hasContext", UIGraphicsGetCurrentContext() != nil)
}

@MainActor
func config() {
    let styles: [(String, UIButton.Configuration)] = [
        ("plain", .plain()), ("tinted", .tinted()), ("gray", .gray()), ("filled", .filled()),
        ("borderless", .borderless()), ("bordered", .bordered()),
        ("borderedTinted", .borderedTinted()), ("borderedProminent", .borderedProminent()),
    ]
    for (name, c) in styles {
        let k = "config.\(name)"
        out("\(k).contentInsets", insets(c.contentInsets))
        out("\(k).imagePadding", c.imagePadding)
        out("\(k).titlePadding", c.titlePadding)
        out("\(k).imagePlacement", c.imagePlacement.rawValue)
        out("\(k).titleAlignment", "\(c.titleAlignment)")
        out("\(k).titleLineBreakMode", c.titleLineBreakMode.rawValue)
        out("\(k).cornerStyle", "\(c.cornerStyle)")
        out("\(k).buttonSize", "\(c.buttonSize)")
        out("\(k).baseForegroundColor", colorDesc(c.baseForegroundColor))
        out("\(k).baseBackgroundColor", colorDesc(c.baseBackgroundColor))
        out("\(k).background.backgroundColor", colorDesc(c.background.backgroundColor))
        out("\(k).background.cornerRadius", c.background.cornerRadius)
        out("\(k).background.strokeColor", colorDesc(c.background.strokeColor))
        out("\(k).background.strokeWidth", c.background.strokeWidth)
        out("\(k).background.strokeOutset", c.background.strokeOutset)
        out("\(k).showsActivityIndicator", c.showsActivityIndicator)
        out("\(k).title", c.title)
        out("\(k).image.isNil", c.image == nil)
        out("\(k).titleTextAttributesTransformer.isNil", c.titleTextAttributesTransformer == nil)
        out("\(k).imageColorTransformer.isNil", c.imageColorTransformer == nil)
    }
    out("config.imagePlacement.raws", [NSDirectionalRectEdge.leading.rawValue, NSDirectionalRectEdge.trailing.rawValue,
                                       NSDirectionalRectEdge.top.rawValue, NSDirectionalRectEdge.bottom.rawValue])
    // Update handler timing.
    let b = UIButton(type: .system)
    var calls = 0
    var states: [UInt] = []
    b.configurationUpdateHandler = { btn in calls += 1; states.append(btn.state.rawValue) }
    out("config.handler.afterAssign.calls", calls)
    b.configuration = .filled()
    out("config.handler.afterConfiguration.calls", calls)
    b.setNeedsUpdateConfiguration()
    out("config.handler.afterSetNeeds.calls", calls)
    b.frame = CGRect(x: 0, y: 0, width: 100, height: 44)
    b.layoutIfNeeded()
    out("config.handler.afterLayout.calls", calls)
    b.isEnabled = false
    out("config.handler.afterDisable.calls", calls)
    b.layoutIfNeeded()
    out("config.handler.afterDisableLayout.calls", calls)
    b.updateConfiguration()
    out("config.handler.afterUpdateConfiguration.calls", calls)
    b.isHighlighted = true
    out("config.handler.afterHighlight.calls", calls)
    b.layoutIfNeeded()
    out("config.handler.afterHighlightLayout.calls", calls)
    out("config.handler.states", states)
    RunLoop.main.run(until: Date().addingTimeInterval(0.2))
    out("config.handler.afterRunLoop.calls", calls)

    // Handler writes a new configuration while running (the KDS shape).
    let b2 = UIButton(type: .system)
    var calls2 = 0
    b2.configuration = .filled()
    b2.configurationUpdateHandler = { btn in
        calls2 += 1
        var c = btn.configuration
        c?.baseForegroundColor = .red
        btn.configuration = c
    }
    b2.frame = CGRect(x: 0, y: 0, width: 100, height: 44)
    b2.layoutIfNeeded()
    out("config.reentrant.afterLayout.calls", calls2)
    b2.layoutIfNeeded()
    out("config.reentrant.afterSecondLayout.calls", calls2)
    out("config.reentrant.foreground", colorDesc(b2.configuration?.baseForegroundColor))

    // Transformers are invoked with what.
    var attrIn: String = ""
    var c3 = UIButton.Configuration.filled()
    c3.title = "Next"
    c3.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { a in
        attrIn = "font=\(fontDesc(a.font)) fg=\(colorDesc(a.foregroundColor))"
        var n = a
        n.font = UIFont.systemFont(ofSize: 20)
        return n
    }
    let b3 = UIButton(configuration: c3)
    b3.frame = CGRect(x: 0, y: 0, width: 100, height: 44)
    b3.layoutIfNeeded()
    out("config.transformer.input", attrIn)
    out("config.transformer.titleLabelFont", fontDesc(b3.titleLabel?.font))
    out("config.filled.titleLabelColor", colorDesc(b3.titleLabel?.textColor))
    out("config.filled.intrinsic", b3.intrinsicContentSize)

    let b4 = UIButton(configuration: .filled())
    b4.setTitle("Next", for: .normal)
    b4.frame = CGRect(x: 0, y: 0, width: 200, height: 44)
    b4.layoutIfNeeded()
    out("config.filledSetTitle.titleLabelFont", fontDesc(b4.titleLabel?.font))
    out("config.filledSetTitle.configTitle", b4.configuration?.title)
}

@MainActor
func fontDescriptors() {
    out("fontdesc.attr.featureSettings", UIFontDescriptor.AttributeName.featureSettings.rawValue)
    out("fontdesc.attr.traits", UIFontDescriptor.AttributeName.traits.rawValue)
    out("fontdesc.attr.family", UIFontDescriptor.AttributeName.family.rawValue)
    out("fontdesc.attr.name", UIFontDescriptor.AttributeName.name.rawValue)
    out("fontdesc.attr.size", UIFontDescriptor.AttributeName.size.rawValue)
    out("fontdesc.attr.textStyle", UIFontDescriptor.AttributeName.textStyle.rawValue)
    out("fontdesc.feature.type", UIFontDescriptor.FeatureKey.type.rawValue)
    out("fontdesc.feature.selector", UIFontDescriptor.FeatureKey.selector.rawValue)
    out("fontdesc.trait.weight", UIFontDescriptor.TraitKey.weight.rawValue)
    out("fontdesc.trait.symbolic", UIFontDescriptor.TraitKey.symbolic.rawValue)
    out("fontdesc.trait.width", UIFontDescriptor.TraitKey.width.rawValue)
    out("fontdesc.trait.slant", UIFontDescriptor.TraitKey.slant.rawValue)
    out("fontdesc.weight.raws", [UIFont.Weight.ultraLight, .thin, .light, .regular, .medium, .semibold, .bold, .heavy, .black].map { $0.rawValue })

    let base = UIFont.systemFont(ofSize: 17)
    let weighted = UIFont(descriptor: base.fontDescriptor.addingAttributes([
        .traits: [UIFontDescriptor.TraitKey.weight: UIFont.Weight.bold]
    ]), size: 0)
    out("fontdesc.weighted.bold", fontDesc(weighted))
    out("fontdesc.weighted.bold.isBoldSystem", weighted == UIFont.systemFont(ofSize: 17, weight: .bold))
    let wSemi = UIFont(descriptor: base.fontDescriptor.addingAttributes([
        .traits: [UIFontDescriptor.TraitKey.weight: UIFont.Weight.semibold]
    ]), size: 0)
    out("fontdesc.weighted.semibold", fontDesc(wSemi))
    out("fontdesc.weighted.semibold.lineHeight", wSemi.lineHeight)
    out("fontdesc.semibold17.lineHeight", UIFont.systemFont(ofSize: 17, weight: .semibold).lineHeight)
    let mono = UIFont(descriptor: base.fontDescriptor.addingAttributes([
        .featureSettings: [[UIFontDescriptor.FeatureKey.type: kNumberSpacingType,
                            UIFontDescriptor.FeatureKey.selector: kMonospacedNumbersSelector]]
    ]), size: 0)
    out("fontdesc.monospaced", fontDesc(mono))
    out("fontdesc.monospaced.lineHeight", mono.lineHeight)
    let digits = "0123456789" as NSString
    out("fontdesc.digitsWidth.base", digits.size(withAttributes: [.font: base]).width)
    out("fontdesc.digitsWidth.monospaced", digits.size(withAttributes: [.font: mono]).width)
    out("fontdesc.digit1Width.base", ("1" as NSString).size(withAttributes: [.font: base]).width)
    out("fontdesc.digit1Width.monospaced", ("1" as NSString).size(withAttributes: [.font: mono]).width)
    out("fontdesc.monospacedDigitSystemFont.digit1Width",
        ("1" as NSString).size(withAttributes: [.font: UIFont.monospacedDigitSystemFont(ofSize: 17, weight: .regular)]).width)
    let bold = base.fontDescriptor.withSymbolicTraits(.traitBold).map { UIFont(descriptor: $0, size: 0) }
    out("fontdesc.withBold", fontDesc(bold))
    let sized = UIFont(descriptor: base.fontDescriptor, size: 24)
    out("fontdesc.resize24", fontDesc(sized))
    let preferred = UIFont.preferredFont(forTextStyle: .headline, compatibleWith: .current)
    out("fontdesc.preferred.headline", fontDesc(preferred))
    out("fontdesc.fromPreferred.ceil", fontDesc(UIFont(descriptor: preferred.fontDescriptor, size: 20)))
    out("fontdesc.base.attributes.keys", base.fontDescriptor.fontAttributes.keys.map { $0.rawValue }.sorted())
}

@MainActor
func coreText(fontDir: String) {
    out("ct.kNumberSpacingType", kNumberSpacingType)
    out("ct.kMonospacedNumbersSelector", kMonospacedNumbersSelector)
    out("ct.kProportionalNumbersSelector", kProportionalNumbersSelector)
    out("ct.kStylisticAlternativesType", kStylisticAlternativesType)
    out("ct.kStylisticAltOneOnSelector", kStylisticAltOneOnSelector)
    out("ct.kStylisticAltTwoOnSelector", kStylisticAltTwoOnSelector)
    out("ct.scope.process", CTFontManagerScope.process.rawValue)
    let names = ["Inter-Regular", "Inter-Regular_Medium", "Inter-Regular_SemiBold", "Inter-Regular_Bold",
                 "Inter-Regular_ExtraBold", "Inter-SemiBold", "Inter-Italic", "Inter", "Inter-Medium"]
    for n in names { out("ct.before.\(n)", fontDesc(UIFont(name: n, size: 16))) }
    for file in ["Inter-Italic-VariableFont", "Inter-VariableFont"] {
        let url = URL(fileURLWithPath: fontDir).appendingPathComponent(file + ".ttf")
        var err: Unmanaged<CFError>?
        let ok = CTFontManagerRegisterFontsForURL(url as CFURL, .process, &err)
        out("ct.register.\(file)", ok)
        out("ct.register.\(file).error", err.map { CFErrorGetCode($0.takeRetainedValue()) })
    }
    let url = URL(fileURLWithPath: fontDir).appendingPathComponent("Inter-VariableFont.ttf")
    var err2: Unmanaged<CFError>?
    out("ct.registerAgain", CTFontManagerRegisterFontsForURL(url as CFURL, .process, &err2))
    out("ct.registerAgain.error", err2.map { CFErrorGetCode($0.takeRetainedValue()) })
    var err3: Unmanaged<CFError>?
    out("ct.registerMissing", CTFontManagerRegisterFontsForURL(URL(fileURLWithPath: "/nonexistent.ttf") as CFURL, .process, &err3))
    out("ct.registerMissing.error", err3.map { CFErrorGetCode($0.takeRetainedValue()) })
    for n in names {
        let f = UIFont(name: n, size: 16)
        out("ct.after.\(n)", fontDesc(f))
        if let f {
            out("ct.after.\(n).metrics", "asc=\(f.ascender) desc=\(f.descender) leading=\(f.leading) line=\(f.lineHeight) cap=\(f.capHeight) x=\(f.xHeight)")
            out("ct.after.\(n).width.Next", ("Next" as NSString).size(withAttributes: [.font: f]).width)
            let scaled = UIFontMetrics(forTextStyle: .headline).scaledFont(for: f, compatibleWith: .current)
            out("ct.after.\(n).scaledHeadline", fontDesc(scaled))
        }
    }
    out("ct.familyNames.inter", UIFont.familyNames.filter { $0.hasPrefix("Inter") })
    out("ct.fontNames.inter", UIFont.fontNames(forFamilyName: "Inter").sorted())
}

@MainActor
func colors() {
    let named: [(String, UIColor)] = [
        ("white", .white), ("black", .black), ("clear", .clear), ("gray", .gray), ("lightGray", .lightGray),
        ("darkGray", .darkGray), ("red", .red), ("green", .green), ("blue", .blue), ("yellow", .yellow),
        ("orange", .orange), ("purple", .purple), ("cyan", .cyan), ("magenta", .magenta), ("brown", .brown),
        ("white0.5", UIColor(white: 0.5, alpha: 1)), ("rgb", UIColor(red: 0.2, green: 0.4, blue: 0.6, alpha: 0.8)),
        ("hsb", UIColor(hue: 0, saturation: 1, brightness: 1, alpha: 1)),
        ("label", .label), ("secondaryLabel", .secondaryLabel), ("tertiaryLabel", .tertiaryLabel),
        ("quaternaryLabel", .quaternaryLabel), ("systemBackground", .systemBackground),
        ("secondarySystemBackground", .secondarySystemBackground), ("tertiarySystemBackground", .tertiarySystemBackground),
        ("systemGroupedBackground", .systemGroupedBackground), ("separator", .separator), ("opaqueSeparator", .opaqueSeparator),
        ("link", .link), ("placeholderText", .placeholderText), ("systemFill", .systemFill),
        ("systemGray", .systemGray), ("systemGray6", .systemGray6), ("systemBlue", .systemBlue), ("systemRed", .systemRed),
        ("lightText", .lightText), ("darkText", .darkText), ("white.alpha0.5", UIColor.white.withAlphaComponent(0.5)),
        ("red.alpha0.5", UIColor.red.withAlphaComponent(0.5)),
    ]
    let light = UITraitCollection(userInterfaceStyle: .light)
    let dark = UITraitCollection(userInterfaceStyle: .dark)
    for (name, c) in named {
        for (mode, t) in [("light", light), ("dark", dark)] {
            let cg = c.resolvedColor(with: t).cgColor
            let comps = (cg.components ?? []).map { String(format: "%.5g", $0) }
            out("cgcolor.\(mode).\(name)", "n=\(cg.numberOfComponents) comps=\(comps) model=\(cg.colorSpace?.model.rawValue ?? -99)")
        }
    }
    let direct = UIColor.white.cgColor
    out("cgcolor.direct.white", "n=\(direct.numberOfComponents) model=\(direct.colorSpace?.model.rawValue ?? -99)")
    out("cgcolor.CGColor.init.gray", CGColor(gray: 0.3, alpha: 1).numberOfComponents)
    out("cgcolor.CGColor.init.rgb", CGColor(red: 1, green: 1, blue: 1, alpha: 1).numberOfComponents)
    out("cgcolor.whiteEqualsRGBWhite", UIColor.white == UIColor(red: 1, green: 1, blue: 1, alpha: 1))
    out("cgcolor.cgWhiteEqualsRGBWhite", UIColor.white.cgColor == UIColor(red: 1, green: 1, blue: 1, alpha: 1).cgColor)
}

@MainActor
func scrollInsets() {
    let sv = UIScrollView()
    sv.scrollIndicatorInsets = UIEdgeInsets(top: 1, left: 2, bottom: 3, right: 4)
    out("scroll2.afterSet.scrollIndicatorInsets", sv.scrollIndicatorInsets)
    sv.verticalScrollIndicatorInsets = UIEdgeInsets(top: 5, left: 6, bottom: 7, right: 8)
    out("scroll2.afterVertical.scrollIndicatorInsets", sv.scrollIndicatorInsets)
    sv.horizontalScrollIndicatorInsets = UIEdgeInsets(top: 5, left: 6, bottom: 7, right: 8)
    out("scroll2.bothEqual.scrollIndicatorInsets", sv.scrollIndicatorInsets)
    sv.scrollIndicatorInsets = UIEdgeInsets(top: 9, left: 9, bottom: 9, right: 9)
    out("scroll2.reset.scrollIndicatorInsets", sv.scrollIndicatorInsets)
    let sv2 = UIScrollView()
    sv2.verticalScrollIndicatorInsets = UIEdgeInsets(top: 1, left: 1, bottom: 1, right: 1)
    out("scroll2.onlyVertical.scrollIndicatorInsets", sv2.scrollIndicatorInsets)
}

func dumpTree(_ v: UIView, _ path: String, _ key: String) {
    let bg = v.backgroundColor.map { colorDesc($0) } ?? "nil"
    let border = v.layer.borderColor.map { colorDesc(UIColor(cgColor: $0)) } ?? "nil"
    var extra = ""
    if let l = v as? UILabel {
        extra = " text=\(l.text ?? "nil") font=\(fontDesc(l.font)) color=\(colorDesc(l.textColor)) lines=\(l.numberOfLines) align=\(l.textAlignment.rawValue) lbm=\(l.lineBreakMode.rawValue)"
    }
    out("\(key).\(path)", "\(type(of: v)) frame=\(v.frame) radius=\(v.layer.cornerRadius) curve=\(v.layer.cornerCurve.rawValue) bg=\(bg) borderW=\(v.layer.borderWidth) border=\(border) clips=\(v.clipsToBounds)\(extra)")
    for (i, s) in v.subviews.enumerated() { dumpTree(s, "\(path).\(i)", key) }
}

@MainActor
func configRender() {
    func build(_ key: String, width: CGFloat = 200, height: CGFloat = 48, _ mutate: (inout UIButton.Configuration) -> Void) {
        var c = UIButton.Configuration.filled()
        c.title = "Next"
        mutate(&c)
        let b = UIButton(configuration: c)
        out("\(key).intrinsic", b.intrinsicContentSize)
        b.frame = CGRect(x: 0, y: 0, width: width, height: height)
        b.layoutIfNeeded()
        dumpTree(b, "0", key)
    }
    build("render.filledDefault") { _ in }
    build("render.filledRadius4") { $0.background.cornerRadius = 4 }
    build("render.fixedRadius4") { $0.cornerStyle = .fixed; $0.background.cornerRadius = 4 }
    build("render.smallStyle") { $0.cornerStyle = .small }
    build("render.capsule") { $0.cornerStyle = .capsule }
    build("render.redBg") { $0.background.backgroundColor = .red }
    build("render.stroke") { $0.background.strokeColor = .blue; $0.background.strokeWidth = 2 }
    build("render.baseFg") { $0.baseForegroundColor = .red }
    build("render.baseBg") { $0.baseBackgroundColor = .red }
    build("render.insets12") { $0.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 12) }
    build("render.wrap", width: 120, height: 80) {
        $0.title = "A long title that needs to wrap"
        $0.titleLineBreakMode = .byWordWrapping
        $0.titleAlignment = .center
    }
    build("render.borderless") { c in c = .borderless(); c.title = "Next" }
    build("render.bordered") { c in c = .bordered(); c.title = "Next" }
    build("render.plain") { c in c = .plain(); c.title = "Next" }
    // KDS shape: filled + small corner radius + explicit colours + font transformer.
    build("render.kds") { c in
        c.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 12)
        c.background.cornerRadius = 8
        c.imagePadding = 6
        c.imagePlacement = .leading
        c.titleLineBreakMode = .byWordWrapping
        c.titleAlignment = .center
        c.background.backgroundColor = UIColor(red: 30/255, green: 30/255, blue: 30/255, alpha: 1)
        c.baseForegroundColor = .white
        c.background.strokeColor = .clear
        c.background.strokeWidth = 0
        c.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { a in
            var n = a
            n.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
            return n
        }
    }
    // Disabled filled.
    let d = UIButton(configuration: .filled())
    d.configuration?.title = "Next"
    d.isEnabled = false
    d.frame = CGRect(x: 0, y: 0, width: 200, height: 48)
    d.layoutIfNeeded()
    dumpTree(d, "0", "render.disabledFilled")
}

@MainActor
func misc() {
    out("misc.isBoldTextEnabled", UIAccessibility.isBoldTextEnabled)
    out("misc.identifierForVendor.isNil", UIDevice.current.identifierForVendor == nil)
}

let fontDir = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "."
MainActor.assumeIsolated {
    lens()
    config()
    fontDescriptors()
    colors()
    scrollInsets()
    configRender()
    misc()
    coreText(fontDir: fontDir)
}
print("done=1")
