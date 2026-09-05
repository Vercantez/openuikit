import Foundation
#if canImport(CoreGraphics)
import CoreGraphics
#endif
#if canImport(CoreLocation)
import CoreLocation
#endif
#if canImport(UIKit)
import UIKit
#endif

open class MKMapView: UIView {
    public final class CameraBoundary: NSObject, NSCopying {
        public private(set) var mapRect: MKMapRect
        public var region: MKCoordinateRegion { MKCoordinateRegion(mapRect) }

        public init?(coordinateRegion region: MKCoordinateRegion) {
            mapRect = MKMapRectForCoordinateRegion(region)
            super.init()
        }

        public init?(mapRect: MKMapRect) {
            self.mapRect = mapRect
            super.init()
        }

        public init?(coder: NSCoder) {
            _ = coder
            return nil
        }

        public func copy(with zone: NSZone? = nil) -> Any {
            _ = zone
            return CameraBoundary(mapRect: mapRect) ?? CameraBoundary(mapRect: .world)!
        }
    }

    public final class CameraZoomRange: NSObject, NSCopying {
        public private(set) var minCenterCoordinateDistance: CLLocationDistance
        public private(set) var maxCenterCoordinateDistance: CLLocationDistance

        public init?(
            minCenterCoordinateDistance minDistance: CLLocationDistance,
            maxCenterCoordinateDistance maxDistance: CLLocationDistance
        ) {
            // Darwin macOS 26.1: inverted finite ranges return nil.
            // MKMapCameraZoomDefault (-1) means unconstrained.
            if minDistance >= 0 && maxDistance >= 0 && minDistance > maxDistance {
                return nil
            }
            minCenterCoordinateDistance = minDistance
            maxCenterCoordinateDistance = maxDistance
            super.init()
        }

        public convenience init?(minCenterCoordinateDistance minDistance: CLLocationDistance) {
            self.init(
                minCenterCoordinateDistance: minDistance,
                maxCenterCoordinateDistance: MKMapCameraZoomDefault
            )
        }

        public convenience init?(maxCenterCoordinateDistance maxDistance: CLLocationDistance) {
            self.init(
                minCenterCoordinateDistance: MKMapCameraZoomDefault,
                maxCenterCoordinateDistance: maxDistance
            )
        }

        public init?(coder: NSCoder) {
            _ = coder
            return nil
        }

        public func copy(with zone: NSZone? = nil) -> Any {
            _ = zone
            return CameraZoomRange(
                minCenterCoordinateDistance: minCenterCoordinateDistance,
                maxCenterCoordinateDistance: maxCenterCoordinateDistance
            ) ?? CameraZoomRange(
                minCenterCoordinateDistance: MKMapCameraZoomDefault,
                maxCenterCoordinateDistance: MKMapCameraZoomDefault
            )!
        }
    }

