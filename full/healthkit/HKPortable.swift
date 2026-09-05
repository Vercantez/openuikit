import Foundation

/// Linux comparison operator used in place of `NSComparisonPredicate.Operator`,
/// which is deprecated/unavailable in swift-corelibs-foundation. Raw values
/// match Apple's `NSComparisonPredicate.Operator` (`equalTo` is 4).
public enum HKPredicateOperator: UInt, Sendable, Hashable {
    case lessThan = 0
    case lessThanOrEqualTo = 1
    case greaterThan = 2
    case greaterThanOrEqualTo = 3
    case equalTo = 4
    case notEqualTo = 5
    case matches = 6
    case like = 7
    case beginsWith = 8
    case endsWith = 9
    case `in` = 10
    case customSelector = 11
    case contains = 12
    case between = 13
}

func hkCompare(_ lhs: Double, _ op: HKPredicateOperator, _ rhs: Double) -> Bool {
    switch op {
    case .lessThan: return lhs < rhs
    case .lessThanOrEqualTo: return lhs <= rhs
    case .greaterThan: return lhs > rhs
    case .greaterThanOrEqualTo: return lhs >= rhs
    case .equalTo: return lhs == rhs
    case .notEqualTo: return lhs != rhs
    default: return false
    }
}

func hkError(
    _ code: HKError.Code,
    reason: String
) -> NSError {
    NSError(
        domain: HKErrorDomain,
        code: code.rawValue,
        userInfo: [NSLocalizedDescriptionKey: reason]
    )
}

/// Isolated-host stand-in for CoreLocation.CLLocation. The sealed gate cannot
/// import CoreLocation; workout-route APIs use this type instead of inventing
/// a live GPS feed.
open class CLLocation: NSObject, NSCopying, NSSecureCoding, @unchecked Sendable {
    public static var supportsSecureCoding: Bool { true }
    public var latitude: Double
    public var longitude: Double
    public var altitude: Double
    public var horizontalAccuracy: Double
    public var verticalAccuracy: Double
    public var timestamp: Date

    public init(
        latitude: Double,
        longitude: Double,
        altitude: Double = 0,
        timestamp: Date = Date(),
        horizontalAccuracy: Double = 0,
        verticalAccuracy: Double = 0
    ) {
        self.latitude = latitude
        self.longitude = longitude
        self.altitude = altitude
        self.timestamp = timestamp
        self.horizontalAccuracy = horizontalAccuracy
        self.verticalAccuracy = verticalAccuracy
        super.init()
    }

    public required init?(coder: NSCoder) {
        self.latitude = coder.decodeDouble(forKey: "latitude")
        self.longitude = coder.decodeDouble(forKey: "longitude")
        self.altitude = coder.decodeDouble(forKey: "altitude")
        self.horizontalAccuracy = 0
        self.verticalAccuracy = 0
        self.timestamp = Date()
        super.init()
    }

    public func encode(with coder: NSCoder) {
        coder.encode(latitude, forKey: "latitude")
        coder.encode(longitude, forKey: "longitude")
        coder.encode(altitude, forKey: "altitude")
    }

    public func copy(with zone: NSZone? = nil) -> Any {
        CLLocation(
            latitude: latitude,
            longitude: longitude,
            altitude: altitude,
            timestamp: timestamp,
            horizontalAccuracy: horizontalAccuracy,
            verticalAccuracy: verticalAccuracy
        )
    }
}

/// Documented test hooks and the on-disk local Health store.
///
/// - Directory: `Documents/OpenUIKitHealthStore` unless `_setStoreDirectory` is used.
/// - `_installAuthorizationHandler` decides `requestAuthorization` outcomes.
///   Without it, the request fail-closes to `.sharingDenied` for each type.
/// - `_setAuthorization` writes the per-type share/read map used by save/query.
/// - `_setCharacteristics` writes date-of-birth / sex / blood type / skin /
///   wheelchair / move-mode for `HKHealthStore` getters.
public enum HKHealthStorePortable {
    public typealias AuthorizationHandler = (Set<HKSampleType>?, Set<HKObjectType>?) -> HKAuthorizationStatus

