import ActivityKit
import Foundation

private struct ProbeAttributes: ActivityAttributes, Equatable {
    struct ContentState: Codable, Hashable {
        var message: String
        var progress: Int
    }

    var label: String
}

private func requireUnsupported(_ error: Error) {
    guard let error = error as? ActivityAuthorizationError else {
        fatalError("expected ActivityAuthorizationError")
    }
    if error != .unsupported {
        fatalError("expected unsupported")
    }
    if error.errorCode != ActivityAuthorizationError.unsupported.errorCode {
        fatalError("unexpected errorCode")
    }
    if ActivityAuthorizationError.errorDomain != "ActivityKit.ActivityAuthorizationError" {
        fatalError("unexpected errorDomain")
    }
    if error.failureReason == nil {
        fatalError("missing failureReason")
    }
    if error.errorDescription != error.failureReason {
        fatalError("errorDescription mismatch")
    }
    if error.recoverySuggestion != nil {
        fatalError("recoverySuggestion should be nil")
    }
    if error.localizedDescription.isEmpty {
        fatalError("missing localizedDescription")
    }
    if error.helpAnchor != nil {
        fatalError("helpAnchor should be nil")
    }
    if !error.errorUserInfo.isEmpty {
        fatalError("errorUserInfo should be empty")
    }
}

private func requireRequestFailure(
    _ body: () throws -> Activity<ProbeAttributes>
) {
    do {
        _ = try body()
        fatalError("Activity.request must fail closed")
    } catch {
        requireUnsupported(error)
    }
}

private func requireTrue(_ value: Bool, _ message: String) {
    if !value {
        fatalError(message)
    }
}

