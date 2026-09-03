import Foundation

// MARK: - Declared type shells
// These types exist so the module compiles a recognizable HealthKit identity.
// Methods that would talk to Apple services, Health records, Watch, or
// CoreLocation stay unimplemented; coverage lists those IDs as deferred.

open class HKActivitySummary: NSObject, NSCopying, NSSecureCoding, @unchecked Sendable {
    public static var supportsSecureCoding: Bool { true }
    public var dateComponents: DateComponents = DateComponents()
    public var activeEnergyBurned: HKQuantity?
    public var appleExerciseTime: HKQuantity?
    public var appleStandHours: HKQuantity?
    public override init() { super.init() }
    public required init?(coder: NSCoder) { super.init() }
    public func encode(with coder: NSCoder) {}
    public func copy(with zone: NSZone? = nil) -> Any { HKActivitySummary() }
}

open class HKAttachment: NSObject, @unchecked Sendable {}
open class HKAttachmentStore: NSObject, @unchecked Sendable {}
open class HKAttachmentDataReader: NSObject, @unchecked Sendable {}
open class HKAudiogramSample: HKSample, @unchecked Sendable {
    public required init?(coder: NSCoder) { super.init(coder: coder) }
}
open class HKAudiogramSensitivityPoint: NSObject, @unchecked Sendable {}
open class HKAudiogramSensitivityPointClampingRange: NSObject, @unchecked Sendable {}
open class HKAudiogramSensitivityTest: NSObject, @unchecked Sendable {}
open class HKCDADocument: NSObject, @unchecked Sendable {}
open class HKCDADocumentSample: HKDocumentSample, @unchecked Sendable {
    public required init?(coder: NSCoder) { super.init(coder: coder) }
}
open class HKClinicalCoding: NSObject, @unchecked Sendable {}
open class HKClinicalRecord: HKSample, @unchecked Sendable {
    public required init?(coder: NSCoder) { super.init(coder: coder) }
}
open class HKContactsLensSpecification: NSObject, @unchecked Sendable {}
open class HKContactsPrescription: NSObject, @unchecked Sendable {}
open class HKElectrocardiogram: HKSeriesSample, @unchecked Sendable {
    public required init?(coder: NSCoder) { super.init(coder: coder) }
}
open class HKFHIRResource: NSObject, @unchecked Sendable {}
open class HKFHIRVersion: NSObject, @unchecked Sendable {}
open class HKGAD7Assessment: HKSample, @unchecked Sendable {
    public required init?(coder: NSCoder) { super.init(coder: coder) }
}
open class HKGlassesLensSpecification: NSObject, @unchecked Sendable {}
open class HKGlassesPrescription: NSObject, @unchecked Sendable {}
open class HKHealthConceptIdentifier: NSObject, @unchecked Sendable {}
open class HKHeartbeatSeriesBuilder: NSObject, @unchecked Sendable {}
open class HKHeartbeatSeriesSample: HKSeriesSample, @unchecked Sendable {
    public required init?(coder: NSCoder) { super.init(coder: coder) }
}
open class HKLensSpecification: NSObject, @unchecked Sendable {}
open class HKLiveWorkoutBuilder: NSObject, @unchecked Sendable {}
open class HKLiveWorkoutDataSource: NSObject, @unchecked Sendable {}
open class HKMedicationConcept: NSObject, @unchecked Sendable {}
open class HKMedicationDoseEvent: HKSample, @unchecked Sendable {
    public required init?(coder: NSCoder) { super.init(coder: coder) }
}
open class HKPHQ9Assessment: HKSample, @unchecked Sendable {
    public required init?(coder: NSCoder) { super.init(coder: coder) }
}
open class HKQuantitySeriesSampleBuilder: NSObject, @unchecked Sendable {}
open class HKScoredAssessment: HKSample, @unchecked Sendable {
    public required init?(coder: NSCoder) { super.init(coder: coder) }
}
open class HKSeriesBuilder: NSObject, @unchecked Sendable {}
open class HKStateOfMind: HKSample, @unchecked Sendable {
    public required init?(coder: NSCoder) { super.init(coder: coder) }
}
open class HKStatistics: NSObject, @unchecked Sendable {}
open class HKStatisticsCollection: NSObject, @unchecked Sendable {}
open class HKUserAnnotatedMedication: NSObject, @unchecked Sendable {}
open class HKVerifiableClinicalRecord: HKSample, @unchecked Sendable {
    public required init?(coder: NSCoder) { super.init(coder: coder) }
}
open class HKVerifiableClinicalRecordSubject: NSObject, @unchecked Sendable {}
open class HKVisionPrescription: HKSample, @unchecked Sendable {
    public required init?(coder: NSCoder) { super.init(coder: coder) }
}
open class HKVisionPrism: NSObject, @unchecked Sendable {}
open class HKWorkoutBuilder: NSObject, @unchecked Sendable {}
open class HKWorkoutRoute: HKSeriesSample, @unchecked Sendable {
    public required init?(coder: NSCoder) { super.init(coder: coder) }
}
open class HKWorkoutRouteBuilder: NSObject, @unchecked Sendable {}
open class HKWorkoutSession: NSObject, @unchecked Sendable {}
open class HKWorkoutEffortRelationship: NSObject, @unchecked Sendable {}

public protocol HKLiveWorkoutBuilderDelegate: AnyObject {}
public protocol HKWorkoutSessionDelegate: AnyObject {}
public protocol HKAsyncQuery {}
public protocol HKAsyncSequenceQuery {}
public protocol HKCategoryValuePredicateProviding: Hashable, RawRepresentable {}

public struct HKSamplePredicate<Sample> where Sample: HKSample {}
public struct HKSampleQueryDescriptor<Sample> where Sample: HKSample {}
public struct HKSourceQueryDescriptor<Sample> where Sample: HKSample {}
public struct HKStatisticsQueryDescriptor {}
public struct HKWorkoutRouteQueryDescriptor {
    public struct Results {
        public struct Iterator {}
    }
}
public struct HKAnchoredObjectQueryDescriptor<Sample> where Sample: HKSample {
    public struct Result {}
    public struct Results {
        public struct Iterator {}
    }
}
public struct HKActivitySummaryQueryDescriptor {
    public struct Results {
        public struct Iterator {}
    }
}
public struct HKHeartbeatSeriesQueryDescriptor {
    public struct Results {
        public struct Iterator {}
    }
    public struct Heartbeat {}
}
public struct HKElectrocardiogramQueryDescriptor {
    public struct Results {
        public struct Iterator {}
    }
}
public struct HKQuantitySeriesSampleQueryDescriptor {
    public struct Result {}
    public struct Options: OptionSet, Sendable {
        public let rawValue: UInt
        public init(rawValue: UInt) { self.rawValue = rawValue }
    }
    public struct Results {
        public struct Iterator {}
    }
}
public struct HKStatisticsCollectionQueryDescriptor {
    public struct Result {}
    public struct Results {
        public struct Iterator {}
    }
}
public struct HKUserAnnotatedMedicationQueryDescriptor {}
public struct HKVerifiableClinicalRecordQueryDescriptor {}
public struct HKWorkoutEffortRelationshipQueryDescriptor {
    public struct Result {}
    public struct Results {
        public struct Iterator {}
    }
}
public struct BufferedAsyncByteIterator {}

extension HKElectrocardiogram {
    public class VoltageMeasurement: NSObject {}
}

extension HKAttachment {
    public struct AsyncBytes {}
}
