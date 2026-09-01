import Foundation
@_spi(OpenUIKitHost) import TipKit

private struct FavoriteTrailTip: Tip {
    var title: Text { Text("Save as a Favorite") }
    var message: Text? { Text("Favorites stay at the top of the list.") }
    var image: Image? { Image(systemName: "star") }

    var actions: [Tips.Action] {
        Tips.Action(id: "learn-more", title: "Learn More")
        Tips.Action(id: "dismiss", title: "Dismiss")
    }

    var options: [any TipOption] {
        Tips.MaxDisplayCount(5)
        Tips.IgnoresDisplayFrequency(true)
    }
}

private struct OrderedAlphaTip: Tip {
    var title: Text { Text("Alpha") }
}

private struct OrderedBetaTip: Tip {
    var title: Text { Text("Beta") }
}

private struct DonationPayload: Codable, Hashable, Sendable {
    var city: String
    var count: Int
}

@MainActor
func tipKitRuntimeMain() async {
        let unconfigured = FavoriteTrailTip()
        precondition(unconfigured.status == .pending)
        precondition(!unconfigured.shouldDisplay)
        precondition(unconfigured.id.contains("FavoriteTrailTip"))
        precondition(unconfigured.title.portableValue == "Save as a Favorite")
        precondition(unconfigured.message?.portableValue == "Favorites stay at the top of the list.")
        precondition(unconfigured.image?.portableSystemName == "star")
        precondition(unconfigured.actions.count == 2)
        precondition(unconfigured.actions[0].id == "learn-more")
        precondition(unconfigured.actions[0].index == 0)
        precondition(unconfigured.actions[1].index == 1)

        do {
            _ = try Tips.ConfigurationOption.DatastoreLocation.groupContainer(
                identifier: "group.example.tips"
            )
            fatalError("groupContainer must fail closed")
        } catch {
            precondition((error as? TipKitError) == .missingGroupContainerEntitlements)
        }

        let location = Tips.ConfigurationOption.DatastoreLocation.url(
            URL(fileURLWithPath: "/tmp/tipkit-portable")
        )
        precondition(
            location == Tips.ConfigurationOption.DatastoreLocation.url(
                URL(fileURLWithPath: "/tmp/tipkit-portable")
            )
        )
        precondition(
            Tips.ConfigurationOption.DatastoreLocation.applicationDefault
                != location
        )
        precondition(
            Tips.ConfigurationOption.CloudKitContainer.automatic
                != .named("iCloud.example")
        )
        precondition(
            Tips.ConfigurationOption.DisplayFrequency.immediate
                != .daily
        )

        try! Tips.configure([
            .displayFrequency(.immediate),
            .datastoreLocation(.applicationDefault),
            .cloudKitContainer(.automatic)
        ])

        do {
            try Tips.configure()
            fatalError("second configure must fail closed")
        } catch {
            precondition((error as? TipKitError) == .tipsDatastoreAlreadyConfigured)
        }

        let tip = FavoriteTrailTip()
        precondition(tip.status == .available)
        precondition(tip.shouldDisplay)

        let erased = AnyTip(tip)
        precondition(erased.id == tip.id)
        precondition(erased.title.portableValue == tip.title.portableValue)
        precondition(erased.shouldDisplay)

        tip.invalidate(reason: .tipClosed)
        precondition(tip.status == .invalidated(.tipClosed))
        precondition(!tip.shouldDisplay)
        await tip.resetEligibility()
        precondition(tip.status == .available)

        let action = Tips.Action(id: "custom") { Text("Custom") }
        precondition(action.id == "custom")
        precondition(action.label().portableValue == "Custom")

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

        struct BlockedByRuleTip: Tip {
            var title: Text { Text("Blocked") }
            var rules: [Tips.Rule] {
                Tips.Rule(.conjunction, [
                    Tips.Rule.portable { true },
                    Tips.Rule.portable { false }
                ])
            }
        }
        precondition(BlockedByRuleTip().status == .pending)
        precondition(Tips.Rule.CompoundOperation.conjunction != .disjunction)

        OrderedAlphaTip().invalidate(reason: .actionPerformed)
        let group = TipGroup(.ordered) {
            OrderedAlphaTip()
            OrderedBetaTip()
        }
        precondition(group.currentTip?.id == OrderedBetaTip().id)

        let firstAvailable = TipGroup(.firstAvailable) {
            FavoriteTrailTip()
            OrderedBetaTip()
        }
        precondition(firstAvailable.currentTip?.id == FavoriteTrailTip().id)

        let view = TipView(FavoriteTrailTip(), arrowEdge: .top)
        precondition(view.portableTip?.id == FavoriteTrailTip().id)
        precondition(view.portableShouldDisplay)

        let configuration = TipViewStyleConfiguration(tip: FavoriteTrailTip())
        precondition(configuration.title?.portableValue == "Save as a Favorite")
        precondition(configuration.actions.count == 2)
        _ = MiniTipViewStyle.miniTip

        Tips.hideAllTipsForTesting()
        precondition(!FavoriteTrailTip().shouldDisplay)
        Tips.showAllTipsForTesting()
        precondition(FavoriteTrailTip().shouldDisplay)
        Tips.hideTipsForTesting([OrderedBetaTip.self])
        precondition(!OrderedBetaTip().shouldDisplay)
        Tips.showTipsForTesting([OrderedBetaTip.self])
        precondition(OrderedBetaTip().shouldDisplay)

        try! Tips.resetDatastore()
        await FavoriteTrailTip().resetEligibility()
        await OrderedAlphaTip().resetEligibility()
        precondition(FavoriteTrailTip().status == .available)

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
