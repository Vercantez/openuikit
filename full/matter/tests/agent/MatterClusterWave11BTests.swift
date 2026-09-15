import Foundation
import Dispatch
import Matter

func testClusterLaundryDryerControlsWave11Init() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    _ = MTRClusterLaundryDryerControls(device: device, endpointID: n(1), queue: DispatchQueue.global())
}

func testClusterLaundryDryerControlsWave11Cache() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    guard let cluster = MTRClusterLaundryDryerControls(device: device, endpointID: n(1), queue: DispatchQueue.global()) else {
        mtrRequire(false, "MTRClusterLaundryDryerControls init")
        return
    }
    _ = cluster.readAttributeAcceptedCommandList(with: MTRReadParams())
    _ = cluster.readAttributeAttributeList(with: MTRReadParams())
    _ = cluster.readAttributeClusterRevision(with: MTRReadParams())
    _ = cluster.readAttributeFeatureMap(with: MTRReadParams())
    _ = cluster.readAttributeGeneratedCommandList(with: MTRReadParams())
    _ = cluster.readAttributeSelectedDrynessLevel(with: MTRReadParams())
    _ = cluster.readAttributeSupportedDrynessLevels(with: MTRReadParams())
    cluster.writeAttributeSelectedDrynessLevel(withValue: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1)), expectedValueInterval: n(1))
    cluster.writeAttributeSelectedDrynessLevel(withValue: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1)), expectedValueInterval: n(1), params: MTRWriteParams())
    let probe = MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(7))
    cluster.writeAttributeSelectedDrynessLevel(withValue: probe, expectedValueInterval: n(1))
    let cached = cluster.readAttributeSelectedDrynessLevel(with: nil)
    mtrRequire(cached != nil, "expected-value cache round-trip")
}

func testClusterLaundryWasherControlsWave11Init() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    _ = MTRClusterLaundryWasherControls(device: device, endpointID: n(1), queue: DispatchQueue.global())
}

func testClusterLaundryWasherControlsWave11Cache() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    guard let cluster = MTRClusterLaundryWasherControls(device: device, endpointID: n(1), queue: DispatchQueue.global()) else {
        mtrRequire(false, "MTRClusterLaundryWasherControls init")
        return
    }
    _ = cluster.readAttributeAcceptedCommandList(with: MTRReadParams())
    _ = cluster.readAttributeAttributeList(with: MTRReadParams())
    _ = cluster.readAttributeClusterRevision(with: MTRReadParams())
    _ = cluster.readAttributeFeatureMap(with: MTRReadParams())
    _ = cluster.readAttributeGeneratedCommandList(with: MTRReadParams())
    _ = cluster.readAttributeNumberOfRinses(with: MTRReadParams())
    _ = cluster.readAttributeSpinSpeedCurrent(with: MTRReadParams())
    _ = cluster.readAttributeSpinSpeeds(with: MTRReadParams())
    _ = cluster.readAttributeSupportedRinses(with: MTRReadParams())
    cluster.writeAttributeNumberOfRinses(withValue: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1)), expectedValueInterval: n(1))
    cluster.writeAttributeNumberOfRinses(withValue: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1)), expectedValueInterval: n(1), params: MTRWriteParams())
    cluster.writeAttributeSpinSpeedCurrent(withValue: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1)), expectedValueInterval: n(1))
    cluster.writeAttributeSpinSpeedCurrent(withValue: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1)), expectedValueInterval: n(1), params: MTRWriteParams())
    let probe = MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(7))
    cluster.writeAttributeNumberOfRinses(withValue: probe, expectedValueInterval: n(1))
    let cached = cluster.readAttributeNumberOfRinses(with: nil)
    mtrRequire(cached != nil, "expected-value cache round-trip")
}

func testClusterLaundryWasherModeWave11Init() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    _ = MTRClusterLaundryWasherMode(device: device, endpointID: n(1), queue: DispatchQueue.global())
}

func testClusterLaundryWasherModeWave11Command() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    guard let cluster = MTRClusterLaundryWasherMode(device: device, endpointID: n(1), queue: DispatchQueue.global()) else {
        mtrRequire(false, "MTRClusterLaundryWasherMode init")
        return
    }
    cluster.changeToMode(with: MTRLaundryWasherModeClusterChangeToModeParams(), expectedValues: [], expectedValueInterval: n(1), completion: { _, err in mtrExpectInvalidState(err) })
}

func testClusterLaundryWasherModeWave11Cache() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    guard let cluster = MTRClusterLaundryWasherMode(device: device, endpointID: n(1), queue: DispatchQueue.global()) else {
        mtrRequire(false, "MTRClusterLaundryWasherMode init")
        return
    }
    _ = cluster.readAttributeAcceptedCommandList(with: MTRReadParams())
    _ = cluster.readAttributeAttributeList(with: MTRReadParams())
    _ = cluster.readAttributeClusterRevision(with: MTRReadParams())
    _ = cluster.readAttributeCurrentMode(with: MTRReadParams())
    _ = cluster.readAttributeFeatureMap(with: MTRReadParams())
    _ = cluster.readAttributeGeneratedCommandList(with: MTRReadParams())
    _ = cluster.readAttributeSupportedModes(with: MTRReadParams())
}

func testClusterLocalizationConfigurationWave11Init() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    _ = MTRClusterLocalizationConfiguration(device: device, endpoint: 1, queue: DispatchQueue.global())
    _ = MTRClusterLocalizationConfiguration(device: device, endpointID: n(1), queue: DispatchQueue.global())
}