    // Darwin macOS 26.1 default region: center (34.597234, -100.562017)
    // span (60.06066117824804, 50.0) — US-centric empty map.
    private var storedRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 34.597234, longitude: -100.562017),
        span: MKCoordinateSpan(latitudeDelta: 60.06066117824804, longitudeDelta: 50)
    )
    private var storedAnnotations: [any MKAnnotation] = []
    private var storedOverlays: [(any MKOverlay, MKOverlayLevel)] = []
    private var reuseClasses: [String: MKAnnotationView.Type] = [:]
    private var reusePool: [String: [MKAnnotationView]] = [:]
    private var annotationViews: [ObjectIdentifier: MKAnnotationView] = [:]
    private var overlayRenderers: [ObjectIdentifier: MKOverlayRenderer] = [:]
    private var selected: [any MKAnnotation] = []

    open weak var delegate: (any MKMapViewDelegate)?
    open var mapType: MKMapType = .standard
    open var isZoomEnabled: Bool = true
    open var isScrollEnabled: Bool = true
    open var isRotateEnabled: Bool = true
    open var isPitchEnabled: Bool = true
    open var showsBuildings: Bool = true
    open var showsCompass: Bool = true
    open var showsScale: Bool = false
    open var showsTraffic: Bool = false
    open var showsPointsOfInterest: Bool = true
    open var showsUserLocation: Bool = false
    open var showsUserTrackingButton: Bool = false
    open var pitchButtonVisibility: MKFeatureVisibility = .adaptive
    open var selectableMapFeatures: MKMapFeatureOptions = []
    open var pointOfInterestFilter: MKPointOfInterestFilter?
    open var preferredConfiguration: MKMapConfiguration = MKStandardMapConfiguration()
    open var userTrackingMode: MKUserTrackingMode = .none
    open var cameraBoundary: CameraBoundary?
    open var cameraZoomRange: CameraZoomRange! = CameraZoomRange(
        minCenterCoordinateDistance: MKMapCameraZoomDefault,
        maxCenterCoordinateDistance: MKMapCameraZoomDefault
    )
    open var camera: MKMapCamera = MKMapCamera()
    public let userLocation = MKUserLocation()

    public override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .lightGray
        camera.centerCoordinate = storedRegion.center
        camera.centerCoordinateDistance = 12_779_558.184111629
        camera.altitude = 12_779_558.184111629
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    open var region: MKCoordinateRegion {
        get { storedRegion }
        set { setRegion(newValue, animated: false) }
    }

    open var centerCoordinate: CLLocationCoordinate2D {
        get { storedRegion.center }
        set { setCenter(newValue, animated: false) }
    }

    open var visibleMapRect: MKMapRect {
        get { MKMapRectForCoordinateRegion(storedRegion) }
        set { setVisibleMapRect(newValue, animated: false) }
    }

    open var annotations: [any MKAnnotation] { storedAnnotations }

    open var overlays: [any MKOverlay] { storedOverlays.map { $0.0 } }

    open var selectedAnnotations: [any MKAnnotation] {
        get { selected }
        set {
            for annotation in selected {
                deselectAnnotation(annotation, animated: false)
            }
            for annotation in newValue {
                selectAnnotation(annotation, animated: false)
            }
        }
    }

    open var isUserLocationVisible: Bool {
        showsUserLocation && userLocation.location != nil
            && visibleMapRect.contains(MKMapPoint(userLocation.coordinate))
    }

    open var annotationVisibleRect: CGRect { bounds }

    open func setRegion(_ region: MKCoordinateRegion, animated: Bool) {
        // `animated` is a no-op: Linux has no MapKit animation clock.
        _ = animated
        let fitted = regionThatFits(mk_clampedRegion(region))
        storedRegion = fitted
        camera.centerCoordinate = fitted.center
        delegate?.mapView(self, regionWillChangeAnimated: animated)
        delegate?.mapViewDidChangeVisibleRegion(self)
        delegate?.mapView(self, regionDidChangeAnimated: animated)
    }

    open func setCenter(_ coordinate: CLLocationCoordinate2D, animated: Bool) {
        var next = storedRegion
        next.center = coordinate
        setRegion(next, animated: animated)
    }

    open func setVisibleMapRect(_ mapRect: MKMapRect, animated animate: Bool) {
        setRegion(MKCoordinateRegion(mapRect), animated: animate)
    }

    open func setVisibleMapRect(_ mapRect: MKMapRect, edgePadding insets: UIEdgeInsets, animated animate: Bool) {
        _ = insets
        setVisibleMapRect(mapRect, animated: animate)
    }

    open func setCamera(_ camera: MKMapCamera, animated: Bool) {
        _ = animated
        self.camera = camera
        storedRegion.center = camera.centerCoordinate
    }

    open func setCameraBoundary(_ cameraBoundary: CameraBoundary?, animated: Bool) {
        _ = animated
        self.cameraBoundary = cameraBoundary
    }

    open func setCameraZoomRange(_ cameraZoomRange: CameraZoomRange?, animated: Bool) {
        _ = animated
        self.cameraZoomRange = cameraZoomRange
    }

    open func setUserTrackingMode(_ mode: MKUserTrackingMode, animated: Bool) {
        userTrackingMode = mode
        delegate?.mapView(self, didChange: mode, animated: animated)
    }

    open func regionThatFits(_ region: MKCoordinateRegion) -> MKCoordinateRegion {
        var fitted = mk_clampedRegion(region)
        let width = max(bounds.width, 1)
        let height = max(bounds.height, 1)
        let aspect = height / width
        if fitted.span.longitudeDelta > 0 {
            let latFromLon = fitted.span.longitudeDelta * Double(aspect)
            if latFromLon > fitted.span.latitudeDelta {
                fitted.span.latitudeDelta = latFromLon
            }
        }
        return fitted
    }

    open func mapRectThatFits(_ mapRect: MKMapRect) -> MKMapRect {
        MKMapRectForCoordinateRegion(regionThatFits(MKCoordinateRegion(mapRect)))
    }

    open func mapRectThatFits(_ mapRect: MKMapRect, edgePadding insets: UIEdgeInsets) -> MKMapRect {
        _ = insets
        return mapRectThatFits(mapRect)
    }

    open func convert(_ coordinate: CLLocationCoordinate2D, toPointTo view: UIView?) -> CGPoint {
        let mapPoint = MKMapPoint(coordinate)
        let visible = visibleMapRect
        let size = bounds.size
        let x = size.width * CGFloat((mapPoint.x - visible.origin.x) / max(visible.size.width, 1))
        let y = size.height * CGFloat((mapPoint.y - visible.origin.y) / max(visible.size.height, 1))
        let point = CGPoint(x: x, y: y)
        _ = view
        return point
    }

    open func convert(_ point: CGPoint, toCoordinateFrom view: UIView?) -> CLLocationCoordinate2D {
        _ = view
        let visible = visibleMapRect
        let size = bounds.size
        let x = visible.origin.x + visible.size.width * Double(point.x / max(size.width, 1))
        let y = visible.origin.y + visible.size.height * Double(point.y / max(size.height, 1))
        return MKCoordinateForMapPoint(MKMapPoint(x: x, y: y))
    }

    open func convert(_ rect: CGRect, toRegionFrom view: UIView?) -> MKCoordinateRegion {
        let nw = convert(rect.origin, toCoordinateFrom: view)
        let se = convert(
            CGPoint(x: rect.origin.x + rect.size.width, y: rect.origin.y + rect.size.height),
            toCoordinateFrom: view
        )
        return MKCoordinateRegion(
            center: CLLocationCoordinate2D(
                latitude: (nw.latitude + se.latitude) / 2,
                longitude: (nw.longitude + se.longitude) / 2
            ),
            span: MKCoordinateSpan(
                latitudeDelta: abs(nw.latitude - se.latitude),
                longitudeDelta: abs(se.longitude - nw.longitude)
            )
        )
    }

    open func convert(_ region: MKCoordinateRegion, toRectTo view: UIView?) -> CGRect {
        let nw = convert(
            CLLocationCoordinate2D(
                latitude: region.center.latitude + region.span.latitudeDelta / 2,
                longitude: region.center.longitude - region.span.longitudeDelta / 2
            ),
            toPointTo: view
        )
        let se = convert(
            CLLocationCoordinate2D(
                latitude: region.center.latitude - region.span.latitudeDelta / 2,
                longitude: region.center.longitude + region.span.longitudeDelta / 2
            ),
            toPointTo: view
        )
        return CGRect(
            x: min(nw.x, se.x),
            y: min(nw.y, se.y),
            width: abs(se.x - nw.x),
            height: abs(se.y - nw.y)
        )
    }

    open func addAnnotation(_ annotation: any MKAnnotation) {
        addAnnotations([annotation])
    }

    open func addAnnotations(_ annotations: [any MKAnnotation]) {
        storedAnnotations.append(contentsOf: annotations)
        var views: [MKAnnotationView] = []
        for annotation in annotations {
            let view = view(for: annotation) ?? mk_makeView(for: annotation)
            annotationViews[ObjectIdentifier(annotation)] = view
            views.append(view)
        }
        if !views.isEmpty {
            delegate?.mapView(self, didAdd: views)
        }
    }

    open func removeAnnotation(_ annotation: any MKAnnotation) {
        removeAnnotations([annotation])
    }

    open func removeAnnotations(_ annotations: [any MKAnnotation]) {
        let ids = Set(annotations.map { ObjectIdentifier($0) })
        storedAnnotations.removeAll { ids.contains(ObjectIdentifier($0)) }
        selected.removeAll { ids.contains(ObjectIdentifier($0)) }
        for annotation in annotations {
            if let view = annotationViews.removeValue(forKey: ObjectIdentifier(annotation)),
               let reuse = view.reuseIdentifier
            {
                view.prepareForReuse()
                reusePool[reuse, default: []].append(view)
            }
        }
    }

    open func annotations(in mapRect: MKMapRect) -> Set<AnyHashable> {
        var result: Set<AnyHashable> = []
        for annotation in storedAnnotations {
            if mapRect.contains(MKMapPoint(annotation.coordinate)), let object = annotation as? NSObject {
                result.insert(object)
            }
        }
        return result
    }

    open func view(for annotation: any MKAnnotation) -> MKAnnotationView? {
        annotationViews[ObjectIdentifier(annotation)]
    }

    open func register(_ viewClass: AnyClass?, forAnnotationViewWithReuseIdentifier identifier: String) {
        reuseClasses[identifier] = viewClass as? MKAnnotationView.Type
    }

    open func dequeueReusableAnnotationView(withIdentifier identifier: String) -> MKAnnotationView? {
        guard var pool = reusePool[identifier], let view = pool.popLast() else { return nil }
        reusePool[identifier] = pool
        return view
    }

    open func dequeueReusableAnnotationView(
        withIdentifier identifier: String,
        for annotation: any MKAnnotation
    ) -> MKAnnotationView {
        if let reused = dequeueReusableAnnotationView(withIdentifier: identifier) {
            reused.annotation = annotation
            return reused
        }
        let type = reuseClasses[identifier] ?? MKAnnotationView.self
        let view = type.init(annotation: annotation, reuseIdentifier: identifier)
        return view
    }

    open func selectAnnotation(_ annotation: any MKAnnotation, animated: Bool) {
        if selected.contains(where: { ObjectIdentifier($0) == ObjectIdentifier(annotation) }) {
            return
        }
        selected.append(annotation)
        if let view = view(for: annotation) {
            view.setSelected(true, animated: animated)
            delegate?.mapView(self, didSelect: view)
        }
        delegate?.mapView(self, didSelect: annotation)
    }

    open func deselectAnnotation(_ annotation: (any MKAnnotation)?, animated: Bool) {
        guard let annotation else { return }
        selected.removeAll { ObjectIdentifier($0) == ObjectIdentifier(annotation) }
        if let view = view(for: annotation) {
            view.setSelected(false, animated: animated)
            delegate?.mapView(self, didDeselect: view)
        }
        delegate?.mapView(self, didDeselect: annotation)
    }

    open func showAnnotations(_ annotations: [any MKAnnotation], animated: Bool) {
        guard !annotations.isEmpty else { return }
        var rect = MKMapRect.null
        for annotation in annotations {
            let point = MKMapPoint(annotation.coordinate)
            rect = rect.union(MKMapRect(x: point.x - 1000, y: point.y - 1000, width: 2000, height: 2000))
        }
        setVisibleMapRect(rect, animated: animated)
    }

    open func addOverlay(_ overlay: any MKOverlay) {
        addOverlay(overlay, level: .aboveLabels)
    }

    open func addOverlay(_ overlay: any MKOverlay, level: MKOverlayLevel) {
        addOverlays([overlay], level: level)
    }

    open func addOverlays(_ overlays: [any MKOverlay]) {
        addOverlays(overlays, level: .aboveLabels)
    }

    open func addOverlays(_ overlays: [any MKOverlay], level: MKOverlayLevel) {
        var renderers: [MKOverlayRenderer] = []
        for overlay in overlays {
            storedOverlays.append((overlay, level))
            let renderer = mk_makeRenderer(for: overlay)
            overlayRenderers[ObjectIdentifier(overlay)] = renderer
            renderers.append(renderer)
        }
        if !renderers.isEmpty {
            delegate?.mapView(self, didAdd: renderers)
        }
    }

    open func removeOverlay(_ overlay: any MKOverlay) {
        removeOverlays([overlay])
    }

    open func removeOverlays(_ overlays: [any MKOverlay]) {
        let ids = Set(overlays.map { ObjectIdentifier($0) })
        storedOverlays.removeAll { ids.contains(ObjectIdentifier($0.0)) }
        for overlay in overlays {
            overlayRenderers.removeValue(forKey: ObjectIdentifier(overlay))
        }
    }

    open func overlays(in level: MKOverlayLevel) -> [any MKOverlay] {
        storedOverlays.filter { $0.1 == level }.map { $0.0 }
    }

    open func insertOverlay(_ overlay: any MKOverlay, at index: Int) {
        insertOverlay(overlay, at: index, level: .aboveLabels)
    }

    open func insertOverlay(_ overlay: any MKOverlay, at index: Int, level: MKOverlayLevel) {
        let clamped = min(max(index, 0), storedOverlays.count)
        storedOverlays.insert((overlay, level), at: clamped)
        overlayRenderers[ObjectIdentifier(overlay)] = mk_makeRenderer(for: overlay)
    }

    open func insertOverlay(_ overlay: any MKOverlay, above sibling: any MKOverlay) {
        if let index = storedOverlays.firstIndex(where: { ObjectIdentifier($0.0) == ObjectIdentifier(sibling) }) {
            insertOverlay(overlay, at: index + 1, level: storedOverlays[index].1)
        } else {
            addOverlay(overlay)
        }
    }

    open func insertOverlay(_ overlay: any MKOverlay, below sibling: any MKOverlay) {
        if let index = storedOverlays.firstIndex(where: { ObjectIdentifier($0.0) == ObjectIdentifier(sibling) }) {
            insertOverlay(overlay, at: index, level: storedOverlays[index].1)
        } else {
            addOverlay(overlay)
        }
    }

    open func exchangeOverlay(_ overlay1: any MKOverlay, with overlay2: any MKOverlay) {
        guard
            let i = storedOverlays.firstIndex(where: { ObjectIdentifier($0.0) == ObjectIdentifier(overlay1) }),
            let j = storedOverlays.firstIndex(where: { ObjectIdentifier($0.0) == ObjectIdentifier(overlay2) })
        else { return }
        storedOverlays.swapAt(i, j)
    }

    open func exchangeOverlay(at index1: Int, withOverlayAt index2: Int) {
        guard storedOverlays.indices.contains(index1), storedOverlays.indices.contains(index2) else { return }
        storedOverlays.swapAt(index1, index2)
    }

    open func renderer(for overlay: any MKOverlay) -> MKOverlayRenderer? {
        overlayRenderers[ObjectIdentifier(overlay)]
    }

    open func view(for overlay: any MKOverlay) -> MKOverlayView {
        let view = MKOverlayView(frame: bounds)
        view.overlay = overlay
        return view
    }

    open override func draw(_ rect: CGRect) {
        super.draw(rect)
        // Tiles fail closed: blank background. Overlay geometry is drawn in
        // map-point space by the renderers when a CGContext is supplied.
        _ = rect
    }

    private func mk_makeView(for annotation: any MKAnnotation) -> MKAnnotationView {
        if let custom = delegate?.mapView(self, viewFor: annotation) {
            return custom
        }
        if annotation is MKUserLocation {
            return MKUserLocationView(annotation: annotation, reuseIdentifier: nil)
        }
        return dequeueReusableAnnotationView(
            withIdentifier: MKMapViewDefaultAnnotationViewReuseIdentifier,
            for: annotation
        )
    }

    private func mk_makeRenderer(for overlay: any MKOverlay) -> MKOverlayRenderer {
        if let custom = delegate?.mapView(self, rendererFor: overlay) {
            return custom
        }
        if let polyline = overlay as? MKPolyline {
            let renderer = MKPolylineRenderer(polyline: polyline)
            renderer.createPath()
            return renderer
        }
        if let polygon = overlay as? MKPolygon {
            let renderer = MKPolygonRenderer(polygon: polygon)
            renderer.createPath()
            return renderer
        }
        if let circle = overlay as? MKCircle {
            let renderer = MKCircleRenderer(circle: circle)
            renderer.createPath()
            return renderer
        }
        return MKOverlayRenderer(overlay: overlay)
    }
}

