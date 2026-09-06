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
        hasher.combine(nsPredicate != nil)
    }

    public static func == (a: HKSamplePredicate<Sample>, b: HKSamplePredicate<Sample>) -> Bool {
        a.sampleType.identifier == b.sampleType.identifier
            && (a.nsPredicate == nil) == (b.nsPredicate == nil)
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
    public typealias Sequence = Results

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
        try resultSync(healthStore)
    }

    public func results(for healthStore: HKHealthStore) -> Results {
        let snapshot = (try? resultSync(healthStore)) ?? Result(
            addedSamples: [],
            deletedObjects: healthStore.hkDeleted(),
            newAnchor: HKQueryAnchor(fromValue: 0)
        )
        return Results(items: [snapshot])
    }

    func resultSync(_ healthStore: HKHealthStore) throws -> Result {
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
}

public struct HKStatisticsCollectionQueryDescriptor: HKAsyncQuery, HKAsyncSequenceQuery {
    public var predicate: HKSamplePredicate<HKQuantitySample>
    public var options: HKStatisticsOptions
    public var anchorDate: Date
    public var intervalComponents: DateComponents
    public typealias Output = HKStatisticsCollection
    public typealias Sequence = Results

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
        try collectionSync(healthStore)
    }

    public func results(for healthStore: HKHealthStore) -> Results {
        let collection = (try? collectionSync(healthStore)) ?? HKStatisticsCollection.build(
            quantityType: predicate.sampleType as? HKQuantityType ?? HKQuantityType(identifier: ""),
            samples: [],
            options: options,
            anchorDate: anchorDate,
            intervalComponents: intervalComponents
        )
        return Results(items: [Result(statisticsCollection: collection, updatedStatistics: nil)])
    }

    func collectionSync(_ healthStore: HKHealthStore) throws -> HKStatisticsCollection {
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
}

public struct HKActivitySummaryQueryDescriptor: HKAsyncQuery, HKAsyncSequenceQuery {
    public var predicate: NSPredicate?
    public typealias Output = [HKActivitySummary]
    public typealias Sequence = Results
    public struct Results: AsyncSequence, Sendable {
        public typealias Element = [HKActivitySummary]
        public let items: [[HKActivitySummary]]
        public func makeAsyncIterator() -> Iterator { Iterator(items: items) }
        public struct Iterator: AsyncIteratorProtocol {
            var items: [[HKActivitySummary]]
            var index = 0
            public mutating func next() async throws -> [HKActivitySummary]? {
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
        return summariesSync()
    }

    public func results(for healthStore: HKHealthStore) -> Results {
        _ = healthStore
        return Results(items: [summariesSync()])
    }

    func summariesSync() -> [HKActivitySummary] {
        HKHealthStorePortable.loadState().summaries.map { HKActivitySummary(stored: $0) }
            .filter { hkEvaluatePredicate(predicate, object: $0) }
    }
}

public struct HKWorkoutRouteQueryDescriptor: HKAsyncQuery, HKAsyncSequenceQuery {
    public var predicate: HKSamplePredicate<HKWorkoutRoute>
    public typealias Output = [HKWorkoutRoute]
    public typealias Sequence = Results
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

    public init(_ workoutRoute: HKWorkoutRoute) {
        self.predicate = HKSamplePredicate.workoutRoute(HKQuery.predicateForObject(with: workoutRoute.uuid))
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
        public var timeIntervalSinceStart: TimeInterval

        public static func == (a: Heartbeat, b: Heartbeat) -> Bool {
            a.precededByGap == b.precededByGap
                && abs(a.timeIntervalSinceStart - b.timeIntervalSinceStart) < 1e-9
        }

        public func hash(into hasher: inout Hasher) {
            hasher.combine(precededByGap)
            hasher.combine(timeIntervalSinceStart)
        }
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

    public var sample: HKHeartbeatSeriesSample
    public typealias Output = [Heartbeat]
    public typealias Sequence = Results

    public init(_ sample: HKHeartbeatSeriesSample) {
        self.sample = sample
    }

    public func result(for healthStore: HKHealthStore) async throws -> [Heartbeat] {
        _ = healthStore
        return heartbeatsSync()
    }

    public func results(for healthStore: HKHealthStore) -> Results {
        _ = healthStore
        return Results(items: heartbeatsSync())
    }

    func heartbeatsSync() -> [Heartbeat] {
        HKHealthStorePortable.heartbeatPoints(for: sample.uuid).map {
            Heartbeat(precededByGap: $0.precededByGap, timeIntervalSinceStart: $0.timeIntervalSinceStart)
        }
    }
}

public struct HKElectrocardiogramQueryDescriptor: HKAsyncQuery, HKAsyncSequenceQuery {
    public var electrocardiogram: HKElectrocardiogram
    public typealias Output = [HKElectrocardiogram.VoltageMeasurement]
    public typealias Sequence = Results
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

    public init(_ electrocardiogram: HKElectrocardiogram) {
        self.electrocardiogram = electrocardiogram
    }

    public func result(for healthStore: HKHealthStore) async throws -> [HKElectrocardiogram.VoltageMeasurement] {
        _ = healthStore
        return HKHealthStorePortable.voltageMeasurements(for: electrocardiogram.uuid)
    }

