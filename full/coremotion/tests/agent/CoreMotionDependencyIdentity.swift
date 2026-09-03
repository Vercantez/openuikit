@_spi(OpenUIKitHost) import CoreMotion
import Foundation

// Future clean EC2 dependency-identity client. Isolated host-gate success
// against toolchain Foundation is not integrated guest-Foundation success.
//
// Expected EC2 steps (no local Docker):
// 1. Build the actual guest Foundation module and `libFoundation.dylib`.
// 2. Build CoreMotion with that Foundation on `-I` / `-L`.
// 3. Link this file as a client that imports CoreMotion and Foundation.
// 4. Run with `LD_LIBRARY_PATH` covering both dylibs.
// 5. Confirm `COREMOTION_DEPENDENCY_IDENTITY_OK` and that `libCoreMotion.dylib`
//    was loaded.

private let eventTimeout = DispatchTimeInterval.seconds(5)

private func waitEvent(_ semaphore: DispatchSemaphore, _ message: String) {
    precondition(semaphore.wait(timeout: .now() + eventTimeout) == .success, message)
}

private func assertNotCoreMotionType<T>(_ value: T) {
    precondition(!String(reflecting: type(of: value)).hasPrefix("CoreMotion."))
}

private func identityUnavailable(_ error: (any Error)?) {
    guard let error else {
        fatalError("expected fail-closed Foundation NSError")
    }
    let nsError = error as NSError
    precondition(type(of: nsError) == NSError.self)
    assertNotCoreMotionType(nsError)
    precondition(nsError.domain == CMErrorDomain)
    precondition(nsError.code == Int(CMErrorNotAvailable.rawValue))
}

private final class IdentityBlocker: @unchecked Sendable {
    private let occupied = DispatchSemaphore(value: 0)
    private let hold = DispatchSemaphore(value: 0)
    private let queue: OperationQueue

    init(queue: OperationQueue) {
        self.queue = queue
    }

    func occupy() {
        CoreMotionHostControl.enqueueCompletionProbe(on: queue) {
            self.occupied.signal()
            self.hold.wait()
        }
        waitEvent(occupied, "identity queue blocker did not start")
    }

    func release() {
        hold.signal()
    }
}

enum CoreMotionDependencyIdentity {
    static func main() {
        let _: Foundation.OperationQueue.Type = OperationQueue.self
        let _: Foundation.Date.Type = Date.self
        let _: Foundation.NSCoder.Type = NSCoder.self
        let _: Foundation.NSError.Type = NSError.self
        let _: Foundation.NSNumber.Type = NSNumber.self
        let _: Measurement<UnitPressure>.Type = Measurement<UnitPressure>.self
        let _: Measurement<UnitTemperature>.Type = Measurement<UnitTemperature>.self
        let _: Measurement<UnitLength>.Type = Measurement<UnitLength>.self

        let queue = OperationQueue()
        queue.name = "CoreMotion.identity"
        queue.maxConcurrentOperationCount = 1
        assertNotCoreMotionType(queue)

        let now = Date()
        assertNotCoreMotionType(now)

        let pressure = Measurement(value: 101.325, unit: UnitPressure.kilopascals)
        let temperature = Measurement(value: 20, unit: UnitTemperature.celsius)
        assertNotCoreMotionType(pressure)
        assertNotCoreMotionType(temperature)

        let ambient = CoreMotionHostControl.makeAmbientPressureData(
            timestamp: 1,
            pressure: pressure,
            temperature: temperature
        )
        precondition(ambient.pressure.unit == UnitPressure.kilopascals)
        precondition(ambient.temperature.unit == UnitTemperature.celsius)

        let manager = CMMotionManager()
        let blocker = IdentityBlocker(queue: queue)
        let done = DispatchSemaphore(value: 0)
        var returned = false
        var sawReturned = false
        blocker.occupy()
        manager.startAccelerometerUpdates(to: queue) { data, error in
            sawReturned = returned
            identityUnavailable(error)
            precondition(data == nil)
            done.signal()
        }
        returned = true
        blocker.release()
        waitEvent(done, "identity handler did not run")
        precondition(sawReturned)

        let item = CoreMotionHostControl.makeLogItem(timestamp: 3)
        do {
            let data = try NSKeyedArchiver.archivedData(
                withRootObject: item,
                requiringSecureCoding: true
            )
            assertNotCoreMotionType(data)
            let decoded = try NSKeyedUnarchiver.unarchivedObject(
                ofClass: CMLogItem.self,
                from: data
            )
            precondition(decoded?.timestamp == 3)
        } catch {
            fatalError("identity NSCoder round-trip failed: \(error)")
        }

        print("COREMOTION_DEPENDENCY_IDENTITY_OK")
    }
}

CoreMotionDependencyIdentity.main()
