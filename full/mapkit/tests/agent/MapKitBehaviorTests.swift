import MapKit
import Foundation
import Dispatch

func testAddressAndFilter() {
    let missing = MKAddress(fullAddress: "", shortAddress: nil)
    precondition(missing == nil)
    let address = MKAddress(fullAddress: "1 Infinite Loop, Cupertino", shortAddress: "Cupertino")
    precondition(address?.fullAddress.contains("Infinite") == true)
    precondition(address?.shortAddress == "Cupertino")

    let including = MKAddressFilter(including: [.country, .locality])
    precondition(including.includes(.country))
    precondition(including.includes(.locality))
    precondition(!including.includes(.postalCode))
    precondition(including.excludes(.postalCode))
    let excluding = MKAddressFilter(excluding: [.postalCode])
    precondition(excluding.excludes(.postalCode))
    precondition(excluding.includes(.country))
    _ = MKAddressFilter.includingAll
    _ = MKAddressFilter.excludingAll
    _ = MKAddressFilter(includingOptions: .country)
    _ = MKAddressFilter(excludingOptions: .locality)
}

func testAddressRepresentations() {
    let representations = MKAddressRepresentations(
        fullAddress: "1 Infinite Loop",
        cityName: "Cupertino",
        regionName: "CA"
    )
    precondition(representations.cityName == "Cupertino")
    precondition(representations.regionName == "CA")
    precondition(representations.fullAddress(includingRegion: false, singleLine: true) == "1 Infinite Loop")
    precondition(representations.fullAddress(includingRegion: true, singleLine: true)?.contains("CA") == true)
    precondition(representations.cityWithContext(.short) == "Cupertino")
    precondition(representations.cityWithContext(.full)?.contains("CA") == true)
    precondition(representations.cityWithContext != nil)
}

func testMapItemMetadata() {
    let address = MKAddress(fullAddress: "1 Infinite Loop", shortAddress: "Loop")
    let item = MKMapItem(address: address)
    item.name = "Apple"
    item.phoneNumber = "1-800-555-0100"
    item.url = URL(string: "https://apple.com")
    item.pointOfInterestCategory = .store
    item.identifier = MKMapItem.Identifier(identifierString: "abc")
    item.addressRepresentations = MKAddressRepresentations(
        fullAddress: "1 Infinite Loop",
        cityName: "Cupertino",
        regionName: "CA"
    )
    precondition(item.name == "Apple")
    precondition(item.phoneNumber != nil)
    precondition(item.url?.host == "apple.com")
    precondition(item.identifier?.identifierString == "abc")
    precondition(item.identifier?.rawValue == "abc")
    precondition(item.openInMaps() == false)
    precondition(MKMapItem.openMaps(with: [item]) == false)
    let current = MKMapItem.forCurrentLocation()
    precondition(current.isCurrentLocation)
    let annotation = MKMapItemAnnotation(mapItem: item)
    precondition(annotation.mapItem === item)
}

func testPointOfInterestFilter() {
    let include = MKPointOfInterestFilter(including: [.cafe, .restaurant])
    precondition(include.includes(.cafe))
    precondition(!include.includes(.airport))
    let exclude = MKPointOfInterestFilter(excluding: [.nightlife])
    precondition(exclude.excludes(.nightlife))
    precondition(exclude.includes(.park))
    precondition(MKPointOfInterestFilter.includingAll.includes(.cafe))
    precondition(!MKPointOfInterestFilter.excludingAll.includes(.cafe))
}

func testShapeAndCluster() {
    let point = MKPointAnnotation(mapPoint: MKMapPoint(x: 10, y: 20))
    point.title = "A"
    point.subtitle = "B"
    precondition(point.title == "A")
    precondition(point.subtitle == "B")
    precondition(point.mapPoint.x == 10)
    let cluster = MKClusterAnnotation(memberAnnotations: [point])
    precondition(cluster.memberAnnotations.count == 1)
    cluster.title = "Cluster"
    precondition(cluster.title == "Cluster")
    let user = MKUserLocation()
    precondition(user.isUpdating == false)
    let feature = MKMapFeatureAnnotation(featureType: .territory)
    precondition(feature.featureType == .territory)
}

