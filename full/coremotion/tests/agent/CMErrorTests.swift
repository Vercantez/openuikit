@_spi(OpenUIKitHost) import CoreMotion
import Foundation

func coreMotionArchiveRoundTrip<T: NSObject & NSSecureCoding>(_ value: T) -> T {
    do {
        let data = try NSKeyedArchiver.archivedData(
            withRootObject: value,
            requiringSecureCoding: true
        )
        guard let decoded = try NSKeyedUnarchiver.unarchivedObject(
            ofClass: T.self,
            from: data
        ) else {
            fatalError("unarchive produced nil for \(T.self)")
        }
        return decoded
    } catch {
        fatalError("archive round-trip failed for \(T.self): \(error)")
    }
}

/// Enqueues fail-closed work without running it. The host test runner has no
/// run loop, so tests must return without waiting on queues.
func coreMotionEnqueueOnSuspendedQueue(_ start: (OperationQueue) -> Void) {
    let queue = OperationQueue()
    queue.name = "CoreMotion.suspended"
    queue.maxConcurrentOperationCount = 1
    queue.isSuspended = true
    start(queue)
    precondition(queue.operationCount >= 1, "fail-closed work must be enqueued")
    queue.cancelAllOperations()
}

func testCMErrorDomain() {
    precondition(CMErrorDomain == "CMErrorDomain")
    let error = NSError(
        domain: CMErrorDomain,
        code: Int(CMErrorNotAvailable.rawValue),
        userInfo: nil
    )
    precondition(error.domain == "CMErrorDomain")
    precondition(error.code == 109)
}

func testCMErrorRawValues() {
    let table: [(CMError, UInt32)] = [
        (CMErrorNULL, 100),
        (CMErrorDeviceRequiresMovement, 101),
        (CMErrorTrueNorthNotAvailable, 102),
        (CMErrorUnknown, 103),
        (CMErrorMotionActivityNotAvailable, 104),
        (CMErrorMotionActivityNotAuthorized, 105),
        (CMErrorMotionActivityNotEntitled, 106),
        (CMErrorInvalidParameter, 107),
        (CMErrorInvalidAction, 108),
        (CMErrorNotAvailable, 109),
        (CMErrorNotEntitled, 110),
        (CMErrorNotAuthorized, 111),
        (CMErrorNilData, 112),
        (CMErrorSize, 113),
    ]
    for (value, raw) in table {
        precondition(value.rawValue == raw)
        precondition(CMError(rawValue: raw) == value)
        precondition(CMError(raw) == value)
        precondition(value != CMError(raw + 1))
    }
    precondition(CMErrorNULL != CMErrorSize)
    precondition(CMError(rawValue: 7).rawValue == 7)
    var hasher = Hasher()
    CMErrorNotAvailable.hash(into: &hasher)
    precondition(CMErrorNotAvailable.hashValue != CMErrorNotEntitled.hashValue)
}
