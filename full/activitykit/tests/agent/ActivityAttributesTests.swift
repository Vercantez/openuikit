@_spi(OpenUIKitHost) import ActivityKit
import Dispatch
import Foundation

func testActivityAttributesJSONRoundTrip() {
    let attributes = ProbeAttributes(label: "probe")
    do {
        let encoded = try JSONEncoder().encode(attributes)
        let decoded = try JSONDecoder().decode(ProbeAttributes.self, from: encoded)
        activityKitRequire(decoded == attributes, "attributes JSON")
    } catch {
        fatalError("attributes JSON failed: \(error)")
    }
}

func testActivityContentStateJSONRoundTrip() {
    let state = ProbeAttributes.ContentState(message: "idle", progress: 4)
    do {
        let encoded = try JSONEncoder().encode(state)
        let decoded = try JSONDecoder().decode(ProbeAttributes.ContentState.self, from: encoded)
        activityKitRequire(decoded == state, "contentState JSON")
    } catch {
        fatalError("contentState JSON failed: \(error)")
    }
}

func testActivityContentStateAlias() {
    activityKitRequire(
        Activity<ProbeAttributes>.ContentState.self == ProbeAttributes.ContentState.self,
        "ContentState alias"
    )
}
