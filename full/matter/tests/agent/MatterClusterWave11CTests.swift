import Foundation
import Dispatch
import Matter

func testClusterPowerTopologyWave11Init() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    _ = MTRClusterPowerTopology(device: device, endpointID: n(1), queue: DispatchQueue.global())
}

func testClusterPowerTopologyWave11Cache() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    guard let cluster = MTRClusterPowerTopology(device: device, endpointID: n(1), queue: DispatchQueue.global()) else {
        mtrRequire(false, "MTRClusterPowerTopology init")
        return
    }
    _ = cluster.readAttributeAcceptedCommandList(with: MTRReadParams())
    _ = cluster.readAttributeActiveEndpoints(with: MTRReadParams())
    _ = cluster.readAttributeAttributeList(with: MTRReadParams())
    _ = cluster.readAttributeAvailableEndpoints(with: MTRReadParams())
    _ = cluster.readAttributeClusterRevision(with: MTRReadParams())
    _ = cluster.readAttributeFeatureMap(with: MTRReadParams())
    _ = cluster.readAttributeGeneratedCommandList(with: MTRReadParams())
}

func testClusterPumpConfigurationAndControlWave11Init() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    _ = MTRClusterPumpConfigurationAndControl(device: device, endpoint: 1, queue: DispatchQueue.global())
    _ = MTRClusterPumpConfigurationAndControl(device: device, endpointID: n(1), queue: DispatchQueue.global())
}

func testClusterPumpConfigurationAndControlWave11Cache() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    guard let cluster = MTRClusterPumpConfigurationAndControl(device: device, endpointID: n(1), queue: DispatchQueue.global()) else {
        mtrRequire(false, "MTRClusterPumpConfigurationAndControl init")
        return
    }
    _ = cluster.readAttributeAcceptedCommandList(with: MTRReadParams())
    _ = cluster.readAttributeAttributeList(with: MTRReadParams())
    _ = cluster.readAttributeCapacity(with: MTRReadParams())
    _ = cluster.readAttributeClusterRevision(with: MTRReadParams())
    _ = cluster.readAttributeControlMode(with: MTRReadParams())
    _ = cluster.readAttributeEffectiveControlMode(with: MTRReadParams())
    _ = cluster.readAttributeEffectiveOperationMode(with: MTRReadParams())
    _ = cluster.readAttributeFeatureMap(with: MTRReadParams())
    _ = cluster.readAttributeGeneratedCommandList(with: MTRReadParams())
    _ = cluster.readAttributeLifetimeEnergyConsumed(with: MTRReadParams())
    _ = cluster.readAttributeLifetimeRunningHours(with: MTRReadParams())
    _ = cluster.readAttributeMaxCompPressure(with: MTRReadParams())
    _ = cluster.readAttributeMaxConstFlow(with: MTRReadParams())
    _ = cluster.readAttributeMaxConstPressure(with: MTRReadParams())
    _ = cluster.readAttributeMaxConstSpeed(with: MTRReadParams())
    _ = cluster.readAttributeMaxConstTemp(with: MTRReadParams())
    _ = cluster.readAttributeMaxFlow(with: MTRReadParams())
    _ = cluster.readAttributeMaxPressure(with: MTRReadParams())
    _ = cluster.readAttributeMaxSpeed(with: MTRReadParams())
    _ = cluster.readAttributeMinCompPressure(with: MTRReadParams())
    _ = cluster.readAttributeMinConstFlow(with: MTRReadParams())
    _ = cluster.readAttributeMinConstPressure(with: MTRReadParams())
    _ = cluster.readAttributeMinConstSpeed(with: MTRReadParams())
    _ = cluster.readAttributeMinConstTemp(with: MTRReadParams())
    _ = cluster.readAttributeOperationMode(with: MTRReadParams())
    _ = cluster.readAttributePower(with: MTRReadParams())
    _ = cluster.readAttributePumpStatus(with: MTRReadParams())
    _ = cluster.readAttributeSpeed(with: MTRReadParams())
    cluster.writeAttributeControlMode(withValue: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1)), expectedValueInterval: n(1))
    cluster.writeAttributeControlMode(withValue: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1)), expectedValueInterval: n(1), params: MTRWriteParams())
    cluster.writeAttributeLifetimeEnergyConsumed(withValue: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1)), expectedValueInterval: n(1))
    cluster.writeAttributeLifetimeEnergyConsumed(withValue: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1)), expectedValueInterval: n(1), params: MTRWriteParams())
    cluster.writeAttributeLifetimeRunningHours(withValue: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1)), expectedValueInterval: n(1))
    cluster.writeAttributeLifetimeRunningHours(withValue: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1)), expectedValueInterval: n(1), params: MTRWriteParams())
    cluster.writeAttributeOperationMode(withValue: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1)), expectedValueInterval: n(1))
    cluster.writeAttributeOperationMode(withValue: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1)), expectedValueInterval: n(1), params: MTRWriteParams())
    let probe = MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(7))
    cluster.writeAttributeControlMode(withValue: probe, expectedValueInterval: n(1))
    let cached = cluster.readAttributeControlMode(with: nil)
    mtrRequire(cached != nil, "expected-value cache round-trip")
}

func testClusterRVCCleanModeWave11Init() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    _ = MTRClusterRVCCleanMode(device: device, endpointID: n(1), queue: DispatchQueue.global())
}

