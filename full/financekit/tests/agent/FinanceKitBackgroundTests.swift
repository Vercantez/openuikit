import Foundation
import FinanceKit

private struct RecordingBackgroundExtension: BackgroundDeliveryExtension {
    func willTerminate() async {}
    func didReceiveData(for types: [FinanceStore.BackgroundDataType]) async {
        _ = types
    }
}

func testBackgroundDeliveryExtensionProviding() {
    let probe: any BackgroundDeliveryExtensionProviding = RecordingBackgroundExtension()
    financeKitSink(probe)
}

func testBackgroundDeliveryExtensionConfiguration() {
    let probe = RecordingBackgroundExtension()
    let typed: any BackgroundDeliveryExtension = probe
    financeKitSink(typed)
}
