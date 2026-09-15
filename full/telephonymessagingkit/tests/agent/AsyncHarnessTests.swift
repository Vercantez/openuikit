import Foundation
import TelephonyMessagingKit

/// Blocking bridge for the fail-closed `async throws` service methods.
///
/// The sealed host runner invokes every cited test synchronously, so async
/// service calls cannot be awaited at the call site. This helper (in an
/// uncited file) parks the calling thread on a semaphore while a cooperative
/// `Task` drives the async work to completion. Every bridged method below
/// throws immediately on Linux (no telephony daemon), so the wait is bounded
/// and no run loop or main-queue pumping is involved.
final class TMKAsyncBox: @unchecked Sendable {
    var error: Error?
}

func tmkRunBlocking(_ work: @escaping @Sendable () async throws -> Void) {
    let gate = DispatchSemaphore(value: 0)
    let box = TMKAsyncBox()
    Task {
        do {
            try await work()
        } catch {
            box.error = error
        }
        gate.signal()
    }
    gate.wait()
    if let error = box.error {
        preconditionFailure("tmkRunBlocking captured async error: \(error)")
    }
}