func testClusterRVCCleanModeWave11Command() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    guard let cluster = MTRClusterRVCCleanMode(device: device, endpointID: n(1), queue: DispatchQueue.global()) else {
        mtrRequire(false, "MTRClusterRVCCleanMode init")
        return
    }
    cluster.changeToMode(with: MTRRVCCleanModeClusterChangeToModeParams(), expectedValues: [], expectedValueInterval: n(1), completion: { _, err in mtrExpectInvalidState(err) })
}

func testClusterRVCCleanModeWave11Cache() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    guard let cluster = MTRClusterRVCCleanMode(device: device, endpointID: n(1), queue: DispatchQueue.global()) else {
        mtrRequire(false, "MTRClusterRVCCleanMode init")
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

func testClusterRVCOperationalStateWave11Init() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    _ = MTRClusterRVCOperationalState(device: device, endpointID: n(1), queue: DispatchQueue.global())
}

func testClusterRVCOperationalStateWave11Command() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    guard let cluster = MTRClusterRVCOperationalState(device: device, endpointID: n(1), queue: DispatchQueue.global()) else {
        mtrRequire(false, "MTRClusterRVCOperationalState init")
        return
    }
    cluster.goHome(withExpectedValues: [], expectedValueInterval: n(1), completion: { _, err in mtrExpectInvalidState(err) })
    cluster.goHome(with: MTRRVCOperationalStateClusterGoHomeParams(), expectedValues: [], expectedValueInterval: n(1), completion: { _, err in mtrExpectInvalidState(err) })
    cluster.pause(withExpectedValues: [], expectedValueInterval: n(1), completion: { _, err in mtrExpectInvalidState(err) })
    cluster.pause(with: MTRRVCOperationalStateClusterPauseParams(), expectedValues: [], expectedValueInterval: n(1), completion: { _, err in mtrExpectInvalidState(err) })
    cluster.resume(withExpectedValues: [], expectedValueInterval: n(1), completion: { _, err in mtrExpectInvalidState(err) })
    cluster.resume(with: MTRRVCOperationalStateClusterResumeParams(), expectedValues: [], expectedValueInterval: n(1), completion: { _, err in mtrExpectInvalidState(err) })
}

func testClusterRVCOperationalStateWave11Cache() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    guard let cluster = MTRClusterRVCOperationalState(device: device, endpointID: n(1), queue: DispatchQueue.global()) else {
        mtrRequire(false, "MTRClusterRVCOperationalState init")
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

func testClusterRVCRunModeWave11Init() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    _ = MTRClusterRVCRunMode(device: device, endpointID: n(1), queue: DispatchQueue.global())
}

func testClusterRVCRunModeWave11Command() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    guard let cluster = MTRClusterRVCRunMode(device: device, endpointID: n(1), queue: DispatchQueue.global()) else {
        mtrRequire(false, "MTRClusterRVCRunMode init")
        return
    }
    cluster.changeToMode(with: MTRRVCRunModeClusterChangeToModeParams(), expectedValues: [], expectedValueInterval: n(1), completion: { _, err in mtrExpectInvalidState(err) })
}

func testClusterRVCRunModeWave11Cache() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    guard let cluster = MTRClusterRVCRunMode(device: device, endpointID: n(1), queue: DispatchQueue.global()) else {
        mtrRequire(false, "MTRClusterRVCRunMode init")
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

func testClusterRadonConcentrationMeasurementWave11Init() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    _ = MTRClusterRadonConcentrationMeasurement(device: device, endpointID: n(1), queue: DispatchQueue.global())
}

func testClusterRadonConcentrationMeasurementWave11Cache() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    guard let cluster = MTRClusterRadonConcentrationMeasurement(device: device, endpointID: n(1), queue: DispatchQueue.global()) else {
        mtrRequire(false, "MTRClusterRadonConcentrationMeasurement init")
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

func testClusterRefrigeratorAlarmWave11Init() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    _ = MTRClusterRefrigeratorAlarm(device: device, endpointID: n(1), queue: DispatchQueue.global())
}

func testClusterRefrigeratorAlarmWave11Cache() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    guard let cluster = MTRClusterRefrigeratorAlarm(device: device, endpointID: n(1), queue: DispatchQueue.global()) else {
        mtrRequire(false, "MTRClusterRefrigeratorAlarm init")
        return
    }
    _ = cluster.readAttributeAcceptedCommandList(with: MTRReadParams())
    _ = cluster.readAttributeAttributeList(with: MTRReadParams())
    _ = cluster.readAttributeClusterRevision(with: MTRReadParams())
    _ = cluster.readAttributeFeatureMap(with: MTRReadParams())
    _ = cluster.readAttributeGeneratedCommandList(with: MTRReadParams())
    _ = cluster.readAttributeMask(with: MTRReadParams())
    _ = cluster.readAttributeState(with: MTRReadParams())
    _ = cluster.readAttributeSupported(with: MTRReadParams())
}

func testClusterRefrigeratorAndTemperatureControlledCabinetModeWave11Init() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    _ = MTRClusterRefrigeratorAndTemperatureControlledCabinetMode(device: device, endpointID: n(1), queue: DispatchQueue.global())
}

func testClusterRefrigeratorAndTemperatureControlledCabinetModeWave11Command() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    guard let cluster = MTRClusterRefrigeratorAndTemperatureControlledCabinetMode(device: device, endpointID: n(1), queue: DispatchQueue.global()) else {
        mtrRequire(false, "MTRClusterRefrigeratorAndTemperatureControlledCabinetMode init")
        return
    }
    cluster.changeToMode(with: MTRRefrigeratorAndTemperatureControlledCabinetModeClusterChangeToModeParams(), expectedValues: [], expectedValueInterval: n(1), completion: { _, err in mtrExpectInvalidState(err) })
}

