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

    public class func quantityType(forIdentifier identifier: HKQuantityTypeIdentifier) -> HKQuantityType? {
        HKQuantityType(identifier: identifier.rawValue)
    }

    public class func quantityType(for identifier: HKQuantityTypeIdentifier) -> HKQuantityType? {
        quantityType(forIdentifier: identifier)
    }

    public class func categoryType(forIdentifier identifier: HKCategoryTypeIdentifier) -> HKCategoryType? {
        HKCategoryType(identifier: identifier.rawValue)
    }

    public class func categoryType(for identifier: HKCategoryTypeIdentifier) -> HKCategoryType? {
        categoryType(forIdentifier: identifier)
    }

    public class func characteristicType(forIdentifier identifier: HKCharacteristicTypeIdentifier) -> HKCharacteristicType? {
        HKCharacteristicType(identifier: identifier.rawValue)
    }

    public class func characteristicType(for identifier: HKCharacteristicTypeIdentifier) -> HKCharacteristicType? {
        characteristicType(forIdentifier: identifier)
    }

    public class func correlationType(forIdentifier identifier: HKCorrelationTypeIdentifier) -> HKCorrelationType? {
        HKCorrelationType(identifier: identifier.rawValue)
    }

    public class func correlationType(for identifier: HKCorrelationTypeIdentifier) -> HKCorrelationType? {
        correlationType(forIdentifier: identifier)
    }

    public class func documentType(forIdentifier identifier: HKDocumentTypeIdentifier) -> HKDocumentType? {
        HKDocumentType(identifier: identifier.rawValue)
    }

    public class func documentType(for identifier: HKDocumentTypeIdentifier) -> HKDocumentType? {
        documentType(forIdentifier: identifier)
    }

    public class func clinicalType(forIdentifier identifier: HKClinicalTypeIdentifier) -> HKClinicalType? {
        HKClinicalType(identifier: identifier.rawValue)
    }

    public class func workoutType() -> HKWorkoutType {
        HKWorkoutType(identifier: HKWorkoutTypeIdentifier)
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

    public class func medicationDoseEventType() -> HKMedicationDoseEventType {
        HKMedicationDoseEventType(identifier: HKMedicationDoseEventTypeIdentifierMedicationDoseEvent)
    }

    public class func stateOfMindType() -> HKStateOfMindType {
        HKStateOfMindType(identifier: HKDataTypeIdentifierStateOfMind)
    }

    public class func userAnnotatedMedicationType() -> HKUserAnnotatedMedicationType {
        HKUserAnnotatedMedicationType(identifier: HKDataTypeIdentifierUserAnnotatedMedicationConcept)
    }

    public class func visionPrescriptionType() -> HKPrescriptionType {
        HKPrescriptionType(identifier: HKVisionPrescriptionTypeIdentifier)
    }
}

open class HKSampleType: HKObjectType, @unchecked Sendable {
    /// Apple documents a seven-day cap for most quantity/category/document samples.
    public static let hkMaximumSampleDuration: TimeInterval = 7 * 24 * 60 * 60

    public var allowsRecalibrationForEstimates: Bool {
        let tokens = ["Walking", "Running", "Stair", "CardioFitness", "VO2", "Estimated", "Steadiness"]
        return tokens.contains(where: { identifier.contains($0) })
    }

    /// Workouts, series, and correlations are not duration-capped on this Linux host.
    public var isMaximumDurationRestricted: Bool {
        if self is HKWorkoutType { return false }
        if self is HKSeriesType { return false }
        if self is HKCorrelationType { return false }
        return true
    }

    public var isMinimumDurationRestricted: Bool { false }

    public var maximumAllowedDuration: TimeInterval {
        isMaximumDurationRestricted ? Self.hkMaximumSampleDuration : 0
    }

    public var minimumAllowedDuration: TimeInterval { 0 }
}

open class HKQuantityType: HKSampleType, @unchecked Sendable {
    public convenience init(_ identifier: HKQuantityTypeIdentifier) {
        self.init(identifier: identifier.rawValue)
    }

    public var canonicalUnit: HKUnit { HKQuantityTypeCatalog.canonicalUnit(for: identifier) }

    public var aggregationStyle: HKQuantityAggregationStyle {
        HKQuantityTypeCatalog.aggregationStyle(for: identifier)
    }

    public func `is`(compatibleWith unit: HKUnit) -> Bool {
        canonicalUnit.`is`(compatibleWith: unit)
    }
}

open class HKCategoryType: HKSampleType, @unchecked Sendable {
    public convenience init(_ identifier: HKCategoryTypeIdentifier) {
        self.init(identifier: identifier.rawValue)
    }
}

