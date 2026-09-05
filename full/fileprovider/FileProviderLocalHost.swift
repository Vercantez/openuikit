import Foundation

/// Process-local File Provider host. Domains persist as JSON under the port
/// documents directory. This is not Apple's `fileproviderd`, Files.app, or an
/// application-extension host.
final class FileProviderLocalHost: NSObject, FileProviderHostAdapter, @unchecked Sendable {
    static let shared = FileProviderLocalHost()

    private let lock = NSLock()
    private var domainRecords: [String: NSFileProviderDomain] = [:]
    private var domainVersions: [String: NSFileProviderDomainVersion] = [:]
    private var providers: [String: FileProviderLocalReplicatedExtension] = [:]
    private var enumeratorBoxes: [EnumeratorBox] = []
    private var pendingOperations = 0
    private var changeWaiters: [@Sendable () -> Void] = []
    private var stabilizeWaiters: [@Sendable () -> Void] = []
    private var sessionTasks: [String: AnyObject] = [:]
    private var resolvedErrors: [String] = []

    private struct EnumeratorBox {
        let container: NSFileProviderItemIdentifier
        let domainID: String
        weak var enumerator: FileProviderLocalEnumerator?
    }

    private override init() {
        super.init()
        loadRegistry()
    }

    func resetForTesting() {
        lock.lock()
        domainRecords = [:]
        domainVersions = [:]
        providers = [:]
        enumeratorBoxes = []
        pendingOperations = 0
        changeWaiters = []
        stabilizeWaiters = []
        sessionTasks = [:]
        resolvedErrors = []
        lock.unlock()
        let root = FileProviderHost.storageRoot()
        try? FileManager.default.removeItem(at: root)
        _ = FileProviderHost.storageRoot()
        persistRegistry()
    }

    func documentsDirectory() -> URL {
        let url = FileProviderHost.storageRoot()
            .appendingPathComponent("documents", isDirectory: true)
        try? FileManager.default.createDirectory(
            at: url,
            withIntermediateDirectories: true
        )
        return url
    }

    func mountDirectory(for domain: NSFileProviderDomain) -> URL {
        let url = documentsDirectory().appendingPathComponent(
            domain.identifier.rawValue,
            isDirectory: true
        )
        try? FileManager.default.createDirectory(
            at: url,
            withIntermediateDirectories: true
        )
        return url
    }

    func providerStorage(for domain: NSFileProviderDomain) -> URL {
        let url = FileProviderHost.storageRoot()
            .appendingPathComponent("providers", isDirectory: true)
            .appendingPathComponent(domain.identifier.rawValue, isDirectory: true)
        try? FileManager.default.createDirectory(
            at: url,
            withIntermediateDirectories: true
        )
        return url
    }

    func addDomain(_ domain: NSFileProviderDomain) async throws {
        try addDomainSync(domain)
    }

    func addDomainSync(_ domain: NSFileProviderDomain) throws {
        domain.isReplicated = true
        if domain.backingStoreIdentity == nil {
            domain.backingStoreIdentity = UUID().uuidString.data(using: .utf8)
        }
        _ = mountDirectory(for: domain)
        _ = providerStorage(for: domain)
        lock.lock()
        domainRecords[domain.identifier.rawValue] = domain
        if domainVersions[domain.identifier.rawValue] == nil {
            domainVersions[domain.identifier.rawValue] = NSFileProviderDomainVersion()
        }
        let provider = providers[domain.identifier.rawValue]
            ?? FileProviderLocalReplicatedExtension(domain: domain, host: self)
        provider.attach(domain: domain)
        providers[domain.identifier.rawValue] = provider
        lock.unlock()
        persistRegistry()
        NotificationCenter.default.post(name: .fileProviderDomainDidChange, object: domain)
    }

    func domains() async throws -> [NSFileProviderDomain] {
        domainsSync()
    }

    func domainsSync() -> [NSFileProviderDomain] {
        lock.lock()
        let values = Array(domainRecords.values).sorted {
            $0.identifier.rawValue < $1.identifier.rawValue
        }
        lock.unlock()
        return values
    }

    func registeredDomain(identifier: NSFileProviderDomainIdentifier) -> NSFileProviderDomain? {
        lock.lock()
        let domain = domainRecords[identifier.rawValue]
        lock.unlock()
        return domain
    }

    func domainVersion(for identifier: NSFileProviderDomainIdentifier) -> NSFileProviderDomainVersion {
        lock.lock()
        let version = domainVersions[identifier.rawValue] ?? NSFileProviderDomainVersion()
        lock.unlock()
        return version
    }

    func bumpDomainVersion(for identifier: NSFileProviderDomainIdentifier) -> NSFileProviderDomainVersion {
        lock.lock()
        let next = (domainVersions[identifier.rawValue] ?? NSFileProviderDomainVersion()).next()
        domainVersions[identifier.rawValue] = next
        lock.unlock()
        return next
    }

    func provider(for domain: NSFileProviderDomain) -> FileProviderLocalReplicatedExtension {
        lock.lock()
        if let existing = providers[domain.identifier.rawValue] {
            lock.unlock()
            return existing
        }
        let created = FileProviderLocalReplicatedExtension(domain: domain, host: self)
        providers[domain.identifier.rawValue] = created
        lock.unlock()
        return created
    }

    func provider(forIdentifier identifier: NSFileProviderDomainIdentifier) -> FileProviderLocalReplicatedExtension? {
        lock.lock()
        let provider = providers[identifier.rawValue]
        lock.unlock()
        return provider
    }

    func removeDomain(_ domain: NSFileProviderDomain) async throws {
        try removeDomainSync(domain)
    }

    func removeDomainSync(_ domain: NSFileProviderDomain) throws {
        lock.lock()
        let existed = domainRecords.removeValue(forKey: domain.identifier.rawValue) != nil
        providers.removeValue(forKey: domain.identifier.rawValue)
        domainVersions.removeValue(forKey: domain.identifier.rawValue)
        enumeratorBoxes.removeAll { $0.domainID == domain.identifier.rawValue }
        lock.unlock()
        guard existed else {
            throw FileProviderHost.unsupported(.providerDomainNotFound)
        }
        try? FileManager.default.removeItem(at: mountDirectory(for: domain))
        try? FileManager.default.removeItem(at: providerStorage(for: domain))
        persistRegistry()
        NotificationCenter.default.post(name: .fileProviderDomainDidChange, object: domain)
    }

