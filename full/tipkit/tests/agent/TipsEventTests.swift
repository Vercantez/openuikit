@_spi(OpenUIKitHost) import TipKit
import Foundation

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
