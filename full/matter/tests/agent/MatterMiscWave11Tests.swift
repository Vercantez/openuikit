import Foundation
import Dispatch
import Matter

func testEmptyClusterEventsWave11() {
    mtrRequire(MTRApplicationBasicClusterApplicationBasicApplication().description.contains("MTRApplicationBasicClusterApplicationStruct"), "ApplicationBasicApplication alias")
    mtrRequire(MTRApplicationLauncherClusterApplication().description.contains("MTRApplicationLauncherClusterApplicationStruct"), "ApplicationLauncher alias")
    mtrRequire(MTRBasicClusterShutDownEvent().description.contains("MTRBasicClusterShutDownEvent"), "BasicShutDown")
    mtrRequire(MTRBasicInformationClusterShutDownEvent().description.contains("MTRBasicInformationClusterShutDownEvent"), "BasicInformationShutDown")
    mtrRequire(MTRBridgedDeviceBasicClusterLeaveEvent().description.contains("MTRBridgedDeviceBasicClusterLeaveEvent"), "BridgedLeave")
    mtrRequire(MTRBridgedDeviceBasicClusterShutDownEvent().description.contains("MTRBridgedDeviceBasicClusterShutDownEvent"), "BridgedShutDown")
    mtrRequire(MTRBridgedDeviceBasicInformationClusterLeaveEvent().description.contains("MTRBridgedDeviceBasicInformationClusterLeaveEvent"), "BridgedInfoLeave")
    mtrRequire(MTRBridgedDeviceBasicInformationClusterShutDownEvent().description.contains("MTRBridgedDeviceBasicInformationClusterShutDownEvent"), "BridgedInfoShutDown")
    mtrRequire(MTRDeviceEnergyManagementClusterPausedEvent().description.contains("MTRDeviceEnergyManagementClusterPausedEvent"), "Paused")
    mtrRequire(MTRDeviceEnergyManagementClusterPowerAdjustStartEvent().description.contains("MTRDeviceEnergyManagementClusterPowerAdjustStartEvent"), "PowerAdjustStart")
    mtrRequire(MTRSmokeCOAlarmClusterAlarmMutedEvent().description.contains("MTRSmokeCOAlarmClusterAlarmMutedEvent"), "AlarmMuted")
    mtrRequire(MTRSmokeCOAlarmClusterAllClearEvent().description.contains("MTRSmokeCOAlarmClusterAllClearEvent"), "AllClear")
    mtrRequire(MTRSmokeCOAlarmClusterEndOfServiceEvent().description.contains("MTRSmokeCOAlarmClusterEndOfServiceEvent"), "EndOfService")
    mtrRequire(MTRSmokeCOAlarmClusterHardwareFaultEvent().description.contains("MTRSmokeCOAlarmClusterHardwareFaultEvent"), "HardwareFault")
    mtrRequire(MTRSmokeCOAlarmClusterMuteEndedEvent().description.contains("MTRSmokeCOAlarmClusterMuteEndedEvent"), "MuteEnded")
    mtrRequire(MTRSmokeCOAlarmClusterSelfTestCompleteEvent().description.contains("MTRSmokeCOAlarmClusterSelfTestCompleteEvent"), "SelfTestComplete")
    mtrRequire(MTRTimeSynchronizationClusterDSTTableEmptyEvent().description.contains("MTRTimeSynchronizationClusterDSTTableEmptyEvent"), "DSTTableEmpty")
    mtrRequire(MTRTimeSynchronizationClusterMissingTrustedTimeSourceEvent().description.contains("MTRTimeSynchronizationClusterMissingTrustedTimeSourceEvent"), "MissingTrustedTimeSource")
    mtrRequire(MTRTimeSynchronizationClusterTimeFailureEvent().description.contains("MTRTimeSynchronizationClusterTimeFailureEvent"), "TimeFailure")
    mtrRequire(MTRWaterHeaterManagementClusterBoostEndedEvent().description.contains("MTRWaterHeaterManagementClusterBoostEndedEvent"), "BoostEnded")
}

func testDistinguishedNameInfoWave11() {
    let info = MTRDistinguishedNameInfo()
    info.rootCACertificateID = n(1)
    _ = info.rootCACertificateID
    info.intermediateCACertificateID = n(2)
    _ = info.intermediateCACertificateID
    mtrRequire(info.intermediateCACertificateID == n(2), "MTRDistinguishedNameInfo intermediateCACertificateID")
}

func testAttributeCacheContainerWave11() {
    let container = MTRAttributeCacheContainer()
    _ = container
}
