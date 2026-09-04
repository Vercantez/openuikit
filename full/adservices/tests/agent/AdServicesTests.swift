import AdServices
import Foundation

func testAttributionErrorDomain() {
    precondition(AAAttributionErrorDomain == "com.apple.ap.adservices.attributionError")
    precondition(AAAttributionError.errorDomain == AAAttributionErrorDomain)
    precondition(AAAttributionError.errorDomain == "com.apple.ap.adservices.attributionError")
    precondition(AAAttributionError._nsErrorDomain == AAAttributionErrorDomain)
}

func testAttributionErrorCodes() {
    precondition(AAAttributionError.Code.networkError.rawValue == 1)
    precondition(AAAttributionError.Code.internalError.rawValue == 2)
    precondition(AAAttributionError.Code.platformNotSupported.rawValue == 3)
    precondition(AAAttributionError.networkError == .networkError)
    precondition(AAAttributionError.internalError == .internalError)
    precondition(AAAttributionError.platformNotSupported == .platformNotSupported)
    precondition(AAAttributionError.Code.networkError != .internalError)
    _ = AAAttributionError.self
}

func testCodeRawValueInitializer() {
    precondition(AAAttributionError.Code(rawValue: 1) == .networkError)
    precondition(AAAttributionError.Code(rawValue: 2) == .internalError)
    precondition(AAAttributionError.Code(rawValue: 3) == .platformNotSupported)
    precondition(AAAttributionError.Code(rawValue: 0) == nil)
    precondition(AAAttributionError.Code(rawValue: 4) == nil)
    precondition(AAAttributionError.Code(rawValue: -1) == nil)
}

func testCodeHashable() {
    precondition(
        AAAttributionError.Code.networkError.hashValue
            == AAAttributionError.Code.networkError.hashValue
    )
    var hasherA = Hasher()
    var hasherB = Hasher()
    AAAttributionError.Code.internalError.hash(into: &hasherA)
    AAAttributionError.Code.internalError.hash(into: &hasherB)
    precondition(hasherA.finalize() == hasherB.finalize())

    var seen: Set<AAAttributionError.Code> = []
    seen.insert(.networkError)
    seen.insert(.networkError)
    seen.insert(.platformNotSupported)
    precondition(seen.count == 2)
}

func testAttributionErrorEqualityAndHash() {
    let empty = AAAttributionError(.networkError)
    precondition(empty.userInfo.isEmpty)
    precondition(empty.errorUserInfo.isEmpty)
    precondition(empty.errorCode == 1)
    precondition(empty.code == .networkError)

    let sentinel = AAAttributionError(.networkError, userInfo: ["sentinel": "value"])
    precondition(sentinel.userInfo["sentinel"] as? String == "value")
    precondition(sentinel.errorUserInfo["sentinel"] as? String == "value")
    precondition(empty == AAAttributionError(.networkError))
    precondition(sentinel != empty)
    precondition(empty != AAAttributionError(.internalError))
    precondition(empty.hashValue == sentinel.hashValue)

    var hasherA = Hasher()
    var hasherB = Hasher()
    empty.hash(into: &hasherA)
    AAAttributionError(.networkError).hash(into: &hasherB)
    precondition(hasherA.finalize() == hasherB.finalize())
}

func testAttributionErrorPatternMatch() {
    let error: any Error = AAAttributionError(.internalError)
    precondition(AAAttributionError.Code.internalError ~= error)
    precondition(!(AAAttributionError.Code.networkError ~= error))
    do {
        throw AAAttributionError(.platformNotSupported)
    } catch let error as AAAttributionError where error.code == .platformNotSupported {
        precondition(AAAttributionError.Code.platformNotSupported ~= error)
    } catch {
        preconditionFailure("expected Code.platformNotSupported pattern match")
    }
}

func testAttributionErrorProtocolConformance() {
    func bridgedDomain<E: Foundation._BridgedStoredNSError>(_: E.Type) -> String {
        E._nsErrorDomain
    }
    func errorTypeName<C: Foundation._ErrorCodeProtocol>(_: C.Type) -> String {
        String(describing: C._ErrorType.self)
    }
    precondition(bridgedDomain(AAAttributionError.self) == AAAttributionErrorDomain)
    precondition(
        errorTypeName(AAAttributionError.Code.self)
            == String(describing: AAAttributionError.self)
    )

    let error = AAAttributionError(.internalError)
    var hasher = Hasher()
    error.hash(into: &hasher)
    _ = hasher.finalize()
    _ = error.hashValue

    var seen: Set<Int> = []
    seen.insert(error.hashValue)
    seen.insert(AAAttributionError(.internalError).hashValue)
    precondition(seen.count == 1)
}

func testLocalizedDescriptionNonempty() {
    let error = AAAttributionError(.platformNotSupported)
    precondition(!error.localizedDescription.isEmpty)
}

func testAttributionClassIdentity() {
    let instance: NSObject = AAAttribution()
    precondition(type(of: instance) == AAAttribution.self)
    precondition(instance.isKind(of: NSObject.self))
    let signature: () throws -> String = AAAttribution.attributionToken
    _ = signature
}

func testAttributionTokenFailClosed() {
    do {
        _ = try AAAttribution.attributionToken()
        preconditionFailure("portable attribution must never fabricate a token")
    } catch let error as AAAttributionError {
        precondition(error.code == .platformNotSupported)
        precondition(error.errorCode == 3)
        let bridged = error as NSError
        precondition(bridged.domain == AAAttributionErrorDomain)
        precondition(bridged.code == 3)
        precondition(
            bridged.userInfo[NSLocalizedDescriptionKey] as? String
                == "Apple Ads attribution is unavailable on this host"
        )
    } catch {
        preconditionFailure("unexpected attribution error: \(error)")
    }
}
