import Foundation
import StoreKit

private func expect(_ condition: Bool, _ message: String) {
    precondition(condition, message)
}

final class ReceiptRefreshDelegate: NSObject, SKRequestDelegate {
    var failed = 0
    var error: Error?
    func request(_ request: SKRequest, didFailWithError error: Error) {
        failed += 1
        self.error = error
    }
}

func testReceiptRefreshRequestFailsClosed() {
    let delegate = ReceiptRefreshDelegate()
    let request = SKReceiptRefreshRequest(receiptProperties: [
        SKReceiptPropertyIsExpired: true
    ])
    request.delegate = delegate
    request.start()
    expect(delegate.failed == 1, "fail-closed")
    expect(request.receiptProperties?[SKReceiptPropertyIsExpired] as? Bool == true, "properties kept")
    expect((delegate.error as? SKError)?.code == .unsupportedPlatform, "SKError")
}

func testSKOverlayModelsDoNotPresent() {
    let config = SKOverlay.AppConfiguration(appIdentifier: "123", position: .bottom)
    config.campaignToken = "camp"
    config.providerToken = "prov"
    config.customProductPageIdentifier = "page"
    config.latestReleaseID = "rel"
    config.userDismissible = false
    config.setAdditionalValue("v", forKey: "k")
    expect(config.additionalValue(forKey: "k") as? String == "v", "additional")
    config.setAdImpression(SKAdImpression())
    expect(config.appIdentifier == "123", "app")
    expect(config.position == .bottom, "bottom")
    expect(SKOverlay.Position.bottomRaised.rawValue == 1, "raised")
    let overlay = SKOverlay(configuration: config)
    overlay.delegate = nil
    overlay.present(in: UIWindowScene())
    expect(overlay.portablePresentCount == 1, "counted, no UI")
    overlay.dismiss(from: UIWindowScene())
    expect(overlay.portablePresentCount == 2, "dismiss counted")
    SKOverlay.dismiss(in: UIWindowScene())
    let clip = SKOverlay.AppClipConfiguration(position: .bottomRaised)
    clip.campaignToken = "c"
    clip.providerToken = "p"
    clip.customProductPageIdentifier = "page"
    clip.latestReleaseID = "rel"
    clip.setAdditionalValue(1, forKey: "n")
    expect(clip.additionalValue(forKey: "n") as? Int == 1, "clip additional")
    expect(clip.position == .bottomRaised, "clip")
    let context = SKOverlay.TransitionContext()
    var ran = false
    context.addAnimationBlock { ran = true }
    expect(ran, "animation block runs locally")
    context.add { ran = true }
    _ = context.startFrame
    _ = context.endFrame
    expect(overlay.configuration === config, "config")
}

func testSKStoreProductViewControllerLoadFailsClosed() {
    let controller = SKStoreProductViewController()
    controller.delegate = nil
    var seen = 0
    controller.loadProduct(withParameters: [
        SKStoreProductParameterITunesItemIdentifier: 1
    ]) { success, error in
        seen += 1
        expect(success == false, "no App Store")
        expect(error is StoreKitPortableError, "fail-closed")
    }
    expect(seen == 1, "completion")
    expect(controller.portableLoadCount == 1, "counted")
    controller.loadProduct(
        withParameters: [SKStoreProductParameterProductIdentifier: "x"],
        impression: SKAdImpression()
    ) { success, error in
        seen += 1
        expect(success == false, "impression load")
        expect(error is StoreKitPortableError, "fail-closed")
    }
    expect(seen == 2, "second completion")
}

func testSKCloudServiceEnumsAndConstants() {
    expect(SKCloudServiceAuthorizationStatus.notDetermined.rawValue == 0, "notDetermined")
    expect(SKCloudServiceAuthorizationStatus.denied.rawValue == 1, "denied")
    expect(SKCloudServiceAuthorizationStatus.restricted.rawValue == 2, "restricted")
    expect(SKCloudServiceAuthorizationStatus.authorized.rawValue == 3, "authorized")
    expect(SKCloudServiceCapability.musicCatalogPlayback.rawValue == 1, "playback")
    expect(SKCloudServiceCapability.musicCatalogSubscriptionEligible.rawValue == 2, "eligible")
    expect(SKCloudServiceCapability.addToCloudMusicLibrary.rawValue == 4, "library")
    expect(SKDownloadState.waiting.rawValue == 0, "waiting")
    expect(SKDownloadState.active.rawValue == 1, "active")
    expect(SKDownloadState.paused.rawValue == 2, "paused")
    expect(SKDownloadState.finished.rawValue == 3, "finished")
    expect(SKDownloadState.failed.rawValue == 4, "failed")
    expect(SKDownloadState.cancelled.rawValue == 5, "cancelled")
    expect(SKProductStorePromotionVisibility.default.rawValue == 0, "default")
    expect(SKProductStorePromotionVisibility.show.rawValue == 1, "show")
    expect(SKProductStorePromotionVisibility.hide.rawValue == 2, "hide")
    expect(SKReceiptPropertyIsExpired == "expired", "expired key")
    expect(SKReceiptPropertyIsRevoked == "revoked", "revoked key")
    expect(SKReceiptPropertyIsVolumePurchase == "volume", "volume key")
    expect(SKCloudServiceSetupAction.subscribe.rawValue == "subscribe", "subscribe")
    expect(SKCloudServiceController.authorizationStatus() == .denied, "denied on Linux")
}

func testSKStoreProductParameterConstants() {
    let constants = [
        SKStoreProductParameterITunesItemIdentifier,
        SKStoreProductParameterProductIdentifier,
        SKStoreProductParameterAffiliateToken,
        SKStoreProductParameterCampaignToken,
        SKStoreProductParameterProviderToken,
        SKStoreProductParameterAdNetworkIdentifier,
        SKStoreProductParameterAdNetworkCampaignIdentifier,
        SKStoreProductParameterAdNetworkNonce,
        SKStoreProductParameterAdNetworkTimestamp,
        SKStoreProductParameterAdNetworkAttributionSignature,
        SKStoreProductParameterAdNetworkSourceAppStoreIdentifier,
        SKStoreProductParameterAdNetworkSourceIdentifier,
        SKStoreProductParameterAdNetworkVersion,
        SKStoreProductParameterAdvertisingPartnerToken,
        SKStoreProductParameterCustomProductPageIdentifier,
    ]
    for value in constants {
        expect(!value.isEmpty, "parameter constant")
    }
    expect(SKDownloadTimeRemainingUnknown == -1, "unknown remaining")
}

func testSKPaymentDiscountAndPeriodUnit() {
    expect(SKProduct.PeriodUnit.day.rawValue == 0, "day")
    expect(SKProduct.PeriodUnit.week.rawValue == 1, "week")
    expect(SKProduct.PeriodUnit.month.rawValue == 2, "month")
    expect(SKProduct.PeriodUnit.year.rawValue == 3, "year")
}
