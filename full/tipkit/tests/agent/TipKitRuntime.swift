@_spi(OpenUIKitHost) import TipKit
import Foundation

// Schema-v1 sealed gate compiles only this file. Focused tests live in
// tests/agent/*Tests.swift; this file inlines them so the host probe still
// exercises every cited identifier.

// --- TipEligibilityTests.swift ---
func testTipProtocolIdentityAndDefaults() {
    let tip = EligibleHostTip()
    precondition(tip.id == "eligible-host")
    precondition(tip.rules.isEmpty)
    let optionTip = OptionsHostTip()
    precondition(optionTip.actions.count == 1)
    precondition(optionTip.actions[0].id == "ok")
    precondition(optionTip.options.count == 3)
    let _: EligibleHostTip.Status = .available
    let _: EligibleHostTip.InvalidationReason = .tipClosed
    let _: EligibleHostTip.Action = Tips.Action(title: "x")
    let _: EligibleHostTip.Rule = Tips.Rule(hostPredicate: { true })
    let _: EligibleHostTip.Event<Tips.EmptyDonation> = Tips.Event(id: "alias-event")
    let _: EligibleHostTip.Option = Tips.MaxDisplayCount(1)
    let _: EligibleHostTip.IgnoresDisplayFrequency = Tips.IgnoresDisplayFrequency(false)
    let _: EligibleHostTip.MaxDisplayCount = Tips.MaxDisplayCount(2)
    let _: EligibleHostTip.MaxDisplayDuration = Tips.MaxDisplayDuration(1)
}

func testTipInvalidateAndResetEligibility() {
    TipsHostControl.resetForHostTests()
    let tip = EligibleHostTip()
    precondition(tip.status == .available)
    precondition(tip.shouldDisplay)
    tip.invalidate(reason: .actionPerformed)
    precondition(tip.status == .invalidated(.actionPerformed))
    precondition(tip.shouldDisplay == false)
    tipKitAwait {
        await tip.resetEligibility()
    }
    precondition(tip.status == .available)
    precondition(tip.shouldDisplay)
}

func testTipPendingRulesAndMaxDisplayCount() {
    TipsHostControl.resetForHostTests()
    let pending = PendingHostTip()
    precondition(pending.status == .pending)
    precondition(pending.shouldDisplay == false)

    let capped = OptionsHostTip()
    precondition(capped.shouldDisplay)
    capped.recordDisplayForHost()
    precondition(capped.status == .invalidated(.displayCountExceeded))
    precondition(capped.shouldDisplay == false)
}

func testTipStatusUpdatesAndShouldDisplayUpdates() {
    TipsHostControl.resetForHostTests()
    let tip = EligibleHostTip()
    let first = TipKitLocked<Tips.Status?>(nil)
    let second = TipKitLocked<Tips.Status?>(nil)
    let firstReady = DispatchSemaphore(value: 0)
    let secondReady = DispatchSemaphore(value: 0)
    Task {
        for await status in tip.statusUpdates {
            if first.load() == nil {
                first.store(status)
                firstReady.signal()
                continue
            }
            second.store(status)
            secondReady.signal()
            break
        }
    }
    tipKitWait(firstReady, "statusUpdates did not yield the initial status")
    precondition(first.load() == .available)
    tip.invalidate(reason: .tipClosed)
    tipKitWait(secondReady, "statusUpdates did not yield invalidation")
    precondition(second.load() == .invalidated(.tipClosed))

    TipsHostControl.resetForHostTests()
    let displayTip = EligibleHostTip()
    let flag = TipKitLocked<Bool?>(nil)
    let ready = DispatchSemaphore(value: 0)
    Task {
        for await value in displayTip.shouldDisplayUpdates {
            flag.store(value)
            ready.signal()
            break
        }
    }
    tipKitWait(ready, "shouldDisplayUpdates did not yield")
    precondition(flag.load() == true)
}

