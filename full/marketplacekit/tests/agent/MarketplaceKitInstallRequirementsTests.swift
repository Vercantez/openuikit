import Foundation
import MarketplaceKit

func testInstallRequirementsDefaults() {
    let empty = InstallRequirements()
    precondition(empty.minimumSystemVersion == nil)
    precondition(empty.requiredDeviceCapabilities == nil)
    precondition(empty.ageRatingRank == nil)
    precondition(empty.expectedInstallSize == nil)
    precondition(empty.satisfiedByDevice())
}

func testInstallRequirementsCapabilitiesFailClosed() {
    var requirements = InstallRequirements()
    requirements.requiredDeviceCapabilities = ["arm64", "metal"]
    precondition(!requirements.satisfiedByDevice())
    requirements.requiredDeviceCapabilities = []
    requirements.minimumSystemVersion = nil
    requirements.ageRatingRank = nil
    requirements.expectedInstallSize = nil
    precondition(requirements.satisfiedByDevice())
}

func testInstallRequirementsMinimumVersionFailClosed() {
    var requirements = InstallRequirements()
    requirements.minimumSystemVersion = "26.0"
    precondition(!requirements.satisfiedByDevice())
}

func testInstallRequirementsAgeRatingFailClosed() {
    var requirements = InstallRequirements()
    requirements.ageRatingRank = 12
    precondition(!requirements.satisfiedByDevice())
}

func testInstallRequirementsExpectedSize() {
    var tiny = InstallRequirements()
    tiny.expectedInstallSize = 1
    precondition(tiny.satisfiedByDevice())
    var huge = InstallRequirements()
    huge.expectedInstallSize = UInt64.max
    precondition(!huge.satisfiedByDevice())
}

func testInstallRequirementsCodableRoundTrip() {
    var requirements = InstallRequirements()
    requirements.minimumSystemVersion = "17.4"
    requirements.requiredDeviceCapabilities = ["opengles-2"]
    requirements.ageRatingRank = 4
    requirements.expectedInstallSize = 4096
    let decoded = marketplaceKitJSONRoundTrip(requirements)
    precondition(decoded.minimumSystemVersion == "17.4")
    precondition(decoded.requiredDeviceCapabilities == ["opengles-2"])
    precondition(decoded.ageRatingRank == 4)
    precondition(decoded.expectedInstallSize == 4096)
    precondition(!decoded.satisfiedByDevice())
}
