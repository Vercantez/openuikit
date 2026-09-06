import Foundation

/// Client for the system Thread credentials store.
///
/// Construction is local and succeeds. Every credentials store, retrieve,
/// and delete call fail-closes: Linux has no Thread daemon, Thread radio, or
/// manage-credentials entitlement. Preferred-network queries report `false`
/// inline. Completions run on the caller; async overlays never suspend.
open class THClient: NSObject {
    public override init() {
        super.init()
    }

    open func retrieveAllCredentials(
        _ completion: @escaping (Set<THCredentials>?, (any Error)?) -> Void
    ) {
        completion(nil, threadNetworkUnavailable())
    }

    open func allCredentials() async throws -> Set<THCredentials> {
        try linuxAllCredentials()
    }

    open func retrieveAllActiveCredentials(
        _ completion: @escaping (Set<THCredentials>?, (any Error)?) -> Void
    ) {
        completion(nil, threadNetworkUnavailable())
    }

    open func allActiveCredentials() async throws -> Set<THCredentials> {
        try linuxAllActiveCredentials()
    }

    open func deleteCredentials(
        forBorderAgent borderAgentID: Data,
        completion: @escaping ((any Error)?) -> Void
    ) {
        _ = borderAgentID
        completion(threadNetworkUnavailable())
    }

    open func deleteCredentials(forBorderAgent borderAgentID: Data) async throws {
        try linuxDeleteCredentials(forBorderAgent: borderAgentID)
    }

    open func retrieveCredentials(
        forBorderAgent borderAgentID: Data,
        completion: @escaping (THCredentials?, (any Error)?) -> Void
    ) {
        _ = borderAgentID
        completion(nil, threadNetworkUnavailable())
    }

    open func credentials(forBorderAgentID borderAgentID: Data) async throws -> THCredentials {
        try linuxCredentials(forBorderAgentID: borderAgentID)
    }

    open func storeCredentials(
        forBorderAgent borderAgentID: Data,
        activeOperationalDataSet: Data,
        completion: @escaping ((any Error)?) -> Void
    ) {
        _ = borderAgentID
        _ = activeOperationalDataSet
        completion(threadNetworkUnavailable())
    }

    open func storeCredentials(
        forBorderAgent borderAgentID: Data,
        activeOperationalDataSet: Data
    ) async throws {
        try linuxStoreCredentials(
            forBorderAgent: borderAgentID,
            activeOperationalDataSet: activeOperationalDataSet
        )
    }

    open func retrievePreferredCredentials(
        _ completion: @escaping (THCredentials?, (any Error)?) -> Void
    ) {
        completion(nil, threadNetworkUnavailable())
    }

    open func preferredCredentials() async throws -> THCredentials {
        try linuxPreferredCredentials()
    }

    open func retrieveCredentials(
        forExtendedPANID extendedPANID: Data,
        completion: @escaping (THCredentials?, (any Error)?) -> Void
    ) {
        _ = extendedPANID
        completion(nil, threadNetworkUnavailable())
    }

    open func credentials(forExtendedPANID extendedPANID: Data) async throws -> THCredentials {
        try linuxCredentials(forExtendedPANID: extendedPANID)
    }

    /// Reports whether `activeOperationalDataSet` matches the preferred Thread
    /// network. Linux has no preferred network and invokes `completion` inline
    /// with `false`.
    open func checkPreferredNetwork(
        forActiveOperationalDataset activeOperationalDataSet: Data,
        completion: @escaping (Bool) -> Void
    ) {
        _ = activeOperationalDataSet
        completion(false)
    }

    open func isPreferred(forActiveOperationalDataset activeOperationalDataSet: Data) async -> Bool {
        _ = activeOperationalDataSet
        return linuxIsPreferredAvailable()
    }

    open func isPreferredNetworkAvailable(completion: @escaping (Bool) -> Void) {
        completion(false)
    }

    open func isPreferredAvailable() async -> Bool {
        linuxIsPreferredAvailable()
    }

    func linuxAllCredentials() throws -> Set<THCredentials> {
        try threadNetworkThrowUnavailable()
    }

    func linuxAllActiveCredentials() throws -> Set<THCredentials> {
        try threadNetworkThrowUnavailable()
    }

    func linuxPreferredCredentials() throws -> THCredentials {
        try threadNetworkThrowUnavailable()
    }

    func linuxCredentials(forBorderAgentID borderAgentID: Data) throws -> THCredentials {
        _ = borderAgentID
        try threadNetworkThrowUnavailable()
    }

    func linuxCredentials(forExtendedPANID extendedPANID: Data) throws -> THCredentials {
        _ = extendedPANID
        try threadNetworkThrowUnavailable()
    }

    func linuxStoreCredentials(
        forBorderAgent borderAgentID: Data,
        activeOperationalDataSet: Data
    ) throws {
        _ = borderAgentID
        _ = activeOperationalDataSet
        try threadNetworkThrowUnavailable()
    }

    func linuxDeleteCredentials(forBorderAgent borderAgentID: Data) throws {
        _ = borderAgentID
        try threadNetworkThrowUnavailable()
    }

    func linuxIsPreferredAvailable() -> Bool {
        false
    }
}
