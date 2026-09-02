import Foundation

open class MKOverlayRenderer: NSObject {
    open var alpha: CGFloat = 1
    open var contentScaleFactor: CGFloat = 1
    public let overlay: any MKOverlay

    public init(overlay: any MKOverlay) {
        self.overlay = overlay
        super.init()
    }

    open func canDraw(_ mapRect: MKMapRect, zoomScale: MKZoomScale) -> Bool {
        _ = (mapRect, zoomScale)
        return false
    }

    open func setNeedsDisplay() {}

    open func setNeedsDisplay(_ mapRect: MKMapRect) {
        _ = mapRect
    }

    open func setNeedsDisplay(_ mapRect: MKMapRect, zoomScale: MKZoomScale) {
        _ = (mapRect, zoomScale)
    }

    open func mapPoint(for point: CGPoint) -> MKMapPoint {
        MKMapPoint(x: Double(point.x), y: Double(point.y))
    }

    open func point(for mapPoint: MKMapPoint) -> CGPoint {
        CGPoint(x: mapPoint.x, y: mapPoint.y)
    }

    open func mapRect(for rect: CGRect) -> MKMapRect {
        MKMapRect(
            x: Double(rect.origin.x),
            y: Double(rect.origin.y),
            width: Double(rect.size.width),
            height: Double(rect.size.height)
        )
    }

    open func rect(for mapRect: MKMapRect) -> CGRect {
        CGRect(
            x: mapRect.origin.x,
            y: mapRect.origin.y,
            width: mapRect.size.width,
            height: mapRect.size.height
        )
    }
}

open class MKOverlayPathRenderer: MKOverlayRenderer {
    open var lineWidth: CGFloat = 0
    open var miterLimit: CGFloat = 10
    open var lineDashPhase: CGFloat = 0
    open var strokeStart: CGFloat = 0
    open var strokeEnd: CGFloat = 1
    open var shouldRasterize = false
}

open class MKPolylineRenderer: MKOverlayPathRenderer {
    public var polyline: MKPolyline { overlay as! MKPolyline }

    public init(polyline: MKPolyline) {
        super.init(overlay: polyline)
    }

    public init(multiPolyline: MKMultiPolyline) {
        super.init(overlay: multiPolyline)
    }
}

open class MKPolygonRenderer: MKOverlayPathRenderer {
    public var polygon: MKPolygon { overlay as! MKPolygon }

    public init(polygon: MKPolygon) {
        super.init(overlay: polygon)
    }

    public init(multiPolygon: MKMultiPolygon) {
        super.init(overlay: multiPolygon)
    }
}

open class MKCircleRenderer: MKOverlayPathRenderer {
    public var circle: MKCircle { overlay as! MKCircle }

    public init(circle: MKCircle) {
        super.init(overlay: circle)
    }
}

open class MKMultiPolylineRenderer: MKOverlayPathRenderer {
    public var multiPolyline: MKMultiPolyline { overlay as! MKMultiPolyline }

    public init(multiPolyline: MKMultiPolyline) {
        super.init(overlay: multiPolyline)
    }
}

open class MKMultiPolygonRenderer: MKOverlayPathRenderer {
    public var multiPolygon: MKMultiPolygon { overlay as! MKMultiPolygon }

    public init(multiPolygon: MKMultiPolygon) {
        super.init(overlay: multiPolygon)
    }
}

open class MKGradientPolylineRenderer: MKPolylineRenderer {
    public private(set) var locations: [CGFloat] = []

    open func setColors(_ colors: [Any], locations: [CGFloat]) {
        _ = colors
        self.locations = locations
    }
}

open class MKTileOverlayRenderer: MKOverlayRenderer {
    public init(overlay: MKTileOverlay) {
        super.init(overlay: overlay)
    }

    public init(tileOverlay overlay: MKTileOverlay) {
        super.init(overlay: overlay)
    }
}
