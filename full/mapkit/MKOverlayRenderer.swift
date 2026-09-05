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

open class MKOverlayRenderer: NSObject {
    public let overlay: any MKOverlay
    open var alpha: CGFloat = 1
    open var contentScaleFactor: CGFloat = 1
    open var blendMode: CGBlendMode = .normal

    public init(overlay: any MKOverlay) {
        self.overlay = overlay
        super.init()
    }

    open func point(for mapPoint: MKMapPoint) -> CGPoint {
        CGPoint(x: CGFloat(mapPoint.x), y: CGFloat(mapPoint.y))
    }

    open func mapPoint(for point: CGPoint) -> MKMapPoint {
        MKMapPoint(x: Double(point.x), y: Double(point.y))
    }

    open func rect(for mapRect: MKMapRect) -> CGRect {
        CGRect(
            x: CGFloat(mapRect.origin.x),
            y: CGFloat(mapRect.origin.y),
            width: CGFloat(mapRect.size.width),
            height: CGFloat(mapRect.size.height)
        )
    }

    open func mapRect(for rect: CGRect) -> MKMapRect {
        MKMapRect(
            x: Double(rect.origin.x),
            y: Double(rect.origin.y),
            width: Double(rect.size.width),
            height: Double(rect.size.height)
        )
    }

    open func canDraw(_ mapRect: MKMapRect, zoomScale: MKZoomScale) -> Bool {
        _ = zoomScale
        return overlay.intersects(mapRect)
    }

    open func draw(_ mapRect: MKMapRect, zoomScale: MKZoomScale, in context: CGContext) {
        _ = (mapRect, zoomScale, context)
    }

    open func setNeedsDisplay() {}
    open func setNeedsDisplay(_ mapRect: MKMapRect) { _ = mapRect }
    open func setNeedsDisplay(_ mapRect: MKMapRect, zoomScale: MKZoomScale) {
        _ = (mapRect, zoomScale)
    }
}

open class MKOverlayPathRenderer: MKOverlayRenderer {
    open var fillColor: UIColor?
    open var strokeColor: UIColor?
    open var lineWidth: CGFloat = 1
    open var lineJoin: CGLineJoin = .round
    open var lineCap: CGLineCap = .round
    open var miterLimit: CGFloat = 10
    open var lineDashPhase: CGFloat = 0
    open var lineDashPattern: [NSNumber]?
    open var shouldRasterize: Bool = false
    open var path: CGPath!

    open func createPath() {}

    open func invalidatePath() {
        path = nil
        createPath()
    }

    open func applyFillProperties(to context: CGContext, atZoomScale zoomScale: MKZoomScale) {
        _ = zoomScale
        let color = fillColor ?? .clear
        let rgba = mk_rgba(color)
        context.setFillColor(red: rgba.0, green: rgba.1, blue: rgba.2, alpha: rgba.3 * alpha)
        context.setBlendMode(blendMode)
        context.setAlpha(alpha)
    }

    open func applyStrokeProperties(to context: CGContext, atZoomScale zoomScale: MKZoomScale) {
        let color = strokeColor ?? .black
        let rgba = mk_rgba(color)
        context.setStrokeColor(red: rgba.0, green: rgba.1, blue: rgba.2, alpha: rgba.3 * alpha)
        let scale = max(zoomScale, 0.0001 as MKZoomScale)
        context.setLineWidth(lineWidth / scale)
        context.setLineCap(lineCap)
        context.setLineJoin(lineJoin)
        context.setMiterLimit(miterLimit)
        if let pattern = lineDashPattern {
            context.setLineDash(phase: lineDashPhase, lengths: pattern.map { CGFloat($0.doubleValue) })
        }
    }

    open func strokePath(_ path: CGPath, in context: CGContext) {
        context.addPath(path)
        context.strokePath()
    }

    open func fillPath(_ path: CGPath, in context: CGContext) {
        context.addPath(path)
        context.fillPath()
    }

    open override func draw(_ mapRect: MKMapRect, zoomScale: MKZoomScale, in context: CGContext) {
        if path == nil {
            createPath()
        }
        guard let path else { return }
        _ = mapRect
        context.saveGState()
        applyFillProperties(to: context, atZoomScale: zoomScale)
        fillPath(path, in: context)
        applyStrokeProperties(to: context, atZoomScale: zoomScale)
        strokePath(path, in: context)
        context.restoreGState()
    }
}

open class MKPolylineRenderer: MKOverlayPathRenderer {
    public var polyline: MKPolyline { overlay as! MKPolyline }
    open var strokeStart: CGFloat = 0
    open var strokeEnd: CGFloat = 1

    public init(polyline: MKPolyline) {
        super.init(overlay: polyline)
        strokeColor = .blue
    }

