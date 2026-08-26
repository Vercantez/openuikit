// SliceStubs.swift -- NOT part of ~/uikit.
// Provenance: added by swift-macho-linux. Two tiny stand-ins the trimmed
// render slice still names:
//   * UIContentSizeCategory -- a field of UITraitCollection (UIColor.swift).
//   * SystemColors.resolve   -- reached only by UIColor's `.semantic` storage.
//     boxes_basic / corner_radius use hex (`.fixed`) colors, so this is never
//     called during their render; it returns opaque black as a loud-but-inert
//     placeholder rather than pulling in Resources/system_colors.json + the
//     JSON + ResourceIO stack.

public enum UIContentSizeCategory: Equatable, Sendable {
    case unspecified, large
}

enum SystemColors {
    static func resolve(_ name: String, traits: UITraitCollection) -> CGColor {
        // Not on the boxes/corner render path; inert placeholder.
        CGColor(red: 0, green: 0, blue: 0, alpha: 1)
    }
}
