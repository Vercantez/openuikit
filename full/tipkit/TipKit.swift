@_exported import Foundation
#if canImport(SwiftUI)
import SwiftUI
#endif

// MARK: - Process-local runtime
//
// Isolated Linux has no Apple TipKit Core Data store and no iCloud. Eligibility,
// donations, parameters, and invalidations are process-local. App Group
// containers, URL datastores, and CloudKit containers fail closed.

enum TipKitTestingMode: Equatable, Sendable {
    case normal
    case showAll
    case hideAll
}

struct TipKitDonationRecord: Sendable {
    var date: Date
    var payload: Data
}

final class TipKitState: @unchecked Sendable {
    static let shared = TipKitState()

    private let lock = NSLock()
    private var configured = false
    private var displayFrequency = Tips.ConfigurationOption.DisplayFrequency.immediate
    private var invalidations: [String: Tips.InvalidationReason] = [:]
    private var displayCounts: [String: Int] = [:]
    private var firstDisplayDates: [String: Date] = [:]
    private var lastGlobalDisplay: Date?
    private var donations: [String: [TipKitDonationRecord]] = [:]
    private var parameters: [String: Data] = [:]
    private var testingMode: TipKitTestingMode = .normal
    private var testingShowTypes: Set<String> = []
    private var testingHideTypes: Set<String> = []
    private var statusListeners: [String: [UUID: AsyncStream<Tips.Status>.Continuation]] = [:]

    var isConfigured: Bool {
        lock.withLock { configured }
    }

    func configure(_ options: [Tips.ConfigurationOption]) throws {
        try lock.withLock {
            if configured {
                throw TipKitError.tipsDatastoreAlreadyConfigured
            }
            var frequency = Tips.ConfigurationOption.DisplayFrequency.immediate
            for option in options {
                switch option.storage {
                case .displayFrequency(let value):
                    frequency = value
                case .datastoreLocation(let value):
                    switch value.kind {
                    case .applicationDefault:
                        break
                    case .url:
                        throw TipKitError.urlDatastoreUnavailable
                    }
                case .cloudKitContainer(let value):
                    if value != nil {
                        throw TipKitError.cloudKitUnavailable
                    }
                }
            }
            displayFrequency = frequency
            configured = true
        }
    }

    func resetDatastore() {
        lock.withLock {
            invalidations.removeAll()
            displayCounts.removeAll()
            firstDisplayDates.removeAll()
            lastGlobalDisplay = nil
            donations.removeAll()
            parameters.removeAll()
        }
        emitAll()
    }

    func showAllTipsForTesting() {
        lock.withLock {
            testingMode = .showAll
            testingShowTypes.removeAll()
            testingHideTypes.removeAll()
        }
        emitAll()
    }

    func hideAllTipsForTesting() {
        lock.withLock {
            testingMode = .hideAll
            testingShowTypes.removeAll()
            testingHideTypes.removeAll()
        }
        emitAll()
    }

    func showTipsForTesting(_ typeNames: [String]) {
        lock.withLock {
            testingMode = .normal
            testingHideTypes.subtract(typeNames)
            testingShowTypes.formUnion(typeNames)
        }
        emitAll()
    }

    func hideTipsForTesting(_ typeNames: [String]) {
        lock.withLock {
            testingMode = .normal
            testingShowTypes.subtract(typeNames)
            testingHideTypes.formUnion(typeNames)
        }
        emitAll()
    }

    func invalidate(id: String, reason: Tips.InvalidationReason) {
        lock.withLock {
            invalidations[id] = reason
        }
        emit(id: id)
    }

    func resetEligibility(id: String) {
        lock.withLock {
            invalidations.removeValue(forKey: id)
            displayCounts.removeValue(forKey: id)
            firstDisplayDates.removeValue(forKey: id)
        }
        emit(id: id)
    }

    func recordDisplay(id: String) {
        let now = Date()
        lock.withLock {
            displayCounts[id, default: 0] += 1
            if firstDisplayDates[id] == nil {
                firstDisplayDates[id] = now
            }
            lastGlobalDisplay = now
        }
        emit(id: id)
    }

