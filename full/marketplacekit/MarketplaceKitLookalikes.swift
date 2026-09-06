#if !canImport(CoreGraphics)
/// CoreGraphics is not a declared dependency. Linux uses `Double` for `CGFloat`.
public typealias CGFloat = Double

public struct CGSize: Equatable, Hashable, Sendable {
    public var width: CGFloat
    public var height: CGFloat

    public init(width: CGFloat = 0, height: CGFloat = 0) {
        self.width = width
        self.height = height
    }

    public static let zero = CGSize()
}
#endif

#if !canImport(UIKit) && !canImport(OpenUIKit)
/// Module-local color stand-in. Not UIKit.UIColor.
open class UIColor: NSObject, @unchecked Sendable {
    public let red: CGFloat
    public let green: CGFloat
    public let blue: CGFloat
    public let alpha: CGFloat

    public init(red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat = 1) {
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
        super.init()
    }

    public static let black = UIColor(red: 0, green: 0, blue: 0, alpha: 1)
    public static let clear = UIColor(red: 0, green: 0, blue: 0, alpha: 0)
}

open class UIView: NSObject, @unchecked Sendable {
    public var isEnabled = true
    public var isHighlighted = false
    public var backgroundColor: UIColor?
    public var tintColor: UIColor!

    public override init() {
        tintColor = UIColor.black
        super.init()
    }
}

open class UIControl: UIView, @unchecked Sendable {}

open class UIWindowScene: NSObject, @unchecked Sendable {
    public override init() {
        super.init()
    }
}

open class UIScene: NSObject, @unchecked Sendable {
    open class ConnectionOptions: NSObject, @unchecked Sendable {
        /// Fail-closed: Linux has no UIKit scene connection payload.
        public var marketplaceDisplayOption: MarketplaceDisplayOption? {
            nil
        }

        public override init() {
            super.init()
        }
    }
}
#endif

#if !canImport(LocalAuthentication)
/// Module-local LocalAuthentication stand-in. Not Apple's `LAContext`.
open class LAContext: NSObject, @unchecked Sendable {
    public override init() {
        super.init()
    }
}
#endif