func testClusterRefrigeratorAndTemperatureControlledCabinetModeWave11Cache() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    guard let cluster = MTRClusterRefrigeratorAndTemperatureControlledCabinetMode(device: device, endpointID: n(1), queue: DispatchQueue.global()) else {
        mtrRequire(false, "MTRClusterRefrigeratorAndTemperatureControlledCabinetMode init")
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

func testClusterServiceAreaWave11Init() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    _ = MTRClusterServiceArea(device: device, endpointID: n(1), queue: DispatchQueue.global())
}

func testClusterServiceAreaWave11Command() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    guard let cluster = MTRClusterServiceArea(device: device, endpointID: n(1), queue: DispatchQueue.global()) else {
        mtrRequire(false, "MTRClusterServiceArea init")
        return
    }
    cluster.selectAreas(with: MTRServiceAreaClusterSelectAreasParams(), expectedValues: [], expectedValueInterval: n(1), completion: { _, err in mtrExpectInvalidState(err) })
    cluster.skip(with: MTRServiceAreaClusterSkipAreaParams(), expectedValues: [], expectedValueInterval: n(1), completion: { _, err in mtrExpectInvalidState(err) })
}

func testClusterServiceAreaWave11Cache() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    guard let cluster = MTRClusterServiceArea(device: device, endpointID: n(1), queue: DispatchQueue.global()) else {
        mtrRequire(false, "MTRClusterServiceArea init")
        return
    }
    _ = cluster.readAttributeAcceptedCommandList(with: MTRReadParams())
    _ = cluster.readAttributeAttributeList(with: MTRReadParams())
    _ = cluster.readAttributeClusterRevision(with: MTRReadParams())
    _ = cluster.readAttributeCurrentArea(with: MTRReadParams())
    _ = cluster.readAttributeEstimatedEndTime(with: MTRReadParams())
    _ = cluster.readAttributeFeatureMap(with: MTRReadParams())
    _ = cluster.readAttributeGeneratedCommandList(with: MTRReadParams())
    _ = cluster.readAttributeProgress(with: MTRReadParams())
    _ = cluster.readAttributeSelectedAreas(with: MTRReadParams())
    _ = cluster.readAttributeSupportedAreas(with: MTRReadParams())
    _ = cluster.readAttributeSupportedMaps(with: MTRReadParams())
}

func testClusterTargetNavigatorWave11Init() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    _ = MTRClusterTargetNavigator(device: device, endpoint: 1, queue: DispatchQueue.global())
    _ = MTRClusterTargetNavigator(device: device, endpointID: n(1), queue: DispatchQueue.global())
}

func testClusterTargetNavigatorWave11Command() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    guard let cluster = MTRClusterTargetNavigator(device: device, endpointID: n(1), queue: DispatchQueue.global()) else {
        mtrRequire(false, "MTRClusterTargetNavigator init")
        return
    }
    cluster.navigateTarget(with: MTRTargetNavigatorClusterNavigateTargetParams(), expectedValues: [], expectedValueInterval: n(1), completion: { _, err in mtrExpectInvalidState(err) })
    cluster.navigateTarget(with: MTRTargetNavigatorClusterNavigateTargetParams(), expectedValues: [], expectedValueInterval: n(1), completionHandler: { _, err in mtrExpectInvalidState(err) })
}

func testClusterTargetNavigatorWave11Cache() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    guard let cluster = MTRClusterTargetNavigator(device: device, endpointID: n(1), queue: DispatchQueue.global()) else {
        mtrRequire(false, "MTRClusterTargetNavigator init")
        return
    }
    _ = cluster.readAttributeAcceptedCommandList(with: MTRReadParams())
    _ = cluster.readAttributeAttributeList(with: MTRReadParams())
    _ = cluster.readAttributeClusterRevision(with: MTRReadParams())
    _ = cluster.readAttributeCurrentTarget(with: MTRReadParams())
    _ = cluster.readAttributeFeatureMap(with: MTRReadParams())
    _ = cluster.readAttributeGeneratedCommandList(with: MTRReadParams())
    _ = cluster.readAttributeTargetList(with: MTRReadParams())
}

func testClusterTemperatureControlWave11Init() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    _ = MTRClusterTemperatureControl(device: device, endpointID: n(1), queue: DispatchQueue.global())
}

func testClusterTemperatureControlWave11Command() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    guard let cluster = MTRClusterTemperatureControl(device: device, endpointID: n(1), queue: DispatchQueue.global()) else {
        mtrRequire(false, "MTRClusterTemperatureControl init")
        return
    }
    cluster.setTemperatureWithExpectedValues([], expectedValueInterval: n(1), completion: { err in mtrExpectInvalidState(err) })
    cluster.setTemperatureWith(MTRTemperatureControlClusterSetTemperatureParams(), expectedValues: [], expectedValueInterval: n(1), completion: { err in mtrExpectInvalidState(err) })
}

func testClusterTemperatureControlWave11Cache() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    guard let cluster = MTRClusterTemperatureControl(device: device, endpointID: n(1), queue: DispatchQueue.global()) else {
        mtrRequire(false, "MTRClusterTemperatureControl init")
        return
    }
    _ = cluster.readAttributeAcceptedCommandList(with: MTRReadParams())
    _ = cluster.readAttributeAttributeList(with: MTRReadParams())
    _ = cluster.readAttributeClusterRevision(with: MTRReadParams())
    _ = cluster.readAttributeFeatureMap(with: MTRReadParams())
    _ = cluster.readAttributeGeneratedCommandList(with: MTRReadParams())
    _ = cluster.readAttributeMaxTemperature(with: MTRReadParams())
    _ = cluster.readAttributeMinTemperature(with: MTRReadParams())
    _ = cluster.readAttributeSelectedTemperatureLevel(with: MTRReadParams())
    _ = cluster.readAttributeStep(with: MTRReadParams())
    _ = cluster.readAttributeSupportedTemperatureLevels(with: MTRReadParams())
    _ = cluster.readAttributeTemperatureSetpoint(with: MTRReadParams())
}

