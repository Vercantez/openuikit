import Foundation

// Isolated-host stand-ins for UIKit / CoreGraphics types that the sealed
// Foundation gate cannot import. Guest builds (`canImport(UIKit)` /
// `canImport(CoreGraphics)`) bind the public typealiases to the real modules.
// These types are not Apple runtime evidence.

#if canImport(CoreGraphics)
public typealias PencilKitTransform = CGAffineTransform
public typealias PencilKitContext = CGContext
#else
public struct PencilKitTransform: Equatable, Sendable {
    public var a: CGFloat
    public var b: CGFloat
    public var c: CGFloat
    public var d: CGFloat
    public var tx: CGFloat
    public var ty: CGFloat

    public init(a: CGFloat, b: CGFloat, c: CGFloat, d: CGFloat, tx: CGFloat, ty: CGFloat) {
        self.a = a
        self.b = b
        self.c = c
        self.d = d
        self.tx = tx
        self.ty = ty
    }

    public static let identity = PencilKitTransform(a: 1, b: 0, c: 0, d: 1, tx: 0, ty: 0)

    public func applying(_ point: CGPoint) -> CGPoint {
        CGPoint(
            x: a * point.x + c * point.y + tx,
            y: b * point.x + d * point.y + ty
        )
    }
}

public final class PencilKitContext: NSObject {}
#endif

#if canImport(UIKit)
public typealias PencilKitColor = UIColor
public typealias PencilKitImage = UIImage
public typealias PencilKitView = UIView
public typealias PencilKitScrollView = UIScrollView
public typealias PencilKitWindow = UIWindow
public typealias PencilKitResponder = UIResponder
public typealias PencilKitGestureRecognizer = UIGestureRecognizer
public typealias PencilKitBezierPath = UIBezierPath
public typealias PencilKitBarButtonItem = UIBarButtonItem
public typealias PencilKitViewController = UIViewController
public typealias PencilKitUserInterfaceStyle = UIUserInterfaceStyle
public typealias PencilKitScrollViewDelegate = UIScrollViewDelegate
#else
public enum PencilKitUserInterfaceStyle: Int, Sendable, Hashable {
    case unspecified = 0
    case light = 1
    case dark = 2
}

open class PencilKitHostColor: NSObject {
    public let pk_red: CGFloat
    public let pk_green: CGFloat
    public let pk_blue: CGFloat
    public let pk_alpha: CGFloat

    public init(red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat) {
        self.pk_red = red
        self.pk_green = green
        self.pk_blue = blue
        self.pk_alpha = alpha
    }

    public convenience init(white: CGFloat, alpha: CGFloat) {
        self.init(red: white, green: white, blue: white, alpha: alpha)
    }

    public static let black = PencilKitHostColor(white: 0, alpha: 1)
    public static let white = PencilKitHostColor(white: 1, alpha: 1)
    public static let clear = PencilKitHostColor(white: 0, alpha: 0)

    public func pk_components() -> (CGFloat, CGFloat, CGFloat, CGFloat) {
        (pk_red, pk_green, pk_blue, pk_alpha)
    }
}

open class PencilKitHostImage: NSObject {
    public var size: CGSize

    public override init() {
        self.size = .zero
        super.init()
    }

    public init(size: CGSize) {
        self.size = size
        super.init()
    }
}

open class PencilKitHostBezierPath: NSObject {
    public var bounds: CGRect = .zero

    public override init() {
        super.init()
    }
}

open class PencilKitHostGestureRecognizer: NSObject {}

open class PencilKitHostBarButtonItem: NSObject {}

open class PencilKitHostViewController: NSObject {}

open class PencilKitHostResponder: NSObject {
    public fileprivate(set) lazy var pencilKitResponderState: PKResponderState = PKResponderState()
    public private(set) var isFirstResponder: Bool = false

    @discardableResult
    open func becomeFirstResponder() -> Bool {
        isFirstResponder = true
        return true
    }

