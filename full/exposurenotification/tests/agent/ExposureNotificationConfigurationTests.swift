import Foundation
import ExposureNotification

func testENExposureConfigurationDefaults() {
    let config = ENExposureConfiguration()
    precondition(config.attenuationDurationThresholds.count == 2)
    precondition(config.attenuationDurationThresholds[0].intValue == 50)
    precondition(config.attenuationDurationThresholds[1].intValue == 70)
    precondition(config.daysSinceLastExposureThreshold == 0)
    precondition(config.minimumRiskScore == 0)
    precondition(config.minimumRiskScoreFullRange == 0)
    precondition(config.reportTypeNoneMap == .confirmedTest)
    precondition(config.metadata == nil)
    precondition(config.infectiousnessForDaysSinceOnsetOfSymptoms == nil)
}

func testENExposureConfigurationV1WeightsAndLevels() {
    let config = ENExposureConfiguration()
    precondition(config.attenuationWeight == Double(ENRiskWeightDefault))
    precondition(config.daysSinceLastExposureWeight == Double(ENRiskWeightDefault))
    precondition(config.durationWeight == Double(ENRiskWeightDefault))
    precondition(config.transmissionRiskWeight == Double(ENRiskWeightDefault))
    precondition(config.attenuationLevelValues.count == 8)
    precondition(config.daysSinceLastExposureLevelValues.count == 8)
    precondition(config.durationLevelValues.count == 8)
    precondition(config.transmissionRiskLevelValues.count == 8)
    for value in config.attenuationLevelValues {
        precondition(value.intValue == 1)
    }
}

func testENExposureConfigurationV2Weights() {
    let config = ENExposureConfiguration()
    let v2 = Double(ENRiskWeightDefaultV2)
    precondition(config.immediateDurationWeight == v2)
    precondition(config.nearDurationWeight == v2)
    precondition(config.mediumDurationWeight == v2)
    precondition(config.otherDurationWeight == v2)
    precondition(config.infectiousnessHighWeight == v2)
    precondition(config.infectiousnessStandardWeight == v2)
    precondition(config.reportTypeConfirmedClinicalDiagnosisWeight == v2)
    precondition(config.reportTypeConfirmedTestWeight == v2)
    precondition(config.reportTypeRecursiveWeight == v2)
    precondition(config.reportTypeSelfReportedWeight == v2)
}

func testENExposureConfigurationMutation() {
    let config = ENExposureConfiguration()
    config.attenuationDurationThresholds = [NSNumber(value: 40), NSNumber(value: 60)]
    config.attenuationWeight = 2.5
    config.daysSinceLastExposureThreshold = 10
    config.minimumRiskScore = 4
    config.minimumRiskScoreFullRange = 12.5
    config.reportTypeNoneMap = .selfReported
    config.immediateDurationWeight = 175
    precondition(config.attenuationDurationThresholds[0].intValue == 40)
    precondition(config.attenuationWeight == 2.5)
    precondition(config.daysSinceLastExposureThreshold == 10)
    precondition(config.minimumRiskScore == 4)
    precondition(config.minimumRiskScoreFullRange == 12.5)
    precondition(config.reportTypeNoneMap == .selfReported)
    precondition(config.immediateDurationWeight == 175)
}

func testENExposureConfigurationMetadataAndInfectiousnessMap() {
    let config = ENExposureConfiguration()
    config.metadata = ["region": "linux"]
    precondition(config.metadata?["region"] as? String == "linux")

    let unknown = NSNumber(value: ENDaysSinceOnsetOfSymptomsUnknown)
    config.infectiousnessForDaysSinceOnsetOfSymptoms = [
        NSNumber(value: 0): NSNumber(value: ENInfectiousness.standard.rawValue),
        unknown: NSNumber(value: ENInfectiousness.high.rawValue)
    ]
    precondition(config.infectiousnessForDaysSinceOnsetOfSymptoms?.count == 2)
    precondition(
        config.infectiousnessForDaysSinceOnsetOfSymptoms?[unknown]?.uint32Value
            == ENInfectiousness.high.rawValue
    )
}

func testENExposureConfigurationLevelValueMutation() {
    let config = ENExposureConfiguration()
    config.attenuationLevelValues = (1...8).map { NSNumber(value: $0) }
    config.daysSinceLastExposureLevelValues = [NSNumber(value: 0)]
    config.durationLevelValues = [NSNumber(value: 8), NSNumber(value: 8)]
    config.transmissionRiskLevelValues = [NSNumber(value: 7)]
    precondition(config.attenuationLevelValues.last?.intValue == 8)
    precondition(config.daysSinceLastExposureLevelValues.count == 1)
    precondition(config.durationLevelValues.count == 2)
    precondition(config.transmissionRiskLevelValues[0].intValue == 7)
}
