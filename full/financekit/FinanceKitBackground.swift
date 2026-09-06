import Foundation

public protocol BackgroundDeliveryExtensionProviding {
    func willTerminate() async
    func didReceiveData(for types: [FinanceStore.BackgroundDataType]) async
}

public protocol BackgroundDeliveryExtension: AppExtension, BackgroundDeliveryExtensionProviding {}

struct FinanceKitUnavailableExtensionConfiguration: AppExtensionConfiguration {}

extension BackgroundDeliveryExtension {
    @MainActor @preconcurrency public var configuration: some AppExtensionConfiguration {
        FinanceKitUnavailableExtensionConfiguration()
    }
}