func testClusterTestClusterWave11Init() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    _ = MTRClusterTestCluster(device: device, endpoint: 1, queue: DispatchQueue.global())
    _ = MTRClusterTestCluster(device: device, endpointID: n(1), queue: DispatchQueue.global())
}

func testClusterTestClusterWave11Command() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    guard let cluster = MTRClusterTestCluster(device: device, endpointID: n(1), queue: DispatchQueue.global()) else {
        mtrRequire(false, "MTRClusterTestCluster init")
        return
    }
    cluster.simpleStructEchoRequest(with: MTRTestClusterClusterSimpleStructEchoRequestParams(), expectedValues: [], expectedValueInterval: n(1), completionHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.testAddArguments(with: MTRTestClusterClusterTestAddArgumentsParams(), expectedValues: [], expectedValueInterval: n(1), completionHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.testComplexNullableOptionalRequest(with: MTRTestClusterClusterTestComplexNullableOptionalRequestParams(), expectedValues: [], expectedValueInterval: n(1), completionHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.testEmitTestEventRequest(with: MTRTestClusterClusterTestEmitTestEventRequestParams(), expectedValues: [], expectedValueInterval: n(1), completionHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.testEmitTestFabricScopedEventRequest(with: MTRTestClusterClusterTestEmitTestFabricScopedEventRequestParams(), expectedValues: [], expectedValueInterval: n(1), completionHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.testEnumsRequest(with: MTRTestClusterClusterTestEnumsRequestParams(), expectedValues: [], expectedValueInterval: n(1), completionHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.testListInt8UArgumentRequest(with: MTRTestClusterClusterTestListInt8UArgumentRequestParams(), expectedValues: [], expectedValueInterval: n(1), completionHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.testListInt8UReverseRequest(with: MTRTestClusterClusterTestListInt8UReverseRequestParams(), expectedValues: [], expectedValueInterval: n(1), completionHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.testListNestedStructListArgumentRequest(with: MTRTestClusterClusterTestListNestedStructListArgumentRequestParams(), expectedValues: [], expectedValueInterval: n(1), completionHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.testListStructArgumentRequest(with: MTRTestClusterClusterTestListStructArgumentRequestParams(), expectedValues: [], expectedValueInterval: n(1), completionHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.testNestedStructArgumentRequest(with: MTRTestClusterClusterTestNestedStructArgumentRequestParams(), expectedValues: [], expectedValueInterval: n(1), completionHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.testNestedStructListArgumentRequest(with: MTRTestClusterClusterTestNestedStructListArgumentRequestParams(), expectedValues: [], expectedValueInterval: n(1), completionHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.testNotHandled(withExpectedValues: [], expectedValueInterval: n(1), completionHandler: { err in mtrExpectInvalidState(err) })
    cluster.testNotHandled(with: MTRTestClusterClusterTestNotHandledParams(), expectedValues: [], expectedValueInterval: n(1), completionHandler: { err in mtrExpectInvalidState(err) })
    cluster.testNullableOptionalRequest(withExpectedValues: [], expectedValueInterval: n(1), completionHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.testNullableOptionalRequest(with: MTRTestClusterClusterTestNullableOptionalRequestParams(), expectedValues: [], expectedValueInterval: n(1), completionHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.testSimpleArgumentRequest(with: MTRTestClusterClusterTestSimpleArgumentRequestParams(), expectedValues: [], expectedValueInterval: n(1), completionHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.testSimpleOptionalArgumentRequest(withExpectedValues: [], expectedValueInterval: n(1), completionHandler: { err in mtrExpectInvalidState(err) })
    cluster.testSimpleOptionalArgumentRequest(with: MTRTestClusterClusterTestSimpleOptionalArgumentRequestParams(), expectedValues: [], expectedValueInterval: n(1), completionHandler: { err in mtrExpectInvalidState(err) })
    cluster.testSpecific(withExpectedValues: [], expectedValueInterval: n(1), completionHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.testSpecific(with: MTRTestClusterClusterTestSpecificParams(), expectedValues: [], expectedValueInterval: n(1), completionHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.testStructArgumentRequest(with: MTRTestClusterClusterTestStructArgumentRequestParams(), expectedValues: [], expectedValueInterval: n(1), completionHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.testStructArrayArgumentRequest(with: MTRTestClusterClusterTestStructArrayArgumentRequestParams(), expectedValues: [], expectedValueInterval: n(1), completionHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.testUnknownCommand(withExpectedValues: [], expectedValueInterval: n(1), completionHandler: { err in mtrExpectInvalidState(err) })
    cluster.testUnknownCommand(with: MTRTestClusterClusterTestUnknownCommandParams(), expectedValues: [], expectedValueInterval: n(1), completionHandler: { err in mtrExpectInvalidState(err) })
    cluster.test(withExpectedValues: [], expectedValueInterval: n(1), completionHandler: { err in mtrExpectInvalidState(err) })
    cluster.test(with: MTRTestClusterClusterTestParams(), expectedValues: [], expectedValueInterval: n(1), completionHandler: { err in mtrExpectInvalidState(err) })
    cluster.timedInvokeRequest(withExpectedValues: [], expectedValueInterval: n(1), completionHandler: { err in mtrExpectInvalidState(err) })
    cluster.timedInvokeRequest(with: MTRTestClusterClusterTimedInvokeRequestParams(), expectedValues: [], expectedValueInterval: n(1), completionHandler: { err in mtrExpectInvalidState(err) })
}

func testClusterThreadBorderRouterManagementWave11Init() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    _ = MTRClusterThreadBorderRouterManagement(device: device, endpointID: n(1), queue: DispatchQueue.global())
}

func testClusterThreadBorderRouterManagementWave11Command() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    guard let cluster = MTRClusterThreadBorderRouterManagement(device: device, endpointID: n(1), queue: DispatchQueue.global()) else {
        mtrRequire(false, "MTRClusterThreadBorderRouterManagement init")
        return
    }
    cluster.getActiveDatasetRequest(withExpectedValues: [], expectedValueInterval: n(1), completion: { _, err in mtrExpectInvalidState(err) })
    cluster.getActiveDatasetRequest(with: MTRThreadBorderRouterManagementClusterGetActiveDatasetRequestParams(), expectedValues: [], expectedValueInterval: n(1), completion: { _, err in mtrExpectInvalidState(err) })
    cluster.getPendingDatasetRequest(withExpectedValues: [], expectedValueInterval: n(1), completion: { _, err in mtrExpectInvalidState(err) })
    cluster.getPendingDatasetRequest(with: MTRThreadBorderRouterManagementClusterGetPendingDatasetRequestParams(), expectedValues: [], expectedValueInterval: n(1), completion: { _, err in mtrExpectInvalidState(err) })
    cluster.setActiveDatasetRequestWith(MTRThreadBorderRouterManagementClusterSetActiveDatasetRequestParams(), expectedValues: [], expectedValueInterval: n(1), completion: { err in mtrExpectInvalidState(err) })
    cluster.setPendingDatasetRequestWith(MTRThreadBorderRouterManagementClusterSetPendingDatasetRequestParams(), expectedValues: [], expectedValueInterval: n(1), completion: { err in mtrExpectInvalidState(err) })
}

func testClusterThreadBorderRouterManagementWave11Cache() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    guard let cluster = MTRClusterThreadBorderRouterManagement(device: device, endpointID: n(1), queue: DispatchQueue.global()) else {
        mtrRequire(false, "MTRClusterThreadBorderRouterManagement init")
        return
    }
    _ = cluster.readAttributeAcceptedCommandList(with: MTRReadParams())
    _ = cluster.readAttributeActiveDatasetTimestamp(with: MTRReadParams())
    _ = cluster.readAttributeAttributeList(with: MTRReadParams())
    _ = cluster.readAttributeBorderAgentID(with: MTRReadParams())
    _ = cluster.readAttributeBorderRouterName(with: MTRReadParams())
    _ = cluster.readAttributeClusterRevision(with: MTRReadParams())
    _ = cluster.readAttributeFeatureMap(with: MTRReadParams())
    _ = cluster.readAttributeGeneratedCommandList(with: MTRReadParams())
    _ = cluster.readAttributeInterfaceEnabled(with: MTRReadParams())
    _ = cluster.readAttributePendingDatasetTimestamp(with: MTRReadParams())
    _ = cluster.readAttributeThreadVersion(with: MTRReadParams())
}

func testClusterThreadNetworkDirectoryWave11Init() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    _ = MTRClusterThreadNetworkDirectory(device: device, endpointID: n(1), queue: DispatchQueue.global())
}

func testClusterThreadNetworkDirectoryWave11Command() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    guard let cluster = MTRClusterThreadNetworkDirectory(device: device, endpointID: n(1), queue: DispatchQueue.global()) else {
        mtrRequire(false, "MTRClusterThreadNetworkDirectory init")
        return
    }
    cluster.addNetwork(with: MTRThreadNetworkDirectoryClusterAddNetworkParams(), expectedValues: [], expectedValueInterval: n(1), completion: { err in mtrExpectInvalidState(err) })
    cluster.getOperationalDataset(with: MTRThreadNetworkDirectoryClusterGetOperationalDatasetParams(), expectedValues: [], expectedValueInterval: n(1), completion: { _, err in mtrExpectInvalidState(err) })
    cluster.removeNetwork(with: MTRThreadNetworkDirectoryClusterRemoveNetworkParams(), expectedValues: [], expectedValueInterval: n(1), completion: { err in mtrExpectInvalidState(err) })
}

func testClusterThreadNetworkDirectoryWave11Cache() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    guard let cluster = MTRClusterThreadNetworkDirectory(device: device, endpointID: n(1), queue: DispatchQueue.global()) else {
        mtrRequire(false, "MTRClusterThreadNetworkDirectory init")
        return
    }
    _ = cluster.readAttributeAcceptedCommandList(with: MTRReadParams())
    _ = cluster.readAttributeAttributeList(with: MTRReadParams())
    _ = cluster.readAttributeClusterRevision(with: MTRReadParams())
    _ = cluster.readAttributeFeatureMap(with: MTRReadParams())
    _ = cluster.readAttributeGeneratedCommandList(with: MTRReadParams())
    _ = cluster.readAttributePreferredExtendedPanID(with: MTRReadParams())
    _ = cluster.readAttributeThreadNetworkTableSize(with: MTRReadParams())
    _ = cluster.readAttributeThreadNetworks(with: MTRReadParams())
    cluster.writeAttributePreferredExtendedPanID(withValue: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1)), expectedValueInterval: n(1))
    cluster.writeAttributePreferredExtendedPanID(withValue: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1)), expectedValueInterval: n(1), params: MTRWriteParams())
    let probe = MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(7))
    cluster.writeAttributePreferredExtendedPanID(withValue: probe, expectedValueInterval: n(1))
    let cached = cluster.readAttributePreferredExtendedPanID(with: nil)
    mtrRequire(cached != nil, "expected-value cache round-trip")
}

func testClusterTotalVolatileOrganicCompoundsConcentrationMeasurementWave11Init() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    _ = MTRClusterTotalVolatileOrganicCompoundsConcentrationMeasurement(device: device, endpointID: n(1), queue: DispatchQueue.global())
}

func testClusterTotalVolatileOrganicCompoundsConcentrationMeasurementWave11Cache() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    guard let cluster = MTRClusterTotalVolatileOrganicCompoundsConcentrationMeasurement(device: device, endpointID: n(1), queue: DispatchQueue.global()) else {
        mtrRequire(false, "MTRClusterTotalVolatileOrganicCompoundsConcentrationMeasurement init")
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

func testClusterUnitLocalizationWave11Init() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    _ = MTRClusterUnitLocalization(device: device, endpoint: 1, queue: DispatchQueue.global())
    _ = MTRClusterUnitLocalization(device: device, endpointID: n(1), queue: DispatchQueue.global())
}

func testClusterUnitLocalizationWave11Cache() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    guard let cluster = MTRClusterUnitLocalization(device: device, endpointID: n(1), queue: DispatchQueue.global()) else {
        mtrRequire(false, "MTRClusterUnitLocalization init")
        return
    }
    _ = cluster.readAttributeAcceptedCommandList(with: MTRReadParams())
    _ = cluster.readAttributeAttributeList(with: MTRReadParams())
    _ = cluster.readAttributeClusterRevision(with: MTRReadParams())
    _ = cluster.readAttributeFeatureMap(with: MTRReadParams())
    _ = cluster.readAttributeGeneratedCommandList(with: MTRReadParams())
    _ = cluster.readAttributeTemperatureUnit(with: MTRReadParams())
    cluster.writeAttributeTemperatureUnit(withValue: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1)), expectedValueInterval: n(1))
    cluster.writeAttributeTemperatureUnit(withValue: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1)), expectedValueInterval: n(1), params: MTRWriteParams())
    let probe = MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(7))
    cluster.writeAttributeTemperatureUnit(withValue: probe, expectedValueInterval: n(1))
    let cached = cluster.readAttributeTemperatureUnit(with: nil)
    mtrRequire(cached != nil, "expected-value cache round-trip")
}

