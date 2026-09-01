import Foundation

#if canImport(UIKit)
import UIKit
#endif

#if canImport(CoreMedia)
import CoreMedia
#endif

// Linux host-gate compilation has no UIKit, CoreMedia, or Darwin Foundation
// extension-host types. These stand-ins exist only so ReplayKit's public
// signatures type-check. They are not a UIKit or CoreMedia port and must not
// be treated as Apple camera, screen, or image objects.
#if !canImport(UIKit)

open class UIView: NSObject, @unchecked Sendable {
    public override init() {
        super.init()
    }
}

open class UIViewController: NSObject, @unchecked Sendable {
    public override init() {
        super.init()
    }
}

open class UIImage: NSObject, @unchecked Sendable {
    public override init() {
        super.init()
    }
}

#endif

#if !canImport(CoreMedia)

/// Opaque portable stand-in for CoreMedia's sample-buffer type.
///
/// ReplayKit never fabricates captured frames. Callers may construct an empty
/// buffer only to exercise `processSampleBuffer` on a subclass.
public struct CMSampleBuffer: Equatable, Sendable {
    public init() {}
}

#endif

#if !canImport(Darwin)

/// Portable stand-in for Foundation's extension context.
///
/// Linux Swift Foundation has no `NSExtensionContext`. Broadcast-setup methods
/// live on this type so ReplayKit's public extension API remains source
/// compatible until a real extension host exists.
open class NSExtensionContext: NSObject, @unchecked Sendable {
    public override init() {
        super.init()
    }

    public private(set) var portableBroadcastURL: URL?
    public private(set) var portableBroadcastConfiguration: RPBroadcastConfiguration?
    public private(set) var portableSetupInfo: [String: any NSCoding & NSObjectProtocol]?
    public private(set) var portableDidCompleteBroadcastRequest = false

    open func completeRequest(
        withBroadcast broadcastURL: URL,
        broadcastConfiguration: RPBroadcastConfiguration,
        setupInfo: [String: any NSCoding & NSObjectProtocol]?
    ) {
        portableBroadcastURL = broadcastURL
        portableBroadcastConfiguration = broadcastConfiguration
        portableSetupInfo = setupInfo
        portableDidCompleteBroadcastRequest = true
    }

    open func completeRequest(
        withBroadcast broadcastURL: URL,
        setupInfo: [String: any NSCoding & NSObjectProtocol]?
    ) {
        portableBroadcastURL = broadcastURL
        portableBroadcastConfiguration = nil
        portableSetupInfo = setupInfo
        portableDidCompleteBroadcastRequest = true
    }

    open func loadBroadcastingApplicationInfo(
        completion handler: @escaping (String, String, UIImage?) -> Void
    ) {
        // No broadcast extension host is present. The ObjC API has no error
        // parameter, so the handler still runs with empty identity values.
        handler("", "", nil)
    }
}

#endif
