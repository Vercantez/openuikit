import Foundation

#if canImport(UIKit)
#else
/// Isolated-host stand-ins for UIKit-shaped PDFKit properties. These are not
/// Apple types; guest builds against real UIKit use `UIColor` / `UIImage`.
open class PDFKitHostColor: NSObject {
    open var red: CGFloat
    open var green: CGFloat
    open var blue: CGFloat
    open var alpha: CGFloat

    public init(red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat) {
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
    }

    public convenience init(white: CGFloat, alpha: CGFloat) {
        self.init(red: white, green: white, blue: white, alpha: alpha)
    }

    public static let black = PDFKitHostColor(white: 0, alpha: 1)
    public static let white = PDFKitHostColor(white: 1, alpha: 1)
    public static let clear = PDFKitHostColor(white: 0, alpha: 0)
}

open class PDFKitHostImage: NSObject {
    open var size: CGSize

    public init(size: CGSize) {
        self.size = size
    }
}

open class PDFKitHostFont: NSObject {
    open var pointSize: CGFloat
    open var fontName: String

    public init(name: String, size: CGFloat) {
        self.fontName = name
        self.pointSize = size
    }

    public static func systemFont(ofSize size: CGFloat) -> PDFKitHostFont {
        PDFKitHostFont(name: "Helvetica", size: size)
    }
}

open class PDFKitHostBezierPath: NSObject {
    open var bounds: CGRect = .zero
}

open class PDFKitHostFindInteraction: NSObject {}

public struct PDFKitHostEdgeInsets: Equatable, Sendable {
    public var top: CGFloat
    public var left: CGFloat
    public var bottom: CGFloat
    public var right: CGFloat

    public init(top: CGFloat, left: CGFloat, bottom: CGFloat, right: CGFloat) {
        self.top = top
        self.left = left
        self.bottom = bottom
        self.right = right
    }

    public static let zero = PDFKitHostEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
}

public enum PDFKitHostTextAlignment: Int, Sendable {
    case left = 0
    case center = 1
    case right = 2
    case justified = 3
    case natural = 4
}

public typealias PDFKitColor = PDFKitHostColor
public typealias PDFKitImage = PDFKitHostImage
public typealias PDFKitFont = PDFKitHostFont
public typealias PDFKitBezierPath = PDFKitHostBezierPath
public typealias PDFKitFindInteraction = PDFKitHostFindInteraction
public typealias PDFKitEdgeInsets = PDFKitHostEdgeInsets
public typealias PDFKitTextAlignment = PDFKitHostTextAlignment
#endif

#if canImport(UIKit)
public typealias PDFKitColor = UIColor
public typealias PDFKitImage = UIImage
public typealias PDFKitFont = UIFont
public typealias PDFKitBezierPath = UIBezierPath
public typealias PDFKitFindInteraction = UIFindInteraction
public typealias PDFKitEdgeInsets = UIEdgeInsets
public typealias PDFKitTextAlignment = NSTextAlignment
#endif
