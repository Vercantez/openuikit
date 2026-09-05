@_spi(OpenUIKitHost) import CoreMotion
import Foundation

func testMotionManagerAvailability() {
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
}

func testMotionManagerIntervals() {
    let manager = CMMotionManager()
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
}

func testMotionManagerPullStart() {
    let manager = CMMotionManager()
    manager.startAccelerometerUpdates()
    manager.startGyroUpdates()
    manager.startMagnetometerUpdates()
    manager.startDeviceMotionUpdates()
    precondition(!manager.isAccelerometerActive)
    precondition(!manager.isGyroActive)
    precondition(!manager.isMagnetometerActive)
    precondition(!manager.isDeviceMotionActive)
    precondition(manager.accelerometerData == nil)
    manager.stopAccelerometerUpdates()
    manager.stopGyroUpdates()
    manager.stopMagnetometerUpdates()
    manager.stopDeviceMotionUpdates()
}

func testMotionManagerHandlerStart() {
    let manager = CMMotionManager()
    let accel: CMAccelerometerHandler = { _, _ in }
    let gyro: CMGyroHandler = { _, _ in }
    let mag: CMMagnetometerHandler = { _, _ in }
    let motion: CMDeviceMotionHandler = { _, _ in }
    coreMotionEnqueueOnSuspendedQueue { queue in
        manager.startAccelerometerUpdates(to: queue, withHandler: accel)
    }
    coreMotionEnqueueOnSuspendedQueue { queue in
        manager.startGyroUpdates(to: queue, withHandler: gyro)
    }
    coreMotionEnqueueOnSuspendedQueue { queue in
        manager.startMagnetometerUpdates(to: queue, withHandler: mag)
    }
    coreMotionEnqueueOnSuspendedQueue { queue in
        manager.startDeviceMotionUpdates(to: queue, withHandler: motion)
    }
    precondition(!manager.isAccelerometerActive)
    manager.stopAccelerometerUpdates()
    manager.stopGyroUpdates()
    manager.stopMagnetometerUpdates()
    manager.stopDeviceMotionUpdates()
}

func testMotionManagerReferenceFrame() {
    let manager = CMMotionManager()
    manager.startDeviceMotionUpdates(using: .xTrueNorthZVertical)
    precondition(manager.attitudeReferenceFrame == .xTrueNorthZVertical)
    precondition(!manager.isDeviceMotionActive)
    let motion: CMDeviceMotionHandler = { _, _ in }
    coreMotionEnqueueOnSuspendedQueue { queue in
        manager.startDeviceMotionUpdates(
            using: .xMagneticNorthZVertical,
            to: queue,
            withHandler: motion
        )
    }
    precondition(manager.attitudeReferenceFrame == .xMagneticNorthZVertical)
    manager.stopDeviceMotionUpdates()
}

func testHandlerTypeAliases() {
    let accel: CMAccelerometerHandler = { _, _ in }
    let gyro: CMGyroHandler = { _, _ in }
    let mag: CMMagnetometerHandler = { _, _ in }
    let motion: CMDeviceMotionHandler = { _, _ in }
    let altitude: CMAltitudeHandler = { _, _ in }
    let absolute: CMAbsoluteAltitudeHandler = { _, _ in }
    let activity: CMMotionActivityHandler = { _ in }
    let query: CMMotionActivityQueryHandler = { _, _ in }
    let pedometer: CMPedometerHandler = { _, _ in }
    let event: CMPedometerEventHandler = { _, _ in }
    let stepQuery: CMStepQueryHandler = { _, _ in }
    let stepUpdate: CMStepUpdateHandler = { _, _, _ in }
    _ = accel
    _ = gyro
    _ = mag
    _ = motion
    _ = altitude
    _ = absolute
    _ = activity
    _ = query
    _ = pedometer
    _ = event
    _ = stepQuery
    _ = stepUpdate
}
