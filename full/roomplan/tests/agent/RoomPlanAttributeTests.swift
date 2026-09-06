import Foundation
import RoomPlan

func testChairTypeRawValues() {
    precondition(ChairType.dining.rawValue == "dining")
    precondition(ChairType.stool.rawValue == "stool")
    precondition(ChairType.swivel.rawValue == "swivel")
    precondition(ChairType.unidentified.rawValue == "unidentified")
    precondition(ChairType(rawValue: "dining") == .dining)
    precondition(ChairType(rawValue: "stool") == .stool)
    precondition(ChairType(rawValue: "swivel") == .swivel)
    precondition(ChairType(rawValue: "unidentified") == .unidentified)
    precondition(ChairType(rawValue: "nope") == nil)
    precondition(ChairType.dining != .stool)
}

func testChairLegTypeRawValues() {
    precondition(ChairLegType.four.rawValue == "four")
    precondition(ChairLegType.star.rawValue == "star")
    precondition(ChairLegType.unidentified.rawValue == "unidentified")
    precondition(ChairLegType(rawValue: "four") == .four)
    precondition(ChairLegType(rawValue: "star") == .star)
    precondition(ChairLegType(rawValue: "missing") == nil)
    precondition(ChairLegType.four != .star)
}

func testChairArmTypeRawValues() {
    precondition(ChairArmType.existing.rawValue == "existing")
    precondition(ChairArmType.missing.rawValue == "missing")
    precondition(ChairArmType(rawValue: "existing") == .existing)
    precondition(ChairArmType(rawValue: "missing") == .missing)
    precondition(ChairArmType(rawValue: "none") == nil)
    precondition(ChairArmType.existing != .missing)
}

func testChairBackTypeRawValues() {
    precondition(ChairBackType.existing.rawValue == "existing")
    precondition(ChairBackType.missing.rawValue == "missing")
    precondition(ChairBackType(rawValue: "existing") == .existing)
    precondition(ChairBackType(rawValue: "missing") == .missing)
    precondition(ChairBackType.existing != .missing)
}

func testSofaTypeRawValues() {
    precondition(SofaType.rectangular.rawValue == "rectangular")
    precondition(SofaType.lShaped.rawValue == "lShaped")
    precondition(SofaType.lShapedExtension.rawValue == "lShapedExtension")
    precondition(SofaType.singleSeat.rawValue == "singleSeat")
    precondition(SofaType.unidentified.rawValue == "unidentified")
    precondition(SofaType(rawValue: "lShaped") == .lShaped)
    precondition(SofaType(rawValue: "beanbag") == nil)
    precondition(SofaType.rectangular != .lShaped)
}

func testTableTypeRawValues() {
    precondition(TableType.coffee.rawValue == "coffee")
    precondition(TableType.dining.rawValue == "dining")
    precondition(TableType.unidentified.rawValue == "unidentified")
    precondition(TableType(rawValue: "coffee") == .coffee)
    precondition(TableType.coffee != .dining)
}

func testTableShapeTypeRawValues() {
    precondition(TableShapeType.rectangular.rawValue == "rectangular")
    precondition(TableShapeType.circularElliptic.rawValue == "circularElliptic")
    precondition(TableShapeType.lShaped.rawValue == "lShaped")
    precondition(TableShapeType.unidentified.rawValue == "unidentified")
    precondition(TableShapeType(rawValue: "circularElliptic") == .circularElliptic)
    precondition(TableShapeType.rectangular != .lShaped)
}

func testStorageTypeRawValues() {
    precondition(StorageType.cabinet.rawValue == "cabinet")
    precondition(StorageType.shelf.rawValue == "shelf")
    precondition(StorageType(rawValue: "cabinet") == .cabinet)
    precondition(StorageType(rawValue: "drawer") == nil)
    precondition(StorageType.cabinet != .shelf)
}

func testChairTypeParentCategory() {
    precondition(ChairType.parentCategory == .object(.chair))
}

func testChairLegTypeParentCategory() {
    precondition(ChairLegType.parentCategory == .object(.chair))
}

func testChairArmTypeParentCategory() {
    precondition(ChairArmType.parentCategory == .object(.chair))
}

func testChairBackTypeParentCategory() {
    precondition(ChairBackType.parentCategory == .object(.chair))
}

func testSofaTypeParentCategory() {
    precondition(SofaType.parentCategory == .object(.sofa))
}

func testTableTypeParentCategory() {
    precondition(TableType.parentCategory == .object(.table))
}

