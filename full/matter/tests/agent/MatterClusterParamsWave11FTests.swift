import Foundation
import Dispatch
import Matter

func testMTRSwitchClusterInitialPressEventParamsWave11() {
    let _MTRSwitchClusterInitialPressEvent = MTRSwitchClusterInitialPressEvent()
    _MTRSwitchClusterInitialPressEvent.newPosition = n(1)
    _ = _MTRSwitchClusterInitialPressEvent.newPosition
    mtrRequire(_MTRSwitchClusterInitialPressEvent.description.contains("MTRSwitchClusterInitialPressEvent"), "MTRSwitchClusterInitialPressEvent desc")
}

func testMTRSwitchClusterLongPressEventParamsWave11() {
    let _MTRSwitchClusterLongPressEvent = MTRSwitchClusterLongPressEvent()
    _MTRSwitchClusterLongPressEvent.newPosition = n(1)
    _ = _MTRSwitchClusterLongPressEvent.newPosition
    mtrRequire(_MTRSwitchClusterLongPressEvent.description.contains("MTRSwitchClusterLongPressEvent"), "MTRSwitchClusterLongPressEvent desc")
}

func testMTRSwitchClusterLongReleaseEventParamsWave11() {
    let _MTRSwitchClusterLongReleaseEvent = MTRSwitchClusterLongReleaseEvent()
    _MTRSwitchClusterLongReleaseEvent.previousPosition = n(1)
    _ = _MTRSwitchClusterLongReleaseEvent.previousPosition
    mtrRequire(_MTRSwitchClusterLongReleaseEvent.description.contains("MTRSwitchClusterLongReleaseEvent"), "MTRSwitchClusterLongReleaseEvent desc")
}

func testMTRSwitchClusterMultiPressCompleteEventParamsWave11() {
    let _MTRSwitchClusterMultiPressCompleteEvent = MTRSwitchClusterMultiPressCompleteEvent()
    _MTRSwitchClusterMultiPressCompleteEvent.newPosition = n(1)
    _ = _MTRSwitchClusterMultiPressCompleteEvent.newPosition
    _MTRSwitchClusterMultiPressCompleteEvent.previousPosition = n(1)
    _ = _MTRSwitchClusterMultiPressCompleteEvent.previousPosition
    _MTRSwitchClusterMultiPressCompleteEvent.totalNumberOfPressesCounted = n(1)
    _ = _MTRSwitchClusterMultiPressCompleteEvent.totalNumberOfPressesCounted
    mtrRequire(_MTRSwitchClusterMultiPressCompleteEvent.description.contains("MTRSwitchClusterMultiPressCompleteEvent"), "MTRSwitchClusterMultiPressCompleteEvent desc")
}

func testMTRSwitchClusterMultiPressOngoingEventParamsWave11() {
    let _MTRSwitchClusterMultiPressOngoingEvent = MTRSwitchClusterMultiPressOngoingEvent()
    _MTRSwitchClusterMultiPressOngoingEvent.currentNumberOfPressesCounted = n(1)
    _ = _MTRSwitchClusterMultiPressOngoingEvent.currentNumberOfPressesCounted
    _MTRSwitchClusterMultiPressOngoingEvent.newPosition = n(1)
    _ = _MTRSwitchClusterMultiPressOngoingEvent.newPosition
    mtrRequire(_MTRSwitchClusterMultiPressOngoingEvent.description.contains("MTRSwitchClusterMultiPressOngoingEvent"), "MTRSwitchClusterMultiPressOngoingEvent desc")
}

func testMTRSwitchClusterShortReleaseEventParamsWave11() {
    let _MTRSwitchClusterShortReleaseEvent = MTRSwitchClusterShortReleaseEvent()
    _MTRSwitchClusterShortReleaseEvent.previousPosition = n(1)
    _ = _MTRSwitchClusterShortReleaseEvent.previousPosition
    mtrRequire(_MTRSwitchClusterShortReleaseEvent.description.contains("MTRSwitchClusterShortReleaseEvent"), "MTRSwitchClusterShortReleaseEvent desc")
}

func testMTRSwitchClusterSwitchLatchedEventParamsWave11() {
    let _MTRSwitchClusterSwitchLatchedEvent = MTRSwitchClusterSwitchLatchedEvent()
    _MTRSwitchClusterSwitchLatchedEvent.newPosition = n(1)
    _ = _MTRSwitchClusterSwitchLatchedEvent.newPosition
    mtrRequire(_MTRSwitchClusterSwitchLatchedEvent.description.contains("MTRSwitchClusterSwitchLatchedEvent"), "MTRSwitchClusterSwitchLatchedEvent desc")
}

func testMTRTargetNavigatorClusterNavigateTargetParamsParamsWave11() {
    let _MTRTargetNavigatorClusterNavigateTargetParams = MTRTargetNavigatorClusterNavigateTargetParams()
    _MTRTargetNavigatorClusterNavigateTargetParams.data = "x"
    _ = _MTRTargetNavigatorClusterNavigateTargetParams.data
    _MTRTargetNavigatorClusterNavigateTargetParams.serverSideProcessingTimeout = n(1)
    _ = _MTRTargetNavigatorClusterNavigateTargetParams.serverSideProcessingTimeout
    _MTRTargetNavigatorClusterNavigateTargetParams.target = n(1)
    _ = _MTRTargetNavigatorClusterNavigateTargetParams.target
    _MTRTargetNavigatorClusterNavigateTargetParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRTargetNavigatorClusterNavigateTargetParams.timedInvokeTimeoutMs
    mtrRequire(_MTRTargetNavigatorClusterNavigateTargetParams.description.contains("MTRTargetNavigatorClusterNavigateTargetParams"), "MTRTargetNavigatorClusterNavigateTargetParams desc")
}

func testMTRTargetNavigatorClusterNavigateTargetResponseParamsParamsWave11() {
    let _MTRTargetNavigatorClusterNavigateTargetResponseParams = (try? MTRTargetNavigatorClusterNavigateTargetResponseParams(responseValue: [MTRDataKey: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1))])) ?? MTRTargetNavigatorClusterNavigateTargetResponseParams()
    _MTRTargetNavigatorClusterNavigateTargetResponseParams.data = "x"
    _ = _MTRTargetNavigatorClusterNavigateTargetResponseParams.data
    _MTRTargetNavigatorClusterNavigateTargetResponseParams.status = n(1)
    _ = _MTRTargetNavigatorClusterNavigateTargetResponseParams.status
    _MTRTargetNavigatorClusterNavigateTargetResponseParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRTargetNavigatorClusterNavigateTargetResponseParams.timedInvokeTimeoutMs
    mtrRequire(_MTRTargetNavigatorClusterNavigateTargetResponseParams.description.contains("MTRTargetNavigatorClusterNavigateTargetResponseParams"), "MTRTargetNavigatorClusterNavigateTargetResponseParams desc")
}

func testMTRTargetNavigatorClusterTargetInfoParamsWave11() {
    let _MTRTargetNavigatorClusterTargetInfo = MTRTargetNavigatorClusterTargetInfo()
    _MTRTargetNavigatorClusterTargetInfo.identifier = n(1)
    _ = _MTRTargetNavigatorClusterTargetInfo.identifier
    _MTRTargetNavigatorClusterTargetInfo.name = "x"
    _ = _MTRTargetNavigatorClusterTargetInfo.name
    mtrRequire(!_MTRTargetNavigatorClusterTargetInfo.description.isEmpty, "MTRTargetNavigatorClusterTargetInfo desc")
}

func testMTRTargetNavigatorClusterTargetInfoStructParamsWave11() {
    let _MTRTargetNavigatorClusterTargetInfoStruct = MTRTargetNavigatorClusterTargetInfoStruct()
    _MTRTargetNavigatorClusterTargetInfoStruct.identifier = n(1)
    _ = _MTRTargetNavigatorClusterTargetInfoStruct.identifier
    _MTRTargetNavigatorClusterTargetInfoStruct.name = "x"
    _ = _MTRTargetNavigatorClusterTargetInfoStruct.name
    mtrRequire(_MTRTargetNavigatorClusterTargetInfoStruct.description.contains("MTRTargetNavigatorClusterTargetInfoStruct"), "MTRTargetNavigatorClusterTargetInfoStruct desc")
}

func testMTRTargetNavigatorClusterTargetUpdatedEventParamsWave11() {
    let _MTRTargetNavigatorClusterTargetUpdatedEvent = MTRTargetNavigatorClusterTargetUpdatedEvent()
    _MTRTargetNavigatorClusterTargetUpdatedEvent.currentTarget = n(1)
    _ = _MTRTargetNavigatorClusterTargetUpdatedEvent.currentTarget
    _MTRTargetNavigatorClusterTargetUpdatedEvent.data = Data([1])
    _ = _MTRTargetNavigatorClusterTargetUpdatedEvent.data
    _MTRTargetNavigatorClusterTargetUpdatedEvent.targetList = [n(1)] as [Any]
    _ = _MTRTargetNavigatorClusterTargetUpdatedEvent.targetList
    mtrRequire(_MTRTargetNavigatorClusterTargetUpdatedEvent.description.contains("MTRTargetNavigatorClusterTargetUpdatedEvent"), "MTRTargetNavigatorClusterTargetUpdatedEvent desc")
}

func testMTRTemperatureControlClusterSetTemperatureParamsParamsWave11() {
    let _MTRTemperatureControlClusterSetTemperatureParams = MTRTemperatureControlClusterSetTemperatureParams()
    _MTRTemperatureControlClusterSetTemperatureParams.serverSideProcessingTimeout = n(1)
    _ = _MTRTemperatureControlClusterSetTemperatureParams.serverSideProcessingTimeout
    _MTRTemperatureControlClusterSetTemperatureParams.targetTemperature = n(1)
    _ = _MTRTemperatureControlClusterSetTemperatureParams.targetTemperature
    _MTRTemperatureControlClusterSetTemperatureParams.targetTemperatureLevel = n(1)
    _ = _MTRTemperatureControlClusterSetTemperatureParams.targetTemperatureLevel
    _MTRTemperatureControlClusterSetTemperatureParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRTemperatureControlClusterSetTemperatureParams.timedInvokeTimeoutMs
    mtrRequire(_MTRTemperatureControlClusterSetTemperatureParams.description.contains("MTRTemperatureControlClusterSetTemperatureParams"), "MTRTemperatureControlClusterSetTemperatureParams desc")
}

func testMTRTestClusterClusterBooleanResponseParamsParamsWave11() {
    let _MTRTestClusterClusterBooleanResponseParams = MTRTestClusterClusterBooleanResponseParams()
    _MTRTestClusterClusterBooleanResponseParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRTestClusterClusterBooleanResponseParams.timedInvokeTimeoutMs
    _MTRTestClusterClusterBooleanResponseParams.value = n(1)
    _ = _MTRTestClusterClusterBooleanResponseParams.value
    mtrRequire(!_MTRTestClusterClusterBooleanResponseParams.description.isEmpty, "MTRTestClusterClusterBooleanResponseParams desc")
}

func testMTRTestClusterClusterDoubleNestedStructListParamsWave11() {
    let _MTRTestClusterClusterDoubleNestedStructList = MTRTestClusterClusterDoubleNestedStructList()
    _MTRTestClusterClusterDoubleNestedStructList.a = [n(1)] as [Any]
    _ = _MTRTestClusterClusterDoubleNestedStructList.a
    mtrRequire(!_MTRTestClusterClusterDoubleNestedStructList.description.isEmpty, "MTRTestClusterClusterDoubleNestedStructList desc")
}

func testMTRTestClusterClusterNestedStructParamsWave11() {
    let _MTRTestClusterClusterNestedStruct = MTRTestClusterClusterNestedStruct()
    _MTRTestClusterClusterNestedStruct.a = n(1)
    _ = _MTRTestClusterClusterNestedStruct.a
    _MTRTestClusterClusterNestedStruct.b = n(1)
    _ = _MTRTestClusterClusterNestedStruct.b
    _MTRTestClusterClusterNestedStruct.c = MTRTestClusterClusterSimpleStruct()
    _ = _MTRTestClusterClusterNestedStruct.c
    mtrRequire(!_MTRTestClusterClusterNestedStruct.description.isEmpty, "MTRTestClusterClusterNestedStruct desc")
}

func testMTRTestClusterClusterNestedStructListParamsWave11() {
    let _MTRTestClusterClusterNestedStructList = MTRTestClusterClusterNestedStructList()
    _MTRTestClusterClusterNestedStructList.a = n(1)
    _ = _MTRTestClusterClusterNestedStructList.a
    _MTRTestClusterClusterNestedStructList.b = n(1)
    _ = _MTRTestClusterClusterNestedStructList.b
    _MTRTestClusterClusterNestedStructList.c = MTRTestClusterClusterSimpleStruct()
    _ = _MTRTestClusterClusterNestedStructList.c
    _MTRTestClusterClusterNestedStructList.d = [n(1)] as [Any]
    _ = _MTRTestClusterClusterNestedStructList.d
    _MTRTestClusterClusterNestedStructList.e = [n(1)] as [Any]
    _ = _MTRTestClusterClusterNestedStructList.e
    _MTRTestClusterClusterNestedStructList.f = [n(1)] as [Any]
    _ = _MTRTestClusterClusterNestedStructList.f
    _MTRTestClusterClusterNestedStructList.g = [n(1)] as [Any]
    _ = _MTRTestClusterClusterNestedStructList.g
    mtrRequire(!_MTRTestClusterClusterNestedStructList.description.isEmpty, "MTRTestClusterClusterNestedStructList desc")
}