    public func results(for healthStore: HKHealthStore) -> Results {
        Results(items: HKHealthStorePortable.voltageMeasurements(for: electrocardiogram.uuid))
    }
}

public struct HKQuantitySeriesSampleQueryDescriptor: HKAsyncQuery, HKAsyncSequenceQuery {
    public struct Options: OptionSet, Sendable, Hashable {
        public let rawValue: Int
        public init(rawValue: Int) { self.rawValue = rawValue }
        public static let includeSample = Options(rawValue: 1 << 0)
        public static let orderByQuantitySampleStartDate = Options(rawValue: 1 << 1)
    }

    public struct Result: Hashable, Sendable {
        public let quantity: HKQuantity
        public let dateInterval: DateInterval
        public let sample: HKQuantitySample?

        public static func == (a: Result, b: Result) -> Bool {
            a.quantity.isEqual(b.quantity)
                && a.dateInterval == b.dateInterval
                && a.sample?.uuid == b.sample?.uuid
        }

        public func hash(into hasher: inout Hasher) {
            hasher.combine(quantity.doubleValue)
            hasher.combine(quantity.unit.unitString)
            hasher.combine(dateInterval.start)
            hasher.combine(dateInterval.duration)
            hasher.combine(sample?.uuid)
        }
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
    public typealias Sequence = Results

    public init(predicate: HKSamplePredicate<HKQuantitySample>, options: Options = []) {
        self.predicate = predicate
        self.options = options
    }

    public func result(for healthStore: HKHealthStore) async throws -> [Result] {
        try seriesSync(healthStore)
    }

    public func results(for healthStore: HKHealthStore) -> Results {
        Results(items: (try? seriesSync(healthStore)) ?? [])
    }

    func seriesSync(_ healthStore: HKHealthStore) throws -> [Result] {
        var samples = try healthStore.hkSamples(
            of: predicate.sampleType,
            predicate: predicate.nsPredicate,
            limit: HKObjectQueryNoLimit,
            sortDescriptors: nil
        ).compactMap { $0 as? HKQuantitySample }
        if options.contains(.orderByQuantitySampleStartDate) {
            samples.sort { $0.startDate < $1.startDate }
        }
        var collected: [Result] = []
        for sample in samples {
            let points = HKHealthStorePortable.quantitySeriesPoints(for: sample.uuid)
            let includeSample = options.contains(.includeSample) ? sample : nil
            if points.isEmpty {
                collected.append(
                    Result(
                        quantity: sample.quantity,
                        dateInterval: DateInterval(start: sample.startDate, end: sample.endDate),
                        sample: includeSample
                    )
                )
            } else {
                for point in points {
                    collected.append(
                        Result(
                            quantity: point.quantity,
                            dateInterval: point.dateInterval,
                            sample: includeSample
                        )
                    )
                }
            }
        }
        return collected
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
    public var recordTypes: [HKVerifiableClinicalRecordCredentialType]
    public var sourceTypes: [HKVerifiableClinicalRecordSourceType]
    public var predicate: NSPredicate?
    public typealias Output = [HKVerifiableClinicalRecord]

    public init(
        recordTypes: [HKVerifiableClinicalRecordCredentialType],
        sourceTypes: [HKVerifiableClinicalRecordSourceType],
        predicate: NSPredicate? = nil
    ) {
        self.recordTypes = recordTypes
        self.sourceTypes = sourceTypes
        self.predicate = predicate
    }

    public func result(for healthStore: HKHealthStore) async throws -> [HKVerifiableClinicalRecord] {
        recordsSync(healthStore)
    }

    func recordsSync(_ healthStore: HKHealthStore) -> [HKVerifiableClinicalRecord] {
        let wanted = Set(recordTypes.map(\.rawValue))
        let sources = Set(sourceTypes.map(\.rawValue))
        return healthStore.hkAllSamples().compactMap { $0 as? HKVerifiableClinicalRecord }.filter { record in
            let typeOK = wanted.isEmpty || record.recordTypes.contains(where: { wanted.contains($0) })
            let sourceOK = sources.isEmpty || (record.sourceType.map { sources.contains($0.rawValue) } ?? false)
            return typeOK && sourceOK && hkEvaluatePredicate(predicate, object: record)
        }
    }
}

public struct HKWorkoutEffortRelationshipQueryDescriptor: HKAsyncQuery, HKAsyncSequenceQuery {
    public var predicate: NSPredicate?
    public var anchor: HKQueryAnchor?
    public var option: HKWorkoutEffortRelationshipQueryOptions
    public typealias Output = Result
    public typealias Sequence = Results
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
        return resultSync()
    }

    public func results(for healthStore: HKHealthStore) -> Results {
        _ = healthStore
        return Results(items: [resultSync()])
    }

    func resultSync() -> Result {
        var rows = HKHealthStorePortable.effortRelationshipsLocked().filter {
            hkEvaluatePredicate(predicate, object: $0)
        }
        if option == .mostRelevant, let last = rows.last {
            rows = [last]
        }
        return Result(
            relationships: rows,
            newAnchor: HKQueryAnchor(fromValue: HKHealthStorePortable.loadState().nextAnchor)
        )
    }
}

public struct BufferedAsyncByteIterator {}
