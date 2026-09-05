import Foundation

public protocol HKAsyncQuery {
    associatedtype Output
    func result(for healthStore: HKHealthStore) async throws -> Output
}

public protocol HKAsyncSequenceQuery {
    associatedtype Sequence: AsyncSequence
    func results(for healthStore: HKHealthStore) -> Sequence
}

public struct HKSamplePredicate<Sample: HKSample>: Hashable, Sendable {
    public let sampleType: HKSampleType
    public nonisolated(unsafe) let nsPredicate: NSPredicate?

    public init(sampleType: HKSampleType, nsPredicate: NSPredicate?) {
        self.sampleType = sampleType
        self.nsPredicate = nsPredicate
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(sampleType.identifier)
    }

    public static func == (a: HKSamplePredicate<Sample>, b: HKSamplePredicate<Sample>) -> Bool {
        a.sampleType.identifier == b.sampleType.identifier
    }

    public static func sample(type sampleType: HKSampleType, predicate: NSPredicate? = nil) -> HKSamplePredicate<HKSample> {
        HKSamplePredicate<HKSample>(sampleType: sampleType, nsPredicate: predicate)
    }

    public static func quantitySample(type quantityType: HKQuantityType, predicate: NSPredicate? = nil) -> HKSamplePredicate<HKQuantitySample> {
        HKSamplePredicate<HKQuantitySample>(sampleType: quantityType, nsPredicate: predicate)
    }

    public static func categorySample(type categoryType: HKCategoryType, predicate: NSPredicate? = nil) -> HKSamplePredicate<HKCategorySample> {
        HKSamplePredicate<HKCategorySample>(sampleType: categoryType, nsPredicate: predicate)
    }

    public static func correlation(type correlationType: HKCorrelationType, predicate: NSPredicate? = nil) -> HKSamplePredicate<HKCorrelation> {
        HKSamplePredicate<HKCorrelation>(sampleType: correlationType, nsPredicate: predicate)
    }

    public static func workout(_ predicate: NSPredicate? = nil) -> HKSamplePredicate<HKWorkout> {
        HKSamplePredicate<HKWorkout>(sampleType: HKObjectType.workoutType(), nsPredicate: predicate)
    }

    public static func workoutRoute(_ predicate: NSPredicate? = nil) -> HKSamplePredicate<HKWorkoutRoute> {
        HKSamplePredicate<HKWorkoutRoute>(sampleType: HKSeriesType.workoutRoute(), nsPredicate: predicate)
    }

    public static func stateOfMind(_ predicate: NSPredicate? = nil) -> HKSamplePredicate<HKStateOfMind> {
        HKSamplePredicate<HKStateOfMind>(sampleType: HKObjectType.stateOfMindType(), nsPredicate: predicate)
    }

    public static func clinicalRecord(type clinicalType: HKClinicalType, predicate: NSPredicate? = nil) -> HKSamplePredicate<HKClinicalRecord> {
        HKSamplePredicate<HKClinicalRecord>(sampleType: clinicalType, nsPredicate: predicate)
    }

    public static func gad7Assessment(_ predicate: NSPredicate? = nil) -> HKSamplePredicate<HKGAD7Assessment> {
        HKSamplePredicate<HKGAD7Assessment>(sampleType: HKScoredAssessmentType(identifier: HKScoredAssessmentTypeIdentifier.GAD7.rawValue), nsPredicate: predicate)
    }

    public static func phq9Assessment(_ predicate: NSPredicate? = nil) -> HKSamplePredicate<HKPHQ9Assessment> {
        HKSamplePredicate<HKPHQ9Assessment>(sampleType: HKScoredAssessmentType(identifier: HKScoredAssessmentTypeIdentifier.PHQ9.rawValue), nsPredicate: predicate)
    }

    public static func heartbeatSeries(_ predicate: NSPredicate? = nil) -> HKSamplePredicate<HKHeartbeatSeriesSample> {
        HKSamplePredicate<HKHeartbeatSeriesSample>(sampleType: HKSeriesType.heartbeat(), nsPredicate: predicate)
    }

    public static func electrocardiogram(_ predicate: NSPredicate? = nil) -> HKSamplePredicate<HKElectrocardiogram> {
        HKSamplePredicate<HKElectrocardiogram>(sampleType: HKObjectType.electrocardiogramType(), nsPredicate: predicate)
    }

