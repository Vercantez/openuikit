import Foundation

#if canImport(UIKit)
import UIKit
#endif

#if canImport(AVFoundation)
import AVFoundation
#endif

/// Linux starting point for Apple's public ReplayKit module.
///
/// Screen capture, microphone/camera mixing, Control Center broadcast picking,
/// and ReplayKit daemon/extension IPC are fail-closed. In-process types used
/// by broadcast-upload extensions (Telegram, element-ios) are real and
/// subclassable; they never claim that a sample ever left this process.
public let RPRecordingErrorDomain = "RPRecordingErrorDomain"

/// Attachment key for video sample orientation. The string equals the public
/// symbol name; confirm the Darwin runtime value before depending on it.
public let RPVideoSampleOrientationKey = "RPVideoSampleOrientationKey"

/// Key for a bundle identifier inside broadcast annotation dictionaries.
public let RPApplicationInfoBundleIdentifierKey =
    "RPApplicationInfoBundleIdentifierKey"

/// ScreenCaptureKit stream error domain re-exported by ReplayKit headers.
/// The string equals the public symbol name; confirm the Darwin value.
public let SCStreamErrorDomain = "SCStreamErrorDomain"

public enum RPSampleBufferType: Int, Sendable, Equatable, Hashable {
    case video = 1
    case audioApp = 2
    case audioMic = 3
}

public enum RPCameraPosition: Int, Sendable, Equatable, Hashable {
    case front = 1
    case back = 2
}

#if canImport(Darwin)

extension NSExtensionContext {
    open func completeRequest(
        withBroadcast broadcastURL: URL,
        broadcastConfiguration: RPBroadcastConfiguration,
        setupInfo: [String: any NSCoding & NSObjectProtocol]?
    ) {
        _ = (broadcastURL, broadcastConfiguration, setupInfo)
    }

    open func completeRequest(
        withBroadcast broadcastURL: URL,
        setupInfo: [String: any NSCoding & NSObjectProtocol]?
    ) {
        _ = (broadcastURL, setupInfo)
    }

    open func loadBroadcastingApplicationInfo(
        completion handler: @escaping (String, String, UIImage?) -> Void
    ) {
        handler("", "", nil)
    }
}

#endif
