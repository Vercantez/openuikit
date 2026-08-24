// OpenUIKit — portable UIKit reimplementation.
// RULES for every file in this target:
//   - No Foundation. No Apple frameworks. Pure Swift + OpenCoreGraphics
//     (+ CSTBTrueType/CPortableIO through dedicated wrappers only).
//   - Match real UIKit behavior; golden data in golden/ is ground truth.
@_exported import OpenCoreGraphics

/// Global runtime configuration. openrender (or any host app) sets
/// `resourceRoot` before using OpenUIKit; resource files live in
/// Sources/OpenUIKit/Resources/ and are read via CPortableIO.
public enum OpenUIKitRuntime {
    /// Directory containing system_colors.json, font_metrics.json, and fonts.
    public static var resourceRoot: String = "Sources/OpenUIKit/Resources"
    /// Optional explicit font file paths (system, bold-face variants, mono, italic).
    /// When empty, the font engine falls back to platform-known locations
    /// (e.g. /System/Library/Fonts/SFNS.ttf on macOS).
    public static var fontPaths: [String: String] = [:]
}
