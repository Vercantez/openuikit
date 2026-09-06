import Foundation

// Linux starting point for Apple's Accessibility framework (Xcode 26.1 /
// iPhoneOS 26.1). Value types, descriptors, error codes, option sets, and
// AttributedString attributes are implemented here. Assistive technologies,
// hearing hardware, Settings.app jumps, feature-override entitlements,
// localized color names, and braille-table catalogs are fail-closed: this
// host has no Accessibility daemon, entitlement prompt, or Apple table data.

// MARK: - CoreGraphics stand-ins

// CoreGraphics is not a declared dependency. Foundation already provides
// CGRect, CGPoint, and CGSize on this toolchain. Color and image objects
// are opaque NSObject markers so AXNameFromColor and AXBrailleMap.present
// type-check; they never invent Apple palette names or rasterize bitmaps.

public class CGColor: NSObject {
    public override init() {
        super.init()
    }
}

public class CGImage: NSObject {
    public override init() {
        super.init()
    }
}

/// Localized color names are produced by Apple's palette + Accessibility
/// bundle. Linux has neither, so this always returns an empty string.
public func AXNameFromColor(_ color: CGColor) -> String {
    _ = color
    return ""
}

public func AXAnimatedImagesEnabled() -> Bool {
    AccessibilitySettings.animatedImagesEnabled
}

public func AXPrefersHorizontalTextLayout() -> Bool {
    AccessibilitySettings.prefersHorizontalTextLayout
}

internal func axCopyAttributed(_ string: NSAttributedString?) -> NSAttributedString? {
    string.map { NSAttributedString(attributedString: $0) }
}

internal func axAttributed(_ string: String?) -> NSAttributedString? {
    string.map { NSAttributedString(string: $0) }
}

internal func axFailClosedError(domain: String, code: Int, userInfo: [String: Any] = [:]) -> NSError {
    NSError(domain: domain, code: code, userInfo: userInfo)
}
