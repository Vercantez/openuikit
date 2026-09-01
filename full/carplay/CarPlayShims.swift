import Foundation

#if canImport(UIKit)
import UIKit
#else

/// Linux stand-in for UIKit.UIImage so CarPlay image-taking APIs compile
/// without claiming bitmap decoding or asset catalogs.
open class UIImage: NSObject, NSSecureCoding, NSCopying {
    public let portableName: String?

    public override init() {
        portableName = nil
        super.init()
    }

    public init(portableName: String) {
        self.portableName = portableName
        super.init()
    }

    public required init?(coder: NSCoder) {
        return nil
    }

    public func encode(with coder: NSCoder) {}

    public static var supportsSecureCoding: Bool { true }

    public func copy(with zone: NSZone? = nil) -> Any {
        UIImage(portableName: portableName ?? "")
    }
}

/// Linux stand-in for UIKit.UIColor. Stores RGBA only.
open class UIColor: NSObject, NSSecureCoding, NSCopying {
    public let portableRed: CGFloat
    public let portableGreen: CGFloat
    public let portableBlue: CGFloat
    public let portableAlpha: CGFloat

    public init(red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat) {
        portableRed = red
        portableGreen = green
        portableBlue = blue
        portableAlpha = alpha
        super.init()
    }

    public static var black: UIColor { UIColor(red: 0, green: 0, blue: 0, alpha: 1) }
    public static var white: UIColor { UIColor(red: 1, green: 1, blue: 1, alpha: 1) }
    public static var clear: UIColor { UIColor(red: 0, green: 0, blue: 0, alpha: 0) }
    public static var red: UIColor { UIColor(red: 1, green: 0, blue: 0, alpha: 1) }
    public static var green: UIColor { UIColor(red: 0, green: 1, blue: 0, alpha: 1) }
    public static var blue: UIColor { UIColor(red: 0, green: 0, blue: 1, alpha: 1) }
    public static var orange: UIColor { UIColor(red: 1, green: 0.5, blue: 0, alpha: 1) }

    public required init?(coder: NSCoder) {
        return nil
    }

    public func encode(with coder: NSCoder) {}

    public static var supportsSecureCoding: Bool { true }

    public func copy(with zone: NSZone? = nil) -> Any {
        UIColor(
            red: portableRed,
            green: portableGreen,
            blue: portableBlue,
            alpha: portableAlpha
        )
    }
}

open class UIWindow: NSObject {}

open class UILayoutGuide: NSObject {}

open class UITraitCollection: NSObject {}

public enum UIUserInterfaceStyle: Int, Sendable {
    case unspecified = 0
    case light = 1
    case dark = 2
}

open class UIScene: NSObject {}

public protocol UISceneDelegate: AnyObject {}

open class UIApplication: NSObject {}

public protocol UIApplicationDelegate: AnyObject {}

public enum UITabBarItem {
    public enum SystemItem: Int, Sendable {
        case more = 0
        case favorites = 1
        case featured = 2
        case topRated = 3
        case recents = 4
        case contacts = 5
        case history = 6
        case bookmarks = 7
        case search = 8
        case downloads = 9
        case mostRecent = 10
        case mostViewed = 11
    }
}

public struct UISceneSession {
    public struct Role: RawRepresentable, Hashable, Sendable {
        public let rawValue: String

        public init(rawValue: String) {
            self.rawValue = rawValue
        }

        public static let carTemplateApplication = Role(
            rawValue: "CPTemplateApplicationSceneSessionRoleApplication"
        )
        public static let CPTemplateApplicationDashboardSceneSessionRoleApplication = Role(
            rawValue: "CPTemplateApplicationDashboardSceneSessionRoleApplication"
        )
        public static let CPTemplateApplicationInstrumentClusterSceneSessionRoleApplication = Role(
            rawValue: "CPTemplateApplicationInstrumentClusterSceneSessionRoleApplication"
        )
    }
}

#endif

#if canImport(UIKit)
extension UISceneSession.Role {
    public static let carTemplateApplication = UISceneSession.Role(
        rawValue: "CPTemplateApplicationSceneSessionRoleApplication"
    )
    public static let CPTemplateApplicationDashboardSceneSessionRoleApplication =
        UISceneSession.Role(
            rawValue: "CPTemplateApplicationDashboardSceneSessionRoleApplication"
        )
    public static let CPTemplateApplicationInstrumentClusterSceneSessionRoleApplication =
        UISceneSession.Role(
            rawValue: "CPTemplateApplicationInstrumentClusterSceneSessionRoleApplication"
        )
}
#endif

#if canImport(MapKit)
import MapKit
#else

public struct CLLocationCoordinate2D: Equatable, Sendable {
    public var latitude: Double
    public var longitude: Double

    public init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }
}

public struct MKCoordinateSpan: Equatable, Sendable {
    public var latitudeDelta: Double
    public var longitudeDelta: Double

    public init(latitudeDelta: Double, longitudeDelta: Double) {
        self.latitudeDelta = latitudeDelta
        self.longitudeDelta = longitudeDelta
    }
}

public struct MKCoordinateRegion: Equatable, Sendable {
    public var center: CLLocationCoordinate2D
    public var span: MKCoordinateSpan

    public init(center: CLLocationCoordinate2D, span: MKCoordinateSpan) {
        self.center = center
        self.span = span
    }
}

open class MKMapItem: NSObject {
    public var name: String?

    public override init() {
        super.init()
    }

    public convenience init(portableName: String) {
        self.init()
        name = portableName
    }
}

#endif
