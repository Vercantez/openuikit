@_exported import Foundation

public typealias CLLocationDegrees = Double
public typealias CLLocationDistance = Double
public typealias CLLocationAccuracy = Double
public typealias CLLocationSpeed = Double
public typealias CLLocationDirection = Double
public typealias CLTimeInterval = Double
public typealias CLBeaconMajorValue = UInt16
public typealias CLBeaconMinorValue = UInt16
public typealias CLHeadingComponentValue = Double
public typealias CLGeocodeCompletionHandler = ([CLPlacemark]?, (any Error)?) -> Void

public let CLLocationDistanceMax = Double.greatestFiniteMagnitude
public let kCLDistanceFilterNone: CLLocationDistance = -1
public let kCLHeadingFilterNone: CLLocationDegrees = -1
public let kCLLocationAccuracyBestForNavigation: CLLocationAccuracy = -2
public let kCLLocationAccuracyBest: CLLocationAccuracy = -1
public let kCLLocationAccuracyNearestTenMeters: CLLocationAccuracy = 10
public let kCLLocationAccuracyHundredMeters: CLLocationAccuracy = 100
public let kCLLocationAccuracyKilometer: CLLocationAccuracy = 1_000
public let kCLLocationAccuracyThreeKilometers: CLLocationAccuracy = 3_000
public let kCLLocationAccuracyReduced: CLLocationAccuracy = 6_380_000
public let kCLErrorDomain = "kCLErrorDomain"
public let kCLErrorUserInfoAlternateRegionKey = "kCLErrorUserInfoAlternateRegionKey"
public let CLLocationPushServiceErrorDomain = "CLLocationPushServiceErrorDomain"
public var CL_TARGET_SUPPORTS_CONDITIONS: Int32 { 1 }

public struct CLLocationCoordinate2D: Hashable, Sendable {
  public var latitude: CLLocationDegrees
  public var longitude: CLLocationDegrees

  public init(latitude: CLLocationDegrees, longitude: CLLocationDegrees) {
    self.latitude = latitude
    self.longitude = longitude
  }
}

public let kCLLocationCoordinate2DInvalid = CLLocationCoordinate2D(
  latitude: .infinity,
  longitude: .infinity
)

public func CLLocationCoordinate2DMake(
  _ latitude: CLLocationDegrees,
  _ longitude: CLLocationDegrees
) -> CLLocationCoordinate2D {
  CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
}

public func CLLocationCoordinate2DIsValid(
  _ coordinate: CLLocationCoordinate2D
) -> Bool {
  coordinate.latitude.isFinite
    && coordinate.longitude.isFinite
    && (-90.0...90.0).contains(coordinate.latitude)
    && (-180.0...180.0).contains(coordinate.longitude)
}

#if canImport(ObjectiveC)
@objc
#endif
public enum CLAuthorizationStatus: Int, Sendable {
  case notDetermined = 0
  case restricted = 1
  case denied = 2
  case authorizedAlways = 3
  case authorizedWhenInUse = 4

  /// Deprecated alias of `authorizedAlways` (raw value 3).
  public static var authorized: CLAuthorizationStatus { .authorizedAlways }
}

#if canImport(ObjectiveC)
@objc
#endif
public enum CLAccuracyAuthorization: Int, Sendable {
  case fullAccuracy = 0
  case reducedAccuracy = 1
}

#if canImport(ObjectiveC)
@objc
#endif
public enum CLActivityType: Int, Sendable {
  case other = 1
  case automotiveNavigation = 2
  case fitness = 3
  case otherNavigation = 4
  case airborne = 5
}

#if canImport(ObjectiveC)
@objc
#endif
public enum CLDeviceOrientation: Int, Sendable {
  case unknown = 0
  case portrait = 1
  case portraitUpsideDown = 2
  case landscapeLeft = 3
  case landscapeRight = 4
  case faceUp = 5
  case faceDown = 6
}

#if canImport(ObjectiveC)
@objc
#endif
public enum CLRegionState: Int, Sendable {
  case unknown = 0
  case inside = 1
  case outside = 2
}

#if canImport(ObjectiveC)
@objc
#endif
public enum CLProximity: Int, Sendable {
  case unknown = 0
  case immediate = 1
  case near = 2
  case far = 3
}

/// Bridged CoreLocation error.
///
/// Linux Foundation exposes `Foundation._BridgedStoredNSError`. Typed
/// `NSError as? CLError` round-trips are not claimed: Linux Foundation
/// special-cases Cocoa/POSIX/URL errors and does not wrap arbitrary domains.
public struct CLError: Foundation._BridgedStoredNSError, LocalizedError,
  @unchecked Sendable
{
  public enum Code: Int, Foundation._ErrorCodeProtocol, Sendable {
    public typealias _ErrorType = CLError

    case locationUnknown = 0
    case denied = 1
    case network = 2
    case headingFailure = 3
    case regionMonitoringDenied = 4
    case regionMonitoringFailure = 5
    case regionMonitoringSetupDelayed = 6
    case regionMonitoringResponseDelayed = 7
    case geocodeFoundNoResult = 8
    case geocodeFoundPartialResult = 9
    case geocodeCanceled = 10
    case deferredFailed = 11
    case deferredNotUpdatingLocation = 12
    case deferredAccuracyTooLow = 13
    case deferredDistanceFiltered = 14
    case deferredCanceled = 15
    case rangingUnavailable = 16
    case rangingFailure = 17
    case promptDeclined = 18
    case historicalLocationError = 19
  }

  public let _nsError: NSError

  public init(_nsError: NSError) {
    self._nsError = _nsError
  }

  public static var _nsErrorDomain: String { kCLErrorDomain }
  public static var errorDomain: String { kCLErrorDomain }

  public static var locationUnknown: Code { .locationUnknown }
  public static var denied: Code { .denied }
  public static var network: Code { .network }
  public static var headingFailure: Code { .headingFailure }
  public static var regionMonitoringDenied: Code { .regionMonitoringDenied }
  public static var regionMonitoringFailure: Code { .regionMonitoringFailure }
  public static var regionMonitoringSetupDelayed: Code { .regionMonitoringSetupDelayed }
  public static var regionMonitoringResponseDelayed: Code { .regionMonitoringResponseDelayed }
  public static var geocodeFoundNoResult: Code { .geocodeFoundNoResult }
  public static var geocodeFoundPartialResult: Code { .geocodeFoundPartialResult }
  public static var geocodeCanceled: Code { .geocodeCanceled }
  public static var deferredFailed: Code { .deferredFailed }
  public static var deferredNotUpdatingLocation: Code { .deferredNotUpdatingLocation }
  public static var deferredAccuracyTooLow: Code { .deferredAccuracyTooLow }
  public static var deferredDistanceFiltered: Code { .deferredDistanceFiltered }
  public static var deferredCanceled: Code { .deferredCanceled }
  public static var rangingUnavailable: Code { .rangingUnavailable }
  public static var rangingFailure: Code { .rangingFailure }
  public static var promptDeclined: Code { .promptDeclined }
  public static var historicalLocationError: Code { .historicalLocationError }

  public var code: Code {
    Code(rawValue: _nsError.code) ?? .locationUnknown
  }

  public var userInfo: [String: Any] { _nsError.userInfo }
  public var errorUserInfo: [String: Any] { _nsError.userInfo }
  public var errorCode: Int { _nsError.code }
  public var localizedDescription: String { _nsError.localizedDescription }

  public var alternateRegion: CLRegion? {
    userInfo[kCLErrorUserInfoAlternateRegionKey] as? CLRegion
  }

  public var errorDescription: String? {
    switch code {
    case .locationUnknown: "The location is currently unknown"
    case .denied: "Location access is denied or unavailable"
    case .network: "A network service required for location is unavailable"
    case .headingFailure: "Heading data is unavailable"
    case .geocodeFoundNoResult: "No geocoding result is available"
    case .geocodeCanceled: "The geocoding request was canceled"
    default: "CoreLocation error \(code.rawValue)"
    }
  }

  /// Foundation's `_BridgedStoredNSError` hash witnesses trap on Linux.
  public func hash(into hasher: inout Hasher) {
    hasher.combine(_nsError.domain)
    hasher.combine(_nsError.code)
  }

  public var hashValue: Int {
    var hasher = Hasher()
    hash(into: &hasher)
    return hasher.finalize()
  }
}

