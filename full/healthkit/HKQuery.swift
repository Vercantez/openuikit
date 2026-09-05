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

public var HKAnchoredObjectQueryNoAnchor: Int32 { 0 }

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
        NSPredicate { object, _ in
            (object as? HKObject)?.sourceRevision.source.bundleIdentifier == source.bundleIdentifier
        }
    }

    public class func predicateForObjects(from sources: Set<HKSource>) -> NSPredicate {
        let ids = Set(sources.map(\.bundleIdentifier))
        return NSPredicate { object, _ in
            guard let object = object as? HKObject else { return false }
            return ids.contains(object.sourceRevision.source.bundleIdentifier)
        }
    }

    public class func predicateForObjects(from sourceRevisions: Set<HKSourceRevision>) -> NSPredicate {
        let keys = Set(sourceRevisions.map { "\($0.source.bundleIdentifier)|\($0.version ?? "")" })
        return NSPredicate { object, _ in
            guard let object = object as? HKObject else { return false }
            let key = "\(object.sourceRevision.source.bundleIdentifier)|\(object.sourceRevision.version ?? "")"
            return keys.contains(key)
        }
    }

    public class func predicateForObjects(from devices: Set<HKDevice>) -> NSPredicate {
        let names = Set(devices.compactMap(\.name))
        return NSPredicate { object, _ in
            guard let name = (object as? HKObject)?.device?.name else { return names.isEmpty }
            return names.contains(name)
        }
    }

    public class func predicateForObjects(from workout: HKWorkout) -> NSPredicate {
        NSPredicate { object, _ in
            guard let object = object as? HKObject else { return false }
            return HKHealthStorePortable.sampleIDs(forWorkout: workout.uuid).contains(object.uuid)
        }
    }

    public class func predicateForObjectsFromWorkout(_ workout: HKWorkout) -> NSPredicate {
        predicateForObjects(from: workout)
    }

    public class func predicateForObjects(withMetadataKey key: String) -> NSPredicate {
        NSPredicate { object, _ in
            (object as? HKObject)?.metadata?[key] != nil
        }
    }

    public class func predicateForObjects(with metadataKey: String) -> NSPredicate {
        predicateForObjects(withMetadataKey: metadataKey)
    }

    public class func predicateForObjects(withMetadataKey key: String, allowedValues: [Any]) -> NSPredicate {
        let strings = allowedValues.map { String(describing: $0) }
        return NSPredicate { object, _ in
            guard let value = (object as? HKObject)?.metadata?[key] else { return false }
            return strings.contains(String(describing: value))
        }
    }

    public class func predicateForObjects(with metadataKey: String, allowedValues: [Any]) -> NSPredicate {
        predicateForObjects(withMetadataKey: metadataKey, allowedValues: allowedValues)
    }

    public class func predicateForObjects(withMetadataKey key: String, operatorType: HKPredicateOperator, value: Any) -> NSPredicate {
        NSPredicate { object, _ in
            guard let stored = (object as? HKObject)?.metadata?[key] else { return false }
            if let lhs = (stored as? NSNumber)?.doubleValue, let rhs = (value as? NSNumber)?.doubleValue {
                return hkCompare(lhs, operatorType, rhs)
            }
            return operatorType == .equalTo && String(describing: stored) == String(describing: value)
        }
    }

    public class func predicateForObjects(with UUIDs: Set<UUID>) -> NSPredicate {
        NSPredicate { object, _ in
            guard let object = object as? HKObject else { return false }
            return UUIDs.contains(object.uuid)
        }
    }

    public class func predicateForObjects(withNoUUIDs UUIDs: Set<UUID>) -> NSPredicate {
        NSPredicate { object, _ in
            guard let object = object as? HKObject else { return false }
            return !UUIDs.contains(object.uuid)
        }
    }

    public class func predicateForObjectsWithDeviceProperty(_ key: String, allowedValues: Set<String>) -> NSPredicate {
        predicateForObjects(withDeviceProperty: key, allowedValues: allowedValues)
    }

    public class func predicateForObjects(withDeviceProperty key: String, allowedValues: Set<String>) -> NSPredicate {
        NSPredicate { object, _ in
            guard let device = (object as? HKObject)?.device else { return false }
            let value: String?
            switch key {
            case HKDevicePropertyKeyName: value = device.name
            case HKDevicePropertyKeyManufacturer: value = device.manufacturer
            case HKDevicePropertyKeyModel: value = device.model
            case HKDevicePropertyKeyHardwareVersion: value = device.hardwareVersion
            case HKDevicePropertyKeyFirmwareVersion: value = device.firmwareVersion
            case HKDevicePropertyKeySoftwareVersion: value = device.softwareVersion
            case HKDevicePropertyKeyLocalIdentifier: value = device.localIdentifier
            case HKDevicePropertyKeyUDIDeviceIdentifier: value = device.udiDeviceIdentifier
            default: value = nil
            }
            guard let value else { return false }
            return allowedValues.contains(value)
        }
    }

    public class func predicateForSamples(
        withStart startDate: Date?,
        end endDate: Date?,
        options: HKQueryOptions = []
    ) -> NSPredicate {
        NSPredicate { object, _ in
            guard let sample = object as? HKSample else { return false }
            if let startDate {
                if options.contains(.strictStartDate) {
                    if sample.startDate < startDate { return false }
                } else if sample.endDate < startDate {
                    return false
                }
            }
            if let endDate {
                if options.contains(.strictEndDate) {
                    if sample.endDate > endDate { return false }
                } else if sample.startDate > endDate {
                    return false
                }
            }
            return true
        }
    }

    public class func predicateForObject(with UUID: UUID) -> NSPredicate {
        predicateForObjects(with: [UUID])
    }

    public class func predicateForObjectsWithNoCorrelation() -> NSPredicate {
        NSPredicate { object, _ in
            (object as? HKCorrelation) == nil
        }
    }

    public class func predicateForActivitySummary(with dateComponents: DateComponents) -> NSPredicate {
        NSPredicate { object, _ in
            guard let summary = object as? HKActivitySummary else { return false }
            return hkDateComponentsMatch(summary.dateComponents, dateComponents)
        }
    }

    public class func predicateForActivitySummaries(with dateComponents: DateComponents) -> NSPredicate {
        predicateForActivitySummary(with: dateComponents)
    }

    public class func predicate(forActivitySummariesBetweenStart startDateComponents: DateComponents, end endDateComponents: DateComponents) -> NSPredicate {
        predicateForActivitySummaries(betweenStart: startDateComponents, end: endDateComponents)
    }

    public class func predicateForActivitySummaries(
        betweenStart startDateComponents: DateComponents,
        end endDateComponents: DateComponents
    ) -> NSPredicate {
        NSPredicate { object, _ in
            guard let summary = object as? HKActivitySummary else { return false }
            let start = summary.dateComponents
            func ordinal(_ c: DateComponents) -> Int {
                (c.year ?? 0) * 400 + (c.month ?? 0) * 32 + (c.day ?? 0)
            }
            let value = ordinal(start)
            return value >= ordinal(startDateComponents) && value <= ordinal(endDateComponents)
        }
    }

    public class func predicateForElectrocardiograms(classification: HKElectrocardiogram.Classification) -> NSPredicate {
        NSPredicate { object, _ in
            (object as? HKElectrocardiogram)?.classification == classification
        }
    }

    public class func predicateForElectrocardiograms(symptomsStatus: HKElectrocardiogram.SymptomsStatus) -> NSPredicate {
        NSPredicate { object, _ in
            (object as? HKElectrocardiogram)?.symptomsStatus == symptomsStatus
        }
    }

    public class func predicateForCategorySamplesEqualToValues(_ values: Set<NSNumber>) -> NSPredicate {
        let ints = Set(values.map(\.intValue))
        return NSPredicate { object, _ in
            guard let sample = object as? HKCategorySample else { return false }
            return ints.contains(sample.value)
        }
    }

    public class func predicateForCategorySamples(with operatorType: HKPredicateOperator, value: Int) -> NSPredicate {
        NSPredicate { object, _ in
            guard let sample = object as? HKCategorySample else { return false }
            return hkCompare(Double(sample.value), operatorType, Double(value))
        }
    }

    public class func predicateForQuantitySamples(with operatorType: HKPredicateOperator, quantity: HKQuantity) -> NSPredicate {
        NSPredicate { object, _ in
            guard let sample = object as? HKQuantitySample,
                  sample.quantity.`is`(compatibleWith: quantity.unit)
            else { return false }
            return hkCompare(
                sample.quantity.doubleValue(for: quantity.unit),
                operatorType,
                quantity.doubleValue
            )
        }
    }

    public class func predicateForWorkouts(with workoutActivityType: HKWorkoutActivityType) -> NSPredicate {
        NSPredicate { object, _ in
            (object as? HKWorkout)?.workoutActivityType == workoutActivityType
        }
    }

    public class func predicateForWorkouts(activityPredicate: NSPredicate) -> NSPredicate {
        NSPredicate { object, _ in
            guard let workout = object as? HKWorkout else { return false }
            return workout.workoutActivities.contains { activityPredicate.evaluate(with: $0) }
        }
    }

    public class func predicateForWorkouts(associatedWithAttempt uuid: UUID) -> NSPredicate {
        _ = uuid
        return NSPredicate(value: false)
    }

    public class func predicateForWorkouts(with operatorType: HKPredicateOperator, duration: TimeInterval) -> NSPredicate {
        NSPredicate { object, _ in
            guard let workout = object as? HKWorkout else { return false }
            return hkCompare(workout.duration, operatorType, duration)
        }
    }

    public class func predicateForWorkouts(with operatorType: HKPredicateOperator, totalDistance: HKQuantity) -> NSPredicate {
        NSPredicate { object, _ in
            guard let workout = object as? HKWorkout, let qty = workout.totalDistance,
                  qty.`is`(compatibleWith: totalDistance.unit)
            else { return false }
            return hkCompare(qty.doubleValue(for: totalDistance.unit), operatorType, totalDistance.doubleValue)
        }
    }

    public class func predicateForWorkouts(with operatorType: HKPredicateOperator, totalEnergyBurned: HKQuantity) -> NSPredicate {
        NSPredicate { object, _ in
            guard let workout = object as? HKWorkout, let qty = workout.totalEnergyBurned,
                  qty.`is`(compatibleWith: totalEnergyBurned.unit)
            else { return false }
            return hkCompare(qty.doubleValue(for: totalEnergyBurned.unit), operatorType, totalEnergyBurned.doubleValue)
        }
    }

    public class func predicateForWorkouts(with operatorType: HKPredicateOperator, totalFlightsClimbed: HKQuantity) -> NSPredicate {
        NSPredicate { object, _ in
            guard let workout = object as? HKWorkout, let qty = workout.totalFlightsClimbed,
                  qty.`is`(compatibleWith: totalFlightsClimbed.unit)
            else { return false }
            return hkCompare(qty.doubleValue(for: totalFlightsClimbed.unit), operatorType, totalFlightsClimbed.doubleValue)
        }
    }

    public class func predicateForWorkouts(with operatorType: HKPredicateOperator, totalSwimmingStrokeCount: HKQuantity) -> NSPredicate {
        NSPredicate { object, _ in
            guard let workout = object as? HKWorkout, let qty = workout.totalSwimmingStrokeCount,
                  qty.`is`(compatibleWith: totalSwimmingStrokeCount.unit)
            else { return false }
            return hkCompare(qty.doubleValue(for: totalSwimmingStrokeCount.unit), operatorType, totalSwimmingStrokeCount.doubleValue)
        }
    }

    public class func predicateForWorkouts(
        operatorType: HKPredicateOperator,
        quantityType: HKQuantityType,
        averageQuantity: HKQuantity
    ) -> NSPredicate {
        _ = quantityType
        return predicateForWorkouts(with: operatorType, totalEnergyBurned: averageQuantity)
    }

    public class func predicateForWorkouts(
        operatorType: HKPredicateOperator,
        quantityType: HKQuantityType,
        maximumQuantity: HKQuantity
    ) -> NSPredicate {
        _ = quantityType
        return predicateForWorkouts(with: operatorType, totalEnergyBurned: maximumQuantity)
    }

    public class func predicateForWorkouts(
        operatorType: HKPredicateOperator,
        quantityType: HKQuantityType,
        minimumQuantity: HKQuantity
    ) -> NSPredicate {
        _ = quantityType
        return predicateForWorkouts(with: operatorType, totalEnergyBurned: minimumQuantity)
    }

    public class func predicateForWorkouts(
        operatorType: HKPredicateOperator,
        quantityType: HKQuantityType,
        sumQuantity: HKQuantity
    ) -> NSPredicate {
        _ = quantityType
        return predicateForWorkouts(with: operatorType, totalEnergyBurned: sumQuantity)
    }

    public class func predicateForWorkoutActivities(workoutActivityType: HKWorkoutActivityType) -> NSPredicate {
        NSPredicate { object, _ in
            (object as? HKWorkoutActivity)?.workoutConfiguration.activityType == workoutActivityType
                || (object as? HKWorkout)?.workoutActivities.contains { $0.workoutConfiguration.activityType == workoutActivityType } == true
        }
    }

    public class func predicateForWorkoutActivities(start startDate: Date?, end endDate: Date?, options: HKQueryOptions = []) -> NSPredicate {
        NSPredicate { object, _ in
            let interval: (Date, Date?)
            if let activity = object as? HKWorkoutActivity {
                interval = (activity.startDate, activity.endDate)
            } else if let workout = object as? HKWorkout {
                interval = (workout.startDate, workout.endDate)
            } else {
                return false
            }
            if let startDate, interval.0 < startDate { return false }
            if let endDate, let end = interval.1, end > endDate, options.contains(.strictEndDate) { return false }
            _ = options
            return true
        }
    }

    public class func predicateForWorkoutActivities(operatorType: HKPredicateOperator, duration: TimeInterval) -> NSPredicate {
        NSPredicate { object, _ in
            guard let activity = object as? HKWorkoutActivity else { return false }
            let durationValue = (activity.endDate ?? activity.startDate).timeIntervalSince(activity.startDate)
            return hkCompare(durationValue, operatorType, duration)
        }
    }

    public class func predicateForWorkoutActivities(
        operatorType: HKPredicateOperator,
        quantityType: HKQuantityType,
        averageQuantity: HKQuantity
    ) -> NSPredicate {
        _ = quantityType
        _ = averageQuantity
        _ = operatorType
        return NSPredicate(value: true)
    }

    public class func predicateForWorkoutActivities(
        operatorType: HKPredicateOperator,
        quantityType: HKQuantityType,
        maximumQuantity: HKQuantity
    ) -> NSPredicate {
        _ = (operatorType, quantityType, maximumQuantity)
        return NSPredicate(value: true)
    }

    public class func predicateForWorkoutActivities(
        operatorType: HKPredicateOperator,
        quantityType: HKQuantityType,
        minimumQuantity: HKQuantity
    ) -> NSPredicate {
        _ = (operatorType, quantityType, minimumQuantity)
        return NSPredicate(value: true)
    }

    public class func predicateForWorkoutActivities(
        operatorType: HKPredicateOperator,
        quantityType: HKQuantityType,
        sumQuantity: HKQuantity
    ) -> NSPredicate {
        _ = (operatorType, quantityType, sumQuantity)
        return NSPredicate(value: true)
    }

    public class func predicateForWorkoutEffortSamplesRelated(workout: HKWorkout, activity: HKWorkoutActivity?) -> NSPredicate {
        _ = activity
        return predicateForObjects(from: workout)
    }

    public class func predicateForClinicalRecords(withFHIRResourceType resourceType: HKFHIRResourceType) -> NSPredicate {
        NSPredicate { object, _ in
            (object as? HKClinicalRecord)?.fhirResourceType == resourceType
        }
    }

    public class func predicateForClinicalRecords(
        withFHIRResourceType resourceType: HKFHIRResourceType,
        sourceURL: URL,
        identifier: String
    ) -> NSPredicate {
        NSPredicate { object, _ in
            guard let record = object as? HKClinicalRecord else { return false }
            return record.fhirResourceType == resourceType
                && record.fhirSourceURL == sourceURL
                && record.fhirIdentifier == identifier
        }
    }

    public class func predicateForClinicalRecords(
        from source: HKSource,
        fhirResourceType resourceType: HKFHIRResourceType,
        identifier: String
    ) -> NSPredicate {
        NSPredicate { object, _ in
            guard let record = object as? HKClinicalRecord else { return false }
            return record.sourceRevision.source.bundleIdentifier == source.bundleIdentifier
                && record.fhirResourceType == resourceType
                && record.fhirIdentifier == identifier
        }
    }

    public class func predicateForObjectsAssociated(with electrocardiogram: HKElectrocardiogram) -> NSPredicate {
        predicateForObjectsAssociated(electrocardiogram: electrocardiogram)
    }

    public class func predicateForObjectsAssociated(electrocardiogram: HKElectrocardiogram) -> NSPredicate {
        NSPredicate { object, _ in
            (object as? HKObject)?.uuid == electrocardiogram.uuid
        }
    }

    public class func predicateForMedicationDoseEvent(medicationConceptIdentifier: HKHealthConceptIdentifier) -> NSPredicate {
        NSPredicate { object, _ in
            (object as? HKMedicationDoseEvent)?.medicationConceptIdentifier == medicationConceptIdentifier
        }
    }

    public class func predicateForMedicationDoseEvent(medicationConceptIdentifiers: Set<HKHealthConceptIdentifier>) -> NSPredicate {
        NSPredicate { object, _ in
            guard let event = object as? HKMedicationDoseEvent else { return false }
            return medicationConceptIdentifiers.contains(event.medicationConceptIdentifier)
        }
    }

    public class func predicateForMedicationDoseEvent(scheduledDate: Date) -> NSPredicate {
        NSPredicate { object, _ in
            (object as? HKMedicationDoseEvent)?.scheduledDate == scheduledDate
        }
    }

    public class func predicateForMedicationDoseEvent(scheduledDates: Set<Date>) -> NSPredicate {
        NSPredicate { object, _ in
            guard let date = (object as? HKMedicationDoseEvent)?.scheduledDate else { return false }
            return scheduledDates.contains(date)
        }
    }

    public class func predicateForMedicationDoseEvent(scheduledStart startDate: Date?, end endDate: Date?) -> NSPredicate {
        NSPredicate { object, _ in
            guard let date = (object as? HKMedicationDoseEvent)?.scheduledDate else { return false }
            if let startDate, date < startDate { return false }
            if let endDate, date > endDate { return false }
            return true
        }
    }

    public class func predicateForMedicationDoseEvent(status: HKMedicationDoseEvent.LogStatus) -> NSPredicate {
        NSPredicate { object, _ in
            (object as? HKMedicationDoseEvent)?.logStatus == status
        }
    }

    public class func predicateForMedicationDoseEvent(statuses: Set<NSNumber>) -> NSPredicate {
        let values = Set(statuses.map(\.intValue))
        return NSPredicate { object, _ in
            guard let event = object as? HKMedicationDoseEvent else { return false }
            return values.contains(event.logStatus.rawValue)
        }
    }

    public class func predicateForStatesOfMind(with association: HKStateOfMind.Association) -> NSPredicate {
        NSPredicate { object, _ in
            (object as? HKStateOfMind)?.associations.contains(association) == true
        }
    }

    public class func predicateForStatesOfMind(with kind: HKStateOfMind.Kind) -> NSPredicate {
        NSPredicate { object, _ in
            (object as? HKStateOfMind)?.kind == kind
        }
    }

    public class func predicateForStatesOfMind(with label: HKStateOfMind.Label) -> NSPredicate {
        NSPredicate { object, _ in
            (object as? HKStateOfMind)?.labels.contains(label) == true
        }
    }

    public class func predicateForStatesOfMind(withValence valence: Double, operatorType: HKPredicateOperator) -> NSPredicate {
        NSPredicate { object, _ in
            guard let mind = object as? HKStateOfMind else { return false }
            return hkCompare(mind.valence, operatorType, valence)
        }
    }

    public class func predicateForUserAnnotatedMedications(hasSchedule: Bool) -> NSPredicate {
        NSPredicate { object, _ in
            (object as? HKUserAnnotatedMedication)?.hasSchedule == hasSchedule
        }
    }

    public class func predicateForUserAnnotatedMedications(isArchived: Bool) -> NSPredicate {
        NSPredicate { object, _ in
            (object as? HKUserAnnotatedMedication)?.isArchived == isArchived
        }
    }

    public class func predicateForVerifiableClinicalRecords(withRelevantDateWithin dateInterval: DateInterval) -> NSPredicate {
        NSPredicate { object, _ in
            guard let record = object as? HKVerifiableClinicalRecord else { return false }
            return dateInterval.contains(record.startDate)
        }
    }
}