    @discardableResult
    open func resignFirstResponder() -> Bool {
        isFirstResponder = false
        return true
    }
}

open class PencilKitHostView: PencilKitHostResponder {
    public var frame: CGRect
    public var bounds: CGRect

    public override init() {
        self.frame = .zero
        self.bounds = .zero
        super.init()
    }

    public init(frame: CGRect) {
        self.frame = frame
        self.bounds = CGRect(origin: .zero, size: frame.size)
        super.init()
    }
}

open class PencilKitHostScrollView: PencilKitHostView {
    public var contentOffset: CGPoint = .zero
    public var contentSize: CGSize = .zero
}

open class PencilKitHostWindow: PencilKitHostView {}

public protocol PencilKitScrollViewDelegate: AnyObject {}

public typealias PencilKitColor = PencilKitHostColor
public typealias PencilKitImage = PencilKitHostImage
public typealias PencilKitView = PencilKitHostView
public typealias PencilKitScrollView = PencilKitHostScrollView
public typealias PencilKitWindow = PencilKitHostWindow
public typealias PencilKitResponder = PencilKitHostResponder
public typealias PencilKitGestureRecognizer = PencilKitHostGestureRecognizer
public typealias PencilKitBezierPath = PencilKitHostBezierPath
public typealias PencilKitBarButtonItem = PencilKitHostBarButtonItem
public typealias PencilKitViewController = PencilKitHostViewController
#endif

func pk_colorComponents(_ color: PencilKitColor) -> (CGFloat, CGFloat, CGFloat, CGFloat) {
#if canImport(UIKit)
    var r: CGFloat = 0
    var g: CGFloat = 0
    var b: CGFloat = 0
    var a: CGFloat = 0
    if color.getRed(&r, green: &g, blue: &b, alpha: &a) {
        return (r, g, b, a)
    }
    return (0, 0, 0, 1)
#else
    return color.pk_components()
#endif
}

func pk_colorsEqual(_ lhs: PencilKitColor, _ rhs: PencilKitColor) -> Bool {
    let a = pk_colorComponents(lhs)
    let b = pk_colorComponents(rhs)
    return a.0 == b.0 && a.1 == b.1 && a.2 == b.2 && a.3 == b.3
}

func pk_makeColor(red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat) -> PencilKitColor {
#if canImport(UIKit)
    return UIColor(red: red, green: green, blue: blue, alpha: alpha)
#else
    return PencilKitHostColor(red: red, green: green, blue: blue, alpha: alpha)
#endif
}

func pk_applyTransform(_ transform: PencilKitTransform, to point: CGPoint) -> CGPoint {
#if canImport(CoreGraphics)
    return point.applying(transform)
#else
    return transform.applying(point)
#endif
}

func pk_identityTransform() -> PencilKitTransform {
#if canImport(CoreGraphics)
    return .identity
#else
    return .identity
#endif
}

func pk_transformComponents(_ transform: PencilKitTransform) -> (CGFloat, CGFloat, CGFloat, CGFloat, CGFloat, CGFloat) {
#if canImport(CoreGraphics)
    return (transform.a, transform.b, transform.c, transform.d, transform.tx, transform.ty)
#else
    return (transform.a, transform.b, transform.c, transform.d, transform.tx, transform.ty)
#endif
}

func pk_makeTransform(a: CGFloat, b: CGFloat, c: CGFloat, d: CGFloat, tx: CGFloat, ty: CGFloat) -> PencilKitTransform {
#if canImport(CoreGraphics)
    return CGAffineTransform(a: a, b: b, c: c, d: d, tx: tx, ty: ty)
#else
    return PencilKitTransform(a: a, b: b, c: c, d: d, tx: tx, ty: ty)
#endif
}

func pk_transformsEqual(_ lhs: PencilKitTransform, _ rhs: PencilKitTransform) -> Bool {
    pk_transformComponents(lhs) == pk_transformComponents(rhs)
}
