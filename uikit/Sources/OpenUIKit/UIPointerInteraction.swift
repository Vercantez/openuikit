// Pointer-interaction compatibility used by Focus's AppShortcuts target.
//
// The API shape and defaults below were checked against the iOS 26.1 SDK
// Swift interface and a live iOS 26.1 simulator. OpenUIKit has no host-pointer
// event source yet, so effects and shapes are descriptors rather than rendered
// cursor treatments (docs/KNOWN_GAPS.md).

#if canImport(CoreGraphics)
import struct CoreFoundation.CGFloat
import struct CoreGraphics.CGRect
#elseif canImport(Foundation)
import Foundation
#endif

/// The Swift overlay's value-shaped pointer effects. UIKit's refined enum
/// advertises an unusual equality operator whose live behavior is not even
/// reflexive, so OpenUIKit deliberately does not invent value equality for
/// descriptors that retain identity-bearing previews.
@preconcurrency @MainActor
public enum UIPointerEffect {
    public enum TintMode: Sendable, Hashable {
        case none, overlay, underlay
    }

    case automatic(UITargetedPreview)
    case highlight(UITargetedPreview)
    case lift(UITargetedPreview)
    case hover(UITargetedPreview,
               preferredTintMode: TintMode = .overlay,
               prefersShadow: Bool = false,
               prefersScaledContent: Bool = true)

    public var preview: UITargetedPreview {
        switch self {
        case .automatic(let preview), .highlight(let preview), .lift(let preview),
             .hover(let preview, _, _, _):
            return preview
        }
    }
}

/// The iOS Swift overlay's pointer-shape cases. They are retained by
/// `UIPointerStyle`; drawing them is intentionally deferred to a future host
/// pointer backend.
@preconcurrency @MainActor
public enum UIPointerShape {
    case path(UIBezierPath)
    case roundedRect(CGRect, radius: CGFloat = UIPointerShape.defaultCornerRadius)
    case verticalBeam(length: CGFloat)
    case horizontalBeam(length: CGFloat)

    /// UIKit uses this sentinel to request its system-selected corner radius.
    nonisolated public static let defaultCornerRadius = CGFloat.leastNormalMagnitude
}

@preconcurrency @MainActor
public final class UIPointerStyle {
    let _effect: UIPointerEffect
    let _shape: UIPointerShape?

    public init(effect: UIPointerEffect, shape: UIPointerShape? = nil) {
        _effect = effect
        _shape = shape
    }
}

@preconcurrency @MainActor
public final class UIPointerRegion {
    public let rect: CGRect
    public let identifier: AnyHashable?

    public init(rect: CGRect, identifier: AnyHashable? = nil) {
        self.rect = rect
        self.identifier = identifier
    }
}

/// UIKit declares every delegate callback optional. OpenUIKit expresses the
/// callback Focus uses as a Swift requirement with a default implementation,
/// preserving the same opt-in conformance behavior without Objective-C
/// optional dispatch.
@preconcurrency @MainActor
public protocol UIPointerInteractionDelegate: AnyObject {
    func pointerInteraction(_ interaction: UIPointerInteraction,
                            styleFor region: UIPointerRegion) -> UIPointerStyle?
}

public extension UIPointerInteractionDelegate {
    func pointerInteraction(_ interaction: UIPointerInteraction,
                            styleFor region: UIPointerRegion) -> UIPointerStyle? { nil }
}

@preconcurrency @MainActor
public final class UIPointerInteraction: UIInteraction {
    public private(set) weak var delegate: UIPointerInteractionDelegate?
    public private(set) weak var view: UIView?
    public var isEnabled = true

    public init(delegate: UIPointerInteractionDelegate?) {
        self.delegate = delegate
    }

    public func willMove(to view: UIView?) {}

    public func didMove(to view: UIView?) {
        self.view = view
    }

    /// UIKit asks the pointer system to resolve the style again. There is no
    /// host pointer system to invalidate yet, so this deliberately has no
    /// observable effect.
    public func invalidate() {}

    /// Shared by tests and the future host pointer bridge. It keeps disabled
    /// or detached interactions from consulting application delegates.
    func _resolvedStyle(for region: UIPointerRegion) -> UIPointerStyle? {
        guard isEnabled, view != nil else { return nil }
        return delegate?.pointerInteraction(self, styleFor: region)
    }
}
