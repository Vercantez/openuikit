// UIScreen — the display an app is running on. Owner: lifecycle module
// (M12, docs/APP_COMPAT.md "App lifecycle / environment").
//
// OpenUIKit has no display server, so `UIScreen.main` is HOST-DRIVEN: the
// host (openhost's SDL window, openrender's scene, a test) calls
// `_hostConfigure(bounds:scale:)` with the real surface it is rendering
// into, and every app-visible property follows from that. Nothing here is
// invented per frame — the numbers are the ones the frames are actually
// rendered at, which is the whole point of the class for app code
// (`UIWindow(frame: UIScreen.main.bounds)` must produce the window the host
// really opened).
//
// Before any host configures it, the defaults describe a portrait iPhone
// 12/13/14-class device (390 x 844 pt @3x, 1170 x 2532 px). That is a
// PLAUSIBLE FIXED VALUE, not a measurement: it matches the size the rest of
// OpenUIKit already assumes (UIViewController.loadView's default frame) and
// keeps `UIScreen.main.bounds` sane for code that reads it before a host
// exists.

@preconcurrency @MainActor
public final class UIScreen {
    /// The screen the app renders into.
    public static let main = UIScreen(bounds: CGRect(x: 0, y: 0, width: 390, height: 844),
                                      scale: 3)

    /// Every screen known to the app. OpenUIKit is single-display: this is
    /// always `[main]` (UIKit would list external displays too).
    public static var screens: [UIScreen] { [main] }

    /// Screen size in POINTS, origin always zero (UIKit reports the screen's
    /// own coordinate space).
    public private(set) var bounds: CGRect

    /// Backing-store scale: points -> pixels.
    public private(set) var scale: CGFloat

    /// Physical pixel dimensions. UIKit's nativeBounds is in PIXELS and, on
    /// a portrait device, is the portrait pixel size regardless of
    /// orientation; OpenUIKit has no orientation, so it is simply
    /// `bounds * nativeScale`.
    public var nativeBounds: CGRect {
        CGRect(x: 0, y: 0,
               width: bounds.width * nativeScale,
               height: bounds.height * nativeScale)
    }

    /// Scale of the physical display. Equal to `scale` here: OpenUIKit never
    /// renders through a downscaled framebuffer the way UIKit does on the
    /// zoomed-display iPhones, so the two cannot diverge.
    public var nativeScale: CGFloat { scale }

    /// Traits of the screen. Explicit process-wide size classes are retained;
    /// otherwise the host surface supplies OpenUIKit's documented 600 pt
    /// per-axis approximation. This read does not mutate process-wide traits.
    public var traitCollection: UITraitCollection {
        var traits = _currentTraitsResolvingSizeClasses
        traits.displayScale = scale
        return traits
    }

    /// Complete only the axes missing from the process environment. Detached
    /// views/controllers use this while retaining current's style, scale, and
    /// Dynamic Type category; UIScreen.traitCollection separately substitutes
    /// the physical screen scale above.
    var _currentTraitsResolvingSizeClasses: UITraitCollection {
        var traits = UITraitCollection.current
        traits._resolveUnspecifiedSizeClasses(for: bounds.size)
        return traits
    }

    init(bounds: CGRect, scale: CGFloat) {
        self.bounds = CGRect(x: 0, y: 0, width: bounds.width, height: bounds.height)
        self.scale = scale
    }

    /// HOST HOOK (not UIKit API — hence the underscore): point the screen at
    /// the surface the host is really rendering. openhost calls this with
    /// the SDL window's point size and the scene scale before booting the
    /// app, so `UIScreen.main.bounds` is the window an app would get.
    public func _hostConfigure(bounds: CGRect, scale: CGFloat) {
        self.bounds = CGRect(x: 0, y: 0, width: bounds.width, height: bounds.height)
        self.scale = scale > 0 ? scale : 1
    }
}
