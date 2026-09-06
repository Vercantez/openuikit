@_spi(OpenUIKitHost) import SharedWithYouCore
import Foundation

func swcRequireType<T>(_ value: Any, as type: T.Type) {
    precondition(value is T, "expected \(type)")
}

private func swcArchiveRoundTrip<T: NSObject & NSSecureCoding>(_ value: T) -> T {
    let data: Data
    do {
        data = try NSKeyedArchiver.archivedData(withRootObject: value, requiringSecureCoding: true)
    } catch {
        preconditionFailure("archive failed: \(error)")
    }
    do {
        guard let restored = try NSKeyedUnarchiver.unarchivedObject(ofClass: T.self, from: data) else {
            preconditionFailure("expected restored \(T.self)")
        }
        return restored
    } catch {
        preconditionFailure("unarchive failed: \(error)")
    }
}

private func swcRejectsEmptyCoder<T: NSObject & NSSecureCoding>(_ type: T.Type) {
    do {
        let data = try NSKeyedArchiver.archivedData(
            withRootObject: "swc-malformed",
            requiringSecureCoding: true
        )
        let unarchiver = try NSKeyedUnarchiver(forReadingFrom: data)
        unarchiver.requiresSecureCoding = true
        precondition(type.init(coder: unarchiver) == nil)
    } catch {
        preconditionFailure("malformed archive setup failed: \(error)")
    }
}

func testSWActionClass() {
    let action = SWAction()
    swcRequireType(action, as: SWAction.self)
    precondition(action.isComplete == false)
}

func testSWActionUUID() {
    let uuid = UUID(uuidString: "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb")!
    let action = SharedWithYouCoreHostControl.makeAction(uuid: uuid)
    precondition(action.uuid == uuid)
    let other = SWAction()
    precondition(action.uuid != other.uuid)
}

func testSWActionIsComplete() {
    let action = SWAction()
    precondition(action.isComplete == false)
    action.fulfill()
    precondition(action.isComplete == true)
}

func testSWActionFulfill() {
    let action = SWAction()
    action.fulfill()
    precondition(action.isComplete)
    precondition(SharedWithYouCoreHostControl.actionCompletion(action) == .fulfilled)
    action.fail()
    precondition(SharedWithYouCoreHostControl.actionCompletion(action) == .fulfilled)
    precondition(action.isComplete)
}

func testSWActionFail() {
    let action = SWAction()
    action.fail()
    precondition(action.isComplete)
    precondition(SharedWithYouCoreHostControl.actionCompletion(action) == .failed)
    action.fulfill()
    precondition(SharedWithYouCoreHostControl.actionCompletion(action) == .failed)
}

func testSWActionInitCoder() {
    let uuid = UUID(uuidString: "cccccccc-cccc-cccc-cccc-cccccccccccc")!
    let action = SharedWithYouCoreHostControl.makeAction(uuid: uuid)
    action.fulfill()
    let restored = swcArchiveRoundTrip(action)
    precondition(restored.uuid == uuid)
    precondition(restored.isComplete)
    precondition(SharedWithYouCoreHostControl.actionCompletion(restored) == .fulfilled)
    swcRejectsEmptyCoder(SWAction.self)
}
