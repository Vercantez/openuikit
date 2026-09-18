import Foundation
import LiveCommunicationKit

private func failClosedConfiguration() -> ConversationManager.Configuration {
    ConversationManager.Configuration(
        ringtoneName: nil,
        iconTemplateImageData: nil,
        maximumConversationGroups: 1,
        maximumConversationsPerConversationGroup: 1,
        includesConversationInRecents: false,
        supportsVideo: false,
        supportedHandleTypes: [.phoneNumber]
    )
}

private struct FailClosedRecentDTO: Codable {
    var id: UUID
    var handles: [Handle]
    var date: Date
    var duration: TimeInterval
    var status: ConversationHistoryManager.RecentConversation.Status
    var direction: ConversationHistoryManager.RecentConversation.Direction
    var isRead: Bool
}

private func failClosedRecent() -> ConversationHistoryManager.RecentConversation {
    let dto = FailClosedRecentDTO(
        id: UUID(),
        handles: [Handle(type: .phoneNumber, value: "+15551212")],
        date: Date(timeIntervalSince1970: 7),
        duration: 0,
        status: .missed,
        direction: .incoming,
        isRead: false
    )
    return try! JSONDecoder().decode(
        ConversationHistoryManager.RecentConversation.self,
        from: try! JSONEncoder().encode(dto)
    )
}

private func expectFeatureUnsupported(_ error: any Error, operation: String) {
    precondition(
        (error as? CocoaError)?.code == .featureUnsupported,
        "\(operation) threw an unexpected error: \(error)"
    )
}

func testManagerPerformThrowsFeatureUnsupported() async {
    let manager = ConversationManager(configuration: failClosedConfiguration())
    let action = ConversationAction(conversationUUID: UUID())
    do {
        try await manager.perform([action])
        precondition(false, "perform must throw featureUnsupported without a CallKit daemon")
    } catch {
        expectFeatureUnsupported(error, operation: "perform")
    }
    precondition(manager.pendingActions.isEmpty)
}

func testReportNewIncomingConversationThrowsFeatureUnsupported() async {
    let manager = ConversationManager(configuration: failClosedConfiguration())
    do {
        try await manager.reportNewIncomingConversation(
            uuid: UUID(),
            update: Conversation.Update()
        )
        precondition(false, "reportNewIncomingConversation must throw featureUnsupported")
    } catch {
        expectFeatureUnsupported(error, operation: "reportNewIncomingConversation")
    }
    precondition(manager.conversations.isEmpty)
}

func testReportNewIncomingVoIPPushPayloadThrowsFeatureUnsupported() async {
    do {
        try await ConversationManager.reportNewIncomingVoIPPushPayload(["aps": ["sound": "ring"]])
        precondition(false, "reportNewIncomingVoIPPushPayload must throw featureUnsupported")
    } catch {
        expectFeatureUnsupported(error, operation: "reportNewIncomingVoIPPushPayload")
    }
}

func testRecentConversationsMatchingThrowsFeatureUnsupported() async {
    let predicate = Predicate<ConversationHistoryManager.RecentConversation> { _ in
        PredicateExpressions.Value(true)
    }
    do {
        _ = try await ConversationHistoryManager.sharedInstance.recentConversations(
            matching: predicate
        )
        precondition(false, "recentConversations must throw featureUnsupported")
    } catch {
        expectFeatureUnsupported(error, operation: "recentConversations")
    }
}

func testMarkConversationAsReadThrowsFeatureUnsupported() async {
    do {
        try await ConversationHistoryManager.sharedInstance.markConversationAsRead(
            failClosedRecent()
        )
        precondition(false, "markConversationAsRead must throw featureUnsupported")
    } catch {
        expectFeatureUnsupported(error, operation: "markConversationAsRead")
    }
}

func testMarkConversationsAsReadThrowsFeatureUnsupported() async {
    do {
        try await ConversationHistoryManager.sharedInstance.markConversationsAsRead(
            [failClosedRecent()]
        )
        precondition(false, "markConversationsAsRead must throw featureUnsupported")
    } catch {
        expectFeatureUnsupported(error, operation: "markConversationsAsRead")
    }
}

func testStartCellularConversationThrowsFeatureUnsupported() async {
    let action = StartCellularConversationAction(
        Handle(type: .phoneNumber, value: "+15551212")
    )
    do {
        try await TelephonyConversationManager.sharedInstance.startCellularConversation(action)
        precondition(false, "startCellularConversation must throw featureUnsupported")
    } catch {
        expectFeatureUnsupported(error, operation: "startCellularConversation")
    }
    precondition(TelephonyConversationManager.sharedInstance.cellularServices.isEmpty)
}
