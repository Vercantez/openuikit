import Foundation

open class HKQueryAnchor: NSObject, NSCopying, NSSecureCoding, @unchecked Sendable {
    public static var supportsSecureCoding: Bool { true }
    public let value: Int

    public init(fromValue value: Int) {
        self.value = value
        super.init()
    }

    public required init?(coder: NSCoder) {
        self.value = 0
        super.init()
    }

    public func encode(with coder: NSCoder) {
        coder.encode(value, forKey: "value")
    }

    public func copy(with zone: NSZone? = nil) -> Any {
        HKQueryAnchor(fromValue: value)
    }
}

open class HKQueryDescriptor: NSObject, NSCopying, @unchecked Sendable {
    public let sampleType: HKSampleType
    public let predicate: NSPredicate?

    public init(sampleType: HKSampleType, predicate: NSPredicate?) {
        self.sampleType = sampleType
        self.predicate = predicate
        super.init()
    }

    public func copy(with zone: NSZone? = nil) -> Any {
        HKQueryDescriptor(sampleType: sampleType, predicate: predicate)
    }
}

open class HKQuery: NSObject, @unchecked Sendable {
    public private(set) var objectType: HKObjectType?
    public private(set) var sampleType: HKSampleType?
    public private(set) var predicate: NSPredicate?

    public init(objectType: HKObjectType?, predicate: NSPredicate?) {
        self.objectType = objectType
        self.sampleType = objectType as? HKSampleType
        self.predicate = predicate
        super.init()
    }

    public class func predicateForObjects(from source: HKSource) -> NSPredicate {
        NSPredicate(value: false)
    }

    public class func predicateForObjects(from sources: Set<HKSource>) -> NSPredicate {
        _ = sources
        return NSPredicate(value: false)
    }

    public class func predicateForObjects(from devices: Set<HKDevice>) -> NSPredicate {
        _ = devices
        return NSPredicate(value: false)
    }

    public class func predicateForObjects(with metadataKey: String) -> NSPredicate {
        _ = metadataKey
        return NSPredicate(value: false)
    }

    public class func predicateForObjects(with metadataKey: String, allowedValues: [Any]) -> NSPredicate {
        _ = metadataKey
        _ = allowedValues
        return NSPredicate(value: false)
    }

    public class func predicateForObjects(with UUIDs: Set<UUID>) -> NSPredicate {
        _ = UUIDs
        return NSPredicate(value: false)
    }

    public class func predicateForObjects(withNoUUIDs UUIDs: Set<UUID>) -> NSPredicate {
        _ = UUIDs
        return NSPredicate(value: false)
    }

    public class func predicateForObjectsWithDeviceProperty(_ key: String, allowedValues: Set<String>) -> NSPredicate {
        _ = key
        _ = allowedValues
        return NSPredicate(value: false)
    }

    public class func predicateForSamples(
        withStart startDate: Date?,
        end endDate: Date?,
        options: HKQueryOptions = []
    ) -> NSPredicate {
        _ = startDate
        _ = endDate
        _ = options
        return NSPredicate(value: false)
    }

    public class func predicateForObject(with UUID: UUID) -> NSPredicate {
        _ = UUID
        return NSPredicate(value: false)
    }

    public class func predicateForObjectsWithNoCorrelation() -> NSPredicate {
        NSPredicate(value: false)
    }

    public class func predicateForActivitySummary(with dateComponents: DateComponents) -> NSPredicate {
        _ = dateComponents
        return NSPredicate(value: false)
    }

    public class func predicateForElectrocardiograms(classification: HKElectrocardiogram.Classification) -> NSPredicate {
        _ = classification
        return NSPredicate(value: false)
    }

    public class func predicateForElectrocardiograms(symptomsStatus: HKElectrocardiogram.SymptomsStatus) -> NSPredicate {
        _ = symptomsStatus
        return NSPredicate(value: false)
    }

    public class func predicateForCategorySamplesEqualToValues(_ values: Set<NSNumber>) -> NSPredicate {
        _ = values
        return NSPredicate(value: false)
    }

    public class func predicateForWorkouts(with workoutActivityType: HKWorkoutActivityType) -> NSPredicate {
        _ = workoutActivityType
        return NSPredicate(value: false)
    }

