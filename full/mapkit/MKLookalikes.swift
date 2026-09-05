#if canImport(CoreGraphics)
import CoreGraphics
#endif
#if canImport(CoreLocation)
import CoreLocation
#endif
#if canImport(UIKit)
import UIKit
#endif
import Foundation

// Module-local stand-ins for CoreGraphics / CoreLocation / UIKit types when
// those modules are absent. The isolated Linux host compiles Foundation only.
// Real modules are imported by tests/agent/MapKitDependencyIdentity.swift for
// the later EC2 integration build. Never publish these names when the owner
// module is present.

#if !canImport(CoreLocation)
public typealias CLLocationDegrees = Double
public typealias CLLocationDistance = Double
public typealias CLLocationDirection = Double
public typealias CLLocationAccuracy = Double
public typealias CLLocationSpeed = Double

public struct CLLocationCoordinate2D: Equatable, Hashable, Sendable {
    public var latitude: CLLocationDegrees
    public var longitude: CLLocationDegrees

    public init() {
        latitude = 0
        longitude = 0
    }

    public init(latitude: CLLocationDegrees, longitude: CLLocationDegrees) {
        self.latitude = latitude
        self.longitude = longitude
    }
}

open class CLLocation: NSObject {
    public private(set) var coordinate: CLLocationCoordinate2D
    public var altitude: CLLocationDistance
    public var horizontalAccuracy: CLLocationAccuracy
    public var verticalAccuracy: CLLocationAccuracy
    public var timestamp: Date

    public init(latitude: CLLocationDegrees, longitude: CLLocationDegrees) {
        coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        altitude = 0
        horizontalAccuracy = -1
        verticalAccuracy = -1
        timestamp = Date()
        super.init()
    }

    public init(coordinate: CLLocationCoordinate2D, altitude: CLLocationDistance, horizontalAccuracy: CLLocationAccuracy, verticalAccuracy: CLLocationAccuracy, timestamp: Date) {
        self.coordinate = coordinate
        self.altitude = altitude
        self.horizontalAccuracy = horizontalAccuracy
        self.verticalAccuracy = verticalAccuracy
        self.timestamp = timestamp
        super.init()
    }
}

open class CLHeading: NSObject {
    public var magneticHeading: CLLocationDirection = 0
    public var trueHeading: CLLocationDirection = 0
    public var headingAccuracy: CLLocationDirection = -1
}

open class CLPlacemark: NSObject {
    public var location: CLLocation?
    public var name: String?
    public var country: String?
    public var administrativeArea: String?
    public var subAdministrativeArea: String?
    public var locality: String?
    public var subLocality: String?
    public var thoroughfare: String?
    public var subThoroughfare: String?
    public var postalCode: String?
    public var isoCountryCode: String?
}
#endif

#if !canImport(CoreGraphics)
public struct CGPoint: Equatable, Hashable, Sendable {
    public var x: CGFloat
    public var y: CGFloat
    public init() { x = 0; y = 0 }
    public init(x: CGFloat, y: CGFloat) { self.x = x; self.y = y }
    public static let zero = CGPoint()
}

public struct CGSize: Equatable, Hashable, Sendable {
    public var width: CGFloat
    public var height: CGFloat
    public init() { width = 0; height = 0 }
    public init(width: CGFloat, height: CGFloat) { self.width = width; self.height = height }
    public static let zero = CGSize()
}

public struct CGRect: Equatable, Hashable, Sendable {
    public var origin: CGPoint
    public var size: CGSize
    public init() { origin = .zero; size = .zero }
    public init(x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat) {
        origin = CGPoint(x: x, y: y)
        size = CGSize(width: width, height: height)
    }
    public init(origin: CGPoint, size: CGSize) {
        self.origin = origin
        self.size = size
    }
    public static let zero = CGRect()
    public var width: CGFloat { size.width }
    public var height: CGFloat { size.height }
    public var minX: CGFloat { origin.x }
    public var minY: CGFloat { origin.y }
    public var maxX: CGFloat { origin.x + size.width }
    public var maxY: CGFloat { origin.y + size.height }
}

public enum CGRectEdge: UInt32, Sendable {
    case minXEdge = 0
    case minYEdge = 1
    case maxXEdge = 2
    case maxYEdge = 3
}

public enum CGLineCap: Int32, Sendable {
    case butt = 0
    case round = 1
    case square = 2
}

public enum CGLineJoin: Int32, Sendable {
    case miter = 0
    case round = 1
    case bevel = 2
}

