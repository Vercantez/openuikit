@_spi(OpenUIKitHost) import CoreMotion
import Foundation

enum CoreMotionRuntimeProbe {
    static func check(_ condition: Bool, _ message: String) {
        if !condition {
            fatalError("COREMOTION_AGENT_RUNTIME_FAIL: \(message)")
        }
    }
}

final class ErrorBox: @unchecked Sendable {
    private let lock = NSLock()
    private var values: [String: Error?] = [:]
    private var count = 0

    func set(_ key: String, _ error: Error?) {
        lock.lock()
        values[key] = error
        lock.unlock()
    }

    func get(_ key: String) -> Error? {
        lock.lock()
        let value = values[key] ?? nil
        lock.unlock()
        return value
    }

    func increment() {
        lock.lock()
        count += 1
        lock.unlock()
    }

    var total: Int {
        lock.lock()
        let value = count
        lock.unlock()
        return value
    }
}

final class HeadphoneDelegateProbe: NSObject, CMHeadphoneMotionManagerDelegate {
    var connected = 0
    var disconnected = 0

    func headphoneMotionManagerDidConnect(_ manager: CMHeadphoneMotionManager) {
        _ = manager
        connected += 1
    }

    func headphoneMotionManagerDidDisconnect(_ manager: CMHeadphoneMotionManager) {
        _ = manager
        disconnected += 1
    }
}

final class WaterDelegateProbe: NSObject, CMWaterSubmersionManagerDelegate {
    let lock = NSLock()
    var errors = 0
    var events = 0
    var measurements = 0
    var temperatures = 0

    func manager(_ manager: CMWaterSubmersionManager, didUpdate event: CMWaterSubmersionEvent) {
        _ = manager
        _ = event
        lock.lock()
        events += 1
        lock.unlock()
    }

    func manager(
        _ manager: CMWaterSubmersionManager,
        didUpdate measurement: CMWaterSubmersionMeasurement
    ) {
        _ = manager
        _ = measurement
        lock.lock()
        measurements += 1
        lock.unlock()
    }

    func manager(_ manager: CMWaterSubmersionManager, didUpdate measurement: CMWaterTemperature) {
        _ = manager
        _ = measurement
        lock.lock()
        temperatures += 1
        lock.unlock()
    }

    func manager(_ manager: CMWaterSubmersionManager, errorOccurred error: any Error) {
        _ = manager
        _ = error
        lock.lock()
        errors += 1
        lock.unlock()
    }
}

