import Foundation

open class CKContainer: NSObject, @unchecked Sendable {
    public enum ApplicationPermissionStatus: Int, Sendable, Hashable {
        case initialState = 0
        case couldNotComplete = 1
        case denied = 2
        case granted = 3
    }

    public struct ApplicationPermissions: OptionSet, Sendable, Hashable {
        public let rawValue: UInt

        public init(rawValue: UInt) {
            self.rawValue = rawValue
        }

        public static let userDiscoverability = ApplicationPermissions(rawValue: 1 << 0)
    }

    public typealias ApplicationPermissionBlock = (
        CKContainer.ApplicationPermissionStatus,
        (any Error)?
    ) -> Void

    public enum Application {
        public typealias Permissions = CKContainer.ApplicationPermissions
        public typealias PermissionBlock = CKContainer.ApplicationPermissionBlock
        public typealias PermissionStatus = CKContainer.ApplicationPermissionStatus
    }

    private static let defaultContainer = CKContainer(defaultMarker: ())

    open private(set) var containerIdentifier: String?
    let simulatedState: CKSimulatedContainerState
    private let privateDatabase: CKDatabase
    private let publicDatabase: CKDatabase
    private let sharedDatabase: CKDatabase

    open class func `default`() -> CKContainer {
        defaultContainer
    }

    public init(identifier containerIdentifier: String) {
        self.containerIdentifier = containerIdentifier
        self.simulatedState = CKSimulatedContainerState(identifier: containerIdentifier)
        self.privateDatabase = CKDatabase(scope: .private)
        self.publicDatabase = CKDatabase(scope: .public)
        self.sharedDatabase = CKDatabase(scope: .shared)
        super.init()
        privateDatabase.attach(container: self)
        publicDatabase.attach(container: self)
        sharedDatabase.attach(container: self)
    }

    private init(defaultMarker: Void) {
        self.containerIdentifier = nil
        self.simulatedState = CKSimulatedContainerState(identifier: nil)
        self.privateDatabase = CKDatabase(scope: .private)
        self.publicDatabase = CKDatabase(scope: .public)
        self.sharedDatabase = CKDatabase(scope: .shared)
        super.init()
        privateDatabase.attach(container: self)
        publicDatabase.attach(container: self)
        sharedDatabase.attach(container: self)
    }

    /// Simulated-container network. Not an Apple API. CloudKitRuntime
    /// networkUnavailable probe: after `true`, save returns CKError.networkUnavailable.
    public func setSimulatedOffline(_ offline: Bool) {
        simulatedState.lock.lock()
        simulatedState.offline = offline
        simulatedState.lock.unlock()
    }

    open var privateCloudDatabase: CKDatabase { privateDatabase }
    open var publicCloudDatabase: CKDatabase { publicDatabase }
    open var sharedCloudDatabase: CKDatabase { sharedDatabase }

    open func database(with databaseScope: CKDatabase.Scope) -> CKDatabase {
        switch databaseScope {
        case .private: return privateDatabase
        case .public: return publicDatabase
        case .shared: return sharedDatabase
        }
    }

    open func add(_ operation: CKOperation) {
        operation.container = self
        CloudKitHost.schedule(operation)
    }

    open func accountStatus(
        completionHandler: @escaping (CKAccountStatus, (any Error)?) -> Void
    ) {
        CloudKitHost.schedule {
            // Linux has no iCloud account. Measured: CloudKitRuntime accountStatus
            // probe expects .noAccount with a nil error.
            completionHandler(.noAccount, nil)
        }
    }

    open func fetchUserRecordID(
        completionHandler: @escaping (CKRecord.ID?, (any Error)?) -> Void
    ) {
        CloudKitHost.completeUnsupported(completionHandler)
    }

    open func requestApplicationPermission(
        _ applicationPermission: CKContainer.ApplicationPermissions
    ) async throws -> CKContainer.ApplicationPermissionStatus {
        _ = applicationPermission
        throw CloudKitHost.unsupportedError()
    }

    open func applicationPermissionStatus(
        for applicationPermission: CKContainer.ApplicationPermissions
    ) async throws -> CKContainer.ApplicationPermissionStatus {
        _ = applicationPermission
        throw CloudKitHost.unsupportedError()
    }

