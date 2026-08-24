// Shared helpers for the text module's tests. Tests MAY use Foundation.
import Foundation
import XCTest
@testable import OpenUIKit

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
        if let f = j["frame"] as? [Double], f.count == 4 {
            label.frame = CGRect(x: f[0], y: f[1], width: f[2], height: f[3])
        }
        if (j["sizeToFit"] as? Bool) == true { label.sizeToFit() }
        return label
    }
}
