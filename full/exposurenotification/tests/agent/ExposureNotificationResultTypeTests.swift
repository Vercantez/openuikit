import Foundation
import ExposureNotification

func testENTemporaryExposureKeyStorage() {
    let key = ENTemporaryExposureKey()
    precondition(key.keyData.isEmpty)
    precondition(key.rollingPeriod == 144)
    precondition(key.rollingStartNumber == 0)
    precondition(key.transmissionRiskLevel == 0)

    let payload = Data([0xAA, 0xBB, 0xCC, 0xDD])
    key.keyData = payload
    key.rollingPeriod = 144
    key.rollingStartNumber = 12345
    key.transmissionRiskLevel = 5
    precondition(key.keyData == payload)
    precondition(key.rollingPeriod == 144)
    precondition(key.rollingStartNumber == 12345)
    precondition(key.transmissionRiskLevel == 5)
}

func testENScanInstanceProperties() {
    let empty = ENScanInstance()
    precondition(empty.minimumAttenuation == 0)
    precondition(empty.typicalAttenuation == 0)
    precondition(empty.secondsSinceLastScan == 0)

    let scan = ENScanInstance(
        minimumAttenuation: 40,
        typicalAttenuation: 55,
        secondsSinceLastScan: 240
    )
    precondition(scan.minimumAttenuation == 40)
    precondition(scan.typicalAttenuation == 55)
    precondition(scan.secondsSinceLastScan == 240)
}

func testENExposureWindowProperties() {
    let empty = ENExposureWindow()
    precondition(empty.calibrationConfidence == .lowest)
    precondition(empty.date.timeIntervalSince1970 == 0)
    precondition(empty.diagnosisReportType == .unknown)
    precondition(empty.infectiousness == .none)
    precondition(empty.scanInstances.isEmpty)
    precondition(empty.variantOfConcernType == .typeUnknown)

    let date = Date(timeIntervalSince1970: 1_600_000_000)
    let scan = ENScanInstance(
        minimumAttenuation: 30,
        typicalAttenuation: 45,
        secondsSinceLastScan: 180
    )
    let window = ENExposureWindow(
        calibrationConfidence: .high,
        date: date,
        diagnosisReportType: .confirmedTest,
        infectiousness: .high,
        scanInstances: [scan],
        variantOfConcernType: .type1
    )
    precondition(window.calibrationConfidence == .high)
    precondition(window.date == date)
    precondition(window.diagnosisReportType == .confirmedTest)
    precondition(window.infectiousness == .high)
    precondition(window.scanInstances.count == 1)
    precondition(window.scanInstances[0].typicalAttenuation == 45)
    precondition(window.variantOfConcernType == .type1)
}

func testENExposureInfoProperties() {
    let empty = ENExposureInfo()
    precondition(empty.attenuationDurations.isEmpty)
    precondition(empty.attenuationValue == 0)
    precondition(empty.date.timeIntervalSince1970 == 0)
    precondition(empty.daysSinceOnsetOfSymptoms == ENDaysSinceOnsetOfSymptomsUnknown)
    precondition(empty.diagnosisReportType == .unknown)
    precondition(empty.duration == 0)
    precondition(empty.metadata == nil)
    precondition(empty.totalRiskScore == 0)
    precondition(empty.totalRiskScoreFullRange == 0)
    precondition(empty.transmissionRiskLevel == 0)

    let date = Date(timeIntervalSince1970: 50)
    let info = ENExposureInfo(
        attenuationDurations: [NSNumber(value: 300), NSNumber(value: 120)],
        attenuationValue: 60,
        date: date,
        daysSinceOnsetOfSymptoms: 2,
        diagnosisReportType: .confirmedClinicalDiagnosis,
        duration: 900,
        metadata: ["source": "host"],
        totalRiskScore: 7,
        totalRiskScoreFullRange: 42.5,
        transmissionRiskLevel: 4
    )
    precondition(info.attenuationDurations.count == 2)
    precondition(info.attenuationValue == 60)
    precondition(info.date == date)
    precondition(info.daysSinceOnsetOfSymptoms == 2)
    precondition(info.diagnosisReportType == .confirmedClinicalDiagnosis)
    precondition(info.duration == 900)
    precondition(info.metadata?["source"] as? String == "host")
    precondition(info.totalRiskScore == 7)
    precondition(info.totalRiskScoreFullRange == 42.5)
    precondition(info.transmissionRiskLevel == 4)
}