func testAnyTipErasure() {
    TipsHostControl.resetForHostTests()
    let base = OptionsHostTip()
    let erased = AnyTip(base)
    precondition(erased.id == "options-host")
    precondition(erased.rules.isEmpty)
    precondition(erased.actions.count == 1)
    precondition(erased.options.count == 3)
    precondition(erased.status == .available)
    precondition(erased.shouldDisplay)
    erased.invalidate(reason: .actionPerformed)
    precondition(erased.status == .invalidated(.actionPerformed))
    precondition(base.status == .invalidated(.actionPerformed))
    let _: AnyTip.ID = erased.id
    let _: AnyTip.Status = erased.status
    let _: AnyTip.InvalidationReason = .tipClosed
    let _: AnyTip.Action = erased.actions[0]
    let _: AnyTip.Option = Tips.MaxDisplayCount(1)
    let _: AnyTip.Rule = Tips.Rule(hostPredicate: { true })
    let _: AnyTip.Event<Tips.EmptyDonation> = Tips.Event(id: "any-event")
    let _: AnyTip.IgnoresDisplayFrequency = Tips.IgnoresDisplayFrequency(true)
    let _: AnyTip.MaxDisplayCount = Tips.MaxDisplayCount(4)
    let _: AnyTip.MaxDisplayDuration = Tips.MaxDisplayDuration(2)
    tipKitAwait { await erased.resetEligibility() }
    precondition(erased.status == .available)
}
// --- TipGroupTests.swift ---
func testTipGroupPriority() {
    let group = TipGroup(.ordered)
    precondition(group.priority == .ordered)
    precondition(TipGroup.Priority.firstAvailable != .ordered)
    var hasher = Hasher()
    group.priority.hash(into: &hasher)
    _ = TipGroup.Priority.firstAvailable.hashValue
    _ = TipGroup()
}

func testTipGroupCurrentTip() {
    TipsHostControl.resetForHostTests()
    let pending = PendingHostTip()
    let eligible = EligibleHostTip()
    let group = TipGroup(.ordered) {
        pending
        eligible
    }
    let seen = TipKitLocked<String?>(nil)
    let ready = DispatchSemaphore(value: 0)
    Task { @MainActor in
        seen.store(group.currentTip?.id)
        ready.signal()
    }
    tipKitWait(ready, "currentTip did not resolve on MainActor")
    precondition(seen.load() == "eligible-host")

    let first = TipKitLocked<String?>(nil)
    let firstReady = DispatchSemaphore(value: 0)
    Task {
        for await tip in group.currentTipUpdates {
            first.store(tip.id)
            firstReady.signal()
            break
        }
    }
    tipKitWait(firstReady, "currentTipUpdates did not yield")
    precondition(first.load() == "eligible-host")
}

func testHideShowAllAndTypedTestingFlags() {
    TipsHostControl.resetForHostTests()
    let tip = EligibleHostTip()
    Tips.hideAllTipsForTesting()
    var flags = TipsHostControl.testingFlags()
    precondition(flags.hideAll)
    precondition(flags.showAll == false)
    precondition(tip.shouldDisplay == false)
    Tips.showAllTipsForTesting()
    flags = TipsHostControl.testingFlags()
    precondition(flags.showAll)
    precondition(flags.hideAll == false)
    precondition(tip.shouldDisplay)

    TipsHostControl.resetForHostTests()
    let pending = PendingHostTip()
    precondition(pending.shouldDisplay == false)
    Tips.showTipsForTesting([PendingHostTip.self])
    precondition(pending.shouldDisplay)
    Tips.hideTipsForTesting([PendingHostTip.self])
    precondition(pending.shouldDisplay == false)
}
// --- TipKitErrorTests.swift ---
func testTipKitErrorIdentities() {
    let configured = TipKitError.tipsDatastoreAlreadyConfigured
    let entitlements = TipKitError.missingGroupContainerEntitlements
    let predicate = TipKitError.invalidPredicateValueType
    precondition(configured == TipKitError.tipsDatastoreAlreadyConfigured)
    precondition(configured != entitlements)
    precondition(entitlements != predicate)
    precondition(configured.description == "tipsDatastoreAlreadyConfigured")
    precondition(configured.errorDescription == "tipsDatastoreAlreadyConfigured")
    precondition(configured.failureReason == nil)
    precondition(configured.helpAnchor == nil)
    precondition(configured.recoverySuggestion == nil)
    precondition(!configured.localizedDescription.isEmpty)
    var hasher = Hasher()
    configured.hash(into: &hasher)
    _ = configured.hashValue
    _ = entitlements.hashValue
    _ = predicate.hashValue
}
// --- TipKitSupportTests.swift ---
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
// --- TipsActionParameterTests.swift ---
func testActionStringProtocolInit() {
    let fired = TipKitLocked(0)
    let action = Tips.Action(id: "open-settings", title: "Open Settings") {
        fired.store(fired.load() + 1)
    }
    precondition(action.id == "open-settings")
    precondition(action.index == nil)
    precondition(action.titleText == "Open Settings")
    tipKitAwait {
        await MainActor.run {
            action.handler()
        }
    }
    precondition(fired.load() == 1)
    let inferred = Tips.Action(title: "OnlyTitle")
    precondition(inferred.id == "OnlyTitle")
}

