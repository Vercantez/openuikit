import Foundation
@_spi(OpenUIKitHost) import FamilyControls

/// Table-driven `FamilyControlsMember` cases (`child = 0`, `individual = 1`).
func testMemberCases() {
    let table: [(FamilyControlsMember, Int)] = [
        (.child, 0),
        (.individual, 1),
    ]
    precondition(Set(table.map(\.0)).count == 2)
    precondition(Set(table.map(\.1)).count == 2)
    for (value, raw) in table {
        precondition(value.rawValue == raw)
        precondition(FamilyControlsMember(rawValue: raw) == value)
    }
    typealias Raw = FamilyControlsMember.RawValue
    precondition((table[0].1 as Raw) == 0)
}

func testMemberRawValueInit() {
    precondition(FamilyControlsMember(rawValue: 0) == .child)
    precondition(FamilyControlsMember(rawValue: 1) == .individual)
    precondition(FamilyControlsMember(rawValue: 2) == nil)
    precondition(FamilyControlsMember(rawValue: -1) == nil)
}

func testMemberDescription() {
    precondition(FamilyControlsMember.child.description == "child")
    precondition(FamilyControlsMember.individual.description == "individual")
    precondition(String(describing: FamilyControlsMember.child) == "child")
}

func testMemberInequality() {
    precondition(FamilyControlsMember.child != .individual)
    precondition(!(FamilyControlsMember.child != .child))
    precondition(FamilyControlsMember.individual == .individual)
}

func testMemberHash() {
    var hasher = Hasher()
    FamilyControlsMember.child.hash(into: &hasher)
    FamilyControlsMember.individual.hash(into: &hasher)
    _ = hasher.finalize()
    precondition(FamilyControlsMember.child.hashValue == FamilyControlsMember.child.hashValue)
    let set: Set<FamilyControlsMember> = [.child, .individual, .child]
    precondition(set.count == 2)
}

func testMemberCodable() {
    let encoder = JSONEncoder()
    let decoder = JSONDecoder()
    for member in [FamilyControlsMember.child, .individual] {
        let data = try! encoder.encode(member)
        let decoded = try! decoder.decode(FamilyControlsMember.self, from: data)
        precondition(decoded == member)
    }
}
