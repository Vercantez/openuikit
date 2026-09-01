import Accounts
import Foundation

private func requirePermissionDenied(_ error: (any Error)?) {
    guard let error else {
        fatalError("expected ACErrorPermissionDenied NSError")
    }
    let nsError = error as NSError
    precondition(nsError.domain == ACErrorDomain)
    precondition(nsError.code == Int(ACErrorPermissionDenied.rawValue))
}

private func requirePermissionDeniedThrow(_ body: () async throws -> Void) async {
    do {
        try await body()
        fatalError("expected fail-closed throw")
    } catch {
        requirePermissionDenied(error)
    }
}

private func exerciseConstants() {
    precondition(ACErrorDomain == "com.apple.accounts")
    precondition(ACAccountTypeIdentifierTwitter == "com.apple.twitter")
    precondition(ACAccountTypeIdentifierFacebook == "com.apple.facebook")
    precondition(ACAccountTypeIdentifierSinaWeibo == "com.apple.sinaweibo")
    precondition(ACAccountTypeIdentifierTencentWeibo == "com.apple.tencentweibo")
    precondition(ACFacebookAppIdKey == "ACFacebookAppIdKey")
    precondition(ACFacebookPermissionsKey == "ACFacebookPermissionsKey")
    precondition(ACFacebookAudienceKey == "ACFacebookAudienceKey")
    precondition(ACFacebookAudienceEveryone == "everyone")
    precondition(ACFacebookAudienceFriends == "friends")
    precondition(ACFacebookAudienceOnlyMe == "only_me")
    precondition(ACTencentWeiboAppIdKey == "ACTencentWeiboAppIdKey")
    precondition(
        NSNotification.Name.ACAccountStoreDidChange.rawValue
            == "ACAccountStoreDidChangeNotification"
    )
}

private func exerciseErrorCodes() {
    let codes: [ACErrorCode] = [
        ACErrorUnknown,
        ACErrorAccountMissingRequiredProperty,
        ACErrorAccountAuthenticationFailed,
        ACErrorAccountTypeInvalid,
        ACErrorAccountAlreadyExists,
        ACErrorAccountNotFound,
        ACErrorPermissionDenied,
        ACErrorAccessInfoInvalid,
        ACErrorClientPermissionDenied,
        ACErrorAccessDeniedByProtectionPolicy,
        ACErrorCredentialNotFound,
        ACErrorFetchCredentialFailed,
        ACErrorStoreCredentialFailed,
        ACErrorRemoveCredentialFailed,
        ACErrorUpdatingNonexistentAccount,
        ACErrorInvalidClientBundleID,
        ACErrorDeniedByPlugin,
        ACErrorCoreDataSaveFailed,
        ACErrorFailedSerializingAccountInfo,
        ACErrorInvalidCommand,
        ACErrorMissingTransportMessageID,
        ACErrorCredentialItemNotFound,
        ACErrorCredentialItemNotExpired,
    ]
    precondition(codes.map(\.rawValue) == Array(UInt32(1)...UInt32(23)))
    precondition(ACErrorCode(rawValue: 7) == ACErrorPermissionDenied)
    precondition(ACErrorCode(7) == ACErrorPermissionDenied)
    precondition(ACErrorUnknown != ACErrorPermissionDenied)
    precondition(ACErrorUnknown == ACErrorCode(rawValue: 1))

    var hasher = Hasher()
    ACErrorPermissionDenied.hash(into: &hasher)
    ACErrorUnknown.hash(into: &hasher)
    _ = hasher.finalize()
    precondition(Set(codes).count == codes.count)
}

private func exerciseRenewResult() {
    precondition(ACAccountCredentialRenewResult.renewed.rawValue == 0)
    precondition(ACAccountCredentialRenewResult.rejected.rawValue == 1)
    precondition(ACAccountCredentialRenewResult.failed.rawValue == 2)
    precondition(ACAccountCredentialRenewResult(rawValue: 0) == .renewed)
    precondition(ACAccountCredentialRenewResult(rawValue: 1) == .rejected)
    precondition(ACAccountCredentialRenewResult(rawValue: 2) == .failed)
    precondition(ACAccountCredentialRenewResult(rawValue: 3) == nil)
    precondition(ACAccountCredentialRenewResult.renewed != .failed)

    var hasher = Hasher()
    ACAccountCredentialRenewResult.failed.hash(into: &hasher)
    _ = hasher.finalize()
    precondition(Set([ACAccountCredentialRenewResult.renewed, .rejected, .failed]).count == 3)
}

private func exerciseLocalObjects(store: ACAccountStore) {
    precondition(store.accounts.count == 0)

    let twitterType = store.accountType(
        withAccountTypeIdentifier: ACAccountTypeIdentifierTwitter
    )!
    precondition(twitterType.identifier == ACAccountTypeIdentifierTwitter)
    precondition(twitterType.accountTypeDescription == ACAccountTypeIdentifierTwitter)
    precondition(twitterType.accessGranted == false)

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
    precondition(account.identifier == nil)
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

private func exerciseFailClosedStore(store: ACAccountStore) async {
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

    let accessResult = await withCheckedContinuation { continuation in
        store.requestAccessToAccounts(with: accountType, options: options) { granted, error in
            continuation.resume(returning: (granted, error))
        }
    }
    precondition(accessResult.0 == false)
    requirePermissionDenied(accessResult.1)

    let saveResult = await withCheckedContinuation { continuation in
        store.saveAccount(account) { saved, error in
            continuation.resume(returning: (saved, error))
        }
    }
    precondition(saveResult.0 == false)
    requirePermissionDenied(saveResult.1)

    let removeResult = await withCheckedContinuation { continuation in
        store.removeAccount(account) { removed, error in
            continuation.resume(returning: (removed, error))
        }
    }
    precondition(removeResult.0 == false)
    requirePermissionDenied(removeResult.1)

    let renewResult = await withCheckedContinuation { continuation in
        store.renewCredentials(for: account) { result, error in
            continuation.resume(returning: (result, error))
        }
    }
    precondition(renewResult.0 == .failed)
    requirePermissionDenied(renewResult.1)

    await requirePermissionDeniedThrow {
        _ = try await store.requestAccessToAccounts(with: accountType, options: options)
    }
    await requirePermissionDeniedThrow {
        _ = try await store.saveAccount(account)
    }
    await requirePermissionDeniedThrow {
        _ = try await store.removeAccount(account)
    }
    await requirePermissionDeniedThrow {
        _ = try await store.renewCredentials(for: account)
    }

    precondition(store.accounts.count == 0)
    precondition(accountType.accessGranted == false)
    precondition(account.identifier == nil)
}

func accountsRuntimeMain() async {
    exerciseConstants()
    exerciseErrorCodes()
    exerciseRenewResult()
    let store = ACAccountStore()
    exerciseLocalObjects(store: store)
    await exerciseFailClosedStore(store: store)
    print("ACCOUNTS_AGENT_RUNTIME_OK")
}

let runtimeSemaphore = DispatchSemaphore(value: 0)
Task {
    await accountsRuntimeMain()
    runtimeSemaphore.signal()
}
runtimeSemaphore.wait()
