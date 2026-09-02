import Accounts
import Foundation

// Future clean EC2 dependency-identity client. Isolated host-gate success
// against toolchain Foundation is not integrated guest-Foundation success.
//
// Expected EC2 steps (no local Docker):
// 1. Build the actual guest Foundation module and `libFoundation.dylib`.
// 2. Build Accounts with that Foundation on `-I` / `-L` (and rpath as needed).
// 3. Link this file as a client that `import`s Accounts and Foundation.
// 4. Run with `LD_LIBRARY_PATH` covering both dylibs.
// 5. Confirm `ACCOUNTS_DEPENDENCY_IDENTITY_OK` and that `libAccounts.dylib`
//    was loaded.

private let eventTimeout = DispatchTimeInterval.seconds(5)

private final class LockedState: @unchecked Sendable {
    private let lock = NSLock()
    private var returned = false
    private var sawReturned = false
    private var count = 0

    func markReturned() {
        lock.lock()
        returned = true
        lock.unlock()
    }

    func noteCallback() {
        lock.lock()
        sawReturned = returned
        count += 1
        lock.unlock()
    }

    func snapshot() -> (sawReturned: Bool, count: Int) {
        lock.lock()
        defer { lock.unlock() }
        return (sawReturned, count)
    }
}

private func identityFailClosed(_ error: (any Error)?) {
    guard let error else {
        fatalError("expected fail-closed Foundation NSError")
    }
    let nsError = error as NSError
    precondition(type(of: nsError) == NSError.self)
    precondition(!String(reflecting: type(of: nsError)).hasPrefix("Accounts."))
    precondition(nsError.domain == "com.apple.accounts")
    precondition(nsError.domain == ACErrorDomain)
    precondition(nsError.code == 7)
    precondition(nsError.code == Int(ACErrorPermissionDenied.rawValue))
}

private func waitEvent(_ semaphore: DispatchSemaphore, _ message: String) {
    precondition(semaphore.wait(timeout: .now() + eventTimeout) == .success, message)
}

private final class CompletionQueueBlocker: @unchecked Sendable {
    private let occupied = DispatchSemaphore(value: 0)
    private let hold = DispatchSemaphore(value: 0)

    func occupy() {
        ACAccountStore.completionQueue.async {
            self.occupied.signal()
            self.hold.wait()
        }
        waitEvent(occupied, "completion queue blocker did not start")
    }

    func release() {
        hold.signal()
    }
}

private func assertNotAccountsType<T>(_ value: T) {
    precondition(!String(reflecting: type(of: value)).hasPrefix("Accounts."))
}

private func assertOracleConstants() {
    precondition(ACAccountTypeIdentifierTwitter == "com.apple.twitter")
    precondition(ACAccountTypeIdentifierFacebook == "com.apple.facebook")
    precondition(ACAccountTypeIdentifierSinaWeibo == "com.apple.sinaweibo")
    precondition(ACAccountTypeIdentifierTencentWeibo == "com.apple.account.tencentweibo")
    precondition(ACErrorDomain == "com.apple.accounts")
    precondition(
        NSNotification.Name.ACAccountStoreDidChange.rawValue
            == "ACAccountStoreDidChangeNotification"
    )
    precondition(ACErrorUnknown.rawValue == 1)
    precondition(ACErrorAccountMissingRequiredProperty.rawValue == 2)
    precondition(ACErrorAccountAuthenticationFailed.rawValue == 3)
    precondition(ACErrorAccountTypeInvalid.rawValue == 4)
    precondition(ACErrorAccountAlreadyExists.rawValue == 5)
    precondition(ACErrorAccountNotFound.rawValue == 6)
    precondition(ACErrorPermissionDenied.rawValue == 7)
    precondition(ACErrorAccessInfoInvalid.rawValue == 8)
    precondition(ACErrorClientPermissionDenied.rawValue == 9)
    precondition(ACErrorAccessDeniedByProtectionPolicy.rawValue == 10)
    precondition(ACErrorCredentialNotFound.rawValue == 11)
    precondition(ACErrorFetchCredentialFailed.rawValue == 12)
    precondition(ACErrorStoreCredentialFailed.rawValue == 13)
    precondition(ACErrorRemoveCredentialFailed.rawValue == 14)
    precondition(ACErrorUpdatingNonexistentAccount.rawValue == 15)
    precondition(ACErrorInvalidClientBundleID.rawValue == 16)
    precondition(ACErrorDeniedByPlugin.rawValue == 17)
    precondition(ACErrorCoreDataSaveFailed.rawValue == 18)
    precondition(ACErrorFailedSerializingAccountInfo.rawValue == 19)
    precondition(ACErrorInvalidCommand.rawValue == 20)
    precondition(ACErrorMissingTransportMessageID.rawValue == 21)
    precondition(ACErrorCredentialItemNotFound.rawValue == 22)
    precondition(ACErrorCredentialItemNotExpired.rawValue == 23)
}