func testClusterLocalizationConfigurationWave11Cache() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    guard let cluster = MTRClusterLocalizationConfiguration(device: device, endpointID: n(1), queue: DispatchQueue.global()) else {
        mtrRequire(false, "MTRClusterLocalizationConfiguration init")
        return
    }
    _ = cluster.readAttributeAcceptedCommandList(with: MTRReadParams())
    _ = cluster.readAttributeActiveLocale(with: MTRReadParams())
    _ = cluster.readAttributeAttributeList(with: MTRReadParams())
    _ = cluster.readAttributeClusterRevision(with: MTRReadParams())
    _ = cluster.readAttributeFeatureMap(with: MTRReadParams())
    _ = cluster.readAttributeGeneratedCommandList(with: MTRReadParams())
    _ = cluster.readAttributeSupportedLocales(with: MTRReadParams())
    cluster.writeAttributeActiveLocale(withValue: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1)), expectedValueInterval: n(1))
    cluster.writeAttributeActiveLocale(withValue: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1)), expectedValueInterval: n(1), params: MTRWriteParams())
    let probe = MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(7))
    cluster.writeAttributeActiveLocale(withValue: probe, expectedValueInterval: n(1))
    let cached = cluster.readAttributeActiveLocale(with: nil)
    mtrRequire(cached != nil, "expected-value cache round-trip")
}

func testClusterLowPowerWave11Init() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    _ = MTRClusterLowPower(device: device, endpoint: 1, queue: DispatchQueue.global())
    _ = MTRClusterLowPower(device: device, endpointID: n(1), queue: DispatchQueue.global())
}

func testClusterLowPowerWave11Command() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    guard let cluster = MTRClusterLowPower(device: device, endpointID: n(1), queue: DispatchQueue.global()) else {
        mtrRequire(false, "MTRClusterLowPower init")
        return
    }
    cluster.sleep(withExpectedValues: [], expectedValueInterval: n(1), completion: { err in mtrExpectInvalidState(err) })
    cluster.sleep(withExpectedValues: [], expectedValueInterval: n(1), completionHandler: { err in mtrExpectInvalidState(err) })
    cluster.sleep(with: MTRLowPowerClusterSleepParams(), expectedValues: [], expectedValueInterval: n(1), completion: { err in mtrExpectInvalidState(err) })
    cluster.sleep(with: MTRLowPowerClusterSleepParams(), expectedValues: [], expectedValueInterval: n(1), completionHandler: { err in mtrExpectInvalidState(err) })
}

func testClusterLowPowerWave11Cache() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    guard let cluster = MTRClusterLowPower(device: device, endpointID: n(1), queue: DispatchQueue.global()) else {
        mtrRequire(false, "MTRClusterLowPower init")
        return
    }
    _ = cluster.readAttributeAcceptedCommandList(with: MTRReadParams())
    _ = cluster.readAttributeAttributeList(with: MTRReadParams())
    _ = cluster.readAttributeClusterRevision(with: MTRReadParams())
    _ = cluster.readAttributeFeatureMap(with: MTRReadParams())
    _ = cluster.readAttributeGeneratedCommandList(with: MTRReadParams())
}

func testClusterMessagesWave11Init() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    _ = MTRClusterMessages(device: device, endpointID: n(1), queue: DispatchQueue.global())
}

func testClusterMessagesWave11Command() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    guard let cluster = MTRClusterMessages(device: device, endpointID: n(1), queue: DispatchQueue.global()) else {
        mtrRequire(false, "MTRClusterMessages init")
        return
    }
    cluster.cancelRequest(with: MTRMessagesClusterCancelMessagesRequestParams(), expectedValues: [], expectedValueInterval: n(1), completion: { err in mtrExpectInvalidState(err) })
    cluster.presentRequest(with: MTRMessagesClusterPresentMessagesRequestParams(), expectedValues: [], expectedValueInterval: n(1), completion: { err in mtrExpectInvalidState(err) })
}

func testClusterMessagesWave11Cache() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    guard let cluster = MTRClusterMessages(device: device, endpointID: n(1), queue: DispatchQueue.global()) else {
        mtrRequire(false, "MTRClusterMessages init")
        return
    }
    _ = cluster.readAttributeAcceptedCommandList(with: MTRReadParams())
    _ = cluster.readAttributeActiveMessageIDs(with: MTRReadParams())
    _ = cluster.readAttributeAttributeList(with: MTRReadParams())
    _ = cluster.readAttributeClusterRevision(with: MTRReadParams())
    _ = cluster.readAttributeFeatureMap(with: MTRReadParams())
    _ = cluster.readAttributeGeneratedCommandList(with: MTRReadParams())
    _ = cluster.readAttributeMessages(with: MTRReadParams())
}

func testClusterMicrowaveOvenControlWave11Init() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    _ = MTRClusterMicrowaveOvenControl(device: device, endpointID: n(1), queue: DispatchQueue.global())
}

