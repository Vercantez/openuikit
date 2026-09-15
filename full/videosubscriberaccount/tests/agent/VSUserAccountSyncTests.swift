import Foundation
@_spi(OpenUIKitHost) import VideoSubscriberAccount

func testUserAccountsFailClosed() {
    let manager = VSUserAccountManager.shared
    let method: (VSUserAccountManager.QueryOptions) async throws -> [VSUserAccount] =
        manager.userAccounts(options:)
    _ = method
    do {
        _ = try VideoSubscriberAccountHostControl.userAccountsSync(manager, options: .allDevices)
        preconditionFailure("Linux must not invent user accounts")
    } catch let error as VSError {
        precondition(error.code == .unsupported)
        precondition(VSError.Code.unsupported ~= error)
    } catch {
        preconditionFailure("expected VSError.unsupported")
    }
}

func testAutoSignInTokenFailClosed() {
    let manager = VSUserAccountManager.shared
    do {
        _ = try VideoSubscriberAccountHostControl.autoSignInTokenSync(manager)
        preconditionFailure("Linux must not invent an auto sign-in token")
    } catch let error as VSError {
        precondition(error.code == .unsupported)
    } catch {
        preconditionFailure("expected VSError.unsupported")
    }
    precondition(
        VideoSubscriberAccountHostControl.linuxUnsupportedError.code == .unsupported
    )
}

func testDeleteAutoSignInTokenFailClosed() {
    let manager = VSUserAccountManager.shared
    let method: () async throws -> Void = manager.deleteAutoSignInToken
    _ = method
    do {
        try VideoSubscriberAccountHostControl.deleteAutoSignInTokenSync(manager)
        preconditionFailure("Linux must not report auto sign-in deletion success")
    } catch let error as VSError {
        precondition(error.code == .unsupported)
    } catch {
        preconditionFailure("expected VSError.unsupported")
    }
}

func testUpdateAutoSignInTokenFailClosed() {
    let manager = VSUserAccountManager.shared
    let method: (String, VSUserAccountManager.AutoSignInTokenUpdateContext) async throws -> Void =
        manager.updateAutoSignInToken(_:updateContext:)
    _ = method
    let context = VSUserAccountManager.AutoSignInTokenUpdateContext(authorization: .granted)
    do {
        try VideoSubscriberAccountHostControl.updateAutoSignInTokenSync(
            manager,
            "token",
            updateContext: context
        )
        preconditionFailure("Linux must not report auto sign-in update success")
    } catch let error as VSError {
        precondition(error.code == .unsupported)
    } catch {
        preconditionFailure("expected VSError.unsupported")
    }
}

func testRequestAutoSignInAuthorizationFailClosed() {
    let manager = VSUserAccountManager.shared
    let method: () async throws -> VSUserAccountManager.AutoSignInTokenUpdateContext =
        manager.requestAutoSignInAuthorization
    _ = method
    do {
        _ = try VideoSubscriberAccountHostControl.requestAutoSignInAuthorizationSync(manager)
        preconditionFailure("Linux must not invent auto sign-in authorization")
    } catch let error as VSError {
        precondition(error.code == .unsupported)
    } catch {
        preconditionFailure("expected VSError.unsupported")
    }
}

func testUpdateUserAccountFailClosed() {
    let manager = VSUserAccountManager.shared
    let method: (VSUserAccount) async throws -> Void = manager.update(_:)
    _ = method
    let account = VSUserAccount(accountType: .paid, updateURL: nil)
    do {
        try VideoSubscriberAccountHostControl.updateSync(manager, account)
        preconditionFailure("Linux must not report account update success")
    } catch let error as VSError {
        precondition(error.code == .unsupported)
    } catch {
        preconditionFailure("expected VSError.unsupported")
    }
}
