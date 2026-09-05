@_spi(OpenUIKitHost) import CoreMotion
import Foundation

func testAuthorizationStatus() {
    let statuses: [CMAuthorizationStatus] = [
        .notDetermined, .restricted, .denied, .authorized
    ]
    precondition(statuses.map(\.rawValue) == [0, 1, 2, 3])
    precondition(CMAuthorizationStatus(rawValue: 2) == .denied)
    precondition(CMAuthorizationStatus(rawValue: 99) == nil)
    precondition(CMAuthorizationStatus.denied != .authorized)
    var hasher = Hasher()
    CMAuthorizationStatus.denied.hash(into: &hasher)
    precondition(CMAuthorizationStatus.denied.hashValue != CMAuthorizationStatus.authorized.hashValue)
}

func testMagneticFieldCalibrationAccuracy() {
    precondition(CMMagneticFieldCalibrationAccuracy.uncalibrated.rawValue == -1)
    precondition(CMMagneticFieldCalibrationAccuracy.low.rawValue == 0)
    precondition(CMMagneticFieldCalibrationAccuracy.medium.rawValue == 1)
    precondition(CMMagneticFieldCalibrationAccuracy.high.rawValue == 2)
    precondition(CMMagneticFieldCalibrationAccuracy(rawValue: -1) == .uncalibrated)
    precondition(CMMagneticFieldCalibrationAccuracy.low != .high)
    var hasher = Hasher()
    CMMagneticFieldCalibrationAccuracy.medium.hash(into: &hasher)
    precondition(
        CMMagneticFieldCalibrationAccuracy.low.hashValue
            != CMMagneticFieldCalibrationAccuracy.high.hashValue
    )
}

func testMotionActivityConfidence() {
    precondition(CMMotionActivityConfidence.low.rawValue == 0)
    precondition(CMMotionActivityConfidence.medium.rawValue == 1)
    precondition(CMMotionActivityConfidence.high.rawValue == 2)
    precondition(CMMotionActivityConfidence(rawValue: 1) == .medium)
    precondition(CMMotionActivityConfidence.low != .high)
    var hasher = Hasher()
    CMMotionActivityConfidence.medium.hash(into: &hasher)
    _ = CMMotionActivityConfidence.medium.hashValue
}

func testPedometerEventType() {
    precondition(CMPedometerEventType.pause.rawValue == 0)
    precondition(CMPedometerEventType.resume.rawValue == 1)
    precondition(CMPedometerEventType(rawValue: 0) == .pause)
    precondition(CMPedometerEventType.pause != .resume)
    var hasher = Hasher()
    CMPedometerEventType.resume.hash(into: &hasher)
    _ = CMPedometerEventType.resume.hashValue
}

func testOdometerOriginDevice() {
    precondition(CMOdometerOriginDevice.unknown.rawValue == 0)
    precondition(CMOdometerOriginDevice.local.rawValue == 1)
    precondition(CMOdometerOriginDevice.remote.rawValue == 2)
    precondition(CMOdometerOriginDevice(rawValue: 1) == .local)
    precondition(CMOdometerOriginDevice.local != .remote)
    var hasher = Hasher()
    CMOdometerOriginDevice.unknown.hash(into: &hasher)
    _ = CMOdometerOriginDevice.unknown.hashValue
}

func testHeartRateConfidence() {
    precondition(CMHighFrequencyHeartRateDataConfidence.low.rawValue == 0)
    precondition(CMHighFrequencyHeartRateDataConfidence.medium.rawValue == 1)
    precondition(CMHighFrequencyHeartRateDataConfidence.high.rawValue == 2)
    precondition(CMHighFrequencyHeartRateDataConfidence.highest.rawValue == 3)
    precondition(CMHighFrequencyHeartRateDataConfidence(rawValue: 3) == .highest)
    precondition(CMHighFrequencyHeartRateDataConfidence.low != .highest)
    var hasher = Hasher()
    CMHighFrequencyHeartRateDataConfidence.medium.hash(into: &hasher)
    _ = CMHighFrequencyHeartRateDataConfidence.medium.hashValue
}

func testDeviceMotionSensorLocation() {
    precondition(CMDeviceMotion.SensorLocation.default.rawValue == 0)
    precondition(CMDeviceMotion.SensorLocation.headphoneLeft.rawValue == 1)
    precondition(CMDeviceMotion.SensorLocation.headphoneRight.rawValue == 2)
    precondition(CMDeviceMotion.SensorLocation(rawValue: 0) == .default)
    precondition(CMDeviceMotion.SensorLocation.default != .headphoneLeft)
    var hasher = Hasher()
    CMDeviceMotion.SensorLocation.headphoneRight.hash(into: &hasher)
    _ = CMDeviceMotion.SensorLocation.headphoneRight.hashValue
}

func testHeadphoneActivityStatus() {
    precondition(CMHeadphoneActivityManager.Status.disconnected.rawValue == 0)
    precondition(CMHeadphoneActivityManager.Status.connected.rawValue == 1)
    precondition(CMHeadphoneActivityManager.Status(rawValue: 1) == .connected)
    precondition(
        CMHeadphoneActivityManager.Status.connected
            != .disconnected
    )
    var hasher = Hasher()
    CMHeadphoneActivityManager.Status.disconnected.hash(into: &hasher)
    _ = CMHeadphoneActivityManager.Status.disconnected.hashValue
}

func testWaterSubmersionState() {
    precondition(CMWaterSubmersionEvent.State.unknown.rawValue == 0)
    precondition(CMWaterSubmersionEvent.State.notSubmerged.rawValue == 1)
    precondition(CMWaterSubmersionEvent.State.submerged.rawValue == 2)
    precondition(CMWaterSubmersionEvent.State(rawValue: 2) == .submerged)
    precondition(CMWaterSubmersionEvent.State.submerged != .notSubmerged)
    var hasher = Hasher()
    CMWaterSubmersionEvent.State.unknown.hash(into: &hasher)
    _ = CMWaterSubmersionEvent.State.unknown.hashValue
}

func testWaterSubmersionDepthState() {
    let states: [CMWaterSubmersionMeasurement.DepthState] = [
        .unknown, .notSubmerged, .submergedShallow, .submergedDeep,
        .approachingMaxDepth, .pastMaxDepth, .sensorDepthError
    ]
    precondition(states.map(\.rawValue) == [0, 1, 2, 3, 4, 5, 6])
    precondition(CMWaterSubmersionMeasurement.DepthState(rawValue: 4) == .approachingMaxDepth)
    precondition(
        CMWaterSubmersionMeasurement.DepthState.submergedShallow
            != .pastMaxDepth
    )
    var hasher = Hasher()
    CMWaterSubmersionMeasurement.DepthState.unknown.hash(into: &hasher)
    _ = CMWaterSubmersionMeasurement.DepthState.unknown.hashValue
}