func testClusterMicrowaveOvenControlWave11Command() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    guard let cluster = MTRClusterMicrowaveOvenControl(device: device, endpointID: n(1), queue: DispatchQueue.global()) else {
        mtrRequire(false, "MTRClusterMicrowaveOvenControl init")
        return
    }
    cluster.addMoreTime(with: MTRMicrowaveOvenControlClusterAddMoreTimeParams(), expectedValues: [], expectedValueInterval: n(1), completion: { err in mtrExpectInvalidState(err) })
    cluster.setCookingParametersWithExpectedValues([], expectedValueInterval: n(1), completion: { err in mtrExpectInvalidState(err) })
    cluster.setCookingParametersWith(MTRMicrowaveOvenControlClusterSetCookingParametersParams(), expectedValues: [], expectedValueInterval: n(1), completion: { err in mtrExpectInvalidState(err) })
}

func testClusterMicrowaveOvenControlWave11Cache() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    guard let cluster = MTRClusterMicrowaveOvenControl(device: device, endpointID: n(1), queue: DispatchQueue.global()) else {
        mtrRequire(false, "MTRClusterMicrowaveOvenControl init")
        return
    }
    _ = cluster.readAttributeAcceptedCommandList(with: MTRReadParams())
    _ = cluster.readAttributeAttributeList(with: MTRReadParams())
    _ = cluster.readAttributeClusterRevision(with: MTRReadParams())
    _ = cluster.readAttributeCookTime(with: MTRReadParams())
    _ = cluster.readAttributeFeatureMap(with: MTRReadParams())
    _ = cluster.readAttributeGeneratedCommandList(with: MTRReadParams())
    _ = cluster.readAttributeMaxCookTime(with: MTRReadParams())
    _ = cluster.readAttributeMaxPower(with: MTRReadParams())
    _ = cluster.readAttributeMinPower(with: MTRReadParams())
    _ = cluster.readAttributePowerSetting(with: MTRReadParams())
    _ = cluster.readAttributePowerStep(with: MTRReadParams())
    _ = cluster.readAttributeWattRating(with: MTRReadParams())
}

func testClusterMicrowaveOvenModeWave11Init() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    _ = MTRClusterMicrowaveOvenMode(device: device, endpointID: n(1), queue: DispatchQueue.global())
}

func testClusterMicrowaveOvenModeWave11Cache() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    guard let cluster = MTRClusterMicrowaveOvenMode(device: device, endpointID: n(1), queue: DispatchQueue.global()) else {
        mtrRequire(false, "MTRClusterMicrowaveOvenMode init")
        return
    }
    _ = cluster.readAttributeAcceptedCommandList(with: MTRReadParams())
    _ = cluster.readAttributeAttributeList(with: MTRReadParams())
    _ = cluster.readAttributeClusterRevision(with: MTRReadParams())
    _ = cluster.readAttributeCurrentMode(with: MTRReadParams())
    _ = cluster.readAttributeFeatureMap(with: MTRReadParams())
    _ = cluster.readAttributeGeneratedCommandList(with: MTRReadParams())
    _ = cluster.readAttributeSupportedModes(with: MTRReadParams())
}

func testClusterNitrogenDioxideConcentrationMeasurementWave11Init() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    _ = MTRClusterNitrogenDioxideConcentrationMeasurement(device: device, endpointID: n(1), queue: DispatchQueue.global())
}

func testClusterNitrogenDioxideConcentrationMeasurementWave11Cache() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    guard let cluster = MTRClusterNitrogenDioxideConcentrationMeasurement(device: device, endpointID: n(1), queue: DispatchQueue.global()) else {
        mtrRequire(false, "MTRClusterNitrogenDioxideConcentrationMeasurement init")
        return
    }
    _ = cluster.readAttributeAcceptedCommandList(with: MTRReadParams())
    _ = cluster.readAttributeAttributeList(with: MTRReadParams())
    _ = cluster.readAttributeAverageMeasuredValueWindow(with: MTRReadParams())
    _ = cluster.readAttributeAverageMeasuredValue(with: MTRReadParams())
    _ = cluster.readAttributeClusterRevision(with: MTRReadParams())
    _ = cluster.readAttributeFeatureMap(with: MTRReadParams())
    _ = cluster.readAttributeGeneratedCommandList(with: MTRReadParams())
    _ = cluster.readAttributeLevelValue(with: MTRReadParams())
    _ = cluster.readAttributeMaxMeasuredValue(with: MTRReadParams())
    _ = cluster.readAttributeMeasuredValue(with: MTRReadParams())
    _ = cluster.readAttributeMeasurementMedium(with: MTRReadParams())
    _ = cluster.readAttributeMeasurementUnit(with: MTRReadParams())
    _ = cluster.readAttributeMinMeasuredValue(with: MTRReadParams())
    _ = cluster.readAttributePeakMeasuredValueWindow(with: MTRReadParams())
    _ = cluster.readAttributePeakMeasuredValue(with: MTRReadParams())
    _ = cluster.readAttributeUncertainty(with: MTRReadParams())
}

func testClusterOTASoftwareUpdateProviderWave11Init() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    _ = MTRClusterOTASoftwareUpdateProvider(device: device, endpointID: n(1), queue: DispatchQueue.global())
}

func testClusterOTASoftwareUpdateProviderWave11Command() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    guard let cluster = MTRClusterOTASoftwareUpdateProvider(device: device, endpointID: n(1), queue: DispatchQueue.global()) else {
        mtrRequire(false, "MTRClusterOTASoftwareUpdateProvider init")
        return
    }
    cluster.applyUpdateRequest(with: MTROTASoftwareUpdateProviderClusterApplyUpdateRequestParams(), expectedValues: [], expectedValueInterval: n(1), completion: { _, err in mtrExpectInvalidState(err) })
    cluster.notifyUpdateApplied(with: MTROTASoftwareUpdateProviderClusterNotifyUpdateAppliedParams(), expectedValues: [], expectedValueInterval: n(1), completion: { err in mtrExpectInvalidState(err) })
    cluster.queryImage(with: MTROTASoftwareUpdateProviderClusterQueryImageParams(), expectedValues: [], expectedValueInterval: n(1), completion: { _, err in mtrExpectInvalidState(err) })
}