    func status(
        id: String,
        typeName: String,
        rules: [Tips.Rule],
        options: [any TipOption]
    ) -> Tips.Status {
        lock.withLock {
            resolvedStatus(
                id: id,
                typeName: typeName,
                rules: rules,
                options: options,
                now: Date()
            )
        }
    }

    func registerStatusListener(
        id: String,
        continuation: AsyncStream<Tips.Status>.Continuation
    ) -> UUID {
        let token = UUID()
        lock.withLock {
            var bucket = statusListeners[id] ?? [:]
            bucket[token] = continuation
            statusListeners[id] = bucket
        }
        return token
    }

    func unregisterStatusListener(id: String, token: UUID) {
        lock.withLock {
            statusListeners[id]?[token] = nil
            if statusListeners[id]?.isEmpty == true {
                statusListeners.removeValue(forKey: id)
            }
        }
    }

    func donate(eventID: String, payload: Data, date: Date, limit: Tips.DonationLimit?) {
        lock.withLock {
            var records = donations[eventID] ?? []
            records.append(TipKitDonationRecord(date: date, payload: payload))
            donations[eventID] = Self.trim(records, limit: limit, now: date)
        }
    }

    func donationRecords(eventID: String) -> [TipKitDonationRecord] {
        lock.withLock { donations[eventID] ?? [] }
    }

    func deleteDonations(eventID: String) {
        lock.withLock { donations[eventID] = [] }
    }

    func parameterValue<Value: Codable>(id: String, default defaultValue: Value, transient: Bool) -> Value {
        lock.withLock {
            if transient {
                return defaultValue
            }
            guard let data = parameters[id] else {
                return defaultValue
            }
            return (try? JSONDecoder().decode(Value.self, from: data)) ?? defaultValue
        }
    }

    func setParameterValue<Value: Codable>(id: String, value: Value, transient: Bool) {
        guard !transient else { return }
        lock.withLock {
            parameters[id] = try? JSONEncoder().encode(value)
        }
    }

    private func resolvedStatus(
        id: String,
        typeName: String,
        rules: [Tips.Rule],
        options: [any TipOption],
        now: Date
    ) -> Tips.Status {
        if testingHideTypes.contains(typeName) || testingMode == .hideAll {
            return .pending
        }
        if let reason = invalidations[id] {
            return .invalidated(reason)
        }

        let maxCount = options.compactMap { $0 as? Tips.MaxDisplayCount }.last
        let maxDuration = options.compactMap { $0 as? Tips.MaxDisplayDuration }.last
        let ignoresFrequency = options.compactMap { $0 as? Tips.IgnoresDisplayFrequency }.last?.ignores ?? false
        let count = displayCounts[id] ?? 0
        if let maxCount, count >= maxCount.value {
            invalidations[id] = .displayCountExceeded
            return .invalidated(.displayCountExceeded)
        }
        if let maxDuration, let first = firstDisplayDates[id] {
            if now.timeIntervalSince(first) >= maxDuration.value {
                invalidations[id] = .displayDurationExceeded
                return .invalidated(.displayDurationExceeded)
            }
        }

        if testingShowTypes.contains(typeName) || testingMode == .showAll {
            return .available
        }
        guard configured else { return .pending }
        if !rules.allSatisfy({ $0.evaluate() }) {
            return .pending
        }
        if !ignoresFrequency, let last = lastGlobalDisplay {
            if now.timeIntervalSince(last) < displayFrequency.minimumInterval {
                return .pending
            }
        }
        return .available
    }

    private func emit(id: String) {
        let listeners: [AsyncStream<Tips.Status>.Continuation]
        let current: Tips.Status
        (listeners, current) = lock.withLock {
            let list = Array((statusListeners[id] ?? [:]).values)
            let status = resolvedStatus(id: id, typeName: id, rules: [], options: [], now: Date())
            return (list, status)
        }
        for listener in listeners {
            listener.yield(current)
        }
    }

