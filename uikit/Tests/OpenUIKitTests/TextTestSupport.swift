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
            let size = (r["fontSize"] as? Double) ?? 17
            let w = weight((r["fontWeight"] as? String) ?? "regular") ?? .regular
            let f: UIFont
            if (r["italic"] as? Bool) == true { f = .italicSystemFont(ofSize: size) }
            else if (r["monospaced"] as? Bool) == true {
                f = .monospacedSystemFont(ofSize: size, weight: w)
            } else { f = .systemFont(ofSize: size, weight: w) }
            if let attJ = r["attachment"] as? [String: Any] {
                let att = NSTextAttachment()
                if let imgJ = attJ["image"] as? [String: Any] {
                    att.image = solidImage(from: imgJ)
                }
                if let b = attJ["bounds"] as? [Double], b.count == 4 {
                    att.bounds = CGRect(x: b[0], y: b[1], width: b[2], height: b[3])
                }
                if let p = attJ["lineLayoutPadding"] as? Double {
                    att.lineLayoutPadding = OpenUIKit.CGFloat(p)
                }
                if let ft = attJ["fileType"] as? String { att.fileType = ft }
                if let allow = attJ["allowsTextAttachmentView"] as? Bool {
                    att.allowsTextAttachmentView = allow
                }
                let piece = OpenUIKit.NSMutableAttributedString(
                    attributedString: OpenUIKit.NSAttributedString(attachment: att))
                var extra: [OpenUIKit.NSAttributedString.Key: Any] = [.font: f]
                if let c = r["color"] as? String, let color = namedColor(c) {
                    extra[.foregroundColor] = color
                }
                piece.addAttributes(extra, range: NSRange(location: 0, length: piece.length))
                out.append(piece)
                continue
            }
            let text = (r["text"] as? String) ?? ""
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

    /// Solid bitmap matching openrender `makeImage` `{kind: solid, colors, size}`.
    static func solidImage(from j: [String: Any]) -> UIImage {
        let sz = (j["size"] as? [Double]) ?? [24, 24]
        let w = OpenUIKit.CGFloat(sz[0])
        let h = OpenUIKit.CGFloat(sz.count > 1 ? sz[1] : sz[0])
        let scale: OpenUIKit.CGFloat = 2
        let pw = Swift.max(1, Int((w * scale).rounded()))
        let ph = Swift.max(1, Int((h * scale).rounded()))
        let bmp = Bitmap(width: pw, height: ph)
        var r: UInt8 = 255, g: UInt8 = 0, b: UInt8 = 0, a: UInt8 = 255
        if let colors = j["colors"] as? [String], let hex = colors.first,
           let parsed = parseHex(hex) {
            r = parsed.0; g = parsed.1; b = parsed.2; a = parsed.3
        }
        var i = 0
        while i + 3 < bmp.pixels.count {
            bmp.pixels[i] = r
            bmp.pixels[i + 1] = g
            bmp.pixels[i + 2] = b
            bmp.pixels[i + 3] = a
            i += 4
        }
        return UIImage(bitmap: bmp, scale: scale)
    }

    static func parseHex(_ s: String) -> (UInt8, UInt8, UInt8, UInt8)? {
        var hex = s
        if hex.hasPrefix("#") { hex.removeFirst() }
        guard hex.count == 6 || hex.count == 8 else { return nil }
        var value: UInt64 = 0
        guard Scanner(string: hex).scanHexInt64(&value) else { return nil }
        if hex.count == 6 {
            return (UInt8((value >> 16) & 0xFF), UInt8((value >> 8) & 0xFF),
                    UInt8(value & 0xFF), 255)
        }
        return (UInt8((value >> 24) & 0xFF), UInt8((value >> 16) & 0xFF),
                UInt8((value >> 8) & 0xFF), UInt8(value & 0xFF))
    }
}
