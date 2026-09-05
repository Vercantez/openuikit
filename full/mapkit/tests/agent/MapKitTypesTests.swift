import MapKit
import Foundation

func testErrorCodes() {
    precondition(MKError.Code.unknown.rawValue == 1)
    precondition(MKError.Code.serverFailure.rawValue == 2)
    precondition(MKError.Code.loadingThrottled.rawValue == 3)
    precondition(MKError.Code.placemarkNotFound.rawValue == 4)
    precondition(MKError.Code.directionsNotFound.rawValue == 5)
    precondition(MKError.Code.decodingFailed.rawValue == 6)
    precondition(MKError.unknown == .unknown)
    precondition(MKError.serverFailure == .serverFailure)
    precondition(MKError.loadingThrottled == .loadingThrottled)
    precondition(MKError.placemarkNotFound == .placemarkNotFound)
    precondition(MKError.directionsNotFound == .directionsNotFound)
    precondition(MKError.decodingFailed == .decodingFailed)
    let error = MKError(.placemarkNotFound, userInfo: ["reason": "none"])
    precondition(error.code == .placemarkNotFound)
    precondition(error.errorCode == 4)
    precondition(MKError.errorDomain == MKErrorDomain)
    precondition(error.errorUserInfo["reason"] as? String == "none")
    precondition(!error.localizedDescription.isEmpty)
    precondition(error.code == MKError(.placemarkNotFound).code)
    var hasher = Hasher()
    error.hash(into: &hasher)
    _ = hasher.finalize()
    precondition((MKError.Code.placemarkNotFound ~= error) == true)
    let other: any Error = MKError(.unknown)
    precondition((MKError.Code.placemarkNotFound ~= other) == false)
    precondition(MKError.Code(rawValue: 1) == .unknown)
    precondition(MKError.Code(rawValue: 99) == nil)
    _ = error.hashValue
    _ = MKError.Code.unknown.hashValue
}

