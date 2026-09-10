#if canImport(Foundation)
import class Foundation.NSObject
import protocol Foundation.NSObjectProtocol
#elseif canImport(ObjectiveC)
import class ObjectiveC.NSObject
import protocol ObjectiveC.NSObjectProtocol
#else
#error("UICoordinateSpace requires the NSObject protocol")
#endif

/// The coordinate conversion contract adopted by UIKit views.
@preconcurrency @MainActor
public protocol UICoordinateSpace: NSObjectProtocol {
    var bounds: CGRect { get }
    func convert(_ point: CGPoint, to coordinateSpace: UICoordinateSpace) -> CGPoint
    func convert(_ point: CGPoint, from coordinateSpace: UICoordinateSpace) -> CGPoint
    func convert(_ rect: CGRect, to coordinateSpace: UICoordinateSpace) -> CGRect
    func convert(_ rect: CGRect, from coordinateSpace: UICoordinateSpace) -> CGRect
}

extension UIView: UICoordinateSpace {
    // CoordinateSpaceProbe, iPhone SE 2x / iOS 26.1, captured in
    // Tools/oracle2/coordinatespaceprobe/ios-26.1.txt: protocol-typed views
    // use ordinary view conversion, including bounds offsets and rotation.
    // A custom NSObject coordinate space receives NO forwarded calls:
    // child (8,9) -> custom is (55,85), custom -> child is (-39,-67),
    // exactly the hierarchy-root conversion. Unknown spaces use that same
    // nil-view route instead of guessing a transform or calling the peer.
    // Keep the cast branches explicit: Apple Swift 6.2.1's release
    // OwnershipModelEliminator aborts when the borrowed existential's
    // `as? UIView` result is passed directly as an Optional<UIView> argument.
    // Screen spaces (signalrowsprobe screen.*, iPhone 16 / iOS 26.1): the
    // root conversion plus the window's frame origin, see `_toScreen`.
    public func convert(_ point: CGPoint, to coordinateSpace: UICoordinateSpace) -> CGPoint {
        if coordinateSpace is _UIScreenCoordinateSpace { return _toScreen(point) }
        guard let view = coordinateSpace as? UIView else {
            return convert(point, to: nil as UIView?)
        }
        return convert(point, to: Optional(view))
    }

    public func convert(_ point: CGPoint, from coordinateSpace: UICoordinateSpace) -> CGPoint {
        if coordinateSpace is _UIScreenCoordinateSpace { return _fromScreen(point) }
        guard let view = coordinateSpace as? UIView else {
            return convert(point, from: nil as UIView?)
        }
        return convert(point, from: Optional(view))
    }

    public func convert(_ rect: CGRect, to coordinateSpace: UICoordinateSpace) -> CGRect {
        if coordinateSpace is _UIScreenCoordinateSpace {
            return UIView._boundingBox(of: rect) { self._toScreen($0) }
        }
        guard let view = coordinateSpace as? UIView else {
            return convert(rect, to: nil as UIView?)
        }
        return convert(rect, to: Optional(view))
    }

    public func convert(_ rect: CGRect, from coordinateSpace: UICoordinateSpace) -> CGRect {
        if coordinateSpace is _UIScreenCoordinateSpace {
            return UIView._boundingBox(of: rect) { self._fromScreen($0) }
        }
        guard let view = coordinateSpace as? UIView else {
            return convert(rect, from: nil as UIView?)
        }
        return convert(rect, from: Optional(view))
    }

    /// Screen-space offset of this view's hierarchy root: a window's frame
    /// origin (measured: an offset window at (10, 20) adds (10, 20)); a
    /// detached hierarchy has no window and no offset (unmeasured).
    var _rootScreenOffset: CGPoint {
        let (_, root) = _transformToRoot()
        guard let window = root as? UIWindow else { return .zero }
        return window.frame.origin
    }

    func _toScreen(_ point: CGPoint) -> CGPoint {
        let inRoot = convert(point, to: nil as UIView?)
        let offset = _rootScreenOffset
        return CGPoint(x: inRoot.x + offset.x, y: inRoot.y + offset.y)
    }

