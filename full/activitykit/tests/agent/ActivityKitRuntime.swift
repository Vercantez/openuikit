@_spi(OpenUIKitHost) import ActivityKit
import Foundation

private struct ProbeAttributes: ActivityAttributes, Equatable {
    struct ContentState: Codable, Hashable {
        var message: String
        var progress: Int
    }

    var label: String
}

private func requireTrue(_ value: Bool, _ message: String) {
    if !value {
        fatalError(message)
    }
}

private func requireError(
    _ expected: ActivityAuthorizationError,
    _ body: () throws -> Void
) {
    do {
        try body()
        fatalError("expected \(expected)")
    } catch let error as ActivityAuthorizationError {
        requireTrue(error == expected, "expected \(expected) got \(error)")
        requireTrue(error.errorCode == expected.errorCode, "errorCode")
        requireTrue(error.failureReason != nil, "failureReason")
        requireTrue(error.errorDescription == error.failureReason, "errorDescription")
    } catch {
        fatalError("expected ActivityAuthorizationError, got \(error)")
    }
}

private func collectPrefix<S: AsyncSequence>(
    _ sequence: S,
    _ limit: Int
) async rethrows -> [S.Element] {
    var values: [S.Element] = []
    for try await value in sequence.prefix(limit) {
        values.append(value)
    }
    return values
}

private func exerciseAsyncSequence<S: AsyncSequence>(_ sequence: S) async throws {
    var prefixCount = 0
    for try await _ in sequence.prefix(1) { prefixCount += 1 }
    _ = prefixCount

    var dropCount = 0
    for try await _ in sequence.dropFirst().prefix(0) { dropCount += 1 }
    _ = dropCount

    var dropWhileCount = 0
    for try await _ in sequence.drop(while: { _ in false }).prefix(1) { dropWhileCount += 1 }
    _ = dropWhileCount

    var prefixWhileCount = 0
    for try await _ in try sequence.prefix(while: { _ in true }).prefix(1) {
        prefixWhileCount += 1
    }
    _ = prefixWhileCount

    var filterCount = 0
    for try await _ in sequence.filter({ _ in true }).prefix(1) { filterCount += 1 }
    _ = filterCount

    var mapCount = 0
    for try await _ in sequence.map({ _ in 1 }).prefix(1) { mapCount += 1 }
    _ = mapCount

    var throwingMapCount = 0
    for try await _ in sequence.map({ _ throws in 1 }).prefix(1) { throwingMapCount += 1 }
    _ = throwingMapCount

    var compactCount = 0
    for try await _ in sequence.compactMap({ _ in 1 }).prefix(1) { compactCount += 1 }
    _ = compactCount

    var throwingCompactCount = 0
    for try await _ in sequence.compactMap({ _ throws -> Int? in 1 }).prefix(1) {
        throwingCompactCount += 1
    }
    _ = throwingCompactCount

    _ = try await sequence.prefix(1).contains(where: { _ in true })
    _ = try await sequence.prefix(1).contains(where: { _ in false })
    _ = try await sequence.prefix(1).allSatisfy { _ in true }
    _ = try await sequence.prefix(1).first(where: { _ in true })
    _ = try await sequence.prefix(1).reduce(0) { count, _ in count + 1 }
    _ = try await sequence.prefix(1).reduce(into: 0) { count, _ in count += 1 }
    _ = try await sequence.prefix(1).max(by: { _, _ in false })
    _ = try await sequence.prefix(1).min(by: { _, _ in false })

    var nestedCount = 0
    for try await _ in sequence.flatMap({ _ in sequence.prefix(1) }).prefix(1) {
        nestedCount += 1
    }
    _ = nestedCount

    var throwingNested = 0
    for try await _ in sequence.flatMap({ _ async throws in sequence.prefix(1) }).prefix(1) {
        throwingNested += 1
    }
    _ = throwingNested
}