    fileprivate static let lock = NSRecursiveLock()
    fileprivate static var directoryOverride: URL?
    fileprivate static var authorizationHandler: AuthorizationHandler?
    fileprivate static var cachedState: HKLocalStoreState?
    fileprivate static var stoppedQueries = Set<ObjectIdentifier>()
    fileprivate static var observerQueries: [ObjectIdentifier: HKObserverQuery] = [:]
    fileprivate static var routeLocations: [UUID: [CLLocation]] = [:]
    fileprivate static var workoutSampleIDs: [UUID: Set<UUID>] = [:]
    fileprivate static var nextAnchor: Int = 1

    public static var storeDirectory: URL {
        lock.lock()
        defer { lock.unlock() }
        if let directoryOverride { return directoryOverride }
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        return docs.appendingPathComponent("OpenUIKitHealthStore", isDirectory: true)
    }

    public static func _setStoreDirectory(_ url: URL?) {
        lock.lock()
        directoryOverride = url
        cachedState = nil
        lock.unlock()
    }

    public static func _installAuthorizationHandler(_ handler: AuthorizationHandler?) {
        lock.lock()
        authorizationHandler = handler
        lock.unlock()
    }

    public static func _reset() {
        lock.lock()
        let dir = directoryOverride
            ?? FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?
            .appendingPathComponent("OpenUIKitHealthStore", isDirectory: true)
        cachedState = nil
        authorizationHandler = nil
        stoppedQueries.removeAll()
        observerQueries.removeAll()
        routeLocations.removeAll()
        workoutSampleIDs.removeAll()
        nextAnchor = 1
        lock.unlock()
        if let dir {
            try? FileManager.default.removeItem(at: dir)
        }
    }

    public static func _setAuthorization(
        for type: HKObjectType,
        share: HKAuthorizationStatus,
        read: HKAuthorizationStatus
    ) {
        mutate { state in
            state.share[type.identifier] = share.rawValue
            state.read[type.identifier] = read.rawValue
        }
    }

    public static func _setCharacteristics(
        dateOfBirth: DateComponents? = nil,
        biologicalSex: HKBiologicalSex = .notSet,
        bloodType: HKBloodType = .notSet,
        fitzpatrickSkinType: HKFitzpatrickSkinType = .notSet,
        wheelchairUse: HKWheelchairUse = .notSet,
        activityMoveMode: HKActivityMoveMode = .activeEnergy
    ) {
        mutate { state in
            if let dateOfBirth {
                state.birthYear = dateOfBirth.year
                state.birthMonth = dateOfBirth.month
                state.birthDay = dateOfBirth.day
            }
            state.biologicalSex = biologicalSex.rawValue
            state.bloodType = bloodType.rawValue
            state.fitzpatrickSkinType = fitzpatrickSkinType.rawValue
            state.wheelchairUse = wheelchairUse.rawValue
            state.activityMoveMode = activityMoveMode.rawValue
        }
    }

    public static func _setRouteLocations(_ locations: [CLLocation], for route: HKWorkoutRoute) {
        lock.lock()
        routeLocations[route.uuid] = locations
        lock.unlock()
    }

    static func authorizationHandlerLocked() -> AuthorizationHandler? {
        lock.lock()
        defer { lock.unlock() }
        return authorizationHandler
    }

    static func loadState() -> HKLocalStoreState {
        lock.lock()
        defer { lock.unlock() }
        if let cachedState { return cachedState }
        let state = HKLocalStoreState.load(from: storeDirectoryUnlocked())
        cachedState = state
        nextAnchor = max(nextAnchor, state.nextAnchor)
        return state
    }

    static func mutate(_ body: (inout HKLocalStoreState) -> Void) {
        lock.lock()
        var state = cachedState ?? HKLocalStoreState.load(from: storeDirectoryUnlocked())
        body(&state)
        state.nextAnchor = max(state.nextAnchor, nextAnchor)
        cachedState = state
        let dir = storeDirectoryUnlocked()
        lock.unlock()
        state.save(to: dir)
    }

    static func markStopped(_ query: HKQuery) {
        lock.lock()
        stoppedQueries.insert(ObjectIdentifier(query))
        observerQueries.removeValue(forKey: ObjectIdentifier(query))
        lock.unlock()
    }

