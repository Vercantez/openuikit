import Foundation
import IOSurface

func testBridgeInits() {
    let original = iosurfaceMakeBGRA(2, 2)
    let asRef = IOSurfaceRef(original)
    let asObj = IOSurface(asRef)
    precondition(asRef.surfaceID == original.surfaceID)
    precondition(asObj.surfaceID == original.surfaceID)
    precondition(asRef == original)
    precondition(asObj == original)
}

func testEqualityAndHash() {
    let first = iosurfaceMakeBGRA(2, 1)
    let second = iosurfaceMakeBGRA(2, 1)
    precondition(first != second)
    precondition(IOSurfaceRef(first) == first)
    var hasher = Hasher()
    first.hash(into: &hasher)
    _ = first.hashValue
    _ = second.hashValue
}

func testIOSurfaceRefEquality() {
    let surface = iosurfaceMakeBGRA(2, 1)
    let copy = IOSurfaceRef(surface)
    precondition(surface == copy)
    precondition(!(surface != copy))
}
