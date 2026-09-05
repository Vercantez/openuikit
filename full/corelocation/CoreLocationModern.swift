@_exported import Foundation

/// Apple's Swift overlay aliases `CLMonitor.Event.State` to this imported
/// C enum. Raw values follow the pinned `dotnet/macios` `CLMonitoringState`.
public enum __CLMonitoringState: UInt, Hashable, Sendable {
  case unknown = 0
  case satisfied = 1
  case unsatisfied = 2
  case unmonitored = 3
}

public protocol CLCondition: Decodable, Encodable, Sendable {}

public struct CLLocationUpdate: Sendable {
  public enum LiveConfiguration: Hashable, Sendable {
    case `default`
    case automotiveNavigation
    case otherNavigation
    case fitness
    case airborne

    public static func == (
      a: CLLocationUpdate.LiveConfiguration,
      b: CLLocationUpdate.LiveConfiguration
    ) -> Bool {
      switch (a, b) {
      case (.default, .default),
        (.automotiveNavigation, .automotiveNavigation),
        (.otherNavigation, .otherNavigation),
        (.fitness, .fitness),
        (.airborne, .airborne):
        return true
      default:
        return false
      }
    }

    public func hash(into hasher: inout Hasher) {
      hasher.combine(discriminator)
    }

    public var hashValue: Int {
      var hasher = Hasher()
      hash(into: &hasher)
      return hasher.finalize()
    }

    private var discriminator: Int {
      switch self {
      case .default: 0
      case .automotiveNavigation: 1
      case .otherNavigation: 2
      case .fitness: 3
      case .airborne: 4
      }
    }
  }

  public let location: CLLocation?
  public let isStationary: Bool
  public var stationary: Bool { isStationary }
  public let authorizationDenied: Bool
  public let authorizationDeniedGlobally: Bool
  public let authorizationRestricted: Bool
  public let insufficientlyInUse: Bool
  public let locationUnavailable: Bool
  public let accuracyLimited: Bool
  public let serviceSessionRequired: Bool
  public let authorizationRequestInProgress: Bool

  @_spi(OpenUIKitHost)
  public init(
    location: CLLocation?,
    isStationary: Bool = false,
    authorizationDenied: Bool = false,
    authorizationDeniedGlobally: Bool = false,
    authorizationRestricted: Bool = false,
    insufficientlyInUse: Bool = false,
    locationUnavailable: Bool = false,
    accuracyLimited: Bool = false,
    serviceSessionRequired: Bool = false,
    authorizationRequestInProgress: Bool = false
  ) {
    self.location = location
    self.isStationary = isStationary
    self.authorizationDenied = authorizationDenied
    self.authorizationDeniedGlobally = authorizationDeniedGlobally
    self.authorizationRestricted = authorizationRestricted
    self.insufficientlyInUse = insufficientlyInUse
    self.locationUnavailable = locationUnavailable
    self.accuracyLimited = accuracyLimited
    self.serviceSessionRequired = serviceSessionRequired
    self.authorizationRequestInProgress = authorizationRequestInProgress
  }

  public static func liveUpdates(
    _ configuration: CLLocationUpdate.LiveConfiguration = .default
  ) -> CLLocationUpdate.Updates {
    _ = configuration
    return Updates()
  }

  public struct Updates: AsyncSequence, Sendable {
    public typealias Element = CLLocationUpdate
    public typealias AsyncIterator = Iterator

    public func makeAsyncIterator() -> Iterator {
      Iterator()
    }

    public struct Iterator: AsyncIteratorProtocol, Sendable {
      public typealias Element = CLLocationUpdate.Updates.Element
      private var emitted = false

      public mutating func next() async throws -> CLLocationUpdate.Updates.Element? {
        if emitted { return nil }
        emitted = true
        return CLLocationUpdate(
          location: nil,
          authorizationDenied: true,
          locationUnavailable: true
        )
      }
    }
  }
}

private final class CLInvalidationFlag: @unchecked Sendable {
  private let lock = NSLock()
  private var value = false

  func mark() {
    lock.lock()
    value = true
    lock.unlock()
  }

  func isSet() -> Bool {
    lock.lock()
    defer { lock.unlock() }
    return value
  }
}

public final class CLServiceSession: Sendable {
  public enum AuthorizationRequirement: Hashable, Sendable {
    case none
    case whenInUse
    case always