    func removeDomain(
        _ domain: NSFileProviderDomain,
        mode: NSFileProviderManager.DomainRemovalMode
    ) async throws -> URL? {
        _ = mode
        let preserved = mountDirectory(for: domain)
        try await removeDomain(domain)
        return preserved
    }

    func removeAllDomains() async throws {
        let existing = domainsSync()
        for domain in existing {
            try await removeDomain(domain)
        }
    }

    func writePlaceholder(at url: URL, metadata: NSFileProviderItem) throws {
        try NSFileProviderManager._writeLinuxPlaceholderJSON(at: url, withMetadata: metadata)
    }

    func writePlaceholder(at url: URL, resourceValues: [URLResourceKey: Any]) throws {
        try NSFileProviderManager._writeLinuxPlaceholderJSON(
            at: url,
            resourceValues: resourceValues
        )
    }

    func registerEnumerator(
        _ enumerator: FileProviderLocalEnumerator,
        domain: NSFileProviderDomain,
        container: NSFileProviderItemIdentifier
    ) {
        lock.lock()
        enumeratorBoxes.removeAll { $0.enumerator == nil }
        enumeratorBoxes.append(
            EnumeratorBox(
                container: container,
                domainID: domain.identifier.rawValue,
                enumerator: enumerator
            )
        )
        lock.unlock()
    }

    func signalEnumerator(
        domain: NSFileProviderDomain,
        container: NSFileProviderItemIdentifier
    ) async throws {
        try signalEnumeratorSync(domain: domain, container: container)
    }

    func signalEnumeratorSync(
        domain: NSFileProviderDomain,
        container: NSFileProviderItemIdentifier
    ) throws {
        guard registeredDomain(identifier: domain.identifier) != nil else {
            throw FileProviderHost.unsupported(.providerDomainNotFound)
        }
        _ = bumpDomainVersion(for: domain.identifier)
        lock.lock()
        enumeratorBoxes.removeAll { $0.enumerator == nil }
        let targets = enumeratorBoxes.filter {
            $0.domainID == domain.identifier.rawValue
                && ($0.container == container || container == .workingSet)
        }
        let waiters = changeWaiters
        changeWaiters = []
        lock.unlock()
        for box in targets {
            box.enumerator?.hostDidSignal()
        }
        for waiter in waiters {
            waiter()
        }
    }

    func waitForChanges() async {
        await withCheckedContinuation { continuation in
            enqueueChangeWaiter {
                continuation.resume()
            }
        }
    }

    func enqueueChangeWaiter(_ waiter: @escaping @Sendable () -> Void) {
        lock.lock()
        if pendingOperations == 0 {
            lock.unlock()
            waiter()
            return
        }
        changeWaiters.append(waiter)
        lock.unlock()
    }

    func waitForStabilization(completionHandler: @escaping @Sendable () -> Void) {
        lock.lock()
        if pendingOperations == 0 {
            lock.unlock()
            FileProviderCallback.queue.async(execute: completionHandler)
            return
        }
        stabilizeWaiters.append(completionHandler)
        lock.unlock()
    }

    func beginOperation() {
        lock.lock()
        pendingOperations += 1
        lock.unlock()
    }

    func endOperation() {
        lock.lock()
        pendingOperations = max(0, pendingOperations - 1)
        let drained = pendingOperations == 0
        let stabilize = drained ? stabilizeWaiters : []
        let changes = drained ? changeWaiters : []
        if drained {
            stabilizeWaiters = []
            changeWaiters = []
        }
        lock.unlock()
        if drained {
            for waiter in stabilize {
                FileProviderCallback.queue.async(execute: waiter)
            }
            for waiter in changes {
                waiter()
            }
        }
    }

    func userVisibleURL(
        domain: NSFileProviderDomain,
        itemIdentifier: NSFileProviderItemIdentifier
    ) throws -> URL {
        let provider = provider(for: domain)
        let item = try provider.storedItem(for: itemIdentifier)
        let mount = mountDirectory(for: domain)
        if itemIdentifier == .rootContainer {
            return mount
        }
        return mount.appendingPathComponent(item.filename)
    }

    func identifierForUserVisibleFile(
        at url: URL
    ) throws -> (NSFileProviderItemIdentifier, NSFileProviderDomainIdentifier) {
        let mountRoot = documentsDirectory().standardizedFileURL.path
        let standardized = url.standardizedFileURL
        let path = standardized.path
        guard path.hasPrefix(mountRoot) else {
            throw FileProviderHost.unsupported(.noSuchItem)
        }
        let relative = String(path.dropFirst(mountRoot.count))
            .trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let parts = relative.split(separator: "/", maxSplits: 1).map(String.init)
        guard let domainID = parts.first, !domainID.isEmpty else {
            throw FileProviderHost.unsupported(.noSuchItem)
        }
        let identifier = NSFileProviderDomainIdentifier(domainID)
        guard let domain = registeredDomain(identifier: identifier) else {
            throw FileProviderHost.unsupported(.providerDomainNotFound)
        }
        if parts.count == 1 {
            return (.rootContainer, identifier)
        }
        let filename = (parts[1] as NSString).lastPathComponent
        let provider = provider(for: domain)
        if let item = provider.itemMatching(filename: filename) {
            return (item.itemIdentifier, identifier)
        }
        throw FileProviderHost.unsupported(
            .noSuchItem,
            userInfo: [NSFileProviderErrorNonExistentItemIdentifierKey: filename]
        )
    }

    func registerTask(_ task: AnyObject, identifier: NSFileProviderItemIdentifier) {
        lock.lock()
        sessionTasks[identifier.rawValue] = task
        lock.unlock()
    }

    func signalErrorResolved(_ error: any Error) {
        lock.lock()
        resolvedErrors.append(String(describing: error))
        lock.unlock()
    }

