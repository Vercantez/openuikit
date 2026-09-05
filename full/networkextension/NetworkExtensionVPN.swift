@_spi(OpenUIKitHost)
public enum NetworkExtensionHostPreferences {
    public static func resetForHostTesting(rootDirectory: URL? = nil) {
        _NEVPNPreferenceStore.shared.reset(rootDirectory: rootDirectory, wipeDisk: true)
        NEVPNManager.shared().resetForHostTesting()
    }

    public static func reloadPersistedStateForHostTesting() {
        _NEVPNPreferenceStore.shared.reloadFromDisk()
        NEVPNManager.shared().resetForHostTesting()
    }
}

final class _NEVPNPreferenceStore: @unchecked Sendable {
    static let shared = _NEVPNPreferenceStore()

    private let lock = NSLock()
    private var root: URL
    private var personal: _NEVPNPreferenceRecord?
    private var tunnels: [String: _NEVPNPreferenceRecord] = [:]

    private init() {
        root = _NEVPNPreferenceStore.defaultRoot()
        loadFromDiskLocked()
    }

    private static func defaultRoot() -> URL {
        let base = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first
            ?? URL(fileURLWithPath: NSHomeDirectory())
                .appendingPathComponent("Library/Application Support")
        return base.appendingPathComponent("org.openuikit.NetworkExtension", isDirectory: true)
    }

    func reset(rootDirectory: URL?, wipeDisk: Bool) {
        lock.lock()
        defer { lock.unlock() }
        if let rootDirectory {
            root = rootDirectory
        } else {
            root = _NEVPNPreferenceStore.defaultRoot()
        }
        personal = nil
        tunnels = [:]
        if wipeDisk {
            try? FileManager.default.removeItem(at: root)
        }
        loadFromDiskLocked()
    }

    func reloadFromDisk() {
        lock.lock()
        defer { lock.unlock() }
        loadFromDiskLocked()
    }

    func loadPersonal() -> _NEVPNPreferenceRecord? {
        lock.lock()
        defer { lock.unlock() }
        return personal?.copy() as? _NEVPNPreferenceRecord
    }

    func savePersonal(_ record: _NEVPNPreferenceRecord) throws {
        lock.lock()
        defer { lock.unlock() }
        personal = record.copy() as? _NEVPNPreferenceRecord
        try persistLocked()
    }

    func removePersonal() throws {
        lock.lock()
        defer { lock.unlock() }
        personal = nil
        try persistLocked()
    }

    func loadTunnels() -> [_NEVPNPreferenceRecord] {
        lock.lock()
        defer { lock.unlock() }
        return tunnels.values.compactMap { $0.copy() as? _NEVPNPreferenceRecord }
    }

    func saveTunnel(_ record: _NEVPNPreferenceRecord) throws {
        lock.lock()
        defer { lock.unlock() }
        tunnels[record.identifier] = record.copy() as? _NEVPNPreferenceRecord
        try persistLocked()
    }

    func removeTunnel(identifier: String) throws {
        lock.lock()
        defer { lock.unlock() }
        tunnels.removeValue(forKey: identifier)
        try persistLocked()
    }

    private var storeURL: URL {
        root.appendingPathComponent("vpn-preferences.json", isDirectory: false)
    }

    fileprivate static var protocolArchiveClasses: [AnyClass] {
        [
            NEVPNProtocol.self,
            NEVPNProtocolIPSec.self,
            NEVPNProtocolIKEv2.self,
            NETunnelProviderProtocol.self,
            NEDNSProxyProviderProtocol.self,
            NEVPNIKEv2SecurityAssociationParameters.self,
            NEVPNIKEv2PPKConfiguration.self,
            NEProxySettings.self,
            NEProxyServer.self,
            NSArray.self,
            NSDictionary.self,
            NSString.self,
            NSNumber.self,
            NSData.self,
            NSURL.self,
        ]
    }

    fileprivate static var onDemandArchiveClasses: [AnyClass] {
        [
            NSArray.self,
            NEOnDemandRule.self,
            NEOnDemandRuleConnect.self,
            NEOnDemandRuleDisconnect.self,
            NEOnDemandRuleIgnore.self,
            NEOnDemandRuleEvaluateConnection.self,
            NEEvaluateConnectionRule.self,
            NSURL.self,
            NSString.self,
            NSNumber.self,
        ]
    }

