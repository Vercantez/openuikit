@_exported import OpenCoreGraphics
import OpenUIKit

// OpenUIKit owns these declarations today.  QuartzCore publishes aliases to
// those exact types so importing UIKit and QuartzCore cannot fork a layer,
// animation, geometry, or transaction identity.
public typealias CACornerMask = OpenUIKit.CACornerMask
public typealias CALayerDelegate = OpenUIKit.CALayerDelegate
public typealias CALayer = OpenUIKit.CALayer
public typealias CAGradientLayer = OpenUIKit.CAGradientLayer
public typealias CAMediaTimingFillMode = OpenUIKit.CAMediaTimingFillMode
public typealias CAAnimation = OpenUIKit.CAAnimation
public typealias CAPropertyAnimation = OpenUIKit.CAPropertyAnimation
public typealias CABasicAnimation = OpenUIKit.CABasicAnimation
public typealias CATransaction = OpenUIKit.CATransaction

/// Linkable identity anchor used by the cold package probe.  Passing a
/// `UIView.layer` here is a compile-time and runtime proof that QuartzCore did
/// not introduce a wrapper or shadow CALayer hierarchy.
@MainActor
public func _openUIKitQuartzCoreLayerIdentity(
    _ layer: CALayer
) -> ObjectIdentifier {
    ObjectIdentifier(layer)
}
