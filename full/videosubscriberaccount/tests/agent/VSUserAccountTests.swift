import Foundation
import VideoSubscriberAccount

func testUserAccountInitDefaults() {
    let account = VSUserAccount(accountType: .free, updateURL: nil)
    precondition(account.accountType == .free)
    precondition(account.updateURL == nil)
    precondition(account.identifier == nil)
    precondition(account.isSignedOut == false)
    precondition(account.deviceCategory == .other)
    precondition(account.tierIdentifiers == nil)
    precondition(account.appleSubscription == nil)
    precondition(account.billingIdentifier == nil)
    precondition(account.authenticationData == nil)
    precondition(account.isFromCurrentDevice)
    precondition(account.requiresSystemTrust == false)
    precondition(account.accountProviderIdentifier == nil)
    precondition(account.subscriptionBillingCycleEndDate == nil)
}

func testUserAccountPropertyStorage() {
    let url = URL(string: "https://example.invalid/update")!
    let date = Date(timeIntervalSince1970: 1_700_000_000)
    var account = VSUserAccount(accountType: .paid, updateURL: url)
    account.identifier = "user-1"
    account.isSignedOut = true
    account.tierIdentifiers = ["sports"]
    account.billingIdentifier = "bill"
    account.authenticationData = "auth"
    account.requiresSystemTrust = true
    account.accountProviderIdentifier = "provider.a"
    account.subscriptionBillingCycleEndDate = date
    let apple = VSAppleSubscription(customerID: "cust", productCodes: ["sku"])
    account.appleSubscription = apple
    precondition(account.accountType == .paid)
    precondition(account.updateURL == url)
    precondition(account.identifier == "user-1")
    precondition(account.isSignedOut)
    precondition(account.tierIdentifiers == ["sports"])
    precondition(account.billingIdentifier == "bill")
    precondition(account.authenticationData == "auth")
    precondition(account.requiresSystemTrust)
    precondition(account.accountProviderIdentifier == "provider.a")
    precondition(account.subscriptionBillingCycleEndDate == date)
    precondition(account.appleSubscription == apple)
    precondition(account.deviceCategory == .other)
    precondition(account.isFromCurrentDevice)
}

func testUserAccountEqualityAndHash() {
    let url = URL(string: "https://example.invalid/a")!
    var left = VSUserAccount(accountType: .free, updateURL: url)
    var right = VSUserAccount(accountType: .free, updateURL: url)
    precondition(left == right)
    precondition(left.hashValue == right.hashValue)
    left.identifier = "a"
    precondition(left != right)
    right.identifier = "a"
    precondition(left == right)
    var hasher = Hasher()
    left.hash(into: &hasher)
    _ = hasher.finalize()
}

func testAppleSubscriptionInitEqualityAndHash() {
    let first = VSAppleSubscription(customerID: "c1", productCodes: ["p1", "p2"])
    let second = VSAppleSubscription(customerID: "c1", productCodes: ["p1", "p2"])
    let third = VSAppleSubscription(customerID: "c2", productCodes: ["p1"])
    precondition(first.customerID == "c1")
    precondition(first.productCodes == ["p1", "p2"])
    precondition(first == second)
    precondition(first != third)
    precondition(first.hashValue == second.hashValue)
    var hasher = Hasher()
    first.hash(into: &hasher)
    _ = hasher.finalize()
}

func testAutoSignInTokenFields() {
    let token = VSUserAccountManager.AutoSignInToken(
        authorization: .granted,
        value: "secret"
    )
    precondition(token.authorization == .granted)
    precondition(token.value == "secret")
    let empty = VSUserAccountManager.AutoSignInToken(authorization: .denied)
    precondition(empty.authorization == .denied)
    precondition(empty.value == nil)
    precondition(token != empty)
}

func testAutoSignInTokenUpdateContext() {
    let context = VSUserAccountManager.AutoSignInTokenUpdateContext(authorization: .granted)
    precondition(context.authorization == .granted)
    let other = VSUserAccountManager.AutoSignInTokenUpdateContext(authorization: .notDetermined)
    precondition(context != other)
}

func testUserAccountManagerShared() {
    let first = VSUserAccountManager.shared
    let second = VSUserAccountManager.shared
    precondition(first === second)
}
