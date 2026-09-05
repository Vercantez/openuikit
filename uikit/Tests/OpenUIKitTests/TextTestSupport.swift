// Shared helpers for the text module's tests. Tests MAY use Foundation.
import Foundation
import XCTest
@testable import OpenUIKit

// OpenUIKit's attributed-text types shadow Foundation's, and this file also
// uses Foundation (JSONSerialization), so they are fully qualified below —
// see docs/KNOWN_GAPS.md "Attributed text shadows Foundation's types".

#if !os(Linux)
@MainActor
#endif
enum TextTestSupport {
    /// Absolute repo root, derived from this file's location.
    static let repoRoot: URL = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()   // OpenUIKitTests
        .deletingLastPathComponent()   // Tests
        .deletingLastPathComponent()   // root

    static func configureResourceRoot() {
        OpenUIKitRuntime.resourceRoot =
            repoRoot.appendingPathComponent("Sources/OpenUIKit/Resources").path
    }

    static func loadJSON(_ relativePath: String) throws -> [String: Any] {
        let url = repoRoot.appendingPathComponent(relativePath)
        let data = try Data(contentsOf: url)
        return try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
    }

    static func font(fromID id: String) -> UIFont? {
        // id = "<family>-<weight>-<size>"
        let parts = id.split(separator: "-")
        guard parts.count == 3, let size = Double(parts[2]) else { return nil }
        guard let w = weight(String(parts[1])) else { return nil }
        switch parts[0] {
        case "system": return .systemFont(ofSize: size, weight: w)
        case "mono": return .monospacedSystemFont(ofSize: size, weight: w)
        case "italic": return .italicSystemFont(ofSize: size)
        default: return nil
        }
    }

    static func weight(_ s: String) -> UIFont.Weight? {
        switch s {
        case "ultraLight": return .ultraLight
        case "thin": return .thin
        case "light": return .light
        case "regular": return .regular
        case "medium": return .medium
        case "semibold": return .semibold
        case "bold": return .bold
        case "heavy": return .heavy
        case "black": return .black
        default: return nil
        }
    }

    /// Build a UILabel from a scene-spec view object (docs/SCENE_SPEC.md).
    static func makeLabel(_ j: [String: Any]) -> UILabel {
        let label = UILabel()
        label.text = j["text"] as? String
        let size = (j["fontSize"] as? Double) ?? 17
        let w = weight((j["fontWeight"] as? String) ?? "regular") ?? .regular
        if (j["italic"] as? Bool) == true {
            label.font = .italicSystemFont(ofSize: size)
        } else if (j["monospaced"] as? Bool) == true {
            label.font = .monospacedSystemFont(ofSize: size, weight: w)
        } else {
            label.font = .systemFont(ofSize: size, weight: w)
        }
        if let a = j["textAlignment"] as? String {
            switch a {
            case "left": label.textAlignment = .left
            case "center": label.textAlignment = .center
            case "right": label.textAlignment = .right
            case "justified": label.textAlignment = .justified
            default: label.textAlignment = .natural
            }
        }
        if let n = j["numberOfLines"] as? Int { label.numberOfLines = n }
        if let m = j["lineBreakMode"] as? String {
            switch m {
            case "wordWrap": label.lineBreakMode = .byWordWrapping
            case "charWrap": label.lineBreakMode = .byCharWrapping
            case "clip": label.lineBreakMode = .byClipping
            case "truncateHead": label.lineBreakMode = .byTruncatingHead
            case "truncateTail": label.lineBreakMode = .byTruncatingTail
            case "truncateMiddle": label.lineBreakMode = .byTruncatingMiddle
            default: break
            }
        }
        if let a = j["attributedText"] as? [String: Any] {
            label.attributedText = attributedString(a)
        }
        if let f = j["frame"] as? [Double], f.count == 4 {
            label.frame = CGRect(x: f[0], y: f[1], width: f[2], height: f[3])
        }
        if (j["sizeToFit"] as? Bool) == true { label.sizeToFit() }
        return label
    }

