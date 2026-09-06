import Foundation
import VideoSubscriberAccount

func testSubscriptionDefaultsAndStorage() {
    let subscription = VSSubscription()
    precondition(subscription.accessLevel == .unknown)
    precondition(subscription.billingIdentifier == nil)
    precondition(subscription.expirationDate == nil)
    precondition(subscription.tierIdentifiers.isEmpty)
    let date = Date(timeIntervalSince1970: 1_800_000_000)
    subscription.accessLevel = .paid
    subscription.billingIdentifier = "bill-1"
    subscription.expirationDate = date
    subscription.tierIdentifiers = ["gold", "sports"]
    precondition(subscription.accessLevel == .paid)
    precondition(subscription.billingIdentifier == "bill-1")
    precondition(subscription.expirationDate == date)
    precondition(subscription.tierIdentifiers == ["gold", "sports"])
}

func testSubscriptionRegistrationCenterSingleton() {
    let first = VSSubscriptionRegistrationCenter.default()
    let second = VSSubscriptionRegistrationCenter.default()
    precondition(first === second)
}

func testSubscriptionRegistrationCenterSetCurrent() {
    let center = VSSubscriptionRegistrationCenter.default()
    let subscription = VSSubscription()
    subscription.accessLevel = .freeWithAccount
    center.setCurrentSubscription(subscription)
    precondition(center.linuxCurrentSubscription === subscription)
    center.setCurrentSubscription(nil)
    precondition(center.linuxCurrentSubscription == nil)
}
