import AdSupport
import Foundation

// Isolated host-gate success against toolchain Foundation is not integrated
// guest-Foundation success. This probe is for a future clean EC2 run that
// builds guest Foundation first, then AdSupport with that `-I` / `-L`.

func adSupportDependencyIdentityProbe() {
    let date = Date(timeIntervalSince1970: 1)
    let data = Data("adsupport-identity".utf8)
    precondition(type(of: date) == Date.self)
    precondition(type(of: data) == Data.self)
    precondition(!String(reflecting: type(of: date)).hasPrefix("AdSupport."))
    precondition(!String(reflecting: type(of: data)).hasPrefix("AdSupport."))

    let manager = ASIdentifierManager.shared()
    let identifier: UUID = manager.advertisingIdentifier
    precondition(type(of: identifier) == UUID.self)
    precondition(type(of: identifier) == Foundation.UUID.self)
    precondition(!String(reflecting: type(of: identifier)).hasPrefix("AdSupport."))
    precondition(identifier.uuidString == "00000000-0000-0000-0000-000000000000")

    let enabled: Bool = manager.isAdvertisingTrackingEnabled
    precondition(enabled == false)
    let boxed = NSNumber(value: enabled)
    precondition(type(of: boxed) == NSNumber.self)
    precondition(!String(reflecting: type(of: boxed)).hasPrefix("AdSupport."))
    precondition(boxed.boolValue == false)

    let asObject: NSObject = manager
    precondition(asObject === manager)
    precondition(type(of: asObject) == ASIdentifierManager.self)
    precondition(!String(reflecting: NSObject.self).hasPrefix("AdSupport."))

    print("ADSUPPORT_DEPENDENCY_IDENTITY_OK")
}

#if ADSUPPORT_IDENTITY_MAIN
adSupportDependencyIdentityProbe()
#endif