func testClusterOTASoftwareUpdateProviderWave11Cache() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    guard let cluster = MTRClusterOTASoftwareUpdateProvider(device: device, endpointID: n(1), queue: DispatchQueue.global()) else {
        mtrRequire(false, "MTRClusterOTASoftwareUpdateProvider init")
        return
    }
    _ = cluster.readAttributeAcceptedCommandList(with: MTRReadParams())
    _ = cluster.readAttributeAttributeList(with: MTRReadParams())
    _ = cluster.readAttributeClusterRevision(with: MTRReadParams())
    _ = cluster.readAttributeFeatureMap(with: MTRReadParams())
    _ = cluster.readAttributeGeneratedCommandList(with: MTRReadParams())
}

func testClusterOTASoftwareUpdateRequestorWave11Init() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    _ = MTRClusterOTASoftwareUpdateRequestor(device: device, endpointID: n(1), queue: DispatchQueue.global())
}

func testClusterOTASoftwareUpdateRequestorWave11Command() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    guard let cluster = MTRClusterOTASoftwareUpdateRequestor(device: device, endpointID: n(1), queue: DispatchQueue.global()) else {
        mtrRequire(false, "MTRClusterOTASoftwareUpdateRequestor init")
        return
    }
    cluster.announceOTAProvider(with: MTROTASoftwareUpdateRequestorClusterAnnounceOTAProviderParams(), expectedValues: [], expectedValueInterval: n(1), completion: { err in mtrExpectInvalidState(err) })
}

func testClusterOTASoftwareUpdateRequestorWave11Cache() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    guard let cluster = MTRClusterOTASoftwareUpdateRequestor(device: device, endpointID: n(1), queue: DispatchQueue.global()) else {
        mtrRequire(false, "MTRClusterOTASoftwareUpdateRequestor init")
        return
    }
    _ = cluster.readAttributeAcceptedCommandList(with: MTRReadParams())
    _ = cluster.readAttributeAttributeList(with: MTRReadParams())
    _ = cluster.readAttributeClusterRevision(with: MTRReadParams())
    _ = cluster.readAttributeDefaultOTAProviders(with: MTRReadParams())
    _ = cluster.readAttributeFeatureMap(with: MTRReadParams())
    _ = cluster.readAttributeGeneratedCommandList(with: MTRReadParams())
    _ = cluster.readAttributeUpdatePossible(with: MTRReadParams())
    _ = cluster.readAttributeUpdateStateProgress(with: MTRReadParams())
    _ = cluster.readAttributeUpdateState(with: MTRReadParams())
    cluster.writeAttributeDefaultOTAProviders(withValue: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1)), expectedValueInterval: n(1))
    cluster.writeAttributeDefaultOTAProviders(withValue: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1)), expectedValueInterval: n(1), params: MTRWriteParams())
    let probe = MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(7))
    cluster.writeAttributeDefaultOTAProviders(withValue: probe, expectedValueInterval: n(1))
    let cached = cluster.readAttributeDefaultOTAProviders(with: nil)
    mtrRequire(cached != nil, "expected-value cache round-trip")
}

func testClusterOnOffSwitchConfigurationWave11Init() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    _ = MTRClusterOnOffSwitchConfiguration(device: device, endpoint: 1, queue: DispatchQueue.global())
    _ = MTRClusterOnOffSwitchConfiguration(device: device, endpointID: n(1), queue: DispatchQueue.global())
}

func testClusterOnOffSwitchConfigurationWave11Cache() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    guard let cluster = MTRClusterOnOffSwitchConfiguration(device: device, endpointID: n(1), queue: DispatchQueue.global()) else {
        mtrRequire(false, "MTRClusterOnOffSwitchConfiguration init")
        return
    }
    _ = cluster.readAttributeAcceptedCommandList(with: MTRReadParams())
    _ = cluster.readAttributeAttributeList(with: MTRReadParams())
    _ = cluster.readAttributeClusterRevision(with: MTRReadParams())
    _ = cluster.readAttributeFeatureMap(with: MTRReadParams())
    _ = cluster.readAttributeGeneratedCommandList(with: MTRReadParams())
    _ = cluster.readAttributeSwitchActions(with: MTRReadParams())
    _ = cluster.readAttributeSwitchType(with: MTRReadParams())
    cluster.writeAttributeSwitchActions(withValue: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1)), expectedValueInterval: n(1))
    cluster.writeAttributeSwitchActions(withValue: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1)), expectedValueInterval: n(1), params: MTRWriteParams())
    let probe = MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(7))
    cluster.writeAttributeSwitchActions(withValue: probe, expectedValueInterval: n(1))
    let cached = cluster.readAttributeSwitchActions(with: nil)
    mtrRequire(cached != nil, "expected-value cache round-trip")
}

func testClusterOperationalStateWave11Init() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    _ = MTRClusterOperationalState(device: device, endpointID: n(1), queue: DispatchQueue.global())
}

