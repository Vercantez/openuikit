@_spi(OpenUIKitHost) import WiFiAware
import Foundation

private func waExpect(_ condition: Bool, _ message: String) {
    precondition(condition, message)
}

func testThroughputCapacityRatio() {
    let metrics = WAPerformanceReport.TransmitLatencyMetrics(
        accessCategory: .bestEffort,
        average: Duration.milliseconds(12)
    )
    let report = WAPerformanceReport(
        timestamp: Date(timeIntervalSince1970: 1),
        localTimestamp: ContinuousClock.now,
        throughputCeiling: 100,
        throughputCapacity: 40,
        transmitLatency: [.bestEffort: metrics],
        signalStrength: 0.5
    )
    waExpect(report.throughputCapacityRatio == 0.4, "capacity / ceiling")
    waExpect(report.throughputCeiling == 100, "ceiling")
    waExpect(report.throughputCapacity == 40, "capacity")
    let missingCeiling = WAPerformanceReport(
        timestamp: Date(),
        localTimestamp: ContinuousClock.now,
        throughputCeiling: nil,
        throughputCapacity: 10,
        transmitLatency: [:],
        signalStrength: nil
    )
    waExpect(missingCeiling.throughputCapacityRatio == nil, "ratio nil without ceiling")
    let zeroCeiling = WAPerformanceReport(
        timestamp: Date(),
        localTimestamp: ContinuousClock.now,
        throughputCeiling: 0,
        throughputCapacity: 10,
        transmitLatency: [:],
        signalStrength: nil
    )
    waExpect(zeroCeiling.throughputCapacityRatio == nil, "ratio nil when ceiling is 0")
}

func testPerformanceReportCodable() {
    let metrics = WAPerformanceReport.TransmitLatencyMetrics(
        accessCategory: .interactiveVoice,
        average: .seconds(1)
    )
    let report = WAPerformanceReport(
        timestamp: Date(timeIntervalSince1970: 1),
        localTimestamp: ContinuousClock.now,
        throughputCeiling: 100,
        throughputCapacity: 40,
        transmitLatency: [.interactiveVoice: metrics],
        signalStrength: 0.5
    )
    let encoded = try! JSONEncoder().encode(report)
    let decoded = try! JSONDecoder().decode(WAPerformanceReport.self, from: encoded)
    waExpect(decoded.timestamp.timeIntervalSince1970 == 1, "timestamp")
    waExpect(decoded.signalStrength == 0.5, "signal")
    waExpect(
        decoded.transmitLatency[.interactiveVoice]?.accessCategory == .interactiveVoice,
        "latency category"
    )
    _ = decoded.localTimestamp
    let _: WAPerformanceReport = decoded
}

func testTransmitLatencyMetrics() {
    let metrics = WAPerformanceReport.TransmitLatencyMetrics(
        accessCategory: .background,
        average: Duration.milliseconds(8)
    )
    waExpect(metrics.accessCategory == .background, "metrics category")
    waExpect(metrics.average == Duration.milliseconds(8), "metrics average")
    let encoded = try! JSONEncoder().encode(metrics)
    let decoded = try! JSONDecoder().decode(
        WAPerformanceReport.TransmitLatencyMetrics.self,
        from: encoded
    )
    waExpect(decoded.accessCategory == .background, "metrics Codable")
}
