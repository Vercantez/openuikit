import Foundation

// MARK: - Temporary exposure key

/// Diagnosis key used to generate rolling proximity identifiers.
///
/// `rollingPeriod` defaults to 144 (24 hours of 10-minute intervals), the
/// documented EN interval period. Linux never mints real TEKs; callers may
/// store fields locally.
public class ENTemporaryExposureKey: NSObject {
    public var keyData: Data
    public var rollingPeriod: ENIntervalNumber
    public var rollingStartNumber: ENIntervalNumber
    public var transmissionRiskLevel: ENRiskLevel

    public override init() {
        self.keyData = Data()
        self.rollingPeriod = 144
        self.rollingStartNumber = 0
        self.transmissionRiskLevel = 0
        super.init()
    }
}

// MARK: - Scan / window / info result objects
//
// Apple's framework constructs these from detection results. Linux never
// produces detections; empty constructed objects use documented unknown/zero
// defaults. Extra host initializers exist so tests can store-and-read
// values without inventing a detection success path.

public class ENScanInstance: NSObject {
    public private(set) var minimumAttenuation: ENAttenuation
    public private(set) var typicalAttenuation: ENAttenuation
    public private(set) var secondsSinceLastScan: Int

    public override init() {
        self.minimumAttenuation = 0
        self.typicalAttenuation = 0
        self.secondsSinceLastScan = 0
        super.init()
    }

    public init(
        minimumAttenuation: ENAttenuation,
        typicalAttenuation: ENAttenuation,
        secondsSinceLastScan: Int
    ) {
        self.minimumAttenuation = minimumAttenuation
        self.typicalAttenuation = typicalAttenuation
        self.secondsSinceLastScan = secondsSinceLastScan
        super.init()
    }
}

public class ENExposureWindow: NSObject {
    public private(set) var calibrationConfidence: ENCalibrationConfidence
    public private(set) var date: Date
    public private(set) var diagnosisReportType: ENDiagnosisReportType
    public private(set) var infectiousness: ENInfectiousness
    public private(set) var scanInstances: [ENScanInstance]
    public private(set) var variantOfConcernType: ENVariantOfConcernType

    public override init() {
        self.calibrationConfidence = .lowest
        self.date = Date(timeIntervalSince1970: 0)
        self.diagnosisReportType = .unknown
        self.infectiousness = .none
        self.scanInstances = []
        self.variantOfConcernType = .typeUnknown
        super.init()
    }

    public init(
        calibrationConfidence: ENCalibrationConfidence,
        date: Date,
        diagnosisReportType: ENDiagnosisReportType,
        infectiousness: ENInfectiousness,
        scanInstances: [ENScanInstance],
        variantOfConcernType: ENVariantOfConcernType
    ) {
        self.calibrationConfidence = calibrationConfidence
        self.date = date
        self.diagnosisReportType = diagnosisReportType
        self.infectiousness = infectiousness
        self.scanInstances = scanInstances
        self.variantOfConcernType = variantOfConcernType
        super.init()
    }
}

public class ENExposureInfo: NSObject {
    public private(set) var attenuationDurations: [NSNumber]
    public private(set) var attenuationValue: ENAttenuation
    public private(set) var date: Date
    public private(set) var daysSinceOnsetOfSymptoms: Int
    public private(set) var diagnosisReportType: ENDiagnosisReportType
    public private(set) var duration: TimeInterval
    public private(set) var metadata: [AnyHashable: Any]?
    public private(set) var totalRiskScore: ENRiskScore
    public private(set) var totalRiskScoreFullRange: Double
    public private(set) var transmissionRiskLevel: ENRiskLevel

    public override init() {
        self.attenuationDurations = []
        self.attenuationValue = 0
        self.date = Date(timeIntervalSince1970: 0)
        self.daysSinceOnsetOfSymptoms = ENDaysSinceOnsetOfSymptomsUnknown
        self.diagnosisReportType = .unknown
        self.duration = 0
        self.metadata = nil
        self.totalRiskScore = 0
        self.totalRiskScoreFullRange = 0
        self.transmissionRiskLevel = 0
        super.init()
    }

