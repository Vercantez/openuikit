import Foundation
import DeclaredAgeRange

func testAgeRangeDeclarationType() {
    let value: AgeRangeService.AgeRangeDeclaration = .selfDeclared
    precondition(type(of: value) == AgeRangeService.AgeRangeDeclaration.self)
}

func testAgeRangeDeclarationCases() {
    let table: [AgeRangeService.AgeRangeDeclaration] = [
        .selfDeclared,
        .guardianDeclared,
    ]
    precondition(Set(table).count == 2)
    switch table[0] {
    case .selfDeclared:
        break
    case .guardianDeclared:
        preconditionFailure("order mismatch")
    }
    switch table[1] {
    case .guardianDeclared:
        break
    case .selfDeclared:
        preconditionFailure("order mismatch")
    }
}

func testAgeRangeDeclarationEquality() {
    precondition(AgeRangeService.AgeRangeDeclaration.selfDeclared == .selfDeclared)
    precondition(AgeRangeService.AgeRangeDeclaration.guardianDeclared == .guardianDeclared)
    precondition(
        !(AgeRangeService.AgeRangeDeclaration.selfDeclared == .guardianDeclared)
    )
}

func testAgeRangeDeclarationInequality() {
    precondition(AgeRangeService.AgeRangeDeclaration.selfDeclared != .guardianDeclared)
    precondition(
        !(AgeRangeService.AgeRangeDeclaration.selfDeclared != .selfDeclared)
    )
    precondition(
        !(AgeRangeService.AgeRangeDeclaration.guardianDeclared != .guardianDeclared)
    )
}

func testAgeRangeDeclarationHashInto() {
    var hasher = Hasher()
    AgeRangeService.AgeRangeDeclaration.selfDeclared.hash(into: &hasher)
    AgeRangeService.AgeRangeDeclaration.guardianDeclared.hash(into: &hasher)
    _ = hasher.finalize()
}

func testAgeRangeDeclarationHashValue() {
    let selfDeclared = AgeRangeService.AgeRangeDeclaration.selfDeclared.hashValue
    precondition(selfDeclared == AgeRangeService.AgeRangeDeclaration.selfDeclared.hashValue)
    let guardian = AgeRangeService.AgeRangeDeclaration.guardianDeclared.hashValue
    precondition(guardian == AgeRangeService.AgeRangeDeclaration.guardianDeclared.hashValue)
}