public struct CLLocationPushServiceError: Foundation._BridgedStoredNSError,
  LocalizedError, @unchecked Sendable
{
  public enum Code: Int, Foundation._ErrorCodeProtocol, Sendable {
    public typealias _ErrorType = CLLocationPushServiceError

    case unknown = 0
    case missingPushExtension = 1
    case missingPushServerEnvironment = 2
    case missingEntitlement = 3
    case unsupportedPlatform = 4
  }

  public let _nsError: NSError

  public init(_nsError: NSError) {
    self._nsError = _nsError
  }

  public static var _nsErrorDomain: String { CLLocationPushServiceErrorDomain }
  public static var errorDomain: String { CLLocationPushServiceErrorDomain }

  public static var unknown: Code { .unknown }
  public static var missingPushExtension: Code { .missingPushExtension }
  public static var missingPushServerEnvironment: Code { .missingPushServerEnvironment }
  public static var missingEntitlement: Code { .missingEntitlement }
  public static var unsupportedPlatform: Code { .unsupportedPlatform }

  public var code: Code {
    Code(rawValue: _nsError.code) ?? .unknown
  }

  public var userInfo: [String: Any] { _nsError.userInfo }
  public var errorUserInfo: [String: Any] { _nsError.userInfo }
  public var errorCode: Int { _nsError.code }
  public var localizedDescription: String { _nsError.localizedDescription }

  public var errorDescription: String? {
    "CLLocationPushServiceError \(code.rawValue)"
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(_nsError.domain)
    hasher.combine(_nsError.code)
  }

  public var hashValue: Int {
    var hasher = Hasher()
    hash(into: &hasher)
    return hasher.finalize()
  }
}

#if canImport(ObjectiveC)
@objc(CLFloor)
#endif
open class CLFloor: NSObject, @unchecked Sendable {
  #if canImport(ObjectiveC)
  @objc
  #endif
  public let level: Int

  @_spi(OpenUIKitHost)
  public init(level: Int) {
    self.level = level
    super.init()
  }
}

#if canImport(ObjectiveC)
@objc(CLLocation)
#endif
open class CLLocation: NSObject, NSCopying, @unchecked Sendable {
  public let coordinate: CLLocationCoordinate2D
  #if canImport(ObjectiveC)
  @objc
  #endif
  public let altitude: CLLocationDistance
  #if canImport(ObjectiveC)
  @objc
  #endif
  public let horizontalAccuracy: CLLocationAccuracy
  #if canImport(ObjectiveC)
  @objc
  #endif
  public let verticalAccuracy: CLLocationAccuracy
  #if canImport(ObjectiveC)
  @objc
  #endif
  public let course: CLLocationDirection
  #if canImport(ObjectiveC)
  @objc
  #endif
  public let courseAccuracy: CLLocationDirection
  #if canImport(ObjectiveC)
  @objc
  #endif
  public let speed: CLLocationSpeed
  #if canImport(ObjectiveC)
  @objc
  #endif
  public let speedAccuracy: CLLocationSpeed
  #if canImport(ObjectiveC)
  @objc
  #endif
  public let timestamp: Date
  #if canImport(ObjectiveC)
  @objc
  #endif
  public let floor: CLFloor?

  #if canImport(ObjectiveC)
  @objc
  #endif
  public convenience init(
    latitude: CLLocationDegrees,
    longitude: CLLocationDegrees
  ) {
    self.init(
      coordinate: .init(latitude: latitude, longitude: longitude),
      altitude: 0,
      horizontalAccuracy: -1,
      verticalAccuracy: -1,
      course: -1,
      courseAccuracy: -1,
      speed: -1,
      speedAccuracy: -1,
      timestamp: Date()
    )
  }

  public convenience init(
    coordinate: CLLocationCoordinate2D,
    altitude: CLLocationDistance,
    horizontalAccuracy hAccuracy: CLLocationAccuracy,
    verticalAccuracy vAccuracy: CLLocationAccuracy,
    timestamp: Date
  ) {
    self.init(
      coordinate: coordinate,
      altitude: altitude,
      horizontalAccuracy: hAccuracy,
      verticalAccuracy: vAccuracy,
      course: -1,
      courseAccuracy: -1,
      speed: -1,
      speedAccuracy: -1,
      timestamp: timestamp
    )
  }

  public convenience init(
    coordinate: CLLocationCoordinate2D,
    altitude: CLLocationDistance,
    horizontalAccuracy hAccuracy: CLLocationAccuracy,
    verticalAccuracy vAccuracy: CLLocationAccuracy,
    course: CLLocationDirection,
    speed: CLLocationSpeed,
    timestamp: Date
  ) {
    self.init(
      coordinate: coordinate,
      altitude: altitude,
      horizontalAccuracy: hAccuracy,
      verticalAccuracy: vAccuracy,
      course: course,
      courseAccuracy: -1,
      speed: speed,
      speedAccuracy: -1,
      timestamp: timestamp
    )
  }

  public init(
    coordinate: CLLocationCoordinate2D,
    altitude: CLLocationDistance,
    horizontalAccuracy hAccuracy: CLLocationAccuracy,
    verticalAccuracy vAccuracy: CLLocationAccuracy,
    course: CLLocationDirection,
    courseAccuracy: CLLocationDirection,
    speed: CLLocationSpeed,
    speedAccuracy: CLLocationSpeed,
    timestamp: Date
  ) {
    self.coordinate = coordinate
    self.altitude = altitude
    horizontalAccuracy = hAccuracy
    verticalAccuracy = vAccuracy
    self.course = course
    self.courseAccuracy = courseAccuracy
    self.speed = speed
    self.speedAccuracy = speedAccuracy
    self.timestamp = timestamp
    floor = nil
    super.init()
  }

  #if canImport(ObjectiveC)
  @objc(distanceFromLocation:)
  #endif
  open func distance(from location: CLLocation) -> CLLocationDistance {
    guard CLLocationCoordinate2DIsValid(coordinate),
      CLLocationCoordinate2DIsValid(location.coordinate)
    else { return .greatestFiniteMagnitude }

    return _openGeodesicDistance(coordinate, location.coordinate)
  }

  public func copy(with zone: NSZone? = nil) -> Any {
    _ = zone
    return self
  }

  open override func isEqual(_ object: Any?) -> Bool {
    guard let other = object as? CLLocation else { return false }
    return coordinate == other.coordinate
      && altitude == other.altitude
      && horizontalAccuracy == other.horizontalAccuracy
      && verticalAccuracy == other.verticalAccuracy
      && course == other.course
      && courseAccuracy == other.courseAccuracy
      && speed == other.speed
      && speedAccuracy == other.speedAccuracy
      && timestamp == other.timestamp
  }

  open override var hash: Int {
    var hasher = Hasher()
    hasher.combine(coordinate)
    hasher.combine(altitude)
    hasher.combine(horizontalAccuracy)
    hasher.combine(verticalAccuracy)
    hasher.combine(course)
    hasher.combine(courseAccuracy)
    hasher.combine(speed)
    hasher.combine(speedAccuracy)
    hasher.combine(timestamp)
    return hasher.finalize()
  }

  open override var description: String {
    "<CLLocation \(coordinate.latitude),\(coordinate.longitude) ±\(horizontalAccuracy)m>"
  }

  #if canImport(ObjectiveC)
  @objc(_openLatitude)
  #endif
  public var _openLatitude: CLLocationDegrees { coordinate.latitude }

  #if canImport(ObjectiveC)
  @objc(_openLongitude)
  #endif
  public var _openLongitude: CLLocationDegrees { coordinate.longitude }
}