func testMTRTestClusterClusterNullablesAndOptionalsStructParamsWave11() {
    let _MTRTestClusterClusterNullablesAndOptionalsStruct = MTRTestClusterClusterNullablesAndOptionalsStruct()
    _MTRTestClusterClusterNullablesAndOptionalsStruct.nullableInt = n(1)
    _ = _MTRTestClusterClusterNullablesAndOptionalsStruct.nullableInt
    _MTRTestClusterClusterNullablesAndOptionalsStruct.nullableList = [n(1)] as [Any]
    _ = _MTRTestClusterClusterNullablesAndOptionalsStruct.nullableList
    _MTRTestClusterClusterNullablesAndOptionalsStruct.nullableOptionalInt = n(1)
    _ = _MTRTestClusterClusterNullablesAndOptionalsStruct.nullableOptionalInt
    _MTRTestClusterClusterNullablesAndOptionalsStruct.nullableOptionalList = [n(1)] as [Any]
    _ = _MTRTestClusterClusterNullablesAndOptionalsStruct.nullableOptionalList
    _MTRTestClusterClusterNullablesAndOptionalsStruct.nullableOptionalString = "x"
    _ = _MTRTestClusterClusterNullablesAndOptionalsStruct.nullableOptionalString
    _MTRTestClusterClusterNullablesAndOptionalsStruct.nullableOptionalStruct = MTRTestClusterClusterSimpleStruct()
    _ = _MTRTestClusterClusterNullablesAndOptionalsStruct.nullableOptionalStruct
    _MTRTestClusterClusterNullablesAndOptionalsStruct.nullableString = "x"
    _ = _MTRTestClusterClusterNullablesAndOptionalsStruct.nullableString
    _MTRTestClusterClusterNullablesAndOptionalsStruct.nullableStruct = MTRTestClusterClusterSimpleStruct()
    _ = _MTRTestClusterClusterNullablesAndOptionalsStruct.nullableStruct
    _MTRTestClusterClusterNullablesAndOptionalsStruct.optionalInt = n(1)
    _ = _MTRTestClusterClusterNullablesAndOptionalsStruct.optionalInt
    _MTRTestClusterClusterNullablesAndOptionalsStruct.optionalList = [n(1)] as [Any]
    _ = _MTRTestClusterClusterNullablesAndOptionalsStruct.optionalList
    _MTRTestClusterClusterNullablesAndOptionalsStruct.optionalString = "x"
    _ = _MTRTestClusterClusterNullablesAndOptionalsStruct.optionalString
    _MTRTestClusterClusterNullablesAndOptionalsStruct.optionalStruct = MTRTestClusterClusterSimpleStruct()
    _ = _MTRTestClusterClusterNullablesAndOptionalsStruct.optionalStruct
    mtrRequire(!_MTRTestClusterClusterNullablesAndOptionalsStruct.description.isEmpty, "MTRTestClusterClusterNullablesAndOptionalsStruct desc")
}

func testMTRTestClusterClusterSimpleStructParamsWave11() {
    let _MTRTestClusterClusterSimpleStruct = MTRTestClusterClusterSimpleStruct()
    _MTRTestClusterClusterSimpleStruct.a = n(1)
    _ = _MTRTestClusterClusterSimpleStruct.a
    _MTRTestClusterClusterSimpleStruct.b = n(1)
    _ = _MTRTestClusterClusterSimpleStruct.b
    _MTRTestClusterClusterSimpleStruct.c = n(1)
    _ = _MTRTestClusterClusterSimpleStruct.c
    _MTRTestClusterClusterSimpleStruct.d = Data([1])
    _ = _MTRTestClusterClusterSimpleStruct.d
    _MTRTestClusterClusterSimpleStruct.e = "x"
    _ = _MTRTestClusterClusterSimpleStruct.e
    _MTRTestClusterClusterSimpleStruct.f = n(1)
    _ = _MTRTestClusterClusterSimpleStruct.f
    _MTRTestClusterClusterSimpleStruct.g = n(1)
    _ = _MTRTestClusterClusterSimpleStruct.g
    _MTRTestClusterClusterSimpleStruct.h = n(1)
    _ = _MTRTestClusterClusterSimpleStruct.h
    mtrRequire(!_MTRTestClusterClusterSimpleStruct.description.isEmpty, "MTRTestClusterClusterSimpleStruct desc")
}

func testMTRTestClusterClusterSimpleStructEchoRequestParamsParamsWave11() {
    let _MTRTestClusterClusterSimpleStructEchoRequestParams = MTRTestClusterClusterSimpleStructEchoRequestParams()
    _MTRTestClusterClusterSimpleStructEchoRequestParams.arg1 = MTRUnitTestingClusterSimpleStruct()
    _ = _MTRTestClusterClusterSimpleStructEchoRequestParams.arg1
    _MTRTestClusterClusterSimpleStructEchoRequestParams.serverSideProcessingTimeout = n(1)
    _ = _MTRTestClusterClusterSimpleStructEchoRequestParams.serverSideProcessingTimeout
    _MTRTestClusterClusterSimpleStructEchoRequestParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRTestClusterClusterSimpleStructEchoRequestParams.timedInvokeTimeoutMs
    mtrRequire(!_MTRTestClusterClusterSimpleStructEchoRequestParams.description.isEmpty, "MTRTestClusterClusterSimpleStructEchoRequestParams desc")
}

func testMTRTestClusterClusterSimpleStructResponseParamsParamsWave11() {
    let _MTRTestClusterClusterSimpleStructResponseParams = MTRTestClusterClusterSimpleStructResponseParams()
    _MTRTestClusterClusterSimpleStructResponseParams.arg1 = MTRUnitTestingClusterSimpleStruct()
    _ = _MTRTestClusterClusterSimpleStructResponseParams.arg1
    _MTRTestClusterClusterSimpleStructResponseParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRTestClusterClusterSimpleStructResponseParams.timedInvokeTimeoutMs
    mtrRequire(!_MTRTestClusterClusterSimpleStructResponseParams.description.isEmpty, "MTRTestClusterClusterSimpleStructResponseParams desc")
}

func testMTRTestClusterClusterTestAddArgumentsParamsParamsWave11() {
    let _MTRTestClusterClusterTestAddArgumentsParams = MTRTestClusterClusterTestAddArgumentsParams()
    _MTRTestClusterClusterTestAddArgumentsParams.arg1 = n(1)
    _ = _MTRTestClusterClusterTestAddArgumentsParams.arg1
    _MTRTestClusterClusterTestAddArgumentsParams.arg2 = n(1)
    _ = _MTRTestClusterClusterTestAddArgumentsParams.arg2
    _MTRTestClusterClusterTestAddArgumentsParams.serverSideProcessingTimeout = n(1)
    _ = _MTRTestClusterClusterTestAddArgumentsParams.serverSideProcessingTimeout
    _MTRTestClusterClusterTestAddArgumentsParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRTestClusterClusterTestAddArgumentsParams.timedInvokeTimeoutMs
    mtrRequire(!_MTRTestClusterClusterTestAddArgumentsParams.description.isEmpty, "MTRTestClusterClusterTestAddArgumentsParams desc")
}

func testMTRTestClusterClusterTestAddArgumentsResponseParamsParamsWave11() {
    let _MTRTestClusterClusterTestAddArgumentsResponseParams = MTRTestClusterClusterTestAddArgumentsResponseParams()
    _MTRTestClusterClusterTestAddArgumentsResponseParams.returnValue = n(1)
    _ = _MTRTestClusterClusterTestAddArgumentsResponseParams.returnValue
    _MTRTestClusterClusterTestAddArgumentsResponseParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRTestClusterClusterTestAddArgumentsResponseParams.timedInvokeTimeoutMs
    mtrRequire(!_MTRTestClusterClusterTestAddArgumentsResponseParams.description.isEmpty, "MTRTestClusterClusterTestAddArgumentsResponseParams desc")
}

func testMTRTestClusterClusterTestComplexNullableOptionalRequestParamsParamsWave11() {
    let _MTRTestClusterClusterTestComplexNullableOptionalRequestParams = MTRTestClusterClusterTestComplexNullableOptionalRequestParams()
    _MTRTestClusterClusterTestComplexNullableOptionalRequestParams.nullableInt = n(1)
    _ = _MTRTestClusterClusterTestComplexNullableOptionalRequestParams.nullableInt
    _MTRTestClusterClusterTestComplexNullableOptionalRequestParams.nullableList = [n(1)] as [Any]
    _ = _MTRTestClusterClusterTestComplexNullableOptionalRequestParams.nullableList
    _MTRTestClusterClusterTestComplexNullableOptionalRequestParams.nullableOptionalInt = n(1)
    _ = _MTRTestClusterClusterTestComplexNullableOptionalRequestParams.nullableOptionalInt
    _MTRTestClusterClusterTestComplexNullableOptionalRequestParams.nullableOptionalList = [n(1)] as [Any]
    _ = _MTRTestClusterClusterTestComplexNullableOptionalRequestParams.nullableOptionalList
    _MTRTestClusterClusterTestComplexNullableOptionalRequestParams.nullableOptionalString = "x"
    _ = _MTRTestClusterClusterTestComplexNullableOptionalRequestParams.nullableOptionalString
    _MTRTestClusterClusterTestComplexNullableOptionalRequestParams.nullableOptionalStruct = MTRUnitTestingClusterSimpleStruct()
    _ = _MTRTestClusterClusterTestComplexNullableOptionalRequestParams.nullableOptionalStruct
    _MTRTestClusterClusterTestComplexNullableOptionalRequestParams.nullableString = "x"
    _ = _MTRTestClusterClusterTestComplexNullableOptionalRequestParams.nullableString
    _MTRTestClusterClusterTestComplexNullableOptionalRequestParams.nullableStruct = MTRUnitTestingClusterSimpleStruct()
    _ = _MTRTestClusterClusterTestComplexNullableOptionalRequestParams.nullableStruct
    _MTRTestClusterClusterTestComplexNullableOptionalRequestParams.optionalInt = n(1)
    _ = _MTRTestClusterClusterTestComplexNullableOptionalRequestParams.optionalInt
    _MTRTestClusterClusterTestComplexNullableOptionalRequestParams.optionalList = [n(1)] as [Any]
    _ = _MTRTestClusterClusterTestComplexNullableOptionalRequestParams.optionalList
    _MTRTestClusterClusterTestComplexNullableOptionalRequestParams.optionalString = "x"
    _ = _MTRTestClusterClusterTestComplexNullableOptionalRequestParams.optionalString
    _MTRTestClusterClusterTestComplexNullableOptionalRequestParams.optionalStruct = MTRUnitTestingClusterSimpleStruct()
    _ = _MTRTestClusterClusterTestComplexNullableOptionalRequestParams.optionalStruct
    _MTRTestClusterClusterTestComplexNullableOptionalRequestParams.serverSideProcessingTimeout = n(1)
    _ = _MTRTestClusterClusterTestComplexNullableOptionalRequestParams.serverSideProcessingTimeout
    _MTRTestClusterClusterTestComplexNullableOptionalRequestParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRTestClusterClusterTestComplexNullableOptionalRequestParams.timedInvokeTimeoutMs
    mtrRequire(!_MTRTestClusterClusterTestComplexNullableOptionalRequestParams.description.isEmpty, "MTRTestClusterClusterTestComplexNullableOptionalRequestParams desc")
}