    private func loadFromDiskLocked() {
        personal = nil
        tunnels = [:]
        guard FileManager.default.fileExists(atPath: storeURL.path) else { return }
        do {
            let data = try Data(contentsOf: storeURL)
            let snapshot = try JSONDecoder().decode(_NEVPNDiskStore.self, from: data)
            personal = snapshot.personal?.makeRecord()
            tunnels = Dictionary(
                uniqueKeysWithValues: snapshot.tunnels.map { record in
                    let restored = record.makeRecord()
                    return (restored.identifier, restored)
                }
            )
        } catch {
            personal = nil
            tunnels = [:]
        }
    }

    private func persistLocked() throws {
        do {
            try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
            let snapshot = _NEVPNDiskStore(
                personal: try personal.map(_NEVPNDiskRecord.init(record:)),
                tunnels: try tunnels.values.map(_NEVPNDiskRecord.init(record:))
            )
            let data = try JSONEncoder().encode(snapshot)
            try data.write(to: storeURL, options: .atomic)
        } catch {
            throw _NEHostBoundary.vpnError(.configurationReadWriteFailed)
        }
    }
}

private struct _NEVPNDiskStore: Codable {
    var personal: _NEVPNDiskRecord?
    var tunnels: [_NEVPNDiskRecord]
}

private struct _NEVPNDiskRecord: Codable {
    var identifier: String
    var localizedDescription: String?
    var isEnabled: Bool
    var isOnDemandEnabled: Bool
    var protocolData: Data?
    var onDemandData: Data?
    var appRulesData: Data?

    init(record: _NEVPNPreferenceRecord) throws {
        identifier = record.identifier
        localizedDescription = record.localizedDescription
        isEnabled = record.isEnabled
        isOnDemandEnabled = record.isOnDemandEnabled
        if let configuration = record.protocolConfiguration {
            protocolData = try NSKeyedArchiver.archivedData(
                withRootObject: configuration,
                requiringSecureCoding: true
            )
        }
        if let rules = record.onDemandRules {
            onDemandData = try NSKeyedArchiver.archivedData(
                withRootObject: rules as NSArray,
                requiringSecureCoding: true
            )
        }
        if let rules = record.appRules {
            appRulesData = try NSKeyedArchiver.archivedData(
                withRootObject: rules as NSArray,
                requiringSecureCoding: true
            )
        }
    }

    func makeRecord() -> _NEVPNPreferenceRecord {
        let record = _NEVPNPreferenceRecord(identifier: identifier)
        record.localizedDescription = localizedDescription
        record.isEnabled = isEnabled
        record.isOnDemandEnabled = isOnDemandEnabled
        if let protocolData {
            record.protocolConfiguration = try? NSKeyedUnarchiver.unarchivedObject(
                ofClasses: _NEVPNPreferenceStore.protocolArchiveClasses,
                from: protocolData
            ) as? NEVPNProtocol
        }
        if let onDemandData {
            record.onDemandRules = try? NSKeyedUnarchiver.unarchivedObject(
                ofClasses: _NEVPNPreferenceStore.onDemandArchiveClasses,
                from: onDemandData
            ) as? [NEOnDemandRule]
        }
        if let appRulesData {
            record.appRules = try? NSKeyedUnarchiver.unarchivedObject(
                ofClasses: [NSArray.self, NEAppRule.self, NSString.self],
                from: appRulesData
            ) as? [NEAppRule]
        }
        return record
    }
}

final class _NEVPNPreferenceRecord: NSObject, NSCopying, NSSecureCoding {
    static var supportsSecureCoding: Bool { true }

    var identifier: String
    var localizedDescription: String?
    var isEnabled = false
    var isOnDemandEnabled = false
    var onDemandRules: [NEOnDemandRule]?
    var protocolConfiguration: NEVPNProtocol?
    var appRules: [NEAppRule]?

    init(identifier: String = UUID().uuidString) {
        self.identifier = identifier
        super.init()
    }