    static func isStopped(_ query: HKQuery) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return stoppedQueries.contains(ObjectIdentifier(query))
    }

    static func registerObserver(_ query: HKObserverQuery) {
        lock.lock()
        observerQueries[ObjectIdentifier(query)] = query
        lock.unlock()
    }

    static func activeObservers() -> [HKObserverQuery] {
        lock.lock()
        defer { lock.unlock() }
        return Array(observerQueries.values)
    }

    static func locations(for uuid: UUID) -> [CLLocation] {
        lock.lock()
        defer { lock.unlock() }
        return routeLocations[uuid] ?? []
    }

    static func associate(sampleIDs: [UUID], with workout: UUID) {
        lock.lock()
        var set = workoutSampleIDs[workout] ?? []
        sampleIDs.forEach { set.insert($0) }
        workoutSampleIDs[workout] = set
        lock.unlock()
    }

    static func sampleIDs(forWorkout workout: UUID) -> Set<UUID> {
        lock.lock()
        defer { lock.unlock() }
        return workoutSampleIDs[workout] ?? []
    }

    private static func storeDirectoryUnlocked() -> URL {
        if let directoryOverride { return directoryOverride }
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        return docs.appendingPathComponent("OpenUIKitHealthStore", isDirectory: true)
    }
}

struct HKLocalStoreState: Codable {
    var share: [String: Int] = [:]
    var read: [String: Int] = [:]
    var samples: [HKStoredSample] = []
    var deleted: [HKStoredDeleted] = []
    var summaries: [HKStoredSummary] = []
    var nextAnchor: Int = 1
    var birthYear: Int?
    var birthMonth: Int?
    var birthDay: Int?
    var biologicalSex: Int = 0
    var bloodType: Int = 0
    var fitzpatrickSkinType: Int = 0
    var wheelchairUse: Int = 0
    var activityMoveMode: Int = 1

    static func load(from directory: URL) -> HKLocalStoreState {
        let url = directory.appendingPathComponent("store.json")
        guard let data = try? Data(contentsOf: url),
              let state = try? JSONDecoder().decode(HKLocalStoreState.self, from: data)
        else {
            return HKLocalStoreState()
        }
        return state
    }

    func save(to directory: URL) {
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let url = directory.appendingPathComponent("store.json")
        if let data = try? JSONEncoder().encode(self) {
            try? data.write(to: url, options: .atomic)
        }
    }

    func shareStatus(for identifier: String) -> HKAuthorizationStatus {
        HKAuthorizationStatus(rawValue: share[identifier] ?? 0) ?? .notDetermined
    }

    func readStatus(for identifier: String) -> HKAuthorizationStatus {
        HKAuthorizationStatus(rawValue: read[identifier] ?? 0) ?? .notDetermined
    }
}

struct HKStoredDeleted: Codable {
    var uuid: String
    var metadata: [String: String]
}

struct HKStoredSummary: Codable {
    var year: Int
    var month: Int
    var day: Int
    var activeEnergy: Double
    var exerciseMinutes: Double
    var standHours: Double
    var moveTimeMinutes: Double
    var moveMode: Int
    var paused: Bool
}

struct HKStoredSample: Codable {
    var kind: String
    var uuid: String
    var type: String
    var start: Double
    var end: Double
    var unit: String?
    var value: Double?
    var categoryValue: Int?
    var workoutActivity: UInt?
    var duration: Double?
    var energy: Double?
    var distance: Double?
    var sourceName: String
    var sourceBundle: String
    var deviceName: String?
    var metadata: [String: String]
    var correlationChildren: [String]
    var anchor: Int
}

func hkEvaluatePredicate(_ predicate: NSPredicate?, object: Any) -> Bool {
    guard let predicate else { return true }
    return predicate.evaluate(with: object)
}

func hkDateComponentsMatch(_ lhs: DateComponents, _ rhs: DateComponents) -> Bool {
    (lhs.year == nil || lhs.year == rhs.year)
        && (lhs.month == nil || lhs.month == rhs.month)
        && (lhs.day == nil || lhs.day == rhs.day)
}

extension NSNotification.Name {
    public static let HKUserPreferencesDidChange = NSNotification.Name("HKUserPreferencesDidChange")
}