    private func emitAll() {
        let snapshot: [(AsyncStream<Tips.Status>.Continuation, Tips.Status)] = lock.withLock {
            statusListeners.flatMap { id, bucket in
                let status = resolvedStatus(id: id, typeName: id, rules: [], options: [], now: Date())
                return bucket.values.map { ($0, status) }
            }
        }
        for (listener, status) in snapshot {
            listener.yield(status)
        }
    }

    private static func trim(
        _ records: [TipKitDonationRecord],
        limit: Tips.DonationLimit?,
        now: Date
    ) -> [TipKitDonationRecord] {
        guard let limit else { return records }
        var filtered = records
        if let age = limit.maximumAge {
            filtered = filtered.filter { now.timeIntervalSince($0.date) <= age.seconds }
        }
        if filtered.count > limit.maximumCount {
            filtered = Array(filtered.suffix(limit.maximumCount))
        }
        return filtered
    }
}

private extension NSLock {
    func withLock<T>(_ body: () throws -> T) rethrows -> T {
        lock()
        defer { unlock() }
        return try body()
    }
}

// MARK: - TipOption

/// A type that represents the various customizations that you can make to a tip's behavior.
public protocol TipOption: Sendable {}

// MARK: - TipKitError

/// A localized tip kit error.
public struct TipKitError: Error, LocalizedError, CustomStringConvertible, Hashable, Sendable {
    enum Kind: String, Sendable {
        case invalidPredicateValueType
        case tipsDatastoreAlreadyConfigured
        case missingGroupContainerEntitlements
        case cloudKitUnavailable
        case urlDatastoreUnavailable
    }

    let kind: Kind

    init(_ kind: Kind) {
        self.kind = kind
    }

    public static let invalidPredicateValueType = TipKitError(.invalidPredicateValueType)
    public static let tipsDatastoreAlreadyConfigured = TipKitError(.tipsDatastoreAlreadyConfigured)
    public static let missingGroupContainerEntitlements = TipKitError(.missingGroupContainerEntitlements)

    @_spi(OpenUIKitHost)
    public static let cloudKitUnavailable = TipKitError(.cloudKitUnavailable)

    @_spi(OpenUIKitHost)
    public static let urlDatastoreUnavailable = TipKitError(.urlDatastoreUnavailable)

    public var errorDescription: String? {
        switch kind {
        case .invalidPredicateValueType:
            return "The predicate value type is invalid for this TipKit rule."
        case .tipsDatastoreAlreadyConfigured:
            return "The tips datastore has already been configured."
        case .missingGroupContainerEntitlements:
            return "The App Group container entitlement is missing or unavailable."
        case .cloudKitUnavailable:
            return "CloudKit tip datastores are unavailable on this Linux host."
        case .urlDatastoreUnavailable:
            return "URL tip datastores are unavailable; isolated Linux is process-local memory only."
        }
    }

    public var description: String {
        errorDescription ?? kind.rawValue
    }

    public var failureReason: String? { errorDescription }
    public var recoverySuggestion: String? { nil }
    public var helpAnchor: String? { nil }
}

// MARK: - Tips namespace

/// TipKit namespace.
@frozen public enum Tips {
    public static func configure(_ configuration: [Tips.ConfigurationOption] = []) throws {
        try TipKitState.shared.configure(configuration)
    }

    public static func resetDatastore() throws {
        TipKitState.shared.resetDatastore()
    }

    public static func showAllTipsForTesting() {
        TipKitState.shared.showAllTipsForTesting()
    }

    public static func hideAllTipsForTesting() {
        TipKitState.shared.hideAllTipsForTesting()
    }

#if canImport(SwiftUI)
    public static func showTipsForTesting(_ tips: [any Tip.Type]) {
        TipKitState.shared.showTipsForTesting(tips.map { String(reflecting: $0) })
    }

    public static func hideTipsForTesting(_ tips: [any Tip.Type]) {
        TipKitState.shared.hideTipsForTesting(tips.map { String(reflecting: $0) })
    }
#endif

    /// A type that describes the current display eligibility status for a tip.
    public enum Status: Hashable, Sendable {
        case pending
        case available
        case invalidated(Tips.InvalidationReason)
    }