func testClusterUnitTestingWave11Command() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    guard let cluster = MTRClusterUnitTesting(device: device, endpointID: n(1), queue: DispatchQueue.global()) else {
        mtrRequire(false, "MTRClusterUnitTesting init")
        return
    }
    cluster.simpleStructEchoRequest(with: MTRUnitTestingClusterSimpleStructEchoRequestParams(), expectedValues: [], expectedValueInterval: n(1), completion: { _, err in mtrExpectInvalidState(err) })
    cluster.testAddArguments(with: MTRUnitTestingClusterTestAddArgumentsParams(), expectedValues: [], expectedValueInterval: n(1), completion: { _, err in mtrExpectInvalidState(err) })
    cluster.testComplexNullableOptionalRequest(with: MTRUnitTestingClusterTestComplexNullableOptionalRequestParams(), expectedValues: [], expectedValueInterval: n(1), completion: { _, err in mtrExpectInvalidState(err) })
    cluster.testEmitTestEventRequest(with: MTRUnitTestingClusterTestEmitTestEventRequestParams(), expectedValues: [], expectedValueInterval: n(1), completion: { _, err in mtrExpectInvalidState(err) })
    cluster.testEmitTestFabricScopedEventRequest(with: MTRUnitTestingClusterTestEmitTestFabricScopedEventRequestParams(), expectedValues: [], expectedValueInterval: n(1), completion: { _, err in mtrExpectInvalidState(err) })
    cluster.testEnumsRequest(with: MTRUnitTestingClusterTestEnumsRequestParams(), expectedValues: [], expectedValueInterval: n(1), completion: { _, err in mtrExpectInvalidState(err) })
    cluster.testListInt8UArgumentRequest(with: MTRUnitTestingClusterTestListInt8UArgumentRequestParams(), expectedValues: [], expectedValueInterval: n(1), completion: { _, err in mtrExpectInvalidState(err) })
    cluster.testListInt8UReverseRequest(with: MTRUnitTestingClusterTestListInt8UReverseRequestParams(), expectedValues: [], expectedValueInterval: n(1), completion: { _, err in mtrExpectInvalidState(err) })
    cluster.testListNestedStructListArgumentRequest(with: MTRUnitTestingClusterTestListNestedStructListArgumentRequestParams(), expectedValues: [], expectedValueInterval: n(1), completion: { _, err in mtrExpectInvalidState(err) })
    cluster.testListStructArgumentRequest(with: MTRUnitTestingClusterTestListStructArgumentRequestParams(), expectedValues: [], expectedValueInterval: n(1), completion: { _, err in mtrExpectInvalidState(err) })
    cluster.testNestedStructArgumentRequest(with: MTRUnitTestingClusterTestNestedStructArgumentRequestParams(), expectedValues: [], expectedValueInterval: n(1), completion: { _, err in mtrExpectInvalidState(err) })
    cluster.testNestedStructListArgumentRequest(with: MTRUnitTestingClusterTestNestedStructListArgumentRequestParams(), expectedValues: [], expectedValueInterval: n(1), completion: { _, err in mtrExpectInvalidState(err) })
    cluster.testNotHandled(withExpectedValues: [], expectedValueInterval: n(1), completion: { err in mtrExpectInvalidState(err) })
    cluster.testNotHandled(with: MTRUnitTestingClusterTestNotHandledParams(), expectedValues: [], expectedValueInterval: n(1), completion: { err in mtrExpectInvalidState(err) })
    cluster.testNullableOptionalRequest(withExpectedValues: [], expectedValueInterval: n(1), completion: { _, err in mtrExpectInvalidState(err) })
    cluster.testNullableOptionalRequest(with: MTRUnitTestingClusterTestNullableOptionalRequestParams(), expectedValues: [], expectedValueInterval: n(1), completion: { _, err in mtrExpectInvalidState(err) })
    cluster.testSimpleArgumentRequest(with: MTRUnitTestingClusterTestSimpleArgumentRequestParams(), expectedValues: [], expectedValueInterval: n(1), completion: { _, err in mtrExpectInvalidState(err) })
    cluster.testSimpleOptionalArgumentRequest(withExpectedValues: [], expectedValueInterval: n(1), completion: { err in mtrExpectInvalidState(err) })
    cluster.testSimpleOptionalArgumentRequest(with: MTRUnitTestingClusterTestSimpleOptionalArgumentRequestParams(), expectedValues: [], expectedValueInterval: n(1), completion: { err in mtrExpectInvalidState(err) })
    cluster.testSpecific(withExpectedValues: [], expectedValueInterval: n(1), completion: { _, err in mtrExpectInvalidState(err) })
    cluster.testSpecific(with: MTRUnitTestingClusterTestSpecificParams(), expectedValues: [], expectedValueInterval: n(1), completion: { _, err in mtrExpectInvalidState(err) })
    cluster.testStructArgumentRequest(with: MTRUnitTestingClusterTestStructArgumentRequestParams(), expectedValues: [], expectedValueInterval: n(1), completion: { _, err in mtrExpectInvalidState(err) })
    cluster.testStructArrayArgumentRequest(with: MTRUnitTestingClusterTestStructArrayArgumentRequestParams(), expectedValues: [], expectedValueInterval: n(1), completion: { _, err in mtrExpectInvalidState(err) })
    cluster.testUnknownCommand(withExpectedValues: [], expectedValueInterval: n(1), completion: { err in mtrExpectInvalidState(err) })
    cluster.testUnknownCommand(with: MTRUnitTestingClusterTestUnknownCommandParams(), expectedValues: [], expectedValueInterval: n(1), completion: { err in mtrExpectInvalidState(err) })
    cluster.test(withExpectedValues: [], expectedValueInterval: n(1), completion: { err in mtrExpectInvalidState(err) })
    cluster.test(with: MTRUnitTestingClusterTestParams(), expectedValues: [], expectedValueInterval: n(1), completion: { err in mtrExpectInvalidState(err) })
    cluster.timedInvokeRequest(withExpectedValues: [], expectedValueInterval: n(1), completion: { err in mtrExpectInvalidState(err) })
    cluster.timedInvokeRequest(with: MTRUnitTestingClusterTimedInvokeRequestParams(), expectedValues: [], expectedValueInterval: n(1), completion: { err in mtrExpectInvalidState(err) })
}

