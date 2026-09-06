import Foundation
@_spi(OpenUIKitHost) import WirelessInsights

func testServicePredictionProviderType() {
    let provider = ServicePredictionProvider()
    wiExpect(
        type(of: provider) == ServicePredictionProvider.self,
        "ServicePredictionProvider metatype"
    )
    let other = ServicePredictionProvider()
    wiExpect(provider !== other, "class identity")
}

func testServicePredictionProviderInit() {
    let provider = ServicePredictionProvider()
    _ = provider
    wiExpect(true, "init() constructs")
}

func testServicePredictionProviderServicePredictions() {
    let provider = ServicePredictionProvider()
    let sequence = provider.servicePredictions
    _ = sequence
    do {
        _ = try WirelessInsightsHostControl.firstServicePredictions(provider)
        wiExpect(false, "Linux must not yield a success snapshot")
    } catch let error as ServicePredictionError {
        wiExpect(error == .unsupportedDevice, "fail-closed unsupportedDevice")
    } catch {
        wiExpect(false, "wrong error type \(error)")
    }
}