    /// A type that describes why the system permanently invalidated a tip.
    public enum InvalidationReason: Hashable, Sendable {
        case actionPerformed
        case displayCountExceeded
        case displayDurationExceeded
        case tipClosed
    }

    public struct DonationLimit: Sendable {
        public let maximumCount: Int
        public let maximumAge: Tips.DonationTimeRange?

        public init(maximumCount: Int, maximumAge: Tips.DonationTimeRange? = nil) {
            self.maximumCount = maximumCount
            self.maximumAge = maximumAge
        }
    }

    public struct EmptyDonation: Codable, Hashable, Sendable {
        public init() {}

        public init(from decoder: any Decoder) throws {
            _ = decoder
        }

        public func encode(to encoder: any Encoder) throws {
            var container = encoder.singleValueContainer()
            try container.encode(true)
        }
    }

    public struct MaxDisplayCount: TipOption, Sendable {
        let value: Int

        public init(_ maxDisplayCount: Int) {
            value = maxDisplayCount
        }
    }

    public struct MaxDisplayDuration: TipOption, Sendable {
        let value: TimeInterval

        public init(_ maxDisplayDuration: TimeInterval) {
            value = maxDisplayDuration
        }
    }

    public struct IgnoresDisplayFrequency: TipOption, Sendable {
        let ignores: Bool

        public init(_ ignoresDisplayFrequency: Bool) {
            ignores = ignoresDisplayFrequency
        }
    }

    public struct ParameterOption: Hashable, Sendable {
        let isTransient: Bool

        public static var transient: Tips.ParameterOption {
            ParameterOption(isTransient: true)
        }
    }

    public struct DonationTimeRange: Hashable, Codable, Sendable {
        let seconds: TimeInterval

        init(seconds: TimeInterval) {
            self.seconds = seconds
        }

        public static var minute: Tips.DonationTimeRange { .minutes(1) }
        public static var hour: Tips.DonationTimeRange { .hours(1) }
        public static var day: Tips.DonationTimeRange { .days(1) }
        public static var week: Tips.DonationTimeRange { .weeks(1) }

        public static func minutes(_ value: Int) -> Tips.DonationTimeRange {
            DonationTimeRange(seconds: TimeInterval(value) * 60)
        }

        public static func hours(_ value: Int) -> Tips.DonationTimeRange {
            DonationTimeRange(seconds: TimeInterval(value) * 3600)
        }

        public static func days(_ value: Int) -> Tips.DonationTimeRange {
            DonationTimeRange(seconds: TimeInterval(value) * 86400)
        }

        public static func weeks(_ value: Int) -> Tips.DonationTimeRange {
            DonationTimeRange(seconds: TimeInterval(value) * 604800)
        }
    }

    public struct ConfigurationOption: Sendable {
        enum Storage: Sendable {
            case displayFrequency(DisplayFrequency)
            case datastoreLocation(DatastoreLocation)
            case cloudKitContainer(CloudKitContainer?)
        }

        let storage: Storage

        public struct CloudKitContainer: Hashable, Sendable {
            enum Kind: Hashable, Sendable {
                case automatic
                case named(String)
            }

            let kind: Kind

            public static var automatic: CloudKitContainer {
                CloudKitContainer(kind: .automatic)
            }

            public static func named(_ containerName: String) -> CloudKitContainer {
                CloudKitContainer(kind: .named(containerName))
            }
        }

        public struct DisplayFrequency: Hashable, Sendable {
            enum Kind: Hashable, Sendable {
                case immediate
                case hourly
                case daily
                case weekly
                case monthly
            }

            let kind: Kind

            public static var immediate: DisplayFrequency { DisplayFrequency(kind: .immediate) }
            public static var hourly: DisplayFrequency { DisplayFrequency(kind: .hourly) }
            public static var daily: DisplayFrequency { DisplayFrequency(kind: .daily) }
            public static var weekly: DisplayFrequency { DisplayFrequency(kind: .weekly) }
            public static var monthly: DisplayFrequency { DisplayFrequency(kind: .monthly) }

