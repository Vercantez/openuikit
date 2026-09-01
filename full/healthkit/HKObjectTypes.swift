import Foundation

/// Object-type identity. Linux constructs the public type graph locally;
/// nothing here talks to the Health store.
open class HKObjectType: NSObject, NSCopying {
    public let identifier: String

    init(identifier: String) {
        self.identifier = identifier
        super.init()
    }

    public convenience init?(coder: NSCoder) {
        return nil
    }

    public func copy(with zone: NSZone? = nil) -> Any {
        HKObjectType(identifier: identifier)
    }

    open func requiresPerObjectAuthorization() -> Bool { false }

    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? HKObjectType else { return false }
        return identifier == other.identifier && type(of: self) == type(of: other)
    }

    public override var hash: Int { identifier.hashValue }

    open class func quantityType(forIdentifier identifier: HKQuantityTypeIdentifier) -> HKQuantityType? {
        HKQuantityType(identifier)
    }

    open class func categoryType(forIdentifier identifier: HKCategoryTypeIdentifier) -> HKCategoryType? {
        HKCategoryType(identifier)
    }

    open class func characteristicType(forIdentifier identifier: HKCharacteristicTypeIdentifier) -> HKCharacteristicType? {
        HKCharacteristicType(identifier)
    }

    open class func correlationType(forIdentifier identifier: HKCorrelationTypeIdentifier) -> HKCorrelationType? {
        HKCorrelationType(identifier)
    }

    open class func documentType(forIdentifier identifier: HKDocumentTypeIdentifier) -> HKDocumentType? {
        HKDocumentType(identifier)
    }

    open class func clinicalType(forIdentifier identifier: HKClinicalTypeIdentifier) -> HKClinicalType? {
        HKClinicalType(identifier)
    }

    open class func workoutType() -> HKWorkoutType {
        HKWorkoutType(identifier: HKWorkoutTypeIdentifier)
    }

    open class func activitySummaryType() -> HKActivitySummaryType {
        HKActivitySummaryType(identifier: "HKActivitySummaryTypeIdentifier")
    }

    open class func audiogramSampleType() -> HKAudiogramSampleType {
        HKAudiogramSampleType(identifier: "HKAudiogramTypeIdentifierAudiogram")
    }

    open class func electrocardiogramType() -> HKElectrocardiogramType {
        HKElectrocardiogramType(identifier: "HKDataTypeIdentifierElectrocardiogram")
    }

    open class func seriesType(forIdentifier identifier: String) -> HKSeriesType? {
        switch identifier {
        case HKWorkoutRouteTypeIdentifier, HKSeriesType.workoutRoute().identifier:
            return HKSeriesType.workoutRoute()
        case HKDataTypeIdentifierHeartbeatSeries, HKSeriesType.heartbeat().identifier:
            return HKSeriesType.heartbeat()
        default:
            return HKSeriesType(identifier: identifier)
        }
    }

    open class func stateOfMindType() -> HKStateOfMindType {
        HKStateOfMindType(identifier: HKDataTypeIdentifierStateOfMind)
    }

    open class func medicationDoseEventType() -> HKMedicationDoseEventType {
        HKMedicationDoseEventType(identifier: HKMedicationDoseEventTypeIdentifierMedicationDoseEvent)
    }

    open class func userAnnotatedMedicationType() -> HKUserAnnotatedMedicationType {
        HKUserAnnotatedMedicationType(identifier: HKDataTypeIdentifierUserAnnotatedMedicationConcept)
    }

    open class func visionPrescriptionType() -> HKPrescriptionType {
        HKPrescriptionType(identifier: HKVisionPrescriptionTypeIdentifier)
    }
}

open class HKSampleType: HKObjectType {
    open var allowsRecalibrationForEstimates: Bool { false }
    open var isMaximumDurationRestricted: Bool { false }
    open var isMinimumDurationRestricted: Bool { false }
    open var maximumAllowedDuration: TimeInterval { 0 }
    open var minimumAllowedDuration: TimeInterval { 0 }
}

open class HKQuantityType: HKSampleType {
    public convenience init(_ identifier: HKQuantityTypeIdentifier) {
        self.init(identifier: identifier.rawValue)
    }

    open var aggregationStyle: HKQuantityAggregationStyle {
        HKQuantityType.cumulativeIdentifiers.contains(identifier) ? .cumulative : .discreteArithmetic
    }

    open func `is`(compatibleWith unit: HKUnit) -> Bool {
        guard let expected = HKQuantityType.expectedDimension(for: identifier) else {
            return true
        }
        return unit.dimension == expected
    }

