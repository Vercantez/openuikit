import CallKit
import Foundation

private func roundTripAction<T: CXAction>(_ action: T) -> T {
    let archiver = NSKeyedArchiver(requiringSecureCoding: true)
    action.encode(with: archiver)
    let data = archiver.encodedData
    do {
        let unarchiver = try NSKeyedUnarchiver(forReadingFrom: data)
        unarchiver.requiresSecureCoding = true
        guard let restored = T(coder: unarchiver) else {
            preconditionFailure("\(T.self) decode returned nil")
        }
        return restored
    } catch {
        preconditionFailure("\(T.self) unarchive failed: \(error)")
    }
}

func testCXActionInitFulfillFailAndTimeoutDate() {
    let action = CXAction()
    precondition(type(of: action) == CXAction.self)
    precondition(!action.isComplete)
    precondition(action.timeoutDate == Date.distantFuture)
    precondition(action.uuid.uuidString.count == 36)
    action.fulfill()
    precondition(action.isComplete)
    action.fail()
    precondition(action.isComplete)
}

func testCXActionFailCompletes() {
    let action = CXAction()
    action.fail()
    precondition(action.isComplete)
}

func testCXActionNSCodingRoundTrip() {
    let original = CXAction()
    let restored = roundTripAction(original)
    precondition(restored.uuid == original.uuid)
    precondition(!restored.isComplete)
    precondition(restored.timeoutDate == Date.distantFuture)
}

func testCXCallActionInitVariants() {
    let uuid = UUID()
    let designated = CXCallAction(callUUID: uuid)
    let convenience = CXCallAction(call: uuid)
    precondition(designated.callUUID == uuid)
    precondition(convenience.callUUID == uuid)
    precondition(type(of: designated) == CXCallAction.self)
}

func testCXCallActionNSCodingRoundTrip() {
    let uuid = UUID()
    let original = CXCallAction(callUUID: uuid)
    let restored = roundTripAction(original)
    precondition(restored.callUUID == uuid)
}

func testCXTransactionInitAddActionAndComplete() {
    let first = CXAction()
    let transaction = CXTransaction(action: first)
    precondition(transaction.actions.count == 1)
    precondition(transaction.uuid.uuidString.count == 36)
    precondition(!transaction.isComplete)
    transaction.addAction(CXAction())
    precondition(transaction.actions.count == 2)
    transaction.actions.forEach { $0.fulfill() }
    precondition(transaction.isComplete)
    precondition(type(of: transaction) == CXTransaction.self)
}

func testCXTransactionInitWithActions() {
    let actions = [CXAction(), CXAction()]
    let transaction = CXTransaction(actions: actions)
    precondition(transaction.actions.count == 2)
}

func testCXTransactionNSCodingRoundTrip() {
    let start = CXStartCallAction(
        callUUID: UUID(),
        handle: CXHandle(type: .generic, value: "coded")
    )
    start.contactIdentifier = "cid"
    start.isVideo = true
    let original = CXTransaction(action: start)
    let archiver = NSKeyedArchiver(requiringSecureCoding: true)
    original.encode(with: archiver)
    let data = archiver.encodedData
    do {
        let unarchiver = try NSKeyedUnarchiver(forReadingFrom: data)
        unarchiver.requiresSecureCoding = true
        guard let restored = CXTransaction(coder: unarchiver) else {
            preconditionFailure("CXTransaction decode returned nil")
        }
        precondition(restored.uuid == original.uuid)
        precondition(restored.actions.count == 1)
        let restoredStart = restored.actions[0] as? CXStartCallAction
        precondition(restoredStart?.handle.value == "coded")
        precondition(restoredStart?.isVideo == true)
        precondition(restoredStart?.contactIdentifier == "cid")
    } catch {
        preconditionFailure("CXTransaction unarchive failed: \(error)")
    }
}
