import Foundation
import SensorKit

/// Isolated-host identity probe. Real Foundation values pass through public SensorKit APIs.
func sensorKitDependencyIdentityProbe() {
    let interval: TimeInterval = 12.5
    let time = SRAbsoluteTime(interval)
    precondition(time.rawValue == interval)

    let date = Date(SRAbsoluteTime: time)
    precondition(abs(date.srAbsoluteTime.rawValue - interval) < 0.000_001)

    let domain: String = SRErrorDomain
    let error = SRError(.noAuthorization, userInfo: [NSLocalizedDescriptionKey: domain])
    precondition((error as NSError).domain == domain)
    precondition(error.errorCode == SRError.Code.noAuthorization.rawValue)

    let request = SRFetchRequest()
    request.from = time
    request.to = SRAbsoluteTime.current()
    request.device = SRDevice.current
    precondition(request.from.rawValue == interval)

    let reader = SRSensorReader(sensor: .accelerometer)
    precondition(reader.authorizationStatus == .denied)

    let data = Data([0x53, 0x4b])
    precondition(data.count == 2)
}
