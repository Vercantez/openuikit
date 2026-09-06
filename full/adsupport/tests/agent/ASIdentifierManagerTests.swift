import AdSupport
import Foundation

func testASIdentifierManagerClassIdentity() {
    let manager = ASIdentifierManager.shared()
    precondition(type(of: manager) == ASIdentifierManager.self)
    let asObject: NSObject = manager
    precondition(asObject === manager)
    precondition(manager.isKind(of: NSObject.self))
    let _: ASIdentifierManager.Type = ASIdentifierManager.self
    precondition(!(String(reflecting: ASIdentifierManager.self).hasPrefix("Foundation.")))
}

func testSharedReturnsProcessWideSingleton() {
    let first = ASIdentifierManager.shared()
    let second = ASIdentifierManager.shared()
    precondition(first === second)
    let signature: () -> ASIdentifierManager = ASIdentifierManager.shared
    precondition(signature() === first)
    precondition(type(of: first) == ASIdentifierManager.self)
}

func testAdvertisingIdentifierIsZeroUUID() {
    let manager = ASIdentifierManager.shared()
    let identifier = manager.advertisingIdentifier
    let zero = UUID(uuid: (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0))
    precondition(identifier == zero)
    precondition(identifier.uuidString == "00000000-0000-0000-0000-000000000000")
    precondition(identifier.uuidString == identifier.uuidString.lowercased())
    precondition(type(of: identifier) == UUID.self)
    precondition(manager.advertisingIdentifier == identifier)
    precondition(UUID(uuidString: identifier.uuidString) == identifier)
}

func testAdvertisingTrackingEnabledIsFalse() {
    let manager = ASIdentifierManager.shared()
    precondition(manager.isAdvertisingTrackingEnabled == false)
    let boxed = NSNumber(value: manager.isAdvertisingTrackingEnabled)
    precondition(boxed.boolValue == false)
    precondition(type(of: manager.isAdvertisingTrackingEnabled) == Bool.self)
}
