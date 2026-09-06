import Foundation

/// A class that provides cellular service predictions about upcoming events
/// and anomalies.
///
/// Linux has no WirelessInsights daemon, modem metrics, or service-predictions
/// entitlement. Iterating `servicePredictions` throws
/// `ServicePredictionError.unsupportedDevice` immediately, matching Apple's
/// documented fail-closed behavior on Mac Catalyst, visionOS, macOS on Apple
/// silicon, and Wi-Fi-only iPad. `connectionError` is reserved for recoverable
/// stream-setup failure on a supported device and is never produced here.
public final class ServicePredictionProvider {
    public init() {}

    /// An asynchronous sequence of current predictions.
    public var servicePredictions: any AsyncSequence<[ServicePrediction], any Error> {
        UnsupportedDevicePredictionSequence()
    }

    func linuxFirstPredictions() throws -> [ServicePrediction] {
        throw ServicePredictionError.unsupportedDevice
    }
}

/// Fail-closed sequence: the first pull throws `unsupportedDevice` and never
/// yields a (possibly empty) success snapshot.
struct UnsupportedDevicePredictionSequence: AsyncSequence {
    typealias Element = [ServicePrediction]
    typealias Failure = any Error

    struct AsyncIterator: AsyncIteratorProtocol {
        typealias Element = [ServicePrediction]
        typealias Failure = any Error

        func next() async throws -> [ServicePrediction]? {
            throw ServicePredictionError.unsupportedDevice
        }
    }

    func makeAsyncIterator() -> AsyncIterator {
        AsyncIterator()
    }
}