public protocol MKMapViewDelegate: AnyObject {
    func mapView(_ mapView: MKMapView, viewFor annotation: any MKAnnotation) -> MKAnnotationView?
    func mapView(_ mapView: MKMapView, didAdd views: [MKAnnotationView])
    func mapView(_ mapView: MKMapView, didSelect annotation: any MKAnnotation)
    func mapView(_ mapView: MKMapView, didDeselect annotation: any MKAnnotation)
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView)
    func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView)
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl)
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, didChange newState: MKAnnotationView.DragState, fromOldState oldState: MKAnnotationView.DragState)
    func mapView(_ mapView: MKMapView, clusterAnnotationForMemberAnnotations memberAnnotations: [any MKAnnotation]) -> MKClusterAnnotation
    func mapView(_ mapView: MKMapView, rendererFor overlay: any MKOverlay) -> MKOverlayRenderer
    func mapView(_ mapView: MKMapView, didAdd renderers: [MKOverlayRenderer])
    func mapView(_ mapView: MKMapView, didAddOverlayViews overlayViews: [Any])
    func mapView(_ mapView: MKMapView, viewFor overlay: any MKOverlay) -> MKOverlayView
    func mapView(_ mapView: MKMapView, didChange mode: MKUserTrackingMode, animated: Bool)
    func mapView(_ mapView: MKMapView, didFailToLocateUserWithError error: any Error)
    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation)
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool)
    func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool)
    func mapViewDidChangeVisibleRegion(_ mapView: MKMapView)
    func mapViewDidFailLoadingMap(_ mapView: MKMapView, withError error: any Error)
    func mapViewDidFinishLoadingMap(_ mapView: MKMapView)
    func mapViewDidFinishRenderingMap(_ mapView: MKMapView, fullyRendered: Bool)
    func mapViewDidStopLocatingUser(_ mapView: MKMapView)
    func mapViewWillStartLoadingMap(_ mapView: MKMapView)
    func mapViewWillStartLocatingUser(_ mapView: MKMapView)
    func mapViewWillStartRenderingMap(_ mapView: MKMapView)
    func mapView(_ mapView: MKMapView, selectionAccessoryFor annotation: any MKAnnotation) -> MKSelectionAccessory?
}

