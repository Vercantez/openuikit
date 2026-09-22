// Every test here would FAIL if a shim fabricated success: a completion
// reporting success, a token/intent/payment option appearing, an identity
// being adopted, an event being retained, or an image replacing the
// placeholder. Call shapes are copied from the ios-oss call sites named in
// each shim's header.
import Foundation
import XCTest
import AlamofireImage
import BrazeKit
import BrazeUI
import FacebookCore
import FacebookLogin
import Firebase
import Segment
import SegmentBrazeUI
import Statsig
import StripeApplePay
import StripePaymentSheet
import UIKit
#if canImport(PassKit)
import PassKit
#endif

final class FirebaseShimTests: XCTestCase {
    func testConfigureCreatesNoApp() {
        FirebaseApp.configure()
        XCTAssertNil(FirebaseApp.app())
    }

    func testRemoteConfigFetchAndActivateFailsWithTheConnectionClassError() {
        let done = expectation(description: "completion")
        var calls = 0
        RemoteConfig.remoteConfig().fetchAndActivate { status, error in
            calls += 1
            XCTAssertEqual(status, .error)
            let ns = error as NSError?
            // AppDelegate.swift:499-500 treats exactly this as a connection error.
            XCTAssertEqual(ns?.domain, RemoteConfigErrorDomain)
            XCTAssertEqual(ns?.code, RemoteConfigError.internalError.rawValue)
            done.fulfill()
        }
        wait(for: [done], timeout: 2)
        XCTAssertEqual(calls, 1)
    }

    func testFetchAndActivateNeverSucceed() {
        let fetched = expectation(description: "fetch")
        let activated = expectation(description: "activate")
        let rc = RemoteConfig.remoteConfig()
        rc.fetch { status, error in
            XCTAssertEqual(status, .failure)
            XCTAssertNotNil(error)
            fetched.fulfill()
        }
        rc.activate { changed, error in
            XCTAssertFalse(changed)
            XCTAssertNotNil(error)
            activated.fulfill()
        }
        wait(for: [fetched, activated], timeout: 2)
        XCTAssertEqual(rc.lastFetchStatus, .noFetchYet)
    }

    func testDefaultsAreNotServedBackAsIfFetched() {
        let rc = RemoteConfig.remoteConfig()
        rc.setDefaults(["some_feature": NSNumber(value: true)])
        let value = rc.configValue(forKey: "some_feature")
        XCTAssertFalse(value.boolValue)
        XCTAssertEqual(value.stringValue, "")
        XCTAssertEqual(value.source, .static)
    }

    func testUpdateListenerNeverFires() {
        let never = expectation(description: "listener")
        never.isInverted = true
        let registration = RemoteConfig.remoteConfig().addOnConfigUpdateListener { _, _ in never.fulfill() }
        wait(for: [never], timeout: 0.3)
        registration.remove()
    }

    func testMockSubclassShapeFromTheAppCompiles() {
        // Library/MockRemoteConfigClient.swift subclasses the value type.
        final class MockValue: RemoteConfigValue {
            var bool = false
            override var boolValue: Bool { bool }
        }
        let v = MockValue()
        v.bool = true
        XCTAssertTrue(v.boolValue)
        XCTAssertNotNil(ConfigUpdateListenerRegistration())
    }

    func testCrashlyticsRetainsNothing() {
        Crashlytics.crashlytics().record(error: NSError(domain: "x", code: 1))
        Crashlytics.crashlytics().log(format: "%@", arguments: getVaList(["event"]))
        XCTAssertEqual(Crashlytics.crashlytics().pendingReports, 0)
    }

    func testConsentIsDropped() {
        // AppDelegate.swift:456 shape; also proves Firebase's `Analytics`
        // and Segment's resolve by member in one file, as in AppDelegate.
        Analytics.setConsent([.analyticsStorage: .denied, .adStorage: .denied,
                              .adUserData: .denied, .adPersonalization: .denied])
        XCTAssertEqual(FirebaseAnalytics.Analytics.consentSettingsRecorded, 0)
        let segment: Segment.Analytics = Segment.Analytics(configuration: Configuration(writeKey: "k"))
        XCTAssertEqual(segment.queuedEventCount, 0)
    }
}

