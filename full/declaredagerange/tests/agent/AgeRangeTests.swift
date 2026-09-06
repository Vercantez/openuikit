import Foundation
import DeclaredAgeRange

func testAgeRangeType() {
    let range = AgeRangeService.AgeRange()
    precondition(type(of: range) == AgeRangeService.AgeRange.self)
}

func testAgeRangeLowerBound() {
    var range = AgeRangeService.AgeRange()
    precondition(range.lowerBound == nil)
    range.lowerBound = 13
    precondition(range.lowerBound == 13)
    range.lowerBound = nil
    precondition(range.lowerBound == nil)
}

func testAgeRangeUpperBound() {
    var range = AgeRangeService.AgeRange(lowerBound: 18, upperBound: nil)
    precondition(range.upperBound == nil)
    range.upperBound = 17
    precondition(range.upperBound == 17)
    range.upperBound = nil
    precondition(range.upperBound == nil)
}

func testAgeRangeDeclarationProperty() {
    var range = AgeRangeService.AgeRange()
    precondition(range.ageRangeDeclaration == nil)
    range.ageRangeDeclaration = .selfDeclared
    precondition(range.ageRangeDeclaration == .selfDeclared)
    range.ageRangeDeclaration = .guardianDeclared
    precondition(range.ageRangeDeclaration == .guardianDeclared)
    range.ageRangeDeclaration = nil
    precondition(range.ageRangeDeclaration == nil)
}

func testAgeRangeActiveParentalControls() {
    var range = AgeRangeService.AgeRange()
    precondition(range.activeParentalControls.isEmpty)
    range.activeParentalControls = .communicationLimits
    precondition(range.activeParentalControls.contains(.communicationLimits))
    range.activeParentalControls = []
    precondition(range.activeParentalControls.isEmpty)
}