    public static func visionPrescription(_ predicate: NSPredicate? = nil) -> HKSamplePredicate<HKVisionPrescription> {
        HKSamplePredicate<HKVisionPrescription>(sampleType: HKObjectType.visionPrescriptionType(), nsPredicate: predicate)
    }

    public static func audiogram(_ predicate: NSPredicate? = nil) -> HKSamplePredicate<HKAudiogramSample> {
        HKSamplePredicate<HKAudiogramSample>(sampleType: HKObjectType.audiogramSampleType(), nsPredicate: predicate)
    }
}

public struct HKSampleQueryDescriptor<Sample: HKSample>: HKAsyncQuery {
    public var predicates: [HKSamplePredicate<Sample>]
    public var sortDescriptors: [SortDescriptor<Sample>]
    public var limit: Int?
    public typealias Output = [Sample]

    public init(predicates: [HKSamplePredicate<Sample>], sortDescriptors: [SortDescriptor<Sample>], limit: Int? = nil) {
        self.predicates = predicates
        self.sortDescriptors = sortDescriptors
        self.limit = limit
    }

    public func result(for healthStore: HKHealthStore) async throws -> [Sample] {
        var collected: [Sample] = []
        for predicate in predicates {
            let samples = try healthStore.hkSamples(
                of: predicate.sampleType,
                predicate: predicate.nsPredicate,
                limit: limit ?? HKObjectQueryNoLimit,
                sortDescriptors: nil
            )
            collected.append(contentsOf: samples.compactMap { $0 as? Sample })
        }
        if let limit, collected.count > limit {
            collected = Array(collected.prefix(limit))
        }
        return collected
    }
}

public struct HKSourceQueryDescriptor<Sample: HKSample>: HKAsyncQuery {
    public var predicate: HKSamplePredicate<Sample>
    public typealias Output = [HKSource]

    public init(predicate: HKSamplePredicate<Sample>) {
        self.predicate = predicate
    }

    public func result(for healthStore: HKHealthStore) async throws -> [HKSource] {
        let samples = try healthStore.hkSamples(
            of: predicate.sampleType,
            predicate: predicate.nsPredicate,
            limit: HKObjectQueryNoLimit,
            sortDescriptors: nil
        )
        var seen = Set<String>()
        var sources: [HKSource] = []
        for sample in samples {
            let id = sample.sourceRevision.source.bundleIdentifier
            if seen.insert(id).inserted {
                sources.append(sample.sourceRevision.source)
            }
        }
        return sources
    }
}

public struct HKStatisticsQueryDescriptor: HKAsyncQuery {
    public var predicate: HKSamplePredicate<HKQuantitySample>
    public var options: HKStatisticsOptions
    public typealias Output = HKStatistics

    public init(predicate: HKSamplePredicate<HKQuantitySample>, options: HKStatisticsOptions) {
        self.predicate = predicate
        self.options = options
    }

    public func result(for healthStore: HKHealthStore) async throws -> HKStatistics {
        guard let type = predicate.sampleType as? HKQuantityType else {
            throw hkError(.errorInvalidArgument, reason: "statistics descriptor requires a quantity type")
        }
        let samples = try healthStore.hkSamples(
            of: type,
            predicate: predicate.nsPredicate,
            limit: HKObjectQueryNoLimit,
            sortDescriptors: nil
        ).compactMap { $0 as? HKQuantitySample }
        return HKStatistics.compute(
            quantityType: type,
            samples: samples,
            options: options,
            start: samples.map(\.startDate).min() ?? Date(),
            end: samples.map(\.endDate).max() ?? Date()
        )
    }
}

public struct HKAnchoredObjectQueryDescriptor<Sample: HKSample>: HKAsyncQuery, HKAsyncSequenceQuery {
    public var predicates: [HKSamplePredicate<Sample>]
    public var anchor: HKQueryAnchor?
    public var limit: Int?
    public typealias Output = Result

    public struct Result: Sendable {
        public var addedSamples: [Sample]
        public var deletedObjects: [HKDeletedObject]
        public var newAnchor: HKQueryAnchor
    }

    public struct Results: AsyncSequence, Sendable {
        public typealias Element = Result
        public let items: [Result]
        public func makeAsyncIterator() -> Iterator { Iterator(items: items) }
        public struct Iterator: AsyncIteratorProtocol {
            var items: [Result]
            var index = 0
            public mutating func next() async throws -> Result? {
                guard index < items.count else { return nil }
                defer { index += 1 }
                return items[index]
            }
        }
    }

