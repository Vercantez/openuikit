import Foundation
import VideoSubscriberAccount

func testQueryOptionsAllDevices() {
    precondition(VSUserAccountManager.QueryOptions.allDevices.rawValue == 1)
    precondition(VSUserAccountManager.QueryOptions.allDevices.contains(.allDevices))
}

func testQueryOptionsEmptyAndRawValue() {
    let empty = VSUserAccountManager.QueryOptions()
    precondition(empty.isEmpty)
    precondition(empty.rawValue == 0)
    let fromRaw = VSUserAccountManager.QueryOptions(rawValue: 1)
    precondition(fromRaw == .allDevices)
    precondition(empty != .allDevices)
}

func testQueryOptionsUnionAndIntersection() {
    let empty = VSUserAccountManager.QueryOptions()
    let unioned = empty.union(.allDevices)
    precondition(unioned == .allDevices)
    var forming = VSUserAccountManager.QueryOptions()
    forming.formUnion(.allDevices)
    precondition(forming == .allDevices)
    let intersection = VSUserAccountManager.QueryOptions.allDevices.intersection(.allDevices)
    precondition(intersection == .allDevices)
    var formingIntersection = VSUserAccountManager.QueryOptions.allDevices
    formingIntersection.formIntersection(.allDevices)
    precondition(formingIntersection == .allDevices)
    let disjoint = VSUserAccountManager.QueryOptions().intersection(.allDevices)
    precondition(disjoint.isEmpty)
}

func testQueryOptionsSymmetricDifferenceAndSubtract() {
    let empty = VSUserAccountManager.QueryOptions()
    let symmetric = empty.symmetricDifference(.allDevices)
    precondition(symmetric == .allDevices)
    var forming = VSUserAccountManager.QueryOptions()
    forming.formSymmetricDifference(.allDevices)
    precondition(forming == .allDevices)
    let subtracted = VSUserAccountManager.QueryOptions.allDevices.subtracting(.allDevices)
    precondition(subtracted.isEmpty)
    var mutating = VSUserAccountManager.QueryOptions.allDevices
    mutating.subtract(.allDevices)
    precondition(mutating.isEmpty)
}

func testQueryOptionsInsertRemoveUpdateContains() {
    var options = VSUserAccountManager.QueryOptions()
    let insertResult = options.insert(.allDevices)
    precondition(insertResult.inserted)
    precondition(insertResult.memberAfterInsert == .allDevices)
    precondition(options.contains(.allDevices))
    let secondInsert = options.insert(.allDevices)
    precondition(!secondInsert.inserted)
    let updated = options.update(with: .allDevices)
    precondition(updated == .allDevices)
    let removed = options.remove(.allDevices)
    precondition(removed == .allDevices)
    precondition(!options.contains(.allDevices))
    precondition(options.remove(.allDevices) == nil)
}

func testQueryOptionsSubsetRelations() {
    let empty = VSUserAccountManager.QueryOptions()
    let all = VSUserAccountManager.QueryOptions.allDevices
    precondition(empty.isSubset(of: all))
    precondition(all.isSuperset(of: empty))
    precondition(empty.isStrictSubset(of: all))
    precondition(all.isStrictSuperset(of: empty))
    precondition(empty.isDisjoint(with: all))
    precondition(!all.isDisjoint(with: .allDevices))
    precondition(!all.isStrictSubset(of: all))
}

func testQueryOptionsSequenceAndArrayLiteralInits() {
    let fromSequence = VSUserAccountManager.QueryOptions([.allDevices])
    precondition(fromSequence == .allDevices)
    let literal: VSUserAccountManager.QueryOptions = [.allDevices]
    precondition(literal == .allDevices)
    let emptyLiteral: VSUserAccountManager.QueryOptions = []
    precondition(emptyLiteral.isEmpty)
}