enum ActivityKitRuntime {
    static func main() async {
        OpenUIKitActivityKitTesting.reset()

        requireTrue(Activity<ProbeAttributes>.ID.self == String.self, "ID alias")
        requireTrue(Activity<ProbeAttributes>.activities.isEmpty, "activities start empty")
        requireTrue(Activity<ProbeAttributes>.pushToStartToken == nil, "pushToStartToken")

        var pushToStart: [Data] = []
        for await token in Activity<ProbeAttributes>.pushToStartTokenUpdates {
            pushToStart.append(token)
        }
        requireTrue(pushToStart.isEmpty, "push-to-start sequence empty")

        exerciseAuthorization()
        await exerciseEnablementSequences()
        await exerciseRequestAndUpdates()
        await exerciseDismissalAndStale()
        await exerciseLimitsAndErrors()
        await exercisePushTokenHook()
        await exerciseSequenceHelpers()
        exerciseValueTypes()

        OpenUIKitActivityKitTesting.reset()
        print("ACTIVITYKIT_AGENT_RUNTIME_OK")
    }

    private static func exerciseAuthorization() {
        OpenUIKitActivityKitTesting.reset()
        let info = ActivityAuthorizationInfo()
        requireTrue(info.areActivitiesEnabled, "default enabled")
        requireTrue(info.frequentPushesEnabled == false, "frequent default")

        OpenUIKitActivityKitTesting.setAreActivitiesEnabled(false)
        requireTrue(ActivityAuthorizationInfo().areActivitiesEnabled == false, "stored disabled")
        OpenUIKitActivityKitTesting.setAreActivitiesEnabled(true)
        requireTrue(ActivityAuthorizationInfo().areActivitiesEnabled, "stored enabled")

        OpenUIKitActivityKitTesting.setFrequentPushesEnabled(true)
        requireTrue(ActivityAuthorizationInfo().frequentPushesEnabled, "frequent enabled")
        OpenUIKitActivityKitTesting.setFrequentPushesEnabled(false)
        requireTrue(ActivityAuthorizationInfo().frequentPushesEnabled == false, "frequent disabled")
    }

    private static func exerciseEnablementSequences() async {
        OpenUIKitActivityKitTesting.reset()
        let info = ActivityAuthorizationInfo()

        var enablementIterator = info.activityEnablementUpdates.makeAsyncIterator()
        let firstEnablement = await enablementIterator.next()
        requireTrue(firstEnablement == true, "enablement replay")
        OpenUIKitActivityKitTesting.setAreActivitiesEnabled(false)
        let secondEnablement = await enablementIterator.next()
        requireTrue(
            [firstEnablement, secondEnablement] == [true, false],
            "enablement in order"
        )

        var frequentIterator = info.frequentPushEnablementUpdates.makeAsyncIterator()
        let firstFrequent = await frequentIterator.next()
        requireTrue(firstFrequent == false, "frequent replay")
        OpenUIKitActivityKitTesting.setFrequentPushesEnabled(true)
        let secondFrequent = await frequentIterator.next()
        requireTrue(
            [firstFrequent, secondFrequent] == [false, true],
            "frequent in order"
        )

        try! await exerciseAsyncSequence(info.activityEnablementUpdates)
        try! await exerciseAsyncSequence(info.frequentPushEnablementUpdates)

        let containsFalse = await info.activityEnablementUpdates.prefix(1).contains(false)
        requireTrue(containsFalse, "contains false")
        let mapped = info.activityEnablementUpdates.map { $0 ? 1 : 0 }
        let mappedValues = await collectPrefix(mapped, 1)
        requireTrue(mappedValues == [0] || mappedValues == [1], "mapped enablement")
    }