func testMapTypeAndVisibilityEnums() {
    precondition(MKMapType.standard.rawValue == 0)
    precondition(MKMapType.satellite.rawValue == 1)
    precondition(MKMapType.hybrid.rawValue == 2)
    precondition(MKMapType.satelliteFlyover.rawValue == 3)
    precondition(MKMapType.hybridFlyover.rawValue == 4)
    precondition(MKMapType.mutedStandard.rawValue == 5)
    precondition(MKMapType.standard != .hybrid)
    precondition(MKFeatureVisibility.adaptive.rawValue == 0)
    precondition(MKFeatureVisibility.hidden.rawValue == 1)
    precondition(MKFeatureVisibility.visible.rawValue == 2)
    precondition(MKOverlayLevel.aboveRoads.rawValue == 0)
    precondition(MKOverlayLevel.aboveLabels.rawValue == 1)
    precondition(MKUserTrackingMode.none.rawValue == 0)
    precondition(MKUserTrackingMode.follow.rawValue == 1)
    precondition(MKUserTrackingMode.followWithHeading.rawValue == 2)
    precondition(MKPinAnnotationColor.red.rawValue == 0)
    precondition(MKPinAnnotationColor.green.rawValue == 1)
    precondition(MKPinAnnotationColor.purple.rawValue == 2)
    precondition(MKLookAroundBadgePosition.topLeading.rawValue == 0)
    precondition(MKLookAroundBadgePosition.topTrailing.rawValue == 1)
    precondition(MKLookAroundBadgePosition.bottomTrailing.rawValue == 2)
    precondition(MKDirections.RoutePreference.any.rawValue == 0)
    precondition(MKDirections.RoutePreference.avoid.rawValue == 1)
    precondition(MKLocalSearchRegionPriority.default.rawValue == 0)
    precondition(MKLocalSearchRegionPriority.required.rawValue == 1)
    precondition(MKLocalSearchCompleter.FilterType.locationsAndQueries.rawValue == 0)
    precondition(MKLocalSearchCompleter.FilterType.locationsOnly.rawValue == 1)
    precondition(MKAnnotationView.CollisionMode.rectangle.rawValue == 0)
    precondition(MKAnnotationView.CollisionMode.circle.rawValue == 1)
    precondition(MKAnnotationView.CollisionMode.none.rawValue == 2)
    precondition(MKAnnotationView.DragState.none.rawValue == 0)
    precondition(MKAnnotationView.DragState.starting.rawValue == 1)
    precondition(MKAnnotationView.DragState.dragging.rawValue == 2)
    precondition(MKAnnotationView.DragState.canceling.rawValue == 3)
    precondition(MKAnnotationView.DragState.ending.rawValue == 4)
    precondition(MKMapConfiguration.ElevationStyle.flat.rawValue == 0)
    precondition(MKMapConfiguration.ElevationStyle.realistic.rawValue == 1)
    precondition(MKStandardMapConfiguration.EmphasisStyle.default.rawValue == 0)
    precondition(MKStandardMapConfiguration.EmphasisStyle.muted.rawValue == 1)
    precondition(MKScaleView.Alignment.leading.rawValue == 0)
    precondition(MKScaleView.Alignment.trailing.rawValue == 1)
    precondition(MKScaleView.Alignment.center.rawValue == 2)
    precondition(MKMapFeatureAnnotation.FeatureType.pointOfInterest.rawValue == 0)
    precondition(MKMapFeatureAnnotation.FeatureType.territory.rawValue == 1)
    precondition(MKMapFeatureAnnotation.FeatureType.physicalFeature.rawValue == 2)
    precondition(MKSelectionAccessory.MapItemDetailPresentationStyle.CalloutStyle.automatic.rawValue == 0)
    precondition(MKSelectionAccessory.MapItemDetailPresentationStyle.CalloutStyle.full.rawValue == 1)
    precondition(MKSelectionAccessory.MapItemDetailPresentationStyle.CalloutStyle.compact.rawValue == 2)
    precondition(MKAddressRepresentations.ContextStyle.automatic.rawValue == 0)
    precondition(MKAddressRepresentations.ContextStyle.full.rawValue == 1)
    precondition(MKAddressRepresentations.ContextStyle.short.rawValue == 2)
    var hasher = Hasher()
    MKMapType.standard.hash(into: &hasher)
    MKFeatureVisibility.visible.hash(into: &hasher)
    _ = hasher.finalize()
    _ = MKMapType.standard.hashValue
    _ = MKFeatureVisibility.visible.hashValue
    _ = MKOverlayLevel.aboveRoads.hashValue
    _ = MKUserTrackingMode.none.hashValue
    _ = MKPinAnnotationColor.red.hashValue
    _ = MKLookAroundBadgePosition.topLeading.hashValue
    _ = MKDirections.RoutePreference.any.hashValue
    _ = MKLocalSearchRegionPriority.default.hashValue
    _ = MKLocalSearchCompleter.FilterType.locationsAndQueries.hashValue
    _ = MKAnnotationView.CollisionMode.rectangle.hashValue
    _ = MKAnnotationView.DragState.none.hashValue
    _ = MKMapConfiguration.ElevationStyle.flat.hashValue
    _ = MKStandardMapConfiguration.EmphasisStyle.default.hashValue
    _ = MKScaleView.Alignment.leading.hashValue
    _ = MKMapFeatureAnnotation.FeatureType.pointOfInterest.hashValue
    _ = MKSelectionAccessory.MapItemDetailPresentationStyle.CalloutStyle.automatic.hashValue
    _ = MKAddressRepresentations.ContextStyle.automatic.hashValue
}

