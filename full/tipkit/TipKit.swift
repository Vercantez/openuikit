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
        private var donations: [String: [StoredDonation]] = [:]

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
            lock.lock()
            defer { lock.unlock() }
            donations.removeAll()
        }

        func resetEverythingForHost() {
            lock.lock()
            defer { lock.unlock() }
            configured = false
            displayFrequency = nil
            requestedDatastore = nil
            requestedCloudKit = nil
            hideAllForTesting = false
            showAllForTesting = false
            donations.removeAll()
        }

        func setHideAllForTesting() {
            lock.lock()
            hideAllForTesting = true
            showAllForTesting = false
            lock.unlock()
        }

        func setShowAllForTesting() {
            lock.lock()
            showAllForTesting = true
            hideAllForTesting = false
            lock.unlock()
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
