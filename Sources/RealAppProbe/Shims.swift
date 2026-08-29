// SHIMS — everything in this file is NOT pocket-casts source.
//
// The point of Sources/RealAppProbe is to measure how much of a REAL app
// screen compiles and renders against OpenUIKit. That measurement is only
// meaningful if the thing under test is the UIKit surface, so the app's own
// infrastructure (its 11-theme colour system, its Dynamic Type font helper,
// its analytics, its settings store) is replaced here by the smallest thing
// that type-checks and produces the same pixels for the ONE configuration the
// harness renders.
//
// Rules for this file, so the report stays honest:
//   * every shim states what it replaces and where the real one lives;
//   * colour shims carry the exact hex from the app's own theme table
//     (pocket-casts-ios/scripts/themes/theme.csv), so the render is the app's
//     real colours, not invented ones;
//   * NOTHING here stands in for a UIKit symbol. A missing UIKit symbol is
//     either implemented in Sources/OpenUIKit or recorded as blocked in
//     docs/REAL_APP_TEST.md. If it were shimmed here the measurement would be
//     circular.
//
// Line count of this file is reported alongside the vendored line count.

import OpenUIKit

// MARK: - Theme (replaces podcasts/Theme.swift + Theme+Color.swift, ~1.4k lines
// of generated colour tables across 11 themes). Only `.light` and `.dark` are
// modelled; the hexes are lifted verbatim from scripts/themes/theme.csv.

public enum ThemeStyle {
    case primaryText01, primaryText02
    case primaryUi01, primaryUi01Active, primaryUi05
    case primaryIcon01
    case support01, support05
}

public final class Theme {
    public enum ThemeType {
        case light, dark
        public var isDark: Bool { self == .dark }
    }
    public static let sharedTheme = Theme()
    public var activeTheme: ThemeType = .light
    public static func isDarkTheme() -> Bool { sharedTheme.activeTheme == .dark }
}

private func hex(_ v: UInt32) -> UIColor {
    UIColor(red: CGFloat((v >> 16) & 0xFF) / 255,
            green: CGFloat((v >> 8) & 0xFF) / 255,
            blue: CGFloat(v & 0xFF) / 255, alpha: 1)
}

enum ThemeColor {
    private static func resolve(_ t: Theme.ThemeType?) -> Theme.ThemeType {
        t ?? Theme.sharedTheme.activeTheme
    }
    // theme.csv $primary-ui-01
    static func primaryUi01(for t: Theme.ThemeType? = nil) -> UIColor {
        resolve(t) == .dark ? hex(0x292B2E) : hex(0xFFFFFF)
    }
    // theme.csv $primary-ui-01-active
    static func primaryUi01Active(for t: Theme.ThemeType? = nil) -> UIColor {
        resolve(t) == .dark ? hex(0x383A3D) : hex(0xF7F9FA)
    }
    // theme.csv $primary-ui-05
    static func primaryUi05(for t: Theme.ThemeType? = nil) -> UIColor {
        resolve(t) == .dark ? hex(0x393A3C) : hex(0xE0E6EA)
    }
    // theme.csv $primary-text-01
    static func primaryText01(for t: Theme.ThemeType? = nil) -> UIColor {
        resolve(t) == .dark ? hex(0xFFFFFF) : hex(0x292B2E)
    }
    // theme.csv $primary-text-02
    static func primaryText02(for t: Theme.ThemeType? = nil) -> UIColor {
        resolve(t) == .dark ? hex(0x9C9FA4) : hex(0x8F97A4)
    }
    // theme.csv $primary-icon-01
    static func primaryIcon01(for t: Theme.ThemeType? = nil) -> UIColor {
        resolve(t) == .dark ? hex(0x33B8F4) : hex(0x03A9F4)
    }
    // theme.csv $support-01
    static func support01(for t: Theme.ThemeType? = nil) -> UIColor {
        resolve(t) == .dark ? hex(0x33B8F4) : hex(0x03A9F4)
    }
    // theme.csv $support-05
    static func support05(for t: Theme.ThemeType? = nil) -> UIColor {
        hex(0xF43E37)
    }
}

