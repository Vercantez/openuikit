import Foundation

#if canImport(UIKit)
import UIKit
#endif

/// Linux starting point for Apple's public ReplayKit module.
///
/// The isolated host gate compiles this module against Foundation only.
/// UIKit, CoreMedia, and Foundation.NSExtensionContext APIs are compiled
/// exclusively when those real modules are present. This module never
/// declares lookalike types under those names.
///
/// Screen capture, microphone/camera mixing, Control Center broadcast
/// picking, and ReplayKit daemon/extension IPC are fail-closed.
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

#if canImport(UIKit)

extension NSExtensionContext {
    /// Completes broadcast setup. Linux has no ReplayKit extension host, so
    /// this is a fail-closed no-op and does not start a session.
    public func completeRequest(
        withBroadcast broadcastURL: URL,
        broadcastConfiguration: RPBroadcastConfiguration,
        setupInfo: [String: any NSCoding & NSObjectProtocol]?
    ) {
        _ = (broadcastURL, broadcastConfiguration, setupInfo)
    }

    /// Completes broadcast setup. Linux has no ReplayKit extension host, so
    /// this is a fail-closed no-op and does not start a session.
    public func completeRequest(
        withBroadcast broadcastURL: URL,
        setupInfo: [String: any NSCoding & NSObjectProtocol]?
    ) {
        _ = (broadcastURL, setupInfo)
    }

    /// Loads the broadcasting app's identity. With no extension host the
    /// ObjC API still requires a callback, so this reports empty identity
    /// rather than inventing a bundle ID, display name, or icon.
    public func loadBroadcastingApplicationInfo(
        completion handler: @escaping (String, String, UIImage?) -> Void
    ) {
        handler("", "", nil)
    }
}

#endif
