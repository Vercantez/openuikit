import AdAttributionKit
import Foundation

private let errorCases: [AdAttributionKitError] = [
    .missingAttributionView,
    .impressionExpired,
    .invalidConversionTag,
    .conversionTagNotSupported,
    .invalidImpressionJWSHeader,
    .invalidImpressionJWSPayload,
    .invalidImpressionJWSSignature,
    .invalidImpressionJWSComponents,
    .unknown,
]

private let linuxDescriptions: [AdAttributionKitError: String] = [
    .missingAttributionView: "missingAttributionView",
    .impressionExpired: "impressionExpired",
    .invalidConversionTag: "invalidConversionTag",
    .conversionTagNotSupported: "conversionTagNotSupported",
    .invalidImpressionJWSHeader: "invalidImpressionJWSHeader",
    .invalidImpressionJWSPayload: "invalidImpressionJWSPayload",
    .invalidImpressionJWSSignature: "invalidImpressionJWSSignature",
    .invalidImpressionJWSComponents: "invalidImpressionJWSComponents",
    .unknown: "unknown",
]

func testErrorCases() {
    precondition(errorCases.count == 9)
    precondition(Set(errorCases).count == 9)
    _ = AdAttributionKitError.self
}

func testErrorEquatable() {
    precondition(AdAttributionKitError.unknown == AdAttributionKitError.unknown)
    precondition(AdAttributionKitError.unknown != .invalidImpressionJWSSignature)
    precondition(AdAttributionKitError.missingAttributionView != .impressionExpired)
    precondition(AdAttributionKitError.invalidConversionTag != .conversionTagNotSupported)
    for (index, left) in errorCases.enumerated() {
        for (other, right) in errorCases.enumerated() {
            if index == other {
                precondition(left == right)
                precondition(!(left != right))
            } else {
                precondition(left != right)
                precondition(!(left == right))
            }
        }
    }
}

func testErrorHashable() {
    var hasher = Hasher()
    var seen: Set<Int> = []
    for item in errorCases {
        item.hash(into: &hasher)
        seen.insert(item.hashValue)
        precondition(item.hashValue == item.hashValue)
    }
    _ = hasher.finalize()
    precondition(seen.count == errorCases.count)
    precondition(Set(errorCases).count == errorCases.count)
}

func testErrorDescription() {
    for item in errorCases {
        precondition(item.description == linuxDescriptions[item])
        precondition(!item.description.isEmpty)
    }
}

func testErrorLocalizedDescription() {
    for item in errorCases {
        let asError: any Error = item
        precondition(!item.localizedDescription.isEmpty)
        precondition(!asError.localizedDescription.isEmpty)
    }
}