func probeValueTypes() {
    CoreMotionRuntimeProbe.check(
        (CMErrorNotAvailable as NSError).domain == CMErrorDomain,
        "error domain bridges through NSError"
    )
    CoreMotionRuntimeProbe.check(CMErrorNotAvailable == CMErrorNotAvailable, "error identity")
    CoreMotionRuntimeProbe.check(CMErrorNotAvailable != CMErrorNULL, "named errors are distinct")
    CoreMotionRuntimeProbe.check(CMErrorNotAvailable != CMErrorUnknown, "not-available != unknown")
    CoreMotionRuntimeProbe.check(
        CMError(rawValue: CMErrorNotAvailable.rawValue) == CMErrorNotAvailable,
        "error round-trip preserves named constant"
    )
    CoreMotionRuntimeProbe.check(
        CMError(CMErrorNotAvailable.rawValue) == CMErrorNotAvailable,
        "unlabeled init round-trip"
    )
    var hasher = Hasher()
    CMErrorNotAvailable.hash(into: &hasher)
    CMErrorNULL.hash(into: &hasher)
    CoreMotionRuntimeProbe.check(
        Set([CMErrorNotAvailable, CMErrorNULL]).count == 2,
        "error hashing distinguishes named constants"
    )

    var frames: CMAttitudeReferenceFrame = []
    CoreMotionRuntimeProbe.check(frames.isEmpty, "empty frames")
    frames.insert(.xArbitraryZVertical)
    CoreMotionRuntimeProbe.check(frames.contains(.xArbitraryZVertical), "contains arbitrary")
    frames.formUnion(.xMagneticNorthZVertical)
    CoreMotionRuntimeProbe.check(
        frames.contains(.xMagneticNorthZVertical),
        "union magnetic"
    )
    let combined = CMAttitudeReferenceFrame.xArbitraryCorrectedZVertical.union(
        .xTrueNorthZVertical
    )
    CoreMotionRuntimeProbe.check(
        combined.contains(.xTrueNorthZVertical)
            && combined.contains(.xArbitraryCorrectedZVertical),
        "corrected+true"
    )
    CoreMotionRuntimeProbe.check(
        combined.intersection(.xTrueNorthZVertical) == .xTrueNorthZVertical,
        "intersection"
    )
    CoreMotionRuntimeProbe.check(
        !combined.isDisjoint(with: .xTrueNorthZVertical),
        "not disjoint"
    )
    CoreMotionRuntimeProbe.check(combined.isSuperset(of: .xTrueNorthZVertical), "superset")
    CoreMotionRuntimeProbe.check(combined.isSubset(of: combined), "subset")
    CoreMotionRuntimeProbe.check(
        !combined.isStrictSubset(of: combined),
        "strict subset"
    )
    CoreMotionRuntimeProbe.check(
        combined.isStrictSuperset(of: .xTrueNorthZVertical),
        "strict superset"
    )
    var mutable = combined
    mutable.subtract(.xTrueNorthZVertical)
    CoreMotionRuntimeProbe.check(!mutable.contains(.xTrueNorthZVertical), "subtract")
    CoreMotionRuntimeProbe.check(
        combined.subtracting(.xTrueNorthZVertical) == .xArbitraryCorrectedZVertical,
        "subtracting"
    )
    var symmetric = CMAttitudeReferenceFrame.xArbitraryZVertical
    symmetric.formSymmetricDifference(.xMagneticNorthZVertical)
    CoreMotionRuntimeProbe.check(
        symmetric.contains(.xArbitraryZVertical)
            && symmetric.contains(.xMagneticNorthZVertical),
        "symmetric"
    )
    CoreMotionRuntimeProbe.check(
        CMAttitudeReferenceFrame.xArbitraryZVertical.symmetricDifference(
            .xArbitraryZVertical
        ).isEmpty,
        "symmetric empty"
    )
    var intersect = combined
    intersect.formIntersection(.xTrueNorthZVertical)
    CoreMotionRuntimeProbe.check(intersect == .xTrueNorthZVertical, "form intersection")
    var unioned: CMAttitudeReferenceFrame = .xArbitraryZVertical
    unioned.formUnion(.xMagneticNorthZVertical)
    _ = unioned.remove(.xArbitraryZVertical)
    _ = unioned.update(with: .xTrueNorthZVertical)
    let fromSequence = CMAttitudeReferenceFrame([.xArbitraryZVertical, .xTrueNorthZVertical])
    CoreMotionRuntimeProbe.check(fromSequence.contains(.xTrueNorthZVertical), "sequence init")
    let fromLiteral: CMAttitudeReferenceFrame = [.xArbitraryZVertical]
    CoreMotionRuntimeProbe.check(fromLiteral.contains(.xArbitraryZVertical), "array literal")

    CoreMotionRuntimeProbe.check(
        CMAuthorizationStatus.authorized != .denied,
        "auth cases distinct"
    )
    CoreMotionRuntimeProbe.check(
        Set([CMAuthorizationStatus.denied, .restricted, .notDetermined, .authorized]).count == 4,
        "auth hashing"
    )
    hasher = Hasher()
    CMAuthorizationStatus.denied.hash(into: &hasher)
    CoreMotionRuntimeProbe.check(
        CMMagneticFieldCalibrationAccuracy.uncalibrated != .high,
        "mag accuracy cases"
    )
    CoreMotionRuntimeProbe.check(CMMotionActivityConfidence.low != .high, "activity conf")
    CoreMotionRuntimeProbe.check(CMPedometerEventType.pause != .resume, "pedo event")
    CoreMotionRuntimeProbe.check(CMOdometerOriginDevice.local != .remote, "odo origin")
    CoreMotionRuntimeProbe.check(
        CMHighFrequencyHeartRateDataConfidence.low != .highest,
        "hr conf"
    )
    CoreMotionRuntimeProbe.check(
        CMDeviceMotion.SensorLocation.default != .headphoneLeft,
        "sensor loc"
    )
    CoreMotionRuntimeProbe.check(
        CMHeadphoneActivityManager.Status.disconnected != .connected,
        "hp status"
    )
    CoreMotionRuntimeProbe.check(
        CMWaterSubmersionEvent.State.notSubmerged != .submerged,
        "sub event"
    )
    CoreMotionRuntimeProbe.check(
        CMWaterSubmersionMeasurement.DepthState.notSubmerged
            != .pastMaxDepth,
        "depth state"
    )

    let accel = CMAcceleration(x: 0.1, y: -0.2, z: 0.9)
    CoreMotionRuntimeProbe.check(accel.x == 0.1 && accel.y == -0.2 && accel.z == 0.9, "accel")
    CoreMotionRuntimeProbe.check(CMAcceleration().x == 0 && CMAcceleration().y == 0, "accel zero")
    let rate = CMRotationRate(x: 1, y: 2, z: 3)
    CoreMotionRuntimeProbe.check(rate.y == 2 && CMRotationRate().x == 0, "gyro struct")
    let field = CMMagneticField(x: 4, y: 5, z: 6)
    CoreMotionRuntimeProbe.check(field.z == 6 && CMMagneticField().y == 0, "mag struct")
    let quat = CMQuaternion(x: 0, y: 0, z: 0, w: 1)
    CoreMotionRuntimeProbe.check(quat.w == 1 && quat.x == 0, "quat")
    let matrix = CMRotationMatrix(
        m11: 1, m12: 0, m13: 0,
        m21: 0, m22: 1, m23: 0,
        m31: 0, m32: 0, m33: 1
    )
    CoreMotionRuntimeProbe.check(matrix.m22 == 1 && matrix.m11 == 1, "matrix")
    let calibrated = CMCalibratedMagneticField(field: field, accuracy: .high)
    CoreMotionRuntimeProbe.check(
        calibrated.field.x == 4 && calibrated.accuracy == .high,
        "cal mag"
    )
}