private func _openGeodesicDistance(
  _ source: CLLocationCoordinate2D,
  _ destination: CLLocationCoordinate2D
) -> CLLocationDistance {
  if source == destination { return 0 }

  // Vincenty's inverse solution on WGS-84. CoreLocation reports ellipsoidal
  // distances rather than a spherical haversine approximation; this keeps
  // long-haul and equatorial results aligned with Apple's public behavior.
  let majorAxis = 6_378_137.0
  let flattening = 1.0 / 298.257_223_563
  let minorAxis = (1 - flattening) * majorAxis
  let radians = Double.pi / 180
  let reducedLatitude1 = atan((1 - flattening) * tan(source.latitude * radians))
  let reducedLatitude2 = atan((1 - flattening) * tan(destination.latitude * radians))
  let sinU1 = sin(reducedLatitude1)
  let cosU1 = cos(reducedLatitude1)
  let sinU2 = sin(reducedLatitude2)
  let cosU2 = cos(reducedLatitude2)
  let longitudeDelta = (destination.longitude - source.longitude) * radians
  var lambda = longitudeDelta
  var sigma = 0.0
  var sinSigma = 0.0
  var cosSigma = 0.0
  var sinAlpha = 0.0
  var cosSquaredAlpha = 0.0
  var cosTwoSigmaM = 0.0
  var converged = false

  for _ in 0..<100 {
    let sinLambda = sin(lambda)
    let cosLambda = cos(lambda)
    let first = cosU2 * sinLambda
    let second = cosU1 * sinU2 - sinU1 * cosU2 * cosLambda
    sinSigma = sqrt(first * first + second * second)
    if sinSigma == 0 { return 0 }
    cosSigma = sinU1 * sinU2 + cosU1 * cosU2 * cosLambda
    sigma = atan2(sinSigma, cosSigma)
    sinAlpha = cosU1 * cosU2 * sinLambda / sinSigma
    cosSquaredAlpha = max(0, 1 - sinAlpha * sinAlpha)
    cosTwoSigmaM = cosSquaredAlpha == 0
      ? 0
      : cosSigma - 2 * sinU1 * sinU2 / cosSquaredAlpha
    let coefficient = flattening / 16 * cosSquaredAlpha
      * (4 + flattening * (4 - 3 * cosSquaredAlpha))
    let previous = lambda
    lambda = longitudeDelta + (1 - coefficient) * flattening * sinAlpha
      * (sigma + coefficient * sinSigma
        * (cosTwoSigmaM + coefficient * cosSigma
          * (-1 + 2 * cosTwoSigmaM * cosTwoSigmaM)))
    if abs(lambda - previous) <= 1e-12 {
      converged = true
      break
    }
  }

  guard converged else {
    let latitude1 = source.latitude * radians
    let latitude2 = destination.latitude * radians
    let deltaLatitude = (destination.latitude - source.latitude) * radians
    let deltaLongitude = (destination.longitude - source.longitude) * radians
    let haversine = sin(deltaLatitude / 2) * sin(deltaLatitude / 2)
      + cos(latitude1) * cos(latitude2)
      * sin(deltaLongitude / 2) * sin(deltaLongitude / 2)
    return 6_371_008.8 * 2
      * atan2(sqrt(haversine), sqrt(max(0, 1 - haversine)))
  }

  let uSquared = cosSquaredAlpha
    * (majorAxis * majorAxis - minorAxis * minorAxis)
    / (minorAxis * minorAxis)
  let aCoefficient = 1 + uSquared / 16_384
    * (4_096 + uSquared * (-768 + uSquared * (320 - 175 * uSquared)))
  let bCoefficient = uSquared / 1_024
    * (256 + uSquared * (-128 + uSquared * (74 - 47 * uSquared)))
  let deltaSigma = bCoefficient * sinSigma
    * (cosTwoSigmaM + bCoefficient / 4
      * (cosSigma * (-1 + 2 * cosTwoSigmaM * cosTwoSigmaM)
        - bCoefficient / 6 * cosTwoSigmaM
        * (-3 + 4 * sinSigma * sinSigma)
        * (-3 + 4 * cosTwoSigmaM * cosTwoSigmaM)))
  return minorAxis * aCoefficient * (sigma - deltaSigma)
}

#if canImport(ObjectiveC)
@objc(CLHeading)
#endif
open class CLHeading: NSObject, NSCopying, @unchecked Sendable {
  #if canImport(ObjectiveC)
  @objc
  #endif
  public let magneticHeading: CLLocationDirection
  #if canImport(ObjectiveC)
  @objc
  #endif
  public let trueHeading: CLLocationDirection
  #if canImport(ObjectiveC)
  @objc
  #endif
  public let headingAccuracy: CLLocationDirection
  #if canImport(ObjectiveC)
  @objc
  #endif
  public let x: Double
  #if canImport(ObjectiveC)
  @objc
  #endif
  public let y: Double
  #if canImport(ObjectiveC)
  @objc
  #endif
  public let z: Double
  #if canImport(ObjectiveC)
  @objc
  #endif
  public let timestamp: Date

  @_spi(OpenUIKitHost)
  public init(
    magneticHeading: CLLocationDirection,
    trueHeading: CLLocationDirection,
    headingAccuracy: CLLocationDirection,
    x: Double = 0,
    y: Double = 0,
    z: Double = 0,
    timestamp: Date = Date()
  ) {
    self.magneticHeading = magneticHeading
    self.trueHeading = trueHeading
    self.headingAccuracy = headingAccuracy
    self.x = x
    self.y = y
    self.z = z
    self.timestamp = timestamp
    super.init()
  }

  public func copy(with zone: NSZone? = nil) -> Any {
    _ = zone
    return self
  }
}

#if canImport(ObjectiveC)
@objc(CLRegion)
#endif
open class CLRegion: NSObject, NSCopying, @unchecked Sendable {
  #if canImport(ObjectiveC)
  @objc
  #endif
  public let identifier: String
  #if canImport(ObjectiveC)
  @objc
  #endif
  open var notifyOnEntry: Bool = true
  #if canImport(ObjectiveC)
  @objc
  #endif
  open var notifyOnExit: Bool = true

  #if canImport(ObjectiveC)
  @objc
  #endif
  public init(identifier: String) {
    self.identifier = identifier
    super.init()
  }

  open func contains(_ coordinate: CLLocationCoordinate2D) -> Bool {
    _ = coordinate
    return false
  }

  public func copy(with zone: NSZone? = nil) -> Any {
    _ = zone
    return self
  }

  open override func isEqual(_ object: Any?) -> Bool {
    guard let other = object as? CLRegion else { return false }
    return type(of: self) == type(of: other) && identifier == other.identifier
  }

  open override var hash: Int { identifier.hashValue }
}

#if canImport(ObjectiveC)
@objc(CLCircularRegion)
#endif
open class CLCircularRegion: CLRegion, @unchecked Sendable {
  public let center: CLLocationCoordinate2D
  #if canImport(ObjectiveC)
  @objc
  #endif
  public let radius: CLLocationDistance

  public init(
    center: CLLocationCoordinate2D,
    radius: CLLocationDistance,
    identifier: String
  ) {
    self.center = center
    self.radius = max(0, radius)
    super.init(identifier: identifier)
  }

  open override func contains(_ coordinate: CLLocationCoordinate2D) -> Bool {
    CLLocation(latitude: center.latitude, longitude: center.longitude)
      .distance(from: CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude))
      <= radius
  }

  open override func isEqual(_ object: Any?) -> Bool {
    guard let other = object as? CLCircularRegion else { return false }
    return identifier == other.identifier && center == other.center && radius == other.radius
  }

  open override var hash: Int {
    var hasher = Hasher()
    hasher.combine(identifier)
    hasher.combine(center)
    hasher.combine(radius)
    return hasher.finalize()
  }

  #if canImport(ObjectiveC)
  @objc(_openCenterLatitude)
  #endif
  public var _openCenterLatitude: CLLocationDegrees { center.latitude }

  #if canImport(ObjectiveC)
  @objc(_openCenterLongitude)
  #endif
  public var _openCenterLongitude: CLLocationDegrees { center.longitude }

  #if canImport(ObjectiveC)
  @objc(_openContainsLatitude:longitude:)
  #endif
  public func _openContains(
    latitude: CLLocationDegrees,
    longitude: CLLocationDegrees
  ) -> Bool {
    contains(.init(latitude: latitude, longitude: longitude))
  }
}

