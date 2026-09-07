import Foundation
@_spi(OpenUIKitHost) import FamilyControls

func testAuthorizationBoundaryConsistency() {
    let center = AuthorizationCenter.shared
    precondition(center.authorizationStatus == .denied)

    for member in [FamilyControlsMember.child, .individual] {
        do {
            try FamilyControlsHostControl.requestAuthorizationSync(center, for: member)
            preconditionFailure("Linux authorization must fail closed")
        } catch let error as FamilyControlsError {
            precondition(error == .unavailable)
        } catch {
            preconditionFailure("Unexpected authorization error: \(error)")
        }
        precondition(center.authorizationStatus == .denied)
    }

    do {
        try FamilyControlsHostControl.revokeAuthorizationSync(center)
        preconditionFailure("Linux revocation must report the unavailable service")
    } catch let error as FamilyControlsError {
        precondition(error == .unavailable)
    } catch {
        preconditionFailure("Unexpected revocation error: \(error)")
    }
    precondition(center.authorizationStatus == .denied)
}

func testSharedSingleton() {
    let a = AuthorizationCenter.shared
    let b = AuthorizationCenter.shared
    precondition(a === b)
    precondition(type(of: a) == AuthorizationCenter.self)
}

func testAuthorizationStatusDenied() {
    precondition(AuthorizationCenter.shared.authorizationStatus == .denied)
    precondition(AuthorizationCenter.shared.authorizationStatus != .approved)
    precondition(AuthorizationCenter.shared.authorizationStatus != .notDetermined)
}

func testAuthorizationStatusPublisher() {
    let publisher = AuthorizationCenter.shared.$authorizationStatus
    _ = publisher
    precondition(AuthorizationCenter.shared.authorizationStatus == .denied)
}

func testObjectWillChange() {
    typealias Publisher = AuthorizationCenter.ObjectWillChangePublisher
    let publisher: Publisher = AuthorizationCenter.shared.objectWillChange
    publisher.send()
    precondition(AuthorizationCenter.shared.authorizationStatus == .denied)
}

func testRequestAuthorizationCompletion() {
    var results: [Result<Void, any Error>] = []
    AuthorizationCenter.shared.requestAuthorization { result in
        results.append(result)
    }
    precondition(results.count == 1)
    switch results[0] {
    case .success:
        preconditionFailure("Linux must not invent FamilyControls authorization")
    case .failure(let error):
        let typed = error as? FamilyControlsError
        precondition(typed == .unavailable)
        precondition(typed?.rawValue == 1)
    }
    precondition(AuthorizationCenter.shared.authorizationStatus == .denied)
}

func testRequestAuthorizationFor() {
    let center = AuthorizationCenter.shared
    let method: (FamilyControlsMember) async throws -> Void = center.requestAuthorization(for:)
    _ = method
    do {
        try FamilyControlsHostControl.requestAuthorizationSync(center, for: .child)
        preconditionFailure("Linux must not invent FamilyControls authorization")
    } catch let error as FamilyControlsError {
        precondition(error == .unavailable)
    } catch {
        preconditionFailure("expected FamilyControlsError.unavailable")
    }
    do {
        try FamilyControlsHostControl.requestAuthorizationSync(center, for: .individual)
        preconditionFailure("Linux must not invent FamilyControls authorization")
    } catch let error as FamilyControlsError {
        precondition(error == FamilyControlsHostControl.linuxAuthorizationError)
    } catch {
        preconditionFailure("expected FamilyControlsError.unavailable")
    }
    precondition(center.authorizationStatus == .denied)
}

func testRevokeAuthorization() {
    var results: [Result<Void, any Error>] = []
    AuthorizationCenter.shared.revokeAuthorization { result in
        results.append(result)
    }
    precondition(results.count == 1)
    switch results[0] {
    case .success:
        preconditionFailure("Linux must not invent a FamilyControls revoke")
    case .failure(let error):
        precondition((error as? FamilyControlsError) == .unavailable)
    }
    precondition(AuthorizationCenter.shared.authorizationStatus == .denied)
}