public typealias HKSampleQueryResultsHandler = (HKSampleQuery, [HKSample]?, (any Error)?) -> Void

open class HKSampleQuery: HKQuery, @unchecked Sendable {
    public let limit: Int
    public let sortDescriptors: [NSSortDescriptor]?
    public let queryDescriptors: [HKQueryDescriptor]
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
        self.queryDescriptors = [HKQueryDescriptor(sampleType: sampleType, predicate: predicate)]
        self.resultsHandler = resultsHandler
        super.init(objectType: sampleType, predicate: predicate)
    }

    public init(
        queryDescriptors: [HKQueryDescriptor],
        limit: Int,
        resultsHandler: @escaping HKSampleQueryResultsHandler
    ) {
        self.limit = limit
        self.sortDescriptors = nil
        self.queryDescriptors = queryDescriptors
        self.resultsHandler = resultsHandler
        super.init(objectType: queryDescriptors.first?.sampleType, predicate: queryDescriptors.first?.predicate)
    }

    public init(
        queryDescriptors: [HKQueryDescriptor],
        limit: Int,
        sortDescriptors: [NSSortDescriptor],
        resultsHandler: @escaping HKSampleQueryResultsHandler
    ) {
        self.limit = limit
        self.sortDescriptors = sortDescriptors
        self.queryDescriptors = queryDescriptors
        self.resultsHandler = resultsHandler
        super.init(objectType: queryDescriptors.first?.sampleType, predicate: queryDescriptors.first?.predicate)
    }

    func deliver(_ samples: [HKSample]?, error: (any Error)?) {
        resultsHandler?(self, samples, error)
    }
}