func testClusterOperationalStateWave11Command() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    guard let cluster = MTRClusterOperationalState(device: device, endpointID: n(1), queue: DispatchQueue.global()) else {
        mtrRequire(false, "MTRClusterOperationalState init")
        return
    }
    cluster.pause(withExpectedValues: [], expectedValueInterval: n(1), completion: { _, err in mtrExpectInvalidState(err) })
    cluster.pause(with: MTROperationalStateClusterPauseParams(), expectedValues: [], expectedValueInterval: n(1), completion: { _, err in mtrExpectInvalidState(err) })
    cluster.resume(withExpectedValues: [], expectedValueInterval: n(1), completion: { _, err in mtrExpectInvalidState(err) })
    cluster.resume(with: MTROperationalStateClusterResumeParams(), expectedValues: [], expectedValueInterval: n(1), completion: { _, err in mtrExpectInvalidState(err) })
    cluster.start(withExpectedValues: [], expectedValueInterval: n(1), completion: { _, err in mtrExpectInvalidState(err) })
    cluster.start(with: MTROperationalStateClusterStartParams(), expectedValues: [], expectedValueInterval: n(1), completion: { _, err in mtrExpectInvalidState(err) })
    cluster.stop(withExpectedValues: [], expectedValueInterval: n(1), completion: { _, err in mtrExpectInvalidState(err) })
    cluster.stop(with: MTROperationalStateClusterStopParams(), expectedValues: [], expectedValueInterval: n(1), completion: { _, err in mtrExpectInvalidState(err) })
}

func testClusterOperationalStateWave11Cache() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    guard let cluster = MTRClusterOperationalState(device: device, endpointID: n(1), queue: DispatchQueue.global()) else {
        mtrRequire(false, "MTRClusterOperationalState init")
        return
    }
    _ = cluster.readAttributeAcceptedCommandList(with: MTRReadParams())
    _ = cluster.readAttributeAttributeList(with: MTRReadParams())
    _ = cluster.readAttributeClusterRevision(with: MTRReadParams())
    _ = cluster.readAttributeCountdownTime(with: MTRReadParams())
    _ = cluster.readAttributeCurrentPhase(with: MTRReadParams())
    _ = cluster.readAttributeFeatureMap(with: MTRReadParams())
    _ = cluster.readAttributeGeneratedCommandList(with: MTRReadParams())
    _ = cluster.readAttributeOperationalError(with: MTRReadParams())
    _ = cluster.readAttributeOperationalStateList(with: MTRReadParams())
    _ = cluster.readAttributeOperationalState(with: MTRReadParams())
    _ = cluster.readAttributePhaseList(with: MTRReadParams())
}

func testClusterOtaSoftwareUpdateProviderWave11Init() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    _ = MTRClusterOtaSoftwareUpdateProvider(device: device, endpoint: 1, queue: DispatchQueue.global())
    _ = MTRClusterOtaSoftwareUpdateProvider(device: device, endpointID: n(1), queue: DispatchQueue.global())
}

func testClusterOtaSoftwareUpdateProviderWave11Command() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    guard let cluster = MTRClusterOtaSoftwareUpdateProvider(device: device, endpointID: n(1), queue: DispatchQueue.global()) else {
        mtrRequire(false, "MTRClusterOtaSoftwareUpdateProvider init")
        return
    }
    cluster.applyUpdateRequest(with: MTROtaSoftwareUpdateProviderClusterApplyUpdateRequestParams(), expectedValues: [], expectedValueInterval: n(1), completionHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.notifyUpdateApplied(with: MTROtaSoftwareUpdateProviderClusterNotifyUpdateAppliedParams(), expectedValues: [], expectedValueInterval: n(1), completionHandler: { err in mtrExpectInvalidState(err) })
    cluster.queryImage(with: MTROtaSoftwareUpdateProviderClusterQueryImageParams(), expectedValues: [], expectedValueInterval: n(1), completionHandler: { _, err in mtrExpectInvalidState(err) })
}

func testClusterOtaSoftwareUpdateRequestorWave11Init() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    _ = MTRClusterOtaSoftwareUpdateRequestor(device: device, endpoint: 1, queue: DispatchQueue.global())
    _ = MTRClusterOtaSoftwareUpdateRequestor(device: device, endpointID: n(1), queue: DispatchQueue.global())
}

func testClusterOtaSoftwareUpdateRequestorWave11Command() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    guard let cluster = MTRClusterOtaSoftwareUpdateRequestor(device: device, endpointID: n(1), queue: DispatchQueue.global()) else {
        mtrRequire(false, "MTRClusterOtaSoftwareUpdateRequestor init")
        return
    }
    cluster.announceOtaProvider(with: MTROtaSoftwareUpdateRequestorClusterAnnounceOtaProviderParams(), expectedValues: [], expectedValueInterval: n(1), completionHandler: { err in mtrExpectInvalidState(err) })
}

func testClusterOtaSoftwareUpdateRequestorWave11Cache() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    guard let cluster = MTRClusterOtaSoftwareUpdateRequestor(device: device, endpointID: n(1), queue: DispatchQueue.global()) else {
        mtrRequire(false, "MTRClusterOtaSoftwareUpdateRequestor init")
        return
    }
    _ = cluster.readAttributeDefaultOtaProviders(with: MTRReadParams())
    cluster.writeAttributeDefaultOtaProviders(withValue: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1)), expectedValueInterval: n(1))
    cluster.writeAttributeDefaultOtaProviders(withValue: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1)), expectedValueInterval: n(1), params: MTRWriteParams())
    let probe = MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(7))
    cluster.writeAttributeDefaultOtaProviders(withValue: probe, expectedValueInterval: n(1))
    let cached = cluster.readAttributeDefaultOtaProviders(with: nil)
    _ = cached
}