    private static func exerciseRequestAndUpdates() async {
        OpenUIKitActivityKitTesting.reset()
        let start = Date(timeIntervalSince1970: 1_700_000_000)
        OpenUIKitActivityKitTesting.setNow(start)

        let attributes = ProbeAttributes(label: "probe")
        let contentState = ProbeAttributes.ContentState(message: "idle", progress: 0)
        let content = ActivityContent(
            state: contentState,
            staleDate: nil,
            relevanceScore: 1.5
        )

        let encoded = try! JSONEncoder().encode(attributes)
        let decoded = try! JSONDecoder().decode(ProbeAttributes.self, from: encoded)
        requireTrue(decoded == attributes, "attributes JSON round trip")
        let encodedState = try! JSONEncoder().encode(contentState)
        let decodedState = try! JSONDecoder().decode(
            ProbeAttributes.ContentState.self,
            from: encodedState
        )
        requireTrue(decodedState == contentState, "contentState JSON round trip")

        let activity = try! Activity.request(
            attributes: attributes,
            content: content,
            pushType: .token
        )
        requireTrue(activity.attributes.label == "probe", "attributes")
        requireTrue(activity.contentState.message == "idle", "contentState")
        requireTrue(activity.content.relevanceScore == 1.5, "relevance")
        requireTrue(activity.activityState == .active, "active")
        requireTrue(activity.pushToken == nil, "pushToken nil")
        requireTrue(!activity.id.isEmpty, "id")
        requireTrue(Activity<ProbeAttributes>.activities.map(\.id) == [activity.id], "list")

        let replayed = await collectPrefix(Activity<ProbeAttributes>.activityUpdates, 1)
        requireTrue(replayed.map(\.id) == [activity.id], "activityUpdates replay")

        let states = await collectPrefix(activity.activityStateUpdates, 1)
        requireTrue(states == [.active], "state replay")
        let contents = await collectPrefix(activity.contentUpdates, 1)
        requireTrue(contents.first?.state.progress == 0, "content replay")
        let contentStates = await collectPrefix(activity.contentStateUpdates, 1)
        requireTrue(contentStates.first?.message == "idle", "contentState replay")

        let next = ProbeAttributes.ContentState(message: "running", progress: 40)
        let contentIterator = activity.contentUpdates.makeAsyncIterator()
        let contentStateIterator = activity.contentStateUpdates.makeAsyncIterator()
        let firstContent = await contentIterator.next()
        let firstState = await contentStateIterator.next()
        requireTrue(firstContent?.state.progress == 0, "content replay")
        requireTrue(firstState?.message == "idle", "contentState replay")
        await activity.update(
            ActivityContent(state: next, staleDate: nil, relevanceScore: 2)
        )
        let secondContent = await contentIterator.next()
        let secondState = await contentStateIterator.next()
        requireTrue(
            [firstContent?.state.progress, secondContent?.state.progress] == [0, 40],
            "contentUpdates order"
        )
        requireTrue(
            [firstState?.message, secondState?.message] == ["idle", "running"],
            "contentStateUpdates order"
        )
        requireTrue(activity.contentState.progress == 40, "updated state")
        requireTrue(activity.content.relevanceScore == 2, "updated score")

        await activity.update(using: ProbeAttributes.ContentState(message: "using", progress: 41))
        requireTrue(activity.contentState.message == "using", "update(using:)")

        let withStyle = try! Activity.request(
            attributes: ProbeAttributes(label: "styled"),
            content: content,
            style: .transient
        )
        requireTrue(withStyle.activityState == .active, "style request")

        let fromState = try! Activity.request(
            attributes: ProbeAttributes(label: "state-only"),
            contentState: contentState
        )
        requireTrue(fromState.content.staleDate == nil, "contentState request")
        requireTrue(Activity<ProbeAttributes>.activities.count == 3, "three activities")
    }