public typealias HKObserverQueryCompletionHandler = () -> Void

open class HKStatisticsQuery: HKQuery, @unchecked Sendable {
    public let quantityType: HKQuantityType
    public let options: HKStatisticsOptions
    private let completionHandler: ((HKStatisticsQuery, HKStatistics?, (any Error)?) -> Void)?

    public init(
        quantityType: HKQuantityType,
        quantitySamplePredicate: NSPredicate?,
        options: HKStatisticsOptions = [],
        completionHandler handler: @escaping (HKStatisticsQuery, HKStatistics?, (any Error)?) -> Void
    ) {
        self.quantityType = quantityType
        self.options = options
        self.completionHandler = handler
        super.init(objectType: quantityType, predicate: quantitySamplePredicate)
    }

    func deliver(_ statistics: HKStatistics?, error: (any Error)?) {
        completionHandler?(self, statistics, error)
    }
}

open class HKStatisticsCollectionQuery: HKQuery, @unchecked Sendable {
    public let quantityType: HKQuantityType
    public let options: HKStatisticsOptions
    public let anchorDate: Date
    public let intervalComponents: DateComponents
    public var initialResultsHandler: ((HKStatisticsCollectionQuery, HKStatisticsCollection?, (any Error)?) -> Void)?
    public var statisticsUpdateHandler: ((HKStatisticsCollectionQuery, HKStatistics?, HKStatisticsCollection?, (any Error)?) -> Void)?

