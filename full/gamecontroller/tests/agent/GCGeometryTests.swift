import Foundation
import Dispatch
import GameController

func testGeometryAndNSValue() {
    let point = GCPoint2Make(1.5, -2)
    precondition(GCPoint2Equal(point, GCPoint2(x: 1.5, y: -2)))
    precondition(!GCPoint2Equal(point, GCPoint2Zero))
    _ = point.x
    _ = point.y
    _ = GCPoint2()
    _ = NSStringFromGCPoint2(point)
    let boxed = NSValue(GCPoint2: point)
    precondition(GCPoint2Equal(boxed.gcPoint2Value, point))
    _ = GCPoint2.self
}