// Replaces podcasts/AppTheme.swift (~800 lines). Bodies are copied from the
// real AppTheme so the indirection is identical.
enum AppTheme {
    static func optionPickerBackgroundColor(for t: Theme.ThemeType? = nil) -> UIColor {
        ThemeColor.primaryUi01(for: t)
    }
    static func destructiveTextColor(for t: Theme.ThemeType? = nil) -> UIColor {
        ThemeColor.support05(for: t)
    }
    static func mainTextColor(for t: Theme.ThemeType? = nil) -> UIColor {
        ThemeColor.primaryText01(for: t)
    }
    static func tableDividerColor(for t: Theme.ThemeType? = nil) -> UIColor {
        ThemeColor.primaryUi05(for: t)
    }
    static func colorForStyle(_ style: ThemeStyle,
                              themeOverride: Theme.ThemeType? = nil) -> UIColor {
        switch style {
        case .primaryText01: return ThemeColor.primaryText01(for: themeOverride)
        case .primaryText02: return ThemeColor.primaryText02(for: themeOverride)
        case .primaryUi01: return ThemeColor.primaryUi01(for: themeOverride)
        case .primaryUi01Active: return ThemeColor.primaryUi01Active(for: themeOverride)
        case .primaryUi05: return ThemeColor.primaryUi05(for: themeOverride)
        case .primaryIcon01: return ThemeColor.primaryIcon01(for: themeOverride)
        case .support01: return ThemeColor.support01(for: themeOverride)
        case .support05: return ThemeColor.support05(for: themeOverride)
        }
    }
}

// Replaces podcasts/ThemeableSwitch.swift — a UISwitch subclass that repaints
// on theme change. The harness renders one theme, so the repaint is a no-op.
final class ThemeableSwitch: UISwitch {}

// Replaces podcasts' LiquidGlass feature flag (iOS 26 glass materials).
// OpenUIKit now has UIVisualEffectView's object/view semantics and a Canvas
// backdrop-filter primitive, but not UIGlassEffect or the view-render
// integration between them, so the harness pins the flag off — which is also
// what the real app does below iOS 26.
enum LiquidGlass { static let isEnabled = false }

// Replaces podcasts/SceneHelper.swift's window lookup. Only reachable from
// OptionsPicker.present() with no argument, which the harness does not call.
enum SceneHelper {
    @MainActor
    static func rootViewController() -> UIViewController? {
        UIApplication.shared.keyWindow?.rootViewController
    }
}

// MARK: - App extensions on UIKit types

// Replaces podcasts/UIFont+FontStyle.swift. The body is the real one with the
// `maxSizeCategory` clamp dropped, because OpenUIKit's UIFontMetrics does not
// model content size categories yet (docs/REAL_APP_TEST.md, blocked list).
extension UIFont {
    static func font(ofSize size: CGFloat,
                     weight: UIFont.Weight = .regular,
                     scalingWith style: UIFont.TextStyle) -> UIFont {
        let font = systemFont(ofSize: size, weight: weight)
        return UIFontMetrics(forTextStyle: style).scaledFont(for: font)
    }
}

// Replaces PocketCastsUtils/Extensions/UI/UIImage+Tint.swift, verbatim apart
// from the UIGraphics* calls, which OpenUIKit spells with the renderer API.
extension UIImage {
    func tintedImage(_ color: UIColor) -> UIImage? {
        // The real body is a `sourceIn` blend over the image's alpha, i.e.
        // exactly UIKit's own template tinting. OpenUIKit exports that as
        // `withTintColor`, so the shim calls it rather than reimplementing a
        // blend mode the Canvas does not expose.
        withTintColor(color)
    }
}

// Replaces PocketCastsUtils/Extensions/UI/UIViewExtension.swift
// updateSizeConstraints — copied verbatim.
extension UIView {
    func updateSizeConstraints(to value: CGFloat) {
        updateSizeConstraints(width: value, height: value)
    }

    func updateSizeConstraints(width: CGFloat, height: CGFloat) {
        for constraint in constraints {
            if constraint.secondItem != nil { continue }
            switch constraint.firstAttribute {
            case .width: constraint.constant = width
            case .height: constraint.constant = height
            default: continue
            }
        }
    }
}

// MARK: - Sibling action views

// Replaces podcasts/DescriptiveActionView.swift (205 lines) and
// MultipleActionView.swift. They are siblings of SimpleActionView inside the
// same picker; the harness renders the SimpleActionView path, so these exist
// only to keep OptionsPickerRootController's other two entry points compiling.
// Their bodies are empty ON PURPOSE — the report does not claim they render.
final class DescriptiveActionView: UIView {
    init(frame: CGRect, title: String, message: String?, icon: String,
         actions: [OptionAction], delegate: OptionsPickerRootController,
         themeOverride: Theme.ThemeType? = nil,
         iconTintStyle: ThemeStyle = .primaryIcon01,
         dismissAction: (() -> Void)? = nil) {
        super.init(frame: frame)
    }
    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }
    func actionWasAdded(vc: UIViewController) {}
}

final class MultipleActionView: UIView {
    init(frame: CGRect, name: String, icon: String?, actions: [OptionAction],
         themeOverride: Theme.ThemeType? = nil) {
        super.init(frame: frame)
    }
    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }
    func actionWasAdded() {}
}
