/// Portable Linux starting point for Apple's public `FileProviderUI` module.
///
/// Value types, error codes, and the action-extension request state machine
/// are real. Linux has no Files.app, File Provider UI extension host, or
/// Apple authentication sheet: `prepare(forAction:itemIdentifiers:)` and
/// `prepare(forError:)` record inputs without presenting UI, and
/// `completeRequest()` / `cancelRequest(withError:)` only mutate process-local
/// disposition. They never complete an Apple `NSExtensionContext` request.
///
/// Apple annotates `FPUIActionExtensionViewController` `@MainActor`. The
/// isolated Linux host has no UIKit run loop, so the Linux type is usable
/// from synchronous tests.

import Foundation

#if canImport(FileProvider)
import FileProvider
#endif
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Error domain

/// Apple's public File Provider UI error domain constant.
/// Identity matches the pinned `dotnet/macios` `[ErrorDomain ("FPUIErrorDomain")]`.
public let FPUIErrorDomain: String = "FPUIErrorDomain"

// MARK: - FPUIExtensionErrorCode

/// Bridged `NS_ENUM(NSUInteger, FPUIExtensionErrorCode)`.
///
/// Raw values follow the pinned `dotnet/macios` `[Native]` case order
/// (`UserCancelled`, then `Failed`). They are not taken from an Apple
/// runtime observation.
public enum FPUIExtensionErrorCode: UInt, Error, Hashable, Sendable {
    /// The user cancelled the File Provider UI action.
    case userCancelled = 0
    /// The requested File Provider UI action failed.
    case failed = 1
}

extension FPUIExtensionErrorCode: CustomNSError {
    public static var errorDomain: String { FPUIErrorDomain }

    public var errorCode: Int { Int(rawValue) }

    public var errorUserInfo: [String: Any] { [:] }
}

// MARK: - FPUIActionIdentifier

/// Swift overlay of `NSString * FPUIActionIdentifier NS_EXTENSIBLE_STRING_ENUM`.
///
/// The C export `_FPUIActionIdentifierAuthenticate` is in the TBD but is not
/// a public Swift-surface identifier. Its string payload is unobserved.
public struct FPUIActionIdentifier: RawRepresentable, Hashable, Sendable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public init(_ rawValue: String) {
        self.rawValue = rawValue
    }
}

// MARK: - Request disposition (Linux host)

/// Process-local action-extension request disposition.
/// Not an Apple `NSExtensionContext` host state.
public enum FPUIActionExtensionRequestDisposition: Equatable, Sendable {
    case active
    case completed
    case cancelled
}

// MARK: - FPUIActionExtensionContext

/// File Provider UI action-extension context.
///
/// Darwin subclasses `NSExtensionContext`. Linux toolchain Foundation has no
/// `NSExtensionContext`, so this type subclasses `NSObject`. Completing or
/// cancelling never talks to an extension host.
#if os(iOS) || os(tvOS) || os(watchOS) || os(visionOS) || os(macOS)
open class FPUIActionExtensionContext: NSExtensionContext, @unchecked Sendable {
#else
open class FPUIActionExtensionContext: NSObject, @unchecked Sendable {
#endif
    private struct State: @unchecked Sendable {
        var domainIdentifier: NSFileProviderDomainIdentifier?
        var disposition: FPUIActionExtensionRequestDisposition
        var cancellationError: (any Error)?
    }

    private let lock = NSLock()
    private var state: State

    public override init() {
        state = State(
            domainIdentifier: nil,
            disposition: .active,
            cancellationError: nil
        )
        super.init()
    }

    /// File Provider domain that owns the items. `nil` until a host injects
    /// one. Linux never invents a domain.
    open var domainIdentifier: NSFileProviderDomainIdentifier? {
        lock.lock()
        defer { lock.unlock() }
        return state.domainIdentifier
    }

    /// Marks the requested action complete. No-ops after the first terminal
    /// disposition. Does not notify an Apple extension host.
    open func completeRequest() {
        lock.lock()
        defer { lock.unlock() }
        guard state.disposition == .active else { return }
        state.disposition = .completed
    }

    /// Cancels the request with `error`. No-ops after the first terminal
    /// disposition. Does not notify an Apple extension host.
    open func cancelRequest(withError error: any Error) {
        lock.lock()
        defer { lock.unlock() }
        guard state.disposition == .active else { return }
        state.disposition = .cancelled
        state.cancellationError = error
    }

    @_spi(OpenUIKitHost)
    public var hostDisposition: FPUIActionExtensionRequestDisposition {
        lock.lock()
        defer { lock.unlock() }
        return state.disposition
    }

    @_spi(OpenUIKitHost)
    public var hostCancellationError: (any Error)? {
        lock.lock()
        defer { lock.unlock() }
        return state.cancellationError
    }

    @_spi(OpenUIKitHost)
    public func hostSetDomainIdentifier(_ identifier: NSFileProviderDomainIdentifier?) {
        lock.lock()
        defer { lock.unlock() }
        state.domainIdentifier = identifier
    }
}

// MARK: - FPUIActionExtensionViewController

/// File Provider UI action-extension view controller.
///
/// Darwin subclasses `UIViewController` and is `@MainActor`. Linux records
/// `prepare` inputs and never presents Files.app chrome, an authentication
/// sheet, or any other Apple UI.
open class FPUIActionExtensionViewController: UIViewController {
    private let storedExtensionContext = FPUIActionExtensionContext()
    private let lock = NSLock()
    private var lastActionIdentifier: String?
    private var lastItemIdentifiers: [NSFileProviderItemIdentifier]?
    private var lastError: (any Error)?

    public override init() {
        super.init()
    }

    /// Extension context for this controller. Linux vends a process-local
    /// context; it is not an Apple extension-host object.
    open var extensionContext: FPUIActionExtensionContext {
        storedExtensionContext
    }

    /// Default `prepare` records the action and items. It does not present
    /// UI. Subclasses override to supply their own Linux UI.
    open func prepare(
        forAction actionIdentifier: String,
        itemIdentifiers: [NSFileProviderItemIdentifier]
    ) {
        lock.lock()
        lastActionIdentifier = actionIdentifier
        lastItemIdentifiers = itemIdentifiers
        lastError = nil
        lock.unlock()
    }

    /// Default `prepare` records the error. It does not present UI.
    /// Subclasses override to supply their own Linux UI.
    open func prepare(forError error: any Error) {
        lock.lock()
        lastError = error
        lastActionIdentifier = nil
        lastItemIdentifiers = nil
        lock.unlock()
    }

    @_spi(OpenUIKitHost)
    public var hostPreparedActionIdentifier: String? {
        lock.lock()
        defer { lock.unlock() }
        return lastActionIdentifier
    }

    @_spi(OpenUIKitHost)
    public var hostPreparedItemIdentifiers: [NSFileProviderItemIdentifier]? {
        lock.lock()
        defer { lock.unlock() }
        return lastItemIdentifiers
    }

    @_spi(OpenUIKitHost)
    public var hostPreparedError: (any Error)? {
        lock.lock()
        defer { lock.unlock() }
        return lastError
    }
}
