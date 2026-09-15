import Foundation

// Wave-11 generated Matter cluster Params / Response / Event / Struct value types.

open class MTRAccessControlClusterAccessControlEntryChangedEvent: NSObject {
    public var adminNodeID: NSNumber?
    public var adminPasscodeID: NSNumber?
    public var changeType: NSNumber = 0
    public var fabricIndex: NSNumber = 0
    public var latestValue: MTRAccessControlClusterAccessControlEntryStruct?
    public override init() { super.init() }
    public override var description: String {
        "MTRAccessControlClusterAccessControlEntryChangedEvent(adminNodeID: \(adminNodeID as Optional<Any>), adminPasscodeID: \(adminPasscodeID as Optional<Any>), changeType: \(changeType as Optional<Any>), fabricIndex: \(fabricIndex as Optional<Any>), latestValue: \(latestValue as Optional<Any>))"
    }
}
open class MTRAccessControlClusterAccessControlEntryStruct: NSObject {
    public var authMode: NSNumber = 0
    public var fabricIndex: NSNumber = 0
    public var privilege: NSNumber = 0
    public var subjects: [Any]?
    public var targets: [Any]?
    public override init() { super.init() }
    public override var description: String {
        "MTRAccessControlClusterAccessControlEntryStruct(authMode: \(authMode as Optional<Any>), fabricIndex: \(fabricIndex as Optional<Any>), privilege: \(privilege as Optional<Any>), subjects: \(subjects as Optional<Any>), targets: \(targets as Optional<Any>))"
    }
}
open class MTRAccessControlClusterAccessControlExtensionChangedEvent: NSObject {
    public var adminNodeID: NSNumber?
    public var adminPasscodeID: NSNumber?
    public var changeType: NSNumber = 0
    public var fabricIndex: NSNumber = 0
    public var latestValue: MTRAccessControlClusterAccessControlExtensionStruct?
    public override init() { super.init() }
    public override var description: String {
        "MTRAccessControlClusterAccessControlExtensionChangedEvent(adminNodeID: \(adminNodeID as Optional<Any>), adminPasscodeID: \(adminPasscodeID as Optional<Any>), changeType: \(changeType as Optional<Any>), fabricIndex: \(fabricIndex as Optional<Any>), latestValue: \(latestValue as Optional<Any>))"
    }
}
open class MTRAccessControlClusterAccessControlExtensionStruct: NSObject {
    public var data: Data = Data()
    public var fabricIndex: NSNumber = 0
    public override init() { super.init() }
    public override var description: String {
        "MTRAccessControlClusterAccessControlExtensionStruct(data: \(data as Optional<Any>), fabricIndex: \(fabricIndex as Optional<Any>))"
    }
}
open class MTRAccessControlClusterAccessControlTargetStruct: NSObject {
    public var cluster: NSNumber?
    public var deviceType: NSNumber?
    public var endpoint: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRAccessControlClusterAccessControlTargetStruct(cluster: \(cluster as Optional<Any>), deviceType: \(deviceType as Optional<Any>), endpoint: \(endpoint as Optional<Any>))"
    }
}
open class MTRAccessControlClusterAccessRestrictionEntryStruct: NSObject {
    public var cluster: NSNumber = 0
    public var endpoint: NSNumber = 0
    public var fabricIndex: NSNumber = 0
    public var restrictions: [Any] = []
    public override init() { super.init() }
    public override var description: String {
        "MTRAccessControlClusterAccessRestrictionEntryStruct(cluster: \(cluster as Optional<Any>), endpoint: \(endpoint as Optional<Any>), fabricIndex: \(fabricIndex as Optional<Any>), restrictions: \(restrictions as Optional<Any>))"
    }
}
open class MTRAccessControlClusterAccessRestrictionStruct: NSObject {
    public var id: NSNumber?
    public var `type`: NSNumber = 0
    public override init() { super.init() }
    public override var description: String {
        "MTRAccessControlClusterAccessRestrictionStruct(id: \(id as Optional<Any>), type: \(`type` as Optional<Any>))"
    }
}
open class MTRAccessControlClusterCommissioningAccessRestrictionEntryStruct: NSObject {
    public var cluster: NSNumber = 0
    public var endpoint: NSNumber = 0
    public var restrictions: [Any] = []
    public override init() { super.init() }
    public override var description: String {
        "MTRAccessControlClusterCommissioningAccessRestrictionEntryStruct(cluster: \(cluster as Optional<Any>), endpoint: \(endpoint as Optional<Any>), restrictions: \(restrictions as Optional<Any>))"
    }
}
open class MTRAccessControlClusterFabricRestrictionReviewUpdateEvent: NSObject {
    public var fabricIndex: NSNumber = 0
    public var instruction: String?
    public var token: NSNumber = 0
    public override init() { super.init() }
    public override var description: String {
        "MTRAccessControlClusterFabricRestrictionReviewUpdateEvent(fabricIndex: \(fabricIndex as Optional<Any>), instruction: \(instruction as Optional<Any>), token: \(token as Optional<Any>))"
    }
}
open class MTRAccessControlClusterReviewFabricRestrictionsParams: NSObject {
    public var arl: [Any] = []
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRAccessControlClusterReviewFabricRestrictionsParams(arl: \(arl as Optional<Any>), serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}
open class MTRAccessControlClusterReviewFabricRestrictionsResponseParams: NSObject {
    public init(responseValue: [String : Any]) throws {
        if let err = responseValue[MTRErrorKey] as? (any Error) {
            throw err
        }
        super.init()
        _ = responseValue[MTRDataKey] as? [String: Any]
    }
    public var token: NSNumber = 0
    public override init() { super.init() }
    public override var description: String {
        "MTRAccessControlClusterReviewFabricRestrictionsResponseParams(token: \(token as Optional<Any>))"
    }
}
open class MTRAccountLoginClusterGetSetupPINParams: NSObject {
    public var serverSideProcessingTimeout: NSNumber?
    public var tempAccountIdentifier: String = ""
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRAccountLoginClusterGetSetupPINParams(serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), tempAccountIdentifier: \(tempAccountIdentifier as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}
open class MTRAccountLoginClusterGetSetupPINResponseParams: NSObject {
    public init(responseValue: [String : Any]) throws {
        if let err = responseValue[MTRErrorKey] as? (any Error) {
            throw err
        }
        super.init()
        _ = responseValue[MTRDataKey] as? [String: Any]
    }
    public var setupPIN: String = ""
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRAccountLoginClusterGetSetupPINResponseParams(setupPIN: \(setupPIN as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}
open class MTRAccountLoginClusterLoggedOutEvent: NSObject {
    public var node: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRAccountLoginClusterLoggedOutEvent(node: \(node as Optional<Any>))"
    }
}
open class MTRAccountLoginClusterLoginParams: NSObject {
    public var node: NSNumber?
    public var serverSideProcessingTimeout: NSNumber?
    public var setupPIN: String = ""
    public var tempAccountIdentifier: String = ""
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRAccountLoginClusterLoginParams(node: \(node as Optional<Any>), serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), setupPIN: \(setupPIN as Optional<Any>), tempAccountIdentifier: \(tempAccountIdentifier as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}
open class MTRAccountLoginClusterLogoutParams: NSObject {
    public var node: NSNumber?
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRAccountLoginClusterLogoutParams(node: \(node as Optional<Any>), serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}
open class MTRActionsClusterActionFailedEvent: NSObject {
    public var actionID: NSNumber = 0
    public var error: NSNumber = 0
    public var invokeID: NSNumber = 0
    public var newState: NSNumber = 0
    public override init() { super.init() }
    public override var description: String {
        "MTRActionsClusterActionFailedEvent(actionID: \(actionID as Optional<Any>), error: \(error as Optional<Any>), invokeID: \(invokeID as Optional<Any>), newState: \(newState as Optional<Any>))"
    }
}
open class MTRActionsClusterActionStruct: NSObject {
    public var actionID: NSNumber = 0
    public var endpointListID: NSNumber = 0
    public var name: String = ""
    public var state: NSNumber = 0
    public var supportedCommands: NSNumber = 0
    public var `type`: NSNumber = 0
    public override init() { super.init() }
    public override var description: String {
        "MTRActionsClusterActionStruct(actionID: \(actionID as Optional<Any>), endpointListID: \(endpointListID as Optional<Any>), name: \(name as Optional<Any>), state: \(state as Optional<Any>), supportedCommands: \(supportedCommands as Optional<Any>), type: \(`type` as Optional<Any>))"
    }
}
open class MTRActionsClusterDisableActionParams: NSObject {
    public var actionID: NSNumber = 0
    public var invokeID: NSNumber?
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRActionsClusterDisableActionParams(actionID: \(actionID as Optional<Any>), invokeID: \(invokeID as Optional<Any>), serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}
open class MTRActionsClusterDisableActionWithDurationParams: NSObject {
    public var actionID: NSNumber = 0
    public var duration: NSNumber = 0
    public var invokeID: NSNumber?
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRActionsClusterDisableActionWithDurationParams(actionID: \(actionID as Optional<Any>), duration: \(duration as Optional<Any>), invokeID: \(invokeID as Optional<Any>), serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}
open class MTRActionsClusterEnableActionParams: NSObject {
    public var actionID: NSNumber = 0
    public var invokeID: NSNumber?
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRActionsClusterEnableActionParams(actionID: \(actionID as Optional<Any>), invokeID: \(invokeID as Optional<Any>), serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}
open class MTRActionsClusterEnableActionWithDurationParams: NSObject {
    public var actionID: NSNumber = 0
    public var duration: NSNumber = 0
    public var invokeID: NSNumber?
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRActionsClusterEnableActionWithDurationParams(actionID: \(actionID as Optional<Any>), duration: \(duration as Optional<Any>), invokeID: \(invokeID as Optional<Any>), serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}
open class MTRActionsClusterEndpointListStruct: NSObject {
    public var endpointListID: NSNumber = 0
    public var endpoints: [Any] = []
    public var name: String = ""
    public var `type`: NSNumber = 0
    public override init() { super.init() }
    public override var description: String {
        "MTRActionsClusterEndpointListStruct(endpointListID: \(endpointListID as Optional<Any>), endpoints: \(endpoints as Optional<Any>), name: \(name as Optional<Any>), type: \(`type` as Optional<Any>))"
    }
}
open class MTRActionsClusterInstantActionParams: NSObject {
    public var actionID: NSNumber = 0
    public var invokeID: NSNumber?
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRActionsClusterInstantActionParams(actionID: \(actionID as Optional<Any>), invokeID: \(invokeID as Optional<Any>), serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}
open class MTRActionsClusterInstantActionWithTransitionParams: NSObject {
    public var actionID: NSNumber = 0
    public var invokeID: NSNumber?
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public var transitionTime: NSNumber = 0
    public override init() { super.init() }
    public override var description: String {
        "MTRActionsClusterInstantActionWithTransitionParams(actionID: \(actionID as Optional<Any>), invokeID: \(invokeID as Optional<Any>), serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>), transitionTime: \(transitionTime as Optional<Any>))"
    }
}
open class MTRActionsClusterPauseActionParams: NSObject {
    public var actionID: NSNumber = 0
    public var invokeID: NSNumber?
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRActionsClusterPauseActionParams(actionID: \(actionID as Optional<Any>), invokeID: \(invokeID as Optional<Any>), serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}
open class MTRActionsClusterPauseActionWithDurationParams: NSObject {
    public var actionID: NSNumber = 0
    public var duration: NSNumber = 0
    public var invokeID: NSNumber?
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRActionsClusterPauseActionWithDurationParams(actionID: \(actionID as Optional<Any>), duration: \(duration as Optional<Any>), invokeID: \(invokeID as Optional<Any>), serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}
open class MTRActionsClusterResumeActionParams: NSObject {
    public var actionID: NSNumber = 0
    public var invokeID: NSNumber?
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRActionsClusterResumeActionParams(actionID: \(actionID as Optional<Any>), invokeID: \(invokeID as Optional<Any>), serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}
open class MTRActionsClusterStartActionParams: NSObject {
    public var actionID: NSNumber = 0
    public var invokeID: NSNumber?
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRActionsClusterStartActionParams(actionID: \(actionID as Optional<Any>), invokeID: \(invokeID as Optional<Any>), serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}
open class MTRActionsClusterStartActionWithDurationParams: NSObject {
    public var actionID: NSNumber = 0
    public var duration: NSNumber = 0
    public var invokeID: NSNumber?
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRActionsClusterStartActionWithDurationParams(actionID: \(actionID as Optional<Any>), duration: \(duration as Optional<Any>), invokeID: \(invokeID as Optional<Any>), serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}
open class MTRActionsClusterStateChangedEvent: NSObject {
    public var actionID: NSNumber = 0
    public var invokeID: NSNumber = 0
    public var newState: NSNumber = 0
    public override init() { super.init() }
    public override var description: String {
        "MTRActionsClusterStateChangedEvent(actionID: \(actionID as Optional<Any>), invokeID: \(invokeID as Optional<Any>), newState: \(newState as Optional<Any>))"
    }
}
open class MTRActionsClusterStopActionParams: NSObject {
    public var actionID: NSNumber = 0
    public var invokeID: NSNumber?
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRActionsClusterStopActionParams(actionID: \(actionID as Optional<Any>), invokeID: \(invokeID as Optional<Any>), serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}
open class MTRActivatedCarbonFilterMonitoringClusterReplacementProductStruct: NSObject {
    public var productIdentifierType: NSNumber = 0
    public var productIdentifierValue: String = ""
    public override init() { super.init() }
    public override var description: String {
        "MTRActivatedCarbonFilterMonitoringClusterReplacementProductStruct(productIdentifierType: \(productIdentifierType as Optional<Any>), productIdentifierValue: \(productIdentifierValue as Optional<Any>))"
    }
}
open class MTRActivatedCarbonFilterMonitoringClusterResetConditionParams: NSObject {
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRActivatedCarbonFilterMonitoringClusterResetConditionParams(serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}
open class MTRAdministratorCommissioningClusterOpenBasicCommissioningWindowParams: NSObject {
    public var commissioningTimeout: NSNumber = 0
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRAdministratorCommissioningClusterOpenBasicCommissioningWindowParams(commissioningTimeout: \(commissioningTimeout as Optional<Any>), serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}
open class MTRAdministratorCommissioningClusterOpenCommissioningWindowParams: NSObject {
    public var commissioningTimeout: NSNumber = 0
    public var discriminator: NSNumber = 0
    public var iterations: NSNumber = 0
    public var pakePasscodeVerifier: Data = Data()
    public var pakeVerifier: Data = Data()
    public var salt: Data = Data()
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRAdministratorCommissioningClusterOpenCommissioningWindowParams(commissioningTimeout: \(commissioningTimeout as Optional<Any>), discriminator: \(discriminator as Optional<Any>), iterations: \(iterations as Optional<Any>), pakePasscodeVerifier: \(pakePasscodeVerifier as Optional<Any>), pakeVerifier: \(pakeVerifier as Optional<Any>), salt: \(salt as Optional<Any>), serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}
open class MTRAdministratorCommissioningClusterRevokeCommissioningParams: NSObject {
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRAdministratorCommissioningClusterRevokeCommissioningParams(serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}
open class MTRApplicationBasicClusterApplicationStruct: NSObject {
    public var applicationID: String = ""
    public var applicationId: String = ""
    public var catalogVendorID: NSNumber = 0
    public var catalogVendorId: NSNumber = 0
    public override init() { super.init() }
    public override var description: String {
        "MTRApplicationBasicClusterApplicationStruct(applicationID: \(applicationID as Optional<Any>), applicationId: \(applicationId as Optional<Any>), catalogVendorID: \(catalogVendorID as Optional<Any>), catalogVendorId: \(catalogVendorId as Optional<Any>))"
    }
}
open class MTRApplicationLauncherClusterApplicationEPStruct: NSObject {
    public var application: MTRApplicationLauncherClusterApplicationStruct = MTRApplicationLauncherClusterApplicationStruct()
    public var endpoint: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRApplicationLauncherClusterApplicationEPStruct(application: \(application as Optional<Any>), endpoint: \(endpoint as Optional<Any>))"
    }
}
open class MTRApplicationLauncherClusterApplicationStruct: NSObject {
    public var applicationID: String = ""
    public var applicationId: String = ""
    public var catalogVendorID: NSNumber = 0
    public var catalogVendorId: NSNumber = 0
    public override init() { super.init() }
    public override var description: String {
        "MTRApplicationLauncherClusterApplicationStruct(applicationID: \(applicationID as Optional<Any>), applicationId: \(applicationId as Optional<Any>), catalogVendorID: \(catalogVendorID as Optional<Any>), catalogVendorId: \(catalogVendorId as Optional<Any>))"
    }
}
open class MTRApplicationLauncherClusterHideAppParams: NSObject {
    public var application: MTRApplicationLauncherClusterApplicationStruct?
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRApplicationLauncherClusterHideAppParams(application: \(application as Optional<Any>), serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}
open class MTRApplicationLauncherClusterLaunchAppParams: NSObject {
    public var application: MTRApplicationLauncherClusterApplicationStruct?
    public var data: Data?
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRApplicationLauncherClusterLaunchAppParams(application: \(application as Optional<Any>), data: \(data as Optional<Any>), serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}
open class MTRApplicationLauncherClusterLauncherResponseParams: NSObject {
    public init(responseValue: [String : Any]) throws {
        if let err = responseValue[MTRErrorKey] as? (any Error) {
            throw err
        }
        super.init()
        _ = responseValue[MTRDataKey] as? [String: Any]
    }
    public var data: Data?
    public var status: NSNumber = 0
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRApplicationLauncherClusterLauncherResponseParams(data: \(data as Optional<Any>), status: \(status as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}
open class MTRApplicationLauncherClusterStopAppParams: NSObject {
    public var application: MTRApplicationLauncherClusterApplicationStruct?
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRApplicationLauncherClusterStopAppParams(application: \(application as Optional<Any>), serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}
open class MTRAudioOutputClusterOutputInfoStruct: NSObject {
    public var index: NSNumber = 0
    public var name: String = ""
    public var outputType: NSNumber = 0
    public override init() { super.init() }
    public override var description: String {
        "MTRAudioOutputClusterOutputInfoStruct(index: \(index as Optional<Any>), name: \(name as Optional<Any>), outputType: \(outputType as Optional<Any>))"
    }
}
open class MTRAudioOutputClusterRenameOutputParams: NSObject {
    public var index: NSNumber = 0
    public var name: String = ""
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRAudioOutputClusterRenameOutputParams(index: \(index as Optional<Any>), name: \(name as Optional<Any>), serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}
open class MTRAudioOutputClusterSelectOutputParams: NSObject {
    public var index: NSNumber = 0
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRAudioOutputClusterSelectOutputParams(index: \(index as Optional<Any>), serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}
open class MTRBarrierControlClusterBarrierControlGoToPercentParams: NSObject {
    public var percentOpen: NSNumber = 0
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRBarrierControlClusterBarrierControlGoToPercentParams(percentOpen: \(percentOpen as Optional<Any>), serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}
open class MTRBarrierControlClusterBarrierControlStopParams: NSObject {
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRBarrierControlClusterBarrierControlStopParams(serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}
open class MTRBasicClusterMfgSpecificPingParams: NSObject {
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRBasicClusterMfgSpecificPingParams(serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}
open class MTRBasicInformationClusterCapabilityMinimaStruct: NSObject {
    public var caseSessionsPerFabric: NSNumber = 0
    public var subscriptionsPerFabric: NSNumber = 0
    public override init() { super.init() }
    public override var description: String {
        "MTRBasicInformationClusterCapabilityMinimaStruct(caseSessionsPerFabric: \(caseSessionsPerFabric as Optional<Any>), subscriptionsPerFabric: \(subscriptionsPerFabric as Optional<Any>))"
    }
}
open class MTRBasicInformationClusterLeaveEvent: NSObject {
    public var fabricIndex: NSNumber = 0
    public override init() { super.init() }
    public override var description: String {
        "MTRBasicInformationClusterLeaveEvent(fabricIndex: \(fabricIndex as Optional<Any>))"
    }
}
open class MTRBasicInformationClusterProductAppearanceStruct: NSObject {
    public var finish: NSNumber = 0
    public var primaryColor: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRBasicInformationClusterProductAppearanceStruct(finish: \(finish as Optional<Any>), primaryColor: \(primaryColor as Optional<Any>))"
    }
}
open class MTRBasicInformationClusterReachableChangedEvent: NSObject {
    public var reachableNewValue: NSNumber = 0
    public override init() { super.init() }
    public override var description: String {
        "MTRBasicInformationClusterReachableChangedEvent(reachableNewValue: \(reachableNewValue as Optional<Any>))"
    }
}
open class MTRBasicInformationClusterStartUpEvent: NSObject {
    public var softwareVersion: NSNumber = 0
    public override init() { super.init() }
    public override var description: String {
        "MTRBasicInformationClusterStartUpEvent(softwareVersion: \(softwareVersion as Optional<Any>))"
    }
}
open class MTRBindingClusterTargetStruct: NSObject {
    public var cluster: NSNumber?
    public var endpoint: NSNumber?
    public var fabricIndex: NSNumber = 0
    public var group: NSNumber?
    public var node: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRBindingClusterTargetStruct(cluster: \(cluster as Optional<Any>), endpoint: \(endpoint as Optional<Any>), fabricIndex: \(fabricIndex as Optional<Any>), group: \(group as Optional<Any>), node: \(node as Optional<Any>))"
    }
}
open class MTRBooleanStateClusterStateChangeEvent: NSObject {
    public var stateValue: NSNumber = 0
    public override init() { super.init() }
    public override var description: String {
        "MTRBooleanStateClusterStateChangeEvent(stateValue: \(stateValue as Optional<Any>))"
    }
}
open class MTRBooleanStateConfigurationClusterAlarmsStateChangedEvent: NSObject {
    public var alarmsActive: NSNumber = 0
    public var alarmsSuppressed: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRBooleanStateConfigurationClusterAlarmsStateChangedEvent(alarmsActive: \(alarmsActive as Optional<Any>), alarmsSuppressed: \(alarmsSuppressed as Optional<Any>))"
    }
}
open class MTRBooleanStateConfigurationClusterEnableDisableAlarmParams: NSObject {
    public var alarmsToEnableDisable: NSNumber = 0
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRBooleanStateConfigurationClusterEnableDisableAlarmParams(alarmsToEnableDisable: \(alarmsToEnableDisable as Optional<Any>), serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}
open class MTRBooleanStateConfigurationClusterSensorFaultEvent: NSObject {
    public var sensorFault: NSNumber = 0
    public override init() { super.init() }
    public override var description: String {
        "MTRBooleanStateConfigurationClusterSensorFaultEvent(sensorFault: \(sensorFault as Optional<Any>))"
    }
}
open class MTRBooleanStateConfigurationClusterSuppressAlarmParams: NSObject {
    public var alarmsToSuppress: NSNumber = 0
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRBooleanStateConfigurationClusterSuppressAlarmParams(alarmsToSuppress: \(alarmsToSuppress as Optional<Any>), serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}
open class MTRBridgedDeviceBasicInformationClusterActiveChangedEvent: NSObject {
    public var promisedActiveDuration: NSNumber = 0
    public override init() { super.init() }
    public override var description: String {
        "MTRBridgedDeviceBasicInformationClusterActiveChangedEvent(promisedActiveDuration: \(promisedActiveDuration as Optional<Any>))"
    }
}
open class MTRBridgedDeviceBasicInformationClusterKeepActiveParams: NSObject {
    public var serverSideProcessingTimeout: NSNumber?
    public var stayActiveDuration: NSNumber = 0
    public var timedInvokeTimeoutMs: NSNumber?
    public var timeoutMs: NSNumber = 0
    public override init() { super.init() }
    public override var description: String {
        "MTRBridgedDeviceBasicInformationClusterKeepActiveParams(serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), stayActiveDuration: \(stayActiveDuration as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>), timeoutMs: \(timeoutMs as Optional<Any>))"
    }
}
open class MTRBridgedDeviceBasicInformationClusterProductAppearanceStruct: NSObject {
    public var finish: NSNumber = 0
    public var primaryColor: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRBridgedDeviceBasicInformationClusterProductAppearanceStruct(finish: \(finish as Optional<Any>), primaryColor: \(primaryColor as Optional<Any>))"
    }
}
open class MTRBridgedDeviceBasicInformationClusterReachableChangedEvent: NSObject {
    public var reachableNewValue: NSNumber = 0
    public override init() { super.init() }
    public override var description: String {
        "MTRBridgedDeviceBasicInformationClusterReachableChangedEvent(reachableNewValue: \(reachableNewValue as Optional<Any>))"
    }
}
open class MTRBridgedDeviceBasicInformationClusterStartUpEvent: NSObject {
    public var softwareVersion: NSNumber = 0
    public override init() { super.init() }
    public override var description: String {
        "MTRBridgedDeviceBasicInformationClusterStartUpEvent(softwareVersion: \(softwareVersion as Optional<Any>))"
    }
}
open class MTRChannelClusterCancelRecordProgramParams: NSObject {
    public var data: Data = Data()
    public var programIdentifier: String = ""
    public var serverSideProcessingTimeout: NSNumber?
    public var shouldRecordSeries: NSNumber = 0
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRChannelClusterCancelRecordProgramParams(data: \(data as Optional<Any>), programIdentifier: \(programIdentifier as Optional<Any>), serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), shouldRecordSeries: \(shouldRecordSeries as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}
open class MTRChannelClusterChangeChannelByNumberParams: NSObject {
    public var majorNumber: NSNumber = 0
    public var minorNumber: NSNumber = 0
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRChannelClusterChangeChannelByNumberParams(majorNumber: \(majorNumber as Optional<Any>), minorNumber: \(minorNumber as Optional<Any>), serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}
open class MTRChannelClusterChangeChannelParams: NSObject {
    public var match: String = ""
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRChannelClusterChangeChannelParams(match: \(match as Optional<Any>), serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}
open class MTRChannelClusterChangeChannelResponseParams: NSObject {
    public init(responseValue: [String : Any]) throws {
        if let err = responseValue[MTRErrorKey] as? (any Error) {
            throw err
        }
        super.init()
        _ = responseValue[MTRDataKey] as? [String: Any]
    }
    public var data: String?
    public var status: NSNumber = 0
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRChannelClusterChangeChannelResponseParams(data: \(data as Optional<Any>), status: \(status as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}
open class MTRChannelClusterChannelInfoStruct: NSObject {
    public var affiliateCallSign: String?
    public var callSign: String?
    public var identifier: String?
    public var majorNumber: NSNumber = 0
    public var minorNumber: NSNumber = 0
    public var name: String?
    public var `type`: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRChannelClusterChannelInfoStruct(affiliateCallSign: \(affiliateCallSign as Optional<Any>), callSign: \(callSign as Optional<Any>), identifier: \(identifier as Optional<Any>), majorNumber: \(majorNumber as Optional<Any>), minorNumber: \(minorNumber as Optional<Any>), name: \(name as Optional<Any>), type: \(`type` as Optional<Any>))"
    }
}
open class MTRChannelClusterChannelPagingStruct: NSObject {
    public var nextToken: MTRChannelClusterPageTokenStruct?
    public var previousToken: MTRChannelClusterPageTokenStruct?
    public override init() { super.init() }
    public override var description: String {
        "MTRChannelClusterChannelPagingStruct(nextToken: \(nextToken as Optional<Any>), previousToken: \(previousToken as Optional<Any>))"
    }
}
open class MTRChannelClusterGetProgramGuideParams: NSObject {
    public var channelList: [Any]?
    public var data: Data?
    public var endTime: NSNumber?
    public var pageToken: MTRChannelClusterPageTokenStruct?
    public var recordingFlag: NSNumber?
    public var serverSideProcessingTimeout: NSNumber?
    public var startTime: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRChannelClusterGetProgramGuideParams(channelList: \(channelList as Optional<Any>), data: \(data as Optional<Any>), endTime: \(endTime as Optional<Any>), pageToken: \(pageToken as Optional<Any>), recordingFlag: \(recordingFlag as Optional<Any>), serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), startTime: \(startTime as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}
open class MTRChannelClusterLineupInfoStruct: NSObject {
    public var lineupInfoType: NSNumber = 0
    public var lineupName: String?
    public var operatorName: String = ""
    public var postalCode: String?
    public override init() { super.init() }
    public override var description: String {
        "MTRChannelClusterLineupInfoStruct(lineupInfoType: \(lineupInfoType as Optional<Any>), lineupName: \(lineupName as Optional<Any>), operatorName: \(operatorName as Optional<Any>), postalCode: \(postalCode as Optional<Any>))"
    }
}
open class MTRChannelClusterPageTokenStruct: NSObject {
    public var after: String?
    public var before: String?
    public var limit: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRChannelClusterPageTokenStruct(after: \(after as Optional<Any>), before: \(before as Optional<Any>), limit: \(limit as Optional<Any>))"
    }
}
open class MTRChannelClusterProgramCastStruct: NSObject {
    public var name: String = ""
    public var role: String = ""
    public override init() { super.init() }
    public override var description: String {
        "MTRChannelClusterProgramCastStruct(name: \(name as Optional<Any>), role: \(role as Optional<Any>))"
    }
}
open class MTRChannelClusterProgramCategoryStruct: NSObject {
    public var category: String = ""
    public var subCategory: String?
    public override init() { super.init() }
    public override var description: String {
        "MTRChannelClusterProgramCategoryStruct(category: \(category as Optional<Any>), subCategory: \(subCategory as Optional<Any>))"
    }
}
open class MTRChannelClusterProgramGuideResponseParams: NSObject {
    public init(responseValue: [String : Any]) throws {
        if let err = responseValue[MTRErrorKey] as? (any Error) {
            throw err
        }
        super.init()
        _ = responseValue[MTRDataKey] as? [String: Any]
    }
    public var paging: MTRChannelClusterChannelPagingStruct = MTRChannelClusterChannelPagingStruct()
    public var programList: [Any] = []
    public override init() { super.init() }
    public override var description: String {
        "MTRChannelClusterProgramGuideResponseParams(paging: \(paging as Optional<Any>), programList: \(programList as Optional<Any>))"
    }
}
open class MTRChannelClusterProgramStruct: NSObject {
    public var audioLanguages: [Any]?
    public var castList: [Any]?
    public var categoryList: [Any]?
    public var channel: MTRChannelClusterChannelInfoStruct = MTRChannelClusterChannelInfoStruct()
    public var descriptionString: String?
    public var endTime: NSNumber = 0
    public var identifier: String = ""
    public var parentalGuidanceText: String?
    public var ratings: [Any]?
    public var recordingFlag: NSNumber?
    public var releaseDate: String?
    public var seriesInfo: MTRChannelClusterSeriesInfoStruct?
    public var startTime: NSNumber = 0
    public var subtitle: String?
    public var title: String = ""
    public override init() { super.init() }
    public override var description: String {
        "MTRChannelClusterProgramStruct(audioLanguages: \(audioLanguages as Optional<Any>), castList: \(castList as Optional<Any>), categoryList: \(categoryList as Optional<Any>), channel: \(channel as Optional<Any>), descriptionString: \(descriptionString as Optional<Any>), endTime: \(endTime as Optional<Any>), identifier: \(identifier as Optional<Any>), parentalGuidanceText: \(parentalGuidanceText as Optional<Any>), ratings: \(ratings as Optional<Any>), recordingFlag: \(recordingFlag as Optional<Any>), releaseDate: \(releaseDate as Optional<Any>), seriesInfo: \(seriesInfo as Optional<Any>), startTime: \(startTime as Optional<Any>), subtitle: \(subtitle as Optional<Any>), title: \(title as Optional<Any>))"
    }
}
open class MTRChannelClusterRecordProgramParams: NSObject {
    public var data: Data = Data()
    public var programIdentifier: String = ""
    public var serverSideProcessingTimeout: NSNumber?
    public var shouldRecordSeries: NSNumber = 0
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRChannelClusterRecordProgramParams(data: \(data as Optional<Any>), programIdentifier: \(programIdentifier as Optional<Any>), serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), shouldRecordSeries: \(shouldRecordSeries as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}
open class MTRChannelClusterSeriesInfoStruct: NSObject {
    public var episode: String = ""
    public var season: String = ""
    public override init() { super.init() }
    public override var description: String {
        "MTRChannelClusterSeriesInfoStruct(episode: \(episode as Optional<Any>), season: \(season as Optional<Any>))"
    }
}
open class MTRChannelClusterSkipChannelParams: NSObject {
    public var count: NSNumber = 0
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRChannelClusterSkipChannelParams(count: \(count as Optional<Any>), serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}
open class MTRCommissionerControlClusterCommissionNodeParams: NSObject {
    public var requestID: NSNumber = 0
    public var responseTimeoutSeconds: NSNumber = 0
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRCommissionerControlClusterCommissionNodeParams(requestID: \(requestID as Optional<Any>), responseTimeoutSeconds: \(responseTimeoutSeconds as Optional<Any>), serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}
open class MTRCommissionerControlClusterCommissioningRequestResultEvent: NSObject {
    public var clientNodeID: NSNumber = 0
    public var fabricIndex: NSNumber = 0
    public var requestID: NSNumber = 0
    public var statusCode: NSNumber = 0
    public override init() { super.init() }
    public override var description: String {
        "MTRCommissionerControlClusterCommissioningRequestResultEvent(clientNodeID: \(clientNodeID as Optional<Any>), fabricIndex: \(fabricIndex as Optional<Any>), requestID: \(requestID as Optional<Any>), statusCode: \(statusCode as Optional<Any>))"
    }
}
open class MTRCommissionerControlClusterRequestCommissioningApprovalParams: NSObject {
    public var label: String?
    public var productID: NSNumber = 0
    public var requestID: NSNumber = 0
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public var vendorID: NSNumber = 0
    public override init() { super.init() }
    public override var description: String {
        "MTRCommissionerControlClusterRequestCommissioningApprovalParams(label: \(label as Optional<Any>), productID: \(productID as Optional<Any>), requestID: \(requestID as Optional<Any>), serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>), vendorID: \(vendorID as Optional<Any>))"
    }
}
open class MTRCommissionerControlClusterReverseOpenCommissioningWindowParams: NSObject {
    public init(responseValue: [String : Any]) throws {
        if let err = responseValue[MTRErrorKey] as? (any Error) {
            throw err
        }
        super.init()
        _ = responseValue[MTRDataKey] as? [String: Any]
    }
    public var commissioningTimeout: NSNumber = 0
    public var discriminator: NSNumber = 0
    public var iterations: NSNumber = 0
    public var pakePasscodeVerifier: Data = Data()
    public var salt: Data = Data()
    public override init() { super.init() }
    public override var description: String {
        "MTRCommissionerControlClusterReverseOpenCommissioningWindowParams(commissioningTimeout: \(commissioningTimeout as Optional<Any>), discriminator: \(discriminator as Optional<Any>), iterations: \(iterations as Optional<Any>), pakePasscodeVerifier: \(pakePasscodeVerifier as Optional<Any>), salt: \(salt as Optional<Any>))"
    }
}
open class MTRContentAppObserverClusterContentAppMessageParams: NSObject {
    public var data: String?
    public var encodingHint: String = ""
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRContentAppObserverClusterContentAppMessageParams(data: \(data as Optional<Any>), encodingHint: \(encodingHint as Optional<Any>), serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}
open class MTRContentAppObserverClusterContentAppMessageResponseParams: NSObject {
    public init(responseValue: [String : Any]) throws {
        if let err = responseValue[MTRErrorKey] as? (any Error) {
            throw err
        }
        super.init()
        _ = responseValue[MTRDataKey] as? [String: Any]
    }
    public var data: String?
    public var encodingHint: String?
    public var status: NSNumber = 0
    public override init() { super.init() }
    public override var description: String {
        "MTRContentAppObserverClusterContentAppMessageResponseParams(data: \(data as Optional<Any>), encodingHint: \(encodingHint as Optional<Any>), status: \(status as Optional<Any>))"
    }
}
open class MTRContentLauncherClusterAdditionalInfoStruct: NSObject {
    public var name: String = ""
    public var value: String = ""
    public override init() { super.init() }
    public override var description: String {
        "MTRContentLauncherClusterAdditionalInfoStruct(name: \(name as Optional<Any>), value: \(value as Optional<Any>))"
    }
}
open class MTRContentLauncherClusterBrandingInformationStruct: NSObject {
    public var background: MTRContentLauncherClusterStyleInformationStruct?
    public var logo: MTRContentLauncherClusterStyleInformationStruct?
    public var progressBar: MTRContentLauncherClusterStyleInformationStruct?
    public var providerName: String = ""
    public var splash: MTRContentLauncherClusterStyleInformationStruct?
    public var waterMark: MTRContentLauncherClusterStyleInformationStruct?
    public override init() { super.init() }
    public override var description: String {
        "MTRContentLauncherClusterBrandingInformationStruct(background: \(background as Optional<Any>), logo: \(logo as Optional<Any>), progressBar: \(progressBar as Optional<Any>), providerName: \(providerName as Optional<Any>), splash: \(splash as Optional<Any>), waterMark: \(waterMark as Optional<Any>))"
    }
}
open class MTRContentLauncherClusterContentSearchStruct: NSObject {
    public var parameterList: [Any] = []
    public override init() { super.init() }
    public override var description: String {
        "MTRContentLauncherClusterContentSearchStruct(parameterList: \(parameterList as Optional<Any>))"
    }
}
open class MTRContentLauncherClusterDimensionStruct: NSObject {
    public var height: NSNumber = 0
    public var metric: NSNumber = 0
    public var width: NSNumber = 0
    public override init() { super.init() }
    public override var description: String {
        "MTRContentLauncherClusterDimensionStruct(height: \(height as Optional<Any>), metric: \(metric as Optional<Any>), width: \(width as Optional<Any>))"
    }
}
open class MTRContentLauncherClusterLaunchContentParams: NSObject {
    public var autoPlay: NSNumber = 0
    public var data: String?
    public var search: MTRContentLauncherClusterContentSearchStruct = MTRContentLauncherClusterContentSearchStruct()
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public var useCurrentContext: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRContentLauncherClusterLaunchContentParams(autoPlay: \(autoPlay as Optional<Any>), data: \(data as Optional<Any>), search: \(search as Optional<Any>), serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>), useCurrentContext: \(useCurrentContext as Optional<Any>))"
    }
}
open class MTRContentLauncherClusterLaunchURLParams: NSObject {
    public var brandingInformation: MTRContentLauncherClusterBrandingInformationStruct?
    public var contentURL: String = ""
    public var displayString: String?
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRContentLauncherClusterLaunchURLParams(brandingInformation: \(brandingInformation as Optional<Any>), contentURL: \(contentURL as Optional<Any>), displayString: \(displayString as Optional<Any>), serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}
open class MTRContentLauncherClusterLauncherResponseParams: NSObject {
    public init(responseValue: [String : Any]) throws {
        if let err = responseValue[MTRErrorKey] as? (any Error) {
            throw err
        }
        super.init()
        _ = responseValue[MTRDataKey] as? [String: Any]
    }
    public var data: String?
    public var status: NSNumber = 0
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRContentLauncherClusterLauncherResponseParams(data: \(data as Optional<Any>), status: \(status as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}
open class MTRContentLauncherClusterParameterStruct: NSObject {
    public var externalIDList: [Any]?
    public var `type`: NSNumber = 0
    public var value: String = ""
    public override init() { super.init() }
    public override var description: String {
        "MTRContentLauncherClusterParameterStruct(externalIDList: \(externalIDList as Optional<Any>), type: \(`type` as Optional<Any>), value: \(value as Optional<Any>))"
    }
}
open class MTRContentLauncherClusterStyleInformationStruct: NSObject {
    public var color: String?
    public var imageURL: String?
    public var imageUrl: String?
    public var size: MTRContentLauncherClusterDimensionStruct?
    public override init() { super.init() }
    public override var description: String {
        "MTRContentLauncherClusterStyleInformationStruct(color: \(color as Optional<Any>), imageURL: \(imageURL as Optional<Any>), imageUrl: \(imageUrl as Optional<Any>), size: \(size as Optional<Any>))"
    }
}
open class MTRDataTypeAtomicAttributeStatusStruct: NSObject {
    public var attributeID: NSNumber = 0
    public var statusCode: NSNumber = 0
    public override init() { super.init() }
    public override var description: String {
        "MTRDataTypeAtomicAttributeStatusStruct(attributeID: \(attributeID as Optional<Any>), statusCode: \(statusCode as Optional<Any>))"
    }
}
open class MTRDataTypeLocationDescriptorStruct: NSObject {
    public var areaType: NSNumber?
    public var floorNumber: NSNumber?
    public var locationName: String = ""
    public override init() { super.init() }
    public override var description: String {
        "MTRDataTypeLocationDescriptorStruct(areaType: \(areaType as Optional<Any>), floorNumber: \(floorNumber as Optional<Any>), locationName: \(locationName as Optional<Any>))"
    }
}
open class MTRDescriptorClusterDeviceTypeStruct: NSObject {
    public var deviceType: NSNumber = 0
    public var revision: NSNumber = 0
    public var `type`: NSNumber = 0
    public override init() { super.init() }
    public override var description: String {
        "MTRDescriptorClusterDeviceTypeStruct(deviceType: \(deviceType as Optional<Any>), revision: \(revision as Optional<Any>), type: \(`type` as Optional<Any>))"
    }
}
open class MTRDeviceEnergyManagementClusterCancelPowerAdjustRequestParams: NSObject {
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRDeviceEnergyManagementClusterCancelPowerAdjustRequestParams(serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}
open class MTRDeviceEnergyManagementClusterCancelRequestParams: NSObject {
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRDeviceEnergyManagementClusterCancelRequestParams(serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}
open class MTRDeviceEnergyManagementClusterConstraintsStruct: NSObject {
    public var duration: NSNumber = 0
    public var loadControl: NSNumber?
    public var maximumEnergy: NSNumber?
    public var nominalPower: NSNumber?
    public var startTime: NSNumber = 0
    public override init() { super.init() }
    public override var description: String {
        "MTRDeviceEnergyManagementClusterConstraintsStruct(duration: \(duration as Optional<Any>), loadControl: \(loadControl as Optional<Any>), maximumEnergy: \(maximumEnergy as Optional<Any>), nominalPower: \(nominalPower as Optional<Any>), startTime: \(startTime as Optional<Any>))"
    }
}
open class MTRDeviceEnergyManagementClusterCostStruct: NSObject {
    public var costType: NSNumber = 0
    public var currency: NSNumber?
    public var decimalPoints: NSNumber = 0
    public var value: NSNumber = 0
    public override init() { super.init() }
    public override var description: String {
        "MTRDeviceEnergyManagementClusterCostStruct(costType: \(costType as Optional<Any>), currency: \(currency as Optional<Any>), decimalPoints: \(decimalPoints as Optional<Any>), value: \(value as Optional<Any>))"
    }
}
open class MTRDeviceEnergyManagementClusterForecastStruct: NSObject {
    public var activeSlotNumber: NSNumber?
    public var earliestStartTime: NSNumber?
    public var endTime: NSNumber = 0
    public var forecastID: NSNumber = 0
    public var forecastUpdateReason: NSNumber = 0
    public var isPausable: NSNumber = 0
    public var latestEndTime: NSNumber?
    public var slots: [Any] = []
    public var startTime: NSNumber = 0
    public override init() { super.init() }
    public override var description: String {
        "MTRDeviceEnergyManagementClusterForecastStruct(activeSlotNumber: \(activeSlotNumber as Optional<Any>), earliestStartTime: \(earliestStartTime as Optional<Any>), endTime: \(endTime as Optional<Any>), forecastID: \(forecastID as Optional<Any>), forecastUpdateReason: \(forecastUpdateReason as Optional<Any>), isPausable: \(isPausable as Optional<Any>), latestEndTime: \(latestEndTime as Optional<Any>), slots: \(slots as Optional<Any>), startTime: \(startTime as Optional<Any>))"
    }
}
open class MTRDeviceEnergyManagementClusterModifyForecastRequestParams: NSObject {
    public var cause: NSNumber = 0
    public var forecastID: NSNumber = 0
    public var serverSideProcessingTimeout: NSNumber?
    public var slotAdjustments: [Any] = []
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRDeviceEnergyManagementClusterModifyForecastRequestParams(cause: \(cause as Optional<Any>), forecastID: \(forecastID as Optional<Any>), serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), slotAdjustments: \(slotAdjustments as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}
open class MTRDeviceEnergyManagementClusterPauseRequestParams: NSObject {
    public var cause: NSNumber = 0
    public var duration: NSNumber = 0
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRDeviceEnergyManagementClusterPauseRequestParams(cause: \(cause as Optional<Any>), duration: \(duration as Optional<Any>), serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}
open class MTRDeviceEnergyManagementClusterPowerAdjustCapabilityStruct: NSObject {
    public var cause: NSNumber = 0
    public var powerAdjustCapability: [Any]?
    public override init() { super.init() }
    public override var description: String {
        "MTRDeviceEnergyManagementClusterPowerAdjustCapabilityStruct(cause: \(cause as Optional<Any>), powerAdjustCapability: \(powerAdjustCapability as Optional<Any>))"
    }
}
open class MTRDeviceEnergyManagementClusterPowerAdjustEndEvent: NSObject {
    public var cause: NSNumber = 0
    public var duration: NSNumber = 0
    public var energyUse: NSNumber = 0
    public override init() { super.init() }
    public override var description: String {
        "MTRDeviceEnergyManagementClusterPowerAdjustEndEvent(cause: \(cause as Optional<Any>), duration: \(duration as Optional<Any>), energyUse: \(energyUse as Optional<Any>))"
    }
}
open class MTRDeviceEnergyManagementClusterPowerAdjustRequestParams: NSObject {
    public var cause: NSNumber = 0
    public var duration: NSNumber = 0
    public var power: NSNumber = 0
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRDeviceEnergyManagementClusterPowerAdjustRequestParams(cause: \(cause as Optional<Any>), duration: \(duration as Optional<Any>), power: \(power as Optional<Any>), serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}
open class MTRDeviceEnergyManagementClusterPowerAdjustStruct: NSObject {
    public var maxDuration: NSNumber = 0
    public var maxPower: NSNumber = 0
    public var minDuration: NSNumber = 0
    public var minPower: NSNumber = 0
    public override init() { super.init() }
    public override var description: String {
        "MTRDeviceEnergyManagementClusterPowerAdjustStruct(maxDuration: \(maxDuration as Optional<Any>), maxPower: \(maxPower as Optional<Any>), minDuration: \(minDuration as Optional<Any>), minPower: \(minPower as Optional<Any>))"
    }
}
open class MTRDeviceEnergyManagementClusterRequestConstraintBasedForecastParams: NSObject {
    public var cause: NSNumber = 0
    public var constraints: [Any] = []
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRDeviceEnergyManagementClusterRequestConstraintBasedForecastParams(cause: \(cause as Optional<Any>), constraints: \(constraints as Optional<Any>), serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}
open class MTRDeviceEnergyManagementClusterResumeRequestParams: NSObject {
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRDeviceEnergyManagementClusterResumeRequestParams(serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}
open class MTRDeviceEnergyManagementClusterResumedEvent: NSObject {
    public var cause: NSNumber = 0
    public override init() { super.init() }
    public override var description: String {
        "MTRDeviceEnergyManagementClusterResumedEvent(cause: \(cause as Optional<Any>))"
    }
}
open class MTRDeviceEnergyManagementClusterSlotAdjustmentStruct: NSObject {
    public var duration: NSNumber = 0
    public var nominalPower: NSNumber?
    public var slotIndex: NSNumber = 0
    public override init() { super.init() }
    public override var description: String {
        "MTRDeviceEnergyManagementClusterSlotAdjustmentStruct(duration: \(duration as Optional<Any>), nominalPower: \(nominalPower as Optional<Any>), slotIndex: \(slotIndex as Optional<Any>))"
    }
}
open class MTRDeviceEnergyManagementClusterSlotStruct: NSObject {
    public var costs: [Any]?
    public var defaultDuration: NSNumber = 0
    public var elapsedSlotTime: NSNumber = 0
    public var manufacturerESAState: NSNumber?
    public var maxDuration: NSNumber = 0
    public var maxDurationAdjustment: NSNumber?
    public var maxPauseDuration: NSNumber?
    public var maxPower: NSNumber?
    public var maxPowerAdjustment: NSNumber?
    public var minDuration: NSNumber = 0
    public var minDurationAdjustment: NSNumber?
    public var minPauseDuration: NSNumber?
    public var minPower: NSNumber?
    public var minPowerAdjustment: NSNumber?
    public var nominalEnergy: NSNumber?
    public var nominalPower: NSNumber?
    public var remainingSlotTime: NSNumber = 0
    public var slotIsPausable: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRDeviceEnergyManagementClusterSlotStruct(costs: \(costs as Optional<Any>), defaultDuration: \(defaultDuration as Optional<Any>), elapsedSlotTime: \(elapsedSlotTime as Optional<Any>), manufacturerESAState: \(manufacturerESAState as Optional<Any>), maxDuration: \(maxDuration as Optional<Any>), maxDurationAdjustment: \(maxDurationAdjustment as Optional<Any>), maxPauseDuration: \(maxPauseDuration as Optional<Any>), maxPower: \(maxPower as Optional<Any>), maxPowerAdjustment: \(maxPowerAdjustment as Optional<Any>), minDuration: \(minDuration as Optional<Any>), minDurationAdjustment: \(minDurationAdjustment as Optional<Any>), minPauseDuration: \(minPauseDuration as Optional<Any>), minPower: \(minPower as Optional<Any>), minPowerAdjustment: \(minPowerAdjustment as Optional<Any>), nominalEnergy: \(nominalEnergy as Optional<Any>), nominalPower: \(nominalPower as Optional<Any>), remainingSlotTime: \(remainingSlotTime as Optional<Any>), slotIsPausable: \(slotIsPausable as Optional<Any>))"
    }
}
open class MTRDeviceEnergyManagementClusterStartTimeAdjustRequestParams: NSObject {
    public var cause: NSNumber = 0
    public var requestedStartTime: NSNumber = 0
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRDeviceEnergyManagementClusterStartTimeAdjustRequestParams(cause: \(cause as Optional<Any>), requestedStartTime: \(requestedStartTime as Optional<Any>), serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}
open class MTRDeviceEnergyManagementModeClusterChangeToModeParams: NSObject {
    public var newMode: NSNumber = 0
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRDeviceEnergyManagementModeClusterChangeToModeParams(newMode: \(newMode as Optional<Any>), serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}
open class MTRDeviceEnergyManagementModeClusterChangeToModeResponseParams: NSObject {
    public init(responseValue: [String : Any]) throws {
        if let err = responseValue[MTRErrorKey] as? (any Error) {
            throw err
        }
        super.init()
        _ = responseValue[MTRDataKey] as? [String: Any]
    }
    public var status: NSNumber = 0
    public var statusText: String?
    public override init() { super.init() }
    public override var description: String {
        "MTRDeviceEnergyManagementModeClusterChangeToModeResponseParams(status: \(status as Optional<Any>), statusText: \(statusText as Optional<Any>))"
    }
}
open class MTRDeviceEnergyManagementModeClusterModeOptionStruct: NSObject {
    public var label: String = ""
    public var mode: NSNumber = 0
    public var modeTags: [Any] = []
    public override init() { super.init() }
    public override var description: String {
        "MTRDeviceEnergyManagementModeClusterModeOptionStruct(label: \(label as Optional<Any>), mode: \(mode as Optional<Any>), modeTags: \(modeTags as Optional<Any>))"
    }
}
open class MTRDeviceEnergyManagementModeClusterModeTagStruct: NSObject {
    public var mfgCode: NSNumber?
    public var value: NSNumber = 0
    public override init() { super.init() }
    public override var description: String {
        "MTRDeviceEnergyManagementModeClusterModeTagStruct(mfgCode: \(mfgCode as Optional<Any>), value: \(value as Optional<Any>))"
    }
}
open class MTRDiagnosticLogsClusterRetrieveLogsRequestParams: NSObject {
    public var intent: NSNumber = 0
    public var requestedProtocol: NSNumber = 0
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public var transferFileDesignator: String?
    public override init() { super.init() }
    public override var description: String {
        "MTRDiagnosticLogsClusterRetrieveLogsRequestParams(intent: \(intent as Optional<Any>), requestedProtocol: \(requestedProtocol as Optional<Any>), serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>), transferFileDesignator: \(transferFileDesignator as Optional<Any>))"
    }
}
open class MTRDiagnosticLogsClusterRetrieveLogsResponseParams: NSObject {
    public init(responseValue: [String : Any]) throws {
        if let err = responseValue[MTRErrorKey] as? (any Error) {
            throw err
        }
        super.init()
        _ = responseValue[MTRDataKey] as? [String: Any]
    }
    public var content: Data = Data()
    public var logContent: Data = Data()
    public var status: NSNumber = 0
    public var timeSinceBoot: NSNumber?
    public var timeStamp: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public var utcTimeStamp: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRDiagnosticLogsClusterRetrieveLogsResponseParams(content: \(content as Optional<Any>), logContent: \(logContent as Optional<Any>), status: \(status as Optional<Any>), timeSinceBoot: \(timeSinceBoot as Optional<Any>), timeStamp: \(timeStamp as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>), utcTimeStamp: \(utcTimeStamp as Optional<Any>))"
    }
}
open class MTRDishwasherAlarmClusterModifyEnabledAlarmsParams: NSObject {
    public var mask: NSNumber = 0
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRDishwasherAlarmClusterModifyEnabledAlarmsParams(mask: \(mask as Optional<Any>), serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}
open class MTRDishwasherAlarmClusterNotifyEvent: NSObject {
    public var active: NSNumber = 0
    public var inactive: NSNumber = 0
    public var mask: NSNumber = 0
    public var state: NSNumber = 0
    public override init() { super.init() }
    public override var description: String {
        "MTRDishwasherAlarmClusterNotifyEvent(active: \(active as Optional<Any>), inactive: \(inactive as Optional<Any>), mask: \(mask as Optional<Any>), state: \(state as Optional<Any>))"
    }
}
open class MTRDishwasherAlarmClusterResetParams: NSObject {
    public var alarms: NSNumber = 0
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRDishwasherAlarmClusterResetParams(alarms: \(alarms as Optional<Any>), serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}
open class MTRDishwasherModeClusterChangeToModeParams: NSObject {
    public var newMode: NSNumber = 0
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRDishwasherModeClusterChangeToModeParams(newMode: \(newMode as Optional<Any>), serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}
open class MTRDishwasherModeClusterChangeToModeResponseParams: NSObject {
    public init(responseValue: [String : Any]) throws {
        if let err = responseValue[MTRErrorKey] as? (any Error) {
            throw err
        }
        super.init()
        _ = responseValue[MTRDataKey] as? [String: Any]
    }
    public var status: NSNumber = 0
    public var statusText: String?
    public override init() { super.init() }
    public override var description: String {
        "MTRDishwasherModeClusterChangeToModeResponseParams(status: \(status as Optional<Any>), statusText: \(statusText as Optional<Any>))"
    }
}
open class MTRDishwasherModeClusterModeOptionStruct: NSObject {
    public var label: String = ""
    public var mode: NSNumber = 0
    public var modeTags: [Any] = []
    public override init() { super.init() }
    public override var description: String {
        "MTRDishwasherModeClusterModeOptionStruct(label: \(label as Optional<Any>), mode: \(mode as Optional<Any>), modeTags: \(modeTags as Optional<Any>))"
    }
}
open class MTRDishwasherModeClusterModeTagStruct: NSObject {
    public var mfgCode: NSNumber?
    public var value: NSNumber = 0
    public override init() { super.init() }
    public override var description: String {
        "MTRDishwasherModeClusterModeTagStruct(mfgCode: \(mfgCode as Optional<Any>), value: \(value as Optional<Any>))"
    }
}
open class MTRElectricalEnergyMeasurementClusterCumulativeEnergyMeasuredEvent: NSObject {
    public var energyExported: MTRElectricalEnergyMeasurementClusterEnergyMeasurementStruct?
    public var energyImported: MTRElectricalEnergyMeasurementClusterEnergyMeasurementStruct?
    public override init() { super.init() }
    public override var description: String {
        "MTRElectricalEnergyMeasurementClusterCumulativeEnergyMeasuredEvent(energyExported: \(energyExported as Optional<Any>), energyImported: \(energyImported as Optional<Any>))"
    }
}
open class MTRElectricalEnergyMeasurementClusterCumulativeEnergyResetStruct: NSObject {
    public var exportedResetSystime: NSNumber?
    public var exportedResetTimestamp: NSNumber?
    public var importedResetSystime: NSNumber?
    public var importedResetTimestamp: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRElectricalEnergyMeasurementClusterCumulativeEnergyResetStruct(exportedResetSystime: \(exportedResetSystime as Optional<Any>), exportedResetTimestamp: \(exportedResetTimestamp as Optional<Any>), importedResetSystime: \(importedResetSystime as Optional<Any>), importedResetTimestamp: \(importedResetTimestamp as Optional<Any>))"
    }
}
open class MTRElectricalEnergyMeasurementClusterEnergyMeasurementStruct: NSObject {
    public var endSystime: NSNumber?
    public var endTimestamp: NSNumber?
    public var energy: NSNumber = 0
    public var startSystime: NSNumber?
    public var startTimestamp: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRElectricalEnergyMeasurementClusterEnergyMeasurementStruct(endSystime: \(endSystime as Optional<Any>), endTimestamp: \(endTimestamp as Optional<Any>), energy: \(energy as Optional<Any>), startSystime: \(startSystime as Optional<Any>), startTimestamp: \(startTimestamp as Optional<Any>))"
    }
}
open class MTRElectricalEnergyMeasurementClusterMeasurementAccuracyRangeStruct: NSObject {
    public var fixedMax: NSNumber?
    public var fixedMin: NSNumber?
    public var fixedTypical: NSNumber?
    public var percentMax: NSNumber?
    public var percentMin: NSNumber?
    public var percentTypical: NSNumber?
    public var rangeMax: NSNumber = 0
    public var rangeMin: NSNumber = 0
    public override init() { super.init() }
    public override var description: String {
        "MTRElectricalEnergyMeasurementClusterMeasurementAccuracyRangeStruct(fixedMax: \(fixedMax as Optional<Any>), fixedMin: \(fixedMin as Optional<Any>), fixedTypical: \(fixedTypical as Optional<Any>), percentMax: \(percentMax as Optional<Any>), percentMin: \(percentMin as Optional<Any>), percentTypical: \(percentTypical as Optional<Any>), rangeMax: \(rangeMax as Optional<Any>), rangeMin: \(rangeMin as Optional<Any>))"
    }
}
open class MTRElectricalEnergyMeasurementClusterMeasurementAccuracyStruct: NSObject {
    public var accuracyRanges: [Any] = []
    public var maxMeasuredValue: NSNumber = 0
    public var measured: NSNumber = 0
    public var measurementType: NSNumber = 0
    public var minMeasuredValue: NSNumber = 0
    public override init() { super.init() }
    public override var description: String {
        "MTRElectricalEnergyMeasurementClusterMeasurementAccuracyStruct(accuracyRanges: \(accuracyRanges as Optional<Any>), maxMeasuredValue: \(maxMeasuredValue as Optional<Any>), measured: \(measured as Optional<Any>), measurementType: \(measurementType as Optional<Any>), minMeasuredValue: \(minMeasuredValue as Optional<Any>))"
    }
}
open class MTRElectricalEnergyMeasurementClusterPeriodicEnergyMeasuredEvent: NSObject {
    public var energyExported: MTRElectricalEnergyMeasurementClusterEnergyMeasurementStruct?
    public var energyImported: MTRElectricalEnergyMeasurementClusterEnergyMeasurementStruct?
    public override init() { super.init() }
    public override var description: String {
        "MTRElectricalEnergyMeasurementClusterPeriodicEnergyMeasuredEvent(energyExported: \(energyExported as Optional<Any>), energyImported: \(energyImported as Optional<Any>))"
    }
}
open class MTRElectricalPowerMeasurementClusterHarmonicMeasurementStruct: NSObject {
    public var measurement: NSNumber?
    public var order: NSNumber = 0
    public override init() { super.init() }
    public override var description: String {
        "MTRElectricalPowerMeasurementClusterHarmonicMeasurementStruct(measurement: \(measurement as Optional<Any>), order: \(order as Optional<Any>))"
    }
}
open class MTRElectricalPowerMeasurementClusterMeasurementAccuracyRangeStruct: NSObject {
    public var fixedMax: NSNumber?
    public var fixedMin: NSNumber?
    public var fixedTypical: NSNumber?
    public var percentMax: NSNumber?
    public var percentMin: NSNumber?
    public var percentTypical: NSNumber?
    public var rangeMax: NSNumber = 0
    public var rangeMin: NSNumber = 0
    public override init() { super.init() }
    public override var description: String {
        "MTRElectricalPowerMeasurementClusterMeasurementAccuracyRangeStruct(fixedMax: \(fixedMax as Optional<Any>), fixedMin: \(fixedMin as Optional<Any>), fixedTypical: \(fixedTypical as Optional<Any>), percentMax: \(percentMax as Optional<Any>), percentMin: \(percentMin as Optional<Any>), percentTypical: \(percentTypical as Optional<Any>), rangeMax: \(rangeMax as Optional<Any>), rangeMin: \(rangeMin as Optional<Any>))"
    }
}
open class MTRElectricalPowerMeasurementClusterMeasurementAccuracyStruct: NSObject {
    public var accuracyRanges: [Any] = []
    public var maxMeasuredValue: NSNumber = 0
    public var measured: NSNumber = 0
    public var measurementType: NSNumber = 0
    public var minMeasuredValue: NSNumber = 0
    public override init() { super.init() }
    public override var description: String {
        "MTRElectricalPowerMeasurementClusterMeasurementAccuracyStruct(accuracyRanges: \(accuracyRanges as Optional<Any>), maxMeasuredValue: \(maxMeasuredValue as Optional<Any>), measured: \(measured as Optional<Any>), measurementType: \(measurementType as Optional<Any>), minMeasuredValue: \(minMeasuredValue as Optional<Any>))"
    }
}
open class MTRElectricalPowerMeasurementClusterMeasurementPeriodRangesEvent: NSObject {
    public var ranges: [Any] = []
    public override init() { super.init() }
    public override var description: String {
        "MTRElectricalPowerMeasurementClusterMeasurementPeriodRangesEvent(ranges: \(ranges as Optional<Any>))"
    }
}
open class MTRElectricalPowerMeasurementClusterMeasurementRangeStruct: NSObject {
    public var endSystime: NSNumber?
    public var endTimestamp: NSNumber?
    public var max: NSNumber = 0
    public var maxSystime: NSNumber?
    public var maxTimestamp: NSNumber?
    public var measurementType: NSNumber = 0
    public var min: NSNumber = 0
    public var minSystime: NSNumber?
    public var minTimestamp: NSNumber?
    public var startSystime: NSNumber?
    public var startTimestamp: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRElectricalPowerMeasurementClusterMeasurementRangeStruct(endSystime: \(endSystime as Optional<Any>), endTimestamp: \(endTimestamp as Optional<Any>), max: \(max as Optional<Any>), maxSystime: \(maxSystime as Optional<Any>), maxTimestamp: \(maxTimestamp as Optional<Any>), measurementType: \(measurementType as Optional<Any>), min: \(min as Optional<Any>), minSystime: \(minSystime as Optional<Any>), minTimestamp: \(minTimestamp as Optional<Any>), startSystime: \(startSystime as Optional<Any>), startTimestamp: \(startTimestamp as Optional<Any>))"
    }
}
open class MTREnergyEVSEClusterChargingTargetScheduleStruct: NSObject {
    public var chargingTargets: [Any] = []
    public var dayOfWeekForSequence: NSNumber = 0
    public override init() { super.init() }
    public override var description: String {
        "MTREnergyEVSEClusterChargingTargetScheduleStruct(chargingTargets: \(chargingTargets as Optional<Any>), dayOfWeekForSequence: \(dayOfWeekForSequence as Optional<Any>))"
    }
}
open class MTREnergyEVSEClusterChargingTargetStruct: NSObject {
    public var addedEnergy: NSNumber?
    public var targetSoC: NSNumber?
    public var targetTimeMinutesPastMidnight: NSNumber = 0
    public override init() { super.init() }
    public override var description: String {
        "MTREnergyEVSEClusterChargingTargetStruct(addedEnergy: \(addedEnergy as Optional<Any>), targetSoC: \(targetSoC as Optional<Any>), targetTimeMinutesPastMidnight: \(targetTimeMinutesPastMidnight as Optional<Any>))"
    }
}
open class MTREnergyEVSEClusterClearTargetsParams: NSObject {
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTREnergyEVSEClusterClearTargetsParams(serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}
open class MTREnergyEVSEClusterDisableParams: NSObject {
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTREnergyEVSEClusterDisableParams(serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}
open class MTREnergyEVSEClusterEVConnectedEvent: NSObject {
    public var sessionID: NSNumber = 0
    public override init() { super.init() }
    public override var description: String {
        "MTREnergyEVSEClusterEVConnectedEvent(sessionID: \(sessionID as Optional<Any>))"
    }
}
open class MTREnergyEVSEClusterEVNotDetectedEvent: NSObject {
    public var sessionDuration: NSNumber = 0
    public var sessionEnergyCharged: NSNumber = 0
    public var sessionID: NSNumber = 0
    public var state: NSNumber = 0
    public override init() { super.init() }
    public override var description: String {
        "MTREnergyEVSEClusterEVNotDetectedEvent(sessionDuration: \(sessionDuration as Optional<Any>), sessionEnergyCharged: \(sessionEnergyCharged as Optional<Any>), sessionID: \(sessionID as Optional<Any>), state: \(state as Optional<Any>))"
    }
}
open class MTREnergyEVSEClusterEnableChargingParams: NSObject {
    public var chargingEnabledUntil: NSNumber?
    public var maximumChargeCurrent: NSNumber = 0
    public var minimumChargeCurrent: NSNumber = 0
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTREnergyEVSEClusterEnableChargingParams(chargingEnabledUntil: \(chargingEnabledUntil as Optional<Any>), maximumChargeCurrent: \(maximumChargeCurrent as Optional<Any>), minimumChargeCurrent: \(minimumChargeCurrent as Optional<Any>), serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}
open class MTREnergyEVSEClusterEnergyTransferStartedEvent: NSObject {
    public var maximumCurrent: NSNumber = 0
    public var sessionID: NSNumber = 0
    public var state: NSNumber = 0
    public override init() { super.init() }
    public override var description: String {
        "MTREnergyEVSEClusterEnergyTransferStartedEvent(maximumCurrent: \(maximumCurrent as Optional<Any>), sessionID: \(sessionID as Optional<Any>), state: \(state as Optional<Any>))"
    }
}
open class MTREnergyEVSEClusterEnergyTransferStoppedEvent: NSObject {
    public var energyTransferred: NSNumber = 0
    public var reason: NSNumber = 0
    public var sessionID: NSNumber = 0
    public var state: NSNumber = 0
    public override init() { super.init() }
    public override var description: String {
        "MTREnergyEVSEClusterEnergyTransferStoppedEvent(energyTransferred: \(energyTransferred as Optional<Any>), reason: \(reason as Optional<Any>), sessionID: \(sessionID as Optional<Any>), state: \(state as Optional<Any>))"
    }
}
open class MTREnergyEVSEClusterFaultEvent: NSObject {
    public var faultStateCurrentState: NSNumber = 0
    public var faultStatePreviousState: NSNumber = 0
    public var sessionID: NSNumber?
    public var state: NSNumber = 0
    public override init() { super.init() }
    public override var description: String {
        "MTREnergyEVSEClusterFaultEvent(faultStateCurrentState: \(faultStateCurrentState as Optional<Any>), faultStatePreviousState: \(faultStatePreviousState as Optional<Any>), sessionID: \(sessionID as Optional<Any>), state: \(state as Optional<Any>))"
    }
}
open class MTREnergyEVSEClusterGetTargetsParams: NSObject {
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTREnergyEVSEClusterGetTargetsParams(serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}
open class MTREnergyEVSEClusterGetTargetsResponseParams: NSObject {
    public init(responseValue: [String : Any]) throws {
        if let err = responseValue[MTRErrorKey] as? (any Error) {
            throw err
        }
        super.init()
        _ = responseValue[MTRDataKey] as? [String: Any]
    }
    public var chargingTargetSchedules: [Any] = []
    public override init() { super.init() }
    public override var description: String {
        "MTREnergyEVSEClusterGetTargetsResponseParams(chargingTargetSchedules: \(chargingTargetSchedules as Optional<Any>))"
    }
}
open class MTREnergyEVSEClusterRFIDEvent: NSObject {
    public var uid: Data = Data()
    public override init() { super.init() }
    public override var description: String {
        "MTREnergyEVSEClusterRFIDEvent(uid: \(uid as Optional<Any>))"
    }
}
open class MTREnergyEVSEClusterSetTargetsParams: NSObject {
    public var chargingTargetSchedules: [Any] = []
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTREnergyEVSEClusterSetTargetsParams(chargingTargetSchedules: \(chargingTargetSchedules as Optional<Any>), serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}
open class MTREnergyEVSEClusterStartDiagnosticsParams: NSObject {
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTREnergyEVSEClusterStartDiagnosticsParams(serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}
open class MTREnergyEVSEModeClusterChangeToModeParams: NSObject {
    public var newMode: NSNumber = 0
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTREnergyEVSEModeClusterChangeToModeParams(newMode: \(newMode as Optional<Any>), serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}
open class MTREnergyEVSEModeClusterChangeToModeResponseParams: NSObject {
    public init(responseValue: [String : Any]) throws {
        if let err = responseValue[MTRErrorKey] as? (any Error) {
            throw err
        }
        super.init()
        _ = responseValue[MTRDataKey] as? [String: Any]
    }
    public var status: NSNumber = 0
    public var statusText: String?
    public override init() { super.init() }
    public override var description: String {
        "MTREnergyEVSEModeClusterChangeToModeResponseParams(status: \(status as Optional<Any>), statusText: \(statusText as Optional<Any>))"
    }
}
open class MTREnergyEVSEModeClusterModeOptionStruct: NSObject {
    public var label: String = ""
    public var mode: NSNumber = 0
    public var modeTags: [Any] = []
    public override init() { super.init() }
    public override var description: String {
        "MTREnergyEVSEModeClusterModeOptionStruct(label: \(label as Optional<Any>), mode: \(mode as Optional<Any>), modeTags: \(modeTags as Optional<Any>))"
    }
}
open class MTREnergyEVSEModeClusterModeTagStruct: NSObject {
    public var mfgCode: NSNumber?
    public var value: NSNumber = 0
    public override init() { super.init() }
    public override var description: String {
        "MTREnergyEVSEModeClusterModeTagStruct(mfgCode: \(mfgCode as Optional<Any>), value: \(value as Optional<Any>))"
    }
}
open class MTREthernetNetworkDiagnosticsClusterResetCountsParams: NSObject {
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTREthernetNetworkDiagnosticsClusterResetCountsParams(serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}
open class MTRFanControlClusterStepParams: NSObject {
    public var direction: NSNumber = 0
    public var lowestOff: NSNumber?
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public var wrap: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRFanControlClusterStepParams(direction: \(direction as Optional<Any>), lowestOff: \(lowestOff as Optional<Any>), serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>), wrap: \(wrap as Optional<Any>))"
    }
}
open class MTRFixedLabelClusterLabelStruct: NSObject {
    public var label: String = ""
    public var value: String = ""
    public override init() { super.init() }
    public override var description: String {
        "MTRFixedLabelClusterLabelStruct(label: \(label as Optional<Any>), value: \(value as Optional<Any>))"
    }
}
open class MTRGeneralCommissioningClusterArmFailSafeParams: NSObject {
    public var breadcrumb: NSNumber = 0
    public var expiryLengthSeconds: NSNumber = 0
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRGeneralCommissioningClusterArmFailSafeParams(breadcrumb: \(breadcrumb as Optional<Any>), expiryLengthSeconds: \(expiryLengthSeconds as Optional<Any>), serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}
open class MTRGeneralCommissioningClusterArmFailSafeResponseParams: NSObject {
    public init(responseValue: [String : Any]) throws {
        if let err = responseValue[MTRErrorKey] as? (any Error) {
            throw err
        }
        super.init()
        _ = responseValue[MTRDataKey] as? [String: Any]
    }
    public var debugText: String = ""
    public var errorCode: NSNumber = 0
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRGeneralCommissioningClusterArmFailSafeResponseParams(debugText: \(debugText as Optional<Any>), errorCode: \(errorCode as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}
open class MTRGeneralCommissioningClusterBasicCommissioningInfo: NSObject {
    public var failSafeExpiryLengthSeconds: NSNumber = 0
    public var maxCumulativeFailsafeSeconds: NSNumber = 0
    public override init() { super.init() }
    public override var description: String {
        "MTRGeneralCommissioningClusterBasicCommissioningInfo(failSafeExpiryLengthSeconds: \(failSafeExpiryLengthSeconds as Optional<Any>), maxCumulativeFailsafeSeconds: \(maxCumulativeFailsafeSeconds as Optional<Any>))"
    }
}
open class MTRGeneralCommissioningClusterCommissioningCompleteParams: NSObject {
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRGeneralCommissioningClusterCommissioningCompleteParams(serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}
open class MTRGeneralCommissioningClusterCommissioningCompleteResponseParams: NSObject {
    public init(responseValue: [String : Any]) throws {
        if let err = responseValue[MTRErrorKey] as? (any Error) {
            throw err
        }
        super.init()
        _ = responseValue[MTRDataKey] as? [String: Any]
    }
    public var debugText: String = ""
    public var errorCode: NSNumber = 0
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRGeneralCommissioningClusterCommissioningCompleteResponseParams(debugText: \(debugText as Optional<Any>), errorCode: \(errorCode as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}
open class MTRGeneralCommissioningClusterSetRegulatoryConfigParams: NSObject {
    public var breadcrumb: NSNumber = 0
    public var countryCode: String = ""
    public var newRegulatoryConfig: NSNumber = 0
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRGeneralCommissioningClusterSetRegulatoryConfigParams(breadcrumb: \(breadcrumb as Optional<Any>), countryCode: \(countryCode as Optional<Any>), newRegulatoryConfig: \(newRegulatoryConfig as Optional<Any>), serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}
open class MTRGeneralCommissioningClusterSetRegulatoryConfigResponseParams: NSObject {
    public init(responseValue: [String : Any]) throws {
        if let err = responseValue[MTRErrorKey] as? (any Error) {
            throw err
        }
        super.init()
        _ = responseValue[MTRDataKey] as? [String: Any]
    }
    public var debugText: String = ""
    public var errorCode: NSNumber = 0
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRGeneralCommissioningClusterSetRegulatoryConfigResponseParams(debugText: \(debugText as Optional<Any>), errorCode: \(errorCode as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}
open class MTRGeneralDiagnosticsClusterBootReasonEvent: NSObject {
    public var bootReason: NSNumber = 0
    public override init() { super.init() }
    public override var description: String {
        "MTRGeneralDiagnosticsClusterBootReasonEvent(bootReason: \(bootReason as Optional<Any>))"
    }
}
open class MTRGeneralDiagnosticsClusterHardwareFaultChangeEvent: NSObject {
    public var current: [Any] = []
    public var previous: [Any] = []
    public override init() { super.init() }
    public override var description: String {
        "MTRGeneralDiagnosticsClusterHardwareFaultChangeEvent(current: \(current as Optional<Any>), previous: \(previous as Optional<Any>))"
    }
}
open class MTRGeneralDiagnosticsClusterNetworkFaultChangeEvent: NSObject {
    public var current: [Any] = []
    public var previous: [Any] = []
    public override init() { super.init() }
    public override var description: String {
        "MTRGeneralDiagnosticsClusterNetworkFaultChangeEvent(current: \(current as Optional<Any>), previous: \(previous as Optional<Any>))"
    }
}
open class MTRGeneralDiagnosticsClusterNetworkInterface: NSObject {
    public var hardwareAddress: Data = Data()
    public var iPv4Addresses: [Any] = []
    public var iPv6Addresses: [Any] = []
    public var isOperational: NSNumber = 0
    public var name: String = ""
    public var offPremiseServicesReachableIPv4: NSNumber?
    public var offPremiseServicesReachableIPv6: NSNumber?
    public var `type`: NSNumber = 0
    public override init() { super.init() }
    public override var description: String {
        "MTRGeneralDiagnosticsClusterNetworkInterface(hardwareAddress: \(hardwareAddress as Optional<Any>), iPv4Addresses: \(iPv4Addresses as Optional<Any>), iPv6Addresses: \(iPv6Addresses as Optional<Any>), isOperational: \(isOperational as Optional<Any>), name: \(name as Optional<Any>), offPremiseServicesReachableIPv4: \(offPremiseServicesReachableIPv4 as Optional<Any>), offPremiseServicesReachableIPv6: \(offPremiseServicesReachableIPv6 as Optional<Any>), type: \(`type` as Optional<Any>))"
    }
}
open class MTRGeneralDiagnosticsClusterPayloadTestRequestParams: NSObject {
    public var count: NSNumber = 0
    public var enableKey: Data = Data()
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public var value: NSNumber = 0
    public override init() { super.init() }
    public override var description: String {
        "MTRGeneralDiagnosticsClusterPayloadTestRequestParams(count: \(count as Optional<Any>), enableKey: \(enableKey as Optional<Any>), serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>), value: \(value as Optional<Any>))"
    }
}
open class MTRGeneralDiagnosticsClusterPayloadTestResponseParams: NSObject {
    public init(responseValue: [String : Any]) throws {
        if let err = responseValue[MTRErrorKey] as? (any Error) {
            throw err
        }
        super.init()
        _ = responseValue[MTRDataKey] as? [String: Any]
    }
    public var payload: Data = Data()
    public override init() { super.init() }
    public override var description: String {
        "MTRGeneralDiagnosticsClusterPayloadTestResponseParams(payload: \(payload as Optional<Any>))"
    }
}
open class MTRGeneralDiagnosticsClusterRadioFaultChangeEvent: NSObject {
    public var current: [Any] = []
    public var previous: [Any] = []
    public override init() { super.init() }
    public override var description: String {
        "MTRGeneralDiagnosticsClusterRadioFaultChangeEvent(current: \(current as Optional<Any>), previous: \(previous as Optional<Any>))"
    }
}
open class MTRGeneralDiagnosticsClusterTestEventTriggerParams: NSObject {
    public var enableKey: Data = Data()
    public var eventTrigger: NSNumber = 0
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRGeneralDiagnosticsClusterTestEventTriggerParams(enableKey: \(enableKey as Optional<Any>), eventTrigger: \(eventTrigger as Optional<Any>), serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}
open class MTRGeneralDiagnosticsClusterTimeSnapshotParams: NSObject {
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRGeneralDiagnosticsClusterTimeSnapshotParams(serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}
open class MTRGeneralDiagnosticsClusterTimeSnapshotResponseParams: NSObject {
    public init(responseValue: [String : Any]) throws {
        if let err = responseValue[MTRErrorKey] as? (any Error) {
            throw err
        }
        super.init()
        _ = responseValue[MTRDataKey] as? [String: Any]
    }
    public var posixTimeMs: NSNumber?
    public var systemTimeMs: NSNumber = 0
    public override init() { super.init() }
    public override var description: String {
        "MTRGeneralDiagnosticsClusterTimeSnapshotResponseParams(posixTimeMs: \(posixTimeMs as Optional<Any>), systemTimeMs: \(systemTimeMs as Optional<Any>))"
    }
}
open class MTRGroupKeyManagementClusterGroupInfoMapStruct: NSObject {
    public var endpoints: [Any] = []
    public var fabricIndex: NSNumber = 0
    public var groupId: NSNumber = 0
    public var groupName: String?
    public override init() { super.init() }
    public override var description: String {
        "MTRGroupKeyManagementClusterGroupInfoMapStruct(endpoints: \(endpoints as Optional<Any>), fabricIndex: \(fabricIndex as Optional<Any>), groupId: \(groupId as Optional<Any>), groupName: \(groupName as Optional<Any>))"
    }
}
open class MTRGroupKeyManagementClusterGroupKeyMapStruct: NSObject {
    public var fabricIndex: NSNumber = 0
    public var groupId: NSNumber = 0
    public var groupKeySetID: NSNumber = 0
    public override init() { super.init() }
    public override var description: String {
        "MTRGroupKeyManagementClusterGroupKeyMapStruct(fabricIndex: \(fabricIndex as Optional<Any>), groupId: \(groupId as Optional<Any>), groupKeySetID: \(groupKeySetID as Optional<Any>))"
    }
}
open class MTRGroupKeyManagementClusterGroupKeySetStruct: NSObject {
    public var epochKey0: Data?
    public var epochKey1: Data?
    public var epochKey2: Data?
    public var epochStartTime0: NSNumber?
    public var epochStartTime1: NSNumber?
    public var epochStartTime2: NSNumber?
    public var groupKeySecurityPolicy: NSNumber = 0
    public var groupKeySetID: NSNumber = 0
    public override init() { super.init() }
    public override var description: String {
        "MTRGroupKeyManagementClusterGroupKeySetStruct(epochKey0: \(epochKey0 as Optional<Any>), epochKey1: \(epochKey1 as Optional<Any>), epochKey2: \(epochKey2 as Optional<Any>), epochStartTime0: \(epochStartTime0 as Optional<Any>), epochStartTime1: \(epochStartTime1 as Optional<Any>), epochStartTime2: \(epochStartTime2 as Optional<Any>), groupKeySecurityPolicy: \(groupKeySecurityPolicy as Optional<Any>), groupKeySetID: \(groupKeySetID as Optional<Any>))"
    }
}
open class MTRGroupKeyManagementClusterKeySetReadAllIndicesParams: NSObject {
    public var groupKeySetIDs: [Any] = []
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRGroupKeyManagementClusterKeySetReadAllIndicesParams(groupKeySetIDs: \(groupKeySetIDs as Optional<Any>), serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}
open class MTRGroupKeyManagementClusterKeySetReadAllIndicesResponseParams: NSObject {
    public init(responseValue: [String : Any]) throws {
        if let err = responseValue[MTRErrorKey] as? (any Error) {
            throw err
        }
        super.init()
        _ = responseValue[MTRDataKey] as? [String: Any]
    }
    public var groupKeySetIDs: [Any] = []
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRGroupKeyManagementClusterKeySetReadAllIndicesResponseParams(groupKeySetIDs: \(groupKeySetIDs as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}
open class MTRGroupKeyManagementClusterKeySetReadParams: NSObject {
    public var groupKeySetID: NSNumber = 0
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRGroupKeyManagementClusterKeySetReadParams(groupKeySetID: \(groupKeySetID as Optional<Any>), serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}
open class MTRGroupKeyManagementClusterKeySetReadResponseParams: NSObject {
    public init(responseValue: [String : Any]) throws {
        if let err = responseValue[MTRErrorKey] as? (any Error) {
            throw err
        }
        super.init()
        _ = responseValue[MTRDataKey] as? [String: Any]
    }
    public var groupKeySet: MTRGroupKeyManagementClusterGroupKeySetStruct = MTRGroupKeyManagementClusterGroupKeySetStruct()
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRGroupKeyManagementClusterKeySetReadResponseParams(groupKeySet: \(groupKeySet as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}
open class MTRGroupKeyManagementClusterKeySetRemoveParams: NSObject {
    public var groupKeySetID: NSNumber = 0
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRGroupKeyManagementClusterKeySetRemoveParams(groupKeySetID: \(groupKeySetID as Optional<Any>), serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}
open class MTRGroupKeyManagementClusterKeySetWriteParams: NSObject {
    public var groupKeySet: MTRGroupKeyManagementClusterGroupKeySetStruct = MTRGroupKeyManagementClusterGroupKeySetStruct()
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRGroupKeyManagementClusterKeySetWriteParams(groupKeySet: \(groupKeySet as Optional<Any>), serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}
open class MTRGroupsClusterAddGroupIfIdentifyingParams: NSObject {
    public var groupID: NSNumber = 0
    public var groupId: NSNumber = 0
    public var groupName: String = ""
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRGroupsClusterAddGroupIfIdentifyingParams(groupID: \(groupID as Optional<Any>), groupId: \(groupId as Optional<Any>), groupName: \(groupName as Optional<Any>), serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}
open class MTRGroupsClusterAddGroupParams: NSObject {
    public var groupID: NSNumber = 0
    public var groupId: NSNumber = 0
    public var groupName: String = ""
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRGroupsClusterAddGroupParams(groupID: \(groupID as Optional<Any>), groupId: \(groupId as Optional<Any>), groupName: \(groupName as Optional<Any>), serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}
open class MTRGroupsClusterAddGroupResponseParams: NSObject {
    public init(responseValue: [String : Any]) throws {
        if let err = responseValue[MTRErrorKey] as? (any Error) {
            throw err
        }
        super.init()
        _ = responseValue[MTRDataKey] as? [String: Any]
    }
    public var groupID: NSNumber = 0
    public var groupId: NSNumber = 0
    public var status: NSNumber = 0
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRGroupsClusterAddGroupResponseParams(groupID: \(groupID as Optional<Any>), groupId: \(groupId as Optional<Any>), status: \(status as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}
open class MTRGroupsClusterGetGroupMembershipParams: NSObject {
    public var groupList: [Any] = []
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRGroupsClusterGetGroupMembershipParams(groupList: \(groupList as Optional<Any>), serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}
open class MTRGroupsClusterGetGroupMembershipResponseParams: NSObject {
    public init(responseValue: [String : Any]) throws {
        if let err = responseValue[MTRErrorKey] as? (any Error) {
            throw err
        }
        super.init()
        _ = responseValue[MTRDataKey] as? [String: Any]
    }
    public var capacity: NSNumber?
    public var groupList: [Any] = []
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRGroupsClusterGetGroupMembershipResponseParams(capacity: \(capacity as Optional<Any>), groupList: \(groupList as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}
open class MTRGroupsClusterRemoveAllGroupsParams: NSObject {
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRGroupsClusterRemoveAllGroupsParams(serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}
open class MTRGroupsClusterRemoveGroupParams: NSObject {
    public var groupID: NSNumber = 0
    public var groupId: NSNumber = 0
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRGroupsClusterRemoveGroupParams(groupID: \(groupID as Optional<Any>), groupId: \(groupId as Optional<Any>), serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}
open class MTRGroupsClusterRemoveGroupResponseParams: NSObject {
    public init(responseValue: [String : Any]) throws {
        if let err = responseValue[MTRErrorKey] as? (any Error) {
            throw err
        }
        super.init()
        _ = responseValue[MTRDataKey] as? [String: Any]
    }
    public var groupID: NSNumber = 0
    public var groupId: NSNumber = 0
    public var status: NSNumber = 0
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRGroupsClusterRemoveGroupResponseParams(groupID: \(groupID as Optional<Any>), groupId: \(groupId as Optional<Any>), status: \(status as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}
open class MTRGroupsClusterViewGroupParams: NSObject {
    public var groupID: NSNumber = 0
    public var groupId: NSNumber = 0
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRGroupsClusterViewGroupParams(groupID: \(groupID as Optional<Any>), groupId: \(groupId as Optional<Any>), serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}
open class MTRGroupsClusterViewGroupResponseParams: NSObject {
    public init(responseValue: [String : Any]) throws {
        if let err = responseValue[MTRErrorKey] as? (any Error) {
            throw err
        }
        super.init()
        _ = responseValue[MTRDataKey] as? [String: Any]
    }
    public var groupID: NSNumber = 0
    public var groupId: NSNumber = 0
    public var groupName: String = ""
    public var status: NSNumber = 0
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRGroupsClusterViewGroupResponseParams(groupID: \(groupID as Optional<Any>), groupId: \(groupId as Optional<Any>), groupName: \(groupName as Optional<Any>), status: \(status as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}
open class MTRHEPAFilterMonitoringClusterReplacementProductStruct: NSObject {
    public var productIdentifierType: NSNumber = 0
    public var productIdentifierValue: String = ""
    public override init() { super.init() }
    public override var description: String {
        "MTRHEPAFilterMonitoringClusterReplacementProductStruct(productIdentifierType: \(productIdentifierType as Optional<Any>), productIdentifierValue: \(productIdentifierValue as Optional<Any>))"
    }
}
open class MTRHEPAFilterMonitoringClusterResetConditionParams: NSObject {
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRHEPAFilterMonitoringClusterResetConditionParams(serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}
open class MTRICDManagementClusterMonitoringRegistrationStruct: NSObject {
    public var checkInNodeID: NSNumber = 0
    public var clientType: NSNumber = 0
    public var fabricIndex: NSNumber = 0
    public var monitoredSubject: NSNumber = 0
    public override init() { super.init() }
    public override var description: String {
        "MTRICDManagementClusterMonitoringRegistrationStruct(checkInNodeID: \(checkInNodeID as Optional<Any>), clientType: \(clientType as Optional<Any>), fabricIndex: \(fabricIndex as Optional<Any>), monitoredSubject: \(monitoredSubject as Optional<Any>))"
    }
}
open class MTRICDManagementClusterRegisterClientParams: NSObject {
    public var checkInNodeID: NSNumber = 0
    public var clientType: NSNumber = 0
    public var key: Data = Data()
    public var monitoredSubject: NSNumber = 0
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public var verificationKey: Data?
    public override init() { super.init() }
    public override var description: String {
        "MTRICDManagementClusterRegisterClientParams(checkInNodeID: \(checkInNodeID as Optional<Any>), clientType: \(clientType as Optional<Any>), key: \(key as Optional<Any>), monitoredSubject: \(monitoredSubject as Optional<Any>), serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>), verificationKey: \(verificationKey as Optional<Any>))"
    }
}
open class MTRICDManagementClusterRegisterClientResponseParams: NSObject {
    public init(responseValue: [String : Any]) throws {
        if let err = responseValue[MTRErrorKey] as? (any Error) {
            throw err
        }
        super.init()
        _ = responseValue[MTRDataKey] as? [String: Any]
    }
    public var icdCounter: NSNumber = 0
    public override init() { super.init() }
    public override var description: String {
        "MTRICDManagementClusterRegisterClientResponseParams(icdCounter: \(icdCounter as Optional<Any>))"
    }
}
open class MTRICDManagementClusterStayActiveRequestParams: NSObject {
    public var serverSideProcessingTimeout: NSNumber?
    public var stayActiveDuration: NSNumber = 0
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRICDManagementClusterStayActiveRequestParams(serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), stayActiveDuration: \(stayActiveDuration as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}
open class MTRICDManagementClusterStayActiveResponseParams: NSObject {
    public init(responseValue: [String : Any]) throws {
        if let err = responseValue[MTRErrorKey] as? (any Error) {
            throw err
        }
        super.init()
        _ = responseValue[MTRDataKey] as? [String: Any]
    }
    public var promisedActiveDuration: NSNumber = 0
    public override init() { super.init() }
    public override var description: String {
        "MTRICDManagementClusterStayActiveResponseParams(promisedActiveDuration: \(promisedActiveDuration as Optional<Any>))"
    }
}
open class MTRICDManagementClusterUnregisterClientParams: NSObject {
    public var checkInNodeID: NSNumber = 0
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public var verificationKey: Data?
    public override init() { super.init() }
    public override var description: String {
        "MTRICDManagementClusterUnregisterClientParams(checkInNodeID: \(checkInNodeID as Optional<Any>), serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>), verificationKey: \(verificationKey as Optional<Any>))"
    }
}
open class MTRIdentifyClusterIdentifyParams: NSObject {
    public var identifyTime: NSNumber = 0
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRIdentifyClusterIdentifyParams(identifyTime: \(identifyTime as Optional<Any>), serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}
open class MTRIdentifyClusterTriggerEffectParams: NSObject {
    public var effectIdentifier: NSNumber = 0
    public var effectVariant: NSNumber = 0
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRIdentifyClusterTriggerEffectParams(effectIdentifier: \(effectIdentifier as Optional<Any>), effectVariant: \(effectVariant as Optional<Any>), serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}
open class MTRKeypadInputClusterSendKeyParams: NSObject {
    public var keyCode: NSNumber = 0
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRKeypadInputClusterSendKeyParams(keyCode: \(keyCode as Optional<Any>), serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}
open class MTRKeypadInputClusterSendKeyResponseParams: NSObject {
    public init(responseValue: [String : Any]) throws {
        if let err = responseValue[MTRErrorKey] as? (any Error) {
            throw err
        }
        super.init()
        _ = responseValue[MTRDataKey] as? [String: Any]
    }
    public var status: NSNumber = 0
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRKeypadInputClusterSendKeyResponseParams(status: \(status as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}
open class MTRLaundryWasherModeClusterChangeToModeParams: NSObject {
    public var newMode: NSNumber = 0
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRLaundryWasherModeClusterChangeToModeParams(newMode: \(newMode as Optional<Any>), serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}
open class MTRLaundryWasherModeClusterChangeToModeResponseParams: NSObject {
    public init(responseValue: [String : Any]) throws {
        if let err = responseValue[MTRErrorKey] as? (any Error) {
            throw err
        }
        super.init()
        _ = responseValue[MTRDataKey] as? [String: Any]
    }
    public var status: NSNumber = 0
    public var statusText: String?
    public override init() { super.init() }
    public override var description: String {
        "MTRLaundryWasherModeClusterChangeToModeResponseParams(status: \(status as Optional<Any>), statusText: \(statusText as Optional<Any>))"
    }
}
open class MTRLaundryWasherModeClusterModeOptionStruct: NSObject {
    public var label: String = ""
    public var mode: NSNumber = 0
    public var modeTags: [Any] = []
    public override init() { super.init() }
    public override var description: String {
        "MTRLaundryWasherModeClusterModeOptionStruct(label: \(label as Optional<Any>), mode: \(mode as Optional<Any>), modeTags: \(modeTags as Optional<Any>))"
    }
}
open class MTRLaundryWasherModeClusterModeTagStruct: NSObject {
    public var mfgCode: NSNumber?
    public var value: NSNumber = 0
    public override init() { super.init() }
    public override var description: String {
        "MTRLaundryWasherModeClusterModeTagStruct(mfgCode: \(mfgCode as Optional<Any>), value: \(value as Optional<Any>))"
    }
}
open class MTRLowPowerClusterSleepParams: NSObject {
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRLowPowerClusterSleepParams(serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}
open class MTRMediaInputClusterHideInputStatusParams: NSObject {
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRMediaInputClusterHideInputStatusParams(serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}
open class MTRMediaInputClusterInputInfoStruct: NSObject {
    public var descriptionString: String = ""
    public var index: NSNumber = 0
    public var inputType: NSNumber = 0
    public var name: String = ""
    public override init() { super.init() }
    public override var description: String {
        "MTRMediaInputClusterInputInfoStruct(descriptionString: \(descriptionString as Optional<Any>), index: \(index as Optional<Any>), inputType: \(inputType as Optional<Any>), name: \(name as Optional<Any>))"
    }
}
open class MTRMediaInputClusterRenameInputParams: NSObject {
    public var index: NSNumber = 0
    public var name: String = ""
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRMediaInputClusterRenameInputParams(index: \(index as Optional<Any>), name: \(name as Optional<Any>), serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}
open class MTRMediaInputClusterSelectInputParams: NSObject {
    public var index: NSNumber = 0
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRMediaInputClusterSelectInputParams(index: \(index as Optional<Any>), serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}
open class MTRMediaInputClusterShowInputStatusParams: NSObject {
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRMediaInputClusterShowInputStatusParams(serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}
open class MTRMediaPlaybackClusterActivateAudioTrackParams: NSObject {
    public var audioOutputIndex: NSNumber = 0
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public var trackID: String = ""
    public override init() { super.init() }
    public override var description: String {
        "MTRMediaPlaybackClusterActivateAudioTrackParams(audioOutputIndex: \(audioOutputIndex as Optional<Any>), serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>), trackID: \(trackID as Optional<Any>))"
    }
}
open class MTRMediaPlaybackClusterActivateTextTrackParams: NSObject {
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public var trackID: String = ""
    public override init() { super.init() }
    public override var description: String {
        "MTRMediaPlaybackClusterActivateTextTrackParams(serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>), trackID: \(trackID as Optional<Any>))"
    }
}
open class MTRMediaPlaybackClusterDeactivateTextTrackParams: NSObject {
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRMediaPlaybackClusterDeactivateTextTrackParams(serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}
open class MTRMediaPlaybackClusterFastForwardParams: NSObject {
    public var audioAdvanceUnmuted: NSNumber?
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRMediaPlaybackClusterFastForwardParams(audioAdvanceUnmuted: \(audioAdvanceUnmuted as Optional<Any>), serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}
open class MTRMediaPlaybackClusterNextParams: NSObject {
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRMediaPlaybackClusterNextParams(serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}
open class MTRMediaPlaybackClusterPauseParams: NSObject {
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRMediaPlaybackClusterPauseParams(serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}
open class MTRMediaPlaybackClusterPlayParams: NSObject {
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRMediaPlaybackClusterPlayParams(serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}
open class MTRMediaPlaybackClusterPlaybackPositionStruct: NSObject {
    public var position: NSNumber?
    public var updatedAt: NSNumber = 0
    public override init() { super.init() }
    public override var description: String {
        "MTRMediaPlaybackClusterPlaybackPositionStruct(position: \(position as Optional<Any>), updatedAt: \(updatedAt as Optional<Any>))"
    }
}
open class MTRMediaPlaybackClusterPlaybackResponseParams: NSObject {
    public init(responseValue: [String : Any]) throws {
        if let err = responseValue[MTRErrorKey] as? (any Error) {
            throw err
        }
        super.init()
        _ = responseValue[MTRDataKey] as? [String: Any]
    }
    public var data: String?
    public var status: NSNumber = 0
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRMediaPlaybackClusterPlaybackResponseParams(data: \(data as Optional<Any>), status: \(status as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}
open class MTRMediaPlaybackClusterPreviousParams: NSObject {
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRMediaPlaybackClusterPreviousParams(serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}
open class MTRMediaPlaybackClusterRewindParams: NSObject {
    public var audioAdvanceUnmuted: NSNumber?
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRMediaPlaybackClusterRewindParams(audioAdvanceUnmuted: \(audioAdvanceUnmuted as Optional<Any>), serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}
open class MTRMediaPlaybackClusterSeekParams: NSObject {
    public var position: NSNumber = 0
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRMediaPlaybackClusterSeekParams(position: \(position as Optional<Any>), serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}
open class MTRMediaPlaybackClusterSkipBackwardParams: NSObject {
    public var deltaPositionMilliseconds: NSNumber = 0
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRMediaPlaybackClusterSkipBackwardParams(deltaPositionMilliseconds: \(deltaPositionMilliseconds as Optional<Any>), serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}
open class MTRMediaPlaybackClusterSkipForwardParams: NSObject {
    public var deltaPositionMilliseconds: NSNumber = 0
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRMediaPlaybackClusterSkipForwardParams(deltaPositionMilliseconds: \(deltaPositionMilliseconds as Optional<Any>), serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}
open class MTRMediaPlaybackClusterStartOverParams: NSObject {
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRMediaPlaybackClusterStartOverParams(serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}
open class MTRMediaPlaybackClusterStateChangedEvent: NSObject {
    public var audioAdvanceUnmuted: NSNumber = 0
    public var currentState: NSNumber = 0
    public var data: Data?
    public var duration: NSNumber = 0
    public var playbackSpeed: NSNumber = 0
    public var sampledPosition: MTRMediaPlaybackClusterPlaybackPositionStruct = MTRMediaPlaybackClusterPlaybackPositionStruct()
    public var seekRangeEnd: NSNumber = 0
    public var seekRangeStart: NSNumber = 0
    public var startTime: NSNumber = 0
    public override init() { super.init() }
    public override var description: String {
        "MTRMediaPlaybackClusterStateChangedEvent(audioAdvanceUnmuted: \(audioAdvanceUnmuted as Optional<Any>), currentState: \(currentState as Optional<Any>), data: \(data as Optional<Any>), duration: \(duration as Optional<Any>), playbackSpeed: \(playbackSpeed as Optional<Any>), sampledPosition: \(sampledPosition as Optional<Any>), seekRangeEnd: \(seekRangeEnd as Optional<Any>), seekRangeStart: \(seekRangeStart as Optional<Any>), startTime: \(startTime as Optional<Any>))"
    }
}
open class MTRMediaPlaybackClusterStopParams: NSObject {
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRMediaPlaybackClusterStopParams(serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}
open class MTRMessagesClusterCancelMessagesRequestParams: NSObject {
    public var messageIDs: [Any] = []
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRMessagesClusterCancelMessagesRequestParams(messageIDs: \(messageIDs as Optional<Any>), serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}
open class MTRMessagesClusterMessageCompleteEvent: NSObject {
    public var futureMessagesPreference: NSNumber?
    public var messageID: Data = Data()
    public var reply: String?
    public var responseID: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRMessagesClusterMessageCompleteEvent(futureMessagesPreference: \(futureMessagesPreference as Optional<Any>), messageID: \(messageID as Optional<Any>), reply: \(reply as Optional<Any>), responseID: \(responseID as Optional<Any>))"
    }
}
open class MTRMessagesClusterMessagePresentedEvent: NSObject {
    public var messageID: Data = Data()
    public override init() { super.init() }
    public override var description: String {
        "MTRMessagesClusterMessagePresentedEvent(messageID: \(messageID as Optional<Any>))"
    }
}
open class MTRMessagesClusterMessageQueuedEvent: NSObject {
    public var messageID: Data = Data()
    public override init() { super.init() }
    public override var description: String {
        "MTRMessagesClusterMessageQueuedEvent(messageID: \(messageID as Optional<Any>))"
    }
}
open class MTRMessagesClusterMessageResponseOptionStruct: NSObject {
    public var label: String?
    public var messageResponseID: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRMessagesClusterMessageResponseOptionStruct(label: \(label as Optional<Any>), messageResponseID: \(messageResponseID as Optional<Any>))"
    }
}
open class MTRMessagesClusterMessageStruct: NSObject {
    public var duration: NSNumber?
    public var messageControl: NSNumber = 0
    public var messageID: Data = Data()
    public var messageText: String = ""
    public var priority: NSNumber = 0
    public var responses: [Any]?
    public var startTime: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRMessagesClusterMessageStruct(duration: \(duration as Optional<Any>), messageControl: \(messageControl as Optional<Any>), messageID: \(messageID as Optional<Any>), messageText: \(messageText as Optional<Any>), priority: \(priority as Optional<Any>), responses: \(responses as Optional<Any>), startTime: \(startTime as Optional<Any>))"
    }
}
open class MTRMessagesClusterPresentMessagesRequestParams: NSObject {
    public var duration: NSNumber?
    public var messageControl: NSNumber = 0
    public var messageID: Data = Data()
    public var messageText: String = ""
    public var priority: NSNumber = 0
    public var responses: [Any]?
    public var serverSideProcessingTimeout: NSNumber?
    public var startTime: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRMessagesClusterPresentMessagesRequestParams(duration: \(duration as Optional<Any>), messageControl: \(messageControl as Optional<Any>), messageID: \(messageID as Optional<Any>), messageText: \(messageText as Optional<Any>), priority: \(priority as Optional<Any>), responses: \(responses as Optional<Any>), serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), startTime: \(startTime as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}
open class MTRMicrowaveOvenControlClusterAddMoreTimeParams: NSObject {
    public var serverSideProcessingTimeout: NSNumber?
    public var timeToAdd: NSNumber = 0
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRMicrowaveOvenControlClusterAddMoreTimeParams(serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timeToAdd: \(timeToAdd as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}
open class MTRMicrowaveOvenControlClusterSetCookingParametersParams: NSObject {
    public var cookMode: NSNumber?
    public var cookTime: NSNumber?
    public var powerSetting: NSNumber?
    public var serverSideProcessingTimeout: NSNumber?
    public var startAfterSetting: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRMicrowaveOvenControlClusterSetCookingParametersParams(cookMode: \(cookMode as Optional<Any>), cookTime: \(cookTime as Optional<Any>), powerSetting: \(powerSetting as Optional<Any>), serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), startAfterSetting: \(startAfterSetting as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}
open class MTRMicrowaveOvenModeClusterModeOptionStruct: NSObject {
    public var label: String = ""
    public var mode: NSNumber = 0
    public var modeTags: [Any] = []
    public override init() { super.init() }
    public override var description: String {
        "MTRMicrowaveOvenModeClusterModeOptionStruct(label: \(label as Optional<Any>), mode: \(mode as Optional<Any>), modeTags: \(modeTags as Optional<Any>))"
    }
}
open class MTRMicrowaveOvenModeClusterModeTagStruct: NSObject {
    public var mfgCode: NSNumber?
    public var value: NSNumber = 0
    public override init() { super.init() }
    public override var description: String {
        "MTRMicrowaveOvenModeClusterModeTagStruct(mfgCode: \(mfgCode as Optional<Any>), value: \(value as Optional<Any>))"
    }
}
open class MTRModeSelectClusterChangeToModeParams: NSObject {
    public var newMode: NSNumber = 0
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRModeSelectClusterChangeToModeParams(newMode: \(newMode as Optional<Any>), serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}
open class MTRModeSelectClusterModeOptionStruct: NSObject {
    public var label: String = ""
    public var mode: NSNumber = 0
    public var semanticTags: [Any] = []
    public override init() { super.init() }
    public override var description: String {
        "MTRModeSelectClusterModeOptionStruct(label: \(label as Optional<Any>), mode: \(mode as Optional<Any>), semanticTags: \(semanticTags as Optional<Any>))"
    }
}
open class MTRModeSelectClusterSemanticTagStruct: NSObject {
    public var mfgCode: NSNumber = 0
    public var value: NSNumber = 0
    public override init() { super.init() }
    public override var description: String {
        "MTRModeSelectClusterSemanticTagStruct(mfgCode: \(mfgCode as Optional<Any>), value: \(value as Optional<Any>))"
    }
}
open class MTRNetworkCommissioningClusterAddOrUpdateThreadNetworkParams: NSObject {
    public var breadcrumb: NSNumber?
    public var operationalDataset: Data = Data()
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRNetworkCommissioningClusterAddOrUpdateThreadNetworkParams(breadcrumb: \(breadcrumb as Optional<Any>), operationalDataset: \(operationalDataset as Optional<Any>), serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}
open class MTRNetworkCommissioningClusterAddOrUpdateWiFiNetworkParams: NSObject {
    public var breadcrumb: NSNumber?
    public var credentials: Data = Data()
    public var serverSideProcessingTimeout: NSNumber?
    public var ssid: Data = Data()
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRNetworkCommissioningClusterAddOrUpdateWiFiNetworkParams(breadcrumb: \(breadcrumb as Optional<Any>), credentials: \(credentials as Optional<Any>), serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), ssid: \(ssid as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}
open class MTRNetworkCommissioningClusterConnectNetworkParams: NSObject {
    public var breadcrumb: NSNumber?
    public var networkID: Data = Data()
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRNetworkCommissioningClusterConnectNetworkParams(breadcrumb: \(breadcrumb as Optional<Any>), networkID: \(networkID as Optional<Any>), serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}
open class MTRNetworkCommissioningClusterConnectNetworkResponseParams: NSObject {
    public init(responseValue: [String : Any]) throws {
        if let err = responseValue[MTRErrorKey] as? (any Error) {
            throw err
        }
        super.init()
        _ = responseValue[MTRDataKey] as? [String: Any]
    }
    public var debugText: String?
    public var errorValue: NSNumber?
    public var networkingStatus: NSNumber = 0
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRNetworkCommissioningClusterConnectNetworkResponseParams(debugText: \(debugText as Optional<Any>), errorValue: \(errorValue as Optional<Any>), networkingStatus: \(networkingStatus as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}
open class MTRNetworkCommissioningClusterNetworkConfigResponseParams: NSObject {
    public init(responseValue: [String : Any]) throws {
        if let err = responseValue[MTRErrorKey] as? (any Error) {
            throw err
        }
        super.init()
        _ = responseValue[MTRDataKey] as? [String: Any]
    }
    public var debugText: String?
    public var networkIndex: NSNumber?
    public var networkingStatus: NSNumber = 0
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRNetworkCommissioningClusterNetworkConfigResponseParams(debugText: \(debugText as Optional<Any>), networkIndex: \(networkIndex as Optional<Any>), networkingStatus: \(networkingStatus as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}
open class MTRNetworkCommissioningClusterNetworkInfoStruct: NSObject {
    public var connected: NSNumber = 0
    public var networkID: Data = Data()
    public override init() { super.init() }
    public override var description: String {
        "MTRNetworkCommissioningClusterNetworkInfoStruct(connected: \(connected as Optional<Any>), networkID: \(networkID as Optional<Any>))"
    }
}
open class MTRNetworkCommissioningClusterRemoveNetworkParams: NSObject {
    public var breadcrumb: NSNumber?
    public var networkID: Data = Data()
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRNetworkCommissioningClusterRemoveNetworkParams(breadcrumb: \(breadcrumb as Optional<Any>), networkID: \(networkID as Optional<Any>), serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}
open class MTRNetworkCommissioningClusterReorderNetworkParams: NSObject {
    public var breadcrumb: NSNumber?
    public var networkID: Data = Data()
    public var networkIndex: NSNumber = 0
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRNetworkCommissioningClusterReorderNetworkParams(breadcrumb: \(breadcrumb as Optional<Any>), networkID: \(networkID as Optional<Any>), networkIndex: \(networkIndex as Optional<Any>), serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}
open class MTRNetworkCommissioningClusterScanNetworksParams: NSObject {
    public var breadcrumb: NSNumber?
    public var serverSideProcessingTimeout: NSNumber?
    public var ssid: Data?
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRNetworkCommissioningClusterScanNetworksParams(breadcrumb: \(breadcrumb as Optional<Any>), serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), ssid: \(ssid as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}
open class MTRNetworkCommissioningClusterScanNetworksResponseParams: NSObject {
    public init(responseValue: [String : Any]) throws {
        if let err = responseValue[MTRErrorKey] as? (any Error) {
            throw err
        }
        super.init()
        _ = responseValue[MTRDataKey] as? [String: Any]
    }
    public var debugText: String?
    public var networkingStatus: NSNumber = 0
    public var threadScanResults: [Any]?
    public var timedInvokeTimeoutMs: NSNumber?
    public var wiFiScanResults: [Any]?
    public override init() { super.init() }
    public override var description: String {
        "MTRNetworkCommissioningClusterScanNetworksResponseParams(debugText: \(debugText as Optional<Any>), networkingStatus: \(networkingStatus as Optional<Any>), threadScanResults: \(threadScanResults as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>), wiFiScanResults: \(wiFiScanResults as Optional<Any>))"
    }
}
open class MTRNetworkCommissioningClusterThreadInterfaceScanResultStruct: NSObject {
    public var channel: NSNumber = 0
    public var extendedAddress: Data = Data()
    public var extendedPanId: NSNumber = 0
    public var lqi: NSNumber = 0
    public var networkName: String = ""
    public var panId: NSNumber = 0
    public var rssi: NSNumber = 0
    public var version: NSNumber = 0
    public override init() { super.init() }
    public override var description: String {
        "MTRNetworkCommissioningClusterThreadInterfaceScanResultStruct(channel: \(channel as Optional<Any>), extendedAddress: \(extendedAddress as Optional<Any>), extendedPanId: \(extendedPanId as Optional<Any>), lqi: \(lqi as Optional<Any>), networkName: \(networkName as Optional<Any>), panId: \(panId as Optional<Any>), rssi: \(rssi as Optional<Any>), version: \(version as Optional<Any>))"
    }
}
open class MTRNetworkCommissioningClusterWiFiInterfaceScanResultStruct: NSObject {
    public var bssid: Data = Data()
    public var channel: NSNumber = 0
    public var rssi: NSNumber = 0
    public var security: NSNumber = 0
    public var ssid: Data = Data()
    public var wiFiBand: NSNumber = 0
    public override init() { super.init() }
    public override var description: String {
        "MTRNetworkCommissioningClusterWiFiInterfaceScanResultStruct(bssid: \(bssid as Optional<Any>), channel: \(channel as Optional<Any>), rssi: \(rssi as Optional<Any>), security: \(security as Optional<Any>), ssid: \(ssid as Optional<Any>), wiFiBand: \(wiFiBand as Optional<Any>))"
    }
}
open class MTROTASoftwareUpdateProviderClusterApplyUpdateRequestParams: NSObject {
    public var newVersion: NSNumber = 0
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public var updateToken: Data = Data()
    public override init() { super.init() }
    public override var description: String {
        "MTROTASoftwareUpdateProviderClusterApplyUpdateRequestParams(newVersion: \(newVersion as Optional<Any>), serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>), updateToken: \(updateToken as Optional<Any>))"
    }
}
open class MTROTASoftwareUpdateProviderClusterApplyUpdateResponseParams: NSObject {
    public init(responseValue: [String : Any]) throws {
        if let err = responseValue[MTRErrorKey] as? (any Error) {
            throw err
        }
        super.init()
        _ = responseValue[MTRDataKey] as? [String: Any]
    }
    public var action: NSNumber = 0
    public var delayedActionTime: NSNumber = 0
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTROTASoftwareUpdateProviderClusterApplyUpdateResponseParams(action: \(action as Optional<Any>), delayedActionTime: \(delayedActionTime as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}
open class MTROTASoftwareUpdateProviderClusterNotifyUpdateAppliedParams: NSObject {
    public var serverSideProcessingTimeout: NSNumber?
    public var softwareVersion: NSNumber = 0
    public var timedInvokeTimeoutMs: NSNumber?
    public var updateToken: Data = Data()
    public override init() { super.init() }
    public override var description: String {
        "MTROTASoftwareUpdateProviderClusterNotifyUpdateAppliedParams(serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), softwareVersion: \(softwareVersion as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>), updateToken: \(updateToken as Optional<Any>))"
    }
}
open class MTROTASoftwareUpdateProviderClusterQueryImageParams: NSObject {
    public var hardwareVersion: NSNumber?
    public var location: String?
    public var metadataForProvider: Data?
    public var productID: NSNumber = 0
    public var productId: NSNumber = 0
    public var protocolsSupported: [Any] = []
    public var requestorCanConsent: NSNumber?
    public var serverSideProcessingTimeout: NSNumber?
    public var softwareVersion: NSNumber = 0
    public var timedInvokeTimeoutMs: NSNumber?
    public var vendorID: NSNumber = 0
    public var vendorId: NSNumber = 0
    public override init() { super.init() }
    public override var description: String {
        "MTROTASoftwareUpdateProviderClusterQueryImageParams(hardwareVersion: \(hardwareVersion as Optional<Any>), location: \(location as Optional<Any>), metadataForProvider: \(metadataForProvider as Optional<Any>), productID: \(productID as Optional<Any>), productId: \(productId as Optional<Any>), protocolsSupported: \(protocolsSupported as Optional<Any>), requestorCanConsent: \(requestorCanConsent as Optional<Any>), serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), softwareVersion: \(softwareVersion as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>), vendorID: \(vendorID as Optional<Any>), vendorId: \(vendorId as Optional<Any>))"
    }
}
open class MTROTASoftwareUpdateProviderClusterQueryImageResponseParams: NSObject {
    public init(responseValue: [String : Any]) throws {
        if let err = responseValue[MTRErrorKey] as? (any Error) {
            throw err
        }
        super.init()
        _ = responseValue[MTRDataKey] as? [String: Any]
    }
    public var delayedActionTime: NSNumber?
    public var imageURI: String?
    public var metadataForRequestor: Data?
    public var softwareVersion: NSNumber?
    public var softwareVersionString: String?
    public var status: NSNumber = 0
    public var timedInvokeTimeoutMs: NSNumber?
    public var updateToken: Data?
    public var userConsentNeeded: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTROTASoftwareUpdateProviderClusterQueryImageResponseParams(delayedActionTime: \(delayedActionTime as Optional<Any>), imageURI: \(imageURI as Optional<Any>), metadataForRequestor: \(metadataForRequestor as Optional<Any>), softwareVersion: \(softwareVersion as Optional<Any>), softwareVersionString: \(softwareVersionString as Optional<Any>), status: \(status as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>), updateToken: \(updateToken as Optional<Any>), userConsentNeeded: \(userConsentNeeded as Optional<Any>))"
    }
}
open class MTROTASoftwareUpdateRequestorClusterAnnounceOTAProviderParams: NSObject {
    public var announcementReason: NSNumber = 0
    public var endpoint: NSNumber = 0
    public var metadataForNode: Data?
    public var providerNodeID: NSNumber = 0
    public var providerNodeId: NSNumber = 0
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public var vendorID: NSNumber = 0
    public var vendorId: NSNumber = 0
    public override init() { super.init() }
    public override var description: String {
        "MTROTASoftwareUpdateRequestorClusterAnnounceOTAProviderParams(announcementReason: \(announcementReason as Optional<Any>), endpoint: \(endpoint as Optional<Any>), metadataForNode: \(metadataForNode as Optional<Any>), providerNodeID: \(providerNodeID as Optional<Any>), providerNodeId: \(providerNodeId as Optional<Any>), serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>), vendorID: \(vendorID as Optional<Any>), vendorId: \(vendorId as Optional<Any>))"
    }
}
open class MTROTASoftwareUpdateRequestorClusterDownloadErrorEvent: NSObject {
    public var bytesDownloaded: NSNumber = 0
    public var platformCode: NSNumber?
    public var progressPercent: NSNumber?
    public var softwareVersion: NSNumber = 0
    public override init() { super.init() }
    public override var description: String {
        "MTROTASoftwareUpdateRequestorClusterDownloadErrorEvent(bytesDownloaded: \(bytesDownloaded as Optional<Any>), platformCode: \(platformCode as Optional<Any>), progressPercent: \(progressPercent as Optional<Any>), softwareVersion: \(softwareVersion as Optional<Any>))"
    }
}
open class MTROTASoftwareUpdateRequestorClusterProviderLocation: NSObject {
    public var endpoint: NSNumber = 0
    public var fabricIndex: NSNumber = 0
    public var providerNodeID: NSNumber = 0
    public override init() { super.init() }
    public override var description: String {
        "MTROTASoftwareUpdateRequestorClusterProviderLocation(endpoint: \(endpoint as Optional<Any>), fabricIndex: \(fabricIndex as Optional<Any>), providerNodeID: \(providerNodeID as Optional<Any>))"
    }
}
open class MTROTASoftwareUpdateRequestorClusterStateTransitionEvent: NSObject {
    public var newState: NSNumber = 0
    public var previousState: NSNumber = 0
    public var reason: NSNumber = 0
    public var targetSoftwareVersion: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTROTASoftwareUpdateRequestorClusterStateTransitionEvent(newState: \(newState as Optional<Any>), previousState: \(previousState as Optional<Any>), reason: \(reason as Optional<Any>), targetSoftwareVersion: \(targetSoftwareVersion as Optional<Any>))"
    }
}
open class MTROTASoftwareUpdateRequestorClusterVersionAppliedEvent: NSObject {
    public var productID: NSNumber = 0
    public var softwareVersion: NSNumber = 0
    public override init() { super.init() }
    public override var description: String {
        "MTROTASoftwareUpdateRequestorClusterVersionAppliedEvent(productID: \(productID as Optional<Any>), softwareVersion: \(softwareVersion as Optional<Any>))"
    }
}
open class MTROccupancySensingClusterHoldTimeLimitsStruct: NSObject {
    public var holdTimeDefault: NSNumber = 0
    public var holdTimeMax: NSNumber = 0
    public var holdTimeMin: NSNumber = 0
    public override init() { super.init() }
    public override var description: String {
        "MTROccupancySensingClusterHoldTimeLimitsStruct(holdTimeDefault: \(holdTimeDefault as Optional<Any>), holdTimeMax: \(holdTimeMax as Optional<Any>), holdTimeMin: \(holdTimeMin as Optional<Any>))"
    }
}
open class MTROccupancySensingClusterOccupancyChangedEvent: NSObject {
    public var occupancy: NSNumber = 0
    public override init() { super.init() }
    public override var description: String {
        "MTROccupancySensingClusterOccupancyChangedEvent(occupancy: \(occupancy as Optional<Any>))"
    }
}
open class MTROnOffClusterOffParams: NSObject {
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTROnOffClusterOffParams(serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}
open class MTROnOffClusterOffWithEffectParams: NSObject {
    public var effectId: NSNumber = 0
    public var effectIdentifier: NSNumber = 0
    public var effectVariant: NSNumber = 0
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTROnOffClusterOffWithEffectParams(effectId: \(effectId as Optional<Any>), effectIdentifier: \(effectIdentifier as Optional<Any>), effectVariant: \(effectVariant as Optional<Any>), serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}
open class MTROnOffClusterOnParams: NSObject {
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTROnOffClusterOnParams(serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}
open class MTROnOffClusterOnWithRecallGlobalSceneParams: NSObject {
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTROnOffClusterOnWithRecallGlobalSceneParams(serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}
open class MTROnOffClusterOnWithTimedOffParams: NSObject {
    public var offWaitTime: NSNumber = 0
    public var onOffControl: NSNumber = 0
    public var onTime: NSNumber = 0
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTROnOffClusterOnWithTimedOffParams(offWaitTime: \(offWaitTime as Optional<Any>), onOffControl: \(onOffControl as Optional<Any>), onTime: \(onTime as Optional<Any>), serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}
open class MTROnOffClusterToggleParams: NSObject {
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTROnOffClusterToggleParams(serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}
open class MTROperationalCredentialsClusterAddNOCParams: NSObject {
    public var adminVendorId: NSNumber = 0
    public var caseAdminSubject: NSNumber = 0
    public var icacValue: Data?
    public var ipkValue: Data = Data()
    public var nocValue: Data = Data()
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTROperationalCredentialsClusterAddNOCParams(adminVendorId: \(adminVendorId as Optional<Any>), caseAdminSubject: \(caseAdminSubject as Optional<Any>), icacValue: \(icacValue as Optional<Any>), ipkValue: \(ipkValue as Optional<Any>), nocValue: \(nocValue as Optional<Any>), serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}
open class MTROperationalCredentialsClusterAddTrustedRootCertificateParams: NSObject {
    public var rootCACertificate: Data = Data()
    public var rootCertificate: Data = Data()
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTROperationalCredentialsClusterAddTrustedRootCertificateParams(rootCACertificate: \(rootCACertificate as Optional<Any>), rootCertificate: \(rootCertificate as Optional<Any>), serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}
open class MTROperationalCredentialsClusterAttestationRequestParams: NSObject {
    public var attestationNonce: Data = Data()
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTROperationalCredentialsClusterAttestationRequestParams(attestationNonce: \(attestationNonce as Optional<Any>), serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}
open class MTROperationalCredentialsClusterAttestationResponseParams: NSObject {
    public init(responseValue: [String : Any]) throws {
        if let err = responseValue[MTRErrorKey] as? (any Error) {
            throw err
        }
        super.init()
        _ = responseValue[MTRDataKey] as? [String: Any]
    }
    public var attestationElements: Data = Data()
    public var attestationSignature: Data = Data()
    public var signature: Data = Data()
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTROperationalCredentialsClusterAttestationResponseParams(attestationElements: \(attestationElements as Optional<Any>), attestationSignature: \(attestationSignature as Optional<Any>), signature: \(signature as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}
open class MTROperationalCredentialsClusterCSRRequestParams: NSObject {
    public var csrNonce: Data = Data()
    public var isForUpdateNOC: NSNumber?
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTROperationalCredentialsClusterCSRRequestParams(csrNonce: \(csrNonce as Optional<Any>), isForUpdateNOC: \(isForUpdateNOC as Optional<Any>), serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}
open class MTROperationalCredentialsClusterCSRResponseParams: NSObject {
    public init(responseValue: [String : Any]) throws {
        if let err = responseValue[MTRErrorKey] as? (any Error) {
            throw err
        }
        super.init()
        _ = responseValue[MTRDataKey] as? [String: Any]
    }
    public var attestationSignature: Data = Data()
    public var nocsrElements: Data = Data()
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTROperationalCredentialsClusterCSRResponseParams(attestationSignature: \(attestationSignature as Optional<Any>), nocsrElements: \(nocsrElements as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}
open class MTROperationalCredentialsClusterCertificateChainRequestParams: NSObject {
    public var certificateType: NSNumber = 0
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTROperationalCredentialsClusterCertificateChainRequestParams(certificateType: \(certificateType as Optional<Any>), serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}
open class MTROperationalCredentialsClusterCertificateChainResponseParams: NSObject {
    public init(responseValue: [String : Any]) throws {
        if let err = responseValue[MTRErrorKey] as? (any Error) {
            throw err
        }
        super.init()
        _ = responseValue[MTRDataKey] as? [String: Any]
    }
    public var certificate: Data = Data()
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTROperationalCredentialsClusterCertificateChainResponseParams(certificate: \(certificate as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}
open class MTROperationalCredentialsClusterFabricDescriptorStruct: NSObject {
    public var fabricID: NSNumber = 0
    public var fabricId: NSNumber = 0
    public var fabricIndex: NSNumber = 0
    public var label: String = ""
    public var nodeID: NSNumber = 0
    public var nodeId: NSNumber = 0
    public var rootPublicKey: Data = Data()
    public var vendorID: NSNumber = 0
    public var vendorId: NSNumber = 0
    public override init() { super.init() }
    public override var description: String {
        "MTROperationalCredentialsClusterFabricDescriptorStruct(fabricID: \(fabricID as Optional<Any>), fabricId: \(fabricId as Optional<Any>), fabricIndex: \(fabricIndex as Optional<Any>), label: \(label as Optional<Any>), nodeID: \(nodeID as Optional<Any>), nodeId: \(nodeId as Optional<Any>), rootPublicKey: \(rootPublicKey as Optional<Any>), vendorID: \(vendorID as Optional<Any>), vendorId: \(vendorId as Optional<Any>))"
    }
}
open class MTROperationalCredentialsClusterNOCResponseParams: NSObject {
    public init(responseValue: [String : Any]) throws {
        if let err = responseValue[MTRErrorKey] as? (any Error) {
            throw err
        }
        super.init()
        _ = responseValue[MTRDataKey] as? [String: Any]
    }
    public var debugText: String?
    public var fabricIndex: NSNumber?
    public var statusCode: NSNumber = 0
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTROperationalCredentialsClusterNOCResponseParams(debugText: \(debugText as Optional<Any>), fabricIndex: \(fabricIndex as Optional<Any>), statusCode: \(statusCode as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}
open class MTROperationalCredentialsClusterNOCStruct: NSObject {
    public var fabricIndex: NSNumber = 0
    public var icac: Data?
    public var noc: Data = Data()
    public override init() { super.init() }
    public override var description: String {
        "MTROperationalCredentialsClusterNOCStruct(fabricIndex: \(fabricIndex as Optional<Any>), icac: \(icac as Optional<Any>), noc: \(noc as Optional<Any>))"
    }
}
open class MTROperationalCredentialsClusterRemoveFabricParams: NSObject {
    public var fabricIndex: NSNumber = 0
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTROperationalCredentialsClusterRemoveFabricParams(fabricIndex: \(fabricIndex as Optional<Any>), serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}
open class MTROperationalCredentialsClusterUpdateFabricLabelParams: NSObject {
    public var label: String = ""
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTROperationalCredentialsClusterUpdateFabricLabelParams(label: \(label as Optional<Any>), serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}
open class MTROperationalCredentialsClusterUpdateNOCParams: NSObject {
    public var icacValue: Data?
    public var nocValue: Data = Data()
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTROperationalCredentialsClusterUpdateNOCParams(icacValue: \(icacValue as Optional<Any>), nocValue: \(nocValue as Optional<Any>), serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}
open class MTROperationalStateClusterErrorStateStruct: NSObject {
    public var errorStateDetails: String?
    public var errorStateID: NSNumber = 0
    public var errorStateLabel: String?
    public override init() { super.init() }
    public override var description: String {
        "MTROperationalStateClusterErrorStateStruct(errorStateDetails: \(errorStateDetails as Optional<Any>), errorStateID: \(errorStateID as Optional<Any>), errorStateLabel: \(errorStateLabel as Optional<Any>))"
    }
}
open class MTROperationalStateClusterOperationCompletionEvent: NSObject {
    public var completionErrorCode: NSNumber = 0
    public var pausedTime: NSNumber?
    public var totalOperationalTime: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTROperationalStateClusterOperationCompletionEvent(completionErrorCode: \(completionErrorCode as Optional<Any>), pausedTime: \(pausedTime as Optional<Any>), totalOperationalTime: \(totalOperationalTime as Optional<Any>))"
    }
}
open class MTROperationalStateClusterOperationalCommandResponseParams: NSObject {
    public init(responseValue: [String : Any]) throws {
        if let err = responseValue[MTRErrorKey] as? (any Error) {
            throw err
        }
        super.init()
        _ = responseValue[MTRDataKey] as? [String: Any]
    }
    public var commandResponseState: MTROperationalStateClusterErrorStateStruct = MTROperationalStateClusterErrorStateStruct()
    public override init() { super.init() }
    public override var description: String {
        "MTROperationalStateClusterOperationalCommandResponseParams(commandResponseState: \(commandResponseState as Optional<Any>))"
    }
}
open class MTROperationalStateClusterOperationalErrorEvent: NSObject {
    public var errorState: MTROperationalStateClusterErrorStateStruct = MTROperationalStateClusterErrorStateStruct()
    public override init() { super.init() }
    public override var description: String {
        "MTROperationalStateClusterOperationalErrorEvent(errorState: \(errorState as Optional<Any>))"
    }
}
open class MTROperationalStateClusterOperationalStateStruct: NSObject {
    public var operationalStateID: NSNumber = 0
    public var operationalStateLabel: String?
    public override init() { super.init() }
    public override var description: String {
        "MTROperationalStateClusterOperationalStateStruct(operationalStateID: \(operationalStateID as Optional<Any>), operationalStateLabel: \(operationalStateLabel as Optional<Any>))"
    }
}
open class MTROperationalStateClusterPauseParams: NSObject {
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTROperationalStateClusterPauseParams(serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}
open class MTROperationalStateClusterResumeParams: NSObject {
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTROperationalStateClusterResumeParams(serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}
open class MTROperationalStateClusterStartParams: NSObject {
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTROperationalStateClusterStartParams(serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}
open class MTROperationalStateClusterStopParams: NSObject {
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTROperationalStateClusterStopParams(serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}
open class MTROvenCavityOperationalStateClusterErrorStateStruct: NSObject {
    public var errorStateDetails: String?
    public var errorStateID: NSNumber = 0
    public var errorStateLabel: String?
    public override init() { super.init() }
    public override var description: String {
        "MTROvenCavityOperationalStateClusterErrorStateStruct(errorStateDetails: \(errorStateDetails as Optional<Any>), errorStateID: \(errorStateID as Optional<Any>), errorStateLabel: \(errorStateLabel as Optional<Any>))"
    }
}
open class MTROvenCavityOperationalStateClusterOperationCompletionEvent: NSObject {
    public var completionErrorCode: NSNumber = 0
    public var pausedTime: NSNumber?
    public var totalOperationalTime: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTROvenCavityOperationalStateClusterOperationCompletionEvent(completionErrorCode: \(completionErrorCode as Optional<Any>), pausedTime: \(pausedTime as Optional<Any>), totalOperationalTime: \(totalOperationalTime as Optional<Any>))"
    }
}
open class MTROvenCavityOperationalStateClusterOperationalCommandResponseParams: NSObject {
    public init(responseValue: [String : Any]) throws {
        if let err = responseValue[MTRErrorKey] as? (any Error) {
            throw err
        }
        super.init()
        _ = responseValue[MTRDataKey] as? [String: Any]
    }
    public var commandResponseState: MTROvenCavityOperationalStateClusterErrorStateStruct = MTROvenCavityOperationalStateClusterErrorStateStruct()
    public override init() { super.init() }
    public override var description: String {
        "MTROvenCavityOperationalStateClusterOperationalCommandResponseParams(commandResponseState: \(commandResponseState as Optional<Any>))"
    }
}
open class MTROvenCavityOperationalStateClusterOperationalErrorEvent: NSObject {
    public var errorState: MTROvenCavityOperationalStateClusterErrorStateStruct = MTROvenCavityOperationalStateClusterErrorStateStruct()
    public override init() { super.init() }
    public override var description: String {
        "MTROvenCavityOperationalStateClusterOperationalErrorEvent(errorState: \(errorState as Optional<Any>))"
    }
}
open class MTROvenCavityOperationalStateClusterOperationalStateStruct: NSObject {
    public var operationalStateID: NSNumber = 0
    public var operationalStateLabel: String?
    public override init() { super.init() }
    public override var description: String {
        "MTROvenCavityOperationalStateClusterOperationalStateStruct(operationalStateID: \(operationalStateID as Optional<Any>), operationalStateLabel: \(operationalStateLabel as Optional<Any>))"
    }
}
open class MTROvenCavityOperationalStateClusterStartParams: NSObject {
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTROvenCavityOperationalStateClusterStartParams(serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}
open class MTROvenCavityOperationalStateClusterStopParams: NSObject {
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTROvenCavityOperationalStateClusterStopParams(serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}
open class MTROvenModeClusterChangeToModeParams: NSObject {
    public var newMode: NSNumber = 0
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTROvenModeClusterChangeToModeParams(newMode: \(newMode as Optional<Any>), serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}
open class MTROvenModeClusterChangeToModeResponseParams: NSObject {
    public init(responseValue: [String : Any]) throws {
        if let err = responseValue[MTRErrorKey] as? (any Error) {
            throw err
        }
        super.init()
        _ = responseValue[MTRDataKey] as? [String: Any]
    }
    public var status: NSNumber = 0
    public var statusText: String?
    public override init() { super.init() }
    public override var description: String {
        "MTROvenModeClusterChangeToModeResponseParams(status: \(status as Optional<Any>), statusText: \(statusText as Optional<Any>))"
    }
}
open class MTROvenModeClusterModeOptionStruct: NSObject {
    public var label: String = ""
    public var mode: NSNumber = 0
    public var modeTags: [Any] = []
    public override init() { super.init() }
    public override var description: String {
        "MTROvenModeClusterModeOptionStruct(label: \(label as Optional<Any>), mode: \(mode as Optional<Any>), modeTags: \(modeTags as Optional<Any>))"
    }
}
open class MTROvenModeClusterModeTagStruct: NSObject {
    public var mfgCode: NSNumber?
    public var value: NSNumber = 0
    public override init() { super.init() }
    public override var description: String {
        "MTROvenModeClusterModeTagStruct(mfgCode: \(mfgCode as Optional<Any>), value: \(value as Optional<Any>))"
    }
}
open class MTRRVCCleanModeClusterChangeToModeParams: NSObject {
    public var newMode: NSNumber = 0
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRRVCCleanModeClusterChangeToModeParams(newMode: \(newMode as Optional<Any>), serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}
open class MTRRVCCleanModeClusterChangeToModeResponseParams: NSObject {
    public init(responseValue: [String : Any]) throws {
        if let err = responseValue[MTRErrorKey] as? (any Error) {
            throw err
        }
        super.init()
        _ = responseValue[MTRDataKey] as? [String: Any]
    }
    public var status: NSNumber = 0
    public var statusText: String?
    public override init() { super.init() }
    public override var description: String {
        "MTRRVCCleanModeClusterChangeToModeResponseParams(status: \(status as Optional<Any>), statusText: \(statusText as Optional<Any>))"
    }
}
open class MTRRVCCleanModeClusterModeOptionStruct: NSObject {
    public var label: String = ""
    public var mode: NSNumber = 0
    public var modeTags: [Any] = []
    public override init() { super.init() }
    public override var description: String {
        "MTRRVCCleanModeClusterModeOptionStruct(label: \(label as Optional<Any>), mode: \(mode as Optional<Any>), modeTags: \(modeTags as Optional<Any>))"
    }
}
open class MTRRVCCleanModeClusterModeTagStruct: NSObject {
    public var mfgCode: NSNumber?
    public var value: NSNumber = 0
    public override init() { super.init() }
    public override var description: String {
        "MTRRVCCleanModeClusterModeTagStruct(mfgCode: \(mfgCode as Optional<Any>), value: \(value as Optional<Any>))"
    }
}
open class MTRRVCOperationalStateClusterErrorStateStruct: NSObject {
    public var errorStateDetails: String?
    public var errorStateID: NSNumber = 0
    public var errorStateLabel: String?
    public override init() { super.init() }
    public override var description: String {
        "MTRRVCOperationalStateClusterErrorStateStruct(errorStateDetails: \(errorStateDetails as Optional<Any>), errorStateID: \(errorStateID as Optional<Any>), errorStateLabel: \(errorStateLabel as Optional<Any>))"
    }
}
open class MTRRVCOperationalStateClusterGoHomeParams: NSObject {
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRRVCOperationalStateClusterGoHomeParams(serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}
open class MTRRVCOperationalStateClusterOperationCompletionEvent: NSObject {
    public var completionErrorCode: NSNumber = 0
    public var pausedTime: NSNumber?
    public var totalOperationalTime: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRRVCOperationalStateClusterOperationCompletionEvent(completionErrorCode: \(completionErrorCode as Optional<Any>), pausedTime: \(pausedTime as Optional<Any>), totalOperationalTime: \(totalOperationalTime as Optional<Any>))"
    }
}
open class MTRRVCOperationalStateClusterOperationalCommandResponseParams: NSObject {
    public init(responseValue: [String : Any]) throws {
        if let err = responseValue[MTRErrorKey] as? (any Error) {
            throw err
        }
        super.init()
        _ = responseValue[MTRDataKey] as? [String: Any]
    }
    public var commandResponseState: MTRRVCOperationalStateClusterErrorStateStruct = MTRRVCOperationalStateClusterErrorStateStruct()
    public override init() { super.init() }
    public override var description: String {
        "MTRRVCOperationalStateClusterOperationalCommandResponseParams(commandResponseState: \(commandResponseState as Optional<Any>))"
    }
}
open class MTRRVCOperationalStateClusterOperationalErrorEvent: NSObject {
    public var errorState: MTRRVCOperationalStateClusterErrorStateStruct = MTRRVCOperationalStateClusterErrorStateStruct()
    public override init() { super.init() }
    public override var description: String {
        "MTRRVCOperationalStateClusterOperationalErrorEvent(errorState: \(errorState as Optional<Any>))"
    }
}
open class MTRRVCOperationalStateClusterOperationalStateStruct: NSObject {
    public var operationalStateID: NSNumber = 0
    public var operationalStateLabel: String?
    public override init() { super.init() }
    public override var description: String {
        "MTRRVCOperationalStateClusterOperationalStateStruct(operationalStateID: \(operationalStateID as Optional<Any>), operationalStateLabel: \(operationalStateLabel as Optional<Any>))"
    }
}
open class MTRRVCOperationalStateClusterPauseParams: NSObject {
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRRVCOperationalStateClusterPauseParams(serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}
open class MTRRVCOperationalStateClusterResumeParams: NSObject {
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRRVCOperationalStateClusterResumeParams(serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}
open class MTRRVCRunModeClusterChangeToModeParams: NSObject {
    public var newMode: NSNumber = 0
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRRVCRunModeClusterChangeToModeParams(newMode: \(newMode as Optional<Any>), serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}
open class MTRRVCRunModeClusterChangeToModeResponseParams: NSObject {
    public init(responseValue: [String : Any]) throws {
        if let err = responseValue[MTRErrorKey] as? (any Error) {
            throw err
        }
        super.init()
        _ = responseValue[MTRDataKey] as? [String: Any]
    }
    public var status: NSNumber = 0
    public var statusText: String?
    public override init() { super.init() }
    public override var description: String {
        "MTRRVCRunModeClusterChangeToModeResponseParams(status: \(status as Optional<Any>), statusText: \(statusText as Optional<Any>))"
    }
}
open class MTRRVCRunModeClusterModeOptionStruct: NSObject {
    public var label: String = ""
    public var mode: NSNumber = 0
    public var modeTags: [Any] = []
    public override init() { super.init() }
    public override var description: String {
        "MTRRVCRunModeClusterModeOptionStruct(label: \(label as Optional<Any>), mode: \(mode as Optional<Any>), modeTags: \(modeTags as Optional<Any>))"
    }
}
open class MTRRVCRunModeClusterModeTagStruct: NSObject {
    public var mfgCode: NSNumber?
    public var value: NSNumber = 0
    public override init() { super.init() }
    public override var description: String {
        "MTRRVCRunModeClusterModeTagStruct(mfgCode: \(mfgCode as Optional<Any>), value: \(value as Optional<Any>))"
    }
}
open class MTRRefrigeratorAlarmClusterNotifyEvent: NSObject {
    public var active: NSNumber = 0
    public var inactive: NSNumber = 0
    public var mask: NSNumber = 0
    public var state: NSNumber = 0
    public override init() { super.init() }
    public override var description: String {
        "MTRRefrigeratorAlarmClusterNotifyEvent(active: \(active as Optional<Any>), inactive: \(inactive as Optional<Any>), mask: \(mask as Optional<Any>), state: \(state as Optional<Any>))"
    }
}
open class MTRRefrigeratorAndTemperatureControlledCabinetModeClusterChangeToModeParams: NSObject {
    public var newMode: NSNumber = 0
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRRefrigeratorAndTemperatureControlledCabinetModeClusterChangeToModeParams(newMode: \(newMode as Optional<Any>), serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}
open class MTRRefrigeratorAndTemperatureControlledCabinetModeClusterChangeToModeResponseParams: NSObject {
    public init(responseValue: [String : Any]) throws {
        if let err = responseValue[MTRErrorKey] as? (any Error) {
            throw err
        }
        super.init()
        _ = responseValue[MTRDataKey] as? [String: Any]
    }
    public var status: NSNumber = 0
    public var statusText: String?
    public override init() { super.init() }
    public override var description: String {
        "MTRRefrigeratorAndTemperatureControlledCabinetModeClusterChangeToModeResponseParams(status: \(status as Optional<Any>), statusText: \(statusText as Optional<Any>))"
    }
}
open class MTRRefrigeratorAndTemperatureControlledCabinetModeClusterModeOptionStruct: NSObject {
    public var label: String = ""
    public var mode: NSNumber = 0
    public var modeTags: [Any] = []
    public override init() { super.init() }
    public override var description: String {
        "MTRRefrigeratorAndTemperatureControlledCabinetModeClusterModeOptionStruct(label: \(label as Optional<Any>), mode: \(mode as Optional<Any>), modeTags: \(modeTags as Optional<Any>))"
    }
}
open class MTRRefrigeratorAndTemperatureControlledCabinetModeClusterModeTagStruct: NSObject {
    public var mfgCode: NSNumber?
    public var value: NSNumber = 0
    public override init() { super.init() }
    public override var description: String {
        "MTRRefrigeratorAndTemperatureControlledCabinetModeClusterModeTagStruct(mfgCode: \(mfgCode as Optional<Any>), value: \(value as Optional<Any>))"
    }
}
open class MTRServiceAreaClusterAreaInfoStruct: NSObject {
    public var landmarkInfo: MTRServiceAreaClusterLandmarkInfoStruct?
    public var locationInfo: MTRDataTypeLocationDescriptorStruct?
    public override init() { super.init() }
    public override var description: String {
        "MTRServiceAreaClusterAreaInfoStruct(landmarkInfo: \(landmarkInfo as Optional<Any>), locationInfo: \(locationInfo as Optional<Any>))"
    }
}
open class MTRServiceAreaClusterAreaStruct: NSObject {
    public var areaID: NSNumber = 0
    public var areaInfo: MTRServiceAreaClusterAreaInfoStruct = MTRServiceAreaClusterAreaInfoStruct()
    public var mapID: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRServiceAreaClusterAreaStruct(areaID: \(areaID as Optional<Any>), areaInfo: \(areaInfo as Optional<Any>), mapID: \(mapID as Optional<Any>))"
    }
}
open class MTRServiceAreaClusterLandmarkInfoStruct: NSObject {
    public var landmarkTag: NSNumber = 0
    public var relativePositionTag: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRServiceAreaClusterLandmarkInfoStruct(landmarkTag: \(landmarkTag as Optional<Any>), relativePositionTag: \(relativePositionTag as Optional<Any>))"
    }
}
open class MTRServiceAreaClusterMapStruct: NSObject {
    public var mapID: NSNumber = 0
    public var name: String = ""
    public override init() { super.init() }
    public override var description: String {
        "MTRServiceAreaClusterMapStruct(mapID: \(mapID as Optional<Any>), name: \(name as Optional<Any>))"
    }
}
open class MTRServiceAreaClusterProgressStruct: NSObject {
    public var areaID: NSNumber = 0
    public var status: NSNumber = 0
    public var totalOperationalTime: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRServiceAreaClusterProgressStruct(areaID: \(areaID as Optional<Any>), status: \(status as Optional<Any>), totalOperationalTime: \(totalOperationalTime as Optional<Any>))"
    }
}
open class MTRServiceAreaClusterSelectAreasParams: NSObject {
    public var newAreas: [Any] = []
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRServiceAreaClusterSelectAreasParams(newAreas: \(newAreas as Optional<Any>), serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}
open class MTRServiceAreaClusterSelectAreasResponseParams: NSObject {
    public init(responseValue: [String : Any]) throws {
        if let err = responseValue[MTRErrorKey] as? (any Error) {
            throw err
        }
        super.init()
        _ = responseValue[MTRDataKey] as? [String: Any]
    }
    public var status: NSNumber = 0
    public var statusText: String = ""
    public override init() { super.init() }
    public override var description: String {
        "MTRServiceAreaClusterSelectAreasResponseParams(status: \(status as Optional<Any>), statusText: \(statusText as Optional<Any>))"
    }
}
open class MTRServiceAreaClusterSkipAreaParams: NSObject {
    public var serverSideProcessingTimeout: NSNumber?
    public var skippedArea: NSNumber = 0
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRServiceAreaClusterSkipAreaParams(serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), skippedArea: \(skippedArea as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}
open class MTRServiceAreaClusterSkipAreaResponseParams: NSObject {
    public init(responseValue: [String : Any]) throws {
        if let err = responseValue[MTRErrorKey] as? (any Error) {
            throw err
        }
        super.init()
        _ = responseValue[MTRDataKey] as? [String: Any]
    }
    public var status: NSNumber = 0
    public var statusText: String = ""
    public override init() { super.init() }
    public override var description: String {
        "MTRServiceAreaClusterSkipAreaResponseParams(status: \(status as Optional<Any>), statusText: \(statusText as Optional<Any>))"
    }
}
open class MTRSmokeCOAlarmClusterCOAlarmEvent: NSObject {
    public var alarmSeverityLevel: NSNumber = 0
    public override init() { super.init() }
    public override var description: String {
        "MTRSmokeCOAlarmClusterCOAlarmEvent(alarmSeverityLevel: \(alarmSeverityLevel as Optional<Any>))"
    }
}
open class MTRSmokeCOAlarmClusterInterconnectCOAlarmEvent: NSObject {
    public var alarmSeverityLevel: NSNumber = 0
    public override init() { super.init() }
    public override var description: String {
        "MTRSmokeCOAlarmClusterInterconnectCOAlarmEvent(alarmSeverityLevel: \(alarmSeverityLevel as Optional<Any>))"
    }
}
open class MTRSmokeCOAlarmClusterInterconnectSmokeAlarmEvent: NSObject {
    public var alarmSeverityLevel: NSNumber = 0
    public override init() { super.init() }
    public override var description: String {
        "MTRSmokeCOAlarmClusterInterconnectSmokeAlarmEvent(alarmSeverityLevel: \(alarmSeverityLevel as Optional<Any>))"
    }
}
open class MTRSmokeCOAlarmClusterLowBatteryEvent: NSObject {
    public var alarmSeverityLevel: NSNumber = 0
    public override init() { super.init() }
    public override var description: String {
        "MTRSmokeCOAlarmClusterLowBatteryEvent(alarmSeverityLevel: \(alarmSeverityLevel as Optional<Any>))"
    }
}
open class MTRSmokeCOAlarmClusterSelfTestRequestParams: NSObject {
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRSmokeCOAlarmClusterSelfTestRequestParams(serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}
open class MTRSmokeCOAlarmClusterSmokeAlarmEvent: NSObject {
    public var alarmSeverityLevel: NSNumber = 0
    public override init() { super.init() }
    public override var description: String {
        "MTRSmokeCOAlarmClusterSmokeAlarmEvent(alarmSeverityLevel: \(alarmSeverityLevel as Optional<Any>))"
    }
}
open class MTRSoftwareDiagnosticsClusterResetWatermarksParams: NSObject {
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRSoftwareDiagnosticsClusterResetWatermarksParams(serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}
open class MTRSoftwareDiagnosticsClusterSoftwareFaultEvent: NSObject {
    public var faultRecording: Data?
    public var id: NSNumber = 0
    public var name: String?
    public override init() { super.init() }
    public override var description: String {
        "MTRSoftwareDiagnosticsClusterSoftwareFaultEvent(faultRecording: \(faultRecording as Optional<Any>), id: \(id as Optional<Any>), name: \(name as Optional<Any>))"
    }
}
open class MTRSoftwareDiagnosticsClusterThreadMetricsStruct: NSObject {
    public var id: NSNumber = 0
    public var name: String?
    public var stackFreeCurrent: NSNumber?
    public var stackFreeMinimum: NSNumber?
    public var stackSize: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRSoftwareDiagnosticsClusterThreadMetricsStruct(id: \(id as Optional<Any>), name: \(name as Optional<Any>), stackFreeCurrent: \(stackFreeCurrent as Optional<Any>), stackFreeMinimum: \(stackFreeMinimum as Optional<Any>), stackSize: \(stackSize as Optional<Any>))"
    }
}
open class MTRSwitchClusterInitialPressEvent: NSObject {
    public var newPosition: NSNumber = 0
    public override init() { super.init() }
    public override var description: String {
        "MTRSwitchClusterInitialPressEvent(newPosition: \(newPosition as Optional<Any>))"
    }
}
open class MTRSwitchClusterLongPressEvent: NSObject {
    public var newPosition: NSNumber = 0
    public override init() { super.init() }
    public override var description: String {
        "MTRSwitchClusterLongPressEvent(newPosition: \(newPosition as Optional<Any>))"
    }
}
open class MTRSwitchClusterLongReleaseEvent: NSObject {
    public var previousPosition: NSNumber = 0
    public override init() { super.init() }
    public override var description: String {
        "MTRSwitchClusterLongReleaseEvent(previousPosition: \(previousPosition as Optional<Any>))"
    }
}
open class MTRSwitchClusterMultiPressCompleteEvent: NSObject {
    public var newPosition: NSNumber = 0
    public var previousPosition: NSNumber = 0
    public var totalNumberOfPressesCounted: NSNumber = 0
    public override init() { super.init() }
    public override var description: String {
        "MTRSwitchClusterMultiPressCompleteEvent(newPosition: \(newPosition as Optional<Any>), previousPosition: \(previousPosition as Optional<Any>), totalNumberOfPressesCounted: \(totalNumberOfPressesCounted as Optional<Any>))"
    }
}
open class MTRSwitchClusterMultiPressOngoingEvent: NSObject {
    public var currentNumberOfPressesCounted: NSNumber = 0
    public var newPosition: NSNumber = 0
    public override init() { super.init() }
    public override var description: String {
        "MTRSwitchClusterMultiPressOngoingEvent(currentNumberOfPressesCounted: \(currentNumberOfPressesCounted as Optional<Any>), newPosition: \(newPosition as Optional<Any>))"
    }
}
open class MTRSwitchClusterShortReleaseEvent: NSObject {
    public var previousPosition: NSNumber = 0
    public override init() { super.init() }
    public override var description: String {
        "MTRSwitchClusterShortReleaseEvent(previousPosition: \(previousPosition as Optional<Any>))"
    }
}
open class MTRSwitchClusterSwitchLatchedEvent: NSObject {
    public var newPosition: NSNumber = 0
    public override init() { super.init() }
    public override var description: String {
        "MTRSwitchClusterSwitchLatchedEvent(newPosition: \(newPosition as Optional<Any>))"
    }
}
open class MTRTargetNavigatorClusterNavigateTargetParams: NSObject {
    public var data: String?
    public var serverSideProcessingTimeout: NSNumber?
    public var target: NSNumber = 0
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRTargetNavigatorClusterNavigateTargetParams(data: \(data as Optional<Any>), serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), target: \(target as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}
open class MTRTargetNavigatorClusterNavigateTargetResponseParams: NSObject {
    public init(responseValue: [String : Any]) throws {
        if let err = responseValue[MTRErrorKey] as? (any Error) {
            throw err
        }
        super.init()
        _ = responseValue[MTRDataKey] as? [String: Any]
    }
    public var data: String?
    public var status: NSNumber = 0
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRTargetNavigatorClusterNavigateTargetResponseParams(data: \(data as Optional<Any>), status: \(status as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}
open class MTRTargetNavigatorClusterTargetInfoStruct: NSObject {
    public var identifier: NSNumber = 0
    public var name: String = ""
    public override init() { super.init() }
    public override var description: String {
        "MTRTargetNavigatorClusterTargetInfoStruct(identifier: \(identifier as Optional<Any>), name: \(name as Optional<Any>))"
    }
}
open class MTRTargetNavigatorClusterTargetUpdatedEvent: NSObject {
    public var currentTarget: NSNumber = 0
    public var data: Data = Data()
    public var targetList: [Any] = []
    public override init() { super.init() }
    public override var description: String {
        "MTRTargetNavigatorClusterTargetUpdatedEvent(currentTarget: \(currentTarget as Optional<Any>), data: \(data as Optional<Any>), targetList: \(targetList as Optional<Any>))"
    }
}
open class MTRTemperatureControlClusterSetTemperatureParams: NSObject {
    public var serverSideProcessingTimeout: NSNumber?
    public var targetTemperature: NSNumber?
    public var targetTemperatureLevel: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRTemperatureControlClusterSetTemperatureParams(serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), targetTemperature: \(targetTemperature as Optional<Any>), targetTemperatureLevel: \(targetTemperatureLevel as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}
open class MTRThreadBorderRouterManagementClusterDatasetResponseParams: NSObject {
    public init(responseValue: [String : Any]) throws {
        if let err = responseValue[MTRErrorKey] as? (any Error) {
            throw err
        }
        super.init()
        _ = responseValue[MTRDataKey] as? [String: Any]
    }
    public var dataset: Data = Data()
    public override init() { super.init() }
    public override var description: String {
        "MTRThreadBorderRouterManagementClusterDatasetResponseParams(dataset: \(dataset as Optional<Any>))"
    }
}
open class MTRThreadBorderRouterManagementClusterGetActiveDatasetRequestParams: NSObject {
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRThreadBorderRouterManagementClusterGetActiveDatasetRequestParams(serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}
open class MTRThreadBorderRouterManagementClusterGetPendingDatasetRequestParams: NSObject {
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRThreadBorderRouterManagementClusterGetPendingDatasetRequestParams(serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}
open class MTRThreadBorderRouterManagementClusterSetActiveDatasetRequestParams: NSObject {
    public var activeDataset: Data = Data()
    public var breadcrumb: NSNumber?
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRThreadBorderRouterManagementClusterSetActiveDatasetRequestParams(activeDataset: \(activeDataset as Optional<Any>), breadcrumb: \(breadcrumb as Optional<Any>), serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}
open class MTRThreadBorderRouterManagementClusterSetPendingDatasetRequestParams: NSObject {
    public var pendingDataset: Data = Data()
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRThreadBorderRouterManagementClusterSetPendingDatasetRequestParams(pendingDataset: \(pendingDataset as Optional<Any>), serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}
open class MTRThreadNetworkDirectoryClusterAddNetworkParams: NSObject {
    public var operationalDataset: Data = Data()
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRThreadNetworkDirectoryClusterAddNetworkParams(operationalDataset: \(operationalDataset as Optional<Any>), serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}
open class MTRThreadNetworkDirectoryClusterGetOperationalDatasetParams: NSObject {
    public var extendedPanID: Data = Data()
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRThreadNetworkDirectoryClusterGetOperationalDatasetParams(extendedPanID: \(extendedPanID as Optional<Any>), serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}
open class MTRThreadNetworkDirectoryClusterOperationalDatasetResponseParams: NSObject {
    public init(responseValue: [String : Any]) throws {
        if let err = responseValue[MTRErrorKey] as? (any Error) {
            throw err
        }
        super.init()
        _ = responseValue[MTRDataKey] as? [String: Any]
    }
    public var operationalDataset: Data = Data()
    public override init() { super.init() }
    public override var description: String {
        "MTRThreadNetworkDirectoryClusterOperationalDatasetResponseParams(operationalDataset: \(operationalDataset as Optional<Any>))"
    }
}
open class MTRThreadNetworkDirectoryClusterRemoveNetworkParams: NSObject {
    public var extendedPanID: Data = Data()
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRThreadNetworkDirectoryClusterRemoveNetworkParams(extendedPanID: \(extendedPanID as Optional<Any>), serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}
open class MTRThreadNetworkDirectoryClusterThreadNetworkStruct: NSObject {
    public var activeTimestamp: NSNumber = 0
    public var channel: NSNumber = 0
    public var extendedPanID: Data = Data()
    public var networkName: String = ""
    public override init() { super.init() }
    public override var description: String {
        "MTRThreadNetworkDirectoryClusterThreadNetworkStruct(activeTimestamp: \(activeTimestamp as Optional<Any>), channel: \(channel as Optional<Any>), extendedPanID: \(extendedPanID as Optional<Any>), networkName: \(networkName as Optional<Any>))"
    }
}
open class MTRTimeSynchronizationClusterDSTOffsetStruct: NSObject {
    public var offset: NSNumber = 0
    public var validStarting: NSNumber = 0
    public var validUntil: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRTimeSynchronizationClusterDSTOffsetStruct(offset: \(offset as Optional<Any>), validStarting: \(validStarting as Optional<Any>), validUntil: \(validUntil as Optional<Any>))"
    }
}
open class MTRTimeSynchronizationClusterDSTStatusEvent: NSObject {
    public var dstOffsetActive: NSNumber = 0
    public override init() { super.init() }
    public override var description: String {
        "MTRTimeSynchronizationClusterDSTStatusEvent(dstOffsetActive: \(dstOffsetActive as Optional<Any>))"
    }
}
open class MTRTimeSynchronizationClusterFabricScopedTrustedTimeSourceStruct: NSObject {
    public var endpoint: NSNumber = 0
    public var nodeID: NSNumber = 0
    public override init() { super.init() }
    public override var description: String {
        "MTRTimeSynchronizationClusterFabricScopedTrustedTimeSourceStruct(endpoint: \(endpoint as Optional<Any>), nodeID: \(nodeID as Optional<Any>))"
    }
}
open class MTRTimeSynchronizationClusterSetDSTOffsetParams: NSObject {
    public var dstOffset: [Any] = []
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRTimeSynchronizationClusterSetDSTOffsetParams(dstOffset: \(dstOffset as Optional<Any>), serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}
open class MTRTimeSynchronizationClusterSetDefaultNTPParams: NSObject {
    public var defaultNTP: String?
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRTimeSynchronizationClusterSetDefaultNTPParams(defaultNTP: \(defaultNTP as Optional<Any>), serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}
open class MTRTimeSynchronizationClusterSetTimeZoneParams: NSObject {
    public var serverSideProcessingTimeout: NSNumber?
    public var timeZone: [Any] = []
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRTimeSynchronizationClusterSetTimeZoneParams(serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timeZone: \(timeZone as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}
open class MTRTimeSynchronizationClusterSetTimeZoneResponseParams: NSObject {
    public init(responseValue: [String : Any]) throws {
        if let err = responseValue[MTRErrorKey] as? (any Error) {
            throw err
        }
        super.init()
        _ = responseValue[MTRDataKey] as? [String: Any]
    }
    public var dstOffsetRequired: NSNumber = 0
    public override init() { super.init() }
    public override var description: String {
        "MTRTimeSynchronizationClusterSetTimeZoneResponseParams(dstOffsetRequired: \(dstOffsetRequired as Optional<Any>))"
    }
}
open class MTRTimeSynchronizationClusterSetTrustedTimeSourceParams: NSObject {
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public var trustedTimeSource: MTRTimeSynchronizationClusterFabricScopedTrustedTimeSourceStruct?
    public override init() { super.init() }
    public override var description: String {
        "MTRTimeSynchronizationClusterSetTrustedTimeSourceParams(serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>), trustedTimeSource: \(trustedTimeSource as Optional<Any>))"
    }
}
open class MTRTimeSynchronizationClusterSetUTCTimeParams: NSObject {
    public var granularity: NSNumber = 0
    public var serverSideProcessingTimeout: NSNumber?
    public var timeSource: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public var utcTime: NSNumber = 0
    public override init() { super.init() }
    public override var description: String {
        "MTRTimeSynchronizationClusterSetUTCTimeParams(granularity: \(granularity as Optional<Any>), serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timeSource: \(timeSource as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>), utcTime: \(utcTime as Optional<Any>))"
    }
}
open class MTRTimeSynchronizationClusterTimeZoneStatusEvent: NSObject {
    public var name: String?
    public var offset: NSNumber = 0
    public override init() { super.init() }
    public override var description: String {
        "MTRTimeSynchronizationClusterTimeZoneStatusEvent(name: \(name as Optional<Any>), offset: \(offset as Optional<Any>))"
    }
}
open class MTRTimeSynchronizationClusterTimeZoneStruct: NSObject {
    public var name: String?
    public var offset: NSNumber = 0
    public var validAt: NSNumber = 0
    public override init() { super.init() }
    public override var description: String {
        "MTRTimeSynchronizationClusterTimeZoneStruct(name: \(name as Optional<Any>), offset: \(offset as Optional<Any>), validAt: \(validAt as Optional<Any>))"
    }
}
open class MTRTimeSynchronizationClusterTrustedTimeSourceStruct: NSObject {
    public var endpoint: NSNumber = 0
    public var fabricIndex: NSNumber = 0
    public var nodeID: NSNumber = 0
    public override init() { super.init() }
    public override var description: String {
        "MTRTimeSynchronizationClusterTrustedTimeSourceStruct(endpoint: \(endpoint as Optional<Any>), fabricIndex: \(fabricIndex as Optional<Any>), nodeID: \(nodeID as Optional<Any>))"
    }
}
open class MTRUserLabelClusterLabelStruct: NSObject {
    public var label: String = ""
    public var value: String = ""
    public override init() { super.init() }
    public override var description: String {
        "MTRUserLabelClusterLabelStruct(label: \(label as Optional<Any>), value: \(value as Optional<Any>))"
    }
}
open class MTRValveConfigurationAndControlClusterCloseParams: NSObject {
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRValveConfigurationAndControlClusterCloseParams(serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}
open class MTRValveConfigurationAndControlClusterOpenParams: NSObject {
    public var openDuration: NSNumber?
    public var serverSideProcessingTimeout: NSNumber?
    public var targetLevel: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRValveConfigurationAndControlClusterOpenParams(openDuration: \(openDuration as Optional<Any>), serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), targetLevel: \(targetLevel as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}
open class MTRValveConfigurationAndControlClusterValveFaultEvent: NSObject {
    public var valveFault: NSNumber = 0
    public override init() { super.init() }
    public override var description: String {
        "MTRValveConfigurationAndControlClusterValveFaultEvent(valveFault: \(valveFault as Optional<Any>))"
    }
}
open class MTRValveConfigurationAndControlClusterValveStateChangedEvent: NSObject {
    public var valveLevel: NSNumber?
    public var valveState: NSNumber = 0
    public override init() { super.init() }
    public override var description: String {
        "MTRValveConfigurationAndControlClusterValveStateChangedEvent(valveLevel: \(valveLevel as Optional<Any>), valveState: \(valveState as Optional<Any>))"
    }
}
open class MTRWaterHeaterManagementClusterBoostParams: NSObject {
    public var boostInfo: MTRWaterHeaterManagementClusterWaterHeaterBoostInfoStruct = MTRWaterHeaterManagementClusterWaterHeaterBoostInfoStruct()
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRWaterHeaterManagementClusterBoostParams(boostInfo: \(boostInfo as Optional<Any>), serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}
open class MTRWaterHeaterManagementClusterBoostStartedEvent: NSObject {
    public var boostInfo: MTRWaterHeaterManagementClusterWaterHeaterBoostInfoStruct = MTRWaterHeaterManagementClusterWaterHeaterBoostInfoStruct()
    public override init() { super.init() }
    public override var description: String {
        "MTRWaterHeaterManagementClusterBoostStartedEvent(boostInfo: \(boostInfo as Optional<Any>))"
    }
}
open class MTRWaterHeaterManagementClusterCancelBoostParams: NSObject {
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRWaterHeaterManagementClusterCancelBoostParams(serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}
open class MTRWaterHeaterManagementClusterWaterHeaterBoostInfoStruct: NSObject {
    public var duration: NSNumber = 0
    public var emergencyBoost: NSNumber?
    public var oneShot: NSNumber?
    public var targetPercentage: NSNumber?
    public var targetReheat: NSNumber?
    public var temporarySetpoint: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRWaterHeaterManagementClusterWaterHeaterBoostInfoStruct(duration: \(duration as Optional<Any>), emergencyBoost: \(emergencyBoost as Optional<Any>), oneShot: \(oneShot as Optional<Any>), targetPercentage: \(targetPercentage as Optional<Any>), targetReheat: \(targetReheat as Optional<Any>), temporarySetpoint: \(temporarySetpoint as Optional<Any>))"
    }
}
open class MTRWaterHeaterModeClusterChangeToModeParams: NSObject {
    public var newMode: NSNumber = 0
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRWaterHeaterModeClusterChangeToModeParams(newMode: \(newMode as Optional<Any>), serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}
open class MTRWaterHeaterModeClusterChangeToModeResponseParams: NSObject {
    public init(responseValue: [String : Any]) throws {
        if let err = responseValue[MTRErrorKey] as? (any Error) {
            throw err
        }
        super.init()
        _ = responseValue[MTRDataKey] as? [String: Any]
    }
    public var status: NSNumber = 0
    public var statusText: String?
    public override init() { super.init() }
    public override var description: String {
        "MTRWaterHeaterModeClusterChangeToModeResponseParams(status: \(status as Optional<Any>), statusText: \(statusText as Optional<Any>))"
    }
}
open class MTRWaterHeaterModeClusterModeOptionStruct: NSObject {
    public var label: String = ""
    public var mode: NSNumber = 0
    public var modeTags: [Any] = []
    public override init() { super.init() }
    public override var description: String {
        "MTRWaterHeaterModeClusterModeOptionStruct(label: \(label as Optional<Any>), mode: \(mode as Optional<Any>), modeTags: \(modeTags as Optional<Any>))"
    }
}
open class MTRWaterHeaterModeClusterModeTagStruct: NSObject {
    public var mfgCode: NSNumber?
    public var value: NSNumber = 0
    public override init() { super.init() }
    public override var description: String {
        "MTRWaterHeaterModeClusterModeTagStruct(mfgCode: \(mfgCode as Optional<Any>), value: \(value as Optional<Any>))"
    }
}
open class MTRWiFiNetworkDiagnosticsClusterAssociationFailureEvent: NSObject {
    public var associationFailure: NSNumber = 0
    public var associationFailureCause: NSNumber = 0
    public var status: NSNumber = 0
    public override init() { super.init() }
    public override var description: String {
        "MTRWiFiNetworkDiagnosticsClusterAssociationFailureEvent(associationFailure: \(associationFailure as Optional<Any>), associationFailureCause: \(associationFailureCause as Optional<Any>), status: \(status as Optional<Any>))"
    }
}
open class MTRWiFiNetworkDiagnosticsClusterConnectionStatusEvent: NSObject {
    public var connectionStatus: NSNumber = 0
    public override init() { super.init() }
    public override var description: String {
        "MTRWiFiNetworkDiagnosticsClusterConnectionStatusEvent(connectionStatus: \(connectionStatus as Optional<Any>))"
    }
}
open class MTRWiFiNetworkDiagnosticsClusterDisconnectionEvent: NSObject {
    public var reasonCode: NSNumber = 0
    public override init() { super.init() }
    public override var description: String {
        "MTRWiFiNetworkDiagnosticsClusterDisconnectionEvent(reasonCode: \(reasonCode as Optional<Any>))"
    }
}
open class MTRWiFiNetworkDiagnosticsClusterResetCountsParams: NSObject {
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRWiFiNetworkDiagnosticsClusterResetCountsParams(serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}
open class MTRWiFiNetworkManagementClusterNetworkPassphraseRequestParams: NSObject {
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRWiFiNetworkManagementClusterNetworkPassphraseRequestParams(serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}
open class MTRWiFiNetworkManagementClusterNetworkPassphraseResponseParams: NSObject {
    public init(responseValue: [String : Any]) throws {
        if let err = responseValue[MTRErrorKey] as? (any Error) {
            throw err
        }
        super.init()
        _ = responseValue[MTRDataKey] as? [String: Any]
    }
    public var passphrase: Data = Data()
    public override init() { super.init() }
    public override var description: String {
        "MTRWiFiNetworkManagementClusterNetworkPassphraseResponseParams(passphrase: \(passphrase as Optional<Any>))"
    }
}
