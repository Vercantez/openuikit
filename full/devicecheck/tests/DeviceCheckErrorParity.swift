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
        precondition(sentinel.hashValue == empty.hashValue)

        let intOne = DCError(.invalidInput, userInfo: ["x": 1])
        let stringOne = DCError(.invalidInput, userInfo: ["x": "1"])
        precondition(intOne != stringOne)
        precondition(intOne.hashValue == stringOne.hashValue)

        let sameCode = [
            DCError(.invalidInput),
            DCError(.invalidInput, userInfo: ["x": 1]),
            DCError(.invalidInput, userInfo: ["x": 2]),
            DCError(.invalidInput, userInfo: ["x": "1"]),
            DCError(.invalidInput, userInfo: ["y": 1]),
            DCError(.invalidInput, userInfo: ["nested": [1, 2]]),
        ]
        precondition(Set(sameCode.map(\.hashValue)).count == 1)
        precondition(sameCode[0] != sameCode[1])
        precondition(sameCode[1] != sameCode[2])
        precondition(sameCode[1] != sameCode[3])
        precondition(sameCode[1] != sameCode[4])
        precondition(sameCode[1] != sameCode[5])

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
