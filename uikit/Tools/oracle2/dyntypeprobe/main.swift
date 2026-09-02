// DynTypeProbe: real-iOS Dynamic Type tables.
//
// OpenUIKit's UIFont.TextStyle / UIFont.preferredFont(forTextStyle:) /
// UIFontMetrics are built from THIS dump — no constant in
// Sources/OpenUIKit/UIFontMetrics.swift is guessed.
//
// For every (text style x content size category) it records:
//   * UIFontDescriptor.preferredFontDescriptor(withTextStyle:compatibleWith:)
//     -> pointSize                       (the "preferred" size)
//   * UIFont.preferredFont(forTextStyle:compatibleWith:)
//     -> pointSize, lineHeight, postScriptName, symbolic traits
//   * UIFontMetrics(forTextStyle:).scaledValue(for: v, compatibleWith:)
//     for a spread of base values, which is what pins the scaling RULE
//     (is it a ratio? is it clamped? is it per-style?).
//
// Output: <Documents>/dynamic_type_ios.json
// Run: scripts/dyntype_probe_sim.sh <outdir>
import UIKit

let docsDir = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]

let styles: [(String, UIFont.TextStyle)] = [
    ("largeTitle", .largeTitle), ("title1", .title1), ("title2", .title2),
    ("title3", .title3), ("headline", .headline), ("subheadline", .subheadline),
    ("body", .body), ("callout", .callout), ("footnote", .footnote),
    ("caption1", .caption1), ("caption2", .caption2),
]

let categories: [(String, UIContentSizeCategory)] = [
    ("extraSmall", .extraSmall), ("small", .small), ("medium", .medium),
    ("large", .large), ("extraLarge", .extraLarge),
    ("extraExtraLarge", .extraExtraLarge),
    ("extraExtraExtraLarge", .extraExtraExtraLarge),
    ("accessibilityMedium", .accessibilityMedium),
    ("accessibilityLarge", .accessibilityLarge),
    ("accessibilityExtraLarge", .accessibilityExtraLarge),
    ("accessibilityExtraExtraLarge", .accessibilityExtraExtraLarge),
    ("accessibilityExtraExtraExtraLarge", .accessibilityExtraExtraExtraLarge),
]

// Base values the app corpus actually passes to scaledValue/font(ofSize:).
let baseValues: [CGFloat] = [8, 10, 11, 12, 13, 14, 15, 16, 17, 18, 20, 22, 24, 26, 28, 34, 40, 48, 64]

final class AppDelegate: NSObject, UIApplicationDelegate {
    var window: UIWindow?
    func application(_ app: UIApplication,
                     didFinishLaunchingWithOptions o: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        var out: [[String: Any]] = []
        for (cname, cat) in categories {
            let traits = UITraitCollection(preferredContentSizeCategory: cat)
            for (sname, style) in styles {
                let desc = UIFontDescriptor.preferredFontDescriptor(withTextStyle: style,
                                                                    compatibleWith: traits)
                let font = UIFont.preferredFont(forTextStyle: style, compatibleWith: traits)
                let metrics = UIFontMetrics(forTextStyle: style)
                var scaled: [String: Double] = [:]
                for v in baseValues {
                    scaled["\(v)"] = Double(metrics.scaledValue(for: v, compatibleWith: traits))
                }
                // scaledFont() rounds differently from scaledValue() in places
                // -- record both so the implementation can match whichever the
                // app path uses.
                var scaledFontPt: [String: Double] = [:]
                for v in baseValues {
                    let f = metrics.scaledFont(for: .systemFont(ofSize: v, weight: .semibold),
                                               compatibleWith: traits)
                    scaledFontPt["\(v)"] = Double(f.pointSize)
                }
                out.append([
                    "category": cname,
                    "style": sname,
                    "descriptorPointSize": Double(desc.pointSize),
                    "fontPointSize": Double(font.pointSize),
                    "fontLineHeight": Double(font.lineHeight),
                    "fontAscender": Double(font.ascender),
                    "fontDescender": Double(font.descender),
                    "postScriptName": font.fontName,
                    "isBold": font.fontDescriptor.symbolicTraits.contains(.traitBold),
                    "scaledValue": scaled,
                    "scaledFontPointSize": scaledFontPt,
                ])
            }
        }
        let data = try! JSONSerialization.data(withJSONObject: ["entries": out],
                                               options: [.sortedKeys])
        try! data.write(to: URL(fileURLWithPath: "\(docsDir)/dynamic_type_ios.json"))
        try! "ok".write(toFile: docsDir + "/DONE", atomically: true, encoding: .utf8)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { exit(0) }
        return true
    }
}
let delegateClassName = NSStringFromClass(AppDelegate.self)
UIApplicationMain(CommandLine.argc, CommandLine.unsafeArgv, nil, delegateClassName)