#if canImport(ObjectiveC)
@objc(CLBeaconIdentityConstraint)
#endif
open class CLBeaconIdentityConstraint: NSObject, NSCopying,
  @unchecked Sendable
{
  #if canImport(ObjectiveC)
  @objc
  #endif
  public let uuid: UUID
  #if canImport(ObjectiveC)
  @objc
  #endif
  public let major: NSNumber?
  #if canImport(ObjectiveC)
  @objc
  #endif
  public let minor: NSNumber?

  #if canImport(ObjectiveC)
  @objc
  #endif
  public init(uuid: UUID) {
    self.uuid = uuid
    major = nil
    minor = nil
    super.init()
  }

  #if canImport(ObjectiveC)
  @objc
  #endif
  public init(uuid: UUID, major: CLBeaconMajorValue) {
    self.uuid = uuid
    self.major = NSNumber(value: major)
    minor = nil
    super.init()
  }

  #if canImport(ObjectiveC)
  @objc
  #endif
  public init(
    uuid: UUID,
    major: CLBeaconMajorValue,
    minor: CLBeaconMinorValue
  ) {
    self.uuid = uuid
    self.major = NSNumber(value: major)
    self.minor = NSNumber(value: minor)
    super.init()
  }

  public func copy(with zone: NSZone? = nil) -> Any {
    _ = zone
    return self
  }
}

#if canImport(ObjectiveC)
@objc(CLBeaconRegion)
#endif
open class CLBeaconRegion: CLRegion, @unchecked Sendable {
  #if canImport(ObjectiveC)
  @objc
  #endif
  public let uuid: UUID
  #if canImport(ObjectiveC)
  @objc
  #endif
  public let major: NSNumber?
  #if canImport(ObjectiveC)
  @objc
  #endif
  public let minor: NSNumber?
  #if canImport(ObjectiveC)
  @objc
  #endif
  open var notifyEntryStateOnDisplay = false

  #if canImport(ObjectiveC)
  @objc
  #endif
  public init(uuid: UUID, identifier: String) {
    self.uuid = uuid
    major = nil
    minor = nil
    super.init(identifier: identifier)
  }

  #if canImport(ObjectiveC)
  @objc
  #endif
  public init(
    uuid: UUID,
    major: CLBeaconMajorValue,
    identifier: String
  ) {
    self.uuid = uuid
    self.major = NSNumber(value: major)
    minor = nil
    super.init(identifier: identifier)
  }

  #if canImport(ObjectiveC)
  @objc
  #endif
  public init(
    uuid: UUID,
    major: CLBeaconMajorValue,
    minor: CLBeaconMinorValue,
    identifier: String
  ) {
    self.uuid = uuid
    self.major = NSNumber(value: major)
    self.minor = NSNumber(value: minor)
    super.init(identifier: identifier)
  }

  #if canImport(ObjectiveC)
  @objc
  #endif
  public convenience init(
    beaconIdentityConstraint: CLBeaconIdentityConstraint,
    identifier: String
  ) {
    let major = beaconIdentityConstraint.major?.uint16Value
    let minor = beaconIdentityConstraint.minor?.uint16Value
    if let major, let minor {
      self.init(
        uuid: beaconIdentityConstraint.uuid,
        major: major,
        minor: minor,
        identifier: identifier
      )
    } else if let major {
      self.init(
        uuid: beaconIdentityConstraint.uuid,
        major: major,
        identifier: identifier
      )
    } else {
      self.init(uuid: beaconIdentityConstraint.uuid, identifier: identifier)
    }
  }

  #if canImport(ObjectiveC)
  @objc
  #endif
  public convenience init(
    proximityUUID: UUID,
    identifier: String
  ) {
    self.init(uuid: proximityUUID, identifier: identifier)
  }

  #if canImport(ObjectiveC)
  @objc
  #endif
  public convenience init(
    proximityUUID: UUID,
    major: CLBeaconMajorValue,
    identifier: String
  ) {
    self.init(uuid: proximityUUID, major: major, identifier: identifier)
  }

  #if canImport(ObjectiveC)
  @objc
  #endif
  public convenience init(
    proximityUUID: UUID,
    major: CLBeaconMajorValue,
    minor: CLBeaconMinorValue,
    identifier: String
  ) {
    self.init(
      uuid: proximityUUID,
      major: major,
      minor: minor,
      identifier: identifier
    )
  }

  #if canImport(ObjectiveC)
  @objc(initWithUUID:identifier:)
  #endif
  public convenience init(UUID uuid: UUID, identifier: String) {
    self.init(uuid: uuid, identifier: identifier)
  }

  #if canImport(ObjectiveC)
  @objc(initWithUUID:major:identifier:)
  #endif
  public convenience init(
    UUID uuid: UUID,
    major: CLBeaconMajorValue,
    identifier: String
  ) {
    self.init(uuid: uuid, major: major, identifier: identifier)
  }

  #if canImport(ObjectiveC)
  @objc(initWithUUID:major:minor:identifier:)
  #endif
  public convenience init(
    UUID uuid: UUID,
    major: CLBeaconMajorValue,
    minor: CLBeaconMinorValue,
    identifier: String
  ) {
    self.init(uuid: uuid, major: major, minor: minor, identifier: identifier)
  }

  #if canImport(ObjectiveC)
  @objc
  #endif
  public var proximityUUID: UUID { uuid }

  #if canImport(ObjectiveC)
  @objc
  #endif
  public func peripheralData(withMeasuredPower measuredPower: NSNumber?)
    -> NSMutableDictionary
  {
    let payload = NSMutableDictionary()
    payload["uuid"] = uuid.uuidString
    if let major { payload["major"] = major }
    if let minor { payload["minor"] = minor }
    if let measuredPower { payload["measuredPower"] = measuredPower }
    return payload
  }

  #if canImport(ObjectiveC)
  @objc
  #endif
  public var beaconIdentityConstraint: CLBeaconIdentityConstraint {
    if let major, let minor {
      return CLBeaconIdentityConstraint(
        uuid: uuid,
        major: major.uint16Value,
        minor: minor.uint16Value
      )
    }
    if let major {
      return CLBeaconIdentityConstraint(uuid: uuid, major: major.uint16Value)
    }
    return CLBeaconIdentityConstraint(uuid: uuid)
  }
}

#if canImport(ObjectiveC)
@objc(CLBeacon)
#endif
open class CLBeacon: NSObject, @unchecked Sendable {
  #if canImport(ObjectiveC)
  @objc
  #endif
  public let uuid: UUID
  #if canImport(ObjectiveC)
  @objc
  #endif
  public let major: NSNumber
  #if canImport(ObjectiveC)
  @objc
  #endif
  public let minor: NSNumber
  #if canImport(ObjectiveC)
  @objc
  #endif
  public let proximity: CLProximity
  #if canImport(ObjectiveC)
  @objc
  #endif
  public let accuracy: CLLocationAccuracy
  #if canImport(ObjectiveC)
  @objc
  #endif
  public let rssi: Int
  #if canImport(ObjectiveC)
  @objc
  #endif
  public let timestamp: Date
  #if canImport(ObjectiveC)
  @objc
  #endif
  public var proximityUUID: UUID { uuid }

  @_spi(OpenUIKitHost)
  public init(
    uuid: UUID,
    major: CLBeaconMajorValue,
    minor: CLBeaconMinorValue,
    proximity: CLProximity,
    accuracy: CLLocationAccuracy,
    rssi: Int,
    timestamp: Date = Date()
  ) {
    self.uuid = uuid
    self.major = NSNumber(value: major)
    self.minor = NSNumber(value: minor)
    self.proximity = proximity
    self.accuracy = accuracy
    self.rssi = rssi
    self.timestamp = timestamp
    super.init()
  }
}

#if canImport(ObjectiveC)
@objc(CLVisit)
#endif
open class CLVisit: NSObject, @unchecked Sendable {
  public let coordinate: CLLocationCoordinate2D
  #if canImport(ObjectiveC)
  @objc
  #endif
  public let horizontalAccuracy: CLLocationAccuracy
  #if canImport(ObjectiveC)
  @objc
  #endif
  public let arrivalDate: Date
  #if canImport(ObjectiveC)
  @objc
  #endif
  public let departureDate: Date