    public init(predicates: [HKSamplePredicate<Sample>], anchor: HKQueryAnchor?, limit: Int? = nil) {
        self.predicates = predicates
        self.anchor = anchor
        self.limit = limit
    }

    public func result(for healthStore: HKHealthStore) async throws -> Result {
        var added: [Sample] = []
        for predicate in predicates {
            let samples = try healthStore.hkSamples(
                of: predicate.sampleType,
                predicate: predicate.nsPredicate,
                limit: limit ?? HKObjectQueryNoLimit,
                sortDescriptors: nil
            )
            added.append(contentsOf: samples.compactMap { $0 as? Sample })
        }
        return Result(
            addedSamples: added,
            deletedObjects: healthStore.hkDeleted(),
            newAnchor: HKQueryAnchor(fromValue: HKHealthStorePortable.loadState().nextAnchor)
        )
    }

    public func results(for healthStore: HKHealthStore) -> Results {
        let value = Result(
            addedSamples: [],
            deletedObjects: healthStore.hkDeleted(),
            newAnchor: HKQueryAnchor(fromValue: 0)
        )
        return Results(items: [value])
    }
}

public struct HKStatisticsCollectionQueryDescriptor: HKAsyncQuery, HKAsyncSequenceQuery {
    public var predicate: HKSamplePredicate<HKQuantitySample>
    public var options: HKStatisticsOptions
    public var anchorDate: Date
    public var intervalComponents: DateComponents
    public typealias Output = HKStatisticsCollection

    public struct Result: Sendable {
        public let statisticsCollection: HKStatisticsCollection
        public let updatedStatistics: [HKStatistics]?
    }

    public struct Results: AsyncSequence, Sendable {
        public typealias Element = Result
        public let items: [Result]
        public func makeAsyncIterator() -> Iterator { Iterator(items: items) }
        public struct Iterator: AsyncIteratorProtocol {
            var items: [Result]
            var index = 0
            public mutating func next() async throws -> Result? {
                guard index < items.count else { return nil }
                defer { index += 1 }
                return items[index]
            }
        }
    }

    public init(
        predicate: HKSamplePredicate<HKQuantitySample>,
        options: HKStatisticsOptions,
        anchorDate: Date,
        intervalComponents: DateComponents
    ) {
        self.predicate = predicate
        self.options = options
        self.anchorDate = anchorDate
        self.intervalComponents = intervalComponents
    }

    public func result(for healthStore: HKHealthStore) async throws -> HKStatisticsCollection {
        guard let type = predicate.sampleType as? HKQuantityType else {
            throw hkError(.errorInvalidArgument, reason: "collection descriptor requires a quantity type")
        }
        let samples = try healthStore.hkSamples(
            of: type,
            predicate: predicate.nsPredicate,
            limit: HKObjectQueryNoLimit,
            sortDescriptors: nil
        ).compactMap { $0 as? HKQuantitySample }
        return HKStatisticsCollection.build(
            quantityType: type,
            samples: samples,
            options: options,
            anchorDate: anchorDate,
            intervalComponents: intervalComponents
        )
    }

    public func results(for healthStore: HKHealthStore) -> Results {
        _ = healthStore
        let collection = HKStatisticsCollection.build(
            quantityType: predicate.sampleType as? HKQuantityType ?? HKQuantityType(identifier: ""),
            samples: [],
            options: options,
            anchorDate: anchorDate,
            intervalComponents: intervalComponents
        )
        return Results(items: [Result(statisticsCollection: collection, updatedStatistics: nil)])
    }
}

public struct HKActivitySummaryQueryDescriptor: HKAsyncQuery, HKAsyncSequenceQuery {
    public var predicate: NSPredicate?
    public typealias Output = [HKActivitySummary]
    public struct Results: AsyncSequence, Sendable {
        public typealias Element = HKActivitySummary
        public let items: [HKActivitySummary]
        public func makeAsyncIterator() -> Iterator { Iterator(items: items) }
        public struct Iterator: AsyncIteratorProtocol {
            var items: [HKActivitySummary]
            var index = 0
            public mutating func next() async throws -> HKActivitySummary? {
                guard index < items.count else { return nil }
                defer { index += 1 }
                return items[index]
            }
        }
    }

    public init(predicate: NSPredicate?) {
        self.predicate = predicate
    }

    public func result(for healthStore: HKHealthStore) async throws -> [HKActivitySummary] {
        _ = healthStore
        return HKHealthStorePortable.loadState().summaries.map { HKActivitySummary(stored: $0) }
            .filter { hkEvaluatePredicate(predicate, object: $0) }
    }

