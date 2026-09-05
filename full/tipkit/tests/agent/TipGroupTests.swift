@_spi(OpenUIKitHost) import TipKit
import Foundation

func testTipGroupPriority() {
    let group = TipGroup(.ordered)
    precondition(group.priority == .ordered)
    precondition(TipGroup.Priority.firstAvailable != .ordered)
    var hasher = Hasher()
    group.priority.hash(into: &hasher)
    _ = TipGroup.Priority.firstAvailable.hashValue
    _ = TipGroup()
}

func testTipGroupCurrentTip() {
    TipsHostControl.resetForHostTests()
    let pending = PendingHostTip()
    let eligible = EligibleHostTip()
    let group = TipGroup(.ordered) {
        pending
        eligible
    }
    let seen = TipKitLocked<String?>(nil)
    let ready = DispatchSemaphore(value: 0)
    Task { @MainActor in
        seen.store(group.currentTip?.id)
        ready.signal()
    }
    tipKitWait(ready, "currentTip did not resolve on MainActor")
    precondition(seen.load() == "eligible-host")

    let first = TipKitLocked<String?>(nil)
    let firstReady = DispatchSemaphore(value: 0)
    Task {
        for await tip in group.currentTipUpdates {
            first.store(tip.id)
            firstReady.signal()
            break
        }
    }
    tipKitWait(firstReady, "currentTipUpdates did not yield")
    precondition(first.load() == "eligible-host")
}

func testHideShowAllAndTypedTestingFlags() {
    TipsHostControl.resetForHostTests()
    let tip = EligibleHostTip()
    Tips.hideAllTipsForTesting()
    var flags = TipsHostControl.testingFlags()
    precondition(flags.hideAll)
    precondition(flags.showAll == false)
    precondition(tip.shouldDisplay == false)
    Tips.showAllTipsForTesting()
    flags = TipsHostControl.testingFlags()
    precondition(flags.showAll)
    precondition(flags.hideAll == false)
    precondition(tip.shouldDisplay)

    TipsHostControl.resetForHostTests()
    let pending = PendingHostTip()
    precondition(pending.shouldDisplay == false)
    Tips.showTipsForTesting([PendingHostTip.self])
    precondition(pending.shouldDisplay)
    Tips.hideTipsForTesting([PendingHostTip.self])
    precondition(pending.shouldDisplay == false)
}