    public static func == (
      a: CLServiceSession.AuthorizationRequirement,
      b: CLServiceSession.AuthorizationRequirement
    ) -> Bool {
      switch (a, b) {
      case (.none, .none), (.whenInUse, .whenInUse), (.always, .always):
        return true
      default:
        return false
      }
    }

    public func hash(into hasher: inout Hasher) {
      hasher.combine(discriminator)
    }

    public var hashValue: Int {
      var hasher = Hasher()
      hash(into: &hasher)
      return hasher.finalize()
    }

    private var discriminator: Int {
      switch self {
      case .none: 0
      case .whenInUse: 1
      case .always: 2
      }
    }
  }

  public struct Diagnostic: Sendable {
    public let authorizationDenied: Bool
    public let authorizationDeniedGlobally: Bool
    public let authorizationRestricted: Bool
    public let insufficientlyInUse: Bool
    public let fullAccuracyDenied: Bool
    public let alwaysAuthorizationDenied: Bool
    public let serviceSessionRequired: Bool
    public let authorizationRequestInProgress: Bool

    @_spi(OpenUIKitHost)
    public init(
      authorizationDenied: Bool = true,
      authorizationDeniedGlobally: Bool = false,
      authorizationRestricted: Bool = false,
      insufficientlyInUse: Bool = false,
      fullAccuracyDenied: Bool = false,
      alwaysAuthorizationDenied: Bool = false,
      serviceSessionRequired: Bool = false,
      authorizationRequestInProgress: Bool = false
    ) {
      self.authorizationDenied = authorizationDenied
      self.authorizationDeniedGlobally = authorizationDeniedGlobally
      self.authorizationRestricted = authorizationRestricted
      self.insufficientlyInUse = insufficientlyInUse
      self.fullAccuracyDenied = fullAccuracyDenied
      self.alwaysAuthorizationDenied = alwaysAuthorizationDenied
      self.serviceSessionRequired = serviceSessionRequired
      self.authorizationRequestInProgress = authorizationRequestInProgress
    }
  }

  public final class Diagnostics: AsyncSequence, Sendable {
    public typealias Element = CLServiceSession.Diagnostic
    public typealias AsyncIterator = Iterator
    private let invalidated: @Sendable () -> Bool

    fileprivate init(invalidated: @escaping @Sendable () -> Bool) {
      self.invalidated = invalidated
    }

    public func makeAsyncIterator() -> Iterator {
      Iterator(invalidated: invalidated)
    }

    public struct Iterator: AsyncIteratorProtocol, Sendable {
      public typealias Element = CLServiceSession.Diagnostics.Element
      private let invalidated: @Sendable () -> Bool
      private var emitted = false

      fileprivate init(invalidated: @escaping @Sendable () -> Bool) {
        self.invalidated = invalidated
      }

      public mutating func next() async throws -> CLServiceSession.Diagnostics.Element? {
        if emitted || invalidated() { return nil }
        emitted = true
        return Diagnostic()
      }
    }
  }

  private let invalidation = CLInvalidationFlag()
  public let diagnostics: Diagnostics

  public init(authorization: CLServiceSession.AuthorizationRequirement) {
    _ = authorization
    let flag = invalidation
    diagnostics = Diagnostics(invalidated: { flag.isSet() })
  }

  public init(
    authorization: CLServiceSession.AuthorizationRequirement,
    fullAccuracyPurposeKey: String
  ) {
    _ = authorization
    _ = fullAccuracyPurposeKey
    let flag = invalidation
    diagnostics = Diagnostics(invalidated: { flag.isSet() })
  }

  public func invalidate() {
    invalidation.mark()
  }
}

public final class CLBackgroundActivitySession: Sendable {
  public struct Diagnostic: Sendable {
    public let authorizationDenied: Bool
    public let authorizationDeniedGlobally: Bool
    public let authorizationRestricted: Bool
    public let insufficientlyInUse: Bool
    public let serviceSessionRequired: Bool
    public let authorizationRequestInProgress: Bool

