@_spi(OpenUIKitHost) import TipKit
import Foundation

private let eventTimeout = DispatchTimeInterval.seconds(5)

private final class LockedState: @unchecked Sendable {
    private let lock = NSLock()
    private var returned = false
    private var sawReturned = false
    private var count = 0

    func markReturned() {
        lock.lock()
        returned = true
        lock.unlock()
    }

    func noteCallback() {
        lock.lock()
        sawReturned = returned
        count += 1
        lock.unlock()
    }

    func snapshot() -> (sawReturned: Bool, count: Int) {
        lock.lock()
        defer { lock.unlock() }
        return (sawReturned, count)
    }
}

private func waitEvent(_ semaphore: DispatchSemaphore, _ message: String) {
    precondition(semaphore.wait(timeout: .now() + eventTimeout) == .success, message)
}

private struct Visit: Codable, Sendable {
    var city: String
    var count: Int
}

func assertErrorIdentities() {
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
}

func assertStatusAndInvalidation() {
    let pending = Tips.Status.pending
    let available = Tips.Status.available
    let closed = Tips.Status.invalidated(.tipClosed)
    precondition(pending == .pending)
    precondition(pending != available)
    precondition(available != closed)
    precondition(closed == .invalidated(.tipClosed))
    precondition(Tips.InvalidationReason.actionPerformed != .displayCountExceeded)
    precondition(Tips.InvalidationReason.displayDurationExceeded != .tipClosed)
    var hasher = Hasher()
    pending.hash(into: &hasher)
    Tips.InvalidationReason.actionPerformed.hash(into: &hasher)
    _ = pending.hashValue
    _ = Tips.InvalidationReason.tipClosed.hashValue
}

func assertTimeRangesAndLimits() {
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

    let limit = Tips.DonationLimit(maximumCount: 2, maximumAge: .minute)
    precondition(limit.maximumCount == 2)
    precondition(limit.maximumAge == .minute)

    _ = Tips.MaxDisplayCount(3)
    _ = Tips.MaxDisplayDuration(1.5)
    _ = Tips.IgnoresDisplayFrequency(true)
    let option: any TipOption = Tips.MaxDisplayCount(1)
    _ = option
}

func assertConfigurationOptions() {
    let automatic = Tips.ConfigurationOption.CloudKitContainer.automatic
    let named = Tips.ConfigurationOption.CloudKitContainer.named("iCloud.example")
    precondition(automatic != named)
    precondition(automatic == .automatic)
    let daily = Tips.ConfigurationOption.DisplayFrequency.daily
    precondition(daily == .daily)
    precondition(Tips.ConfigurationOption.DisplayFrequency.hourly != .weekly)
    precondition(Tips.ConfigurationOption.DisplayFrequency.monthly != .immediate)
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
    _ = Tips.ConfigurationOption.displayFrequency(.hourly)
    _ = Tips.ConfigurationOption.cloudKitContainer(.automatic)
    _ = Tips.ConfigurationOption.cloudKitContainer(nil)
}

func exerciseConfigure() throws {
    TipsHostControl.resetForHostTests()
    try Tips.configure([
        .displayFrequency(.daily),
        .datastoreLocation(.url(URL(fileURLWithPath: "/tmp/tipkit-should-not-be-created.store"))),
        .cloudKitContainer(.named("iCloud.example")),
    ])
    let snapshot = TipsHostControl.snapshotConfig()
    precondition(snapshot.configured)
    precondition(snapshot.frequency == .daily)
    precondition(
        FileManager.default.fileExists(
            atPath: "/tmp/tipkit-should-not-be-created.store"
        ) == false
    )
    do {
        try Tips.configure()
        fatalError("second configure must throw")
    } catch let error as TipKitError {
        precondition(error == .tipsDatastoreAlreadyConfigured)
    } catch {
        fatalError("second configure must throw TipKitError")
    }
}

func exerciseTestingFlags() {
    Tips.hideAllTipsForTesting()
    var flags = TipsHostControl.testingFlags()
    precondition(flags.hideAll)
    precondition(flags.showAll == false)
    Tips.showAllTipsForTesting()
    flags = TipsHostControl.testingFlags()
    precondition(flags.showAll)
    precondition(flags.hideAll == false)
}