@MainActor
final class FacebookShimTests: XCTestCase {
    func testLoginFailsAndNeverProducesAToken() {
        let manager = LoginManager()
        manager.defaultAudience = .friends
        let done = expectation(description: "handler")
        var sawResult = false
        manager.logIn(permissions: ["public_profile", "email", "user_friends"], from: nil) { result, error in
            if let result, !result.isCancelled { sawResult = true; _ = result.token?.tokenString }
            let ns = error as NSError?
            XCTAssertEqual(ns?.domain, LoginManager.shimErrorDomain)
            // No FBSDK localized keys: the app's own strings are shown.
            XCTAssertNil(ns?.userInfo[ErrorLocalizedTitleKey])
            XCTAssertNil(ns?.userInfo[ErrorLocalizedDescriptionKey])
            done.fulfill()
        }
        wait(for: [done], timeout: 2)
        XCTAssertFalse(sawResult)
        XCTAssertNil(AccessToken.current)
        manager.logOut()
    }

    func testOpenURLIsNotHandled() {
        FacebookCore.Settings.shared.isEventDataUsageLimited = true
        FacebookCore.Settings.shared.appID = "demo"
        let app = UIApplication.shared
        FacebookCore.ApplicationDelegate.shared.application(app, didFinishLaunchingWithOptions: nil)
        XCTAssertFalse(FacebookCore.ApplicationDelegate.shared.application(
            app, open: URL(string: "fb123://authorize")!, options: [:]))
    }
}

@MainActor
final class StripeShimTests: XCTestCase {
    final class Context: STPAuthenticationContext {
        let vc = UIViewController()
        func authenticationPresentingViewController() -> UIViewController { vc }
    }

    func testConfirmPaymentAndSetupIntentFail() {
        STPAPIClient.shared.publishableKey = "pk_test"
        STPAPIClient.shared.configuration.appleMerchantIdentifier = "merchant.test"
        let context = Context()
        let pay = expectation(description: "pay")
        let setup = expectation(description: "setup")
        let params = STPPaymentIntentParams(clientSecret: "pi_123_secret")
        params.paymentMethodId = "pm_1"
        STPPaymentHandler.shared().confirmPayment(params, with: context) { status, intent, error in
            XCTAssertEqual(status, .failed)
            XCTAssertNil(intent)
            XCTAssertNotNil(error)
            // Must not look like a real card decline (PostCampaignCheckout:462).
            XCTAssertNotEqual(error?.domain, STPError.stripeDomain)
            pay.fulfill()
        }
        STPPaymentHandler.shared().confirmSetupIntent(
            STPSetupIntentConfirmParams(clientSecret: "seti_123_secret"), with: context
        ) { status, intent, error in
            XCTAssertEqual(status, .failed)
            XCTAssertNil(intent)
            XCTAssertNotNil(error)
            setup.fulfill()
        }
        wait(for: [pay, setup], timeout: 2)
    }

    func testRetrieveSetupIntentReturnsNothing() {
        let done = expectation(description: "retrieve")
        STPAPIClient.shared.retrieveSetupIntent(withClientSecret: "seti_1") { intent, error in
            XCTAssertNil(intent?.paymentMethodID)
            XCTAssertNil(intent)
            XCTAssertNotNil(error)
            done.fulfill()
        }
        wait(for: [done], timeout: 2)
    }

    func testPaymentSheetCannotBeCreated() {
        var configuration = PaymentSheet.Configuration()
        configuration.merchantDisplayName = "Kickstarter"
        configuration.allowsDelayedPaymentMethods = true
        configuration.defaultBillingDetails.email = "a@b.c"
        let done = expectation(description: "create")
        PaymentSheet.FlowController.create(setupIntentClientSecret: "seti_1", configuration: configuration) {
            result in
            if case .success = result { XCTFail("PaymentSheet must not be created") }
            done.fulfill()
        }
        wait(for: [done], timeout: 2)
    }

    #if canImport(PassKit)
    func testApplePayContextIsUnavailable() {
        final class Delegate: STPApplePayContextDelegate {
            func applePayContext(_: StripeApplePay.STPApplePayContext,
                                 didCreatePaymentMethod paymentMethod: StripePayments.STPPaymentMethod,
                                 paymentInformation _: PKPayment,
                                 completion: @escaping StripeApplePay.STPIntentClientSecretCompletionBlock) {}
            func applePayContext(_: StripeApplePay.STPApplePayContext,
                                 didCompleteWith status: StripePayments.STPPaymentStatus, error _: Error?) {}
        }
        let request = PKPaymentRequest()
        XCTAssertNil(STPApplePayContext(paymentRequest: request, delegate: Delegate()))
    }
    #endif
}

