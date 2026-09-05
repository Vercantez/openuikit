@_spi(OpenUIKitHost) import MetricKit
import Foundation

func testMetricPayloadGetters() {
    let begin = Date(timeIntervalSince1970: 1)
    let end = Date(timeIntervalSince1970: 2)
    let payload = MXMetricPayload(
        latestApplicationVersion: "9",
        includesMultipleApplicationVersions: true,
        timeStampBegin: begin,
        timeStampEnd: end,
        cpuMetrics: MXCPUMetric(),
        gpuMetrics: MXGPUMetric(),
        cellularConditionMetrics: MXCellularConditionMetric(),
        applicationTimeMetrics: MXAppRunTimeMetric(),
        locationActivityMetrics: MXLocationActivityMetric(),
        networkTransferMetrics: MXNetworkTransferMetric(),
        applicationLaunchMetrics: MXAppLaunchMetric(),
        applicationResponsivenessMetrics: MXAppResponsivenessMetric(),
        diskIOMetrics: MXDiskIOMetric(),
        memoryMetrics: MXMemoryMetric(),
        displayMetrics: MXDisplayMetric(),
        animationMetrics: MXAnimationMetric(),
        applicationExitMetrics: MXAppExitMetric(),
        diskSpaceUsageMetrics: MXDiskSpaceUsageMetric(),
        signpostMetrics: [MXSignpostMetric(signpostName: "n")],
        metaData: MXMetaData(bundleIdentifier: "payload.app")
    )
    mxRequire(payload.latestApplicationVersion == "9", "testMetricPayloadGetters: version")
    mxRequire(payload.includesMultipleApplicationVersions, "testMetricPayloadGetters: multi")
    mxRequire(payload.timeStampBegin == begin, "testMetricPayloadGetters: begin")
    mxRequire(payload.timeStampEnd == end, "testMetricPayloadGetters: end")
    mxRequire(payload.cpuMetrics != nil, "testMetricPayloadGetters: cpu")
    mxRequire(payload.gpuMetrics != nil, "testMetricPayloadGetters: gpu")
    mxRequire(payload.cellularConditionMetrics != nil, "testMetricPayloadGetters: cellular")
    mxRequire(payload.applicationTimeMetrics != nil, "testMetricPayloadGetters: time")
    mxRequire(payload.locationActivityMetrics != nil, "testMetricPayloadGetters: location")
    mxRequire(payload.networkTransferMetrics != nil, "testMetricPayloadGetters: network")
    mxRequire(payload.applicationLaunchMetrics != nil, "testMetricPayloadGetters: launch")
    mxRequire(payload.applicationResponsivenessMetrics != nil, "testMetricPayloadGetters: resp")
    mxRequire(payload.diskIOMetrics != nil, "testMetricPayloadGetters: diskio")
    mxRequire(payload.memoryMetrics != nil, "testMetricPayloadGetters: memory")
    mxRequire(payload.displayMetrics != nil, "testMetricPayloadGetters: display")
    mxRequire(payload.animationMetrics != nil, "testMetricPayloadGetters: animation")
    mxRequire(payload.applicationExitMetrics != nil, "testMetricPayloadGetters: exits")
    mxRequire(payload.diskSpaceUsageMetrics != nil, "testMetricPayloadGetters: space")
    mxRequire(payload.signpostMetrics?.count == 1, "testMetricPayloadGetters: signposts")
    mxRequire(payload.metaData?.bundleIdentifier == "payload.app", "testMetricPayloadGetters: meta")
}

func testDiagnosticPayloadGetters() {
    let diagBegin = Date(timeIntervalSince1970: 3)
    let diagEnd = Date(timeIntervalSince1970: 4)
    let diagnostics = MXDiagnosticPayload(
        cpuExceptionDiagnostics: [MXCPUExceptionDiagnostic()],
        diskWriteExceptionDiagnostics: [MXDiskWriteExceptionDiagnostic()],
        hangDiagnostics: [MXHangDiagnostic()],
        appLaunchDiagnostics: [MXAppLaunchDiagnostic()],
        crashDiagnostics: [MXCrashDiagnostic()],
        timeStampBegin: diagBegin,
        timeStampEnd: diagEnd
    )
    mxRequire(diagnostics.cpuExceptionDiagnostics?.count == 1, "testDiagnosticPayloadGetters: diag cpu")
    mxRequire(diagnostics.diskWriteExceptionDiagnostics?.count == 1, "testDiagnosticPayloadGetters: diag disk")
    mxRequire(diagnostics.hangDiagnostics?.count == 1, "testDiagnosticPayloadGetters: diag hang")
    mxRequire(diagnostics.appLaunchDiagnostics?.count == 1, "testDiagnosticPayloadGetters: diag launch")
    mxRequire(diagnostics.crashDiagnostics?.count == 1, "testDiagnosticPayloadGetters: diag crash")
    mxRequire(diagnostics.timeStampBegin == diagBegin, "testDiagnosticPayloadGetters: diag begin")
    mxRequire(diagnostics.timeStampEnd == diagEnd, "testDiagnosticPayloadGetters: diag end")
}
