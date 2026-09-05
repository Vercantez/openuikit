@_spi(OpenUIKitHost) import MetricKit
import Foundation

func testMXLaunchTaskID() {
    let task = MXLaunchTaskID("extended-launch")
    mxRequire(task.rawValue == "extended-launch", "testMXLaunchTaskID: rawValue")
    mxRequire(MXLaunchTaskID(rawValue: "extended-launch") == task, "testMXLaunchTaskID: init(rawValue:)")
    mxRequire(MXLaunchTaskID("other") != task, "testMXLaunchTaskID: !=")
    var hasher = Hasher()
    task.hash(into: &hasher)
    mxRequire(task.hashValue == MXLaunchTaskID("extended-launch").hashValue, "testMXLaunchTaskID: hashValue")
}

private func requireLaunchFailClosed(_ body: () throws -> Void, _ message: String) {
    do {
        try body()
        fatalError("\(message): expected throw")
    } catch let error as MXError {
        mxRequire(error.code == .launchTaskInternalFailure, "\(message): MXError.Code")
        mxRequire(error.errorCode == 5, "\(message): raw 5")
        let cocoa = error as NSError
        mxRequire(cocoa.domain == MXErrorDomain, "\(message): domain")
        mxRequire(cocoa.code == 5, "\(message): NSError code 5")
    } catch {
        fatalError("\(message): expected MXError")
    }
}

func testExtendLaunchMeasurementFailClosed() {
    requireLaunchFailClosed({
        try MXMetricManager.extendLaunchMeasurement(forTaskID: MXLaunchTaskID(""))
    }, "testExtendLaunchMeasurementFailClosed: empty")
    requireLaunchFailClosed({
        try MXMetricManager.extendLaunchMeasurement(forTaskID: MXLaunchTaskID("task"))
    }, "testExtendLaunchMeasurementFailClosed: nonempty")
}

func testFinishExtendedLaunchMeasurementFailClosed() {
    requireLaunchFailClosed({
        try MXMetricManager.finishExtendedLaunchMeasurement(forTaskID: MXLaunchTaskID(""))
    }, "testFinishExtendedLaunchMeasurementFailClosed: empty")
    requireLaunchFailClosed({
        try MXMetricManager.finishExtendedLaunchMeasurement(
            forTaskID: MXLaunchTaskID("never-started")
        )
    }, "testFinishExtendedLaunchMeasurementFailClosed: never-started")
}
