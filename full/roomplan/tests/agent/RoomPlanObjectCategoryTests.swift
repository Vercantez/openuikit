import Foundation
import RoomPlan

func testObjectCategorySupportedAttributeTypes() {
    let chair = CapturedRoom.Object.Category.chair.supportedAttributeTypes
    precondition(chair.count == 4)
    let names = Set(chair.map { String(describing: $0) })
    precondition(names.contains("ChairType"))
    precondition(names.contains("ChairLegType"))
    precondition(names.contains("ChairArmType"))
    precondition(names.contains("ChairBackType"))

    let table = CapturedRoom.Object.Category.table.supportedAttributeTypes
    precondition(table.count == 2)
    precondition(CapturedRoom.Object.Category.sofa.supportedAttributeTypes.count == 1)
    precondition(CapturedRoom.Object.Category.storage.supportedAttributeTypes.count == 1)
    precondition(CapturedRoom.Object.Category.bed.supportedAttributeTypes.isEmpty)
    precondition(CapturedRoom.Object.Category.television.supportedAttributeTypes.isEmpty)
}

func testObjectCategorySupportsCombination() {
    precondition(CapturedRoom.Object.Category.chair.supportsCombination([ChairType.stool, ChairLegType.star]))
    precondition(CapturedRoom.Object.Category.chair.supportsCombination([ChairType.dining]))
    precondition(!CapturedRoom.Object.Category.chair.supportsCombination([SofaType.rectangular]))
    precondition(!CapturedRoom.Object.Category.chair.supportsCombination([ChairType.stool, ChairType.dining]))
    precondition(!CapturedRoom.Object.Category.chair.supportsCombination([]))
    precondition(CapturedRoom.Object.Category.table.supportsCombination([TableType.coffee, TableShapeType.rectangular]))
    precondition(CapturedRoom.Object.Category.storage.supportsCombination([StorageType.shelf]))
    precondition(!CapturedRoom.Object.Category.bed.supportsCombination([ChairType.stool]))
}

func testObjectCategorySupportedCombinations() {
    let chair = CapturedRoom.Object.Category.chair.supportedCombinations
    precondition(!chair.isEmpty)
    let singles = chair.filter { $0.count == 1 }
    precondition(singles.contains { ($0.first as? ChairType) == .stool })
    let mixed = chair.filter { $0.count == 2 }
    precondition(mixed.contains { attrs in
        attrs.contains { ($0 as? ChairType) == .stool }
            && attrs.contains { ($0 as? ChairLegType) == .star }
    })
    precondition(CapturedRoom.Object.Category.storage.supportedCombinations.count == 2)
    precondition(CapturedRoom.Object.Category.fireplace.supportedCombinations.isEmpty)
}

func testObjectAttributeLookup() {
    let object = CapturedRoom.Object(
        category: .chair,
        attributes: [ChairType.stool, ChairLegType.star]
    )
    precondition(object.attribute(of: ChairType.self) == .stool)
    precondition(object.attribute(of: ChairLegType.self) == .star)
    precondition(object.attribute(of: SofaType.self) == nil)
    precondition(object.category == .chair)
    precondition(object.confidence == .low)
    precondition(object.story == 0)
    precondition(object.parentIdentifier == nil)
    precondition(object.dimensions == .zero)
    precondition(object.transform == .identity)
}

func testObjectCategoryCodable() {
    let encoded = try! JSONEncoder().encode(CapturedRoom.Object.Category.washerDryer)
    let decoded = try! JSONDecoder().decode(CapturedRoom.Object.Category.self, from: encoded)
    precondition(decoded == .washerDryer)
}

func testCapturedRoomObjectProperties() {
    let identifier = UUID()
    let parent = UUID()
    let object = CapturedRoom.Object(
        category: .table,
        attributes: [TableType.dining],
        confidence: .high,
        dimensions: simd_float3(1, 0.75, 2),
        identifier: identifier,
        parentIdentifier: parent,
        story: 2,
        transform: .identity
    )
    precondition(object.identifier == identifier)
    precondition(object.parentIdentifier == parent)
    precondition(object.story == 2)
    precondition(object.confidence == .high)
    precondition(object.dimensions.y == 0.75)
}