    private static func exerciseDismissalAndStale() async {
        OpenUIKitActivityKitTesting.reset()
        let start = Date(timeIntervalSince1970: 1_800_000_000)
        OpenUIKitActivityKitTesting.setNow(start)
        let attributes = ProbeAttributes(label: "clock")
        let content = ActivityContent(
            state: ProbeAttributes.ContentState(message: "go", progress: 1),
            staleDate: start.addingTimeInterval(30),
            relevanceScore: 0
        )

        let staleActivity = try! Activity.request(attributes: attributes, content: content)
        requireTrue(staleActivity.activityState == .active, "not yet stale")
        OpenUIKitActivityKitTesting.setNow(start.addingTimeInterval(30))
        requireTrue(staleActivity.activityState == .stale, "staleDate")

        let alreadyStale = try! Activity.request(
            attributes: ProbeAttributes(label: "already-stale"),
            content: ActivityContent(
                state: ProbeAttributes.ContentState(message: "old", progress: 0),
                staleDate: start,
                relevanceScore: 0
            )
        )
        requireTrue(alreadyStale.activityState == .stale, "stale at request")

        let immediate = try! Activity.request(
            attributes: ProbeAttributes(label: "immediate"),
            contentState: ProbeAttributes.ContentState(message: "end", progress: 9)
        )
        await immediate.end(nil, dismissalPolicy: .immediate, timestamp: start.addingTimeInterval(30))
        requireTrue(immediate.activityState == .dismissed, "immediate dismiss")

        let defaultEnd = try! Activity.request(
            attributes: ProbeAttributes(label: "default"),
            contentState: ProbeAttributes.ContentState(message: "end", progress: 8)
        )
        let endAt = start.addingTimeInterval(60)
        OpenUIKitActivityKitTesting.setNow(endAt)
        await defaultEnd.end(
            ActivityContent(
                state: ProbeAttributes.ContentState(message: "final", progress: 100),
                staleDate: nil,
                relevanceScore: 0
            ),
            dismissalPolicy: .default,
            timestamp: endAt
        )
        requireTrue(defaultEnd.activityState == .ended, "default still ended")
        requireTrue(defaultEnd.contentState.message == "final", "final content")
        OpenUIKitActivityKitTesting.setNow(endAt.addingTimeInterval(4 * 60 * 60 - 1))
        requireTrue(defaultEnd.activityState == .ended, "before 4h")
        OpenUIKitActivityKitTesting.setNow(endAt.addingTimeInterval(4 * 60 * 60))
        requireTrue(defaultEnd.activityState == .dismissed, "default 4h")

        let afterStart = start.addingTimeInterval(24 * 60 * 60)
        OpenUIKitActivityKitTesting.setNow(afterStart)
        let after = try! Activity.request(
            attributes: ProbeAttributes(label: "after"),
            contentState: ProbeAttributes.ContentState(message: "end", progress: 7)
        )
        let afterDate = afterStart.addingTimeInterval(120)
        await after.end(using: nil, dismissalPolicy: .after(afterDate))
        requireTrue(after.activityState == .ended, "after pending")
        OpenUIKitActivityKitTesting.setNow(afterDate)
        requireTrue(after.activityState == .dismissed, "after date")

        let born = afterStart.addingTimeInterval(240)
        OpenUIKitActivityKitTesting.setNow(born)
        let autoEnd = try! Activity.request(
            attributes: ProbeAttributes(label: "auto"),
            contentState: ProbeAttributes.ContentState(message: "live", progress: 1)
        )
        OpenUIKitActivityKitTesting.setNow(born.addingTimeInterval(8 * 60 * 60))
        requireTrue(autoEnd.activityState == .ended, "8h auto-end")
        OpenUIKitActivityKitTesting.setNow(born.addingTimeInterval(12 * 60 * 60))
        requireTrue(autoEnd.activityState == .dismissed, "8h + 4h dismiss")
    }

