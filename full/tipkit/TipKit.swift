@_exported import Foundation

/// Linux starting point for Apple's public `TipKit` module.
///
/// The Foundation event, rule, parameter, and configuration engine is real.
/// `datastoreLocation(.applicationDefault)` writes JSON under Application
/// Support/TipKit. CloudKit options are recorded and never synchronized.
/// SwiftUI `Text`/`Image`/`View` members and UIKit rendering stay gated;
/// `TipView` / `TipUI*` exist as configuration models only.
@frozen public enum Tips {}

enum TipsTime {
    private static let lock = NSLock()
    private static var override: Date?

    static var now: Date {
        lock.lock()
        defer { lock.unlock() }
        return override ?? Date()
    }

    static func setNow(_ date: Date?) {
        lock.lock()
        override = date
        lock.unlock()
    }
}

enum TipsStore {
    static let shared = Storage()

    struct DiskDonation: Codable {
        var date: TimeInterval
        var payload: Data
    }

    struct DiskState: Codable {
        var donations: [String: [DiskDonation]]
        var invalidations: [String: String]
        var displayCounts: [String: Int]
        var parameters: [String: Data]
        var lastDisplayEpoch: TimeInterval?
    }

    final class Storage: @unchecked Sendable {
        let completionQueue = DispatchQueue(label: "TipKit.Tips.completion")
        private let lock = NSLock()
        private var configured = false
        private var displayFrequency: Tips.ConfigurationOption.DisplayFrequency?
        private var requestedDatastore: Tips.ConfigurationOption.DatastoreLocation?
        private var requestedCloudKit: Tips.ConfigurationOption.CloudKitContainer??
        private var storeURL: URL?
        private var applicationSupportRootOverride: URL?
        private var hideAllForTesting = false
        private var showAllForTesting = false
        private var hiddenTypeKeys: Set<String> = []
        private var shownTypeKeys: Set<String> = []
        private var donations: [String: [StoredDonation]] = [:]
        private var invalidations: [String: Tips.InvalidationReason] = [:]
        private var displayCounts: [String: Int] = [:]
        private var parameters: [String: Data] = [:]
        private var transientParameters: [String: Data] = [:]
        private var lastDisplayDate: Date?
        private var statusListeners: [UUID: () -> Void] = [:]

        struct StoredDonation: Sendable {
            var date: Date
            var payload: Data
        }

        func configure(_ configuration: [Tips.ConfigurationOption]) throws {
            lock.lock()
            if configured {
                lock.unlock()
                throw TipKitError.tipsDatastoreAlreadyConfigured
            }
            var location: Tips.ConfigurationOption.DatastoreLocation = .applicationDefault
            for option in configuration {
                switch option.payload {
                case .datastore(let requested):
                    location = requested
                    requestedDatastore = requested
                case .frequency(let frequency):
                    displayFrequency = frequency
                case .cloudKit(let container):
                    requestedCloudKit = container
                }
            }
            if requestedDatastore == nil {
                requestedDatastore = location
            }
            let url = resolveStoreURLLocked(location)
            storeURL = url
            configured = true
            lock.unlock()
            loadFromDisk(url)
            flushToDisk()
        }

        func resetDatastore() throws {
            let listeners: [() -> Void]
            lock.lock()
            donations.removeAll()
            invalidations.removeAll()
            displayCounts.removeAll()
            parameters.removeAll()
            transientParameters.removeAll()
            lastDisplayDate = nil
            listeners = Array(statusListeners.values)
            lock.unlock()
            flushToDisk()
            listeners.forEach { $0() }
        }

        func resetEverythingForHost() {
            lock.lock()
            configured = false
            displayFrequency = nil
            requestedDatastore = nil
            requestedCloudKit = nil
            storeURL = nil
            hideAllForTesting = false
            showAllForTesting = false
            hiddenTypeKeys.removeAll()
            shownTypeKeys.removeAll()
            donations.removeAll()
            invalidations.removeAll()
            displayCounts.removeAll()
            parameters.removeAll()
            transientParameters.removeAll()
            lastDisplayDate = nil
            let listeners = Array(statusListeners.values)
            let isolatedRoot = FileManager.default.temporaryDirectory
                .appendingPathComponent(
                    "tipkit-host-as-\(UUID().uuidString)",
                    isDirectory: true
                )
            applicationSupportRootOverride = isolatedRoot
            lock.unlock()
            TipsTime.setNow(nil)
            listeners.forEach { $0() }
        }

