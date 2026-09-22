// Fail-closed stand-in for BrazeUI from braze-swift-sdk 12.1.0 (c630122e).
// The only call site is Kickstarter-iOS/AppDelegate.swift:539,
// `braze.inAppMessagePresenter = BrazeUI.BrazeInAppMessageUI()`, inside the
// Braze ready callback that the fail-closed SegmentBrazeUI destination never
// calls. The presenter presents nothing: no in-app message ever arrives.
import BrazeKit
import Foundation

public final class BrazeInAppMessageUI: BrazeInAppMessagePresenter {
    public init() {}

    /// Not SDK API. Always 0: no message is ever presented.
    public var presentedMessageCount: Int { 0 }
}
