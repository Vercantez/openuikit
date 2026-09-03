import Foundation

open class CKFetchDatabaseChangesOperation: CKDatabaseOperation, @unchecked Sendable {
    open var changeTokenUpdatedBlock: ((CKServerChangeToken) -> Void)?
    open var fetchAllChanges: Bool = true
    open var fetchDatabaseChangesCompletionBlock: ((CKServerChangeToken?, Bool, (any Error)?) -> Void)?
    open var previousServerChangeToken: CKServerChangeToken?
    open var recordZoneWithIDChangedBlock: ((CKRecordZone.ID) -> Void)?
    open var recordZoneWithIDWasDeletedBlock: ((CKRecordZone.ID) -> Void)?
    open var recordZoneWithIDWasDeletedDueToUserEncryptedDataResetBlock: ((CKRecordZone.ID) -> Void)?
    open var recordZoneWithIDWasPurgedBlock: ((CKRecordZone.ID) -> Void)?
    open var resultsLimit: Int = 0

    public override init() {
        super.init()
    }

    public convenience init(previousServerChangeToken: CKServerChangeToken?) {
        self.init()
        self.previousServerChangeToken = previousServerChangeToken
    }

    override func finishFailClosed() {
        fetchDatabaseChangesCompletionBlock?(nil, false, CloudKitHost.unsupportedError())
    }
}

open class CKFetchRecordChangesOperation: CKDatabaseOperation, @unchecked Sendable {
    open var desiredKeys: [String]?
    open var fetchRecordChangesCompletionBlock: ((CKServerChangeToken?, Data?, (any Error)?) -> Void)?
    open private(set) var moreComing: Bool = false
    open var previousServerChangeToken: CKServerChangeToken?
    open var recordChangedBlock: ((CKRecord) -> Void)?
    open var recordWithIDWasDeletedBlock: ((CKRecord.ID) -> Void)?
    open var recordZoneID: CKRecordZone.ID?
    open var resultsLimit: Int = 0

    public override init() {
        super.init()
    }

    public convenience init(
        recordZoneID: CKRecordZone.ID,
        previousServerChangeToken: CKServerChangeToken?
    ) {
        self.init()
        self.recordZoneID = recordZoneID
        self.previousServerChangeToken = previousServerChangeToken
    }

    override func finishFailClosed() {
        fetchRecordChangesCompletionBlock?(nil, nil, CloudKitHost.unsupportedError())
    }
}

open class CKFetchRecordZoneChangesOperation: CKDatabaseOperation, @unchecked Sendable {
    open class ZoneConfiguration: NSObject, @unchecked Sendable {
        open var previousServerChangeToken: CKServerChangeToken?
        open var resultsLimit: Int = 0
        open var desiredKeys: [CKRecord.FieldKey]?

        public override init() {
            super.init()
        }
    }

    open class ZoneOptions: NSObject, @unchecked Sendable {
        open var desiredKeys: [String]?
        open var previousServerChangeToken: CKServerChangeToken?
        open var resultsLimit: Int = 0

        public override init() {
            super.init()
        }
    }

    open var configurationsByRecordZoneID: [CKRecordZone.ID: ZoneConfiguration]?
    open var fetchAllChanges: Bool = true
    open var fetchRecordZoneChangesCompletionBlock: (((any Error)?) -> Void)?
    open var optionsByRecordZoneID: [CKRecordZone.ID: ZoneOptions]?
    open var recordChangedBlock: ((CKRecord) -> Void)?
    open var recordZoneChangeTokensUpdatedBlock: ((CKRecordZone.ID, CKServerChangeToken?, Data?) -> Void)?
    open var recordZoneFetchCompletionBlock: ((CKRecordZone.ID, CKServerChangeToken?, Data?, Bool, (any Error)?) -> Void)?
    open var recordZoneIDs: [CKRecordZone.ID]?

    public override init() {
        super.init()
    }

