import CoreFoundation
import CoreTelephony
import Foundation

/// Identity probe: CoreTelephony types are the staged platform Foundation
/// NSObject / Notification.Name, not a module-local lookalike. CoreFoundation
/// is the same staged CF module the toolchain already provides.
func consumeFoundationObject(_ object: Foundation.NSObject) {
    _ = object
}

func consumeNotificationName(_ name: Foundation.Notification.Name) {
    _ = name.rawValue
}

consumeFoundationObject(CTCall())
consumeFoundationObject(CTCallCenter())
consumeFoundationObject(CTCarrier())
consumeFoundationObject(CTCellularData())
consumeFoundationObject(CTCellularPlanProperties())
consumeFoundationObject(CTCellularPlanProvisioning())
consumeFoundationObject(CTCellularPlanProvisioningRequest())
consumeFoundationObject(CTCellularPlanStatus())
consumeFoundationObject(CTSubscriber())
consumeFoundationObject(CTSubscriberInfo())
consumeFoundationObject(CTTelephonyNetworkInfo())

consumeNotificationName(.CTRadioAccessTechnologyDidChange)
consumeNotificationName(.CTServiceRadioAccessTechnologyDidChange)

_ = CFBooleanGetValue(kCFBooleanTrue)

print("CORETELEPHONY_IDENTITY_OK")
