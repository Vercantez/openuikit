import Foundation
import LiveCommunicationKit

private struct CellularServiceDTO: Codable {
    var id: UUID
    var label: String
}

func testCellularServiceCodableRoundTrip() {
    let dto = CellularServiceDTO(
        id: UUID(uuidString: "00000000-0000-0000-0000-00000000000a")!,
        label: "Primary"
    )
    let data = try! JSONEncoder().encode(dto)
    let service = try! JSONDecoder().decode(CellularService.self, from: data)
    precondition(service.id == dto.id)
    precondition(service.label == "Primary")
    let identity: CellularService.ID = service.id
    precondition(identity == service.id)
}

func testCellularServiceEqualityAndHash() {
    let dto = CellularServiceDTO(
        id: UUID(uuidString: "00000000-0000-0000-0000-00000000000b")!,
        label: "Secondary"
    )
    let data = try! JSONEncoder().encode(dto)
    let a = try! JSONDecoder().decode(CellularService.self, from: data)
    let b = try! JSONDecoder().decode(CellularService.self, from: data)
    precondition(a == b)
    precondition(!(a != b))
    var hasherA = Hasher()
    var hasherB = Hasher()
    a.hash(into: &hasherA)
    b.hash(into: &hasherB)
    precondition(hasherA.finalize() == hasherB.finalize())
    precondition(a.hashValue == b.hashValue)
}

func testStartCellularConversationActionFromHandle() {
    let handle = Handle(type: .phoneNumber, value: "+15551212")
    let action = StartCellularConversationAction(handle)
    let again = StartCellularConversationAction(handle, cellularService: nil)
    precondition(action == again)
    precondition(!(action != again))
}

func testStartCellularConversationActionWithService() {
    let handle = Handle(type: .generic, value: "id")
    let service = try! JSONDecoder().decode(
        CellularService.self,
        from: try! JSONEncoder().encode(
            CellularServiceDTO(id: UUID(), label: "SIM")
        )
    )
    let withService = StartCellularConversationAction(handle, cellularService: service)
    let without = StartCellularConversationAction(handle)
    precondition(withService != without)
    var hasher = Hasher()
    withService.hash(into: &hasher)
    _ = hasher.finalize()
    precondition(withService.hashValue == withService.hashValue)
}

func testStartCellularConversationActionFromRecent() {
    let handle = Handle(type: .phoneNumber, value: "+1999")
    let dto = RecentSeed(
        id: UUID(),
        handles: [handle],
        date: Date(timeIntervalSince1970: 8),
        duration: 1,
        status: .missed,
        direction: .incoming,
        isRead: false
    )
    let recent = try! JSONDecoder().decode(
        ConversationHistoryManager.RecentConversation.self,
        from: try! JSONEncoder().encode(dto)
    )
    let action = StartCellularConversationAction(recent)
    let fromHandle = StartCellularConversationAction(handle)
    precondition(action == fromHandle)
}

func testStartCellularConversationActionCodable() {
    let handle = Handle(type: .emailAddress, value: "a@b.c")
    let original = StartCellularConversationAction(handle)
    let data = try! JSONEncoder().encode(original)
    let restored = try! JSONDecoder().decode(StartCellularConversationAction.self, from: data)
    precondition(restored == original)
}

func testTelephonyConversationManagerSharedAndEmptyServices() {
    let manager = TelephonyConversationManager.sharedInstance
    precondition(manager === TelephonyConversationManager.sharedInstance)
    precondition(manager.cellularServices.isEmpty)
}

private struct RecentSeed: Codable {
    var id: UUID
    var handles: [Handle]
    var date: Date
    var duration: TimeInterval
    var status: ConversationHistoryManager.RecentConversation.Status
    var direction: ConversationHistoryManager.RecentConversation.Direction
    var isRead: Bool
}
