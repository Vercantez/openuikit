import Foundation

#if canImport(Metal)
import Metal
#endif
#if canImport(UIKit)
import UIKit
#endif
#if canImport(CoreGraphics)
import CoreGraphics
#endif

/// Visual contents of a control. Linux records requested size; it does not
/// upload SF Symbols or GPU textures.
public final class TCControlContents: NSObject {
    public enum ButtonShape: Int, Sendable, Hashable {
        case circle = 0
        case rect = 1
    }

    public enum DpadDirection: Int, Sendable, Hashable {
        case up = 0
        case down = 1
        case left = 2
        case right = 3
    }

    public enum DpadElementStyle: Int, Sendable, Hashable {
        case circle = 0
        case pentagon = 1
    }

    public private(set) var images: [TCControlImage]

    public convenience init(images: [TCControlImage]) {
        self.init(copiedImages: images)
    }

    init(copiedImages: [TCControlImage]) {
        self.images = copiedImages
        super.init()
    }

    public class func buttonContents(
        forSystemImageNamed imageName: String,
        size: CGSize,
        shape: ButtonShape,
        controller: TCTouchController
    ) -> TCControlContents {
        _ = imageName
        _ = shape
        _ = controller
        return TCControlContents(copiedImages: [TCControlImage(size: size, offset: .zero)])
    }

    public class func switchedOnContents(
        forSystemImageNamed imageName: String,
        size: CGSize,
        shape: ButtonShape,
        controller: TCTouchController
    ) -> TCControlContents {
        _ = imageName
        _ = shape
        _ = controller
        return TCControlContents(copiedImages: [TCControlImage(size: size, offset: .zero)])
    }

    public class func directionPadContents(
        label: TCControlLabel,
        size: CGSize,
        style: DpadElementStyle,
        direction: DpadDirection,
        controller: TCTouchController
    ) -> TCControlContents {
        _ = label
        _ = style
        _ = direction
        _ = controller
        return TCControlContents(copiedImages: [TCControlImage(size: size, offset: .zero)])
    }

    public class func throttleBackgroundContents(
        size: CGSize,
        controller: TCTouchController
    ) -> TCControlContents {
        _ = controller
        return TCControlContents(copiedImages: [TCControlImage(size: size, offset: .zero)])
    }

    public class func throttleIndicatorContents(
        size: CGSize,
        controller: TCTouchController
    ) -> TCControlContents {
        _ = controller
        return TCControlContents(copiedImages: [TCControlImage(size: size, offset: .zero)])
    }

    public class func thumbstickStickBackgroundContents(
        size: CGSize,
        controller: TCTouchController
    ) -> TCControlContents {
        _ = controller
        return TCControlContents(copiedImages: [TCControlImage(size: size, offset: .zero)])
    }

    public class func thumbstickStickContents(
        size: CGSize,
        controller: TCTouchController
    ) -> TCControlContents {
        _ = controller
        return TCControlContents(copiedImages: [TCControlImage(size: size, offset: .zero)])
    }
}

/// CPU-side image descriptor. Metal texture, `CGImage`, `UIImage`, and
/// `CGColor` members are unavailable on the isolated host (those modules
/// are not present and this framework does not ship substitutes).
public final class TCControlImage: NSObject {
    public var offset: CGPoint
    public var size: CGSize

    init(size: CGSize, offset: CGPoint) {
        self.size = size
        self.offset = offset
        super.init()
    }

#if canImport(Metal)
    public var texture: any MTLTexture
    public var highlightTexture: (any MTLTexture)?

    public convenience init(texture: any MTLTexture, size: CGSize) {
        self.init(size: size, offset: .zero)
        self.texture = texture
        self.highlightTexture = nil
    }

    public init(
        texture: any MTLTexture,
        size: CGSize,
        highlight highlightTexture: (any MTLTexture)?,
        offset: CGPoint,
        tintColor: Any
    ) {
        self.texture = texture
        self.highlightTexture = highlightTexture
        self.size = size
        self.offset = offset
        super.init()
        _ = tintColor
    }

    public init(
        texture: any MTLTexture,
        size: CGSize,
        highlightTexture: (any MTLTexture)?,
        offset: CGPoint,
        tintColor: Any
    ) {
        self.texture = texture
        self.highlightTexture = highlightTexture
        self.size = size
        self.offset = offset
        super.init()
        _ = tintColor
    }
#endif

#if canImport(Metal) && canImport(CoreGraphics)
    public unowned(unsafe) var tintColor: CGColor

    public convenience init?(cgImage: CGImage, size: CGSize, device: any MTLDevice) {
        _ = cgImage
        _ = size
        _ = device
        return nil
    }

    public convenience init?(CGImage cgImage: CGImage, size: CGSize, device: any MTLDevice) {
        self.init(cgImage: cgImage, size: size, device: device)
    }
#endif

#if canImport(Metal) && canImport(UIKit)
    public convenience init?(uiImage: UIImage, size: CGSize, device: any MTLDevice) {
        _ = uiImage
        _ = size
        _ = device
        return nil
    }

    public convenience init?(UIImage uiImage: UIImage, size: CGSize, device: any MTLDevice) {
        self.init(uiImage: uiImage, size: size, device: device)
    }
#endif
}
