import Foundation
@_spi(OpenUIKitHost) import SensorKit

private final class RecordingDelegate: SRSensorReaderDelegate {
    var authChanges: [SRAuthorizationStatus] = []
    var completed: [SRFetchRequest] = []
    var fetchedDevices: [[SRDevice]] = []
    var fetchDeviceErrors: [Error] = []
    var fetchResults: [(SRFetchRequest, SRFetchResult<AnyObject>)] = []
    var fetchErrors: [(SRFetchRequest, Error)] = []
    var startErrors: [Error] = []
    var stopErrors: [Error] = []
    var didStop = 0
    var willStart = 0

    func sensorReader(_ reader: SRSensorReader, didChange authorizationStatus: SRAuthorizationStatus) {
        authChanges.append(authorizationStatus)
    }

    func sensorReader(_ reader: SRSensorReader, didCompleteFetch fetchRequest: SRFetchRequest) {
        completed.append(fetchRequest)
    }

    func sensorReader(_ reader: SRSensorReader, didFetch devices: [SRDevice]) {
        fetchedDevices.append(devices)
    }

    func sensorReader(_ reader: SRSensorReader, fetchDevicesDidFailWithError error: any Error) {
        fetchDeviceErrors.append(error)
    }

    func sensorReader(_ reader: SRSensorReader, fetching fetchRequest: SRFetchRequest, didFetchResult result: SRFetchResult<AnyObject>) -> Bool {
        fetchResults.append((fetchRequest, result))
        return false
    }

    func sensorReader(_ reader: SRSensorReader, fetching fetchRequest: SRFetchRequest, failedWithError error: any Error) {
        fetchErrors.append((fetchRequest, error))
    }

    func sensorReader(_ reader: SRSensorReader, startRecordingFailedWithError error: any Error) {
        startErrors.append(error)
    }

    func sensorReader(_ reader: SRSensorReader, stopRecordingFailedWithError error: any Error) {
        stopErrors.append(error)
    }

    func sensorReaderDidStopRecording(_ reader: SRSensorReader) {
        didStop += 1
    }

    func sensorReaderWillStartRecording(_ reader: SRSensorReader) {
        willStart += 1
    }
}

func testSRDeviceCurrent() {
    let device = SRDevice.current
    skExpect(!device.name.isEmpty, "name")
    skExpect(device.model == "linux", "model")
    skExpect(device.productType == "linux", "product")
    skExpect(device.systemName == "Linux", "sysname")
    skExpect(!device.systemVersion.isEmpty, "version")
}

func testSRFetchRequestAndResult() {
    let request = SRFetchRequest()
    request.from = SRAbsoluteTime(1)
    request.to = SRAbsoluteTime(2)
    request.device = SRDevice.current
    skExpect(request.from.rawValue == 1, "from")
    skExpect(request.to.rawValue == 2, "to")
    skExpect(request.device.model == "linux", "device")

    let sample = SRSleepSession(duration: 1, identifier: "x", startDate: Date())
    let result = SRFetchResult(sample: sample, timestamp: SRAbsoluteTime(9))
    skExpect(result.sample.identifier == "x", "sample")
    skExpect(result.timestamp.rawValue == 9, "ts")
}

func testSRSensorReaderFailClosed() {
    let reader = SRSensorReader(sensor: .accelerometer)
    skExpect(reader.sensor == .accelerometer, "sensor")
    skExpect(reader.authorizationStatus == .denied, "denied")
    skExpect(reader.delegate == nil, "nil delegate")

    let delegate = RecordingDelegate()
    reader.delegate = delegate

    let valid = SRFetchRequest()
    valid.from = SRAbsoluteTime(0)
    valid.to = SRAbsoluteTime(1)
    reader.fetch(valid)
    skExpect(delegate.fetchErrors.count == 1, "fetch error")
    skExpect(SRError.Code.noAuthorization ~= delegate.fetchErrors[0].1, "no auth")
    skExpect(delegate.completed.isEmpty, "no complete")
    skExpect(delegate.fetchResults.isEmpty, "no results")

    let invalid = SRFetchRequest()
    invalid.from = SRAbsoluteTime(5)
    invalid.to = SRAbsoluteTime(1)
    reader.fetch(invalid)
    skExpect(SRError.Code.fetchRequestInvalid ~= delegate.fetchErrors[1].1, "invalid")

    reader.fetchDevices()
    skExpect(SRError.Code.noAuthorization ~= delegate.fetchDeviceErrors[0], "devices")
    skExpect(delegate.fetchedDevices.isEmpty, "no devices")

    reader.startRecording()
    skExpect(SRError.Code.invalidEntitlement ~= delegate.startErrors[0], "start")
    skExpect(delegate.willStart == 0, "willStart not success")

    reader.stopRecording()
    skExpect(SRError.Code.dataInaccessible ~= delegate.stopErrors[0], "stop")
    skExpect(delegate.didStop == 0, "didStop not success")

    reader.delegate = nil
    reader.fetch(valid)
    reader.fetchDevices()
    reader.startRecording()
    reader.stopRecording()
}

func testSRSensorReaderDelegateProtocolExists() {
    let unused: (any SRSensorReaderDelegate)? = nil
    skExpect(unused == nil, "protocol is instantiable as existential")
}

func testDeletionRecordAndSupplemental() {
    let record = SRDeletionRecord(
        startTime: SRAbsoluteTime(1),
        endTime: SRAbsoluteTime(2),
        reason: .userInitiated
    )
    skExpect(record.startTime.rawValue == 1, "start")
    skExpect(record.endTime.rawValue == 2, "end")
    skExpect(record.reason == .userInitiated, "reason")

    let category = SRSupplementalCategory(identifier: "com.example")
    skExpect(category.identifier == "com.example", "id")
}

func testTextInputSession() {
    let session = SRTextInputSession(duration: 3, sessionIdentifier: "s", sessionType: .dictation)
    skExpect(session.duration == 3, "dur")
    skExpect(session.sessionIdentifier == "s", "id")
    skExpect(session.sessionType == .dictation, "type")
}
