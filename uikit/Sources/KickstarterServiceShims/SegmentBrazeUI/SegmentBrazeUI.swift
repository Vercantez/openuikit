// Fail-closed stand-in for SegmentBrazeUI (braze-inc/braze-segment-swift
// 6.0.0, 6579644c). Surface = what ios-oss touches:
//   Kickstarter-iOS/AppDelegate.swift:519-556 `BrazeDestination(additional
//     Configuration:brazeReadyCallback:)` added to Segment with add(plugin:)
//   Library/Tracking/KSRAnalytics.swift imports the module (no member use)
//
// The real destination creates its Braze instance only after Segment's CDN
// settings for the write key arrive. The shim's Segment never fetches
// settings, so the destination never activates: `additionalConfiguration`
// and `brazeReadyCallback` are stored and NEVER called, no Braze instance
// exists, and every event reaching the destination (none do) is dropped.
// `braze` is always nil.
@_exported import BrazeKit
import BrazeUI
import Foundation
@_exported import Segment

public final class BrazeDestination: DestinationPlugin {
    public let key = "Appboy"
    public let type = PluginType.destination
    public weak var analytics: Analytics?

    public let additionalConfiguration: ((Braze.Configuration) -> Void)?
    public let brazeReadyCallback: ((Braze) -> Void)?

    /// Always nil: the destination never activates.
    public var braze: Braze? { nil }

    public init(
        additionalConfiguration: ((Braze.Configuration) -> Void)? = nil,
        brazeReadyCallback: ((Braze) -> Void)? = nil
    ) {
        self.additionalConfiguration = additionalConfiguration
        self.brazeReadyCallback = brazeReadyCallback
    }

    public func identify(event: IdentifyEvent) -> IdentifyEvent? { nil }
    public func track(event: TrackEvent) -> TrackEvent? { nil }
}
