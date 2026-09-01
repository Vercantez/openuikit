import Foundation

open class HKActivitySummary: NSObject {
    public var dateComponents: DateComponents = DateComponents()
    public var activeEnergyBurned: HKQuantity?
    public var appleExerciseTime: HKQuantity?
    public var appleStandHours: HKQuantity?
    public override init() { super.init() }
    public convenience init?(coder: NSCoder) { nil }
}

open class HKScoredAssessment: HKSample {}

open class HKGAD7Assessment: HKScoredAssessment {
    public enum Answer: Int, Sendable, Hashable {
        case notAtAll = 0
        case severalDays = 1
        case moreThanHalfTheDays = 2
        case nearlyEveryDay = 3
    }

    public enum Risk: Int, Sendable, Hashable {
        case noneToMinimal = 0
        case mild = 1
        case moderate = 2
        case severe = 3
    }
}

open class HKPHQ9Assessment: HKScoredAssessment {
    public enum Answer: Int, Sendable, Hashable {
        case notAtAll = 0
        case severalDays = 1
        case moreThanHalfTheDays = 2
        case nearlyEveryDay = 3
        case preferNotToAnswer = 4
    }

    public enum Risk: Int, Sendable, Hashable {
        case noneToMinimal = 0
        case mild = 1
        case moderate = 2
        case moderatelySevere = 3
        case severe = 4
    }
}

open class HKElectrocardiogram: HKSample {
    public enum Classification: Int, Sendable, Hashable {
        case notSet = 0
        case sinusRhythm = 1
        case atrialFibrillation = 2
        case inconclusiveLowHeartRate = 3
        case inconclusiveHighHeartRate = 4
        case inconclusivePoorReading = 5
        case inconclusiveOther = 6
        case unrecognized = 7
    }

    public enum Lead: Int, Sendable, Hashable {
        case appleWatchSimilarToLeadI = 1
    }

    public enum SymptomsStatus: Int, Sendable, Hashable {
        case notSet = 0
        case none = 1
        case present = 2
    }

    open class VoltageMeasurement: NSObject {
        public let timeOffset: TimeInterval
        public func quantity(for lead: HKElectrocardiogram.Lead) -> HKQuantity? { nil }

        init(timeOffset: TimeInterval) {
            self.timeOffset = timeOffset
            super.init()
        }
    }
}

open class HKStateOfMind: HKSample {
    public enum Kind: Int, Sendable, Hashable {
        case momentaryEmotion = 1
        case dailyMood = 2
    }

    public enum ValenceClassification: Int, Sendable, Hashable {
        case veryUnpleasant = 1
        case unpleasant = 2
        case slightlyUnpleasant = 3
        case neutral = 4
        case slightlyPleasant = 5
        case pleasant = 6
        case veryPleasant = 7
    }

    public enum Label: Int, Sendable, Hashable {
        case amazed = 1
        case amused = 2
        case angry = 3
        case annoyed = 4
        case anxious = 5
        case ashamed = 6
        case brave = 7
        case calm = 8
        case confident = 9
        case content = 10
        case disappointed = 11
        case discouraged = 12
        case disgusted = 13
        case drained = 14
        case embarrassed = 15
        case excited = 16
        case frustrated = 17
        case grateful = 18
        case guilty = 19
        case happy = 20
        case hopeful = 21
        case hopeless = 22
        case indifferent = 23
        case irritated = 24
        case jealous = 25
        case joyful = 26
        case lonely = 27
        case overwhelmed = 28
        case passionate = 29
        case peaceful = 30
        case proud = 31
        case relieved = 32
        case sad = 33
        case satisfied = 34
        case scared = 35
        case stressed = 36
        case surprised = 37
        case worried = 38
    }

    public enum Association: Int, Sendable, Hashable {
        case community = 1
        case currentEvents = 2
        case dating = 3
        case education = 4
        case family = 5
        case fitness = 6
        case friends = 7
        case health = 8
        case hobbies = 9
        case identity = 10
        case money = 11
        case partner = 12
        case selfCare = 13
        case spirituality = 14
        case tasks = 15
        case travel = 16
        case weather = 17
        case work = 18
    }
}

open class HKMedicationDoseEvent: HKSample {
    public enum LogStatus: Int, Sendable, Hashable {
        case notInteracted = 0
        case notificationNotSent = 1
        case snoozed = 2
        case skipped = 3
        case taken = 4
        case notLogged = 5
    }