    public func results(for healthStore: HKHealthStore) -> Results {
        _ = healthStore
        let items = HKHealthStorePortable.loadState().summaries.map { HKActivitySummary(stored: $0) }
            .filter { hkEvaluatePredicate(predicate, object: $0) }
        return Results(items: items)
    }
}

public struct HKWorkoutRouteQueryDescriptor: HKAsyncQuery, HKAsyncSequenceQuery {
    public var predicate: HKSamplePredicate<HKWorkoutRoute>
    public typealias Output = [HKWorkoutRoute]
    public struct Results: AsyncSequence, Sendable {
        public typealias Element = [CLLocation]
        public let items: [[CLLocation]]
        public func makeAsyncIterator() -> Iterator { Iterator(items: items) }
        public struct Iterator: AsyncIteratorProtocol {
            var items: [[CLLocation]]
            var index = 0
            public mutating func next() async throws -> [CLLocation]? {
                guard index < items.count else { return nil }
                defer { index += 1 }
                return items[index]
            }
        }
    }

    public init(predicate: HKSamplePredicate<HKWorkoutRoute>) {
        self.predicate = predicate
    }

    public func result(for healthStore: HKHealthStore) async throws -> [HKWorkoutRoute] {
        try healthStore.hkSamples(
            of: predicate.sampleType,
            predicate: predicate.nsPredicate,
            limit: HKObjectQueryNoLimit,
            sortDescriptors: nil
        ).compactMap { $0 as? HKWorkoutRoute }
    }

    public func results(for healthStore: HKHealthStore) -> Results {
        let routes = (try? healthStore.hkSamples(
            of: predicate.sampleType,
            predicate: predicate.nsPredicate,
            limit: HKObjectQueryNoLimit,
            sortDescriptors: nil
        ).compactMap { $0 as? HKWorkoutRoute }) ?? []
        return Results(items: routes.map { HKHealthStorePortable.locations(for: $0.uuid) })
    }
}

public struct HKHeartbeatSeriesQueryDescriptor: HKAsyncQuery, HKAsyncSequenceQuery {
    public struct Heartbeat: Hashable, Sendable {
        public var precededByGap: Bool
        public var timeSinceSeriesStart: TimeInterval
    }

    public struct Results: AsyncSequence, Sendable {
        public typealias Element = Heartbeat
        public let items: [Heartbeat]
        public func makeAsyncIterator() -> Iterator { Iterator(items: items) }
        public struct Iterator: AsyncIteratorProtocol {
            var items: [Heartbeat]
            var index = 0
            public mutating func next() async throws -> Heartbeat? {
                guard index < items.count else { return nil }
                defer { index += 1 }
                return items[index]
            }
        }
    }

    public var predicate: HKSamplePredicate<HKHeartbeatSeriesSample>
    public typealias Output = [Heartbeat]

    public init(predicate: HKSamplePredicate<HKHeartbeatSeriesSample>) {
        self.predicate = predicate
    }

    public func result(for healthStore: HKHealthStore) async throws -> [Heartbeat] {
        _ = try healthStore.hkSamples(of: predicate.sampleType, predicate: predicate.nsPredicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil)
        return []
    }

    public func results(for healthStore: HKHealthStore) -> Results {
        Results(items: [])
    }
}

public struct HKElectrocardiogramQueryDescriptor: HKAsyncQuery, HKAsyncSequenceQuery {
    public var predicate: HKSamplePredicate<HKElectrocardiogram>
    public typealias Output = [HKElectrocardiogram.VoltageMeasurement]
    public struct Results: AsyncSequence, Sendable {
        public typealias Element = HKElectrocardiogram.VoltageMeasurement
        public let items: [HKElectrocardiogram.VoltageMeasurement]
        public func makeAsyncIterator() -> Iterator { Iterator(items: items) }
        public struct Iterator: AsyncIteratorProtocol {
            var items: [HKElectrocardiogram.VoltageMeasurement]
            var index = 0
            public mutating func next() async throws -> HKElectrocardiogram.VoltageMeasurement? {
                guard index < items.count else { return nil }
                defer { index += 1 }
                return items[index]
            }
        }
    }

    public init(predicate: HKSamplePredicate<HKElectrocardiogram>) {
        self.predicate = predicate
    }

    public func result(for healthStore: HKHealthStore) async throws -> [HKElectrocardiogram.VoltageMeasurement] {
        _ = healthStore
        return []
    }