    open func accept(_ metadata: CKShare.Metadata) async throws -> CKShare {
        _ = metadata
        return try CloudKitHost.fail()
    }

    open func accept(
        _ metadatas: [CKShare.Metadata],
        completionHandler: @escaping (
            Result<[CKShare.Metadata: Result<CKShare, any Error>], any Error>
        ) -> Void
    ) {
        _ = metadatas
        completionHandler(.failure(CloudKitHost.unsupportedError()))
    }

    open func accept(
        _ metadatas: [CKShare.Metadata]
    ) async throws -> [CKShare.Metadata: Result<CKShare, any Error>] {
        throw CloudKitHost.unsupportedError()
    }

    open func allUserIdentitiesFromContacts() async throws -> [CKUserIdentity] {
        try CloudKitHost.fail()
    }

    open func discoverUserIdentity(
        withEmailAddress email: String,
        completionHandler: @escaping (CKUserIdentity?, (any Error)?) -> Void
    ) {
        _ = email
        CloudKitHost.completeUnsupported(completionHandler)
    }

    open func discoverUserIdentity(
        withPhoneNumber phoneNumber: String,
        completionHandler: @escaping (CKUserIdentity?, (any Error)?) -> Void
    ) {
        _ = phoneNumber
        CloudKitHost.completeUnsupported(completionHandler)
    }

    open func discoverUserIdentity(
        withUserRecordID userRecordID: CKRecord.ID,
        completionHandler: @escaping (CKUserIdentity?, (any Error)?) -> Void
    ) {
        _ = userRecordID
        CloudKitHost.completeUnsupported(completionHandler)
    }

    open func fetchShareMetadata(
        with url: URL,
        completionHandler: @escaping (CKShare.Metadata?, (any Error)?) -> Void
    ) {
        _ = url
        CloudKitHost.completeUnsupported(completionHandler)
    }

    open func fetchShareParticipant(
        withEmailAddress emailAddress: String,
        completionHandler: @escaping (CKShare.Participant?, (any Error)?) -> Void
    ) {
        _ = emailAddress
        CloudKitHost.completeUnsupported(completionHandler)
    }

    open func fetchShareParticipant(
        withPhoneNumber phoneNumber: String,
        completionHandler: @escaping (CKShare.Participant?, (any Error)?) -> Void
    ) {
        _ = phoneNumber
        CloudKitHost.completeUnsupported(completionHandler)
    }

    open func fetchShareParticipant(
        withUserRecordID userRecordID: CKRecord.ID,
        completionHandler: @escaping (CKShare.Participant?, (any Error)?) -> Void
    ) {
        _ = userRecordID
        CloudKitHost.completeUnsupported(completionHandler)
    }

    open func shareMetadatas(for urls: [URL]) async throws -> [URL: Result<CKShare.Metadata, any Error>] {
        _ = urls
        throw CloudKitHost.unsupportedError()
    }

    open func userIdentities(forPhoneNumbers phoneNumbers: [String]) async throws -> [String: CKUserIdentity] {
        _ = phoneNumbers
        throw CloudKitHost.unsupportedError()
    }

    open func userIdentities(forUserRecordIDs userRecordIDs: [CKRecord.ID]) async throws -> [CKRecord.ID: CKUserIdentity] {
        _ = userRecordIDs
        throw CloudKitHost.unsupportedError()
    }

    open func userIdentities(forEmailAddresses emails: [String]) async throws -> [String: CKUserIdentity] {
        _ = emails
        throw CloudKitHost.unsupportedError()
    }

    open func shareParticipants(
        forPhoneNumbers phoneNumbers: [String]
    ) async throws -> [String: Result<CKShare.Participant, any Error>] {
        _ = phoneNumbers
        throw CloudKitHost.unsupportedError()
    }

    open func shareParticipants(
        forUserRecordIDs userRecordIDs: [CKRecord.ID]
    ) async throws -> [CKRecord.ID: Result<CKShare.Participant, any Error>] {
        _ = userRecordIDs
        throw CloudKitHost.unsupportedError()
    }

