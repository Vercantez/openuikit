import Foundation

#if canImport(UIKit)
import UIKit
#endif
#if canImport(MapKit)
import MapKit
#endif
#if canImport(CoreLocation)
import CoreLocation
#endif

// Isolated host-gate stand-ins for UIKit / MapKit / CoreLocation types.
// These exist only when the real modules cannot be imported. They are not
// Apple implementations and are not claimed as UIKit/MapKit ABI.

#if !canImport(UIKit)
open class UIImage: NSObject, @unchecked Sendable {
    public let size: CGSize
    public init(size: CGSize = .zero) {
        self.size = size
        super.init()
    }
}

open class UIColor: NSObject, @unchecked Sendable {
    public override init() {
        super.init()
    }
}

open class UIView: NSObject, @unchecked Sendable {
    public var frame: CGRect = .zero
    public override init() {
        super.init()
    }
    public init(frame: CGRect) {
        self.frame = frame
        super.init()
    }
}

open class UIWindow: UIView, @unchecked Sendable {
    public var rootViewController: AnyObject?
}

open class UIScene: NSObject, @unchecked Sendable {
    public override init() {
        super.init()
    }
}

open class UIApplication: NSObject, @unchecked Sendable {
    public static let shared = UIApplication()
}

public protocol UIApplicationDelegate: AnyObject {}
public protocol UISceneDelegate: AnyObject {}

public enum UIUserInterfaceStyle: Int, Sendable {
    case unspecified = 0
    case light = 1
    case dark = 2
}

open class UISceneSession: NSObject, @unchecked Sendable {
    public struct Role: RawRepresentable, Hashable, Sendable {
        public var rawValue: String
        public init(rawValue: String) {
            self.rawValue = rawValue
        }
    }
}

open class UITraitCollection: NSObject, @unchecked Sendable {
    public var userInterfaceStyle: UIUserInterfaceStyle = .unspecified
    public override init() {
        super.init()
    }
}

open class UILayoutGuide: NSObject, @unchecked Sendable {
    public override init() {
        super.init()
    }
}

open class UITabBarItem: NSObject, @unchecked Sendable {
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
    public var title: String?
    public override init() {
        super.init()
    }
}
#endif

#if !canImport(CoreLocation)
public struct CLLocationCoordinate2D: Sendable, Hashable {
    public var latitude: Double
    public var longitude: Double
    public init(latitude: Double = 0, longitude: Double = 0) {
        self.latitude = latitude
        self.longitude = longitude
    }
}
#endif

#if !canImport(MapKit)
public struct MKCoordinateSpan: Sendable, Hashable {
    public var latitudeDelta: Double
    public var longitudeDelta: Double
    public init(latitudeDelta: Double = 0, longitudeDelta: Double = 0) {
        self.latitudeDelta = latitudeDelta
        self.longitudeDelta = longitudeDelta
    }
}

public struct MKCoordinateRegion: Sendable, Hashable {
    public var center: CLLocationCoordinate2D
    public var span: MKCoordinateSpan
    public init(
        center: CLLocationCoordinate2D = CLLocationCoordinate2D(),
        span: MKCoordinateSpan = MKCoordinateSpan()
    ) {
        self.center = center
        self.span = span
    }
}

open class MKMapItem: NSObject, @unchecked Sendable {
    public var name: String?
    public override init() {
        super.init()
    }
}
#endif

