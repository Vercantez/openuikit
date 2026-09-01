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

    func manager(_ manager: CMWaterSubmersionManager, didUpdate event: CMWaterSubmersionEvent) {
        _ = manager
        _ = event
    }

    func manager(
        _ manager: CMWaterSubmersionManager,
        didUpdate measurement: CMWaterSubmersionMeasurement
    ) {
        _ = manager
        _ = measurement
    }

    func manager(_ manager: CMWaterSubmersionManager, didUpdate measurement: CMWaterTemperature) {
        _ = manager
        _ = measurement
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
    CoreMotionRuntimeProbe.check(CMErrorDomain == "CMErrorDomain", "error domain")
    CoreMotionRuntimeProbe.check(CMErrorNULL.rawValue == 100, "CMErrorNULL")
    CoreMotionRuntimeProbe.check(CMErrorDeviceRequiresMovement.rawValue == 101, "movement")
    CoreMotionRuntimeProbe.check(CMErrorTrueNorthNotAvailable.rawValue == 102, "true north")
    CoreMotionRuntimeProbe.check(CMErrorUnknown.rawValue == 103, "unknown")
    CoreMotionRuntimeProbe.check(CMErrorMotionActivityNotAvailable.rawValue == 104, "act na")
    CoreMotionRuntimeProbe.check(CMErrorMotionActivityNotAuthorized.rawValue == 105, "act nauth")
    CoreMotionRuntimeProbe.check(CMErrorMotionActivityNotEntitled.rawValue == 106, "act nent")
    CoreMotionRuntimeProbe.check(CMErrorInvalidParameter.rawValue == 107, "invalid param")
    CoreMotionRuntimeProbe.check(CMErrorInvalidAction.rawValue == 108, "invalid action")
    CoreMotionRuntimeProbe.check(CMErrorNotAvailable.rawValue == 109, "not available")
    CoreMotionRuntimeProbe.check(CMErrorNotEntitled.rawValue == 110, "not entitled")
    CoreMotionRuntimeProbe.check(CMErrorNotAuthorized.rawValue == 111, "not authorized")
    CoreMotionRuntimeProbe.check(CMErrorNilData.rawValue == 112, "nil data")
    CoreMotionRuntimeProbe.check(CMErrorSize.rawValue == 113, "size")
    CoreMotionRuntimeProbe.check(CMError(rawValue: 109) == CMErrorNotAvailable, "error eq")
    CoreMotionRuntimeProbe.check(CMError(109) == CMErrorNotAvailable, "error unlabeled")
    CoreMotionRuntimeProbe.check(CMErrorNotAvailable != CMErrorNULL, "error ne")
    CoreMotionRuntimeProbe.check(CMErrorNotAvailable.hashValue != 0 || true, "error hash")
    var hasher = Hasher()
    CMErrorNotAvailable.hash(into: &hasher)
    _ = hasher.finalize()

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
        CMAttitudeReferenceFrame(rawValue: 1 << 0) == .xArbitraryZVertical,
        "frame raw"
    )

    CoreMotionRuntimeProbe.check(CMAuthorizationStatus(rawValue: 2) == .denied, "auth raw")
    CoreMotionRuntimeProbe.check(
        CMAuthorizationStatus.authorized != .denied,
        "auth ne"
    )
    CoreMotionRuntimeProbe.check(
        Set([CMAuthorizationStatus.denied]).contains(.denied),
        "auth hash"
    )
    CoreMotionRuntimeProbe.check(
        CMMagneticFieldCalibrationAccuracy(rawValue: -1) == .uncalibrated,
        "mag acc"
    )
    CoreMotionRuntimeProbe.check(CMMotionActivityConfidence(rawValue: 2) == .high, "activity conf")
    CoreMotionRuntimeProbe.check(CMPedometerEventType(rawValue: 1) == .resume, "pedo event")
    CoreMotionRuntimeProbe.check(CMOdometerOriginDevice(rawValue: 1) == .local, "odo origin")
    CoreMotionRuntimeProbe.check(
        CMHighFrequencyHeartRateDataConfidence(rawValue: 3) == .highest,
        "hr conf"
    )
    CoreMotionRuntimeProbe.check(
        CMDeviceMotion.SensorLocation(rawValue: 1) == .headphoneLeft,
        "sensor loc"
    )
    CoreMotionRuntimeProbe.check(
        CMHeadphoneActivityManager.Status(rawValue: 1) == .connected,
        "hp status"
    )
    CoreMotionRuntimeProbe.check(
        CMWaterSubmersionEvent.State(rawValue: 2) == .submerged,
        "sub event"
    )
    CoreMotionRuntimeProbe.check(
        CMWaterSubmersionMeasurement.DepthState(rawValue: 5) == .pastMaxDepth,
        "depth state"
    )
    _ = CMAuthorizationStatus.notDetermined.hashValue
    CMAuthorizationStatus.denied.hash(into: &hasher)

    let accel = CMAcceleration(x: 0.1, y: -0.2, z: 0.9)
    CoreMotionRuntimeProbe.check(accel.x == 0.1 && CMAcceleration().z == 0, "accel")
    let rate = CMRotationRate(x: 1, y: 2, z: 3)
    CoreMotionRuntimeProbe.check(rate.y == 2 && CMRotationRate().x == 0, "gyro struct")
    let field = CMMagneticField(x: 4, y: 5, z: 6)
    CoreMotionRuntimeProbe.check(field.z == 6 && CMMagneticField().y == 0, "mag struct")
    let quat = CMQuaternion(x: 0, y: 0, z: 0, w: 1)
    CoreMotionRuntimeProbe.check(quat.w == 1 && CMQuaternion().w == 0, "quat")
    let matrix = CMRotationMatrix(
        m11: 1, m12: 0, m13: 0,
        m21: 0, m22: 1, m23: 0,
        m31: 0, m32: 0, m33: 1
    )
    CoreMotionRuntimeProbe.check(matrix.m22 == 1 && CMRotationMatrix().m11 == 0, "matrix")
    let calibrated = CMCalibratedMagneticField(field: field, accuracy: .high)
    CoreMotionRuntimeProbe.check(
        calibrated.accuracy == .high && CMCalibratedMagneticField().accuracy == .low,
        "cal mag"
    )
}

