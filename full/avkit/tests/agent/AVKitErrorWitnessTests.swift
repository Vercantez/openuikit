import Foundation
import AVKit

func testAVKitErrorDomainString() {
    precondition(AVKitErrorDomain == "AVKitErrorDomain")
}

func testAVKitErrorCustomNSErrorDomain() {
    precondition(AVKitError.errorDomain == AVKitErrorDomain)
}

func testAVKitErrorCustomNSErrorUserInfo() {
    let typed = AVKitError(.unknown, userInfo: ["probe": "avkit"])
    precondition(typed.errorUserInfo["probe"] as? String == "avkit")
}

func testAVKitErrorCustomNSErrorCode() {
    let typed = AVKitError(.pictureInPictureStartFailed)
    precondition(typed.errorCode == -1001)
}

func testAVKitErrorCodeMatchesOperator() {
    let typed = AVKitError(.pictureInPictureStartFailed)
    precondition(AVKitError.Code.pictureInPictureStartFailed ~= (typed as any Error))
    precondition(!(AVKitError.Code.unknown ~= (typed as any Error)))
}

func testAVKitErrorBridgedErrorUserInfo() {
    let typed = AVKitError(.unknown, userInfo: ["k": 7])
    let bridgedUserInfo = (typed as AVKitError).errorUserInfo
    precondition(bridgedUserInfo["k"] as? Int == 7)
}

func testAVKitErrorEquality() {
    let lhs = AVKitError(.unknown, userInfo: ["a": 1])
    let rhs = AVKitError(.unknown, userInfo: ["a": 1])
    let other = AVKitError(.pictureInPictureStartFailed)
    precondition(lhs == rhs)
    precondition(!(lhs == other))
}

func testAVKitErrorCodeProperty() {
    let typed = AVKitError(.pictureInPictureStartFailed, userInfo: [:])
    precondition(typed.code == .pictureInPictureStartFailed)
}

func testAVKitErrorHashInto() {
    var hasher = Hasher()
    AVKitError(.unknown).hash(into: &hasher)
    _ = hasher.finalize()
}

func testAVKitErrorUserInfo() {
    let typed = AVKitError(.unknown, userInfo: ["probe": "avkit"])
    precondition(typed.userInfo["probe"] as? String == "avkit")
}

func testAVKitErrorBridgedErrorCode() {
    let typed = AVKitError(.unknown)
    precondition(typed.errorCode == -1000)
}

func testAVKitErrorHashValue() {
    let first = AVKitError(.pictureInPictureStartFailed, userInfo: ["a": 1])
    let second = AVKitError(.pictureInPictureStartFailed, userInfo: ["b": 2])
    precondition(first.hashValue == second.hashValue)
}

func testAVKitErrorInitCodeUserInfo() {
    let typed = AVKitError(.unknown, userInfo: ["probe": true])
    precondition(typed.code == .unknown)
    precondition(typed.userInfo["probe"] as? Bool == true)
}

func testAVKitErrorStructType() {
    let typed = AVKitError(.unknown)
    _ = typed
    precondition(typed.code == .unknown)
}

func testAVKitErrorStaticErrorDomain() {
    precondition(AVKitError.errorDomain == "AVKitErrorDomain")
}

func testAVKitErrorPictureInPictureStartFailedCode() {
    precondition(AVKitError.pictureInPictureStartFailed == .pictureInPictureStartFailed)
    precondition(AVKitError.Code.pictureInPictureStartFailed.rawValue == -1001)
}

func testAVKitErrorUnknownCode() {
    precondition(AVKitError.unknown == .unknown)
    precondition(AVKitError.Code.unknown.rawValue == -1000)
}

func testAVKitErrorNotEqual() {
    precondition(AVKitError(.unknown) != AVKitError(.pictureInPictureStartFailed))
}

func testAVKitErrorCodeHashValue() {
    precondition(AVKitError.Code.unknown.hashValue == AVKitError.Code.unknown.hashValue)
    precondition(AVKitError.Code.unknown.hashValue != AVKitError.Code.pictureInPictureStartFailed.hashValue)
}

func testAVKitErrorCodeHashInto() {
    var hasher = Hasher()
    AVKitError.Code.pictureInPictureStartFailed.hash(into: &hasher)
    _ = hasher.finalize()
}

func testAVKitErrorLocalizedDescription() {
    let description = AVKitError(.unknown).localizedDescription
    precondition(!description.isEmpty)
}

func testPlatformSupportsAVKitCoreIsFalse() {
    precondition(PLATFORM_SUPPORTS_AVKITCORE == false)
}

func testPrepareRouteSelectionForPlaybackSynchronousFailClosed() {
    let session = AVAudioSession()
    var called = 0
    var allowed = true
    var selection = AVAudioSession.RouteSelection.local
    session.prepareRouteSelectionForPlayback { nextAllowed, nextSelection in
        called += 1
        allowed = nextAllowed
        selection = nextSelection
    }
    precondition(called == 1)
    precondition(allowed == false)
    precondition(selection == .none)
}
