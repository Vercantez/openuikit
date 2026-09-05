import CloudKit
import Foundation

func testCKFailClosedIdentityAndSharingOperations() async {
    let named = isolatedContainer("identity")
    let recordID = CKRecord.ID(recordName: "rec-1")
    let lookup = CKUserIdentity.LookupInfo(emailAddress: "user@example.com")

    do {
        _ = try await named.requestApplicationPermission(.userDiscoverability)
        fatalError("permission must fail closed")
    } catch {
        requireCKError(error, code: .notAuthenticated)
    }
    do {
        _ = try await named.applicationPermissionStatus(for: .userDiscoverability)
        fatalError("permission status must fail closed")
    } catch {
        requireCKError(error, code: .notAuthenticated)
    }

    let userRecordID = await awaitValue { done in
        named.fetchUserRecordID { recordID, error in
            done((recordID, error))
        }
    }
    precondition(userRecordID.0 == nil)
    requireCKError(userRecordID.1, code: .notAuthenticated)

    do {
        _ = try await named.accept([] as [CKShare.Metadata])
        fatalError("accept must fail closed")
    } catch {
        requireCKError(error, code: .notAuthenticated)
    }
    named.accept([] as [CKShare.Metadata]) { result in
        if case .failure(let error) = result {
            requireCKError(error, code: .notAuthenticated)
        }
    }

    named.discoverUserIdentity(withEmailAddress: "user@example.com") { identity, error in
        precondition(identity == nil)
        requireCKError(error, code: .notAuthenticated)
    }
    named.discoverUserIdentity(withPhoneNumber: "+1") { _, _ in }
    named.discoverUserIdentity(withUserRecordID: recordID) { _, _ in }
    named.fetchShareMetadata(with: URL(fileURLWithPath: "/")) { _, _ in }
    named.fetchShareParticipant(withEmailAddress: "user@example.com") { _, _ in }
    named.fetchShareParticipant(withPhoneNumber: "+1") { _, _ in }
    named.fetchShareParticipant(withUserRecordID: recordID) { _, _ in }
    named.fetchShareMetadatas(for: []) { _ in }
    named.discoverUserIdentities(forUserRecordIDs: []) { _ in }
    named.discoverUserIdentities(forPhoneNumbers: []) { _ in }
    named.discoverUserIdentities(forEmailAddresses: []) { _ in }
    named.fetchShareParticipants(forPhoneNumbers: []) { _ in }
    named.fetchShareParticipants(forUserRecordIDs: []) { _ in }
    named.fetchShareParticipants(forEmailAddresses: []) { _ in }
    named.fetchLongLivedOperation(withID: "op") { _, _ in }
    named.fetchAllLongLivedOperationIDs { _, _ in }

    do { _ = try await named.shareMetadatas(for: []) } catch { requireCKError(error, code: .notAuthenticated) }
    do { _ = try await named.userIdentities(forPhoneNumbers: []) } catch { requireCKError(error, code: .notAuthenticated) }
    do { _ = try await named.userIdentities(forUserRecordIDs: []) } catch { requireCKError(error, code: .notAuthenticated) }
    do { _ = try await named.userIdentities(forEmailAddresses: []) } catch { requireCKError(error, code: .notAuthenticated) }
    do { _ = try await named.shareParticipants(forPhoneNumbers: []) } catch { requireCKError(error, code: .notAuthenticated) }
    do { _ = try await named.shareParticipants(forUserRecordIDs: []) } catch { requireCKError(error, code: .notAuthenticated) }
    do { _ = try await named.shareParticipants(forEmailAddresses: []) } catch { requireCKError(error, code: .notAuthenticated) }
    do { _ = try await named.shareParticipants(for: [lookup]) } catch { requireCKError(error, code: .notAuthenticated) }
    do { _ = try await named.longLivedOperation(for: "op") } catch { requireCKError(error, code: .notAuthenticated) }
    do { _ = try await named.requestShareAccess(for: []) } catch { requireCKError(error, code: .notAuthenticated) }
    do { _ = try await named.allLongLivedOperationIDs() } catch { requireCKError(error, code: .notAuthenticated) }
    do {
        _ = try await named.allUserIdentitiesFromContacts()
        fatalError("identity discovery must fail closed")
    } catch {
        requireCKError(error, code: .notAuthenticated)
    }
}