private func assertLookups(store: ACAccountStore) {
    for identifier in [
        ACAccountTypeIdentifierTwitter,
        ACAccountTypeIdentifierFacebook,
        ACAccountTypeIdentifierSinaWeibo,
        ACAccountTypeIdentifierTencentWeibo,
    ] {
        let accountType = store.accountType(withAccountTypeIdentifier: identifier)
        precondition(accountType != nil)
        precondition(accountType!.identifier == identifier)
        precondition(accountType!.accessGranted == false)
    }
    precondition(store.accountType(withAccountTypeIdentifier: "com.example.unknown") == nil)
    precondition(store.accountType(withAccountTypeIdentifier: "com.apple.tencentweibo") == nil)
    precondition(store.accountType(withAccountTypeIdentifier: nil) == nil)
}

private func passFoundationValues(store: ACAccountStore) {
    let asObject: NSObject = store
    precondition(asObject === store)
    precondition(!String(reflecting: NSObject.self).hasPrefix("Accounts."))

    let accounts: NSArray = store.accounts
    precondition(accounts.count == 0)
    assertNotAccountsType(accounts)
    precondition(!String(reflecting: NSArray.self).hasPrefix("Accounts."))

    let accountType = store.accountType(
        withAccountTypeIdentifier: ACAccountTypeIdentifierTwitter
    )!
    let account = ACAccount(accountType: accountType)!
    let identifier: NSString? = account.identifier
    precondition(identifier == nil)
    precondition(!String(reflecting: NSString.self).hasPrefix("Accounts."))

    let expiry = Date(timeIntervalSince1970: 1_700_000_000)
    assertNotAccountsType(expiry)
    precondition(!String(reflecting: Date.self).hasPrefix("Accounts."))
    let credential = ACAccountCredential(
        oAuth2Token: "token",
        refreshToken: "refresh",
        expiryDate: expiry
    )!
    account.credential = credential
    precondition(account.credential === credential)

    let name = NSNotification.Name.ACAccountStoreDidChange
    let notification = Notification(name: name, object: store, userInfo: nil)
    precondition(notification.name.rawValue == "ACAccountStoreDidChangeNotification")
    precondition((notification.object as? ACAccountStore) === store)
    assertNotAccountsType(notification)
    precondition(!String(reflecting: Notification.self).hasPrefix("Accounts."))
    precondition(!String(reflecting: NSError.self).hasPrefix("Accounts."))
}

private func proveBoolCallback(
    _ invoke: (@escaping (Bool, (any Error)?) -> Void) -> Void
) {
    let state = LockedState()
    let blocker = CompletionQueueBlocker()
    blocker.occupy()
    invoke { granted, error in
        state.noteCallback()
        precondition(granted == false)
        identityFailClosed(error)
    }
    state.markReturned()
    let drained = DispatchSemaphore(value: 0)
    ACAccountStore.completionQueue.async {
        drained.signal()
    }
    blocker.release()
    waitEvent(drained, "bool callback did not drain")
    let snapshot = state.snapshot()
    precondition(snapshot.sawReturned)
    precondition(snapshot.count == 1)
}

private func exerciseGatedCallbacks(store: ACAccountStore) {
    let accountType = store.accountType(
        withAccountTypeIdentifier: ACAccountTypeIdentifierFacebook
    )!
    let account = ACAccount(accountType: accountType)!
    proveBoolCallback { handler in
        store.saveAccount(account, withCompletionHandler: handler)
    }
    proveBoolCallback { handler in
        store.removeAccount(account, withCompletionHandler: handler)
    }
    proveBoolCallback { handler in
        store.requestAccessToAccounts(with: accountType, options: [:], completion: handler)
    }

    let state = LockedState()
    let blocker = CompletionQueueBlocker()
    blocker.occupy()
    store.renewCredentials(for: account) { result, error in
        state.noteCallback()
        precondition(result == .failed)
        identityFailClosed(error)
    }
    state.markReturned()
    let drained = DispatchSemaphore(value: 0)
    ACAccountStore.completionQueue.async {
        drained.signal()
    }
    blocker.release()
    waitEvent(drained, "renew callback did not drain")
    let snapshot = state.snapshot()
    precondition(snapshot.sawReturned)
    precondition(snapshot.count == 1)
}

private func exerciseAsyncOverlays(store: ACAccountStore) async {
    let accountType = store.accountType(
        withAccountTypeIdentifier: ACAccountTypeIdentifierSinaWeibo
    )!
    let account = ACAccount(accountType: accountType)!
    do {
        _ = try await store.saveAccount(account)
        fatalError("saveAccount async overlay must fail closed")
    } catch {
        identityFailClosed(error)
    }
    do {
        _ = try await store.removeAccount(account)
        fatalError("removeAccount async overlay must fail closed")
    } catch {
        identityFailClosed(error)
    }
    do {
        _ = try await store.requestAccessToAccounts(with: accountType)
        fatalError("requestAccess async overlay must fail closed")
    } catch {
        identityFailClosed(error)
    }
    do {
        _ = try await store.renewCredentials(for: account)
        fatalError("renewCredentials async overlay must fail closed")
    } catch {
        identityFailClosed(error)
    }
}

func accountsDependencyIdentityMain() async {
    assertOracleConstants()
    let store = ACAccountStore()
    assertLookups(store: store)
    passFoundationValues(store: store)
    exerciseGatedCallbacks(store: store)
    await exerciseAsyncOverlays(store: store)
    print("ACCOUNTS_DEPENDENCY_IDENTITY_OK")
}

let identitySemaphore = DispatchSemaphore(value: 0)
Task {
    await accountsDependencyIdentityMain()
    identitySemaphore.signal()
}
identitySemaphore.wait()