    func testingOperations(for domain: NSFileProviderDomain) -> [any NSFileProviderTestingOperation] {
        guard domain.testingModes.contains(.alwaysEnabled)
            || domain.testingModes.contains(.interactive)
        else {
            return []
        }
        let provider = provider(for: domain)
        return provider.makeTestingOperations()
    }

    private func registryURL() -> URL {
        FileProviderHost.storageRoot().appendingPathComponent("domains.json")
    }

    private func persistRegistry() {
        lock.lock()
        let payload: [[String: Any]] = domainRecords.values.map { domain in
            [
                "identifier": domain.identifier.rawValue,
                "displayName": domain.displayName,
                "pathRelativeToDocumentStorage": domain.pathRelativeToDocumentStorage,
                "isReplicated": domain.isReplicated,
                "supportsSyncingTrash": domain.supportsSyncingTrash,
                "testingModes": domain.testingModes.rawValue,
                "userEnabled": domain.userEnabled,
                "backingStoreIdentity": domain.backingStoreIdentity?.base64EncodedString() ?? "",
                "generation": domainVersions[domain.identifier.rawValue]?.generation ?? 0,
            ]
        }
        lock.unlock()
        guard let data = try? JSONSerialization.data(
            withJSONObject: payload,
            options: [.prettyPrinted, .sortedKeys]
        ) else {
            return
        }
        try? data.write(to: registryURL(), options: .atomic)
    }

    private func loadRegistry() {
        guard let data = try? Data(contentsOf: registryURL()),
            let payload = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]]
        else {
            return
        }
        for row in payload {
            guard let identifier = row["identifier"] as? String,
                let displayName = row["displayName"] as? String
            else {
                continue
            }
            let path = row["pathRelativeToDocumentStorage"] as? String ?? identifier
            let domain = NSFileProviderDomain(
                identifier: NSFileProviderDomainIdentifier(identifier),
                displayName: displayName,
                pathRelativeToDocumentStorage: path
            )
            domain.isReplicated = row["isReplicated"] as? Bool ?? true
            domain.supportsSyncingTrash = row["supportsSyncingTrash"] as? Bool ?? true
            domain.userEnabled = row["userEnabled"] as? Bool ?? true
            if let modes = row["testingModes"] as? UInt {
                domain.testingModes = NSFileProviderDomain.TestingModes(rawValue: modes)
            }
            if let identity = row["backingStoreIdentity"] as? String, !identity.isEmpty {
                domain.backingStoreIdentity = Data(base64Encoded: identity)
            }
            domainRecords[identifier] = domain
            let generation = row["generation"] as? Int64 ?? 0
            domainVersions[identifier] = NSFileProviderDomainVersion(generation: generation)
            providers[identifier] = FileProviderLocalReplicatedExtension(
                domain: domain,
                host: self
            )
        }
    }
}

/// Mutable item used by the in-process replicated provider.
final class FileProviderStoredItem: NSObject, NSFileProviderItemProtocol, NSFileProviderItemDecorating {
    var itemIdentifier: NSFileProviderItemIdentifier
    var parentItemIdentifier: NSFileProviderItemIdentifier
    var filename: String
    var capabilities: NSFileProviderItemCapabilities
    var childItemCount: NSNumber?
    var contentModificationDate: Date?
    var contentPolicy: NSFileProviderContentPolicy
    var creationDate: Date?
    var documentSize: NSNumber?
    var isDownloaded: Bool
    var isDownloading: Bool
    var downloadingError: (any Error)?
    var extendedAttributes: [String: Data]
    var favoriteRank: NSNumber?
    var fileSystemFlags: NSFileProviderFileSystemFlags
    var itemVersion: NSFileProviderItemVersion?
    var lastUsedDate: Date?
    var mostRecentEditorNameComponents: PersonNameComponents?
    var isMostRecentVersionDownloaded: Bool
    var ownerNameComponents: PersonNameComponents?
    var isShared: Bool
    var isSharedByCurrentUser: Bool
    var symlinkTargetPath: String?
    var tagData: Data?
    var isTrashed: Bool
    var typeAndCreator: NSFileProviderTypeAndCreator
    var typeIdentifier: String?
    var isUploaded: Bool
    var isUploading: Bool
    var uploadingError: (any Error)?
    var userInfo: [AnyHashable: Any]?
    var versionIdentifier: Data?
    var decorations: [NSFileProviderItemDecorationIdentifier]?
    var contentURL: URL?

    init(
        itemIdentifier: NSFileProviderItemIdentifier,
        parentItemIdentifier: NSFileProviderItemIdentifier,
        filename: String
    ) {
        self.itemIdentifier = itemIdentifier
        self.parentItemIdentifier = parentItemIdentifier
        self.filename = filename
        self.capabilities = [.allowsAll, .allowsEvicting]
        self.childItemCount = 0
        let now = Date()
        self.contentModificationDate = now
        self.contentPolicy = .inherited
        self.creationDate = now
        self.documentSize = 0
        self.isDownloaded = true
        self.isDownloading = false
        self.downloadingError = nil
        self.extendedAttributes = [:]
        self.favoriteRank = NSNumber(value: NSFileProviderFavoriteRankUnranked)
        self.fileSystemFlags = [.userReadable, .userWritable]
        self.itemVersion = NSFileProviderItemVersion(
            contentVersion: Data([0]),
            metadataVersion: Data([0])
        )
        self.lastUsedDate = now
        self.mostRecentEditorNameComponents = nil
        self.isMostRecentVersionDownloaded = true
        self.ownerNameComponents = nil
        self.isShared = false
        self.isSharedByCurrentUser = false
        self.symlinkTargetPath = nil
        self.tagData = nil
        self.isTrashed = false
        self.typeAndCreator = NSFileProviderTypeAndCreator()
        self.typeIdentifier = "public.item"
        self.isUploaded = true
        self.isUploading = false
        self.uploadingError = nil
        self.userInfo = [:]
        self.versionIdentifier = Data([0])
        self.decorations = []
        super.init()
    }