func testMTRTestClusterClusterTestComplexNullableOptionalResponseParamsParamsWave11() {
    let _MTRTestClusterClusterTestComplexNullableOptionalResponseParams = MTRTestClusterClusterTestComplexNullableOptionalResponseParams()
    _MTRTestClusterClusterTestComplexNullableOptionalResponseParams.nullableIntValue = n(1)
    _ = _MTRTestClusterClusterTestComplexNullableOptionalResponseParams.nullableIntValue
    _MTRTestClusterClusterTestComplexNullableOptionalResponseParams.nullableIntWasNull = n(1)
    _ = _MTRTestClusterClusterTestComplexNullableOptionalResponseParams.nullableIntWasNull
    _MTRTestClusterClusterTestComplexNullableOptionalResponseParams.nullableListValue = [n(1)] as [Any]
    _ = _MTRTestClusterClusterTestComplexNullableOptionalResponseParams.nullableListValue
    _MTRTestClusterClusterTestComplexNullableOptionalResponseParams.nullableListWasNull = n(1)
    _ = _MTRTestClusterClusterTestComplexNullableOptionalResponseParams.nullableListWasNull
    _MTRTestClusterClusterTestComplexNullableOptionalResponseParams.nullableOptionalIntValue = n(1)
    _ = _MTRTestClusterClusterTestComplexNullableOptionalResponseParams.nullableOptionalIntValue
    _MTRTestClusterClusterTestComplexNullableOptionalResponseParams.nullableOptionalIntWasNull = n(1)
    _ = _MTRTestClusterClusterTestComplexNullableOptionalResponseParams.nullableOptionalIntWasNull
    _MTRTestClusterClusterTestComplexNullableOptionalResponseParams.nullableOptionalIntWasPresent = n(1)
    _ = _MTRTestClusterClusterTestComplexNullableOptionalResponseParams.nullableOptionalIntWasPresent
    _MTRTestClusterClusterTestComplexNullableOptionalResponseParams.nullableOptionalListValue = [n(1)] as [Any]
    _ = _MTRTestClusterClusterTestComplexNullableOptionalResponseParams.nullableOptionalListValue
    _MTRTestClusterClusterTestComplexNullableOptionalResponseParams.nullableOptionalListWasNull = n(1)
    _ = _MTRTestClusterClusterTestComplexNullableOptionalResponseParams.nullableOptionalListWasNull
    _MTRTestClusterClusterTestComplexNullableOptionalResponseParams.nullableOptionalListWasPresent = n(1)
    _ = _MTRTestClusterClusterTestComplexNullableOptionalResponseParams.nullableOptionalListWasPresent
    _MTRTestClusterClusterTestComplexNullableOptionalResponseParams.nullableOptionalStringValue = "x"
    _ = _MTRTestClusterClusterTestComplexNullableOptionalResponseParams.nullableOptionalStringValue
    _MTRTestClusterClusterTestComplexNullableOptionalResponseParams.nullableOptionalStringWasNull = n(1)
    _ = _MTRTestClusterClusterTestComplexNullableOptionalResponseParams.nullableOptionalStringWasNull
    _MTRTestClusterClusterTestComplexNullableOptionalResponseParams.nullableOptionalStringWasPresent = n(1)
    _ = _MTRTestClusterClusterTestComplexNullableOptionalResponseParams.nullableOptionalStringWasPresent
    _MTRTestClusterClusterTestComplexNullableOptionalResponseParams.nullableOptionalStructValue = MTRUnitTestingClusterSimpleStruct()
    _ = _MTRTestClusterClusterTestComplexNullableOptionalResponseParams.nullableOptionalStructValue
    _MTRTestClusterClusterTestComplexNullableOptionalResponseParams.nullableOptionalStructWasNull = n(1)
    _ = _MTRTestClusterClusterTestComplexNullableOptionalResponseParams.nullableOptionalStructWasNull
    _MTRTestClusterClusterTestComplexNullableOptionalResponseParams.nullableOptionalStructWasPresent = n(1)
    _ = _MTRTestClusterClusterTestComplexNullableOptionalResponseParams.nullableOptionalStructWasPresent
    _MTRTestClusterClusterTestComplexNullableOptionalResponseParams.nullableStringValue = "x"
    _ = _MTRTestClusterClusterTestComplexNullableOptionalResponseParams.nullableStringValue
    _MTRTestClusterClusterTestComplexNullableOptionalResponseParams.nullableStringWasNull = n(1)
    _ = _MTRTestClusterClusterTestComplexNullableOptionalResponseParams.nullableStringWasNull
    _MTRTestClusterClusterTestComplexNullableOptionalResponseParams.nullableStructValue = MTRUnitTestingClusterSimpleStruct()
    _ = _MTRTestClusterClusterTestComplexNullableOptionalResponseParams.nullableStructValue
    _MTRTestClusterClusterTestComplexNullableOptionalResponseParams.nullableStructWasNull = n(1)
    _ = _MTRTestClusterClusterTestComplexNullableOptionalResponseParams.nullableStructWasNull
    _MTRTestClusterClusterTestComplexNullableOptionalResponseParams.optionalIntValue = n(1)
    _ = _MTRTestClusterClusterTestComplexNullableOptionalResponseParams.optionalIntValue
    _MTRTestClusterClusterTestComplexNullableOptionalResponseParams.optionalIntWasPresent = n(1)
    _ = _MTRTestClusterClusterTestComplexNullableOptionalResponseParams.optionalIntWasPresent
    _MTRTestClusterClusterTestComplexNullableOptionalResponseParams.optionalListValue = [n(1)] as [Any]
    _ = _MTRTestClusterClusterTestComplexNullableOptionalResponseParams.optionalListValue
    _MTRTestClusterClusterTestComplexNullableOptionalResponseParams.optionalListWasPresent = n(1)
    _ = _MTRTestClusterClusterTestComplexNullableOptionalResponseParams.optionalListWasPresent
    _MTRTestClusterClusterTestComplexNullableOptionalResponseParams.optionalStringValue = "x"
    _ = _MTRTestClusterClusterTestComplexNullableOptionalResponseParams.optionalStringValue
    _MTRTestClusterClusterTestComplexNullableOptionalResponseParams.optionalStringWasPresent = n(1)
    _ = _MTRTestClusterClusterTestComplexNullableOptionalResponseParams.optionalStringWasPresent
    _MTRTestClusterClusterTestComplexNullableOptionalResponseParams.optionalStructValue = MTRUnitTestingClusterSimpleStruct()
    _ = _MTRTestClusterClusterTestComplexNullableOptionalResponseParams.optionalStructValue
    _MTRTestClusterClusterTestComplexNullableOptionalResponseParams.optionalStructWasPresent = n(1)
    _ = _MTRTestClusterClusterTestComplexNullableOptionalResponseParams.optionalStructWasPresent
    _MTRTestClusterClusterTestComplexNullableOptionalResponseParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRTestClusterClusterTestComplexNullableOptionalResponseParams.timedInvokeTimeoutMs
    mtrRequire(!_MTRTestClusterClusterTestComplexNullableOptionalResponseParams.description.isEmpty, "MTRTestClusterClusterTestComplexNullableOptionalResponseParams desc")
}

func testMTRTestClusterClusterTestEmitTestEventRequestParamsParamsWave11() {
    let _MTRTestClusterClusterTestEmitTestEventRequestParams = MTRTestClusterClusterTestEmitTestEventRequestParams()
    _MTRTestClusterClusterTestEmitTestEventRequestParams.arg1 = n(1)
    _ = _MTRTestClusterClusterTestEmitTestEventRequestParams.arg1
    _MTRTestClusterClusterTestEmitTestEventRequestParams.arg2 = n(1)
    _ = _MTRTestClusterClusterTestEmitTestEventRequestParams.arg2
    _MTRTestClusterClusterTestEmitTestEventRequestParams.arg3 = n(1)
    _ = _MTRTestClusterClusterTestEmitTestEventRequestParams.arg3
    _MTRTestClusterClusterTestEmitTestEventRequestParams.serverSideProcessingTimeout = n(1)
    _ = _MTRTestClusterClusterTestEmitTestEventRequestParams.serverSideProcessingTimeout
    _MTRTestClusterClusterTestEmitTestEventRequestParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRTestClusterClusterTestEmitTestEventRequestParams.timedInvokeTimeoutMs
    mtrRequire(!_MTRTestClusterClusterTestEmitTestEventRequestParams.description.isEmpty, "MTRTestClusterClusterTestEmitTestEventRequestParams desc")
}

func testMTRTestClusterClusterTestEmitTestEventResponseParamsParamsWave11() {
    let _MTRTestClusterClusterTestEmitTestEventResponseParams = MTRTestClusterClusterTestEmitTestEventResponseParams()
    _MTRTestClusterClusterTestEmitTestEventResponseParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRTestClusterClusterTestEmitTestEventResponseParams.timedInvokeTimeoutMs
    _MTRTestClusterClusterTestEmitTestEventResponseParams.value = n(1)
    _ = _MTRTestClusterClusterTestEmitTestEventResponseParams.value
    mtrRequire(!_MTRTestClusterClusterTestEmitTestEventResponseParams.description.isEmpty, "MTRTestClusterClusterTestEmitTestEventResponseParams desc")
}

func testMTRTestClusterClusterTestEmitTestFabricScopedEventRequestParamsParamsWave11() {
    let _MTRTestClusterClusterTestEmitTestFabricScopedEventRequestParams = MTRTestClusterClusterTestEmitTestFabricScopedEventRequestParams()
    _MTRTestClusterClusterTestEmitTestFabricScopedEventRequestParams.arg1 = n(1)
    _ = _MTRTestClusterClusterTestEmitTestFabricScopedEventRequestParams.arg1
    _MTRTestClusterClusterTestEmitTestFabricScopedEventRequestParams.serverSideProcessingTimeout = n(1)
    _ = _MTRTestClusterClusterTestEmitTestFabricScopedEventRequestParams.serverSideProcessingTimeout
    _MTRTestClusterClusterTestEmitTestFabricScopedEventRequestParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRTestClusterClusterTestEmitTestFabricScopedEventRequestParams.timedInvokeTimeoutMs
    mtrRequire(!_MTRTestClusterClusterTestEmitTestFabricScopedEventRequestParams.description.isEmpty, "MTRTestClusterClusterTestEmitTestFabricScopedEventRequestParams desc")
}

func testMTRTestClusterClusterTestEmitTestFabricScopedEventResponseParamsParamsWave11() {
    let _MTRTestClusterClusterTestEmitTestFabricScopedEventResponseParams = MTRTestClusterClusterTestEmitTestFabricScopedEventResponseParams()
    _MTRTestClusterClusterTestEmitTestFabricScopedEventResponseParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRTestClusterClusterTestEmitTestFabricScopedEventResponseParams.timedInvokeTimeoutMs
    _MTRTestClusterClusterTestEmitTestFabricScopedEventResponseParams.value = n(1)
    _ = _MTRTestClusterClusterTestEmitTestFabricScopedEventResponseParams.value
    mtrRequire(!_MTRTestClusterClusterTestEmitTestFabricScopedEventResponseParams.description.isEmpty, "MTRTestClusterClusterTestEmitTestFabricScopedEventResponseParams desc")
}

func testMTRTestClusterClusterTestEnumsRequestParamsParamsWave11() {
    let _MTRTestClusterClusterTestEnumsRequestParams = MTRTestClusterClusterTestEnumsRequestParams()
    _MTRTestClusterClusterTestEnumsRequestParams.arg1 = n(1)
    _ = _MTRTestClusterClusterTestEnumsRequestParams.arg1
    _MTRTestClusterClusterTestEnumsRequestParams.arg2 = n(1)
    _ = _MTRTestClusterClusterTestEnumsRequestParams.arg2
    _MTRTestClusterClusterTestEnumsRequestParams.serverSideProcessingTimeout = n(1)
    _ = _MTRTestClusterClusterTestEnumsRequestParams.serverSideProcessingTimeout
    _MTRTestClusterClusterTestEnumsRequestParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRTestClusterClusterTestEnumsRequestParams.timedInvokeTimeoutMs
    mtrRequire(!_MTRTestClusterClusterTestEnumsRequestParams.description.isEmpty, "MTRTestClusterClusterTestEnumsRequestParams desc")
}

func testMTRTestClusterClusterTestEnumsResponseParamsParamsWave11() {
    let _MTRTestClusterClusterTestEnumsResponseParams = MTRTestClusterClusterTestEnumsResponseParams()
    _MTRTestClusterClusterTestEnumsResponseParams.arg1 = n(1)
    _ = _MTRTestClusterClusterTestEnumsResponseParams.arg1
    _MTRTestClusterClusterTestEnumsResponseParams.arg2 = n(1)
    _ = _MTRTestClusterClusterTestEnumsResponseParams.arg2
    _MTRTestClusterClusterTestEnumsResponseParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRTestClusterClusterTestEnumsResponseParams.timedInvokeTimeoutMs
    mtrRequire(!_MTRTestClusterClusterTestEnumsResponseParams.description.isEmpty, "MTRTestClusterClusterTestEnumsResponseParams desc")
}

func testMTRTestClusterClusterTestEventEventParamsWave11() {
    let _MTRTestClusterClusterTestEventEvent = MTRTestClusterClusterTestEventEvent()
    _MTRTestClusterClusterTestEventEvent.arg1 = n(1)
    _ = _MTRTestClusterClusterTestEventEvent.arg1
    _MTRTestClusterClusterTestEventEvent.arg2 = n(1)
    _ = _MTRTestClusterClusterTestEventEvent.arg2
    _MTRTestClusterClusterTestEventEvent.arg3 = n(1)
    _ = _MTRTestClusterClusterTestEventEvent.arg3
    _MTRTestClusterClusterTestEventEvent.arg4 = MTRTestClusterClusterSimpleStruct()
    _ = _MTRTestClusterClusterTestEventEvent.arg4
    _MTRTestClusterClusterTestEventEvent.arg5 = [n(1)] as [Any]
    _ = _MTRTestClusterClusterTestEventEvent.arg5
    _MTRTestClusterClusterTestEventEvent.arg6 = [n(1)] as [Any]
    _ = _MTRTestClusterClusterTestEventEvent.arg6
    mtrRequire(!_MTRTestClusterClusterTestEventEvent.description.isEmpty, "MTRTestClusterClusterTestEventEvent desc")
}

func testMTRTestClusterClusterTestFabricScopedParamsWave11() {
    let _MTRTestClusterClusterTestFabricScoped = MTRTestClusterClusterTestFabricScoped()
    _MTRTestClusterClusterTestFabricScoped.fabricIndex = n(1)
    _ = _MTRTestClusterClusterTestFabricScoped.fabricIndex
    _MTRTestClusterClusterTestFabricScoped.fabricSensitiveCharString = "x"
    _ = _MTRTestClusterClusterTestFabricScoped.fabricSensitiveCharString
    _MTRTestClusterClusterTestFabricScoped.fabricSensitiveInt8u = n(1)
    _ = _MTRTestClusterClusterTestFabricScoped.fabricSensitiveInt8u
    _MTRTestClusterClusterTestFabricScoped.fabricSensitiveInt8uList = [n(1)] as [Any]
    _ = _MTRTestClusterClusterTestFabricScoped.fabricSensitiveInt8uList
    _MTRTestClusterClusterTestFabricScoped.fabricSensitiveStruct = MTRTestClusterClusterSimpleStruct()
    _ = _MTRTestClusterClusterTestFabricScoped.fabricSensitiveStruct
    _MTRTestClusterClusterTestFabricScoped.nullableFabricSensitiveInt8u = n(1)
    _ = _MTRTestClusterClusterTestFabricScoped.nullableFabricSensitiveInt8u
    _MTRTestClusterClusterTestFabricScoped.nullableOptionalFabricSensitiveInt8u = n(1)
    _ = _MTRTestClusterClusterTestFabricScoped.nullableOptionalFabricSensitiveInt8u
    _MTRTestClusterClusterTestFabricScoped.optionalFabricSensitiveInt8u = n(1)
    _ = _MTRTestClusterClusterTestFabricScoped.optionalFabricSensitiveInt8u
    mtrRequire(!_MTRTestClusterClusterTestFabricScoped.description.isEmpty, "MTRTestClusterClusterTestFabricScoped desc")
}

