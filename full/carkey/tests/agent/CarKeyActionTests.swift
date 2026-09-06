import CarKey
import Foundation

func testRemoteKeylessEntryAction() {
    let function = FunctionIdentifier(3)
    let actionID = ActionIdentifier(8)
    let action = RemoteKeylessEntryAction(
        functionID: function,
        actionID: actionID,
        vehicleID: "VIN-TEST-1"
    )
    precondition(action.functionID == function)
    precondition(action.actionID == actionID)
    precondition(action.recipientVehicleID == "VIN-TEST-1")
}

func testRemoteKeylessEntryEnduringAction() {
    let function = FunctionIdentifier(4)
    let actionID = ActionIdentifier(1)
    let action = RemoteKeylessEntryEnduringAction(
        functionID: function,
        actionID: actionID,
        vehicleID: "VIN-TEST-2"
    )
    precondition(action.functionID == function)
    precondition(action.actionID == actionID)
    precondition(action.recipientVehicleID == "VIN-TEST-2")
}

func testRemoteKeylessEntryConfigurableEnduringAction() {
    let function = FunctionIdentifier(5)
    let actionID = ActionIdentifier(2)
    let action = RemoteKeylessEntryConfigurableEnduringAction(
        functionID: function,
        actionID: actionID,
        vehicleID: "VIN-TEST-3"
    )
    precondition(action.functionID == function)
    precondition(action.actionID == actionID)
    precondition(action.recipientVehicleID == "VIN-TEST-3")
}

func testActionExecutionRequestType() {
    let request = RemoteKeylessEntryAction.ExecutionRequest()
    _ = request
}

func testEnduringExecutionRequestStop() {
    let request = RemoteKeylessEntryEnduringAction.EnduringExecutionRequest()
    expectCarKeyError(.RequestNotInProgress) {
        try request.stop()
    }
}

func testConfigurableExecutionRequestStop() {
    let request = RemoteKeylessEntryConfigurableEnduringAction.EnduringExecutionRequest()
    expectCarKeyError(.RequestNotInProgress) {
        try request.stop()
    }
}

func testContinuationRequestDataAndConfirm() {
    let empty = RemoteKeylessEntryConfigurableEnduringAction.EnduringExecutionRequest
        .ContinuationRequest()
    precondition(empty.data == nil)
    let payload = Data([0x01, 0x02])
    let filled = RemoteKeylessEntryConfigurableEnduringAction.EnduringExecutionRequest
        .ContinuationRequest(data: payload)
    precondition(filled.data == payload)
    expectCarKeyError(.RequestNotInProgress) {
        try filled.confirm()
    }
    expectCarKeyError(.RequestNotInProgress) {
        try filled.confirm(Data([0xFF]))
    }
}

func testConfigurableEventStream() {
    let request = RemoteKeylessEntryConfigurableEnduringAction.EnduringExecutionRequest()
    let stream = request.eventStream
    _ = stream
}

func testConfigurableContinuationEvent() {
    let continuation = RemoteKeylessEntryConfigurableEnduringAction.EnduringExecutionRequest
        .ContinuationRequest(data: Data([0xAA]))
    let event = RemoteKeylessEntryConfigurableEnduringAction.EnduringExecutionRequest.Event
        .receivedContinuationRequest(continuation)
    switch event {
    case .receivedContinuationRequest(let request):
        precondition(request.data == Data([0xAA]))
    }
}