            var minimumInterval: TimeInterval {
                switch kind {
                case .immediate: return 0
                case .hourly: return 3600
                case .daily: return 86400
                case .weekly: return 604800
                case .monthly: return 2_592_000
                }
            }
        }

        public struct DatastoreLocation: Hashable, Sendable {
            enum Kind: Hashable, Sendable {
                case applicationDefault
                case url(URL)
            }

            let kind: Kind

            public static var applicationDefault: DatastoreLocation {
                DatastoreLocation(kind: .applicationDefault)
            }

            public static func url(_ url: URL) -> DatastoreLocation {
                DatastoreLocation(kind: .url(url))
            }

            public static func groupContainer(identifier: String) throws -> DatastoreLocation {
                _ = identifier
                throw TipKitError.missingGroupContainerEntitlements
            }
        }

        public static func displayFrequency(
            _ displayFrequency: DisplayFrequency
        ) -> ConfigurationOption {
            ConfigurationOption(storage: .displayFrequency(displayFrequency))
        }

        public static func datastoreLocation(
            _ storeLocation: DatastoreLocation
        ) -> ConfigurationOption {
            ConfigurationOption(storage: .datastoreLocation(storeLocation))
        }

        public static func cloudKitContainer(
            _ cloudKitContainer: CloudKitContainer?
        ) -> ConfigurationOption {
            ConfigurationOption(storage: .cloudKitContainer(cloudKitContainer))
        }
    }

    @resultBuilder
    public struct RuleBuilder {
        public static func buildExpression(_ expression: Rule) -> [Rule] { [expression] }
        public static func buildExpression(_ expression: [Rule]) -> [Rule] { expression }
        public static func buildExpression(_ expression: Rule?) -> [Rule] {
            expression.map { [$0] } ?? []
        }
        public static func buildBlock(_ components: [Rule]...) -> [Rule] {
            components.flatMap { $0 }
        }
        public static func buildOptional(_ component: [Rule]?) -> [Rule] { component ?? [] }
        public static func buildEither(first: [Rule]) -> [Rule] { first }
        public static func buildEither(second: [Rule]) -> [Rule] { second }
        public static func buildArray(_ components: [[Rule]]) -> [Rule] {
            components.flatMap { $0 }
        }
        public static func buildPartialBlock(first: [Rule]) -> [Rule] { first }
        public static func buildPartialBlock(accumulated: [Rule], next: [Rule]) -> [Rule] {
            accumulated + next
        }
    }

#if canImport(SwiftUI)
    @resultBuilder
    public struct ActionBuilder {
        public static func buildExpression(_ expression: Action) -> [Action] { [expression] }
        public static func buildExpression(_ expression: [Action]) -> [Action] { expression }
        public static func buildBlock(_ components: [Action]...) -> [Action] {
            components.flatMap { $0 }
        }
        public static func buildOptional(_ component: [Action]?) -> [Action] { component ?? [] }
        public static func buildEither(first: [Action]) -> [Action] { first }
        public static func buildEither(second: [Action]) -> [Action] { second }
        public static func buildArray(_ components: [[Action]]) -> [Action] {
            components.flatMap { $0 }
        }
        public static func buildPartialBlock(first: [Action]) -> [Action] { first }
        public static func buildPartialBlock(accumulated: [Action], next: [Action]) -> [Action] {
            accumulated + next
        }
        public static func buildLimitedAvailability(_ component: [Action]) -> [Action] { component }
        public static func buildFinalResult(_ component: [Action]) -> [Action] {
            component.enumerated().map { offset, action in
                Action(
                    id: action.id,
                    index: offset,
                    label: action.label,
                    handler: action.handler
                )
            }
        }
    }
#endif