    public init(
        attenuationDurations: [NSNumber],
        attenuationValue: ENAttenuation,
        date: Date,
        daysSinceOnsetOfSymptoms: Int,
        diagnosisReportType: ENDiagnosisReportType,
        duration: TimeInterval,
        metadata: [AnyHashable: Any]?,
        totalRiskScore: ENRiskScore,
        totalRiskScoreFullRange: Double,
        transmissionRiskLevel: ENRiskLevel
    ) {
        self.attenuationDurations = attenuationDurations
        self.attenuationValue = attenuationValue
        self.date = date
        self.daysSinceOnsetOfSymptoms = daysSinceOnsetOfSymptoms
        self.diagnosisReportType = diagnosisReportType
        self.duration = duration
        self.metadata = metadata
        self.totalRiskScore = totalRiskScore
        self.totalRiskScoreFullRange = totalRiskScoreFullRange
        self.transmissionRiskLevel = transmissionRiskLevel
        super.init()
    }
}

public class ENExposureSummaryItem: NSObject {
    public private(set) var maximumScore: Double
    public private(set) var scoreSum: Double
    public private(set) var weightedDurationSum: TimeInterval

    public override init() {
        self.maximumScore = 0
        self.scoreSum = 0
        self.weightedDurationSum = 0
        super.init()
    }

    public init(maximumScore: Double, scoreSum: Double, weightedDurationSum: TimeInterval) {
        self.maximumScore = maximumScore
        self.scoreSum = scoreSum
        self.weightedDurationSum = weightedDurationSum
        super.init()
    }
}

public class ENExposureDaySummary: NSObject {
    public private(set) var confirmedClinicalDiagnosisSummary: ENExposureSummaryItem?
    public private(set) var confirmedTestSummary: ENExposureSummaryItem?
    public private(set) var date: Date
    public private(set) var daySummary: ENExposureSummaryItem
    public private(set) var recursiveSummary: ENExposureSummaryItem?
    public private(set) var selfReportedSummary: ENExposureSummaryItem?

    public override init() {
        self.confirmedClinicalDiagnosisSummary = nil
        self.confirmedTestSummary = nil
        self.date = Date(timeIntervalSince1970: 0)
        self.daySummary = ENExposureSummaryItem()
        self.recursiveSummary = nil
        self.selfReportedSummary = nil
        super.init()
    }

    public init(
        date: Date,
        daySummary: ENExposureSummaryItem,
        confirmedTestSummary: ENExposureSummaryItem? = nil,
        confirmedClinicalDiagnosisSummary: ENExposureSummaryItem? = nil,
        recursiveSummary: ENExposureSummaryItem? = nil,
        selfReportedSummary: ENExposureSummaryItem? = nil
    ) {
        self.date = date
        self.daySummary = daySummary
        self.confirmedTestSummary = confirmedTestSummary
        self.confirmedClinicalDiagnosisSummary = confirmedClinicalDiagnosisSummary
        self.recursiveSummary = recursiveSummary
        self.selfReportedSummary = selfReportedSummary
        super.init()
    }
}

public class ENExposureDetectionSummary: NSObject {
    public private(set) var attenuationDurations: [NSNumber]
    public private(set) var daySummaries: [ENExposureDaySummary]
    public private(set) var daysSinceLastExposure: Int
    public private(set) var matchedKeyCount: UInt64
    public private(set) var maximumRiskScore: ENRiskScore
    public private(set) var maximumRiskScoreFullRange: Double
    public private(set) var metadata: [AnyHashable: Any]?
    public private(set) var riskScoreSumFullRange: Double

    public override init() {
        self.attenuationDurations = []
        self.daySummaries = []
        self.daysSinceLastExposure = 0
        self.matchedKeyCount = 0
        self.maximumRiskScore = 0
        self.maximumRiskScoreFullRange = 0
        self.metadata = nil
        self.riskScoreSumFullRange = 0
        super.init()
    }