    open override func createPath() {
        path = mk_path(for: polyline.storedPoints)
    }
}

open class MKPolygonRenderer: MKOverlayPathRenderer {
    public var polygon: MKPolygon { overlay as! MKPolygon }
    open var strokeStart: CGFloat = 0
    open var strokeEnd: CGFloat = 1

    public init(polygon: MKPolygon) {
        super.init(overlay: polygon)
        fillColor = UIColor(red: 0, green: 0, blue: 1, alpha: 0.25)
        strokeColor = .blue
    }

    open override func createPath() {
        path = mk_path(for: polygon.storedPoints, close: true)
    }
}

open class MKCircleRenderer: MKOverlayPathRenderer {
    public var circle: MKCircle { overlay as! MKCircle }
    open var strokeStart: CGFloat = 0
    open var strokeEnd: CGFloat = 1

    public init(circle: MKCircle) {
        super.init(overlay: circle)
        fillColor = UIColor(red: 0, green: 0, blue: 1, alpha: 0.25)
        strokeColor = .blue
    }

    open override func createPath() {
        let rect = self.rect(for: circle.boundingMapRect)
        let mutable = CGMutablePath()
        mutable.addEllipse(in: rect)
        path = mutable
    }
}

open class MKMultiPolylineRenderer: MKOverlayPathRenderer {
    public var multiPolyline: MKMultiPolyline { overlay as! MKMultiPolyline }

    public init(multiPolyline: MKMultiPolyline) {
        super.init(overlay: multiPolyline)
        strokeColor = .blue
    }

    open override func createPath() {
        let mutable = CGMutablePath()
        for line in multiPolyline.polylines {
            mk_addLines(line.storedPoints, to: mutable, close: false)
        }
        path = mutable
    }
}

open class MKMultiPolygonRenderer: MKOverlayPathRenderer {
    public var multiPolygon: MKMultiPolygon { overlay as! MKMultiPolygon }

    public init(multiPolygon: MKMultiPolygon) {
        super.init(overlay: multiPolygon)
        fillColor = UIColor(red: 0, green: 0, blue: 1, alpha: 0.25)
        strokeColor = .blue
    }

    open override func createPath() {
        let mutable = CGMutablePath()
        for polygon in multiPolygon.polygons {
            mk_addLines(polygon.storedPoints, to: mutable, close: true)
        }
        path = mutable
    }
}

open class MKGradientPolylineRenderer: MKPolylineRenderer {
    public private(set) var colors: [UIColor] = []
    public private(set) var locations: [CGFloat] = []

    public func setColors(_ colors: [UIColor], locations: [CGFloat]) {
        self.colors = colors
        self.locations = locations
    }
}

open class MKTileOverlayRenderer: MKOverlayRenderer {
    public init(tileOverlay overlay: MKTileOverlay) {
        super.init(overlay: overlay)
    }

    open func reloadData() {}

    open override func draw(_ mapRect: MKMapRect, zoomScale: MKZoomScale, in context: CGContext) {
        // Tile bytes are not fetched on Linux; paint the map's blank fill.
        _ = (mapRect, zoomScale)
        context.setFillColor(red: 0.85, green: 0.85, blue: 0.85, alpha: 1)
        context.fillPath()
    }
}

open class MKOverlayView: UIView {
    open var overlay: (any MKOverlay)?
    public override init(frame: CGRect) {
        super.init(frame: frame)
    }
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
}

open class MKOverlayPathView: MKOverlayView {}
open class MKPolylineView: MKOverlayPathView {}
open class MKPolygonView: MKOverlayPathView {}
open class MKCircleView: MKOverlayPathView {}

func mk_path(for points: [MKMapPoint], close: Bool = false) -> CGMutablePath {
    let path = CGMutablePath()
    mk_addLines(points, to: path, close: close)
    return path
}

func mk_addLines(_ points: [MKMapPoint], to path: CGMutablePath, close: Bool) {
    guard let first = points.first else { return }
    path.move(to: CGPoint(x: CGFloat(first.x), y: CGFloat(first.y)))
    for point in points.dropFirst() {
        path.addLine(to: CGPoint(x: CGFloat(point.x), y: CGFloat(point.y)))
    }
    if close {
        path.closeSubpath()
    }
}

func mk_rgba(_ color: UIColor) -> (CGFloat, CGFloat, CGFloat, CGFloat) {
#if canImport(UIKit)
    var r: CGFloat = 0
    var g: CGFloat = 0
    var b: CGFloat = 0
    var a: CGFloat = 1
    _ = color.getRed(&r, green: &g, blue: &b, alpha: &a)
    return (r, g, b, a)
#else
    return (color.r, color.g, color.b, color.a)
#endif
}
