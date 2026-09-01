@_exported import Foundation
@_exported import StagedFoundation

/// Test-only EC2 staging UIColor. Not part of the UserNotificationsUI product.
public final class UIColor: NSObject, NSCopying {
    public let red: CGFloat
    public let green: CGFloat
    public let blue: CGFloat
    public let alpha: CGFloat

    public init(red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat) {
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
        super.init()
    }

    public func copy(with zone: NSZone? = nil) -> Any {
        _ = zone
        return UIColor(red: red, green: green, blue: blue, alpha: alpha)
    }

    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? UIColor else { return false }
        return red == other.red
            && green == other.green
            && blue == other.blue
            && alpha == other.alpha
    }
}
