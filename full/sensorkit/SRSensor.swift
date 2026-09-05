import Foundation

/// Typed sensor identifier. Linux raw values use the C constant spelling from
/// the TBD export names; Apple's on-device string payload is unobserved.
public struct SRSensor: RawRepresentable, Hashable, Sendable {
    public var rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public static let accelerometer = SRSensor(rawValue: "SRSensorAccelerometer")
    public static let acousticSettings = SRSensor(rawValue: "SRSensorAcousticSettings")
    public static let ambientLightSensor = SRSensor(rawValue: "SRSensorAmbientLightSensor")
    public static let ambientPressure = SRSensor(rawValue: "SRSensorAmbientPressure")
    public static let deviceUsageReport = SRSensor(rawValue: "SRSensorDeviceUsageReport")
    public static let electrocardiogram = SRSensor(rawValue: "SRSensorElectrocardiogram")
    public static let faceMetrics = SRSensor(rawValue: "SRSensorFaceMetrics")
    public static let heartRate = SRSensor(rawValue: "SRSensorHeartRate")
    public static let keyboardMetrics = SRSensor(rawValue: "SRSensorKeyboardMetrics")
    public static let mediaEvents = SRSensor(rawValue: "SRSensorMediaEvents")
    public static let messagesUsageReport = SRSensor(rawValue: "SRSensorMessagesUsageReport")
    public static let odometer = SRSensor(rawValue: "SRSensorOdometer")
    public static let onWristState = SRSensor(rawValue: "SRSensorOnWristState")
    public static let pedometerData = SRSensor(rawValue: "SRSensorPedometerData")
    public static let phoneUsageReport = SRSensor(rawValue: "SRSensorPhoneUsageReport")
    public static let photoplethysmogram = SRSensor(rawValue: "SRSensorPhotoplethysmogram")
    public static let rotationRate = SRSensor(rawValue: "SRSensorRotationRate")
    public static let siriSpeechMetrics = SRSensor(rawValue: "SRSensorSiriSpeechMetrics")
    public static let sleepSessions = SRSensor(rawValue: "SRSensorSleepSessions")
    public static let telephonySpeechMetrics = SRSensor(rawValue: "SRSensorTelephonySpeechMetrics")
    public static let visits = SRSensor(rawValue: "SRSensorVisits")
    public static let wristTemperature = SRSensor(rawValue: "SRSensorWristTemperature")
}

extension NSString {
    /// Linux-local deletion-record identifier: appends `DeletionRecords`.
    public func sr_sensorForDeletionRecordsFromSensor() -> SRSensor? {
        let value = self as String
        if value.isEmpty { return nil }
        return SRSensor(rawValue: value + "DeletionRecords")
    }
}

extension String {
    public func sr_sensorForDeletionRecordsFromSensor() -> SRSensor? {
        (self as NSString).sr_sensorForDeletionRecordsFromSensor()
    }
}
