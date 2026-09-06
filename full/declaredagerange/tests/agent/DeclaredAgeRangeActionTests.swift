import Foundation
@_spi(OpenUIKitHost) import DeclaredAgeRange

func testDeclaredAgeRangeActionType() {
    let action = DeclaredAgeRangeAction()
    precondition(type(of: action) == DeclaredAgeRangeAction.self)
}

func testDeclaredAgeRangeActionCallAsFunctionFailClosed() {
    let action = DeclaredAgeRangeAction()
    let method = action.callAsFunction
    _ = method
    do {
        _ = try DeclaredAgeRangeHostControl.callAsFunctionSync(action, ageGates: 13, 16, 18)
        preconditionFailure("Linux must not share an age range")
    } catch let error as AgeRangeService.Error {
        precondition(error == .notAvailable)
    } catch {
        preconditionFailure("unexpected error \(error)")
    }
}

func testDeclaredAgeRangeActionCallAsFunctionInvalidRequest() {
    let action = DeclaredAgeRangeAction()
    do {
        _ = try DeclaredAgeRangeHostControl.callAsFunctionSync(action, ageGates: -1)
        preconditionFailure("negative gate must be invalid")
    } catch AgeRangeService.Error.invalidRequest {
        ()
    } catch {
        preconditionFailure("unexpected error \(error)")
    }
}

func testEnvironmentValuesRequestAgeRange() {
    let values = EnvironmentValues()
    let action = values.requestAgeRange
    precondition(type(of: action) == DeclaredAgeRangeAction.self)
    do {
        _ = try DeclaredAgeRangeHostControl.callAsFunctionSync(action, ageGates: 18)
        preconditionFailure("Linux must not share an age range")
    } catch AgeRangeService.Error.notAvailable {
        ()
    } catch {
        preconditionFailure("unexpected error \(error)")
    }
}
