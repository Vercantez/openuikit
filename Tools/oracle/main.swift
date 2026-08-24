// Oracle: renders scene JSON files with REAL UIKit (Mac Catalyst, offscreen).
// Scene building / layout dumping lives in SceneKit.swift (shared with
// Tools/oracle2, the real-window drawHierarchy variant).
// Usage:
//   oracle render <outdir> <scene.json>...
//   oracle colors <outfile.json>
//   oracle fontmetrics <outfile.json>
import UIKit

// MARK: - Render one scene (offscreen layer.render)

func renderScene(file: String, outdir: String) throws {
    let spec = try loadScene(file: file)
    guard spec.animations.isEmpty else {
        // CA discards animations on layers with no render context at commit
        // (verified: animationKeys() empties on CATransaction.flush() and
        // presentation() stays nil offscreen), so v1 cannot capture them.
        fatalError("scene \(spec.name) has \"animations\" — render it with Tools/oracle2 (mark it \"window\": true)")
    }
    let container = buildContainer(spec)

    try writeLayoutDump(container, name: spec.name, outdir: outdir)

    let fmt = UIGraphicsImageRendererFormat()
    fmt.scale = spec.scale
    fmt.opaque = false
    let renderer = UIGraphicsImageRenderer(size: CGSize(width: spec.width, height: spec.height), format: fmt)
    let img = renderer.image { ctx in
        spec.traits.performAsCurrent {
            container.layer.render(in: ctx.cgContext)
        }
    }
    try img.pngData()!.write(to: URL(fileURLWithPath: "\(outdir)/\(spec.name).png"))
    print("rendered \(spec.name)")
}

// MARK: - Color dump

func dumpColors(outfile: String) throws {
    var result: JSON = [:]
    for styleName in ["light", "dark"] {
        let traits = UITraitCollection(userInterfaceStyle: styleName == "dark" ? .dark : .light)
        var table: JSON = [:]
        for (name, color) in systemColorNames {
            let resolved = color.resolvedColor(with: traits)
            var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
            // Convert to extended sRGB components
            let srgb = resolved.cgColor.converted(to: CGColorSpace(name: CGColorSpace.sRGB)!,
                                                  intent: .defaultIntent, options: nil) ?? resolved.cgColor
            let comps = srgb.components!
            if comps.count >= 4 { r = comps[0]; g = comps[1]; b = comps[2]; a = comps[3] }
            else { r = comps[0]; g = comps[0]; b = comps[0]; a = comps[1] }
            table[name] = [Double(r), Double(g), Double(b), Double(a)]
        }
        result[styleName] = table
    }
    let data = try JSONSerialization.data(withJSONObject: result, options: [.prettyPrinted, .sortedKeys])
    try data.write(to: URL(fileURLWithPath: outfile))
    print("wrote \(outfile)")
}

// MARK: - Font metrics dump

func dumpFontMetrics(outfile: String) throws {
    var fonts: [JSON] = []
    let weights: [(String, UIFont.Weight)] = [
        ("ultraLight", .ultraLight), ("thin", .thin), ("light", .light), ("regular", .regular),
        ("medium", .medium), ("semibold", .semibold), ("bold", .bold), ("heavy", .heavy), ("black", .black),
    ]
    let sizes: [CGFloat] = Array(stride(from: 8, through: 40, by: 1)).map { CGFloat($0) } + [11.5, 13.5, 17.5]
    let sampleStrings = [
        "Hello UIKit", "The quick brown fox jumps over the lazy dog", "0123456789",
        "AVAST Wavy To. LT", "iiiiillll", "WWWW MMMM",
    ]
    func entry(_ label: String, _ font: UIFont) -> JSON {
        var advances: [String: Double] = [:]
        for scalar in 32...126 {
            let ch = String(UnicodeScalar(scalar)!)
            let w = (ch as NSString).size(withAttributes: [.font: font]).width
            advances[ch] = Double(w)
        }
        var strings: [String: Double] = [:]
        for s in sampleStrings {
            strings[s] = Double((s as NSString).size(withAttributes: [.font: font]).width)
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
            "postScriptName": font.fontName,
        ]
    }
    for size in sizes {
        for (wname, w) in weights {
            fonts.append(entry("system-\(wname)-\(size)", .systemFont(ofSize: size, weight: w)))
        }
        fonts.append(entry("italic-regular-\(size)", .italicSystemFont(ofSize: size)))
        fonts.append(entry("mono-regular-\(size)", .monospacedSystemFont(ofSize: size, weight: .regular)))
        fonts.append(entry("mono-bold-\(size)", .monospacedSystemFont(ofSize: size, weight: .bold)))
    }
    let data = try JSONSerialization.data(withJSONObject: ["fonts": fonts], options: [.sortedKeys])
    try data.write(to: URL(fileURLWithPath: outfile))
    print("wrote \(outfile) (\(fonts.count) font entries)")
}

// MARK: - Main

let args = CommandLine.arguments
guard args.count >= 3 else {
    print("usage: oracle render <outdir> <scene.json>... | oracle colors <out.json> | oracle fontmetrics <out.json>")
    exit(1)
}
switch args[1] {
case "render":
    let outdir = args[2]
    try FileManager.default.createDirectory(atPath: outdir, withIntermediateDirectories: true)
    var failures = 0
    for file in args.dropFirst(3) {
        do { try renderScene(file: file, outdir: outdir) }
        catch { print("FAIL \(file): \(error)"); failures += 1 }
    }
    exit(failures == 0 ? 0 : 1)
case "colors":
    try dumpColors(outfile: args[2])
case "fontmetrics":
    try dumpFontMetrics(outfile: args[2])
default:
    print("unknown command \(args[1])")
    exit(1)
}
