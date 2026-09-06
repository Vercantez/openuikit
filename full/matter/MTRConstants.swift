import Foundation

public let MTRArrayValueType = "Array"
public let MTRAttributePathKey = "attributePath"
public let MTRBooleanValueType = "Boolean"
public let MTRCommandPathKey = "commandPath"
public let MTRContextTagKey = "contextTag"
public let MTRDataKey = "data"
public let MTRDataVersionKey = "dataVersion"
public let MTRDoubleValueType = "Double"
public let MTRErrorKey = "error"
public let MTREventIsHistoricalKey = "historical"
public let MTREventNumberKey = "eventNumber"
public let MTREventPathKey = "eventPath"
public let MTREventPriorityKey = "eventPriority"
public let MTREventSystemUpTimeKey = "systemUpTime"
public let MTREventTimeTypeKey = "eventTimeType"
public let MTREventTimestampDateKey = "timestampDate"
public let MTRFloatValueType = "Float"
public let MTRNullValueType = "Null"
public let MTROctetStringValueType = "OctetString"
public let MTRPreviousDataKey = "previousData"
public let MTRSignedIntegerValueType = "SignedInteger"
public let MTRStructureValueType = "Structure"
public let MTRTypeKey = "type"
public let MTRUTF8StringValueType = "UTF8String"
public let MTRUnsignedIntegerValueType = "UnsignedInteger"
public let MTRValueKey = "value"
public let MTRDeviceControllerRegistrationControllerCompressedFabricIDKey =
    "MTRDeviceControllerRegistrationControllerCompressedFabricIDKey"
public let MTRDeviceControllerRegistrationControllerContextKey =
    "MTRDeviceControllerRegistrationControllerContextKey"
public let MTRDeviceControllerRegistrationControllerIsRunningKey =
    "MTRDeviceControllerRegistrationControllerIsRunningKey"
public let MTRDeviceControllerRegistrationControllerNodeIDKey =
    "MTRDeviceControllerRegistrationControllerNodeIDKey"
public let MTRDeviceControllerRegistrationDeviceInternalStateKey =
    "MTRDeviceControllerRegistrationDeviceInternalStateKey"
public let MTRDeviceControllerRegistrationNodeIDKey = "MTRDeviceControllerRegistrationNodeIDKey"
public let MTRDeviceControllerRegistrationNodeIDsKey = "MTRDeviceControllerRegistrationNodeIDsKey"
public let MTRSizeThreadExtendedPANID = 8
public let MTRSizeThreadExtendedPanId = 8
public let MTRSizeThreadMasterKey = 16
public let MTRSizeThreadNetworkName = 16
public let MTRSizeThreadPANID = 2
public let MTRSizeThreadPSKc = 16
public let MTR_ENABLE_PROVISIONAL: Int32 = 0
public let MTR_ENABLE_UNSTABLE_API: Int32 = 0
public let MTR_NO_AVAILABILITY: Int32 = 0

public func MTRMakeDataValue(type: String, value: Any?) -> [String: Any] {
    var dict: [String: Any] = [MTRTypeKey: type]
    if type != MTRNullValueType, let value {
        dict[MTRValueKey] = value
    }
    return dict
}

public func MTRMakeAttributeResponse(path: MTRAttributePath, data: [String: Any]) -> [String: Any] {
    [MTRAttributePathKey: path, MTRDataKey: data]
}

public func MTRMakeEventResponse(path: MTREventPath, data: [String: Any]) -> [String: Any] {
    [MTREventPathKey: path, MTRDataKey: data]
}

public func MTRMakeCommandResponse(path: MTRCommandPath, data: [String: Any]) -> [String: Any] {
    [MTRCommandPathKey: path, MTRDataKey: data]
}

public func MTRMakeErrorResponse(error: any Error) -> [String: Any] {
    [MTRErrorKey: error]
}