    public init(
        attenuationDurations: [NSNumber],
        daySummaries: [ENExposureDaySummary],
        daysSinceLastExposure: Int,
        matchedKeyCount: UInt64,
        maximumRiskScore: ENRiskScore,
        maximumRiskScoreFullRange: Double,
        metadata: [AnyHashable: Any]?,
        riskScoreSumFullRange: Double
    ) {
        self.attenuationDurations = attenuationDurations
        self.daySummaries = daySummaries
        self.daysSinceLastExposure = daysSinceLastExposure
        self.matchedKeyCount = matchedKeyCount
        self.maximumRiskScore = maximumRiskScore
        self.maximumRiskScoreFullRange = maximumRiskScoreFullRange
        self.metadata = metadata
        self.riskScoreSumFullRange = riskScoreSumFullRange
        super.init()
    }
}

// MARK: - Exposure configuration

/// Configuration parameters for exposure detection.
///
/// Get/set storage is real. V1 level-value arrays default to eight `1`s
/// (Apple's documented empty-array substitute). V1 weights default to
/// `ENRiskWeightDefault`; V2 duration/infectiousness/report-type weights
/// default to `ENRiskWeightDefaultV2`. `attenuationDurationThresholds`
/// defaults to `[50, 70]` as documented for the two-bucket V1 thresholds.
/// Linux never runs detection against these values.
public class ENExposureConfiguration: NSObject {
    private static let defaultLevelValues: [NSNumber] = (0..<8).map { _ in NSNumber(value: 1) }

    public var attenuationDurationThresholds: [NSNumber]
    public var attenuationLevelValues: [NSNumber]
    public var attenuationWeight: Double
    public var daysSinceLastExposureLevelValues: [NSNumber]
    public var daysSinceLastExposureThreshold: Int
    public var daysSinceLastExposureWeight: Double
    public var durationLevelValues: [NSNumber]
    public var durationWeight: Double
    public var immediateDurationWeight: Double
    public var infectiousnessForDaysSinceOnsetOfSymptoms: [NSNumber: NSNumber]?
    public var infectiousnessHighWeight: Double
    public var infectiousnessStandardWeight: Double
    public var mediumDurationWeight: Double
    public var metadata: [AnyHashable: Any]?
    public var minimumRiskScore: ENRiskScore
    public var minimumRiskScoreFullRange: Double
    public var nearDurationWeight: Double
    public var otherDurationWeight: Double
    public var reportTypeConfirmedClinicalDiagnosisWeight: Double
    public var reportTypeConfirmedTestWeight: Double
    public var reportTypeNoneMap: ENDiagnosisReportType
    public var reportTypeRecursiveWeight: Double
    public var reportTypeSelfReportedWeight: Double
    public var transmissionRiskLevelValues: [NSNumber]
    public var transmissionRiskWeight: Double

    public override init() {
        let v1 = Double(ENRiskWeightDefault)
        let v2 = Double(ENRiskWeightDefaultV2)
        self.attenuationDurationThresholds = [NSNumber(value: 50), NSNumber(value: 70)]
        self.attenuationLevelValues = Self.defaultLevelValues
        self.attenuationWeight = v1
        self.daysSinceLastExposureLevelValues = Self.defaultLevelValues
        self.daysSinceLastExposureThreshold = 0
        self.daysSinceLastExposureWeight = v1
        self.durationLevelValues = Self.defaultLevelValues
        self.durationWeight = v1
        self.immediateDurationWeight = v2
        self.infectiousnessForDaysSinceOnsetOfSymptoms = nil
        self.infectiousnessHighWeight = v2
        self.infectiousnessStandardWeight = v2
        self.mediumDurationWeight = v2
        self.metadata = nil
        self.minimumRiskScore = 0
        self.minimumRiskScoreFullRange = 0
        self.nearDurationWeight = v2
        self.otherDurationWeight = v2
        self.reportTypeConfirmedClinicalDiagnosisWeight = v2
        self.reportTypeConfirmedTestWeight = v2
        self.reportTypeNoneMap = .confirmedTest
        self.reportTypeRecursiveWeight = v2
        self.reportTypeSelfReportedWeight = v2
        self.transmissionRiskLevelValues = Self.defaultLevelValues
        self.transmissionRiskWeight = v1
        super.init()
    }
}