  @_spi(OpenUIKitHost)
  public init(
    coordinate: CLLocationCoordinate2D,
    horizontalAccuracy: CLLocationAccuracy,
    arrivalDate: Date,
    departureDate: Date
  ) {
    self.coordinate = coordinate
    self.horizontalAccuracy = horizontalAccuracy
    self.arrivalDate = arrivalDate
    self.departureDate = departureDate
    super.init()
  }

  #if canImport(ObjectiveC)
  @objc(_openLatitude)
  #endif
  public var _openLatitude: CLLocationDegrees { coordinate.latitude }

  #if canImport(ObjectiveC)
  @objc(_openLongitude)
  #endif
  public var _openLongitude: CLLocationDegrees { coordinate.longitude }
}

#if canImport(ObjectiveC)
@objc(CLPlacemark)
#endif
open class CLPlacemark: NSObject, NSCopying, @unchecked Sendable {
  #if canImport(ObjectiveC)
  @objc
  #endif
  public let location: CLLocation?
  #if canImport(ObjectiveC)
  @objc
  #endif
  public let region: CLRegion?
  #if canImport(ObjectiveC)
  @objc
  #endif
  public let timeZone: TimeZone?
  #if canImport(ObjectiveC)
  @objc
  #endif
  public let name: String?
  #if canImport(ObjectiveC)
  @objc
  #endif
  public let thoroughfare: String?
  #if canImport(ObjectiveC)
  @objc
  #endif
  public let subThoroughfare: String?
  #if canImport(ObjectiveC)
  @objc
  #endif
  public let locality: String?
  #if canImport(ObjectiveC)
  @objc
  #endif
  public let subLocality: String?
  #if canImport(ObjectiveC)
  @objc
  #endif
  public let administrativeArea: String?
  #if canImport(ObjectiveC)
  @objc
  #endif
  public let subAdministrativeArea: String?
  #if canImport(ObjectiveC)
  @objc
  #endif
  public let postalCode: String?
  #if canImport(ObjectiveC)
  @objc
  #endif
  public let isoCountryCode: String?
  #if canImport(ObjectiveC)
  @objc
  #endif
  public let country: String?
  #if canImport(ObjectiveC)
  @objc
  #endif
  public let inlandWater: String?
  #if canImport(ObjectiveC)
  @objc
  #endif
  public let ocean: String?
  #if canImport(ObjectiveC)
  @objc
  #endif
  public let areasOfInterest: [String]?

  @_spi(OpenUIKitHost)
  public init(
    location: CLLocation?,
    region: CLRegion? = nil,
    timeZone: TimeZone? = nil,
    name: String? = nil,
    thoroughfare: String? = nil,
    subThoroughfare: String? = nil,
    locality: String? = nil,
    subLocality: String? = nil,
    administrativeArea: String? = nil,
    subAdministrativeArea: String? = nil,
    postalCode: String? = nil,
    isoCountryCode: String? = nil,
    country: String? = nil,
    inlandWater: String? = nil,
    ocean: String? = nil,
    areasOfInterest: [String]? = nil
  ) {
    self.location = location
    self.region = region
    self.timeZone = timeZone
    self.name = name
    self.thoroughfare = thoroughfare
    self.subThoroughfare = subThoroughfare
    self.locality = locality
    self.subLocality = subLocality
    self.administrativeArea = administrativeArea
    self.subAdministrativeArea = subAdministrativeArea
    self.postalCode = postalCode
    self.isoCountryCode = isoCountryCode
    self.country = country
    self.inlandWater = inlandWater
    self.ocean = ocean
    self.areasOfInterest = areasOfInterest
    super.init()
  }

  public convenience init(placemark: CLPlacemark) {
    self.init(
      location: placemark.location,
      region: placemark.region,
      timeZone: placemark.timeZone,
      name: placemark.name,
      thoroughfare: placemark.thoroughfare,
      subThoroughfare: placemark.subThoroughfare,
      locality: placemark.locality,
      subLocality: placemark.subLocality,
      administrativeArea: placemark.administrativeArea,
      subAdministrativeArea: placemark.subAdministrativeArea,
      postalCode: placemark.postalCode,
      isoCountryCode: placemark.isoCountryCode,
      country: placemark.country,
      inlandWater: placemark.inlandWater,
      ocean: placemark.ocean,
      areasOfInterest: placemark.areasOfInterest
    )
  }

  #if canImport(ObjectiveC)
  @objc
  #endif
  public var addressDictionary: [AnyHashable: Any]? {
    var payload: [AnyHashable: Any] = [:]
    if let name { payload["Name"] = name }
    if let thoroughfare { payload["Thoroughfare"] = thoroughfare }
    if let subThoroughfare { payload["SubThoroughfare"] = subThoroughfare }
    if let locality { payload["City"] = locality }
    if let subLocality { payload["SubLocality"] = subLocality }
    if let administrativeArea { payload["State"] = administrativeArea }
    if let subAdministrativeArea { payload["SubAdministrativeArea"] = subAdministrativeArea }
    if let postalCode { payload["ZIP"] = postalCode }
    if let isoCountryCode { payload["CountryCode"] = isoCountryCode }
    if let country { payload["Country"] = country }
    return payload.isEmpty ? nil : payload
  }

  public func copy(with zone: NSZone? = nil) -> Any {
    _ = zone
    return self
  }
}

#if canImport(ObjectiveC)
@objc
#endif
public protocol CLLocationManagerDelegate: NSObjectProtocol {
  #if canImport(ObjectiveC)
  @objc
  #endif
  func locationManager(
    _ manager: CLLocationManager,
    didUpdateLocations locations: [CLLocation]
  )
  #if canImport(ObjectiveC)
  @objc
  #endif
  func locationManager(
    _ manager: CLLocationManager,
    didUpdateHeading newHeading: CLHeading
  )
  #if canImport(ObjectiveC)
  @objc
  #endif
  func locationManager(
    _ manager: CLLocationManager,
    didFailWithError error: Error
  )
  #if canImport(ObjectiveC)
  @objc
  #endif
  func locationManagerDidChangeAuthorization(
    _ manager: CLLocationManager
  )
  #if canImport(ObjectiveC)
  @objc
  #endif
  func locationManager(
    _ manager: CLLocationManager,
    didChangeAuthorization status: CLAuthorizationStatus
  )
  #if canImport(ObjectiveC)
  @objc
  #endif
  func locationManager(
    _ manager: CLLocationManager,
    didEnterRegion region: CLRegion
  )
  #if canImport(ObjectiveC)
  @objc
  #endif
  func locationManager(
    _ manager: CLLocationManager,
    didExitRegion region: CLRegion
  )
  #if canImport(ObjectiveC)
  @objc
  #endif
  func locationManager(
    _ manager: CLLocationManager,
    didDetermineState state: CLRegionState,
    for region: CLRegion
  )
  #if canImport(ObjectiveC)
  @objc
  #endif
  func locationManager(
    _ manager: CLLocationManager,
    monitoringDidFailFor region: CLRegion?,
    withError error: Error
  )
  #if canImport(ObjectiveC)
  @objc
  #endif
  func locationManager(
    _ manager: CLLocationManager,
    didStartMonitoringFor region: CLRegion
  )
  #if canImport(ObjectiveC)
  @objc
  #endif
  func locationManagerDidPauseLocationUpdates(
    _ manager: CLLocationManager
  )
  #if canImport(ObjectiveC)
  @objc
  #endif
  func locationManagerDidResumeLocationUpdates(
    _ manager: CLLocationManager
  )
  #if canImport(ObjectiveC)
  @objc
  #endif
  func locationManager(
    _ manager: CLLocationManager,
    didVisit visit: CLVisit
  )
  #if canImport(ObjectiveC)
  @objc
  #endif
  func locationManager(
    _ manager: CLLocationManager,
    didRangeBeacons beacons: [CLBeacon],
    in region: CLBeaconRegion
  )
  #if canImport(ObjectiveC)
  @objc
  #endif
  func locationManager(
    _ manager: CLLocationManager,
    didRange beacons: [CLBeacon],
    satisfying beaconConstraint: CLBeaconIdentityConstraint
  )
  #if canImport(ObjectiveC)
  @objc
  #endif
  func locationManager(
    _ manager: CLLocationManager,
    rangingBeaconsDidFailFor region: CLBeaconRegion,
    withError error: any Error
  )
  #if canImport(ObjectiveC)
  @objc
  #endif
  func locationManager(
    _ manager: CLLocationManager,
    didFailRangingFor beaconConstraint: CLBeaconIdentityConstraint,
    error: any Error
  )
  #if canImport(ObjectiveC)
  @objc
  #endif
  func locationManager(
    _ manager: CLLocationManager,
    didFinishDeferredUpdatesWithError error: (any Error)?
  )
  #if canImport(ObjectiveC)
  @objc
  #endif
  func locationManagerShouldDisplayHeadingCalibration(
    _ manager: CLLocationManager
  ) -> Bool
}

