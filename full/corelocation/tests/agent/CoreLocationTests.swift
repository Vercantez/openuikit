@_spi(OpenUIKitHost) import CoreLocation
import Dispatch
import Foundation

private final class CLLocked<Value>: @unchecked Sendable {
  private let lock = NSLock()
  private var value: Value

  init(_ value: Value) {
    self.value = value
  }

  func load() -> Value {
    lock.lock()
    defer { lock.unlock() }
    return value
  }

  func store(_ value: Value) {
    lock.lock()
    self.value = value
    lock.unlock()
  }
}

private func clAwait<T>(_ body: @escaping () async throws -> T) -> Result<T, Error> {
  let semaphore = DispatchSemaphore(value: 0)
  let box = CLLocked<Result<T, Error>?>(nil)
  Task {
    do {
      box.store(.success(try await body()))
    } catch {
      box.store(.failure(error))
    }
    semaphore.signal()
  }
  semaphore.wait()
  guard let result = box.load() else {
    preconditionFailure("async probe did not complete")
  }
  return result
}

private final class LocationDelegate: NSObject, CLLocationManagerDelegate {
  var authorizations: [CLAuthorizationStatus] = []
  var locations: [CLLocation] = []
  var headings: [CLHeading] = []
  var errors: [CLError.Code] = []
  var regionStates: [CLRegionState] = []
  var rangingFailures: [CLError.Code] = []
  var deferredErrors: [CLError.Code] = []
  var constraintFailures: [CLError.Code] = []

  func locationManager(
    _ manager: CLLocationManager,
    didChangeAuthorization status: CLAuthorizationStatus
  ) {
    _ = manager
    authorizations.append(status)
  }

  func locationManager(
    _ manager: CLLocationManager,
    didUpdateLocations locations: [CLLocation]
  ) {
    _ = manager
    self.locations.append(contentsOf: locations)
  }

  func locationManager(
    _ manager: CLLocationManager,
    didUpdateHeading newHeading: CLHeading
  ) {
    _ = manager
    headings.append(newHeading)
  }

  func locationManager(
    _ manager: CLLocationManager,
    didFailWithError error: Error
  ) {
    _ = manager
    if let error = error as? CLError {
      errors.append(error.code)
    }
  }

  func locationManager(
    _ manager: CLLocationManager,
    didDetermineState state: CLRegionState,
    for region: CLRegion
  ) {
    _ = manager
    _ = region
    regionStates.append(state)
  }

  func locationManager(
    _ manager: CLLocationManager,
    rangingBeaconsDidFailFor region: CLBeaconRegion,
    withError error: any Error
  ) {
    _ = manager
    _ = region
    if let error = error as? CLError {
      rangingFailures.append(error.code)
    }
  }

  func locationManager(
    _ manager: CLLocationManager,
    didFailRangingFor beaconConstraint: CLBeaconIdentityConstraint,
    error: any Error
  ) {
    _ = manager
    _ = beaconConstraint
    if let error = error as? CLError {
      constraintFailures.append(error.code)
    }
  }

  func locationManager(
    _ manager: CLLocationManager,
    didFinishDeferredUpdatesWithError error: (any Error)?
  ) {
    _ = manager
    if let error = error as? CLError {
      deferredErrors.append(error.code)
    }
  }
}

func testCoordinateValidityAndConstants() {
  precondition(CLLocationDistanceMax == Double.greatestFiniteMagnitude)
  precondition(kCLDistanceFilterNone == -1)
  precondition(kCLHeadingFilterNone == -1)
  precondition(kCLLocationAccuracyBestForNavigation == -2)
  precondition(kCLLocationAccuracyBest == -1)
  precondition(kCLLocationAccuracyNearestTenMeters == 10)
  precondition(kCLLocationAccuracyHundredMeters == 100)
  precondition(kCLLocationAccuracyKilometer == 1_000)
  precondition(kCLLocationAccuracyThreeKilometers == 3_000)
  precondition(kCLLocationAccuracyReduced == 6_380_000)
  precondition(kCLErrorDomain == "kCLErrorDomain")
  precondition(kCLErrorUserInfoAlternateRegionKey == "kCLErrorUserInfoAlternateRegionKey")
  precondition(CLLocationPushServiceErrorDomain == "CLLocationPushServiceErrorDomain")
  precondition(CL_TARGET_SUPPORTS_CONDITIONS == 1)
  precondition(!CLLocationCoordinate2DIsValid(kCLLocationCoordinate2DInvalid))
  let valid = CLLocationCoordinate2DMake(12.5, -45.25)
  precondition(CLLocationCoordinate2DIsValid(valid))
  precondition(valid.latitude == 12.5)
  precondition(valid.longitude == -45.25)
  precondition(!CLLocationCoordinate2DIsValid(CLLocationCoordinate2D(latitude: 91, longitude: 0)))
}