    required init?(coder: NSCoder) {
        identifier = _NEDecodeString(coder, "identifier") ?? UUID().uuidString
        localizedDescription = _NEDecodeString(coder, "localizedDescription")
        isEnabled = coder.decodeBool(forKey: "isEnabled")
        isOnDemandEnabled = coder.decodeBool(forKey: "isOnDemandEnabled")
        onDemandRules = coder.decodeObject(
            of: [
                NSArray.self,
                NEOnDemandRule.self,
                NEOnDemandRuleConnect.self,
                NEOnDemandRuleDisconnect.self,
                NEOnDemandRuleIgnore.self,
                NEOnDemandRuleEvaluateConnection.self,
            ],
            forKey: "onDemandRules"
        ) as? [NEOnDemandRule]
        protocolConfiguration = coder.decodeObject(
            of: [
                NEVPNProtocol.self,
                NEVPNProtocolIPSec.self,
                NEVPNProtocolIKEv2.self,
                NETunnelProviderProtocol.self,
                NEDNSProxyProviderProtocol.self,
            ],
            forKey: "protocolConfiguration"
        ) as? NEVPNProtocol
        appRules = coder.decodeObject(
            of: [NSArray.self, NEAppRule.self],
            forKey: "appRules"
        ) as? [NEAppRule]
        super.init()
    }

    func encode(with coder: NSCoder) {
        _NEEncodeString(coder, "identifier", identifier)
        _NEEncodeString(coder, "localizedDescription", localizedDescription)
        _NEEncodeBool(coder, "isEnabled", isEnabled)
        _NEEncodeBool(coder, "isOnDemandEnabled", isOnDemandEnabled)
        if let onDemandRules {
            coder.encode(onDemandRules as NSArray, forKey: "onDemandRules")
        }
        _NEEncodeObject(coder, "protocolConfiguration", protocolConfiguration)
        if let appRules {
            coder.encode(appRules as NSArray, forKey: "appRules")
        }
    }

    func copy(with zone: NSZone? = nil) -> Any {
        _ = zone
        let copy = _NEVPNPreferenceRecord(identifier: identifier)
        copy.localizedDescription = localizedDescription
        copy.isEnabled = isEnabled
        copy.isOnDemandEnabled = isOnDemandEnabled
        copy.onDemandRules = _NECopiedArray(onDemandRules)
        copy.protocolConfiguration = _NECopiedObject(protocolConfiguration)
        copy.appRules = _NECopiedArray(appRules)
        return copy
    }

    func apply(to manager: NEVPNManager) {
        manager.localizedDescription = localizedDescription
        manager.isEnabled = isEnabled
        manager.isOnDemandEnabled = isOnDemandEnabled
        manager.onDemandRules = _NECopiedArray(onDemandRules)
        manager.protocolConfiguration = _NECopiedObject(protocolConfiguration)
        if let tunnel = manager as? NETunnelProviderManager {
            tunnel.replaceAppRulesForHostTesting(_NECopiedArray(appRules))
        }
    }

    static func capture(from manager: NEVPNManager, identifier: String) -> _NEVPNPreferenceRecord {
        let record = _NEVPNPreferenceRecord(identifier: identifier)
        record.localizedDescription = manager.localizedDescription
        record.isEnabled = manager.isEnabled
        record.isOnDemandEnabled = manager.isOnDemandEnabled
        record.onDemandRules = _NECopiedArray(manager.onDemandRules)
        record.protocolConfiguration = _NECopiedObject(manager.protocolConfiguration)
        if let tunnel = manager as? NETunnelProviderManager {
            record.appRules = tunnel.copyAppRules()
        }
        return record
    }
}

open class NEVPNConnection: NSObject {
    private unowned let _manager: NEVPNManager
    private let lock = NSLock()
    private var _status: NEVPNStatus = .invalid
    private var _connectedDate: Date?
    private var lastDisconnectError: (any Error)?

    init(manager: NEVPNManager) {
        _manager = manager
        super.init()
    }

    open var manager: NEVPNManager { _manager }

    open var status: NEVPNStatus {
        lock.lock()
        defer { lock.unlock() }
        return _status
    }

    open var connectedDate: Date? {
        lock.lock()
        defer { lock.unlock() }
        return _connectedDate
    }