func testParameterAndRuleSPI() {
    let parameter = Tips.Parameter(wrappedValue: true, id: "seen-onboarding", options: .transient)
    precondition(parameter.id == "seen-onboarding")
    precondition(parameter.wrappedValue == true)
    parameter.wrappedValue = false
    precondition(parameter.wrappedValue == false)
    precondition(parameter.projectedValue.id == "seen-onboarding")
    precondition(Tips.ParameterOption.transient == .transient)

    let yes = Tips.Rule(hostPredicate: { true })
    let no = Tips.Rule(hostPredicate: { false })
    precondition(yes.evaluateHost())
    precondition(no.evaluateHost() == false)
    let and = Tips.Rule.conjunction(yes, no)
    precondition(and.evaluateHost() == false)
    precondition(and.hostOperation == .conjunction)
    let or = Tips.Rule.disjunction(yes, no)
    precondition(or.evaluateHost())
    precondition(or.hostOperation == .disjunction)
    precondition(Tips.Rule.CompoundOperation.conjunction != .disjunction)
    var hasher = Hasher()
    Tips.Rule.CompoundOperation.conjunction.hash(into: &hasher)
    _ = Tips.Rule.CompoundOperation.disjunction.hashValue
}
// --- TipsConfigurationTests.swift ---
func testConfigurationCloudKitAndFrequency() {
    let automatic = Tips.ConfigurationOption.CloudKitContainer.automatic
    let named = Tips.ConfigurationOption.CloudKitContainer.named("iCloud.example")
    precondition(automatic != named)
    precondition(automatic == .automatic)
    let daily = Tips.ConfigurationOption.DisplayFrequency.daily
    precondition(daily == .daily)
    precondition(Tips.ConfigurationOption.DisplayFrequency.hourly != .weekly)
    precondition(Tips.ConfigurationOption.DisplayFrequency.monthly != .immediate)
    _ = Tips.ConfigurationOption.displayFrequency(.hourly)
    _ = Tips.ConfigurationOption.cloudKitContainer(.automatic)
    _ = Tips.ConfigurationOption.cloudKitContainer(nil)
}

func testDatastoreLocationFailClosed() {
    let memory = Tips.ConfigurationOption.DatastoreLocation.applicationDefault
    let url = Tips.ConfigurationOption.DatastoreLocation.url(
        URL(fileURLWithPath: "/tmp/tipkit-should-not-be-created.store")
    )
    precondition(memory != url)
    precondition(memory == .applicationDefault)
    do {
        _ = try Tips.ConfigurationOption.DatastoreLocation.groupContainer(
            identifier: "group.example"
        )
        fatalError("groupContainer must throw")
    } catch let error as TipKitError {
        precondition(error == .missingGroupContainerEntitlements)
    } catch {
        fatalError("groupContainer must throw TipKitError")
    }
    _ = Tips.ConfigurationOption.datastoreLocation(memory)
}

