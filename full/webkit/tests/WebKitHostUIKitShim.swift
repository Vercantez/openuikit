// Test-only UIKit surface for the Linux WebKit host gate.
// This is not a product source and is never shipped in libWebKit.dylib.
// Geometry types come from Foundation; this shim only supplies UIKit views.
@_exported import Foundation

public struct UIEdgeInsets: Equatable, Sendable {
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
    public static let zero = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
}

public struct NSKeyValueObservingOptions: OptionSet, Sendable {
    public let rawValue: UInt
    public init(rawValue: UInt) { self.rawValue = rawValue }
    public static let new = Self(rawValue: 1 << 0)
    public static let old = Self(rawValue: 1 << 1)
    public static let initial = Self(rawValue: 1 << 2)
    public static let prior = Self(rawValue: 1 << 3)
}

public final class NSKeyValueObservation: NSObject {
    public func invalidate() {}
}

public protocol _HostKeyValueCodingAndObserving: AnyObject {}
extension NSObject: _HostKeyValueCodingAndObserving {}

public extension _HostKeyValueCodingAndObserving where Self: NSObject {
    func observe<Value>(
        _ keyPath: KeyPath<Self, Value>,
        options: NSKeyValueObservingOptions = [],
        changeHandler: @escaping (Self, Any) -> Void
    ) -> NSKeyValueObservation {
        _ = (keyPath, options, changeHandler)
        return NSKeyValueObservation()
    }
}

public final class UIColor: NSObject {
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

    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? UIColor else { return false }
        return r == other.r && g == other.g && b == other.b && a == other.a
    }

    public static let white = UIColor(red: 1, green: 1, blue: 1, alpha: 1)
    public static let black = UIColor(red: 0, green: 0, blue: 0, alpha: 1)
    public static let clear = UIColor(red: 0, green: 0, blue: 0, alpha: 0)
}

public final class UIImage: NSObject {}

@MainActor
open class UIView: NSObject {
    open var frame: CGRect
    open var bounds: CGRect
    public private(set) var subviews: [UIView] = []

    public init(frame: CGRect) {
        self.frame = frame
        self.bounds = CGRect(origin: .zero, size: frame.size)
        super.init()
    }

    public override init() {
        self.frame = .zero
        self.bounds = .zero
        super.init()
    }

    public required init?(coder: NSCoder) {
        self.frame = .zero
        self.bounds = .zero
        super.init()
    }

    open func addSubview(_ view: UIView) {
        subviews.append(view)
    }

    open func layoutSubviews() {}
}

@MainActor
open class UIScrollView: UIView {}

@MainActor
open class UIViewController: NSObject {
    public override init() {
        super.init()
    }
}