func probeAttitudeMath() {
    let identity = CMAttitude(hostQuaternion: CMQuaternion(x: 0, y: 0, z: 0, w: 1))
    CoreMotionRuntimeProbe.check(identity.quaternion.w == 1, "stored quaternion")
    CoreMotionRuntimeProbe.check(abs(identity.roll) < 1e-9, "internal identity roll")
    CoreMotionRuntimeProbe.check(abs(identity.pitch) < 1e-9, "internal identity pitch")
    CoreMotionRuntimeProbe.check(abs(identity.yaw) < 1e-9, "internal identity yaw")
    CoreMotionRuntimeProbe.check(
        abs(identity.rotationMatrix.m11 - 1) < 1e-9
            && abs(identity.rotationMatrix.m22 - 1) < 1e-9
            && abs(identity.rotationMatrix.m33 - 1) < 1e-9,
        "internal identity matrix diagonal"
    )
    let other = CMAttitude(hostQuaternion: CMQuaternion(x: 0, y: 0, z: 0, w: 1))
    identity.multiply(byInverseOf: other)
    CoreMotionRuntimeProbe.check(
        abs(identity.quaternion.w - 1) < 1e-9
            && abs(identity.quaternion.x) < 1e-9,
        "multiply by inverse of identity is a no-op"
    )

    let encoded = try! NSKeyedArchiver.archivedData(
        withRootObject: identity,
        requiringSecureCoding: true
    )
    let decoded = try! NSKeyedUnarchiver.unarchivedObject(ofClass: CMAttitude.self, from: encoded)
    CoreMotionRuntimeProbe.check(decoded?.quaternion.w == 1, "attitude coder")
}

func probeMotionManager() {
    let manager = CMMotionManager()
    CoreMotionRuntimeProbe.check(!manager.isAccelerometerAvailable, "accel available")
    CoreMotionRuntimeProbe.check(!manager.isGyroAvailable, "gyro available")
    CoreMotionRuntimeProbe.check(!manager.isMagnetometerAvailable, "mag available")
    CoreMotionRuntimeProbe.check(!manager.isDeviceMotionAvailable, "dm available")
    CoreMotionRuntimeProbe.check(manager.accelerometerData == nil, "accel data")
    CoreMotionRuntimeProbe.check(manager.gyroData == nil, "gyro data")
    CoreMotionRuntimeProbe.check(manager.magnetometerData == nil, "mag data")
    CoreMotionRuntimeProbe.check(manager.deviceMotion == nil, "dm data")
    CoreMotionRuntimeProbe.check(
        CMMotionManager.availableAttitudeReferenceFrames().isEmpty,
        "available frames"
    )
    manager.accelerometerUpdateInterval = 0.02
    manager.gyroUpdateInterval = 0.03
    manager.magnetometerUpdateInterval = 0.04
    manager.deviceMotionUpdateInterval = 0.05
    manager.showsDeviceMovementDisplay = true
    CoreMotionRuntimeProbe.check(manager.accelerometerUpdateInterval == 0.02, "accel interval")
    CoreMotionRuntimeProbe.check(manager.gyroUpdateInterval == 0.03, "gyro interval")
    CoreMotionRuntimeProbe.check(manager.magnetometerUpdateInterval == 0.04, "mag interval")
    CoreMotionRuntimeProbe.check(manager.deviceMotionUpdateInterval == 0.05, "dm interval")
    CoreMotionRuntimeProbe.check(manager.showsDeviceMovementDisplay, "movement display storage")

    manager.startAccelerometerUpdates()
    CoreMotionRuntimeProbe.check(!manager.isAccelerometerActive, "accel stays inactive")
    manager.stopAccelerometerUpdates()
    manager.startGyroUpdates()
    manager.startMagnetometerUpdates()
    manager.startDeviceMotionUpdates()
    CoreMotionRuntimeProbe.check(!manager.isGyroActive, "gyro stays inactive")
    CoreMotionRuntimeProbe.check(!manager.isMagnetometerActive, "mag stays inactive")
    CoreMotionRuntimeProbe.check(!manager.isDeviceMotionActive, "dm stays inactive")
    manager.startDeviceMotionUpdates(using: .xMagneticNorthZVertical)
    CoreMotionRuntimeProbe.check(!manager.isDeviceMotionActive, "using-frame stays inactive")
    CoreMotionRuntimeProbe.check(
        manager.attitudeReferenceFrame.isEmpty,
        "failed start does not fabricate a reference frame"
    )
    manager.stopGyroUpdates()
    manager.stopMagnetometerUpdates()
    manager.stopDeviceMotionUpdates()

    let queue = OperationQueue()
    queue.maxConcurrentOperationCount = 1
    queue.name = "coremotion.runtime.motion"
    let box = ErrorBox()
    manager.startAccelerometerUpdates(to: queue) { data, error in
        CoreMotionRuntimeProbe.check(data == nil, "no fabricated accel")
        box.set("accel", error)
    }
    CoreMotionRuntimeProbe.check(!manager.isAccelerometerActive, "push accel stays inactive")
    manager.startGyroUpdates(to: queue) { data, error in
        CoreMotionRuntimeProbe.check(data == nil, "no fabricated gyro")
        box.set("gyro", error)
    }
    manager.startMagnetometerUpdates(to: queue) { data, error in
        CoreMotionRuntimeProbe.check(data == nil, "no fabricated mag")
        box.set("mag", error)
    }
    manager.startDeviceMotionUpdates(to: queue) { data, error in
        CoreMotionRuntimeProbe.check(data == nil, "no fabricated dm")
        box.set("dm", error)
    }
    manager.startDeviceMotionUpdates(using: .xTrueNorthZVertical, to: queue) { data, error in
        CoreMotionRuntimeProbe.check(data == nil, "no fabricated dm using")
        box.set("dmUsing", error)
    }
    CoreMotionRuntimeProbe.check(!manager.isDeviceMotionActive, "queued dm stays inactive")
    queue.waitUntilAllOperationsAreFinished()
    for key in ["accel", "gyro", "mag", "dm", "dmUsing"] {
        CoreMotionRuntimeProbe.check(
            (box.get(key) as? CMError) == CMErrorNotAvailable,
            "fail-closed sensor error \(key)"
        )
    }
    manager.stopAccelerometerUpdates()
    manager.stopGyroUpdates()
    manager.stopMagnetometerUpdates()
    manager.stopDeviceMotionUpdates()
}

