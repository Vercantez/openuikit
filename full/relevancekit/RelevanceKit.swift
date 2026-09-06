@_exported import Foundation

/// Linux starting point for Apple's public `RelevanceKit` module.
///
/// Apple documents that Smart Stack suggestions driven by these APIs take
/// effect only on watchOS; calling the API on other platforms has no widget
/// effect. This port stores the documented value-type clues and never talks to
/// WidgetKit, HealthKit, location daemons, or headphone hardware.
///
/// `CoreLocation.CLRegion` and `MapKit.MKPointOfInterestCategory` are owned by
/// other modules and are omitted (unavailable) rather than replaced with
/// lookalikes.
public struct RelevantContext: Equatable, Hashable, Sendable {
    enum Payload: Equatable, Hashable, Sendable {
        case exactDate(Date)
        case dateRange(start: Date, end: Date)
        case datedExact(Date, DateKind)
        case datedInterval(DateInterval, DateKind)
        case datedRange(ClosedRange<Date>, DateKind)
        case inferredLocation(InferredLocation)
        case sleep(SleepCondition)
        case fitness(FitnessCondition)
        case headphones(HeadphonesCondition)
    }

    let payload: Payload

    /// Tells the system a widget is relevant at a specific date.
    public static func date(_ exact: Date) -> RelevantContext {
        RelevantContext(payload: .exactDate(exact))
    }

    /// Tells the system a widget is relevant between two dates.
    ///
    /// Deprecated on Apple platforms in favor of `date(interval:kind:)` and
    /// `date(range:kind:)`. Bounds are stored as given; this port does not
    /// swap an inverted `from`/`to` pair because Apple's behavior is unobserved.
    public static func date(from: Date, to: Date) -> RelevantContext {
        RelevantContext(payload: .dateRange(start: from, end: to))
    }

    /// Tells the system a widget is relevant at a specific date and provides
    /// an additional contextual hint.
    public static func date(_ exact: Date, kind: DateKind) -> RelevantContext {
        RelevantContext(payload: .datedExact(exact, kind))
    }

    /// Tells the system a widget is relevant for a time interval and provides
    /// an additional contextual hint.
    public static func date(interval: DateInterval, kind: DateKind) -> RelevantContext {
        RelevantContext(payload: .datedInterval(interval, kind))
    }

    /// Tells the system a widget is relevant for a known date range and
    /// provides an additional contextual hint.
    public static func date(range: ClosedRange<Date>, kind: DateKind) -> RelevantContext {
        RelevantContext(payload: .datedRange(range, kind))
    }

    /// Tells the system a widget is relevant at a person's inferred location.
    ///
    /// Construction stores the clue. Linux has no location daemon, so this
    /// never infers a live place and never affects a Smart Stack.
    public static func location(inferred: InferredLocation) -> RelevantContext {
        RelevantContext(payload: .inferredLocation(inferred))
    }

    /// Tells the system a widget is relevant because of a person's sleep schedule.
    ///
    /// Construction stores the clue. Linux has no HealthKit sleep-analysis
    /// authorization or sleep schedule daemon.
    public static func sleep(_ condition: SleepCondition) -> RelevantContext {
        RelevantContext(payload: .sleep(condition))
    }

    /// Tells the system a widget is relevant because of a person's fitness activity.
    ///
    /// Construction stores the clue. Linux has no HealthKit workout or
    /// activity-ring data.
    public static func fitness(_ condition: FitnessCondition) -> RelevantContext {
        RelevantContext(payload: .fitness(condition))
    }

    /// Tells the system a widget is relevant when a person's headphones are connected.
    ///
    /// Construction stores the supplied condition. Linux does not probe
    /// headphone hardware; passing `.connected` does not mean headphones are attached.
    public static func hardware(headphones: HeadphonesCondition) -> RelevantContext {
        RelevantContext(payload: .headphones(headphones))
    }
}

extension RelevantContext {
    /// Values that represent a person's typical bedtime or wakeup time.
    public struct SleepCondition: Equatable, Hashable, Sendable {
        let code: UInt8

        init(code: UInt8) {
            self.code = code
        }

        /// A timespan close to when a person typically wakes up.
        public static let wakeup = SleepCondition(code: 1)

        /// A timespan close to when a person typically goes to bed.
        public static let bedtime = SleepCondition(code: 2)
    }

    /// Values that represent a person's fitness activity.
    public struct FitnessCondition: Equatable, Hashable, Sendable {
        let code: UInt8

        init(code: UInt8) {
            self.code = code
        }

        /// A person is actively working out.
        public static let workoutActive = FitnessCondition(code: 1)