func testClusterUserLabelWave11Init() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    _ = MTRClusterUserLabel(device: device, endpoint: 1, queue: DispatchQueue.global())
    _ = MTRClusterUserLabel(device: device, endpointID: n(1), queue: DispatchQueue.global())
}

func testClusterUserLabelWave11Cache() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    guard let cluster = MTRClusterUserLabel(device: device, endpointID: n(1), queue: DispatchQueue.global()) else {
        mtrRequire(false, "MTRClusterUserLabel init")
        return
    }
    _ = cluster.readAttributeAcceptedCommandList(with: MTRReadParams())
    _ = cluster.readAttributeAttributeList(with: MTRReadParams())
    _ = cluster.readAttributeClusterRevision(with: MTRReadParams())
    _ = cluster.readAttributeFeatureMap(with: MTRReadParams())
    _ = cluster.readAttributeGeneratedCommandList(with: MTRReadParams())
    _ = cluster.readAttributeLabelList(with: MTRReadParams())
    cluster.writeAttributeLabelList(withValue: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1)), expectedValueInterval: n(1))
    cluster.writeAttributeLabelList(withValue: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1)), expectedValueInterval: n(1), params: MTRWriteParams())
    let probe = MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(7))
    cluster.writeAttributeLabelList(withValue: probe, expectedValueInterval: n(1))
    let cached = cluster.readAttributeLabelList(with: nil)
    mtrRequire(cached != nil, "expected-value cache round-trip")
}

