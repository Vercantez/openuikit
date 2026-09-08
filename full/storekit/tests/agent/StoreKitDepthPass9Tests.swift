import Foundation
import StoreKit

private func expectDepth9(_ condition: Bool, _ message: String) {
    precondition(condition, message)
}

func testStoreKitNewtypeHashValues() {
    testStoreKitJWSCanonicalEnvelope()
    let coarse = SKAdNetwork.CoarseConversionValue(rawValue: "low")
    let action = SKCloudServiceSetupAction(rawValue: "subscribe")
    let message = SKCloudServiceSetupMessageIdentifier(rawValue: "join")
    let option = SKCloudServiceSetupOptionsKey(rawValue: "campaign")

    expectDepth9(coarse.hashValue == coarse.hashValue, "coarse hash must be stable in-process")
    expectDepth9(action.hashValue == action.hashValue, "action hash must be stable in-process")
    expectDepth9(message.hashValue == message.hashValue, "message hash must be stable in-process")
    expectDepth9(option.hashValue == option.hashValue, "option hash must be stable in-process")

    var values: Set<SKCloudServiceSetupOptionsKey> = [option]
    values.insert(SKCloudServiceSetupOptionsKey(rawValue: "campaign"))
    expectDepth9(values.count == 1, "equal raw values must hash equally")
}

func testStoreKitJWSCanonicalEnvelope() {
    let valid = "eyJhbGciOiJFUzI1NiIsInR5cCI6IkpXUyIsIng1YyI6WyJBUUlkIl19.e30."
        + String(repeating: "qqqq", count: 21) + "qg"
    let parsed = try! StoreKitJWS(compactSerialization: valid)
    expectDepth9(parsed.algorithm == "ES256", "algorithm")
    expectDepth9(parsed.x5cChain == [Data([1, 2, 29])], "certificate bytes")
    expectDepth9(parsed.signatureData.count == 64, "signature shape")

    let paddedHeader = "eyJhbGciOiJFUzI1NiIsIng1YyI6WyJBUUlkIl19=.e30."
        + String(repeating: "qqqq", count: 21) + "qg"
    do {
        _ = try StoreKitJWS(compactSerialization: paddedHeader)
        preconditionFailure("padded compact segment must fail closed")
    } catch let error as VerificationResult<Transaction>.VerificationError {
        expectDepth9(error == .invalidEncoding, "padding error")
    } catch {
        preconditionFailure("unexpected padding error")
    }

    let wrongType = "eyJhbGciOiJFUzI1NiIsInR5cCI6IkpXVCIsIng1YyI6WyJBUUlkIl19.e30."
        + String(repeating: "qqqq", count: 21) + "qg"
    do {
        _ = try StoreKitJWS(compactSerialization: wrongType)
        preconditionFailure("wrong protected-header type must fail closed")
    } catch let error as VerificationResult<Transaction>.VerificationError {
        expectDepth9(error == .invalidEncoding, "type error")
    } catch {
        preconditionFailure("unexpected type error")
    }
}