    @resultBuilder
    public struct OptionsBuilder {
        public static func buildExpression(_ expression: any TipOption) -> [any TipOption] {
            [expression]
        }
        public static func buildExpression(_ expression: [any TipOption]) -> [any TipOption] {
            expression
        }
        public static func buildExpression(_ expression: (any TipOption)?) -> [any TipOption] {
            expression.map { [$0] } ?? []
        }
        public static func buildBlock(_ components: [any TipOption]...) -> [any TipOption] {
            components.flatMap { $0 }
        }
        public static func buildOptional(_ component: [any TipOption]?) -> [any TipOption] {
            component ?? []
        }
        public static func buildEither(first: [any TipOption]) -> [any TipOption] { first }
        public static func buildEither(second: [any TipOption]) -> [any TipOption] { second }
        public static func buildArray(_ components: [[any TipOption]]) -> [any TipOption] {
            components.flatMap { $0 }
        }
        public static func buildPartialBlock(first: [any TipOption]) -> [any TipOption] { first }
        public static func buildPartialBlock(
            accumulated: [any TipOption],
            next: [any TipOption]
        ) -> [any TipOption] {
            accumulated + next
        }
        public static func buildFinalResult(_ component: [any TipOption]) -> [any TipOption] {
            component
        }
    }

#if canImport(SwiftUI)
    @resultBuilder
    public struct GroupBuilder {
        public static func buildExpression(_ expression: any Tip) -> [any Tip] { [expression] }
        public static func buildBlock(_ components: [any Tip]...) -> [any Tip] {
            components.flatMap { $0 }
        }
        public static func buildOptional(_ component: [any Tip]?) -> [any Tip] { component ?? [] }
        public static func buildEither(first: [any Tip]) -> [any Tip] { first }
        public static func buildEither(second: [any Tip]) -> [any Tip] { second }
        public static func buildArray(_ components: [[any Tip]]) -> [any Tip] {
            components.flatMap { $0 }
        }
        public static func buildPartialBlock(first: [any Tip]) -> [any Tip] { first }
        public static func buildPartialBlock(accumulated: [any Tip], next: [any Tip]) -> [any Tip] {
            accumulated + next
        }
        public static func buildIf(_ component: [any Tip]?) -> [any Tip] { component ?? [] }
    }
#endif

    /// A condition to meet before displaying a tip.
    public struct Rule: @unchecked Sendable {
        public enum CompoundOperation: Hashable, Sendable {
            case conjunction
            case disjunction
        }

        enum Storage {
            case always
            case evaluated(() -> Bool)
            case compound(CompoundOperation, [Rule])
        }

        let storage: Storage

        public init(_ operation: CompoundOperation, _ children: [Rule]) {
            storage = .compound(operation, children)
        }

        @_spi(OpenUIKitHost)
        public static func evaluated(_ predicate: @escaping () -> Bool) -> Rule {
            Rule(storage: .evaluated(predicate))
        }

        init(storage: Storage) {
            self.storage = storage
        }

        func evaluate() -> Bool {
            switch storage {
            case .always:
                return true
            case .evaluated(let predicate):
                return predicate()
            case .compound(.conjunction, let children):
                return children.allSatisfy { $0.evaluate() }
            case .compound(.disjunction, let children):
                return children.contains { $0.evaluate() }
            }
        }
    }

#if canImport(SwiftUI)
    /// A type that describes a control associated with a tip.
    public struct Action: Identifiable, @unchecked Sendable {
        public typealias ID = String

        public let id: String
        public let index: Int?
        public let label: () -> Text
        public let handler: @MainActor () -> Void

        @preconcurrency
        nonisolated public init(
            id: String? = nil,
            title: some StringProtocol,
            perform handler: @escaping @MainActor () -> Void = {}
        ) {
            let titleString = String(title)
            self.id = id ?? titleString
            self.index = nil
            self.label = { Text(titleString) }
            self.handler = { @MainActor in handler() }
        }

        @preconcurrency
        public init(
            id: String? = nil,
            perform handler: @escaping @MainActor () -> Void = {},
            _ label: @escaping () -> Text
        ) {
            self.id = id ?? "action"
            self.index = nil
            self.label = label
            self.handler = { @MainActor in handler() }
        }

        init(
            id: String,
            index: Int?,
            label: @escaping () -> Text,
            handler: @escaping @MainActor () -> Void
        ) {
            self.id = id
            self.index = index
            self.label = label
            self.handler = { @MainActor in handler() }
        }
    }
#endif