extension CLLocationManagerDelegate {
  public func locationManager(
    _ manager: CLLocationManager,
    didUpdateLocations locations: [CLLocation]
  ) {
    _ = manager
    _ = locations
  }

  public func locationManager(
    _ manager: CLLocationManager,
    didUpdateHeading newHeading: CLHeading
  ) {
    _ = manager
    _ = newHeading
  }

  public func locationManager(
    _ manager: CLLocationManager,
    didFailWithError error: Error
  ) {
    _ = manager
    _ = error
  }

  public func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
    _ = manager
  }

  public func locationManager(
    _ manager: CLLocationManager,
    didChangeAuthorization status: CLAuthorizationStatus
  ) {
    _ = manager
    _ = status
  }

  public func locationManager(
    _ manager: CLLocationManager,
    didEnterRegion region: CLRegion
  ) {
    _ = manager
    _ = region
  }

  public func locationManager(
    _ manager: CLLocationManager,
    didExitRegion region: CLRegion
  ) {
    _ = manager
    _ = region
  }

  public func locationManager(
    _ manager: CLLocationManager,
    didDetermineState state: CLRegionState,
    for region: CLRegion
  ) {
    _ = manager
    _ = state
    _ = region
  }

  public func locationManager(
    _ manager: CLLocationManager,
    monitoringDidFailFor region: CLRegion?,
    withError error: Error
  ) {
    _ = manager
    _ = region
    _ = error
  }

  public func locationManager(
    _ manager: CLLocationManager,
    didStartMonitoringFor region: CLRegion
  ) {
    _ = manager
    _ = region
  }

  public func locationManagerDidPauseLocationUpdates(_ manager: CLLocationManager) {
    _ = manager
  }

  public func locationManagerDidResumeLocationUpdates(_ manager: CLLocationManager) {
    _ = manager
  }

  public func locationManager(
    _ manager: CLLocationManager,
    didVisit visit: CLVisit
  ) {
    _ = manager
    _ = visit
  }

  public func locationManager(
    _ manager: CLLocationManager,
    didRangeBeacons beacons: [CLBeacon],
    in region: CLBeaconRegion
  ) {
    _ = manager
    _ = beacons
    _ = region
  }

  public func locationManager(
    _ manager: CLLocationManager,
    didRange beacons: [CLBeacon],
    satisfying beaconConstraint: CLBeaconIdentityConstraint
  ) {
    _ = manager
    _ = beacons
    _ = beaconConstraint
  }

  public func locationManager(
    _ manager: CLLocationManager,
    rangingBeaconsDidFailFor region: CLBeaconRegion,
    withError error: any Error
  ) {
    _ = manager
    _ = region
    _ = error
  }

  public func locationManager(
    _ manager: CLLocationManager,
    didFailRangingFor beaconConstraint: CLBeaconIdentityConstraint,
    error: any Error
  ) {
    _ = manager
    _ = beaconConstraint
    _ = error
  }

  public func locationManager(
    _ manager: CLLocationManager,
    didFinishDeferredUpdatesWithError error: (any Error)?
  ) {
    _ = manager
    _ = error
  }

  public func locationManagerShouldDisplayHeadingCalibration(
    _ manager: CLLocationManager
  ) -> Bool {
    _ = manager
    return false
  }
}

#if canImport(ObjectiveC)
@objc(CLLocationManager)
#endif
open class CLLocationManager: NSObject, @unchecked Sendable {
  private let portableLock = NSLock()
  private weak var portableDelegate: CLLocationManagerDelegate?
  private var portableLocation: CLLocation?
  private var portableHeading: CLHeading?
  private var portableAuthorizationStatus: CLAuthorizationStatus = .notDetermined
  private var portableAccuracyAuthorization: CLAccuracyAuthorization = .fullAccuracy
  private var portableUpdatingLocation = false
  private var portableUpdatingHeading = false
  private var portableMonitoringSignificantChanges = false
  private var portableMonitoringVisits = false
  private var portableMonitoredRegions: Set<CLRegion> = []
  private var portableRangedRegions: Set<CLRegion> = []
  private var portableRangedBeaconConstraints: Set<CLBeaconIdentityConstraint> = []

  #if canImport(ObjectiveC)
  @objc
  #endif
  open weak var delegate: CLLocationManagerDelegate? {
    get {
      portableLock.lock()
      defer { portableLock.unlock() }
      return portableDelegate
    }
    set {
      portableLock.lock()
      portableDelegate = newValue
      portableLock.unlock()
    }
  }

  #if canImport(ObjectiveC)
  @objc
  #endif
  open var location: CLLocation? {
    portableLock.lock()
    defer { portableLock.unlock() }
    return portableLocation
  }

  #if canImport(ObjectiveC)
  @objc
  #endif
  open var heading: CLHeading? {
    portableLock.lock()
    defer { portableLock.unlock() }
    return portableHeading
  }

  #if canImport(ObjectiveC)
  @objc
  #endif
  open var authorizationStatus: CLAuthorizationStatus {
    portableLock.lock()
    defer { portableLock.unlock() }
    return portableAuthorizationStatus
  }

  #if canImport(ObjectiveC)
  @objc
  #endif
  open var accuracyAuthorization: CLAccuracyAuthorization {
    portableLock.lock()
    defer { portableLock.unlock() }
    return portableAccuracyAuthorization
  }

  #if canImport(ObjectiveC)
  @objc
  #endif
  open var desiredAccuracy: CLLocationAccuracy = kCLLocationAccuracyBest
  #if canImport(ObjectiveC)
  @objc
  #endif
  open var distanceFilter: CLLocationDistance = kCLDistanceFilterNone
  #if canImport(ObjectiveC)
  @objc
  #endif
  open var activityType: CLActivityType = .other
  #if canImport(ObjectiveC)
  @objc
  #endif
  open var pausesLocationUpdatesAutomatically = true
  #if canImport(ObjectiveC)
  @objc
  #endif
  open var allowsBackgroundLocationUpdates = false
  #if canImport(ObjectiveC)
  @objc
  #endif
  open var showsBackgroundLocationIndicator = false
  #if canImport(ObjectiveC)
  @objc
  #endif
  open var headingFilter: CLLocationDegrees = 1
  #if canImport(ObjectiveC)
  @objc
  #endif
  open var headingOrientation: CLDeviceOrientation = .portrait

  #if canImport(ObjectiveC)
  @objc
  #endif
  open var monitoredRegions: Set<CLRegion> {
    portableLock.lock()
    defer { portableLock.unlock() }
    return portableMonitoredRegions
  }

