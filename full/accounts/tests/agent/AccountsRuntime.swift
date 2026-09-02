@_spi(OpenUIKitHost) import Accounts
import Foundation

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

private final class LockedCounter: @unchecked Sendable {
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
    precondition(nsError.domain == "com.apple.accounts")
    precondition(nsError.domain == ACErrorDomain)
    precondition(nsError.code == 7)
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

private func waitEvent(_ semaphore: DispatchSemaphore, _ message: String) {
    precondition(semaphore.wait(timeout: .now() + eventTimeout) == .success, message)
}

/// Occupy the SPI-exposed Linux completion queue until `release` so later `async`
/// completions cannot run. `occupy` returns only after the blocker is running.
private final class CompletionQueueBlocker: @unchecked Sendable {
    private let occupied = DispatchSemaphore(value: 0)
    private let hold = DispatchSemaphore(value: 0)

    func occupy() {
        AccountsHostControl.enqueueCompletionProbe {
            self.occupied.signal()
            self.hold.wait()
        }
        waitEvent(occupied, "completion queue blocker did not start")
    }

    func release() {
        hold.signal()
    }
}

private func drainCompletionQueue() {
    let drained = DispatchSemaphore(value: 0)
    AccountsHostControl.enqueueCompletionProbe {
        drained.signal()
    }
    waitEvent(drained, "completion queue did not drain")
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
    precondition(ACFacebookAppIdKey == "ACFacebookAppIdKey")
    precondition(ACFacebookPermissionsKey == "ACFacebookPermissionsKey")
    precondition(ACFacebookAudienceKey == "ACFacebookAudienceKey")
    precondition(ACFacebookAudienceEveryone == "everyone")
    precondition(ACFacebookAudienceFriends == "friends")
    precondition(ACFacebookAudienceOnlyMe == "me")
    precondition(ACTencentWeiboAppIdKey == "ACTencentWeiboAppIdKey")

    let codes: [(ACErrorCode, UInt32)] = [
        (ACErrorUnknown, 1),
        (ACErrorAccountMissingRequiredProperty, 2),
        (ACErrorAccountAuthenticationFailed, 3),
        (ACErrorAccountTypeInvalid, 4),
        (ACErrorAccountAlreadyExists, 5),
        (ACErrorAccountNotFound, 6),
        (ACErrorPermissionDenied, 7),
        (ACErrorAccessInfoInvalid, 8),
        (ACErrorClientPermissionDenied, 9),
        (ACErrorAccessDeniedByProtectionPolicy, 10),
        (ACErrorCredentialNotFound, 11),
        (ACErrorFetchCredentialFailed, 12),
        (ACErrorStoreCredentialFailed, 13),
        (ACErrorRemoveCredentialFailed, 14),
        (ACErrorUpdatingNonexistentAccount, 15),
        (ACErrorInvalidClientBundleID, 16),
        (ACErrorDeniedByPlugin, 17),
        (ACErrorCoreDataSaveFailed, 18),
        (ACErrorFailedSerializingAccountInfo, 19),
        (ACErrorInvalidCommand, 20),
        (ACErrorMissingTransportMessageID, 21),
        (ACErrorCredentialItemNotFound, 22),
        (ACErrorCredentialItemNotExpired, 23),
    ]
    for (code, raw) in codes {
        precondition(code.rawValue == raw)
        precondition(ACErrorCode(rawValue: raw) == code)
        precondition(ACErrorCode(raw) == code)
    }
    precondition(ACErrorUnknown != ACErrorPermissionDenied)
    precondition(ACErrorUnknown != ACErrorCredentialItemNotExpired)

    var hasher = Hasher()
    ACErrorPermissionDenied.hash(into: &hasher)
    ACErrorUnknown.hash(into: &hasher)
    _ = hasher.finalize()
    precondition(Set(codes.map(\.0)).count == 23)
}

private func assertAccountTypeLookup(store: ACAccountStore) {
    let known = [
        (ACAccountTypeIdentifierTwitter, "Twitter"),
        (ACAccountTypeIdentifierFacebook, "Facebook"),
        (ACAccountTypeIdentifierSinaWeibo, "Sina Weibo"),
        (ACAccountTypeIdentifierTencentWeibo, "Tencent Weibo"),
    ]
    for (identifier, description) in known {
        let accountType = store.accountType(withAccountTypeIdentifier: identifier)
        precondition(accountType != nil, identifier)
        precondition(accountType!.identifier == identifier)
        precondition(accountType!.accountTypeDescription == description)
        precondition(accountType!.accessGranted == false)
    }
    precondition(store.accountType(withAccountTypeIdentifier: "com.example.unknown") == nil)
    precondition(store.accountType(withAccountTypeIdentifier: "com.apple.tencentweibo") == nil)
    precondition(store.accountType(withAccountTypeIdentifier: nil) == nil)
}

private func exerciseLocalObjects(store: ACAccountStore) {
    let accounts: NSArray = store.accounts
    precondition(accounts.count == 0)

    let twitterType = store.accountType(
        withAccountTypeIdentifier: ACAccountTypeIdentifierTwitter
    )!
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

private func exerciseRenewResult() {
    precondition(ACAccountCredentialRenewResult.renewed.rawValue == 0)
    precondition(ACAccountCredentialRenewResult.rejected.rawValue == 1)
    precondition(ACAccountCredentialRenewResult.failed.rawValue == 2)
    precondition(ACAccountCredentialRenewResult(rawValue: 0) == .renewed)
    precondition(ACAccountCredentialRenewResult(rawValue: 1) == .rejected)
    precondition(ACAccountCredentialRenewResult(rawValue: 2) == .failed)
    precondition(ACAccountCredentialRenewResult(rawValue: 99) == nil)
    precondition(ACAccountCredentialRenewResult.renewed != .failed)

    var hasher = Hasher()
    ACAccountCredentialRenewResult.failed.hash(into: &hasher)
    _ = hasher.finalize()
    precondition(Set([ACAccountCredentialRenewResult.renewed, .rejected, .failed]).count == 3)
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
        requireFailClosedError(error)
    }
    state.markReturned()
    let drained = DispatchSemaphore(value: 0)
    AccountsHostControl.enqueueCompletionProbe {
        drained.signal()
    }
    blocker.release()
    waitEvent(drained, "bool callback did not drain")
    let snapshot = state.snapshot()
    precondition(snapshot.sawReturned, "callback did not observe returned=true")
    precondition(snapshot.count == 1)
}

private func proveRenewCallback(store: ACAccountStore, account: ACAccount) {
    let state = LockedState()
    let blocker = CompletionQueueBlocker()
    blocker.occupy()
    store.renewCredentials(for: account) { result, error in
        state.noteCallback()
        precondition(result == .failed)
        requireFailClosedError(error)
    }
    state.markReturned()
    let drained = DispatchSemaphore(value: 0)
    AccountsHostControl.enqueueCompletionProbe {
        drained.signal()
    }
    blocker.release()
    waitEvent(drained, "renew callback did not drain")
    let snapshot = state.snapshot()
    precondition(snapshot.sawReturned, "renew callback did not observe returned=true")
    precondition(snapshot.count == 1)
}

private func proveNilHandlers(store: ACAccountStore, account: ACAccount, accountType: ACAccountType) {
    let blocker = CompletionQueueBlocker()
    blocker.occupy()
    store.saveAccount(account, withCompletionHandler: nil)
    store.removeAccount(account, withCompletionHandler: nil)
    store.requestAccessToAccounts(with: accountType, options: [:], completion: nil)
    store.renewCredentials(for: account, completion: nil)
    let drained = DispatchSemaphore(value: 0)
    AccountsHostControl.enqueueCompletionProbe {
        drained.signal()
    }
    blocker.release()
    waitEvent(drained, "nil-handler drain did not complete")
}

private func exerciseGatedCallbacks(store: ACAccountStore) {
    let accountType = store.accountType(
        withAccountTypeIdentifier: ACAccountTypeIdentifierFacebook
    )!
    let account = ACAccount(accountType: accountType)!
    let options: [AnyHashable: Any] = [
        ACFacebookAppIdKey: "unused-app-id",
        ACFacebookPermissionsKey: ["email"],
        ACFacebookAudienceKey: ACFacebookAudienceOnlyMe,
    ]

    proveBoolCallback { handler in
        store.requestAccessToAccounts(with: accountType, options: options, completion: handler)
    }
    proveBoolCallback { handler in
        store.saveAccount(account, withCompletionHandler: handler)
    }
    proveBoolCallback { handler in
        store.removeAccount(account, withCompletionHandler: handler)
    }
    proveRenewCallback(store: store, account: account)
    proveNilHandlers(store: store, account: account, accountType: accountType)
}

private func exerciseConcurrentCallbacks(store: ACAccountStore) {
    let accountType = store.accountType(
        withAccountTypeIdentifier: ACAccountTypeIdentifierTwitter
    )!
    let account = ACAccount(accountType: accountType)!
    let iterations = 8
    let group = DispatchGroup()
    let accessCount = LockedCounter()
    let saveCount = LockedCounter()
    let removeCount = LockedCounter()
    let renewCount = LockedCounter()

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
        group.wait(timeout: .now() + eventTimeout) == .success,
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
    assertOracleConstants()
    exerciseRenewResult()
    let store = ACAccountStore()
    assertAccountTypeLookup(store: store)
    exerciseLocalObjects(store: store)
    exerciseGatedCallbacks(store: store)
    exerciseConcurrentCallbacks(store: store)
    await exerciseAsyncOverlays(store: store)
    drainCompletionQueue()
    print("ACCOUNTS_AGENT_RUNTIME_OK")
}

let runtimeSemaphore = DispatchSemaphore(value: 0)
Task {
    await accountsRuntimeMain()
    runtimeSemaphore.signal()
}
runtimeSemaphore.wait()
