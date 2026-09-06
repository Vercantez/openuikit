import Foundation
import EnergyKit

func testInsightRecordType() {
    let record = ElectricityInsightRecord<Duration>(range: energyKitSampleInterval())
    energyKitExpectEqual(record.range, energyKitSampleInterval())
}

func testInsightRecordRange() {
    let interval = DateInterval(start: Date(timeIntervalSince1970: 10), duration: 60)
    energyKitExpectEqual(ElectricityInsightRecord<Duration>(range: interval).range, interval)
}

func testInsightRecordTotalEnergy() {
    var record = ElectricityInsightRecord<Measurement<UnitEnergy>>(range: energyKitSampleInterval())
    energyKitExpect(record.totalEnergy == nil)
    record.totalEnergy = Measurement(value: 4, unit: UnitEnergy.kilowattHours)
    energyKitExpectEqual(record.totalEnergy?.value, 4)
}

func testInsightRecordTotalRuntime() {
    var record = ElectricityInsightRecord<Duration>(range: energyKitSampleInterval())
    energyKitExpect(record.totalRuntime == nil)
    record.totalRuntime = Duration.seconds(90)
    energyKitExpectEqual(record.totalRuntime, Duration.seconds(90))
}

func testInsightRecordDataByGridCleanliness() {
    var record = ElectricityInsightRecord<Duration>(range: energyKitSampleInterval())
    energyKitExpect(record.dataByGridCleanliness == nil)
    record.dataByGridCleanliness = ElectricityInsightRecord<Duration>.GridCleanliness(
        cleaner: .seconds(1),
        lessClean: .seconds(2),
        avoid: .seconds(3),
        unknown: nil
    )
    energyKitExpectEqual(record.dataByGridCleanliness?.cleaner, Duration.seconds(1))
}

func testInsightRecordDataByTariffPeak() {
    var record = ElectricityInsightRecord<Duration>(range: energyKitSampleInterval())
    energyKitExpect(record.dataByTariffPeak == nil)
    record.dataByTariffPeak = ElectricityInsightRecord<Duration>.TariffPeak(
        superOffPeak: .seconds(1),
        offPeak: .seconds(2),
        partialPeak: nil,
        onPeak: .seconds(4),
        criticalPeak: nil,
        unknown: .seconds(6)
    )
    energyKitExpectEqual(record.dataByTariffPeak?.offPeak, Duration.seconds(2))
}

func testGridCleanlinessInit() {
    let bucket = ElectricityInsightRecord<Duration>.GridCleanliness(
        cleaner: .seconds(10),
        lessClean: nil,
        avoid: .seconds(30),
        unknown: .seconds(0)
    )
    energyKitExpectEqual(bucket.avoid, Duration.seconds(30))
}

func testGridCleanlinessCleaner() {
    var bucket = ElectricityInsightRecord<Duration>.GridCleanliness(
        cleaner: .seconds(1),
        lessClean: nil,
        avoid: nil,
        unknown: nil
    )
    bucket.cleaner = .seconds(8)
    energyKitExpectEqual(bucket.cleaner, Duration.seconds(8))
}

func testGridCleanlinessLessClean() {
    let bucket = ElectricityInsightRecord<Duration>.GridCleanliness(
        cleaner: nil,
        lessClean: .seconds(2),
        avoid: nil,
        unknown: nil
    )
    energyKitExpectEqual(bucket.lessClean, Duration.seconds(2))
}

func testGridCleanlinessAvoid() {
    let bucket = ElectricityInsightRecord<Duration>.GridCleanliness(
        cleaner: nil,
        lessClean: nil,
        avoid: .seconds(3),
        unknown: nil
    )
    energyKitExpectEqual(bucket.avoid, Duration.seconds(3))
}

func testGridCleanlinessUnknown() {
    let bucket = ElectricityInsightRecord<Duration>.GridCleanliness(
        cleaner: nil,
        lessClean: nil,
        avoid: nil,
        unknown: .seconds(4)
    )
    energyKitExpectEqual(bucket.unknown, Duration.seconds(0) + Duration.seconds(4))
}

func testTariffPeakInit() {
    let peak = ElectricityInsightRecord<Duration>.TariffPeak(
        superOffPeak: .seconds(1),
        offPeak: .seconds(2),
        partialPeak: .seconds(3),
        onPeak: .seconds(4),
        criticalPeak: .seconds(5),
        unknown: .seconds(6)
    )
    energyKitExpectEqual(peak.criticalPeak, Duration.seconds(5))
}

func testTariffPeakSuperOffPeak() {
    let peak = ElectricityInsightRecord<Duration>.TariffPeak(
        superOffPeak: .seconds(11),
        offPeak: nil,
        partialPeak: nil,
        onPeak: nil,
        criticalPeak: nil,
        unknown: nil
    )
    energyKitExpectEqual(peak.superOffPeak, Duration.seconds(11))
}

func testTariffPeakOffPeak() {
    let peak = ElectricityInsightRecord<Duration>.TariffPeak(
        superOffPeak: nil,
        offPeak: .seconds(12),
        partialPeak: nil,
        onPeak: nil,
        criticalPeak: nil,
        unknown: nil
    )
    energyKitExpectEqual(peak.offPeak, Duration.seconds(12))
}

func testTariffPeakPartialPeak() {
    let peak = ElectricityInsightRecord<Duration>.TariffPeak(
        superOffPeak: nil,
        offPeak: nil,
        partialPeak: .seconds(13),
        onPeak: nil,
        criticalPeak: nil,
        unknown: nil
    )
    energyKitExpectEqual(peak.partialPeak, Duration.seconds(13))
}

func testTariffPeakOnPeak() {
    let peak = ElectricityInsightRecord<Duration>.TariffPeak(
        superOffPeak: nil,
        offPeak: nil,
        partialPeak: nil,
        onPeak: .seconds(14),
        criticalPeak: nil,
        unknown: nil
    )
    energyKitExpectEqual(peak.onPeak, Duration.seconds(14))
}

func testTariffPeakCriticalPeak() {
    let peak = ElectricityInsightRecord<Duration>.TariffPeak(
        superOffPeak: nil,
        offPeak: nil,
        partialPeak: nil,
        onPeak: nil,
        criticalPeak: .seconds(15),
        unknown: nil
    )
    energyKitExpectEqual(peak.criticalPeak, Duration.seconds(15))
}

func testTariffPeakUnknown() {
    var peak = ElectricityInsightRecord<Duration>.TariffPeak(
        superOffPeak: nil,
        offPeak: nil,
        partialPeak: nil,
        onPeak: nil,
        criticalPeak: nil,
        unknown: .seconds(16)
    )
    peak.unknown = .seconds(17)
    energyKitExpectEqual(peak.unknown, Duration.seconds(17))
}

func testInsightMeasureDurationConformance() {
    let value: any ElectricityInsightMeasure = Duration.seconds(1)
    energyKitExpect(value is Duration)
}

func testInsightMeasureMeasurementConformance() {
    let value: any ElectricityInsightMeasure = Measurement(value: 1, unit: UnitEnergy.joules)
    energyKitExpect(value is Measurement<UnitEnergy>)
}

func testElectricalLoadEventProtocolHVAC() {
    let event: any ElectricalLoadEventProtocol = energyKitHVACEvent()
    energyKitExpect(event is ElectricHVACLoadEvent)
}

func testElectricalLoadEventProtocolVehicle() {
    let event: any ElectricalLoadEventProtocol = energyKitVehicleEvent()
    energyKitExpect(event is ElectricVehicleLoadEvent)
}