func testOverlaysFromMapPoints() {
    var points = [
        MKMapPoint(x: 0, y: 0),
        MKMapPoint(x: 10, y: 0),
        MKMapPoint(x: 10, y: 10)
    ]
    let polyline = points.withUnsafeMutableBufferPointer { buffer in
        MKPolyline(points: buffer.baseAddress!, count: buffer.count)
    }
    precondition(polyline.pointCount == 3)
    precondition(!polyline.boundingMapRect.isNull)
    precondition(polyline.intersects(MKMapRect(x: 0, y: 0, width: 5, height: 5)))
    precondition(!polyline.canReplaceMapContent())

    let polygon = points.withUnsafeMutableBufferPointer { buffer in
        MKPolygon(points: buffer.baseAddress!, count: buffer.count)
    }
    precondition(polygon.pointCount == 3)
    let interior = points.withUnsafeMutableBufferPointer { buffer in
        MKPolygon(points: buffer.baseAddress!, count: buffer.count, interiorPolygons: nil)
    }
    precondition(interior.interiorPolygons == nil)

    let circle = MKCircle(mapRect: MKMapRect(x: 0, y: 0, width: 100, height: 100))
    precondition(circle.radius.isFinite)
    precondition(circle.boundingMapRect.width == 100)

    let multiLine = MKMultiPolyline([polyline])
    precondition(multiLine.polylines.count == 1)
    let multiPoly = MKMultiPolygon([polygon])
    precondition(multiPoly.polygons.count == 1)
    _ = MKGeodesicPolyline(points: &points, count: points.count)
}

func testTileOverlayURLTemplate() {
    let overlay = MKTileOverlay(urlTemplate: "https://example.test/{z}/{x}/{y}.png")
    overlay.canReplaceMapContent = true
    overlay.maximumZ = 18
    overlay.minimumZ = 2
    overlay.tileSize = CGSize(width: 256, height: 256)
    let url = overlay.url(forTilePath: MKTileOverlayPath(x: 3, y: 4, z: 5, contentScaleFactor: 1))
    precondition(url.absoluteString == "https://example.test/5/3/4.png")
    precondition(overlay.boundingMapRect.origin.x == 0)
}

func testOverlayRendererConversion() {
    let overlay = MKTileOverlay(urlTemplate: nil)
    let renderer = MKOverlayRenderer(overlay: overlay)
    renderer.alpha = 0.5
    renderer.contentScaleFactor = 2
    precondition(renderer.alpha == 0.5)
    let mapPoint = renderer.mapPoint(for: CGPoint(x: 8, y: 9))
    precondition(mapPoint.x == 8)
    precondition(mapPoint.y == 9)
    let point = renderer.point(for: MKMapPoint(x: 4, y: 5))
    precondition(point.x == 4)
    precondition(point.y == 5)
    let mapRect = renderer.mapRect(for: CGRect(x: 1, y: 2, width: 3, height: 4))
    precondition(mapRect.origin.x == 1)
    let cg = renderer.rect(for: mapRect)
    precondition(cg.width == 3)
    precondition(!renderer.canDraw(.world, zoomScale: 1))
    let circle = MKCircle(mapRect: MKMapRect(x: 0, y: 0, width: 10, height: 10))
    let circleRenderer = MKCircleRenderer(circle: circle)
    precondition(circleRenderer.circle === circle)
    circleRenderer.strokeStart = 0.1
    circleRenderer.strokeEnd = 0.9
    precondition(circleRenderer.strokeEnd == 0.9)
}

func testMapConfiguration() {
    let standard = MKStandardMapConfiguration(elevationStyle: .realistic, emphasisStyle: .muted)
    precondition(standard.elevationStyle == .realistic)
    precondition(standard.emphasisStyle == .muted)
    standard.showsTraffic = true
    precondition(standard.showsTraffic)
    let hybrid = MKHybridMapConfiguration(elevationStyle: .flat)
    hybrid.showsTraffic = false
    precondition(hybrid.elevationStyle == .flat)
    let imagery = MKImageryMapConfiguration(elevationStyle: .realistic)
    precondition(imagery.elevationStyle == .realistic)
    let camera = MKMapCamera(
        lookingAtCenterMapPoint: MKMapPoint(x: 1, y: 2),
        fromDistance: 500,
        pitch: 15,
        heading: 90
    )
    precondition(camera.heading == 90)
    precondition(camera.pitch == 15)
    precondition(camera.altitude == 500)
}

