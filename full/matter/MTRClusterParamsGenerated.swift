import Foundation

// Generated Matter cluster Params / Response / Event / Struct value types.

open class MTRColorControlClusterColorLoopSetParams: NSObject {
    public var action: NSNumber = 0
    public var direction: NSNumber = 0
    public var optionsMask: NSNumber = 0
    public var optionsOverride: NSNumber = 0
    public var serverSideProcessingTimeout: NSNumber?
    public var startHue: NSNumber = 0
    public var time: NSNumber = 0
    public var timedInvokeTimeoutMs: NSNumber?
    public var updateFlags: NSNumber = 0
    public override init() { super.init() }
    public override var description: String {
        "MTRColorControlClusterColorLoopSetParams(action: \(action as Optional<Any>), direction: \(direction as Optional<Any>), optionsMask: \(optionsMask as Optional<Any>), optionsOverride: \(optionsOverride as Optional<Any>), serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), startHue: \(startHue as Optional<Any>))"
    }
}

open class MTRColorControlClusterEnhancedMoveHueParams: NSObject {
    public var moveMode: NSNumber = 0
    public var optionsMask: NSNumber = 0
    public var optionsOverride: NSNumber = 0
    public var rate: NSNumber = 0
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRColorControlClusterEnhancedMoveHueParams(moveMode: \(moveMode as Optional<Any>), optionsMask: \(optionsMask as Optional<Any>), optionsOverride: \(optionsOverride as Optional<Any>), rate: \(rate as Optional<Any>), serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}

open class MTRColorControlClusterEnhancedMoveToHueAndSaturationParams: NSObject {
    public var enhancedHue: NSNumber = 0
    public var optionsMask: NSNumber = 0
    public var optionsOverride: NSNumber = 0
    public var saturation: NSNumber = 0
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public var transitionTime: NSNumber = 0
    public override init() { super.init() }
    public override var description: String {
        "MTRColorControlClusterEnhancedMoveToHueAndSaturationParams(enhancedHue: \(enhancedHue as Optional<Any>), optionsMask: \(optionsMask as Optional<Any>), optionsOverride: \(optionsOverride as Optional<Any>), saturation: \(saturation as Optional<Any>), serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}

open class MTRColorControlClusterEnhancedMoveToHueParams: NSObject {
    public var direction: NSNumber = 0
    public var enhancedHue: NSNumber = 0
    public var optionsMask: NSNumber = 0
    public var optionsOverride: NSNumber = 0
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public var transitionTime: NSNumber = 0
    public override init() { super.init() }
    public override var description: String {
        "MTRColorControlClusterEnhancedMoveToHueParams(direction: \(direction as Optional<Any>), enhancedHue: \(enhancedHue as Optional<Any>), optionsMask: \(optionsMask as Optional<Any>), optionsOverride: \(optionsOverride as Optional<Any>), serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}

open class MTRColorControlClusterEnhancedStepHueParams: NSObject {
    public var optionsMask: NSNumber = 0
    public var optionsOverride: NSNumber = 0
    public var serverSideProcessingTimeout: NSNumber?
    public var stepMode: NSNumber = 0
    public var stepSize: NSNumber = 0
    public var timedInvokeTimeoutMs: NSNumber?
    public var transitionTime: NSNumber = 0
    public override init() { super.init() }
    public override var description: String {
        "MTRColorControlClusterEnhancedStepHueParams(optionsMask: \(optionsMask as Optional<Any>), optionsOverride: \(optionsOverride as Optional<Any>), serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), stepMode: \(stepMode as Optional<Any>), stepSize: \(stepSize as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}

open class MTRColorControlClusterMoveColorParams: NSObject {
    public var optionsMask: NSNumber = 0
    public var optionsOverride: NSNumber = 0
    public var rateX: NSNumber = 0
    public var rateY: NSNumber = 0
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRColorControlClusterMoveColorParams(optionsMask: \(optionsMask as Optional<Any>), optionsOverride: \(optionsOverride as Optional<Any>), rateX: \(rateX as Optional<Any>), rateY: \(rateY as Optional<Any>), serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}

open class MTRColorControlClusterMoveColorTemperatureParams: NSObject {
    public var colorTemperatureMaximumMireds: NSNumber = 0
    public var colorTemperatureMinimumMireds: NSNumber = 0
    public var moveMode: NSNumber = 0
    public var optionsMask: NSNumber = 0
    public var optionsOverride: NSNumber = 0
    public var rate: NSNumber = 0
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRColorControlClusterMoveColorTemperatureParams(colorTemperatureMaximumMireds: \(colorTemperatureMaximumMireds as Optional<Any>), colorTemperatureMinimumMireds: \(colorTemperatureMinimumMireds as Optional<Any>), moveMode: \(moveMode as Optional<Any>), optionsMask: \(optionsMask as Optional<Any>), optionsOverride: \(optionsOverride as Optional<Any>), rate: \(rate as Optional<Any>))"
    }
}

open class MTRColorControlClusterMoveHueParams: NSObject {
    public var moveMode: NSNumber = 0
    public var optionsMask: NSNumber = 0
    public var optionsOverride: NSNumber = 0
    public var rate: NSNumber = 0
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRColorControlClusterMoveHueParams(moveMode: \(moveMode as Optional<Any>), optionsMask: \(optionsMask as Optional<Any>), optionsOverride: \(optionsOverride as Optional<Any>), rate: \(rate as Optional<Any>), serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}

open class MTRColorControlClusterMoveSaturationParams: NSObject {
    public var moveMode: NSNumber = 0
    public var optionsMask: NSNumber = 0
    public var optionsOverride: NSNumber = 0
    public var rate: NSNumber = 0
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRColorControlClusterMoveSaturationParams(moveMode: \(moveMode as Optional<Any>), optionsMask: \(optionsMask as Optional<Any>), optionsOverride: \(optionsOverride as Optional<Any>), rate: \(rate as Optional<Any>), serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}

open class MTRColorControlClusterMoveToColorParams: NSObject {
    public var colorX: NSNumber = 0
    public var colorY: NSNumber = 0
    public var optionsMask: NSNumber = 0
    public var optionsOverride: NSNumber = 0
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public var transitionTime: NSNumber = 0
    public override init() { super.init() }
    public override var description: String {
        "MTRColorControlClusterMoveToColorParams(colorX: \(colorX as Optional<Any>), colorY: \(colorY as Optional<Any>), optionsMask: \(optionsMask as Optional<Any>), optionsOverride: \(optionsOverride as Optional<Any>), serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}

open class MTRColorControlClusterMoveToColorTemperatureParams: NSObject {
    public var colorTemperature: NSNumber = 0
    public var colorTemperatureMireds: NSNumber = 0
    public var optionsMask: NSNumber = 0
    public var optionsOverride: NSNumber = 0
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public var transitionTime: NSNumber = 0
    public override init() { super.init() }
    public override var description: String {
        "MTRColorControlClusterMoveToColorTemperatureParams(colorTemperature: \(colorTemperature as Optional<Any>), colorTemperatureMireds: \(colorTemperatureMireds as Optional<Any>), optionsMask: \(optionsMask as Optional<Any>), optionsOverride: \(optionsOverride as Optional<Any>), serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}

open class MTRColorControlClusterMoveToHueAndSaturationParams: NSObject {
    public var hue: NSNumber = 0
    public var optionsMask: NSNumber = 0
    public var optionsOverride: NSNumber = 0
    public var saturation: NSNumber = 0
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public var transitionTime: NSNumber = 0
    public override init() { super.init() }
    public override var description: String {
        "MTRColorControlClusterMoveToHueAndSaturationParams(hue: \(hue as Optional<Any>), optionsMask: \(optionsMask as Optional<Any>), optionsOverride: \(optionsOverride as Optional<Any>), saturation: \(saturation as Optional<Any>), serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}

open class MTRColorControlClusterMoveToHueParams: NSObject {
    public var direction: NSNumber = 0
    public var hue: NSNumber = 0
    public var optionsMask: NSNumber = 0
    public var optionsOverride: NSNumber = 0
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public var transitionTime: NSNumber = 0
    public override init() { super.init() }
    public override var description: String {
        "MTRColorControlClusterMoveToHueParams(direction: \(direction as Optional<Any>), hue: \(hue as Optional<Any>), optionsMask: \(optionsMask as Optional<Any>), optionsOverride: \(optionsOverride as Optional<Any>), serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}

open class MTRColorControlClusterMoveToSaturationParams: NSObject {
    public var optionsMask: NSNumber = 0
    public var optionsOverride: NSNumber = 0
    public var saturation: NSNumber = 0
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public var transitionTime: NSNumber = 0
    public override init() { super.init() }
    public override var description: String {
        "MTRColorControlClusterMoveToSaturationParams(optionsMask: \(optionsMask as Optional<Any>), optionsOverride: \(optionsOverride as Optional<Any>), saturation: \(saturation as Optional<Any>), serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>), transitionTime: \(transitionTime as Optional<Any>))"
    }
}

open class MTRColorControlClusterStepColorParams: NSObject {
    public var optionsMask: NSNumber = 0
    public var optionsOverride: NSNumber = 0
    public var serverSideProcessingTimeout: NSNumber?
    public var stepX: NSNumber = 0
    public var stepY: NSNumber = 0
    public var timedInvokeTimeoutMs: NSNumber?
    public var transitionTime: NSNumber = 0
    public override init() { super.init() }
    public override var description: String {
        "MTRColorControlClusterStepColorParams(optionsMask: \(optionsMask as Optional<Any>), optionsOverride: \(optionsOverride as Optional<Any>), serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), stepX: \(stepX as Optional<Any>), stepY: \(stepY as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}

open class MTRColorControlClusterStepColorTemperatureParams: NSObject {
    public var colorTemperatureMaximumMireds: NSNumber = 0
    public var colorTemperatureMinimumMireds: NSNumber = 0
    public var optionsMask: NSNumber = 0
    public var optionsOverride: NSNumber = 0
    public var serverSideProcessingTimeout: NSNumber?
    public var stepMode: NSNumber = 0
    public var stepSize: NSNumber = 0
    public var timedInvokeTimeoutMs: NSNumber?
    public var transitionTime: NSNumber = 0
    public override init() { super.init() }
    public override var description: String {
        "MTRColorControlClusterStepColorTemperatureParams(colorTemperatureMaximumMireds: \(colorTemperatureMaximumMireds as Optional<Any>), colorTemperatureMinimumMireds: \(colorTemperatureMinimumMireds as Optional<Any>), optionsMask: \(optionsMask as Optional<Any>), optionsOverride: \(optionsOverride as Optional<Any>), serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), stepMode: \(stepMode as Optional<Any>))"
    }
}

open class MTRColorControlClusterStepHueParams: NSObject {
    public var optionsMask: NSNumber = 0
    public var optionsOverride: NSNumber = 0
    public var serverSideProcessingTimeout: NSNumber?
    public var stepMode: NSNumber = 0
    public var stepSize: NSNumber = 0
    public var timedInvokeTimeoutMs: NSNumber?
    public var transitionTime: NSNumber = 0
    public override init() { super.init() }
    public override var description: String {
        "MTRColorControlClusterStepHueParams(optionsMask: \(optionsMask as Optional<Any>), optionsOverride: \(optionsOverride as Optional<Any>), serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), stepMode: \(stepMode as Optional<Any>), stepSize: \(stepSize as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}

open class MTRColorControlClusterStepSaturationParams: NSObject {
    public var optionsMask: NSNumber = 0
    public var optionsOverride: NSNumber = 0
    public var serverSideProcessingTimeout: NSNumber?
    public var stepMode: NSNumber = 0
    public var stepSize: NSNumber = 0
    public var timedInvokeTimeoutMs: NSNumber?
    public var transitionTime: NSNumber = 0
    public override init() { super.init() }
    public override var description: String {
        "MTRColorControlClusterStepSaturationParams(optionsMask: \(optionsMask as Optional<Any>), optionsOverride: \(optionsOverride as Optional<Any>), serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), stepMode: \(stepMode as Optional<Any>), stepSize: \(stepSize as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}

open class MTRColorControlClusterStopMoveStepParams: NSObject {
    public var optionsMask: NSNumber = 0
    public var optionsOverride: NSNumber = 0
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRColorControlClusterStopMoveStepParams(optionsMask: \(optionsMask as Optional<Any>), optionsOverride: \(optionsOverride as Optional<Any>), serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}

open class MTRDoorLockClusterClearAliroReaderConfigParams: NSObject {
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRDoorLockClusterClearAliroReaderConfigParams(serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}

open class MTRDoorLockClusterClearCredentialParams: NSObject {
    public var credential: MTRDoorLockClusterCredentialStruct?
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRDoorLockClusterClearCredentialParams(credential: \(credential as Optional<Any>), serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}

open class MTRDoorLockClusterClearHolidayScheduleParams: NSObject {
    public var holidayIndex: NSNumber = 0
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRDoorLockClusterClearHolidayScheduleParams(holidayIndex: \(holidayIndex as Optional<Any>), serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}

open class MTRDoorLockClusterClearUserParams: NSObject {
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public var userIndex: NSNumber = 0
    public override init() { super.init() }
    public override var description: String {
        "MTRDoorLockClusterClearUserParams(serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>), userIndex: \(userIndex as Optional<Any>))"
    }
}

open class MTRDoorLockClusterClearWeekDayScheduleParams: NSObject {
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public var userIndex: NSNumber = 0
    public var weekDayIndex: NSNumber = 0
    public override init() { super.init() }
    public override var description: String {
        "MTRDoorLockClusterClearWeekDayScheduleParams(serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>), userIndex: \(userIndex as Optional<Any>), weekDayIndex: \(weekDayIndex as Optional<Any>))"
    }
}

open class MTRDoorLockClusterClearYearDayScheduleParams: NSObject {
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public var userIndex: NSNumber = 0
    public var yearDayIndex: NSNumber = 0
    public override init() { super.init() }
    public override var description: String {
        "MTRDoorLockClusterClearYearDayScheduleParams(serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>), userIndex: \(userIndex as Optional<Any>), yearDayIndex: \(yearDayIndex as Optional<Any>))"
    }
}

open class MTRDoorLockClusterCredentialStruct: NSObject {
    public var credentialIndex: NSNumber = 0
    public var credentialType: NSNumber = 0
    public override init() { super.init() }
    public override var description: String {
        "MTRDoorLockClusterCredentialStruct(credentialIndex: \(credentialIndex as Optional<Any>), credentialType: \(credentialType as Optional<Any>))"
    }
}

open class MTRDoorLockClusterDlCredential: MTRDoorLockClusterCredentialStruct {
    public override init() { super.init() }
    public override var description: String {
        "MTRDoorLockClusterDlCredential(MTRDoorLockClusterDlCredential)"
    }
}

open class MTRDoorLockClusterDoorLockAlarmEvent: NSObject {
    public var alarmCode: NSNumber = 0
    public override init() { super.init() }
    public override var description: String {
        "MTRDoorLockClusterDoorLockAlarmEvent(alarmCode: \(alarmCode as Optional<Any>))"
    }
}

open class MTRDoorLockClusterDoorStateChangeEvent: NSObject {
    public var doorState: NSNumber = 0
    public override init() { super.init() }
    public override var description: String {
        "MTRDoorLockClusterDoorStateChangeEvent(doorState: \(doorState as Optional<Any>))"
    }
}

open class MTRDoorLockClusterGetCredentialStatusParams: NSObject {
    public var credential: MTRDoorLockClusterCredentialStruct = MTRDoorLockClusterCredentialStruct()
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRDoorLockClusterGetCredentialStatusParams(credential: \(credential as Optional<Any>), serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}

open class MTRDoorLockClusterGetCredentialStatusResponseParams: NSObject {
    public init(responseValue: [String : Any]) throws {
        if let err = responseValue[MTRErrorKey] as? (any Error) {
            throw err
        }
        super.init()
        _ = responseValue[MTRDataKey] as? [String: Any]
    }
    public var creatorFabricIndex: NSNumber?
    public var credentialData: Data?
    public var credentialExists: NSNumber = 0
    public var lastModifiedFabricIndex: NSNumber?
    public var nextCredentialIndex: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public var userIndex: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRDoorLockClusterGetCredentialStatusResponseParams(creatorFabricIndex: \(creatorFabricIndex as Optional<Any>), credentialData: \(credentialData as Optional<Any>), credentialExists: \(credentialExists as Optional<Any>), lastModifiedFabricIndex: \(lastModifiedFabricIndex as Optional<Any>), nextCredentialIndex: \(nextCredentialIndex as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}

open class MTRDoorLockClusterGetHolidayScheduleParams: NSObject {
    public var holidayIndex: NSNumber = 0
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRDoorLockClusterGetHolidayScheduleParams(holidayIndex: \(holidayIndex as Optional<Any>), serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}

open class MTRDoorLockClusterGetHolidayScheduleResponseParams: NSObject {
    public init(responseValue: [String : Any]) throws {
        if let err = responseValue[MTRErrorKey] as? (any Error) {
            throw err
        }
        super.init()
        _ = responseValue[MTRDataKey] as? [String: Any]
    }
    public var holidayIndex: NSNumber = 0
    public var localEndTime: NSNumber?
    public var localStartTime: NSNumber?
    public var operatingMode: NSNumber?
    public var status: NSNumber = 0
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRDoorLockClusterGetHolidayScheduleResponseParams(holidayIndex: \(holidayIndex as Optional<Any>), localEndTime: \(localEndTime as Optional<Any>), localStartTime: \(localStartTime as Optional<Any>), operatingMode: \(operatingMode as Optional<Any>), status: \(status as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}

open class MTRDoorLockClusterGetUserParams: NSObject {
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public var userIndex: NSNumber = 0
    public override init() { super.init() }
    public override var description: String {
        "MTRDoorLockClusterGetUserParams(serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>), userIndex: \(userIndex as Optional<Any>))"
    }
}

open class MTRDoorLockClusterGetUserResponseParams: NSObject {
    public init(responseValue: [String : Any]) throws {
        if let err = responseValue[MTRErrorKey] as? (any Error) {
            throw err
        }
        super.init()
        _ = responseValue[MTRDataKey] as? [String: Any]
    }
    public var creatorFabricIndex: NSNumber?
    public var credentialRule: NSNumber?
    public var credentials: [Any]?
    public var lastModifiedFabricIndex: NSNumber?
    public var nextUserIndex: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public var userIndex: NSNumber = 0
    public var userName: String?
    public var userStatus: NSNumber?
    public var userType: NSNumber?
    public var userUniqueID: NSNumber?
    public var userUniqueId: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRDoorLockClusterGetUserResponseParams(creatorFabricIndex: \(creatorFabricIndex as Optional<Any>), credentialRule: \(credentialRule as Optional<Any>), credentials: \(credentials as Optional<Any>), lastModifiedFabricIndex: \(lastModifiedFabricIndex as Optional<Any>), nextUserIndex: \(nextUserIndex as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}

open class MTRDoorLockClusterGetWeekDayScheduleParams: NSObject {
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public var userIndex: NSNumber = 0
    public var weekDayIndex: NSNumber = 0
    public override init() { super.init() }
    public override var description: String {
        "MTRDoorLockClusterGetWeekDayScheduleParams(serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>), userIndex: \(userIndex as Optional<Any>), weekDayIndex: \(weekDayIndex as Optional<Any>))"
    }
}

open class MTRDoorLockClusterGetWeekDayScheduleResponseParams: NSObject {
    public init(responseValue: [String : Any]) throws {
        if let err = responseValue[MTRErrorKey] as? (any Error) {
            throw err
        }
        super.init()
        _ = responseValue[MTRDataKey] as? [String: Any]
    }
    public var daysMask: NSNumber?
    public var endHour: NSNumber?
    public var endMinute: NSNumber?
    public var startHour: NSNumber?
    public var startMinute: NSNumber?
    public var status: NSNumber = 0
    public var timedInvokeTimeoutMs: NSNumber?
    public var userIndex: NSNumber = 0
    public var weekDayIndex: NSNumber = 0
    public override init() { super.init() }
    public override var description: String {
        "MTRDoorLockClusterGetWeekDayScheduleResponseParams(daysMask: \(daysMask as Optional<Any>), endHour: \(endHour as Optional<Any>), endMinute: \(endMinute as Optional<Any>), startHour: \(startHour as Optional<Any>), startMinute: \(startMinute as Optional<Any>), status: \(status as Optional<Any>))"
    }
}

open class MTRDoorLockClusterGetYearDayScheduleParams: NSObject {
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public var userIndex: NSNumber = 0
    public var yearDayIndex: NSNumber = 0
    public override init() { super.init() }
    public override var description: String {
        "MTRDoorLockClusterGetYearDayScheduleParams(serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>), userIndex: \(userIndex as Optional<Any>), yearDayIndex: \(yearDayIndex as Optional<Any>))"
    }
}

open class MTRDoorLockClusterGetYearDayScheduleResponseParams: NSObject {
    public init(responseValue: [String : Any]) throws {
        if let err = responseValue[MTRErrorKey] as? (any Error) {
            throw err
        }
        super.init()
        _ = responseValue[MTRDataKey] as? [String: Any]
    }
    public var localEndTime: NSNumber?
    public var localStartTime: NSNumber?
    public var status: NSNumber = 0
    public var timedInvokeTimeoutMs: NSNumber?
    public var userIndex: NSNumber = 0
    public var yearDayIndex: NSNumber = 0
    public override init() { super.init() }
    public override var description: String {
        "MTRDoorLockClusterGetYearDayScheduleResponseParams(localEndTime: \(localEndTime as Optional<Any>), localStartTime: \(localStartTime as Optional<Any>), status: \(status as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>), userIndex: \(userIndex as Optional<Any>), yearDayIndex: \(yearDayIndex as Optional<Any>))"
    }
}

open class MTRDoorLockClusterLockDoorParams: NSObject {
    public var pinCode: Data?
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRDoorLockClusterLockDoorParams(pinCode: \(pinCode as Optional<Any>), serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}

open class MTRDoorLockClusterLockOperationErrorEvent: NSObject {
    public var credentials: [Any]?
    public var fabricIndex: NSNumber?
    public var lockOperationType: NSNumber = 0
    public var operationError: NSNumber = 0
    public var operationSource: NSNumber = 0
    public var sourceNode: NSNumber?
    public var userIndex: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRDoorLockClusterLockOperationErrorEvent(credentials: \(credentials as Optional<Any>), fabricIndex: \(fabricIndex as Optional<Any>), lockOperationType: \(lockOperationType as Optional<Any>), operationError: \(operationError as Optional<Any>), operationSource: \(operationSource as Optional<Any>), sourceNode: \(sourceNode as Optional<Any>))"
    }
}

open class MTRDoorLockClusterLockOperationEvent: NSObject {
    public var credentials: [Any]?
    public var fabricIndex: NSNumber?
    public var lockOperationType: NSNumber = 0
    public var operationSource: NSNumber = 0
    public var sourceNode: NSNumber?
    public var userIndex: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRDoorLockClusterLockOperationEvent(credentials: \(credentials as Optional<Any>), fabricIndex: \(fabricIndex as Optional<Any>), lockOperationType: \(lockOperationType as Optional<Any>), operationSource: \(operationSource as Optional<Any>), sourceNode: \(sourceNode as Optional<Any>), userIndex: \(userIndex as Optional<Any>))"
    }
}

open class MTRDoorLockClusterLockUserChangeEvent: NSObject {
    public var dataIndex: NSNumber?
    public var dataOperationType: NSNumber = 0
    public var fabricIndex: NSNumber?
    public var lockDataType: NSNumber = 0
    public var operationSource: NSNumber = 0
    public var sourceNode: NSNumber?
    public var userIndex: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRDoorLockClusterLockUserChangeEvent(dataIndex: \(dataIndex as Optional<Any>), dataOperationType: \(dataOperationType as Optional<Any>), fabricIndex: \(fabricIndex as Optional<Any>), lockDataType: \(lockDataType as Optional<Any>), operationSource: \(operationSource as Optional<Any>), sourceNode: \(sourceNode as Optional<Any>))"
    }
}

open class MTRDoorLockClusterSetAliroReaderConfigParams: NSObject {
    public var groupIdentifier: Data = Data()
    public var groupResolvingKey: Data?
    public var serverSideProcessingTimeout: NSNumber?
    public var signingKey: Data = Data()
    public var timedInvokeTimeoutMs: NSNumber?
    public var verificationKey: Data = Data()
    public override init() { super.init() }
    public override var description: String {
        "MTRDoorLockClusterSetAliroReaderConfigParams(groupIdentifier: \(groupIdentifier as Optional<Any>), groupResolvingKey: \(groupResolvingKey as Optional<Any>), serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), signingKey: \(signingKey as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>), verificationKey: \(verificationKey as Optional<Any>))"
    }
}

open class MTRDoorLockClusterSetCredentialParams: NSObject {
    public var credential: MTRDoorLockClusterCredentialStruct = MTRDoorLockClusterCredentialStruct()
    public var credentialData: Data = Data()
    public var operationType: NSNumber = 0
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public var userIndex: NSNumber?
    public var userStatus: NSNumber?
    public var userType: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRDoorLockClusterSetCredentialParams(credential: \(credential as Optional<Any>), credentialData: \(credentialData as Optional<Any>), operationType: \(operationType as Optional<Any>), serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>), userIndex: \(userIndex as Optional<Any>))"
    }
}

open class MTRDoorLockClusterSetCredentialResponseParams: NSObject {
    public init(responseValue: [String : Any]) throws {
        if let err = responseValue[MTRErrorKey] as? (any Error) {
            throw err
        }
        super.init()
        _ = responseValue[MTRDataKey] as? [String: Any]
    }
    public var nextCredentialIndex: NSNumber?
    public var status: NSNumber = 0
    public var timedInvokeTimeoutMs: NSNumber?
    public var userIndex: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRDoorLockClusterSetCredentialResponseParams(nextCredentialIndex: \(nextCredentialIndex as Optional<Any>), status: \(status as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>), userIndex: \(userIndex as Optional<Any>))"
    }
}

open class MTRDoorLockClusterSetHolidayScheduleParams: NSObject {
    public var holidayIndex: NSNumber = 0
    public var localEndTime: NSNumber = 0
    public var localStartTime: NSNumber = 0
    public var operatingMode: NSNumber = 0
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRDoorLockClusterSetHolidayScheduleParams(holidayIndex: \(holidayIndex as Optional<Any>), localEndTime: \(localEndTime as Optional<Any>), localStartTime: \(localStartTime as Optional<Any>), operatingMode: \(operatingMode as Optional<Any>), serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}

open class MTRDoorLockClusterSetUserParams: NSObject {
    public var credentialRule: NSNumber?
    public var operationType: NSNumber = 0
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public var userIndex: NSNumber = 0
    public var userName: String?
    public var userStatus: NSNumber?
    public var userType: NSNumber?
    public var userUniqueID: NSNumber?
    public var userUniqueId: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRDoorLockClusterSetUserParams(credentialRule: \(credentialRule as Optional<Any>), operationType: \(operationType as Optional<Any>), serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>), userIndex: \(userIndex as Optional<Any>), userName: \(userName as Optional<Any>))"
    }
}

open class MTRDoorLockClusterSetWeekDayScheduleParams: NSObject {
    public var daysMask: NSNumber = 0
    public var endHour: NSNumber = 0
    public var endMinute: NSNumber = 0
    public var serverSideProcessingTimeout: NSNumber?
    public var startHour: NSNumber = 0
    public var startMinute: NSNumber = 0
    public var timedInvokeTimeoutMs: NSNumber?
    public var userIndex: NSNumber = 0
    public var weekDayIndex: NSNumber = 0
    public override init() { super.init() }
    public override var description: String {
        "MTRDoorLockClusterSetWeekDayScheduleParams(daysMask: \(daysMask as Optional<Any>), endHour: \(endHour as Optional<Any>), endMinute: \(endMinute as Optional<Any>), serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), startHour: \(startHour as Optional<Any>), startMinute: \(startMinute as Optional<Any>))"
    }
}

open class MTRDoorLockClusterSetYearDayScheduleParams: NSObject {
    public var localEndTime: NSNumber = 0
    public var localStartTime: NSNumber = 0
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public var userIndex: NSNumber = 0
    public var yearDayIndex: NSNumber = 0
    public override init() { super.init() }
    public override var description: String {
        "MTRDoorLockClusterSetYearDayScheduleParams(localEndTime: \(localEndTime as Optional<Any>), localStartTime: \(localStartTime as Optional<Any>), serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>), userIndex: \(userIndex as Optional<Any>), yearDayIndex: \(yearDayIndex as Optional<Any>))"
    }
}

open class MTRDoorLockClusterUnboltDoorParams: NSObject {
    public var pinCode: Data?
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRDoorLockClusterUnboltDoorParams(pinCode: \(pinCode as Optional<Any>), serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}

open class MTRDoorLockClusterUnlockDoorParams: NSObject {
    public var pinCode: Data?
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRDoorLockClusterUnlockDoorParams(pinCode: \(pinCode as Optional<Any>), serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}

open class MTRDoorLockClusterUnlockWithTimeoutParams: NSObject {
    public var pinCode: Data?
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public var timeout: NSNumber = 0
    public override init() { super.init() }
    public override var description: String {
        "MTRDoorLockClusterUnlockWithTimeoutParams(pinCode: \(pinCode as Optional<Any>), serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>), timeout: \(timeout as Optional<Any>))"
    }
}

open class MTRElectricalMeasurementClusterGetMeasurementProfileCommandParams: NSObject {
    public var attributeId: NSNumber = 0
    public var numberOfIntervals: NSNumber = 0
    public var serverSideProcessingTimeout: NSNumber?
    public var startTime: NSNumber = 0
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRElectricalMeasurementClusterGetMeasurementProfileCommandParams(attributeId: \(attributeId as Optional<Any>), numberOfIntervals: \(numberOfIntervals as Optional<Any>), serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), startTime: \(startTime as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}

open class MTRElectricalMeasurementClusterGetMeasurementProfileResponseCommandParams: NSObject {
    public init(responseValue: [String : Any]) throws {
        if let err = responseValue[MTRErrorKey] as? (any Error) {
            throw err
        }
        super.init()
        _ = responseValue[MTRDataKey] as? [String: Any]
    }
    public var attributeId: NSNumber = 0
    public var intervals: [Any] = []
    public var numberOfIntervalsDelivered: NSNumber = 0
    public var profileIntervalPeriod: NSNumber = 0
    public var startTime: NSNumber = 0
    public var status: NSNumber = 0
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRElectricalMeasurementClusterGetMeasurementProfileResponseCommandParams(attributeId: \(attributeId as Optional<Any>), intervals: \(intervals as Optional<Any>), numberOfIntervalsDelivered: \(numberOfIntervalsDelivered as Optional<Any>), profileIntervalPeriod: \(profileIntervalPeriod as Optional<Any>), startTime: \(startTime as Optional<Any>), status: \(status as Optional<Any>))"
    }
}

open class MTRElectricalMeasurementClusterGetProfileInfoCommandParams: NSObject {
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRElectricalMeasurementClusterGetProfileInfoCommandParams(serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}

open class MTRElectricalMeasurementClusterGetProfileInfoResponseCommandParams: NSObject {
    public init(responseValue: [String : Any]) throws {
        if let err = responseValue[MTRErrorKey] as? (any Error) {
            throw err
        }
        super.init()
        _ = responseValue[MTRDataKey] as? [String: Any]
    }
    public var listOfAttributes: [Any] = []
    public var maxNumberOfIntervals: NSNumber = 0
    public var profileCount: NSNumber = 0
    public var profileIntervalPeriod: NSNumber = 0
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRElectricalMeasurementClusterGetProfileInfoResponseCommandParams(listOfAttributes: \(listOfAttributes as Optional<Any>), maxNumberOfIntervals: \(maxNumberOfIntervals as Optional<Any>), profileCount: \(profileCount as Optional<Any>), profileIntervalPeriod: \(profileIntervalPeriod as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}

open class MTRLevelControlClusterMoveParams: NSObject {
    public var moveMode: NSNumber = 0
    public var optionsMask: NSNumber = 0
    public var optionsOverride: NSNumber = 0
    public var rate: NSNumber?
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRLevelControlClusterMoveParams(moveMode: \(moveMode as Optional<Any>), optionsMask: \(optionsMask as Optional<Any>), optionsOverride: \(optionsOverride as Optional<Any>), rate: \(rate as Optional<Any>), serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}

open class MTRLevelControlClusterMoveToClosestFrequencyParams: NSObject {
    public var frequency: NSNumber = 0
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRLevelControlClusterMoveToClosestFrequencyParams(frequency: \(frequency as Optional<Any>), serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}

open class MTRLevelControlClusterMoveToLevelParams: NSObject {
    public var level: NSNumber = 0
    public var optionsMask: NSNumber = 0
    public var optionsOverride: NSNumber = 0
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public var transitionTime: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRLevelControlClusterMoveToLevelParams(level: \(level as Optional<Any>), optionsMask: \(optionsMask as Optional<Any>), optionsOverride: \(optionsOverride as Optional<Any>), serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>), transitionTime: \(transitionTime as Optional<Any>))"
    }
}

open class MTRLevelControlClusterMoveToLevelWithOnOffParams: NSObject {
    public var level: NSNumber = 0
    public var optionsMask: NSNumber = 0
    public var optionsOverride: NSNumber = 0
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public var transitionTime: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRLevelControlClusterMoveToLevelWithOnOffParams(level: \(level as Optional<Any>), optionsMask: \(optionsMask as Optional<Any>), optionsOverride: \(optionsOverride as Optional<Any>), serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>), transitionTime: \(transitionTime as Optional<Any>))"
    }
}

open class MTRLevelControlClusterMoveWithOnOffParams: NSObject {
    public var moveMode: NSNumber = 0
    public var optionsMask: NSNumber = 0
    public var optionsOverride: NSNumber = 0
    public var rate: NSNumber?
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRLevelControlClusterMoveWithOnOffParams(moveMode: \(moveMode as Optional<Any>), optionsMask: \(optionsMask as Optional<Any>), optionsOverride: \(optionsOverride as Optional<Any>), rate: \(rate as Optional<Any>), serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}

open class MTRLevelControlClusterStepParams: NSObject {
    public var optionsMask: NSNumber = 0
    public var optionsOverride: NSNumber = 0
    public var serverSideProcessingTimeout: NSNumber?
    public var stepMode: NSNumber = 0
    public var stepSize: NSNumber = 0
    public var timedInvokeTimeoutMs: NSNumber?
    public var transitionTime: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRLevelControlClusterStepParams(optionsMask: \(optionsMask as Optional<Any>), optionsOverride: \(optionsOverride as Optional<Any>), serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), stepMode: \(stepMode as Optional<Any>), stepSize: \(stepSize as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}

open class MTRLevelControlClusterStepWithOnOffParams: NSObject {
    public var optionsMask: NSNumber = 0
    public var optionsOverride: NSNumber = 0
    public var serverSideProcessingTimeout: NSNumber?
    public var stepMode: NSNumber = 0
    public var stepSize: NSNumber = 0
    public var timedInvokeTimeoutMs: NSNumber?
    public var transitionTime: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRLevelControlClusterStepWithOnOffParams(optionsMask: \(optionsMask as Optional<Any>), optionsOverride: \(optionsOverride as Optional<Any>), serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), stepMode: \(stepMode as Optional<Any>), stepSize: \(stepSize as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}

open class MTRLevelControlClusterStopParams: NSObject {
    public var optionsMask: NSNumber = 0
    public var optionsOverride: NSNumber = 0
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRLevelControlClusterStopParams(optionsMask: \(optionsMask as Optional<Any>), optionsOverride: \(optionsOverride as Optional<Any>), serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}

open class MTRLevelControlClusterStopWithOnOffParams: NSObject {
    public var optionsMask: NSNumber = 0
    public var optionsOverride: NSNumber = 0
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRLevelControlClusterStopWithOnOffParams(optionsMask: \(optionsMask as Optional<Any>), optionsOverride: \(optionsOverride as Optional<Any>), serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}

open class MTRPowerSourceClusterBatChargeFaultChangeEvent: NSObject {
    public var current: [Any] = []
    public var previous: [Any] = []
    public override init() { super.init() }
    public override var description: String {
        "MTRPowerSourceClusterBatChargeFaultChangeEvent(current: \(current as Optional<Any>), previous: \(previous as Optional<Any>))"
    }
}

open class MTRPowerSourceClusterBatChargeFaultChangeType: NSObject {
    public var current: [Any] = []
    public var previous: [Any] = []
    public override init() { super.init() }
    public override var description: String {
        "MTRPowerSourceClusterBatChargeFaultChangeType(current: \(current as Optional<Any>), previous: \(previous as Optional<Any>))"
    }
}

open class MTRPowerSourceClusterBatFaultChangeEvent: NSObject {
    public var current: [Any] = []
    public var previous: [Any] = []
    public override init() { super.init() }
    public override var description: String {
        "MTRPowerSourceClusterBatFaultChangeEvent(current: \(current as Optional<Any>), previous: \(previous as Optional<Any>))"
    }
}

open class MTRPowerSourceClusterBatFaultChangeType: NSObject {
    public var current: [Any] = []
    public var previous: [Any] = []
    public override init() { super.init() }
    public override var description: String {
        "MTRPowerSourceClusterBatFaultChangeType(current: \(current as Optional<Any>), previous: \(previous as Optional<Any>))"
    }
}

open class MTRPowerSourceClusterWiredFaultChangeEvent: NSObject {
    public var current: [Any] = []
    public var previous: [Any] = []
    public override init() { super.init() }
    public override var description: String {
        "MTRPowerSourceClusterWiredFaultChangeEvent(current: \(current as Optional<Any>), previous: \(previous as Optional<Any>))"
    }
}

open class MTRPowerSourceClusterWiredFaultChangeType: NSObject {
    public var current: [Any] = []
    public var previous: [Any] = []
    public override init() { super.init() }
    public override var description: String {
        "MTRPowerSourceClusterWiredFaultChangeType(current: \(current as Optional<Any>), previous: \(previous as Optional<Any>))"
    }
}

open class MTRPumpConfigurationAndControlClusterAirDetectionEvent: NSObject {
    public override init() { super.init() }
    public override var description: String {
        "MTRPumpConfigurationAndControlClusterAirDetectionEvent(MTRPumpConfigurationAndControlClusterAirDetectionEvent)"
    }
}

open class MTRPumpConfigurationAndControlClusterDryRunningEvent: NSObject {
    public override init() { super.init() }
    public override var description: String {
        "MTRPumpConfigurationAndControlClusterDryRunningEvent(MTRPumpConfigurationAndControlClusterDryRunningEvent)"
    }
}

open class MTRPumpConfigurationAndControlClusterElectronicFatalFailureEvent: NSObject {
    public override init() { super.init() }
    public override var description: String {
        "MTRPumpConfigurationAndControlClusterElectronicFatalFailureEvent(MTRPumpConfigurationAndControlClusterElectronicFatalFailureEvent)"
    }
}

open class MTRPumpConfigurationAndControlClusterElectronicNonFatalFailureEvent: NSObject {
    public override init() { super.init() }
    public override var description: String {
        "MTRPumpConfigurationAndControlClusterElectronicNonFatalFailureEvent(MTRPumpConfigurationAndControlClusterElectronicNonFatalFailureEvent)"
    }
}

open class MTRPumpConfigurationAndControlClusterElectronicTemperatureHighEvent: NSObject {
    public override init() { super.init() }
    public override var description: String {
        "MTRPumpConfigurationAndControlClusterElectronicTemperatureHighEvent(MTRPumpConfigurationAndControlClusterElectronicTemperatureHighEvent)"
    }
}

open class MTRPumpConfigurationAndControlClusterGeneralFaultEvent: NSObject {
    public override init() { super.init() }
    public override var description: String {
        "MTRPumpConfigurationAndControlClusterGeneralFaultEvent(MTRPumpConfigurationAndControlClusterGeneralFaultEvent)"
    }
}

open class MTRPumpConfigurationAndControlClusterLeakageEvent: NSObject {
    public override init() { super.init() }
    public override var description: String {
        "MTRPumpConfigurationAndControlClusterLeakageEvent(MTRPumpConfigurationAndControlClusterLeakageEvent)"
    }
}

open class MTRPumpConfigurationAndControlClusterMotorTemperatureHighEvent: NSObject {
    public override init() { super.init() }
    public override var description: String {
        "MTRPumpConfigurationAndControlClusterMotorTemperatureHighEvent(MTRPumpConfigurationAndControlClusterMotorTemperatureHighEvent)"
    }
}

open class MTRPumpConfigurationAndControlClusterPowerMissingPhaseEvent: NSObject {
    public override init() { super.init() }
    public override var description: String {
        "MTRPumpConfigurationAndControlClusterPowerMissingPhaseEvent(MTRPumpConfigurationAndControlClusterPowerMissingPhaseEvent)"
    }
}

open class MTRPumpConfigurationAndControlClusterPumpBlockedEvent: NSObject {
    public override init() { super.init() }
    public override var description: String {
        "MTRPumpConfigurationAndControlClusterPumpBlockedEvent(MTRPumpConfigurationAndControlClusterPumpBlockedEvent)"
    }
}

open class MTRPumpConfigurationAndControlClusterPumpMotorFatalFailureEvent: NSObject {
    public override init() { super.init() }
    public override var description: String {
        "MTRPumpConfigurationAndControlClusterPumpMotorFatalFailureEvent(MTRPumpConfigurationAndControlClusterPumpMotorFatalFailureEvent)"
    }
}

open class MTRPumpConfigurationAndControlClusterSensorFailureEvent: NSObject {
    public override init() { super.init() }
    public override var description: String {
        "MTRPumpConfigurationAndControlClusterSensorFailureEvent(MTRPumpConfigurationAndControlClusterSensorFailureEvent)"
    }
}

open class MTRPumpConfigurationAndControlClusterSupplyVoltageHighEvent: NSObject {
    public override init() { super.init() }
    public override var description: String {
        "MTRPumpConfigurationAndControlClusterSupplyVoltageHighEvent(MTRPumpConfigurationAndControlClusterSupplyVoltageHighEvent)"
    }
}

open class MTRPumpConfigurationAndControlClusterSupplyVoltageLowEvent: NSObject {
    public override init() { super.init() }
    public override var description: String {
        "MTRPumpConfigurationAndControlClusterSupplyVoltageLowEvent(MTRPumpConfigurationAndControlClusterSupplyVoltageLowEvent)"
    }
}

open class MTRPumpConfigurationAndControlClusterSystemPressureHighEvent: NSObject {
    public override init() { super.init() }
    public override var description: String {
        "MTRPumpConfigurationAndControlClusterSystemPressureHighEvent(MTRPumpConfigurationAndControlClusterSystemPressureHighEvent)"
    }
}

open class MTRPumpConfigurationAndControlClusterSystemPressureLowEvent: NSObject {
    public override init() { super.init() }
    public override var description: String {
        "MTRPumpConfigurationAndControlClusterSystemPressureLowEvent(MTRPumpConfigurationAndControlClusterSystemPressureLowEvent)"
    }
}

open class MTRPumpConfigurationAndControlClusterTurbineOperationEvent: NSObject {
    public override init() { super.init() }
    public override var description: String {
        "MTRPumpConfigurationAndControlClusterTurbineOperationEvent(MTRPumpConfigurationAndControlClusterTurbineOperationEvent)"
    }
}

open class MTRThermostatClusterAtomicRequestParams: NSObject {
    public var attributeRequests: [Any] = []
    public var requestType: NSNumber = 0
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public var timeout: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRThermostatClusterAtomicRequestParams(attributeRequests: \(attributeRequests as Optional<Any>), requestType: \(requestType as Optional<Any>), serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>), timeout: \(timeout as Optional<Any>))"
    }
}

open class MTRThermostatClusterAtomicResponseParams: NSObject {
    public init(responseValue: [String : Any]) throws {
        if let err = responseValue[MTRErrorKey] as? (any Error) {
            throw err
        }
        super.init()
        _ = responseValue[MTRDataKey] as? [String: Any]
    }
    public var attributeStatus: [Any] = []
    public var statusCode: NSNumber = 0
    public var timeout: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRThermostatClusterAtomicResponseParams(attributeStatus: \(attributeStatus as Optional<Any>), statusCode: \(statusCode as Optional<Any>), timeout: \(timeout as Optional<Any>))"
    }
}

open class MTRThermostatClusterClearWeeklyScheduleParams: NSObject {
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRThermostatClusterClearWeeklyScheduleParams(serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}

open class MTRThermostatClusterGetWeeklyScheduleParams: NSObject {
    public var daysToReturn: NSNumber = 0
    public var modeToReturn: NSNumber = 0
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRThermostatClusterGetWeeklyScheduleParams(daysToReturn: \(daysToReturn as Optional<Any>), modeToReturn: \(modeToReturn as Optional<Any>), serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}

open class MTRThermostatClusterGetWeeklyScheduleResponseParams: NSObject {
    public init(responseValue: [String : Any]) throws {
        if let err = responseValue[MTRErrorKey] as? (any Error) {
            throw err
        }
        super.init()
        _ = responseValue[MTRDataKey] as? [String: Any]
    }
    public var dayOfWeekForSequence: NSNumber = 0
    public var modeForSequence: NSNumber = 0
    public var numberOfTransitionsForSequence: NSNumber = 0
    public var timedInvokeTimeoutMs: NSNumber?
    public var transitions: [Any] = []
    public override init() { super.init() }
    public override var description: String {
        "MTRThermostatClusterGetWeeklyScheduleResponseParams(dayOfWeekForSequence: \(dayOfWeekForSequence as Optional<Any>), modeForSequence: \(modeForSequence as Optional<Any>), numberOfTransitionsForSequence: \(numberOfTransitionsForSequence as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>), transitions: \(transitions as Optional<Any>))"
    }
}

open class MTRThermostatClusterPresetStruct: NSObject {
    public var builtIn: NSNumber?
    public var coolingSetpoint: NSNumber?
    public var heatingSetpoint: NSNumber?
    public var name: String?
    public var presetHandle: Data?
    public var presetScenario: NSNumber = 0
    public override init() { super.init() }
    public override var description: String {
        "MTRThermostatClusterPresetStruct(builtIn: \(builtIn as Optional<Any>), coolingSetpoint: \(coolingSetpoint as Optional<Any>), heatingSetpoint: \(heatingSetpoint as Optional<Any>), name: \(name as Optional<Any>), presetHandle: \(presetHandle as Optional<Any>), presetScenario: \(presetScenario as Optional<Any>))"
    }
}

open class MTRThermostatClusterPresetTypeStruct: NSObject {
    public var numberOfPresets: NSNumber = 0
    public var presetScenario: NSNumber = 0
    public var presetTypeFeatures: NSNumber = 0
    public override init() { super.init() }
    public override var description: String {
        "MTRThermostatClusterPresetTypeStruct(numberOfPresets: \(numberOfPresets as Optional<Any>), presetScenario: \(presetScenario as Optional<Any>), presetTypeFeatures: \(presetTypeFeatures as Optional<Any>))"
    }
}

open class MTRThermostatClusterScheduleStruct: NSObject {
    public var builtIn: NSNumber?
    public var name: String?
    public var presetHandle: Data?
    public var scheduleHandle: Data?
    public var systemMode: NSNumber = 0
    public var transitions: [Any] = []
    public override init() { super.init() }
    public override var description: String {
        "MTRThermostatClusterScheduleStruct(builtIn: \(builtIn as Optional<Any>), name: \(name as Optional<Any>), presetHandle: \(presetHandle as Optional<Any>), scheduleHandle: \(scheduleHandle as Optional<Any>), systemMode: \(systemMode as Optional<Any>), transitions: \(transitions as Optional<Any>))"
    }
}

open class MTRThermostatClusterScheduleTransitionStruct: NSObject {
    public var coolingSetpoint: NSNumber?
    public var dayOfWeek: NSNumber = 0
    public var heatingSetpoint: NSNumber?
    public var presetHandle: Data?
    public var systemMode: NSNumber?
    public var transitionTime: NSNumber = 0
    public override init() { super.init() }
    public override var description: String {
        "MTRThermostatClusterScheduleTransitionStruct(coolingSetpoint: \(coolingSetpoint as Optional<Any>), dayOfWeek: \(dayOfWeek as Optional<Any>), heatingSetpoint: \(heatingSetpoint as Optional<Any>), presetHandle: \(presetHandle as Optional<Any>), systemMode: \(systemMode as Optional<Any>), transitionTime: \(transitionTime as Optional<Any>))"
    }
}

open class MTRThermostatClusterScheduleTypeStruct: NSObject {
    public var numberOfSchedules: NSNumber = 0
    public var scheduleTypeFeatures: NSNumber = 0
    public var systemMode: NSNumber = 0
    public override init() { super.init() }
    public override var description: String {
        "MTRThermostatClusterScheduleTypeStruct(numberOfSchedules: \(numberOfSchedules as Optional<Any>), scheduleTypeFeatures: \(scheduleTypeFeatures as Optional<Any>), systemMode: \(systemMode as Optional<Any>))"
    }
}

open class MTRThermostatClusterSetActivePresetRequestParams: NSObject {
    public var presetHandle: Data?
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRThermostatClusterSetActivePresetRequestParams(presetHandle: \(presetHandle as Optional<Any>), serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}

open class MTRThermostatClusterSetActiveScheduleRequestParams: NSObject {
    public var scheduleHandle: Data = Data()
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRThermostatClusterSetActiveScheduleRequestParams(scheduleHandle: \(scheduleHandle as Optional<Any>), serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}

open class MTRThermostatClusterSetWeeklyScheduleParams: NSObject {
    public var dayOfWeekForSequence: NSNumber = 0
    public var modeForSequence: NSNumber = 0
    public var numberOfTransitionsForSequence: NSNumber = 0
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public var transitions: [Any] = []
    public override init() { super.init() }
    public override var description: String {
        "MTRThermostatClusterSetWeeklyScheduleParams(dayOfWeekForSequence: \(dayOfWeekForSequence as Optional<Any>), modeForSequence: \(modeForSequence as Optional<Any>), numberOfTransitionsForSequence: \(numberOfTransitionsForSequence as Optional<Any>), serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>), transitions: \(transitions as Optional<Any>))"
    }
}

open class MTRThermostatClusterSetpointRaiseLowerParams: NSObject {
    public var amount: NSNumber = 0
    public var mode: NSNumber = 0
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRThermostatClusterSetpointRaiseLowerParams(amount: \(amount as Optional<Any>), mode: \(mode as Optional<Any>), serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}

open class MTRThermostatClusterWeeklyScheduleTransitionStruct: NSObject {
    public var coolSetpoint: NSNumber?
    public var heatSetpoint: NSNumber?
    public var transitionTime: NSNumber = 0
    public override init() { super.init() }
    public override var description: String {
        "MTRThermostatClusterWeeklyScheduleTransitionStruct(coolSetpoint: \(coolSetpoint as Optional<Any>), heatSetpoint: \(heatSetpoint as Optional<Any>), transitionTime: \(transitionTime as Optional<Any>))"
    }
}

open class MTRThermostatClusterThermostatScheduleTransition: MTRThermostatClusterWeeklyScheduleTransitionStruct {
    public override init() { super.init() }
    public override var description: String {
        "MTRThermostatClusterThermostatScheduleTransition(MTRThermostatClusterThermostatScheduleTransition)"
    }
}

open class MTRThreadNetworkDiagnosticsClusterConnectionStatusEvent: NSObject {
    public var connectionStatus: NSNumber = 0
    public override init() { super.init() }
    public override var description: String {
        "MTRThreadNetworkDiagnosticsClusterConnectionStatusEvent(connectionStatus: \(connectionStatus as Optional<Any>))"
    }
}

open class MTRThreadNetworkDiagnosticsClusterNeighborTableStruct: NSObject {
    public var age: NSNumber = 0
    public var averageRssi: NSNumber?
    public var extAddress: NSNumber = 0
    public var frameErrorRate: NSNumber = 0
    public var fullNetworkData: NSNumber = 0
    public var fullThreadDevice: NSNumber = 0
    public var isChild: NSNumber = 0
    public var lastRssi: NSNumber?
    public var linkFrameCounter: NSNumber = 0
    public var lqi: NSNumber = 0
    public var messageErrorRate: NSNumber = 0
    public var mleFrameCounter: NSNumber = 0
    public var rloc16: NSNumber = 0
    public var rxOnWhenIdle: NSNumber = 0
    public override init() { super.init() }
    public override var description: String {
        "MTRThreadNetworkDiagnosticsClusterNeighborTableStruct(age: \(age as Optional<Any>), averageRssi: \(averageRssi as Optional<Any>), extAddress: \(extAddress as Optional<Any>), frameErrorRate: \(frameErrorRate as Optional<Any>), fullNetworkData: \(fullNetworkData as Optional<Any>), fullThreadDevice: \(fullThreadDevice as Optional<Any>))"
    }
}

open class MTRThreadNetworkDiagnosticsClusterNeighborTable: MTRThreadNetworkDiagnosticsClusterNeighborTableStruct {
    public override init() { super.init() }
    public override var description: String {
        "MTRThreadNetworkDiagnosticsClusterNeighborTable(MTRThreadNetworkDiagnosticsClusterNeighborTable)"
    }
}

open class MTRThreadNetworkDiagnosticsClusterNetworkFaultChangeEvent: NSObject {
    public var current: [Any] = []
    public var previous: [Any] = []
    public override init() { super.init() }
    public override var description: String {
        "MTRThreadNetworkDiagnosticsClusterNetworkFaultChangeEvent(current: \(current as Optional<Any>), previous: \(previous as Optional<Any>))"
    }
}

open class MTRThreadNetworkDiagnosticsClusterOperationalDatasetComponents: NSObject {
    public var activeTimestampPresent: NSNumber = 0
    public var channelMaskPresent: NSNumber = 0
    public var channelPresent: NSNumber = 0
    public var delayPresent: NSNumber = 0
    public var extendedPanIdPresent: NSNumber = 0
    public var masterKeyPresent: NSNumber = 0
    public var meshLocalPrefixPresent: NSNumber = 0
    public var networkNamePresent: NSNumber = 0
    public var panIdPresent: NSNumber = 0
    public var pendingTimestampPresent: NSNumber = 0
    public var pskcPresent: NSNumber = 0
    public var securityPolicyPresent: NSNumber = 0
    public override init() { super.init() }
    public override var description: String {
        "MTRThreadNetworkDiagnosticsClusterOperationalDatasetComponents(activeTimestampPresent: \(activeTimestampPresent as Optional<Any>), channelMaskPresent: \(channelMaskPresent as Optional<Any>), channelPresent: \(channelPresent as Optional<Any>), delayPresent: \(delayPresent as Optional<Any>), extendedPanIdPresent: \(extendedPanIdPresent as Optional<Any>), masterKeyPresent: \(masterKeyPresent as Optional<Any>))"
    }
}

open class MTRThreadNetworkDiagnosticsClusterResetCountsParams: NSObject {
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRThreadNetworkDiagnosticsClusterResetCountsParams(serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}

open class MTRThreadNetworkDiagnosticsClusterRouteTableStruct: NSObject {
    public var age: NSNumber = 0
    public var allocated: NSNumber = 0
    public var extAddress: NSNumber = 0
    public var linkEstablished: NSNumber = 0
    public var lqiIn: NSNumber = 0
    public var lqiOut: NSNumber = 0
    public var nextHop: NSNumber = 0
    public var pathCost: NSNumber = 0
    public var rloc16: NSNumber = 0
    public var routerId: NSNumber = 0
    public override init() { super.init() }
    public override var description: String {
        "MTRThreadNetworkDiagnosticsClusterRouteTableStruct(age: \(age as Optional<Any>), allocated: \(allocated as Optional<Any>), extAddress: \(extAddress as Optional<Any>), linkEstablished: \(linkEstablished as Optional<Any>), lqiIn: \(lqiIn as Optional<Any>), lqiOut: \(lqiOut as Optional<Any>))"
    }
}

open class MTRThreadNetworkDiagnosticsClusterRouteTable: MTRThreadNetworkDiagnosticsClusterRouteTableStruct {
    public override init() { super.init() }
    public override var description: String {
        "MTRThreadNetworkDiagnosticsClusterRouteTable(MTRThreadNetworkDiagnosticsClusterRouteTable)"
    }
}

open class MTRThreadNetworkDiagnosticsClusterSecurityPolicy: NSObject {
    public var flags: NSNumber = 0
    public var rotationTime: NSNumber = 0
    public override init() { super.init() }
    public override var description: String {
        "MTRThreadNetworkDiagnosticsClusterSecurityPolicy(flags: \(flags as Optional<Any>), rotationTime: \(rotationTime as Optional<Any>))"
    }
}

open class MTRUnitTestingClusterBooleanResponseParams: NSObject {
    public init(responseValue: [String : Any]) throws {
        if let err = responseValue[MTRErrorKey] as? (any Error) {
            throw err
        }
        super.init()
        _ = responseValue[MTRDataKey] as? [String: Any]
    }
    public var timedInvokeTimeoutMs: NSNumber?
    public var value: NSNumber = 0
    public override init() { super.init() }
    public override var description: String {
        "MTRUnitTestingClusterBooleanResponseParams(timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>), value: \(value as Optional<Any>))"
    }
}

open class MTRUnitTestingClusterDoubleNestedStructList: NSObject {
    public var a: [Any] = []
    public override init() { super.init() }
    public override var description: String {
        "MTRUnitTestingClusterDoubleNestedStructList(a: \(a as Optional<Any>))"
    }
}

open class MTRUnitTestingClusterNestedStruct: NSObject {
    public var a: NSNumber = 0
    public var b: NSNumber = 0
    public var c: MTRUnitTestingClusterSimpleStruct = MTRUnitTestingClusterSimpleStruct()
    public override init() { super.init() }
    public override var description: String {
        "MTRUnitTestingClusterNestedStruct(a: \(a as Optional<Any>), b: \(b as Optional<Any>), c: \(c as Optional<Any>))"
    }
}

open class MTRUnitTestingClusterNestedStructList: NSObject {
    public var a: NSNumber = 0
    public var b: NSNumber = 0
    public var c: MTRUnitTestingClusterSimpleStruct = MTRUnitTestingClusterSimpleStruct()
    public var d: [Any] = []
    public var e: [Any] = []
    public var f: [Any] = []
    public var g: [Any] = []
    public override init() { super.init() }
    public override var description: String {
        "MTRUnitTestingClusterNestedStructList(a: \(a as Optional<Any>), b: \(b as Optional<Any>), c: \(c as Optional<Any>), d: \(d as Optional<Any>), e: \(e as Optional<Any>), f: \(f as Optional<Any>))"
    }
}

open class MTRUnitTestingClusterNullablesAndOptionalsStruct: NSObject {
    public var nullableInt: NSNumber?
    public var nullableList: [Any]?
    public var nullableOptionalInt: NSNumber?
    public var nullableOptionalList: [Any]?
    public var nullableOptionalString: String?
    public var nullableOptionalStruct: MTRUnitTestingClusterSimpleStruct?
    public var nullableString: String?
    public var nullableStruct: MTRUnitTestingClusterSimpleStruct?
    public var optionalInt: NSNumber?
    public var optionalList: [Any]?
    public var optionalString: String?
    public var optionalStruct: MTRUnitTestingClusterSimpleStruct?
    public override init() { super.init() }
    public override var description: String {
        "MTRUnitTestingClusterNullablesAndOptionalsStruct(nullableInt: \(nullableInt as Optional<Any>), nullableList: \(nullableList as Optional<Any>), nullableOptionalInt: \(nullableOptionalInt as Optional<Any>), nullableOptionalList: \(nullableOptionalList as Optional<Any>), nullableOptionalString: \(nullableOptionalString as Optional<Any>), nullableOptionalStruct: \(nullableOptionalStruct as Optional<Any>))"
    }
}

open class MTRUnitTestingClusterSimpleStruct: NSObject {
    public var a: NSNumber = 0
    public var b: NSNumber = 0
    public var c: NSNumber = 0
    public var d: Data = Data()
    public var e: String = ""
    public var f: NSNumber = 0
    public var g: NSNumber = 0
    public var h: NSNumber = 0
    public override init() { super.init() }
    public override var description: String {
        "MTRUnitTestingClusterSimpleStruct(a: \(a as Optional<Any>), b: \(b as Optional<Any>), c: \(c as Optional<Any>), d: \(d as Optional<Any>), e: \(e as Optional<Any>), f: \(f as Optional<Any>))"
    }
}

open class MTRUnitTestingClusterSimpleStructEchoRequestParams: NSObject {
    public var arg1: MTRUnitTestingClusterSimpleStruct = MTRUnitTestingClusterSimpleStruct()
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRUnitTestingClusterSimpleStructEchoRequestParams(arg1: \(arg1 as Optional<Any>), serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}

open class MTRUnitTestingClusterSimpleStructResponseParams: NSObject {
    public init(responseValue: [String : Any]) throws {
        if let err = responseValue[MTRErrorKey] as? (any Error) {
            throw err
        }
        super.init()
        _ = responseValue[MTRDataKey] as? [String: Any]
    }
    public var arg1: MTRUnitTestingClusterSimpleStruct = MTRUnitTestingClusterSimpleStruct()
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRUnitTestingClusterSimpleStructResponseParams(arg1: \(arg1 as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}

open class MTRUnitTestingClusterTestAddArgumentsParams: NSObject {
    public var arg1: NSNumber = 0
    public var arg2: NSNumber = 0
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRUnitTestingClusterTestAddArgumentsParams(arg1: \(arg1 as Optional<Any>), arg2: \(arg2 as Optional<Any>), serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}

open class MTRUnitTestingClusterTestAddArgumentsResponseParams: NSObject {
    public init(responseValue: [String : Any]) throws {
        if let err = responseValue[MTRErrorKey] as? (any Error) {
            throw err
        }
        super.init()
        _ = responseValue[MTRDataKey] as? [String: Any]
    }
    public var returnValue: NSNumber = 0
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRUnitTestingClusterTestAddArgumentsResponseParams(returnValue: \(returnValue as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}

open class MTRUnitTestingClusterTestComplexNullableOptionalRequestParams: NSObject {
    public var nullableInt: NSNumber?
    public var nullableList: [Any]?
    public var nullableOptionalInt: NSNumber?
    public var nullableOptionalList: [Any]?
    public var nullableOptionalString: String?
    public var nullableOptionalStruct: MTRUnitTestingClusterSimpleStruct?
    public var nullableString: String?
    public var nullableStruct: MTRUnitTestingClusterSimpleStruct?
    public var optionalInt: NSNumber?
    public var optionalList: [Any]?
    public var optionalString: String?
    public var optionalStruct: MTRUnitTestingClusterSimpleStruct?
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRUnitTestingClusterTestComplexNullableOptionalRequestParams(nullableInt: \(nullableInt as Optional<Any>), nullableList: \(nullableList as Optional<Any>), nullableOptionalInt: \(nullableOptionalInt as Optional<Any>), nullableOptionalList: \(nullableOptionalList as Optional<Any>), nullableOptionalString: \(nullableOptionalString as Optional<Any>), nullableOptionalStruct: \(nullableOptionalStruct as Optional<Any>))"
    }
}

open class MTRUnitTestingClusterTestComplexNullableOptionalResponseParams: NSObject {
    public init(responseValue: [String : Any]) throws {
        if let err = responseValue[MTRErrorKey] as? (any Error) {
            throw err
        }
        super.init()
        _ = responseValue[MTRDataKey] as? [String: Any]
    }
    public var nullableIntValue: NSNumber?
    public var nullableIntWasNull: NSNumber = 0
    public var nullableListValue: [Any]?
    public var nullableListWasNull: NSNumber = 0
    public var nullableOptionalIntValue: NSNumber?
    public var nullableOptionalIntWasNull: NSNumber?
    public var nullableOptionalIntWasPresent: NSNumber = 0
    public var nullableOptionalListValue: [Any]?
    public var nullableOptionalListWasNull: NSNumber?
    public var nullableOptionalListWasPresent: NSNumber = 0
    public var nullableOptionalStringValue: String?
    public var nullableOptionalStringWasNull: NSNumber?
    public var nullableOptionalStringWasPresent: NSNumber = 0
    public var nullableOptionalStructValue: MTRUnitTestingClusterSimpleStruct?
    public var nullableOptionalStructWasNull: NSNumber?
    public var nullableOptionalStructWasPresent: NSNumber = 0
    public var nullableStringValue: String?
    public var nullableStringWasNull: NSNumber = 0
    public var nullableStructValue: MTRUnitTestingClusterSimpleStruct?
    public var nullableStructWasNull: NSNumber = 0
    public var optionalIntValue: NSNumber?
    public var optionalIntWasPresent: NSNumber = 0
    public var optionalListValue: [Any]?
    public var optionalListWasPresent: NSNumber = 0
    public var optionalStringValue: String?
    public var optionalStringWasPresent: NSNumber = 0
    public var optionalStructValue: MTRUnitTestingClusterSimpleStruct?
    public var optionalStructWasPresent: NSNumber = 0
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRUnitTestingClusterTestComplexNullableOptionalResponseParams(nullableIntValue: \(nullableIntValue as Optional<Any>), nullableIntWasNull: \(nullableIntWasNull as Optional<Any>), nullableListValue: \(nullableListValue as Optional<Any>), nullableListWasNull: \(nullableListWasNull as Optional<Any>), nullableOptionalIntValue: \(nullableOptionalIntValue as Optional<Any>), nullableOptionalIntWasNull: \(nullableOptionalIntWasNull as Optional<Any>))"
    }
}

open class MTRUnitTestingClusterTestEmitTestEventRequestParams: NSObject {
    public var arg1: NSNumber = 0
    public var arg2: NSNumber = 0
    public var arg3: NSNumber = 0
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRUnitTestingClusterTestEmitTestEventRequestParams(arg1: \(arg1 as Optional<Any>), arg2: \(arg2 as Optional<Any>), arg3: \(arg3 as Optional<Any>), serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}

open class MTRUnitTestingClusterTestEmitTestEventResponseParams: NSObject {
    public init(responseValue: [String : Any]) throws {
        if let err = responseValue[MTRErrorKey] as? (any Error) {
            throw err
        }
        super.init()
        _ = responseValue[MTRDataKey] as? [String: Any]
    }
    public var timedInvokeTimeoutMs: NSNumber?
    public var value: NSNumber = 0
    public override init() { super.init() }
    public override var description: String {
        "MTRUnitTestingClusterTestEmitTestEventResponseParams(timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>), value: \(value as Optional<Any>))"
    }
}

open class MTRUnitTestingClusterTestEmitTestFabricScopedEventRequestParams: NSObject {
    public var arg1: NSNumber = 0
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRUnitTestingClusterTestEmitTestFabricScopedEventRequestParams(arg1: \(arg1 as Optional<Any>), serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}

open class MTRUnitTestingClusterTestEmitTestFabricScopedEventResponseParams: NSObject {
    public init(responseValue: [String : Any]) throws {
        if let err = responseValue[MTRErrorKey] as? (any Error) {
            throw err
        }
        super.init()
        _ = responseValue[MTRDataKey] as? [String: Any]
    }
    public var timedInvokeTimeoutMs: NSNumber?
    public var value: NSNumber = 0
    public override init() { super.init() }
    public override var description: String {
        "MTRUnitTestingClusterTestEmitTestFabricScopedEventResponseParams(timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>), value: \(value as Optional<Any>))"
    }
}

open class MTRUnitTestingClusterTestEnumsRequestParams: NSObject {
    public var arg1: NSNumber = 0
    public var arg2: NSNumber = 0
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRUnitTestingClusterTestEnumsRequestParams(arg1: \(arg1 as Optional<Any>), arg2: \(arg2 as Optional<Any>), serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}

open class MTRUnitTestingClusterTestEnumsResponseParams: NSObject {
    public init(responseValue: [String : Any]) throws {
        if let err = responseValue[MTRErrorKey] as? (any Error) {
            throw err
        }
        super.init()
        _ = responseValue[MTRDataKey] as? [String: Any]
    }
    public var arg1: NSNumber = 0
    public var arg2: NSNumber = 0
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRUnitTestingClusterTestEnumsResponseParams(arg1: \(arg1 as Optional<Any>), arg2: \(arg2 as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}

open class MTRUnitTestingClusterTestEventEvent: NSObject {
    public var arg1: NSNumber = 0
    public var arg2: NSNumber = 0
    public var arg3: NSNumber = 0
    public var arg4: MTRUnitTestingClusterSimpleStruct = MTRUnitTestingClusterSimpleStruct()
    public var arg5: [Any] = []
    public var arg6: [Any] = []
    public override init() { super.init() }
    public override var description: String {
        "MTRUnitTestingClusterTestEventEvent(arg1: \(arg1 as Optional<Any>), arg2: \(arg2 as Optional<Any>), arg3: \(arg3 as Optional<Any>), arg4: \(arg4 as Optional<Any>), arg5: \(arg5 as Optional<Any>), arg6: \(arg6 as Optional<Any>))"
    }
}

open class MTRUnitTestingClusterTestFabricScoped: NSObject {
    public var fabricIndex: NSNumber = 0
    public var fabricSensitiveCharString: String = ""
    public var fabricSensitiveInt8u: NSNumber = 0
    public var fabricSensitiveInt8uList: [Any] = []
    public var fabricSensitiveStruct: MTRUnitTestingClusterSimpleStruct = MTRUnitTestingClusterSimpleStruct()
    public var nullableFabricSensitiveInt8u: NSNumber?
    public var nullableOptionalFabricSensitiveInt8u: NSNumber?
    public var optionalFabricSensitiveInt8u: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRUnitTestingClusterTestFabricScoped(fabricIndex: \(fabricIndex as Optional<Any>), fabricSensitiveCharString: \(fabricSensitiveCharString as Optional<Any>), fabricSensitiveInt8u: \(fabricSensitiveInt8u as Optional<Any>), fabricSensitiveInt8uList: \(fabricSensitiveInt8uList as Optional<Any>), fabricSensitiveStruct: \(fabricSensitiveStruct as Optional<Any>), nullableFabricSensitiveInt8u: \(nullableFabricSensitiveInt8u as Optional<Any>))"
    }
}

open class MTRUnitTestingClusterTestFabricScopedEventEvent: NSObject {
    public var fabricIndex: NSNumber = 0
    public override init() { super.init() }
    public override var description: String {
        "MTRUnitTestingClusterTestFabricScopedEventEvent(fabricIndex: \(fabricIndex as Optional<Any>))"
    }
}

open class MTRUnitTestingClusterTestListInt8UArgumentRequestParams: NSObject {
    public var arg1: [Any] = []
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRUnitTestingClusterTestListInt8UArgumentRequestParams(arg1: \(arg1 as Optional<Any>), serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}

open class MTRUnitTestingClusterTestListInt8UReverseRequestParams: NSObject {
    public var arg1: [Any] = []
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRUnitTestingClusterTestListInt8UReverseRequestParams(arg1: \(arg1 as Optional<Any>), serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}

open class MTRUnitTestingClusterTestListInt8UReverseResponseParams: NSObject {
    public init(responseValue: [String : Any]) throws {
        if let err = responseValue[MTRErrorKey] as? (any Error) {
            throw err
        }
        super.init()
        _ = responseValue[MTRDataKey] as? [String: Any]
    }
    public var arg1: [Any] = []
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRUnitTestingClusterTestListInt8UReverseResponseParams(arg1: \(arg1 as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}

open class MTRUnitTestingClusterTestListNestedStructListArgumentRequestParams: NSObject {
    public var arg1: [Any] = []
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRUnitTestingClusterTestListNestedStructListArgumentRequestParams(arg1: \(arg1 as Optional<Any>), serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}

open class MTRUnitTestingClusterTestListStructArgumentRequestParams: NSObject {
    public var arg1: [Any] = []
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRUnitTestingClusterTestListStructArgumentRequestParams(arg1: \(arg1 as Optional<Any>), serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}

open class MTRUnitTestingClusterTestListStructOctet: NSObject {
    public var member1: NSNumber = 0
    public var member2: Data = Data()
    public override init() { super.init() }
    public override var description: String {
        "MTRUnitTestingClusterTestListStructOctet(member1: \(member1 as Optional<Any>), member2: \(member2 as Optional<Any>))"
    }
}

open class MTRUnitTestingClusterTestNestedStructArgumentRequestParams: NSObject {
    public var arg1: MTRUnitTestingClusterNestedStruct = MTRUnitTestingClusterNestedStruct()
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRUnitTestingClusterTestNestedStructArgumentRequestParams(arg1: \(arg1 as Optional<Any>), serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}

open class MTRUnitTestingClusterTestNestedStructListArgumentRequestParams: NSObject {
    public var arg1: MTRUnitTestingClusterNestedStructList = MTRUnitTestingClusterNestedStructList()
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRUnitTestingClusterTestNestedStructListArgumentRequestParams(arg1: \(arg1 as Optional<Any>), serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}

open class MTRUnitTestingClusterTestNotHandledParams: NSObject {
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRUnitTestingClusterTestNotHandledParams(serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}

open class MTRUnitTestingClusterTestNullableOptionalRequestParams: NSObject {
    public var arg1: NSNumber?
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRUnitTestingClusterTestNullableOptionalRequestParams(arg1: \(arg1 as Optional<Any>), serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}

open class MTRUnitTestingClusterTestNullableOptionalResponseParams: NSObject {
    public init(responseValue: [String : Any]) throws {
        if let err = responseValue[MTRErrorKey] as? (any Error) {
            throw err
        }
        super.init()
        _ = responseValue[MTRDataKey] as? [String: Any]
    }
    public var originalValue: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public var value: NSNumber?
    public var wasNull: NSNumber?
    public var wasPresent: NSNumber = 0
    public override init() { super.init() }
    public override var description: String {
        "MTRUnitTestingClusterTestNullableOptionalResponseParams(originalValue: \(originalValue as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>), value: \(value as Optional<Any>), wasNull: \(wasNull as Optional<Any>), wasPresent: \(wasPresent as Optional<Any>))"
    }
}

open class MTRUnitTestingClusterTestParams: NSObject {
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRUnitTestingClusterTestParams(serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}

open class MTRUnitTestingClusterTestSimpleArgumentRequestParams: NSObject {
    public var arg1: NSNumber = 0
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRUnitTestingClusterTestSimpleArgumentRequestParams(arg1: \(arg1 as Optional<Any>), serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}

open class MTRUnitTestingClusterTestSimpleArgumentResponseParams: NSObject {
    public init(responseValue: [String : Any]) throws {
        if let err = responseValue[MTRErrorKey] as? (any Error) {
            throw err
        }
        super.init()
        _ = responseValue[MTRDataKey] as? [String: Any]
    }
    public var returnValue: NSNumber = 0
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRUnitTestingClusterTestSimpleArgumentResponseParams(returnValue: \(returnValue as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}

open class MTRUnitTestingClusterTestSimpleOptionalArgumentRequestParams: NSObject {
    public var arg1: NSNumber?
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRUnitTestingClusterTestSimpleOptionalArgumentRequestParams(arg1: \(arg1 as Optional<Any>), serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}

open class MTRUnitTestingClusterTestSpecificParams: NSObject {
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRUnitTestingClusterTestSpecificParams(serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}

open class MTRUnitTestingClusterTestSpecificResponseParams: NSObject {
    public init(responseValue: [String : Any]) throws {
        if let err = responseValue[MTRErrorKey] as? (any Error) {
            throw err
        }
        super.init()
        _ = responseValue[MTRDataKey] as? [String: Any]
    }
    public var returnValue: NSNumber = 0
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRUnitTestingClusterTestSpecificResponseParams(returnValue: \(returnValue as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}

open class MTRUnitTestingClusterTestStructArgumentRequestParams: NSObject {
    public var arg1: MTRUnitTestingClusterSimpleStruct = MTRUnitTestingClusterSimpleStruct()
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRUnitTestingClusterTestStructArgumentRequestParams(arg1: \(arg1 as Optional<Any>), serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}

open class MTRUnitTestingClusterTestStructArrayArgumentRequestParams: NSObject {
    public var arg1: [Any] = []
    public var arg2: [Any] = []
    public var arg3: [Any] = []
    public var arg4: [Any] = []
    public var arg5: NSNumber = 0
    public var arg6: NSNumber = 0
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRUnitTestingClusterTestStructArrayArgumentRequestParams(arg1: \(arg1 as Optional<Any>), arg2: \(arg2 as Optional<Any>), arg3: \(arg3 as Optional<Any>), arg4: \(arg4 as Optional<Any>), arg5: \(arg5 as Optional<Any>), arg6: \(arg6 as Optional<Any>))"
    }
}

open class MTRUnitTestingClusterTestStructArrayArgumentResponseParams: NSObject {
    public init(responseValue: [String : Any]) throws {
        if let err = responseValue[MTRErrorKey] as? (any Error) {
            throw err
        }
        super.init()
        _ = responseValue[MTRDataKey] as? [String: Any]
    }
    public var arg1: [Any] = []
    public var arg2: [Any] = []
    public var arg3: [Any] = []
    public var arg4: [Any] = []
    public var arg5: NSNumber = 0
    public var arg6: NSNumber = 0
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRUnitTestingClusterTestStructArrayArgumentResponseParams(arg1: \(arg1 as Optional<Any>), arg2: \(arg2 as Optional<Any>), arg3: \(arg3 as Optional<Any>), arg4: \(arg4 as Optional<Any>), arg5: \(arg5 as Optional<Any>), arg6: \(arg6 as Optional<Any>))"
    }
}

open class MTRUnitTestingClusterTestUnknownCommandParams: NSObject {
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRUnitTestingClusterTestUnknownCommandParams(serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}

open class MTRUnitTestingClusterTimedInvokeRequestParams: NSObject {
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRUnitTestingClusterTimedInvokeRequestParams(serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}

open class MTRWindowCoveringClusterDownOrCloseParams: NSObject {
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRWindowCoveringClusterDownOrCloseParams(serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}

open class MTRWindowCoveringClusterGoToLiftPercentageParams: NSObject {
    public var liftPercent100thsValue: NSNumber = 0
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRWindowCoveringClusterGoToLiftPercentageParams(liftPercent100thsValue: \(liftPercent100thsValue as Optional<Any>), serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}

open class MTRWindowCoveringClusterGoToLiftValueParams: NSObject {
    public var liftValue: NSNumber = 0
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRWindowCoveringClusterGoToLiftValueParams(liftValue: \(liftValue as Optional<Any>), serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}

open class MTRWindowCoveringClusterGoToTiltPercentageParams: NSObject {
    public var serverSideProcessingTimeout: NSNumber?
    public var tiltPercent100thsValue: NSNumber = 0
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRWindowCoveringClusterGoToTiltPercentageParams(serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), tiltPercent100thsValue: \(tiltPercent100thsValue as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}

open class MTRWindowCoveringClusterGoToTiltValueParams: NSObject {
    public var serverSideProcessingTimeout: NSNumber?
    public var tiltValue: NSNumber = 0
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRWindowCoveringClusterGoToTiltValueParams(serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), tiltValue: \(tiltValue as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}

open class MTRWindowCoveringClusterStopMotionParams: NSObject {
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRWindowCoveringClusterStopMotionParams(serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}

open class MTRWindowCoveringClusterUpOrOpenParams: NSObject {
    public var serverSideProcessingTimeout: NSNumber?
    public var timedInvokeTimeoutMs: NSNumber?
    public override init() { super.init() }
    public override var description: String {
        "MTRWindowCoveringClusterUpOrOpenParams(serverSideProcessingTimeout: \(serverSideProcessingTimeout as Optional<Any>), timedInvokeTimeoutMs: \(timedInvokeTimeoutMs as Optional<Any>))"
    }
}

