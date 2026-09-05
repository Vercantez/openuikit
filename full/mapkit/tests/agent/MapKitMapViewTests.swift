import Foundation
import MapKit

func testCoordinateConversions() {
    // Darwin macOS 26.1: MKMapPoint(0°, 0°) == (134217728, 134217728)
    let origin = MKMapPoint(CLLocationCoordinate2D(latitude: 0, longitude: 0))
    precondition(abs(origin.x - 134217728) < 1e-6)
    precondition(abs(origin.y - 134217728) < 1e-6)
    let back = origin.coordinate
    precondition(abs(back.latitude) < 1e-9)
    precondition(abs(back.longitude) < 1e-9)
    let nyc = MKMapPoint(CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060))
    precondition(abs(nyc.x - 79034854.78684445) < 1)
    precondition(abs(nyc.y - 100926577.02763256) < 1)
    let roundtrip = nyc.coordinate
    precondition(abs(roundtrip.latitude - 40.7128) < 1e-6)
    precondition(abs(roundtrip.longitude + 74.0060) < 1e-6)
    let viaFunc = MKMapPointForCoordinate(CLLocationCoordinate2D(latitude: 0, longitude: 0))
    precondition(MKMapPointEqualToPoint(viaFunc, origin))
    let coord = MKCoordinateForMapPoint(origin)
    precondition(abs(coord.latitude) < 1e-9)
}

func testMetersPerMapPointMeasured() {
    // Darwin macOS 26.1 WGS-84 meridional formula.
    precondition(abs(MKMetersPerMapPointAtLatitude(0) - 0.14828977333772544) < 1e-12)
    precondition(abs(MKMetersPerMapPointAtLatitude(60) - 0.07470109070817468) < 1e-12)
    let inverse = MKMapPointsPerMeterAtLatitude(0)
    precondition(abs(inverse * MKMetersPerMapPointAtLatitude(0) - 1) < 1e-9)
}

func testCoordinateRegion() {
    let region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 0, longitude: 0),
        latitudinalMeters: 1000,
        longitudinalMeters: 2000
    )
    precondition(abs(region.span.latitudeDelta - 0.009043695025814083) < 1e-6)
    precondition(abs(region.span.longitudeDelta - 0.017966310975031877) < 1e-6)
    let fromRect = MKCoordinateRegion(MKMapRect.world)
    precondition(abs(fromRect.center.latitude) < 1e-6)
    precondition(abs(fromRect.span.longitudeDelta - 360) < 1e-6)
    precondition(abs(fromRect.span.latitudeDelta - 170.10225755961318) < 1e-4)
    let span = MKCoordinateSpan(latitudeDelta: 1, longitudeDelta: 2)
    let made = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 10, longitude: 20),
        span: span
    )
    precondition(made.center.latitude == 10)
    precondition(made.span.longitudeDelta == 2)
    _ = MKCoordinateRegion()
    var hasher = Hasher()
    made.hash(into: &hasher)
    _ = hasher.finalize()
}

func testMapRectDivide() {
    let rect = MKMapRect(x: 10, y: 20, width: 30, height: 40)
    var slice = MKMapRect()
    var remainder = MKMapRect()
    MKMapRectDivide(rect, &slice, &remainder, 10, .minXEdge)
    precondition(slice.origin.x == 10)
    precondition(slice.size.width == 10)
    precondition(remainder.origin.x == 20)
    precondition(remainder.size.width == 20)
}

func testGeodesicPolyline() {
    var equator = [
        CLLocationCoordinate2D(latitude: 0, longitude: 0),
        CLLocationCoordinate2D(latitude: 0, longitude: 90)
    ]
    let geo = MKGeodesicPolyline(coordinates: &equator, count: 2)
    // Darwin macOS 26.1: 90° of equator → 10020 points.
    precondition(geo.pointCount == 10020)
    var oneDeg = [
        CLLocationCoordinate2D(latitude: 0, longitude: 0),
        CLLocationCoordinate2D(latitude: 0, longitude: 1)
    ]
    let short = MKGeodesicPolyline(coordinates: &oneDeg, count: 2)
    precondition(short.pointCount == 113)
}

