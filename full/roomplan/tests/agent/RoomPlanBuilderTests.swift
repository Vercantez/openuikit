import Foundation
import RoomPlan

func testRoomBuilderInit() {
    let empty = RoomBuilder(options: [])
    _ = empty
    let beautified = RoomBuilder(options: .beautifyObjects)
    _ = beautified
}

func testStructureBuilderInit() {
    let builder = StructureBuilder(options: .beautifyObjects)
    _ = builder
    let plain = StructureBuilder(options: [])
    _ = plain
}

func testStructureBuilderConfigurationOptionsAlias() {
    let options: StructureBuilder.ConfigurationOptions = .beautifyObjects
    precondition(options == RoomBuilder.ConfigurationOptions.beautifyObjects)
}

func testCapturedStructureTypealiases() {
    let surface: CapturedStructure.Surface = CapturedRoom.Surface(category: .wall)
    let object: CapturedStructure.Object = CapturedRoom.Object(category: .bed)
    let section: CapturedStructure.Section = CapturedRoom.Section(label: .bedroom)
    let options: CapturedStructure.USDExportOptions = .mesh
    let provider: CapturedStructure.ModelProvider = CapturedRoom.ModelProvider()
    let error: CapturedStructure.Error = .deviceNotSupported
    _ = surface
    _ = object
    _ = section
    _ = options
    _ = provider
    precondition(error == CapturedRoom.Error.deviceNotSupported)
    _ = provider.modelFileURLs
}

func testCapturedStructureAggregation() {
    let roomA = CapturedRoom(
        walls: [CapturedRoom.Surface(category: .wall)],
        objects: [CapturedRoom.Object(category: .chair)],
        sections: [CapturedRoom.Section(label: .livingRoom)]
    )
    let roomB = CapturedRoom(
        doors: [CapturedRoom.Surface(category: .door(isOpen: false))],
        windows: [CapturedRoom.Surface(category: .window)],
        openings: [CapturedRoom.Surface(category: .opening)],
        floors: [CapturedRoom.Surface(category: .floor)]
    )
    let structure = CapturedStructure(rooms: [roomA, roomB])
    precondition(structure.rooms.count == 2)
    precondition(structure.walls.count == 1)
    precondition(structure.objects.count == 1)
    precondition(structure.sections.count == 1)
    precondition(structure.doors.count == 1)
    precondition(structure.windows.count == 1)
    precondition(structure.openings.count == 1)
    precondition(structure.floors.count == 1)
}

func testCapturedRoomSurfaceProperties() {
    let identifier = UUID()
    let parent = UUID()
    let surface = CapturedRoom.Surface(
        category: .window,
        confidence: .medium,
        dimensions: simd_float3(1.2, 1.4, 0.05),
        identifier: identifier,
        completedEdges: [.bottom, .right],
        polygonCorners: [simd_float3(0, 0, 0)],
        parentIdentifier: parent,
        story: 3,
        transform: .identity
    )
    precondition(surface.identifier == identifier)
    precondition(surface.parentIdentifier == parent)
    precondition(surface.story == 3)
    precondition(surface.confidence == .medium)
    precondition(surface.category == .window)
    precondition(surface.completedEdges.contains(.bottom))
    precondition(surface.polygonCorners.count == 1)
}

func testCGRectStandIn() {
    let rect = CGRect(x: 10, y: 20, width: 30, height: 40)
    precondition(rect.origin.x == 10)
    precondition(rect.origin.y == 20)
    precondition(rect.width == 30)
    precondition(rect.height == 40)
    precondition(CGRect.zero == CGRect(x: 0, y: 0, width: 0, height: 0))
}