    func copyItem() -> FileProviderStoredItem {
        let copy = FileProviderStoredItem(
            itemIdentifier: itemIdentifier,
            parentItemIdentifier: parentItemIdentifier,
            filename: filename
        )
        copy.capabilities = capabilities
        copy.childItemCount = childItemCount
        copy.contentModificationDate = contentModificationDate
        copy.contentPolicy = contentPolicy
        copy.creationDate = creationDate
        copy.documentSize = documentSize
        copy.isDownloaded = isDownloaded
        copy.isDownloading = isDownloading
        copy.downloadingError = downloadingError
        copy.extendedAttributes = extendedAttributes
        copy.favoriteRank = favoriteRank
        copy.fileSystemFlags = fileSystemFlags
        copy.itemVersion = itemVersion
        copy.lastUsedDate = lastUsedDate
        copy.mostRecentEditorNameComponents = mostRecentEditorNameComponents
        copy.isMostRecentVersionDownloaded = isMostRecentVersionDownloaded
        copy.ownerNameComponents = ownerNameComponents
        copy.isShared = isShared
        copy.isSharedByCurrentUser = isSharedByCurrentUser
        copy.symlinkTargetPath = symlinkTargetPath
        copy.tagData = tagData
        copy.isTrashed = isTrashed
        copy.typeAndCreator = typeAndCreator
        copy.typeIdentifier = typeIdentifier
        copy.isUploaded = isUploaded
        copy.isUploading = isUploading
        copy.uploadingError = uploadingError
        copy.userInfo = userInfo
        copy.versionIdentifier = versionIdentifier
        copy.decorations = decorations
        copy.contentURL = contentURL
        return copy
    }

    func bumpVersion() {
        let content = itemVersion?.contentVersion ?? Data()
        let meta = itemVersion?.metadataVersion ?? Data()
        var nextMeta = Array(meta)
        if nextMeta.isEmpty {
            nextMeta = [0]
        }
        nextMeta[nextMeta.count - 1] &+= 1
        itemVersion = NSFileProviderItemVersion(
            contentVersion: content,
            metadataVersion: Data(nextMeta)
        )
        versionIdentifier = itemVersion?.metadataVersion
    }
}

final class FileProviderLocalEnumerator: NSObject, NSFileProviderEnumerator, NSFileProviderPendingSetEnumerator {
    private weak var host: FileProviderLocalHost?
    private weak var provider: FileProviderLocalReplicatedExtension?
    let container: NSFileProviderItemIdentifier
    private(set) var lastAnchor: NSFileProviderSyncAnchor
    private var invalid = false
    let domainVersion: NSFileProviderDomainVersion?
    let isMaximumSizeReached = false
    let refreshInterval: TimeInterval = 15
    var pendingOnly = false
    var materializedOnly = false

    init(
        host: FileProviderLocalHost,
        provider: FileProviderLocalReplicatedExtension,
        container: NSFileProviderItemIdentifier,
        domainVersion: NSFileProviderDomainVersion?
    ) {
        self.host = host
        self.provider = provider
        self.container = container
        self.domainVersion = domainVersion
        self.lastAnchor = NSFileProviderSyncAnchor(Data("0".utf8))
        super.init()
        host.registerEnumerator(self, domain: provider.domain, container: container)
    }

    func invalidate() {
        invalid = true
    }

    func hostDidSignal() {
        lastAnchor = NSFileProviderSyncAnchor(
            Data(String(host?.domainVersion(for: provider?.domain.identifier
                ?? NSFileProviderDomainIdentifier("")).generation ?? 0).utf8)
        )
    }

    func enumerateItems(
        for observer: any NSFileProviderEnumerationObserver,
        startingAt page: NSFileProviderPage
    ) {
        if invalid {
            FileProviderCallback.queue.async {
                observer.finishEnumeratingWithError(NSFileProviderError(.cannotSynchronize))
            }
            return
        }
        let items = visibleItems()
        let sorted: [FileProviderStoredItem]
        let byDate = page.rawValue == Data(referencing: NSFileProviderPage.initialPageSortedByDate)
            || page.rawValue.starts(with: Data("date:".utf8))
        if byDate {
            sorted = items.sorted {
                ($0.contentModificationDate ?? .distantPast)
                    < ($1.contentModificationDate ?? .distantPast)
            }
        } else {
            sorted = items.sorted { $0.filename.localizedCompare($1.filename) == .orderedAscending }
        }
        let pageSize = max(observer.suggestedPageSize, 1)
        let offset = Self.offset(from: page)
        let slice = Array(sorted.dropFirst(offset).prefix(pageSize))
        let nextOffset = offset + slice.count
        FileProviderCallback.queue.async {
            observer.didEnumerate(slice)
            if nextOffset < sorted.count {
                let prefix = byDate ? "date:" : "name:"
                observer.finishEnumerating(
                    upTo: NSFileProviderPage(Data("\(prefix)\(nextOffset)".utf8))
                )
            } else {
                observer.finishEnumerating(upTo: nil)
            }
        }
    }

    func enumerateChanges(
        for observer: any NSFileProviderChangeObserver,
        from syncAnchor: NSFileProviderSyncAnchor
    ) {
        if invalid {
            FileProviderCallback.queue.async {
                observer.finishEnumeratingWithError(NSFileProviderError(.cannotSynchronize))
            }
            return
        }
        let token = String(data: syncAnchor.rawValue, encoding: .utf8) ?? ""
        if !syncAnchor.rawValue.isEmpty && token != "0" && Int64(token) == nil {
            FileProviderCallback.queue.async {
                observer.finishEnumeratingWithError(NSFileProviderError(.syncAnchorExpired))
            }
            return
        }
        guard let provider else {
            FileProviderCallback.queue.async {
                observer.finishEnumeratingWithError(NSFileProviderError(.providerNotFound))
            }
            return
        }
        let snapshot = provider.changeSnapshot(from: syncAnchor, container: container)
        lastAnchor = snapshot.anchor
        FileProviderCallback.queue.async {
            if !snapshot.deleted.isEmpty {
                observer.didDeleteItems(withIdentifiers: snapshot.deleted)
            }
            if !snapshot.updated.isEmpty {
                observer.didUpdate(snapshot.updated)
            }
            observer.finishEnumeratingChanges(upTo: snapshot.anchor, moreComing: snapshot.moreComing)
        }
    }

