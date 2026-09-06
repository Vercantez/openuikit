import Foundation
import Dispatch

// Generated Matter cluster I/O. Completion/subscribe paths fail closed
// synchronously (no radio). MTRCluster* reads/writes use the in-memory
// expected-value cache on MTRDevice.

open class MTRBaseClusterElectricalMeasurement: MTRGenericBaseCluster {
    open func getProfileCommand(with params: MTRElectricalMeasurementClusterGetMeasurementProfileCommandParams, completion: @escaping ((any Error)?) -> Void)
    {
        _ = (params, completion)
        mtrFailClosed(completion)
    }
    open func getProfileCommand(with params: MTRElectricalMeasurementClusterGetMeasurementProfileCommandParams, completionHandler: @escaping ((any Error)?) -> Void)
    {
        _ = (params, completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func getProfileInfoCommand(completion: @escaping ((any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func getProfileInfoCommand(completionHandler: @escaping ((any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func getProfileInfoCommand(with params: MTRElectricalMeasurementClusterGetProfileInfoCommandParams?, completion: @escaping ((any Error)?) -> Void)
    {
        _ = (params, completion)
        mtrFailClosed(completion)
    }
    open func getProfileInfoCommand(with params: MTRElectricalMeasurementClusterGetProfileInfoCommandParams?, completionHandler: @escaping ((any Error)?) -> Void)
    {
        _ = (params, completionHandler)
        mtrFailClosed(completionHandler)
    }
    public init?(device: MTRBaseDevice, endpoint: UInt16, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.endpoint = NSNumber(value: endpoint)
        self.queue = queue
    }
    public init?(device: MTRBaseDevice, endpointID: NSNumber, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.endpoint = endpointID
        self.queue = queue
    }
    open func readAttributeAcActivePowerOverload(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeAcActivePowerOverload(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeAcCurrentDivisor(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeAcCurrentDivisor(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeAcCurrentMultiplier(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeAcCurrentMultiplier(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeAcCurrentOverload(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeAcCurrentOverload(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeAcFrequencyDivisor(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeAcFrequencyDivisor(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeAcFrequencyMax(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeAcFrequencyMax(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeAcFrequencyMin(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeAcFrequencyMin(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeAcFrequencyMultiplier(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeAcFrequencyMultiplier(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeAcFrequency(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeAcFrequency(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeAcOverloadAlarmsMask(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeAcOverloadAlarmsMask(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeAcPowerDivisor(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeAcPowerDivisor(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeAcPowerMultiplier(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeAcPowerMultiplier(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeAcReactivePowerOverload(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeAcReactivePowerOverload(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeAcVoltageDivisor(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeAcVoltageDivisor(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeAcVoltageMultiplier(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeAcVoltageMultiplier(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeAcVoltageOverload(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeAcVoltageOverload(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeAcceptedCommandList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeAcceptedCommandList(completionHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeActiveCurrentPhaseB(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeActiveCurrentPhaseB(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeActiveCurrentPhaseC(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeActiveCurrentPhaseC(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeActivePowerMaxPhaseB(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeActivePowerMaxPhaseB(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeActivePowerMaxPhaseC(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeActivePowerMaxPhaseC(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeActivePowerMax(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeActivePowerMax(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeActivePowerMinPhaseB(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeActivePowerMinPhaseB(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeActivePowerMinPhaseC(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeActivePowerMinPhaseC(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeActivePowerMin(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeActivePowerMin(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeActivePowerPhaseB(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeActivePowerPhaseB(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeActivePowerPhaseC(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeActivePowerPhaseC(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeActivePower(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeActivePower(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeApparentPowerPhaseB(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeApparentPowerPhaseB(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeApparentPowerPhaseC(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeApparentPowerPhaseC(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeApparentPower(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeApparentPower(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeAttributeList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeAttributeList(completionHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeAverageRmsOverVoltageCounterPhaseB(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeAverageRmsOverVoltageCounterPhaseB(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeAverageRmsOverVoltageCounterPhaseC(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeAverageRmsOverVoltageCounterPhaseC(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeAverageRmsOverVoltage(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeAverageRmsOverVoltage(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeAverageRmsUnderVoltageCounterPhaseB(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeAverageRmsUnderVoltageCounterPhaseB(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeAverageRmsUnderVoltageCounterPhaseC(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeAverageRmsUnderVoltageCounterPhaseC(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeAverageRmsUnderVoltageCounter(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeAverageRmsUnderVoltageCounter(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeAverageRmsUnderVoltage(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeAverageRmsUnderVoltage(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeAverageRmsVoltageMeasurementPeriodPhaseB(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeAverageRmsVoltageMeasurementPeriodPhaseB(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeAverageRmsVoltageMeasurementPeriodPhaseC(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeAverageRmsVoltageMeasurementPeriodPhaseC(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeAverageRmsVoltageMeasurementPeriod(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeAverageRmsVoltageMeasurementPeriod(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeClusterRevision(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeClusterRevision(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeCurrentOverload(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeCurrentOverload(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeDcCurrentDivisor(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeDcCurrentDivisor(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeDcCurrentMax(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeDcCurrentMax(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeDcCurrentMin(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeDcCurrentMin(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeDcCurrentMultiplier(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeDcCurrentMultiplier(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeDcCurrent(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeDcCurrent(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeDcPowerDivisor(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeDcPowerDivisor(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeDcPowerMax(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeDcPowerMax(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeDcPowerMin(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeDcPowerMin(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeDcPowerMultiplier(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeDcPowerMultiplier(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeDcPower(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeDcPower(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeDcVoltageDivisor(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeDcVoltageDivisor(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeDcVoltageMax(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeDcVoltageMax(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeDcVoltageMin(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeDcVoltageMin(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeDcVoltageMultiplier(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeDcVoltageMultiplier(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeDcVoltage(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeDcVoltage(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeFeatureMap(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeFeatureMap(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeGeneratedCommandList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeGeneratedCommandList(completionHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeHarmonicCurrentMultiplier(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeHarmonicCurrentMultiplier(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeInstantaneousActiveCurrent(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeInstantaneousActiveCurrent(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeInstantaneousLineCurrent(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeInstantaneousLineCurrent(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeInstantaneousPower(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeInstantaneousPower(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeInstantaneousReactiveCurrent(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeInstantaneousReactiveCurrent(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeInstantaneousVoltage(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeInstantaneousVoltage(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeLineCurrentPhaseB(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeLineCurrentPhaseB(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeLineCurrentPhaseC(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeLineCurrentPhaseC(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeMeasured11thHarmonicCurrent(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeMeasured11thHarmonicCurrent(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeMeasured1stHarmonicCurrent(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeMeasured1stHarmonicCurrent(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeMeasured3rdHarmonicCurrent(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeMeasured3rdHarmonicCurrent(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeMeasured5thHarmonicCurrent(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeMeasured5thHarmonicCurrent(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeMeasured7thHarmonicCurrent(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeMeasured7thHarmonicCurrent(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeMeasured9thHarmonicCurrent(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeMeasured9thHarmonicCurrent(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeMeasuredPhase11thHarmonicCurrent(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeMeasuredPhase11thHarmonicCurrent(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeMeasuredPhase1stHarmonicCurrent(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeMeasuredPhase1stHarmonicCurrent(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeMeasuredPhase3rdHarmonicCurrent(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeMeasuredPhase3rdHarmonicCurrent(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeMeasuredPhase5thHarmonicCurrent(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeMeasuredPhase5thHarmonicCurrent(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeMeasuredPhase7thHarmonicCurrent(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeMeasuredPhase7thHarmonicCurrent(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeMeasuredPhase9thHarmonicCurrent(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeMeasuredPhase9thHarmonicCurrent(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeMeasurementType(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeMeasurementType(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeNeutralCurrent(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeNeutralCurrent(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeOverloadAlarmsMask(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeOverloadAlarmsMask(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributePhaseHarmonicCurrentMultiplier(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributePhaseHarmonicCurrentMultiplier(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributePowerDivisor(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributePowerDivisor(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributePowerFactorPhaseB(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributePowerFactorPhaseB(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributePowerFactorPhaseC(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributePowerFactorPhaseC(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributePowerFactor(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributePowerFactor(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributePowerMultiplier(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributePowerMultiplier(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeReactiveCurrentPhaseB(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeReactiveCurrentPhaseB(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeReactiveCurrentPhaseC(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeReactiveCurrentPhaseC(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeReactivePowerPhaseB(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeReactivePowerPhaseB(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeReactivePowerPhaseC(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeReactivePowerPhaseC(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeReactivePower(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeReactivePower(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeRmsCurrentMaxPhaseB(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeRmsCurrentMaxPhaseB(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeRmsCurrentMaxPhaseC(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeRmsCurrentMaxPhaseC(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeRmsCurrentMax(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeRmsCurrentMax(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeRmsCurrentMinPhaseB(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeRmsCurrentMinPhaseB(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeRmsCurrentMinPhaseC(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeRmsCurrentMinPhaseC(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeRmsCurrentMin(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeRmsCurrentMin(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeRmsCurrentPhaseB(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeRmsCurrentPhaseB(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeRmsCurrentPhaseC(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeRmsCurrentPhaseC(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeRmsCurrent(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeRmsCurrent(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeRmsExtremeOverVoltagePeriodPhaseB(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeRmsExtremeOverVoltagePeriodPhaseB(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeRmsExtremeOverVoltagePeriodPhaseC(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeRmsExtremeOverVoltagePeriodPhaseC(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeRmsExtremeOverVoltagePeriod(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeRmsExtremeOverVoltagePeriod(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeRmsExtremeOverVoltage(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeRmsExtremeOverVoltage(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeRmsExtremeUnderVoltagePeriodPhaseB(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeRmsExtremeUnderVoltagePeriodPhaseB(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeRmsExtremeUnderVoltagePeriodPhaseC(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeRmsExtremeUnderVoltagePeriodPhaseC(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeRmsExtremeUnderVoltagePeriod(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeRmsExtremeUnderVoltagePeriod(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeRmsExtremeUnderVoltage(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeRmsExtremeUnderVoltage(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeRmsVoltageMaxPhaseB(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeRmsVoltageMaxPhaseB(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeRmsVoltageMaxPhaseC(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeRmsVoltageMaxPhaseC(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeRmsVoltageMax(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeRmsVoltageMax(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeRmsVoltageMinPhaseB(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeRmsVoltageMinPhaseB(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeRmsVoltageMinPhaseC(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeRmsVoltageMinPhaseC(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeRmsVoltageMin(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeRmsVoltageMin(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeRmsVoltagePhaseB(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeRmsVoltagePhaseB(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeRmsVoltagePhaseC(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeRmsVoltagePhaseC(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeRmsVoltageSagPeriodPhaseB(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeRmsVoltageSagPeriodPhaseB(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeRmsVoltageSagPeriodPhaseC(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeRmsVoltageSagPeriodPhaseC(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeRmsVoltageSagPeriod(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeRmsVoltageSagPeriod(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeRmsVoltageSag(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeRmsVoltageSag(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeRmsVoltageSwellPeriodPhaseB(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeRmsVoltageSwellPeriodPhaseB(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeRmsVoltageSwellPeriodPhaseC(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeRmsVoltageSwellPeriodPhaseC(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeRmsVoltageSwellPeriod(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeRmsVoltageSwellPeriod(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeRmsVoltageSwell(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeRmsVoltageSwell(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeRmsVoltage(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeRmsVoltage(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeTotalActivePower(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeTotalActivePower(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeTotalApparentPower(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeTotalApparentPower(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeTotalReactivePower(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeTotalReactivePower(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeVoltageOverload(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeVoltageOverload(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func subscribeAttributeAcActivePowerOverload(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAcActivePowerOverload(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAcCurrentDivisor(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAcCurrentDivisor(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAcCurrentMultiplier(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAcCurrentMultiplier(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAcCurrentOverload(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAcCurrentOverload(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAcFrequencyDivisor(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAcFrequencyDivisor(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAcFrequencyMax(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAcFrequencyMax(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAcFrequencyMin(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAcFrequencyMin(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAcFrequencyMultiplier(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAcFrequencyMultiplier(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAcFrequency(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAcFrequency(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAcOverloadAlarmsMask(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAcOverloadAlarmsMask(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAcPowerDivisor(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAcPowerDivisor(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAcPowerMultiplier(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAcPowerMultiplier(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAcReactivePowerOverload(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAcReactivePowerOverload(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAcVoltageDivisor(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAcVoltageDivisor(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAcVoltageMultiplier(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAcVoltageMultiplier(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAcVoltageOverload(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAcVoltageOverload(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAcceptedCommandList(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAcceptedCommandList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeActiveCurrentPhaseB(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeActiveCurrentPhaseB(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeActiveCurrentPhaseC(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeActiveCurrentPhaseC(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeActivePowerMaxPhaseB(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeActivePowerMaxPhaseB(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeActivePowerMaxPhaseC(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeActivePowerMaxPhaseC(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeActivePowerMax(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeActivePowerMax(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeActivePowerMinPhaseB(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeActivePowerMinPhaseB(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeActivePowerMinPhaseC(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeActivePowerMinPhaseC(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeActivePowerMin(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeActivePowerMin(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeActivePowerPhaseB(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeActivePowerPhaseB(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeActivePowerPhaseC(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeActivePowerPhaseC(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeActivePower(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeActivePower(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeApparentPowerPhaseB(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeApparentPowerPhaseB(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeApparentPowerPhaseC(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeApparentPowerPhaseC(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeApparentPower(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeApparentPower(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAttributeList(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAttributeList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAverageRmsOverVoltageCounterPhaseB(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAverageRmsOverVoltageCounterPhaseB(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAverageRmsOverVoltageCounterPhaseC(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAverageRmsOverVoltageCounterPhaseC(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAverageRmsOverVoltage(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAverageRmsOverVoltage(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAverageRmsUnderVoltageCounterPhaseB(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAverageRmsUnderVoltageCounterPhaseB(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAverageRmsUnderVoltageCounterPhaseC(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAverageRmsUnderVoltageCounterPhaseC(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAverageRmsUnderVoltageCounter(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAverageRmsUnderVoltageCounter(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAverageRmsUnderVoltage(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAverageRmsUnderVoltage(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAverageRmsVoltageMeasurementPeriodPhaseB(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAverageRmsVoltageMeasurementPeriodPhaseB(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAverageRmsVoltageMeasurementPeriodPhaseC(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAverageRmsVoltageMeasurementPeriodPhaseC(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAverageRmsVoltageMeasurementPeriod(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAverageRmsVoltageMeasurementPeriod(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeClusterRevision(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeClusterRevision(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeCurrentOverload(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeCurrentOverload(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeDcCurrentDivisor(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeDcCurrentDivisor(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeDcCurrentMax(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeDcCurrentMax(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeDcCurrentMin(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeDcCurrentMin(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeDcCurrentMultiplier(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeDcCurrentMultiplier(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeDcCurrent(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeDcCurrent(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeDcPowerDivisor(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeDcPowerDivisor(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeDcPowerMax(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeDcPowerMax(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeDcPowerMin(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeDcPowerMin(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeDcPowerMultiplier(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeDcPowerMultiplier(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeDcPower(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeDcPower(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeDcVoltageDivisor(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeDcVoltageDivisor(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeDcVoltageMax(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeDcVoltageMax(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeDcVoltageMin(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeDcVoltageMin(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeDcVoltageMultiplier(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeDcVoltageMultiplier(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeDcVoltage(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeDcVoltage(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeFeatureMap(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeFeatureMap(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeGeneratedCommandList(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeGeneratedCommandList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeHarmonicCurrentMultiplier(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeHarmonicCurrentMultiplier(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeInstantaneousActiveCurrent(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeInstantaneousActiveCurrent(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeInstantaneousLineCurrent(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeInstantaneousLineCurrent(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeInstantaneousPower(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeInstantaneousPower(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeInstantaneousReactiveCurrent(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeInstantaneousReactiveCurrent(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeInstantaneousVoltage(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeInstantaneousVoltage(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeLineCurrentPhaseB(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeLineCurrentPhaseB(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeLineCurrentPhaseC(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeLineCurrentPhaseC(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeMeasured11thHarmonicCurrent(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeMeasured11thHarmonicCurrent(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeMeasured1stHarmonicCurrent(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeMeasured1stHarmonicCurrent(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeMeasured3rdHarmonicCurrent(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeMeasured3rdHarmonicCurrent(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeMeasured5thHarmonicCurrent(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeMeasured5thHarmonicCurrent(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeMeasured7thHarmonicCurrent(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeMeasured7thHarmonicCurrent(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeMeasured9thHarmonicCurrent(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeMeasured9thHarmonicCurrent(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeMeasuredPhase11thHarmonicCurrent(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeMeasuredPhase11thHarmonicCurrent(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeMeasuredPhase1stHarmonicCurrent(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeMeasuredPhase1stHarmonicCurrent(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeMeasuredPhase3rdHarmonicCurrent(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeMeasuredPhase3rdHarmonicCurrent(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeMeasuredPhase5thHarmonicCurrent(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeMeasuredPhase5thHarmonicCurrent(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeMeasuredPhase7thHarmonicCurrent(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeMeasuredPhase7thHarmonicCurrent(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeMeasuredPhase9thHarmonicCurrent(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeMeasuredPhase9thHarmonicCurrent(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeMeasurementType(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeMeasurementType(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeNeutralCurrent(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeNeutralCurrent(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeOverloadAlarmsMask(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeOverloadAlarmsMask(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributePhaseHarmonicCurrentMultiplier(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributePhaseHarmonicCurrentMultiplier(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributePowerDivisor(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributePowerDivisor(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributePowerFactorPhaseB(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributePowerFactorPhaseB(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributePowerFactorPhaseC(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributePowerFactorPhaseC(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributePowerFactor(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributePowerFactor(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributePowerMultiplier(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributePowerMultiplier(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeReactiveCurrentPhaseB(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeReactiveCurrentPhaseB(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeReactiveCurrentPhaseC(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeReactiveCurrentPhaseC(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeReactivePowerPhaseB(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeReactivePowerPhaseB(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeReactivePowerPhaseC(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeReactivePowerPhaseC(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeReactivePower(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeReactivePower(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeRmsCurrentMaxPhaseB(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeRmsCurrentMaxPhaseB(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeRmsCurrentMaxPhaseC(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeRmsCurrentMaxPhaseC(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeRmsCurrentMax(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeRmsCurrentMax(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeRmsCurrentMinPhaseB(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeRmsCurrentMinPhaseB(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeRmsCurrentMinPhaseC(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeRmsCurrentMinPhaseC(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeRmsCurrentMin(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeRmsCurrentMin(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeRmsCurrentPhaseB(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeRmsCurrentPhaseB(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeRmsCurrentPhaseC(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeRmsCurrentPhaseC(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeRmsCurrent(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeRmsCurrent(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeRmsExtremeOverVoltagePeriodPhaseB(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeRmsExtremeOverVoltagePeriodPhaseB(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeRmsExtremeOverVoltagePeriodPhaseC(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeRmsExtremeOverVoltagePeriodPhaseC(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeRmsExtremeOverVoltagePeriod(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeRmsExtremeOverVoltagePeriod(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeRmsExtremeOverVoltage(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeRmsExtremeOverVoltage(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeRmsExtremeUnderVoltagePeriodPhaseB(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeRmsExtremeUnderVoltagePeriodPhaseB(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeRmsExtremeUnderVoltagePeriodPhaseC(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeRmsExtremeUnderVoltagePeriodPhaseC(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeRmsExtremeUnderVoltagePeriod(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeRmsExtremeUnderVoltagePeriod(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeRmsExtremeUnderVoltage(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeRmsExtremeUnderVoltage(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeRmsVoltageMaxPhaseB(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeRmsVoltageMaxPhaseB(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeRmsVoltageMaxPhaseC(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeRmsVoltageMaxPhaseC(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeRmsVoltageMax(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeRmsVoltageMax(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeRmsVoltageMinPhaseB(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeRmsVoltageMinPhaseB(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeRmsVoltageMinPhaseC(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeRmsVoltageMinPhaseC(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeRmsVoltageMin(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeRmsVoltageMin(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeRmsVoltagePhaseB(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeRmsVoltagePhaseB(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeRmsVoltagePhaseC(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeRmsVoltagePhaseC(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeRmsVoltageSagPeriodPhaseB(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeRmsVoltageSagPeriodPhaseB(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeRmsVoltageSagPeriodPhaseC(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeRmsVoltageSagPeriodPhaseC(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeRmsVoltageSagPeriod(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeRmsVoltageSagPeriod(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeRmsVoltageSag(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeRmsVoltageSag(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeRmsVoltageSwellPeriodPhaseB(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeRmsVoltageSwellPeriodPhaseB(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeRmsVoltageSwellPeriodPhaseC(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeRmsVoltageSwellPeriodPhaseC(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeRmsVoltageSwellPeriod(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeRmsVoltageSwellPeriod(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeRmsVoltageSwell(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeRmsVoltageSwell(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeRmsVoltage(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeRmsVoltage(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeTotalActivePower(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeTotalActivePower(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeTotalApparentPower(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeTotalApparentPower(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeTotalReactivePower(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeTotalReactivePower(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeVoltageOverload(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeVoltageOverload(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
}

open class MTRClusterElectricalMeasurement: MTRGenericCluster {
    open func getProfileCommand(with params: MTRElectricalMeasurementClusterGetMeasurementProfileCommandParams, expectedValues expectedDataValueDictionaries: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completion: @escaping ((any Error)?) -> Void)
    {
        _ = (params, expectedDataValueDictionaries, expectedValueIntervalMs, completion)
        mtrFailClosed(completion)
    }
    open func getProfileCommand(with params: MTRElectricalMeasurementClusterGetMeasurementProfileCommandParams, expectedValues expectedDataValueDictionaries: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completionHandler: @escaping ((any Error)?) -> Void)
    {
        _ = (params, expectedDataValueDictionaries, expectedValueIntervalMs, completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func getProfileInfoCommand(withExpectedValues expectedValues: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completion: @escaping ((any Error)?) -> Void)
    {
        _ = (expectedValues, expectedValueIntervalMs, completion)
        mtrFailClosed(completion)
    }
    open func getProfileInfoCommand(withExpectedValues expectedValues: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completionHandler: @escaping ((any Error)?) -> Void)
    {
        _ = (expectedValues, expectedValueIntervalMs, completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func getProfileInfoCommand(with params: MTRElectricalMeasurementClusterGetProfileInfoCommandParams?, expectedValues expectedDataValueDictionaries: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completion: @escaping ((any Error)?) -> Void)
    {
        _ = (params, expectedDataValueDictionaries, expectedValueIntervalMs, completion)
        mtrFailClosed(completion)
    }
    open func getProfileInfoCommand(with params: MTRElectricalMeasurementClusterGetProfileInfoCommandParams?, expectedValues expectedDataValueDictionaries: [[String : Any]]?, expectedValueInterval expectedValueIntervalMs: NSNumber?, completionHandler: @escaping ((any Error)?) -> Void)
    {
        _ = (params, expectedDataValueDictionaries, expectedValueIntervalMs, completionHandler)
        mtrFailClosed(completionHandler)
    }
    public init?(device: MTRDevice, endpoint: UInt16, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.endpoint = NSNumber(value: endpoint)
        self.queue = queue
    }
    public init?(device: MTRDevice, endpointID: NSNumber, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.endpoint = endpointID
        self.queue = queue
    }
    open func readAttributeAcActivePowerOverload(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("AcActivePowerOverload", params: params)
    }
    open func readAttributeAcCurrentDivisor(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("AcCurrentDivisor", params: params)
    }
    open func readAttributeAcCurrentMultiplier(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("AcCurrentMultiplier", params: params)
    }
    open func readAttributeAcCurrentOverload(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("AcCurrentOverload", params: params)
    }
    open func readAttributeAcFrequencyDivisor(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("AcFrequencyDivisor", params: params)
    }
    open func readAttributeAcFrequencyMax(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("AcFrequencyMax", params: params)
    }
    open func readAttributeAcFrequencyMin(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("AcFrequencyMin", params: params)
    }
    open func readAttributeAcFrequencyMultiplier(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("AcFrequencyMultiplier", params: params)
    }
    open func readAttributeAcFrequency(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("AcFrequency", params: params)
    }
    open func readAttributeAcOverloadAlarmsMask(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("AcOverloadAlarmsMask", params: params)
    }
    open func readAttributeAcPowerDivisor(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("AcPowerDivisor", params: params)
    }
    open func readAttributeAcPowerMultiplier(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("AcPowerMultiplier", params: params)
    }
    open func readAttributeAcReactivePowerOverload(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("AcReactivePowerOverload", params: params)
    }
    open func readAttributeAcVoltageDivisor(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("AcVoltageDivisor", params: params)
    }
    open func readAttributeAcVoltageMultiplier(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("AcVoltageMultiplier", params: params)
    }
    open func readAttributeAcVoltageOverload(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("AcVoltageOverload", params: params)
    }
    open func readAttributeAcceptedCommandList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("AcceptedCommandList", params: params)
    }
    open func readAttributeActiveCurrentPhaseB(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("ActiveCurrentPhaseB", params: params)
    }
    open func readAttributeActiveCurrentPhaseC(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("ActiveCurrentPhaseC", params: params)
    }
    open func readAttributeActivePowerMaxPhaseB(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("ActivePowerMaxPhaseB", params: params)
    }
    open func readAttributeActivePowerMaxPhaseC(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("ActivePowerMaxPhaseC", params: params)
    }
    open func readAttributeActivePowerMax(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("ActivePowerMax", params: params)
    }
    open func readAttributeActivePowerMinPhaseB(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("ActivePowerMinPhaseB", params: params)
    }
    open func readAttributeActivePowerMinPhaseC(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("ActivePowerMinPhaseC", params: params)
    }
    open func readAttributeActivePowerMin(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("ActivePowerMin", params: params)
    }
    open func readAttributeActivePowerPhaseB(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("ActivePowerPhaseB", params: params)
    }
    open func readAttributeActivePowerPhaseC(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("ActivePowerPhaseC", params: params)
    }
    open func readAttributeActivePower(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("ActivePower", params: params)
    }
    open func readAttributeApparentPowerPhaseB(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("ApparentPowerPhaseB", params: params)
    }
    open func readAttributeApparentPowerPhaseC(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("ApparentPowerPhaseC", params: params)
    }
    open func readAttributeApparentPower(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("ApparentPower", params: params)
    }
    open func readAttributeAttributeList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("AttributeList", params: params)
    }
    open func readAttributeAverageRmsOverVoltageCounterPhaseB(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("AverageRmsOverVoltageCounterPhaseB", params: params)
    }
    open func readAttributeAverageRmsOverVoltageCounterPhaseC(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("AverageRmsOverVoltageCounterPhaseC", params: params)
    }
    open func readAttributeAverageRmsOverVoltage(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("AverageRmsOverVoltage", params: params)
    }
    open func readAttributeAverageRmsUnderVoltageCounterPhaseB(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("AverageRmsUnderVoltageCounterPhaseB", params: params)
    }
    open func readAttributeAverageRmsUnderVoltageCounterPhaseC(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("AverageRmsUnderVoltageCounterPhaseC", params: params)
    }
    open func readAttributeAverageRmsUnderVoltageCounter(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("AverageRmsUnderVoltageCounter", params: params)
    }
    open func readAttributeAverageRmsUnderVoltage(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("AverageRmsUnderVoltage", params: params)
    }
    open func readAttributeAverageRmsVoltageMeasurementPeriodPhaseB(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("AverageRmsVoltageMeasurementPeriodPhaseB", params: params)
    }
    open func readAttributeAverageRmsVoltageMeasurementPeriodPhaseC(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("AverageRmsVoltageMeasurementPeriodPhaseC", params: params)
    }
    open func readAttributeAverageRmsVoltageMeasurementPeriod(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("AverageRmsVoltageMeasurementPeriod", params: params)
    }
    open func readAttributeClusterRevision(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("ClusterRevision", params: params)
    }
    open func readAttributeCurrentOverload(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("CurrentOverload", params: params)
    }
    open func readAttributeDcCurrentDivisor(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("DcCurrentDivisor", params: params)
    }
    open func readAttributeDcCurrentMax(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("DcCurrentMax", params: params)
    }
    open func readAttributeDcCurrentMin(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("DcCurrentMin", params: params)
    }
    open func readAttributeDcCurrentMultiplier(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("DcCurrentMultiplier", params: params)
    }
    open func readAttributeDcCurrent(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("DcCurrent", params: params)
    }
    open func readAttributeDcPowerDivisor(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("DcPowerDivisor", params: params)
    }
    open func readAttributeDcPowerMax(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("DcPowerMax", params: params)
    }
    open func readAttributeDcPowerMin(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("DcPowerMin", params: params)
    }
    open func readAttributeDcPowerMultiplier(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("DcPowerMultiplier", params: params)
    }
    open func readAttributeDcPower(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("DcPower", params: params)
    }
    open func readAttributeDcVoltageDivisor(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("DcVoltageDivisor", params: params)
    }
    open func readAttributeDcVoltageMax(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("DcVoltageMax", params: params)
    }
    open func readAttributeDcVoltageMin(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("DcVoltageMin", params: params)
    }
    open func readAttributeDcVoltageMultiplier(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("DcVoltageMultiplier", params: params)
    }
    open func readAttributeDcVoltage(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("DcVoltage", params: params)
    }
    open func readAttributeFeatureMap(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("FeatureMap", params: params)
    }
    open func readAttributeGeneratedCommandList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("GeneratedCommandList", params: params)
    }
    open func readAttributeHarmonicCurrentMultiplier(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("HarmonicCurrentMultiplier", params: params)
    }
    open func readAttributeInstantaneousActiveCurrent(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("InstantaneousActiveCurrent", params: params)
    }
    open func readAttributeInstantaneousLineCurrent(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("InstantaneousLineCurrent", params: params)
    }
    open func readAttributeInstantaneousPower(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("InstantaneousPower", params: params)
    }
    open func readAttributeInstantaneousReactiveCurrent(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("InstantaneousReactiveCurrent", params: params)
    }
    open func readAttributeInstantaneousVoltage(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("InstantaneousVoltage", params: params)
    }
    open func readAttributeLineCurrentPhaseB(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("LineCurrentPhaseB", params: params)
    }
    open func readAttributeLineCurrentPhaseC(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("LineCurrentPhaseC", params: params)
    }
    open func readAttributeMeasured11thHarmonicCurrent(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("Measured11thHarmonicCurrent", params: params)
    }
    open func readAttributeMeasured1stHarmonicCurrent(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("Measured1stHarmonicCurrent", params: params)
    }
    open func readAttributeMeasured3rdHarmonicCurrent(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("Measured3rdHarmonicCurrent", params: params)
    }
    open func readAttributeMeasured5thHarmonicCurrent(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("Measured5thHarmonicCurrent", params: params)
    }
    open func readAttributeMeasured7thHarmonicCurrent(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("Measured7thHarmonicCurrent", params: params)
    }
    open func readAttributeMeasured9thHarmonicCurrent(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("Measured9thHarmonicCurrent", params: params)
    }
    open func readAttributeMeasuredPhase11thHarmonicCurrent(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("MeasuredPhase11thHarmonicCurrent", params: params)
    }
    open func readAttributeMeasuredPhase1stHarmonicCurrent(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("MeasuredPhase1stHarmonicCurrent", params: params)
    }
    open func readAttributeMeasuredPhase3rdHarmonicCurrent(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("MeasuredPhase3rdHarmonicCurrent", params: params)
    }
    open func readAttributeMeasuredPhase5thHarmonicCurrent(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("MeasuredPhase5thHarmonicCurrent", params: params)
    }
    open func readAttributeMeasuredPhase7thHarmonicCurrent(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("MeasuredPhase7thHarmonicCurrent", params: params)
    }
    open func readAttributeMeasuredPhase9thHarmonicCurrent(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("MeasuredPhase9thHarmonicCurrent", params: params)
    }
    open func readAttributeMeasurementType(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("MeasurementType", params: params)
    }
    open func readAttributeNeutralCurrent(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("NeutralCurrent", params: params)
    }
    open func readAttributeOverloadAlarmsMask(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("OverloadAlarmsMask", params: params)
    }
    open func readAttributePhaseHarmonicCurrentMultiplier(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("PhaseHarmonicCurrentMultiplier", params: params)
    }
    open func readAttributePowerDivisor(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("PowerDivisor", params: params)
    }
    open func readAttributePowerFactorPhaseB(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("PowerFactorPhaseB", params: params)
    }
    open func readAttributePowerFactorPhaseC(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("PowerFactorPhaseC", params: params)
    }
    open func readAttributePowerFactor(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("PowerFactor", params: params)
    }
    open func readAttributePowerMultiplier(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("PowerMultiplier", params: params)
    }
    open func readAttributeReactiveCurrentPhaseB(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("ReactiveCurrentPhaseB", params: params)
    }
    open func readAttributeReactiveCurrentPhaseC(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("ReactiveCurrentPhaseC", params: params)
    }
    open func readAttributeReactivePowerPhaseB(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("ReactivePowerPhaseB", params: params)
    }
    open func readAttributeReactivePowerPhaseC(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("ReactivePowerPhaseC", params: params)
    }
    open func readAttributeReactivePower(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("ReactivePower", params: params)
    }
    open func readAttributeRmsCurrentMaxPhaseB(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("RmsCurrentMaxPhaseB", params: params)
    }
    open func readAttributeRmsCurrentMaxPhaseC(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("RmsCurrentMaxPhaseC", params: params)
    }
    open func readAttributeRmsCurrentMax(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("RmsCurrentMax", params: params)
    }
    open func readAttributeRmsCurrentMinPhaseB(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("RmsCurrentMinPhaseB", params: params)
    }
    open func readAttributeRmsCurrentMinPhaseC(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("RmsCurrentMinPhaseC", params: params)
    }
    open func readAttributeRmsCurrentMin(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("RmsCurrentMin", params: params)
    }
    open func readAttributeRmsCurrentPhaseB(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("RmsCurrentPhaseB", params: params)
    }
    open func readAttributeRmsCurrentPhaseC(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("RmsCurrentPhaseC", params: params)
    }
    open func readAttributeRmsCurrent(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("RmsCurrent", params: params)
    }
    open func readAttributeRmsExtremeOverVoltagePeriodPhaseB(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("RmsExtremeOverVoltagePeriodPhaseB", params: params)
    }
    open func readAttributeRmsExtremeOverVoltagePeriodPhaseC(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("RmsExtremeOverVoltagePeriodPhaseC", params: params)
    }
    open func readAttributeRmsExtremeOverVoltagePeriod(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("RmsExtremeOverVoltagePeriod", params: params)
    }
    open func readAttributeRmsExtremeOverVoltage(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("RmsExtremeOverVoltage", params: params)
    }
    open func readAttributeRmsExtremeUnderVoltagePeriodPhaseB(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("RmsExtremeUnderVoltagePeriodPhaseB", params: params)
    }
    open func readAttributeRmsExtremeUnderVoltagePeriodPhaseC(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("RmsExtremeUnderVoltagePeriodPhaseC", params: params)
    }
    open func readAttributeRmsExtremeUnderVoltagePeriod(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("RmsExtremeUnderVoltagePeriod", params: params)
    }
    open func readAttributeRmsExtremeUnderVoltage(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("RmsExtremeUnderVoltage", params: params)
    }
    open func readAttributeRmsVoltageMaxPhaseB(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("RmsVoltageMaxPhaseB", params: params)
    }
    open func readAttributeRmsVoltageMaxPhaseC(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("RmsVoltageMaxPhaseC", params: params)
    }
    open func readAttributeRmsVoltageMax(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("RmsVoltageMax", params: params)
    }
    open func readAttributeRmsVoltageMinPhaseB(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("RmsVoltageMinPhaseB", params: params)
    }
    open func readAttributeRmsVoltageMinPhaseC(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("RmsVoltageMinPhaseC", params: params)
    }
    open func readAttributeRmsVoltageMin(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("RmsVoltageMin", params: params)
    }
    open func readAttributeRmsVoltagePhaseB(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("RmsVoltagePhaseB", params: params)
    }
    open func readAttributeRmsVoltagePhaseC(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("RmsVoltagePhaseC", params: params)
    }
    open func readAttributeRmsVoltageSagPeriodPhaseB(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("RmsVoltageSagPeriodPhaseB", params: params)
    }
    open func readAttributeRmsVoltageSagPeriodPhaseC(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("RmsVoltageSagPeriodPhaseC", params: params)
    }
    open func readAttributeRmsVoltageSagPeriod(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("RmsVoltageSagPeriod", params: params)
    }
    open func readAttributeRmsVoltageSag(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("RmsVoltageSag", params: params)
    }
    open func readAttributeRmsVoltageSwellPeriodPhaseB(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("RmsVoltageSwellPeriodPhaseB", params: params)
    }
    open func readAttributeRmsVoltageSwellPeriodPhaseC(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("RmsVoltageSwellPeriodPhaseC", params: params)
    }
    open func readAttributeRmsVoltageSwellPeriod(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("RmsVoltageSwellPeriod", params: params)
    }
    open func readAttributeRmsVoltageSwell(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("RmsVoltageSwell", params: params)
    }
    open func readAttributeRmsVoltage(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("RmsVoltage", params: params)
    }
    open func readAttributeTotalActivePower(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("TotalActivePower", params: params)
    }
    open func readAttributeTotalApparentPower(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("TotalApparentPower", params: params)
    }
    open func readAttributeTotalReactivePower(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("TotalReactivePower", params: params)
    }
    open func readAttributeVoltageOverload(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("VoltageOverload", params: params)
    }
    open func writeAttributeAcOverloadAlarmsMask(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber)
    {
        _ = (dataValueDictionary, expectedValueIntervalMs)
        mtrHostWrite("AcOverloadAlarmsMask", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: nil)
    }
    open func writeAttributeAcOverloadAlarmsMask(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber, params: MTRWriteParams?)
    {
        _ = (dataValueDictionary, expectedValueIntervalMs, params)
        mtrHostWrite("AcOverloadAlarmsMask", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: params)
    }
    open func writeAttributeAverageRmsUnderVoltageCounter(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber)
    {
        _ = (dataValueDictionary, expectedValueIntervalMs)
        mtrHostWrite("AverageRmsUnderVoltageCounter", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: nil)
    }
    open func writeAttributeAverageRmsUnderVoltageCounter(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber, params: MTRWriteParams?)
    {
        _ = (dataValueDictionary, expectedValueIntervalMs, params)
        mtrHostWrite("AverageRmsUnderVoltageCounter", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: params)
    }
    open func writeAttributeAverageRmsVoltageMeasurementPeriod(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber)
    {
        _ = (dataValueDictionary, expectedValueIntervalMs)
        mtrHostWrite("AverageRmsVoltageMeasurementPeriod", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: nil)
    }
    open func writeAttributeAverageRmsVoltageMeasurementPeriod(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber, params: MTRWriteParams?)
    {
        _ = (dataValueDictionary, expectedValueIntervalMs, params)
        mtrHostWrite("AverageRmsVoltageMeasurementPeriod", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: params)
    }
    open func writeAttributeOverloadAlarmsMask(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber)
    {
        _ = (dataValueDictionary, expectedValueIntervalMs)
        mtrHostWrite("OverloadAlarmsMask", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: nil)
    }
    open func writeAttributeOverloadAlarmsMask(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber, params: MTRWriteParams?)
    {
        _ = (dataValueDictionary, expectedValueIntervalMs, params)
        mtrHostWrite("OverloadAlarmsMask", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: params)
    }
    open func writeAttributeRmsExtremeOverVoltagePeriod(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber)
    {
        _ = (dataValueDictionary, expectedValueIntervalMs)
        mtrHostWrite("RmsExtremeOverVoltagePeriod", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: nil)
    }
    open func writeAttributeRmsExtremeOverVoltagePeriod(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber, params: MTRWriteParams?)
    {
        _ = (dataValueDictionary, expectedValueIntervalMs, params)
        mtrHostWrite("RmsExtremeOverVoltagePeriod", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: params)
    }
    open func writeAttributeRmsExtremeUnderVoltagePeriod(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber)
    {
        _ = (dataValueDictionary, expectedValueIntervalMs)
        mtrHostWrite("RmsExtremeUnderVoltagePeriod", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: nil)
    }
    open func writeAttributeRmsExtremeUnderVoltagePeriod(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber, params: MTRWriteParams?)
    {
        _ = (dataValueDictionary, expectedValueIntervalMs, params)
        mtrHostWrite("RmsExtremeUnderVoltagePeriod", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: params)
    }
    open func writeAttributeRmsVoltageSagPeriod(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber)
    {
        _ = (dataValueDictionary, expectedValueIntervalMs)
        mtrHostWrite("RmsVoltageSagPeriod", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: nil)
    }
    open func writeAttributeRmsVoltageSagPeriod(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber, params: MTRWriteParams?)
    {
        _ = (dataValueDictionary, expectedValueIntervalMs, params)
        mtrHostWrite("RmsVoltageSagPeriod", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: params)
    }
    open func writeAttributeRmsVoltageSwellPeriod(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber)
    {
        _ = (dataValueDictionary, expectedValueIntervalMs)
        mtrHostWrite("RmsVoltageSwellPeriod", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: nil)
    }
    open func writeAttributeRmsVoltageSwellPeriod(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber, params: MTRWriteParams?)
    {
        _ = (dataValueDictionary, expectedValueIntervalMs, params)
        mtrHostWrite("RmsVoltageSwellPeriod", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: params)
    }
}

open class MTRBaseClusterThermostat: MTRGenericBaseCluster {
    open func clearWeeklySchedule(completion: @escaping ((any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func clearWeeklySchedule(completionHandler: @escaping ((any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func getWeeklySchedule(with params: MTRThermostatClusterGetWeeklyScheduleParams, completion: @escaping (MTRThermostatClusterGetWeeklyScheduleResponseParams?, (any Error)?) -> Void)
    {
        _ = (params, completion)
        mtrFailClosed(completion)
    }
    open func getWeeklySchedule(with params: MTRThermostatClusterGetWeeklyScheduleParams, completionHandler: @escaping (MTRThermostatClusterGetWeeklyScheduleResponseParams?, (any Error)?) -> Void)
    {
        _ = (params, completionHandler)
        mtrFailClosed(completionHandler)
    }
    public init?(device: MTRBaseDevice, endpoint: UInt16, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.endpoint = NSNumber(value: endpoint)
        self.queue = queue
    }
    public init?(device: MTRBaseDevice, endpointID: NSNumber, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.endpoint = endpointID
        self.queue = queue
    }
    open func readAttributeACCapacity(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeACCapacity(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeACCapacityformat(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeACCapacityformat(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeACCoilTemperature(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeACCoilTemperature(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeACCompressorType(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeACCompressorType(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeACErrorCode(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeACErrorCode(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeACLouverPosition(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeACLouverPosition(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeACRefrigerantType(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeACRefrigerantType(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeACType(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeACType(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeAbsMaxCoolSetpointLimit(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeAbsMaxCoolSetpointLimit(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeAbsMaxHeatSetpointLimit(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeAbsMaxHeatSetpointLimit(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeAbsMinCoolSetpointLimit(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeAbsMinCoolSetpointLimit(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeAbsMinHeatSetpointLimit(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeAbsMinHeatSetpointLimit(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeAcceptedCommandList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeAcceptedCommandList(completionHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeActivePresetHandle(completion: @escaping (Data?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeActiveScheduleHandle(completion: @escaping (Data?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeAttributeList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeAttributeList(completionHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeClusterRevision(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeClusterRevision(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeControlSequenceOfOperation(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeControlSequenceOfOperation(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeEmergencyHeatDelta(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeEmergencyHeatDelta(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeFeatureMap(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeFeatureMap(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeGeneratedCommandList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeGeneratedCommandList(completionHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeHVACSystemTypeConfiguration(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeHVACSystemTypeConfiguration(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeLocalTemperatureCalibration(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeLocalTemperatureCalibration(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeLocalTemperature(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeLocalTemperature(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeMaxCoolSetpointLimit(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeMaxCoolSetpointLimit(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeMaxHeatSetpointLimit(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeMaxHeatSetpointLimit(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeMinCoolSetpointLimit(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeMinCoolSetpointLimit(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeMinHeatSetpointLimit(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeMinHeatSetpointLimit(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeMinSetpointDeadBand(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeMinSetpointDeadBand(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeNumberOfDailyTransitions(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeNumberOfDailyTransitions(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeNumberOfPresets(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeNumberOfScheduleTransitionPerDay(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeNumberOfScheduleTransitions(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeNumberOfSchedules(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeNumberOfWeeklyTransitions(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeNumberOfWeeklyTransitions(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeOccupancy(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeOccupancy(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeOccupiedCoolingSetpoint(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeOccupiedCoolingSetpoint(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeOccupiedHeatingSetpoint(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeOccupiedHeatingSetpoint(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeOccupiedSetbackMax(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeOccupiedSetbackMax(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeOccupiedSetbackMin(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeOccupiedSetbackMin(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeOccupiedSetback(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeOccupiedSetback(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeOutdoorTemperature(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeOutdoorTemperature(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributePICoolingDemand(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributePICoolingDemand(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributePIHeatingDemand(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributePIHeatingDemand(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributePresetTypes(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributePresets(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeRemoteSensing(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeRemoteSensing(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeScheduleTypes(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeSchedules(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeSetpointChangeAmount(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeSetpointChangeAmount(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeSetpointChangeSourceTimestamp(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeSetpointChangeSourceTimestamp(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeSetpointChangeSource(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeSetpointChangeSource(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeSetpointHoldExpiryTimestamp(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeStartOfWeek(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeStartOfWeek(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeSystemMode(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeSystemMode(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeTemperatureSetpointHoldDuration(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeTemperatureSetpointHoldDuration(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeTemperatureSetpointHold(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeTemperatureSetpointHold(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeThermostatProgrammingOperationMode(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeThermostatProgrammingOperationMode(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeThermostatRunningMode(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeThermostatRunningMode(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeThermostatRunningState(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeThermostatRunningState(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeUnoccupiedCoolingSetpoint(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeUnoccupiedCoolingSetpoint(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeUnoccupiedHeatingSetpoint(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeUnoccupiedHeatingSetpoint(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeUnoccupiedSetbackMax(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeUnoccupiedSetbackMax(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeUnoccupiedSetbackMin(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeUnoccupiedSetbackMin(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeUnoccupiedSetback(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeUnoccupiedSetback(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func subscribeAttributeACCapacity(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeACCapacity(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeACCapacityformat(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeACCapacityformat(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeACCoilTemperature(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeACCoilTemperature(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeACCompressorType(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeACCompressorType(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeACErrorCode(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeACErrorCode(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeACLouverPosition(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeACLouverPosition(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeACRefrigerantType(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeACRefrigerantType(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeACType(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeACType(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAbsMaxCoolSetpointLimit(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAbsMaxCoolSetpointLimit(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAbsMaxHeatSetpointLimit(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAbsMaxHeatSetpointLimit(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAbsMinCoolSetpointLimit(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAbsMinCoolSetpointLimit(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAbsMinHeatSetpointLimit(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAbsMinHeatSetpointLimit(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAcceptedCommandList(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAcceptedCommandList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeActivePresetHandle(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (Data?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeActiveScheduleHandle(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (Data?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAttributeList(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAttributeList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeClusterRevision(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeClusterRevision(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeControlSequenceOfOperation(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeControlSequenceOfOperation(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeEmergencyHeatDelta(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeEmergencyHeatDelta(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeFeatureMap(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeFeatureMap(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeGeneratedCommandList(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeGeneratedCommandList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeHVACSystemTypeConfiguration(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeHVACSystemTypeConfiguration(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeLocalTemperatureCalibration(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeLocalTemperatureCalibration(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeLocalTemperature(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeLocalTemperature(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeMaxCoolSetpointLimit(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeMaxCoolSetpointLimit(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeMaxHeatSetpointLimit(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeMaxHeatSetpointLimit(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeMinCoolSetpointLimit(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeMinCoolSetpointLimit(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeMinHeatSetpointLimit(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeMinHeatSetpointLimit(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeMinSetpointDeadBand(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeMinSetpointDeadBand(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeNumberOfDailyTransitions(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeNumberOfDailyTransitions(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeNumberOfPresets(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeNumberOfScheduleTransitionPerDay(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeNumberOfScheduleTransitions(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeNumberOfSchedules(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeNumberOfWeeklyTransitions(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeNumberOfWeeklyTransitions(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeOccupancy(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeOccupancy(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeOccupiedCoolingSetpoint(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeOccupiedCoolingSetpoint(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeOccupiedHeatingSetpoint(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeOccupiedHeatingSetpoint(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeOccupiedSetbackMax(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeOccupiedSetbackMax(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeOccupiedSetbackMin(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeOccupiedSetbackMin(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeOccupiedSetback(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeOccupiedSetback(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeOutdoorTemperature(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeOutdoorTemperature(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributePICoolingDemand(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributePICoolingDemand(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributePIHeatingDemand(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributePIHeatingDemand(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributePresetTypes(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributePresets(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeRemoteSensing(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeRemoteSensing(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeScheduleTypes(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeSchedules(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeSetpointChangeAmount(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeSetpointChangeAmount(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeSetpointChangeSourceTimestamp(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeSetpointChangeSourceTimestamp(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeSetpointChangeSource(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeSetpointChangeSource(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeSetpointHoldExpiryTimestamp(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeStartOfWeek(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeStartOfWeek(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeSystemMode(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeSystemMode(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeTemperatureSetpointHoldDuration(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeTemperatureSetpointHoldDuration(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeTemperatureSetpointHold(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeTemperatureSetpointHold(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeThermostatProgrammingOperationMode(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeThermostatProgrammingOperationMode(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeThermostatRunningMode(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeThermostatRunningMode(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeThermostatRunningState(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeThermostatRunningState(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeUnoccupiedCoolingSetpoint(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeUnoccupiedCoolingSetpoint(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeUnoccupiedHeatingSetpoint(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeUnoccupiedHeatingSetpoint(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeUnoccupiedSetbackMax(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeUnoccupiedSetbackMax(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeUnoccupiedSetbackMin(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeUnoccupiedSetbackMin(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeUnoccupiedSetback(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeUnoccupiedSetback(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
}

open class MTRBaseClusterUnitTesting: MTRGenericBaseCluster {
    public init?(device: MTRBaseDevice, endpointID: NSNumber, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.endpoint = endpointID
        self.queue = queue
    }
    open func readAttributeAcceptedCommandList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeAttributeList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeBitmap16(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeBitmap32(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeBitmap64(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeBitmap8(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeBoolean(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeCharString(completion: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeClusterErrorBoolean(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeClusterRevision(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeEnum16(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeEnum8(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeEnumAttr(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeEpochS(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeEpochUs(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeFeatureMap(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeFloatDouble(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeFloatSingle(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeGeneralErrorBoolean(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeGeneratedCommandList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeInt16s(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeInt16u(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeInt24s(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeInt24u(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeInt32s(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeInt32u(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeInt40s(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeInt40u(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeInt48s(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeInt48u(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeInt56s(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeInt56u(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeInt64s(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeInt64u(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeInt8s(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeInt8u(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeListInt8u(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeListLongOctetString(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeListNullablesAndOptionalsStruct(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeListOctetString(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeListStructOctetString(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeLongCharString(completion: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeLongOctetString(completion: @escaping (Data?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeNullableBitmap16(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeNullableBitmap32(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeNullableBitmap64(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeNullableBitmap8(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeNullableBoolean(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeNullableCharString(completion: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeNullableEnum16(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeNullableEnum8(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeNullableEnumAttr(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeNullableFloatDouble(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeNullableFloatSingle(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeNullableInt16s(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeNullableInt16u(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeNullableInt24s(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeNullableInt24u(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeNullableInt32s(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeNullableInt32u(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeNullableInt40s(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeNullableInt40u(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeNullableInt48s(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeNullableInt48u(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeNullableInt56s(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeNullableInt56u(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeNullableInt64s(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeNullableInt64u(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeNullableInt8s(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeNullableInt8u(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeNullableOctetString(completion: @escaping (Data?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeNullableRangeRestrictedInt16s(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeNullableRangeRestrictedInt16u(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeNullableRangeRestrictedInt8s(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeNullableRangeRestrictedInt8u(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeNullableStruct(completion: @escaping (MTRUnitTestingClusterSimpleStruct?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeOctetString(completion: @escaping (Data?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeRangeRestrictedInt16s(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeRangeRestrictedInt16u(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeRangeRestrictedInt8s(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeRangeRestrictedInt8u(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeStructAttr(completion: @escaping (MTRUnitTestingClusterSimpleStruct?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeTimedWriteBoolean(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeUnsupported(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeVendorId(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeWriteOnlyInt8u(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func subscribeAttributeAcceptedCommandList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAttributeList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeBitmap16(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeBitmap32(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeBitmap64(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeBitmap8(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeBoolean(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeCharString(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeClusterErrorBoolean(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeClusterRevision(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeEnum16(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeEnum8(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeEnumAttr(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeEpochS(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeEpochUs(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeFeatureMap(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeFloatDouble(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeFloatSingle(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeGeneralErrorBoolean(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeGeneratedCommandList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeInt16s(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeInt16u(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeInt24s(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeInt24u(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeInt32s(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeInt32u(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeInt40s(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeInt40u(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeInt48s(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeInt48u(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeInt56s(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeInt56u(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeInt64s(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeInt64u(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeInt8s(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeInt8u(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeListFabricScoped(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeListInt8u(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeListLongOctetString(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeListNullablesAndOptionalsStruct(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeListOctetString(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeListStructOctetString(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeLongCharString(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeLongOctetString(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (Data?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeNullableBitmap16(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeNullableBitmap32(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeNullableBitmap64(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeNullableBitmap8(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeNullableBoolean(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeNullableCharString(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeNullableEnum16(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeNullableEnum8(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeNullableEnumAttr(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeNullableFloatDouble(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeNullableFloatSingle(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeNullableInt16s(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeNullableInt16u(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeNullableInt24s(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeNullableInt24u(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeNullableInt32s(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeNullableInt32u(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeNullableInt40s(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeNullableInt40u(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeNullableInt48s(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeNullableInt48u(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeNullableInt56s(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeNullableInt56u(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeNullableInt64s(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeNullableInt64u(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeNullableInt8s(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeNullableInt8u(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeNullableOctetString(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (Data?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeNullableRangeRestrictedInt16s(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeNullableRangeRestrictedInt16u(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeNullableRangeRestrictedInt8s(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeNullableRangeRestrictedInt8u(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeNullableStruct(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (MTRUnitTestingClusterSimpleStruct?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeOctetString(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (Data?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeRangeRestrictedInt16s(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeRangeRestrictedInt16u(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeRangeRestrictedInt8s(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeRangeRestrictedInt8u(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeStructAttr(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (MTRUnitTestingClusterSimpleStruct?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeTimedWriteBoolean(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeUnsupported(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeVendorId(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeWriteOnlyInt8u(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func testNotHandled(completion: @escaping ((any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func testNullableOptionalRequest(completion: @escaping (MTRUnitTestingClusterTestNullableOptionalResponseParams?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func testSimpleOptionalArgumentRequest(completion: @escaping ((any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func testSpecific(completion: @escaping (MTRUnitTestingClusterTestSpecificResponseParams?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func testUnknownCommand(completion: @escaping ((any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func test(completion: @escaping ((any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func timedInvokeRequest(completion: @escaping ((any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
}

open class MTRBaseClusterTestCluster: MTRBaseClusterUnitTesting {
    public convenience init?(device: MTRBaseDevice, endpoint: UInt16, queue: dispatch_queue_t)
    {
        self.init(device: device, endpointID: NSNumber(value: endpoint), queue: queue)
    }
    open func readAttributeAcceptedCommandList(completionHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeAttributeList(completionHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeBitmap16(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeBitmap32(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeBitmap64(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeBitmap8(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeBoolean(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeCharString(completionHandler: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeClusterErrorBoolean(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeClusterRevision(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeEnum16(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeEnum8(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeEnumAttr(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeEpochS(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeEpochUs(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeFeatureMap(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeFloatDouble(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeFloatSingle(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeGeneralErrorBoolean(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeGeneratedCommandList(completionHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeInt16s(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeInt16u(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeInt24s(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeInt24u(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeInt32s(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeInt32u(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeInt40s(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeInt40u(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeInt48s(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeInt48u(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeInt56s(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeInt56u(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeInt64s(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeInt64u(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeInt8s(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeInt8u(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeListInt8u(completionHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeListLongOctetString(completionHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeListNullablesAndOptionalsStruct(completionHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeListOctetString(completionHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeListStructOctetString(completionHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeLongCharString(completionHandler: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeLongOctetString(completionHandler: @escaping (Data?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeNullableBitmap16(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeNullableBitmap32(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeNullableBitmap64(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeNullableBitmap8(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeNullableBoolean(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeNullableCharString(completionHandler: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeNullableEnum16(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeNullableEnum8(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeNullableEnumAttr(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeNullableFloatDouble(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeNullableFloatSingle(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeNullableInt16s(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeNullableInt16u(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeNullableInt24s(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeNullableInt24u(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeNullableInt32s(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeNullableInt32u(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeNullableInt40s(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeNullableInt40u(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeNullableInt48s(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeNullableInt48u(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeNullableInt56s(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeNullableInt56u(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeNullableInt64s(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeNullableInt64u(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeNullableInt8s(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeNullableInt8u(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeNullableOctetString(completionHandler: @escaping (Data?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeNullableRangeRestrictedInt16s(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeNullableRangeRestrictedInt16u(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeNullableRangeRestrictedInt8s(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeNullableRangeRestrictedInt8u(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeNullableStruct(completionHandler: @escaping (MTRTestClusterClusterSimpleStruct?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeOctetString(completionHandler: @escaping (Data?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeRangeRestrictedInt16s(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeRangeRestrictedInt16u(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeRangeRestrictedInt8s(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeRangeRestrictedInt8u(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeStructAttr(completionHandler: @escaping (MTRTestClusterClusterSimpleStruct?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeTimedWriteBoolean(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeUnsupported(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeVendorId(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeWriteOnlyInt8u(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func subscribeAttributeAcceptedCommandList(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAttributeList(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeBitmap16(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeBitmap32(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeBitmap64(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeBitmap8(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeBoolean(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeCharString(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeClusterErrorBoolean(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeClusterRevision(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeEnum16(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeEnum8(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeEnumAttr(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeEpochS(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeEpochUs(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeFeatureMap(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeFloatDouble(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeFloatSingle(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeGeneralErrorBoolean(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeGeneratedCommandList(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeInt16s(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeInt16u(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeInt24s(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeInt24u(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeInt32s(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeInt32u(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeInt40s(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeInt40u(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeInt48s(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeInt48u(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeInt56s(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeInt56u(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeInt64s(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeInt64u(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeInt8s(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeInt8u(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeListFabricScoped(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeListInt8u(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeListLongOctetString(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeListNullablesAndOptionalsStruct(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeListOctetString(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeListStructOctetString(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeLongCharString(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeLongOctetString(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (Data?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeNullableBitmap16(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeNullableBitmap32(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeNullableBitmap64(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeNullableBitmap8(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeNullableBoolean(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeNullableCharString(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeNullableEnum16(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeNullableEnum8(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeNullableEnumAttr(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeNullableFloatDouble(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeNullableFloatSingle(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeNullableInt16s(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeNullableInt16u(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeNullableInt24s(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeNullableInt24u(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeNullableInt32s(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeNullableInt32u(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeNullableInt40s(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeNullableInt40u(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeNullableInt48s(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeNullableInt48u(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeNullableInt56s(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeNullableInt56u(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeNullableInt64s(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeNullableInt64u(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeNullableInt8s(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeNullableInt8u(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeNullableOctetString(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (Data?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeNullableRangeRestrictedInt16s(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeNullableRangeRestrictedInt16u(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeNullableRangeRestrictedInt8s(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeNullableRangeRestrictedInt8u(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeNullableStruct(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (MTRTestClusterClusterSimpleStruct?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeOctetString(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (Data?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeRangeRestrictedInt16s(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeRangeRestrictedInt16u(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeRangeRestrictedInt8s(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeRangeRestrictedInt8u(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeStructAttr(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (MTRTestClusterClusterSimpleStruct?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeTimedWriteBoolean(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeUnsupported(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeVendorId(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeWriteOnlyInt8u(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func testNotHandled(completionHandler: @escaping ((any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func testNullableOptionalRequest(completionHandler: @escaping (MTRTestClusterClusterTestNullableOptionalResponseParams?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func testSimpleOptionalArgumentRequest(completionHandler: @escaping ((any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func testSpecific(completionHandler: @escaping (MTRTestClusterClusterTestSpecificResponseParams?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func testUnknownCommand(completionHandler: @escaping ((any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func test(completionHandler: @escaping ((any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func timedInvokeRequest(completionHandler: @escaping ((any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
}

open class MTRBaseClusterColorControl: MTRGenericBaseCluster {
    public init?(device: MTRBaseDevice, endpoint: UInt16, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.endpoint = NSNumber(value: endpoint)
        self.queue = queue
    }
    public init?(device: MTRBaseDevice, endpointID: NSNumber, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.endpoint = endpointID
        self.queue = queue
    }
    open func readAttributeAcceptedCommandList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeAcceptedCommandList(completionHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeAttributeList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeAttributeList(completionHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeClusterRevision(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeClusterRevision(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeColorCapabilities(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeColorCapabilities(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeColorLoopActive(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeColorLoopActive(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeColorLoopDirection(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeColorLoopDirection(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeColorLoopStartEnhancedHue(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeColorLoopStartEnhancedHue(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeColorLoopStoredEnhancedHue(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeColorLoopStoredEnhancedHue(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeColorLoopTime(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeColorLoopTime(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeColorMode(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeColorMode(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeColorPointBIntensity(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeColorPointBIntensity(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeColorPointBX(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeColorPointBX(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeColorPointBY(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeColorPointBY(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeColorPointGIntensity(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeColorPointGIntensity(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeColorPointGX(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeColorPointGX(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeColorPointGY(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeColorPointGY(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeColorPointRIntensity(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeColorPointRIntensity(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeColorPointRX(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeColorPointRX(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeColorPointRY(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeColorPointRY(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeColorTempPhysicalMaxMireds(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeColorTempPhysicalMaxMireds(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeColorTempPhysicalMinMireds(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeColorTempPhysicalMinMireds(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeColorTemperatureMireds(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeColorTemperatureMireds(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeCompensationText(completion: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeCompensationText(completionHandler: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeCoupleColorTempToLevelMinMireds(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeCoupleColorTempToLevelMinMireds(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeCurrentHue(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeCurrentHue(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeCurrentSaturation(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeCurrentSaturation(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeCurrentX(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeCurrentX(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeCurrentY(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeCurrentY(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeDriftCompensation(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeDriftCompensation(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeEnhancedColorMode(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeEnhancedColorMode(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeEnhancedCurrentHue(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeEnhancedCurrentHue(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeFeatureMap(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeFeatureMap(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeGeneratedCommandList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeGeneratedCommandList(completionHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeNumberOfPrimaries(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeNumberOfPrimaries(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeOptions(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeOptions(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributePrimary1Intensity(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributePrimary1Intensity(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributePrimary1X(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributePrimary1X(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributePrimary1Y(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributePrimary1Y(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributePrimary2Intensity(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributePrimary2Intensity(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributePrimary2X(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributePrimary2X(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributePrimary2Y(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributePrimary2Y(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributePrimary3Intensity(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributePrimary3Intensity(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributePrimary3X(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributePrimary3X(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributePrimary3Y(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributePrimary3Y(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributePrimary4Intensity(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributePrimary4Intensity(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributePrimary4X(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributePrimary4X(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributePrimary4Y(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributePrimary4Y(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributePrimary5Intensity(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributePrimary5Intensity(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributePrimary5X(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributePrimary5X(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributePrimary5Y(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributePrimary5Y(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributePrimary6Intensity(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributePrimary6Intensity(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributePrimary6X(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributePrimary6X(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributePrimary6Y(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributePrimary6Y(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeRemainingTime(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeRemainingTime(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeStartUpColorTemperatureMireds(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeStartUpColorTemperatureMireds(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeWhitePointX(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeWhitePointX(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeWhitePointY(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeWhitePointY(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func subscribeAttributeAcceptedCommandList(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAcceptedCommandList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAttributeList(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAttributeList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeClusterRevision(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeClusterRevision(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeColorCapabilities(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeColorCapabilities(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeColorLoopActive(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeColorLoopActive(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeColorLoopDirection(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeColorLoopDirection(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeColorLoopStartEnhancedHue(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeColorLoopStartEnhancedHue(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeColorLoopStoredEnhancedHue(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeColorLoopStoredEnhancedHue(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeColorLoopTime(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeColorLoopTime(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeColorMode(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeColorMode(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeColorPointBIntensity(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeColorPointBIntensity(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeColorPointBX(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeColorPointBX(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeColorPointBY(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeColorPointBY(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeColorPointGIntensity(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeColorPointGIntensity(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeColorPointGX(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeColorPointGX(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeColorPointGY(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeColorPointGY(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeColorPointRIntensity(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeColorPointRIntensity(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeColorPointRX(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeColorPointRX(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeColorPointRY(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeColorPointRY(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeColorTempPhysicalMaxMireds(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeColorTempPhysicalMaxMireds(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeColorTempPhysicalMinMireds(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeColorTempPhysicalMinMireds(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeColorTemperatureMireds(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeColorTemperatureMireds(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeCompensationText(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeCompensationText(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeCoupleColorTempToLevelMinMireds(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeCoupleColorTempToLevelMinMireds(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeCurrentHue(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeCurrentHue(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeCurrentSaturation(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeCurrentSaturation(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeCurrentX(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeCurrentX(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeCurrentY(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeCurrentY(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeDriftCompensation(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeDriftCompensation(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeEnhancedColorMode(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeEnhancedColorMode(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeEnhancedCurrentHue(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeEnhancedCurrentHue(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeFeatureMap(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeFeatureMap(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeGeneratedCommandList(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeGeneratedCommandList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeNumberOfPrimaries(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeNumberOfPrimaries(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeOptions(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeOptions(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributePrimary1Intensity(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributePrimary1Intensity(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributePrimary1X(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributePrimary1X(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributePrimary1Y(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributePrimary1Y(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributePrimary2Intensity(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributePrimary2Intensity(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributePrimary2X(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributePrimary2X(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributePrimary2Y(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributePrimary2Y(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributePrimary3Intensity(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributePrimary3Intensity(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributePrimary3X(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributePrimary3X(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributePrimary3Y(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributePrimary3Y(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributePrimary4Intensity(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributePrimary4Intensity(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributePrimary4X(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributePrimary4X(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributePrimary4Y(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributePrimary4Y(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributePrimary5Intensity(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributePrimary5Intensity(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributePrimary5X(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributePrimary5X(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributePrimary5Y(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributePrimary5Y(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributePrimary6Intensity(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributePrimary6Intensity(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributePrimary6X(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributePrimary6X(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributePrimary6Y(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributePrimary6Y(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeRemainingTime(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeRemainingTime(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeStartUpColorTemperatureMireds(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeStartUpColorTemperatureMireds(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeWhitePointX(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeWhitePointX(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeWhitePointY(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeWhitePointY(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
}

open class MTRBaseClusterThreadNetworkDiagnostics: MTRGenericBaseCluster {
    public init?(device: MTRBaseDevice, endpoint: UInt16, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.endpoint = NSNumber(value: endpoint)
        self.queue = queue
    }
    public init?(device: MTRBaseDevice, endpointID: NSNumber, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.endpoint = endpointID
        self.queue = queue
    }
    open func readAttributeAcceptedCommandList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeAcceptedCommandList(completionHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeActiveNetworkFaultsList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeActiveNetworkFaultsList(completionHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeActiveTimestamp(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeActiveTimestamp(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeAttachAttemptCount(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeAttachAttemptCount(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeAttributeList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeAttributeList(completionHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeBetterPartitionAttachAttemptCount(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeBetterPartitionAttachAttemptCount(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeChannelPage0Mask(completion: @escaping (Data?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeChannelPage0Mask(completionHandler: @escaping (Data?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeChannel(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeChannel(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeChildRoleCount(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeChildRoleCount(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeClusterRevision(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeClusterRevision(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeDataVersion(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeDataVersion(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeDelay(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeDelay(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeDetachedRoleCount(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeDetachedRoleCount(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeExtendedPanId(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeExtendedPanId(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeFeatureMap(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeFeatureMap(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeGeneratedCommandList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeGeneratedCommandList(completionHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeLeaderRoleCount(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeLeaderRoleCount(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeLeaderRouterId(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeLeaderRouterId(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeMeshLocalPrefix(completion: @escaping (Data?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeMeshLocalPrefix(completionHandler: @escaping (Data?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeNeighborTableList(completionHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeNeighborTable(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeNetworkName(completion: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeNetworkName(completionHandler: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeOperationalDatasetComponents(completion: @escaping (MTRThreadNetworkDiagnosticsClusterOperationalDatasetComponents?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeOperationalDatasetComponents(completionHandler: @escaping (MTRThreadNetworkDiagnosticsClusterOperationalDatasetComponents?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeOverrunCount(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeOverrunCount(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributePanId(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributePanId(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeParentChangeCount(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeParentChangeCount(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributePartitionIdChangeCount(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributePartitionIdChangeCount(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributePartitionId(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributePartitionId(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributePendingTimestamp(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributePendingTimestamp(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeRouteTableList(completionHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeRouteTable(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeRouterRoleCount(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeRouterRoleCount(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeRoutingRole(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeRoutingRole(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeRxAddressFilteredCount(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeRxAddressFilteredCount(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeRxBeaconCount(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeRxBeaconCount(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeRxBeaconRequestCount(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeRxBeaconRequestCount(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeRxBroadcastCount(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeRxBroadcastCount(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeRxDataCount(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeRxDataCount(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeRxDataPollCount(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeRxDataPollCount(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeRxDestAddrFilteredCount(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeRxDestAddrFilteredCount(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeRxDuplicatedCount(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeRxDuplicatedCount(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeRxErrFcsCount(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeRxErrFcsCount(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeRxErrInvalidSrcAddrCount(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeRxErrInvalidSrcAddrCount(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeRxErrNoFrameCount(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeRxErrNoFrameCount(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeRxErrOtherCount(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeRxErrOtherCount(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeRxErrSecCount(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeRxErrSecCount(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeRxErrUnknownNeighborCount(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeRxErrUnknownNeighborCount(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeRxOtherCount(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeRxOtherCount(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeRxTotalCount(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeRxTotalCount(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeRxUnicastCount(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeRxUnicastCount(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeSecurityPolicy(completion: @escaping (MTRThreadNetworkDiagnosticsClusterSecurityPolicy?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeSecurityPolicy(completionHandler: @escaping (MTRThreadNetworkDiagnosticsClusterSecurityPolicy?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeStableDataVersion(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeStableDataVersion(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeTxAckRequestedCount(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeTxAckRequestedCount(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeTxAckedCount(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeTxAckedCount(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeTxBeaconCount(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeTxBeaconCount(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeTxBeaconRequestCount(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeTxBeaconRequestCount(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeTxBroadcastCount(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeTxBroadcastCount(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeTxDataCount(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeTxDataCount(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeTxDataPollCount(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeTxDataPollCount(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeTxDirectMaxRetryExpiryCount(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeTxDirectMaxRetryExpiryCount(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeTxErrAbortCount(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeTxErrAbortCount(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeTxErrBusyChannelCount(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeTxErrBusyChannelCount(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeTxErrCcaCount(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeTxErrCcaCount(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeTxIndirectMaxRetryExpiryCount(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeTxIndirectMaxRetryExpiryCount(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeTxNoAckRequestedCount(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeTxNoAckRequestedCount(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeTxOtherCount(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeTxOtherCount(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeTxRetryCount(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeTxRetryCount(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeTxTotalCount(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeTxTotalCount(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeTxUnicastCount(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeTxUnicastCount(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeWeighting(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeWeighting(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func resetCounts(completion: @escaping ((any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func resetCounts(completionHandler: @escaping ((any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func subscribeAttributeAcceptedCommandList(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAcceptedCommandList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeActiveNetworkFaultsList(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeActiveNetworkFaultsList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeActiveTimestamp(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeActiveTimestamp(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAttachAttemptCount(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAttachAttemptCount(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAttributeList(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAttributeList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeBetterPartitionAttachAttemptCount(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeBetterPartitionAttachAttemptCount(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeChannelPage0Mask(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (Data?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeChannelPage0Mask(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (Data?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeChannel(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeChannel(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeChildRoleCount(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeChildRoleCount(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeClusterRevision(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeClusterRevision(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeDataVersion(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeDataVersion(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeDelay(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeDelay(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeDetachedRoleCount(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeDetachedRoleCount(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeExtendedPanId(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeExtendedPanId(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeFeatureMap(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeFeatureMap(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeGeneratedCommandList(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeGeneratedCommandList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeLeaderRoleCount(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeLeaderRoleCount(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeLeaderRouterId(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeLeaderRouterId(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeMeshLocalPrefix(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (Data?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeMeshLocalPrefix(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (Data?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeNeighborTableList(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeNeighborTable(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeNetworkName(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeNetworkName(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeOperationalDatasetComponents(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (MTRThreadNetworkDiagnosticsClusterOperationalDatasetComponents?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeOperationalDatasetComponents(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (MTRThreadNetworkDiagnosticsClusterOperationalDatasetComponents?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeOverrunCount(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeOverrunCount(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributePanId(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributePanId(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeParentChangeCount(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeParentChangeCount(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributePartitionIdChangeCount(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributePartitionIdChangeCount(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributePartitionId(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributePartitionId(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributePendingTimestamp(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributePendingTimestamp(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeRouteTableList(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeRouteTable(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeRouterRoleCount(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeRouterRoleCount(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeRoutingRole(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeRoutingRole(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeRxAddressFilteredCount(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeRxAddressFilteredCount(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeRxBeaconCount(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeRxBeaconCount(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeRxBeaconRequestCount(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeRxBeaconRequestCount(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeRxBroadcastCount(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeRxBroadcastCount(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeRxDataCount(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeRxDataCount(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeRxDataPollCount(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeRxDataPollCount(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeRxDestAddrFilteredCount(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeRxDestAddrFilteredCount(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeRxDuplicatedCount(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeRxDuplicatedCount(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeRxErrFcsCount(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeRxErrFcsCount(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeRxErrInvalidSrcAddrCount(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeRxErrInvalidSrcAddrCount(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeRxErrNoFrameCount(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeRxErrNoFrameCount(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeRxErrOtherCount(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeRxErrOtherCount(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeRxErrSecCount(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeRxErrSecCount(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeRxErrUnknownNeighborCount(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeRxErrUnknownNeighborCount(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeRxOtherCount(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeRxOtherCount(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeRxTotalCount(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeRxTotalCount(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeRxUnicastCount(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeRxUnicastCount(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeSecurityPolicy(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (MTRThreadNetworkDiagnosticsClusterSecurityPolicy?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeSecurityPolicy(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (MTRThreadNetworkDiagnosticsClusterSecurityPolicy?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeStableDataVersion(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeStableDataVersion(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeTxAckRequestedCount(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeTxAckRequestedCount(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeTxAckedCount(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeTxAckedCount(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeTxBeaconCount(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeTxBeaconCount(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeTxBeaconRequestCount(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeTxBeaconRequestCount(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeTxBroadcastCount(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeTxBroadcastCount(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeTxDataCount(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeTxDataCount(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeTxDataPollCount(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeTxDataPollCount(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeTxDirectMaxRetryExpiryCount(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeTxDirectMaxRetryExpiryCount(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeTxErrAbortCount(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeTxErrAbortCount(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeTxErrBusyChannelCount(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeTxErrBusyChannelCount(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeTxErrCcaCount(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeTxErrCcaCount(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeTxIndirectMaxRetryExpiryCount(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeTxIndirectMaxRetryExpiryCount(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeTxNoAckRequestedCount(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeTxNoAckRequestedCount(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeTxOtherCount(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeTxOtherCount(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeTxRetryCount(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeTxRetryCount(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeTxTotalCount(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeTxTotalCount(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeTxUnicastCount(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeTxUnicastCount(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeWeighting(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeWeighting(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
}

open class MTRBaseClusterDoorLock: MTRGenericBaseCluster {
    open func clearAliroReaderConfig(completion: @escaping ((any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func getHolidaySchedule(with params: MTRDoorLockClusterGetHolidayScheduleParams, completion: @escaping (MTRDoorLockClusterGetHolidayScheduleResponseParams?, (any Error)?) -> Void)
    {
        _ = (params, completion)
        mtrFailClosed(completion)
    }
    open func getHolidaySchedule(with params: MTRDoorLockClusterGetHolidayScheduleParams, completionHandler: @escaping (MTRDoorLockClusterGetHolidayScheduleResponseParams?, (any Error)?) -> Void)
    {
        _ = (params, completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func getUserWith(_ params: MTRDoorLockClusterGetUserParams, completion: @escaping (MTRDoorLockClusterGetUserResponseParams?, (any Error)?) -> Void)
    {
        _ = (params, completion)
        mtrFailClosed(completion)
    }
    open func getUserWith(_ params: MTRDoorLockClusterGetUserParams, completionHandler: @escaping (MTRDoorLockClusterGetUserResponseParams?, (any Error)?) -> Void)
    {
        _ = (params, completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func getWeekDaySchedule(with params: MTRDoorLockClusterGetWeekDayScheduleParams, completion: @escaping (MTRDoorLockClusterGetWeekDayScheduleResponseParams?, (any Error)?) -> Void)
    {
        _ = (params, completion)
        mtrFailClosed(completion)
    }
    open func getWeekDaySchedule(with params: MTRDoorLockClusterGetWeekDayScheduleParams, completionHandler: @escaping (MTRDoorLockClusterGetWeekDayScheduleResponseParams?, (any Error)?) -> Void)
    {
        _ = (params, completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func getYearDaySchedule(with params: MTRDoorLockClusterGetYearDayScheduleParams, completion: @escaping (MTRDoorLockClusterGetYearDayScheduleResponseParams?, (any Error)?) -> Void)
    {
        _ = (params, completion)
        mtrFailClosed(completion)
    }
    open func getYearDaySchedule(with params: MTRDoorLockClusterGetYearDayScheduleParams, completionHandler: @escaping (MTRDoorLockClusterGetYearDayScheduleResponseParams?, (any Error)?) -> Void)
    {
        _ = (params, completionHandler)
        mtrFailClosed(completionHandler)
    }
    public init?(device: MTRBaseDevice, endpoint: UInt16, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.endpoint = NSNumber(value: endpoint)
        self.queue = queue
    }
    public init?(device: MTRBaseDevice, endpointID: NSNumber, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.endpoint = endpointID
        self.queue = queue
    }
    open func lockDoor(completion: @escaping ((any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeAcceptedCommandList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeAcceptedCommandList(completionHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeActuatorEnabled(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeActuatorEnabled(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeAliroBLEAdvertisingVersion(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeAliroExpeditedTransactionSupportedProtocolVersions(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeAliroGroupResolvingKey(completion: @escaping (Data?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeAliroReaderGroupIdentifier(completion: @escaping (Data?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeAliroReaderGroupSubIdentifier(completion: @escaping (Data?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeAliroReaderVerificationKey(completion: @escaping (Data?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeAliroSupportedBLEUWBProtocolVersions(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeAttributeList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeAttributeList(completionHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeAutoRelockTime(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeAutoRelockTime(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeClusterRevision(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeClusterRevision(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeCredentialRulesSupport(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeCredentialRulesSupport(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeDefaultConfigurationRegister(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeDefaultConfigurationRegister(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeDoorClosedEvents(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeDoorClosedEvents(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeDoorOpenEvents(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeDoorOpenEvents(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeDoorState(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeDoorState(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeEnableInsideStatusLED(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeEnableInsideStatusLED(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeEnableLocalProgramming(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeEnableLocalProgramming(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeEnableOneTouchLocking(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeEnableOneTouchLocking(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeEnablePrivacyModeButton(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeEnablePrivacyModeButton(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeExpiringUserTimeout(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeExpiringUserTimeout(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeFeatureMap(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeFeatureMap(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeGeneratedCommandList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeGeneratedCommandList(completionHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeLEDSettings(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeLEDSettings(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeLanguage(completion: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeLanguage(completionHandler: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeLocalProgrammingFeatures(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeLocalProgrammingFeatures(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeLockState(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeLockState(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeLockType(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeLockType(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeMaxPINCodeLength(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeMaxPINCodeLength(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeMaxRFIDCodeLength(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeMaxRFIDCodeLength(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeMinPINCodeLength(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeMinPINCodeLength(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeMinRFIDCodeLength(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeMinRFIDCodeLength(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeNumberOfAliroCredentialIssuerKeysSupported(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeNumberOfAliroEndpointKeysSupported(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeNumberOfCredentialsSupportedPerUser(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeNumberOfCredentialsSupportedPerUser(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeNumberOfHolidaySchedulesSupported(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeNumberOfHolidaySchedulesSupported(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeNumberOfPINUsersSupported(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeNumberOfPINUsersSupported(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeNumberOfRFIDUsersSupported(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeNumberOfRFIDUsersSupported(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeNumberOfTotalUsersSupported(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeNumberOfTotalUsersSupported(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeNumberOfWeekDaySchedulesSupportedPerUser(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeNumberOfWeekDaySchedulesSupportedPerUser(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeNumberOfYearDaySchedulesSupportedPerUser(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeNumberOfYearDaySchedulesSupportedPerUser(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeOpenPeriod(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeOpenPeriod(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeOperatingMode(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeOperatingMode(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeRequirePINforRemoteOperation(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeRequirePINforRemoteOperation(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeSendPINOverTheAir(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeSendPINOverTheAir(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeSoundVolume(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeSoundVolume(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeSupportedOperatingModes(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeSupportedOperatingModes(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeUserCodeTemporaryDisableTime(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeUserCodeTemporaryDisableTime(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeWrongCodeEntryLimit(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeWrongCodeEntryLimit(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func subscribeAttributeAcceptedCommandList(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAcceptedCommandList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeActuatorEnabled(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeActuatorEnabled(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAliroBLEAdvertisingVersion(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAliroExpeditedTransactionSupportedProtocolVersions(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAliroGroupResolvingKey(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (Data?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAliroReaderGroupIdentifier(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (Data?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAliroReaderGroupSubIdentifier(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (Data?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAliroReaderVerificationKey(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (Data?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAliroSupportedBLEUWBProtocolVersions(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAttributeList(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAttributeList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAutoRelockTime(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAutoRelockTime(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeClusterRevision(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeClusterRevision(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeCredentialRulesSupport(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeCredentialRulesSupport(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeDefaultConfigurationRegister(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeDefaultConfigurationRegister(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeDoorClosedEvents(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeDoorClosedEvents(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeDoorOpenEvents(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeDoorOpenEvents(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeDoorState(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeDoorState(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeEnableInsideStatusLED(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeEnableInsideStatusLED(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeEnableLocalProgramming(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeEnableLocalProgramming(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeEnableOneTouchLocking(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeEnableOneTouchLocking(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeEnablePrivacyModeButton(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeEnablePrivacyModeButton(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeExpiringUserTimeout(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeExpiringUserTimeout(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeFeatureMap(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeFeatureMap(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeGeneratedCommandList(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeGeneratedCommandList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeLEDSettings(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeLEDSettings(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeLanguage(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeLanguage(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeLocalProgrammingFeatures(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeLocalProgrammingFeatures(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeLockState(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeLockState(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeLockType(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeLockType(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeMaxPINCodeLength(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeMaxPINCodeLength(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeMaxRFIDCodeLength(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeMaxRFIDCodeLength(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeMinPINCodeLength(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeMinPINCodeLength(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeMinRFIDCodeLength(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeMinRFIDCodeLength(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeNumberOfAliroCredentialIssuerKeysSupported(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeNumberOfAliroEndpointKeysSupported(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeNumberOfCredentialsSupportedPerUser(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeNumberOfCredentialsSupportedPerUser(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeNumberOfHolidaySchedulesSupported(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeNumberOfHolidaySchedulesSupported(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeNumberOfPINUsersSupported(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeNumberOfPINUsersSupported(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeNumberOfRFIDUsersSupported(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeNumberOfRFIDUsersSupported(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeNumberOfTotalUsersSupported(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeNumberOfTotalUsersSupported(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeNumberOfWeekDaySchedulesSupportedPerUser(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeNumberOfWeekDaySchedulesSupportedPerUser(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeNumberOfYearDaySchedulesSupportedPerUser(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeNumberOfYearDaySchedulesSupportedPerUser(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeOpenPeriod(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeOpenPeriod(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeOperatingMode(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeOperatingMode(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeRequirePINforRemoteOperation(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeRequirePINforRemoteOperation(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeSendPINOverTheAir(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeSendPINOverTheAir(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeSoundVolume(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeSoundVolume(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeSupportedOperatingModes(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeSupportedOperatingModes(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeUserCodeTemporaryDisableTime(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeUserCodeTemporaryDisableTime(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeWrongCodeEntryLimit(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeWrongCodeEntryLimit(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func unboltDoor(completion: @escaping ((any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func unlockDoor(completion: @escaping ((any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
}

open class MTRClusterUnitTesting: MTRGenericCluster {
    public init?(device: MTRDevice, endpointID: NSNumber, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.endpoint = endpointID
        self.queue = queue
    }
    open func readAttributeAcceptedCommandList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("AcceptedCommandList", params: params)
    }
    open func readAttributeAttributeList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("AttributeList", params: params)
    }
    open func readAttributeBitmap16(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("Bitmap16", params: params)
    }
    open func readAttributeBitmap32(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("Bitmap32", params: params)
    }
    open func readAttributeBitmap64(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("Bitmap64", params: params)
    }
    open func readAttributeBitmap8(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("Bitmap8", params: params)
    }
    open func readAttributeBoolean(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("Boolean", params: params)
    }
    open func readAttributeCharString(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("CharString", params: params)
    }
    open func readAttributeClusterErrorBoolean(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("ClusterErrorBoolean", params: params)
    }
    open func readAttributeClusterRevision(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("ClusterRevision", params: params)
    }
    open func readAttributeEnum16(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("Enum16", params: params)
    }
    open func readAttributeEnum8(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("Enum8", params: params)
    }
    open func readAttributeEnumAttr(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("EnumAttr", params: params)
    }
    open func readAttributeEpochS(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("EpochS", params: params)
    }
    open func readAttributeEpochUs(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("EpochUs", params: params)
    }
    open func readAttributeFeatureMap(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("FeatureMap", params: params)
    }
    open func readAttributeFloatDouble(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("FloatDouble", params: params)
    }
    open func readAttributeFloatSingle(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("FloatSingle", params: params)
    }
    open func readAttributeGeneralErrorBoolean(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("GeneralErrorBoolean", params: params)
    }
    open func readAttributeGeneratedCommandList(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("GeneratedCommandList", params: params)
    }
    open func readAttributeInt16s(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("Int16s", params: params)
    }
    open func readAttributeInt16u(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("Int16u", params: params)
    }
    open func readAttributeInt24s(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("Int24s", params: params)
    }
    open func readAttributeInt24u(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("Int24u", params: params)
    }
    open func readAttributeInt32s(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("Int32s", params: params)
    }
    open func readAttributeInt32u(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("Int32u", params: params)
    }
    open func readAttributeInt40s(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("Int40s", params: params)
    }
    open func readAttributeInt40u(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("Int40u", params: params)
    }
    open func readAttributeInt48s(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("Int48s", params: params)
    }
    open func readAttributeInt48u(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("Int48u", params: params)
    }
    open func readAttributeInt56s(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("Int56s", params: params)
    }
    open func readAttributeInt56u(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("Int56u", params: params)
    }
    open func readAttributeInt64s(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("Int64s", params: params)
    }
    open func readAttributeInt64u(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("Int64u", params: params)
    }
    open func readAttributeInt8s(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("Int8s", params: params)
    }
    open func readAttributeInt8u(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("Int8u", params: params)
    }
    open func readAttributeListFabricScoped(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("ListFabricScoped", params: params)
    }
    open func readAttributeListInt8u(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("ListInt8u", params: params)
    }
    open func readAttributeListLongOctetString(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("ListLongOctetString", params: params)
    }
    open func readAttributeListNullablesAndOptionalsStruct(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("ListNullablesAndOptionalsStruct", params: params)
    }
    open func readAttributeListOctetString(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("ListOctetString", params: params)
    }
    open func readAttributeListStructOctetString(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("ListStructOctetString", params: params)
    }
    open func readAttributeLongCharString(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("LongCharString", params: params)
    }
    open func readAttributeLongOctetString(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("LongOctetString", params: params)
    }
    open func readAttributeNullableBitmap16(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("NullableBitmap16", params: params)
    }
    open func readAttributeNullableBitmap32(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("NullableBitmap32", params: params)
    }
    open func readAttributeNullableBitmap64(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("NullableBitmap64", params: params)
    }
    open func readAttributeNullableBitmap8(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("NullableBitmap8", params: params)
    }
    open func readAttributeNullableBoolean(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("NullableBoolean", params: params)
    }
    open func readAttributeNullableCharString(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("NullableCharString", params: params)
    }
    open func readAttributeNullableEnum16(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("NullableEnum16", params: params)
    }
    open func readAttributeNullableEnum8(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("NullableEnum8", params: params)
    }
    open func readAttributeNullableEnumAttr(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("NullableEnumAttr", params: params)
    }
    open func readAttributeNullableFloatDouble(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("NullableFloatDouble", params: params)
    }
    open func readAttributeNullableFloatSingle(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("NullableFloatSingle", params: params)
    }
    open func readAttributeNullableInt16s(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("NullableInt16s", params: params)
    }
    open func readAttributeNullableInt16u(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("NullableInt16u", params: params)
    }
    open func readAttributeNullableInt24s(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("NullableInt24s", params: params)
    }
    open func readAttributeNullableInt24u(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("NullableInt24u", params: params)
    }
    open func readAttributeNullableInt32s(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("NullableInt32s", params: params)
    }
    open func readAttributeNullableInt32u(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("NullableInt32u", params: params)
    }
    open func readAttributeNullableInt40s(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("NullableInt40s", params: params)
    }
    open func readAttributeNullableInt40u(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("NullableInt40u", params: params)
    }
    open func readAttributeNullableInt48s(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("NullableInt48s", params: params)
    }
    open func readAttributeNullableInt48u(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("NullableInt48u", params: params)
    }
    open func readAttributeNullableInt56s(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("NullableInt56s", params: params)
    }
    open func readAttributeNullableInt56u(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("NullableInt56u", params: params)
    }
    open func readAttributeNullableInt64s(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("NullableInt64s", params: params)
    }
    open func readAttributeNullableInt64u(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("NullableInt64u", params: params)
    }
    open func readAttributeNullableInt8s(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("NullableInt8s", params: params)
    }
    open func readAttributeNullableInt8u(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("NullableInt8u", params: params)
    }
    open func readAttributeNullableOctetString(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("NullableOctetString", params: params)
    }
    open func readAttributeNullableRangeRestrictedInt16s(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("NullableRangeRestrictedInt16s", params: params)
    }
    open func readAttributeNullableRangeRestrictedInt16u(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("NullableRangeRestrictedInt16u", params: params)
    }
    open func readAttributeNullableRangeRestrictedInt8s(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("NullableRangeRestrictedInt8s", params: params)
    }
    open func readAttributeNullableRangeRestrictedInt8u(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("NullableRangeRestrictedInt8u", params: params)
    }
    open func readAttributeNullableStruct(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("NullableStruct", params: params)
    }
    open func readAttributeOctetString(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("OctetString", params: params)
    }
    open func readAttributeRangeRestrictedInt16s(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("RangeRestrictedInt16s", params: params)
    }
    open func readAttributeRangeRestrictedInt16u(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("RangeRestrictedInt16u", params: params)
    }
    open func readAttributeRangeRestrictedInt8s(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("RangeRestrictedInt8s", params: params)
    }
    open func readAttributeRangeRestrictedInt8u(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("RangeRestrictedInt8u", params: params)
    }
    open func readAttributeStructAttr(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("StructAttr", params: params)
    }
    open func readAttributeTimedWriteBoolean(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("TimedWriteBoolean", params: params)
    }
    open func readAttributeUnsupported(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("Unsupported", params: params)
    }
    open func readAttributeVendorId(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("VendorId", params: params)
    }
    open func readAttributeWriteOnlyInt8u(with params: MTRReadParams?) -> [String : Any]?
    {
        _ = (params)
        return mtrHostRead("WriteOnlyInt8u", params: params)
    }
    open func writeAttributeBitmap16(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber)
    {
        _ = (dataValueDictionary, expectedValueIntervalMs)
        mtrHostWrite("Bitmap16", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: nil)
    }
    open func writeAttributeBitmap16(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber, params: MTRWriteParams?)
    {
        _ = (dataValueDictionary, expectedValueIntervalMs, params)
        mtrHostWrite("Bitmap16", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: params)
    }
    open func writeAttributeBitmap32(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber)
    {
        _ = (dataValueDictionary, expectedValueIntervalMs)
        mtrHostWrite("Bitmap32", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: nil)
    }
    open func writeAttributeBitmap32(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber, params: MTRWriteParams?)
    {
        _ = (dataValueDictionary, expectedValueIntervalMs, params)
        mtrHostWrite("Bitmap32", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: params)
    }
    open func writeAttributeBitmap64(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber)
    {
        _ = (dataValueDictionary, expectedValueIntervalMs)
        mtrHostWrite("Bitmap64", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: nil)
    }
    open func writeAttributeBitmap64(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber, params: MTRWriteParams?)
    {
        _ = (dataValueDictionary, expectedValueIntervalMs, params)
        mtrHostWrite("Bitmap64", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: params)
    }
    open func writeAttributeBitmap8(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber)
    {
        _ = (dataValueDictionary, expectedValueIntervalMs)
        mtrHostWrite("Bitmap8", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: nil)
    }
    open func writeAttributeBitmap8(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber, params: MTRWriteParams?)
    {
        _ = (dataValueDictionary, expectedValueIntervalMs, params)
        mtrHostWrite("Bitmap8", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: params)
    }
    open func writeAttributeBoolean(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber)
    {
        _ = (dataValueDictionary, expectedValueIntervalMs)
        mtrHostWrite("Boolean", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: nil)
    }
    open func writeAttributeBoolean(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber, params: MTRWriteParams?)
    {
        _ = (dataValueDictionary, expectedValueIntervalMs, params)
        mtrHostWrite("Boolean", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: params)
    }
    open func writeAttributeCharString(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber)
    {
        _ = (dataValueDictionary, expectedValueIntervalMs)
        mtrHostWrite("CharString", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: nil)
    }
    open func writeAttributeCharString(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber, params: MTRWriteParams?)
    {
        _ = (dataValueDictionary, expectedValueIntervalMs, params)
        mtrHostWrite("CharString", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: params)
    }
    open func writeAttributeClusterErrorBoolean(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber)
    {
        _ = (dataValueDictionary, expectedValueIntervalMs)
        mtrHostWrite("ClusterErrorBoolean", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: nil)
    }
    open func writeAttributeClusterErrorBoolean(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber, params: MTRWriteParams?)
    {
        _ = (dataValueDictionary, expectedValueIntervalMs, params)
        mtrHostWrite("ClusterErrorBoolean", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: params)
    }
    open func writeAttributeEnum16(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber)
    {
        _ = (dataValueDictionary, expectedValueIntervalMs)
        mtrHostWrite("Enum16", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: nil)
    }
    open func writeAttributeEnum16(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber, params: MTRWriteParams?)
    {
        _ = (dataValueDictionary, expectedValueIntervalMs, params)
        mtrHostWrite("Enum16", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: params)
    }
    open func writeAttributeEnum8(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber)
    {
        _ = (dataValueDictionary, expectedValueIntervalMs)
        mtrHostWrite("Enum8", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: nil)
    }
    open func writeAttributeEnum8(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber, params: MTRWriteParams?)
    {
        _ = (dataValueDictionary, expectedValueIntervalMs, params)
        mtrHostWrite("Enum8", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: params)
    }
    open func writeAttributeEnumAttr(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber)
    {
        _ = (dataValueDictionary, expectedValueIntervalMs)
        mtrHostWrite("EnumAttr", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: nil)
    }
    open func writeAttributeEnumAttr(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber, params: MTRWriteParams?)
    {
        _ = (dataValueDictionary, expectedValueIntervalMs, params)
        mtrHostWrite("EnumAttr", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: params)
    }
    open func writeAttributeEpochS(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber)
    {
        _ = (dataValueDictionary, expectedValueIntervalMs)
        mtrHostWrite("EpochS", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: nil)
    }
    open func writeAttributeEpochS(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber, params: MTRWriteParams?)
    {
        _ = (dataValueDictionary, expectedValueIntervalMs, params)
        mtrHostWrite("EpochS", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: params)
    }
    open func writeAttributeEpochUs(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber)
    {
        _ = (dataValueDictionary, expectedValueIntervalMs)
        mtrHostWrite("EpochUs", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: nil)
    }
    open func writeAttributeEpochUs(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber, params: MTRWriteParams?)
    {
        _ = (dataValueDictionary, expectedValueIntervalMs, params)
        mtrHostWrite("EpochUs", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: params)
    }
    open func writeAttributeFloatDouble(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber)
    {
        _ = (dataValueDictionary, expectedValueIntervalMs)
        mtrHostWrite("FloatDouble", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: nil)
    }
    open func writeAttributeFloatDouble(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber, params: MTRWriteParams?)
    {
        _ = (dataValueDictionary, expectedValueIntervalMs, params)
        mtrHostWrite("FloatDouble", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: params)
    }
    open func writeAttributeFloatSingle(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber)
    {
        _ = (dataValueDictionary, expectedValueIntervalMs)
        mtrHostWrite("FloatSingle", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: nil)
    }
    open func writeAttributeFloatSingle(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber, params: MTRWriteParams?)
    {
        _ = (dataValueDictionary, expectedValueIntervalMs, params)
        mtrHostWrite("FloatSingle", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: params)
    }
    open func writeAttributeGeneralErrorBoolean(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber)
    {
        _ = (dataValueDictionary, expectedValueIntervalMs)
        mtrHostWrite("GeneralErrorBoolean", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: nil)
    }
    open func writeAttributeGeneralErrorBoolean(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber, params: MTRWriteParams?)
    {
        _ = (dataValueDictionary, expectedValueIntervalMs, params)
        mtrHostWrite("GeneralErrorBoolean", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: params)
    }
    open func writeAttributeInt16s(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber)
    {
        _ = (dataValueDictionary, expectedValueIntervalMs)
        mtrHostWrite("Int16s", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: nil)
    }
    open func writeAttributeInt16s(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber, params: MTRWriteParams?)
    {
        _ = (dataValueDictionary, expectedValueIntervalMs, params)
        mtrHostWrite("Int16s", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: params)
    }
    open func writeAttributeInt16u(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber)
    {
        _ = (dataValueDictionary, expectedValueIntervalMs)
        mtrHostWrite("Int16u", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: nil)
    }
    open func writeAttributeInt16u(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber, params: MTRWriteParams?)
    {
        _ = (dataValueDictionary, expectedValueIntervalMs, params)
        mtrHostWrite("Int16u", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: params)
    }
    open func writeAttributeInt24s(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber)
    {
        _ = (dataValueDictionary, expectedValueIntervalMs)
        mtrHostWrite("Int24s", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: nil)
    }
    open func writeAttributeInt24s(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber, params: MTRWriteParams?)
    {
        _ = (dataValueDictionary, expectedValueIntervalMs, params)
        mtrHostWrite("Int24s", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: params)
    }
    open func writeAttributeInt24u(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber)
    {
        _ = (dataValueDictionary, expectedValueIntervalMs)
        mtrHostWrite("Int24u", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: nil)
    }
    open func writeAttributeInt24u(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber, params: MTRWriteParams?)
    {
        _ = (dataValueDictionary, expectedValueIntervalMs, params)
        mtrHostWrite("Int24u", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: params)
    }
    open func writeAttributeInt32s(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber)
    {
        _ = (dataValueDictionary, expectedValueIntervalMs)
        mtrHostWrite("Int32s", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: nil)
    }
    open func writeAttributeInt32s(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber, params: MTRWriteParams?)
    {
        _ = (dataValueDictionary, expectedValueIntervalMs, params)
        mtrHostWrite("Int32s", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: params)
    }
    open func writeAttributeInt32u(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber)
    {
        _ = (dataValueDictionary, expectedValueIntervalMs)
        mtrHostWrite("Int32u", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: nil)
    }
    open func writeAttributeInt32u(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber, params: MTRWriteParams?)
    {
        _ = (dataValueDictionary, expectedValueIntervalMs, params)
        mtrHostWrite("Int32u", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: params)
    }
    open func writeAttributeInt40s(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber)
    {
        _ = (dataValueDictionary, expectedValueIntervalMs)
        mtrHostWrite("Int40s", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: nil)
    }
    open func writeAttributeInt40s(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber, params: MTRWriteParams?)
    {
        _ = (dataValueDictionary, expectedValueIntervalMs, params)
        mtrHostWrite("Int40s", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: params)
    }
    open func writeAttributeInt40u(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber)
    {
        _ = (dataValueDictionary, expectedValueIntervalMs)
        mtrHostWrite("Int40u", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: nil)
    }
    open func writeAttributeInt40u(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber, params: MTRWriteParams?)
    {
        _ = (dataValueDictionary, expectedValueIntervalMs, params)
        mtrHostWrite("Int40u", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: params)
    }
    open func writeAttributeInt48s(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber)
    {
        _ = (dataValueDictionary, expectedValueIntervalMs)
        mtrHostWrite("Int48s", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: nil)
    }
    open func writeAttributeInt48s(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber, params: MTRWriteParams?)
    {
        _ = (dataValueDictionary, expectedValueIntervalMs, params)
        mtrHostWrite("Int48s", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: params)
    }
    open func writeAttributeInt48u(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber)
    {
        _ = (dataValueDictionary, expectedValueIntervalMs)
        mtrHostWrite("Int48u", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: nil)
    }
    open func writeAttributeInt48u(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber, params: MTRWriteParams?)
    {
        _ = (dataValueDictionary, expectedValueIntervalMs, params)
        mtrHostWrite("Int48u", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: params)
    }
    open func writeAttributeInt56s(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber)
    {
        _ = (dataValueDictionary, expectedValueIntervalMs)
        mtrHostWrite("Int56s", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: nil)
    }
    open func writeAttributeInt56s(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber, params: MTRWriteParams?)
    {
        _ = (dataValueDictionary, expectedValueIntervalMs, params)
        mtrHostWrite("Int56s", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: params)
    }
    open func writeAttributeInt56u(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber)
    {
        _ = (dataValueDictionary, expectedValueIntervalMs)
        mtrHostWrite("Int56u", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: nil)
    }
    open func writeAttributeInt56u(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber, params: MTRWriteParams?)
    {
        _ = (dataValueDictionary, expectedValueIntervalMs, params)
        mtrHostWrite("Int56u", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: params)
    }
    open func writeAttributeInt64s(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber)
    {
        _ = (dataValueDictionary, expectedValueIntervalMs)
        mtrHostWrite("Int64s", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: nil)
    }
    open func writeAttributeInt64s(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber, params: MTRWriteParams?)
    {
        _ = (dataValueDictionary, expectedValueIntervalMs, params)
        mtrHostWrite("Int64s", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: params)
    }
    open func writeAttributeInt64u(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber)
    {
        _ = (dataValueDictionary, expectedValueIntervalMs)
        mtrHostWrite("Int64u", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: nil)
    }
    open func writeAttributeInt64u(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber, params: MTRWriteParams?)
    {
        _ = (dataValueDictionary, expectedValueIntervalMs, params)
        mtrHostWrite("Int64u", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: params)
    }
    open func writeAttributeInt8s(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber)
    {
        _ = (dataValueDictionary, expectedValueIntervalMs)
        mtrHostWrite("Int8s", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: nil)
    }
    open func writeAttributeInt8s(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber, params: MTRWriteParams?)
    {
        _ = (dataValueDictionary, expectedValueIntervalMs, params)
        mtrHostWrite("Int8s", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: params)
    }
    open func writeAttributeInt8u(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber)
    {
        _ = (dataValueDictionary, expectedValueIntervalMs)
        mtrHostWrite("Int8u", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: nil)
    }
    open func writeAttributeInt8u(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber, params: MTRWriteParams?)
    {
        _ = (dataValueDictionary, expectedValueIntervalMs, params)
        mtrHostWrite("Int8u", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: params)
    }
    open func writeAttributeListFabricScoped(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber)
    {
        _ = (dataValueDictionary, expectedValueIntervalMs)
        mtrHostWrite("ListFabricScoped", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: nil)
    }
    open func writeAttributeListFabricScoped(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber, params: MTRWriteParams?)
    {
        _ = (dataValueDictionary, expectedValueIntervalMs, params)
        mtrHostWrite("ListFabricScoped", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: params)
    }
    open func writeAttributeListInt8u(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber)
    {
        _ = (dataValueDictionary, expectedValueIntervalMs)
        mtrHostWrite("ListInt8u", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: nil)
    }
    open func writeAttributeListInt8u(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber, params: MTRWriteParams?)
    {
        _ = (dataValueDictionary, expectedValueIntervalMs, params)
        mtrHostWrite("ListInt8u", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: params)
    }
    open func writeAttributeListLongOctetString(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber)
    {
        _ = (dataValueDictionary, expectedValueIntervalMs)
        mtrHostWrite("ListLongOctetString", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: nil)
    }
    open func writeAttributeListLongOctetString(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber, params: MTRWriteParams?)
    {
        _ = (dataValueDictionary, expectedValueIntervalMs, params)
        mtrHostWrite("ListLongOctetString", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: params)
    }
    open func writeAttributeListNullablesAndOptionalsStruct(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber)
    {
        _ = (dataValueDictionary, expectedValueIntervalMs)
        mtrHostWrite("ListNullablesAndOptionalsStruct", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: nil)
    }
    open func writeAttributeListNullablesAndOptionalsStruct(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber, params: MTRWriteParams?)
    {
        _ = (dataValueDictionary, expectedValueIntervalMs, params)
        mtrHostWrite("ListNullablesAndOptionalsStruct", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: params)
    }
    open func writeAttributeListOctetString(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber)
    {
        _ = (dataValueDictionary, expectedValueIntervalMs)
        mtrHostWrite("ListOctetString", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: nil)
    }
    open func writeAttributeListOctetString(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber, params: MTRWriteParams?)
    {
        _ = (dataValueDictionary, expectedValueIntervalMs, params)
        mtrHostWrite("ListOctetString", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: params)
    }
    open func writeAttributeListStructOctetString(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber)
    {
        _ = (dataValueDictionary, expectedValueIntervalMs)
        mtrHostWrite("ListStructOctetString", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: nil)
    }
    open func writeAttributeListStructOctetString(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber, params: MTRWriteParams?)
    {
        _ = (dataValueDictionary, expectedValueIntervalMs, params)
        mtrHostWrite("ListStructOctetString", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: params)
    }
    open func writeAttributeLongCharString(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber)
    {
        _ = (dataValueDictionary, expectedValueIntervalMs)
        mtrHostWrite("LongCharString", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: nil)
    }
    open func writeAttributeLongCharString(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber, params: MTRWriteParams?)
    {
        _ = (dataValueDictionary, expectedValueIntervalMs, params)
        mtrHostWrite("LongCharString", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: params)
    }
    open func writeAttributeLongOctetString(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber)
    {
        _ = (dataValueDictionary, expectedValueIntervalMs)
        mtrHostWrite("LongOctetString", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: nil)
    }
    open func writeAttributeLongOctetString(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber, params: MTRWriteParams?)
    {
        _ = (dataValueDictionary, expectedValueIntervalMs, params)
        mtrHostWrite("LongOctetString", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: params)
    }
    open func writeAttributeNullableBitmap16(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber)
    {
        _ = (dataValueDictionary, expectedValueIntervalMs)
        mtrHostWrite("NullableBitmap16", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: nil)
    }
    open func writeAttributeNullableBitmap16(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber, params: MTRWriteParams?)
    {
        _ = (dataValueDictionary, expectedValueIntervalMs, params)
        mtrHostWrite("NullableBitmap16", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: params)
    }
    open func writeAttributeNullableBitmap32(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber)
    {
        _ = (dataValueDictionary, expectedValueIntervalMs)
        mtrHostWrite("NullableBitmap32", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: nil)
    }
    open func writeAttributeNullableBitmap32(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber, params: MTRWriteParams?)
    {
        _ = (dataValueDictionary, expectedValueIntervalMs, params)
        mtrHostWrite("NullableBitmap32", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: params)
    }
    open func writeAttributeNullableBitmap64(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber)
    {
        _ = (dataValueDictionary, expectedValueIntervalMs)
        mtrHostWrite("NullableBitmap64", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: nil)
    }
    open func writeAttributeNullableBitmap64(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber, params: MTRWriteParams?)
    {
        _ = (dataValueDictionary, expectedValueIntervalMs, params)
        mtrHostWrite("NullableBitmap64", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: params)
    }
    open func writeAttributeNullableBitmap8(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber)
    {
        _ = (dataValueDictionary, expectedValueIntervalMs)
        mtrHostWrite("NullableBitmap8", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: nil)
    }
    open func writeAttributeNullableBitmap8(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber, params: MTRWriteParams?)
    {
        _ = (dataValueDictionary, expectedValueIntervalMs, params)
        mtrHostWrite("NullableBitmap8", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: params)
    }
    open func writeAttributeNullableBoolean(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber)
    {
        _ = (dataValueDictionary, expectedValueIntervalMs)
        mtrHostWrite("NullableBoolean", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: nil)
    }
    open func writeAttributeNullableBoolean(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber, params: MTRWriteParams?)
    {
        _ = (dataValueDictionary, expectedValueIntervalMs, params)
        mtrHostWrite("NullableBoolean", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: params)
    }
    open func writeAttributeNullableCharString(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber)
    {
        _ = (dataValueDictionary, expectedValueIntervalMs)
        mtrHostWrite("NullableCharString", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: nil)
    }
    open func writeAttributeNullableCharString(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber, params: MTRWriteParams?)
    {
        _ = (dataValueDictionary, expectedValueIntervalMs, params)
        mtrHostWrite("NullableCharString", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: params)
    }
    open func writeAttributeNullableEnum16(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber)
    {
        _ = (dataValueDictionary, expectedValueIntervalMs)
        mtrHostWrite("NullableEnum16", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: nil)
    }
    open func writeAttributeNullableEnum16(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber, params: MTRWriteParams?)
    {
        _ = (dataValueDictionary, expectedValueIntervalMs, params)
        mtrHostWrite("NullableEnum16", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: params)
    }
    open func writeAttributeNullableEnum8(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber)
    {
        _ = (dataValueDictionary, expectedValueIntervalMs)
        mtrHostWrite("NullableEnum8", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: nil)
    }
    open func writeAttributeNullableEnum8(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber, params: MTRWriteParams?)
    {
        _ = (dataValueDictionary, expectedValueIntervalMs, params)
        mtrHostWrite("NullableEnum8", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: params)
    }
    open func writeAttributeNullableEnumAttr(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber)
    {
        _ = (dataValueDictionary, expectedValueIntervalMs)
        mtrHostWrite("NullableEnumAttr", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: nil)
    }
    open func writeAttributeNullableEnumAttr(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber, params: MTRWriteParams?)
    {
        _ = (dataValueDictionary, expectedValueIntervalMs, params)
        mtrHostWrite("NullableEnumAttr", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: params)
    }
    open func writeAttributeNullableFloatDouble(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber)
    {
        _ = (dataValueDictionary, expectedValueIntervalMs)
        mtrHostWrite("NullableFloatDouble", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: nil)
    }
    open func writeAttributeNullableFloatDouble(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber, params: MTRWriteParams?)
    {
        _ = (dataValueDictionary, expectedValueIntervalMs, params)
        mtrHostWrite("NullableFloatDouble", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: params)
    }
    open func writeAttributeNullableFloatSingle(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber)
    {
        _ = (dataValueDictionary, expectedValueIntervalMs)
        mtrHostWrite("NullableFloatSingle", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: nil)
    }
    open func writeAttributeNullableFloatSingle(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber, params: MTRWriteParams?)
    {
        _ = (dataValueDictionary, expectedValueIntervalMs, params)
        mtrHostWrite("NullableFloatSingle", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: params)
    }
    open func writeAttributeNullableInt16s(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber)
    {
        _ = (dataValueDictionary, expectedValueIntervalMs)
        mtrHostWrite("NullableInt16s", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: nil)
    }
    open func writeAttributeNullableInt16s(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber, params: MTRWriteParams?)
    {
        _ = (dataValueDictionary, expectedValueIntervalMs, params)
        mtrHostWrite("NullableInt16s", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: params)
    }
    open func writeAttributeNullableInt16u(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber)
    {
        _ = (dataValueDictionary, expectedValueIntervalMs)
        mtrHostWrite("NullableInt16u", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: nil)
    }
    open func writeAttributeNullableInt16u(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber, params: MTRWriteParams?)
    {
        _ = (dataValueDictionary, expectedValueIntervalMs, params)
        mtrHostWrite("NullableInt16u", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: params)
    }
    open func writeAttributeNullableInt24s(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber)
    {
        _ = (dataValueDictionary, expectedValueIntervalMs)
        mtrHostWrite("NullableInt24s", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: nil)
    }
    open func writeAttributeNullableInt24s(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber, params: MTRWriteParams?)
    {
        _ = (dataValueDictionary, expectedValueIntervalMs, params)
        mtrHostWrite("NullableInt24s", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: params)
    }
    open func writeAttributeNullableInt24u(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber)
    {
        _ = (dataValueDictionary, expectedValueIntervalMs)
        mtrHostWrite("NullableInt24u", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: nil)
    }
    open func writeAttributeNullableInt24u(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber, params: MTRWriteParams?)
    {
        _ = (dataValueDictionary, expectedValueIntervalMs, params)
        mtrHostWrite("NullableInt24u", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: params)
    }
    open func writeAttributeNullableInt32s(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber)
    {
        _ = (dataValueDictionary, expectedValueIntervalMs)
        mtrHostWrite("NullableInt32s", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: nil)
    }
    open func writeAttributeNullableInt32s(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber, params: MTRWriteParams?)
    {
        _ = (dataValueDictionary, expectedValueIntervalMs, params)
        mtrHostWrite("NullableInt32s", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: params)
    }
    open func writeAttributeNullableInt32u(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber)
    {
        _ = (dataValueDictionary, expectedValueIntervalMs)
        mtrHostWrite("NullableInt32u", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: nil)
    }
    open func writeAttributeNullableInt32u(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber, params: MTRWriteParams?)
    {
        _ = (dataValueDictionary, expectedValueIntervalMs, params)
        mtrHostWrite("NullableInt32u", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: params)
    }
    open func writeAttributeNullableInt40s(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber)
    {
        _ = (dataValueDictionary, expectedValueIntervalMs)
        mtrHostWrite("NullableInt40s", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: nil)
    }
    open func writeAttributeNullableInt40s(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber, params: MTRWriteParams?)
    {
        _ = (dataValueDictionary, expectedValueIntervalMs, params)
        mtrHostWrite("NullableInt40s", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: params)
    }
    open func writeAttributeNullableInt40u(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber)
    {
        _ = (dataValueDictionary, expectedValueIntervalMs)
        mtrHostWrite("NullableInt40u", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: nil)
    }
    open func writeAttributeNullableInt40u(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber, params: MTRWriteParams?)
    {
        _ = (dataValueDictionary, expectedValueIntervalMs, params)
        mtrHostWrite("NullableInt40u", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: params)
    }
    open func writeAttributeNullableInt48s(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber)
    {
        _ = (dataValueDictionary, expectedValueIntervalMs)
        mtrHostWrite("NullableInt48s", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: nil)
    }
    open func writeAttributeNullableInt48s(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber, params: MTRWriteParams?)
    {
        _ = (dataValueDictionary, expectedValueIntervalMs, params)
        mtrHostWrite("NullableInt48s", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: params)
    }
    open func writeAttributeNullableInt48u(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber)
    {
        _ = (dataValueDictionary, expectedValueIntervalMs)
        mtrHostWrite("NullableInt48u", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: nil)
    }
    open func writeAttributeNullableInt48u(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber, params: MTRWriteParams?)
    {
        _ = (dataValueDictionary, expectedValueIntervalMs, params)
        mtrHostWrite("NullableInt48u", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: params)
    }
    open func writeAttributeNullableInt56s(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber)
    {
        _ = (dataValueDictionary, expectedValueIntervalMs)
        mtrHostWrite("NullableInt56s", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: nil)
    }
    open func writeAttributeNullableInt56s(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber, params: MTRWriteParams?)
    {
        _ = (dataValueDictionary, expectedValueIntervalMs, params)
        mtrHostWrite("NullableInt56s", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: params)
    }
    open func writeAttributeNullableInt56u(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber)
    {
        _ = (dataValueDictionary, expectedValueIntervalMs)
        mtrHostWrite("NullableInt56u", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: nil)
    }
    open func writeAttributeNullableInt56u(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber, params: MTRWriteParams?)
    {
        _ = (dataValueDictionary, expectedValueIntervalMs, params)
        mtrHostWrite("NullableInt56u", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: params)
    }
    open func writeAttributeNullableInt64s(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber)
    {
        _ = (dataValueDictionary, expectedValueIntervalMs)
        mtrHostWrite("NullableInt64s", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: nil)
    }
    open func writeAttributeNullableInt64s(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber, params: MTRWriteParams?)
    {
        _ = (dataValueDictionary, expectedValueIntervalMs, params)
        mtrHostWrite("NullableInt64s", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: params)
    }
    open func writeAttributeNullableInt64u(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber)
    {
        _ = (dataValueDictionary, expectedValueIntervalMs)
        mtrHostWrite("NullableInt64u", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: nil)
    }
    open func writeAttributeNullableInt64u(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber, params: MTRWriteParams?)
    {
        _ = (dataValueDictionary, expectedValueIntervalMs, params)
        mtrHostWrite("NullableInt64u", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: params)
    }
    open func writeAttributeNullableInt8s(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber)
    {
        _ = (dataValueDictionary, expectedValueIntervalMs)
        mtrHostWrite("NullableInt8s", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: nil)
    }
    open func writeAttributeNullableInt8s(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber, params: MTRWriteParams?)
    {
        _ = (dataValueDictionary, expectedValueIntervalMs, params)
        mtrHostWrite("NullableInt8s", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: params)
    }
    open func writeAttributeNullableInt8u(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber)
    {
        _ = (dataValueDictionary, expectedValueIntervalMs)
        mtrHostWrite("NullableInt8u", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: nil)
    }
    open func writeAttributeNullableInt8u(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber, params: MTRWriteParams?)
    {
        _ = (dataValueDictionary, expectedValueIntervalMs, params)
        mtrHostWrite("NullableInt8u", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: params)
    }
    open func writeAttributeNullableOctetString(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber)
    {
        _ = (dataValueDictionary, expectedValueIntervalMs)
        mtrHostWrite("NullableOctetString", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: nil)
    }
    open func writeAttributeNullableOctetString(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber, params: MTRWriteParams?)
    {
        _ = (dataValueDictionary, expectedValueIntervalMs, params)
        mtrHostWrite("NullableOctetString", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: params)
    }
    open func writeAttributeNullableRangeRestrictedInt16s(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber)
    {
        _ = (dataValueDictionary, expectedValueIntervalMs)
        mtrHostWrite("NullableRangeRestrictedInt16s", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: nil)
    }
    open func writeAttributeNullableRangeRestrictedInt16s(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber, params: MTRWriteParams?)
    {
        _ = (dataValueDictionary, expectedValueIntervalMs, params)
        mtrHostWrite("NullableRangeRestrictedInt16s", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: params)
    }
    open func writeAttributeNullableRangeRestrictedInt16u(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber)
    {
        _ = (dataValueDictionary, expectedValueIntervalMs)
        mtrHostWrite("NullableRangeRestrictedInt16u", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: nil)
    }
    open func writeAttributeNullableRangeRestrictedInt16u(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber, params: MTRWriteParams?)
    {
        _ = (dataValueDictionary, expectedValueIntervalMs, params)
        mtrHostWrite("NullableRangeRestrictedInt16u", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: params)
    }
    open func writeAttributeNullableRangeRestrictedInt8s(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber)
    {
        _ = (dataValueDictionary, expectedValueIntervalMs)
        mtrHostWrite("NullableRangeRestrictedInt8s", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: nil)
    }
    open func writeAttributeNullableRangeRestrictedInt8s(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber, params: MTRWriteParams?)
    {
        _ = (dataValueDictionary, expectedValueIntervalMs, params)
        mtrHostWrite("NullableRangeRestrictedInt8s", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: params)
    }
    open func writeAttributeNullableRangeRestrictedInt8u(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber)
    {
        _ = (dataValueDictionary, expectedValueIntervalMs)
        mtrHostWrite("NullableRangeRestrictedInt8u", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: nil)
    }
    open func writeAttributeNullableRangeRestrictedInt8u(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber, params: MTRWriteParams?)
    {
        _ = (dataValueDictionary, expectedValueIntervalMs, params)
        mtrHostWrite("NullableRangeRestrictedInt8u", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: params)
    }
    open func writeAttributeNullableStruct(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber)
    {
        _ = (dataValueDictionary, expectedValueIntervalMs)
        mtrHostWrite("NullableStruct", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: nil)
    }
    open func writeAttributeNullableStruct(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber, params: MTRWriteParams?)
    {
        _ = (dataValueDictionary, expectedValueIntervalMs, params)
        mtrHostWrite("NullableStruct", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: params)
    }
    open func writeAttributeOctetString(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber)
    {
        _ = (dataValueDictionary, expectedValueIntervalMs)
        mtrHostWrite("OctetString", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: nil)
    }
    open func writeAttributeOctetString(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber, params: MTRWriteParams?)
    {
        _ = (dataValueDictionary, expectedValueIntervalMs, params)
        mtrHostWrite("OctetString", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: params)
    }
    open func writeAttributeRangeRestrictedInt16s(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber)
    {
        _ = (dataValueDictionary, expectedValueIntervalMs)
        mtrHostWrite("RangeRestrictedInt16s", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: nil)
    }
    open func writeAttributeRangeRestrictedInt16s(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber, params: MTRWriteParams?)
    {
        _ = (dataValueDictionary, expectedValueIntervalMs, params)
        mtrHostWrite("RangeRestrictedInt16s", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: params)
    }
    open func writeAttributeRangeRestrictedInt16u(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber)
    {
        _ = (dataValueDictionary, expectedValueIntervalMs)
        mtrHostWrite("RangeRestrictedInt16u", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: nil)
    }
    open func writeAttributeRangeRestrictedInt16u(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber, params: MTRWriteParams?)
    {
        _ = (dataValueDictionary, expectedValueIntervalMs, params)
        mtrHostWrite("RangeRestrictedInt16u", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: params)
    }
    open func writeAttributeRangeRestrictedInt8s(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber)
    {
        _ = (dataValueDictionary, expectedValueIntervalMs)
        mtrHostWrite("RangeRestrictedInt8s", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: nil)
    }
    open func writeAttributeRangeRestrictedInt8s(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber, params: MTRWriteParams?)
    {
        _ = (dataValueDictionary, expectedValueIntervalMs, params)
        mtrHostWrite("RangeRestrictedInt8s", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: params)
    }
    open func writeAttributeRangeRestrictedInt8u(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber)
    {
        _ = (dataValueDictionary, expectedValueIntervalMs)
        mtrHostWrite("RangeRestrictedInt8u", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: nil)
    }
    open func writeAttributeRangeRestrictedInt8u(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber, params: MTRWriteParams?)
    {
        _ = (dataValueDictionary, expectedValueIntervalMs, params)
        mtrHostWrite("RangeRestrictedInt8u", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: params)
    }
    open func writeAttributeStructAttr(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber)
    {
        _ = (dataValueDictionary, expectedValueIntervalMs)
        mtrHostWrite("StructAttr", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: nil)
    }
    open func writeAttributeStructAttr(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber, params: MTRWriteParams?)
    {
        _ = (dataValueDictionary, expectedValueIntervalMs, params)
        mtrHostWrite("StructAttr", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: params)
    }
    open func writeAttributeTimedWriteBoolean(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber)
    {
        _ = (dataValueDictionary, expectedValueIntervalMs)
        mtrHostWrite("TimedWriteBoolean", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: nil)
    }
    open func writeAttributeTimedWriteBoolean(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber, params: MTRWriteParams?)
    {
        _ = (dataValueDictionary, expectedValueIntervalMs, params)
        mtrHostWrite("TimedWriteBoolean", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: params)
    }
    open func writeAttributeUnsupported(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber)
    {
        _ = (dataValueDictionary, expectedValueIntervalMs)
        mtrHostWrite("Unsupported", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: nil)
    }
    open func writeAttributeUnsupported(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber, params: MTRWriteParams?)
    {
        _ = (dataValueDictionary, expectedValueIntervalMs, params)
        mtrHostWrite("Unsupported", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: params)
    }
    open func writeAttributeVendorId(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber)
    {
        _ = (dataValueDictionary, expectedValueIntervalMs)
        mtrHostWrite("VendorId", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: nil)
    }
    open func writeAttributeVendorId(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber, params: MTRWriteParams?)
    {
        _ = (dataValueDictionary, expectedValueIntervalMs, params)
        mtrHostWrite("VendorId", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: params)
    }
    open func writeAttributeWriteOnlyInt8u(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber)
    {
        _ = (dataValueDictionary, expectedValueIntervalMs)
        mtrHostWrite("WriteOnlyInt8u", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: nil)
    }
    open func writeAttributeWriteOnlyInt8u(withValue dataValueDictionary: [String : Any], expectedValueInterval expectedValueIntervalMs: NSNumber, params: MTRWriteParams?)
    {
        _ = (dataValueDictionary, expectedValueIntervalMs, params)
        mtrHostWrite("WriteOnlyInt8u", value: dataValueDictionary, expectedValueInterval: expectedValueIntervalMs, params: params)
    }
}

open class MTRBaseClusterPowerSource: MTRGenericBaseCluster {
    public init?(device: MTRBaseDevice, endpoint: UInt16, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.endpoint = NSNumber(value: endpoint)
        self.queue = queue
    }
    public init?(device: MTRBaseDevice, endpointID: NSNumber, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.endpoint = endpointID
        self.queue = queue
    }
    open func readAttributeAcceptedCommandList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeAcceptedCommandList(completionHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeActiveBatChargeFaults(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeActiveBatChargeFaults(completionHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeActiveBatFaults(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeActiveBatFaults(completionHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeActiveWiredFaults(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeActiveWiredFaults(completionHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeAttributeList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeAttributeList(completionHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeBatANSIDesignation(completion: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeBatANSIDesignation(completionHandler: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeBatApprovedChemistry(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeBatApprovedChemistry(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeBatCapacity(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeBatCapacity(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeBatChargeLevel(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeBatChargeLevel(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeBatChargeState(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeBatChargeState(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeBatChargingCurrent(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeBatChargingCurrent(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeBatCommonDesignation(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeBatCommonDesignation(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeBatFunctionalWhileCharging(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeBatFunctionalWhileCharging(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeBatIECDesignation(completion: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeBatIECDesignation(completionHandler: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeBatPercentRemaining(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeBatPercentRemaining(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeBatPresent(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeBatPresent(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeBatQuantity(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeBatQuantity(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeBatReplaceability(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeBatReplaceability(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeBatReplacementDescription(completion: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeBatReplacementDescription(completionHandler: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeBatReplacementNeeded(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeBatReplacementNeeded(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeBatTimeRemaining(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeBatTimeRemaining(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeBatTimeToFullCharge(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeBatTimeToFullCharge(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeBatVoltage(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeBatVoltage(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeClusterRevision(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeClusterRevision(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeDescription(completion: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeDescription(completionHandler: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeEndpointList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeFeatureMap(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeFeatureMap(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeGeneratedCommandList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeGeneratedCommandList(completionHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeOrder(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeOrder(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeStatus(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeStatus(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeWiredAssessedCurrent(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeWiredAssessedCurrent(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeWiredAssessedInputFrequency(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeWiredAssessedInputFrequency(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeWiredAssessedInputVoltage(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeWiredAssessedInputVoltage(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeWiredCurrentType(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeWiredCurrentType(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeWiredMaximumCurrent(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeWiredMaximumCurrent(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeWiredNominalVoltage(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeWiredNominalVoltage(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeWiredPresent(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeWiredPresent(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func subscribeAttributeAcceptedCommandList(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAcceptedCommandList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeActiveBatChargeFaults(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeActiveBatChargeFaults(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeActiveBatFaults(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeActiveBatFaults(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeActiveWiredFaults(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeActiveWiredFaults(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAttributeList(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAttributeList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeBatANSIDesignation(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeBatANSIDesignation(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeBatApprovedChemistry(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeBatApprovedChemistry(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeBatCapacity(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeBatCapacity(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeBatChargeLevel(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeBatChargeLevel(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeBatChargeState(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeBatChargeState(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeBatChargingCurrent(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeBatChargingCurrent(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeBatCommonDesignation(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeBatCommonDesignation(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeBatFunctionalWhileCharging(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeBatFunctionalWhileCharging(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeBatIECDesignation(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeBatIECDesignation(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeBatPercentRemaining(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeBatPercentRemaining(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeBatPresent(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeBatPresent(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeBatQuantity(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeBatQuantity(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeBatReplaceability(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeBatReplaceability(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeBatReplacementDescription(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeBatReplacementDescription(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeBatReplacementNeeded(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeBatReplacementNeeded(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeBatTimeRemaining(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeBatTimeRemaining(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeBatTimeToFullCharge(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeBatTimeToFullCharge(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeBatVoltage(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeBatVoltage(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeClusterRevision(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeClusterRevision(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeDescription(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeDescription(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeEndpointList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeFeatureMap(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeFeatureMap(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeGeneratedCommandList(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeGeneratedCommandList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeOrder(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeOrder(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeStatus(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeStatus(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeWiredAssessedCurrent(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeWiredAssessedCurrent(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeWiredAssessedInputFrequency(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeWiredAssessedInputFrequency(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeWiredAssessedInputVoltage(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeWiredAssessedInputVoltage(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeWiredCurrentType(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeWiredCurrentType(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeWiredMaximumCurrent(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeWiredMaximumCurrent(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeWiredNominalVoltage(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeWiredNominalVoltage(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeWiredPresent(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeWiredPresent(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
}

open class MTRBaseClusterWindowCovering: MTRGenericBaseCluster {
    open func downOrClose(completion: @escaping ((any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func downOrClose(completionHandler: @escaping ((any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    public init?(device: MTRBaseDevice, endpoint: UInt16, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.endpoint = NSNumber(value: endpoint)
        self.queue = queue
    }
    public init?(device: MTRBaseDevice, endpointID: NSNumber, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.endpoint = endpointID
        self.queue = queue
    }
    open func readAttributeAcceptedCommandList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeAcceptedCommandList(completionHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeAttributeList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeAttributeList(completionHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeClusterRevision(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeClusterRevision(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeConfigStatus(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeConfigStatus(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeCurrentPositionLiftPercent100ths(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeCurrentPositionLiftPercent100ths(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeCurrentPositionLiftPercentage(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeCurrentPositionLiftPercentage(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeCurrentPositionLift(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeCurrentPositionLift(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeCurrentPositionTiltPercent100ths(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeCurrentPositionTiltPercent100ths(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeCurrentPositionTiltPercentage(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeCurrentPositionTiltPercentage(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeCurrentPositionTilt(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeCurrentPositionTilt(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeEndProductType(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeEndProductType(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeFeatureMap(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeFeatureMap(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeGeneratedCommandList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeGeneratedCommandList(completionHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeInstalledClosedLimitLift(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeInstalledClosedLimitLift(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeInstalledClosedLimitTilt(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeInstalledClosedLimitTilt(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeInstalledOpenLimitLift(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeInstalledOpenLimitLift(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeInstalledOpenLimitTilt(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeInstalledOpenLimitTilt(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeMode(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeMode(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeNumberOfActuationsLift(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeNumberOfActuationsLift(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeNumberOfActuationsTilt(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeNumberOfActuationsTilt(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeOperationalStatus(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeOperationalStatus(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributePhysicalClosedLimitLift(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributePhysicalClosedLimitLift(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributePhysicalClosedLimitTilt(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributePhysicalClosedLimitTilt(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeSafetyStatus(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeSafetyStatus(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeTargetPositionLiftPercent100ths(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeTargetPositionLiftPercent100ths(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeTargetPositionTiltPercent100ths(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeTargetPositionTiltPercent100ths(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeType(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeType(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func stopMotion(completion: @escaping ((any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func stopMotion(completionHandler: @escaping ((any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func subscribeAttributeAcceptedCommandList(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAcceptedCommandList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAttributeList(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAttributeList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeClusterRevision(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeClusterRevision(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeConfigStatus(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeConfigStatus(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeCurrentPositionLiftPercent100ths(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeCurrentPositionLiftPercent100ths(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeCurrentPositionLiftPercentage(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeCurrentPositionLiftPercentage(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeCurrentPositionLift(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeCurrentPositionLift(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeCurrentPositionTiltPercent100ths(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeCurrentPositionTiltPercent100ths(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeCurrentPositionTiltPercentage(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeCurrentPositionTiltPercentage(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeCurrentPositionTilt(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeCurrentPositionTilt(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeEndProductType(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeEndProductType(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeFeatureMap(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeFeatureMap(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeGeneratedCommandList(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeGeneratedCommandList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeInstalledClosedLimitLift(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeInstalledClosedLimitLift(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeInstalledClosedLimitTilt(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeInstalledClosedLimitTilt(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeInstalledOpenLimitLift(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeInstalledOpenLimitLift(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeInstalledOpenLimitTilt(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeInstalledOpenLimitTilt(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeMode(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeMode(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeNumberOfActuationsLift(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeNumberOfActuationsLift(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeNumberOfActuationsTilt(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeNumberOfActuationsTilt(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeOperationalStatus(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeOperationalStatus(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributePhysicalClosedLimitLift(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributePhysicalClosedLimitLift(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributePhysicalClosedLimitTilt(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributePhysicalClosedLimitTilt(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeSafetyStatus(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeSafetyStatus(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeTargetPositionLiftPercent100ths(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeTargetPositionLiftPercent100ths(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeTargetPositionTiltPercent100ths(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeTargetPositionTiltPercent100ths(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeType(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeType(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func upOrOpen(completion: @escaping ((any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func upOrOpen(completionHandler: @escaping ((any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
}

open class MTRBaseClusterPumpConfigurationAndControl: MTRGenericBaseCluster {
    public init?(device: MTRBaseDevice, endpoint: UInt16, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.endpoint = NSNumber(value: endpoint)
        self.queue = queue
    }
    public init?(device: MTRBaseDevice, endpointID: NSNumber, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.endpoint = endpointID
        self.queue = queue
    }
    open func readAttributeAcceptedCommandList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeAcceptedCommandList(completionHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeAttributeList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeAttributeList(completionHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeCapacity(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeCapacity(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeClusterRevision(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeClusterRevision(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeControlMode(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeControlMode(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeEffectiveControlMode(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeEffectiveControlMode(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeEffectiveOperationMode(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeEffectiveOperationMode(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeFeatureMap(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeFeatureMap(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeGeneratedCommandList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeGeneratedCommandList(completionHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeLifetimeEnergyConsumed(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeLifetimeEnergyConsumed(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeLifetimeRunningHours(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeLifetimeRunningHours(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeMaxCompPressure(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeMaxCompPressure(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeMaxConstFlow(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeMaxConstFlow(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeMaxConstPressure(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeMaxConstPressure(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeMaxConstSpeed(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeMaxConstSpeed(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeMaxConstTemp(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeMaxConstTemp(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeMaxFlow(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeMaxFlow(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeMaxPressure(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeMaxPressure(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeMaxSpeed(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeMaxSpeed(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeMinCompPressure(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeMinCompPressure(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeMinConstFlow(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeMinConstFlow(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeMinConstPressure(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeMinConstPressure(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeMinConstSpeed(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeMinConstSpeed(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeMinConstTemp(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeMinConstTemp(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeOperationMode(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeOperationMode(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributePower(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributePower(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributePumpStatus(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributePumpStatus(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeSpeed(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeSpeed(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func subscribeAttributeAcceptedCommandList(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAcceptedCommandList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAttributeList(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAttributeList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeCapacity(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeCapacity(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeClusterRevision(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeClusterRevision(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeControlMode(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeControlMode(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeEffectiveControlMode(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeEffectiveControlMode(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeEffectiveOperationMode(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeEffectiveOperationMode(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeFeatureMap(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeFeatureMap(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeGeneratedCommandList(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeGeneratedCommandList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeLifetimeEnergyConsumed(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeLifetimeEnergyConsumed(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeLifetimeRunningHours(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeLifetimeRunningHours(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeMaxCompPressure(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeMaxCompPressure(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeMaxConstFlow(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeMaxConstFlow(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeMaxConstPressure(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeMaxConstPressure(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeMaxConstSpeed(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeMaxConstSpeed(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeMaxConstTemp(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeMaxConstTemp(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeMaxFlow(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeMaxFlow(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeMaxPressure(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeMaxPressure(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeMaxSpeed(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeMaxSpeed(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeMinCompPressure(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeMinCompPressure(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeMinConstFlow(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeMinConstFlow(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeMinConstPressure(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeMinConstPressure(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeMinConstSpeed(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeMinConstSpeed(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeMinConstTemp(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeMinConstTemp(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeOperationMode(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeOperationMode(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributePower(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributePower(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributePumpStatus(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributePumpStatus(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeSpeed(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeSpeed(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
}

open class MTRBaseClusterLevelControl: MTRGenericBaseCluster {
    public init?(device: MTRBaseDevice, endpoint: UInt16, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.endpoint = NSNumber(value: endpoint)
        self.queue = queue
    }
    public init?(device: MTRBaseDevice, endpointID: NSNumber, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.endpoint = endpointID
        self.queue = queue
    }
    open func readAttributeAcceptedCommandList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeAcceptedCommandList(completionHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeAttributeList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeAttributeList(completionHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeClusterRevision(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeClusterRevision(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeCurrentFrequency(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeCurrentFrequency(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeCurrentLevel(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeCurrentLevel(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeDefaultMoveRate(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeDefaultMoveRate(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeFeatureMap(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeFeatureMap(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeGeneratedCommandList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeGeneratedCommandList(completionHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeMaxFrequency(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeMaxFrequency(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeMaxLevel(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeMaxLevel(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeMinFrequency(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeMinFrequency(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeMinLevel(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeMinLevel(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeOffTransitionTime(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeOffTransitionTime(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeOnLevel(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeOnLevel(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeOnOffTransitionTime(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeOnOffTransitionTime(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeOnTransitionTime(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeOnTransitionTime(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeOptions(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeOptions(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeRemainingTime(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeRemainingTime(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeStartUpCurrentLevel(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeStartUpCurrentLevel(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func subscribeAttributeAcceptedCommandList(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAcceptedCommandList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAttributeList(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAttributeList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeClusterRevision(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeClusterRevision(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeCurrentFrequency(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeCurrentFrequency(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeCurrentLevel(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeCurrentLevel(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeDefaultMoveRate(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeDefaultMoveRate(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeFeatureMap(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeFeatureMap(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeGeneratedCommandList(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeGeneratedCommandList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeMaxFrequency(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeMaxFrequency(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeMaxLevel(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeMaxLevel(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeMinFrequency(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeMinFrequency(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeMinLevel(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeMinLevel(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeOffTransitionTime(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeOffTransitionTime(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeOnLevel(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeOnLevel(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeOnOffTransitionTime(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeOnOffTransitionTime(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeOnTransitionTime(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeOnTransitionTime(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeOptions(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeOptions(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeRemainingTime(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeRemainingTime(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeStartUpCurrentLevel(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeStartUpCurrentLevel(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
}

open class MTRBaseClusterBallastConfiguration: MTRGenericBaseCluster {
    public init?(device: MTRBaseDevice, endpoint: UInt16, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.endpoint = NSNumber(value: endpoint)
        self.queue = queue
    }
    public init?(device: MTRBaseDevice, endpointID: NSNumber, queue: dispatch_queue_t)
    {
        super.init()
        self.device = device
        self.endpoint = endpointID
        self.queue = queue
    }
    open func readAttributeAcceptedCommandList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeAcceptedCommandList(completionHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeAttributeList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeAttributeList(completionHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeBallastFactorAdjustment(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeBallastFactorAdjustment(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeBallastStatus(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeBallastStatus(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeClusterRevision(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeClusterRevision(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeFeatureMap(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeFeatureMap(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeGeneratedCommandList(completion: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeGeneratedCommandList(completionHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeIntrinsicBalanceFactor(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeIntrinsicBallastFactor(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeLampAlarmMode(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeLampAlarmMode(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeLampBurnHoursTripPoint(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeLampBurnHoursTripPoint(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeLampBurnHours(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeLampBurnHours(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeLampManufacturer(completion: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeLampManufacturer(completionHandler: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeLampQuantity(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeLampQuantity(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeLampRatedHours(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeLampRatedHours(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeLampType(completion: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeLampType(completionHandler: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeMaxLevel(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeMaxLevel(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributeMinLevel(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributeMinLevel(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributePhysicalMaxLevel(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributePhysicalMaxLevel(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func readAttributePhysicalMinLevel(completion: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completion)
        mtrFailClosed(completion)
    }
    open func readAttributePhysicalMinLevel(completionHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (completionHandler)
        mtrFailClosed(completionHandler)
    }
    open func subscribeAttributeAcceptedCommandList(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAcceptedCommandList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAttributeList(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeAttributeList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeBallastFactorAdjustment(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeBallastFactorAdjustment(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeBallastStatus(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeBallastStatus(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeClusterRevision(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeClusterRevision(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeFeatureMap(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeFeatureMap(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeGeneratedCommandList(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeGeneratedCommandList(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping ([Any]?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeIntrinsicBalanceFactor(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeIntrinsicBallastFactor(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeLampAlarmMode(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeLampAlarmMode(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeLampBurnHoursTripPoint(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeLampBurnHoursTripPoint(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeLampBurnHours(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeLampBurnHours(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeLampManufacturer(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeLampManufacturer(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeLampQuantity(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeLampQuantity(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeLampRatedHours(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeLampRatedHours(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeLampType(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeLampType(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (String?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeMaxLevel(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeMaxLevel(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeMinLevel(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributeMinLevel(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributePhysicalMaxLevel(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributePhysicalMaxLevel(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributePhysicalMinLevel(withMinInterval minInterval: NSNumber, maxInterval: NSNumber, params: MTRSubscribeParams?, subscriptionEstablished subscriptionEstablishedHandler: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (minInterval, maxInterval, params, subscriptionEstablishedHandler, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
    open func subscribeAttributePhysicalMinLevel(with params: MTRSubscribeParams, subscriptionEstablished: MTRSubscriptionEstablishedHandler?, reportHandler: @escaping (NSNumber?, (any Error)?) -> Void)
    {
        _ = (params, subscriptionEstablished, reportHandler)
        mtrSubscribeFailClosed(reportHandler)
    }
}

