@_spi(OpenUIKitHost) import TipKit
import Foundation

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