    public init(
        quantityType: HKQuantityType,
        quantitySamplePredicate: NSPredicate?,
        options: HKStatisticsOptions = [],
        anchorDate: Date,
        intervalComponents: DateComponents
    ) {
        self.quantityType = quantityType
        self.options = options
        self.anchorDate = anchorDate
        self.intervalComponents = intervalComponents
        super.init(objectType: quantityType, predicate: quantitySamplePredicate)
    }
}

open class HKObserverQuery: HKQuery, @unchecked Sendable {
    public let queryDescriptors: [HKQueryDescriptor]
    private let updateHandler: ((HKObserverQuery, Set<HKSampleType>?, @escaping HKObserverQueryCompletionHandler, (any Error)?) -> Void)?
    private let sampleUpdateHandler: ((HKObserverQuery, @escaping HKObserverQueryCompletionHandler, (any Error)?) -> Void)?

    public init(
        sampleType: HKSampleType,
        predicate: NSPredicate?,
        updateHandler: @escaping (HKObserverQuery, @escaping HKObserverQueryCompletionHandler, (any Error)?) -> Void
    ) {
        self.queryDescriptors = [HKQueryDescriptor(sampleType: sampleType, predicate: predicate)]
        self.updateHandler = nil
        self.sampleUpdateHandler = updateHandler
        super.init(objectType: sampleType, predicate: predicate)
    }