public enum CGBlendMode: Int32, Sendable {
    case normal = 0
    case multiply = 1
    case screen = 2
    case overlay = 3
}

open class CGPath: NSObject {}

open class CGMutablePath: CGPath {
    public override init() { super.init() }
    open func move(to point: CGPoint) { _ = point }
    open func addLine(to point: CGPoint) { _ = point }
    open func addEllipse(in rect: CGRect) { _ = rect }
    open func closeSubpath() {}
}

open class CGContext: NSObject {
    public override init() { super.init() }
    open func saveGState() {}
    open func restoreGState() {}
    open func setFillColor(red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat) {
        _ = (red, green, blue, alpha)
    }
    open func setStrokeColor(red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat) {
        _ = (red, green, blue, alpha)
    }
    open func setLineWidth(_ width: CGFloat) { _ = width }
    open func setLineCap(_ cap: CGLineCap) { _ = cap }
    open func setLineJoin(_ join: CGLineJoin) { _ = join }
    open func setMiterLimit(_ limit: CGFloat) { _ = limit }
    open func setLineDash(phase: CGFloat, lengths: [CGFloat]) { _ = (phase, lengths) }
    open func setAlpha(_ alpha: CGFloat) { _ = alpha }
    open func setBlendMode(_ mode: CGBlendMode) { _ = mode }
    open func addPath(_ path: CGPath) { _ = path }
    open func strokePath() {}
    open func fillPath() {}
    open func beginPath() {}
    open func move(to point: CGPoint) { _ = point }
    open func addLine(to point: CGPoint) { _ = point }
    open func closePath() {}
    open func translateBy(x: CGFloat, y: CGFloat) { _ = (x, y) }
    open func scaleBy(x: CGFloat, y: CGFloat) { _ = (x, y) }
    open func clip() {}
    open func addEllipse(in rect: CGRect) { _ = rect }
}
#endif

#if !canImport(UIKit)
public struct UIEdgeInsets: Equatable, Hashable, Sendable {
    public var top: CGFloat
    public var left: CGFloat
    public var bottom: CGFloat
    public var right: CGFloat
    public init() { top = 0; left = 0; bottom = 0; right = 0 }
    public init(top: CGFloat, left: CGFloat, bottom: CGFloat, right: CGFloat) {
        self.top = top
        self.left = left
        self.bottom = bottom
        self.right = right
    }
    public static let zero = UIEdgeInsets()
}

open class UIColor: NSObject {
    public let r: CGFloat
    public let g: CGFloat
    public let b: CGFloat
    public let a: CGFloat

    public init(red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat) {
        r = red
        g = green
        b = blue
        a = alpha
        super.init()
    }

    public static let red = UIColor(red: 1, green: 0, blue: 0, alpha: 1)
    public static let green = UIColor(red: 0, green: 1, blue: 0, alpha: 1)
    public static let blue = UIColor(red: 0, green: 0, blue: 1, alpha: 1)
    public static let purple = UIColor(red: 0.5, green: 0, blue: 0.5, alpha: 1)
    public static let white = UIColor(red: 1, green: 1, blue: 1, alpha: 1)
    public static let black = UIColor(red: 0, green: 0, blue: 0, alpha: 1)
    public static let clear = UIColor(red: 0, green: 0, blue: 0, alpha: 0)
    public static let lightGray = UIColor(red: 0.667, green: 0.667, blue: 0.667, alpha: 1)
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

open class UIView: NSObject {
    open var frame: CGRect
    open var bounds: CGRect
    open var backgroundColor: UIColor?
    open var isHidden: Bool
    open var alpha: CGFloat
    public weak var superview: UIView?

    public override init() {
        frame = .zero
        bounds = .zero
        isHidden = false
        alpha = 1
        super.init()
    }

    public init(frame: CGRect) {
        self.frame = frame
        self.bounds = CGRect(origin: .zero, size: frame.size)
        isHidden = false
        alpha = 1
        super.init()
    }

    public required init?(coder: NSCoder) {
        _ = coder
        return nil
    }

    open func setNeedsDisplay() {}
    open func draw(_ rect: CGRect) { _ = rect }
}

open class UIViewController: NSObject {
    public override init() { super.init() }
    public init(nibName: String?, bundle: Bundle?) {
        _ = (nibName, bundle)
        super.init()
    }
    public required init?(coder: NSCoder) {
        _ = coder
        return nil
    }
}

open class UIControl: UIView {}

open class UIBarButtonItem: NSObject {
    public override init() { super.init() }
}

open class UITraitCollection: NSObject {
    public override init() { super.init() }
}

open class UIScene: NSObject {}
#endif
