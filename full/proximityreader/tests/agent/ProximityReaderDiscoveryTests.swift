import Foundation
import ProximityReader

func testProximityReaderDiscoveryContent() {
    let content = ProximityReaderDiscovery.Content(id: "c1", description: "How to tap")
    precondition(content.id == "c1")
    precondition(content.description == "How to tap")
    precondition(ProximityReaderDiscovery.Content.ID.self == String.self)
    _ = ProximityReaderDiscovery()
}


func testProximityReaderDiscoveryContentError() {
    let cases: [ProximityReaderDiscovery.ContentError] = [
        .systemBusy, .notSupported, .contentNotFound, .networkUnavailable,
        .contentDisplayFailed, .unknown,
    ]
    precondition(cases.count == 6)
    let error = ProximityReaderDiscovery.ContentError.notSupported
    precondition(error.errorDescription?.contains("notSupported") == true)
    precondition(error.failureReason == nil)
    precondition(error.recoverySuggestion == nil)
    precondition(error.helpAnchor == nil)
    precondition(error.localizedDescription.contains("notSupported"))
    precondition(error == .notSupported)
    precondition(error != .unknown)
    _ = error.hashValue
    var hasher = Hasher()
    error.hash(into: &hasher)
}


func testProximityReaderDiscoveryTopic() {
    let topic = ProximityReaderDiscovery.Topic.payment(.howToTap)
    switch topic {
    case .payment(let payment):
        precondition(payment == .howToTap)
        precondition(payment == .howToTap)
    }
    _ = ProximityReaderDiscovery.Topic.Payment.howToTap.hashValue
    var hasher = Hasher()
    ProximityReaderDiscovery.Topic.Payment.howToTap.hash(into: &hasher)
}