func testConfigureOnceAndResetDatastore() {
    TipsHostControl.resetForHostTests()
    let store = tipKitUniqueDirectory().appendingPathComponent("tips.store")
    try! Tips.configure([
        .displayFrequency(.daily),
        .datastoreLocation(.url(store)),
        .cloudKitContainer(.named("iCloud.example")),
    ])
    let snapshot = TipsHostControl.snapshotConfig()
    precondition(snapshot.configured)
    precondition(snapshot.frequency == .daily)
    precondition(FileManager.default.fileExists(atPath: store.path))
    precondition(TipsHostControl.cloudKitSyncEnabled() == false)
    do {
        try Tips.configure()
        fatalError("second configure must throw")
    } catch let error as TipKitError {
        precondition(error == .tipsDatastoreAlreadyConfigured)
    } catch {
        fatalError("second configure must throw TipKitError")
    }

    let tip = EligibleHostTip()
    tip.invalidate(reason: .actionPerformed)
    precondition(tip.status == .invalidated(.actionPerformed))
    try! Tips.resetDatastore()
    precondition(tip.status == .available)
}
// --- TipsDonationTests.swift ---
func testDonationTimeRangeValues() {
    precondition(Tips.DonationTimeRange.minute != .hour)
    precondition(Tips.DonationTimeRange.hour != .day)
    precondition(Tips.DonationTimeRange.day != .week)
    precondition(Tips.DonationTimeRange.minutes(2) != .minutes(3))
    precondition(Tips.DonationTimeRange.hours(1) == .hour)
    precondition(Tips.DonationTimeRange.days(1) == .day)
    precondition(Tips.DonationTimeRange.weeks(1) == .week)
    let encoded = try! JSONEncoder().encode(Tips.DonationTimeRange.day)
    let decoded = try! JSONDecoder().decode(Tips.DonationTimeRange.self, from: encoded)
    precondition(decoded == .day)
    var hasher = Hasher()
    decoded.hash(into: &hasher)
    _ = decoded.hashValue
}

func testDonationLimitAndDisplayOptions() {
    let limit = Tips.DonationLimit(maximumCount: 2, maximumAge: .minute)
    precondition(limit.maximumCount == 2)
    precondition(limit.maximumAge == .minute)
    let count = Tips.MaxDisplayCount(3)
    let duration = Tips.MaxDisplayDuration(1.5)
    let ignores = Tips.IgnoresDisplayFrequency(true)
    let option: any TipOption = count
    _ = option
    _ = duration
    _ = ignores
}

func testEmptyDonationCodable() {
    let empty = Tips.EmptyDonation()
    let data = try! JSONEncoder().encode(empty)
    _ = try! JSONDecoder().decode(Tips.EmptyDonation.self, from: data)
}
// --- TipsEventTests.swift ---
func testEventDonateAndQuery() {
    TipsHostControl.resetForHostTests()
    try! Tips.resetDatastore()
    let visits = Tips.Event<VisitDonation>(id: "visited-city")
    tipKitAwait {
        await visits.donate(VisitDonation(city: "Austin", count: 1))
        await visits.donate(VisitDonation(city: "Austin", count: 2))
        await visits.donate(VisitDonation(city: "Dallas", count: 1))
    }
    precondition(visits.donations.count == 3)
    precondition(visits.donations[0].city == "Austin")
    precondition(visits.donations[0].date.timeIntervalSince1970 > 0)
    let largest = visits.donations.largestSubset(groupedBy: \.city)
    precondition(largest.count == 2)
    precondition(largest.allSatisfy { $0.city == "Austin" })
    let smallest = visits.donations.smallestSubset(groupedBy: \.city)
    precondition(smallest.count == 1)
    precondition(smallest[0].city == "Dallas")
    let recent = visits.donations.donatedWithin(.day)
    precondition(recent.count == 3)
    tipKitAwait {
        try! await visits.deleteDonations()
    }
    precondition(visits.donations.isEmpty)
}

