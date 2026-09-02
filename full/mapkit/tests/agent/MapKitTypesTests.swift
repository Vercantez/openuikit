import MapKit
import Foundation

func testErrorCodesAndDomain() {
    precondition(MKErrorDomain == "MKErrorDomain")
    precondition(MKError.Code.unknown.rawValue == 1)
    precondition(MKError.Code.serverFailure.rawValue == 2)
    precondition(MKError.Code.loadingThrottled.rawValue == 3)
    precondition(MKError.Code.placemarkNotFound.rawValue == 4)
    precondition(MKError.Code.directionsNotFound.rawValue == 5)
    precondition(MKError.Code.decodingFailed.rawValue == 6)
    let error = MKError(.directionsNotFound, userInfo: ["k": "v"])
    precondition(error.code == .directionsNotFound)
    precondition(error.errorCode == 5)
    precondition(MKError.errorDomain == MKErrorDomain)
    precondition(MKError.unknown == .unknown)
    precondition(MKError.serverFailure == .serverFailure)
    precondition(MKError.loadingThrottled == .loadingThrottled)
    precondition(MKError.placemarkNotFound == .placemarkNotFound)
    precondition(MKError.directionsNotFound == .directionsNotFound)
    precondition(MKError.decodingFailed == .decodingFailed)
    precondition(error != MKError(.unknown))
    precondition(MKError.Code.directionsNotFound ~= error)
    _ = error.hashValue
    _ = error.localizedDescription
    _ = error.errorUserInfo
    _ = error.userInfo
    precondition(MKError.Code(rawValue: 1) == .unknown)
}

func testMapTypeAndOverlayLevel() {
    precondition(MKMapType.standard.rawValue == 0)
    precondition(MKMapType.satellite.rawValue == 1)
    precondition(MKMapType.hybrid.rawValue == 2)
    precondition(MKMapType.satelliteFlyover.rawValue == 3)
    precondition(MKMapType.hybridFlyover.rawValue == 4)
    precondition(MKMapType.mutedStandard.rawValue == 5)
    precondition(MKOverlayLevel.aboveRoads.rawValue == 0)
    precondition(MKOverlayLevel.aboveLabels.rawValue == 1)
    precondition(MKFeatureVisibility.adaptive.rawValue == 0)
    precondition(MKFeatureVisibility.hidden.rawValue == 1)
    precondition(MKFeatureVisibility.visible.rawValue == 2)
    precondition(MKPinAnnotationColor.red.rawValue == 0)
    precondition(MKPinAnnotationColor.green.rawValue == 1)
    precondition(MKPinAnnotationColor.purple.rawValue == 2)
    precondition(MKUserTrackingMode.none.rawValue == 0)
    precondition(MKUserTrackingMode.follow.rawValue == 1)
    precondition(MKUserTrackingMode.followWithHeading.rawValue == 2)
    precondition(MKLocalSearchRegionPriority.default.rawValue == 0)
    precondition(MKLocalSearchRegionPriority.required.rawValue == 1)
    precondition(MKLookAroundBadgePosition.topLeading.rawValue == 0)
    precondition(MKLookAroundBadgePosition.topTrailing.rawValue == 1)
    precondition(MKLookAroundBadgePosition.bottomTrailing.rawValue == 2)
}

func testDirectionsTransportType() {
    var types: MKDirectionsTransportType = [.automobile, .walking]
    precondition(types.contains(.automobile))
    precondition(types.contains(.walking))
    precondition(!types.contains(.transit))
    types.insert(.cycling)
    precondition(types.contains(.cycling))
    types.remove(.walking)
    precondition(!types.contains(.walking))
    let mixed = MKDirectionsTransportType.automobile.union(.transit)
    precondition(mixed.intersection(.transit) == .transit)
    precondition(!MKDirectionsTransportType.automobile.isDisjoint(with: .any))
    precondition(MKDirectionsTransportType.any.rawValue == 0x0FFF_FFFF)
    precondition(MKDirectionsTransportType() != .automobile)
}