func testDistanceFormatter() {
    let formatter = MKDistanceFormatter()
    formatter.units = .metric
    formatter.unitStyle = .abbreviated
    let km = formatter.string(fromDistance: 2500)
    precondition(km.contains("km"))
    let meters = formatter.string(fromDistance: 12)
    precondition(meters.contains("m"))
    formatter.units = .imperial
    let miles = formatter.string(fromDistance: 3200)
    precondition(miles.contains("mi") || miles.contains("ft"))
    let parsed = formatter.distance(from: "2 km")
    precondition(parsed == 2000)
    precondition(formatter.string(fromDistance: Double.nan).isEmpty)
}

func testSelectionAccessory() {
    let style = MKSelectionAccessory.MapItemDetailPresentationStyle.callout(.compact)
    let accessory = MKSelectionAccessory.mapItemDetail(style)
    _ = accessory.presentationStyle
    _ = MKSelectionAccessory.MapItemDetailPresentationStyle.callout
    _ = MKSelectionAccessory.MapItemDetailPresentationStyle.openInMaps
    _ = MKSelectionAccessory.MapItemDetailPresentationStyle.automatic(presentationViewController: nil)
}

func testDirectionsRequestState() {
    let request = MKDirections.Request()
    request.transportType = .walking
    request.requestsAlternateRoutes = true
    request.highwayPreference = .avoid
    request.tollPreference = .any
    request.source = MKMapItem()
    request.destination = MKMapItem()
    request.departureDate = Date(timeIntervalSince1970: 0)
    request.arrivalDate = Date(timeIntervalSince1970: 100)
    precondition(request.transportType.contains(.walking))
    precondition(request.requestsAlternateRoutes)
    precondition(request.highwayPreference == .avoid)
    precondition(MKDirections.Request.isDirectionsRequest(URL(string: "https://example.test")!) == false)
}

func testLocalSearchRequestState() {
    let request = MKLocalSearch.Request(naturalLanguageQuery: "coffee")
    request.resultTypes = [.pointOfInterest]
    request.regionPriority = .required
    request.addressFilter = MKAddressFilter(including: .locality)
    request.pointOfInterestFilter = MKPointOfInterestFilter(including: [.cafe])
    precondition(request.naturalLanguageQuery == "coffee")
    precondition(request.resultTypes.contains(.pointOfInterest))
    let completion = MKLocalSearchCompletion(title: "Cafe", subtitle: "Main St")
    let fromCompletion = MKLocalSearch.Request(completion: completion)
    precondition(fromCompletion.naturalLanguageQuery == "Cafe")
    precondition(completion.title == "Cafe")
    precondition(completion.subtitle == "Main St")
    let poi = MKLocalPointsOfInterestRequest(centerMapPoint: MKMapPoint(x: 0, y: 0), radius: 50_000)
    precondition(poi.radius == MKLocalPointsOfInterestRequest.maxRadius)
}

func testDirectionsFailClosedNonInlineExactlyOnce() {
    let directions = MKDirections(request: MKDirections.Request())
    let semaphore = DispatchSemaphore(value: 0)
    var calls = 0
    var inline = false
    directions.calculate { response, error in
        calls += 1
        inline = true
        precondition(response == nil)
        let mkError = error as? MKError
        precondition(mkError?.code == .directionsNotFound)
        semaphore.signal()
    }
    precondition(calls == 0)
    precondition(!inline)
    precondition(directions.isCalculating)
    let wait = semaphore.wait(timeout: .now() + 5)
    precondition(wait == .success)
    precondition(calls == 1)
    directions.cancel()
    precondition(calls == 1)
}

func testETAFailClosedCancellationSafe() {
    let directions = MKDirections(request: MKDirections.Request())
    let semaphore = DispatchSemaphore(value: 0)
    var calls = 0
    directions.calculateETA { response, error in
        calls += 1
        precondition(response == nil)
        precondition(error != nil)
        semaphore.signal()
    }
    precondition(calls == 0)
    directions.cancel()
    let wait = semaphore.wait(timeout: .now() + 5)
    precondition(wait == .success)
    precondition(calls == 1)
}

func testLocalSearchFailClosed() {
    let search = MKLocalSearch(request: MKLocalSearch.Request(naturalLanguageQuery: "park"))
    let semaphore = DispatchSemaphore(value: 0)
    var calls = 0
    search.start { response, error in
        calls += 1
        precondition(response == nil)
        let mkError = error as? MKError
        precondition(mkError?.code == .placemarkNotFound)
        semaphore.signal()
    }
    precondition(calls == 0)
    precondition(search.isSearching)
    let wait = semaphore.wait(timeout: .now() + 5)
    precondition(wait == .success)
    precondition(calls == 1)
}

