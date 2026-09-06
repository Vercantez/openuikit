import Foundation
import RoomPlan

func testUSDExportOptionsRawValues() {
    precondition(CapturedRoom.USDExportOptions.parametric.rawValue == 1)
    precondition(CapturedRoom.USDExportOptions.mesh.rawValue == 2)
    precondition(CapturedRoom.USDExportOptions.model.rawValue == 4)
    precondition(CapturedRoom.USDExportOptions(rawValue: 1) == .parametric)
    precondition(CapturedRoom.USDExportOptions(rawValue: 2) == .mesh)
    precondition(CapturedRoom.USDExportOptions(rawValue: 4) == .model)
    let _: CapturedRoom.USDExportOptions.RawValue = CapturedRoom.USDExportOptions.mesh.rawValue
    let _: CapturedRoom.USDExportOptions.Element = .mesh
    let _: CapturedRoom.USDExportOptions.ArrayLiteralElement = .parametric
}

func testUSDExportOptionsUnion() {
    let combined = CapturedRoom.USDExportOptions.mesh.union(.model)
    precondition(combined.contains(.mesh))
    precondition(combined.contains(.model))
    precondition(!combined.contains(.parametric))
    var mutating = CapturedRoom.USDExportOptions.parametric
    mutating.formUnion(.mesh)
    precondition(mutating.contains(.parametric))
    precondition(mutating.contains(.mesh))
}

func testUSDExportOptionsIntersection() {
    let left: CapturedRoom.USDExportOptions = [.mesh, .model]
    let right: CapturedRoom.USDExportOptions = [.model, .parametric]
    let overlap = left.intersection(right)
    precondition(overlap == .model)
    var mutating = left
    mutating.formIntersection(right)
    precondition(mutating == .model)
}

func testUSDExportOptionsSymmetricDifference() {
    let left: CapturedRoom.USDExportOptions = [.mesh, .model]
    let right: CapturedRoom.USDExportOptions = [.model, .parametric]
    let difference = left.symmetricDifference(right)
    precondition(difference.contains(.mesh))
    precondition(difference.contains(.parametric))
    precondition(!difference.contains(.model))
    var mutating = left
    mutating.formSymmetricDifference(right)
    precondition(mutating == difference)
}

func testUSDExportOptionsContainsInsertRemove() {
    var options = CapturedRoom.USDExportOptions()
    precondition(options.isEmpty)
    let inserted = options.insert(.mesh)
    precondition(inserted.inserted)
    precondition(options.contains(.mesh))
    let again = options.insert(.mesh)
    precondition(!again.inserted)
    let removed = options.remove(.mesh)
    precondition(removed == .mesh)
    precondition(!options.contains(.mesh))
    let updated = options.update(with: .model)
    precondition(updated == nil)
    precondition(options.contains(.model))
}

func testUSDExportOptionsSubsetSuperset() {
    let mesh = CapturedRoom.USDExportOptions.mesh
    let both: CapturedRoom.USDExportOptions = [.mesh, .parametric]
    precondition(mesh.isSubset(of: both))
    precondition(both.isSuperset(of: mesh))
    precondition(mesh.isStrictSubset(of: both))
    precondition(both.isStrictSuperset(of: mesh))
    precondition(!mesh.isDisjoint(with: both))
    precondition(mesh.isDisjoint(with: .model))
}

func testUSDExportOptionsEmptyAndSubtract() {
    var options: CapturedRoom.USDExportOptions = [.mesh, .model]
    precondition(!options.isEmpty)
    let subtracted = options.subtracting(.mesh)
    precondition(subtracted == .model)
    options.subtract(.model)
    precondition(options == .mesh)
    let fromSequence = CapturedRoom.USDExportOptions([.parametric, .mesh])
    precondition(fromSequence.contains(.parametric))
    precondition(fromSequence.contains(.mesh))
}

func testUSDExportOptionsArrayLiteral() {
    let options: CapturedRoom.USDExportOptions = [.parametric, .mesh, .model]
    precondition(options.contains(.parametric))
    precondition(options.contains(.mesh))
    precondition(options.contains(.model))
}

func testUSDExportOptionsInequality() {
    precondition(CapturedRoom.USDExportOptions.mesh != .model)
    precondition(CapturedRoom.USDExportOptions.parametric != .mesh)
    precondition(CapturedRoom.USDExportOptions() != .mesh)
}

func testConfigurationOptionsRawValues() {
    precondition(RoomBuilder.ConfigurationOptions.beautifyObjects.rawValue == 1)
    precondition(RoomBuilder.ConfigurationOptions(rawValue: 1) == .beautifyObjects)
    precondition(RoomBuilder.ConfigurationOptions().rawValue == 0)
    let _: RoomBuilder.ConfigurationOptions.RawValue = RoomBuilder.ConfigurationOptions.beautifyObjects.rawValue
    let _: RoomBuilder.ConfigurationOptions.Element = .beautifyObjects
    let _: RoomBuilder.ConfigurationOptions.ArrayLiteralElement = .beautifyObjects
}

func testConfigurationOptionsAlgebra() {
    var options = RoomBuilder.ConfigurationOptions()
    precondition(options.isEmpty)
    precondition(options.insert(.beautifyObjects).inserted)
    precondition(options.contains(.beautifyObjects))
    let unioned = options.union(.beautifyObjects)
    precondition(unioned == .beautifyObjects)
    let intersection = options.intersection(.beautifyObjects)
    precondition(intersection == .beautifyObjects)
    let difference = options.symmetricDifference(.beautifyObjects)
    precondition(difference.isEmpty)
    options.formUnion([])
    options.formIntersection(.beautifyObjects)
    options.formSymmetricDifference([])
    precondition(options == .beautifyObjects)
    let removed = options.remove(.beautifyObjects)
    precondition(removed == .beautifyObjects)
    precondition(options.update(with: .beautifyObjects) == nil)
    precondition(options.subtracting(.beautifyObjects).isEmpty)
    options.subtract(.beautifyObjects)
    precondition(options.isEmpty)
    precondition(RoomBuilder.ConfigurationOptions.beautifyObjects.isSubset(of: .beautifyObjects))
    precondition(RoomBuilder.ConfigurationOptions.beautifyObjects.isSuperset(of: .beautifyObjects))
    precondition(!RoomBuilder.ConfigurationOptions.beautifyObjects.isStrictSubset(of: .beautifyObjects))
    precondition(!RoomBuilder.ConfigurationOptions.beautifyObjects.isStrictSuperset(of: .beautifyObjects))
    precondition(RoomBuilder.ConfigurationOptions().isDisjoint(with: .beautifyObjects))
    let fromSequence = RoomBuilder.ConfigurationOptions([.beautifyObjects])
    precondition(fromSequence == .beautifyObjects)
}

func testConfigurationOptionsArrayLiteral() {
    let options: RoomBuilder.ConfigurationOptions = [.beautifyObjects]
    precondition(options.contains(.beautifyObjects))
}

func testConfigurationOptionsInequality() {
    precondition(RoomBuilder.ConfigurationOptions.beautifyObjects != RoomBuilder.ConfigurationOptions())
}