func probeEnvironmentManagers() {
    CoreMotionRuntimeProbe.check(!CMAltimeter.isRelativeAltitudeAvailable(), "rel alt")
    CoreMotionRuntimeProbe.check(!CMAltimeter.isAbsoluteAltitudeAvailable(), "abs alt")
    CoreMotionRuntimeProbe.check(CMAltimeter.authorizationStatus() == .denied, "alt auth")
    CoreMotionRuntimeProbe.check(!CMMotionActivityManager.isActivityAvailable(), "activity avail")
    CoreMotionRuntimeProbe.check(
        CMMotionActivityManager.authorizationStatus() == .denied,
        "activity auth"
    )
    CoreMotionRuntimeProbe.check(!CMPedometer.isStepCountingAvailable(), "steps")
    CoreMotionRuntimeProbe.check(!CMPedometer.isDistanceAvailable(), "distance")
    CoreMotionRuntimeProbe.check(!CMPedometer.isFloorCountingAvailable(), "floors")
    CoreMotionRuntimeProbe.check(!CMPedometer.isPaceAvailable(), "pace")
    CoreMotionRuntimeProbe.check(!CMPedometer.isCadenceAvailable(), "cadence")
    CoreMotionRuntimeProbe.check(!CMPedometer.isPedometerEventTrackingAvailable(), "pedo events")
    CoreMotionRuntimeProbe.check(CMPedometer.authorizationStatus() == .denied, "pedo auth")
    CoreMotionRuntimeProbe.check(!CMStepCounter.isStepCountingAvailable(), "step counter")
    CoreMotionRuntimeProbe.check(!CMSensorRecorder.isAccelerometerRecordingAvailable(), "recorder")
    CoreMotionRuntimeProbe.check(!CMSensorRecorder.isAuthorizedForRecording(), "recorder authz")
    CoreMotionRuntimeProbe.check(CMSensorRecorder.authorizationStatus() == .denied, "recorder auth")
    CoreMotionRuntimeProbe.check(!CMBatchedSensorManager.isAccelerometerSupported, "batched accel")
    CoreMotionRuntimeProbe.check(!CMBatchedSensorManager.isDeviceMotionSupported, "batched dm")
    CoreMotionRuntimeProbe.check(
        CMBatchedSensorManager.authorizationStatus == .denied,
        "batched auth"
    )

    let queue = OperationQueue()
    queue.name = "coremotion.runtime.env"
    let box = ErrorBox()
    let altimeter = CMAltimeter()
    altimeter.startRelativeAltitudeUpdates(to: queue) { data, error in
        CoreMotionRuntimeProbe.check(data == nil, "no alt")
        CoreMotionRuntimeProbe.check((error as? CMError) == CMErrorNotAvailable, "alt err")
        box.increment()
    }
    altimeter.stopRelativeAltitudeUpdates()
    altimeter.startAbsoluteAltitudeUpdates(to: queue) { data, error in
        CoreMotionRuntimeProbe.check(data == nil, "no abs alt")
        CoreMotionRuntimeProbe.check((error as? CMError) == CMErrorNotAvailable, "abs alt err")
        box.increment()
    }
    altimeter.stopAbsoluteAltitudeUpdates()

    let activity = CMMotionActivityManager()
    let from = Date(timeIntervalSince1970: 10)
    let to = Date(timeIntervalSince1970: 20)
    activity.queryActivityStarting(from: from, to: to, to: queue) { items, error in
        CoreMotionRuntimeProbe.check(items == nil, "no activity query")
        CoreMotionRuntimeProbe.check((error as? CMError) == CMErrorNotAvailable, "activity err")
        box.increment()
    }
    activity.startActivityUpdates(to: queue) { sample in
        CoreMotionRuntimeProbe.check(sample == nil, "activity stream must stay nil")
        fatalError("COREMOTION_AGENT_RUNTIME_FAIL: activity stream must stay inert")
    }
    activity.stopActivityUpdates()

    let pedometer = CMPedometer()
    pedometer.queryPedometerData(from: from, to: to) { data, error in
        CoreMotionRuntimeProbe.check(data == nil, "no pedo query")
        CoreMotionRuntimeProbe.check((error as? CMError) == CMErrorNotAvailable, "pedo err")
        box.increment()
    }
    pedometer.startUpdates(from: from) { data, error in
        CoreMotionRuntimeProbe.check(data == nil, "no pedo stream")
        CoreMotionRuntimeProbe.check((error as? CMError) == CMErrorNotAvailable, "pedo stream err")
        box.increment()
    }
    pedometer.stopUpdates()
    pedometer.startEventUpdates { event, error in
        CoreMotionRuntimeProbe.check(event == nil, "no pedo event")
        CoreMotionRuntimeProbe.check((error as? CMError) == CMErrorNotAvailable, "pedo event err")
        box.increment()
    }
    pedometer.stopEventUpdates()

    let steps = CMStepCounter()
    steps.queryStepCountStarting(from: from, to: to, to: queue) { count, error in
        CoreMotionRuntimeProbe.check(count == 0, "no steps")
        CoreMotionRuntimeProbe.check((error as? CMError) == CMErrorNotAvailable, "step err")
        box.increment()
    }
    steps.startStepCountingUpdates(to: queue, updateOn: 1) { count, date, error in
        CoreMotionRuntimeProbe.check(count == 0, "no live steps")
        CoreMotionRuntimeProbe.check((error as? CMError) == CMErrorNotAvailable, "live step err")
        _ = date.timeIntervalSince1970
        box.increment()
    }
    steps.stopStepCountingUpdates()

    let recorder = CMSensorRecorder()
    recorder.recordAccelerometer(forDuration: 10)
    CoreMotionRuntimeProbe.check(
        recorder.accelerometerData(from: from, to: to) == nil,
        "no recorded accel"
    )

    let batched = CMBatchedSensorManager()
    CoreMotionRuntimeProbe.check(batched.accelerometerDataFrequency == 0, "batch freq")
    CoreMotionRuntimeProbe.check(batched.deviceMotionDataFrequency == 0, "dm freq")
    CoreMotionRuntimeProbe.check(batched.accelerometerBatch == nil, "accel batch")
    CoreMotionRuntimeProbe.check(batched.deviceMotionBatch == nil, "dm batch")
    batched.startAccelerometerUpdates()
    CoreMotionRuntimeProbe.check(!batched.isAccelerometerActive, "batch accel stays inactive")
    batched.startAccelerometerUpdates { data, error in
        CoreMotionRuntimeProbe.check(data == nil, "no batch accel")
        CoreMotionRuntimeProbe.check((error as? CMError) == CMErrorNotAvailable, "batch accel err")
        box.increment()
    }
    CoreMotionRuntimeProbe.check(!batched.isAccelerometerActive, "batch accel handler inactive")
    batched.stopAccelerometerUpdates()
    batched.startDeviceMotionUpdates()
    CoreMotionRuntimeProbe.check(!batched.isDeviceMotionActive, "batch dm stays inactive")
    batched.startDeviceMotionUpdates { data, error in
        CoreMotionRuntimeProbe.check(data == nil, "no batch dm")
        CoreMotionRuntimeProbe.check((error as? CMError) == CMErrorNotAvailable, "batch dm err")
        box.increment()
    }
    batched.stopDeviceMotionUpdates()
    CoreMotionRuntimeProbe.check(!batched.isDeviceMotionActive, "batch dm stopped")

    queue.waitUntilAllOperationsAreFinished()
    CoreMotionRuntimeProbe.check(box.total >= 10, "environment callbacks \(box.total)")
}

