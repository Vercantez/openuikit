import CoreTelephony
import Foundation

func testCTCarrierFailClosed() {
    let carrier = CTCarrier()
    precondition(carrier.carrierName == nil)
    precondition(carrier.mobileCountryCode == nil)
    precondition(carrier.mobileNetworkCode == nil)
    precondition(carrier.isoCountryCode == nil)
    precondition(carrier.allowsVOIP == false)
}