func testClusterOvenCavityOperationalStateWave11Init() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    _ = MTRClusterOvenCavityOperationalState(device: device, endpointID: n(1), queue: DispatchQueue.global())
}

func testClusterOvenCavityOperationalStateWave11Command() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    guard let cluster = MTRClusterOvenCavityOperationalState(device: device, endpointID: n(1), queue: DispatchQueue.global()) else {
        mtrRequire(false, "MTRClusterOvenCavityOperationalState init")
        return
    }
    cluster.start(withExpectedValues: [], expectedValueInterval: n(1), completion: { _, err in mtrExpectInvalidState(err) })
    cluster.start(with: MTROvenCavityOperationalStateClusterStartParams(), expectedValues: [], expectedValueInterval: n(1), completion: { _, err in mtrExpectInvalidState(err) })
    cluster.stop(withExpectedValues: [], expectedValueInterval: n(1), completion: { _, err in mtrExpectInvalidState(err) })
    cluster.stop(with: MTROvenCavityOperationalStateClusterStopParams(), expectedValues: [], expectedValueInterval: n(1), completion: { _, err in mtrExpectInvalidState(err) })
}

func testClusterOvenCavityOperationalStateWave11Cache() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    guard let cluster = MTRClusterOvenCavityOperationalState(device: device, endpointID: n(1), queue: DispatchQueue.global()) else {
        mtrRequire(false, "MTRClusterOvenCavityOperationalState init")
        return
    }
    _ = cluster.readAttributeAcceptedCommandList(with: MTRReadParams())
    _ = cluster.readAttributeAttributeList(with: MTRReadParams())
    _ = cluster.readAttributeClusterRevision(with: MTRReadParams())
    _ = cluster.readAttributeCountdownTime(with: MTRReadParams())
    _ = cluster.readAttributeCurrentPhase(with: MTRReadParams())
    _ = cluster.readAttributeFeatureMap(with: MTRReadParams())
    _ = cluster.readAttributeGeneratedCommandList(with: MTRReadParams())
    _ = cluster.readAttributeOperationalError(with: MTRReadParams())
    _ = cluster.readAttributeOperationalStateList(with: MTRReadParams())
    _ = cluster.readAttributeOperationalState(with: MTRReadParams())
    _ = cluster.readAttributePhaseList(with: MTRReadParams())
}

func testClusterOvenModeWave11Init() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    _ = MTRClusterOvenMode(device: device, endpointID: n(1), queue: DispatchQueue.global())
}

func testClusterOvenModeWave11Command() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    guard let cluster = MTRClusterOvenMode(device: device, endpointID: n(1), queue: DispatchQueue.global()) else {
        mtrRequire(false, "MTRClusterOvenMode init")
        return
    }
    cluster.changeToMode(with: MTROvenModeClusterChangeToModeParams(), expectedValues: [], expectedValueInterval: n(1), completion: { _, err in mtrExpectInvalidState(err) })
}

func testClusterOvenModeWave11Cache() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    guard let cluster = MTRClusterOvenMode(device: device, endpointID: n(1), queue: DispatchQueue.global()) else {
        mtrRequire(false, "MTRClusterOvenMode init")
        return
    }
    _ = cluster.readAttributeAcceptedCommandList(with: MTRReadParams())
    _ = cluster.readAttributeAttributeList(with: MTRReadParams())
    _ = cluster.readAttributeClusterRevision(with: MTRReadParams())
    _ = cluster.readAttributeCurrentMode(with: MTRReadParams())
    _ = cluster.readAttributeFeatureMap(with: MTRReadParams())
    _ = cluster.readAttributeGeneratedCommandList(with: MTRReadParams())
    _ = cluster.readAttributeSupportedModes(with: MTRReadParams())
}

func testClusterOzoneConcentrationMeasurementWave11Init() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    _ = MTRClusterOzoneConcentrationMeasurement(device: device, endpointID: n(1), queue: DispatchQueue.global())
}

func testClusterOzoneConcentrationMeasurementWave11Cache() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    guard let cluster = MTRClusterOzoneConcentrationMeasurement(device: device, endpointID: n(1), queue: DispatchQueue.global()) else {
        mtrRequire(false, "MTRClusterOzoneConcentrationMeasurement init")
        return
    }
    _ = cluster.readAttributeAcceptedCommandList(with: MTRReadParams())
    _ = cluster.readAttributeAttributeList(with: MTRReadParams())
    _ = cluster.readAttributeAverageMeasuredValueWindow(with: MTRReadParams())
    _ = cluster.readAttributeAverageMeasuredValue(with: MTRReadParams())
    _ = cluster.readAttributeClusterRevision(with: MTRReadParams())
    _ = cluster.readAttributeFeatureMap(with: MTRReadParams())
    _ = cluster.readAttributeGeneratedCommandList(with: MTRReadParams())
    _ = cluster.readAttributeLevelValue(with: MTRReadParams())
    _ = cluster.readAttributeMaxMeasuredValue(with: MTRReadParams())
    _ = cluster.readAttributeMeasuredValue(with: MTRReadParams())
    _ = cluster.readAttributeMeasurementMedium(with: MTRReadParams())
    _ = cluster.readAttributeMeasurementUnit(with: MTRReadParams())
    _ = cluster.readAttributeMinMeasuredValue(with: MTRReadParams())
    _ = cluster.readAttributePeakMeasuredValueWindow(with: MTRReadParams())
    _ = cluster.readAttributePeakMeasuredValue(with: MTRReadParams())
    _ = cluster.readAttributeUncertainty(with: MTRReadParams())
}