func probeAccessoryManagers() {
    CoreMotionRuntimeProbe.check(
        CMHeadphoneMotionManager.authorizationStatus() == .denied,
        "hp motion auth"
    )
    CoreMotionRuntimeProbe.check(
        CMHeadphoneActivityManager.authorizationStatus() == .denied,
        "hp activity auth"
    )
    CoreMotionRuntimeProbe.check(
        CMWaterSubmersionManager.authorizationStatus == .denied,
        "water auth"
    )
    CoreMotionRuntimeProbe.check(!CMWaterSubmersionManager.waterSubmersionAvailable, "water avail")

    let headphones = CMHeadphoneMotionManager()
    let delegate = HeadphoneDelegateProbe()
    headphones.delegate = delegate
    CoreMotionRuntimeProbe.check(headphones.delegate === delegate, "hp delegate stored")
    CoreMotionRuntimeProbe.check(!headphones.isDeviceMotionAvailable, "hp dm avail")
    CoreMotionRuntimeProbe.check(headphones.deviceMotion == nil, "hp dm")
    headphones.startDeviceMotionUpdates()
    CoreMotionRuntimeProbe.check(!headphones.isDeviceMotionActive, "hp dm stays inactive")
    headphones.stopDeviceMotionUpdates()
    headphones.startConnectionStatusUpdates()
    CoreMotionRuntimeProbe.check(!headphones.isConnectionStatusActive, "hp conn stays inactive")
    headphones.stopConnectionStatusUpdates()
    CoreMotionRuntimeProbe.check(delegate.connected == 0 && delegate.disconnected == 0, "no fake hp")

    let queue = OperationQueue()
    queue.name = "coremotion.runtime.accessory"
    let box = ErrorBox()
    headphones.startDeviceMotionUpdates(to: queue) { data, error in
        CoreMotionRuntimeProbe.check(data == nil, "no hp sample")
        CoreMotionRuntimeProbe.check((error as? CMError) == CMErrorNotAvailable, "hp err")
        box.increment()
    }
    CoreMotionRuntimeProbe.check(!headphones.isDeviceMotionActive, "hp queued stays inactive")

    let activity = CMHeadphoneActivityManager()
    CoreMotionRuntimeProbe.check(!activity.isActivityAvailable, "hp activity avail")
    CoreMotionRuntimeProbe.check(!activity.isStatusAvailable, "hp status avail")
    activity.startActivityUpdates(to: queue) { data, error in
        CoreMotionRuntimeProbe.check(data == nil, "no hp activity")
        CoreMotionRuntimeProbe.check((error as? CMError) == CMErrorNotAvailable, "hp activity err")
        box.increment()
    }
    CoreMotionRuntimeProbe.check(!activity.isActivityActive, "hp activity stays inactive")
    activity.stopActivityUpdates()
    activity.startStatusUpdates(to: queue) { _, error in
        CoreMotionRuntimeProbe.check((error as? CMError) == CMErrorNotAvailable, "hp status err")
        box.increment()
    }
    CoreMotionRuntimeProbe.check(!activity.isStatusActive, "hp status stays inactive")
    activity.stopStatusUpdates()
    queue.waitUntilAllOperationsAreFinished()
    CoreMotionRuntimeProbe.check(box.total == 3, "hp callbacks")

    let water = CMWaterSubmersionManager()
    CoreMotionRuntimeProbe.check(water.maximumDepth == nil, "max depth")
    let waterDelegate = WaterDelegateProbe()
    water.delegate = waterDelegate
    CoreMotionRuntimeProbe.check(water.delegate === waterDelegate, "water delegate stored")
    waterDelegate.lock.lock()
    let waterErrors = waterDelegate.errors
    let waterEvents = waterDelegate.events
    let waterMeasurements = waterDelegate.measurements
    let waterTemperatures = waterDelegate.temperatures
    waterDelegate.lock.unlock()
    CoreMotionRuntimeProbe.check(waterErrors == 0, "assigning delegate does not invent errors")
    CoreMotionRuntimeProbe.check(waterEvents == 0, "assigning delegate does not invent events")
    CoreMotionRuntimeProbe.check(
        waterMeasurements == 0 && waterTemperatures == 0,
        "assigning delegate does not invent measurements"
    )
}

