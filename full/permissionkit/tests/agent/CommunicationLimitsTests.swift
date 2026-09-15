import Foundation
import PermissionKit

func testCommunicationLimitsCurrentSingleton() {
    precondition(CommunicationLimits.current === CommunicationLimits.current)
}

func testCommunicationLimitsCurrentType() {
    let limits: CommunicationLimits = .current
    precondition(type(of: limits) == CommunicationLimits.self)
}

func testCommunicationLimitsUpdatesStreamType() {
    let updates: AsyncStream<PermissionResponse<CommunicationTopic>> = CommunicationLimits.current.updates
    precondition(type(of: updates) == AsyncStream<PermissionResponse<CommunicationTopic>>.self)
}