func testAddressFilterOptions() {
    var options: MKAddressFilter.Options = [.country, .locality]
    precondition(options.contains(.country))
    precondition(options.contains(.locality))
    precondition(!options.contains(.postalCode))
    options.formUnion(.postalCode)
    precondition(options.contains(.postalCode))
    options.formIntersection([.country, .postalCode])
    precondition(options.contains(.country))
    precondition(!options.contains(.locality))
    let empty = MKAddressFilter.Options()
    precondition(empty.isEmpty)
    precondition(empty.isDisjoint(with: .country))
    precondition(MKAddressFilter.Options.country != .locality)
    precondition(options.isSuperset(of: .country))
    precondition(!options.isSubset(of: .country))
    var copy = options
    copy.subtract(.country)
    precondition(!copy.contains(.country))
    _ = copy.symmetricDifference(.locality)
    _ = MKAddressFilter.Options(arrayLiteral: .country, .locality)
}

func testLocalSearchResultTypes() {
    var completer: MKLocalSearchCompleter.ResultType = [.address, .query]
    precondition(completer.contains(.address))
    precondition(completer.contains(.query))
    completer.insert(.pointOfInterest)
    precondition(completer.contains(.pointOfInterest))
    completer.remove(.query)
    precondition(!completer.contains(.query))
    precondition(MKLocalSearchCompleter.ResultType.physicalFeature.rawValue == 1 << 3)
    var search: MKLocalSearch.ResultType = [.address, .pointOfInterest]
    precondition(search.contains(.address))
    search.formUnion(.physicalFeature)
    precondition(search.contains(.physicalFeature))
    precondition(MKMapFeatureOptions.pointsOfInterest.rawValue == 1)
    precondition(MKMapFeatureOptions.territories.rawValue == 2)
    precondition(MKMapFeatureOptions.physicalFeatures.rawValue == 4)
    var features: MKMapFeatureOptions = [.pointsOfInterest]
    features.insert(.territories)
    precondition(features.contains(.territories))
}

func testNestedEnums() {
    precondition(MKDirections.RoutePreference.any.rawValue == 0)
    precondition(MKDirections.RoutePreference.avoid.rawValue == 1)
    precondition(MKDistanceFormatter.Units.default.rawValue == 0)
    precondition(MKDistanceFormatter.Units.metric.rawValue == 1)
    precondition(MKDistanceFormatter.Units.imperial.rawValue == 2)
    precondition(MKDistanceFormatter.Units.imperialWithYards.rawValue == 3)
    precondition(MKDistanceFormatter.DistanceUnitStyle.default.rawValue == 0)
    precondition(MKDistanceFormatter.DistanceUnitStyle.abbreviated.rawValue == 1)
    precondition(MKDistanceFormatter.DistanceUnitStyle.full.rawValue == 2)
    precondition(MKMapConfiguration.ElevationStyle.flat.rawValue == 0)
    precondition(MKMapConfiguration.ElevationStyle.realistic.rawValue == 1)
    precondition(MKStandardMapConfiguration.EmphasisStyle.default.rawValue == 0)
    precondition(MKStandardMapConfiguration.EmphasisStyle.muted.rawValue == 1)
    precondition(MKLocalSearchCompleter.FilterType.locationsAndQueries.rawValue == 0)
    precondition(MKLocalSearchCompleter.FilterType.locationsOnly.rawValue == 1)
    precondition(MKMapFeatureAnnotation.FeatureType.pointOfInterest.rawValue == 0)
    precondition(MKMapFeatureAnnotation.FeatureType.territory.rawValue == 1)
    precondition(MKMapFeatureAnnotation.FeatureType.physicalFeature.rawValue == 2)
    precondition(MKAddressRepresentations.ContextStyle.automatic.rawValue == 0)
    precondition(MKAddressRepresentations.ContextStyle.short.rawValue == 1)
    precondition(MKAddressRepresentations.ContextStyle.full.rawValue == 2)
    precondition(MKSelectionAccessory.MapItemDetailPresentationStyle.CalloutStyle.automatic.rawValue == 0)
    precondition(MKSelectionAccessory.MapItemDetailPresentationStyle.CalloutStyle.full.rawValue == 1)
    precondition(MKSelectionAccessory.MapItemDetailPresentationStyle.CalloutStyle.compact.rawValue == 2)
}