func testWGS84DistanceAndCircularRegion() {
  let origin = CLLocation(latitude: 40.7128, longitude: -74.0060)
  let destination = CLLocation(latitude: 51.5074, longitude: -0.1278)
  let transatlantic = origin.distance(from: destination)
  precondition((5_500_000...5_650_000).contains(transatlantic))
  precondition(Int(transatlantic.rounded()) == 5_585_234)
  let equator = CLLocation(latitude: 0, longitude: 0)
    .distance(from: CLLocation(latitude: 0, longitude: 1))
  precondition(Int(equator.rounded()) == 111_319)
  let region = CLCircularRegion(
    center: origin.coordinate,
    radius: 100,
    identifier: "downtown"
  )
  precondition(region.contains(origin.coordinate))
  precondition(!region.contains(destination.coordinate))
  precondition(region.radius == 100)
  precondition(region.center == origin.coordinate)
  region.notifyOnEntry = false
  region.notifyOnExit = false
  precondition(region.notifyOnEntry == false)
  precondition(region.notifyOnExit == false)
}

func testAuthorizationFailClosed() {
  let denied = CLLocationManager()
  let deniedDelegate = LocationDelegate()
  denied.delegate = deniedDelegate
  denied.requestWhenInUseAuthorization()
  denied.requestLocation()
  precondition(denied.authorizationStatus == .denied)
  precondition(deniedDelegate.authorizations == [.denied])
  precondition(deniedDelegate.errors == [.denied])
  let always = CLLocationManager()
  always.requestAlwaysAuthorization()
  precondition(always.authorizationStatus == .denied)
  precondition(CLAuthorizationStatus.authorized == .authorizedAlways)
  precondition(CLAuthorizationStatus.authorizedAlways.rawValue == 3)
  precondition(CLLocationManager.authorizationStatus() == .notDetermined)
}

func testHostInjectedLocationHeadingRegion() {
  let origin = CLLocation(latitude: 40.7128, longitude: -74.0060)
  let destination = CLLocation(latitude: 51.5074, longitude: -0.1278)
  let region = CLCircularRegion(
    center: origin.coordinate,
    radius: 100,
    identifier: "downtown"
  )
  let manager = CLLocationManager()
  let delegate = LocationDelegate()
  manager.delegate = delegate
  manager._portableSetAuthorization(.authorizedWhenInUse)
  manager.startUpdatingLocation()
  manager.startUpdatingHeading()
  manager.startMonitoring(for: region)
  manager._portableInject(locations: [origin])
  manager._portableInject(
    heading: CLHeading(
      magneticHeading: 14,
      trueHeading: 12,
      headingAccuracy: 1
    )
  )
  precondition(delegate.locations == [origin])
  precondition(delegate.headings.count == 1)
  precondition(delegate.headings[0].magneticHeading == 14)
  precondition(delegate.regionStates == [.inside])
  manager.stopUpdatingLocation()
  manager._portableInject(locations: [destination])
  precondition(delegate.locations == [origin])
  precondition(manager.location == destination)
  manager.requestLocation()
  precondition(delegate.locations == [origin, destination])
  manager.stopUpdatingHeading()
  manager.stopMonitoring(for: region)
  precondition(manager.monitoredRegions.isEmpty)
}