        func setApplicationSupportRootForHost(_ url: URL?) {
            lock.lock()
            applicationSupportRootOverride = url
            lock.unlock()
        }

        func setHideAllForTesting() {
            lock.lock()
            hideAllForTesting = true
            showAllForTesting = false
            let listeners = Array(statusListeners.values)
            lock.unlock()
            listeners.forEach { $0() }
        }

        func setShowAllForTesting() {
            lock.lock()
            showAllForTesting = true
            hideAllForTesting = false
            let listeners = Array(statusListeners.values)
            lock.unlock()
            listeners.forEach { $0() }
        }

        func hideTipsForTesting(_ typeKeys: [String]) {
            lock.lock()
            for key in typeKeys {
                hiddenTypeKeys.insert(key)
                shownTypeKeys.remove(key)
            }
            let listeners = Array(statusListeners.values)
            lock.unlock()
            listeners.forEach { $0() }
        }

        func showTipsForTesting(_ typeKeys: [String]) {
            lock.lock()
            for key in typeKeys {
                shownTypeKeys.insert(key)
                hiddenTypeKeys.remove(key)
            }
            let listeners = Array(statusListeners.values)
            lock.unlock()
            listeners.forEach { $0() }
        }

        func testingFlags() -> (hideAll: Bool, showAll: Bool) {
            lock.lock()
            defer { lock.unlock() }
            return (hideAllForTesting, showAllForTesting)
        }

        func snapshotConfig() -> (
            configured: Bool,
            frequency: Tips.ConfigurationOption.DisplayFrequency?,
            datastore: Tips.ConfigurationOption.DatastoreLocation?,
            cloudKit: Tips.ConfigurationOption.CloudKitContainer??
        ) {
            lock.lock()
            defer { lock.unlock() }
            return (configured, displayFrequency, requestedDatastore, requestedCloudKit)
        }

        func datastoreFileURL() -> URL? {
            lock.lock()
            defer { lock.unlock() }
            return storeURL
        }

        func lastDisplayDateValue() -> Date? {
            lock.lock()
            defer { lock.unlock() }
            return lastDisplayDate
        }

        func cloudKitSyncEnabled() -> Bool {
            false
        }

        func appendDonation(
            eventID: String,
            date: Date,
            payload: Data,
            limit: Tips.DonationLimit
        ) {
            lock.lock()
            var list = donations[eventID, default: []]
            list.append(StoredDonation(date: date, payload: payload))
            if let maximumAge = limit.maximumAge {
                let cutoff = date.addingTimeInterval(-maximumAge.hostSeconds)
                list.removeAll { $0.date < cutoff }
            }
            if list.count > limit.maximumCount {
                list.removeFirst(list.count - limit.maximumCount)
            }
            donations[eventID] = list
            lock.unlock()
            flushToDisk()
        }

        func loadDonations(eventID: String) -> [StoredDonation] {
            lock.lock()
            defer { lock.unlock() }
            return donations[eventID, default: []]
        }

        func deleteDonations(eventID: String) {
            lock.lock()
            donations[eventID] = []
            lock.unlock()
            flushToDisk()
        }

        func invalidate(id: String, reason: Tips.InvalidationReason) {
            lock.lock()
            invalidations[id] = reason
            let listeners = Array(statusListeners.values)
            lock.unlock()
            flushToDisk()
            listeners.forEach { $0() }
        }

        func resetEligibility(id: String) {
            lock.lock()
            invalidations[id] = nil
            displayCounts[id] = 0
            let listeners = Array(statusListeners.values)
            lock.unlock()
            flushToDisk()
            listeners.forEach { $0() }
        }

        func recordDisplay(id: String, maxDisplayCount: Int?) {
            lock.lock()
            let next = displayCounts[id, default: 0] + 1
            displayCounts[id] = next
            lastDisplayDate = TipsTime.now
            var didInvalidate = false
            if let maxDisplayCount, next >= maxDisplayCount {
                invalidations[id] = .displayCountExceeded
                didInvalidate = true
            }
            let listeners = Array(statusListeners.values)
            lock.unlock()
            flushToDisk()
            if didInvalidate || !listeners.isEmpty {
                listeners.forEach { $0() }
            }
        }

