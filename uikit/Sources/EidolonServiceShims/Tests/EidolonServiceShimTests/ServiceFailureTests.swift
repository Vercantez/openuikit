import Foundation
import XCTest
import Keys
import ARAnalytics
import Stripe
import EidolonLaunchCompat

final class ServiceFailureTests: XCTestCase {
    func testLaunchRefusesBeforeConstructingApplicationOrProvider() {
        var applicationConstructions = 0
        XCTAssertThrowsError(try EidolonLaunchCompat.withLaunchPreflight {
            applicationConstructions += 1
        }) { error in
            guard case .serviceCredentialsUnavailable? = error as? EidolonLaunchError else {
                return XCTFail("Launch must report the unavailable credential boundary")
            }
        }
        XCTAssertEqual(applicationConstructions, 0)
    }

    func testUnavailableKeysDoNotSelectSuccessfulFixtureResponses() {
        let keys = EidolonKeys()
        XCTAssertFalse(EidolonKeys.servicesAvailable)
        // This is the unchanged app predicate at APIKeys.swift:31.
        let stubResponses = keys.artsyAPIClientKey.count < 2 || keys.artsyAPIClientSecret.count < 2
        XCTAssertFalse(stubResponses)
        XCTAssertEqual(Set([
            keys.artsyAPIClientKey, keys.artsyAPIClientSecret,
            keys.hockeyProductionSecret, keys.hockeyBetaSecret, keys.segmentWriteKey,
            keys.cardflightProductionAPIClientKey, keys.cardflightProductionMerchantAccountToken,
            keys.stripeProductionPublishableKey, keys.cardflightStagingAPIClientKey,
            keys.cardflightStagingMerchantAccountToken, keys.stripeStagingPublishableKey,
        ]), ["OPENUIKIT_SERVICE_UNAVAILABLE"])
    }

    func testAnalyticsConfigurationAndEventsNeverEnableService() {
        ARAnalytics.setup(withAnalytics: [
            ARHockeyAppBetaID: "unavailable", ARHockeyAppLiveID: "unavailable",
            ARSegmentioWriteKey: "unavailable",
        ])
        ARAnalytics.event("Session Started")
        ARAnalytics.event("Placed a bid", withProperties: ["top_bidder": false])
        XCTAssertFalse(ARAnalytics.isEnabled)
    }

    func testStripeCallsBackOnceWithFailureAndNoToken() {
        Stripe.setDefaultPublishableKey("unavailable")
        let card = STPCardParams()
        card.number = "not-a-card"
        card.expMonth = 1
        card.expYear = 2000
        card.cvc = "unavailable"
        card.address.postalCode = "unavailable"
        var callbacks = 0
        STPAPIClient.shared().createToken(withCard: card) { token, error in
            callbacks += 1
            XCTAssertNil(token)
            guard case .serviceUnavailable? = error as? EidolonStripeError else {
                return XCTFail("Token failure must provide the app's force-unwrapped error")
            }
        }
        XCTAssertEqual(callbacks, 1)
        STPAPIClient.shared().createToken(withCard: card, completion: nil)
    }
}