func testEventEmptyDonationAndLimit() {
    TipsHostControl.resetForHostTests()
    let empty = Tips.Event<Tips.EmptyDonation>(id: "opened-app")
    tipKitAwait { await empty.donate() }
    precondition(empty.donations.count == 1)

    let limited = Tips.Event<VisitDonation>(
        id: "limited-visits",
        donationLimit: Tips.DonationLimit(maximumCount: 2)
    )
    tipKitAwait {
        await limited.donate(VisitDonation(city: "A", count: 1))
        await limited.donate(VisitDonation(city: "B", count: 1))
        await limited.donate(VisitDonation(city: "C", count: 1))
    }
    precondition(limited.donations.count == 2)
    precondition(limited.donations[0].city == "B")
    precondition(limited.donations[1].city == "C")

    let encoded = try! JSONEncoder().encode(limited.donations[1])
    let decoded = try! JSONDecoder().decode(
        Tips.Event<VisitDonation>.Donation.self,
        from: encoded
    )
    precondition(decoded.city == "C")

    let typedEmpty = Tips.Event<Tips.EmptyDonation>(
        id: "empty-limited",
        donationLimit: Tips.DonationLimit(maximumCount: 8)
    )
    _ = typedEmpty.id
}

func testEventSendDonationHop() {
    TipsHostControl.resetForHostTests()
    let event = Tips.Event<Tips.EmptyDonation>(id: "hop-empty")
    let returned = TipKitLocked(false)
    let sawReturned = TipKitLocked(false)
    let count = TipKitLocked(0)
    let release = TipsHostControl.occupyCompletionQueue {}
    event.sendDonation {
        sawReturned.store(returned.load())
        count.store(count.load() + 1)
    }
    returned.store(true)
    release()
    let done = DispatchSemaphore(value: 0)
    TipsHostControl.completionQueue.async {
        done.signal()
    }
    tipKitWait(done, "donation completion queue did not drain")
    precondition(count.load() == 1)
    precondition(sawReturned.load())
}

func testEventDonationAgeTrim() {
    TipsHostControl.resetForHostTests()
    let event = Tips.Event<VisitDonation>(
        id: "aged-visits",
        donationLimit: Tips.DonationLimit(maximumCount: 10, maximumAge: .minute)
    )
    let old = Date().addingTimeInterval(-120)
    event.sendDonation(VisitDonation(city: "Old", count: 1), date: old)
    event.sendDonation(VisitDonation(city: "New", count: 1), date: Date()) {}
    precondition(event.donations.count == 1)
    precondition(event.donations[0].city == "New")
}
// --- TipsStatusTests.swift ---
func testTipsStatusCases() {
    let pending = Tips.Status.pending
    let available = Tips.Status.available
    let closed = Tips.Status.invalidated(.tipClosed)
    precondition(pending == .pending)
    precondition(pending != available)
    precondition(available != closed)
    precondition(closed == .invalidated(.tipClosed))
    var hasher = Hasher()
    pending.hash(into: &hasher)
    _ = pending.hashValue
    _ = available.hashValue
}

func testInvalidationReasonCases() {
    let cases: [Tips.InvalidationReason] = [
        .actionPerformed,
        .displayCountExceeded,
        .displayDurationExceeded,
        .tipClosed,
    ]
    precondition(Set(cases).count == 4)
    precondition(Tips.InvalidationReason.actionPerformed != .displayCountExceeded)
    precondition(Tips.InvalidationReason.displayDurationExceeded != .tipClosed)
    var hasher = Hasher()
    Tips.InvalidationReason.actionPerformed.hash(into: &hasher)
    _ = Tips.InvalidationReason.tipClosed.hashValue
}

func testConfigureCreatesApplicationDefaultStore() {
    TipsHostControl.resetForHostTests()
    let root = tipKitUniqueDirectory()
    TipsHostControl.setApplicationSupportRootForHost(root)
    try! Tips.configure([.datastoreLocation(.applicationDefault)])
    let url = root
        .appendingPathComponent("TipKit", isDirectory: true)
        .appendingPathComponent("datastore.json", isDirectory: false)
    precondition(FileManager.default.fileExists(atPath: url.path))
    precondition(TipsHostControl.datastoreFileURL()?.path == url.path)
}

