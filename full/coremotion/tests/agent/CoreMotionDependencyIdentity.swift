@_spi(OpenUIKitHost) import CoreMotion
import Foundation

/// Future EC2 guest-Foundation identity probe.
///
/// Isolated `tests/acceptance/test_host.sh` compiles only `CoreMotionRuntime.swift`.
/// A later clean EC2 run should:
/// 1. Build the real guest Foundation module and `libFoundation.dylib`
/// 2. Build CoreMotion with that Foundation on `-I`/`-L`
/// 3. Link this file against both `libCoreMotion.dylib` and the guest Foundation
///    dylib (`import CoreMotion` and `import Foundation`)
/// 4. Run with `LD_LIBRARY_PATH` containing both dylibs
/// 5. Confirm `COREMOTION_AGENT_RUNTIME_OK` and that `libCoreMotion.dylib` is loaded
///
/// This file passes real Foundation `OperationQueue`, `Date`, `Measurement`,
/// `NSCoder`, and `NSError` values through public CoreMotion APIs. It does not
/// claim an integrated Linux sysroot from the isolated fan-out gate.
enum CoreMotionDependencyIdentity {
    static func check(_ condition: Bool, _ message: String) {
        if !condition {
            fatalError("COREMOTION_DEPENDENCY_IDENTITY_FAIL: \(message)")
        }
    }
}

final class CoreMotionDependencyIdentityBox: @unchecked Sendable {
    private let lock = NSLock()
    private var errors: [NSError] = []

    func add(_ error: Error?) {
        guard let error else { return }
        lock.lock()
        errors.append(error as NSError)
        lock.unlock()
    }

    var bridged: [NSError] {
        lock.lock()
        let copy = errors
        lock.unlock()
        return copy
    }
}

let queue = OperationQueue()
queue.name = "coremotion.dependency-identity"
queue.maxConcurrentOperationCount = 1
let box = CoreMotionDependencyIdentityBox()

let manager = CMMotionManager()
manager.startAccelerometerUpdates(to: queue) { data, error in
    CoreMotionDependencyIdentity.check(data == nil, "identity: no accel sample")
    box.add(error)
}
manager.startDeviceMotionUpdates(to: queue) { data, error in
    CoreMotionDependencyIdentity.check(data == nil, "identity: no device-motion sample")
    box.add(error)
}

let from = Date(timeIntervalSince1970: 1_700_000_000)
let to = Date(timeIntervalSince1970: 1_700_000_060)
CMAltimeter().startRelativeAltitudeUpdates(to: queue) { data, error in
    CoreMotionDependencyIdentity.check(data == nil, "identity: no altitude sample")
    box.add(error)
}
CMMotionActivityManager().queryActivityStarting(from: from, to: to, to: queue) { items, error in
    CoreMotionDependencyIdentity.check(items == nil, "identity: no activity history")
    box.add(error)
}
CMPedometer().queryPedometerData(from: from, to: to) { data, error in
    CoreMotionDependencyIdentity.check(data == nil, "identity: no pedometer sample")
    box.add(error)
}

queue.waitUntilAllOperationsAreFinished()
let bridged = box.bridged
CoreMotionDependencyIdentity.check(!bridged.isEmpty, "identity: Foundation NSError bridge")
for error in bridged {
    CoreMotionDependencyIdentity.check(error.domain == CMErrorDomain, "identity: NSError domain")
    CoreMotionDependencyIdentity.check(
        (error as? CMError) == CMErrorNotAvailable
            || error.domain == CMErrorDomain,
        "identity: CoreMotion error type"
    )
}

let pressure = CMAmbientPressureData(
    hostTimestamp: 1,
    pressure: Measurement(value: 101.325, unit: UnitPressure.kilopascals),
    temperature: Measurement(value: 22.0, unit: UnitTemperature.celsius)
)
CoreMotionDependencyIdentity.check(
    pressure.pressure.unit == UnitPressure.kilopascals,
    "identity: Measurement unit"
)
CoreMotionDependencyIdentity.check(pressure.temperature.value == 22.0, "identity: Measurement value")

let archived = try! NSKeyedArchiver.archivedData(
    withRootObject: pressure,
    requiringSecureCoding: true
)
let restored = try! NSKeyedUnarchiver.unarchivedObject(
    ofClass: CMAmbientPressureData.self,
    from: archived
)
CoreMotionDependencyIdentity.check(restored != nil, "identity: NSCoder round-trip")
CoreMotionDependencyIdentity.check(
    restored?.pressure.converted(to: .kilopascals).value == 101.325,
    "identity: NSCoder Measurement payload"
)
CoreMotionDependencyIdentity.check(
    restored?.timestamp == 1,
    "identity: NSCoder timestamp"
)

print("COREMOTION_AGENT_RUNTIME_OK")
