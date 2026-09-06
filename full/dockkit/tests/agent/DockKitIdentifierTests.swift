import Foundation
import DockKit

func testIdentifierProperties() {
    let uuid = UUID(uuidString: "AAAAAAAA-BBBB-CCCC-DDDD-EEEEFFFFFFFF")!
    let identifier = DockAccessory.Identifier(
        name: "Studio Stand",
        uuid: uuid,
        category: .trackingStand
    )
    precondition(identifier.name == "Studio Stand")
    precondition(identifier.uuid == uuid)
    precondition(identifier.category == .trackingStand)
}

func testIdentifierEqualityAndHash() {
    let uuid = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
    let a = DockAccessory.Identifier(name: "A", uuid: uuid, category: .trackingStand)
    let b = DockAccessory.Identifier(name: "A", uuid: uuid, category: .trackingStand)
    let c = DockAccessory.Identifier(name: "B", uuid: uuid, category: .trackingStand)
    precondition(a == b)
    precondition(a != c)
    var hasherA = Hasher()
    var hasherB = Hasher()
    a.hash(into: &hasherA)
    b.hash(into: &hasherB)
    precondition(hasherA.finalize() == hasherB.finalize())
    precondition(a.hashValue == b.hashValue)
}

func testIdentifierDebugDescription() {
    let uuid = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!
    let identifier = DockAccessory.Identifier(
        name: "Pole",
        uuid: uuid,
        category: .trackingStand
    )
    let description = identifier.debugDescription
    precondition(description.contains("Pole"))
    precondition(description.contains(uuid.uuidString))
    precondition(description.contains("trackingStand"))
}