    public convenience init(
        recordZoneIDs: [CKRecordZone.ID],
        optionsByRecordZoneID: [CKRecordZone.ID: ZoneOptions]? = nil
    ) {
        self.init()
        self.recordZoneIDs = recordZoneIDs
        self.optionsByRecordZoneID = optionsByRecordZoneID
    }

    override func finishFailClosed() {
        let error = CloudKitHost.unsupportedError()
        recordZoneIDs?.forEach { zoneID in
            recordZoneFetchCompletionBlock?(zoneID, nil, nil, false, error)
        }
        fetchRecordZoneChangesCompletionBlock?(error)
    }
}

open class CKFetchSubscriptionsOperation: CKDatabaseOperation, @unchecked Sendable {
    open var fetchSubscriptionsResultBlock: ((Result<Void, any Error>) -> Void)?
    open var subscriptionIDs: [CKSubscription.ID]?
    open var perSubscriptionResultBlock: ((CKSubscription.ID, Result<CKSubscription, any Error>) -> Void)?
    open var fetchSubscriptionCompletionBlock: (([CKSubscription.ID: CKSubscription]?, (any Error)?) -> Void)?

    public override required init() {
        super.init()
    }

    public convenience init(subscriptionIDs: [CKSubscription.ID]) {
        self.init()
        self.subscriptionIDs = subscriptionIDs
    }

    open class func fetchAllSubscriptionsOperation() -> Self {
        Self.init()
    }

    override func finishFailClosed() {
        let error = CloudKitHost.unsupportedError()
        subscriptionIDs?.forEach { subscriptionID in
            perSubscriptionResultBlock?(subscriptionID, .failure(error))
        }
        fetchSubscriptionCompletionBlock?(nil, error)
        fetchSubscriptionsResultBlock?(.failure(error))
    }
}

open class CKFetchWebAuthTokenOperation: CKDatabaseOperation, @unchecked Sendable {
    open var apiToken: String?
    open var fetchWebAuthTokenCompletionBlock: ((String?, (any Error)?) -> Void)?
    open var fetchWebAuthTokenResultBlock: ((Result<String, any Error>) -> Void)?

    public override init() {
        super.init()
    }

    public convenience init(apiToken APIToken: String) {
        self.init()
        self.apiToken = APIToken
    }

    override func finishFailClosed() {
        let error = CloudKitHost.unsupportedError()
        fetchWebAuthTokenCompletionBlock?(nil, error)
        fetchWebAuthTokenResultBlock?(.failure(error))
    }
}

open class CKAcceptSharesOperation: CKOperation, @unchecked Sendable {
    open var acceptSharesCompletionBlock: (((any Error)?) -> Void)?
    open var perShareCompletionBlock: ((CKShare.Metadata, CKShare?, (any Error)?) -> Void)?
    open var shareMetadatas: [CKShare.Metadata]?

    public override init() {
        super.init()
    }

    public convenience init(shareMetadatas: [CKShare.Metadata]) {
        self.init()
        self.shareMetadatas = shareMetadatas
    }

    override func finishFailClosed() {
        let error = CloudKitHost.unsupportedError()
        shareMetadatas?.forEach { metadata in
            perShareCompletionBlock?(metadata, nil, error)
        }
        acceptSharesCompletionBlock?(error)
    }
}

open class CKDiscoverAllUserIdentitiesOperation: CKOperation, @unchecked Sendable {
    open var discoverAllUserIdentitiesCompletionBlock: (((any Error)?) -> Void)?
    open var userIdentityDiscoveredBlock: ((CKUserIdentity) -> Void)?

    public override init() {
        super.init()
    }

    override func finishFailClosed() {
        discoverAllUserIdentitiesCompletionBlock?(CloudKitHost.unsupportedError())
    }
}

