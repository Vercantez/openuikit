import Dispatch
import Foundation
import ExposureNotification

private func expectUnsupported(_ error: (any Error)?) {
    let ns = (error as NSError?) ?? { preconditionFailure("missing error") }()
    precondition(ns.domain == ENErrorDomain)
    precondition(ns.code == ENError.Code.unsupported.rawValue)
}

private func expectCode(_ error: (any Error)?, _ code: ENError.Code) {
    let ns = (error as NSError?) ?? { preconditionFailure("missing error") }()
    precondition(ns.domain == ENErrorDomain)
    precondition(ns.code == code.rawValue)
}

func testENManagerInitState() {
    let manager = ENManager()
    precondition(manager.exposureNotificationEnabled == false)
    precondition(manager.exposureNotificationStatus == .unknown)
    precondition(manager.activityHandler == nil)
    precondition(manager.diagnosisKeysAvailableHandler == nil)
    precondition(manager.invalidationHandler == nil)
}

func testENManagerAuthorizationStatus() {
    precondition(ENManager.authorizationStatus == .restricted)
    precondition(ENManager.authorizationStatus != .authorized)
    precondition(ENManager.authorizationStatus != .unknown)
}

func testENManagerActivateFailClosed() {
    let manager = ENManager()
    var called = false
    manager.activate { error in
        called = true
        expectUnsupported(error)
    }
    precondition(called)
    precondition(manager.exposureNotificationEnabled == false)
    precondition(manager.exposureNotificationStatus == .unknown)
}

func testENManagerInvalidate() {
    let manager = ENManager()
    var invalidated = 0
    manager.invalidationHandler = { invalidated += 1 }
    manager.invalidate()
    precondition(invalidated == 1)
    precondition(manager.exposureNotificationStatus == .restricted)
    precondition(manager.exposureNotificationEnabled == false)
    precondition(manager.activityHandler == nil)
    precondition(manager.diagnosisKeysAvailableHandler == nil)

    manager.invalidate()
    precondition(invalidated == 1)

    var after = false
    manager.activate { error in
        after = true
        expectCode(error, .invalidated)
    }
    precondition(after)
}

func testENManagerDetectExposures() {
    let manager = ENManager()
    let config = ENExposureConfiguration()
    var called = false
    let progress = manager.detectExposures(configuration: config) { summary, error in
        called = true
        precondition(summary == nil)
        expectUnsupported(error)
    }
    precondition(called)
    precondition(progress.isCancelled)
}

func testENManagerDetectExposuresWithURLs() {
    let manager = ENManager()
    let config = ENExposureConfiguration()
    let url = URL(fileURLWithPath: "/tmp/en-keys.bin")
    var called = false
    let progress = manager.detectExposures(
        configuration: config,
        diagnosisKeyURLs: [url]
    ) { summary, error in
        called = true
        precondition(summary == nil)
        expectUnsupported(error)
    }
    precondition(called)
    precondition(progress.isCancelled)
    precondition(progress.completedUnitCount == 1)
}

func testENManagerGetExposureInfo() {
    let manager = ENManager()
    let summary = ENExposureDetectionSummary()
    var called = false
    let progress = manager.getExposureInfo(
        summary: summary,
        userExplanation: "linux host"
    ) { infos, error in
        called = true
        precondition(infos == nil)
        expectUnsupported(error)
    }
    precondition(called)
    precondition(progress.isCancelled)
}

func testENManagerGetExposureWindows() {
    let manager = ENManager()
    let summary = ENExposureDetectionSummary()
    var called = false
    let progress = manager.getExposureWindows(summary: summary) { windows, error in
        called = true
        precondition(windows == nil)
        expectUnsupported(error)
    }
    precondition(called)
    precondition(progress.isCancelled)
}

func testENManagerGetTestDiagnosisKeys() {
    let manager = ENManager()
    var called = false
    manager.getTestDiagnosisKeys { keys, error in
        called = true
        precondition(keys == nil)
        expectUnsupported(error)
    }
    precondition(called)
}

func testENManagerGetDiagnosisKeys() {
    let manager = ENManager()
    var called = false
    manager.getDiagnosisKeys { keys, error in
        called = true
        precondition(keys == nil)
        expectUnsupported(error)
    }
    precondition(called)
}

func testENManagerGetUserTraveled() {
    let manager = ENManager()
    var called = false
    manager.getUserTraveled { traveled, error in
        called = true
        precondition(traveled == false)
        expectCode(error, .travelStatusNotAvailable)
    }
    precondition(called)

    manager.invalidate()
    var after = false
    manager.getUserTraveled { traveled, error in
        after = true
        precondition(traveled == false)
        expectCode(error, .invalidated)
    }
    precondition(after)
}

func testENManagerSetExposureNotificationEnabled() {
    let manager = ENManager()
    var called = false
    manager.setExposureNotificationEnabled(true) { error in
        called = true
        expectUnsupported(error)
    }
    precondition(called)
    precondition(manager.exposureNotificationEnabled == false)

    manager.invalidate()
    var after = false
    manager.setExposureNotificationEnabled(false) { error in
        after = true
        expectCode(error, .invalidated)
    }
    precondition(after)
}

func testENManagerPreAuthorizeDiagnosisKeys() {
    let manager = ENManager()
    var called = false
    manager.preAuthorizeDiagnosisKeys { error in
        called = true
        expectUnsupported(error)
    }
    precondition(called)
}

func testENManagerRequestPreAuthorizedDiagnosisKeys() {
    let manager = ENManager()
    var called = false
    manager.requestPreAuthorizedDiagnosisKeys { error in
        called = true
        expectUnsupported(error)
    }
    precondition(called)
}

func testENManagerHandlers() {
    let manager = ENManager()
    var activitySeen: ENActivityFlags?
    manager.activityHandler = { flags in activitySeen = flags }
    manager.activityHandler?(.periodicRun)
    precondition(activitySeen == .periodicRun)

    var keysSeen: [ENTemporaryExposureKey]?
    manager.diagnosisKeysAvailableHandler = { keys in keysSeen = keys }
    manager.diagnosisKeysAvailableHandler?([])
    precondition(keysSeen?.isEmpty == true)
}

func testENManagerDispatchQueue() {
    let manager = ENManager()
    let queue = DispatchQueue(label: "en.tests.queue")
    manager.dispatchQueue = queue
    precondition(manager.dispatchQueue === queue)
}

func testENManagerInvalidatedDaemonMethods() {
    let manager = ENManager()
    manager.invalidate()
    var detect = false
    _ = manager.detectExposures(configuration: ENExposureConfiguration()) { summary, error in
        detect = true
        precondition(summary == nil)
        expectCode(error, .invalidated)
    }
    precondition(detect)

    var keys = false
    manager.getTestDiagnosisKeys { keysResult, error in
        keys = true
        precondition(keysResult == nil)
        expectCode(error, .invalidated)
    }
    precondition(keys)
}
