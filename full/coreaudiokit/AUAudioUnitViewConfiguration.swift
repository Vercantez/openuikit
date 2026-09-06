import Foundation

#if canImport(UIKit)
import UIKit
#endif

/// Host-preferred Audio Unit view size. Width, height, and
/// `hostHasController` are stored at `init` and are get-only afterward.
/// Linux implements `NSSecureCoding` for those three fields. Apple's exact
/// coder keys and `isEqual:` policy are unobserved.
///
/// https://developer.apple.com/documentation/coreaudiokit/auaudiounitviewconfiguration
open class AUAudioUnitViewConfiguration: NSObject, NSSecureCoding {
    public static var supportsSecureCoding: Bool { true }

    private static let codingKeyWidth = "width"
    private static let codingKeyHeight = "height"
    private static let codingKeyHostHasController = "hostHasController"

    public let width: CGFloat
    public let height: CGFloat
    public let hostHasController: Bool

    public init(width: CGFloat, height: CGFloat, hostHasController: Bool) {
        self.width = width
        self.height = height
        self.hostHasController = hostHasController
        super.init()
    }

    public required init?(coder: NSCoder) {
        self.width = CGFloat(coder.decodeDouble(forKey: Self.codingKeyWidth))
        self.height = CGFloat(coder.decodeDouble(forKey: Self.codingKeyHeight))
        self.hostHasController = coder.decodeBool(forKey: Self.codingKeyHostHasController)
        super.init()
    }

    public func encode(with coder: NSCoder) {
        coder.encode(Double(width), forKey: Self.codingKeyWidth)
        coder.encode(Double(height), forKey: Self.codingKeyHeight)
        coder.encode(hostHasController, forKey: Self.codingKeyHostHasController)
    }
}
