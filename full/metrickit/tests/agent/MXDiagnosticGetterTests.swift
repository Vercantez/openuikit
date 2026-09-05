@_spi(OpenUIKitHost) import MetricKit
import Foundation

func testMetaDataGetters() {
    let meta = MXMetaData(
        regionFormat: "US",
        osVersion: "Linux",
        deviceType: "test",
        applicationBuildVersion: "1",
        platformArchitecture: "x86_64",
        lowPowerModeEnabled: true,
        isTestFlightApp: false,
        pid: 42,
        bundleIdentifier: "example.app"
    )
    mxRequire(meta.regionFormat == "US", "testMetaDataGetters: region")
    mxRequire(meta.osVersion == "Linux", "testMetaDataGetters: os")
    mxRequire(meta.deviceType == "test", "testMetaDataGetters: device")
    mxRequire(meta.applicationBuildVersion == "1", "testMetaDataGetters: build")
    mxRequire(meta.platformArchitecture == "x86_64", "testMetaDataGetters: arch")
    mxRequire(meta.lowPowerModeEnabled, "testMetaDataGetters: low power")
    mxRequire(!meta.isTestFlightApp, "testMetaDataGetters: testflight")
    mxRequire(meta.pid == 42, "testMetaDataGetters: pid")
    mxRequire(meta.bundleIdentifier == "example.app", "testMetaDataGetters: bundle")
}

func testSignpostRecordGetters() {
    let record = MXSignpostRecord(
        subsystem: "app",
        category: "ui",
        name: "frame",
        beginTimeStamp: Date(timeIntervalSince1970: 10),
        endTimeStamp: Date(timeIntervalSince1970: 11),
        duration: Measurement(value: 1, unit: .seconds),
        isInterval: true
    )
    mxRequire(record.subsystem == "app", "testSignpostRecordGetters: subsystem")
    mxRequire(record.category == "ui", "testSignpostRecordGetters: category")
    mxRequire(record.name == "frame", "testSignpostRecordGetters: name")
    mxRequire(record.beginTimeStamp.timeIntervalSince1970 == 10, "testSignpostRecordGetters: begin")
    mxRequire(record.endTimeStamp?.timeIntervalSince1970 == 11, "testSignpostRecordGetters: end")
    mxRequire(record.duration?.value == 1, "testSignpostRecordGetters: duration")
    mxRequire(record.isInterval, "testSignpostRecordGetters: interval")
}

func testExceptionReasonGetters() {
    let reason = MXCrashDiagnosticObjectiveCExceptionReason(
        composedMessage: "boom",
        formatString: "%@",
        arguments: ["x"],
        exceptionType: "NSException",
        className: "Thing",
        exceptionName: "Test"
    )
    mxRequire(reason.composedMessage == "boom", "testExceptionReasonGetters: composed")
    mxRequire(reason.formatString == "%@", "testExceptionReasonGetters: format")
    mxRequire(reason.arguments == ["x"], "testExceptionReasonGetters: args")
    mxRequire(reason.exceptionType == "NSException", "testExceptionReasonGetters: exc type")
    mxRequire(reason.exceptionName == "Test", "testExceptionReasonGetters: name")
}

func testMXCrashDiagnosticObjectiveCExceptionReasonClassName() {
    let reason = MXCrashDiagnosticObjectiveCExceptionReason(
        composedMessage: "boom",
        formatString: "%@",
        arguments: ["x"],
        exceptionType: "NSException",
        className: "Thing",
        exceptionName: "Test"
    )
    let observed: String = reason.className
    mxRequire(
        observed == "Thing",
        "testMXCrashDiagnosticObjectiveCExceptionReasonClassName: stored className"
    )
#if canImport(ObjectiveC)
    let asObject: NSObject = reason
    mxRequire(
        asObject.className == "Thing",
        "testMXCrashDiagnosticObjectiveCExceptionReasonClassName: NSObject override"
    )
#endif
}