func testClusterPM10ConcentrationMeasurementWave11Init() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    _ = MTRClusterPM10ConcentrationMeasurement(device: device, endpointID: n(1), queue: DispatchQueue.global())
}

func testClusterPM10ConcentrationMeasurementWave11Cache() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    guard let cluster = MTRClusterPM10ConcentrationMeasurement(device: device, endpointID: n(1), queue: DispatchQueue.global()) else {
        mtrRequire(false, "MTRClusterPM10ConcentrationMeasurement init")
        return
    }
    _ = cluster.readAttributeAcceptedCommandList(with: MTRReadParams())
    _ = cluster.readAttributeAttributeList(with: MTRReadParams())
    _ = cluster.readAttributeAverageMeasuredValueWindow(with: MTRReadParams())
    _ = cluster.readAttributeAverageMeasuredValue(with: MTRReadParams())
    _ = cluster.readAttributeClusterRevision(with: MTRReadParams())
    _ = cluster.readAttributeFeatureMap(with: MTRReadParams())
    _ = cluster.readAttributeGeneratedCommandList(with: MTRReadParams())
    _ = cluster.readAttributeLevelValue(with: MTRReadParams())
    _ = cluster.readAttributeMaxMeasuredValue(with: MTRReadParams())
    _ = cluster.readAttributeMeasuredValue(with: MTRReadParams())
    _ = cluster.readAttributeMeasurementMedium(with: MTRReadParams())
    _ = cluster.readAttributeMeasurementUnit(with: MTRReadParams())
    _ = cluster.readAttributeMinMeasuredValue(with: MTRReadParams())
    _ = cluster.readAttributePeakMeasuredValueWindow(with: MTRReadParams())
    _ = cluster.readAttributePeakMeasuredValue(with: MTRReadParams())
    _ = cluster.readAttributeUncertainty(with: MTRReadParams())
}

func testClusterPM1ConcentrationMeasurementWave11Init() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    _ = MTRClusterPM1ConcentrationMeasurement(device: device, endpointID: n(1), queue: DispatchQueue.global())
}

func testClusterPM1ConcentrationMeasurementWave11Cache() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    guard let cluster = MTRClusterPM1ConcentrationMeasurement(device: device, endpointID: n(1), queue: DispatchQueue.global()) else {
        mtrRequire(false, "MTRClusterPM1ConcentrationMeasurement init")
        return
    }
    _ = cluster.readAttributeAcceptedCommandList(with: MTRReadParams())
    _ = cluster.readAttributeAttributeList(with: MTRReadParams())
    _ = cluster.readAttributeAverageMeasuredValueWindow(with: MTRReadParams())
    _ = cluster.readAttributeAverageMeasuredValue(with: MTRReadParams())
    _ = cluster.readAttributeClusterRevision(with: MTRReadParams())
    _ = cluster.readAttributeFeatureMap(with: MTRReadParams())
    _ = cluster.readAttributeGeneratedCommandList(with: MTRReadParams())
    _ = cluster.readAttributeLevelValue(with: MTRReadParams())
    _ = cluster.readAttributeMaxMeasuredValue(with: MTRReadParams())
    _ = cluster.readAttributeMeasuredValue(with: MTRReadParams())
    _ = cluster.readAttributeMeasurementMedium(with: MTRReadParams())
    _ = cluster.readAttributeMeasurementUnit(with: MTRReadParams())
    _ = cluster.readAttributeMinMeasuredValue(with: MTRReadParams())
    _ = cluster.readAttributePeakMeasuredValueWindow(with: MTRReadParams())
    _ = cluster.readAttributePeakMeasuredValue(with: MTRReadParams())
    _ = cluster.readAttributeUncertainty(with: MTRReadParams())
}

func testClusterPM25ConcentrationMeasurementWave11Init() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    _ = MTRClusterPM25ConcentrationMeasurement(device: device, endpointID: n(1), queue: DispatchQueue.global())
}

func testClusterPM25ConcentrationMeasurementWave11Cache() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    guard let cluster = MTRClusterPM25ConcentrationMeasurement(device: device, endpointID: n(1), queue: DispatchQueue.global()) else {
        mtrRequire(false, "MTRClusterPM25ConcentrationMeasurement init")
        return
    }
    _ = cluster.readAttributeAcceptedCommandList(with: MTRReadParams())
    _ = cluster.readAttributeAttributeList(with: MTRReadParams())
    _ = cluster.readAttributeAverageMeasuredValueWindow(with: MTRReadParams())
    _ = cluster.readAttributeAverageMeasuredValue(with: MTRReadParams())
    _ = cluster.readAttributeClusterRevision(with: MTRReadParams())
    _ = cluster.readAttributeFeatureMap(with: MTRReadParams())
    _ = cluster.readAttributeGeneratedCommandList(with: MTRReadParams())
    _ = cluster.readAttributeLevelValue(with: MTRReadParams())
    _ = cluster.readAttributeMaxMeasuredValue(with: MTRReadParams())
    _ = cluster.readAttributeMeasuredValue(with: MTRReadParams())
    _ = cluster.readAttributeMeasurementMedium(with: MTRReadParams())
    _ = cluster.readAttributeMeasurementUnit(with: MTRReadParams())
    _ = cluster.readAttributeMinMeasuredValue(with: MTRReadParams())
    _ = cluster.readAttributePeakMeasuredValueWindow(with: MTRReadParams())
    _ = cluster.readAttributePeakMeasuredValue(with: MTRReadParams())
    _ = cluster.readAttributeUncertainty(with: MTRReadParams())
}

