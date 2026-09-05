import Foundation
import ClassKit

func testCLSErrorBridging() {
    classKitExpect(CLSError.errorDomain == CLSErrorCodeDomain, "errorDomain")
    classKitExpect(CLSError.none.rawValue == 0, "none alias")
    classKitExpect(CLSError.classKitUnavailable.rawValue == 1, "unavailable alias")
    classKitExpect(CLSError.invalidArgument.rawValue == 2, "invalidArgument alias")
    classKitExpect(CLSError.invalidModification.rawValue == 3, "invalidModification alias")
    classKitExpect(CLSError.authorizationDenied.rawValue == 4, "authorizationDenied alias")
    classKitExpect(CLSError.databaseInaccessible.rawValue == 5, "databaseInaccessible alias")
    classKitExpect(CLSError.limits.rawValue == 6, "limits alias")
    classKitExpect(CLSError.invalidCreate.rawValue == 7, "invalidCreate alias")
    classKitExpect(CLSError.invalidUpdate.rawValue == 8, "invalidUpdate alias")
    classKitExpect(CLSError.partialFailure.rawValue == 9, "partialFailure alias")
    classKitExpect(CLSError.invalidAccountCredentials.rawValue == 10, "credentials alias")

    let tagged = CLSError(.classKitUnavailable, userInfo: [CLSErrorUserInfoKey.objectKey.rawValue: "ctx"])
    classKitExpect(tagged.code == .classKitUnavailable, "code")
    classKitExpect(tagged.errorCode == 1, "errorCode")
    classKitExpect(tagged.userInfo[CLSErrorUserInfoKey.objectKey.rawValue] as? String == "ctx", "userInfo")
    classKitExpect(tagged.errorUserInfo[CLSErrorUserInfoKey.objectKey.rawValue] as? String == "ctx", "errorUserInfo")
    classKitExpect(!tagged.localizedDescription.isEmpty, "localizedDescription")
    _ = tagged.hashValue
    var hasher = Hasher()
    tagged.hash(into: &hasher)
    _ = hasher.finalize()

    let empty = CLSError(.classKitUnavailable)
    classKitExpect(tagged != empty, "error !=")
    classKitExpect(empty == CLSError(.classKitUnavailable), "error ==")
    classKitExpect(CLSError(.none) != CLSError(.limits), "distinct codes")
}

func testCLSErrorPatternMatching() {
    let error: any Error = CLSError(.authorizationDenied)
    classKitExpect(CLSError.Code.authorizationDenied ~= error, "match")
    classKitExpect(!(CLSError.Code.limits ~= error), "nonmatch")
    do {
        throw CLSError(.databaseInaccessible)
    } catch {
        classKitExpect(CLSError.Code.databaseInaccessible ~= error, "catch")
    }
}