    /// A repeatable user-defined action.
    public struct Event<DonationInfo: Codable & Sendable>: Identifiable, Sendable {
        public typealias ID = String
        public typealias Value = Tips.Event<DonationInfo>

        public let id: String
        let donationLimit: Tips.DonationLimit?

        public init(id: String) where DonationInfo == Tips.EmptyDonation {
            self.id = id
            self.donationLimit = nil
        }

        public init(id: String) {
            self.id = id
            self.donationLimit = nil
        }

        public init(id: String, donationLimit: Tips.DonationLimit) where DonationInfo == Tips.EmptyDonation {
            self.id = id
            self.donationLimit = donationLimit
        }

        public init(id: String, donationLimit: Tips.DonationLimit) {
            self.id = id
            self.donationLimit = donationLimit
        }

        public var donations: [Donation] {
            let decoder = JSONDecoder()
            return TipKitState.shared.donationRecords(eventID: id).compactMap { record in
                guard let info = try? decoder.decode(DonationInfo.self, from: record.payload) else {
                    return nil
                }
                return Donation(date: record.date, info: info)
            }
        }

        public func donate(_ donation: DonationInfo) async {
            let payload = (try? JSONEncoder().encode(donation)) ?? Data()
            TipKitState.shared.donate(
                eventID: id,
                payload: payload,
                date: Date(),
                limit: donationLimit
            )
        }

        public func sendDonation(
            _ donation: DonationInfo,
            _ completion: (() -> Void)? = nil
        ) {
            Task {
                await donate(donation)
                completion?()
            }
        }

        public func deleteDonations() async throws {
            TipKitState.shared.deleteDonations(eventID: id)
        }

        @dynamicMemberLookup
        public struct Donation: Codable, Sendable {
            public let date: Date
            let info: DonationInfo

            init(date: Date, info: DonationInfo) {
                self.date = date
                self.info = info
            }

            public init(from decoder: any Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                date = try container.decode(Date.self, forKey: .date)
                info = try container.decode(DonationInfo.self, forKey: .info)
            }

            public func encode(to encoder: any Encoder) throws {
                var container = encoder.container(keyedBy: CodingKeys.self)
                try container.encode(date, forKey: .date)
                try container.encode(info, forKey: .info)
            }

            public subscript<Value>(dynamicMember keyPath: KeyPath<DonationInfo, Value>) -> Value {
                info[keyPath: keyPath]
            }

            enum CodingKeys: String, CodingKey {
                case date
                case info
            }
        }
    }

    /// A type that monitors the state of its wrapped value to reevaluate any dependent tip rules.
    @propertyWrapper
    public struct Parameter<Value: Codable & Sendable>: Identifiable, @unchecked Sendable {
        public typealias ID = String

        public let id: String
        private let defaultValue: Value
        private let isTransient: Bool

        public var wrappedValue: Value {
            get {
                TipKitState.shared.parameterValue(
                    id: id,
                    default: defaultValue,
                    transient: isTransient
                )
            }
            nonmutating set {
                TipKitState.shared.setParameterValue(
                    id: id,
                    value: newValue,
                    transient: isTransient
                )
            }
        }

        public init(wrappedValue: Value, id: String, _ options: ParameterOption...) {
            self.id = id
            self.defaultValue = wrappedValue
            self.isTransient = options.contains(where: \.isTransient)
        }

        public init(wrappedValue: Value) {
            self.init(wrappedValue: wrappedValue, id: "parameter.\(String(describing: Value.self))")
        }
    }
}

extension Tips.Event where DonationInfo == Tips.EmptyDonation {
    public func donate() async {
        await donate(Tips.EmptyDonation())
    }

    public func sendDonation(_ completion: (() -> Void)? = nil) {
        sendDonation(Tips.EmptyDonation(), completion)
    }
}

extension Tips {
    @_spi(OpenUIKitHost)
    public static func eligibilityStatus(
        id: String,
        typeName: String = "",
        rules: [Rule] = [],
        options: [any TipOption] = []
    ) -> Status {
        TipKitState.shared.status(
            id: id,
            typeName: typeName,
            rules: rules,
            options: options
        )
    }