func testClusterWakeOnLANWave11Init() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    _ = MTRClusterWakeOnLAN(device: device, endpointID: n(1), queue: DispatchQueue.global())
}

func testClusterWakeOnLANWave11Cache() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    guard let cluster = MTRClusterWakeOnLAN(device: device, endpointID: n(1), queue: DispatchQueue.global()) else {
        mtrRequire(false, "MTRClusterWakeOnLAN init")
        return
    }
    _ = cluster.readAttributeAcceptedCommandList(with: MTRReadParams())
    _ = cluster.readAttributeAttributeList(with: MTRReadParams())
    _ = cluster.readAttributeClusterRevision(with: MTRReadParams())
    _ = cluster.readAttributeFeatureMap(with: MTRReadParams())
    _ = cluster.readAttributeGeneratedCommandList(with: MTRReadParams())
    _ = cluster.readAttributeLinkLocalAddress(with: MTRReadParams())
    _ = cluster.readAttributeMACAddress(with: MTRReadParams())
}

func testClusterWakeOnLanWave11Init() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    _ = MTRClusterWakeOnLan(device: device, endpoint: 1, queue: DispatchQueue.global())
    _ = MTRClusterWakeOnLan(device: device, endpointID: n(1), queue: DispatchQueue.global())
}

func testClusterWaterHeaterManagementWave11Init() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    _ = MTRClusterWaterHeaterManagement(device: device, endpointID: n(1), queue: DispatchQueue.global())
}

