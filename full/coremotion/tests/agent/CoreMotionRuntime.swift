@_spi(OpenUIKitHost) import CoreMotion
import Foundation
import Glibc

private let eventTimeout = DispatchTimeInterval.seconds(5)

private final class LockedState: @unchecked Sendable {
    private let lock = NSLock()
    private var returned = false
    private var sawReturned = false
    private var count = 0
    private var error: (any Error)?
    private var hasNilSample = false

    func markReturned() {
        lock.lock()
        returned = true
        lock.unlock()
    }

    func noteCallback(sampleIsNil: Bool, error: (any Error)?) {
        lock.lock()
        sawReturned = returned
        count += 1
        hasNilSample = sampleIsNil
        self.error = error
        lock.unlock()
    }

    func snapshot() -> (sawReturned: Bool, count: Int, sampleIsNil: Bool, error: (any Error)?) {
        lock.lock()
        defer { lock.unlock() }
        return (sawReturned, count, hasNilSample, error)
    }
}

private func waitEvent(_ semaphore: DispatchSemaphore, _ message: String) {
    precondition(semaphore.wait(timeout: .now() + eventTimeout) == .success, message)
}

private final class CompletionQueueBlocker: @unchecked Sendable {
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
        waitEvent(occupied, "completion queue blocker did not start")
    }

    func release() {
        hold.signal()
    }
}

private func requireUnavailableError(_ error: (any Error)?) {
    guard let error else {
        fatalError("expected fail-closed NSError")
    }
    let nsError = error as NSError
    precondition(type(of: nsError) == NSError.self)
    precondition(!String(reflecting: type(of: nsError)).hasPrefix("CoreMotion."))
    precondition(nsError.domain == CMErrorDomain)
    precondition(nsError.domain == "CMErrorDomain")
    precondition(nsError.code == Int(CMErrorNotAvailable.rawValue))
}

private func proveQueuedHandler(
    start: (OperationQueue, LockedState) -> Void
) {
    let queue = OperationQueue()
    queue.name = "CoreMotion.runtime.probe"
    queue.maxConcurrentOperationCount = 1
    let blocker = CompletionQueueBlocker(queue: queue)
    let state = LockedState()
    blocker.occupy()
    start(queue, state)
    state.markReturned()
    let before = state.snapshot()
    precondition(before.count == 0, "handler must not run inline")
    blocker.release()
    let drained = DispatchSemaphore(value: 0)
    CoreMotionHostControl.enqueueCompletionProbe(on: queue) {
        drained.signal()
    }
    waitEvent(drained, "handler queue did not drain")
    let after = state.snapshot()
    precondition(after.count == 1)
    precondition(after.sawReturned)
    precondition(after.sampleIsNil)
    requireUnavailableError(after.error)
}

