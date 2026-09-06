import Foundation

// Isolated-host stand-ins for CoreGraphics, UIKit, UniformTypeIdentifiers,
// and PencilKit types named by the public PaperKit surface. The sealed host
// gate compiles this module alone. When a real dependency module is on the
// link line, the matching block compiles out. These types are not Apple
// runtime evidence and are not a Linux UIKit or PencilKit port.

#if !canImport(CoreGraphics)

public struct CGAffineTransform: Equatable, Sendable {
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

    public static let identity = CGAffineTransform(a: 1, b: 0, c: 0, d: 1, tx: 0, ty: 0)
}

public final class CGColor: @unchecked Sendable {
    public let red: CGFloat
    public let green: CGFloat
    public let blue: CGFloat
    public let alpha: CGFloat

    public init(srgbRed: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat) {
        self.red = srgbRed
        self.green = green
        self.blue = blue
        self.alpha = alpha
    }
}

public final class CGImage: @unchecked Sendable {
    public let width: Int
    public let height: Int

    public init(width: Int, height: Int) {
        self.width = width
        self.height = height
    }
}

public final class CGContext: @unchecked Sendable {
    public init() {}
}

#endif

#if !canImport(UIKit)

public enum UIUserInterfaceStyle: Int, Sendable, Hashable {
    case unspecified = 0
    case light = 1
    case dark = 2
}

public enum UITraitEnvironmentLayoutDirection: Int, Sendable, Hashable {
    case unspecified = -1
    case leftToRight = 0
    case rightToLeft = 1
}

open class UITraitCollection: NSObject {
    public var userInterfaceStyle: UIUserInterfaceStyle
    public var layoutDirection: UITraitEnvironmentLayoutDirection

    public override init() {
        self.userInterfaceStyle = .unspecified
        self.layoutDirection = .unspecified
        super.init()
    }

    public init(
        userInterfaceStyle: UIUserInterfaceStyle,
        layoutDirection: UITraitEnvironmentLayoutDirection = .leftToRight
    ) {
        self.userInterfaceStyle = userInterfaceStyle
        self.layoutDirection = layoutDirection
        super.init()
    }
}

open class UIView: NSObject {
    public var frame: CGRect

    public override init() {
        self.frame = .zero
        super.init()
    }

    public init(frame: CGRect) {
        self.frame = frame
        super.init()
    }
}

open class UIViewController: NSObject {
    open var canBecomeFirstResponder: Bool { false }
    open var undoManager: UndoManager? { nil }

    public override init() {
        super.init()
    }

    open func viewDidLoad() {}
}

open class UIMenuElement: NSObject {
    public override init() {
        super.init()
    }
}

open class UndoManager: NSObject {
    public override init() {
        super.init()
    }

    public var canUndo: Bool { false }
    public var canRedo: Bool { false }
}

#endif

#if !canImport(UniformTypeIdentifiers)

public struct UTType: Equatable, Hashable, Sendable {
    public let identifier: String

    public init(identifier: String) {
        self.identifier = identifier
    }

    public init(filenameExtension: String) {
        self.identifier = "public.\(filenameExtension)"
    }
}

#endif

#if !canImport(PencilKit)

public protocol PKTool {}

public enum PKContentVersion: Int, Sendable, Hashable {
    case version1 = 1
    case version2 = 2
    case version3 = 3
    case version4 = 4

    public static var latest: PKContentVersion { .version4 }
}

public struct PKInkingTool: PKTool, Equatable, Sendable {
    public enum InkType: String, Hashable, Sendable {
        case pen
        case pencil
        case marker
        case monoline
        case fountainPen
        case watercolor
        case crayon
        case reed
    }

    public var inkType: InkType

    public init(_ inkType: InkType = .pen) {
        self.inkType = inkType
    }
}

public struct PKDrawing: Equatable, Sendable {
    public init() {}
}

open class PKToolPicker: NSObject {
    public var isRulerActive: Bool = false
    public var selectedTool: any PKTool = PKInkingTool(.pen)

    public override init() {
        super.init()
    }
}

#endif

func paperKitApply(_ transform: CGAffineTransform, to point: CGPoint) -> CGPoint {
#if canImport(CoreGraphics)
    return point.applying(transform)
#else
    return CGPoint(
        x: transform.a * point.x + transform.c * point.y + transform.tx,
        y: transform.b * point.x + transform.d * point.y + transform.ty
    )
#endif
}

func paperKitColorComponents(_ color: CGColor) -> (CGFloat, CGFloat, CGFloat, CGFloat) {
#if canImport(CoreGraphics)
    if let components = color.components, components.count >= 3 {
        let alpha = components.count > 3 ? components[3] : 1
        return (components[0], components[1], components[2], alpha)
    }
    return (0, 0, 0, 1)
#else
    return (color.red, color.green, color.blue, color.alpha)
#endif
}

func paperKitColorsEqual(_ lhs: CGColor?, _ rhs: CGColor?) -> Bool {
    switch (lhs, rhs) {
    case (nil, nil):
        return true
    case let (left?, right?):
        let a = paperKitColorComponents(left)
        let b = paperKitColorComponents(right)
        return a.0 == b.0 && a.1 == b.1 && a.2 == b.2 && a.3 == b.3
    default:
        return false
    }
}

func paperKitAllInkTypes() -> Set<PKInkingTool.InkType> {
    [
        .pen, .pencil, .marker, .monoline,
        .fountainPen, .watercolor, .crayon, .reed,
    ]
}