func testClusterWaterHeaterManagementWave11Command() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    guard let cluster = MTRClusterWaterHeaterManagement(device: device, endpointID: n(1), queue: DispatchQueue.global()) else {
        mtrRequire(false, "MTRClusterWaterHeaterManagement init")
        return
    }
    cluster.boost(with: MTRWaterHeaterManagementClusterBoostParams(), expectedValues: [], expectedValueInterval: n(1), completion: { err in mtrExpectInvalidState(err) })
    cluster.cancelBoost(withExpectedValues: [], expectedValueInterval: n(1), completion: { err in mtrExpectInvalidState(err) })
    cluster.cancelBoost(with: MTRWaterHeaterManagementClusterCancelBoostParams(), expectedValues: [], expectedValueInterval: n(1), completion: { err in mtrExpectInvalidState(err) })
}

func testClusterWaterHeaterManagementWave11Cache() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    guard let cluster = MTRClusterWaterHeaterManagement(device: device, endpointID: n(1), queue: DispatchQueue.global()) else {
        mtrRequire(false, "MTRClusterWaterHeaterManagement init")
        return
    }
    _ = cluster.readAttributeAcceptedCommandList(with: MTRReadParams())
    _ = cluster.readAttributeAttributeList(with: MTRReadParams())
    _ = cluster.readAttributeBoostState(with: MTRReadParams())
    _ = cluster.readAttributeClusterRevision(with: MTRReadParams())
    _ = cluster.readAttributeEstimatedHeatRequired(with: MTRReadParams())
    _ = cluster.readAttributeFeatureMap(with: MTRReadParams())
    _ = cluster.readAttributeGeneratedCommandList(with: MTRReadParams())
    _ = cluster.readAttributeHeatDemand(with: MTRReadParams())
    _ = cluster.readAttributeHeaterTypes(with: MTRReadParams())
    _ = cluster.readAttributeTankPercentage(with: MTRReadParams())
    _ = cluster.readAttributeTankVolume(with: MTRReadParams())
}

func testClusterWaterHeaterModeWave11Init() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    _ = MTRClusterWaterHeaterMode(device: device, endpointID: n(1), queue: DispatchQueue.global())
}

func testClusterWaterHeaterModeWave11Command() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    guard let cluster = MTRClusterWaterHeaterMode(device: device, endpointID: n(1), queue: DispatchQueue.global()) else {
        mtrRequire(false, "MTRClusterWaterHeaterMode init")
        return
    }
    cluster.changeToMode(with: MTRWaterHeaterModeClusterChangeToModeParams(), expectedValues: [], expectedValueInterval: n(1), completion: { _, err in mtrExpectInvalidState(err) })
}

func testClusterWaterHeaterModeWave11Cache() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    guard let cluster = MTRClusterWaterHeaterMode(device: device, endpointID: n(1), queue: DispatchQueue.global()) else {
        mtrRequire(false, "MTRClusterWaterHeaterMode init")
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

func testClusterWiFiNetworkManagementWave11Init() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    _ = MTRClusterWiFiNetworkManagement(device: device, endpointID: n(1), queue: DispatchQueue.global())
}

func testClusterWiFiNetworkManagementWave11Command() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    guard let cluster = MTRClusterWiFiNetworkManagement(device: device, endpointID: n(1), queue: DispatchQueue.global()) else {
        mtrRequire(false, "MTRClusterWiFiNetworkManagement init")
        return
    }
    cluster.networkPassphraseRequest(withExpectedValues: [], expectedValueInterval: n(1), completion: { _, err in mtrExpectInvalidState(err) })
    cluster.networkPassphraseRequest(with: MTRWiFiNetworkManagementClusterNetworkPassphraseRequestParams(), expectedValues: [], expectedValueInterval: n(1), completion: { _, err in mtrExpectInvalidState(err) })
}

func testClusterWiFiNetworkManagementWave11Cache() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    guard let cluster = MTRClusterWiFiNetworkManagement(device: device, endpointID: n(1), queue: DispatchQueue.global()) else {
        mtrRequire(false, "MTRClusterWiFiNetworkManagement init")
        return
    }
    _ = cluster.readAttributeAcceptedCommandList(with: MTRReadParams())
    _ = cluster.readAttributeAttributeList(with: MTRReadParams())
    _ = cluster.readAttributeClusterRevision(with: MTRReadParams())
    _ = cluster.readAttributeFeatureMap(with: MTRReadParams())
    _ = cluster.readAttributeGeneratedCommandList(with: MTRReadParams())
    _ = cluster.readAttributePassphraseSurrogate(with: MTRReadParams())
    _ = cluster.readAttributeSSID(with: MTRReadParams())
}