func testMTRTestClusterClusterTestFabricScopedEventEventParamsWave11() {
    let _MTRTestClusterClusterTestFabricScopedEventEvent = MTRTestClusterClusterTestFabricScopedEventEvent()
    _MTRTestClusterClusterTestFabricScopedEventEvent.fabricIndex = n(1)
    _ = _MTRTestClusterClusterTestFabricScopedEventEvent.fabricIndex
    mtrRequire(!_MTRTestClusterClusterTestFabricScopedEventEvent.description.isEmpty, "MTRTestClusterClusterTestFabricScopedEventEvent desc")
}

func testMTRTestClusterClusterTestListInt8UArgumentRequestParamsParamsWave11() {
    let _MTRTestClusterClusterTestListInt8UArgumentRequestParams = MTRTestClusterClusterTestListInt8UArgumentRequestParams()
    _MTRTestClusterClusterTestListInt8UArgumentRequestParams.arg1 = [n(1)] as [Any]
    _ = _MTRTestClusterClusterTestListInt8UArgumentRequestParams.arg1
    _MTRTestClusterClusterTestListInt8UArgumentRequestParams.serverSideProcessingTimeout = n(1)
    _ = _MTRTestClusterClusterTestListInt8UArgumentRequestParams.serverSideProcessingTimeout
    _MTRTestClusterClusterTestListInt8UArgumentRequestParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRTestClusterClusterTestListInt8UArgumentRequestParams.timedInvokeTimeoutMs
    mtrRequire(!_MTRTestClusterClusterTestListInt8UArgumentRequestParams.description.isEmpty, "MTRTestClusterClusterTestListInt8UArgumentRequestParams desc")
}

func testMTRTestClusterClusterTestListInt8UReverseRequestParamsParamsWave11() {
    let _MTRTestClusterClusterTestListInt8UReverseRequestParams = MTRTestClusterClusterTestListInt8UReverseRequestParams()
    _MTRTestClusterClusterTestListInt8UReverseRequestParams.arg1 = [n(1)] as [Any]
    _ = _MTRTestClusterClusterTestListInt8UReverseRequestParams.arg1
    _MTRTestClusterClusterTestListInt8UReverseRequestParams.serverSideProcessingTimeout = n(1)
    _ = _MTRTestClusterClusterTestListInt8UReverseRequestParams.serverSideProcessingTimeout
    _MTRTestClusterClusterTestListInt8UReverseRequestParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRTestClusterClusterTestListInt8UReverseRequestParams.timedInvokeTimeoutMs
    mtrRequire(!_MTRTestClusterClusterTestListInt8UReverseRequestParams.description.isEmpty, "MTRTestClusterClusterTestListInt8UReverseRequestParams desc")
}

func testMTRTestClusterClusterTestListInt8UReverseResponseParamsParamsWave11() {
    let _MTRTestClusterClusterTestListInt8UReverseResponseParams = MTRTestClusterClusterTestListInt8UReverseResponseParams()
    _MTRTestClusterClusterTestListInt8UReverseResponseParams.arg1 = [n(1)] as [Any]
    _ = _MTRTestClusterClusterTestListInt8UReverseResponseParams.arg1
    _MTRTestClusterClusterTestListInt8UReverseResponseParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRTestClusterClusterTestListInt8UReverseResponseParams.timedInvokeTimeoutMs
    mtrRequire(!_MTRTestClusterClusterTestListInt8UReverseResponseParams.description.isEmpty, "MTRTestClusterClusterTestListInt8UReverseResponseParams desc")
}

func testMTRTestClusterClusterTestListNestedStructListArgumentRequestParamsParamsWave11() {
    let _MTRTestClusterClusterTestListNestedStructListArgumentRequestParams = MTRTestClusterClusterTestListNestedStructListArgumentRequestParams()
    _MTRTestClusterClusterTestListNestedStructListArgumentRequestParams.arg1 = [n(1)] as [Any]
    _ = _MTRTestClusterClusterTestListNestedStructListArgumentRequestParams.arg1
    _MTRTestClusterClusterTestListNestedStructListArgumentRequestParams.serverSideProcessingTimeout = n(1)
    _ = _MTRTestClusterClusterTestListNestedStructListArgumentRequestParams.serverSideProcessingTimeout
    _MTRTestClusterClusterTestListNestedStructListArgumentRequestParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRTestClusterClusterTestListNestedStructListArgumentRequestParams.timedInvokeTimeoutMs
    mtrRequire(!_MTRTestClusterClusterTestListNestedStructListArgumentRequestParams.description.isEmpty, "MTRTestClusterClusterTestListNestedStructListArgumentRequestParams desc")
}

func testMTRTestClusterClusterTestListStructArgumentRequestParamsParamsWave11() {
    let _MTRTestClusterClusterTestListStructArgumentRequestParams = MTRTestClusterClusterTestListStructArgumentRequestParams()
    _MTRTestClusterClusterTestListStructArgumentRequestParams.arg1 = [n(1)] as [Any]
    _ = _MTRTestClusterClusterTestListStructArgumentRequestParams.arg1
    _MTRTestClusterClusterTestListStructArgumentRequestParams.serverSideProcessingTimeout = n(1)
    _ = _MTRTestClusterClusterTestListStructArgumentRequestParams.serverSideProcessingTimeout
    _MTRTestClusterClusterTestListStructArgumentRequestParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRTestClusterClusterTestListStructArgumentRequestParams.timedInvokeTimeoutMs
    mtrRequire(!_MTRTestClusterClusterTestListStructArgumentRequestParams.description.isEmpty, "MTRTestClusterClusterTestListStructArgumentRequestParams desc")
}

func testMTRTestClusterClusterTestListStructOctetParamsWave11() {
    let _MTRTestClusterClusterTestListStructOctet = MTRTestClusterClusterTestListStructOctet()
    _MTRTestClusterClusterTestListStructOctet.member1 = n(1)
    _ = _MTRTestClusterClusterTestListStructOctet.member1
    _MTRTestClusterClusterTestListStructOctet.member2 = Data([1])
    _ = _MTRTestClusterClusterTestListStructOctet.member2
    mtrRequire(!_MTRTestClusterClusterTestListStructOctet.description.isEmpty, "MTRTestClusterClusterTestListStructOctet desc")
}

func testMTRTestClusterClusterTestNestedStructArgumentRequestParamsParamsWave11() {
    let _MTRTestClusterClusterTestNestedStructArgumentRequestParams = MTRTestClusterClusterTestNestedStructArgumentRequestParams()
    _MTRTestClusterClusterTestNestedStructArgumentRequestParams.arg1 = MTRUnitTestingClusterNestedStruct()
    _ = _MTRTestClusterClusterTestNestedStructArgumentRequestParams.arg1
    _MTRTestClusterClusterTestNestedStructArgumentRequestParams.serverSideProcessingTimeout = n(1)
    _ = _MTRTestClusterClusterTestNestedStructArgumentRequestParams.serverSideProcessingTimeout
    _MTRTestClusterClusterTestNestedStructArgumentRequestParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRTestClusterClusterTestNestedStructArgumentRequestParams.timedInvokeTimeoutMs
    mtrRequire(!_MTRTestClusterClusterTestNestedStructArgumentRequestParams.description.isEmpty, "MTRTestClusterClusterTestNestedStructArgumentRequestParams desc")
}

func testMTRTestClusterClusterTestNestedStructListArgumentRequestParamsParamsWave11() {
    let _MTRTestClusterClusterTestNestedStructListArgumentRequestParams = MTRTestClusterClusterTestNestedStructListArgumentRequestParams()
    _MTRTestClusterClusterTestNestedStructListArgumentRequestParams.arg1 = MTRUnitTestingClusterNestedStructList()
    _ = _MTRTestClusterClusterTestNestedStructListArgumentRequestParams.arg1
    _MTRTestClusterClusterTestNestedStructListArgumentRequestParams.serverSideProcessingTimeout = n(1)
    _ = _MTRTestClusterClusterTestNestedStructListArgumentRequestParams.serverSideProcessingTimeout
    _MTRTestClusterClusterTestNestedStructListArgumentRequestParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRTestClusterClusterTestNestedStructListArgumentRequestParams.timedInvokeTimeoutMs
    mtrRequire(!_MTRTestClusterClusterTestNestedStructListArgumentRequestParams.description.isEmpty, "MTRTestClusterClusterTestNestedStructListArgumentRequestParams desc")
}

func testMTRTestClusterClusterTestNotHandledParamsParamsWave11() {
    let _MTRTestClusterClusterTestNotHandledParams = MTRTestClusterClusterTestNotHandledParams()
    _MTRTestClusterClusterTestNotHandledParams.serverSideProcessingTimeout = n(1)
    _ = _MTRTestClusterClusterTestNotHandledParams.serverSideProcessingTimeout
    _MTRTestClusterClusterTestNotHandledParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRTestClusterClusterTestNotHandledParams.timedInvokeTimeoutMs
    mtrRequire(!_MTRTestClusterClusterTestNotHandledParams.description.isEmpty, "MTRTestClusterClusterTestNotHandledParams desc")
}

func testMTRTestClusterClusterTestNullableOptionalRequestParamsParamsWave11() {
    let _MTRTestClusterClusterTestNullableOptionalRequestParams = MTRTestClusterClusterTestNullableOptionalRequestParams()
    _MTRTestClusterClusterTestNullableOptionalRequestParams.arg1 = n(1)
    _ = _MTRTestClusterClusterTestNullableOptionalRequestParams.arg1
    _MTRTestClusterClusterTestNullableOptionalRequestParams.serverSideProcessingTimeout = n(1)
    _ = _MTRTestClusterClusterTestNullableOptionalRequestParams.serverSideProcessingTimeout
    _MTRTestClusterClusterTestNullableOptionalRequestParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRTestClusterClusterTestNullableOptionalRequestParams.timedInvokeTimeoutMs
    mtrRequire(!_MTRTestClusterClusterTestNullableOptionalRequestParams.description.isEmpty, "MTRTestClusterClusterTestNullableOptionalRequestParams desc")
}

func testMTRTestClusterClusterTestNullableOptionalResponseParamsParamsWave11() {
    let _MTRTestClusterClusterTestNullableOptionalResponseParams = MTRTestClusterClusterTestNullableOptionalResponseParams()
    _MTRTestClusterClusterTestNullableOptionalResponseParams.originalValue = n(1)
    _ = _MTRTestClusterClusterTestNullableOptionalResponseParams.originalValue
    _MTRTestClusterClusterTestNullableOptionalResponseParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRTestClusterClusterTestNullableOptionalResponseParams.timedInvokeTimeoutMs
    _MTRTestClusterClusterTestNullableOptionalResponseParams.value = n(1)
    _ = _MTRTestClusterClusterTestNullableOptionalResponseParams.value
    _MTRTestClusterClusterTestNullableOptionalResponseParams.wasNull = n(1)
    _ = _MTRTestClusterClusterTestNullableOptionalResponseParams.wasNull
    _MTRTestClusterClusterTestNullableOptionalResponseParams.wasPresent = n(1)
    _ = _MTRTestClusterClusterTestNullableOptionalResponseParams.wasPresent
    mtrRequire(!_MTRTestClusterClusterTestNullableOptionalResponseParams.description.isEmpty, "MTRTestClusterClusterTestNullableOptionalResponseParams desc")
}

func testMTRTestClusterClusterTestParamsParamsWave11() {
    let _MTRTestClusterClusterTestParams = MTRTestClusterClusterTestParams()
    _MTRTestClusterClusterTestParams.serverSideProcessingTimeout = n(1)
    _ = _MTRTestClusterClusterTestParams.serverSideProcessingTimeout
    _MTRTestClusterClusterTestParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRTestClusterClusterTestParams.timedInvokeTimeoutMs
    mtrRequire(!_MTRTestClusterClusterTestParams.description.isEmpty, "MTRTestClusterClusterTestParams desc")
}

func testMTRTestClusterClusterTestSimpleArgumentRequestParamsParamsWave11() {
    let _MTRTestClusterClusterTestSimpleArgumentRequestParams = MTRTestClusterClusterTestSimpleArgumentRequestParams()
    _MTRTestClusterClusterTestSimpleArgumentRequestParams.arg1 = n(1)
    _ = _MTRTestClusterClusterTestSimpleArgumentRequestParams.arg1
    _MTRTestClusterClusterTestSimpleArgumentRequestParams.serverSideProcessingTimeout = n(1)
    _ = _MTRTestClusterClusterTestSimpleArgumentRequestParams.serverSideProcessingTimeout
    _MTRTestClusterClusterTestSimpleArgumentRequestParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRTestClusterClusterTestSimpleArgumentRequestParams.timedInvokeTimeoutMs
    mtrRequire(!_MTRTestClusterClusterTestSimpleArgumentRequestParams.description.isEmpty, "MTRTestClusterClusterTestSimpleArgumentRequestParams desc")
}