    func resetStatusForHostTesting() {
        lock.lock()
        _status = .invalid
        _connectedDate = nil
        lastDisconnectError = nil
        lock.unlock()
    }

    func setDisconnectedAfterLoad() {
        applyStatus(.disconnected, connectedDate: nil, disconnectError: nil)
    }

    func setInvalidAfterRemove() {
        applyStatus(.invalid, connectedDate: nil, disconnectError: nil)
    }

    open func startVPNTunnel() throws {
        try startVPNTunnel(options: nil)
    }

    open func startVPNTunnel(options: [String: NSObject]? = nil) throws {
        _ = options
        try _manager.prepareSimulatedTunnelStart()
        applyStatus(.connecting, connectedDate: nil, disconnectError: nil)
        applyStatus(.connected, connectedDate: Date(), disconnectError: nil)
    }

    open func stopVPNTunnel() {
        let current = status
        guard current == .connected || current == .connecting || current == .reasserting else {
            return
        }
        applyStatus(.disconnecting, connectedDate: connectedDate, disconnectError: nil)
        applyStatus(
            .disconnected,
            connectedDate: nil,
            disconnectError: _NEHostBoundary.vpnError(.connectionFailed)
        )
    }

    open func fetchLastDisconnectError(
        completionHandler handler: @escaping ((any Error)?) -> Void
    ) {
        lock.lock()
        let error = lastDisconnectError
        lock.unlock()
        _NEOnceDelivery(handler).schedule(error)
    }

    private func applyStatus(
        _ status: NEVPNStatus,
        connectedDate: Date?,
        disconnectError: (any Error)?
    ) {
        lock.lock()
        _status = status
        _connectedDate = connectedDate
        if disconnectError != nil {
            lastDisconnectError = disconnectError
        }
        lock.unlock()
        NotificationCenter.default.post(
            name: .NEVPNStatusDidChange,
            object: self
        )
    }
}

open class NETunnelProviderSession: NEVPNConnection {
    open func startTunnel(options: [String: Any]? = nil) throws {
        _ = options
        throw _NEHostBoundary.vpnError(.connectionFailed)
    }

    open override func startVPNTunnel(options: [String: NSObject]? = nil) throws {
        _ = options
        throw _NEHostBoundary.vpnError(.connectionFailed)
    }

    open func stopTunnel() {
        stopVPNTunnel()
    }

    open func sendProviderMessage(
        _ messageData: Data,
        responseHandler: ((Data?) -> Void)? = nil
    ) throws {
        _ = (messageData, responseHandler)
        throw _NEHostBoundary.vpnError(.configurationInvalid)
    }
}

open class NEVPNManager: NSObject {
    private static let _shared = NEVPNManager()
    private var _connection: NEVPNConnection!
    private let stateLock = NSLock()
    private var _preferencesLoaded = false
    private var _preferencesSaved = false
    var preferenceIdentifier = "personal"

    open class func shared() -> NEVPNManager { _shared }

    public override init() {
        super.init()
        _connection = NEVPNConnection(manager: self)
    }

    fileprivate func installConnection(_ connection: NEVPNConnection) {
        _connection = connection
    }

    open var connection: NEVPNConnection { _connection }
    open var isEnabled = false
    open var localizedDescription: String?
    open var isOnDemandEnabled = false
    open var onDemandRules: [NEOnDemandRule]?
    open var protocolConfiguration: NEVPNProtocol?

    open var `protocol`: NEVPNProtocol? {
        get { protocolConfiguration }
        set { protocolConfiguration = newValue }
    }

    var isPreferencesLoaded: Bool {
        stateLock.lock()
        defer { stateLock.unlock() }
        return _preferencesLoaded
    }

    var isPreferencesSaved: Bool {
        stateLock.lock()
        defer { stateLock.unlock() }
        return _preferencesSaved
    }

    func resetForHostTesting() {
        stateLock.lock()
        _preferencesLoaded = false
        _preferencesSaved = false
        stateLock.unlock()
        localizedDescription = nil
        isEnabled = false
        isOnDemandEnabled = false
        onDemandRules = nil
        protocolConfiguration = nil
        connection.resetStatusForHostTesting()
    }

