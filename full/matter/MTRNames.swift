import Foundation

private let mtrClusterNames: [UInt32: String] = [
    3: "Identify", 4: "Groups", 6: "OnOff", 7: "OnOffSwitchConfiguration", 8: "LevelControl", 15: "BinaryInputBasic", 28: "PulseWidthModulation", 29: "Descriptor", 30: "Binding", 31: "AccessControl", 37: "Actions", 40: "Basic", 41: "OtaSoftwareUpdateProvider", 42: "OtaSoftwareUpdateRequestor", 43: "LocalizationConfiguration", 44: "TimeFormatLocalization", 45: "UnitLocalization", 46: "PowerSourceConfiguration", 47: "PowerSource", 48: "GeneralCommissioning", 49: "NetworkCommissioning", 50: "DiagnosticLogs", 51: "GeneralDiagnostics", 52: "SoftwareDiagnostics", 53: "ThreadNetworkDiagnostics", 54: "WiFiNetworkDiagnostics", 55: "EthernetNetworkDiagnostics", 56: "TimeSynchronization", 57: "BridgedDeviceBasic", 59: "Switch", 60: "AdministratorCommissioning", 62: "OperationalCredentials", 63: "GroupKeyManagement", 64: "FixedLabel", 65: "UserLabel", 69: "BooleanState", 70: "IcdManagement", 72: "OvenCavityOperationalState", 73: "OvenMode", 74: "LaundryDryerControls", 80: "ModeSelect", 81: "LaundryWasherMode", 82: "RefrigeratorAndTemperatureControlledCabinetMode", 83: "LaundryWasherControls", 84: "RvcRunMode", 85: "RvcCleanMode", 86: "TemperatureControl", 87: "RefrigeratorAlarm", 89: "DishwasherMode", 91: "AirQuality", 92: "SmokeCOAlarm", 93: "DishwasherAlarm", 94: "MicrowaveOvenMode", 95: "MicrowaveOvenControl", 96: "OperationalState", 97: "RvcOperationalState", 113: "HepaFilterMonitoring", 114: "ActivatedCarbonFilterMonitoring", 128: "BooleanStateConfiguration", 129: "ValveConfigurationAndControl", 144: "ElectricalPowerMeasurement", 145: "ElectricalEnergyMeasurement", 148: "WaterHeaterManagement", 151: "Messages", 152: "DeviceEnergyManagement", 153: "EnergyEVSE", 156: "PowerTopology", 157: "EnergyEVSEMode", 158: "WaterHeaterMode", 159: "DeviceEnergyManagementMode", 257: "DoorLock", 258: "WindowCovering", 259: "BarrierControl", 336: "ServiceArea", 512: "PumpConfigurationAndControl", 513: "Thermostat", 514: "FanControl", 516: "ThermostatUserInterfaceConfiguration", 768: "ColorControl", 769: "BallastConfiguration", 1024: "IlluminanceMeasurement", 1026: "TemperatureMeasurement", 1027: "PressureMeasurement", 1028: "FlowMeasurement", 1029: "RelativeHumidityMeasurement", 1030: "OccupancySensing", 1036: "CarbonMonoxideConcentrationMeasurement", 1037: "CarbonDioxideConcentrationMeasurement", 1043: "NitrogenDioxideConcentrationMeasurement", 1045: "OzoneConcentrationMeasurement", 1066: "Pm25ConcentrationMeasurement", 1067: "FormaldehydeConcentrationMeasurement", 1068: "Pm1ConcentrationMeasurement", 1069: "Pm10ConcentrationMeasurement", 1070: "TotalVolatileOrganicCompoundsConcentrationMeasurement", 1071: "RadonConcentrationMeasurement", 1105: "WiFiNetworkManagement", 1106: "ThreadBorderRouterManagement", 1107: "ThreadNetworkDirectory", 1283: "WakeOnLan", 1284: "Channel", 1285: "TargetNavigator", 1286: "MediaPlayback", 1287: "MediaInput", 1288: "LowPower", 1289: "KeypadInput", 1290: "ContentLauncher", 1291: "AudioOutput", 1292: "ApplicationLauncher", 1293: "ApplicationBasic", 1294: "AccountLogin", 1296: "ContentAppObserver", 1873: "CommissionerControl", 2820: "ElectricalMeasurement", 4294048773: "TestCluster"
]

private let mtrGlobalAttributeNames: [UInt32: String] = [
    0xFFF8: "GeneratedCommandList", 0xFFF9: "AcceptedCommandList",
    0xFFFA: "EventList", 0xFFFB: "AttributeList",
    0xFFFC: "FeatureMap", 0xFFFD: "ClusterRevision"
]

private let mtrOnOffAttributeNames: [UInt32: String] = [0: "OnOff"]
private let mtrOnOffCommandNames: [UInt32: String] = [0: "Off", 1: "On", 2: "Toggle"]

public func MTRClusterNameForID(_ clusterID: NSNumber) -> String? {
    mtrClusterNames[clusterID.uint32Value]
}

public func MTRAttributeNameForID(_ clusterID: NSNumber, _ attributeID: NSNumber) -> String? {
    if let global = mtrGlobalAttributeNames[attributeID.uint32Value] { return global }
    if clusterID.uint32Value == 6 { return mtrOnOffAttributeNames[attributeID.uint32Value] }
    if clusterID.uint32Value == 3, attributeID.uint32Value == 0 { return "IdentifyTime" }
    return nil
}

public func MTRRequestCommandNameForID(_ clusterID: NSNumber, _ commandID: NSNumber) -> String? {
    if clusterID.uint32Value == 6 { return mtrOnOffCommandNames[commandID.uint32Value] }
    if clusterID.uint32Value == 3, commandID.uint32Value == 0 { return "Identify" }
    return nil
}

public func MTRResponseCommandNameForID(_ clusterID: NSNumber, _ commandID: NSNumber) -> String? {
    MTRRequestCommandNameForID(clusterID, commandID)
}

public func MTREventNameForID(_ clusterID: NSNumber, _ eventID: NSNumber) -> String? {
    if clusterID.uint32Value == 0x28, eventID.uint32Value == 0 { return "StartUp" }
    return nil
}