func testTableShapeTypeParentCategory() {
    precondition(TableShapeType.parentCategory == .object(.table))
}

func testStorageTypeParentCategory() {
    precondition(StorageType.parentCategory == .object(.storage))
}

func testAttributeShortIdentifiers() {
    precondition(ChairType.dining.shortIdentifier == "dining")
    precondition(ChairLegType.star.shortIdentifier == "star")
    precondition(ChairArmType.missing.shortIdentifier == "missing")
    precondition(ChairBackType.existing.shortIdentifier == "existing")
    precondition(SofaType.singleSeat.shortIdentifier == "singleSeat")
    precondition(TableType.coffee.shortIdentifier == "coffee")
    precondition(TableShapeType.circularElliptic.shortIdentifier == "circularElliptic")
    precondition(StorageType.shelf.shortIdentifier == "shelf")
}

func testChairTypeAllCases() {
    precondition(ChairType.allCases == [.dining, .stool, .swivel, .unidentified])
    let _: ChairType.AllCases = ChairType.allCases
    let _: ChairType.RawValue = ChairType.dining.rawValue
}

func testChairLegTypeAllCases() {
    precondition(ChairLegType.allCases == [.four, .star, .unidentified])
    let _: ChairLegType.AllCases = ChairLegType.allCases
    let _: ChairLegType.RawValue = ChairLegType.four.rawValue
}

func testChairArmTypeAllCases() {
    precondition(ChairArmType.allCases == [.existing, .missing])
    let _: ChairArmType.AllCases = ChairArmType.allCases
    let _: ChairArmType.RawValue = ChairArmType.existing.rawValue
}

func testChairBackTypeAllCases() {
    precondition(ChairBackType.allCases == [.existing, .missing])
    let _: ChairBackType.AllCases = ChairBackType.allCases
    let _: ChairBackType.RawValue = ChairBackType.existing.rawValue
}

func testSofaTypeAllCases() {
    precondition(
        SofaType.allCases == [
            .rectangular, .lShaped, .lShapedExtension, .singleSeat, .unidentified,
        ]
    )
    let _: SofaType.AllCases = SofaType.allCases
    let _: SofaType.RawValue = SofaType.rectangular.rawValue
}

func testTableTypeAllCases() {
    precondition(TableType.allCases == [.coffee, .dining, .unidentified])
    let _: TableType.AllCases = TableType.allCases
    let _: TableType.RawValue = TableType.coffee.rawValue
}

func testTableShapeTypeAllCases() {
    precondition(
        TableShapeType.allCases == [.rectangular, .circularElliptic, .lShaped, .unidentified]
    )
    let _: TableShapeType.AllCases = TableShapeType.allCases
    let _: TableShapeType.RawValue = TableShapeType.lShaped.rawValue
}

func testStorageTypeAllCases() {
    precondition(StorageType.allCases == [.cabinet, .shelf])
    let _: StorageType.AllCases = StorageType.allCases
    let _: StorageType.RawValue = StorageType.cabinet.rawValue
}

func testCapturedRoomAttributeProtocol() {
    let attribute: any CapturedRoomAttribute = ChairType.stool
    precondition(attribute.rawValue == "stool")
    precondition(attribute.shortIdentifier == "stool")
    precondition(type(of: attribute).parentCategory == .object(.chair))
}

func testAttributeInequalityAndHash() {
    precondition(ChairType.dining != ChairType.stool)
    precondition(ChairLegType.four != ChairLegType.star)
    precondition(SofaType.rectangular != SofaType.unidentified)
    precondition(TableType.coffee != TableType.dining)
    precondition(StorageType.cabinet != StorageType.shelf)

    var hasherA = Hasher()
    var hasherB = Hasher()
    ChairType.dining.hash(into: &hasherA)
    ChairType.dining.hash(into: &hasherB)
    precondition(hasherA.finalize() == hasherB.finalize())
    precondition(ChairType.dining.hashValue == ChairType.dining.hashValue)
    precondition(SofaType.lShaped.hashValue == SofaType.lShaped.hashValue)
    StorageType.shelf.hash(into: &hasherA)
}

func testAttributeCodable() {
    let encoded = try! JSONEncoder().encode(ChairType.swivel)
    let decoded = try! JSONDecoder().decode(ChairType.self, from: encoded)
    precondition(decoded == .swivel)

    let sofa = try! JSONDecoder().decode(SofaType.self, from: Data("\"singleSeat\"".utf8))
    precondition(sofa == .singleSeat)
}