    public init(
        queryDescriptors: [HKQueryDescriptor],
        updateHandler: @escaping (HKObserverQuery, Set<HKSampleType>?, @escaping HKObserverQueryCompletionHandler, (any Error)?) -> Void
    ) {
        self.queryDescriptors = queryDescriptors
        self.updateHandler = updateHandler
        self.sampleUpdateHandler = nil
        super.init(objectType: queryDescriptors.first?.sampleType, predicate: queryDescriptors.first?.predicate)
    }

    func deliverUpdate(changed: Set<String>) {
        let types = Set(queryDescriptors.map(\.sampleType).filter { changed.contains($0.identifier) })
        let completion: HKObserverQueryCompletionHandler = {}
        if let updateHandler {
            updateHandler(self, types, completion, nil)
        } else {
            sampleUpdateHandler?(self, completion, nil)
        }
    }
}

open class HKAnchoredObjectQuery: HKQuery, @unchecked Sendable {
    public let limit: Int
    public let queryDescriptors: [HKQueryDescriptor]
    public var updateHandler: ((HKAnchoredObjectQuery, [HKSample]?, [HKDeletedObject]?, HKQueryAnchor?, (any Error)?) -> Void)?
    private let resultsHandler: ((HKAnchoredObjectQuery, [HKSample]?, [HKDeletedObject]?, HKQueryAnchor?, (any Error)?) -> Void)?
    private let completionHandler: ((HKAnchoredObjectQuery, [HKSample]?, Int, (any Error)?) -> Void)?
    let initialAnchor: HKQueryAnchor?