    func prepareSimulatedTunnelStart() throws {
        guard isPreferencesSaved else {
            throw _NEHostBoundary.vpnError(.configurationInvalid)
        }
        guard isEnabled else {
            throw _NEHostBoundary.vpnError(.configurationDisabled)
        }
        guard
            let configuration = protocolConfiguration,
            let address = configuration.serverAddress,
            !address.isEmpty
        else {
            throw _NEHostBoundary.vpnError(.configurationInvalid)
        }
    }

    private func markLoaded(_ saved: Bool) {
        stateLock.lock()
        _preferencesLoaded = true
        _preferencesSaved = saved
        stateLock.unlock()
    }

    func validateForSave() throws {
        guard isPreferencesLoaded else {
            throw _NEHostBoundary.vpnError(.configurationStale)
        }
        guard
            let configuration = protocolConfiguration,
            let address = configuration.serverAddress,
            !address.isEmpty
        else {
            throw _NEHostBoundary.vpnError(.configurationInvalid)
        }
    }

    open func loadFromPreferences(
        completionHandler: @escaping ((any Error)?) -> Void
    ) {
        do {
            try applyLoadedRecord(_NEVPNPreferenceStore.shared.loadPersonal())
            _NEHostBoundary.completeNilError(completionHandler)
        } catch {
            _NEHostBoundary.complete(completionHandler, error)
        }
    }

    func applyLoadedRecord(_ record: _NEVPNPreferenceRecord?) throws {
        if let record {
            record.apply(to: self)
            markLoaded(true)
            connection.setDisconnectedAfterLoad()
        } else {
            localizedDescription = nil
            isEnabled = false
            isOnDemandEnabled = false
            onDemandRules = nil
            protocolConfiguration = nil
            markLoaded(false)
            connection.setInvalidAfterRemove()
            stateLock.lock()
            _preferencesLoaded = true
            _preferencesSaved = false
            stateLock.unlock()
        }
        postConfigurationChange()
    }

    open func saveToPreferences(
        completionHandler: (((any Error)?) -> Void)? = nil
    ) {
        do {
            try validateForSave()
            let record = _NEVPNPreferenceRecord.capture(from: self, identifier: preferenceIdentifier)
            try persistRecord(record)
            markLoaded(true)
            if connection.status == .invalid {
                connection.setDisconnectedAfterLoad()
            }
            postConfigurationChange()
            _NEHostBoundary.completeOptionalNil(completionHandler)
        } catch {
            _NEHostBoundary.completeOptional(completionHandler, error)
        }
    }

    func persistRecord(_ record: _NEVPNPreferenceRecord) throws {
        try _NEVPNPreferenceStore.shared.savePersonal(record)
    }

    open func removeFromPreferences(
        completionHandler: (((any Error)?) -> Void)? = nil
    ) {
        do {
            try deletePersistedRecord()
            localizedDescription = nil
            isEnabled = false
            isOnDemandEnabled = false
            onDemandRules = nil
            protocolConfiguration = nil
            markLoaded(true)
            stateLock.lock()
            _preferencesSaved = false
            stateLock.unlock()
            connection.setInvalidAfterRemove()
            postConfigurationChange()
            _NEHostBoundary.completeOptionalNil(completionHandler)
        } catch {
            _NEHostBoundary.completeOptional(completionHandler, error)
        }
    }

    func deletePersistedRecord() throws {
        try _NEVPNPreferenceStore.shared.removePersonal()
    }

    private func postConfigurationChange() {
        let manager = self
        NetworkExtensionHostCallback.schedule {
            NotificationCenter.default.post(
                name: .NEVPNConfigurationChange,
                object: manager
            )
        }
    }
}

open class NETunnelProviderManager: NEVPNManager {
    private var _appRules: [NEAppRule]?

    public override init() {
        super.init()
        preferenceIdentifier = UUID().uuidString
        installConnection(NETunnelProviderSession(manager: self))
    }

    open var routingMethod: NETunnelProviderRoutingMethod { .destinationIP }

    open override func loadFromPreferences(
        completionHandler: @escaping ((any Error)?) -> Void
    ) {
        let record = _NEVPNPreferenceStore.shared.loadTunnels().first {
            $0.identifier == preferenceIdentifier
        }
        do {
            try applyLoadedRecord(record)
            _NEHostBoundary.completeNilError(completionHandler)
        } catch {
            _NEHostBoundary.complete(completionHandler, error)
        }
    }

