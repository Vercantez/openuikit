@_exported import Foundation

/// Linux starting point for Apple's public `AppTrackingTransparency` module.
///
/// Linux has no ATT system prompt, IDFA, or privacy Settings pane. Tracking
/// is never authorized. `ATTrackingManager.trackingAuthorizationStatus` is
/// always `.denied`, and `requestTrackingAuthorization` delivers `.denied`
/// asynchronously on one private serial queue, exactly once per call.

// MARK: - Completion delivery
//
// Completions hop once onto `AppTrackingTransparency.ATTrackingManager.completion`
// with `async`, never `sync`. Nested callback calls therefore enqueue behind the
// running handler. Tests occupy this serial queue through host SPI to prove
// non-inline delivery. Exactly-once is one scheduled block plus a per-invocation
// flag.

private struct ATTUncheckedWork: @unchecked Sendable {
    let body: () -> Void
}

private final class ATTOnceFlag: @unchecked Sendable {
    private let lock = NSLock()
    private var delivered = false

    func take() -> Bool {
        lock.lock()
        defer { lock.unlock() }
        if delivered {
            return false
        }
        delivered = true
        return true
    }
}

private let attCompletionQueue = DispatchQueue(
    label: "AppTrackingTransparency.ATTrackingManager.completion",
    qos: .utility
)

/// Linux host-test control. Hidden from ordinary `import AppTrackingTransparency`
/// clients and absent from Apple's public ATT surface.
@_spi(OpenUIKitHost)
public enum AppTrackingTransparencyHostControl {
    public static func enqueueCompletionProbe(
        _ body: @escaping @Sendable () -> Void
    ) {
        attCompletionQueue.async(execute: body)
    }
}

private func attDeliver(_ body: @escaping () -> Void) {
    let once = ATTOnceFlag()
    let work = ATTUncheckedWork(body: body)
    attCompletionQueue.async {
        guard once.take() else { return }
        work.body()
    }
}

// MARK: - ATTrackingManager

/// A manager that requests authorization to track the user. Linux never grants
/// tracking: there is no prompt, no IDFA, and no Settings toggle.
open class ATTrackingManager: NSObject {
    /// Public `NS_ENUM` overlay for `ATTrackingManagerAuthorizationStatus`.
    /// Raw values `0...3` match the public sequential `NS_ENUM` in
    /// `ATTrackingManager.h` (SDK input recorded in `reference/sdk-inputs.tsv`;
    /// header bytes are not vendored).
    public enum AuthorizationStatus: UInt, Sendable, Hashable {
        case notDetermined = 0
        case restricted = 1
        case denied = 2
        case authorized = 3
    }

    /// Linux has no ATT prompt or privacy Settings value. Tracking is not
    /// permitted, so the status is always `.denied`. This never reports
    /// `.authorized` or `.notDetermined`.
    open class var trackingAuthorizationStatus: AuthorizationStatus {
        .denied
    }

    /// Requests tracking authorization. Linux never shows a prompt. The
    /// completion is delivered asynchronously on
    /// `AppTrackingTransparency.ATTrackingManager.completion` with `.denied`,
    /// exactly once. The method returns before the handler runs.
    open class func requestTrackingAuthorization(
        completionHandler completion: @escaping (AuthorizationStatus) -> Void
    ) {
        attDeliver {
            completion(.denied)
        }
    }

    /// Swift async overlay of `requestTrackingAuthorization(completionHandler:)`.
    /// Shares the same fail-closed delivery path. Always returns `.denied`.
    open class func requestTrackingAuthorization() async -> AuthorizationStatus {
        await withCheckedContinuation { continuation in
            requestTrackingAuthorization { status in
                continuation.resume(returning: status)
            }
        }
    }
}
