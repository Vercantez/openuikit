import Foundation
import LiveCommunicationKit

private struct RecentConversationDTO: Codable {
    var id: UUID
    var handles: [Handle]
    var date: Date
    var duration: TimeInterval
    var status: ConversationHistoryManager.RecentConversation.Status
    var direction: ConversationHistoryManager.RecentConversation.Direction
    var isRead: Bool
}

func testRecentConversationCodableRoundTrip() {
    let handle = Handle(type: .emailAddress, value: "a@b.c", displayName: "Ada")
    let dto = RecentConversationDTO(
        id: UUID(),
        handles: [handle],
        date: Date(timeIntervalSince1970: 42),
        duration: 3.25,
        status: .connected,
        direction: .outgoing,
        isRead: true
    )
    let data = try! JSONEncoder().encode(dto)
    let recent = try! JSONDecoder().decode(
        ConversationHistoryManager.RecentConversation.self,
        from: data
    )
    precondition(recent.id == dto.id)
    precondition(recent.handles == [handle])
    precondition(recent.date == dto.date)
    precondition(recent.duration == 3.25)
    precondition(recent.status == .connected)
    precondition(recent.direction == .outgoing)
    precondition(recent.isRead)
    let id: ConversationHistoryManager.RecentConversation.ID = recent.id
    precondition(id == recent.id)
}

func testRecentConversationEqualityAndHash() {
    let dto = RecentConversationDTO(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
        handles: [Handle(type: .generic, value: "x")],
        date: Date(timeIntervalSince1970: 1),
        duration: 0,
        status: .cancelled,
        direction: .outgoing,
        isRead: false
    )
    let data = try! JSONEncoder().encode(dto)
    let a = try! JSONDecoder().decode(
        ConversationHistoryManager.RecentConversation.self,
        from: data
    )
    let b = try! JSONDecoder().decode(
        ConversationHistoryManager.RecentConversation.self,
        from: data
    )
    precondition(a == b)
    precondition(!(a != b))
    var hasherA = Hasher()
    var hasherB = Hasher()
    a.hash(into: &hasherA)
    b.hash(into: &hasherB)
    precondition(hasherA.finalize() == hasherB.finalize())
    precondition(a.hashValue == b.hashValue)
}

func testConversationHistorySharedInstanceIdentity() {
    let shared = ConversationHistoryManager.sharedInstance
    precondition(shared === ConversationHistoryManager.sharedInstance)
}

func testConversationHistoryDidUpdateNameAndInit() {
    let message = ConversationHistoryManager.ConversationHistoryDidUpdate()
    _ = message
    let name = ConversationHistoryManager.ConversationHistoryDidUpdate.name
    precondition(name.rawValue.contains("ConversationHistoryDidUpdate"))
    let subject: ConversationHistoryManager.ConversationHistoryDidUpdate.Subject.Type =
        ConversationHistoryManager.self
    precondition(subject == ConversationHistoryManager.self)
}

func testConversationHistoryDidUpdateMakeMessage() {
    let name = ConversationHistoryManager.ConversationHistoryDidUpdate.name
    let matching = Notification(name: name)
    let message = ConversationHistoryManager.ConversationHistoryDidUpdate.makeMessage(matching)
    precondition(message != nil)
    let other = Notification(name: Notification.Name("other"))
    precondition(ConversationHistoryManager.ConversationHistoryDidUpdate.makeMessage(other) == nil)
}

func testConversationHistoryDidUpdateMakeNotification() {
    let message = ConversationHistoryManager.ConversationHistoryDidUpdate()
    let notification = ConversationHistoryManager.ConversationHistoryDidUpdate.makeNotification(message)
    precondition(notification.name == ConversationHistoryManager.ConversationHistoryDidUpdate.name)
    let roundTrip = ConversationHistoryManager.ConversationHistoryDidUpdate.makeMessage(notification)
    precondition(roundTrip != nil)
}

func testRecentConversationStatusUnknownAndCancelled() {
    let dto = RecentConversationDTO(
        id: UUID(),
        handles: [],
        date: Date(timeIntervalSince1970: 0),
        duration: 0,
        status: .unknown,
        direction: .incoming,
        isRead: false
    )
    let recent = try! JSONDecoder().decode(
        ConversationHistoryManager.RecentConversation.self,
        from: try! JSONEncoder().encode(dto)
    )
    precondition(recent.status == .unknown)
    precondition(recent.handles.isEmpty)
    precondition(!recent.isRead)
}