    @_spi(OpenUIKitHost)
    public func replaceAppRulesForHostTesting(_ rules: [NEAppRule]?) {
        _appRules = _NECopiedArray(rules)
    }

    open class func loadAllFromPreferences(
        completionHandler: @escaping ([NETunnelProviderManager]?, (any Error)?) -> Void
    ) {
        let managers: [NETunnelProviderManager] = _NEVPNPreferenceStore.shared.loadTunnels().map {
            record in
            let manager = NETunnelProviderManager()
            manager.preferenceIdentifier = record.identifier
            try? manager.applyLoadedRecord(record)
            return manager
        }
        _NEOnceDelivery { (pair: ([NETunnelProviderManager]?, (any Error)?)) in
            completionHandler(pair.0, pair.1)
        }.schedule((managers, nil))
    }

    open func copyAppRules() -> [NEAppRule]? {
        _NECopiedArray(_appRules)
    }

    override func persistRecord(_ record: _NEVPNPreferenceRecord) throws {
        try _NEVPNPreferenceStore.shared.saveTunnel(record)
    }

    override func deletePersistedRecord() throws {
        try _NEVPNPreferenceStore.shared.removeTunnel(identifier: preferenceIdentifier)
    }

    override func applyLoadedRecord(_ record: _NEVPNPreferenceRecord?) throws {
        try super.applyLoadedRecord(record)
        if let record {
            _appRules = _NECopiedArray(record.appRules)
        } else {
            _appRules = nil
        }
    }
}

open class NEAppProxyProviderManager: NETunnelProviderManager {
    open class func loadAllFromPreferences(
        completionHandler: @escaping ([NEAppProxyProviderManager]?, (any Error)?) -> Void
    ) {
        NETunnelProviderManager.loadAllFromPreferences { managers, error in
            let typed = managers?.compactMap { $0 as? NEAppProxyProviderManager }
            completionHandler(typed ?? [], error)
        }
    }
}

open class NEDNSSettingsManager: NSObject {
    private static let _shared = NEDNSSettingsManager()

    open class func shared() -> NEDNSSettingsManager { _shared }

    open var dnsSettings: NEDNSSettings?
    open var isEnabled: Bool { false }
    open var localizedDescription: String?
    open var onDemandRules: [NEOnDemandRule]?

    open func loadFromPreferences(
        completionHandler: @escaping ((any Error)?) -> Void
    ) {
        _NEHostBoundary.complete(
            completionHandler,
            _NEHostBoundary.nsError(
                domain: NEDNSSettingsErrorDomain,
                code: NEDNSSettingsManagerError.configurationInvalid.rawValue
            )
        )
    }

    open func saveToPreferences(
        completionHandler: @escaping ((any Error)?) -> Void
    ) {
        _NEHostBoundary.complete(
            completionHandler,
            _NEHostBoundary.nsError(
                domain: NEDNSSettingsErrorDomain,
                code: NEDNSSettingsManagerError.configurationInvalid.rawValue
            )
        )
    }

    open func removeFromPreferences(
        completionHandler: @escaping ((any Error)?) -> Void
    ) {
        _NEHostBoundary.complete(
            completionHandler,
            _NEHostBoundary.nsError(
                domain: NEDNSSettingsErrorDomain,
                code: NEDNSSettingsManagerError.configurationCannotBeRemoved.rawValue
            )
        )
    }
}

open class NEDNSProxyManager: NSObject {
    private static let _shared = NEDNSProxyManager()

    open class func shared() -> NEDNSProxyManager { _shared }

    open var isEnabled = false
    open var localizedDescription: String?
    open var providerProtocol: NEDNSProxyProviderProtocol?

    open func loadFromPreferences(
        completionHandler: @escaping ((any Error)?) -> Void
    ) {
        _NEHostBoundary.complete(
            completionHandler,
            _NEHostBoundary.nsError(
                domain: NEDNSProxyErrorDomain,
                code: NEDNSProxyManagerError.configurationInvalid.rawValue
            )
        )
    }

