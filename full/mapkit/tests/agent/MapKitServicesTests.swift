import Foundation
import MapKit

final class CompleterProbe: NSObject, MKLocalSearchCompleterDelegate {
    var failed = false
    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: any Error) {
        failed = (error as? MKError)?.code == .serverFailure
        _ = completer
    }
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        _ = completer
    }
}

func testLocalSearchFailClosed() {
    let request = MKLocalSearch.Request()
    request.naturalLanguageQuery = "coffee"
    request.region = MKCoordinateRegion()
    request.regionPriority = .required
    request.resultTypes = [.address]
    request.pointOfInterestFilter = .includingAll
    request.addressFilter = .includingAll
    _ = MKLocalSearch.Request(naturalLanguageQuery: "park")
    _ = MKLocalSearch.Request(
        naturalLanguageQuery: "park",
        region: MKCoordinateRegion()
    )
    let completion = MKLocalSearchCompletion()
    completion.title = "Cafe"
    completion.subtitle = "Main"
    completion.titleHighlightRanges = []
    completion.subtitleHighlightRanges = []
    _ = MKLocalSearch.Request(completion: completion)
    let search = MKLocalSearch(request: request)
    precondition(!search.isSearching)
    search.start { response, error in
        precondition(response == nil)
        precondition((error as? MKError)?.code == .serverFailure)
    }
    search.cancel()
    let poi = MKLocalPointsOfInterestRequest(
        center: CLLocationCoordinate2D(latitude: 0, longitude: 0),
        radius: 5000
    )
    precondition(poi.radius == MKLocalPointsOfInterestRequest.maxRadius)
    precondition(MKLocalPointsOfInterestRequest.maxRadius == 2000)
    _ = MKLocalPointsOfInterestRequest(
        centerCoordinate: CLLocationCoordinate2D(latitude: 1, longitude: 1),
        radius: 10
    )
    _ = MKLocalPointsOfInterestRequest(coordinateRegion: MKCoordinateRegion())
    poi.pointOfInterestFilter = .includingAll
    _ = poi.coordinate
    _ = poi.region
    let poiSearch = MKLocalSearch(pointsOfInterestRequest: poi)
    poiSearch.start { _, error in
        precondition((error as? MKError)?.code == .serverFailure)
    }
    _ = MKLocalSearch(request: poi)
}

func testCompleterStateMachine() {
    let completer = MKLocalSearchCompleter()
    let probe = CompleterProbe()
    completer.delegate = probe
    completer.region = MKCoordinateRegion()
    completer.regionPriority = .default
    completer.resultTypes = [.query]
    completer.filterType = .locationsOnly
    completer.pointOfInterestFilter = .excludingAll
    completer.addressFilter = .excludingAll
    completer.queryFragment = "ab"
    precondition(probe.failed)
    precondition(!completer.isSearching)
    precondition(completer.results.isEmpty)
    completer.cancel()
    completer.queryFragment = ""
}

func testDirectionsFailClosed() {
    let request = MKDirections.Request()
    request.source = MKMapItem.forCurrentLocation()
    request.destination = MKMapItem(placemark: MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: 1, longitude: 1)))
    request.transportType = .walking
    request.requestsAlternateRoutes = true
    request.departureDate = Date()
    request.arrivalDate = Date()
    request.highwayPreference = .avoid
    request.tollPreference = .any
    _ = MKDirections.Request.isDirectionsRequest(URL(string: "https://maps.apple.com")!)
    _ = MKDirections.Request(contentsOfURL: URL(string: "https://example.com")!)
    let directions = MKDirections(request: request)
    precondition(!directions.isCalculating)
    directions.calculate { response, error in
        precondition(response == nil)
        precondition((error as? MKError)?.code == .directionsNotFound)
    }
    directions.calculateETA { response, error in
        precondition(response == nil)
        precondition((error as? MKError)?.code == .directionsNotFound)
    }
    directions.cancel()
    _ = MKDirections.Response()
    _ = MKDirections.ETAResponse()
    let route = MKRoute()
    _ = route.name
    _ = route.advisoryNotices
    _ = route.distance
    _ = route.expectedTravelTime
    _ = route.transportType
    _ = route.polyline
    _ = route.steps
    _ = route.hasHighways
    _ = route.hasTolls
    let step = MKRoute.Step()
    _ = step.instructions
    _ = step.notice
    _ = step.distance
    _ = step.transportType
    _ = step.polyline
}