extension MKMapViewDelegate {
    public func mapView(_ mapView: MKMapView, viewFor annotation: any MKAnnotation) -> MKAnnotationView? {
        _ = (mapView, annotation)
        return nil
    }
    public func mapView(_ mapView: MKMapView, didAdd views: [MKAnnotationView]) { _ = (mapView, views) }
    public func mapView(_ mapView: MKMapView, didSelect annotation: any MKAnnotation) { _ = (mapView, annotation) }
    public func mapView(_ mapView: MKMapView, didDeselect annotation: any MKAnnotation) { _ = (mapView, annotation) }
    public func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) { _ = (mapView, view) }
    public func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView) { _ = (mapView, view) }
    public func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        _ = (mapView, view, control)
    }
    public func mapView(
        _ mapView: MKMapView,
        annotationView view: MKAnnotationView,
        didChange newState: MKAnnotationView.DragState,
        fromOldState oldState: MKAnnotationView.DragState
    ) {
        _ = (mapView, view, newState, oldState)
    }
    public func mapView(_ mapView: MKMapView, clusterAnnotationForMemberAnnotations memberAnnotations: [any MKAnnotation]) -> MKClusterAnnotation {
        _ = mapView
        return MKClusterAnnotation(memberAnnotations: memberAnnotations)
    }
    public func mapView(_ mapView: MKMapView, rendererFor overlay: any MKOverlay) -> MKOverlayRenderer {
        _ = mapView
        return MKOverlayRenderer(overlay: overlay)
    }
    public func mapView(_ mapView: MKMapView, didAdd renderers: [MKOverlayRenderer]) { _ = (mapView, renderers) }
    public func mapView(_ mapView: MKMapView, didAddOverlayViews overlayViews: [Any]) { _ = (mapView, overlayViews) }
    public func mapView(_ mapView: MKMapView, viewFor overlay: any MKOverlay) -> MKOverlayView {
        _ = (mapView, overlay)
        return MKOverlayView(frame: .zero)
    }
    public func mapView(_ mapView: MKMapView, didChange mode: MKUserTrackingMode, animated: Bool) {
        _ = (mapView, mode, animated)
    }
    public func mapView(_ mapView: MKMapView, didFailToLocateUserWithError error: any Error) { _ = (mapView, error) }
    public func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) { _ = (mapView, userLocation) }
    public func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) { _ = (mapView, animated) }
    public func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) { _ = (mapView, animated) }
    public func mapViewDidChangeVisibleRegion(_ mapView: MKMapView) { _ = mapView }
    public func mapViewDidFailLoadingMap(_ mapView: MKMapView, withError error: any Error) { _ = (mapView, error) }
    public func mapViewDidFinishLoadingMap(_ mapView: MKMapView) { _ = mapView }
    public func mapViewDidFinishRenderingMap(_ mapView: MKMapView, fullyRendered: Bool) { _ = (mapView, fullyRendered) }
    public func mapViewDidStopLocatingUser(_ mapView: MKMapView) { _ = mapView }
    public func mapViewWillStartLoadingMap(_ mapView: MKMapView) { _ = mapView }
    public func mapViewWillStartLocatingUser(_ mapView: MKMapView) { _ = mapView }
    public func mapViewWillStartRenderingMap(_ mapView: MKMapView) { _ = mapView }
    public func mapView(_ mapView: MKMapView, selectionAccessoryFor annotation: any MKAnnotation) -> MKSelectionAccessory? {
        _ = (mapView, annotation)
        return nil
    }
}
