@_spi(OpenUIKitHost) import ActivityKit
import Dispatch
import Foundation

func testActivityStateCases() {
    let cases: [ActivityState] = [.pending, .active, .ended, .dismissed, .stale]
    activityKitRequire(Set(cases).count == 5, "five states")
}

func testActivityStateHashable() {
    activityKitRequire(ActivityState.active == .active, "equal")
    activityKitRequire(ActivityState.pending != .stale, "unequal")
    var hasher = Hasher()
    ActivityState.ended.hash(into: &hasher)
    activityKitRequire(ActivityState.ended.hashValue == ActivityState.ended.hashValue, "hash")
}

func testActivityStateCodable() {
    do {
        let encoded = try JSONEncoder().encode(ActivityState.active)
        let decoded = try JSONDecoder().decode(ActivityState.self, from: encoded)
        activityKitRequire(decoded == .active, "round-trip")
        let reencoded = try JSONEncoder().encode(decoded)
        let roundTripped = try JSONDecoder().decode(ActivityState.self, from: reencoded)
        activityKitRequire(roundTripped == .active, "encode(to:) round-trip")
    } catch {
        fatalError("ActivityState Codable failed: \(error)")
    }
}
