// Portable Linux starting point for Apple's public NotificationCenter surface.
//
// Today View / widget-extension APIs are source-compatible value types, a
// providing protocol with Swift defaults, and a process-local widget
// controller. Linux has no SpringBoard, Today View host, or Notification
// Center compositor; host-facing calls record local intent and never report
// that an Apple daemon accepted them.
//
// Geometry and vibrancy types are UIKit's. Extension-context identity is
// Foundation's. This file does not declare UIEdgeInsets, UIVibrancyEffect, or
// NSExtensionContext.

import Foundation

#if canImport(UIKit)
import UIKit
#endif

// MARK: - Update result

/// Result of a Today View widget update pass.
///
/// Raw values follow the public `NS_ENUM(NSUInteger, NCUpdateResult)` order
/// from `NCWidgetProviding.h`: `newData`, `noData`, `failed`.
public enum NCUpdateResult: UInt, Equatable, Hashable, Sendable {
    case newData = 0
    case noData = 1
    case failed = 2
}

// MARK: - Display mode

/// Compact or expanded Today View display mode.
///
/// Raw values follow the public `NS_ENUM(NSInteger, NCWidgetDisplayMode)`
/// order from `NCWidgetTypes.h`: `compact`, `expanded`.
public enum NCWidgetDisplayMode: Int, Equatable, Hashable, Sendable {
    case compact = 0
    case expanded = 1
}

// MARK: - Widget providing

/// Today View widget update protocol. Objective-C optional requirements are
/// expressed as Swift protocol defaults so ordinary `NSObject` conformers can
/// implement the same source surface without an ObjC runtime.
public protocol NCWidgetProviding: NSObjectProtocol {
    func widgetPerformUpdate(
        completionHandler: @escaping (NCUpdateResult) -> Void
    )

    func widgetActiveDisplayModeDidChange(
        _ activeDisplayMode: NCWidgetDisplayMode,
        withMaximumSize maxSize: CGSize
    )

#if canImport(UIKit)
    func widgetMarginInsets(
        forProposedMarginInsets defaultMarginInsets: UIEdgeInsets
    ) -> UIEdgeInsets
#endif
}

extension NCWidgetProviding {
    /// Default: no new content. Does not fabricate a successful Apple fetch.
    public func widgetPerformUpdate(
        completionHandler: @escaping (NCUpdateResult) -> Void
    ) {
        completionHandler(.noData)
    }

    public func widgetActiveDisplayModeDidChange(
        _ activeDisplayMode: NCWidgetDisplayMode,
        withMaximumSize maxSize: CGSize
    ) {
        _ = (activeDisplayMode, maxSize)
    }

#if canImport(UIKit)
    /// Default: accept the proposed insets. Exact Apple default-margin
    /// constants are not claimed.
    public func widgetMarginInsets(
        forProposedMarginInsets defaultMarginInsets: UIEdgeInsets
    ) -> UIEdgeInsets {
        defaultMarginInsets
    }
#endif

    /// Swift overlay of the completion-handler requirement. The canonical
    /// public-surface identifier is the completion-handler form; this async
    /// witness is the conflicting raw-graph duplicate of the same precise ID.
    public func widgetPerformUpdate() async -> NCUpdateResult {
        await withCheckedContinuation { continuation in
            widgetPerformUpdate { result in
                continuation.resume(returning: result)
            }
        }
    }
}

// MARK: - Widget controller

/// Process-local widget content-flag controller.
///
/// Apple's controller talks to SpringBoard over an entitlement-gated XPC
/// connection (`NCWidgetControllerHasContentEntitlement`). Linux has no such
/// host: `setHasContent` records the requested flag and never reports that
/// the system Today View hid or showed the widget.
open class NCWidgetController: NSObject {
    private static let storeLock = NSLock()
    private static var contentFlags: [String: Bool] = [:]

    /// Linux has no Notification Center / Today View widget host.
    open class var systemWidgetHostAvailable: Bool { false }

    open class func widgetController() -> NCWidgetController {
        NCWidgetController()
    }

    public override init() {
        super.init()
    }

    open func setHasContent(
        _ flag: Bool,
        forWidgetWithBundleIdentifier bundleID: String
    ) {
        Self.storeLock.lock()
        Self.contentFlags[bundleID] = flag
        Self.storeLock.unlock()
    }

    /// Host-readable copy of flags recorded by `setHasContent`. `nil` means
    /// the identifier has never been written in this process.
    @_spi(OpenUIKitHost)
    public func portableHasContent(
        forWidgetWithBundleIdentifier bundleID: String
    ) -> Bool? {
        Self.storeLock.lock()
        let value = Self.contentFlags[bundleID]
        Self.storeLock.unlock()
        return value
    }

    @_spi(OpenUIKitHost)
    public func resetPortableContentFlags() {
        Self.storeLock.lock()
        Self.contentFlags.removeAll()
        Self.storeLock.unlock()
    }
}
