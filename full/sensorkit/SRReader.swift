import Foundation

public protocol SRSensorReaderDelegate: AnyObject {
    func sensorReader(_ reader: SRSensorReader, didChange authorizationStatus: SRAuthorizationStatus)
    func sensorReader(_ reader: SRSensorReader, didCompleteFetch fetchRequest: SRFetchRequest)
    func sensorReader(_ reader: SRSensorReader, didFetch devices: [SRDevice])
    func sensorReader(_ reader: SRSensorReader, fetchDevicesDidFailWithError error: any Error)
    func sensorReader(_ reader: SRSensorReader, fetching fetchRequest: SRFetchRequest, didFetchResult result: SRFetchResult<AnyObject>) -> Bool
    func sensorReader(_ reader: SRSensorReader, fetching fetchRequest: SRFetchRequest, failedWithError error: any Error)
    func sensorReader(_ reader: SRSensorReader, startRecordingFailedWithError error: any Error)
    func sensorReader(_ reader: SRSensorReader, stopRecordingFailedWithError error: any Error)
    func sensorReaderDidStopRecording(_ reader: SRSensorReader)
    func sensorReaderWillStartRecording(_ reader: SRSensorReader)
}

extension SRSensorReaderDelegate {
    public func sensorReader(_ reader: SRSensorReader, didChange authorizationStatus: SRAuthorizationStatus) {}
    public func sensorReader(_ reader: SRSensorReader, didCompleteFetch fetchRequest: SRFetchRequest) {}
    public func sensorReader(_ reader: SRSensorReader, didFetch devices: [SRDevice]) {}
    public func sensorReader(_ reader: SRSensorReader, fetchDevicesDidFailWithError error: any Error) {}
    public func sensorReader(_ reader: SRSensorReader, fetching fetchRequest: SRFetchRequest, didFetchResult result: SRFetchResult<AnyObject>) -> Bool { false }
    public func sensorReader(_ reader: SRSensorReader, fetching fetchRequest: SRFetchRequest, failedWithError error: any Error) {}
    public func sensorReader(_ reader: SRSensorReader, startRecordingFailedWithError error: any Error) {}
    public func sensorReader(_ reader: SRSensorReader, stopRecordingFailedWithError error: any Error) {}
    public func sensorReaderDidStopRecording(_ reader: SRSensorReader) {}
    public func sensorReaderWillStartRecording(_ reader: SRSensorReader) {}
}

public class SRFetchRequest: NSObject {
    public var device: SRDevice
    public var from: SRAbsoluteTime
    public var to: SRAbsoluteTime

    public override init() {
        self.device = SRDevice.current
        self.from = SRAbsoluteTime(0)
        self.to = SRAbsoluteTime(0)
        super.init()
    }
}

public class SRFetchResult<SampleType: AnyObject>: NSObject {
    private let _sample: SampleType
    private let _timestamp: SRAbsoluteTime

    public var sample: SampleType { _sample }
    public var timestamp: SRAbsoluteTime { _timestamp }

    @_spi(OpenUIKitHost)
    public init(sample: SampleType, timestamp: SRAbsoluteTime) {
        self._sample = sample
        self._timestamp = timestamp
        super.init()
    }
}

public class SRSensorReader: NSObject {
    public private(set) var sensor: SRSensor
    public weak var delegate: (any SRSensorReaderDelegate)?

    /// Linux has no Research-app prompt or SensorKit daemon.
    public var authorizationStatus: SRAuthorizationStatus { .denied }

    public init(sensor: SRSensor) {
        self.sensor = sensor
        super.init()
    }

    public func fetch(_ request: SRFetchRequest) {
        let code: SRError.Code
        if request.to.rawValue < request.from.rawValue {
            code = .fetchRequestInvalid
        } else {
            code = .noAuthorization
        }
        delegate?.sensorReader(self, fetching: request, failedWithError: srMakeError(code))
    }

    public func fetchDevices() {
        delegate?.sensorReader(self, fetchDevicesDidFailWithError: srMakeError(.noAuthorization))
    }

    public func startRecording() {
        delegate?.sensorReader(self, startRecordingFailedWithError: srMakeError(.invalidEntitlement))
    }

    public func stopRecording() {
        delegate?.sensorReader(self, stopRecordingFailedWithError: srMakeError(.dataInaccessible))
    }

    public class func requestAuthorization(sensors: Set<SRSensor>) async throws {
        _ = sensors
        throw srMakeError(.invalidEntitlement)
    }
}