func testGeocoderFailClosedAndHostInjection() {
  let origin = CLLocation(latitude: 40.7128, longitude: -74.0060)
  let geocoder = CLGeocoder()
  precondition(geocoder.isGeocoding == false)
  var failClosed: CLError.Code?
  geocoder.reverseGeocodeLocation(origin) { placemarks, error in
    precondition(placemarks == nil)
    failClosed = (error as? CLError)?.code
  }
  precondition(failClosed == .geocodeFoundNoResult)
  let placemark = CLPlacemark(
    location: origin,
    locality: "New York",
    isoCountryCode: "US",
    country: "United States"
  )
  geocoder._portableSetReverseGeocodeHandler { _ in .success([placemark]) }
  var hostLocality: String?
  geocoder.reverseGeocodeLocation(origin) { placemarks, error in
    precondition(error == nil)
    hostLocality = placemarks?.first?.locality
  }
  precondition(hostLocality == "New York")
  geocoder.cancelGeocode()
  var canceled: CLError.Code?
  geocoder.geocodeAddressString("anywhere") { placemarks, error in
    precondition(placemarks == nil)
    canceled = (error as? CLError)?.code
  }
  precondition(canceled == .geocodeCanceled)
}

func testGeocodeAddressDictionaryAndLocaleOverloads() {
  let geocoder = CLGeocoder()
  var dictionaryCode: CLError.Code?
  geocoder.geocodeAddressDictionary(["City": "Paris"]) { placemarks, error in
    precondition(placemarks == nil)
    dictionaryCode = (error as? CLError)?.code
  }
  precondition(dictionaryCode == .geocodeFoundNoResult)

  let origin = CLLocation(latitude: 40.7128, longitude: -74.0060)
  switch clAwait({
    try await geocoder.geocodeAddressString("nowhere", in: nil, preferredLocale: Locale(identifier: "en_US"))
  }) {
  case .success:
    preconditionFailure("locale geocode invented a result")
  case .failure(let error):
    precondition((error as? CLError)?.code == .geocodeFoundNoResult)
  }
  switch clAwait({ try await geocoder.reverseGeocodeLocation(origin, preferredLocale: nil) }) {
  case .success:
    preconditionFailure("preferred-locale reverse geocode invented a result")
  case .failure(let error):
    precondition((error as? CLError)?.code == .geocodeFoundNoResult)
  }
}

func testEnumRawValues() {
  precondition(CLAccuracyAuthorization.fullAccuracy.rawValue == 0)
  precondition(CLAccuracyAuthorization.reducedAccuracy.rawValue == 1)
  precondition(CLActivityType.other.rawValue == 1)
  precondition(CLActivityType.automotiveNavigation.rawValue == 2)
  precondition(CLActivityType.fitness.rawValue == 3)
  precondition(CLActivityType.otherNavigation.rawValue == 4)
  precondition(CLActivityType.airborne.rawValue == 5)
  precondition(CLAuthorizationStatus.notDetermined.rawValue == 0)
  precondition(CLAuthorizationStatus.restricted.rawValue == 1)
  precondition(CLAuthorizationStatus.denied.rawValue == 2)
  precondition(CLAuthorizationStatus.authorizedWhenInUse.rawValue == 4)
  precondition(CLDeviceOrientation.unknown.rawValue == 0)
  precondition(CLDeviceOrientation.portrait.rawValue == 1)
  precondition(CLDeviceOrientation.portraitUpsideDown.rawValue == 2)
  precondition(CLDeviceOrientation.landscapeLeft.rawValue == 3)
  precondition(CLDeviceOrientation.landscapeRight.rawValue == 4)
  precondition(CLDeviceOrientation.faceUp.rawValue == 5)
  precondition(CLDeviceOrientation.faceDown.rawValue == 6)
  precondition(CLProximity.unknown.rawValue == 0)
  precondition(CLProximity.immediate.rawValue == 1)
  precondition(CLProximity.near.rawValue == 2)
  precondition(CLProximity.far.rawValue == 3)
  precondition(CLRegionState.unknown.rawValue == 0)
  precondition(CLRegionState.inside.rawValue == 1)
  precondition(CLRegionState.outside.rawValue == 2)
  precondition(CLLocationUpdate.LiveConfiguration.default != .fitness)
  precondition(CLLocationUpdate.LiveConfiguration.automotiveNavigation != .airborne)
  precondition(CLLocationUpdate.LiveConfiguration.otherNavigation != .default)
  precondition(CLServiceSession.AuthorizationRequirement.whenInUse != .always)
  precondition(CLServiceSession.AuthorizationRequirement.none != .always)
}

