@_spi(OpenUIKitHost) import CoreMotion
import Foundation

/// Schema-v1 host probe. The depth-pass evidence lives in `*Tests.swift`;
/// this file must remain a self-contained executable for the sealed gate.
func coreMotionRuntimeMain() {
    precondition(CMErrorDomain == "CMErrorDomain")
    precondition(CMErrorNULL.rawValue == 100)
    precondition(CMErrorNotAvailable.rawValue == 109)
    precondition(CMErrorNilData.rawValue == 112)
    precondition(CMErrorSize.rawValue == 113)
    precondition(CMAcceleration(x: 1, y: 0, z: -1).z == -1)
    precondition(CMAuthorizationStatus.denied.rawValue == 2)
    precondition(CMAttitudeReferenceFrame.xTrueNorthZVertical.rawValue == 1 << 3)

    let manager = CMMotionManager()
    precondition(!manager.isAccelerometerAvailable)
    manager.startAccelerometerUpdates()
    precondition(!manager.isAccelerometerActive)
    precondition(manager.accelerometerData == nil)
    manager.stopAccelerometerUpdates()

    precondition(CMPedometer.authorizationStatus() == .denied)
    precondition(!CMAltimeter.isRelativeAltitudeAvailable())
    precondition(CMWaterSubmersionManager.authorizationStatus == .denied)

    let item = CoreMotionHostControl.makeLogItem(timestamp: 1)
    precondition(item.timestamp == 1)

    print("COREMOTION_AGENT_RUNTIME_OK")
}

coreMotionRuntimeMain()