func testMTRTestClusterClusterTestSimpleArgumentResponseParamsParamsWave11() {
    let _MTRTestClusterClusterTestSimpleArgumentResponseParams = MTRTestClusterClusterTestSimpleArgumentResponseParams()
    _MTRTestClusterClusterTestSimpleArgumentResponseParams.returnValue = n(1)
    _ = _MTRTestClusterClusterTestSimpleArgumentResponseParams.returnValue
    _MTRTestClusterClusterTestSimpleArgumentResponseParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRTestClusterClusterTestSimpleArgumentResponseParams.timedInvokeTimeoutMs
    mtrRequire(!_MTRTestClusterClusterTestSimpleArgumentResponseParams.description.isEmpty, "MTRTestClusterClusterTestSimpleArgumentResponseParams desc")
}

func testMTRTestClusterClusterTestSimpleOptionalArgumentRequestParamsParamsWave11() {
    let _MTRTestClusterClusterTestSimpleOptionalArgumentRequestParams = MTRTestClusterClusterTestSimpleOptionalArgumentRequestParams()
    _MTRTestClusterClusterTestSimpleOptionalArgumentRequestParams.arg1 = n(1)
    _ = _MTRTestClusterClusterTestSimpleOptionalArgumentRequestParams.arg1
    _MTRTestClusterClusterTestSimpleOptionalArgumentRequestParams.serverSideProcessingTimeout = n(1)
    _ = _MTRTestClusterClusterTestSimpleOptionalArgumentRequestParams.serverSideProcessingTimeout
    _MTRTestClusterClusterTestSimpleOptionalArgumentRequestParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRTestClusterClusterTestSimpleOptionalArgumentRequestParams.timedInvokeTimeoutMs
    mtrRequire(!_MTRTestClusterClusterTestSimpleOptionalArgumentRequestParams.description.isEmpty, "MTRTestClusterClusterTestSimpleOptionalArgumentRequestParams desc")
}

func testMTRTestClusterClusterTestSpecificParamsParamsWave11() {
    let _MTRTestClusterClusterTestSpecificParams = MTRTestClusterClusterTestSpecificParams()
    _MTRTestClusterClusterTestSpecificParams.serverSideProcessingTimeout = n(1)
    _ = _MTRTestClusterClusterTestSpecificParams.serverSideProcessingTimeout
    _MTRTestClusterClusterTestSpecificParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRTestClusterClusterTestSpecificParams.timedInvokeTimeoutMs
    mtrRequire(!_MTRTestClusterClusterTestSpecificParams.description.isEmpty, "MTRTestClusterClusterTestSpecificParams desc")
}

func testMTRTestClusterClusterTestSpecificResponseParamsParamsWave11() {
    let _MTRTestClusterClusterTestSpecificResponseParams = MTRTestClusterClusterTestSpecificResponseParams()
    _MTRTestClusterClusterTestSpecificResponseParams.returnValue = n(1)
    _ = _MTRTestClusterClusterTestSpecificResponseParams.returnValue
    _MTRTestClusterClusterTestSpecificResponseParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRTestClusterClusterTestSpecificResponseParams.timedInvokeTimeoutMs
    mtrRequire(!_MTRTestClusterClusterTestSpecificResponseParams.description.isEmpty, "MTRTestClusterClusterTestSpecificResponseParams desc")
}

func testMTRTestClusterClusterTestStructArgumentRequestParamsParamsWave11() {
    let _MTRTestClusterClusterTestStructArgumentRequestParams = MTRTestClusterClusterTestStructArgumentRequestParams()
    _MTRTestClusterClusterTestStructArgumentRequestParams.arg1 = MTRUnitTestingClusterSimpleStruct()
    _ = _MTRTestClusterClusterTestStructArgumentRequestParams.arg1
    _MTRTestClusterClusterTestStructArgumentRequestParams.serverSideProcessingTimeout = n(1)
    _ = _MTRTestClusterClusterTestStructArgumentRequestParams.serverSideProcessingTimeout
    _MTRTestClusterClusterTestStructArgumentRequestParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRTestClusterClusterTestStructArgumentRequestParams.timedInvokeTimeoutMs
    mtrRequire(!_MTRTestClusterClusterTestStructArgumentRequestParams.description.isEmpty, "MTRTestClusterClusterTestStructArgumentRequestParams desc")
}

func testMTRTestClusterClusterTestStructArrayArgumentRequestParamsParamsWave11() {
    let _MTRTestClusterClusterTestStructArrayArgumentRequestParams = MTRTestClusterClusterTestStructArrayArgumentRequestParams()
    _MTRTestClusterClusterTestStructArrayArgumentRequestParams.arg1 = [n(1)] as [Any]
    _ = _MTRTestClusterClusterTestStructArrayArgumentRequestParams.arg1
    _MTRTestClusterClusterTestStructArrayArgumentRequestParams.arg2 = [n(1)] as [Any]
    _ = _MTRTestClusterClusterTestStructArrayArgumentRequestParams.arg2
    _MTRTestClusterClusterTestStructArrayArgumentRequestParams.arg3 = [n(1)] as [Any]
    _ = _MTRTestClusterClusterTestStructArrayArgumentRequestParams.arg3
    _MTRTestClusterClusterTestStructArrayArgumentRequestParams.arg4 = [n(1)] as [Any]
    _ = _MTRTestClusterClusterTestStructArrayArgumentRequestParams.arg4
    _MTRTestClusterClusterTestStructArrayArgumentRequestParams.arg5 = n(1)
    _ = _MTRTestClusterClusterTestStructArrayArgumentRequestParams.arg5
    _MTRTestClusterClusterTestStructArrayArgumentRequestParams.arg6 = n(1)
    _ = _MTRTestClusterClusterTestStructArrayArgumentRequestParams.arg6
    _MTRTestClusterClusterTestStructArrayArgumentRequestParams.serverSideProcessingTimeout = n(1)
    _ = _MTRTestClusterClusterTestStructArrayArgumentRequestParams.serverSideProcessingTimeout
    _MTRTestClusterClusterTestStructArrayArgumentRequestParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRTestClusterClusterTestStructArrayArgumentRequestParams.timedInvokeTimeoutMs
    mtrRequire(!_MTRTestClusterClusterTestStructArrayArgumentRequestParams.description.isEmpty, "MTRTestClusterClusterTestStructArrayArgumentRequestParams desc")
}

func testMTRTestClusterClusterTestStructArrayArgumentResponseParamsParamsWave11() {
    let _MTRTestClusterClusterTestStructArrayArgumentResponseParams = MTRTestClusterClusterTestStructArrayArgumentResponseParams()
    _MTRTestClusterClusterTestStructArrayArgumentResponseParams.arg1 = [n(1)] as [Any]
    _ = _MTRTestClusterClusterTestStructArrayArgumentResponseParams.arg1
    _MTRTestClusterClusterTestStructArrayArgumentResponseParams.arg2 = [n(1)] as [Any]
    _ = _MTRTestClusterClusterTestStructArrayArgumentResponseParams.arg2
    _MTRTestClusterClusterTestStructArrayArgumentResponseParams.arg3 = [n(1)] as [Any]
    _ = _MTRTestClusterClusterTestStructArrayArgumentResponseParams.arg3
    _MTRTestClusterClusterTestStructArrayArgumentResponseParams.arg4 = [n(1)] as [Any]
    _ = _MTRTestClusterClusterTestStructArrayArgumentResponseParams.arg4
    _MTRTestClusterClusterTestStructArrayArgumentResponseParams.arg5 = n(1)
    _ = _MTRTestClusterClusterTestStructArrayArgumentResponseParams.arg5
    _MTRTestClusterClusterTestStructArrayArgumentResponseParams.arg6 = n(1)
    _ = _MTRTestClusterClusterTestStructArrayArgumentResponseParams.arg6
    _MTRTestClusterClusterTestStructArrayArgumentResponseParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRTestClusterClusterTestStructArrayArgumentResponseParams.timedInvokeTimeoutMs
    mtrRequire(!_MTRTestClusterClusterTestStructArrayArgumentResponseParams.description.isEmpty, "MTRTestClusterClusterTestStructArrayArgumentResponseParams desc")
}

func testMTRTestClusterClusterTestUnknownCommandParamsParamsWave11() {
    let _MTRTestClusterClusterTestUnknownCommandParams = MTRTestClusterClusterTestUnknownCommandParams()
    _MTRTestClusterClusterTestUnknownCommandParams.serverSideProcessingTimeout = n(1)
    _ = _MTRTestClusterClusterTestUnknownCommandParams.serverSideProcessingTimeout
    _MTRTestClusterClusterTestUnknownCommandParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRTestClusterClusterTestUnknownCommandParams.timedInvokeTimeoutMs
    mtrRequire(!_MTRTestClusterClusterTestUnknownCommandParams.description.isEmpty, "MTRTestClusterClusterTestUnknownCommandParams desc")
}

func testMTRTestClusterClusterTimedInvokeRequestParamsParamsWave11() {
    let _MTRTestClusterClusterTimedInvokeRequestParams = MTRTestClusterClusterTimedInvokeRequestParams()
    _MTRTestClusterClusterTimedInvokeRequestParams.serverSideProcessingTimeout = n(1)
    _ = _MTRTestClusterClusterTimedInvokeRequestParams.serverSideProcessingTimeout
    _MTRTestClusterClusterTimedInvokeRequestParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRTestClusterClusterTimedInvokeRequestParams.timedInvokeTimeoutMs
    mtrRequire(!_MTRTestClusterClusterTimedInvokeRequestParams.description.isEmpty, "MTRTestClusterClusterTimedInvokeRequestParams desc")
}

func testMTRThreadBorderRouterManagementClusterDatasetResponseParamsParamsWave11() {
    let _MTRThreadBorderRouterManagementClusterDatasetResponseParams = (try? MTRThreadBorderRouterManagementClusterDatasetResponseParams(responseValue: [MTRDataKey: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1))])) ?? MTRThreadBorderRouterManagementClusterDatasetResponseParams()
    _MTRThreadBorderRouterManagementClusterDatasetResponseParams.dataset = Data([1])
    _ = _MTRThreadBorderRouterManagementClusterDatasetResponseParams.dataset
    mtrRequire(_MTRThreadBorderRouterManagementClusterDatasetResponseParams.description.contains("MTRThreadBorderRouterManagementClusterDatasetResponseParams"), "MTRThreadBorderRouterManagementClusterDatasetResponseParams desc")
}

func testMTRThreadBorderRouterManagementClusterGetActiveDatasetRequestParamsParamsWave11() {
    let _MTRThreadBorderRouterManagementClusterGetActiveDatasetRequestParams = MTRThreadBorderRouterManagementClusterGetActiveDatasetRequestParams()
    _MTRThreadBorderRouterManagementClusterGetActiveDatasetRequestParams.serverSideProcessingTimeout = n(1)
    _ = _MTRThreadBorderRouterManagementClusterGetActiveDatasetRequestParams.serverSideProcessingTimeout
    _MTRThreadBorderRouterManagementClusterGetActiveDatasetRequestParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRThreadBorderRouterManagementClusterGetActiveDatasetRequestParams.timedInvokeTimeoutMs
    mtrRequire(_MTRThreadBorderRouterManagementClusterGetActiveDatasetRequestParams.description.contains("MTRThreadBorderRouterManagementClusterGetActiveDatasetRequestParams"), "MTRThreadBorderRouterManagementClusterGetActiveDatasetRequestParams desc")
}

func testMTRThreadBorderRouterManagementClusterGetPendingDatasetRequestParamsParamsWave11() {
    let _MTRThreadBorderRouterManagementClusterGetPendingDatasetRequestParams = MTRThreadBorderRouterManagementClusterGetPendingDatasetRequestParams()
    _MTRThreadBorderRouterManagementClusterGetPendingDatasetRequestParams.serverSideProcessingTimeout = n(1)
    _ = _MTRThreadBorderRouterManagementClusterGetPendingDatasetRequestParams.serverSideProcessingTimeout
    _MTRThreadBorderRouterManagementClusterGetPendingDatasetRequestParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRThreadBorderRouterManagementClusterGetPendingDatasetRequestParams.timedInvokeTimeoutMs
    mtrRequire(_MTRThreadBorderRouterManagementClusterGetPendingDatasetRequestParams.description.contains("MTRThreadBorderRouterManagementClusterGetPendingDatasetRequestParams"), "MTRThreadBorderRouterManagementClusterGetPendingDatasetRequestParams desc")
}

func testMTRThreadBorderRouterManagementClusterSetActiveDatasetRequestParamsParamsWave11() {
    let _MTRThreadBorderRouterManagementClusterSetActiveDatasetRequestParams = MTRThreadBorderRouterManagementClusterSetActiveDatasetRequestParams()
    _MTRThreadBorderRouterManagementClusterSetActiveDatasetRequestParams.activeDataset = Data([1])
    _ = _MTRThreadBorderRouterManagementClusterSetActiveDatasetRequestParams.activeDataset
    _MTRThreadBorderRouterManagementClusterSetActiveDatasetRequestParams.breadcrumb = n(1)
    _ = _MTRThreadBorderRouterManagementClusterSetActiveDatasetRequestParams.breadcrumb
    _MTRThreadBorderRouterManagementClusterSetActiveDatasetRequestParams.serverSideProcessingTimeout = n(1)
    _ = _MTRThreadBorderRouterManagementClusterSetActiveDatasetRequestParams.serverSideProcessingTimeout
    _MTRThreadBorderRouterManagementClusterSetActiveDatasetRequestParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRThreadBorderRouterManagementClusterSetActiveDatasetRequestParams.timedInvokeTimeoutMs
    mtrRequire(_MTRThreadBorderRouterManagementClusterSetActiveDatasetRequestParams.description.contains("MTRThreadBorderRouterManagementClusterSetActiveDatasetRequestParams"), "MTRThreadBorderRouterManagementClusterSetActiveDatasetRequestParams desc")
}