        func loadParameter(id: String, transient: Bool) -> Data? {
            lock.lock()
            defer { lock.unlock() }
            if transient {
                return transientParameters[id]
            }
            return parameters[id]
        }

        func storeParameter(id: String, payload: Data, transient: Bool) {
            lock.lock()
            if transient {
                transientParameters[id] = payload
                lock.unlock()
                return
            }
            parameters[id] = payload
            lock.unlock()
            flushToDisk()
        }

        func status(
            id: String,
            typeKey: String,
            rules: [Tips.Rule]
        ) -> Tips.Status {
            lock.lock()
            if let reason = invalidations[id] {
                let forceAvailable = showAllForTesting || shownTypeKeys.contains(typeKey)
                lock.unlock()
                return forceAvailable ? .available : .invalidated(reason)
            }
            if showAllForTesting || shownTypeKeys.contains(typeKey) {
                lock.unlock()
                return .available
            }
            lock.unlock()
            let rulesPass = rules.allSatisfy { $0.evaluate() }
            return rulesPass ? .available : .pending
        }

        func shouldDisplay(
            id: String,
            typeKey: String,
            rules: [Tips.Rule],
            options: [any TipOption]
        ) -> Bool {
            lock.lock()
            let hideAll = hideAllForTesting
            let hidden = hiddenTypeKeys.contains(typeKey)
            let showAll = showAllForTesting
            let shown = shownTypeKeys.contains(typeKey)
            let frequency = displayFrequency
            let lastDisplay = lastDisplayDate
            lock.unlock()
            if hideAll || hidden {
                return false
            }
            if showAll || shown {
                return true
            }
            let resolved = status(id: id, typeKey: typeKey, rules: rules)
            guard case .available = resolved else {
                return false
            }
            let ignores = options.contains { option in
                (option as? Tips.IgnoresDisplayFrequency)?.ignoresDisplayFrequency == true
            }
            if ignores {
                return true
            }
            guard let seconds = frequency?.hostSeconds, let lastDisplay else {
                return true
            }
            return TipsTime.now.timeIntervalSince(lastDisplay) >= seconds
        }

        func addStatusListener(_ body: @escaping () -> Void) -> UUID {
            let token = UUID()
            lock.lock()
            statusListeners[token] = body
            lock.unlock()
            return token
        }

        func removeStatusListener(_ token: UUID) {
            lock.lock()
            statusListeners[token] = nil
            lock.unlock()
        }

        private func resolveStoreURLLocked(
            _ location: Tips.ConfigurationOption.DatastoreLocation
        ) -> URL {
            switch location.kind {
            case .applicationDefault:
                let root = applicationSupportRootOverride
                    ?? FileManager.default.urls(
                        for: .applicationSupportDirectory,
                        in: .userDomainMask
                    ).first
                    ?? FileManager.default.temporaryDirectory
                return root
                    .appendingPathComponent("TipKit", isDirectory: true)
                    .appendingPathComponent("datastore.json", isDirectory: false)
            case .url(let url):
                if url.hasDirectoryPath {
                    return url.appendingPathComponent("datastore.json", isDirectory: false)
                }
                return url
            }
        }

        private func loadFromDisk(_ url: URL) {
            let data: Data
            do {
                data = try Data(contentsOf: url)
            } catch {
                return
            }
            guard let state = try? JSONDecoder().decode(DiskState.self, from: data) else {
                return
            }
            lock.lock()
            donations = state.donations.mapValues { rows in
                rows.map {
                    StoredDonation(
                        date: Date(timeIntervalSince1970: $0.date),
                        payload: $0.payload
                    )
                }
            }
            invalidations = state.invalidations.compactMapValues(Tips.InvalidationReason.init(storeKey:))
            displayCounts = state.displayCounts
            parameters = state.parameters
            if let epoch = state.lastDisplayEpoch {
                lastDisplayDate = Date(timeIntervalSince1970: epoch)
            } else {
                lastDisplayDate = nil
            }
            lock.unlock()
        }