    public init(
        type: HKSampleType,
        predicate: NSPredicate?,
        anchor: HKQueryAnchor?,
        limit: Int,
        resultsHandler handler: @escaping (HKAnchoredObjectQuery, [HKSample]?, [HKDeletedObject]?, HKQueryAnchor?, (any Error)?) -> Void
    ) {
        self.limit = limit
        self.queryDescriptors = [HKQueryDescriptor(sampleType: type, predicate: predicate)]
        self.resultsHandler = handler
        self.completionHandler = nil
        self.initialAnchor = anchor
        super.init(objectType: type, predicate: predicate)
    }

    public init(
        type: HKSampleType,
        predicate: NSPredicate?,
        anchor: Int,
        limit: Int,
        completionHandler handler: @escaping (HKAnchoredObjectQuery, [HKSample]?, Int, (any Error)?) -> Void
    ) {
        self.limit = limit
        self.queryDescriptors = [HKQueryDescriptor(sampleType: type, predicate: predicate)]
        self.resultsHandler = nil
        self.completionHandler = handler
        self.initialAnchor = HKQueryAnchor(fromValue: anchor)
        super.init(objectType: type, predicate: predicate)
    }

    public init(
        queryDescriptors: [HKQueryDescriptor],
        anchor: HKQueryAnchor?,
        limit: Int,
        resultsHandler handler: @escaping (HKAnchoredObjectQuery, [HKSample]?, [HKDeletedObject]?, HKQueryAnchor?, (any Error)?) -> Void
    ) {
        self.limit = limit
        self.queryDescriptors = queryDescriptors
        self.resultsHandler = handler
        self.completionHandler = nil
        self.initialAnchor = anchor
        super.init(objectType: queryDescriptors.first?.sampleType, predicate: queryDescriptors.first?.predicate)
    }

    func deliver(samples: [HKSample]?, deleted: [HKDeletedObject]?, anchor: HKQueryAnchor?, error: (any Error)?) {
        resultsHandler?(self, samples, deleted, anchor, error)
        completionHandler?(self, samples, Int(anchor?.value ?? 0), error)
        updateHandler?(self, samples, deleted, anchor, error)
    }
}

open class HKSourceQuery: HKQuery, @unchecked Sendable {
    private let completionHandler: ((HKSourceQuery, Set<HKSource>?, (any Error)?) -> Void)?

    public init(
        sampleType: HKSampleType,
        samplePredicate objectPredicate: NSPredicate?,
        completionHandler: @escaping (HKSourceQuery, Set<HKSource>?, (any Error)?) -> Void
    ) {
        self.completionHandler = completionHandler
        super.init(objectType: sampleType, predicate: objectPredicate)
    }

    func deliver(_ sources: Set<HKSource>?, error: (any Error)?) {
        completionHandler?(self, sources, error)
    }
}

open class HKCorrelationQuery: HKQuery, @unchecked Sendable {
    public let correlationType: HKCorrelationType
    public let samplePredicates: [HKSampleType: NSPredicate]?
    private let completion: ((HKCorrelationQuery, [HKCorrelation]?, (any Error)?) -> Void)?

    public init(
        type correlationType: HKCorrelationType,
        predicate: NSPredicate?,
        samplePredicates: [HKSampleType: NSPredicate]?,
        completion: @escaping (HKCorrelationQuery, [HKCorrelation]?, (any Error)?) -> Void
    ) {
        self.correlationType = correlationType
        self.samplePredicates = samplePredicates
        self.completion = completion
        super.init(objectType: correlationType, predicate: predicate)
    }

    func deliver(_ correlations: [HKCorrelation]?, error: (any Error)?) {
        completion?(self, correlations, error)
    }
}

open class HKDocumentQuery: HKQuery, @unchecked Sendable {
    public init(documentType: HKDocumentType, predicate: NSPredicate?, limit: Int, sortDescriptors: [NSSortDescriptor]?, includeDocumentData: Bool, resultsHandler: @escaping (HKDocumentQuery, [HKDocumentSample]?, (any Error)?) -> Void) {
        _ = (limit, sortDescriptors, includeDocumentData, resultsHandler)
        super.init(objectType: documentType, predicate: predicate)
    }
}