    private static let cumulativeIdentifiers: Set<String> = [
        HKQuantityTypeIdentifier.stepCount.rawValue,
        HKQuantityTypeIdentifier.flightsClimbed.rawValue,
        HKQuantityTypeIdentifier.distanceWalkingRunning.rawValue,
        HKQuantityTypeIdentifier.distanceCycling.rawValue,
        HKQuantityTypeIdentifier.distanceSwimming.rawValue,
        HKQuantityTypeIdentifier.distanceWheelchair.rawValue,
        HKQuantityTypeIdentifier.distanceDownhillSnowSports.rawValue,
        HKQuantityTypeIdentifier.distanceCrossCountrySkiing.rawValue,
        HKQuantityTypeIdentifier.distancePaddleSports.rawValue,
        HKQuantityTypeIdentifier.distanceRowing.rawValue,
        HKQuantityTypeIdentifier.distanceSkatingSports.rawValue,
        HKQuantityTypeIdentifier.activeEnergyBurned.rawValue,
        HKQuantityTypeIdentifier.basalEnergyBurned.rawValue,
        HKQuantityTypeIdentifier.dietaryEnergyConsumed.rawValue,
        HKQuantityTypeIdentifier.appleExerciseTime.rawValue,
        HKQuantityTypeIdentifier.appleStandTime.rawValue,
        HKQuantityTypeIdentifier.appleMoveTime.rawValue,
        HKQuantityTypeIdentifier.swimmingStrokeCount.rawValue,
        HKQuantityTypeIdentifier.pushCount.rawValue,
        HKQuantityTypeIdentifier.nikeFuel.rawValue,
        HKQuantityTypeIdentifier.inhalerUsage.rawValue,
        HKQuantityTypeIdentifier.insulinDelivery.rawValue,
        HKQuantityTypeIdentifier.uvExposure.rawValue,
        HKQuantityTypeIdentifier.numberOfTimesFallen.rawValue,
        HKQuantityTypeIdentifier.numberOfAlcoholicBeverages.rawValue,
        HKQuantityTypeIdentifier.timeInDaylight.rawValue,
    ]

    private static func expectedDimension(for identifier: String) -> HKUnitDimension? {
        switch identifier {
        case HKQuantityTypeIdentifier.bodyMass.rawValue,
             HKQuantityTypeIdentifier.leanBodyMass.rawValue:
            return .mass
        case HKQuantityTypeIdentifier.height.rawValue,
             HKQuantityTypeIdentifier.waistCircumference.rawValue,
             HKQuantityTypeIdentifier.walkingStepLength.rawValue,
             HKQuantityTypeIdentifier.runningStrideLength.rawValue,
             HKQuantityTypeIdentifier.runningVerticalOscillation.rawValue:
            return .length
        case HKQuantityTypeIdentifier.stepCount.rawValue,
             HKQuantityTypeIdentifier.flightsClimbed.rawValue,
             HKQuantityTypeIdentifier.swimmingStrokeCount.rawValue,
             HKQuantityTypeIdentifier.pushCount.rawValue,
             HKQuantityTypeIdentifier.numberOfTimesFallen.rawValue,
             HKQuantityTypeIdentifier.numberOfAlcoholicBeverages.rawValue,
             HKQuantityTypeIdentifier.inhalerUsage.rawValue:
            return .count
        case HKQuantityTypeIdentifier.heartRate.rawValue,
             HKQuantityTypeIdentifier.restingHeartRate.rawValue,
             HKQuantityTypeIdentifier.walkingHeartRateAverage.rawValue,
             HKQuantityTypeIdentifier.respiratoryRate.rawValue:
            return HKUnitDimension.frequency
        default:
            return nil
        }
    }
}

open class HKCategoryType: HKSampleType {
    public convenience init(_ identifier: HKCategoryTypeIdentifier) {
        self.init(identifier: identifier.rawValue)
    }
}

open class HKCharacteristicType: HKObjectType {
    public convenience init(_ identifier: HKCharacteristicTypeIdentifier) {
        self.init(identifier: identifier.rawValue)
    }
}

open class HKCorrelationType: HKSampleType {
    public convenience init(_ identifier: HKCorrelationTypeIdentifier) {
        self.init(identifier: identifier.rawValue)
    }
}

open class HKDocumentType: HKSampleType {
    public convenience init(_ identifier: HKDocumentTypeIdentifier) {
        self.init(identifier: identifier.rawValue)
    }
}

open class HKWorkoutType: HKSampleType {}

open class HKSeriesType: HKSampleType {
    open class func heartbeat() -> Self {
        unsafeDowncast(HKSeriesType(identifier: HKDataTypeIdentifierHeartbeatSeries), to: Self.self)
    }

    open class func workoutRoute() -> Self {
        unsafeDowncast(HKSeriesType(identifier: HKWorkoutRouteTypeIdentifier), to: Self.self)
    }
}

open class HKActivitySummaryType: HKObjectType {}
open class HKAudiogramSampleType: HKSampleType {}
open class HKElectrocardiogramType: HKSampleType {}
open class HKClinicalType: HKSampleType {
    public convenience init(_ identifier: HKClinicalTypeIdentifier) {
        self.init(identifier: identifier.rawValue)
    }
}
open class HKPrescriptionType: HKSampleType {}
open class HKScoredAssessmentType: HKSampleType {
    public convenience init(_ identifier: HKScoredAssessmentTypeIdentifier) {
        self.init(identifier: identifier.rawValue)
    }
}
open class HKStateOfMindType: HKSampleType {}
open class HKMedicationDoseEventType: HKSampleType {}
open class HKUserAnnotatedMedicationType: HKSampleType {}
