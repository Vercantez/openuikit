import Foundation
import RoomPlan

func testCapturedRoomEmptyRoundTrip() {
    let room = CapturedRoom(identifier: UUID(uuidString: "00000000-0000-0000-0000-00000000000A")!, version: 3)
    let data = try! JSONEncoder().encode(room)
    let decoded = try! JSONDecoder().decode(CapturedRoom.self, from: data)
    precondition(decoded.identifier == room.identifier)
    precondition(decoded.version == 3)
    precondition(decoded.walls.isEmpty)
    precondition(decoded.doors.isEmpty)
    precondition(decoded.windows.isEmpty)
    precondition(decoded.openings.isEmpty)
    precondition(decoded.floors.isEmpty)
    precondition(decoded.objects.isEmpty)
    precondition(decoded.sections.isEmpty)
    precondition(decoded.story == 0)
}

func testCapturedRoomWithSurfacesAndObjects() {
    let wall = CapturedRoom.Surface(
        category: .wall,
        confidence: .high,
        dimensions: simd_float3(4, 2.5, 0.1),
        completedEdges: [.top, .left],
        polygonCorners: [simd_float3(0, 0, 0), simd_float3(4, 0, 0)]
    )
    let door = CapturedRoom.Surface(category: .door(isOpen: true), confidence: .medium)
    let window = CapturedRoom.Surface(category: .window)
    let opening = CapturedRoom.Surface(category: .opening)
    let floor = CapturedRoom.Surface(category: .floor, confidence: .low)
    let chair = CapturedRoom.Object(category: .chair, attributes: [ChairType.dining])
    let section = CapturedRoom.Section(
        label: .kitchen,
        center: simd_float3(1, 0, 1),
        story: 1
    )
    let room = CapturedRoom(
        walls: [wall],
        doors: [door],
        windows: [window],
        openings: [opening],
        floors: [floor],
        objects: [chair],
        sections: [section],
        story: 1,
        version: 2
    )
    let data = try! JSONEncoder().encode(room)
    let decoded = try! JSONDecoder().decode(CapturedRoom.self, from: data)
    precondition(decoded.walls.count == 1)
    precondition(decoded.walls[0].category == .wall)
    precondition(decoded.walls[0].completedEdges.contains(.top))
    precondition(decoded.doors[0].category == .door(isOpen: true))
    precondition(decoded.windows[0].category == .window)
    precondition(decoded.openings[0].category == .opening)
    precondition(decoded.floors[0].category == .floor)
    precondition(decoded.objects[0].attribute(of: ChairType.self) == .dining)
    precondition(decoded.sections[0].label == .kitchen)
    precondition(decoded.sections[0].center.x == 1)
    precondition(decoded.story == 1)
    precondition(decoded.version == 2)
}

func testCapturedRoomDataRoundTrip() {
    final class EndBox: RoomCaptureSessionDelegate {
        var data: CapturedRoomData?
        func captureSession(
            _ session: RoomCaptureSession,
            didEndWith data: CapturedRoomData,
            error: (any Error)?
        ) {
            self.data = data
        }
    }
    let session = RoomCaptureSession()
    let box = EndBox()
    session.delegate = box
    session.run(configuration: RoomCaptureSession.Configuration())
    let original = box.data!
    let encoded = try! JSONEncoder().encode(original)
    let decoded = try! JSONDecoder().decode(CapturedRoomData.self, from: encoded)
    let again = try! JSONEncoder().encode(decoded)
    precondition(encoded == again)
}

func testCapturedStructureRoundTrip() {
    let room = CapturedRoom(
        walls: [CapturedRoom.Surface(category: .wall)],
        identifier: UUID(uuidString: "00000000-0000-0000-0000-00000000000B")!
    )
    let structure = CapturedStructure(rooms: [room], version: 5)
    precondition(structure.rooms.count == 1)
    precondition(structure.walls.count == 1)
    precondition(structure.version == 5)
    let data = try! JSONEncoder().encode(structure)
    let decoded = try! JSONDecoder().decode(CapturedStructure.self, from: data)
    precondition(decoded.rooms[0].identifier == room.identifier)
    precondition(decoded.walls.count == 1)
    precondition(decoded.version == 5)
}