enum ActivityKitRuntime {
    static func main() async {
        requireTrue(Activity<ProbeAttributes>.ID.self == String.self, "ID alias")
        requireTrue(Activity<ProbeAttributes>.activities.isEmpty, "activities")
        requireTrue(Activity<ProbeAttributes>.pushToStartToken == nil, "pushToStartToken")

        let info = ActivityAuthorizationInfo()
        requireTrue(info.areActivitiesEnabled == false, "areActivitiesEnabled")
        requireTrue(info.frequentPushesEnabled == false, "frequentPushesEnabled")

        var enablement: [Bool] = []
        for await value in info.activityEnablementUpdates {
            enablement.append(value)
        }
        requireTrue(enablement == [false], "enablement sequence")

        var frequent: [Bool] = []
        for await value in info.frequentPushEnablementUpdates {
            frequent.append(value)
        }
        requireTrue(frequent == [false], "frequent sequence")

        let containsFalse = await info.activityEnablementUpdates.contains(false)
        requireTrue(containsFalse, "contains false")
        let containsTrue = await info.activityEnablementUpdates.contains(true)
        requireTrue(containsTrue == false, "contains true")
        let allDisabled = await info.activityEnablementUpdates.allSatisfy { $0 == false }
        requireTrue(allDisabled, "allSatisfy disabled")
        let firstDisabled = await info.activityEnablementUpdates.first(where: { $0 == false })
        requireTrue(firstDisabled == false, "first disabled")
        let frequentHasTrue = await info.frequentPushEnablementUpdates.contains(where: { $0 })
        requireTrue(frequentHasTrue == false, "frequent contains true")

        let mappedEnablement = info.activityEnablementUpdates.map { $0 ? 1 : 0 }
        var mappedValues: [Int] = []
        for await value in mappedEnablement {
            mappedValues.append(value)
        }
        requireTrue(mappedValues == [0], "mapped enablement")

        var activityIDs: [String] = []
        for await activity in Activity<ProbeAttributes>.activityUpdates {
            activityIDs.append(activity.id)
        }
        requireTrue(activityIDs.isEmpty, "activityUpdates")
        let hasActivity = await Activity<ProbeAttributes>.activityUpdates.contains(where: { _ in true })
        requireTrue(hasActivity == false, "activityUpdates contains")
        let allActivitiesFalse = await Activity<ProbeAttributes>.activityUpdates.allSatisfy { _ in false }
        requireTrue(allActivitiesFalse, "activityUpdates allSatisfy empty")

        let prefixed = Activity<ProbeAttributes>.activityUpdates.prefix(1)
        var prefixCount = 0
        for await _ in prefixed { prefixCount += 1 }
        requireTrue(prefixCount == 0, "prefix")
        let dropped = Activity<ProbeAttributes>.activityUpdates.dropFirst()
        var dropCount = 0
        for await _ in dropped { dropCount += 1 }
        requireTrue(dropCount == 0, "dropFirst")
        let reduced = await Activity<ProbeAttributes>.activityUpdates.reduce(0) { count, _ in
            count + 1
        }
        requireTrue(reduced == 0, "reduce")
        let reducedInto = await Activity<ProbeAttributes>.activityUpdates.reduce(into: 0) {
            count, _ in
            count += 1
        }
        requireTrue(reducedInto == 0, "reduce into")
        let filtered = Activity<ProbeAttributes>.activityUpdates.filter { _ in true }
        var filterCount = 0
        for await _ in filtered { filterCount += 1 }
        requireTrue(filterCount == 0, "filter")
        let compact = Activity<ProbeAttributes>.activityUpdates.compactMap { activity -> String? in
            activity.id
        }
        var compactCount = 0
        for await _ in compact { compactCount += 1 }
        requireTrue(compactCount == 0, "compactMap")
        let dropping = Activity<ProbeAttributes>.activityUpdates.drop(while: { _ in false })
        var dropWhileCount = 0
        for await _ in dropping { dropWhileCount += 1 }
        requireTrue(dropWhileCount == 0, "drop while")
        let prefixing = Activity<ProbeAttributes>.activityUpdates.prefix(while: { _ in true })
        var prefixWhileCount = 0
        for await _ in prefixing { prefixWhileCount += 1 }
        requireTrue(prefixWhileCount == 0, "prefix while")
        let nested = Activity<ProbeAttributes>.activityUpdates.flatMap { _ in
            Activity<ProbeAttributes>.activityUpdates
        }
        var nestedCount = 0
        for await _ in nested { nestedCount += 1 }
        requireTrue(nestedCount == 0, "flatMap")

        var pushTokens: [Data] = []
        for await token in Activity<ProbeAttributes>.pushToStartTokenUpdates {
            pushTokens.append(token)
        }
        requireTrue(pushTokens.isEmpty, "push tokens")
        let containsEmptyToken = await Activity<ProbeAttributes>.pushToStartTokenUpdates.contains(Data())
        requireTrue(containsEmptyToken == false, "contains empty token")
        let maxToken = await Activity<ProbeAttributes>.pushToStartTokenUpdates.max(by: {
            $0.count < $1.count
        })
        requireTrue(maxToken == nil, "max token")
        let minToken = await Activity<ProbeAttributes>.pushToStartTokenUpdates.min(by: {
            $0.count < $1.count
        })
        requireTrue(minToken == nil, "min token")

        let attributes = ProbeAttributes(label: "probe")
        let contentState = ProbeAttributes.ContentState(message: "idle", progress: 0)
        let content = ActivityContent(
            state: contentState,
            staleDate: nil,
            relevanceScore: 1.5
        )
        requireTrue(content.state == contentState, "content state")
        requireTrue(content.staleDate == nil, "staleDate")
        requireTrue(content.relevanceScore == 1.5, "relevanceScore")
        requireTrue(content.description.contains("1.5"), "description")

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

        let alert = AlertConfiguration(
            title: "Title",
            body: LocalizedStringResource("Body"),
            sound: .default
        )
        let namedAlert = AlertConfiguration(
            title: "Title",
            body: "Body",
            sound: .named("chime")
        )
        requireTrue(
            alert == AlertConfiguration(title: "Title", body: "Body", sound: .default),
            "alert equality"
        )
        requireTrue(alert != namedAlert, "alert sound inequality")
        requireTrue(
            AlertConfiguration.AlertSound.default != .named("default"),
            "default sound identity"
        )

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
        for error in errors {
            _ = error.errorCode
            _ = error.failureReason
            _ = error.hashValue
            _ = error != .unsupported
        }
        requireTrue(
            ActivityAuthorizationError.unentitled
                != ActivityAuthorizationError.unsupportedTarget,
            "entitlement cases"
        )

        let start = Date(timeIntervalSince1970: 1)
        requireRequestFailure {
            try Activity.request(attributes: attributes, contentState: contentState)
        }
        requireRequestFailure {
            try Activity.request(
                attributes: attributes,
                contentState: contentState,
                pushType: .token
            )
        }
        requireRequestFailure {
            try Activity.request(attributes: attributes, content: content)
        }
        requireRequestFailure {
            try Activity.request(
                attributes: attributes,
                content: content,
                pushType: .channel("probe")
            )
        }
        requireRequestFailure {
            try Activity.request(
                attributes: attributes,
                content: content,
                style: .standard
            )
        }
        requireRequestFailure {
            try Activity.request(
                attributes: attributes,
                content: content,
                pushType: .token,
                style: .transient
            )
        }
        requireRequestFailure {
            try Activity.request(
                attributes: attributes,
                content: content,
                style: .standard,
                alertConfiguration: alert,
                start: start
            )
        }
        requireRequestFailure {
            try Activity.request(
                attributes: attributes,
                content: content,
                pushType: nil,
                style: .transient,
                alertConfiguration: namedAlert,
                start: start
            )
        }
        requireRequestFailure {
            try Activity.request(
                attributes: attributes,
                content: content,
                style: .standard,
                alertConfiguration: alert,
                startDate: start
            )
        }
        requireRequestFailure {
            try Activity.request(
                attributes: attributes,
                content: content,
                pushType: .token,
                style: .transient,
                alertConfiguration: namedAlert,
                startDate: start
            )
        }

        print("ACTIVITYKIT_AGENT_RUNTIME_OK")
    }
}

await ActivityKitRuntime.main()
