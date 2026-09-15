import AdAttributionKit
import Foundation

// init(compactJWS:) always throws (no verified impression exists on Linux),
// so these tests build values through the underscored test-support factory
// and then exercise each real storage getter, Hashable, and Equatable.
// Every test below is a top-level synchronous no-argument function.

func testAppImpressionStorageIDs() {
    let id = UUID()
    let impression = AppImpression._unverifiedForTesting(
        id: id,
        publisherItemID: 11,
        advertisedItemID: 22,
        sourceID: 33
    )
    precondition(impression.id == id)
    precondition(impression.publisherItemID == 11)
    precondition(impression.advertisedItemID == 22)
    precondition(impression.sourceID == 33)
}

func testAppImpressionStorageStrings() {
    let impression = AppImpression._unverifiedForTesting(
        keyID: "test-key-id",
        adNetworkID: "example.network",
        compactJWSRepresentation: "header.payload.signature"
    )
    precondition(impression.keyID == "test-key-id")
    precondition(impression.adNetworkID == "example.network")
    precondition(impression.compactJWSRepresentation == "header.payload.signature")
}

func testAppImpressionStorageFlags() {
    let moment = Date(timeIntervalSince1970: 1_700_000_000)
    let impression = AppImpression._unverifiedForTesting(
        timestamp: moment,
        eligibleForReengagement: true
    )
    precondition(impression.timestamp == moment)
    precondition(impression.eligibleForReengagement == true)
    let locked = AppImpression._unverifiedForTesting(eligibleForReengagement: false)
    precondition(locked.eligibleForReengagement == false)
}

func testAppImpressionStorageHashable() {
    let sharedID = UUID()
    let first = AppImpression._unverifiedForTesting(
        id: sharedID,
        publisherItemID: 7,
        adNetworkID: "example.network"
    )
    let second = AppImpression._unverifiedForTesting(
        id: sharedID,
        publisherItemID: 7,
        adNetworkID: "example.network"
    )
    let other = AppImpression._unverifiedForTesting(publisherItemID: 8)
    precondition(first == second)
    precondition(!(first == other))
    precondition(first != other)
    precondition(!(first != second))
    var hasher = Hasher()
    first.hash(into: &hasher)
    _ = hasher.finalize()
    precondition(first.hashValue == second.hashValue)
    precondition(Set([first, second]).count == 1)
    precondition(Set([first, other]).count == 2)
}