func testMTRThreadBorderRouterManagementClusterSetPendingDatasetRequestParamsParamsWave11() {
    let _MTRThreadBorderRouterManagementClusterSetPendingDatasetRequestParams = MTRThreadBorderRouterManagementClusterSetPendingDatasetRequestParams()
    _MTRThreadBorderRouterManagementClusterSetPendingDatasetRequestParams.pendingDataset = Data([1])
    _ = _MTRThreadBorderRouterManagementClusterSetPendingDatasetRequestParams.pendingDataset
    _MTRThreadBorderRouterManagementClusterSetPendingDatasetRequestParams.serverSideProcessingTimeout = n(1)
    _ = _MTRThreadBorderRouterManagementClusterSetPendingDatasetRequestParams.serverSideProcessingTimeout
    _MTRThreadBorderRouterManagementClusterSetPendingDatasetRequestParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRThreadBorderRouterManagementClusterSetPendingDatasetRequestParams.timedInvokeTimeoutMs
    mtrRequire(_MTRThreadBorderRouterManagementClusterSetPendingDatasetRequestParams.description.contains("MTRThreadBorderRouterManagementClusterSetPendingDatasetRequestParams"), "MTRThreadBorderRouterManagementClusterSetPendingDatasetRequestParams desc")
}

func testMTRThreadNetworkDirectoryClusterAddNetworkParamsParamsWave11() {
    let _MTRThreadNetworkDirectoryClusterAddNetworkParams = MTRThreadNetworkDirectoryClusterAddNetworkParams()
    _MTRThreadNetworkDirectoryClusterAddNetworkParams.operationalDataset = Data([1])
    _ = _MTRThreadNetworkDirectoryClusterAddNetworkParams.operationalDataset
    _MTRThreadNetworkDirectoryClusterAddNetworkParams.serverSideProcessingTimeout = n(1)
    _ = _MTRThreadNetworkDirectoryClusterAddNetworkParams.serverSideProcessingTimeout
    _MTRThreadNetworkDirectoryClusterAddNetworkParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRThreadNetworkDirectoryClusterAddNetworkParams.timedInvokeTimeoutMs
    mtrRequire(_MTRThreadNetworkDirectoryClusterAddNetworkParams.description.contains("MTRThreadNetworkDirectoryClusterAddNetworkParams"), "MTRThreadNetworkDirectoryClusterAddNetworkParams desc")
}

func testMTRThreadNetworkDirectoryClusterGetOperationalDatasetParamsParamsWave11() {
    let _MTRThreadNetworkDirectoryClusterGetOperationalDatasetParams = MTRThreadNetworkDirectoryClusterGetOperationalDatasetParams()
    _MTRThreadNetworkDirectoryClusterGetOperationalDatasetParams.extendedPanID = Data([1])
    _ = _MTRThreadNetworkDirectoryClusterGetOperationalDatasetParams.extendedPanID
    _MTRThreadNetworkDirectoryClusterGetOperationalDatasetParams.serverSideProcessingTimeout = n(1)
    _ = _MTRThreadNetworkDirectoryClusterGetOperationalDatasetParams.serverSideProcessingTimeout
    _MTRThreadNetworkDirectoryClusterGetOperationalDatasetParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRThreadNetworkDirectoryClusterGetOperationalDatasetParams.timedInvokeTimeoutMs
    mtrRequire(_MTRThreadNetworkDirectoryClusterGetOperationalDatasetParams.description.contains("MTRThreadNetworkDirectoryClusterGetOperationalDatasetParams"), "MTRThreadNetworkDirectoryClusterGetOperationalDatasetParams desc")
}

func testMTRThreadNetworkDirectoryClusterOperationalDatasetResponseParamsParamsWave11() {
    let _MTRThreadNetworkDirectoryClusterOperationalDatasetResponseParams = (try? MTRThreadNetworkDirectoryClusterOperationalDatasetResponseParams(responseValue: [MTRDataKey: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1))])) ?? MTRThreadNetworkDirectoryClusterOperationalDatasetResponseParams()
    _MTRThreadNetworkDirectoryClusterOperationalDatasetResponseParams.operationalDataset = Data([1])
    _ = _MTRThreadNetworkDirectoryClusterOperationalDatasetResponseParams.operationalDataset
    mtrRequire(_MTRThreadNetworkDirectoryClusterOperationalDatasetResponseParams.description.contains("MTRThreadNetworkDirectoryClusterOperationalDatasetResponseParams"), "MTRThreadNetworkDirectoryClusterOperationalDatasetResponseParams desc")
}

func testMTRThreadNetworkDirectoryClusterRemoveNetworkParamsParamsWave11() {
    let _MTRThreadNetworkDirectoryClusterRemoveNetworkParams = MTRThreadNetworkDirectoryClusterRemoveNetworkParams()
    _MTRThreadNetworkDirectoryClusterRemoveNetworkParams.extendedPanID = Data([1])
    _ = _MTRThreadNetworkDirectoryClusterRemoveNetworkParams.extendedPanID
    _MTRThreadNetworkDirectoryClusterRemoveNetworkParams.serverSideProcessingTimeout = n(1)
    _ = _MTRThreadNetworkDirectoryClusterRemoveNetworkParams.serverSideProcessingTimeout
    _MTRThreadNetworkDirectoryClusterRemoveNetworkParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRThreadNetworkDirectoryClusterRemoveNetworkParams.timedInvokeTimeoutMs
    mtrRequire(_MTRThreadNetworkDirectoryClusterRemoveNetworkParams.description.contains("MTRThreadNetworkDirectoryClusterRemoveNetworkParams"), "MTRThreadNetworkDirectoryClusterRemoveNetworkParams desc")
}

func testMTRThreadNetworkDirectoryClusterThreadNetworkStructParamsWave11() {
    let _MTRThreadNetworkDirectoryClusterThreadNetworkStruct = MTRThreadNetworkDirectoryClusterThreadNetworkStruct()
    _MTRThreadNetworkDirectoryClusterThreadNetworkStruct.activeTimestamp = n(1)
    _ = _MTRThreadNetworkDirectoryClusterThreadNetworkStruct.activeTimestamp
    _MTRThreadNetworkDirectoryClusterThreadNetworkStruct.channel = n(1)
    _ = _MTRThreadNetworkDirectoryClusterThreadNetworkStruct.channel
    _MTRThreadNetworkDirectoryClusterThreadNetworkStruct.extendedPanID = Data([1])
    _ = _MTRThreadNetworkDirectoryClusterThreadNetworkStruct.extendedPanID
    _MTRThreadNetworkDirectoryClusterThreadNetworkStruct.networkName = "x"
    _ = _MTRThreadNetworkDirectoryClusterThreadNetworkStruct.networkName
    mtrRequire(_MTRThreadNetworkDirectoryClusterThreadNetworkStruct.description.contains("MTRThreadNetworkDirectoryClusterThreadNetworkStruct"), "MTRThreadNetworkDirectoryClusterThreadNetworkStruct desc")
}

func testMTRTimeSynchronizationClusterDSTOffsetStructParamsWave11() {
    let _MTRTimeSynchronizationClusterDSTOffsetStruct = MTRTimeSynchronizationClusterDSTOffsetStruct()
    _MTRTimeSynchronizationClusterDSTOffsetStruct.offset = n(1)
    _ = _MTRTimeSynchronizationClusterDSTOffsetStruct.offset
    _MTRTimeSynchronizationClusterDSTOffsetStruct.validStarting = n(1)
    _ = _MTRTimeSynchronizationClusterDSTOffsetStruct.validStarting
    _MTRTimeSynchronizationClusterDSTOffsetStruct.validUntil = n(1)
    _ = _MTRTimeSynchronizationClusterDSTOffsetStruct.validUntil
    mtrRequire(_MTRTimeSynchronizationClusterDSTOffsetStruct.description.contains("MTRTimeSynchronizationClusterDSTOffsetStruct"), "MTRTimeSynchronizationClusterDSTOffsetStruct desc")
}

func testMTRTimeSynchronizationClusterDSTStatusEventParamsWave11() {
    let _MTRTimeSynchronizationClusterDSTStatusEvent = MTRTimeSynchronizationClusterDSTStatusEvent()
    _MTRTimeSynchronizationClusterDSTStatusEvent.dstOffsetActive = n(1)
    _ = _MTRTimeSynchronizationClusterDSTStatusEvent.dstOffsetActive
    mtrRequire(_MTRTimeSynchronizationClusterDSTStatusEvent.description.contains("MTRTimeSynchronizationClusterDSTStatusEvent"), "MTRTimeSynchronizationClusterDSTStatusEvent desc")
}

func testMTRTimeSynchronizationClusterDstOffsetTypeParamsWave11() {
    let _MTRTimeSynchronizationClusterDstOffsetType = MTRTimeSynchronizationClusterDstOffsetType()
    _MTRTimeSynchronizationClusterDstOffsetType.offset = n(1)
    _ = _MTRTimeSynchronizationClusterDstOffsetType.offset
    _MTRTimeSynchronizationClusterDstOffsetType.validStarting = n(1)
    _ = _MTRTimeSynchronizationClusterDstOffsetType.validStarting
    _MTRTimeSynchronizationClusterDstOffsetType.validUntil = n(1)
    _ = _MTRTimeSynchronizationClusterDstOffsetType.validUntil
    mtrRequire(!_MTRTimeSynchronizationClusterDstOffsetType.description.isEmpty, "MTRTimeSynchronizationClusterDstOffsetType desc")
}

func testMTRTimeSynchronizationClusterFabricScopedTrustedTimeSourceStructParamsWave11() {
    let _MTRTimeSynchronizationClusterFabricScopedTrustedTimeSourceStruct = MTRTimeSynchronizationClusterFabricScopedTrustedTimeSourceStruct()
    _MTRTimeSynchronizationClusterFabricScopedTrustedTimeSourceStruct.endpoint = n(1)
    _ = _MTRTimeSynchronizationClusterFabricScopedTrustedTimeSourceStruct.endpoint
    _MTRTimeSynchronizationClusterFabricScopedTrustedTimeSourceStruct.nodeID = n(1)
    _ = _MTRTimeSynchronizationClusterFabricScopedTrustedTimeSourceStruct.nodeID
    mtrRequire(_MTRTimeSynchronizationClusterFabricScopedTrustedTimeSourceStruct.description.contains("MTRTimeSynchronizationClusterFabricScopedTrustedTimeSourceStruct"), "MTRTimeSynchronizationClusterFabricScopedTrustedTimeSourceStruct desc")
}

func testMTRTimeSynchronizationClusterSetDSTOffsetParamsParamsWave11() {
    let _MTRTimeSynchronizationClusterSetDSTOffsetParams = MTRTimeSynchronizationClusterSetDSTOffsetParams()
    _MTRTimeSynchronizationClusterSetDSTOffsetParams.dstOffset = [n(1)] as [Any]
    _ = _MTRTimeSynchronizationClusterSetDSTOffsetParams.dstOffset
    _MTRTimeSynchronizationClusterSetDSTOffsetParams.serverSideProcessingTimeout = n(1)
    _ = _MTRTimeSynchronizationClusterSetDSTOffsetParams.serverSideProcessingTimeout
    _MTRTimeSynchronizationClusterSetDSTOffsetParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRTimeSynchronizationClusterSetDSTOffsetParams.timedInvokeTimeoutMs
    mtrRequire(_MTRTimeSynchronizationClusterSetDSTOffsetParams.description.contains("MTRTimeSynchronizationClusterSetDSTOffsetParams"), "MTRTimeSynchronizationClusterSetDSTOffsetParams desc")
}

func testMTRTimeSynchronizationClusterSetDefaultNTPParamsParamsWave11() {
    let _MTRTimeSynchronizationClusterSetDefaultNTPParams = MTRTimeSynchronizationClusterSetDefaultNTPParams()
    _MTRTimeSynchronizationClusterSetDefaultNTPParams.defaultNTP = "x"
    _ = _MTRTimeSynchronizationClusterSetDefaultNTPParams.defaultNTP
    _MTRTimeSynchronizationClusterSetDefaultNTPParams.serverSideProcessingTimeout = n(1)
    _ = _MTRTimeSynchronizationClusterSetDefaultNTPParams.serverSideProcessingTimeout
    _MTRTimeSynchronizationClusterSetDefaultNTPParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRTimeSynchronizationClusterSetDefaultNTPParams.timedInvokeTimeoutMs
    mtrRequire(_MTRTimeSynchronizationClusterSetDefaultNTPParams.description.contains("MTRTimeSynchronizationClusterSetDefaultNTPParams"), "MTRTimeSynchronizationClusterSetDefaultNTPParams desc")
}

