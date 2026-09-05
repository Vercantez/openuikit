@_spi(OpenUIKitHost) import CoreMotion
import Foundation

func testLogItem() {
    let item = CoreMotionHostControl.makeLogItem(timestamp: 12.5)
    precondition(item.timestamp == 12.5)
    let decoded = coreMotionArchiveRoundTrip(item)
    precondition(decoded.timestamp == 12.5)
}

func testAccelerometerData() {
    let accel = CoreMotionHostControl.makeAccelerometerData(
        timestamp: 1,
        acceleration: CMAcceleration(x: 1, y: 0, z: -1)
    )
    precondition(accel.acceleration.x == 1)
    precondition(coreMotionArchiveRoundTrip(accel).acceleration.z == -1)
}

func testGyroAndRotationRateData() {
    let gyro = CoreMotionHostControl.makeGyroData(
        timestamp: 2,
        rotationRate: CMRotationRate(x: 0, y: 1, z: 0)
    )
    precondition(gyro.rotationRate.y == 1)
    let recorded = CoreMotionHostControl.makeRecordedRotationRateData(
        timestamp: 9,
        rotationRate: CMRotationRate(x: 1, y: 0, z: 0),
        startDate: Date(timeIntervalSince1970: 11)
    )
    precondition(recorded.startDate.timeIntervalSince1970 == 11)
    precondition(recorded.rotationRate.x == 1)
}

func testMagnetometerData() {
    let mag = CoreMotionHostControl.makeMagnetometerData(
        timestamp: 3,
        magneticField: CMMagneticField(x: 9, y: 8, z: 7)
    )
    precondition(mag.magneticField.x == 9)
}

func testDeviceMotionSample() {
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
    precondition(motion.rotationRate == CMRotationRate())
    precondition(motion.magneticField.accuracy == .uncalibrated)
    let decoded = coreMotionArchiveRoundTrip(motion)
    precondition(decoded.userAcceleration == CMAcceleration())
}

func testAltitudeSamples() {
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
}

func testRecordedSensorData() {
    let recordedAccel = CoreMotionHostControl.makeRecordedAccelerometerData(
        timestamp: 8,
        acceleration: CMAcceleration(x: 0.2, y: 0, z: 0),
        identifier: 99,
        startDate: Date(timeIntervalSince1970: 10)
    )
    precondition(recordedAccel.identifier == 99)
    precondition(recordedAccel.startDate.timeIntervalSince1970 == 10)

    let recordedPressure = CoreMotionHostControl.makeRecordedPressureData(
        timestamp: 10,
        pressure: Measurement(value: 100, unit: .kilopascals),
        temperature: Measurement(value: 15, unit: .celsius),
        identifier: 3,
        startDate: Date(timeIntervalSince1970: 12)
    )
    precondition(recordedPressure.identifier == 3)

    let list = CoreMotionHostControl.makeSensorDataList(items: [recordedAccel])
    precondition(Array(list).count == 1)
    precondition(CMSensorDataList().count == 0)
}

func testMotionActivitySample() {
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
    precondition(activity.startDate.timeIntervalSince1970 == 1)
    precondition(!activity.walking && !activity.running)
    precondition(!activity.automotive && !activity.cycling)
    precondition(!activity.unknown)
}
