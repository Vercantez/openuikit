// Portable Linux starting point for Apple's public `BusinessChat` module.
//
// Value types (`BCChatAction.Parameter`, `BCChatButton.Style`) and fail-closed
// action recording are real. Linux has no Messages.app, Business Chat /
// Messages for Business daemon, or Apple business-chat entitlement: 
// `openTranscript` records the request and never opens a transcript, and
// `BCChatButton` stores a style without presenting Messages chrome.
//
// Darwin types: https://developer.apple.com/documentation/businesschat

import Foundation

#if canImport(UIKit)
import UIKit
#endif

// MARK: - Fail-closed host error

/// Fail-closed error for Messages.app, Business Chat daemon, entitlement,
/// or Apple-service paths. Linux never invents a successful transcript open.
public enum BusinessChatUnavailable: Error, Equatable, Sendable {
    case linuxHost(operation: String)
}

// MARK: - Host registry

final class BusinessChatHostRegistry: @unchecked Sendable {
    static let shared = BusinessChatHostRegistry()

    private let lock = NSLock()
    private var storedIdentifier: String?
    private var storedParameters: [BCChatAction.Parameter: String]?
    private var storedDidOpen = false

    var lastOpenTranscript: (
        businessIdentifier: String,
        intentParameters: [BCChatAction.Parameter: String]
    )? {
        lock.lock()
        defer { lock.unlock() }
        guard let storedIdentifier, let storedParameters else { return nil }
        return (storedIdentifier, storedParameters)
    }

    var didOpenTranscript: Bool {
        lock.lock()
        defer { lock.unlock() }
        return storedDidOpen
    }

    func recordOpenTranscript(
        businessIdentifier: String,
        intentParameters: [BCChatAction.Parameter: String]
    ) {
        lock.lock()
        storedIdentifier = businessIdentifier
        storedParameters = intentParameters
        storedDidOpen = false
        lock.unlock()
    }

    func reset() {
        lock.lock()
        storedIdentifier = nil
        storedParameters = nil
        storedDidOpen = false
        lock.unlock()
    }
}

/// Linux host-test control. Hidden from ordinary `import BusinessChat`
/// clients and not part of Apple's public BusinessChat surface.
@_spi(OpenUIKitHost)
public enum BusinessChatHostControl {
    public static func reset() {
        BusinessChatHostRegistry.shared.reset()
    }

    public static func lastOpenTranscript() -> (
        businessIdentifier: String,
        intentParameters: [BCChatAction.Parameter: String]
    )? {
        BusinessChatHostRegistry.shared.lastOpenTranscript
    }

    /// Darwin opens Messages. Linux never does.
    public static func didOpenTranscript() -> Bool {
        BusinessChatHostRegistry.shared.didOpenTranscript
    }

    /// Attempts the Darwin `openTranscript` path. Linux always fails closed.
    public static func openTranscriptResult() -> Result<Void, BusinessChatUnavailable> {
        .failure(.linuxHost(operation: "openTranscript"))
    }

    public static func style(of button: BCChatButton) -> BCChatButton.Style {
        button.hostStyle
    }
}

// MARK: - BCChatAction

/// Actions for opening a Messages for Business transcript.
///
/// Darwin subclasses `NSObject` and is deprecated as of iOS 16.1 in the
/// pinned graph (macios records 16.2; see `oracle-questions.tsv`). Linux
/// records `openTranscript` inputs and never talks to Messages.
open class BCChatAction: NSObject {
    /// Matches the pinned `dotnet/macios` `[DisableDefaultCtor]` annotation.
    @available(*, unavailable)
    public override init() {
        fatalError("BCChatAction is not constructible")
    }

    /// Opens the transcript for `businessIdentifier` with `intentParameters`.
    ///
    /// Darwin hands the request to Messages. Linux records the identifier and
    /// parameters, then returns without opening a transcript or constructing
    /// a `https://bcrw.apple.com` URL.
    open class func openTranscript(
        businessIdentifier: String,
        intentParameters: [BCChatAction.Parameter: String]
    ) {
        BusinessChatHostRegistry.shared.recordOpenTranscript(
            businessIdentifier: businessIdentifier,
            intentParameters: intentParameters
        )
    }
}

extension BCChatAction {
    /// Swift overlay of `NSString * BCParameterName NS_TYPED_ENUM`.
    ///
    /// Static members use the ObjC constant *names* exported by the TBD
    /// (`_BCParameterNameIntent`, `_BCParameterNameGroup`,
    /// `_BCParameterNameBody`) as `rawValue`. The Darwin NSString payloads
    /// are unobserved; see `oracle-questions.tsv`.
    public struct Parameter: RawRepresentable, Hashable, Sendable {
        public let rawValue: String

        public init(rawValue: String) {
            self.rawValue = rawValue
        }

        public init(_ rawValue: String) {
            self.rawValue = rawValue
        }

        /// ObjC constant `BCParameterNameIntent`.
        public static let intent = Parameter(rawValue: "BCParameterNameIntent")

        /// ObjC constant `BCParameterNameGroup`.
        public static let group = Parameter(rawValue: "BCParameterNameGroup")

        /// ObjC constant `BCParameterNameBody`.
        public static let body = Parameter(rawValue: "BCParameterNameBody")
    }
}

// MARK: - BCChatButton

/// A Messages for Business entry-point button.
///
/// Darwin subclasses `UIControl` and is `@MainActor`. Isolated host
/// compilation has Foundation only, so the Linux type subclasses `NSObject`
/// unless UIKit is on the link line. The sealed runner has no run loop, so
/// `@MainActor` is omitted (see `oracle-questions.tsv`). Linux stores `style`
/// and never presents Messages chrome.
#if canImport(UIKit)
open class BCChatButton: UIControl {
#else
open class BCChatButton: NSObject {
#endif
    /// Bridged `NS_ENUM(NSInteger, BCChatButtonStyle)`.
    ///
    /// Raw values follow the pinned `dotnet/macios` `[Native]` case order
    /// (`Light = 0`, then `Dark`). They are not taken from an Apple runtime
    /// observation.
    public enum Style: Int, Hashable, Sendable {
        case light = 0
        case dark = 1
    }

    let hostStyle: Style

    /// Designated initializer. Records `style` and does not draw Apple's
    /// Business Chat artwork.
    public init(style: Style) {
        self.hostStyle = style
#if canImport(UIKit)
        super.init(frame: .zero)
#else
        super.init()
#endif
    }

    /// Nib/archive decoding. Linux has no Apple UI archive and always fails
    /// closed with `nil`.
#if canImport(UIKit)
    public required init?(coder: NSCoder) {
        _ = coder
        return nil
    }
#else
    public init?(coder: NSCoder) {
        _ = coder
        return nil
    }
#endif
}
