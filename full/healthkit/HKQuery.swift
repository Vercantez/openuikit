import Foundation

open class HKQuery: NSObject {
    public let objectType: HKObjectType?
    public let predicate: NSPredicate?
    public var sampleType: HKSampleType? { objectType as? HKSampleType }

    var isExecuting = false

    init(objectType: HKObjectType?, predicate: NSPredicate?) {
        self.objectType = objectType
        self.predicate = predicate
        super.init()
    }

    func handleExecution(on store: HKHealthStore) {}
    func handleStop() { isExecuting = false }

    open class func predicateForObject(with UUID: UUID) -> NSPredicate {
        NSPredicate { object, _ in
            (object as? HKObject)?.uuid == UUID
        }
    }

    open class func predicateForObjects(with UUIDs: Set<UUID>) -> NSPredicate {
        NSPredicate { object, _ in
            guard let sample = object as? HKObject else { return false }
            return UUIDs.contains(sample.uuid)
        }
    }

    open class func predicateForObjects(from source: HKSource) -> NSPredicate {
        NSPredicate { object, _ in
            (object as? HKObject)?.source.bundleIdentifier == source.bundleIdentifier
        }
    }

    open class func predicateForObjects(from sources: Set<HKSource>) -> NSPredicate {
        let ids = Set(sources.map(\.bundleIdentifier))
        return NSPredicate { object, _ in
            guard let sample = object as? HKObject else { return false }
            return ids.contains(sample.source.bundleIdentifier)
        }
    }

    open class func predicateForObjects(from sourceRevisions: Set<HKSourceRevision>) -> NSPredicate {
        NSPredicate { object, _ in
            guard let sample = object as? HKObject else { return false }
            return sourceRevisions.contains { revision in
                revision.source.bundleIdentifier == sample.sourceRevision.source.bundleIdentifier
                    && revision.version == sample.sourceRevision.version
            }
        }
    }

    open class func predicateForObjects(from devices: Set<HKDevice>) -> NSPredicate {
        NSPredicate { object, _ in
            guard let sample = object as? HKObject, let device = sample.device else { return false }
            return devices.contains { candidate in
                candidate.localIdentifier == device.localIdentifier
                    && candidate.name == device.name
                    && candidate.udiDeviceIdentifier == device.udiDeviceIdentifier
            }
        }
    }

    open class func predicateForObjects(from workout: HKWorkout) -> NSPredicate {
        NSPredicate { object, _ in
            (object as? HKObject)?.uuid == workout.uuid
        }
    }