        /// A person needs to complete their activity rings.
        public static let activityRingsIncomplete = FitnessCondition(code: 2)
    }

    /// A structure with values for a person's inferred home, work, school, and commute locations.
    public struct InferredLocation: Equatable, Hashable, Sendable {
        let code: UInt8

        init(code: UInt8) {
            self.code = code
        }

        /// A person's inferred home location.
        public static let home = InferredLocation(code: 1)

        /// A person's inferred work location.
        public static let work = InferredLocation(code: 2)

        /// A person's inferred school location.
        public static let school = InferredLocation(code: 3)

        /// A person's commute between two inferred locations.
        public static let commute = InferredLocation(code: 4)
    }

    /// A structure that indicates whether a person's headphones are connected.
    public struct HeadphonesCondition: Equatable, Hashable, Sendable {
        let code: UInt8

        init(code: UInt8) {
            self.code = code
        }

        /// A person's headphones are connected to the device.
        public static let connected = HeadphonesCondition(code: 1)
    }

    /// Values the system uses as additional context for time-based relevance clues.
    public struct DateKind: Equatable, Hashable, Sendable {
        let code: UInt8

        init(code: UInt8) {
            self.code = code
        }

        /// A hint that tells the system to treat a widget with slightly lower
        /// priority because it displays content and doesn't require an action.
        public static let informational = DateKind(code: 1)

        /// A hint that tells the system to treat a widget with default priority.
        public static let `default` = DateKind(code: 2)

        /// A hint that tells the system to treat a widget with increased priority
        /// because it displays important content or requires action.
        public static let scheduled = DateKind(code: 3)
    }
}

/// Isolated-host inspection of stored payload. These symbols are not part of
/// Apple's public RelevanceKit surface.
@_spi(OpenUIKitHost)
public enum RelevantContextHostKind: Equatable, Sendable {
    case exactDate
    case dateRange
    case datedExact
    case datedInterval
    case datedRange
    case inferredLocation
    case sleep
    case fitness
    case headphones
}

extension RelevantContext {
    @_spi(OpenUIKitHost)
    public var hostKind: RelevantContextHostKind {
        switch payload {
        case .exactDate: return .exactDate
        case .dateRange: return .dateRange
        case .datedExact: return .datedExact
        case .datedInterval: return .datedInterval
        case .datedRange: return .datedRange
        case .inferredLocation: return .inferredLocation
        case .sleep: return .sleep
        case .fitness: return .fitness
        case .headphones: return .headphones
        }
    }

    @_spi(OpenUIKitHost)
    public var hostExactDate: Date? {
        switch payload {
        case .exactDate(let date), .datedExact(let date, _):
            return date
        default:
            return nil
        }
    }

    @_spi(OpenUIKitHost)
    public var hostRangeStart: Date? {
        switch payload {
        case .dateRange(let start, _):
            return start
        case .datedRange(let range, _):
            return range.lowerBound
        case .datedInterval(let interval, _):
            return interval.start
        default:
            return nil
        }
    }

    @_spi(OpenUIKitHost)
    public var hostRangeEnd: Date? {
        switch payload {
        case .dateRange(_, let end):
            return end
        case .datedRange(let range, _):
            return range.upperBound
        case .datedInterval(let interval, _):
            return interval.end
        default:
            return nil
        }
    }

    @_spi(OpenUIKitHost)
    public var hostDateInterval: DateInterval? {
        if case .datedInterval(let interval, _) = payload {
            return interval
        }
        return nil
    }

    @_spi(OpenUIKitHost)
    public var hostClosedRange: ClosedRange<Date>? {
        if case .datedRange(let range, _) = payload {
            return range
        }
        return nil
    }

    @_spi(OpenUIKitHost)
    public var hostDateKind: DateKind? {
        switch payload {
        case .datedExact(_, let kind),
             .datedInterval(_, let kind),
             .datedRange(_, let kind):
            return kind
        default:
            return nil
        }
    }

    @_spi(OpenUIKitHost)
    public var hostSleepCondition: SleepCondition? {
        if case .sleep(let condition) = payload {
            return condition
        }
        return nil
    }

    @_spi(OpenUIKitHost)
    public var hostFitnessCondition: FitnessCondition? {
        if case .fitness(let condition) = payload {
            return condition
        }
        return nil
    }

    @_spi(OpenUIKitHost)
    public var hostInferredLocation: InferredLocation? {
        if case .inferredLocation(let location) = payload {
            return location
        }
        return nil
    }

    @_spi(OpenUIKitHost)
    public var hostHeadphonesCondition: HeadphonesCondition? {
        if case .headphones(let condition) = payload {
            return condition
        }
        return nil
    }
}
