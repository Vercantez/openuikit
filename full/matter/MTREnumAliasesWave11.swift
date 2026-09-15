import Foundation

// Wave-11 deprecated Apple enum aliases (renamed cases).

extension MTRAudioOutputOutputType {
    public static var bt: MTRAudioOutputOutputType { .BT }
    public static var hdmi: MTRAudioOutputOutputType { .HDMI }
}

extension MTRChannelLineupInfoType {
    public static var mso: MTRChannelLineupInfoType { .MSO }
}

extension MTRColorControlColorLoopDirection {
    public static var decrementHue: MTRColorControlColorLoopDirection { .decrement }
    public static var incrementHue: MTRColorControlColorLoopDirection { .increment }
}

extension MTRColorControlColorMode {
    public static var colorTemperature: MTRColorControlColorMode { .colorTemperatureMireds }
}

extension MTRContentLauncherMetricType {
    public static var PERCENTAGE: MTRContentLauncherMetricType { .percentage }
    public static var PIXELS: MTRContentLauncherMetricType { .pixels }
}

extension MTRDoorLockUserType {
    public static var masterUser: MTRDoorLockUserType { .programmingUser }
    public static var unrestricted: MTRDoorLockUserType { .unrestrictedUser }
}

extension MTRFanControlFanModeSequence {
    public static var offOn: MTRFanControlFanModeSequence { .offHigh }
    public static var offOnAuto: MTRFanControlFanModeSequence { .offHighAuto }
}

extension MTRGeneralCommissioningCommissioningError {
    public static var ok: MTRGeneralCommissioningCommissioningError { .OK }
}

extension MTRIdentifyType {
    public static var visibleLED: MTRIdentifyType { .visibleIndicator }
    public static var visibleLight: MTRIdentifyType { .lightOutput }
}

extension MTRMediaInputInputType {
    public static var hdmi: MTRMediaInputInputType { .HDMI }
    public static var scart: MTRMediaInputInputType { .SCART }
    public static var usb: MTRMediaInputInputType { .USB }
}

extension MTROnOffDelayedAllOffEffectVariant {
    public static var fadeToOffIn0p8Seconds: MTROnOffDelayedAllOffEffectVariant { .delayedOffFastFade }
}

extension MTROnOffStartUpOnOff {
    public static var togglePreviousOnOff: MTROnOffStartUpOnOff { .toggle }
}

extension MTRPowerSourceBatChargeFault {
    public static var unspecfied: MTRPowerSourceBatChargeFault { .unspecified }
}

extension MTRPowerSourceBatChargeLevel {
    public static var ok: MTRPowerSourceBatChargeLevel { .OK }
}

extension MTRPowerSourceBatFault {
    public static var unspecfied: MTRPowerSourceBatFault { .unspecified }
}

extension MTRPowerSourceStatus {
    public static var unspecfied: MTRPowerSourceStatus { .unspecified }
}

extension MTRPowerSourceWiredFault {
    public static var unspecfied: MTRPowerSourceWiredFault { .unspecified }
}

extension MTRThermostatSystemMode {
    public static var emergencyHeating: MTRThermostatSystemMode { .emergencyHeat }
}

