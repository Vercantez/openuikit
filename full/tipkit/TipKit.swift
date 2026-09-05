@_exported import Foundation

/// Linux starting point for Apple's public `TipKit` module.
///
/// The Foundation-only event, rule-status, and configuration engine is real
/// and in-memory. SwiftUI `Text`/`Image`/`TipView` surface and UIKit `TipUI*`
/// types are gated off this isolated host; they are not replaced with local
/// stand-ins. Persistence and CloudKit options are fail-closed / inert.
@frozen public enum Tips {}

enum TipsStore {
    static let shared = Storage()

    final class Storage: @unchecked Sendable {
        let completionQueue = DispatchQueue(label: "TipKit.Tips.completion")
        private let lock = NSLock()
        private var configured = false
        private var displayFrequency: Tips.ConfigurationOption.DisplayFrequency?
        private var requestedDatastore: Tips.ConfigurationOption.DatastoreLocation?
        private var requestedCloudKit: Tips.ConfigurationOption.CloudKitContainer??
        private var hideAllForTesting = false
        private var showAllForTesting = false
        private var hiddenTypeKeys: Set<String> = []
        private var shownTypeKeys: Set<String> = []
        private var donations: [String: [StoredDonation]] = [:]
        private var invalidations: [String: Tips.InvalidationReason] = [:]
        private var displayCounts: [String: Int] = [:]
        private var statusListeners: [UUID: () -> Void] = [:]

        struct StoredDonation: Sendable {
            var date: Date
            var payload: Data
        }

        func configure(_ configuration: [Tips.ConfigurationOption]) throws {
            lock.lock()
            defer { lock.unlock() }
            if configured {
                throw TipKitError.tipsDatastoreAlreadyConfigured
            }
            for option in configuration {
                switch option.payload {
                case .datastore(let location):
                    requestedDatastore = location
                case .frequency(let frequency):
                    displayFrequency = frequency
                case .cloudKit(let container):
                    requestedCloudKit = container
                }
            }
            configured = true
        }

        func resetDatastore() throws {
            let listeners: [() -> Void]
            lock.lock()
            donations.removeAll()
            invalidations.removeAll()
            displayCounts.removeAll()
            listeners = Array(statusListeners.values)
            lock.unlock()
            listeners.forEach { $0() }
        }

        func resetEverythingForHost() {
            lock.lock()
            configured = false
            displayFrequency = nil
            requestedDatastore = nil
            requestedCloudKit = nil
            hideAllForTesting = false
            showAllForTesting = false
            hiddenTypeKeys.removeAll()
            shownTypeKeys.removeAll()
            donations.removeAll()
            invalidations.removeAll()
            displayCounts.removeAll()
            let listeners = Array(statusListeners.values)
            lock.unlock()
            listeners.forEach { $0() }
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

        func appendDonation(
            eventID: String,
            date: Date,
            payload: Data,
            limit: Tips.DonationLimit
        ) {
            lock.lock()
            defer { lock.unlock() }
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
        }

        func invalidate(id: String, reason: Tips.InvalidationReason) {
            lock.lock()
            invalidations[id] = reason
            let listeners = Array(statusListeners.values)
            lock.unlock()
            listeners.forEach { $0() }
        }

        func resetEligibility(id: String) {
            lock.lock()
            invalidations[id] = nil
            displayCounts[id] = 0
            let listeners = Array(statusListeners.values)
            lock.unlock()
            listeners.forEach { $0() }
        }

        func recordDisplay(id: String, maxDisplayCount: Int?) {
            lock.lock()
            let next = displayCounts[id, default: 0] + 1
            displayCounts[id] = next
            var didInvalidate = false
            if let maxDisplayCount, next >= maxDisplayCount {
                invalidations[id] = .displayCountExceeded
                didInvalidate = true
            }
            let listeners = Array(statusListeners.values)
            lock.unlock()
            if didInvalidate || !listeners.isEmpty {
                listeners.forEach { $0() }
            }
        }

        func status(
            id: String,
            typeKey: String,
            rules: [Tips.Rule]
        ) -> Tips.Status {
            lock.lock()
            defer { lock.unlock() }
            if let reason = invalidations[id] {
                if showAllForTesting || shownTypeKeys.contains(typeKey) {
                    return .available
                }
                return .invalidated(reason)
            }
            if showAllForTesting || shownTypeKeys.contains(typeKey) {
                return .available
            }
            let rulesPass = rules.allSatisfy { $0.evaluate() }
            return rulesPass ? .available : .pending
        }

        func shouldDisplay(
            id: String,
            typeKey: String,
            rules: [Tips.Rule]
        ) -> Bool {
            lock.lock()
            let hideAll = hideAllForTesting
            let hidden = hiddenTypeKeys.contains(typeKey)
            let showAll = showAllForTesting
            let shown = shownTypeKeys.contains(typeKey)
            lock.unlock()
            if hideAll || hidden {
                return false
            }
            if showAll || shown {
                return true
            }
            let resolved = status(id: id, typeKey: typeKey, rules: rules)
            if case .available = resolved {
                return true
            }
            return false
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
    }
}

extension Tips {
    /// Configures the in-memory Linux tip store once per process.
    ///
    /// `datastoreLocation(.url)` and `cloudKitContainer` are accepted as
    /// option values and recorded, but they do not create a file, CloudKit
    /// container, or synchronized store. A second call throws
    /// `TipKitError.tipsDatastoreAlreadyConfigured`.
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
