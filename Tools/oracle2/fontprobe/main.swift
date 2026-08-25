// FontProbe: the `oracle fontmetrics` dump, re-taken on REAL iOS.
//
// Tools/oracle/main.swift harvests Resources/font_metrics.json on Mac
// Catalyst. The `window: true` fixtures (alerts, sheets) are rendered by the
// iOS-26 simulator instead, so any place where the two platforms disagree
// shows up as an advance-width drift in those goldens only. This probe emits
// the SAME structure from iOS so the two can be diffed directly.
//
// Output: <Documents>/font_metrics_ios.json
// Run: scripts/font_probe_sim.sh <outdir>
import UIKit

let docsDir = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]

let weights: [(String, UIFont.Weight)] = [
    ("ultraLight", .ultraLight), ("thin", .thin), ("light", .light), ("regular", .regular),
    ("medium", .medium), ("semibold", .semibold), ("bold", .bold), ("heavy", .heavy), ("black", .black),
]
let sizes: [CGFloat] = Array(stride(from: 8, through: 40, by: 1)).map { CGFloat($0) } + [11.5, 13.5, 17.5]
let sampleStrings = [
    "Hello UIKit", "The quick brown fox jumps over the lazy dog", "0123456789",
    "AVAST Wavy To. LT", "iiiiillll", "WWWW MMMM",
]

func entry(_ label: String, _ font: UIFont) -> [String: Any] {
    var advances: [String: Double] = [:]
    for scalar in 32...126 {
        let ch = String(UnicodeScalar(scalar)!)
        advances[ch] = Double((ch as NSString).size(withAttributes: [.font: font]).width)
    }
    var strings: [String: Double] = [:]
    for s in sampleStrings {
        strings[s] = Double((s as NSString).size(withAttributes: [.font: font]).width)
    }
    // What a real UILabel reports for the same strings (this is what the
    // goldens actually render).
    var labelWidths: [String: Double] = [:]
    for s in sampleStrings {
        let l = UILabel()
        l.font = font
        l.text = s
        labelWidths[s] = Double(l.intrinsicContentSize.width)
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
        "labelWidths": labelWidths,
        "postScriptName": font.fontName,
    ]
}

final class AppDelegate: NSObject, UIApplicationDelegate {
    var window: UIWindow?
    func application(_ app: UIApplication,
                     didFinishLaunchingWithOptions o: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        var fonts: [[String: Any]] = []
        for size in sizes {
            for (wname, w) in weights {
                fonts.append(entry("system-\(wname)-\(size)", .systemFont(ofSize: size, weight: w)))
            }
            fonts.append(entry("italic-regular-\(size)", .italicSystemFont(ofSize: size)))
            fonts.append(entry("mono-regular-\(size)", .monospacedSystemFont(ofSize: size, weight: .regular)))
            fonts.append(entry("mono-bold-\(size)", .monospacedSystemFont(ofSize: size, weight: .bold)))
        }
        let data = try! JSONSerialization.data(withJSONObject: ["fonts": fonts], options: [.sortedKeys])
        try! data.write(to: URL(fileURLWithPath: "\(docsDir)/font_metrics_ios.json"))
        try! "ok".write(toFile: docsDir + "/DONE", atomically: true, encoding: .utf8)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { exit(0) }
        return true
    }
}
let delegateClassName = NSStringFromClass(AppDelegate.self)
UIApplicationMain(CommandLine.argc, CommandLine.unsafeArgv, nil, delegateClassName)