func testMapViewStores() {
    let map = MKMapView(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
    precondition(map.mapType == .standard)
    precondition(map.isZoomEnabled)
    precondition(map.isScrollEnabled)
    precondition(map.isRotateEnabled)
    precondition(map.isPitchEnabled)
    precondition(!map.showsUserLocation)
    map.mapType = .hybrid
    map.isZoomEnabled = false
    map.isScrollEnabled = false
    map.showsUserLocation = true
    map.showsTraffic = true
    map.showsCompass = false
    map.showsScale = true
    map.showsBuildings = false
    map.showsPointsOfInterest = false
    map.showsUserTrackingButton = true
    map.pitchButtonVisibility = .visible
    map.selectableMapFeatures = [.pointsOfInterest]
    map.pointOfInterestFilter = .includingAll
    map.preferredConfiguration = MKHybridMapConfiguration()
    precondition(map.mapType == .hybrid)
    precondition(!map.isZoomEnabled)
    precondition(map.showsUserLocation)
    map.setUserTrackingMode(.follow, animated: false)
    precondition(map.userTrackingMode == .follow)
    let camera = MKMapCamera(
        lookingAtCenter: CLLocationCoordinate2D(latitude: 37.8, longitude: -122.4),
        fromDistance: 1000,
        pitch: 30,
        heading: 90
    )
    map.setCamera(camera, animated: false)
    precondition(map.camera.heading == 90)
    precondition(map.camera.pitch == 30)
    _ = map.userLocation
    _ = map.isUserLocationVisible
    _ = map.annotationVisibleRect
    _ = map.visibleMapRect
    map.setVisibleMapRect(MKMapRect.world, animated: false)
    map.setVisibleMapRect(MKMapRect.world, edgePadding: .zero, animated: false)
    let boundary = MKMapView.CameraBoundary(mapRect: MKMapRect.world)
    map.setCameraBoundary(boundary, animated: false)
    precondition(map.cameraBoundary?.mapRect.width == MKMapRect.world.width)
    _ = map.cameraBoundary?.region
    let zoom = MKMapView.CameraZoomRange(minCenterCoordinateDistance: 1000)
    map.setCameraZoomRange(zoom, animated: false)
    precondition(map.cameraZoomRange.minCenterCoordinateDistance == 1000)
    precondition(MKMapView.CameraZoomRange(minCenterCoordinateDistance: 5000, maxCenterCoordinateDistance: 1000) == nil)
    _ = MKMapView.CameraBoundary(coordinateRegion: MKCoordinateRegion())
    _ = MKMapView.CameraZoomRange(maxCenterCoordinateDistance: 2000)
    _ = map.regionThatFits(MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 0, longitude: 0),
        span: MKCoordinateSpan(latitudeDelta: 1, longitudeDelta: 1)
    ))
    _ = map.mapRectThatFits(MKMapRect.world)
    _ = map.mapRectThatFits(MKMapRect.world, edgePadding: UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8))
}

func testMapViewRegionClamp() {
    let map = MKMapView(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
    map.setRegion(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 0, longitude: 0),
            span: MKCoordinateSpan(latitudeDelta: 1, longitudeDelta: 1)
        ),
        animated: true
    )
    precondition(map.region.span.longitudeDelta > 0)
    map.setCenter(CLLocationCoordinate2D(latitude: 10, longitude: 20), animated: false)
    precondition(abs(map.centerCoordinate.latitude - 10) < 1e-6)
    map.region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 200, longitude: 400),
        span: MKCoordinateSpan(latitudeDelta: 1, longitudeDelta: 1)
    )
    precondition(map.region.center.latitude <= 90)
}