func testCKFailClosedOperationClasses() async {
    let named = isolatedContainer("fail-ops")
    let lookup = CKUserIdentity.LookupInfo(emailAddress: "user@example.com")
    let addLock = NSRecursiveLock()
    var insideContainerAdd = true
    let discover = CKDiscoverAllUserIdentitiesOperation()
    discover.userIdentityDiscoveredBlock = { _ in }
    discover.discoverAllUserIdentitiesResultBlock = { _ in }
    let discoverError = await awaitValue { done in
        discover.discoverAllUserIdentitiesCompletionBlock = { discoverErr in
            addLock.lock()
            let firedInline = insideContainerAdd
            addLock.unlock()
            done((discoverErr, firedInline))
        }
        addLock.lock()
        named.add(discover)
        insideContainerAdd = false
        addLock.unlock()
    }
    precondition(discoverError.1 == false, "CKContainer.add must not invoke completions inline")
    requireCKError(discoverError.0, code: .notAuthenticated)

    let discoverOne = CKDiscoverUserIdentitiesOperation(userIdentityLookupInfos: [lookup])
    discoverOne.userIdentityDiscoveredBlock = { _, _ in }
    discoverOne.discoverUserIdentitiesResultBlock = { _ in }
    precondition(discoverOne.userIdentityLookupInfos.count == 1)
    _ = CKDiscoverUserIdentitiesOperation()
}

func testCKFailClosedSharingAndWebAuthOperations() async {
    let lookup = CKUserIdentity.LookupInfo(emailAddress: "user@example.com")
    let acceptOp = CKAcceptSharesOperation()
    acceptOp.shareMetadatas = []
    acceptOp.perShareCompletionBlock = { _, _, _ in }
    acceptOp.perShareResultBlock = { _, _ in }
    acceptOp.acceptSharesResultBlock = { _ in }
    _ = CKAcceptSharesOperation(shareMetadatas: [])
    let metaOp = CKFetchShareMetadataOperation(shareURLs: [URL(fileURLWithPath: "/")])
    metaOp.perShareMetadataBlock = { _, _, _ in }
    metaOp.perShareMetadataResultBlock = { _, _ in }
    metaOp.fetchShareMetadataResultBlock = { _ in }
    metaOp.shouldFetchRootRecord = true
    metaOp.rootRecordDesiredKeys = ["title"]
    _ = CKFetchShareMetadataOperation(share: [URL(fileURLWithPath: "/")])
    _ = CKFetchShareParticipantsOperation(userIdentityLookupInfos: [lookup])
    _ = CKShareRequestAccessOperation(shareURLs: [])
}

func testCKFailClosedWebAuthAndSharingUI() {
    let named = isolatedContainer("fail-webauth")
    _ = CKFetchWebAuthTokenOperation(apiToken: "token")
    _ = CKFetchWebAuthTokenOperation(APIToken: "token")
    _ = CKFetchWebAuthTokenOperation()
    _ = CKSystemSharingUIObserver(container: named)
    let observer = CKSystemSharingUIObserver(container: named)
    observer.systemSharingUIDidSaveShareBlock = { _, _ in }
    observer.systemSharingUIDidStopSharingBlock = { _, _ in }
}

func testCKPublicConstants() {
    precondition(CKAccountChangedNotification == "CKAccountChangedNotification")
    precondition(NSNotification.Name.CKAccountChanged.rawValue == CKAccountChangedNotification)
    precondition(CKQueryOperationMaximumResults == 0)
    precondition(CKQueryOperation.maximumResults == CKQueryOperationMaximumResults)
}
