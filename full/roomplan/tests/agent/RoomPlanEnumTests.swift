import Foundation
import RoomPlan

func testCapturedRoomConfidenceCases() {
    let cases: [CapturedRoom.Confidence] = [.high, .medium, .low]
    precondition(cases[0] == .high)
    precondition(cases[1] == .medium)
    precondition(cases[2] == .low)
    precondition(CapturedRoom.Confidence.high != .low)
    precondition(CapturedRoom.Confidence.medium != .high)

    var hasherA = Hasher()
    var hasherB = Hasher()
    CapturedRoom.Confidence.high.hash(into: &hasherA)
    CapturedRoom.Confidence.high.hash(into: &hasherB)
    precondition(hasherA.finalize() == hasherB.finalize())
    precondition(CapturedRoom.Confidence.low.hashValue == CapturedRoom.Confidence.low.hashValue)
}

func testSurfaceEdgeCases() {
    precondition(CapturedRoom.Surface.Edge.allCases == [.top, .right, .bottom, .left])
    let _: CapturedRoom.Surface.Edge.AllCases = CapturedRoom.Surface.Edge.allCases
    precondition(CapturedRoom.Surface.Edge.top != .bottom)
    precondition(CapturedRoom.Surface.Edge.left != .right)

    var hasherA = Hasher()
    var hasherB = Hasher()
    CapturedRoom.Surface.Edge.top.hash(into: &hasherA)
    CapturedRoom.Surface.Edge.top.hash(into: &hasherB)
    precondition(hasherA.finalize() == hasherB.finalize())
    precondition(CapturedRoom.Surface.Edge.right.hashValue == CapturedRoom.Surface.Edge.right.hashValue)
}

func testSurfaceCategoryCases() {
    let wall = CapturedRoom.Surface.Category.wall
    let opening = CapturedRoom.Surface.Category.opening
    let window = CapturedRoom.Surface.Category.window
    let doorOpen = CapturedRoom.Surface.Category.door(isOpen: true)
    let doorClosed = CapturedRoom.Surface.Category.door(isOpen: false)
    let floor = CapturedRoom.Surface.Category.floor
    precondition(wall != opening)
    precondition(window != floor)
    precondition(doorOpen != doorClosed)
    precondition(doorOpen == .door(isOpen: true))

    var hasherA = Hasher()
    var hasherB = Hasher()
    doorOpen.hash(into: &hasherA)
    CapturedRoom.Surface.Category.door(isOpen: true).hash(into: &hasherB)
    precondition(hasherA.finalize() == hasherB.finalize())
    precondition(wall.hashValue == CapturedRoom.Surface.Category.wall.hashValue)
}

func testSectionLabelRawValues() {
    precondition(CapturedRoom.Section.Label.livingRoom.rawValue == "livingRoom")
    precondition(CapturedRoom.Section.Label.bedroom.rawValue == "bedroom")
    precondition(CapturedRoom.Section.Label.bathroom.rawValue == "bathroom")
    precondition(CapturedRoom.Section.Label.kitchen.rawValue == "kitchen")
    precondition(CapturedRoom.Section.Label.diningRoom.rawValue == "diningRoom")
    precondition(CapturedRoom.Section.Label.unidentified.rawValue == "unidentified")
    precondition(CapturedRoom.Section.Label(rawValue: "kitchen") == .kitchen)
    precondition(CapturedRoom.Section.Label(rawValue: "garage") == nil)
    precondition(CapturedRoom.Section.Label.bedroom != .bathroom)
    let _: CapturedRoom.Section.Label.RawValue = CapturedRoom.Section.Label.kitchen.rawValue

    var hasherA = Hasher()
    var hasherB = Hasher()
    CapturedRoom.Section.Label.kitchen.hash(into: &hasherA)
    CapturedRoom.Section.Label.kitchen.hash(into: &hasherB)
    precondition(hasherA.finalize() == hasherB.finalize())
    precondition(
        CapturedRoom.Section.Label.livingRoom.hashValue
            == CapturedRoom.Section.Label.livingRoom.hashValue
    )
}

func testCapturedElementCategoryCases() {
    let surface = CapturedElementCategory.surface(.wall)
    let object = CapturedElementCategory.object(.chair)
    precondition(surface != object)
    precondition(surface == .surface(.wall))
    precondition(object == .object(.chair))
    precondition(CapturedElementCategory.object(.table) != .object(.sofa))
}

func testObjectCategoryAllCases() {
    let expected: [CapturedRoom.Object.Category] = [
        .storage, .refrigerator, .stove, .bed, .sink, .washerDryer, .toilet, .bathtub,
        .oven, .dishwasher, .table, .sofa, .chair, .fireplace, .television, .stairs,
    ]
    precondition(CapturedRoom.Object.Category.allCases == expected)
    let _: CapturedRoom.Object.Category.AllCases = CapturedRoom.Object.Category.allCases
    precondition(CapturedRoom.Object.Category.chair != .sofa)
    precondition(CapturedRoom.Object.Category.storage != .table)

    var hasherA = Hasher()
    var hasherB = Hasher()
    CapturedRoom.Object.Category.chair.hash(into: &hasherA)
    CapturedRoom.Object.Category.chair.hash(into: &hasherB)
    precondition(hasherA.finalize() == hasherB.finalize())
    precondition(
        CapturedRoom.Object.Category.bed.hashValue == CapturedRoom.Object.Category.bed.hashValue
    )
}

func testCaptureSessionInstructionCases() {
    let cases: [RoomCaptureSession.Instruction] = [
        .moveCloseToWall, .moveAwayFromWall, .slowDown, .turnOnLight, .normal, .lowTexture,
    ]
    precondition(cases.count == 6)
    precondition(RoomCaptureSession.Instruction.normal != .slowDown)
    precondition(RoomCaptureSession.Instruction.lowTexture != .turnOnLight)

    var hasherA = Hasher()
    var hasherB = Hasher()
    RoomCaptureSession.Instruction.normal.hash(into: &hasherA)
    RoomCaptureSession.Instruction.normal.hash(into: &hasherB)
    precondition(hasherA.finalize() == hasherB.finalize())
    precondition(
        RoomCaptureSession.Instruction.moveCloseToWall.hashValue
            == RoomCaptureSession.Instruction.moveCloseToWall.hashValue
    )
}

func testSimdFloat4x4Identity() {
    let identity = simd_float4x4.identity
    precondition(identity.columns.0 == SIMD4<Float>(1, 0, 0, 0))
    precondition(identity.columns.3 == SIMD4<Float>(0, 0, 0, 1))
    precondition(identity == simd_float4x4(scalars: identity.scalars))
    let other = simd_float4x4(
        columns: (
            SIMD4<Float>(2, 0, 0, 0),
            SIMD4<Float>(0, 2, 0, 0),
            SIMD4<Float>(0, 0, 2, 0),
            SIMD4<Float>(0, 0, 0, 1)
        )
    )
    precondition(identity != other)
}
