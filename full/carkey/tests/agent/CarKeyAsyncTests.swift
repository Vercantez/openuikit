import CarKey
import Foundation

private struct AsyncProbeDelegate: CarKeyRemoteControlSessionDelegate {
    func remoteControlSession(
        _ session: CarKeyRemoteControlSession,
        didInvalidateWithError error: CarKeyErrorCode
    ) {
        _ = session
        _ = error
    }

    func remoteControlSession(
        _ session: CarKeyRemoteControlSession,
        vehicleDidUpdateReport report: VehicleReport
    ) {
        _ = session
        _ = report
    }

    func remoteControlSession(
        _ session: CarKeyRemoteControlSession,
        didReceivePassthroughData data: Data,
        fromVehicle vehicleID: String
    ) {
        _ = session
        _ = data
        _ = vehicleID
    }
}

func testAsyncStartFailsClosed() async {
    let delegate = AsyncProbeDelegate()
    do {
        _ = try await CarKeyRemoteControl.start(delegate: delegate)
        preconditionFailure("expected FeatureNotSupported but start succeeded")
    } catch let code as CarKeyErrorCode {
        precondition(code == CarKeyErrorCode.FeatureNotSupported)
    } catch {
        preconditionFailure("expected CarKeyErrorCode got \(error)")
    }
}

func testAsyncOneShotResultsFailsClosed() async {
    let request = RemoteKeylessEntryAction.ExecutionRequest()
    do {
        _ = try await request.results()
        preconditionFailure("expected RequestNotInProgress but results succeeded")
    } catch let code as CarKeyErrorCode {
        precondition(code == CarKeyErrorCode.RequestNotInProgress)
    } catch {
        preconditionFailure("expected CarKeyErrorCode got \(error)")
    }
}

func testAsyncEnduringResultsFailsClosed() async {
    let request = RemoteKeylessEntryEnduringAction.EnduringExecutionRequest()
    do {
        _ = try await request.results()
        preconditionFailure("expected RequestNotInProgress but results succeeded")
    } catch let code as CarKeyErrorCode {
        precondition(code == CarKeyErrorCode.RequestNotInProgress)
    } catch {
        preconditionFailure("expected CarKeyErrorCode got \(error)")
    }
}

func testAsyncConfigurableResultsFailsClosed() async {
    let request = RemoteKeylessEntryConfigurableEnduringAction.EnduringExecutionRequest()
    do {
        _ = try await request.results()
        preconditionFailure("expected RequestNotInProgress but results succeeded")
    } catch let code as CarKeyErrorCode {
        precondition(code == CarKeyErrorCode.RequestNotInProgress)
    } catch {
        preconditionFailure("expected CarKeyErrorCode got \(error)")
    }
}
