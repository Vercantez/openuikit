import Foundation
import WirelessInsights

func testServicePredictionQuantizedIntervalType() {
    wiExpect(
        ServicePrediction.QuantizedInterval.minimal
            < ServicePrediction.QuantizedInterval.short,
        "minimal < short"
    )
    wiExpect(
        ServicePrediction.QuantizedInterval.short
            < ServicePrediction.QuantizedInterval.medium,
        "short < medium"
    )
    wiExpect(
        ServicePrediction.QuantizedInterval.medium
            < ServicePrediction.QuantizedInterval.long,
        "medium < long"
    )
}

func testServicePredictionQuantizedIntervalMinimal() {
    wiExpect(ServicePrediction.QuantizedInterval.minimal == 10, "minimal is 10 seconds")
}

func testServicePredictionQuantizedIntervalShort() {
    wiExpect(ServicePrediction.QuantizedInterval.short == 60, "short is 60 seconds")
}

func testServicePredictionQuantizedIntervalMedium() {
    wiExpect(ServicePrediction.QuantizedInterval.medium == 300, "medium is five minutes")
}

func testServicePredictionQuantizedIntervalLong() {
    wiExpect(ServicePrediction.QuantizedInterval.long == 600, "long is 10 minutes")
    wiExpect(
        ServicePrediction.QuantizedInterval.long
            > ServicePrediction.QuantizedInterval.medium,
        "long is more than five minutes"
    )
}