open class HKActivitySummaryQuery: HKQuery, @unchecked Sendable {
    public var updateHandler: ((HKActivitySummaryQuery, [HKActivitySummary]?, (any Error)?) -> Void)?
    private let resultsHandler: ((HKActivitySummaryQuery, [HKActivitySummary]?, (any Error)?) -> Void)?

    public init(
        predicate: NSPredicate?,
        resultsHandler handler: @escaping (HKActivitySummaryQuery, [HKActivitySummary]?, (any Error)?) -> Void
    ) {
        self.resultsHandler = handler
        super.init(objectType: HKObjectType.activitySummaryType(), predicate: predicate)
    }

    func deliver(_ summaries: [HKActivitySummary]?, error: (any Error)?) {
        resultsHandler?(self, summaries, error)
        updateHandler?(self, summaries, error)
    }
}

open class HKHeartbeatSeriesQuery: HKQuery, @unchecked Sendable {
    public init(heartbeatSeries: HKHeartbeatSeriesSample, dataHandler: @escaping (HKHeartbeatSeriesQuery, TimeInterval, Bool, Bool, (any Error)?) -> Void) {
        _ = (heartbeatSeries, dataHandler)
        super.init(objectType: HKSeriesType.heartbeat(), predicate: nil)
    }
}

open class HKQuantitySeriesSampleQuery: HKQuery, @unchecked Sendable {
    public init(quantityType: HKQuantityType, predicate: NSPredicate?, quantityHandler: @escaping (HKQuantitySeriesSampleQuery, HKQuantity?, Date?, HKQuantitySample?, Bool, (any Error)?) -> Void) {
        _ = quantityHandler
        super.init(objectType: quantityType, predicate: predicate)
    }
}

open class HKElectrocardiogramQuery: HKQuery, @unchecked Sendable {
    public init(electrocardiogram: HKElectrocardiogram, dataHandler: @escaping (HKElectrocardiogramQuery, HKElectrocardiogramQuery.Result) -> Void) {
        _ = (electrocardiogram, dataHandler)
        super.init(objectType: HKObjectType.electrocardiogramType(), predicate: nil)
    }
}

open class HKWorkoutRouteQuery: HKQuery, @unchecked Sendable {
    public let route: HKWorkoutRoute
    public let dateInterval: DateInterval?
    private let dataHandler: (HKWorkoutRouteQuery, [CLLocation]?, Bool, (any Error)?) -> Void

    public init(route workoutRoute: HKWorkoutRoute, dataHandler: @escaping (HKWorkoutRouteQuery, [CLLocation]?, Bool, (any Error)?) -> Void) {
        self.route = workoutRoute
        self.dateInterval = nil
        self.dataHandler = dataHandler
        super.init(objectType: HKSeriesType.workoutRoute(), predicate: nil)
    }

    public init(route workoutRoute: HKWorkoutRoute, dateInterval: DateInterval, dataHandler: @escaping (HKWorkoutRouteQuery, [CLLocation]?, Bool, (any Error)?) -> Void) {
        self.route = workoutRoute
        self.dateInterval = dateInterval
        self.dataHandler = dataHandler
        super.init(objectType: HKSeriesType.workoutRoute(), predicate: nil)
    }

    func deliver(_ locations: [CLLocation]?, done: Bool, error: (any Error)?) {
        dataHandler(self, locations, done, error)
    }
}

open class HKWorkoutEffortRelationshipQuery: HKQuery, @unchecked Sendable {
    public init(
        predicate: NSPredicate?,
        anchor: HKQueryAnchor?,
        options: HKWorkoutEffortRelationshipQueryOptions,
        resultsHandler: @escaping (HKWorkoutEffortRelationshipQuery, [HKWorkoutEffortRelationship]?, HKQueryAnchor?, (any Error)?) -> Void
    ) {
        _ = (anchor, options, resultsHandler)
        super.init(objectType: nil, predicate: predicate)
    }
}

open class HKUserAnnotatedMedicationQuery: HKQuery, @unchecked Sendable {
    public init(predicate: NSPredicate?, limit: Int, resultsHandler: @escaping (HKUserAnnotatedMedicationQuery, [HKUserAnnotatedMedication]?, (any Error)?) -> Void) {
        _ = (limit, resultsHandler)
        super.init(objectType: HKObjectType.userAnnotatedMedicationType(), predicate: predicate)
    }
}

open class HKVerifiableClinicalRecordQuery: HKQuery, @unchecked Sendable {
    public init(recordTypes: [String], predicate: NSPredicate?, resultsHandler: @escaping (HKVerifiableClinicalRecordQuery, [HKVerifiableClinicalRecord]?, (any Error)?) -> Void) {
        _ = (recordTypes, resultsHandler)
        super.init(objectType: nil, predicate: predicate)
    }
}

