@_spi(OpenUIKitHost) import TipKit
import Foundation

func testDisplayFrequencyDailyAgainstFixedClock() {
    TipsHostControl.resetForHostTests()
    let start = Date(timeIntervalSince1970: 1_700_000_000)
    TipsHostControl.setNow(start)
    try! Tips.configure([.displayFrequency(.daily)])
    let tip = EligibleHostTip()
    precondition(tip.status == .available)
    precondition(tip.shouldDisplay)
    tip.recordDisplayForHost()
    precondition(TipsHostControl.lastDisplayDate() == start)
    precondition(tip.status == .available)
    precondition(tip.shouldDisplay == false)
    TipsHostControl.setNow(start.addingTimeInterval(86_399))
    precondition(tip.shouldDisplay == false)
    TipsHostControl.setNow(start.addingTimeInterval(86_400))
    precondition(tip.shouldDisplay)
}

func testDisplayFrequencyHourlyWeeklyMonthlyImmediate() {
    let start = Date(timeIntervalSince1970: 1_710_000_000)
    let cases: [(Tips.ConfigurationOption.DisplayFrequency, TimeInterval?)] = [
        (.immediate, nil),
        (.hourly, 3_600),
        (.weekly, 604_800),
        (.monthly, 2_592_000),
    ]
    for (frequency, seconds) in cases {
        TipsHostControl.resetForHostTests()
        TipsHostControl.setNow(start)
        try! Tips.configure([.displayFrequency(frequency)])
        let tip = EligibleHostTip()
        precondition(tip.shouldDisplay)
        tip.recordDisplayForHost()
        if let seconds {
            TipsHostControl.setNow(start.addingTimeInterval(seconds - 1))
            precondition(tip.shouldDisplay == false)
            TipsHostControl.setNow(start.addingTimeInterval(seconds))
            precondition(tip.shouldDisplay)
        } else {
            precondition(tip.shouldDisplay)
        }
    }
}

func testIgnoresDisplayFrequencyBypassesThrottle() {
    TipsHostControl.resetForHostTests()
    let start = Date(timeIntervalSince1970: 1_720_000_000)
    TipsHostControl.setNow(start)
    try! Tips.configure([.displayFrequency(.daily)])
    EligibleHostTip().recordDisplayForHost()
    precondition(EligibleHostTip().shouldDisplay == false)
    precondition(FrequencyIgnoreHostTip().shouldDisplay)
    precondition(FrequencyIgnoreHostTip().status == .available)
}
