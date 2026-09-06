import Foundation

/// Linux starting point for Apple's public `WirelessInsights` module.
///
/// Value types (`ServicePrediction`, `Confidence`, `Impact`,
/// `ConfidenceScore`, `QuantizedInterval`) and `ServicePredictionError`
/// are real. There is no cellular modem metrics daemon, WirelessInsights
/// XPC service, or `com.apple.developer.wireless-insights.service-predictions`
/// entitlement on Linux: `ServicePredictionProvider.servicePredictions`
/// fail-closes with `ServicePredictionError.unsupportedDevice`, matching
/// Apple's documented behavior on Mac Catalyst, visionOS, macOS on Apple
/// silicon, and Wi-Fi-only iPad. See `README.md`.
enum WirelessInsightsModuleMarker {
    static let name = "WirelessInsights"
}

/// Linux host-test control. Hidden from ordinary `import WirelessInsights`
/// clients and not part of Apple's public WirelessInsights surface.
@_spi(OpenUIKitHost)
public enum WirelessInsightsHostControl {
    /// Synchronous twin of the first `servicePredictions` pull.
    /// The async sequence never suspends; it always throws this error.
    public static func firstServicePredictions(
        _ provider: ServicePredictionProvider
    ) throws -> [ServicePrediction] {
        try provider.linuxFirstPredictions()
    }
}
