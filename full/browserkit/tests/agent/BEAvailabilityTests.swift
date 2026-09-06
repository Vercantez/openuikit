import BrowserKit
import Foundation

func testBEAvailabilityIsNSObject() {
    let first = BEAvailability()
    let second = BEAvailability()
    precondition(first is NSObject)
    precondition(type(of: first) == BEAvailability.self)
    precondition(first !== second)
    let asObject: NSObject = first
    precondition(asObject === first)
    precondition(first.isEqual(first))
    precondition(!first.isEqual(second))
}

func testBEAvailabilityIsEligibleFailClosed() {
    var calls = 0
    var eligibleBox: Bool?
    var errorBox: (any Error)?
    BEAvailability.isEligible(for: .webBrowser) { eligible, error in
        calls += 1
        eligibleBox = eligible
        errorBox = error
    }
    precondition(calls == 1)
    precondition(eligibleBox == false)
    guard let typed = errorBox as? BrowserKitHostError else {
        preconditionFailure("expected BrowserKitHostError")
    }
    precondition(typed == .eligibilityUnavailable)
    let nsError = errorBox as NSError?
    precondition(nsError?.domain == "BrowserKit.Linux")
    precondition(nsError?.code == 1)
    precondition(nsError?.domain == BrowserKitHostError.errorDomain)
}