func testMTRTimeSynchronizationClusterSetTimeZoneParamsParamsWave11() {
    let _MTRTimeSynchronizationClusterSetTimeZoneParams = MTRTimeSynchronizationClusterSetTimeZoneParams()
    _MTRTimeSynchronizationClusterSetTimeZoneParams.serverSideProcessingTimeout = n(1)
    _ = _MTRTimeSynchronizationClusterSetTimeZoneParams.serverSideProcessingTimeout
    _MTRTimeSynchronizationClusterSetTimeZoneParams.timeZone = [n(1)] as [Any]
    _ = _MTRTimeSynchronizationClusterSetTimeZoneParams.timeZone
    _MTRTimeSynchronizationClusterSetTimeZoneParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRTimeSynchronizationClusterSetTimeZoneParams.timedInvokeTimeoutMs
    mtrRequire(_MTRTimeSynchronizationClusterSetTimeZoneParams.description.contains("MTRTimeSynchronizationClusterSetTimeZoneParams"), "MTRTimeSynchronizationClusterSetTimeZoneParams desc")
}

func testMTRTimeSynchronizationClusterSetTimeZoneResponseParamsParamsWave11() {
    let _MTRTimeSynchronizationClusterSetTimeZoneResponseParams = (try? MTRTimeSynchronizationClusterSetTimeZoneResponseParams(responseValue: [MTRDataKey: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1))])) ?? MTRTimeSynchronizationClusterSetTimeZoneResponseParams()
    _MTRTimeSynchronizationClusterSetTimeZoneResponseParams.dstOffsetRequired = n(1)
    _ = _MTRTimeSynchronizationClusterSetTimeZoneResponseParams.dstOffsetRequired
    mtrRequire(_MTRTimeSynchronizationClusterSetTimeZoneResponseParams.description.contains("MTRTimeSynchronizationClusterSetTimeZoneResponseParams"), "MTRTimeSynchronizationClusterSetTimeZoneResponseParams desc")
}

func testMTRTimeSynchronizationClusterSetTrustedTimeSourceParamsParamsWave11() {
    let _MTRTimeSynchronizationClusterSetTrustedTimeSourceParams = MTRTimeSynchronizationClusterSetTrustedTimeSourceParams()
    _MTRTimeSynchronizationClusterSetTrustedTimeSourceParams.serverSideProcessingTimeout = n(1)
    _ = _MTRTimeSynchronizationClusterSetTrustedTimeSourceParams.serverSideProcessingTimeout
    _MTRTimeSynchronizationClusterSetTrustedTimeSourceParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRTimeSynchronizationClusterSetTrustedTimeSourceParams.timedInvokeTimeoutMs
    _MTRTimeSynchronizationClusterSetTrustedTimeSourceParams.trustedTimeSource = MTRTimeSynchronizationClusterFabricScopedTrustedTimeSourceStruct()
    _ = _MTRTimeSynchronizationClusterSetTrustedTimeSourceParams.trustedTimeSource
    mtrRequire(_MTRTimeSynchronizationClusterSetTrustedTimeSourceParams.description.contains("MTRTimeSynchronizationClusterSetTrustedTimeSourceParams"), "MTRTimeSynchronizationClusterSetTrustedTimeSourceParams desc")
}

func testMTRTimeSynchronizationClusterSetUTCTimeParamsParamsWave11() {
    let _MTRTimeSynchronizationClusterSetUTCTimeParams = MTRTimeSynchronizationClusterSetUTCTimeParams()
    _MTRTimeSynchronizationClusterSetUTCTimeParams.granularity = n(1)
    _ = _MTRTimeSynchronizationClusterSetUTCTimeParams.granularity
    _MTRTimeSynchronizationClusterSetUTCTimeParams.serverSideProcessingTimeout = n(1)
    _ = _MTRTimeSynchronizationClusterSetUTCTimeParams.serverSideProcessingTimeout
    _MTRTimeSynchronizationClusterSetUTCTimeParams.timeSource = n(1)
    _ = _MTRTimeSynchronizationClusterSetUTCTimeParams.timeSource
    _MTRTimeSynchronizationClusterSetUTCTimeParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRTimeSynchronizationClusterSetUTCTimeParams.timedInvokeTimeoutMs
    _MTRTimeSynchronizationClusterSetUTCTimeParams.utcTime = n(1)
    _ = _MTRTimeSynchronizationClusterSetUTCTimeParams.utcTime
    mtrRequire(_MTRTimeSynchronizationClusterSetUTCTimeParams.description.contains("MTRTimeSynchronizationClusterSetUTCTimeParams"), "MTRTimeSynchronizationClusterSetUTCTimeParams desc")
}

func testMTRTimeSynchronizationClusterSetUtcTimeParamsParamsWave11() {
    let _MTRTimeSynchronizationClusterSetUtcTimeParams = MTRTimeSynchronizationClusterSetUtcTimeParams()
    _MTRTimeSynchronizationClusterSetUtcTimeParams.granularity = n(1)
    _ = _MTRTimeSynchronizationClusterSetUtcTimeParams.granularity
    _MTRTimeSynchronizationClusterSetUtcTimeParams.serverSideProcessingTimeout = n(1)
    _ = _MTRTimeSynchronizationClusterSetUtcTimeParams.serverSideProcessingTimeout
    _MTRTimeSynchronizationClusterSetUtcTimeParams.timeSource = n(1)
    _ = _MTRTimeSynchronizationClusterSetUtcTimeParams.timeSource
    _MTRTimeSynchronizationClusterSetUtcTimeParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRTimeSynchronizationClusterSetUtcTimeParams.timedInvokeTimeoutMs
    _MTRTimeSynchronizationClusterSetUtcTimeParams.utcTime = n(1)
    _ = _MTRTimeSynchronizationClusterSetUtcTimeParams.utcTime
    mtrRequire(!_MTRTimeSynchronizationClusterSetUtcTimeParams.description.isEmpty, "MTRTimeSynchronizationClusterSetUtcTimeParams desc")
}

func testMTRTimeSynchronizationClusterTimeZoneStatusEventParamsWave11() {
    let _MTRTimeSynchronizationClusterTimeZoneStatusEvent = MTRTimeSynchronizationClusterTimeZoneStatusEvent()
    _MTRTimeSynchronizationClusterTimeZoneStatusEvent.name = "x"
    _ = _MTRTimeSynchronizationClusterTimeZoneStatusEvent.name
    _MTRTimeSynchronizationClusterTimeZoneStatusEvent.offset = n(1)
    _ = _MTRTimeSynchronizationClusterTimeZoneStatusEvent.offset
    mtrRequire(_MTRTimeSynchronizationClusterTimeZoneStatusEvent.description.contains("MTRTimeSynchronizationClusterTimeZoneStatusEvent"), "MTRTimeSynchronizationClusterTimeZoneStatusEvent desc")
}

func testMTRTimeSynchronizationClusterTimeZoneStructParamsWave11() {
    let _MTRTimeSynchronizationClusterTimeZoneStruct = MTRTimeSynchronizationClusterTimeZoneStruct()
    _MTRTimeSynchronizationClusterTimeZoneStruct.name = "x"
    _ = _MTRTimeSynchronizationClusterTimeZoneStruct.name
    _MTRTimeSynchronizationClusterTimeZoneStruct.offset = n(1)
    _ = _MTRTimeSynchronizationClusterTimeZoneStruct.offset
    _MTRTimeSynchronizationClusterTimeZoneStruct.validAt = n(1)
    _ = _MTRTimeSynchronizationClusterTimeZoneStruct.validAt
    mtrRequire(_MTRTimeSynchronizationClusterTimeZoneStruct.description.contains("MTRTimeSynchronizationClusterTimeZoneStruct"), "MTRTimeSynchronizationClusterTimeZoneStruct desc")
}

func testMTRTimeSynchronizationClusterTimeZoneTypeParamsWave11() {
    let _MTRTimeSynchronizationClusterTimeZoneType = MTRTimeSynchronizationClusterTimeZoneType()
    _MTRTimeSynchronizationClusterTimeZoneType.name = "x"
    _ = _MTRTimeSynchronizationClusterTimeZoneType.name
    _MTRTimeSynchronizationClusterTimeZoneType.offset = n(1)
    _ = _MTRTimeSynchronizationClusterTimeZoneType.offset
    _MTRTimeSynchronizationClusterTimeZoneType.validAt = n(1)
    _ = _MTRTimeSynchronizationClusterTimeZoneType.validAt
    mtrRequire(!_MTRTimeSynchronizationClusterTimeZoneType.description.isEmpty, "MTRTimeSynchronizationClusterTimeZoneType desc")
}

func testMTRTimeSynchronizationClusterTrustedTimeSourceStructParamsWave11() {
    let _MTRTimeSynchronizationClusterTrustedTimeSourceStruct = MTRTimeSynchronizationClusterTrustedTimeSourceStruct()
    _MTRTimeSynchronizationClusterTrustedTimeSourceStruct.endpoint = n(1)
    _ = _MTRTimeSynchronizationClusterTrustedTimeSourceStruct.endpoint
    _MTRTimeSynchronizationClusterTrustedTimeSourceStruct.fabricIndex = n(1)
    _ = _MTRTimeSynchronizationClusterTrustedTimeSourceStruct.fabricIndex
    _MTRTimeSynchronizationClusterTrustedTimeSourceStruct.nodeID = n(1)
    _ = _MTRTimeSynchronizationClusterTrustedTimeSourceStruct.nodeID
    mtrRequire(_MTRTimeSynchronizationClusterTrustedTimeSourceStruct.description.contains("MTRTimeSynchronizationClusterTrustedTimeSourceStruct"), "MTRTimeSynchronizationClusterTrustedTimeSourceStruct desc")
}

func testMTRUserLabelClusterLabelStructParamsWave11() {
    let _MTRUserLabelClusterLabelStruct = MTRUserLabelClusterLabelStruct()
    _MTRUserLabelClusterLabelStruct.label = "x"
    _ = _MTRUserLabelClusterLabelStruct.label
    _MTRUserLabelClusterLabelStruct.value = "x"
    _ = _MTRUserLabelClusterLabelStruct.value
    mtrRequire(_MTRUserLabelClusterLabelStruct.description.contains("MTRUserLabelClusterLabelStruct"), "MTRUserLabelClusterLabelStruct desc")
}

func testMTRValveConfigurationAndControlClusterCloseParamsParamsWave11() {
    let _MTRValveConfigurationAndControlClusterCloseParams = MTRValveConfigurationAndControlClusterCloseParams()
    _MTRValveConfigurationAndControlClusterCloseParams.serverSideProcessingTimeout = n(1)
    _ = _MTRValveConfigurationAndControlClusterCloseParams.serverSideProcessingTimeout
    _MTRValveConfigurationAndControlClusterCloseParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRValveConfigurationAndControlClusterCloseParams.timedInvokeTimeoutMs
    mtrRequire(_MTRValveConfigurationAndControlClusterCloseParams.description.contains("MTRValveConfigurationAndControlClusterCloseParams"), "MTRValveConfigurationAndControlClusterCloseParams desc")
}

func testMTRValveConfigurationAndControlClusterOpenParamsParamsWave11() {
    let _MTRValveConfigurationAndControlClusterOpenParams = MTRValveConfigurationAndControlClusterOpenParams()
    _MTRValveConfigurationAndControlClusterOpenParams.openDuration = n(1)
    _ = _MTRValveConfigurationAndControlClusterOpenParams.openDuration
    _MTRValveConfigurationAndControlClusterOpenParams.serverSideProcessingTimeout = n(1)
    _ = _MTRValveConfigurationAndControlClusterOpenParams.serverSideProcessingTimeout
    _MTRValveConfigurationAndControlClusterOpenParams.targetLevel = n(1)
    _ = _MTRValveConfigurationAndControlClusterOpenParams.targetLevel
    _MTRValveConfigurationAndControlClusterOpenParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRValveConfigurationAndControlClusterOpenParams.timedInvokeTimeoutMs
    mtrRequire(_MTRValveConfigurationAndControlClusterOpenParams.description.contains("MTRValveConfigurationAndControlClusterOpenParams"), "MTRValveConfigurationAndControlClusterOpenParams desc")
}

func testMTRValveConfigurationAndControlClusterValveFaultEventParamsWave11() {
    let _MTRValveConfigurationAndControlClusterValveFaultEvent = MTRValveConfigurationAndControlClusterValveFaultEvent()
    _MTRValveConfigurationAndControlClusterValveFaultEvent.valveFault = n(1)
    _ = _MTRValveConfigurationAndControlClusterValveFaultEvent.valveFault
    mtrRequire(_MTRValveConfigurationAndControlClusterValveFaultEvent.description.contains("MTRValveConfigurationAndControlClusterValveFaultEvent"), "MTRValveConfigurationAndControlClusterValveFaultEvent desc")
}

func testMTRValveConfigurationAndControlClusterValveStateChangedEventParamsWave11() {
    let _MTRValveConfigurationAndControlClusterValveStateChangedEvent = MTRValveConfigurationAndControlClusterValveStateChangedEvent()
    _MTRValveConfigurationAndControlClusterValveStateChangedEvent.valveLevel = n(1)
    _ = _MTRValveConfigurationAndControlClusterValveStateChangedEvent.valveLevel
    _MTRValveConfigurationAndControlClusterValveStateChangedEvent.valveState = n(1)
    _ = _MTRValveConfigurationAndControlClusterValveStateChangedEvent.valveState
    mtrRequire(_MTRValveConfigurationAndControlClusterValveStateChangedEvent.description.contains("MTRValveConfigurationAndControlClusterValveStateChangedEvent"), "MTRValveConfigurationAndControlClusterValveStateChangedEvent desc")
}

