#if canImport(UIKit)
import UIKit
#else
import Foundation

/// Linux stand-in for UIKit geometry used by VisionKit signatures.
public struct UIEdgeInsets: Equatable, Sendable {
    public var top: CGFloat
    public var left: CGFloat
    public var bottom: CGFloat
    public var right: CGFloat

    public static let zero = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)

    public init(top: CGFloat, left: CGFloat, bottom: CGFloat, right: CGFloat) {
        self.top = top
        self.left = left
        self.bottom = bottom
        self.right = right
    }
}

/// Linux stand-in for `UIView`.
@MainActor
open class UIView: NSObject {
    public var bounds: CGRect = .zero
    public var frame: CGRect = .zero

    public override init() {
        super.init()
    }

    open func addSubview(_ view: UIView) {
        _ = view
    }
}

/// Linux stand-in for `UIViewController`.
@MainActor
open class UIViewController: NSObject {
    open var view: UIView

    public override init() {
        view = UIView()
        super.init()
    }

    public init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        _ = nibNameOrNil
        _ = nibBundleOrNil
        view = UIView()
        super.init()
    }

    open func loadView() {}
    open func viewDidLoad() {}
    open func viewWillAppear(_ animated: Bool) { _ = animated }
    open func viewDidDisappear(_ animated: Bool) { _ = animated }
    open func removeFromParent() {}
}

/// Linux stand-in for `UIImage`.
open class UIImage: NSObject {
    public enum Orientation: Int, Sendable {
        case up = 0
        case down = 1
        case left = 2
        case right = 3
        case upMirrored = 4
        case downMirrored = 5
        case leftMirrored = 6
        case rightMirrored = 7
    }

    public var imageOrientation: Orientation = .up

    public override init() {
        super.init()
    }
}

/// Linux stand-in for `UIFont`.
open class UIFont: NSObject {
    public override init() {
        super.init()
    }
}

/// Linux stand-in for `UIInteraction`.
@MainActor
public protocol UIInteraction: AnyObject {
    var view: UIView? { get }
    func willMove(to view: UIView?)
    func didMove(to view: UIView?)
}
#endif

#if canImport(CoreGraphics)
import CoreGraphics
#elseif canImport(ImageIO)
import ImageIO
#else
/// Linux stand-in for `CGImage`.
open class CGImage: NSObject {
    public override init() {
        super.init()
    }
}

/// Linux stand-in matching ImageIO's documented orientation values.
public enum CGImagePropertyOrientation: UInt32, Sendable {
    case up = 1
    case upMirrored = 2
    case down = 3
    case downMirrored = 4
    case leftMirrored = 5
    case left = 6
    case rightMirrored = 7
    case right = 8
}
#endif

#if canImport(CoreImage)
import CoreImage
#else
/// Linux stand-in for `CIImage`.
open class CIImage: NSObject {
    public override init() {
        super.init()
    }
}
#endif

#if canImport(CoreVideo)
import CoreVideo
#else
/// Linux stand-in for `CVPixelBuffer`.
open class CVPixelBuffer: NSObject {
    public override init() {
        super.init()
    }
}
#endif

#if canImport(Vision)
import Vision
#else
/// Linux stand-in for Vision barcode symbology identifiers.
public struct VNBarcodeSymbology: RawRepresentable, Hashable, Sendable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }
}

/// Linux stand-in for Vision text observations.
open class VNRecognizedTextObservation: NSObject, @unchecked Sendable {
    public override init() {
        super.init()
    }
}

/// Linux stand-in for Vision barcode observations.
open class VNBarcodeObservation: NSObject, @unchecked Sendable {
    public var payloadStringValue: String?

    public override init() {
        super.init()
    }

    public init(payloadStringValue: String?) {
        self.payloadStringValue = payloadStringValue
        super.init()
    }
}
#endif