open class CKDiscoverUserIdentitiesOperation: CKOperation, @unchecked Sendable {
    open var discoverUserIdentitiesCompletionBlock: (((any Error)?) -> Void)?
    open var userIdentityDiscoveredBlock: ((CKUserIdentity, CKUserIdentity.LookupInfo) -> Void)?
    open var userIdentityLookupInfos: [CKUserIdentity.LookupInfo] = []

    public override init() {
        super.init()
    }

    public convenience init(userIdentityLookupInfos: [CKUserIdentity.LookupInfo]) {
        self.init()
        self.userIdentityLookupInfos = userIdentityLookupInfos
    }

    override func finishFailClosed() {
        discoverUserIdentitiesCompletionBlock?(CloudKitHost.unsupportedError())
    }
}

open class CKFetchShareMetadataOperation: CKOperation, @unchecked Sendable {
    open var fetchShareMetadataCompletionBlock: (((any Error)?) -> Void)?
    open var perShareMetadataBlock: ((URL, CKShare.Metadata?, (any Error)?) -> Void)?
    open var shareURLs: [URL]?
    open var shouldFetchRootRecord: Bool = false

    public override init() {
        super.init()
    }

    public convenience init(shareURLs: [URL]) {
        self.init()
        self.shareURLs = shareURLs
    }

    public convenience init(share shareURLs: [URL]) {
        self.init(shareURLs: shareURLs)
    }

    override func finishFailClosed() {
        let error = CloudKitHost.unsupportedError()
        shareURLs?.forEach { url in
            perShareMetadataBlock?(url, nil, error)
        }
        fetchShareMetadataCompletionBlock?(error)
    }
}

open class CKFetchShareParticipantsOperation: CKOperation, @unchecked Sendable {
    open var shareParticipantFetchedBlock: ((CKShare.Participant) -> Void)?
    open var fetchShareParticipantsCompletionBlock: (((any Error)?) -> Void)?
    open var userIdentityLookupInfos: [CKUserIdentity.LookupInfo]?
    open var perShareParticipantResultBlock: ((CKUserIdentity.LookupInfo, Result<CKShare.Participant, any Error>) -> Void)?
    open var fetchShareParticipantsResultBlock: ((Result<Void, any Error>) -> Void)?

    public override init() {
        super.init()
    }

    public convenience init(userIdentityLookupInfos: [CKUserIdentity.LookupInfo]) {
        self.init()
        self.userIdentityLookupInfos = userIdentityLookupInfos
    }

    override func finishFailClosed() {
        let error = CloudKitHost.unsupportedError()
        userIdentityLookupInfos?.forEach { info in
            perShareParticipantResultBlock?(info, .failure(error))
        }
        fetchShareParticipantsCompletionBlock?(error)
        fetchShareParticipantsResultBlock?(.failure(error))
    }
}

open class CKShareRequestAccessOperation: CKOperation, @unchecked Sendable {
    open var shareURLs: [URL]?
    open var shareAccessRequestResultBlock: ((Result<Void, any Error>) -> Void)?
    open var perShareAccessRequestResultBlock: ((URL, Result<Void, any Error>) -> Void)?

    public override init() {
        super.init()
    }

    public convenience init(shareURLs: [URL]) {
        self.init()
        self.shareURLs = shareURLs
    }

    override func finishFailClosed() {
        let error = CloudKitHost.unsupportedError()
        shareURLs?.forEach { url in
            perShareAccessRequestResultBlock?(url, .failure(error))
        }
        shareAccessRequestResultBlock?(.failure(error))
    }
}

open class CKSystemSharingUIObserver: NSObject, @unchecked Sendable {
    open var systemSharingUIDidSaveShareBlock: ((CKRecord.ID, Result<CKShare, any Error>) -> Void)?
    open var systemSharingUIDidStopSharingBlock: ((CKRecord.ID, Result<Void, any Error>) -> Void)?

    public init(container: CKContainer) {
        _ = container
        super.init()
    }
}