func testURLDatastorePersistsDonationsAndParameters() {
    TipsHostControl.resetForHostTests()
    let store = tipKitUniqueDirectory().appendingPathComponent("tips.store")
    try! Tips.configure([.datastoreLocation(.url(store))])
    let event = Tips.Event<Tips.EmptyDonation>(id: "persist-open")
    event.sendDonation()
    let parameter = Tips.Parameter(wrappedValue: 0, id: "persist-count")
    parameter.wrappedValue = 9
    EligibleHostTip().invalidate(reason: .tipClosed)
    precondition(FileManager.default.fileExists(atPath: store.path))
    precondition(event.donations.count == 1)

    TipsHostControl.resetForHostTests()
    try! Tips.configure([.datastoreLocation(.url(store))])
    precondition(Tips.Event<Tips.EmptyDonation>(id: "persist-open").donations.count == 1)
    precondition(Tips.Parameter(wrappedValue: 0, id: "persist-count").wrappedValue == 9)
    precondition(EligibleHostTip().status == .invalidated(.tipClosed))
}

func testResetDatastoreClearsOnDiskStore() {
    TipsHostControl.resetForHostTests()
    let store = tipKitUniqueDirectory().appendingPathComponent("reset.store")
    try! Tips.configure([.datastoreLocation(.url(store))])
    Tips.Event<Tips.EmptyDonation>(id: "reset-open").sendDonation()
    EligibleHostTip().invalidate(reason: .actionPerformed)
    try! Tips.resetDatastore()
    precondition(Tips.Event<Tips.EmptyDonation>(id: "reset-open").donations.isEmpty)
    precondition(EligibleHostTip().status == .available)

    TipsHostControl.resetForHostTests()
    try! Tips.configure([.datastoreLocation(.url(store))])
    precondition(Tips.Event<Tips.EmptyDonation>(id: "reset-open").donations.isEmpty)
    precondition(EligibleHostTip().status == .available)
}

func testTransientParameterDoesNotPersist() {
    TipsHostControl.resetForHostTests()
    let store = tipKitUniqueDirectory().appendingPathComponent("transient.store")
    try! Tips.configure([.datastoreLocation(.url(store))])
    let parameter = Tips.Parameter(
        wrappedValue: true,
        id: "transient-flag",
        options: .transient
    )
    parameter.wrappedValue = false
    precondition(parameter.wrappedValue == false)

    TipsHostControl.resetForHostTests()
    try! Tips.configure([.datastoreLocation(.url(store))])
    let restored = Tips.Parameter(
        wrappedValue: true,
        id: "transient-flag",
        options: .transient
    )
    precondition(restored.wrappedValue == true)
}

func testCloudKitContainerIsFailClosed() {
    TipsHostControl.resetForHostTests()
    try! Tips.configure([.cloudKitContainer(.named("iCloud.example"))])
    let snapshot = TipsHostControl.snapshotConfig()
    precondition(snapshot.configured)
    precondition(TipsHostControl.cloudKitSyncEnabled() == false)
}

func testRuleParameterPredicate() {
    TipsHostControl.resetForHostTests()
    let seen = Tips.Parameter(wrappedValue: false, id: "onboarded-wave8")
    let rule = Tips.Rule(seen) { $0 == true }
    struct RuleParameterTip: Tip {
        let rules: [Tips.Rule]
        var id: String { "rule-parameter-tip" }
    }
    let tip = RuleParameterTip(rules: [rule])
    precondition(tip.status == .pending)
    precondition(tip.shouldDisplay == false)
    seen.wrappedValue = true
    precondition(seen.wrappedValue == true)
    precondition(tip.status == .available)
    precondition(tip.shouldDisplay)
}

func testRuleEventDonationCountPredicate() {
    TipsHostControl.resetForHostTests()
    let unlocked = Tips.Event<Tips.EmptyDonation>(id: "opened-editor")
    let rule = Tips.Rule(unlocked) { $0.donations.count >= 2 }
    struct RuleEventTip: Tip {
        let rules: [Tips.Rule]
        var id: String { "rule-event-tip" }
    }
    let tip = RuleEventTip(rules: [rule])
    precondition(unlocked.donations.count == 0)
    precondition(tip.status == .pending)
    unlocked.sendDonation()
    precondition(unlocked.donations.count == 1)
    precondition(tip.status == .pending)
    unlocked.sendDonation()
    precondition(unlocked.donations.count == 2)
    precondition(tip.status == .available)
    precondition(tip.shouldDisplay)
}

