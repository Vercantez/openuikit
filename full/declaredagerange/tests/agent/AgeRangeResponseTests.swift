import Foundation
import DeclaredAgeRange

func testResponseType() {
    let response: AgeRangeService.Response = .declinedSharing
    precondition(type(of: response) == AgeRangeService.Response.self)
}

func testResponseCases() {
    let declined = AgeRangeService.Response.declinedSharing
    let range = AgeRangeService.AgeRange(
        lowerBound: 13,
        upperBound: 17,
        ageRangeDeclaration: .guardianDeclared,
        activeParentalControls: .communicationLimits
    )
    let sharing = AgeRangeService.Response.sharing(range: range)
    switch declined {
    case .declinedSharing:
        break
    case .sharing:
        preconditionFailure("declinedSharing mismatch")
    }
    switch sharing {
    case .sharing(let shared):
        precondition(shared.lowerBound == 13)
        precondition(shared.upperBound == 17)
        precondition(shared.ageRangeDeclaration == .guardianDeclared)
        precondition(shared.activeParentalControls.contains(.communicationLimits))
    case .declinedSharing:
        preconditionFailure("sharing mismatch")
    }
}
