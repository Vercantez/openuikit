import DeviceCheck
import Foundation

@main
struct DeviceCheckErrorParity {
    static func main() {
        precondition(DCErrorDomain == "com.apple.devicecheck.error")
        precondition(DCError.errorDomain == "com.apple.devicecheck.error")
        precondition(DCError.errorDomain == DCErrorDomain)

        let empty = DCError(.featureUnsupported)
        precondition(empty.userInfo.isEmpty)
        precondition(empty.errorUserInfo.isEmpty)
        precondition(!empty.userInfo.keys.contains(NSLocalizedDescriptionKey))
        precondition(!empty.errorUserInfo.keys.contains(NSLocalizedDescriptionKey))

        let sentinel = DCError(
            .featureUnsupported,
            userInfo: ["sentinel": "value"]
        )
        precondition(sentinel.userInfo["sentinel"] as? String == "value")
        precondition(sentinel.errorUserInfo["sentinel"] as? String == "value")
        precondition(sentinel.userInfo.count == 1)
        precondition(sentinel.errorUserInfo.count == 1)
        precondition(!sentinel.userInfo.keys.contains(NSLocalizedDescriptionKey))
        precondition(!sentinel.errorUserInfo.keys.contains(NSLocalizedDescriptionKey))

        let emptyAgain = DCError(.featureUnsupported)
        precondition(empty == emptyAgain)
        precondition(empty.hashValue == emptyAgain.hashValue)

        let sentinelAgain = DCError(
            .featureUnsupported,
            userInfo: ["sentinel": "value"]
        )
        precondition(sentinel == sentinelAgain)
        precondition(sentinel.hashValue == sentinelAgain.hashValue)

        precondition(sentinel != empty)
        precondition(empty != DCError(.invalidInput))
        precondition(
            DCError(.featureUnsupported, userInfo: ["sentinel": "a"]) !=
                DCError(.featureUnsupported, userInfo: ["sentinel": "b"])
        )

        var hasherA = Hasher()
        var hasherB = Hasher()
        empty.hash(into: &hasherA)
        emptyAgain.hash(into: &hasherB)
        precondition(hasherA.finalize() == hasherB.finalize())

        print(
            "DEVICECHECK_ERROR_PARITY_OK domain=com.apple.devicecheck.error " +
            "userInfo=preserved hash=lawful"
        )
    }
}
