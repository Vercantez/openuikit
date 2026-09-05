import Foundation
@_spi(OpenUIKitHost) import SensorKit

func testSRSensorIdentifiers() {
    let sensors: [SRSensor] = [
        .accelerometer, .acousticSettings, .ambientLightSensor, .ambientPressure,
        .deviceUsageReport, .electrocardiogram, .faceMetrics, .heartRate,
        .keyboardMetrics, .mediaEvents, .messagesUsageReport, .odometer,
        .onWristState, .pedometerData, .phoneUsageReport, .photoplethysmogram,
        .rotationRate, .siriSpeechMetrics, .sleepSessions, .telephonySpeechMetrics,
        .visits, .wristTemperature,
    ]
    skExpect(Set(sensors.map(\.rawValue)).count == sensors.count, "unique")
    for sensor in sensors {
        skExpect(SRSensor(rawValue: sensor.rawValue) == sensor, "round-trip \(sensor.rawValue)")
        skExpect(sensor != SRSensor(rawValue: sensor.rawValue + "-x"), "!=")
        _ = sensor.hashValue
        var hasher = Hasher()
        sensor.hash(into: &hasher)
        _ = hasher.finalize()
        skExpect(sensor.rawValue.hasPrefix("SRSensor"), "C spelling \(sensor.rawValue)")
    }
}

func testCategoryKeys() {
    let keys: [SRDeviceUsageReport.CategoryKey] = [
        .books, .business, .catalogs, .developerTools, .education, .entertainment,
        .finance, .foodAndDrink, .games, .graphicsAndDesign, .healthAndFitness,
        .kids, .lifestyle, .medical, .miscellaneous, .music, .navigation, .news,
        .newsstand, .photoAndVideo, .productivity, .reference, .shopping,
        .socialNetworking, .sports, .stickers, .travel, .utilities, .weather,
    ]
    skExpect(Set(keys.map(\.rawValue)).count == keys.count, "unique")
    for key in keys {
        skExpect(SRDeviceUsageReport.CategoryKey(rawValue: key.rawValue) == key, "rt")
        skExpect(key != SRDeviceUsageReport.CategoryKey(rawValue: "nope"), "!=")
        _ = key.hashValue
        var hasher = Hasher()
        key.hash(into: &hasher)
        _ = hasher.finalize()
        skExpect(key.rawValue.hasPrefix("SRDeviceUsageCategory"), key.rawValue)
    }
}

func testSRAbsoluteTime() {
    let t0 = SRAbsoluteTime(rawValue: 12.5)
    let t1 = SRAbsoluteTime(12.5)
    skExpect(t0.rawValue == 12.5, "rawValue")
    skExpect(t0 == t1, "eq")
    skExpect(t0 != SRAbsoluteTime(0), "!=")
    skExpect(t0.toCFAbsoluteTime() == 12.5, "toCF identity Linux")
    _ = t0.hashValue
    var hasher = Hasher()
    t0.hash(into: &hasher)
    _ = hasher.finalize()
    let now = SRAbsoluteTime.current()
    skExpect(now.rawValue > 0, "current is after 2001")
}

func testNSDateSRAbsoluteTime() {
    let time = SRAbsoluteTime(42)
    let date = NSDate(SRAbsoluteTime: time)
    skExpect(abs(date.srAbsoluteTime.rawValue - 42) < 0.000_001, "nsdate")
    let value = Date(SRAbsoluteTime: time)
    skExpect(abs(value.srAbsoluteTime.rawValue - 42) < 0.000_001, "date")
}

func testNSStringDeletionRecords() {
    let sensor = "SRSensorAccelerometer" as NSString
    let deletion = sensor.sr_sensorForDeletionRecordsFromSensor()
    skExpect(deletion?.rawValue == "SRSensorAccelerometerDeletionRecords", "suffix")
    skExpect(("" as NSString).sr_sensorForDeletionRecordsFromSensor() == nil, "empty")
    skExpect("SRSensorVisits".sr_sensorForDeletionRecordsFromSensor()?.rawValue == "SRSensorVisitsDeletionRecords", "string")
}