func hkExecute(_ query: HKQuery) {
    let store = HKHealthStore()
    do {
        if let sampleQuery = query as? HKSampleQuery {
            var collected: [HKSample] = []
            for descriptor in sampleQuery.queryDescriptors {
                let part = try store.hkSamples(
                    of: descriptor.sampleType,
                    predicate: descriptor.predicate,
                    limit: HKObjectQueryNoLimit,
                    sortDescriptors: sampleQuery.sortDescriptors
                )
                collected.append(contentsOf: part)
            }
            collected = hkSort(collected, descriptors: sampleQuery.sortDescriptors)
            if sampleQuery.limit > 0, collected.count > sampleQuery.limit {
                collected = Array(collected.prefix(sampleQuery.limit))
            }
            sampleQuery.deliver(collected, error: nil)
            return
        }
        if let statisticsQuery = query as? HKStatisticsQuery {
            let samples = try store.hkSamples(
                of: statisticsQuery.quantityType,
                predicate: statisticsQuery.predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: nil
            ).compactMap { $0 as? HKQuantitySample }
            let stats = HKStatistics.compute(
                quantityType: statisticsQuery.quantityType,
                samples: samples,
                options: statisticsQuery.options,
                start: samples.map(\.startDate).min() ?? Date(),
                end: samples.map(\.endDate).max() ?? Date()
            )
            statisticsQuery.deliver(stats, error: nil)
            return
        }
        if let collectionQuery = query as? HKStatisticsCollectionQuery {
            let samples = try store.hkSamples(
                of: collectionQuery.quantityType,
                predicate: collectionQuery.predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: nil
            ).compactMap { $0 as? HKQuantitySample }
            let collection = HKStatisticsCollection.build(
                quantityType: collectionQuery.quantityType,
                samples: samples,
                options: collectionQuery.options,
                anchorDate: collectionQuery.anchorDate,
                intervalComponents: collectionQuery.intervalComponents
            )
            collectionQuery.initialResultsHandler?(collectionQuery, collection, nil)
            return
        }
        if let observer = query as? HKObserverQuery {
            HKHealthStorePortable.registerObserver(observer)
            observer.deliverUpdate(changed: Set(observer.queryDescriptors.map { $0.sampleType.identifier }))
            return
        }
        if let anchored = query as? HKAnchoredObjectQuery {
            var collected: [HKSample] = []
            for descriptor in anchored.queryDescriptors {
                let part = try store.hkSamples(
                    of: descriptor.sampleType,
                    predicate: descriptor.predicate,
                    limit: HKObjectQueryNoLimit,
                    sortDescriptors: nil
                )
                collected.append(contentsOf: part)
            }
            let floor = anchored.initialAnchor?.value ?? 0
            let filtered = collected.filter { sample in
                HKHealthStorePortable.loadState().samples.first { $0.uuid == sample.uuid.uuidString }?.anchor ?? 0 > floor
            }
            let limited: [HKSample]
            if anchored.limit > 0 {
                limited = Array(filtered.prefix(anchored.limit))
            } else {
                limited = filtered
            }
            let newAnchor = HKQueryAnchor(fromValue: HKHealthStorePortable.loadState().nextAnchor)
            anchored.deliver(samples: limited, deleted: store.hkDeleted(), anchor: newAnchor, error: nil)
            return
        }
        if let sourceQuery = query as? HKSourceQuery {
            let samples = try store.hkSamples(
                of: sourceQuery.sampleType,
                predicate: sourceQuery.predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: nil
            )
            sourceQuery.deliver(Set(samples.map { $0.sourceRevision.source }), error: nil)
            return
        }
        if let correlationQuery = query as? HKCorrelationQuery {
            let samples = try store.hkSamples(
                of: correlationQuery.correlationType,
                predicate: correlationQuery.predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: nil
            ).compactMap { $0 as? HKCorrelation }
            correlationQuery.deliver(samples, error: nil)
            return
        }
        if let routeQuery = query as? HKWorkoutRouteQuery {
            var locations = HKHealthStorePortable.locations(for: routeQuery.route.uuid)
            if let interval = routeQuery.dateInterval {
                locations = locations.filter { interval.contains($0.timestamp) }
            }
            routeQuery.deliver(locations, done: true, error: nil)
            return
        }
        if let summaryQuery = query as? HKActivitySummaryQuery {
            let summaries = HKHealthStorePortable.loadState().summaries.map { HKActivitySummary(stored: $0) }
                .filter { hkEvaluatePredicate(query.predicate, object: $0) }
            summaryQuery.deliver(summaries, error: nil)
            return
        }
    } catch {
        if let sampleQuery = query as? HKSampleQuery {
            sampleQuery.deliver(nil, error: error)
        } else if let statisticsQuery = query as? HKStatisticsQuery {
            statisticsQuery.deliver(nil, error: error)
        } else if let collectionQuery = query as? HKStatisticsCollectionQuery {
            collectionQuery.initialResultsHandler?(collectionQuery, nil, error)
        } else if let sourceQuery = query as? HKSourceQuery {
            sourceQuery.deliver(nil, error: error)
        } else if let correlationQuery = query as? HKCorrelationQuery {
            correlationQuery.deliver(nil, error: error)
        } else if let routeQuery = query as? HKWorkoutRouteQuery {
            routeQuery.deliver(nil, done: true, error: error)
        } else if let summaryQuery = query as? HKActivitySummaryQuery {
            summaryQuery.deliver(nil, error: error)
        }
    }
}
