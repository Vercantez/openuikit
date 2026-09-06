import Foundation
import PermissionKit

func testCommunicationLimitsCurrentSingleton() {
    precondition(CommunicationLimits.current === CommunicationLimits.current)
}

func testCommunicationLimitsCurrentType() {
    let limits: CommunicationLimits = .current
    precondition(type(of: limits) == CommunicationLimits.self)
}
