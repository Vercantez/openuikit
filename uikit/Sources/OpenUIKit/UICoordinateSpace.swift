#if canImport(Foundation)
import protocol Foundation.NSObjectProtocol
#elseif canImport(ObjectiveC)
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
    public func convert(_ point: CGPoint, to coordinateSpace: UICoordinateSpace) -> CGPoint {
        guard let view = coordinateSpace as? UIView else {
            return convert(point, to: nil as UIView?)
        }
        return convert(point, to: Optional(view))
    }

    public func convert(_ point: CGPoint, from coordinateSpace: UICoordinateSpace) -> CGPoint {
        guard let view = coordinateSpace as? UIView else {
            return convert(point, from: nil as UIView?)
        }
        return convert(point, from: Optional(view))
    }

    public func convert(_ rect: CGRect, to coordinateSpace: UICoordinateSpace) -> CGRect {
        guard let view = coordinateSpace as? UIView else {
            return convert(rect, to: nil as UIView?)
        }
        return convert(rect, to: Optional(view))
    }

    public func convert(_ rect: CGRect, from coordinateSpace: UICoordinateSpace) -> CGRect {
        guard let view = coordinateSpace as? UIView else {
            return convert(rect, from: nil as UIView?)
        }
        return convert(rect, from: Optional(view))
    }
}
