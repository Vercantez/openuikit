import Foundation
import IdentityLookup

func testClassificationActionRawValues() {
    precondition(ILClassificationAction.none.rawValue == 0)
    precondition(ILClassificationAction.reportNotJunk.rawValue == 1)
    precondition(ILClassificationAction.reportJunk.rawValue == 2)
    precondition(ILClassificationAction.reportJunkAndBlockSender.rawValue == 3)
    precondition(ILClassificationAction(rawValue: 0) == ILClassificationAction.none)
    precondition(ILClassificationAction(rawValue: 1) == .reportNotJunk)
    precondition(ILClassificationAction(rawValue: 2) == .reportJunk)
    precondition(ILClassificationAction(rawValue: 3) == .reportJunkAndBlockSender)
    precondition(ILClassificationAction(rawValue: 4) == nil)
    precondition(ILClassificationAction.none != .reportJunk)
    precondition(ILClassificationAction.reportJunk.hashValue == ILClassificationAction.reportJunk.hashValue)
    var hasher = Hasher()
    ILClassificationAction.reportNotJunk.hash(into: &hasher)
    _ = hasher.finalize()
}

func testMessageFilterActionRawValues() {
    precondition(ILMessageFilterAction.none.rawValue == 0)
    precondition(ILMessageFilterAction.allow.rawValue == 1)
    precondition(ILMessageFilterAction.junk.rawValue == 2)
    precondition(ILMessageFilterAction.promotion.rawValue == 3)
    precondition(ILMessageFilterAction.transaction.rawValue == 4)
    precondition(ILMessageFilterAction.filter == .junk)
    precondition(ILMessageFilterAction.filter.rawValue == 2)
    precondition(ILMessageFilterAction(rawValue: 0) == ILMessageFilterAction.none)
    precondition(ILMessageFilterAction(rawValue: 1) == .allow)
    precondition(ILMessageFilterAction(rawValue: 2) == .junk)
    precondition(ILMessageFilterAction(rawValue: 3) == .promotion)
    precondition(ILMessageFilterAction(rawValue: 4) == .transaction)
    precondition(ILMessageFilterAction(rawValue: 5) == nil)
    precondition(ILMessageFilterAction.allow != .junk)
    precondition(ILMessageFilterAction.promotion.hashValue == ILMessageFilterAction.promotion.hashValue)
    var hasher = Hasher()
    ILMessageFilterAction.transaction.hash(into: &hasher)
    _ = hasher.finalize()
}

func testMessageFilterSubActionRawValues() {
    precondition(ILMessageFilterSubAction.none.rawValue == 0)
    precondition(ILMessageFilterSubAction.transactionalOthers.rawValue == 10000)
    precondition(ILMessageFilterSubAction.transactionalFinance.rawValue == 10001)
    precondition(ILMessageFilterSubAction.transactionalOrders.rawValue == 10002)
    precondition(ILMessageFilterSubAction.transactionalReminders.rawValue == 10003)
    precondition(ILMessageFilterSubAction.transactionalHealth.rawValue == 10004)
    precondition(ILMessageFilterSubAction.transactionalWeather.rawValue == 10005)
    precondition(ILMessageFilterSubAction.transactionalCarrier.rawValue == 10006)
    precondition(ILMessageFilterSubAction.transactionalRewards.rawValue == 10007)
    precondition(ILMessageFilterSubAction.transactionalPublicServices.rawValue == 10008)
    precondition(ILMessageFilterSubAction.promotionalOthers.rawValue == 20000)
    precondition(ILMessageFilterSubAction.promotionalOffers.rawValue == 20001)
    precondition(ILMessageFilterSubAction.promotionalCoupons.rawValue == 20002)
    precondition(ILMessageFilterSubAction(rawValue: 0) == ILMessageFilterSubAction.none)
    precondition(ILMessageFilterSubAction(rawValue: 10000) == .transactionalOthers)
    precondition(ILMessageFilterSubAction(rawValue: 20002) == .promotionalCoupons)
    precondition(ILMessageFilterSubAction(rawValue: 1) == nil)
    precondition(ILMessageFilterSubAction.promotionalOffers != .promotionalCoupons)
    precondition(
        ILMessageFilterSubAction.transactionalFinance.hashValue
            == ILMessageFilterSubAction.transactionalFinance.hashValue
    )
    var hasher = Hasher()
    ILMessageFilterSubAction.transactionalHealth.hash(into: &hasher)
    _ = hasher.finalize()
}

func testCallLookupExtensionStatusCases() {
    precondition(CallLookupExtensionStatus.enabled != .disabled)
    precondition(CallLookupExtensionStatus.enabled == .enabled)
    precondition(CallLookupExtensionStatus.disabled == .disabled)
    precondition(
        CallLookupExtensionStatus.enabled.hashValue
            == CallLookupExtensionStatus.enabled.hashValue
    )
    var hasher = Hasher()
    CallLookupExtensionStatus.disabled.hash(into: &hasher)
    _ = hasher.finalize()
}