    private static func exerciseLimitsAndErrors() async {
        OpenUIKitActivityKitTesting.reset()
        let start = Date(timeIntervalSince1970: 1_900_000_000)
        OpenUIKitActivityKitTesting.setNow(start)
        let content = ActivityContent(
            state: ProbeAttributes.ContentState(message: "cap", progress: 0),
            staleDate: nil
        )

        OpenUIKitActivityKitTesting.setAreActivitiesEnabled(false)
        requireError(.denied) {
            _ = try Activity.request(
                attributes: ProbeAttributes(label: "denied"),
                content: content
            )
        }
        OpenUIKitActivityKitTesting.setAreActivitiesEnabled(true)

        OpenUIKitActivityKitTesting.setDeviceSupportsActivities(false)
        requireError(.unsupported) {
            _ = try Activity.request(
                attributes: ProbeAttributes(label: "unsupported"),
                content: content
            )
        }
        OpenUIKitActivityKitTesting.setDeviceSupportsActivities(true)

        OpenUIKitActivityKitTesting.setEntitled(false)
        requireError(.unentitled) {
            _ = try Activity.request(
                attributes: ProbeAttributes(label: "unentitled"),
                content: content
            )
        }
        OpenUIKitActivityKitTesting.setEntitled(true)

        OpenUIKitActivityKitTesting.setBackgrounded(true)
        requireError(.visibility) {
            _ = try Activity.request(
                attributes: ProbeAttributes(label: "bg"),
                content: content
            )
        }
        OpenUIKitActivityKitTesting.setBackgrounded(false)

        requireError(.malformedActivityIdentifier) {
            _ = try Activity.request(
                attributes: ProbeAttributes(label: "channel"),
                content: content,
                pushType: .channel("")
            )
        }
        requireError(.malformedActivityIdentifier) {
            _ = try Activity.openUIKitHostRequest(
                attributes: ProbeAttributes(label: "bad-id"),
                content: content,
                id: ""
            )
        }
        requireError(.malformedActivityIdentifier) {
            _ = try Activity.openUIKitHostRequest(
                attributes: ProbeAttributes(label: "slash"),
                content: content,
                id: "not/valid"
            )
        }

        let first = try! Activity.openUIKitHostRequest(
            attributes: ProbeAttributes(label: "dup"),
            content: content,
            id: "stable-id"
        )
        requireError(.reconnectNotPermitted) {
            _ = try Activity.openUIKitHostRequest(
                attributes: ProbeAttributes(label: "dup2"),
                content: content,
                id: "stable-id"
            )
        }
        requireTrue(first.id == "stable-id", "explicit id")

        struct HugeAttributes: ActivityAttributes {
            struct ContentState: Codable, Hashable {
                var n: Int
            }

            var blob: String
        }
        requireError(.attributesTooLarge) {
            _ = try Activity.request(
                attributes: HugeAttributes(blob: String(repeating: "A", count: 5000)),
                contentState: HugeAttributes.ContentState(n: 1)
            )
        }

        OpenUIKitActivityKitTesting.reset()
        OpenUIKitActivityKitTesting.setNow(start)
        var started: [Activity<ProbeAttributes>] = []
        for index in 0..<8 {
            let created = try! Activity.request(
                attributes: ProbeAttributes(label: "cap-\(index)"),
                content: content
            )
            started.append(created)
        }
        requireTrue(Activity<ProbeAttributes>.activities.count == 8, "cap full")
        requireError(.targetMaximumExceeded) {
            _ = try Activity.request(
                attributes: ProbeAttributes(label: "ninth"),
                content: content
            )
        }
        await started[0].end(nil, dismissalPolicy: .immediate, timestamp: start)
        requireTrue(started[0].activityState == .dismissed, "slot freed")
        let ninth = try! Activity.request(
            attributes: ProbeAttributes(label: "ninth"),
            content: content
        )
        requireTrue(ninth.activityState == .active, "ninth after free")

        OpenUIKitActivityKitTesting.setInjectedRequestError(.globalMaximumExceeded)
        requireError(.globalMaximumExceeded) {
            _ = try Activity.request(
                attributes: ProbeAttributes(label: "global"),
                content: content
            )
        }
        OpenUIKitActivityKitTesting.setInjectedRequestError(.unsupportedTarget)
        requireError(.unsupportedTarget) {
            _ = try Activity.request(
                attributes: ProbeAttributes(label: "target"),
                content: content
            )
        }
        OpenUIKitActivityKitTesting.setInjectedRequestError(.persistenceFailure)
        requireError(.persistenceFailure) {
            _ = try Activity.request(
                attributes: ProbeAttributes(label: "persist"),
                content: content
            )
        }
        OpenUIKitActivityKitTesting.setInjectedRequestError(.missingProcessIdentifier)
        requireError(.missingProcessIdentifier) {
            _ = try Activity.request(
                attributes: ProbeAttributes(label: "pid"),
                content: content
            )
        }
    }

    private static func exercisePushTokenHook() async {
        OpenUIKitActivityKitTesting.reset()
        let activity = try! Activity.request(
            attributes: ProbeAttributes(label: "token"),
            contentState: ProbeAttributes.ContentState(message: "t", progress: 0),
            pushType: .token
        )
        requireTrue(activity.pushToken == nil, "no APNs token")

        let payload = Data([0x0A, 0x0B])
        OpenUIKitActivityKitTesting.setPushToken(payload, forActivityID: activity.id)
        requireTrue(activity.pushToken == payload, "pushToken set")
        let received = await collectPrefix(activity.pushTokenUpdates, 1)
        requireTrue(received == [payload], "pushTokenUpdates")
        _ = await activity.pushTokenUpdates.prefix(1).contains(payload)
        try! await exerciseAsyncSequence(activity.pushTokenUpdates)
    }

    private static func exerciseSequenceHelpers() async {
        OpenUIKitActivityKitTesting.reset()
        let activity = try! Activity.request(
            attributes: ProbeAttributes(label: "seq"),
            contentState: ProbeAttributes.ContentState(message: "s", progress: 1)
        )
        try! await exerciseAsyncSequence(Activity<ProbeAttributes>.activityUpdates)
        try! await exerciseAsyncSequence(activity.activityStateUpdates)
        try! await exerciseAsyncSequence(activity.contentUpdates)
        try! await exerciseAsyncSequence(activity.contentStateUpdates)

        _ = await activity.activityStateUpdates.prefix(1).contains(ActivityState.active)
        _ = await activity.contentStateUpdates.prefix(1).contains(
            ProbeAttributes.ContentState(message: "s", progress: 1)
        )
        _ = await Activity<ProbeAttributes>.pushToStartTokenUpdates.contains(Data())
        _ = await Activity<ProbeAttributes>.pushToStartTokenUpdates.max(by: {
            $0.count < $1.count
        })
        _ = await Activity<ProbeAttributes>.pushToStartTokenUpdates.min(by: {
            $0.count < $1.count
        })
    }