    func currentSyncAnchor(completionHandler: @escaping (NSFileProviderSyncAnchor?) -> Void) {
        let once = FileProviderCallback.Once()
        FileProviderCallback.asyncOnce(once) {
            completionHandler(self.lastAnchor)
        }
    }

    private func visibleItems() -> [FileProviderStoredItem] {
        guard let provider else { return [] }
        return provider.items(
            in: container,
            pendingOnly: pendingOnly,
            materializedOnly: materializedOnly
        )
    }

    private static func offset(from page: NSFileProviderPage) -> Int {
        let text = String(data: page.rawValue, encoding: .utf8) ?? ""
        if let range = text.range(of: "name:") {
            return Int(text[range.upperBound...]) ?? 0
        }
        if let range = text.range(of: "date:") {
            return Int(text[range.upperBound...]) ?? 0
        }
        return 0
    }
}

@_spi(OpenUIKitHost)
public final class FileProviderLocalReplicatedExtension: NSObject, NSFileProviderReplicatedExtension,
    NSFileProviderIncrementalContentFetching, NSFileProviderThumbnailing, NSFileProviderServicing,
    NSFileProviderCustomAction, NSFileProviderDomainState, @unchecked Sendable
{
    private(set) var domain: NSFileProviderDomain
    private weak var host: FileProviderLocalHost?
    private let lock = NSLock()
    private var items: [String: FileProviderStoredItem] = [:]
    private var deletedSince: [String: NSFileProviderItemIdentifier] = [:]
    private var generation: Int64 = 0

    public var domainVersion: NSFileProviderDomainVersion {
        host?.domainVersion(for: domain.identifier) ?? NSFileProviderDomainVersion()
    }

    public var userInfo: [AnyHashable: Any] {
        ["domain": domain.identifier.rawValue]
    }

    public init(domain: NSFileProviderDomain) {
        self.domain = domain
        super.init()
        seedRoot()
    }

    init(domain: NSFileProviderDomain, host: FileProviderLocalHost) {
        self.domain = domain
        self.host = host
        super.init()
        seedRoot()
        loadFromDisk()
    }

    func attach(domain: NSFileProviderDomain) {
        self.domain = domain
    }

    public func invalidate() {
        lock.lock()
        items.removeAll()
        deletedSince.removeAll()
        lock.unlock()
        seedRoot()
    }

    public func enumerator(
        for containerItemIdentifier: NSFileProviderItemIdentifier,
        request: NSFileProviderRequest
    ) throws -> any NSFileProviderEnumerator {
        _ = request
        guard let host else {
            throw FileProviderHost.unsupported()
        }
        return FileProviderLocalEnumerator(
            host: host,
            provider: self,
            container: containerItemIdentifier,
            domainVersion: domainVersion
        )
    }

    public func item(
        for identifier: NSFileProviderItemIdentifier,
        request: NSFileProviderRequest,
        completionHandler: @escaping (NSFileProviderItem?, (any Error)?) -> Void
    ) -> Progress {
        _ = request
        let progress = Progress(totalUnitCount: 1)
        FileProviderCallback.queue.async {
            do {
                let stored = try self.storedItem(for: identifier)
                progress.completedUnitCount = 1
                completionHandler(stored, nil)
            } catch {
                progress.completedUnitCount = 1
                completionHandler(nil, error)
            }
        }
        return progress
    }

    public func createItem(
        basedOn itemTemplate: NSFileProviderItem,
        fields: NSFileProviderItemFields,
        contents url: URL?,
        options: NSFileProviderCreateItemOptions,
        request: NSFileProviderRequest,
        completionHandler: @escaping (
            NSFileProviderItem?,
            NSFileProviderItemFields,
            Bool,
            (any Error)?
        ) -> Void
    ) -> Progress {
        _ = request
        host?.beginOperation()
        let progress = Progress(totalUnitCount: 1)
        FileProviderCallback.queue.async {
            defer {
                progress.completedUnitCount = 1
                self.host?.endOperation()
            }
            let parent = fields.contains(.parentItemIdentifier)
                ? itemTemplate.parentItemIdentifier
                : .rootContainer
            let filename = fields.contains(.filename) ? itemTemplate.filename : "untitled"
            if let existing = self.itemMatching(filename: filename, parent: parent) {
                if options.contains(.mayAlreadyExist) {
                    completionHandler(existing, [], false, nil)
                    return
                }
                completionHandler(
                    nil,
                    [],
                    false,
                    NSFileProviderError(
                        .filenameCollision,
                        userInfo: [
                            NSFileProviderErrorCollidingItemKey: existing,
                            NSFileProviderErrorItemKey: existing,
                        ]
                    )
                )
                return
            }
            let identifier = itemTemplate.itemIdentifier.rawValue.isEmpty
                ? NSFileProviderItemIdentifier(UUID().uuidString)
                : itemTemplate.itemIdentifier
            if self.lookup(identifier) != nil && !options.contains(.deletionConflicted) {
                completionHandler(
                    nil,
                    [],
                    false,
                    NSFileProviderError(.filenameCollision)
                )
                return
            }
            let stored = FileProviderStoredItem(
                itemIdentifier: identifier,
                parentItemIdentifier: parent,
                filename: filename
            )
            self.apply(fields, from: itemTemplate, onto: stored)
            stored.capabilities = itemTemplate.capabilities
            stored.contentPolicy = itemTemplate.contentPolicy
            stored.typeIdentifier = itemTemplate.typeIdentifier
            stored.userInfo = itemTemplate.userInfo
            stored.isTrashed = itemTemplate.isTrashed
            stored.symlinkTargetPath = itemTemplate.symlinkTargetPath
            if let url {
                self.persistContents(url, onto: stored)
            }
            let fetch = fields.contains(.contents) && url == nil
            stored.isDownloaded = url != nil
            self.lock.lock()
            self.items[identifier.rawValue] = stored
            self.deletedSince.removeValue(forKey: identifier.rawValue)
            self.generation += 1
            self.lock.unlock()
            self.materializeVisibleCopy(stored)
            self.saveToDisk()
            completionHandler(stored, [], fetch, nil)
        }
        return progress
    }

    public func modifyItem(
        _ item: NSFileProviderItem,
        baseVersion version: NSFileProviderItemVersion,
        changedFields: NSFileProviderItemFields,
        contents newContents: URL?,
        options: NSFileProviderModifyItemOptions,
        request: NSFileProviderRequest,
        completionHandler: @escaping (
            NSFileProviderItem?,
            NSFileProviderItemFields,
            Bool,
            (any Error)?
        ) -> Void
    ) -> Progress {
        _ = request
        host?.beginOperation()
        let progress = Progress(totalUnitCount: 1)
        FileProviderCallback.queue.async {
            defer {
                progress.completedUnitCount = 1
                self.host?.endOperation()
            }
            guard let existing = self.lookup(item.itemIdentifier) else {
                completionHandler(nil, [], false, NSFileProviderError(.noSuchItem))
                return
            }
            if options.contains(.failOnConflict),
                let current = existing.itemVersion,
                current.contentVersion != version.contentVersion
                    || current.metadataVersion != version.metadataVersion
            {
                completionHandler(
                    existing,
                    changedFields,
                    false,
                    NSFileProviderError(.localVersionConflictingWithServer)
                )
                return
            }
            if changedFields.contains(.filename) || changedFields.contains(.parentItemIdentifier) {
                let filename = changedFields.contains(.filename) ? item.filename : existing.filename
                let parent = changedFields.contains(.parentItemIdentifier)
                    ? item.parentItemIdentifier
                    : existing.parentItemIdentifier
                if let other = self.itemMatching(filename: filename, parent: parent),
                    other.itemIdentifier != existing.itemIdentifier,
                    !options.contains(.mayAlreadyExist)
                {
                    completionHandler(
                        existing,
                        changedFields,
                        false,
                        NSFileProviderError(
                            .filenameCollision,
                            userInfo: [
                                NSFileProviderErrorCollidingItemKey: other,
                                NSFileProviderErrorItemKey: other,
                            ]
                        )
                    )
                    return
                }
            }
            self.apply(changedFields, from: item, onto: existing)
            if let newContents {
                self.persistContents(newContents, onto: existing)
                existing.isDownloaded = true
            }
            existing.bumpVersion()
            if options.contains(.isImmediateUploadRequestByPresentingApplication) {
                existing.isUploading = false
                existing.isUploaded = true
            }
            self.generation += 1
            self.materializeVisibleCopy(existing)
            self.saveToDisk()
            let fetch = changedFields.contains(.contents) && newContents == nil
            completionHandler(existing, [], fetch, nil)
        }
        return progress
    }

    public func deleteItem(
        identifier: NSFileProviderItemIdentifier,
        baseVersion version: NSFileProviderItemVersion,
        options: NSFileProviderDeleteItemOptions,
        request: NSFileProviderRequest,
        completionHandler: @escaping ((any Error)?) -> Void
    ) -> Progress {
        _ = version
        _ = request
        host?.beginOperation()
        let progress = Progress(totalUnitCount: 1)
        FileProviderCallback.queue.async {
            defer {
                progress.completedUnitCount = 1
                self.host?.endOperation()
            }
            guard self.lookup(identifier) != nil else {
                completionHandler(NSFileProviderError(.noSuchItem))
                return
            }
            let children = self.children(of: identifier)
            if !children.isEmpty && !options.contains(.recursive) {
                completionHandler(NSFileProviderError(.directoryNotEmpty))
                return
            }
            var removed = [identifier]
            if options.contains(.recursive) {
                removed.append(contentsOf: self.subtree(of: identifier))
            }
            self.lock.lock()
            for id in removed {
                if let item = self.items.removeValue(forKey: id.rawValue) {
                    if let url = item.contentURL {
                        try? FileManager.default.removeItem(at: url)
                    }
                    self.deletedSince[id.rawValue] = id
                }
            }
            self.generation += 1
            self.lock.unlock()
            self.saveToDisk()
            completionHandler(nil)
        }
        return progress
    }

    public func fetchContents(
        for itemIdentifier: NSFileProviderItemIdentifier,
        version requestedVersion: NSFileProviderItemVersion?,
        request: NSFileProviderRequest,
        completionHandler: @escaping (URL?, NSFileProviderItem?, (any Error)?) -> Void
    ) -> Progress {
        _ = requestedVersion
        _ = request
        host?.beginOperation()
        let progress = Progress(totalUnitCount: 1)
        FileProviderCallback.queue.async {
            defer {
                progress.completedUnitCount = 1
                self.host?.endOperation()
            }
            do {
                let stored = try self.storedItem(for: itemIdentifier)
                stored.isDownloading = false
                stored.isDownloaded = true
                stored.isMostRecentVersionDownloaded = true
                completionHandler(stored.contentURL, stored, nil)
            } catch {
                completionHandler(nil, nil, error)
            }
        }
        return progress
    }

    public func fetchContents(
        for itemIdentifier: NSFileProviderItemIdentifier,
        version requestedVersion: NSFileProviderItemVersion?,
        usingExistingContentsAt existingContents: URL,
        existingVersion: NSFileProviderItemVersion,
        request: NSFileProviderRequest,
        completionHandler: @escaping (URL?, NSFileProviderItem?, (any Error)?) -> Void
    ) -> Progress {
        _ = existingVersion
        _ = requestedVersion
        _ = request
        host?.beginOperation()
        let progress = Progress(totalUnitCount: 1)
        FileProviderCallback.queue.async {
            defer {
                progress.completedUnitCount = 1
                self.host?.endOperation()
            }
            do {
                let stored = try self.storedItem(for: itemIdentifier)
                self.persistContents(existingContents, onto: stored)
                stored.isDownloaded = true
                completionHandler(stored.contentURL, stored, nil)
            } catch {
                completionHandler(nil, nil, error)
            }
        }
        return progress
    }

    public func fetchThumbnails(
        for itemIdentifiers: [NSFileProviderItemIdentifier],
        requestedSize size: CGSize,
        perThumbnailCompletionHandler: @escaping (
            NSFileProviderItemIdentifier,
            Data?,
            (any Error)?
        ) -> Void,
        completionHandler: @escaping ((any Error)?) -> Void
    ) -> Progress {
        _ = size
        let progress = Progress(totalUnitCount: Int64(max(itemIdentifiers.count, 1)))
        FileProviderCallback.queue.async {
            for identifier in itemIdentifiers {
                perThumbnailCompletionHandler(
                    identifier,
                    nil,
                    FileProviderHost.unsupported()
                )
                progress.completedUnitCount += 1
            }
            completionHandler(FileProviderHost.unsupported())
        }
        return progress
    }

    public func supportedServiceSources(
        for itemIdentifier: NSFileProviderItemIdentifier,
        completionHandler: @escaping ([any NSFileProviderServiceSource]?, (any Error)?) -> Void
    ) -> Progress {
        _ = itemIdentifier
        let progress = Progress(totalUnitCount: 1)
        FileProviderCallback.queue.async {
            progress.completedUnitCount = 1
            completionHandler(nil, FileProviderHost.unsupported())
        }
        return progress
    }

    public func performAction(
        identifier actionIdentifier: NSFileProviderExtensionActionIdentifier,
        onItemsWithIdentifiers itemIdentifiers: [NSFileProviderItemIdentifier],
        completionHandler: @escaping ((any Error)?) -> Void
    ) -> Progress {
        _ = actionIdentifier
        _ = itemIdentifiers
        let progress = Progress(totalUnitCount: 1)
        FileProviderCallback.queue.async {
            progress.completedUnitCount = 1
            completionHandler(FileProviderHost.unsupported(.applicationExtensionNotFound))
        }
        return progress
    }

    func storedItem(for identifier: NSFileProviderItemIdentifier) throws -> FileProviderStoredItem {
        guard let item = lookup(identifier) else {
            throw NSFileProviderError(
                .noSuchItem,
                userInfo: [NSFileProviderErrorNonExistentItemIdentifierKey: identifier.rawValue]
            )
        }
        return item
    }

    func lookup(_ identifier: NSFileProviderItemIdentifier) -> FileProviderStoredItem? {
        lock.lock()
        let item = items[identifier.rawValue]
        lock.unlock()
        return item
    }

    func itemMatching(filename: String, parent: NSFileProviderItemIdentifier? = nil) -> FileProviderStoredItem? {
        lock.lock()
        let match = items.values.first {
            $0.filename == filename
                && (parent == nil || $0.parentItemIdentifier == parent)
                && !$0.isTrashed
        }
        lock.unlock()
        return match
    }

    func items(
        in container: NSFileProviderItemIdentifier,
        pendingOnly: Bool,
        materializedOnly: Bool
    ) -> [FileProviderStoredItem] {
        lock.lock()
        let values = Array(items.values)
        lock.unlock()
        return values.filter { item in
            if pendingOnly && !item.isUploading { return false }
            if materializedOnly && !item.isDownloaded { return false }
            if container == .workingSet { return true }
            if container == .trashContainer { return item.isTrashed }
            if container == .rootContainer {
                return item.parentItemIdentifier == .rootContainer
                    && item.itemIdentifier != .rootContainer
                    && !item.isTrashed
            }
            return item.parentItemIdentifier == container && !item.isTrashed
        }
    }

    func changeSnapshot(
        from anchor: NSFileProviderSyncAnchor,
        container: NSFileProviderItemIdentifier
    ) -> (updated: [FileProviderStoredItem], deleted: [NSFileProviderItemIdentifier],
        anchor: NSFileProviderSyncAnchor, moreComing: Bool)
    {
        let text = String(data: anchor.rawValue, encoding: .utf8) ?? ""
        if !text.isEmpty && Int64(text) == nil && text != "0" {
            return (
                [],
                [],
                NSFileProviderSyncAnchor(Data(String(generation).utf8)),
                false
            )
        }
        lock.lock()
        let updated = Array(items.values).filter { item in
            if container == .workingSet { return true }
            if container == .trashContainer { return item.isTrashed }
            return item.parentItemIdentifier == container || item.itemIdentifier == container
        }
        let deleted = Array(deletedSince.values)
        let next = NSFileProviderSyncAnchor(Data(String(generation).utf8))
        lock.unlock()
        return (updated, deleted, next, false)
    }

    func evict(_ identifier: NSFileProviderItemIdentifier) throws {
        let item = try storedItem(for: identifier)
        if !item.capabilities.contains(.allowsEvicting)
            && !item.capabilities.contains(.allowsAll)
        {
            throw NSFileProviderError(.nonEvictable)
        }
        let kids = children(of: identifier)
        if !kids.isEmpty {
            throw NSFileProviderError(.nonEvictableChildren)
        }
        if !item.isUploaded || item.isUploading {
            throw NSFileProviderError(.unsyncedEdits)
        }
        if let url = item.contentURL {
            try? FileManager.default.removeItem(at: url)
        }
        item.contentURL = nil
        item.isDownloaded = false
        item.documentSize = 0
        item.bumpVersion()
        saveToDisk()
    }

    func reimport(below identifier: NSFileProviderItemIdentifier) throws {
        _ = try storedItem(for: identifier)
        lock.lock()
        for item in items.values where item.parentItemIdentifier == identifier
            || item.itemIdentifier == identifier
            || identifier == .rootContainer
            || identifier == .workingSet
        {
            item.bumpVersion()
        }
        generation += 1
        lock.unlock()
        saveToDisk()
    }

    func makeTestingOperations() -> [any NSFileProviderTestingOperation] {
        let root = lookup(.rootContainer) ?? FileProviderStoredItem(
            itemIdentifier: .rootContainer,
            parentItemIdentifier: .rootContainer,
            filename: "/"
        )
        return [
            FileProviderTestingLookupOperation(itemIdentifier: .rootContainer, side: .fileProvider),
            FileProviderTestingIngestionOperation(
                item: root,
                itemIdentifier: .rootContainer,
                side: .disk
            ),
            FileProviderTestingCreationOperation(
                domainVersion: domainVersion,
                sourceItem: root,
                targetSide: .fileProvider
            ),
            FileProviderTestingModificationOperation(
                changedFields: [.filename],
                domainVersion: domainVersion,
                sourceItem: root,
                targetItemBaseVersion: root.itemVersion
                    ?? NSFileProviderItemVersion(contentVersion: Data(), metadataVersion: Data()),
                targetItemIdentifier: .rootContainer,
                targetSide: .fileProvider
            ),
            FileProviderTestingDeletionOperation(
                domainVersion: domainVersion,
                sourceItemIdentifier: .rootContainer,
                targetItemBaseVersion: root.itemVersion
                    ?? NSFileProviderItemVersion(contentVersion: Data(), metadataVersion: Data()),
                targetItemIdentifier: .rootContainer,
                targetSide: .fileProvider
            ),
            FileProviderTestingContentFetchOperation(
                itemIdentifier: .rootContainer,
                side: .fileProvider
            ),
            FileProviderTestingChildrenEnumerationOperation(
                itemIdentifier: .rootContainer,
                side: .fileProvider
            ),
            FileProviderTestingCollisionResolutionOperation(
                renamedItem: root,
                side: .fileProvider
            ),
        ]
    }

    private func seedRoot() {
        lock.lock()
        if items[NSFileProviderItemIdentifier.rootContainer.rawValue] == nil {
            let root = FileProviderStoredItem(
                itemIdentifier: .rootContainer,
                parentItemIdentifier: .rootContainer,
                filename: "/"
            )
            root.typeIdentifier = "public.folder"
            root.capabilities = [.allowsReading, .allowsAddingSubItems, .allowsContentEnumerating]
            items[NSFileProviderItemIdentifier.rootContainer.rawValue] = root
        }
        lock.unlock()
    }

    private func apply(
        _ fields: NSFileProviderItemFields,
        from template: NSFileProviderItem,
        onto stored: FileProviderStoredItem
    ) {
        if fields.contains(.filename) { stored.filename = template.filename }
        if fields.contains(.parentItemIdentifier) {
            stored.parentItemIdentifier = template.parentItemIdentifier
        }
        if fields.contains(.lastUsedDate) { stored.lastUsedDate = template.lastUsedDate }
        if fields.contains(.tagData) { stored.tagData = template.tagData }
        if fields.contains(.favoriteRank) { stored.favoriteRank = template.favoriteRank }
        if fields.contains(.creationDate) { stored.creationDate = template.creationDate }
        if fields.contains(.contentModificationDate) {
            stored.contentModificationDate = template.contentModificationDate
        }
        if fields.contains(.fileSystemFlags) { stored.fileSystemFlags = template.fileSystemFlags }
        if fields.contains(.extendedAttributes) {
            stored.extendedAttributes = template.extendedAttributes
        }
        if fields.contains(.typeAndCreator) { stored.typeAndCreator = template.typeAndCreator }
    }

    private func persistContents(_ url: URL, onto stored: FileProviderStoredItem) {
        guard let host else { return }
        let destination = host.providerStorage(for: domain)
            .appendingPathComponent("contents", isDirectory: true)
        try? FileManager.default.createDirectory(at: destination, withIntermediateDirectories: true)
        let target = destination.appendingPathComponent(stored.itemIdentifier.rawValue)
        try? FileManager.default.removeItem(at: target)
        try? FileManager.default.copyItem(at: url, to: target)
        stored.contentURL = target
        if let size = try? FileManager.default.attributesOfItem(atPath: target.path)[.size] as? NSNumber {
            stored.documentSize = size
        }
        let content = stored.itemVersion?.contentVersion ?? Data([0])
        var bytes = Array(content)
        if bytes.isEmpty { bytes = [0] }
        bytes[bytes.count - 1] &+= 1
        stored.itemVersion = NSFileProviderItemVersion(
            contentVersion: Data(bytes),
            metadataVersion: stored.itemVersion?.metadataVersion ?? Data([0])
        )
    }

    private func materializeVisibleCopy(_ stored: FileProviderStoredItem) {
        guard let host, stored.itemIdentifier != .rootContainer else { return }
        let visible = host.mountDirectory(for: domain)
            .appendingPathComponent(stored.filename)
        if let content = stored.contentURL {
            try? FileManager.default.removeItem(at: visible)
            try? FileManager.default.copyItem(at: content, to: visible)
        } else if !FileManager.default.fileExists(atPath: visible.path) {
            _ = FileManager.default.createFile(atPath: visible.path, contents: Data())
        }
    }

    private func children(of identifier: NSFileProviderItemIdentifier) -> [NSFileProviderItemIdentifier] {
        lock.lock()
        let ids = items.values
            .filter { $0.parentItemIdentifier == identifier && $0.itemIdentifier != identifier }
            .map(\.itemIdentifier)
        lock.unlock()
        return ids
    }

    private func subtree(of identifier: NSFileProviderItemIdentifier) -> [NSFileProviderItemIdentifier] {
        var result: [NSFileProviderItemIdentifier] = []
        var queue = children(of: identifier)
        while let next = queue.first {
            queue.removeFirst()
            result.append(next)
            queue.append(contentsOf: children(of: next))
        }
        return result
    }

    private func saveToDisk() {
        guard let host else { return }
        lock.lock()
        let payload: [[String: String]] = items.values.map { item in
            [
                "id": item.itemIdentifier.rawValue,
                "parent": item.parentItemIdentifier.rawValue,
                "filename": item.filename,
            ]
        }
        lock.unlock()
        let url = host.providerStorage(for: domain).appendingPathComponent("items.json")
        if let data = try? JSONSerialization.data(withJSONObject: payload, options: [.sortedKeys]) {
            try? data.write(to: url, options: .atomic)
        }
    }

    private func loadFromDisk() {
        guard let host else { return }
        let url = host.providerStorage(for: domain).appendingPathComponent("items.json")
        guard let data = try? Data(contentsOf: url),
            let payload = try? JSONSerialization.jsonObject(with: data) as? [[String: String]]
        else {
            return
        }
        lock.lock()
        for row in payload {
            guard let id = row["id"], let parent = row["parent"], let filename = row["filename"]
            else {
                continue
            }
            if items[id] == nil {
                items[id] = FileProviderStoredItem(
                    itemIdentifier: NSFileProviderItemIdentifier(id),
                    parentItemIdentifier: NSFileProviderItemIdentifier(parent),
                    filename: filename
                )
            }
        }
        lock.unlock()
        seedRoot()
    }
}