func testCLErrorCodesAndBridging() {
  precondition(CLError.errorDomain == kCLErrorDomain)
  precondition(CLError._nsErrorDomain == kCLErrorDomain)
  let codes: [CLError.Code] = [
    .locationUnknown, .denied, .network, .headingFailure,
    .regionMonitoringDenied, .regionMonitoringFailure,
    .regionMonitoringSetupDelayed, .regionMonitoringResponseDelayed,
    .geocodeFoundNoResult, .geocodeFoundPartialResult, .geocodeCanceled,
    .deferredFailed, .deferredNotUpdatingLocation, .deferredAccuracyTooLow,
    .deferredDistanceFiltered, .deferredCanceled,
    .rangingUnavailable, .rangingFailure, .promptDeclined, .historicalLocationError
  ]
  for (index, code) in codes.enumerated() {
    precondition(code.rawValue == index)
  }
  let denied = CLError(.denied, userInfo: [kCLErrorUserInfoAlternateRegionKey: "unused"])
  precondition(denied.code == .denied)
  precondition(denied.errorCode == 1)
  precondition(denied.userInfo[kCLErrorUserInfoAlternateRegionKey] as? String == "unused")
  precondition(denied.errorUserInfo[kCLErrorUserInfoAlternateRegionKey] as? String == "unused")
  precondition(denied.alternateRegion == nil)
  precondition(!denied.localizedDescription.isEmpty)
  precondition(CLError.promptDeclined == .promptDeclined)
  precondition(CLError.historicalLocationError == .historicalLocationError)
  do {
    throw CLError(.network)
  } catch let error as CLError where error.code == .network {
    ()
  } catch {
    preconditionFailure("expected CLError.network")
  }
}

func testLocationPushServiceError() {
  precondition(CLLocationPushServiceError.errorDomain == CLLocationPushServiceErrorDomain)
  precondition(CLLocationPushServiceError.unknown.rawValue == 0)
  precondition(CLLocationPushServiceError.missingPushExtension.rawValue == 1)
  precondition(CLLocationPushServiceError.missingPushServerEnvironment.rawValue == 2)
  precondition(CLLocationPushServiceError.missingEntitlement.rawValue == 3)
  precondition(CLLocationPushServiceError.unsupportedPlatform.rawValue == 4)
  let error = CLLocationPushServiceError(.unsupportedPlatform)
  precondition(error.code == .unsupportedPlatform)
  precondition(error.errorCode == 4)
  precondition(!error.localizedDescription.isEmpty)
}

func testBeaconIdentityAndPeripheralData() {
  let uuid = UUID()
  let constraint = CLBeaconIdentityConstraint(uuid: uuid, major: 7, minor: 9)
  let region = CLBeaconRegion(beaconIdentityConstraint: constraint, identifier: "store")
  precondition(region.uuid == uuid)
  precondition(region.major?.uint16Value == 7)
  precondition(region.minor?.uint16Value == 9)
  precondition(region.proximityUUID == uuid)
  let viaUUID = CLBeaconRegion(UUID: uuid, identifier: "uuid-label")
  precondition(viaUUID.uuid == uuid)
  let viaProximity = CLBeaconRegion(proximityUUID: uuid, major: 1, minor: 2, identifier: "legacy")
  precondition(viaProximity.major?.uint16Value == 1)
  let payload = region.peripheralData(withMeasuredPower: NSNumber(value: -59))
  precondition(payload["uuid"] as? String == uuid.uuidString)
  precondition(payload["measuredPower"] as? NSNumber == NSNumber(value: -59))
  let beacon = CLBeacon(
    uuid: uuid,
    major: 7,
    minor: 9,
    proximity: .near,
    accuracy: 1.5,
    rssi: -70
  )
  precondition(beacon.proximityUUID == uuid)
  precondition(beacon.proximity == .near)
}

func testRangingVisitsAndDeferredFailClosed() {
  let manager = CLLocationManager()
  let delegate = LocationDelegate()
  manager.delegate = delegate
  precondition(CLLocationManager.isRangingAvailable() == false)
  precondition(CLLocationManager.deferredLocationUpdatesAvailable() == false)
  precondition(manager.isAuthorizedForWidgetUpdates == false)
  let uuid = UUID()
  let region = CLBeaconRegion(uuid: uuid, identifier: "aisle")
  let constraint = CLBeaconIdentityConstraint(uuid: uuid)
  manager.startRangingBeacons(in: region)
  manager.startRangingBeacons(satisfying: constraint)
  precondition(delegate.rangingFailures == [.rangingUnavailable])
  precondition(delegate.constraintFailures == [.rangingUnavailable])
  precondition(manager.rangedRegions.contains(region))
  precondition(manager.rangedBeaconConstraints.contains(constraint))
  manager.stopRangingBeacons(in: region)
  manager.stopRangingBeacons(satisfying: constraint)
  manager.startMonitoringVisits()
  manager.stopMonitoringVisits()
  manager.allowDeferredLocationUpdates(untilTraveled: 100, timeout: 30)
  precondition(delegate.deferredErrors == [.deferredFailed])
  manager.disallowDeferredLocationUpdates()
}