func testDisplayFrequencyDailyAgainstFixedClock() {
    TipsHostControl.resetForHostTests()
    let start = Date(timeIntervalSince1970: 1_700_000_000)
    TipsHostControl.setNow(start)
    try! Tips.configure([.displayFrequency(.daily)])
    let tip = EligibleHostTip()
    precondition(tip.status == .available)
    precondition(tip.shouldDisplay)
    tip.recordDisplayForHost()
    precondition(TipsHostControl.lastDisplayDate() == start)
    precondition(tip.status == .available)
    precondition(tip.shouldDisplay == false)
    TipsHostControl.setNow(start.addingTimeInterval(86_399))
    precondition(tip.shouldDisplay == false)
    TipsHostControl.setNow(start.addingTimeInterval(86_400))
    precondition(tip.shouldDisplay)
}

func testDisplayFrequencyHourlyWeeklyMonthlyImmediate() {
    let start = Date(timeIntervalSince1970: 1_710_000_000)
    let cases: [(Tips.ConfigurationOption.DisplayFrequency, TimeInterval?)] = [
        (.immediate, nil),
        (.hourly, 3_600),
        (.weekly, 604_800),
        (.monthly, 2_592_000),
    ]
    for (frequency, seconds) in cases {
        TipsHostControl.resetForHostTests()
        TipsHostControl.setNow(start)
        try! Tips.configure([.displayFrequency(frequency)])
        let tip = EligibleHostTip()
        precondition(tip.shouldDisplay)
        tip.recordDisplayForHost()
        if let seconds {
            TipsHostControl.setNow(start.addingTimeInterval(seconds - 1))
            precondition(tip.shouldDisplay == false)
            TipsHostControl.setNow(start.addingTimeInterval(seconds))
            precondition(tip.shouldDisplay)
        } else {
            precondition(tip.shouldDisplay)
        }
    }
}

func testIgnoresDisplayFrequencyBypassesThrottle() {
    TipsHostControl.resetForHostTests()
    let start = Date(timeIntervalSince1970: 1_720_000_000)
    TipsHostControl.setNow(start)
    try! Tips.configure([.displayFrequency(.daily)])
    EligibleHostTip().recordDisplayForHost()
    precondition(EligibleHostTip().shouldDisplay == false)
    precondition(FrequencyIgnoreHostTip().shouldDisplay)
    precondition(FrequencyIgnoreHostTip().status == .available)
}

func testTipViewHoldsTipAndAction() {
    let tip = EligibleHostTip()
    var fired = 0
    let view = TipView(tip) { _ in
        fired += 1
    }
    precondition(view.tip?.id == "eligible-host")
    view.actionHandler(Tips.Action(title: "do"))
    precondition(fired == 1)
    let erased = TipView(tip as (any Tip)?)
    precondition(erased.tip?.id == "eligible-host")
}

func testMiniTipViewStyleMakeBody() {
    let style = MiniTipViewStyle()
    let configuration = TipViewStyleConfiguration(tip: EligibleHostTip())
    let body = style.makeBody(configuration: configuration)
    precondition(body.tip.id == "eligible-host")
    let mini = MiniTipViewStyle.miniTip
    _ = mini.makeBody(configuration: configuration)
}

func testTipViewStyleConfigurationActions() {
    let configuration = TipViewStyleConfiguration(tip: OptionsHostTip())
    precondition(configuration.tip.id == "options-host")
    precondition(configuration.actions.count == 1)
    precondition(configuration.actions[0].id == "ok")
}

func testTipUIViewConfiguration() {
    let view = TipUIView(EligibleHostTip())
    precondition(view.tip.id == "eligible-host")
    view.cornerRadius = 8
    view.imageSize = CGSize(width: 12, height: 16)
    view.viewStyle = MiniTipViewStyle()
    precondition(view.cornerRadius == 8)
    precondition(view.imageSize.width == 12)
    precondition(view.imageSize.height == 16)
    let configuration = TipViewStyleConfiguration(tip: view.tip)
    _ = MiniTipViewStyle().makeBody(configuration: configuration)
}

