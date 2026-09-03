import Foundation

open class HKObjectType: NSObject, NSCopying, NSSecureCoding, @unchecked Sendable {
    public static var supportsSecureCoding: Bool { true }

    public let identifier: String

    public init(identifier: String) {
        self.identifier = identifier
        super.init()
    }

    public required init?(coder: NSCoder) {
        self.identifier = (coder.decodeObject(of: NSString.self, forKey: "identifier") as String?) ?? ""
        super.init()
    }

    public func encode(with coder: NSCoder) {
        coder.encode(identifier as NSString, forKey: "identifier")
    }

    public func copy(with zone: NSZone? = nil) -> Any {
        HKObjectType(identifier: identifier)
    }

    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? HKObjectType else { return false }
        return identifier == other.identifier && type(of: self) == type(of: other)
    }

    public override var hash: Int { identifier.hashValue }

    public func requiresPerObjectAuthorization() -> Bool {
        false
    }

    public class func quantityType(for identifier: HKQuantityTypeIdentifier) -> HKQuantityType? {
        HKQuantityType(identifier: identifier.rawValue)
    }

    public class func categoryType(for identifier: HKCategoryTypeIdentifier) -> HKCategoryType? {
        HKCategoryType(identifier: identifier.rawValue)
    }

    public class func characteristicType(for identifier: HKCharacteristicTypeIdentifier) -> HKCharacteristicType? {
        HKCharacteristicType(identifier: identifier.rawValue)
    }

    public class func correlationType(for identifier: HKCorrelationTypeIdentifier) -> HKCorrelationType? {
        HKCorrelationType(identifier: identifier.rawValue)
    }

    public class func documentType(for identifier: HKDocumentTypeIdentifier) -> HKDocumentType? {
        HKDocumentType(identifier: identifier.rawValue)
    }

    public class func workoutType() -> HKWorkoutType {
        HKWorkoutType(identifier: "HKWorkoutTypeIdentifier")
    }

    public class func activitySummaryType() -> HKActivitySummaryType {
        HKActivitySummaryType(identifier: "HKActivitySummaryTypeIdentifier")
    }

    public class func audiogramSampleType() -> HKAudiogramSampleType {
        HKAudiogramSampleType(identifier: "HKAudiogramTypeIdentifier")
    }

    public class func electrocardiogramType() -> HKElectrocardiogramType {
        HKElectrocardiogramType(identifier: "HKElectrocardiogramTypeIdentifier")
    }

    public class func seriesType(forIdentifier identifier: String) -> HKSeriesType? {
        HKSeriesType(identifier: identifier)
    }
}

open class HKSampleType: HKObjectType, @unchecked Sendable {
    public var allowsRecalibrationForEstimates: Bool { false }
    public var isMaximumDurationRestricted: Bool { false }
    public var isMinimumDurationRestricted: Bool { false }
    public var maximumAllowedDuration: TimeInterval { 0 }
    public var minimumAllowedDuration: TimeInterval { 0 }
}

open class HKQuantityType: HKSampleType, @unchecked Sendable {
    public var aggregationStyle: HKQuantityAggregationStyle {
        let cumulative: Set<String> = [
            HKQuantityTypeIdentifier.stepCount.rawValue,
            HKQuantityTypeIdentifier.distanceWalkingRunning.rawValue,
            HKQuantityTypeIdentifier.activeEnergyBurned.rawValue,
            HKQuantityTypeIdentifier.basalEnergyBurned.rawValue,
            HKQuantityTypeIdentifier.dietaryEnergyConsumed.rawValue,
            HKQuantityTypeIdentifier.appleExerciseTime.rawValue,
            HKQuantityTypeIdentifier.appleStandTime.rawValue,
            HKQuantityTypeIdentifier.flightsClimbed.rawValue,
        ]
        return cumulative.contains(identifier) ? .cumulative: .discreteArithmetic
    }

    public func `is`(compatibleWith unit: HKUnit) -> Bool {
        // Linux uses identifier-level compatibility only when a quantity is built.
        _ = unit
        return true
    }
}

open class HKCategoryType: HKSampleType, @unchecked Sendable {}
open class HKCharacteristicType: HKObjectType, @unchecked Sendable {}
open class HKCorrelationType: HKSampleType, @unchecked Sendable {}
open class HKDocumentType: HKSampleType, @unchecked Sendable {}
open class HKWorkoutType: HKSampleType, @unchecked Sendable {}
open class HKActivitySummaryType: HKObjectType, @unchecked Sendable {}
open class HKAudiogramSampleType: HKSampleType, @unchecked Sendable {}
open class HKElectrocardiogramType: HKSampleType, @unchecked Sendable {}
open class HKSeriesType: HKSampleType, @unchecked Sendable {}
open class HKClinicalType: HKSampleType, @unchecked Sendable {}
open class HKPrescriptionType: HKSampleType, @unchecked Sendable {}
open class HKScoredAssessmentType: HKSampleType, @unchecked Sendable {}
open class HKStateOfMindType: HKSampleType, @unchecked Sendable {}
open class HKMedicationDoseEventType: HKSampleType, @unchecked Sendable {}
open class HKUserAnnotatedMedicationType: HKObjectType, @unchecked Sendable {}