func testENExposureSummaryItemProperties() {
    let empty = ENExposureSummaryItem()
    precondition(empty.maximumScore == 0)
    precondition(empty.scoreSum == 0)
    precondition(empty.weightedDurationSum == 0)

    let item = ENExposureSummaryItem(maximumScore: 8.5, scoreSum: 21, weightedDurationSum: 600)
    precondition(item.maximumScore == 8.5)
    precondition(item.scoreSum == 21)
    precondition(item.weightedDurationSum == 600)
}

func testENExposureDaySummaryProperties() {
    let empty = ENExposureDaySummary()
    precondition(empty.confirmedClinicalDiagnosisSummary == nil)
    precondition(empty.confirmedTestSummary == nil)
    precondition(empty.date.timeIntervalSince1970 == 0)
    precondition(empty.daySummary.maximumScore == 0)
    precondition(empty.recursiveSummary == nil)
    precondition(empty.selfReportedSummary == nil)

    let date = Date(timeIntervalSince1970: 99)
    let day = ENExposureSummaryItem(maximumScore: 3, scoreSum: 4, weightedDurationSum: 30)
    let confirmed = ENExposureSummaryItem(maximumScore: 5, scoreSum: 6, weightedDurationSum: 90)
    let clinical = ENExposureSummaryItem(maximumScore: 1, scoreSum: 1, weightedDurationSum: 10)
    let recursive = ENExposureSummaryItem(maximumScore: 2, scoreSum: 2, weightedDurationSum: 20)
    let selfReported = ENExposureSummaryItem(maximumScore: 0, scoreSum: 0, weightedDurationSum: 5)
    let summary = ENExposureDaySummary(
        date: date,
        daySummary: day,
        confirmedTestSummary: confirmed,
        confirmedClinicalDiagnosisSummary: clinical,
        recursiveSummary: recursive,
        selfReportedSummary: selfReported
    )
    precondition(summary.date == date)
    precondition(summary.daySummary.scoreSum == 4)
    precondition(summary.confirmedTestSummary?.maximumScore == 5)
    precondition(summary.confirmedClinicalDiagnosisSummary?.weightedDurationSum == 10)
    precondition(summary.recursiveSummary?.scoreSum == 2)
    precondition(summary.selfReportedSummary?.weightedDurationSum == 5)
}

func testENExposureDetectionSummaryProperties() {
    let empty = ENExposureDetectionSummary()
    precondition(empty.attenuationDurations.isEmpty)
    precondition(empty.daySummaries.isEmpty)
    precondition(empty.daysSinceLastExposure == 0)
    precondition(empty.matchedKeyCount == 0)
    precondition(empty.maximumRiskScore == 0)
    precondition(empty.maximumRiskScoreFullRange == 0)
    precondition(empty.metadata == nil)
    precondition(empty.riskScoreSumFullRange == 0)

    let day = ENExposureDaySummary()
    let summary = ENExposureDetectionSummary(
        attenuationDurations: [NSNumber(value: 100), NSNumber(value: 200), NSNumber(value: 0)],
        daySummaries: [day],
        daysSinceLastExposure: 3,
        matchedKeyCount: 2,
        maximumRiskScore: 8,
        maximumRiskScoreFullRange: 64,
        metadata: ["matched": true],
        riskScoreSumFullRange: 80
    )
    precondition(summary.attenuationDurations.count == 3)
    precondition(summary.daySummaries.count == 1)
    precondition(summary.daysSinceLastExposure == 3)
    precondition(summary.matchedKeyCount == 2)
    precondition(summary.maximumRiskScore == 8)
    precondition(summary.maximumRiskScoreFullRange == 64)
    precondition(summary.metadata?["matched"] as? Bool == true)
    precondition(summary.riskScoreSumFullRange == 80)
}
