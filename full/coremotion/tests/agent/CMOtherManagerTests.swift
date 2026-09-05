@_spi(OpenUIKitHost) import CoreMotion
import Foundation

func testAltimeterFailClosed() {
    precondition(CMAltimeter.authorizationStatus() == .denied)
    precondition(!CMAltimeter.isRelativeAltitudeAvailable())
    precondition(!CMAltimeter.isAbsoluteAltitudeAvailable())
    let altimeter = CMAltimeter()
    let relative: CMAltitudeHandler = { _, _ in }
    let absolute: CMAbsoluteAltitudeHandler = { _, _ in }
    coreMotionEnqueueOnSuspendedQueue { queue in
        altimeter.startRelativeAltitudeUpdates(to: queue, withHandler: relative)
    }
    coreMotionEnqueueOnSuspendedQueue { queue in
        altimeter.startAbsoluteAltitudeUpdates(to: queue, withHandler: absolute)
    }
    altimeter.stopRelativeAltitudeUpdates()
    altimeter.stopAbsoluteAltitudeUpdates()
}

func testMotionActivityManagerFailClosed() {
    precondition(CMMotionActivityManager.authorizationStatus() == .denied)
    precondition(!CMMotionActivityManager.isActivityAvailable())
    let activity = CMMotionActivityManager()
    let query: CMMotionActivityQueryHandler = { _, _ in }
    coreMotionEnqueueOnSuspendedQueue { queue in
        activity.queryActivityStarting(
            from: Date(timeIntervalSince1970: 0),
            to: Date(timeIntervalSince1970: 1),
            to: queue,
            withHandler: query
        )
    }
    let silent = OperationQueue()
    silent.isSuspended = true
    let handler: CMMotionActivityHandler = { sample in
        _ = sample
    }
    activity.startActivityUpdates(to: silent, withHandler: handler)
    precondition(silent.operationCount == 0)
    activity.stopActivityUpdates()
}

func testStepCounterFailClosed() {
    precondition(!CMStepCounter.isStepCountingAvailable())
    let steps = CMStepCounter()
    let query: CMStepQueryHandler = { _, _ in }
    let update: CMStepUpdateHandler = { _, _, _ in }
    coreMotionEnqueueOnSuspendedQueue { queue in
        steps.queryStepCountStarting(
            from: Date(timeIntervalSince1970: 0),
            to: Date(timeIntervalSince1970: 1),
            to: queue,
            withHandler: query
        )
    }
    coreMotionEnqueueOnSuspendedQueue { queue in
        steps.startStepCountingUpdates(to: queue, updateOn: 1, withHandler: update)
    }
    steps.stopStepCountingUpdates()
}

func testBatchedSensorManagerFailClosed() {
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
    batched.startAccelerometerUpdates { _, _ in }
    batched.startDeviceMotionUpdates { _, _ in }
    batched.stopAccelerometerUpdates()
    batched.stopDeviceMotionUpdates()
}

func testSensorRecorderFailClosed() {
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
}

func testHeadphoneMotionManagerFailClosed() {
    precondition(CMHeadphoneMotionManager.authorizationStatus() == .denied)
    let headphones = CMHeadphoneMotionManager()
    precondition(!headphones.isDeviceMotionAvailable)
    precondition(!headphones.isDeviceMotionActive)
    precondition(!headphones.isConnectionStatusActive)
    precondition(headphones.deviceMotion == nil)
    let probe = HeadphoneMotionProbe()
    headphones.delegate = probe
    precondition(headphones.delegate === probe)
    precondition(!probe.connected)
    headphones.startDeviceMotionUpdates()
    let handler: CMHeadphoneMotionManager.DeviceMotionHandler = { _, _ in }
    coreMotionEnqueueOnSuspendedQueue { queue in
        headphones.startDeviceMotionUpdates(to: queue, withHandler: handler)
    }
    headphones.stopDeviceMotionUpdates()
    headphones.startConnectionStatusUpdates()
    headphones.stopConnectionStatusUpdates()
    probe.headphoneMotionManagerDidConnect(headphones)
    probe.headphoneMotionManagerDidDisconnect(headphones)
    precondition(probe.connected)
}

func testHeadphoneActivityManagerFailClosed() {
    precondition(CMHeadphoneActivityManager.authorizationStatus() == .denied)
    let headphoneActivity = CMHeadphoneActivityManager()
    precondition(!headphoneActivity.isActivityAvailable)
    precondition(!headphoneActivity.isStatusAvailable)
    precondition(!headphoneActivity.isActivityActive)
    precondition(!headphoneActivity.isStatusActive)
    let activity: CMHeadphoneActivityManager.ActivityHandler = { _, _ in }
    let status: CMHeadphoneActivityManager.StatusHandler = { _, _ in }
    coreMotionEnqueueOnSuspendedQueue { queue in
        headphoneActivity.startActivityUpdates(to: queue, withHandler: activity)
    }
    coreMotionEnqueueOnSuspendedQueue { queue in
        headphoneActivity.startStatusUpdates(to: queue, withHandler: status)
    }
    headphoneActivity.stopActivityUpdates()
    headphoneActivity.stopStatusUpdates()
}

private final class HeadphoneMotionProbe: NSObject, CMHeadphoneMotionManagerDelegate {
    var connected = false

    func headphoneMotionManagerDidConnect(_ manager: CMHeadphoneMotionManager) {
        connected = true
        _ = manager
    }

    func headphoneMotionManagerDidDisconnect(_ manager: CMHeadphoneMotionManager) {
        _ = manager
    }
}