    open class func predicateForSamples(
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

    open class func predicateForWorkouts(with workoutActivityType: HKWorkoutActivityType) -> NSPredicate {
        NSPredicate { object, _ in
            (object as? HKWorkout)?.workoutActivityType == workoutActivityType
        }
    }

    open class func predicateForObjectsWithNoCorrelation() -> NSPredicate {
        NSPredicate { object, _ in
            !(object is HKCorrelation)
        }
    }

    open class func predicateForObjects(withMetadataKey key: String) -> NSPredicate {
        NSPredicate { object, _ in
            (object as? HKObject)?.metadata?[key] != nil
        }
    }

    open class func predicateForObjects(
        withDeviceProperty key: String,
        allowedValues: Set<String>
    ) -> NSPredicate {
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
}

open class HKQueryDescriptor: NSObject, NSCopying {
    public let sampleType: HKSampleType
    public let predicate: NSPredicate?

    public init(sampleType: HKSampleType, predicate: NSPredicate?) {
        self.sampleType = sampleType
        self.predicate = predicate
        super.init()
    }

    public convenience init?(coder: NSCoder) { nil }

    public func copy(with zone: NSZone? = nil) -> Any {
        HKQueryDescriptor(sampleType: sampleType, predicate: predicate)
    }
}

open class HKSampleQuery: HKQuery {
    public let limit: Int
    public let sortDescriptors: [NSSortDescriptor]?
    let resultsHandler: (HKSampleQuery, [HKSample]?, (any Error)?) -> Void

    public init(
        sampleType: HKSampleType,
        predicate: NSPredicate?,
        limit: Int,
        sortDescriptors: [NSSortDescriptor]?,
        resultsHandler: @escaping (HKSampleQuery, [HKSample]?, (any Error)?) -> Void
    ) {
        self.limit = limit
        self.sortDescriptors = sortDescriptors
        self.resultsHandler = resultsHandler
        super.init(objectType: sampleType, predicate: predicate)
    }

    public convenience init(
        queryDescriptors: [HKQueryDescriptor],
        limit: Int,
        resultsHandler: @escaping (HKSampleQuery, [HKSample]?, (any Error)?) -> Void
    ) {
        let sampleType = queryDescriptors.first?.sampleType ?? HKObjectType.workoutType()
        self.init(
            sampleType: sampleType,
            predicate: queryDescriptors.first?.predicate,
            limit: limit,
            sortDescriptors: nil,
            resultsHandler: resultsHandler
        )
    }

    public convenience init(
        queryDescriptors: [HKQueryDescriptor],
        limit: Int,
        sortDescriptors: [NSSortDescriptor],
        resultsHandler: @escaping (HKSampleQuery, [HKSample]?, (any Error)?) -> Void
    ) {
        let sampleType = queryDescriptors.first?.sampleType ?? HKObjectType.workoutType()
        self.init(
            sampleType: sampleType,
            predicate: queryDescriptors.first?.predicate,
            limit: limit,
            sortDescriptors: sortDescriptors,
            resultsHandler: resultsHandler
        )
    }

    override func handleExecution(on store: HKHealthStore) {
        resultsHandler(self, nil, hkUnavailableError())
    }
}

public typealias HKObserverQueryCompletionHandler = () -> Void

open class HKObserverQuery: HKQuery {
    let updateHandler: (HKObserverQuery, @escaping HKObserverQueryCompletionHandler, (any Error)?) -> Void

    public init(
        sampleType: HKSampleType,
        predicate: NSPredicate?,
        updateHandler: @escaping (HKObserverQuery, @escaping HKObserverQueryCompletionHandler, (any Error)?) -> Void
    ) {
        self.updateHandler = updateHandler
        super.init(objectType: sampleType, predicate: predicate)
    }

    override func handleExecution(on store: HKHealthStore) {
        updateHandler(self, {}, hkUnavailableError())
    }
}

open class HKAnchoredObjectQuery: HKQuery {
    public init(
        type: HKSampleType,
        predicate: NSPredicate?,
        anchor: HKQueryAnchor?,
        limit: Int,
        resultsHandler: @escaping (HKAnchoredObjectQuery, [HKSample]?, [HKDeletedObject]?, HKQueryAnchor?, (any Error)?) -> Void
    ) {
        self._handler = resultsHandler
        super.init(objectType: type, predicate: predicate)
    }

    private let _handler: (HKAnchoredObjectQuery, [HKSample]?, [HKDeletedObject]?, HKQueryAnchor?, (any Error)?) -> Void

    override func handleExecution(on store: HKHealthStore) {
        _handler(self, nil, nil, nil, hkUnavailableError())
    }
}

open class HKStatisticsQuery: HKQuery {
    public init(
        quantityType: HKQuantityType,
        quantitySamplePredicate: NSPredicate?,
        options: HKStatisticsOptions,
        completionHandler: @escaping (HKStatisticsQuery, HKStatistics?, (any Error)?) -> Void
    ) {
        self._handler = completionHandler
        super.init(objectType: quantityType, predicate: quantitySamplePredicate)
    }

    private let _handler: (HKStatisticsQuery, HKStatistics?, (any Error)?) -> Void

    override func handleExecution(on store: HKHealthStore) {
        _handler(self, nil, hkUnavailableError())
    }
}

open class HKSourceQuery: HKQuery {
    public init(
        sampleType: HKSampleType,
        samplePredicate: NSPredicate?,
        completionHandler: @escaping (HKSourceQuery, Set<HKSource>?, (any Error)?) -> Void
    ) {
        self._handler = completionHandler
        super.init(objectType: sampleType, predicate: samplePredicate)
    }

    private let _handler: (HKSourceQuery, Set<HKSource>?, (any Error)?) -> Void

    override func handleExecution(on store: HKHealthStore) {
        _handler(self, nil, hkUnavailableError())
    }
}

open class HKCorrelationQuery: HKQuery {
    public init(
        type correlationType: HKCorrelationType,
        predicate: NSPredicate?,
        samplePredicates: [HKSampleType: NSPredicate]?,
        completion: @escaping (HKCorrelationQuery, [HKCorrelation]?, (any Error)?) -> Void
    ) {
        self._handler = completion
        super.init(objectType: correlationType, predicate: predicate)
    }

    private let _handler: (HKCorrelationQuery, [HKCorrelation]?, (any Error)?) -> Void

    override func handleExecution(on store: HKHealthStore) {
        _handler(self, nil, hkUnavailableError())
    }
}

open class HKActivitySummaryQuery: HKQuery {
    public init(
        predicate: NSPredicate?,
        resultsHandler handler: @escaping (HKActivitySummaryQuery, [HKActivitySummary]?, (any Error)?) -> Void
    ) {
        self._handler = handler
        super.init(objectType: HKObjectType.activitySummaryType(), predicate: predicate)
    }

    private let _handler: (HKActivitySummaryQuery, [HKActivitySummary]?, (any Error)?) -> Void

    override func handleExecution(on store: HKHealthStore) {
        _handler(self, nil, hkUnavailableError())
    }
}