open class HKCharacteristicType: HKObjectType, @unchecked Sendable {}
open class HKCorrelationType: HKSampleType, @unchecked Sendable {
    public convenience init(_ identifier: HKCorrelationTypeIdentifier) {
        self.init(identifier: identifier.rawValue)
    }
}
open class HKDocumentType: HKSampleType, @unchecked Sendable {}
open class HKWorkoutType: HKSampleType, @unchecked Sendable {}
open class HKActivitySummaryType: HKObjectType, @unchecked Sendable {}
open class HKAudiogramSampleType: HKSampleType, @unchecked Sendable {}
open class HKElectrocardiogramType: HKSampleType, @unchecked Sendable {}
open class HKSeriesType: HKSampleType, @unchecked Sendable {
    public class func heartbeat() -> HKSeriesType {
        HKSeriesType(identifier: HKDataTypeIdentifierHeartbeatSeries)
    }

    public class func workoutRoute() -> HKSeriesType {
        HKSeriesType(identifier: HKWorkoutRouteTypeIdentifier)
    }
}
open class HKClinicalType: HKSampleType, @unchecked Sendable {
    public convenience init(_ identifier: HKClinicalTypeIdentifier) {
        self.init(identifier: identifier.rawValue)
    }
}
open class HKPrescriptionType: HKSampleType, @unchecked Sendable {}
open class HKScoredAssessmentType: HKSampleType, @unchecked Sendable {}
open class HKStateOfMindType: HKSampleType, @unchecked Sendable {}
open class HKMedicationDoseEventType: HKSampleType, @unchecked Sendable {}
open class HKUserAnnotatedMedicationType: HKObjectType, @unchecked Sendable {}

enum HKQuantityTypeCatalog {
    static func aggregationStyle(for identifier: String) -> HKQuantityAggregationStyle {
        if identifier.contains("AudioExposure") {
            return .discreteEquivalentContinuousLevel
        }
        let cumulativeTokens = [
            "StepCount", "PushCount", "FlightsClimbed", "StrokeCount",
            "EnergyBurned", "EnergyConsumed", "Distance", "Dietary",
            "ExerciseTime", "StandTime", "MoveTime", "TimeInDaylight",
            "NikeFuel", "TimesFallen", "InhalerUsage", "InsulinDelivery",
            "UVExposure", "AlcoholicBeverages"
        ]
        if cumulativeTokens.contains(where: { identifier.contains($0) }) {
            return .cumulative
        }
        return .discreteArithmetic
    }

    static func canonicalUnit(for identifier: String) -> HKUnit {
        if identifier.contains("HeartRate") || identifier.contains("RespiratoryRate") {
            return HKUnit.count().unitDivided(by: HKUnit.minute())
        }
        if identifier.contains("Energy") {
            return .kilocalorie()
        }
        if identifier.contains("Distance") || identifier.contains("Height")
            || identifier.contains("Length") || identifier.contains("Circumference")
            || identifier.contains("Depth") || identifier.contains("Oscillation") {
            return .meter()
        }
        if identifier.contains("Time") || identifier.contains("Duration") {
            return .second()
        }
        if identifier.contains("Mass") || identifier.contains("Weight") {
            return .gramUnit(with: .kilo)
        }
        if identifier.contains("Temperature") {
            return .degreeCelsius()
        }
        if identifier.contains("Pressure") || identifier.contains("BloodPressure") {
            return .millimeterOfMercury()
        }
        if identifier.contains("Power") {
            return .watt()
        }
        if identifier.contains("Speed") || identifier.contains("Cadence") {
            return HKUnit.meter().unitDivided(by: HKUnit.second())
        }
        if identifier.contains("Percent") || identifier.contains("Saturation")
            || identifier.contains("Steadiness") || identifier.contains("Burden")
            || identifier.contains("FatPercentage") || identifier.contains("WalkingAsymmetry")
            || identifier.contains("DoubleSupport") {
            return .percent()
        }
        if identifier.contains("Glucose") {
            return HKUnit.gramUnit(with: .milli).unitDivided(by: HKUnit.literUnit(with: .deci))
        }
        if identifier.contains("VO2Max") {
            return HKUnit.literUnit(with: .milli).unitDivided(by: HKUnit.gramUnit(with: .kilo).unitMultiplied(by: HKUnit.minute()))
        }
        if identifier.contains("Volume") || identifier.contains("Water")
            || identifier.contains("VitalCapacity") || identifier.contains("Expiratory") {
            return .liter()
        }
        if identifier.contains("Count") || identifier.contains("Fuel") {
            return .count()
        }
        return .count()
    }
}
