import Foundation
@_spi(OpenUIKitHost) import TipKit

private struct DonationPayload: Codable, Hashable, Sendable {
    var city: String
    var count: Int
}

func tipKitRuntimeMain() async {
    do {
        _ = try Tips.ConfigurationOption.DatastoreLocation.groupContainer(
            identifier: "group.example.tips"
        )
        fatalError("groupContainer must fail closed")
    } catch {
        precondition((error as? TipKitError) == .missingGroupContainerEntitlements)
    }

    let urlLocation = Tips.ConfigurationOption.DatastoreLocation.url(
        URL(fileURLWithPath: "/tmp/tipkit-unpersisted")
    )
    precondition(
        urlLocation == Tips.ConfigurationOption.DatastoreLocation.url(
            URL(fileURLWithPath: "/tmp/tipkit-unpersisted")
        )
    )
    precondition(
        Tips.ConfigurationOption.DatastoreLocation.applicationDefault != urlLocation
    )
    do {
        try Tips.configure([.datastoreLocation(urlLocation)])
        fatalError("URL datastore must fail closed")
    } catch {
        precondition((error as? TipKitError) == .urlDatastoreUnavailable)
    }

    precondition(
        Tips.ConfigurationOption.CloudKitContainer.automatic != .named("iCloud.example")
    )
    do {
        try Tips.configure([.cloudKitContainer(.automatic)])
        fatalError("CloudKit configure must fail closed")
    } catch {
        precondition((error as? TipKitError) == .cloudKitUnavailable)
    }

    precondition(
        Tips.ConfigurationOption.DisplayFrequency.immediate != .daily
    )

    try! Tips.configure([
        .displayFrequency(.immediate),
        .datastoreLocation(.applicationDefault)
    ])

    do {
        try Tips.configure()
        fatalError("second configure must fail closed")
    } catch {
        precondition((error as? TipKitError) == .tipsDatastoreAlreadyConfigured)
    }

    precondition(Tips.eligibilityStatus(id: "favorite.trail") == .available)

    Tips.invalidateEligibility(id: "favorite.trail", reason: .tipClosed)
    precondition(
        Tips.eligibilityStatus(id: "favorite.trail") == .invalidated(.tipClosed)
    )
    Tips.resetEligibility(id: "favorite.trail")
    precondition(Tips.eligibilityStatus(id: "favorite.trail") == .available)

    let blockedRule = Tips.Rule(
        .conjunction,
        [Tips.Rule.evaluated { true }, Tips.Rule.evaluated { false }]
    )
    precondition(
        Tips.eligibilityStatus(id: "blocked.rule", rules: [blockedRule]) == .pending
    )
    let allowedRule = Tips.Rule(
        .disjunction,
        [Tips.Rule.evaluated { false }, Tips.Rule.evaluated { true }]
    )
    precondition(
        Tips.eligibilityStatus(id: "allowed.rule", rules: [allowedRule]) == .available
    )
    precondition(Tips.Rule.CompoundOperation.conjunction != .disjunction)

    let capped = Tips.eligibilityStatus(
        id: "capped.tip",
        options: [Tips.MaxDisplayCount(5), Tips.IgnoresDisplayFrequency(true)]
    )
    precondition(capped == .available)

    let event = Tips.Event<DonationPayload>(id: "visited-city")
    await event.donate(DonationPayload(city: "lisbon", count: 1))
    await event.donate(DonationPayload(city: "lisbon", count: 2))
    await event.donate(DonationPayload(city: "porto", count: 1))
    precondition(event.donations.count == 3)
    precondition(event.donations[0].city == "lisbon")

    let recent = event.donations.donatedWithin(.day)
    precondition(recent.count == 3)
    let largest = event.donations.largestSubset(groupedBy: \.city)
    precondition(largest.count == 2)
    precondition(largest[0].city == "lisbon")
    let smallest = event.donations.smallestSubset(groupedBy: \.city)
    precondition(smallest.count == 1)
    precondition(smallest[0].city == "porto")

    try! await event.deleteDonations()
    precondition(event.donations.isEmpty)

    let emptyEvent = Tips.Event(id: "opened-app")
    await emptyEvent.donate()
    precondition(emptyEvent.donations.count == 1)

    let limited = Tips.Event<DonationPayload>(
        id: "limited",
        donationLimit: Tips.DonationLimit(maximumCount: 1, maximumAge: .week)
    )
    await limited.donate(DonationPayload(city: "a", count: 1))
    await limited.donate(DonationPayload(city: "b", count: 1))
    precondition(limited.donations.count == 1)
    precondition(limited.donations[0].city == "b")

    let parameter = Tips.Parameter(wrappedValue: false, id: "has-seen")
    precondition(parameter.wrappedValue == false)
    parameter.wrappedValue = true
    precondition(Tips.Parameter(wrappedValue: false, id: "has-seen").wrappedValue == true)

    let transient = Tips.Parameter(
        wrappedValue: 7,
        id: "transient-count",
        .transient
    )
    transient.wrappedValue = 99
    precondition(
        Tips.Parameter(wrappedValue: 7, id: "transient-count", .transient).wrappedValue == 7
    )

    Tips.hideAllTipsForTesting()
    precondition(Tips.eligibilityStatus(id: "favorite.trail") == .pending)
    Tips.showAllTipsForTesting()
    precondition(Tips.eligibilityStatus(id: "favorite.trail") == .available)

    try! Tips.resetDatastore()
    Tips.resetEligibility(id: "favorite.trail")
    precondition(Tips.eligibilityStatus(id: "favorite.trail") == .available)

    precondition(TipKitError.invalidPredicateValueType != .tipsDatastoreAlreadyConfigured)
    precondition(
        TipKitError.missingGroupContainerEntitlements.errorDescription?.isEmpty == false
    )
    precondition(Tips.DonationTimeRange.hour != .day)
    precondition(Tips.DonationTimeRange.minutes(2) == Tips.DonationTimeRange.minutes(2))
    precondition(Tips.Status.pending != .available)
    precondition(Tips.InvalidationReason.tipClosed != .actionPerformed)

    let encodedEmpty = try! JSONEncoder().encode(Tips.EmptyDonation())
    _ = try! JSONDecoder().decode(Tips.EmptyDonation.self, from: encodedEmpty)

    print("TIPKIT_AGENT_RUNTIME_OK")
}

await tipKitRuntimeMain()