func testTransportOptionSet() {
    var transport: MKDirectionsTransportType = [.automobile, .walking]
    precondition(transport.contains(.automobile))
    precondition(transport.contains(.walking))
    precondition(!transport.contains(.transit))
    precondition(MKDirectionsTransportType.cycling.rawValue == 1 << 3)
    precondition(MKDirectionsTransportType.any.rawValue == 0x0FFF_FFFF)
    _ = transport.insert(.transit)
    precondition(transport.contains(.transit))
    _ = transport.remove(.walking)
    precondition(!transport.contains(.walking))
    _ = transport.update(with: .cycling)
    let unioned = MKDirectionsTransportType.automobile.union(.transit)
    precondition(unioned.contains(.automobile) && unioned.contains(.transit))
    let inter = unioned.intersection(.transit)
    precondition(inter == .transit)
    let sym = MKDirectionsTransportType.automobile.symmetricDifference(.walking)
    precondition(sym.contains(.automobile) && sym.contains(.walking))
    precondition(MKDirectionsTransportType.automobile.isDisjoint(with: .walking))
    precondition(MKDirectionsTransportType.any.isSuperset(of: .automobile))
    precondition(MKDirectionsTransportType.automobile.isSubset(of: .any))
    precondition(MKDirectionsTransportType.automobile.isStrictSubset(of: .any))
    precondition(MKDirectionsTransportType.any.isStrictSuperset(of: .automobile))
    var mutable = MKDirectionsTransportType.automobile
    mutable.formUnion(.walking)
    mutable.formIntersection(.any)
    mutable.formSymmetricDifference(.transit)
    mutable.subtract(.transit)
    precondition(mutable.subtracting(.walking).contains(.automobile))
    precondition(MKDirectionsTransportType().isEmpty)
    let fromArray: MKDirectionsTransportType = [.automobile, .cycling]
    precondition(fromArray.contains(.cycling))
    let fromSeq = MKDirectionsTransportType([.walking, .transit])
    precondition(fromSeq.contains(.walking))
    precondition(MKDirectionsTransportType.automobile != .walking)
    var hasher = Hasher()
    MKDirectionsTransportType.automobile.hash(into: &hasher)
    _ = hasher.finalize()
}

func testAddressFilterOptions() {
    var options: MKAddressFilter.Options = [.country, .locality]
    precondition(options.contains(.country))
    precondition(options.contains(.locality))
    precondition(!options.contains(.postalCode))
    _ = options.insert(.postalCode)
    _ = options.remove(.country)
    _ = options.update(with: .administrativeArea)
    precondition(MKAddressFilter.Options.subAdministrativeArea.rawValue == 1 << 2)
    precondition(MKAddressFilter.Options.subLocality.rawValue == 1 << 4)
    let unioned = MKAddressFilter.Options.country.union(.locality)
    _ = unioned.intersection(.country)
    _ = unioned.symmetricDifference(.postalCode)
    precondition(MKAddressFilter.Options.country.isSubset(of: unioned))
    precondition(MKAddressFilter.Options.country.isStrictSubset(of: unioned))
    precondition(unioned.isSuperset(of: .country))
    precondition(unioned.isStrictSuperset(of: .country))
    precondition(MKAddressFilter.Options.country.isDisjoint(with: .locality))
    var mutable = MKAddressFilter.Options.country
    mutable.formUnion(.locality)
    mutable.formIntersection(.country)
    mutable.formSymmetricDifference(.postalCode)
    mutable.subtract(.postalCode)
    _ = mutable.subtracting(.country)
    precondition(MKAddressFilter.Options().isEmpty)
    let fromArray: MKAddressFilter.Options = [.country]
    precondition(fromArray.contains(.country))
    let fromSeq = MKAddressFilter.Options([.locality])
    precondition(fromSeq.contains(.locality))
    precondition(MKAddressFilter.Options.country != .locality)
    var hasher = Hasher()
    MKAddressFilter.Options.country.hash(into: &hasher)
    _ = hasher.finalize()
}