func testMapViewAnnotations() {
    let map = MKMapView(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
    map.register(MKMarkerAnnotationView.self, forAnnotationViewWithReuseIdentifier: "mark")
    let pin = MKPointAnnotation(coordinate: CLLocationCoordinate2D(latitude: 1, longitude: 2), title: "A", subtitle: "B")
    precondition(pin.title == "A")
    map.addAnnotation(pin)
    precondition(map.annotations.count == 1)
    let view = map.view(for: pin)
    precondition(view != nil)
    map.selectAnnotation(pin, animated: false)
    precondition(map.selectedAnnotations.count == 1)
    map.deselectAnnotation(pin, animated: false)
    precondition(map.selectedAnnotations.isEmpty)
    let dequeued = map.dequeueReusableAnnotationView(withIdentifier: "mark", for: pin)
    precondition(dequeued is MKMarkerAnnotationView)
    _ = map.dequeueReusableAnnotationView(withIdentifier: "missing")
    let found = map.annotations(in: MKMapRect.world)
    precondition(!found.isEmpty)
    map.showAnnotations([pin], animated: false)
    map.removeAnnotation(pin)
    precondition(map.annotations.isEmpty)
    let extra = MKPointAnnotation(coordinate: CLLocationCoordinate2D(latitude: 3, longitude: 4))
    map.addAnnotations([extra])
    map.removeAnnotations(map.annotations)
    let cluster = MKClusterAnnotation(memberAnnotations: [pin, extra])
    _ = cluster.coordinate
    cluster.title = "c"
    cluster.subtitle = "s"
    let user = MKUserLocation()
    user.title = "me"
    _ = user.coordinate
    _ = user.isUpdating
    _ = user.heading
    _ = user.location
}

func testMapViewOverlays() {
    let map = MKMapView(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
    var coords = [
        CLLocationCoordinate2D(latitude: 0, longitude: 0),
        CLLocationCoordinate2D(latitude: 1, longitude: 1)
    ]
    let line = MKPolyline(coordinates: &coords, count: 2)
    map.addOverlay(line)
    precondition(map.overlays.count == 1)
    let renderer = map.renderer(for: line)
    precondition(renderer is MKPolylineRenderer)
    (renderer as? MKPolylineRenderer)?.createPath()
    precondition((renderer as? MKPolylineRenderer)?.polyline === line)
    map.addOverlay(line, level: .aboveRoads)
    map.addOverlays([line])
    map.addOverlays([line], level: .aboveLabels)
    _ = map.overlays(in: .aboveRoads)
    let circle = MKCircle(center: CLLocationCoordinate2D(latitude: 0, longitude: 0), radius: 100)
    map.insertOverlay(circle, at: 0)
    map.insertOverlay(circle, at: 0, level: .aboveRoads)
    map.insertOverlay(circle, above: line)
    map.insertOverlay(circle, below: line)
    map.exchangeOverlay(line, with: circle)
    map.exchangeOverlay(at: 0, withOverlayAt: 1)
    _ = map.view(for: line)
    map.removeOverlay(line)
    map.removeOverlays(map.overlays)
    let convert = map.convert(CLLocationCoordinate2D(latitude: 0, longitude: 0), toPointTo: map)
    _ = map.convert(convert, toCoordinateFrom: map)
    _ = map.convert(CGRect(x: 0, y: 0, width: 10, height: 10), toRegionFrom: map)
    _ = map.convert(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 0, longitude: 0),
            span: MKCoordinateSpan(latitudeDelta: 1, longitudeDelta: 1)
        ),
        toRectTo: map
    )
}