    @_spi(OpenUIKitHost)
    public static func invalidateEligibility(
        id: String,
        reason: InvalidationReason
    ) {
        TipKitState.shared.invalidate(id: id, reason: reason)
    }

    @_spi(OpenUIKitHost)
    public static func resetEligibility(id: String) {
        TipKitState.shared.resetEligibility(id: id)
    }
}

#if canImport(SwiftUI)

// MARK: - Tip protocol

/// A type that sets a tip's content, as well as the conditions for when it displays.
public protocol Tip: Identifiable, Sendable where ID == String {
    var id: String { get }
    var title: Text { get }
    var message: Text? { get }
    var image: Image? { get }
    @Tips.ActionBuilder var actions: [Self.Action] { get }
    @Tips.RuleBuilder var rules: [Self.Rule] { get }
    @Tips.OptionsBuilder var options: [any TipOption] { get }
}

extension Tip {
    public typealias Status = Tips.Status
    public typealias InvalidationReason = Tips.InvalidationReason
    public typealias Action = Tips.Action
    public typealias Rule = Tips.Rule
    public typealias Event = Tips.Event
    public typealias Option = TipOption
    public typealias IgnoresDisplayFrequency = Tips.IgnoresDisplayFrequency
    public typealias MaxDisplayCount = Tips.MaxDisplayCount
    public typealias MaxDisplayDuration = Tips.MaxDisplayDuration

    public var id: String { String(reflecting: Self.self) }
    public var message: Text? { nil }
    public var image: Image? { nil }
    public var actions: [Self.Action] { [] }
    public var rules: [Self.Rule] { [] }
    public var options: [any TipOption] { [] }

    public var status: Self.Status {
        TipKitState.shared.status(
            id: id,
            typeName: String(reflecting: Self.self),
            rules: rules,
            options: options
        )
    }

    public var shouldDisplay: Bool { status == .available }

    public var statusUpdates: AsyncStream<Self.Status> {
        let currentID = id
        let typeName = String(reflecting: Self.self)
        let currentRules = rules
        let currentOptions = options
        return AsyncStream { continuation in
            let token = TipKitState.shared.registerStatusListener(
                id: currentID,
                continuation: continuation
            )
            continuation.yield(
                TipKitState.shared.status(
                    id: currentID,
                    typeName: typeName,
                    rules: currentRules,
                    options: currentOptions
                )
            )
            continuation.onTermination = { _ in
                TipKitState.shared.unregisterStatusListener(id: currentID, token: token)
            }
        }
    }

    public var shouldDisplayUpdates: AsyncMapSequence<AsyncStream<Self.Status>, Bool> {
        statusUpdates.map { $0 == .available }
    }

    public func invalidate(reason: Self.InvalidationReason) {
        TipKitState.shared.invalidate(id: id, reason: reason)
    }

    public func resetEligibility() async {
        TipKitState.shared.resetEligibility(id: id)
    }
}

/// A type-erased tip value.
public struct AnyTip: Tip, @unchecked Sendable {
    public typealias ID = String

    private let base: any Tip

    public init(_ tip: any Tip) {
        base = tip
    }

    public init(erasing tip: any Tip) {
        base = tip
    }

    public var id: String { base.id }
    public var title: Text { base.title }
    public var message: Text? { base.message }
    public var image: Image? { base.image }
    public var actions: [Tips.Action] { base.actions }
    public var rules: [Tips.Rule] { base.rules }
    public var options: [any TipOption] { base.options }

    public var status: Tips.Status { base.status }
    public var shouldDisplay: Bool { base.shouldDisplay }
    public var statusUpdates: AsyncStream<Tips.Status> { base.statusUpdates }
    public var shouldDisplayUpdates: AsyncMapSequence<AsyncStream<Tips.Status>, Bool> {
        base.shouldDisplayUpdates
    }

    public func invalidate(reason: Tips.InvalidationReason) {
        base.invalidate(reason: reason)
    }

    public func resetEligibility() async {
        await base.resetEligibility()
    }
}

#endif