func testTemporaryFullAccuracyAndLocationPushesFailClosed() {
  let manager = CLLocationManager()
  let delegate = LocationDelegate()
  manager.delegate = delegate
  manager.requestTemporaryFullAccuracyAuthorization(withPurposeKey: "example")
  precondition(delegate.errors == [.promptDeclined])
  switch clAwait({
    try await manager.requestTemporaryFullAccuracyAuthorization(withPurposeKey: "example")
  }) {
  case .success:
    preconditionFailure("temporary full accuracy succeeded without a prompt")
  case .failure(let error):
    precondition((error as? CLError)?.code == .promptDeclined)
  }
  var pushError: CLLocationPushServiceError.Code?
  manager.startMonitoringLocationPushes { data, error in
    precondition(data == nil)
    pushError = (error as? CLLocationPushServiceError)?.code
  }
  precondition(pushError == .unsupportedPlatform)
  manager.stopMonitoringLocationPushes()
}

func testPlacemarkCopyAndAddressDictionary() {
  let origin = CLLocation(latitude: 1, longitude: 2)
  let source = CLPlacemark(
    location: origin,
    name: "HQ",
    thoroughfare: "Market St",
    locality: "San Francisco",
    administrativeArea: "CA",
    postalCode: "94105",
    isoCountryCode: "US",
    country: "United States"
  )
  let copy = CLPlacemark(placemark: source)
  precondition(copy.locality == "San Francisco")
  let dictionary = copy.addressDictionary
  precondition(dictionary?["City"] as? String == "San Francisco")
  precondition(dictionary?["CountryCode"] as? String == "US")
  let coder = NSKeyedArchiver(requiringSecureCoding: true)
  precondition(CLPlacemark(coder: coder) == nil)
  precondition(CLBeacon(coder: coder) == nil)
  precondition(CLHeading(coder: coder) == nil)
  precondition(CLRegion(coder: coder) == nil)
  precondition(CLVisit(coder: coder) == nil)
}

func testLocationUpdateLiveUpdatesFailClosed() {
  switch clAwait({
    var iterator = CLLocationUpdate.liveUpdates(.fitness).makeAsyncIterator()
    let first = try await iterator.next()
    let second = try await iterator.next()
    return (first, second)
  }) {
  case .success(let (first, second)):
    precondition(second == nil)
    guard let update = first else {
      preconditionFailure("liveUpdates produced no fail-closed diagnostic")
    }
    precondition(update.location == nil)
    precondition(update.authorizationDenied)
    precondition(update.locationUnavailable)
    precondition(update.stationary == false)
    precondition(update.isStationary == false)
    precondition(update.authorizationDeniedGlobally == false)
    precondition(update.accuracyLimited == false)
    precondition(update.serviceSessionRequired == false)
    precondition(update.authorizationRequestInProgress == false)
    precondition(update.authorizationRestricted == false)
    precondition(update.insufficientlyInUse == false)
  case .failure(let error):
    preconditionFailure("liveUpdates threw \(error)")
  }
}

func testServiceSessionDiagnosticsFailClosed() {
  let session = CLServiceSession(authorization: .whenInUse)
  switch clAwait({
    var iterator = session.diagnostics.makeAsyncIterator()
    let first = try await iterator.next()
    session.invalidate()
    let after = try await iterator.next()
    return (first, after)
  }) {
  case .success(let (first, after)):
    precondition(after == nil)
    guard let diagnostic = first else {
      preconditionFailure("service session produced no diagnostic")
    }
    precondition(diagnostic.authorizationDenied)
    precondition(diagnostic.fullAccuracyDenied == false)
    precondition(diagnostic.alwaysAuthorizationDenied == false)
    precondition(diagnostic.serviceSessionRequired == false)
  case .failure(let error):
    preconditionFailure("service session threw \(error)")
  }
  let keyed = CLServiceSession(authorization: .always, fullAccuracyPurposeKey: "purpose")
  keyed.invalidate()
}