    public func results(for healthStore: HKHealthStore) -> Results {
        Results(items: [])
    }
}

public struct HKQuantitySeriesSampleQueryDescriptor: HKAsyncQuery, HKAsyncSequenceQuery {
    public struct Options: OptionSet, Sendable {
        public let rawValue: UInt
        public init(rawValue: UInt) { self.rawValue = rawValue }
        public static let includeQuantities = Options(rawValue: 1 << 0)
    }

    public struct Result: Sendable {
        public var quantity: HKQuantity?
        public var date: Date?
        public var sample: HKQuantitySample?
    }

    public struct Results: AsyncSequence, Sendable {
        public typealias Element = Result
        public let items: [Result]
        public func makeAsyncIterator() -> Iterator { Iterator(items: items) }
        public struct Iterator: AsyncIteratorProtocol {
            var items: [Result]
            var index = 0
            public mutating func next() async throws -> Result? {
                guard index < items.count else { return nil }
                defer { index += 1 }
                return items[index]
            }
        }
    }

    public var predicate: HKSamplePredicate<HKQuantitySample>
    public var options: Options
    public typealias Output = [Result]

    public init(predicate: HKSamplePredicate<HKQuantitySample>, options: Options = []) {
        self.predicate = predicate
        self.options = options
    }

    public func result(for healthStore: HKHealthStore) async throws -> [Result] {
        let samples = try healthStore.hkSamples(
            of: predicate.sampleType,
            predicate: predicate.nsPredicate,
            limit: HKObjectQueryNoLimit,
            sortDescriptors: nil
        ).compactMap { $0 as? HKQuantitySample }
        return samples.map { Result(quantity: $0.quantity, date: $0.startDate, sample: $0) }
    }

    public func results(for healthStore: HKHealthStore) -> Results {
        let samples = (try? healthStore.hkSamples(
            of: predicate.sampleType,
            predicate: predicate.nsPredicate,
            limit: HKObjectQueryNoLimit,
            sortDescriptors: nil
        ).compactMap { $0 as? HKQuantitySample }) ?? []
        return Results(items: samples.map { Result(quantity: $0.quantity, date: $0.startDate, sample: $0) })
    }
}

public struct HKUserAnnotatedMedicationQueryDescriptor: HKAsyncQuery {
    public var predicate: NSPredicate?
    public typealias Output = [HKUserAnnotatedMedication]
    public init(predicate: NSPredicate?) { self.predicate = predicate }
    public func result(for healthStore: HKHealthStore) async throws -> [HKUserAnnotatedMedication] {
        _ = (healthStore, predicate)
        return []
    }
}

public struct HKVerifiableClinicalRecordQueryDescriptor: HKAsyncQuery {
    public var predicate: NSPredicate?
    public typealias Output = [HKVerifiableClinicalRecord]
    public init(predicate: NSPredicate?) { self.predicate = predicate }
    public func result(for healthStore: HKHealthStore) async throws -> [HKVerifiableClinicalRecord] {
        _ = (healthStore, predicate)
        return []
    }
}

public struct HKWorkoutEffortRelationshipQueryDescriptor: HKAsyncQuery, HKAsyncSequenceQuery {
    public var predicate: NSPredicate?
    public var anchor: HKQueryAnchor?
    public var option: HKWorkoutEffortRelationshipQueryOptions
    public typealias Output = Result
    public struct Result: Sendable {
        public var relationships: [HKWorkoutEffortRelationship]
        public var newAnchor: HKQueryAnchor
    }
    public struct Results: AsyncSequence, Sendable {
        public typealias Element = Result
        public let items: [Result]
        public func makeAsyncIterator() -> Iterator { Iterator(items: items) }
        public struct Iterator: AsyncIteratorProtocol {
            var items: [Result]
            var index = 0
            public mutating func next() async throws -> Result? {
                guard index < items.count else { return nil }
                defer { index += 1 }
                return items[index]
            }
        }
    }

    public init(predicate: NSPredicate?, anchor: HKQueryAnchor?, option: HKWorkoutEffortRelationshipQueryOptions) {
        self.predicate = predicate
        self.anchor = anchor
        self.option = option
    }

    public func result(for healthStore: HKHealthStore) async throws -> Result {
        _ = healthStore
        return Result(relationships: [], newAnchor: HKQueryAnchor(fromValue: 0))
    }

    public func results(for healthStore: HKHealthStore) -> Results {
        Results(items: [])
    }
}

public struct BufferedAsyncByteIterator {}
