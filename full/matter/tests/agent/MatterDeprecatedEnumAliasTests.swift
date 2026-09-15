import Foundation
import Dispatch
import Matter

func testMTRAudioOutputOutputTypeDeprecatedAliasesWave11() {
    mtrRequire(MTRAudioOutputOutputType.bt == MTRAudioOutputOutputType.BT, "MTRAudioOutputOutputType.bt")
    mtrRequire(MTRAudioOutputOutputType.hdmi == MTRAudioOutputOutputType.HDMI, "MTRAudioOutputOutputType.hdmi")
}

func testMTRChannelLineupInfoTypeDeprecatedAliasesWave11() {
    mtrRequire(MTRChannelLineupInfoType.mso == MTRChannelLineupInfoType.MSO, "MTRChannelLineupInfoType.mso")
}

func testMTRColorControlColorLoopDirectionDeprecatedAliasesWave11() {
    mtrRequire(MTRColorControlColorLoopDirection.decrementHue == MTRColorControlColorLoopDirection.decrement, "MTRColorControlColorLoopDirection.decrementHue")
    mtrRequire(MTRColorControlColorLoopDirection.incrementHue == MTRColorControlColorLoopDirection.increment, "MTRColorControlColorLoopDirection.incrementHue")
}

func testMTRColorControlColorModeDeprecatedAliasesWave11() {
    mtrRequire(MTRColorControlColorMode.colorTemperature == MTRColorControlColorMode.colorTemperatureMireds, "MTRColorControlColorMode.colorTemperature")
}

func testMTRContentLauncherMetricTypeDeprecatedAliasesWave11() {
    mtrRequire(MTRContentLauncherMetricType.PERCENTAGE == MTRContentLauncherMetricType.percentage, "MTRContentLauncherMetricType.PERCENTAGE")
    mtrRequire(MTRContentLauncherMetricType.PIXELS == MTRContentLauncherMetricType.pixels, "MTRContentLauncherMetricType.PIXELS")
}

func testMTRDoorLockUserTypeDeprecatedAliasesWave11() {
    mtrRequire(MTRDoorLockUserType.masterUser == MTRDoorLockUserType.programmingUser, "MTRDoorLockUserType.masterUser")
    mtrRequire(MTRDoorLockUserType.unrestricted == MTRDoorLockUserType.unrestrictedUser, "MTRDoorLockUserType.unrestricted")
}

func testMTRFanControlFanModeSequenceDeprecatedAliasesWave11() {
    mtrRequire(MTRFanControlFanModeSequence.offOn == MTRFanControlFanModeSequence.offHigh, "MTRFanControlFanModeSequence.offOn")
    mtrRequire(MTRFanControlFanModeSequence.offOnAuto == MTRFanControlFanModeSequence.offHighAuto, "MTRFanControlFanModeSequence.offOnAuto")
}

func testMTRGeneralCommissioningCommissioningErrorDeprecatedAliasesWave11() {
    mtrRequire(MTRGeneralCommissioningCommissioningError.ok == MTRGeneralCommissioningCommissioningError.OK, "MTRGeneralCommissioningCommissioningError.ok")
}

func testMTRIdentifyTypeDeprecatedAliasesWave11() {
    mtrRequire(MTRIdentifyType.visibleLED == MTRIdentifyType.visibleIndicator, "MTRIdentifyType.visibleLED")
    mtrRequire(MTRIdentifyType.visibleLight == MTRIdentifyType.lightOutput, "MTRIdentifyType.visibleLight")
}

func testMTRMediaInputInputTypeDeprecatedAliasesWave11() {
    mtrRequire(MTRMediaInputInputType.hdmi == MTRMediaInputInputType.HDMI, "MTRMediaInputInputType.hdmi")
    mtrRequire(MTRMediaInputInputType.scart == MTRMediaInputInputType.SCART, "MTRMediaInputInputType.scart")
    mtrRequire(MTRMediaInputInputType.usb == MTRMediaInputInputType.USB, "MTRMediaInputInputType.usb")
}

func testMTROnOffDelayedAllOffEffectVariantDeprecatedAliasesWave11() {
    mtrRequire(MTROnOffDelayedAllOffEffectVariant.fadeToOffIn0p8Seconds == MTROnOffDelayedAllOffEffectVariant.delayedOffFastFade, "MTROnOffDelayedAllOffEffectVariant.fadeToOffIn0p8Seconds")
}

func testMTROnOffStartUpOnOffDeprecatedAliasesWave11() {
    mtrRequire(MTROnOffStartUpOnOff.togglePreviousOnOff == MTROnOffStartUpOnOff.toggle, "MTROnOffStartUpOnOff.togglePreviousOnOff")
}

func testMTRPowerSourceBatChargeFaultDeprecatedAliasesWave11() {
    mtrRequire(MTRPowerSourceBatChargeFault.unspecfied == MTRPowerSourceBatChargeFault.unspecified, "MTRPowerSourceBatChargeFault.unspecfied")
}

func testMTRPowerSourceBatChargeLevelDeprecatedAliasesWave11() {
    mtrRequire(MTRPowerSourceBatChargeLevel.ok == MTRPowerSourceBatChargeLevel.OK, "MTRPowerSourceBatChargeLevel.ok")
}

func testMTRPowerSourceBatFaultDeprecatedAliasesWave11() {
    mtrRequire(MTRPowerSourceBatFault.unspecfied == MTRPowerSourceBatFault.unspecified, "MTRPowerSourceBatFault.unspecfied")
}

func testMTRPowerSourceStatusDeprecatedAliasesWave11() {
    mtrRequire(MTRPowerSourceStatus.unspecfied == MTRPowerSourceStatus.unspecified, "MTRPowerSourceStatus.unspecfied")
}

func testMTRPowerSourceWiredFaultDeprecatedAliasesWave11() {
    mtrRequire(MTRPowerSourceWiredFault.unspecfied == MTRPowerSourceWiredFault.unspecified, "MTRPowerSourceWiredFault.unspecfied")
}

func testMTRThermostatSystemModeDeprecatedAliasesWave11() {
    mtrRequire(MTRThermostatSystemMode.emergencyHeating == MTRThermostatSystemMode.emergencyHeat, "MTRThermostatSystemMode.emergencyHeating")
}

