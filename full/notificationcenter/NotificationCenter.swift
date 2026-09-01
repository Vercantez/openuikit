// Portable Linux starting point for Apple's public NotificationCenter surface.
//
// Today View / widget-extension APIs are source-compatible value types, a
// providing protocol with Swift defaults, a process-local widget controller,
// and Foundation/UIKit extension shims. Linux has no SpringBoard, Today View
// host, or Notification Center compositor; host-facing calls record local
// intent and never report that an Apple daemon accepted them.

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

// MARK: - Portable UIKit stand-ins (Foundation-only Linux host)

#if !canImport(UIKit)

/// Linux stand-in for UIKit's `UIEdgeInsets`. Used only when UIKit is absent.
public struct UIEdgeInsets: Equatable, Sendable {
    public var top: CGFloat
    public var left: CGFloat
    public var bottom: CGFloat
    public var right: CGFloat

    public static let zero = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)

    public init(top: CGFloat, left: CGFloat, bottom: CGFloat, right: CGFloat) {
        self.top = top
        self.left = left
        self.bottom = bottom
        self.right = right
    }
}

/// Linux stand-in for UIKit's `UIVibrancyEffectStyle`. Named cases match the
/// iOS 13 `NS_ENUM` order; raw values are sequential from zero pending an
/// Apple-oracle confirmation.
public enum UIVibrancyEffectStyle: Int, Equatable, Hashable, Sendable {
    case label = 0
    case secondaryLabel = 1
    case tertiaryLabel = 2
    case quaternaryLabel = 3
    case fill = 4
    case secondaryFill = 5
    case tertiaryFill = 6
    case separator = 7
}

/// Inert Linux stand-in for UIKit's `UIVibrancyEffect`.
///
/// Factory methods return distinguishable placeholders. They do not apply
/// Apple blur, vibrancy, or Notification Center visual treatment.
open class UIVibrancyEffect: NSObject, @unchecked Sendable {
    public enum PortableKind: Equatable, Hashable, Sendable {
        case notificationCenter
        case widgetPrimary
        case widgetSecondary
        case widget(style: UIVibrancyEffectStyle)
    }

    public let portableKind: PortableKind

    public init(portableKind: PortableKind) {
        self.portableKind = portableKind
        super.init()
    }

    @MainActor
    open class func notificationCenter() -> UIVibrancyEffect {
        UIVibrancyEffect(portableKind: .notificationCenter)
    }

    @MainActor
    open class func widgetPrimary() -> UIVibrancyEffect {
        UIVibrancyEffect(portableKind: .widgetPrimary)
    }

    @MainActor
    open class func widgetSecondary() -> UIVibrancyEffect {
        UIVibrancyEffect(portableKind: .widgetSecondary)
    }

    @MainActor
    open class func widgetEffect(
        forVibrancyStyle vibrancyStyle: UIVibrancyEffectStyle
    ) -> UIVibrancyEffect {
        UIVibrancyEffect(portableKind: .widget(style: vibrancyStyle))
    }
}

#else

extension UIVibrancyEffect {
    @MainActor
    public class func notificationCenter() -> UIVibrancyEffect {
        UIVibrancyEffect()
    }

    @MainActor
    public class func widgetPrimary() -> UIVibrancyEffect {
        UIVibrancyEffect()
    }

    @MainActor
    public class func widgetSecondary() -> UIVibrancyEffect {
        UIVibrancyEffect()
    }

    @MainActor
    public class func widgetEffect(
        forVibrancyStyle vibrancyStyle: UIVibrancyEffectStyle
    ) -> UIVibrancyEffect {
        _ = vibrancyStyle
        return UIVibrancyEffect()
    }
}

#endif

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

    func widgetMarginInsets(
        forProposedMarginInsets defaultMarginInsets: UIEdgeInsets
    ) -> UIEdgeInsets
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

    /// Default: accept the proposed insets. Exact Apple default-margin
    /// constants are not claimed.
    public func widgetMarginInsets(
        forProposedMarginInsets defaultMarginInsets: UIEdgeInsets
    ) -> UIEdgeInsets {
        defaultMarginInsets
    }

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

