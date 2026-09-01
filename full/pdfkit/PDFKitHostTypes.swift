import Foundation
#if canImport(CoreGraphics)
import CoreGraphics
#endif
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Isolated-host stand-ins
//
// The fan-out host gate compiles this module with Foundation only. Apple UIKit
// and CoreGraphics types are substituted here so PDFKit's public signatures
// type-check. When those modules are present they are used instead. These
// stand-ins are not Apple UIKit/CoreGraphics and do not claim rendering,
// printing, or find-interaction behavior.

#if !canImport(CoreGraphics)
public struct CGAffineTransform: Equatable, Sendable {
    public var a: CGFloat
    public var b: CGFloat
    public var c: CGFloat
    public var d: CGFloat
    public var tx: CGFloat
    public var ty: CGFloat

    public static let identity = CGAffineTransform(a: 1, b: 0, c: 0, d: 1, tx: 0, ty: 0)

    public init(a: CGFloat, b: CGFloat, c: CGFloat, d: CGFloat, tx: CGFloat, ty: CGFloat) {
        self.a = a
        self.b = b
        self.c = c
        self.d = d
        self.tx = tx
        self.ty = ty
    }
}

open class CGContext: NSObject {
    public override init() { super.init() }
}

open class CGPDFDocument: NSObject {
    public override init() { super.init() }
}

open class CGPDFPage: NSObject {
    public override init() { super.init() }
}
#endif

#if !canImport(UIKit)
public enum NSTextAlignment: Int, Sendable {
    case left = 0
    case center = 1
    case right = 2
    case justified = 3
    case natural = 4
}

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

open class UIColor: NSObject {
    public let redComponent: CGFloat
    public let greenComponent: CGFloat
    public let blueComponent: CGFloat
    public let alphaComponent: CGFloat

    public static let black = UIColor(white: 0, alpha: 1)
    public static let white = UIColor(white: 1, alpha: 1)
    public static let clear = UIColor(white: 0, alpha: 0)

    public init(red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat) {
        redComponent = red
        greenComponent = green
        blueComponent = blue
        alphaComponent = alpha
        super.init()
    }

    public convenience init(white: CGFloat, alpha: CGFloat) {
        self.init(red: white, green: white, blue: white, alpha: alpha)
    }
}

open class UIFont: NSObject {
    public var pointSize: CGFloat

    public init(pointSize: CGFloat = 12) {
        self.pointSize = pointSize
        super.init()
    }
}

open class UIImage: NSObject {
    public var size: CGSize

    public override init() {
        size = .zero
        super.init()
    }

    public init(size: CGSize) {
        self.size = size
        super.init()
    }
}

open class UIBezierPath: NSObject {
    public override init() { super.init() }
}

open class UIEvent: NSObject {
    public override init() { super.init() }
}

open class UIView: NSObject {
    open var frame: CGRect = .zero
    open var bounds: CGRect = .zero
    open var isHidden = false

    public override init() { super.init() }

    public init(frame: CGRect) {
        self.frame = frame
        self.bounds = CGRect(origin: .zero, size: frame.size)
        super.init()
    }
}

open class UIViewController: NSObject {
    public override init() { super.init() }
}

open class UIFindInteraction: NSObject {
    public override init() { super.init() }
}
#endif
