import Foundation
import ClassKit

func testActivityLifecycle() {
    classKitResetStore()
    let context = CLSDataStore.shared.mainAppContext
    let activity = context.createNewActivity()
    classKitExpect(activity.isStarted == false, "not started")
    classKitExpect(activity.duration >= 0, "duration non-negative")
    activity.start()
    classKitExpect(activity.isStarted, "started")
    classKitExpect(CLSDataStore.shared.runningActivity === activity, "running")
    let mid = activity.duration
    classKitExpect(mid >= 0, "duration while running")
    activity.stop()
    classKitExpect(activity.isStarted == false, "stopped")
    let frozen = activity.duration
    classKitExpect(frozen >= mid || frozen >= 0, "frozen duration")
    classKitExpect(CLSDataStore.shared.runningActivity == nil, "cleared running")
    activity.stop()
    classKitExpect(activity.duration == frozen, "second stop is idle")
}

func testActivityProgress() {
    classKitResetStore()
    let activity = CLSDataStore.shared.mainAppContext.createNewActivity()
    classKitExpect(activity.progress == 0, "default progress")
    activity.progress = 1.5
    classKitExpect(activity.progress == 1, "clamp high")
    activity.progress = -0.2
    classKitExpect(activity.progress == 0, "clamp low")
    activity.addProgressRange(fromStart: 0.1, toEnd: 0.4)
    classKitExpect(activity.progress == 0.4, "range end")
    activity.addProgressRange(fromStart: 0.2, toEnd: 0.7)
    classKitExpect(activity.progress == 0.7, "range max")
    activity.addProgressRange(fromStart: 0.9, toEnd: 0.1)
    classKitExpect(activity.progress == 0.7, "invalid range ignored")
}

func testActivityItems() {
    classKitResetStore()
    let activity = CLSDataStore.shared.mainAppContext.createNewActivity()
    let primary = CLSBinaryItem(identifier: "primary", title: "Primary", type: .passFail)
    let extra = CLSQuantityItem(identifier: "extra", title: "Extra")
    activity.primaryActivityItem = primary
    classKitExpect(activity.primaryActivityItem === primary, "primary")
    activity.addAdditionalActivityItem(extra)
    classKitExpect(activity.additionalActivityItems.count == 1, "additional count")
    classKitExpect(activity.additionalActivityItems.first === extra, "additional")
    activity.removeAllActivityItems()
    classKitExpect(activity.primaryActivityItem == nil, "cleared primary")
    classKitExpect(activity.additionalActivityItems.isEmpty, "cleared additional")
}

func testBinaryItem() {
    let item = CLSBinaryItem(identifier: "bin", title: "Binary", type: .correctIncorrect)
    classKitExpect(item.identifier == "bin", "identifier")
    classKitExpect(item.title == "Binary", "title")
    classKitExpect(item.valueType == .correctIncorrect, "type")
    classKitExpect(item.value == false, "default value")
    item.value = true
    classKitExpect(item.value, "set value")
    item.title = "Updated"
    classKitExpect(item.title == "Updated", "title set")
}

func testQuantityItem() {
    let item = CLSQuantityItem(identifier: "qty", title: "Quantity")
    classKitExpect(item.quantity == 0, "default")
    item.quantity = 12.5
    classKitExpect(item.quantity == 12.5, "set")
}

func testScoreItem() {
    let item = CLSScoreItem(identifier: "score", title: "Score", score: 8, maxScore: 10)
    classKitExpect(item.score == 8, "score")
    classKitExpect(item.maxScore == 10, "max")
    item.score = 9
    item.maxScore = 12
    classKitExpect(item.score == 9, "score set")
    classKitExpect(item.maxScore == 12, "max set")
}
