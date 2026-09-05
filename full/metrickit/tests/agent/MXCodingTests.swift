@_spi(OpenUIKitHost) import MetricKit
import Foundation

func testSupportInitWithCoder() {
    let coder = MXDummyCoder()
    mxRequire(MXAverage<UnitDuration>(coder: coder) == nil, "testSupportInitWithCoder: MXAverage")
    mxRequire(MXHistogram<UnitDuration>(coder: coder) == nil, "testSupportInitWithCoder: MXHistogram")
    mxRequire(
        MXHistogramBucket<UnitDuration>(coder: coder) == nil,
        "testSupportInitWithCoder: MXHistogramBucket"
    )
    let average = MXAverage(
        averageMeasurement: Measurement(value: 1, unit: UnitDuration.seconds)
    )
    average.encode(with: coder)
    MXHistogram<UnitDuration>().encode(with: coder)
}

func testMetricInitWithCoder() {
    let coder = MXDummyCoder()
    mxRequire(MXMetric(coder: coder) == nil, "testMetricInitWithCoder: MXMetric")
    mxRequire(MXBackgroundExitData(coder: coder) == nil, "testMetricInitWithCoder: MXBackgroundExitData")
    mxRequire(MXForegroundExitData(coder: coder) == nil, "testMetricInitWithCoder: MXForegroundExitData")
    mxRequire(MXSignpostIntervalData(coder: coder) == nil, "testMetricInitWithCoder: MXSignpostIntervalData")
    MXMetric().encode(with: coder)
    MXBackgroundExitData().encode(with: coder)
    MXForegroundExitData().encode(with: coder)
    MXSignpostIntervalData().encode(with: coder)
}

func testDiagnosticInitWithCoder() {
    let coder = MXDummyCoder()
    mxRequire(MXCallStackTree(coder: coder) == nil, "testDiagnosticInitWithCoder: MXCallStackTree")
    mxRequire(
        MXCrashDiagnosticObjectiveCExceptionReason(coder: coder) == nil,
        "testDiagnosticInitWithCoder: exception reason"
    )
    mxRequire(MXDiagnostic(coder: coder) == nil, "testDiagnosticInitWithCoder: MXDiagnostic")
    mxRequire(MXMetaData(coder: coder) == nil, "testDiagnosticInitWithCoder: MXMetaData")
    mxRequire(MXSignpostRecord(coder: coder) == nil, "testDiagnosticInitWithCoder: MXSignpostRecord")
    MXCallStackTree().encode(with: coder)
    MXCrashDiagnosticObjectiveCExceptionReason().encode(with: coder)
    MXDiagnostic().encode(with: coder)
    MXMetaData().encode(with: coder)
    MXSignpostRecord().encode(with: coder)
}

func testPayloadInitWithCoder() {
    let coder = MXDummyCoder()
    mxRequire(MXMetricPayload(coder: coder) == nil, "testPayloadInitWithCoder: MXMetricPayload")
    mxRequire(MXDiagnosticPayload(coder: coder) == nil, "testPayloadInitWithCoder: MXDiagnosticPayload")
    MXMetricPayload().encode(with: coder)
    MXDiagnosticPayload().encode(with: coder)
}