func testClusterPowerSourceWave11Init() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    _ = MTRClusterPowerSource(device: device, endpoint: 1, queue: DispatchQueue.global())
    _ = MTRClusterPowerSource(device: device, endpointID: n(1), queue: DispatchQueue.global())
}

func testClusterPowerSourceWave11Cache() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    guard let cluster = MTRClusterPowerSource(device: device, endpointID: n(1), queue: DispatchQueue.global()) else {
        mtrRequire(false, "MTRClusterPowerSource init")
        return
    }
    _ = cluster.readAttributeAcceptedCommandList(with: MTRReadParams())
    _ = cluster.readAttributeActiveBatChargeFaults(with: MTRReadParams())
    _ = cluster.readAttributeActiveBatFaults(with: MTRReadParams())
    _ = cluster.readAttributeActiveWiredFaults(with: MTRReadParams())
    _ = cluster.readAttributeAttributeList(with: MTRReadParams())
    _ = cluster.readAttributeBatANSIDesignation(with: MTRReadParams())
    _ = cluster.readAttributeBatApprovedChemistry(with: MTRReadParams())
    _ = cluster.readAttributeBatCapacity(with: MTRReadParams())
    _ = cluster.readAttributeBatChargeLevel(with: MTRReadParams())
    _ = cluster.readAttributeBatChargeState(with: MTRReadParams())
    _ = cluster.readAttributeBatChargingCurrent(with: MTRReadParams())
    _ = cluster.readAttributeBatCommonDesignation(with: MTRReadParams())
    _ = cluster.readAttributeBatFunctionalWhileCharging(with: MTRReadParams())
    _ = cluster.readAttributeBatIECDesignation(with: MTRReadParams())
    _ = cluster.readAttributeBatPercentRemaining(with: MTRReadParams())
    _ = cluster.readAttributeBatPresent(with: MTRReadParams())
    _ = cluster.readAttributeBatQuantity(with: MTRReadParams())
    _ = cluster.readAttributeBatReplaceability(with: MTRReadParams())
    _ = cluster.readAttributeBatReplacementDescription(with: MTRReadParams())
    _ = cluster.readAttributeBatReplacementNeeded(with: MTRReadParams())
    _ = cluster.readAttributeBatTimeRemaining(with: MTRReadParams())
    _ = cluster.readAttributeBatTimeToFullCharge(with: MTRReadParams())
    _ = cluster.readAttributeBatVoltage(with: MTRReadParams())
    _ = cluster.readAttributeClusterRevision(with: MTRReadParams())
    _ = cluster.readAttributeDescription(with: MTRReadParams())
    _ = cluster.readAttributeEndpointList(with: MTRReadParams())
    _ = cluster.readAttributeFeatureMap(with: MTRReadParams())
    _ = cluster.readAttributeGeneratedCommandList(with: MTRReadParams())
    _ = cluster.readAttributeOrder(with: MTRReadParams())
    _ = cluster.readAttributeStatus(with: MTRReadParams())
    _ = cluster.readAttributeWiredAssessedCurrent(with: MTRReadParams())
    _ = cluster.readAttributeWiredAssessedInputFrequency(with: MTRReadParams())
    _ = cluster.readAttributeWiredAssessedInputVoltage(with: MTRReadParams())
    _ = cluster.readAttributeWiredCurrentType(with: MTRReadParams())
    _ = cluster.readAttributeWiredMaximumCurrent(with: MTRReadParams())
    _ = cluster.readAttributeWiredNominalVoltage(with: MTRReadParams())
    _ = cluster.readAttributeWiredPresent(with: MTRReadParams())
}

func testClusterPowerSourceConfigurationWave11Init() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    _ = MTRClusterPowerSourceConfiguration(device: device, endpoint: 1, queue: DispatchQueue.global())
    _ = MTRClusterPowerSourceConfiguration(device: device, endpointID: n(1), queue: DispatchQueue.global())
}

func testClusterPowerSourceConfigurationWave11Cache() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    guard let cluster = MTRClusterPowerSourceConfiguration(device: device, endpointID: n(1), queue: DispatchQueue.global()) else {
        mtrRequire(false, "MTRClusterPowerSourceConfiguration init")
        return
    }
    _ = cluster.readAttributeAcceptedCommandList(with: MTRReadParams())
    _ = cluster.readAttributeAttributeList(with: MTRReadParams())
    _ = cluster.readAttributeClusterRevision(with: MTRReadParams())
    _ = cluster.readAttributeFeatureMap(with: MTRReadParams())
    _ = cluster.readAttributeGeneratedCommandList(with: MTRReadParams())
    _ = cluster.readAttributeSources(with: MTRReadParams())
}