    @_spi(OpenUIKitHost)
    public init(
      authorizationDenied: Bool = true,
      authorizationDeniedGlobally: Bool = false,
      authorizationRestricted: Bool = false,
      insufficientlyInUse: Bool = false,
      serviceSessionRequired: Bool = false,
      authorizationRequestInProgress: Bool = false
    ) {
      self.authorizationDenied = authorizationDenied
      self.authorizationDeniedGlobally = authorizationDeniedGlobally
      self.authorizationRestricted = authorizationRestricted
      self.insufficientlyInUse = insufficientlyInUse
      self.serviceSessionRequired = serviceSessionRequired
      self.authorizationRequestInProgress = authorizationRequestInProgress
    }
  }

  public final class Diagnostics: AsyncSequence, Sendable {
    public typealias Element = CLBackgroundActivitySession.Diagnostic
    public typealias AsyncIterator = Iterator
    private let invalidated: @Sendable () -> Bool

    fileprivate init(invalidated: @escaping @Sendable () -> Bool) {
      self.invalidated = invalidated
    }

    public func makeAsyncIterator() -> Iterator {
      Iterator(invalidated: invalidated)
    }

    public struct Iterator: AsyncIteratorProtocol, Sendable {
      public typealias Element = CLBackgroundActivitySession.Diagnostics.Element
      private let invalidated: @Sendable () -> Bool
      private var emitted = false

      fileprivate init(invalidated: @escaping @Sendable () -> Bool) {
        self.invalidated = invalidated
      }

      public mutating func next() async throws -> CLBackgroundActivitySession.Diagnostics.Element? {
        if emitted || invalidated() { return nil }
        emitted = true
        return Diagnostic()
      }
    }
  }

  private let invalidation = CLInvalidationFlag()
  public let diagnostics: Diagnostics

  public init() {
    let flag = invalidation
    diagnostics = Diagnostics(invalidated: { flag.isSet() })
  }

  public func invalidate() {
    invalidation.mark()
  }
}

