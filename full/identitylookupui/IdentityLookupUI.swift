/// Portable Linux starting point for Apple's public `IdentityLookupUI` module.
///
/// The classification-extension context flag and the view-controller
/// prepare/response state machine are real and process-local. Linux has no
/// SMS/Call Classification UI extension host, Messages/Phone reporting sheet,
/// or `NSExtensionContext` XPC: setting `isReadyForClassificationResponse` never
/// enables an Apple Done button, `prepare(for:)` never presents UI, and the
/// base `classificationResponse(for:)` never reports junk.
///
/// Apple annotates `ILClassificationUIExtensionViewController` `@MainActor`.
/// The isolated Linux host has no UIKit run loop, so the Linux type is
/// usable from synchronous tests.

import Foundation

#if canImport(IdentityLookup)
import IdentityLookup
#endif
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Fail-closed host errors

/// Linux-only result when a host asks to present Apple SMS/Call
/// Classification UI. Not an Apple NSError domain or extension error code.
public enum IdentityLookupUIUnavailable: Error, Equatable, Hashable, Sendable {
    case linuxHost(operation: String)
}

/// Process-local classification-UI phase. Not an Apple extension-host state.
public enum ILClassificationUIHostPhase: Equatable, Sendable {
    case idle
    case prepared
}

#if os(iOS) || os(tvOS) || os(watchOS) || os(visionOS) || os(macOS)
public typealias ILClassificationUIExtensionContextBase = NSExtensionContext
#else
public typealias ILClassificationUIExtensionContextBase = NSObject
#endif

// MARK: - ILClassificationUIExtensionContext

/// Classification UI extension context.
///
/// Darwin subclasses `NSExtensionContext`. Linux toolchain Foundation has no
/// `NSExtensionContext`, so this type subclasses `NSObject`. Mutating
/// `isReadyForClassificationResponse` never talks to an extension host.
open class ILClassificationUIExtensionContext: ILClassificationUIExtensionContextBase, @unchecked Sendable {
    private let lock = NSLock()
    private var readyForClassificationResponseStorage = false

    public override init() {
        super.init()
    }

    /// Whether the extension has enough information to complete the report.
    /// Defaults to `false`. Setting the flag is process-local; Linux never
    /// enables a system Done button or completes an Apple request.
    open var isReadyForClassificationResponse: Bool {
        get {
            lock.lock()
            defer { lock.unlock() }
            return readyForClassificationResponseStorage
        }
        set {
            lock.lock()
            readyForClassificationResponseStorage = newValue
            lock.unlock()
        }
    }
}

// MARK: - ILClassificationUIExtensionViewController

/// Base class for Unwanted Communication Reporting extension view controllers.
///
/// Darwin subclasses `UIViewController` and is `@MainActor`. Linux records
/// `prepare(for:)` inputs and never presents Messages/Phone reporting chrome.
open class ILClassificationUIExtensionViewController: UIViewController {
    private let storedExtensionContext = ILClassificationUIExtensionContext()
    private let lock = NSLock()
    private var preparedRequest: ILClassificationRequest?
    private var lastClassificationResponse: ILClassificationResponse?
    private var hostPhaseStorage: ILClassificationUIHostPhase = .idle

    public override init() {
        super.init()
    }

    /// Extension context for this controller. Linux vends a process-local
    /// context; it is not an Apple extension-host object.
    open var extensionContext: ILClassificationUIExtensionContext {
        storedExtensionContext
    }

    /// Default `prepare` records the request. It does not present UI and
    /// does not set `isReadyForClassificationResponse`. Subclasses override to
    /// supply their own Linux UI.
    open func prepare(for request: ILClassificationRequest) {
        lock.lock()
        preparedRequest = request
        hostPhaseStorage = .prepared
        lock.unlock()
    }

    /// Default response is `ILClassificationAction.none`. Linux never invents
    /// a junk / not-junk / block-sender report. Subclasses override to return
    /// the user's classification; the base class stays fail-closed.
    open func classificationResponse(for request: ILClassificationRequest) -> ILClassificationResponse {
        _ = request
        let response = ILClassificationResponse(action: .none)
        lock.lock()
        lastClassificationResponse = response
        lock.unlock()
        return response
    }

    @_spi(OpenUIKitHost)
    public var hostPreparedRequest: ILClassificationRequest? {
        lock.lock()
        defer { lock.unlock() }
        return preparedRequest
    }

    @_spi(OpenUIKitHost)
    public var hostLastClassificationResponse: ILClassificationResponse? {
        lock.lock()
        defer { lock.unlock() }
        return lastClassificationResponse
    }

    @_spi(OpenUIKitHost)
    public var hostPhase: ILClassificationUIHostPhase {
        lock.lock()
        defer { lock.unlock() }
        return hostPhaseStorage
    }
}

/// Linux host-test control. Not part of Apple's public IdentityLookupUI surface.
@_spi(OpenUIKitHost)
public enum IdentityLookupUIHostControl {
    /// Always throws. Linux never presents SMS/Call Classification UI.
    public static func presentClassificationUI() throws {
        throw IdentityLookupUIUnavailable.linuxHost(operation: "presentClassificationUI")
    }
}
