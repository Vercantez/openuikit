@_spi(OpenUIKitHost) import CoreMotion
import Foundation

func testDyskineticSymptomResult() {
    let dys = CoreMotionHostControl.makeDyskineticSymptomResult(
        startDate: Date(timeIntervalSince1970: 0),
        endDate: Date(timeIntervalSince1970: 1),
        percentLikely: 0.2,
        percentUnlikely: 0.8
    )
    precondition(dys.percentLikely == 0.2)
    precondition(dys.startDate.timeIntervalSince1970 == 0)
    precondition(dys.endDate.timeIntervalSince1970 == 1)
    precondition(coreMotionArchiveRoundTrip(dys).percentUnlikely == 0.8)
}

func testTremorResult() {
    let tremor = CoreMotionHostControl.makeTremorResult(
        startDate: Date(timeIntervalSince1970: 0),
        endDate: Date(timeIntervalSince1970: 1),
        percentUnknown: 0.1,
        percentNone: 0.2,
        percentSlight: 0.3,
        percentMild: 0.15,
        percentModerate: 0.15,
        percentStrong: 0.1
    )
    precondition(tremor.percentMild == 0.15)
    precondition(tremor.percentUnknown == 0.1)
    precondition(tremor.percentNone == 0.2)
    precondition(tremor.percentSlight == 0.3)
    precondition(tremor.percentModerate == 0.15)
    precondition(tremor.startDate.timeIntervalSince1970 == 0)
    precondition(tremor.endDate.timeIntervalSince1970 == 1)
    precondition(coreMotionArchiveRoundTrip(tremor).percentStrong == 0.1)
}

func testHeartRateData() {
    let heart = CoreMotionHostControl.makeHeartRateData(
        timestamp: 1,
        heartRate: 72,
        confidence: .high,
        date: Date(timeIntervalSince1970: 20)
    )
    precondition(heart.heartRate == 72)
    precondition(heart.confidence == .high)
    precondition(heart.date?.timeIntervalSince1970 == 20)
}

func testWaterSubmersionEvent() {
    let waterEvent = CoreMotionHostControl.makeWaterSubmersionEvent(
        date: Date(timeIntervalSince1970: 1),
        state: .notSubmerged
    )
    precondition(waterEvent.state == .notSubmerged)
    precondition(waterEvent.date.timeIntervalSince1970 == 1)
    precondition(coreMotionArchiveRoundTrip(waterEvent).state == .notSubmerged)
}

func testWaterSubmersionMeasurement() {
    let waterMeasure = CoreMotionHostControl.makeWaterSubmersionMeasurement(
        date: Date(timeIntervalSince1970: 2),
        depth: Measurement(value: 1.5, unit: .meters),
        pressure: Measurement(value: 120, unit: .kilopascals),
        surfacePressure: Measurement(value: 101.325, unit: .kilopascals),
        submersionState: .submergedShallow
    )
    precondition(waterMeasure.depth?.value == 1.5)
    precondition(waterMeasure.pressure?.value == 120)
    precondition(waterMeasure.submersionState == .submergedShallow)
    precondition(waterMeasure.date.timeIntervalSince1970 == 2)
    let decoded = coreMotionArchiveRoundTrip(waterMeasure)
    precondition(decoded.surfacePressure.value == 101.325)
}

func testWaterTemperature() {
    let waterTemp = CoreMotionHostControl.makeWaterTemperature(
        date: Date(timeIntervalSince1970: 3),
        temperature: Measurement(value: 18, unit: .celsius),
        temperatureUncertainty: Measurement(value: 0.5, unit: .celsius)
    )
    precondition(waterTemp.temperature.value == 18)
    precondition(waterTemp.date.timeIntervalSince1970 == 3)
    precondition(coreMotionArchiveRoundTrip(waterTemp).temperatureUncertainty.value == 0.5)
}

func testWaterSubmersionManagerFailClosed() {
    precondition(CMWaterSubmersionManager.authorizationStatus == .denied)
    precondition(!CMWaterSubmersionManager.waterSubmersionAvailable)
    let water = CMWaterSubmersionManager()
    precondition(water.maximumDepth == nil)
    let probe = WaterSubmersionProbe()
    water.delegate = probe
    precondition(water.delegate === probe)
    precondition(probe.errors == 0)
    precondition(probe.events == 0)
    probe.manager(water, didUpdate: CoreMotionHostControl.makeWaterSubmersionEvent(
        date: Date(),
        state: .unknown
    ))
    probe.manager(water, didUpdate: CoreMotionHostControl.makeWaterSubmersionMeasurement(
        date: Date(),
        depth: nil,
        pressure: nil,
        surfacePressure: Measurement(value: 101.325, unit: .kilopascals),
        submersionState: .unknown
    ))
    probe.manager(water, didUpdate: CoreMotionHostControl.makeWaterTemperature(
        date: Date(),
        temperature: Measurement(value: 0, unit: .celsius),
        temperatureUncertainty: Measurement(value: 0, unit: .celsius)
    ))
    probe.manager(water, errorOccurred: NSError(domain: CMErrorDomain, code: 109, userInfo: nil))
    precondition(probe.events == 1)
    precondition(probe.errors == 1)
}

private final class WaterSubmersionProbe: NSObject, CMWaterSubmersionManagerDelegate {
    var errors = 0
    var events = 0

    func manager(
        _ manager: CMWaterSubmersionManager,
        didUpdate event: CMWaterSubmersionEvent
    ) {
        _ = manager
        _ = event
        events += 1
    }

    func manager(
        _ manager: CMWaterSubmersionManager,
        didUpdate measurement: CMWaterSubmersionMeasurement
    ) {
        _ = manager
        _ = measurement
    }

    func manager(
        _ manager: CMWaterSubmersionManager,
        didUpdate measurement: CMWaterTemperature
    ) {
        _ = manager
        _ = measurement
    }

    func manager(_ manager: CMWaterSubmersionManager, errorOccurred error: any Error) {
        _ = manager
        _ = error
        errors += 1
    }
}
