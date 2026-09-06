@_spi(OpenUIKitHost) import TipKit
import Foundation

final class TipKitLocked<Value>: @unchecked Sendable {
    private let lock = NSLock()
    private var value: Value

    init(_ value: Value) {
        self.value = value
    }

    func load() -> Value {
        lock.lock()
        defer { lock.unlock() }
        return value
    }

    func store(_ value: Value) {
        lock.lock()
        self.value = value
        lock.unlock()
    }
}

func tipKitWait(_ semaphore: DispatchSemaphore, _ message: String) {
    precondition(
        semaphore.wait(timeout: .now() + DispatchTimeInterval.seconds(5)) == .success,
        message
    )
}

func tipKitAwait(_ body: @escaping @Sendable () async -> Void) {
    let semaphore = DispatchSemaphore(value: 0)
    Task {
        await body()
        semaphore.signal()
    }
    tipKitWait(semaphore, "async TipKit probe timed out")
}

struct EligibleHostTip: Tip {
    var id: String { "eligible-host" }
}

struct PendingHostTip: Tip {
    var id: String { "pending-host" }

    @Tips.RuleBuilder
    var rules: [Tips.Rule] {
        Tips.Rule(hostPredicate: { false })
    }
}

struct OptionsHostTip: Tip {
    var id: String { "options-host" }

    @Tips.OptionsBuilder
    var options: [any TipOption] {
        Tips.MaxDisplayCount(1)
        Tips.IgnoresDisplayFrequency(true)
        Tips.MaxDisplayDuration(30)
    }

    @Tips.ActionBuilder
    var actions: [Tips.Action] {
        Tips.Action(id: "ok", title: "OK")
    }
}

struct VisitDonation: Codable, Sendable {
    var city: String
    var count: Int
}

struct FrequencyIgnoreHostTip: Tip {
    var id: String { "frequency-ignore-host" }

    @Tips.OptionsBuilder
    var options: [any TipOption] {
        Tips.IgnoresDisplayFrequency(true)
    }
}

func tipKitUniqueDirectory() -> URL {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent(
        "tipkit-host-\(UUID().uuidString)",
        isDirectory: true
    )
    try! FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    return url
}

final class TipKitHostCoder: NSCoder {}
