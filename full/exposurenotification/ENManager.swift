import Dispatch
import Foundation

/// Linux Exposure Notification manager.
///
/// `authorizationStatus` is `.restricted`: Linux has no EN entitlement,
/// privacy prompt, or Bluetooth TEK radio. `exposureNotificationStatus`
/// stays `.unknown` until `invalidate()`, matching Apple's "unknown until
/// activate completes" description without claiming an active session.
///
/// `activate` and every daemon method fail closed. Completions run on the
/// caller thread so the sealed runner (no run loop) can observe them.
/// Apple's `dispatchQueue` hop is unobserved and recorded as an oracle
/// question.
public class ENManager: NSObject {
    public class var authorizationStatus: ENAuthorizationStatus { .restricted }

    public var activityHandler: ENActivityHandler?
    public var diagnosisKeysAvailableHandler: ENDiagnosisKeysAvailableHandler?
    public var dispatchQueue: dispatch_queue_t
    public var invalidationHandler: (() -> Void)?

    public private(set) var exposureNotificationEnabled: Bool
    public private(set) var exposureNotificationStatus: ENStatus

    private var invalidated = false
    private var invalidationHandlerCalled = false

    public override init() {
        self.dispatchQueue = DispatchQueue(label: "ExposureNotification.ENManager")
        self.exposureNotificationEnabled = false
        self.exposureNotificationStatus = .unknown
        super.init()
    }

    public func activate(completionHandler: @escaping ((any Error)?) -> Void) {
        completionHandler(failClosedError())
    }

    public func detectExposures(
        configuration: ENExposureConfiguration,
        completionHandler: @escaping ENDetectExposuresHandler
    ) -> Progress {
        _ = configuration
        return finishWithNilSummary(completionHandler)
    }

    public func detectExposures(
        configuration: ENExposureConfiguration,
        diagnosisKeyURLs: [URL],
        completionHandler: @escaping ENDetectExposuresHandler
    ) -> Progress {
        _ = configuration
        _ = diagnosisKeyURLs
        return finishWithNilSummary(completionHandler)
    }

    public func getDiagnosisKeys(completionHandler: @escaping ENGetDiagnosisKeysHandler) {
        completionHandler(nil, failClosedError())
    }

    public func diagnosisKeys() async throws -> [ENTemporaryExposureKey] {
        try await withCheckedThrowingContinuation { continuation in
            self.getDiagnosisKeys { keys, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: keys ?? [])
                }
            }
        }
    }

    public func getExposureInfo(
        summary: ENExposureDetectionSummary,
        userExplanation: String,
        completionHandler: @escaping ENGetExposureInfoHandler
    ) -> Progress {
        _ = summary
        _ = userExplanation
        let progress = cancelledProgress()
        completionHandler(nil, failClosedError())
        return progress
    }

    public func getExposureWindows(
        summary: ENExposureDetectionSummary,
        completionHandler: @escaping ENGetExposureWindowsHandler
    ) -> Progress {
        _ = summary
        let progress = cancelledProgress()
        completionHandler(nil, failClosedError())
        return progress
    }

    public func getTestDiagnosisKeys(
        completionHandler: @escaping ([ENTemporaryExposureKey]?, (any Error)?) -> Void
    ) {
        completionHandler(nil, failClosedError())
    }

    public func getUserTraveled(completionHandler: @escaping (Bool, (any Error)?) -> Void) {
        if invalidated {
            completionHandler(false, ENError(.invalidated))
            return
        }
        completionHandler(false, ENError(.travelStatusNotAvailable))
    }

    public func preAuthorizeDiagnosisKeys(completionHandler: @escaping ((any Error)?) -> Void) {
        completionHandler(failClosedError())
    }

    public func requestPreAuthorizedDiagnosisKeys(completionHandler: @escaping ((any Error)?) -> Void) {
        completionHandler(failClosedError())
    }

    public func setExposureNotificationEnabled(
        _ enabled: Bool,
        completionHandler: @escaping ENErrorHandler
    ) {
        _ = enabled
        completionHandler(failClosedError())
        // Never flip `exposureNotificationEnabled`; Linux cannot activate EN.
    }

    public func setExposureNotificationEnabled(_ enabled: Bool) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            self.setExposureNotificationEnabled(enabled) { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }

    public func invalidate() {
        guard !invalidated else { return }
        invalidated = true
        exposureNotificationStatus = .restricted
        exposureNotificationEnabled = false
        if !invalidationHandlerCalled {
            invalidationHandlerCalled = true
            invalidationHandler?()
        }
        activityHandler = nil
        diagnosisKeysAvailableHandler = nil
    }

    private func failClosedError() -> ENError {
        invalidated ? ENError(.invalidated) : ENError(.unsupported)
    }

    private func cancelledProgress() -> Progress {
        let progress = Progress(totalUnitCount: 1)
        progress.cancel()
        progress.completedUnitCount = 1
        return progress
    }

    private func finishWithNilSummary(
        _ completionHandler: @escaping ENDetectExposuresHandler
    ) -> Progress {
        finishDetect(failClosedError(), completionHandler)
    }

    private func finishDetect(
        _ error: ENError,
        _ completionHandler: @escaping ENDetectExposuresHandler
    ) -> Progress {
        let progress = cancelledProgress()
        completionHandler(nil, error)
        return progress
    }
}