  #if canImport(ObjectiveC)
  @objc
  #endif
  open class func locationServicesEnabled() -> Bool { true }
  #if canImport(ObjectiveC)
  @objc
  #endif
  open class func headingAvailable() -> Bool { true }
  #if canImport(ObjectiveC)
  @objc
  #endif
  open class func significantLocationChangeMonitoringAvailable() -> Bool { true }
  #if canImport(ObjectiveC)
  @objc
  #endif
  open class func regionMonitoringAvailable() -> Bool { true }
  #if canImport(ObjectiveC)
  @objc
  #endif
  open class func regionMonitoringEnabled() -> Bool { true }
  #if canImport(ObjectiveC)
  @objc
  #endif
  open class func isMonitoringAvailable(for regionClass: AnyClass) -> Bool {
    regionClass is CLRegion.Type
  }
  #if canImport(ObjectiveC)
  @objc
  #endif
  open class func authorizationStatus() -> CLAuthorizationStatus {
    .notDetermined
  }
  #if canImport(ObjectiveC)
  @objc
  #endif
  open class func isRangingAvailable() -> Bool { false }
  #if canImport(ObjectiveC)
  @objc
  #endif
  open class func deferredLocationUpdatesAvailable() -> Bool { false }

  #if canImport(ObjectiveC)
  @objc
  #endif
  open var isAuthorizedForWidgetUpdates: Bool { false }

  #if canImport(ObjectiveC)
  @objc
  #endif
  open var rangedRegions: Set<CLRegion> {
    portableLock.lock()
    defer { portableLock.unlock() }
    return portableRangedRegions
  }

  #if canImport(ObjectiveC)
  @objc
  #endif
  open var rangedBeaconConstraints: Set<CLBeaconIdentityConstraint> {
    portableLock.lock()
    defer { portableLock.unlock() }
    return portableRangedBeaconConstraints
  }

  #if canImport(ObjectiveC)
  @objc
  #endif
  open var maximumRegionMonitoringDistance: CLLocationDistance {
    CLLocationDistanceMax
  }

  #if canImport(ObjectiveC)
  @objc
  #endif
  open func startUpdatingLocation() {
    portableLock.lock()
    portableUpdatingLocation = true
    portableLock.unlock()
  }

  #if canImport(ObjectiveC)
  @objc
  #endif
  open func stopUpdatingLocation() {
    portableLock.lock()
    portableUpdatingLocation = false
    portableLock.unlock()
  }

  #if canImport(ObjectiveC)
  @objc
  #endif
  open func requestLocation() {
    portableLock.lock()
    let delegate = portableDelegate
    let status = portableAuthorizationStatus
    let location = portableLocation
    portableLock.unlock()
    guard status == .authorizedAlways || status == .authorizedWhenInUse else {
      delegate?.locationManager(self, didFailWithError: CLError(.denied))
      return
    }
    guard let location else {
      delegate?.locationManager(self, didFailWithError: CLError(.locationUnknown))
      return
    }
    delegate?.locationManager(self, didUpdateLocations: [location])
  }

  #if canImport(ObjectiveC)
  @objc
  #endif
  open func startUpdatingHeading() {
    portableLock.lock()
    portableUpdatingHeading = true
    portableLock.unlock()
  }

  #if canImport(ObjectiveC)
  @objc
  #endif
  open func stopUpdatingHeading() {
    portableLock.lock()
    portableUpdatingHeading = false
    portableLock.unlock()
  }

  #if canImport(ObjectiveC)
  @objc
  #endif
  open func dismissHeadingCalibrationDisplay() {}

  #if canImport(ObjectiveC)
  @objc
  #endif
  open func requestWhenInUseAuthorization() {
    portableRequestAuthorization()
  }

  #if canImport(ObjectiveC)
  @objc
  #endif
  open func requestAlwaysAuthorization() {
    portableRequestAuthorization()
  }

  private func portableRequestAuthorization() {
    portableLock.lock()
    if portableAuthorizationStatus == .notDetermined {
      portableAuthorizationStatus = .denied
    }
    let status = portableAuthorizationStatus
    let delegate = portableDelegate
    portableLock.unlock()
    delegate?.locationManager(self, didChangeAuthorization: status)
    delegate?.locationManagerDidChangeAuthorization(self)
  }

  #if canImport(ObjectiveC)
  @objc
  #endif
  open func startMonitoringSignificantLocationChanges() {
    portableLock.lock()
    portableMonitoringSignificantChanges = true
    portableLock.unlock()
  }

  #if canImport(ObjectiveC)
  @objc
  #endif
  open func stopMonitoringSignificantLocationChanges() {
    portableLock.lock()
    portableMonitoringSignificantChanges = false
    portableLock.unlock()
  }

  #if canImport(ObjectiveC)
  @objc
  #endif
  open func startMonitoring(for region: CLRegion) {
    portableLock.lock()
    portableMonitoredRegions.insert(region)
    let delegate = portableDelegate
    portableLock.unlock()
    delegate?.locationManager(self, didStartMonitoringFor: region)
  }

  #if canImport(ObjectiveC)
  @objc
  #endif
  open func stopMonitoring(for region: CLRegion) {
    portableLock.lock()
    portableMonitoredRegions.remove(region)
    portableLock.unlock()
  }

  #if canImport(ObjectiveC)
  @objc
  #endif
  open func requestState(for region: CLRegion) {
    portableLock.lock()
    let delegate = portableDelegate
    let location = portableLocation
    portableLock.unlock()
    let state: CLRegionState
    if let circular = region as? CLCircularRegion, let location {
      state = circular.contains(location.coordinate) ? .inside : .outside
    } else {
      state = .unknown
    }
    delegate?.locationManager(self, didDetermineState: state, for: region)
  }

  #if canImport(ObjectiveC)
  @objc
  #endif
  open func startMonitoringVisits() {
    portableLock.lock()
    portableMonitoringVisits = true
    portableLock.unlock()
  }

  #if canImport(ObjectiveC)
  @objc
  #endif
  open func stopMonitoringVisits() {
    portableLock.lock()
    portableMonitoringVisits = false
    portableLock.unlock()
  }

  #if canImport(ObjectiveC)
  @objc
  #endif
  open func startRangingBeacons(in region: CLBeaconRegion) {
    portableLock.lock()
    portableRangedRegions.insert(region)
    let delegate = portableDelegate
    portableLock.unlock()
    delegate?.locationManager(
      self,
      rangingBeaconsDidFailFor: region,
      withError: CLError(.rangingUnavailable)
    )
  }

  #if canImport(ObjectiveC)
  @objc
  #endif
  open func stopRangingBeacons(in region: CLBeaconRegion) {
    portableLock.lock()
    portableRangedRegions.remove(region)
    portableLock.unlock()
  }

  #if canImport(ObjectiveC)
  @objc
  #endif
  open func startRangingBeacons(satisfying constraint: CLBeaconIdentityConstraint) {
    portableLock.lock()
    portableRangedBeaconConstraints.insert(constraint)
    let delegate = portableDelegate
    portableLock.unlock()
    delegate?.locationManager(
      self,
      didFailRangingFor: constraint,
      error: CLError(.rangingUnavailable)
    )
  }

  #if canImport(ObjectiveC)
  @objc
  #endif
  open func stopRangingBeacons(satisfying constraint: CLBeaconIdentityConstraint) {
    portableLock.lock()
    portableRangedBeaconConstraints.remove(constraint)
    portableLock.unlock()
  }

  #if canImport(ObjectiveC)
  @objc
  #endif
  open func allowDeferredLocationUpdates(
    untilTraveled distance: CLLocationDistance,
    timeout: TimeInterval
  ) {
    _ = distance
    _ = timeout
    portableLock.lock()
    let delegate = portableDelegate
    portableLock.unlock()
    delegate?.locationManager(
      self,
      didFinishDeferredUpdatesWithError: CLError(.deferredFailed)
    )
  }

  #if canImport(ObjectiveC)
  @objc
  #endif
  open func disallowDeferredLocationUpdates() {}

  #if canImport(ObjectiveC)
  @objc
  #endif
  open func requestTemporaryFullAccuracyAuthorization(withPurposeKey purposeKey: String) {
    _ = purposeKey
    portableLock.lock()
    let delegate = portableDelegate
    portableLock.unlock()
    delegate?.locationManager(self, didFailWithError: CLError(.promptDeclined))
  }

  open func requestTemporaryFullAccuracyAuthorization(
    withPurposeKey purposeKey: String
  ) async throws {
    _ = purposeKey
    throw CLError(.promptDeclined)
  }

