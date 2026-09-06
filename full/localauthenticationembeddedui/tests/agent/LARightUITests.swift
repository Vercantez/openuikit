import Foundation
@_spi(OpenUIKitHost) import LocalAuthenticationEmbeddedUI

func testAuthorizeInPresentationContextFailClosed() {
    LocalAuthenticationEmbeddedUIHostControl.reset()
    precondition(LocalAuthenticationEmbeddedUIHostControl.authorizationAttempts() == 0)

    let right = LARight()
    let window = UIWindow()
    precondition(right.state == .unknown)
    precondition(right.state.rawValue == 0)

    var calls = 0
    var captured: (any Error)?
    right.authorize(localizedReason: "Unlock secret", in: window) { error in
        calls += 1
        captured = error
        precondition(right.state == .notAuthorized)
        precondition(right.state.rawValue == 3)
    }
    precondition(calls == 1)
    precondition(captured is LocalAuthenticationEmbeddedUIPresentationError)
    precondition(
        (captured as? LocalAuthenticationEmbeddedUIPresentationError)
            == .notInteractive
    )
    let nsError = captured as NSError?
    precondition(nsError?.domain == "com.apple.LocalAuthentication")
    precondition(nsError?.code == -1004)
    precondition(right.state == .notAuthorized)
    precondition(right.state != .authorized)
    precondition(
        LocalAuthenticationEmbeddedUIHostControl.lastLocalizedReason()
            == "Unlock secret"
    )
    precondition(
        LocalAuthenticationEmbeddedUIHostControl.lastPresentationContext() === window
    )
    precondition(LocalAuthenticationEmbeddedUIHostControl.authorizationAttempts() == 1)

    right.authorize(localizedReason: "again", in: window) { error in
        calls += 1
        captured = error
    }
    precondition(calls == 2)
    precondition((captured as NSError?)?.code == -1004)
    precondition(right.state == .notAuthorized)
    precondition(LocalAuthenticationEmbeddedUIHostControl.authorizationAttempts() == 2)
    precondition(
        LocalAuthenticationEmbeddedUIHostControl.lastLocalizedReason() == "again"
    )
}

func testAuthorizeEmptyReasonStillFailClosed() {
    LocalAuthenticationEmbeddedUIHostControl.reset()
    let right = LARight()
    let window = UIWindow()
    var calls = 0
    var captured: (any Error)?
    right.authorize(localizedReason: "", in: window) { error in
        calls += 1
        captured = error
    }
    precondition(calls == 1)
    precondition(
        (captured as? LocalAuthenticationEmbeddedUIPresentationError)
            == .notInteractive
    )
    precondition(right.state == .notAuthorized)
    precondition(LocalAuthenticationEmbeddedUIHostControl.lastLocalizedReason() == "")
}

func testAuthorizeDoesNotInventSuccess() {
    LocalAuthenticationEmbeddedUIHostControl.reset()
    let right = LARight()
    let window = UIWindow()
    right.tag = 7
    precondition(right.tag == 7)
    var success = false
    right.authorize(localizedReason: "login", in: window) { error in
        if error == nil {
            success = true
        }
    }
    precondition(!success)
    precondition(right.state != .authorized)
    precondition(right.state == .notAuthorized)
}

func testRightStateRawValues() {
    precondition(LARight.State.unknown.rawValue == 0)
    precondition(LARight.State.authorizing.rawValue == 1)
    precondition(LARight.State.authorized.rawValue == 2)
    precondition(LARight.State.notAuthorized.rawValue == 3)
    precondition(LARight.State(rawValue: 0) == .unknown)
    precondition(LARight.State(rawValue: 1) == .authorizing)
    precondition(LARight.State(rawValue: 2) == .authorized)
    precondition(LARight.State(rawValue: 3) == .notAuthorized)
    precondition(LARight.State(rawValue: 4) == nil)
}
