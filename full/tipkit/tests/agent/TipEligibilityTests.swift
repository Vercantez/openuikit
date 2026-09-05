@_spi(OpenUIKitHost) import TipKit
import Foundation

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
