import AuthenticationServices
import Foundation
import XCTest

/// NetNewsWire Account/Feedly/OAuthAccountAuthorizationOperation.swift.
/// MEASURED iPhone 16 / iOS 26.1:
/// Tools/oracle2/webauthsessionprobe/transcript-ios26.1.txt.
@MainActor
final class WebAuthenticationSessionTests: XCTestCase {
    private final class Provider: NSObject, ASWebAuthenticationPresentationContextProviding {
        let window = UIWindow(frame: .zero)
        func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor { window }
    }

    func testDomainCodesAndAnchorType() {
        XCTAssertEqual(ASWebAuthenticationSessionErrorDomain, "com.apple.AuthenticationServices.WebAuthenticationSession")
        XCTAssertEqual(ASWebAuthenticationSessionError.Code.canceledLogin.rawValue, 1)
        XCTAssertEqual(ASWebAuthenticationSessionError.Code.presentationContextNotProvided.rawValue, 2)
        XCTAssertEqual(ASWebAuthenticationSessionError.Code.presentationContextInvalid.rawValue, 3)
        XCTAssertTrue(ASPresentationAnchor.self == UIWindow.self)
    }

    func testStartWithoutProviderFailsSynchronouslyWithCode2() {
        var events: [String] = []
        let s = ASWebAuthenticationSession(url: URL(string: "https://example.invalid/oauth")!, callbackURLScheme: "x") { url, error in
            let e = error as NSError?
            events.append("callback url=\(url == nil ? "nil" : "set") \(e?.domain ?? "") \(e?.code ?? -1) \(error is ASWebAuthenticationSessionError)")
        }
        XCTAssertFalse(s.prefersEphemeralWebBrowserSession)
        XCTAssertFalse(s.canStart)
        let started = s.start()
        events.append("start=\(started)")
        XCTAssertEqual(events, [
            "callback url=nil com.apple.AuthenticationServices.WebAuthenticationSession 2 true",
            "start=false",
        ])
    }

    func testStartWithProviderCannotPresentAndFailsWithCode3() {
        var codes: [ASWebAuthenticationSessionError.Code] = []
        let s = ASWebAuthenticationSession(url: URL(string: "https://example.invalid/oauth")!, callbackURLScheme: "x") { _, error in
            if let e = error as? ASWebAuthenticationSessionError { codes.append(e.code) }
        }
        let p = Provider()
        s.presentationContextProvider = p
        XCTAssertFalse(s.canStart)
        XCTAssertFalse(s.start())
        XCTAssertFalse(s.start())
        s.cancel()
        // measured: one callback on the first failed start, none on the
        // second start or on cancel
        XCTAssertEqual(codes, [.presentationContextInvalid])
    }
}