func testTipUICollectionViewCellFrameInit() {
    let cell = TipUICollectionViewCell(
        frame: CGRect(x: 1, y: 2, width: 30, height: 40)
    )
    precondition(cell.frame.width == 30)
    precondition(cell.frame.height == 40)
    cell.cornerRadius = 3
    cell.imageSize = CGSize(width: 5, height: 6)
    cell.viewStyle = MiniTipViewStyle()
    _ = cell.configureTip(EligibleHostTip())
    precondition(cell.tip?.id == "eligible-host")
    precondition(cell.cornerRadius == 3)
    precondition(cell.imageSize.width == 5)
}

func testTipUICollectionViewCellCoderInit() {
    precondition(TipUICollectionViewCell(coder: TipKitHostCoder()) == nil)
}

func testTipUICollectionReusableViewFrameInit() {
    let view = TipUICollectionReusableView(
        frame: CGRect(x: 0, y: 0, width: 10, height: 20)
    )
    precondition(view.frame.height == 20)
    view.cornerRadius = 1
    view.imageSize = CGSize(width: 2, height: 3)
    view.viewStyle = MiniTipViewStyle()
    _ = view.configureTip(OptionsHostTip())
    precondition(view.tip?.id == "options-host")
}

func testTipUICollectionReusableViewCoderInit() {
    precondition(TipUICollectionReusableView(coder: TipKitHostCoder()) == nil)
}

func testTipUIPopoverViewControllerNibInit() {
    let controller = TipUIPopoverViewController(nibName: "TipPopover", bundle: nil)
    precondition(controller.nibName == "TipPopover")
    precondition(controller.bundle == nil)
    controller.imageSize = CGSize(width: 9, height: 9)
    controller.viewStyle = MiniTipViewStyle()
    controller.configure(EligibleHostTip())
    precondition(controller.tip?.id == "eligible-host")
    precondition(controller.imageSize.width == 9)
}

func testTipUIPopoverViewControllerCoderInit() {
    precondition(TipUIPopoverViewController(coder: TipKitHostCoder()) == nil)
}

func tipKitRuntimeMain() {
    TipsHostControl.resetForHostTests()
    testTipKitErrorIdentities()
    testTipsStatusCases()
    testInvalidationReasonCases()
    testDonationTimeRangeValues()
    testDonationLimitAndDisplayOptions()
    testEmptyDonationCodable()
    testConfigurationCloudKitAndFrequency()
    testDatastoreLocationFailClosed()
    testConfigureOnceAndResetDatastore()
    testConfigureCreatesApplicationDefaultStore()
    testURLDatastorePersistsDonationsAndParameters()
    testResetDatastoreClearsOnDiskStore()
    testTransientParameterDoesNotPersist()
    testCloudKitContainerIsFailClosed()
    testEventDonateAndQuery()
    testEventEmptyDonationAndLimit()
    testEventSendDonationHop()
    testEventDonationAgeTrim()
    testActionStringProtocolInit()
    testParameterAndRuleSPI()
    testRuleParameterPredicate()
    testRuleEventDonationCountPredicate()
    testDisplayFrequencyDailyAgainstFixedClock()
    testDisplayFrequencyHourlyWeeklyMonthlyImmediate()
    testIgnoresDisplayFrequencyBypassesThrottle()
    testTipProtocolIdentityAndDefaults()
    testTipInvalidateAndResetEligibility()
    testTipPendingRulesAndMaxDisplayCount()
    testTipStatusUpdatesAndShouldDisplayUpdates()
    testAnyTipErasure()
    testTipGroupPriority()
    testTipGroupCurrentTip()
    testHideShowAllAndTypedTestingFlags()
    testTipViewHoldsTipAndAction()
    testMiniTipViewStyleMakeBody()
    testTipViewStyleConfigurationActions()
    testTipUIViewConfiguration()
    testTipUICollectionViewCellFrameInit()
    testTipUICollectionViewCellCoderInit()
    testTipUICollectionReusableViewFrameInit()
    testTipUICollectionReusableViewCoderInit()
    testTipUIPopoverViewControllerNibInit()
    testTipUIPopoverViewControllerCoderInit()
    print("TIPKIT_AGENT_RUNTIME_OK")
}

Task {
    tipKitRuntimeMain()
    exit(0)
}
dispatchMain()