func testSnapshotterAndLookAroundFailClosed() {
    let options = MKMapSnapshotter.Options()
    options.size = CGSize(width: 100, height: 80)
    options.mapType = .hybrid
    let snapshotter = MKMapSnapshotter(options: options)
    let snapSem = DispatchSemaphore(value: 0)
    var snapCalls = 0
    snapshotter.start { snapshot, error in
        snapCalls += 1
        precondition(snapshot == nil)
        precondition(error != nil)
        snapSem.signal()
    }
    precondition(snapCalls == 0)
    precondition(snapshotter.isLoading)
    precondition(snapSem.wait(timeout: .now() + 5) == .success)
    precondition(snapCalls == 1)

    let look = MKLookAroundSceneRequest()
    let lookSem = DispatchSemaphore(value: 0)
    var lookCalls = 0
    look.getSceneWithCompletionHandler { scene, error in
        lookCalls += 1
        precondition(scene == nil)
        precondition(error != nil)
        lookSem.signal()
    }
    precondition(lookCalls == 0)
    precondition(lookSem.wait(timeout: .now() + 5) == .success)
    precondition(lookCalls == 1)
}

func testGeocodingAndMapItemRequestFailClosed() {
    let geocode = MKGeocodingRequest(addressString: "Cupertino")
    precondition(geocode != nil)
    let geoSem = DispatchSemaphore(value: 0)
    var geoCalls = 0
    geocode?.getMapItems { items, error in
        geoCalls += 1
        precondition(items == nil)
        precondition(error != nil)
        geoSem.signal()
    }
    precondition(geoCalls == 0)
    precondition(geoSem.wait(timeout: .now() + 5) == .success)
    precondition(geoCalls == 1)

    guard let identifier = MKMapItem.Identifier(rawValue: "id") else {
        preconditionFailure("identifier rawValue must succeed for a nonempty string")
    }
    let request = MKMapItemRequest(mapItemIdentifier: identifier)
    let itemSem = DispatchSemaphore(value: 0)
    var itemCalls = 0
    request.getMapItem { item, error in
        itemCalls += 1
        precondition(item == nil)
        precondition(error != nil)
        itemSem.signal()
    }
    precondition(itemCalls == 0)
    precondition(itemSem.wait(timeout: .now() + 5) == .success)
    precondition(itemCalls == 1)
}

func testGeoJSONDecoderFailClosed() {
    do {
        _ = try MKGeoJSONDecoder().decode(Data())
        preconditionFailure("decoder must fail closed")
    } catch let error as MKError {
        precondition(error.code == .decodingFailed)
    } catch {
        preconditionFailure("unexpected error type")
    }
    let feature = MKGeoJSONFeature()
    feature.identifier = "f"
    precondition(feature.identifier == "f")
}

func testTileLoadFailClosed() {
    let overlay = MKTileOverlay(urlTemplate: "https://example.test/{z}/{x}/{y}.png")
    let semaphore = DispatchSemaphore(value: 0)
    var calls = 0
    overlay.loadTile(at: MKTileOverlayPath(x: 1, y: 1, z: 1, contentScaleFactor: 1)) { data, error in
        calls += 1
        precondition(data == nil)
        precondition(error != nil)
        semaphore.signal()
    }
    precondition(calls == 0)
    precondition(semaphore.wait(timeout: .now() + 5) == .success)
    precondition(calls == 1)
}

func testCompleterFailClosed() {
    final class CompleterSink: NSObject, MKLocalSearchCompleterDelegate {
        var failures = 0
        func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
            _ = completer
        }
        func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: any Error) {
            _ = (completer, error)
            failures += 1
        }
    }
    let sink = CompleterSink()
    let completer = MKLocalSearchCompleter()
    completer.delegate = sink
    completer.filterType = .locationsOnly
    completer.resultTypes = [.address]
    completer.regionPriority = .required
    let semaphore = DispatchSemaphore(value: 0)
    DispatchQueue.global().asyncAfter(deadline: .now() + 0.05) {
        semaphore.signal()
    }
    completer.queryFragment = "coffee"
    precondition(semaphore.wait(timeout: .now() + 5) == .success)
    precondition(completer.results.isEmpty)
}

func testLocalSearchPointsOfInterestInitializer() {
    let request = MKLocalPointsOfInterestRequest()
    let search = MKLocalSearch(pointsOfInterestRequest: request)
    _ = MKLocalSearch(request: request)
    search.cancel()
    precondition(!search.isSearching)
}