    open func shareParticipants(
        forEmailAddresses emails: [String]
    ) async throws -> [String: Result<CKShare.Participant, any Error>] {
        _ = emails
        throw CloudKitHost.unsupportedError()
    }

    open func shareParticipants(
        for lookupInfos: [CKUserIdentity.LookupInfo]
    ) async throws -> [CKUserIdentity.LookupInfo: Result<CKShare.Participant, any Error>] {
        _ = lookupInfos
        throw CloudKitHost.unsupportedError()
    }

    open func longLivedOperation(for operationID: CKOperation.ID) async throws -> CKOperation? {
        _ = operationID
        throw CloudKitHost.unsupportedError()
    }

    open func requestShareAccess(for urls: [URL]) async throws -> [URL: Result<Void, any Error>] {
        _ = urls
        throw CloudKitHost.unsupportedError()
    }

    open func fetchShareMetadatas(
        for urls: [URL],
        completionHandler: @escaping (Result<[URL: Result<CKShare.Metadata, any Error>], any Error>) -> Void
    ) {
        _ = urls
        completionHandler(.failure(CloudKitHost.unsupportedError()))
    }

    open func discoverUserIdentities(
        forUserRecordIDs userRecordIDs: [CKRecord.ID],
        completionHandler: @escaping (Result<[CKRecord.ID: CKUserIdentity], any Error>) -> Void
    ) {
        _ = userRecordIDs
        completionHandler(.failure(CloudKitHost.unsupportedError()))
    }

    open func discoverUserIdentities(
        forPhoneNumbers phoneNumbers: [String],
        completionHandler: @escaping (Result<[String: CKUserIdentity], any Error>) -> Void
    ) {
        _ = phoneNumbers
        completionHandler(.failure(CloudKitHost.unsupportedError()))
    }

    open func discoverUserIdentities(
        forEmailAddresses emails: [String],
        completionHandler: @escaping (Result<[String: CKUserIdentity], any Error>) -> Void
    ) {
        _ = emails
        completionHandler(.failure(CloudKitHost.unsupportedError()))
    }

    open func fetchShareParticipants(
        forPhoneNumbers phoneNumbers: [String],
        completionHandler: @escaping (Result<[String: Result<CKShare.Participant, any Error>], any Error>) -> Void
    ) {
        _ = phoneNumbers
        completionHandler(.failure(CloudKitHost.unsupportedError()))
    }

    open func fetchShareParticipants(
        forUserRecordIDs userRecordIDs: [CKRecord.ID],
        completionHandler: @escaping (Result<[CKRecord.ID: Result<CKShare.Participant, any Error>], any Error>) -> Void
    ) {
        _ = userRecordIDs
        completionHandler(.failure(CloudKitHost.unsupportedError()))
    }

    open func fetchShareParticipants(
        forEmailAddresses emails: [String],
        completionHandler: @escaping (Result<[String: Result<CKShare.Participant, any Error>], any Error>) -> Void
    ) {
        _ = emails
        completionHandler(.failure(CloudKitHost.unsupportedError()))
    }

    open func fetchLongLivedOperation(
        withID operationID: CKOperation.ID,
        completionHandler: @escaping (CKOperation?, (any Error)?) -> Void
    ) {
        _ = operationID
        CloudKitHost.completeUnsupported(completionHandler)
    }

    open func allLongLivedOperationIDs() async throws -> [CKOperation.ID] {
        try CloudKitHost.fail()
    }

    open func fetchAllLongLivedOperationIDs(
        completionHandler: @escaping ([CKOperation.ID]?, (any Error)?) -> Void
    ) {
        CloudKitHost.completeUnsupported(completionHandler)
    }

    @discardableResult
    open func configuredWith<R>(
        configuration: CKOperation.Configuration? = nil,
        group: CKOperationGroup? = nil,
        body: (CKContainer) throws -> R
    ) rethrows -> R {
        _ = (configuration, group)
        return try body(self)
    }

    @discardableResult
    open func configuredWith<R>(
        configuration: CKOperation.Configuration? = nil,
        group: CKOperationGroup? = nil,
        body: (CKContainer) async throws -> R
    ) async rethrows -> R {
        _ = (configuration, group)
        return try await body(self)
    }
}
