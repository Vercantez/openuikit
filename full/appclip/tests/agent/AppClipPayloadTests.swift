import AppClip
import Foundation

func testPayloadClassIdentity() {
    let instance: NSObject = APActivationPayload()
    precondition(type(of: instance) == APActivationPayload.self)
    precondition(instance.isKind(of: NSObject.self))
    precondition(APActivationPayload.supportsSecureCoding)
    let copy = instance.copy() as? APActivationPayload
    precondition(copy != nil)
    precondition(copy !== instance)
}

func testPayloadURLIsNil() {
    let payload = APActivationPayload()
    precondition(payload.url == nil)
    let copied = payload.copy() as! APActivationPayload
    precondition(copied.url == nil)
}

func testPayloadInitCoderFailClosed() {
    do {
        let data = try NSKeyedArchiver.archivedData(
            withRootObject: "appclip-malformed",
            requiringSecureCoding: true
        )
        let unarchiver = try NSKeyedUnarchiver(forReadingFrom: data)
        unarchiver.requiresSecureCoding = true
        precondition(APActivationPayload(coder: unarchiver) == nil)
    } catch {
        preconditionFailure("malformed archive setup failed: \(error)")
    }

    let payload = APActivationPayload()
    do {
        let data = try NSKeyedArchiver.archivedData(
            withRootObject: payload,
            requiringSecureCoding: true
        )
        let restored = try NSKeyedUnarchiver.unarchivedObject(
            ofClass: APActivationPayload.self,
            from: data
        )
        precondition(restored == nil)
    } catch {
        // Fail-closed unarchive (throwing instead of nil) is also honest.
        _ = error
    }
}
