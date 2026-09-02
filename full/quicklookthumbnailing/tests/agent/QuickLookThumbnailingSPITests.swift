import Dispatch
import Foundation
@_spi(LinuxPort) import QuickLookThumbnailing

private final class QLTSPLocked<Value>: @unchecked Sendable {
    private let lock = NSLock()
    private var value: Value

    init(_ value: Value) {
        self.value = value
    }

    func load() -> Value {
        lock.lock()
        defer { lock.unlock() }
        return value
    }

    func store(_ value: Value) {
        lock.lock()
        self.value = value
        lock.unlock()
    }

    func increment() where Value == Int {
        lock.lock()
        self.value += 1
        lock.unlock()
    }
}

private func qltSPIErrorCode(_ error: (any Error)?) -> Int? {
    (error as NSError?)?.code
}

/// Blocked-queue / barrier harness. Ordinary `import QuickLookThumbnailing`
/// cannot see `callbackQueue`; this file is the SPI-positive proof.
func testCancelWhileOperationActive() {
    let generator = QLThumbnailGenerator()
    let request = QLThumbnailGenerator.Request(
        fileAt: URL(fileURLWithPath: "/tmp/qlt-active-cancel"),
        size: CGSize(width: 64, height: 48),
        scale: 2,
        representationTypes: .thumbnail
    )
    generator.callbackQueue.suspend()

    let didReturn = QLTSPLocked(false)
    let callbackAfterReturn = QLTSPLocked(false)
    let callbacks = QLTSPLocked(0)
    let callbackCode = QLTSPLocked<Int?>(nil)
    let semaphore = DispatchSemaphore(value: 0)
    generator.generateBestRepresentation(for: request) { _, error in
        callbackAfterReturn.store(didReturn.load())
        callbacks.increment()
        callbackCode.store(qltSPIErrorCode(error))
        semaphore.signal()
    }
    generator.cancel(request)
    didReturn.store(true)
    generator.callbackQueue.resume()
    semaphore.wait()
    precondition(callbackAfterReturn.load())
    precondition(callbacks.load() == 1)
    precondition(callbackCode.load() == QLThumbnailError.Code.requestCancelled.rawValue)
}

func testIndependentGeneratorCancellation() {
    let first = QLThumbnailGenerator()
    let second = QLThumbnailGenerator()
    let request = QLThumbnailGenerator.Request(
        fileAt: URL(fileURLWithPath: "/tmp/qlt-independent"),
        size: CGSize(width: 64, height: 48),
        scale: 2,
        representationTypes: .thumbnail
    )
    first.callbackQueue.suspend()
    second.callbackQueue.suspend()

    let firstCode = QLTSPLocked<Int?>(nil)
    let secondCode = QLTSPLocked<Int?>(nil)
    let firstCount = QLTSPLocked(0)
    let secondCount = QLTSPLocked(0)
    let firstDone = DispatchSemaphore(value: 0)
    let secondDone = DispatchSemaphore(value: 0)
    first.generateBestRepresentation(for: request) { _, error in
        firstCount.increment()
        firstCode.store(qltSPIErrorCode(error))
        firstDone.signal()
    }
    second.generateBestRepresentation(for: request) { _, error in
        secondCount.increment()
        secondCode.store(qltSPIErrorCode(error))
        secondDone.signal()
    }
    first.cancel(request)
    first.callbackQueue.resume()
    second.callbackQueue.resume()
    firstDone.wait()
    secondDone.wait()
    precondition(firstCount.load() == 1)
    precondition(secondCount.load() == 1)
    precondition(firstCode.load() == QLThumbnailError.Code.requestCancelled.rawValue)
    precondition(secondCode.load() == QLThumbnailError.Code.generationFailed.rawValue)
}

func testBlockedQueueCompletionAfterReturnExactlyOnce() {
    let generator = QLThumbnailGenerator()
    let request = QLThumbnailGenerator.Request(
        fileAt: URL(fileURLWithPath: "/tmp/qlt-blocked-queue"),
        size: CGSize(width: 16, height: 16),
        scale: 1,
        representationTypes: .icon
    )
    generator.callbackQueue.suspend()
    let didReturn = QLTSPLocked(false)
    let afterReturn = QLTSPLocked(false)
    let callbacks = QLTSPLocked(0)
    let semaphore = DispatchSemaphore(value: 0)
    generator.generateBestRepresentation(for: request) { _, _ in
        afterReturn.store(didReturn.load())
        callbacks.increment()
        semaphore.signal()
    }
    didReturn.store(true)
    precondition(callbacks.load() == 0)
    generator.callbackQueue.resume()
    semaphore.wait()
    precondition(afterReturn.load())
    precondition(callbacks.load() == 1)
}
