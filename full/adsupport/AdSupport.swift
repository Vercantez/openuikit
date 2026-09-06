@_exported import Foundation

/// Linux starting point for Apple's public `AdSupport` module.
///
/// Linux has no IDFA, advertising identifier daemon, ATT prompt, or Settings
/// advertising toggle. This module never fabricates a tracking identifier.
/// `advertisingIdentifier` is the all-zero UUID that Apple documents when
/// tracking is not authorized, and `isAdvertisingTrackingEnabled` is `false`.

/// All-zero advertising identifier. Matches Apple's documented IDFA when the
/// user has not authorized tracking / has limited ad tracking. Not a live
/// device identifier.
private let zeroAdvertisingIdentifier = UUID(
    uuid: (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
)

/// An object that provides a device identifier used only to serve advertisements.
///
/// Reconstructs the Xcode 26.1 iPhoneOS Swift overlay for the ObjC class
/// `ASIdentifierManager`. The class is `open`, inherits `NSObject`, and is
/// obtained through `shared()`. Linux never returns a non-zero IDFA.
open class ASIdentifierManager: NSObject {
    private static let sharedInstance = ASIdentifierManager()

    /// The shared identifier manager for this process.
    ///
    /// Overlay of ObjC `+sharedManager`. Linux keeps one process-wide instance.
    /// Whether Darwin `alloc/init` aliases this singleton is unobserved.
    open class func shared() -> ASIdentifierManager {
        sharedInstance
    }

    /// The advertising identifier for this device.
    ///
    /// Overlay of ObjC `advertisingIdentifier` (`NSUUID` → Swift `UUID`).
    /// Linux has no IDFA hardware or advertising daemon, so this is always
    /// `00000000-0000-0000-0000-000000000000`. That is Apple's documented
    /// value when tracking is not authorized; it is not a generated IDFA.
    open var advertisingIdentifier: UUID {
        zeroAdvertisingIdentifier
    }

    /// Whether advertising tracking is allowed.
    ///
    /// Overlay of ObjC `isAdvertisingTrackingEnabled`. Deprecated in iOS 14
    /// in favor of AppTrackingTransparency's `ATTrackingManager`. Linux has
    /// no Settings advertising switch and never reports tracking as enabled.
    @available(
        iOS,
        introduced: 6.0,
        deprecated: 14.0,
        message: "This has been replaced by functionality in AppTrackingTransparency's ATTrackingManager class."
    )
    open var isAdvertisingTrackingEnabled: Bool {
        false
    }
}