func testDiagnosticGetters() {
    let meta = MXMetaData(pid: 42, bundleIdentifier: "example.app")
    let tree = MXCallStackTree()
    let record = MXSignpostRecord(name: "frame")
    let diagnostic = MXDiagnostic(applicationVersion: "1.0", metaData: meta, signpostData: [record])
    mxRequire(diagnostic.applicationVersion == "1.0", "testDiagnosticGetters: version")
    mxRequire(diagnostic.metaData.pid == 42, "testDiagnosticGetters: meta")
    mxRequire(diagnostic.signpostData?.count == 1, "testDiagnosticGetters: signposts")
    _ = tree
}

func testAppLaunchDiagnosticGetters() {
    let tree = MXCallStackTree()
    let launch = MXAppLaunchDiagnostic(
        callStackTree: tree,
        launchDuration: Measurement(value: 2, unit: .seconds)
    )
    mxRequire(launch.launchDuration.value == 2, "testAppLaunchDiagnosticGetters: duration")
    mxRequire(launch.callStackTree === tree, "testAppLaunchDiagnosticGetters: tree")
}

func testCPUExceptionDiagnosticGetters() {
    let tree = MXCallStackTree()
    let cpuExc = MXCPUExceptionDiagnostic(
        totalCPUTime: Measurement(value: 3, unit: .seconds),
        totalSampledTime: Measurement(value: 4, unit: .seconds)
    )
    mxRequire(cpuExc.totalCPUTime.value == 3, "testCPUExceptionDiagnosticGetters: cpu time")
    mxRequire(cpuExc.totalSampledTime.value == 4, "testCPUExceptionDiagnosticGetters: sampled")
    mxRequire(cpuExc.callStackTree !== tree, "testCPUExceptionDiagnosticGetters: distinct tree")
}

func testCrashDiagnosticGetters() {
    let tree = MXCallStackTree()
    let reason = MXCrashDiagnosticObjectiveCExceptionReason(exceptionName: "Test")
    let crash = MXCrashDiagnostic(
        callStackTree: tree,
        terminationReason: "signal",
        virtualMemoryRegionInfo: "stack",
        exceptionType: NSNumber(value: 1),
        exceptionCode: NSNumber(value: 2),
        signal: NSNumber(value: 11),
        exceptionReason: reason
    )
    mxRequire(crash.callStackTree === tree, "testCrashDiagnosticGetters: tree")
    mxRequire(crash.terminationReason == "signal", "testCrashDiagnosticGetters: term")
    mxRequire(crash.virtualMemoryRegionInfo == "stack", "testCrashDiagnosticGetters: vm")
    mxRequire(crash.exceptionType == NSNumber(value: 1), "testCrashDiagnosticGetters: type")
    mxRequire(crash.exceptionCode == NSNumber(value: 2), "testCrashDiagnosticGetters: code")
    mxRequire(crash.signal == NSNumber(value: 11), "testCrashDiagnosticGetters: signal")
    mxRequire(crash.exceptionReason?.exceptionName == "Test", "testCrashDiagnosticGetters: reason")
}

func testDiskWriteExceptionDiagnosticGetters() {
    let tree = MXCallStackTree()
    let disk = MXDiskWriteExceptionDiagnostic(totalWritesCaused: Measurement(value: 9, unit: .bytes))
    mxRequire(disk.totalWritesCaused.value == 9, "testDiskWriteExceptionDiagnosticGetters: writes")
    mxRequire(disk.callStackTree !== tree, "testDiskWriteExceptionDiagnosticGetters: distinct tree")
}

func testHangDiagnosticGetters() {
    let tree = MXCallStackTree()
    let hang = MXHangDiagnostic(hangDuration: Measurement(value: 5, unit: .seconds))
    mxRequire(hang.hangDuration.value == 5, "testHangDiagnosticGetters: hang")
    mxRequire(hang.callStackTree !== tree, "testHangDiagnosticGetters: distinct tree")
}

func testCallStackTreeType() {
    let tree = MXCallStackTree()
    mxRequire(tree.isKind(of: NSObject.self), "testCallStackTreeType: NSObject")
}
