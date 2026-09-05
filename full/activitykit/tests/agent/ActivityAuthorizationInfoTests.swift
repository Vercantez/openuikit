@_spi(OpenUIKitHost) import ActivityKit
import Dispatch
import Foundation

func testAuthorizationInfoInit() {
    activityKitReset()
    let info = ActivityAuthorizationInfo()
    activityKitRequire(info.areActivitiesEnabled, "default enabled after init")
}

func testAuthorizationInfoAreActivitiesEnabled() {
    activityKitReset()
    OpenUIKitActivityKitTesting.setAreActivitiesEnabled(false)
    activityKitRequire(
        ActivityAuthorizationInfo().areActivitiesEnabled == false,
        "stored disabled"
    )
    OpenUIKitActivityKitTesting.setAreActivitiesEnabled(true)
    activityKitRequire(ActivityAuthorizationInfo().areActivitiesEnabled, "stored enabled")
}

func testAuthorizationInfoFrequentPushesEnabled() {
    activityKitReset()
    activityKitRequire(
        ActivityAuthorizationInfo().frequentPushesEnabled == false,
        "frequent default"
    )
    OpenUIKitActivityKitTesting.setFrequentPushesEnabled(true)
    activityKitRequire(ActivityAuthorizationInfo().frequentPushesEnabled, "frequent enabled")
}

func testActivityEnablementUpdatesProperty() {
    activityKitReset()
    let info = ActivityAuthorizationInfo()
    activityKitRunAsync {
        var iterator = info.activityEnablementUpdates.makeAsyncIterator()
        let first = await iterator.next()
        activityKitRequire(first == true, "enablement replay")
        OpenUIKitActivityKitTesting.setAreActivitiesEnabled(false)
        let second = await iterator.next()
        activityKitRequire(second == false, "enablement in order")
    }
}

func testFrequentPushEnablementUpdatesProperty() {
    activityKitReset()
    let info = ActivityAuthorizationInfo()
    activityKitRunAsync {
        var iterator = info.frequentPushEnablementUpdates.makeAsyncIterator()
        let first = await iterator.next()
        activityKitRequire(first == false, "frequent replay")
        OpenUIKitActivityKitTesting.setFrequentPushesEnabled(true)
        let second = await iterator.next()
        activityKitRequire(second == true, "frequent in order")
    }
}