    func _fromScreen(_ point: CGPoint) -> CGPoint {
        let offset = _rootScreenOffset
        return convert(CGPoint(x: point.x - offset.x, y: point.y - offset.y), from: nil as UIView?)
    }

    /// Axis-aligned bounding box of a rect's four converted corners: UIKit's
    /// CGRect conversion through any transform.
    static func _boundingBox(of rect: CGRect, _ convert: (CGPoint) -> CGPoint) -> CGRect {
        let corners = [
            CGPoint(x: rect.minX, y: rect.minY),
            CGPoint(x: rect.maxX, y: rect.minY),
            CGPoint(x: rect.minX, y: rect.maxY),
            CGPoint(x: rect.maxX, y: rect.maxY),
        ].map(convert)
        let minX = corners.map(\.x).min() ?? 0, maxX = corners.map(\.x).max() ?? 0
        let minY = corners.map(\.y).min() ?? 0, maxY = corners.map(\.y).max() ?? 0
        return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }
}

// MARK: - Screen coordinate spaces

/// Marker for `UIScreen.coordinateSpace` / `fixedCoordinateSpace`: points in
/// these spaces are screen points, and every conversion goes through the
/// view's window. Both spaces coincide here (no interface rotation).
protocol _UIScreenCoordinateSpace: UICoordinateSpace {}

extension _UIScreenCoordinateSpace {
    func _convertPoint(_ point: CGPoint, to coordinateSpace: UICoordinateSpace) -> CGPoint {
        guard let view = coordinateSpace as? UIView else { return point }
        return view._fromScreen(point)
    }

    func _convertPoint(_ point: CGPoint, from coordinateSpace: UICoordinateSpace) -> CGPoint {
        guard let view = coordinateSpace as? UIView else { return point }
        return view._toScreen(point)
    }
}

// signalrowsprobe screen.*, iPhone 16 / iOS 26.1: `UIScreen.coordinateSpace`
// is the screen itself; a nested, bounds-offset child under a full-screen
// window converts (8, 9) to (55, 85) and back to (-39, -67); the screen
// space converts the same point to the child as (-39, -67) and from it as
// (55, 85); rotated child: (135, 95), rect (95, 95, 40, 30) and back
// (-78, 106, 40, 30). Screen to fixed space is the identity.
extension UIScreen: _UIScreenCoordinateSpace {
    public func convert(_ point: CGPoint, to coordinateSpace: UICoordinateSpace) -> CGPoint {
        _convertPoint(point, to: coordinateSpace)
    }

    public func convert(_ point: CGPoint, from coordinateSpace: UICoordinateSpace) -> CGPoint {
        _convertPoint(point, from: coordinateSpace)
    }

    public func convert(_ rect: CGRect, to coordinateSpace: UICoordinateSpace) -> CGRect {
        UIView._boundingBox(of: rect) { _convertPoint($0, to: coordinateSpace) }
    }

    public func convert(_ rect: CGRect, from coordinateSpace: UICoordinateSpace) -> CGRect {
        UIView._boundingBox(of: rect) { _convertPoint($0, from: coordinateSpace) }
    }
}

/// `UIScreen.fixedCoordinateSpace`: Apple's private class of the same name,
/// a distinct object with the screen's bounds.
@preconcurrency @MainActor
final class _UIScreenFixedCoordinateSpace: NSObject, _UIScreenCoordinateSpace {
    unowned let screen: UIScreen

    init(screen: UIScreen) {
        self.screen = screen
        super.init()
    }

    var bounds: CGRect { screen.bounds }

    func convert(_ point: CGPoint, to coordinateSpace: UICoordinateSpace) -> CGPoint {
        _convertPoint(point, to: coordinateSpace)
    }

    func convert(_ point: CGPoint, from coordinateSpace: UICoordinateSpace) -> CGPoint {
        _convertPoint(point, from: coordinateSpace)
    }

    func convert(_ rect: CGRect, to coordinateSpace: UICoordinateSpace) -> CGRect {
        UIView._boundingBox(of: rect) { _convertPoint($0, to: coordinateSpace) }
    }

    func convert(_ rect: CGRect, from coordinateSpace: UICoordinateSpace) -> CGRect {
        UIView._boundingBox(of: rect) { _convertPoint($0, from: coordinateSpace) }
    }
}