func testSnapshotterAndLookAroundFailClosed() {
    let options = MKMapSnapshotter.Options()
    options.camera = MKMapCamera()
    options.mapRect = .world
    options.region = MKCoordinateRegion()
    options.mapType = .standard
    options.size = CGSize(width: 64, height: 64)
    options.scale = 2
    options.showsBuildings = false
    options.showsPointsOfInterest = false
    options.pointOfInterestFilter = .includingAll
    options.preferredConfiguration = MKStandardMapConfiguration()
    options.traitCollection = UITraitCollection()
    let snap = MKMapSnapshotter(options: options)
    precondition(!snap.isLoading)
    snap.start { snapshot, error in
        precondition(snapshot == nil)
        precondition((error as? MKError)?.code == .serverFailure)
    }
    snap.cancel()
    let snapshot = MKMapSnapshotter.Snapshot()
    _ = snapshot.image
    _ = snapshot.traitCollection
    _ = snapshot.point(for: CLLocationCoordinate2D(latitude: 0, longitude: 0))
    let scene = MKLookAroundScene()
    _ = scene.copy()
    let sceneReq = MKLookAroundSceneRequest(coordinate: CLLocationCoordinate2D(latitude: 0, longitude: 0))
    _ = sceneReq.coordinate
    _ = sceneReq.isCancelled
    _ = sceneReq.isLoading
    sceneReq.getSceneWithCompletionHandler { scene, error in
        precondition(scene == nil)
        precondition((error as? MKError)?.code == .serverFailure)
    }
    sceneReq.cancel()
    _ = MKLookAroundSceneRequest(mapItem: MKMapItem.forCurrentLocation())
    let lookOptions = MKLookAroundSnapshotter.Options()
    lookOptions.size = CGSize(width: 10, height: 10)
    lookOptions.traitCollection = UITraitCollection()
    lookOptions.pointOfInterestFilter = .includingAll
    let lookSnap = MKLookAroundSnapshotter(scene: scene, options: lookOptions)
    lookSnap.getSnapshotWithCompletionHandler { snapshot, error in
        precondition(snapshot == nil)
        precondition((error as? MKError)?.code == .serverFailure)
    }
    lookSnap.cancel()
    _ = lookSnap.isLoading
    _ = MKLookAroundSnapshotter.Snapshot().image
    let lookVC = MKLookAroundViewController(scene: scene)
    lookVC.badgePosition = .topTrailing
    lookVC.isNavigationEnabled = false
    lookVC.showsRoadLabels = false
    lookVC.pointOfInterestFilter = .excludingAll
    lookVC.scene = scene
    _ = MKLookAroundViewController(nibName: nil, bundle: nil)
    let lookCoder = try! NSKeyedUnarchiver(
        forReadingFrom: try! NSKeyedArchiver.archivedData(withRootObject: "x", requiringSecureCoding: false)
    )
    _ = MKLookAroundViewController(coder: lookCoder)
}

func testGeocodingRequestsFailClosed() {
    let geo = MKGeocodingRequest(addressString: "1 Infinite Loop")
    precondition(geo?.addressString == "1 Infinite Loop")
    geo?.preferredLocale = Locale(identifier: "en_US")
    geo?.region = MKCoordinateRegion()
    geo?.getMapItems { items, error in
        precondition(items == nil)
        precondition((error as? MKError)?.code == .placemarkNotFound)
    }
    geo?.cancel()
    precondition(MKGeocodingRequest(addressString: "") == nil)
    let reverse = MKReverseGeocodingRequest(location: CLLocation(latitude: 0, longitude: 0))
    reverse?.preferredLocale = Locale(identifier: "en_US")
    _ = reverse?.location
    reverse?.getMapItems { items, error in
        precondition(items == nil)
        precondition((error as? MKError)?.code == .placemarkNotFound)
    }
    reverse?.cancel()
    _ = reverse?.isCancelled
    _ = reverse?.isLoading
}

final class MapDelegateProbe: NSObject, MKMapViewDelegate {
    var selected = false
    func mapView(_ mapView: MKMapView, viewFor annotation: any MKAnnotation) -> MKAnnotationView? {
        MKPinAnnotationView(annotation: annotation, reuseIdentifier: "d")
    }
    func mapView(_ mapView: MKMapView, didSelect annotation: any MKAnnotation) {
        selected = true
        _ = (mapView, annotation)
    }
    func mapView(_ mapView: MKMapView, rendererFor overlay: any MKOverlay) -> MKOverlayRenderer {
        MKOverlayRenderer(overlay: overlay)
    }
}

func testMapViewDelegateCallbacks() {
    let map = MKMapView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
    let probe = MapDelegateProbe()
    map.delegate = probe
    let pin = MKPointAnnotation(coordinate: CLLocationCoordinate2D(latitude: 0, longitude: 0))
    map.addAnnotation(pin)
    map.selectAnnotation(pin, animated: false)
    precondition(probe.selected)
    var coords = [CLLocationCoordinate2D(latitude: 0, longitude: 0), CLLocationCoordinate2D(latitude: 1, longitude: 1)]
    map.addOverlay(MKPolyline(coordinates: &coords, count: 2))
    map.setRegion(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 0, longitude: 0),
            span: MKCoordinateSpan(latitudeDelta: 1, longitudeDelta: 1)
        ),
        animated: false
    )
}
