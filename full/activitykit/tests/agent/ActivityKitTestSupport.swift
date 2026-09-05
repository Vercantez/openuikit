@_spi(OpenUIKitHost) import ActivityKit
import Dispatch
import Foundation

struct ProbeAttributes: ActivityAttributes, Equatable, Sendable {
    struct ContentState: Codable, Hashable, Sendable {
        var message: String
        var progress: Int
    }

    var label: String
}

final class ActivityKitErrorBox: @unchecked Sendable {
    var value: Error?
}

func activityKitRequire(_ value: Bool, _ message: String) {
    if !value {
        fatalError(message)
    }
}

func activityKitRunAsync(_ body: @escaping @Sendable () async throws -> Void) {
    let semaphore = DispatchSemaphore(value: 0)
    let box = ActivityKitErrorBox()
    Task {
        do {
            try await body()
        } catch {
            box.value = error
        }
        semaphore.signal()
    }
    if semaphore.wait(timeout: .now() + .seconds(8)) != .success {
        fatalError("async timeout")
    }
    if let error = box.value {
        fatalError("async error: \(error)")
    }
}

func activityKitReset() {
    OpenUIKitActivityKitTesting.reset()
}

func activityKitContent(
    _ message: String = "idle",
    progress: Int = 0,
    staleDate: Date? = nil,
    relevanceScore: Double = 0
) -> ActivityContent<ProbeAttributes.ContentState> {
    ActivityContent(
        state: ProbeAttributes.ContentState(message: message, progress: progress),
        staleDate: staleDate,
        relevanceScore: relevanceScore
    )
}

func activityKitRequest(
    _ label: String,
    content: ActivityContent<ProbeAttributes.ContentState>? = nil,
    pushType: PushType? = nil,
    style: ActivityStyle? = nil
) throws -> Activity<ProbeAttributes> {
    let resolved = content ?? activityKitContent()
    if let style {
        return try Activity.request(
            attributes: ProbeAttributes(label: label),
            content: resolved,
            pushType: pushType,
            style: style
        )
    }
    return try Activity.request(
        attributes: ProbeAttributes(label: label),
        content: resolved,
        pushType: pushType
    )
}

func activityKitExpectError(
    _ expected: ActivityAuthorizationError,
    _ body: () throws -> Void
) {
    do {
        try body()
        fatalError("expected \(expected)")
    } catch let error as ActivityAuthorizationError {
        activityKitRequire(error == expected, "expected \(expected) got \(error)")
        activityKitRequire(error.errorCode == expected.errorCode, "errorCode")
        activityKitRequire(error.failureReason != nil, "failureReason")
    } catch {
        fatalError("expected ActivityAuthorizationError, got \(error)")
    }
}
