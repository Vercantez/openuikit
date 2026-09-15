@_spi(OpenUIKitHost) import ActivityKit
import Dispatch
import Foundation

struct ActivityTerminalProbeError: Error {}

func testActivityUpdatesMaxBy() {
    activityKitReset()
    _ = try! activityKitRequest("tmax-a")
    _ = try! activityKitRequest("tmax-b")
    activityKitRunAsync {
        do {
            _ = try await Activity<ProbeAttributes>.activityUpdates.max(by: { _, _ -> Bool in
                throw ActivityTerminalProbeError()
            })
            fatalError("max should throw")
        } catch is ActivityTerminalProbeError {
        }
    }
}

func testActivityUpdatesMinBy() {
    activityKitReset()
    _ = try! activityKitRequest("tmin-a")
    _ = try! activityKitRequest("tmin-b")
    activityKitRunAsync {
        do {
            _ = try await Activity<ProbeAttributes>.activityUpdates.min(by: { _, _ -> Bool in
                throw ActivityTerminalProbeError()
            })
            fatalError("min should throw")
        } catch is ActivityTerminalProbeError {
        }
    }
}

func testActivityUpdatesReduce() {
    activityKitReset()
    _ = try! activityKitRequest("tred-updates")
    activityKitRunAsync {
        do {
            _ = try await Activity<ProbeAttributes>.activityUpdates.reduce(0) { _, _ -> Int in
                throw ActivityTerminalProbeError()
            }
            fatalError("reduce should throw")
        } catch is ActivityTerminalProbeError {
        }
    }
}

func testActivityUpdatesReduceInto() {
    activityKitReset()
    _ = try! activityKitRequest("tredi-updates")
    activityKitRunAsync {
        do {
            _ = try await Activity<ProbeAttributes>.activityUpdates.reduce(into: 0) { _, _ in
                throw ActivityTerminalProbeError()
            }
            fatalError("reduce into should throw")
        } catch is ActivityTerminalProbeError {
        }
    }
}

func testActivityStateUpdatesMaxBy() {
    activityKitReset()
    let activity = try! activityKitRequest("tmax-state")
    activityKitRunAsync {
        await activity.end(nil, dismissalPolicy: .immediate)
        do {
            _ = try await activity.activityStateUpdates.max(by: { _, _ -> Bool in
                throw ActivityTerminalProbeError()
            })
            fatalError("max should throw")
        } catch is ActivityTerminalProbeError {
        }
    }
}

func testActivityStateUpdatesMinBy() {
    activityKitReset()
    let activity = try! activityKitRequest("tmin-state")
    activityKitRunAsync {
        await activity.end(nil, dismissalPolicy: .immediate)
        do {
            _ = try await activity.activityStateUpdates.min(by: { _, _ -> Bool in
                throw ActivityTerminalProbeError()
            })
            fatalError("min should throw")
        } catch is ActivityTerminalProbeError {
        }
    }
}

func testActivityStateUpdatesReduce() {
    activityKitReset()
    let activity = try! activityKitRequest("tred-state")
    activityKitRunAsync {
        do {
            _ = try await activity.activityStateUpdates.reduce(0) { _, _ -> Int in
                throw ActivityTerminalProbeError()
            }
            fatalError("reduce should throw")
        } catch is ActivityTerminalProbeError {
        }
    }
}

func testActivityStateUpdatesReduceInto() {
    activityKitReset()
    let activity = try! activityKitRequest("tredi-state")
    activityKitRunAsync {
        do {
            _ = try await activity.activityStateUpdates.reduce(into: 0) { _, _ in
                throw ActivityTerminalProbeError()
            }
            fatalError("reduce into should throw")
        } catch is ActivityTerminalProbeError {
        }
    }
}

func testContentUpdatesMaxBy() {
    activityKitReset()
    let activity = try! activityKitRequest("tmax-content", content: activityKitContent("idle", progress: 0))
    activityKitRunAsync {
        await activity.update(using: ProbeAttributes.ContentState(message: "running", progress: 1))
        do {
            _ = try await activity.contentUpdates.max(by: { _, _ -> Bool in
                throw ActivityTerminalProbeError()
            })
            fatalError("max should throw")
        } catch is ActivityTerminalProbeError {
        }
    }
}

func testContentUpdatesMinBy() {
    activityKitReset()
    let activity = try! activityKitRequest("tmin-content", content: activityKitContent("idle", progress: 0))
    activityKitRunAsync {
        await activity.update(using: ProbeAttributes.ContentState(message: "running", progress: 1))
        do {
            _ = try await activity.contentUpdates.min(by: { _, _ -> Bool in
                throw ActivityTerminalProbeError()
            })
            fatalError("min should throw")
        } catch is ActivityTerminalProbeError {
        }
    }
}