func testAttributesCodableRepresentation() {
    let representation = CapturedRoom.AttributesCodableRepresentation(
        attributes: [ChairType.stool, ChairLegType.star]
    )
    precondition(representation.attributes.count == 2)
    let data = try! JSONEncoder().encode(representation)
    let decoded = try! JSONDecoder().decode(
        CapturedRoom.AttributesCodableRepresentation.self,
        from: data
    )
    precondition(decoded.attributes.count == 2)
    precondition(decoded.attributes.contains { ($0 as? ChairType) == .stool })
    precondition(decoded.attributes.contains { ($0 as? ChairLegType) == .star })
}

func testSurfaceCurveCoding() {
    let curve = CapturedRoom.Surface.Curve(
        startAngle: Measurement(value: 0, unit: .degrees),
        endAngle: Measurement(value: 90, unit: .degrees),
        center: simd_float2(1, 2),
        radius: 0.5
    )
    let surface = CapturedRoom.Surface(category: .wall, curve: curve)
    precondition(surface.curve?.radius == 0.5)
    let data = try! JSONEncoder().encode(surface)
    let decoded = try! JSONDecoder().decode(CapturedRoom.Surface.self, from: data)
    precondition(decoded.curve?.radius == 0.5)
    precondition(decoded.curve?.center.x == 1)
    precondition(decoded.curve?.center.y == 2)
}

func testConfidenceCoding() {
    let encoded = try! JSONEncoder().encode(CapturedRoom.Confidence.medium)
    let decoded = try! JSONDecoder().decode(CapturedRoom.Confidence.self, from: encoded)
    precondition(decoded == .medium)
}

func testSectionCoding() {
    let section = CapturedRoom.Section(label: .diningRoom, center: simd_float3(3, 0, 4), story: 2)
    let data = try! JSONEncoder().encode(section)
    let decoded = try! JSONDecoder().decode(CapturedRoom.Section.self, from: data)
    precondition(decoded.label == .diningRoom)
    precondition(decoded.center.z == 4)
    precondition(decoded.story == 2)
}

func testSurfaceCategoryCoding() {
    for category in [
        CapturedRoom.Surface.Category.wall,
        .opening,
        .window,
        .door(isOpen: false),
        .floor,
    ] {
        let data = try! JSONEncoder().encode(category)
        let decoded = try! JSONDecoder().decode(CapturedRoom.Surface.Category.self, from: data)
        precondition(decoded == category)
    }
}

func testCapturedElementCategoryCoding() {
    let original = CapturedElementCategory.object(.sink)
    let data = try! JSONEncoder().encode(original)
    let decoded = try! JSONDecoder().decode(CapturedElementCategory.self, from: data)
    precondition(decoded == original)
    let surface = CapturedElementCategory.surface(.window)
    let surfaceDecoded = try! JSONDecoder().decode(
        CapturedElementCategory.self,
        from: try! JSONEncoder().encode(surface)
    )
    precondition(surfaceDecoded == surface)
}

func testSectionLabelCoding() {
    let encoded = try! JSONEncoder().encode(CapturedRoom.Section.Label.bathroom)
    let decoded = try! JSONDecoder().decode(CapturedRoom.Section.Label.self, from: encoded)
    precondition(decoded == .bathroom)
}

func testSurfaceEdgeCoding() {
    let encoded = try! JSONEncoder().encode(CapturedRoom.Surface.Edge.bottom)
    let decoded = try! JSONDecoder().decode(CapturedRoom.Surface.Edge.self, from: encoded)
    precondition(decoded == .bottom)
}
