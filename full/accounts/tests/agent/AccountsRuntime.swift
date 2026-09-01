import Accounts
import Foundation

private let callbackTimeout = DispatchTimeInterval.seconds(2)

private final class AccountsFlag: @unchecked Sendable {
    private let lock = NSLock()
    private var value = false

    func set() {
        lock.lock()
        value = true
        lock.unlock()
    }

    func get() -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return value
    }
}

private final class AccountsCounter: @unchecked Sendable {
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

private func requireFailClosedError(_ error: (any Error)?) {
    guard let error else {
        fatalError("expected fail-closed NSError")
    }
    let nsError = error as NSError
    precondition(nsError.domain == ACErrorDomain)
    precondition(nsError.code == Int(ACErrorPermissionDenied.rawValue))
}

private func requireFailClosedThrow(_ body: () async throws -> Void) async {
    do {
        try await body()
        fatalError("expected fail-closed throw")
    } catch {
        requireFailClosedError(error)
    }
}

private func waitOnce(_ semaphore: DispatchSemaphore) {
    precondition(
        semaphore.wait(timeout: .now() + callbackTimeout) == .success,
        "callback did not run"
    )
}

private func assertNoExtraSignal(_ semaphore: DispatchSemaphore) {
    precondition(
        semaphore.wait(timeout: .now() + .milliseconds(40)) == .timedOut,
        "callback ran more than once"
    )
}

private func exerciseLocalObjects(store: ACAccountStore) {
    let accounts: NSArray = store.accounts
    precondition(accounts.count == 0)

    let twitterType = store.accountType(
        withAccountTypeIdentifier: ACAccountTypeIdentifierTwitter
    )!
    precondition(twitterType.identifier == ACAccountTypeIdentifierTwitter)
    precondition(twitterType.accessGranted == false)
    _ = twitterType.accountTypeDescription

    let unknownType = store.accountType(
        withAccountTypeIdentifier: "com.example.unknown"
    )!
    precondition(unknownType.identifier == "com.example.unknown")
    precondition(unknownType.accessGranted == false)
    precondition(store.accountType(withAccountTypeIdentifier: nil) == nil)

    precondition(store.account(withIdentifier: "any-id") == nil)
    let listed = store.accounts(with: twitterType)!
    precondition(listed.isEmpty)

    let account = ACAccount(accountType: twitterType)!
    account.username = "linux-user"
    account.accountDescription = "local only"
    precondition(account.username == "linux-user")
    precondition(account.accountDescription == "local only")
    precondition(account.accountType === twitterType)
    let accountIdentifier: NSString? = account.identifier
    precondition(accountIdentifier == nil)
    precondition(account.userFullName == nil)
    precondition(account.credential == nil)

    let oauth = ACAccountCredential(oAuthToken: "token", tokenSecret: "secret")!
    precondition(oauth.oauthToken == "token")
    oauth.oauthToken = "rotated"
    precondition(oauth.oauthToken == "rotated")

    let oauthAlias = ACAccountCredential(OAuthToken: "alias", tokenSecret: "secret")!
    precondition(oauthAlias.oauthToken == "alias")

    let expiry = Date(timeIntervalSince1970: 0)
    let oauth2 = ACAccountCredential(
        oAuth2Token: "access",
        refreshToken: "refresh",
        expiryDate: expiry
    )!
    precondition(oauth2.oauthToken == "access")
    let oauth2Alias = ACAccountCredential(
        OAuth2Token: "access2",
        refreshToken: "refresh2",
        expiryDate: expiry
    )!
    precondition(oauth2Alias.oauthToken == "access2")
    account.credential = oauth2
    precondition(account.credential === oauth2)

    let saveHandler: ACAccountStoreSaveCompletionHandler = { _, _ in }
    let accessHandler: ACAccountStoreRequestAccessCompletionHandler = { _, _ in }
    let removeHandler: ACAccountStoreRemoveCompletionHandler = { _, _ in }
    let renewHandler: ACAccountStoreCredentialRenewalHandler = { _, _ in }
    _ = (saveHandler, accessHandler, removeHandler, renewHandler)
}

private func exerciseErrorSurface() {
    _ = ACErrorUnknown
    _ = ACErrorAccountMissingRequiredProperty
    _ = ACErrorAccountAuthenticationFailed
    _ = ACErrorAccountTypeInvalid
    _ = ACErrorAccountAlreadyExists
    _ = ACErrorAccountNotFound
    _ = ACErrorPermissionDenied
    _ = ACErrorAccessInfoInvalid
    _ = ACErrorClientPermissionDenied
    _ = ACErrorAccessDeniedByProtectionPolicy
    _ = ACErrorCredentialNotFound
    _ = ACErrorFetchCredentialFailed
    _ = ACErrorStoreCredentialFailed
    _ = ACErrorRemoveCredentialFailed
    _ = ACErrorUpdatingNonexistentAccount
    _ = ACErrorInvalidClientBundleID
    _ = ACErrorDeniedByPlugin
    _ = ACErrorCoreDataSaveFailed
    _ = ACErrorFailedSerializingAccountInfo
    _ = ACErrorInvalidCommand
    _ = ACErrorMissingTransportMessageID
    _ = ACErrorCredentialItemNotFound
    _ = ACErrorCredentialItemNotExpired

    let denied = ACErrorCode(rawValue: ACErrorPermissionDenied.rawValue)
    precondition(denied == ACErrorPermissionDenied)
    precondition(ACErrorCode(ACErrorPermissionDenied.rawValue) == ACErrorPermissionDenied)
    precondition(ACErrorUnknown != ACErrorPermissionDenied)

    var hasher = Hasher()
    ACErrorPermissionDenied.hash(into: &hasher)
    ACErrorUnknown.hash(into: &hasher)
    _ = hasher.finalize()
    precondition(Set([ACErrorUnknown, ACErrorPermissionDenied]).count == 2)
}

private func exerciseRenewResult() {
    precondition(ACAccountCredentialRenewResult(rawValue: ACAccountCredentialRenewResult.renewed.rawValue) == .renewed)
    precondition(ACAccountCredentialRenewResult(rawValue: ACAccountCredentialRenewResult.rejected.rawValue) == .rejected)
    precondition(ACAccountCredentialRenewResult(rawValue: ACAccountCredentialRenewResult.failed.rawValue) == .failed)
    precondition(ACAccountCredentialRenewResult(rawValue: 99) == nil)
    precondition(ACAccountCredentialRenewResult.renewed != .failed)

    var hasher = Hasher()
    ACAccountCredentialRenewResult.failed.hash(into: &hasher)
    _ = hasher.finalize()
    precondition(Set([ACAccountCredentialRenewResult.renewed, .rejected, .failed]).count == 3)
}

private func exerciseExactlyOnceCallbacks(store: ACAccountStore) {
    let accountType = store.accountType(
        withAccountTypeIdentifier: ACAccountTypeIdentifierFacebook
    )!
    let account = ACAccount(accountType: accountType)!
    account.username = "unused"
    let options: [AnyHashable: Any] = [
        ACFacebookAppIdKey: "unused-app-id",
        ACFacebookPermissionsKey: ["email"],
        ACFacebookAudienceKey: ACFacebookAudienceOnlyMe,
    ]

    func proveBoolCallback(_ start: (@escaping (Bool, (any Error)?) -> Void) -> Void) {
        let methodReturned = DispatchSemaphore(value: 0)
        let count = AccountsCounter()
        let once = DispatchSemaphore(value: 0)
        start { granted, error in
            precondition(
                methodReturned.wait(timeout: .now() + callbackTimeout) == .success,
                "handler ran before the method returned"
            )
            count.increment()
            precondition(granted == false)
            requireFailClosedError(error)
            once.signal()
        }
        methodReturned.signal()
        waitOnce(once)
        precondition(count.current() == 1)
        assertNoExtraSignal(once)
    }

    proveBoolCallback { handler in
        store.requestAccessToAccounts(with: accountType, options: options, completion: handler)
    }
    proveBoolCallback { handler in
        store.saveAccount(account, withCompletionHandler: handler)
    }
    proveBoolCallback { handler in
        store.removeAccount(account, withCompletionHandler: handler)
    }

    let renewReturned = DispatchSemaphore(value: 0)
    let renewCount = AccountsCounter()
    let renewOnce = DispatchSemaphore(value: 0)
    store.renewCredentials(for: account) { result, error in
        precondition(
            renewReturned.wait(timeout: .now() + callbackTimeout) == .success,
            "renew handler ran before the method returned"
        )
        renewCount.increment()
        precondition(result == .failed)
        requireFailClosedError(error)
        renewOnce.signal()
    }
    renewReturned.signal()
    waitOnce(renewOnce)
    precondition(renewCount.current() == 1)
    assertNoExtraSignal(renewOnce)

    let innerRanOnCallersStack = AccountsFlag()
    let outerDone = DispatchSemaphore(value: 0)
    let innerDone = DispatchSemaphore(value: 0)
    store.saveAccount(account, withCompletionHandler: { _, _ in
        let innerMethodReturned = DispatchSemaphore(value: 0)
        store.saveAccount(account, withCompletionHandler: { _, _ in
            if innerMethodReturned.wait(timeout: .now() + 0) != .success {
                innerRanOnCallersStack.set()
            }
            innerDone.signal()
        })
        innerMethodReturned.signal()
        outerDone.signal()
    })
    waitOnce(outerDone)
    waitOnce(innerDone)
    precondition(
        !innerRanOnCallersStack.get(),
        "nested saveAccount invoked its handler reentrantly"
    )
}

private func exerciseConcurrentCallbacks(store: ACAccountStore) {
    let accountType = store.accountType(
        withAccountTypeIdentifier: ACAccountTypeIdentifierTwitter
    )!
    let account = ACAccount(accountType: accountType)!
    let iterations = 8
    let group = DispatchGroup()
    let accessCount = AccountsCounter()
    let saveCount = AccountsCounter()
    let removeCount = AccountsCounter()
    let renewCount = AccountsCounter()

    for _ in 0..<iterations {
        group.enter()
        DispatchQueue.global(qos: .userInitiated).async {
            store.requestAccessToAccounts(with: accountType, options: [:]) { granted, error in
                precondition(granted == false)
                requireFailClosedError(error)
                accessCount.increment()
                group.leave()
            }
        }
        group.enter()
        DispatchQueue.global(qos: .userInitiated).async {
            store.saveAccount(account) { saved, error in
                precondition(saved == false)
                requireFailClosedError(error)
                saveCount.increment()
                group.leave()
            }
        }
        group.enter()
        DispatchQueue.global(qos: .userInitiated).async {
            store.removeAccount(account) { removed, error in
                precondition(removed == false)
                requireFailClosedError(error)
                removeCount.increment()
                group.leave()
            }
        }
        group.enter()
        DispatchQueue.global(qos: .userInitiated).async {
            store.renewCredentials(for: account) { result, error in
                precondition(result == .failed)
                requireFailClosedError(error)
                renewCount.increment()
                group.leave()
            }
        }
    }

    precondition(
        group.wait(timeout: .now() + .seconds(5)) == .success,
        "concurrent callbacks did not finish"
    )
    precondition(accessCount.current() == iterations)
    precondition(saveCount.current() == iterations)
    precondition(removeCount.current() == iterations)
    precondition(renewCount.current() == iterations)
}

private func exerciseAsyncOverlays(store: ACAccountStore) async {
    let accountType = store.accountType(
        withAccountTypeIdentifier: ACAccountTypeIdentifierFacebook
    )!
    let account = ACAccount(accountType: accountType)!
    let options: [AnyHashable: Any] = [ACFacebookAppIdKey: "unused"]

    await requireFailClosedThrow {
        _ = try await store.requestAccessToAccounts(with: accountType, options: options)
    }
    await requireFailClosedThrow {
        _ = try await store.saveAccount(account)
    }
    await requireFailClosedThrow {
        _ = try await store.removeAccount(account)
    }
    await requireFailClosedThrow {
        _ = try await store.renewCredentials(for: account)
    }

    await withTaskGroup(of: Void.self) { group in
        for _ in 0..<4 {
            group.addTask {
                await requireFailClosedThrow {
                    _ = try await store.saveAccount(account)
                }
            }
            group.addTask {
                await requireFailClosedThrow {
                    _ = try await store.requestAccessToAccounts(with: accountType)
                }
            }
        }
        await group.waitForAll()
    }

    precondition(store.accounts.count == 0)
    precondition(accountType.accessGranted == false)
    precondition(account.identifier == nil)
}

func accountsRuntimeMain() async {
    _ = ACErrorDomain
    _ = NSNotification.Name.ACAccountStoreDidChange
    exerciseErrorSurface()
    exerciseRenewResult()
    let store = ACAccountStore()
    exerciseLocalObjects(store: store)
    exerciseExactlyOnceCallbacks(store: store)
    exerciseConcurrentCallbacks(store: store)
    await exerciseAsyncOverlays(store: store)
    print("ACCOUNTS_AGENT_RUNTIME_OK")
}

let runtimeSemaphore = DispatchSemaphore(value: 0)
Task {
    await accountsRuntimeMain()
    runtimeSemaphore.signal()
}
runtimeSemaphore.wait()