private func archiveRoundTrip<T: NSObject & NSSecureCoding>(_ value: T) -> T {
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

private func assertValueTypes() {
    let accel = CMAcceleration(x: 1, y: -2, z: 3)
    precondition(accel.x == 1 && accel.y == -2 && accel.z == 3)
    precondition(CMAcceleration() == CMAcceleration(x: 0, y: 0, z: 0))

    let gyro = CMRotationRate(x: 0.1, y: 0.2, z: 0.3)
    precondition(gyro.x == 0.1 && gyro.y == 0.2 && gyro.z == 0.3)
    precondition(CMRotationRate() == CMRotationRate(x: 0, y: 0, z: 0))

    let field = CMMagneticField(x: 4, y: 5, z: 6)
    precondition(field.x == 4 && field.y == 5 && field.z == 6)
    precondition(CMMagneticField() == CMMagneticField(x: 0, y: 0, z: 0))

    let calibrated = CMCalibratedMagneticField(field: field, accuracy: .medium)
    precondition(calibrated.field == field)
    precondition(calibrated.accuracy == .medium)
    precondition(CMCalibratedMagneticField().accuracy == .uncalibrated)

    let identity = CMQuaternion()
    precondition(identity.x == 0 && identity.y == 0 && identity.z == 0 && identity.w == 1)
    let custom = CMQuaternion(x: 0, y: 0, z: 0, w: 1)
    precondition(custom == identity)

    let matrix = CMRotationMatrix()
    precondition(matrix.m11 == 1 && matrix.m22 == 1 && matrix.m33 == 1)
    precondition(matrix.m12 == 0 && matrix.m13 == 0 && matrix.m21 == 0)
    let named = CMRotationMatrix(
        m11: 1, m12: 0, m13: 0,
        m21: 0, m22: 1, m23: 0,
        m31: 0, m32: 0, m33: 1
    )
    precondition(named == matrix)
}

private func assertAttitudeMath() {
    let identity = CoreMotionHostControl.makeAttitude(quaternion: CMQuaternion())
    precondition(identity.roll == 0)
    precondition(identity.pitch == 0)
    precondition(identity.yaw == 0)
    let im = identity.rotationMatrix
    precondition(im.m11 == 1 && im.m22 == 1 && im.m33 == 1)

    let angle = Double.pi / 5
    let half = angle / 2
    let qz = CMQuaternion(x: 0, y: 0, z: sin(half), w: cos(half))
    let yawed = CoreMotionHostControl.makeAttitude(quaternion: qz)
    precondition(abs(yawed.yaw - angle) < 1e-9)
    precondition(abs(yawed.roll) < 1e-9)
    precondition(abs(yawed.pitch) < 1e-9)

    let inverse = CoreMotionHostControl.makeAttitude(quaternion: qz)
    yawed.multiply(byInverseOf: inverse)
    precondition(abs(yawed.quaternion.x) < 1e-9)
    precondition(abs(yawed.quaternion.y) < 1e-9)
    precondition(abs(yawed.quaternion.z) < 1e-9)
    precondition(abs(yawed.quaternion.w - 1) < 1e-9)

    let decoded = archiveRoundTrip(identity)
    precondition(decoded.quaternion.w == 1)
}

private func abs(_ value: Double) -> Double {
    value < 0 ? -value : value
}

private func assertEnums() {
    let statuses: [CMAuthorizationStatus] = [
        .notDetermined, .restricted, .denied, .authorized
    ]
    precondition(Set(statuses.map(\.rawValue)).count == 4)
    precondition(CMAuthorizationStatus(rawValue: 2) == .denied)
    precondition(CMAuthorizationStatus.denied != .authorized)
    var hasher = Hasher()
    CMAuthorizationStatus.denied.hash(into: &hasher)
    let deniedHash = CMAuthorizationStatus.denied.hashValue
    let authorizedHash = CMAuthorizationStatus.authorized.hashValue
    precondition(deniedHash != authorizedHash)

    precondition(CMMagneticFieldCalibrationAccuracy(rawValue: -1) == .uncalibrated)
    precondition(CMMagneticFieldCalibrationAccuracy.low != .high)

    precondition(CMMotionActivityConfidence.low != .high)
    precondition(CMPedometerEventType.pause != .resume)
    precondition(CMOdometerOriginDevice.local != .remote)
    precondition(CMHighFrequencyHeartRateDataConfidence.low != .highest)
    precondition(CMDeviceMotion.SensorLocation.default != .headphoneLeft)
    precondition(CMHeadphoneActivityManager.Status.connected != .disconnected)
    precondition(CMWaterSubmersionEvent.State.submerged != .notSubmerged)
    precondition(
        CMWaterSubmersionMeasurement.DepthState.submergedShallow
            != .pastMaxDepth
    )
    _ = CMWaterSubmersionMeasurement.DepthState.unknown.hashValue
    _ = CMWaterSubmersionEvent.State.unknown.hashValue
    _ = CMDeviceMotion.SensorLocation.headphoneRight.hashValue
    _ = CMHeadphoneActivityManager.Status.disconnected.hashValue
    _ = CMHighFrequencyHeartRateDataConfidence.medium.hashValue
    _ = CMMagneticFieldCalibrationAccuracy.medium.hashValue
    _ = CMMotionActivityConfidence.medium.hashValue
    _ = CMOdometerOriginDevice.unknown.hashValue
    _ = CMPedometerEventType.resume.hashValue
}

private func assertOptionSet() {
    var frames: CMAttitudeReferenceFrame = []
    precondition(frames.isEmpty)
    frames.insert(.xArbitraryZVertical)
    precondition(frames.contains(.xArbitraryZVertical))
    precondition(!frames.contains(.xTrueNorthZVertical))
    frames.formUnion(.xMagneticNorthZVertical)
    precondition(frames.isSuperset(of: .xArbitraryZVertical))
    precondition(frames.isSubset(of: [
        .xArbitraryZVertical, .xMagneticNorthZVertical, .xTrueNorthZVertical
    ]))
    let intersection = frames.intersection(.xMagneticNorthZVertical)
    precondition(intersection == .xMagneticNorthZVertical)
    frames.subtract(.xArbitraryZVertical)
    precondition(frames == .xMagneticNorthZVertical)
    let corrected: CMAttitudeReferenceFrame = [
        .xArbitraryCorrectedZVertical, .xTrueNorthZVertical
    ]
    precondition(corrected.contains(.xTrueNorthZVertical))
    precondition(!corrected.isDisjoint(with: .xTrueNorthZVertical))
    precondition(corrected.isStrictSuperset(of: .xTrueNorthZVertical))
    precondition(CMAttitudeReferenceFrame.xArbitraryZVertical.isStrictSubset(of: corrected.union(.xArbitraryZVertical)))
    _ = corrected.symmetricDifference(.xTrueNorthZVertical)
    frames.formIntersection(.xMagneticNorthZVertical)
    frames.formSymmetricDifference(.xTrueNorthZVertical)
    var copy = CMAttitudeReferenceFrame(arrayLiteral: .xArbitraryZVertical)
    _ = copy.update(with: .xArbitraryZVertical)
    _ = copy.remove(.xArbitraryZVertical)
    let sequenced = CMAttitudeReferenceFrame([.xArbitraryZVertical, .xTrueNorthZVertical])
    precondition(sequenced.contains(.xTrueNorthZVertical))
    precondition(CMMotionManager.availableAttitudeReferenceFrames().isEmpty)
}

private func assertErrorSurface() {
    let a = CMError(rawValue: 7)
    let b = CMError(7)
    precondition(a == b)
    precondition(a.rawValue == 7)
    precondition(a != CMError(8))
    precondition(CMError(1).hashValue != CMError(2).hashValue)
    var hasher = Hasher()
    a.hash(into: &hasher)
    _ = CMErrorNULL
    _ = CMErrorDeviceRequiresMovement
    _ = CMErrorTrueNorthNotAvailable
    _ = CMErrorUnknown
    _ = CMErrorMotionActivityNotAvailable
    _ = CMErrorMotionActivityNotAuthorized
    _ = CMErrorMotionActivityNotEntitled
    _ = CMErrorInvalidParameter
    _ = CMErrorInvalidAction
    _ = CMErrorNilData
    _ = CMErrorNotAvailable
    _ = CMErrorNotAuthorized
    _ = CMErrorNotEntitled
    _ = CMErrorSize
    precondition(CMErrorDomain == "CMErrorDomain")
}

private func assertSamplesAndCoding() {
    let item = CoreMotionHostControl.makeLogItem(timestamp: 12.5)
    precondition(item.timestamp == 12.5)
    let itemDecoded = archiveRoundTrip(item)
    precondition(itemDecoded.timestamp == 12.5)

    let accel = CoreMotionHostControl.makeAccelerometerData(
        timestamp: 1,
        acceleration: CMAcceleration(x: 1, y: 0, z: -1)
    )
    precondition(accel.acceleration.x == 1)
    precondition(archiveRoundTrip(accel).acceleration.z == -1)

    let gyro = CoreMotionHostControl.makeGyroData(
        timestamp: 2,
        rotationRate: CMRotationRate(x: 0, y: 1, z: 0)
    )
    precondition(gyro.rotationRate.y == 1)

    let mag = CoreMotionHostControl.makeMagnetometerData(
        timestamp: 3,
        magneticField: CMMagneticField(x: 9, y: 8, z: 7)
    )
    precondition(mag.magneticField.x == 9)

    let attitude = CoreMotionHostControl.makeAttitude(quaternion: CMQuaternion())
    let motion = CoreMotionHostControl.makeDeviceMotion(
        timestamp: 4,
        attitude: attitude,
        rotationRate: CMRotationRate(),
        gravity: CMAcceleration(x: 0, y: 0, z: -1),
        userAcceleration: CMAcceleration(),
        magneticField: CMCalibratedMagneticField(),
        heading: -1,
        sensorLocation: .default
    )
    precondition(motion.gravity.z == -1)
    precondition(motion.heading == -1)
    precondition(motion.sensorLocation == .default)
    precondition(motion.attitude.quaternion.w == 1)
    let motionDecoded = archiveRoundTrip(motion)
    precondition(motionDecoded.userAcceleration == CMAcceleration())

    let altitude = CoreMotionHostControl.makeAltitudeData(
        timestamp: 5,
        relativeAltitude: 2.5,
        pressure: 101.3
    )
    precondition(altitude.relativeAltitude.doubleValue == 2.5)
    precondition(altitude.pressure.doubleValue == 101.3)

    let absolute = CoreMotionHostControl.makeAbsoluteAltitudeData(
        timestamp: 6,
        altitude: 12,
        accuracy: 0.5,
        precision: 0.1
    )
    precondition(absolute.altitude == 12)
    precondition(absolute.accuracy == 0.5)
    precondition(absolute.precision == 0.1)

    let ambient = CoreMotionHostControl.makeAmbientPressureData(
        timestamp: 7,
        pressure: Measurement(value: 101.325, unit: .kilopascals),
        temperature: Measurement(value: 20, unit: .celsius)
    )
    precondition(ambient.pressure.value == 101.325)
    precondition(ambient.temperature.value == 20)

    let recordedAccel = CoreMotionHostControl.makeRecordedAccelerometerData(
        timestamp: 8,
        acceleration: CMAcceleration(x: 0.2, y: 0, z: 0),
        identifier: 99,
        startDate: Date(timeIntervalSince1970: 10)
    )
    precondition(recordedAccel.identifier == 99)
    precondition(recordedAccel.startDate.timeIntervalSince1970 == 10)

    let recordedGyro = CoreMotionHostControl.makeRecordedRotationRateData(
        timestamp: 9,
        rotationRate: CMRotationRate(x: 1, y: 0, z: 0),
        startDate: Date(timeIntervalSince1970: 11)
    )
    precondition(recordedGyro.startDate.timeIntervalSince1970 == 11)
    precondition(recordedGyro.rotationRate.x == 1)

    let recordedPressure = CoreMotionHostControl.makeRecordedPressureData(
        timestamp: 10,
        pressure: Measurement(value: 100, unit: .kilopascals),
        temperature: Measurement(value: 15, unit: .celsius),
        identifier: 3,
        startDate: Date(timeIntervalSince1970: 12)
    )
    precondition(recordedPressure.identifier == 3)

    let activity = CoreMotionHostControl.makeMotionActivity(
        startDate: Date(timeIntervalSince1970: 1),
        confidence: .high,
        unknown: false,
        stationary: true,
        walking: false,
        running: false,
        automotive: false,
        cycling: false
    )
    precondition(activity.stationary)
    precondition(activity.confidence == .high)
    precondition(!activity.walking && !activity.running)
    precondition(!activity.automotive && !activity.cycling)
    precondition(!activity.unknown)

    let pedometer = CoreMotionHostControl.makePedometerData(
        startDate: Date(timeIntervalSince1970: 0),
        endDate: Date(timeIntervalSince1970: 60),
        numberOfSteps: 12,
        distance: 8.5,
        floorsAscended: 1,
        floorsDescended: 0,
        currentPace: 1.2,
        currentCadence: 1.8,
        averageActivePace: 1.1
    )
    precondition(pedometer.numberOfSteps.intValue == 12)
    precondition(pedometer.distance?.doubleValue == 8.5)
    precondition(pedometer.floorsAscended?.intValue == 1)
    precondition(pedometer.floorsDescended?.intValue == 0)
    precondition(pedometer.currentPace?.doubleValue == 1.2)
    precondition(pedometer.currentCadence?.doubleValue == 1.8)
    precondition(pedometer.averageActivePace?.doubleValue == 1.1)
    let pedDecoded = archiveRoundTrip(pedometer)
    precondition(pedDecoded.numberOfSteps.intValue == 12)

    let event = CoreMotionHostControl.makePedometerEvent(
        date: Date(timeIntervalSince1970: 3),
        type: .resume
    )
    precondition(event.type == .resume)
    precondition(archiveRoundTrip(event).type == .resume)

    let odometer = CoreMotionHostControl.makeOdometerData(
        startDate: Date(timeIntervalSince1970: 0),
        endDate: Date(timeIntervalSince1970: 5),
        deltaDistance: 10,
        deltaDistanceAccuracy: 1,
        speed: 2,
        speedAccuracy: 0.2,
        deltaAltitude: 0.5,
        verticalAccuracy: 0.3,
        originDevice: .local,
        gpsDate: Date(timeIntervalSince1970: 4),
        slope: 0.01,
        maxAbsSlope: 0.02
    )
    precondition(odometer.deltaDistance == 10)
    precondition(odometer.originDevice == .local)
    precondition(odometer.slope == 0.01)
    precondition(odometer.maxAbsSlope == 0.02)
    let odoDecoded = archiveRoundTrip(odometer)
    precondition(odoDecoded.speed == 2)

    let dys = CoreMotionHostControl.makeDyskineticSymptomResult(
        startDate: Date(timeIntervalSince1970: 0),
        endDate: Date(timeIntervalSince1970: 1),
        percentLikely: 0.2,
        percentUnlikely: 0.8
    )
    precondition(dys.percentLikely == 0.2)
    precondition(archiveRoundTrip(dys).percentUnlikely == 0.8)

    let tremor = CoreMotionHostControl.makeTremorResult(
        startDate: Date(timeIntervalSince1970: 0),
        endDate: Date(timeIntervalSince1970: 1),
        percentUnknown: 0.1,
        percentNone: 0.2,
        percentSlight: 0.3,
        percentMild: 0.15,
        percentModerate: 0.15,
        percentStrong: 0.1
    )
    precondition(tremor.percentMild == 0.15)
    precondition(archiveRoundTrip(tremor).percentStrong == 0.1)

    let heart = CoreMotionHostControl.makeHeartRateData(
        timestamp: 1,
        heartRate: 72,
        confidence: .high,
        date: Date(timeIntervalSince1970: 20)
    )
    precondition(heart.heartRate == 72)
    precondition(heart.confidence == .high)
    precondition(heart.date?.timeIntervalSince1970 == 20)

    let waterEvent = CoreMotionHostControl.makeWaterSubmersionEvent(
        date: Date(timeIntervalSince1970: 1),
        state: .notSubmerged
    )
    precondition(waterEvent.state == .notSubmerged)
    precondition(archiveRoundTrip(waterEvent).state == .notSubmerged)

    let waterMeasure = CoreMotionHostControl.makeWaterSubmersionMeasurement(
        date: Date(timeIntervalSince1970: 2),
        depth: Measurement(value: 1.5, unit: .meters),
        pressure: Measurement(value: 120, unit: .kilopascals),
        surfacePressure: Measurement(value: 101.325, unit: .kilopascals),
        submersionState: .submergedShallow
    )
    precondition(waterMeasure.depth?.value == 1.5)
    precondition(waterMeasure.submersionState == .submergedShallow)
    let wmDecoded = archiveRoundTrip(waterMeasure)
    precondition(wmDecoded.surfacePressure.value == 101.325)

    let waterTemp = CoreMotionHostControl.makeWaterTemperature(
        date: Date(timeIntervalSince1970: 3),
        temperature: Measurement(value: 18, unit: .celsius),
        temperatureUncertainty: Measurement(value: 0.5, unit: .celsius)
    )
    precondition(waterTemp.temperature.value == 18)
    precondition(
        archiveRoundTrip(waterTemp).temperatureUncertainty.value == 0.5
    )

    let list = CoreMotionHostControl.makeSensorDataList(items: [recordedAccel])
    precondition(Array(list).count == 1)
    precondition(CMSensorDataList().count == 0)
}

private func assertMotionManagerFailClosed() {
    let manager = CMMotionManager()
    precondition(!manager.isAccelerometerAvailable)
    precondition(!manager.isGyroAvailable)
    precondition(!manager.isMagnetometerAvailable)
    precondition(!manager.isDeviceMotionAvailable)
    precondition(!manager.isAccelerometerActive)
    precondition(!manager.isGyroActive)
    precondition(!manager.isMagnetometerActive)
    precondition(!manager.isDeviceMotionActive)
    precondition(manager.accelerometerData == nil)
    precondition(manager.gyroData == nil)
    precondition(manager.magnetometerData == nil)
    precondition(manager.deviceMotion == nil)

    manager.accelerometerUpdateInterval = 0.02
    manager.gyroUpdateInterval = 0.03
    manager.magnetometerUpdateInterval = 0.04
    manager.deviceMotionUpdateInterval = 0.05
    precondition(manager.accelerometerUpdateInterval == 0.02)
    precondition(manager.gyroUpdateInterval == 0.03)
    precondition(manager.magnetometerUpdateInterval == 0.04)
    precondition(manager.deviceMotionUpdateInterval == 0.05)
    manager.showsDeviceMovementDisplay = true
    precondition(manager.showsDeviceMovementDisplay)

    manager.startAccelerometerUpdates()
    manager.startGyroUpdates()
    manager.startMagnetometerUpdates()
    manager.startDeviceMotionUpdates()
    precondition(!manager.isAccelerometerActive)
    precondition(!manager.isGyroActive)
    precondition(!manager.isMagnetometerActive)
    precondition(!manager.isDeviceMotionActive)
    precondition(manager.accelerometerData == nil)

    manager.startDeviceMotionUpdates(using: .xTrueNorthZVertical)
    precondition(manager.attitudeReferenceFrame == .xTrueNorthZVertical)
    precondition(!manager.isDeviceMotionActive)

    proveQueuedHandler { queue, state in
        manager.startAccelerometerUpdates(to: queue) { data, error in
            state.noteCallback(sampleIsNil: data == nil, error: error)
        }
    }
    proveQueuedHandler { queue, state in
        manager.startGyroUpdates(to: queue) { data, error in
            state.noteCallback(sampleIsNil: data == nil, error: error)
        }
    }
    proveQueuedHandler { queue, state in
        manager.startMagnetometerUpdates(to: queue) { data, error in
            state.noteCallback(sampleIsNil: data == nil, error: error)
        }
    }
    proveQueuedHandler { queue, state in
        manager.startDeviceMotionUpdates(to: queue) { data, error in
            state.noteCallback(sampleIsNil: data == nil, error: error)
        }
    }
    proveQueuedHandler { queue, state in
        manager.startDeviceMotionUpdates(using: .xMagneticNorthZVertical, to: queue) { data, error in
            state.noteCallback(sampleIsNil: data == nil, error: error)
        }
    }
    precondition(manager.attitudeReferenceFrame == .xMagneticNorthZVertical)
    manager.stopAccelerometerUpdates()
    manager.stopGyroUpdates()
    manager.stopMagnetometerUpdates()
    manager.stopDeviceMotionUpdates()
}

private func assertOtherManagers() {
    precondition(CMAltimeter.authorizationStatus() == .denied)
    precondition(!CMAltimeter.isRelativeAltitudeAvailable())
    precondition(!CMAltimeter.isAbsoluteAltitudeAvailable())
    let altimeter = CMAltimeter()
    proveQueuedHandler { queue, state in
        altimeter.startRelativeAltitudeUpdates(to: queue) { data, error in
            state.noteCallback(sampleIsNil: data == nil, error: error)
        }
    }
    proveQueuedHandler { queue, state in
        altimeter.startAbsoluteAltitudeUpdates(to: queue) { data, error in
            state.noteCallback(sampleIsNil: data == nil, error: error)
        }
    }
    altimeter.stopRelativeAltitudeUpdates()
    altimeter.stopAbsoluteAltitudeUpdates()

    precondition(CMPedometer.authorizationStatus() == .denied)
    precondition(!CMPedometer.isStepCountingAvailable())
    precondition(!CMPedometer.isDistanceAvailable())
    precondition(!CMPedometer.isFloorCountingAvailable())
    precondition(!CMPedometer.isPaceAvailable())
    precondition(!CMPedometer.isCadenceAvailable())
    precondition(!CMPedometer.isPedometerEventTrackingAvailable())
    let pedometer = CMPedometer()
    let pedState = LockedState()
    let pedQueue = coreMotionProbePrivateWait(
        start: {
            pedometer.queryPedometerData(
                from: Date(timeIntervalSince1970: 0),
                to: Date(timeIntervalSince1970: 1)
            ) { data, error in
                pedState.noteCallback(sampleIsNil: data == nil, error: error)
            }
        },
        state: pedState
    )
    _ = pedQueue
    pedometer.startUpdates(from: Date()) { _, _ in }
    pedometer.stopUpdates()
    pedometer.startEventUpdates { _, _ in }
    pedometer.stopEventUpdates()

    precondition(CMMotionActivityManager.authorizationStatus() == .denied)
    precondition(!CMMotionActivityManager.isActivityAvailable())
    let activity = CMMotionActivityManager()
    proveQueuedHandler { queue, state in
        activity.queryActivityStarting(
            from: Date(timeIntervalSince1970: 0),
            to: Date(timeIntervalSince1970: 1),
            to: queue
        ) { samples, error in
            state.noteCallback(sampleIsNil: samples == nil, error: error)
        }
    }
    let silent = OperationQueue()
    activity.startActivityUpdates(to: silent) { sample in
        fatalError("activity handler must not be invented, got \(String(describing: sample))")
    }
    activity.stopActivityUpdates()

    precondition(!CMStepCounter.isStepCountingAvailable())
    let steps = CMStepCounter()
    proveQueuedHandler { queue, state in
        steps.queryStepCountStarting(
            from: Date(timeIntervalSince1970: 0),
            to: Date(timeIntervalSince1970: 1),
            to: queue
        ) { count, error in
            state.noteCallback(sampleIsNil: count == 0, error: error)
        }
    }
    proveQueuedHandler { queue, state in
        steps.startStepCountingUpdates(to: queue, updateOn: 1) { _, _, error in
            state.noteCallback(sampleIsNil: true, error: error)
        }
    }
    steps.stopStepCountingUpdates()

    precondition(!CMBatchedSensorManager.isAccelerometerSupported)
    precondition(!CMBatchedSensorManager.isDeviceMotionSupported)
    precondition(CMBatchedSensorManager.authorizationStatus == .denied)
    let batched = CMBatchedSensorManager()
    precondition(!batched.isAccelerometerActive)
    precondition(!batched.isDeviceMotionActive)
    precondition(batched.accelerometerBatch == nil)
    precondition(batched.deviceMotionBatch == nil)
    precondition(batched.accelerometerDataFrequency == 0)
    precondition(batched.deviceMotionDataFrequency == 0)
    batched.startAccelerometerUpdates()
    batched.startDeviceMotionUpdates()
    precondition(!batched.isAccelerometerActive)
    let batchState = LockedState()
    _ = coreMotionProbePrivateWait(
        start: {
            batched.startAccelerometerUpdates { data, error in
                batchState.noteCallback(sampleIsNil: data == nil, error: error)
            }
        },
        state: batchState
    )
    let batchMotionState = LockedState()
    _ = coreMotionProbePrivateWait(
        start: {
            batched.startDeviceMotionUpdates { data, error in
                batchMotionState.noteCallback(sampleIsNil: data == nil, error: error)
            }
        },
        state: batchMotionState
    )
    batched.stopAccelerometerUpdates()
    batched.stopDeviceMotionUpdates()

    precondition(CMSensorRecorder.authorizationStatus() == .denied)
    precondition(!CMSensorRecorder.isAccelerometerRecordingAvailable())
    precondition(!CMSensorRecorder.isAuthorizedForRecording())
    let recorder = CMSensorRecorder()
    recorder.recordAccelerometer(forDuration: 1)
    precondition(
        recorder.accelerometerData(
            from: Date(timeIntervalSince1970: 0),
            to: Date(timeIntervalSince1970: 1)
        ) == nil
    )

    precondition(CMHeadphoneMotionManager.authorizationStatus() == .denied)
    let headphones = CMHeadphoneMotionManager()
    precondition(!headphones.isDeviceMotionAvailable)
    precondition(!headphones.isDeviceMotionActive)
    precondition(!headphones.isConnectionStatusActive)
    precondition(headphones.deviceMotion == nil)
    let headphoneDelegate = HeadphoneProbe()
    headphones.delegate = headphoneDelegate
    precondition(headphones.delegate === headphoneDelegate)
    precondition(!headphoneDelegate.connected)
    headphones.startDeviceMotionUpdates()
    proveQueuedHandler { queue, state in
        headphones.startDeviceMotionUpdates(to: queue) { data, error in
            state.noteCallback(sampleIsNil: data == nil, error: error)
        }
    }
    headphones.stopDeviceMotionUpdates()
    headphones.startConnectionStatusUpdates()
    headphones.stopConnectionStatusUpdates()

    precondition(CMHeadphoneActivityManager.authorizationStatus() == .denied)
    let headphoneActivity = CMHeadphoneActivityManager()
    precondition(!headphoneActivity.isActivityAvailable)
    precondition(!headphoneActivity.isStatusAvailable)
    precondition(!headphoneActivity.isActivityActive)
    precondition(!headphoneActivity.isStatusActive)
    proveQueuedHandler { queue, state in
        headphoneActivity.startActivityUpdates(to: queue) { data, error in
            state.noteCallback(sampleIsNil: data == nil, error: error)
        }
    }
    proveQueuedHandler { queue, state in
        headphoneActivity.startStatusUpdates(to: queue) { status, error in
            state.noteCallback(sampleIsNil: status == .disconnected, error: error)
        }
    }
    headphoneActivity.stopActivityUpdates()
    headphoneActivity.stopStatusUpdates()

    precondition(CMWaterSubmersionManager.authorizationStatus == .denied)
    precondition(!CMWaterSubmersionManager.waterSubmersionAvailable)
    let water = CMWaterSubmersionManager()
    precondition(water.maximumDepth == nil)
    let waterDelegate = WaterProbe()
    water.delegate = waterDelegate
    precondition(water.delegate === waterDelegate)
    precondition(waterDelegate.errors == 0)
    precondition(waterDelegate.events == 0)
}

private func coreMotionProbePrivateWait(
    start: () -> Void,
    state: LockedState
) -> Int {
    let blocker = CompletionQueueBlocker(queue: coreMotionPrivateQueueForTests())
    blocker.occupy()
    start()
    state.markReturned()
    precondition(state.snapshot().count == 0)
    blocker.release()
    let drained = DispatchSemaphore(value: 0)
    CoreMotionHostControl.enqueueCompletionProbe {
        drained.signal()
    }
    waitEvent(drained, "private completion queue did not drain")
    let after = state.snapshot()
    precondition(after.count == 1)
    precondition(after.sawReturned)
    requireUnavailableError(after.error)
    return after.count
}

private func coreMotionPrivateQueueForTests() -> OperationQueue {
    CoreMotionHostControl.completionQueue
}

private final class HeadphoneProbe: NSObject, CMHeadphoneMotionManagerDelegate {
    var connected = false
    func headphoneMotionManagerDidConnect(_ manager: CMHeadphoneMotionManager) {
        connected = true
        _ = manager
    }
    func headphoneMotionManagerDidDisconnect(_ manager: CMHeadphoneMotionManager) {
        _ = manager
    }
}

private final class WaterProbe: NSObject, CMWaterSubmersionManagerDelegate {
    var errors = 0
    var events = 0
    func manager(
        _ manager: CMWaterSubmersionManager,
        didUpdate event: CMWaterSubmersionEvent
    ) {
        _ = manager
        _ = event
        events += 1
    }
    func manager(
        _ manager: CMWaterSubmersionManager,
        didUpdate measurement: CMWaterSubmersionMeasurement
    ) {
        _ = manager
        _ = measurement
    }
    func manager(
        _ manager: CMWaterSubmersionManager,
        didUpdate measurement: CMWaterTemperature
    ) {
        _ = manager
        _ = measurement
    }
    func manager(_ manager: CMWaterSubmersionManager, errorOccurred error: any Error) {
        _ = manager
        _ = error
        errors += 1
    }
}

func coreMotionRuntimeMain() {
    assertValueTypes()
    assertAttitudeMath()
    assertEnums()
    assertOptionSet()
    assertErrorSurface()
    assertSamplesAndCoding()
    assertMotionManagerFailClosed()
    assertOtherManagers()
    print("COREMOTION_AGENT_RUNTIME_OK")
}

coreMotionRuntimeMain()