    private static func exerciseValueTypes() {
        do {
            let encodedState = try JSONEncoder().encode(ActivityState.active)
            let decodedState = try JSONDecoder().decode(ActivityState.self, from: encodedState)
            requireTrue(decodedState == .active, "codable state")
        } catch {
            fatalError("ActivityState Codable failed: \(error)")
        }
        requireTrue(ActivityState.pending != .stale, "state inequality")
        requireTrue(
            ActivityState.ended.hashValue == ActivityState.ended.hashValue,
            "state hash"
        )
        let allStates: [ActivityState] = [.pending, .active, .ended, .dismissed, .stale]
        requireTrue(Set(allStates).count == 5, "state cases")

        requireTrue(ActivityStyle.standard != .transient, "style inequality")
        requireTrue(
            ActivityStyle.standard.hashValue == ActivityStyle.standard.hashValue,
            "style hash"
        )

        let defaultPolicy = ActivityUIDismissalPolicy.default
        let immediatePolicy = ActivityUIDismissalPolicy.immediate
        let afterPolicy = ActivityUIDismissalPolicy.after(Date(timeIntervalSince1970: 0))
        requireTrue(defaultPolicy != immediatePolicy, "policy default/immediate")
        requireTrue(afterPolicy != defaultPolicy, "policy after")
        requireTrue(defaultPolicy == .default, "policy equality")

        requireTrue(PushType.token == .token, "push token equality")
        requireTrue(PushType.channel("sports") != .token, "channel vs token")
        requireTrue(PushType.channel("sports") == PushType.channel("sports"), "channel equality")
        requireTrue(PushType.channel("a") != PushType.channel("b"), "channel names")

        let errors: [ActivityAuthorizationError] = [
            .attributesTooLarge,
            .unsupported,
            .denied,
            .globalMaximumExceeded,
            .targetMaximumExceeded,
            .unsupportedTarget,
            .visibility,
            .persistenceFailure,
            .missingProcessIdentifier,
            .unentitled,
            .malformedActivityIdentifier,
            .reconnectNotPermitted,
        ]
        requireTrue(Set(errors).count == 12, "error cases")
        requireTrue(ActivityAuthorizationError.errorDomain == "ActivityKit.ActivityAuthorizationError", "domain")
        for error in errors {
            _ = error.errorCode
            _ = error.failureReason
            _ = error.hashValue
            _ = error != .unsupported
            requireTrue(error.recoverySuggestion == nil, "recovery")
            requireTrue(error.helpAnchor == nil, "helpAnchor")
            requireTrue(!error.localizedDescription.isEmpty, "localized")
            requireTrue(error.errorUserInfo.isEmpty, "userInfo")
        }
        requireTrue(
            ActivityAuthorizationError.attributesTooLarge.errorCode == 0,
            "raw 0"
        )
        requireTrue(
            ActivityAuthorizationError.malformedActivityIdentifier.errorCode == 10,
            "raw 10"
        )
        requireTrue(
            ActivityAuthorizationError.attributesTooLarge.failureReason
                == "The provided Live Activity attributes exceeded the maximum size of 4KB.",
            "too large description"
        )
        requireTrue(
            ActivityAuthorizationError.targetMaximumExceeded.failureReason
                == "The app has already started the maximum number of concurrent Live Activities.",
            "cap description"
        )
        requireTrue(
            ActivityAuthorizationError.unentitled
                != ActivityAuthorizationError.unsupportedTarget,
            "entitlement cases"
        )

        let content = ActivityContent(
            state: ProbeAttributes.ContentState(message: "idle", progress: 0),
            staleDate: nil,
            relevanceScore: 1.5
        )
        requireTrue(content.description.contains("1.5"), "description")
    }
}

await ActivityKitRuntime.main()
