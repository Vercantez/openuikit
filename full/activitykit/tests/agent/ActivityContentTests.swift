@_spi(OpenUIKitHost) import ActivityKit
import Dispatch
import Foundation

func testActivityContentInit() {
    let content = ActivityContent(
        state: ProbeAttributes.ContentState(message: "idle", progress: 0),
        staleDate: nil,
        relevanceScore: 1.5
    )
    activityKitRequire(content.relevanceScore == 1.5, "score from init")
}

func testActivityContentState() {
    let state = ProbeAttributes.ContentState(message: "idle", progress: 3)
    let content = ActivityContent(state: state, staleDate: nil, relevanceScore: 0)
    activityKitRequire(content.state == state, "state")
}

func testActivityContentStaleDate() {
    let date = Date(timeIntervalSince1970: 10)
    let content = ActivityContent(
        state: ProbeAttributes.ContentState(message: "old", progress: 0),
        staleDate: date,
        relevanceScore: 0
    )
    activityKitRequire(content.staleDate == date, "staleDate")
}

func testActivityContentRelevanceScore() {
    let content = ActivityContent(
        state: ProbeAttributes.ContentState(message: "idle", progress: 0),
        staleDate: nil,
        relevanceScore: 2.25
    )
    activityKitRequire(content.relevanceScore == 2.25, "relevanceScore")
}

func testActivityContentDescription() {
    let content = ActivityContent(
        state: ProbeAttributes.ContentState(message: "idle", progress: 0),
        staleDate: nil,
        relevanceScore: 1.5
    )
    activityKitRequire(content.description.contains("1.5"), "description")
}
