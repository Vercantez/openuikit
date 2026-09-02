import MapKit
import CoreGraphics
import CoreLocation
import Foundation
import UIKit

/// Clean EC2 integration probe. The isolated host gate does not compile this
/// file. It must import the real dependency modules and pass their values
/// through MapKit APIs, including UIKit ancestry for MapKit views.
@inline(never)
public func mapKitDependencyIdentityProbe() {
    let coordinate = CLLocationCoordinate2D(latitude: 37.3349, longitude: -122.0090)
    let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    let region = MKCoordinateRegion(center: coordinate, span: span)
    let point = MKMapPoint(coordinate)
    _ = point.coordinate
    let rect = MKMapRect(
        x: point.x - 1000,
        y: point.y - 1000,
        width: 2000,
        height: 2000
    )
    let cgRect = CGRect(x: 0, y: 0, width: 320, height: 240)
    let renderer = MKOverlayRenderer(overlay: MKTileOverlay(urlTemplate: nil))
    let mappedRect = renderer.mapRect(for: cgRect)
    let back = renderer.rect(for: mappedRect)
    _ = (region, rect, back)

    let mapView = MKMapView(frame: cgRect)
    let asView: UIView = mapView
    precondition(mapView === asView)
    mapView.setRegion(region, animated: false)
    mapView.visibleMapRect = rect

    let lookAround = MKLookAroundViewController()
    let asController: UIViewController = lookAround
    precondition(lookAround === asController)

    let annotationView = MKAnnotationView(annotation: nil, reuseIdentifier: "id")
    let pin = MKPinAnnotationView(annotation: nil, reuseIdentifier: "pin")
    _ = pin as MKAnnotationView
    _ = annotationView as UIView
    _ = MKUserLocationView(annotation: nil, reuseIdentifier: "user") as UIView
    _ = MKCompassButton(mapView: mapView) as UIView
    _ = MKScaleView(frame: .zero) as UIView
    _ = MKUserTrackingButton(frame: .zero) as UIView
    _ = MKMapItemDetailViewController(mapItem: nil) as UIViewController

    let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
    _ = MKReverseGeocodingRequest(location: location)
    _ = MKMapItem(location: location, address: MKAddress(fullAddress: "1 Infinite Loop", shortAddress: "Cupertino"))
}