    public enum ScheduleType: Int, Sendable, Hashable {
        case asNeeded = 0
        case schedule = 1
    }
}

open class HKSeriesSample: HKSample {}
open class HKHeartbeatSeriesSample: HKSeriesSample {}
open class HKWorkoutRoute: HKSeriesSample {}
open class HKCumulativeQuantitySample: HKQuantitySample {}
open class HKDiscreteQuantitySample: HKQuantitySample {}
open class HKCumulativeQuantitySeriesSample: HKCumulativeQuantitySample {}
open class HKDocumentSample: HKSample {}
open class HKCDADocumentSample: HKDocumentSample {}
open class HKAudiogramSample: HKSample {}
open class HKClinicalRecord: HKSample {}
open class HKVerifiableClinicalRecord: HKSample {}
open class HKVisionPrescription: HKSample {}
open class HKContactsPrescription: HKVisionPrescription {}
open class HKGlassesPrescription: HKVisionPrescription {}

open class HKAttachment: NSObject {}
open class HKAttachmentStore: NSObject {}
open class HKAttachmentDataReader: NSObject {}
open class HKAudiogramSensitivityPoint: NSObject {}
open class HKAudiogramSensitivityPointClampingRange: NSObject {}
open class HKAudiogramSensitivityTest: NSObject {}
open class HKCDADocument: NSObject {}
open class HKClinicalCoding: NSObject {}
open class HKLensSpecification: NSObject {}
open class HKContactsLensSpecification: HKLensSpecification {}
open class HKGlassesLensSpecification: HKLensSpecification {}
open class HKFHIRResource: NSObject {}
open class HKFHIRVersion: NSObject {}
open class HKHealthConceptIdentifier: NSObject {}
open class HKMedicationConcept: NSObject {}
open class HKUserAnnotatedMedication: NSObject {}
open class HKVerifiableClinicalRecordSubject: NSObject {}
open class HKVisionPrism: NSObject {}
open class HKWorkoutEffortRelationship: NSObject {}
open class HKStatisticsCollection: NSObject {}

open class HKSeriesBuilder: NSObject {}
open class HKHeartbeatSeriesBuilder: HKSeriesBuilder {}
open class HKQuantitySeriesSampleBuilder: NSObject {}
open class HKWorkoutBuilder: NSObject {}
open class HKLiveWorkoutBuilder: HKWorkoutBuilder {}
open class HKLiveWorkoutDataSource: NSObject {}
open class HKWorkoutRouteBuilder: NSObject {}

open class HKHeartbeatSeriesQuery: HKQuery {}
open class HKQuantitySeriesSampleQuery: HKQuery {}
open class HKStatisticsCollectionQuery: HKQuery {}
open class HKDocumentQuery: HKQuery {}
open class HKElectrocardiogramQuery: HKQuery {
    public enum Result {
        case measurement(HKElectrocardiogram.VoltageMeasurement)
        case done
        case error(any Error)
    }
}
open class HKVerifiableClinicalRecordQuery: HKQuery {}
open class HKUserAnnotatedMedicationQuery: HKQuery {}
open class HKWorkoutEffortRelationshipQuery: HKQuery {}
open class HKWorkoutRouteQuery: HKQuery {}

/// Watch / session hardware is unavailable on Linux. The type exists so
/// clients can compile; starting a session is not supported.
open class HKWorkoutSession: NSObject {
    public weak var delegate: HKWorkoutSessionDelegate?
    public var state: HKWorkoutSessionState { .notStarted }
    public var workoutConfiguration: HKWorkoutConfiguration

    public init(healthStore: HKHealthStore, configuration: HKWorkoutConfiguration) throws {
        self.workoutConfiguration = configuration
        super.init()
        throw hkUnavailableError("Workout sessions require Apple Watch / HealthKit hardware.")
    }
}

public protocol HKWorkoutSessionDelegate: NSObjectProtocol {
    func workoutSession(
        _ workoutSession: HKWorkoutSession,
        didChangeTo toState: HKWorkoutSessionState,
        from fromState: HKWorkoutSessionState,
        date: Date
    )
    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: any Error)
}

public protocol HKLiveWorkoutBuilderDelegate: NSObjectProtocol {}
public protocol HKAsyncQuery {}
public protocol HKAsyncSequenceQuery {}
public protocol HKCategoryValuePredicateProviding: Hashable, RawRepresentable {}