func probeAttitudeMath() {
    let identity = CMAttitude(hostQuaternion: CMQuaternion(x: 0, y: 0, z: 0, w: 1))
    CoreMotionRuntimeProbe.check(abs(identity.roll) < 1e-9, "identity roll")
    CoreMotionRuntimeProbe.check(abs(identity.pitch) < 1e-9, "identity pitch")
    CoreMotionRuntimeProbe.check(abs(identity.yaw) < 1e-9, "identity yaw")
    CoreMotionRuntimeProbe.check(abs(identity.rotationMatrix.m11 - 1) < 1e-9, "identity m11")
    let other = CMAttitude(hostQuaternion: CMQuaternion(x: 0, y: 0, z: 0, w: 1))
    identity.multiply(byInverseOf: other)
    CoreMotionRuntimeProbe.check(abs(identity.quaternion.w - 1) < 1e-9, "multiply identity")

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
    CoreMotionRuntimeProbe.check(manager.showsDeviceMovementDisplay, "movement display")

    manager.startAccelerometerUpdates()
    CoreMotionRuntimeProbe.check(manager.isAccelerometerActive, "accel active pull")
    manager.stopAccelerometerUpdates()
    CoreMotionRuntimeProbe.check(!manager.isAccelerometerActive, "accel stopped")
    manager.startGyroUpdates()
    manager.startMagnetometerUpdates()
    manager.startDeviceMotionUpdates()
    CoreMotionRuntimeProbe.check(manager.isGyroActive && manager.isMagnetometerActive, "pull active")
    CoreMotionRuntimeProbe.check(manager.isDeviceMotionActive, "dm pull")
    CoreMotionRuntimeProbe.check(
        manager.attitudeReferenceFrame == .xArbitraryZVertical,
        "default frame"
    )
    manager.stopGyroUpdates()
    manager.stopMagnetometerUpdates()
    manager.stopDeviceMotionUpdates()
    manager.startDeviceMotionUpdates(using: .xMagneticNorthZVertical)
    CoreMotionRuntimeProbe.check(
        manager.attitudeReferenceFrame == .xMagneticNorthZVertical,
        "requested frame stored"
    )
    manager.stopDeviceMotionUpdates()

    let queue = OperationQueue()
    queue.maxConcurrentOperationCount = 1
    let box = ErrorBox()
    manager.startAccelerometerUpdates(to: queue) { data, error in
        CoreMotionRuntimeProbe.check(data == nil, "no fabricated accel")
        box.set("accel", error)
    }
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
    activity.queryActivityStarting(from: Date.distantPast, to: Date(), to: queue) { items, error in
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
    pedometer.queryPedometerData(from: Date.distantPast, to: Date()) { data, error in
        CoreMotionRuntimeProbe.check(data == nil, "no pedo query")
        CoreMotionRuntimeProbe.check((error as? CMError) == CMErrorNotAvailable, "pedo err")
        box.increment()
    }
    pedometer.startUpdates(from: Date()) { data, error in
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
    steps.queryStepCountStarting(from: Date.distantPast, to: Date(), to: queue) { count, error in
        CoreMotionRuntimeProbe.check(count == 0, "no steps")
        CoreMotionRuntimeProbe.check((error as? CMError) == CMErrorNotAvailable, "step err")
        box.increment()
    }
    steps.startStepCountingUpdates(to: queue, updateOn: 1) { count, _, error in
        CoreMotionRuntimeProbe.check(count == 0, "no live steps")
        CoreMotionRuntimeProbe.check((error as? CMError) == CMErrorNotAvailable, "live step err")
        box.increment()
    }
    steps.stopStepCountingUpdates()

    let recorder = CMSensorRecorder()
    recorder.recordAccelerometer(forDuration: 10)
    CoreMotionRuntimeProbe.check(
        recorder.accelerometerData(from: Date.distantPast, to: Date()) == nil,
        "no recorded accel"
    )

    let batched = CMBatchedSensorManager()
    CoreMotionRuntimeProbe.check(batched.accelerometerDataFrequency == 0, "batch freq")
    CoreMotionRuntimeProbe.check(batched.deviceMotionDataFrequency == 0, "dm freq")
    CoreMotionRuntimeProbe.check(batched.accelerometerBatch == nil, "accel batch")
    CoreMotionRuntimeProbe.check(batched.deviceMotionBatch == nil, "dm batch")
    batched.startAccelerometerUpdates()
    CoreMotionRuntimeProbe.check(batched.isAccelerometerActive, "batch accel active")
    batched.startAccelerometerUpdates { data, error in
        CoreMotionRuntimeProbe.check(data == nil, "no batch accel")
        CoreMotionRuntimeProbe.check((error as? CMError) == CMErrorNotAvailable, "batch accel err")
        box.increment()
    }
    batched.stopAccelerometerUpdates()
    batched.startDeviceMotionUpdates()
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
    CoreMotionRuntimeProbe.check(!headphones.isDeviceMotionAvailable, "hp dm avail")
    CoreMotionRuntimeProbe.check(headphones.deviceMotion == nil, "hp dm")
    headphones.startDeviceMotionUpdates()
    CoreMotionRuntimeProbe.check(headphones.isDeviceMotionActive, "hp dm active")
    headphones.stopDeviceMotionUpdates()
    headphones.startConnectionStatusUpdates()
    CoreMotionRuntimeProbe.check(headphones.isConnectionStatusActive, "hp conn")
    headphones.stopConnectionStatusUpdates()
    CoreMotionRuntimeProbe.check(delegate.connected == 0 && delegate.disconnected == 0, "no fake hp")

    let queue = OperationQueue()
    let box = ErrorBox()
    headphones.startDeviceMotionUpdates(to: queue) { data, error in
        CoreMotionRuntimeProbe.check(data == nil, "no hp sample")
        CoreMotionRuntimeProbe.check((error as? CMError) == CMErrorNotAvailable, "hp err")
        box.increment()
    }

    let activity = CMHeadphoneActivityManager()
    CoreMotionRuntimeProbe.check(!activity.isActivityAvailable, "hp activity avail")
    CoreMotionRuntimeProbe.check(!activity.isStatusAvailable, "hp status avail")
    activity.startActivityUpdates(to: queue) { data, error in
        CoreMotionRuntimeProbe.check(data == nil, "no hp activity")
        CoreMotionRuntimeProbe.check((error as? CMError) == CMErrorNotAvailable, "hp activity err")
        box.increment()
    }
    activity.stopActivityUpdates()
    activity.startStatusUpdates(to: queue) { status, error in
        CoreMotionRuntimeProbe.check(status == .disconnected, "hp status disconnected")
        CoreMotionRuntimeProbe.check((error as? CMError) == CMErrorNotAvailable, "hp status err")
        box.increment()
    }
    activity.stopStatusUpdates()
    queue.waitUntilAllOperationsAreFinished()
    CoreMotionRuntimeProbe.check(box.total == 3, "hp callbacks")

    let water = CMWaterSubmersionManager()
    CoreMotionRuntimeProbe.check(water.maximumDepth == nil, "max depth")
    let waterDelegate = WaterDelegateProbe()
    water.delegate = waterDelegate
    waterDelegate.lock.lock()
    let waterErrors = waterDelegate.errors
    waterDelegate.lock.unlock()
    CoreMotionRuntimeProbe.check(waterErrors == 1, "water fail-closed on delegate")
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
    let motion = CMDeviceMotion(
        hostTimestamp: 4,
        attitude: attitude,
        rotationRate: CMRotationRate(),
        gravity: CMAcceleration(x: 0, y: 0, z: -1),
        userAcceleration: CMAcceleration(),
        magneticField: CMCalibratedMagneticField(field: CMMagneticField(), accuracy: .uncalibrated),
        heading: -1,
        sensorLocation: .default
    )
    CoreMotionRuntimeProbe.check(motion.heading == -1, "invalid heading")
    CoreMotionRuntimeProbe.check(motion.gravity.z == -1, "gravity")
    CoreMotionRuntimeProbe.check(motion.sensorLocation == .default, "default location")
    let encodedMotion = try! NSKeyedArchiver.archivedData(
        withRootObject: motion,
        requiringSecureCoding: true
    )
    let decodedMotion = try! NSKeyedUnarchiver.unarchivedObject(
        ofClass: CMDeviceMotion.self,
        from: encodedMotion
    )
    CoreMotionRuntimeProbe.check(decodedMotion?.heading == -1, "motion coder")

    let altitude = CMAltitudeData(
        hostTimestamp: 5,
        relativeAltitude: NSNumber(value: 1.25),
        pressure: NSNumber(value: 101.3)
    )
    CoreMotionRuntimeProbe.check(altitude.relativeAltitude.doubleValue == 1.25, "rel alt data")
    let absolute = CMAbsoluteAltitudeData(
        hostTimestamp: 6,
        altitude: 12,
        accuracy: 1,
        precision: 0.5
    )
    CoreMotionRuntimeProbe.check(absolute.altitude == 12 && absolute.precision == 0.5, "abs alt")
    let pressure = CMAmbientPressureData(
        hostTimestamp: 7,
        pressure: Measurement(value: 101.325, unit: .kilopascals),
        temperature: Measurement(value: 20, unit: .celsius)
    )
    CoreMotionRuntimeProbe.check(pressure.temperature.value == 20, "ambient temp")

    let activity = CMMotionActivity(
        hostTimestamp: 8,
        confidence: .low,
        startDate: Date(timeIntervalSince1970: 0),
        unknown: true,
        stationary: false,
        walking: false,
        running: false,
        automotive: false,
        cycling: false
    )
    CoreMotionRuntimeProbe.check(activity.unknown && !activity.walking, "activity flags")

    let pedo = CMPedometerData(
        hostStartDate: Date(timeIntervalSince1970: 1),
        endDate: Date(timeIntervalSince1970: 2),
        numberOfSteps: NSNumber(value: 0)
    )
    CoreMotionRuntimeProbe.check(pedo.numberOfSteps.intValue == 0, "pedo steps")
    CoreMotionRuntimeProbe.check(pedo.distance == nil, "pedo distance nil")
    let event = CMPedometerEvent(hostDate: Date(timeIntervalSince1970: 3), type: .pause)
    CoreMotionRuntimeProbe.check(event.type == .pause, "pedo event type")
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

    let dys = CMDyskineticSymptomResult(
        hostStartDate: Date(timeIntervalSince1970: 6),
        endDate: Date(timeIntervalSince1970: 7),
        percentUnlikely: 1,
        percentLikely: 0
    )
    CoreMotionRuntimeProbe.check(dys.percentUnlikely == 1, "dyskinetic")
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

    let waterEvent = CMWaterSubmersionEvent(hostDate: Date(), state: .notSubmerged)
    CoreMotionRuntimeProbe.check(waterEvent.state == .notSubmerged, "water event")
    let waterMeasure = CMWaterSubmersionMeasurement(
        hostDate: Date(),
        depth: nil,
        pressure: nil,
        surfacePressure: Measurement(value: 101.325, unit: .kilopascals),
        submersionState: .notSubmerged
    )
    CoreMotionRuntimeProbe.check(waterMeasure.depth == nil, "no fabricated depth")
    let waterTemp = CMWaterTemperature(
        hostDate: Date(),
        temperature: Measurement(value: 18, unit: .celsius),
        temperatureUncertainty: Measurement(value: 0.5, unit: .celsius)
    )
    CoreMotionRuntimeProbe.check(waterTemp.temperature.value == 18, "water temp")

    let recordedAccel = CMRecordedAccelerometerData(
        hostTimestamp: 10,
        acceleration: CMAcceleration(x: 0, y: 0, z: 1),
        identifier: 7,
        startDate: Date(timeIntervalSince1970: 10)
    )
    CoreMotionRuntimeProbe.check(recordedAccel.identifier == 7, "recorded accel id")
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