  #if canImport(ObjectiveC)
  @objc
  #endif
  open func startMonitoringLocationPushes(
    completion: ((Data?, (any Error)?) -> Void)? = nil
  ) {
    completion?(nil, CLLocationPushServiceError(.unsupportedPlatform))
  }

  #if canImport(ObjectiveC)
  @objc
  #endif
  open func stopMonitoringLocationPushes() {}

  @_spi(OpenUIKitHost)
  public func _portableSetAuthorization(
    _ status: CLAuthorizationStatus,
    accuracy: CLAccuracyAuthorization = .fullAccuracy
  ) {
    portableLock.lock()
    let changed = status != portableAuthorizationStatus
      || accuracy != portableAccuracyAuthorization
    portableAuthorizationStatus = status
    portableAccuracyAuthorization = accuracy
    let delegate = portableDelegate
    portableLock.unlock()
    guard changed else { return }
    delegate?.locationManager(self, didChangeAuthorization: status)
    delegate?.locationManagerDidChangeAuthorization(self)
  }

  @_spi(OpenUIKitHost)
  public func _portableInject(locations: [CLLocation]) {
    guard let latest = locations.last else { return }
    portableLock.lock()
    portableLocation = latest
    let delegate = portableDelegate
    let authorized = portableAuthorizationStatus == .authorizedAlways
      || portableAuthorizationStatus == .authorizedWhenInUse
    let deliver = authorized
      && (portableUpdatingLocation || portableMonitoringSignificantChanges)
    let regions = portableMonitoredRegions
    portableLock.unlock()
    guard deliver else { return }
    delegate?.locationManager(self, didUpdateLocations: locations)
    for region in regions {
      guard let circular = region as? CLCircularRegion else { continue }
      let state: CLRegionState = circular.contains(latest.coordinate) ? .inside : .outside
      delegate?.locationManager(self, didDetermineState: state, for: region)
    }
  }

  @_spi(OpenUIKitHost)
  public func _portableInject(heading: CLHeading) {
    portableLock.lock()
    portableHeading = heading
    let delegate = portableDelegate
    let deliver = portableUpdatingHeading
    portableLock.unlock()
    if deliver {
      delegate?.locationManager(self, didUpdateHeading: heading)
    }
  }

  @_spi(OpenUIKitHost)
  public func _portableInject(error: Error) {
    portableLock.lock()
    let delegate = portableDelegate
    portableLock.unlock()
    delegate?.locationManager(self, didFailWithError: error)
  }
}

#if canImport(ObjectiveC)
@objc(CLGeocoder)
#endif
open class CLGeocoder: NSObject, @unchecked Sendable {
  public typealias PortableReverseGeocodeHandler = @Sendable (
    CLLocation
  ) -> Result<[CLPlacemark], Error>
  public typealias PortableForwardGeocodeHandler = @Sendable (
    String
  ) -> Result<[CLPlacemark], Error>

  private let portableLock = NSLock()
  private var portableCanceled = false
  private var reverseHandler: PortableReverseGeocodeHandler?
  private var forwardHandler: PortableForwardGeocodeHandler?

  #if canImport(ObjectiveC)
  @objc
  #endif
  open var isGeocoding: Bool {
    portableLock.lock()
    defer { portableLock.unlock() }
    return false
  }

  #if canImport(ObjectiveC)
  @objc
  #endif
  open func reverseGeocodeLocation(
    _ location: CLLocation,
    completionHandler: @escaping ([CLPlacemark]?, Error?) -> Void
  ) {
    portableLock.lock()
    let canceled = portableCanceled
    portableCanceled = false
    let handler = reverseHandler
    portableLock.unlock()
    if canceled {
      completionHandler(nil, CLError(.geocodeCanceled))
      return
    }
    switch handler?(location) ?? .failure(CLError(.geocodeFoundNoResult)) {
    case .success(let placemarks): completionHandler(placemarks, nil)
    case .failure(let error): completionHandler(nil, error)
    }
  }

  #if canImport(ObjectiveC)
  @objc
  #endif
  open func geocodeAddressString(
    _ addressString: String,
    completionHandler: @escaping ([CLPlacemark]?, Error?) -> Void
  ) {
    portableLock.lock()
    let canceled = portableCanceled
    portableCanceled = false
    let handler = forwardHandler
    portableLock.unlock()
    if canceled {
      completionHandler(nil, CLError(.geocodeCanceled))
      return
    }
    switch handler?(addressString) ?? .failure(CLError(.geocodeFoundNoResult)) {
    case .success(let placemarks): completionHandler(placemarks, nil)
    case .failure(let error): completionHandler(nil, error)
    }
  }

  open func reverseGeocodeLocation(
    _ location: CLLocation
  ) async throws -> [CLPlacemark] {
    try await withCheckedThrowingContinuation { continuation in
      reverseGeocodeLocation(location) { placemarks, error in
        if let error { continuation.resume(throwing: error) }
        else { continuation.resume(returning: placemarks ?? []) }
      }
    }
  }

  open func geocodeAddressString(
    _ addressString: String
  ) async throws -> [CLPlacemark] {
    try await withCheckedThrowingContinuation { continuation in
      geocodeAddressString(addressString) { placemarks, error in
        if let error { continuation.resume(throwing: error) }
        else { continuation.resume(returning: placemarks ?? []) }
      }
    }
  }

  open func geocodeAddressString(
    _ addressString: String,
    in region: CLRegion?
  ) async throws -> [CLPlacemark] {
    _ = region
    return try await geocodeAddressString(addressString)
  }

  open func geocodeAddressString(
    _ addressString: String,
    in region: CLRegion?,
    preferredLocale locale: Locale?
  ) async throws -> [CLPlacemark] {
    _ = region
    _ = locale
    return try await geocodeAddressString(addressString)
  }

  open func reverseGeocodeLocation(
    _ location: CLLocation,
    preferredLocale locale: Locale?
  ) async throws -> [CLPlacemark] {
    _ = locale
    return try await reverseGeocodeLocation(location)
  }

  #if canImport(ObjectiveC)
  @objc
  #endif
  open func geocodeAddressDictionary(
    _ addressDictionary: [AnyHashable: Any],
    completionHandler: @escaping CLGeocodeCompletionHandler
  ) {
    _ = addressDictionary
    portableLock.lock()
    let canceled = portableCanceled
    portableCanceled = false
    portableLock.unlock()
    if canceled {
      completionHandler(nil, CLError(.geocodeCanceled))
      return
    }
    completionHandler(nil, CLError(.geocodeFoundNoResult))
  }

  #if canImport(ObjectiveC)
  @objc
  #endif
  open func cancelGeocode() {
    portableLock.lock()
    portableCanceled = true
    portableLock.unlock()
  }

  @_spi(OpenUIKitHost)
  public func _portableSetReverseGeocodeHandler(
    _ handler: PortableReverseGeocodeHandler?
  ) {
    portableLock.lock()
    reverseHandler = handler
    portableLock.unlock()
  }

  @_spi(OpenUIKitHost)
  public func _portableSetForwardGeocodeHandler(
    _ handler: PortableForwardGeocodeHandler?
  ) {
    portableLock.lock()
    forwardHandler = handler
    portableLock.unlock()
  }
}

extension CLBeacon {
  public convenience init?(coder: NSCoder) {
    _ = coder
    return nil
  }
}

extension CLHeading {
  public convenience init?(coder: NSCoder) {
    _ = coder
    return nil
  }
}

extension CLPlacemark {
  public convenience init?(coder: NSCoder) {
    _ = coder
    return nil
  }
}

extension CLRegion {
  public convenience init?(coder: NSCoder) {
    _ = coder
    return nil
  }
}

extension CLVisit {
  public convenience init?(coder: NSCoder) {
    _ = coder
    return nil
  }
}

#if canImport(ObjectiveC)
@objc
#endif
public protocol CLLocationPushServiceExtension: NSObjectProtocol {
  func didReceiveLocationPushPayload(_ payload: [String: Any]) async
  #if canImport(ObjectiveC)
  @objc
  #endif
  func serviceExtensionWillTerminate()
}

extension CLLocationPushServiceExtension {
  public func serviceExtensionWillTerminate() {}
}