func testLocalSearchResultTypes() {
    var completer: MKLocalSearchCompleter.ResultType = [.address, .query]
    precondition(completer.contains(.address))
    precondition(completer.contains(.query))
    precondition(MKLocalSearchCompleter.ResultType.pointOfInterest.rawValue == 1 << 1)
    precondition(MKLocalSearchCompleter.ResultType.physicalFeature.rawValue == 1 << 3)
    _ = completer.insert(.pointOfInterest)
    _ = completer.remove(.query)
    _ = completer.update(with: .physicalFeature)
    _ = completer.union(.query)
    _ = completer.intersection(.address)
    _ = completer.symmetricDifference(.query)
    _ = completer.isDisjoint(with: .query)
    _ = completer.isSubset(of: .init(rawValue: ~UInt(0)))
    _ = completer.isSuperset(of: .address)
    _ = completer.isStrictSubset(of: .init(rawValue: ~UInt(0)))
    _ = completer.isStrictSuperset(of: [])
    var m = MKLocalSearchCompleter.ResultType.address
    m.formUnion(.query)
    m.formIntersection(.address)
    m.formSymmetricDifference(.pointOfInterest)
    m.subtract(.pointOfInterest)
    _ = m.subtracting(.address)
    _ = MKLocalSearchCompleter.ResultType().isEmpty
    let literal: MKLocalSearchCompleter.ResultType = [.address]
    precondition(literal.contains(.address))
    _ = MKLocalSearchCompleter.ResultType([.query])
    precondition(MKLocalSearchCompleter.ResultType.address != .query)

    var search: MKLocalSearch.ResultType = [.address, .pointOfInterest]
    precondition(search.contains(.address))
    precondition(MKLocalSearch.ResultType.physicalFeature.rawValue == 1 << 2)
    _ = search.insert(.physicalFeature)
    _ = search.remove(.address)
    _ = search.update(with: .address)
    _ = search.union(.pointOfInterest)
    _ = search.intersection(.pointOfInterest)
    _ = search.symmetricDifference(.address)
    _ = search.isDisjoint(with: [])
    _ = search.isSubset(of: .init(rawValue: ~UInt(0)))
    _ = search.isSuperset(of: .pointOfInterest)
    _ = search.isStrictSubset(of: .init(rawValue: ~UInt(0)))
    _ = search.isStrictSuperset(of: [])
    var sm = MKLocalSearch.ResultType.address
    sm.formUnion(.pointOfInterest)
    sm.formIntersection(.address)
    sm.formSymmetricDifference(.physicalFeature)
    sm.subtract(.physicalFeature)
    _ = sm.subtracting(.address)
    _ = MKLocalSearch.ResultType().isEmpty
    let searchLiteral: MKLocalSearch.ResultType = [.address]
    precondition(searchLiteral.contains(.address))
    _ = MKLocalSearch.ResultType([.pointOfInterest])
    precondition(MKLocalSearch.ResultType.address != .pointOfInterest)
    var hasher = Hasher()
    MKLocalSearchCompleter.ResultType.address.hash(into: &hasher)
    MKLocalSearch.ResultType.address.hash(into: &hasher)
    _ = hasher.finalize()
}

func testMapFeatureOptions() {
    var options: MKMapFeatureOptions = [.pointsOfInterest, .territories]
    precondition(options.contains(.pointsOfInterest))
    precondition(options.contains(.territories))
    precondition(MKMapFeatureOptions.physicalFeatures.rawValue == 1 << 2)
    _ = options.insert(.physicalFeatures)
    _ = options.remove(.territories)
    _ = options.update(with: .territories)
    _ = options.union(.physicalFeatures)
    _ = options.intersection(.pointsOfInterest)
    _ = options.symmetricDifference(.territories)
    _ = options.isDisjoint(with: [])
    _ = options.isSubset(of: .init(rawValue: ~0))
    _ = options.isSuperset(of: .pointsOfInterest)
    _ = options.isStrictSubset(of: .init(rawValue: ~0))
    _ = options.isStrictSuperset(of: [])
    var mutable = MKMapFeatureOptions.pointsOfInterest
    mutable.formUnion(.territories)
    mutable.formIntersection(.pointsOfInterest)
    mutable.formSymmetricDifference(.physicalFeatures)
    mutable.subtract(.physicalFeatures)
    _ = mutable.subtracting(.pointsOfInterest)
    precondition(MKMapFeatureOptions().isEmpty)
    let literal: MKMapFeatureOptions = [.pointsOfInterest]
    precondition(literal.contains(.pointsOfInterest))
    _ = MKMapFeatureOptions([.territories])
    precondition(MKMapFeatureOptions.pointsOfInterest != .territories)
    var hasher = Hasher()
    MKMapFeatureOptions.pointsOfInterest.hash(into: &hasher)
    _ = hasher.finalize()
}

func testAddressFilterClass() {
    let including = MKAddressFilter(including: [.country, .locality])
    precondition(including.includes(.country))
    precondition(including.includes(.locality))
    precondition(!including.includes(.postalCode))
    precondition(including.excludes(.postalCode))
    let includingAlias = MKAddressFilter(includingOptions: [.postalCode])
    precondition(includingAlias.includes(.postalCode))
    let excluding = MKAddressFilter(excluding: [.country])
    precondition(excluding.excludes(.country))
    precondition(excluding.includes(.locality))
    let excludingAlias = MKAddressFilter(excludingOptions: [.locality])
    precondition(excludingAlias.excludes(.locality))
    precondition(MKAddressFilter.includingAll.includes(.country))
    precondition(MKAddressFilter.excludingAll.excludes(.country))
    let copied = including.copy() as! MKAddressFilter
    precondition(copied.includes(.country))
}

