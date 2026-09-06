import Foundation

/// Collider used for hit-testing a control's layout box.
/// Raw values follow the pinned `dotnet/macios` `[Native]` declaration order.
public enum TCColliderShape: Int, Sendable, Hashable {
    case circle = 0
    case rect = 1
    case leftSide = 2
    case rightSide = 3
}

/// Layout anchor on the parent canvas and on the control's own box.
/// Raw values follow the pinned `dotnet/macios` `[Native]` declaration order.
public enum TCControlLayoutAnchor: Int, Sendable, Hashable {
    case topLeft = 0
    case topCenter = 1
    case topRight = 2
    case centerLeft = 3
    case center = 4
    case centerRight = 5
    case bottomLeft = 6
    case bottomCenter = 7
    case bottomRight = 8
}

/// How `offset` is applied when resolving `position`.
/// Raw values follow the pinned `dotnet/macios` `[Native]` declaration order.
///
/// Linux policy (Apple's exact units are an oracle question):
/// - `absolute`: `offset` is in points, added to the parent-side anchor.
/// - `relative`: `offset` is a fraction of the parent size, added to the
///   parent-side anchor (`dx = offset.x * parent.width`).
public enum TCControlLayoutAnchorCoordinateSystem: Int, Sendable, Hashable {
    case relative = 0
    case absolute = 1
}