func testMTRWaterHeaterManagementClusterBoostParamsParamsWave11() {
    let _MTRWaterHeaterManagementClusterBoostParams = MTRWaterHeaterManagementClusterBoostParams()
    _MTRWaterHeaterManagementClusterBoostParams.boostInfo = MTRWaterHeaterManagementClusterWaterHeaterBoostInfoStruct()
    _ = _MTRWaterHeaterManagementClusterBoostParams.boostInfo
    _MTRWaterHeaterManagementClusterBoostParams.serverSideProcessingTimeout = n(1)
    _ = _MTRWaterHeaterManagementClusterBoostParams.serverSideProcessingTimeout
    _MTRWaterHeaterManagementClusterBoostParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRWaterHeaterManagementClusterBoostParams.timedInvokeTimeoutMs
    mtrRequire(_MTRWaterHeaterManagementClusterBoostParams.description.contains("MTRWaterHeaterManagementClusterBoostParams"), "MTRWaterHeaterManagementClusterBoostParams desc")
}

func testMTRWaterHeaterManagementClusterBoostStartedEventParamsWave11() {
    let _MTRWaterHeaterManagementClusterBoostStartedEvent = MTRWaterHeaterManagementClusterBoostStartedEvent()
    _MTRWaterHeaterManagementClusterBoostStartedEvent.boostInfo = MTRWaterHeaterManagementClusterWaterHeaterBoostInfoStruct()
    _ = _MTRWaterHeaterManagementClusterBoostStartedEvent.boostInfo
    mtrRequire(_MTRWaterHeaterManagementClusterBoostStartedEvent.description.contains("MTRWaterHeaterManagementClusterBoostStartedEvent"), "MTRWaterHeaterManagementClusterBoostStartedEvent desc")
}

func testMTRWaterHeaterManagementClusterCancelBoostParamsParamsWave11() {
    let _MTRWaterHeaterManagementClusterCancelBoostParams = MTRWaterHeaterManagementClusterCancelBoostParams()
    _MTRWaterHeaterManagementClusterCancelBoostParams.serverSideProcessingTimeout = n(1)
    _ = _MTRWaterHeaterManagementClusterCancelBoostParams.serverSideProcessingTimeout
    _MTRWaterHeaterManagementClusterCancelBoostParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRWaterHeaterManagementClusterCancelBoostParams.timedInvokeTimeoutMs
    mtrRequire(_MTRWaterHeaterManagementClusterCancelBoostParams.description.contains("MTRWaterHeaterManagementClusterCancelBoostParams"), "MTRWaterHeaterManagementClusterCancelBoostParams desc")
}

func testMTRWaterHeaterManagementClusterWaterHeaterBoostInfoStructParamsWave11() {
    let _MTRWaterHeaterManagementClusterWaterHeaterBoostInfoStruct = MTRWaterHeaterManagementClusterWaterHeaterBoostInfoStruct()
    _MTRWaterHeaterManagementClusterWaterHeaterBoostInfoStruct.duration = n(1)
    _ = _MTRWaterHeaterManagementClusterWaterHeaterBoostInfoStruct.duration
    _MTRWaterHeaterManagementClusterWaterHeaterBoostInfoStruct.emergencyBoost = n(1)
    _ = _MTRWaterHeaterManagementClusterWaterHeaterBoostInfoStruct.emergencyBoost
    _MTRWaterHeaterManagementClusterWaterHeaterBoostInfoStruct.oneShot = n(1)
    _ = _MTRWaterHeaterManagementClusterWaterHeaterBoostInfoStruct.oneShot
    _MTRWaterHeaterManagementClusterWaterHeaterBoostInfoStruct.targetPercentage = n(1)
    _ = _MTRWaterHeaterManagementClusterWaterHeaterBoostInfoStruct.targetPercentage
    _MTRWaterHeaterManagementClusterWaterHeaterBoostInfoStruct.targetReheat = n(1)
    _ = _MTRWaterHeaterManagementClusterWaterHeaterBoostInfoStruct.targetReheat
    _MTRWaterHeaterManagementClusterWaterHeaterBoostInfoStruct.temporarySetpoint = n(1)
    _ = _MTRWaterHeaterManagementClusterWaterHeaterBoostInfoStruct.temporarySetpoint
    mtrRequire(_MTRWaterHeaterManagementClusterWaterHeaterBoostInfoStruct.description.contains("MTRWaterHeaterManagementClusterWaterHeaterBoostInfoStruct"), "MTRWaterHeaterManagementClusterWaterHeaterBoostInfoStruct desc")
}

func testMTRWaterHeaterModeClusterChangeToModeParamsParamsWave11() {
    let _MTRWaterHeaterModeClusterChangeToModeParams = MTRWaterHeaterModeClusterChangeToModeParams()
    _MTRWaterHeaterModeClusterChangeToModeParams.newMode = n(1)
    _ = _MTRWaterHeaterModeClusterChangeToModeParams.newMode
    _MTRWaterHeaterModeClusterChangeToModeParams.serverSideProcessingTimeout = n(1)
    _ = _MTRWaterHeaterModeClusterChangeToModeParams.serverSideProcessingTimeout
    _MTRWaterHeaterModeClusterChangeToModeParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRWaterHeaterModeClusterChangeToModeParams.timedInvokeTimeoutMs
    mtrRequire(_MTRWaterHeaterModeClusterChangeToModeParams.description.contains("MTRWaterHeaterModeClusterChangeToModeParams"), "MTRWaterHeaterModeClusterChangeToModeParams desc")
}

func testMTRWaterHeaterModeClusterChangeToModeResponseParamsParamsWave11() {
    let _MTRWaterHeaterModeClusterChangeToModeResponseParams = (try? MTRWaterHeaterModeClusterChangeToModeResponseParams(responseValue: [MTRDataKey: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1))])) ?? MTRWaterHeaterModeClusterChangeToModeResponseParams()
    _MTRWaterHeaterModeClusterChangeToModeResponseParams.status = n(1)
    _ = _MTRWaterHeaterModeClusterChangeToModeResponseParams.status
    _MTRWaterHeaterModeClusterChangeToModeResponseParams.statusText = "x"
    _ = _MTRWaterHeaterModeClusterChangeToModeResponseParams.statusText
    mtrRequire(_MTRWaterHeaterModeClusterChangeToModeResponseParams.description.contains("MTRWaterHeaterModeClusterChangeToModeResponseParams"), "MTRWaterHeaterModeClusterChangeToModeResponseParams desc")
}

func testMTRWaterHeaterModeClusterModeOptionStructParamsWave11() {
    let _MTRWaterHeaterModeClusterModeOptionStruct = MTRWaterHeaterModeClusterModeOptionStruct()
    _MTRWaterHeaterModeClusterModeOptionStruct.label = "x"
    _ = _MTRWaterHeaterModeClusterModeOptionStruct.label
    _MTRWaterHeaterModeClusterModeOptionStruct.mode = n(1)
    _ = _MTRWaterHeaterModeClusterModeOptionStruct.mode
    _MTRWaterHeaterModeClusterModeOptionStruct.modeTags = [n(1)] as [Any]
    _ = _MTRWaterHeaterModeClusterModeOptionStruct.modeTags
    mtrRequire(_MTRWaterHeaterModeClusterModeOptionStruct.description.contains("MTRWaterHeaterModeClusterModeOptionStruct"), "MTRWaterHeaterModeClusterModeOptionStruct desc")
}

func testMTRWaterHeaterModeClusterModeTagStructParamsWave11() {
    let _MTRWaterHeaterModeClusterModeTagStruct = MTRWaterHeaterModeClusterModeTagStruct()
    _MTRWaterHeaterModeClusterModeTagStruct.mfgCode = n(1)
    _ = _MTRWaterHeaterModeClusterModeTagStruct.mfgCode
    _MTRWaterHeaterModeClusterModeTagStruct.value = n(1)
    _ = _MTRWaterHeaterModeClusterModeTagStruct.value
    mtrRequire(_MTRWaterHeaterModeClusterModeTagStruct.description.contains("MTRWaterHeaterModeClusterModeTagStruct"), "MTRWaterHeaterModeClusterModeTagStruct desc")
}

func testMTRWiFiNetworkDiagnosticsClusterAssociationFailureEventParamsWave11() {
    let _MTRWiFiNetworkDiagnosticsClusterAssociationFailureEvent = MTRWiFiNetworkDiagnosticsClusterAssociationFailureEvent()
    _MTRWiFiNetworkDiagnosticsClusterAssociationFailureEvent.associationFailure = n(1)
    _ = _MTRWiFiNetworkDiagnosticsClusterAssociationFailureEvent.associationFailure
    _MTRWiFiNetworkDiagnosticsClusterAssociationFailureEvent.associationFailureCause = n(1)
    _ = _MTRWiFiNetworkDiagnosticsClusterAssociationFailureEvent.associationFailureCause
    _MTRWiFiNetworkDiagnosticsClusterAssociationFailureEvent.status = n(1)
    _ = _MTRWiFiNetworkDiagnosticsClusterAssociationFailureEvent.status
    mtrRequire(_MTRWiFiNetworkDiagnosticsClusterAssociationFailureEvent.description.contains("MTRWiFiNetworkDiagnosticsClusterAssociationFailureEvent"), "MTRWiFiNetworkDiagnosticsClusterAssociationFailureEvent desc")
}

func testMTRWiFiNetworkDiagnosticsClusterConnectionStatusEventParamsWave11() {
    let _MTRWiFiNetworkDiagnosticsClusterConnectionStatusEvent = MTRWiFiNetworkDiagnosticsClusterConnectionStatusEvent()
    _MTRWiFiNetworkDiagnosticsClusterConnectionStatusEvent.connectionStatus = n(1)
    _ = _MTRWiFiNetworkDiagnosticsClusterConnectionStatusEvent.connectionStatus
    mtrRequire(_MTRWiFiNetworkDiagnosticsClusterConnectionStatusEvent.description.contains("MTRWiFiNetworkDiagnosticsClusterConnectionStatusEvent"), "MTRWiFiNetworkDiagnosticsClusterConnectionStatusEvent desc")
}

func testMTRWiFiNetworkDiagnosticsClusterDisconnectionEventParamsWave11() {
    let _MTRWiFiNetworkDiagnosticsClusterDisconnectionEvent = MTRWiFiNetworkDiagnosticsClusterDisconnectionEvent()
    _MTRWiFiNetworkDiagnosticsClusterDisconnectionEvent.reasonCode = n(1)
    _ = _MTRWiFiNetworkDiagnosticsClusterDisconnectionEvent.reasonCode
    mtrRequire(_MTRWiFiNetworkDiagnosticsClusterDisconnectionEvent.description.contains("MTRWiFiNetworkDiagnosticsClusterDisconnectionEvent"), "MTRWiFiNetworkDiagnosticsClusterDisconnectionEvent desc")
}

func testMTRWiFiNetworkDiagnosticsClusterResetCountsParamsParamsWave11() {
    let _MTRWiFiNetworkDiagnosticsClusterResetCountsParams = MTRWiFiNetworkDiagnosticsClusterResetCountsParams()
    _MTRWiFiNetworkDiagnosticsClusterResetCountsParams.serverSideProcessingTimeout = n(1)
    _ = _MTRWiFiNetworkDiagnosticsClusterResetCountsParams.serverSideProcessingTimeout
    _MTRWiFiNetworkDiagnosticsClusterResetCountsParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRWiFiNetworkDiagnosticsClusterResetCountsParams.timedInvokeTimeoutMs
    mtrRequire(_MTRWiFiNetworkDiagnosticsClusterResetCountsParams.description.contains("MTRWiFiNetworkDiagnosticsClusterResetCountsParams"), "MTRWiFiNetworkDiagnosticsClusterResetCountsParams desc")
}

func testMTRWiFiNetworkManagementClusterNetworkPassphraseRequestParamsParamsWave11() {
    let _MTRWiFiNetworkManagementClusterNetworkPassphraseRequestParams = MTRWiFiNetworkManagementClusterNetworkPassphraseRequestParams()
    _MTRWiFiNetworkManagementClusterNetworkPassphraseRequestParams.serverSideProcessingTimeout = n(1)
    _ = _MTRWiFiNetworkManagementClusterNetworkPassphraseRequestParams.serverSideProcessingTimeout
    _MTRWiFiNetworkManagementClusterNetworkPassphraseRequestParams.timedInvokeTimeoutMs = n(1)
    _ = _MTRWiFiNetworkManagementClusterNetworkPassphraseRequestParams.timedInvokeTimeoutMs
    mtrRequire(_MTRWiFiNetworkManagementClusterNetworkPassphraseRequestParams.description.contains("MTRWiFiNetworkManagementClusterNetworkPassphraseRequestParams"), "MTRWiFiNetworkManagementClusterNetworkPassphraseRequestParams desc")
}

func testMTRWiFiNetworkManagementClusterNetworkPassphraseResponseParamsParamsWave11() {
    let _MTRWiFiNetworkManagementClusterNetworkPassphraseResponseParams = (try? MTRWiFiNetworkManagementClusterNetworkPassphraseResponseParams(responseValue: [MTRDataKey: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1))])) ?? MTRWiFiNetworkManagementClusterNetworkPassphraseResponseParams()
    _MTRWiFiNetworkManagementClusterNetworkPassphraseResponseParams.passphrase = Data([1])
    _ = _MTRWiFiNetworkManagementClusterNetworkPassphraseResponseParams.passphrase
    mtrRequire(_MTRWiFiNetworkManagementClusterNetworkPassphraseResponseParams.description.contains("MTRWiFiNetworkManagementClusterNetworkPassphraseResponseParams"), "MTRWiFiNetworkManagementClusterNetworkPassphraseResponseParams desc")
}