func probeHostData() {
    let accel = CMAccelerometerData(
        hostTimestamp: 1.5,
        acceleration: CMAcceleration(x: 0, y: 0, z: 1)
    )
    CoreMotionRuntimeProbe.check(accel.timestamp == 1.5 && accel.acceleration.z == 1, "accel data")
    let gyro = CMGyroData(hostTimestamp: 2, rotationRate: CMRotationRate(x: 1, y: 0, z: 0))
    CoreMotionRuntimeProbe.check(gyro.rotationRate.x == 1, "gyro data")
    let mag = CMMagnetometerData(
        hostTimestamp: 3,
        magneticField: CMMagneticField(x: 1, y: 2, z: 3)
    )
    CoreMotionRuntimeProbe.check(mag.magneticField.y == 2, "mag data")
    let attitude = CMAttitude(hostQuaternion: CMQuaternion(x: 0, y: 0, z: 0, w: 1))
    let suppliedHeading = 47.25
    let motion = CMDeviceMotion(
        hostTimestamp: 4,
        attitude: attitude,
        rotationRate: CMRotationRate(),
        gravity: CMAcceleration(x: 0, y: 0, z: -1),
        userAcceleration: CMAcceleration(),
        magneticField: CMCalibratedMagneticField(field: CMMagneticField(), accuracy: .uncalibrated),
        heading: suppliedHeading,
        sensorLocation: .default
    )
    CoreMotionRuntimeProbe.check(motion.heading == suppliedHeading, "host heading stored")
    CoreMotionRuntimeProbe.check(motion.gravity.z == -1, "gravity")
    CoreMotionRuntimeProbe.check(motion.userAcceleration.x == 0, "user accel")
    CoreMotionRuntimeProbe.check(motion.sensorLocation == .default, "default location")
    CoreMotionRuntimeProbe.check(motion.magneticField.accuracy == .uncalibrated, "mag accuracy")
    let encodedMotion = try! NSKeyedArchiver.archivedData(
        withRootObject: motion,
        requiringSecureCoding: true
    )
    let decodedMotion = try! NSKeyedUnarchiver.unarchivedObject(
        ofClass: CMDeviceMotion.self,
        from: encodedMotion
    )
    CoreMotionRuntimeProbe.check(decodedMotion?.heading == suppliedHeading, "motion coder")
    CoreMotionRuntimeProbe.check(decodedMotion?.gravity.z == -1, "motion coder gravity")

    let altitude = CMAltitudeData(
        hostTimestamp: 5,
        relativeAltitude: NSNumber(value: 1.25),
        pressure: NSNumber(value: 101.3)
    )
    CoreMotionRuntimeProbe.check(altitude.relativeAltitude.doubleValue == 1.25, "rel alt data")
    CoreMotionRuntimeProbe.check(altitude.pressure.doubleValue == 101.3, "pressure number")
    let absolute = CMAbsoluteAltitudeData(
        hostTimestamp: 6,
        altitude: 12,
        accuracy: 1,
        precision: 0.5
    )
    CoreMotionRuntimeProbe.check(absolute.altitude == 12 && absolute.precision == 0.5, "abs alt")
    CoreMotionRuntimeProbe.check(absolute.accuracy == 1, "abs accuracy")
    let pressure = CMAmbientPressureData(
        hostTimestamp: 7,
        pressure: Measurement(value: 101.325, unit: .kilopascals),
        temperature: Measurement(value: 20, unit: .celsius)
    )
    CoreMotionRuntimeProbe.check(pressure.temperature.value == 20, "ambient temp")
    CoreMotionRuntimeProbe.check(pressure.pressure.value == 101.325, "ambient pressure")

    let encodedPressure = try! NSKeyedArchiver.archivedData(
        withRootObject: pressure,
        requiringSecureCoding: true
    )
    let decodedPressure = try! NSKeyedUnarchiver.unarchivedObject(
        ofClass: CMAmbientPressureData.self,
        from: encodedPressure
    )
    CoreMotionRuntimeProbe.check(
        decodedPressure?.temperature.value == 20,
        "pressure coder temperature"
    )

    let start = Date(timeIntervalSince1970: 0)
    let activity = CMMotionActivity(
        hostTimestamp: 8,
        confidence: .low,
        startDate: start,
        unknown: true,
        stationary: false,
        walking: false,
        running: false,
        automotive: false,
        cycling: false
    )
    CoreMotionRuntimeProbe.check(activity.unknown && !activity.walking, "activity flags")
    CoreMotionRuntimeProbe.check(!activity.stationary && !activity.running, "activity flags 2")
    CoreMotionRuntimeProbe.check(!activity.automotive && !activity.cycling, "activity flags 3")
    CoreMotionRuntimeProbe.check(activity.confidence == .low, "activity confidence")
    CoreMotionRuntimeProbe.check(activity.startDate == start, "activity date")

    let pedo = CMPedometerData(
        hostStartDate: Date(timeIntervalSince1970: 1),
        endDate: Date(timeIntervalSince1970: 2),
        numberOfSteps: NSNumber(value: 0)
    )
    CoreMotionRuntimeProbe.check(pedo.numberOfSteps.intValue == 0, "pedo steps")
    CoreMotionRuntimeProbe.check(pedo.distance == nil, "pedo distance nil")
    CoreMotionRuntimeProbe.check(pedo.floorsAscended == nil, "pedo floors nil")
    CoreMotionRuntimeProbe.check(pedo.currentPace == nil, "pedo pace nil")
    let event = CMPedometerEvent(hostDate: Date(timeIntervalSince1970: 3), type: .pause)
    CoreMotionRuntimeProbe.check(event.type == .pause, "pedo event type")
    CoreMotionRuntimeProbe.check(event.date.timeIntervalSince1970 == 3, "pedo event date")
    let encodedPedo = try! NSKeyedArchiver.archivedData(
        withRootObject: pedo,
        requiringSecureCoding: true
    )
    CoreMotionRuntimeProbe.check(
        (try! NSKeyedUnarchiver.unarchivedObject(ofClass: CMPedometerData.self, from: encodedPedo))?
            .numberOfSteps.intValue == 0,
        "pedo coder"
    )

    let odo = CMOdometerData(
        hostStartDate: Date(timeIntervalSince1970: 4),
        endDate: Date(timeIntervalSince1970: 5),
        deltaDistance: 1,
        deltaDistanceAccuracy: 2,
        speed: 3,
        speedAccuracy: 4,
        gpsDate: Date(timeIntervalSince1970: 4.5),
        deltaAltitude: 0.5,
        verticalAccuracy: 6,
        originDevice: .local,
        slope: 0.1,
        maxAbsSlope: 0.2
    )
    CoreMotionRuntimeProbe.check(odo.slope == 0.1 && odo.maxAbsSlope == 0.2, "odo slope")
    CoreMotionRuntimeProbe.check(odo.originDevice == .local, "odo origin")
    CoreMotionRuntimeProbe.check(odo.deltaDistance == 1 && odo.speed == 3, "odo distance/speed")

    let dys = CMDyskineticSymptomResult(
        hostStartDate: Date(timeIntervalSince1970: 6),
        endDate: Date(timeIntervalSince1970: 7),
        percentUnlikely: 1,
        percentLikely: 0
    )
    CoreMotionRuntimeProbe.check(dys.percentUnlikely == 1 && dys.percentLikely == 0, "dyskinetic")
    let tremor = CMTremorResult(
        hostStartDate: Date(timeIntervalSince1970: 8),
        endDate: Date(timeIntervalSince1970: 9),
        percentUnknown: 1,
        percentNone: 0,
        percentSlight: 0,
        percentMild: 0,
        percentModerate: 0,
        percentStrong: 0
    )
    CoreMotionRuntimeProbe.check(tremor.percentUnknown == 1, "tremor")
    CoreMotionRuntimeProbe.check(tremor.percentNone == 0 && tremor.percentStrong == 0, "tremor rest")

    let waterEvent = CMWaterSubmersionEvent(hostDate: Date(timeIntervalSince1970: 1), state: .notSubmerged)
    CoreMotionRuntimeProbe.check(waterEvent.state == .notSubmerged, "water event")
    let waterMeasure = CMWaterSubmersionMeasurement(
        hostDate: Date(timeIntervalSince1970: 2),
        depth: nil,
        pressure: nil,
        surfacePressure: Measurement(value: 101.325, unit: .kilopascals),
        submersionState: .notSubmerged
    )
    CoreMotionRuntimeProbe.check(waterMeasure.depth == nil, "no fabricated depth")
    CoreMotionRuntimeProbe.check(waterMeasure.surfacePressure.value == 101.325, "surface pressure")
    let waterTemp = CMWaterTemperature(
        hostDate: Date(timeIntervalSince1970: 3),
        temperature: Measurement(value: 18, unit: .celsius),
        temperatureUncertainty: Measurement(value: 0.5, unit: .celsius)
    )
    CoreMotionRuntimeProbe.check(waterTemp.temperature.value == 18, "water temp")
    CoreMotionRuntimeProbe.check(waterTemp.temperatureUncertainty.value == 0.5, "water temp unc")

    let recordedAccel = CMRecordedAccelerometerData(
        hostTimestamp: 10,
        acceleration: CMAcceleration(x: 0, y: 0, z: 1),
        identifier: 7,
        startDate: Date(timeIntervalSince1970: 10)
    )
    CoreMotionRuntimeProbe.check(recordedAccel.identifier == 7, "recorded accel id")
    CoreMotionRuntimeProbe.check(recordedAccel.acceleration.z == 1, "recorded accel")
    let recordedPressure = CMRecordedPressureData(
        hostTimestamp: 11,
        pressure: Measurement(value: 101, unit: .kilopascals),
        temperature: Measurement(value: 21, unit: .celsius),
        identifier: 8,
        startDate: Date(timeIntervalSince1970: 11)
    )
    CoreMotionRuntimeProbe.check(recordedPressure.identifier == 8, "recorded pressure id")
    let rotation = CMRotationRateData(
        hostTimestamp: 12,
        rotationRate: CMRotationRate(x: 1, y: 0, z: 0)
    )
    CoreMotionRuntimeProbe.check(rotation.rotationRate.x == 1, "rotation rate data")
    let recordedRotation = CMRecordedRotationRateData(
        hostTimestamp: 13,
        rotationRate: CMRotationRate(x: 0, y: 1, z: 0),
        startDate: Date(timeIntervalSince1970: 13)
    )
    CoreMotionRuntimeProbe.check(
        recordedRotation.startDate.timeIntervalSince1970 == 13,
        "recorded gyro"
    )
    let heart = CMHighFrequencyHeartRateData(
        hostTimestamp: 14,
        heartRate: 60,
        confidence: .medium,
        date: Date(timeIntervalSince1970: 14)
    )
    CoreMotionRuntimeProbe.check(heart.heartRate == 60 && heart.confidence == .medium, "heart")
    CoreMotionRuntimeProbe.check(heart.date?.timeIntervalSince1970 == 14, "heart date")

    let list = CMSensorDataList()
    CoreMotionRuntimeProbe.check(Array(list).isEmpty, "empty sensor list")

    let log = CMLogItem(hostTimestamp: 9)
    CoreMotionRuntimeProbe.check(log.timestamp == 9, "log item")
    let encodedLog = try! NSKeyedArchiver.archivedData(
        withRootObject: log,
        requiringSecureCoding: true
    )
    CoreMotionRuntimeProbe.check(
        (try! NSKeyedUnarchiver.unarchivedObject(ofClass: CMLogItem.self, from: encodedLog))?
            .timestamp == 9,
        "log coder"
    )
}

probeValueTypes()
probeAttitudeMath()
probeMotionManager()
probeEnvironmentManagers()
probeAccessoryManagers()
probeHostData()
print("COREMOTION_AGENT_RUNTIME_OK")