func testDistanceFormatter() {
    let formatter = MKDistanceFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.units = .metric
    formatter.unitStyle = .abbreviated
    let km = formatter.string(fromDistance: 5000)
    precondition(mk_testContains(km, "km") || mk_testContains(km, "5"))
    let meters = formatter.string(fromDistance: 12)
    precondition(mk_testContains(meters, "m"))
    let parsed = formatter.distance(from: "5 km")
    precondition(abs(parsed - 5000) < 1)
    precondition(formatter.distance(from: "") == 0)
    formatter.units = .imperial
    let miles = formatter.string(fromDistance: 1609.344)
    precondition(mk_testContains(miles, "mi") || mk_testContains(miles, "1"))
    formatter.units = .imperialWithYards
    formatter.unitStyle = .full
    let yards = formatter.string(fromDistance: 9.144)
    precondition(mk_testContains(yards, "yard") || mk_testContains(yards, "10"))
    formatter.units = .default
    formatter.unitStyle = .default
    _ = formatter.string(fromDistance: 100)
    precondition(MKDistanceFormatter.Units.metric != .imperial)
    precondition(MKDistanceFormatter.DistanceUnitStyle.abbreviated != .full)
    var hasher = Hasher()
    MKDistanceFormatter.Units.metric.hash(into: &hasher)
    MKDistanceFormatter.DistanceUnitStyle.abbreviated.hash(into: &hasher)
    _ = hasher.finalize()
}

func testPointOfInterestFilter() {
    let including = MKPointOfInterestFilter(including: [.airport, .cafe])
    precondition(including.includes(.airport))
    precondition(!including.includes(.zoo))
    precondition(including.excludes(.zoo))
    let alias = MKPointOfInterestFilter(includingCategories: [.museum])
    precondition(alias.includes(.museum))
    let excluding = MKPointOfInterestFilter(excluding: [.airport])
    precondition(excluding.excludes(.airport))
    precondition(excluding.includes(.cafe))
    let excludingAlias = MKPointOfInterestFilter(excludingCategories: [.cafe])
    precondition(excludingAlias.excludes(.cafe))
    precondition(MKPointOfInterestFilter.includingAll.includes(.zoo))
    precondition(MKPointOfInterestFilter.excludingAll.excludes(.zoo))
    let copied = including.copy() as! MKPointOfInterestFilter
    precondition(copied.includes(.airport))
}

func testPointOfInterestCategoryRawValues() {
    // Darwin macOS 26.1: raw strings are `MKPOICategory…` (not `MKPointOfInterestCategory…`).
    let samples: [(MKPointOfInterestCategory, String)] = [
        (.atm, "MKPOICategoryATM"),
        (.airport, "MKPOICategoryAirport"),
        (.cafe, "MKPOICategoryCafe"),
        (.evCharger, "MKPOICategoryEVCharger"),
        (.museum, "MKPOICategoryMuseum"),
        (.nationalPark, "MKPOICategoryNationalPark"),
        (.restaurant, "MKPOICategoryRestaurant"),
        (.zoo, "MKPOICategoryZoo"),
    ]
    for (category, raw) in samples {
        precondition(category.rawValue == raw)
    }
    let all: [MKPointOfInterestCategory] = [
        .atm, .airport, .amusementPark, .animalService, .aquarium, .automotiveRepair,
        .bakery, .bank, .baseball, .basketball, .beach, .beauty, .bowling, .brewery,
        .cafe, .campground, .carRental, .castle, .conventionCenter, .distillery,
        .evCharger, .fairground, .fireStation, .fishing, .fitnessCenter, .foodMarket,
        .fortress, .gasStation, .goKart, .golf, .hiking, .hospital, .hotel, .kayaking,
        .landmark, .laundry, .library, .mailbox, .marina, .miniGolf, .movieTheater,
        .museum, .musicVenue, .nationalMonument, .nationalPark, .nightlife, .park,
        .parking, .pharmacy, .planetarium, .police, .postOffice, .publicTransport,
        .rvPark, .restaurant, .restroom, .rockClimbing, .school, .skatePark, .skating,
        .skiing, .soccer, .spa, .stadium, .store, .surfing, .swimming, .tennis,
        .theater, .university, .volleyball, .winery, .zoo,
    ]
    for category in all {
        precondition(category.rawValue.hasPrefix("MKPOICategory"))
        precondition(MKPointOfInterestCategory(rawValue: category.rawValue) == category)
    }
    precondition(all.count == 73)
}

