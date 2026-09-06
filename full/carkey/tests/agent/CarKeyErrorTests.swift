import CarKey
import Foundation

func expectCarKeyError(_ expected: CarKeyErrorCode, _ body: () throws -> Void) {
    do {
        try body()
        preconditionFailure("expected \(expected) but the call succeeded")
    } catch let code as CarKeyErrorCode {
        precondition(code == expected, "expected \(expected) got \(code)")
    } catch {
        preconditionFailure("expected CarKeyErrorCode got \(error)")
    }
}

func testCarKeyErrorCodeCases() {
    let cases: [CarKeyErrorCode] = [
        .Internal,
        .VehicleNotConnected,
        .AnotherRequestInProgress,
        .SessionNotActive,
        .FunctionUnknown,
        .SecurityViolation,
        .VehicleNotFound,
        .MessageTooLong,
        .RequestTimedOut,
        .EnduringRequestUsingEventMethod,
        .RequestNotInProgress,
        .ClientInBackground,
        .FeatureNotSupported,
    ]
    precondition(cases.count == 13)
    precondition(Set(cases).count == 13)
    precondition(CarKeyErrorCode.Internal != CarKeyErrorCode.FeatureNotSupported)
    precondition(CarKeyErrorCode.VehicleNotConnected != CarKeyErrorCode.VehicleNotFound)
    precondition(CarKeyErrorCode.AnotherRequestInProgress != CarKeyErrorCode.RequestNotInProgress)
    precondition(CarKeyErrorCode.SessionNotActive != CarKeyErrorCode.RequestTimedOut)
    precondition(CarKeyErrorCode.FunctionUnknown != CarKeyErrorCode.SecurityViolation)
    precondition(CarKeyErrorCode.MessageTooLong != CarKeyErrorCode.ClientInBackground)
    precondition(
        CarKeyErrorCode.EnduringRequestUsingEventMethod != CarKeyErrorCode.FeatureNotSupported
    )
}

func testCarKeyErrorCodeEquality() {
    let a = CarKeyErrorCode.SessionNotActive
    let b = CarKeyErrorCode.SessionNotActive
    let c = CarKeyErrorCode.FeatureNotSupported
    precondition(a == b)
    precondition(a != c)
    precondition(!(a != b))

    var h1 = Hasher()
    var h2 = Hasher()
    a.hash(into: &h1)
    b.hash(into: &h2)
    precondition(h1.finalize() == h2.finalize())
    precondition(a.hashValue == b.hashValue)
    precondition(a.hashValue != c.hashValue)

    let error: any Error = CarKeyErrorCode.SecurityViolation
    precondition(!error.localizedDescription.isEmpty)
    precondition(!CarKeyErrorCode.Internal.localizedDescription.isEmpty)
}

func testCarKeyErrorCodeThrownType() {
    expectCarKeyError(.FeatureNotSupported) {
        try CarKeyRemoteControl.registerForLaunchOnCarKeyEvent()
    }
}
