import Accounts
import Foundation

// Future clean EC2 dependency-identity client. Do not treat the isolated
// `tests/acceptance/test_host.sh` gate as integrated Linux success.
//
// Expected EC2 steps (no local Docker):
// 1. Build the actual guest Foundation module and `libFoundation.dylib`.
// 2. Build Accounts with that Foundation on `-I` / `-L` (and rpath as needed).
// 3. Link this file as a client that `import`s Accounts and Foundation.
// 4. Run with `LD_LIBRARY_PATH` covering both dylibs.
// 5. Confirm the marker below and that `libAccounts.dylib` was loaded.
//
//     swiftc -warnings-as-errors \
//       -I "$FOUNDATION_MODULE" -I "$ACCOUNTS_MODULE" \
//       -L "$FOUNDATION_LIB" -L "$ACCOUNTS_LIB" \
//       -lFoundation -lAccounts \
//       full/accounts/tests/agent/AccountsDependencyIdentity.swift \
//       -o accounts-dependency-identity
//     LD_LIBRARY_PATH="$FOUNDATION_LIB:$ACCOUNTS_LIB" ./accounts-dependency-identity

private let identityTimeout = DispatchTimeInterval.seconds(2)

private final class IdentityCounter: @unchecked Sendable {
    private let lock = NSLock()
    private var value = 0

    func increment() {
        lock.lock()
        value += 1
        lock.unlock()
    }

    func current() -> Int {
        lock.lock()
        defer { lock.unlock() }
        return value
    }
}

private func identityFailClosed(_ error: (any Error)?) {
    guard let error else {
        fatalError("expected fail-closed NSError from Foundation")
    }
    let nsError = error as NSError
    precondition(nsError.domain == ACErrorDomain)
    precondition(nsError.code == Int(ACErrorPermissionDenied.rawValue))
}

private func identityWait(_ semaphore: DispatchSemaphore) {
    precondition(semaphore.wait(timeout: .now() + identityTimeout) == .success)
}

private func passFoundationValues(store: ACAccountStore) {
    let asObject: NSObject = store
    precondition(asObject === store)

    let accounts: NSArray = store.accounts
    precondition(accounts.count == 0)

    let accountType = store.accountType(
        withAccountTypeIdentifier: ACAccountTypeIdentifierTwitter
    )!
    let account = ACAccount(accountType: accountType)!
    let identifier: NSString? = account.identifier
    precondition(identifier == nil)

    let expiry = Date(timeIntervalSince1970: 1_700_000_000)
    let credential = ACAccountCredential(
        oAuth2Token: "token",
        refreshToken: "refresh",
        expiryDate: expiry
    )!
    account.credential = credential
    precondition(account.credential === credential)

    let name = NSNotification.Name.ACAccountStoreDidChange
    let notification = Notification(name: name, object: store, userInfo: nil)
    precondition(notification.name == name)
    precondition((notification.object as? ACAccountStore) === store)
}

private func proveNonInlineOnce(
    _ start: (@escaping (Bool, (any Error)?) -> Void) -> Void
) {
    let methodReturned = DispatchSemaphore(value: 0)
    let count = IdentityCounter()
    let once = DispatchSemaphore(value: 0)
    start { granted, error in
        precondition(
            methodReturned.wait(timeout: .now() + identityTimeout) == .success,
            "handler ran before the method returned"
        )
        count.increment()
        precondition(granted == false)
        identityFailClosed(error)
        once.signal()
    }
    methodReturned.signal()
    identityWait(once)
    precondition(count.current() == 1)
    precondition(once.wait(timeout: .now() + .milliseconds(40)) == .timedOut)
}

private func exerciseCallbacks(store: ACAccountStore) {
    let accountType = store.accountType(
        withAccountTypeIdentifier: ACAccountTypeIdentifierFacebook
    )!
    let account = ACAccount(accountType: accountType)!
    proveNonInlineOnce { handler in
        store.saveAccount(account, withCompletionHandler: handler)
    }
    proveNonInlineOnce { handler in
        store.removeAccount(account, withCompletionHandler: handler)
    }
    proveNonInlineOnce { handler in
        store.requestAccessToAccounts(with: accountType, options: [:], completion: handler)
    }

    let returned = DispatchSemaphore(value: 0)
    let count = IdentityCounter()
    let once = DispatchSemaphore(value: 0)
    store.renewCredentials(for: account) { result, error in
        precondition(
            returned.wait(timeout: .now() + identityTimeout) == .success,
            "renew handler ran before the method returned"
        )
        count.increment()
        precondition(result == .failed)
        identityFailClosed(error)
        once.signal()
    }
    returned.signal()
    identityWait(once)
    precondition(count.current() == 1)
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
    let store = ACAccountStore()
    passFoundationValues(store: store)
    exerciseCallbacks(store: store)
    await exerciseAsyncOverlays(store: store)
    print("ACCOUNTS_DEPENDENCY_IDENTITY_OK")
}

let identitySemaphore = DispatchSemaphore(value: 0)
Task {
    await accountsDependencyIdentityMain()
    identitySemaphore.signal()
}
identitySemaphore.wait()