func testAnnotationViews() {
    let pin = MKPointAnnotation()
    let view = MKAnnotationView(annotation: pin, reuseIdentifier: "r")
    view.canShowCallout = true
    view.isDraggable = true
    view.isEnabled = false
    view.isHighlighted = true
    view.centerOffset = CGPoint(x: 1, y: 2)
    view.calloutOffset = CGPoint(x: 3, y: 4)
    view.accessoryOffset = CGPoint(x: 5, y: 6)
    view.clusteringIdentifier = "c"
    view.displayPriority = .defaultHigh
    view.collisionMode = .circle
    view.zPriority = .max
    view.selectedZPriority = .min
    view.image = UIImage()
    view.leftCalloutAccessoryView = UIView(frame: .zero)
    view.rightCalloutAccessoryView = UIView(frame: .zero)
    view.detailCalloutAccessoryView = UIView(frame: .zero)
    view.setSelected(true, animated: false)
    view.setDragState(.dragging, animated: false)
    view.prepareForDisplay()
    view.prepareForReuse()
    _ = view.cluster
    _ = view.reuseIdentifier
    let annotationCoder = try! NSKeyedUnarchiver(
        forReadingFrom: try! NSKeyedArchiver.archivedData(withRootObject: "x", requiringSecureCoding: false)
    )
    _ = MKAnnotationView(coder: annotationCoder)
    let marker = MKMarkerAnnotationView(annotation: pin, reuseIdentifier: "m")
    marker.markerTintColor = .red
    marker.glyphTintColor = .white
    marker.glyphText = "A"
    marker.glyphImage = UIImage()
    marker.selectedGlyphImage = UIImage()
    marker.titleVisibility = .visible
    marker.subtitleVisibility = .hidden
    marker.animatesWhenAdded = true
    let pinView = MKPinAnnotationView(annotation: pin, reuseIdentifier: "p")
    pinView.pinColor = .green
    pinView.pinTintColor = MKPinAnnotationView.greenPinColor()
    pinView.animatesDrop = true
    _ = MKPinAnnotationView.redPinColor()
    _ = MKPinAnnotationView.purplePinColor()
    _ = MKUserLocationView(annotation: MKUserLocation(), reuseIdentifier: nil)
}

func testMapCamera() {
    let camera = MKMapCamera(
        lookingAtCenter: CLLocationCoordinate2D(latitude: 10, longitude: 20),
        fromDistance: 500,
        pitch: 45,
        heading: 90
    )
    precondition(camera.centerCoordinate.latitude == 10)
    precondition(camera.centerCoordinateDistance == 500)
    precondition(camera.heading == 90)
    precondition(camera.pitch == 45)
    let eye = MKMapCamera(
        lookingAtCenter: CLLocationCoordinate2D(latitude: 0, longitude: 0),
        fromEyeCoordinate: CLLocationCoordinate2D(latitude: 0.01, longitude: 0),
        eyeAltitude: 500
    )
    precondition(eye.altitude == 500)
    precondition(eye.centerCoordinateDistance > 0)
    let item = MKMapItem(placemark: MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: 1, longitude: 2)))
    _ = MKMapCamera(lookingAt: item, forViewSize: CGSize(width: 100, height: 100), allowPitch: true)
    _ = MKMapCamera(lookingAtMapItem: item, forViewSize: CGSize(width: 100, height: 100), allowPitch: false)
    _ = MKMapCamera(lookingAtCenterCoordinate: CLLocationCoordinate2D(latitude: 0, longitude: 0), fromDistance: 1, pitch: 0, heading: 0)
    _ = MKMapCamera(
        lookingAtCenterCoordinate: CLLocationCoordinate2D(latitude: 0, longitude: 0),
        fromEyeCoordinate: CLLocationCoordinate2D(latitude: 0, longitude: 0),
        eyeAltitude: 1
    )
    let copy = camera.copy() as! MKMapCamera
    precondition(copy.heading == 90)
    let cameraCoder = try! NSKeyedUnarchiver(
        forReadingFrom: try! NSKeyedArchiver.archivedData(withRootObject: "x", requiringSecureCoding: false)
    )
    _ = MKMapCamera(coder: cameraCoder)
}