        private func flushToDisk() {
            lock.lock()
            guard let url = storeURL else {
                lock.unlock()
                return
            }
            let state = DiskState(
                donations: donations.mapValues { rows in
                    rows.map {
                        DiskDonation(date: $0.date.timeIntervalSince1970, payload: $0.payload)
                    }
                },
                invalidations: invalidations.mapValues(\.storeKey),
                displayCounts: displayCounts,
                parameters: parameters,
                lastDisplayEpoch: lastDisplayDate?.timeIntervalSince1970
            )
            lock.unlock()
            let directory = url.deletingLastPathComponent()
            try? FileManager.default.createDirectory(
                at: directory,
                withIntermediateDirectories: true
            )
            guard let data = try? JSONEncoder().encode(state) else {
                return
            }
            try? data.write(to: url, options: .atomic)
        }
    }
}

extension Tips.InvalidationReason {
    var storeKey: String {
        switch self {
        case .actionPerformed: return "actionPerformed"
        case .displayCountExceeded: return "displayCountExceeded"
        case .displayDurationExceeded: return "displayDurationExceeded"
        case .tipClosed: return "tipClosed"
        }
    }

    init?(storeKey: String) {
        switch storeKey {
        case "actionPerformed": self = .actionPerformed
        case "displayCountExceeded": self = .displayCountExceeded
        case "displayDurationExceeded": self = .displayDurationExceeded
        case "tipClosed": self = .tipClosed
        default: return nil
        }
    }
}

extension Tips {
    /// Configures the Linux tip store once per process.
    ///
    /// `datastoreLocation(.applicationDefault)` creates a JSON store under
    /// Application Support/TipKit. `datastoreLocation(.url)` writes that file.
    /// `cloudKitContainer` is recorded and never synchronized. A second call
    /// throws `TipKitError.tipsDatastoreAlreadyConfigured`.
    public static func configure(
        _ configuration: [Tips.ConfigurationOption] = []
    ) throws {
        try TipsStore.shared.configure(configuration)
    }

    public static func resetDatastore() throws {
        try TipsStore.shared.resetDatastore()
    }

    public static func hideAllTipsForTesting() {
        TipsStore.shared.setHideAllForTesting()
    }

    public static func showAllTipsForTesting() {
        TipsStore.shared.setShowAllForTesting()
    }

    public static func hideTipsForTesting(_ tips: [any Tip.Type]) {
        TipsStore.shared.hideTipsForTesting(tips.map { String(describing: $0) })
    }

    public static func showTipsForTesting(_ tips: [any Tip.Type]) {
        TipsStore.shared.showTipsForTesting(tips.map { String(describing: $0) })
    }
}

@_spi(OpenUIKitHost)
public enum TipsHostControl {
    public static var completionQueue: DispatchQueue {
        TipsStore.shared.completionQueue
    }

    public static func resetForHostTests() {
        TipsStore.shared.resetEverythingForHost()
    }

    public static func testingFlags() -> (hideAll: Bool, showAll: Bool) {
        TipsStore.shared.testingFlags()
    }

    public static func snapshotConfig() -> (
        configured: Bool,
        frequency: Tips.ConfigurationOption.DisplayFrequency?,
        datastore: Tips.ConfigurationOption.DatastoreLocation?,
        cloudKit: Tips.ConfigurationOption.CloudKitContainer??
    ) {
        TipsStore.shared.snapshotConfig()
    }

    public static func datastoreFileURL() -> URL? {
        TipsStore.shared.datastoreFileURL()
    }

    public static func lastDisplayDate() -> Date? {
        TipsStore.shared.lastDisplayDateValue()
    }

    public static func cloudKitSyncEnabled() -> Bool {
        TipsStore.shared.cloudKitSyncEnabled()
    }

    public static func setApplicationSupportRootForHost(_ url: URL?) {
        TipsStore.shared.setApplicationSupportRootForHost(url)
    }

    public static func setNow(_ date: Date) {
        TipsTime.setNow(date)
    }

    public static func resetClock() {
        TipsTime.setNow(nil)
    }

    /// Occupies the donation-completion queue until `release` so later `async`
    /// completions cannot run. `occupy` returns only after the blocker is running.
    public static func occupyCompletionQueue(_ body: @escaping () -> Void) -> () -> Void {
        let occupied = DispatchSemaphore(value: 0)
        let hold = DispatchSemaphore(value: 0)
        completionQueue.async {
            occupied.signal()
            hold.wait()
            body()
        }
        occupied.wait()
        return { hold.signal() }
    }
}
