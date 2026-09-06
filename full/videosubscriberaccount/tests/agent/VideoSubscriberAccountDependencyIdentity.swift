import Foundation
import VideoSubscriberAccount

// Isolated host-gate success against toolchain Foundation is not integrated
// guest-Foundation success. This probe is for a future clean EC2 run that
// builds guest Foundation first, then VideoSubscriberAccount with that `-I` / `-L`.
// The host gate does not compile this file.

func videoSubscriberAccountDependencyIdentityProbe() {
    let data = Data("video-subscriber-account".utf8)
    let url = URL(string: "https://example.invalid/vsa")!
    let date = Date(timeIntervalSince1970: 1_700_000_000)
    precondition(type(of: data) == Data.self)
    precondition(type(of: url) == URL.self)
    precondition(type(of: date) == Date.self)
    precondition(!String(reflecting: type(of: data)).hasPrefix("VideoSubscriberAccount."))
    precondition(!String(reflecting: type(of: url)).hasPrefix("VideoSubscriberAccount."))
    precondition(!String(reflecting: type(of: date)).hasPrefix("VideoSubscriberAccount."))

    var account = VSUserAccount(accountType: .paid, updateURL: url)
    account.subscriptionBillingCycleEndDate = date
    account.authenticationData = String(data: data, encoding: .utf8)
    precondition(account.updateURL == url)
    precondition(account.subscriptionBillingCycleEndDate == date)
    precondition(account.authenticationData == "video-subscriber-account")

    let metadata = VSAccountMetadata(
        authenticationExpirationDate: date,
        verificationData: data
    )
    precondition(metadata.authenticationExpirationDate == date)
    precondition(metadata.verificationData == data)
}

#if VIDEOSUBSCRIBERACCOUNT_IDENTITY_MAIN
videoSubscriberAccountDependencyIdentityProbe()
print("VIDEOSUBSCRIBERACCOUNT_DEPENDENCY_IDENTITY_OK")
#endif