    /// Build an NSAttributedString from the scene-spec "attributedText"
    /// object (docs/SCENE_SPEC.md v5.2) — mirrors openrender's builder.
    static func attributedString(_ j: [String: Any]) -> OpenUIKit.NSAttributedString {
        let out = OpenUIKit.NSMutableAttributedString()
        for r in (j["runs"] as? [[String: Any]]) ?? [] {
            let text = (r["text"] as? String) ?? ""
            let size = (r["fontSize"] as? Double) ?? 17
            let w = weight((r["fontWeight"] as? String) ?? "regular") ?? .regular
            let f: UIFont
            if (r["italic"] as? Bool) == true { f = .italicSystemFont(ofSize: size) }
            else if (r["monospaced"] as? Bool) == true {
                f = .monospacedSystemFont(ofSize: size, weight: w)
            } else { f = .systemFont(ofSize: size, weight: w) }
            var a: [OpenUIKit.NSAttributedString.Key: Any] = [.font: f]
            if let c = r["color"] as? String, let color = namedColor(c) {
                a[.foregroundColor] = color
            }
            if let v = r["kern"] as? Double { a[.kern] = OpenUIKit.CGFloat(v) }
            if let v = r["baselineOffset"] as? Double { a[.baselineOffset] = OpenUIKit.CGFloat(v) }
            if let u = r["underline"] as? String, u != "none" {
                a[.underlineStyle] = OpenUIKit.NSUnderlineStyle.single.rawValue
            }
            if let u = r["strikethrough"] as? String, u != "none" {
                a[.strikethroughStyle] = OpenUIKit.NSUnderlineStyle.single.rawValue
            }
            out.append(OpenUIKit.NSAttributedString(string: text, attributes: a))
        }
        if let p = j["paragraph"] as? [String: Any] {
            let ps = OpenUIKit.NSMutableParagraphStyle()
            switch (p["alignment"] as? String) ?? "natural" {
            case "left": ps.alignment = .left
            case "center": ps.alignment = .center
            case "right": ps.alignment = .right
            case "justified": ps.alignment = .justified
            default: ps.alignment = .natural
            }
            if let v = p["lineSpacing"] as? Double { ps.lineSpacing = OpenUIKit.CGFloat(v) }
            if let v = p["paragraphSpacing"] as? Double { ps.paragraphSpacing = OpenUIKit.CGFloat(v) }
            if let v = p["lineHeightMultiple"] as? Double { ps.lineHeightMultiple = OpenUIKit.CGFloat(v) }
            if let v = p["minimumLineHeight"] as? Double { ps.minimumLineHeight = OpenUIKit.CGFloat(v) }
            if let v = p["maximumLineHeight"] as? Double { ps.maximumLineHeight = OpenUIKit.CGFloat(v) }
            if let v = p["firstLineHeadIndent"] as? Double {
                ps.firstLineHeadIndent = OpenUIKit.CGFloat(v)
            }
            if let v = p["headIndent"] as? Double { ps.headIndent = OpenUIKit.CGFloat(v) }
            if let v = p["tailIndent"] as? Double { ps.tailIndent = OpenUIKit.CGFloat(v) }
            switch (p["lineBreakMode"] as? String) ?? "wordWrap" {
            case "charWrap": ps.lineBreakMode = .byCharWrapping
            case "clip": ps.lineBreakMode = .byClipping
            case "truncateHead": ps.lineBreakMode = .byTruncatingHead
            case "truncateTail": ps.lineBreakMode = .byTruncatingTail
            case "truncateMiddle": ps.lineBreakMode = .byTruncatingMiddle
            default: ps.lineBreakMode = .byWordWrapping
            }
            out.addAttribute(.paragraphStyle, value: ps, range: out.fullRange)
        }
        return out
    }

    static func namedColor(_ s: String) -> UIColor? {
        switch s {
        case "label": return .label
        case "secondaryLabel": return .secondaryLabel
        case "systemBlue": return .systemBlue
        case "systemRed": return .systemRed
        default: return nil
        }
    }
}
