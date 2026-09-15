import Foundation
import MapKit

final class MapViewDefaultSpy: NSObject, MKMapViewDelegate {}

final class LookAroundDefaultSpy: NSObject, MKLookAroundViewControllerDelegate {}

final class MapItemDetailDefaultSpy: NSObject, MKMapItemDetailViewControllerDelegate {}

final class CompleterDefaultSpy: NSObject, MKLocalSearchCompleterDelegate {}

func testMapViewDelegateDefaults() {
    let map = MKMapView(frame: CGRect(x: 0, y: 0, width: 64, height: 64))
    let spy = MapViewDefaultSpy()
    let peer: any MKMapViewDelegate = spy
    _ = peer
    map.delegate = spy
    precondition(map.delegate != nil)
    let pin = MKPointAnnotation(coordinate: CLLocationCoordinate2D(latitude: 1, longitude: 2))
    let members: [any MKAnnotation] = [pin]
    let view = MKPinAnnotationView(annotation: pin, reuseIdentifier: "spy")
    let control = UIControl(frame: CGRect(x: 0, y: 0, width: 8, height: 8))
    spy.mapView(map, annotationView: view, calloutAccessoryControlTapped: control)
    spy.mapView(map, annotationView: view, didChange: .dragging, fromOldState: .starting)
    let cluster = spy.mapView(map, clusterAnnotationForMemberAnnotations: members)
    precondition(cluster.memberAnnotations.count == 1)
    spy.mapView(map, didAdd: [view])
    let circle = MKCircle(center: CLLocationCoordinate2D(latitude: 0, longitude: 0), radius: 10)
    spy.mapView(map, didAdd: [MKCircleRenderer(circle: circle)])
    spy.mapView(map, didAddOverlayViews: [])
    spy.mapView(map, didChange: .follow, animated: false)
    spy.mapView(map, didDeselect: pin)
    spy.mapView(map, didDeselect: view)
    spy.mapView(map, didFailToLocateUserWithError: MKError(.unknown))
    spy.mapView(map, didUpdate: MKUserLocation())
    spy.mapView(map, regionDidChangeAnimated: false)
    spy.mapView(map, regionWillChangeAnimated: true)
    spy.mapViewDidChangeVisibleRegion(map)
    spy.mapViewDidFailLoadingMap(map, withError: MKError(.loadingThrottled))
    spy.mapViewDidFinishLoadingMap(map)
    spy.mapViewDidFinishRenderingMap(map, fullyRendered: true)
    spy.mapViewDidStopLocatingUser(map)
    spy.mapViewWillStartLoadingMap(map)
    spy.mapViewWillStartLocatingUser(map)
    spy.mapViewWillStartRenderingMap(map)
    let accessory = spy.mapView(map, selectionAccessoryFor: pin)
    precondition(accessory == nil)
}

func testLookAroundDelegateDefaults() {
    let lookAround = MKLookAroundViewController(scene: MKLookAroundScene())
    let spy = LookAroundDefaultSpy()
    let peer: any MKLookAroundViewControllerDelegate = spy
    _ = peer
    lookAround.delegate = spy
    precondition(lookAround.delegate != nil)
    spy.lookAroundViewControllerWillUpdateScene(lookAround)
    spy.lookAroundViewControllerDidUpdateScene(lookAround)
    spy.lookAroundViewControllerWillPresentFullScreen(lookAround)
    spy.lookAroundViewControllerDidPresentFullScreen(lookAround)
    spy.lookAroundViewControllerWillDismissFullScreen(lookAround)
    spy.lookAroundViewControllerDidDismissFullScreen(lookAround)
}

func testMapItemDetailDelegateDefaults() {
    let item = MKMapItem(placemark: MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: 3, longitude: 4)))
    let detail = MKMapItemDetailViewController(mapItem: item)
    let spy = MapItemDetailDefaultSpy()
    let peer: any MKMapItemDetailViewControllerDelegate = spy
    _ = peer
    detail.delegate = spy
    precondition(detail.delegate != nil)
    spy.mapItemDetailViewControllerDidFinish(detail)
}

func testCompleterDelegateDefaults() {
    let completer = MKLocalSearchCompleter()
    let spy = CompleterDefaultSpy()
    let peer: any MKLocalSearchCompleterDelegate = spy
    _ = peer
    completer.delegate = spy
    precondition(completer.delegate != nil)
    spy.completerDidUpdateResults(completer)
}