    public class func predicateForWorkoutActivities(workoutActivityType: HKWorkoutActivityType) -> NSPredicate {
        _ = workoutActivityType
        return NSPredicate(value: false)
    }

    public class func predicateForWorkoutActivities(start startDate: Date?, end endDate: Date?, options: HKQueryOptions) -> NSPredicate {
        _ = startDate
        _ = endDate
        _ = options
        return NSPredicate(value: false)
    }

    public class func predicateForWorkouts(activityPredicate: NSPredicate) -> NSPredicate {
        _ = activityPredicate
        return NSPredicate(value: false)
    }

    public class func predicateForWorkouts(associatedWithAttempt uuid: UUID) -> NSPredicate {
        _ = uuid
        return NSPredicate(value: false)
    }

    public class func predicateForActivitySummaries(with dateComponents: DateComponents) -> NSPredicate {
        _ = dateComponents
        return NSPredicate(value: false)
    }

    public class func predicateForActivitySummaries(
        betweenStart startDateComponents: DateComponents,
        end endDateComponents: DateComponents
    ) -> NSPredicate {
        _ = startDateComponents
        _ = endDateComponents
        return NSPredicate(value: false)
    }

    public class func predicateForClinicalRecords(
        withFHIRResourceType resourceType: HKFHIRResourceType
    ) -> NSPredicate {
        _ = resourceType
        return NSPredicate(value: false)
    }

    public class func predicateForClinicalRecords(
        withFHIRResourceType resourceType: HKFHIRResourceType,
        sourceURL: URL,
        identifier: String
    ) -> NSPredicate {
        _ = resourceType
        _ = sourceURL
        _ = identifier
        return NSPredicate(value: false)
    }

    public class func predicateForObjectsAssociated(with electrocardiogram: HKElectrocardiogram) -> NSPredicate {
        _ = electrocardiogram
        return NSPredicate(value: false)
    }

    public class func predicateForObjectsFromWorkout(_ workout: HKWorkout) -> NSPredicate {
        _ = workout
        return NSPredicate(value: false)
    }
}

public typealias HKSampleQueryResultsHandler = (HKSampleQuery, [HKSample]?, (any Error)?) -> Void

open class HKSampleQuery: HKQuery, @unchecked Sendable {
    public let limit: Int
    public let sortDescriptors: [NSSortDescriptor]?
    private let resultsHandler: HKSampleQueryResultsHandler?

    public init(
        sampleType: HKSampleType,
        predicate: NSPredicate?,
        limit: Int,
        sortDescriptors: [NSSortDescriptor]?,
        resultsHandler: @escaping HKSampleQueryResultsHandler
    ) {
        self.limit = limit
        self.sortDescriptors = sortDescriptors
        self.resultsHandler = resultsHandler
        super.init(objectType: sampleType, predicate: predicate)
    }

    func deliverUnavailable() {
        resultsHandler?(self, nil, hkUnavailableError())
    }
}

open class HKStatisticsQuery: HKQuery, @unchecked Sendable {}
open class HKStatisticsCollectionQuery: HKQuery, @unchecked Sendable {}
open class HKObserverQuery: HKQuery, @unchecked Sendable {}
open class HKAnchoredObjectQuery: HKQuery, @unchecked Sendable {}
open class HKSourceQuery: HKQuery, @unchecked Sendable {}
open class HKCorrelationQuery: HKQuery, @unchecked Sendable {}
open class HKDocumentQuery: HKQuery, @unchecked Sendable {}
open class HKActivitySummaryQuery: HKQuery, @unchecked Sendable {}
open class HKHeartbeatSeriesQuery: HKQuery, @unchecked Sendable {}
open class HKQuantitySeriesSampleQuery: HKQuery, @unchecked Sendable {}
open class HKElectrocardiogramQuery: HKQuery, @unchecked Sendable {}
open class HKWorkoutRouteQuery: HKQuery, @unchecked Sendable {}
open class HKWorkoutEffortRelationshipQuery: HKQuery, @unchecked Sendable {}
open class HKUserAnnotatedMedicationQuery: HKQuery, @unchecked Sendable {}
open class HKVerifiableClinicalRecordQuery: HKQuery, @unchecked Sendable {}
