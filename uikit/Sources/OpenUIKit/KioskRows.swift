// UIKit members Eidolon's Objective-C pods reach on the way to Kiosk's first
// screen (ARTiledImageView, SVProgressHUD, DZNWebViewController), measured
// on the iOS 26.1 simulator by Tools/oracle2/kioskrowsprobe
// (docs/agent_reports/eidolon-kiosk.md). Their Objective-C twins are in
// OpenUIKitObjCBridge/EidolonKioskObjCBridge.swift.

#if canImport(CoreGraphics)
import struct CoreFoundation.CGFloat
import struct CoreGraphics.CGPoint
import struct CoreGraphics.CGRect
import struct CoreGraphics.CGSize
#elseif canImport(Foundation)
import Foundation
#endif
#if canImport(Foundation)
import struct Foundation.Notification
#endif

/// UIStringDrawing.h's UIBaselineAdjustment (iOS 26.1 raw values,
/// kioskrowsprobe `## hud`: AlignBaselines 0, AlignCenters 1, None 2).
public enum UIBaselineAdjustment: Int, Sendable {
    case alignBaselines = 0
    case alignCenters = 1
    case none = 2
}

extension UIView {
    /// UIKit's `setNeedsDisplay(_:)` (ARTiledImageView redraws one tile's
    /// rect). OpenUIKit redraws the whole view: the rect is a hint.
    public final func setNeedsDisplay(_ rect: CGRect) {
        _ = rect
        setNeedsDisplay()
    }
}

extension UIApplication {
    /// Deprecated since iOS 13 (SVProgressHUD reads it to place the HUD).
    /// The key window scene's orientation where the host supplied one;
    /// otherwise portrait for a tall screen and landscapeRight for a wide one
    /// (MEASURED kioskrowsprobe: landscape exactly when the screen is wide;
    /// Eidolon's golden device reports landscapeRight, lldb-orient.txt).
    @available(iOS, deprecated: 13.0)
    public final var statusBarOrientation: UIInterfaceOrientation {
        if let scene = keyWindow?.windowScene, scene.interfaceOrientation != .unknown {
            return scene.interfaceOrientation
        }
        let bounds = UIScreen.main.bounds
        return bounds.width > bounds.height ? .landscapeRight : .portrait
    }

    /// Deprecated since iOS 13. The screen-wide strip above the key window's
    /// top safe-area inset (MEASURED kioskrowsprobe: as wide as the screen).
    @available(iOS, deprecated: 13.0)
    public final var statusBarFrame: CGRect {
        CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: keyWindow?.safeAreaInsets.top ?? 0)
    }

#if canImport(Foundation)
    /// MEASURED kioskrowsprobe: the name is its own string.
    @available(iOS, deprecated: 13.0)
    public static let didChangeStatusBarOrientationNotification =
        Notification.Name("UIApplicationDidChangeStatusBarOrientationNotification")
#endif
}

/// NSString (UIStringDrawing)'s `boundingRectWithSize:options:attributes:context:`
/// for Objective-C callers (SVProgressHUD sizes its status label with it).
/// MEASURED kioskrowsprobe `## hud` (iOS 26.1): "Loading" in the 16 pt
/// system font with UsesLineFragmentOrigin | UsesFontLeading |
/// TruncatesLastVisibleLine in 200 × 300 is at 0,0, one line tall
/// (19.094 = the font's lineHeight) and narrower than 200.
public enum _OUKStringDrawing {
    public static func boundingRect(_ string: String, size: CGSize, options: NSStringDrawingOptions,
                                    font: UIFont) -> CGRect {
        guard !string.isEmpty else { return .zero }
        if options.contains(.usesLineFragmentOrigin), size.width > 0 {
            let lines = TextLayout.wrap(string, font: font, maxWidth: size.width, maxLines: 0)
            let width = lines.reduce(CGFloat.zero) { Swift.max($0, $1.measuredWidth) }
            return CGRect(x: 0, y: 0, width: width, height: CGFloat(Swift.max(1, lines.count)) * font.lineHeight)
        }
        return CGRect(x: 0, y: 0, width: FontEngine.measure(string, font: font), height: font.lineHeight)
    }
}
