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

// Wave-8 Apple-oracle legacy spellings. Raw values are pinned from the Xcode
// 26.1 Matter.framework headers (MTRBaseClusters.h) and confirmed by a macOS
// runtime probe against the same SDK:
//   fabricSntp/fabricNtp/mixedNtp/nonFabricSntp/nonFabricNtp = 6/7/8/4/5,
//   NTS variants fabricSntpNts/fabricNtpNts/mixedNtpNts/nonFabricSntpNts/
//   nonFabricNtpNts = 11/12/13/9/10, ptp = 15, gnss = 16;
//   heatSetpoint/coolSetpoint/heatAndCoolSetpoints = 0/1/2;
//   type80211a/b/g/n/ac/ax = 0/1/2/3/4/5.
// Each spelling duplicates a newer enumerator, so Swift models them as
// static aliases (duplicate raw-value cases are illegal in Swift).

extension MTRTimeSynchronizationTimeSource {
    public static var nonFabricSntp: MTRTimeSynchronizationTimeSource { .nonMatterSNTP }
    public static var nonFabricNtp: MTRTimeSynchronizationTimeSource { .nonMatterNTP }
    public static var fabricSntp: MTRTimeSynchronizationTimeSource { .matterSNTP }
    public static var fabricNtp: MTRTimeSynchronizationTimeSource { .matterNTP }
    public static var mixedNtp: MTRTimeSynchronizationTimeSource { .mixedNTP }
    public static var nonFabricSntpNts: MTRTimeSynchronizationTimeSource { .nonMatterSNTPNTS }
    public static var nonFabricNtpNts: MTRTimeSynchronizationTimeSource { .nonMatterNTPNTS }
    public static var fabricSntpNts: MTRTimeSynchronizationTimeSource { .matterSNTPNTS }
    public static var fabricNtpNts: MTRTimeSynchronizationTimeSource { .matterNTPNTS }
    public static var mixedNtpNts: MTRTimeSynchronizationTimeSource { .mixedNTPNTS }
    public static var ptp: MTRTimeSynchronizationTimeSource { .PTP }
    public static var gnss: MTRTimeSynchronizationTimeSource { .GNSS }
}

extension MTRThermostatSetpointAdjustMode {
    public static var heatSetpoint: MTRThermostatSetpointAdjustMode { .heat }
    public static var coolSetpoint: MTRThermostatSetpointAdjustMode { .cool }
    public static var heatAndCoolSetpoints: MTRThermostatSetpointAdjustMode { .both }
}

extension MTRWiFiNetworkDiagnosticsWiFiVersionType {
    public static var type80211a: MTRWiFiNetworkDiagnosticsWiFiVersionType { .A }
    public static var type80211b: MTRWiFiNetworkDiagnosticsWiFiVersionType { .B }
    public static var type80211g: MTRWiFiNetworkDiagnosticsWiFiVersionType { .G }
    public static var type80211n: MTRWiFiNetworkDiagnosticsWiFiVersionType { .N }
    public static var type80211ac: MTRWiFiNetworkDiagnosticsWiFiVersionType { .ac }
    public static var type80211ax: MTRWiFiNetworkDiagnosticsWiFiVersionType { .ax }
}