public actor CLMonitor {
  public struct BeaconIdentityCondition: CLCondition, Sendable {
    public let uuid: UUID
    public let major: UInt16?
    public let minor: UInt16?

    public init(uuid: UUID) {
      self.uuid = uuid
      self.major = nil
      self.minor = nil
    }

    public init(uuid: UUID, major: UInt16) {
      self.uuid = uuid
      self.major = major
      self.minor = nil
    }

    public init(uuid: UUID, major: UInt16, minor: UInt16) {
      self.uuid = uuid
      self.major = major
      self.minor = minor
    }

    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: CodingKeys.self)
      uuid = try container.decode(UUID.self, forKey: .uuid)
      major = try container.decodeIfPresent(UInt16.self, forKey: .major)
      minor = try container.decodeIfPresent(UInt16.self, forKey: .minor)
    }

    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: CodingKeys.self)
      try container.encode(uuid, forKey: .uuid)
      try container.encodeIfPresent(major, forKey: .major)
      try container.encodeIfPresent(minor, forKey: .minor)
    }

    private enum CodingKeys: String, CodingKey {
      case uuid, major, minor
    }
  }

  public struct CircularGeographicCondition: CLCondition, Sendable {
    public let center: CLLocationCoordinate2D
    public let radius: CLLocationDistance

    public init(center: CLLocationCoordinate2D, radius: CLLocationDistance) {
      self.center = center
      self.radius = radius
    }

    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: CodingKeys.self)
      let latitude = try container.decode(CLLocationDegrees.self, forKey: .latitude)
      let longitude = try container.decode(CLLocationDegrees.self, forKey: .longitude)
      center = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
      radius = try container.decode(CLLocationDistance.self, forKey: .radius)
    }

    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: CodingKeys.self)
      try container.encode(center.latitude, forKey: .latitude)
      try container.encode(center.longitude, forKey: .longitude)
      try container.encode(radius, forKey: .radius)
    }

    private enum CodingKeys: String, CodingKey {
      case latitude, longitude, radius
    }
  }

  public struct Event: Sendable {
    public typealias State = __CLMonitoringState

    public let identifier: String
    public let refinement: (any CLCondition)?
    public let state: State
    public let date: Date
    public let authorizationDenied: Bool
    public let authorizationDeniedGlobally: Bool
    public let authorizationRestricted: Bool
    public let insufficientlyInUse: Bool
    public let accuracyLimited: Bool
    public let conditionUnsupported: Bool
    public let conditionLimitExceeded: Bool
    public let persistenceUnavailable: Bool
    public let serviceSessionRequired: Bool
    public let authorizationRequestInProgress: Bool

    @_spi(OpenUIKitHost)
    public init(
      identifier: String,
      refinement: (any CLCondition)?,
      state: State,
      date: Date = Date(),
      authorizationDenied: Bool = true,
      authorizationDeniedGlobally: Bool = false,
      authorizationRestricted: Bool = false,
      insufficientlyInUse: Bool = false,
      accuracyLimited: Bool = false,
      conditionUnsupported: Bool = false,
      conditionLimitExceeded: Bool = false,
      persistenceUnavailable: Bool = false,
      serviceSessionRequired: Bool = false,
      authorizationRequestInProgress: Bool = false
    ) {
      self.identifier = identifier
      self.refinement = refinement
      self.state = state
      self.date = date
      self.authorizationDenied = authorizationDenied
      self.authorizationDeniedGlobally = authorizationDeniedGlobally
      self.authorizationRestricted = authorizationRestricted
      self.insufficientlyInUse = insufficientlyInUse
      self.accuracyLimited = accuracyLimited
      self.conditionUnsupported = conditionUnsupported
      self.conditionLimitExceeded = conditionLimitExceeded
      self.persistenceUnavailable = persistenceUnavailable
      self.serviceSessionRequired = serviceSessionRequired
      self.authorizationRequestInProgress = authorizationRequestInProgress
    }
  }

  public struct Record: Sendable {
    public let condition: any CLCondition
    public let lastEvent: Event
  }

  public struct Events: AsyncSequence, Sendable {
    public typealias Element = Event
    public typealias AsyncIterator = Iterator
    private let monitor: CLMonitor

    fileprivate init(monitor: CLMonitor) {
      self.monitor = monitor
    }

    public func makeAsyncIterator() -> Iterator {
      Iterator(monitor: monitor)
    }

    public struct Iterator: AsyncIteratorProtocol, Sendable {
      public typealias Element = CLMonitor.Events.Element
      private let monitor: CLMonitor

      fileprivate init(monitor: CLMonitor) {
        self.monitor = monitor
      }

      /// Returns queued host-injected events; nil when the mailbox is empty.
      /// Linux never invents hardware transitions
      /// (testMonitorStoresConditionWithoutHardwareEvents,
      /// testMonitorInjectedGeographicEvents).
      public mutating func next() async throws -> CLMonitor.Events.Element? {
        await monitor.dequeueEvent()
      }
    }
  }

  public var events: Events { Events(monitor: self) }
  private var records: [String: Record] = [:]
  private var pendingEvents: [Event] = []
  private let name: String

  public var identifiers: [String] { Array(records.keys).sorted() }

  public init(_ name: String) async {
    self.name = name
  }

  func dequeueEvent() -> Event? {
    guard !pendingEvents.isEmpty else { return nil }
    return pendingEvents.removeFirst()
  }

  public func add(_ condition: any CLCondition, identifier: String) {
    add(condition, identifier: identifier, assuming: .unknown)
  }

  public func add(
    _ condition: any CLCondition,
    identifier: String,
    assuming state: Event.State
  ) {
    let event = Event(
      identifier: identifier,
      refinement: condition,
      state: state,
      authorizationDenied: true
    )
    records[identifier] = Record(condition: condition, lastEvent: event)
  }

  public func remove(_ identifier: String) {
    records.removeValue(forKey: identifier)
  }

  public func record(for identifier: String) -> Record? {
    records[identifier]
  }

  /// Evaluates stored circular conditions against a host location.
  /// Satisfied when Vincenty distance to the center is ≤ radius
  /// (testMonitorInjectedGeographicEvents, nyc-london / equator samples
  /// from testWGS84DistanceAndCircularRegion).
  @_spi(OpenUIKitHost)
  public func _portableInject(location: CLLocation) {
    for identifier in identifiers {
      guard let record = records[identifier] else { continue }
      guard let geographic = record.condition as? CircularGeographicCondition else {
        continue
      }
      let center = CLLocation(
        latitude: geographic.center.latitude,
        longitude: geographic.center.longitude
      )
      let inside = center.distance(from: location) <= geographic.radius
      let newState: Event.State = inside ? .satisfied : .unsatisfied
      if newState == record.lastEvent.state { continue }
      let event = Event(
        identifier: identifier,
        refinement: geographic,
        state: newState,
        authorizationDenied: false
      )
      records[identifier] = Record(condition: record.condition, lastEvent: event)
      pendingEvents.append(event)
    }
  }
}