func testDisplayPriorities() {
    precondition(MKFeatureDisplayPriority.required.rawValue == 1000)
    precondition(MKFeatureDisplayPriority.defaultHigh.rawValue == 750)
    precondition(MKFeatureDisplayPriority.defaultLow.rawValue == 250)
    precondition(MKAnnotationViewZPriority.max.rawValue == 1000)
    precondition(MKAnnotationViewZPriority.defaultSelected.rawValue == 1000)
    precondition(MKAnnotationViewZPriority.defaultUnselected.rawValue == 500)
    precondition(MKAnnotationViewZPriority.min.rawValue == 0)
    var hasher = Hasher()
    MKFeatureDisplayPriority.required.hash(into: &hasher)
    MKAnnotationViewZPriority.max.hash(into: &hasher)
    MKPointOfInterestCategory.airport.hash(into: &hasher)
    _ = hasher.finalize()
    precondition(MKFeatureDisplayPriority.required != MKFeatureDisplayPriority.defaultLow)
    precondition(MKAnnotationViewZPriority.max != .min)
    precondition(MKPointOfInterestCategory.airport != .zoo)
    precondition(MKPointOfInterestCategory.airport.rawValue == "MKPOICategoryAirport")
    _ = MKFeatureDisplayPriority.required.hashValue
    _ = MKAnnotationViewZPriority.max.hashValue
    _ = MKPointOfInterestCategory.airport.hashValue
}

func testNotificationName() {
    precondition(
        Notification.Name.MKAnnotationCalloutInfoDidChange.rawValue
            == "MKAnnotationCalloutInfoDidChangeNotification"
    )
    precondition(MKAnnotationCalloutInfoDidChangeNotification == "MKAnnotationCalloutInfoDidChangeNotification")
    precondition(MKErrorDomain == "MKErrorDomain")
    precondition(MKLaunchOptionsDirectionsModeKey == "MKLaunchOptionsDirectionsMode")
    precondition(MKLaunchOptionsMapCenterKey == "MKLaunchOptionsMapCenter")
    precondition(MKLaunchOptionsMapSpanKey == "MKLaunchOptionsMapSpan")
    precondition(MKLaunchOptionsMapTypeKey == "MKLaunchOptionsMapType")
    precondition(MKLaunchOptionsShowsTrafficKey == "MKLaunchOptionsShowsTraffic")
    precondition(MKLaunchOptionsCameraKey == "MKLaunchOptionsCameraKey")
    precondition(MKLaunchOptionsDirectionsModeDriving == "MKLaunchOptionsDirectionsModeDriving")
    precondition(MKLaunchOptionsDirectionsModeWalking == "MKLaunchOptionsDirectionsModeWalking")
    precondition(MKLaunchOptionsDirectionsModeTransit == "MKLaunchOptionsDirectionsModeTransit")
    precondition(MKLaunchOptionsDirectionsModeDefault == "MKLaunchOptionsDirectionsModeDefault")
    precondition(MKLaunchOptionsDirectionsModeCycling == "MKLaunchOptionsDirectionsModeCycling")
    precondition(MKMapViewDefaultAnnotationViewReuseIdentifier == "MKMapViewDefaultAnnotationViewReuseIdentifier")
    precondition(MKMapViewDefaultClusterAnnotationViewReuseIdentifier == "MKMapViewDefaultClusterAnnotationViewReuseIdentifier")
    precondition(MKMapItemTypeIdentifier == "com.apple.mapkit.map-item")
    precondition(MKMapCameraZoomDefault == -1)
}
