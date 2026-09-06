import WirelessInsights
import Foundation

// Future clean EC2 dependency-identity client. Isolated host-gate success
// against toolchain Foundation is not integrated guest WirelessInsights success.
// This file is not compiled by the sealed host gate.
//
// Expected EC2 steps (no local Docker):
// 1. Build guest Foundation (and its dylib).
// 2. Build WirelessInsights with that module on `-I` / `-L`.
// 3. Link this file as a client that imports WirelessInsights and Foundation.
// 4. Run with `LD_LIBRARY_PATH` covering those dylibs.
// 5. Confirm `WIRELESSINSIGHTS_DEPENDENCY_IDENTITY_OK` and that
//    `libWirelessInsights.dylib` was loaded.

private func assertNotWirelessInsightsType<T>(_ value: T) {
    precondition(!String(reflecting: type(of: value)).hasPrefix("WirelessInsights."))
}

func assertFoundationIdentity() {
    let start = Date(timeIntervalSince1970: 1_700_000_000)
    assertNotWirelessInsightsType(start)

    let interval: TimeInterval = ServicePrediction.QuantizedInterval.short
    assertNotWirelessInsightsType(interval)
    precondition(interval == 60)

    let score = ServicePrediction.ConfidenceScore(
        prediction: .high,
        startTime: .medium,
        duration: .low
    )
    let prediction = ServicePrediction(
        impact: .high,
        predictedStartTime: start,
        predictedInterval: interval,
        confidenceScore: score
    )
    precondition(prediction.predictedStartTime == start)
    precondition(prediction.predictedInterval == interval)

    let provider = ServicePredictionProvider()
    _ = provider

    _ = Foundation.Date.self
    _ = Foundation.TimeInterval.self
    _ = Foundation.JSONEncoder.self
    _ = Foundation.JSONDecoder.self
}

func wirelessInsightsDependencyIdentityMain() {
    assertFoundationIdentity()
    print("WIRELESSINSIGHTS_DEPENDENCY_IDENTITY_OK")
}