func testBackgroundActivitySessionFailClosed() {
  let session = CLBackgroundActivitySession()
  switch clAwait({
    var iterator = session.diagnostics.makeAsyncIterator()
    let first = try await iterator.next()
    session.invalidate()
    return first
  }) {
  case .success(let first):
    precondition(first?.authorizationDenied == true)
    precondition(first?.authorizationDeniedGlobally == false)
  case .failure(let error):
    preconditionFailure("background session threw \(error)")
  }
}

func testMonitorStoresConditionWithoutHardwareEvents() {
  let center = CLLocationCoordinate2D(latitude: 37.3349, longitude: -122.0090)
  switch clAwait({
    let monitor = await CLMonitor("corelocation-lane")
    let geographic = CLMonitor.CircularGeographicCondition(center: center, radius: 50)
    await monitor.add(geographic, identifier: "campus", assuming: .unknown)
    let beacon = CLMonitor.BeaconIdentityCondition(uuid: UUID(), major: 1, minor: 2)
    await monitor.add(beacon, identifier: "ibeacon")
    let ids = await monitor.identifiers
    let record = await monitor.record(for: "campus")
    var iterator = await monitor.events.makeAsyncIterator()
    let event = try await iterator.next()
    await monitor.remove("ibeacon")
    let remaining = await monitor.identifiers
    return (ids, record?.lastEvent.state, event, remaining, record?.lastEvent.authorizationDenied)
  }) {
  case .success(let (ids, state, event, remaining, denied)):
    precondition(ids.contains("campus"))
    precondition(ids.contains("ibeacon"))
    precondition(state == .unknown)
    precondition(event == nil)
    precondition(remaining == ["campus"])
    precondition(denied == true)
  case .failure(let error):
    preconditionFailure("monitor threw \(error)")
  }
}

func testMonitorConditionCodableRoundTrip() {
  let uuid = UUID()
  let beacon = CLMonitor.BeaconIdentityCondition(uuid: uuid, major: 4)
  let geographic = CLMonitor.CircularGeographicCondition(
    center: CLLocationCoordinate2D(latitude: 10, longitude: 20),
    radius: 30
  )
  let encoder = JSONEncoder()
  let decoder = JSONDecoder()
  do {
    let beaconData = try encoder.encode(beacon)
    let decodedBeacon = try decoder.decode(CLMonitor.BeaconIdentityCondition.self, from: beaconData)
    precondition(decodedBeacon.uuid == uuid)
    precondition(decodedBeacon.major == 4)
    precondition(decodedBeacon.minor == nil)
    let geoData = try encoder.encode(geographic)
    let decodedGeo = try decoder.decode(CLMonitor.CircularGeographicCondition.self, from: geoData)
    precondition(decodedGeo.center.latitude == 10)
    precondition(decodedGeo.radius == 30)
  } catch {
    preconditionFailure("condition Codable failed: \(error)")
  }
}

func testHeadingVisitAndManagerDefaults() {
  let heading = CLHeading(magneticHeading: 90, trueHeading: 88, headingAccuracy: 2, x: 1, y: 2, z: 3)
  precondition(heading.x == 1)
  precondition(heading.y == 2)
  precondition(heading.z == 3)
  let visit = CLVisit(
    coordinate: CLLocationCoordinate2D(latitude: 1, longitude: 2),
    horizontalAccuracy: 5,
    arrivalDate: Date(timeIntervalSince1970: 1),
    departureDate: Date(timeIntervalSince1970: 2)
  )
  precondition(visit.horizontalAccuracy == 5)
  let manager = CLLocationManager()
  precondition(manager.desiredAccuracy == kCLLocationAccuracyBest)
  precondition(manager.distanceFilter == kCLDistanceFilterNone)
  precondition(manager.headingFilter == 1)
  precondition(manager.activityType == .other)
  precondition(manager.headingOrientation == .portrait)
  precondition(CLLocationManager.locationServicesEnabled())
  precondition(CLLocationManager.headingAvailable())
  manager.dismissHeadingCalibrationDisplay()
  manager.startMonitoringSignificantLocationChanges()
  manager.stopMonitoringSignificantLocationChanges()
}
