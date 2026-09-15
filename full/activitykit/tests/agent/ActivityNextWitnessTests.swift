@_spi(OpenUIKitHost) import ActivityKit
import Dispatch
import Foundation

func testActivityEnablementUpdatesNextWitness() {
    activityKitReset()
    activityKitRunAsync {
        let info = ActivityAuthorizationInfo()
        var iterator: any AsyncIteratorProtocol = info.activityEnablementUpdates.makeAsyncIterator()
        let first = try await iterator.next() as? Bool
        activityKitRequire(first == true, "next() witness replay")
    }
}

func testFrequentPushEnablementUpdatesNextWitness() {
    activityKitReset()
    activityKitRunAsync {
        let info = ActivityAuthorizationInfo()
        var iterator: any AsyncIteratorProtocol = info.frequentPushEnablementUpdates.makeAsyncIterator()
        let first = try await iterator.next() as? Bool
        activityKitRequire(first == false, "next() witness replay")
    }
}