func testPriorities() {
    precondition(MKFeatureDisplayPriority.required.rawValue == 1000)
    precondition(MKFeatureDisplayPriority.defaultHigh.rawValue == 750)
    precondition(MKFeatureDisplayPriority.defaultLow.rawValue == 250)
    precondition(MKAnnotationViewZPriority.min.rawValue == 0)
    precondition(MKAnnotationViewZPriority.max.rawValue == 1000)
    precondition(MKAnnotationViewZPriority.defaultUnselected.rawValue == 250)
    precondition(MKAnnotationViewZPriority.defaultSelected.rawValue == 1000)
    let custom = MKAnnotationViewZPriority(500)
    precondition(custom.rawValue == 500)
}

func testPointOfInterestCategories() {
    let categories: [MKPointOfInterestCategory] = [
        .airport, .amusementPark, .aquarium, .atm, .bakery, .bank, .beach, .brewery,
        .cafe, .campground, .carRental, .evCharger, .fireStation, .fitnessCenter,
        .foodMarket, .gasStation, .hospital, .hotel, .laundry, .library, .marina,
        .movieTheater, .museum, .nationalPark, .nightlife, .park, .parking, .pharmacy,
        .police, .postOffice, .publicTransport, .restaurant, .restroom, .school,
        .stadium, .store, .theater, .university, .winery, .zoo, .animalService,
        .automotiveRepair, .baseball, .basketball, .beauty, .bowling, .castle,
        .conventionCenter, .distillery, .fairground, .fishing, .fortress, .golf,
        .goKart, .hiking, .kayaking, .landmark, .mailbox, .miniGolf, .musicVenue,
        .nationalMonument, .planetarium, .rockClimbing, .rvPark, .skatePark, .skating,
        .skiing, .soccer, .spa, .surfing, .swimming, .tennis, .volleyball
    ]
    let unique = Set(categories.map(\.rawValue))
    precondition(unique.count == categories.count)
    precondition(MKPointOfInterestCategory.airport.rawValue.contains("Airport"))
}

func testLaunchOptionConstants() {
    precondition(MKLaunchOptionsCameraKey == "MKLaunchOptionsCameraKey")
    precondition(MKLaunchOptionsDirectionsModeKey == "MKLaunchOptionsDirectionsModeKey")
    precondition(MKLaunchOptionsDirectionsModeCycling == "MKLaunchOptionsDirectionsModeCycling")
    precondition(MKLaunchOptionsDirectionsModeDefault == "MKLaunchOptionsDirectionsModeDefault")
    precondition(MKLaunchOptionsDirectionsModeDriving == "MKLaunchOptionsDirectionsModeDriving")
    precondition(MKLaunchOptionsDirectionsModeTransit == "MKLaunchOptionsDirectionsModeTransit")
    precondition(MKLaunchOptionsDirectionsModeWalking == "MKLaunchOptionsDirectionsModeWalking")
    precondition(MKLaunchOptionsMapCenterKey == "MKLaunchOptionsMapCenterKey")
    precondition(MKLaunchOptionsMapSpanKey == "MKLaunchOptionsMapSpanKey")
    precondition(MKLaunchOptionsMapTypeKey == "MKLaunchOptionsMapTypeKey")
    precondition(MKLaunchOptionsShowsTrafficKey == "MKLaunchOptionsShowsTrafficKey")
    precondition(MKMapItemTypeIdentifier == "MKMapItemTypeIdentifier")
    precondition(MKMapViewDefaultAnnotationViewReuseIdentifier == "MKMapViewDefaultAnnotationViewReuseIdentifier")
    precondition(MKMapViewDefaultClusterAnnotationViewReuseIdentifier == "MKMapViewDefaultClusterAnnotationViewReuseIdentifier")
    precondition(MKMapCameraZoomDefault.isInfinite)
    let _: MKZoomScale = 1
    precondition(Notification.Name.MKAnnotationCalloutInfoDidChange.rawValue == "MKAnnotationCalloutInfoDidChangeNotification")
}
