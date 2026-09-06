import Foundation

/// Coordinates TV-provider access. Linux has no Video Subscriber Account
/// daemon, entitlement, or UIKit presentation host.
///
/// `enqueue` completes on the caller thread with `VSError.unsupported`.
/// The Swift overlay `checkAccessStatus(options:)` is `async throws` and
/// likewise fails closed; the isolated runner cannot await it.
open class VSAccountManager: NSObject {
    public weak var delegate: (any VSAccountManagerDelegate)?

    /// Swift overlay of `checkAccessStatusWithOptions:completionHandler:`.
    /// Always throws `VSError.unsupported`; never returns `.granted`.
    open func checkAccessStatus(
        options: [VSCheckAccessOption: Any] = [:]
    ) async throws -> VSAccountAccessStatus {
        _ = options
        throw VideoSubscriberAccountLinux.unsupportedError()
    }

    /// ObjC completion overlay retained from the raw graph. Completes
    /// synchronously with `.notDetermined` plus `VSError.unsupported`.
    open func checkAccessStatus(
        options: [VSCheckAccessOption: Any] = [:],
        completionHandler: @escaping (VSAccountAccessStatus, (any Error)?) -> Void
    ) {
        _ = options
        completionHandler(.notDetermined, VideoSubscriberAccountLinux.unsupportedError())
    }

    @discardableResult
    open func enqueue(
        _ request: VSAccountMetadataRequest,
        completionHandler: @escaping (VSAccountMetadata?, (any Error)?) -> Void
    ) -> VSAccountManagerResult {
        _ = request
        let result = VSAccountManagerResult()
        completionHandler(nil, VideoSubscriberAccountLinux.unsupportedError())
        return result
    }
}

/// Cancellable handle for an in-flight metadata request. Linux completes
/// before return, so `cancel()` is a no-op.
open class VSAccountManagerResult: NSObject {
    private var cancelled = false

    open func cancel() {
        cancelled = true
    }

    public var isCancelled: Bool { cancelled }
}

/// Delegate for authentication UI. The required present/dismiss methods
/// take UIKit `UIViewController` and are deferred: this module does not
/// publish a UIKit lookalike. The optional authentication gate is real.
public protocol VSAccountManagerDelegate: NSObjectProtocol {
    func accountManager(
        _ accountManager: VSAccountManager,
        shouldAuthenticateAccountProviderWithIdentifier accountProviderIdentifier: String
    ) -> Bool
}

extension VSAccountManagerDelegate {
    public func accountManager(
        _ accountManager: VSAccountManager,
        shouldAuthenticateAccountProviderWithIdentifier accountProviderIdentifier: String
    ) -> Bool {
        _ = accountManager
        _ = accountProviderIdentifier
        return false
    }
}