// MARK: - NSExtensionContext widget surface

#if os(iOS) || os(tvOS)

extension NSExtensionContext {
    private static let modeLock = NSLock()
    private static var largestModes: [ObjectIdentifier: NCWidgetDisplayMode] = [:]
    private static var activeModes: [ObjectIdentifier: NCWidgetDisplayMode] = [:]
    private static var maximumSizes: [ObjectIdentifier: [NCWidgetDisplayMode: CGSize]] = [:]

    public var widgetLargestAvailableDisplayMode: NCWidgetDisplayMode {
        get {
            Self.modeLock.lock()
            let value = Self.largestModes[ObjectIdentifier(self)] ?? .compact
            Self.modeLock.unlock()
            return value
        }
        set {
            Self.modeLock.lock()
            Self.largestModes[ObjectIdentifier(self)] = newValue
            Self.modeLock.unlock()
        }
    }

    public var widgetActiveDisplayMode: NCWidgetDisplayMode {
        Self.modeLock.lock()
        let value = Self.activeModes[ObjectIdentifier(self)] ?? .compact
        Self.modeLock.unlock()
        return value
    }

    public func widgetMaximumSize(for displayMode: NCWidgetDisplayMode) -> CGSize {
        Self.modeLock.lock()
        let value = Self.maximumSizes[ObjectIdentifier(self)]?[displayMode] ?? .zero
        Self.modeLock.unlock()
        return value
    }

    @_spi(OpenUIKitHost)
    public func setPortableActiveDisplayMode(_ mode: NCWidgetDisplayMode) {
        Self.modeLock.lock()
        Self.activeModes[ObjectIdentifier(self)] = mode
        Self.modeLock.unlock()
    }

    @_spi(OpenUIKitHost)
    public func setPortableWidgetMaximumSize(
        _ size: CGSize,
        for displayMode: NCWidgetDisplayMode
    ) {
        Self.modeLock.lock()
        var table = Self.maximumSizes[ObjectIdentifier(self)] ?? [:]
        table[displayMode] = size
        Self.maximumSizes[ObjectIdentifier(self)] = table
        Self.modeLock.unlock()
    }
}

#else

/// Linux stand-in for Foundation's `NSExtensionContext`.
///
/// Widget geometry is host-injected. Without a host, active mode is compact
/// and maximum sizes are `CGSize.zero` so this module does not invent Apple
/// Today View compact (110pt) or expanded metrics.
open class NSExtensionContext: NSObject, @unchecked Sendable {
    private let stateLock = NSLock()
    private var largestAvailableDisplayMode: NCWidgetDisplayMode = .compact
    private var activeDisplayModeStorage: NCWidgetDisplayMode = .compact
    private var maximumSizes: [NCWidgetDisplayMode: CGSize] = [:]

    public override init() {
        super.init()
    }

    open var widgetLargestAvailableDisplayMode: NCWidgetDisplayMode {
        get {
            stateLock.lock()
            let value = largestAvailableDisplayMode
            stateLock.unlock()
            return value
        }
        set {
            stateLock.lock()
            largestAvailableDisplayMode = newValue
            stateLock.unlock()
        }
    }

    open var widgetActiveDisplayMode: NCWidgetDisplayMode {
        stateLock.lock()
        let value = activeDisplayModeStorage
        stateLock.unlock()
        return value
    }

    open func widgetMaximumSize(for displayMode: NCWidgetDisplayMode) -> CGSize {
        stateLock.lock()
        let value = maximumSizes[displayMode] ?? .zero
        stateLock.unlock()
        return value
    }

    @_spi(OpenUIKitHost)
    public func setPortableActiveDisplayMode(_ mode: NCWidgetDisplayMode) {
        stateLock.lock()
        activeDisplayModeStorage = mode
        stateLock.unlock()
    }

    @_spi(OpenUIKitHost)
    public func setPortableWidgetMaximumSize(
        _ size: CGSize,
        for displayMode: NCWidgetDisplayMode
    ) {
        stateLock.lock()
        maximumSizes[displayMode] = size
        stateLock.unlock()
    }
}

#endif