func exerciseActions() async {
    let fired = LockedState()
    let action = Tips.Action(id: "open-settings", title: "Open Settings") {
        fired.noteCallback()
    }
    precondition(action.id == "open-settings")
    precondition(action.index == nil)
    precondition(action.titleText == "Open Settings")
    await MainActor.run {
        action.handler()
    }
    precondition(fired.snapshot().count == 1)
    let inferred = Tips.Action(title: "OnlyTitle")
    precondition(inferred.id == "OnlyTitle")
}

func exerciseParametersAndRules() {
    var parameter = Tips.Parameter(wrappedValue: true, id: "seen-onboarding", options: .transient)
    precondition(parameter.id == "seen-onboarding")
    precondition(parameter.wrappedValue == true)
    parameter.wrappedValue = false
    precondition(parameter.wrappedValue == false)
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

func exerciseEvents() async throws {
    try Tips.resetDatastore()
    let visits = Tips.Event<Visit>(id: "visited-city")
    await visits.donate(Visit(city: "Austin", count: 1))
    await visits.donate(Visit(city: "Austin", count: 2))
    await visits.donate(Visit(city: "Dallas", count: 1))
    precondition(visits.donations.count == 3)
    precondition(visits.donations[0].city == "Austin")
    let largest = visits.donations.largestSubset(groupedBy: \.city)
    precondition(largest.count == 2)
    precondition(largest.allSatisfy { $0.city == "Austin" })
    let smallest = visits.donations.smallestSubset(groupedBy: \.city)
    precondition(smallest.count == 1)
    precondition(smallest[0].city == "Dallas")
    let recent = visits.donations.donatedWithin(.day)
    precondition(recent.count == 3)
    try await visits.deleteDonations()
    precondition(visits.donations.isEmpty)

    let empty = Tips.Event<Tips.EmptyDonation>(id: "opened-app")
    await empty.donate()
    precondition(empty.donations.count == 1)

    let limited = Tips.Event<Visit>(
        id: "limited-visits",
        donationLimit: Tips.DonationLimit(maximumCount: 2)
    )
    await limited.donate(Visit(city: "A", count: 1))
    await limited.donate(Visit(city: "B", count: 1))
    await limited.donate(Visit(city: "C", count: 1))
    precondition(limited.donations.count == 2)
    precondition(limited.donations[0].city == "B")
    precondition(limited.donations[1].city == "C")

    let encoded = try JSONEncoder().encode(limited.donations[1])
    let decoded = try JSONDecoder().decode(Tips.Event<Visit>.Donation.self, from: encoded)
    precondition(decoded.city == "C")
}

func exerciseSendDonationHop() {
    let event = Tips.Event<Tips.EmptyDonation>(id: "hop-empty")
    let state = LockedState()
    let release = TipsHostControl.occupyCompletionQueue {}
    event.sendDonation {
        state.noteCallback()
    }
    state.markReturned()
    release()
    let done = DispatchSemaphore(value: 0)
    TipsHostControl.completionQueue.async {
        done.signal()
    }
    waitEvent(done, "donation completion queue did not drain")
    let snapshot = state.snapshot()
    precondition(snapshot.count == 1)
    precondition(snapshot.sawReturned)
}

func exerciseEmptyDonationCodable() throws {
    let empty = Tips.EmptyDonation()
    let data = try JSONEncoder().encode(empty)
    _ = try JSONDecoder().decode(Tips.EmptyDonation.self, from: data)
}

func exerciseTipGroupPriority() {
    let group = TipGroup(.ordered)
    precondition(group.priority == .ordered)
    precondition(TipGroup.Priority.firstAvailable != .ordered)
    var hasher = Hasher()
    group.priority.hash(into: &hasher)
    _ = TipGroup.Priority.firstAvailable.hashValue
    _ = TipGroup()
}

func tipKitRuntimeMain() async throws {
    TipsHostControl.resetForHostTests()
    assertErrorIdentities()
    assertStatusAndInvalidation()
    assertTimeRangesAndLimits()
    assertConfigurationOptions()
    try exerciseConfigure()
    exerciseTestingFlags()
    await exerciseActions()
    exerciseParametersAndRules()
    try await exerciseEvents()
    exerciseSendDonationHop()
    try exerciseEmptyDonationCodable()
    exerciseTipGroupPriority()
    print("TIPKIT_AGENT_RUNTIME_OK")
}

Task {
    do {
        try await tipKitRuntimeMain()
        exit(0)
    } catch {
        fatalError("TipKit runtime failed: \(error)")
    }
}
dispatchMain()