    open func saveToPreferences(
        completionHandler: @escaping ((any Error)?) -> Void
    ) {
        _NEHostBoundary.complete(
            completionHandler,
            _NEHostBoundary.nsError(
                domain: NEDNSProxyErrorDomain,
                code: NEDNSProxyManagerError.configurationInvalid.rawValue
            )
        )
    }

    open func removeFromPreferences(
        completionHandler: @escaping ((any Error)?) -> Void
    ) {
        _NEHostBoundary.complete(
            completionHandler,
            _NEHostBoundary.nsError(
                domain: NEDNSProxyErrorDomain,
                code: NEDNSProxyManagerError.configurationCannotBeRemoved.rawValue
            )
        )
    }
}

open class NERelay: NSObject, NSCopying {
    open var http2RelayURL: URL?
    open var http3RelayURL: URL?
    open var additionalHTTPHeaderFields: [String: String] = [:]
    open var dnsOverHTTPSURL: URL?
    open var identityData: Data?
    open var identityDataPassword: String?
    open var rawPublicKeys: [Data]?
    open var syntheticDNSAnswerIPv4Prefix: String?
    open var syntheticDNSAnswerIPv6Prefix: String?

    open func copy(with zone: NSZone? = nil) -> Any {
        _ = zone
        let copy = NERelay()
        copy.http2RelayURL = http2RelayURL
        copy.http3RelayURL = http3RelayURL
        copy.additionalHTTPHeaderFields = additionalHTTPHeaderFields
        copy.dnsOverHTTPSURL = dnsOverHTTPSURL
        copy.identityData = identityData
        copy.identityDataPassword = identityDataPassword
        copy.rawPublicKeys = rawPublicKeys
        copy.syntheticDNSAnswerIPv4Prefix = syntheticDNSAnswerIPv4Prefix
        copy.syntheticDNSAnswerIPv6Prefix = syntheticDNSAnswerIPv6Prefix
        return copy
    }
}

open class NERelayManager: NSObject {
    private static let _shared = NERelayManager()

    open class func shared() -> NERelayManager { _shared }

    open var isUIToggleEnabled = false
    open var isDNSFailoverAllowed = false
    open var isEnabled = false
    open var excludedDomains: [String]?
    open var excludedFQDNs: [String]?
    open var localizedDescription: String?
    open var matchDomains: [String]?
    open var matchFQDNs: [String]?
    open var onDemandRules: [NEOnDemandRule]?
    open var relays: [NERelay]?

    open class func loadAllManagersFromPreferences(
        completionHandler: @escaping ([NERelayManager], (any Error)?) -> Void
    ) {
        _NEOnceDelivery { (pair: ([NERelayManager], (any Error)?)) in
            completionHandler(pair.0, pair.1)
        }.schedule(
            (
                [],
                _NEHostBoundary.nsError(
                    domain: NERelayErrorDomain,
                    code: NERelayManagerError.configurationInvalid.rawValue
                )
            )
        )
    }

    open func loadFromPreferences(
        completionHandler: @escaping ((any Error)?) -> Void
    ) {
        _NEHostBoundary.complete(
            completionHandler,
            _NEHostBoundary.nsError(
                domain: NERelayErrorDomain,
                code: NERelayManagerError.configurationInvalid.rawValue
            )
        )
    }

    open func saveToPreferences(
        completionHandler: @escaping ((any Error)?) -> Void
    ) {
        _NEHostBoundary.complete(
            completionHandler,
            _NEHostBoundary.nsError(
                domain: NERelayErrorDomain,
                code: NERelayManagerError.configurationInvalid.rawValue
            )
        )
    }

    open func removeFromPreferences(
        completionHandler: @escaping ((any Error)?) -> Void
    ) {
        _NEHostBoundary.complete(
            completionHandler,
            _NEHostBoundary.nsError(
                domain: NERelayErrorDomain,
                code: NERelayManagerError.configurationCannotBeRemoved.rawValue
            )
        )
    }

    open func getLastClientErrors(
        _ seconds: TimeInterval,
        completionHandler: @escaping ([any Error]?) -> Void
    ) {
        _ = seconds
        _NEOnceDelivery(completionHandler).schedule(nil)
    }
}
