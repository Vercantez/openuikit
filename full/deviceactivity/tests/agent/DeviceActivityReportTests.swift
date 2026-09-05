import DeviceActivity
import Foundation

func testDeviceActivityReportContext() {
    let context = DeviceActivityReport.Context("total-activity")
    deviceActivityRequire(context.rawValue == "total-activity", "init(_)")
    let fromRaw = DeviceActivityReport.Context(rawValue: "total-activity")
    deviceActivityRequire(fromRaw == context, "equal context")
    deviceActivityRequire(context != DeviceActivityReport.Context("other"), "unequal")
    var hasher = Hasher()
    context.hash(into: &hasher)
    deviceActivityRequire(context.hashValue == fromRaw.hashValue, "hashValue")
}

func testDeviceActivityReportInitAndBody() {
    let day = DateInterval(start: Date(timeIntervalSince1970: 0), duration: 3600)
    let filter = DeviceActivityFilter(segment: .daily(during: day), devices: .all)
    let report = DeviceActivityReport(.init("total-activity"), filter: filter)
    deviceActivityRequire(report.context.rawValue == "total-activity", "context")
    deviceActivityRequire(report.filter == filter, "filter")
    deviceActivityRequire(report.body.context == report.context, "body identity")
    let defaulted = DeviceActivityReport(DeviceActivityReport.Context("empty"))
    deviceActivityRequire(defaulted.filter.users == nil, "default filter")
}

func testDeviceActivityReportBuilderBuildBlock() {
    let first = DeviceActivityReport.Context("a")
    let second = DeviceActivityReport.Context("b")
    deviceActivityRequire(
        DeviceActivityReportBuilder.buildBlock(first) == first,
        "one scene"
    )
    deviceActivityRequire(
        DeviceActivityReportBuilder.buildBlock(first, second) == first,
        "two scenes keep first"
    )
    deviceActivityRequire(
        DeviceActivityReportBuilder.buildBlock(
            first, second, first, second, first, second, first, second, first, second
        ) == first,
        "ten scenes keep first"
    )
}

func testDeviceActivityResultsIteration() {
    let results = DeviceActivityResults([1, 2, 3])
    let iterator = results.makeAsyncIterator()
    deviceActivityRequire(iterator.nextSynchronously() == 1, "first")
    deviceActivityRequire(iterator.nextSynchronously() == 2, "second")
    deviceActivityRequire(iterator.nextSynchronously() == 3, "third")
    deviceActivityRequire(iterator.nextSynchronously() == nil, "exhausted")
    let empty = DeviceActivityResults<Int>()
    let emptyIterator = empty.makeAsyncIterator()
    deviceActivityRequire(emptyIterator.nextSynchronously() == nil, "empty")
    deviceActivityRequire(
        DeviceActivityResults<Int>.AsyncIterator.self
            == DeviceActivityResults<Int>.Iterator<Int>.self,
        "AsyncIterator alias"
    )
}

func testDeviceActivityMonitoringErrorSurface() {
    let cases: [DeviceActivityCenter.MonitoringError] = [
        .excessiveActivities,
        .intervalTooLong,
        .intervalTooShort,
        .invalidDateComponents,
        .unauthorized,
    ]
    deviceActivityRequire(Set(cases).count == 5, "five cases")
    deviceActivityRequire(
        DeviceActivityCenter.MonitoringError.unauthorized
            != .intervalTooShort,
        "unequal"
    )
    deviceActivityRequire(
        DeviceActivityCenter.MonitoringError.unauthorized.errorDescription
            == "The calling process isn’t authorized to monitor device activity.",
        "unauthorized description"
    )
    deviceActivityRequire(
        DeviceActivityCenter.MonitoringError.intervalTooShort.errorDescription
            == "The activity’s schedule has an interval that is too short.",
        "short description"
    )
    deviceActivityRequire(
        DeviceActivityCenter.MonitoringError.intervalTooLong.errorDescription
            == "The activity’s schedule has an interval that is too long.",
        "long description"
    )
    deviceActivityRequire(
        DeviceActivityCenter.MonitoringError.excessiveActivities.recoverySuggestion
            != nil,
        "recovery"
    )
    deviceActivityRequire(
        DeviceActivityCenter.MonitoringError.unauthorized.helpAnchor == nil,
        "helpAnchor default"
    )
    deviceActivityRequire(
        DeviceActivityCenter.MonitoringError.unauthorized.failureReason == nil,
        "failureReason default"
    )
    deviceActivityRequire(
        DeviceActivityCenter.MonitoringError.unauthorized.localizedDescription
            .contains("authorized"),
        "localizedDescription"
    )
    var hasher = Hasher()
    DeviceActivityCenter.MonitoringError.unauthorized.hash(into: &hasher)
    deviceActivityRequire(
        DeviceActivityCenter.MonitoringError.unauthorized.hashValue
            == DeviceActivityCenter.MonitoringError.unauthorized.hashValue,
        "hashValue"
    )
}

func testDeviceActivityViewStubIdentity() {
    let report = DeviceActivityReport(DeviceActivityReport.Context("stub"))
    deviceActivityRequire(report.brightness(0.5).context == report.context, "brightness")
    deviceActivityRequire(report.padding().context == report.context, "padding")
    deviceActivityRequire(report.navigationViewStyle(0).context == report.context, "nav")
}
