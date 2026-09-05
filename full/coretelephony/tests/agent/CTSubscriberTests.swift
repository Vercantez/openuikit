import CoreTelephony
import Foundation

private final class SubscriberDelegateProbe: NSObject, CTSubscriberDelegate {
    var refreshed: CTSubscriber?
    func subscriberTokenRefreshed(_ subscriber: CTSubscriber) {
        refreshed = subscriber
    }
}

func testSubscriberFailClosed() {
    let subscriber = CTSubscriber()
    precondition(subscriber.carrierToken == nil)
    precondition(subscriber.identifier.isEmpty)
    precondition(subscriber.isSIMInserted == false)
    precondition(subscriber.refreshCarrierToken() == false)
}

func testSubscriberDelegate() {
    let subscriber = CTSubscriber()
    let probe = SubscriberDelegateProbe()
    subscriber.delegate = probe
    precondition(subscriber.delegate === probe)
    precondition(subscriber.refreshCarrierToken() == false)
    precondition(probe.refreshed == nil)
    let existential: any CTSubscriberDelegate = probe
    existential.subscriberTokenRefreshed(subscriber)
    precondition(probe.refreshed === subscriber)
}

func testSubscriberInfo() {
    precondition(CTSubscriberInfo.subscribers().isEmpty)
    let deprecated = CTSubscriberInfo.subscriber()
    precondition(deprecated.isSIMInserted == false)
    precondition(deprecated.carrierToken == nil)
}

func testSubscriberTokenRefreshedConstant() {
    precondition(CTSubscriberTokenRefreshed == "CTSubscriberTokenRefreshed")
    precondition(CTSubscriberTokenRefreshed != CTCallStateConnected)
}
