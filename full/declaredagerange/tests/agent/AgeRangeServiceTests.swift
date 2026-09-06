import Foundation
@_spi(OpenUIKitHost) import DeclaredAgeRange

func testAgeRangeServiceType() {
    let service: AgeRangeService = AgeRangeService.shared
    precondition(type(of: service) == AgeRangeService.self)
    _ = AgeRangeService()
}

func testAgeRangeServiceShared() {
    let first = AgeRangeService.shared
    let second = AgeRangeService.shared
    precondition(type(of: first) == AgeRangeService.self)
    precondition(type(of: second) == AgeRangeService.self)
    let method = AgeRangeService.shared
    _ = method
}

func testRequestAgeRangeFailClosed() {
    let presenter = UIViewController()
    let service = AgeRangeService.shared
    let method = service.requestAgeRange
    _ = method
    do {
        _ = try DeclaredAgeRangeHostControl.requestAgeRangeSync(
            ageGates: 13,
            15,
            18,
            in: presenter
        )
        preconditionFailure("Linux must not share an age range")
    } catch let error as AgeRangeService.Error {
        precondition(error == .notAvailable)
        precondition(error == DeclaredAgeRangeHostControl.linuxUnavailableError)
    } catch {
        preconditionFailure("unexpected error \(error)")
    }
}

func testRequestAgeRangeInvalidRequest() {
    let presenter = UIViewController()
    do {
        _ = try DeclaredAgeRangeHostControl.requestAgeRangeSync(
            ageGates: 0,
            in: presenter
        )
        preconditionFailure("zero gate must be invalid")
    } catch AgeRangeService.Error.invalidRequest {
        ()
    } catch {
        preconditionFailure("unexpected error \(error)")
    }
    do {
        _ = try DeclaredAgeRangeHostControl.requestAgeRangeSync(
            ageGates: 18,
            13,
            in: presenter
        )
        preconditionFailure("decreasing gates must be invalid")
    } catch AgeRangeService.Error.invalidRequest {
        ()
    } catch {
        preconditionFailure("unexpected error \(error)")
    }
    do {
        _ = try DeclaredAgeRangeHostControl.requestAgeRangeSync(
            ageGates: 13,
            nil,
            18,
            in: presenter
        )
        preconditionFailure("gap before threshold3 must be invalid")
    } catch AgeRangeService.Error.invalidRequest {
        ()
    } catch {
        preconditionFailure("unexpected error \(error)")
    }
}