func testContentUpdatesReduce() {
    activityKitReset()
    let activity = try! activityKitRequest("tred-content", content: activityKitContent("idle", progress: 0))
    activityKitRunAsync {
        do {
            _ = try await activity.contentUpdates.reduce(0) { _, _ -> Int in
                throw ActivityTerminalProbeError()
            }
            fatalError("reduce should throw")
        } catch is ActivityTerminalProbeError {
        }
    }
}

func testContentUpdatesReduceInto() {
    activityKitReset()
    let activity = try! activityKitRequest("tredi-content", content: activityKitContent("idle", progress: 0))
    activityKitRunAsync {
        do {
            _ = try await activity.contentUpdates.reduce(into: 0) { _, _ in
                throw ActivityTerminalProbeError()
            }
            fatalError("reduce into should throw")
        } catch is ActivityTerminalProbeError {
        }
    }
}

func testContentStateUpdatesMaxBy() {
    activityKitReset()
    let activity = try! activityKitRequest("tmax-cstate", content: activityKitContent("idle", progress: 0))
    activityKitRunAsync {
        await activity.update(using: ProbeAttributes.ContentState(message: "running", progress: 1))
        do {
            _ = try await activity.contentStateUpdates.max(by: { _, _ -> Bool in
                throw ActivityTerminalProbeError()
            })
            fatalError("max should throw")
        } catch is ActivityTerminalProbeError {
        }
    }
}

func testContentStateUpdatesMinBy() {
    activityKitReset()
    let activity = try! activityKitRequest("tmin-cstate", content: activityKitContent("idle", progress: 0))
    activityKitRunAsync {
        await activity.update(using: ProbeAttributes.ContentState(message: "running", progress: 1))
        do {
            _ = try await activity.contentStateUpdates.min(by: { _, _ -> Bool in
                throw ActivityTerminalProbeError()
            })
            fatalError("min should throw")
        } catch is ActivityTerminalProbeError {
        }
    }
}

func testContentStateUpdatesReduce() {
    activityKitReset()
    let activity = try! activityKitRequest("tred-cstate", content: activityKitContent("idle", progress: 0))
    activityKitRunAsync {
        do {
            _ = try await activity.contentStateUpdates.reduce(0) { _, _ -> Int in
                throw ActivityTerminalProbeError()
            }
            fatalError("reduce should throw")
        } catch is ActivityTerminalProbeError {
        }
    }
}

func testContentStateUpdatesReduceInto() {
    activityKitReset()
    let activity = try! activityKitRequest("tredi-cstate", content: activityKitContent("idle", progress: 0))
    activityKitRunAsync {
        do {
            _ = try await activity.contentStateUpdates.reduce(into: 0) { _, _ in
                throw ActivityTerminalProbeError()
            }
            fatalError("reduce into should throw")
        } catch is ActivityTerminalProbeError {
        }
    }
}

func testActivityEnablementUpdatesReduce() {
    activityKitReset()
    activityKitRunAsync {
        let info = ActivityAuthorizationInfo()
        do {
            _ = try await info.activityEnablementUpdates.reduce(0) { _, _ -> Int in
                throw ActivityTerminalProbeError()
            }
            fatalError("reduce should throw")
        } catch is ActivityTerminalProbeError {
        }
    }
}

func testActivityEnablementUpdatesReduceInto() {
    activityKitReset()
    activityKitRunAsync {
        let info = ActivityAuthorizationInfo()
        do {
            _ = try await info.activityEnablementUpdates.reduce(into: 0) { _, _ in
                throw ActivityTerminalProbeError()
            }
            fatalError("reduce into should throw")
        } catch is ActivityTerminalProbeError {
        }
    }
}

func testFrequentPushEnablementUpdatesReduce() {
    activityKitReset()
    activityKitRunAsync {
        let info = ActivityAuthorizationInfo()
        do {
            _ = try await info.frequentPushEnablementUpdates.reduce(0) { _, _ -> Int in
                throw ActivityTerminalProbeError()
            }
            fatalError("reduce should throw")
        } catch is ActivityTerminalProbeError {
        }
    }
}

func testFrequentPushEnablementUpdatesReduceInto() {
    activityKitReset()
    activityKitRunAsync {
        let info = ActivityAuthorizationInfo()
        do {
            _ = try await info.frequentPushEnablementUpdates.reduce(into: 0) { _, _ in
                throw ActivityTerminalProbeError()
            }
            fatalError("reduce into should throw")
        } catch is ActivityTerminalProbeError {
        }
    }
}