final class SegmentBrazeShimTests: XCTestCase {
    // Library/Tracking/Vendor/BrazeDebounceMiddleware.swift shape.
    final class Debounce: EventPlugin {
        weak var analytics: Segment.Analytics?
        let type = PluginType.before
        func identify(event: IdentifyEvent) -> IdentifyEvent? {
            var e = event
            e.integrations = try? event.integrations?.add(value: false, forKey: "Appboy")
            return e
        }
    }

    func testEventsAreDroppedAndIdentityIsNotAdopted() {
        let configuration = Configuration(writeKey: "write-key-staging")
            .flushAt(3)
            .flushInterval(10)
            .setTrackedApplicationLifecycleEvents([.applicationInstalled, .applicationUpdated,
                                                   .applicationOpened, .applicationBackgrounded])
        let analytics = Segment.Analytics(configuration: configuration)
        analytics.identify(userId: "42", traits: ["name": "x"])
        analytics.track(name: "CTA Clicked", properties: ["a": 1])
        XCTAssertNil(analytics.userId)
        XCTAssertEqual(analytics.anonymousId, "")
        XCTAssertEqual(analytics.queuedEventCount, 0)
        analytics.enabled = false
        analytics.reset()
    }

    func testBrazeDestinationNeverActivates() {
        var configured = false
        var ready = false
        let destination = BrazeDestination(additionalConfiguration: { configuration in
            configuration.triggerMinimumTimeInterval = 5
            configuration.logger.level = .debug
            configured = true
        }) { braze in
            braze.inAppMessagePresenter = BrazeUI.BrazeInAppMessageUI()
            ready = true
        }
        let analytics = Segment.Analytics(configuration: Configuration(writeKey: "k"))
        analytics.add(plugin: destination)
        let debounce = Debounce()
        analytics.add(plugin: debounce)
        XCTAssertTrue(debounce.analytics === analytics) // SDK add(plugin:) contract
        let settle = expectation(description: "settle")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { settle.fulfill() }
        wait(for: [settle], timeout: 2)
        XCTAssertFalse(configured)
        XCTAssertFalse(ready)
        XCTAssertNil(destination.braze)
    }

    func testJSONAddMatchesTheMiddlewareUse() throws {
        let integrations = try JSON(["Segment.io": true])
        XCTAssertEqual(try integrations.add(value: false, forKey: "Appboy"),
                       try JSON(["Segment.io": true, "Appboy": false]))
        XCTAssertThrowsError(try JSON.string("x").add(value: false, forKey: "k"))
    }

    func testPushAutomationShapeAndDelayedInitRecordNothing() {
        let automation: BrazeKit.Braze.Configuration.Push.Automation = true
        automation.automaticSetup = false
        automation.requestAuthorizationAtLaunch = false
        automation.registerDeviceToken = false
        XCTAssertTrue(automation.handleNotificationResponse)
        Braze.prepareForDelayedInitialization(pushAutomation: automation)
        XCTAssertEqual(BrazeInAppMessageUI().presentedMessageCount, 0)
    }
}

@MainActor
final class AlamofireImageShimTests: XCTestCase {
    func testSetImageKeepsThePlaceholderAndReportsFailure() {
        let placeholder = UIImage()
        let view = UIImageView(frame: .zero)
        let done = expectation(description: "completion")
        view.af.setImage(
            withURL: URL(string: "https://example.com/a.png")!,
            placeholderImage: placeholder,
            filter: nil,
            progress: nil,
            progressQueue: DispatchQueue.main,
            imageTransition: .crossDissolve(0.3),
            runImageTransitionIfCached: false
        ) { result in
            if case .success = result { XCTFail("no image may be delivered") }
            done.fulfill()
        }
        wait(for: [done], timeout: 2)
        XCTAssertTrue(view.image === placeholder)
        view.af.cancelImageRequest()
    }

    func testSetImageWithoutPlaceholderLeavesTheViewEmpty() {
        let view = UIImageView(frame: .zero)
        view.af.setImage(withURL: URL(string: "https://example.com/a.png")!)
        view.af.setImage(withURL: URL(string: "https://example.com/b.png")!, placeholderImage: nil,
                         filter: CircleFilter())
        let settle = expectation(description: "settle")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { settle.fulfill() }
        wait(for: [settle], timeout: 2)
        XCTAssertNil(view.image)
    }
}

final class StatsigShimTests: XCTestCase {
    func testStatsigErrorDescribesUnavailability() {
        XCTAssertNotNil(StatsigUnavailable().errorDescription)
    }
}