func testMapItemAndPlacemark() {
    let place = MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: 40, longitude: -74))
    precondition(place.coordinate.latitude == 40)
    let dict = MKPlacemark(
        coordinate: CLLocationCoordinate2D(latitude: 1, longitude: 2),
        addressDictionary: ["City": "Town", "CountryCode": "US"]
    )
    precondition(dict.locality == "Town")
    precondition(dict.countryCode == "US")
    let item = MKMapItem(placemark: place)
    item.name = "Spot"
    item.phoneNumber = "1"
    item.url = URL(string: "https://example.com")
    item.timeZone = TimeZone(secondsFromGMT: 0)
    item.pointOfInterestCategory = .cafe
    precondition(item.location.coordinate.latitude == 40)
    precondition(item.openInMaps() == false)
    precondition(MKMapItem.openMaps(with: [item]) == false)
    let current = MKMapItem.forCurrentLocation()
    precondition(current.isCurrentLocation)
    let address = MKAddress(fullAddress: "1 Main St", shortAddress: "Main")
    precondition(address?.fullAddress == "1 Main St")
    _ = MKMapItem(location: CLLocation(latitude: 0, longitude: 0), address: address)
    let ident = MKMapItem.Identifier(rawValue: "abc")
    precondition(ident?.rawValue == "abc")
    _ = MKMapItem.Identifier(identifierString: "abc")
    _ = ident.hashValue
    var identHasher = Hasher()
    ident?.hash(into: &identHasher)
    _ = identHasher.finalize()
    let data = try! JSONEncoder().encode(ident!)
    _ = try! JSONDecoder().decode(MKMapItem.Identifier.self, from: data)
    let reps = MKAddressRepresentations()
    reps.cityName = "City"
    reps.regionName = "Region"
    _ = reps.cityWithContext(.short)
    _ = reps.fullAddress(includingRegion: true, singleLine: true)
    _ = reps.region
    let style = MKSelectionAccessory.MapItemDetailPresentationStyle.callout(.full)
    _ = MKSelectionAccessory.mapItemDetail(style)
    _ = MKSelectionAccessory.MapItemDetailPresentationStyle.openInMaps
    _ = MKSelectionAccessory.MapItemDetailPresentationStyle.callout
    _ = MKSelectionAccessory.MapItemDetailPresentationStyle.automatic(presentationViewController: nil)
    _ = MKSelectionAccessory.MapItemDetailPresentationStyle.sheet(presentedFrom: UIViewController())
    let detail = MKMapItemDetailViewController(mapItem: item, displaysMap: true)
    detail.mapItem = item
    _ = MKMapItemDetailViewController(mapItem: item)
    let feature = MKMapFeatureAnnotation()
    feature.featureType = .pointOfInterest
    _ = MKMapItemRequest(mapFeatureAnnotation: feature)
    let req = MKMapItemRequest(mapItemIdentifier: ident!)
    _ = req.mapItemIdentifier
    _ = req.isCancelled
    _ = req.isLoading
    _ = req.featureAnnotation
    _ = req.mapFeatureAnnotation
    req.cancel()
    req.getMapItem { item, error in
        precondition(item == nil)
        precondition((error as? MKError)?.code == .serverFailure)
    }
    let annot = MKMapItemAnnotation(mapItem: item)
    _ = annot?.coordinate
    _ = annot?.mapItem
    let activity = NSUserActivity(activityType: "test")
    activity.mapItem = item
    _ = activity.mapItem
    let value = NSValue(MKCoordinate: place.coordinate)
    _ = value.mkCoordinateValue
    let spanValue = NSValue(MKCoordinateSpan: MKCoordinateSpan(latitudeDelta: 1, longitudeDelta: 1))
    _ = spanValue.mkCoordinateSpanValue
    _ = MKIconStyle()
}
